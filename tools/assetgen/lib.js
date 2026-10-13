// Mogefe varlık üreteci: ortak yardımcılar.
// - Model: parçalar three.js ile kurulur, malzeme adına göre birleştirilir, GLB olarak yazılır.
// - Doku: kodla üretilen RGBA piksel dizileri PNG olarak yazılır (zlib, Node yerleşik).
import * as THREE from 'three';
import { writeFileSync, mkdirSync } from 'node:fs';
import { dirname } from 'node:path';
import { deflateSync } from 'node:zlib';

// ---------------- rastgelelik ve gürültü ----------------

export function rng(seed = 1) {
  let s = seed >>> 0 || 1;
  return () => {
    s ^= s << 13; s >>>= 0;
    s ^= s >> 17;
    s ^= s << 5; s >>>= 0;
    return s / 4294967296;
  };
}

// Döşenebilir (tileable) değer gürültüsü: period hücrede bir tekrar eder.
export function makeNoise(seed, period) {
  const r = rng(seed);
  const g = new Float32Array(period * period);
  for (let i = 0; i < g.length; i++) g[i] = r();
  const at = (x, y) => g[((y % period + period) % period) * period + ((x % period + period) % period)];
  const sm = (t) => t * t * (3 - 2 * t);
  return (x, y) => {
    const xi = Math.floor(x), yi = Math.floor(y);
    const fx = sm(x - xi), fy = sm(y - yi);
    const a = at(xi, yi), b = at(xi + 1, yi), c = at(xi, yi + 1), d = at(xi + 1, yi + 1);
    return a + (b - a) * fx + (c - a) * fy + (a - b - c + d) * fx * fy;
  };
}

// Döşenebilir fBm: u,v ∈ [0,1)
export function fbm(seed, base = 4, oct = 4) {
  const layers = [];
  for (let o = 0; o < oct; o++) layers.push({ n: makeNoise(seed + o * 101, base << o), f: base << o, a: 1 / (1 << o) });
  const norm = layers.reduce((s, l) => s + l.a, 0);
  return (u, v) => layers.reduce((s, l) => s + l.n(u * l.f, v * l.f) * l.a, 0) / norm;
}

// ---------------- PNG ----------------

const CRC = (() => {
  const t = new Uint32Array(256);
  for (let n = 0; n < 256; n++) { let c = n; for (let k = 0; k < 8; k++) c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1; t[n] = c >>> 0; }
  return t;
})();
function crc32(buf) { let c = 0xffffffff; for (const b of buf) c = CRC[(c ^ b) & 255] ^ (c >>> 8); return (c ^ 0xffffffff) >>> 0; }
function chunk(type, data) {
  const len = Buffer.alloc(4); len.writeUInt32BE(data.length);
  const td = Buffer.concat([Buffer.from(type, 'ascii'), data]);
  const crc = Buffer.alloc(4); crc.writeUInt32BE(crc32(td));
  return Buffer.concat([len, td, crc]);
}
export function writePNG(path, w, h, rgba) {
  const raw = Buffer.alloc((w * 4 + 1) * h);
  for (let y = 0; y < h; y++) {
    raw[y * (w * 4 + 1)] = 0;
    for (let i = 0; i < w * 4; i++) raw[y * (w * 4 + 1) + 1 + i] = rgba[y * w * 4 + i];
  }
  const ihdr = Buffer.alloc(13);
  ihdr.writeUInt32BE(w, 0); ihdr.writeUInt32BE(h, 4); ihdr[8] = 8; ihdr[9] = 6; ihdr[10] = 0; ihdr[11] = 0; ihdr[12] = 0;
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, Buffer.concat([Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]), chunk('IHDR', ihdr),
    chunk('IDAT', deflateSync(raw, { level: 9 })), chunk('IEND', Buffer.alloc(0))]));
}

// Doku tuvali: fn(x, y) → [r,g,b,a] (0..1)
export function texture(path, size, fn) {
  const px = new Uint8Array(size * size * 4);
  for (let y = 0; y < size; y++) for (let x = 0; x < size; x++) {
    const c = fn(x, y);
    const i = (y * size + x) * 4;
    for (let k = 0; k < 4; k++) px[i + k] = Math.max(0, Math.min(255, Math.round((c[k] ?? 1) * 255)));
  }
  writePNG(path, size, size, px);
}

