# Limitless OS — Plan definitivo de construcción

> Documento maestro. Sustituye la Fase 0 de `plan.md` y consolida `plan-automation.md`, `spec-layouts.md`, `spec-package-panel.md` y `spec-colorscheme.md`.
> Escenario real: **CachyOS base, sin entorno gráfico, sin ningún DE.** Solo TTY.

---

## 0. Lo que cambia respecto a todo lo planificado antes

Dos hechos nuevos invalidan consejos que te di:

**1. No hay entorno de respaldo.** Mi Fase 0 decía "instala Hyprland junto a tu DE actual y déjalo como salvavidas". Eso ya no existe: si Hyprland no arranca, no hay a dónde caer. **La red de seguridad hay que rediseñarla entera** (§1).

**2. herdr no es un multiplexor genérico.** Yo te dije en `spec-layouts.md` §3.3 que los multiplexores locales sobran cuando el WM ya tilea. Con herdr eso **no aplica**: no es tmux, es un runtime de agentes con detección de estado en cuatro colores (bloqueado, trabajando, hecho, inactivo). Hyprland no puede hacer ese trabajo. Y esos cuatro estados son la mejor oportunidad de integración de todo el proyecto (§3.4).

---

## 1. La red de seguridad sin GUI

Sin DE de respaldo, el riesgo cambia de "queda feo" a "no puedo usar el ordenador". Tres capas, de más barata a más contundente.

### Capa 1 — El TTY nunca se va

`Ctrl+Alt+F2` siempre te da una consola, arranque Hyprland o no. Toda la administración del sistema debe ser posible desde ahí, y por eso **la mitad del ecosistema son herramientas TUI** (§3). No es estética: es que sin GUI, `impala` y `bluetui` son la *única* forma de arreglar la red.

### Capa 2 — Instantáneas arrancables desde GRUB

> **Situación real: CachyOS ya está instalado, con GRUB.** El plan original asumía Limine por su menú de instantáneas. No hace falta cambiar de gestor de arranque: GRUB da lo mismo con tres paquetes.

```bash
paru -S --needed snapper snap-pac grub-btrfs
sudo systemctl enable --now grub-btrfsd
```

Qué aporta cada uno:

| Paquete | Función |
|---|---|
| `snapper` | Gestiona las instantáneas Btrfs y sus políticas de retención |
| `snap-pac` | Enganche de pacman: instantánea **pre y post** en cada transacción, automáticamente |
| `grub-btrfs` | Añade a GRUB un submenú **«Arch Linux snapshots»** con cada instantánea, por fecha y descripción |
| `grub-btrfsd` | Demonio que vigila las instantáneas nuevas y regenera el menú solo |

Resultado: si `pacman -Syu` rompe el sistema, reinicias, entras al submenú de instantáneas y arrancas la de antes de la actualización. **Es exactamente el salvavidas de Limine, sobre GRUB.**

Detalle a tener presente: las instantáneas arrancan en **solo lectura**. Sirven para diagnosticar y para hacer rollback, no para trabajar desde ellas.

> ADVERTENCIA: **todo esto exige que la raíz sea Btrfs.** Si CachyOS se instaló sobre ext4, esta capa no existe y hay que sustituirla — ver Capa 2b. Verifícalo con `findmnt -no FSTYPE /`.

### Capa 2b — Si la raíz NO es Btrfs

Sin Btrfs no hay instantáneas del sistema, y la red de seguridad cambia de forma:

- **El riesgo real baja de categoría.** Lo que más se rompe en este proyecto no es el sistema, es *tu configuración* — y de eso protege git, no Btrfs: `git -C ~/.limitless checkout HEAD~1 && dotctl restow`.
- **Para el sistema**: `timeshift` en modo rsync da copias restaurables, aunque no arrancables desde GRUB.
- **Pin de versión de Hyprland** en `packages/`, para que una actualización del compositor nunca te sorprenda.
- **Un USB de arranque en el cajón**, con el procedimiento escrito en el README.

No es tan cómodo, pero cubre el caso que de verdad te va a pasar.

### Capa 3 — Configuración mínima conocida-buena

En el repo, `dev/minimal.lua`: una config de Hyprland de ~30 líneas sin plugins, sin Quickshell, sin cristal. Solo un compositor que arranca y abre un terminal. El procedimiento de rescate se reduce a:

```
Ctrl+Alt+F2  →  Hyprland -c ~/.limitless/dev/minimal.lua
```

