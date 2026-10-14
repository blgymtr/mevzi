// Eklemli asker modelleri v2. İleri -Z, ayakta kalça y=0.92.
// Düğümler (pivot = eklem): torso, arm (omuz), fore (dirsek), thigh (kalça), shin (diz),
// silahlar: rifle, mg, rpg, sniper, smg, mortar, tablet, pistol (kabza noktası, -Z namlu)
// ekler: x_medic, x_at, x_eng, x_sniper, x_mortar, x_radio
// Malzemeler: uniform, vest, skin, helmet, team, boot, gun, pack, dark, medic, red, wood
import { Model, THREE } from './lib.js';

const V = (x, y, z) => [x, y, z];
const RX = (a) => [a, 0, 0];
const RY = (a) => [0, a, 0];
const RZ = (a) => [0, 0, a];

// sivrilen uzuv: üstte r0, altta r1, uzunluk L, merkez y
function limb(m, mat, r0, r1, L, y, o = {}) {
  m.add(mat, new THREE.CylinderGeometry(r0, r1, L, 8), { pos: V(o.x ?? 0, y, o.z ?? 0), scale: [1, 1, o.flat ?? 0.92], rot: o.rot });
}

function body(m, blue) {
  // ---------------- gövde + baş (kalça pivotu)
  m.group('torso', V(0, 0.92, 0));
  // kalça / bel
  m.hull('uniform', [
    [-0.16, 0.9, -0.1], [0.16, 0.9, -0.1], [-0.16, 0.9, 0.1], [0.16, 0.9, 0.1],
    [-0.15, 1.04, -0.1], [0.15, 1.04, -0.1], [-0.15, 1.04, 0.09], [0.15, 1.04, 0.09],
  ]);
  // göğüs kafesi (omuzda geniş)
  m.hull('uniform', [
    [-0.15, 1.0, -0.09], [0.15, 1.0, -0.09], [-0.15, 1.0, 0.09], [0.15, 1.0, 0.09],
    [-0.19, 1.3, -0.11], [0.19, 1.3, -0.11], [-0.19, 1.3, 0.1], [0.19, 1.3, 0.1],
    [-0.2, 1.43, -0.07], [0.2, 1.43, -0.07], [-0.2, 1.43, 0.08], [0.2, 1.43, 0.08],
    [-0.08, 1.5, -0.04], [0.08, 1.5, -0.04], [-0.08, 1.5, 0.05], [0.08, 1.5, 0.05],
  ]);
  for (const s of [-1, 1]) m.add('uniform', new THREE.SphereGeometry(0.075, 8, 6), { pos: V(s * 0.19, 1.41, 0.0) });
  if (blue) {
    // plaka taşıyıcı: ön/arka plaka, kemerband, şarjör cepleri, telsiz, ilk yardım
    m.bevel('vest', 0.34, 0.34, 0.07, V(0, 1.26, -0.125), 0.025);
    m.bevel('vest', 0.33, 0.34, 0.07, V(0, 1.27, 0.12), 0.025);
    m.bevel('vest', 0.38, 0.13, 0.25, V(0, 1.12, 0.0), 0.03);
    for (const x of [-0.105, 0, 0.105]) m.bevel('vest', 0.09, 0.13, 0.06, V(x, 1.15, -0.18), 0.015, { tint: [0.92, 0.92, 0.9] });
    m.bevel('vest', 0.1, 0.08, 0.05, V(-0.1, 1.33, -0.17), 0.012, { tint: [0.88, 0.88, 0.86] });
    m.bevel('dark', 0.06, 0.13, 0.05, V(0.12, 1.36, -0.16), 0.01);
    m.cyl('dark', 0.006, 0.006, 0.2, 3, V(0.13, 1.5, -0.15));
    for (const s of [-1, 1]) m.box('vest', 0.06, 0.04, 0.24, V(s * 0.12, 1.44, 0.0), { tint: [0.85, 0.85, 0.82] });   // omuz askısı
    // hücum çantası
    m.bevel('pack', 0.28, 0.34, 0.14, V(0, 1.26, 0.22), 0.04);
    m.bevel('pack', 0.22, 0.12, 0.08, V(0, 1.18, 0.3), 0.025, { tint: [0.85, 0.85, 0.85] });
    m.cyl('dark', 0.035, 0.035, 0.26, 6, V(0.0, 1.46, 0.22), { rot: RZ(Math.PI / 2) });
  } else {
    // ağır yelek + yaka + göğüs teçhizatı
    m.hull('vest', [
      [-0.2, 1.06, -0.15], [0.2, 1.06, -0.15], [-0.2, 1.06, 0.14], [0.2, 1.06, 0.14],
      [-0.21, 1.4, -0.13], [0.21, 1.4, -0.13], [-0.21, 1.4, 0.13], [0.21, 1.4, 0.13],
    ]);
    m.add('vest', new THREE.TorusGeometry(0.1, 0.035, 5, 10, Math.PI * 1.4), { pos: V(0, 1.47, 0.0), rot: [Math.PI / 2, 0, -Math.PI * 0.2], tint: [0.9, 0.9, 0.88] });
    for (const x of [-0.12, -0.04, 0.04, 0.12]) m.bevel('vest', 0.075, 0.14, 0.06, V(x, 1.2, -0.18), 0.015, { tint: [0.85, 0.85, 0.82] });
    m.bevel('dark', 0.08, 0.1, 0.05, V(-0.1, 1.35, -0.17), 0.012);
    m.bevel('pack', 0.26, 0.3, 0.13, V(0, 1.22, 0.21), 0.04);
  }
  m.box('dark', 0.36, 0.045, 0.23, V(0, 0.98, 0.0));                                    // kemer
  m.bevel('pack', 0.08, 0.09, 0.06, V(-0.15, 0.98, -0.05), 0.012, { tint: [0.8, 0.8, 0.78] });   // bel çantası
  m.box('team', 0.075, 0.06, 0.15, V(-0.2, 1.36, 0.0));                                  // omuz bandı
  // boyun + baş
  m.cyl('skin', 0.048, 0.055, 0.1, 7, V(0, 1.54, 0.0));
  m.add('skin', new THREE.IcosahedronGeometry(0.1, 2), { pos: V(0, 1.655, -0.005), scale: [0.9, 1.08, 0.98] });
  m.box('skin', 0.03, 0.04, 0.03, V(0, 1.64, -0.1));                                     // burun
  if (blue) {
    // kesik kenarlı kask + kılıf + gece görüş yuvası + karşı ağırlık
    m.add('helmet', new THREE.SphereGeometry(0.128, 12, 7, 0, Math.PI * 2, 0, Math.PI * 0.52), { pos: V(0, 1.665, 0.008), scale: [1.0, 0.98, 1.08] });
    for (const s of [-1, 1]) m.bevel('dark', 0.02, 0.05, 0.11, V(s * 0.125, 1.69, 0.0), 0.008);        // yan ray
    m.bevel('dark', 0.07, 0.05, 0.035, V(0, 1.745, -0.12), 0.01);
    m.bevel('pack', 0.1, 0.06, 0.04, V(0, 1.7, 0.13), 0.012, { tint: [0.8, 0.8, 0.78] });
    m.box('dark', 0.16, 0.04, 0.025, V(0, 1.665, -0.095));                              // gözlük
    m.box('team', 0.03, 0.012, 0.18, V(0, 1.785, 0.01));                                // kask şeridi
  } else {
    // yuvarlak kask + gözlük bandı
    m.add('helmet', new THREE.SphereGeometry(0.132, 12, 7, 0, Math.PI * 2, 0, Math.PI * 0.56), { pos: V(0, 1.655, 0.0), scale: [1.02, 1.0, 1.06] });
    m.add('dark', new THREE.CylinderGeometry(0.135, 0.135, 0.022, 12, 1, true), { pos: V(0, 1.7, 0.0), scale: [1.02, 1, 1.06] });
    m.bevel('dark', 0.14, 0.045, 0.04, V(0, 1.72, -0.12), 0.01);
    m.box('team', 0.2, 0.02, 0.03, V(0, 1.64, 0.13));                                   // ense bandı
    m.box('uniform', 0.15, 0.06, 0.03, V(0, 1.58, -0.09), { tint: [0.85, 0.85, 0.8] });  // boyunluk
  }
  // ---------------- kol (omuz pivotu)
  m.group('arm', V(0, 1.42, 0));
  limb(m, 'uniform', 0.056, 0.047, 0.3, 1.27);
  if (blue) m.bevel('vest', 0.1, 0.1, 0.11, V(0, 1.34, 0.0), 0.03, { tint: [0.9, 0.9, 0.88] });   // omuz pedi
  m.group('fore', V(0, 1.13, 0));
  limb(m, 'uniform', 0.047, 0.04, 0.25, 1.0);
  m.add('dark', new THREE.SphereGeometry(0.05, 7, 5), { pos: V(0, 1.12, 0.005), scale: [1, 0.8, 1] });    // dirsek
  m.bevel(blue ? 'dark' : 'skin', 0.075, 0.1, 0.085, V(0, 0.84, -0.01), 0.02);            // el
  // ---------------- bacak (kalça pivotu)
  m.group('thigh', V(0, 0.92, 0));
  limb(m, 'uniform', 0.085, 0.065, 0.46, 0.7);
  m.bevel('uniform', 0.06, 0.13, 0.11, V(0.085, 0.68, 0.0), 0.02, { tint: [0.9, 0.9, 0.88] });   // yan cep
  m.group('shin', V(0, 0.48, 0));
  limb(m, 'uniform', 0.064, 0.05, 0.38, 0.29);
  m.bevel('dark', 0.1, 0.1, 0.06, V(0, 0.45, -0.055), 0.025);                             // dizlik
  m.bevel('boot', 0.11, 0.13, 0.27, V(0, 0.07, -0.04), 0.03);
  m.box('dark', 0.12, 0.03, 0.28, V(0, 0.015, -0.04));                                    // taban
}

