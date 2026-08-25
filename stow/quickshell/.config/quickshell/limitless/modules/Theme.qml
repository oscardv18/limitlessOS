// modules/Theme.qml — singleton, cimiento de QuickShell (LIMITLESS-OS.md
// §6 Fase 4, reparto-tareas.md: "esquema de theme.toml" + "Cimiento").
//
// Lee themes/hud-void/theme.toml directamente (misma ruta que ya usa
// install/stages/50-theme.sh: $REPO_DIR/themes/hud-void/theme.toml, es
// decir ~/.limitless/... una vez desplegado) — sin generar un JSON
// intermedio ni depender de python en el arranque del shell. El parser de
// abajo es deliberadamente un subconjunto de TOML (solo lo que theme.toml
// usa: secciones [a.b.c], claves = "cadena" o claves = número, comentarios
// con #) — no un parser TOML general.
//
// Type real: `Singleton` (import Quickshell), no `QtObject` — Singleton
// hereda de Scope y sí admite hijos QML no visuales (aquí, el FileView),
// a diferencia de QtObject que no tiene default property. Verificado
// contra quickshell.org/docs/v0.3.0/types/Quickshell/Singleton/ tras
// encontrar un ejemplo real (jimallen/quickshell) que usa QtObject solo
// porque ese Theme.qml no lee ningún archivo — el nuestro sí.
pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

