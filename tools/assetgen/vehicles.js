// Araç modelleri (ileri -Z, Y yukarı, metre). İki ordu: blue (modern Batı tipi), red (Doğu tipi).
// Düğümler: hull, turret (taret halkası pivotu), barrel (muylu pivotu), wheel_N (tekerlek merkezi), rotor, trotor.
// Malzemeler: paint (kamuflaj), trim (koyu boya), metal, track, rubber, glass, canvas, mark (takım işareti), light, dark
import { Model, THREE } from './lib.js';

const V = (x, y, z) => [x, y, z];
const RX = (a) => [a, 0, 0];
const RZ = (a) => [0, 0, a];

function wheelNode(m, i, x, y, z, r, w) {
  m.group('wheel_' + i, V(x, y, z));
  m.cyl('rubber', r, r, w, 14, V(x, y, z), { rot: RZ(Math.PI / 2), uvScale: 1.0 });
  m.cyl('metal', r * 0.58, r * 0.58, w * 1.04, 10, V(x, y, z), { rot: RZ(Math.PI / 2) });
  m.cyl('trim', r * 0.2, r * 0.2, w * 1.1, 6, V(x, y, z), { rot: RZ(Math.PI / 2) });
  for (let k = 0; k < 6; k++) {
    const a = (k / 6) * Math.PI * 2;
    m.box('metal', w * 1.06, r * 0.08, r * 0.08, V(x, y + Math.cos(a) * r * 0.4, z + Math.sin(a) * r * 0.4));
  }
  m.group('hull');
}

// paletli yürüyen aksam: palet, yol tekerleri, ön çark, gergi
function tracks(m, L, x, y0, wheels, r, opt = {}) {
  for (const s of [-1, 1]) {
    const X = s * x;
    m.box('track', 0.66, 0.1, L, V(X, y0 - r + 0.05, 0), { uvScale: 1.0 });
    m.box('track', 0.66, 0.1, L * 0.92, V(X, y0 + r + 0.05, 0), { uvScale: 1.0 });
    m.cyl('track', r + 0.05, r + 0.05, 0.66, 12, V(X, y0 + 0.05, -L / 2 + r * 0.6), { rot: RZ(Math.PI / 2) });
    m.cyl('track', r + 0.05, r + 0.05, 0.66, 12, V(X, y0 + 0.05, L / 2 - r * 0.6), { rot: RZ(Math.PI / 2) });
    for (let i = 0; i < wheels; i++) {
      const z = -L / 2 + r * 1.3 + (i * (L - r * 2.6)) / (wheels - 1);
      m.cyl('metal', r * 0.92, r * 0.92, 0.5, 14, V(X, y0, z), { rot: RZ(Math.PI / 2) });
      m.cyl('trim', r * 0.35, r * 0.35, 0.56, 8, V(X, y0, z), { rot: RZ(Math.PI / 2) });
    }
    if (opt.skirt) m.box('paint', 0.1, opt.skirt, L * 0.9, V(X + s * 0.36, y0 + r - opt.skirt / 2 + 0.25, -0.1));
  }
}

