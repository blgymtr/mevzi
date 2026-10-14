# Asker v3 — faset (low-poly) stil, iskeletli tek parça. Dış varlık yok; tamamen betikle.
# Kullanım: blender -b -P tools/blender/soldier_v3.py -- <cikti.glb> <usa|rus>
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
v("hip", (0, 0, 0.9)); v("waist", (0, 0, 1.03)); v("chest", (0, 0.01, 1.22)); v("upper", (0, 0, 1.37)); v("neck", (0, 0, 1.5)); v("head", (0, 0.012, 1.62))
e("hip", "waist"); e("waist", "chest"); e("chest", "upper"); e("upper", "neck"); e("neck", "head")
for s, n in ((-1, "r"), (1, "l")):
    v("sh" + n, (s * 0.16, 0, 1.4)); v("sa" + n, armpt(s, 0.03)); v("el" + n, armpt(s, UA)); v("wr" + n, armpt(s, UA + FA))
    e("upper", "sh" + n); e("sh" + n, "sa" + n); e("sa" + n, "el" + n); e("el" + n, "wr" + n)
    v("hp" + n, (s * 0.1, 0, 0.87)); v("th" + n, (s * 0.105, 0.005, 0.7)); v("kn" + n, (s * 0.1, 0.0, 0.48)); v("cf" + n, (s * 0.1, -0.01, 0.32)); v("an" + n, (s * 0.1, 0, 0.17))
    e("hip", "hp" + n); e("hp" + n, "th" + n); e("th" + n, "kn" + n); e("kn" + n, "cf" + n); e("cf" + n, "an" + n)
bm.to_mesh(me)
body = bpy.data.objects.new("body", me)
bpy.context.collection.objects.link(body)
sk = body.modifiers.new("skin", 'SKIN')
R = {"hip": (0.16, 0.115), "waist": (0.148, 0.1), "chest": (0.172, 0.112), "upper": (0.176, 0.105), "neck": (0.058, 0.058), "head": (0.082, 0.092)}
for n in "rl":
    # bol kesim pantolon/kol (referanstaki gibi kalın uzuvlar)
    R.update({"sh" + n: (0.07, 0.072), "sa" + n: (0.072, 0.074), "el" + n: (0.058, 0.06), "wr" + n: (0.046, 0.046),
              "hp" + n: (0.11, 0.115), "th" + n: (0.105, 0.11), "kn" + n: (0.082, 0.085), "cf" + n: (0.08, 0.084), "an" + n: (0.072, 0.074)})
sv = me.skin_vertices[0].data
for name, vert in V.items():
    sv[vert.index].radius = R[name]
sv[V["hip"].index].use_root = True
sd = body.modifiers.new("sub", 'SUBSURF'); sd.levels = 1
body.data.materials.append(mat("uniform"))
bpy.context.view_layer.objects.active = body
for m in list(body.modifiers):
    bpy.ops.object.modifier_apply(modifier=m.name)
# baş bölgesini balaklava malzemesine ata (boyun üstü)
body.data.materials.append(mat("dark"))
for p in body.data.polygons:
    c = sum((body.data.vertices[i].co for i in p.vertices), Vector()) / len(p.vertices)
    if c.z > 1.5:
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
        b = o.modifiers.new("bev", 'BEVEL'); b.width = bev; b.segments = 1
    o.data.materials.append(mat(mname))
    return o

def cyl(loc, r, h, mname, rot=(0, 0, 0), seg=10, r2=None, sc=(1, 1)):
    bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r2 is None else r2, depth=h, location=loc)
    o = bpy.context.active_object
    o.rotation_euler = rot
    o.scale = (sc[0], sc[1], 1)
    o.data.materials.append(mat(mname))
    return o

def ring(loc, rx, ry, h, mname, seg=14, t=0.012):
    # açık uçlu halka (kask bandı, bilek/diz kayışı)
    bpy.ops.mesh.primitive_cylinder_add(vertices=seg, radius=1.0, depth=h, location=loc, end_fill_type='NOTHING')
    o = bpy.context.active_object
    o.scale = (rx, ry, 1)
    s2 = o.modifiers.new("sol", 'SOLIDIFY'); s2.thickness = t; s2.offset = 1.0
    o.data.materials.append(mat(mname))
    return o

def shell(loc, scale, cut, mname, seg=12, thick=-0.03):
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

