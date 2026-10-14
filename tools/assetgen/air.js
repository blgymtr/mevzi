// Hava araçları v2: saldırı ve nakliye helikopterleri, FPV drone. İleri -Z.
// Düğümler: hull, rotor (ana rotor göbeği), trotor (kuyruk rotoru, X ekseninde döner).
import { Model, THREE } from './lib.js';
import { V, RX, RY, RZ, antenna } from './parts.js';

function blades(m, y, z, n, R, chord, x = 0, phase = 0) {
  m.cyl('trim', 0.22, 0.26, 0.28, 10, V(x, y, z));
  m.cyl('dark', 0.1, 0.1, 0.5, 8, V(x, y + 0.3, z));
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2 + phase;
    const ca = Math.cos(a), sa = Math.sin(a);
    const pts = [];
    for (const [r, c] of [[0.25, chord * 0.6], [0.6, chord], [R, chord * 0.8]]) {
      for (const s of [-1, 1]) for (const t of [-0.02, 0.02]) {
        const lx = r, lz = s * c / 2;
        pts.push([x + lx * ca - lz * sa, y + 0.15 + t - r * 0.01, z + lx * sa + lz * ca]);
      }
    }
    m.hull('dark', pts);
  }
}

function tailRotor(m, x, y, z, n, R) {
  m.cyl('trim', 0.1, 0.1, 0.2, 8, V(x, y, z), { rot: RZ(Math.PI / 2) });
  for (let i = 0; i < n; i++) {
    const a = (i / n) * Math.PI * 2;
    m.box('dark', 0.03, R * 2 * 0.5, 0.14, V(x + 0.04, y + Math.cos(a) * R * 0.5, z + Math.sin(a) * R * 0.5), { rot: RX(-a) });
  }
}

function rocketPod(m, x, y, z, L = 1.3, r = 0.2) {
  m.cyl('paint', r, r, L, 12, V(x, y, z), { rot: RX(Math.PI / 2) });
  m.cyl('dark', r * 0.9, r * 0.9, 0.03, 12, V(x, y, z - L / 2 - 0.01), { rot: RX(Math.PI / 2) });
  for (let k = 0; k < 7; k++) {
    const a = (k / 6) * Math.PI * 2;
    const rr = k === 6 ? 0 : r * 0.55;
    m.cyl('trim', 0.035, 0.035, 0.04, 6, V(x + Math.cos(a) * rr, y + Math.sin(a) * rr, z - L / 2 - 0.02), { rot: RX(Math.PI / 2) });
  }
  m.add('paint', new THREE.ConeGeometry(r, 0.35, 12), { pos: V(x, y, z + L / 2 + 0.17), rot: RX(Math.PI / 2) });
}

function missileRack(m, x, y, z) {
  m.box('trim', 0.1, 0.1, 1.2, V(x, y + 0.12, z));
  for (const dx of [-0.12, 0.12]) for (const dy of [0, -0.24]) {
    m.cyl('pack', 0.07, 0.07, 1.25, 8, V(x + dx, y + dy - 0.05, z), { rot: RX(Math.PI / 2), tint: [0.4, 0.42, 0.3] });
    m.add('pack', new THREE.ConeGeometry(0.07, 0.18, 8), { pos: V(x + dx, y + dy - 0.05, z - 0.71), rot: RX(-Math.PI / 2), tint: [0.4, 0.42, 0.3] });
  }
}

function skidWheel(m, x, y, z, r = 0.22) {
  m.cyl('rubber', r, r, 0.16, 12, V(x, y, z), { rot: RZ(Math.PI / 2) });
  m.cyl('metal', r * 0.5, r * 0.5, 0.18, 8, V(x, y, z), { rot: RZ(Math.PI / 2) });
}