Si eso arranca, el problema está en tu configuración. Si no arranca, es el sistema, y toca instantánea. **Ese diagnóstico de 30 segundos es lo que evita las noches perdidas.**

### El procedimiento, escrito antes de necesitarlo

`README.md` debe abrirse con esto, no enterrarlo:

| Síntoma | Acción |
|---|---|
| Hyprland no arranca | `Ctrl+Alt+F2` → `Hyprland -c ~/.limitless/dev/minimal.lua` |
| Arranca pero sin barra ni dock | `qs -c limitless` en un terminal, leer el error |
| Rompió tras `dotctl update` | `limitless rollback` (última instantánea) |
| Rompió tras `pacman -Syu` | Reiniciar → GRUB → submenú **Arch Linux snapshots** |
| Sin red desde TTY | `nmtui` o `impala` |
| No sé qué pasa | `dotctl doctor` |

---

## 2. Cómo se entra a Limitless

Sin DE, el arranque de sesión hay que decidirlo. Tres opciones:

| | Ruta | Pro | Contra |
|---|---|---|---|
| A ✅ | **Autologin en TTY1 → uwsm lanza Hyprland → hyprlock bloquea al instante** | **La pantalla de login que ya diseñaste ES tu login.** Cero componentes extra, coherencia total | Requiere cifrado de disco para ser seguro |
| B | `greetd` + `tuigreet` | Greeter TUI, ligero, correcto | Es una pantalla fea antes de tu pantalla bonita. Duplica el concepto de login |
| C | SDDM | Familiar | Arrastra Qt y un tema más que mantener, para una pantalla que ves 3 segundos |

**Recomiendo A si el disco está cifrado con LUKS.** Con cifrado, la puerta real es la contraseña del arranque: el autologin posterior no debilita nada y hyprlock protege la sesión en caliente.

**Si el disco NO está cifrado** —y con CachyOS ya instalado, eso está decidido— hay que elegir a conciencia:

| Situación | Recomendación |
|---|---|
| Sobremesa, en casa, nadie más accede | **A igualmente.** El riesgo es físico y lo asumes conscientemente. Ganas tu pantalla de login diseñada |
| Portátil, o el equipo sale de casa | **B: `greetd` + `tuigreet`.** Sin cifrado, el autologin convierte el robo del equipo en robo de datos |

Con B no pierdes la pantalla que diseñaste: `tuigreet` es solo el portero, y hyprlock sigue siendo lo que ves al bloquear y reanudar, que es el 95% de las veces que la miras.

Verifica el cifrado con `lsblk -f` — si aparece `crypto_LUKS`, estás cubierto.

---

## 3. El ecosistema

La regla que lo unifica: **si existe una TUI decente, la TUI gana.** No por estética — porque funciona en el TTY cuando la sesión gráfica no arranca, se tematiza desde `theme.toml`, arranca instantánea y se controla por teclado.

### 3.1 Base del sistema

| Rol | Herramienta | Nota |
|---|---|---|
| Compositor | `hyprland` | Config en **Lua** (0.55+), ver `spec-layouts.md` §0 |
| Sesión | `uwsm` | Envuelve Hyprland en unidades systemd: los servicios mueren limpio |
| Portal | `xdg-desktop-portal-hyprland`, `-gtk` | Compartir pantalla, selectores de archivo |
| Polkit | `hyprpolkitagent` | Sin él, nada que pida root gráficamente funciona |
| Audio | `pipewire`, `wireplumber`, `pipewire-pulse` | |
| Red | `networkmanager` | |
| Bloqueo / idle | `hyprlock`, `hypridle` | Es tu pantalla de login (§2) |
| Fondo | `swww` | Hasta que el campo de colisión viva en Quickshell |
| Shell | `quickshell` | Barra, dock, launcher, paneles |
| Cursores | `hyprcursor` + tema | |

### 3.2 Terminal y shell

| Rol | Herramienta |
|---|---|
| Terminal | **ghostty** (`spec-layouts.md` §4) |
| Shell | **zsh** + plugins sueltos, sin framework |
| Prompt | **starship** — ya escrito, `stow/starship/` |
| Sugerencias | `zsh-autosuggestions` |
| Resaltado | `fast-syntax-highlighting` |
| Completado | `zsh-completions` + `fzf-tab` |
| Agentes / sesiones | **herdr** |
| Salto de directorio | `zoxide` |
| Búsqueda difusa | `fzf` |
| Grep / find / ls / cat | `ripgrep`, `fd`, `eza`, `bat` |
| Disco | `dust`, `duf` |
| Procesos | `procs` |

