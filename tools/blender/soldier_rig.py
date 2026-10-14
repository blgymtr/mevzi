# İskeletli, tek parça (deri bağlı) asker — Blender betiği, dış varlık yok.
# Kullanım: blender -b -P tools/blender/soldier_rig.py -- <cikti.glb> <usa|rus>
# Kemikler oyundaki pivotlarla aynı konumda ve adda:
#   pelvis(0.92) > spine(0.92) > arm_r/arm_l(±0.21, 1.42) > fore_r/fore_l(1.13)
#   pelvis > leg_r/leg_l(±0.1, 0.92) > knee_r/knee_l(0.48)
# Blender: Z yukarı, +Y ileri (glTF'te -Z). Sağ taraf: -X.
import bpy, bmesh, sys, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "soldier_rig.glb"
NAT = argv[1] if len(argv) > 1 else "usa"
USA = NAT == "usa"

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}
def mat(n):
    if n not in MATS:
        MATS[n] = bpy.data.materials.new(n)
    return MATS[n]

A = math.radians(38)          # A-pozu kol açısı (ağırlık hesabı için kollar gövdeden uzak)
SH = 0.21
SY = 1.42
UA = 0.29                      # üst kol boyu
FA = 0.26                      # önkol boyu (bilekten)

def armpt(s, L):
    # omuzdan aşağı-dışa A açısıyla
    return Vector((s * (SH + math.sin(A) * L), 0.0, SY - math.cos(A) * L))

# ---------------- gövde: tek deri grafiği
me = bpy.data.meshes.new("body")
bm = bmesh.new()
V = {}
def v(name, co):
    V[name] = bm.verts.new(co)
def e(a, b):
    bm.edges.new((V[a], V[b]))
v("hip", (0, 0, 0.9)); v("waist", (0, 0.0, 1.04)); v("chest", (0, 0.012, 1.24)); v("upper", (0, 0.0, 1.38)); v("neck", (0, 0.0, 1.52))
e("hip", "waist"); e("waist", "chest"); e("chest", "upper"); e("upper", "neck")
for s, n in ((-1, "r"), (1, "l")):
    v("sh" + n, (s * 0.17, 0, 1.4)); v("sa" + n, armpt(s, 0.02)); v("el" + n, armpt(s, UA)); v("wr" + n, armpt(s, UA + FA)); v("hd" + n, armpt(s, UA + FA + 0.08))
    e("upper", "sh" + n); e("sh" + n, "sa" + n); e("sa" + n, "el" + n); e("el" + n, "wr" + n); e("wr" + n, "hd" + n)
    v("hp" + n, (s * 0.1, 0, 0.88)); v("th" + n, (s * 0.1, 0, 0.72)); v("kn" + n, (s * 0.1, 0, 0.48)); v("cf" + n, (s * 0.1, -0.01, 0.34)); v("an" + n, (s * 0.1, 0, 0.1))
    e("hip", "hp" + n); e("hp" + n, "th" + n); e("th" + n, "kn" + n); e("kn" + n, "cf" + n); e("cf" + n, "an" + n)
bm.to_mesh(me)
body = bpy.data.objects.new("body", me)
bpy.context.collection.objects.link(body)
sk = body.modifiers.new("skin", 'SKIN')
sk.use_smooth_shade = True
R = {
    "hip": (0.155, 0.11), "waist": (0.15, 0.1), "chest": (0.18, 0.115), "upper": (0.19, 0.11), "neck": (0.052, 0.052),
}
for n in "rl":
    R.update({"sh" + n: (0.075, 0.075), "sa" + n: (0.07, 0.072), "el" + n: (0.055, 0.057), "wr" + n: (0.04, 0.042), "hd" + n: (0.042, 0.03),
              "hp" + n: (0.105, 0.11), "th" + n: (0.1, 0.105), "kn" + n: (0.072, 0.076), "cf" + n: (0.075, 0.08), "an" + n: (0.056, 0.058)})
sv = me.skin_vertices[0].data
for name, vert in V.items():
    sv[vert.index].radius = R[name]
sv[V["hip"].index].use_root = True
sd = body.modifiers.new("sub", 'SUBSURF'); sd.levels = 2
body.data.materials.append(mat("uniform"))
bpy.context.view_layer.objects.active = body
for m in list(body.modifiers):
    bpy.ops.object.modifier_apply(modifier=m.name)
