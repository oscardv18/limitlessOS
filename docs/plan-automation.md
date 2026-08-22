# Capa de sistema: automatización y scripts

> Complemento de `docs/plan.md`. Este documento cubre lo que convierte una carpeta de configs en un **sistema de dotfiles** al estilo Omarchy/ML4W.
> Escrito tras revisar la arquitectura real de Omarchy 3 (fuentes al final), no de memoria.

---

## 1. Qué hace Omarchy realmente (y qué de eso te sirve)

Omarchy 3 es una **distribución**, no unos dotfiles: paquetea a `/usr/share/omarchy`, siembra config vía `/etc/skel`, tiene su propio mirror de Arch y un proceso de release versionado. Tú tienes una máquina y eres a la vez el autor y el único usuario. Copiar su maquinaria entera sería sobreingeniería pura.

Lo valioso son **los patrones**. Los ordeno por lo que te aportan a ti:

| Patrón de Omarchy | ¿Te sirve? | Por qué |
|---|---|---|
| **Migraciones con timestamp** | ✅ Sí, es la joya | Scripts en `migrations/`, nombrados con timestamp Unix, ejecutados en orden. El estado vive en `~/.local/state/…/migrations/`: si el nombre del script ya está ahí, no se vuelve a ejecutar. Idempotencia sin base de datos |
| **Router de comandos con metadatos** | ✅ Sí, y más de lo que parece | Un solo binario escanea las cabeceras de los scripts y construye `omarchy capture screenshot`. La ayuda y el menú **se generan de los scripts**, no se mantienen aparte |
| **Pares `refresh-*` / `restart-*`** | ✅ Sí | `refresh-` reescribe la config, `restart-` recarga el componente. Separados, porque no siempre quieres las dos cosas |
| **Snapshot antes de actualizar** | ✅ Sí, y es barato | Snapshot Btrfs vía `snapper` antes de tocar paquetes, integrado en el bootloader. **CachyOS ya viene con Btrfs + snapper + limine configurados**, así que esto es casi gratis para ti |
| **Ficheros de estado pequeños** | ✅ Sí | Un valor por archivo en `~/.local/state/`. Sin daemon, sin parseo, `cat`-eable |
| **Menú jerárquico de teclado** | ✅ Sí — y aquí está tu oportunidad (§4) | El `omarchy-menu` es su interfaz central |
| **Instalador de webapps** | ✅ Sí, alto valor por poco código | Convierte una web en app de escritorio: `chromium --app=URL` + un `.desktop` generado |
| **Comprobaciones previas al update** | ✅ Sí | Lock con `flock` contra ejecuciones concurrentes, verificación de espacio en disco, log completo |
| **Config en capas (`default/` + override)** | ⚠️ **No lo necesitas** | Ver §2 — es la trampa más fácil de este plan |
| Mirror propio de paquetes, `/etc/skel`, releases versionadas | ❌ No | Maquinaria de distribuir a terceros |
| Multi-distro (lo de ML4W: Arch + Fedora + openSUSE) | ❌ No | Es lo que hace que el instalador de ML4W sea enorme y frágil. Tú tienes CachyOS |

De **ML4W** lo que merece la pena robar es una sola idea: **la app gráfica de ajustes**, que te deja tocar blur, rounding, gaps o tema sin abrir un editor. En tu proyecto eso no es una app GTK aparte — es un panel HUD más en QuickShell, con los tokens del v12. Lo que **no** hay que robar de ML4W es el theming material derivado del wallpaper: ya lo descartamos en `plan.md` §5, porque destruiría tu paleta de identidad.

---

## 2. La trampa: la configuración en capas

Omarchy separa `default/` (lo que él mantiene) de `~/.config/` (lo que tú tocas), y `refresh-*` copia de uno a otro. Es una arquitectura excelente… **para resolver un problema que tú no tienes**: Omarchy publica actualizaciones a miles de usuarios y no puede pisarles sus ediciones.

En tu caso, **tú eres el upstream y el usuario a la vez**. Con stow, editar `~/.config/hypr/hyprland.conf` *es* editar el repo, porque es un symlink. Meter una capa de defaults te obligaría a editar en un sitio y probar en otro, que es precisamente la fricción que stow elimina.

**Recomendación: capa única con stow.** Con **una** excepción, que sí conviene desde el día 1:

```
stow/hypr/.config/hypr/
├── hyprland.conf          # versionado
│     source = conf/*.conf
│     source = local.conf   # <- si existe
└── conf/…                 # versionado
~/.config/hypr/local.conf  # NO versionado (.gitignore): monitores, GPU, cosas de esta máquina
```

Eso te cuesta dos líneas y te resuelve el día que tengas un segundo equipo o un monitor externo distinto — sin construir un sistema de capas completo. Si algún día publicas los dotfiles para otros, **entonces** adoptas el modelo `default/` de Omarchy. No antes.

---

## 3. Arquitectura de `dotctl`