// ======================================================== MAVİ saldırı helikopteri (tandem kokpit)
export function heli_blue() {
  const m = new Model('heli_blue');
  // gövde
  m.loft('paint', [
    [-3.2, [[0.18, -0.85], [0.22, -0.45]]],
    [-2.4, [[0.45, -1.0], [0.5, -0.3], [0.32, 0.1]]],
    [-0.6, [[0.55, -1.05], [0.62, 0.1], [0.42, 0.75]]],
    [1.4, [[0.55, -0.95], [0.6, 0.1], [0.4, 0.7]]],
    [2.6, [[0.35, -0.55], [0.38, 0.1], [0.25, 0.45]]],
  ], { mirror: true });
  // basamaklı kokpit camları
  m.loft('glass', [[-2.75, [[0.3, -0.35], [0.2, -0.05]]], [-2.0, [[0.4, -0.3], [0.3, 0.2]]], [-1.55, [[0.4, -0.3], [0.32, 0.22]]]], { mirror: true });
  m.loft('glass', [[-1.5, [[0.42, -0.1], [0.3, 0.5]]], [-0.7, [[0.44, -0.05], [0.34, 0.7]]], [-0.4, [[0.44, -0.05], [0.34, 0.65]]]], { mirror: true });
  // burun sensör kulesi + top
  m.cyl('trim', 0.26, 0.28, 0.45, 12, V(0, -0.6, -3.25), { rot: RX(Math.PI / 2) });
  m.add('glass', new THREE.SphereGeometry(0.22, 10, 6), { pos: V(0, -0.6, -3.5), scale: [1, 1, 0.5] });
  m.cyl('trim', 0.16, 0.16, 0.3, 10, V(0, -1.08, -2.4));
  m.cyl('metal', 0.035, 0.035, 1.0, 6, V(0, -1.1, -2.9), { rot: RX(Math.PI / 2) });
  // motor nacelleri + egzoz
  for (const s of [-1, 1]) {
    m.cyl('paint', 0.3, 0.3, 2.0, 12, V(s * 0.78, 0.6, 0.6), { rot: RX(Math.PI / 2) });
    m.cyl('dark', 0.24, 0.24, 0.05, 12, V(s * 0.78, 0.6, -0.42), { rot: RX(Math.PI / 2) });
    m.bevel('trim', 0.3, 0.25, 0.5, V(s * 0.85, 0.75, 1.75), 0.05, { rot: RY(s * 0.3) });
    // kanatçık + yükler
    m.loft('paint', [[-0.5, [[0.55, -0.1], [0.55, 0.0]]], [-0.5, [[2.1, -0.15], [2.1, -0.07]]], [0.3, [[2.1, -0.15], [2.1, -0.07]]], [0.4, [[0.55, -0.1], [0.55, 0.0]]]].map(([z, r]) => [z, r.map(([x, y]) => [s * x, y])]));
    rocketPod(m, s * 1.25, -0.42, -0.1);
    missileRack(m, s * 1.9, -0.35, -0.15);
    m.box('trim', 0.08, 0.32, 0.3, V(s * 1.25, -0.2, -0.1));
    // iniş takımı
    m.box('trim', 0.08, 0.6, 0.12, V(s * 0.62, -1.15, -1.6), { rot: RZ(s * 0.25) });
    skidWheel(m, s * 0.7, -1.45, -1.6);
    m.box('mark', 0.02, 0.18, 0.5, V(s * 0.6, 0.0, 1.0));
  }
  // kuyruk kirişi + dikey/yatay dengeleyici
  m.loft('paint', [[2.4, [[0.3, -0.3], [0.3, 0.42]]], [8.2, [[0.1, 0.05], [0.1, 0.4]]]], { mirror: true });
  m.hull('paint', [[0, 0.1, 7.4], [0, 0.4, 7.2], [0, 2.0, 8.1], [0, 2.0, 8.7], [0, 0.1, 8.6], [0.09, 0.3, 8.0], [-0.09, 0.3, 8.0], [0.06, 1.9, 8.4], [-0.06, 1.9, 8.4]]);
  m.bevel('paint', 2.4, 0.06, 0.6, V(0, 0.35, 8.1), 0.02);
  skidWheel(m, 0, -0.1, 7.6, 0.14);
  antenna(m, 0, 0.75, 1.6, 0.4);
  m.group('rotor', V(0, 1.15, 0.3));
  blades(m, 1.15, 0.3, 4, 3.8, 0.4, 0, 0.3);
  m.cyl('trim', 0.28, 0.28, 0.12, 12, V(0, 1.75, 0.3));         // mast radarı
  m.group('trotor', V(0.12, 1.0, 8.0));
  tailRotor(m, 0.18, 1.0, 8.0, 4, 1.2);
  m.meta = { muzzle: V(0, -1.1, -3.4), radius: 3.4 };
  return m;
}

