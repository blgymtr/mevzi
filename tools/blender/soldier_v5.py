# Asker v5 — anatomik gövde + ayrıntılı teçhizat. v4 iskeleti/kemik adları aynen (oyundaki pozlar, IK,
# ragdoll değişmeden çalışır). Gövde: deltoid/pazı/önkol kası, kalça, uyluk ön-arka kesiti, baldır kası,
# pantolon kırışık halkaları. Teçhizat: yüksek kesim kask (kulak oyuğu, NVG yuvası + bungee, yan ray + kulaklık),
# plaka taşıyıcı + kummerbund MOLLE şeritleri, cepten taşan şarjörler, telsiz + kırbaç anten + PTT kablosu,
# omuz askısında turnike, el bombası cepleri, hidrasyon hortumu, saldırı çantası (sıkıştırma kayışları,
# uyku tulumu rulosu, katlanır kürek), battle belt (dökme cebi, matara, kılıf), dizlik/dirseklik,
# bağcıklı bot + dişli taban, eldiven boğum pedi. ABD/Rusya ayrımı (Ratnik 6B47 kask örtüsü, yaka koruması).
# Kullanım: python3 tools/blender/soldier_v5.py -- <cikti.glb> <usa|rus>
# İskelet oyundaki pivotlarla aynı (soldier_rig.py ile aynı kemik adları/konumları), bu yüzden
# yürüme/koşma/çömelme/yüzüstü/atlama/sürüklenme/ragdoll pozlarının hepsi bu gövdeyi sürer.
# Stil: düz (faset) gölgeleme, balaklava + gözlüklü kask, plaka taşıyıcı, kargo pantolon, dizlik, sırt çantası.
import bpy, bmesh, sys, math
from mathutils import Vector, Matrix

argv = sys.argv[sys.argv.index("--") + 1:] if "--" in sys.argv else []
OUT = argv[0] if argv else "soldier_v5.glb"
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
v("hip", (0, -0.012, 0.9)); v("waist", (0, 0.0, 1.03)); v("chest", (0, 0.016, 1.22)); v("upper", (0, 0.004, 1.36)); v("neck", (0, 0.012, 1.5))
e("hip", "waist"); e("waist", "chest"); e("chest", "upper"); e("upper", "neck")
for s, n in ((-1, "r"), (1, "l")):
    v("sh" + n, (s * 0.16, 0, 1.4)); v("sa" + n, armpt(s, 0.03)); v("bi" + n, armpt(s, 0.15)); v("el" + n, armpt(s, UA)); v("fo" + n, armpt(s, UA + 0.07)); v("wr" + n, armpt(s, UA + FA))
    e("upper", "sh" + n); e("sh" + n, "sa" + n); e("sa" + n, "bi" + n); e("bi" + n, "el" + n); e("el" + n, "fo" + n); e("fo" + n, "wr" + n)
    # bacak: kalça → uyluk (önde dolgun) → diz → baldır (arkada şişkin) → bilek
    v("hp" + n, (s * 0.1, -0.006, 0.87)); v("th" + n, (s * 0.104, 0.008, 0.71)); v("tl" + n, (s * 0.1, 0.01, 0.57)); v("kn" + n, (s * 0.1, 0.004, 0.48))
    v("cf" + n, (s * 0.1, -0.018, 0.35)); v("sn" + n, (s * 0.1, -0.006, 0.24)); v("an" + n, (s * 0.1, 0, 0.17))
    e("hip", "hp" + n); e("hp" + n, "th" + n); e("th" + n, "tl" + n); e("tl" + n, "kn" + n); e("kn" + n, "cf" + n); e("cf" + n, "sn" + n); e("sn" + n, "an" + n)
