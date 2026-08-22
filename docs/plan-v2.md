# Plan v2 — Dotfiles Hyprland "Liquid Glass" (CachyOS)

> Revisión crítica del plan v1 (`plan-dotfiles-hyprland.md`) + opciones en cada punto de decisión + ideas que el v1 no contempla.
> Cada decisión tiene **Opciones** y una **Recomendación** marcada con ✅.

---

## 0. Qué está bien del plan v1 (no tocar)

- El mapeo macOS → Linux es correcto y completo.
- Hyprland nativo para blur/rounding/shadow: sí, es la base.
- matugen como motor de color: es la elección correcta hoy.
- Fases incrementales con git desde el commit 0.
- Elegir QuickShell para dock/launcher (Fase 4): **es la mejor decisión del plan**, y por eso mismo hay que llevarla más lejos (ver §1.1).

---

## 1. Los 4 problemas reales del plan v1

### 1.1 Contradicción de stack: Waybar + AGS + QuickShell coexisten

El documento mapea AGS en §2, crea `stow/ags/` en §3, decide QuickShell en Fase 4, y vuelve a decir "propagación a Waybar/AGS" en Fase 5. Son **tres motores de shell** para el mismo trabajo.

Consecuencias: tres lenguajes (JSONC+CSS, TS+GTK4, QML), tres sistemas de theming, tres puntos de fallo, y una barra Waybar que nunca va a casar visualmente con el dock QuickShell (distinta pila de render, distintas curvas de animación, distinto blur).

**Opciones**

| | Stack | Pro | Contra |
|---|---|---|---|
| A | Waybar + rofi, sin QuickShell | Rapidísimo de arrancar, todo copy-pasteable | Techo bajo: no hay dock con magnificación, ni rueda, ni widgets ricos. Renuncias al 60% de la visión |
| B | Waybar (barra) + QuickShell (dock/launcher/widgets) | Barra estable desde el día 1 | Dos motores; barra y dock nunca casan del todo; doble theming |
| C ✅ | **QuickShell para todo el shell** (barra, dock, launcher, notificaciones, OSD, widgets) | Un lenguaje (QML), un theme, coherencia visual total, animaciones compartidas | Curva de QML al principio; menos tutoriales que Waybar |

**Recomendación: C.** AGS/Astal sale del plan por completo. Waybar entra sólo como **andamio temporal** de la Fase 2, con fecha de caducidad explícita: se borra en la Fase 4. No es tiempo perdido — te da un desktop usable mientras aprendes QML, y el CSS te sirve para fijar la paleta.

Lo que QuickShell cubre nativamente y el v1 no aprovecha (`Quickshell.Services.*`): bandeja del sistema, MPRIS (música), PipeWire (volumen real, no `wpctl` por Process), UPower (batería), Notifications (servidor completo → **mako sobra**), Hyprland IPC, y PAM (un lockscreen propio es posible).

### 1.2 Reinstalar CachyOS es innecesario y arriesgado

El v1 abre con "reinstalar CachyOS con el instalador online eligiendo Hyprland". Hyprland es un paquete, no un sistema operativo: se instala sobre lo que ya tienes y aparece como sesión en SDDM junto a la actual.

**Opciones**

| | Ruta | Pro | Contra |
|---|---|---|---|
| A ✅ | **Instalar Hyprland sobre el CachyOS actual** | Cero riesgo, cero pérdida de datos, el DE actual queda como salvavidas real (no hipotético) | Arrastras config previa (menor: casi todo vive en `~/.config`) |
| B | Reinstalar eligiendo perfil Hyprland | Base "limpia" | Horas de setup, riesgo de pérdida, y el perfil trae config preconfigurada que vas a borrar igual |
| C | VM o segundo usuario | Aislamiento total | Sin aceleración GPU decente el blur no se ve como se verá de verdad |

**Recomendación: A.** El "salvavidas" que el v1 pone como *opcional* pasa a ser el estado por defecto. Regla de oro: **no cierres la sesión buena hasta que la nueva arranque dos veces seguidas.**

