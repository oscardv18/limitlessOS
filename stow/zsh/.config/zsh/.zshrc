# ~/.config/zsh/.zshrc — entrypoint delgado.
#
# Igual que hyprland.lua: este archivo no contiene lógica, solo carga
# módulos en orden. Añadir un módulo = crear un archivo en conf.d/;
# nunca hay que tocar esto.

for _f in "$ZDOTDIR"/conf.d/*.zsh; do
  source "$_f"
done
unset _f
