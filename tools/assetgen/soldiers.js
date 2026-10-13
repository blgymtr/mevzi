// Eklemli asker modelleri. İleri -Z, ayakta kalça y=0.92.
// Düğümler (pivot = eklem): torso, arm (omuz), fore (dirsek), thigh (kalça), shin (diz),
// silahlar: rifle, mg, rpg, pistol (kabza noktası, -Z namlu), ekler: x_medic, x_at, x_radio
// Malzemeler: uniform, vest, skin, helmet, team, boot, gun, pack, dark, medic, red
import { Model, THREE } from './lib.js';

const V = (x, y, z) => [x, y, z];
const RX = (a) => [a, 0, 0];

function common(m, f) {
  const blue = f === 'blue';
  // ---------------- gövde + baş (kalça pivotu)
  m.group('torso', V(0, 0.92, 0));
  m.add('uniform', new THREE.CylinderGeometry(0.17, 0.15, 0.56, 8), { pos: V(0, 1.2, 0), scale: [1.05, 1, 0.66] });
  m.add('uniform', new THREE.CylinderGeometry(0.16, 0.17, 0.14, 8), { pos: V(0, 0.96, 0), scale: [1.05, 1, 0.7] });
  if (blue) {
    // plaka taşıyıcı + cepler
    m.box('vest', 0.36, 0.38, 0.26, V(0, 1.24, 0));
    for (const x of [-0.11, 0, 0.11]) m.box('vest', 0.09, 0.12, 0.06, V(x, 1.12, -0.15), { tint: [0.9, 0.9, 0.9] });
    m.box('vest', 0.08, 0.1, 0.05, V(-0.12, 1.3, -0.15), { tint: [0.85, 0.85, 0.85] });
    m.box('dark', 0.05, 0.12, 0.04, V(0.12, 1.32, -0.15));                       // telsiz
    m.box('pack', 0.32, 0.36, 0.16, V(0, 1.22, 0.2));                             // sırt çantası
    m.box('pack', 0.28, 0.1, 0.14, V(0, 1.44, 0.21), { tint: [0.85, 0.85, 0.85] });
  } else {
    // göğüs yeleği (chest rig)
    m.box('vest', 0.34, 0.2, 0.08, V(0, 1.15, -0.13));
    for (const x of [-0.1, 0.0, 0.1]) m.box('vest', 0.08, 0.13, 0.05, V(x, 1.15, -0.18), { tint: [0.9, 0.9, 0.9] });
    m.box('vest', 0.05, 0.4, 0.03, V(-0.12, 1.3, -0.1));
    m.box('vest', 0.05, 0.4, 0.03, V(0.12, 1.3, -0.1));
    m.box('pack', 0.22, 0.2, 0.1, V(0.04, 1.05, 0.15));                            // heybe
  }
  m.box('dark', 0.34, 0.05, 0.22, V(0, 0.97, 0));                                   // kemer
  m.box('team', 0.06, 0.07, 0.13, V(-0.2, 1.38, 0));                                // kol bandı (omuz)
  // boyun + baş
  m.cyl('skin', 0.05, 0.055, 0.1, 6, V(0, 1.53, 0));
  m.add('skin', new THREE.IcosahedronGeometry(0.105, 1), { pos: V(0, 1.65, 0), scale: [0.95, 1.08, 1.0] });
  if (blue) {
    m.add('helmet', new THREE.SphereGeometry(0.135, 10, 6, 0, Math.PI * 2, 0, Math.PI * 0.55), { pos: V(0, 1.67, 0.01), scale: [1, 0.95, 1.06] });
    m.box('dark', 0.06, 0.05, 0.05, V(0, 1.77, -0.12));                           // NVG yuvası
    m.box('dark', 0.17, 0.045, 0.03, V(0, 1.7, -0.12));                           // gözlük
    m.box('team', 0.24, 0.025, 0.22, V(0, 1.68, 0.01));                           // kask bandı
    m.box('dark', 0.06, 0.06, 0.05, V(-0.08, 1.78, 0.09));                        // ışık
  } else {
    m.add('team', new THREE.SphereGeometry(0.12, 10, 5, 0, Math.PI * 2, 0, Math.PI * 0.45), { pos: V(0.015, 1.71, 0), scale: [1.08, 0.6, 1.08] });   // bere
    m.cyl('team', 0.115, 0.115, 0.03, 10, V(0, 1.7, 0));
    m.box('dark', 0.12, 0.02, 0.01, V(0, 1.66, -0.1));                             // kaş/göz
  }
  // ---------------- kol (omuz pivotu): üst kol
  m.group('arm', V(0, 1.42, 0));
  m.add('uniform', new THREE.CylinderGeometry(0.052, 0.046, 0.3, 6), { pos: V(0, 1.27, 0) });
  if (blue) m.add('uniform', new THREE.SphereGeometry(0.065, 6, 4), { pos: V(0, 1.4, 0) });
  m.group('fore', V(0, 1.13, 0));
  m.add('uniform', new THREE.CylinderGeometry(0.045, 0.04, 0.24, 6), { pos: V(0, 1.0, 0) });
  m.add(blue ? 'dark' : 'skin', new THREE.BoxGeometry(0.07, 0.09, 0.08), { pos: V(0, 0.85, -0.01) });   // el / eldiven
  // ---------------- bacak (kalça pivotu)
  m.group('thigh', V(0, 0.92, 0));
  m.add('uniform', new THREE.CylinderGeometry(0.075, 0.062, 0.45, 7), { pos: V(0, 0.7, 0) });
  if (blue) m.box('pack', 0.08, 0.1, 0.06, V(0.07, 0.66, 0.0), { tint: [0.8, 0.8, 0.8] });   // bacak cebi
  m.group('shin', V(0, 0.48, 0));
  m.add('uniform', new THREE.CylinderGeometry(0.06, 0.05, 0.38, 7), { pos: V(0, 0.29, 0) });
  if (blue) m.box('dark', 0.1, 0.09, 0.05, V(0, 0.44, -0.05));                       // dizlik
  m.box('boot', 0.11, 0.12, 0.25, V(0, 0.06, -0.04));
  m.box('boot', 0.12, 0.03, 0.27, V(0, 0.015, -0.04), { tint: [0.6, 0.6, 0.6] });
}

