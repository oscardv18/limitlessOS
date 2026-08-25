// modules/Field.qml — CAMPO DE COLISIÓN 蒼 + 赫 → 茈
// (plan.md §3.5b, LIMITLESS-OS.md §6 Fase 4)
//
// Port fiel del motor de docs/mockups/limitless-shell.html (createField,
// líneas 1504-1690). Un solo motor, tres intensidades — "un archivo, tres
// configuraciones", exactamente como pide plan.md §3.5b. No son tres
// componentes.
//
// Qué dibuja: un cerebro de nodos (esfera de Fibonacci proyectada en 3D,
// rotando en dos ejes), dos grafos laterales que le disparan energía, y un
// núcleo donde esa energía colisiona.
//
// LA REGLA DE COLOR, que es el alma de esto: el degradado azul→morado→rojo
// NO está pintado. Cada arista se tiñe según su posición horizontal — azul
// a la izquierda, rojo a la derecha, morado al cruzar el centro. Es
// 蒼 + 赫 → 茈 emergiendo de la geometría. Si alguna vez alguien lo
// "simplifica" a un gradiente lineal, habrá perdido el punto entero.
//
// ── por qué Canvas y no ShaderEffect ────────────────────────────────────
// plan.md §3.5 recomienda ShaderEffect (opción A) sobre Canvas (opción B,
// "la peor opción para batería"). Esa tabla se escribió para el campo de
// ESTRELLAS que este motor sustituyó — ruido procedural, que un fragment
// shader borda. Esto es otra cosa: geometría real (grafo de aristas,
// proyección 3D, partículas con estado). Rehacerlo en GLSL puro es
// raymarching, no una traducción — y es justo el "spike del shader" que
// LIMITLESS-OS.md §6 deja para la Fase 6 CON perfilado en hardware real.
// Traducir a Canvas es lo que se puede verificar hoy contra el mockup;
// el shader es una optimización posterior con datos, no una suposición.
//
// ⚠ ADVERTENCIA DE RENDIMIENTO — LEER ANTES DE TOCAR ESTE ARCHIVO ⚠
// La documentación de Qt sobre Canvas dice, literalmente, que "large
// canvases, frequent updates, and animation should be avoided with the
// Canvas.Image render target" — y en Qt 6 `Canvas.FramebufferObject` se
// IGNORA, así que Canvas.Image es el único destino que existe. Un canvas
// a pantalla completa animado es exactamente el caso que esa frase
// desaconseja: cada frame se vuelve a subir la textura entera a la GPU.
//
// Mitigaciones REALES aplicadas (no promesas):
//   · renderScale — se pinta a resolución reducida y se escala al mostrar.
//     Es la palanca grande: a 0.5 el coste de subida baja ~4×, y el campo
//     es difuso y luminoso, no tiene detalle fino que perder.
//   · fps configurable — el preset ambiente va a 24, no a 60
//   · renderStrategy Threaded: no pinta en el hilo de la interfaz
//   · running:false cuando la superficie no se ve (lo controla quien lo usa)
//   · bin/cmd/power-profile baja el blur del compositor al desenchufar
//
// PENDIENTE DE HARDWARE: nada de esto está MEDIDO. Si en la máquina real
// el campo cuesta demasiado, las tres salidas por orden de esfuerzo son
// (1) bajar renderScale a 0.35 y fps a 15, (2) usar el preset `wallpaper`
// con brainN menor, (3) el spike del shader de la Fase 6. La primera se
// hace sin tocar código.
import QtQuick

