// Ağaç / çalı modelleri: ez-tree (MIT, Daniel Greenheck) üreteciyle dallanan gövde + yaprak kartları,
// oyun ölçeğine (metre) indirilir ve GLB olarak assets/trees/ altına yazılır.
// Kabuk/yaprak dokuları: Poly Haven + TextureCan (CC0) — assets/trees/tex/ altına kopyalanır.
// Kullanım: cd tools/trees && npm install && node gen_trees.mjs
import { build } from 'esbuild';
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath, pathToFileURL } from 'node:url';
import { Document, NodeIO } from '@gltf-transform/core';

const HERE = path.dirname(fileURLToPath(import.meta.url));
const ROOT = path.resolve(HERE, '../..');
const OUT = path.join(ROOT, 'assets/trees');
const LIB = path.join(HERE, 'node_modules/@dgreenheck/ez-tree/src/lib');

// ---- ez-tree kaynağını doku yüklemeden paketle (node'da DOM yok)
const stub = path.join(HERE, '.tex_stub.js');
fs.writeFileSync(stub, `import * as THREE from 'three';
export function getBarkTexture() { return new THREE.Texture(); }
export function getLeafTexture() { return new THREE.Texture(); }`);
const bundle = path.join(HERE, '.eztree_bundle.mjs');
await build({
  entryPoints: [path.join(LIB, 'index.js')],
  bundle: true, format: 'esm', platform: 'node', outfile: bundle, logLevel: 'error',
  loader: { '.jpg': 'empty', '.png': 'empty' },
  plugins: [{ name: 'stub', setup(b) { b.onResolve({ filter: /\/textures$/ }, () => ({ path: stub })); } }],
});
const { Tree, TreePreset } = await import(pathToFileURL(bundle).href);

// ---- tür listesi: ad, ön ayar, hedef boy (m), kabuk, yaprak, değişiklikler
// ez-tree ölçeği büyük (gövde ~40 birim); hedef boya göre ölçeklenir.
const lite = (o, lv) => {
  // RTS kamerası için üçgen bütçesi: bölüm/segment sayısını kıs
  const b = o.branch;
  for (const k of Object.keys(b.sections)) b.sections[k] = Math.max(2, Math.round(b.sections[k] * (k === '0' ? 0.6 : 0.55)));
  for (const k of Object.keys(b.segments)) b.segments[k] = Math.max(3, Math.min(b.segments[k], k === '0' ? 9 : 5));
  if (lv !== undefined) b.levels = lv;
  return o;
};
const SPECIES = [
  // meşe — geniş taç, kalın gövde
  { id: 'oak_s', preset: 'Oak Small', h: 5.0, bark: 'oak', leaf: 'oak', tint: 0x9fb07a },
  { id: 'oak_m', preset: 'Oak Medium', h: 7.0, bark: 'oak', leaf: 'oak', tint: 0x93a86e },
  { id: 'oak_l', preset: 'Oak Large', h: 9.5, bark: 'oak', leaf: 'oak', tint: 0x8aa066 },
  // dişbudak
  { id: 'ash_s', preset: 'Ash Small', h: 4.5, bark: 'willow', leaf: 'ash', tint: 0xa8b884 },
  { id: 'ash_m', preset: 'Ash Medium', h: 7.0, bark: 'willow', leaf: 'ash', tint: 0x9cb07a },
  { id: 'ash_l', preset: 'Ash Large', h: 9.0, bark: 'oak', leaf: 'ash', tint: 0x93a872 },
  // kavak (titrek kavak) — uzun ince
  { id: 'aspen_m', preset: 'Aspen Medium', h: 8.0, bark: 'birch', leaf: 'aspen', tint: 0xb4c27e },
  { id: 'aspen_l', preset: 'Aspen Large', h: 11.0, bark: 'birch', leaf: 'aspen', tint: 0xa9ba76 },
  // huş — beyaz kabuk (gerçekte beyaz, siyah benekli), açık yeşil yaprak
  { id: 'birch_m', preset: 'Aspen Small', h: 6.5, bark: 'birch', leaf: 'aspen', tint: 0xc0cc84 },
  // söğüt — nehir kıyısı
  { id: 'willow_m', preset: 'Ash Medium', h: 6.5, bark: 'willow', leaf: 'aspen', tint: 0xa6b870, mod: (o) => { o.branch.force.strength = -0.06; o.leaves.count = Math.round(o.leaves.count * 1.3); } },
  // çam
  { id: 'pine_s', preset: 'Pine Small', h: 5.0, bark: 'pine', leaf: 'pine', tint: 0x7f9466 },
  { id: 'pine_m', preset: 'Pine Medium', h: 8.0, bark: 'pine', leaf: 'pine', tint: 0x788e60 },
  { id: 'pine_l', preset: 'Pine Large', h: 11.5, bark: 'pine', leaf: 'pine', tint: 0x71875a },
  // çalılar
  { id: 'bush_1', preset: 'Bush 1', h: 1.3, bark: 'oak', leaf: 'oak', tint: 0x93a86e, bush: true },
  { id: 'bush_2', preset: 'Bush 2', h: 1.6, bark: 'oak', leaf: 'ash', tint: 0x9cb07a, bush: true },
  { id: 'bush_3', preset: 'Bush 3', h: 1.1, bark: 'oak', leaf: 'aspen', tint: 0xa9ba76, bush: true },
];
const SEEDS = 3;