#### Por qué zsh, y qué hay que añadirle

**Decidido: zsh.** Yo recomendaba fish por sus valores por defecto, pero el argumento decisivo va en contra: **fish no es compatible con POSIX**. Cada `source install.sh` que copies de internet, cada instalador de versiones (nvm, sdkman, rustup, pyenv) y cada fragmento de la documentación de un proyecto asume bash o zsh. Con fish acabas manteniendo traducciones o abriendo un bash solo para eso. Para alguien que vive en la terminal y copia fragmentos a diario, zsh es la elección correcta.

Lo que fish trae de fábrica y a zsh hay que darle — tres paquetes, **sin framework**:

| Paquete | Qué aporta |
|---|---|
| `zsh-autosuggestions` | Sugerencia en gris del historial mientras escribes |
| `fast-syntax-highlighting` | Comandos válidos en verde, inválidos en rojo, en vivo |
| `zsh-completions` + `fzf-tab` | Completado rico, con el menú en fzf tematizado |

**Sin oh-my-zsh.** Es lento, opaco, y la mitad de lo que aporta ya lo cubre Starship. Tres `source` en el `.zshrc`, paquetes gestionados por pacman, y controlas exactamente lo que corre.

**Dos ganancias que fish no tenía:** `bindkey -v` te da modo vi nativo —coherente con Neovim, y el `vicmd_symbol` del prompt ya está configurado— y todo script POSIX funciona sin traducir.

**Coste añadido:** dos plantillas de tema más. El color de la sugerencia (`ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE`) y la paleta del resaltado tienen que salir de `theme.toml` como todo lo demás.

### 3.3 Desarrollo

| Rol | Herramienta |
|---|---|
| Editor | **neovim** + tema `limitless` (ya escrito) |
| Git | **lazygit** |
| Diff | `delta` (dentro de git y lazygit) |
| Contenedores | **lazydocker** |
| GitHub | `gh` |
| JSON / YAML | `jq`, `yq` |
| HTTP | `posting` (TUI) o `xh` |
| Bases de datos | `lazysql` |
| Rendimiento | `hyperfine` |

### 3.4 Sistema — indispensables sin GUI

Estas no son opcionales: **son la única interfaz que tendrás si la sesión gráfica falla.**

| Rol | Herramienta |
|---|---|
| Recursos | **btop** |
| GPU | `nvtop` |
| Wi-Fi | **impala** |
| Bluetooth | **bluetui** |
| Audio | `wiremix` |
| Servicios | `systemctl-tui` |
| Archivos | **yazi** |
| Registros | `lnav` |
| Paquetes | `paru` + el panel `dotctl pkg` |

### 3.5 Medios

`mpv`, `imv` (imágenes), `zathura` (PDF), `rmpc` (música). Todos ligeros y con configuración en texto plano, o sea tematizables.

---

## 4. Lo que convierte una lista en un ecosistema

Instalar 40 paquetes no es un sistema operativo. Estas cinco integraciones sí:

### 4.1 herdr → HUD *(la mejor idea de este documento)*

herdr detecta cuatro estados por agente: **bloqueado, trabajando, hecho, inactivo**. Y tu paleta tiene exactamente cuatro registros:

| Estado herdr | Color Limitless | Lectura |
|---|---|---|
| Bloqueado — te necesita | `#ff4a2e` 赫 | Reversión: algo te espera |
| Trabajando | `#ffd25e` ámbar | En curso |
| Hecho | `#3b9eff` 蒼 | Atracción: listo para revisar |
| Inactivo | `#6b7f9e` atenuado | Ruido de fondo |

**La integración:** un puente lee el estado de herdr y lo publica por IPC a Quickshell. La barra muestra un grupo de puntos —uno por agente— con su color. Un agente que se bloquea **enciende un punto rojo en la barra aunque el terminal esté en otro workspace**, y dispara una notificación con el material de cristal.

Dejas de tener que mirar si el agente terminó. El escritorio te lo dice. Esto no existe en ningún rice ni en Omarchy: es propio de tu flujo.

### 4.2 Las TUI son ciudadanas de primera

`lazygit`, `btop`, `lazydocker`, `yazi`, `impala` no son "cosas que abres en un terminal". Cada una recibe:

