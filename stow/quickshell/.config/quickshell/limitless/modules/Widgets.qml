import QtQuick
import QtQuick.Layouts
import Quickshell
import Quickshell.Io
import Quickshell.Services.Mpris
import "." as Local

PanelWindow {
    id: root
    
    Local.IPC {
        id: ipc
        surfaceName: "widgets"
    }

    visible: reveal.active

    anchors {
        top: true
        right: true
        bottom: true
    }
    
    margins {
        top: 36
        right: 12
        bottom: 44
    }

    width: 326
    color: "transparent"
    focusable: false

    // ── datos reales ───────────────────────────────────────────────────
    // El reproductor: el primero que esté sonando; si ninguno suena, el
    // primero que exista (así se ve la última pista en pausa en vez de
    // una tarjeta vacía).
    readonly property var player: {
        var ps = Mpris.players
        if (!ps || ps.values === undefined) return null
        for (var i = 0; i < ps.values.length; i++)
            if (ps.values[i].isPlaying) return ps.values[i]
        return ps.values.length > 0 ? ps.values[0] : null
    }

    // Clima por wttr.in — sin clave de API, detecta la ubicación por IP.
    // Si no hay red, `weatherOk` queda en false y la tarjeta lo dice, en
    // vez de enseñar un valor viejo como si fuera de ahora.
    property string weatherTemp: ""
    property string weatherDesc: ""
    property string weatherPlace: ""
    property bool weatherOk: false

    Process {
        id: weatherProc
        command: ["sh", "-c", "curl -s --max-time 8 'wttr.in/?format=%t|%C|%l' 2>/dev/null || true"]
        stdout: StdioCollector {
            onStreamFinished: {
                var parts = this.text.trim().split("|")
                if (parts.length < 3 || parts[0] === "") {
                    root.weatherOk = false
                    return
                }
                root.weatherTemp = parts[0].replace("+", "").trim()
                root.weatherDesc = parts[1].trim()
                root.weatherPlace = parts[2].trim().toUpperCase()
                root.weatherOk = true
            }
        }
    }

    // media hora: el tiempo no cambia más rápido y wttr.in agradece que
    // no lo martilleen
    Timer {
        running: true
        interval: 1800000
        repeat: true
        triggeredOnStart: true
        onTriggered: weatherProc.running = true
    }

    // Fecha real, recalculada cada minuto (barata, y así el calendario no
    // se queda en el día de ayer si dejas la sesión abierta).
    property var now: new Date()
    Timer {
        running: true
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: root.now = new Date()
    }

    readonly property int daysInMonth: new Date(now.getFullYear(), now.getMonth() + 1, 0).getDate()
    // getDay(): 0=domingo. La rejilla empieza en lunes, así que se rota.
    readonly property int firstWeekday: {
        var d = new Date(now.getFullYear(), now.getMonth(), 1).getDay()
        return (d + 6) % 7
    }
    readonly property var monthNames: ["ENERO","FEBRERO","MARZO","ABRIL","MAYO","JUNIO",
                                       "JULIO","AGOSTO","SEPTIEMBRE","OCTUBRE","NOVIEMBRE","DICIEMBRE"]

    // Disco de / — `df` es más simple y portable que parsear /proc/mounts
    property string diskFree: "—"
    property int diskPercent: 0

    Process {
        id: diskProc
        command: ["sh", "-c", "df -BG --output=avail,pcent / | tail -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                var m = this.text.trim().match(/(\d+)G\s+(\d+)%/)
                if (!m) return
                root.diskFree = m[1] + "G"
                root.diskPercent = parseInt(m[2])
            }
        }
    }

    Timer {
        running: true
        interval: 60000
        repeat: true
        triggeredOnStart: true
        onTriggered: diskProc.running = true
    }

    // Notas: un archivo real, una nota por línea. Si no existe, la
    // tarjeta lo dice y explica dónde crearlo.
    property var notes: []

    FileView {
        id: notesFile
        path: (Quickshell.env("HOME") || "") + "/.config/limitless/notas.md"
        watchChanges: true
        onFileChanged: reload()
        onLoaded: {
            var out = []
            var lines = text().split("\n")
            for (var i = 0; i < lines.length; i++) {
                var l = lines[i].trim()
                if (l !== "") out.push(l)
            }
            root.notes = out
        }
        onLoadFailed: root.notes = []
    }

    Local.Reveal {
        id: reveal
        anchors.fill: parent
        shown: ipc.shown

    Flickable {
        anchors.fill: parent
        contentWidth: width
        contentHeight: contentCol.implicitHeight + 20
        clip: true
        boundsBehavior: Flickable.StopAtBounds

        ColumnLayout {
            id: contentCol
            width: parent.width
            spacing: 10
            
            // CARD 1: CLIMA
            Local.GlassSurface {
                Layout.fillWidth: true
                height: weatherLayout.implicitHeight + 28
                cornerRadius: 14

                ColumnLayout {
                    id: weatherLayout
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 11
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "◍"; color: Local.Theme.accent; font.pixelSize: 11 }
                        Text { text: "CLIMA"; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                        Text { text: root.weatherPlace; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; horizontalAlignment: Text.AlignRight; font.family: Local.Theme.font.family; elide: Text.ElideRight; Layout.maximumWidth: 130 }
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 14
                        visible: root.weatherOk
                        Text { text: root.weatherTemp; color: Local.Theme.text.text; font.pixelSize: 34; font.weight: Font.Thin; font.family: Local.Theme.font.family }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: root.weatherDesc; color: Local.Theme.text.text; font.pixelSize: 10; font.family: Local.Theme.font.family; wrapMode: Text.WordWrap; Layout.fillWidth: true }
                            Text { text: "wttr.in · por IP"; color: Local.Theme.text.mute; font.pixelSize: 9; font.family: Local.Theme.font.family }
                        }
                    }

                    // sin red o sin respuesta: se dice, no se inventa
                    Text {
                        Layout.fillWidth: true
                        visible: !root.weatherOk
                        text: "sin datos de clima — ¿hay red?"
                        color: Local.Theme.text.mute
                        font.pixelSize: 10
                        font.family: Local.Theme.font.family
                    }
                }
            }

            // CARD 2: CALENDARIO
            Local.GlassSurface {
                Layout.fillWidth: true
                height: calLayout.implicitHeight + 28
                cornerRadius: 14

                ColumnLayout {
                    id: calLayout
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 11
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: ""; color: Local.Theme.accent; font.pixelSize: 11 }
                        Text { text: "CALENDARIO"; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                        Text { text: root.monthNames[root.now.getMonth()] + " " + root.now.getFullYear(); color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; horizontalAlignment: Text.AlignRight; font.family: Local.Theme.font.family }
                    }
                    
                    GridLayout {
                        Layout.fillWidth: true
                        columns: 7
                        columnSpacing: 3
                        rowSpacing: 3
                        
                        Repeater {
                            model: ["L", "M", "X", "J", "V", "S", "D"]
                            Text { text: modelData; color: Local.Theme.text.mute; font.pixelSize: 7.5; font.letterSpacing: 1; horizontalAlignment: Text.AlignHCenter; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                        }
                        
                        // huecos hasta el primer día del mes, para que los
                        // números caigan bajo su día de la semana correcto
                        Repeater {
                            model: root.firstWeekday
                            Item { Layout.fillWidth: true; height: 20 }
                        }

                        Repeater {
                            model: root.daysInMonth
                            Rectangle {
                                required property int index
                                readonly property bool isToday: (index + 1) === root.now.getDate()
                                Layout.fillWidth: true
                                height: 20
                                color: isToday ? Local.Theme.accent : "transparent"
                                radius: 5
                                Text {
                                    anchors.centerIn: parent
                                    text: parent.index + 1
                                    color: parent.isToday ? Local.Theme.void_ : Local.Theme.text.dim
                                    font.pixelSize: 9
                                    font.bold: parent.isToday
                                    font.family: Local.Theme.font.family
                                }
                            }
                        }
                    }
                    
                    // La agenda tenía tres citas inventadas. No hay fuente
                    // real: haría falta un backend de calendario (khal,
                    // CalDAV…) y este proyecto no ha elegido ninguno. Se
                    // enseña la fecha completa de hoy, que sí es cierta,
                    // en vez de reuniones que no existen.
                    Text {
                        Layout.fillWidth: true
                        text: Qt.formatDateTime(root.now, "dddd, d 'de' MMMM")
                        color: Local.Theme.text.dim
                        font.pixelSize: 10
                        font.family: Local.Theme.font.family
                    }
                }
            }

            // CARD 3: REPRODUCIENDO
            Local.GlassSurface {
                Layout.fillWidth: true
                height: mprisLayout.implicitHeight + 28
                cornerRadius: 14

                ColumnLayout {
                    id: mprisLayout
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 11
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "♪"; color: Local.Theme.accent; font.pixelSize: 11 }
                        Text { text: "REPRODUCIENDO"; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                        Text { text: root.player ? root.player.identity.toLowerCase() : ""; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; horizontalAlignment: Text.AlignRight; font.family: Local.Theme.font.family }
                    }

                    // sin reproductor MPRIS: se dice, no se finge
                    Text {
                        Layout.fillWidth: true
                        visible: !root.player
                        text: "nada sonando"
                        color: Local.Theme.text.mute
                        font.pixelSize: 10
                        font.family: Local.Theme.font.family
                    }

                    RowLayout {
                        Layout.fillWidth: true
                        spacing: 12
                        visible: root.player !== null
                        Rectangle {
                            width: 46; height: 46; radius: 9
                            color: Local.Theme.surfaceGlass.line
                            clip: true
                            // carátula real si el reproductor la publica
                            Image {
                                anchors.fill: parent
                                source: root.player && root.player.trackArtUrl ? root.player.trackArtUrl : ""
                                visible: source !== ""
                                fillMode: Image.PreserveAspectCrop
                            }
                            Text {
                                anchors.centerIn: parent
                                text: "♪"
                                color: Local.Theme.accentCore
                                font.pixelSize: 19
                                visible: !(root.player && root.player.trackArtUrl)
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text { text: root.player ? root.player.trackTitle : ""; color: Local.Theme.text.text; font.pixelSize: 11; elide: Text.ElideRight; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                            Text {
                                text: root.player ? (root.player.trackArtist + (root.player.trackAlbum ? " · " + root.player.trackAlbum : "")) : ""
                                color: Local.Theme.text.mute; font.pixelSize: 9; elide: Text.ElideRight; Layout.fillWidth: true; font.family: Local.Theme.font.family
                            }
                        }
                        // controles que SÍ controlan
                        RowLayout {
                            spacing: 11
                            Text {
                                text: "⏮"; color: Local.Theme.text.dim; font.pixelSize: 12
                                opacity: (root.player && root.player.canGoPrevious) ? 1 : 0.35
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.previous() }
                            }
                            Text {
                                text: (root.player && root.player.isPlaying) ? "⏸" : "▶"
                                color: Local.Theme.accent; font.pixelSize: 12
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.togglePlaying() }
                            }
                            Text {
                                text: "⏭"; color: Local.Theme.text.dim; font.pixelSize: 12
                                opacity: (root.player && root.player.canGoNext) ? 1 : 0.35
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: if (root.player) root.player.next() }
                            }
                        }
                    }

                    Rectangle {
                        Layout.fillWidth: true
                        height: 2
                        color: Local.Theme.surfaceGlass.line
                        radius: 2
                        visible: root.player !== null
                        Rectangle {
                            // progreso real de la pista
                            width: (root.player && root.player.length > 0)
                                   ? parent.width * Math.min(1, root.player.position / root.player.length)
                                   : 0
                            height: parent.height
                            color: Local.Theme.accent
                            radius: 2
                        }
                    }
                }
            }

            // CARD 4: SISTEMA
            Local.GlassSurface {
                Layout.fillWidth: true
                height: sysLayout.implicitHeight + 28
                cornerRadius: 14

                ColumnLayout {
                    id: sysLayout
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 11
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "◫"; color: Local.Theme.accent; font.pixelSize: 11 }
                        Text { text: "SISTEMA"; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 9
                        // CPU/MEM reales (SysInfo, /proc) y disco real (df).
                        // GPU se cayó de la lista a propósito: no hay
                        // fuente portable — nvidia-smi es de NVIDIA y las
                        // AMD/Intel van por rutas de hwmon distintas en
                        // cada equipo. Mejor tres números ciertos que
                        // cuatro con uno inventado.
                        Repeater {
                            model: [
                                { l: "CPU", v: Local.SysInfo.cpuPercent + "%",
                                  p: Local.SysInfo.cpuPercent / 100, hot: Local.SysInfo.cpuPercent > 85 },
                                { l: "MEM", v: Local.SysInfo.memUsedGb.toFixed(1) + "G",
                                  p: Local.SysInfo.memPercent / 100, hot: Local.SysInfo.memPercent > 90 },
                                { l: "DISCO", v: root.diskFree,
                                  p: root.diskPercent / 100, hot: root.diskPercent > 90 }
                            ]
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 10
                                Text { text: modelData.l; color: Local.Theme.text.mute; font.pixelSize: 9; font.letterSpacing: 1; Layout.preferredWidth: 38; font.family: Local.Theme.font.family }
                                Rectangle {
                                    Layout.fillWidth: true
                                    height: 3
                                    color: Local.Theme.surfaceGlass.line
                                    radius: 2
                                    Rectangle {
                                        width: parent.width * modelData.p
                                        height: parent.height
                                        color: modelData.hot ? Local.Theme.state.remove : Local.Theme.accent
                                        radius: 2
                                    }
                                }
                                Text { text: modelData.v; color: Local.Theme.text.dim; font.pixelSize: 9; horizontalAlignment: Text.AlignRight; Layout.preferredWidth: 40; font.family: Local.Theme.font.family }
                            }
                        }
                    }
                }
            }

            // CARD 5: NOTAS RÅPIDAS
            Local.GlassSurface {
                Layout.fillWidth: true
                height: notesLayout.implicitHeight + 28
                cornerRadius: 14

                ColumnLayout {
                    id: notesLayout
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 14 }
                    spacing: 11
                    
                    RowLayout {
                        Layout.fillWidth: true
                        Text { text: "✎"; color: Local.Theme.accent; font.pixelSize: 11 }
                        Text { text: "NOTAS RÁPIDAS"; color: Local.Theme.text.mute; font.pixelSize: 8.5; font.letterSpacing: 2.4; Layout.fillWidth: true; font.family: Local.Theme.font.family }
                    }
                    
                    ColumnLayout {
                        Layout.fillWidth: true
                        spacing: 8
                        // vacío explícito: dice dónde escribirlas
                        Text {
                            Layout.fillWidth: true
                            visible: root.notes.length === 0
                            text: "sin notas — escríbelas en ~/.config/limitless/notas.md"
                            color: Local.Theme.text.mute
                            font.pixelSize: 10
                            font.family: Local.Theme.font.family
                            wrapMode: Text.WordWrap
                        }

                        Repeater {
                            model: root.notes
                            RowLayout {
                                Layout.fillWidth: true
                                spacing: 9
                                Rectangle { width: 1; height: Math.max(16, txt.implicitHeight); color: Local.Theme.surfaceGlass.lineHi }
                                Text { id: txt; text: modelData; color: Local.Theme.text.dim; font.pixelSize: 10; Layout.fillWidth: true; wrapMode: Text.WordWrap; textFormat: Text.RichText; font.family: Local.Theme.font.family }
                            }
                        }
                    }
                }
            }
        }
    }
    }
}