// ======================================================== tanklar
export function tank_blue() {
  const m = new Model('tank_blue');
  const L = 7.6;
  tracks(m, L, 1.5, 0.48, 7, 0.36, { skirt: 0.75 });
  m.box('paint', 2.4, 0.8, 7.2, V(0, 0.95, 0.1));
  // eğik ön zırh (glasis)
  m.add('paint', new THREE.BoxGeometry(3.6, 0.12, 1.6), { pos: V(0, 1.15, -3.45), rot: RX(-0.3) });
  m.box('paint', 3.7, 0.12, 6.0, V(0, 1.37, 0.4));                  // çamurluk/üst güverte
  m.box('trim', 2.6, 0.06, 2.6, V(0, 1.45, 2.4));                    // motor ızgarası
  for (let i = 0; i < 6; i++) m.box('dark', 2.3, 0.02, 0.1, V(0, 1.49, 1.4 + i * 0.4));
  for (const s of [-1, 1]) {
    m.box('paint', 0.5, 0.3, 1.4, V(s * 1.55, 1.58, 1.8));           // yan kutular
    m.box('light', 0.18, 0.12, 0.08, V(s * 1.45, 1.25, -4.05));      // farlar
  }
  m.box('trim', 3.0, 0.4, 0.3, V(0, 1.2, 3.85));                      // arka
  m.box('dark', 0.5, 0.25, 0.1, V(-0.9, 1.2, 4.0));
  m.box('dark', 0.5, 0.25, 0.1, V(0.9, 1.2, 4.0));
  // ---- taret (köşeli, kama ön) ----
  m.group('turret', V(0, 1.45, -0.2));
  m.box('paint', 2.9, 0.85, 3.4, V(0, 1.9, 0.0));
  m.add('paint', new THREE.CylinderGeometry(0.01, 1.5, 1.4, 4, 1), { pos: V(0, 1.9, -2.0), rot: [Math.PI / 2, Math.PI / 4, 0], scale: [1.4, 1.0, 0.42] });
  m.box('paint', 2.6, 0.7, 1.2, V(0, 1.86, 2.15));                    // bagaj sepeti tabanı
  for (let i = 0; i < 4; i++) m.box('dark', 2.7, 0.05, 0.05, V(0, 2.25, 1.7 + i * 0.3));
  m.box('canvas', 2.2, 0.35, 0.9, V(0, 2.4, 2.2), { tint: [0.6, 0.62, 0.45] });  // çantalar
  for (const s of [-1, 1]) {
    m.cyl('trim', 0.33, 0.33, 0.14, 10, V(s * 0.65, 2.38, 0.3));     // kapaklar
    for (let k = 0; k < 4; k++) m.cyl('dark', 0.06, 0.06, 0.3, 6, V(s * 1.5, 2.1 + k * 0.08, -0.9 + k * 0.12), { rot: [0, 0, s * 0.6] });  // sis atarlar
    m.box('mark', 0.04, 0.3, 0.7, V(s * 1.46, 1.95, 0.6));          // takım işareti
  }
  m.box('glass', 0.5, 0.35, 0.4, V(-0.9, 2.5, -0.6));                 // komutan görüş
  m.box('metal', 0.08, 0.12, 0.9, V(0.7, 2.6, 0.1));                  // MG
  m.cyl('metal', 0.05, 0.05, 2.2, 5, V(0.3, 2.3, 2.6));               // anten
  m.box('trim', 0.7, 0.6, 0.5, V(0, 1.9, -1.75));                     // kalkan
  // ---- namlu ----
  m.group('barrel', V(0, 1.95, -1.9));
  m.cyl('paint', 0.12, 0.1, 5.2, 10, V(0, 1.95, -4.5), { rot: RX(Math.PI / 2) });
  m.cyl('trim', 0.15, 0.15, 0.7, 10, V(0, 1.95, -3.2), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.11, 0.11, 0.18, 10, V(0, 1.95, -7.05), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0, 1.95, -7.15), radius: 2.9 };
  return m;
}

