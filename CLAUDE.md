# CLAUDE.md — Limitless OS

Instrucciones para cualquier instancia de Claude Code que abra este repositorio. Lee esto primero.

## Qué es este proyecto

Dotfiles de Hyprland para CachyOS con identidad visual propia (paleta de las técnicas de Satoru Gojo: 蒼 azul `#3b9eff`, 茈 morado `#a970ff`, 赫 rojo `#ff4a2e`), liquid glass real en superficies que se ven pero no se leen, y un ecosistema de terminal coherente de punta a punta. No es una carpeta de configs — es un sistema con instalador propio, router de comandos (`dotctl`), y documentación exhaustiva de cada decisión.

**El destino de este repo es correr sobre CachyOS sin entorno gráfico** (compositor Hyprland puro, sin GNOME/KDE). El usuario tiene doble arranque Windows/CachyOS en la misma máquina; este repo se escribió principalmente desde el lado Windows y se ejecuta/verifica del lado Linux.

## Primero: lee `docs/`

`docs/LIMITLESS-OS.md` es el plan maestro — léelo entero antes de tocar nada. Los demás documentos son specs de una pieza concreta:

| Documento | Cuándo consultarlo |
|---|---|
| `docs/LIMITLESS-OS.md` | Siempre primero. Fases, red de seguridad, ecosistema completo |
| `docs/plan.md` | Identidad visual, liquid glass, fases del shell QuickShell |
| `docs/plan-automation.md` | `dotctl`, migraciones, patrones de Omarchy |
| `docs/spec-layouts.md` | Layouts por workspace, terminal, Hyprland 0.55+/0.56 |
| `docs/spec-keybinds.md` | **Tabla definitiva de atajos.** SUPER es la tecla líder — nunca inventes un bind sin mirar aquí primero |
| `docs/spec-colorscheme.md` | El tema de Neovim, con la medición de contraste |
| `docs/spec-package-panel.md` | Buscador de paquetes |
| `docs/runbook-fase-0.md` | **El siguiente paso ejecutable.** Si no sabes qué hacer, es esto |
| `docs/mockups/limitless-shell.html` | Mockup interactivo del shell completo — verificado, funcional, es la referencia visual |

`docs/plan-v2.md` es histórico (una revisión intermedia superada por `LIMITLESS-OS.md`); no lo tomes como fuente de verdad si contradice a los documentos de arriba.

## Qué hacer ahora mismo

Ejecuta **`docs/runbook-fase-0.md`** paso a paso. Resumido: `./install.sh` desde la raíz del repo, luego verificar los dos criterios de cierre de la Fase 0 (submenú de instantáneas en GRUB, `Hyprland -c dev/minimal.conf` arranca desde un TTY). El instalador es interactivo (usa `gum`), así que corre con el usuario presente, no en segundo plano sin supervisión.

Tienes acceso de ejecución real que la sesión de Windows no tenía — úsalo: corre el instalador, lee los logs, corrige lo que falle, vuelve a intentar. No te limites a leer y describir lo que haría; hazlo.

## Reglas que no son negociables

**No adivines sintaxis de Hyprland 0.55+/0.56 en Lua.** Todo el proyecto se escribe en Lua (hyprlang está deprecado), pero durante el diseño no fue posible extraer con confianza los nombres exactos de campos del wiki. `dev/minimal.conf` se dejó deliberadamente en hyprlang viejo por este motivo — es la única excepción, documentada en su propia cabecera. Cuando escribas `hyprland.lua` real (Fase 1), verifica cada función de la API (`hl.bind`, `hl.workspace_rule`, `hl.layout.register`, etc.) contra el wiki en vivo o el código fuente, línea a línea. No copies de memoria ni extrapoles de los ejemplos de este repo.

**SUPER es la tecla líder.** `docs/spec-keybinds.md` es la fuente de verdad de todos los atajos. Contiene dos colisiones reales que se resolvieron ahí (no las repitas) y tres correcciones de "lo que el mockup usaba sin modificador, por limitación del navegador" vs. "lo que el sistema real necesita" — léela antes de escribir un solo `bind`.

