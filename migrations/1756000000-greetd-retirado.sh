#!/usr/bin/env bash
#: desc: Retira greetd/tuigreet tras el cambio a LightDM
#
# PRIMERA MIGRACIÓN — sirve además de plantilla del patrón exacto para las
# siguientes (plan-automation.md §5). Tres propiedades que toda migración
# debe cumplir y que esta demuestra:
#
#   1. IDEMPOTENTE: correrla dos veces no rompe nada. Cada paso comprueba
#      antes de actuar.
#   2. SALE 0 SI NO HAY NADA QUE HACER: un sistema que nunca tuvo greetd
#      no es un error, es el caso normal en una instalación nueva.
#   3. NO ASUME: verifica que cada cosa existe antes de tocarla.
#
# El caso real que la motiva: greetd + tuigreet se abandonaron tras fallar
# en la máquina real (docs/LIMITLESS-OS.md §2). Quien actualice desde un
# commit anterior a ese cambio tiene el paquete instalado, el servicio
# habilitado y /etc/greetd/ con configuración muerta — y dos gestores de
# pantalla habilitados a la vez es exactamente cómo se arranca a una
# pantalla negra.

set -uo pipefail

did_something=0

# 1. deshabilitar el servicio antes de quitar el paquete: al revés,
#    systemd se queda con una unidad huérfana habilitada.
if systemctl is-enabled greetd.service >/dev/null 2>&1; then
  echo "  · deshabilitando greetd.service"
  sudo systemctl disable greetd.service >/dev/null 2>&1 || true
  did_something=1
fi

# 2. el paquete, solo si está
if pacman -Qq greetd >/dev/null 2>&1; then
  echo "  · desinstalando greetd"
  sudo pacman -Rns --noconfirm greetd >/dev/null 2>&1 || true
  did_something=1
fi

if pacman -Qq greetd-tuigreet >/dev/null 2>&1; then
  echo "  · desinstalando greetd-tuigreet"
  sudo pacman -Rns --noconfirm greetd-tuigreet >/dev/null 2>&1 || true
  did_something=1
fi

# 3. la configuración muerta. Se hace copia antes de borrar: /etc no es
#    un sitio donde este proyecto borre sin dejar rastro.
if [[ -d /etc/greetd ]]; then
  echo "  · respaldando y retirando /etc/greetd"
  sudo cp -a /etc/greetd "/etc/greetd.bak.$(date +%Y%m%d%H%M%S)" 2>/dev/null || true
  sudo rm -rf /etc/greetd 2>/dev/null || true
  did_something=1
fi

if (( did_something == 0 )); then
  echo "  · greetd no estaba presente — nada que hacer"
fi

exit 0