export function tank_red() {
  const m = new Model('tank_red');
  const L = 6.4;
  tracks(m, L, 1.32, 0.45, 5, 0.42);
  m.box('paint', 2.0, 0.7, 6.0, V(0, 0.75, 0.15));
  m.add('paint', new THREE.BoxGeometry(3.0, 0.1, 1.2), { pos: V(0, 0.92, -3.0), rot: RX(-0.5) });
  m.box('paint', 3.3, 0.1, 5.5, V(0, 1.02, 0.25));                    // çamurluklar
  for (const s of [-1, 1]) {
    for (let i = 0; i < 3; i++) m.box('trim', 0.4, 0.28, 0.9, V(s * 1.42, 1.2, -1.9 + i * 1.05));  // çamurluk kutuları
    m.box('light', 0.16, 0.16, 0.1, V(s * 0.9, 1.25, -3.05));
  }
  m.box('trim', 2.4, 0.16, 2.3, V(0, 1.12, 1.7));
  for (let i = 0; i < 5; i++) m.box('dark', 1.9, 0.03, 0.12, V(0, 1.21, 0.9 + i * 0.38));
  for (const s of [-0.5, 0.5]) m.cyl('paint', 0.3, 0.3, 0.9, 10, V(s - 0.45 + 0.45, 1.28, 3.05), { rot: RZ(Math.PI / 2) });   // varil
  m.cyl('dark', 0.1, 0.1, 0.4, 6, V(1.0, 1.0, 3.1), { rot: RX(Math.PI / 2) });     // egzoz
  // ---- taret (yuvarlak kubbe) ----
  m.group('turret', V(0, 1.1, -0.35));
  m.add('paint', new THREE.SphereGeometry(1.2, 18, 9, 0, Math.PI * 2, 0, Math.PI * 0.5), { pos: V(0, 1.1, 0), scale: [1.0, 0.55, 1.12] });
  m.cyl('paint', 1.2, 1.25, 0.12, 18, V(0, 1.1, 0), { scale: [1, 1, 1.12] });
  m.cyl('trim', 0.32, 0.3, 0.25, 10, V(0.45, 1.75, 0.25));
  m.add('trim', new THREE.SphereGeometry(0.3, 10, 5, 0, Math.PI * 2, 0, Math.PI * 0.5), { pos: V(0.45, 1.87, 0.25), scale: [1, 0.35, 1] });
  m.cyl('trim', 0.26, 0.26, 0.14, 10, V(-0.45, 1.72, 0.35));
  m.box('metal', 0.08, 0.1, 1.1, V(-0.45, 1.98, 0.15));               // DShK
  m.box('glass', 0.32, 0.22, 0.28, V(-0.9, 1.45, -0.55));            // projektör
  m.box('trim', 1.0, 0.25, 0.35, V(0, 1.38, 1.35));                   // arka kutu
  for (const s of [-1, 1]) m.box('mark', 0.04, 0.22, 0.6, V(s * 1.17, 1.32, 0.1));
  m.cyl('dark', 0.025, 0.02, 1.6, 4, V(0.2, 1.8, 0.9));                // anten
  m.box('trim', 0.55, 0.45, 0.45, V(0, 1.3, -1.2));                    // namlu kalkanı
  m.group('barrel', V(0, 1.35, -1.3));
  m.cyl('paint', 0.09, 0.075, 3.6, 10, V(0, 1.35, -3.1), { rot: RX(Math.PI / 2) });
  m.cyl('paint', 0.13, 0.13, 0.5, 10, V(0, 1.35, -3.6), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.085, 0.085, 0.14, 10, V(0, 1.35, -4.9), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0, 1.35, -4.98), radius: 2.7 };
  return m;
}

// ======================================================== ZPT (8x8)
export function apc_blue() {
  const m = new Model('apc_blue');
  m.box('paint', 2.7, 1.3, 7.0, V(0, 1.45, 0.1));
  m.add('paint', new THREE.BoxGeometry(2.7, 0.12, 1.5), { pos: V(0, 1.9, -3.7), rot: RX(-0.55) });
  m.add('paint', new THREE.BoxGeometry(2.7, 0.12, 1.2), { pos: V(0, 1.0, -3.65), rot: RX(0.7) });
  for (const s of [-1, 1]) {
    m.add('paint', new THREE.BoxGeometry(0.12, 0.6, 7.0), { pos: V(s * 1.42, 1.85, 0.1), rot: RZ(s * 0.35) });
    for (let i = 0; i < 4; i++) m.box('trim', 0.06, 0.3, 0.5, V(s * 1.38, 1.3, -2.2 + i * 1.5));
    m.box('mark', 0.04, 0.35, 0.8, V(s * 1.53, 1.75, 2.3));
    m.box('light', 0.16, 0.1, 0.08, V(s * 1.1, 1.5, -4.1));
  }
  m.box('trim', 2.2, 0.1, 5.5, V(0, 2.14, 0.4));
  m.box('trim', 1.6, 0.9, 0.1, V(0, 1.4, 3.65));                       // rampa
  m.box('canvas', 1.8, 0.35, 1.2, V(0, 2.35, 2.5), { tint: [0.55, 0.57, 0.42] });
  for (const [i, z] of [-2.4, -1.0, 1.0, 2.4].entries()) {
    wheelNode(m, i * 2, -1.25, 0.55, z, 0.55, 0.42);
    wheelNode(m, i * 2 + 1, 1.25, 0.55, z, 0.55, 0.42);
  }
  m.group('turret', V(0.3, 2.15, -0.8));
  m.box('paint', 0.9, 0.5, 1.0, V(0.3, 2.45, -0.8));
  m.box('glass', 0.5, 0.25, 0.2, V(0.3, 2.5, -1.35));
  m.group('barrel', V(0.3, 2.5, -1.3));
  m.cyl('metal', 0.05, 0.045, 1.6, 6, V(0.3, 2.5, -2.1), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0.3, 2.5, -2.9), radius: 2.5 };
  return m;
}

