# Plan definitivo — Dotfiles Hyprland

> Sustituye a `plan-dotfiles-hyprland.md` (v1) y a `plan-v2.md` (auditoría de infraestructura, que sigue siendo válida en lo suyo).
> Esta versión está escrita **después** de leer el mockup real (`docs/mockups/hyprland-ui-mockup-v12-final.html`), y eso cambia la premisa del proyecto.

---

## 1. El hallazgo: el mockup no es macOS

El plan v1 define el objetivo como *"réplica de macOS Tahoe Liquid Glass"*: barra clara translúcida, dock con magnificación, semáforo de tres botones, wallpaper de gradiente azul/púrpura fluido, tarjetas de vidrio.

El mockup v12 que has construido es **otra cosa completamente distinta, y mucho más interesante**:

| | Plan v1 (macOS Tahoe) | Mockup v12 (lo que realmente diseñaste) |
|---|---|---|
| Fondo | Gradiente líquido claro | `#07070b` casi negro + campo de estrellas animado |
| Tipografía | SF Pro / Inter (humanista) | JetBrains Mono (monoespaciada) en **todo**, incluso el reloj |
| Paleta | Derivada del wallpaper | Identidad fija: cian `#0ea5e9`, violeta `#6d28d9`, carmesí `#b91c1c` |
| Iconos | Iconos de app reales (WhiteSur) | Glifos geométricos Unicode (`▣ ❯ ⊙ ♪ ⚙ ✉ ◈ ▤ ⌘ ⏻`) |
| Cromo | Semáforo de ventana, esquinas suaves | Corchetes de esquina HUD, telemetría (uptime, NET, GPU °C, layout) |
| Dock | Fila con magnificación al hover | Rueda orbital de radio 850px que gira con el scroll |
| Launcher | Spotlight: barra + lista | Disco inclinado en rotación con la búsqueda en el centro |
| Sensación | Producto de consumo, cálido, amable | **Cabina / HUD / Jarvis**, frío, técnico, denso en datos |

Esto no es "macOS con tema oscuro". Es un lenguaje de diseño distinto, coherente consigo mismo, y **el mockup es mucho más original que el plan**. El problema es que medio plan v1 sigue escrito para el otro objetivo.

**Decisión #1 — la más importante de todo el documento:**

| | Dirección | Consecuencia |
|---|---|---|
| A ✅ | **Comprometerse con el HUD del v12.** macOS pasa a ser inspiración de *ergonomía* (dock, spotlight, centro de notificaciones), no de *estética* | Caen del plan: hyprbars con semáforo, iconos WhiteSur, cursores Apple, Inter/SF Pro, wallpaper líquido claro, matugen derivando color del fondo. Ganas identidad propia |
| B | Rehacer los mockups en clave macOS | Tiras el trabajo de diseño ya hecho y acabas siendo un rice más de los cientos que replican macOS |
| C | Dos temas intercambiables (HUD + macOS) | Duplicas todo el trabajo visual. **No en la v1.0** — anótalo como idea futura, la arquitectura de theming (§5) lo deja abierto |

**Recomiendo A**, y todo lo que sigue lo asume. Si prefieres B, dímelo antes de escribir una línea de código, porque cambia las fases 3 a 5 enteras.

---

## 2. Sistema de diseño extraído del v12

Esto ya no hay que inventarlo: está en el CSS del mockup. Se convierte en `themes/hud-void/theme.toml`, la fuente de verdad única.

```toml
[color.surface]
void          = "#07070b"              # fondo absoluto
panel         = "rgba(18,20,28,0.55)"  # cristal normal
panel_strong  = "rgba(14,16,23,0.72)"  # cristal de iconos/dock
border        = "rgba(148,163,184,0.14)"

[color.accent]
blue    = "#0ea5e9"   # primario: enlaces, activo, match
violet  = "#6d28d9"   # secundario: layout, categorías
crimson = "#b91c1c"   # alerta / power / media

[color.text]
normal = "#e5e9f0"
dim    = "#64748b"

[font]
family = "JetBrains Mono"
bar    = 10.5   # px
micro  = 9      # telemetría y labels
label  = 7      # labels bajo los iconos del launcher

[geometry]
bar_height     = 26
radius_icon    = 12   # dock
radius_orbit   = 14   # launcher
tracking       = 0.04 # letter-spacing em
```

