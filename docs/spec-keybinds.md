# Spec: atajos de teclado — la tecla líder es SUPER

> Tabla definitiva. Hasta este documento, los atajos vivían dispersos en `plan.md`, `plan-v2.md`, `plan-automation.md`, `spec-layouts.md` y `spec-package-panel.md`, escritos en momentos distintos de la conversación. Al juntarlos aparecieron **dos colisiones reales** y **tres atajos del mockup que serían errores graves** si se copiaran tal cual a un sistema de verdad. Este documento es la única fuente de verdad a partir de ahora; cuando la Fase 1 escriba los binds reales en `hyprland.lua`, salen de aquí.

---

## 0. Por qué el mockup usa una sola tecla

Un navegador **no puede interceptar la tecla Super/Meta del sistema operativo** — el propio mockup v12 original ya lo advertía en su pie de página. Por eso todo el mockup interactivo (`limitless-shell.html`) usa letras sueltas: es la única forma de que las pruebas funcionen dentro de un `<iframe>`. Ningún atajo del mockup es el atajo real; cada uno de abajo dice a qué combinación con `SUPER` corresponde.

---

## 1. Las dos colisiones que aparecieron al consolidar

### 1.1 `SUPER+M` — menú de comandos vs. reproductor de música

- `spec-layouts.md` (scratchpads, §3.1) asignaba `SUPER+M` al reproductor de música TUI.
- El mockup usa `M` para el **menú de comandos** (el panel generado desde las cabeceras de `bin/cmd/*`, `plan-automation.md` §4).

**Resolución:** el menú de comandos es la superficie que más se usa —es el equivalente al Spotlight de macOS o al `Ctrl+Shift+P` de VS Code— y se queda con la tecla sin modificador extra. El reproductor de música se mueve a `SUPER+SHIFT+M`.

### 1.2 `SUPER+V` — portapapeles vs. `togglefloating`

- `plan-v2.md` §2.2 y el mockup coinciden: `SUPER+V` abre el **portapapeles**.
- `dev/minimal.conf` usa `SUPER+V` para `togglefloating` (flotar/anclar la ventana activa).

**Resolución:** no es una colisión en tiempo de ejecución de verdad —`dev/minimal.conf` es un entorno de rescate aislado que nunca corre a la vez que el shell real (`LIMITLESS-OS.md` §1, Capa 3)— pero sí lo sería si se copiara sin pensar al `hyprland.lua` de la Fase 1. Ahí, `togglefloating` se mueve a `SUPER+ALT+V`. `dev/minimal.conf` se queda como está: es un archivo de rescate de 30 líneas, no vale la pena tocarlo por una colisión que no ocurre nunca en la práctica.

---

## 2. Los tres atajos del mockup que serían errores reales

El mockup, por necesidad de probarse en un navegador sin `SUPER`, usa teclas sueltas para algunas cosas que en un sistema real **rompen la escritura normal si se dejan sin modificador**. Ninguno de los tres es un bug del mockup — son sustituciones necesarias para la demo — pero hay que dejar constancia de cuál es el atajo real para que nadie los copie literalmente al escribir `hyprland.lua`.

| En el mockup (sin modificador) | Por qué ahí está bien | Atajo real |
|---|---|---|
| `1`–`5` cambia de workspace | Es una demo aislada; nadie escribe texto en ella | **`SUPER+1..9`** — con números sueltos, cualquier campo de texto de cualquier app dejaría de poder escribir dígitos |
| `↑` / `↓` cambia el volumen | Ídem | **Teclas multimedia** (`XF86AudioRaiseVolume` / `XF86AudioLowerVolume` / `XF86AudioMute`) — las flechas sueltas son navegación básica en cualquier programa |
| `Tab` cicla el foco entre ventanas | Ídem | **`SUPER+TAB`** — `Tab` sin modificador es fundamental para moverse entre campos de formulario en cualquier app |

---

## 3. La tabla definitiva

### 3.1 Shell — superficies invocadas globalmente

