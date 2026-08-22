# Spec: layouts, terminal y cristal en las aplicaciones

> Complemento de `plan.md`. Responde a tres preguntas: qué layouts tendrán los dotfiles, qué terminal usar, y hasta dónde llega de verdad el liquid glass fuera del shell.

---

## 0. Antes de nada: Hyprland cambió de lenguaje de configuración

**Hyprland 0.55 mueve la configuración de hyprlang (`.conf`) a Lua (`hyprland.lua`).** hyprlang sigue funcionando "1 o 2 releases" más y **ya no recibe funciones nuevas**; después se retira.

Esto invalida una suposición de todo el plan anterior, que asumía `.conf` en todas partes. La corrección es simple y hay que aplicarla desde el primer commit: **escribir la configuración en Lua directamente.** Migrar 2.000 líneas de `.conf` dentro de seis meses es trabajo tirado que puedes no hacer nunca si empiezas bien.

Lo que gana el proyecto con el cambio, y no es poco:

- **Layouts definidos por el usuario.** Existe una API de layouts en Lua: `hl.layout.register(nombre, { recalculate, layout_msg })`, y se invoca como `lua:nombre`. Un layout propio deja de necesitar un plugin compilado.
- **Timers, eventos y callbacks** nativos en la config — cosas que antes exigían plugin o script externo.
- Adiós a líneas como `windowrule = immediate yes, border_size 4, class:^(x)$, title:^(y)$`, que es literalmente el ejemplo que los desarrolladores dan de por qué el formato viejo no daba más de sí.

**Consecuencia buena para el riesgo #1 del plan:** yo había marcado "los plugins rompen en cada actualización de Hyprland" como el riesgo más probable. Con layouts en Lua, **hyprscrolling deja de ser obligatorio**: el layout scroll se puede escribir en la propia config. Menos plugins compilados = menos rupturas.

> **Aviso honesto sobre la sintaxis.** Confirmé las *formas* de la API (`hl.bind(teclas, dispatcher)`, `hl.workspace_rule({...})`, `hl.layout.register(...)`, referencia `lua:nombre`), pero los bloques de código del wiki no se dejaron extraer limpiamente. **No voy a inventarme los nombres exactos de campos.** Al escribir la Fase 1 los contrastamos línea a línea contra el wiki; el diseño de abajo es independiente de esos detalles.

---

### 0.1 Actualización: 0.56 (335 commits, **cero cambios rompientes**)

Cuatro cosas de esta versión afectan al proyecto, y tres son regalos:

| Novedad | Qué significa aquí |
|---|---|
| **REPL de Lua en `hyprctl`** | Sustituye a mi consejo de iterar con `hyprctl keyword`. Ahora pruebas fragmentos de Lua en vivo, sin reiniciar el compositor. El bucle de iteración de la Fase 1 se acorta otra vez |
| **`glow` y `shadow` con gradientes y ángulo animado** | **Es el aro refractivo del liquid glass, nativo en el compositor.** Lo que en el mockup hago con un borde enmascarado, Hyprland puede pintarlo él con dispersión cian→violeta y ángulo animado. Ver `plan.md` §3.6 escalón 2 |
| **Gestos personalizados + registro/despacho de eventos en Lua** | La degradación por batería y los *focus modes* pueden vivir **en la config**, no en scripts externos que escuchan a UPower |
| **Scroll: `fit_into_view`, `inhibit_scroll`; master: `focus_master_on_close`** | Afinan directamente los layouts de §2. `focus_master_on_close` arregla el salto de foco al cerrar una ventana en `code` |

Y lo importante para la decisión anterior: **cero cambios rompientes**, y la superficie de la API de Lua casi se dobla. La recomendación de escribir en Lua desde el primer commit sale reforzada.

### 0.2 Zona exclusiva: la barra reserva, el dock flota

Regla que parece un detalle y define cuánta pantalla tienes:

