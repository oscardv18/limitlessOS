// modules/IPC.qml — patrón de IPC para los toggles de superficie
// (reparto-tareas.md: "el patrón de IPC para los toggles"). Cada
// superficie de Fase 4 (launcher, control center, widgets, clipboard...)
// instancia UNO de estos con su propio `surfaceName`, y queda invocable
// desde fuera de QuickShell sin escribir su propio IpcHandler cada vez.
//
// IpcHandler verificado contra
// quickshell.org/docs/v0.3.0/types/Quickshell.Io/IpcHandler/: `target`
// debe ser único en todo el shell — cada superficie que use este
// componente necesita un `surfaceName` distinto, o Quickshell falla al
// registrar el segundo con el mismo target.
//
// Ejemplo de uso:
//
//   Panel {
//     shown: ipc.shown          // ← `shown`, NUNCA `visible`
//     IPC { id: ipc; surfaceName: "launcher" }
//     ...contenido...
//   }
//
// `visible` está reservado: Panel.qml lo usa para mantener la ventana viva
// mientras dura el fundido de salida (modules/Reveal.qml). Fijar `visible`
// a mano aquí mataría la ventana en el primer frame de la animación y la
// salida se vería como un corte seco. Si tu superficie es un PanelWindow
// suelto en vez de un Panel, envuelve el contenido en un Reveal y usa
// `visible: reveal.active`.
//
// spec-keybinds.md liga SUPER+SPACE a `dotctl shell launcher toggle`
// (hyprland.lua, lua/keybinds.lua, ya escrito) — el subcomando `shell` de
// dotctl (Fase 5, todavía sin escribir) es lo que traduce eso a
// `qs -c limitless ipc call launcher toggle`. Este componente es el lado
// que recibe esa llamada, no el que la emite.
import QtQuick
import Quickshell.Io

Item {
    id: root

    property string surfaceName: ""
    property bool shown: false

    signal toggled(bool visible)

    IpcHandler {
        target: root.surfaceName

        function toggle(): void {
            root.shown = !root.shown
            root.toggled(root.shown)
        }
        function show(): void {
            root.shown = true
            root.toggled(true)
        }
        function hide(): void {
            root.shown = false
            root.toggled(false)
        }
    }
}