Singleton {
    id: root

    readonly property string themePath: Quickshell.env("HOME") + "/.limitless/themes/hud-void/theme.toml"

    // ── parseo ─────────────────────────────────────────────────────────
    property var raw: ({})

    FileView {
        id: file
        path: root.themePath
        watchChanges: true
        blockLoading: true
        onFileChanged: reload()
        onLoaded: root.raw = root._parseToml(text())
        onLoadFailed: function (error) {
            console.warn("Theme.qml: no se pudo leer " + root.themePath + " — " + error)
        }
    }

    // '#' solo cuenta como comentario si no está dentro de comillas —
    // los hex de theme.toml ("#04060d") lo llevan dentro. El mismo error
    // que ya se atrapó una vez en el validador de hyprland.lua (Fase 1):
    // ahí se pisó por hacer el strip de comentarios ANTES que el de
    // cadenas; aquí se evita desde el diseño, no se corrige después.
    function _stripComment(line) {
        var inStr = false
        for (var i = 0; i < line.length; i++) {
            var c = line.charAt(i)
            if (c === '"') inStr = !inStr
            else if (c === '#' && !inStr) return line.substring(0, i)
        }
        return line
    }

    function _parseToml(src) {
        var sections = {}
        var current = null
        var lines = src.split("\n")
        for (var i = 0; i < lines.length; i++) {
            var line = root._stripComment(lines[i]).trim()
            if (line.length === 0) continue

            var sectionMatch = line.match(/^\[([a-zA-Z0-9_.]+)\]$/)
            if (sectionMatch) {
                current = sectionMatch[1]
                sections[current] = {}
                continue
            }

            var kv = line.match(/^([a-zA-Z0-9_]+)\s*=\s*(.+)$/)
            if (kv && current) {
                var rawValue = kv[2].trim()
                var value
                if (rawValue.charAt(0) === '"' && rawValue.charAt(rawValue.length - 1) === '"') {
                    value = rawValue.substring(1, rawValue.length - 1)
                } else {
                    value = parseFloat(rawValue)
                }
                sections[current][kv[1]] = value
            }
        }
        return sections
    }

    function _get(section, key, fallback) {
        return (root.raw[section] && root.raw[section][key] !== undefined) ? root.raw[section][key] : fallback
    }

    // "#RRGGBB" lo entiende QML de forma nativa; "rgba(r,g,b,a)" (formato
    // CSS que usa [color.surface_glass]) no está garantizado en el parser
    // de color de Qt, así que se convierte a mano con Qt.rgba().
    function _toColor(str, fallback) {
        if (str === undefined) return fallback
        if (str.charAt(0) === "#") return str
        var m = str.match(/^rgba\(\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*,\s*([\d.]+)\s*\)$/)
        if (m) return Qt.rgba(parseFloat(m[1]) / 255, parseFloat(m[2]) / 255, parseFloat(m[3]) / 255, parseFloat(m[4]))
        return fallback
    }

    // ── superficies de cristal (todo lo que QuickShell dibuja es cristal
    //    — surface_opaque y [color.syntax] son territorio de Neovim, no
    //    se exponen aquí a propósito) ──────────────────────────────────
    readonly property QtObject surfaceGlass: QtObject {
        readonly property color surface: root._toColor(root._get("color.surface_glass", "surface", undefined), Qt.rgba(0.047, 0.07, 0.125, 0.62))
        readonly property color surfaceHi: root._toColor(root._get("color.surface_glass", "surface_hi", undefined), Qt.rgba(0.06, 0.09, 0.16, 0.80))
        readonly property color line: root._toColor(root._get("color.surface_glass", "line", undefined), Qt.rgba(0.49, 0.66, 0.84, 0.16))
        readonly property color lineHi: root._toColor(root._get("color.surface_glass", "line_hi", undefined), Qt.rgba(0.49, 0.66, 0.84, 0.32))
    }

    readonly property QtObject text: QtObject {
        readonly property color text: root._get("color.text", "text", "#eaf2ff")
        readonly property color dim: root._get("color.text", "dim", "#7e93b0")
        readonly property color comment: root._get("color.text", "comment", "#6b7f9e")
        readonly property color mute: root._get("color.text", "mute", "#46587a")
        readonly property color ghost: root._get("color.text", "ghost", "#2a3a55")
    }

    readonly property QtObject state: QtObject {
        readonly property color add: root._get("color.state", "add", "#1d5f42")
        readonly property color change: root._get("color.state", "change", "#1d3f6b")
        readonly property color remove: root._get("color.state", "delete", "#5f1f18")
        readonly property color diffText: root._get("color.state", "diff_text", "#2a5a91")
    }

    readonly property QtObject font: QtObject {
        readonly property string family: root._get("font", "family", "JetBrains Mono")
        readonly property string jp: root._get("font", "jp", "Noto Serif JP")
    }

    // ── movimiento ─────────────────────────────────────────────────────
    // Del mockup: `--dur: .34s` y `--ease: cubic-bezier(.16,.84,.36,1)`
    // (docs/mockups/limitless-shell.html, :root). Una sola definición para
    // todo el shell — si cada superficie inventa su propia curva, el
    // conjunto deja de sentirse como un sistema.
    //
    // OJO con el tipo: en Qt 6 la curva a medida es `Easing.BezierSpline`,
    // NO `Easing.Bezier` (ese es el nombre de Qt 5 y aquí no haría nada).
    // Formato: [cx1, cy1, cx2, cy2, endx, endy], y el punto final DEBE
    // ser 1,1.
    readonly property int animDuration: 340
    readonly property int animFast: 180
    readonly property var animCurve: [0.16, 0.84, 0.36, 1, 1, 1]

    readonly property QtObject geometry: QtObject {
        readonly property int barHeight: root._get("geometry", "bar_height", 26)
        readonly property real radiusDock: root._get("geometry", "radius_dock", 14)
        readonly property real radiusIcon: root._get("geometry", "radius_icon", 12)
        readonly property real tracking: root._get("geometry", "tracking", 0.04)
    }

    // el iris — constante, independiente de la técnica activa
    readonly property color sixEyes: root._get("color.constant", "six_eyes", "#b8ecff")
    // colores fijos por técnica — API PÚBLICA. Igual que hollowAccent (que
    // GlassSurface ya usaba para el aro), para cuando una superficie
    // necesita un color denotativo que NO debe cambiar con la técnica
    // activa (p. ej. "sucio" siempre en rojo, "por delante" siempre en
    // morado) — a diferencia de _techniques (más abajo), que es un detalle
    // interno y puede cambiar de forma sin aviso.
    readonly property color lapseAccent: root._get("color.technique.lapse", "accent", "#3b9eff")
    readonly property color hollowAccent: root._get("color.technique.hollow", "accent", "#a970ff")
    readonly property color reversalAccent: root._get("color.technique.reversal", "accent", "#ff4a2e")
    // void — el único valor de [color.surface_opaque] expuesto aquí: texto
    // oscuro de contraste sobre un botón/badge de color de acento (nunca
    // superficies opacas completas, eso sigue siendo territorio de Neovim).
    readonly property color void_: root._get("color.surface_opaque", "void", "#04060d")

    // ── las tres técnicas — PRIVADO, no lo uses desde otra superficie.
    //    Para un color fijo por técnica hay API pública arriba
    //    (lapseAccent/hollowAccent/reversalAccent); para el "core" fijo,
    //    repórtalo si hace falta en vez de leer esto directo — QML no
    //    impone privacidad real, pero el guion bajo es la señal ─────────
    readonly property var _techniques: ({
        lapse:    { kanji: "蒼", name: "Lapse",    accent: root._get("color.technique.lapse", "accent", "#3b9eff"),    core: root._get("color.technique.lapse", "accent_core", "#8fe3ff") },
        hollow:   { kanji: "茈", name: "Hollow",   accent: root._get("color.technique.hollow", "accent", "#a970ff"),   core: root._get("color.technique.hollow", "accent_core", "#e9d5ff") },
        reversal: { kanji: "赫", name: "Reversal", accent: root._get("color.technique.reversal", "accent", "#ff4a2e"), core: root._get("color.technique.reversal", "accent_core", "#ffb4a0") }
    })

    // técnica activa — estado en caliente (SUPER+T), NO se escribe de
    // vuelta a theme.toml. `meta.technique_default` solo decide el valor
    // al arrancar el shell, igual que hace Neovim/Starship con el suyo.
    property string activeTechnique: root._get("meta", "technique_default", "lapse")

    readonly property color accent: root._techniques[root.activeTechnique] ? root._techniques[root.activeTechnique].accent : "#3b9eff"
    readonly property color accentCore: root._techniques[root.activeTechnique] ? root._techniques[root.activeTechnique].core : "#8fe3ff"
    readonly property string currentKanji: root._techniques[root.activeTechnique] ? root._techniques[root.activeTechnique].kanji : "蒼"
    readonly property string currentName: root._techniques[root.activeTechnique] ? root._techniques[root.activeTechnique].name : "Lapse"

    readonly property var techniqueOrder: ["lapse", "hollow", "reversal"]

    function cycleTechnique() {
        var idx = root.techniqueOrder.indexOf(root.activeTechnique)
        root.activeTechnique = root.techniqueOrder[(idx + 1) % root.techniqueOrder.length]
    }

    // IPC global de tema — `dotctl theme cycle` (Fase 5, spec-keybinds.md
    // SUPER+T) invoca esto vía `qs -c limitless ipc call theme cycle`,
    // no un script propio: una sola fuente de verdad para "qué técnica
    // está activa", igual que pide LIMITLESS-OS.md §4.4.
    IpcHandler {
        target: "theme"
        function cycle(): void { root.cycleTechnique() }
        function set(name: string): void {
            if (root.techniqueOrder.indexOf(name) !== -1) root.activeTechnique = name
        }
    }
}
