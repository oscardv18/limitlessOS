# 50-prompt.zsh — starship.toml ya existe y ya está tematizado
# (stow/starship/.config/starship.toml). Aquí solo se activa.

if command -v starship >/dev/null 2>&1; then
  eval "$(starship init zsh)"
else
  print -P "%F{9}✗%f starship no está instalado — %F{8}dotctl doctor%f"
fi