# ---------------- baş: balaklava (gövde), kask, gözlük, mikrofon
G.append(shell((0, -0.004, 1.645), (0.142, 0.154, 0.138), -0.42 if USA else -0.3, "helmet", seg=14))
G.append(ring((0, -0.004, 1.66), 0.143, 0.155, 0.02, "team", seg=14))          # takım bandı
# gözlük: kask önünde, turuncu cam + koyu çerçeve + kayış
G.append(ring((0, -0.004, 1.7), 0.146, 0.158, 0.022, "dark", seg=14, t=0.008))
G.append(box((0, 0.142, 1.7), (0.19, 0.035, 0.06), "dark", rot=(math.radians(-12), 0, 0), bev=0.01))
for s in (-1, 1):
    G.append(box((s * 0.046, 0.161, 1.7), (0.082, 0.012, 0.045), "lens", rot=(math.radians(-12), 0, s * math.radians(-14))))
# mikrofon kolu (sağ)
G.append(box((-0.09, 0.07, 1.57), (0.012, 0.11, 0.012), "dark", rot=(0, 0, math.radians(18))))
G.append(box((-0.135, 0.0, 1.6), (0.03, 0.06, 0.06), "dark"))
if USA:
    G.append(box((0, 0.135, 1.75), (0.045, 0.03, 0.035), "dark", bev=0.006))        # NVG yuvası
    G.append(box((0, -0.155, 1.68), (0.08, 0.03, 0.045), "pack", bev=0.006))        # karşı ağırlık
    for s in (-1, 1):
        G.append(box((s * 0.143, 0.0, 1.66), (0.012, 0.09, 0.018), "dark"))        # yan ray
# boyunluk
G.append(cyl((0, 0, 1.5), 0.072, 0.06, "dark", seg=10, r2=0.062))

# ---------------- plaka taşıyıcı
vest_w = 0.36 if USA else 0.38
G.append(skin_tube([(0, 0, 1.06), (0, 0.008, 1.24), (0, 0.004, 1.4)], [(0.19, 0.14), (0.198, 0.146), (0.18, 0.12)], "vest", sub=0))
G.append(box((0, 0.135, 1.27), (vest_w * 0.82, 0.04, 0.3), "vest", bev=0.012))        # ön plaka
G.append(box((0, -0.135, 1.27), (vest_w * 0.82, 0.04, 0.32), "pack", bev=0.012))      # arka panel
# omuz askıları (çakal)
for s in (-1, 1):
    G.append(box((s * 0.115, 0.0, 1.43), (0.06, 0.3, 0.025), "pack", bev=0.006))
    G.append(box((s * 0.12, 0.11, 1.33), (0.05, 0.02, 0.18), "pack"))
# alt sıra şarjör cepleri (3 uzun) + üst idari cepler (2)
for x in (-0.1, 0.0, 0.1):
    G.append(box((x, 0.168, 1.155), (0.07, 0.045, 0.12), "vest", bev=0.008))
    G.append(box((x, 0.192, 1.205), (0.072, 0.012, 0.03), "dark"))                     # kapak
for x in (-0.07, 0.07):
    G.append(box((x, 0.165, 1.33), (0.08, 0.035, 0.07), "vest", bev=0.008))
G.append(box((0.1, 0.162, 1.42), (0.03, 0.025, 0.07), "dark", bev=0.005))              # telsiz
if not USA:
    # Ratnik: yaka koruması ve omuz pedi
    bpy.ops.mesh.primitive_torus_add(major_radius=0.095, minor_radius=0.032, major_segments=10, minor_segments=5, location=(0, 0, 1.47))
    t = bpy.context.active_object; t.data.materials.append(mat("vest")); G.append(t)

# ---------------- sırt çantası (çakal) + alt cep + yan cep
G.append(box((0, -0.245, 1.24), (0.29, 0.15, 0.34), "pack", bev=0.02))
G.append(box((0, -0.255, 1.4), (0.27, 0.13, 0.05), "pack", bev=0.01))               # kapak
G.append(box((0, -0.27, 1.05), (0.25, 0.12, 0.13), "pack", bev=0.015))              # alt cep
G.append(box((0, -0.325, 1.27), (0.16, 0.03, 0.14), "pack", bev=0.01))              # ön cep
for s in (-1, 1):
    G.append(box((s * 0.155, -0.24, 1.2), (0.035, 0.1, 0.16), "pack", bev=0.01))     # yan cepler
    G.append(box((s * 0.07, -0.324, 1.25), (0.02, 0.01, 0.34), "dark"))             # kayışlar

