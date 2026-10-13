// Mevzi dokuları: kamuflaj desenleri, metal, palet, kumaş, branda. (+ yükseklikten normal haritası)
import { rng, fbm, writePNG } from './lib.js';

const clamp255 = (v) => Math.max(0, Math.min(255, Math.round(v * 255)));
const mix = (a, b, t) => a + (b - a) * t;
const sstep = (a, b, x) => { const t = Math.max(0, Math.min(1, (x - a) / (b - a))); return t * t * (3 - 2 * t); };
const mixc = (a, b, t) => [mix(a[0], b[0], t), mix(a[1], b[1], t), mix(a[2], b[2], t)];

function make(out, name, size, fn, { normal = true, strength = 2.0 } = {}) {
  const px = new Uint8Array(size * size * 4);
  const hgt = new Float32Array(size * size);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const [r, g, b, h = 0.5] = fn(x / size, y / size, x, y);
    const i = y * size + x;
    px[i * 4] = clamp255(r); px[i * 4 + 1] = clamp255(g); px[i * 4 + 2] = clamp255(b); px[i * 4 + 3] = 255;
    hgt[i] = h;
  }
  writePNG(`${out}/${name}.png`, size, size, px);
  if (!normal) return;
  const nm = new Uint8Array(size * size * 4);
  const H = (x, y) => hgt[((y + size) % size) * size + ((x + size) % size)];
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const dx = (H(x + 1, y) - H(x - 1, y)) * strength;
    const dy = (H(x, y + 1) - H(x, y - 1)) * strength;
    const l = Math.hypot(dx, dy, 1);
    const i = (y * size + x) * 4;
    nm[i] = clamp255((-dx / l) * 0.5 + 0.5); nm[i + 1] = clamp255((dy / l) * 0.5 + 0.5); nm[i + 2] = clamp255((1 / l) * 0.5 + 0.5); nm[i + 3] = 255;
  }
  writePNG(`${out}/${name}_n.png`, size, size, nm);
}

// Kamuflaj: n renk katmanı, her biri eşiklenmiş düşük frekanslı gürültü lekesi
function camo(out, name, cols, seed, { scale = 3, grime = 0.12, panels = true } = {}) {
  const layers = cols.slice(1).map((c, i) => ({ c, n: fbm(seed + i * 17, scale + i, 4), th: 0.52 + i * 0.02 }));
  const g1 = fbm(seed + 91, 16, 4), g2 = fbm(seed + 93, 4, 3), sc = fbm(seed + 95, 32, 3);
  make(out, name, 512, (u, v, x, y) => {
    let c = cols[0];
    for (const L of layers) if (L.n(u, v) > L.th) c = L.c;
    // ince kir, büyük ölçek solma, çizikler
    const gr = (g1(u, v) - 0.5) * grime * 2 + (g2(u, v) - 0.5) * grime;
    let k = 1 + gr;
    const scratch = sc(u, v) > 0.78 ? 0.12 : 0;
    // panel çizgileri (128 px ızgara) ve perçinler
    let h = 0.5 + (g1(u, v) - 0.5) * 0.1;
    if (panels) {
      const px = x % 128, py = y % 128;
      if ((x % 256) < 2 && (y % 512) < 300) { k *= 0.8; h = 0.3; }
    }
    return [c[0] * k + scratch, c[1] * k + scratch, c[2] * k + scratch, h];
  });
}