Item {
    id: root

    // ── presets, verbatim del mockup (PRESETS, líneas 1513-1531) ────────
    // Cambiar estos números cambia el carácter del campo; están medidos
    // en el prototipo, no elegidos a ojo.
    readonly property var presets: ({
        wallpaper: {
            brainN: 52,  brainR: 0.30, brainA: 0.30, rot: 0.0016, edge: 0.52, dotA: 0.34,
            sideN: 9,    sideA: 0.20,  sideSpread: 0.52,
            flowA: 0.24, flowSpMin: 0.0012, flowSpMax: 0.0022,
            coreS: 0.040, coreA: 0.30, rings: false, fields: 0.55, glow: false
        },
        // `lock` está SIN USAR, y a propósito: la pantalla de bloqueo es
        // hyprlock, un binario aparte que no puede ejecutar QML. Usa una
        // captura desenfocada (stow/hypr/.config/hypr/hyprlock.conf), que
        // es lo más cercano que su formato declarativo permite.
        // Se conserva el preset porque el día que el bloqueo se haga con
        // QuickShell (hay proyectos que lo hacen con `WlSessionLock`) esto
        // es exactamente lo que hará falta, ya medido en el prototipo.
        lock: {
            brainN: 76,  brainR: 0.26, brainA: 0.42, rot: 0.0024, edge: 0.48, dotA: 0.5,
            sideN: 15,   sideA: 0.34,  sideSpread: 0.66,
            flowA: 0.36, flowSpMin: 0.0016, flowSpMax: 0.0032,
            coreS: 0.048, coreA: 0.34, rings: true,  fields: 0.75, glow: true
        },
        saver: {
            brainN: 120, brainR: 0.19, brainA: 1.0,  rot: 0.0034, edge: 0.46, dotA: 1.0,
            sideN: 26,   sideA: 1.0,   sideSpread: 1.0,
            flowA: 1.0,  flowSpMin: 0.0022, flowSpMax: 0.0064,
            coreS: 0.062, coreA: 1.0,  rings: true,  fields: 1.0, glow: true
        }
    })

    property string preset: "wallpaper"
    readonly property var p: root.presets[root.preset] || root.presets.wallpaper

    property bool running: true
    property int fps: 24            // ambiente: 24 basta y cuesta menos de la mitad que 60
    property bool opaqueBackground: true

    // Resolución interna de pintado, como fracción de la real. Ver la
    // advertencia de rendimiento de la cabecera: esta es la palanca que
    // más baja el coste, y la que menos se nota en un campo difuso.
    property real renderScale: 0.5

    // Los colores salen del tema, nunca a mano. `purple` y `core` son
    // fijos (茈 es 茈 aunque la técnica activa sea otra) — el campo ES el
    // choque de las tres técnicas, no un reflejo de la activa.
    readonly property color colBlue: Theme.lapseAccent
    readonly property color colRed: Theme.reversalAccent
    readonly property color colPurple: Theme.hollowAccent
    readonly property color colCore: Theme.sixEyes
    readonly property color colVoid: Theme.void_

    property int _t: 0
    property var _nodes: []
    property var _edges: []
    property var _lateral: []
    property var _flows: []
    property var _pulses: []

    onPresetChanged: root._build()

    // ── construcción de la geometría (build(), línea 1552) ──────────────
    // Trabaja en coordenadas del CANVAS, no del Item: el canvas pinta a
    // resolución reducida (renderScale) y se escala al mostrarse, así que
    // toda la geometría debe calcularse en ese espacio o el campo saldría
    // descentrado y del tamaño equivocado.
    function _build() {
        var W = canvas.width, H = canvas.height
        if (W <= 0 || H <= 0) return
        var P = root.p
        var R = Math.min(W, H) * P.brainR

        // esfera de Fibonacci: reparte N puntos uniformemente sobre una
        // esfera sin agruparlos en los polos, que es lo que pasaría con
        // lat/lon ingenuo.
        var nodes = []
        var i, j
        for (i = 0; i < P.brainN; i++) {
            var k = i + 0.5
            var phi = Math.acos(1 - 2 * k / P.brainN)
            var th = Math.PI * (1 + Math.sqrt(5)) * k
            nodes.push({
                x: Math.cos(th) * Math.sin(phi),
                y: Math.cos(phi),
                z: Math.sin(th) * Math.sin(phi),
                R: R,
                pulse: Math.random() * Math.PI * 2
            })
        }

        // aristas: solo entre nodos suficientemente cercanos. O(n²) pero
        // se calcula una vez por resize, no por frame.
        var edges = []
        for (i = 0; i < nodes.length; i++) {
            for (j = i + 1; j < nodes.length; j++) {
                var a = nodes[i], b = nodes[j]
                var dx = a.x - b.x, dy = a.y - b.y, dz = a.z - b.z
                var d = Math.sqrt(dx * dx + dy * dy + dz * dz)
                if (d < P.edge) edges.push([i, j, d])
            }
        }

        // grafos laterales: dos nubes, izquierda (蒼) y derecha (赫)
        function mk(side) {
            var arr = []
            for (var n = 0; n < P.sideN; n++) {
                var ang = (n / P.sideN) * Math.PI * 2 + Math.random() * 0.4
                var rad = (0.14 + Math.random() * 0.30) * Math.min(W, H) * P.sideSpread
                arr.push({
                    side: side,
                    bx: side * (W * 0.31) + Math.cos(ang) * rad * 0.62,
                    by: Math.sin(ang) * rad * 0.72,
                    ph: Math.random() * Math.PI * 2,
                    sp: 0.3 + Math.random() * 0.7,
                    r: 0.8 + Math.random() * 1.9,
                    px: undefined, py: undefined
                })
            }
            return arr
        }
        var lateral = mk(-1).concat(mk(1))

        var flows = []
        for (i = 0; i < lateral.length; i++) {
            flows.push({
                from: lateral[i],
                p: Math.random(),
                sp: P.flowSpMin + Math.random() * (P.flowSpMax - P.flowSpMin)
            })
        }

        root._nodes = nodes
        root._edges = edges
        root._lateral = lateral
        root._flows = flows
        root._pulses = []
    }

    function reseed() {
        root._t = 0
        root._pulses = []
        root._build()
    }

    Timer {
        running: root.running && root.visible && canvas.width > 0
        interval: Math.max(8, Math.round(1000 / Math.max(1, root.fps)))
        repeat: true
        onTriggered: {
            root._t += 1
            canvas.requestPaint()
        }
    }

    Canvas {
        id: canvas

        // pintado a resolución reducida y escalado al mostrar — ver la
        // advertencia de rendimiento de la cabecera del archivo
        width: Math.max(1, Math.round(root.width * root.renderScale))
        height: Math.max(1, Math.round(root.height * root.renderScale))
        transform: Scale {
            xScale: root.renderScale > 0 ? 1 / root.renderScale : 1
            yScale: root.renderScale > 0 ? 1 / root.renderScale : 1
        }
        // suavizar al ampliar: sin esto el escalado se ve pixelado y
        // delataría el truco
        smooth: true
        antialiasing: true

        // fuera del hilo de la interfaz: un frame lento del campo no debe
        // atascar el resto del shell.
        // (renderTarget NO se fija: en Qt 6 Canvas.FramebufferObject se
        // ignora y Canvas.Image es el único destino real — ponerlo solo
        // daría una falsa sensación de estar optimizando algo.)
        renderStrategy: Canvas.Threaded

        // la geometría depende del tamaño del canvas, no del Item
        onWidthChanged: root._build()
        onHeightChanged: root._build()
        Component.onCompleted: root._build()

        onPaint: {
            var ctx = getContext("2d")
            if (!ctx) return
            var P = root.p
            var W = width, H = height
            if (W <= 0 || H <= 0) return
            var cxp = W / 2, cyp = H / 2
            var t = root._t
            var i

            ctx.reset()
            ctx.clearRect(0, 0, W, H)
            if (root.opaqueBackground) {
                ctx.fillStyle = root.colVoid
                ctx.fillRect(0, 0, W, H)
            }

            // ── campos laterales: dos halos radiales ────────────────────
            var sides = [[-1, root.colBlue], [1, root.colRed]]
            for (i = 0; i < 2; i++) {
                var sd = sides[i][0], sc = sides[i][1]
                var g = ctx.createRadialGradient(cxp + sd * W * 0.30, cyp, 0,
                                                 cxp + sd * W * 0.30, cyp, W * 0.34)
                g.addColorStop(0, Qt.rgba(sc.r, sc.g, sc.b, 0.13))
                g.addColorStop(1, "transparent")
                ctx.globalAlpha = P.fields
                ctx.fillStyle = g
                ctx.fillRect(0, 0, W, H)
            }
            ctx.globalAlpha = 1

            // ── grafos laterales ───────────────────────────────────────
            ctx.lineWidth = 0.7
            var lat = root._lateral
            for (i = 0; i < lat.length; i++) {
                var n = lat[i]
                var col = n.side < 0 ? root.colBlue : root.colRed
                n.px = cxp + n.bx + Math.sin(t * 0.006 * n.sp + n.ph) * 14
                n.py = cyp + n.by + Math.cos(t * 0.005 * n.sp + n.ph) * 11

                var nx = lat[i + 1]
                if (nx && nx.side === n.side && nx.px !== undefined) {
                    ctx.globalAlpha = P.sideA * 0.19
                    ctx.strokeStyle = col
                    ctx.beginPath()
                    ctx.moveTo(n.px, n.py)
                    ctx.lineTo(nx.px, nx.py)
                    ctx.stroke()
                }
                ctx.globalAlpha = P.sideA * (0.5 + 0.5 * Math.abs(Math.sin(t * 0.02 * n.sp + n.ph)))
                ctx.fillStyle = col
                ctx.beginPath()
                ctx.arc(n.px, n.py, n.r, 0, 6.2832)
                ctx.fill()
            }
            ctx.globalAlpha = 1

            // ── flujos hacia el centro ─────────────────────────────────
            var flows = root._flows
            for (i = 0; i < flows.length; i++) {
                var f = flows[i]
                f.p += f.sp
                if (f.p > 1) {
                    f.p = 0
                    if (P.rings) root._pulses.push({ r: 0, a: 1, side: f.from.side })
                }
                var fn = f.from
                if (fn.px === undefined) continue
                var e = 1 - Math.pow(1 - f.p, 2.2)
                var x = fn.px + (cxp - fn.px) * e
                var y = fn.py + (cyp - fn.py) * e
                // al acercarse al centro vira a morado: la colisión
                ctx.strokeStyle = f.p > 0.8 ? root.colPurple
                                : (fn.side < 0 ? root.colBlue : root.colRed)
                ctx.globalAlpha = P.flowA * (0.16 + f.p * 0.5)
                ctx.lineWidth = 0.6 + f.p * 1.2
                var e0 = Math.max(0, e - 0.06)
                ctx.beginPath()
                ctx.moveTo(fn.px + (cxp - fn.px) * e0, fn.py + (cyp - fn.py) * e0)
                ctx.lineTo(x, y)
                ctx.stroke()
            }
            ctx.globalAlpha = 1

            // ── el cerebro: proyección 3D ──────────────────────────────
            var ry = t * P.rot
            var rx = Math.sin(t * 0.0011) * 0.34
            var span = Math.min(W, H) * (P.brainR * 0.9)
            var nodes = root._nodes
            var proj = []
            for (i = 0; i < nodes.length; i++) {
                var nd = nodes[i]
                var x1 = nd.x * Math.cos(ry) - nd.z * Math.sin(ry)
                var z1 = nd.x * Math.sin(ry) + nd.z * Math.cos(ry)
                var y1 = nd.y * Math.cos(rx) - z1 * Math.sin(rx)
                z1 = nd.y * Math.sin(rx) + z1 * Math.cos(rx)
                var persp = 1 / (1.9 - z1 * 0.55)
                proj.push({
                    x: cxp + x1 * nd.R * persp * 1.5,
                    y: cyp + y1 * nd.R * persp * 1.5,
                    z: z1, persp: persp, pulse: nd.pulse
                })
            }

            // AQUÍ vive la regla: el color sale de la posición horizontal.
            function hue(mx) {
                var b = Math.max(-1, Math.min(1, (mx - cxp) / span))
                return b < -0.45 ? root.colBlue : (b > 0.45 ? root.colRed : root.colPurple)
            }

            var edges = root._edges
            for (i = 0; i < edges.length; i++) {
                var ed = edges[i]
                var pa = proj[ed[0]], pb = proj[ed[1]]
                if (!pa || !pb) continue
                var depth = (pa.z + pb.z) / 2
                ctx.globalAlpha = P.brainA * (0.06 + (depth + 1) * 0.16) * (1 - ed[2] / P.edge) * 1.4
                ctx.strokeStyle = hue((pa.x + pb.x) / 2)
                ctx.lineWidth = 0.55 + (depth + 1) * 0.35
                ctx.beginPath()
                ctx.moveTo(pa.x, pa.y)
                ctx.lineTo(pb.x, pb.y)
                ctx.stroke()
            }

            for (i = 0; i < proj.length; i++) {
                var pp = proj[i]
                var bb = Math.max(-1, Math.min(1, (pp.x - cxp) / span))
                ctx.globalAlpha = P.dotA * ((pp.z + 1) / 2)
                              * (0.55 + 0.45 * Math.abs(Math.sin(t * 0.016 + pp.pulse)))
                ctx.fillStyle = bb < -0.45 ? root.colBlue
                              : (bb > 0.45 ? root.colRed : root.colCore)
                ctx.beginPath()
                ctx.arc(pp.x, pp.y, 0.9 + pp.persp * 1.5, 0, 6.2832)
                ctx.fill()
            }
            ctx.globalAlpha = 1

            // ── núcleo: la colisión ────────────────────────────────────
            if (P.glow) ctx.globalCompositeOperation = "lighter"
            var cr = Math.min(W, H) * P.coreS * (1 + Math.sin(t * 0.026) * 0.09)
            var core = ctx.createRadialGradient(cxp, cyp, 0, cxp, cyp, cr * 3.6)
            core.addColorStop(0, Qt.rgba(1, 1, 1, 1))
            core.addColorStop(0.16, root.colCore)
            core.addColorStop(0.42, root.colPurple)
            core.addColorStop(1, "transparent")
            ctx.globalAlpha = P.coreA
            ctx.fillStyle = core
            ctx.beginPath()
            ctx.arc(cxp, cyp, cr * 3.6, 0, 6.2832)
            ctx.fill()

            // ── anillos de impacto ─────────────────────────────────────
            if (P.rings) {
                var alive = []
                for (i = 0; i < root._pulses.length; i++) {
                    var pu = root._pulses[i]
                    pu.r += 3.4
                    pu.a *= 0.955
                    if (pu.a <= 0.02) continue
                    alive.push(pu)
                    ctx.strokeStyle = pu.side < 0 ? root.colBlue : root.colRed
                    ctx.globalAlpha = pu.a * 0.5 * P.flowA
                    ctx.lineWidth = 1.1
                    ctx.beginPath()
                    ctx.arc(cxp, cyp, pu.r, 0, 6.2832)
                    ctx.stroke()
                }
                root._pulses = alive
            }

            ctx.globalCompositeOperation = "source-over"
            ctx.globalAlpha = 1
        }
    }
}