- Una entrada `.desktop` generada, para que el **launcher las encuentre** como cualquier app.
- Un **glifo** en el dock, coherente con el v12.
- Un **scratchpad** propio cuando tiene sentido: `SUPER+G` lazygit sobre el proyecto actual, `SUPER+SHIFT+M` btop.
- Un terminal flotante con **geometría y opacidad propias**, no la ventana genérica.

`dotctl tui-install <cmd> <nombre> <glifo>` lo genera todo. Es el mismo truco que `webapp-install` de Omarchy, aplicado a TUIs.

### 4.3 Sesiones de proyecto reales

`dotctl dev open <proyecto>` (el panel `P` del mockup):

1. Workspace `code`, layout `master`.
2. Editor en el master, en el directorio del proyecto.
3. **Sesión de herdr** restaurada con sus paneles y agentes.
4. lazygit en el stack si el repo está sucio.
5. Rama y estado de pruebas a la barra.

### 4.4 Un solo color para todo

`theme.toml` → matugen → **todo**: Hyprland, Quickshell, Ghostty, Neovim, Starship, btop, lazygit, yazi, bat, delta, fzf, GTK, Qt, hyprlock. Pulsar `T` recolorea el sistema entero sin reiniciar nada.

### 4.5 Un solo punto de entrada

`dotctl` para todo, y el menú del HUD generado desde las cabeceras de los scripts (`plan-automation.md` §4). Escribes un script nuevo y aparece en el menú.

---

## 5. El instalador

### 5.1 Arranque desde TTY pelado

CachyOS ya está instalado, así que el punto de partida es una consola con sesión iniciada:

```
1. Red:            nmtui        (o iwctl si NetworkManager no está)
2. sudo pacman -S --needed git base-devel
3. git clone <repo> ~/.limitless
4. cd ~/.limitless && ./install.sh
5. reboot
```

Cinco pasos, todos escribibles a mano. Sin `curl | bash`: el repo se clona **antes** de ejecutar nada, para que puedas leer lo que vas a correr.

### 5.2 Arquitectura por etapas

`install.sh` es un despachador; la lógica vive en `install/` numerada:

| Etapa | Qué hace |
|---|---|
| `00-preflight` | Verifica arquitectura, red, espacio y que no seas root. **Instala y activa `snapper`+`snap-pac`+`grub-btrfs` si la raíz es Btrfs**, y crea la primera instantánea antes de tocar nada |
| `10-core` | Paquetes oficiales desde `packages/pacman.txt` |
| `20-aur` | Instala `paru` si falta, luego `packages/aur.txt` |
| `30-services` | Habilita pipewire, NetworkManager, bluetooth, seatd |
| `40-stow` | Enlaza las configuraciones |
| `50-theme` | matugen genera los temas de las ~14 aplicaciones |
| `60-session` | Autologin + uwsm + hyprlock (§2) |
| `70-shell` | zsh por defecto, plugins, starship, zoxide, fzf-tab |
| `80-tui` | Entradas `.desktop` de las TUI (§4.2) |
| `90-verify` | `dotctl doctor` y resumen |

Reglas para todas: **idempotentes** (ejecutar dos veces no rompe nada), **marcadas** en `~/.local/state/limitless/stages/`, y **reanudables** con `./install.sh --from=50`. Si la etapa 20 falla compilando un paquete AUR a las dos horas, no repites desde cero.

### 5.3 Orden que importa

`30-services` va **antes** que `60-session`: si el autologin arranca Hyprland sin pipewire ni polkit habilitados, entras a una sesión rota y sin GUI para arreglarla. Y `90-verify` termina diciéndote explícitamente si es seguro reiniciar.

---

## 6. Fases de construcción

