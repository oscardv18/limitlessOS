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

En el repo, `dev/minimal.conf`: una config de Hyprland de ~30 líneas sin plugins, sin Quickshell, sin cristal. Solo un compositor que arranca y abre un terminal. El procedimiento de rescate se reduce a:

```
Ctrl+Alt+F2  →  Hyprland -c ~/.limitless/dev/minimal.conf
```

Si eso arranca, el problema está en tu configuración. Si no arranca, es el sistema, y toca instantánea. **Ese diagnóstico de 30 segundos es lo que evita las noches perdidas.**

### El procedimiento, escrito antes de necesitarlo

`README.md` debe abrirse con esto, no enterrarlo:

| Síntoma | Acción |
|---|---|
| Hyprland no arranca | `Ctrl+Alt+F2` → `Hyprland -c ~/.limitless/dev/minimal.conf` |
| Arranca pero sin barra ni dock | `qs -c limitless` en un terminal, leer el error |
| Rompió tras `dotctl update` | `limitless rollback` (última instantánea) |
| Rompió tras `pacman -Syu` | Reiniciar → GRUB → submenú **Arch Linux snapshots** |
| Sin red desde TTY | `nmtui` o `impala` |
| No sé qué pasa | `dotctl doctor` |

---

## 2. Cómo se entra a Limitless

> **Decisión revisada — supera a las tres opciones (autologin / greetd+tuigreet / SDDM) que este documento barajaba antes.** El motivo del cambio: se probó la ruta de "sin entorno gráfico en absoluto" en la máquina real y falló — Plymouth se colgó en el traspaso de pantalla y no hubo forma de caer a nada gráfico, solo TTY a mano. La arquitectura actual añade una red de seguridad *gráfica* real, no solo una consola de rescate.

**LightDM, con dos sesiones a elegir en cada arranque: Hyprland Limitless (a diario) o XFCE (emergencia).** Ambas cuelgan del mismo gestor de pantalla, así que no hay dos sistemas de login que mantener — solo una pantalla, un tema, dos opciones.

| Pieza | Elección | Por qué |
|---|---|---|
| Gestor de pantalla | **LightDM** | Maduro, probado durante años, no se cuelga en silencio como puede hacerlo un greeter TUI más joven. Es además lo que trae por defecto el perfil XFCE de CachyOS — cero fricción |
| Tema del greeter | **`lightdm-webkit2-greeter`** | HTML/CSS/JS real, con `backdrop-filter` funcional (confirmado: la versión *webkit1*, deprecada, no lo soporta; *webkit2* sí). El cristal, el campo de colisión y la paleta se portan del mockup casi sin reescribir — a diferencia de `tuigreet`, que solo aceptaba 16 colores ANSI |
| Sesión a diario | **Hyprland Limitless** | El sistema completo que describe este documento |
| Sesión de emergencia | **XFCE** | X11, no Wayland — por diseño no puede competir ni chocar con el stack de Hyprland. Es un "romper cristal en caso de emergencia", no un segundo hogar |
| Splash de arranque | **Ninguno — Plymouth se desinstala** (`00-preflight.sh`, ya construido) | Causa documentada y recurrente de cuelgues de arranque en CachyOS, con o sin greeter TUI de por medio. Puramente cosmético; se pierde solo la animación |

No hace falta decidir entre cifrado sí/no para esta arquitectura: LightDM siempre pide credenciales, así que no hay una puerta "más débil" que proteger con autologin.

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
| Fondo | `awww` (era `swww`, renombrado upstream) | Solo respaldo: el campo de colisión ya vive en QuickShell (`modules/Wallpaper.qml`) |
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

herdr detecta estados por agente, y tu paleta tiene un registro para cada uno:

| Estado herdr | Color Limitless | Lectura |
|---|---|---|
| `blocked` — te necesita | `#ff4a2e` 赫 | Reversión: algo te espera |
| `working` | `#ffd25e` ámbar | En curso |
| `done` | `#3b9eff` 蒼 | Atracción: listo para revisar |
| `idle` | `#6b7f9e` atenuado | Ruido de fondo |
| `unknown` | `#6b7f9e` atenuado | Ver nota |

