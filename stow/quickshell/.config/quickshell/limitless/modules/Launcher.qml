// modules/Launcher.qml — Buscador y lanzador global (SUPER+SPACE) (LIMITLESS-OS.md §6 Fase 4)
//
// Reproduce el lanzador HUD (#launcher / #core) de docs/mockups/limitless-shell.html:
//   - Anclado en el centro de la pantalla con fondo modal translúcido.
//   - Orbe central "六眼" (Seis Ojos) con campo de búsqueda interactivo.
//   - Lista de resultados filtrados en tiempo real (aplicaciones, herramientas TUI, comandos rápidos).
//   - Navegación ágil por teclado (Flechas Arriba/Abajo, Enter para ejecutar, Escape para cerrar).
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    IPC {
        id: ipc
        surfaceName: "launcher"
    }

    visible: reveal.active
    anchors.centerIn: parent
    width: 620
    height: 520
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: ipc.shown

    property int selectedIndex: 0
    // glifos geométricos, nunca emoji (identidad visual, CLAUDE.md) — mismo
    // criterio que el resto del shell. dotctl ya es invocable por nombre
    // suelto (symlink en /usr/local/bin, install/stages/40-stow.sh); discord
    // no lo está a propósito, se resuelve por ruta absoluta con $HOME.
    property var appList: [
        { name: "Ghostty", desc: "Terminal acelerado por GPU", glyph: "◫", cmd: "ghostty", cat: "SISTEMA" },
        { name: "Neovim", desc: "Editor extensible en Lua", glyph: "◈", cmd: "ghostty -e nvim", cat: "DESARROLLO" },
        { name: "Firefox", desc: "Navegador web principal", glyph: "⊙", cmd: "firefox", cat: "INTERNET" },
        { name: "Discord", desc: "Comunicación y comunidades", glyph: "◆", cmd: '"$HOME/.limitless/bin/discord-wayland"', cat: "COMUNICACIÓN" },
        { name: "Spotify", desc: "Reproductor de música", glyph: "♪", cmd: "spotify", cat: "MEDIOS" },
        { name: "Lazygit", desc: "Interfaz TUI para control de versiones", glyph: "⑂", cmd: "ghostty -e lazygit", cat: "DESARROLLO" },
        { name: "Btop", desc: "Monitor de recursos del sistema", glyph: "◧", cmd: "ghostty -e btop", cat: "SISTEMA" },
        { name: "Yazi", desc: "Gestor de archivos ultrarrápido en terminal", glyph: "▣", cmd: "ghostty -e yazi", cat: "UTILIDADES" },
        { name: "dotctl doctor", desc: "Diagnóstico integral del sistema", glyph: "⚙", cmd: "dotctl doctor", cat: "SISTEMA" },
        { name: "dotctl pkg", desc: "Gestor interactivo de paquetes oficiales y AUR", glyph: "▣", cmd: "dotctl pkg", cat: "SISTEMA" }
    ]

    function filteredApps() {
        var q = searchInput.text.trim().toLowerCase()
        if (q === "") return appList
        return appList.filter(function(item) {
            return item.name.toLowerCase().indexOf(q) !== -1 ||
                   item.desc.toLowerCase().indexOf(q) !== -1 ||
                   item.cat.toLowerCase().indexOf(q) !== -1
        })
    }

    function launch(item) {
        Quickshell.execDetached(["sh", "-c", item.cmd])
        ipc.hide()
    }

    // Keys.onPressed necesita un Item con foco real, no un PanelWindow (es
    // un Window, no un Item) — mismo fix que ya se aplicó en ControlCenter.qml.
    FocusScope {
        id: keyScope
        anchors.fill: parent
        focus: root.visible

    Keys.onPressed: function(event) {
        var items = filteredApps()
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
                root.launch(items[root.selectedIndex])
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
        cornerRadius: 18

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: 18
            spacing: 14

            // ── Cabecera HUD: Seis Ojos (六眼) y Buscador ─────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 12

                // Emblema Seis Ojos
                Rectangle {
                    Layout.preferredWidth: 36
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Theme.surfaceGlass.surfaceHi
                    border.color: Theme.surfaceGlass.line
                    border.width: 1

                    Text {
                        anchors.centerIn: parent
                        text: "六眼"
                        color: Theme.sixEyes
                        font.family: Theme.font.jp
                        font.pixelSize: 13
                    }
                }

                // Campo de texto de búsqueda
                Rectangle {
                    Layout.fillWidth: true
                    Layout.preferredHeight: 36
                    radius: 10
                    color: Theme.surfaceGlass.surfaceHi
                    border.color: searchInput.activeFocus ? Theme.accent : Theme.surfaceGlass.line
                    border.width: 1

                    RowLayout {
                        anchors.fill: parent
                        anchors.leftMargin: 12
                        anchors.rightMargin: 12
                        spacing: 8

                        Text {
                            text: "❯"
                            color: Theme.accent
                            font.family: Theme.font.family
                            font.pixelSize: 13
                        }

                        TextInput {
                            id: searchInput
                            Layout.fillWidth: true
                            color: Theme.text.text
                            font.family: Theme.font.family
                            font.pixelSize: 13
                            font.weight: Font.Light
                            clip: true
                            focus: ipc.shown
                            onTextChanged: root.selectedIndex = 0

                            Text {
                                anchors.fill: parent
                                text: "escribe para buscar aplicaciones, comandos o TUIs…"
                                color: Theme.text.mute
                                font.family: Theme.font.family
                                font.pixelSize: 13
                                font.weight: Font.Light
                                visible: searchInput.text === "" && !searchInput.activeFocus
                            }
                        }
                    }
                }
            }

            // Separador
            Rectangle {
                Layout.fillWidth: true
                height: 1
                color: Theme.surfaceGlass.line
            }

            // ── Lista de Resultados ─────────────────────────────────────
            Flickable {
                Layout.fillWidth: true
                Layout.fillHeight: true
                contentWidth: width
                contentHeight: resultCol.implicitHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds

                ColumnLayout {
                    id: resultCol
                    width: parent.width
                    spacing: 4

                    Repeater {
                        model: root.filteredApps()

                        MouseArea {
                            id: rowArea
                            Layout.fillWidth: true
                            Layout.preferredHeight: 46
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                root.selectedIndex = index
                                root.launch(modelData)
                            }

                            readonly property bool isSel: root.selectedIndex === index

                            Rectangle {
                                anchors.fill: parent
                                radius: 8
                                color: rowArea.isSel ? Theme.surfaceGlass.lineHi : (rowArea.containsMouse ? Theme.surfaceGlass.line : "transparent")
                                border.color: rowArea.isSel ? Theme.accent : "transparent"
                                border.width: 1

                                RowLayout {
                                    anchors.fill: parent
                                    anchors.leftMargin: 12
                                    anchors.rightMargin: 12
                                    spacing: 12

                                    // Glifo
                                    Text {
                                        text: modelData.glyph
                                        color: rowArea.isSel ? Theme.accentCore : Theme.accent
                                        font.family: Theme.font.family
                                        font.pixelSize: 16
                                    }

                                    // Nombre y Descripción
                                    ColumnLayout {
                                        Layout.fillWidth: true
                                        spacing: 2

                                        Text {
                                            text: modelData.name
                                            color: rowArea.isSel ? Theme.text.text : Theme.text.text
                                            font.family: Theme.font.family
                                            font.pixelSize: 12
                                            font.bold: rowArea.isSel
                                        }

                                        Text {
                                            text: modelData.desc
                                            color: Theme.text.dim
                                            font.family: Theme.font.family
                                            font.pixelSize: 9
                                            elide: Text.ElideRight
                                            Layout.fillWidth: true
                                        }
                                    }

                                    // Categoría
                                    Rectangle {
                                        Layout.preferredWidth: catText.implicitWidth + 8
                                        Layout.preferredHeight: 18
                                        radius: 4
                                        color: Theme.surfaceGlass.surface
                                        border.color: Theme.surfaceGlass.line
                                        border.width: 1

                                        Text {
                                            id: catText
                                            anchors.centerIn: parent
                                            text: modelData.cat
                                            color: Theme.text.mute
                                            font.family: Theme.font.family
                                            font.pixelSize: 8
                                            font.letterSpacing: 0.8
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ── Pie HUD ────────────────────────────────────────────────
            RowLayout {
                Layout.fillWidth: true
                spacing: 8

                Text {
                    text: "↑↓ navegar · ↵ ejecutar · esc cerrar"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 9
                }

                Item { Layout.fillWidth: true }

                Text {
                    text: "SUPER + ESPACIO"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    font.letterSpacing: 1
                }
            }
        }
    }
    }
    }
}
