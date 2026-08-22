#!/usr/bin/env bash
# 80-tui.sh — convierte las TUI del ecosistema en ciudadanas de primera
# (LIMITLESS-OS.md §4.2): cada una recibe un .desktop generado, para que el
# launcher las encuentre como cualquier app gráfica. Esto es exactamente lo
# que `dotctl tui-install` hará bajo demanda más adelante (§7); aquí se
# aplica una vez, a las que ya sabemos que quieres.
#
# Formato de la tabla: comando | Nombre visible | glifo (para cuando el
# launcher del mockup lea Icon= — de momento se guarda como comentario,
# porque QuickShell todavía no existe para consumirlo).

stage_main() {
  local apps_dir="$HOME/.local/share/applications"
  mkdir -p "$apps_dir"

  local -a TUIS=(
    "lazygit|Lazygit|⑂"
    "lazydocker|Lazydocker|⌬"
    "btop|Sistema (btop)|◫"
    "nvtop|GPU (nvtop)|◧"
    "yazi|Archivos (yazi)|▣"
    "impala|Wi-Fi (impala)|◈"
    "bluetui|Bluetooth (bluetui)|✦"
    "wiremix|Audio (wiremix)|◨"
    "systemctl-tui|Servicios|⚙"
    "lnav|Registros (lnav)|⌗"
  )

  local entry cmd name glyph n_ok=0 n_skip=0
  for entry in "${TUIS[@]}"; do
    IFS='|' read -r cmd name glyph <<<"$entry"
    if ! has_cmd "$cmd"; then
      n_skip=$((n_skip + 1))
      continue
    fi
    local desktop_file="$apps_dir/limitless-${cmd}.desktop"
    cat >"$desktop_file" <<EOF
[Desktop Entry]
Type=Application
Name=${name}
Comment=Herramienta del ecosistema Limitless (${glyph})
Exec=ghostty -e ${cmd}
Terminal=false
Categories=System;ConsoleOnly;
X-Limitless-Glyph=${glyph}
EOF
    n_ok=$((n_ok + 1))
    ui_ok "$name"
  done

  ui_info "$n_ok entradas generadas, $n_skip omitidas (herramienta no instalada)"
  update-desktop-database "$apps_dir" 2>/dev/null || true
  return 0
}
