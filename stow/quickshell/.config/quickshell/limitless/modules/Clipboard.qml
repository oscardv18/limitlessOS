// modules/Clipboard.qml — Historial del portapapeles (SUPER+V)
// (spec-keybinds.md §3.1, LIMITLESS-OS.md §6 Fase 4)
//
// Respaldado por cliphist, que ya está corriendo desde lua/exec.lua
// (`wl-paste --watch cliphist store`). Esta superficie no guarda estado
// propio: lee `cliphist list` cada vez que se abre, y al elegir una
// entrada la devuelve al portapapeles con `cliphist decode | wl-copy`.
//
// Formato de `cliphist list`: una línea por entrada, "<id>\t<vista previa>".
// El id es lo que hay que pasarle de vuelta a `cliphist decode` — la vista
// previa está recortada y no sirve para recuperar el contenido real.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    IPC {
        id: ipc
        surfaceName: "clipboard"
    }

    visible: reveal.active
    anchors.centerIn: parent
    width: 620
    height: 460
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: ipc.shown

    property int selectedIndex: 0
    property var entries: []

    // recargar al abrir: el portapapeles cambia constantemente mientras el
    // panel está cerrado, así que una lista cacheada estaría siempre vieja
    onVisibleChanged: if (visible) { root.selectedIndex = 0; listProc.running = true }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    var line = lines[i]
                    if (line.trim() === "") continue
                    var tab = line.indexOf("\t")
                    if (tab === -1) continue
                    out.push({
                        id: line.substring(0, tab),
                        preview: line.substring(tab + 1)
                    })
                }
                root.entries = out
            }
        }
    }

    function copySelected() {
        var item = root.entries[root.selectedIndex]
        if (!item) return
        // decode necesita el id por stdin, de ahí el pipe con echo
        Quickshell.execDetached(["sh", "-c",
            "echo '" + item.id + "' | cliphist decode | wl-copy"])
        ipc.hide()
    }

    // Keys.onPressed va en un FocusScope, no en el PanelWindow (es un
    // Window, no un Item) — mismo patrón que el resto de superficies.
    FocusScope {
        anchors.fill: parent
        focus: root.visible

        Keys.onPressed: function(event) {
            var n = root.entries.length
            if (event.key === Qt.Key_Escape) {
                ipc.hide()
                event.accepted = true
            } else if (event.key === Qt.Key_Down) {
                if (n > 0) root.selectedIndex = (root.selectedIndex + 1) % n
                event.accepted = true
            } else if (event.key === Qt.Key_Up) {
                if (n > 0) root.selectedIndex = (root.selectedIndex - 1 + n) % n
                event.accepted = true
            } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                root.copySelected()
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

                RowLayout {
                    Layout.fillWidth: true
                    spacing: 8

                    Text { text: "⧉"; color: Theme.accent; font.pixelSize: 13 }
                    Text {
                        text: "PORTAPAPELES"
                        color: Theme.text.text
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        font.bold: true
                        font.letterSpacing: 1.5
                    }
                    Item { Layout.fillWidth: true }
                    Text {
                        text: root.entries.length + " entradas"
                        color: Theme.text.mute
                        font.family: Theme.font.family
                        font.pixelSize: 9
                    }
                }

                Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceGlass.line }

                // estado vacío explícito: cliphist recién arrancado no
                // tiene nada, y un panel en blanco parecería un fallo
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 24
                    visible: root.entries.length === 0
                    text: "sin entradas todavía — copia algo y vuelve"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 11
                    horizontalAlignment: Text.AlignHCenter
                }

                Flickable {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    visible: root.entries.length > 0
                    contentWidth: width
                    contentHeight: clipCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: clipCol
                        width: parent.width
                        spacing: 3

                        Repeater {
                            model: root.entries

                            MouseArea {
                                id: entryArea
                                Layout.fillWidth: true
                                Layout.preferredHeight: 34
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    root.selectedIndex = index
                                    root.copySelected()
                                }

                                readonly property bool isSel: root.selectedIndex === index

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: entryArea.isSel ? Theme.surfaceGlass.lineHi
                                         : (entryArea.containsMouse ? Theme.surfaceGlass.line : "transparent")
                                    border.color: entryArea.isSel ? Theme.accent : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 10

                                        Text {
                                            text: "⧉"
                                            color: entryArea.isSel ? Theme.accentCore : Theme.text.mute
                                            font.pixelSize: 10
                                        }
                                        Text {
                                            text: modelData.preview
                                            color: entryArea.isSel ? Theme.text.text : Theme.text.dim
                                            font.family: Theme.font.family
                                            font.pixelSize: 10.5
                                            Layout.fillWidth: true
                                            elide: Text.ElideRight
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    text: "↑↓ navegar · ↵ copiar · esc cerrar"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 9
                }
            }
        }
        }
    }
}
