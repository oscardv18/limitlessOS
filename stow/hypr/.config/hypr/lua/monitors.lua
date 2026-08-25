-- lua/monitors.lua — hl.monitor() verificado verbatim en el ejemplo
-- oficial. Sin datos reales de tu hardware todavía (docs/plan-fase1-
-- cimientos.md §5), así que un único monitor "el que sea, resolución
-- preferida, posición automática" — el mismo criterio que dev/minimal.conf
-- usa en hyprlang. Se ajusta en el despliegue con tus salidas reales.

hl.monitor({
  output   = "",
  mode     = "preferred",
  position = "auto",
  scale    = "auto",
})

-- Cuando tengas la configuración real, esto se reemplaza por una entrada
-- por salida física, más una para la externa/proyector que dispara
-- XF86Display (docs/spec-keybinds.md §4b):
--
-- hl.monitor({ output = "eDP-1", mode = "1920x1200@60", position = "0x0", scale = 1.25 })
-- hl.monitor({ output = "HDMI-A-1", mode = "preferred", position = "1920x0", scale = 1.0 })