Un binario router + un script por comando. El router no contiene lógica: localiza, lee metadatos y delega.

```
bin/
├── dotctl                    # router (~80 líneas de bash)
└── cmd/
    ├── theme-set             ├── capture-screenshot    ├── update
    ├── theme-list            ├── capture-record        ├── migrate
    ├── theme-bg-next         ├── pkg-install           ├── snapshot-create
    ├── focus-set             ├── pkg-search            ├── doctor
    ├── refresh-hypr          ├── pkg-sync              ├── state
    ├── restart-shell         ├── webapp-install        └── menu-json
```

**Cabecera de metadatos.** Cada script se autodescribe en sus primeras líneas, con el formato `# <ns>:<clave>=<valor>` que usa Omarchy de verdad:

```bash
#!/usr/bin/env bash
# dot:group=style
# dot:summary=Aplica un tema y recolorea shell, GTK, Qt y terminal
# dot:glyph=◈
# dot:args=<nombre-tema>
# dot:requires-sudo=false
# dot:terminal=false
set -euo pipefail
```

De aquí salen **tres cosas a la vez, sin duplicar nada**: `dotctl help`, el autocompletado de bash/zsh, y el JSON que alimenta el menú HUD (§4). Añadir un comando = crear un archivo. Nada más que tocar.

Dos claves que parecen menores y no lo son, ambas copiadas de Omarchy:

- **`requires-sudo`** — el router se encarga del sudo de forma centralizada (incluido mantener viva la sesión durante compilaciones largas de AUR) en vez de que cada script lo resuelva a su manera.
- **`terminal`** — declara si el comando necesita una ventana de terminal visible. El menú HUD lo lee y decide si lanzarlo en silencio o abrir un terminal flotante. Es lo que permite que instalar paquetes y cambiar un color convivan en el mismo árbol de menú (ver [`spec-package-panel.md`](spec-package-panel.md)).

**Invocación.** `dotctl theme set liquid-void` → `bin/cmd/theme-set liquid-void`. El router prueba de más específico a más genérico (`theme-set-bg` antes que `theme-set`), igual que el enrutado de Omarchy.

**Por qué esto importa más de lo que parece:** los keybinds de Hyprland llaman a `dotctl …`, nunca a un script directamente. Puedes reorganizar, renombrar o reescribir cualquier cosa por dentro sin tocar `keybinds.conf` jamás.

---

## 4. La integración que ni Omarchy ni ML4W tienen

Aquí es donde tu proyecto puede superar a los dos, y sale de combinar dos cosas que ya tienes decididas:

- Omarchy genera su menú desde los metadatos de los scripts, pero lo pinta con un launcher genérico.
- Tú vas a tener un shell QuickShell propio con un lenguaje visual HUD muy definido.

**Junta las dos:** `dotctl menu --json` emite el árbol de comandos leído de las cabeceras, y el panel HUD de QuickShell lo consume y lo dibuja con tus tokens — reutilizando el componente de búsqueda difusa del launcher y los glifos del §2 de `plan.md`.

Resultado: **escribes un script nuevo con su cabecera y aparece solo en el menú del sistema**, con su glifo, su categoría y su búsqueda, sin tocar una línea de QML. El menú deja de ser algo que mantienes y pasa a ser un reflejo de `bin/cmd/`.

Es la misma idea que hace bueno al `omarchy-menu`, pero con presentación propia en vez de prestada. Y encaja exactamente con el `SUPER+I` de instalación de paquetes que ya querías: deja de ser un panel especial y pasa a ser *una rama más* del mismo árbol.

---

## 5. Migraciones

El mecanismo, adaptado: scripts en `migrations/<timestamp>-<slug>.sh`, ejecutados en orden por nombre; cada uno que termina bien deja su marca en `~/.local/state/hyprdots/migrations/`; los ya marcados no se repiten. Si uno falla, `dotctl update` pregunta (con `gum`) si saltarlo o abortar.

```bash
# migrations/1756000000-waybar-retired.sh
#: desc: Retira Waybar tras completar la barra en QuickShell
[[ -d ~/.config/waybar ]] || exit 0
pacman -Qq waybar &>/dev/null && sudo pacman -Rns --noconfirm waybar
rm -rf ~/.config/waybar
```

**Seamos honestos sobre el valor real en una sola máquina:** el 90% del beneficio de las migraciones es para actualizar equipos ajenos. En tu caso sirven para dos cosas concretas y reales — reinstalar limpio sin arrastrar basura, y **el propio recorrido de este plan**, que está lleno de retiradas (Waybar en la Fase 4, mako, swayosd, renombrados de temas). Cada una de esas es una migración natural.

Regla para no sobrecargarte: **escribe una migración sólo cuando un cambio rompa un `stow` limpio o deje residuos.** Un cambio de color no es una migración. Renombrar `themes/liquid-blue/` a `themes/hud-void/` sí.

---

## 6. `dotctl update` y `dotctl doctor`

