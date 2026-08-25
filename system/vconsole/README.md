# Paleta de la consola virtual

> **Nota:** este archivo se escribió cuando el greeter era `tuigreet` (superado por LightDM + `lightdm-webkit2-greeter`, ver `LIMITLESS-OS.md` §2 — LightDM no usa la paleta del VT, tiene su propio tema en HTML/CSS/JS). El razonamiento de abajo sigue siendo válido igual: cualquier TTY al que caigas (`Ctrl+Alt+F2`, rescate) sigue usando esta paleta remapeada, con o sin greeter gráfico encima.

> Esto es lo que hace que cualquier TTY se vea Limitless — tuigreet, en su momento, fue el ejemplo original que motivó el arreglo.

## El problema

`tuigreet --theme` **solo acepta nombres ANSI** (`blue`, `magenta`, `darkgray`…), no hex. Verificado contra su documentación: *"the color is a valid ANSI color name as listed in the ratatui repository"*.

Así que no se puede pedir `#3b9eff` directamente.

## La solución: cambiar lo que significa «blue»

En lugar de pelear con tuigreet, se remapea la paleta de 16 colores de la **consola virtual del kernel**. Cuando tuigreet pide `blue`, la consola pinta `#3b9eff`.

Dos efectos, ambos deseables:

1. **tuigreet queda en los colores exactos de Limitless.**
2. **Todos tus TTY también.** Y eso importa más de lo que parece: sin GUI, el TTY es tu consola de rescate (`LIMITLESS-OS.md` §1). Que la pantalla a la que caes cuando algo se rompe pertenezca al mismo sistema visual no es capricho — es continuidad cuando más la agradeces.

## Instalación

Añadir a `GRUB_CMDLINE_LINUX_DEFAULT` en `/etc/default/grub`:

```
vt.default_red=0x0e,0xff,0x4b,0xff,0x3b,0xa9,0x2e,0x7e,0x46,0xff,0x4b,0xff,0x8f,0xff,0x2e,0xea
vt.default_grn=0x15,0x4a,0xf0,0xd2,0x9e,0x70,0xe6,0x93,0x58,0x6b,0xf0,0x9d,0xe3,0x5e,0xe6,0xf2
vt.default_blu=0x24,0x2e,0xa5,0x5e,0xff,0xff,0xd6,0xb0,0x7a,0x7f,0xa5,0x3d,0xff,0xcb,0xd6,0xff
```

Los tres en la misma línea, separados por espacios, y después:

```bash
sudo grub-mkconfig -o /boot/grub/grub.cfg
```

Requiere reiniciar: la paleta se fija en el arranque del kernel.

La etapa `60-session` del instalador hace esto sola, comprobando antes si los parámetros ya están para no duplicarlos.

## La paleta

Los mismos 16 colores que `terminal_color_0..15` de `colors/limitless.lua` y que Ghostty. Una sola fuente, tres consumidores.

| # | Nombre ANSI | Color | Rol en Limitless |
|---|---|---|---|
| 0 | `black` | `#0e1524` | Superficie |
| 1 | `red` | `#ff4a2e` | 赫 · errores |
| 2 | `green` | `#4bf0a5` | Cadenas, éxito |
| 3 | `yellow` | `#ffd25e` | Tipos, avisos |
| 4 | `blue` | `#3b9eff` | 蒼 · funciones, botones |
| 5 | `magenta` | `#a970ff` | 茈 · palabras clave, prompt |
| 6 | `cyan` | `#2ee6d6` | Operadores |
| 7 | `gray` | `#7e93b0` | Texto secundario |
| 8 | `darkgray` | `#46587a` | Bordes, gutter |
| 9 | `lightred` | `#ff6b7f` | Variables |
| 10 | `lightgreen` | `#4bf0a5` | — |
| 11 | `lightyellow` | `#ff9d3d` | Números |
| 12 | `lightblue` | `#8fe3ff` | Hielo · hora, propiedades |
| 13 | `lightmagenta` | `#ff5ecb` | Macros |
| 14 | `lightcyan` | `#2ee6d6` | — |
| 15 | `white` | `#eaf2ff` | Texto principal |

## Fuente de la consola

La paleta arregla el color; la tipografía es aparte. Para que el TTY no desentone:

```bash
# /etc/vconsole.conf
FONT=ter-v18n          # paquete: terminus-font
```

Terminus a 18px es lo más cercano a JetBrains Mono que existe como fuente de consola. Los kanji del saludo (`無下限`) **no se renderizan en el VT** — la consola del kernel no tiene esos glifos. Si te importa, quita la parte japonesa del `--greeting` y deja solo `⬡ L I M I T L E S S`.

## Límite honesto — y ya superado

Esta paleta ANSI remapeada seguía teniendo un techo: por ser una TUI sobre consola, `tuigreet` no podía hacer cristal, blur, el campo de colisión, tipografía proporcional ni animación. Esa era exactamente la mejora anotada como pendiente en la versión anterior de este archivo.

**Ya está resuelto, por otra vía.** `system/lightdm/` reemplazó al greeter TUI por `lightdm-webkit2-greeter` — HTML/CSS/JS real, con `backdrop-filter` funcional. El cristal, el campo de colisión y la tipografía proporcional que aquí eran una limitación honesta, ahora existen de verdad en el login. Este archivo se queda solo por lo que sigue siendo cierto: la paleta del VT importa para cualquier TTY de rescate, que no pasa por LightDM.
