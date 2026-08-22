-- limitless.lua — colorscheme de Neovim para los dotfiles Limitless
--
-- Base: One Dark Pro Darker, con los tonos llevados a la saturación del HUD
-- (+18 a +46 puntos de saturación) y el fondo cambiado al void azulado del
-- shell. Los tres colores de identidad (蒼 azul / 茈 morado / 赫 rojo) ocupan
-- los mismos roles sintácticos que en One Dark Pro, así que la memoria
-- muscular se conserva pero el editor pertenece a la misma interfaz.
--
-- Opciones (fijar ANTES de :colorscheme limitless):
--   vim.g.limitless_transparent = false  -- POR DEFECTO. nvim corre dentro de un
--     terminal de cristal, pero un editor con el fondo translúcido se lee peor:
--     el texto denso necesita fondo estable. Así que nvim pinta su propio void
--     (#04060d) — el mismo del fondo de pantalla, así que sigue perteneciendo a
--     la interfaz, pero es opaco y legible. Ponlo a true si quieres que un nvim
--     abierto de paso en un terminal suelto se funda con el cristal.
--   vim.g.limitless_italic_comments = true

local M = {}

------------------------------------------------------------------------------
-- Paleta. Contraste verificado sobre el fondo: todo lo legible ≥ 4.97:1 (AA).
------------------------------------------------------------------------------
local c = {
  -- superficies (compartidas con theme.toml del shell)
  bg        = "#04060d",  -- --void
  bg_dim    = "#02040a",  -- splits inactivos
  bg_alt    = "#080d18",  -- flotantes, sidebar, statusline
  bg_hl     = "#0e1524",  -- cursorline
  bg_sel    = "#16233c",  -- selección visual
  bg_float  = "#070c17",
  border    = "#1c2a40",

  -- texto
  fg        = "#eaf2ff",  -- 17.98:1
  fg_dim    = "#7e93b0",  --  6.45:1
  comment   = "#6b7f9e",  --  4.97:1  ← subido: ODP deja los comentarios a 3:1
  gutter    = "#46587a",
  ghost     = "#2a3a55",  -- inlay hints, whitespace

  -- sintaxis intensificada
  blue      = "#3b9eff",  -- 蒼 · funciones          7.25:1
  ice       = "#8fe3ff",  -- builtins, campos       14.08:1
  cyan      = "#2ee6d6",  -- operadores             12.93:1
  violet    = "#a970ff",  -- 茈 · palabras clave     6.22:1
  magenta   = "#ff5ecb",  -- macros, especiales      7.44:1
  red       = "#ff4a2e",  -- 赫 · errores            6.05:1
  coral     = "#ff6b7f",  -- variables, parámetros   7.39:1
  orange    = "#ff9d3d",  -- números, constantes     9.78:1
  amber     = "#ffd25e",  -- tipos, clases          14.11:1
  green     = "#4bf0a5",  -- cadenas                13.80:1

  -- estados
  warn      = "#ffd25e",
  info      = "#3b9eff",
  hint      = "#2ee6d6",
  ok        = "#4bf0a5",
  add       = "#1d5f42",
  change    = "#1d3f6b",
  delete    = "#5f1f18",
}
M.palette = c

------------------------------------------------------------------------------
local function setup()
  if vim.g.colors_name then vim.cmd.hi("clear") end
  vim.g.colors_name = "limitless"
  vim.o.termguicolors = true
  vim.o.background = "dark"

  local transparent = vim.g.limitless_transparent
  if transparent == nil then transparent = false end
  local italic = vim.g.limitless_italic_comments
  if italic == nil then italic = true end

  -- Regla del proyecto: cristal donde adorna, opacidad donde se lee.
  -- El editor se lee, así que por defecto pinta fondo. Coincide con el void
  -- del shell, de modo que la unidad visual se mantiene sin sacrificar
  -- legibilidad. En modo transparente deja pasar el cristal del terminal.
  local BG      = transparent and "NONE" or c.bg
  local BG_ALT  = transparent and "NONE" or c.bg_alt
  local BG_FLT  = c.bg_float

  local hl = function(group, spec) vim.api.nvim_set_hl(0, group, spec) end

  local groups = {
    ------------------------------------------------------------------ editor
    Normal          = { fg = c.fg, bg = BG },
    NormalNC        = { fg = c.fg_dim, bg = BG },
    NormalFloat     = { fg = c.fg, bg = BG_FLT },
    FloatBorder     = { fg = c.border, bg = BG_FLT },
    FloatTitle      = { fg = c.blue, bg = BG_FLT, bold = true },
    Cursor          = { fg = c.bg, bg = c.blue },
    lCursor         = { fg = c.bg, bg = c.violet },
    CursorLine      = { bg = c.bg_hl },
    CursorColumn    = { bg = c.bg_hl },
    ColorColumn     = { bg = c.bg_alt },
    LineNr          = { fg = c.gutter },
    CursorLineNr    = { fg = c.blue, bold = true },
    SignColumn      = { bg = BG },
    FoldColumn      = { fg = c.gutter, bg = BG },
    Folded          = { fg = c.fg_dim, bg = c.bg_alt },
    VertSplit       = { fg = c.border },
    WinSeparator    = { fg = c.border },
    Visual          = { bg = c.bg_sel },
    VisualNOS       = { bg = c.bg_sel },
    Search          = { fg = c.bg, bg = c.amber },
    IncSearch       = { fg = c.bg, bg = c.orange, bold = true },
    CurSearch       = { fg = c.bg, bg = c.ice, bold = true },
    Substitute      = { fg = c.bg, bg = c.coral },
    MatchParen      = { fg = c.ice, bold = true, underline = true },
    NonText         = { fg = c.ghost },
    Whitespace      = { fg = c.ghost },
    SpecialKey      = { fg = c.ghost },
    EndOfBuffer     = { fg = BG == "NONE" and c.bg or BG },
    Conceal         = { fg = c.fg_dim },
    Directory       = { fg = c.blue, bold = true },
    Title           = { fg = c.violet, bold = true },
    Question        = { fg = c.green },
    MoreMsg         = { fg = c.green },
    ModeMsg         = { fg = c.fg, bold = true },
    ErrorMsg        = { fg = c.red, bold = true },
    WarningMsg      = { fg = c.warn },
    WinBar          = { fg = c.fg_dim, bg = BG_ALT },
    WinBarNC        = { fg = c.gutter, bg = BG_ALT },

    StatusLine      = { fg = c.fg_dim, bg = c.bg_alt },
    StatusLineNC    = { fg = c.gutter, bg = c.bg_dim },
    TabLine         = { fg = c.fg_dim, bg = c.bg_alt },
    TabLineFill     = { bg = c.bg_dim },
    TabLineSel      = { fg = c.blue, bg = BG, bold = true },

    Pmenu           = { fg = c.fg_dim, bg = c.bg_float },
    PmenuSel        = { fg = c.fg, bg = c.bg_sel, bold = true },
    PmenuSbar       = { bg = c.bg_alt },
    PmenuThumb      = { bg = c.border },
    PmenuKind       = { fg = c.violet, bg = c.bg_float },
    PmenuExtra      = { fg = c.gutter, bg = c.bg_float },
    WildMenu        = { fg = c.bg, bg = c.blue },

    ------------------------------------------------------------------ sintaxis
    Comment         = { fg = c.comment, italic = italic },
    Constant        = { fg = c.orange },
    String          = { fg = c.green },
    Character       = { fg = c.green },
    Number          = { fg = c.orange },
    Boolean         = { fg = c.orange, bold = true },
    Float           = { fg = c.orange },
    Identifier      = { fg = c.coral },
    Function        = { fg = c.blue },
    Statement       = { fg = c.violet },
    Conditional     = { fg = c.violet },
    Repeat          = { fg = c.violet },
    Label           = { fg = c.violet },
    Operator        = { fg = c.cyan },
    Keyword         = { fg = c.violet, italic = true },
    Exception       = { fg = c.magenta },
    PreProc         = { fg = c.magenta },
    Include         = { fg = c.magenta },
    Define          = { fg = c.magenta },
    Macro           = { fg = c.magenta },
    PreCondit       = { fg = c.magenta },
    Type            = { fg = c.amber },
    StorageClass    = { fg = c.violet },
    Structure       = { fg = c.amber },
    Typedef         = { fg = c.amber },
    Special         = { fg = c.ice },
    SpecialChar     = { fg = c.magenta },
    Delimiter       = { fg = c.fg_dim },
    Tag             = { fg = c.coral },
    Debug           = { fg = c.red },
    Underlined      = { fg = c.blue, underline = true },
    Todo            = { fg = c.bg, bg = c.amber, bold = true },
    Error           = { fg = c.red, bold = true },

    ------------------------------------------------------------------ treesitter
    ["@variable"]              = { fg = c.coral },
    ["@variable.builtin"]      = { fg = c.red, italic = true },
    ["@variable.parameter"]    = { fg = c.coral, italic = true },
    ["@variable.member"]       = { fg = c.ice },
    ["@constant"]              = { fg = c.orange },
    ["@constant.builtin"]      = { fg = c.orange, bold = true },
    ["@constant.macro"]        = { fg = c.magenta },
    ["@module"]                = { fg = c.amber },
    ["@label"]                 = { fg = c.violet },
    ["@string"]                = { fg = c.green },
    ["@string.escape"]         = { fg = c.magenta, bold = true },
    ["@string.special"]        = { fg = c.ice },
    ["@string.regexp"]         = { fg = c.cyan },
    ["@character"]             = { fg = c.green },
    ["@boolean"]               = { fg = c.orange, bold = true },
    ["@number"]                = { fg = c.orange },
    ["@function"]              = { fg = c.blue },
    ["@function.builtin"]      = { fg = c.ice },
    ["@function.call"]         = { fg = c.blue },
    ["@function.macro"]        = { fg = c.magenta },
    ["@function.method"]       = { fg = c.blue },
    ["@constructor"]           = { fg = c.amber },
    ["@operator"]              = { fg = c.cyan },
    ["@keyword"]               = { fg = c.violet, italic = true },
    ["@keyword.function"]      = { fg = c.violet, italic = true },
    ["@keyword.return"]        = { fg = c.magenta, italic = true },
    ["@keyword.import"]        = { fg = c.magenta },
    ["@keyword.exception"]     = { fg = c.magenta },
    ["@keyword.conditional"]   = { fg = c.violet, italic = true },
    ["@keyword.repeat"]        = { fg = c.violet, italic = true },
    ["@type"]                  = { fg = c.amber },
    ["@type.builtin"]          = { fg = c.amber, italic = true },
    ["@type.definition"]       = { fg = c.amber },
    ["@attribute"]             = { fg = c.magenta },
    ["@property"]              = { fg = c.ice },
    ["@punctuation.delimiter"] = { fg = c.fg_dim },
    ["@punctuation.bracket"]   = { fg = c.fg_dim },
    ["@punctuation.special"]   = { fg = c.cyan },
    ["@comment"]               = { fg = c.comment, italic = italic },
    ["@comment.todo"]          = { fg = c.bg, bg = c.amber, bold = true },
    ["@comment.warning"]       = { fg = c.bg, bg = c.orange, bold = true },
    ["@comment.error"]         = { fg = c.bg, bg = c.red, bold = true },
    ["@comment.note"]          = { fg = c.bg, bg = c.cyan, bold = true },
    ["@tag"]                   = { fg = c.coral },
    ["@tag.attribute"]         = { fg = c.amber, italic = true },
    ["@tag.delimiter"]         = { fg = c.fg_dim },
    ["@markup.heading"]        = { fg = c.violet, bold = true },
    ["@markup.strong"]         = { fg = c.orange, bold = true },
    ["@markup.italic"]         = { fg = c.coral, italic = true },
    ["@markup.link"]           = { fg = c.blue, underline = true },
    ["@markup.link.url"]       = { fg = c.cyan, underline = true },
    ["@markup.raw"]            = { fg = c.green },
    ["@markup.list"]           = { fg = c.cyan },
    ["@diff.plus"]             = { fg = c.green },
    ["@diff.minus"]            = { fg = c.red },

    ------------------------------------------------------------------ LSP
    ["@lsp.type.class"]         = { link = "@type" },
    ["@lsp.type.enum"]          = { link = "@type" },
    ["@lsp.type.enumMember"]    = { link = "@constant" },
    ["@lsp.type.interface"]     = { fg = c.amber, italic = true },
    ["@lsp.type.namespace"]     = { link = "@module" },
    ["@lsp.type.parameter"]     = { link = "@variable.parameter" },
    ["@lsp.type.property"]      = { link = "@property" },
    ["@lsp.type.struct"]        = { link = "@type" },
    ["@lsp.type.typeParameter"] = { fg = c.amber, italic = true },
    ["@lsp.type.variable"]      = { link = "@variable" },
    ["@lsp.type.decorator"]     = { link = "@attribute" },
    LspReferenceText            = { bg = c.bg_sel },
    LspReferenceRead            = { bg = c.bg_sel },
    LspReferenceWrite           = { bg = c.bg_sel, underline = true },
    LspInlayHint                = { fg = c.ghost, italic = true },
    LspCodeLens                 = { fg = c.comment, italic = true },
    LspSignatureActiveParameter = { fg = c.ice, bold = true },

    ------------------------------------------------------------------ diagnósticos
    DiagnosticError            = { fg = c.red },
    DiagnosticWarn             = { fg = c.warn },
    DiagnosticInfo             = { fg = c.info },
    DiagnosticHint             = { fg = c.hint },
    DiagnosticOk               = { fg = c.ok },
    DiagnosticUnderlineError   = { sp = c.red,   undercurl = true },
    DiagnosticUnderlineWarn    = { sp = c.warn,  undercurl = true },
    DiagnosticUnderlineInfo    = { sp = c.info,  undercurl = true },
    DiagnosticUnderlineHint    = { sp = c.hint,  undercurl = true },
    DiagnosticVirtualTextError = { fg = c.red,   bg = "#1a0a08" },
    DiagnosticVirtualTextWarn  = { fg = c.warn,  bg = "#1a1508" },
    DiagnosticVirtualTextInfo  = { fg = c.info,  bg = "#08111f" },
    DiagnosticVirtualTextHint  = { fg = c.hint,  bg = "#071a19" },

    ------------------------------------------------------------------ diff / git
    DiffAdd      = { bg = c.add },
    DiffChange   = { bg = c.change },
    DiffDelete   = { bg = c.delete },
    DiffText     = { bg = "#2a5a91", bold = true },
    diffAdded    = { fg = c.green },
    diffRemoved  = { fg = c.red },
    diffChanged  = { fg = c.blue },
    diffFile     = { fg = c.amber },
    diffLine     = { fg = c.violet },
    GitSignsAdd    = { fg = c.green },
    GitSignsChange = { fg = c.blue },
    GitSignsDelete = { fg = c.red },

    ------------------------------------------------------------------ plugins
    TelescopeNormal        = { fg = c.fg, bg = c.bg_float },
    TelescopeBorder        = { fg = c.border, bg = c.bg_float },
    TelescopeTitle         = { fg = c.bg, bg = c.blue, bold = true },
    TelescopePromptPrefix  = { fg = c.violet },
    TelescopeSelection     = { fg = c.fg, bg = c.bg_sel, bold = true },
    TelescopeMatching      = { fg = c.ice, bold = true },

    CmpItemAbbr           = { fg = c.fg_dim },
    CmpItemAbbrMatch      = { fg = c.ice, bold = true },
    CmpItemAbbrMatchFuzzy = { fg = c.blue },
    CmpItemAbbrDeprecated = { fg = c.gutter, strikethrough = true },
    CmpItemKind           = { fg = c.violet },
    CmpItemMenu           = { fg = c.comment },

    IblIndent      = { fg = "#101827" },
    IblScope       = { fg = c.border },

    NeoTreeNormal      = { fg = c.fg_dim, bg = BG_ALT },
    NeoTreeNormalNC    = { fg = c.gutter, bg = BG_ALT },
    NeoTreeGitModified = { fg = c.amber },
    NeoTreeGitAdded    = { fg = c.green },
    NeoTreeGitDeleted  = { fg = c.red },
    NeoTreeRootName    = { fg = c.violet, bold = true },

    WhichKey          = { fg = c.violet },
    WhichKeyGroup     = { fg = c.blue },
    WhichKeyDesc      = { fg = c.fg_dim },
    WhichKeySeparator = { fg = c.gutter },
    WhichKeyFloat     = { bg = c.bg_float },

    NotifyERRORBorder = { fg = c.red },   NotifyERRORIcon = { fg = c.red },
    NotifyWARNBorder  = { fg = c.warn },  NotifyWARNIcon  = { fg = c.warn },
    NotifyINFOBorder  = { fg = c.info },  NotifyINFOIcon  = { fg = c.info },
    NotifyDEBUGBorder = { fg = c.comment },
    NotifyTRACEBorder = { fg = c.violet },
  }

  for group, spec in pairs(groups) do hl(group, spec) end

  -- Paleta del terminal integrado: los mismos 16 colores que usa Ghostty,
  -- para que :terminal y el terminal del sistema no se contradigan.
  local term = {
    c.bg_hl, c.red,   c.green, c.amber,
    c.blue,  c.violet, c.cyan, c.fg_dim,
    c.gutter, c.coral, c.green, c.orange,
    c.ice,   c.magenta, c.cyan, c.fg,
  }
  for i, col in ipairs(term) do vim.g["terminal_color_" .. (i - 1)] = col end
end

setup()
return M