**`update`** — la secuencia, copiada de Omarchy porque su orden está bien pensado:

```
flock (evita updates concurrentes)
  → comprobar espacio libre en disco
  → snapshot Btrfs con snapper   ← el paso que convierte "romper el sistema" en "reiniciar y elegir el snapshot anterior"
  → git pull
  → stow --restow
  → dotctl migrate
  → pacman -Syu + yay + limpiar huérfanos
  → dotctl refresh-*  →  dotctl restart-*
  → log completo en /tmp/dotctl-update.log
```

El snapshot es la pieza que más te va a salvar y la más barata: CachyOS ya trae Btrfs con snapper y el bootloader integrado. Son ~15 líneas de script.

**`doctor`** — diagnóstico, y el comando que más veces vas a usar. Debe comprobar:

| Comprobación | Por qué |
|---|---|
| Paquetes de `packages/*.txt` faltantes | Detecta que instalaste algo a mano y no lo anotaste |
| Symlinks de stow rotos o no aplicados | El fallo más común, y silencioso |
| **Versión de Hyprland vs. la fijada para los plugins** | Los plugins rompen en cada actualización de Hyprland. Este es el aviso más valioso de todo `doctor` |
| Migraciones pendientes | Por si actualizaste con `pacman` a secas |
| `quickshell`, `hypridle`, `hyprpaper` corriendo | Servicios caídos sin que te hayas dado cuenta |
| Hex literales fuera de `themes/` | Hace cumplir la regla dura de `plan.md` §5 |
| `qmllint` + `shellcheck` en verde | Errores de sintaxis antes de que te dejen sin barra |

Las tres últimas son tuyas, no de Omarchy, y son las que mantienen la coherencia del proyecto a lo largo del tiempo.

---

## 7. Scripts de alto valor por poco código

| Comando | Qué hace | Nota |
|---|---|---|
| `webapp-install <url> <nombre> <glifo>` | Genera un `.desktop` con `chromium --app=URL` e icono glífico | Directo de Omarchy. Te da "apps" nativas de cualquier web y encaja perfecto con la estética de glifos del v12 |
| `pkg-sync` | Compara `pacman -Qqe` con `packages/*.txt` y te ofrece añadir lo que falta o desinstalar lo que sobra | El manifiesto se mantiene solo en vez de pudrirse |
| `capture-screenshot` / `capture-record` | `grim`+`slurp`+`satty` / `wf-recorder`, con indicador en la barra HUD mientras graba | El indicador es el detalle que lo hace sentir integrado |
| `focus-set work\|deep\|off` | Silencia notificaciones, inhibe idle, oculta el dock, atenúa el fondo | Sólo posible controlando todo el shell |
| `theme-set` | Escribe `theme.toml` → matugen → refresh → restart de cada componente | El `refresh`/`restart` por separado es lo que evita parpadeos |
| `state <clave> [valor]` | Lee/escribe `~/.local/state/hyprdots/<clave>` | Base de todos los toggles. 10 líneas |

---

## 8. Qué construir y cuándo

El riesgo evidente de este documento es el scope creep: es fácil pasarse tres semanas construyendo tooling y cero minutos usando el escritorio. Reparto:

**Mínimo viable — Fase 0/1 (una tarde, no negociable):**
`dotctl` router + cabeceras de metadatos, `state`, `doctor` (versión básica: paquetes + symlinks), `install.sh` idempotente. Sin esto, todo lo demás se construye torcido.

**Fase 2 (cuando el escritorio ya se usa):**
`capture-*`, `theme-set`, `pkg-install`, `refresh-*`/`restart-*`, `snapshot-create`, `update` con snapshot.

**Fase 4 (con QuickShell en marcha):**
`menu-json` + el panel HUD de menú (§4). Aquí es donde el tooling deja de ser scripts y se vuelve interfaz.

**Fase 5:**
`migrate`, `webapp-install`, `focus-set`, `pkg-sync`, `doctor` completo.

Las migraciones van deliberadamente tarde: hasta la Fase 4 el repo cambia de forma tan a menudo que versionar cada cambio sería ruido. El momento de empezar a migrar en serio es **cuando retires Waybar** — y ésa, apropiadamente, es la primera migración de verdad que vas a escribir.

---

## Fuentes

- [basecamp/omarchy](https://github.com/basecamp/omarchy) — estructura del repositorio
- [Configuration Management and Migrations — DeepWiki](https://deepwiki.com/basecamp/omarchy/10-configuration-management-and-migrations)
- [Update System — DeepWiki](https://deepwiki.com/basecamp/omarchy/6.4-update-system)
- [Omarchy — DeepWiki (arquitectura general)](https://deepwiki.com/basecamp/omarchy)
- [Updates — The Omarchy Manual](https://omarchy.org/manual/updates/)
- [mylinuxforwork/dotfiles (ML4W)](https://github.com/mylinuxforwork/dotfiles) · [ML4W OS](https://ml4w.com/os/)
