// Araç parçaları: yürüyen aksam, kapaklar, optikler, teçhizat. İleri -Z, Y yukarı, metre.
import { THREE } from './lib.js';

export const V = (x, y, z) => [x, y, z];
export const RX = (a) => [a, 0, 0];
export const RY = (a) => [0, a, 0];
export const RZ = (a) => [0, 0, a];
const AX = RZ(Math.PI / 2);   // silindiri X eksenine yatır

// ---------------------------------------------------------------- yürüyen aksam
// yol tekeri: lastik bandaj + disk + göbek + cıvatalar (dış yüz s yönünde)
export function roadWheel(m, x, y, z, r, w, s, o = {}) {
  m.cyl('rubber', r, r, w, 16, V(x, y, z), { rot: AX, uvScale: 1.2 });
  m.cyl('paint', r * 0.82, r * 0.82, w * 1.04, 16, V(x, y, z), { rot: AX });
  m.cyl('trim', r * 0.5, r * 0.56, w * 1.12, 12, V(x + s * 0.01, y, z), { rot: AX });
  m.cyl('metal', r * 0.18, r * 0.2, w * 1.3, 8, V(x + s * 0.02, y, z), { rot: AX });
  const n = o.bolts ?? 6;
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2;
    m.box('dark', 0.03, 0.035, 0.035, V(x + s * w * 0.58, y + Math.cos(a) * r * 0.32, z + Math.sin(a) * r * 0.32));
  }
  if (o.spokes) {
    for (let k = 0; k < o.spokes; k++) {
      const a = (k / o.spokes) * Math.PI * 2;
      m.box('dark', 0.02, r * 0.16, r * 0.16, V(x + s * w * 0.55, y + Math.cos(a) * r * 0.66, z + Math.sin(a) * r * 0.66));
    }
  }
}

// çark (dişli) ve gergi tekeri
export function sprocket(m, x, y, z, r, w, s) {
  m.cyl('metal', r * 0.86, r * 0.86, w, 14, V(x, y, z), { rot: AX });
  m.cyl('trim', r * 0.45, r * 0.45, w * 1.15, 10, V(x + s * 0.01, y, z), { rot: AX });
  const n = 11;
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2;
    m.box('metal', w * 0.7, r * 0.22, r * 0.22, V(x, y + Math.cos(a) * r * 0.95, z + Math.sin(a) * r * 0.95), { rot: RX(a) });
  }
}

// palet zinciri: alt/üst koşu + ön/arka yaylar + kılavuz dişleri
export function trackBelt(m, x, w, zF, zB, yC, r, topY = null) {
  // palet: ayrı bakla (pabuç) blokları — alt/üst koşu ve ön/arka yaylar boyunca
  const t = 0.07, pitch = 0.17;
  const link = (px, py, pz, ang) => {
    m.box('track', w, t, pitch * 0.82, V(px, py, pz), { rot: RX(ang), uvScale: 0.85 });
    m.box('track', w * 0.18, t * 0.9, pitch * 0.5, V(px, py + Math.cos(ang) * t * 0.7, pz + Math.sin(ang) * t * 0.7), { rot: RX(ang), tint: [0.8, 0.8, 0.8] });   // kılavuz dişi
  };
  const ty = topY ?? yC + r - t * 0.5;
  // iç gövde (bakla aralarında koyu bant görünmesin)
  m.box('track', w * 0.92, t * 0.6, zB - zF, V(x, yC - r + t * 0.5, (zF + zB) / 2), { tint: [0.5, 0.5, 0.5] });
  m.box('track', w * 0.92, t * 0.6, (zB - zF) * 0.94, V(x, ty, (zF + zB) / 2), { tint: [0.5, 0.5, 0.5] });
  const n = Math.floor((zB - zF) / pitch);
  for (let i = 0; i < n; i++) {
    const z = zF + (i + 0.5) * ((zB - zF) / n);
    link(x, yC - r + t * 0.5, z, 0);
    if (z > zF + 0.15 && z < zB - 0.15) link(x, ty, z, Math.PI);
  }
  for (const zc of [zF, zB]) {
    const sgn = zc === zF ? -1 : 1;
    const seg = Math.max(5, Math.round((Math.PI * r) / pitch));
    for (let i = 1; i < seg; i++) {
      const a = (i / seg) * Math.PI - Math.PI / 2;
      const cz = zc + sgn * Math.cos(a) * (r - t * 0.5);
      const cy = yC + Math.sin(a) * (r - t * 0.5);
      link(x, cy, cz, sgn * (a + Math.PI / 2));
    }
  }
}

