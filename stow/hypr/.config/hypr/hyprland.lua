-- hyprland.lua — entrada. Sin lógica propia, igual que dotctl o
-- stow/zsh/.config/zsh/.zshrc: solo carga módulos, en orden.
--
-- require() como forma de dividir la config es el patrón OFICIAL, no una
-- convención inventada aquí — el propio ejemplo de Hyprland lo dice en su
-- cabecera: "You can (and should!!) split this configuration into
-- multiple files... require them like this: require('myColors')"
-- (verificado contra example/hyprland.lua del repositorio, no de memoria).
--
-- Orden: entorno antes que apariencia (algunas variables de blur dependen
-- del compositor ya arrancado), layouts antes que workspaces (los
-- workspaces referencian layouts por nombre), reglas antes que binds
-- (un bind puede apuntar a una regla ya declarada), exec al final
-- (lanza QuickShell y awww, que esperan que todo lo anterior ya exista).

require("lua.env")
require("lua.monitors")
require("lua.input")
require("lua.appearance")
require("lua.layouts")
require("lua.workspaces")
require("lua.windowrules")
require("lua.keybinds")
require("lua.plugins")
require("lua.exec")
