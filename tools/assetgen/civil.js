// Sivil araçlar (harita dekoru / enkaz): sedan, hatchback, pikap, minibüs, eski Doğu sedanı, otobüs.
// İleri +X (props.gd ile uyumlu), Y yukarı, metre. Malzemeler: body (boya, renk oyunda verilir),
// glass, chrome, rubber, dark, light, red, metal, trim (plastik tampon).
import { Model, THREE } from './lib.js';

const V = (x, y, z) => [x, y, z];
const RX = (a) => [a, 0, 0];

function wheel(m, x, z, r, w) {
  const s = Math.sign(z);
  m.cyl('rubber', r, r, w, 16, V(x, r, z), { rot: RX(Math.PI / 2) });
  m.cyl('chrome', r * 0.6, r * 0.6, w * 1.04, 12, V(x, r, z + s * 0.01), { rot: RX(Math.PI / 2) });
  m.cyl('dark', r * 0.25, r * 0.25, w * 1.1, 8, V(x, r, z + s * 0.02), { rot: RX(Math.PI / 2) });
}

// gövde: yandan profil (x,y) → z = ±w/2 arasında; üst kısım daralır (tumblehome)
function shell(m, mat, prof, w, taper = 0.0) {
  const pts = [];
  for (const [x, y] of prof) {
    const k = 1 - taper * Math.max(0, (y - 0.9) / 0.6);
    pts.push([x, y, w / 2 * k], [x, y, -w / 2 * k]);
  }
  m.hull(mat, pts);
}

function lights(m, xF, xR, y, w, rear = 0.8) {
  for (const s of [-1, 1]) {
    m.bevel('light', 0.04, 0.12, 0.32, V(xF, y, s * (w / 2 - 0.25)), 0.02);
    m.bevel('red', 0.04, 0.12, 0.26, V(xR, y + 0.05 * rear, s * (w / 2 - 0.2)), 0.02);
  }
}

function plates(m, xF, xR, y) {
  m.box('chrome', 0.02, 0.11, 0.5, V(xF, y, 0));
  m.box('chrome', 0.02, 0.11, 0.5, V(xR, y, 0));
}

function mirrors(m, x, y, w) {
  for (const s of [-1, 1]) m.bevel('body', 0.1, 0.09, 0.14, V(x, y, s * (w / 2 + 0.05)), 0.02);
}

function windows(m, prof, w, inset = 0.02) {
  // cam şeridi: kabin profilinin biraz içi
  shell(m, 'glass', prof, w + inset, 0.18);
}

export function car_sedan() {
  const m = new Model('car_sedan');
  const w = 1.78;
  shell(m, 'body', [[-2.3, 0.32], [-2.35, 0.75], [-2.0, 0.95], [-1.2, 0.98], [1.5, 0.98], [2.25, 0.82], [2.3, 0.45], [2.1, 0.3], [-2.1, 0.3]], w);
  shell(m, 'body', [[-1.55, 0.95], [-1.05, 1.42], [0.45, 1.44], [1.25, 0.95]], w - 0.08, 0.18);
  windows(m, [[-1.48, 0.98], [-1.02, 1.38], [0.42, 1.4], [1.18, 0.98]], w - 0.05);
  shell(m, 'body', [[-0.98, 1.4], [-0.9, 1.45], [0.36, 1.46], [0.42, 1.41]], w - 0.2, 0.0);   // tavan
  for (const s of [-1, 1]) m.box('dark', 0.02, 0.45, 0.02, V(-0.1, 1.18, s * (w / 2 - 0.12)));   // B direği
  m.bevel('trim', 0.12, 0.2, w, V(2.28, 0.42, 0), 0.04);
  m.bevel('trim', 0.12, 0.2, w, V(-2.33, 0.42, 0), 0.04);
  m.bevel('dark', 0.03, 0.12, 0.8, V(2.31, 0.62, 0), 0.02);   // ızgara
  lights(m, 2.27, -2.33, 0.72, w);
  plates(m, 2.36, -2.4, 0.42);
  mirrors(m, 0.95, 1.05, w);
  for (const x of [-1.35, 1.38]) for (const z of [-0.78, 0.78]) wheel(m, x, z, 0.32, 0.22);
  return m;
}

