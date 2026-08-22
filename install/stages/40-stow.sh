#!/usr/bin/env bash
# 40-stow.sh — enlaza cada paquete de stow/ a $HOME.
# Los conflictos con archivos ya existentes se avisan, no se pisan a ciegas:
# perder una config que ya tenías por un enlace silencioso es exactamente el
# tipo de "acción irreversible sin avisar" que este proyecto evita en todo.

stage_main() {
  has_cmd stow || { ui_spin "Instalando GNU Stow" -- sudo pacman -S --needed --noconfirm stow || return 1; }

  local stow_dir="$REPO_DIR/stow"
  [[ -d "$stow_dir" ]] || { ui_fail "no existe $stow_dir"; return 1; }

  local -a pkgs=()
  local d
  for d in "$stow_dir"/*/; do
    [[ -d "$d" ]] && pkgs+=("$(basename "$d")")
  done
  (( ${#pkgs[@]} == 0 )) && { ui_warn "stow/ está vacío todavía"; return 0; }

  ui_info "paquetes: ${pkgs[*]}"

  local -a conflicts=()
  for p in "${pkgs[@]}"; do
    local sim
    sim="$(stow -n -v -d "$stow_dir" -t "$HOME" "$p" 2>&1 | grep -i 'existing target' || true)"
    [[ -n "$sim" ]] && conflicts+=("$p")
  done

  if (( ${#conflicts[@]} > 0 )); then
    ui_warn "conflictos detectados en: ${conflicts[*]}"
    ui_info "stow no sobrescribe archivos existentes. Revísalos a mano o hazles backup, luego reintenta esta etapa."
    ui_confirm "¿Continuar solo con los paquetes sin conflicto?" || return 1
  fi

  for p in "${pkgs[@]}"; do
    [[ " ${conflicts[*]} " == *" $p "* ]] && { ui_skip "$p (conflicto)"; continue; }
    if ui_spin "stow: $p" -- stow -d "$stow_dir" -t "$HOME" "$p"; then :; fi
  done

  ui_ok "dotfiles enlazados"
  return 0
}
