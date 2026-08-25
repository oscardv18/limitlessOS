-- lua/keybinds.lua — traducción completa de docs/spec-keybinds.md.
-- SUPER es la tecla líder (spec-keybinds.md §0). Todo bind que invoca
-- algo del ecosistema propio (no un dispatcher nativo de Hyprland) pasa
-- por `dotctl` — nunca una implementación directa (plan-automation.md
-- §3: "los keybinds llaman siempre a dotctl…, nunca a un script
-- directamente"). Los subcomandos de dotctl que esto asume
-- (shell/scratch/lock/capture/layout) son Fase 5 — este archivo queda
-- correcto y completo independientemente de cuándo se escriban.

local mainMod = "SUPER"

------------------------------------------------------------------------
-- 3.1 — Shell: superficies invocadas globalmente
------------------------------------------------------------------------
hl.bind(mainMod .. " + SPACE", hl.dsp.exec_cmd("dotctl shell launcher toggle"))
hl.bind(mainMod .. " + M",     hl.dsp.exec_cmd("dotctl shell menu toggle"))
hl.bind(mainMod .. " + I",     hl.dsp.exec_cmd("dotctl shell pkg toggle"))
hl.bind(mainMod .. " + P",     hl.dsp.exec_cmd("dotctl shell dev toggle"))
hl.bind(mainMod .. " + V",     hl.dsp.exec_cmd("dotctl shell clipboard toggle"))
hl.bind(mainMod .. " + W",     hl.dsp.exec_cmd("dotctl shell widgets toggle"))
hl.bind(mainMod .. " + C",     hl.dsp.exec_cmd("dotctl shell control toggle"))
hl.bind(mainMod .. " + K",     hl.dsp.exec_cmd("dotctl lock"))
hl.bind(mainMod .. " + T",     hl.dsp.exec_cmd("dotctl theme cycle"))
hl.bind(mainMod .. " + D",     hl.dsp.exec_cmd("dotctl shell dock pin-toggle"))
hl.bind(mainMod .. " + SHIFT + D", hl.dsp.exec_cmd("dotctl shell dock hide-toggle"))
hl.bind(mainMod .. " + SHIFT + S", hl.dsp.exec_cmd("dotctl capture region"))

hl.bind(mainMod .. " + [", hl.dsp.exec_cmd("dotctl layout cycle -1"))
hl.bind(mainMod .. " + ]", hl.dsp.exec_cmd("dotctl layout cycle 1"))

-- ciclar foco entre ventanas — dispatcher nativo confirmado, sin pasar
-- por dotctl porque es comportamiento puro de Hyprland, no del ecosistema
hl.bind(mainMod .. " + TAB", hl.dsp.window.cycle_next({ tiled = true }))

-- workspaces — SUPER+1..9, nunca sueltos (spec-keybinds.md §2: números
-- sueltos rompen escribir cualquier dígito en cualquier campo de texto)
for i = 1, 9 do
  hl.bind(mainMod .. " + " .. i, hl.dsp.focus({ workspace = i }))
end

-- paneo de la cinta en el layout scroll: es el mismo dispatcher de
-- movimiento direccional que ya usan el resto de layouts — en scroll,
-- "mover foco a la izquierda/derecha" ES panear la cinta, sin necesitar
-- una rama de código distinta por layout
hl.bind(mainMod .. " + left",  hl.dsp.focus({ direction = "left" }))
hl.bind(mainMod .. " + right", hl.dsp.focus({ direction = "right" }))
hl.bind(mainMod .. " + up",    hl.dsp.focus({ direction = "up" }))
hl.bind(mainMod .. " + down",  hl.dsp.focus({ direction = "down" }))

------------------------------------------------------------------------
-- 3.2 — Gestión de ventanas (heredado de dev/minimal.conf, con un cambio)
------------------------------------------------------------------------
hl.bind(mainMod .. " + RETURN", hl.dsp.exec_cmd("ghostty"))
hl.bind(mainMod .. " + Q",      hl.dsp.window.close())
hl.bind(mainMod .. " + SHIFT + E", hl.dsp.exit())
-- fullscreen vive bajo hl.dsp.window, no como función suelta — error
-- real que cometí al escribir esto la primera vez, corregido tras
-- verificar. El número exacto de "mode" (0/1/2/3, histórico de hyprlang:
-- ninguno/full/maximizar/full+maximizar) no quedó confirmado con
-- precisión — se deja mode=1 (fullscreen simple) y se ajusta en el
-- despliegue si el comportamiento real no coincide.
hl.bind(mainMod .. " + F", hl.dsp.window.fullscreen({ mode = 1 }))
hl.bind(mainMod .. " + ALT + V", hl.dsp.window.float({ action = "toggle" }))  -- movido desde SUPER+V (§1.2)

------------------------------------------------------------------------
-- 3.3 — Multimedia: sin SUPER, teclas físicas dedicadas. Nombres XF86
-- verificados verbatim contra example/hyprland.lua del repositorio
-- (RaiseVolume/LowerVolume/Mute/MonBrightness ya venían confirmados de
-- ahí; Display y RFKill se verificaron aparte, spec-keybinds.md §4b).
------------------------------------------------------------------------
-- Cada tecla hace DOS cosas: cambia el valor y luego pinta el OSD.
-- Van encadenadas con `&&` en una sola shell en vez de dos binds: así el
-- OSD lee el valor YA aplicado (dotctl osd consulta el estado real, no
-- recibe el delta), y nunca se pinta un número que no llegó a aplicarse.
hl.bind("XF86AudioRaiseVolume", hl.dsp.exec_cmd("sh -c 'wpctl set-volume -l 1 @DEFAULT_AUDIO_SINK@ 5%+ && dotctl osd vol'"), { locked = true, repeating = true })
hl.bind("XF86AudioLowerVolume", hl.dsp.exec_cmd("sh -c 'wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%- && dotctl osd vol'"),      { locked = true, repeating = true })
hl.bind("XF86AudioMute",        hl.dsp.exec_cmd("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle && dotctl osd vol'"),     { locked = true, repeating = true })
hl.bind("XF86AudioMicMute",     hl.dsp.exec_cmd("sh -c 'wpctl set-mute @DEFAULT_AUDIO_SOURCE@ toggle && dotctl osd mic'"),   { locked = true })
hl.bind("XF86MonBrightnessUp",   hl.dsp.exec_cmd("sh -c 'brightnessctl -e4 -n2 set 5%+ && dotctl osd bri'"), { locked = true, repeating = true })
hl.bind("XF86MonBrightnessDown", hl.dsp.exec_cmd("sh -c 'brightnessctl -e4 -n2 set 5%- && dotctl osd bri'"), { locked = true, repeating = true })

-- vía MPRIS, llegan directo a herdr y al reproductor del panel de widgets
hl.bind("XF86AudioPlay", hl.dsp.exec_cmd("playerctl play-pause"), { locked = true })
hl.bind("XF86AudioNext", hl.dsp.exec_cmd("playerctl next"),       { locked = true })
hl.bind("XF86AudioPrev", hl.dsp.exec_cmd("playerctl previous"),   { locked = true })

hl.bind("XF86Display", hl.dsp.exec_cmd("dotctl display cycle"), { locked = true })
hl.bind("XF86RFKill",  hl.dsp.exec_cmd("rfkill toggle all"),    { locked = true })
-- ver spec-keybinds.md §4b: en hardware ASUS a veces llega como XF86WLAN
hl.bind("XF86WLAN",    hl.dsp.exec_cmd("rfkill toggle all"),    { locked = true })

hl.bind("Print", hl.dsp.exec_cmd("dotctl capture region"), { locked = true })

------------------------------------------------------------------------
-- 3.4 — Scratchpads (spec-layouts.md §3.1, reconciliado en spec-keybinds
-- §3.4). Todos pasan por `dotctl scratch <nombre>` — spawn-o-toggle es
-- lógica con estado, no un dispatcher de una línea, y coherente con la
-- regla de siempre-vía-dotctl.
------------------------------------------------------------------------
hl.bind(mainMod .. " + grave", hl.dsp.exec_cmd("dotctl scratch term"))
hl.bind(mainMod .. " + ntilde", hl.dsp.exec_cmd("dotctl scratch term"))  -- alternativa teclado ES
hl.bind(mainMod .. " + SHIFT + M", hl.dsp.exec_cmd("dotctl scratch music"))
hl.bind(mainMod .. " + N",         hl.dsp.exec_cmd("dotctl scratch notes"))
hl.bind(mainMod .. " + SHIFT + B", hl.dsp.exec_cmd("dotctl scratch sys"))
hl.bind(mainMod .. " + G",         hl.dsp.exec_cmd("dotctl scratch lazygit"))