export function car_hatch() {
  const m = new Model('car_hatch');
  const w = 1.7;
  shell(m, 'body', [[-1.8, 0.32], [-1.85, 0.85], [-1.7, 1.0], [1.2, 0.98], [1.85, 0.8], [1.9, 0.45], [1.7, 0.3], [-1.7, 0.3]], w);
  shell(m, 'body', [[-1.8, 0.98], [-1.7, 1.45], [0.25, 1.48], [1.05, 0.98]], w - 0.08, 0.18);
  windows(m, [[-1.75, 1.02], [-1.65, 1.4], [0.22, 1.43], [0.98, 1.0]], w - 0.05);
  m.bevel('trim', 0.1, 0.2, w, V(1.88, 0.42, 0), 0.04);
  m.bevel('trim', 0.1, 0.2, w, V(-1.86, 0.42, 0), 0.04);
  lights(m, 1.86, -1.84, 0.74, w, 2.0);
  plates(m, 1.95, -1.92, 0.42);
  mirrors(m, 0.75, 1.05, w);
  for (const x of [-1.15, 1.22]) for (const z of [-0.74, 0.74]) wheel(m, x, z, 0.3, 0.2);
  return m;
}

export function car_pickup() {
  const m = new Model('car_pickup');
  const w = 1.88;
  shell(m, 'body', [[-2.6, 0.45], [-2.65, 1.0], [2.35, 1.02], [2.6, 0.9], [2.65, 0.55], [2.45, 0.42], [-2.45, 0.42]], w);
  shell(m, 'body', [[-0.4, 1.0], [-0.35, 1.75], [0.85, 1.78], [1.6, 1.02]], w - 0.06, 0.12);
  windows(m, [[-0.33, 1.05], [-0.3, 1.7], [0.82, 1.73], [1.52, 1.05]], w - 0.03);
  // kasa
  m.bevel('dark', 2.1, 0.06, w - 0.2, V(-1.5, 1.0, 0), 0.02);
  for (const s of [-1, 1]) m.bevel('body', 2.2, 0.42, 0.06, V(-1.5, 1.2, s * (w / 2 - 0.03)), 0.02);
  m.bevel('body', 0.06, 0.42, w, V(-2.6, 1.2, 0), 0.02);
  m.bevel('chrome', 0.14, 0.24, w, V(2.62, 0.55, 0), 0.04);
  m.bevel('chrome', 0.12, 0.2, w, V(-2.66, 0.55, 0), 0.04);
  m.bevel('dark', 0.03, 0.28, 1.0, V(2.66, 0.82, 0), 0.02);
  lights(m, 2.62, -2.64, 0.92, w);
  mirrors(m, 1.2, 1.25, w);
  for (const x of [-1.65, 1.65]) for (const z of [-0.84, 0.84]) wheel(m, x, z, 0.4, 0.26);
  return m;
}