export function apc_red() {
  const m = new Model('apc_red');
  const prof = new THREE.Shape();
  [[-3.7, 1.15], [-3.3, 0.55], [3.4, 0.55], [3.6, 1.0], [3.4, 1.85], [-2.6, 2.0], [-3.5, 1.6]].forEach(([x, y], i) => i ? prof.lineTo(x, y) : prof.moveTo(x, y));
  const g = new THREE.ExtrudeGeometry(prof, { depth: 2.5, bevelEnabled: false });
  g.translate(0, 0, -1.25);
  m.add('paint', g, { rot: [0, -Math.PI / 2, 0] });
  for (const s of [-1, 1]) {
    for (let i = 0; i < 3; i++) m.box('trim', 0.05, 0.25, 0.4, V(s * 1.28, 1.5, -1.0 + i * 1.2));
    m.box('mark', 0.04, 0.2, 0.6, V(s * 1.28, 1.8, 2.0));
    m.box('light', 0.14, 0.14, 0.08, V(s * 0.8, 1.3, 3.55 * -1));
  }
  m.box('trim', 0.7, 0.1, 0.8, V(0.5, 2.06, 1.8));
  m.box('trim', 0.6, 0.1, 0.6, V(-0.6, 2.06, 1.6));
  for (const [i, z] of [-2.4, -1.1, 1.0, 2.3].entries()) {
    wheelNode(m, i * 2, -1.22, 0.58, z, 0.58, 0.42);
    wheelNode(m, i * 2 + 1, 1.22, 0.58, z, 0.58, 0.42);
  }
  m.group('turret', V(0, 2.0, -0.7));
  m.cyl('paint', 0.62, 0.52, 0.48, 12, V(0, 2.24, -0.7));
  m.box('glass', 0.2, 0.15, 0.3, V(0.4, 2.4, -1.05));
  m.group('barrel', V(0, 2.3, -1.2));
  m.cyl('metal', 0.055, 0.045, 2.0, 6, V(0, 2.3, -2.2), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0, 2.3, -3.2), radius: 2.5 };
  return m;
}

// ======================================================== hafif araç
export function technical_blue() {
  // Hafif zırhlı keşif aracı (geniş, alçak) + taret halkası makineli
  const m = new Model('technical_blue');
  m.box('paint', 2.2, 0.6, 4.8, V(0, 0.95, 0));
  m.box('paint', 2.1, 0.5, 1.5, V(0, 1.4, -1.6));                      // motor kaputu
  m.box('paint', 2.15, 0.85, 2.4, V(0, 1.65, 0.6));                    // kabin
  for (const s of [-1, 1]) {
    m.box('glass', 0.04, 0.4, 0.6, V(s * 1.08, 1.8, 0.0));
    m.box('glass', 0.04, 0.4, 0.6, V(s * 1.08, 1.8, 1.0));
    m.box('light', 0.2, 0.12, 0.06, V(s * 0.8, 1.25, -2.42));
    m.box('mark', 0.03, 0.25, 0.5, V(s * 1.1, 1.3, 1.6));
  }
  m.box('glass', 1.9, 0.45, 0.06, V(0, 1.85, -0.62), { rot: RX(-0.25) });
  m.box('trim', 2.0, 0.25, 0.1, V(0, 0.9, -2.42));                      // tampon
  m.box('canvas', 1.8, 0.3, 0.9, V(0, 2.2, 1.5), { tint: [0.55, 0.57, 0.45] });
  for (const [i, z] of [-1.6, 1.6].entries()) {
    wheelNode(m, i * 2, -1.0, 0.48, z, 0.48, 0.38);
    wheelNode(m, i * 2 + 1, 1.0, 0.48, z, 0.48, 0.38);
  }
  m.group('turret', V(0, 2.1, 0.5));
  m.cyl('trim', 0.5, 0.5, 0.12, 12, V(0, 2.14, 0.5));
  m.box('paint', 0.9, 0.5, 0.06, V(0, 2.45, 0.05));                    // nişancı kalkanı
  m.group('barrel', V(0, 2.45, 0.2));
  m.box('metal', 0.1, 0.14, 1.3, V(0, 2.45, -0.3));
  m.meta = { muzzle: V(0, 2.45, -0.95), gunner: V(0, 1.55, 0.75), radius: 1.9 };
  return m;
}

