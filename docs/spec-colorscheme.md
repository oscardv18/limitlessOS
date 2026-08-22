# Spec: colorscheme de Neovim — «Limitless»

> Implementado en [`stow/nvim/.config/nvim/colors/limitless.lua`](../stow/nvim/.config/nvim/colors/limitless.lua) — 210 grupos de resaltado.
> Base: One Dark Pro Darker. Tonos intensificados y armonizados con el shell.

---

## 1. Los dos cambios que lo hacen tuyo

**1. El fondo deja de ser gris-marrón.** One Dark Pro Darker usa `#1e2227` / `#21252b`: neutro cálido. El nuestro es **`#04060d`**, exactamente el `--void` del shell — negro con sesgo azul. Es el único cambio que hace que el editor y el escritorio se vean del mismo mundo, y por sí solo vale más que todos los demás.

**2. Los tres colores de identidad ocupan sus roles naturales.** No hay que forzar nada, porque One Dark Pro ya reparte los papeles así:

| Rol sintáctico | One Dark Pro | Limitless | Técnica |
|---|---|---|---|
| Funciones | `#61afef` | **`#3b9eff`** | 蒼 Azul |
| Palabras clave | `#c678dd` | **`#a970ff`** | 茈 Morado |
| Errores | `#be5046` | **`#ff4a2e`** | 赫 Rojo |

Tu memoria muscular de One Dark Pro se conserva: las funciones siguen siendo azules, las keywords moradas. Lo que cambia es que ahora esos azules y morados son **los mismos** que los del dock, la barra y el campo de colisión.

---

## 2. «Mucho más intensos»: medido

Saturación HSL, One Dark Pro → Limitless:

| | ODP | Limitless | Δ |
|---|---|---|---|
| Verde (cadenas) | `#98c379` 38% | **`#4bf0a5`** 85% | **+46** |
| Naranja (números) | `#d19a66` 54% | **`#ff9d3d`** 100% | **+46** |
| Violeta (keywords) | `#c678dd` 60% | **`#a970ff`** 100% | **+40** |
| Rojo (variables) | `#e06c75` 65% | **`#ff6b7f`** 100% | **+35** |
| Ámbar (tipos) | `#e5c07b` 67% | **`#ffd25e`** 100% | **+33** |
| Cian (operadores) | `#56b6c2` 47% | **`#2ee6d6`** 79% | **+32** |
| Azul (funciones) | `#61afef` 82% | **`#3b9eff`** 100% | **+18** |

El salto medio es de **+36 puntos**. One Dark Pro es un tema apagado a propósito; éste está calibrado para un fondo casi negro, donde los tonos suaves se apagan aún más y hace falta empujarlos.

---

## 3. Paleta completa y contraste

Todo verificado sobre `#04060d`. El mínimo AA para texto normal es 4.5:1.

| Token | Hex | Contraste | Uso |
|---|---|---|---|
| Texto | `#eaf2ff` | 17.98:1 | Texto base |
| Ámbar | `#ffd25e` | 14.11:1 | Tipos, clases, structs |
| Hielo | `#8fe3ff` | 14.08:1 | Campos, propiedades, builtins |
| Verde | `#4bf0a5` | 13.80:1 | Cadenas |
| Cian | `#2ee6d6` | 12.93:1 | Operadores, regex |
| Naranja | `#ff9d3d` | 9.78:1 | Números, constantes, booleanos |
| Magenta | `#ff5ecb` | 7.44:1 | Macros, `return`, `import` |
| Coral | `#ff6b7f` | 7.39:1 | Variables, parámetros |
| Azul | `#3b9eff` | 7.25:1 | Funciones |
| Fg atenuado | `#7e93b0` | 6.45:1 | Delimitadores |
| Violeta | `#a970ff` | 6.22:1 | Palabras clave |
| Rojo | `#ff4a2e` | 6.05:1 | Errores, diff-delete |
| Comentarios | `#6b7f9e` | **4.97:1** | Comentarios, en cursiva |

**El comentario merece explicación.** One Dark Pro usa `#5c6370`, que sobre un fondo tan oscuro cae a ~3:1 — por debajo de AA. Es la queja más repetida contra el tema: los comentarios no se leen. Aquí están en 4.97:1, claramente secundarios pero legibles. Si trabajas ocho horas seguidas lo vas a notar.

---

## 4. La decisión del fondo transparente

Aquí hay una tensión que hay que resolver a conciencia: **nvim corre dentro del terminal, y el terminal es de cristal.** Si nvim no pinta fondo, hereda el cristal de Ghostty.

Y tú pediste **editores opacos**. Así que el valor por defecto es `vim.g.limitless_transparent = false`: nvim pinta su propio `#04060d`.

No pierdes la integración, porque ese `#04060d` es exactamente el void del fondo de pantalla. El editor sigue perteneciendo a la interfaz — simplemente no deja pasar el blur. Es la regla del proyecto aplicada al pie de la letra: **cristal donde adorna, opacidad donde se lee.** Texto denso durante horas necesita fondo estable.

Si quieres lo contrario para un nvim abierto de paso en un terminal suelto, `vim.g.limitless_transparent = true` antes del `:colorscheme`.

---

## 5. Cobertura

210 grupos: UI del editor, sintaxis clásica, **Treesitter** (`@variable`, `@function.builtin`, `@markup.*`, `@diff.*`…), **tokens semánticos de LSP** (`@lsp.type.*`), diagnósticos con `undercurl` y virtual-text sobre fondo teñido, diff y GitSigns, y los plugins habituales: Telescope, nvim-cmp, indent-blankline, Neo-tree, which-key, nvim-notify.

Además fija los **16 colores del terminal integrado** con la misma paleta, para que `:terminal` dentro de nvim y el terminal del sistema no se contradigan.

---

## 6. Pendiente

- **Plantilla de matugen.** Ahora mismo la paleta está escrita a mano en el `.lua`. Debe pasar a generarse desde `themes/hud-void/theme.toml`, como el resto (`plan.md` §5). Cuando eso esté, cambiar de técnica con `T` recolorea también el editor.
- **Ghostty**: aplicar los mismos 16 colores a su config, desde la misma plantilla.
- **Variantes por técnica**: 蒼 / 赫 / 茈 podrían desplazar el acento del editor (`CursorLineNr`, `Search`, selección) sin tocar los colores de sintaxis, que deben quedarse quietos — cambiar el color de las cadenas al cambiar de tema sería desorientador.