// paletli yürüyen aksam (iki yan): tekerler, çark, gergi, dönüş makaraları, palet
export function runningGear(m, o) {
  const { x, w = 0.62, zF, zB, y, r, n, ret = 0, sprocketBack = true, gap = 0.0 } = o;
  for (const s of [-1, 1]) {
    const X = s * x;
    trackBelt(m, X, w, zF, zB, y + 0.02, r + 0.07, o.topY);
    const z0 = zF + r * 1.25, z1 = zB - r * 1.25;
    for (let i = 0; i < n; i++) {
      const z = z0 + (i * (z1 - z0)) / (n - 1) + (i > 0 && gap ? gap : 0);
      roadWheel(m, X, y, z, r, w * 0.72, s, { spokes: o.spokes ?? 0 });
    }
    const zs = sprocketBack ? zB : zF, zi = sprocketBack ? zF : zB;
    sprocket(m, X, y + r * 0.35, zs, r * 0.85, w * 0.6, s);
    m.cyl('metal', r * 0.7, r * 0.7, w * 0.6, 14, V(X, y + r * 0.3, zi), { rot: AX });
    m.cyl('trim', r * 0.3, r * 0.3, w * 0.7, 8, V(X + s * 0.01, y + r * 0.3, zi), { rot: AX });
    for (let i = 0; i < ret; i++) {
      const z = zF + ((i + 1) * (zB - zF)) / (ret + 1);
      m.cyl('metal', 0.11, 0.11, w * 0.5, 8, V(X, (o.topY ?? y + r + 0.07) - 0.12, z), { rot: AX });
    }
  }
}

// lastik teker (tekerlekli araç): ayrı düğüm 'wheel_i' içine
export function tyre(m, i, x, y, z, r, w, s, o = {}) {
  m.group('wheel_' + i, V(x, y, z));
  m.cyl('rubber', r, r, w, 20, V(x, y, z), { rot: AX, uvScale: 1.4 });
  m.cyl('rubber', r * 0.94, r * 0.94, w * 1.06, 20, V(x, y, z), { rot: AX, tint: [0.75, 0.75, 0.75] });
  m.cyl('paint', r * 0.58, r * 0.6, w * 1.1, 14, V(x + s * 0.01, y, z), { rot: AX });
  m.cyl('trim', r * 0.3, r * 0.34, w * 1.18, 10, V(x + s * 0.02, y, z), { rot: AX });
  m.cyl('metal', r * 0.12, r * 0.14, w * 1.3, 8, V(x + s * 0.03, y, z), { rot: AX });
  const n = o.bolts ?? 8;
  for (let k = 0; k < n; k++) {
    const a = (k / n) * Math.PI * 2;
    m.box('dark', 0.03, 0.03, 0.03, V(x + s * w * 0.6, y + Math.cos(a) * r * 0.22, z + Math.sin(a) * r * 0.22));
  }
  // diş deseni (lastik sırtı)
  const t = 14;
  for (let k = 0; k < t; k++) {
    const a = (k / t) * Math.PI * 2;
    m.box('rubber', w * 0.9, 0.035, r * 0.18, V(x, y + Math.cos(a) * (r + 0.01), z + Math.sin(a) * (r + 0.01)), { rot: RX(-a), tint: [0.8, 0.8, 0.8] });
  }
  m.group('hull');
}

