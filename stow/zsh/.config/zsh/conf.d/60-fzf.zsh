# 60-fzf.zsh — fzf es el motor detrás del completado (fzf-tab), Ctrl+R,
# Ctrl+T y del panel de paquetes (spec-package-panel.md). Un solo bloque de
# color para los cuatro. A diferencia de tuigreet, fzf SÍ acepta hex directo.
#
# El color ya no vive aquí a mano — lo genera matugen desde theme.toml
# (themes/_templates/fzf.tmpl, vía bin/cmd/theme-export + 50-theme.sh).
# Si el archivo generado todavía no existe (primer arranque antes del
# instalador, o clon nuevo sin desplegar), cae a un valor de emergencia
# para que abrir una terminal no se rompa.
if [[ -f "$ZDOTDIR/fzf-colors.zsh" ]]; then
  source "$ZDOTDIR/fzf-colors.zsh"
else
  export FZF_DEFAULT_OPTS="--height=52% --layout=reverse --border=rounded --info=inline"
fi

# el paquete `fzf` de Arch instala los scripts de integración aquí
if [[ -f /usr/share/fzf/completion.zsh ]]; then
  source /usr/share/fzf/completion.zsh
fi
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
  source /usr/share/fzf/key-bindings.zsh
fi

# Ctrl+T (insertar ruta) y Ctrl+R (historial) heredan FZF_DEFAULT_OPTS.
# Alt+C (cd interactivo) usa fd si existe, para respetar .gitignore.
if command -v fd >/dev/null 2>&1; then
  export FZF_ALT_C_COMMAND='fd --type=d --hidden --exclude .git'
  export FZF_CTRL_T_COMMAND='fd --hidden --exclude .git'
fi
export FZF_CTRL_T_OPTS="--preview 'bat --color=always --style=numbers --line-range=:80 {} 2>/dev/null || eza -1 --color=always --icons {}'"
export FZF_ALT_C_OPTS="--preview 'eza -1 --color=always --icons {}'"
