# Prompt para Antigravity — su parte de la Fase 4 (QuickShell)

> Copia y pega esto tal cual en el chat principal de Antigravity, con el repositorio abierto como workspace. Sustituye a la sección "Lo que NO debes invocar todavía... quickshell-surfaces" de `docs/prompt-antigravity.md` — esa condición ya se cumplió.

```
Este workspace es Limitless OS. El cimiento de QuickShell que bloqueaba a
tu subagente quickshell-surfaces ya existe — lo construyó Claude en esta
sesión. Antes de invocar nada, lee en este orden:

1. CLAUDE.md — regla más importante: NUNCA ejecutes install.sh ni ninguna
   etapa de install/stages/, bajo ninguna circunstancia.
2. docs/reparto-tareas.md — confirma que lo de abajo sigue siendo tuyo.
3. .agents/agents/quickshell-surfaces.md — tu subagente ya no está
   bloqueado, la condición que lo detenía (que exista el cimiento) ya
   se cumplió. Sigue exactamente sus reglas ("Antes de escribir nada",
   "Reglas no negociables", "Al terminar") para cada superficie.

Corre `git status` y `git log --oneline -10` antes de invocar cualquier
subagente — Claude puede seguir trabajando en paralelo.

## El cimiento que ya existe — dónde está y cómo se usa

Todo bajo stow/quickshell/.config/quickshell/limitless/:

- `shell.qml` — punto de entrada de `qs -c limitless`. Hoy solo pinta un
  indicador mínimo (kanji + "LIMITLESS") para probar que el cimiento
  funciona de punta a punta — NO es la barra real. Tus superficies no se
  instancian ahí todavía (eso lo conecta Claude cuando la barra real
  exista); constrúyelas como archivos independientes en `modules/` o en
  una subcarpeta nueva si el tamaño lo justifica, listas para engancharse.
- `modules/Theme.qml` — singleton. Lee themes/hud-void/theme.toml de
  verdad (no hex a mano en ningún lado). Propiedades disponibles:
    Theme.accent, Theme.accentCore        (técnica activa)
    Theme.currentKanji, Theme.currentName (蒼/茈/赫, "Lapse"/"Hollow"/"Reversal")
    Theme.hollowAccent, Theme.sixEyes     (constantes, no cambian con la técnica)
    Theme.surfaceGlass.{surface,surfaceHi,line,lineHi}
    Theme.text.{text,dim,comment,mute,ghost}
    Theme.state.{add,change,remove,diffText}
    Theme.font.{family,jp}
    Theme.geometry.{barHeight,radiusDock,radiusIcon,tracking}
    Theme.cycleTechnique()                (SUPER+T ya lo invoca por IPC,
                                            target "theme", función "cycle")
  Si tu superficie necesita un color que no está en esta lista, PARA y
  repórtalo — no lo escribas a mano. (`[color.syntax]` y
  `[color.surface_opaque]` de theme.toml son territorio de Neovim, a
  propósito no están expuestos aquí.)
- `modules/GlassSurface.qml` — el material de cristal. No lo
  reimplementes: hereda de él (directo, o vía Panel.qml).
- `modules/Panel.qml` — PanelWindow + GlassSurface ya montados. Uso:
    Panel {
      anchors { top: true; right: true }   // o los que corresponda
      margins { top: 10; right: 10 }
      width: 320; height: 400
      cornerRadius: 16
      // tu contenido va aquí directo, como hijo
    }
- `modules/IPC.qml` — patrón de toggle mostrar/ocultar. Uso:
    Panel {
      visible: ipc.shown
      IPC { id: ipc; surfaceName: "widgets" }   // nombre único por superficie
      ...
    }
  `surfaceName` debe ser único en todo el shell — no reutilices uno que
  ya use otra superficie. Esto es lo que `dotctl shell <superficie>
  toggle` (Fase 5, todavía sin escribir) va a invocar via
  `qs -c limitless ipc call <surfaceName> toggle` — el emisor no existe
  todavía, pero el receptor (esto) sí, y no bloquea tu trabajo.

## Las cinco superficies que te tocan (reparto-tareas.md) — una por invocación

1. **Widgets** (clima/calendario/agenda) — mockup: sección de widgets,
   atajo SUPER+W (`spec-keybinds.md`). `IPC { surfaceName: "widgets" }`.
2. **Pestañas del centro de control** — mockup: control center, atajo
   SUPER+C, cambio de pestaña con 1-4. Esas teclas 1-4 NO son un bind
   global de Hyprland (1-9 ya está tomado por cambio de workspace en
   `lua/keybinds.lua`) — el cambio de pestaña es manejo de teclado
   LOCAL de la superficie mientras tiene foco (`Keys.onPressed` o
   equivalente QML), no IPC. `IPC { surfaceName: "control" }` solo para
   mostrar/ocultar el panel completo.
3. **Notificaciones** — antes de escribir una sola línea, VERIFICA si
   Quickshell expone un módulo tipo `Quickshell.Services.Notifications`
   / `NotificationServer` (busca en quickshell.org/docs, no lo asumas:
   este cimiento no lo verificó, es terreno nuevo). Si existe con ese
   nombre, constrúyelo. Si NO existe o no estás seguro, PARA y repórtalo
   tal cual — significaría que el proyecto necesita un daemon de
   notificaciones aparte (mako u otro), y esa es una decisión de
   arquitectura que vuelve a Claude, no la tomes tú.
4. **OSD** (volumen/brillo) — mockup: `#osd` (líneas 298-313 y
   2711-2731 de limitless-shell.html). El emisor real (hyprland.lua
   disparando esto al pulsar XF86AudioRaiseVolume/MonBrightnessUp) es
   Fase 5, todavía no existe — no te bloquea. Construye el RECEPTOR:
   un IpcHandler propio (no el patrón genérico de IPC.qml, que solo
   sirve para toggle/show/hide sin argumentos) con una función con
   firma tipada, por ejemplo `function show(kind: string, value: int): void`,
   target "osd". Documenta esa firma exacta en un comentario de
   cabecera — es el contrato que Fase 5 va a tener que invocar.
