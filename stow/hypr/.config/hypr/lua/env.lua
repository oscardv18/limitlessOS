-- lua/env.lua — variables de entorno + el traspaso de sesión que necesita
-- el portal de captura de pantalla (OBS, Discord). hl.env() verificado
-- verbatim en example/hyprland.lua del repositorio de Hyprland.

hl.env("XCURSOR_SIZE", "24")
hl.env("HYPRCURSOR_SIZE", "24")
hl.env("XDG_CURRENT_DESKTOP", "Hyprland")
hl.env("XDG_SESSION_TYPE", "wayland")
hl.env("XDG_SESSION_DESKTOP", "Hyprland")

-- necesario para que xdg-desktop-portal-hyprland vea las variables
-- correctas — sin esto OBS y Discord no encuentran ninguna fuente de
-- pantalla que compartir (verificado, docs/spec-keybinds.md §4c)
hl.on("hyprland.start", function()
  hl.exec_cmd("dbus-update-activation-environment --systemd WAYLAND_DISPLAY XDG_CURRENT_DESKTOP")
  hl.exec_cmd("systemctl --user import-environment DISPLAY WAYLAND_DISPLAY")
end)
