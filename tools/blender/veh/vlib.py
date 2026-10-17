# Blender araç kütüphanesi: sert yüzey parçaları (faset stil, ince pah kırılmış kenarlar).
# Koordinat: Blender Z yukarı, +Y ileri (glTF'te -Z), +X sağ. Birim: metre (gerçek ölçek).
# Düğümler: body (0,0,0), turret (taret halkası), barrel (muylu). Malzeme adları oyundaki Art.material ile eşleşir:
#   paint_<ulus>, trim_<ulus>, metal, gun, track, rubber, glass, dark, light, lens, red, mark, canvas, wood
# Çekirdek: her parça doğrudan bmesh ile kurulur (bpy.ops yok → hızlı), düğüm × malzeme başına tek bmesh'e eklenir.
# Dışa aktarımda: kutu izdüşümü UV, açıya göre keskin kenar, ışın izlemeli ortam kapanması (AO) köşe rengine pişirilir.
import bpy, bmesh, math
from mathutils import Vector, Matrix, Euler
from mathutils.bvhtree import BVHTree

NAT = "usa"
COLS = {"paint": (0.55, 0.5, 0.36), "trim": (0.42, 0.38, 0.28), "metal": (0.35, 0.35, 0.34), "track": (0.12, 0.12, 0.11),
        "rubber": (0.06, 0.06, 0.06), "glass": (0.05, 0.08, 0.1), "dark": (0.06, 0.06, 0.06), "light": (1, 0.95, 0.8),
        "mark": (0.9, 0.9, 0.9), "canvas": (0.45, 0.42, 0.3), "red": (0.6, 0.05, 0.03), "lens": (0.9, 0.45, 0.05),
        "gun": (0.15, 0.15, 0.15), "wood": (0.42, 0.26, 0.14),
        "airgray": (0.6, 0.62, 0.63)}   # hava aracı açık gri boyası (İHA) — oyunda Art.material("airgray")
_M = {}
NODES = {"body": {}, "turret": {}, "barrel": {}}
CUR = "body"
WHEELS = []
ROT_NB = []                    # rotor pal sayıları (meta 'nb': oyunda dönüş görüntüsü bundan ayarlanır)
EXTRA_PIVOTS = {}              # ayrı dönen parçaların pivotları (İHA pervaneleri: propy_N / propz_N)
DOOR = {}                      # (79) arka rampa / kapak: {'pivot': menteşe, 'open': açılma açısı (rad)} → pivot 'door', meta 'door_open'
_TMP = None
SHARP = math.radians(14)       # düz parçalarda keskin kenar eşiği
SMOOTH = math.radians(33)      # silindir / loft gövdelerde (12+ dilim yumuşak görünür)

def reset(nat):
    global NAT, CUR, _TMP
    NAT = nat
    CUR = "body"
    for k, d in NODES.items():
        for b in d.values():
            b.free()
    NODES.clear()
    NODES.update({"body": {}, "turret": {}, "barrel": {}})
    _M.clear()
    WHEELS.clear()
    ROT_NB.clear()
    EXTRA_PIVOTS.clear()
    DOOR.clear()
    bpy.ops.wm.read_factory_settings(use_empty=True)
    _TMP = bpy.data.meshes.new("_tmp")

def node(n):
    global CUR
    CUR = n
    NODES.setdefault(n, {})

def clear_node(n):
    for b in NODES.get(n, {}).values():
        b.free()
    NODES[n] = {}

def mat(n):
    full = n + "_" + NAT if n in ("paint", "trim") else n
    if full not in _M:
        m = bpy.data.materials.new(full)
        m.use_nodes = True
        b = m.node_tree.nodes.get("Principled BSDF")
        if b:
            b.inputs["Base Color"].default_value = (*COLS.get(n, (0.5, 0.5, 0.5)), 1)
            b.inputs["Roughness"].default_value = 0.7
        _M[full] = m
    return _M[full]

def _bev_amount(bev, m):
    """İnce, tek kademeli pah: büyük levhalarda ışığı yakalayacak kadar, küçük parçada orantılı."""
    if bev <= 0:
        return 0.0
    cap = 0.022 if m > 0.6 else (0.014 if m > 0.25 else 0.009)
    return min(max(bev, 0.006), cap, m * 0.14)

def _add(bm, mname, bev=0.0, thr=SHARP):
    """Parça bmesh'ini (dünya koordinatında) etkin düğümün malzeme kovasına ekle."""
    if bev > 0:
        es = [e for e in bm.edges if e.is_manifold and e.calc_face_angle(0.0) > math.radians(30)]
        if es:
            bmesh.ops.bevel(bm, geom=es, offset=bev, offset_type='OFFSET', segments=1, profile=0.5,
                            affect='EDGES', clamp_overlap=True)
    for f in bm.faces:
        f.smooth = True
    for e in bm.edges:
        e.smooth = (not e.is_manifold) or e.calc_face_angle(0.0) < thr
    bm.to_mesh(_TMP)
    bm.free()
    tgt = NODES[CUR].get(mname)
    if tgt is None:
        tgt = NODES[CUR][mname] = bmesh.new()
    tgt.from_mesh(_TMP)
    return True

def _xf(bm, loc, rot=None, scale=None):
    M = Matrix.Translation(Vector(loc))
    if rot is not None:
        M = M @ (rot.to_4x4() if isinstance(rot, Matrix) else Euler(rot).to_matrix().to_4x4())
    if scale is not None:
        M = M @ Matrix.Diagonal((*scale, 1.0))
    bmesh.ops.transform(bm, matrix=M, verts=bm.verts)

def box(loc, size, mname="paint", rot=(0, 0, 0), bev=0.02):
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    _xf(bm, loc, rot, size)
    return _add(bm, mname, _bev_amount(bev, min(size)))

_AX = {"Z": (0, 0, 0), "X": (0, math.pi / 2, 0), "Y": (math.pi / 2, 0, 0)}

def cyl(loc, r, depth, mname="metal", axis="Z", seg=16, r2=None, bev=0.0, rot=None):
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=depth)
    _xf(bm, loc, rot if rot is not None else _AX[axis])
    return _add(bm, mname, _bev_amount(bev, min(r, depth)) if bev > 0 else 0.0, SMOOTH if seg >= 12 else SHARP)

def poly_extrude_x(profile, x0, x1, mname="paint", bev=0.02):
    """YZ düzleminde çokgen (y,z) → X boyunca x0..x1 katı."""
    bm = bmesh.new()
    a = [bm.verts.new((x0, y, z)) for y, z in profile]
    b = [bm.verts.new((x1, y, z)) for y, z in profile]
    n = len(profile)
    bm.faces.new(a[::-1]); bm.faces.new(b)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _add(bm, mname, min(bev, 0.02))

def loft(sections, mname="paint", bev=0.02, cap=True):
    """sections: [(y, [(x,z), ...])] — her kesit aynı nokta sayısında, x>=0 yarım profil (alt merkezden üst merkeze);
    X'e göre aynalanır. Uçlar kapatılır."""
    bm = bmesh.new()
    rings = []
    for y, half in sections:
        pts = list(half) + [(-x, z) for x, z in reversed(half)][1:-1] if half[0][0] == 0 and half[-1][0] == 0 else list(half) + [(-x, z) for x, z in reversed(half)]
        rings.append([bm.verts.new((x, y, z)) for x, z in pts])
    for r1, r2 in zip(rings, rings[1:]):
        n = len(r1)
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((r1[i], r1[j], r2[j], r2[i]))
    if cap:
        bm.faces.new(rings[0][::-1]); bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _add(bm, mname, min(bev, 0.02), SMOOTH)

def hull_pts(pts, mname="paint", bev=0.02, thr=SHARP):
    """Dışbükey gövde (nokta bulutundan)."""
    bm = bmesh.new()
    for p in pts:
        bm.verts.new(p)
    bmesh.ops.convex_hull(bm, input=bm.verts)
    # iç (yüzsüz) noktaları at
    loose = [v for v in bm.verts if not v.link_faces]
    if loose:
        bmesh.ops.delete(bm, geom=loose, context='VERTS')
    bmesh.ops.dissolve_limit(bm, angle_limit=math.radians(0.5), verts=bm.verts, edges=bm.edges)
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return _add(bm, mname, min(bev, 0.02), thr)