> **Corrección sobre esta misma tabla.** Esta sección decía "cuatro estados" y los daba por buenos sin haberlos verificado. Al construir el puente (`bin/cmd/herdr-bridge`) se comprobó la API real (`herdr.dev/docs/socket-api/`): los estados son **cinco**, no cuatro — el quinto es `unknown`, para paneles que el detector no supo clasificar. Se colapsa sobre `idle` (mismo color) porque un estado que herdr no reconoce no merece reclamar tu atención; pero existe, y quien lea esta tabla debe saberlo en vez de encontrárselo.

**Cómo está construido:** `bin/cmd/herdr-bridge` sondea el socket UNIX de herdr (`agent.list`, JSON delimitado por saltos de línea) cada 2 s y publica el conteo por IPC a QuickShell; `modules/Bar.qml` pinta un punto por agente con el color de su estado. Lo lanza `lua/exec.lua` al arrancar la sesión. Si herdr no está instalado, el puente publica ceros y la barra simplemente no dibuja el grupo de puntos.

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
| `00-preflight` | Verifica arquitectura, red, espacio y que no seas root. **Instala y activa `snapper`+`snap-pac`+`grub-btrfs` si la raíz es Btrfs**, crea la primera instantánea, y **desinstala Plymouth** (ya construido — causa documentada de cuelgues) |
| `10-core` | Paquetes oficiales desde `packages/pacman.txt`, sobre pacman puro — funciona igual en CachyOS que en cualquier Arch |
| `20-aur` | Instala `paru` si falta, luego `packages/aur.txt`. Fallos individuales no frenan la etapa |
| `30-services` | Habilita pipewire, wireplumber, NetworkManager, bluetooth, seatd |
| `40-stow` | Enlaza las configuraciones |
| `50-theme` | matugen genera los temas de las ~14 aplicaciones |
| `60-session` | **LightDM + `lightdm-webkit2-greeter`** (tema propio) + sesiones Hyprland/XFCE + hyprlock/hypridle (§2) — sustituye a la etapa anterior de `greetd`/autologin |
| `70-shell` | zsh por defecto, plugins, starship, zoxide, fzf-tab |
| `80-tui` | Entradas `.desktop` de las TUI (§4.2) |
| `90-verify` | `dotctl doctor` y resumen |

Reglas para todas: **idempotentes** (ejecutar dos veces no rompe nada), **marcadas** en `~/.local/state/limitless/stages/`, y **reanudables** con `./install.sh --from=50`. Si la etapa 20 falla compilando un paquete AUR a las dos horas, no repites desde cero. **Ninguna etapa se ejecuta durante la construcción** — el instalador entero corre una sola vez, en la Fase de Despliegue (§6).

### 5.3 Orden que importa

`00-preflight` (sudo, red de seguridad) va antes que todo. `10-core` (paquetes oficiales) va antes que `20-aur`, porque `paru` necesita `base-devel`/`git` ya instalados para poder compilar. `30-services` va **antes** que `60-session`: si LightDM arranca una sesión sin pipewire ni polkit habilitados, entras a una sesión rota. Y `90-verify` termina diciéndote explícitamente si es seguro reiniciar.

---

## 6. Fases de construcción

> **Cambio de arquitectura, decidido en esta revisión.** Las fases anteriores mezclaban "escribir código" con "ejecutarlo sobre una máquina real" — Fase 0 literalmente pedía correr `install.sh` antes de que el sistema estuviera terminado. Eso ya no es así.
>
> **Todas las fases de construcción son trabajo en el repositorio: código, configuración, documentación — nunca instalación sobre una máquina real.** `install.sh` no se ejecuta en ninguna fase de construcción. Se ejecuta **una sola vez**, al final de todo, en la **Fase de Despliegue**, y solo cuando tú lo pidas explícitamente sobre un sistema operativo ya instalado. Ningún agente —yo, u otro trabajando en paralelo— debe ejecutarlo antes de eso. Está escrito así, en mayúsculas de intención, en `CLAUDE.md`.
>
> El "terminas cuando" de cada fase ya no es "arranca en mi hardware": es que el código exista, esté verificado por los medios que sí están disponibles sin una máquina real —sintaxis validada, mockup consultado y consistente, `bash -n`/`qmllint` en verde, revisión cruzada— y quede documentado.

**Arquitectura de sesión, ya decidida** (sustituye a `greetd`+`tuigreet` de revisiones anteriores): **GRUB → Plymouth desactivado (causa conocida de cuelgues en CachyOS, `install/stages/00-preflight.sh`) → LightDM → elección de sesión: Hyprland Limitless (a diario) o XFCE (emergencia) → CachyOS/Arch base.** El tema de LightDM se construye sobre `lightdm-webkit2-greeter` (HTML/CSS/JS real, con `backdrop-filter` funcional — a diferencia de `tuigreet`, aquí sí se porta el cristal de verdad desde el mockup).