### 1.3 No hay estrategia de "no romper nada"

El v1 asume iteración a ciegas: editas config, cierras sesión, rezas. Tres mecanismos cambian el ritmo de trabajo por completo:

1. **Sesión anidada.** Hyprland corre dentro de una ventana de tu sesión actual: `Hyprland -c ~/dotfiles/dev/nested.conf`. Pruebas keybinds, reglas de ventana y layouts sin arriesgar la sesión real.
2. **Hot reload.** `hyprctl reload` para la config; `hyprctl keyword decoration:blur:passes 4` para probar valores en caliente sin editar archivos; QuickShell recarga QML solo al guardar. El bucle de iteración baja de minutos a segundos.
3. **TTY de rescate documentado.** `Ctrl+Alt+F2` → login → `git -C ~/dotfiles checkout HEAD~1 && systemctl restart sddm`. Escrito en el README, no en tu memoria.

### 1.4 El theming coordinado llega en la Fase 5 — llega tarde

Si el color se centraliza en la Fase 5, las Fases 1–4 se escriben con colores hardcodeados que luego hay que desenterrar de cinco archivos. **El theming es infraestructura, no acabado.** Se monta en la Fase 1, aunque al principio genere un solo tema.

Arquitectura: **una fuente de verdad → plantillas → todo lo demás.**

```
themes/liquid-blue/theme.toml   ← ÚNICA fuente de color (o generada por matugen desde el wallpaper)
        │
        └── themes/_templates/
              ├── hypr-colors.conf      → Hyprland (bordes, sombras)
              ├── qs-theme.json         → QuickShell (leído por un singleton Theme.qml)
              ├── gtk3 / gtk4 / libadwaita
              ├── qt5ct / qt6ct / Kvantum   ← el v1 lo omite: las apps KDE se verían fuera de sitio
              ├── kitty.conf (o ghostty)
              ├── hyprlock.conf
              └── mako / swayosd            (mientras existan)
```

Regla dura: **ningún hex literal fuera de `themes/`.** Si aparece uno en un `.qml`, `.conf` o `.css`, es un bug.

---

## 2. Ideas que el plan v1 no contempla

De "impacto alto / esfuerzo bajo" a experimental.

### 2.1 Impacto alto, esfuerzo bajo

**Plugins de Hyprland — te dan gratis lo que el v1 planea construir a mano**

- **hyprbars** → barras de título con los tres botones semáforo. El v1 lista esto como elemento clave de la inspiración y luego nunca dice cómo lograrlo. hyprbars es la respuesta directa: color, radio y orden de botones configurables.
- **hyprexpo** → Mission Control. Rejilla animada de todos los workspaces. Es la pieza de macOS que más se echa de menos y no aparece en el plan.
- **hyprscrolling / hyprscroller** → layout scrollable tipo PaperWM. Opcional, pero combina muy bien con un dock-rueda.

Precio a pagar: los plugins se compilan contra la versión exacta de Hyprland y **rompen en cada actualización**. Gestión con `hyprpm update`, y `install.sh` fija versiones.

**Ajuste fino del glass (el v1 dice "blur" y ahí lo deja)**

El aspecto macOS no sale de `blur = true`, sale de la combinación: `vibrancy` (saturación del fondo difuminado — es *el* parámetro que separa "borroso" de "vidrio"), `vibrancy_darkness`, `noise` bajo, `contrast`, y `passes` 3–4 con `size` moderado (más passes y menos size rinde mejor que al revés).

Y lo crítico que casi todos los rices olvidan: **`layerrule = blur, <namespace>`** para que las superficies de QuickShell (barra, dock, launcher) tengan blur de verdad, más `layerrule = ignorealpha 0.3, <namespace>` para que las zonas transparentes no se emborronen a sí mismas. Sin esto el dock se ve plano por muy bonito que sea el QML.

**Toolchain de calidad desde el commit 1**

