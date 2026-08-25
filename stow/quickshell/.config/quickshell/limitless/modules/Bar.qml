// modules/Bar.qml — Barra superior de QuickShell (LIMITLESS-OS.md §6 Fase 4)
//
// Reproduce fielmente la barra superior (#bar) de docs/mockups/limitless-shell.html:
//   - Izquierda: marca "⬡ LIMITLESS", kanji de técnica activa (蒼/茈/赫, interactivo) y usuario.
//   - Centro: selector de workspaces semánticos (1:code, 2:term, 3:web, 4:comms, 5:ops).
//   - Derecha: puntos de estado herdr, métricas (CPU/MEM), git, batería y reloj digital.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland
import Quickshell.Services.UPower
import "."

PanelWindow {
    id: root

    anchors {
        top: true
        left: true
        right: true
    }
    height: Theme.geometry.barHeight
    exclusionMode: ExclusionMode.Auto
    color: "transparent"

    property string timeStr: "00:00"
    property string dateStr: ""

    // ── batería (Quickshell.Services.UPower) ───────────────────────────
    // `displayDevice` es la batería que UPower considera principal; en
    // sobremesa no es una batería de portátil y toda la sección se oculta.
    readonly property var battery: UPower.displayDevice
    readonly property bool hasBattery: battery && battery.isLaptopBattery
    // La documentación describe `percentage` como "current charge level as
    // a percentage" pero también dice que se calcula energy/energyCapacity
    // — 0-100 y 0-1 respectivamente. Ambiguo, así que se normaliza en vez
    // de apostar: un valor <= 1 se trata como fracción.
    readonly property int batteryPercent: {
        if (!hasBattery) return 0
        var p = battery.percentage
        if (p === undefined || isNaN(p)) return 0
        return Math.round(p <= 1 ? p * 100 : p)
    }

    // ── proyecto activo — lo escribe `dotctl dev open` ─────────────────
    property string projectName: ""
    property string projectBranch: ""

    FileView {
        id: projectFile
        path: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state"))
              + "/limitless/project"
        onLoaded: {
            // formato: "<nombre>\t<rama>" — una línea, escrita por dotctl dev
            var parts = text().trim().split("\t")
            root.projectName = parts[0] || ""
            root.projectBranch = parts[1] || ""
        }
        onLoadFailed: {
            root.projectName = ""
            root.projectBranch = ""
        }
    }

    // ── estado de los agentes de herdr (LIMITLESS-OS.md §4.1) ───────────
    // Lo publica bin/cmd/herdr-bridge por IPC cada 2s. Mientras el puente
    // no corra, los cuatro quedan en 0 y el grupo de puntos no se dibuja
    // — no hay puntos de mentira ocupando la barra.
    property int herdrBlocked: 0
    property int herdrWorking: 0
    property int herdrDone: 0
    property int herdrIdle: 0

    IpcHandler {
        target: "herdr"
        function setCounts(blocked: int, working: int, done: int, idle: int): void {
            root.herdrBlocked = blocked
            root.herdrWorking = working
            root.herdrDone = done
            root.herdrIdle = idle
        }
    }

    // Actualización de reloj
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            var now = new Date()
            root.timeStr = Qt.formatDateTime(now, "hh:mm")
            root.dateStr = Qt.formatDateTime(now, "dddd, d 'de' MMMM")
        }
    }

    // Fondo de cristal con realces
    Rectangle {
        anchors.fill: parent
        color: Theme.surfaceGlass.surface

        // Línea inferior sutil
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                bottom: parent.bottom
            }
            height: 1
            color: Theme.surfaceGlass.line
        }

        // Realce superior
        Rectangle {
            anchors {
                left: parent.left
                right: parent.right
                top: parent.top
            }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.15)
        }
    }

    RowLayout {
        anchors {
            fill: parent
            leftMargin: 14
            rightMargin: 14
        }
        spacing: 0

        // ── Izquierda: Marca, Técnica y Usuario ─────────────────────────
        RowLayout {
            Layout.alignment: Qt.AlignLeft | Qt.AlignVCenter
            spacing: 12

            // Marca Limitless
            Text {
                text: "⬡ LIMITLESS"
                color: Theme.accent
                font.family: Theme.font.family
                font.pixelSize: 10
                font.bold: true
                font.letterSpacing: 1.2
            }

            // Kanji de Técnica Activa (Clic para ciclar técnica)
            MouseArea {
                id: kanjiArea
                Layout.preferredWidth: kanjiText.implicitWidth + 8
                Layout.preferredHeight: parent.height
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: Theme.cycleTechnique()

                Rectangle {
                    anchors.centerIn: parent
                    width: kanjiText.implicitWidth + 8
                    height: 20
                    radius: 4
                    color: kanjiArea.containsMouse ? Theme.surfaceGlass.line : "transparent"
                    border.color: kanjiArea.containsMouse ? Theme.surfaceGlass.lineHi : "transparent"
                    border.width: 1

                    Text {
                        id: kanjiText
                        anchors.centerIn: parent
                        text: Theme.currentKanji
                        color: Theme.accent
                        font.family: Theme.font.jp
                        font.pixelSize: 12
                    }
                }
            }

            // Nombre de usuario — sin distro hardcodeada: el proyecto debe
            // funcionar en cualquier base Arch, no solo CachyOS (CLAUDE.md).
            Text {
                text: Quickshell.env("USER") || "usuario"
                color: Theme.text.mute
                font.family: Theme.font.family
                font.pixelSize: 10
                font.letterSpacing: 0.5
            }
        }

        Item { Layout.fillWidth: true }

        // ── Centro: Espacios de Trabajo Semánticos (1-5) ────────────────
        RowLayout {
            Layout.alignment: Qt.AlignHCenter | Qt.AlignVCenter
            spacing: 4

            // Workspaces REALES del compositor (Quickshell.Hyprland), no
            // una lista fija: aparecen y desaparecen según los uses, y el
            // activo lo dice Hyprland, no un contador nuestro.
            Repeater {
                model: Hyprland.workspaces

                MouseArea {
                    id: wsBtn
                    required property var modelData
                    Layout.preferredWidth: 20
                    Layout.preferredHeight: 20
                    cursorShape: Qt.PointingHandCursor
                    hoverEnabled: true
                    onClicked: wsBtn.modelData.activate()

                    readonly property bool isActive: wsBtn.modelData.focused
                    readonly property bool isUrgent: wsBtn.modelData.urgent

                    Rectangle {
                        anchors.fill: parent
                        radius: 6
                        color: wsBtn.isActive ? "transparent" : (wsBtn.containsMouse ? Theme.surfaceGlass.line : Qt.rgba(1, 1, 1, 0.025))
                        // urgente = 赫: una ventana reclama atención en un
                        // workspace que no estás mirando
                        border.color: wsBtn.isUrgent ? Theme.reversalAccent
                                    : (wsBtn.isActive ? "transparent"
                                    : (wsBtn.containsMouse ? Theme.surfaceGlass.lineHi : Qt.rgba(1, 1, 1, 0.05)))
                        border.width: 1

                        // Gradiente para workspace activo (Lapse/Accent -> Hollow)
                        Rectangle {
                            anchors.fill: parent
                            radius: 6
                            visible: wsBtn.isActive
                            gradient: Gradient {
                                orientation: Gradient.Horizontal
                                GradientStop { position: 0.0; color: Theme.accent }
                                GradientStop { position: 1.0; color: Theme.hollowAccent }
                            }
                        }

                        Text {
                            anchors.centerIn: parent
                            // el nombre real del workspace si lo tiene
                            // (lua/workspaces.lua los nombra), o su id
                            text: wsBtn.modelData.name || wsBtn.modelData.id
                            // el workspace activo lleva fondo de acento:
                            // el texto va OSCURO para contrastar con él,
                            // no blanco (y sale del tema, no a mano)
                            color: wsBtn.isActive ? Theme.void_ : (wsBtn.containsMouse ? Theme.text.dim : Theme.text.mute)
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            font.bold: wsBtn.isActive
                        }
                    }
                }
            }
        }

        Item { Layout.fillWidth: true }

        // ── Derecha: Herdr, Stats, Git, Batería y Reloj ─────────────────
        RowLayout {
            Layout.alignment: Qt.AlignRight | Qt.AlignVCenter
            spacing: 12

            // Puntos de estado de agentes herdr — uno por agente REAL,
            // con el color de su estado (LIMITLESS-OS.md §4.1). El mapeo
            // estado→color es el de esa sección; `unknown` lo colapsa el
            // puente sobre `idle` antes de llegar aquí.
            RowLayout {
                spacing: 4
                visible: root.herdrBlocked + root.herdrWorking + root.herdrDone + root.herdrIdle > 0

                // lista plana (un elemento por agente) en vez de Repeater
                // anidado: anidarlos obliga a sombrear `modelData`, que es
                // una fuente clásica de errores silenciosos en QML.
                Repeater {
                    model: {
                        var dots = []
                        var i
                        for (i = 0; i < root.herdrBlocked; i++) dots.push(Theme.reversalAccent)  // 赫 te necesita
                        for (i = 0; i < root.herdrWorking; i++) dots.push(Theme.accentCore)      // en curso
                        for (i = 0; i < root.herdrDone;    i++) dots.push(Theme.accent)          // 蒼 listo
                        for (i = 0; i < root.herdrIdle;    i++) dots.push(Theme.text.mute)       // ruido de fondo
                        return dots
                    }

                    Rectangle {
                        width: 5
                        height: 5
                        radius: 2.5
                        color: modelData
                    }
                }
            }

            // CPU — real, de /proc/stat (SysInfo)
            RowLayout {
                spacing: 3
                Text { text: "CPU"; color: Theme.text.mute; font.pixelSize: 10; font.family: Theme.font.family }
                Text {
                    text: SysInfo.cpuPercent + "%"
                    // por encima del 85% el número se pone en 赫: es la
                    // única métrica de la barra que justifica alarmar
                    color: SysInfo.cpuPercent > 85 ? Theme.reversalAccent : Theme.text.text
                    font.pixelSize: 10; font.bold: true; font.family: Theme.font.family
                }
            }

            // MEM — real, de /proc/meminfo (SysInfo)
            RowLayout {
                spacing: 3
                Text { text: "MEM"; color: Theme.text.mute; font.pixelSize: 10; font.family: Theme.font.family }
                Text {
                    text: SysInfo.memUsedGb.toFixed(1) + "G"
                    color: SysInfo.memPercent > 90 ? Theme.reversalAccent : Theme.text.text
                    font.pixelSize: 10; font.bold: true; font.family: Theme.font.family
                }
            }

            // Proyecto y rama — de `dotctl dev open`. Se oculta si no hay
            // sesión de proyecto abierta, en vez de enseñar "main" siempre.
            RowLayout {
                spacing: 4
                visible: root.projectBranch !== ""
                Text { text: "⑂"; color: Theme.accent; font.pixelSize: 11; font.family: Theme.font.family }
                Text {
                    text: root.projectBranch
                    color: Theme.text.text
                    font.pixelSize: 10; font.bold: true; font.family: Theme.font.family
                }
            }

            // Batería — real, de UPower. Oculta en sobremesa.
            RowLayout {
                spacing: 3
                visible: root.hasBattery
                Text {
                    text: "⏻"
                    color: root.batteryPercent <= 15 ? Theme.reversalAccent : Theme.accent
                    font.pixelSize: 11; font.family: Theme.font.family
                }
                Text {
                    text: root.batteryPercent + "%"
                    color: root.batteryPercent <= 15 ? Theme.reversalAccent : Theme.text.text
                    font.pixelSize: 10; font.bold: true; font.family: Theme.font.family
                }
            }

            // Separador
            Rectangle {
                Layout.preferredWidth: 1
                Layout.preferredHeight: 12
                color: Theme.surfaceGlass.line
            }

            // Reloj
            MouseArea {
                Layout.preferredWidth: clockText.implicitWidth + 6
                Layout.preferredHeight: 20
                cursorShape: Qt.PointingHandCursor
                hoverEnabled: true

                Text {
                    id: clockText
                    anchors.centerIn: parent
                    text: root.timeStr
                    color: Theme.text.text
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    font.bold: true
                }
            }
        }
    }
}
