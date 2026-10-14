// Topçu: sahra topu, çekili obüs, tanksavar topu, uçaksavar topu, ağır havan, dağ topu,
// roketatar (kamyon), sahil topçusu (sabit taret). İleri -Z.
// Namlu yükselişi modele işlenir (oyun yalnızca tareti döndürür).
import { Model, THREE } from './lib.js';
import { V, RX, RY, RZ, tyre, mg, grille, headlight, jerrycan, bag, antenna, smokeLaunchers } from './parts.js';

// yükseltilmiş boru: start noktasından e açısıyla -Z yönünde L boyunca
function tube(m, mat, r0, r1, L, start, e, seg = 12) {
  const d = [0, Math.sin(e), -Math.cos(e)];
  const c = [start[0] + d[0] * L / 2, start[1] + d[1] * L / 2, start[2] + d[2] * L / 2];
  m.cyl(mat, r1, r0, L, seg, c, { rot: RX(e - Math.PI / 2) });
}
const along = (start, e, L) => [start[0], start[1] + Math.sin(e) * L, start[2] - Math.cos(e) * L];

// çekili top lavetası: iki teker + aks + açılır kuyruklar + kazma
function carriage(m, o) {
  const { x, y, r, w, trail = 2.6, spread = 0.5 } = o;
  tyre(m, 0, -x, y, o.z ?? 0, r, w, -1, { bolts: 6 });
  tyre(m, 1, x, y, o.z ?? 0, r, w, 1, { bolts: 6 });
  m.cyl('trim', 0.07, 0.07, x * 2, 8, V(0, y, o.z ?? 0), { rot: RZ(Math.PI / 2) });
  m.bevel('paint', x * 1.3, 0.22, 0.6, V(0, y + 0.18, o.z ?? 0), 0.04);
  for (const s of [-1, 1]) {
    const a = s * spread;
    const L = trail;
    m.bevel('paint', 0.14, 0.16, L, V(s * 0.3 + Math.sin(a) * L / 2, y * 0.55, (o.z ?? 0) + Math.cos(a) * L / 2), 0.03, { rot: [0.08, a, 0] });
    m.bevel('trim', 0.34, 0.3, 0.06, V(s * 0.3 + Math.sin(a) * L, 0.12, (o.z ?? 0) + Math.cos(a) * L), 0.02, { rot: [0.5, a, 0] });   // kazma
  }
}

function crewSeat(m, x, y, z) {
  m.bevel('trim', 0.3, 0.05, 0.3, V(x, y, z), 0.02);
  m.box('trim', 0.04, y - 0.05, 0.04, V(x, (y - 0.05) / 2, z));
}

// ======================================================== sahra topu
function fieldgun(name, blue) {
  const m = new Model(name);
  carriage(m, { x: 0.9, y: 0.5, r: 0.5, w: 0.25, trail: 2.7, spread: 0.45 });
  m.group('turret', V(0, 0.8, 0.0));
  m.bevel('paint', 0.5, 0.35, 1.3, V(0, 0.95, 0.05), 0.04);
  // kalkan
  for (const s of [-1, 1]) m.bevel('paint', 0.85, blue ? 0.9 : 1.05, 0.05, V(s * 0.48, 1.2, -0.45), 0.02, { rot: [-0.12, s * 0.18, 0] });
  m.bevel('paint', 0.5, 0.35, 0.05, V(0, 0.82, -0.45), 0.02);
  m.box('dark', 0.16, 0.12, 0.03, V(-0.32, 1.3, -0.5));
  m.group('barrel', V(0, 1.05, -0.3));
  tube(m, 'trim', 0.17, 0.17, 0.9, V(0, 1.05, 0.3), 0);
  tube(m, 'paint', 0.085, 0.07, 3.2, V(0, 1.05, -0.3), 0.03);
  const mz = along(V(0, 1.05, -0.3), 0.03, 3.2);
  m.bevel('trim', 0.28, 0.18, 0.3, V(mz[0], mz[1], mz[2] + 0.12), 0.03);
  m.meta = { muzzle: along(V(0, 1.05, -0.3), 0.03, 3.3), radius: 1.6 };
  return m;
}

