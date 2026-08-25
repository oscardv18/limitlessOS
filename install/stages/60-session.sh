#!/usr/bin/env bash
# 60-session.sh — LightDM + tema propio + sesiones Hyprland/XFCE + paleta
# del VT + tema de GRUB (system/lightdm/, system/vconsole/README.md,
# system/grub/theme/). Sustituye a greetd+tuigreet: LightDM es más maduro,
# y el tema aquí es HTML/CSS/JS real con cristal de verdad — ver
# LIMITLESS-OS.md §2. Todo lo que toca /etc/default/grub vive en esta
# etapa, para que un solo `grub-mkconfig` al final aplique la paleta del
# VT y el tema a la vez, no dos pasadas.

_install_lightdm_session() {
  local src="$REPO_DIR/system/lightdm"
  local theme_dst="/usr/share/lightdm-webkit/themes/limitless"

  [[ -d "$src/theme" ]] || { echo "no existe $src/theme"; return 1; }

  if ! has_cmd lightdm; then
    sudo pacman -S --needed --noconfirm lightdm lightdm-webkit2-greeter xfce4 xfce4-terminal || return 1
  fi

  # el tema (HTML/CSS/JS) — se reemplaza entero en cada corrida, nunca se
  # mezcla con una versión vieja a medias
  sudo rm -rf "$theme_dst"
  sudo mkdir -p "$theme_dst"
  sudo cp "$src/theme/index.html" "$src/theme/style.css" "$src/theme/field.js" "$src/theme/script.js" "$theme_dst/" || return 1

  sudo install -Dm644 "$src/lightdm-webkit2-greeter.conf" /etc/lightdm/lightdm-webkit2-greeter.conf || return 1
  sudo install -Dm644 "$src/lightdm.conf.d/50-limitless.conf" /etc/lightdm/lightdm.conf.d/50-limitless.conf || return 1

  # la sesión de Hyprland envuelta en uwsm — uwsm no trae esto de fábrica,
  # hay que declararla (verificado: "uwsm start -- hyprland.desktop" es la
  # sintaxis real, contra hyprland.desktop que sí instala el paquete hyprland)
  sudo install -Dm644 "$src/hyprland-limitless.desktop" /usr/share/wayland-sessions/hyprland-limitless.desktop || return 1

  echo "tema y sesiones de LightDM instalados"
}
export -f _install_lightdm_session

_grub_has_vt_palette() {
  grep -q 'vt.default_red=' /etc/default/grub 2>/dev/null
}
export -f _grub_has_vt_palette

_install_grub_theme() {
  local src="$REPO_DIR/system/grub/theme"
  local dst="/boot/grub/themes/limitless"
  local font_src="/usr/share/fonts/TTF/JetBrainsMonoNerdFontMono-Regular.ttf"

  [[ -f "$src/theme.txt" ]] || { echo "no existe $src/theme.txt"; return 1; }
  [[ -f "$font_src" ]] || { echo "falta $font_src — ¿falló ttf-jetbrains-mono-nerd en la etapa 10?"; return 1; }
  command -v grub-mkfont >/dev/null 2>&1 || { echo "grub-mkfont no está disponible (paquete grub + freetype2)"; return 1; }

  sudo mkdir -p "$dst/pf2"
  sudo cp "$src/theme.txt" "$dst/theme.txt"

  # los .pf2 se generan aquí, nunca se versionan como binario en el repo
  sudo grub-mkfont -n "Limitless Mono" -s 16 -o "$dst/pf2/limitless-16.pf2" "$font_src" || return 1
  sudo grub-mkfont -n "Limitless Mono" -s 24 -o "$dst/pf2/limitless-24.pf2" "$font_src" || return 1
  # theme.txt referencia "Limitless Mono 16/24" por nombre; GRUB busca los
  # .pf2 en el mismo directorio del tema, así que basta con que existan ahí
  sudo cp "$dst/pf2/limitless-16.pf2" "$dst/limitless-16.pf2"
  sudo cp "$dst/pf2/limitless-24.pf2" "$dst/limitless-24.pf2"

  if grep -q '^GRUB_THEME=' /etc/default/grub 2>/dev/null; then
    sudo sed -i "s|^GRUB_THEME=.*|GRUB_THEME=\"$dst/theme.txt\"|" /etc/default/grub
  else
    echo "GRUB_THEME=\"$dst/theme.txt\"" | sudo tee -a /etc/default/grub >/dev/null
  fi
  grep -q '^GRUB_GFXMODE=' /etc/default/grub 2>/dev/null || \
    echo 'GRUB_GFXMODE=1920x1080,auto' | sudo tee -a /etc/default/grub >/dev/null
}
export -f _install_grub_theme