// ---------------- model kurma ----------------

// Bir model: malzeme adı → parça listesi. Her parça: geometri + dünya dönüşümü + uv kipi + renk çarpanı.
export class Model {
  constructor(name) { this.name = name; this.parts = []; this.node = 'body'; this.pivots = { body: [0, 0, 0] }; }

  // Bundan sonra eklenen parçalar ayrı bir düğüme (eklem) gider; pivot düğümün dönme noktası.
  group(name, pivot = [0, 0, 0]) { this.node = name; this.pivots[name] = pivot; return this; }

  // geo: BufferGeometry. o: {pos, rot, scale, uv: 'box'|'own', uvScale, tint: [r,g,b], ao}
  add(mat, geo, o = {}) {
    const m = new THREE.Matrix4();
    const q = new THREE.Quaternion().setFromEuler(new THREE.Euler(...(o.rot ?? [0, 0, 0]), 'YXZ'));
    m.compose(new THREE.Vector3(...(o.pos ?? [0, 0, 0])), q, new THREE.Vector3(...(o.scale ?? [1, 1, 1])));
    if (o.matrix) m.premultiply(o.matrix);
    this.parts.push({ mat, geo, m, uv: o.uv ?? 'box', uvScale: o.uvScale ?? 0.5, tint: o.tint ?? [1, 1, 1], ao: o.ao ?? true, node: this.node });
    return this;
  }

  box(mat, w, h, d, pos, o = {}) { return this.add(mat, new THREE.BoxGeometry(w, h, d), { ...o, pos }); }
  cyl(mat, rt, rb, h, seg, pos, o = {}) { return this.add(mat, new THREE.CylinderGeometry(rt, rb, h, seg, 1, false), { ...o, pos }); }
  sphere(mat, r, pos, o = {}) { return this.add(mat, new THREE.IcosahedronGeometry(r, o.detail ?? 0), { ...o, pos }); }

  // Beşik (iki yana eğimli) çatı: genişlik w (x), derinlik d (z), yükseklik h, saçak taşması over.
  // Çatı kiremit dokusu sıraları saçağa paralel gider; mahya kiremidi eklenir.
  gable(mat, w, d, h, y, o = {}) {
    const over = o.over ?? 0.35, cx = o.x ?? 0, cz = o.z ?? 0, rotY = o.rotY ?? 0;
    const hw = w / 2 + over, hd = d / 2 + over;
    const slope = Math.hypot(hw, h);
    const thick = o.thick ?? 0.12;
    const g = new THREE.BufferGeometry();
    // iki eğik yüz (üst), iki üçgen alın (gable) ayrı malzemede, alt yüzler
    const P = [], U = [];
    const quad = (a, b, c, d, ua, ub, uc, ud) => { P.push(...a, ...b, ...c, ...a, ...c, ...d); U.push(...ua, ...ub, ...uc, ...ua, ...uc, ...ud); };
    const top = [0, h, 0];
    // sol eğim (-x)
    quad([-hw, -thick, hd], [0, h, hd], [0, h, -hd], [-hw, -thick, -hd], [0, slope], [0, 0], [2 * hd, 0], [2 * hd, slope]);
    // sağ eğim (+x)
    quad([hw, -thick, -hd], [0, h, -hd], [0, h, hd], [hw, -thick, hd], [0, slope], [0, 0], [2 * hd, 0], [2 * hd, slope]);
    // saçak altı
    quad([-hw, -thick, -hd], [hw, -thick, -hd], [hw, -thick, hd], [-hw, -thick, hd], [0, 0], [1, 0], [1, 1], [0, 1]);
    g.setAttribute('position', new THREE.Float32BufferAttribute(P, 3));
    g.setAttribute('uv', new THREE.Float32BufferAttribute(U.map((v) => v * (o.uvScale ?? 0.45)), 2));
    this.add(mat, g, { pos: [cx, y, cz], rot: [0, rotY, 0], uv: 'own', tint: o.tint });
    // alınlar (duvar malzemesi)
    if (o.gableMat) {
      const t = new THREE.BufferGeometry();
      const iw = w / 2;
      const yr = h * (1 - iw / hw) - 0.02;   // duvar hizasında çatının yüksekliği
      const z1 = d / 2, z0 = -d / 2;
      t.setAttribute('position', new THREE.Float32BufferAttribute([
        -iw, 0, z1, iw, 0, z1, iw, yr, z1, -iw, 0, z1, iw, yr, z1, 0, h, z1, -iw, 0, z1, 0, h, z1, -iw, yr, z1,
        iw, 0, z0, -iw, 0, z0, -iw, yr, z0, iw, 0, z0, -iw, yr, z0, 0, h, z0, iw, 0, z0, 0, h, z0, iw, yr, z0], 3));
      this.add(o.gableMat, t, { pos: [cx, y, cz], rot: [0, rotY, 0] });
    }
    // mahya
    if (o.ridge !== false) this.add(o.ridgeMat ?? mat, new THREE.CylinderGeometry(0.14, 0.14, 2 * hd + 0.05, 6), { pos: [cx, y + h + 0.02, cz], rot: [Math.PI / 2, rotY, 0], tint: [0.8, 0.8, 0.8] });
    return this;
  }

