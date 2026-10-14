// Kullanım: node gen.js [all|textures|models]
// Çıktı: ../../assets/gen/*.png (dokular), ../../assets/models/*.glb + *.json (pivot/meta)
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { existsSync, writeFileSync, mkdirSync } from 'node:fs';
import { buildTextures } from './textures.js';
import { VEHICLES } from './vehicles.js';
import { SOLDIERS } from './soldiers.js';
import { VEHICLES2 } from './vehicles2.js';
import { ARMOR } from './armor.js';
import { ARMOR2 } from './armor2.js';
import { AIR } from './air.js';
import { ARTILLERY } from './artillery.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..', '..', 'assets');
const only = process.argv[2] ?? 'all';
const t0 = Date.now();
if (only === 'all' || only === 'textures') {
  const out = join(root, 'gen');
  mkdirSync(out, { recursive: true });
  buildTextures(out);
  console.log(`dokular: ${((Date.now() - t0) / 1000).toFixed(1)} sn`);
}
if (only === 'all' || only === 'models') {
  const all = { ...VEHICLES, ...VEHICLES2, ...SOLDIERS, ...ARMOR, ...ARMOR2, ...AIR, ...ARTILLERY };
  const pick = process.argv[3];
  if (pick) for (const k of Object.keys(all)) if (!k.startsWith(pick)) delete all[k];
  for (const [name, fn] of Object.entries(all)) {
    const m = fn();
    const path = join(root, 'models', `${name}.glb`);
    m.write(path);
    writeFileSync(join(root, 'models', `${name}.json`), JSON.stringify({ pivots: m.pivots, meta: m.meta ?? {} }));
    if (!existsSync(path + '.import')) writeFileSync(path + '.import', `[remap]\n\nimporter="scene"\nimporter_version=1\ntype="PackedScene"\n\n[deps]\n\nsource_file="res://assets/models/${name}.glb"\n\n[params]\n\nnodes/root_type=""\nmeshes/ensure_tangents=true\nmeshes/generate_lods=false\nmeshes/create_shadow_meshes=false\nmeshes/light_baking=1\nmeshes/force_disable_compression=true\n`);
  }
  console.log(`modeller: ${Object.keys(all).length}`);
}
