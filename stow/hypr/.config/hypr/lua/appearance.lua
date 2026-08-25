-- lua/appearance.lua — el cristal. La traducción CSS→Hyprland ya
-- documentada en docs/plan.md §3.6, con las claves de decoration.blur
-- verificadas verbatim contra example/hyprland.lua (enabled/size/passes/
-- vibrancy — NO existe "brightness" en el ejemplo oficial, así que se
-- retira esa clave que plan.md sugería sin haberla verificado todavía;
-- el efecto de brillo se deja al vibrancy + los propios tokens de
-- theme.toml, no a una clave que no está confirmada).

hl.config({
  general = {
    gaps_in  = 4,
    gaps_out = 8,
    border_size = 2,

    -- 蒼→茈: el borde activo degrada del acento de la técnica al
    -- morado — mismo lenguaje visual que el aro de dispersión cromática
    -- del material de cristal (themes/hud-void/theme.toml)
    col = {
      active_border   = { colors = { "rgba(3b9effee)", "rgba(a970ffee)" }, angle = 45 },
      inactive_border = "rgba(1c2a40aa)",
    },

    resize_on_border = true,
    allow_tearing = false,
    layout = "master",  -- por defecto; cada workspace lo sobreescribe (lua/workspaces.lua)
  },

  decoration = {
    rounding = 12,
    rounding_power = 2,

    active_opacity   = 1.0,
    inactive_opacity = 0.96,

    shadow = {
      enabled      = true,
      range        = 22,
      render_power = 3,
      color        = 0xaa000000,
    },

    -- vibrancy es el parámetro que separa "borroso" de "vidrio" — el
    -- equivalente directo del saturate(190%) que ya usa el mockup y el
    -- tema de LightDM (plan.md §3.6). passes 3 / size moderado rinde
    -- mejor que passes bajo con size alto.
    blur = {
      enabled  = true,
      size     = 6,
      passes   = 3,
      vibrancy = 0.42,
    },
  },

  animations = {
    enabled = true,
  },
})

-- curvas y animaciones — mismo criterio de tiempos que ya se usa en
-- todo el sistema (150–280ms), no las 10 curvas del ejemplo oficial
hl.curve("limitlessEase", { type = "bezier", points = { { 0.16, 0.84 }, { 0.36, 1 } } })

hl.animation({ leaf = "global",  enabled = true, speed = 6,   bezier = "limitlessEase" })
hl.animation({ leaf = "border",  enabled = true, speed = 4,   bezier = "limitlessEase" })
hl.animation({ leaf = "windows", enabled = true, speed = 3.5, bezier = "limitlessEase" })
hl.animation({ leaf = "fade",    enabled = true, speed = 2.8, bezier = "limitlessEase" })
hl.animation({ leaf = "workspaces", enabled = true, speed = 3, bezier = "limitlessEase", style = "fade" })

------------------------------------------------------------------------
-- Reglas de capa — el cristal de verdad en las superficies de QuickShell.
--
-- CONFIRMADO: "blur" e "ignorealpha"/"ignore_alpha" son propiedades
-- válidas de layerrule, accesibles desde hl.layer_rule() (verificado
-- contra un ejemplo real de configuración de QuickShell+Hyprland, no
-- inventado). SIN VERIFICAR AL 100%: el nombre exacto de la clave Lua
-- para el segundo caso — se ha visto "ignore_alpha" y "ignorealpha" en
-- fuentes distintas. Se deja "ignore_alpha" (snake_case, coherente con
-- el resto de claves confirmadas del proyecto: rounding_power,
-- render_power). Si al desplegar Hyprland rechaza esta clave, es el
-- primer punto a revisar — no un fallo silencioso: Hyprland avisa de
-- claves de config no reconocidas.
------------------------------------------------------------------------
hl.layer_rule({
  name  = "quickshell-glass",
  match = { namespace = "^(quickshell.*)$" },
  blur         = true,
  ignore_alpha = 0.3,   -- sin esto, la propia superficie se difumina a sí misma
})