| Real (`SUPER+…`) | Acción | Tecla en el mockup |
|---|---|---|
| `SPACE` | Launcher (rueda orbital) | `L` |
| `M` | Menú de comandos | `M` |
| `I` | Paquetes | `I` |
| `P` | Proyectos / sesiones de desarrollo | `P` |
| `V` | Portapapeles | `V` |
| `W` | Widgets | `W` |
| `C` | Centro de control (red / audio / pantallas / captura) | `C` |
| `K` | Bloquear sesión | `K` |
| `T` | Ciclar técnica (蒼 → 赫 → 茈) | `T` |
| `D` | Fijar / soltar el dock | `D` |
| `SHIFT+D` | Ocultar el dock del todo | `H` |
| `SHIFT+S` | Captura de región | `X` — la `X` del mockup era solo un hueco libre, porque `S` ya estaba tomada por la prueba del salvapantallas |
| `[` / `]` | Ciclar layout del workspace activo | `[` / `]` |
| `TAB` | Ciclar foco entre ventanas | `Tab` — ver §2, aquí SÍ hace falta el modificador |
| `1`–`9` | Cambiar de workspace | `1`–`5` — ver §2 |
| `LEFT` / `RIGHT` | Paneo de la cinta, solo cuando el layout activo es `scroll` | `←` / `→` |
| `E` | Mission Control (`hyprexpo`) — rejilla de todos los workspaces | *nuevo, sin equivalente en el mockup* |

### 3.2 Gestión de ventanas (heredado de `dev/minimal.conf`, con un cambio)

| Real (`SUPER+…`) | Acción | Nota |
|---|---|---|
| `RETURN` | Abrir terminal | igual que en `dev/minimal.conf` |
| `Q` | Cerrar ventana activa | igual |
| `SHIFT+E` | Salir de la sesión | igual |
| `F` | Pantalla completa | igual |
| `ALT+V` | Flotar / anclar ventana | **movido** desde `SUPER+V` — ver §1.2 |

### 3.3 Multimedia (sin `SUPER` — teclas dedicadas, cuando existen)

| Tecla | Acción |
|---|---|
| `XF86AudioRaiseVolume` / `XF86AudioLowerVolume` | Volumen ± |
| `XF86AudioMute` | Silenciar |
| `XF86MonBrightnessUp` / `Down` | Brillo (portátil) |
| `XF86AudioPlay` / `Next` / `Prev` | Control de reproducción — llega directo a herdr/MPRIS |

### 3.4 Scratchpads — terminales y TUI persistentes (`spec-layouts.md` §3.1, reconciliado)

