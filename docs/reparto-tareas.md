# Reparto de tareas — Claude / Antigravity (Gemini, enjambre)

> Vive aparte de `LIMITLESS-OS.md` porque es un documento de *flujo de trabajo*, no de arquitectura — se actualiza según avanza el reparto, no según cambien las decisiones de diseño. `CLAUDE.md` ya avisa de este contexto: revisa `git status`/`git log` antes de tocar nada, por si el enjambre ya lo cambió en paralelo.

## El criterio: riesgo y dependencias, no volumen

No se reparte por cuánto trabajo hay, se reparte por **qué tan caro es un error** y **qué bloquea a qué**. Tres piezas condicionan casi todo lo demás — si salen mal, no es "se ve feo", es "no arranca" o "hay que rehacer 20 archivos que ya se apoyaban en la base equivocada". Esas se quedan conmigo. Todo lo que es mecánico, independiente, y donde un fallo se queda contenido a un solo archivo va al enjambre.

---

## Claude — las tres piezas que bloquean todo lo demás

| Pieza | Por qué no es delegable |
|---|---|
| **`hyprland.lua`** completo — binds (SUPER+letra, XF86, `spec-keybinds.md` entero), layouts (master/dwindle/scroll/grid/focus, `spec-layouts.md`), reglas de ventana/workspace, blur/vibrancy, `exec-once` del portal (necesario para OBS/Discord, `spec-keybinds.md` §4c) | Sintaxis Lua de Hyprland 0.55+/0.56 sin margen de error — un bind mal escrito no falla en silencio, puede impedir que la sesión entera arranque. Exige verificar cada función contra el wiki en vivo, línea a línea (la regla ya escrita en `CLAUDE.md`). Es además la pieza de la que depende literalmente todo lo demás: QuickShell recibe sus toggles de aquí, el tema de LightDM ya referencia `hyprland.desktop` |
| **Cimiento de QuickShell** — esqueleto del proyecto, singleton `Theme.qml` (lee `theme.toml`), el componente de material de cristal reutilizable (el aro de dispersión cromática, el `backdrop-filter`, tiene que coincidir con el mockup al píxel), el panel base de layer-shell del que heredan barra/dock/launcher, y el patrón de IPC para los toggles | Es la plantilla de la que copia todo lo demás. Si el material de cristal no es exacto aquí, cada superficie que se construya encima hereda el error, multiplicado por diez componentes |
| **Esquema de `theme.toml`** (las claves, no las 12 plantillas) | Todo lo demás —matugen, las plantillas, QuickShell— necesita saber qué variables va a poder leer. Definirlo mal significa reescribir 12+ plantillas después |
| Puente herdr → QuickShell | herdr es una herramienta nueva, poco documentada — el formato de estado real hay que verificarlo, no asumirlo. Es además "lo más original del proyecto" (`LIMITLESS-OS.md` §4.1) |
| Spike del shader de refracción | Experimental, con perfilado de rendimiento real de por medio — no es código que se pueda validar solo por sintaxis |
| Degradación por batería / gestos | Toca el comportamiento en caliente de `hyprland.lua` ya escrito — un ajuste mal calibrado ahí interactúa con todo lo demás de forma impredecible |

---

## Antigravity / Gemini (enjambre) — mecánico, independiente, bajo riesgo

**Regla para el enjambre: cada tarea de aquí tiene su spec ya escrita en `docs/`. No hay que inventar diseño, hay que seguirlo.**

| Pieza | Spec a seguir | Por qué es seguro delegarla |
|---|---|---|
| **12 plantillas de matugen** — Ghostty, btop, lazygit, lazydocker, yazi, bat, delta, fzf, hyprlock, GTK3/4, Qt/Kvantum, herdr | `spec-colorscheme.md` (paleta ya fijada) + el esquema de `theme.toml` (una vez yo lo defina) | Cada una es un archivo de config independiente, formato bien documentado, si una sale mal solo afecta a esa app — cero riesgo de sistema |
| **Superficies de QuickShell** que no son el cimiento: widgets (clima/calendario/agenda), pestañas del centro de control, notificaciones, OSD, panel de proyectos (la UI, no el motor de despacho) | `docs/mockups/limitless-shell.html` (referencia visual pixel a pixel) + el cimiento que yo entregue | Una vez existe el componente base de cristal, cada superficie es "aplicar el patrón a un layout nuevo" — exactamente lo que `plan.md` ya pedía: mockup antes que QML, nunca improvisar |
| **Panel de paquetes** (la lógica de búsqueda fzf + presentación) | `spec-package-panel.md`, ya completa con el código de referencia de Omarchy | Autocontenido, no toca nada fuera de sí mismo |
| **Migraciones** — una vez yo escriba la primera como plantilla | `plan-automation.md` §5 | Patrón mecánico: timestamp + estado. Repetible sin criterio nuevo |
| `dotctl tui-install`, envoltorio de Discord (flags de Wayland, `spec-keybinds.md` §4c), entradas `.desktop` sueltas | Ya hay un patrón idéntico en `install/stages/80-tui.sh` | Copiar y adaptar, no diseñar |
| CI de lint (`qmllint`, `shellcheck` en un workflow) | — | No toca ninguna máquina real, solo valida sintaxis en CI |
| README con capturas, pulido de documentación | — | Bajo riesgo por definición |

