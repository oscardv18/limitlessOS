// modules/Panel.qml — panel base de layer-shell (reparto-tareas.md:
// "el panel base de layer-shell del que heredan barra/dock/launcher").
// Envuelve PanelWindow (import Quickshell, verificado contra
// quickshell.org/docs/v0.3.0/types/Quickshell/PanelWindow/) + un
// GlassSurface ya montado — una superficie de Fase 4 solo pone sus
// anchors/margins/tamaño y su contenido, nunca vuelve a escribir el
// cristal.
//
// color:"transparent" es obligatorio: si el PanelWindow pinta un fondo
// opaco, tapa el propio GlassSurface y el blur de Hyprland (layer_rule,
// appearance.lua) no tiene nada translúcido que desenfocar detrás.
import QtQuick
import Quickshell

PanelWindow {
    id: root

    default property alias content: surface.content
    property real cornerRadius: 16
    property bool compact: false

    // Aparición/desaparición animada, gratis para todo el que herede de
    // Panel. Una superficie MODAL fija `shown: ipc.shown` (no `visible`,
    // que ya está tomado por la animación); una permanente lo deja en
    // true y se comporta como siempre.
    property bool shown: true

    color: "transparent"
    focusable: false

    // la ventana sigue viva mientras dura la salida, o el fundido se
    // cortaría de golpe en el primer frame
    visible: reveal.active

    Reveal {
        id: reveal
        anchors.fill: parent
        shown: root.shown

        GlassSurface {
            id: surface
            anchors.fill: parent
            cornerRadius: root.cornerRadius
            compact: root.compact
        }
    }
}
