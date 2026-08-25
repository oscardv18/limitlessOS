// system/lightdm/theme/field.js — el campo de colisión 蒼+赫→茈, a la misma
// intensidad "lock" ya calibrada en docs/mockups/limitless-shell.html
// (plan.md §3.5b). Versión autónoma de un solo preset: el greeter no
// necesita alternar entre fondo/bloqueo/salvapantallas como el shell.

function createField(canvas) {
  const cx = canvas.getContext('2d');
  let W = 0, H = 0, t = 0, nodes = [], edges = [], lateral = [], flows = [], pulses = [];

  const P = {
    brainN: 76, brainR: 0.26, brainA: 0.42, rot: 0.0024, edge: 0.48, dotA: 0.5,
    sideN: 15, sideA: 0.34, sideSpread: 0.66,
    flowA: 0.36, flowSp: [0.0016, 0.0032],
    coreS: 0.048, coreA: 0.34, rings: true, fields: 0.75,
  };

  const REDUCED = window.matchMedia && matchMedia('(prefers-reduced-motion: reduce)').matches;

  const css = (v) => getComputedStyle(document.documentElement).getPropertyValue(v).trim();
  const palette = () => ({
    blue: css('--lapse'), red: css('--reversal'),
    purple: css('--hollow'), core: css('--hollow-core'), void_: css('--void'),
  });

  function resize() {
    const dpr = Math.min(window.devicePixelRatio || 1, 2);
    W = window.innerWidth; H = window.innerHeight;
    canvas.width = W * dpr; canvas.height = H * dpr;
    canvas.style.width = W + 'px'; canvas.style.height = H + 'px';
    cx.setTransform(dpr, 0, 0, dpr, 0, 0);
    build();
  }

  function build() {
    const R = Math.min(W, H) * P.brainR;
    nodes = []; edges = [];
    for (let i = 0; i < P.brainN; i++) {
      const k = i + 0.5;
      const phi = Math.acos(1 - (2 * k) / P.brainN);
      const th = Math.PI * (1 + Math.sqrt(5)) * k;
      nodes.push({
        x: Math.cos(th) * Math.sin(phi), y: Math.cos(phi), z: Math.sin(th) * Math.sin(phi),
        R, pulse: Math.random() * Math.PI * 2,
      });
    }
    for (let i = 0; i < nodes.length; i++) {
      for (let j = i + 1; j < nodes.length; j++) {
        const a = nodes[i], b = nodes[j];
        const d = Math.hypot(a.x - b.x, a.y - b.y, a.z - b.z);
        if (d < P.edge) edges.push([i, j, d]);
      }
    }
    const mk = (side) =>
      Array.from({ length: P.sideN }, (_, i) => {
        const ang = (i / P.sideN) * Math.PI * 2 + Math.random() * 0.4;
        const rad = (0.14 + Math.random() * 0.3) * Math.min(W, H) * P.sideSpread;
        return {
          side, bx: side * (W * 0.31) + Math.cos(ang) * rad * 0.62, by: Math.sin(ang) * rad * 0.72,
          ph: Math.random() * Math.PI * 2, sp: 0.3 + Math.random() * 0.7, r: 0.8 + Math.random() * 1.9,
        };
      });
    lateral = [...mk(-1), ...mk(1)];
    flows = lateral.map((n) => ({
      from: n, p: Math.random(), sp: P.flowSp[0] + Math.random() * (P.flowSp[1] - P.flowSp[0]),
    }));
    pulses = [];
  }

  function draw() {
    const C = palette(), cxp = W / 2, cyp = H / 2;
    if (!REDUCED) t += 1;
    cx.clearRect(0, 0, W, H);
    cx.fillStyle = C.void_;
    cx.fillRect(0, 0, W, H);

    [[-1, C.blue], [1, C.red]].forEach(([side, col]) => {
      const g = cx.createRadialGradient(cxp + side * W * 0.3, cyp, 0, cxp + side * W * 0.3, cyp, W * 0.34);
      g.addColorStop(0, col + '22'); g.addColorStop(1, 'transparent');
      cx.globalAlpha = P.fields; cx.fillStyle = g; cx.fillRect(0, 0, W, H);
    });
    cx.globalAlpha = 1;

    cx.lineWidth = 0.7;
    lateral.forEach((n, i) => {
      const col = n.side < 0 ? C.blue : C.red;
      n.px = cxp + n.bx + Math.sin(t * 0.006 * n.sp + n.ph) * 14;
      n.py = cyp + n.by + Math.cos(t * 0.005 * n.sp + n.ph) * 11;
      const nx = lateral[i + 1];
      if (nx && nx.side === n.side && nx.px !== undefined) {
        cx.globalAlpha = P.sideA * 0.19; cx.strokeStyle = col;
        cx.beginPath(); cx.moveTo(n.px, n.py); cx.lineTo(nx.px, nx.py); cx.stroke();
      }
      cx.globalAlpha = P.sideA * (0.5 + 0.5 * Math.abs(Math.sin(t * 0.02 * n.sp + n.ph)));
      cx.fillStyle = col;
      cx.beginPath(); cx.arc(n.px, n.py, n.r, 0, 6.2832); cx.fill();
    });
    cx.globalAlpha = 1;

    flows.forEach((f) => {
      f.p += f.sp;
      if (f.p > 1) { f.p = 0; if (P.rings) pulses.push({ r: 0, a: 1, side: f.from.side }); }
      const n = f.from; if (n.px === undefined) return;
      const e = 1 - Math.pow(1 - f.p, 2.2);
      const x = n.px + (cxp - n.px) * e, y = n.py + (cyp - n.py) * e;
      cx.strokeStyle = f.p > 0.8 ? C.purple : n.side < 0 ? C.blue : C.red;
      cx.globalAlpha = P.flowA * (0.16 + f.p * 0.5);
      cx.lineWidth = 0.6 + f.p * 1.2;
      cx.beginPath();
      cx.moveTo(n.px + (cxp - n.px) * Math.max(0, e - 0.06), n.py + (cyp - n.py) * Math.max(0, e - 0.06));
      cx.lineTo(x, y); cx.stroke();
    });
    cx.globalAlpha = 1;

    const ry = t * P.rot, rx = Math.sin(t * 0.0011) * 0.34;
    const span = Math.min(W, H) * (P.brainR * 0.9);
    const proj = nodes.map((n) => {
      const x1 = n.x * Math.cos(ry) - n.z * Math.sin(ry);
      let z1 = n.x * Math.sin(ry) + n.z * Math.cos(ry);
      const y1 = n.y * Math.cos(rx) - z1 * Math.sin(rx);
      z1 = n.y * Math.sin(rx) + z1 * Math.cos(rx);
      const persp = 1 / (1.9 - z1 * 0.55);
      return { x: cxp + x1 * n.R * persp * 1.5, y: cyp + y1 * n.R * persp * 1.5, z: z1, persp, pulse: n.pulse };
    });
    const hue = (mx) => {
      const b = Math.max(-1, Math.min(1, (mx - cxp) / span));
      return b < -0.45 ? C.blue : b > 0.45 ? C.red : C.purple;
    };
    edges.forEach(([i, j, d]) => {
      const a = proj[i], b = proj[j], depth = (a.z + b.z) / 2;
      cx.globalAlpha = P.brainA * (0.06 + (depth + 1) * 0.16) * (1 - d / P.edge) * 1.4;
      cx.strokeStyle = hue((a.x + b.x) / 2);
      cx.lineWidth = 0.55 + (depth + 1) * 0.35;
      cx.beginPath(); cx.moveTo(a.x, a.y); cx.lineTo(b.x, b.y); cx.stroke();
    });
    proj.forEach((p) => {
      const b = Math.max(-1, Math.min(1, (p.x - cxp) / span));
      cx.globalAlpha = P.dotA * ((p.z + 1) / 2) * (0.55 + 0.45 * Math.abs(Math.sin(t * 0.016 + p.pulse)));
      cx.fillStyle = b < -0.45 ? C.blue : b > 0.45 ? C.red : C.core;
      cx.beginPath(); cx.arc(p.x, p.y, 0.9 + p.persp * 1.5, 0, 6.2832); cx.fill();
    });
    cx.globalAlpha = 1;

    cx.globalCompositeOperation = 'lighter';
    const cr = Math.min(W, H) * P.coreS * (1 + Math.sin(t * 0.026) * 0.09);
    const core = cx.createRadialGradient(cxp, cyp, 0, cxp, cyp, cr * 3.6);
    core.addColorStop(0, '#ffffff'); core.addColorStop(0.16, C.core);
    core.addColorStop(0.42, C.purple); core.addColorStop(1, 'transparent');
    cx.globalAlpha = P.coreA; cx.fillStyle = core;
    cx.beginPath(); cx.arc(cxp, cyp, cr * 3.6, 0, 6.2832); cx.fill();

    pulses = pulses.filter((p) => p.a > 0.02);
    pulses.forEach((p) => {
      p.r += 3.4; p.a *= 0.955;
      cx.strokeStyle = p.side < 0 ? C.blue : C.red;
      cx.globalAlpha = p.a * 0.5 * P.flowA; cx.lineWidth = 1.1;
      cx.beginPath(); cx.arc(cxp, cyp, p.r, 0, 6.2832); cx.stroke();
    });
    cx.globalCompositeOperation = 'source-over';
    cx.globalAlpha = 1;

    requestAnimationFrame(draw);
  }

  window.addEventListener('resize', resize);
  resize();
  requestAnimationFrame(draw);
  return { resize };
}
