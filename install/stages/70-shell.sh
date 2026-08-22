#!/usr/bin/env bash
# 70-shell.sh — zsh como shell por defecto. Los paquetes (zsh,
# zsh-autosuggestions, zsh-completions, starship, zoxide, fzf) ya entraron
# en 10-core.sh; fast-syntax-highlighting y fzf-tab, en 20-aur.sh. Aquí solo
# se activa zsh y se verifica que los tres plugins se encuentran de verdad
# — el mismo chequeo defensivo que 20-plugins.zsh hace en cada arranque.

stage_main() {
  local zsh_path; zsh_path="$(command -v zsh)"
  if [[ -z "$zsh_path" ]]; then
    ui_fail "zsh no está instalado (¿falló la etapa 10?)"
    return 1
  fi

  if [[ "$SHELL" != "$zsh_path" ]]; then
    ui_spin "Cambiando el shell por defecto a zsh" -- sudo chsh -s "$zsh_path" "$USER" || \
      ui_warn "chsh falló — cámbialo a mano: chsh -s $zsh_path"
  else
    ui_skip "zsh ya es el shell por defecto"
  fi

  mkdir -p "$HOME/.local/state/zsh" "$HOME/.cache/zsh"

  local -a paths=(
    "/usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"
    "/usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh"
    "/usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh"
  )
  local missing=0
  local p
  for p in "${paths[@]}"; do
    if [[ -r "$p" ]]; then
      ui_ok "$(basename "$(dirname "$p")")"
    else
      ui_warn "no encontrado: $p"
      missing=$((missing + 1))
    fi
  done

  if (( missing > 0 )); then
    ui_info "$missing plugin(s) no aparecieron en la ruta esperada."
    ui_info "conf.d/20-plugins.zsh avisará de esto en cada terminal hasta que se resuelva — no es fatal."
  else
    ui_ok "los tres plugins de zsh están en su sitio"
  fi
  return 0
}
