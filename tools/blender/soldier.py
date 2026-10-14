# Blender asker üretici (betikle, dış varlık yok).
# Kullanım: blender -b -P tools/blender/soldier.py -- <cikti.glb> <blue|red>
# Her eklem ayrı nesne; adlar ve pivotlar oyundaki iskeletle aynı:
#   torso (kalça 0.92), arm (omuz 1.42), fore (dirsek 1.13), thigh (kalça 0.92), shin (diz 0.48)
# Gövde: deri (skin) değiştiricisi + yüzey bölme ile organik; teçhizat ayrı yumuşatılmış parçalar.
# Malzeme adları oyundaki Art.material ile eşleşir (uniform, vest, pack, helmet, team, skin, boot, dark).
import bpy, bmesh, sys, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "soldier.glb"
SIDE = argv[1] if len(argv) > 1 else "blue"
BLUE = SIDE == "blue"

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}

def mat(name):
    if name not in MATS:
        m = bpy.data.materials.new(name)
        MATS[name] = m
    return MATS[name]

def skin_limb(name, pts, radii, matname, subdiv=2, smooth=True):
    """pts: [(x,y,z)...] zincir (Blender: Z yukarı), radii: [(rx,ry)...]"""
    me = bpy.data.meshes.new(name)
    bm = bmesh.new()
    vs = [bm.verts.new(p) for p in pts]
    for a, b in zip(vs, vs[1:]):
        bm.edges.new((a, b))
    bm.to_mesh(me)
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    sk = ob.modifiers.new("skin", 'SKIN')
    sk.use_smooth_shade = smooth
    for i, r in enumerate(radii):
        me.skin_vertices[0].data[i].radius = r
    me.skin_vertices[0].data[0].use_root = True
    sd = ob.modifiers.new("sub", 'SUBSURF')
    sd.levels = subdiv
    sd.render_levels = subdiv
    ob.data.materials.append(mat(matname))
    return ob

def prim(kind, name, loc, scale, matname, rot=(0, 0, 0), seg=16):
    if kind == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(6, seg // 2), location=loc)
    elif kind == "cyl":
        bpy.ops.mesh.primitive_cylinder_add(vertices=seg, location=loc)
    else:
        bpy.ops.mesh.primitive_cube_add(location=loc)
    ob = bpy.context.active_object
    ob.name = name
    ob.scale = scale
    ob.rotation_euler = rot
    if kind == "cube":
        bv = ob.modifiers.new("bev", 'BEVEL')
        bv.width = 0.012
        bv.segments = 2
    ob.data.materials.append(mat(matname))
    bpy.ops.object.shade_smooth()
    return ob

def apply_all(ob):
    bpy.context.view_layer.objects.active = ob
    for m in list(ob.modifiers):
        bpy.ops.object.modifier_apply(modifier=m.name)

def join(name, obs, pivot):
    for o in obs:
        apply_all(o)
    bpy.ops.object.select_all(action='DESELECT')
    for o in obs:
        o.select_set(True)
    bpy.context.view_layer.objects.active = obs[0]
    bpy.ops.object.join()
    ob = bpy.context.active_object
    ob.name = name
    # pivotu eklem noktasına al
    bpy.context.scene.cursor.location = pivot
    bpy.ops.object.origin_set(type='ORIGIN_CURSOR')
    bpy.ops.object.shade_smooth()
    # UV: küp izdüşümü (kamuflaj ölçeği oyundaki uv_scale ile ayarlanır) + beyaz tepe rengi
    bpy.ops.object.mode_set(mode='EDIT')
    bpy.ops.mesh.select_all(action='SELECT')
    bpy.ops.uv.cube_project(cube_size=2.5)
    bpy.ops.object.mode_set(mode='OBJECT')
    ca = ob.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
    for d in ca.data:
        d.color = (1, 1, 1, 1)
    return ob

# Blender koordinatı: X sağ, Y ileri(-Z oyunda), Z yukarı. Oyun ileri -Z => Blender +Y.
F = 1.0  # ileri yön işareti (Blender Y)

# ---------------- gövde (kalça pivotu)
parts = []
parts.append(skin_limb("torso_core", [(0, 0, 0.86), (0, 0, 1.0), (0, 0.005, 1.16), (0, 0.01, 1.32), (0, 0, 1.45), (0, 0, 1.53)],
                       [(0.16, 0.11), (0.16, 0.11), (0.15, 0.1), (0.19, 0.12), (0.18, 0.1), (0.06, 0.055)], "uniform", 2))
for sx in (-1, 1):
    parts.append(prim("sphere", "sh", (sx * 0.19, 0, 1.405), (0.078, 0.078, 0.07), "uniform"))
# yelek
if BLUE:
    parts.append(skin_limb("vest", [(0, 0, 1.1), (0, 0.01, 1.25), (0, 0.005, 1.42)], [(0.185, 0.135), (0.2, 0.14), (0.17, 0.115)], "vest", 1))
    for x in (-0.105, 0, 0.105):
        parts.append(prim("cube", "pouch", (x, 0.16, 1.17), (0.043, 0.03, 0.065), "vest"))
    parts.append(prim("cube", "radio", (0.12, 0.15, 1.35), (0.03, 0.025, 0.065), "dark"))
    parts.append(skin_limb("ruck", [(0, -0.21, 1.06), (0, -0.23, 1.3), (0, -0.21, 1.47)], [(0.15, 0.09), (0.16, 0.1), (0.12, 0.06)], "pack", 1))
    parts.append(prim("cyl", "mat", (0, -0.21, 1.52), (0.05, 0.05, 0.13), "pack", rot=(0, math.pi / 2, 0)))
else:
    parts.append(skin_limb("vest", [(0, 0, 1.06), (0, 0.01, 1.22), (0, 0, 1.42)], [(0.18, 0.13), (0.2, 0.14), (0.175, 0.12)], "vest", 1))
    for x in (-0.12, -0.04, 0.04, 0.12):
        parts.append(prim("cube", "pouch", (x, 0.155, 1.2), (0.036, 0.028, 0.07), "vest"))
    parts.append(skin_limb("pack", [(0, -0.18, 1.1), (0, -0.19, 1.32)], [(0.12, 0.07), (0.13, 0.07)], "pack", 1))
parts.append(skin_limb("belt", [(0, 0, 0.95), (0, 0, 0.99)], [(0.172, 0.12), (0.172, 0.12)], "dark", 1))
for sx in (-1, 1):
    parts.append(prim("sphere", "patch", (sx * 0.205, 0, 1.43), (0.065, 0.065, 0.05), "team"))
# boyun + baş
parts.append(skin_limb("neck", [(0, 0, 1.49), (0, 0, 1.58)], [(0.05, 0.05), (0.047, 0.05)], "skin", 1))
parts.append(prim("sphere", "head", (0, 0.005, 1.655), (0.088, 0.098, 0.106), "skin", seg=20))
parts.append(prim("sphere", "jaw", (0, 0.045, 1.6), (0.068, 0.06, 0.048), "skin"))
parts.append(prim("sphere", "nose", (0, 0.1, 1.645), (0.016, 0.02, 0.024), "skin", seg=8))
if BLUE:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=(0, -0.008, 1.66))
    h = bpy.context.active_object
    h.scale = (0.145, 0.157, 0.14)
    # alt yarıyı kes (kask)
    bm = bmesh.new(); bm.from_mesh(h.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.15], context='VERTS')
    bm.to_mesh(h.data); bm.free()
    h.data.materials.append(mat("helmet")); bpy.ops.object.shade_smooth()
    sol = h.modifiers.new("sol", 'SOLIDIFY'); sol.thickness = -0.06
    parts.append(h)
    parts.append(prim("cyl", "band", (0, -0.008, 1.7), (0.148, 0.16, 0.026), "team", seg=24))
    parts.append(prim("cube", "nvg", (0, 0.13, 1.745), (0.035, 0.018, 0.025), "dark"))
    parts.append(prim("cube", "cw", (0, -0.14, 1.7), (0.05, 0.02, 0.03), "pack"))
