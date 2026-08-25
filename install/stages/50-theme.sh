#!/usr/bin/env bash
# 50-theme.sh — matugen + theme.toml → plantillas (plan.md §5).
#
# theme.toml NO es la entrada nativa de matugen (matugen deriva un
# esquema Material You de una imagen o un color semilla; este proyecto
# quiere sus hex exactos, no una derivación algorítmica). El puente real
# es bin/cmd/theme-export: vuelca theme.toml a
# themes/matugen.toml ([config.custom_colors], blend=false por color) y
# genera ~/.config/hypr/hyprlock-colors.conf aparte (formato nativo de
# Hyprland, no lo entiende el lenguaje de plantillas de matugen). Las
# plantillas reales (Ghostty, btop, lazygit...) solo referencian
# {{custom.NOMBRE.hex}} — el esquema derivado del color semilla se
# ignora por completo, por eso la semilla de abajo es arbitraria.

stage_main() {
  has_cmd matugen || {
    ui_spin "Instalando matugen" -- paru -S --needed --noconfirm matugen-bin || {
      ui_warn "matugen no se pudo instalar — se omite el theming automático"
      return 0
    }
  }

  local theme_toml="$REPO_DIR/themes/hud-void/theme.toml"
  if [[ -f "$theme_toml" ]]; then
    ui_spin "Generando themes/matugen.toml desde theme.toml" -- "$REPO_DIR/bin/cmd/theme-export" || {
      ui_fail "bin/cmd/theme-export falló — revisa themes/hud-void/theme.toml"
      return 1
    }
    if compgen -G "$REPO_DIR/themes/_templates/*.tmpl" >/dev/null 2>&1; then
      ui_spin "Aplicando tema con matugen" -- matugen --config "$REPO_DIR/themes/matugen.toml" color hex "#04060d" || \
        ui_warn "matugen falló — revisa themes/matugen.toml"
      ui_ok "tema aplicado"

      # bat (y delta, que comparte su caché de syntect) NO leen los
      # .tmTheme sueltos — usan una caché binaria. Sin este paso el tema
      # existe en disco y las dos herramientas lo ignoran en silencio.
      if has_cmd bat; then
        ui_spin "Reconstruyendo la caché de temas de bat" -- bat cache --build || \
          ui_warn "bat cache --build falló — 'bat --list-themes' dirá si limitless está o no"
      fi
    else
      ui_info "themes/_templates/ aún no tiene plantillas — matugen.toml quedó listo, sin nada que compilar todavía"
    fi
  else
    ui_warn "theme.toml aún no existe (ver spec-colorscheme.md §6) — se omite"
    ui_info "mientras tanto, Neovim y Starship ya llevan la paleta escrita a mano"
  fi
  return 0
}