// ======================================================== KIZIL saldırı helikopteri (Hind tipi)
export function heli_red() {
  const m = new Model('heli_red');
  m.loft('paint', [
    [-4.6, [[0.3, -0.95], [0.32, -0.55]]],
    [-3.4, [[0.6, -1.15], [0.65, -0.2], [0.4, 0.3]]],
    [-1.8, [[0.85, -1.25], [0.9, 0.25], [0.6, 0.9]]],
    [2.0, [[0.85, -1.15], [0.88, 0.3], [0.6, 0.95]]],
    [3.4, [[0.5, -0.65], [0.55, 0.3], [0.4, 0.75]]],
  ], { mirror: true });
  // iki kabarcık kokpit
  m.add('glass', new THREE.SphereGeometry(0.55, 12, 7, 0, Math.PI * 2, 0, Math.PI * 0.55), { pos: V(0, -0.45, -3.7), scale: [0.95, 0.9, 1.3] });
  m.add('glass', new THREE.SphereGeometry(0.62, 12, 7, 0, Math.PI * 2, 0, Math.PI * 0.55), { pos: V(0, 0.15, -2.45), scale: [0.95, 0.95, 1.25] });
  m.cyl('trim', 0.2, 0.22, 0.35, 10, V(0, -1.2, -4.0));
  m.cyl('metal', 0.04, 0.035, 0.8, 6, V(0, -1.22, -4.5), { rot: RX(Math.PI / 2) });
  // motor üst yapısı + egzozlar
  m.loft('trim', [[-1.6, [[0.6, 0.85], [0.45, 1.3]]], [1.8, [[0.65, 0.9], [0.5, 1.35]]], [2.4, [[0.45, 0.85], [0.3, 1.15]]]], { mirror: true });
  for (const s of [-1, 1]) {
    m.cyl('dark', 0.24, 0.26, 0.5, 10, V(s * 0.62, 1.05, -1.75), { rot: RX(Math.PI / 2) });
    m.bevel('dark', 0.28, 0.3, 0.7, V(s * 0.8, 1.0, 2.1), 0.05, { rot: RY(s * 0.4) });
    // aşağı eğik kanatlar + pod ve füzeler
    m.loft('paint', [[-1.0, [[0.85, -0.25], [0.85, -0.1]]], [-1.0, [[2.6, -0.65], [2.6, -0.52]]], [0.0, [[2.6, -0.65], [2.6, -0.52]]], [0.1, [[0.85, -0.25], [0.85, -0.1]]]].map(([z, r]) => [z, r.map(([x, y]) => [s * x, y])]));
    rocketPod(m, s * 1.5, -0.7, -0.45, 1.4, 0.22);
    rocketPod(m, s * 2.15, -0.85, -0.45, 1.3, 0.2);
    m.cyl('pack', 0.08, 0.08, 1.3, 8, V(s * 2.65, -0.85, -0.5), { rot: RX(Math.PI / 2), tint: [0.45, 0.48, 0.32] });
    // kapı, pencereler
    m.box('trim', 0.03, 0.7, 0.9, V(s * 0.88, -0.2, -0.6));
    for (let i = 0; i < 2; i++) m.box('glass', 0.03, 0.25, 0.3, V(s * 0.89, 0.1, 0.4 + i * 0.6));
    m.box('mark', 0.02, 0.2, 0.55, V(s * 0.88, -0.2, 2.6));
    // iniş takımı
    m.box('trim', 0.1, 0.65, 0.12, V(s * 0.9, -1.35, 0.6), { rot: RZ(s * 0.35) });
    skidWheel(m, s * 1.05, -1.65, 0.6, 0.26);
  }
  skidWheel(m, 0, -1.55, -3.1, 0.2);
  m.loft('paint', [[3.2, [[0.4, -0.3], [0.38, 0.65]]], [7.8, [[0.12, 0.2], [0.12, 0.55]]]], { mirror: true });
  m.hull('paint', [[0, 0.3, 7.0], [0, 0.5, 6.9], [0, 2.1, 7.8], [0, 2.1, 8.25], [0, 0.3, 8.1], [0.1, 0.5, 7.6], [-0.1, 0.5, 7.6]]);
  m.bevel('paint', 2.2, 0.07, 0.6, V(0, 0.5, 6.8), 0.02);
  antenna(m, 0, 0.95, 1.2, 0.5);
  m.group('rotor', V(0, 1.35, 0));
  blades(m, 1.45, 0, 5, 4.3, 0.45);
  m.group('trotor', V(0.12, 1.1, 7.6));
  tailRotor(m, 0.18, 1.6, 7.9, 3, 1.3);
  m.meta = { muzzle: V(0, -1.25, -4.9), radius: 3.6 };
  return m;
}