`shellcheck` + `shfmt` (scripts), `qmllint` (QML), `jq` (JSONC), `stylelint` (CSS), en un pre-commit hook y en un GitHub Action. Suena excesivo para dotfiles personales — hasta la primera vez que un typo en QML te deja sin barra sin saber por qué. Coste: una tarde. Beneficio: permanente.

**`dotctl`: un único punto de entrada**

El v1 dispersa la lógica en `toggle-theme.sh`, `wallpaper-picker.sh`, `screenshot.sh`… Mejor un CLI con subcomandos: `dotctl theme set liquid-blue`, `dotctl wallpaper next`, `dotctl focus deep`, `dotctl doctor`, `dotctl update`. Los scripts siguen existiendo dentro, pero la superficie pública es una: los keybinds llaman a `dotctl …`, así que **renombrar un script interno nunca rompe un keybind**.

`dotctl doctor` merece mención aparte: verifica paquetes faltantes, symlinks rotos de stow, plugins desincronizados con la versión de Hyprland, y servicios caídos. Convierte "se me rompió algo" en un diagnóstico de 5 segundos.

### 2.2 Impacto alto, esfuerzo medio

**Degradación adaptativa por batería/carga** — original y muy útil en portátil

Un servicio que escucha UPower y, al desconectar la corriente, ejecuta `hyprctl keyword` para bajar `blur:passes`, acortar animaciones y desactivar sombras; al reconectar, restaura. macOS no hace esto; tú sí puedes. El mismo mecanismo sirve para un **"modo rendimiento"** manual (juegos, compilar) y para **"reduced motion"** (accesibilidad, o simplemente cuando el blur marea).

**Focus Modes / No Molestar de verdad**

No sólo silenciar notificaciones: un modo es un perfil que a la vez silencia, activa idle-inhibit, cambia el wallpaper a algo neutro, oculta el dock y aplica una paleta más sobria. `dotctl focus work|deep|off`. Es el tipo de integración que sólo puedes tener cuando controlas todo el shell — justo el argumento a favor de la Opción C de §1.1.

**Panel de paquetes (ya en el v1) → extenderlo a un HUD de sistema**

El v1 lo limita a instalar. Con el mismo componente de búsqueda: actualizaciones pendientes (`checkupdates`), huérfanos, tamaño de caché, unidades systemd fallidas, botón de limpieza. Un panel, varias pestañas, 80% del código reutilizado.

**Portapapeles estilo macOS**

`cliphist` de backend + panel QuickShell con búsqueda difusa y previsualización de imágenes, en `SUPER+V`. Trivial una vez tienes el componente de lista filtrada del launcher.

**Fuentes, iconos y cursores** (el v1 no los menciona y definen buena parte del "se ve como macOS")

- UI: SF Pro no es redistribuible → no puede ir en el repo. Alternativas: **Inter** (la más cercana, libre) o **Geist**. Mono: **JetBrains Mono** o **Maple Mono**, versión Nerd Font.
- Iconos: **WhiteSur**, o **Colloid** en variante circular.
- Cursor: **Apple Cursor / macOS-Monterey** (AUR).
- Regla para un repo público: lo no redistribuible se **instala**, no se **versiona**. `install.sh` lo baja; el repo guarda sólo el nombre del paquete.

### 2.3 Experimental — aquí está el diferenciador real

**Shader de "liquid glass" auténtico**

Lo que hace que Tahoe se vea como se ve no es el blur, es la **refracción en los bordes**: la luz se dobla en el canto del panel y hay un realce especular. Ningún rice de Hyprland lo tiene, porque ni Waybar ni GTK pueden hacerlo. Dos vías:

1. `decoration:screen_shader` de Hyprland (GLSL sobre pantalla completa). Barato de probar, difícil de acotar sólo a los paneles.
2. `ShaderEffect` de QML dentro de QuickShell, alimentado con `ScreencopyView` como textura de fondo → refracción real del escritorio detrás del dock, con distorsión en los bordes. Es la técnica correcta, y es **cara** (captura continua + shader por frame).

