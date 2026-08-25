# Limitless OS

蒼 + 赫 → 茈 — dotfiles de Hyprland para CachyOS y distribuciones basadas en Arch Linux, con instalador TUI interactivo, arquitectura HUD en QuickShell y red de seguridad multicapa.

```bash
git clone <url-de-este-repo> ~/.limitless
cd ~/.limitless
./install.sh
```

`install.sh` instala `gum` si falta (es lo único que hace fuera de una etapa numerada) y lanza el instalador interactivo real en `install/run.sh`: diez etapas independientes (`00-preflight` a `90-verify`), cada una reanudable con `./install.sh --from=XX`, con progreso, spinners y errores mostrados en pantalla — no un `curl | bash` a ciegas. El repositorio se clona y se audita antes de ejecutar nada.

---

## Si algo se rompe

Esta tabla va primero a propósito. Documentación completa de recuperación en [`docs/LIMITLESS-OS.md`](docs/LIMITLESS-OS.md) §1.

| Síntoma | Acción |
|---|---|
| Hyprland no arranca | `Ctrl+Alt+F2` → `Hyprland -c ~/.limitless/dev/minimal.conf` (o entra a la sesión de emergencia XFCE desde LightDM) |
| Arranca pero sin barra ni dock | Revisa `dotctl doctor` — QuickShell en construcción (Fase 4) |
| Rompió tras `./install.sh` o `pacman -Syu` | Reinicia → Menú GRUB → submenú **«Arch Linux snapshots»** (Btrfs + Snapper) |
| Sin red desde el TTY | `nmtui` o `impala` |
| Fallo gráfico en el gestor de pantalla | Reinicia a TTY (`Ctrl+Alt+F2`) o elige **XFCE** en el selector de sesión de LightDM |
| Diagnóstico general del sistema | `dotctl doctor` |

> Si ni siquiera `dev/minimal.conf` arranca, el problema está en el sistema base o drivers, no en tu configuración: inicia una instantánea anterior en solo lectura desde GRUB para diagnosticar y hacer rollback.

---

## Qué es Limitless OS

Un sistema de entorno de escritorio cohesivo, no una colección desarticulada de configs. Diseñado bajo principios rigurosos:

1. **Identidad visual inmutable:** Inspirada en las técnicas de Satoru Gojo (蒼 azul *Lapse* `#3b9eff`, 茈 morado *Hollow* `#a970ff`, 赫 rojo *Reversal* `#ff4a2e`). No se deriva del fondo de pantalla para evitar degradación de legibilidad.
2. **Cristal donde adorna, opacidad donde se lee:** *Liquid glass* con desenfoque real (`backdrop-filter` / blur en capas) en superficies del HUD, barra, dock y greeter; superficies 100% opacas con alto contraste (WCAG AA) para editores de código, navegadores y terminales de trabajo denso.
3. **Ecosistema TUI como ciudadano de primera:** Si existe una herramienta TUI madura, la TUI gana (`yazi`, `btop`, `lazygit`, `lazydocker`, `impala`, `bluetui`). Funcionan tanto en Wayland como en TTY pelado ante fallos gráficos.
4. **Router único de comandos (`dotctl`):** Un solo punto de entrada para automatización, tematización, diagnóstico y gestión de paquetes.

---

## Arquitectura de Sesión y Seguridad

Limitless implementa una cadena de arranque sólida y predecible:

```
GRUB (menú de instantáneas Btrfs con grub-btrfs)
  ↳ Plymouth eliminado (cero bloqueos cosméticos en arranque)
      ↳ LightDM (tema propio WebKit2 con cristal y selector de sesión)
          ├── [Diario] Hyprland Limitless (Wayland + uwsm)
          └── [Emergencia] XFCE (X11 puro, aislado del stack Wayland)
```

- **Gestor de Login (LightDM + WebKit2):** Tema personalizado en HTML/CSS/JS (`system/lightdm/`) con campo de colisión interactivo, cristal reactivo, selector de sesión y controles de energía.
- **Red de Emergencia XFCE:** Sesión gráfica ligera en X11. Si el compositor Wayland sufre una regresión tras una actualización, XFCE garantiza acceso gráfico inmediato sin competir con Hyprland.
- **Instantáneas automáticas:** `snapper` + `snap-pac` + `grub-btrfs` generan instantáneas previas y posteriores a cada transacción de paquetes, arrancables directamente desde el menú de GRUB.

---

## Color y Theming — Fuente Única de Verdad

Todo el color y la geometría del sistema nacen de [`themes/hud-void/theme.toml`](themes/hud-void/theme.toml). Ningún archivo de configuración fuera de `themes/` define valores hexadecimales de color arbitrarios.

- **Técnicas de color:**
  - **蒼 Azul (Lapse):** `#3b9eff` / core `#8fe3ff` — Modo activo por defecto.
  - **茈 Morado (Hollow):** `#a970ff` / core `#e9d5ff` — Acento central en Neovim y Starship.
  - **赫 Rojo (Reversal):** `#ff4a2e` / core `#ffb4a0` — Estados críticos, alertas y agentes bloqueados.
