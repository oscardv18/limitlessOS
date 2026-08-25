# CLAUDE.md — Limitless OS

Instrucciones para cualquier instancia de Claude Code que abra este repositorio. Lee esto primero.

## ⚠️ Regla más importante de todo el documento

**NUNCA ejecutes `install.sh`, ni ninguna etapa de `install/stages/`, salvo que el usuario te lo pida de forma explícita y ese pedido ocurra en la Fase de Despliegue** (`docs/LIMITLESS-OS.md` §6, `docs/runbook-despliegue.md`) — es decir, cuando **todo** el ecosistema (Fases 1 a 6) ya está construido en el repositorio y hay un CachyOS/Arch recién instalado esperando. Instalar a mitad de la construcción, "para probar", no es aceptable: la construcción entera se hace y se verifica sin tocar una máquina real (sintaxis validada, mockup consultado, `bash -n`/`qmllint` en verde). Si dudas en qué fase estás, pregunta antes de ejecutar cualquier cosa que instale, elimine paquetes, o modifique `/etc`, `mkinitcpio.conf` o el gestor de arranque.

**Este proyecto se construye en paralelo con otro agente (Gemini/Antigravity, en modo enjambre de varios agentes).** El usuario reparte tareas más sencillas a ese enjambre y las más delicadas (arquitectura, sesión, arranque, cualquier cosa que pueda dejar el sistema sin arrancar) las trabaja contigo. Antes de tocar un archivo, revisa `git status`/`git log` por si el enjambre ya lo cambió en paralelo — no asumas que el repo está como lo dejaste tú la última vez.

## Qué es este proyecto

Dotfiles de Hyprland con identidad visual propia (paleta de las técnicas de Satoru Gojo: 蒼 azul `#3b9eff`, 茈 morado `#a970ff`, 赫 rojo `#ff4a2e`), liquid glass real en superficies que se ven pero no se leen, y un ecosistema de terminal coherente de punta a punta. No es una carpeta de configs — es un sistema con instalador propio, router de comandos (`dotctl`), y documentación exhaustiva de cada decisión.

**Portabilidad, como requisito explícito:** el instalador debe funcionar en **CachyOS o cualquier distribución basada en Arch**, no solo CachyOS. Cualquier pieza específica de CachyOS (como la limpieza de `cachyos-plymouth-*` en `00-preflight.sh`) debe estar protegida — verificar que existe antes de asumirlo, nunca fallar si no está presente.

**Arquitectura de sesión** (reemplaza cualquier mención anterior a "sin entorno gráfico" o a `greetd`/`tuigreet`, que se abandonaron tras fallar en la máquina real): GRUB (doble arranque con Windows) → Plymouth desactivado → **LightDM** con tema propio (`lightdm-webkit2-greeter`, HTML/CSS/JS real) → elección de sesión: **Hyprland Limitless** a diario, **XFCE** como red de emergencia (X11, no puede competir con el stack Wayland de Hyprland). Ver `docs/LIMITLESS-OS.md` §2.

## Primero: lee `docs/`

`docs/LIMITLESS-OS.md` es el plan maestro — léelo entero antes de tocar nada. Los demás documentos son specs de una pieza concreta:

| Documento | Cuándo consultarlo |
|---|---|
| `docs/LIMITLESS-OS.md` | Siempre primero. Fases de construcción, arquitectura de sesión, ecosistema completo |
| `docs/plan.md` | Identidad visual, liquid glass, fases del shell QuickShell |
| `docs/plan-automation.md` | `dotctl`, migraciones, patrones de Omarchy |
| `docs/spec-layouts.md` | Layouts por workspace, terminal, Hyprland 0.55+/0.56 |
| `docs/spec-keybinds.md` | **Tabla definitiva de atajos**, incluidas teclas de función de portátil (brillo, volumen, avión, pantalla externa) y la configuración de OBS/pantalla compartida. SUPER es la tecla líder — nunca inventes un bind sin mirar aquí primero |
| `docs/spec-colorscheme.md` | El tema de Neovim, con la medición de contraste |
| `docs/spec-package-panel.md` | Buscador de paquetes |
| `docs/runbook-despliegue.md` | **Solo para la Fase de Despliegue.** No lo ejecutes si sigue quedando construcción pendiente |
| `docs/mockups/limitless-shell.html` | Mockup interactivo del shell completo — verificado, funcional, es la referencia visual |

`docs/plan-v2.md` es histórico (una revisión intermedia superada por `LIMITLESS-OS.md`); no lo tomes como fuente de verdad si contradice a los documentos de arriba.