| Fase | Contenido | Terminas cuando |
|---|---|---|
| **1 · Núcleo** | `hyprland.lua` modular (sintaxis Lua de 0.55+/0.56 verificada línea a línea contra el wiki en vivo — nunca de memoria), cristal, workspaces semánticos, scratchpads, `theme.toml` + plantillas de matugen | El archivo existe, sintaxis Lua verificada, y `theme.toml` gobierna al menos Neovim + Starship + GRUB sin un solo hex fuera de `themes/` |
| **2 · Ecosistema de terminal** | zsh + 3 plugins, Ghostty, Neovim, Starship — ya escritos — más yazi, btop, lazygit, lazydocker, herdr, impala, bluetui, portapapeles, capturas, **12 plantillas de tema restantes** | Cada pieza tiene su plantilla de tema y su entrada en `packages/`; `dotctl doctor` los reconoce todos |
| **3 · Sesión** | LightDM + tema `lightdm-webkit2-greeter` (adaptado del mockup), XFCE como sesión de emergencia, hyprlock, hypridle, notificaciones, OSD, Plymouth fuera (`00-preflight.sh`, ya construido) | El tema del greeter existe como HTML/CSS/JS real, verificado en navegador igual que el mockup del shell |
| **4 · Shell** | QuickShell en el orden de `plan.md` §7: cromo → campo → barra → dock → launcher → notificaciones → OSD | Cada componente QML existe, pasa `qmllint`, y coincide con el mockup |
| **5 · Ecosistema propio** | Puente herdr→HUD, sesiones de proyecto, paneles de control y paquetes, `dotctl` completo, migraciones, **atajos de teclado completos** (`spec-keybinds.md`, incluidas teclas multimedia/función de portátil), **OBS Studio + captura de pantalla** (portal PipeWire, Discord en Wayland nativo) | Todo escrito y verificable: `hl.bind()` para cada atajo, `obs-studio` en `packages/`, la configuración del portal documentada y lista para aplicarse |
| **6 · Pulido** | Gestos, degradación por batería, spike del shader, CI de lint, README con capturas | Repo publicable |
| **Despliegue** *(única fase que toca una máquina real)* | Instalar CachyOS/Arch limpio → `./install.sh` una vez, completo → verificar contra `docs/runbook-despliegue.md` | El sistema arranca, se ve como el mockup, y `dotctl doctor` no reporta fallos |

**Portabilidad, como requisito explícito de ahora en adelante:** el instalador debe funcionar sobre **CachyOS o cualquier distribución basada en Arch**, no solo CachyOS. La mayoría del repo ya lo cumple por construcción — Btrfs/snapper/grub-btrfs es tooling genérico de Arch, no exclusivo de CachyOS, y la única pieza específica de CachyOS (`cachyos-plymouth-bootanimation`, `cachyos-plymouth-theme` en `00-preflight.sh`) ya está protegida con `pacman -Qq` — se salta sola si esos paquetes no existen, sin fallar. Cualquier pieza nueva que se añada de aquí en adelante debe seguir ese mismo patrón: verificar existencia antes de asumir.

---

## 7. Lo que hay que crear

Me preguntaste explícitamente. Esto es lo que **no existe** y hay que escribir:

### Imprescindible

| Pieza | Esfuerzo | Nota |
|---|---|---|
| **Instalador por etapas** | 2–3 días | §5. El más crítico: sin GUI, un instalador a medias te deja sin sistema |
| **`hyprland.lua` modular** | 2 días | En Lua desde el commit 1 |
| **`dotctl` + cabeceras** | 1 tarde | El router (`plan-automation.md` §3) |
| **`dev/minimal.conf`** | 1 hora | Config de rescate. La hora mejor invertida del proyecto |
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
3. Desde TTY: git, clonar, y **verificar que `dev/minimal.conf` arranca**.
4. Solo entonces, la Fase 1.

El paso 2 va antes que todo lo demás a propósito: es la única parte del plan que te protege **mientras construyes el resto**. Y el paso 3 parece trivial pero decide si el proyecto es cómodo o doloroso — un compositor que arranca desde 30 líneas es la diferencia entre depurar y adivinar.
