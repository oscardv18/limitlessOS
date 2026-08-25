import QtQuick
import QtQuick.Layouts
import Quickshell

Panel {
    id: root
    // `shown`, no `visible`: Panel.qml usa visible para mantener la
    // ventana viva mientras dura el fundido de salida
    shown: ipc.shown
    focusable: ipc.shown

    anchors {
        top: true
        right: true
    }
    margins {
        top: 36
        right: 10
    }
    width: 580
    height: 600

    IPC {
        id: ipc
        surfaceName: "control"
    }

    property int activeTab: 0

    // Keys.onPressed necesita un Item con foco activo dentro del árbol de
    // la escena — puesto directo sobre `root` (un PanelWindow, que es un
    // Window, no un Item) no recibía nada. FocusScope + focus:true es el
    // patrón real para que el teclado llegue aquí.
    FocusScope {
        id: keyScope
        anchors.fill: parent
        focus: root.visible

    Keys.onPressed: (event) => {
        if (event.key === Qt.Key_Escape) {
            ipc.hide()
            event.accepted = true
        } else if (event.key === Qt.Key_1) {
            activeTab = 0
            event.accepted = true
        } else if (event.key === Qt.Key_2) {
            activeTab = 1
            event.accepted = true
        } else if (event.key === Qt.Key_3) {
            activeTab = 2
            event.accepted = true
        } else if (event.key === Qt.Key_4) {
            activeTab = 3
            event.accepted = true
        }
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // PHEAD
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 38

            Row {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Text {
                    text: "◉"
                    color: Theme.accent
                    font.family: Theme.font.family
                    font.pixelSize: 12
                }
                Text {
                    text: "CENTRO DE CONTROL"
                    color: Theme.text.text
                    font.family: Theme.font.family
                    font.pixelSize: 12
                    font.letterSpacing: 2
                }
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "1–4 cambia de pestaña"
                color: Theme.text.mute
                font.family: Theme.font.family
                font.pixelSize: 10
            }
        }

        // TABS
        Row {
            Layout.fillWidth: true
            Layout.preferredHeight: 32
            padding: 10
            spacing: 2

            Repeater {
                model: [
                    { name: "RED", icon: "⍄" },
                    { name: "AUDIO", icon: "◨" },
                    { name: "PANTALLAS", icon: "╬" },
                    { name: "CAPTURA", icon: "✚" }
                ]
                delegate: Rectangle {
                    width: 100
                    height: 25
                    color: root.activeTab === index ? Theme.surfaceGlass.lineHi : "transparent"
                    border.color: root.activeTab === index ? Theme.surfaceGlass.line : "transparent"
                    border.width: 1
                    radius: 8

                    Row {
                        anchors.centerIn: parent
                        spacing: 7
                        Text {
                            text: modelData.icon
                            color: root.activeTab === index ? Theme.accent : Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 11
                        }
                        Text {
                            text: modelData.name
                            color: root.activeTab === index ? Theme.accent : Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            font.letterSpacing: 1.5
                        }
                    }

                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.activeTab = index
                    }
                }
            }
        }

        // LINE
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.surfaceGlass.line
        }

        // SCROLL AREA (Simplified as Item for now)
        Item {
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true

            // RED (Tab 0)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                visible: root.activeTab === 0

                // Toggles
                GridLayout {
                    columns: 2
                    columnSpacing: 8
                    rowSpacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { text: "Wi-Fi", icon: "⍴", state: "ON", on: true },
                            { text: "Bluetooth", icon: "✔", state: "ON", on: true },
                            { text: "VPN", icon: "⛤", state: "OFF", on: false },
                            { text: "Modo avión", icon: "☈", state: "OFF", on: false }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 36
                            radius: 11
                            color: modelData.on ? Theme.state.diffText : Theme.surfaceGlass.lineHi
                            border.color: modelData.on ? Theme.accent : Theme.surfaceGlass.line
                            border.width: 1

                            RowLayout {
                                anchors.fill: parent
                                anchors.margins: 12
                                spacing: 10

                                Text {
                                    text: modelData.icon
                                    color: modelData.on ? Theme.accent : Theme.text.dim
                                    font.family: Theme.font.family
                                    font.pixelSize: 14
                                }
                                Text {
                                    text: modelData.text
                                    color: modelData.on ? Theme.text.text : Theme.text.dim
                                    font.family: Theme.font.family
                                    font.pixelSize: 10
                                }
                                Item { Layout.fillWidth: true }
                                Text {
                                    text: modelData.state
                                    color: modelData.on ? Theme.accent : Theme.text.mute
                                    font.family: Theme.font.family
                                    font.pixelSize: 8
                                    font.letterSpacing: 1.5
                                }
                            }
                        }
                    }
                }

                // Networks list placeholder
                Text {
                    text: "REDES DISPONIBLES"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 9
                    font.letterSpacing: 2
                }
                Item { Layout.fillHeight: true }
            }

            // AUDIO (Tab 1)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                visible: root.activeTab === 1

                Text { text: "AUDIO MODULE"; color: Theme.text.text }
                Item { Layout.fillHeight: true }
            }

            // MONITORS (Tab 2)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                visible: root.activeTab === 2

                Text { text: "PANTALLAS MODULE"; color: Theme.text.text }
                Item { Layout.fillHeight: true }
            }

            // CAPTURE (Tab 3)
            ColumnLayout {
                anchors.fill: parent
                anchors.margins: 16
                spacing: 14
                visible: root.activeTab === 3

                // Capture buttons
                GridLayout {
                    columns: 3
                    columnSpacing: 8
                    rowSpacing: 8
                    Layout.fillWidth: true

                    Repeater {
                        model: [
                            { text: "REGIÓN", icon: "✺", key: "super + shift + s" },
                            { text: "VENTANA", icon: "╠", key: "super + shift + w" },
                            { text: "PANTALLA", icon: "╬", key: "impr pant" },
                            { text: "GRABAR", icon: "⏱", key: "super + shift + r" },
                            { text: "GIF", icon: "◫", key: "super + shift + g" },
                            { text: "TEXTO OCR", icon: "⌗", key: "super + shift + t" }
                        ]
                        delegate: Rectangle {
                            Layout.fillWidth: true
                            Layout.preferredHeight: 60
                            radius: 10
                            color: Theme.surfaceGlass.lineHi
                            border.color: Theme.surfaceGlass.line
                            border.width: 1

                            ColumnLayout {
                                anchors.centerIn: parent
                                spacing: 4
                                Text {
                                    text: modelData.icon
                                    color: Theme.accent
                                    font.family: Theme.font.family
                                    font.pixelSize: 19
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.text
                                    color: Theme.text.dim
                                    font.family: Theme.font.family
                                    font.pixelSize: 9
                                    font.letterSpacing: 1
                                    Layout.alignment: Qt.AlignHCenter
                                }
                                Text {
                                    text: modelData.key
                                    color: Theme.text.mute
                                    font.family: Theme.font.family
                                    font.pixelSize: 7.5
                                    Layout.alignment: Qt.AlignHCenter
                                }
                            }
                        }
                    }
                }
                
                Item { Layout.fillHeight: true }
            }
        }

        // FOOTER
        Rectangle {
            Layout.fillWidth: true
            Layout.preferredHeight: 1
            color: Theme.surfaceGlass.line
        }
        Item {
            Layout.fillWidth: true
            Layout.preferredHeight: 38
            
            Text {
                anchors.left: parent.left
                anchors.leftMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "nmcli · wpctl · hyprctl monitors · grim+slurp+satty"
                color: Theme.text.mute
                font.family: Theme.font.family
                font.pixelSize: 10
            }
            Text {
                anchors.right: parent.right
                anchors.rightMargin: 16
                anchors.verticalCenter: parent.verticalCenter
                text: "esc"
                color: Theme.text.dim
                font.family: Theme.font.family
                font.pixelSize: 10
            }
        }
    }
    }
}
