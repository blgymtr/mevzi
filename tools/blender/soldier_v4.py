# Asker v4 — gerçekçi stil (yumuşak gölgeli, iki seviye bölünmüş gövde, açık yüz + güneş gözlüğü,
# kılıflı kask üstünde gözlük, yuvarlatılmış yelek/cepler). İskeletli tek parça; dış varlık yok.
# Kullanım: blender -b -P tools/blender/soldier_v4.py -- <cikti.glb> <usa|rus>
# İskelet oyundaki pivotlarla aynı (soldier_rig.py ile aynı kemik adları/konumları), bu yüzden
# yürüme/koşma/çömelme/yüzüstü/atlama/sürüklenme/ragdoll pozlarının hepsi bu gövdeyi sürer.
# Stil: düz (faset) gölgeleme, balaklava + gözlüklü kask, plaka taşıyıcı, kargo pantolon, dizlik, sırt çantası.
import bpy, bmesh, sys, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "soldier_v3.glb"
NAT = argv[1] if len(argv) > 1 else "usa"
USA = NAT == "usa"

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}
def mat(n):
    if n not in MATS:
        MATS[n] = bpy.data.materials.new(n)
    return MATS[n]

A = math.radians(38)
SH = 0.205
SY = 1.42
UA = 0.29
FA = 0.26

def armpt(s, L, fwd=0.0, out=0.0):
    d = Vector((s * math.sin(A), 0.0, -math.cos(A)))
    o = Vector((s * math.cos(A), 0.0, math.sin(A)))      # kolun dışa bakan normali
    return Vector((s * SH, fwd, SY)) + d * L + o * out

# ---------------- gövde: deri grafiği, tek seviye bölme → faset
me = bpy.data.meshes.new("body")
bm = bmesh.new()
V = {}
def v(name, co):
    V[name] = bm.verts.new(co)
def e(a, b):
    bm.edges.new((V[a], V[b]))
v("hip", (0, -0.005, 0.9)); v("waist", (0, 0.0, 1.03)); v("chest", (0, 0.012, 1.22)); v("upper", (0, 0.004, 1.36)); v("neck", (0, 0.01, 1.5))
e("hip", "waist"); e("waist", "chest"); e("chest", "upper"); e("upper", "neck")
for s, n in ((-1, "r"), (1, "l")):
    v("sh" + n, (s * 0.16, 0, 1.4)); v("sa" + n, armpt(s, 0.03)); v("el" + n, armpt(s, UA)); v("wr" + n, armpt(s, UA + FA))
    e("upper", "sh" + n); e("sh" + n, "sa" + n); e("sa" + n, "el" + n); e("el" + n, "wr" + n)
    v("hp" + n, (s * 0.1, 0, 0.87)); v("th" + n, (s * 0.105, 0.005, 0.7)); v("kn" + n, (s * 0.1, 0.0, 0.48)); v("cf" + n, (s * 0.1, -0.01, 0.32)); v("an" + n, (s * 0.1, 0, 0.17))
    e("hip", "hp" + n); e("hp" + n, "th" + n); e("th" + n, "kn" + n); e("kn" + n, "cf" + n); e("cf" + n, "an" + n)
bm.to_mesh(me)
body = bpy.data.objects.new("body", me)
bpy.context.collection.objects.link(body)
sk = body.modifiers.new("skin", 'SKIN')
R = {"hip": (0.165, 0.125), "waist": (0.148, 0.108), "chest": (0.182, 0.122), "upper": (0.2, 0.118), "neck": (0.056, 0.06)}
for n in "rl":
    # bol kesim pantolon/kol (referanstaki gibi kalın uzuvlar)
    R.update({"sh" + n: (0.078, 0.08), "sa" + n: (0.074, 0.076), "el" + n: (0.058, 0.06), "wr" + n: (0.044, 0.044),
              "hp" + n: (0.118, 0.124), "th" + n: (0.11, 0.115), "kn" + n: (0.082, 0.086), "cf" + n: (0.086, 0.092), "an" + n: (0.064, 0.066)})
