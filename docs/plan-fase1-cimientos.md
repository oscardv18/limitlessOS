# Plan de trabajo — las tres piezas de Claude (`reparto-tareas.md`)

> Desglose técnico de `hyprland.lua`, el cimiento de QuickShell, y el esquema de `theme.toml`. Esto es lo que hay que aprobar antes de que empiece a escribir código — es la parte de mayor riesgo del proyecto entero, así que va con el mismo nivel de detalle que se le pidió.

---

## 0. Orden interno (dentro de mis tres piezas)

No las voy a hacer en el orden en que las nombré la primera vez. El orden correcto:

1. **`theme.toml`** primero. Es lo más rápido, el riesgo más bajo, y **las otras dos lo necesitan** — `hyprland.lua` para los colores de borde/sombra, QuickShell para el singleton de tema. De paso, en cuanto exista, el subagente `theme-templates` deja de trabajar solo con la prosa de `spec-colorscheme.md` y tiene un archivo de datos real que consumir — mejora la consistencia de las 12 plantillas del enjambre sin que yo tenga que revisarlas una a una tan de cerca.
2. **`hyprland.lua`** segundo. Es la pieza de mayor riesgo (sintaxis Lua sin margen de error) y la más novedosa en cuanto a verificación — prefiero enfrentarla con tiempo por delante, no al final.
3. **Cimiento de QuickShell** tercero. Depende conceptualmente de que `hyprland.lua` ya defina los nombres de los toggles IPC (`SUPER+SPACE` → qué comando exacto le llega a QuickShell) — construirlo antes sería adivinar esa interfaz.

---

## 1. `theme.toml` — el esquema

### Qué hace: una sola fuente, cuatro consumidores ya existentes

Hoy la paleta está escrita a mano, de forma consistente, en cuatro sitios: `colors/limitless.lua` (210 grupos), `starship.toml` (33 módulos), `system/grub/theme/theme.txt`, y `system/lightdm/theme/style.css`. El trabajo no es *inventar* una paleta — es **extraer la que ya está**, en los cuatro archivos, a una sola tabla, y verificar que los cuatro consumidores podrían regenerarse desde ahí sin que cambie ni un píxel.

### Estructura propuesta

```toml
[meta]
name = "hud-void"
technique_default = "lapse"   # 蒼 / hollow / reversal — la técnica activa

[color.surface]
void         = "#04060d"
surface      = "rgba(12,18,32,.62)"
surface_hi   = "rgba(16,24,42,.8)"
line         = "rgba(126,168,214,.16)"
line_hi      = "rgba(126,168,214,.32)"

[color.text]
text  = "#eaf2ff"
dim   = "#7e93b0"
mute  = "#46587a"

[color.technique.lapse]     # 蒼 azul — la técnica activa por defecto
accent      = "#3b9eff"
accent_core = "#8fe3ff"

[color.technique.hollow]    # 茈 morado
accent      = "#a970ff"
accent_core = "#e9d5ff"

[color.technique.reversal]  # 赫 rojo
accent      = "#ff4a2e"
accent_core = "#ff6b7f"

[color.syntax]   # los 10 roles ya fijados en spec-colorscheme.md
cyan   = "#2ee6d6"
green  = "#4bf0a5"
amber  = "#ffd25e"
orange = "#ff9d3d"
magenta = "#ff5ecb"

[font]
family = "JetBrains Mono"
jp     = "Noto Serif JP"

[geometry]
bar_height  = 26
radius_dock = 14
radius_icon = 12
tracking    = 0.04
```

### Por qué esta forma y no otra

- **`color.technique.*` como tabla, no una sola clave `accent`** — porque la técnica cambia en caliente (`T` en el mockup, `SUPER+T` en el sistema real) y las tres paletas tienen que coexistir en el archivo, no sobrescribirse.
- **No deriva del wallpaper.** Ya se decidió en `plan.md` §5: es una paleta de identidad fija, matugen la usa como entrada para generar los temas de apps de terceros — nunca al revés.

### Verificación antes de dar por cerrado el esquema

Un solo paso, mecánico: recorrer los cuatro archivos existentes y confirmar que cada hex que aparece ahí tiene una entrada correspondiente en `theme.toml`. Si sobra un hex en alguno de los cuatro que no está en el esquema, el esquema está incompleto — se amplía antes de tocar `hyprland.lua`.

**Esfuerzo estimado: medio día.**

---

## 2. `hyprland.lua` — módulos, en orden de escritura

### Decisión de estructura: modular desde el primer archivo

Igual que el resto del proyecto (`stow/zsh/.config/zsh/conf.d/`, `install/stages/`), no un solo archivo gigante. Lua tiene `dofile`/`require` nativos — **esto no necesita verificación contra el wiki de Hyprland, es Lua puro**, la única pieza de esta lista que doy por buena sin comprobarla en vivo.

