#!/usr/bin/env bash
# 00-preflight.sh — nada se instala sin esto. Monta la red de seguridad
# (LIMITLESS-OS.md §1, capa 2) ANTES que ninguna otra etapa, y crea la
# primera instantánea Btrfs antes de tocar el sistema.

# Plymouth es la causa documentada del cuelgue de arranque que ya viviste:
# no suelta el control de la pantalla en el traspaso KMS/DRM hacia el
# gestor de sesión — bug conocido y recurrente de CachyOS, reportado con
# SDDM también, no es específico de un gestor concreto. La comunidad de
# CachyOS lo trata como el arreglo estándar: quitarlo, no solo apagarlo.
#
# Cinco pasos, en este orden, porque el segundo (mkinitcpio) es el único
# de todo el instalador que puede dejar el sistema sin arrancar si se hace
# mal — por eso va con respaldo explícito y nunca toca HOOKS a ciegas.
_disable_plymouth() {
  pacman -Qq plymouth &>/dev/null || { echo "plymouth no está instalado, nada que hacer"; return 0; }

  # 1. sólo los paquetes que de verdad están instalados — pacman -R falla
  #    si le pides quitar algo que no existe, y eso no debe frenar la etapa
  local candidates=(plymouth cachyos-plymouth-bootanimation cachyos-plymouth-theme plymouth-kcm)
  local installed=()
  local p
  for p in "${candidates[@]}"; do
    pacman -Qq "$p" &>/dev/null && installed+=("$p")
  done
  if (( ${#installed[@]} > 0 )); then
    sudo pacman -Rns --noconfirm "${installed[@]}" || return 1
  fi

  # 2. HOOKS=(...) en mkinitcpio.conf — respaldo primero, y el sed sólo
  #    toca la palabra "plymouth" dentro de esa línea concreta, nunca el
  #    archivo entero, para no arriesgar ninguna otra línea
  if grep -q '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf 2>/dev/null; then
    sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.$(date +%s)"
    sudo sed -i -E '/^HOOKS=/ s/\bplymouth[[:space:]]*//; /^HOOKS=/ s/[[:space:]]+\)/)/' /etc/mkinitcpio.conf
    sudo mkinitcpio -P || return 1
  fi

  # 3. quiet/splash del cmdline — mismo respaldo que ya usa 60-session.sh
  #    para no duplicar copias si esa etapa también toca el archivo
  if grep -qE '\b(quiet|splash)\b' /etc/default/grub 2>/dev/null; then
    [[ -f /etc/default/grub.bak.disable-plymouth ]] || \
      sudo cp /etc/default/grub /etc/default/grub.bak.disable-plymouth
    sudo sed -i -E 's/\b(quiet|splash)\b//g; s/  +/ /g' /etc/default/grub
    sudo grub-mkconfig -o /boot/grub/grub.cfg || return 1
  fi

  echo "plymouth eliminado — el siguiente arranque muestra texto plano, sin animación"
}
export -f _disable_plymouth

# ── conflicto real con el perfil XFCE de CachyOS ──────────────────────────
# El perfil XFCE del instalador de CachyOS trae `cachyos-xfce-settings`,
# que depende de `cachyos-zsh-config`, que a su vez arrastra:
#     oh-my-zsh-git · zsh-theme-powerlevel10k · zsh-syntax-highlighting
# Los tres chocan de frente con este proyecto:
#   · oh-my-zsh — descartado explícitamente (LIMITLESS-OS.md §3.2: "lento,
#     opaco, y la mitad de lo que aporta ya lo cubre Starship")
#   · powerlevel10k — es OTRO prompt; pelea con Starship por el mismo sitio
#   · zsh-syntax-highlighting — engancha el MISMO widget de ZLE que
#     zsh-fast-syntax-highlighting; con los dos, el resaltado se rompe
#
# Además `cachyos-zsh-config` deja su propio /etc/zsh/zshrc, que se ejecuta
# ANTES que el ~/.zshenv de este repo y puede pisar ZDOTDIR.
#
# NO se desinstala a la brava: `cachyos-xfce-settings` depende de él, y
# quitarlo se llevaría por delante la sesión XFCE de emergencia — justo la
# red de seguridad que este proyecto monta. Se AVISA y se deja la decisión
# al usuario, que es lo que corresponde con una dependencia de sistema.
_check_cachyos_zsh() {
  pacman -Qq cachyos-zsh-config &>/dev/null || {
    echo "cachyos-zsh-config no está instalado — sin conflicto"
    return 0
  }
  echo "AVISO: cachyos-zsh-config está instalado (lo trae el perfil XFCE de CachyOS)"
  echo "  arrastra oh-my-zsh + powerlevel10k + zsh-syntax-highlighting,"
  echo "  que chocan con el zsh de este proyecto (starship + fast-syntax-highlighting)."
  echo "  Los enlaces de stow ganan sobre ~/.zshrc, pero /etc/zsh/zshrc se lee antes."
  echo "  Si el prompt sale raro tras reiniciar, ese es el motivo:"
  echo "      sudo pacman -Rdd cachyos-zsh-config    # -Rdd: no toca xfce-settings"
  return 0
}
export -f _check_cachyos_zsh

stage_main() {
  ui_spin "Quitando Plymouth (causa conocida del cuelgue de arranque en CachyOS)" -- _disable_plymouth || \
    ui_warn "no se pudo quitar Plymouth del todo — revisa /etc/mkinitcpio.conf y /etc/default/grub a mano"

  ui_spin "Buscando conflictos conocidos con paquetes de CachyOS" -- _check_cachyos_zsh || true


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