---

## Orden que importa — no repartir todo a la vez

El enjambre **no puede empezar en serio con las superficies de QuickShell hasta que el cimiento exista** — si arrancan antes, construyen sobre una base que yo voy a cambiar, y se tira ese trabajo. Secuencia real:

> **Paso 1, cerrado.** `hyprland.lua` (Fase 1), el esquema de `theme.toml` (Fase 1, con una extensión pequeña en Fase 4: `[color.constant]` para `six_eyes`, que ningún consumidor de la Fase 1 necesitaba) y el cimiento de QuickShell (`stow/quickshell/.config/quickshell/limitless/`: `shell.qml`, `modules/Theme.qml`, `modules/GlassSurface.qml`, `modules/Panel.qml`, `modules/IPC.qml`) ya están en el repositorio. `theme-templates` y `quickshell-surfaces` quedan desbloqueados — ver `docs/prompt-antigravity-fase4.md` para el prompt exacto de la segunda.

1. Yo entrego `hyprland.lua` + el cimiento de QuickShell + el esquema de `theme.toml`.
2. A partir de ahí, el enjambre puede trabajar **en paralelo entre sí** sin pisarse: las 12 plantillas de matugen no dependen unas de otras, y cada superficie de QuickShell (widgets, notificaciones, OSD, paquetes...) es un archivo independiente una vez existe el componente base.
3. Yo hago una revisión final cuando el usuario confirme que el enjambre terminó — contra el mockup y contra `spec-keybinds.md`, no una lectura superficial.

> **Corrección sobre esta misma sección:** decía que las 12 plantillas de tema podían arrancar ya, "solo dependen de `spec-colorscheme.md`". Al escribir el archivo real del subagente (`.agents/agents/theme-templates.md`) quedó claro que eso era impreciso — una plantilla de matugen referencia *variables* de `theme.toml`, y ese archivo todavía no existe. Escribirlas ahora significaría o inventar nombres de variable que luego cambian, o caer en hex a mano — justo lo que la regla del proyecto prohíbe. El subagente ya lo dice bien: espera a `theme.toml`. Esta sección se queda mal si no se corrige aquí también.

Lo que de verdad puede arrancar sin esperar nada, a día de hoy: dentro de `mechanical-tasks`, el **panel de paquetes** (`spec-package-panel.md`, autocontenido), el **envoltorio de Discord** (`spec-keybinds.md` §4c, flags ya verificados), `dotctl tui-install` (el patrón ya existe en `80-tui.sh`), **CI de lint**, y el **README**. Las **migraciones** también esperan — necesitan la primera, escrita por mí, como plantilla del patrón exacto.

---

## Configuración de Antigravity — `.agents/agents/`

Verificado contra `antigravity.google/docs/subagents/` antes de escribir nada (formato real: Markdown con frontmatter YAML, descubierto en `.agents/agents/<nombre>.md` a nivel de workspace). Tres subagentes, uno por bloque de trabajo de arriba:

| Archivo | Modelo | Para qué |
|---|---|---|
| `.agents/agents/theme-templates.md` | `flash` | Las 12 plantillas de matugen — mecánico, alto volumen |
| `.agents/agents/quickshell-surfaces.md` | `pro` | Superficies de QuickShell sobre el cimiento — fidelidad visual contra el mockup, se beneficia de más razonamiento |
| `.agents/agents/mechanical-tasks.md` | `flash` | Paquetes, migraciones, tui-install, Discord, CI, README |

**Dos honestidades sobre lo que pediste y lo que el esquema real permite:**

1. **`model` solo acepta `inherit` / `flash` / `pro`** — niveles abstractos, no la versión exacta ("Gemini 3.7 Flash" / "Gemini 3.1 Pro" son, hoy, a lo que esas etiquetas apuntan según la documentación de modelos de Antigravity — pero el archivo de subagente no fija la versión, Antigravity decide cuál es "flash" y cuál es "pro" en cada momento).
2. **No existe una clave de nivel de razonamiento en el frontmatter de subagentes.** El selector "Low/Medium/High" que sí existe para Gemini 3.7 Flash y Gemini 3.1 Pro vive en el selector de modelo general de Antigravity, no en este archivo — no hay `reasoningLevel:` ni `thinking:` documentado para subagentes. Si quieres que el nivel Alto aplique, selecciónalo en el propio Antigravity al elegir el modelo de la conversación principal; estos archivos no pueden forzarlo por sí solos.

**Esto habilita la delegación, no la dispara.** Escribir estos archivos hace que el agente principal de Antigravity *pueda* invocar cada subagente cuando el trabajo encaje con su `description` — pero alguien tiene que abrir Antigravity y darle una tarea para que eso arranque. No hay manera de programar un disparo automático desde aquí.