**Reglas de traducción CSS → Hyprland/QML** (esto es lo que hace que se vea igual en real, no sólo en el navegador):

| En el mockup | En el sistema real |
|---|---|
| `backdrop-filter: blur(18px)` | `layerrule = blur, quickshell:bar` + `decoration:blur:size/passes` |
| `saturate(140%)` | `decoration:blur:vibrancy` — es el parámetro equivalente, y el que separa "borroso" de "vidrio" |
| `background: rgba(...,0.55)` sobre blur | Además `layerrule = ignorealpha 0.3, quickshell:bar`, o las zonas transparentes se emborronan a sí mismas |
| `box-shadow: 0 0 8px var(--blue-dim)` | Glow en QML: capa duplicada con `layer.effect: MultiEffect` (glow), no `DropShadow` |
| `transition: all .18s ease` | `Behavior on <prop> { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }` |

Consistencias que el mockup ya respeta y hay que mantener: todas las transiciones entre 150 y 280 ms; todos los bordes al 14% de opacidad; el acento nunca se usa como fondo de superficie grande, sólo como línea, glifo o glow.

**Un problema de accesibilidad, medido:** `--text-dim` (`#64748b`) sobre `--void` (`#07070b`) da un contraste de **≈4.2:1**, por debajo del mínimo AA de 4.5:1 — y lo estás usando a 9px en la telemetría. En una captura se ve elegante; a las tres horas de uso cansa. Sugerencia: subir `text-dim` a ~`#7c8ba1` (≈5.6:1) y conservar el `#64748b` sólo para elementos decorativos que no hay que leer.

---

## 3. Auditoría del v12, componente por componente

### 3.1 Barra superior — lista para implementar, pero incompleta funcionalmente

Estructura: grid `1fr auto 1fr`, 26px de alto. Izquierda logo, centro cápsula de 5 workspaces (activo = gradiente cian→violeta + glow), derecha CPU / MEM / reloj.

Lo que está bien: el grid de tres columnas garantiza que el reloj y los workspaces queden **ópticamente centrados** aunque los lados tengan anchos distintos. Es el detalle correcto y mucha gente lo hace mal.

Lo que falta para uso diario: **bandeja del sistema, batería, red, Bluetooth y volumen**. Ninguno está en el mockup. En 26px de alto y con el centro ocupado, el único sitio es el grupo derecho. Opciones:

- **A ✅** Grupo derecho ampliado con glifos de una sola letra + colapso: `↓340K  ⏻87%  ⬡⬡⬡ 21:47`. Click en cualquiera abre un panel HUD desplegable con los controles reales. Mantiene la barra delgada, que es la mitad de su gracia.
- B Subir la barra a 32px y meterlo todo. Más fácil, menos elegante.
- C Bandeja fuera de la barra, en un panel invocado por teclado. Muy coherente con "teclado-first", pero rompe con apps que dependen del icono de bandeja.

Nota práctica: 26px con texto de 10.5px es cómodo en HiDPI; en un panel 1080p va a quedar muy justo. La altura debe salir de `theme.toml`, no estar clavada.

### 3.2 Launcher wheel — el concepto es fuerte, la mecánica necesita tres arreglos

Geometría: elipse de 500×210 (radio 250, `SQUISH 0.42`), 10 apps, `scale` y `opacity` en función de `sin(angle)` para simular profundidad. La ilusión de disco inclinado funciona y es genuinamente original.

**Problema 1 — la rueda no para de girar.** `ringRot += 0.0032` por frame: una vuelta completa cada ~33 s, siempre. Dos consecuencias: (a) hacer click en un icono es **apuntar a un blanco en movimiento**, que es de los peores patrones de interacción que existen; (b) es un `requestAnimationFrame` perpetuo que mantiene la GPU despierta — en un portátil eso se nota en la batería.

> **Arreglo:** la rueda gira sólo cuando hay razón. Reposo → quieta. Scroll o flechas → gira con inercia y frena. Al escribir → rota para llevar el mejor match a la posición frontal. El giro lento continuo se conserva únicamente como animación de bienvenida durante los primeros ~2 s tras abrir, y se detiene al primer input. Ganas usabilidad *y* batería sin perder nada del efecto.

**Problema 2 — sólo caben 10 apps.** El mockup filtra dentro de una lista fija de 10. Un sistema real tiene 100+ `.desktop`. Una rueda con 100 iconos es ilegible.