export function buildTextures(out) {
  // ---- araç boyaları ----
  camo(out, 'camo_wood', [[0.3, 0.33, 0.2], [0.2, 0.24, 0.14], [0.36, 0.3, 0.2], [0.12, 0.12, 0.1]], 11, { scale: 3 });
  camo(out, 'camo_desert', [[0.74, 0.66, 0.5], [0.6, 0.5, 0.36], [0.82, 0.76, 0.62]], 21, { scale: 3 });
  camo(out, 'camo_snow', [[0.86, 0.87, 0.86], [0.55, 0.57, 0.55], [0.95, 0.95, 0.96], [0.35, 0.36, 0.33]], 31, { scale: 3 });
  camo(out, 'paint_olive', [[0.28, 0.31, 0.2], [0.24, 0.27, 0.17]], 41, { scale: 2, grime: 0.18 });
  camo(out, 'paint_sand', [[0.76, 0.7, 0.56], [0.7, 0.63, 0.48]], 51, { scale: 2, grime: 0.18 });
  camo(out, 'paint_dark', [[0.2, 0.22, 0.2], [0.16, 0.17, 0.16], [0.3, 0.32, 0.28]], 61, { scale: 3, grime: 0.15 });
  // ---- metal (namlu, çark) ----
  {
    const g = fbm(71, 16, 4), s = fbm(72, 64, 2);
    make(out, 'metal', 256, (u, v) => {
      const k = 0.3 + g(u, v) * 0.12 + (s(u, v) > 0.7 ? 0.06 : 0);
      return [k, k, k * 1.04, 0.5 + g(u, v) * 0.2];
    });
  }
  // ---- palet zinciri ----
  {
    const g = fbm(81, 16, 3);
    make(out, 'track', 256, (u, v, x, y) => {
      const link = (y % 32) / 32;
      const edge = link < 0.12 || link > 0.88;
      const pin = Math.abs(link - 0.5) < 0.08 && (x % 128 < 24 || x % 128 > 104);
      let k = edge ? 0.08 : (pin ? 0.32 : 0.18);
      k += (g(u, v) - 0.5) * 0.08;
      return [k * 1.05, k, k * 0.92, edge ? 0.2 : (pin ? 0.8 : 0.55)];
    }, { strength: 4 });
  }
  // ---- lastik ----
  {
    const g = fbm(85, 16, 3);
    make(out, 'rubber', 256, (u, v, x, y) => {
      const tread = (Math.floor(y / 12) + Math.floor(x / 40)) % 2 === 0;
      const k = (tread ? 0.07 : 0.11) + (g(u, v) - 0.5) * 0.04;
      return [k, k, k, tread ? 0.3 : 0.6];
    }, { strength: 3 });
  }
  // ---- branda / kumaş ----
  {
    const g = fbm(91, 32, 3), w = fbm(92, 4, 3);
    make(out, 'canvas', 512, (u, v, x, y) => {
      const weave = ((x + y) % 4 < 2 ? 0.03 : -0.03);
      const k = 0.92 + (g(u, v) - 0.5) * 0.15 + weave + (w(u, v) - 0.5) * 0.2;
      const fold = Math.sin(u * Math.PI * 10 + w(u, v) * 6) * 0.06;
      return [k + fold, k + fold, k + fold, 0.5 + fold * 2];
    });
  }
  // ---- üniforma desenleri (küçük ölçek) ----
  camo(out, 'fab_multicam', [[0.52, 0.5, 0.36], [0.38, 0.4, 0.26], [0.6, 0.55, 0.42], [0.3, 0.25, 0.18]], 101, { scale: 6, panels: false, grime: 0.1 });
  camo(out, 'fab_olive', [[0.36, 0.38, 0.24], [0.32, 0.34, 0.21]], 111, { scale: 5, panels: false, grime: 0.12 });
  camo(out, 'fab_desert', [[0.72, 0.64, 0.48], [0.62, 0.52, 0.38], [0.8, 0.74, 0.6]], 121, { scale: 6, panels: false, grime: 0.1 });
  camo(out, 'fab_snow', [[0.88, 0.89, 0.9], [0.66, 0.68, 0.68], [0.95, 0.95, 0.96]], 131, { scale: 6, panels: false, grime: 0.08 });
  camo(out, 'fab_khaki', [[0.56, 0.5, 0.36], [0.5, 0.44, 0.31]], 141, { scale: 5, panels: false, grime: 0.12 });
  // ---- deri / bot ----
  {
    const g = fbm(151, 32, 3);
    make(out, 'leather', 256, (u, v) => { const k = 0.85 + (g(u, v) - 0.5) * 0.25; return [k, k, k, g(u, v)]; });
  }
}