## Qué hacer ahora mismo

Revisa `docs/LIMITLESS-OS.md` §6 para ver qué fase de construcción sigue abierta, y trabaja en eso — escribiendo código y configuración en el repositorio, verificándolo por los medios disponibles sin instalación real (sintaxis, mockup, lint). **No ejecutes `install.sh` ni `docs/runbook-despliegue.md`** hasta que el usuario confirme que todas las fases de construcción están cerradas y pide explícitamente el despliegue.

Tienes acceso de ejecución real que la sesión de Windows no tenía — úsalo para lo que sí corresponde ahora: correr `bash -n` sobre scripts, `qmllint` sobre QML, abrir el mockup en un navegador para contrastar diseño, correr `dotctl doctor` en modo lectura. No te limites a leer y describir lo que haría; hazlo — pero dentro de los límites de "construir", no "instalar".

## Reglas que no son negociables

**No adivines sintaxis de Hyprland 0.55+/0.56 en Lua.** Todo el proyecto se escribe en Lua (hyprlang está deprecado), pero durante el diseño no fue posible extraer con confianza los nombres exactos de campos del wiki. `dev/minimal.conf` se dejó deliberadamente en hyprlang viejo por este motivo — es la única excepción, documentada en su propia cabecera. Cuando escribas `hyprland.lua` real (Fase 1), verifica cada función de la API (`hl.bind`, `hl.workspace_rule`, `hl.layout.register`, etc.) contra el wiki en vivo o el código fuente, línea a línea. No copies de memoria ni extrapoles de los ejemplos de este repo.

**SUPER es la tecla líder.** `docs/spec-keybinds.md` es la fuente de verdad de todos los atajos, incluidas las teclas de función del portátil (§4b, sin modificador — son teclas físicas dedicadas) y la configuración de OBS/pantalla compartida (§4c). Contiene colisiones reales ya resueltas — no las repitas — y varias correcciones de "lo que el mockup usaba sin modificador, por limitación del navegador" vs. "lo que el sistema real necesita". Léela antes de escribir un solo `bind`.

**El mockup manda sobre el código.** `docs/mockups/limitless-shell.html` es la referencia visual verificada — colores exactos, geometría, comportamiento de animación. Cuando construyas QuickShell (Fase 4), el mockup se consulta antes de improvisar estética nueva. Si necesitas cambiar el diseño, cambia el mockup primero y verifícalo en el navegador antes de tocar QML.

**Ningún hex literal fuera de `themes/`**, una vez exista `theme.toml` (todavía no existe — es de las piezas grandes pendientes). Hoy la paleta vive escrita a mano en `stow/nvim/.config/nvim/colors/limitless.lua`, `stow/starship/.config/starship.toml`, `system/grub/theme/theme.txt` y `install/lib/ui.sh`; es una excepción temporal y documentada, no el estado final.

**Cristal donde adorna, opacidad donde se lee.** Terminal y superficies del shell llevan blur real; navegador, editores y cualquier cosa con texto denso van opacas a propósito. No es una renuncia estética, es la regla del proyecto.

**Verifica antes de afirmar.** Este proyecto se construyó verificando cada librería, paquete y sintaxis contra fuentes reales antes de escribir código sobre ellas — varias veces se corrigieron suposiciones equivocadas a mitad de camino (Hyprland cambió de `.conf` a Lua entre sesiones; `tuigreet` no acepta hex, solo nombres ANSI; `nvtop` pasó de AUR a repos oficiales; Plymouth resultó ser la causa real de un cuelgue de arranque que se atribuyó primero al greeter). Si vas a instalar un paquete o usar una API que no has visto documentada en este repo, comprueba que existe y con ese nombre exacto antes de escribirlo en `packages/*.txt` o en un script.

**Cambios de arquitectura se documentan donde ya viven las decisiones anteriores, no se borran en silencio.** Cuando algo se abandona (como `greetd`/`tuigreet`, o "sin entorno gráfico"), la sección correspondiente se reemplaza explicando qué cambió y por qué — no se elimina sin dejar rastro. Así cualquier agente que vuelva a esa sección entiende la decisión en vez de repetir un error ya corregido.

## Estado del proyecto (verifica en `docs/LIMITLESS-OS.md` §6 si esto queda desactualizado)