export function technical_red() {
  const m = new Model('technical_red');
  m.box('paint', 1.9, 0.45, 5.0, V(0, 0.75, 0));
  m.box('paint', 1.86, 0.08, 1.2, V(0, 1.0, -1.9));
  m.add('glass', new THREE.CylinderGeometry(0.8, 1.0, 0.68, 4, 1), { pos: V(0, 1.32, -0.65), rot: [0, Math.PI / 4, 0], scale: [1.2, 1, 0.78] });
  m.box('paint', 1.72, 0.06, 1.1, V(0, 1.67, -0.55));
  for (const s of [-1, 1]) {
    m.box('paint', 0.08, 0.5, 2.3, V(s * 0.92, 1.25, 1.35));
    m.box('light', 0.2, 0.12, 0.06, V(s * 0.65, 0.85, -2.52));
    m.box('mark', 0.03, 0.15, 0.4, V(s * 0.96, 1.15, -1.4));
  }
  m.box('paint', 1.9, 0.5, 0.08, V(0, 1.25, 2.47));
  m.box('dark', 1.76, 0.06, 2.3, V(0, 1.0, 1.35));
  m.box('trim', 1.7, 0.3, 0.06, V(0, 0.7, -2.52));
  for (const [i, z] of [-1.65, 1.55].entries()) {
    wheelNode(m, i * 2, -0.86, 0.42, z, 0.42, 0.3);
    wheelNode(m, i * 2 + 1, 0.86, 0.42, z, 0.42, 0.3);
  }
  m.group('turret', V(0, 1.05, 1.2));
  m.cyl('metal', 0.08, 0.06, 1.0, 6, V(0, 1.55, 1.2));
  m.group('barrel', V(0, 2.05, 1.05));
  m.box('metal', 0.18, 0.2, 0.5, V(0, 2.05, 1.2));
  m.cyl('metal', 0.04, 0.035, 1.4, 6, V(0, 2.05, 0.3), { rot: RX(Math.PI / 2) });
  m.box('trim', 0.6, 0.35, 0.04, V(0, 2.15, 0.8));
  m.meta = { muzzle: V(0, 2.05, -0.4), gunner: V(0, 1.03, 1.85), radius: 1.9 };
  return m;
}

