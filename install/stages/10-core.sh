#!/usr/bin/env bash
# 10-core.sh — paquetes de los repos oficiales.

stage_main() {
  local list="$REPO_DIR/packages/pacman.txt"
  [[ -f "$list" ]] || { ui_fail "no existe $list"; return 1; }

  local total
  total=$(grep -cve '^\s*#' -e '^\s*$' "$list")
  ui_info "instalando $total paquetes oficiales — esto tarda varios minutos"

  ui_spin "pacman -Syu (sincronizando repos)" -- sudo pacman -Syu --noconfirm || return 1
  ui_spin "Instalando paquetes de packages/pacman.txt" -- install_list pacman "$list" || return 1

  ui_ok "$total paquetes oficiales instalados"
  return 0
}