| Fase | Contenido | Terminas cuando |
|---|---|---|
| **0 · Terreno** | Auditar lo ya instalado. Activar instantáneas en GRUB. Repo, `install.sh` con etapas vacías, `dev/minimal.lua`, rescate en el README | Ves el submenú de instantáneas en GRUB **y** arrancas `Hyprland -c dev/minimal.lua` desde TTY |
| **1 · Núcleo** | `hyprland.lua` modular, cristal, workspaces semánticos, scratchpads, **`theme.toml` + matugen operativos** | Sesión completa por teclado, con un solo tema gobernando todo |
| **2 · Habitable** | Ghostty, zsh + 3 plugins, starship, neovim, yazi, btop, lazygit, herdr, impala, bluetui, portapapeles, capturas | **Trabajas el día entero aquí.** Hito crítico |
| **3 · Sesión** | greetd + tuigreet + paleta del VT, hyprlock, hypridle, notificaciones, OSD, uwsm | Entras desde el greeter, bloqueas, reanudas y el sistema te avisa |
| **4 · Shell** | Quickshell en el orden de `plan.md` §7: cromo → campo → barra → dock → launcher → notificaciones → OSD | Un solo motor de shell, con el material de `plan.md` §3.6 |
| **5 · Ecosistema** | **Puente herdr→HUD**, sesiones de proyecto, paneles de control y paquetes, `dotctl` completo, migraciones | El sistema se comporta como un producto |
| **6 · Pulido** | Gestos, degradación por batería, spike del shader, CI de lint, README con capturas | Repo publicable |

**La Fase 2 vuelve a ser el hito.** Sin DE de respaldo tienes aún más razón para llegar rápido a un sistema usable: mientras no lo sea, tu ordenador no lo es.

---

## 7. Lo que hay que crear

Me preguntaste explícitamente. Esto es lo que **no existe** y hay que escribir:

### Imprescindible

| Pieza | Esfuerzo | Nota |
|---|---|---|
| **Instalador por etapas** | 2–3 días | §5. El más crítico: sin GUI, un instalador a medias te deja sin sistema |
| **`hyprland.lua` modular** | 2 días | En Lua desde el commit 1 |
| **`dotctl` + cabeceras** | 1 tarde | El router (`plan-automation.md` §3) |
| **`dev/minimal.lua`** | 1 hora | Config de rescate. La hora mejor invertida del proyecto |
| **Shell de Quickshell** | 2–3 semanas | La pieza grande. Diseño ya cerrado en el mockup |
| **Layouts Lua** (scroll, focus, grid) | 2–3 días | `hl.layout.register` — ya no hacen falta plugins |

### Plantillas de tema — 14 pendientes

Ya escritos: **Neovim** y **Starship**. Faltan, y cada uno es un formato distinto: Ghostty, btop, lazygit, lazydocker, yazi, bat, delta, fzf, hyprlock, GTK3/4, Qt/Kvantum, herdr, **zsh-autosuggestions** y **fast-syntax-highlighting**. Cuenta **1–2 horas cada uno**; es trabajo mecánico pero hay que hacerlo o el sistema se ve inconsistente.

### Integraciones propias — lo que no existe en ningún sitio

| Pieza | Esfuerzo | Por qué importa |
|---|---|---|
| **Puente herdr → Quickshell** | 2–3 días | §4.1. Lo más original del proyecto |
| **`dotctl tui-install`** | 1 día | Convierte cualquier TUI en app de primera clase |
| **Motor de sesiones de proyecto** | 2–3 días | §4.3 |
| **`dotctl doctor`** | 1–2 días | Tu herramienta más usada |
| **Sistema de migraciones** | 1 día | `plan-automation.md` §5 |
| **Panel de paquetes** | 1 día (fzf) | `spec-package-panel.md` |

### Decisiones que necesito de ti

1. **Salida de `lsblk -f` y `findmnt -no FSTYPE /`** — determina la capa 2 (§1) y el modo de login (§2). Ya está decidido por la instalación; solo hay que leerlo.
2. ~~¿fish o zsh?~~ **Decidido: zsh** (§3.2).
3. ~~¿Ruta del repo?~~ **Decidido: `~/.limitless`**.
4. **¿Qué agentes usas en herdr?** Única pendiente. Determina qué muestra el puente del §4.1, y no bloquea nada hasta la Fase 5.

---

## 8. El primer paso

**No escribas configuración todavía.** El orden correcto es:

1. **Auditar el sistema instalado**: sistema de archivos, cifrado, subvolúmenes, paquetes de instantáneas.
2. **Montar la red de seguridad primero**: `snapper` + `snap-pac` + `grub-btrfs`, y comprobar que el submenú aparece en GRUB. Antes de instalar nada más.
3. Desde TTY: git, clonar, y **verificar que `dev/minimal.lua` arranca**.
4. Solo entonces, la Fase 1.

El paso 2 va antes que todo lo demás a propósito: es la única parte del plan que te protege **mientras construyes el resto**. Y el paso 3 parece trivial pero decide si el proyecto es cómodo o doloroso — un compositor que arranca desde 30 líneas es la diferencia entre depurar y adivinar.