bm.to_mesh(me)
body = bpy.data.objects.new("body", me)
bpy.context.collection.objects.link(body)
sk = body.modifiers.new("skin", 'SKIN')
R = {"hip": (0.158, 0.118), "waist": (0.138, 0.102), "chest": (0.17, 0.118), "upper": (0.19, 0.112), "neck": (0.052, 0.056)}
for n in "rl":
    # eliptik kesitler: kol (deltoid → pazı → dirsek → önkol kası → bilek), bacak (uyluk ön-arka dolgun, baldır şişkin)
    R.update({"sh" + n: (0.07, 0.074), "sa" + n: (0.066, 0.07), "bi" + n: (0.056, 0.06), "el" + n: (0.047, 0.049), "fo" + n: (0.05, 0.047), "wr" + n: (0.036, 0.032),
              "hp" + n: (0.1, 0.11), "th" + n: (0.094, 0.104), "tl" + n: (0.08, 0.088), "kn" + n: (0.068, 0.072), "cf" + n: (0.07, 0.08), "sn" + n: (0.058, 0.062), "an" + n: (0.05, 0.052)})
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
G.append(shell((0, -0.012, 1.672), (0.128, 0.142, 0.122), -0.18 if USA else -0.12, "helmet", seg=32))
if USA:
    # yüksek kesim (FAST tipi): kulak üstü oyuk — kulaklık kaskın altından görünür
    for s in (-1, 1):
        G.append(box((s * 0.122, 0.0, 1.637), (0.03, 0.11, 0.05), "helmet", bev=0.01))
    for s in (-1, 1):
        G.append(box((s * 0.138, 0.0, 1.668), (0.012, 0.1, 0.022), "dark", bev=0.003))     # yan ray (ARC)
        G.append(box((s * 0.141, 0.035, 1.668), (0.008, 0.02, 0.014), "gun"))              # ray kilidi
        G.append(box((s * 0.07, -0.08, 1.74), (0.04, 0.05, 0.004), "team", rot=(0.6, 0, s * 0.4)))  # IR/kimlik yaması
    G.append(box((0, 0.128, 1.735), (0.05, 0.022, 0.04), "dark", bev=0.006))              # NVG yuvası (shroud)
    G.append(box((0, 0.148, 1.722), (0.028, 0.02, 0.028), "gun", bev=0.004))
    for s in (-1, 1):
        G.append(box((s * 0.08, -0.06, 1.74), (0.004, 0.16, 0.004), "dark", rot=(0.5, 0, s * 0.6)))  # bungee
    G.append(box((0, -0.155, 1.68), (0.085, 0.032, 0.05), "pack", bev=0.008))             # karşı ağırlık / pil cebi
    G.append(box((0, -0.172, 1.68), (0.06, 0.006, 0.03), "team"))                         # strob
else:
    # 6B47: kumaş kask örtüsü dikişleri + arkada iz bandı
    G.append(ring((0, -0.012, 1.69), 0.131, 0.145, 0.006, "pack", seg=28, t=0.006))
    G.append(ring((0, -0.012, 1.73), 0.115, 0.13, 0.006, "pack", seg=28, t=0.006))
    G.append(box((0, -0.15, 1.69), (0.06, 0.012, 0.018), "team"))
G.append(ring((0, -0.012, 1.652), 0.13, 0.144, 0.01, "helmet", seg=28, t=0.012))
G.append(ring((0, -0.012, 1.716), 0.132, 0.146, 0.018, "dark", seg=28, t=0.007))
G.append(blob((0, 0.118, 1.722), (0.09, 0.028, 0.032), "dark", seg=16))
for s in (-1, 1):
    G.append(blob((s * 0.043, 0.138, 1.724), (0.038, 0.011, 0.024), "lens", seg=14))
for s in (-1, 1):
    G.append(box((s * 0.088, 0.03, 1.565), (0.006, 0.012, 0.09), "dark", rot=(0.4, 0, 0)))  # çene kayışı
    G.append(blob((s * 0.1, 0.0, 1.615), (0.026, 0.044, 0.05), "dark", seg=16))            # aktif kulaklık
    G.append(cyl((s * 0.124, 0.0, 1.615), 0.03, 0.012, "pack", rot=(0, math.pi / 2, 0), seg=14))
G.append(box((-0.095, 0.075, 1.57), (0.01, 0.1, 0.01), "dark", rot=(0, 0, math.radians(18))))   # mikrofon kolu
G.append(blob((-0.08, 0.125, 1.565), (0.012, 0.012, 0.012), "dark", seg=8))
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
# kummerbund: yanlarda MOLLE şeritleri (yatay dokuma bantlar)
for s in (-1, 1):
    for k in range(4):
        G.append(box((s * 0.2, 0.0, 1.1 + k * 0.05), (0.012, 0.21, 0.012), "dark"))
    G.append(box((s * 0.215, -0.02, 1.19), (0.035, 0.1, 0.13), "vest", bev=0.008))       # yan cep (el bombası/telsiz)
# ön plakada MOLLE + alt sıra şarjör cepleri (3) — üstten taşan şarjörler, açık kapaklar
for k in range(3):
    G.append(box((0, 0.172, 1.2 + k * 0.05), (vest_w * 0.8, 0.008, 0.01), "dark"))
for x in (-0.1, 0.0, 0.1):
    G.append(box((x, 0.183, 1.155), (0.07, 0.045, 0.12), "vest", bev=0.008))
    G.append(box((x, 0.19, 1.232), (0.034 if USA else 0.042, 0.03, 0.05), "gun", rot=(0.12, 0, 0)))   # şarjör ucu
    G.append(box((x, 0.19, 1.26), (0.036 if USA else 0.044, 0.032, 0.008), "dark"))                  # dip kapak
    G.append(box((x, 0.208, 1.2), (0.072, 0.012, 0.03), "dark"))                                       # şok kordonu
