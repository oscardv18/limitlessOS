# 10-completion.zsh — motor de completado + estilo visual de fzf-tab.
#
# zsh-completions (paquete oficial `zsh-completions`) añade definiciones al
# fpath ANTES de compinit — si se añaden después no surten efecto.

fpath=(/usr/share/zsh/site-functions $fpath)

autoload -Uz compinit
# recompila el dump solo una vez al día: compinit es lo más lento del arranque
_comp_dump="$ZSH_CACHE_DIR/zcompdump"
if [[ -n "$_comp_dump"(#qN.mh+24) ]]; then
  compinit -d "$_comp_dump"
else
  compinit -C -d "$_comp_dump"
fi
unset _comp_dump

zmodload zsh/complist

# ── estilo general del menú ─────────────────────────────────────────────────
zstyle ':completion:*' menu no
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' group-name ''
zstyle ':completion:*:descriptions' format '  %F{8}» %d%f'
zstyle ':completion:*:messages' format '  %F{8}%d%f'
zstyle ':completion:*:warnings' format '  %F{1}sin coincidencias%f'
zstyle ':completion:*' squeeze-slashes true

# ── fzf-tab: el menú de completado se pinta con fzf, así que el color sale de
#    FZF_DEFAULT_OPTS en 60-fzf.zsh, no de aquí ─────────────────────────────
zstyle ':fzf-tab:*' fzf-flags --height=50%
zstyle ':fzf-tab:*' switch-group ',' '.'
zstyle ':fzf-tab:*' fzf-command fzf
zstyle ':fzf-tab:complete:*:*' fzf-preview \
  '[[ -d $realpath ]] && eza -1 --color=always --icons $realpath 2>/dev/null || bat --color=always --style=numbers --line-range=:60 $realpath 2>/dev/null'
zstyle ':fzf-tab:complete:cd:*' fzf-preview 'eza -1 --color=always --icons $realpath'
zstyle ':fzf-tab:complete:(kill|ps):argument-rest' fzf-preview \
  '[[ $group == "[process ID]" ]] && ps --pid=$word -o cmd --no-headers -w -w'
zstyle ':fzf-tab:*' popup-min-size 60 12
