// Zırhlı araçlar v2 — ikinci kısım: ZPT, PSA, uçaksavar, obüs, teknik araç, kamyon.
import { Model, THREE } from './lib.js';
import {
  V, RX, RY, RZ, runningGear, tyre, hatch, periscope, smokeLaunchers, antenna, jerrycan, bag, toolbox,
  headlight, mg, cannon, chevron, grille, exhaust, towHook, eraGrid,
} from './parts.js';

// tekerlekli araç teker çiftleri
function axles(m, zs, x, y, r, w) {
  zs.forEach((z, i) => {
    tyre(m, i * 2, -x, y, z, r, w, -1);
    tyre(m, i * 2 + 1, x, y, z, r, w, 1);
  });
}

// otomatik top: muylu z0'dan -Z
function autocannon(m, x, y, z0, L, r = 0.045) {
  m.cyl('trim', r * 2.2, r * 2.2, 0.35, 10, V(x, y, z0 - 0.18), { rot: RX(Math.PI / 2) });
  m.cyl('metal', r, r, L, 8, V(x, y, z0 - L / 2), { rot: RX(Math.PI / 2) });
  m.cyl('dark', r * 1.5, r * 1.5, 0.22, 8, V(x, y, z0 - L + 0.1), { rot: RX(Math.PI / 2) });
}

// uzaktan komutalı silah istasyonu (RWS)
function rws(m, x, y, z, gun = 'mg') {
  m.cyl('trim', 0.34, 0.38, 0.12, 12, V(x, y + 0.06, z));
  m.bevel('paint', 0.62, 0.42, 0.75, V(x, y + 0.33, z + 0.05), 0.05);
  m.bevel('trim', 0.26, 0.24, 0.3, V(x + 0.38, y + 0.42, z - 0.12), 0.03);
  m.box('glass', 0.18, 0.14, 0.02, V(x + 0.38, y + 0.44, z - 0.28));
  m.bevel('trim', 0.2, 0.22, 0.4, V(x - 0.38, y + 0.3, z + 0.05), 0.03);
}

