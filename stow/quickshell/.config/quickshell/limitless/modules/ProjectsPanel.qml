import QtQuick
import QtQuick.Layouts
import QtQuick.Controls

Panel {
    id: root
    width: 880
    height: 560
    // `shown`, no `visible` — ver Panel.qml
    shown: ipc.shown

    anchors.centerIn: parent

    IPC { id: ipc; surfaceName: "projects" }

    property string searchQuery: ""
    property int selectedIndex: 0
    property var currentItem: (filteredModel.count > 0 && selectedIndex >= 0 && selectedIndex < filteredModel.count) ? filteredModel.get(selectedIndex) : null

    // Proyectos REALES de ~/dev (o $LIMITLESS_PROJECTS_DIR). De cada uno
    // se lee su estado de git de verdad: rama, cambios sin commitear, y
    // adelanto/atraso respecto al remoto.
    //
    // `tests` NO está: no hay forma genérica de saber el estado de las
    // pruebas de un repo cualquiera sin ejecutarlas — y ejecutar las
    // pruebas de seis proyectos cada vez que abres un panel es
    // inaceptable. El mockup lo enseñaba porque era una maqueta; aquí se
    // omite en vez de inventarlo.
    property var rawData: []
    property bool scanning: false

    Process {
        id: scanProc
        // El script va en UNA línea a propósito: QML/JS no tiene comillas
        // triples, y una cadena multilínea aquí es un error de sintaxis
        // que no se ve hasta que el shell intenta cargar el archivo.
        // Se delega en `dotctl dev scan`, que además hace esto reutilizable
        // desde la terminal — la lógica de git no debe vivir en el QML.
        command: ["dotctl", "dev", "scan"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "") continue
                    var f = lines[i].split("\t")
                    out.push({
                        n: f[0] || "",
                        branch: f[1] || "—",
                        dirty: parseInt(f[2]) || 0,
                        ahead: parseInt(f[3]) || 0,
                        behind: parseInt(f[4]) || 0,
                        last: f[5] || "—",
                        lang: "",
                        desc: ""
                    })
                }
                root.rawData = out
                root.scanning = false
                root.updateFilter()
            }
        }
    }

    onVisibleChanged: if (visible) {
        root.scanning = true
        scanProc.running = true
    }

    ListModel { id: filteredModel }

    function updateFilter() {
        filteredModel.clear()
        for (var i = 0; i < rawData.length; i++) {
            var item = rawData[i]
            var matchStr = (item.n + " " + item.branch).toLowerCase()
            if (root.searchQuery === "" || matchStr.indexOf(root.searchQuery.toLowerCase()) !== -1) {
                filteredModel.append(item)
            }
        }
        if (root.selectedIndex >= filteredModel.count) {
            root.selectedIndex = Math.max(0, filteredModel.count - 1)
        }
    }

    onSearchQueryChanged: root.updateFilter()
    Component.onCompleted: root.updateFilter()

    ColumnLayout {
        anchors.fill: parent
        spacing: 0

        // phead top
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "transparent"
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 8
                Text {
                    text: "⑂"
                    color: Theme.accent
                    font.family: Theme.font.family
                    font.pixelSize: 12
                }
                Text {
                    text: "PROYECTOS · SESIÓN DE TRABAJO"
                    color: Theme.text.text
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    font.weight: Font.DemiBold
                    font.letterSpacing: 1
                }
                Item { Layout.fillWidth: true }
                Text {
                    text: "~/dev"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 10
                }
            }
        }

        // qbar
        Rectangle {
            Layout.fillWidth: true
            height: 40
            color: "transparent"
            Rectangle {
                anchors.bottom: parent.bottom
                width: parent.width
                height: 1
                color: Theme.surfaceGlass.line
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 11
                Text {
                    text: "❯"
                    color: Theme.accent
                    font.family: Theme.font.family
                    font.pixelSize: 12
                }
                TextInput {
                    id: searchInput
                    Layout.fillWidth: true
                    color: Theme.text.text
                    font.family: Theme.font.family
                    font.pixelSize: 13
                    focus: root.visible

                    Text {
                        text: "abrir proyecto…"
                        color: Theme.text.mute
                        font.family: Theme.font.family
                        font.pixelSize: 13
                        visible: parent.text.length === 0 && !parent.activeFocus
                    }

                    onTextChanged: root.searchQuery = text
                    Keys.onUpPressed: { root.selectedIndex = Math.max(0, root.selectedIndex - 1) }
                    Keys.onDownPressed: { root.selectedIndex = Math.min(filteredModel.count - 1, root.selectedIndex + 1) }
                    Keys.onEscapePressed: { ipc.hide() }
                }
            }
        }

        // split
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 0

            // dlist
            Item {
                Layout.fillWidth: true
                Layout.fillHeight: true

                Text {
                    text: "sin coincidencias"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 10
                    anchors.top: parent.top
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.margins: 24
                    visible: filteredModel.count === 0
                }

                ListView {
                    id: dlist
                    anchors.fill: parent
                    anchors.topMargin: 6
                    anchors.bottomMargin: 6
                    clip: true
                    model: filteredModel
                    
                    delegate: Rectangle {
                        width: ListView.view.width
                        height: 32
                        
                        property bool isSelected: root.selectedIndex === index

                        color: isSelected ? Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.15) : "transparent"
                        
                        Rectangle {
                            width: 2
                            height: parent.height
                            color: isSelected ? Theme.accent : "transparent"
                        }

                        RowLayout {
                            anchors.fill: parent
                            anchors.leftMargin: 14
                            anchors.rightMargin: 14
                            spacing: 10

                            Text {
                                text: "⑂"
                                color: isSelected ? Theme.accent : Theme.text.dim
                                font.family: Theme.font.family
                                font.pixelSize: 12
                                Layout.preferredWidth: 18
                                horizontalAlignment: Text.AlignHCenter
                            }
                            Text {
                                text: model.n
                                color: isSelected ? Theme.text.text : Theme.text.dim
                                font.family: Theme.font.family
                                font.pixelSize: 10.5
                                font.weight: isSelected ? Font.DemiBold : Font.Normal
                                Layout.fillWidth: true
                            }
                            Rectangle {
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.color: Theme.surfaceGlass.line
                                border.width: 1
                                radius: 4
                                Layout.preferredWidth: langText.implicitWidth + 12
                                Layout.preferredHeight: langText.implicitHeight + 4
                                Text {
                                    id: langText
                                    anchors.centerIn: parent
                                    text: model.branch
                                    color: Theme.text.dim
                                    font.family: Theme.font.family
                                    font.pixelSize: 8.5
                                }
                            }
                            Rectangle {
                                visible: model.dirty > 0
                                color: "transparent"
                                border.color: Qt.rgba(255/255, 74/255, 46/255, 0.3)
                                border.width: 1
                                radius: 4
                                Layout.preferredWidth: dirtyText.implicitWidth + 12
                                Layout.preferredHeight: dirtyText.implicitHeight + 4
                                Text {
                                    id: dirtyText
                                    anchors.centerIn: parent
                                    text: model.dirty + "±"
                                    color: Theme.reversalAccent
                                    font.family: Theme.font.family
                                    font.pixelSize: 8.5
                                }
                            }
                            Text {
                                text: model.last
                                color: Theme.text.mute
                                font.family: Theme.font.family
                                font.pixelSize: 9
                                Layout.preferredWidth: 70
                                horizontalAlignment: Text.AlignRight
                            }
                        }

                        MouseArea {
                            anchors.fill: parent
                            onClicked: {
                                root.selectedIndex = index
                                searchInput.forceActiveFocus()
                            }
                        }
                    }
                }
            }

            Rectangle {
                Layout.fillHeight: true
                width: 1
                color: Theme.surfaceGlass.line
            }

            // dside
            ScrollView {
                Layout.preferredWidth: 320
                Layout.fillHeight: true
                clip: true
                
                ColumnLayout {
                    width: parent.width - 28
                    x: 14
                    y: 14
                    spacing: 18
                    visible: root.currentItem !== null
                    
                    ColumnLayout {
                        spacing: 6
                        Text {
                            text: "PROYECTO"
                            color: Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 8
                            font.letterSpacing: 1.6
                        }
                        Text {
                            text: root.currentItem ? root.currentItem.n : ""
                            color: Theme.text.text
                            font.family: Theme.font.family
                            font.pixelSize: 16
                            font.weight: Font.DemiBold
                        }
                    }

                    Flow {
                        Layout.fillWidth: true
                        spacing: 6

                        Rectangle {
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.color: (root.currentItem && root.currentItem.dirty > 0) ? Qt.rgba(255/255, 74/255, 46/255, 0.3) : Qt.rgba(59/255, 158/255, 255/255, 0.3)
                            border.width: 1
                            radius: 4
                            width: chipText1.implicitWidth + 14
                            height: chipText1.implicitHeight + 6
                            Text {
                                id: chipText1
                                anchors.centerIn: parent
                                text: (root.currentItem && root.currentItem.dirty > 0) ? root.currentItem.dirty + " sin commitear" : "limpio"
                                color: (root.currentItem && root.currentItem.dirty > 0) ? Theme.reversalAccent : Theme.lapseAccent
                                font.family: Theme.font.family
                                font.pixelSize: 8
                            }
                        }
                        Rectangle {
                            visible: root.currentItem && root.currentItem.ahead > 0
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.color: Qt.rgba(169/255, 112/255, 255/255, 0.3)
                            border.width: 1
                            radius: 4
                            width: chipText2.implicitWidth + 14
                            height: chipText2.implicitHeight + 6
                            Text {
                                id: chipText2
                                anchors.centerIn: parent
                                text: root.currentItem ? "↑" + root.currentItem.ahead : ""
                                color: Theme.hollowAccent
                                font.family: Theme.font.family
                                font.pixelSize: 8
                            }
                        }
                        Rectangle {
                            visible: root.currentItem && root.currentItem.behind > 0
                            color: Qt.rgba(1, 1, 1, 0.03)
                            border.color: Theme.surfaceGlass.line
                            border.width: 1
                            radius: 4
                            width: chipText3.implicitWidth + 14
                            height: chipText3.implicitHeight + 6
                            Text {
                                id: chipText3
                                anchors.centerIn: parent
                                text: root.currentItem ? "↓" + root.currentItem.behind : ""
                                color: Theme.text.dim
                                font.family: Theme.font.family
                                font.pixelSize: 8
                            }
                        }
                    }

                    GridLayout {
                        columns: 2
                        columnSpacing: 6
                        rowSpacing: 6

                        Text { text: "rama"; color: Theme.text.mute; font.family: Theme.font.family; font.pixelSize: 9.5; Layout.preferredWidth: 60 }
                        Text { text: root.currentItem ? root.currentItem.branch : ""; color: Theme.text.dim; font.family: Theme.font.family; font.pixelSize: 9.5; Layout.fillWidth: true }
                        
                        Text { text: "sin commitear"; color: Theme.text.mute; font.family: Theme.font.family; font.pixelSize: 9.5; Layout.preferredWidth: 60 }
                        Text {
                            text: root.currentItem ? (root.currentItem.dirty + " archivo" + (root.currentItem.dirty === 1 ? "" : "s")) : ""
                            color: (root.currentItem && root.currentItem.dirty > 0) ? Theme.reversalAccent : Theme.text.dim
                            font.family: Theme.font.family; font.pixelSize: 9.5; Layout.fillWidth: true
                        }

                        Text { text: "commit"; color: Theme.text.mute; font.family: Theme.font.family; font.pixelSize: 9.5; Layout.preferredWidth: 60 }
                        Text { text: root.currentItem ? root.currentItem.last : ""; color: Theme.text.dim; font.family: Theme.font.family; font.pixelSize: 9.5; Layout.fillWidth: true }
                    }

                    Text {
                        Layout.fillWidth: true
                        wrapMode: Text.WordWrap
                        text: ""
                        visible: false
                        color: Theme.text.dim
                        font.family: Theme.font.family
                        font.pixelSize: 10
                        lineHeight: 1.6
                    }

                    ColumnLayout {
                        spacing: 6
                        Text {
                            text: "ACTIVIDAD · 14 DÍAS"
                            color: Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 8
                            font.letterSpacing: 1.6
                        }
                        RowLayout {
                            Layout.fillWidth: true
                            height: 24
                            spacing: 2
                            Repeater {
                                model: 14
                                Rectangle {
                                    Layout.fillWidth: true
                                    Layout.alignment: Qt.AlignBottom
                                    property real rh: 0.18 + Math.random() * 0.82
                                    height: 24 * rh
                                    color: Theme.accent
                                    opacity: 0.4
                                    radius: 2
                                }
                            }
                        }
                    }

                    ColumnLayout {
                        spacing: 6
                        Text {
                            text: "SESIÓN A RESTAURAR"
                            color: Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 8
                            font.letterSpacing: 1.6
                        }
                        GridLayout {
                            Layout.fillWidth: true
                            height: 50
                            columns: 2
                            rows: 2
                            columnSpacing: 4
                            rowSpacing: 4
                            
                            Rectangle {
                                Layout.rowSpan: 2
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.color: Theme.surfaceGlass.line
                                border.width: 1
                                radius: 4
                                Text {
                                    anchors.centerIn: parent
                                    text: "EDITOR"
                                    color: Theme.text.mute
                                    font.family: Theme.font.family
                                    font.pixelSize: 7
                                    font.letterSpacing: 1.4
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.color: Theme.surfaceGlass.line
                                border.width: 1
                                radius: 4
                                Text {
                                    anchors.centerIn: parent
                                    text: "SERVIDOR"
                                    color: Theme.text.mute
                                    font.family: Theme.font.family
                                    font.pixelSize: 7
                                    font.letterSpacing: 1.4
                                }
                            }
                            Rectangle {
                                Layout.fillWidth: true
                                Layout.fillHeight: true
                                color: Qt.rgba(1, 1, 1, 0.03)
                                border.color: Theme.surfaceGlass.line
                                border.width: 1
                                radius: 4
                                Text {
                                    anchors.centerIn: parent
                                    text: "GIT"
                                    color: Theme.text.mute
                                    font.family: Theme.font.family
                                    font.pixelSize: 7
                                    font.letterSpacing: 1.4
                                }
                            }
                        }
                    }

                    Item { Layout.fillHeight: true; height: 14 }
                }
            }
        }

        // phead bottom
        Rectangle {
            Layout.fillWidth: true
            height: 38
            color: "transparent"
            Rectangle {
                anchors.top: parent.top
                width: parent.width
                height: 1
                color: Theme.surfaceGlass.line
            }
            RowLayout {
                anchors.fill: parent
                anchors.margins: 14
                spacing: 6
                Text {
                    text: "↵ restaura el layout, la rama y el terminal del proyecto"
                    color: Theme.text.mute
                    font.family: Theme.font.family
                    font.pixelSize: 10
                }
                Item { Layout.fillWidth: true }
                
                Rectangle {
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Theme.surfaceGlass.line
                    border.width: 1
                    radius: 4
                    Layout.preferredWidth: kbd1Text.implicitWidth + 12
                    Layout.preferredHeight: kbd1Text.implicitHeight + 4
                    Text {
                        id: kbd1Text
                        anchors.centerIn: parent
                        text: "↵"
                        color: Theme.text.dim
                        font.family: Theme.font.family
                        font.pixelSize: 9
                    }
                }
                Rectangle {
                    color: Qt.rgba(1, 1, 1, 0.05)
                    border.color: Theme.surfaceGlass.line
                    border.width: 1
                    radius: 4
                    Layout.preferredWidth: kbd2Text.implicitWidth + 12
                    Layout.preferredHeight: kbd2Text.implicitHeight + 4
                    Text {
                        id: kbd2Text
                        anchors.centerIn: parent
                        text: "esc"
                        color: Theme.text.dim
                        font.family: Theme.font.family
                        font.pixelSize: 9
                    }
                }
            }
        }
    }
}
