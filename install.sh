#!/usr/bin/env bash
# install.sh — punto de entrada único. `git clone … && cd … && ./install.sh`
#
# Este archivo no instala nada del sistema: su único trabajo es garantizar
# que `gum` exista ANTES de dibujar la primera línea de interfaz, porque gum
# ES la interfaz (install/lib/ui.sh). Es la única parte del proyecto que se
# permite un `pacman -S` fuera de una etapa numerada, y es deliberado: sin
# gum no hay TUI que mostrar, así que no hay nada que orquestar todavía.

set -uo pipefail

if [[ "${EUID}" -eq 0 ]]; then
  echo "No ejecutes install.sh como root — te pedirá sudo cuando lo necesite." >&2
  exit 1
fi

if ! command -v pacman >/dev/null 2>&1; then
  echo "Este instalador es para Arch/CachyOS (necesita pacman)." >&2
  exit 1
fi

if ! command -v gum >/dev/null 2>&1; then
  echo "⬡ Instalando gum (la interfaz del instalador)…"
  sudo pacman -S --needed --noconfirm gum || {
    echo "No se pudo instalar gum. Instálalo a mano (pacman -S gum) y reintenta." >&2
    exit 1
  }
fi

exec "$(dirname -- "${BASH_SOURCE[0]}")/install/run.sh" "$@"
