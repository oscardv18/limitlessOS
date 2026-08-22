#!/usr/bin/env bash
# 50-theme.sh — matugen + theme.toml → plantillas (plan.md §5).
#
# Estado real del proyecto: el theme.toml y las plantillas de matugen
# TODAVÍA NO EXISTEN (spec-colorscheme.md §6 lo deja pendiente; hoy la
# paleta vive escrita a mano en colors/limitless.lua y starship.toml). Esta
# etapa instala la herramienta y aplica lo que haya, sin fingir que el
# pipeline completo está construido — cuando theme.toml exista, esta misma
# etapa lo recogerá sin cambios.

stage_main() {
  has_cmd matugen || {
    ui_spin "Instalando matugen" -- paru -S --needed --noconfirm matugen-bin || {
      ui_warn "matugen no se pudo instalar — se omite el theming automático"
      return 0
    }
  }

  local theme_toml="$REPO_DIR/themes/hud-void/theme.toml"
  if [[ -f "$theme_toml" ]]; then
    ui_spin "Aplicando tema desde theme.toml" -- matugen --config "$REPO_DIR/themes/matugen.toml" || \
      ui_warn "matugen falló — revisa themes/matugen.toml"
    ui_ok "tema aplicado"
  else
    ui_warn "theme.toml aún no existe (ver spec-colorscheme.md §6) — se omite"
    ui_info "mientras tanto, Neovim y Starship ya llevan la paleta escrita a mano"
  fi
  return 0
}