  // Kırma / piramit çatı: taban w×d, tepe genişliği (ridge) 0 → piramit
  hip(mat, w, d, h, y, o = {}) {
    const over = o.over ?? 0.35, cx = o.x ?? 0, cz = o.z ?? 0;
    const hw = w / 2 + over, hd = d / 2 + over;
    const r = Math.max(0, (o.ridge ?? 0) / 2);
    const t = -(o.thick ?? 0.12);
    const P = [], U = [];
    const s = o.uvScale ?? 0.45;
    const tri = (a, b, c, ua, ub, uc) => { P.push(...a, ...b, ...c); U.push(...ua, ...ub, ...uc); };
    const quad = (a, b, c, d, ua, ub, uc, ud) => { tri(a, b, c, ua, ub, uc); tri(a, c, d, ua, uc, ud); };
    const sl = Math.hypot(hd, h), slx = Math.hypot(hw, h);
    // ön (+z), arka (-z): yamuk; yanlar üçgen
    quad([-hw, t, hd], [hw, t, hd], [r, h, 0], [-r, h, 0], [0, sl], [2 * hw, sl], [hw + r, 0], [hw - r, 0]);
    quad([hw, t, -hd], [-hw, t, -hd], [-r, h, 0], [r, h, 0], [0, sl], [2 * hw, sl], [hw + r, 0], [hw - r, 0]);
    tri([hw, t, hd], [hw, t, -hd], [r, h, 0], [0, slx], [2 * hd, slx], [hd, 0]);
    tri([-hw, t, -hd], [-hw, t, hd], [-r, h, 0], [0, slx], [2 * hd, slx], [hd, 0]);
    quad([-hw, t, -hd], [hw, t, -hd], [hw, t, hd], [-hw, t, hd], [0, 0], [1, 0], [1, 1], [0, 1]);
    const g = new THREE.BufferGeometry();
    g.setAttribute('position', new THREE.Float32BufferAttribute(P, 3));
    g.setAttribute('uv', new THREE.Float32BufferAttribute(U.map((v) => v * s), 2));
    this.add(mat, g, { pos: [cx, y, cz], rot: [0, o.rotY ?? 0, 0], uv: 'own', tint: o.tint });
    return this;
  }

  // Koni çatı (kule): r taban yarıçapı
  cone(mat, r, h, seg, pos, o = {}) {
    const g = new THREE.ConeGeometry(r, h, seg, 1, true);
    // uv: çevre boyunca u, eğim boyunca v (kiremit sıraları yatay)
    const p = g.attributes.position, uv = g.attributes.uv;
    for (let i = 0; i < p.count; i++) uv.setXY(i, uv.getX(i) * 2 * Math.PI * r * 0.45, (1 - uv.getY(i)) * Math.hypot(r, h) * 0.45);
    return this.add(mat, g, { ...o, pos, uv: 'own' });
  }