_apply_vt_palette() {
  local red green blue
  red='0x0e,0xff,0x4b,0xff,0x3b,0xa9,0x2e,0x7e,0x46,0xff,0x4b,0xff,0x8f,0xff,0x2e,0xea'
  green='0x15,0x4a,0xf0,0xd2,0x9e,0x70,0xe6,0x93,0x58,0x6b,0xf0,0x9d,0xe3,0x5e,0xe6,0xf2'
  blue='0x24,0x2e,0xa5,0x5e,0xff,0xff,0xd6,0xb0,0x7a,0x7f,0xa5,0x3d,0xff,0xcb,0xd6,0xff'
  local params="vt.default_red=$red vt.default_grn=$green vt.default_blu=$blue"

  sudo sed -i "s|^\(GRUB_CMDLINE_LINUX_DEFAULT=\"[^\"]*\)\"|\\1 ${params}\"|" /etc/default/grub
}
export -f _apply_vt_palette

stage_main() {
  ui_spin "Instalando LightDM + tema Limitless + sesión XFCE de emergencia" -- _install_lightdm_session || {
    ui_fail "no se pudo instalar la sesión — revisa system/lightdm/ manualmente"
    return 1
  }

  ui_spin "Habilitando LightDM" -- sudo systemctl enable lightdm || ui_warn "revisa el servicio a mano"

  # una sola copia de seguridad, antes de la primera de las dos ediciones
  # que siguen (paleta del VT + GRUB_THEME) — no una por cada una
  local grub_touched=0
  if [[ -f /etc/default/grub ]]; then
    sudo cp /etc/default/grub "/etc/default/grub.bak.$(date +%s)"
  fi

  if _grub_has_vt_palette; then
    ui_skip "paleta de la consola virtual (ya estaba en GRUB)"
  else
    if ui_spin "Remapeando la paleta ANSI del VT (system/vconsole/README.md)" -- _apply_vt_palette; then
      grub_touched=1
    else
      ui_warn "no se pudo tocar /etc/default/grub — hazlo a mano, ver system/vconsole/README.md"
    fi
  fi

  if [[ -f /etc/vconsole.conf ]] && ! grep -q '^FONT=ter-v18n' /etc/vconsole.conf 2>/dev/null; then
    ui_spin "Fuente de consola (Terminus)" -- bash -c '
      grep -q "^FONT=" /etc/vconsole.conf && sudo sed -i "s/^FONT=.*/FONT=ter-v18n/" /etc/vconsole.conf \
        || echo "FONT=ter-v18n" | sudo tee -a /etc/vconsole.conf >/dev/null'
  fi

  if ui_spin "Instalando el tema de GRUB (system/grub/theme/)" -- _install_grub_theme; then
    grub_touched=1
    ui_ok "tema de GRUB instalado"
  else
    ui_warn "el tema de GRUB no se pudo instalar — GRUB sigue con su aspecto por defecto"
  fi

  if (( grub_touched )); then
    ui_spin "grub-mkconfig (paleta del VT + tema, en una sola pasada)" -- \
      sudo grub-mkconfig -o /boot/grub/grub.cfg || \
      ui_warn "grub-mkconfig falló — revisa /etc/default/grub a mano"
  fi

  ui_ok "sesión configurada — hará falta reiniciar para ver LightDM, la paleta del VT y el tema de GRUB"
  return 0
}