# idari cep (harita paneli) + iki el bombası cebi
G.append(box((0, 0.18, 1.33), (0.15, 0.03, 0.08), "vest", bev=0.008))
G.append(box((0, 0.197, 1.345), (0.11, 0.004, 0.05), "team"))
for s in (-1, 1):
    G.append(cyl((s * 0.14, 0.175, 1.24), 0.03, 0.08, "vest", seg=12))
    G.append(cyl((s * 0.14, 0.175, 1.285), 0.031, 0.012, "dark", seg=12))
# telsiz (sol arka-yan) + kırbaç anten + PTT kablosu
G.append(box((0.19, -0.1, 1.3), (0.04, 0.06, 0.14), "dark", bev=0.006))
G.append(cyl((0.19, -0.1, 1.55), 0.004, 0.4, "dark", seg=6, rot=(0.15, 0, 0)))
G.append(cyl((0.19, -0.1, 1.38), 0.012, 0.03, "gun", seg=8))
G.append(skin_tube([(0.19, -0.07, 1.36), (0.15, 0.06, 1.45), (0.11, 0.13, 1.42)], [(0.006, 0.006)] * 3, "dark", sub=1))
G.append(box((0.11, 0.135, 1.42), (0.03, 0.012, 0.035), "dark", bev=0.004))        # PTT düğmesi
# sağ omuz askısında turnike + sol omuzda ışık
G.append(box((-0.115, 0.13, 1.38), (0.03, 0.03, 0.09), "dark", bev=0.006))
G.append(box((-0.115, 0.146, 1.42), (0.034, 0.008, 0.012), "red"))
G.append(cyl((0.115, 0.13, 1.39), 0.012, 0.04, "gun", seg=10))
# hidrasyon hortumu: çantadan omuz üstünden göğse
G.append(skin_tube([(-0.08, -0.2, 1.42), (-0.1, -0.05, 1.47), (-0.11, 0.1, 1.42), (-0.1, 0.16, 1.33)], [(0.009, 0.009)] * 4, "dark", sub=1))
G.append(box((0.1, 0.162, 1.42), (0.03, 0.025, 0.07), "dark", bev=0.005))              # ikinci telsiz/GPS
# ---------------- saldırı çantası: gövde + kapak + sıkıştırma kayışları + uyku tulumu rulosu + katlanır kürek
G.append(box((0, -0.26, 1.24), (0.3, 0.15, 0.34), "pack", bev=0.022))
G.append(box((0, -0.255, 1.405), (0.28, 0.14, 0.05), "pack", bev=0.012))               # kapak
G.append(box((0, -0.27, 1.05), (0.25, 0.12, 0.13), "pack", bev=0.015))                 # alt cep
G.append(box((0, -0.33, 1.27), (0.17, 0.03, 0.15), "pack", bev=0.01))                  # ön cep
for k in range(3):
    G.append(box((0, -0.347, 1.22 + k * 0.035), (0.15, 0.006, 0.008), "dark"))          # ön cep MOLLE
for s in (-1, 1):
    G.append(box((s * 0.158, -0.24, 1.2), (0.035, 0.1, 0.16), "pack", bev=0.01))        # yan cepler
    G.append(box((s * 0.07, -0.335, 1.25), (0.02, 0.01, 0.36), "dark"))                 # dikey kayış
    G.append(box((s * 0.07, -0.338, 1.12), (0.026, 0.012, 0.02), "gun"))                # toka
    for z in (1.15, 1.32):
        G.append(box((s * 0.15, -0.26, z), (0.012, 0.16, 0.014), "dark"))              # sıkıştırma kayışı
# uyku tulumu rulosu (üstte enine)
G.append(cyl((0, -0.26, 1.465), 0.055, 0.32, "canvas" if USA else "pack", rot=(0, math.pi / 2, 0), seg=16))
for s in (-1, 1):
    G.append(ring((s * 0.1, -0.26, 1.465), 0.057, 0.057, 0.02, "dark", seg=14))
# katlanır kürek (sağ yanda)
G.append(box((-0.19, -0.27, 1.22), (0.012, 0.03, 0.22), "gun", bev=0.003))
G.append(box((-0.19, -0.27, 1.08), (0.012, 0.1, 0.12), "gun", bev=0.01))
# matara (sol bel)
GEAR["pelvis"].append(cyl((0.2, -0.06, 0.94), 0.04, 0.13, "pack", seg=14))
GEAR["pelvis"].append(cyl((0.2, -0.06, 1.015), 0.018, 0.02, "dark", seg=10))
# dökme cebi (sağ arka)
GEAR["pelvis"].append(box((-0.17, -0.1, 0.92), (0.05, 0.1, 0.12), "vest", bev=0.015))
# ---------------- kemer
GEAR["pelvis"].append(skin_tube([(0, 0, 0.95), (0, 0, 1.0)], [(0.177, 0.13), (0.177, 0.13)], "dark", sub=2))
GEAR["pelvis"].append(box((0, 0.134, 0.975), (0.05, 0.012, 0.035), "gun"))           # toka
GEAR["pelvis"].append(box((0.16, -0.03, 0.95), (0.04, 0.06, 0.08), "pack", bev=0.01))  # bel cebi
GEAR["pelvis"].append(box((-0.16, 0.02, 0.95), (0.035, 0.05, 0.07), "vest", bev=0.01))

