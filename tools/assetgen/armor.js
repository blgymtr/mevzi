// Zırhlı araçlar v2 (eğimli zırh, gerçek yürüyen aksam, teçhizat). İleri -Z.
// Düğümler: hull, turret (taret halkası pivotu), barrel (muylu pivotu), wheel_N.
import { Model, THREE } from './lib.js';
import {
  V, RX, RY, RZ, runningGear, tyre, hatch, periscope, smokeLaunchers, antenna, jerrycan, bag, toolbox,
  headlight, mg, cannon, chevron, grille, exhaust, towHook, eraGrid,
} from './parts.js';

// ======================================================== MAVİ: Batı tipi ana muharebe tankı
export function tank_blue() {
  const m = new Model('tank_blue');
  runningGear(m, { x: 1.38, w: 0.64, zF: -3.55, zB: 3.45, y: 0.42, r: 0.34, n: 7, topY: 0.86 });
  // alt gövde (paletler arası)
  m.loft('paint', [[-3.75, [[1.05, 0.5], [1.05, 0.95]]], [-3.2, [[1.1, 0.3], [1.1, 1.0]]], [3.6, [[1.1, 0.35], [1.1, 1.25]]]], { mirror: true });
  // üst gövde + çamurluklar + eğimli ön zırh
  m.loft('paint', [
    [-3.95, [[1.62, 0.92], [1.58, 1.02]]],
    [-2.45, [[1.8, 0.92], [1.78, 1.33]]],
    [3.72, [[1.8, 0.92], [1.78, 1.33]]],
    [3.86, [[1.7, 0.96], [1.68, 1.28]]],
  ], { mirror: true });
  // yan etekler: 4 panel + cıvata sırası
  for (const s of [-1, 1]) {
    const X = s * 1.86;
    const panels = [[-3.25, 1.0], [-2.1, 1.25], [-0.8, 1.25], [0.5, 1.25], [1.8, 1.25]];
    for (const [z, L] of panels) {
      m.bevel('paint', 0.1, 0.62, L - 0.04, V(X, 0.92, z), 0.03);
      for (let k = 0; k < 4; k++) m.box('dark', 0.02, 0.04, 0.04, V(X + s * 0.05, 1.16, z - L / 2 + 0.15 + (k * (L - 0.3)) / 3));
    }
    m.add('paint', new THREE.BoxGeometry(0.1, 0.5, 0.7), { pos: V(X, 0.86, -3.92), rot: RX(0.45) });
    headlight(m, s * 1.45, 1.22, -3.66);
    towHook(m, s * 0.75, 0.62, -3.8);
    // çamurluk üzerinde takım ve kutular
    toolbox(m, s * 1.5, 1.33, 2.4, 0.5, 0.26, 1.2);
    m.box('dark', 0.05, 0.03, 2.2, V(s * 1.25, 1.36, 0.6));        // çekme halatı
  }
  // sürücü kapağı + periskoplar
  hatch(m, 0, 1.31, -2.25, 0.32);
  for (const k of [-1, 0, 1]) periscope(m, k * 0.22, 1.31, -2.62, -k * 0.25);
  // motor güvertesi
  grille(m, 0, 1.34, 2.15, 2.4, 1.3, 9);
  m.bevel('paint', 2.6, 0.08, 1.0, V(0, 1.37, 0.95), 0.03);
  for (const s of [-1, 1]) m.box('dark', 0.04, 0.02, 3.0, V(s * 1.32, 1.35, 1.5));
  // arka
  exhaust(m, 0, 1.08, 3.92, 1.6, 0.3);
  for (const s of [-1, 1]) {
    m.box('red', 0.12, 0.08, 0.04, V(s * 1.55, 1.2, 3.9));
    towHook(m, s * 0.9, 0.7, 3.85);
    jerrycan(m, s * 1.25, 1.33, 3.45, Math.PI / 2);
  }
  // ---- taret ----
  m.group('turret', V(0, 1.4, -0.3));
  // çekirdek gövde
  m.loft('paint', [
    [-2.2, [[1.15, 1.45], [1.05, 2.16]]],
    [-1.4, [[1.72, 1.43], [1.66, 2.2]]],
    [1.35, [[1.7, 1.46], [1.62, 2.22]]],
    [1.6, [[1.45, 1.5], [1.4, 2.16]]],
  ], { mirror: true });
  // kama ön ek zırh (iki yanda, ortada namlu boşluğu)
  for (const s of [-1, 1]) {
    const pts = [];
    for (const y of [1.47, 2.13]) {
      pts.push([s * 0.42, y, -2.88], [s * 0.42, y - (y > 2 ? 0.04 : 0), -2.25], [s * 1.8, y, -1.62], [s * 1.8, y, -1.32]);
    }
    m.hull('paint', pts);
    m.box('dark', 0.02, 0.6, 0.02, V(s * 1.1, 1.8, -2.25));
  }
  // bagaj sepeti
  m.bevel('paint', 3.0, 0.5, 1.05, V(0, 1.72, 2.1), 0.05);
  for (let i = 0; i < 5; i++) m.box('dark', 3.1, 0.04, 0.04, V(0, 2.08, 1.65 + i * 0.24));
  for (const s of [-1, 1]) m.box('dark', 0.04, 0.4, 1.1, V(s * 1.53, 1.98, 2.1));
  bag(m, -0.7, 1.97, 2.1, 1.1, 0.34, 0.75, 0.05);
  bag(m, 0.65, 1.97, 2.05, 0.9, 0.3, 0.7, -0.08);
  jerrycan(m, 1.25, 1.97, 2.25, 0.0);
  // tavan: komutan kubbesi, panoramik nişangah, nişancı nişangahı, yükleyici kapağı
  m.cyl('paint', 0.42, 0.46, 0.18, 14, V(-0.65, 2.29, 0.25));
  for (let k = 0; k < 6; k++) periscope(m, -0.65 + Math.sin(k) * 0.4, 2.3, 0.25 + Math.cos(k) * 0.4, k);
  hatch(m, -0.65, 2.38, 0.25, 0.32);
  m.bevel('paint', 0.42, 0.4, 0.42, V(-0.95, 2.42, -0.55), 0.06);
  m.box('glass', 0.3, 0.2, 0.02, V(-0.95, 2.48, -0.77));
  m.cyl('trim', 0.12, 0.14, 0.2, 10, V(-0.95, 2.2, -0.55));
  m.bevel('paint', 0.55, 0.32, 0.7, V(0.78, 2.32, -1.15), 0.06);
  m.box('glass', 0.38, 0.18, 0.02, V(0.78, 2.35, -1.51));
  hatch(m, 0.6, 2.21, 0.45, 0.3);
  m.cyl('trim', 0.05, 0.05, 0.3, 6, V(0.62, 2.37, 0.05));
  mg(m, 0.62, 2.55, 0.0, 1.1);
  for (const s of [-1, 1]) {
    smokeLaunchers(m, s * 1.6, 1.98, 0.85, 4, s * -0.9, 0.55);
    antenna(m, s * 1.25, 2.2, 1.35, 2.4, { leanZ: -s * 0.05 });
    toolbox(m, s * 1.78, 1.5, 0.35, 0.18, 0.5, 1.4);
    chevron(m, s * 1.87, 1.75, 0.35, 1.0, s);
  }
  m.cyl('dark', 0.015, 0.015, 0.5, 4, V(0, 2.45, 1.25));
  m.cyl('trim', 0.06, 0.06, 0.06, 6, V(0, 2.72, 1.25));
  // kalkan (mantolet) — tarete bağlı
  m.bevel('trim', 0.74, 0.62, 0.55, V(0, 1.86, -2.62), 0.06);
  // ---- namlu ----
  m.group('barrel', V(0, 1.86, -2.65));
  cannon(m, 1.86, -2.85, 5.0, 0.115, { bands: 4, evacAt: 0.42 });
  m.box('trim', 0.12, 0.08, 0.1, V(0, 2.0, -7.7));               // namlu referans sensörü
  m.meta = { muzzle: V(0, 1.86, -7.9), radius: 2.9 };
  return m;
}