- **Generación centralizada (en construcción):** el diseño es que `matugen` procese `theme.toml` contra una plantilla por aplicación para sincronizar Hyprland, QuickShell, Ghostty, GTK, Qt, lazygit, btop, yazi y el greeter de LightDM con un solo cambio de estado. Hoy esto ya gobierna Neovim, Starship, GRUB y LightDM — las plantillas de matugen para el resto todavía no están escritas (`docs/LIMITLESS-OS.md` §6, Fase 2).

---

## Ecosistema de Comandos (`dotctl`)

El sistema utiliza `bin/dotctl` como router central ([`docs/plan-automation.md`](docs/plan-automation.md)). Los scripts en `bin/cmd/` declaran metadatos estructurados en sus cabeceras (`# dot:group=`, `# dot:summary=`, `# dot:terminal=`, `# dot:requires-sudo=`), alimentando automáticamente la ayuda, el autocompletado y el menú interactivo del HUD.

| Comando | Descripción |
|---|---|
| `dotctl doctor` | Diagnóstico integral: verifica binarios requeridos, servicios systemd, plugins de zsh, fuentes y estado de configs |
| `dotctl pkg <search\|install\|remove\|outdated\|sync>` | Buscador y gestor unificado de paquetes (repositorios oficiales y AUR) con previsualización fzf |
| `dotctl tui-install <cmd> <nombre> <glifo>` | Empaqueta cualquier TUI como app de primera clase: genera `.desktop` para el launcher y el dock |

Comandos como `dotctl theme`, `dotctl dev open` o `dotctl update` están diseñados (`docs/LIMITLESS-OS.md` §4, Fase 5) pero todavía no tienen script — no los invoques esperando que existan. El plan fase a fase de qué falta está en `docs/LIMITLESS-OS.md` §6.

---

## Especificaciones y Documentación

Toda decisión técnica y de diseño está documentada en [`docs/`](docs/):

| Documento | Contenido y Alcance |
|---|---|
| [`LIMITLESS-OS.md`](docs/LIMITLESS-OS.md) | **Plan maestro definitivo:** arquitectura de sesión, red de seguridad multicapa, ecosistema de paquetes y fases |
| [`plan.md`](docs/plan.md) | Identidad visual, lenguaje de *liquid glass*, diseño HUD y fases de construcción del shell |
| [`plan-automation.md`](docs/plan-automation.md) | Arquitectura de `dotctl`, metadatos autodescriptivos, migraciones y patrones adaptados de Omarchy |
| [`spec-layouts.md`](docs/spec-layouts.md) | Layouts por workspace (master, dwindle, scroll, grid, focus), terminal Ghostty y Hyprland en Lua |
| [`spec-keybinds.md`](docs/spec-keybinds.md) | **Tabla definitiva de atajos:** SUPER como tecla líder, teclas de función/laptop (XF86), OBS y portal PipeWire |
| [`spec-colorscheme.md`](docs/spec-colorscheme.md) | Esquema cromático de Neovim y validación de ratios de contraste WCAG AA |
| [`spec-package-panel.md`](docs/spec-package-panel.md) | Especificación del buscador y panel de paquetes interactivo |
| [`plan-fase1-cimientos.md`](docs/plan-fase1-cimientos.md) | Especificación técnica de la Fase 1: cimientos en Lua, estructura de stow y theming |
| [`runbook-despliegue.md`](docs/runbook-despliegue.md) | Procedimiento de despliegue final sobre hardware real (solo tras completar todas las fases) |
| [`reparto-tareas.md`](docs/reparto-tareas.md) | Criterios de delegación y gestión de riesgos entre agentes de desarrollo |
| [`mockups/limitless-shell.html`](docs/mockups/limitless-shell.html) | **Mockup interactivo del shell:** referencia visual verificada píxel por píxel |

---

## Estructura del Repositorio

```
install.sh              Punto de entrada — verifica dependencias básicas y lanza install/run.sh
install/                lib/ (ui.sh, common.sh) + stages/ (00-preflight a 90-verify, reanudables)
bin/dotctl              Router único de comandos del sistema
bin/cmd/                Módulos de comandos independientes (doctor, pkg, tui-install, etc.)
stow/                   Paquetes de configuración gestionados por GNU Stow (hypr, quickshell, nvim, starship, zsh, applications)
system/                 Configuraciones a nivel de sistema base (grub, lightdm, vconsole)
themes/hud-void/        theme.toml — Fuente única de verdad de colores y geometría
packages/               pacman.txt y aur.txt — Listas declarativas de paquetes del sistema
dev/minimal.conf        Configuración Hyprland mínima conocida-buena para rescate
docs/                   Especificaciones técnicas completas, runbooks y mockups visuales
```