// ======================================================== çekili obüs
function howitzer(name, blue) {
  const m = new Model(name);
  carriage(m, { x: 1.05, y: 0.6, r: 0.6, w: 0.32, trail: 3.4, spread: 0.5 });
  if (!blue) for (const s of [-1, 1]) m.bevel('trim', 0.3, 0.06, 0.3, V(s * 1.0, 0.03, -0.9), 0.02);   // taban levhaları
  m.group('turret', V(0, 1.0, 0.2));
  m.bevel('paint', 0.7, 0.5, 1.8, V(0, 1.2, 0.25), 0.05);
  for (const s of [-1, 1]) {
    m.bevel('paint', 0.08, 0.9, 1.0, V(s * 0.42, 1.35, 0.1), 0.03);                 // yan levhalar
    m.cyl('trim', 0.12, 0.12, 0.6, 8, V(s * 0.45, 1.75, 0.6), { rot: RX(Math.PI / 2 - 0.35) });   // denge silindiri
  }
  if (blue) m.bevel('paint', 1.6, 0.8, 0.05, V(0, 1.45, -0.55), 0.02, { rot: RX(-0.15) });
  m.group('barrel', V(0, 1.45, -0.1));
  const e = 0.35;
  tube(m, 'trim', 0.2, 0.2, 1.4, V(0, 1.45, 0.7), e);
  tube(m, 'paint', 0.115, 0.1, 4.6, V(0, 1.45, -0.1), e, 14);
  const mz = along(V(0, 1.45, -0.1), e, 4.6);
  m.add('trim', new THREE.BoxGeometry(0.34, 0.22, 0.42), { pos: mz, rot: RX(e) });
  m.meta = { muzzle: along(V(0, 1.45, -0.1), e, 4.85), radius: 2.0 };
  return m;
}

// ======================================================== tanksavar topu (alçak siluet)
function atgun(name, blue) {
  const m = new Model(name);
  carriage(m, { x: 0.78, y: 0.42, r: 0.42, w: 0.22, trail: 2.5, spread: 0.42 });
  m.group('turret', V(0, 0.6, 0.0));
  m.bevel('paint', 0.42, 0.28, 1.1, V(0, 0.72, 0.0), 0.03);
  for (const s of [-1, 1]) m.bevel('paint', 0.7, 0.55, 0.04, V(s * 0.38, 0.92, -0.4), 0.015, { rot: [-0.3, s * 0.3, 0] });
  m.bevel('dark', 0.12, 0.1, 0.12, V(-0.25, 1.0, -0.2), 0.02);
  m.group('barrel', V(0, 0.85, -0.3));
  tube(m, 'trim', 0.13, 0.13, 0.8, V(0, 0.85, 0.35), 0);
  tube(m, 'paint', 0.06, 0.05, 3.6, V(0, 0.85, -0.3), 0, 10);
  const mz = along(V(0, 0.85, -0.3), 0, 3.6);
  m.cyl('trim', 0.1, 0.1, 0.3, 10, V(mz[0], mz[1], mz[2] + 0.1), { rot: RX(Math.PI / 2) });
  for (let i = 0; i < 3; i++) m.box('dark', 0.21, 0.02, 0.04, V(mz[0], mz[1], mz[2] + 0.02 + i * 0.08));
  m.meta = { muzzle: along(V(0, 0.85, -0.3), 0, 3.75), radius: 1.5 };
  return m;
}

// ======================================================== uçaksavar topu (ikiz namlu)
function aagun(name, blue) {
  const m = new Model(name);
  tyre(m, 0, -0.95, 0.45, 0.2, 0.42, 0.2, -1, { bolts: 5 });
  tyre(m, 1, 0.95, 0.45, 0.2, 0.42, 0.2, 1, { bolts: 5 });
  m.bevel('paint', 1.7, 0.18, 2.6, V(0, 0.55, 0.15), 0.04);
  for (const [x, z] of [[-1, -1.3], [1, -1.3], [-1, 1.5], [1, 1.5]]) {
    m.box('trim', 0.08, 0.5, 0.08, V(x * 0.95, 0.3, z), { rot: [0, 0, x * 0.3] });
    m.bevel('trim', 0.25, 0.05, 0.25, V(x * 1.05, 0.03, z), 0.02);
  }
  m.group('turret', V(0, 0.75, 0.2));
  m.cyl('trim', 0.55, 0.6, 0.12, 14, V(0, 0.7, 0.2));
  m.bevel('paint', 0.9, 0.5, 0.8, V(0, 1.0, 0.25), 0.05);
  crewSeat(m, -0.6, 1.0, 0.55);
  crewSeat(m, 0.6, 1.0, 0.55);
  m.bevel('dark', 0.15, 0.25, 0.15, V(-0.35, 1.45, 0.0), 0.02);
  m.group('barrel', V(0, 1.25, -0.2));
  const e = 0.3;
  for (const s of [-0.18, 0.18]) {
    m.bevel('paint', 0.18, 0.2, 0.9, V(s, 1.25, 0.15), 0.03);
    tube(m, 'metal', 0.035, 0.032, 2.2, V(s, 1.25, -0.2), e, 8);
    const mz = along(V(s, 1.25, -0.2), e, 2.2);
    m.cyl('dark', 0.055, 0.055, 0.18, 8, mz, { rot: RX(e - Math.PI / 2) });
  }
  m.bevel(blue ? 'pack' : 'paint', 0.16, 0.2, 0.3, V(0, 1.4, 0.3), 0.03, { tint: [0.6, 0.6, 0.5] });
  m.meta = { muzzle: along(V(0, 1.25, -0.2), e, 2.3), radius: 1.6 };
  return m;
}

