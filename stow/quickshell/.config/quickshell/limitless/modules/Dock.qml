// modules/Dock.qml — Dock en RUEDA (LIMITLESS-OS.md §6 Fase 4)
//
// Traducción de la rueda del mockup (docs/mockups/limitless-shell.html,
// "#dock (rueda real)", CSS 139-175 + JS 1756-1797). NO es una fila de
// iconos: los iconos viven en el borde de una circunferencia enorme cuyo
// centro está MUY por debajo de la pantalla, así que solo se ve el arco
// superior — como la parte de arriba de una noria.
//
// Números tomados verbatim del prototipo, no elegidos a ojo:
//   DOCKR    = 880  radio de la rueda en px
//   DOCKLIFT = 118  cuánto asoma el arco por encima del borde inferior
//   SPREAD   = 0.78 arco (en radianes) que ocupan todos los iconos
//
// Por qué importa cada uno: con un radio pequeño la curva se nota
// demasiado y parece un abanico; con 880 el arco es sutil y los iconos
// se sienten "sobre una superficie curva" sin gritarlo.
//
// La rueda gira con la rueda del ratón (de ahí el nombre) y se detiene
// donde la sueltes, con un acercamiento exponencial al objetivo — no una
// animación de duración fija, que se sentiría rígida.
import QtQuick
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    // SUPER+D fija/suelta el dock, SUPER+SHIFT+D lo esconde
    // (spec-keybinds.md §3.1, enrutado por bin/cmd/shell).
    property bool pinned: false
    property bool hidden: false

    IpcHandler {
        target: "dock"
        function pinToggle(): void { root.pinned = !root.pinned }
        function toggle(): void { root.hidden = !root.hidden }
        function show(): void { root.hidden = false }
        function hide(): void { root.hidden = true }
    }

    readonly property real wheelRadius: 880
    readonly property real wheelLift: 118
    readonly property real spread: 0.78

    // ángulo actual y objetivo de la rueda
    property real angle: 0
    property real targetAngle: 0
    property int hoverIndex: -1

    // cmd vacío ("") = no lanza proceso, dispara IPC a otra superficie
    readonly property var items: [
        { name: "Ghostty",   glyph: "◫", cmd: "ghostty",             ipc: "" },
        { name: "Neovim",    glyph: "◈", cmd: "ghostty -e nvim",     ipc: "" },
        { name: "Navegador", glyph: "⊙", cmd: "firefox",             ipc: "" },
        { name: "Discord",   glyph: "◆", cmd: "\"$HOME/.limitless/bin/discord-wayland\"", ipc: "" },
        { name: "Música",    glyph: "♪", cmd: "ghostty -e rmpc",     ipc: "" },
        { name: "Lazygit",   glyph: "⑂", cmd: "ghostty -e lazygit",  ipc: "" },
        { name: "Btop",      glyph: "◧", cmd: "ghostty -e btop",     ipc: "" },
        { name: "Archivos",  glyph: "▣", cmd: "ghostty -e yazi",     ipc: "" },
        { name: "Ajustes",   glyph: "⚙", cmd: "",                    ipc: "control" }
    ]

    anchors { bottom: true; left: true; right: true }
    // alto = lo que asoma del arco + margen para la magnificación al pasar
    // el ratón; el resto de la circunferencia queda fuera de la ventana
    height: root.wheelLift + 92
    visible: reveal.active
    // la rueda NUNCA reserva espacio: ocupa una franja ancha y las
    // ventanas deben poder usarla. Fijarlo solo cambia si se auto-esconde.
    exclusionMode: ExclusionMode.Ignore
    color: "transparent"

    function launch(item) {
        if (item.ipc !== "") {
            Quickshell.execDetached(["qs", "-c", "limitless", "ipc", "call", item.ipc, "toggle"])
        } else if (item.cmd !== "") {
            Quickshell.execDetached(["sh", "-c", item.cmd])
        }
    }

    // acercamiento exponencial al objetivo (el `* .12` del mockup): cada
    // frame recorre el 12% de lo que falta. Da una parada suave sin fijar
    // una duración, así que un giro corto y uno largo se sienten igual.
    Timer {
        running: Math.abs(root.targetAngle - root.angle) > 0.0004
        interval: 16
        repeat: true
        onTriggered: root.angle += (root.targetAngle - root.angle) * 0.12
    }

    Reveal {
        id: reveal
        anchors.fill: parent
        shown: !root.hidden
        hiddenScale: 1.0

        WheelHandler {
            // girar con la rueda del ratón, con tope a ±1.1 rad para que
            // no se pueda mandar el dock fuera de la vista
            onWheel: function (event) {
                root.targetAngle += (event.angleDelta.y > 0 ? 1 : -1) * 0.16
                root.targetAngle = Math.max(-1.1, Math.min(1.1, root.targetAngle))
            }
        }

        Item {
            id: pivot
            // el centro de la rueda: horizontalmente centrado, y tan por
            // debajo del borde inferior como dice el radio menos lo que
            // debe asomar
            x: parent.width / 2
            y: parent.height + root.wheelRadius - root.wheelLift

            Repeater {
                model: root.items

                Rectangle {
                    id: icon
                    required property int index
                    required property var modelData

                    // ángulo base: repartidos por el arco, centrados
                    // arriba (-π/2 es la vertical hacia arriba)
                    readonly property real baseAngle:
                        -Math.PI / 2 + (index / (root.items.length - 1) - 0.5) * root.spread
                    readonly property real a: baseAngle + root.angle

                    // "cercanía" al punto más alto del arco: 1 en el
                    // centro, 0 en los extremos. Gobierna tamaño y opacidad
                    // para que la rueda se sienta tridimensional.
                    readonly property real near: Math.max(0, Math.cos(a + Math.PI / 2))

                    // magnificación al pasar el ratón, tipo dock de macOS:
                    // el de debajo del cursor crece más, sus vecinos menos.
                    // Es INDEPENDIENTE del ángulo a propósito (el arreglo
                    // que el propio mockup documenta) — si dependiera del
                    // ángulo, los iconos del borde nunca crecerían.
                    readonly property real mag: {
                        if (root.hoverIndex < 0) return 1
                        var d = Math.abs(index - root.hoverIndex)
                        return d === 0 ? 1.42 : d === 1 ? 1.18 : d === 2 ? 1.06 : 1
                    }

                    width: 46
                    height: 46
                    radius: Theme.geometry.radiusIcon
                    // posición sobre la circunferencia
                    x: Math.cos(a) * root.wheelRadius - width / 2
                    y: -(Math.sin(a) * root.wheelRadius + root.wheelRadius - root.wheelLift) - height / 2
                    scale: (0.72 + near * 0.5) * mag
                    opacity: Math.max(0.1, near)
                    z: 200 + Math.round(near * 60) + (root.hoverIndex === index ? 40 : 0)

                    color: Theme.surfaceGlass.surfaceHi
                    border.color: mouse.containsMouse ? Theme.accent : Theme.surfaceGlass.line
                    border.width: 1

                    Behavior on scale {
                        NumberAnimation { duration: Theme.animFast; easing.type: Easing.BezierSpline; easing.bezierCurve: Theme.animCurve }
                    }
                    Behavior on border.color { ColorAnimation { duration: 200 } }

                    Text {
                        anchors.centerIn: parent
                        text: icon.modelData.glyph
                        color: mouse.containsMouse ? Theme.accentCore : Theme.text.dim
                        font.family: Theme.font.family
                        font.pixelSize: 18
                    }

                    // etiqueta, solo del que tiene el ratón encima
                    Rectangle {
                        anchors.bottom: parent.top
                        anchors.bottomMargin: 8
                        anchors.horizontalCenter: parent.horizontalCenter
                        width: tip.implicitWidth + 14
                        height: 18
                        radius: 4
                        color: Theme.surfaceGlass.surfaceHi
                        border.color: Theme.surfaceGlass.line
                        border.width: 1
                        visible: mouse.containsMouse

                        Text {
                            id: tip
                            anchors.centerIn: parent
                            text: icon.modelData.name
                            color: Theme.text.text
                            font.family: Theme.font.family
                            font.pixelSize: 9
                        }
                    }

                    MouseArea {
                        id: mouse
                        anchors.fill: parent
                        hoverEnabled: true
                        cursorShape: Qt.PointingHandCursor
                        onEntered: root.hoverIndex = icon.index
                        onExited: if (root.hoverIndex === icon.index) root.hoverIndex = -1
                        onClicked: root.launch(icon.modelData)
                    }
                }
            }
        }

        // Pista de que hay algo abajo cuando el dock está replegado
        // (#dock-edge del mockup): una raya fina de acento, sin robar sitio.
        Rectangle {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 3
            width: 104
            height: 3
            radius: 2
            visible: root.hidden
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: "transparent" }
                GradientStop { position: 0.5; color: Theme.accent }
                GradientStop { position: 1.0; color: "transparent" }
            }
            opacity: 0.45
        }
    }
}