// ======================================================== kamyon
function truck(name, cabTint) {
  const m = new Model(name);
  m.box('trim', 1.3, 0.3, 6.6, V(0, 0.95, 0.2));
  m.box('paint', 2.3, 0.9, 1.3, V(0, 1.45, -2.75));
  m.box('paint', 1.6, 0.75, 0.7, V(0, 1.38, -3.55));
  m.box('dark', 1.2, 0.4, 0.05, V(0, 1.4, -3.92));
  m.box('glass', 2.2, 0.55, 0.9, V(0, 2.2, -2.6));
  m.box('paint', 2.24, 0.06, 0.95, V(0, 2.52, -2.55));
  m.box('paint', 2.5, 0.12, 4.4, V(0, 1.3, 1.05));
  for (const s of [-1, 1]) {
    m.box('paint', 0.06, 0.5, 4.4, V(s * 1.22, 1.6, 1.05));
    m.box('light', 0.18, 0.18, 0.06, V(s * 0.9, 1.5, -3.94));
    m.box('mark', 0.04, 0.35, 0.6, V(s * 1.27, 2.05, 0.6));
  }
  // branda
  const prof = new THREE.Shape();
  prof.moveTo(-1.25, 0);
  for (let i = 0; i <= 8; i++) { const a = Math.PI - (i / 8) * Math.PI; prof.lineTo(Math.cos(a) * 1.25, 0.5 + Math.sin(a) * 0.75); }
  prof.lineTo(1.25, 0);
  const g = new THREE.ExtrudeGeometry(prof, { depth: 4.35, bevelEnabled: false });
  g.translate(0, 1.35, -1.12);
  m.add('canvas', g, { tint: cabTint, uv: 'box', uvScale: 0.35 });
  for (const [i, z] of [-2.7, 0.9, 2.3].entries()) {
    wheelNode(m, i * 2, -1.05, 0.55, z, 0.55, 0.4);
    wheelNode(m, i * 2 + 1, 1.05, 0.55, z, 0.55, 0.4);
  }
  m.meta = { radius: 2.3 };
  return m;
}
export const truck_blue = () => truck('truck_blue', [0.55, 0.57, 0.42]);
export const truck_red = () => truck('truck_red', [0.78, 0.72, 0.55]);

// ======================================================== helikopterler
export function heli_red() {
  const m = new Model('heli_red');
  const prof = new THREE.Shape();
  [[5.2, -0.7], [4.2, -1.3], [-1.8, -1.3], [-2.6, -0.6], [-2.4, 0.5], [1.5, 0.8], [3.4, 0.3], [5.0, -0.2]].forEach(([x, y], i) => i ? prof.lineTo(x, y) : prof.moveTo(x, y));
  const g = new THREE.ExtrudeGeometry(prof, { depth: 1.9, bevelEnabled: true, bevelSize: 0.15, bevelThickness: 0.15, bevelSegments: 2 });
  g.translate(0, 0, -0.95);
  m.add('paint', g, { rot: [0, Math.PI / 2, 0] });
  m.add('glass', new THREE.SphereGeometry(0.75, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), { pos: V(0, -0.2, -3.6), scale: [0.9, 0.9, 1.3] });
  m.add('glass', new THREE.SphereGeometry(0.8, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), { pos: V(0, 0.3, -2.2), scale: [0.95, 0.9, 1.25] });
  m.box('trim', 1.5, 0.55, 3.0, V(0, 1.0, 0.2));
  for (const s of [-0.45, 0.45]) m.cyl('dark', 0.22, 0.22, 0.4, 8, V(s, 1.0, -1.25), { rot: RX(Math.PI / 2) });
  m.box('paint', 0.9, 0.7, 1.6, V(0, -0.1, 2.6));
  m.cyl('paint', 0.35, 0.2, 5.6, 8, V(0, 0.2, 5.0), { rot: RX(Math.PI / 2) });
  m.box('paint', 0.15, 1.6, 1.0, V(0, 1.0, 7.6));
  m.box('paint', 2.0, 0.08, 0.6, V(0, 0.25, 7.0));
  for (const s of [-1, 1]) {
    m.box('trim', 1.6, 0.1, 0.9, V(s * 1.7, -0.3, -0.6), { rot: RZ(s * 0.15) });
    m.cyl('metal', 0.22, 0.22, 1.4, 8, V(s * 1.6, -0.55, -1.4), { rot: RX(Math.PI / 2) });
    m.cyl('metal', 0.2, 0.2, 1.2, 8, V(s * 2.3, -0.55, -1.3), { rot: RX(Math.PI / 2) });
    m.box('mark', 0.04, 0.3, 0.8, V(s * 1.05, -0.2, 1.2));
    m.cyl('dark', 0.2, 0.2, 0.15, 8, V(s * 0.9, -1.7, 0.3), { rot: RZ(Math.PI / 2) });
  }
  m.cyl('metal', 0.18, 0.18, 0.3, 8, V(0, -1.3, -4.6));
  m.box('dark', 0.06, 0.06, 0.8, V(0, -1.25, -5.0));
  m.group('rotor', V(0, 1.35, 0));
  m.cyl('dark', 0.18, 0.15, 0.35, 8, V(0, 1.35, 0));
  for (let i = 0; i < 5; i++) { const a = (i / 5) * Math.PI * 2; m.box('dark', 8.2, 0.04, 0.34, V(Math.cos(a) * 4.2, 1.6, Math.sin(a) * 4.2), { rot: [0, -a, 0] }); }
  m.group('trotor', V(0.12, 1.1, 7.6));
  for (let i = 0; i < 3; i++) { const a = (i / 3) * Math.PI * 2; m.box('dark', 0.04, 1.3, 0.18, V(0.12, 1.1 + Math.cos(a) * 0.65, 7.6 + Math.sin(a) * 0.65), { rot: [a, 0, 0] }); }
  m.meta = { muzzle: V(0, -1.3, -4.6), radius: 3.6 };
  return m;
}

