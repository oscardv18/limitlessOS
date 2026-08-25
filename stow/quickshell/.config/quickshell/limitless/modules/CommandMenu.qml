// modules/CommandMenu.qml — Menú de comandos del sistema (LIMITLESS-OS.md §6 Fase 4)
//
// Reproduce el menú del sistema (#menu) de docs/mockups/limitless-shell.html:
//   - Permite despachar subcomandos de dotctl y herramientas del sistema.
//   - Conectado a IPC { surfaceName: "menu" }.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    IPC {
        id: ipc
        surfaceName: "menu"
    }

    visible: reveal.active
    anchors.centerIn: parent
    width: 560
    height: 480
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: ipc.shown

    property int selectedIndex: 0
    // glifos geométricos, nunca emoji (identidad visual, CLAUDE.md). "theme
    // cycle" y "update" todavía no existen como comandos reales (Fase 5) —
    // quedan aquí como UI lista para cuando se escriban; ejecutarlos hoy
    // simplemente falla con "comando no encontrado", no rompe nada.
    property var cmdList: [
        { name: "dotctl doctor",       desc: "Diagnóstico completo del sistema y configuración", glyph: "◎", cat: "DIAGNÓSTICO" },
        { name: "dotctl pkg install",  desc: "Instalador y buscador de paquetes oficiales y AUR", glyph: "▣", cat: "PAQUETES" },
        { name: "dotctl pkg search",   desc: "Búsqueda rápida en repositorios y PKGBUILDs",        glyph: "◈", cat: "PAQUETES" },
        { name: "dotctl tui-install",  desc: "Genera accesos .desktop para aplicaciones de terminal", glyph: "⚙", cat: "SISTEMA" },
        { name: "dotctl theme cycle",  desc: "Cicla entre las técnicas de color (Lapse/Hollow/Reversal)", glyph: "◐", cat: "THEMING" },
        { name: "dotctl update",       desc: "Actualización atómica con instantánea Btrfs previa", glyph: "⟳", cat: "MANTENIMIENTO" },
        { name: "hyprlock",            desc: "Bloquear la sesión gráfica de inmediato", glyph: "◘", cat: "SESIÓN" }
    ]

    function filteredCmds() {
        var q = menuInput.text.trim().toLowerCase()
        if (q === "") return cmdList
        return cmdList.filter(function(item) {
            return item.name.toLowerCase().indexOf(q) !== -1 ||
                   item.desc.toLowerCase().indexOf(q) !== -1 ||
                   item.cat.toLowerCase().indexOf(q) !== -1
        })
    }

    function run(item) {
        Quickshell.execDetached(["sh", "-c", item.name])
        ipc.hide()
    }

    // Keys.onPressed necesita un Item con foco real, no un PanelWindow (es
    // un Window, no un Item) — mismo fix que ControlCenter.qml/Launcher.qml.
    FocusScope {
        id: keyScope
        anchors.fill: parent
        focus: root.visible

    Keys.onPressed: function(event) {
        var items = filteredCmds()
        if (event.key === Qt.Key_Escape) {
            ipc.hide()
            event.accepted = true
        } else if (event.key === Qt.Key_Down) {
            if (items.length > 0) {
                root.selectedIndex = (root.selectedIndex + 1) % items.length
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Up) {
            if (items.length > 0) {
                root.selectedIndex = (root.selectedIndex - 1 + items.length) % items.length
            }
            event.accepted = true
        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
            if (items.length > 0 && root.selectedIndex < items.length) {
                root.run(items[root.selectedIndex])
            }
            event.accepted = true
        }
    }

    Reveal {
        id: reveal
        anchors.fill: parent
        shown: ipc.shown

    GlassSurface {
        anchors.fill: parent
        cornerRadius: 16

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 16
            spacing: 12

            // Cabecera
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text { text: "◈"; color: Theme.accent; font.pixelSize: 13 }
                Text { text: "MENÚ DEL SISTEMA"; color: Theme.text.text; font.family: Theme.font.family; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5 }
                Item { Layout.fillWidth: true }
                Text { text: "dotctl router"; color: Theme.text.mute; font.family: Theme.font.family; font.pixelSize: 9 }
            }

            // Input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: Theme.surfaceGlass.surfaceHi
                border.color: menuInput.activeFocus ? Theme.accent : Theme.surfaceGlass.line
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text { text: "❯"; color: Theme.accent; font.pixelSize: 12 }
                    TextInput {
                        id: menuInput
                        Layout.fillWidth: true
                        color: Theme.text.text
                        font.family: Theme.font.family
                        font.pixelSize: 12
                        clip: true
                        focus: ipc.shown
                        onTextChanged: root.selectedIndex = 0

                        Text {
                            anchors.fill: parent
                            text: "filtrar comandos del sistema…"
                            color: Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            visible: menuInput.text === "" && !menuInput.activeFocus
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceGlass.line }

            // Lista
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: cmdCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: cmdCol
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.filteredCmds()

                        MouseArea {
                            id: cmdArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 44
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index
                                root.run(modelData)
                            }

                            readonly property bool isSel: root.selectedIndex === index

                            Rectangle {
                                anchors.fill: parent
                                radius: 6
                                color: cmdArea.isSel ? Theme.surfaceGlass.lineHi : (cmdArea.containsMouse ? Theme.surfaceGlass.line : "transparent")
                                border.color: cmdArea.isSel ? Theme.accent : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 10
                                    anchors.rightMargin: 10
                                    spacing: 10

                                    Text { text: modelData.glyph; color: cmdArea.isSel ? Theme.accentCore : Theme.accent; font.pixelSize: 14 }
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2
                                        Text { text: modelData.name; color: cmdArea.isSel ? Theme.text.text : Theme.text.text; font.family: Theme.font.family; font.pixelSize: 11; font.bold: cmdArea.isSel }
                                        Text { text: modelData.desc; color: Theme.text.dim; font.family: Theme.font.family; font.pixelSize: 8.5; elide: Text.ElideRight; Layout.fillWidth: true }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    }
    }
}
