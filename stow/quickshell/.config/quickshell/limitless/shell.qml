// shell.qml — punto de entrada general de QuickShell (`qs -c limitless`)
// (LIMITLESS-OS.md §6 Fase 4)
//
// Instancia y organiza todas las superficies del ecosistema Limitless:
//   - Barra superior continua (Bar.qml)
//   - Dock flotante interactivo (Dock.qml)
//   - Lanzador global HUD SUPER+SPACE (Launcher.qml)
//   - Menú de comandos del sistema (CommandMenu.qml)
//   - Panel de paquetes (PackagePanel.qml)
//   - Widgets laterales de clima/calendario/agenda/stats (Widgets.qml)
//   - Centro de control SUPER+C (ControlCenter.qml)
//   - Servidor de notificaciones y toasts (Notifications.qml)
//   - HUD OSD para volumen/brillo (OSD.qml)
//   - Panel de proyectos de desarrollo SUPER+P (ProjectsPanel.qml)
import QtQuick
import Quickshell
import "./modules"

ShellRoot {
    id: root

    // ── Fondo y decoración ambiental (capa `background`, bajo las
    //    ventanas, sin exclusión ni input) ────────────────────────────
    Wallpaper {}
    Chrome {}

    // ── Superficies principales fijas / permanentes ─────────────────
    Bar {}
    Dock {}

    // ── Superficies flotantes y modales controladas por IPC ─────────
    Launcher {}
    CommandMenu {}
    PackagePanel {}
    Widgets {}
    ControlCenter {}
    Clipboard {}
    Notifications {}
    OSD {}
    ProjectsPanel {}

    // Salvapantallas — el preset `saver` del campo, a pleno. Lo dispara
    // hypridle al primer escalón de inactividad.
    Screensaver {}
}
