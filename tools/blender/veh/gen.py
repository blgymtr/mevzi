# Katalogdan araç üretimi: blender -b -P tools/blender/veh/gen.py -- <katalog.json> <çıktı_klasörü> [id_öneki]
# Her birim için <id>.glb + <id>.json (pivotlar, namlu ağzı). Desteklenmeyen aileler atlanır.
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vlib
import fam_tank
import fam_wheeled
import fam_tracked
import fam_air

FAMS = {}
FAMS.update(fam_tank.FAMILIES)
FAMS.update(fam_wheeled.FAMILIES)
FAMS.update(fam_tracked.FAMILIES)
FAMS.update(fam_air.FAMILIES)

argv = sys.argv[sys.argv.index("--") + 1:]
cat = json.load(open(argv[0], encoding="utf-8"))
out = argv[1]
pref = argv[2] if len(argv) > 2 else ""
n = 0
only = set(argv[3].split(",")) if len(argv) > 3 else None
for u in cat["units"]:
    if not u["id"].startswith(pref) or u["fam"] not in FAMS:
        continue
    if only and u["fam"] not in only:
        continue
    vlib.reset(cat["nation"])
    try:
        pivots, meta = FAMS[u["fam"]](u.get("v", {}))
    except Exception as ex:
        import traceback; traceback.print_exc()
        print("FAIL", u["id"], ex)
        continue
    vlib.export(os.path.join(out, u["id"] + ".glb"), pivots, meta)
    n += 1
print("GEN DONE", n)