bpy.ops.object.shade_smooth()

# ---------------- iskelet
arm_d = bpy.data.armatures.new("rig")
rig = bpy.data.objects.new("rig", arm_d)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_d.edit_bones
def bone(name, head, tail, parent=None):
    b = eb.new(name)
    b.head = head
    b.tail = tail
    b.roll = 0.0
    if parent:
        b.parent = eb[parent]
    return b
bone("pelvis", (0, 0, 0.92), (0, 0, 1.0))
bone("spine", (0, 0, 0.92), (0, 0, 1.5), "pelvis")
for s, n in ((-1, "r"), (1, "l")):
    bone("arm_" + n, (s * SH, 0, SY), armpt(s, UA), "spine")
    bone("fore_" + n, armpt(s, UA), armpt(s, UA + FA + 0.08), "arm_" + n)
    bone("leg_" + n, (s * 0.1, 0, 0.92), (s * 0.1, 0, 0.48), "pelvis")
    bone("knee_" + n, (s * 0.1, 0, 0.48), (s * 0.1, 0.02, 0.05), "leg_" + n)
bpy.ops.object.mode_set(mode='OBJECT')

# otomatik ağırlık
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True)
rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# ---------------- teçhizat (sert bağlı: tümü tek kemiğe)
def prim(kind, loc, scale, matname, rot=(0, 0, 0), seg=16, bevel=0.0):
    if kind == "sphere":
        bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(6, seg // 2), location=loc)
    elif kind == "cyl":
        bpy.ops.mesh.primitive_cylinder_add(vertices=seg, location=loc)
    else:
        bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.active_object
    o.scale = scale
    o.rotation_euler = rot
    if bevel > 0:
        b = o.modifiers.new("bev", 'BEVEL'); b.width = bevel; b.segments = 2
    o.data.materials.append(mat(matname))
    bpy.ops.object.shade_smooth()
    return o

def shell(loc, scale, cut, matname, thick=-0.04, seg=24):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    b2 = bmesh.new(); b2.from_mesh(o.data)
    bmesh.ops.delete(b2, geom=[q for q in b2.verts if q.co.z < cut], context='VERTS')
    b2.to_mesh(o.data); b2.free()
    s2 = o.modifiers.new("sol", 'SOLIDIFY'); s2.thickness = thick
    o.data.materials.append(mat(matname))
    bpy.ops.object.shade_smooth()
    return o

def tube(points, radii, matname, sub=1):
    m2 = bpy.data.meshes.new("t"); b3 = bmesh.new()
    vs = [b3.verts.new(p) for p in points]
    for a, b in zip(vs, vs[1:]):
        b3.edges.new((a, b))
    b3.to_mesh(m2)
    o = bpy.data.objects.new("t", m2); bpy.context.collection.objects.link(o)
    sk2 = o.modifiers.new("skin", 'SKIN'); sk2.use_smooth_shade = True
    for i, r in enumerate(radii):
        m2.skin_vertices[0].data[i].radius = r
    m2.skin_vertices[0].data[0].use_root = True
    s3 = o.modifiers.new("sub", 'SUBSURF'); s3.levels = sub
    o.data.materials.append(mat(matname))
    return o

GEAR = {"spine": [], "pelvis": [], "knee_r": [], "knee_l": [], "fore_r": [], "fore_l": [], "arm_r": [], "arm_l": [], "leg_r": [], "leg_l": []}
G = GEAR["spine"]
# baş
G.append(prim("sphere", (0, 0.005, 1.655), (0.088, 0.098, 0.106), "skin", seg=24))
G.append(prim("sphere", (0, 0.045, 1.6), (0.066, 0.058, 0.046), "skin"))
G.append(prim("sphere", (0, 0.1, 1.645), (0.016, 0.02, 0.024), "skin", seg=8))
for s in (-1, 1):
    G.append(prim("sphere", (s * 0.088, 0.0, 1.65), (0.012, 0.022, 0.026), "skin", seg=8))
G.append(prim("cube", (0, 0.085, 1.665), (0.075, 0.012, 0.018), "dark", bevel=0.008))     # gözlük / göz gölgesi
if USA:
    # ACH kask (kılıflı) + takım bandı + NVG yuvası + karşı ağırlık + yan ray
    G.append(shell((0, -0.008, 1.665), (0.145, 0.157, 0.14), -0.18, "helmet"))
    G.append(prim("cyl", (0, -0.008, 1.705), (0.149, 0.161, 0.022), "team", seg=28))
    G.append(prim("cube", (0, 0.135, 1.745), (0.035, 0.016, 0.025), "dark", bevel=0.006))
    G.append(prim("cube", (0, -0.15, 1.705), (0.05, 0.02, 0.03), "pack", bevel=0.008))
    for s in (-1, 1):
        G.append(prim("cube", (s * 0.145, 0.0, 1.69), (0.008, 0.06, 0.012), "dark"))
    # plaka taşıyıcı (çakal) + kemerband + cepler + telsiz + turnike
    G.append(tube([(0, 0, 1.08), (0, 0.01, 1.24), (0, 0.005, 1.42)], [(0.195, 0.145), (0.205, 0.152), (0.18, 0.122)], "vest"))
    for x in (-0.11, 0.0, 0.11):
        G.append(prim("cube", (x, 0.165, 1.17), (0.042, 0.028, 0.068), "vest", bevel=0.012))
    G.append(prim("cube", (-0.11, 0.155, 1.34), (0.05, 0.025, 0.04), "vest", bevel=0.01))
    G.append(prim("cube", (0.12, 0.15, 1.35), (0.03, 0.025, 0.068), "dark", bevel=0.008))
    G.append(prim("cyl", (0.13, 0.15, 1.5), (0.006, 0.006, 0.12), "dark", seg=6))
    for s in (-1, 1):
        G.append(prim("cube", (s * 0.12, 0, 1.445), (0.03, 0.13, 0.018), "vest", bevel=0.006))
    # hücum sırt çantası + yan cepler + rulo mat
    G.append(tube([(0, -0.21, 1.06), (0, -0.235, 1.3), (0, -0.215, 1.47)], [(0.15, 0.09), (0.165, 0.1), (0.125, 0.065)], "pack"))
    for s in (-1, 1):
        G.append(prim("cube", (s * 0.16, -0.22, 1.2), (0.03, 0.06, 0.08), "pack", bevel=0.015))
    G.append(prim("cyl", (0, -0.215, 1.52), (0.055, 0.055, 0.14), "pack", rot=(0, math.pi / 2, 0)))
    # omuz cebi + bayrak yaması (takım rengi)
    for s in (-1, 1):
        GEAR["arm_" + ("r" if s < 0 else "l")].append(prim("cube", (s * (SH + 0.07), 0.0, 1.32), (0.012, 0.045, 0.05), "team", rot=(0, s * A, 0), bevel=0.006))
else:
    # 6B47 kask (kılıflı) + takım bandı + gözlük
    G.append(shell((0, 0, 1.655), (0.15, 0.156, 0.146), -0.12, "helmet"))
    G.append(prim("cyl", (0, 0, 1.69), (0.153, 0.159, 0.022), "team", seg=28))
    G.append(prim("cube", (0, 0.12, 1.72), (0.065, 0.015, 0.02), "dark", bevel=0.006))
    # 6B45 yelek (Ratnik): geniş, yakalı, omuz korumalı
    G.append(tube([(0, 0, 1.04), (0, 0.012, 1.22), (0, 0, 1.43)], [(0.198, 0.15), (0.21, 0.155), (0.19, 0.13)], "vest"))
    bpy.ops.mesh.primitive_torus_add(major_radius=0.1, minor_radius=0.03, location=(0, 0, 1.47))
    t = bpy.context.active_object; t.data.materials.append(mat("vest")); bpy.ops.object.shade_smooth(); G.append(t)
    for x in (-0.12, -0.04, 0.04, 0.12):
        G.append(prim("cube", (x, 0.16, 1.2), (0.035, 0.028, 0.07), "vest", bevel=0.01))
    G.append(prim("cube", (-0.1, 0.155, 1.36), (0.04, 0.025, 0.05), "dark", bevel=0.008))
    G.append(tube([(0, -0.19, 1.1), (0, -0.2, 1.32)], [(0.125, 0.075), (0.135, 0.075)], "pack"))
    for s in (-1, 1):
        GEAR["arm_" + ("r" if s < 0 else "l")].append(prim("sphere", (s * (SH + 0.04), 0.0, 1.4), (0.08, 0.08, 0.06), "vest"))
# kemer + bel çantaları
GEAR["pelvis"].append(tube([(0, 0, 0.94), (0, 0, 0.99)], [(0.168, 0.118), (0.168, 0.118)], "dark"))
GEAR["pelvis"].append(prim("cube", (-0.15, 0.06, 0.96), (0.04, 0.03, 0.045), "pack", bevel=0.01))
GEAR["pelvis"].append(prim("cube", (0.16, -0.04, 0.95), (0.035, 0.035, 0.05), "pack", bevel=0.01))
for s, n in ((-1, "r"), (1, "l")):
    # dizlik (takım rengi), uyluk cebi, eldiven / el, bot
    GEAR["knee_" + n].append(prim("sphere", (s * 0.1, 0.055, 0.47), (0.062, 0.035, 0.062), "team"))
    GEAR["leg_" + n].append(prim("cube", (s * 0.18, 0.0, 0.68), (0.02, 0.045, 0.06), "uniform", bevel=0.012))
    hp = armpt(s, UA + FA + 0.06)
    GEAR["fore_" + n].append(prim("sphere", hp, (0.04, 0.048, 0.055), "glove" if USA else "skin"))
    GEAR["knee_" + n].append(tube([(s * 0.1, 0, 0.2), (s * 0.1, 0.02, 0.09), (s * 0.1, 0.1, 0.035)], [(0.062, 0.066), (0.066, 0.085), (0.058, 0.062)], "boot"))
    GEAR["knee_" + n].append(prim("cube", (s * 0.1, 0.04, 0.012), (0.05, 0.105, 0.012), "dark", bevel=0.006))

# teçhizatı uygula, gövdeye kat ve ilgili kemiğe tam ağırlık ver
for bn, obs in GEAR.items():
    for o in obs:
        bpy.context.view_layer.objects.active = o
        for m in list(o.modifiers):
            bpy.ops.object.modifier_apply(modifier=m.name)
        bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
        vg = o.vertex_groups.new(name=bn)
        vg.add(list(range(len(o.data.vertices))), 1.0, 'REPLACE')
    if obs:
        bpy.ops.object.select_all(action='DESELECT')
        for o in obs:
            o.select_set(True)
        body.select_set(True)
        bpy.context.view_layer.objects.active = body
        bpy.ops.object.join()

# ---------------- kolları A-pozundan aşağı sarkıt ve bunu dinlenme pozu yap
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
for s, n in ((-1, "r"), (1, "l")):
    pb = rig.pose.bones["arm_" + n]
    pb.rotation_mode = 'XYZ'
    # kemik yerel eksenleri: önce dünyada omuz ekseni Y (ileri) etrafında döndür
    M = Matrix.Rotation(s * A, 4, 'Y')
    pb.matrix = Matrix.Translation(pb.head) @ M @ Matrix.Translation(-pb.head) @ pb.matrix
bpy.context.view_layer.update()
bpy.ops.object.mode_set(mode='OBJECT')
bpy.context.view_layer.objects.active = body
for m in body.modifiers:
    if m.type == 'ARMATURE':
        bpy.ops.object.modifier_apply(modifier=m.name)
        break
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
bpy.ops.pose.armature_apply(selected=False)
bpy.ops.object.mode_set(mode='OBJECT')
am = body.modifiers.new("rig", 'ARMATURE')
am.object = rig

# UV + beyaz tepe rengi
bpy.context.view_layer.objects.active = body
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.cube_project(cube_size=2.5)
bpy.ops.object.mode_set(mode='OBJECT')
ca = body.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
for d in ca.data:
    d.color = (1, 1, 1, 1)

for b in rig.data.bones:
    print("BONE", b.name, tuple(round(c, 3) for c in b.head_local), tuple(round(c, 3) for c in b.tail_local))
print("VERTS", len(body.data.vertices))
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_yup=True, export_skins=True, export_animations=False)
print("BLENDER RIG OK", OUT)