> **Arreglo:** la rueda muestra **favoritos** (8–12, fijados por ti). Al escribir, se repuebla con los **N mejores resultados** de la búsqueda difusa sobre todos los `.desktop` (nombre, `GenericName`, `Keywords`, `Exec`), reordenándose con animación. La rueda deja de ser un menú y pasa a ser un visor de resultados — que es lo que la hace escalar.

**Problema 3 — no hay navegación por teclado.** Hoy: escribir filtra, ratón lanza. Falta `←/→` o `Tab` para rotar entre matches, `Enter` para lanzar el frontal, `Esc` para cerrar (esto último sí está). En un proyecto que se define como teclado-first, es el hueco más grave.

Detalles menores: el matching es `startsWith`/`includes`, hay que pasarlo a difuso tipo fzf; y `best.el.style.transform += ' scale(1.9)'` se **compone** con el `scale` de profundidad, así que el tamaño real del match varía según dónde esté en la órbita (entre ~0.84× y ~1.9×). En QML conviene fijar la escala objetivo explícitamente en vez de multiplicarla.

### 3.3 Dock rueda — funciona mejor de lo que yo suponía, y hay que ajustar dos números

En `plan-v2.md` objeté que una rueda "esconde iconos tras el borde". Hice los números sobre el código real y **la objeción no se sostiene tal cual**:

- `arcSpread = 0.72` rad repartido entre 9 iconos → **0.09 rad de separación**, que a `R = 850` son 76 px de arco por icono. Con iconos de 44 px, quedan ~32 px de aire. Espaciado correcto.
- En reposo, `centerCloseness` va de 1.0 (centro) a 0.936 (extremos) → la escala varía sólo entre **1.26× y 1.22×**, y la opacidad no baja de 0.94.

Es decir: **en reposo no se esconde nada y la magnificación es casi imperceptible.** Para hundir un icono de los extremos hacen falta ~5,5 muescas de scroll. Así que el dock por defecto se comporta como un arco estático perfectamente legible, y la rueda sólo entra en juego cuando hay más iconos de los que caben. Es el comportamiento correcto — probablemente mejor de lo que pretendías.

Dos ajustes concretos:

1. **La magnificación de 1.22→1.26 es tan sutil que no comunica el foco.** Si quieres el feedback tipo macOS al pasar el ratón, hace falta un factor de hover *independiente* de `centerCloseness` (p. ej. 1.35× en el icono bajo el cursor, 1.15× en los vecinos), no derivado del ángulo.
2. **`layoutDock()` corre en `requestAnimationFrame` eterno** aunque `dockOffset === targetDockOffset`. En QML esto se resuelve con `Behavior`/`NumberAnimation` sobre el ángulo: cero frames cuando no pasa nada.

Lo que al dock le falta para ser un dock y no una fila de botones: **indicador de app abierta** (el punto de macOS — imprescindible), tooltip/label al hover, semántica de click (lanzar vs. enfocar vs. minimizar), reordenar arrastrando, y estado de "reclama atención". Nada de eso está diseñado todavía.

### 3.4 Cromo HUD (corchetes + telemetría) — barato y es el 40% del carácter

Cuatro corchetes SVG en las esquinas y dos bloques de lectura (UPTIME/NET a la izquierda, LAYOUT/GPU a la derecha). Técnicamente es lo más fácil de todo el proyecto: una superficie layer-shell en la capa **`bottom`** (sobre el wallpaper, bajo las ventanas), sin exclusión de espacio y sin zona de input, para que los clicks la atraviesen.

Advertencia honesta: sólo se ve con el escritorio despejado. Con una ventana maximizada desaparece. Es decoración ambiental, no información operativa — no pongas ahí nada que necesites de verdad.

### 3.5b Campo de colisión: un motor, tres intensidades

**Sustituye al campo de estrellas de §3.5.** Fondo de pantalla, bloqueo y salvapantallas no son tres piezas: son **el mismo renderizador con tres presets**. Prototipado en `limitless-shell.html`.

Qué dibuja: un cerebro de nodos (esfera de Fibonacci proyectada en 3D, rotando en dos ejes), dos grafos laterales que le disparan energía, y un núcleo donde esa energía colisiona. El color no se pinta: **cada arista se tiñe según su posición horizontal** — azul a la izquierda, rojo a la derecha, morado al cruzar el centro. Es 蒼 + 赫 → 茈 emergiendo de la geometría, no un degradado decorativo.