function weapons(m, f) {
  const blue = f === 'blue';
  m.group('rifle', V(0, 0, 0));
  if (blue) {
    m.box('gun', 0.06, 0.08, 0.5, V(0, 0, -0.2));
    m.box('gun', 0.045, 0.045, 0.3, V(0, 0.01, -0.58));
    m.box('gun', 0.05, 0.12, 0.06, V(0, -0.08, -0.22));
    m.box('gun', 0.05, 0.1, 0.22, V(0, -0.02, 0.15));
    m.box('dark', 0.05, 0.06, 0.12, V(0, 0.07, -0.25));                             // nişangah
  } else {
    m.box('gun', 0.06, 0.08, 0.48, V(0, 0, -0.18));
    m.box('gun', 0.035, 0.035, 0.3, V(0, 0.02, -0.55));
    m.add('gun', new THREE.BoxGeometry(0.04, 0.16, 0.06), { pos: V(0, -0.1, -0.2), rot: RX(0.35) });     // şarjör (muz)
    m.box('wood', 0.055, 0.1, 0.24, V(0, -0.03, 0.14));
    m.box('wood', 0.055, 0.05, 0.16, V(0, -0.0, -0.36));
  }
  m.group('mg', V(0, 0, 0));
  m.box('gun', 0.08, 0.1, 0.75, V(0, 0, -0.25));
  m.box('gun', 0.04, 0.04, 0.35, V(0, 0.01, -0.78));
  m.box('pack', 0.12, 0.12, 0.14, V(0.08, -0.08, -0.12));                              // kutu
  m.box('gun', 0.05, 0.1, 0.22, V(0, -0.02, 0.2));
  m.add('gun', new THREE.CylinderGeometry(0.01, 0.01, 0.3, 4), { pos: V(0.05, -0.12, -0.75), rot: [0.4, 0, 0.4] });
  m.add('gun', new THREE.CylinderGeometry(0.01, 0.01, 0.3, 4), { pos: V(-0.05, -0.12, -0.75), rot: [0.4, 0, -0.4] });
  m.group('rpg', V(0, 0, 0));
  m.cyl(blue ? 'pack' : 'gun', 0.055, 0.055, 1.05, 8, V(0, 0, 0.1), { rot: RX(Math.PI / 2), tint: blue ? [0.8, 0.8, 0.7] : [1, 1, 1] });
  if (!blue) m.add('pack', new THREE.ConeGeometry(0.075, 0.28, 8), { pos: V(0, 0, -0.55), rot: RX(-Math.PI / 2), tint: [0.75, 0.78, 0.6] });
  else m.box('dark', 0.1, 0.12, 0.16, V(0.07, 0.04, -0.15));
  m.box('gun', 0.04, 0.12, 0.05, V(0, -0.08, 0.0));
  m.group('sniper', V(0, 0, 0));
  m.box(blue ? 'gun' : 'wood', 0.055, 0.08, 0.6, V(0, 0, -0.2), { tint: blue ? [0.8, 0.75, 0.6] : [1, 1, 1] });
  m.box('gun', 0.03, 0.03, 0.55, V(0, 0.02, -0.75));
  m.cyl('dark', 0.03, 0.035, 0.3, 8, V(0, 0.1, -0.15), { rot: RX(Math.PI / 2) });
  m.box(blue ? 'gun' : 'wood', 0.05, 0.11, 0.25, V(0, -0.03, 0.18), { tint: blue ? [0.8, 0.75, 0.6] : [1, 1, 1] });
  m.group('smg', V(0, 0, 0));
  m.box('gun', 0.05, 0.08, 0.36, V(0, 0, -0.1));
  m.box('gun', 0.035, 0.12, 0.05, V(0, -0.09, -0.12));
  m.box('gun', 0.04, 0.06, 0.18, V(0, 0, 0.16));
  m.group('mortar', V(0, 0, 0));
  m.cyl('gun', 0.045, 0.045, 0.9, 8, V(0, 0, -0.3), { rot: RX(Math.PI / 2) });
  m.cyl('gun', 0.16, 0.16, 0.03, 10, V(0, 0, 0.15), { rot: RX(Math.PI / 2) });
  m.group('tablet', V(0, 0, 0));
  m.box('dark', 0.22, 0.03, 0.15, V(0, 0, -0.1));
  m.box('light', 0.18, 0.005, 0.11, V(0, 0.017, -0.1));
  m.group('pistol', V(0, 0, 0));
  m.box('gun', 0.04, 0.05, 0.18, V(0, 0, -0.06));
  m.box('gun', 0.035, 0.09, 0.04, V(0, -0.05, 0.0));
  // rol ekleri (gövdeye takılır, kalça pivotu)
  m.group('x_medic', V(0, 0.92, 0));
  m.box('medic', 0.16, 0.16, 0.02, V(0, 1.3, 0.29));
  m.box('red', 0.1, 0.03, 0.01, V(0, 1.3, 0.301));
  m.box('red', 0.03, 0.1, 0.01, V(0, 1.3, 0.301));
  m.box('medic', 0.065, 0.075, 0.135, V(0.2, 1.38, 0));
  m.group('x_at', V(0, 0.92, 0));
  for (const x of [-0.08, 0.08]) {
    m.cyl('pack', 0.05, 0.05, 0.5, 6, V(x, 1.28, 0.26), { tint: [0.75, 0.78, 0.6] });
    m.add('pack', new THREE.ConeGeometry(0.06, 0.18, 6), { pos: V(x, 1.62, 0.26), tint: [0.7, 0.72, 0.55] });
  }
  m.group('x_eng', V(0, 0.92, 0));
  m.box('pack', 0.3, 0.38, 0.18, V(0, 1.25, 0.24), { tint: [0.7, 0.7, 0.6] });
  m.box('gun', 0.05, 0.6, 0.05, V(0.12, 1.4, 0.3), { rot: [0, 0, 0.3] });
  m.box('gun', 0.18, 0.16, 0.03, V(0.22, 1.7, 0.3), { rot: [0, 0, 0.3] });
  m.group('x_sniper', V(0, 0.92, 0));
  for (let i = 0; i < 8; i++) m.box('pack', 0.12, 0.08, 0.12, V((i % 3 - 1) * 0.12, 1.25 + Math.floor(i / 3) * 0.12, 0.2 + (i % 2) * 0.03), { tint: [0.55, 0.58, 0.35], rot: [0.3, i, 0] });
  m.group('x_mortar', V(0, 0.92, 0));
  m.box('pack', 0.28, 0.3, 0.2, V(0, 1.22, 0.24), { tint: [0.6, 0.62, 0.45] });
  for (const x of [-0.08, 0.08]) m.cyl('pack', 0.04, 0.04, 0.3, 6, V(x, 1.5, 0.24), { tint: [0.5, 0.52, 0.38] });
  m.group('x_radio', V(0, 0.92, 0));
  m.box('dark', 0.2, 0.26, 0.12, V(0, 1.3, 0.3));
  m.cyl('dark', 0.006, 0.006, 0.9, 3, V(-0.07, 1.8, 0.3));
}

export function soldier_blue() { const m = new Model('soldier_blue'); common(m, 'blue'); weapons(m, 'blue'); return m; }
export function soldier_red() { const m = new Model('soldier_red'); common(m, 'red'); weapons(m, 'red'); return m; }
export const SOLDIERS = { soldier_blue, soldier_red };