```
stow/hypr/.config/hypr/
├── hyprland.lua        -- entrada: solo dofile() en orden, cero lógica
└── lua/
    ├── env.lua          -- variables de entorno, dbus-update-activation-environment
    ├── monitors.lua      -- salida(s), a la espera de tu hardware real
    ├── input.lua          -- teclado, touchpad
    ├── appearance.lua      -- blur/vibrancy/rounding/sombras — plan.md §3.6
    ├── layouts.lua          -- master/dwindle/scroll/grid/focus — spec-layouts.md
    ├── workspaces.lua        -- code/term/web/comms/ops, semánticos
    ├── windowrules.lua        -- cristal vs. opacidad — spec-layouts.md §5
    ├── keybinds.lua             -- spec-keybinds.md completo
    ├── plugins.lua               -- hyprexpo (sin hyprbars, ya descartado)
    └── exec.lua                  -- exec-once: quickshell, swww, portal
```

### Módulo por módulo: qué contiene y qué tengo que verificar antes de escribirlo

| Módulo | Contenido | Riesgo de sintaxis | Qué verifico, dónde |
|---|---|---|---|
| `env.lua` | `XDG_CURRENT_DESKTOP`, `WAYLAND_DISPLAY`, variables de sesión | Bajo | Forma de `hl.env()` o equivalente — wiki + fuente de Hyprland |
| `monitors.lua` | Al menos un monitor `preferred, auto, 1` (como `dev/minimal.conf`), estructura para añadir más | Bajo | `hl.monitor()` — sintaxis, no comportamiento |
| `input.lua` | Teclado, touchpad, sensibilidad | Bajo | `hl.keyword()` o función dedicada de input |
| `appearance.lua` | `blur`, `vibrancy`, `rounding`, `shadow`, `layerrule` — la tabla de traducción CSS→Hyprland que ya escribí en `plan.md` §3.6 | **Alto** | Los nombres exactos de cada propiedad de `decoration:blur:*` en Lua — es donde vive el cristal, no puede quedar aproximado |
| `layouts.lua` | `master`/`dwindle` nativos; `scroll` (0.55+, ya no plugin); `grid`/`focus` **custom vía `hl.layout.register`** | **Alto** | `hl.layout.register(nombre, {recalculate, layout_msg})` — la única API de la que solo tengo la *forma*, no el detalle, según lo que ya quedó anotado en `spec-layouts.md` §0 |
| `workspaces.lua` | `hl.workspace_rule({workspace=..., layout=...})` por cada uno de los 5 workspaces semánticos | Medio | Forma de la tabla que acepta `workspace_rule` |
| `windowrules.lua` | Reglas `opaque`/`noblur` para navegador y editores (clase de ventana), cristal para el resto | Medio | Sintaxis de `hl.window_rule()` y cómo se filtra por clase |
| `keybinds.lua` | Los ~35 binds de `spec-keybinds.md`: `SUPER+letra`, `SUPER+SHIFT+letra`, teclas `XF86*`, scratchpads | **Alto** | `hl.bind()` para modificadores combinados y para nombres `XF86*` — es el módulo con más líneas y más superficie de error |
| `plugins.lua` | Carga de `hyprexpo` | Bajo | Cómo se declara un plugin en Lua — probablemente distinto de `plugin = ruta.so` de hyprlang |
| `exec.lua` | `dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` (verificado en `spec-keybinds.md` §4c), lanzar QuickShell, `swww` | Bajo | Forma de `exec-once` en Lua |

**Los tres módulos de riesgo alto (`appearance`, `layouts`, `keybinds`) se escriben primero**, cada uno verificado contra el wiki en vivo o la fuente de Hyprland antes de pasar al siguiente — no todos al final en un solo repaso.

### Contingencia de verificación — un riesgo real, no teórico

`wiki.hypr.land` me ha bloqueado con protección Anubis (403) **varias veces** en esta misma conversación, cuando intenté verificar Plymouth y otros temas. No puedo asumir que la wiki vaya a responder cuando la necesite para esto. Plan de respaldo, en este orden:

1. `wiki.hypr.land` directo (si responde, es la fuente primaria).
2. Fuente del propio compositor en GitHub (`hyprwm/Hyprland`, vía `raw.githubusercontent.com` — esto sí respondió consistentemente en todo lo que llevamos verificado).
3. Búsqueda + síntesis de varias fuentes independientes (el mismo método que usé para confirmar `exec-once` con `||`, o los paquetes de Plymouth de CachyOS).
4. Si ninguna de las tres da una respuesta con la que me quede tranquilo: lo digo explícitamente en vez de escribir algo a medias — no hay ninguna prisa que justifique adivinar en el archivo del que depende que el sistema arranque.

