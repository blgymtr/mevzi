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
  // ---- taret: Abrams tipi (alçak, geniş, köşeli; önde V plakalar) ----
  m.group('turret', V(0, 1.4, -0.3));
  const tp = [];
  for (const s of [-1, 1]) {
    tp.push([s * 0.52, 1.44, -2.62], [s * 0.48, 2.02, -2.42]);      // namlu yanı (V'nin dibi)
    tp.push([s * 1.78, 1.44, -1.95], [s * 1.66, 2.08, -1.78]);      // ön köşe
    tp.push([s * 1.84, 1.44, 1.15], [s * 1.72, 2.14, 1.15]);        // yan arka
    tp.push([s * 1.62, 1.48, 1.95], [s * 1.5, 2.1, 1.95]);          // bagaj başlangıcı
  }
  m.hull('paint', tp);
  // ön plaka ek yerleri
  for (const s of [-1, 1]) {
    m.box('dark', 0.02, 0.55, 0.02, V(s * 1.15, 1.75, -2.2), { rot: RY(s * 0.5) });
    m.box('dark', 1.2, 0.02, 0.02, V(s * 1.1, 2.06, -2.08), { rot: RY(-s * 0.45) });
  }
  // bagaj sepeti (ızgaralı)
  m.bevel('paint', 3.0, 0.12, 1.05, V(0, 1.52, 2.45), 0.03);
  for (let i = 0; i < 6; i++) m.box('dark', 0.03, 0.5, 0.03, V(-1.45 + i * 0.58, 1.8, 2.95));
  for (const y of [1.78, 2.05]) m.box('dark', 3.0, 0.03, 0.03, V(0, y, 2.97));
  for (const s of [-1, 1]) for (const y of [1.78, 2.05]) m.box('dark', 0.03, 0.03, 1.05, V(s * 1.5, y, 2.45));
  bag(m, -0.75, 1.58, 2.45, 1.2, 0.42, 0.8, 0.05);
  bag(m, 0.55, 1.58, 2.4, 0.8, 0.36, 0.75, -0.06);
  jerrycan(m, 1.2, 1.58, 2.5, 0.0);
  m.cyl('canvas', 0.2, 0.2, 1.6, 10, V(0, 2.0, 2.55), { rot: RZ(Math.PI / 2), tint: [0.45, 0.47, 0.34] });   // rulo kamuflaj ağı
  // yan kutular
  for (const s of [-1, 1]) {
    toolbox(m, s * 1.86, 1.55, 0.2, 0.16, 0.42, 1.6);
    smokeLaunchers(m, s * 1.55, 2.08, -1.55, 6, s * -0.75, 0.5);
    chevron(m, s * 1.9, 1.82, -0.6, 1.0, s);
  }
  // komutan (sağ): uzaktan kumandalı silah + kapak + periskoplar
  m.cyl('paint', 0.45, 0.48, 0.14, 14, V(0.75, 2.2, 0.35));
  for (let k = 0; k < 6; k++) periscope(m, 0.75 + Math.sin(k * 1.05) * 0.42, 2.2, 0.35 + Math.cos(k * 1.05) * 0.42, k * 1.05);
  hatch(m, 0.75, 2.27, 0.45, 0.3);
  m.bevel('trim', 0.34, 0.3, 0.45, V(0.75, 2.55, 0.0), 0.04);
  m.box('glass', 0.18, 0.12, 0.02, V(0.85, 2.58, -0.23));
  mg(m, 0.62, 2.62, -0.1, 1.3);
  m.bevel('pack', 0.2, 0.2, 0.26, V(0.48, 2.55, 0.05), 0.03, { tint: [0.42, 0.44, 0.32] });
  // nişancı ana nişangahı (sağ ön, "köpek kulübesi")
  m.bevel('paint', 0.62, 0.36, 0.78, V(0.95, 2.26, -1.35), 0.06);
  m.box('glass', 0.42, 0.2, 0.02, V(0.95, 2.3, -1.75));
  // yükleyici (sol): kapak + kalkanlı makineli
  hatch(m, -0.68, 2.15, 0.35, 0.32);
  m.cyl('trim', 0.05, 0.05, 0.28, 6, V(-0.68, 2.3, -0.05));
  m.bevel('paint', 0.62, 0.32, 0.04, V(-0.68, 2.48, -0.32), 0.015);
  mg(m, -0.68, 2.5, -0.15, 1.15);
  // komutanın bağımsız görüş sistemi (sol arka)
  m.cyl('trim', 0.14, 0.16, 0.25, 10, V(-1.05, 2.25, 0.9));
  m.bevel('paint', 0.34, 0.3, 0.36, V(-1.05, 2.5, 0.9), 0.04);
  m.box('glass', 0.22, 0.14, 0.02, V(-1.05, 2.52, 0.71));
  // rüzgâr sensörü ve antenler
  m.cyl('dark', 0.015, 0.015, 0.55, 4, V(0.0, 2.4, 1.6));
  m.cyl('trim', 0.05, 0.05, 0.08, 6, V(0.0, 2.7, 1.6));
  antenna(m, -1.35, 2.12, 1.65, 2.6, { leanZ: 0.05 });
  antenna(m, 1.35, 2.12, 1.65, 2.2, { leanZ: -0.05 });
  // kalkan (mantolet): dikdörtgen blok + eş eksenli makineli deliği
  m.bevel('trim', 0.92, 0.66, 0.5, V(0, 1.8, -2.62), 0.05);
  m.cyl('dark', 0.04, 0.04, 0.06, 6, V(0.3, 1.82, -2.88), { rot: RX(Math.PI / 2) });
  // ---- namlu: 120 mm, ısı kılıfı, duman tahliyesi yok ----
  m.group('barrel', V(0, 1.82, -2.65));
  cannon(m, 1.82, -2.85, 5.05, 0.115, { bands: 5, evac: false });
  m.box('trim', 0.12, 0.08, 0.12, V(0, 1.96, -7.75));
  m.meta = { muzzle: V(0, 1.82, -7.95), radius: 2.9 };
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