// ---------------------------------------------------------------- üst donanım
export function hatch(m, x, y, z, r, o = {}) {
  m.cyl('paint', r, r * 1.02, 0.07, 14, V(x, y + 0.035, z));
  m.cyl('trim', r * 0.92, r * 0.92, 0.05, 14, V(x, y + 0.08, z));
  m.box('metal', r * 1.0, 0.03, 0.04, V(x, y + 0.12, z + r * 0.35), { rot: RY(o.rot ?? 0) });
  m.box('dark', 0.08, 0.06, 0.1, V(x + r * 0.95, y + 0.06, z));
}

export function periscope(m, x, y, z, rotY = 0) {
  m.box('trim', 0.18, 0.1, 0.12, V(x, y + 0.05, z), { rot: RY(rotY) });
  m.box('glass', 0.15, 0.05, 0.02, V(x - Math.sin(rotY) * 0.06, y + 0.07, z - Math.cos(rotY) * 0.06), { rot: RY(rotY) });
}

// sis bombası atar demeti: n tüp, yön a (Y ekseni), yükseliş e
export function smokeLaunchers(m, x, y, z, n, a, e = 0.5) {
  m.bevel('trim', 0.18, 0.12, 0.08 * n + 0.04, V(x, y, z), 0.02, { rot: RY(a) });
  for (let i = 0; i < n; i++) {
    const off = (i - (n - 1) / 2) * 0.085;
    const px = x + Math.cos(a) * off, pz = z - Math.sin(a) * off;
    m.cyl('dark', 0.035, 0.035, 0.26, 7, V(px - Math.sin(a) * 0.08, y + 0.08, pz - Math.cos(a) * 0.08), { rot: [Math.PI / 2 - e, a, 0] });
  }
}

export function antenna(m, x, y, z, h, o = {}) {
  m.cyl('trim', 0.06, 0.07, 0.1, 8, V(x, y + 0.05, z));
  m.cyl('dark', 0.012, 0.02, h, 4, V(x, y + 0.1 + h / 2, z), { rot: [o.lean ?? 0, 0, o.leanZ ?? 0] });
}

export function jerrycan(m, x, y, z, rotY = 0, mat = 'trim') {
  m.bevel(mat, 0.17, 0.46, 0.34, V(x, y + 0.23, z), 0.03, { rot: RY(rotY) });
  m.box('dark', 0.05, 0.05, 0.12, V(x, y + 0.48, z), { rot: RY(rotY) });
}

export function bag(m, x, y, z, w, h, d, rotY = 0) {
  m.bevel('canvas', w, h, d, V(x, y + h / 2, z), Math.min(w, h, d) * 0.3, { rot: RY(rotY), tint: [0.52, 0.5, 0.38] });
  m.box('dark', w * 1.02, 0.03, 0.04, V(x, y + h * 0.7, z), { rot: RY(rotY) });
}

export function toolbox(m, x, y, z, w, h, d, rotY = 0) {
  m.bevel('paint', w, h, d, V(x, y + h / 2, z), 0.025, { rot: RY(rotY) });
  m.box('metal', w * 0.3, 0.025, 0.04, V(x, y + h + 0.012, z), { rot: RY(rotY) });
}

export function headlight(m, x, y, z, s = 1) {
  m.bevel('trim', 0.22 * s, 0.16 * s, 0.1, V(x, y, z), 0.02);
  m.box('light', 0.16 * s, 0.1 * s, 0.02, V(x, y, z - 0.055));
  m.box('dark', 0.02, 0.2 * s, 0.14, V(x - 0.12 * s, y, z - 0.02));
  m.box('dark', 0.02, 0.2 * s, 0.14, V(x + 0.12 * s, y, z - 0.02));
}