**El mockup manda sobre el código.** `docs/mockups/limitless-shell.html` es la referencia visual verificada — colores exactos, geometría, comportamiento de animación. Cuando construyas QuickShell (Fase 4), el mockup se consulta antes de improvisar estética nueva. Si necesitas cambiar el diseño, cambia el mockup primero y verifícalo en el navegador antes de tocar QML.

**Ningún hex literal fuera de `themes/`**, una vez exista `theme.toml` (todavía no existe — es de las piezas grandes pendientes). Hoy la paleta vive escrita a mano en `stow/nvim/.config/nvim/colors/limitless.lua`, `stow/starship/.config/starship.toml`, `system/grub/theme/theme.txt` y `install/lib/ui.sh`; es una excepción temporal y documentada, no el estado final.

**Cristal donde adorna, opacidad donde se lee.** Terminal y superficies del shell llevan blur real; navegador, editores y cualquier cosa con texto denso van opacas a propósito. No es una renuncia estética, es la regla del proyecto.

**Verifica antes de afirmar.** Este proyecto se construyó verificando cada librería, paquete y sintaxis contra fuentes reales antes de escribir código sobre ellas — varias veces se corrigieron suposiciones equivocadas a mitad de camino (Hyprland cambió de `.conf` a Lua entre sesiones; `tuigreet` no acepta hex, solo nombres ANSI; `nvtop` pasó de AUR a repos oficiales). Si vas a instalar un paquete o usar una API que no has visto documentada en este repo, comprueba que existe y con ese nombre exacto antes de escribirlo en `packages/*.txt` o en un script.

## Estado del proyecto (verifica en `docs/LIMITLESS-OS.md` si esto queda desactualizado)

**Código real, ya escrito:**
- Instalador TUI completo (`install.sh` + `install/`, 10 etapas, probado con corrida simulada completa, reanudación y fallo-con-continuación)
- `bin/dotctl` (router) + `bin/cmd/doctor` (7 chequeos)
- zsh completo (`stow/zsh/`, 7 módulos — sustituye a fish con autosuggestions + fast-syntax-highlighting + fzf-tab)
- Neovim (`colors/limitless.lua`, 210 grupos), Starship (`starship.toml`, 33 módulos)
- greetd + tuigreet (`system/greetd/`), tema de GRUB (`system/grub/theme/`), paleta del VT (`system/vconsole/`)
- `dev/minimal.conf` — configuración de rescate, hyprlang (ver regla de arriba)

**Sin construir todavía:**
- `hyprland.lua` real (solo existe el de rescate en hyprlang)
- El shell de QuickShell entero (barra, dock, launcher, paneles — todo diseñado en el mockup, nada en QML)
- `theme.toml` + plantillas de matugen (la paleta hoy está escrita a mano en 4 sitios)
- 12 plantillas de tema restantes (Ghostty, btop, lazygit, lazydocker, yazi, bat, delta, fzf, hyprlock, GTK, Qt/Kvantum, herdr)
- Puente herdr → QuickShell, motor de sesiones de proyecto, migraciones

## Convenciones de commit y git

- Mensajes de commit en español, estilo del historial existente: línea de asunto corta, cuerpo explicando el *porqué*, sin emojis.
- El repo usa `.gitattributes` para forzar LF — no lo desactives ni lo pises.
- Antes de cualquier `git push --force`, `git reset --hard` o similar: para y pregunta. El historial de este repo es corto y no hay razón para reescribirlo sin que el usuario lo pida explícitamente.
- No hagas commit ni push a menos que el usuario lo pida — igual que en cualquier repo, pero vale la pena decirlo aquí porque esta sesión probablemente va a estar ejecutando comandos reales sobre el sistema y es fácil encadenar un `git commit` automático sin que se haya pedido.

## Tono

El usuario y la sesión de Windows llevan toda la conversación en español; sigue en español salvo que te pida lo contrario. El proyecto tiene una identidad estética muy definida (HUD futurista, Gojo, "liquid glass") — no la diluyas por comodidad técnica sin consultarlo primero.
