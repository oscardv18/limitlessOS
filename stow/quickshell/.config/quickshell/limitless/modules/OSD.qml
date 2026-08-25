// modules/OSD.qml
// Contrato IPC:
//   target: "osd"
//   function show(kind: string, value: int): void

import QtQuick
import Quickshell
import Quickshell.Io

PanelWindow {
    id: root

    anchors {
        bottom: true
    }
    margins {
        bottom: 120
    }
    
    width: 220
    height: 38

    color: "transparent"
    focusable: false

    property real vol: 60
    property string kind: "vol"
    property bool active: false

    IpcHandler {
        target: "osd"
        function show(kind: string, value: int): void {
            root.kind = kind
            root.vol = Math.max(0, Math.min(100, value))
            root.active = true
            hideTimer.restart()
        }
    }

    Timer {
        id: hideTimer
        interval: 1400
        onTriggered: root.active = false
    }

    Rectangle {
        id: pill
        anchors.centerIn: parent
        width: parent.width
        height: parent.height
        radius: 19

        color: Theme.surfaceGlass.surfaceHi
        border.color: Theme.surfaceGlass.line
        border.width: 1

        opacity: root.active ? 1 : 0
        scale: root.active ? 1 : 0.9

        Behavior on opacity {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }
        Behavior on scale {
            NumberAnimation { duration: 220; easing.type: Easing.OutQuad }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 20
            anchors.rightMargin: 20
            spacing: 13

            Text {
                id: iconTxt
                font.pixelSize: 15
                color: Theme.accent
                anchors.verticalCenter: parent.verticalCenter
                text: {
                    if (root.kind === "mic") {
                        return root.vol === 0 ? "⊘" : "◍"
                    } else if (root.kind === "bri") {
                        return "◍"
                    } else {
                        return root.vol === 0 ? "⊘" : (root.vol < 40 ? "◧" : "◨")
                    }
                }
                Behavior on color {
                    ColorAnimation { duration: 200 }
                }
            }

            Rectangle {
                id: track
                width: 132
                height: 2
                radius: 1
                color: Theme.surfaceGlass.line
                anchors.verticalCenter: parent.verticalCenter
                clip: true

                Rectangle {
                    id: fill
                    height: parent.height
                    width: (parent.width * root.vol) / 100
                    radius: 1
                    
                    gradient: Gradient {
                        orientation: Gradient.Horizontal
                        GradientStop { position: 0.0; color: Theme.accent }
                        GradientStop { position: 1.0; color: Theme.accentCore }
                    }

                    Behavior on width {
                        NumberAnimation { duration: 160; easing.type: Easing.OutQuad }
                    }
                }
            }

            Text {
                id: numTxt
                width: 26
                font.pixelSize: 10
                color: Theme.text.dim
                text: Math.round(root.vol)
                horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                font.family: Theme.font.family
            }
        }
    }
}
