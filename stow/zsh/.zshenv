# ~/.zshenv — se lee SIEMPRE, hasta en shells no interactivos (scripts, cron).
# Por eso va vacío de casi todo: solo fija dónde vive el resto de la config,
# para que un `env -i zsh -c cmd` desde otra herramienta no arrastre nada más.

export ZDOTDIR="$HOME/.config/zsh"