  // Ahşap iskelet (yarı kerpiç): bir duvar yüzüne kirişler. face: 'z+'|'z-'|'x+'|'x-'
  timberFrame(mat, w, h, y0, plane, face, o = {}) {
    const t = o.t ?? 0.14, out = o.out ?? 0.05;
    const n = Math.max(2, Math.round(w / (o.spacing ?? 1.1)));
    const put = (bw, bh, x, yy, rot = 0) => {
      let pos, ry = 0;
      if (face === 'z+') pos = [x, yy, plane + out];
      if (face === 'z-') pos = [x, yy, plane - out];
      if (face === 'x+') { pos = [plane + out, yy, x]; ry = Math.PI / 2; }
      if (face === 'x-') { pos = [plane - out, yy, x]; ry = Math.PI / 2; }
      this.add(mat, new THREE.BoxGeometry(bw, bh, t), { pos, rot: [0, ry, rot] });
    };
    put(w + t, t, 0, y0 + t / 2);
    put(w + t, t, 0, y0 + h - t / 2);
    for (let i = 0; i <= n; i++) put(t, h, -w / 2 + (w * i) / n, y0 + h / 2);
    if (o.braces !== false) {
      const cw = w / n, ang = Math.atan2(h, cw);
      for (let i = 0; i < n; i += 2) put(Math.hypot(cw, h) * 0.98, t * 0.8, -w / 2 + cw * (i + 0.5), y0 + h / 2, (i / 2) % 2 ? ang : -ang);
    }
    return this;
  }

  // Pencere: koyu boşluk + çerçeve + kanatlar. face yönüne bakar.
  window(x, y, z, face, o = {}) {
    const w = o.w ?? 0.5, h = o.h ?? 0.65;
    const ry = { 'z+': 0, 'z-': Math.PI, 'x+': Math.PI / 2, 'x-': -Math.PI / 2 }[face];
    const m = new THREE.Matrix4().makeRotationY(ry).setPosition(x, y, z);
    this.add('dark', new THREE.BoxGeometry(w, h, 0.08), { matrix: m, pos: [0, 0, 0.02] });
    this.add(o.frame ?? 'timber', new THREE.BoxGeometry(w + 0.14, 0.08, 0.12), { matrix: m, pos: [0, -h / 2 - 0.02, 0.04] });
    this.add(o.frame ?? 'timber', new THREE.BoxGeometry(w + 0.14, 0.08, 0.12), { matrix: m, pos: [0, h / 2 + 0.02, 0.04] });
    if (o.shutters !== false) {
      this.add('planks', new THREE.BoxGeometry(w * 0.5, h, 0.05), { matrix: m, pos: [-w * 0.78, 0, 0.06], tint: o.shutterTint ?? [0.7, 0.5, 0.35] });
      this.add('planks', new THREE.BoxGeometry(w * 0.5, h, 0.05), { matrix: m, pos: [w * 0.78, 0, 0.06], tint: o.shutterTint ?? [0.7, 0.5, 0.35] });
    }
    return this;
  }

  // Kemerli kapı
  door(x, y, z, face, o = {}) {
    const w = o.w ?? 0.9, h = o.h ?? 1.5;
    const ry = { 'z+': 0, 'z-': Math.PI, 'x+': Math.PI / 2, 'x-': -Math.PI / 2 }[face];
    const m = new THREE.Matrix4().makeRotationY(ry).setPosition(x, y, z);
    this.add('planks', new THREE.BoxGeometry(w, h, 0.08), { matrix: m, pos: [0, h / 2, 0.02], tint: [0.55, 0.38, 0.25] });
    this.add('planks', new THREE.CylinderGeometry(w / 2, w / 2, 0.08, 10, 1, false, 0, Math.PI), { matrix: m, pos: [0, h, 0.02], rot: [Math.PI / 2, 0, -Math.PI / 2], tint: [0.55, 0.38, 0.25] });
    this.add(o.frame ?? 'stone', new THREE.BoxGeometry(w + 0.3, 0.16, 0.16), { matrix: m, pos: [0, 0.05, 0.08] });
    this.add('metal', new THREE.BoxGeometry(w * 0.9, 0.05, 0.03), { matrix: m, pos: [0, h * 0.35, 0.07] });
    this.add('metal', new THREE.BoxGeometry(w * 0.9, 0.05, 0.03), { matrix: m, pos: [0, h * 0.75, 0.07] });
    return this;
  }

