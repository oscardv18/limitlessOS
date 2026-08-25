-- lua/workspaces.lua — los workspaces semánticos de docs/spec-layouts.md
-- §1. hl.workspace_rule({workspace=, layout=, ...}) confirmado (campo
-- "layout" verificado, no solo layout_opts).
--
-- grid y focus no se asignan de forma fija a un workspace: se alcanzan
-- ciclando con SUPER+[ / SUPER+] sobre cualquiera (spec-keybinds.md §3.1)
-- — por eso solo los cuatro con propósito fijo llevan workspace_rule.

hl.workspace_rule({ workspace = "1", layout = "master",  persistent = true })  -- code:  editor + terminal + logs
hl.workspace_rule({ workspace = "2", layout = "scrolling", persistent = true })  -- term:  muchas terminales, cinta horizontal
hl.workspace_rule({ workspace = "3", layout = "dwindle", persistent = true })  -- web:   navegador + docs, comparar
hl.workspace_rule({ workspace = "4", layout = "master",  persistent = true,
  layout_opts = { orientation = "top" } })                                     -- comms: master arriba, resto abajo
