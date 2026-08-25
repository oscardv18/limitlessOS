// modules/Reveal.qml — la aparición/desaparición de una superficie modal.
//
// El problema que resuelve: `visible: ipc.shown` sobre un PanelWindow es
// un POP instantáneo. El mockup no hace eso — funde con un cambio de
// escala en 340 ms (`--dur`, `--ease`), y esa transición es buena parte
// de por qué el shell del mockup se siente caro. Sin ella, todo el
// material de cristal aparece de golpe y parece un menú de 1998.
//
// Por qué hace falta un componente y no un `Behavior on opacity` suelto:
// un Window no se puede fundir; su `visible` es booleano y punto. Hay que
// (1) mantener la ventana viva mientras dura la salida y (2) animar el
// CONTENIDO dentro. Eso son dos cosas coordinadas, y repetirlas a mano en
// ocho superficies es repetir ocho veces la ocasión de equivocarse.
//
// Uso:
//     PanelWindow {
//         visible: reveal.active          // ← ventana viva durante la salida
//         Reveal {
//             id: reveal
//             anchors.fill: parent
//             shown: ipc.shown
//             GlassSurface { anchors.fill: parent; ... }
//         }
//     }
import QtQuick

Item {
    id: root

    // lo que pide el IPC: true = mostrar
    property bool shown: false

    // true mientras la superficie debe seguir renderizándose — incluye la
    // salida en curso. Es lo que el PanelWindow debe usar como `visible`.
    readonly property bool active: root.shown || root.opacity > 0.01

    property real hiddenScale: 0.97

    default property alias content: inner.data

    opacity: root.shown ? 1 : 0
    // no aceptar clics mientras se desvanece: pulsar sobre un panel que ya
    // se está yendo es una fuente clásica de acciones fantasma
    enabled: root.shown

    Behavior on opacity {
        NumberAnimation {
            duration: Theme.animDuration
            easing.type: Easing.BezierSpline
            easing.bezierCurve: Theme.animCurve
        }
    }

    Item {
        id: inner
        anchors.fill: parent
        scale: root.shown ? 1 : root.hiddenScale
        transformOrigin: Item.Center

        Behavior on scale {
            NumberAnimation {
                duration: Theme.animDuration
                easing.type: Easing.BezierSpline
                easing.bezierCurve: Theme.animCurve
            }
        }
    }
}
