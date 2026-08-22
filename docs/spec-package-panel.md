# Spec: buscador e instalador de paquetes (`SUPER+I`)

> Complemento de `plan-automation.md`. Cubre el flujo que en Omarchy es `Install > Package` / `Install > AUR`.
> Escrito sobre el código real de `omarchy-pkg-install` y `omarchy-pkg-aur-install`.

---

## 1. Qué hace Omarchy exactamente

Lo primero que sorprende al leer la fuente: **el flujo entero son ~20 líneas de bash.** No hay panel, no hay app, no hay GUI. Es `fzf` sobre la salida de `pacman`.

```bash
fzf_args=(
  --multi                                   # Tab marca varios
  --preview 'pacman -Sii {1}'               # panel de detalles en vivo
  --preview-window 'down:65%:wrap'
  --bind 'alt-p:toggle-preview'
  --bind 'alt-j:preview-down,alt-k:preview-up'
  --color 'pointer:green,marker:green'
)
pkg_names=$(pacman -Slq | fzf "${fzf_args[@]}")

if [[ -n $pkg_names ]]; then
  source omarchy-sudo-keepalive
  echo "$pkg_names" | tr '\n' ' ' | xargs sudo pacman -S --noconfirm
  omarchy-show-done
fi
```

La variante AUR es idéntica cambiando `pacman -Slq` por `yay -Slqa`, `pacman -Sii` por `yay -Siia`, y añadiendo un binding extra: `alt-b` cambia la preview al **PKGBUILD** (`yay -Gpa`), para que puedas leer el script que vas a compilar antes de compilarlo. Detalle de seguridad genuinamente bueno.

Tres piezas que sostienen todo y son fáciles de pasar por alto:

- **`omarchy-sudo-keepalive`** — mantiene viva la sesión de sudo. Sin esto, compilar 10 paquetes AUR hace que sudo caduque a mitad y la instalación muere.
- **`omarchy-show-done`** — notificación al terminar. Compilar desde AUR puede tardar 20 minutos; no te vas a quedar mirando.
- **La cabecera de metadatos**, que resulta ser distinta de la que yo propuse:

```bash
# omarchy:summary=Show a fuzzy-finder TUI for picking new Arch packages to install.
# omarchy:requires-sudo=true
```

Es `# <ns>:<clave>=<valor>`. Y `requires-sudo=true` es una idea que yo no había contemplado y que conviene copiar: **el router se encarga del sudo de forma centralizada** en vez de que cada script lo resuelva a su manera. Ya está corregido en `plan-automation.md` §3.

---

## 2. La decisión: terminal con fzf, o panel nativo QuickShell

El plan v1 daba esto por resuelto ("panel nativo de QuickShell con estética de cristal, buscador reutilizado del launcher, panel lateral de detalles estilo Jarvis"). Tras leer el código, la decisión merece más cuidado, y el motivo es una cifra:

- `pacman -Slq` → **~14.000** paquetes
- `yay -Slqa` → **~90.000** paquetes (AUR)

Filtrar 90.000 cadenas en cada pulsación de tecla desde JavaScript dentro de QML **va a dar tirones**. fzf está escrito en Go, filtra en paralelo y hace eso sin despeinarse. No es un detalle de implementación: es el eje de la decisión.

| | Enfoque | Pro | Contra |
|---|---|---|---|
| A | **Terminal + fzf tematizado** (la vía de Omarchy) | 20 líneas. Funciona hoy. Multi-select, preview y PKGBUILD gratis. Velocidad imbatible | Es una ventana de terminal: el aspecto llega hasta donde llegue el tema del terminal |
| B | **Panel nativo QuickShell** | Encaja perfecto con el HUD, reutiliza el buscador del launcher, panel de detalles a tu gusto | Rendimiento sobre 90k ítems, `Process` asíncrono, parseo de `pacman -Sii`, gestión de sudo, streaming de salida. Semanas, no días |
| C ✅ | **Híbrido por fases** | Ver abajo | Requiere disciplina para no saltarse la fase 1 |

### Recomendación: C

**Fase 2 — copia el enfoque de Omarchy casi literal, pero tematizado.** Un terminal flotante puede verse *muy* HUD si le pones:

- Regla de ventana en Hyprland: `windowrulev2 = float, class:^(dotctl-pkg)$` + tamaño centrado + `rounding` + `opacity` + blur.
- Colores de fzf desde `theme.toml`: `--color 'fg:#e5e9f0,fg+:#0ea5e9,bg:-1,bg+:#12141c,border:#94a3b824,pointer:#0ea5e9,marker:#6d28d9,prompt:#6d28d9,info:#64748b'`.
- `--pointer '❯' --marker '◈' --prompt '◈ PKG › '` — los glifos del v12, así que aunque sea un terminal, **habla tu idioma visual**.
- `--border none --preview-window 'right:55%:border-left'` para que se parezca al panel lateral que querías.