  // Mazgallı duvar tepesi: dikdörtgenin kenarları boyunca dişler
  crenels(mat, w, d, y, o = {}) {
    const s = o.size ?? 0.42, gap = o.gap ?? 0.42;
    const edge = (len, f) => { const n = Math.floor(len / (s + gap)); for (let i = 0; i < n; i++) f(-len / 2 + (s + gap) * (i + 0.5)); };
    edge(w, (x) => { this.box(mat, s, s * 1.1, s, [x, y + s * 0.55, d / 2 - s / 2]); this.box(mat, s, s * 1.1, s, [x, y + s * 0.55, -d / 2 + s / 2]); });
    edge(d, (z) => { this.box(mat, s, s * 1.1, s, [w / 2 - s / 2, y + s * 0.55, z]); this.box(mat, s, s * 1.1, s, [-w / 2 + s / 2, y + s * 0.55, z]); });
    return this;
  }

  // Yuvarlak kule mazgalı
  crenelRing(mat, r, y, n, pos) {
    for (let i = 0; i < n; i++) {
      const a = (i / n) * Math.PI * 2;
      this.box(mat, 0.38, 0.45, 0.32, [pos[0] + Math.cos(a) * r, y + 0.22, pos[2] + Math.sin(a) * r], { rot: [0, -a, 0] });
    }
    return this;
  }

  barrel(x, z, o = {}) {
    const g = new THREE.CylinderGeometry(0.26, 0.26, 0.6, 9);
    const p = g.attributes.position;
    for (let i = 0; i < p.count; i++) { const k = 1 + 0.18 * (1 - (p.getY(i) / 0.3) ** 2); p.setX(i, p.getX(i) * k); p.setZ(i, p.getZ(i) * k); }
    this.add('planks', g, { pos: [x, (o.y ?? 0) + 0.3, z], tint: [0.75, 0.55, 0.38] });
    this.cyl('metal', 0.3, 0.3, 0.05, 9, [x, (o.y ?? 0) + 0.15, z]);
    this.cyl('metal', 0.3, 0.3, 0.05, 9, [x, (o.y ?? 0) + 0.45, z]);
    return this;
  }

  crate(x, z, s = 0.5, o = {}) {
    this.box('planks', s, s, s, [x, (o.y ?? 0) + s / 2, z], { rot: [0, o.r ?? 0, 0], tint: [0.85, 0.65, 0.45] });
    return this;
  }

  // ---- GLB'ye yaz ----
  write(path) {
    const nodes = new Map();   // düğüm → (malzeme → geometriler)
    for (const part of this.parts) {
      let g = part.geo.index ? part.geo.toNonIndexed() : part.geo.clone();
      g.applyMatrix4(part.m);
      const pv = this.pivots[part.node] ?? [0, 0, 0];
      if (!g.attributes.uv || part.uv === 'box') boxUV(g, part.uvScale);
      g.computeVertexNormals();
      // tepe noktası rengi: parça tonu × zemine yakın hafif karartma (ortam gölgesi)
      const n = g.attributes.position.count;
      const col = new Float32Array(n * 3);
      for (let i = 0; i < n; i++) {
        const y = g.attributes.position.getY(i);
        const ao = part.ao ? 0.72 + 0.28 * Math.min(1, Math.max(0, y / 1.6)) : 1;
        col[i * 3] = part.tint[0] * ao; col[i * 3 + 1] = part.tint[1] * ao; col[i * 3 + 2] = part.tint[2] * ao;
      }
      g.setAttribute('color', new THREE.BufferAttribute(col, 3));
      g.translate(-pv[0], -pv[1], -pv[2]);
      if (!nodes.has(part.node)) nodes.set(part.node, new Map());
      const groups = nodes.get(part.node);
      if (!groups.has(part.mat)) groups.set(part.mat, []);
      groups.get(part.mat).push(g);
    }
    writeGLB(path, this.name, nodes, this.pivots);
  }
}

// Dünya ölçekli kutu izdüşümü uv'si: yüz normalinin baskın eksenine göre
function boxUV(g, s) {
  const p = g.attributes.position;
  const uv = new Float32Array(p.count * 2);
  const a = new THREE.Vector3(), b = new THREE.Vector3(), c = new THREE.Vector3(), nrm = new THREE.Vector3();
  for (let i = 0; i < p.count; i += 3) {
    a.fromBufferAttribute(p, i); b.fromBufferAttribute(p, i + 1); c.fromBufferAttribute(p, i + 2);
    nrm.subVectors(c, b).cross(new THREE.Vector3().subVectors(a, b)).normalize();
    const ax = Math.abs(nrm.x), ay = Math.abs(nrm.y), az = Math.abs(nrm.z);
    for (let k = 0; k < 3; k++) {
      const v = [a, b, c][k];
      let u, w;
      if (ay >= ax && ay >= az) { u = v.x; w = v.z; }
      else if (ax >= az) { u = v.z; w = -v.y; }
      else { u = v.x; w = -v.y; }
      uv[(i + k) * 2] = u * s; uv[(i + k) * 2 + 1] = w * s;
    }
  }
  g.setAttribute('uv', new THREE.BufferAttribute(uv, 2));
}