| Real (`SUPER+…`) | Scratchpad | Cambio respecto a `spec-layouts.md` |
|---|---|---|
| `` ` `` (grave) — o `Ñ` en teclado ES | Terminal desplegable | `spec-layouts.md` proponía solo `Ñ`; se añade la grave como alternativa de layout US, porque un atajo que solo existe en un teclado no es un atajo fiable |
| `SHIFT+M` | Reproductor de música | **movido** desde `M` — ver §1.1 |
| `N` | Notas | sin cambio — el `N` del mockup era solo una notificación de prueba, no colisiona de verdad |
| `SHIFT+B` | Monitor de sistema (btop) | **movido** desde `SHIFT+M`, que ahora es música |
| `G` | lazygit sobre el proyecto actual | `LIMITLESS-OS.md` §4.2. El `G` del mockup era la vista previa del greeter — ver §4, no colisiona |

---

## 4. Lo que en el mockup no necesita atajo real

Cuatro teclas del mockup existen solo para poder demostrar un estado sin esperar al evento real que lo dispara — no son atajos que vayan a existir en el sistema terminado:

| Tecla del mockup | Qué demuestra | Cómo se dispara de verdad |
|---|---|---|
| `G` | Vista previa del greeter | LightDM lo muestra antes de iniciar sesión — nunca se invoca a mano |
| `S` | Disparo inmediato del salvapantallas | `hypridle`, tras 25 s de inactividad |
| `N` | Notificación de prueba | El propio sistema, cuando pasa algo real |
| `+` / `-` | Añadir/quitar ventanas falsas del layout | No existe equivalente: las ventanas aparecen al abrir apps, no con un atajo |

---

## 4b. Teclas de función del portátil

Sin `SUPER`: son teclas físicas dedicadas (brillo, volumen, avión…), no combinaciones que tú eliges — el estándar es enlazarlas directo, sin modificador, exactamente como llegan del hardware. Nombres verificados contra `XF86keysym.h` (el estándar de facto en X11/Wayland desde hace más de veinte años; Hyprland los reconoce igual que cualquier compositor) — nada de esta tabla es una suposición.

| Tecla física | Keysym | Acción | Nota |
|---|---|---|---|
| Brillo ↑ | `XF86MonBrightnessUp` | Subir brillo de pantalla | `brightnessctl set +5%` o equivalente |
| Brillo ↓ | `XF86MonBrightnessDown` | Bajar brillo de pantalla | |
| Silenciar | `XF86AudioMute` | Mute/unmute | `wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle` |
| Volumen ↓ | `XF86AudioLowerVolume` | Bajar volumen | Alimenta el OSD del mockup (§3.1 de `plan.md`) |
| Volumen ↑ | `XF86AudioRaiseVolume` | Subir volumen | |
| Pista anterior | `XF86AudioPrev` | Anterior | Vía MPRIS — el mismo bus que ya usa el reproductor del panel de widgets |
| Pista siguiente | `XF86AudioNext` | Siguiente | |
| Reproducir/pausa | `XF86AudioPlay` | Play/Pause | Toggle; algunos teclados envían `XF86AudioPause` por separado — enlazar ambos al mismo toggle no hace daño |
| Pantalla externa / proyector | `XF86Display` | Ciclar disposición de monitores | Confirmado: en ThinkPad es `Fn+F7`, en HP `Fn+F4` — la tecla física varía, el keysym no. Dispara un script propio (`dotctl display cycle`, pendiente de escribir) que rota interno-only → espejo → extender → externo-only |
| Modo avión | `XF86RFKill` | Alternar todo el radio (Wi-Fi + Bluetooth) | `rfkill toggle all`. En hardware ASUS el driver a veces mapea esta tecla como `XF86WLAN` en vez de `XF86RFKill` — si no responde, comprobar con `wev` cuál de las dos llega realmente |
| Captura de pantalla | `Print` | Región a portapapeles | No lleva prefijo `XF86` — es el `Print`/`Sys_Req` estándar de X11, no una tecla de función especial. Coincide con `SUPER+SHIFT+S` de la tabla §3.1: mismo comando, dos formas de llegar a él |

Verificación en la máquina real, antes de dar esto por bueno: `wev` (Wayland) muestra el keysym exacto que envía cada tecla física — hardware distinto puede mapear de forma distinta, sobre todo en el par avión/RFKill.

## 4c. OBS Studio y compartir pantalla (Discord y similares)

Verificado contra la documentación de `xdg-desktop-portal-hyprland` y reportes reales de la comunidad — el mecanismo es PipeWire + el portal `ScreenCast`, no una integración especial por aplicación:

- **Requisito de base, ya en `packages/pacman.txt`:** `pipewire`, `wireplumber`, `xdg-desktop-portal-hyprland`, `xdg-desktop-portal-gtk`, `obs-studio` (confirmado en el repo `extra` oficial de Arch, sin AUR).
- **Falta en `hyprland.lua` (Fase 1):** `exec-once = dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP` — sin esto el portal no ve las variables de entorno correctas y OBS/Discord no encuentran ninguna fuente que compartir.
- **OBS** funciona directo una vez el portal está sano: fuente "Captura de pantalla (PipeWire)", aparece un selector nativo preguntando qué compartir.
- **Discord y cualquier app basada en Electron** corren bajo XWayland por defecto, y XWayland **no puede** capturar ventanas ni pantallas Wayland — solo otras ventanas XWayland. Hace falta forzar Wayland nativo en el lanzador de la app:
  ```
  discord --enable-features=UseOzonePlatform,WebRTCPipeWireCapturer --ozone-platform=wayland
  ```
  Pendiente: envolver esto en el `.desktop` de Discord (`dotctl tui-install`-style, o una entrada manual en `stow/`) para que no haya que recordarlo cada vez.

---

## 5. Pendiente

Esta tabla se escribe en `hyprland.lua` durante la Fase 1. Dos cosas a verificar en ese momento, no antes (ver la nota de honestidad de `spec-layouts.md` §0 sobre la sintaxis Lua de Hyprland 0.55+/0.56):

- La sintaxis exacta de `hl.bind()` para modificadores combinados (`SUPER+SHIFT+letra`) y para teclas `XF86*`.
- Si el layout `scroll` expone su propio dispatcher de paneo (`SUPER+LEFT/RIGHT` solo cuando ese layout está activo) o si hay que condicionarlo a mano comprobando el layout del workspace enfocado.