export function car_van() {
  const m = new Model('car_van');
  const w = 1.95;
  shell(m, 'body', [[-2.5, 0.4], [-2.55, 2.15], [-2.4, 2.25], [1.2, 2.25], [2.2, 1.35], [2.45, 1.05], [2.5, 0.5], [2.3, 0.38], [-2.3, 0.38]], w);
  windows(m, [[1.15, 2.1], [2.05, 1.38], [2.05, 1.05], [1.15, 1.05]], w - 0.02);
  for (const s of [-1, 1]) {
    m.box('glass', 1.4, 0.55, 0.02, V(-0.2, 1.7, s * (w / 2 + 0.005)));
    m.box('dark', 0.02, 1.6, 0.02, V(0.7, 1.25, s * (w / 2 + 0.01)));   // sürgülü kapı yarığı
  }
  m.box('glass', 0.02, 0.6, w - 0.4, V(-2.56, 1.7, 0));
  m.bevel('trim', 0.12, 0.22, w, V(2.48, 0.5, 0), 0.04);
  m.bevel('trim', 0.12, 0.22, w, V(-2.55, 0.5, 0), 0.04);
  lights(m, 2.42, -2.56, 1.0, w, 3.0);
  mirrors(m, 1.55, 1.55, w);
  for (const x of [-1.6, 1.55]) for (const z of [-0.84, 0.84]) wheel(m, x, z, 0.35, 0.22);
  return m;
}

// eski, köşeli Doğu Avrupa sedanı
export function car_boxy() {
  const m = new Model('car_boxy');
  const w = 1.62;
  shell(m, 'body', [[-2.05, 0.32], [-2.08, 0.82], [-1.85, 0.92], [1.95, 0.92], [2.05, 0.85], [2.08, 0.42], [1.9, 0.3], [-1.9, 0.3]], w);
  shell(m, 'body', [[-1.2, 0.9], [-0.9, 1.38], [0.65, 1.38], [1.05, 0.9]], w - 0.06, 0.06);
  windows(m, [[-1.15, 0.94], [-0.88, 1.34], [0.62, 1.34], [1.0, 0.94]], w - 0.03);
  m.bevel('chrome', 0.1, 0.12, w + 0.04, V(2.1, 0.45, 0), 0.03);
  m.bevel('chrome', 0.1, 0.12, w + 0.04, V(-2.1, 0.45, 0), 0.03);
  m.bevel('chrome', 0.03, 0.18, 1.1, V(2.09, 0.68, 0), 0.02);
  for (const s of [-1, 1]) m.cyl('light', 0.09, 0.09, 0.04, 10, V(2.09, 0.7, s * 0.6), { rot: [0, 0, Math.PI / 2] });
  lights(m, 2.07, -2.09, 0.66, w);
  mirrors(m, 0.85, 0.98, w);
  for (const x of [-1.25, 1.3]) for (const z of [-0.72, 0.72]) wheel(m, x, z, 0.31, 0.18);
  return m;
}

export function car_bus() {
  const m = new Model('car_bus');
  const w = 2.45;
  shell(m, 'body', [[-5.5, 0.45], [-5.55, 2.95], [-5.4, 3.05], [5.4, 3.05], [5.55, 2.8], [5.55, 0.5], [5.35, 0.42], [-5.35, 0.42]], w);
  for (const s of [-1, 1]) {
    m.box('glass', 9.4, 0.85, 0.02, V(-0.3, 2.2, s * (w / 2 + 0.005)));
    for (let i = 0; i < 7; i++) m.box('dark', 0.06, 0.86, 0.025, V(-4.6 + i * 1.4, 2.2, s * (w / 2 + 0.01)));
    m.box('dark', 1.0, 1.9, 0.02, V(4.3, 1.45, s * (w / 2 + 0.01)));
  }
  m.box('glass', 0.02, 1.3, w - 0.2, V(5.56, 2.1, 0));
  m.box('glass', 0.02, 0.8, w - 0.4, V(-5.56, 2.3, 0));
  m.bevel('trim', 0.14, 0.3, w, V(5.58, 0.6, 0), 0.04);
  m.bevel('trim', 0.14, 0.3, w, V(-5.58, 0.6, 0), 0.04);
  lights(m, 5.56, -5.57, 0.9, w);
  for (const x of [-3.6, 3.4]) for (const z of [-1.08, 1.08]) wheel(m, x, z, 0.5, 0.3);
  return m;
}

export const CIVIL = { car_sedan, car_hatch, car_pickup, car_van, car_boxy, car_bus };