function weapons(m, blue) {
  // ---------------- tüfek
  m.group('rifle', V(0, 0, 0));
  if (blue) {
    m.bevel('gun', 0.055, 0.075, 0.36, V(0, 0.0, -0.12), 0.012);                         // gövde
    m.bevel('gun', 0.06, 0.06, 0.26, V(0, 0.005, -0.42), 0.012);                         // el kundağı
    m.cyl('gun', 0.012, 0.012, 0.2, 6, V(0, 0.005, -0.64), { rot: RX(Math.PI / 2) });
    m.bevel('gun', 0.035, 0.12, 0.06, V(0, -0.085, -0.16), 0.01, { rot: RX(0.18) });    // şarjör
    m.bevel('gun', 0.03, 0.08, 0.04, V(0, -0.07, -0.02), 0.008, { rot: RX(-0.3) });     // kabza
    m.bevel('gun', 0.045, 0.08, 0.2, V(0, -0.015, 0.16), 0.015);                         // dipçik
    m.bevel('dark', 0.04, 0.05, 0.1, V(0, 0.07, -0.15), 0.01);                           // optik
    m.cyl('dark', 0.022, 0.022, 0.03, 8, V(0, 0.075, -0.21), { rot: RX(Math.PI / 2) });
  } else {
    m.bevel('gun', 0.055, 0.08, 0.36, V(0, 0.0, -0.1), 0.012);
    m.bevel('wood', 0.055, 0.055, 0.2, V(0, -0.005, -0.38), 0.012);
    m.cyl('gun', 0.012, 0.012, 0.24, 6, V(0, 0.015, -0.6), { rot: RX(Math.PI / 2) });
    m.add('gun', new THREE.BoxGeometry(0.035, 0.17, 0.06), { pos: V(0, -0.11, -0.16), rot: RX(0.45) });   // muz şarjör
    m.bevel('wood', 0.03, 0.08, 0.04, V(0, -0.07, -0.0), 0.008, { rot: RX(-0.3) });
    m.bevel('wood', 0.045, 0.09, 0.22, V(0, -0.025, 0.17), 0.015);
    m.box('gun', 0.03, 0.02, 0.1, V(0, 0.05, -0.12));
  }
  // ---------------- makineli tüfek
  m.group('mg', V(0, 0, 0));
  m.bevel('gun', 0.075, 0.1, 0.5, V(0, 0, -0.18), 0.015);
  m.bevel('gun', 0.06, 0.06, 0.2, V(0, 0.005, -0.52), 0.012);
  m.cyl('gun', 0.018, 0.018, 0.34, 6, V(0, 0.01, -0.78), { rot: RX(Math.PI / 2) });
  m.bevel(blue ? 'pack' : 'gun', 0.11, 0.12, 0.13, V(0.08, -0.09, -0.12), 0.02, { tint: [0.85, 0.85, 0.8] });   // fişek kutusu
  m.bevel('gun', 0.045, 0.1, 0.2, V(0, -0.02, 0.18), 0.015);
  m.bevel('gun', 0.03, 0.08, 0.04, V(0, -0.07, -0.02), 0.008, { rot: RX(-0.3) });
  m.bevel('dark', 0.045, 0.05, 0.1, V(0, 0.08, -0.1), 0.01);
  for (const s of [-1, 1]) m.cyl('gun', 0.008, 0.008, 0.28, 4, V(s * 0.04, -0.11, -0.74), { rot: [0.35, 0, s * 0.3] });
  // ---------------- tanksavar
  m.group('rpg', V(0, 0, 0));
  if (blue) {
    m.cyl('pack', 0.06, 0.06, 1.05, 10, V(0, 0, 0.1), { rot: RX(Math.PI / 2), tint: [0.72, 0.74, 0.6] });
    m.cyl('dark', 0.065, 0.065, 0.05, 10, V(0, 0, -0.43), { rot: RX(Math.PI / 2) });
    m.cyl('dark', 0.07, 0.065, 0.12, 10, V(0, 0, 0.6), { rot: RX(Math.PI / 2) });
    m.bevel('dark', 0.08, 0.1, 0.14, V(0.07, 0.05, -0.12), 0.015);
  } else {
    m.cyl('gun', 0.04, 0.04, 0.95, 8, V(0, 0, 0.12), { rot: RX(Math.PI / 2) });
    m.cyl('wood', 0.05, 0.05, 0.25, 8, V(0, 0, 0.0), { rot: RX(Math.PI / 2) });
    m.add('pack', new THREE.ConeGeometry(0.08, 0.3, 10), { pos: V(0, 0, -0.55), rot: RX(-Math.PI / 2), tint: [0.62, 0.66, 0.5] });
    m.cyl('pack', 0.04, 0.05, 0.12, 8, V(0, 0, -0.36), { rot: RX(Math.PI / 2), tint: [0.62, 0.66, 0.5] });
    m.cyl('gun', 0.055, 0.045, 0.12, 8, V(0, 0, 0.62), { rot: RX(Math.PI / 2) });
  }
  m.bevel('gun', 0.035, 0.11, 0.045, V(0, -0.08, 0.0), 0.008);
  // ---------------- keskin nişancı tüfeği
  m.group('sniper', V(0, 0, 0));
  m.bevel(blue ? 'pack' : 'wood', 0.055, 0.08, 0.62, V(0, -0.01, -0.12), 0.015, { tint: blue ? [0.7, 0.66, 0.5] : [1, 1, 1] });
  m.cyl('gun', 0.014, 0.012, 0.6, 6, V(0, 0.015, -0.72), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.028, 0.032, 0.32, 8, V(0, 0.09, -0.15), { rot: RX(Math.PI / 2) });
  m.cyl('dark', 0.036, 0.036, 0.04, 8, V(0, 0.09, -0.32), { rot: RX(Math.PI / 2) });
  m.bevel(blue ? 'pack' : 'wood', 0.045, 0.11, 0.24, V(0, -0.03, 0.2), 0.015, { tint: blue ? [0.7, 0.66, 0.5] : [1, 1, 1] });
  for (const s of [-1, 1]) m.cyl('gun', 0.007, 0.007, 0.22, 4, V(s * 0.03, -0.1, -0.5), { rot: [0.4, 0, s * 0.25] });
  // ---------------- kısa tüfek (istihkâm)
  m.group('smg', V(0, 0, 0));
  m.bevel('gun', 0.05, 0.075, 0.3, V(0, 0, -0.08), 0.012);
  m.cyl('gun', 0.012, 0.012, 0.14, 6, V(0, 0.005, -0.3), { rot: RX(Math.PI / 2) });
  m.bevel('gun', 0.032, 0.12, 0.05, V(0, -0.09, -0.1), 0.008, { rot: RX(0.15) });
  m.bevel('gun', 0.04, 0.07, 0.16, V(0, -0.01, 0.15), 0.012);
  m.bevel('dark', 0.035, 0.04, 0.07, V(0, 0.06, -0.1), 0.008);
  // ---------------- havan tüpü
  m.group('mortar', V(0, 0, 0));
  m.cyl('gun', 0.045, 0.045, 0.9, 10, V(0, 0, -0.3), { rot: RX(Math.PI / 2) });
  m.cyl('gun', 0.17, 0.17, 0.03, 12, V(0, 0, 0.15), { rot: RX(Math.PI / 2) });
  m.bevel('dark', 0.06, 0.06, 0.1, V(0.07, 0.04, -0.3), 0.01);
  // ---------------- tablet (drone kumandası)
  m.group('tablet', V(0, 0, 0));
  m.bevel('dark', 0.24, 0.035, 0.16, V(0, 0, -0.1), 0.01);
  m.box('light', 0.17, 0.005, 0.1, V(0, 0.02, -0.1));
  for (const s of [-1, 1]) m.cyl('dark', 0.012, 0.012, 0.04, 5, V(s * 0.09, 0.03, -0.06));
  // ---------------- tabanca
  m.group('pistol', V(0, 0, 0));
  m.bevel('gun', 0.035, 0.045, 0.18, V(0, 0, -0.06), 0.008);
  m.bevel('gun', 0.032, 0.09, 0.045, V(0, -0.05, 0.0), 0.008, { rot: RX(-0.2) });
  // ---------------- rol ekleri (gövdeye takılır, kalça pivotu)
  m.group('x_medic', V(0, 0.92, 0));
  m.bevel('medic', 0.22, 0.26, 0.1, V(0, 1.27, 0.31), 0.03);
  m.box('red', 0.12, 0.035, 0.01, V(0, 1.3, 0.362));
  m.box('red', 0.035, 0.12, 0.01, V(0, 1.3, 0.362));
  m.box('medic', 0.075, 0.08, 0.15, V(0.2, 1.36, 0.0));
  m.box('red', 0.076, 0.03, 0.03, V(0.2, 1.36, -0.03));
  m.group('x_at', V(0, 0.92, 0));
  for (const x of [-0.09, 0.09]) {
    m.cyl('pack', 0.05, 0.05, 0.5, 8, V(x, 1.28, 0.27), { tint: [0.6, 0.64, 0.48] });
    m.add('pack', new THREE.ConeGeometry(0.06, 0.18, 8), { pos: V(x, 1.62, 0.27), tint: [0.55, 0.58, 0.44] });
  }
  m.box('dark', 0.26, 0.03, 0.04, V(0, 1.2, 0.27));
  m.group('x_eng', V(0, 0.92, 0));
  m.bevel('pack', 0.3, 0.4, 0.18, V(0, 1.25, 0.25), 0.04, { tint: [0.75, 0.74, 0.62] });
  m.box('gun', 0.04, 0.62, 0.04, V(0.13, 1.42, 0.32), { rot: RZ(0.3) });
  m.bevel('gun', 0.18, 0.16, 0.03, V(0.23, 1.72, 0.32), 0.01, { rot: RZ(0.3) });
  m.bevel('dark', 0.12, 0.08, 0.06, V(-0.1, 1.05, 0.25), 0.015);
  m.group('x_sniper', V(0, 0.92, 0));
  // gölge kıyafet (ghillie) parçaları
  for (let i = 0; i < 14; i++) {
    const a = i * 2.3;
    m.add('pack', new THREE.IcosahedronGeometry(0.07, 0), { pos: V(Math.sin(a) * 0.16, 1.08 + (i % 5) * 0.09, 0.12 + Math.cos(a) * 0.08), rot: [a, i, 0], tint: [0.5 + (i % 3) * 0.06, 0.55, 0.32] });
  }
  m.group('x_mortar', V(0, 0.92, 0));
  m.bevel('pack', 0.28, 0.3, 0.2, V(0, 1.22, 0.25), 0.04, { tint: [0.62, 0.64, 0.48] });
  for (const x of [-0.08, 0.08]) {
    m.cyl('pack', 0.04, 0.04, 0.3, 8, V(x, 1.5, 0.25), { tint: [0.5, 0.52, 0.38] });
    m.add('pack', new THREE.ConeGeometry(0.04, 0.08, 8), { pos: V(x, 1.69, 0.25), tint: [0.45, 0.47, 0.35] });
  }
  m.group('x_radio', V(0, 0.92, 0));
  m.bevel('dark', 0.2, 0.28, 0.12, V(0, 1.3, 0.3), 0.025);
  m.cyl('dark', 0.006, 0.006, 0.95, 3, V(-0.07, 1.85, 0.3));
  m.bevel('pack', 0.22, 0.14, 0.1, V(0, 1.1, 0.29), 0.02, { tint: [0.8, 0.8, 0.78] });
}

export function soldier_blue() { const m = new Model('soldier_blue'); body(m, true); weapons(m, true); return m; }
export function soldier_red() { const m = new Model('soldier_red'); body(m, false); weapons(m, false); return m; }
export const SOLDIERS = { soldier_blue, soldier_red };
