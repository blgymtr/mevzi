// Ek araçlar: PSA, uçaksavar, obüs, nakliye helikopteri, FPV drone.
import { Model, THREE } from './lib.js';
import { tracks } from './vehicles.js';

const V = (x, y, z) => [x, y, z];
const RX = (a) => [a, 0, 0];

export function ifv_blue() {
  const m = new Model('ifv_blue');
  tracks(m, 6.6, 1.45, 0.45, 6, 0.34, { skirt: 0.6 });
  m.box('paint', 2.5, 1.3, 6.4, V(0, 1.25, 0.1));
  m.add('paint', new THREE.BoxGeometry(3.2, 0.12, 1.4), { pos: V(0, 1.6, -3.1), rot: RX(-0.45) });
  m.box('paint', 3.3, 0.1, 5.2, V(0, 1.92, 0.5));
  for (const s of [-1, 1]) {
    for (let i = 0; i < 3; i++) m.box('trim', 0.08, 0.55, 1.2, V(s * 1.65, 1.5, -1.4 + i * 1.4));
    m.box('mark', 0.04, 0.3, 0.7, V(s * 1.7, 1.55, 2.4));
    m.box('light', 0.16, 0.1, 0.06, V(s * 1.0, 1.55, -3.6));
  }
  m.box('trim', 2.2, 1.0, 0.1, V(0, 1.3, 3.35));
  m.box('canvas', 2.0, 0.3, 0.9, V(0, 2.1, 2.4), { tint: [0.55, 0.57, 0.42] });
  m.group('turret', V(0.3, 1.97, -0.2));
  m.box('paint', 1.7, 0.6, 1.9, V(0.3, 2.27, -0.2));
  m.add('paint', new THREE.BoxGeometry(1.7, 0.12, 0.8), { pos: V(0.3, 2.45, -1.25), rot: RX(-0.5) });
  m.box('trim', 0.4, 0.35, 0.8, V(1.25, 2.35, 0.1));
  m.box('glass', 0.3, 0.2, 0.25, V(-0.3, 2.65, -0.5));
  m.group('barrel', V(0.1, 2.3, -1.15));
  m.cyl('metal', 0.07, 0.06, 2.2, 8, V(0.1, 2.3, -2.25), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0.1, 2.3, -3.35), radius: 2.6 };
  return m;
}

export function ifv_red() {
  const m = new Model('ifv_red');
  tracks(m, 6.4, 1.3, 0.42, 6, 0.36);
  m.box('paint', 2.4, 0.9, 6.2, V(0, 1.0, 0.1));
  m.add('paint', new THREE.BoxGeometry(2.9, 0.1, 2.6), { pos: V(0, 1.3, -2.6), rot: RX(-0.25) });
  m.add('paint', new THREE.BoxGeometry(2.9, 0.1, 1.0), { pos: V(0, 0.95, -3.4), rot: RX(0.8) });
  m.box('paint', 3.0, 0.08, 4.0, V(0, 1.5, 1.1));
  for (const s of [-1, 1]) {
    for (let i = 0; i < 4; i++) m.cyl('dark', 0.08, 0.08, 0.08, 8, V(s * 1.0, 1.56, 0.3 + i * 0.75));
    m.box('mark', 0.04, 0.2, 0.6, V(s * 1.22, 1.15, 1.6));
    m.box('light', 0.14, 0.14, 0.06, V(s * 0.9, 1.35, -3.4));
  }
  m.group('turret', V(0, 1.5, -0.6));
  m.cyl('paint', 0.85, 0.95, 0.5, 12, V(0, 1.75, -0.6));
  m.add('paint', new THREE.ConeGeometry(0.85, 0.25, 12), { pos: V(0, 2.12, -0.6) });
  m.cyl('trim', 0.12, 0.12, 0.9, 6, V(0, 2.3, -0.4), { rot: RX(Math.PI / 2) });
  m.group('barrel', V(0, 1.85, -1.4));
  m.cyl('metal', 0.07, 0.06, 2.4, 8, V(0, 1.85, -2.6), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0, 1.85, -3.8), radius: 2.5 };
  return m;
}