// ======================================================== ağır havan (120 mm)
function hmortar(name, blue) {
  const m = new Model(name);
  m.cyl('trim', 0.42, 0.45, 0.08, 14, V(0, 0.04, 0.35));
  m.bevel('dark', 0.5, 0.04, 0.5, V(0, 0.09, 0.35), 0.02);
  // nakil tekerleri (yanda)
  tyre(m, 0, -0.7, 0.3, 0.6, 0.3, 0.16, -1, { bolts: 5 });
  tyre(m, 1, 0.7, 0.3, 0.6, 0.3, 0.16, 1, { bolts: 5 });
  m.cyl('trim', 0.04, 0.04, 1.4, 6, V(0, 0.3, 0.6), { rot: RZ(Math.PI / 2) });
  for (let i = 0; i < 3; i++) m.bevel('pack', 0.18, 0.3, 0.14, V(0.65 + i * 0.2, 0.15, 1.2), 0.02, { tint: [0.45, 0.48, 0.32] });   // mühimmat sandıkları
  m.group('turret', V(0, 0.15, 0.3));
  m.cyl('trim', 0.12, 0.14, 0.12, 10, V(0, 0.2, 0.3));
  m.group('barrel', V(0, 0.35, 0.3));
  const e = 1.0;
  tube(m, 'paint', 0.075, 0.075, 1.85, V(0, 0.3, 0.3), e, 12);
  const mid = along(V(0, 0.3, 0.3), e, 1.0);
  for (const s of [-1, 1]) {
    // çift ayak
    m.cyl('trim', 0.025, 0.025, 1.0, 6, V(s * 0.25, mid[1] / 2 + 0.02, mid[2] - 0.15), { rot: [0.25, 0, s * 0.35] });
  }
  m.bevel('dark', 0.12, 0.12, 0.1, V(0.12, mid[1], mid[2]), 0.02);
  m.meta = { muzzle: along(V(0, 0.3, 0.3), e, 1.9), radius: 1.2 };
  return m;
}

// ======================================================== dağ topu (hafif, parçalara ayrılabilir)
function mtngun(name, blue) {
  const m = new Model(name);
  carriage(m, { x: 0.62, y: 0.38, r: 0.38, w: 0.16, trail: 1.9, spread: 0.0 });
  m.group('turret', V(0, 0.6, 0.0));
  m.bevel('paint', 0.36, 0.28, 0.9, V(0, 0.72, 0.1), 0.03);
  if (blue) m.bevel('paint', 0.9, 0.55, 0.04, V(0, 0.95, -0.3), 0.015);
  m.group('barrel', V(0, 0.82, -0.2));
  const e = 0.28;
  tube(m, 'trim', 0.11, 0.11, 0.7, V(0, 0.82, 0.3), e);
  tube(m, 'paint', 0.07, 0.065, 1.8, V(0, 0.82, -0.2), e, 10);
  m.meta = { muzzle: along(V(0, 0.82, -0.2), e, 1.9), radius: 1.3 };
  return m;
}