| Preset | Nodos | Uso | Notas |
|---|---|---|---|
| `wallpaper` | 52 | Siempre visible tras las ventanas | Rotación lenta, sin anillos de impacto, sin `lighter`. Es ambiente: no debe pedir atención |
| `lock` | 76 | Detrás del reloj de bloqueo | Intensidad media + halo radial bajo la cifra, para que el reloj se lea sin tapar el campo |
| `saver` | 120 | Inactividad (25 s) | Todo activo: anillos de impacto, composición `lighter`, núcleo blanco |

**Por qué importa para la implementación:** en QuickShell esto es **un `ShaderEffect`/`Canvas` parametrizado que se instancia tres veces**, no tres componentes. Un archivo, tres configuraciones, y el theming entra por las mismas variables que todo lo demás.

**Regla de rendimiento, ya implementada en el prototipo:** el fondo **se detiene** cuando el salvapantallas o el bloqueo están activos, y se reanuda al salir. Nunca hay dos campos pintando a la vez. Sin esto, un salvapantallas de pantalla completa estaría componiendo sobre un fondo que nadie ve — el error clásico de los rices con fondo animado.

### 3.5 Fondo: el campo de estrellas *(sustituido por §3.5b)*

El mockup lo dibuja en `<canvas>`: densidad `w*h/2600`, parpadeo por seno, 15% de estrellas teñidas de cian o violeta. Opciones para llevarlo a real:

| | Cómo | Coste | Notas |
|---|---|---|---|
| A ✅ | `ShaderEffect` GLSL en una capa `background` de QuickShell | Bajo si el shader está bien escrito | Se colorea desde `theme.toml`, resolución independiente, y puedes pausarlo al bloquear o con batería baja |
| B | Canvas QML replicando el JS tal cual | Muy bajo esfuerzo | Redibuja por CPU cada frame: es la peor opción para batería |
| C | Imagen estática generada una vez + `swww` | Cero coste continuo | Se pierde el parpadeo, que es justo lo que le da vida |
| D | `mpvpaper` con un vídeo en bucle | Alto (decodificación continua) | Descartar |

Con A, además, el fondo participa del theming: cambias el acento y las estrellas teñidas cambian con él.

### 3.6 Liquid glass: el material (decisión tomada)

El liquid glass vuelve al proyecto — no como estética macOS, que se descartó en §1, sino como **material de las superficies**. La identidad sigue siendo el HUD de Gojo; lo que cambia es de qué está hecho el cristal. Está prototipado y funcionando en `limitless-shell.html`.

Un panel de vidrio creíble no es "blur + borde". Son cuatro cosas simultáneas:

| Componente | Qué hace | Cómo se consigue |
|---|---|---|
| **Realce especular** | Luz que entra por arriba-izquierda; el canto superior brilla | `inset 0 1px 0 rgba(255,255,255,.30)` + caída interior. En QML: capa de gradiente sobre el fondo |
| **Grosor** | El vidrio tiene canto: sombra interior abajo | `inset 0 -1px 0 rgba(0,0,0,.45)` + difuminado interior inferior |
| **Dispersión cromática** | El canto tiñe la luz que lo atraviesa | Borde de 1,3px con gradiente cian→violeta. **Aquí física y paleta coinciden**: la dispersión real de un canto de vidrio produce exactamente el cian-violeta de Gojo |
| **Brillo móvil** | El realce se desplaza al mover el puntero | Dos variables CSS actualizadas en `pointermove`. En QML: `MouseArea.positionChanged` → posición del gradiente |

Ese cuarto punto es el que separa "vidrio" de "fondo borroso". Sin él la superficie está muerta; con él la luz recorre el panel cuando te mueves. Y cuesta muy poco: dos variables, sin `requestAnimationFrame`, sin recalcular layout.

**Ruta de implementación, en tres escalones** (haz el 1 completo antes de mirar el 3):

1. **Material CSS/QML sin refracción** — los cuatro componentes de arriba. Barato, funciona en cualquier GPU, y es el 80% del efecto. **Esto es lo que va en la Fase 4.**
2. **Refracción falsa en el canto** — un aro fino con `backdrop-filter` propio a distinta intensidad que el centro. Da la ilusión de que la luz se dobla en el borde. Coste bajo.
3. **Refracción real por shader** — `ShaderEffect` de QML alimentado con `ScreencopyView`, con desplazamiento en los bordes. Es el techo, es caro (captura continua + shader por frame), y sigue siendo un **spike acotado de la Fase 6**: una tarde, medir FPS y batería, decidir con datos.

