# Poly Haven CC0 eşyaları oyuna hazırlama (roadmap 121): glTF içe al → tek nesne → azalt (RTS kamerası için
# üçgen bütçesi) → orijin taban ortası → dokular 512 px → assets/props/<id>.glb + assets/props/props.json
# (boyut, üçgen). Kullanım:
#   blender -b --factory-startup -P tools/blender/props.py -- <kaynak_kök> <çıkış_kök> [id ...]
import bpy, sys, os, json, math

argv = sys.argv[sys.argv.index("--") + 1:]
SRC, OUT = argv[0], argv[1]
IDS = argv[2:] or sorted(d for d in os.listdir(SRC) if os.path.isdir(os.path.join(SRC, d)))
TEX = 512
DEFAULT_BUDGET = 1600
BUDGET = {
    "covered_car": 5000, "modular_chainlink_fence": 2500, "street_lamp_01": 1200, "portable_generator": 2500,
    "old_military_compressor": 2500, "hand_truck": 1500, "dead_tree_trunk_02": 2500, "tree_stump_01": 1500,
    "concrete_road_barrier": 800, "concrete_road_barrier_02": 800, "old_tyre": 1000, "rusted_wheel_rim_01": 1000,
}
TMP = os.path.join(OUT, "_tex_tmp")
os.makedirs(OUT, exist_ok=True)
os.makedirs(TMP, exist_ok=True)
man_path = os.path.join(OUT, "props.json")
manifest = json.load(open(man_path, encoding="utf-8")) if os.path.exists(man_path) else {}


def tri_count(ob):
    return sum(len(p.vertices) - 2 for p in ob.data.polygons)


for pid in IDS:
    d = os.path.join(SRC, pid)
    gl = [f for f in os.listdir(d) if f.endswith(".gltf")]
    if not gl:
        print("PROPS gltf yok", pid)
        continue
    bpy.ops.wm.read_factory_settings(use_empty=True)
    bpy.ops.import_scene.gltf(filepath=os.path.join(d, gl[0]))
    # aynı dosyada birden çok varyant olabilir (old_military_crate_a / _b): en büyük parça "_a" ile bitiyor ve
    # "_b" eşi varsa yalnız "_a" (ve soneksiz) parçalar alınır; parçalı tek model (ammo_box + kulp + mandal) bütün kalır
    import re
    allm = [o for o in bpy.context.scene.objects if o.type == "MESH"]
    names = {o.name for o in allm}
    big = max(allm, key=lambda o: len(o.data.polygons)) if allm else None
    meshes = allm
    if big is not None and re.search(r"_a(\.\d+)?$", big.name) and re.sub(r"_a(\.\d+)?$", "_b", big.name) in {re.sub(r"\.\d+$", "", n) for n in names}:
        meshes = [o for o in allm if not re.search(r"_[b-z](\.\d+)?$", o.name)]
        print("PROPS %s varyant: %d / %d parça" % (pid, len(meshes), len(allm)))
    if not meshes:
        print("PROPS mesh yok", pid)
        continue
    # ebeveynden kopar (dünya dönüşümü korunur), dönüşümü uygula, birleştir
    bpy.ops.object.select_all(action="DESELECT")
    for o in meshes:
        o.select_set(True)
    bpy.context.view_layer.objects.active = meshes[0]
    bpy.ops.object.parent_clear(type="CLEAR_KEEP_TRANSFORM")
    bpy.ops.object.make_single_user(object=True, obdata=True)
    bpy.ops.object.transform_apply(location=True, rotation=True, scale=True)
    if len(meshes) > 1:
        bpy.ops.object.join()
    ob = bpy.context.view_layer.objects.active
    for o in list(bpy.context.scene.objects):
        if o != ob:
            bpy.data.objects.remove(o, do_unlink=True)
    if ob.data.shape_keys:
        ob.shape_key_clear()
    t0 = tri_count(ob)
    budget = BUDGET.get(pid, DEFAULT_BUDGET)
    if t0 > budget:
        m = ob.modifiers.new("dec", "DECIMATE")
        m.ratio = max(0.02, budget / t0)
        m.use_collapse_triangulate = True
        bpy.ops.object.modifier_apply(modifier="dec")
    t1 = tri_count(ob)
    # orijin: taban ortası (Blender Z yukarı)
    xs = [v.co.x for v in ob.data.vertices]
    ys = [v.co.y for v in ob.data.vertices]
    zs = [v.co.z for v in ob.data.vertices]
    cx, cy, z0 = (min(xs) + max(xs)) * 0.5, (min(ys) + max(ys)) * 0.5, min(zs)
    for v in ob.data.vertices:
        v.co.x -= cx
        v.co.y -= cy
        v.co.z -= z0
    dims = [max(xs) - min(xs), max(zs) - min(zs), max(ys) - min(ys)]   # Godot (x, y yukarı, z)
    # dokular: en çok 512 px, JPEG olarak geçici klasöre (dışa aktarıcı bu dosyaları gömer)
    # dokular: en çok 512 px; küçültülen kopya JPEG olarak kaydedilip yeni görüntü diye yüklenir ve tüm
    # kullanımlar ona bağlanır (içe aktarılan görüntüler paketli — yerinde kaydetmek özgün veriyi yazıyordu)
    for img in list(bpy.data.images):
        if img.size[0] == 0:
            continue
        w, h = img.size
        if max(w, h) <= TEX:
            continue
        k = TEX / max(w, h)
        cp = img.copy()
        cp.scale(max(1, int(w * k)), max(1, int(h * k)))
        # saydamlıklı doku (tel örgü vb.) PNG kalır; JPEG alfa kanalını siler
        alpha = img.channels == 4 and img.alpha_mode != "NONE" and any(img.pixels[i] < 0.99 for i in range(3, min(len(img.pixels), 4 * 65536), 4 * 37))
        p = os.path.join(TMP, "%s_%s.%s" % (pid, bpy.path.clean_name(img.name), "png" if alpha else "jpg"))
        cp.filepath_raw = p
        cp.file_format = "PNG" if alpha else "JPEG"
        cp.save()
        new = bpy.data.images.load(p)
        new.colorspace_settings.name = img.colorspace_settings.name
        img.user_remap(new)
        bpy.data.images.remove(cp)
    out = os.path.join(OUT, pid + ".glb")
    bpy.ops.export_scene.gltf(filepath=out, export_format="GLB", export_image_format="AUTO", export_yup=True)
    manifest[pid] = {"dims": [round(x, 3) for x in dims], "tris": t1, "tris_src": t0, "src": "polyhaven", "license": "CC0"}
    print("PROPS %s tris %d -> %d dims %s kb %d" % (pid, t0, t1, ["%.2f" % x for x in dims], os.path.getsize(out) // 1024))
    json.dump(manifest, open(man_path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)

json.dump(manifest, open(man_path, "w", encoding="utf-8"), indent=1, ensure_ascii=False)
for f in os.listdir(TMP):
    os.remove(os.path.join(TMP, f))
os.rmdir(TMP)
