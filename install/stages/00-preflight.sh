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

  # ORDEN CORREGIDO tras un despliegue real: HOOKS= se limpia PRIMERO,
  # antes de quitar el paquete. Al revés (como estaba) pasa esto: pacman
  # -R plymouth dispara su propio hook de postinstalación que regenera el
  # initramfs — pero HOOKS= todavía dice "plymouth" y el script del hook
  # ya se borró con el paquete, así que esa regeneración automática falla
  # con "Hook 'plymouth' cannot be found" y deja escrito en /boot un
  # initramfs marcado "may not be complete". El script lo corregía un
  # paso después con su propio `mkinitcpio -P`, así que el resultado final
  # quedaba bien — pero si la máquina se apaga justo en esa ventana, el
  # initramfs roto es el que queda. Limpiar HOOKS= antes cierra esa
  # ventana: cuando el hook de pacman se dispare, ya no menciona plymouth.

  # 1. HOOKS=(...) en mkinitcpio.conf — respaldo primero, y el sed sólo
  #    toca la palabra "plymouth" dentro de esa línea concreta, nunca el
  #    archivo entero, para no arriesgar ninguna otra línea
  if grep -q '^HOOKS=.*\bplymouth\b' /etc/mkinitcpio.conf 2>/dev/null; then
    sudo cp /etc/mkinitcpio.conf "/etc/mkinitcpio.conf.bak.$(date +%s)"
    sudo sed -i -E '/^HOOKS=/ s/\bplymouth[[:space:]]*//; /^HOOKS=/ s/[[:space:]]+\)/)/' /etc/mkinitcpio.conf
  fi

  # 2. sólo los paquetes que de verdad están instalados — pacman -R falla
  #    si le pides quitar algo que no existe, y eso no debe frenar la etapa.
  #    Esto ya dispara la regeneración del initramfs por su cuenta (el hook
  #    de pacman), ahora con HOOKS= ya limpio — no hace falta llamarlo aparte.
  local candidates=(plymouth cachyos-plymouth-bootanimation cachyos-plymouth-theme plymouth-kcm)
  local installed=()
  local p
  for p in "${candidates[@]}"; do
    pacman -Qq "$p" &>/dev/null && installed+=("$p")
  done
  if (( ${#installed[@]} > 0 )); then
    sudo pacman -Rns --noconfirm "${installed[@]}" || return 1
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

# ── paquetes que YA vienen instalados en la máquina y chocan de frente
#    con lo que pide packages/pacman.txt ──────────────────────────────────
# Encontrado en un despliegue real: pipewire-jack conflictúa con jack2
# (ambos declaran provides=jack — son intercambiables, pero pacman nunca
# migra solo porque pipewire-jack no declara replaces=jack2). Con
# --noconfirm, el prompt "¿Quitar jack2? [s/N]" toma el default (N), la
# transacción entera aborta con "dependencias en conflicto" — y como es
# una transacción atómica, NINGÚN paquete de esa corrida de pacman se
# instala, no solo pipewire-jack. Mismo patrón real con
# pulseaudio/pipewire-pulse, aunque no se manifestó en esa corrida porque
# esa instalación de CachyOS ya traía pipewire-pulse de fábrica — otros
# perfiles de CachyOS (o de cualquier distro base Arch) sí pueden traer
# pulseaudio puro.
#
# La resolución es seleccionar el paquete de PipeWire, no una decisión al
# azar: es lo que el resto del sistema espera (wireplumber ya está en la
# lista, PIPEWIRE_SESSION_MANAGER, todo lo demás asume pipewire). `-Rdd`
# quita SOLO el paquete nombrado, sin arrastrar lo que dependa de él — un
# paquete que dependía del jack2 nombrado a secas queda con una
# dependencia "huérfana" que `pacman -Dk` reportaría, pero sigue
# funcionando porque pipewire-jack provee la misma interfaz.
_resolve_pipewire_conflicts() {
  local pairs=("jack2:pipewire-jack" "pulseaudio:pipewire-pulse")
  local pair old new
  for pair in "${pairs[@]}"; do
    old="${pair%%:*}"
    new="${pair##*:}"
    if pacman -Qq "$old" &>/dev/null; then
      echo "AVISO: '$old' ya está instalado y conflictúa con '$new' (packages/pacman.txt) — quitando '$old' primero"
      sudo pacman -Rdd --noconfirm "$old" || {
        echo "  no se pudo quitar '$old' — revísalo a mano antes de reintentar la instalación" >&2
        return 1
      }
    fi
  done
  return 0
}
export -f _resolve_pipewire_conflicts

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

  ui_spin "Resolviendo conflictos conocidos de audio (jack2/pulseaudio)" -- _resolve_pipewire_conflicts || \
    ui_warn "no se pudieron resolver a tiempo — 10-core.sh puede fallar si jack2 o pulseaudio siguen instalados"


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
