-- lua/layouts.lua — docs/spec-layouts.md §1-2. Cinco layouts: master,
-- dwindle, scroll nativos; grid custom vía hl.layout.register (patrón
-- confirmado verbatim contra example/layouts/grid.lua y columns.lua del
-- repositorio); focus queda pendiente — ver nota al final, no inventado.

hl.config({
  master = {
    new_status     = "master",
    orientation    = "left",
  },
  dwindle = {
    preserve_split = true,  -- evita el "salto" impredecible de BSP — ya en el ejemplo oficial
  },
  scrolling = {
    fullscreen_on_one_column = true,
  },
})

------------------------------------------------------------------------
-- grid — rejilla uniforme n×n, para "vigilar" (spec-layouts.md §2.2).
-- Adaptado casi literal de example/layouts/grid.lua del propio
-- repositorio de Hyprland — no hubo que inventar nada, el layout que
-- ya diseñamos coincide con el ejemplo oficial.
------------------------------------------------------------------------
hl.layout.register("grid", {
  recalculate = function(ctx)
    local n = #ctx.targets
    if n == 0 then return end

    local cols = math.ceil(math.sqrt(n))
    for i, target in ipairs(ctx.targets) do
      target:place(ctx:grid_cell(i, cols))
    end
  end,
})

------------------------------------------------------------------------
-- focus — PENDIENTE. Diseño (spec-layouts.md §2): una ventana centrada,
-- gaps grandes, el resto oculto.
--
-- Lo que impide escribirlo ya: para dar espacio a la ventana enfocada y
-- ocultar el resto, el layout necesita saber CUÁL target está enfocado.
-- Confirmado que existe target.window (acceso a la ventana subyacente,
-- verificado contra la documentación de la API), pero NINGUNA fuente
-- consultada confirma el nombre exacto de una propiedad de foco sobre
-- ese objeto window (¿target.window.focused? ¿una función distinta?).
--
-- No lo adivino. Cuando haya Hyprland real corriendo, se verifica con
-- una prueba directa (imprimir los campos de target.window desde la
-- función recalculate, algo que ninguna documentación puede sustituir)
-- y se completa este bloque. Hasta entonces, "focus" no está en la
-- lista de layouts disponibles — mejor no ofrecerlo que ofrecer uno roto.
