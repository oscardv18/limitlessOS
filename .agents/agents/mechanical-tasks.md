---
name: mechanical-tasks
description: Tareas pequeñas e independientes que ya tienen su spec completa por escrito — panel de búsqueda de paquetes (spec-package-panel.md), migraciones siguiendo la primera plantilla que entregue el agente principal, dotctl tui-install, el envoltorio de Discord con flags de Wayland (spec-keybinds.md §4c), CI de lint, pulido de README. Cada tarea es un archivo o un par de archivos, sin dependencias entre sí. Se puede invocar en paralelo sin restricción de orden.
tools:
  - view_file
  - grep_search
  - run_command
subagent: true
mainAgent: false
model: flash
commandExecutionPolicy: sandbox
---

Tarea pequeña, autocontenida, con spec ya escrita — no hay diseño que inventar, hay que seguir lo que ya está decidido.

## Antes de escribir nada

1. Lee `CLAUDE.md` completo — en particular la regla de que **nunca se ejecuta `install.sh` ni ninguna etapa de `install/stages/`** durante construcción, y que este proyecto trabaja en paralelo con otro agente (tú), así que revisa `git status`/`git log` antes de asumir el estado del repositorio.
2. Localiza la spec exacta de tu tarea:
   - Panel de paquetes → `docs/spec-package-panel.md` (incluye código de referencia real de Omarchy, no lo reinventes)
   - Migraciones → `plan-automation.md` §5 + la primera migración ya escrita por el agente principal, como plantilla del patrón exacto
   - `dotctl tui-install` → el patrón ya existe en `install/stages/80-tui.sh`, replícalo
   - Envoltorio de Discord → `docs/spec-keybinds.md` §4c, con los flags de Wayland ya verificados ahí — no los cambies
   - CI de lint → `qmllint` sobre `.qml`, `shellcheck` sobre `install/` y `bin/`, siguiendo el mismo criterio que ya usa `bin/cmd/doctor`

## Reglas no negociables

- **Verifica antes de afirmar** (la regla del proyecto, en `CLAUDE.md`): si vas a usar un paquete, comando o API que no está ya documentado en este repositorio, comprueba que existe y con ese nombre exacto antes de escribirlo — no lo asumas de memoria.
- Tu tarea toca su propio archivo o los que la spec indique explícitamente — nada de `hyprland.lua`, nada de `install/lib/`, nada del cimiento de QuickShell.
- Sintaxis validada antes de reportar terminado: `bash -n` para scripts, formato correcto para YAML/TOML/desktop entries.

## Al terminar

Reporta qué tarea, qué archivo(s) tocaste, y el resultado de la verificación de sintaxis correspondiente.
