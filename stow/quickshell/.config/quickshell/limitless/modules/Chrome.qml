// modules/Chrome.qml — cromo HUD: corchetes de esquina + telemetría
// (plan.md §3.4, LIMITLESS-OS.md §6 Fase 4)
//
// Traducido de docs/mockups/limitless-shell.html: `.brk` (líneas 119-126)
// y `.rail` (128-136), con la geometría exacta del marcado (líneas
// 1130-1143).
//
// Capa `background` (aboveWindows:false), sin exclusión de espacio y sin
// zona de input: los clics lo atraviesan. plan.md §3.4 lo advierte y
// conviene repetirlo aquí — "sólo se ve con el escritorio despejado. Con
// una ventana maximizada desaparece. Es decoración ambiental, no
// información operativa: no pongas ahí nada que necesites de verdad."
// Por eso la telemetría de aquí es contexto (uptime, técnica, layout) y
// no alertas: lo que importa de verdad vive en la barra.
import QtQuick
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }
    aboveWindows: false
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    property string uptime: "--:--:--"
    property string layoutName: "master"
    property string projectName: "—"

    // uptime desde /proc/uptime: son segundos desde el arranque, en la
    // primera columna. Más barato que invocar `uptime` cada segundo.
    FileView {
        id: uptimeFile
        path: "/proc/uptime"
        onLoaded: {
            var secs = parseFloat(text().split(" ")[0])
            if (isNaN(secs)) return
            var h = Math.floor(secs / 3600)
            var m = Math.floor((secs % 3600) / 60)
            var s = Math.floor(secs % 60)
            root.uptime = (h < 10 ? "0" : "") + h + ":" +
                          (m < 10 ? "0" : "") + m + ":" +
                          (s < 10 ? "0" : "") + s
        }
    }

    Timer {
        running: true
        interval: 1000
        repeat: true
        triggeredOnStart: true
        onTriggered: uptimeFile.reload()
    }

    // el layout activo lo mantiene `dotctl layout` en su archivo de estado
    Process {
        id: layoutProc
        command: ["sh", "-c", "cat \"${XDG_STATE_HOME:-$HOME/.local/state}/limitless/layout\" 2>/dev/null || echo 0"]
        stdout: StdioCollector {
            onStreamFinished: {
                var names = ["master", "dwindle", "scrolling", "grid"]
                var idx = parseInt(this.text.trim())
                if (!isNaN(idx) && idx >= 0 && idx < names.length) root.layoutName = names[idx]
            }
        }
    }

    Timer {
        running: true
        interval: 4000
        repeat: true
        triggeredOnStart: true
        onTriggered: layoutProc.running = true
    }

    // ── corchetes de esquina ────────────────────────────────────────────
    // El trazado del mockup es "M2 14 L2 2 L14 2" en un viewBox 34×34: una
    // ele. Las otras tres esquinas son la misma ele reflejada, igual que
    // hace el CSS con scaleX/scaleY — no cuatro trazados distintos.
    component Bracket: Item {
        id: brk
        property bool flipH: false
        property bool flipV: false
        property color stroke: Theme.accent
        width: 34
        height: 34
        opacity: 0.45

        Canvas {
            anchors.fill: parent
            onPaint: {
                var ctx = getContext("2d")
                ctx.reset()
                ctx.save()
                ctx.translate(brk.flipH ? width : 0, brk.flipV ? height : 0)
                ctx.scale(brk.flipH ? -1 : 1, brk.flipV ? -1 : 1)
                ctx.strokeStyle = brk.stroke
                ctx.lineWidth = 1.3
                ctx.beginPath()
                ctx.moveTo(2, 14)
                ctx.lineTo(2, 2)
                ctx.lineTo(14, 2)
                ctx.stroke()
                ctx.restore()
            }
            // repintar cuando cambia la técnica activa
            Connections {
                target: Theme
                function onAccentChanged() { parent.requestPaint() }
            }
        }
    }

    // superiores en el color de la técnica activa, inferiores en 茈 fijo
    // (mockup: `.brk.bl path,.brk.br path{stroke:var(--hollow)}`)
    Bracket { x: 18; y: 40 }
    Bracket { x: parent.width - 18 - 34; y: 40; flipH: true }
    Bracket { x: 18; y: parent.height - 18 - 34; flipV: true; stroke: Theme.hollowAccent }
    Bracket { x: parent.width - 18 - 34; y: parent.height - 18 - 34; flipH: true; flipV: true; stroke: Theme.hollowAccent }

    // ── raíles de telemetría ────────────────────────────────────────────
    component RailRow: Row {
        id: rail
        property string k: ""
        property string v: ""
        property bool alt: false
        spacing: 6
        // por id, no por `parent`: dentro de un componente en línea
        // `parent` sí resuelve al Row, pero se rompe en silencio en cuanto
        // alguien envuelve estos Text en otro contenedor.
        Text {
            text: rail.k
            color: Theme.text.mute
            font.family: Theme.font.family
            font.pixelSize: 9
            font.letterSpacing: 0.54
        }
        Text {
            text: rail.v
            color: rail.alt ? Theme.hollowAccent : Theme.accent
            font.family: Theme.font.family
            font.pixelSize: 9
            font.letterSpacing: 0.54
        }
    }

    Column {
        x: 20
        y: 68
        spacing: 3
        RailRow { k: "UPTIME";   v: root.uptime }
        RailRow { k: "TÉCNICA";  v: Theme.currentName.toUpperCase() + " · " + Theme.currentKanji }
        RailRow { k: "PROYECTO"; v: root.projectName; alt: true }
    }

    Column {
        x: parent.width - width - 20
        y: 68
        spacing: 3
        RailRow { k: "LAYOUT"; v: root.layoutName; alt: true }
        RailRow { k: "SESIÓN"; v: "hyprland · wayland" }
    }
}
