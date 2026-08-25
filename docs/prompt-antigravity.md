# Prompt para Antigravity

> Copia y pega esto tal cual en el chat principal de Antigravity, con el repositorio abierto como workspace. No hace falta editarlo — ya referencia los archivos reales del repo.

```
Este workspace es Limitless OS. Antes de hacer nada, lee en este orden:
1. CLAUDE.md — reglas del proyecto, la más importante: NUNCA ejecutes
   install.sh ni ninguna etapa de install/stages/, bajo ninguna
   circunstancia, salvo que el usuario te lo pida explícitamente y
   estemos en la Fase de Despliegue (docs/runbook-despliegue.md).
2. docs/reparto-tareas.md — qué te toca a ti y a tus subagentes,
   qué le toca a Claude, y sobre todo el orden de dependencias: hay
   piezas que NO puedes empezar todavía.
3. docs/plan-fase1-cimientos.md — el plan de lo que Claude está
   construyendo ahora mismo (theme.toml, hyprland.lua, el cimiento
   de QuickShell). Antes de invocar cualquier subagente, comprueba
   si esos archivos ya existen — puede que hayan avanzado desde que
   se escribió este prompt.

Antes de invocar un subagente, corre `git status` y `git log --oneline -10`
para ver el estado real del repositorio — Claude puede estar trabajando en
paralelo ahora mismo, y tus subagentes no deben pisar archivos que no les
corresponden.

Tienes tres subagentes ya configurados en .agents/agents/, cada uno con su
modelo asignado en su propio frontmatter — no cambies esos valores:

- theme-templates (flash) — una plantilla de matugen por invocación
- quickshell-surfaces (pro) — una superficie de QuickShell por invocación
- mechanical-tasks (flash) — tareas pequeñas y autocontenidas

Cada archivo de subagente ya dice, en su propia descripción, si algo debe
existir antes de invocarlo. Respeta eso literalmente: si el subagente dice
que debe detenerse y reportar en vez de continuar, dale ese resultado por
bueno — no reinterpretes la instrucción para "avanzar de todos modos".

Lo que puedes invocar YA, sin esperar nada más (verifica primero que el
archivo correspondiente no exista todavía, por si ya se hizo):

- mechanical-tasks → panel de búsqueda de paquetes (docs/spec-package-panel.md)
- mechanical-tasks → envoltorio de Discord con flags de Wayland
  (docs/spec-keybinds.md §4c)
- mechanical-tasks → dotctl tui-install (el patrón ya existe en
  install/stages/80-tui.sh, replícalo)
- mechanical-tasks → CI de lint (qmllint + shellcheck)
- mechanical-tasks → pulido de README

Lo que NO debes invocar todavía, aunque parezca tentador:

- mechanical-tasks → migraciones: espera a que exista la primera,
  escrita por Claude, como plantilla del patrón

> **Actualización:** `theme-templates` y `quickshell-surfaces` YA NO están
> bloqueados — `themes/hud-void/theme.toml` y el cimiento de QuickShell
> (`stow/quickshell/.config/quickshell/limitless/{shell.qml,modules/*.qml}`)
> existen. Para `quickshell-surfaces` usa el prompt dedicado y más
> detallado de `docs/prompt-antigravity-fase4.md` en vez de improvisar
> sobre esta sección — tiene la API real del cimiento. Para
> `theme-templates`, las 12 plantillas de matugen (Ghostty, btop,
> lazygit, lazydocker, yazi, bat, delta, fzf, hyprlock, GTK, Qt/Kvantum,
> herdr) ya pueden invocarse tal cual describe `.agents/agents/theme-templates.md`.

Invoca los subagentes que correspondan en paralelo cuando sean
independientes entre sí — por ejemplo, el panel de paquetes y el
envoltorio de Discord no dependen uno del otro. Cuando termine cada uno,
resume en una frase qué se hizo y qué verificación de sintaxis pasó, sin
inventar que algo se verificó si el subagente reportó que no pudo hacerlo.

Cuando ya no quede ninguna tarea disponible de las de arriba, dilo
explícitamente y espera — no inventes trabajo nuevo fuera de lo que
docs/reparto-tareas.md asigna al enjambre.
```

## Por qué el prompt está escrito así

- **Empieza pidiéndole que lea, no que actúe.** Antigravity no tiene memoria de esta conversación — todo el contexto tiene que venir de los archivos.
- **`git status`/`git log` antes de invocar nada** es la misma regla que ya dejé en `CLAUDE.md` para mí — aplica igual de fuerte al enjambre, quizás más, porque son varios procesos que podrían solaparse entre sí.
- **No le doy la lista de "qué evitar" como una ocurrencia — se la doy explícita y nombrada**, porque la tentación natural de un agente eficiente es "ya que puedo, adelanto la siguiente pieza" — exactamente el fallo que ya identifiqué (`quickshell-surfaces` construyendo su propia versión provisional del cimiento si nadie se lo prohíbe con claridad).
- **Le pido que reporte cuando no queda nada que hacer**, en vez de dejar que decida solo qué inventar — así sabes exactamente cuándo Antigravity se quedó sin trabajo real y toca esperarme a mí.