else:
    bpy.ops.mesh.primitive_uv_sphere_add(segments=24, ring_count=12, location=(0, 0, 1.652))
    h = bpy.context.active_object
    h.scale = (0.148, 0.155, 0.145)
    bm = bmesh.new(); bm.from_mesh(h.data)
    bmesh.ops.delete(bm, geom=[v for v in bm.verts if v.co.z < -0.1], context='VERTS')
    bm.to_mesh(h.data); bm.free()
    h.data.materials.append(mat("helmet")); bpy.ops.object.shade_smooth()
    sol = h.modifiers.new("sol", 'SOLIDIFY'); sol.thickness = -0.06
    parts.append(h)
    parts.append(prim("cyl", "band", (0, 0, 1.69), (0.152, 0.158, 0.026), "team", seg=24))
torso = join("torso", parts, (0, 0, 0.92))

# ---------------- üst kol (omuz pivotu) ve önkol (dirsek)
arm = join("arm", [skin_limb("ua", [(0, 0, 1.44), (0, 0, 1.3), (0, 0, 1.14)], [(0.066, 0.068), (0.062, 0.064), (0.052, 0.054)], "uniform", 2)], (0, 0, 1.42))
fp = [skin_limb("fa", [(0, 0, 1.15), (0, 0, 1.02), (0, 0, 0.9)], [(0.054, 0.056), (0.05, 0.052), (0.04, 0.042)], "uniform", 2),
      prim("sphere", "hand", (0, 0.008, 0.85), (0.038, 0.044, 0.052), "dark" if BLUE else "skin"),
      prim("sphere", "elbow", (0, -0.01, 1.13), (0.052, 0.05, 0.045), "uniform")]
fore = join("fore", fp, (0, 0, 1.13))

# ---------------- bacak
th = join("thigh", [skin_limb("th", [(0, 0, 0.95), (0, 0, 0.78), (0, 0, 0.6), (0, 0, 0.5)], [(0.11, 0.115), (0.104, 0.108), (0.086, 0.09), (0.076, 0.08)], "uniform", 2),
                    prim("cube", "pocket", (0.095, 0, 0.7), (0.03, 0.055, 0.07), "uniform")], (0, 0, 0.92))
sh = join("shin", [skin_limb("sh", [(0, 0, 0.5), (0, -0.01, 0.38), (0, -0.005, 0.26), (0, 0, 0.17)], [(0.076, 0.078), (0.08, 0.084), (0.066, 0.068), (0.058, 0.06)], "uniform", 2),
                   prim("sphere", "knee", (0, 0.045, 0.46), (0.06, 0.04, 0.06), "team"),
                   skin_limb("boot", [(0, 0, 0.2), (0, 0.03, 0.09), (0, 0.1, 0.035)], [(0.058, 0.062), (0.062, 0.08), (0.055, 0.06)], "boot", 2)], (0, 0, 0.48))

# --------------- dışa aktar (glTF: Y yukarı çevrilir)
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', use_selection=False, export_apply=True, export_yup=True)
print("BLENDER SOLDIER OK", OUT)