sv = me.skin_vertices[0].data
for name, vert in V.items():
    sv[vert.index].radius = R[name]
sv[V["hip"].index].use_root = True
sd = body.modifiers.new("sub", 'SUBSURF'); sd.levels = 2
body.data.materials.append(mat("uniform"))
bpy.context.view_layer.objects.active = body
for m in list(body.modifiers):
    bpy.ops.object.modifier_apply(modifier=m.name)
# boyun ten rengi
body.data.materials.append(mat("skin"))
for p in body.data.polygons:
    c = sum((body.data.vertices[i].co for i in p.vertices), Vector()) / len(p.vertices)
    if c.z > 1.49:
        p.material_index = 1

# ---------------- iskelet (soldier_rig.py ile aynı)
arm_d = bpy.data.armatures.new("rig")
rig = bpy.data.objects.new("rig", arm_d)
bpy.context.collection.objects.link(rig)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='EDIT')
eb = arm_d.edit_bones
def bone(name, head, tail, parent=None):
    b = eb.new(name); b.head = head; b.tail = tail; b.roll = 0.0
    if parent:
        b.parent = eb[parent]
bone("pelvis", (0, 0, 0.92), (0, 0, 1.0))
bone("spine", (0, 0, 0.92), (0, 0, 1.5), "pelvis")
for s, n in ((-1, "r"), (1, "l")):
    bone("arm_" + n, (s * 0.21, 0, SY), armpt(s, UA), "spine")
    bone("fore_" + n, armpt(s, UA), armpt(s, UA + FA + 0.08), "arm_" + n)
    bone("leg_" + n, (s * 0.1, 0, 0.92), (s * 0.1, 0, 0.48), "pelvis")
    bone("knee_" + n, (s * 0.1, 0, 0.48), (s * 0.1, 0.02, 0.05), "leg_" + n)
bpy.ops.object.mode_set(mode='OBJECT')
bpy.ops.object.select_all(action='DESELECT')
body.select_set(True); rig.select_set(True)
bpy.context.view_layer.objects.active = rig
bpy.ops.object.parent_set(type='ARMATURE_AUTO')

# ---------------- teçhizat yardımcıları (düşük poligon, faset)
def box(loc, size, mname, rot=(0, 0, 0), bev=0.0):
    bpy.ops.mesh.primitive_cube_add(location=loc)
    o = bpy.context.active_object
    o.scale = (size[0] * 0.5, size[1] * 0.5, size[2] * 0.5)
    o.rotation_euler = rot
    if bev > 0:
        bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
        b = o.modifiers.new("bev", 'BEVEL'); b.width = bev; b.segments = 3
    o.data.materials.append(mat(mname))
    return o

def blob(loc, scale, mname, seg=14, rot=(0, 0, 0)):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=max(6, seg // 2 + 1), location=loc, rotation=rot)
    o = bpy.context.active_object
    o.scale = scale
    o.data.materials.append(mat(mname))
    return o

def cyl(loc, r, h, mname, rot=(0, 0, 0), seg=16, r2=None, sc=(1, 1)):
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r2 is None else r2, depth=h, location=loc)
    o = bpy.context.active_object
    o.rotation_euler = rot
    o.scale = (sc[0], sc[1], 1)
    o.data.materials.append(mat(mname))
    return o

def ring(loc, rx, ry, h, mname, seg=24, t=0.012):
    # açık uçlu halka (kask bandı, bilek/diz kayışı)
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=1.0, depth=h, location=loc, end_fill_type='NOTHING')
    o = bpy.context.active_object
    o.scale = (rx, ry, 1)
    s2 = o.modifiers.new("sol", 'SOLIDIFY'); s2.thickness = t; s2.offset = 1.0
    o.data.materials.append(mat(mname))
    return o