// ======================================================== roketatar (6x6 kamyon + roket kutusu)
function mlrs(name, blue) {
  const m = new Model(name);
  m.bevel('trim', 1.2, 0.3, 6.6, V(0, 0.95, 0.3), 0.04);
  m.loft('paint', [
    [-3.4, [[1.15, 0.95], [1.12, 2.35]]],
    [-3.15, [[1.2, 0.85], [1.18, 2.55]]],
    [-1.8, [[1.2, 0.85], [1.18, 2.6]]],
  ], { mirror: true });
  m.box('glass', 2.1, 0.7, 0.03, V(0, 2.05, -3.42), { rot: RX(0.12) });
  for (const s of [-1, 1]) {
    m.box('glass', 0.03, 0.55, 0.8, V(s * 1.2, 2.1, -2.6));
    headlight(m, s * 0.85, 1.15, -3.44, 0.85);
    m.bevel('paint', 0.12, 0.6, 3.4, V(s * 1.18, 1.35, 1.6), 0.03);
    m.bevel('trim', 0.25, 0.35, 0.25, V(s * 1.15, 0.35, 3.3), 0.03);              // denge ayakları
    jerrycan(m, s * 1.25, 1.0, -1.2, 0);
  }
  m.bevel('paint', 2.4, 0.15, 4.2, V(0, 1.2, 1.4), 0.03);
  m.bevel('dark', 1.6, 0.4, 0.04, V(0, 1.35, -3.43), 0.02);
  antenna(m, -0.9, 2.55, -2.2, 1.6);
  for (const [i, z] of [-2.55, 0.8, 2.25].entries()) {
    tyre(m, i * 2, -1.05, 0.55, z, 0.55, 0.4, -1);
    tyre(m, i * 2 + 1, 1.05, 0.55, z, 0.55, 0.4, 1);
  }
  m.group('turret', V(0, 1.4, 1.9));
  m.cyl('trim', 0.6, 0.65, 0.2, 14, V(0, 1.4, 1.9));
  m.bevel('paint', 0.7, 0.5, 0.8, V(0, 1.7, 2.1), 0.04);
  m.group('barrel', V(0, 1.95, 2.8));
  const e = 0.42, L = 3.3;
  const d = [0, Math.sin(e), -Math.cos(e)];
  const c = [0, 1.95 + d[1] * L / 2 + 0.45, 2.8 + d[2] * L / 2];
  m.add('paint', new THREE.BoxGeometry(2.0, 0.9, L), { pos: c, rot: RX(e) });
  // tüp ağızları (ön yüz)
  const front = [0, c[1] + d[1] * L / 2, c[2] + d[2] * L / 2];
  const n = blue ? [2, 3] : [3, 5];
  for (let i = 0; i < n[1]; i++) for (let j = 0; j < n[0]; j++) {
    const lx = (i - (n[1] - 1) / 2) * (1.7 / n[1]);
    const ly = (j - (n[0] - 1) / 2) * (0.7 / n[0]);
    m.cyl('dark', 0.11, 0.11, 0.04, 10, [front[0] + lx, front[1] + ly * Math.cos(e), front[2] + ly * Math.sin(e) - 0.01], { rot: RX(e - Math.PI / 2) });
  }
  m.box('trim', 2.05, 0.04, 0.06, [c[0], c[1] + 0.47 * Math.cos(e), c[2] + 0.47 * Math.sin(e)], { rot: RX(e) });
  m.meta = { muzzle: front, radius: 2.3 };
  return m;
}

// ======================================================== sahil topçusu (beton yuva + kuleli top)
function coastal(name, blue) {
  const m = new Model(name);
  m.loft('trim', [[-3.2, [[3.2, 0.0], [2.9, 1.1]]], [3.2, [[3.2, 0.0], [2.9, 1.1]]]], { mirror: true, tint: [0.75, 0.74, 0.7] });
  m.cyl('dark', 2.2, 2.2, 0.05, 20, V(0, 1.12, 0));
  for (const s of [-1, 1]) m.bevel('trim', 1.2, 0.5, 0.8, V(s * 2.2, 1.35, 2.3), 0.05, { tint: [0.7, 0.7, 0.66] });
  m.group('turret', V(0, 1.15, 0));
  m.loft('paint', [
    [-1.9, [[1.1, 1.15], [0.9, 2.3]]],
    [-1.2, [[1.7, 1.15], [1.55, 2.6]]],
    [1.8, [[1.7, 1.15], [1.55, 2.6]]],
  ], { mirror: true });
  m.bevel('trim', 0.6, 0.35, 0.6, V(-0.9, 2.75, 0.4), 0.05);
  m.box('glass', 0.4, 0.15, 0.02, V(-0.9, 2.8, 0.09));
  antenna(m, 1.1, 2.6, 1.2, 2.0);
  m.group('barrel', V(0, 1.9, -1.7));
  const e = 0.12;
  tube(m, 'trim', 0.32, 0.32, 0.7, V(0, 1.9, -1.4), e);
  tube(m, 'paint', 0.18, 0.15, 7.0, V(0, 1.9, -1.7), e, 16);
  m.meta = { muzzle: along(V(0, 1.9, -1.7), e, 7.1), radius: 3.3 };
  return m;
}

const pair = (fn, base) => ({ [base + '_blue']: () => fn(base + '_blue', true), [base + '_red']: () => fn(base + '_red', false) });
export const ARTILLERY = {
  ...pair(fieldgun, 'fieldgun'), ...pair(howitzer, 'howitzer'), ...pair(atgun, 'atgun'), ...pair(aagun, 'aagun'),
  ...pair(hmortar, 'hmortar'), ...pair(mtngun, 'mtngun'), ...pair(mlrs, 'mlrs'), ...pair(coastal, 'coastal'),
};
