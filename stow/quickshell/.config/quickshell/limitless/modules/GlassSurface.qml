// modules/GlassSurface.qml — el material de cristal reutilizable
// (reparto-tareas.md: "el aro de dispersión cromática, el
// backdrop-filter, tiene que coincidir con el mockup al píxel"). Toda
// superficie de QuickShell (barra, dock, launcher, paneles de Fase 4) se
// construye ENCIMA de esto, nunca reimplementando el cristal a mano —
// .agents/agents/quickshell-surfaces.md ya se lo prohíbe explícitamente
// a Antigravity por la misma razón.
//
// Traducción directa de la clase `.glass` del mockup
// (docs/mockups/limitless-shell.html líneas 938-975):
//   - fondo: degradado sutil sobre --surface, más el propio --surface
//   - aro refractivo: borde de 1.3px con degradado cian→acento→hollow
//   - realces de luz superior/inferior, aproximando el inset box-shadow
//
// backdrop-filter:blur(26px) NO se replica aquí — ese blur lo aplica
// Hyprland sobre la superficie de layer-shell entera (hl.layer_rule en
// stow/hypr/.config/hypr/lua/appearance.lua, namespace
// "^(quickshell.*)$", Fase 1) — GlassSurface solo pinta lo que va DENTRO
// de esa superficie ya desenfocada por el compositor, igual que hace la
// terminal (.win.glassy en el mismo mockup).
//
// Simplificación documentada: el degradado del aro es diagonal (145deg)
// en CSS; QtQuick.Rectangle.gradient solo admite Vertical/Horizontal sin
// traer Qt5Compat.GraphicalEffects (dependencia que packages/ todavía no
// declara) — se usa Vertical. Corregible más adelante sin tocar la API
// pública de este componente.
//
// Tampoco se replica `.glass::after` (el brillo que sigue al cursor): es
// interacción de ratón sobre una superficie táctil/HUD sin cursor
// tradicional en la mayoría de las superficies reales — se omite, no se
// olvidó.
import QtQuick

Item {
    id: root

    default property alias content: body.data
    property real cornerRadius: 16
    property real ringThickness: compact ? 1 : 1.3
    property bool compact: false

    implicitWidth: 200
    implicitHeight: 100

    // aro: rectángulo exterior con el degradado completo, tapado por uno
    // interior más pequeño — el mismo resultado que mask-composite:exclude
    // sin esa primitiva en QtQuick.
    Rectangle {
        id: ring
        anchors.fill: parent
        radius: root.cornerRadius
        opacity: root.compact ? 0.5 : 0.55
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.62) }
            GradientStop { position: 0.12; color: Theme.sixEyes }
            GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.10) }
            GradientStop { position: 0.50; color: "transparent" }
            GradientStop { position: 0.72; color: Theme.accent }
            GradientStop { position: 0.86; color: Theme.hollowAccent }
            GradientStop { position: 1.00; color: Qt.rgba(1, 1, 1, 0.42) }
        }
    }

    Rectangle {
        id: body
        anchors.fill: parent
        anchors.margins: root.ringThickness
        radius: Math.max(0, root.cornerRadius - root.ringThickness)
        clip: true
        color: Theme.surfaceGlass.surface

        // degradado sutil 157deg del mockup, aproximado en vertical por
        // la misma limitación que el aro de arriba
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Vertical
                GradientStop { position: 0.00; color: Qt.rgba(1, 1, 1, 0.075) }
                GradientStop { position: 0.34; color: Qt.rgba(1, 1, 1, 0.018) }
                GradientStop { position: 0.58; color: "transparent" }
                GradientStop { position: 1.00; color: Qt.rgba(0, 0, 0, 0.10) }
            }
        }

        // realces: canto superior claro, canto inferior oscuro —
        // aproximan los inset box-shadow del mockup (líneas 949-952)
        Rectangle {
            anchors { top: parent.top; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(1, 1, 1, 0.30)
        }
        Rectangle {
            anchors { bottom: parent.bottom; left: parent.left; right: parent.right }
            height: 1
            color: Qt.rgba(0, 0, 0, 0.45)
        }
    }
}
