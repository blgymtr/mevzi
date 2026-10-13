// Poly Haven CC0 dokularını indirir (2k jpg): renk, normal (GL), pürüzlülük.
// Kullanım: node tools/fetch_textures.cjs
const fs = require('fs'), path = require('path');
const ROOT = path.join(__dirname, '..', 'assets', 'textures');
const TEX = ['aerial_sand', 'aerial_beach_01', 'aerial_grass_rock', 'grass_path_2', 'forest_ground_04', 'aerial_mud_1',
  'brown_mud_dry', 'dirt_aerial_02', 'snow_field_aerial', 'snow_02', 'burned_ground_01', 'rocky_terrain', 'gravel_road',
  'dry_ground_01', 'leaves_forest_ground'];
async function get(url) { for (let i = 0; i < 4; i++) { try { const r = await fetch(url); if (!r.ok) throw new Error(r.status + ' ' + url); return Buffer.from(await r.arrayBuffer()); } catch (e) { if (i === 3) throw e; await new Promise(r => setTimeout(r, 1500)); } } }
async function save(url, file) { if (fs.existsSync(file) && fs.statSync(file).size > 0) return; fs.mkdirSync(path.dirname(file), { recursive: true }); fs.writeFileSync(file, await get(url)); }
(async () => {
  for (const id of TEX) {
    const f = JSON.parse(await get('https://api.polyhaven.com/files/' + id));
    const pick = (keys) => { for (const k of keys) if (f[k] && f[k]['2k'] && f[k]['2k'].jpg) return f[k]['2k'].jpg.url; return null; };
    const maps = { albedo: pick(['Diffuse', 'diff']), normal: pick(['nor_gl']), rough: pick(['Rough', 'rough']) };
    for (const [k, u] of Object.entries(maps)) if (u) await save(u, path.join(ROOT, id, k + '.jpg'));
    console.log('tex', id, Object.keys(maps).filter(k => maps[k]).join(','));
  }
  fs.writeFileSync(path.join(ROOT, 'CREDITS.txt'), 'Poly Haven (polyhaven.com) — CC0:\n' + TEX.join('\n') + '\n');
})();