// makineli tüfek (kendi yatağında): uzunluk L, -Z yönünde
export function mg(m, x, y, z, L = 1.1, mat = 'metal') {
  m.box(mat, 0.08, 0.12, L * 0.55, V(x, y, z - L * 0.1));
  m.cyl(mat, 0.022, 0.022, L * 0.5, 6, V(x, y + 0.01, z - L * 0.62), { rot: RX(Math.PI / 2) });
  m.box(mat, 0.1, 0.1, 0.12, V(x + 0.09, y - 0.03, z - L * 0.15));
  m.box('dark', 0.05, 0.08, 0.16, V(x, y - 0.02, z + L * 0.22));
}

// tank topu namlusu: muylu z0'dan -Z yönünde L boyunca (koni + ısı kılıfı bantları + duman tahliye)
export function cannon(m, y, z0, L, r, o = {}) {
  const zc = z0 - L / 2;
  m.cyl('paint', r * 0.82, r, L, 14, V(0, y, zc), { rot: RX(Math.PI / 2) });
  const bands = o.bands ?? 4;
  for (let i = 1; i <= bands; i++) m.cyl('trim', r * 1.08, r * 1.08, 0.06, 14, V(0, y, z0 - (L * i) / (bands + 1)), { rot: RX(Math.PI / 2) });
  if (o.evac !== false) m.cyl('paint', r * 1.45, r * 1.45, L * 0.16, 14, V(0, y, z0 - L * (o.evacAt ?? 0.45)), { rot: RX(Math.PI / 2) });
  m.cyl('dark', r * 0.65, r * 0.65, 0.04, 12, V(0, y, z0 - L - 0.01), { rot: RX(Math.PI / 2) });
  m.cyl('trim', r * 0.95, r * 0.88, 0.22, 14, V(0, y, z0 - L + 0.1), { rot: RX(Math.PI / 2) });
}

// taktik işaret (takım rengi): ters V / şerit
export function chevron(m, x, y, z, s, side) {
  const a = side * Math.PI / 2;
  m.box('mark', 0.02, 0.06, 0.32 * s, V(x, y, z - 0.08 * s), { rot: [0.6, a - side * Math.PI / 2, 0] });
  m.box('mark', 0.02, 0.06, 0.32 * s, V(x, y, z + 0.08 * s), { rot: [-0.6, a - side * Math.PI / 2, 0] });
}

// ızgara (motor güvertesi): w×d alanda n çıta
export function grille(m, x, y, z, w, d, n, rotY = 0) {
  m.box('dark', w, 0.02, d, V(x, y, z));
  for (let i = 0; i < n; i++) m.box('trim', w * 0.96, 0.035, d / n * 0.45, V(x, y + 0.02, z - d / 2 + (i + 0.5) * d / n), { rot: RY(rotY) });
}

export function exhaust(m, x, y, z, w, h) {
  m.bevel('dark', w, h, 0.1, V(x, y, z), 0.02);
  for (let i = 0; i < 3; i++) m.box('trim', w * 0.9, 0.02, 0.12, V(x, y - h / 2 + (i + 1) * h / 4, z));
}

export function towHook(m, x, y, z) {
  m.box('metal', 0.08, 0.14, 0.16, V(x, y, z));
  m.cyl('metal', 0.03, 0.03, 0.2, 6, V(x, y - 0.05, z - 0.06), { rot: AX });
}

// ERA (reaktif zırh) tuğlaları: düzlem üzerinde ızgara
export function eraGrid(m, cx, cy, cz, nx, ny, bw, bh, rot, mat = 'paint') {
  const q = new THREE.Euler(...rot, 'YXZ');
  const mx = new THREE.Matrix4().makeRotationFromEuler(q);
  for (let i = 0; i < nx; i++) for (let j = 0; j < ny; j++) {
    const lx = (i - (nx - 1) / 2) * bw * 1.06;
    const ly = (j - (ny - 1) / 2) * bh * 1.08;
    const p = new THREE.Vector3(lx, ly, -0.04).applyMatrix4(mx);
    m.bevel(mat, bw, bh, 0.1, V(cx + p.x, cy + p.y, cz + p.z), 0.02, { rot, tint: [0.92, 0.92, 0.9] });
  }
}