**Ajustes obligados en Hyprland** para que el escalón 1 se vea como en el mockup: `decoration:blur:vibrancy` alto (equivale al `saturate(190%)` del prototipo), `blur:brightness` ~1.07, y `layerrule = blur, quickshell:*` junto con `ignorealpha 0.3` — sin esa última regla el propio panel se emborrona a sí mismo y todo el trabajo de cantos se pierde.

**Riesgo a vigilar:** el material multiplica el coste de GPU por superficie. Con dock, barra, cromo y un panel abierto hay cuatro capas de blur compuestas a la vez. Es exactamente el escenario para el que existe la degradación adaptativa por batería (`plan-v2.md` §2.2): al desenchufar, bajar `passes` y desactivar el brillo móvil.

---

## 4. Deuda de diseño: lo que no tiene mockup

~~El v12 cubre barra, dock, launcher y cromo.~~ **Resuelto.** `limitless-shell.html` cubre ya barra, cromo HUD, dock, launcher, menú de comandos, paquetes, proyectos, notificaciones, OSD, lockscreen, widgets y portapapeles — todos con el material de §3.6.

Queda sin mockup una sola cosa: el **panel desplegable de red / audio / Bluetooth** de §3.1. Es el menos urgente y el más convencional de todos.

Regla que sigue vigente: **el mockup va antes que el QML**. Improvisar la estética en código es como acaban los rices inconsistentes.

Prioridad sugerida: OSD y notificaciones (los ves 50 veces al día) → lockscreen (es la cara del sistema) → panel de red/audio → paquetes → widgets → portapapeles.

---

## 5. Stack y theming

**Stack:** QuickShell (QML) para todo el shell. Sin AGS, sin Astal. Waybar sólo como andamio temporal de la Fase 2, con eliminación programada en la Fase 4. El razonamiento completo está en `plan-v2.md` §1.1 y no cambia — el mockup lo refuerza, porque **la rueda orbital y el disco inclinado no son implementables ni en Waybar ni cómodamente en GTK**. QuickShell aporta además, ya resueltos: bandeja, MPRIS, PipeWire, UPower, servidor de notificaciones (→ mako sobra) y PAM.

**Conflicto de theming que hay que resolver ahora.** El plan v1 quiere matugen derivando la paleta del wallpaper. Pero el v12 tiene una **paleta de identidad fija** (cian/violeta/carmesí). Si matugen recolorea desde el fondo, destruye exactamente lo que hace reconocible al diseño.

| | Modelo | Veredicto |
|---|---|---|
| A ✅ | **Paleta de identidad fija**, escrita a mano en `theme.toml`; matugen se conserva sólo para generar los temas de **apps de terceros** (GTK, Qt/Kvantum, terminal) a partir de esa paleta — no al revés | El shell mantiene su carácter y las apps ajenas dejan de desentonar. Es el uso correcto de matugen aquí |
| B | matugen manda, todo sale del wallpaper | Con un fondo casi negro genera paletas apagadas; adiós al cian eléctrico |
| C | matugen con acento forzado | Complejidad extra para un beneficio que con un fondo fijo no existe |

Cadena resultante: `theme.toml` → plantillas matugen → `qs-theme.json` (singleton `Theme.qml`), `hypr-colors.conf`, GTK3/4, Qt5ct/Qt6ct/Kvantum, kitty, hyprlock. **Regla dura: ningún hex literal fuera de `themes/`.** Si aparece uno en un `.qml`, es un bug.

---

## 6. Estructura del repo y capa de sistema

Igual que en `plan-v2.md` §3, con `themes/hud-void/` como tema base y `docs/mockups/` ya poblado. Recordatorio de las piezas que el v1 no tenía: `bin/dotctl` (CLI único, para que renombrar un script no rompa un keybind), `packages/` (manifiestos con la versión de Hyprland fijada, porque los plugins rompen en cada actualización), `dev/nested.conf` (sesión Hyprland anidada para iterar sin arriesgar la sesión real) y `docs/decisions.md`.

