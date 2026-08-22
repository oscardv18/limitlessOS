#!/usr/bin/env bash
# install/lib/ui.sh — capa visual del instalador, sobre `gum`.
#
# gum (charmbracelet/gum, paquete oficial de Arch) es lo que convierte una
# secuencia de `pacman -S` en algo que se siente como un instalador gráfico:
# acepta hex directo en --foreground/--border-foreground (vía lipgloss, con
# degradación automática si la terminal no soporta color real), así que la
# paleta es literalmente la de colors/limitless.lua. Ni un color inventado.
#
# Todas las funciones de aquí degradan con gracia a texto plano si `gum` no
# está disponible todavía (ver install.sh: gum se instala ANTES que nada,
# precisamente para que esta degradación nunca ocurra en la práctica).

# ── paleta (idéntica en las 14 plantillas del proyecto) ─────────────────────
C_VOID='#04060d'
C_SURFACE='#0e1524'
C_LINE='#1c2a40'
C_TEXT='#eaf2ff'
C_DIM='#7e93b0'
C_MUTE='#46587a'
C_LAPSE='#3b9eff'     # 蒼 azul   — progreso, info
C_HOLLOW='#a970ff'    # 茈 morado — títulos, prompts
C_REVERSAL='#ff4a2e'  # 赫 rojo   — errores
C_GREEN='#4bf0a5'     # éxito
C_AMBER='#ffd25e'     # avisos

HAS_GUM=0
command -v gum >/dev/null 2>&1 && HAS_GUM=1

# ── primitivas ───────────────────────────────────────────────────────────────
ui_banner() {
  local title="$1" subtitle="${2:-}"
  if (( HAS_GUM )); then
    if [[ -n "$subtitle" ]]; then
      gum style --border=rounded --border-foreground="$C_LINE" \
        --foreground="$C_LAPSE" --align=center --width=58 --padding="1 3" --bold \
        "⬡  ${title}" "" "$(gum style --foreground="$C_DIM" "$subtitle")"
    else
      gum style --border=rounded --border-foreground="$C_LINE" \
        --foreground="$C_LAPSE" --align=center --width=58 --padding="1 3" --bold \
        "⬡  ${title}"
    fi
  else
    printf '\n=== %s ===\n%s\n\n' "$title" "$subtitle"
  fi
}

ui_section() {
  local n="$1" total="$2" title="$3"
  if (( HAS_GUM )); then
    gum style --foreground="$C_HOLLOW" --bold "▸ [$n/$total] $title"
  else
    printf '\n[%s/%s] %s\n' "$n" "$total" "$title"
  fi
}

ui_ok()   { (( HAS_GUM )) && gum style --foreground="$C_GREEN"    "  ✓ $1" || echo "  OK  $1"; }
ui_fail() { (( HAS_GUM )) && gum style --foreground="$C_REVERSAL" "  ✗ $1" || echo "  ERR $1"; }
ui_warn() { (( HAS_GUM )) && gum style --foreground="$C_AMBER"    "  ⚠ $1" || echo "  ADVERTENCIA $1"; }
ui_info() { (( HAS_GUM )) && gum style --foreground="$C_DIM"      "  · $1" || echo "  · $1"; }
ui_skip() { (( HAS_GUM )) && gum style --foreground="$C_MUTE"     "  ○ $1 (ya hecho)" || echo "  -- $1 (ya hecho)"; }

# ui_confirm "pregunta" → 0 = sí, 1 = no
ui_confirm() {
  if (( HAS_GUM )); then
    gum confirm --affirmative="Sí" --negative="No" \
      --selected.background="$C_LAPSE" --selected.foreground="$C_VOID" \
      --prompt.foreground="$C_TEXT" "$1"
  else
    read -r -p "$1 [s/N] " _r; [[ "$_r" =~ ^[sSyY] ]]
  fi
}

# ui_choose_multi "encabezado" opt1 opt2 ... → líneas seleccionadas por stdout
ui_choose_multi() {
  local header="$1"; shift
  if (( HAS_GUM )); then
    gum choose --no-limit --header="$header" \
      --header.foreground="$C_HOLLOW" \
      --cursor.foreground="$C_LAPSE" --selected.foreground="$C_GREEN" \
      --cursor="❯ " --selected-prefix="◈ " --unselected-prefix="  " \
      "$@"
  else
    printf '%s\n' "$@"   # sin gum, todo entra por defecto
  fi
}

# Helper de _ui_spin: separado en función propia (en vez de un `bash -c`
# con "$@" anidado) porque intentar redirigir dentro de una única línea de
# `bash -c '"$@" >"$0" 2>&1'` es exactamente el tipo de una-línea-lista-para-
# fallar que este proyecto evita en todas partes. `export -f` la hace visible
# al subproceso que lanza `gum spin` sin pasar por una cadena evaluada.
_ui_spin_runner() { local out="$1"; shift; "$@" >"$out" 2>&1; }
export -f _ui_spin_runner

# ui_spin "título" -- comando args...
# Ejecuta con spinner; SIEMPRE registra la salida completa en el log
# (install/lib/common.sh), y si falla, la muestra — un instalador que traga
# errores en silencio es peor que uno feo que los enseña.
ui_spin() {
  local title="$1"; shift
  [[ "$1" == "--" ]] && shift
  local logfile; logfile="$(mktemp)"
  local rc=0

  if (( HAS_GUM )); then
    gum spin --spinner=dot --title="$title" \
      --spinner.foreground="$C_LAPSE" --title.foreground="$C_DIM" \
      -- bash -c '_ui_spin_runner "$@"' _ "$logfile" "$@" || rc=$?
  else
    echo "→ $title"
    _ui_spin_runner "$logfile" "$@" || rc=$?
  fi

  cat "$logfile" >>"${LIMITLESS_LOG:-/dev/null}" 2>/dev/null
  if (( rc == 0 )); then
    rm -f "$logfile"; return 0
  fi
  ui_fail "$title"
  if (( HAS_GUM )); then
    gum style --foreground="$C_REVERSAL" --border=rounded \
      --border-foreground="$C_REVERSAL" --padding="0 1" \
      "$(tail -n 12 "$logfile")"
  else
    tail -n 12 "$logfile"
  fi
  rm -f "$logfile"
  return "$rc"
}

ui_divider() {
  (( HAS_GUM )) && gum style --foreground="$C_LINE" "$(printf '─%.0s' $(seq 1 58))" \
    || printf -- '-%.0s' $(seq 1 58) && echo
}