**Código real, ya escrito:**
- Instalador TUI completo (`install.sh` + `install/`, 10 etapas, probado con corrida simulada completa, reanudación y fallo-con-continuación) — **sin ejecutar en una máquina real todavía, y no debe ejecutarse hasta el despliegue**
- `bin/dotctl` (router) + `bin/cmd/doctor` (7 chequeos)
- zsh completo (`stow/zsh/`, 7 módulos — sustituye a fish con autosuggestions + fast-syntax-highlighting + fzf-tab)
- Neovim (`colors/limitless.lua`, 210 grupos), Starship (`starship.toml`, 33 módulos)
- Tema de GRUB (`system/grub/theme/`), paleta del VT (`system/vconsole/`)
- Desinstalación de Plymouth (`install/stages/00-preflight.sh`, verificada con simulacro de sistema de archivos)
- `dev/minimal.conf` — configuración de rescate, hyprlang (ver regla de arriba)
- **LightDM completo** (`system/lightdm/`): tema `lightdm-webkit2-greeter` en HTML/CSS/JS real (cristal, campo de colisión, selector de sesión, botones de energía — API de `window.lightdm` verificada contra el manual, probado end-to-end sirviendo el tema por HTTP local con un `window.lightdm` simulado), `lightdm.conf.d/50-limitless.conf`, `hyprland-limitless.desktop` (invocación `uwsm start -- hyprland.desktop`, verificada), y `install/stages/60-session.sh` reescrito — ya no instala `greetd`
- **`hyprland.lua` completo** (Fase 1, `stow/hypr/.config/hypr/`): 10 módulos en `lua/` (env, monitors, input, appearance, layouts, workspaces, windowrules, keybinds, plugins, exec), los 31+1 binds de `spec-keybinds.md` §3.1-3.4 traducidos, blur/vibrancy y el `layer_rule` de cristal para QuickShell, layouts `grid` nativo (el custom `focus` queda sin implementar a propósito — ver el propio archivo — pendiente de verificar en hardware real)
- **`themes/hud-void/theme.toml`** — esquema de color completo, gobierna Neovim + Starship + GRUB + LightDM sin un hex fuera de `themes/`; extendido en Fase 4 con `[color.constant].six_eyes` para el aro de QuickShell
- **Fase 3 (Sesión)**: `hyprlock.conf` + `hypridle.conf` (`stow/hypr/.config/hypr/`) — pantalla de bloqueo traducida del mockup (kanji, reloj, campo en píldora), cadena de inactividad de tres escalones (atenuar → bloquear → DPMS off). Colores vía `source = ~/.config/hypr/hyprlock-colors.conf`, contrato para la plantilla de matugen de `hyprlock` (variables `$accent $accent_core $surface_hi $line $text $text_dim $reversal $void`, todavía sin escribir por el enjambre)
- **Cimiento de QuickShell** (Fase 4, `stow/quickshell/.config/quickshell/limitless/`): `Theme.qml` (singleton, lee `theme.toml` con un parser TOML propio, técnica activa conmutable por IPC target `theme`), `GlassSurface.qml` (el material de cristal — aro de dispersión cromática + realces, blur real delegado a Hyprland vía `layer_rule`), `Panel.qml` (PanelWindow + GlassSurface listos para heredar), `IPC.qml` (patrón toggle reutilizable), `shell.qml` (entrada mínima de prueba, no la barra real todavía). Validado a mano (balance de llaves/paréntesis/corchetes) — `qmllint` no está disponible en este entorno Windows
- **Antigravity/enjambre ya entregó** (mecánico, `mechanical-tasks`): panel de paquetes (`bin/cmd/pkg`, `pkg-install`, `pkg-remove`, `pkg-search`), envoltorio de Discord (`bin/discord-wayland` + `stow/applications/.../discord.desktop`), `bin/cmd/tui-install`, CI de lint (`.github/workflows/lint.yml`)
- `packages/pacman.txt` ya incluye `lightdm`, `lightdm-webkit2-greeter`, `xfce4`, `xfce4-terminal`, `obs-studio`, `hyprlock`, `hypridle`

