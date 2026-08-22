# 00-options.zsh — historial y comportamiento base del shell.

HISTFILE="$HOME/.local/state/zsh/history"
[[ -d "${HISTFILE:h}" ]] || mkdir -p "${HISTFILE:h}"
HISTSIZE=50000
SAVEHIST=50000

setopt EXTENDED_HISTORY       # timestamp por comando
setopt HIST_EXPIRE_DUPS_FIRST # al llenarse, purga duplicados antes que únicos
setopt HIST_IGNORE_DUPS       # no repite el comando inmediatamente anterior
setopt HIST_IGNORE_ALL_DUPS   # un comando repetido borra la entrada vieja
setopt HIST_IGNORE_SPACE      # `  comando` con espacio inicial no se guarda
setopt HIST_FIND_NO_DUPS
setopt HIST_SAVE_NO_DUPS
setopt SHARE_HISTORY          # varias terminales comparten historial en vivo
setopt APPEND_HISTORY
setopt INC_APPEND_HISTORY_TIME

setopt AUTO_CD                # `~/dev/proyecto` sin `cd` delante
setopt AUTO_PUSHD
setopt PUSHD_IGNORE_DUPS
setopt PUSHD_SILENT
setopt EXTENDED_GLOB          # necesario para varios patrones de fzf-tab
setopt NO_BEEP
setopt INTERACTIVE_COMMENTS   # permite `# comentario` al final de una línea interactiva

# Directorios de estado propios — no todo va a $HOME suelto.
export ZSH_CACHE_DIR="$HOME/.cache/zsh"
[[ -d "$ZSH_CACHE_DIR" ]] || mkdir -p "$ZSH_CACHE_DIR"

export EDITOR="nvim"
export VISUAL="nvim"
export PAGER="bat --paging=always --style=plain"
export MANPAGER="sh -c 'col -bx | bat -l man -p'"
