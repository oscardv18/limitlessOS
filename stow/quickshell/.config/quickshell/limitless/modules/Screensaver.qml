// modules/Screensaver.qml — la técnica a pleno (plan.md §3.5b)
//
// El tercer preset del campo, `saver`: 120 nodos, anillos de impacto,
// composición aditiva, núcleo blanco. Es el mismo motor que el fondo de
// escritorio y la pantalla de bloqueo — un archivo, tres configuraciones.
// Hasta ahora era el ÚNICO preset que no se instanciaba en ningún sitio.
//
// Lo dispara hypridle al primer escalón de inactividad (antes de atenuar
// y mucho antes de bloquear), vía `dotctl shell saver show`. Cualquier
// tecla o movimiento lo quita.
//
// REGLA DE plan.md §3.5b, cumplida aquí: mientras el salvapantallas está
// activo, el fondo de escritorio SE DETIENE. Nunca hay dos campos
// pintando a la vez — "el error clásico de los rices con fondo animado".
import QtQuick
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    IPC {
        id: ipc
        surfaceName: "saver"
    }

    anchors { top: true; bottom: true; left: true; right: true }

    // por encima de las ventanas: es un salvapantallas, tapa todo
    aboveWindows: true
    exclusionMode: ExclusionMode.Ignore
    // acepta foco para poder capturar la tecla que lo cierra
    focusable: ipc.shown
    color: "transparent"
    visible: reveal.active

    // Al mostrarse, callar el fondo; al ocultarse, devolverle la voz.
    onVisibleChanged: {
        Quickshell.execDetached(["qs", "-c", "limitless", "ipc", "call",
                                 "wallpaper", visible ? "suspend" : "resume"])
    }

    Reveal {
        id: reveal
        anchors.fill: parent
        shown: ipc.shown
        // el salvapantallas funde sin encoger: un cambio de escala en algo
        // que ocupa la pantalla entera se ve como un salto, no como una
        // aparición
        hiddenScale: 1.0

        Field {
            anchors.fill: parent
            preset: "saver"
            opaqueBackground: true
            // a pleno: aquí sí importa que se vea fluido, y no hay
            // ventanas compitiendo por la GPU
            fps: 60
            renderScale: 0.6
            running: root.visible
        }

        // Cualquier tecla o movimiento lo cierra. MouseArea con
        // hoverEnabled capta el movimiento sin necesitar un clic.
        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            onPositionChanged: ipc.hide()
            onClicked: ipc.hide()
        }

        FocusScope {
            anchors.fill: parent
            focus: root.visible
            Keys.onPressed: function (event) {
                ipc.hide()
                event.accepted = true
            }
        }

        // Reloj discreto, para que el salvapantallas siga siendo útil
        Text {
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.bottom: parent.bottom
            anchors.bottomMargin: 48
            text: Qt.formatDateTime(new Date(), "hh:mm")
            color: Theme.text.dim
            font.family: Theme.font.family
            font.pixelSize: 13
            font.letterSpacing: 4
            opacity: 0.5
        }
    }
}