// ======================================================== nakliye helikopterleri
export function transport_blue() {
  const m = new Model('transport_blue');
  m.loft('paint', [
    [-3.5, [[0.35, -0.75], [0.4, -0.2]]],
    [-2.6, [[0.85, -0.95], [0.95, 0.3], [0.6, 0.85]]],
    [1.6, [[0.95, -0.95], [1.0, 0.35], [0.7, 1.0]]],
    [2.8, [[0.6, -0.6], [0.65, 0.35], [0.45, 0.85]]],
  ], { mirror: true });
  m.loft('glass', [[-3.35, [[0.4, -0.5], [0.42, -0.15]]], [-2.65, [[0.86, -0.55], [0.88, 0.25], [0.55, 0.78]]], [-2.35, [[0.88, -0.2], [0.6, 0.78]]]], { mirror: true });
  m.loft('trim', [[-1.4, [[0.6, 0.9], [0.45, 1.35]]], [1.2, [[0.7, 0.95], [0.5, 1.4]]], [1.9, [[0.45, 0.9], [0.3, 1.2]]]], { mirror: true });
  for (const s of [-1, 1]) {
    m.box('trim', 0.03, 1.0, 1.5, V(s * 0.98, -0.25, -0.9));                 // sürgülü kapı
    m.box('glass', 0.03, 0.32, 0.4, V(s * 0.99, 0.15, -1.2));
    m.box('glass', 0.03, 0.3, 0.38, V(s * 0.98, 0.15, 0.7));
    m.cyl('dark', 0.24, 0.24, 0.4, 10, V(s * 0.55, 1.12, -1.5), { rot: RX(Math.PI / 2) });
    m.bevel('dark', 0.25, 0.22, 0.5, V(s * 0.7, 1.12, 1.7), 0.05, { rot: RY(s * 0.4) });
    m.box('mark', 0.02, 0.22, 0.6, V(s * 0.96, -0.1, 1.9));
    m.box('trim', 0.08, 0.5, 0.12, V(s * 0.85, -1.1, -2.0), { rot: RZ(s * 0.3) });
    skidWheel(m, s * 0.95, -1.35, -2.0, 0.25);
    // kapı makineli tüfeği
    m.box('metal', 0.07, 0.1, 0.9, V(s * 1.05, 0.15, -1.0));
  }
  m.loft('paint', [[2.6, [[0.4, -0.2], [0.38, 0.8]]], [8.6, [[0.12, 0.45], [0.12, 0.75]]]], { mirror: true });
  m.hull('paint', [[0, 0.5, 7.9], [0, 0.8, 7.7], [0, 2.1, 8.4], [0, 2.1, 8.9], [0, 0.5, 8.8], [0.09, 0.7, 8.3], [-0.09, 0.7, 8.3]]);
  m.bevel('paint', 2.5, 0.06, 0.6, V(0, 0.6, 8.4), 0.02);
  skidWheel(m, 0, 0.2, 7.9, 0.14);
  antenna(m, 0, 1.0, 2.0, 0.5);
  m.group('rotor', V(0, 1.6, -0.2));
  blades(m, 1.6, -0.2, 4, 4.4, 0.45);
  m.group('trotor', V(0.15, 1.4, 8.4));
  tailRotor(m, 0.2, 1.6, 8.6, 4, 1.2);
  m.meta = { muzzle: V(1.05, 0.15, -1.45), radius: 3.8 };
  return m;
}

