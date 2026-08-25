-- lua/exec.lua — lo que arranca con la sesión. hl.on("hyprland.start", fn)
-- + hl.exec_cmd() confirmado verbatim en example/hyprland.lua.
--
-- El orden importa: awww-daemon antes de fijar el fondo (necesita el
-- daemon corriendo primero), QuickShell al final — cuando exista de
-- verdad (Fase 4), va a leer theme.toml vía matugen, así que más vale
-- que el resto de la sesión ya esté en pie.

hl.on("hyprland.start", function()
  -- awww es RESPALDO, no el fondo principal: desde la Fase 4 el fondo real
  -- es el campo de colisión de QuickShell (modules/Wallpaper.qml). Se deja
  -- porque si el shell no arranca, un escritorio con imagen se ve
  -- "arrancando"; uno negro se ve "roto". QuickShell pinta encima.
  --
  -- Es `awww`, NO `swww`: el proyecto se renombró y los binarios con él
  -- (awww / awww-daemon). El nombre viejo aquí habría fallado en silencio
  -- — y como QuickShell pinta encima, ni se habría notado hasta el día
  -- que el shell no arrancara, que es justo cuando este respaldo importa.
  hl.exec_cmd("awww-daemon")
  hl.exec_cmd("awww img ~/.config/limitless/wallpaper.png --transition-type fade")

  hl.exec_cmd("qs -c limitless")

  -- Puente herdr → barra del HUD (LIMITLESS-OS.md §4.1). Va DESPUÉS de
  -- qs: publica por IPC, así que necesita que el shell esté levantado
  -- para que el primer sondeo encuentre a quién hablarle. Si herdr no
  -- está instalado, el puente se queda publicando ceros — inofensivo.
  hl.exec_cmd("dotctl herdr-bridge watch")

  -- Agente de autenticación: sin él, nada que pida root gráficamente
  -- funciona (LIMITLESS-OS.md §3.1). Estaba en la tabla de paquetes
  -- desde el principio pero no se lanzaba en ningún sitio.
  hl.exec_cmd("systemctl --user start hyprpolkitagent")

  -- Historial de portapapeles — lo consume SUPER+V (spec-keybinds.md).
  hl.exec_cmd("wl-paste --watch cliphist store")

  -- Degradación por batería (Fase 6): aplica el perfil correcto al
  -- arrancar y reacciona al enchufar/desenchufar. En sobremesa detecta
  -- que no hay batería y se queda siempre en el perfil completo.
  hl.exec_cmd("dotctl power-profile watch")
end)