def shell(loc, scale, cut, mname, seg=24, thick=-0.03):
    bpy.ops.mesh.primitive_uv_sphere_add(segments=seg, ring_count=seg // 2 + 1, location=loc)
    o = bpy.context.active_object
    o.scale = scale
    b2 = bmesh.new(); b2.from_mesh(o.data)
    bmesh.ops.delete(b2, geom=[q for q in b2.verts if q.co.z < cut], context='VERTS')
    b2.to_mesh(o.data); b2.free()
    s2 = o.modifiers.new("sol", 'SOLIDIFY'); s2.thickness = thick
    o.data.materials.append(mat(mname))
    return o

def skin_tube(points, radii, mname, sub=1):
    m2 = bpy.data.meshes.new("t"); b3 = bmesh.new()
    vs = [b3.verts.new(p) for p in points]
    for a, b in zip(vs, vs[1:]):
        b3.edges.new((a, b))
    b3.to_mesh(m2)
    o = bpy.data.objects.new("t", m2); bpy.context.collection.objects.link(o)
    o.modifiers.new("skin", 'SKIN')
    for i, r in enumerate(radii):
        m2.skin_vertices[0].data[i].radius = r
    m2.skin_vertices[0].data[0].use_root = True
    if sub:
        s3 = o.modifiers.new("sub", 'SUBSURF'); s3.levels = sub
    o.data.materials.append(mat(mname))
    return o

GEAR = {k: [] for k in ["spine", "pelvis", "arm_r", "arm_l", "fore_r", "fore_l", "leg_r", "leg_l", "knee_r", "knee_l"]}
G = GEAR["spine"]

# ---------------- baş: yüz (kafa, çene, elmacık, burun, kulak, kaş), güneş gözlüğü, kask
G.append(blob((0, 0.01, 1.615), (0.086, 0.096, 0.108), "skin", seg=24))
G.append(blob((0, 0.045, 1.56), (0.064, 0.058, 0.045), "skin", seg=18))
for s in (-1, 1):
    G.append(blob((s * 0.05, 0.07, 1.6), (0.028, 0.03, 0.024), "skin", seg=12))
    G.append(blob((s * 0.086, 0.0, 1.61), (0.014, 0.024, 0.03), "skin", seg=12))
G.append(blob((0, 0.098, 1.6), (0.016, 0.022, 0.028), "skin", seg=12, rot=(0.25, 0, 0)))
G.append(box((0, 0.088, 1.648), (0.13, 0.02, 0.016), "skin", bev=0.006))
G.append(box((0, 0.09, 1.552), (0.04, 0.008, 0.008), "dark", bev=0.003))
for s in (-1, 1):
    G.append(blob((s * 0.034, 0.093, 1.622), (0.03, 0.01, 0.019), "lens", seg=14))
    G.append(box((s * 0.07, 0.04, 1.625), (0.006, 0.09, 0.006), "dark"))
G.append(box((0, 0.1, 1.626), (0.016, 0.006, 0.006), "dark"))
G.append(shell((0, -0.012, 1.672), (0.128, 0.142, 0.122), -0.18 if USA else -0.12, "helmet", seg=28))
G.append(ring((0, -0.012, 1.652), 0.13, 0.144, 0.01, "helmet", seg=28, t=0.012))
G.append(ring((0, -0.012, 1.676), 0.13, 0.144, 0.014, "team", seg=28))
G.append(ring((0, -0.012, 1.716), 0.132, 0.146, 0.018, "dark", seg=28, t=0.007))
G.append(blob((0, 0.118, 1.722), (0.09, 0.028, 0.032), "dark", seg=16))
for s in (-1, 1):
    G.append(blob((s * 0.043, 0.138, 1.724), (0.038, 0.011, 0.024), "lens", seg=14))
for s in (-1, 1):
    G.append(box((s * 0.088, 0.03, 1.565), (0.006, 0.012, 0.09), "dark", rot=(0.4, 0, 0)))
    G.append(blob((s * 0.095, 0.0, 1.615), (0.022, 0.04, 0.045), "dark", seg=14))
G.append(box((-0.085, 0.07, 1.565), (0.01, 0.1, 0.01), "dark", rot=(0, 0, math.radians(18))))
if USA:
    G.append(box((0, 0.135, 1.75), (0.045, 0.03, 0.035), "dark", bev=0.006))        # NVG yuvası
    G.append(box((0, -0.155, 1.68), (0.08, 0.03, 0.045), "pack", bev=0.006))        # karşı ağırlık
    for s in (-1, 1):
        G.append(box((s * 0.143, 0.0, 1.66), (0.012, 0.09, 0.018), "dark"))        # yan ray
# ceket eteği
G.append(skin_tube([(0, 0.0, 0.93), (0, 0.0, 1.0)], [(0.172, 0.13), (0.164, 0.122)], "uniform", sub=2))
# gömlek yakası
G.append(cyl((0, 0.005, 1.49), 0.07, 0.05, "uniform", seg=20, r2=0.064))

# ---------------- plaka taşıyıcı
vest_w = 0.36 if USA else 0.38
G.append(skin_tube([(0, 0, 1.06), (0, 0.008, 1.24), (0, 0.004, 1.4)], [(0.204, 0.152), (0.212, 0.158), (0.194, 0.132)], "vest", sub=2))
G.append(box((0, 0.15, 1.27), (vest_w * 0.88, 0.04, 0.3), "vest", bev=0.012))        # ön plaka
G.append(box((0, -0.15, 1.27), (vest_w * 0.88, 0.04, 0.32), "pack", bev=0.012))      # arka panel
# omuz askıları (çakal)
for s in (-1, 1):
    G.append(box((s * 0.115, 0.0, 1.43), (0.06, 0.3, 0.025), "pack", bev=0.006))
    G.append(box((s * 0.12, 0.11, 1.33), (0.05, 0.02, 0.18), "pack"))
# alt sıra şarjör cepleri (3 uzun) + üst idari cepler (2)
for x in (-0.1, 0.0, 0.1):
    G.append(box((x, 0.183, 1.155), (0.07, 0.045, 0.12), "vest", bev=0.008))
    G.append(box((x, 0.207, 1.205), (0.072, 0.012, 0.03), "dark"))                     # kapak
for x in (-0.07, 0.07):
    G.append(box((x, 0.18, 1.33), (0.08, 0.035, 0.07), "vest", bev=0.008))
G.append(box((0.1, 0.162, 1.42), (0.03, 0.025, 0.07), "dark", bev=0.005))              # telsiz
if not USA:
    # Ratnik: yaka koruması ve omuz pedi
    bpy.ops.mesh.primitive_torus_add(major_radius=0.095, minor_radius=0.032, major_segments=10, minor_segments=5, location=(0, 0, 1.47))
    t = bpy.context.active_object; t.data.materials.append(mat("vest")); G.append(t)

# ---------------- sırt çantası (çakal) + alt cep + yan cep
G.append(box((0, -0.26, 1.24), (0.3, 0.15, 0.34), "pack", bev=0.02))
G.append(box((0, -0.255, 1.4), (0.27, 0.13, 0.05), "pack", bev=0.01))               # kapak
G.append(box((0, -0.27, 1.05), (0.25, 0.12, 0.13), "pack", bev=0.015))              # alt cep
G.append(box((0, -0.325, 1.27), (0.16, 0.03, 0.14), "pack", bev=0.01))              # ön cep
for s in (-1, 1):
    G.append(box((s * 0.155, -0.24, 1.2), (0.035, 0.1, 0.16), "pack", bev=0.01))     # yan cepler
    G.append(box((s * 0.07, -0.324, 1.25), (0.02, 0.01, 0.34), "dark"))             # kayışlar

# ---------------- kemer
GEAR["pelvis"].append(skin_tube([(0, 0, 0.95), (0, 0, 1.0)], [(0.177, 0.13), (0.177, 0.13)], "dark", sub=2))
GEAR["pelvis"].append(box((0, 0.134, 0.975), (0.05, 0.012, 0.035), "gun"))           # toka
GEAR["pelvis"].append(box((0.16, -0.03, 0.95), (0.04, 0.06, 0.08), "pack", bev=0.01))  # bel cebi
GEAR["pelvis"].append(box((-0.16, 0.02, 0.95), (0.035, 0.05, 0.07), "vest", bev=0.01))

# ---------------- kollar: omuz cebi + bayrak, dirseklik, bileklik, parmaksız eldiven
for s, n in ((-1, "r"), (1, "l")):
    rot = (0, -s * A, 0)
    GEAR["arm_" + n].append(box(armpt(s, 0.12, 0.0, 0.086), (0.016, 0.075, 0.09), "pack", rot=rot, bev=0.005))
    GEAR["arm_" + n].append(box(armpt(s, 0.1, 0.0, 0.092), (0.008, 0.055, 0.035), "team", rot=rot))
    GEAR["fore_" + n].append(box(armpt(s, UA + 0.02, -0.055, 0.0), (0.1, 0.045, 0.1), "dark", rot=rot, bev=0.012))   # dirseklik (arka)
    GEAR["fore_" + n].append(ring(armpt(s, UA + FA - 0.03), 0.058, 0.058, 0.03, "dark", seg=8))
    # el: eldivenli avuç + kıvrık parmaklar + başparmak
    GEAR["fore_" + n].append(blob(armpt(s, UA + FA + 0.045, 0.0, 0.0), (0.034, 0.024, 0.045), "glove", seg=14, rot=rot))
    for k in range(4):
        GEAR["fore_" + n].append(blob(armpt(s, UA + FA + 0.09, 0.012, (k - 1.5) * 0.013), (0.009, 0.014, 0.022), "glove", seg=10, rot=rot))
    GEAR["fore_" + n].append(blob(armpt(s, UA + FA + 0.04, 0.03, -0.02), (0.01, 0.012, 0.028), "glove", seg=10, rot=rot))

# ---------------- bacaklar: kargo cebi, dizlik + kayış, paça kayışı, bot
for s, n in ((-1, "r"), (1, "l")):
    x = s * 0.1
    GEAR["leg_" + n].append(box((x + s * 0.115, 0.03, 0.7), (0.045, 0.12, 0.16), "uniform", bev=0.01))
    GEAR["leg_" + n].append(box((x + s * 0.14, 0.03, 0.775), (0.006, 0.12, 0.025), "dark"))
    GEAR["knee_" + n].append(blob((x, 0.085, 0.47), (0.065, 0.035, 0.07), "dark", seg=16))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.47), 0.105, 0.108, 0.025, "dark", seg=10))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.25), 0.1, 0.104, 0.02, "dark", seg=10))
    # bot: konç + gövde + burun + taban
    GEAR["knee_" + n].append(cyl((x, 0.0, 0.16), 0.088, 0.12, "boot", seg=10, r2=0.084))
    GEAR["knee_" + n].append(box((x, 0.04, 0.06), (0.13, 0.2, 0.1), "boot", bev=0.035))
    GEAR["knee_" + n].append(blob((x, 0.13, 0.045), (0.065, 0.06, 0.04), "boot", seg=16))
    GEAR["knee_" + n].append(box((x, 0.055, 0.008), (0.145, 0.27, 0.022), "dark", bev=0.004))
    GEAR["knee_" + n].append(box((x, 0.02, 0.13), (0.08, 0.1, 0.012), "dark"))     # bağcık bandı

# teçhizatı uygula, gövdeye kat, kemiğine tam ağırlık
for bn, obs in GEAR.items():
    obs = [o for o in obs if o is not None]
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

# ---------------- A-pozundan kollar aşağı → dinlenme pozu
bpy.context.view_layer.objects.active = rig
bpy.ops.object.mode_set(mode='POSE')
for s, n in ((-1, "r"), (1, "l")):
    pb = rig.pose.bones["arm_" + n]
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

# yumuşak gölgeleme + UV + beyaz tepe rengi
bpy.context.view_layer.objects.active = body
bpy.ops.object.shade_smooth()
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.cube_project(cube_size=2.5)
bpy.ops.object.mode_set(mode='OBJECT')
ca = body.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
for d in ca.data:
    d.color = (1, 1, 1, 1)
print("VERTS", len(body.data.vertices), "TRIS", sum(len(p.vertices) - 2 for p in body.data.polygons))
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_yup=True, export_skins=True, export_animations=False)
print("BLENDER V4 OK", OUT)
