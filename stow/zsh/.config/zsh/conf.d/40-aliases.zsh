# 40-aliases.zsh — el ecosistema de LIMITLESS-OS.md §3, a un nombre corto.

# ── reemplazos modernos (§3.2) ──────────────────────────────────────────────
if command -v eza >/dev/null 2>&1; then
  alias ls='eza --icons --group-directories-first'
  alias ll='eza -l --icons --group-directories-first --git'
  alias la='eza -la --icons --group-directories-first --git'
  alias lt='eza --tree --icons --level=2'
fi
command -v bat  >/dev/null 2>&1 && alias cat='bat --style=plain --paging=never'
command -v fd   >/dev/null 2>&1 && alias find='fd'
command -v rg   >/dev/null 2>&1 && alias grep='rg'
command -v dust >/dev/null 2>&1 && alias du='dust'
command -v duf  >/dev/null 2>&1 && alias df='duf'
command -v procs >/dev/null 2>&1 && alias ps='procs'

# ── dotctl: el único punto de entrada (plan-automation.md §3) ──────────────
alias d='dotctl'
alias dt='dotctl theme set'
alias di='dotctl pkg install'
alias dr='dotctl pkg remove'
alias dp='dotctl dev open'
alias ddoc='dotctl doctor'
alias dup='dotctl update'

# ── git: lazygit es la interfaz principal, no un extra ──────────────────────
alias lg='lazygit'
alias g='git'
alias gs='git status -sb'
alias gc='git commit'
alias gp='git push'
alias gl='git log --oneline --graph --decorate -20'

# ── el ecosistema TUI (§3.4): un nombre corto para cada uno ─────────────────
alias ld='lazydocker'
alias y='yazi'
alias t='btop'
alias gpu='nvtop'
alias wifi='impala'
alias bt='bluetui'
alias vol='wiremix'
alias svc='systemctl-tui'
alias logs='lnav'

# ── seguridad: nunca un rm/mv/cp silencioso a la primera ───────────────────
alias rm='rm -I'
alias mv='mv -i'
alias cp='cp -i'

# ── atajos de navegación ─────────────────────────────────────────────────────
alias ..='cd ..'
alias ...='cd ../..'
alias ....='cd ../../..'
alias -- -='cd -'         # `-` para volver al directorio anterior

# ── herdr: agentes (LIMITLESS-OS.md §4.1) ───────────────────────────────────
alias h='herdr'
alias ha='herdr attach'

mkcd() { mkdir -p -- "$1" && cd -- "$1"; }
