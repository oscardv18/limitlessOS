// modules/PackagePanel.qml — Panel visual de paquetes (LIMITLESS-OS.md §6 Fase 4)
//
// Reproduce el panel unificado (#pkg) de docs/mockups/limitless-shell.html:
//   - Conectado a IPC { surfaceName: "pkg" }.
//   - Dos columnas: lista izquierda con paquetes oficiales y AUR, panel derecho con detalles del paquete seleccionado.
import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    IPC {
        id: ipc
        surfaceName: "pkg"
    }

    visible: reveal.active
    anchors.centerIn: parent
    width: 860
    height: 520
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"
    focusable: ipc.shown

    property int selectedIndex: 0
    property var pkgList: []
    property bool loading: false

    // Lista REAL de paquetes instalados. `pacman -Qi` da nombre, versión,
    // descripción y repo de una sola pasada; se filtra a lo instalado
    // porque los ~14.000 disponibles no caben en un panel de QML sin
    // tirones — para BUSCAR e instalar está `dotctl pkg install`, que usa
    // fzf en Go y filtra 90.000 sin despeinarse (spec-package-panel.md §2,
    // donde esta división ya estaba decidida).
    Process {
        id: pkgProc
        command: ["sh", "-c",
            "expac -Q '%n\\t%v\\t%d\\t%r' 2>/dev/null || pacman -Q --color=never | awk '{print $1\"\\t\"$2\"\\t\\t\"}'"]
        stdout: StdioCollector {
            onStreamFinished: {
                var out = []
                var lines = this.text.split("\n")
                for (var i = 0; i < lines.length; i++) {
                    if (lines[i].trim() === "") continue
                    var f = lines[i].split("\t")
                    out.push({
                        name: f[0] || "",
                        ver: f[1] || "",
                        desc: f[2] || "",
                        repo: f[3] || "local",
                        installed: true
                    })
                }
                root.pkgList = out
                root.loading = false
            }
        }
    }

    onVisibleChanged: if (visible && root.pkgList.length === 0) {
        root.loading = true
        pkgProc.running = true
    }

    function filteredPkgs() {
        var q = pkgInput.text.trim().toLowerCase()
        if (q === "") return pkgList
        return pkgList.filter(function(item) {
            return item.name.toLowerCase().indexOf(q) !== -1 ||
                   item.desc.toLowerCase().indexOf(q) !== -1 ||
                   item.repo.toLowerCase().indexOf(q) !== -1
        })
    }

    // Las dos acciones abren una TERMINAL VISIBLE a propósito
    // (spec-package-panel.md §2, regla que aplica pase lo que pase): la
    // contraseña de sudo, la compilación de AUR —que puede tardar 20
    // minutos y a veces pregunta— y los errores de PKGBUILD tienen que
    // verse. "Un panel bonito que se traga un fallo de compilación es
    // peor que un terminal feo que te lo enseña."
    function openInstaller() {
        Quickshell.execDetached(["sh", "-c", "ghostty -e dotctl pkg install"])
        ipc.hide()
    }

    function removeSelected() {
        var item = filteredPkgs()[root.selectedIndex]
        if (!item) return
        Quickshell.execDetached(["sh", "-c", 'ghostty -e dotctl pkg remove "' + item.name + '"'])
        ipc.hide()
    }

    // Keys.onPressed necesita un Item con foco real, no un PanelWindow (es
    // un Window, no un Item) — mismo fix que ControlCenter.qml/Launcher.qml.
    FocusScope {
        id: keyScope
        anchors.fill: parent
        focus: root.visible

    Keys.onPressed: function(event) {
        var items = filteredPkgs()
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
            // Enter abre el buscador de instalación, no elimina: la
            // acción destructiva no debe estar a una tecla de distancia
            root.openInstaller()
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

                Text { text: "▣"; color: Theme.accent; font.pixelSize: 13 }
                Text { text: "PAQUETES INSTALADOS"; color: Theme.text.text; font.family: Theme.font.family; font.pixelSize: 10; font.bold: true; font.letterSpacing: 1.5 }
                Item { Layout.fillWidth: true }
                Text {
                    text: root.loading ? "leyendo…" : (root.pkgList.length + " paquetes")
                    color: Theme.text.mute; font.family: Theme.font.family; font.pixelSize: 9
                }
            }

            // Input
            Rectangle {
                Layout.fillWidth: true
                Layout.preferredHeight: 34
                radius: 8
                color: Theme.surfaceGlass.surfaceHi
                border.color: pkgInput.activeFocus ? Theme.accent : Theme.surfaceGlass.line
                border.width: 1

                RowLayout {
                    anchors.fill: parent
                    anchors.leftMargin: 10
                    anchors.rightMargin: 10
                    spacing: 8

                    Text { text: "◈"; color: Theme.accent; font.pixelSize: 12 }
                    TextInput {
                        id: pkgInput
                        Layout.fillWidth: true
                        color: Theme.text.text
                        font.family: Theme.font.family
                        font.pixelSize: 12
                        clip: true
                        focus: ipc.shown
                        onTextChanged: root.selectedIndex = 0

                        Text {
                            anchors.fill: parent
                            text: "filtrar entre los paquetes instalados…"
                            color: Theme.text.mute
                            font.family: Theme.font.family
                            font.pixelSize: 12
                            visible: pkgInput.text === "" && !pkgInput.activeFocus
                        }
                    }
                }
            }

            Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceGlass.line }

            // División en dos columnas
            RowLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 12

                // Columna izquierda: Lista
                Flickable {
                    Layout.preferredWidth: parent.width * 0.55
                    Layout.fillHeight: true
                    contentWidth: width
                    contentHeight: pkgCol.implicitHeight
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds

                    ColumnLayout {
                        id: pkgCol
                        width: parent.width
                        spacing: 4

                        Repeater {
                            model: root.filteredPkgs()

                            MouseArea {
                                id: pArea
                                Layout.fillWidth: true
                                Layout.preferredHeight: 40
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.selectedIndex = index

                                readonly property bool isSel: root.selectedIndex === index

                                Rectangle {
                                    anchors.fill: parent
                                    radius: 6
                                    color: pArea.isSel ? Theme.surfaceGlass.lineHi : (pArea.containsMouse ? Theme.surfaceGlass.line : "transparent")
                                    border.color: pArea.isSel ? Theme.accent : "transparent"
                                    border.width: 1

                                    RowLayout {
                                        anchors.fill: parent
                                        anchors.leftMargin: 10
                                        anchors.rightMargin: 10
                                        spacing: 8

                                        Text { text: "▣"; color: pArea.isSel ? Theme.accentCore : Theme.text.dim; font.pixelSize: 11 }
                                        Text { text: modelData.name; color: pArea.isSel ? Theme.text.text : Theme.text.text; font.family: Theme.font.family; font.pixelSize: 11; font.bold: pArea.isSel; Layout.fillWidth: true; elide: Text.ElideRight }
                                        Rectangle {
                                            Layout.preferredWidth: rText.implicitWidth + 6
                                            Layout.preferredHeight: 16
                                            radius: 3
                                            color: Theme.surfaceGlass.surface
                                            border.color: modelData.repo === "aur" ? Theme.hollowAccent : Theme.accent
                                            border.width: 1

                                            Text { id: rText; anchors.centerIn: parent; text: modelData.repo; color: modelData.repo === "aur" ? Theme.hollowAccent : Theme.accent; font.pixelSize: 8; font.family: Theme.font.family }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }

                // Separador vertical
                Rectangle {
                    Layout.preferredWidth: 1
                    Layout.fillHeight: true
                    color: Theme.surfaceGlass.line
                }

                // Columna derecha: Detalles
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    spacing: 10

                    readonly property var currentPkg: (root.filteredPkgs().length > root.selectedIndex) ? root.filteredPkgs()[root.selectedIndex] : null

                    Text {
                        text: parent.currentPkg ? parent.currentPkg.name : "Sin selección"
                        color: Theme.accent
                        font.family: Theme.font.family
                        font.pixelSize: 16
                        font.bold: true
                    }

                    Text {
                        text: parent.currentPkg ? "Versión: " + parent.currentPkg.ver + " (" + parent.currentPkg.repo + ")" : ""
                        color: Theme.text.mute
                        font.family: Theme.font.family
                        font.pixelSize: 10
                    }

                    Rectangle { Layout.fillWidth: true; height: 1; color: Theme.surfaceGlass.line }

                    Text {
                        text: parent.currentPkg ? parent.currentPkg.desc : ""
                        color: Theme.text.dim
                        font.family: Theme.font.family
                        font.pixelSize: 11
                        wrapMode: Text.WordWrap
                        Layout.fillWidth: true
                    }

                    Item { Layout.fillHeight: true }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 8

                        // Buscar e instalar abre el buscador fzf en una
                        // terminal: 90.000 paquetes no se filtran desde QML
                        // (spec-package-panel.md §2), y la instalación debe
                        // verse — sudo, compilación de AUR, errores.
                        Rectangle {
                            Layout.preferredWidth: 140
                            Layout.preferredHeight: 28
                            radius: 6
                            color: Theme.accent

                            Text {
                                anchors.centerIn: parent
                                text: "Buscar e instalar"
                                color: Theme.void_
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.openInstaller()
                            }
                        }

                        Rectangle {
                            Layout.preferredWidth: 100
                            Layout.preferredHeight: 28
                            radius: 6
                            color: "transparent"
                            border.color: Theme.reversalAccent
                            border.width: 1

                            Text {
                                anchors.centerIn: parent
                                text: "Eliminar"
                                color: Theme.reversalAccent
                                font.family: Theme.font.family
                                font.pixelSize: 10
                                font.bold: true
                            }

                            MouseArea {
                                anchors.fill: parent
                                hoverEnabled: true
                                cursorShape: Qt.PointingHandCursor
                                onClicked: root.removeSelected()
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
