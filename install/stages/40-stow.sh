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

  # ── vincular dotctl al PATH del sistema ──────────────────────────────
  # Sin esto, ni dotctl mismo es invocable por nombre suelto fuera de un
  # script que ya conozca $REPO_DIR — y la mitad de spec-keybinds.md
  # (todo lo que hl.dsp.exec_cmd("dotctl ...") dispara desde Hyprland,
  # lua/keybinds.lua) queda sin efecto, porque LightDM → uwsm → Hyprland
  # no pasa por ningún rc de shell (.zshenv nunca se ejecuta ahí).
  # /usr/local/bin sí está en el PATH por defecto de systemd para
  # cualquier proceso del sistema, sesión gráfica incluida — sin
  # depender de que nadie source nada.
  #
  # Solo dotctl necesita esto: todo lo demás en bin/cmd/ se invoca A
  # TRAVÉS de dotctl, nunca directo, y bin/discord-wayland ya se resuelve
  # por ruta absoluta desde su propio .desktop.
  local dotctl_src="$REPO_DIR/bin/dotctl"
  local dotctl_link="/usr/local/bin/dotctl"
  if [[ -L "$dotctl_link" && "$(readlink -f "$dotctl_link" 2>/dev/null)" == "$(readlink -f "$dotctl_src" 2>/dev/null)" ]]; then
    ui_skip "dotctl ya vinculado en $dotctl_link"
  elif [[ -e "$dotctl_link" ]]; then
    ui_warn "$dotctl_link ya existe y no es el enlace de este repo — no se sobrescribe a ciegas"
    ui_info "revísalo a mano; dotctl sigue funcionando invocado con la ruta completa ($dotctl_src)"
  else
    ui_spin "Vinculando dotctl a $dotctl_link" -- sudo ln -s "$dotctl_src" "$dotctl_link" || \
      ui_warn "no se pudo crear el enlace — dotctl sigue funcionando solo con la ruta completa"
  fi

  return 0
}
