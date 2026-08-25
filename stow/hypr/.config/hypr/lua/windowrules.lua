-- lua/windowrules.lua — "cristal donde adorna, opacidad donde se lee"
-- (docs/spec-layouts.md §5, docs/plan.md §3.6). hl.window_rule() con
-- match={class=...} confirmado verbatim en el ejemplo oficial.
--
-- "opaque" y "no_blur" siguen el mismo patrón snake_case ya confirmado
-- en dos propiedades independientes del propio ejemplo oficial
-- (no_focus en window_rule, no_anim en layer_rule) — no son una
-- suposición aislada, es el mismo estilo de nombrado ya verificado dos
-- veces. Aun así: primer punto a revisar si Hyprland avisa de una clave
-- no reconocida al desplegar.

-- navegador y editores: nunca cristal, el texto denso lo necesita opaco
hl.window_rule({
  name  = "opaque-browser",
  match = { class = "^(firefox|chromium|brave-browser|Google-chrome)$" },
  opaque   = true,
  no_blur  = true,
})

hl.window_rule({
  name  = "opaque-editors",
  match = { class = "^(code|Code|jetbrains-.*)$" },
  opaque   = true,
  no_blur  = true,
})

-- arreglo de arrastre de XWayland, tal cual el ejemplo oficial —
-- no hay razón para reescribirlo distinto
hl.window_rule({
  name  = "fix-xwayland-drags",
  match = {
    class      = "^$",
    title      = "^$",
    xwayland   = true,
    float      = true,
    fullscreen = false,
    pin        = false,
  },
  no_focus = true,
})

-- ignorar solicitudes de maximizar — igual que el ejemplo oficial,
-- coherente con "el layout decide el tamaño, no la app"
hl.window_rule({
  name  = "suppress-maximize-events",
  match = { class = ".*" },
  suppress_event = "maximize",
})
