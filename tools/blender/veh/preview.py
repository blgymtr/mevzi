# Araç önizleme: python3 preview.py -- <in.glb> <out_prefix> [yükseklik_açısı] [genişlik]
#   → <out>_a.png (ön 3/4), <out>_b.png (arka 3/4). Cycles (CPU, az örnek); köşe rengi (AO) taban rengiyle çarpılır.
import bpy, sys, math, mathutils
argv = sys.argv[sys.argv.index("--") + 1:]
bpy.ops.wm.read_factory_settings(use_empty=True)
bpy.ops.import_scene.gltf(filepath=argv[0])
EL = float(argv[2]) if len(argv) > 2 else 38.0
RES = int(argv[3]) if len(argv) > 3 else 900
cols = {"paint": (0.36, 0.33, 0.2), "trim": (0.27, 0.25, 0.16), "metal": (0.3, 0.3, 0.29), "track": (0.1, 0.1, 0.09),
        "rubber": (0.035, 0.035, 0.035), "glass": (0.03, 0.05, 0.07), "dark": (0.04, 0.04, 0.04), "light": (1, 0.95, 0.8),
        "canvas": (0.32, 0.3, 0.2), "red": (0.6, 0.05, 0.03), "mark": (0.9, 0.9, 0.9), "lens": (0.9, 0.45, 0.05),
        "gun": (0.12, 0.12, 0.12), "wood": (0.3, 0.18, 0.09)}
rough = {"glass": 0.1, "metal": 0.4, "gun": 0.45, "rubber": 0.95, "canvas": 0.95}
for m in bpy.data.materials:
    m.use_nodes = True
    nt = m.node_tree
    b = nt.nodes.get("Principled BSDF")
    if not b:
        continue
    for l in list(b.inputs["Base Color"].links):
        nt.links.remove(l)
    k = m.name.split(".")[0].split("_")[0]
    c = cols.get(k, (0.5, 0.5, 0.5))
    at = nt.nodes.new("ShaderNodeVertexColor")
    mul = nt.nodes.new("ShaderNodeMix")
    mul.data_type = 'RGBA'
    mul.blend_type = 'MULTIPLY'
    mul.inputs[0].default_value = 1.0
    mul.inputs[6].default_value = (*c, 1)
    nt.links.new(at.outputs["Color"], mul.inputs[7])
    nt.links.new(mul.outputs[2], b.inputs["Base Color"])
    b.inputs["Roughness"].default_value = rough.get(k, 0.7)
    b.inputs["Metallic"].default_value = 0.6 if k in ("metal", "gun") else (0.1 if k in ("paint", "trim") else 0.0)
    if k in ("light", "lens"):
        b.inputs["Emission Color"].default_value = (*c, 1)
        b.inputs["Emission Strength"].default_value = 2.0
# sınır kutusu
mn = mathutils.Vector((1e9, 1e9, 1e9)); mx = -mn
for o in bpy.data.objects:
    if o.type == 'MESH':
        for c in o.bound_box:
            w = o.matrix_world @ mathutils.Vector(c)
            mn = mathutils.Vector(map(min, mn, w)); mx = mathutils.Vector(map(max, mx, w))
ctr = (mn + mx) * 0.5
size = (mx - mn).length
bpy.ops.mesh.primitive_plane_add(size=200)
pm = bpy.data.materials.new("floor"); pm.use_nodes = True
pm.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.3, 0.29, 0.25, 1)
bpy.context.active_object.data.materials.append(pm)
sc = bpy.context.scene
sc.render.engine = 'CYCLES'
sc.cycles.samples = 12
sc.cycles.use_denoising = True
try:
    sc.cycles.denoiser = 'OPENIMAGEDENOISE'
except Exception:
    pass
sc.cycles.max_bounces = 3
sc.render.resolution_x = RES
sc.render.resolution_y = int(RES * 0.66)
sc.world = bpy.data.worlds.new("w")
sc.world.use_nodes = True  # (6.0'da kalkacak; şimdilik gerekli)
sc.world.node_tree.nodes["Background"].inputs[0].default_value = (0.5, 0.56, 0.62, 1)
sc.world.node_tree.nodes["Background"].inputs[1].default_value = 0.9
bpy.ops.object.light_add(type='SUN', rotation=(math.radians(45), 0, math.radians(150)))
bpy.context.active_object.data.energy = 3.5
bpy.context.active_object.data.angle = math.radians(3)
R = size * 1.45
for tag, yaw in (("a", 35), ("b", 215)):
    a = math.radians(yaw)
    e = math.radians(EL)
    loc = ctr + mathutils.Vector((math.sin(a) * math.cos(e) * R, math.cos(a) * math.cos(e) * R, math.sin(e) * R))
    bpy.ops.object.camera_add(location=loc)
    cam = bpy.context.active_object
    cam.rotation_euler = (ctr - loc).to_track_quat('-Z', 'Y').to_euler()
    cam.data.lens = 50
    sc.camera = cam
    sc.render.filepath = argv[1] + "_" + tag + ".png"
    bpy.ops.render.render(write_still=True)
print("PREVIEW OK")
