// Poly Haven CC0 malzeme dokuları (1k jpg): renk, normal (GL), pürüzlülük.
// Araç (metal, pas, branda) ve bina (sıva, tuğla, beton, kiremit, sac, ahşap) yüzeyleri.
// Kullanım: node tools/fetch_materials.cjs
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..', 'assets', 'materials');
const TEX = [
  // araç
  'rusty_painted_metal', 'metal_plate_02', 'rust_coarse_01', 'green_metal_rust', 'hessian_230', 'brown_leather',
  // bina
  'white_plaster_rough_02', 'painted_plaster_wall', 'brick_wall_02', 'concrete_wall_005', 'precast_concrete_wall',
  'roof_tiles_14', 'clay_roof_tiles_02', 'grey_roof_tiles', 'corrugated_iron_02', 'worn_corrugated_iron', 'brown_planks_05',
  'rough_plaster_brick', 'red_plaster_weathered',
];
async function get(url) { for (let i = 0; i < 4; i++) { try { const r = await fetch(url); if (!r.ok) throw new Error(r.status + ' ' + url); return Buffer.from(await r.arrayBuffer()); } catch (e) { if (i === 3) throw e; await new Promise(r => setTimeout(r, 1500)); } } }
async function save(url, file) { if (fs.existsSync(file) && fs.statSync(file).size > 0) return; fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, await get(url)); }
(async () => {
  for (const id of TEX) {
    const f = JSON.parse(await get('https://api.polyhaven.com/files/' + id));
    const pick = (keys) => { for (const k of keys) if (f[k] && f[k]['1k'] && f[k]['1k'].jpg) return f[k]['1k'].jpg.url; return null; };
    const maps = { albedo: pick(['Diffuse', 'diff']), normal: pick(['nor_gl']), rough: pick(['Rough', 'rough']) };
    for (const [k, u] of Object.entries(maps)) if (u) await save(u, path.join(ROOT, id, k + '.jpg'));
    console.log('mat', id, Object.keys(maps).filter(k => maps[k]).join(','));
  }
  fs.writeFileSync(path.join(ROOT, 'CREDITS.txt'), 'Poly Haven (polyhaven.com) — CC0 (kamu malı):\n' + TEX.join('\n') + '\n');
})();