Tratar como **spike acotado en la Fase 6**: una tarde de prototipo, medir FPS y consumo, decidir con datos. Si funciona, tienes algo que no existe hoy en el ecosistema. Si no, has perdido una tarde y el dock con blur normal ya era bonito.

**Lockscreen propio en QuickShell (vía PAM)**

Posible y coherente con el resto. Pero un lockscreen roto = sesión inaccesible. **Recomendación: hyprlock.** Es aburrido y funciona. Deja el spike para cuando todo lo demás esté estable, y sólo con hyprlock configurado como fallback.

**Dock: la rueda del v12**

El v1 lo da por cerrado. Mi objeción no es estética sino ergonómica: una rueda que oculta iconos tras el borde inferior **esconde información**, y un dock existe para mostrarla. Implementa la rueda como está decidido, pero mide después de una semana de uso real cuántas veces haces scroll para encontrar un icono. Si la respuesta es "muchas", el arco estático (v13–v15, descartado) merece revisión. **Decide con uso, no con mockup** — y guarda ambas variantes tras un flag del theme, que en QML cuesta poco.

> **Bloqueo detectado:** los mockups v7 y v12 citados como referencia canónica no existen ni en el repo ni en Downloads. Recuperarlos o rehacerlos es **prerrequisito de la Fase 4**, y deben vivir versionados en `docs/mockups/`.

---

## 3. Estructura de repo revisada

Cambios sobre el v1: fuera `ags/`; dentro `bin/` (CLI), `packages/` (manifiestos), `dev/` (sesión anidada), `docs/` (mockups y decisiones); `themes/` con plantillas en vez de colores sueltos.

```
~/dotfiles/
├── README.md                    # incluye el procedimiento de rescate por TTY
├── install.sh                   # idempotente: paquetes + stow + plugins + fuentes
├── justfile                     # just install / restow / lint / doctor
├── bin/
│   └── dotctl                   # CLI único (theme, wallpaper, focus, doctor, update)
├── packages/
│   ├── pacman.txt
│   ├── aur.txt
│   └── plugins.txt              # plugins + versión de Hyprland fijada
├── stow/
│   ├── hypr/.config/hypr/
│   │   ├── hyprland.conf        # sólo `source =`, nada más
│   │   ├── conf/                # monitors, input, keybinds, windowrules,
│   │   │                        # animations, env, decoration, layerrules, plugins
│   │   ├── hyprlock.conf
│   │   └── hypridle.conf
│   ├── quickshell/.config/quickshell/
│   │   ├── shell.qml            # entrada
│   │   ├── modules/             # Bar, Dock, Launcher, Notifications, Osd,
│   │   │                        # Widgets, Packages, Clipboard
│   │   ├── services/            # wrappers de Quickshell.Services + estado propio
│   │   └── theme/Theme.qml      # singleton ← lee qs-theme.json generado
│   ├── waybar/                  # TEMPORAL — se elimina al cerrar la Fase 4
│   ├── matugen/  gtk/  qt/  kitty/  cliphist/
├── themes/
│   ├── liquid-blue/
│   │   ├── theme.toml           # fuente de verdad
│   │   └── wallpaper.png
│   └── _templates/              # plantillas matugen → todos los consumidores
├── dev/
│   └── nested.conf              # sesión Hyprland anidada para pruebas
├── docs/
│   ├── plan-v2.md               # este archivo
│   ├── decisions.md             # ADRs cortos: qué se decidió y por qué
│   └── mockups/                 # v7, v12… (faltan, recuperar)
└── assets/wallpapers/
```

Sobre Stow: el v1 acierta, es la opción correcta para una sola máquina. Añadido barato: un `justfile` para no memorizar flags.

---

## 4. Fases revisadas

Cambios clave: theming sube a la Fase 1, QuickShell empieza por la barra (no sólo el dock), y aparece una Fase 0 de seguridad.