function aa(name, blue) {
  const m = new Model(name);
  tracks(m, 6.4, 1.4, 0.45, 6, 0.36, blue ? { skirt: 0.55 } : {});
  m.box('paint', 2.4, 0.9, 6.2, V(0, 1.0, 0.1));
  m.add('paint', new THREE.BoxGeometry(3.0, 0.1, 1.2), { pos: V(0, 1.3, -3.1), rot: RX(-0.4) });
  m.box('paint', 3.1, 0.1, 5.4, V(0, 1.5, 0.4));
  for (const s of [-1, 1]) { m.box('mark', 0.04, 0.25, 0.6, V(s * 1.22, 1.15, 1.8)); m.box('light', 0.14, 0.12, 0.06, V(s * 0.9, 1.35, -3.5)); }
  m.group('turret', V(0, 1.55, 0.2));
  m.box('paint', 2.0, 0.9, 2.2, V(0, 2.0, 0.2));
  m.add('paint', new THREE.BoxGeometry(2.0, 0.12, 0.8), { pos: V(0, 2.3, -1.0), rot: RX(-0.6) });
  if (blue) {
    m.cyl('trim', 0.06, 0.06, 0.6, 6, V(0, 2.75, 0.8));
    m.box('dark', 1.3, 0.5, 0.08, V(0, 3.1, 0.8));
  } else {
    m.box('dark', 1.1, 0.06, 0.6, V(0, 2.75, 1.0));
    m.cyl('dark', 0.05, 0.05, 0.3, 6, V(0, 2.55, 1.0));
  }
  m.group('barrel', V(0, 2.2, -0.6));
  for (const s of (blue ? [-1.15, 1.15] : [-0.25, -0.08, 0.08, 0.25])) {
    m.cyl('metal', 0.045, 0.04, blue ? 2.6 : 1.9, 6, V(s, 2.2, blue ? -1.9 : -1.55), { rot: RX(Math.PI / 2) });
    if (blue) m.box('paint', 0.35, 0.4, 0.9, V(s, 2.2, -0.3));
  }
  m.meta = { muzzle: V(0, 2.2, blue ? -3.2 : -2.5), radius: 2.5 };
  return m;
}
export const aa_blue = () => aa('aa_blue', true);
export const aa_red = () => aa('aa_red', false);

function arty(name, blue) {
  const m = new Model(name);
  tracks(m, 6.8, 1.45, 0.45, 7, 0.34, blue ? { skirt: 0.5 } : {});
  m.box('paint', 2.6, 0.8, 6.6, V(0, 0.95, 0.0));
  m.add('paint', new THREE.BoxGeometry(3.1, 0.1, 1.2), { pos: V(0, 1.2, -3.3), rot: RX(-0.35) });
  m.box('paint', 3.2, 0.1, 6.0, V(0, 1.38, 0.0));
  for (const s of [-1, 1]) { m.box('mark', 0.04, 0.3, 0.7, V(s * 1.62, 1.6, 0.5)); m.box('light', 0.14, 0.12, 0.06, V(s * 1.0, 1.25, -3.65)); }
  m.box('trim', 2.8, 0.15, 0.6, V(0, 1.0, 3.5));
  m.group('turret', V(0, 1.43, 0.9));
  m.box('paint', 2.9, 1.3, 3.4, V(0, 2.1, 0.9));
  m.add('paint', new THREE.BoxGeometry(2.9, 0.12, 1.0), { pos: V(0, 2.6, -0.95), rot: RX(-0.7) });
  m.cyl('trim', 0.3, 0.3, 0.15, 10, V(0.8, 2.82, 1.4));
  m.box('metal', 0.08, 0.12, 0.9, V(0.8, 3.0, 1.0));
  m.group('barrel', V(0, 2.1, -0.75));
  m.cyl('paint', 0.12, 0.1, blue ? 6.2 : 5.0, 10, V(0, 2.1, blue ? -3.85 : -3.25), { rot: RX(Math.PI / 2) });
  m.cyl('trim', 0.2, 0.2, 0.6, 10, V(0, 2.1, -1.2), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.16, 0.16, 0.35, 10, V(0, 2.1, blue ? -6.9 : -5.7), { rot: RX(Math.PI / 2) });
  m.meta = { muzzle: V(0, 2.1, blue ? -7.1 : -5.9), radius: 2.8 };
  return m;
}
export const arty_blue = () => arty('arty_blue', true);
export const arty_red = () => arty('arty_red', false);

export function transport_blue() {
  const m = new Model('transport_blue');
  m.box('paint', 1.9, 1.7, 6.0, V(0, 0.1, 0.0));
  m.add('paint', new THREE.SphereGeometry(1.0, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), { pos: V(0, 0.1, -3.0), rot: RX(-Math.PI / 2), scale: [0.95, 1.3, 0.85] });
  m.add('glass', new THREE.BoxGeometry(1.7, 0.7, 0.9), { pos: V(0, 0.55, -3.35), rot: RX(0.5) });
  m.box('trim', 1.5, 0.6, 3.0, V(0, 1.15, -0.2));
  for (const s of [-1, 1]) {
    m.box('dark', 0.04, 0.9, 1.4, V(s * 0.96, 0.15, -0.8));
    m.box('glass', 0.04, 0.3, 0.4, V(s * 0.96, 0.5, 0.9));
    m.box('mark', 0.03, 0.35, 0.8, V(s * 0.97, 0.0, 1.8));
    m.cyl('dark', 0.25, 0.25, 0.18, 8, V(s * 0.9, -0.95, -1.8), { rot: [0, 0, Math.PI / 2] });
    m.box('trim', 0.12, 0.4, 0.12, V(s * 0.9, -0.65, -1.8));
  }
  m.cyl('paint', 0.45, 0.2, 6.0, 8, V(0, 0.4, 5.6), { rot: RX(Math.PI / 2) });
  m.box('paint', 0.15, 1.7, 1.2, V(0, 1.2, 8.4));
  m.box('paint', 2.4, 0.08, 0.7, V(0, 0.4, 8.0));
  m.group('rotor', V(0, 1.6, -0.2));
  m.cyl('dark', 0.24, 0.2, 0.4, 8, V(0, 1.6, -0.2));
  for (let i = 0; i < 4; i++) { const a = (i / 4) * Math.PI * 2; m.box('dark', 8.6, 0.04, 0.45, V(Math.cos(a) * 4.4, 1.85, -0.2 + Math.sin(a) * 4.4), { rot: [0, -a, 0] }); }
  m.group('trotor', V(0.15, 1.4, 8.4));
  for (let i = 0; i < 4; i++) { const a = (i / 4) * Math.PI * 2; m.box('dark', 0.04, 1.4, 0.18, V(0.15, 1.4 + Math.cos(a) * 0.7, 8.4 + Math.sin(a) * 0.7), { rot: [a, 0, 0] }); }
  m.meta = { muzzle: V(0.95, 0.2, -0.8), radius: 3.8 };
  return m;
}

