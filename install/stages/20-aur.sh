#!/usr/bin/env bash
# 20-aur.sh — instala paru si falta, luego packages/aur.txt.
#
# A diferencia de 10-core.sh, un paquete que falla aquí NO detiene la etapa:
# son 20 compilaciones independientes, y una PKGBUILD rota no debe tirar
# abajo el resto. Se reporta un resumen al final.

_ensure_paru() {
  has_cmd paru && return 0
  ui_info "paru no está instalado — se compila una vez, ahora"
  local tmp; tmp="$(mktemp -d)"
  git clone --quiet https://aur.archlinux.org/paru-bin.git "$tmp/paru-bin" || return 1
  ( cd "$tmp/paru-bin" && makepkg -si --noconfirm ) || return 1
  rm -rf "$tmp"
}
export -f _ensure_paru

stage_main() {
  ui_spin "Instalando paru (AUR helper)" -- _ensure_paru || {
    ui_fail "no se pudo instalar paru — la etapa AUR se salta"
    return 1
  }
  ui_ok "paru disponible"

  local list="$REPO_DIR/packages/aur.txt"
  [[ -f "$list" ]] || { ui_warn "no existe $list, nada que instalar"; return 0; }

  local -a pkgs=() failed=()
  while IFS= read -r line; do
    line="${line%%#*}"; line="$(echo -n "$line" | xargs)"
    [[ -n "$line" ]] && pkgs+=("$line")
  done <"$list"

  ui_info "${#pkgs[@]} paquetes AUR — cada uno se compila por separado"
  local pkg
  for pkg in "${pkgs[@]}"; do
    if ui_spin "AUR: $pkg" -- paru -S --needed --noconfirm "$pkg"; then
      : # ok, ya reportado por ui_spin
    else
      failed+=("$pkg")
    fi
  done

  if (( ${#failed[@]} > 0 )); then
    ui_warn "no se pudieron instalar: ${failed[*]}"
    ui_info "reinténtalos a mano: paru -S ${failed[*]}"
  else
    ui_ok "todos los paquetes AUR instalados"
  fi
  return 0   # una compilación fallida no debe abortar el instalador entero
}
