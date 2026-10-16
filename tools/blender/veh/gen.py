# Katalogdan araç üretimi: blender -b -P tools/blender/veh/gen.py -- <katalog.json> <çıktı_klasörü> [id_öneki]
# Her birim için <id>.glb + <id>.json (pivotlar, namlu ağzı). Desteklenmeyen aileler atlanır.
import sys, os, json
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
import vlib
import fam_tank
import fam_wheeled
import fam_tracked
import fam_air
import fam_ru
import fam_uav
import fam_cargo
import fam_arty

FAMS = {}
FAMS.update(fam_tank.FAMILIES)
FAMS.update(fam_wheeled.FAMILIES)
FAMS.update(fam_tracked.FAMILIES)
FAMS.update(fam_air.FAMILIES)
FAMS.update(fam_ru.FAMILIES)
FAMS.update(fam_uav.FAMILIES)
FAMS.update(fam_cargo.FAMILIES)
FAMS.update(fam_arty.FAMILIES)

argv = sys.argv[sys.argv.index("--") + 1:]
if argv[0] == "--base":
    # taban tip modelleri (roadmap 10): <taban>_<ulus>.glb, ulus başına seçili katalog biriminden (katalog
    # 'scale' gerçek boyut düzeltmesi geometriye işlenir: taban tipte oyun ölçeği uygulamaz)
    spec = json.load(open(argv[1], encoding="utf-8"))
    out = argv[2]
    here = os.path.dirname(os.path.abspath(argv[1]))
    n = 0
    for nat in ("usa", "rus"):
        units = {u["id"]: u for u in json.load(open(os.path.join(here, nat + ".json"), encoding="utf-8"))["units"]}
        for base, uid in spec.get(nat, {}).items():
            u = units.get(uid)
            if u is None or u["fam"] not in FAMS:
                print("FAIL", base, nat, uid)
                continue
            v = dict(u.get("v", {}))
            s = u.get("scale")
            if s is not None:
                sv = [float(x) for x in s] if isinstance(s, list) else [float(s)] * 3
                f0 = v.get("fit_s", [1.0, 1.0, 1.0])
                v["fit_s"] = [sv[0] * f0[0], sv[2] * f0[1], sv[1] * f0[2]]   # katalog ölçeği Godot (x,y,z) → Blender (x,-z,y)
            vlib.reset(nat)
            try:
                pivots, meta = FAMS[u["fam"]](v)
                pivots = {**vlib.EXTRA_PIVOTS, **pivots}
                pivots, meta = vlib.apply_fit(v, pivots, meta)
            except Exception as ex:
                import traceback; traceback.print_exc()
                print("FAIL", base, nat, ex)
                continue
            vlib.export(os.path.join(out, "%s_%s.glb" % (base, nat)), pivots, meta)
            n += 1
    print("GEN DONE", n)
    sys.exit(0)
cat = json.load(open(argv[0], encoding="utf-8"))
out = argv[1]
pref = argv[2] if len(argv) > 2 else ""
n = 0
only = set(argv[3].split(",")) if len(argv) > 3 and argv[3] else None
# GEN_IDS ortam değişkeni: yalnız bu birimler (virgüllü) — boyut düzeltmesinde kısmi yeniden üretim
ids = set(x for x in os.environ.get("GEN_IDS", "").split(",") if x)
for u in cat["units"]:
    if not u["id"].startswith(pref) or u["fam"] not in FAMS:
        continue
    if only and u["fam"] not in only:
        continue
    if ids and u["id"] not in ids:
        continue
    vlib.reset(cat["nation"])
    try:
        pivots, meta = FAMS[u["fam"]](u.get("v", {}))
        pivots = {**vlib.EXTRA_PIVOTS, **pivots}
        pivots, meta = vlib.apply_fit(u.get("v", {}), pivots, meta)
    except Exception as ex:
        import traceback; traceback.print_exc()
        print("FAIL", u["id"], ex)
        continue
    vlib.export(os.path.join(out, u["id"] + ".glb"), pivots, meta)
    n += 1
print("GEN DONE", n)