export function transport_red() {
  const m = new Model('transport_red');
  m.box('paint', 2.2, 2.0, 6.4, V(0, 0.2, 0.3));
  m.add('paint', new THREE.SphereGeometry(1.1, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), { pos: V(0, 0.2, -2.9), rot: RX(-Math.PI / 2), scale: [1.0, 1.1, 0.95] });
  m.add('glass', new THREE.SphereGeometry(0.95, 10, 6, 0, Math.PI * 2, 0, Math.PI / 2), { pos: V(0, 0.45, -3.2), rot: RX(-Math.PI / 2 + 0.3), scale: [0.95, 0.8, 0.7] });
  m.box('trim', 1.8, 0.7, 3.4, V(0, 1.55, -0.4));
  for (const s of [-1, 1]) {
    for (let i = 0; i < 4; i++) m.cyl('glass', 0.18, 0.18, 0.04, 10, V(s * 1.11, 0.5, -0.6 + i * 0.9), { rot: [0, 0, Math.PI / 2] });
    m.box('mark', 0.03, 0.4, 0.8, V(s * 1.12, 0.0, 2.6));
    m.box('trim', 0.6, 0.5, 1.6, V(s * 1.35, -0.5, 0.0));
    m.cyl('dark', 0.28, 0.28, 0.2, 8, V(s * 1.2, -1.05, 0.6), { rot: [0, 0, Math.PI / 2] });
  }
  m.cyl('paint', 0.5, 0.22, 6.4, 8, V(0, 0.6, 6.4), { rot: RX(Math.PI / 2) });
  m.box('paint', 0.18, 1.6, 1.2, V(0, 1.4, 9.4));
  m.group('rotor', V(0, 2.0, -0.4));
  m.cyl('dark', 0.26, 0.2, 0.4, 8, V(0, 2.0, -0.4));
  for (let i = 0; i < 5; i++) { const a = (i / 5) * Math.PI * 2; m.box('dark', 10.2, 0.04, 0.5, V(Math.cos(a) * 5.2, 2.25, -0.4 + Math.sin(a) * 5.2), { rot: [0, -a, 0] }); }
  m.group('trotor', V(0.18, 1.5, 9.4));
  for (let i = 0; i < 3; i++) { const a = (i / 3) * Math.PI * 2; m.box('dark', 0.04, 1.6, 0.2, V(0.18, 1.5 + Math.cos(a) * 0.8, 9.4 + Math.sin(a) * 0.8), { rot: [a, 0, 0] }); }
  m.meta = { muzzle: V(1.1, 0.3, -1.0), radius: 4.2 };
  return m;
}

function fpv(name) {
  const m = new Model(name);
  m.box('dark', 0.16, 0.06, 0.22, V(0, 0, 0));
  m.box('trim', 0.08, 0.06, 0.14, V(0, -0.06, 0.02));
  for (const [x, z] of [[-1, -1], [1, -1], [-1, 1], [1, 1]]) {
    m.box('dark', 0.03, 0.02, 0.22, V(x * 0.08, 0, z * 0.08), { rot: [0, Math.atan2(x, z), 0] });
    m.cyl('dark', 0.025, 0.025, 0.04, 6, V(x * 0.16, 0.01, z * 0.16));
    m.cyl('glass', 0.09, 0.09, 0.005, 10, V(x * 0.16, 0.035, z * 0.16));
  }
  m.box('light', 0.03, 0.02, 0.02, V(0, 0.02, -0.12));
  m.meta = { radius: 0.4 };
  return m;
}
export const fpv_blue = () => fpv('fpv_blue');
export const fpv_red = () => fpv('fpv_red');

export const VEHICLES2 = { ifv_blue, ifv_red, aa_blue, aa_red, arty_blue, arty_red, transport_blue, transport_red, fpv_blue, fpv_red };
