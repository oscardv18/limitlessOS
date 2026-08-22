# 30-keybindings.zsh — modo vi (coherente con Neovim y con vicmd_symbol
# de starship.toml, que ya esperaba esto) + atajos sueltos.

bindkey -v
export KEYTIMEOUT=15   # ms para reconocer una secuencia de escape — 15 evita
                        # el retraso perceptible al pulsar Esc que trae el defecto

# el cursor cambia de forma según el modo, igual que en nvim
function _limitless_cursor_shape() {
  case $KEYMAP in
    vicmd)      print -n '\e[2 q' ;;  # bloque — modo normal
    viins|main) print -n '\e[6 q' ;;  # barra  — modo inserción
  esac
}
zle -N zle-keymap-select _limitless_cursor_shape
zle -N zle-line-init _limitless_cursor_shape

# Ctrl+R para historial lo asume fzf-history (fzf-tab no lo cubre) — ver
# 60-fzf.zsh. Ctrl+E abre la línea actual en $EDITOR, como en nvim con `cc`.
autoload -Uz edit-command-line
zle -N edit-command-line
bindkey -M vicmd 'v' edit-command-line
bindkey '^E' edit-command-line

# navegación de palabras con Ctrl+flechas, la que trae cualquier terminal
bindkey '^[[1;5C' forward-word
bindkey '^[[1;5D' backward-word
bindkey '^[[3~'   delete-char           # Supr
bindkey '^?'       backward-delete-char # Retroceso — algunos terminales lo pierden en modo vi

# aceptar la sugerencia de autosuggestions con Fin, no solo con flecha derecha
bindkey '^[[F' end-of-line
bindkey '^[[H' beginning-of-line