# ---------------- kemer
GEAR["pelvis"].append(skin_tube([(0, 0, 0.95), (0, 0, 1.0)], [(0.165, 0.118), (0.165, 0.118)], "dark", sub=0))
GEAR["pelvis"].append(box((0, 0.122, 0.975), (0.05, 0.012, 0.035), "gun"))           # toka
GEAR["pelvis"].append(box((0.16, -0.03, 0.95), (0.04, 0.06, 0.08), "pack", bev=0.01))  # bel cebi
GEAR["pelvis"].append(box((-0.16, 0.02, 0.95), (0.035, 0.05, 0.07), "vest", bev=0.01))

# ---------------- kollar: omuz cebi + bayrak, dirseklik, bileklik, parmaksız eldiven
for s, n in ((-1, "r"), (1, "l")):
    rot = (0, -s * A, 0)
    GEAR["arm_" + n].append(box(armpt(s, 0.12, 0.0, 0.07), (0.016, 0.075, 0.09), "pack", rot=rot, bev=0.005))
    GEAR["arm_" + n].append(box(armpt(s, 0.1, 0.0, 0.075), (0.008, 0.055, 0.035), "team", rot=rot))
    GEAR["fore_" + n].append(box(armpt(s, UA + 0.02, -0.045, 0.0), (0.085, 0.04, 0.085), "dark", rot=rot, bev=0.012))   # dirseklik (arka)
    GEAR["fore_" + n].append(ring(armpt(s, UA + FA - 0.03), 0.05, 0.05, 0.03, "dark", seg=8))
    # el: avuç (eldiven) + parmak ucu (ten)
    GEAR["fore_" + n].append(box(armpt(s, UA + FA + 0.045, 0.0, 0.0), (0.062, 0.035, 0.075), "glove", rot=rot, bev=0.008))
    GEAR["fore_" + n].append(box(armpt(s, UA + FA + 0.105, 0.005, 0.0), (0.056, 0.03, 0.05), "skin", rot=rot, bev=0.006))
    GEAR["fore_" + n].append(box(armpt(s, UA + FA + 0.04, 0.035, -0.02), (0.02, 0.02, 0.05), "skin", rot=rot))      # başparmak

# ---------------- bacaklar: kargo cebi, dizlik + kayış, paça kayışı, bot
for s, n in ((-1, "r"), (1, "l")):
    x = s * 0.1
    GEAR["leg_" + n].append(box((x + s * 0.09, 0.03, 0.7), (0.04, 0.11, 0.15), "uniform", bev=0.01))
    GEAR["leg_" + n].append(box((x + s * 0.112, 0.03, 0.765), (0.006, 0.11, 0.025), "dark"))
    GEAR["knee_" + n].append(box((x, 0.072, 0.47), (0.11, 0.05, 0.12), "dark", bev=0.015))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.47), 0.088, 0.088, 0.025, "dark", seg=10))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.25), 0.083, 0.086, 0.02, "dark", seg=10))
    # bot: konç + gövde + burun + taban
    GEAR["knee_" + n].append(cyl((x, 0.0, 0.16), 0.074, 0.12, "boot", seg=10, r2=0.07))
    GEAR["knee_" + n].append(box((x, 0.045, 0.06), (0.12, 0.2, 0.09), "boot", bev=0.02))
    GEAR["knee_" + n].append(box((x, 0.12, 0.045), (0.11, 0.07, 0.06), "boot", bev=0.02))
    GEAR["knee_" + n].append(box((x, 0.05, 0.008), (0.125, 0.25, 0.022), "dark", bev=0.004))
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

# faset gölgeleme + UV + beyaz tepe rengi
bpy.context.view_layer.objects.active = body
bpy.ops.object.shade_flat()
bpy.ops.object.mode_set(mode='EDIT')
bpy.ops.mesh.select_all(action='SELECT')
bpy.ops.uv.cube_project(cube_size=2.5)
bpy.ops.object.mode_set(mode='OBJECT')
ca = body.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
for d in ca.data:
    d.color = (1, 1, 1, 1)
print("VERTS", len(body.data.vertices), "TRIS", sum(len(p.vertices) - 2 for p in body.data.polygons))
bpy.ops.export_scene.gltf(filepath=OUT, export_format='GLB', export_yup=True, export_skins=True, export_animations=False)
print("BLENDER V3 OK", OUT)