Con eso tienes el flujo completo funcionando en una tarde, y probablemente descubras que el 90% de lo que querías del panel nativo ya está.

**Fase 5 — reevalúa con datos.** Si después de usarlo dos meses el terminal te sigue chirriando, migras. Y si migras, la vía sensata no es reimplementar el matching: es **usar fzf como motor de filtrado sin interfaz**. `fzf --filter=<query>` recibe la lista por stdin y escribe los resultados ordenados en stdout, sin TUI. QuickShell le manda la consulta con un debounce de ~100 ms y pinta los N primeros con tus tokens. Obtienes velocidad de Go con presentación de QML.

**Y una regla que aplica pase lo que pase:** la instalación en sí **se ejecuta siempre en una ventana de terminal visible**, aunque la selección sea nativa. Motivos: la contraseña de sudo, la salida de compilación de AUR (que puede tardar 20 minutos y a veces pregunta cosas), y los errores de PKGBUILD. Un panel bonito que se traga un fallo de compilación es peor que un terminal feo que te lo enseña.

**La regla arquitectónica que hace posible todo esto:** el keybind y la entrada del menú apuntan siempre a `dotctl pkg install`. Nunca a fzf, nunca a un panel. Cambiar el frontend por debajo no toca ni `keybinds.conf` ni el QML del menú.

---

## 3. Cuatro mejoras sobre Omarchy

Su script está bien para una distro. Para un **repo de dotfiles** le faltan cosas:

**3.1 — Un solo buscador, no dos.** Tú describías el flujo como "Install → elijo entre AUR o Package → me lista todo". Esa bifurcación existe porque son dos comandos distintos. Pero `pacman -Sl` (sin `-q`) devuelve el repositorio en la primera columna, así que puedes emitir **una lista unificada y prefijada**:

```
extra/neovim      aur/hyprshot-git      multilib/steam      extra/btop
```

Un único `SUPER+I`, y si quieres acotar escribes `aur/` en la búsqueda — porque el matching difuso ya filtra por el prefijo. Una entrada de menú en vez de dos, y no tienes que decidir *antes* de buscar si lo que quieres está en AUR o no, que es justo lo que muchas veces no sabes.

**3.2 — Que el manifiesto se actualice solo.** `omarchy-pkg-install` instala y ya está. En un repo de dotfiles eso hace que `packages/pacman.txt` se pudra en dos semanas. El tuyo debe, al terminar con éxito, **añadir lo instalado al manifiesto correspondiente y ofrecerte commitear**. Es la diferencia entre un manifiesto que describe tu sistema y uno que describe tu sistema de hace tres meses.

**3.3 — Ocultar lo ya instalado.** `pacman -Slq` lista *todo*, incluido lo que ya tienes. Se arregla con una línea:

```bash
comm -23 <(pacman -Slq | sort -u) <(pacman -Qq | sort -u)
```

Y para el flujo inverso (`dotctl pkg remove`), lo contrario. Pequeño, pero se nota cada vez que lo usas.

**3.4 — Snapshot antes de instalar.** Ya vas a tener `dotctl snapshot create` (`plan-automation.md` §6). Engancharlo aquí cuando la selección supere N paquetes, o siempre que haya AUR de por medio, convierte "instalé 30 cosas y algo rompió el sistema" en un reinicio.

---

## 4. Alcance final del panel

Con el árbol de menú generado desde los metadatos (`plan-automation.md` §4), esto deja de ser un panel especial y pasa a ser una rama:

```
◈ SISTEMA
├── ▣ Paquetes
│   ├── Instalar          → dotctl pkg install     (lista unificada, §3.1)
│   ├── Eliminar          → dotctl pkg remove
│   ├── Buscar            → dotctl pkg search      (sólo consulta, sin instalar)
│   ├── Actualizaciones   → dotctl pkg outdated    (checkupdates + yay -Qua)
│   └── Sincronizar       → dotctl pkg sync        (manifiesto ↔ sistema)
├── ⚙ Estilo
└── ⏻ Sesión
```

Añadir `dotctl pkg outdated` es escribir un script con su cabecera. Aparece en el menú HUD solo.

---

## Fuentes

- [`bin/omarchy-pkg-install`](https://github.com/basecamp/omarchy/blob/master/bin/omarchy-pkg-install)
- [`bin/omarchy-pkg-aur-install`](https://github.com/basecamp/omarchy/blob/dev/bin/omarchy-pkg-aur-install)
- [Package Management — DeepWiki](https://deepwiki.com/basecamp/omarchy/5-terminal-and-shell)
- [fzf — ArchWiki](https://wiki.archlinux.org/title/Fzf)
