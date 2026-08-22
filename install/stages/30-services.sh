#!/usr/bin/env bash
# 30-services.sh — habilita lo que la sesión necesita YA levantado.
# Va antes de 60-session.sh a propósito (LIMITLESS-OS.md §5.3): si el login
# arranca Hyprland sin pipewire ni polkit habilitados, entras a una sesión
# rota y sin GUI para arreglarla.

stage_main() {
  local -a services=(
    NetworkManager
    bluetooth
    seatd
  )
  local svc
  for svc in "${services[@]}"; do
    if systemctl is-enabled "$svc" >/dev/null 2>&1; then
      ui_skip "$svc"
    else
      ui_spin "Habilitando $svc" -- sudo systemctl enable --now "$svc" || ui_warn "$svc no se pudo habilitar"
    fi
  done

  # pipewire/wireplumber son servicios de USUARIO, no de sistema
  local -a user_services=(pipewire pipewire-pulse wireplumber)
  for svc in "${user_services[@]}"; do
    if systemctl --user is-enabled "$svc" >/dev/null 2>&1; then
      ui_skip "$svc (usuario)"
    else
      ui_spin "Habilitando $svc (usuario)" -- systemctl --user enable --now "$svc" || ui_warn "$svc no se pudo habilitar"
    fi
  done

  # el usuario actual necesita pertenecer a estos grupos
  local -a groups=(video seat)
  for g in "${groups[@]}"; do
    getent group "$g" >/dev/null 2>&1 || continue
    if id -nG "$USER" | grep -qw "$g"; then
      ui_skip "grupo $g"
    else
      ui_spin "Añadiendo a $USER al grupo $g" -- sudo usermod -aG "$g" "$USER" || true
    fi
  done
  ui_ok "servicios base activos"
  return 0
}