| Fase | Contenido | Salida verificable |
|---|---|---|
| **0 — Red de seguridad** | Hyprland instalado *junto a* tu entorno actual. Repo git + stow + `install.sh` + esqueleto de `dotctl doctor`. `dev/nested.conf` funcionando. Rescate por TTY documentado. | Arrancas Hyprland desde SDDM y vuelves a tu DE sin drama |
| **1 — Núcleo + theming** | `hyprland.conf` modular. Blur/rounding/shadows/gaps afinados (vibrancy incluido). **matugen + `theme.toml` + plantillas operativos ya**, aunque sólo haya un tema. | Ventanas con glass. `dotctl theme set` cambia el color de todo lo que existe |
| **2 — Usable a diario** | Waybar mínima (andamio), swww + wallpaper, walker/rofi, keybinds macOS-like, cliphist, screenshots (grim+slurp+satty), hyprpicker. | Puedes trabajar el día entero aquí. **Hito a alcanzar rápido** |
| **3 — Sesión** | hyprlock + hypridle coordinados, swayosd, mako. Plugins: **hyprbars** (semáforo) + **hyprexpo** (Mission Control). | El sistema se bloquea, avisa y responde como un desktop completo |
| **4 — QuickShell** | Barra → dock (rueda v12) → launcher → notificaciones → OSD → widgets → panel de paquetes, **en ese orden**, retirando Waybar/mako/swayosd a medida que se sustituyen. IPC para toggles (`SUPER+SPACE`, `SUPER+D`). | Waybar, mako y swayosd desinstalados. Un solo motor de shell |
| **5 — Integración** | Focus modes, degradación por batería, HUD de sistema, wallpaper → recoloreado automático, Qt/GTK/libadwaita coherentes. | El sistema se comporta como un producto, no como una colección de configs |
| **6 — Pulido y spikes** | Gestos táctiles, curvas de animación finas, spike del shader de refracción, README con capturas y GIFs, CI de lint. | Repo presentable públicamente |

**La Fase 2 es el hito importante.** Un dotfiles que tardas seis semanas en poder usar es un dotfiles que abandonas. Todo lo espectacular (Fase 4+) se construye encima de algo que ya funciona.

---

## 5. Riesgos, por probabilidad

| Riesgo | Prob. | Mitigación |
|---|---|---|
| Los plugins de Hyprland rompen al actualizar | Alta | Versión fijada en `packages/plugins.txt`; `dotctl doctor` avisa del desajuste; no actualizar Hyprland un día que necesites el equipo |
| Curva de QML más larga de lo previsto | Alta | La Fase 2 te deja usable sin QML. QuickShell se aprende módulo a módulo, empezando por la barra (el más simple) |
| Blur pesado → batería y FPS | Media | Presupuesto de frame desde la Fase 1; degradación adaptativa (§2.2); `xray` para no re-blurrear ventanas |
| Scope creep (el v1 ya tiene 3 shells y un shader) | Media | `docs/decisions.md`: toda idea nueva se escribe ahí y **espera a la fase que le toca** |
| Mockups perdidos bloquean la Fase 4 | Cierta | Recuperar o rehacer antes de empezar |
| Assets no redistribuibles en repo público | Baja | Se instalan, no se versionan |

---

## 6. Primer paso concreto

No empezar por `hyprland.conf`. Empezar por la **Fase 0**, en este orden y en una sola sesión:

1. `git init` + estructura de carpetas + primer commit.
2. `install.sh` idempotente que instale Hyprland **junto a** tu entorno actual (sin reinstalar CachyOS).
3. Comprobar que arrancas Hyprland desde SDDM con una config de 20 líneas — y que vuelves a tu DE.
4. `dev/nested.conf` funcionando → a partir de aquí iteras sin riesgo.
5. Escribir el procedimiento de rescate en el README **antes** de necesitarlo.

Con eso montado, la Fase 1 (`hyprland.conf` modular + theming) se escribe bloque a bloque, explicando cada uno, sin copiar de ningún preset.
