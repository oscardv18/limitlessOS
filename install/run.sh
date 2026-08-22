#!/usr/bin/env bash
# install/run.sh — el instalador de verdad. install.sh en la raíz solo
# comprueba que `gum` exista antes de llegar aquí (LIMITLESS-OS.md §5.2).
#
# Etapas numeradas en install/stages/, cada una define `stage_main()` en su
# propio archivo y se descarta después (unset -f) para que un nombre de
# función no sobreviva de una etapa a la siguiente por accidente.

set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." &>/dev/null && pwd)"
export REPO_DIR
source "$REPO_DIR/install/lib/common.sh"
source "$REPO_DIR/install/lib/ui.sh"

require_not_root

# ── etapas, en orden ─────────────────────────────────────────────────────────
STAGES=(
  "00-preflight.sh|Red de seguridad"
  "10-core.sh|Paquetes oficiales"
  "20-aur.sh|Paquetes AUR"
  "30-services.sh|Servicios"
  "40-stow.sh|Dotfiles"
  "50-theme.sh|Tema"
  "60-session.sh|Sesión (greetd)"
  "70-shell.sh|Shell (zsh)"
  "80-tui.sh|Ecosistema TUI"
  "90-verify.sh|Verificación"
)

# ── argumentos: --from=NN salta etapas ya hechas antes de esa ───────────────
FROM=0
for arg in "$@"; do
  case "$arg" in
    --from=*) FROM="${arg#*=}"; stage_reset_from "$FROM" ;;
    --help|-h)
      echo "uso: install/run.sh [--from=NN]"
      echo "  --from=NN   reanuda desde la etapa NN, olvidando el progreso posterior"
      exit 0
      ;;
  esac
done

clear
ui_banner "L I M I T L E S S   O S" "CachyOS + Hyprland · $(date '+%Y-%m-%d %H:%M')"
echo
ui_info "repositorio: $REPO_DIR"
ui_info "log completo: $LIMITLESS_LOG"
echo

if ! ui_confirm "¿Instalar Limitless OS ahora? Todo queda registrado y es reanudable."; then
  ui_info "cancelado. Nada se ha tocado."
  exit 0
fi

sudo_keepalive_start
trap sudo_keepalive_stop EXIT

TOTAL=${#STAGES[@]}
N=0
FAILED_STAGES=()

for entry in "${STAGES[@]}"; do
  N=$((N + 1))
  file="${entry%%|*}"
  title="${entry#*|}"
  stage_id="${file%%-*}"

  if stage_done "$file"; then
    ui_section "$N" "$TOTAL" "$title"
    ui_skip "etapa ya completada"
    continue
  fi

  ui_section "$N" "$TOTAL" "$title"
  # shellcheck disable=SC1090
  source "$REPO_DIR/install/stages/$file"

  if stage_main; then
    stage_mark "$file"
  else
    ui_fail "la etapa «$title» falló"
    FAILED_STAGES+=("$title")
    if ! ui_confirm "¿Continuar con la siguiente etapa de todos modos?"; then
      break
    fi
  fi
  unset -f stage_main
  echo
done

echo
if (( ${#FAILED_STAGES[@]} == 0 )); then
  ui_banner "INSTALACIÓN COMPLETA" "蒼 + 赫 → 茈"
else
  ui_banner "INSTALACIÓN CON AVISOS" "fallaron: ${FAILED_STAGES[*]}"
  ui_info "reintenta la etapa exacta con: install.sh --from=NN (ver install/stages/)"
fi
ui_info "log completo en $LIMITLESS_LOG"