export function heli_blue() {
  // ince gövdeli, basamaklı kokpit, dört pal
  const m = new Model('heli_blue');
  m.box('paint', 1.1, 1.3, 4.6, V(0, -0.2, 0.2));
  m.add('paint', new THREE.BoxGeometry(1.0, 1.0, 1.4), { pos: V(0, -0.45, -2.6), rot: RX(0.25) });
  m.add('glass', new THREE.BoxGeometry(0.9, 0.6, 1.3), { pos: V(0, 0.05, -2.6), rot: RX(0.35) });
  m.add('glass', new THREE.BoxGeometry(0.95, 0.65, 1.2), { pos: V(0, 0.5, -1.3), rot: RX(0.25) });
  for (const s of [-1, 1]) {
    m.box('trim', 0.55, 0.6, 2.0, V(s * 0.75, 0.55, 0.4));                 // motor nacelleri
    m.cyl('dark', 0.22, 0.22, 0.2, 8, V(s * 0.75, 0.55, 1.45), { rot: RX(Math.PI / 2) });
    m.box('trim', 1.8, 0.1, 0.8, V(s * 1.4, -0.1, -0.2));                   // kanatçık
    for (const k of [1.0, 1.9]) m.box('metal', 0.3, 0.3, 1.3, V(s * k, -0.35, -0.3));
    m.box('mark', 0.03, 0.3, 0.7, V(s * 0.56, -0.2, 1.4));
    m.box('dark', 0.1, 0.5, 0.1, V(s * 0.6, -1.05, -1.5));
    m.cyl('dark', 0.2, 0.2, 0.14, 8, V(s * 0.6, -1.3, -1.5), { rot: RZ(Math.PI / 2) });
  }
  m.cyl('paint', 0.35, 0.18, 6.0, 8, V(0, 0.1, 5.2), { rot: RX(Math.PI / 2) });
  m.box('paint', 0.14, 1.7, 1.1, V(0, 0.9, 8.0));
  m.box('paint', 2.2, 0.08, 0.7, V(0, 0.0, 7.6));
  m.cyl('metal', 0.14, 0.14, 0.4, 8, V(0, -1.05, -2.2));
  m.box('dark', 0.05, 0.05, 1.0, V(0, -1.05, -2.8));
  m.group('rotor', V(0, 1.15, 0.3));
  m.cyl('dark', 0.2, 0.16, 0.35, 8, V(0, 1.15, 0.3));
  for (let i = 0; i < 4; i++) { const a = (i / 4) * Math.PI * 2 + 0.3; m.box('dark', 7.4, 0.04, 0.38, V(Math.cos(a) * 3.8, 1.4, 0.3 + Math.sin(a) * 3.8), { rot: [0, -a, 0] }); }
  m.group('trotor', V(0.12, 1.0, 8.0));
  for (let i = 0; i < 4; i++) { const a = (i / 4) * Math.PI * 2; m.box('dark', 0.04, 1.2, 0.16, V(0.12, 1.0 + Math.cos(a) * 0.6, 8.0 + Math.sin(a) * 0.6), { rot: [a, 0, 0] }); }
  m.meta = { muzzle: V(0, -1.05, -3.3), radius: 3.4 };
  return m;
}

export const VEHICLES = { tank_blue, tank_red, apc_blue, apc_red, technical_blue, technical_red, truck_blue, truck_red, heli_blue, heli_red };