- **Barra superior → zona exclusiva.** Reserva su alto (28 px). Las ventanas nunca la pisan. En Quickshell: `exclusionMode: Auto`.
- **Dock → sin exclusión.** Flota por encima y **se repliega solo** cuando una ventana lo pisa; vuelve al acercar el puntero al borde inferior. En Quickshell: `exclusionMode: Ignore`.

Reservarle alto fijo al dock es regalar una franja de pantalla a cambio de nada: la mayor parte del tiempo lo que hay debajo del dock es escritorio vacío. Con auto-repliegue tienes **el alto completo menos la barra** y el dock sigue a un gesto de distancia.

En el mockup: `D` alterna entre fijado y automático, y una línea fina en el borde inferior indica que sigue ahí cuando está replegado.

---

## 1. La decisión de fondo: no elegir *un* layout

El error típico es preguntarse "¿dwindle o master?" y casarse con uno. Un layout es una herramienta, y tú haces cosas distintas: escribir código no se parece a leer documentación, ni a tener seis terminales mirando logs.

**Hyprland soporta layout por workspace de forma nativa desde 0.54.** Así que la respuesta es: **cada workspace tiene el layout que corresponde a su propósito, y tú cambias de propósito, no de layout.**

Eso es lo que lo hace intuitivo: no memorizas atajos de layout, memorizas *dónde vive cada tipo de trabajo*. `SUPER+2` siempre es terminales, y las terminales siempre se colocan como deben.

### Los workspaces semánticos

| WS | Nombre | Layout | Para qué | Por qué ese layout |
|---|---|---|---|---|
| 1 | `code` | **master** | Editor + terminal + logs | El editor es el master (≈62%); todo lo demás se apila a la derecha sin robarle sitio. Es *el* layout de programar |
| 2 | `term` | **scroll** | Muchas terminales | Cinta horizontal infinita: abres la séptima terminal y las demás no encogen. Te desplazas, no rediminesionas |
| 3 | `web` | **dwindle** | Navegador + docs | Partición binaria: cómodo para 1–3 ventanas y para comparar dos cosas lado a lado |
| 4 | `comms` | **master** (vertical) | Chat, correo | Master arriba, resto abajo. Ventanas altas y estrechas se leen mal |
| 5 | `media` | **dwindle** + flotante | Vídeo, música, diseño | Estas apps quieren su propio tamaño; no pelees con ellas |

Y una regla que ahorra más tiempo que cualquier atajo: **las aplicaciones se abren solas donde les toca.** El navegador siempre aparece en `web`, el chat siempre en `comms`, aunque los lances desde el launcher en el workspace 1. Eso son reglas de ventana, y es la mitad de la "automatización" que buscas — dejas de mover ventanas a mano.

---

## 2. Los cinco layouts

Además del layout por workspace, un modo puntual que puedes invocar sobre cualquier workspace.

**1. `master` — programar.** Un master grande a la izquierda, pila a la derecha. Es el layout por defecto de `code`. Atajos que importan: intercambiar con el master (la ventana en la que estás pasa a ser la principal), y ajustar el ancho del master. Con eso cubres el 90% de una sesión de código.

**2. `dwindle` — comparar.** Cada ventana nueva parte la actual. Con `preserve_split` recuerda la orientación, así que deja de "saltar" impredeciblemente, que es la queja habitual contra BSP.

**3. `scroll` — muchas terminales.** Cinta horizontal de columnas: abrir una columna nueva no encoge las demás, te mueves por la cinta. Es el layout que hace que trabajar con 8 terminales sea llevadero. Ahora **escribible en Lua** en vez de depender del plugin.

**4. `focus` — pensar.** Una ventana, centrada, con gaps grandes y el resto oculto. No es fullscreen: es margen deliberado. Se combina con `dotctl focus deep` (silencio, dock oculto, fondo atenuado).

**5. `grid` — vigilar.** Rejilla uniforme n×n. Para cuando quieres ver cuatro logs a la vez y todos importan igual. Es un layout de vigilancia, no de edición.

---

## 3. Terminales: dónde está la productividad de verdad

### 3.1 Scratchpads — lo que más vas a usar

