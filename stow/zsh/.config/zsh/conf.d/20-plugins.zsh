# 20-plugins.zsh — carga los tres plugins que en fish venían de fábrica
# (spec-layouts.md / LIMITLESS-OS.md §3.2). Sin framework: un loader
# defensivo de ~15 líneas en vez de oh-my-zsh.
#
# Los paquetes de Arch/AUR instalan cada plugin en una ruta más o menos
# estándar, pero no siempre idéntica entre repos oficiales y AUR. En vez de
# asumir una sola ruta y romper en silencio si cambia, se prueban varias
# candidatas por plugin y se avisa (una vez, no en cada shell nuevo) si
# ninguna existe — así `dotctl doctor` tiene algo que detectar.

typeset -A _limitless_plugins=(
  [zsh-autosuggestions]="
    /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
  "
  [fast-syntax-highlighting]="
    /usr/share/zsh/plugins/fast-syntax-highlighting/fast-syntax-highlighting.plugin.zsh
    /usr/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
  "
  [fzf-tab]="
    /usr/share/zsh/plugins/fzf-tab/fzf-tab.plugin.zsh
  "
)

_limitless_missing=()
for _name in "${(k)_limitless_plugins[@]}"; do
  _found=""
  for _path in ${(z)_limitless_plugins[$_name]}; do
    if [[ -r "$_path" ]]; then
      source "$_path"
      _found=1
      break
    fi
  done
  [[ -n "$_found" ]] || _limitless_missing+=("$_name")
done

if (( ${#_limitless_missing} > 0 )) && [[ -z "$LIMITLESS_SILENCE_PLUGIN_WARN" ]]; then
  print -P "%F{9}✗%f faltan plugins de zsh: %F{3}${(j:, :)_limitless_missing}%f — %F{8}dotctl doctor%f para instalarlos"
fi
unset _limitless_plugins _limitless_missing _name _found _path

# ── ajustes de comportamiento, no de carga ──────────────────────────────────
# El color de la sugerencia sale de la paleta del tema, no de un valor suelto
# (pendiente: generar desde theme.toml — ver docs/spec-colorscheme.md §6).
ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=#46587a"          # gutter — visible, nunca protagonista
ZSH_AUTOSUGGEST_STRATEGY=(history completion)
ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=48                    # no intentes sugerir sobre líneas larguísimas

# fast-syntax-highlighting no expone variables de color en su API pública;
# su paleta se ajusta con `fast-theme`, ver system/themes/README (pendiente,
# spec-colorscheme.md §6, junto con la plantilla de matugen).

# zoxide reemplaza `cd` con salto por frecuencia — se carga aquí porque
# fzf-tab necesita existir antes para que `zi` (su selector interactivo)
# pinte con el mismo estilo que el resto de menús.
if command -v zoxide >/dev/null 2>&1; then
  eval "$(zoxide init zsh --cmd cd)"
fi
