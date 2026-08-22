#!/usr/bin/env bash
# 00-preflight.sh — nada se instala sin esto. Monta la red de seguridad
# (LIMITLESS-OS.md §1, capa 2) ANTES que ninguna otra etapa, y crea la
# primera instantánea Btrfs antes de tocar el sistema.

stage_main() {
  ui_info "arquitectura: $(uname -m)"
  [[ "$(uname -m)" == "x86_64" ]] || { ui_fail "arquitectura no soportada"; return 1; }

  ui_info "comprobando conexión a internet…"
  if ! ping -c1 -W3 archlinux.org >/dev/null 2>&1; then
    ui_fail "sin red. Configúrala con nmtui o iwctl y vuelve a ejecutar."
    return 1
  fi
  ui_ok "red disponible"

  local free_gb
  free_gb=$(df --output=avail -BG / | tail -1 | tr -dc '0-9')
  if (( free_gb < 8 )); then
    ui_warn "quedan ${free_gb}G libres en /. Se recomiendan al menos 8G"
    ui_confirm "¿Continuar de todos modos?" || return 1
  else
    ui_ok "espacio libre: ${free_gb}G"
  fi

  local fstype
  fstype="$(findmnt -no FSTYPE / 2>/dev/null)"
  ui_info "sistema de archivos raíz: ${fstype:-desconocido}"

  if [[ "$fstype" == "btrfs" ]]; then
    if ! has_cmd snapper || ! has_cmd grub-btrfs 2>/dev/null; then
      ui_spin "Instalando snapper + snap-pac + grub-btrfs (LIMITLESS-OS.md §1)" -- \
        sudo pacman -S --needed --noconfirm snapper snap-pac grub-btrfs || return 1
    fi
    if [[ ! -d /etc/snapper/configs ]] || ! sudo snapper list-configs 2>/dev/null | grep -q '^root'; then
      ui_spin "Configurando snapper para la raíz" -- \
        sudo snapper -c root create-config / || ui_warn "snapper ya podría estar configurado"
    fi
    ui_spin "Activando grub-btrfsd" -- \
      sudo systemctl enable --now grub-btrfsd || ui_warn "revisa grub-btrfsd manualmente"
    ui_spin "Primera instantánea (antes de tocar nada)" -- \
      sudo snapper -c root create --description "limitless: preflight" || true
    ui_ok "red de seguridad activa — comprueba el submenú «Arch Linux snapshots» en GRUB tras reiniciar"
  else
    ui_warn "raíz no-Btrfs: sin instantáneas de sistema. Ver LIMITLESS-OS.md, Capa 2b"
  fi

  return 0
}
