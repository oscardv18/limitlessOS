#!/usr/bin/env bash
# install/lib/common.sh — estado, log y utilidades compartidas por las etapas.
# Idempotencia y reanudación (plan-automation.md §5 aplicado al instalador,
# no solo a las migraciones): cada etapa se marca al terminar, y --from=N
# permite reanudar sin repetir lo ya hecho.

set -uo pipefail

REPO_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")/../.." &>/dev/null && pwd)"
STATE_DIR="$HOME/.local/state/limitless"
STAGE_DIR="$STATE_DIR/stages"
export LIMITLESS_LOG="$STATE_DIR/install.log"

mkdir -p "$STAGE_DIR"
: >>"$LIMITLESS_LOG"

require_not_root() {
  if [[ "$EUID" -eq 0 ]]; then
    echo "No ejecutes esto como root. El instalador pide sudo cuando lo necesita." >&2
    exit 1
  fi
}

# mantiene viva la sesión de sudo durante etapas largas (compilación AUR),
# el mismo truco de omarchy-sudo-keepalive (plan-automation.md §1)
sudo_keepalive_start() {
  sudo -v
  ( while true; do sudo -n true; sleep 60; kill -0 "$$" 2>/dev/null || exit; done ) &
  SUDO_KEEPALIVE_PID=$!
}
sudo_keepalive_stop() {
  [[ -n "${SUDO_KEEPALIVE_PID:-}" ]] && kill "$SUDO_KEEPALIVE_PID" 2>/dev/null
}

stage_done() { [[ -f "$STAGE_DIR/$1" ]]; }
stage_mark() { touch "$STAGE_DIR/$1"; }
stage_reset_from() {
  # borra las marcas de la etapa N en adelante, para --from=N
  local from="$1"
  local n
  for f in "$STAGE_DIR"/*; do
    [[ -e "$f" ]] || continue
    n="${f##*/}"; n="${n%%-*}"
    [[ "$n" =~ ^[0-9]+$ ]] || continue
    (( 10#$n >= 10#$from )) && rm -f "$f"
  done
}

has_cmd() { command -v "$1" >/dev/null 2>&1; }

# instala una lista de paquetes desde packages/*.txt, ignorando comentarios
# y líneas vacías. Uso: install_list pacman packages/pacman.txt
install_list() {
  local mgr="$1" file="$2"
  local -a pkgs=()
  while IFS= read -r line; do
    line="${line%%#*}"
    line="$(echo -n "$line" | xargs)"
    [[ -n "$line" ]] && pkgs+=("$line")
  done <"$file"
  (( ${#pkgs[@]} == 0 )) && return 0

  if [[ "$mgr" == "pacman" ]]; then
    sudo pacman -S --needed --noconfirm "${pkgs[@]}"
  else
    paru -S --needed --noconfirm "${pkgs[@]}"
  fi
}
export -f install_list
