# Runbook — Fase 0: Terreno

> Procedimiento exacto para ejecutar en la máquina real de CachyOS. Yo no tengo acceso a esa máquina — todo lo de aquí abajo lo corres tú, y me pegas la salida si algo falla.

---

## -1. Doble arranque, mismo disco

Dos cosas antes de empezar, porque tu Linux vive junto a este Windows en la misma máquina:

**No tengo acceso remoto a tu CachyOS.** No hay SSH entre nosotros — el flujo es: reinicias a Linux, ejecutas los comandos ahí, y vuelves a Windows para traerme el resultado. Cada paso de verificación de este runbook implica ese ir y venir; lo digo aquí para que no te sorprenda a mitad.

**Un atajo para no copiar todo a mano:** como es el mismo disco, es muy probable que CachyOS monte tu partición de Windows (NTFS) automáticamente, o que puedas montarla con un `mount` simple. Compruébalo una vez estés en CachyOS con:

```bash
lsblk -f
findmnt -t ntfs3,ntfs
```

Si aparece montada (por ejemplo en `/mnt/windows` o similar — no asumas la ruta, compruébala), puedes volcar los logs ahí desde Linux:

```bash
cp ~/.local/state/limitless/install.log /ruta/de/montaje/install.log
```

y yo lo leo directo la próxima vez que arranques Windows, sin que transcribas nada a mano.

**Sobre el propio GRUB:** revisé el código de `60-session.sh` antes de escribir esto — solo toca `GRUB_THEME` y la paleta de colores del VT en `/etc/default/grub`. Nunca toca `GRUB_DISABLE_OS_PROBER` ni nada que afecte cómo GRUB detecta Windows. Tu entrada de Windows en el menú de arranque sigue ahí, solo hereda el mismo estilo visual que el resto.

---

## 0. Antes de nada: qué vas a instalar realmente

El instalador está organizado **por tipo de cambio** (paquetes, servicios, dotfiles, tema, sesión, shell, TUI, verificación), no por fase de diseño. Eso significa que ejecutar `install.sh` completo hace dos cosas a la vez:

1. Cubre por completo la Fase 0 (red de seguridad + `dev/minimal.conf` verificable).
2. **De paso, adelanta casi toda la Fase 2** — zsh, Neovim, Starship, Ghostty, btop, lazygit, yazi, etc. — porque esas etapas ya están escritas y no tiene sentido separarlas artificialmente.

Lo que **no** instala todavía, porque no existe como código: `hyprland.lua` real (hoy solo está `dev/minimal.conf`, el de rescate) y el shell de QuickShell. Eso es la Fase 1 y la Fase 4, y vienen después.

Nada de esto es irreversible sin salida: la etapa `00-preflight` crea una instantánea Btrfs **antes** de tocar cualquier paquete, y cada etapa posterior es idempotente — puedes parar, reiniciar, y volver a correr `./install.sh` sin duplicar trabajo.

---

## 1. Pre-vuelo (2 minutos)

Desde la sesión actual en tu CachyOS (TTY o lo que estés usando ahora):

```bash
# confirma dónde estás parado — debería decir btrfs, ya lo verificamos antes
findmnt -no FSTYPE /

# confirma que tienes red
ping -c1 archlinux.org
```

Si el sistema de archivos no dice `btrfs`, para aquí y avísame — cambia la Capa 2 de la red de seguridad (`LIMITLESS-OS.md` §1, Capa 2b) y hay que ajustar el plan antes de seguir.

---

## 2. Clonar y ejecutar

```bash
git clone https://github.com/<tu-usuario>/<tu-repo>.git ~/.limitless
cd ~/.limitless
./install.sh
```

Qué vas a ver: `install.sh` instala `gum` si falta (único paso fuera de una etapa numerada), y después el banner de bienvenida con una confirmación. Contesta que sí y las 10 etapas corren en orden, cada una con su spinner y su resultado.

**Si algo falla a mitad:** el instalador pregunta si quieres continuar con la siguiente etapa. Di que sí salvo que el fallo te preocupe — cada etapa es independiente y una etapa AUR rota (§ etapa 20) nunca debe frenar el resto.

**Si quieres parar y reanudar más tarde:**

```bash
./install.sh --from=NN   # NN = el número de la etapa donde quieres retomar
```

(las etapas ya completadas antes de esa NN no se repiten; consulta `install/stages/` para los números)

---

## 3. Qué reportarme al terminar

Pégame la salida de esto, sea cual sea el resultado:

```bash
cat ~/.local/state/limitless/install.log | tail -80
```

Y si `dotctl doctor` (la última etapa lo ejecuta sola) marcó algún fallo o aviso, dime cuáles — la mayoría se resuelven con un `paru -S <paquete>` suelto, pero prefiero verlos antes de que asumas que son inofensivos.

---

## 4. Los dos criterios de cierre de la Fase 0

No des la Fase 0 por terminada hasta comprobar esto — **reinicia primero**:

### 4.1 El submenú de instantáneas en GRUB

Al arrancar, antes de que cargue el sistema, deberías ver el menú de GRUB con la paleta Limitless (si `60-session` corrió bien) y una entrada **«Arch Linux snapshots»**. Entra ahí y confirma que aparece al menos una instantánea con la descripción `limitless: preflight`.

Si no aparece el submenú: `sudo systemctl status grub-btrfsd` y pégame la salida.

### 4.2 `dev/minimal.conf` arranca de verdad

Desde un TTY (`Ctrl+Alt+F2` si estás en una sesión gráfica, o directamente si sigues en consola):

```bash
Hyprland -c ~/.limitless/dev/minimal.conf
```

Debería abrir un compositor sin adornos —sin blur, sin animaciones, gaps mínimos— con un terminal ya abierto (`ghostty`, o su respaldo si `ghostty` no está). Prueba `SUPER+RETURN` para otro terminal y `SUPER+SHIFT+E` para salir.

**Si esto arranca:** la Fase 0 está cerrada. Cualquier fallo futuro del shell real (Fase 1 en adelante) será de tu configuración, no del sistema — el diagnóstico de 30 segundos que se buscaba desde el principio.

**Si esto NO arranca:** el problema es del sistema base, no de una config. En ese caso:
1. `journalctl -b -p err | tail -40` y pégamelo.
2. Como último recurso, reinicia y entra a la instantánea anterior desde el submenú de GRUB del paso 4.1.

---

## 5. Cuando ambos criterios pasen

Dímelo y arrancamos la Fase 1: `hyprland.lua` de verdad, bloque a bloque — el primer archivo Lua real del proyecto, y el único punto donde voy a verificar la sintaxis de Hyprland 0.56 línea a línea contra el wiki en vivo antes de escribir nada, en vez de reutilizar lo que ya sé de memoria (que es exactamente lo que hice con `minimal.conf`, y por lo que ese archivo se quedó en hyprlang).