# ------------------------------------------------------------ yardımcı geometri: çubuk, kiriş, halka, yerel çerçeve
def rod(p0, p1, r, mname="metal", seg=6):
    """p0→p1 arası silindir çubuk."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    L = d.length
    if L < 1e-5:
        return
    q = d.normalized().to_track_quat('Z', 'Y')
    bm = bmesh.new()
    bmesh.ops.create_cone(bm, cap_ends=True, cap_tris=False, segments=seg, radius1=r, radius2=r, depth=L)
    _xf(bm, (p0 + p1) * 0.5, q.to_matrix())
    return _add(bm, mname, 0.0, SMOOTH if seg >= 8 else SHARP)

def bar(p0, p1, w, h, mname="metal", up=(0, 0, 1)):
    """p0→p1 arası dikdörtgen kesitli kiriş (w yatay, h 'up' yönünde)."""
    p0, p1 = Vector(p0), Vector(p1)
    d = p1 - p0
    L = d.length
    if L < 1e-5:
        return
    y = d.normalized()
    u = Vector(up)
    x = y.cross(u)
    if x.length < 1e-4:
        x = y.cross(Vector((1, 0, 0)))
    x.normalize()
    z = x.cross(y)
    R = Matrix((x, y, z)).transposed()
    bm = bmesh.new()
    bmesh.ops.create_cube(bm, size=1.0)
    _xf(bm, (p0 + p1) * 0.5, R, (w, L, h))
    return _add(bm, mname, 0.0)

def ring(loc, R, r, mname="metal", axis="Z", seg=10, tseg=4, rot=None):
    """Halka (torus): çekme gözü, kaldırma halkası, kablo gözü."""
    bm = bmesh.new()
    rings = []
    for i in range(seg):
        a = i * math.tau / seg
        c = Vector((math.cos(a) * R, math.sin(a) * R, 0))
        n = Vector((math.cos(a), math.sin(a), 0))
        rings.append([bm.verts.new(c + n * math.cos(b) * r + Vector((0, 0, math.sin(b) * r)))
                      for b in (k * math.tau / tseg for k in range(tseg))])
    for i in range(seg):
        r1, r2 = rings[i], rings[(i + 1) % seg]
        for k in range(tseg):
            kk = (k + 1) % tseg
            bm.faces.new((r1[k], r2[k], r2[kk], r1[kk]))
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    _xf(bm, loc, rot if rot is not None else _AX[axis])
    return _add(bm, mname, 0.0, SMOOTH)

class F:
    """Yerel çerçeve: parçaları yerel koordinatta tanımlayıp döndürülmüş/taşınmış olarak ekler."""
    def __init__(s, p, rot=(0, 0, 0)):
        s.p = Vector(p)
        s.R = rot if isinstance(rot, Matrix) else Euler(rot).to_matrix()
    def P(s, l):
        return s.p + s.R @ Vector(l)
    def E(s, rot=(0, 0, 0)):
        return (s.R @ Euler(rot).to_matrix()).to_euler()
    def box(s, l, size, m="paint", rot=(0, 0, 0), bev=0.0):
        return box(s.P(l), size, m, rot=s.E(rot), bev=bev)
    def cyl(s, l, r, d, m="metal", axis="Z", seg=12, r2=None, rot=None, bev=0.0):
        return cyl(s.P(l), r, d, m, seg=seg, r2=r2, rot=s.E(rot if rot is not None else _AX[axis]), bev=bev)
    def rod(s, a, b, r, m="metal", seg=6):
        return rod(s.P(a), s.P(b), r, m, seg)
    def bar(s, a, b, w, h, m="metal", up=(0, 0, 1)):
        return bar(s.P(a), s.P(b), w, h, m, s.R @ Vector(up))
    def ring(s, l, R, r, m="metal", axis="Z", seg=10, tseg=4):
        return ring(s.P(l), R, r, m, seg=seg, tseg=tseg, rot=s.E(_AX[axis]))

def face_frame(p, normal, yaw=0.0):
    """Yüzeye yaslı çerçeve: yerel +Z = yüzey normali, yerel +Y = uzun eksen (yatay/yan yüzde araç ileri yönü, ön/arka yüzde yukarı)."""
    z = Vector(normal).normalized()
    ref = Vector((0, 1, 0)) if abs(z.y) < 0.9 else Vector((0, 0, 1))
    x = ref.cross(z).normalized()
    y = z.cross(x)
    return F(p, Matrix((x, y, z)).transposed() @ Euler((0, 0, yaw)).to_matrix())

# ------------------------------------------------------------ küçük ayrıntılar: cıvata, kaynak, panel çizgisi, tutamak
def bolt(p, normal=(0, 0, 1), r=0.018, h=0.016, m="trim"):
    """Altıgen cıvata başı (yüzeye yaslı)."""
    f = face_frame(p, normal)
    f.cyl((0, 0, h * 0.5), r, h, m, seg=6)

def bolt_row(p0, p1, n, normal=(0, 0, 1), r=0.018, m="trim"):
    p0, p1 = Vector(p0), Vector(p1)
    for i in range(n):
        t = (i + 0.5) / n
        bolt(p0.lerp(p1, t), normal, r, m=m)

def weld(p0, p1, w=0.025, m="trim"):
    """Kaynak dikişi: iki levha birleşiminde ince kabarık şerit."""
    bar(p0, p1, w, w * 0.6, m)

def seam(p0, p1, normal=(0, 0, 1), w=0.014, m="dark"):
    """Panel çizgisi: yüzeyde çok ince koyu oluk (yüzeyden hafif taşar)."""
    n = Vector(normal) * 0.003
    bar(Vector(p0) + n, Vector(p1) + n, w, 0.008, m, up=normal)

def grab_handle(p, along=(1, 0, 0), normal=(0, 0, 1), L=0.3, h=0.07, r=0.011, m="metal"):
    """U tutamak: iki ayak + üst çubuk."""
    p, a, n = Vector(p), Vector(along).normalized(), Vector(normal).normalized()
    p0, p1 = p - a * L * 0.5, p + a * L * 0.5
    q0, q1 = p0 + n * h, p1 + n * h
    rod(p0, q0, r, m, 5); rod(q0, q1, r, m, 5); rod(q1, p1, r, m, 5)

def tiedown(p, normal=(0, 0, 1)):
    """Bağlama / kaldırma halkası: taban + D halka."""
    f = face_frame(p, normal)
    f.box((0, 0, 0.012), (0.08, 0.06, 0.024), "trim")
    f.ring((0, 0, 0.05), 0.035, 0.009, "metal", axis="X", seg=8, tseg=4)

def lift_eye(p, normal=(0, 0, 1), yaw=0.0):
    """Kaldırma gözü (kalın plaka + delik halkası)."""
    f = face_frame(p, normal, yaw)
    f.box((0, 0, 0.05), (0.04, 0.12, 0.1), "paint", bev=0.01)
    f.ring((0, 0, 0.07), 0.03, 0.01, "metal", axis="X", seg=8, tseg=4)

# ------------------------------------------------------------ yürüyen aksam
def road_wheel(x, y, z, r, w, side, holes=6, rim="paint"):
    """İkiz yol tekeri: iki lastik bandajlı disk, aradaki boşlukta palet kılavuz dişleri koşar; göbek + somunlar."""
    s = side
    hw = w * 0.42
    for o in (1, -1):
        xo = x + s * o * (w * 0.5 - hw * 0.5)
        cyl((xo, y, z), r, hw, "rubber", "X", seg=20)
        cyl((xo + s * o * hw * 0.5, y, z), r * 0.84, 0.03, rim, "X", seg=20)
    xo = x + s * (w * 0.5 + 0.015)
    cyl((xo, y, z), r * 0.7, 0.025, rim, "X", seg=16)                                 # dış disk çıkıntısı
    for k in range(holes):
        a = k * math.tau / max(holes, 1) + 0.3
        cyl((xo + s * 0.006, y + math.cos(a) * r * 0.5, z + math.sin(a) * r * 0.5), r * 0.12, 0.02, "dark", "X", seg=8)
    cyl((xo + s * 0.025, y, z), r * 0.3, 0.05, "metal", "X", seg=10)
    cyl((xo + s * 0.055, y, z), r * 0.16, 0.03, "metal", "X", seg=8)
    for k in range(6):
        a = k * math.tau / 6
        cyl((xo + s * 0.045, y + math.cos(a) * r * 0.22, z + math.sin(a) * r * 0.22), 0.016, 0.03, "metal", "X", seg=6)

def idler(x, y, z, r, w, side):
    s = side
    for o in (1, -1):
        cyl((x + s * o * w * 0.3, y, z), r, w * 0.36, "paint", "X", seg=18)
    cyl((x + s * w * 0.5, y, z), r * 0.75, 0.02, "paint", "X", seg=16)
    for k in range(6):
        a = k * math.tau / 6
        cyl((x + s * (w * 0.5 + 0.005), y + math.cos(a) * r * 0.48, z + math.sin(a) * r * 0.48), r * 0.13, 0.02, "dark", "X", seg=8)
    cyl((x + s * (w * 0.5 + 0.02), y, z), r * 0.3, 0.05, "metal", "X", seg=10)
    for k in range(5):
        a = k * math.tau / 5
        cyl((x + s * (w * 0.5 + 0.045), y + math.cos(a) * r * 0.2, z + math.sin(a) * r * 0.2), 0.014, 0.025, "metal", "X", seg=6)

def sprocket(x, y, z, r, w, side, teeth=11):
    """Çift dişli çember (palet pimlerini kavrar) + göbek + somun çemberi."""
    s = side
    for o in (1, -1):
        xo = x + s * o * w * 0.3
        cyl((xo, y, z), r * 0.88, w * 0.18, "metal", "X", seg=22)
        for k in range(teeth):
            a = (k + 0.5 * (o > 0)) * math.tau / teeth
            box((xo, y + math.cos(a) * r * 0.93, z + math.sin(a) * r * 0.93), (w * 0.18, 0.07, 0.09), "metal", rot=(a, 0, 0), bev=0.0)
    cyl((x, y, z), r * 0.6, w * 0.7, "paint", "X", seg=16)
    cyl((x + s * w * 0.42, y, z), r * 0.55, 0.03, "paint", "X", seg=16)
    cyl((x + s * w * 0.48, y, z), r * 0.32, 0.08, "dark", "X", seg=12)
    for k in range(8):
        a = k * math.tau / 8
        cyl((x + s * w * 0.46, y + math.cos(a) * r * 0.44, z + math.sin(a) * r * 0.44), 0.017, 0.04, "metal", "X", seg=6)

def _link(bm, M, w, link, guide=True, grouser=True):
    """Tek palet baklası (yerel: X genişlik, Y yol yönü, +Z içe / tekerlere bakan yüz, -Z dış yüz).
    Gövde plakası + dış yüzde tırnak (grouser) + iç yüzde kılavuz diş + iki uçta bağlantı kıskaçları."""
    parts = [(0, 0, 0, w, link * 0.84, 0.05)]
    if grouser:
        parts.append((0, -link * 0.12, -0.04, w * 0.96, link * 0.22, 0.035))        # tırnak
    if guide:
        parts.append((0, 0, 0.065, 0.07, link * 0.42, 0.09))                         # kılavuz diş
    parts.append((w * 0.5 + 0.015, 0, 0, 0.03, link * 0.5, 0.06))                  # uç bağlantı kıskacı
    parts.append((-w * 0.5 - 0.015, 0, 0, 0.03, link * 0.5, 0.06))
    for (cx, cy, cz, sx, sy, sz) in parts:
        g = bmesh.ops.create_cube(bm, size=1.0)
        for v in g["verts"]:
            v.co = M @ Vector((v.co.x * sx + cx, v.co.y * sy + cy, v.co.z * sz + cz))

def _track_path(poly, x, w, link):
    segs = []
    tot = 0.0
    for a, b in zip(poly, poly[1:]):
        L = math.hypot(b[0] - a[0], b[1] - a[1])
        if L > 1e-5:
            segs.append((a, b, L)); tot += L
    n = max(8, int(tot / link))
    step = tot / n
    # yön: saat yönündeyse (alan < 0) yerel +Z dışa bakar → Y etrafında çevir ki +Z hep içe baksın
    area = sum(a[0] * b[1] - b[0] * a[1] for a, b in zip(poly, poly[1:]))
    flip = Matrix.Rotation(math.pi, 4, 'Y') if area < 0 else Matrix.Identity(4)
    bm = bmesh.new()
    si = 0; acc = 0.0
    for i in range(n):
        t = i * step
        while si < len(segs) - 1 and acc + segs[si][2] < t:
            acc += segs[si][2]; si += 1
        a, b, L = segs[si]
        f = (t - acc) / L
        y = a[0] + (b[0] - a[0]) * f; z = a[1] + (b[1] - a[1]) * f
        ang = math.atan2(b[1] - a[1], b[0] - a[0])
        M = Matrix.Translation((x, y, z)) @ Matrix.Rotation(ang, 4, 'X') @ flip
        # zemine bakan alt koşuda tırnak görünmez → atla (üçgen tasarrufu)
        outz = (M.to_3x3() @ Vector((0, 0, -1))).z
        _link(bm, M, w, step, grouser=outz > -0.7)
    return bm

def track_loop(x, w, y_front, y_rear, r_front, r_rear, z_bottom=0.0, z_top=None, z_f=None, z_r=None, link=0.17):
    """Tek tek palet baklaları: alt düz + arka dişli yayı + üst dönüş + ön avara yayı."""
    z_f = z_f if z_f is not None else z_bottom + r_front
    z_r = z_r if z_r is not None else z_bottom + r_rear
    z_top = z_top if z_top is not None else max(z_f + r_front, z_r + r_rear) - 0.02
    path = []
    def arc(cy, cz, r, a0, a1, n):
        for i in range(n + 1):
            a = a0 + (a1 - a0) * i / n
            path.append((cy + math.cos(a) * r, cz + math.sin(a) * r))
    path.append((y_front, z_bottom)); path.append((y_rear, z_bottom))
    arc(y_rear, z_r, r_rear, -math.pi / 2, -math.pi * 1.5, 10)
    path.append((y_front, z_top))
    arc(y_front, z_f, r_front, math.pi / 2, -math.pi / 2, 10)
    return _add(_track_path(path, x, w, link), "track", 0.0)

def _hull2d(pts):
    pts = sorted(set(pts))
    def cross(o, a, b):
        return (a[0] - o[0]) * (b[1] - o[1]) - (a[1] - o[1]) * (b[0] - o[0])
    lo, up = [], []
    for p in pts:
        while len(lo) >= 2 and cross(lo[-2], lo[-1], p) <= 0:
            lo.pop()
        lo.append(p)
    for p in reversed(pts):
        while len(up) >= 2 and cross(up[-2], up[-1], p) <= 0:
            up.pop()
        up.append(p)
    return lo[:-1] + up[:-1]

def track_hull(x, w, circles, link=0.17, th=0.03):
    """Palet: tekerlek/avara/dişli çemberlerinin dışbükey zarfı boyunca tek tek baklalar."""
    smp = []
    for (cy, cz, r) in circles:
        for k in range(36):
            a = k * math.tau / 36
            smp.append((round(cy + math.cos(a) * (r + th), 4), round(cz + math.sin(a) * (r + th), 4)))
    poly = _hull2d(smp)
    poly.append(poly[0])
    return _add(_track_path(poly, x, w, link), "track", 0.0)

def running_gear(xc, w, wheels_y, r, y_front, y_rear, r_idler, r_spr, z_top_run=None, rollers_y=(), sprocket_rear=True, holes=6, shocks=True):
    """y_front: avara (ön/arka fark etmez), y_rear: dişli. Avara ve dişli palet üst hattına hizalanır."""
    zt = z_top_run if z_top_run else 2 * r + 0.12
    zi = max(r_idler + 0.04, zt - r_idler - 0.03)
    zs = max(r_spr + 0.04, zt - r_spr - 0.03)
    for s in (-1, 1):
        x = s * xc
        for y in wheels_y:
            road_wheel(x, y, r, r, w * 0.82, s, holes)
        idler(x, y_front, zi, r_idler, w * 0.8, s)
        sprocket(x, y_rear, zs, r_spr, w * 0.8, s)
        for y in rollers_y:
            cyl((x, y, zt - 0.06), 0.075, w * 0.5, "rubber", "X", seg=12)
            cyl((x + s * w * 0.27, y, zt - 0.06), 0.05, 0.03, "metal", "X", seg=8)
        circles = [(y, r, r) for y in wheels_y] + [(y_front, zi, r_idler), (y_rear, zs, r_spr)]
        track_hull(x, w, circles)
        # süspansiyon kolları (iç tarafta) + tampon takozları
        for y in wheels_y:
            box((s * (xc - w * 0.55), y + 0.18, r + 0.06), (0.06, 0.4, 0.08), "metal", rot=(0.35, 0, 0), bev=0.0)
            box((s * (xc - w * 0.45), y + 0.05, r * 2 + 0.03), (0.1, 0.14, 0.06), "rubber", bev=0.0)
        if shocks and len(wheels_y) > 2:
            for y in (wheels_y[0], wheels_y[1], wheels_y[-1]):
                rod((s * (xc - w * 0.62), y + 0.05, r + 0.05), (s * (xc - w * 0.62), y + 0.35, r * 2 + 0.05), 0.035, "metal", 8)

# ------------------------------------------------------------ teçhizat
def hatch(x, y, z, r=0.3, open_=False, peri=0, yaw=0.0):
    """Kapak: kaldırılmış çember taban + kapak (merkezde takviye plakası) + menteşe + tutamak + kilit kolu."""
    f = F((x, y, z), (0, 0, yaw))
    f.cyl((0, 0, 0.03), r + 0.05, 0.06, "paint", seg=16, bev=0.008)
    f.cyl((0, 0, 0.075), r, 0.04, "paint", seg=16, bev=0.006)
    f.cyl((0, 0, 0.1), r * 0.62, 0.02, "trim", seg=12)
    f.cyl((0, -r * 0.95, 0.085), 0.035, r * 0.9, "metal", axis="X", seg=8)             # menteşe
    for sx in (-1, 1):
        f.box((sx * r * 0.32, -r * 0.8, 0.1), (0.06, 0.2, 0.03), "trim")
    grab_handle(f.P((0, r * 0.62, 0.095)), f.R @ Vector((1, 0, 0)), f.R @ Vector((0, 0, 1)), L=r * 0.6, h=0.05, r=0.01)
    f.box((r * 0.55, 0.0, 0.11), (0.05, 0.16, 0.025), "metal")                          # kilit kolu
    for k in range(peri):
        a = math.pi * 0.25 + k * math.pi * 0.5
        periscope(*f.P((math.cos(a) * r * 0.55, math.sin(a) * r * 0.55, 0.08)), yaw=yaw + a - math.pi / 2, small=True)

def periscope(x, y, z, yaw=0.0, small=False):
    """Zırhlı periskop başı: taban + eğik başlık + cam + üstte yağmur siperi."""
    k = 0.75 if small else 1.0
    f = F((x, y, z), (0, 0, yaw))
    f.box((0, 0, 0.03 * k), (0.2 * k, 0.14 * k, 0.06 * k), "paint", bev=0.006)
    f.box((0, -0.01, 0.085 * k), (0.17 * k, 0.1 * k, 0.07 * k), "paint", rot=(-0.25, 0, 0), bev=0.006)
    f.box((0, 0.048 * k, 0.08 * k), (0.14 * k, 0.012, 0.045 * k), "glass", rot=(-0.25, 0, 0))
    f.box((0, 0.045 * k, 0.125 * k), (0.18 * k, 0.05 * k, 0.012), "trim")

def vision_block(x, y, z, yaw=0.0, w=0.22):
    """Gövde yan/ön görüş bloğu: gömme çerçeve + cam."""
    f = F((x, y, z), (0, 0, yaw))
    f.box((0, 0, 0), (w, 0.04, 0.12), "trim")
    f.box((0, 0.022, 0), (w * 0.75, 0.01, 0.07), "glass")
    f.box((0, 0.03, 0.075), (w * 1.05, 0.06, 0.015), "trim")

def smoke_launchers(x, y, z, yaw, n=6, side=1):
    """Sis bombası atar demeti: montaj plakası + sıra sıra tüpler (lastik ağız kapakları)."""
    f = F((x, y, z), (0, 0, yaw))
    f.box((0, 0, 0), (0.16, 0.36, 0.2), "paint", bev=0.012)
    f.box((-side * 0.06, 0, -0.12), (0.12, 0.3, 0.04), "trim")
    rows = 2 if n > 3 else 1
    per = (n + rows - 1) // rows
    for i in range(n):
        rr, c = divmod(i, per)
        oy = (c - (per - 1) / 2) * 0.1
        oz = (rr - (rows - 1) / 2) * 0.09
        tilt = math.pi / 2 + 0.35 * side
        f.cyl((0.09 * side, oy, oz + 0.02), 0.036, 0.2, "dark", rot=(0, tilt, 0), seg=8)
        d = Vector((math.sin(tilt) * 0.105, 0, math.cos(tilt) * 0.105))
        f.cyl((0.09 * side + d.x, oy, oz + 0.02 + d.z), 0.04, 0.02, "rubber", rot=(0, tilt, 0), seg=8)

def mg(x, y, z, yaw=0.0, L=1.1, heavy=False):
    """Makineli tüfek: gövde, soğutma ceketli namlu, alev gizleyici, taşıma kolu, kabza/çatal tutamak, şerit kutusu, beşik."""
    f = F((x, y, z), (0, 0, yaw))
    r = 0.03 if heavy else 0.018
    f.box((0, 0, 0), (0.11, 0.42 if heavy else 0.32, 0.13), "gun")                       # gövde
    f.box((0, -0.02, 0.075), (0.09, 0.25, 0.02), "gun")                                   # kapak
    f.cyl((0, 0.21 + L * 0.5, 0.02), r, L, "gun", axis="Y", seg=8)
    if heavy:
        f.cyl((0, 0.21 + L * 0.22, 0.02), r * 1.7, L * 0.42, "gun", axis="Y", seg=8)    # delikli ceket
        for k in range(3):
            f.box((0, 0.27 + k * L * 0.12, 0.02 + r * 1.8), (0.02, 0.05, 0.012), "dark")
    f.cyl((0, 0.21 + L + 0.04, 0.02), r * 1.3, 0.09, "gun", axis="Y", seg=8)            # alev gizleyici
    f.box((0, 0.12, 0.12), (0.025, 0.12, 0.05), "gun")                                   # taşıma kolu
    f.box((0, -0.23, -0.02), (0.13, 0.05, 0.12), "gun")                                  # arka plaka
    for sx in (-1, 1):
        f.cyl((sx * 0.045, -0.29, -0.03), 0.017, 0.12, "gun", seg=6, rot=(0.3, 0, 0))   # çatal tutamaklar
    f.box((-0.13, 0.0, -0.03), (0.13, 0.22, 0.16), "trim")                               # şerit kutusu
    f.box((-0.13, 0.0, 0.055), (0.135, 0.06, 0.015), "metal")
    f.box((-0.07, 0.02, 0.02), (0.04, 0.06, 0.03), "gun")                                # besleme
    f.box((0, 0.02, -0.1), (0.16, 0.18, 0.06), "gun")                                    # beşik
    f.cyl((0, 0.0, -0.17), 0.03, 0.12, "gun", seg=8)                                     # mesnet

def rws(x, y, z, heavy=True, low=False):
    """Uzaktan kumandalı silah istasyonu (CROWS tipi): döner taban, yan çatal, beşik, sensör kafası, mühimmat kutusu."""
    cyl((x, y, z + 0.05), 0.24, 0.1, "paint", seg=16, bev=0.006)
    for k in range(8):
        a = k * math.tau / 8
        cyl((x + math.cos(a) * 0.2, y + math.sin(a) * 0.2, z + 0.105), 0.012, 0.012, "trim", seg=6)
    h = 0.32 if not low else 0.22
    box((x, y - 0.02, z + 0.1 + h * 0.3), (0.42, 0.46, h * 0.6), "paint", bev=0.015)           # taban gövdesi
    for s in (-1, 1):
        box((x + s * 0.17, y + 0.04, z + 0.1 + h * 0.75), (0.05, 0.32, h * 0.6), "paint", bev=0.008)    # çatal kolları
    box((x + 0.26, y + 0.06, z + 0.12 + h * 0.7), (0.14, 0.26, 0.2), "paint", bev=0.012)              # sensör kafası
    for k, (dz, ww) in enumerate(((0.04, 0.08), (-0.04, 0.05))):
        box((x + 0.24 + k * 0.04, y + 0.195, z + 0.12 + h * 0.7 + dz), (ww, 0.012, 0.05), "glass", bev=0.0)
    box((x + 0.26, y + 0.12, z + 0.23 + h * 0.7), (0.15, 0.2, 0.012), "trim", bev=0.0)                 # güneşlik
    mg(x - 0.02, y + 0.12, z + 0.1 + h * 0.75, 0.0, 1.15, heavy)
    box((x - 0.26, y - 0.02, z + 0.12 + h * 0.6), (0.14, 0.38, 0.26), "trim", bev=0.01)                # mühimmat
    grab_handle((x - 0.26, y - 0.02, z + 0.25 + h * 0.6), (0, 1, 0), (0, 0, 1), L=0.18, h=0.04, r=0.008)
    rod((x - 0.18, y + 0.1, z + 0.18 + h * 0.6), (x - 0.06, y + 0.12, z + 0.12 + h * 0.75), 0.018, "dark", 6)  # şerit oluğu

def aps(x, y, z, side):
    """Aktif koruma: radar paneli + fırlatıcı."""
    box((x, y, z), (0.06, 0.42, 0.3), "paint", bev=0.015)
    box((x + side * 0.035, y, z), (0.01, 0.34, 0.22), "dark", bev=0.0)
    for k in range(4):
        bolt((x + side * 0.03, y - 0.18 + (k % 2) * 0.36, z - 0.13 + (k // 2) * 0.26), (side, 0, 0), 0.012)
    cyl((x, y - 0.35, z + 0.12), 0.11, 0.18, "paint", seg=12)
    box((x, y - 0.35, z + 0.25), (0.2, 0.2, 0.08), "paint", bev=0.015)
    for k in range(2):
        cyl((x + side * 0.06, y - 0.35 + (k - 0.5) * 0.09, z + 0.32), 0.03, 0.08, "dark", seg=8, rot=(0, side * 0.6, 0))

def era_brick(loc, size, rot=(0, 0, 0), nrm=(0, 0, 1), m="trim"):
    """Reaktif zırh tuğlası: kutu + dış yüzde kapak levhası + köşe cıvataları. nrm: yerel dış yüz ekseni."""
    f = F(loc, rot)
    sx, sy, sz = size
    f.box((0, 0, 0), size, m, bev=0.01)
    n = Vector(nrm)
    ax = [i for i in range(3) if abs(n[i]) < 0.5]
    hs = [size[i] * 0.5 for i in range(3)]
    d = [0, 0, 0]
    k = [i for i in range(3) if abs(n[i]) >= 0.5][0]
    d[k] = n[k] * (hs[k] + 0.006)
    lid = list(size)
    lid[k] = 0.012
    lid[ax[0]] *= 0.82; lid[ax[1]] *= 0.82
    f.box(tuple(d), tuple(lid), "paint" if m == "trim" else "trim")
    for a, b in ((-1, -1), (1, 1)):
        if True:
            p = list(d)
            p[k] = n[k] * (hs[k] + 0.012)
            p[ax[0]] = a * hs[ax[0]] * 0.7
            p[ax[1]] = b * hs[ax[1]] * 0.7
            f.cyl(tuple(p), 0.012, 0.014, "metal", seg=6, rot=_AX["XYZ"[k]])

def era_grid(x0, x1, y0, y1, z0, z1, side, nx=2, ny=8, depth=0.12):
    """Reaktif zırh tuğlaları: yan yüzeyde (x sabit) y-z ızgarası."""
    for j in range(ny):
        for i in range(nx):
            y = y0 + (y1 - y0) * (j + 0.5) / ny
            z = z0 + (z1 - z0) * (i + 0.5) / nx
            era_brick((x0, y, z), (depth, (y1 - y0) / ny * 0.92, (z1 - z0) / nx * 0.9), nrm=(side, 0, 0))
    # taşıyıcı ray
    box((x0 - side * depth * 0.3, (y0 + y1) / 2, z0 - 0.03), (0.04, abs(y1 - y0), 0.05), "paint", bev=0.0)

def slat_armor(x, y0, y1, z0, z1, side, pitch=0.11):
    """Kafes/çubuk zırh: çerçeve + dik çıtalar + gövdeye dayanak kolları."""
    xs = x
    for z in (z0, z1):
        bar((xs, y0, z), (xs, y1, z), 0.04, 0.05, "paint")
    for y in (y0, y1):
        bar((xs, y, z0), (xs, y, z1), 0.04, 0.05, "paint")
    n = max(2, int(abs(y1 - y0) / pitch))
    for i in range(1, n):
        y = y0 + (y1 - y0) * i / n
        box((xs, y, (z0 + z1) / 2), (0.05, 0.012, abs(z1 - z0) - 0.04), "paint", bev=0.0)
    m = max(2, int(abs(y1 - y0) / 1.2))
    for i in range(m + 1):
        y = y0 + (y1 - y0) * i / m
        bar((xs, y, (z0 + z1) / 2), (xs - side * 0.3, y, (z0 + z1) / 2), 0.04, 0.04, "metal")

def jerrycan(x, y, z, yaw=0.0, holder=True):
    """20 L bidon: gövde, X kabartma, üç kollu tutamak, kapak; tutucu kafes."""
    f = F((x, y, z), (0, 0, yaw))
    f.box((0, 0, 0), (0.165, 0.34, 0.45), "paint", bev=0.016)
    for sx in (-1, 1):
        for a in (-1, 1):
            f.box((sx * 0.085, 0, 0), (0.012, 0.035, 0.42), "paint", rot=(a * 0.65, 0, 0))
    for k in (-1, 0, 1):
        f.box((0, k * 0.075, 0.26), (0.03, 0.025, 0.06), "paint")
    f.box((0, 0, 0.29), (0.03, 0.2, 0.025), "paint")
    f.cyl((0, 0.13, 0.25), 0.03, 0.06, "metal", seg=8, rot=(0.6, 0, 0))
    if holder:
        f.box((0, 0, -0.24), (0.2, 0.38, 0.03), "metal")
        for sy in (-1, 1):
            f.box((0, sy * 0.18, -0.06), (0.19, 0.02, 0.36), "metal")
        f.box((0, 0, 0.12), (0.2, 0.36, 0.02), "metal")

def bag(x, y, z, sx, sy, sz, straps=2):
    """Teçhizat çantası: hafif pahlı branda + kayışlar + toka."""
    box((x, y, z), (sx, sy, sz), "canvas", bev=min(sx, sy, sz) * 0.12)
    for k in range(straps):
        yy = y - sy * 0.5 + sy * (k + 0.5) / straps
        box((x, yy, z), (sx + 0.012, 0.035, sz + 0.012), "dark", bev=0.0)
        box((x + sx * 0.5 + 0.008, yy, z + sz * 0.2), (0.012, 0.045, 0.04), "metal", bev=0.0)
    box((x, y, z + sz * 0.5 + 0.002), (sx * 0.9, sy * 0.4, 0.012), "canvas", bev=0.0)          # kapak kenarı

def net_roll(x, y, z, L, r=0.13, axis="X"):
    """Sarılı kamuflaj ağı / branda rulosu + kayışlar."""
    cyl((x, y, z), r, L, "canvas", axis, seg=10)
    for t in (-0.32, 0.32):
        o = Vector((t * L, 0, 0)) if axis == "X" else Vector((0, t * L, 0))
        cyl((x + o.x, y + o.y, z), r + 0.012, 0.04, "dark", axis, seg=10)

def ammo_box(x, y, z, yaw=0.0, big=False):
    f = F((x, y, z), (0, 0, yaw))
    sx, sy, sz = (0.2, 0.32, 0.2) if not big else (0.26, 0.45, 0.24)
    f.box((0, 0, 0), (sx, sy, sz), "trim", bev=0.008)
    f.box((0, 0, sz * 0.5 + 0.01), (sx * 0.9, sy * 0.95, 0.02), "trim")
    f.box((sx * 0.5 + 0.008, sy * 0.3, sz * 0.25), (0.015, 0.05, 0.06), "metal")
    grab_handle(f.P((0, 0, sz * 0.5 + 0.02)), f.R @ Vector((0, 1, 0)), f.R @ Vector((0, 0, 1)), L=sy * 0.4, h=0.03, r=0.007)

def stowage_box(x, y, z, sx, sy, sz, yaw=0.0, side=1, m="paint"):
    """Takım/zula kutusu: gövde + kapak çizgisi + menteşe + iki kilit mandalı."""
    f = F((x, y, z), (0, 0, yaw))
    f.box((0, 0, 0), (sx, sy, sz), m, bev=0.012)
    f.box((0, 0, sz * 0.5 + 0.008), (sx * 0.94, sy * 0.96, 0.016), m, bev=0.0)               # kapak
    seam(f.P((-sx * 0.5, -sy * 0.5, sz * 0.3)), f.P((-sx * 0.5, sy * 0.5, sz * 0.3)), f.R @ Vector((-1, 0, 0)))
    seam(f.P((sx * 0.5, -sy * 0.5, sz * 0.3)), f.P((sx * 0.5, sy * 0.5, sz * 0.3)), f.R @ Vector((1, 0, 0)))
    for t in (-0.3, 0.3):
        f.box((side * (sx * 0.5 + 0.01), t * sy, sz * 0.32), (0.02, 0.06, 0.08), "metal")
    f.cyl((-side * sx * 0.48, 0, sz * 0.5 + 0.01), 0.014, sy * 0.85, "metal", axis="Y", seg=6)

def basket(x0, x1, y0, y1, z, h, m="dark"):
    """Taret arkası / üstü zula sepeti: boru çerçeve + dikmeler + ızgara taban."""
    for zz in (z, z + h):
        for (a, b) in (((x0, y0), (x1, y0)), ((x1, y0), (x1, y1)), ((x1, y1), (x0, y1))):
            rod((a[0], a[1], zz), (b[0], b[1], zz), 0.018, m, 6)
    nx = max(2, int(abs(x1 - x0) / 0.4))
    ny = max(1, int(abs(y1 - y0) / 0.4))
    for i in range(nx + 1):
        xx = x0 + (x1 - x0) * i / nx
        rod((xx, y1, z), (xx, y1, z + h), 0.014, m, 6)
    for j in range(ny + 1):
        yy = y0 + (y1 - y0) * j / ny
        for xx in (x0, x1):
            rod((xx, yy, z), (xx, yy, z + h), 0.014, m, 6)
    for i in range(1, nx):
        xx = x0 + (x1 - x0) * i / nx
        rod((xx, y0, z), (xx, y1, z), 0.008, m, 4)

def antenna(x, y, z, h=2.2, tied=False):
    """Telsiz anteni: taban bloğu + yay + incelen kırbaç + uç topuz."""
    box((x, y, z + 0.025), (0.12, 0.12, 0.05), "dark", bev=0.0)
    cyl((x, y, z + 0.09), 0.045, 0.08, "dark", seg=8)
    cyl((x, y, z + 0.19), 0.022, 0.13, "dark", seg=6)
    if tied:
        # öne bağlanmış kırbaç (yay biçimli iki parça)
        rod((x, y, z + 0.25), (x, y + h * 0.35, z + h * 0.45), 0.007, "dark", 4)
        rod((x, y + h * 0.35, z + h * 0.45), (x, y + h * 0.75, z + h * 0.3), 0.006, "dark", 4)
        return
    cyl((x, y, z + 0.25 + h / 2), 0.009, h, "dark", seg=4, r2=0.004)
    cyl((x, y, z + 0.25 + h), 0.012, 0.025, "dark", seg=6)

def light(x, y, z, fy=1, guard=True):
    """Far grubu: gövde + ana far + karartma lambası + sinyal; tel koruma kafesi."""
    f = F((x, y, z), (0, 0, 0 if fy > 0 else math.pi))
    f.box((0, 0, 0), (0.24, 0.12, 0.16), "paint", bev=0.01)
    f.cyl((-0.04, 0.065, 0.01), 0.055, 0.02, "light", axis="Y", seg=12)
    f.cyl((-0.04, 0.06, 0.01), 0.068, 0.02, "dark", axis="Y", seg=12)
    f.box((0.075, 0.063, 0.03), (0.05, 0.02, 0.035), "lens" if fy > 0 else "red")
    f.box((0.075, 0.063, -0.035), (0.05, 0.02, 0.03), "dark")
    if guard:
        for gx in (-0.1, -0.03, 0.04, 0.1):
            f.rod((gx, 0.06, -0.08), (gx, 0.13, 0.0), 0.006, "metal", 4)
            f.rod((gx, 0.13, 0.0), (gx, 0.06, 0.085), 0.006, "metal", 4)
        f.rod((-0.12, 0.13, 0.0), (0.12, 0.13, 0.0), 0.006, "metal", 4)

def taillight(x, y, z, fy=-1):
    """Arka lamba grubu: plaka, kırmızı stop, sarı sinyal, koruma çerçevesi."""
    f = F((x, y, z), (0, 0, 0 if fy > 0 else math.pi))
    f.box((0, 0, 0), (0.26, 0.05, 0.14), "paint", bev=0.008)
    f.box((-0.06, 0.03, 0.02), (0.09, 0.015, 0.06), "red")
    f.box((0.06, 0.03, 0.02), (0.07, 0.015, 0.05), "lens")
    f.box((0, 0.03, -0.04), (0.18, 0.015, 0.025), "dark")
    f.box((0, 0.07, 0.075), (0.3, 0.1, 0.015), "metal")
    for gx in (-0.14, 0.14):
        f.box((gx, 0.07, 0.0), (0.015, 0.1, 0.16), "metal")

def grille(x, y, z, w, L, n, louver=True):
    """Motor güvertesi ızgarası: çerçeve + eğik panjur kanatları + kenar cıvataları."""
    box((x, y, z), (w, L, 0.04), "dark", bev=0.0)
    for sx in (-1, 1):
        box((x + sx * (w * 0.5 + 0.02), y, z + 0.02), (0.05, L + 0.1, 0.05), "paint", bev=0.006)
    for sy in (-1, 1):
        box((x, y + sy * (L * 0.5 + 0.025), z + 0.02), (w + 0.1, 0.05, 0.05), "paint", bev=0.006)
    for i in range(n):
        yy = y - L / 2 + (i + 0.5) * L / n
        box((x, yy, z + 0.035), (w * 0.96, L / n * 0.62, 0.012), "paint", rot=(0.45 if louver else 0, 0, 0), bev=0.0)
    if w > 0.8:
        box((x, y, z + 0.04), (0.04, L, 0.03), "paint", bev=0.0)
    nb = max(2, int(L / 0.3))
    for sx in (-1, 1):
        bolt_row((x + sx * (w * 0.5 + 0.02), y - L / 2, z + 0.045), (x + sx * (w * 0.5 + 0.02), y + L / 2, z + 0.045), nb, r=0.012)

def louvers(x, y, z, w, h, n, fy=-1):
    """Dik yüzde (arka) egzoz panjuru: çerçeve + aşağı eğik kanatlar."""
    f = F((x, y, z), (0, 0, 0 if fy > 0 else math.pi))
    f.box((0, 0, 0), (w + 0.08, 0.05, h + 0.08), "paint", bev=0.008)
    f.box((0, 0.02, 0), (w, 0.03, h), "dark")
    for i in range(n):
        zz = -h / 2 + (i + 0.5) * h / n
        f.box((0, 0.05, zz), (w * 0.97, 0.012, h / n * 0.9), "paint", rot=(0.6, 0, 0))
    for sx in (-1, 1):
        bolt_row(f.P((sx * (w * 0.5 + 0.02), 0.03, -h / 2)), f.P((sx * (w * 0.5 + 0.02), 0.03, h / 2)), 3, f.R @ Vector((0, 1, 0)), 0.011)

def exhaust(x, y, z, r=0.09, fy=-1, cover=True):
    """Egzoz borusu + yağmur kapağı."""
    cyl((x, y + fy * 0.08, z), r, 0.16, "metal", "Y", seg=10)
    cyl((x, y + fy * 0.17, z), r * 0.75, 0.02, "dark", "Y", seg=10)
    if cover:
        box((x, y + fy * 0.15, z + r + 0.02), (r * 2.4, 0.08, 0.015), "metal", rot=(fy * 0.3, 0, 0))

# ------------------------------------------------------------ alet / donanım (gövde yanına, üstüne)
def _tool(kind, f):
    """Yerel çerçevede alet: uzun eksen +Y, yüzey +Z, merkez (0,0,0)."""
    if kind == "shovel":
        f.cyl((0, -0.08, 0.035), 0.018, 0.75, "wood", axis="Y", seg=6)
        f.box((0, 0.42, 0.03), (0.22, 0.26, 0.012), "metal", rot=(0.05, 0, 0))
        f.box((0, 0.29, 0.03), (0.06, 0.06, 0.03), "metal")
        f.rod((-0.05, -0.46, 0.035), (0.05, -0.46, 0.035), 0.012, "wood", 5)
        f.rod((-0.05, -0.46, 0.035), (0, -0.4, 0.035), 0.01, "metal", 4)
        f.rod((0.05, -0.46, 0.035), (0, -0.4, 0.035), 0.01, "metal", 4)
    elif kind == "pick":
        f.cyl((0, 0, 0.035), 0.02, 0.9, "wood", axis="Y", seg=6)
        f.box((0, 0.4, 0.035), (0.08, 0.06, 0.05), "metal")
        for sx in (-1, 1):
            f.cyl((sx * 0.17, 0.4, 0.035), 0.022, 0.26, "metal", seg=6, r2=0.004, rot=(0, sx * math.pi / 2, 0))
    elif kind == "sledge":
        f.cyl((0, 0, 0.035), 0.018, 0.8, "wood", axis="Y", seg=6)
        f.cyl((0, 0.4, 0.045), 0.045, 0.18, "metal", axis="X", seg=8)
    elif kind == "axe":
        f.cyl((0, 0, 0.03), 0.017, 0.7, "wood", axis="Y", seg=6)
        f.box((0.06, 0.32, 0.03), (0.14, 0.09, 0.02), "metal")
    elif kind == "bar":
        f.cyl((0, 0, 0.03), 0.016, 1.4, "metal", axis="Y", seg=6)
    for t in (-0.22, 0.22):
        f.box((0, t, 0.02), (0.1, 0.04, 0.05), "dark")                                      # tutucu kelepçe

def tools(x, y, z, normal=(1, 0, 0), kinds=("shovel", "pick"), spacing=0.14, yaw=0.0):
    """Alet takımı: yan yanda (yüzeyin enine) alet sırası."""
    f0 = face_frame((x, y, z), normal, yaw)
    for i, k in enumerate(kinds):
        f = F(f0.P(((i - (len(kinds) - 1) / 2) * spacing, 0, 0)), f0.R)
        _tool(k, f)

def tow_cable(x, y0, y1, z, normal=(1, 0, 0), sag=0.0):
    """Çekme halatı: iki kat çelik halat + uç gözleri + kelepçeler (yüzey boyunca Y yönünde)."""
    n = Vector(normal)
    for o in (-0.025, 0.025):
        off = Vector((0, 0, o)) if abs(n.z) < 0.5 else Vector((o, 0, 0))
        rod(Vector((x, y0, z)) + off + n * 0.03, Vector((x, y1, z)) + off + n * 0.03, 0.017, "metal", 6)
    for yy in (y0, y1):
        d = 1 if yy > (y0 + y1) / 2 else -1
        ring(Vector((x, yy + d * 0.08, z)) + n * 0.03, 0.07, 0.016, "metal", axis="X" if abs(n.x) > 0.5 else "Z", seg=8)
    for t in (0.25, 0.5, 0.75):
        yy = y0 + (y1 - y0) * t
        box(Vector((x, yy, z)) + n * 0.03, (0.08 if abs(n.x) < 0.5 else 0.07, 0.04, 0.09 if abs(n.x) > 0.5 else 0.07), "dark", bev=0.0)

def track_spares(x, y, z, n=4, normal=(0, 0, 1), w=0.55, link=0.17, yaw=0.0):
    """Yedek palet baklaları (gövde önü / taret yanı): tırnaklı plakalar + tutucu çubuk."""
    f = face_frame((x, y, z), normal, yaw)
    for i in range(n):
        yy = (i - (n - 1) / 2) * link
        f.box((0, yy, 0.025), (w, link * 0.88, 0.05), "track")
        f.box((0, yy - link * 0.15, 0.06), (w * 0.95, link * 0.22, 0.03), "track")
        f.box((0, yy, -0.01), (0.07, link * 0.4, 0.04), "track")
    f.rod((-w * 0.5 - 0.04, -(n * link) / 2, 0.09), (-w * 0.5 - 0.04, (n * link) / 2, 0.09), 0.014, "metal", 6)
    f.rod((w * 0.5 + 0.04, -(n * link) / 2, 0.09), (w * 0.5 + 0.04, (n * link) / 2, 0.09), 0.014, "metal", 6)

def fender(x, y0, y1, z, w, side, flap=True):
    """Çamurluk: ince levha + alt destek konsolları + uçta lastik paçalık."""
    box((x, (y0 + y1) / 2, z), (w, abs(y1 - y0), 0.025), "paint", bev=0.006)
    seam((x - w / 2, (y0 + y1) / 2, z + 0.012), (x + w / 2, (y0 + y1) / 2, z + 0.012))
    n = max(2, int(abs(y1 - y0) / 0.8))
    for i in range(n + 1):
        yy = y0 + (y1 - y0) * i / n
        box((x - side * w * 0.3, yy, z - 0.07), (w * 0.4, 0.025, 0.12), "paint", rot=(0, side * 0.5, 0), bev=0.0)
    if flap:
        for yy in (y0, y1):
            box((x, yy, z - 0.18), (w * 0.95, 0.018, 0.34), "rubber", bev=0.0)

def mirror(x, y, z, side, L=0.35):
    """Dikiz aynası: kol + çerçeve + cam."""
    rod((x, y, z), (x + side * L, y + 0.05, z + 0.1), 0.012, "dark", 5)
    rod((x, y, z - 0.25), (x + side * L, y + 0.05, z + 0.1), 0.01, "dark", 5)
    box((x + side * L, y + 0.05, z + 0.1), (0.04, 0.2, 0.28), "dark", bev=0.0)
    box((x + side * L, y + 0.025, z + 0.1), (0.032, 0.012, 0.25), "glass", rot=(0, 0, 0), bev=0.0)

def ir_light(x, y, z, r=0.16, L=0.3):
    """Kızılötesi projektör (Luna tipi): silindir gövde + ön çerçeve + koyu lens + taşıyıcı kol + kablo."""
    cyl((x, y, z), r, L, "paint", "Y", seg=16, bev=0.006)
    cyl((x, y + L * 0.5 + 0.015, z), r * 1.08, 0.04, "paint", "Y", seg=16)
    cyl((x, y + L * 0.5 + 0.03, z), r * 0.88, 0.02, "dark", "Y", seg=16)
    cyl((x, y - L * 0.5 - 0.02, z), r * 0.6, 0.04, "trim", "Y", seg=12)
    for gz in (-0.5, 0.0, 0.5):
        box((x, y + L * 0.5 + 0.045, z + gz * r * 0.9), (r * 1.7, 0.012, 0.012), "metal", bev=0.0)
    box((x, y - 0.02, z - r - 0.06), (0.07, 0.14, 0.14), "paint", bev=0.006)
    rod((x - r * 0.4, y - L * 0.5, z), (x - r * 0.6, y - L * 0.5 - 0.25, z - r - 0.05), 0.012, "rubber", 5)

# ------------------------------------------------------------ rotorlar (roadmap 39/44)
def rotor(cx, cy, cz, nb, D, chord, droop=0.1, phase=0.0, tip="lens", hub_r=None, mname="dark"):
    """Ana rotor: direk + eğik plaka (swashplate) + göbek + pal manşonları, hatve kolları ve çubukları,
    sönümleyiciler + kökten uca sivrilen, burulmuş paller (hücum kenarında aşınma şeridi, uçta görünürlük
    şeridi ve uç kapağı). D = rotor çapı (m). Pal yerel +X boyunca; düğüm Z etrafında döner."""
    R = D * 0.5
    ROT_NB.append(nb)
    hr = hub_r if hub_r is not None else min(0.42, max(0.18, D * 0.022))
    cyl((cx, cy, cz - 0.3), hr * 0.38, 0.46, "metal", seg=12)                    # direk
    cyl((cx, cy, cz - 0.4), hr * 1.05, 0.06, "metal", seg=16)                    # dönen eğik plaka
    cyl((cx, cy, cz - 0.46), hr * 1.12, 0.05, "dark", seg=16)                    # sabit eğik plaka
    cyl((cx, cy, cz), hr, 0.26, "metal", seg=16)                                 # göbek
    cyl((cx, cy, cz + 0.2), hr * 0.45, 0.16, "metal", seg=12, r2=hr * 0.62)      # göbek kubbesi
    cyl((cx, cy, cz + 0.3), hr * 0.16, 0.08, "dark", seg=8)
    span0 = hr + 0.42
    L = max(0.5, R - span0)
    dz = droop / max(R, 1.0)
    for k in range(nb):
        a = phase + k * math.tau / nb
        f = F((cx, cy, cz), (0, 0, a))
        f.box((hr + 0.2, 0, 0), (0.44, chord * 0.42 + 0.06, 0.17), "metal")                 # manşon
        f.box((hr + 0.16, chord * 0.3 + 0.08, -0.06), (0.12, 0.12, 0.06), "metal")            # hatve kolu
        f.rod((hr + 0.16, chord * 0.3 + 0.1, -0.08), (hr * 0.98, chord * 0.3 + 0.1, -0.4), 0.02, "metal")   # hatve çubuğu
        f.rod((hr * 0.55, -chord * 0.3 - 0.06, 0.03), (hr + 0.32, -chord * 0.3 - 0.04, 0.03), 0.035, "dark")  # sönümleyici
        nseg = 5
        for i in range(nseg):
            tm = (i + 0.5) / nseg
            x = span0 + L * tm
            c = chord * (1.0 - 0.18 * tm * tm)
            tw = math.radians(7.0 - 9.0 * tm)
            th = 0.06 * (1.0 - 0.35 * tm)
            z = -dz * x
            f.box((x, 0, z), (L / nseg + 0.012, c, th), mname, rot=(tw, -dz, 0))
            f.box((x, c * 0.5 + 0.006, z), (L / nseg + 0.012, 0.02, th * 0.8), "metal", rot=(tw, -dz, 0))   # aşınma şeridi
        xt = R - 0.46
        f.box((xt, 0, -dz * xt + 0.003), (0.3, chord * 0.84 + 0.012, 0.05), tip, rot=(math.radians(-1.5), -dz, 0))   # uç şeridi
        f.box((R - 0.14, 0, -dz * R + 0.002), (0.26, chord * 0.82 + 0.01, 0.046), "mark", rot=(math.radians(-2.0), -dz, 0))


def tail_rotor_x(cx, cy, cz, nb, D, side=1, chord=None, tip="lens"):
    """Kuyruk rotoru (YZ düzleminde, X ekseni etrafında döner): göbek + manşonlar + paller + uç şeridi."""
    R = D * 0.5
    c = chord if chord is not None else max(0.14, D * 0.075)
    hr = max(0.09, R * 0.11)
    cyl((cx, cy, cz), hr, 0.26, "metal", "X", seg=12)
    cyl((cx + side * 0.15, cy, cz), hr * 0.6, 0.1, "dark", "X", seg=10)
    for k in range(nb):
        a = k * math.tau / nb
        f = F((cx + side * 0.07, cy, cz), (a, 0, 0))
        f.box((0, hr + 0.09, 0), (0.09, 0.18, c * 0.6), "metal")
        f.box((0, (hr + R) * 0.5 + 0.05, 0), (0.045, R - hr - 0.1, c), "dark", rot=(0, math.radians(8), 0))
        f.box((0, R - 0.13, 0), (0.05, 0.22, c * 0.96), tip, rot=(0, math.radians(8), 0))


def spare_wheel(x, y, z, r, w, axis="X"):
    """Yedek teker (tutucuda): lastik + jant + diş blokları + tespit somunu."""
    cyl((x, y, z), r, w, "rubber", axis, seg=20)
    off = {"X": Vector((1, 0, 0)), "Y": Vector((0, 1, 0)), "Z": Vector((0, 0, 1))}[axis]
    p = Vector((x, y, z))
    cyl(p + off * (w * 0.5), r * 0.62, 0.03, "paint", axis, seg=16)
    cyl(p + off * (w * 0.5 + 0.02), r * 0.25, 0.05, "metal", axis, seg=8)
    cyl(p + off * (w * 0.5 + 0.05), 0.04, 0.08, "metal", axis, seg=6)

# ------------------------------------------------------------ dışa aktarım
def _ao(objs, ground=True, rays=14, dist=0.85):
    """Işın izlemeli ortam kapanması → köşe rengi. Döner rotorlar örtücü sayılmaz; yer düzlemi (z=0) örtücüdür."""
    verts = []
    polys = []
    for o in objs:
        if o.name in ("rotor", "trotor"):
            continue
        M = o.matrix_world
        off = len(verts)
        verts += [M @ v.co for v in o.data.vertices]
        polys += [[off + i for i in p.vertices] for p in o.data.polygons]
    bvh = BVHTree.FromPolygons(verts, polys, epsilon=0.0) if polys else None
    # sabit, kosinüs ağırlıklı yarıküre yönleri (Fibonacci)
    dirs = []
    ga = math.pi * (3 - math.sqrt(5))
    for i in range(rays):
        u = (i + 0.5) / rays
        rr = math.sqrt(u)
        a = i * ga
        dirs.append(Vector((math.cos(a) * rr, math.sin(a) * rr, math.sqrt(max(0.0, 1 - u)))))
    for o in objs:
        me = o.data
        M = o.matrix_world
        vals = []
        for v in me.vertices:
            p = M @ v.co
            n = v.normal.normalized()
            t = Vector((1, 0, 0)) if abs(n.x) < 0.9 else Vector((0, 1, 0))
            b1 = n.cross(t).normalized()
            b2 = n.cross(b1)
            occ = 0.0
            o0 = p + n * 0.006
            for d in dirs:
                wd = b1 * d.x + b2 * d.y + n * d.z
                hd = None
                if bvh:
                    h = bvh.ray_cast(o0, wd, dist)
                    if h[0] is not None:
                        hd = h[3]
                if ground and wd.z < -1e-4:
                    tg = -o0.z / wd.z
                    if 0 <= tg < dist and (hd is None or tg < hd):
                        hd = tg
                if hd is not None:
                    occ += 1.0 - (hd / dist) * 0.6
            a = 1.0 - occ / rays
            if ground:
                # alt yüzler ve zemine yakın kısımlar hafif koyulaşır
                a *= 0.82 + 0.18 * min(1.0, max(0.0, p.z / 0.6))
            a = max(0.32, min(1.0, 0.25 + 0.85 * a))
            vals.append(a ** (1 / 2.2))
        ca = me.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
        cols = []
        for lp in me.loops:
            g = vals[lp.vertex_index]
            cols += (g, g, g, 1.0)
        ca.data.foreach_set("color", cols)
        me.color_attributes.active_color = ca
        me.color_attributes.render_color_index = 0

def apply_fit(v, pivots, meta):
    """Gerçek boyut düzeltmesi (roadmap 38, data/real_dims.json → tools/size_audit.gd), katalog 'v' alanından:
    turret_dy: taret + namlu Y kaydırma (m) · gun_k: namlu boyu çarpanı (namlu pivotundan) ·
    fit_s [sx, sy, sz]: genel ölçek — tekerlek düğümleri ölçeklenmez yalnız taşınır (tekerler oval olmaz);
    paletli araçta yalnız sx (genişlik) kullanılır, yol tekerleri yan düzlemde bozulmaz."""
    def _move(name, d):
        for b in NODES.get(name, {}).values():
            for vt in b.verts:
                vt.co += d
    tk = float(v.get("turret_k", 1.0))
    if tk != 1.0 and "turret" in pivots:
        # taret yatayda pivotu çevresinde küçülür (roadmap 97); namlu boyu korunur, küçülen ön yüze taşınır
        tp = pivots["turret"]
        for b in NODES.get("turret", {}).values():
            for vt in b.verts:
                vt.co.x = tp[0] + (vt.co.x - tp[0]) * tk
                vt.co.y = tp[1] + (vt.co.y - tp[1]) * tk
        def _sc(q):
            return (tp[0] + (q[0] - tp[0]) * tk, tp[1] + (q[1] - tp[1]) * tk, q[2])
        if "barrel" in pivots:
            bp = pivots["barrel"]
            nb = _sc(bp)
            _move("barrel", Vector((nb[0] - bp[0], nb[1] - bp[1], 0)))
            pivots["barrel"] = nb
            if "muzzle" in meta:
                m = meta["muzzle"]
                meta["muzzle"] = (m[0] + nb[0] - bp[0], m[1] + nb[1] - bp[1], m[2])
        if "hatch" in meta:
            meta["hatch"] = _sc(meta["hatch"])
    dy = float(v.get("turret_dy", 0.0))
    if dy:
        d = Vector((0, dy, 0))
        for n in ("turret", "barrel"):
            _move(n, d)
            if n in pivots:
                p = pivots[n]
                pivots[n] = (p[0], p[1] + dy, p[2])
        for mk in ("muzzle", "hatch"):
            if mk in meta:
                m = meta[mk]
                meta[mk] = (m[0], m[1] + dy, m[2])
    gk = float(v.get("gun_k", 1.0))
    if gk != 1.0 and "barrel" in pivots:
        o = pivots["barrel"]
        for b in NODES.get("barrel", {}).values():
            for vt in b.verts:
                if vt.co.y > o[1]:
                    vt.co.y = o[1] + (vt.co.y - o[1]) * gk
        if "muzzle" in meta:
            m = meta["muzzle"]
            meta["muzzle"] = (m[0], o[1] + (m[1] - o[1]) * gk, m[2])
    fs = v.get("fit_s")
    if fs:
        S = Vector((float(fs[0]), float(fs[1]), float(fs[2])))
        for name, mats in NODES.items():
            if name.startswith("wheel_"):
                p = Vector(pivots.get(name, (0, 0, 0)))
                np_ = Vector((p.x * S.x, p.y * S.y, p.z))
                _move(name, np_ - p)
                pivots[name] = tuple(np_)
            else:
                for b in mats.values():
                    for vt in b.verts:
                        vt.co = Vector((vt.co.x * S.x, vt.co.y * S.y, vt.co.z * S.z))
                if name in pivots:
                    p = pivots[name]
                    pivots[name] = (p[0] * S.x, p[1] * S.y, p[2] * S.z)
        for k in list(meta.keys()):
            m = meta[k]
            if isinstance(m, (tuple, list)) and len(m) == 3:
                meta[k] = (m[0] * S.x, m[1] * S.y, m[2] * S.z)
        if DOOR and "door" not in pivots:
            p = DOOR["pivot"]
            DOOR["pivot"] = (p[0] * S.x, p[1] * S.y, p[2] * S.z)
    return pivots, meta

def export(path_glb, pivots, meta, ao=True):
    import json
    if DOOR and "door" not in pivots:
        pivots = dict(pivots)
        pivots["door"] = DOOR["pivot"]
        meta = dict(meta)
        meta["door_open"] = DOOR["open"]
    if EXTRA_PIVOTS:
        pivots = dict(pivots)
        for k, v in EXTRA_PIVOTS.items():
            pivots.setdefault(k, v)
    objs = []
    for name, mats in NODES.items():
        mats = [(k, b) for k, b in mats.items() if len(b.faces)]
        if not mats:
            continue
        bm = bmesh.new()
        mlist = []
        for i, (mn, b) in enumerate(mats):
            for f in b.faces:
                f.material_index = i
            b.to_mesh(_TMP)
            bm.from_mesh(_TMP)
            mlist.append(mat(mn))
        # kutu izdüşümü UV (dünya ölçeğinde, 4 m'de bir tekrar)
        uvl = bm.loops.layers.uv.verify()
        for f in bm.faces:
            nn = f.normal
            ax = 0 if abs(nn.x) >= abs(nn.y) and abs(nn.x) >= abs(nn.z) else (1 if abs(nn.y) >= abs(nn.z) else 2)
            for l in f.loops:
                c = l.vert.co
                l[uvl].uv = ((c.y, c.z) if ax == 0 else ((c.x, c.z) if ax == 1 else (c.x, c.y)))
                l[uvl].uv = (l[uvl].uv[0] * 0.25, l[uvl].uv[1] * 0.25)
        pv = Vector(pivots.get(name, (0, 0, 0)))
        bmesh.ops.translate(bm, verts=bm.verts, vec=-pv)
        me = bpy.data.meshes.new(name)
        bm.to_mesh(me)
        bm.free()
        for m in mlist:
            me.materials.append(m)
        o = bpy.data.objects.new(name, me)
        bpy.context.collection.objects.link(o)
        o.location = pv
        objs.append(o)
    bpy.context.view_layer.update()
    if ao:
        _ao(objs, ground="rotor" not in pivots)
    else:
        for o in objs:
            o.data.color_attributes.new("Col", 'BYTE_COLOR', 'CORNER')
    for o in objs:
        o.select_set(True)
    bpy.ops.export_scene.gltf(filepath=path_glb, export_format='GLB', export_yup=True, export_apply=True,
                              export_vertex_color='ACTIVE', export_all_vertex_colors=False)
    def g(p):  # Blender → Godot (x, z, -y)
        return [round(p[0], 3), round(p[2], 3), round(-p[1], 3)]
    if ROT_NB and "nb" not in meta:
        meta = dict(meta)
        meta["nb"] = max(ROT_NB)
    js = {"pivots": {k: g(v) for k, v in pivots.items()}, "meta": {k: (g(v) if isinstance(v, (tuple, list)) and len(v) == 3 else v) for k, v in meta.items()}}
    with open(path_glb[:-4] + ".json", "w") as f:
        json.dump(js, f)
    tris = sum(len(p.vertices) - 2 for o in objs for p in o.data.polygons)
    print("EXPORT", path_glb, "tris", tris)
    return tris

# ------------------------------------------------------------ gövde levhası ve tekerlek düğümleri
def slab(yfb, yft, yrt, yrb, z0, z1, wb, wt, mname="paint", bev=0.03, wf=None):
    """Altı yüzlü gövde: ön alt/üst y, arka üst/alt y, alt/üst z, alt/üst yarı genişlik. wf: ön üst yarı genişlik."""
    wf = wt if wf is None else wf
    pts = []
    for s in (-1, 1):
        pts += [(s * wb, yfb, z0), (s * wf, yft, z1), (s * wt, yrt, z1), (s * wb, yrb, z0)]
    return hull_pts(pts, mname, bev)

def tyre(i, x, y, z, r, w, side, hub="paint", tread=True):
    """Döner tekerlek: ayrı düğüm wheel_i (pivot = teker merkezi). Diş blokları, jant, göbek, bijon somunları."""
    prev = CUR
    node("wheel_%d" % i)
    s = side
    cyl((x, y, z), r * 0.95, w, "rubber", "X", seg=20)
    cyl((x, y, z), r * 0.9, w * 1.04, "rubber", "X", seg=20, r2=r * 0.9)
    if tread:
        # şaşırtmalı diş blokları (iki sıra, yarım adım kaydırılmış)
        nb = 16 if r > 0.4 else 14
        for k in range(nb):
            for o in (-1, 1):
                aa = (k + (0.5 if o > 0 else 0.0)) * math.tau / nb
                box((x + o * w * 0.24, y + math.cos(aa) * r * 0.965, z + math.sin(aa) * r * 0.965), (w * 0.46, r * 0.22, r * 0.08), "rubber",
                    rot=(aa + math.pi / 2, 0, 0), bev=0.0)
    for o in (1, -1):
        cyl((x + s * o * (w * 0.5 + 0.005), y, z), r * 0.72, 0.012, "rubber", "X", seg=16)        # yanak
    xo = x + s * (w * 0.5)
    cyl((xo, y, z), r * 0.6, 0.04, hub, "X", seg=16)                                                # jant
    cyl((xo + s * 0.02, y, z), r * 0.52, 0.02, "trim" if hub == "paint" else hub, "X", seg=16)      # beadlock halkası
    for k in range(10):
        a = k * math.tau / 10
        cyl((xo + s * 0.03, y + math.cos(a) * r * 0.56, z + math.sin(a) * r * 0.56), 0.012, 0.02, "metal", "X", seg=6)
    cyl((xo + s * 0.04, y, z), r * 0.28, 0.07, "metal", "X", seg=10)
    cyl((xo + s * 0.08, y, z), r * 0.14, 0.04, "metal", "X", seg=8)
    for k in range(8):
        a = k * math.tau / 8
        cyl((xo + s * 0.075, y + math.cos(a) * r * 0.2, z + math.sin(a) * r * 0.2), 0.017, 0.04, "metal", "X", seg=6)
    WHEELS.append(("wheel_%d" % i, (x, y, z)))
    node(prev)

def wheels_axles(ys, xw, r, w, hub="paint"):
    n = 0
    for y in ys:
        for s in (-1, 1):
            tyre(n, s * xw, y, r, r, w, s, hub)
            n += 1
    return n

def wheel_pivots(pv):
    for n, p in WHEELS:
        pv[n] = p
    return pv

def gun(y0, z, L, r, mname="paint", brake=False, sleeve=0.0, x=0.0, bands=0, bore=True):
    """Namlu (Y boyunca y0'dan L kadar): koni namlu, duman tahliye kovanı, ısı kılıfı kelepçeleri, namlu ağzı, fren."""
    cyl((x, y0 + L / 2, z), r * 0.9, L, mname, "Y", seg=14, r2=r)          # Y ekseninde ilk yarıçap +Y (ağız) ucunda
    if sleeve:
        cyl((x, y0 + L * 0.45, z), r * 1.45, sleeve, mname, "Y", seg=14)
        for t in (-0.5, 0.5):
            cyl((x, y0 + L * 0.45 + t * sleeve, z), r * 1.3, 0.03, mname, "Y", seg=14)
    for k in range(bands):
        f = (k + 1) / (bands + 1)
        cyl((x, y0 + L * f, z), r * (1.0 - 0.1 * f) + 0.012, 0.035, "trim" if mname == "paint" else mname, "Y", seg=14)
    if bore:
        cyl((x, y0 + L + 0.003, z), r * 0.6, 0.01, "dark", "Y", seg=10)
    if brake:
        box((x, y0 + L + 0.12, z), (r * 3.2, 0.32, r * 2.2), mname if mname != "paint" else "trim", bev=0.015)
        for s in (-1, 1):
            for k in range(2):
                box((x + s * r * 1.62, y0 + L + 0.05 + k * 0.14, z), (0.02, 0.09, r * 1.6), "dark", bev=0.0)
        cyl((x, y0 + L + 0.285, z), r * 0.85, 0.01, "dark", "Y", seg=10)

def canister(x, y, z, L, r, pitch, mname="paint", seg=12, caps=True):
    """Füze kanisteri: Y ekseni etrafında pitch ile yükselen silindir (ileri bakar) + uç bantları + ön kapak."""
    R = Euler((math.pi / 2 - pitch, 0, 0))
    cyl((x, y, z), r, L, mname, rot=R, seg=seg)
    if caps:
        d = Vector((0, math.cos(pitch), math.sin(pitch)))
        c = Vector((x, y, z))
        for t in (-0.46, 0.46):
            cyl(c + d * (L * t), r * 1.08, min(0.05, L * 0.05), "trim" if mname == "paint" else mname, rot=R, seg=seg)
        cyl(c + d * (L * 0.5 + 0.005), r * 0.85, 0.01, "dark", rot=R, seg=seg)

def podbox(x, y, z, sx, sy, sz, pitch=0.0, cells=(2, 3)):
    """Roket/füze kutusu: ön yüzde hücre ağızları, yan nervürler, kaldırma kulakları, arka kapak."""
    E = (pitch, 0, 0)
    f = F((x, y, z), E)
    f.box((0, 0, 0), (sx, sy, sz), "paint", bev=0.03)
    nx, nz = cells
    for i in range(nx):
        for k in range(nz):
            lx = (i - (nx - 1) / 2) * sx / nx * 0.9
            lz = (k - (nz - 1) / 2) * sz / nz * 0.9
            ww, hh = sx / nx * 0.7, sz / nz * 0.7
            f.box((lx, sy / 2 + 0.008, lz), (ww + 0.04, 0.02, hh + 0.04), "trim")
            f.cyl((lx, sy / 2 + 0.012, lz), min(ww, hh) * 0.45, 0.02, "dark", axis="Y", seg=10)
    for t in (-0.42, -0.14, 0.14, 0.42):
        for s in (-1, 1):
            f.box((s * (sx / 2 + 0.012), t * sy, 0), (0.025, 0.05, sz * 0.96), "paint")
    for t in (-0.3, 0.3):
        f.box((0, t * sy, sz / 2 + 0.015), (sx * 0.96, 0.05, 0.03), "paint")
        for s in (-1, 1):
            lift_eye(f.P((s * sx * 0.35, t * sy, sz / 2 + 0.03)), f.R @ Vector((0, 0, 1)))
    f.box((0, -sy / 2 - 0.012, 0), (sx * 0.9, 0.025, sz * 0.9), "trim")

def cab(y, z0, w, L, h, glass=True, mirrors=True):
    """Kamyon kabini: gövde, çerçeveli ikiz ön cam, silecekler, yan camlar, kapı çizgileri, kollar, aynalar, tavan lambaları."""
    slab(y + L / 2, y + L / 2 - 0.25, y - L / 2, y - L / 2, z0, z0 + h, w / 2, w / 2 - 0.08)
    if glass:
        a = -0.45
        yc, zc = y + L / 2 - 0.13, z0 + h * 0.72
        for s in (-1, 1):
            box((s * w * 0.215, yc + 0.012, zc), (w * 0.4, 0.04, h * 0.32), "glass", rot=(a, 0, 0), bev=0.0)
            box((s * w * 0.22, yc + 0.03, zc - h * 0.12), (0.02, 0.02, h * 0.2), "dark", rot=(a - 0.6, 0, 0.0), bev=0.0)   # silecek
        box((0, yc + 0.02, zc), (0.06, 0.05, h * 0.36), "paint", rot=(a, 0, 0), bev=0.0)        # orta dikme
        box((0, yc + 0.02, zc + h * 0.17), (w * 0.9, 0.05, 0.05), "paint", rot=(a, 0, 0), bev=0.0)
        box((0, yc + 0.02, zc - h * 0.17), (w * 0.9, 0.05, 0.05), "paint", rot=(a, 0, 0), bev=0.0)
        box((0, y + L / 2 - 0.05, z0 + h * 0.93), (w * 0.86, 0.2, 0.03), "paint", bev=0.0)       # güneşlik
        for s in (-1, 1):
            box((s * (w / 2 - 0.02), y + L * 0.1, z0 + h * 0.72), (0.03, L * 0.5, h * 0.3), "glass", bev=0.0)
            # kapı çizgisi + kolu + basamak
            seam((s * (w / 2 - 0.035), y + L * 0.38, z0 + 0.1), (s * (w / 2 - 0.035), y + L * 0.38, z0 + h * 0.9), (s, 0, 0))
            seam((s * (w / 2 - 0.035), y - L * 0.2, z0 + 0.1), (s * (w / 2 - 0.035), y - L * 0.2, z0 + h * 0.9), (s, 0, 0))
            box((s * (w / 2 - 0.01), y - L * 0.1, z0 + h * 0.5), (0.03, 0.14, 0.03), "metal", bev=0.0)
            grab_handle((s * (w / 2 - 0.03), y + L * 0.42, z0 + h * 0.5), (0, 0, 1), (s, 0, 0), L=0.5, h=0.05, r=0.012)
            box((s * (w / 2 - 0.05), y + L * 0.1, z0 - 0.18), (0.22, 0.5, 0.04), "metal", bev=0.0)
            if mirrors:
                mirror(s * (w / 2 - 0.02), y + L / 2 - 0.3, z0 + h * 0.7, s)
    for k in (-1, 0, 1):
        box((k * 0.18, y + L / 2 - 0.3, z0 + h + 0.025), (0.08, 0.05, 0.05), "lens", bev=0.0)    # tavan işaret lambaları

def reset_wheels():
    WHEELS.clear()

# ------------------------------------------------------------ ortak gövde donanımı (aileler çağırır)
def shackle(x, y, z, fy=1):
    """Çeki gözü / kancası: gövdeye kaynaklı kulak + U halka + pim."""
    f = F((x, y, z), (0, 0, 0 if fy > 0 else math.pi))
    for sx in (-1, 1):
        f.box((sx * 0.06, 0.04, 0), (0.035, 0.12, 0.14), "paint", bev=0.006)
    f.cyl((0, 0.07, 0), 0.02, 0.18, "metal", axis="X", seg=6)
    f.ring((0, 0.13, -0.03), 0.07, 0.018, "metal", axis="Z", seg=10, tseg=4)

def pintle(x, y, z, fy=-1):
    """Arka çeki kancası (pintle): gövde plakası + kanca."""
    f = F((x, y, z), (0, 0, 0 if fy > 0 else math.pi))
    f.box((0, 0.02, 0), (0.24, 0.05, 0.2), "paint", bev=0.008)
    f.box((0, 0.1, 0), (0.08, 0.14, 0.1), "metal")
    f.ring((0, 0.18, 0.0), 0.05, 0.018, "metal", axis="X", seg=8)
    for k in range(4):
        f.cyl(((k % 2 - 0.5) * 0.16, 0.05, (k // 2 - 0.5) * 0.14), 0.013, 0.02, "metal", axis="Y", seg=6)

def deck_seams(x0, x1, ys, z):
    """Güverte panel ek yerleri (enine) + yanında cıvata sırası."""
    for y in ys:
        seam((x0, y, z), (x1, y, z))
        bolt_row((x0 + 0.05, y - 0.04, z), (x1 - 0.05, y - 0.04, z), max(2, int(abs(x1 - x0) / 0.35)), r=0.013)

def roof_panels(x0, x1, y0, y1, z, nx=2, ny=2, bolts=True):
    """Yatay yüzeyde panel ızgarası: ek yeri çizgileri + kenarlarında cıvata sıraları."""
    for i in range(1, nx):
        x = x0 + (x1 - x0) * i / nx
        seam((x, y0, z), (x, y1, z))
        if bolts:
            bolt_row((x + 0.05, y0, z), (x + 0.05, y1, z), max(2, int(abs(y1 - y0) / 0.4)), r=0.013)
    for j in range(1, ny):
        y = y0 + (y1 - y0) * j / ny
        seam((x0, y, z), (x1, y, z))
        if bolts:
            bolt_row((x0, y + 0.05, z), (x1, y + 0.05, z), max(2, int(abs(x1 - x0) / 0.4)), r=0.013)

def side_panels(x, y0, y1, z0, z1, side, ny=3, bolts=True):
    """Dik yan yüzeyde panel bölmeleri + üst/alt cıvata sıraları."""
    n = (side, 0, 0)
    for j in range(1, ny):
        y = y0 + (y1 - y0) * j / ny
        seam((x, y, z0), (x, y, z1), n)
    if bolts:
        for zz in (z0 + 0.06, z1 - 0.06):
            bolt_row((x + side * 0.004, y0, zz), (x + side * 0.004, y1, zz), max(3, int(abs(y1 - y0) / 0.35)), n, 0.015)

def dress_hull(L, W, zt, zf=0.75, front=True, rear=True, tools_y=None, tools_kind=(("shovel", "pick"), ("sledge", "bar")),
               cable=True, tails=True, ties=True, y_off=0.0):
    """Zırhlının ortak donanımı: çeki gözleri, bağlama halkaları, arka lambalar, alet takımı, çekme halatı.
    L, W: gövde uzunluğu/üst genişliği (merkez y_off), zt: güverte yüksekliği, zf: çeki gözü yüksekliği."""
    yf, yr = y_off + L / 2, y_off - L / 2
    for s in (-1, 1):
        if front:
            shackle(s * W * 0.28, yf + 0.02, zf, 1)
        if rear:
            shackle(s * W * 0.32, yr - 0.02, zf, -1)
        if tails:
            taillight(s * (W / 2 - 0.25), yr - 0.03, zt - 0.18)
        if ties:
            for yy in (yf - 0.35, yr + 0.3):
                tiedown((s * (W / 2 - 0.12), yy, zt), (0, 0, 1))
    if rear:
        pintle(0, yr - 0.03, zf + 0.05)
    if tools_y is not None:
        for s, kinds in zip((-1, 1), tools_kind):
            tools(s * (W / 2 - 0.22), tools_y, zt, (0, 0, 1), kinds, spacing=0.13)
    if cable:
        tow_cable(-(W / 2 - 0.06), yr + 0.5, yr + 0.5 + L * 0.45, zt, (0, 0, 1))