// ======================================================== MAVİ ZPT (8x8, V gövde)
export function apc_blue() {
  const m = new Model('apc_blue');
  m.loft('paint', [
    [-3.75, [[1.1, 0.9], [1.15, 1.35]]],
    [-2.6, [[0.85, 0.55], [1.38, 0.82], [1.38, 1.95], [1.16, 2.3]]],
    [3.45, [[0.85, 0.55], [1.38, 0.82], [1.38, 1.95], [1.16, 2.3]]],
    [3.6, [[0.8, 0.62], [1.3, 0.86], [1.3, 1.9], [1.1, 2.24]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    // çamurluk kemerleri ve yan paneller
    for (const z of [-1.7, 1.7]) m.bevel('paint', 0.18, 0.1, 2.6, V(s * 1.43, 1.2, z), 0.03);
    for (let i = 0; i < 5; i++) m.box('dark', 0.02, 0.9, 0.02, V(s * 1.39, 1.45, -2.4 + i * 1.3));
    for (const z of [-0.2, 0.75]) toolbox(m, s * 1.45, 1.35, z, 0.14, 0.45, 0.7);
    headlight(m, s * 0.95, 1.38, -3.72, 0.9);
    towHook(m, s * 0.55, 0.85, -3.7);
    chevron(m, s * 1.4, 1.75, 2.4, 1.1, s);
    m.box('red', 0.1, 0.12, 0.03, V(s * 1.1, 1.6, 3.62));
  }
  m.bevel('trim', 2.3, 0.08, 1.0, V(0, 1.12, -3.85), 0.03, { rot: RX(-0.25) });   // dalga kırıcı
  hatch(m, -0.6, 2.28, -2.25, 0.28);
  for (const k of [-1, 0, 1]) periscope(m, -0.6 + k * 0.2, 2.25, -2.6, -k * 0.2);
  hatch(m, -0.55, 2.3, 1.6, 0.34);
  hatch(m, 0.55, 2.3, 1.6, 0.34);
  m.bevel('trim', 1.8, 1.25, 0.08, V(0, 1.42, 3.65), 0.03);                       // rampa
  m.box('dark', 1.6, 0.02, 0.02, V(0, 1.5, 3.7));
  grille(m, 0.6, 2.31, -1.5, 0.8, 0.9, 6);
  antenna(m, -1.0, 2.25, 2.9, 2.3);
  antenna(m, 1.0, 2.25, 2.9, 1.8);
  bag(m, 0, 2.3, 2.75, 1.4, 0.3, 0.6);
  axles(m, [-2.45, -1.0, 1.0, 2.45], 1.28, 0.55, 0.55, 0.42);
  // ---- RWS taret (30 mm) ----
  m.group('turret', V(0.3, 2.3, -0.8));
  rws(m, 0.3, 2.3, -0.8);
  smokeLaunchers(m, 0.3, 2.55, -0.45, 3, 0, 0.6);
  m.group('barrel', V(0.3, 2.62, -1.25));
  autocannon(m, 0.3, 2.62, -1.25, 2.1);
  m.meta = { muzzle: V(0.3, 2.62, -3.35), radius: 2.5 };
  return m;
}

// ======================================================== KIZIL ZPT (BTR tipi, tekne gövde)
export function apc_red() {
  const m = new Model('apc_red');
  m.loft('paint', [
    [-3.75, [[0.7, 1.08], [0.75, 1.35]]],
    [-3.15, [[1.1, 0.6], [1.32, 1.25], [1.1, 1.95]]],
    [-2.4, [[1.05, 0.55], [1.34, 1.3], [1.18, 2.0]]],
    [3.0, [[1.05, 0.55], [1.34, 1.3], [1.18, 2.0]]],
    [3.55, [[0.9, 0.7], [1.15, 1.25], [1.0, 1.85]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    m.bevel('paint', 0.08, 0.7, 0.8, V(s * 1.3, 1.55, 0.05), 0.03, { rot: RZ(s * 0.18) });   // yan kapı
    for (let i = 0; i < 3; i++) m.cyl('dark', 0.05, 0.05, 0.06, 8, V(s * 1.3, 1.62, -1.6 + i * 0.6 + (i > 1 ? 1.2 : 0)), { rot: RZ(Math.PI / 2) });
    headlight(m, s * 0.65, 1.42, -3.55, 0.85);
    toolbox(m, s * 1.05, 1.96, 1.6, 0.4, 0.2, 0.9);
    chevron(m, s * 1.33, 1.3, 2.3, 1.0, s);
  }
  m.bevel('paint', 1.6, 0.06, 0.8, V(0, 1.25, -3.85), 0.02, { rot: RX(-0.5) });
  hatch(m, -0.45, 1.98, -2.35, 0.26);
  hatch(m, 0.45, 1.98, -2.35, 0.26);
  for (const s of [-1, 1]) m.box('glass', 0.42, 0.14, 0.03, V(s * 0.45, 1.8, -2.92), { rot: RX(-0.6) });
  grille(m, 0, 2.0, 2.2, 1.6, 1.2, 7);
  m.cyl('dark', 0.16, 0.18, 0.12, 10, V(0, 0.95, 3.58), { rot: RX(Math.PI / 2) });   // su jeti
  antenna(m, -0.9, 1.96, 1.0, 2.0);
  axles(m, [-2.4, -1.1, 1.0, 2.3], 1.22, 0.58, 0.58, 0.42);
  // ---- konik taret (30 mm) ----
  m.group('turret', V(0, 2.0, -0.7));
  m.cyl('paint', 0.58, 0.72, 0.42, 14, V(0, 2.21, -0.7));
  m.cyl('trim', 0.3, 0.32, 0.06, 12, V(0.1, 2.45, -0.55));
  m.bevel('trim', 0.2, 0.18, 0.3, V(-0.4, 2.42, -0.95), 0.03);
  m.box('glass', 0.14, 0.1, 0.02, V(-0.4, 2.44, -1.11));
  smokeLaunchers(m, 0.0, 2.32, -0.2, 6, 0, 0.6);
  m.group('barrel', V(0, 2.3, -1.2));
  autocannon(m, 0, 2.3, -1.2, 2.2);
  m.box('metal', 0.06, 0.08, 0.7, V(0.16, 2.28, -1.45));
  m.meta = { muzzle: V(0, 2.3, -3.4), radius: 2.5 };
  return m;
}

// ======================================================== PSA
export function ifv_blue() {
  const m = new Model('ifv_blue');
  runningGear(m, { x: 1.45, w: 0.62, zF: -3.15, zB: 3.1, y: 0.42, r: 0.34, n: 6, ret: 3, topY: 0.88 });
  m.loft('paint', [[-3.3, [[1.1, 0.5], [1.1, 0.95]]], [-2.8, [[1.12, 0.3], [1.12, 1.0]]], [3.2, [[1.12, 0.35], [1.12, 1.2]]]], { mirror: true });
  m.loft('paint', [
    [-3.45, [[1.72, 0.94], [1.68, 1.05]]],
    [-2.3, [[1.82, 0.94], [1.8, 1.72]]],
    [3.2, [[1.82, 0.94], [1.8, 1.82]]],
    [3.32, [[1.7, 0.98], [1.68, 1.72]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    const X = s * 1.88;
    for (const [z, L] of [[-2.35, 1.4], [-0.9, 1.4], [0.55, 1.4], [2.0, 1.3]]) m.bevel('paint', 0.1, 0.55, L - 0.04, V(X, 0.94, z), 0.03);
    headlight(m, s * 1.4, 1.2, -3.4, 0.9);
    chevron(m, s * 1.84, 1.45, 1.6, 1.0, s);
    toolbox(m, s * 1.55, 1.73, 1.6, 0.4, 0.22, 1.6);
  }
  hatch(m, -0.7, 1.72, -2.0, 0.28);
  for (const k of [-1, 0, 1]) periscope(m, -0.7 + k * 0.2, 1.7, -2.3, -k * 0.25);
  grille(m, -0.7, 1.73, -1.0, 0.9, 1.2, 7);
  hatch(m, 0, 1.82, 2.6, 0.38);
  m.bevel('trim', 1.6, 1.2, 0.08, V(0, 1.25, 3.36), 0.03);
  exhaust(m, 1.82, 1.35, -1.6, 0.1, 0.25);
  antenna(m, 1.3, 1.82, 2.9, 2.2);
  // ---- taret: köşeli, yanında çift tanksavar füze kutusu ----
  m.group('turret', V(0.3, 1.97, -0.2));
  m.loft('paint', [
    [-1.3, [[0.65, 2.0], [0.55, 2.5]]],
    [-0.75, [[1.1, 1.98], [1.02, 2.6]]],
    [0.9, [[1.1, 2.0], [1.0, 2.62]]],
    [1.1, [[0.95, 2.05], [0.85, 2.55]]],
  ].map(([z, r]) => [z, r.map(([x, y]) => [x, y])]), { mirror: true, pos: V(0.3, 0, -0.2) });
  m.bevel('paint', 0.5, 0.55, 1.5, V(-0.85, 2.55, -0.15), 0.05);                    // füze kutusu
  m.box('dark', 0.36, 0.2, 0.02, V(-0.85, 2.66, -0.91));
  m.box('dark', 0.36, 0.2, 0.02, V(-0.85, 2.42, -0.91));
  m.bevel('trim', 0.3, 0.3, 0.36, V(0.95, 2.82, -0.4), 0.04);
  m.box('glass', 0.22, 0.16, 0.02, V(0.95, 2.84, -0.59));
  hatch(m, 0.5, 2.62, 0.3, 0.3);
  smokeLaunchers(m, 1.3, 2.4, -0.7, 4, -0.8, 0.6);
  bag(m, 0.3, 2.3, 1.15, 1.6, 0.35, 0.5);
  m.group('barrel', V(0.1, 2.3, -1.15));
  m.bevel('trim', 0.45, 0.4, 0.4, V(0.1, 2.3, -1.25), 0.04);
  autocannon(m, 0.1, 2.3, -1.45, 2.0, 0.05);
  m.meta = { muzzle: V(0.1, 2.3, -3.45), radius: 2.6 };
  return m;
}

export function ifv_red() {
  const m = new Model('ifv_red');
  runningGear(m, { x: 1.3, w: 0.56, zF: -2.95, zB: 2.95, y: 0.44, r: 0.36, n: 6, ret: 3, spokes: 6, topY: 0.92 });
  m.loft('paint', [[-3.1, [[1.0, 0.5], [1.0, 0.85]]], [-2.6, [[1.05, 0.32], [1.05, 0.95]]], [3.0, [[1.05, 0.35], [1.05, 1.1]]]], { mirror: true });
  // keskin kama burun + nervürlü ön levha
  m.loft('paint', [
    [-3.55, [[1.45, 0.82], [1.4, 0.86]]],
    [-1.6, [[1.6, 0.9], [1.56, 1.38]]],
    [2.95, [[1.6, 0.9], [1.52, 1.45]]],
    [3.05, [[1.5, 0.92], [1.45, 1.38]]],
  ], { mirror: true });
  for (let i = 0; i < 6; i++) m.box('trim', 2.8, 0.04, 0.06, V(0, 0.9 + i * 0.085, -3.3 + i * 0.3));
  for (const s of [-1, 1]) {
    headlight(m, s * 0.9, 1.05, -2.9, 0.8);
    for (let i = 0; i < 4; i++) m.cyl('dark', 0.05, 0.05, 0.05, 8, V(s * 1.58, 1.2, -0.8 + i * 0.7), { rot: RZ(Math.PI / 2) });
    toolbox(m, s * 1.4, 1.4, 1.9, 0.35, 0.25, 1.4);
    chevron(m, s * 1.6, 1.15, 2.3, 0.9, s);
  }
  hatch(m, -0.8, 1.38, -1.4, 0.26);
  for (const z of [0.9, 1.9]) { hatch(m, -0.45, 1.45, z, 0.32); hatch(m, 0.45, 1.45, z, 0.32); }
  exhaust(m, 1.58, 1.15, -1.1, 0.1, 0.22);
  antenna(m, -0.4, 1.45, 2.6, 1.8);
  // ---- küçük taret + tavanda tanksavar füze tüpü ----
  m.group('turret', V(0, 1.5, -0.6));
  m.loft('paint', [
    [-1.25, [[0.6, 1.5], [0.48, 1.9]]],
    [-0.7, [[0.95, 1.48], [0.8, 1.95]]],
    [0.4, [[0.95, 1.5], [0.78, 1.95]]],
  ], { mirror: true });
  hatch(m, -0.35, 1.94, -0.35, 0.26);
  hatch(m, 0.4, 1.94, -0.3, 0.26);
  m.cyl('pack', 0.1, 0.1, 1.3, 10, V(0.0, 2.15, -0.5), { rot: RX(Math.PI / 2), tint: [0.55, 0.58, 0.42] });
  m.cyl('dark', 0.11, 0.11, 0.05, 10, V(0.0, 2.15, -1.16), { rot: RX(Math.PI / 2) });
  m.box('trim', 0.12, 0.2, 0.12, V(0.0, 2.0, -0.5));
  for (const s of [-1, 1]) smokeLaunchers(m, s * 0.85, 1.75, -0.15, 3, s * -1.1, 0.5);
  m.bevel('trim', 0.2, 0.18, 0.28, V(-0.6, 1.95, -0.85), 0.03);
  m.group('barrel', V(0, 1.85, -1.4));
  autocannon(m, 0, 1.85, -1.4, 2.4, 0.045);
  m.meta = { muzzle: V(0, 1.85, -3.8), radius: 2.5 };
  return m;
}

// ======================================================== uçaksavar
function aaHull(m, blue) {
  if (blue) {
    runningGear(m, { x: 1.42, w: 0.6, zF: -3.05, zB: 3.0, y: 0.42, r: 0.34, n: 6, ret: 3, topY: 0.88 });
  } else {
    runningGear(m, { x: 1.35, w: 0.54, zF: -2.95, zB: 2.95, y: 0.44, r: 0.38, n: 6, spokes: 6, topY: 0.94 });
  }
  m.loft('paint', [[-3.2, [[1.05, 0.5], [1.05, 0.95]]], [-2.7, [[1.1, 0.3], [1.1, 1.0]]], [3.1, [[1.1, 0.35], [1.1, 1.1]]]], { mirror: true });
  m.loft('paint', [
    [-3.4, [[1.65, 0.92], [1.6, 1.02]]],
    [-2.2, [[1.75, 0.92], [1.73, 1.45]]],
    [3.1, [[1.75, 0.92], [1.72, 1.5]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    headlight(m, s * 1.3, 1.15, -3.35, 0.9);
    toolbox(m, s * 1.5, 1.45, 1.8, 0.4, 0.22, 1.5);
    chevron(m, s * 1.76, 1.25, 1.2, 1.0, s);
    if (blue) for (const [z, L] of [[-2.2, 1.6], [-0.5, 1.6], [1.2, 1.6]]) m.bevel('paint', 0.1, 0.5, L - 0.04, V(s * 1.8, 0.94, z), 0.03);
  }
  hatch(m, -0.7, 1.45, -2.0, 0.27);
  grille(m, 0, 1.47, 2.2, 2.0, 1.2, 8);
}

export function aa_blue() {
  const m = new Model('aa_blue');
  aaHull(m, true);
  m.group('turret', V(0, 1.55, 0.2));
  m.loft('paint', [
    [-1.0, [[0.9, 1.55], [0.75, 2.35]]],
    [-0.3, [[1.0, 1.55], [0.92, 2.5]]],
    [1.3, [[1.0, 1.55], [0.92, 2.5]]],
  ], { mirror: true });
  // arama radarı (arka, direk üstünde) + takip radarı (ön)
  m.cyl('trim', 0.08, 0.08, 0.5, 8, V(0, 2.75, 1.0));
  m.bevel('dark', 1.6, 0.6, 0.1, V(0, 3.1, 1.05), 0.03, { rot: RX(-0.2) });
  m.cyl('trim', 0.38, 0.38, 0.22, 14, V(0, 2.55, -0.85), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.36, 0.36, 0.02, 14, V(0, 2.55, -0.97), { rot: RX(Math.PI / 2) });
  hatch(m, 0.45, 2.5, 0.4, 0.26);
  for (const s of [-1, 1]) smokeLaunchers(m, s * 0.95, 2.1, -0.6, 4, s * -0.9, 0.6);
  m.group('barrel', V(0, 2.2, -0.6));
  for (const s of [-1, 1]) {
    m.bevel('paint', 0.42, 0.5, 1.6, V(s * 1.22, 2.2, -0.1), 0.06);
    m.cyl('metal', 0.045, 0.045, 2.5, 8, V(s * 1.22, 2.25, -2.1), { rot: RX(Math.PI / 2) });
    m.cyl('dark', 0.075, 0.075, 0.3, 8, V(s * 1.22, 2.25, -3.2), { rot: RX(Math.PI / 2) });
  }
  m.meta = { muzzle: V(0, 2.25, -3.35), radius: 2.5 };
  return m;
}

export function aa_red() {
  const m = new Model('aa_red');
  aaHull(m, false);
  m.group('turret', V(0, 1.55, 0.2));
  m.loft('paint', [
    [-1.2, [[1.25, 1.55], [1.15, 1.95]]],
    [-0.8, [[1.5, 1.55], [1.42, 2.2]]],
    [1.4, [[1.5, 1.55], [1.42, 2.25]]],
  ], { mirror: true });
  // tabak radar (katlanır)
  m.cyl('trim', 0.06, 0.06, 0.5, 6, V(0, 2.45, 1.1));
  m.add('dark', new THREE.SphereGeometry(0.75, 14, 6, 0, Math.PI * 2, 0, Math.PI * 0.32), { pos: V(0, 2.75, 1.25), rot: RX(-1.2) });
  hatch(m, -0.6, 2.23, 0.3, 0.27);
  hatch(m, 0.6, 2.23, 0.3, 0.27);
  for (const s of [-1, 1]) toolbox(m, s * 1.48, 1.7, 0.4, 0.12, 0.4, 1.3);
  m.group('barrel', V(0, 2.2, -0.6));
  m.bevel('trim', 0.9, 0.4, 0.8, V(0, 2.2, -0.7), 0.05);
  for (const s of [-0.28, -0.1, 0.1, 0.28]) {
    m.cyl('metal', 0.035, 0.035, 1.8, 7, V(s, 2.2 + (Math.abs(s) < 0.2 ? 0.12 : 0), -1.95), { rot: RX(Math.PI / 2) });
    m.cyl('dark', 0.055, 0.055, 0.2, 7, V(s, 2.2 + (Math.abs(s) < 0.2 ? 0.12 : 0), -2.8), { rot: RX(Math.PI / 2) });
  }
  m.meta = { muzzle: V(0, 2.25, -2.9), radius: 2.5 };
  return m;
}

// ======================================================== kundağı motorlu obüs
function artyHull(m, blue) {
  runningGear(m, { x: 1.45, w: 0.62, zF: -3.3, zB: 3.25, y: 0.42, r: 0.34, n: 7, ret: blue ? 0 : 3, spokes: blue ? 0 : 6, topY: 0.88 });
  m.loft('paint', [[-3.45, [[1.1, 0.5], [1.1, 0.95]]], [-2.9, [[1.12, 0.3], [1.12, 1.0]]], [3.35, [[1.12, 0.35], [1.12, 1.2]]]], { mirror: true });
  m.loft('paint', [
    [-3.6, [[1.7, 0.92], [1.66, 1.02]]],
    [-2.5, [[1.8, 0.92], [1.78, 1.4]]],
    [3.35, [[1.8, 0.92], [1.78, 1.4]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    headlight(m, s * 1.4, 1.15, -3.55, 0.9);
    if (blue) for (const [z, L] of [[-2.5, 1.6], [-0.8, 1.6], [0.9, 1.6], [2.5, 1.5]]) m.bevel('paint', 0.1, 0.5, L - 0.04, V(s * 1.86, 0.94, z), 0.03);
  }
  hatch(m, -0.75, 1.4, -2.4, 0.27);
  grille(m, 0.5, 1.42, -1.5, 1.2, 1.4, 8);
  m.bevel('trim', 0.4, 0.5, 0.12, V(0, 1.0, -3.85), 0.03);                          // yol kilidi
  m.bevel('trim', 2.6, 0.18, 0.5, V(0, 0.9, 3.55), 0.04);                           // kürek
}

export function arty_blue() {
  const m = new Model('arty_blue');
  artyHull(m, true);
  m.group('turret', V(0, 1.43, 0.9));
  m.loft('paint', [
    [-0.9, [[1.25, 1.42], [1.1, 2.2]]],
    [-0.3, [[1.55, 1.42], [1.48, 2.75]]],
    [2.6, [[1.55, 1.42], [1.48, 2.8]]],
    [2.75, [[1.4, 1.5], [1.32, 2.7]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    toolbox(m, s * 1.6, 1.9, 1.3, 0.12, 0.6, 1.8);
    chevron(m, s * 1.6, 2.35, 0.3, 1.0, s);
    smokeLaunchers(m, s * 1.3, 2.4, -0.55, 4, s * -0.6, 0.6);
  }
  hatch(m, 0.7, 2.8, 1.1, 0.3);
  m.cyl('trim', 0.05, 0.05, 0.3, 6, V(0.7, 2.98, 0.8));
  mg(m, 0.7, 3.12, 0.75, 1.0);
  m.bevel('trim', 0.4, 0.3, 0.4, V(-0.8, 2.92, 0.2), 0.04);
  antenna(m, -1.2, 2.8, 2.3, 2.2);
  m.bevel('trim', 0.8, 0.8, 0.5, V(0, 2.1, -0.92), 0.06);
  m.group('barrel', V(0, 2.1, -0.95));
  cannon(m, 2.1, -1.1, 5.8, 0.11, { bands: 0, evacAt: 0.5 });
  m.bevel('trim', 0.42, 0.26, 0.5, V(0, 2.1, -6.75), 0.04);                         // namlu ağzı freni
  for (const s of [-1, 1]) m.box('dark', 0.03, 0.18, 0.3, V(s * 0.22, 2.1, -6.75));
  m.meta = { muzzle: V(0, 2.1, -7.1), radius: 2.8 };
  return m;
}

export function arty_red() {
  const m = new Model('arty_red');
  artyHull(m, false);
  m.group('turret', V(0, 1.43, 0.9));
  m.loft('paint', [
    [-1.0, [[1.35, 1.42], [1.2, 2.25]]],
    [-0.2, [[1.6, 1.42], [1.5, 2.6]]],
    [2.5, [[1.6, 1.42], [1.42, 2.62]]],
    [2.9, [[1.2, 1.5], [1.0, 2.4]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    toolbox(m, s * 1.65, 1.8, 1.0, 0.12, 0.5, 2.0);
    chevron(m, s * 1.66, 2.2, 0.2, 1.0, s);
    for (let i = 0; i < 4; i++) m.cyl('dark', 0.04, 0.04, 0.26, 7, V(s * 1.25, 2.45, -0.75 + i * 0.12), { rot: [Math.PI / 2 - 0.5, s * -1.2, 0] });
  }
  m.cyl('paint', 0.36, 0.4, 0.22, 12, V(0.65, 2.7, 0.6));
  mg(m, 0.65, 2.98, 0.35, 1.2);
  hatch(m, -0.6, 2.6, 0.9, 0.3);
  antenna(m, -1.1, 2.6, 2.1, 2.0);
  m.bevel('trim', 0.8, 0.75, 0.5, V(0, 2.1, -1.0), 0.06);
  m.group('barrel', V(0, 2.1, -0.95));
  cannon(m, 2.1, -1.2, 4.55, 0.11, { bands: 0, evacAt: 0.55 });
  m.cyl('trim', 0.18, 0.18, 0.45, 10, V(0, 2.1, -5.55), { rot: RX(Math.PI / 2) });
  for (let i = 0; i < 4; i++) m.box('dark', 0.38, 0.03, 0.05, V(0, 2.1, -5.4 - i * 0.09));
  m.meta = { muzzle: V(0, 2.1, -5.9), radius: 2.8 };
  return m;
}

// ======================================================== teknik araç
export function technical_blue() {
  // zırhlı hafif taktik araç (JLTV tipi) + nişancı halkası
  const m = new Model('technical_blue');
  m.loft('paint', [
    [-2.45, [[0.95, 0.85], [0.95, 1.2]]],
    [-1.6, [[1.05, 0.7], [1.05, 1.42]]],
    [-0.6, [[1.08, 0.7], [1.05, 1.5], [0.98, 1.6]]],
    [2.4, [[1.08, 0.7], [1.05, 1.5]]],
  ], { mirror: true });
  m.loft('paint', [
    [-0.75, [[1.05, 1.5], [0.85, 2.15]]],
    [0.2, [[1.08, 1.5], [0.95, 2.25]]],
    [1.3, [[1.08, 1.5], [0.95, 2.22]]],
  ], { mirror: true });
  for (const s of [-1, 1]) {
    for (const z of [-0.15, 0.85]) m.box('glass', 0.03, 0.42, 0.62, V(s * 1.05, 1.85, z), { rot: RZ(s * 0.12) });
    m.bevel('trim', 0.12, 0.22, 1.2, V(s * 1.12, 1.0, 0.35), 0.03);
    headlight(m, s * 0.7, 1.2, -2.47, 0.8);
    chevron(m, s * 1.1, 1.3, 1.9, 0.8, s);
    for (const z of [-1.6, 1.6]) m.bevel('paint', 0.4, 0.12, 1.25, V(s * 0.98, 1.06, z), 0.03);
  }
  m.box('glass', 1.6, 0.42, 0.03, V(0, 1.86, -0.68), { rot: RX(-0.35) });
  m.bevel('trim', 2.0, 0.25, 0.14, V(0, 0.95, -2.5), 0.03);
  grille(m, 0, 1.43, -1.85, 1.3, 0.6, 5);
  m.bevel('paint', 1.9, 0.08, 1.0, V(0, 1.5, 1.9), 0.02);
  bag(m, -0.4, 1.54, 2.0, 0.9, 0.3, 0.7);
  jerrycan(m, 0.6, 1.54, 2.05, Math.PI / 2);
  antenna(m, -0.9, 2.2, 1.2, 1.8);
  axles(m, [-1.6, 1.6], 1.0, 0.48, 0.48, 0.38);
  // ---- nişancı halkası + kalkan ----
  m.group('turret', V(0, 2.2, 0.5));
  m.cyl('trim', 0.48, 0.5, 0.1, 14, V(0, 2.25, 0.5));
  m.bevel('paint', 0.95, 0.5, 0.07, V(0, 2.55, 0.02), 0.02);
  for (const s of [-1, 1]) m.bevel('paint', 0.07, 0.42, 0.45, V(s * 0.5, 2.52, 0.22), 0.02, { rot: RY(s * 0.4) });
  m.box('glass', 0.3, 0.14, 0.02, V(0, 2.62, -0.02));
  m.group('barrel', V(0, 2.5, 0.2));
  mg(m, 0, 2.5, 0.0, 1.5);
  m.box('pack', 0.18, 0.16, 0.24, V(0.13, 2.42, 0.2), { tint: [0.45, 0.48, 0.32] });
  m.meta = { muzzle: V(0, 2.51, -0.95), gunner: V(0, 1.6, 0.75), radius: 1.9 };
  return m;
}

export function technical_red() {
  // pikap + DŞK
  const m = new Model('technical_red');
  m.loft('paint', [
    [-2.55, [[0.85, 0.62], [0.82, 0.95]]],
    [-1.4, [[0.95, 0.55], [0.92, 1.05]]],
    [2.5, [[0.95, 0.55], [0.92, 1.05]]],
  ], { mirror: true });
  m.loft('paint', [
    [-1.4, [[0.92, 1.0], [0.92, 1.05]]],
    [-0.95, [[0.92, 1.05], [0.78, 1.65]]],
    [0.25, [[0.92, 1.05], [0.82, 1.7]]],
  ], { mirror: true });
  m.box('glass', 1.45, 0.48, 0.03, V(0, 1.38, -1.15), { rot: RX(-0.75) });
  for (const s of [-1, 1]) {
    m.box('glass', 0.03, 0.4, 0.75, V(s * 0.9, 1.38, -0.35), { rot: RZ(s * 0.1) });
    m.bevel('paint', 0.06, 0.45, 2.15, V(s * 0.92, 1.25, 1.4), 0.02);
    headlight(m, s * 0.62, 0.86, -2.56, 0.7);
    m.bevel('paint', 0.28, 0.08, 0.9, V(s * 0.88, 0.95, -1.75), 0.03);
    m.bevel('paint', 0.28, 0.08, 0.9, V(s * 0.88, 0.95, 1.65), 0.03);
    chevron(m, s * 0.96, 1.25, -1.6, 0.6, s);
  }
  m.bevel('paint', 1.85, 0.45, 0.06, V(0, 1.25, 2.47), 0.02);
  m.box('dark', 1.76, 0.04, 2.1, V(0, 1.03, 1.4));
  m.bevel('trim', 1.7, 0.22, 0.1, V(0, 0.68, -2.58), 0.03);
  m.box('dark', 1.3, 0.25, 0.03, V(0, 0.85, -2.57));
  bag(m, 0.5, 1.05, 2.1, 0.6, 0.3, 0.5);
  jerrycan(m, -0.55, 1.05, 2.1, 0);
  m.box('dark', 1.4, 0.04, 0.04, V(0, 1.7, 0.27));
  axles(m, [-1.65, 1.55], 0.86, 0.42, 0.42, 0.3);
  // ---- DŞK ayaklı yatak ----
  m.group('turret', V(0, 1.05, 1.2));
  m.cyl('metal', 0.07, 0.09, 0.95, 6, V(0, 1.52, 1.2));
  for (let k = 0; k < 3; k++) m.cyl('metal', 0.02, 0.02, 1.0, 4, V(Math.sin(k * 2.1) * 0.25, 1.4, 1.2 + Math.cos(k * 2.1) * 0.25), { rot: [Math.cos(k * 2.1) * 0.35, 0, -Math.sin(k * 2.1) * 0.35] });
  m.group('barrel', V(0, 2.05, 1.05));
  m.box('metal', 0.16, 0.2, 0.55, V(0, 2.05, 1.2));
  m.cyl('metal', 0.035, 0.032, 1.4, 6, V(0, 2.07, 0.3), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.05, 0.05, 0.12, 6, V(0, 2.07, -0.35), { rot: RX(Math.PI / 2) });
  m.bevel('trim', 0.6, 0.38, 0.04, V(0, 2.18, 0.82), 0.02);
  m.box('pack', 0.14, 0.14, 0.2, V(0.15, 1.98, 1.2), { tint: [0.4, 0.42, 0.3] });
  m.meta = { muzzle: V(0, 2.07, -0.4), gunner: V(0, 1.03, 1.85), radius: 1.9 };
  return m;
}

// ======================================================== ikmal kamyonu
function truck(name, blue) {
  const m = new Model(name);
  m.bevel('trim', 1.2, 0.3, 6.6, V(0, 0.92, 0.2), 0.04);                           // şasi
  if (blue) {
    // önü düz kabin
    m.loft('paint', [
      [-3.95, [[1.18, 0.95], [1.15, 2.2]]],
      [-3.7, [[1.22, 0.85], [1.2, 2.55]]],
      [-2.2, [[1.22, 0.85], [1.2, 2.6]]],
    ], { mirror: true });
    m.box('glass', 2.1, 0.75, 0.03, V(0, 2.05, -3.96), { rot: RX(0.12) });
    for (const s of [-1, 1]) {
      m.box('glass', 0.03, 0.55, 0.85, V(s * 1.22, 2.1, -3.05));
      headlight(m, s * 0.85, 1.15, -3.98, 0.85);
      m.bevel('paint', 0.42, 0.1, 0.95, V(s * 1.0, 1.32, -3.2), 0.03);
    }
    m.bevel('dark', 1.6, 0.4, 0.04, V(0, 1.35, -3.98), 0.02);
  } else {
    // burunlu kabin
    m.loft('paint', [
      [-4.0, [[0.8, 0.95], [0.78, 1.55]]],
      [-2.9, [[0.85, 0.9], [0.82, 1.7]]],
    ], { mirror: true });
    m.loft('paint', [
      [-2.95, [[1.15, 0.95], [1.1, 1.75]]],
      [-2.6, [[1.18, 0.9], [1.05, 2.5]]],
      [-1.6, [[1.18, 0.9], [1.05, 2.5]]],
    ], { mirror: true });
    m.box('glass', 1.9, 0.6, 0.03, V(0, 2.1, -2.78), { rot: RX(0.25) });
    for (const s of [-1, 1]) {
      m.box('glass', 0.03, 0.5, 0.6, V(s * 1.15, 2.1, -2.1));
      headlight(m, s * 0.95, 1.4, -2.98, 0.8);
      m.bevel('paint', 0.5, 0.12, 1.2, V(s * 0.95, 1.25, -3.3), 0.04);
    }
    grille(m, 0, 1.25, -4.01, 1.1, 0.04, 6);
  }
  // kasa + branda
  const z0 = blue ? -2.05 : -1.45;
  const L = 3.55 - z0;
  m.bevel('paint', 2.45, 0.12, L, V(0, 1.3, z0 + L / 2), 0.03);
  for (const s of [-1, 1]) {
    m.bevel('paint', 0.06, 0.5, L, V(s * 1.22, 1.6, z0 + L / 2), 0.02);
    chevron(m, s * 1.26, 1.6, 3.0, 0.9, s);
    m.box('red', 0.1, 0.1, 0.03, V(s * 1.0, 1.15, 3.55));
    jerrycan(m, s * 1.25, 1.0, -1.0, 0);
  }
  const prof = new THREE.Shape();
  prof.moveTo(-1.24, 0);
  for (let i = 0; i <= 10; i++) { const a = Math.PI - (i / 10) * Math.PI; prof.lineTo(Math.cos(a) * 1.24, 0.55 + Math.sin(a) * 0.6); }
  prof.lineTo(1.24, 0);
  const g = new THREE.ExtrudeGeometry(prof, { depth: L - 0.1, bevelEnabled: false });
  g.translate(0, 1.82, z0 + 0.05);
  m.add('canvas', g, { tint: blue ? [0.42, 0.44, 0.32] : [0.5, 0.47, 0.34], uv: 'box', uvScale: 0.35 });
  for (let i = 0; i < 5; i++) m.box('dark', 2.52, 0.03, 0.05, V(0, 2.95 + (i % 2) * 0.02, z0 + 0.3 + i * (L - 0.6) / 4));
  axles(m, [blue ? -3.05 : -2.7, 0.9, 2.3], 1.05, 0.55, 0.55, 0.4);
  m.meta = { radius: 2.3 };
  return m;
}
export const truck_blue = () => truck('truck_blue', true);
export const truck_red = () => truck('truck_red', false);

export const ARMOR2 = { apc_blue, apc_red, ifv_blue, ifv_red, aa_blue, aa_red, arty_blue, arty_red, technical_blue, technical_red, truck_blue, truck_red };