// ======================================================== KIZIL: Doğu tipi alçak silüetli tank
export function tank_red() {
  const m = new Model('tank_red');
  runningGear(m, { x: 1.3, w: 0.58, zF: -3.0, zB: 2.95, y: 0.45, r: 0.4, n: 6, ret: 3, spokes: 8, topY: 0.95 });
  m.loft('paint', [[-3.15, [[1.0, 0.45], [1.0, 0.85]]], [-2.6, [[1.05, 0.3], [1.05, 0.95]]], [3.0, [[1.05, 0.35], [1.05, 1.0]]]], { mirror: true });
  m.loft('paint', [
    [-3.3, [[1.5, 0.84], [1.46, 0.9]]],
    [-1.95, [[1.65, 0.86], [1.62, 1.12]]],
    [3.05, [[1.65, 0.86], [1.6, 1.12]]],
    [3.12, [[1.55, 0.88], [1.52, 1.08]]],
  ], { mirror: true });
  // ön zırhta reaktif zırh tuğlaları
  eraGrid(m, 0, 1.0, -2.62, 6, 3, 0.46, 0.4, RX(1.38));
  for (const s of [-1, 1]) {
    // lastik yan etek + ERA kanatları
    m.box('rubber', 0.04, 0.2, 5.2, V(s * 1.63, 0.98, -0.05), { tint: [0.9, 0.9, 0.9] });
    for (let i = 0; i < 4; i++) m.bevel('paint', 0.06, 0.38, 0.5, V(s * 1.64, 0.82, -2.75 + i * 0.52), 0.02, { tint: [0.92, 0.92, 0.9] });
    // çamurluk kutuları
    for (let i = 0; i < 3; i++) toolbox(m, s * 1.42, 1.12, 0.2 + i * 0.95, 0.38, 0.28, 0.85);
    headlight(m, s * 1.25, 1.16, -2.6, 0.85);
    towHook(m, s * 0.7, 0.62, -3.22);
  }
  exhaust(m, -1.62, 1.0, 1.8, 0.12, 0.3);
  grille(m, 0, 1.13, 2.05, 2.2, 1.5, 8);
  // arka: varil + kütük
  for (const x of [-0.75, 0.75]) {
    m.cyl('paint', 0.3, 0.3, 1.1, 14, V(x, 1.42, 3.1), { rot: RZ(Math.PI / 2), tint: [0.85, 0.85, 0.82] });
    for (const dx of [-0.4, 0.4]) m.cyl('dark', 0.31, 0.31, 0.03, 14, V(x + dx, 1.42, 3.1), { rot: RZ(Math.PI / 2) });
  }
  m.cyl('wood', 0.13, 0.13, 3.0, 9, V(0, 1.22, 2.72), { rot: RZ(Math.PI / 2) });
  hatch(m, 0, 1.1, -1.75, 0.28);
  periscope(m, 0, 1.1, -2.05);
  // ---- taret: döküm kubbe + kapaklı reaktif zırh ----
  m.group('turret', V(0, 1.1, -0.4));
  m.add('paint', new THREE.SphereGeometry(1.2, 22, 10, 0, Math.PI * 2, 0, Math.PI * 0.5), { pos: V(0, 1.12, -0.35), scale: [1.0, 0.52, 1.12] });
  m.cyl('paint', 1.21, 1.26, 0.12, 22, V(0, 1.1, -0.35), { scale: [1, 1, 1.12] });
  for (const s of [-1, 1]) {
    const pts = [];
    for (const y of [1.15, 1.6]) {
      const k = y > 1.3 ? 0.06 : 0;
      pts.push([s * 0.26, y, -1.62 + k], [s * 0.26, y, -1.3 + k], [s * (1.22 - k), y, -0.88 + k], [s * (1.15 - k), y, -0.6 + k]);
    }
    m.hull('paint', pts, { tint: [0.95, 0.95, 0.93] });
    for (let i = 0; i < 3; i++) m.box('dark', 0.02, 0.02, 0.5, V(s * (0.45 + i * 0.25), 1.61, -1.25 + i * 0.17), { rot: RY(s * 0.95) });
    // göz kamaştırıcı projektörler (kırmızı mercek)
    m.bevel('trim', 0.34, 0.22, 0.3, V(s * 0.95, 1.35, -1.12), 0.04);
    m.box('red', 0.24, 0.14, 0.02, V(s * 0.95, 1.35, -1.28));
    // sis atarlar yay şeklinde
    for (let i = 0; i < 6; i++) {
      const a = -0.6 + i * 0.25;
      m.cyl('dark', 0.04, 0.04, 0.28, 7, V(s * (1.05 + Math.sin(a) * 0.05), 1.52, -0.2 + i * 0.12), { rot: [Math.PI / 2 - 0.5, s * (1.3 + a * 0.2), 0] });
    }
  }
  // kubbe, makineli, kapaklar
  m.cyl('paint', 0.36, 0.4, 0.2, 14, V(-0.45, 1.72, 0.0));
  hatch(m, -0.45, 1.82, 0.0, 0.3);
  m.cyl('trim', 0.06, 0.06, 0.32, 6, V(-0.45, 2.0, -0.32));
  mg(m, -0.45, 2.18, -0.35, 1.25);
  m.bevel('trim', 0.12, 0.22, 0.24, V(-0.25, 2.18, -0.55), 0.02);
  hatch(m, 0.48, 1.7, 0.15, 0.3);
  m.bevel('paint', 0.32, 0.3, 0.42, V(0.62, 1.82, -0.62), 0.05);
  m.box('glass', 0.24, 0.16, 0.02, V(0.62, 1.86, -0.84));
  // arka: şnorkel borusu + kutu
  m.cyl('paint', 0.1, 0.1, 1.9, 10, V(0, 1.5, 0.95), { rot: RZ(Math.PI / 2), tint: [0.9, 0.9, 0.88] });
  m.bevel('paint', 1.3, 0.35, 0.45, V(0, 1.3, 1.05), 0.05);
  antenna(m, 0.75, 1.62, 0.65, 2.0);
  for (const s of [-1, 1]) chevron(m, s * 1.17, 1.35, 0.15, 0.9, s);
  // kalkan
  m.bevel('trim', 0.6, 0.48, 0.4, V(0, 1.36, -1.42), 0.06);
  // ---- namlu ----
  m.group('barrel', V(0, 1.36, -1.45));
  cannon(m, 1.36, -1.62, 4.3, 0.105, { bands: 3, evacAt: 0.42 });
  m.meta = { muzzle: V(0, 1.36, -5.95), radius: 2.7 };
  return m;
}


export const ARMOR = { tank_blue, tank_red };
