// Poly Haven CC0 modelleri (roadmap 121): 1k glTF (gltf + bin + dokular) → tools/assets_src/polyhaven/<id>/
// (git dışı ham kaynak; Blender hattı tools/blender/props.py azaltıp assets/props/<id>.glb üretir).
// Kullanım: node tools/fetch_models.cjs [id ...]   (id verilmezse PROPS listesi)
const fs = require('fs'), path = require('path');
const SRC = path.join(__dirname, 'assets_src', 'polyhaven');
const PROPS = [
  // siper / ikmal / sandık (120, 106)
  'wooden_military_crate', 'old_military_crate', 'ammo_box', 'metal_jerrycan', 'metal_jerrycan_green', 'plastic_jerrycan',
  'medical_box', 'wooden_crate_01', 'wooden_crate_02', 'plastic_crate_01', 'Barrel_01', 'Barrel_02', 'barrel_03',
  'propane_tank', 'old_military_compressor', 'portable_generator',
  // yol / şehir siperi
  'concrete_road_barrier', 'concrete_road_barrier_02', 'utility_box_01', 'street_lamp_01', 'fire_hydrant',
  // hurda / sivil
  'covered_car', 'old_tyre', 'rusted_wheel_rim_01', 'hand_truck', 'cardboard_box_01',
  // doğa
  'tree_stump_01', 'dead_tree_trunk_02',
];
async function get(url) { for (let i = 0; i < 4; i++) { try { const r = await fetch(url); if (!r.ok) throw new Error(r.status + ' ' + url); return Buffer.from(await r.arrayBuffer()); } catch (e) { if (i === 3) throw e; await new Promise(r => setTimeout(r, 1500)); } } }
async function save(url, file) { if (fs.existsSync(file) && fs.statSync(file).size > 0) return; fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, await get(url)); }
(async () => {
  const ids = process.argv.length > 2 ? process.argv.slice(2) : PROPS;
  for (const id of ids) {
    try {
      const f = JSON.parse(await get('https://api.polyhaven.com/files/' + id));
      const g = f.gltf && (f.gltf['1k'] || f.gltf['2k']);
      if (!g || !g.gltf) { console.log('gltf yok', id); continue; }
      const dir = path.join(SRC, id);
      await save(g.gltf.url, path.join(dir, path.basename(new URL(g.gltf.url).pathname)));
      for (const [rel, inc] of Object.entries(g.gltf.include || {})) await save(inc.url, path.join(dir, rel));
      console.log('model', id, Object.keys(g.gltf.include || {}).length, 'ek dosya');
    } catch (e) { console.log('HATA', id, e.message); }
  }
})();
