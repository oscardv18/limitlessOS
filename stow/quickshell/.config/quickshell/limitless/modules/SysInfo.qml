// modules/SysInfo.qml — métricas reales del sistema, en un solo sitio.
// Singleton: la barra Y el panel de widgets muestran CPU/MEM, y sondear
// /proc dos veces por lo mismo sería tonto.
//
// De dónde sale cada dato, y por qué de ahí:
//   · CPU  — /proc/stat, delta entre dos lecturas. NO hay forma de leer
//     "el % de CPU ahora": el kernel solo expone contadores acumulados
//     desde el arranque, así que el porcentaje es siempre una diferencia
//     entre dos momentos. Por eso la primera lectura no produce valor.
//   · MEM  — /proc/meminfo. Se usa MemAvailable, no MemFree: MemFree
//     ignora la caché reclamable y da cifras alarmistas y falsas.
//   · GPU  — sin fuente portable. nvidia-smi es de NVIDIA, y las AMD/Intel
//     van por hwmon con rutas que cambian según el equipo. Se deja fuera
//     a propósito en vez de enseñar un número inventado.
//
// Batería y multimedia NO están aquí: Quickshell ya los expone nativos
// (Quickshell.Services.UPower / .Mpris) y duplicarlos sería peor.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    property int cpuPercent: 0
    property real memUsedGb: 0
    property real memTotalGb: 0
    property int memPercent: 0

    // acumulados de la lectura anterior de /proc/stat
    property real _lastTotal: 0
    property real _lastIdle: 0
    property bool _hasPrevious: false

    FileView {
        id: statFile
        path: "/proc/stat"
        onLoaded: {
            // primera línea: "cpu  user nice system idle iowait irq softirq steal ..."
            var line = text().split("\n")[0]
            var parts = line.trim().split(/\s+/)
            if (parts.length < 5 || parts[0] !== "cpu") return

            var total = 0
            for (var i = 1; i < parts.length; i++) {
                var v = parseFloat(parts[i])
                if (!isNaN(v)) total += v
            }
            // idle + iowait: ambos cuentan como "no trabajando"
            var idle = parseFloat(parts[4]) + (parseFloat(parts[5]) || 0)

            if (root._hasPrevious) {
                var dTotal = total - root._lastTotal
                var dIdle = idle - root._lastIdle
                if (dTotal > 0) {
                    root.cpuPercent = Math.max(0, Math.min(100,
                        Math.round((1 - dIdle / dTotal) * 100)))
                }
            }
            root._lastTotal = total
            root._lastIdle = idle
            root._hasPrevious = true
        }
    }

    FileView {
        id: memFile
        path: "/proc/meminfo"
        onLoaded: {
            var totalKb = 0, availKb = 0
            var lines = text().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var m = lines[i].match(/^(MemTotal|MemAvailable):\s+(\d+)\s+kB/)
                if (!m) continue
                if (m[1] === "MemTotal") totalKb = parseInt(m[2])
                else availKb = parseInt(m[2])
            }
            if (totalKb <= 0) return
            var usedKb = totalKb - availKb
            root.memTotalGb = totalKb / 1048576
            root.memUsedGb = usedKb / 1048576
            root.memPercent = Math.round((usedKb / totalKb) * 100)
        }
    }

    Timer {
        running: true
        interval: 2000
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            statFile.reload()
            memFile.reload()
        }
    }
}
