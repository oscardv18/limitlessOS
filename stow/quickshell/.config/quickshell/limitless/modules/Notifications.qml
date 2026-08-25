// modules/Notifications.qml — contenedor de notificaciones emergentes (toasts)
// (Fase 4, reparto-tareas.md: notificaciones)
import QtQuick
import Quickshell
import Quickshell.Services.Notifications

PanelWindow {
    id: root

    anchors {
        top: true
        right: true
    }
    margins {
        top: 40
        right: 18
    }

    width: 296
    height: Math.max(1, listView.contentHeight)

    color: "transparent"
    focusable: false

    NotificationServer {
        id: server
        actionsSupported: true
        bodyMarkupSupported: true

        onNotification: notif => {
            // sin esto, Quickshell descarta la notificación justo después
            // de este handler (contrato documentado de NotificationServer:
            // "if this notification should not be discarded, set tracked
            // to true") — faltaba, y el toast nunca llegaba a pintar nada.
            notif.tracked = true;
            var arr = root.notifArray;
            arr.push(notif);
            root.notifArray = arr;
        }
    }

    property var notifArray: []

    function removeNotification(notif) {
        var arr = root.notifArray;
        var idx = arr.indexOf(notif);
        if (idx !== -1) {
            arr.splice(idx, 1);
            root.notifArray = arr;
        }
        notif.tracked = false;
    }

    ListView {
        id: listView
        width: parent.width
        height: contentHeight
        spacing: 8
        model: root.notifArray
        interactive: false // es overlay, no scrolleable por defecto

        add: Transition {
            NumberAnimation { property: "opacity"; from: 0; to: 1; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; from: 24; to: 0; duration: 360; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; from: 0.96; to: 1; duration: 360; easing.type: Easing.OutCubic }
        }
        remove: Transition {
            NumberAnimation { property: "opacity"; to: 0; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { property: "x"; to: 24; duration: 300; easing.type: Easing.OutCubic }
            NumberAnimation { property: "scale"; to: 0.96; duration: 300; easing.type: Easing.OutCubic }
        }

        delegate: Item {
            id: delegateRoot
            width: ListView.view.width
            height: glass.height
            
            property var notif: modelData

            Timer {
                id: autoCloseTimer
                interval: 5000
                running: delegateRoot.notif.urgency !== 2
                onTriggered: root.removeNotification(delegateRoot.notif)
            }

            Connections {
                target: delegateRoot.notif
                function onTrackedChanged() {
                    if (!delegateRoot.notif.tracked) {
                        var arr = root.notifArray;
                        var idx = arr.indexOf(delegateRoot.notif);
                        if (idx !== -1) {
                            arr.splice(idx, 1);
                            root.notifArray = arr;
                        }
                    }
                }
            }

            GlassSurface {
                id: glass
                width: parent.width
                height: contentCol.height + 22
                cornerRadius: 11
                compact: true

                Rectangle {
                    id: accentLeft
                    width: 2
                    anchors.left: parent.left
                    anchors.top: parent.top
                    anchors.bottom: parent.bottom
                    color: Theme.accent
                    radius: 2
                }

                Column {
                    id: contentCol
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 11
                    anchors.leftMargin: 13
                    anchors.rightMargin: 13
                    spacing: 5
                    
                    Row {
                        spacing: 7
                        Text {
                            text: delegateRoot.notif.appName !== "" ? delegateRoot.notif.appName : "Sistema"
                            color: Theme.accent
                            font.family: Theme.font.family
                            font.pixelSize: 9
                            font.letterSpacing: 1.62
                        }
                    }

                    Row {
                        spacing: 11
                        width: parent.width

                        Image {
                            id: img
                            source: delegateRoot.notif.image || delegateRoot.notif.appIcon || ""
                            width: source !== "" ? 32 : 0
                            height: 32
                            visible: source !== ""
                            fillMode: Image.PreserveAspectCrop
                            anchors.verticalCenter: parent.verticalCenter
                        }

                        Column {
                            width: parent.width - (img.visible ? img.width + 11 : 0)
                            spacing: 3

                            Text {
                                text: delegateRoot.notif.summary
                                color: Theme.text.text
                                font.family: Theme.font.family
                                font.pixelSize: 10.5
                                font.bold: true
                                width: parent.width
                                wrapMode: Text.Wrap
                                visible: text !== ""
                            }

                            Text {
                                text: delegateRoot.notif.body
                                color: Theme.text.dim
                                font.family: Theme.font.family
                                font.pixelSize: 10.5
                                width: parent.width
                                wrapMode: Text.Wrap
                                visible: text !== ""
                                textFormat: Text.RichText
                            }
                        }
                    }
                }

                Rectangle {
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 6
                    width: 16
                    height: 16
                    color: "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "×"
                        color: Theme.text.mute
                        font.pixelSize: 14
                    }
                    MouseArea {
                        anchors.fill: parent
                        onClicked: root.removeNotification(delegateRoot.notif)
                    }
                }
            }
        }
    }
}