Los *special workspaces* de Hyprland son terminales (o cualquier ventana) que aparecen y desaparecen encima de lo que estés haciendo, sin cambiar de workspace ni perder el contexto. Para alguien que vive en la terminal, esto rinde más que cualquier layout:

> **Actualizado en `spec-keybinds.md`.** La tabla de ahí abajo tenía `SUPER+M` para música, pero esa combinación pasó a ser el menú de comandos del shell (más usado, se queda con la tecla sin fricción). Música se mueve a `SUPER+SHIFT+M`, y btop —que ocupaba esa combinación— pasa a `SUPER+SHIFT+B`. Ver `spec-keybinds.md` §1.1 para el porqué completo; esta tabla queda corregida abajo.

| Atajo | Scratchpad | Uso |
|---|---|---|
| `SUPER+`` ` `` (o `SUPER+ñ` en teclado ES) | `term` | Terminal desplegable estilo Quake. Una consulta rápida, un `git status`, y fuera |
| `SUPER+SHIFT+M` | `music` | Reproductor TUI |
| `SUPER+N` | `notes` | Notas |
| `SUPER+SHIFT+B` | `sys` | `btop` — monitor siempre a un toque |

La clave: **conservan el estado**. Tu terminal desplegable mantiene el directorio y el historial entre invocaciones. Es un contexto persistente, no una ventana nueva.

### 3.2 Grupos (pestañas)

Hyprland agrupa ventanas en un contenedor con pestañas. Para terminales es ideal: cuatro terminales de un mismo proyecto ocupan **un solo tile** y te mueves entre ellas con una tecla. Es multiplexor sin multiplexor, gestionado por el WM.

### 3.3 Sesiones automatizadas — el enlace con `dotctl`

Aquí se cierra el círculo con el panel de proyectos del mockup. `dotctl dev open <proyecto>`:

1. Cambia al workspace `code`.
2. Lanza el editor en el master, en el directorio del proyecto.
3. Abre la terminal del stack con el `cwd` correcto.
4. Si el proyecto declara un servidor de desarrollo, lo lanza en un tercer tile.
5. Fija la rama y el estado de git en la barra.

Esto es un script que encadena `hyprctl dispatch`, no magia. Y con los eventos/timers de Lua ahora disponibles en la config, parte de esa lógica puede vivir directamente ahí.

**Sobre multiplexores (tmux / zellij):** si Hyprland ya te tilea, el multiplexor local es redundante y añade una capa de atajos que pelea con los del WM. Úsalo sólo para lo que el WM no puede darte: **sesiones persistentes en máquinas remotas**. Localmente, deja que el compositor haga su trabajo.

---

## 4. Qué terminal

| | Punto fuerte | Punto débil |
|---|---|---|
| **Ghostty** ✅ | Wayland nativo, GPU, muy rápido, valores por defecto excelentes, config simple `clave = valor` que matugen tematiza sin esfuerzo, `background-opacity` real | Proyecto más joven; sin control remoto por script |
| **kitty** | `kitty @ launch …` permite guionizar ventanas y splits **desde fuera** — potente para automatizar | Duplica el trabajo del WM; config más recargada |
| **foot** | El más ligero y el de arranque más rápido. Wayland puro | Menos funciones (sin pestañas ni splits propios) |
| **Alacritty** | Rapidísimo, minimalista, TOML | Sin pestañas ni splits: exige multiplexor |
| **WezTerm** | Config en **Lua** — simetría con la nueva config de Hyprland | El más pesado de los cinco |

**Recomendación: Ghostty.** El argumento decisivo no es la velocidad, es este: **en Hyprland no quieres que el terminal tilee**, quieres que tilee el compositor. Un terminal con splits propios te da dos sistemas de ventanas compitiendo, con dos juegos de atajos. Ghostty se aparta y hace bien lo único que le pides: pintar texto rápido, con fondo translúcido de verdad.

Dos matices honestos:

- Si **guionizar la terminal** pesa más que la coherencia, **kitty** es la elección correcta. `kitty @ launch --location=vsplit --cwd=current` es una herramienta real que Ghostty no iguala.
- Para el **scratchpad** el arranque instantáneo se nota mucho, y ahí **foot** gana. Pero mantener dos terminales significa dos temas que sincronizar; sólo merece la pena si el desplegable se te hace lento.