export function transport_red() {
  const m = new Model('transport_red');
  m.loft('paint', [
    [-3.7, [[0.45, -0.6], [0.5, 0.1]]],
    [-2.9, [[1.0, -1.0], [1.1, 0.45], [0.75, 1.1]]],
    [2.6, [[1.05, -1.0], [1.12, 0.5], [0.8, 1.15]]],
    [3.6, [[0.75, -0.7], [0.8, 0.5], [0.55, 1.05]]],
  ], { mirror: true });
  m.add('glass', new THREE.SphereGeometry(0.95, 12, 7, 0, Math.PI * 2, 0, Math.PI * 0.5), { pos: V(0, 0.15, -3.05), rot: RX(-Math.PI / 2 + 0.35), scale: [1.0, 0.85, 0.75] });
  m.loft('trim', [[-2.2, [[0.75, 1.05], [0.6, 1.6]]], [1.6, [[0.8, 1.1], [0.62, 1.65]]], [2.4, [[0.55, 1.05], [0.4, 1.4]]]], { mirror: true });
  for (const s of [-1, 1]) {
    for (let i = 0; i < 5; i++) m.cyl('glass', 0.17, 0.17, 0.03, 12, V(s * 1.12, 0.45, -1.6 + i * 0.75), { rot: RZ(Math.PI / 2) });
    m.cyl('dark', 0.26, 0.28, 0.5, 10, V(s * 0.6, 1.32, -2.25), { rot: RX(Math.PI / 2) });
    m.bevel('dark', 0.3, 0.26, 0.6, V(s * 0.85, 1.3, 2.3), 0.05, { rot: RY(s * 0.45) });
    m.bevel('paint', 0.55, 0.55, 1.6, V(s * 1.35, -0.55, -0.2), 0.08);       // yakıt tankları
    m.box('mark', 0.02, 0.25, 0.65, V(s * 1.12, -0.1, 2.9));
    m.box('trim', 0.1, 0.6, 0.12, V(s * 1.2, -1.2, 0.8), { rot: RZ(s * 0.3) });
    skidWheel(m, s * 1.35, -1.5, 0.8, 0.28);
  }
  m.box('trim', 0.03, 1.1, 1.2, V(-1.1, -0.2, -1.9));
  m.box('metal', 0.08, 0.1, 0.9, V(1.12, 0.3, -1.6));
  skidWheel(m, 0, -1.4, -2.8, 0.22);
  m.loft('paint', [[3.4, [[0.5, -0.1], [0.48, 0.95]]], [8.8, [[0.14, 0.5], [0.14, 0.85]]]], { mirror: true });
  m.hull('paint', [[0, 0.6, 8.6], [0, 0.85, 8.4], [0, 2.2, 9.2], [0, 2.2, 9.7], [0, 0.6, 9.6], [0.1, 0.8, 9.1], [-0.1, 0.8, 9.1]]);
  m.bevel('paint', 2.0, 0.07, 0.6, V(0, 0.75, 8.2), 0.02);
  antenna(m, 0, 1.15, 2.2, 0.5);
  m.group('rotor', V(0, 2.0, -0.4));
  blades(m, 2.0, -0.4, 5, 5.2, 0.52);
  m.group('trotor', V(0.18, 1.5, 9.4));
  tailRotor(m, 0.24, 1.7, 9.5, 3, 1.4);
  m.meta = { muzzle: V(1.15, 0.3, -2.05), radius: 4.2 };
  return m;
}

// ======================================================== FPV drone
function fpv(name) {
  const m = new Model(name);
  m.bevel('dark', 0.12, 0.05, 0.2, V(0, 0, 0), 0.015);
  m.bevel('pack', 0.08, 0.07, 0.16, V(0, -0.06, 0.01), 0.015, { tint: [0.45, 0.47, 0.32] });   // patlayıcı
  m.cyl('trim', 0.02, 0.02, 0.08, 6, V(0, -0.06, -0.12), { rot: RX(Math.PI / 2) });
  for (const [x, z] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
    m.box('dark', 0.025, 0.015, 0.2, V(x * 0.075, 0, z * 0.075), { rot: RY(Math.atan2(x, z)) });
    m.cyl('trim', 0.022, 0.022, 0.035, 8, V(x * 0.15, 0.012, z * 0.15));
    m.cyl('glass', 0.075, 0.075, 0.004, 12, V(x * 0.15, 0.034, z * 0.15));
  }
  m.box('light', 0.025, 0.015, 0.015, V(0, 0.025, -0.1));
  m.cyl('dark', 0.004, 0.004, 0.15, 3, V(0, 0.07, 0.08), { rot: RX(-0.6) });
  m.meta = { radius: 0.4 };
  return m;
}
export const fpv_blue = () => fpv('fpv_blue');
export const fpv_red = () => fpv('fpv_red');

export const AIR = { heli_blue, heli_red, transport_blue, transport_red, fpv_blue, fpv_red };
