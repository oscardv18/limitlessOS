#!/usr/bin/env bash
# 90-verify.sh — última etapa. Corre dotctl doctor y dice, sin rodeos,
# si es seguro reiniciar.

stage_main() {
  ui_info "ejecutando dotctl doctor…"
  local doctor="$REPO_DIR/bin/cmd/doctor"
  if [[ -x "$doctor" ]]; then
    "$doctor"
    local rc=$?
  else
    ui_warn "bin/cmd/doctor no existe o no es ejecutable"
    local rc=1
  fi

  ui_divider
  if (( rc == 0 )); then
    ui_banner "LISTO" "無下限 — puedes reiniciar cuando quieras"
    ui_info "al arrancar: greetd te recibe con tuigreet, en la paleta Limitless"
    ui_info "si algo falla: Ctrl+Alt+F2 → Hyprland -c ~/.limitless/dev/minimal.conf"
  else
    ui_warn "hay avisos sin resolver. Revísalos antes de reiniciar si puedes."
    ui_info "puedes reiniciar igual: los avisos no son bloqueantes, pero sí informativos."
  fi
  return 0   # la verificación en sí no debe hacer fallar al instalador
}