5. **Panel de proyectos (solo la UI)** — mockup: panel `P`
   (SUPER+P). La lógica de despacho real (restaurar layout/rama/agentes
   de herdr) la entrega Claude aparte; a ti te toca la UI que el mockup
   ya define, con datos de ejemplo si hace falta mientras esa lógica no existe.

Invócalas en paralelo entre sí — son independientes. `qmllint` en verde
antes de reportar cada una terminada; si no está disponible en tu
entorno, dilo explícitamente (Claude no pudo correrlo en esta sesión
por trabajar desde Windows sin Quickshell instalado — validó a mano
balance de llaves/paréntesis en su lugar, y lo dice así, no como si
hubiera sido `qmllint` real).

Cuando termines las cinco, o cuando ya no quede ninguna disponible sin
pisar trabajo de Claude, dilo explícitamente y espera.
```

## Por qué el prompt está escrito así

- **Da la API real del cimiento, no solo "ya existe"** — Antigravity no puede adivinar los nombres exactos de `Theme.qml` sin leerlo entero; listarlos aquí ahorra una ronda de lectura y evita que invente nombres de propiedad que no existen.
- **OSD y notificaciones se marcan como "verifica o para"**, no como tareas mecánicas — a diferencia de las otras tres, aquí hay riesgo real de que la API asumida no exista, y `quickshell-surfaces.md` ya pide exactamente ese comportamiento ("si algo no lo conoces con certeza, búscalo... escribir con sintaxis inventada es peor que no escribirla").
- **El control center aclara explícitamente que 1-4 no es un bind global** porque `lua/keybinds.lua` ya usa 1-9 para workspaces — sin esta nota, la lectura natural del mockup (números sueltos cambian de pestaña) colisiona con un atajo que Claude ya verificó y no debe reabrirse.
- **Le doy la validación real que sí se hizo (balance de llaves a mano) en vez de dejar que asuma `qmllint` corrió** — la misma honestidad que pide su propio archivo de subagente al reportar.
