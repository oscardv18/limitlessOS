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
| `G` | Vista previa del greeter | `greetd` lo muestra antes de iniciar sesión — nunca se invoca a mano |
| `S` | Disparo inmediato del salvapantallas | `hypridle`, tras 25 s de inactividad |
| `N` | Notificación de prueba | El propio sistema, cuando pasa algo real |
| `+` / `-` | Añadir/quitar ventanas falsas del layout | No existe equivalente: las ventanas aparecen al abrir apps, no con un atajo |

---

## 5. Pendiente

Esta tabla se escribe en `hyprland.lua` durante la Fase 1. Dos cosas a verificar en ese momento, no antes (ver la nota de honestidad de `spec-layouts.md` §0 sobre la sintaxis Lua de Hyprland 0.55+/0.56):

- La sintaxis exacta de `hl.bind()` para modificadores combinados (`SUPER+SHIFT+letra`) y para teclas `XF86*`.
- Si el layout `scroll` expone su propio dispatcher de paneo (`SUPER+LEFT/RIGHT` solo cuando ese layout está activo) o si hay que condicionarlo a mano comprobando el layout del workspace enfocado.