---

## 5. Cristal en las aplicaciones: hasta dónde llega de verdad

Aquí hay que ser preciso, porque es donde casi todos los rices se estrellan.

**El error que hay que evitar:** la regla `opacity` de Hyprland multiplica el alfa de **toda la superficie de la ventana, texto incluido**. No es el material de macOS. Si le pones `opacity 0.85` a un editor, el código se vuelve semitransparente y se lee peor. macOS no hace eso: la app dibuja un fondo translúcido con el **texto opaco encima**.

Por eso el cristal real depende de que **la aplicación lo soporte**, no de la regla del compositor:

| Nivel | Aplicaciones | Cómo se consigue | Resultado |
|---|---|---|---|
| **Cristal real** | Terminal (Ghostty/kitty/foot), Quickshell | La app dibuja fondo translúcido; el texto sigue opaco. Hyprland difumina lo de detrás | Idéntico al mockup |
| **Cristal parcial** | GTK (nautilus, gnome-text-editor…), Qt (Kvantum) | Translucidez a nivel de **tema**, no de ventana | Bueno en apps con poco texto |
| **Falso** | Cualquier otra vía `opacity` | El alfa afecta también al texto | Evitar en todo lo que se lea |
| **Ninguno, a propósito** | Navegador, editores, Electron | `opaque` + `noblur` explícitos | Es lo que pediste, y además es lo correcto |

Que quieras el navegador y los editores opacos no es una renuncia: **son exactamente las aplicaciones donde el cristal molesta**. Texto denso, muchas horas, contraste que importa. La regla que sale de esto es sana:

> **Cristal donde adorna, opacidad donde se lee.**

Ajustes que hay que acompañar para que el nivel 1 se vea como el mockup: opacidad de fondo del terminal alta (0.85–0.92, no menos — por debajo el código pierde legibilidad), `blur:vibrancy` alto para la saturación, y `blur:xray` decidido a conciencia: con `xray` el difuminado toma el **fondo de pantalla** en vez de las ventanas de detrás. Con el campo de colisión como fondo (`plan.md` §3.5b), `xray` activo hace que todas las superficies de cristal respiren el mismo campo — mucho más coherente que difuminar ventanas ajenas.

---

## 6. Lo que cambia en el plan

1. **La configuración se escribe en Lua desde el primer commit.** No en `.conf`.
2. **hyprscrolling deja de ser obligatorio** — el layout scroll se escribe en Lua. Menos plugins, menos rupturas.
3. **La Fase 1 incorpora los workspaces semánticos y los scratchpads.** No son pulido: son la mitad de la productividad y cuestan poco.
4. **Terminal: Ghostty**, y el tema del terminal entra en las plantillas de matugen desde la Fase 1.
5. **Las reglas de cristal se dividen en dos listas explícitas** (`opaque` + `noblur` para navegador y editores) y viven en `conf/windowrules`, generadas desde `theme.toml`.

---

## Fuentes

- [Hyprland 0.55 — anuncio oficial](https://hypr.land/news/update55/) · [Lua-ification de las configs](https://hypr.land/news/26_lua/)
- [Workspace Rules — Wiki](https://wiki.hypr.land/Configuring/Basics/Workspace-Rules/) · [Custom Layouts — Wiki](https://wiki.hypr.land/Configuring/Layouts/Custom-Layouts/) · [Master Layout — Wiki](https://wiki.hypr.land/Configuring/Layouts/Master-Layout/)
- [Hyprland 0.55 trae configs Lua y layouts definidos por el usuario — Linuxiac](https://linuxiac.com/hyprland-0-55-brings-lua-configs-and-user-defined-layouts/)
- [Hyprland 0.53 rehace la sintaxis de window rules](https://alternativeto.net/news/2025/12/hyprland-0-53-overhauls-window-rule-syntax-adds-new-launch-command-and-onboarding-app)