> **La capa de automatización —el `dotctl` router, las migraciones, `update` con snapshot, `doctor` y el menú generado desde los scripts— está especificada aparte en [`plan-automation.md`](plan-automation.md)**, escrita sobre la arquitectura real de Omarchy 3. Es lo que separa "una carpeta de configs" de "un sistema de dotfiles", y su §8 dice qué construir en cada fase para no perderse tres semanas en tooling.

---

## 7. Fases

| Fase | Contenido | Salida verificable |
|---|---|---|
| **0 — Red de seguridad** | Hyprland instalado *junto a* tu entorno actual (**no reinstalar CachyOS**: es un paquete, no un SO). Repo, stow, `install.sh`, `dev/nested.conf`, rescate por TTY en el README. | Arrancas Hyprland desde SDDM y vuelves a tu DE sin drama |
| **1 — Núcleo + tokens** | `hyprland.conf` modular. `themes/hud-void/theme.toml` con los valores de §2 + plantillas matugen operativas. Blur/vibrancy/rounding/layerrules afinados contra el mockup. | Ventanas con el cristal correcto. `dotctl theme set` recolorea todo lo que ya existe |
| **2 — Usable a diario** | Waybar mínima con los tokens del v12 (andamio), fondo, walker/rofi, keybinds, cliphist, screenshots, hyprpicker. | **Puedes trabajar el día entero aquí.** Hito crítico |
| **3 — Sesión** | hyprlock + hypridle, swayosd, mako — todos con los tokens. hyprexpo (Mission Control). *Sin hyprbars: el semáforo macOS no pertenece a este lenguaje visual.* | El sistema se bloquea, avisa y responde como un desktop completo |
| **4 — QuickShell** | En orden: **cromo HUD** (§3.4, el más simple, ideal para aprender QML) → fondo shader → barra → dock → launcher → notificaciones → OSD. Se retira Waybar/mako/swayosd conforme se sustituyen. IPC para `SUPER+SPACE` / `SUPER+D`. | Un solo motor de shell. Waybar desinstalada |
| **5 — Paneles** | Mockup + implementación de red/audio/BT, paquetes (`SUPER+I`), widgets, portapapeles. Focus modes, degradación por batería, coherencia GTK/Qt. | El sistema se comporta como un producto |
| **6 — Pulido** | Gestos, curvas de animación finas, CI de lint (`qmllint`, `shellcheck`), README con capturas y GIFs. | Repo presentable |

El orden de la Fase 4 es deliberado: **empezar por el cromo HUD**, que es puramente decorativo y sin estado. Si te sale mal, no se rompe nada. Aprendes layer-shell, tokens y animaciones QML con red debajo, y llegas al dock —que es lo difícil— sabiendo ya QML.

---

## 8. Riesgos

| Riesgo | Prob. | Mitigación |
|---|---|---|
| Deriva estética al implementar los componentes sin mockup (§4) | **Alta** | Mockup antes de QML, siempre. Los tokens de §2 son ley |
| La rueda del launcher resulta más lenta que escribir en un rofi normal | Media | Medir tiempo-hasta-lanzar en la primera semana. Los arreglos de §3.2 (teclado + difuso) son los que deciden esto |
| Los plugins de Hyprland rompen al actualizar | Alta | Versión fijada en `packages/plugins.txt`; `dotctl doctor` avisa |
| Curva de QML | Alta | La Fase 2 te deja usable sin QML; la Fase 4 empieza por lo trivial |
| Animaciones perpetuas (rueda, dock, estrellas) → batería | Media | Los tres arreglos ya identificados en §3.2, §3.3 y §3.5: animar por eventos, nunca por frame |
| Contraste insuficiente del texto dim | Cierta | Corregido en §2 antes de escribir nada |

---

## 9. Primer paso

Dos cosas, en este orden:

1. **Confirmar la Decisión #1** (§1). Todo el documento asume "A: comprometerse con el HUD". Es una respuesta de una palabra y condiciona las fases 3 a 5.
2. **Fase 0 completa** en una sesión: `git init`, estructura, `install.sh` idempotente que instale Hyprland junto a tu entorno actual, arrancar y volver, `dev/nested.conf`, y el rescate por TTY escrito en el README **antes** de necesitarlo.

Con eso, la Fase 1 se escribe bloque a bloque —cada línea explicada, sin copiar de ningún preset— y termina con los tokens del v12 ya gobernando el sistema entero.