**Esfuerzo estimado: 2–3 días**, la mayor parte en `appearance.lua`, `layouts.lua` y `keybinds.lua`.

---

## 3. Cimiento de QuickShell

### Qué es "cimiento" y qué no

Cimiento = lo que **todas** las superficies futuras (barra, dock, launcher, widgets, control, notificaciones...) van a heredar o importar. Nada de esto pinta una superficie final — es la base sobre la que el enjambre construye después.

```
stow/quickshell/.config/quickshell/
├── shell.qml              -- entrada, carga los módulos
├── theme/
│   └── Theme.qml           -- singleton: lee qs-theme.json (JSON, no TOML —
│                               matugen renderiza theme.toml → JSON;
│                               QML tiene JSON.parse nativo, no necesita
│                               parser de TOML en tiempo de ejecución)
├── components/
│   ├── GlassSurface.qml     -- el material de cristal reutilizable
│   └── Panel.qml             -- envoltorio del layer-shell base
└── services/
    └── IPC.qml                -- el manejador de los toggles SUPER+SPACE/SUPER+D
```

### Los cuatro archivos, uno por uno

**`Theme.qml`** — riesgo bajo. Lee un JSON ya generado por matugen desde `theme.toml`, lo expone como propiedades. La única duda real: confirmar el mecanismo de recarga en caliente (`FileView` con `onFileChanged` o hay que reiniciar QuickShell) — no bloqueante, se resuelve con una prueba directa una vez QuickShell esté instalado.

**`GlassSurface.qml`** — **riesgo alto, la pieza más delicada de las cuatro.** Es la traducción exacta de lo que ya construí en CSS para el mockup y el tema de LightDM: el `backdrop-filter` (→ `layerrule = blur` + `decoration:blur:vibrancy`), el aro de dispersión cromática (→ un `MultiEffect`/gradiente de borde, no un simple `border`), y el brillo que sigue al puntero (→ `MouseArea` con `positionChanged`, actualizando un gradiente radial). Se verifica **contra el mockup en el navegador**, lado a lado, no contra documentación — ya sé exactamente cómo se ve, el trabajo es que QML lo reproduzca igual de fiel.

**`Panel.qml`** — riesgo medio. Envuelve `PanelWindow` de QuickShell (layer-shell). Necesito confirmar la API real antes de construir sobre ella: anclas, márgenes, y sobre todo `exclusionMode` (`Auto` para la barra que sí reserva espacio, `Ignore` para el dock que flota — la decisión que ya tomamos cuando corregiste que el dock se comía demasiada pantalla). Verificación: documentación de QuickShell (`quickshell.outfoxxed.me`) o su código fuente.

**`IPC.qml`** — riesgo medio. El `IpcHandler` de QuickShell que recibe la orden cuando `hyprland.lua` ejecuta `qs ipc call launcher toggle` (el patrón ya mencionado desde `plan-v2.md`). Depende de que `keybinds.lua` ya exista con los nombres de comando definidos — por eso este archivo va último de los cuatro.

**Esfuerzo estimado: 3–4 días**, con `GlassSurface.qml` llevándose la mitad de eso solo por la verificación visual iterativa contra el mockup.

---

## 4. Calendario total y qué desbloquea cada entrega

| Entrega | Días | Desbloquea |
|---|---|---|
| `theme.toml` | 0.5 | El subagente `theme-templates` deja de depender solo de prosa; `hyprland.lua` y QuickShell tienen de dónde leer color |
| `hyprland.lua` | 2–3 | La sesión de LightDM queda completa de punta a punta (ya referencia `hyprland.desktop`); el subagente `quickshell-surfaces` sabe qué nombres de IPC esperar |
| Cimiento de QuickShell | 3–4 | El subagente `quickshell-surfaces` puede arrancar en serio — es la señal de que el enjambre pasa de "solo plantillas de tema" a trabajar en paralelo de verdad |

**Total: 6–8 días de trabajo mío antes de que el enjambre pueda operar a plena capacidad.** Mientras tanto, `theme-templates` y la parte de `mechanical-tasks` que no depende de nada pueden avanzar en paralelo desde ya — no hace falta que Antigravity espere sentado los 6-8 días completos.

---

## 5. Qué necesito de ti antes de empezar

Una sola cosa, y solo si la tienes a mano: **la configuración real de monitores** (cuántas pantallas, resolución, si hay una externa que uses seguido) para `monitors.lua` — si no la tienes ahora, empiezo con el mismo `preferred, auto, 1` de `dev/minimal.conf` y lo ajustamos cuando despliegues de verdad. No bloquea nada más de la lista.
