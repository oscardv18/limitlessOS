-- lua/input.lua — hl.config({input=...}) y hl.gesture() verificados
-- verbatim en el ejemplo oficial (example/hyprland.lua).

hl.config({
  input = {
    kb_layout  = "us",
    kb_variant = "",
    kb_model   = "",
    kb_options = "",
    kb_rules   = "",

    follow_mouse = 1,
    sensitivity  = 0,

    touchpad = {
      natural_scroll = true,
    },
  },
})

-- gesto de 3 dedos para cambiar de workspace — mismo patrón que el
-- ejemplo oficial, coherente con "teclado-first pero sin renunciar al
-- trackpad en el portátil"
hl.gesture({
  fingers   = 3,
  direction = "horizontal",
  action    = "workspace",
})
