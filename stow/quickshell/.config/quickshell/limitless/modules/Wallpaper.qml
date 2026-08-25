// modules/Wallpaper.qml — el campo de colisión como fondo de escritorio
// (plan.md §3.5b, LIMITLESS-OS.md §6 Fase 4)
//
// Capa layer-shell `background`: por debajo de TODAS las ventanas y del
// cromo. Sustituye a awww + imagen estática (lua/exec.lua sigue lanzando
// awww como respaldo por si el shell no arranca — un escritorio sin fondo
// es feo, pero uno negro con el shell caído parece roto).
//
// REGLA DE RENDIMIENTO de plan.md §3.5b, implementada aquí y no solo
// prometida: "el fondo se detiene cuando el salvapantallas o el bloqueo
// están activos... Nunca hay dos campos pintando a la vez. Sin esto, un
// salvapantallas de pantalla completa estaría componiendo sobre un fondo
// que nadie ve — el error clásico de los rices con fondo animado."
import QtQuick
import Quickshell
import Quickshell.Io
import "."

PanelWindow {
    id: root

    // cubrir la pantalla entera: los cuatro anclajes a la vez fuerzan
    // ancho y alto = los del monitor (PanelWindow, doc de Quickshell)
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    // debajo de las ventanas normales, y sin reservar espacio ni aceptar
    // clics: es fondo, no interfaz
    aboveWindows: false
    exclusionMode: ExclusionMode.Ignore
    focusable: false
    color: "transparent"

    // Lo apaga hyprlock/hypridle a través de este IPC. El bloqueo dibuja
    // su propio campo (preset `lock`), así que este debe callarse.
    property bool suspended: false

    IpcHandler {
        target: "wallpaper"
        function suspend(): void { root.suspended = true }
        function resume(): void { root.suspended = false }
        function toggle(): void { root.suspended = !root.suspended }
    }

    // Red de seguridad: `unlock_cmd` de hypridle es el campo correcto para
    // reanudar (verificado en el wiki), pero tiene un fallo conocido de
    // fiabilidad (hyprwm/hypridle#79 — "unlock_cmd is not triggered").
    // Si ese IPC nunca llega, el fondo se quedaría congelado PARA SIEMPRE
    // y parecería que el shell murió. Este chequeo lo despierta solo en
    // cuanto hyprlock ya no está: solo corre mientras está suspendido, así
    // que en uso normal no gasta nada.
    Process {
        id: lockCheck
        command: ["sh", "-c", "pidof hyprlock >/dev/null 2>&1 && echo locked || echo free"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (this.text.trim() === "free") root.suspended = false
            }
        }
    }

    Timer {
        running: root.suspended
        interval: 5000
        repeat: true
        onTriggered: lockCheck.running = true
    }

    Field {
        anchors.fill: parent
        preset: "wallpaper"
        opaqueBackground: true
        // 30 fps: es ambiente, no un videojuego. A 60 costaría el doble
        // por una diferencia que nadie mira directamente.
        fps: 30
        running: !root.suspended
    }

    // Veil del mockup (#veil): viñeta + tinte del acento sobre el campo.
    // Es lo que impide que el campo compita con el texto de las ventanas.
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Vertical
            GradientStop { position: 0.0; color: Qt.rgba(Theme.accent.r, Theme.accent.g, Theme.accent.b, 0.06) }
            GradientStop { position: 0.55; color: "transparent" }
            GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.55) }
        }
    }
}
