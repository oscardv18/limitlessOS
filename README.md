# Limitless OS

蒼 + 赫 → 茈 — dotfiles de Hyprland para CachyOS, con instalador TUI propio.

```bash
git clone <url-de-este-repo> ~/.limitless
cd ~/.limitless
./install.sh
```

`install.sh` instala `gum` si falta (es lo único que hace fuera de una etapa numerada) y lanza el instalador interactivo real en `install/run.sh`: diez etapas, cada una reanudable, con progreso, spinners y errores mostrados — no un `curl | bash` a ciegas. El repo se clona y se lee antes de ejecutar nada.

## Si algo se rompe

Esta tabla va primero a propósito. Documentación completa: [`docs/LIMITLESS-OS.md`](docs/LIMITLESS-OS.md) §1.

| Síntoma | Acción |
|---|---|
| Hyprland no arranca | `Ctrl+Alt+F2` → `Hyprland -c ~/.limitless/dev/minimal.conf` |
| Arranca pero sin barra ni dock | Revisa `dotctl doctor` — QuickShell aún no existe en este repo (Fase 4) |
| Rompió tras `./install.sh` o `dotctl update` | Reinicia → GRUB → submenú **«Arch Linux snapshots»** |
| Sin red desde el TTY | `nmtui` o `impala` |
| No sé qué pasa | `dotctl doctor` |

Si ni siquiera `dev/minimal.conf` arranca, el problema es del sistema, no de esta configuración: usa la instantánea anterior desde GRUB.

## Qué es esto

Un sistema de dotfiles completo, no una carpeta de configs: paleta de identidad propia (las técnicas de Gojo — 蒼 azul, 茈 morado, 赫 rojo), liquid glass real en todas las superficies que se ven pero no se leen, un shell HUD en QuickShell (en construcción), y un ecosistema de terminal coherente de punta a punta — mismo tema en Neovim, Starship, zsh y el propio instalador.

Documentación completa en [`docs/`](docs/):

| Documento | Contenido |
|---|---|
| [`LIMITLESS-OS.md`](docs/LIMITLESS-OS.md) | Plan maestro: red de seguridad, ecosistema, fases |
| [`plan.md`](docs/plan.md) | Identidad visual, liquid glass, fases del shell |
| [`plan-automation.md`](docs/plan-automation.md) | `dotctl`, migraciones, patrones tomados de Omarchy |
| [`spec-layouts.md`](docs/spec-layouts.md) | Layouts por workspace, terminal, Hyprland 0.55+/0.56 |
| [`spec-colorscheme.md`](docs/spec-colorscheme.md) | El tema de Neovim, medido |
| [`spec-package-panel.md`](docs/spec-package-panel.md) | Buscador de paquetes |
| [`mockups/limitless-shell.html`](docs/mockups/limitless-shell.html) | Mockup interactivo del shell completo |

## Estado

Ver el plan maestro para el detalle fase a fase. En resumen: la identidad visual está cerrada y verificada en el mockup; el instalador y la configuración base de Hyprland/zsh/Neovim/Starship ya son código real; QuickShell (el shell en sí) está en diseño, pendiente de construcción.

## Estructura

```
install.sh              punto de entrada — instala gum y lanza install/run.sh
install/                lib/ (ui.sh, common.sh) + stages/ (00 a 90, numeradas)
bin/dotctl               router único; bin/cmd/ son sus comandos
stow/                    un paquete de GNU Stow por aplicación
system/                  configs que no van por stow (greetd, vconsole)
packages/                pacman.txt y aur.txt — la fuente de verdad de qué se instala
dev/minimal.conf         configuración de rescate — ver la tabla de arriba
docs/                    todo el porqué de cada decisión
```