// ---------------- GLB yazıcı ----------------

function writeGLB(path, name, nodeMap, pivots) {
  const bins = [];
  let offset = 0;
  const bufferViews = [], accessors = [], materials = [], meshes = [], gnodes = [];
  const matIndex = new Map();
  const push = (arr, type, comps, minmax) => {
    const buf = Buffer.from(arr.buffer, arr.byteOffset, arr.byteLength);
    const pad = (4 - (buf.length % 4)) % 4;
    bufferViews.push({ buffer: 0, byteOffset: offset, byteLength: buf.length });
    bins.push(buf, Buffer.alloc(pad));
    offset += buf.length + pad;
    const acc = { bufferView: bufferViews.length - 1, componentType: 5126, count: arr.length / comps, type };
    if (minmax) Object.assign(acc, minmax);
    accessors.push(acc);
    return accessors.length - 1;
  };
  for (const [node, groups] of nodeMap) {
  const primitives = [];
  for (const [mat, list] of groups) {
    const merge = (attr, comps) => {
      const total = list.reduce((s, g) => s + g.attributes[attr].count * comps, 0);
      const out = new Float32Array(total);
      let o = 0;
      for (const g of list) { const a = g.attributes[attr]; for (let i = 0; i < a.count; i++) for (let k = 0; k < comps; k++) out[o++] = a.array[i * a.itemSize + k]; }
      return out;
    };
    const pos = merge('position', 3);
    const min = [Infinity, Infinity, Infinity], max = [-Infinity, -Infinity, -Infinity];
    for (let i = 0; i < pos.length; i += 3) for (let k = 0; k < 3; k++) { min[k] = Math.min(min[k], pos[i + k]); max[k] = Math.max(max[k], pos[i + k]); }
    const attributes = {
      POSITION: push(pos, 'VEC3', 3, { min, max }),
      NORMAL: push(merge('normal', 3), 'VEC3', 3),
      TEXCOORD_0: push(merge('uv', 2), 'VEC2', 2),
      COLOR_0: push(merge('color', 3), 'VEC3', 3),
    };
    if (!matIndex.has(mat)) { materials.push({ name: mat, pbrMetallicRoughness: { baseColorFactor: [1, 1, 1, 1], metallicFactor: 0, roughnessFactor: 0.9 } }); matIndex.set(mat, materials.length - 1); }
    primitives.push({ attributes, material: matIndex.get(mat), mode: 4 });
  }
  meshes.push({ name: node, primitives });
  gnodes.push({ name: node, mesh: meshes.length - 1, translation: pivots[node] ?? [0, 0, 0] });
  }
  const json = {
    asset: { version: '2.0', generator: 'mogefe-assetgen' },
    scene: 0, scenes: [{ nodes: gnodes.map((_, i) => i) }], nodes: gnodes,
    meshes, materials, accessors, bufferViews, buffers: [{ byteLength: offset }],
  };
  let js = Buffer.from(JSON.stringify(json), 'utf8');
  js = Buffer.concat([js, Buffer.alloc((4 - (js.length % 4)) % 4, 0x20)]);
  const bin = Buffer.concat(bins);
  const header = Buffer.alloc(12);
  header.writeUInt32LE(0x46546c67, 0); header.writeUInt32LE(2, 4); header.writeUInt32LE(12 + 8 + js.length + 8 + bin.length, 8);
  const jh = Buffer.alloc(8); jh.writeUInt32LE(js.length, 0); jh.writeUInt32LE(0x4e4f534a, 4);
  const bh = Buffer.alloc(8); bh.writeUInt32LE(bin.length, 0); bh.writeUInt32LE(0x004e4942, 4);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, Buffer.concat([header, jh, js, bh, bin]));
}

export { THREE };