# ---------------- yan teçhizat: sağ uylukta tabanca kılıfı + tabanca kabzası, yelekte bıçak, belde IFAK (sargı) çantası
GEAR["leg_r"].append(box((-0.2, 0.02, 0.78), (0.045, 0.09, 0.16), "dark", bev=0.01))            # kılıf
GEAR["leg_r"].append(box((-0.2, -0.005, 0.875), (0.035, 0.05, 0.07), "gun", bev=0.006))           # kabza
GEAR["leg_r"].append(ring((-0.1, 0.0, 0.72), 0.115, 0.12, 0.02, "dark", seg=16))
G.append(box((-0.11, 0.2, 1.3), (0.03, 0.022, 0.16), "dark", rot=(0, 0, 0.35), bev=0.005))           # bıçak kını
G.append(box((-0.135, 0.205, 1.4), (0.022, 0.025, 0.06), "gun", rot=(0, 0, 0.35), bev=0.004))        # bıçak sapı
GEAR["pelvis"].append(box((0.0, -0.15, 0.97), (0.14, 0.05, 0.08), "pack", bev=0.012))               # IFAK
GEAR["pelvis"].append(box((0.0, -0.177, 0.975), (0.035, 0.006, 0.035), "team"))                     # haç işareti

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
    GEAR["fore_" + n].append(box(armpt(s, UA + FA + 0.07, -0.022, 0.0), (0.05, 0.012, 0.022), "dark", rot=rot, bev=0.004))   # boğum pedi


# ---------------- bacaklar: kargo cebi (kapaklı), kırışıklar, dizlik + kayış, paça, bot (bağcık + dişli taban)
for s, n in ((-1, "r"), (1, "l")):
    x = s * 0.1
    GEAR["leg_" + n].append(box((x + s * 0.095, 0.02, 0.7), (0.04, 0.11, 0.15), "uniform", bev=0.01))
    GEAR["leg_" + n].append(box((x + s * 0.117, 0.02, 0.77), (0.012, 0.115, 0.038), "uniform", bev=0.004))     # cep kapağı
    GEAR["leg_" + n].append(box((x + s * 0.124, 0.02, 0.757), (0.004, 0.03, 0.01), "dark"))                     # düğme/cırt
    GEAR["knee_" + n].append(blob((x, 0.075, 0.47), (0.052, 0.03, 0.062), "rubber", seg=18))
    GEAR["knee_" + n].append(box((x, 0.1, 0.47), (0.04, 0.008, 0.04), "dark", bev=0.005))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.5), 0.086, 0.09, 0.014, "dark", seg=12))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.44), 0.08, 0.086, 0.014, "dark", seg=12))
    GEAR["knee_" + n].append(ring((x, 0.0, 0.235), 0.066, 0.07, 0.03, "uniform", seg=14, t=0.008))             # pantolon paçası (bot üstüne)
    # bot: konç + gövde + burun + bağcık sırası + topuk + dişli taban
    GEAR["knee_" + n].append(cyl((x, 0.0, 0.16), 0.064, 0.12, "boot", seg=14, r2=0.062))
    GEAR["knee_" + n].append(box((x, 0.035, 0.058), (0.11, 0.19, 0.095), "boot", bev=0.032))
    GEAR["knee_" + n].append(blob((x, 0.12, 0.042), (0.055, 0.058, 0.038), "boot", seg=18))
    for k in range(5):
        GEAR["knee_" + n].append(box((x, 0.06 + 0.012 * k, 0.11 + k * 0.022), (0.05, 0.006, 0.006), "dark"))
    GEAR["knee_" + n].append(box((x, -0.06, 0.04), (0.11, 0.03, 0.06), "boot", bev=0.012))
    GEAR["knee_" + n].append(box((x, 0.05, 0.008), (0.122, 0.26, 0.022), "rubber", bev=0.004))
    for k in range(6):
        GEAR["knee_" + n].append(box((x, -0.07 + k * 0.045, -0.004), (0.114, 0.014, 0.008), "dark"))             # taban dişi
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
print("BLENDER V5 OK", OUT)
