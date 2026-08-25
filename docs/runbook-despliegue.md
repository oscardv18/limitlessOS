# Runbook — Despliegue

> **Este runbook es lo último que se ejecuta, no lo primero.** Sustituye a `runbook-fase-0.md`, cuya premisa ("ejecuta el instalador ahora, en la Fase 0") quedó invalidada: todas las fases de construcción son trabajo sobre el repositorio, nunca sobre una máquina real. `install.sh` se corre **una sola vez**, aquí, cuando el ecosistema completo (Fases 1–6 de `LIMITLESS-OS.md`) ya está terminado y tienes un CachyOS o Arch recién instalado esperando.
>
> Si estás leyendo esto y todavía queda construcción pendiente en el repo, para — vuelve cuando `docs/LIMITLESS-OS.md` §6 tenga las seis fases de construcción cerradas.

---

## -1. Doble arranque, mismo disco

Dos cosas antes de empezar, porque tu Linux vive junto a Windows en la misma máquina:

**No tengo acceso remoto a tu CachyOS.** No hay SSH entre nosotros — el flujo es: reinicias a Linux, ejecutas los comandos ahí, y vuelves a Windows para traerme el resultado, o le pides a la instancia de Claude Code (o al enjambre de Gemini/Antigravity) que esté corriendo ahí que lo haga por ti y te reporte.

**Un atajo para no copiar todo a mano:** como es el mismo disco, es muy probable que CachyOS monte tu partición de Windows (NTFS) automáticamente, o que puedas montarla con un `mount` simple:

```bash
lsblk -f
findmnt -t ntfs3,ntfs
```

Si aparece montada, puedes volcar los logs ahí desde Linux y yo los leo directo la próxima vez que arranques Windows, sin transcribir nada.

**Sobre GRUB:** `60-session.sh` solo toca `GRUB_THEME` y la paleta de colores del VT en `/etc/default/grub`. Nunca toca `GRUB_DISABLE_OS_PROBER` ni nada que afecte a cómo GRUB detecta Windows.

---

## 0. Antes de nada: confirma que la construcción está completa

No es una instalación parcial — la arquitectura completa (`LIMITLESS-OS.md` §2 y §6) debe existir en el repo antes de tocar una máquina real:

- [ ] `hyprland.lua` real existe (no solo `dev/minimal.conf`)
- [ ] QuickShell: los `.qml` de barra, dock, launcher, notificaciones, OSD existen
- [ ] `system/lightdm/` con el tema `lightdm-webkit2-greeter` adaptado del mockup
- [ ] `packages/pacman.txt` incluye `lightdm`, `lightdm-webkit2-greeter`, `xfce4`, `xfce4-terminal`, `obs-studio`
- [ ] `docs/spec-keybinds.md` §4b (teclas de función) y §4c (OBS/pantalla compartida) están aplicadas en `hyprland.lua`, no solo documentadas
- [ ] `dotctl doctor` corre localmente sin errores de sintaxis (`bash -n` sobre todo `install/`, `qmllint` sobre todo `.qml`)

Si algo de esto falta, este no es el momento de instalar — vuelve a la fase de construcción correspondiente.

---

## 1. Pre-vuelo (2 minutos)

Con el CachyOS/Arch recién instalado, desde una sesión con red:

```bash
findmnt -no FSTYPE /       # confirma btrfs
ping -c1 archlinux.org     # confirma red
```

Si el sistema de archivos no dice `btrfs`, para y avísame — cambia la Capa 2 de la red de seguridad (`LIMITLESS-OS.md` §1, Capa 2b).

---

## 2. Clonar y ejecutar — la única vez que esto corre

```bash
git clone https://github.com/<tu-usuario>/<tu-repo>.git ~/.limitless
cd ~/.limitless
./install.sh
```

Orden exacto de lo que va a pasar, y por qué en ese orden (`LIMITLESS-OS.md` §5.3):

1. `install.sh` instala `gum` si falta — único paso fuera de una etapa numerada.
2. Banner de bienvenida + confirmación.
3. **Pide tu contraseña de `sudo` una vez** (`sudo_keepalive_start`, antes de la primera etapa) y la mantiene viva mientras corren las etapas largas — no te la vuelve a pedir a mitad.
4. `00-preflight`: red de seguridad Btrfs + **Plymouth fuera** (causa documentada del cuelgue que ya viviste).
5. `10-core`: paquetes oficiales, pacman puro — funciona igual en CachyOS que en cualquier Arch.
6. `20-aur`: `paru` + AUR. Un paquete que falla no frena el resto.
7. `30-services` → `40-stow` → `50-theme` → `60-session` (LightDM + XFCE + Hyprland) → `70-shell` → `80-tui` → `90-verify`.

**Si algo falla a mitad:** el instalador pregunta si quieres continuar. Di que sí salvo que el fallo te preocupe.

**Para parar y reanudar:** `./install.sh --from=NN` (número de etapa en `install/stages/`).

---

## 3. Qué reportarme al terminar

```bash
cat ~/.local/state/limitless/install.log | tail -80
```

Y el resultado de `dotctl doctor` (la última etapa lo corre sola) — dime cualquier fallo o aviso antes de asumir que es inofensivo.

---

## 4. Criterios de cierre — reinicia primero

### 4.1 El submenú de instantáneas en GRUB

Debe verse con la paleta Limitless y una entrada **«Arch Linux snapshots»**, con al menos una instantánea `limitless: preflight`.

Si no aparece: `sudo systemctl status grub-btrfsd`.

### 4.2 LightDM arranca, con el tema

Deberías ver el greeter tematizado (cristal, campo de colisión, la paleta), con dos sesiones para elegir: **Hyprland Limitless** y **XFCE**.

Si en vez de eso ves una pantalla en blanco, gris, o LightDM no aparece: `journalctl -u lightdm -b --no-pager | tail -60` y pégamelo — es exactamente el tipo de fallo silencioso que ya tuvimos con Plymouth, así que quiero verlo antes de suponer nada.

### 4.3 Ambas sesiones arrancan

Prueba las dos, en este orden:

1. **Hyprland Limitless** — el sistema completo: barra, dock, launcher, cristal, tu paleta. Si algo no coincide con el mockup, dime específicamente qué.
2. **XFCE** — la red de emergencia. Solo confirma que arranca; no hace falta que la uses.

### 4.4 `Ctrl+Alt+F2` → `dev/minimal.conf`, el último respaldo

```bash
Hyprland -c ~/.limitless/dev/minimal.conf
```

Si el shell completo alguna vez falla, este archivo de 30 líneas sin adornos debe arrancar igual. Es el diagnóstico de 30 segundos: si esto arranca, el problema es tu configuración, no el sistema.

---

## 5. Cuando todo pase

El sistema está desplegado. A partir de aquí, cualquier cambio vuelve a ser trabajo de construcción en el repo — nunca se reinstala desde cero para iterar, se usa `dotctl update` (`plan-automation.md` §6) sobre el sistema ya desplegado.
