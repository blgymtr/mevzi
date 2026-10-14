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

// organik gövde: elips halkalardan yumuşak gölgeli parçalar
function body(m, blue) {
  const S = (mat, g, pos, o = {}) => m.add(mat, g, { pos, smooth: true, ...o });
  // ---------------- gövde + baş (kalça pivotu)
  m.group('torso', V(0, 0.92, 0));
  m.ringScale = 1.1;
  m.rings('uniform', [
    [0.86, 0.15, 0.105], [0.93, 0.163, 0.112], [1.0, 0.158, 0.108], [1.07, 0.148, 0.1],
    [1.16, 0.162, 0.108, 0, -0.005], [1.26, 0.185, 0.118, 0, -0.01], [1.35, 0.198, 0.118, 0, -0.008],
    [1.42, 0.19, 0.105], [1.47, 0.14, 0.085], [1.5, 0.07, 0.062],
  ]);
  // omuz yuvarlakları
  for (const s of [-1, 1]) S('uniform', new THREE.SphereGeometry(0.075, 14, 10), V(s * 0.19, 1.405, 0.0), { scale: [1, 0.9, 1] });
  if (blue) {
    // plaka taşıyıcı: ön/arka plaka (yuvarlatılmış), kemerband, şarjör cepleri, telsiz
    m.rings('vest', [[1.13, 0.17, 0.125, 0, -0.005], [1.2, 0.185, 0.132, 0, -0.01], [1.36, 0.19, 0.13, 0, -0.01], [1.42, 0.16, 0.11]], { seg: 16 });
    for (const x of [-0.105, 0, 0.105]) m.bevel('vest', 0.085, 0.13, 0.055, V(x, 1.17, -0.15), 0.02, { tint: [0.92, 0.92, 0.9] });
    m.bevel('vest', 0.1, 0.08, 0.05, V(-0.1, 1.33, -0.145), 0.015, { tint: [0.88, 0.88, 0.86] });
    m.bevel('dark', 0.06, 0.13, 0.05, V(0.12, 1.34, -0.14), 0.012);
    m.cyl('dark', 0.006, 0.006, 0.22, 3, V(0.13, 1.5, -0.13));
    for (const s of [-1, 1]) m.bevel('vest', 0.06, 0.04, 0.26, V(s * 0.12, 1.44, 0.0), 0.012, { tint: [0.85, 0.85, 0.82] });
    // hücum çantası
    m.rings('pack', [[1.05, 0.13, 0.07, 0, 0.2], [1.15, 0.155, 0.095, 0, 0.23], [1.38, 0.15, 0.09, 0, 0.23], [1.48, 0.11, 0.06, 0, 0.2]], { seg: 14 });
    m.rings('pack', [[1.12, 0.06, 0.04, -0.15, 0.2], [1.3, 0.06, 0.04, -0.15, 0.2]], { seg: 10, tint: [0.88, 0.88, 0.85] });   // yan cep
    m.rings('pack', [[1.12, 0.06, 0.04, 0.15, 0.2], [1.3, 0.06, 0.04, 0.15, 0.2]], { seg: 10, tint: [0.88, 0.88, 0.85] });
    m.rings('pack', [[1.47, 0.12, 0.05, 0, 0.21], [1.52, 0.12, 0.05, 0, 0.21]], { seg: 12, tint: [0.75, 0.75, 0.7] });     // rulo mat
    m.cyl('dark', 0.035, 0.035, 0.26, 8, V(0.0, 1.47, 0.2), { rot: RZ(Math.PI / 2) });
  } else {
    // göğüs teçhizatı (yumuşak yelek) + yaka
    m.rings('vest', [[1.08, 0.172, 0.128], [1.2, 0.188, 0.135, 0, -0.008], [1.36, 0.195, 0.128], [1.43, 0.165, 0.11]], { seg: 16 });
    m.add('vest', new THREE.TorusGeometry(0.095, 0.03, 8, 16, Math.PI * 1.4), { pos: V(0, 1.47, 0.0), rot: [Math.PI / 2, 0, -Math.PI * 0.2], tint: [0.9, 0.9, 0.88], smooth: true });
    for (const x of [-0.12, -0.04, 0.04, 0.12]) m.bevel('vest', 0.075, 0.14, 0.055, V(x, 1.2, -0.16), 0.02, { tint: [0.85, 0.85, 0.82] });
    m.bevel('dark', 0.08, 0.1, 0.05, V(-0.1, 1.34, -0.15), 0.012);
    m.rings('pack', [[1.1, 0.11, 0.055, 0, 0.17], [1.2, 0.13, 0.07, 0, 0.18], [1.33, 0.12, 0.065, 0, 0.18]], { seg: 12 });
  }
  // kemer + bel çantası + omuz bandı
  m.rings('dark', [[0.95, 0.168, 0.116], [0.99, 0.168, 0.116]], { seg: 16 });
  m.bevel('pack', 0.08, 0.09, 0.06, V(-0.15, 0.97, -0.07), 0.015, { tint: [0.8, 0.8, 0.78] });
  m.bevel('pack', 0.07, 0.1, 0.07, V(0.16, 0.96, 0.04), 0.015, { tint: [0.78, 0.78, 0.76] });
  S('team', new THREE.CylinderGeometry(0.064, 0.064, 0.05, 14, 1, true), V(-0.2, 1.34, 0.0));
  // boyun + baş
  m.rings('skin', [[1.49, 0.05, 0.05], [1.57, 0.047, 0.05]], { seg: 12 });
  S('skin', new THREE.SphereGeometry(0.1, 18, 14), V(0, 1.655, -0.005), { scale: [0.88, 1.06, 0.98] });
  S('skin', new THREE.SphereGeometry(0.06, 12, 8), V(0, 1.6, -0.045), { scale: [1.15, 0.8, 1.0] });        // çene
  S('skin', new THREE.SphereGeometry(0.018, 8, 6), V(0, 1.645, -0.1), { scale: [0.9, 1.3, 1.1] });         // burun
  for (const s of [-1, 1]) S('skin', new THREE.SphereGeometry(0.022, 8, 6), V(s * 0.088, 1.65, 0.005), { scale: [0.5, 1.1, 0.9] });   // kulaklar
  if (blue) {
    // kesik kenarlı kask (yumuşak) + kılıf + NVG yuvası + karşı ağırlık + gözlük
    S('helmet', new THREE.SphereGeometry(0.142, 22, 12, 0, Math.PI * 2, 0, Math.PI * 0.54), V(0, 1.662, 0.008), { scale: [1.0, 0.98, 1.08] });
    for (const s of [-1, 1]) m.bevel('dark', 0.02, 0.05, 0.11, V(s * 0.125, 1.69, 0.0), 0.008);
    m.bevel('dark', 0.07, 0.05, 0.035, V(0, 1.745, -0.12), 0.012);
    m.bevel('pack', 0.1, 0.06, 0.04, V(0, 1.7, 0.13), 0.015, { tint: [0.8, 0.8, 0.78] });
    S('dark', new THREE.CylinderGeometry(0.1, 0.1, 0.035, 18, 1, true, -Math.PI * 0.35, Math.PI * 0.7), V(0, 1.665, 0.0), { rot: [0, Math.PI, 0] });   // gözlük
    m.box('team', 0.03, 0.012, 0.18, V(0, 1.787, 0.01));
  } else {
    // yuvarlak kask + gözlük bandı
    S('helmet', new THREE.SphereGeometry(0.145, 22, 12, 0, Math.PI * 2, 0, Math.PI * 0.56), V(0, 1.652, 0.0), { scale: [1.02, 1.0, 1.06] });
    S('dark', new THREE.CylinderGeometry(0.136, 0.136, 0.022, 20, 1, true), V(0, 1.7, 0.0), { scale: [1.02, 1, 1.06] });
    m.bevel('dark', 0.14, 0.045, 0.04, V(0, 1.72, -0.12), 0.012);
    m.box('team', 0.2, 0.02, 0.03, V(0, 1.64, 0.13));
    S('uniform', new THREE.TorusGeometry(0.06, 0.022, 8, 14), V(0, 1.565, 0), { rot: RX(Math.PI / 2), tint: [0.85, 0.85, 0.8] });   // boyunluk
  }
  // ---------------- kol (omuz pivotu)
  m.group('arm', V(0, 1.42, 0));
  m.ringScale = 1.22;
  m.rings('uniform', [[1.44, 0.056, 0.058], [1.36, 0.058, 0.06], [1.24, 0.05, 0.053], [1.14, 0.045, 0.047]], { seg: 12 });
  if (blue) m.rings('vest', [[1.42, 0.066, 0.068], [1.33, 0.066, 0.068]], { seg: 12, tint: [0.9, 0.9, 0.88] });
  m.group('fore', V(0, 1.13, 0));
  m.rings('uniform', [[1.15, 0.046, 0.048], [1.06, 0.045, 0.048], [0.96, 0.038, 0.04], [0.9, 0.034, 0.036]], { seg: 12 });
  S(blue ? 'dark' : 'skin', new THREE.SphereGeometry(0.046, 10, 8), V(0, 0.85, -0.008), { scale: [0.8, 1.15, 0.95] });   // el
  S(blue ? 'dark' : 'skin', new THREE.SphereGeometry(0.02, 6, 6), V(-0.028, 0.86, -0.04), { scale: [0.8, 1.6, 0.8] });   // başparmak
  // ---------------- bacak (kalça pivotu)
  m.group('thigh', V(0, 0.92, 0));
  m.ringScale = 1.16;
  m.rings('uniform', [[0.95, 0.086, 0.09], [0.85, 0.084, 0.088], [0.72, 0.074, 0.078], [0.58, 0.062, 0.066], [0.5, 0.058, 0.062]], { seg: 14 });
  m.bevel('uniform', 0.055, 0.14, 0.11, V(0.085, 0.7, 0.0), 0.025, { tint: [0.9, 0.9, 0.88] });   // yan cep
  m.group('shin', V(0, 0.48, 0));
  m.ringScale = 1.14;
  m.rings('uniform', [[0.5, 0.06, 0.063], [0.4, 0.061, 0.066, 0, 0.01], [0.28, 0.05, 0.053, 0, 0.005], [0.17, 0.045, 0.048]], { seg: 14 });
  m.rings('dark', [[0.5, 0.058, 0.04, 0, -0.04], [0.42, 0.058, 0.04, 0, -0.045]], { seg: 12 });          // dizlik
  // bot
  m.rings('boot', [[0.2, 0.05, 0.055], [0.1, 0.055, 0.075, 0, -0.025], [0.04, 0.055, 0.13, 0, -0.045], [0.0, 0.055, 0.135, 0, -0.045]], { seg: 14 });
  m.rings('dark', [[0.0, 0.058, 0.138, 0, -0.045], [0.025, 0.058, 0.138, 0, -0.045]], { seg: 14 });     // taban
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