function makeTree(sp, seed, bare) {
  const t = new Tree();
  const json = JSON.parse(JSON.stringify(TreePreset[sp.preset]));
  t.options.copy(json);
  lite(t.options);
  t.options.seed = 1000 + seed * 7919 + sp.id.length * 31;
  t.options.bark.type = sp.bark;
  t.options.leaves.type = sp.leaf;
  if (sp.mod) sp.mod(t.options);
  // yaprak kartı sayısı azaltılır, kart büyütülür (aynı doluluk, daha az üçgen)
  const lk = sp.bush ? 0.4 : 0.55;
  t.options.leaves.count = Math.max(1, Math.round(t.options.leaves.count * lk));
  t.options.leaves.size *= sp.bush ? 1.35 : 1.25;
  if (sp.bush) t.options.leaves.billboard = 'double';
  if (bare) t.options.leaves.count = 0;
  t.generate();
  return t;
}

function bounds(arr) {
  let mn = [1e9, 1e9, 1e9], mx = [-1e9, -1e9, -1e9];
  for (let i = 0; i < arr.length; i += 3) for (let k = 0; k < 3; k++) { mn[k] = Math.min(mn[k], arr[i + k]); mx[k] = Math.max(mx[k], arr[i + k]); }
  return [mn, mx];
}

const io = new NodeIO();
fs.mkdirSync(OUT, { recursive: true });
const report = [];
for (const sp of SPECIES) {
  const variants = [false];
  if (!sp.bush && sp.leaf !== 'pine') variants.push(true);   // kış: yaprağı dökülmüş
  for (const bare of variants) {
    for (let s = 0; s < SEEDS; s++) {
      const t = makeTree(sp, s, bare);
      const bv = t.branches.verts;
      const lv = t.leaves.verts;
      const all = bv.concat(lv);
      const [mn, mx] = bounds(all.length ? all : [0, 0, 0]);
      // boyu hedefe ölçekle (yaprakları olmayan kış ağacında aynı ölçek: yapraklı ikizine göre)
      const ref = bare ? makeTree(sp, s, false) : t;
      const [rmn, rmx] = bounds(ref.branches.verts.concat(ref.leaves.verts));
      const k = sp.h / Math.max(0.01, rmx[1] - rmn[1]);
      const doc = new Document();
      const buf = doc.createBuffer();
      const mesh = doc.createMesh('tree');
      const add = (verts, norms, uvs, idx, matName, wind) => {
        if (!verts.length) return;
        const pos = new Float32Array(verts.length);
        for (let i = 0; i < verts.length; i += 3) { pos[i] = verts[i] * k; pos[i + 1] = verts[i + 1] * k; pos[i + 2] = verts[i + 2] * k; }
        const prim = doc.createPrimitive()
          .setAttribute('POSITION', doc.createAccessor().setType('VEC3').setArray(pos).setBuffer(buf))
          .setAttribute('TEXCOORD_0', doc.createAccessor().setType('VEC2').setArray(new Float32Array(uvs)).setBuffer(buf))
          .setIndices(doc.createAccessor().setType('SCALAR').setArray(new Uint32Array(idx)).setBuffer(buf))
          .setMaterial(doc.createMaterial(matName).setDoubleSided(matName.startsWith('leaf')));
        if (norms && norms.length === verts.length) prim.setAttribute('NORMAL', doc.createAccessor().setType('VEC3').setArray(new Float32Array(norms)).setBuffer(buf));
        // COLOR_0.r = rüzgâr/salınım ağırlığı (gövde dibi 0, uçlar 1)
        if (wind) {
          const col = new Float32Array((verts.length / 3) * 4);
          for (let i = 0; i < verts.length / 3; i++) { const w = wind[i] ?? 1; col[i * 4] = w; col[i * 4 + 1] = w; col[i * 4 + 2] = w; col[i * 4 + 3] = 1; }
          prim.setAttribute('COLOR_0', doc.createAccessor().setType('VEC4').setArray(col).setBuffer(buf));
        }
        mesh.addPrimitive(prim);
      };
      add(bv, t.branches.normals, t.branches.uvs, t.branches.indices, `bark_${sp.bark}`, t.branches.windFactor);
      add(lv, t.leaves.normals, t.leaves.uvs, t.leaves.indices, `leaf_${sp.leaf}`, null);
      doc.createScene().addChild(doc.createNode(sp.id).setMesh(mesh));
      const name = `${sp.id}${bare ? '_bare' : ''}_${s}`;
      await io.write(path.join(OUT, `${name}.glb`), doc);
      const tris = (t.branches.indices.length + t.leaves.indices.length) / 3;
      report.push({ name, tris, h: +((mx[1] - mn[1]) * k).toFixed(2), w: +(Math.max(mx[0] - mn[0], mx[2] - mn[2]) * k).toFixed(2) });
    }
  }
}

// ---- dokular
const TEX = path.join(OUT, 'tex');
fs.mkdirSync(TEX, { recursive: true });
for (const b of ['oak', 'pine', 'birch', 'willow']) for (const f of ['color', 'normal']) fs.copyFileSync(path.join(LIB, `assets/bark/${b}_${f}_1k.jpg`), path.join(TEX, `bark_${b}_${f}.jpg`));
for (const l of ['oak', 'ash', 'aspen', 'pine']) fs.copyFileSync(path.join(LIB, `assets/leaves/${l}_color.png`), path.join(TEX, `leaf_${l}.png`));
fs.copyFileSync(path.join(LIB, 'assets/bark/README.md'), path.join(TEX, 'SOURCES.md'));
fs.writeFileSync(path.join(OUT, 'index.json'), JSON.stringify(report, null, 1));
fs.rmSync(stub); fs.rmSync(bundle);
console.table(report);