- **Pipeline de tema completo** (Fase 2): `bin/cmd/theme-export` traduce `theme.toml` a `themes/matugen.toml` (`[config.custom_colors]`, `blend=false` — matugen deriva de una imagen o un color semilla, no acepta una paleta fija, así que la semilla se ignora y las plantillas solo leen `{{custom.*}}`). 11 plantillas en `themes/_templates/` → 13 destinos: Ghostty, btop, fzf, lazygit, lazydocker, yazi, bat, delta, herdr, GTK3+GTK4, qt6ct+qt5ct. `hyprlock-colors.conf` lo escribe el propio script (formato `rgba()` nativo de Hyprland, no pasa por matugen)
- **`dotctl` completo** (Fase 5): `shell`, `scratch`, `lock`, `capture`, `layout`, `theme`, `display`, `osd`, `dev`, `migrate`, `herdr-bridge`, `power-profile` — más los que ya había (`doctor`, `pkg*`, `tui-install`, `theme-export`). Todos con cabecera de metadatos, todos enrutados por `bin/dotctl`
- **Puente herdr → HUD** (`bin/cmd/herdr-bridge`, §4.1): sondea el socket UNIX de herdr (`agent.list`) y publica por IPC a `Bar.qml`, que pinta un punto por agente. Parseo defensivo a propósito — ver la cabecera del script
- **Motor de sesiones de proyecto** (`bin/cmd/dev`): workspace + editor + herdr + lazygit-si-está-sucio
- **Migraciones** (`bin/cmd/migrate` + `migrations/1756000000-greetd-retirado.sh` como primera y plantilla del patrón)
- **Degradación por batería** (`bin/cmd/power-profile`, Fase 6) — números sin calibrar en hardware, ver la nota del propio archivo

- **Campo de colisión y cromo HUD** (`Field.qml`, `Wallpaper.qml`, `Chrome.qml`): el fondo animado 蒼+赫→茈 portado del mockup, un motor con tres presets. Se suspende al bloquear (`hypridle.conf`) con red de seguridad por si `unlock_cmd` no llega (fallo conocido: hyprwm/hypridle#79). **Leer la advertencia de rendimiento en la cabecera de `Field.qml` antes de tocarlo** — Qt desaconseja Canvas animado a pantalla completa, está mitigado con `renderScale` pero NO medido
- **Animación de aparición de todas las superficies** (`Reveal.qml`): las 8 superficies modales funden con escala en 340 ms, con la curva del mockup. Regla que se rompe fácil: una superficie fija `shown`, **nunca `visible`** — ese está reservado para mantener la ventana viva durante la salida
- Superficie de portapapeles (`Clipboard.qml`, `SUPER+V`) y el dock con IPC propio (fijar/esconder)

- **Datos reales en todas las superficies**: la barra lee workspaces de `Quickshell.Hyprland`, batería de `UPower`, CPU/MEM de `/proc` (`SysInfo.qml`); los widgets usan MPRIS para música, `wttr.in` para clima y fecha real; el panel de paquetes lista lo instalado de verdad; el de proyectos escanea git vía `dotctl dev scan`. **Ninguna superficie enseña datos inventados** — donde no hay fuente real (agenda, GPU, estado de pruebas) se dice, no se rellena
- **Dock en rueda** (`Dock.qml`): la noria del mockup con su geometría exacta (radio 880, arco 0.78 rad), giro con la rueda del ratón y magnificación tipo macOS
- **Salvapantallas** (`Screensaver.qml`): el preset `saver` del campo, disparado por hypridle a los 90 s; suspende el fondo mientras está activo
- **`dotctl update`** — la secuencia completa de `plan-automation.md` §6

**Sin construir todavía:**
- **Spike del shader de refracción** (Fase 6) — requiere perfilado en hardware real, no se puede cerrar desde aquí
- El layout custom `focus` (`lua/layouts.lua` lo deja sin implementar a propósito — falta confirmar la API de foco de Hyprland)
- La plantilla de matugen de herdr está incompleta a propósito: solo 2 claves confirmadas, se completa con `herdr --default-config` en la máquina real
- El preset `lock` del campo no se usa: hyprlock es un binario aparte y no puede ejecutar QML (ver el comentario en `Field.qml`)

## Convenciones de commit y git

- Mensajes de commit en español, estilo del historial existente: línea de asunto corta, cuerpo explicando el *porqué*, sin emojis.
- El repo usa `.gitattributes` para forzar LF — no lo desactives ni lo pises.
- Antes de cualquier `git push --force`, `git reset --hard` o similar: para y pregunta. El historial de este repo es corto y no hay razón para reescribirlo sin que el usuario lo pida explícitamente.
- No hagas commit ni push a menos que el usuario lo pida — igual que en cualquier repo, pero vale la pena decirlo aquí porque esta sesión probablemente va a estar ejecutando comandos reales sobre el sistema y es fácil encadenar un `git commit` automático sin que se haya pedido. Con un enjambre de agentes trabajando en paralelo, es todavía más fácil pisar el trabajo de otro con un commit apresurado — revisa el diff completo antes.

## Tono

El usuario lleva toda la conversación en español; sigue en español salvo que te pida lo contrario. El proyecto tiene una identidad estética muy definida (HUD futurista, Gojo, "liquid glass") — no la diluyas por comodidad técnica sin consultarlo primero.
