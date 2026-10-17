# Ordu yapıları (Blender, yordamsal sert yüzey): karargâh, ileri üs, kışla, araç fabrikası, helikopter pisti, sahra hastanesi.
# Her yapı iki tarafa ayrı: usa (NATO, çöl/koyot + zeytin yeşili) ve rus (Doğu, yeşil/haki + gri beton, sıva, tuğla).
# Çalıştır: python3 tools/blender/structures.py [--only factory_usa,hq_rus] [--preview <klasör>] [--noao]
# Çıktı: assets/models/struct_<tip>_<usa|rus>.glb — tek ağ, yüzey başına malzeme (vc, metal, glass, lamp*, cloth, flag);
# renk tepe rengi (COLOR_0, doğrusal) + Cycles ile pişirilmiş ortam kapanması. Oyunda malzemeler adla değiştirilir.
# Koordinat: Blender Z yukarı, -Y ön (oyunda +Z, toplanma noktası tarafı), +X sağ. Birim metre, taban z=0, merkez (0,0).
import bpy, bmesh, math, random, os, sys
from mathutils import Vector, Matrix, Euler

ROOT = os.path.abspath(os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", ".."))
OUT = os.path.join(ROOT, "assets", "models")

MATS = ["vc", "metal", "glass", "lamp", "lamp_r", "lamp_g", "lamp_b", "cloth", "flag"]
B = None          # ortak bmesh
CL = None         # köşe renk katmanı
XF = [Matrix.Identity(4)]
RND = random.Random(7)
SIDE = "usa"
P = {}
BODY_H = 3.0      # gövde yüksekliği (inşaat kesmesi/iskele için; direkler ve antenler hariç)

# ------------------------------------------------------------ renk paletleri (sRGB)
COMMON = {
    "white": (0.86, 0.86, 0.83), "black": (0.07, 0.07, 0.07), "dark": (0.14, 0.14, 0.13), "red": (0.72, 0.09, 0.07),
    "yellow": (0.86, 0.66, 0.12), "orange": (0.9, 0.4, 0.08), "glass": (0.1, 0.13, 0.15), "steel": (0.56, 0.57, 0.57),
    "galv": (0.66, 0.67, 0.66), "rubber": (0.08, 0.08, 0.08), "rust": (0.42, 0.25, 0.15), "lamp": (1.0, 0.92, 0.7),
    "lamp_r": (1.0, 0.15, 0.1), "lamp_g": (0.2, 1.0, 0.35), "lamp_b": (0.25, 0.45, 1.0), "flag": (1, 1, 1),
    "gravel": (0.5, 0.48, 0.44), "blue": (0.15, 0.3, 0.55),
}
PALS = {
    "usa": {
        "wall": (0.72, 0.64, 0.49), "wall2": (0.64, 0.56, 0.42), "trim": (0.5, 0.44, 0.33), "olive": (0.34, 0.35, 0.24),
        "olive2": (0.28, 0.3, 0.2), "canvas": (0.69, 0.62, 0.47), "canvas2": (0.6, 0.54, 0.41), "roof": (0.62, 0.63, 0.61),
        "concrete": (0.68, 0.66, 0.62), "concrete2": (0.6, 0.58, 0.55), "hesco": (0.72, 0.64, 0.49), "fill": (0.55, 0.45, 0.32),
        "bag": (0.67, 0.59, 0.43), "wood": (0.64, 0.51, 0.34), "ply": (0.74, 0.62, 0.44), "paint": (0.62, 0.55, 0.4),
        "crate": (0.36, 0.38, 0.26), "net": (0.55, 0.48, 0.34), "net2": (0.42, 0.38, 0.27), "door": (0.52, 0.46, 0.35),
        "tank": (0.58, 0.52, 0.39),
    },
    "rus": {
        "wall": (0.78, 0.74, 0.62), "wall2": (0.7, 0.66, 0.55), "trim": (0.58, 0.55, 0.48), "olive": (0.3, 0.36, 0.22),
        "olive2": (0.25, 0.3, 0.19), "canvas": (0.42, 0.43, 0.3), "canvas2": (0.36, 0.37, 0.26), "roof": (0.56, 0.58, 0.57),
        "concrete": (0.57, 0.57, 0.54), "concrete2": (0.5, 0.5, 0.48), "hesco": (0.45, 0.43, 0.32), "fill": (0.4, 0.33, 0.24),
        "bag": (0.52, 0.5, 0.36), "wood": (0.55, 0.42, 0.28), "ply": (0.6, 0.5, 0.36), "paint": (0.3, 0.36, 0.22),
        "crate": (0.33, 0.37, 0.24), "net": (0.33, 0.38, 0.23), "net2": (0.42, 0.4, 0.28), "door": (0.29, 0.36, 0.23),
        "brick": (0.56, 0.29, 0.21), "brick2": (0.49, 0.24, 0.18), "plinth": (0.45, 0.44, 0.42), "tank": (0.3, 0.36, 0.22),
        "asb": (0.6, 0.61, 0.58),
    },
}


def C(name):
    if isinstance(name, tuple):
        return name
    return P.get(name) or COMMON[name]


def lin(c):
    # oyunun tepe rengi geleneği (Mats.vc: vertex_color_is_srgb = false): palet değerleri doğrudan yazılır
    return tuple(c)


# ------------------------------------------------------------ dönüşüm yığını
class at:
    """with at((x,y,z), rz=..): alt montajlar yerel koordinatta kurulur."""
    def __init__(self, loc=(0, 0, 0), rz=0.0, rx=0.0, ry=0.0, s=1.0, m=None):
        self.m = m if m is not None else Matrix.Translation(Vector(loc)) @ Euler((rx, ry, rz)).to_matrix().to_4x4() @ Matrix.Scale(s, 4)

    def __enter__(self):
        XF.append(XF[-1] @ self.m)
        return self

    def __exit__(self, *a):
        XF.pop()


def frame_ab(a, b, up=(0, 0, 1)):
    """a'dan b'ye yerel Z ekseni (uzunluk boyunca) olan matris."""
    a = Vector(a); b = Vector(b)
    z = (b - a)
    L = z.length
    z.normalize()
    upv = Vector(up)
    if abs(z.dot(upv)) > 0.98:
        upv = Vector((1, 0, 0)) if abs(z.x) < 0.9 else Vector((0, 1, 0))
    x = upv.cross(z).normalized()
    y = z.cross(x)
    M = Matrix((x, y, z)).transposed().to_4x4()
    M.translation = a
    return M, L


# ------------------------------------------------------------ çekirdek: geçici bmesh → ortak ağ
def _emit(tb, col, mat="vc", jit=0.045, dirt=True, M=None):
    M = XF[-1] if M is None else XF[-1] @ M
    base = C(col)
    k = 1.0 + RND.uniform(-jit, jit)
    hue = RND.uniform(-jit, jit) * 0.4
    c0 = Vector(lin((min(1, base[0] * k * (1 + hue)), min(1, base[1] * k), min(1, base[2] * k * (1 - hue)))))
    mi = MATS.index(mat)
    neg = M.to_3x3().determinant() < 0
    vm = {}
    for v in tb.verts:
        vm[v] = B.verts.new(M @ v.co)
    dc = Vector(lin((0.36, 0.3, 0.22)))
    lampish = mat.startswith("lamp") or mat == "flag"
    for f in tb.faces:
        vs = [vm[v] for v in f.verts]
        if neg:
            vs.reverse()
        try:
            nf = B.faces.new(vs)
        except ValueError:
            continue
        nf.material_index = mi
        nf.smooth = f.smooth
        for l in nf.loops:
            c = c0
            if dirt and not lampish:
                z = l.vert.co.z
                t = 1.0 - min(1.0, max(0.0, z / 0.45))
                c = c0.lerp(dc, t * t * 0.45)
            l[CL] = (c.x, c.y, c.z, 1.0)
    tb.free()


def _bev(tb, w, seg=1, edges=None):
    if w <= 0:
        return
    es = edges if edges is not None else list(tb.edges)
    if es:
        bmesh.ops.bevel(tb, geom=es, offset=w, offset_type='OFFSET', segments=seg, profile=0.5, affect='EDGES', clamp_overlap=True)


def _rotm(r):
    if r is None:
        return Matrix.Identity(4)
    if isinstance(r, (int, float)):
        r = (0, 0, r)
    return Euler(r).to_matrix().to_4x4()


def _subdiv(tb, step=1.0):
    """Uzun kenarları böl (köşe başına AO için büyük yüzlerde ara tepe noktaları)."""
    groups = {}
    for e in tb.edges:
        L = e.calc_length()
        if L > step * 1.3:
            groups.setdefault(int(math.ceil(L / step)) - 1, []).append(e)
    for cuts, es in groups.items():
        bmesh.ops.subdivide_edges(tb, edges=es, cuts=cuts, use_grid_fill=True)


def box(c, s, col, mat="vc", r=None, bev=0.015, seg=1, dirt=True, jit=0.045):
    tb = bmesh.new()
    bmesh.ops.create_cube(tb, size=1.0)
    for v in tb.verts:
        v.co = Vector((v.co.x * s[0], v.co.y * s[1], v.co.z * s[2]))
    if bev > 0:
        _bev(tb, min(bev, min(s) * 0.3), seg)
    if max(s) > 1.4 and min(s) > 0.02:
        _subdiv(tb, 1.0)
    _emit(tb, col, mat, jit, dirt, Matrix.Translation(Vector(c)) @ _rotm(r))


def box2(p0, p1, col, mat="vc", bev=0.015, **kw):
    """İki köşeden kutu."""
    c = [(a + b) * 0.5 for a, b in zip(p0, p1)]
    s = [abs(b - a) for a, b in zip(p0, p1)]
    box(c, s, col, mat, bev=bev, **kw)


def cyl(c, r, h, col, mat="vc", rot=None, seg=12, r2=None, bev=0.0, caps=True, smooth=True, dirt=True, jit=0.045):
    """Z ekseni boyunca merkezli silindir/koni."""
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=caps, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=h)
    for f in tb.faces:
        f.smooth = smooth and len(f.verts) == 4
    if bev > 0 and caps:
        es = [e for e in tb.edges if any(len(f.verts) > 4 for f in e.link_faces)]
        _bev(tb, min(bev, h * 0.3, r * 0.3), 1, es)
        for f in tb.faces:
            if len(f.verts) == 4:
                n = f.normal
                f.smooth = smooth and abs(n.z) < 0.5
    _emit(tb, col, mat, jit, dirt, Matrix.Translation(Vector(c)) @ _rotm(rot))


def cyl_ab(a, b, r, col, mat="vc", seg=8, r2=None, bev=0.0, caps=True, smooth=True, dirt=True):
    M, L = frame_ab(a, b)
    if L < 1e-5:
        return
    tb = bmesh.new()
    bmesh.ops.create_cone(tb, cap_ends=caps, cap_tris=False, segments=seg, radius1=r, radius2=r if r2 is None else r2, depth=L)
    for v in tb.verts:
        v.co.z += L * 0.5
    for f in tb.faces:
        f.smooth = smooth and len(f.verts) == 4
    if bev > 0 and caps:
        es = [e for e in tb.edges if any(len(f.verts) > 4 for f in e.link_faces)]
        _bev(tb, min(bev, r * 0.3), 1, es)
    _emit(tb, col, mat, 0.045, dirt, M)


def bar_ab(a, b, w, h, col, mat="vc", bev=0.0, up=(0, 0, 1)):
    """Kare/dikdörtgen kesitli çubuk a→b (w: yatay, h: dikey)."""
    M, L = frame_ab(a, b, up)
    if L < 1e-5:
        return
    tb = bmesh.new()
    bmesh.ops.create_cube(tb, size=1.0)
    for v in tb.verts:
        v.co = Vector((v.co.x * w, v.co.y * h, v.co.z * L + L * 0.5))
    if bev > 0:
        _bev(tb, min(bev, w * 0.3, h * 0.3))
    _emit(tb, col, mat, 0.045, True, M)


def ibeam_ab(a, b, h, w, col, mat="metal", up=(0, 0, 1), tf=None, tw=None):
    """I profil kiriş a→b; h gövde yüksekliği (yerel Y), w başlık genişliği (yerel X)."""
    M, L = frame_ab(a, b, up)
    tf = tf or max(0.012, h * 0.07)
    tw = tw or max(0.008, h * 0.045)
    with at(m=M):
        box((0, (h - tf) * 0.5, L * 0.5), (w, tf, L), col, mat, bev=0.0)
        box((0, -(h - tf) * 0.5, L * 0.5), (w, tf, L), col, mat, bev=0.0)
        box((0, 0, L * 0.5), (tw, h - 2 * tf, L), col, mat, bev=0.0)


def lathe(prof, col, c=(0, 0, 0), rot=None, seg=24, mat="vc", smooth=True, cap0=False, cap1=False, dirt=True, a0=0.0, a1=None):
    """(r, z) profilini Z ekseni etrafında döndür."""
    tb = bmesh.new()
    full = a1 is None
    a1 = math.tau if full else a1
    n = seg if full else seg + 1
    rings = []
    for i in range(n):
        a = a0 + (a1 - a0) * i / seg
        ca, sa = math.cos(a), math.sin(a)
        rings.append([tb.verts.new((r * ca, r * sa, z)) for r, z in prof])
    pairs = list(zip(rings, rings[1:])) + ([(rings[-1], rings[0])] if full else [])
    for r0, r1 in pairs:
        for j in range(len(prof) - 1):
            q = (r0[j], r1[j], r1[j + 1], r0[j + 1])
            if len(set(q)) < 4:
                continue
            try:
                f = tb.faces.new(q)
                f.smooth = smooth
            except ValueError:
                pass
    if full and cap0 and prof[0][0] > 0:
        f = tb.faces.new([r[0] for r in rings][::-1])
    if full and cap1 and prof[-1][0] > 0:
        f = tb.faces.new([r[-1] for r in rings])
    bmesh.ops.remove_doubles(tb, verts=tb.verts, dist=1e-5)
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    _emit(tb, col, mat, 0.045, dirt, Matrix.Translation(Vector(c)) @ _rotm(rot))


def prism(pts, h, col, c=(0, 0, 0), rot=None, mat="vc", bev=0.0, dirt=True):
    """Yerel XY düzleminde çokgen, +Z boyunca h kalınlık."""
    tb = bmesh.new()
    a = [tb.verts.new((x, y, 0)) for x, y in pts]
    b = [tb.verts.new((x, y, h)) for x, y in pts]
    n = len(pts)
    tb.faces.new(a[::-1])
    tb.faces.new(b)
    for i in range(n):
        j = (i + 1) % n
        tb.faces.new((a[i], a[j], b[j], b[i]))
    bmesh.ops.recalc_face_normals(tb, faces=tb.faces)
    if bev > 0:
        _bev(tb, bev)
    _emit(tb, col, mat, 0.045, dirt, Matrix.Translation(Vector(c)) @ _rotm(rot))


def prism_x(pts, x0, x1, col, mat="vc", bev=0.0, dirt=True):
    """YZ düzleminde (y,z) çokgen → X boyunca x0..x1."""
    with at(m=Matrix.Translation((x0, 0, 0)) @ Matrix(((0, 0, 1, 0), (1, 0, 0, 0), (0, 1, 0, 0), (0, 0, 0, 1)))):
        prism(pts, x1 - x0, col, mat=mat, bev=bev, dirt=dirt)


def poly(pts, col, mat="vc", smooth=False, dirt=True, two=False):
    """Tek yüz (3B noktalar)."""
    tb = bmesh.new()
    vs = [tb.verts.new(p) for p in pts]
    f = tb.faces.new(vs)
    f.smooth = smooth
    if two:
        vs2 = [tb.verts.new(p) for p in pts]
        tb.faces.new(vs2[::-1])
    _emit(tb, col, mat, 0.03, dirt)


def grid_surf(fn, nu, nv, col, mat="vc", smooth=True, two=False, jit=0.03, colfn=None, dirt=True):
    """fn(u,v)->(x,y,z) parametrik yüzey (u,v ∈ [0,1])."""
    tb = bmesh.new()
    vs = [[tb.verts.new(fn(i / nu, j / nv)) for j in range(nv + 1)] for i in range(nu + 1)]
    for i in range(nu):
        for j in range(nv):
            f = tb.faces.new((vs[i][j], vs[i + 1][j], vs[i + 1][j + 1], vs[i][j + 1]))
            f.smooth = smooth
            if two:
                g = tb.faces.new((tb.verts.new(vs[i][j].co), tb.verts.new(vs[i][j + 1].co), tb.verts.new(vs[i + 1][j + 1].co), tb.verts.new(vs[i + 1][j].co)))
                g.smooth = smooth
    if colfn is None:
        _emit(tb, col, mat, jit, dirt)
    else:
        # yüz başına renk (kamuflaj ağı lekeleri)
        M = XF[-1]
        mi = MATS.index(mat)
        vm = {v: B.verts.new(M @ v.co) for v in tb.verts}
        for f in tb.faces:
            nf = B.faces.new([vm[v] for v in f.verts])
            nf.material_index = mi
            nf.smooth = f.smooth
            cc = Vector(lin(C(colfn(f.calc_center_median()))))
            for l in nf.loops:
                l[CL] = (cc.x, cc.y, cc.z, 1.0)
        tb.free()


def corr(o, u, v, L, H, col, pitch=0.2, depth=0.035, mat="vc", sine=False, back=None, dirt=True):
    """Oluklu sac: o köşesinden u boyunca L (oluk yönüne dik), v boyunca H; dışa normal = u × v.
    back: arka yüz rengi (verilirse düz arka levha)."""
    o = Vector(o); u = Vector(u).normalized(); v = Vector(v).normalized()
    n = u.cross(v).normalized()
    per = max(1, int(round(L / pitch)))
    p = L / per
    if sine:
        prof = []
        for i in range(per * 6 + 1):
            t = i / 6.0
            prof.append((t * p, (1 - math.cos(t * math.tau)) * 0.5))
    else:
        prof = [(0.0, 0.0)]
        for i in range(per):
            b = i * p
            prof += [(b + 0.12 * p, 0.0), (b + 0.3 * p, 1.0), (b + 0.7 * p, 1.0), (b + 0.88 * p, 0.0), (b + p, 0.0)]
        # yinelenenleri ayıkla
        pr2 = [prof[0]]
        for q in prof[1:]:
            if abs(q[0] - pr2[-1][0]) > 1e-6:
                pr2.append(q)
        prof = pr2
    tb = bmesh.new()
    nv = max(1, int(math.ceil(H / 1.1)))
    rows = [[tb.verts.new(o + u * a + n * (h * depth) + v * (H * k / nv)) for a, h in prof] for k in range(nv + 1)]
    for k in range(nv):
        lo, hi = rows[k], rows[k + 1]
        for i in range(len(prof) - 1):
            f = tb.faces.new((lo[i], lo[i + 1], hi[i + 1], hi[i]))
            f.smooth = sine
    # normal yönü: dışa
    for f in tb.faces:
        f.normal_update()
        if f.normal.dot(n) < 0:
            f.normal_flip()
    if back is not None:
        ob_ = o - n * 0.006
        a0 = tb.verts.new(ob_); a1 = tb.verts.new(ob_ + u * L); a2 = tb.verts.new(ob_ + u * L + v * H); a3 = tb.verts.new(ob_ + v * H)
        f = tb.faces.new((a0, a1, a2, a3))
        f.normal_update()
        if f.normal.dot(n) > 0:
            f.normal_flip()
    _emit(tb, col, mat, 0.03, dirt)


def wall_cells(L, z0, z1, holes):
    """Duvar dikdörtgenini boşluklar (merkez x, merkez z, w, h) dışında parçalara böl → [(xa, xb, za, zb)]."""
    xs = {0.0, L}
    hs = []
    for (x, z, w, h) in holes:
        a, b = max(0.0, x - w / 2), min(L, x + w / 2)
        if b > a:
            xs.update((a, b))
            hs.append((a, b, max(z0, z - h / 2), min(z1, z + h / 2)))
    xs = sorted(xs)
    out = []
    for xa, xb in zip(xs, xs[1:]):
        if xb - xa < 1e-4:
            continue
        m = (xa + xb) / 2
        cut = sorted((hz0, hz1) for (a, b, hz0, hz1) in hs if a <= m <= b)
        cur = z0
        for hz0, hz1 in cut:
            if hz0 - cur > 0.01:
                out.append((xa, xb, cur, hz0))
            cur = max(cur, hz1)
        if z1 - cur > 0.01:
            out.append((xa, xb, cur, z1))
    return out


# ------------------------------------------------------------ yapı detayları (cephe yerel çerçevesi: X duvar boyunca, Z yukarı, -Y dışa)
def window(x, z, w, h, frame="white", glass="glass", depth=0.12, mull=1, tr=0, sill=True, bars=False, flush=False):
    """Duvar yüzü y=0'da; pencere kasası, cam (içeride), kayıt, denizlik.
    flush: boşluksuz düz duvar (konteyner, kabin) — cam yüzeyin hemen önünde."""
    t = 0.06
    fy = -0.03 if flush else -0.02
    box((x, fy, z + h / 2 - t / 2), (w, 0.08 if not flush else 0.04, t), frame, bev=0.008)
    box((x, fy, z - h / 2 + t / 2), (w, 0.08 if not flush else 0.04, t), frame, bev=0.008)
    box((x - w / 2 + t / 2, fy, z), (t, 0.08 if not flush else 0.04, h), frame, bev=0.008)
    box((x + w / 2 - t / 2, fy, z), (t, 0.08 if not flush else 0.04, h), frame, bev=0.008)
    if flush:
        box((x, -0.012, z), (w - 0.04, 0.02, h - 0.04), glass, "glass", bev=0.0, dirt=False)
    else:
        box((x, depth * 0.5, z), (w - 0.04, 0.02, h - 0.04), glass, "glass", bev=0.0, dirt=False)
        box((x, depth * 0.5 + 0.08, z), (w, 0.04, h), "dark", bev=0.0, dirt=False)   # iç karanlık
        # pervaz içi (derinlik)
        box((x, depth * 0.25, z + h / 2 + 0.01), (w, depth * 0.5, 0.02), "trim", bev=0.0)
        box((x, depth * 0.25, z - h / 2 - 0.01), (w, depth * 0.5, 0.02), "trim", bev=0.0)
    for k in range(1, mull + 1):
        xx = x - w / 2 + w * k / (mull + 1)
        box((xx, fy, z), (0.045, 0.05, h - 0.06), frame, bev=0.0)
    if tr:
        box((x, fy, z + h / 2 - tr), (w - 0.06, 0.05, 0.045), frame, bev=0.0)
    if sill:
        box((x, -0.06, z - h / 2 - 0.03), (w + 0.12, 0.16, 0.04), "steel", "metal", bev=0.006)
    if bars:
        for k in range(int(w / 0.14)):
            xx = x - w / 2 + 0.07 + k * 0.14
            cyl((xx, -0.1, z), 0.009, h, "dark", "metal", seg=4, smooth=False)
        for zz in (z - h * 0.3, z + h * 0.3):
            box((x, -0.1, zz), (w, 0.012, 0.03), "dark", "metal", bev=0.0)


def door(x, w, h, col="door", frame="trim", z0=0.0, panels=True, handle=True, open_=0.0, glass=False):
    box((x - w / 2 - 0.04, -0.03, z0 + h / 2 + 0.03), (0.08, 0.1, h + 0.06), frame, bev=0.008)
    box((x + w / 2 + 0.04, -0.03, z0 + h / 2 + 0.03), (0.08, 0.1, h + 0.06), frame, bev=0.008)
    box((x, -0.03, z0 + h + 0.05), (w + 0.16, 0.1, 0.08), frame, bev=0.008)
    box((x, 0.08, z0 + h / 2), (w, 0.02, h), "dark", bev=0.0, dirt=False)
    if open_ > 0:
        a = -open_ * 1.4
        with at((x - w / 2, 0.0, z0), rz=a):
            box((w / 2, -0.025, h / 2), (w - 0.02, 0.045, h - 0.02), col, bev=0.008)
        return
    box((x, 0.0, z0 + h / 2), (w - 0.02, 0.045, h - 0.02), col, bev=0.008)
    if panels:
        for zz in (0.28, 0.72):
            box((x, -0.03, z0 + h * zz), (w * 0.7, 0.02, h * 0.32), col, bev=0.006)
    if glass:
        box((x, -0.035, z0 + h * 0.75), (w * 0.4, 0.02, h * 0.2), "glass", "glass", bev=0.0)
    if handle:
        box((x + w * 0.36, -0.06, z0 + 1.0), (0.12, 0.03, 0.025), "steel", "metal", bev=0.0)
        box((x + w * 0.36, -0.035, z0 + 1.0), (0.05, 0.03, 0.14), "steel", "metal", bev=0.0)


def louver(x, z, w, h, col="steel", n=None, mat="metal"):
    n = n or max(3, int(h / 0.07))
    box((x, -0.01, z), (w + 0.06, 0.04, h + 0.06), col, mat, bev=0.006)
    box((x, 0.02, z), (w, 0.02, h), "black", bev=0.0, dirt=False)
    for i in range(n):
        zz = z - h / 2 + (i + 0.5) * h / n
        box((x, -0.025, zz), (w - 0.02, 0.012, h / n * 1.1), col, mat, r=(0.6, 0, 0), bev=0.0)


def lamp_wall(x, z, col="steel"):
    box((x, -0.05, z), (0.08, 0.1, 0.1), col, "metal", bev=0.006)
    box((x, -0.16, z + 0.02), (0.3, 0.2, 0.06), col, "metal", r=(-0.25, 0, 0), bev=0.006)
    box((x, -0.18, z - 0.02), (0.24, 0.14, 0.02), "lamp", "lamp", r=(-0.25, 0, 0), bev=0.0)


def downpipe(x, z0, z1, col="galv", y=-0.08):
    cyl((x, y, (z0 + z1) / 2 + 0.1), 0.045, z1 - z0 - 0.2, col, "metal", seg=8)
    for zz in [z0 + 0.6 + k * 1.4 for k in range(int((z1 - z0 - 0.8) / 1.4) + 1)]:
        box((x, y + 0.05, zz), (0.12, 0.05, 0.03), col, "metal", bev=0.0)
    cyl_ab((x, y, z0 + 0.12), (x, y - 0.22, z0 + 0.02), 0.045, col, "metal", seg=8)
    cyl_ab((x, y, z1 - 0.1), (x, y + 0.08, z1 + 0.02), 0.045, col, "metal", seg=8)


def railing(a, b, h=1.05, col="yellow", posts=1.2, r=0.024):
    a = Vector(a); b = Vector(b)
    L = (b - a).length
    n = max(1, int(math.ceil(L / posts)))
    for i in range(n + 1):
        p = a.lerp(b, i / n)
        cyl_ab(p, p + Vector((0, 0, h)), r, col, "metal", seg=6)
    cyl_ab(a + Vector((0, 0, h)), b + Vector((0, 0, h)), r, col, "metal", seg=6)
    cyl_ab(a + Vector((0, 0, h * 0.5)), b + Vector((0, 0, h * 0.5)), r * 0.8, col, "metal", seg=6)


def stairs(p0, p1, w, col="steel", rail="yellow", mat="metal"):
    """Dış merdiven: p0 (alt, zemin) → p1 (üst sahanlık), yerel ok yönünde."""
    p0 = Vector(p0); p1 = Vector(p1)
    d = p1 - p0
    hz = d.z
    n = max(3, int(hz / 0.19))
    hor = Vector((d.x, d.y, 0))
    yaw = math.atan2(hor.y, hor.x)
    side = Vector((-math.sin(yaw), math.cos(yaw), 0)) * (w / 2)
    for s in (-1, 1):
        bar_ab(p0 + side * s, p1 + side * s, 0.04, 0.2, col, mat, up=(0, 0, 1))
    for i in range(n):
        t = (i + 0.5) / n
        p = p0.lerp(p1, t)
        with at(p, rz=yaw):
            box((0, 0, 0.0), (hor.length / n * 1.05, w - 0.08, 0.035), col, mat, bev=0.0)
            for k in range(4):
                box((-hor.length / n * 0.3 + k * hor.length / n * 0.2, 0, 0.02), (0.012, w - 0.1, 0.012), "dark", mat, bev=0.0)
    for s in (-1, 1):
        q0 = p0 + side * s * 1.05
        q1 = p1 + side * s * 1.05
        cyl_ab(q0 + Vector((0, 0, 0.95)), q1 + Vector((0, 0, 0.95)), 0.022, rail, "metal", seg=6)
        for t in (0.0, 0.5, 1.0):
            q = q0.lerp(q1, t)
            cyl_ab(q, q + Vector((0, 0, 0.95)), 0.02, rail, "metal", seg=6)


# ------------------------------------------------------------ dekor / ekipman (yerel koordinatta, z=0 zemin)
def drum(p, col="olive", lid="dark", rz=0.0, lying=False):
    if lying:
        with at(p, rz=rz):
            cyl((0, 0, 0.29), 0.29, 0.88, col, rot=(0, math.pi / 2, 0), seg=14, bev=0.015)
            for x in (-0.22, 0.22):
                cyl((x, 0, 0.29), 0.3, 0.03, col, rot=(0, math.pi / 2, 0), seg=14)
        return
    with at(p, rz=rz):
        cyl((0, 0, 0.44), 0.29, 0.88, col, seg=14, bev=0.012)
        for z in (0.29, 0.59):
            cyl((0, 0, z), 0.3, 0.03, col, seg=14)
        cyl((0, 0, 0.885), 0.292, 0.012, lid, seg=14)
        cyl((0.15, 0.08, 0.895), 0.03, 0.02, "steel", "metal", seg=6)
        cyl((-0.16, -0.05, 0.895), 0.02, 0.02, "steel", "metal", seg=6)


def jerrycan(p, col="olive", rz=0.0):
    with at(p, rz=rz):
        box((0, 0, 0.235), (0.165, 0.345, 0.47), col, bev=0.025)
        for s in (-1, 1):
            box((s * 0.084, 0, 0.23), (0.01, 0.22, 0.3), col, bev=0.0)
        box((0, 0.0, 0.5), (0.03, 0.2, 0.04), col, bev=0.008)
        cyl((0, 0.13, 0.49), 0.028, 0.05, "dark", seg=6)


def crate(p, s, col="crate", rz=0.0, ry=0.0, bands=True, stencil=None):
    with at(p, rz=rz):
        box((0, 0, s[2] / 2), s, col, bev=0.012)
        # çıta çerçeve
        for x in (-1, 1):
            box((x * (s[0] / 2 - 0.03), 0, s[2] / 2), (0.06, s[1] + 0.02, s[2] - 0.01), col, bev=0.006)
        if bands:
            for y in (-s[1] * 0.3, s[1] * 0.3):
                box((0, y, s[2] / 2), (s[0] + 0.012, 0.03, s[2] + 0.012), "dark", "metal", bev=0.0)
        if stencil:
            box((0, -s[1] / 2 - 0.004, s[2] * 0.55), (s[0] * 0.4, 0.006, s[2] * 0.22), stencil, bev=0.0, dirt=False)
        box((s[0] / 2 + 0.01, 0, s[2] * 0.6), (0.03, 0.14, 0.03), "dark", "metal", bev=0.0)
        box((-s[0] / 2 - 0.01, 0, s[2] * 0.6), (0.03, 0.14, 0.03), "dark", "metal", bev=0.0)


def ammo_box(p, rz=0.0, col="olive"):
    with at(p, rz=rz):
        box((0, 0, 0.09), (0.3, 0.16, 0.18), col, "metal", bev=0.01)
        box((0, 0, 0.19), (0.31, 0.17, 0.02), col, "metal", bev=0.004)
        box((0, 0, 0.215), (0.12, 0.03, 0.02), "dark", "metal", bev=0.0)
        box((0.15, 0, 0.17), (0.02, 0.06, 0.04), "steel", "metal", bev=0.0)


def pallet(p, w=1.2, d=1.0, rz=0.0, col="wood"):
    with at(p, rz=rz):
        for y in (-d / 2 + 0.05, 0, d / 2 - 0.05):
            box((0, y, 0.05), (w, 0.1, 0.1), col, bev=0.006)
        for i in range(7):
            box((-w / 2 + 0.07 + i * (w - 0.14) / 6, 0, 0.12), (0.1, d, 0.022), col, bev=0.003)


def tyre(p, r=0.5, w=0.32, rot=None, col="rubber", hub="steel", seg=20):
    """Lastik: yanak + diş sırtı + jant (Z ekseni boyunca)."""
    ri = r * 0.58
    prof = [(ri, -w * 0.38), (r * 0.82, -w * 0.5), (r * 0.97, -w * 0.46), (r, -w * 0.32), (r, w * 0.32), (r * 0.97, w * 0.46), (r * 0.82, w * 0.5), (ri, w * 0.38)]
    lathe(prof, col, c=p, rot=rot, seg=seg, smooth=True)
    # diş blokları
    rr = rot or (0, 0, 0)
    with at(p, rx=rr[0], ry=rr[1], rz=rr[2]):
        for k in range(seg):
            a = k * math.tau / seg
            box((math.cos(a) * (r + 0.008), math.sin(a) * (r + 0.008), (0.08 if k % 2 else -0.08) * w), (0.03, r * 0.22, w * 0.42), col, r=(0, 0, a), bev=0.0)
        if hub:
            cyl((0, 0, 0), ri * 1.02, w * 0.7, hub, "metal", seg=14, bev=0.01)
            cyl((0, 0, w * 0.36), ri * 0.4, 0.04, "dark", "metal", seg=8)


def tyre_stack(p, n=4, r=0.5, w=0.3, hub=None):
    for i in range(n):
        tyre((p[0] + RND.uniform(-0.03, 0.03), p[1] + RND.uniform(-0.03, 0.03), w * 0.5 + i * w * 0.98), r, w, (0, 0, RND.uniform(0, 1)), hub=hub, seg=16)


def gas_bottle(p, col="olive", h=1.4, r=0.11):
    with at(p):
        lathe([(0.0, 0.0), (r, 0.0), (r, h - r * 0.6), (r * 0.5, h - 0.04), (0.03, h)], col, seg=12)
        cyl((0, 0, h + 0.04), 0.025, 0.08, "steel", "metal", seg=6)
        cyl((0, 0, h + 0.09), 0.04, 0.03, "dark", "metal", seg=6, rot=(math.pi / 2, 0, 0))


def fire_ext(p, rz=0.0):
    with at(p, rz=rz):
        cyl((0, 0, 0.3), 0.085, 0.55, "red", seg=12, bev=0.01)
        cyl((0, 0, 0.62), 0.02, 0.1, "dark", "metal", seg=6)
        box((0.04, 0, 0.66), (0.12, 0.02, 0.02), "dark", "metal", bev=0.0)


def bag(c, s, col="bag", rz=0.0):
    box(c, s, col, r=(0, 0, rz), bev=min(s) * 0.32, seg=1, jit=0.07)


def sandbag_wall(a, b, rows=3, col="bag", bl=0.58, bw=0.32, bh=0.15, thick=2):
    """a→b boyunca şaşırtmalı kum torbası duvarı (yerel z=0)."""
    a = Vector(a); b = Vector(b)
    d = b - a
    L = d.length
    yaw = math.atan2(d.y, d.x)
    with at(a, rz=yaw):
        for r in range(rows):
            off = (bl * 0.5) if r % 2 else 0.0
            n = int((L - off) / bl)
            th = thick if r < rows - 1 else max(1, thick - 1) if thick > 1 and rows > 2 else thick
            for k in range(th):
                yy = (k - (th - 1) / 2) * (bw * 0.98)
                for i in range(n):
                    x = off + (i + 0.5) * bl
                    bag((x + RND.uniform(-0.02, 0.02), yy + RND.uniform(-0.015, 0.015), bh * 0.5 + r * bh * 0.92), (bl * 0.97, bw, bh), col, RND.uniform(-0.05, 0.05))


def hesco(c, w=1.0, d=1.0, h=1.2, rz=0.0, wire=True, liner="hesco", fill="fill", sides=(1, 1, 1, 1)):
    """HESCO bastion hücresi: geotekstil astar, tel kafes, toprak dolgu (üstte biraz çökük)."""
    with at(c, rz=rz):
        box((0, 0, h / 2 - 0.02), (w - 0.03, d - 0.03, h - 0.04), liner, bev=0.03, jit=0.06)
        box((0, 0, h - 0.06), (w - 0.1, d - 0.1, 0.06), fill, bev=0.0, jit=0.08)
        if not wire:
            return
        g = 0.33
        nx = max(1, int(round(w / g)))
        ny = max(1, int(round(d / g)))
        nz = max(1, int(round(h / g)))
        wc = "steel"
        # dikey teller ve yatay teller: dört yüz (sides: -y, +x, +y, -x)
        for si, (sx, sy, L, nn) in enumerate(((0, -1, w, nx), (1, 0, d, ny), (0, 1, w, nx), (-1, 0, d, ny))):
            if not sides[si]:
                continue
            for i in range(nn + 1):
                t = -L / 2 + i * L / nn
                px = sx * (w / 2) + (t if sy != 0 else 0)
                py = sy * (d / 2) + (t if sx != 0 else 0)
                box((px, py, h / 2), (0.018, 0.018, h), wc, "metal", bev=0.0, dirt=False)
            for k in range(nz + 1):
                z = k * h / nz
                if sy != 0:
                    box((0, sy * (d / 2), z), (w, 0.016, 0.016), wc, "metal", bev=0.0, dirt=False)
                else:
                    box((sx * (w / 2), 0, z), (0.016, d, 0.016), wc, "metal", bev=0.0, dirt=False)


def hesco_row(a, b, w=1.0, d=1.0, h=1.2, out_only=True, **kw):
    a = Vector(a); b = Vector(b)
    dv = b - a
    L = dv.length
    yaw = math.atan2(dv.y, dv.x)
    n = max(1, int(round(L / w)))
    ww = L / n
    with at(a, rz=yaw):
        for i in range(n):
            sides = (1, 1 if i == n - 1 else 0, 1, 1 if i == 0 else 0)
            hesco(((i + 0.5) * ww, 0, 0), ww, d, h, 0.0, sides=sides, **kw)


def concertina(a, b, r=0.38, pitch=0.22, col="steel", z=None):
    """Jiletli tel bobini (sarmal): a→b."""
    a = Vector(a); b = Vector(b)
    M, L = frame_ab(a, b)
    turns = max(1, int(L / pitch))
    n = turns * 10
    pts = []
    for i in range(n + 1):
        t = i / n
        ang = t * turns * math.tau
        pts.append(M @ Vector((math.cos(ang) * r, math.sin(ang) * r + 0.0, t * L)))
    tb = bmesh.new()
    prev = None
    for i in range(len(pts) - 1):
        p0, p1 = pts[i], pts[i + 1]
        dv = (p1 - p0).normalized()
        sx = dv.cross(Vector((0, 0, 1)))
        if sx.length < 1e-3:
            sx = Vector((1, 0, 0))
        sx.normalize()
        sy = dv.cross(sx).normalized()
        k = 0.008
        q0 = [p0 + sx * k, p0 - sx * k * 0.5 + sy * k * 0.86, p0 - sx * k * 0.5 - sy * k * 0.86]
        q1 = [p1 + sx * k, p1 - sx * k * 0.5 + sy * k * 0.86, p1 - sx * k * 0.5 - sy * k * 0.86]
        v0 = [tb.verts.new(q) for q in q0]
        v1 = [tb.verts.new(q) for q in q1]
        for j in range(3):
            tb.faces.new((v0[j], v0[(j + 1) % 3], v1[(j + 1) % 3], v1[j]))
    with at(m=Matrix.Identity(4)):
        _emit(tb, col, "metal", 0.0, False)


def camo_net(cx, cy, w, d, h, sag=0.35, col1="net", col2="net2", seed=1, poles=True, nu=None, nv=None, drop=None, holes=0.14, col3=None):
    """Kamuflaj ağı: direk tepelerinde kalkık, aralarda sarkık, kenarları sarkan; düzensiz kırışık yüzey,
    üç tonlu lekeler ve yer yer boşluklar (ağ dokusu). İki yüzlü (cloth)."""
    rnd = random.Random(seed)
    nu = nu or max(6, int(w / 0.35))
    nv = nv or max(6, int(d / 0.35))
    drop = min(h * 0.35, 0.9) if drop is None else drop
    col3 = col3 or ("olive2" if col1 != "olive2" else "net")
    pts = [(0.25, 0.25), (0.75, 0.25), (0.25, 0.75), (0.75, 0.75)]
    tb = bmesh.new()
    vs = []
    for i in range(nu + 1):
        row = []
        for j in range(nv + 1):
            u, v = i / nu, j / nv
            bump = max(math.exp(-((u - pu) ** 2 + (v - pv) ** 2) / 0.02) for pu, pv in pts)
            z = h - sag + sag * bump
            e = min(u, 1 - u, v, 1 - v)
            if e < 0.15:
                z -= (0.15 - e) / 0.15 * drop
            z += rnd.uniform(-0.09, 0.09)
            row.append(tb.verts.new((cx - w / 2 + u * w + rnd.uniform(-0.05, 0.05), cy - d / 2 + v * d + rnd.uniform(-0.05, 0.05), z)))
        vs.append(row)
    for i in range(nu):
        for j in range(nv):
            if 0 < i < nu - 1 and 0 < j < nv - 1 and rnd.random() < holes:
                continue
            tb.faces.new((vs[i][j], vs[i + 1][j], vs[i + 1][j + 1], vs[i][j + 1]))
    ph = rnd.uniform(0, 6)

    def colfn(c):
        k = math.sin(c.x * 1.3 + ph) + math.sin(c.y * 1.9 + c.x * 0.6 + ph) + rnd.uniform(-0.5, 0.5)
        return col1 if k > 0.4 else (col2 if k > -0.6 else col3)

    M = XF[-1]
    mi = MATS.index("cloth")
    vm = {v: B.verts.new(M @ v.co) for v in tb.verts}
    for f in tb.faces:
        nf = B.faces.new([vm[v] for v in f.verts])
        nf.material_index = mi
        cc = Vector(lin(C(colfn(f.calc_center_median()))))
        for l in nf.loops:
            l[CL] = (cc.x, cc.y, cc.z, 1.0)
    tb.free()
    if poles:
        for pu, pv in pts:
            x = cx - w / 2 + pu * w
            y = cy - d / 2 + pv * d
            cyl((x, y, h / 2), 0.03, h, "dark", "metal", seg=6)
            cyl((x, y, h + 0.02), 0.12, 0.04, "dark", seg=8)


def flagpole(p, h=6.0, col_pole="galv"):
    with at(p):
        cyl((0, 0, 0.15), 0.25, 0.3, "concrete", seg=10, bev=0.03)
        cyl((0, 0, h / 2), 0.045, h, col_pole, "metal", seg=10, r2=0.03)
        cyl((0, 0, h + 0.04), 0.06, 0.08, "yellow", "metal", seg=8)
        # bayrak: hafif dalgalı, iki yüzlü
        def fn(u, v):
            return (0.06 + u * 1.5, math.sin(u * 5.0) * 0.08 * u, h - 0.12 - v * 0.95)
        grid_surf(fn, 8, 2, "flag", "flag", smooth=True, two=True, dirt=False)
        cyl_ab((0.04, 0, h - 0.1), (0.04, 0, 0.9), 0.006, "white", seg=3)


def generator(p, rz=0.0, col="olive", trailer=True, big=1.0):
    """Taktik dizel jeneratör (kızaklı / römorklu): panjurlar, kontrol paneli, egzoz, kaldırma halkaları."""
    L, W, H = 2.0 * big, 1.0 * big, 1.15 * big
    z0 = 0.62 if trailer else 0.1
    with at(p, rz=rz):
        if trailer:
            for s in (-1, 1):
                tyre((L * 0.12, s * (W / 2 + 0.16), 0.36), 0.36, 0.22, (math.pi / 2, 0, 0), seg=14)
                box((L * 0.12, s * (W / 2 + 0.16), 0.66), (0.8, 0.3, 0.04), col, bev=0.008)  # çamurluk
            box((0, 0, 0.42), (L * 1.02, 0.12, 0.12), "dark", "metal", bev=0.0)
            for s in (-1, 1):
                box((0, s * (W / 2 - 0.08), 0.5), (L, 0.1, 0.1), "dark", "metal", bev=0.0)
            bar_ab((-L / 2, -0.3, 0.45), (-L / 2 - 1.0, 0, 0.42), 0.08, 0.08, "dark", "metal")
            bar_ab((-L / 2, 0.3, 0.45), (-L / 2 - 1.0, 0, 0.42), 0.08, 0.08, "dark", "metal")
            cyl((-L / 2 - 1.05, 0, 0.42), 0.06, 0.08, "steel", "metal", seg=8)
            cyl((-L / 2 - 0.85, 0, 0.22), 0.03, 0.42, "dark", "metal", seg=6)     # destek ayağı
            cyl((-L / 2 - 0.85, 0, 0.03), 0.07, 0.04, "dark", "metal", seg=8)
        else:
            for s in (-1, 1):
                box((0, s * (W / 2 - 0.08), 0.05), (L + 0.1, 0.12, 0.1), "dark", "metal", bev=0.0)
        box((0, 0, z0 + H / 2), (L, W, H), col, bev=0.025)
        # çatı kenarı ve kapak çizgileri
        box((0, 0, z0 + H + 0.02), (L - 0.06, W - 0.06, 0.04), col, bev=0.01)
        for s in (-1, 1):
            with at((0, s * W / 2, z0), rz=0 if s < 0 else math.pi):
                for x in (-L * 0.25, L * 0.12):
                    box((x, -0.008, H * 0.5), (L * 0.33, 0.01, H * 0.82), col, bev=0.004)
                    box((x + L * 0.14, -0.02, H * 0.5), (0.03, 0.03, 0.14), "dark", "metal", bev=0.0)
                louver(L * 0.38, H * 0.55, L * 0.16, H * 0.6, col, mat="vc")
        # ön: kontrol paneli
        with at((L / 2, 0, z0), rz=math.pi / 2):
            box((0, -0.03, H * 0.62), (W * 0.62, 0.06, H * 0.42), "dark", bev=0.006)
            for i in range(3):
                cyl((-0.15 + i * 0.15, -0.065, H * 0.7), 0.035, 0.02, "white", rot=(math.pi / 2, 0, 0), seg=10, dirt=False)
            box((0.0, -0.065, H * 0.5), (0.3, 0.01, 0.06), "red", bev=0.0, dirt=False)
        with at((-L / 2, 0, z0), rz=-math.pi / 2):
            louver(0, H * 0.5, W * 0.7, H * 0.6, col, mat="vc")
        # egzoz ve kaldırma halkaları
        cyl((-L * 0.3, W * 0.2, z0 + H + 0.25), 0.05, 0.5, "dark", "metal", seg=8)
        cyl_ab((-L * 0.3, W * 0.2, z0 + H + 0.5), (-L * 0.38, W * 0.2, z0 + H + 0.56), 0.05, "dark", "metal", seg=8)
        for x in (-L * 0.4, L * 0.4):
            for y in (-W * 0.38, W * 0.38):
                cyl((x, y, z0 + H + 0.08), 0.05, 0.02, "steel", "metal", rot=(math.pi / 2, 0, 0), seg=8)
        box((L * 0.2, -W * 0.25, z0 + H + 0.05), (0.18, 0.18, 0.06), "dark", bev=0.006)  # yakıt kapağı
        # kablo kangalı
        lathe([(0.12, 0.0), (0.22, 0.0), (0.22, 0.08), (0.12, 0.08)], "black", c=(L / 2 + 0.45, 0.2, 0.0), seg=14, cap0=False)


def ac_unit(p, rz=0.0, col="paint", w=0.9, d=0.6, h=0.75):
    """Klima / ECU ünitesi: ızgara, fan, servis kapakları."""
    with at(p, rz=rz):
        box((0, 0, h / 2), (w, d, h), col, bev=0.02)
        box((0, -d / 2 - 0.005, h * 0.55), (w * 0.62, 0.01, h * 0.62), "dark", bev=0.0, dirt=False)
        for i in range(7):
            box((0, -d / 2 - 0.012, h * 0.27 + i * h * 0.09), (w * 0.6, 0.012, 0.018), col, "metal", bev=0.0)
        cyl((0, -d / 2 - 0.02, h * 0.55), 0.05, 0.02, "dark", rot=(math.pi / 2, 0, 0), seg=8)
        box((w * 0.38, -d / 2 - 0.01, h * 0.5), (0.12, 0.01, h * 0.7), col, bev=0.0)
        for y in (-0.15, 0.15):
            cyl((w * 0.3, y, h + 0.02), 0.1, 0.04, "dark", seg=10)


def light_tower(p, rz=0.0, col="yellow", h=6.0, up=True):
    """Römorklu aydınlatma kulesi: teleskopik direk, 4 projektör."""
    with at(p, rz=rz):
        for s in (-1, 1):
            tyre((0, s * 0.72, 0.3), 0.3, 0.18, (math.pi / 2, 0, 0), seg=12)
        box((0, 0, 0.75), (1.6, 1.2, 0.9), col, bev=0.025)
        with at((0.8, 0, 0.3), rz=math.pi / 2):
            louver(0, 0.45, 0.8, 0.5, col, mat="vc")
        for sx in (-1, 1):
            for sy in (-1, 1):
                bar_ab((sx * 0.7, sy * 0.5, 0.4), (sx * 1.3, sy * 1.1, 0.06), 0.06, 0.06, col, "metal")
                cyl((sx * 1.3, sy * 1.1, 0.04), 0.09, 0.04, "dark", "metal", seg=8)
        hh = h if up else 2.4
        cyl((0.3, 0, 1.2 + (hh - 1.2) * 0.3), 0.07, (hh - 1.2) * 0.6, "galv", "metal", seg=8)
        cyl((0.3, 0, 1.2 + (hh - 1.2) * 0.7), 0.05, (hh - 1.2) * 0.6, "galv", "metal", seg=8)
        box((0.3, 0, hh), (0.1, 1.3, 0.08), "dark", "metal", bev=0.0)
        for k in range(4):
            y = -0.48 + k * 0.32
            with at((0.3, y, hh + 0.2), rz=math.pi * 0.25 if rz == 0 else 0):
                box((0, 0, 0), (0.18, 0.28, 0.3), "dark", "metal", r=(0, -0.35, 0), bev=0.01)
                box((0.095, 0, 0), (0.01, 0.24, 0.26), "lamp", "lamp", r=(0, -0.35, 0), bev=0.0)


def mast_guyed(p, h=12.0, col="galv", top="biconical", guy=4.5):
    """Gergili anten direği (OE-254 tipi): kademeli boru, gergi telleri, tepe elemanı."""
    with at(p):
        box((0, 0, 0.05), (0.5, 0.5, 0.1), "dark", "metal", bev=0.01)
        segs = 5
        for i in range(segs):
            r = 0.045 - i * 0.006
            cyl((0, 0, (i + 0.5) * h / segs), r, h / segs, col, "metal", seg=8)
            cyl((0, 0, (i + 1) * h / segs - 0.05), r + 0.012, 0.1, "dark", "metal", seg=8)
        if top == "biconical":
            for s in (-1, 1):
                for k in range(8):
                    a = k * math.tau / 8
                    cyl_ab((0, 0, h + 0.5), (math.cos(a) * 0.45, math.sin(a) * 0.45, h + 0.5 + s * 0.6), 0.01, "dark", "metal", seg=4)
            cyl((0, 0, h + 0.5), 0.05, 1.3, "dark", "metal", seg=8)
        elif top == "whip":
            cyl((0, 0, h + 1.2), 0.012, 2.4, "dark", "metal", seg=4)
        for lv in (0.45, 0.9):
            for k in range(4):
                a = k * math.tau / 4 + 0.6
                g = (math.cos(a) * guy * lv, math.sin(a) * guy * lv, 0.0)
                cyl_ab((0, 0, h * lv - 0.05), g, 0.006, "dark", "metal", seg=3)
        for k in range(4):
            a = k * math.tau / 4 + 0.6
            for lv in (0.45, 0.9):
                g = (math.cos(a) * guy * lv, math.sin(a) * guy * lv, 0.0)
                cyl((g[0], g[1], 0.15), 0.02, 0.3, "steel", "metal", seg=5)


def lattice_mast(p, h=14.0, w=0.45, col="red", col2="white", guy=5.0):
    """Üçgen kesitli kafes direk (kızıl-beyaz bantlı), gergi telleri, tepede çubuk antenler."""
    with at(p):
        cyl((0, 0, 0.15), 0.5, 0.3, "concrete", seg=8, bev=0.02)
        R = w / math.sqrt(3)
        corners = [(math.cos(a) * R, math.sin(a) * R) for a in (math.pi / 2, math.pi / 2 + math.tau / 3, math.pi / 2 + 2 * math.tau / 3)]
        nseg = int(h / 0.6)
        for i in range(3):
            x0, y0 = corners[i]
            band = 2.0
            z = 0.3
            k = 0
            while z < h:
                z1 = min(h, z + band)
                cyl_ab((x0, y0, z), (x0, y0, z1), 0.022, col if k % 2 == 0 else col2, "metal", seg=5)
                z = z1
                k += 1
        for j in range(nseg):
            z0 = 0.3 + j * (h - 0.3) / nseg
            z1 = 0.3 + (j + 1) * (h - 0.3) / nseg
            cc = col if int(z0 / 2.0) % 2 == 0 else col2
            for i in range(3):
                a = corners[i]; b = corners[(i + 1) % 3]
                cyl_ab((a[0], a[1], z0), (b[0], b[1], z1), 0.009, cc, "metal", seg=3)
                cyl_ab((a[0], a[1], z1), (b[0], b[1], z1), 0.009, cc, "metal", seg=3)
        # tepe: çubuk antenler ve ikaz lambası
        cyl((0, 0, h + 1.0), 0.02, 2.0, "dark", "metal", seg=5)
        for k in range(3):
            a = k * math.tau / 3
            cyl_ab((math.cos(a) * 0.1, math.sin(a) * 0.1, h - 0.4), (math.cos(a) * 0.5, math.sin(a) * 0.5, h + 1.2), 0.008, "dark", "metal", seg=4)
        cyl((0, 0, h + 2.05), 0.05, 0.1, "lamp_r", "lamp_r", seg=8)
        for lv in (0.5, 0.95):
            for k in range(3):
                a = k * math.tau / 3 + math.pi / 2
                cyl_ab((math.cos(a) * R, math.sin(a) * R, h * lv), (math.cos(a) * guy * lv, math.sin(a) * guy * lv, 0.0), 0.006, "dark", "metal", seg=3)


def sat_dish(p, d=2.4, rz=0.0, el=0.6, col="white", base="steel"):
    """Uydu anteni: parabolik çanak (arkada kaburgalar), besleme kolu, LNB, zemin ayakları."""
    R = d / 2
    with at(p, rz=rz):
        # tabanı: dört ayaklı çerçeve + balast blokları
        for sx in (-1, 1):
            for sy in (-1, 1):
                bar_ab((sx * 0.7, sy * 0.7, 0.05), (0, 0, 1.0), 0.06, 0.06, base, "metal")
                box((sx * 0.75, sy * 0.75, 0.1), (0.4, 0.4, 0.2), "concrete", bev=0.02)
        cyl((0, 0, 1.05), 0.09, 0.3, base, "metal", seg=10)
        with at((0, 0, 1.15 + R * 0.1), ry=-(math.pi / 2 - el)):
            # çanak: Z ekseni etrafında parabol (ağız +Z)
            prof = []
            for i in range(9):
                r = R * i / 8
                prof.append((r, r * r / (4 * R * 0.6)))
            depth = prof[-1][1]
            lathe(prof, col, c=(0, 0, 0.15), seg=24)
            lathe([(R, depth), (R - 0.04, depth - 0.02)], col, c=(0, 0, 0.15), seg=24)
            # arka yüz (ayrı kabuk, içe bakan normal)
            lathe([(r, z - 0.025) for r, z in prof][::-1], "steel", c=(0, 0, 0.15), seg=24)
            for k in range(6):
                a = k * math.tau / 6
                bar_ab((0, 0, 0.1), (math.cos(a) * R * 0.85, math.sin(a) * R * 0.85, 0.12 + depth * 0.6), 0.03, 0.03, base, "metal")
            # besleme kolları ve LNB
            for k in range(3):
                a = k * math.tau / 3 + math.pi / 2
                cyl_ab((math.cos(a) * R * 0.9, math.sin(a) * R * 0.9, depth + 0.12), (0, 0, R * 1.0), 0.015, base, "metal", seg=5)
            cyl((0, 0, R * 1.0), 0.06, 0.22, "dark", "metal", seg=10)
            cyl((0, 0, R * 1.0 - 0.14), 0.05, 0.08, "white", seg=10, r2=0.07)


def windsock(p, h=5.5, rz=0.6):
    with at(p):
        cyl((0, 0, 0.1), 0.35, 0.2, "concrete", seg=10, bev=0.02)
        cyl((0, 0, h / 2), 0.05, h, "white", "metal", seg=8)
        for k in range(int(h / 1.0)):
            cyl((0, 0, 0.5 + k * 1.0), 0.052, 0.5, "red", "metal", seg=8)
        cyl((0, 0, h + 0.06), 0.06, 0.12, "lamp_r", "lamp_r", seg=8)
        with at((0, 0, h - 0.15), rz=rz):
            cyl_ab((0, 0, 0), (0.25, 0, 0), 0.02, "dark", "metal", seg=6)
            lathe([(0.3, 0.0), (0.3, 0.02)], "dark", c=(0.25, 0, 0), rot=(0, math.pi / 2, 0), seg=14, smooth=False)
            # rüzgârla şişmiş, uca doğru incelen, hafif sarkık kumaş (turuncu-beyaz bantlar)
            L = 2.4
            for i in range(5):
                x0 = 0.27 + i * L / 5
                r0 = 0.3 - i * 0.03
                r1 = 0.3 - (i + 1) * 0.03
                sag0 = -0.05 * i
                sag1 = -0.05 * (i + 1)
                with at((x0, 0, sag0), ry=math.pi / 2 + math.atan2(0.05, L / 5)):
                    lathe([(r0, 0.0), (r1, L / 5)], "orange" if i % 2 == 0 else "white", seg=14, mat="cloth", dirt=False)


def stretcher(p, rz=0.0, legs=True, col="olive"):
    with at(p, rz=rz):
        z = 0.32 if legs else 0.1
        for s in (-1, 1):
            cyl_ab((-1.15, s * 0.28, z), (1.15, s * 0.28, z), 0.02, "steel", "metal", seg=6)
        box((0, 0, z), (1.9, 0.56, 0.015), col, mat="cloth", bev=0.0)
        if legs:
            for x in (-0.8, 0.8):
                for s in (-1, 1):
                    cyl_ab((x, s * 0.28, z), (x + 0.12, s * 0.28, 0), 0.016, "steel", "metal", seg=5)
        else:
            for x in (-0.7, 0.7):
                for s in (-1, 1):
                    box((x, s * 0.28, 0.05), (0.04, 0.04, 0.1), "steel", "metal", bev=0.0)


def red_cross(c, s, rz=0.0, rx=0.0, ground="white", circle=False, th=0.012):
    """Kırmızı haç paneli (beyaz zemin): yerel XZ düzleminde, -Y dışa."""
    with at(c, rz=rz, rx=rx):
        if circle:
            cyl((0, 0.0, 0), s * 0.5, th, ground, rot=(math.pi / 2, 0, 0), seg=24, smooth=False, dirt=False)
        else:
            box((0, 0, 0), (s, th, s), ground, bev=0.0, dirt=False)
        box((0, -th, 0), (s * 0.72, th, s * 0.22), "red", bev=0.0, dirt=False)
        box((0, -th, 0), (s * 0.22, th, s * 0.72), "red", bev=0.0, dirt=False)


def container(c, L=6.06, rz=0.0, col="paint", doors_end=1, H=2.59, W=2.44, door_open=False, corr_pitch=0.28):
    """ISO konteyner: oluklu yan duvarlar, köşe dökümleri, kapı kilit çubukları."""
    with at(c, rz=rz):
        # çerçeve
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((sx * (L / 2 - 0.08), sy * (W / 2 - 0.08), H / 2), (0.16, 0.16, H), col, bev=0.01)
                for z in (0.08, H - 0.08):
                    box((sx * (L / 2 - 0.09), sy * (W / 2 - 0.09), z), (0.18, 0.18, 0.16), col, bev=0.01)
                    box((sx * (L / 2 - 0.09), sy * (W / 2 - 0.09) - 0.0, z), (0.19, 0.1, 0.06), "dark", bev=0.0)
            box((sx * (L / 2 - 0.08), 0, 0.08), (0.14, W - 0.3, 0.16), col, bev=0.008)
            box((sx * (L / 2 - 0.08), 0, H - 0.08), (0.14, W - 0.3, 0.16), col, bev=0.008)
        for sy in (-1, 1):
            box((0, sy * (W / 2 - 0.08), 0.08), (L - 0.3, 0.16, 0.16), col, bev=0.008)
            box((0, sy * (W / 2 - 0.08), H - 0.08), (L - 0.3, 0.16, 0.16), col, bev=0.008)
        # oluklu yan duvarlar (iki uzun yüz)
        corr((-L / 2 + 0.16, -W / 2 + 0.05, 0.16), (1, 0, 0), (0, 0, 1), L - 0.32, H - 0.32, col, pitch=corr_pitch, depth=0.04, back=col)
        corr((L / 2 - 0.16, W / 2 - 0.05, 0.16), (-1, 0, 0), (0, 0, 1), L - 0.32, H - 0.32, col, pitch=corr_pitch, depth=0.04, back=col)
        # çatı: hafif oluklu
        corr((L / 2 - 0.16, W / 2 - 0.16, H - 0.06), (-1, 0, 0), (0, -1, 0), L - 0.32, W - 0.32, col, pitch=0.5, depth=0.02, back=col)
        # uç duvarlar: kapı uçta
        for e in (-1, 1):
            with at((e * L / 2, 0, 0), rz=-e * math.pi / 2 + math.pi):
                if (e == 1 and doors_end in (1, 2)) or (e == -1 and doors_end in (-1, 2)):
                    for s in (-1, 1):
                        box((s * W / 4, 0.02, H / 2), (W / 2 - 0.2, 0.04, H - 0.32), col, bev=0.006)
                        for k in range(4):
                            box((s * W / 4 + (k - 1.5) * 0.24, -0.0, H / 2), (0.08, 0.02, H - 0.36), col, bev=0.0)
                        for xx in (s * W * 0.08, s * W * 0.38):
                            cyl((xx, -0.06, H / 2), 0.018, H - 0.25, "steel", "metal", seg=6)
                            box((xx, -0.08, H * 0.45), (0.04, 0.06, 0.2), "steel", "metal", bev=0.0)
                else:
                    corr((-W / 2 + 0.16, 0.05, 0.16), (1, 0, 0), (0, 0, 1), W - 0.32, H - 0.32, col, pitch=corr_pitch, depth=0.035, back=col)
        # taban
        box((0, 0, 0.1), (L - 0.3, W - 0.3, 0.06), "dark", bev=0.0)


def guard_tower(p, h=4.0, col="wood", roof="roof", sand=True, plat=2.2, rz=0.0, ladder_side=1):
    """Ahşap gözetleme kulesi: 4 ayak, çaprazlar, kum torbalı platform, sac çatı, merdiven."""
    hw = plat / 2
    with at(p, rz=rz):
        for sx in (-1, 1):
            for sy in (-1, 1):
                cyl_ab((sx * (hw + 0.2), sy * (hw + 0.2), 0), (sx * (hw - 0.1), sy * (hw - 0.1), h), 0.075, col, seg=6)
                box((sx * (hw + 0.2), sy * (hw + 0.2), 0.08), (0.35, 0.35, 0.16), "concrete", bev=0.02)
        for zz in (h * 0.35, h * 0.7):
            k = (zz / h)
            o = hw + 0.2 - 0.3 * k
            for e in range(4):
                a = e * math.pi / 2
                ca, sa = math.cos(a), math.sin(a)
                with at((0, 0, 0), rz=a):
                    bar_ab((o, -o, zz), (o, o, zz), 0.06, 0.1, col)
        for e in range(4):
            with at((0, 0, 0), rz=e * math.pi / 2):
                o0 = hw + 0.18
                o1 = hw - 0.05
                bar_ab((o0, -o0, 0.15), (o1 + 0.05, o1, h * 0.68), 0.05, 0.08, col)
        # platform
        box((0, 0, h + 0.06), (plat + 0.3, plat + 0.3, 0.12), col, bev=0.01)
        for i in range(int(plat / 0.2)):
            box((-plat / 2 + 0.1 + i * 0.2, 0, h + 0.13), (0.18, plat + 0.25, 0.03), col, bev=0.004)
        if sand:
            for e in range(4):
                with at((0, 0, h + 0.15), rz=e * math.pi / 2):
                    if e == 3:
                        continue
                    for r in range(3):
                        off = 0.15 if r % 2 else 0.0
                        for i in range(int(plat / 0.5)):
                            bag((-plat / 2 + 0.3 + off + i * 0.5, -plat / 2 + 0.12, 0.07 + r * 0.13), (0.48, 0.26, 0.14), "bag", 0.0)
        # direkler ve çatı
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((sx * (hw + 0.05), sy * (hw + 0.05), h + 1.15), (0.1, 0.1, 2.0), col, bev=0.008)
        corr((-hw - 0.45, -hw - 0.4, h + 2.25), (1, 0, 0), (0, 1, 0.12), plat + 0.9, plat + 0.85, roof, pitch=0.18, depth=0.03, back="dark")
        # merdiven
        with at((0, ladder_side * (hw + 0.2), 0), rz=0):
            for s in (-1, 1):
                cyl_ab((s * 0.25, 0.9, 0), (s * 0.25, 0.02, h + 0.1), 0.035, col, seg=5)
            n = int(h / 0.3)
            for i in range(1, n):
                t = i / n
                y = 0.9 - 0.88 * t
                cyl_ab((-0.25, y, t * h), (0.25, y, t * h), 0.02, col, seg=4)


# ------------------------------------------------------------ oturum, AO pişirme, dışa aktarım, önizleme
def begin(side, seed=7):
    global B, CL, P, SIDE, RND, BODY_H
    BODY_H = 3.0
    bpy.ops.wm.read_factory_settings(use_empty=True)
    B = bmesh.new()
    CL = B.loops.layers.float_color.new("Col")
    P = PALS[side]
    SIDE = side
    RND = random.Random(seed)
    XF[:] = [Matrix.Identity(4)]


def _mat(name):
    m = bpy.data.materials.new(name)
    m.use_nodes = True
    b = m.node_tree.nodes.get("Principled BSDF")
    if b:
        b.inputs["Base Color"].default_value = (1, 1, 1, 1)
        b.inputs["Roughness"].default_value = 0.8
    return m


def _ao(me, dist=1.3, nray=20, off=0.05):
    """Köşe başına ortam kapanması (BVH ışın izleme): nokta normal boyunca kaydırılır, böylece oluklu sac
    kıvrımları ve pah kenarları kendi kendini karartmaz; zemin (z=0) analitik."""
    import numpy as np
    from mathutils.bvhtree import BVHTree
    vs = [v.co.copy() for v in me.vertices]
    tree = BVHTree.FromPolygons(vs, [tuple(p.vertices) for p in me.polygons], epsilon=0.0)
    rnd = random.Random(3)
    dirs = []
    for i in range(nray):
        # kosinüs ağırlıklı yarıküre (yerel Z)
        u1 = (i + 0.5) / nray
        u2 = (i * 0.618034) % 1.0
        r = math.sqrt(u1)
        th = math.tau * u2
        dirs.append(Vector((r * math.cos(th), r * math.sin(th), math.sqrt(max(0.0, 1 - u1)))))
    cache = {}
    out = np.ones(len(me.loops), dtype=np.float32)
    lv = [l.vertex_index for l in me.loops]
    for p in me.polygons:
        n = p.normal
        rot = n.to_track_quat('Z', 'Y')
        sm = p.use_smooth
        for li in p.loop_indices:
            vi = lv[li]
            nn = me.vertices[vi].normal if sm else n
            co = vs[vi]
            key = (round(co.x, 3), round(co.y, 3), round(co.z, 3), round(nn.x, 1), round(nn.y, 1), round(nn.z, 1))
            if key in cache:
                out[li] = cache[key]
                continue
            q = nn.to_track_quat('Z', 'Y') if sm else rot
            o = co + nn * off
            hit = 0
            for d0 in dirs:
                d = q @ d0
                if d.z < -1e-4 and o.z > -1e-3:
                    tg = -o.z / d.z
                    if tg < dist:
                        hit += 1
                        continue
                h = tree.ray_cast(o, d, dist)
                if h[0] is not None:
                    hit += 1
            v = 1.0 - hit / len(dirs)
            cache[key] = v
            out[li] = v
    return out


def finish(name, ao=True, samples=48, ao_dist=1.3):
    import numpy as np
    global B
    me = bpy.data.meshes.new(name)
    B.normal_update()
    B.to_mesh(me)
    B.free()
    B = None
    ob = bpy.data.objects.new(name, me)
    bpy.context.collection.objects.link(ob)
    for m in MATS:
        me.materials.append(_mat(m))
    nl = len(me.loops)
    col = np.empty(nl * 4, dtype=np.float32)
    me.color_attributes["Col"].data.foreach_get("color", col)
    col = col.reshape(-1, 4)
    pm = np.empty(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("material_index", pm)
    ls = np.empty(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("loop_start", ls)
    lt = np.empty(len(me.polygons), dtype=np.int32)
    me.polygons.foreach_get("loop_total", lt)
    lm = np.repeat(pm, lt)
    if ao:
        a = _ao(me, ao_dist)
        f = 0.4 + 0.6 * np.clip(a, 0, 1) ** 1.25
        lampish = np.isin(lm, [MATS.index(m) for m in ("lamp", "lamp_r", "lamp_g", "lamp_b")])
        f[lampish] = 1.0
        col[:, :3] *= f[:, None]
    me.color_attributes["Col"].data.foreach_set("color", col.ravel())
    me.attributes.active_color = me.color_attributes["Col"]
    bpy.ops.object.select_all(action='DESELECT')
    ob.select_set(True)
    bpy.context.view_layer.objects.active = ob
    path = os.path.join(OUT, name + ".glb")
    bpy.ops.export_scene.gltf(filepath=path, export_format='GLB', export_yup=True, export_apply=True, use_selection=True,
                              export_vertex_color='NAME', export_vertex_color_name='Col', export_all_vertex_colors=False, export_texcoords=False, export_normals=True, export_materials='EXPORT')
    import json
    with open(path[:-4] + ".json", "w") as fh:
        json.dump({"h": round(BODY_H, 2), "side": SIDE}, fh)
    tris = sum(len(p.vertices) - 2 for p in me.polygons)
    print("EXPORT %s tris=%d size=%.2fMB" % (name, tris, os.path.getsize(path) / 1e6))
    return ob


def preview(ob, out, scale=16.0, focus=(0, 0, 1.5)):
    """Oyun kamerasıyla aynı açı (ortografik, 40° eğim, +X/-Y yönünden) ve ters açıdan Cycles önizleme."""
    for m in ob.data.materials:
        nt = m.node_tree
        b = nt.nodes.get("Principled BSDF")
        at_ = nt.nodes.new("ShaderNodeVertexColor")
        at_.layer_name = "Col"
        nt.links.new(at_.outputs["Color"], b.inputs["Base Color"])
        if m.name.startswith("lamp"):
            nt.links.new(at_.outputs["Color"], b.inputs["Emission Color"])
            b.inputs["Emission Strength"].default_value = 2.0
        if m.name == "metal":
            b.inputs["Metallic"].default_value = 0.4
            b.inputs["Roughness"].default_value = 0.5
        if m.name == "glass":
            b.inputs["Roughness"].default_value = 0.1
    sc = bpy.context.scene
    sc.render.engine = 'CYCLES'
    sc.cycles.samples = 10
    sc.cycles.use_denoising = False
    sc.render.resolution_x = 1100
    sc.render.resolution_y = 740
    w = sc.world or bpy.data.worlds.new("w")
    sc.world = w
    w.use_nodes = True
    w.node_tree.nodes["Background"].inputs["Color"].default_value = (0.5, 0.55, 0.6, 1)
    w.node_tree.nodes["Background"].inputs["Strength"].default_value = 0.9
    gm = bpy.data.meshes.new("gp")
    gm.from_pydata([(-60, -60, -0.01), (60, -60, -0.01), (60, 60, -0.01), (-60, 60, -0.01)], [], [(0, 1, 2, 3)])
    g = bpy.data.objects.new("gp", gm)
    bpy.context.collection.objects.link(g)
    gmat = bpy.data.materials.new("g")
    gmat.use_nodes = True
    gmat.node_tree.nodes["Principled BSDF"].inputs["Base Color"].default_value = (0.23, 0.25, 0.16, 1)
    gm.materials.append(gmat)
    sd = bpy.data.lights.new("sun", 'SUN')
    sd.energy = 3.5
    so = bpy.data.objects.new("sun", sd)
    so.rotation_euler = (math.radians(42), 0, math.radians(30))
    bpy.context.collection.objects.link(so)
    p = math.radians(40)
    for tag, sx, sy in (("a", 1, -1), ("b", -1, 1)):
        off = Vector((sx * math.cos(p) / math.sqrt(2), sy * math.cos(p) / math.sqrt(2), math.sin(p))) * 60
        cd = bpy.data.cameras.new("c")
        cd.type = 'ORTHO'
        cd.ortho_scale = scale
        co = bpy.data.objects.new("c", cd)
        co.location = Vector(focus) + off
        co.rotation_euler = (-off).to_track_quat('-Z', 'Y').to_euler()
        bpy.context.collection.objects.link(co)
        sc.camera = co
        sc.render.filepath = out + "_" + tag + ".png"
        bpy.ops.render.render(write_still=True)


# ------------------------------------------------------------ ortak: zırhlı araç gövdesi (atölye içi), palet baklaları
def armored_hull(p, rz=0.0, col="paint", lifted=0.0, wheels=True):
    """4x4 zırhlı araç gövdesi (MRAP tipi): V taban, eğik camlar, kapılar, kaput ızgarası; +X ileri."""
    with at((p[0], p[1], p[2] + lifted), rz=rz):
        z0 = 0.55
        prism_x([(-0.9, z0 + 0.25), (-0.45, z0), (0.45, z0), (0.9, z0 + 0.25), (1.0, z0 + 1.2), (-1.0, z0 + 1.2)], -2.2, 1.0, col, bev=0.02)
        # kabin üstü
        prism_x([(-1.0, z0 + 1.2), (1.0, z0 + 1.2), (0.85, z0 + 2.0), (-0.85, z0 + 2.0)], -2.1, 0.4, col, bev=0.02)
        prism_x([(-1.0, z0 + 1.2), (1.0, z0 + 1.2), (0.85, z0 + 2.0), (-0.85, z0 + 2.0)], 0.4, 0.75, col, bev=0.02)
        # kaput
        prism_x([(-0.95, z0 + 0.3), (0.95, z0 + 0.3), (0.9, z0 + 1.2), (-0.9, z0 + 1.2)], 1.0, 2.2, col, bev=0.02)
        box((2.22, 0, z0 + 0.75), (0.06, 1.5, 0.75), "dark", bev=0.008)
        for i in range(7):
            box((2.26, -0.6 + i * 0.2, z0 + 0.75), (0.03, 0.06, 0.65), col, bev=0.0)
        # camlar
        with at((0.75, 0, z0 + 1.6), ry=-0.35):
            box((0.02, 0, 0), (0.04, 1.5, 0.6), "glass", "glass", bev=0.0)
        for s in (-1, 1):
            for x in (-0.6, 0.1):
                box((x, s * 0.95, z0 + 1.65), (0.55, 0.04, 0.42), "glass", "glass", r=(s * 0.18, 0, 0), bev=0.0)
                box((x - 0.05, s * 1.02, z0 + 0.95), (0.62, 0.03, 0.85), col, bev=0.006)
                box((x + 0.2, s * 1.05, z0 + 0.9), (0.12, 0.04, 0.03), "dark", "metal", bev=0.0)
            box((-2.25, s * 0.6, z0 + 1.3), (0.06, 0.25, 0.25), "dark", bev=0.0)
            box((2.1, s * 0.85, z0 + 1.0), (0.1, 0.18, 0.12), "lamp", "lamp", bev=0.0)
        box((-2.24, 0, z0 + 0.9), (0.05, 0.9, 1.3), col, bev=0.01)   # arka kapı
        for x in (-1.6, 0.0, 1.5):
            box((x, 0, z0 + 2.03), (0.5, 0.6, 0.06), "dark", bev=0.005)
        cyl((-0.9, 0, z0 + 2.15), 0.35, 0.2, col, seg=14)
        if wheels:
            for x in (-1.4, 1.4):
                for s in (-1, 1):
                    tyre((x, s * 0.95, 0.5 - lifted), 0.5, 0.36, (math.pi / 2, 0, 0), seg=18)


def track_links(p, n=6, rows=3, rz=0.0):
    """Palet bakla destesi (paletin üstünde)."""
    with at(p, rz=rz):
        pallet((0, 0, 0), 1.2, 1.0, 0.0)
        for r in range(rows):
            for i in range(n):
                y = -0.45 + i * 0.18
                z = 0.17 + r * 0.075
                box((0, y, z), (0.62, 0.15, 0.04), "dark", "metal", bev=0.006)
                box((0, y, z + 0.035), (0.08, 0.06, 0.04), "steel", "metal", bev=0.0)
                for s in (-1, 1):
                    box((s * 0.33, y, z), (0.06, 0.1, 0.05), "steel", "metal", bev=0.0)


def hoist(p, drop=2.0, load=True):
    """Köprü vinci arabası + zincir + kanca (+ asılı motor bloğu)."""
    with at(p):
        box((0, 0, 0), (0.5, 0.5, 0.35), "yellow", "metal", bev=0.02)
        box((0, 0, -0.3), (0.3, 0.3, 0.3), "dark", "metal", bev=0.015)
        for i in range(int(drop / 0.08)):
            box((0, 0, -0.5 - i * 0.08), (0.03 if i % 2 else 0.012, 0.012 if i % 2 else 0.03, 0.09), "steel", "metal", bev=0.0, dirt=False)
        cyl((0, 0, -0.55 - drop), 0.06, 0.12, "yellow", "metal", seg=8)
        if load:
            z = -0.75 - drop
            box((0, 0, z - 0.3), (1.0, 0.7, 0.6), "dark", "metal", bev=0.02)
            box((0.0, 0, z - 0.68), (0.8, 0.6, 0.2), "steel", "metal", bev=0.02)
            for k in range(4):
                box((-0.35 + k * 0.23, 0.36, z - 0.25), (0.12, 0.04, 0.3), "steel", "metal", bev=0.0)
            cyl((0.55, 0, z - 0.3), 0.18, 0.16, "steel", "metal", rot=(0, math.pi / 2, 0), seg=14)
            for s in (-1, 1):
                cyl_ab((0, 0, -0.6 - drop), (s * 0.45, 0, z), 0.01, "steel", "metal", seg=3)


def workbench(p, rz=0.0, L=2.2):
    with at(p, rz=rz):
        box((0, 0, 0.88), (L, 0.75, 0.06), "wood", bev=0.008)
        for x in (-L / 2 + 0.06, L / 2 - 0.06):
            for y in (-0.32, 0.32):
                box((x, y, 0.43), (0.06, 0.06, 0.86), "steel", "metal", bev=0.0)
        box((0, 0, 0.2), (L - 0.1, 0.7, 0.03), "steel", "metal", bev=0.0)
        box((0, 0.36, 1.45), (L, 0.04, 1.1), "steel", "metal", bev=0.006)   # alet panosu
        for i in range(10):
            box((-L / 2 + 0.2 + i * 0.2, 0.32, 1.3 + (i % 3) * 0.2), (0.04, 0.03, 0.25), "dark", "metal", bev=0.0)
        box((L * 0.3, 0, 0.95), (0.3, 0.2, 0.1), "blue", "metal", bev=0.01)        # mengene
        box((-L * 0.25, -0.05, 0.98), (0.45, 0.25, 0.15), "red", "metal", bev=0.01)


def tool_cabinet(p, rz=0.0, col="red"):
    with at(p, rz=rz):
        box((0, 0, 0.55), (0.75, 0.5, 1.0), col, "metal", bev=0.012)
        for i in range(6):
            box((0, -0.255, 0.15 + i * 0.15), (0.68, 0.01, 0.12), col, "metal", bev=0.003)
            box((0, -0.27, 0.18 + i * 0.15), (0.3, 0.02, 0.02), "steel", "metal", bev=0.0)
        for x in (-0.3, 0.3):
            for y in (-0.2, 0.2):
                cyl((x, y, 0.04), 0.04, 0.05, "black", rot=(math.pi / 2, 0, 0), seg=8)


def roof_turbine(p, col="galv"):
    with at(p):
        cyl((0, 0, 0.12), 0.16, 0.24, col, "metal", seg=12)
        lathe([(0.0, 0.62), (0.16, 0.6), (0.28, 0.5), (0.3, 0.38), (0.26, 0.26)], col, c=(0, 0, 0), seg=16, mat="metal")
        for k in range(16):
            a = k * math.tau / 16
            box((math.cos(a) * 0.28, math.sin(a) * 0.28, 0.42), (0.02, 0.07, 0.26), col, "metal", r=(0, 0, a + 0.5), bev=0.0)


def bollard(p, h=1.0):
    with at(p):
        cyl((0, 0, h / 2), 0.1, h, "yellow", "metal", seg=12, bev=0.01)
        for k in range(2):
            cyl((0, 0, h * 0.35 + k * h * 0.35), 0.102, 0.12, "black", "metal", seg=12)


def fuel_tank_h(p, L=2.4, r=0.6, rz=0.0, col="tank", bund=True):
    """Yatay yakıt tankı: bombeli kapaklar, beton kızaklar, merdiven, menhol, pompa; çevresinde taşma havuzu."""
    with at(p, rz=rz):
        z = r + 0.35
        prof = [(0.0, -L / 2 - 0.12), (r * 0.6, -L / 2 - 0.09), (r, -L / 2), (r, L / 2), (r * 0.6, L / 2 + 0.09), (0.0, L / 2 + 0.12)]
        lathe(prof, col, c=(0, 0, z), rot=(0, math.pi / 2, 0), seg=20)
        for x in (-L / 2 + 0.15, L / 2 - 0.15):
            cyl((x, 0, z), r + 0.015, 0.05, col, rot=(0, math.pi / 2, 0), seg=20)
        for x in (-L * 0.3, L * 0.3):
            prism_x([(-r * 0.8, 0), (r * 0.8, 0), (r * 0.8, z - r * 0.55), (r * 0.5, z - r * 0.82), (-r * 0.5, z - r * 0.82), (-r * 0.8, z - r * 0.55)], x - 0.12, x + 0.12, "concrete", bev=0.02)
        cyl((0, 0, z + r + 0.06), 0.22, 0.12, col, seg=12, bev=0.01)
        for k in range(8):
            a = k * math.tau / 8
            cyl((math.cos(a) * 0.19, math.sin(a) * 0.19, z + r + 0.13), 0.015, 0.02, "steel", "metal", seg=5)
        cyl((L * 0.3, 0, z + r + 0.2), 0.035, 0.4, "steel", "metal", seg=6)
        cyl((L * 0.3, 0, z + r + 0.42), 0.07, 0.06, "steel", "metal", seg=8)
        # merdiven
        for s in (-1, 1):
            cyl_ab((-L * 0.15 + s * 0.2, -r - 0.35, 0), (-L * 0.15 + s * 0.2, -r * 0.3, z + r + 0.6), 0.02, "steel", "metal", seg=5)
        for i in range(1, 7):
            t = i / 7
            cyl_ab((-L * 0.15 - 0.2, -r - 0.35 + (r * 0.75 + 0.35) * t, t * (z + r + 0.6)), (-L * 0.15 + 0.2, -r - 0.35 + (r * 0.75 + 0.35) * t, t * (z + r + 0.6)), 0.014, "steel", "metal", seg=4)
        # pompa + hortum
        box((L / 2 + 0.45, -0.2, 0.55), (0.4, 0.35, 1.1), "red" if SIDE == "usa" else "olive", "metal", bev=0.02)
        box((L / 2 + 0.45, -0.38, 0.8), (0.25, 0.01, 0.2), "glass", "glass", bev=0.0)
        cyl_ab((L / 2 + 0.05, 0, z - r * 0.5), (L / 2 + 0.45, -0.1, 0.9), 0.035, "dark", "metal", seg=6)
        lathe([(0.12, 0.0), (0.2, 0.0), (0.2, 0.06), (0.12, 0.06)], "black", c=(L / 2 + 0.67, -0.2, 0.7), rot=(0, math.pi / 2, 0), seg=12)
        if bund:
            W = 2 * r + 0.9
            Lb = L + 1.5
            for s in (-1, 1):
                box((0.3, s * W / 2, 0.2), (Lb, 0.14, 0.4), "concrete", bev=0.015)
            for s in (-1, 1):
                box((0.3 + s * Lb / 2, 0, 0.2), (0.14, W, 0.4), "concrete", bev=0.015)
            box((0.3, 0, 0.03), (Lb, W, 0.06), "concrete2", bev=0.0)


# ============================================================ ARAÇ FABRİKASI (12 x 9)
def factory():
    global BODY_H
    usa = SIDE == "usa"
    BODY_H = 6.2
    X0, X1, Y0, Y1 = -5.4, 3.6, -3.55, 3.95
    EAVE, RIDGE, XR = 4.8, 6.0, (X0 + X1) / 2
    D1, D2, DW, DH = -3.0, 1.3, 3.4, 4.0          # kapı merkezleri, genişlik, yükseklik
    frame = "olive" if usa else "steel"
    # zemin: beton döşeme + ön apron (genleşme derzleri, yağ lekeleri)
    box2((X0 - 0.2, Y0 - 0.95, 0), (X1 + 2.4, Y1 + 0.2, 0.06), "concrete", bev=0.01, dirt=False)
    for x in (X0 + 2.2, XR, X1 - 2.0, X1 + 1.2):
        box((x, (Y0 - 0.95 + Y1) / 2, 0.061), (0.02, Y1 - Y0 + 1.1, 0.004), "dark", bev=0.0, dirt=False)
    for k in range(5):
        cyl((RND.uniform(X0, X1), RND.uniform(Y0 - 0.8, Y0 - 0.2), 0.062), RND.uniform(0.15, 0.45), 0.004, "dark", seg=10, smooth=False, dirt=False)
    # ızgaralı drenaj kanalı (kapıların önünde)
    box(((X0 + X1) / 2, Y0 - 0.55, 0.062), (X1 - X0 - 0.4, 0.22, 0.01), "dark", "metal", bev=0.0, dirt=False)
    for i in range(int((X1 - X0 - 0.4) / 0.1)):
        box((X0 + 0.25 + i * 0.1, Y0 - 0.55, 0.068), (0.02, 0.22, 0.008), "steel", "metal", bev=0.0, dirt=False)
    # iç zemin + sarı bölme çizgileri
    box2((X0 + 0.1, Y0 + 0.1, 0.06), (X1 - 0.1, Y1 - 0.1, 0.07), "concrete2", bev=0.0, dirt=False)
    for x in (D1 - DW / 2 + 0.1, D1 + DW / 2 - 0.1, D2 - DW / 2 + 0.1):
        box((x, (Y0 + Y1) / 2, 0.072), (0.08, Y1 - Y0 - 0.4, 0.004), "yellow", bev=0.0, dirt=False)
    # --- iç astar (açık kapıdan görünen): duvar iç yüzleri ve çatı altı
    inner = "wall2"
    box2((X0 + 0.05, Y1 - 0.12, 0.07), (X1 - 0.05, Y1 - 0.05, EAVE), inner, bev=0.0)
    box2((X0 + 0.05, Y0 + 0.05, 0.07), (X0 + 0.12, Y1 - 0.05, EAVE), inner, bev=0.0)
    box2((X0 + 0.05, Y0 + 0.05, DH), (X1 - 0.05, Y0 + 0.12, EAVE), inner, bev=0.0)
    rc = "steel" if usa else "asb"
    poly([(X0, Y0 + 0.06, EAVE), (XR, Y0 + 0.06, RIDGE - 0.02), (XR, Y1 - 0.06, RIDGE - 0.02), (X0, Y1 - 0.06, EAVE)], rc, dirt=False)
    poly([(XR, Y0 + 0.06, RIDGE - 0.02), (X1, Y0 + 0.06, EAVE), (X1, Y1 - 0.06, EAVE), (XR, Y1 - 0.06, RIDGE - 0.02)], rc, dirt=False)
    poly([(X0, Y1 - 0.13, EAVE), (XR, Y1 - 0.13, RIDGE), (X1, Y1 - 0.13, EAVE)], inner, dirt=False)
    # --- iç çerçeve: portal kolonlar + mertekler (I profil), vinç yolu
    fc = "olive" if usa else "steel"
    for y in (Y0 + 0.3, Y0 + 2.75, Y0 + 5.2, Y1 - 0.3):
        for x in (X0 + 0.25, X1 - 0.25):
            ibeam_ab((x, y, 0.07), (x, y, EAVE - 0.05), 0.3, 0.18, fc, up=(0, 1, 0))
        ibeam_ab((X0 + 0.25, y, EAVE - 0.1), (XR, y, RIDGE - 0.2), 0.32, 0.16, fc, up=(0, 1, 0))
        ibeam_ab((X1 - 0.25, y, EAVE - 0.1), (XR, y, RIDGE - 0.2), 0.32, 0.16, fc, up=(0, 1, 0))
        for x in (X0 + 0.45, X1 - 0.45):
            box((x, y, 3.9), (0.3, 0.3, 0.12), "steel", "metal", bev=0.0)   # vinç konsolu
    for x in (X0 + 0.5, X1 - 0.5):
        ibeam_ab((x, Y0 + 0.2, 4.05), (x, Y1 - 0.2, 4.05), 0.3, 0.16, "yellow", up=(0, 0, 1))
    # köprü kiriş, araba + asılı motor (güç paketi)
    yb = -0.6
    box((XR, yb, 4.4), (X1 - X0 - 0.8, 0.5, 0.45), "yellow", "metal", bev=0.02)
    for s in (-1, 1):
        box((XR + s * (X1 - X0 - 0.9) / 2, yb, 4.25), (0.45, 0.9, 0.3), "yellow", "metal", bev=0.015)
    box((XR, yb - 0.26, 4.4), (X1 - X0 - 1.2, 0.02, 0.2), "black", bev=0.0, dirt=False)
    hoist((D1 + 0.4, yb, 4.05), drop=1.0, load=True)
    # araç kaldırma lifti + zırhlı araç gövdesi (bölme 1)
    lc = "red" if usa else "olive"
    for y in (-1.4, 1.6):
        for s in (-1, 1):
            box((D1 + s * 1.55, y, 1.35), (0.28, 0.28, 2.6), lc, "metal", bev=0.015)
            box((D1 + s * 1.55, y, 0.08), (0.5, 0.5, 0.04), "dark", "metal", bev=0.0)
            bar_ab((D1 + s * 1.5, y, 1.0), (D1 + s * 0.7, y + 0.4, 1.0), 0.12, 0.08, "dark", "metal")
    armored_hull((D1, 0.0, 0.07), rz=-math.pi / 2, col="paint", lifted=0.55, wheels=False)
    for (x, y) in ((X0 + 0.55, 1.2), (X0 + 0.55, 2.2)):
        tyre((x, y, 0.55), 0.5, 0.36, (0.1, math.pi / 2 - 0.12, 0), seg=16)
    workbench((XR + 0.4, Y1 - 0.6, 0.07), rz=0.0, L=2.4)
    tool_cabinet((X0 + 1.2, Y1 - 0.5, 0.07))
    tool_cabinet((XR - 1.4, Y1 - 0.45, 0.07), col="red" if usa else "blue")
    for i in range(2):
        gas_bottle((XR - 0.6 + i * 0.25, Y1 - 0.35, 0.07), col="olive" if i else "red", h=1.3, r=0.1)
    # tavan lambaları
    for x in (D1, D2):
        for y in (-1.6, 1.5):
            cyl_ab((x, y, RIDGE - 0.3 - abs(x - XR) * 0.27), (x, y, 4.5), 0.01, "dark", "metal", seg=3)
            lathe([(0.04, 0.2), (0.3, 0.0), (0.32, -0.02)], "steel", c=(x, y, 4.3), seg=14, mat="metal")
            cyl((x, y, 4.29), 0.26, 0.02, "lamp", "lamp", seg=14, smooth=False)

    # --- dış duvarlar
    def clad(o, u, L, H, z0=0.0, holes=()):
        uu = Vector(u)
        for xa, xb, za, zb in wall_cells(L, z0, z0 + H, holes):
            if usa:
                corr(Vector(o) + uu * xa + Vector((0, 0, za)), u, (0, 0, 1), xb - xa, zb - za, "wall", pitch=0.2, depth=0.035)
                continue
            # Doğu: tuğla kaide + sıvalı duvar
            c = Vector(o) + uu * ((xa + xb) / 2)
            yaw = math.atan2(uu.y, uu.x)
            Lc = xb - xa
            with at((c.x, c.y, 0), rz=yaw):
                h0 = min(zb, 1.1)
                if za < h0:
                    box((0, -0.06, (za + h0) / 2), (Lc, 0.12, h0 - za), "brick", bev=0.01)
                    for k in range(int((h0 - za) / 0.077)):
                        box((0, -0.123, za + 0.04 + k * 0.077), (Lc, 0.006, 0.012), "brick2", bev=0.0, dirt=False)
                if zb > 1.1:
                    zz = max(za, 1.1)
                    box((0, -0.04, (zz + zb) / 2), (Lc, 0.08, zb - zz), "wall", bev=0.01)
                    if zz == 1.1:
                        box((0, -0.1, 1.12), (Lc + 0.02, 0.06, 0.06), "plinth", bev=0.008)

    plinth = "concrete" if usa else "plinth"
    wy = (-1.65, 0.2, 2.7)
    if usa:
        hx = [(y - Y0, 3.15, w, 0.7) for y, w in zip(wy, (0.8, 1.6, 1.6))] + [(-2.65 - Y0, 1.05, 0.95, 2.1)]
    else:
        hx = [(y - Y0, 2.6, w, 1.4) for y, w in zip(wy, (0.8, 1.5, 1.5))] + [(-2.65 - Y0, 1.05, 0.95, 2.1)]
    for xs, uy in ((X1, (0, 1, 0)), (X0, (0, -1, 0))):
        o = (xs, Y0, 0) if uy[1] > 0 else (xs, Y1, 0)
        hl = hx if xs > 0 else ()
        if usa:
            for xa, xb, za, zb in wall_cells(Y1 - Y0, 0, 0.45, hl):
                box2((xs - 0.04, Y0 + xa, 0.0), (xs + 0.04, Y0 + xb, 0.45), plinth, bev=0.01)
            clad(o, uy, Y1 - Y0, EAVE - 0.45, 0.45, hl)
        else:
            clad(o, uy, Y1 - Y0, EAVE, 0.0, hl)
    # arka duvar: yaya kapısı + iki pencere
    bwx = (0.8, -1.2)
    bdx = -3.4
    zw, hw_ = (3.15, 0.7) if usa else (2.6, 1.4)
    hb = [(X1 - x, zw, 1.4, hw_) for x in bwx] + [(X1 - bdx, 1.05, 0.95, 2.1)]
    if usa:
        for xa, xb, za, zb in wall_cells(X1 - X0, 0, 0.45, hb):
            box2((X1 - xb, Y1 - 0.04, 0), (X1 - xa, Y1 + 0.04, 0.45), plinth, bev=0.01)
        clad((X1, Y1, 0), (-1, 0, 0), X1 - X0, EAVE - 0.45, 0.45, hb)
    else:
        clad((X1, Y1, 0), (-1, 0, 0), X1 - X0, EAVE, 0.0, hb)
    with at((0, Y1, 0), rz=math.pi):
        for x in bwx:
            window(-x, zw, 1.4 if usa else 1.3, hw_, frame="olive" if usa else "white", mull=1, tr=0 if usa else 0.45, depth=0.2)
        door(-bdx, 0.95, 2.1, col="olive" if usa else "door", frame="olive" if usa else "trim", panels=not usa)
        lamp_wall(-bdx, 2.3)
        box((-bdx, -0.4, 0.08), (1.3, 0.8, 0.16), "concrete", bev=0.02)
    segs = [(X0, D1 - DW / 2), (D1 + DW / 2, D2 - DW / 2), (D2 + DW / 2, X1)]
    for a, b in segs:
        if usa:
            box2((a, Y0 - 0.04, 0), (b, Y0 + 0.04, 0.45), plinth, bev=0.01)
            clad((a, Y0, 0), (1, 0, 0), b - a, EAVE - 0.45, 0.45)
        else:
            clad((a, Y0, 0), (1, 0, 0), b - a, EAVE, 0.0)
    for c in (D1, D2):
        if usa:
            corr((c - DW / 2, Y0, DH + 0.35), (1, 0, 0), (0, 0, 1), DW, EAVE - DH - 0.35, "wall", pitch=0.2, depth=0.035)
        else:
            box((c, Y0 - 0.04, (DH + EAVE) / 2 + 0.1), (DW, 0.08, EAVE - DH - 0.2), "wall", bev=0.008)
            box((c, Y0 - 0.1, DH + 0.15), (DW + 0.5, 0.2, 0.3), "concrete", bev=0.015)   # beton lento
    # ön ve arka üçgen alınlık
    for yy, fl in ((Y0, -1), (Y1, 1)):
        prism([(X0, EAVE), (X1, EAVE), (XR, RIDGE)], 0.08, "wall2" if usa else "wall", c=(0, yy + 0.04 * fl + 0.04, 0), rot=(math.pi / 2, 0, 0))
        if usa:
            for k in range(int((X1 - X0) / 0.4)):
                x = X0 + 0.2 + k * 0.4
                hz = EAVE + (RIDGE - EAVE) * (1 - abs(x - XR) / ((X1 - X0) / 2))
                if hz - EAVE > 0.1:
                    box((x, yy + fl * 0.1, (EAVE + hz) / 2), (0.05, 0.04, hz - EAVE - 0.05), "wall", bev=0.0)
        with at((XR, yy + fl * 0.09, 0), rz=0 if fl < 0 else math.pi):
            if usa:
                louver(0, EAVE + 0.55, 1.2, 0.6, "olive", mat="vc")
            else:
                cyl((0, 0.0, EAVE + 0.55), 0.35, 0.08, "trim", rot=(math.pi / 2, 0, 0), seg=16)
                cyl((0, -0.03, EAVE + 0.55), 0.28, 0.06, "dark", rot=(math.pi / 2, 0, 0), seg=16)
                for k in range(4):
                    box((0, -0.06, EAVE + 0.55), (0.56, 0.03, 0.03), "trim", r=(0, k * math.pi / 4, 0), bev=0.0)
    # dış kolonlar (ABD: görünür çelik çerçeve; Doğu: tuğla payandalar)
    if usa:
        for y in (Y0 + 0.02, Y0 + 2.5, Y0 + 5.0, Y1 - 0.02):
            ibeam_ab((X1 + 0.12, y, 0.0), (X1 + 0.12, y, EAVE + 0.05), 0.24, 0.2, "olive", up=(1, 0, 0))
            box((X1 + 0.14, y, 0.03), (0.4, 0.4, 0.06), "steel", "metal", bev=0.0)
        for x in (X0 + 0.02, D1 + DW / 2 + 0.1, D2 - DW / 2 - 0.1, X1 - 0.02, D1 - DW / 2 - 0.1, D2 + DW / 2 + 0.1):
            ibeam_ab((x, Y0 - 0.12, 0.0), (x, Y0 - 0.12, EAVE + 0.05), 0.24, 0.2, "olive", up=(0, 1, 0))
        box((X1 + 0.05, (Y0 + Y1) / 2, 2.4), (0.06, Y1 - Y0, 0.1), "olive", "metal", bev=0.0)
        for a, b in segs:
            box(((a + b) / 2, Y0 - 0.05, 2.4), (b - a, 0.06, 0.1), "olive", "metal", bev=0.0)
    else:
        for y in (Y0 + 0.15, Y0 + 2.5, Y0 + 5.0, Y1 - 0.15):
            box((X1 + 0.12, y, EAVE / 2), (0.3, 0.5, EAVE), "brick", bev=0.012)
            box((X1 + 0.14, y, 1.1), (0.36, 0.56, 0.08), "plinth", bev=0.01)
            for k in range(int(EAVE / 0.077)):
                box((X1 + 0.272, y, 0.04 + k * 0.077), (0.006, 0.5, 0.012), "brick2", bev=0.0, dirt=False)
        for x in (X0 + 0.15, D1 + DW / 2 + 0.25, D2 - DW / 2 - 0.25, X1 - 0.15, D1 - DW / 2 - 0.25, D2 + DW / 2 + 0.25):
            box((x, Y0 - 0.15, EAVE / 2), (0.5, 0.3, EAVE), "brick", bev=0.012)
            box((x, Y0 - 0.17, 1.1), (0.56, 0.36, 0.08), "plinth", bev=0.01)
            for k in range(int(EAVE / 0.077)):
                box((x, Y0 - 0.302, 0.04 + k * 0.077), (0.5, 0.006, 0.012), "brick2", bev=0.0, dirt=False)
        box(((X0 + X1) / 2, Y0 - 0.1, EAVE - 0.1), (X1 - X0 + 0.2, 0.2, 0.2), "wall2", bev=0.01)   # korniş
        box((X1 + 0.1, (Y0 + Y1) / 2, EAVE - 0.1), (0.2, Y1 - Y0 + 0.2, 0.2), "wall2", bev=0.01)
    # --- yan duvar (+X): pencereler, personel kapısı, fanlar, klima
    with at((X1 + (0.0 if usa else -0.0), 0, 0), rz=math.pi / 2):
        for y, w in zip(wy, (0.8, 1.6, 1.6)):
            if usa:
                window(y, 3.15, w, 0.7, frame="olive", mull=2 if w > 1 else 1, sill=True)
            else:
                window(y, 2.6, w - 0.1, 1.4, frame="white", mull=2 if w > 1 else 1, tr=0.45, sill=True, depth=0.2)
        door(-2.65, 0.95, 2.1, col="olive" if usa else "door", frame="olive" if usa else "trim", panels=not usa, glass=usa)
        box((-2.65, -0.45, 2.45), (1.5, 0.9, 0.06), "olive" if usa else "rust", "metal", r=(0.12, 0, 0), bev=0.006)
        for s in (-1, 1):
            bar_ab((-2.65 + s * 0.65, -0.05, 2.0), (-2.65 + s * 0.65, -0.85, 2.38), 0.04, 0.04, "dark", "metal")
        lamp_wall(-2.65, 2.25)
        box((-2.65, -0.45, 0.08), (1.4, 0.9, 0.16), "concrete", bev=0.02)
        for y in (0.2, 2.7):
            cyl((y, -0.15, 3.9), 0.36, 0.3, "galv", "metal", rot=(math.pi / 2, 0, 0), seg=16, bev=0.02)
            cyl((y, -0.32, 3.9), 0.3, 0.04, "dark", "metal", rot=(math.pi / 2, 0, 0), seg=16)
            for k in range(5):
                box((y, -0.35, 3.9 - 0.24 + k * 0.12), (0.62, 0.03, 0.02), "galv", "metal", bev=0.0)
    # --- kapılar
    def rollup(c, open_):
        with at((c, Y0, 0)):
            for s in (-1, 1):
                box((s * (DW / 2 + 0.06), -0.1, DH / 2), (0.14, 0.14, DH), "steel", "metal", bev=0.008)    # kılavuz ray
                box((s * (DW / 2 + 0.06), -0.18, DH / 2), (0.05, 0.03, DH - 0.1), "dark", "metal", bev=0.0)
            box((0, -0.32, DH + 0.3), (DW + 0.4, 0.6, 0.62), "olive", "metal", bev=0.02)          # sarma kutusu
            box((0, -0.62, DH + 0.3), (DW + 0.3, 0.02, 0.5), "olive", "metal", bev=0.0)
            if open_:
                box((0, -0.1, DH - 0.06), (DW, 0.08, 0.12), "wall2", "metal", bev=0.01)
                return
            corr((DW / 2, -0.05, 0.0), (0, 0, 1), (-1, 0, 0), DH, DW, "wall2", pitch=0.11, depth=0.025, back="steel")
            box((0, -0.1, 0.06), (DW, 0.06, 0.12), "dark", "metal", bev=0.008)
            for s in (-0.6, 0.6):
                box((s, -0.15, 0.55), (0.25, 0.04, 0.05), "steel", "metal", bev=0.0)
            box((DW / 2 - 0.3, -0.13, 1.0), (0.12, 0.06, 0.25), "steel", "metal", bev=0.0)
            box((0, -0.11, 2.2), (0.9, 0.02, 0.35), "glass", "glass", bev=0.0)
            box((0, -0.105, 2.2), (0.98, 0.015, 0.43), "dark", "metal", bev=0.0)

    def swing(c, open_):
        """Doğu tipi iki kanatlı çelik kapı (yaya kapılı, diyagonal takviyeli)."""
        hw = DW / 2
        with at((c, Y0, 0)):
            for s in (-1, 1):
                ang = (s * 1.75) if open_ else 0.0
                with at((s * hw, -0.12, 0.05), rz=ang):
                    lx = -s * hw / 2
                    box((lx, -0.03, DH / 2 - 0.05), (hw - 0.04, 0.06, DH - 0.1), "door", "metal", bev=0.01)
                    for zz in (0.1, DH / 2 - 0.05, DH - 0.2):
                        box((lx, -0.07, zz), (hw - 0.08, 0.04, 0.1), "door", "metal", bev=0.004)
                    for xx in (-s * 0.06, -s * (hw - 0.06)):
                        box((xx, -0.07, DH / 2 - 0.05), (0.08, 0.04, DH - 0.2), "door", "metal", bev=0.004)
                    bar_ab((-s * 0.1, -0.07, 0.15), (-s * (hw - 0.1), -0.07, DH / 2 - 0.1), 0.06, 0.03, "door", "metal", up=(0, 1, 0))
                    bar_ab((-s * 0.1, -0.07, DH / 2), (-s * (hw - 0.1), -0.07, DH - 0.25), 0.06, 0.03, "door", "metal", up=(0, 1, 0))
                    for zz in (0.6, DH - 0.6):
                        cyl((0, -0.03, zz), 0.04, 0.25, "dark", "metal", seg=8)       # menteşe
                    if s > 0:
                        box((lx, -0.1, 1.05), (0.85, 0.02, 1.9), "door", "metal", bev=0.004)   # yaya kapısı
                        box((lx - 0.3, -0.12, 1.0), (0.04, 0.04, 0.12), "steel", "metal", bev=0.0)
                    sp = []
                    for k in range(10):
                        a = math.pi / 2 + k * math.pi / 5
                        rr = 0.32 if k % 2 == 0 else 0.13
                        sp.append((lx + math.cos(a) * rr, DH * 0.72 + math.sin(a) * rr))
                    prism(sp, 0.012, "red", c=(0, -0.09, 0), rot=(math.pi / 2, 0, 0))
            if not open_:
                box((0, -0.2, DH * 0.45), (0.1, 0.06, 0.3), "steel", "metal", bev=0.0)
            # kapı üstü konik emaye abajurlu lamba
            box((0, -0.25, DH + 0.5), (0.3, 0.12, 0.08), "dark", "metal", bev=0.0)
            cyl_ab((0, -0.2, DH + 0.55), (0, -0.6, DH + 0.7), 0.02, "dark", "metal", seg=5)
            lathe([(0.03, 0.12), (0.22, -0.05), (0.24, -0.07)], "olive", c=(0, -0.6, DH + 0.62), seg=14)
            cyl((0, -0.6, DH + 0.555), 0.2, 0.02, "lamp", "lamp", seg=14, smooth=False)

    if usa:
        rollup(D1, True)
        rollup(D2, False)
        for c in (D1, D2):
            for s in (-1, 1):
                bollard((c + s * (DW / 2 + 0.35), Y0 - 0.45, 0.06), 1.1)
            with at((0, Y0 - 0.62, 0)):
                lamp_wall(c, DH + 0.85)
            for k in range(int(DW / 0.3)):
                box((c - DW / 2 + 0.15 + k * 0.3, Y0 - 0.1, 0.07), (0.15, 0.25, 0.01), "yellow" if k % 2 else "black", bev=0.0, dirt=False)
        box((D2 + DW / 2 + 0.55, Y0 - 0.17, 3.0), (0.62, 0.04, 0.9), "olive", bev=0.006)       # birlik tabelası
        box((D2 + DW / 2 + 0.55, Y0 - 0.2, 3.15), (0.4, 0.01, 0.3), "yellow", bev=0.0, dirt=False)
        box((D2 + DW / 2 + 0.55, Y0 - 0.2, 2.75), (0.5, 0.01, 0.06), "white", bev=0.0, dirt=False)
    else:
        swing(D1, True)
        swing(D2, False)
        for c in (D1, D2):
            for s in (-1, 1):
                cyl((c + s * (DW / 2 + 0.55), Y0 - 0.4, 0.3), 0.12, 0.6, "white", seg=10, bev=0.01)   # çarpma babası
                cyl((c + s * (DW / 2 + 0.55), Y0 - 0.4, 0.42), 0.122, 0.1, "black", seg=10)
    # --- çatı
    over = 0.35
    run = XR - X0
    slope = (RIDGE - EAVE) / run
    sl = math.hypot(run + over, (run + over) * slope)
    ze = RIDGE - (run + over) * slope
    for s in (-1, 1):
        xe = XR + s * (run + over)
        vdir = Vector((xe - XR, 0, ze - RIDGE)).normalized()
        u = (0, 1, 0) if s < 0 else (0, -1, 0)
        ys = (Y0 - over, Y1 + over)
        L = ys[1] - ys[0]
        if usa:
            nsh = int(L / 1.0)
            for i in range(nsh):
                y0 = ys[0] + i * L / nsh if s < 0 else ys[1] - i * L / nsh
                sky = i in (2, 5)
                colr = (0.66, 0.84, 0.86) if sky else "roof"
                corr((XR, y0, RIDGE + (0.07 if sky else 0.05)), u, vdir, L / nsh, sl * (0.75 if sky else 1.0), colr, pitch=0.25, depth=0.04, back="steel")
                if sky:
                    corr(Vector((XR, y0, RIDGE + 0.05)) + vdir * (sl * 0.75), u, vdir, L / nsh, sl * 0.25, "roof", pitch=0.25, depth=0.04, back="steel")
        else:
            corr((XR, ys[0] if s < 0 else ys[1], RIDGE + 0.05), u, vdir, L, sl, "asb", pitch=0.17, depth=0.05, sine=True, back="asb")
            for k in range(3):
                t = RND.uniform(0.25, 0.75)
                yy = RND.uniform(ys[0] + 1, ys[1] - 1)
                p = Vector((XR, yy, RIDGE + 0.11)) + vdir * (t * sl)
                with at(p, ry=s * math.atan(slope)):
                    box((0, 0, 0), (1.0, 1.1, 0.012), "rust" if k == 0 else "roof", bev=0.0)
        box((xe + s * 0.06, (Y0 + Y1) / 2, ze - 0.08), (0.14, L, 0.12), "galv", "metal", bev=0.01)    # oluk
        box((xe + s * 0.06, (Y0 + Y1) / 2, ze - 0.04), (0.1, L - 0.04, 0.06), "dark", "metal", bev=0.0)
        with at((XR, (Y0 + Y1) / 2, RIDGE + 0.1), ry=s * math.atan(slope)):
            box((s * 0.17, 0, 0), (0.36, L + 0.02, 0.025), "steel" if usa else "asb", "metal" if usa else "vc", bev=0.0)
            box((s * 0.34, 0, -0.03), (0.025, L + 0.02, 0.07), "steel" if usa else "asb", "metal" if usa else "vc", bev=0.0)
        for yy in ys:
            bar_ab((XR, yy, RIDGE + 0.06), (xe, yy, ze), 0.06, 0.22, "olive" if usa else "wall2", up=(0, 0, 1))
    for y in (-2.0, 0.2, 2.4):
        roof_turbine((XR, y, RIDGE + 0.12))
    if usa:
        ex = (XR + 2.4, 2.4)
        zc = RIDGE - 2.4 * slope
        cyl((ex[0], ex[1], zc + 1.4), 0.2, 2.9, "galv", "metal", seg=14)
        cyl((ex[0], ex[1], zc + 0.1), 0.3, 0.2, "dark", "metal", seg=14)
        lathe([(0.0, 0.32), (0.42, 0.06), (0.44, 0.03), (0.0, 0.18)], "galv", c=(ex[0], ex[1], zc + 3.0), seg=16, mat="metal", smooth=False)
        for k in range(3):
            a = k * math.tau / 3
            bar_ab((ex[0] + math.cos(a) * 0.19, ex[1] + math.sin(a) * 0.19, zc + 2.8), (ex[0] + math.cos(a) * 0.3, ex[1] + math.sin(a) * 0.3, zc + 3.1), 0.02, 0.02, "galv", "metal")
        for k in range(3):
            a = k * math.tau / 3 + 0.3
            gx = ex[0] + math.cos(a) * 1.4
            cyl_ab((ex[0], ex[1], zc + 2.4), (gx, ex[1] + math.sin(a) * 1.4, RIDGE - abs(gx - XR) * slope + 0.05), 0.006, "dark", "metal", seg=3)
        with at((XR - 2.3, -1.0, RIDGE - 2.3 * slope), ry=-math.atan(slope)):
            box((0, 0, 0.3), (1.1, 1.4, 0.6), "roof", "metal", bev=0.02)
            for k in range(6):
                box((0.0, -0.71, 0.1 + k * 0.08), (0.9, 0.02, 0.03), "dark", "metal", bev=0.0)
    else:
        bx, by = X1 - 1.0, Y1 + 0.55
        box((bx, by, 4.0), (0.7, 0.7, 8.0), "brick", bev=0.015)
        for k in range(int(8.0 / 0.077)):
            if k % 3 == 0:
                box((bx, by, 0.04 + k * 0.077), (0.712, 0.712, 0.012), "brick2", bev=0.0, dirt=False)
        box((bx, by, 8.05), (0.85, 0.85, 0.14), "brick2", bev=0.01)
        box((bx, by, 8.1), (0.45, 0.45, 0.12), "black", bev=0.0, dirt=False)
        for z in (2.5, 5.0, 7.5):
            box((bx, by, z), (0.74, 0.74, 0.06), "dark", "metal", bev=0.0)
    for (x, y, rz) in ((X1 + 0.3, Y0 + 0.15, math.pi / 2), (X1 + 0.3, Y1 - 0.15, math.pi / 2), (X0 - 0.3, Y0 + 0.15, -math.pi / 2)):
        with at((x, y, 0), rz=rz):
            downpipe(0, 0.0, ze - 0.1, "galv", y=0.0)
    # --- dış ekipman (+X şeridi): yakıt tankı, jeneratör, varil, lastik, palet bakla
    fuel_tank_h((X1 + 1.45, 2.2, 0.06), L=2.2, r=0.55, rz=math.pi / 2, col="tank", bund=True)
    generator((X1 + 1.35, -1.0, 0.06), rz=math.pi / 2, col="olive", trailer=False, big=0.85)
    cyl_ab((X1 + 1.35, 0.0, 0.3), (X1 + 0.15, 0.6, 0.3), 0.03, "black", seg=6)
    for i, (dx, dy) in enumerate(((0.0, 0.0), (0.62, 0.05), (0.3, 0.55))):
        drum((X1 + 1.0 + dx, Y0 - 0.45 + dy, 0.06), col=("olive" if i % 2 else "blue") if usa else ("rust" if i == 2 else "olive"))
    drum((X1 + 2.05, Y0 + 0.3, 0.06), col="red" if usa else "rust", lying=True, rz=0.4)
    tyre_stack((X0 - 0.35, -2.4, 0.06), n=4, r=0.5, w=0.3)
    track_links((X0 - 0.3, 0.6, 0.06), rz=math.pi / 2)
    if usa:
        jerrycan((X1 + 2.0, -2.6, 0.06), "olive", 0.2)
        jerrycan((X1 + 2.25, -2.55, 0.06), "olive", 0.1)
        fire_ext((X1 + 0.35, -1.95, 0.06))
        ac_unit((X1 + 0.45, 3.0, 0.06), rz=math.pi / 2, col="paint")
    else:
        # yangın panosu: konik kovalar, balta, kürek, kum sandığı
        with at((X1 + 0.32, 0.35, 0.06), rz=math.pi / 2):
            box((0, -0.04, 1.1), (1.3, 0.06, 1.5), "red", bev=0.01)
            box((0, -0.075, 1.1), (1.2, 0.01, 1.4), "white", bev=0.0, dirt=False)
            for x in (-0.35, 0.05):
                lathe([(0.0, 0.0), (0.13, 0.3)], "red", c=(x, -0.2, 1.35), seg=12, cap1=True)
            box((0.4, -0.12, 1.15), (0.05, 0.03, 0.9), "wood", bev=0.0)
            box((0.4, -0.13, 1.55), (0.2, 0.03, 0.12), "dark", "metal", bev=0.0)
            box((-0.15, -0.12, 0.75), (0.9, 0.03, 0.05), "wood", bev=0.0)
            box((0.32, -0.12, 0.75), (0.2, 0.03, 0.22), "dark", "metal", bev=0.0)
        box((X1 + 0.75, -0.6, 0.4), (0.7, 0.9, 0.7), "red", bev=0.02)
        box((X1 + 0.75, -0.6, 0.77), (0.74, 0.94, 0.04), "red", bev=0.008)


# ------------------------------------------------------------ beton elemanlar, karargâh ekipmanı
def t_wall(p, rz=0.0, h=3.6, w=1.5, col="concrete", num=None):
    """T-duvar (Texas barrier): geniş taban, inceltilmiş gövde, pahlı tepe, kaldırma halkaları."""
    with at(p, rz=rz):
        box((0, 0, 0.2), (w, 1.6, 0.4), col, bev=0.03)
        prism_x([(-0.25, 0.4), (0.25, 0.4), (0.15, h - 0.08), (0.08, h), (-0.08, h), (-0.15, h - 0.08)], -w / 2 + 0.01, w / 2 - 0.01, col, bev=0.015)
        for x in (-w * 0.3, w * 0.3):
            lathe([(0.05, 0.0), (0.07, 0.0), (0.07, 0.02), (0.05, 0.02)], "rust", c=(x, 0, h + 0.03), rot=(math.pi / 2, 0, 0), seg=8)
        if num:
            box((0, -0.235, h * 0.62), (w * 0.5, 0.01, 0.35), num, bev=0.0, dirt=False)
        # akıntı lekeleri
        for k in range(2):
            x = RND.uniform(-w * 0.35, w * 0.35)
            box((x, -0.23, h * 0.6), (0.06, 0.008, h * 0.5), "concrete2", bev=0.0, dirt=False)


def jersey(p, rz=0.0, L=2.0, col="concrete"):
    with at(p, rz=rz):
        prism_x([(-0.3, 0), (0.3, 0), (0.3, 0.08), (0.12, 0.3), (0.08, 0.81), (-0.08, 0.81), (-0.12, 0.3), (-0.3, 0.08)], -L / 2, L / 2, col, bev=0.012)
        box((L / 2 - 0.15, 0, 0.84), (0.06, 0.04, 0.06), "rust", bev=0.0)


def concrete_fence(p, rz=0.0, L=4.0, H=2.2, col="concrete"):
    """Doğu tipi beton çit panosu: elmas (eşkenar dörtgen) kabartma deseni, sütunlar."""
    with at(p, rz=rz):
        box((0, 0, H / 2 + 0.05), (L, 0.12, H), col, bev=0.012)
        nx, nz = 8, 4
        for i in range(nx):
            for k in range(nz):
                x = -L / 2 + (i + 0.5) * L / nx
                z = 0.05 + (k + 0.5) * H / nz
                dx_, dz_ = L / nx * 0.42, H / nz * 0.42
                poly([(x, -0.068, z - dz_), (x + dx_, -0.068, z), (x, -0.068, z + dz_), (x - dx_, -0.068, z)], "concrete2")
                poly([(x, 0.068, z - dz_), (x - dx_, 0.068, z), (x, 0.068, z + dz_), (x + dx_, 0.068, z)], "concrete2")
        for x in (-L / 2, L / 2):
            box((x, 0, H / 2 + 0.15), (0.2, 0.25, H + 0.3), "concrete2", bev=0.015)


def chu_box(p, rz=0.0, L=5.6, W=2.44, H=2.55, col="wall", door_end=True, steps=True):
    """Konteyner yaşam birimi (CHU): sandviç panel duvarlar (dikey derzler), kapı, pencere (zırh kepenkli), split klima."""
    with at(p, rz=rz):
        # kızak/takoz
        for y in (-L / 2 + 0.4, 0, L / 2 - 0.4):
            for x in (-W / 2 + 0.3, W / 2 - 0.3):
                box((x, y, 0.1), (0.3, 0.3, 0.2), "wood", bev=0.01)
                box((x, y, 0.22), (0.25, 0.25, 0.04), "wood", r=(0, 0, 0.3), bev=0.005)
        z0 = 0.24
        box((0, 0, z0 + 0.1), (W, L, 0.2), "dark", "metal", bev=0.01)
        box((0, 0, z0 + H / 2), (W - 0.04, L - 0.04, H - 0.06), col, bev=0.02)
        # köşe dikmeleri, üst/alt kirişler
        for sx in (-1, 1):
            for sy in (-1, 1):
                box((sx * (W / 2 - 0.05), sy * (L / 2 - 0.05), z0 + H / 2), (0.1, 0.1, H), "trim", bev=0.008)
        for sy in (-1, 1):
            box((0, sy * (L / 2 - 0.04), z0 + H - 0.05), (W, 0.1, 0.1), "trim", bev=0.006)
        for sx in (-1, 1):
            box((sx * (W / 2 - 0.04), 0, z0 + H - 0.05), (0.1, L, 0.1), "trim", bev=0.006)
            box((sx * (W / 2 - 0.04), 0, z0 + 0.06), (0.1, L, 0.12), "trim", bev=0.006)
            # panel derzleri
            for k in range(1, int(L / 1.1)):
                box((sx * (W / 2 - 0.015), -L / 2 + k * L / int(L / 1.1), z0 + H / 2), (0.012, 0.025, H - 0.2), "trim", bev=0.0)
        # çatı: hafif eğimli kapak, kenar profili
        box((0, 0, z0 + H + 0.03), (W + 0.04, L + 0.04, 0.06), "roof", "metal", bev=0.01)
        # ön uç (-Y): kapı + pencere + klima
        with at((0, -L / 2 + 0.02, z0)):
            door(-W * 0.22, 0.85, 2.0, col="trim", frame="trim", panels=False, glass=False)
            window(W * 0.26, 1.45, 0.65, 0.75, frame="trim", mull=0, sill=False, flush=True)
            box((W * 0.26, -0.06, 1.85), (0.8, 0.12, 0.1), "trim", bev=0.006)     # kepenk kutusu
            box((W * 0.26, -0.05, 1.08), (0.7, 0.06, 0.04), "trim", bev=0.0)
            ac_unit((W * 0.26, -0.35, 1.95), col="white", w=0.7, d=0.25, h=0.45)
            lamp_wall(-W * 0.22, 2.2)
        # basamak
        if steps:
            with at((-W * 0.22, -L / 2 - 0.45, 0)):
                box((0, 0.12, 0.12), (0.9, 0.3, 0.24), "ply", bev=0.008)
                box((0, -0.16, 0.06), (0.9, 0.3, 0.12), "ply", bev=0.008)
        # yan pencereler (zırh kepenkli), menfez
        for sx in (-1, 1):
            with at((sx * (W / 2 - 0.02), 0, z0), rz=sx * math.pi / 2):
                for y in (-L * 0.22, L * 0.12):
                    yy = y * sx
                    window(yy, 1.55, 0.6, 0.7, frame="trim", mull=0, sill=False, flush=True)
                    box((yy, -0.07, 1.98), (0.75, 0.1, 0.1), "trim", bev=0.006)
                louver(-L * 0.4 * sx, 2.1, 0.3, 0.2, "trim", mat="vc")
        # elektrik kutusu + kablo
        box((W / 2 + 0.06, L * 0.3, z0 + 1.5), (0.1, 0.35, 0.45), "steel", "metal", bev=0.008)
        cyl_ab((W / 2 + 0.08, L * 0.3, z0 + 1.27), (W / 2 + 0.2, L * 0.3 + 0.3, 0.02), 0.015, "black", seg=5)


def whip(p, h=3.0, base=0.06):
    cyl((p[0], p[1], p[2] + 0.06), base, 0.12, "dark", "metal", seg=8)
    cyl((p[0], p[1], p[2] + 0.12 + h / 2), 0.008, h, "dark", "metal", seg=4)


def sign_board(p, rz=0.0, w=1.4, h=0.9, col="olive", h0=1.0):
    with at(p, rz=rz):
        for x in (-w / 2 + 0.06, w / 2 - 0.06):
            box((x, 0, (h0 + h) / 2), (0.08, 0.08, h0 + h), "wood", bev=0.006)
        box((0, -0.05, h0 + h / 2), (w, 0.04, h), col, bev=0.008)
        box((0, -0.075, h0 + h * 0.62), (w * 0.7, 0.01, h * 0.22), "white", bev=0.0, dirt=False)
        box((0, -0.075, h0 + h * 0.3), (w * 0.5, 0.01, h * 0.1), "yellow", bev=0.0, dirt=False)


# ============================================================ KARARGÂH (17 x 13)
def hq():
    global BODY_H
    usa = SIDE == "usa"
    # zemin: sıkıştırılmış çakıl + beton döşeme
    box2((-8.4, -6.4, 0), (8.4, 6.4, 0.04), "gravel", bev=0.0, dirt=False, jit=0.02)
    if usa:
        BODY_H = 5.6
        cx = -1.4
        box2((cx - 6.4, -1.6, 0.04), (cx + 6.4, 3.9, 0.12), "concrete", bev=0.01, dirt=False)
        # alt kat: iki 40 ft konteyner yan yana, üst kat: arkadakinin üstünde bir tane
        for y, z, de in ((0.0, 0.12, 0), (2.44, 0.12, 0), (2.44, 2.71, 0)):
            container((cx, y, z), L=12.19, col="paint", doors_end=-1, corr_pitch=0.3)
        # ön konteyner cephesi (-Y): kapılar, pencereler (zırh kepenkli), ECU klimaları
        with at((cx, -1.25, 0.12)):
            for x in (-3.6, 2.4):
                door(x, 0.9, 2.05, col="paint", frame="trim", panels=False, z0=0.12)
                box((x, -0.5, 0.06), (1.3, 0.8, 0.12), "ply", bev=0.008)
                lamp_wall(x, 2.3)
            for x in (-5.2, -1.6, 0.2, 4.2):
                box((x, -0.06, 1.45), (0.9, 0.05, 0.75), "dark", bev=0.0, dirt=False)
                box((x, -0.1, 1.45), (0.84, 0.03, 0.68), "glass", "glass", bev=0.0)
                box((x, -0.14, 1.88), (1.0, 0.18, 0.1), "trim", bev=0.006)
            for x in (-0.7, 3.3):
                ac_unit((x, -0.45, 0.0), col="paint", w=1.0, d=0.8, h=0.95)
                cyl_ab((x, -0.1, 0.9), (x, -0.05, 1.6), 0.13, "canvas2", seg=10)
                cyl_ab((x + 0.3, -0.1, 0.9), (x + 0.3, -0.05, 1.8), 0.13, "canvas2", seg=10)
        # üst kat güvertesi: korkuluk, kum torbası siperi, anten, uydu terminali
        zd = 2.71 + 0.12
        box2((cx - 6.1, -1.22, zd - 0.06), (cx + 6.1, 1.22, zd), "ply", bev=0.008)
        for i in range(int(12.2 / 0.6)):
            box((cx - 6.0 + i * 0.6, 0, zd + 0.005), (0.02, 2.4, 0.01), "wood", bev=0.0, dirt=False)
        railing((cx - 6.05, -1.18, zd), (cx + 4.9, -1.18, zd), 1.05, "olive", 1.5)
        railing((cx - 6.05, -1.18, zd), (cx - 6.05, 1.2, zd), 1.05, "olive", 1.5)
        sandbag_wall((cx - 5.9, -0.95, zd), (cx + 2.5, -0.95, zd), rows=2, thick=1)
        for x in (cx - 5.2, cx - 2.2, cx + 1.0):
            whip((x, 0.6, zd), 3.6)
        sat_dish((cx + 3.6, 0.2, zd - 0.95), d=1.2, rz=-0.6, el=0.75, col="white")
        # dış merdiven (+X uç) → sahanlık
        box2((cx + 6.1, -0.9, zd - 0.12), (cx + 7.3, 1.2, zd), "steel", "metal", bev=0.006)
        for x, y in ((cx + 7.25, -0.85), (cx + 7.25, 1.15)):
            cyl_ab((x, y, 0.12), (x, y, zd - 0.12), 0.05, "steel", "metal", seg=8)
        railing((cx + 7.28, -0.88, zd), (cx + 7.28, 1.18, zd), 1.05, "yellow", 1.0)
        stairs((cx + 6.7, -4.2, 0.04), (cx + 6.7, -0.9, zd), 1.0, col="steel", rail="yellow")
        # üst konteyner yan kapısı (güverteye açılan)
        with at((cx + 1.5, 1.24, zd)):
            door(0, 0.9, 2.0, col="paint", frame="trim", panels=False)
        # kamuflaj ağı (üst kat + güverte üzeri)
        camo_net(cx - 1.5, 1.4, 9.0, 5.6, 6.3, sag=0.45, seed=11, poles=False, drop=0.9)
        for x in (cx - 5.5, cx + 2.5):
            for y in (-1.3, 4.1):
                cyl((x, y, 3.2), 0.035, 6.3, "dark", "metal", seg=6)
        # ön HESCO patlama duvarı (giriş boşluklu) + kum torbası şikanı
        hesco_row((cx - 6.6, -3.6, 0.04), (cx - 1.4, -3.6, 0.04), w=1.0, d=1.0, h=1.4)
        hesco_row((cx + 0.8, -3.6, 0.04), (cx + 4.0, -3.6, 0.04), w=1.0, d=1.0, h=1.4)
        sandbag_wall((cx - 1.2, -5.0, 0.04), (cx + 0.6, -5.0, 0.04), rows=6, thick=2)
        # arka: T-duvar sırası, sol: HESCO
        for i in range(10):
            t_wall((-7.5 + i * 1.55, 5.6, 0.04), rz=math.pi, num="olive" if i % 3 == 0 else None)
        hesco_row((-8.1, 4.6, 0.04), (-8.1, -3.0, 0.04), w=1.0, d=0.9, h=1.4)
        # +X şeridi: anten direği, uydu anteni, jeneratörler, aydınlatma kulesi
        mast_guyed((7.1, 3.3, 0.04), h=12.0, top="biconical", guy=1.9)
        sat_dish((6.8, -2.6, 0.04), d=2.4, rz=-0.7, el=0.55, col="white")
        generator((6.7, 0.9, 0.04), rz=math.pi / 2, col="olive", trailer=True)
        cyl_ab((6.7, -0.3, 0.3), (cx + 6.1, -0.2, 0.2), 0.03, "black", seg=5)
        light_tower((-6.8, -5.2, 0.04), rz=0.4, col="yellow", h=5.5)
        flagpole((3.6, -5.4, 0.04), h=7.0)
        sign_board((1.9, -5.6, 0.04), rz=0.0, col="olive")
        # ön park: MRAP
        armored_hull((-4.2, -5.3, 0.04), rz=0.05, col="paint", lifted=0.0, wheels=True)
        for i in range(3):
            jerrycan((cx + 4.6 + i * 0.22, -1.9, 0.04), "olive", 0.0)
        crate((5.6, -4.9, 0.04), (1.0, 0.8, 0.6), "crate", rz=0.3)
        crate((5.6, -4.9, 0.64), (0.9, 0.7, 0.5), "crate", rz=0.2)
    else:
        BODY_H = 6.8
        # iki katlı tuğla/sıva karargâh binası (düz çatı, parapet)
        X0, X1, Y0, Y1 = -7.2, 3.6, -1.6, 4.6
        H1, H2 = 3.1, 6.2
        box2((X0 - 0.3, Y0 - 0.3, 0.04), (X1 + 0.3, Y1 + 0.3, 0.2), "concrete2", bev=0.02)
        win_x = [X0 + 1.0 + i * 1.75 for i in range(6)]
        ent = -1.95
        holes_f = [(x - X0, 1.75, 1.2, 1.5) for x in win_x if abs(x - ent) > 0.9] + [(ent - X0, 1.3, 1.6, 2.4)]
        holes_f2 = [(x - X0, 4.75, 1.2, 1.5) for x in win_x]
        holes_s = [(y - Y0, z, 1.2, 1.5) for y in (0.0, 2.8) for z in (1.75, 4.75)]

        def facade(o, u, L, holes):
            uu = Vector(u)
            yaw = math.atan2(uu.y, uu.x)
            for xa, xb, za, zb in wall_cells(L, 0.2, H2, holes):
                c = Vector(o) + uu * ((xa + xb) / 2)
                with at((c.x, c.y, 0), rz=yaw):
                    Lc = xb - xa
                    if za < 0.9:
                        z1 = min(zb, 0.9)
                        box((0, -0.07, (za + z1) / 2), (Lc, 0.14, z1 - za), "brick", bev=0.008)
                        for k in range(int((z1 - za) / 0.077)):
                            box((0, -0.143, za + 0.04 + k * 0.077), (Lc, 0.006, 0.012), "brick2", bev=0.0, dirt=False)
                    if zb > 0.9:
                        z0 = max(za, 0.9)
                        box((0, -0.05, (z0 + zb) / 2), (Lc, 0.1, zb - z0), "wall", bev=0.008)
        facade((X0, Y0, 0), (1, 0, 0), X1 - X0, holes_f + holes_f2)
        facade((X1, Y0, 0), (0, 1, 0), Y1 - Y0, holes_s)
        facade((X1, Y1, 0), (-1, 0, 0), X1 - X0, [(X1 - x, z, 1.2, 1.5) for x in win_x for z in (1.75, 4.75)])
        facade((X0, Y1, 0), (0, -1, 0), Y1 - Y0, [])
        # iç karanlık hacim (pencerelerden görünür) + kat döşemesi
        box2((X0 + 0.15, Y0 + 0.15, 0.2), (X1 - 0.15, Y1 - 0.15, H2 - 0.1), "dark", bev=0.0, dirt=False)
        # kat kornişi, parapet, harpuşta
        for (o, u, L) in (((X0, Y0), (1, 0), X1 - X0), ((X1, Y0), (0, 1), Y1 - Y0), ((X1, Y1), (-1, 0), X1 - X0), ((X0, Y1), (0, -1), Y1 - Y0)):
            yaw = math.atan2(u[1], u[0])
            c = (o[0] + u[0] * L / 2, o[1] + u[1] * L / 2)
            with at((c[0], c[1], 0), rz=yaw):
                box((0, -0.12, 0.92), (L + 0.28, 0.1, 0.06), "plinth", bev=0.008)
                box((0, -0.14, H1 + 0.05), (L + 0.3, 0.16, 0.22), "trim", bev=0.01)
                box((0, -0.05, H2 + 0.25), (L + 0.1, 0.2, 0.5), "wall", bev=0.01)
                box((0, -0.06, H2 + 0.52), (L + 0.2, 0.32, 0.06), "galv", "metal", bev=0.006)
                box((0, -0.16, H2 - 0.05), (L + 0.32, 0.2, 0.2), "trim", bev=0.01)
        # pencereler: beyaz kasa, sövelı; zemin kat kum torbalı
        def wins(o, u, xs, zs, bags):
            yaw = math.atan2(u[1], u[0])
            with at((o[0], o[1], 0), rz=yaw):
                for x in xs:
                    for z in zs:
                        window(x, z, 1.2, 1.5, frame="white", mull=1, tr=0.45, depth=0.25, sill=True)
                        box((x, -0.11, z + 0.82), (1.5, 0.08, 0.14), "trim", bev=0.006)
                        for s in (-1, 1):
                            box((x + s * 0.68, -0.11, z), (0.14, 0.06, 1.64), "trim", bev=0.006)
                        if bags and z < 2:
                            for r in range(5):
                                for i in range(3):
                                    bag((x - 0.4 + i * 0.4 + (0.2 if r % 2 else 0) - 0.1, -0.3, 1.0 + r * 0.14), (0.42, 0.3, 0.15), "bag", RND.uniform(-0.05, 0.05))
        wins((X0, Y0), (1, 0), [x - X0 for x in win_x if abs(x - ent) > 0.9], [1.75], True)
        wins((X0, Y0), (1, 0), [x - X0 for x in win_x], [4.75], False)
        wins((X1, Y0), (0, 1), [0.0 - Y0, 2.8 - Y0], [1.75, 4.75], True)
        # giriş: basamaklar, iki sütunlu saçak, çift kanat kapı, plaka
        with at((ent, Y0, 0)):
            door(0, 1.5, 2.3, col="door", frame="trim", z0=0.2, panels=True)
            for i in range(3):
                box((0, -0.45 - i * 0.3, 0.2 - i * 0.065), (2.6 + i * 0.3, 0.9 + i * 0.6, 0.065), "concrete", bev=0.01)
            box((0, -0.9, 2.95), (2.8, 1.9, 0.18), "concrete", bev=0.015)
            box((0, -0.9, 3.08), (2.9, 2.0, 0.06), "galv", "metal", bev=0.004)
            for s in (-1, 1):
                box((s * 1.2, -1.65, 1.55), (0.3, 0.3, 2.7), "white", bev=0.015)
            box((0.95, -0.1, 1.6), (0.45, 0.04, 0.6), "red", bev=0.004)
            box((0.95, -0.125, 1.65), (0.3, 0.01, 0.2), "yellow", bev=0.0, dirt=False)
            lamp_wall(-1.0, 2.7)
            lamp_wall(1.0, 2.7)
        # düz çatı: bitüm, havalandırma çıkıntıları, merdiven kapısı, antenler, drone ağı
        box2((X0 + 0.1, Y0 + 0.1, H2 - 0.02), (X1 - 0.1, Y1 - 0.1, H2 + 0.06), (0.24, 0.24, 0.23), bev=0.0, dirt=False)
        box((X0 + 2.0, Y1 - 1.6, H2 + 0.9), (2.2, 2.0, 1.8), "wall", bev=0.02)
        box((X0 + 2.0, Y1 - 1.6, H2 + 1.85), (2.4, 2.2, 0.1), "trim", bev=0.01)
        with at((X0 + 2.0, Y1 - 2.6, H2 + 0.06)):
            door(0, 0.8, 1.7, col="door", frame="trim")
        for x in (X0 + 5.0, X1 - 1.6):
            box((x, Y0 + 2.2, H2 + 0.5), (0.6, 0.6, 0.9), "brick", bev=0.01)
            box((x, Y0 + 2.2, H2 + 1.0), (0.75, 0.75, 0.08), "concrete", bev=0.008)
        for x in (X0 + 3.5, X0 + 6.5, X1 - 0.8):
            whip((x, Y0 + 0.6, H2 + 0.06), 4.0)
        sat_dish((X1 - 2.6, Y1 - 1.4, H2 + 0.06 - 0.95), d=1.4, rz=-0.8, el=0.7, col="white")
        # drone karşıtı ağ: direkler + gergin ağ (yarım çatı)
        for x in (X0 + 4.0, X1 - 0.4):
            for y in (Y0 + 0.5, Y1 - 0.5):
                cyl((x, y, H2 + 1.3), 0.04, 2.5, "dark", "metal", seg=6)
        camo_net((X0 + 4.0 + X1 - 0.4) / 2, (Y0 + Y1) / 2, X1 - X0 - 3.6, Y1 - Y0 - 0.6, H2 + 2.5, sag=0.3, col1="net", col2="olive2", col3="canvas2", seed=5, poles=False, drop=0.35, holes=0.25)
        # iniş boruları
        for (x, y, rz) in ((X1 + 0.1, Y0 + 0.1, math.pi / 2), (X0 - 0.1, Y0 + 0.1, 0.0)):
            with at((x, y, 0), rz=rz):
                downpipe(0, 0.0, H2 + 0.3, "galv", y=-0.06)
        # beton çit (arka ve sol), beton bloklar (ön)
        for i in range(4):
            concrete_fence((-6.2 + i * 4.1, 6.1, 0.04), rz=0.0)
        for i in range(3):
            concrete_fence((-8.1, 3.6 - i * 4.1, 0.04), rz=math.pi / 2)
        for i, (x, y, r) in enumerate(((-5.2, -4.6, 0.1), (-2.9, -4.9, -0.05), (0.8, -4.7, 0.08))):
            jersey((x, y, 0.04), rz=r)
        # kafes direk (kırmızı-beyaz), jeneratör römorku, varil, kum torbası mevzi
        lattice_mast((6.6, 3.8, 0.04), h=14.0, guy=1.8)
        sat_dish((6.6, -0.4, 0.04), d=2.2, rz=-0.9, el=0.5, col="white", base="olive")
        generator((5.9, -3.4, 0.04), rz=0.0, col="olive", trailer=True)
        cyl_ab((6.9, -3.2, 0.3), (X1 + 0.2, -1.0, 0.25), 0.03, "black", seg=5)
        for i, (dx, dy) in enumerate(((0, 0), (0.6, 0.1), (0.3, 0.6))):
            drum((7.6 + dx * 0.0 - 0.3 + dx, 0.9 + dy, 0.04), col="olive" if i != 1 else "rust")
        flagpole((2.4, -4.9, 0.04), h=7.0)
        # köşe MG mevzisi
        for k in range(8):
            a = -0.2 + k * 0.32
            for r in range(3):
                bag((-6.6 + math.cos(a) * 1.0, -2.7 - math.sin(a) * 1.0, 0.11 + r * 0.14), (0.5, 0.3, 0.15), "bag", -a + math.pi / 2)
        sign_board((4.6, -5.9, 0.04), rz=0.0, col="door")


def water_pallet(p, rz=0.0):
    """Streç filmli su şişesi paleti (koli katları)."""
    with at(p, rz=rz):
        pallet((0, 0, 0), 1.2, 1.0)
        for k in range(4):
            box((0, 0, 0.27 + k * 0.26), (1.14, 0.94, 0.25), (0.62, 0.75, 0.82), bev=0.02, jit=0.02)
            for i in range(4):
                box((-0.43 + i * 0.29, -0.475, 0.27 + k * 0.26), (0.26, 0.01, 0.2), (0.85, 0.88, 0.9), bev=0.0, dirt=False)
        box((0, 0, 1.31), (1.12, 0.92, 0.04), (0.82, 0.86, 0.88), bev=0.01)


def tyre_border(a, b, n, col="white"):
    """Yarıya kadar gömülü beyaz boyalı lastik sırası (Doğu kışla süsü)."""
    a = Vector(a); b = Vector(b)
    yaw = math.atan2((b - a).y, (b - a).x)
    for i in range(n):
        p = a.lerp(b, (i + 0.5) / n)
        lathe([(0.2, -0.12), (0.34, -0.1), (0.36, 0.0), (0.34, 0.1), (0.2, 0.12)], col, c=(p.x, p.y, 0.02), rot=(math.pi / 2, 0, yaw + math.pi / 2), seg=14)


# ============================================================ KIŞLA (9 x 6)
def barracks():
    global BODY_H
    usa = SIDE == "usa"
    box2((-4.45, -2.95, 0), (4.45, 2.95, 0.04), "gravel", bev=0.0, dirt=False, jit=0.02)
    if usa:
        BODY_H = 3.2
        xs = (-3.25, -0.6, 2.05)
        for i, x in enumerate(xs):
            chu_box((x, 0.35, 0.04), L=5.2, col="wall" if i != 1 else "wall2", steps=False)
            # çatıda kum torbası katmanı (havan korunması)
            for r, yy in enumerate((-0.85, 0.0, 0.85)):
                for k in range(8):
                    bag((x + yy, 0.35 - 2.3 + k * 0.62 + (0.3 if r == 1 else 0) - (0.3 if r == 1 and k == 7 else 0), 2.95), (0.3, 0.6, 0.15), "bag", RND.uniform(-0.05, 0.05))
            for k in range(7):
                bag((x - 0.42, 0.35 - 2.0 + k * 0.62, 3.09), (0.3, 0.6, 0.14), "bag", RND.uniform(-0.05, 0.05))
        # ahşap yürüme platformu (kapıların önü)
        box2((-4.4, -2.9, 0.04), (3.3, -2.3, 0.08), "wood", bev=0.0)
        for i in range(int(7.7 / 0.16)):
            box((-4.32 + i * 0.16, -2.6, 0.24), (0.14, 0.6, 0.035), "ply", bev=0.004, jit=0.08)
        for x in (-4.3, -2.4, -0.5, 1.4, 3.2):
            for y in (-2.85, -2.35):
                box((x, y, 0.13), (0.1, 0.1, 0.18), "wood", bev=0.005)
        # +X: HESCO patlama duvarı, ön köşe: su paletleri, yangın söndürücü, çöp varili
        hesco_row((4.0, -1.5, 0.04), (4.0, 2.9, 0.04), w=1.1, d=0.9, h=1.6)
        water_pallet((3.95, -2.35, 0.04), rz=0.1)
        fire_ext((3.35, -1.65, 0.04))
        drum((3.35, 2.75, 0.04), col="olive")
        # elektrik dağıtım panosu + kablolar
        box((-1.95, 2.95, 0.9), (0.6, 0.3, 0.9), "olive", "metal", bev=0.01)
        cyl((-1.95, 2.95, 0.25), 0.04, 0.5, "dark", "metal", seg=6)
        for x in xs:
            cyl_ab((-1.95, 2.85, 0.6), (x + 1.3, 2.4, 0.05), 0.015, "black", seg=4)
        # gölgelik ağı (yürüyüşün üstünde, CHU'lar arasında)
        for x in (-4.3, -1.9, 0.75, 3.2):
            cyl((x, -3.0, 1.45), 0.04, 2.8, "dark", "metal", seg=6)
        camo_net(-0.55, -2.65, 7.8, 0.9, 2.85, sag=0.12, seed=21, poles=False, drop=0.15, holes=0.08, nu=22, nv=3)
        flagpole((-4.25, 2.6, 0.04), h=4.5)
    else:
        BODY_H = 4.6
        X0, X1, Y0, Y1 = -4.2, 4.2, -2.4, 2.4
        EAVE, RIDGE = 3.0, 4.5
        box2((X0 - 0.15, Y0 - 0.15, 0.0), (X1 + 0.15, Y1 + 0.15, 0.35), "concrete2", bev=0.02)
        wx = (-3.0, -1.6, 1.6, 3.0)
        dx = 0.0
        hf = [(x - X0, 1.85, 1.0, 1.35) for x in wx] + [(dx - X0, 1.4, 1.1, 2.1)]
        hs = [(0.0 - Y0, 1.85, 1.0, 1.35)]

        def wall(o, u, L, holes, top=EAVE):
            uu = Vector(u)
            yaw = math.atan2(uu.y, uu.x)
            for xa, xb, za, zb in wall_cells(L, 0.35, top, holes):
                c = Vector(o) + uu * ((xa + xb) / 2)
                with at((c.x, c.y, 0), rz=yaw):
                    Lc = xb - xa
                    if za < 0.9:
                        z1 = min(zb, 0.9)
                        box((0, -0.07, (za + z1) / 2), (Lc, 0.14, z1 - za), "brick", bev=0.008)
                        for k in range(int((z1 - za) / 0.077)):
                            box((0, -0.143, za + 0.04 + k * 0.077), (Lc, 0.006, 0.012), "brick2", bev=0.0, dirt=False)
                    if zb > 0.9:
                        z0 = max(za, 0.9)
                        box((0, -0.05, (z0 + zb) / 2), (Lc, 0.1, zb - z0), "wall", bev=0.008)
        wall((X0, Y0, 0), (1, 0, 0), X1 - X0, hf)
        wall((X1, Y1, 0), (-1, 0, 0), X1 - X0, [(X1 - x, 1.85, 1.0, 1.35) for x in wx])
        wall((X1, Y0, 0), (0, 1, 0), Y1 - Y0, hs)
        wall((X0, Y1, 0), (0, -1, 0), Y1 - Y0, [])
        box2((X0 + 0.12, Y0 + 0.12, 0.35), (X1 - 0.12, Y1 - 0.12, EAVE), "dark", bev=0.0, dirt=False)
        # alınlıklar (ahşap kaplama, çatı arası havalandırma)
        for xx, fl in ((X1, 1), (X0, -1)):
            with at((xx, 0, 0), rz=fl * math.pi / 2):
                prism([(Y0 - 0.0, EAVE), (Y1, EAVE), (0, RIDGE)], 0.06, "wood", c=(0, 0.0, 0), rot=(math.pi / 2, 0, 0))
                for k in range(int((Y1 - Y0) / 0.15)):
                    y = Y0 + 0.075 + k * 0.15
                    hz = EAVE + (RIDGE - EAVE) * (1 - abs(y) / Y1)
                    if hz - EAVE > 0.05:
                        box((y, -0.07, (EAVE + hz) / 2), (0.13, 0.03, hz - EAVE), "wood", bev=0.0, jit=0.08)
                louver(0, EAVE + 0.6, 0.6, 0.4, "wood", mat="vc")
        # pencereler, kapı, sundurma
        with at((X0, Y0, 0)):
            for x in wx:
                window(x - X0, 1.85, 1.0, 1.35, frame="white", mull=1, tr=0.4, depth=0.25)
                box((x - X0, -0.11, 2.62), (1.2, 0.08, 0.1), "white", bev=0.006)
            door(dx - X0, 1.0, 2.0, col="door", frame="white", z0=0.4)
        with at((X1, Y0, 0), rz=math.pi / 2):
            window(0.0 - Y0, 1.85, 1.0, 1.35, frame="white", mull=1, tr=0.4, depth=0.25)
        with at((dx, Y0, 0)):
            for i in range(2):
                box((0, -0.45 - i * 0.28, 0.33 - i * 0.12), (1.6, 0.9 + i * 0.56, 0.12), "concrete", bev=0.01)
            for s in (-1, 1):
                box((s * 0.75, -1.05, 1.35), (0.1, 0.1, 2.0), "wood", bev=0.008)
                with at((0, -0.65, 2.5), ry=s * 0.55):
                    box((s * 0.48, 0, 0), (1.05, 1.5, 0.04), "olive", "metal", bev=0.004)
            prism([(-0.95, 0), (0.95, 0), (0, 0.55)], 0.05, "wood", c=(0, -1.38, 2.22), rot=(math.pi / 2, 0, 0))
            lathe([(0.03, 0.1), (0.2, -0.05), (0.22, -0.07)], "olive", c=(0, -0.3, 2.3), seg=12)
            cyl((0, -0.3, 2.235), 0.18, 0.02, "lamp", "lamp", seg=12, smooth=False)
            box((0.78, -0.08, 1.55), (0.36, 0.03, 0.5), "red", bev=0.004)
            box((0.78, -0.1, 1.6), (0.24, 0.01, 0.15), "yellow", bev=0.0, dirt=False)
        # çatı: yeşil boyalı trapez sac, mahya, oluklar, bacalar
        over = 0.4
        run = Y1 - Y0
        sl = math.hypot(run / 2 + over, (run / 2 + over) * (RIDGE - EAVE) / (run / 2))
        slope = (RIDGE - EAVE) / (run / 2)
        ze = RIDGE - (run / 2 + over) * slope
        for s in (-1, 1):
            vdir = Vector((0, s * (run / 2 + over), ze - RIDGE)).normalized()
            u = (-1, 0, 0) if s < 0 else (1, 0, 0)
            x0 = (X1 + over) if s < 0 else (X0 - over)
            nsh = 9
            Lr = X1 - X0 + 2 * over
            for i in range(nsh):
                xo = x0 - i * Lr / nsh if s < 0 else x0 + i * Lr / nsh
                corr((xo, 0, RIDGE + 0.04), u, vdir, Lr / nsh, sl, "olive" if i not in (3,) else "rust", pitch=0.2, depth=0.035, back="steel")
            box((0, s * (run / 2 + over + 0.06), ze - 0.06), (Lr, 0.14, 0.12), "galv", "metal", bev=0.008)
            with at((0, 0, RIDGE + 0.09), rx=-s * math.atan(slope)):
                box((0, s * 0.16, 0), (Lr + 0.02, 0.34, 0.025), "olive", "metal", bev=0.0)
        for x in (-2.2, 2.2):
            box((x, 0.6, RIDGE + 0.2), (0.5, 0.5, 1.4), "brick", bev=0.01)
            box((x, 0.6, RIDGE + 0.92), (0.62, 0.62, 0.08), "concrete", bev=0.006)
            box((x, 0.6, RIDGE + 1.0), (0.3, 0.3, 0.1), "black", bev=0.0, dirt=False)
        for (x, y, rz) in ((X1 + 0.05, Y0 - 0.45, math.pi / 2), (X0 - 0.05, Y0 - 0.45, -math.pi / 2)):
            with at((x, y, 0), rz=rz):
                downpipe(0, 0.0, ze - 0.06, "galv", y=0.0)
        # +X: açık hava lavabosu (oluk, musluklar, üstte su deposu)
        with at((X1 + 0.45, 0.9, 0.0), rz=math.pi / 2):
            box((0, 0, 0.85), (2.0, 0.45, 0.25), "galv", "metal", bev=0.01)
            box((0, 0, 0.98), (1.9, 0.36, 0.02), "dark", "metal", bev=0.0, dirt=False)
            for x in (-0.9, 0.9):
                for y in (-0.18, 0.18):
                    cyl_ab((x, y, 0.0), (x, y, 0.75), 0.025, "dark", "metal", seg=5)
            box((0, 0.24, 1.55), (2.0, 0.06, 1.1), "wood", bev=0.006)
            cyl((0, 0.15, 2.3), 0.32, 1.8, "galv", "metal", rot=(0, math.pi / 2, 0), seg=14, bev=0.01)
            for k in range(5):
                x = -0.8 + k * 0.4
                cyl_ab((x, 0.2, 1.3), (x, 0.08, 1.22), 0.018, "steel", "metal", seg=5)
        # ön: beyaz lastik sırası, bank, sigara içme köşesi (yarım varil)
        tyre_border((-4.2, -3.0, 0), (-1.2, -3.0, 0), 5)
        tyre_border((1.2, -3.0, 0), (4.2, -3.0, 0), 5)
        with at((X0 - 0.15, 0.4, 0), rz=-math.pi / 2):
            for x in (-0.7, 0.7):
                box((x, 0, 0.22), (0.08, 0.36, 0.44), "wood", bev=0.005)
            for k in range(3):
                box((0, -0.12 + k * 0.12, 0.46), (1.7, 0.1, 0.04), "wood", bev=0.004, jit=0.08)
        lathe([(0.0, 0.0), (0.29, 0.0), (0.29, 0.42), (0.27, 0.42), (0.27, 0.05), (0.0, 0.05)], "rust", c=(X1 + 0.1, Y0 - 0.55, 0.0), seg=14)
        flagpole((X0 - 0.05, Y0 - 0.5, 0.0), h=5.0)


def log_ab(a, b, r=0.11, col="wood"):
    """Kütük: kabuk (koyu) + açık renkli kesik uçlar."""
    cyl_ab(a, b, r, (0.36, 0.28, 0.2), seg=8, bev=0.0)
    a = Vector(a); b = Vector(b)
    d = (b - a).normalized()
    cyl_ab(a - d * 0.005, a + d * 0.01, r * 0.92, (0.72, 0.6, 0.42), seg=8)
    cyl_ab(b - d * 0.01, b + d * 0.005, r * 0.92, (0.72, 0.6, 0.42), seg=8)


def arch_tent(p, L, W, H, col="canvas", rz=0.0, ribs=True, door_ends=(True, True), wins=0, rib_col="canvas2", n=10):
    """Kemerli çadır (Alaska/TEMPER tipi): X boyunca L, yarı-elips kesit, dış kaburga bantları, uç duvarları, kapı."""
    with at(p, rz=rz):
        prof = []
        for i in range(n + 1):
            a = math.pi * i / n
            prof.append((math.cos(a) * W / 2, math.sin(a) * H * 0.93 + 0.12 * (1 - math.sin(a))))
        prof = [(y, z) for y, z in prof]
        # kumaş: kesit boyunca X'e uzatılmış yüzey (yumuşak gölgeli)
        def fn(u, v):
            y, z = prof[int(round(v * n))]
            return (-L / 2 + u * L, y, z)
        nseg = max(2, int(L / 1.2))
        grid_surf(fn, nseg, n, col, "cloth", smooth=True)
        # uç duvarları (düz) + kapı
        for e in (-1, 1):
            pts = [(y, z) for y, z in prof]
            with at((e * L / 2, 0, 0), rz=(0 if e > 0 else math.pi)):
                prism([(-y, z) for y, z in pts], 0.04, "canvas2", c=(-0.02, 0, 0), rot=(math.pi / 2, 0, math.pi / 2))
                if door_ends[0 if e < 0 else 1]:
                    box((0.03, 0, 1.0), (0.03, 1.0, 2.0), "dark", bev=0.0, dirt=False)
                    box((0.045, 0.38, 1.0), (0.02, 0.4, 1.95), col, "cloth", bev=0.0)       # yarı açık kanat
                    box((0.05, -0.3, 1.05), (0.02, 0.5, 1.9), col, "cloth", r=(0.05, 0, 0), bev=0.0)
                    box((0.06, 0, 2.05), (0.03, 1.2, 0.08), "canvas2", bev=0.0)
        if ribs:
            for k in range(nseg + 1):
                x = -L / 2 + 0.06 + k * (L - 0.12) / nseg
                for i in range(n):
                    a0, a1 = prof[i], prof[i + 1]
                    bar_ab((x, a0[0] * 1.01, a0[1] * 1.005 + 0.005), (x, a1[0] * 1.01, a1[1] * 1.005 + 0.005), 0.07, 0.025, rib_col, up=(1, 0, 0))
        # kazık ve gergi ipleri
        for k in range(nseg + 1):
            x = -L / 2 + 0.06 + k * (L - 0.12) / nseg
            for s in (-1, 1):
                cyl_ab((x, s * W * 0.42, H * 0.55), (x, s * (W / 2 + 0.9), 0.0), 0.008, "canvas2", seg=3)
                cyl((x, s * (W / 2 + 0.9), 0.08), 0.02, 0.2, "dark", "metal", seg=4)
        # pencereler (şeffaf panel)
        for k in range(wins):
            x = -L / 2 + (k + 0.5) * L / wins
            ang = math.pi * 2 / n * 1.5
            yy = -math.cos(ang) * W / 2 * 1.01
            zz = math.sin(ang) * H * 0.93
            with at((x, -abs(yy), zz), rx=-(math.pi / 2 - ang)):
                box((0, 0, 0), (0.7, 0.02, 0.4), "glass", "glass", bev=0.0)
                box((0, 0.005, 0), (0.8, 0.02, 0.5), "canvas2", bev=0.0)


def ridge_tent(p, L, W, Hw, Hr, col="canvas", rz=0.0, wins=3, door_x=True, stove=True):
    """Duvarlı sırt çadırı (UST-56 tipi): dikey yan duvarlar, iki eğimli çatı, dikiş bantları, pencereler, soba bacası."""
    with at(p, rz=rz):
        # yan duvarlar (hafif içe eğik), çatı
        for s in (-1, 1):
            poly([(-L / 2, s * W / 2, 0.02), (L / 2, s * W / 2, 0.02), (L / 2, s * W / 2 * 0.97, Hw), (-L / 2, s * W / 2 * 0.97, Hw)][::(1 if s < 0 else -1)], col, "cloth")
            poly([(-L / 2 - 0.15, s * (W / 2 + 0.12), Hw - 0.08), (L / 2 + 0.15, s * (W / 2 + 0.12), Hw - 0.08), (L / 2 + 0.15, 0, Hr), (-L / 2 - 0.15, 0, Hr)][::(1 if s < 0 else -1)], col, "cloth")
            # dikiş bantları
            for k in range(int(L / 1.0) + 1):
                x = -L / 2 + k * L / int(L / 1.0)
                bar_ab((x, s * W / 2 * 1.005, 0.02), (x, s * W / 2 * 0.975, Hw), 0.05, 0.02, "canvas2", up=(1, 0, 0))
                bar_ab((x, s * (W / 2 + 0.13), Hw - 0.07), (x, 0, Hr + 0.012), 0.05, 0.02, "canvas2", up=(1, 0, 0))
            bar_ab((-L / 2 - 0.15, s * (W / 2 + 0.125), Hw - 0.1), (L / 2 + 0.15, s * (W / 2 + 0.125), Hw - 0.1), 0.06, 0.03, "canvas2")
            # pencereler
            for k in range(wins):
                x = -L / 2 + (k + 0.5) * L / wins
                with at((x, s * W / 2 * 0.99, Hw * 0.55), rz=0 if s < 0 else math.pi):
                    box((0, -0.01, 0), (0.62, 0.02, 0.42), "canvas2", bev=0.0)
                    box((0, -0.02, 0), (0.5, 0.02, 0.3), "glass", "glass", bev=0.0)
                    box((0, -0.03, 0), (0.025, 0.02, 0.3), "canvas2", bev=0.0)
            # ipler ve kazıklar
            for k in range(int(L / 1.0) + 1):
                x = -L / 2 + k * L / int(L / 1.0)
                cyl_ab((x, s * (W / 2 + 0.12), Hw - 0.08), (x, s * (W / 2 + 1.0), 0.0), 0.008, "canvas2", seg=3)
                cyl((x, s * (W / 2 + 1.0), 0.08), 0.022, 0.2, "wood", seg=4)
        bar_ab((-L / 2 - 0.15, 0, Hr + 0.01), (L / 2 + 0.15, 0, Hr + 0.01), 0.08, 0.04, "canvas2")
        for e in (-1, 1):
            with at((e * L / 2, 0, 0), rz=(0 if e > 0 else math.pi)):
                prism([(-W / 2, 0.02), (W / 2, 0.02), (W / 2 * 0.97, Hw), (0, Hr), (-W / 2 * 0.97, Hw)], 0.03, col, c=(0.0, 0, 0), rot=(math.pi / 2, 0, math.pi / 2), mat="cloth")
                if door_x:
                    box((0.035, 0, 0.95), (0.02, 0.95, 1.85), "dark", bev=0.0, dirt=False)
                    box((0.05, 0.3, 0.95), (0.02, 0.4, 1.85), col, "cloth", r=(0.0, 0, 0), bev=0.0)
                    bar_ab((0.05, -0.5, 0.0), (0.05, -0.5, 1.95), 0.04, 0.04, "canvas2")
                    bar_ab((0.05, 0.5, 0.0), (0.05, 0.5, 1.95), 0.04, 0.04, "canvas2")
        if stove:
            x = L * 0.25
            yy = W * 0.22
            zz = Hw + (Hr - Hw) * (1 - yy / (W / 2 + 0.12)) + 0.02
            box((x, yy, zz), (0.5, 0.5, 0.02), "steel", "metal", r=(math.atan2(Hr - Hw, W / 2), 0, 0), bev=0.0)
            cyl((x, yy, zz + 0.6), 0.07, 1.3, "dark", "metal", seg=8)
            lathe([(0.0, 0.18), (0.18, 0.02), (0.18, 0.0)], "dark", c=(x, yy, zz + 1.3), seg=10, mat="metal", smooth=False)
            for k in range(3):
                a = k * math.tau / 3
                cyl_ab((x, yy, zz + 1.1), (x + math.cos(a) * 1.2, yy + math.sin(a) * 0.8, zz - 0.2), 0.004, "dark", "metal", seg=3)


def ru_crate(p, s=(0.9, 0.45, 0.3), rz=0.0):
    """Doğu tipi yeşil ahşap mühimmat sandığı: çıtalar, ip kulplar, kilit dilleri."""
    with at(p, rz=rz):
        box((0, 0, s[2] / 2), s, "crate", bev=0.01)
        for i in range(3):
            box((0, -s[1] / 2 - 0.005, 0.05 + i * (s[2] - 0.1) / 2), (s[0], 0.012, 0.012), "olive2", bev=0.0)
        for x in (-s[0] / 2 + 0.05, s[0] / 2 - 0.05):
            box((x, 0, s[2] / 2), (0.08, s[1] + 0.015, s[2] + 0.01), "crate", bev=0.004)
        for sx in (-1, 1):
            lathe([(0.04, -0.01), (0.05, -0.01), (0.05, 0.01), (0.04, 0.01)], "canvas2", c=(sx * (s[0] / 2 + 0.01), 0, s[2] * 0.6), rot=(0, math.pi / 2, 0), seg=8)
        for x in (-s[0] * 0.25, s[0] * 0.25):
            box((x, -s[1] / 2 - 0.012, s[2] - 0.05), (0.05, 0.015, 0.08), "steel", "metal", bev=0.0)
        box((0, -s[1] / 2 - 0.01, s[2] * 0.45), (s[0] * 0.3, 0.006, s[2] * 0.18), "white", bev=0.0, dirt=False)


# ============================================================ İLERİ ÜS (10 x 10)
def fob():
    global BODY_H
    usa = SIDE == "usa"
    BODY_H = 2.6
    R = 4.6
    Rv = R / math.cos(math.pi / 16)
    box2((-4.9, -4.9, 0), (4.9, 4.9, 0.03), "gravel", bev=0.0, dirt=False, jit=0.02)
    # çevre: oyun ızgarasıyla aynı 16'lı halka (Godot açısı 90°–112.5° arası giriş boşluğu)
    def vert(k):
        a = -(k * math.tau / 16 - math.pi / 16)     # Godot z → Blender -y
        return Vector((math.cos(a) * Rv, math.sin(a) * Rv, 0.03))
    segs = [i for i in range(16) if i not in (4, 5)]
    for i in segs:
        a, b = vert(i), vert(i + 1)
        if usa:
            hesco_row(a, b, w=0.9, d=1.0, h=1.15)
            if i in (9, 10, 11, 12, 13, 14):
                m = (a + b) / 2
                cc = m * (1 + 0.0 / R)
                concertina(a * 1.0 + Vector((0, 0, 1.55)), b * 1.0 + Vector((0, 0, 1.55)), r=0.35, pitch=0.25)
        else:
            # kütük kaplamalı toprak siper + üstte kum torbaları
            d = (b - a)
            L = d.length
            yaw = math.atan2(d.y, d.x)
            n = Vector((math.sin(yaw), -math.cos(yaw), 0))     # dışa
            with at(a, rz=yaw):
                prism_x([(-0.6, 0.0), (0.5, 0.0), (0.5, 0.95), (-0.25, 0.95)], 0.0, L, "fill", bev=0.0)
                for k in range(5):
                    log_ab((-0.05, 0.6, 0.11 + k * 0.19), (L + 0.05, 0.6, 0.11 + k * 0.19), 0.1)
                for x in (0.15, L / 2, L - 0.15):
                    cyl((x, 0.74, 0.6), 0.05, 1.25, (0.4, 0.32, 0.22), seg=6)
                    cyl_ab((x, 0.74, 1.1), (x, 0.3, 1.0), 0.012, "dark", "metal", seg=3)
                for k in range(3):
                    bag((0.3 + k * 0.6, 0.3, 1.03), (0.58, 0.3, 0.15), "bag", RND.uniform(-0.06, 0.06))
                for k in range(2):
                    bag((0.6 + k * 0.6, 0.28, 1.17), (0.58, 0.3, 0.15), "bag", RND.uniform(-0.06, 0.06))
    # merkez yapı: Godot (-0.8,-0.8) 3.6x3.6 → Blender (-0.8, 0.8)
    cx, cy = -0.8, 0.8
    if usa:
        arch_tent((cx, cy, 0.03), 3.4, 3.3, 2.3, col="canvas", rz=0.0, door_ends=(True, False))
        camo_net(cx + 0.2, cy + 0.9, 4.4, 2.6, 2.7, sag=0.3, seed=31, poles=True, drop=0.8)
        # gözetleme kulesi (arka sağ), mühimmat istifi (ön sağ)
        guard_tower((2.6, 2.4, 0.03), h=3.0, col="wood", roof="roof", plat=1.8, rz=0.0, ladder_side=-1)
        for k, (x, y) in enumerate(((1.7, -1.6), (2.4, -1.6), (1.7, -2.15), (2.4, -2.15))):
            for z in range(2 if k < 2 else 1):
                ammo_box((x, y, 0.03 + z * 0.21), rz=0.0)
        crate((2.0, -0.6, 0.03), (1.0, 0.7, 0.55), "crate", rz=0.15)
        crate((2.0, -0.6, 0.58), (0.8, 0.6, 0.45), "crate", rz=0.05)
        generator((-2.3, -1.9, 0.03), rz=0.2, col="olive", trailer=False, big=0.6)
        for i in range(3):
            jerrycan((-3.3 + i * 0.2, -1.2, 0.03), "olive", 0.0)
        whip((0.9, 2.1, 0.03), 4.5)
        flagpole((0.8, -2.6, 0.03), h=4.5)
        light_tower((-3.0, 2.6, 0.03), rz=-0.6, col="yellow", h=4.0)
        water_pallet((0.4, 3.1, 0.03), rz=0.2)
    else:
        # kütük sığınak (blindaj): kütük duvarlar, toprak örtülü çatı, girişte basamaklar, soba borusu
        with at((cx, cy, 0.03)):
            for k in range(6):
                z = 0.1 + k * 0.19
                for s in (-1, 1):
                    log_ab((-1.7, s * 1.6, z), (1.7, s * 1.6, z), 0.1)
                    log_ab((s * 1.6, -1.7, z + 0.095), (s * 1.6, 1.7, z + 0.095), 0.1)
            for i in range(9):
                log_ab((-1.85 + i * 0.46, -1.85, 1.3), (-1.85 + i * 0.46, 1.85, 1.3), 0.11)
            prism_x([(-1.9, 1.38), (1.9, 1.38), (1.2, 1.95), (-1.2, 1.95)], -1.9, 1.9, "fill", bev=0.0)
            for k in range(14):
                bag((RND.uniform(-1.3, 1.3), RND.uniform(-1.0, 1.0), 2.0), (0.58, 0.3, 0.15), "bag", RND.uniform(0, 3))
            # giriş (ön): kazılmış basamaklar ve kütük çerçeve
            box((0.6, -1.66, 0.75), (0.9, 0.06, 1.4), "dark", bev=0.0, dirt=False)
            for s in (-1, 1):
                log_ab((0.6 + s * 0.5, -1.75, 0.0), (0.6 + s * 0.5, -1.75, 1.45), 0.09)
            log_ab((-0.0, -1.75, 1.45), (1.2, -1.75, 1.45), 0.09)
            for i in range(3):
                box((0.6, -2.0 - i * 0.28, 0.25 - i * 0.08), (0.9, 0.3, 0.1), "wood", bev=0.006)
            cyl((-0.8, 0.6, 2.4), 0.07, 1.2, "dark", "metal", seg=8)
            lathe([(0.0, 0.16), (0.16, 0.02), (0.16, 0.0)], "dark", c=(-0.8, 0.6, 3.0), seg=10, mat="metal", smooth=False)
        camo_net(cx, cy, 4.4, 4.2, 2.6, sag=0.3, col1="net", col2="olive2", col3="canvas2", seed=41, poles=True, drop=0.9)
        guard_tower((2.6, 2.4, 0.03), h=3.0, col="wood", roof="rust", plat=1.8, rz=0.0, ladder_side=-1)
        for k, (x, y) in enumerate(((1.6, -1.7), (2.5, -1.7), (1.6, -2.2), (2.5, -2.2))):
            ru_crate((x, y, 0.03))
            if k < 2:
                ru_crate((x, y, 0.33), rz=0.05)
        for i, (x, y) in enumerate(((2.4, -0.5), (2.9, -0.2), (2.0, -0.1))):
            drum((x, y, 0.03), col="olive" if i != 1 else "rust")
        generator((-2.4, -2.0, 0.03), rz=0.3, col="olive", trailer=False, big=0.55)
        whip((0.9, 2.2, 0.03), 4.5)
        flagpole((0.8, -2.6, 0.03), h=4.5)
        stretcher((-3.0, 2.2, 0.03), rz=0.4, legs=False, col="canvas")
        for i in range(2):
            ru_crate((-3.2 + i * 0.95, 3.0, 0.03), s=(0.9, 0.45, 0.3), rz=0.1)


# ============================================================ HELİKOPTER PİSTİ (11 x 11)
def helipad():
    global BODY_H
    usa = SIDE == "usa"
    BODY_H = 2.4
    S_ = 10.6
    box2((-5.45, -5.45, 0), (5.45, 5.45, 0.03), "gravel", bev=0.0, dirt=False, jit=0.02)
    if usa:
        # beton plaka: 2.65 m'lik döşeme karoları, derzler, lastik izleri
        n = 4
        for i in range(n):
            for j in range(n):
                x = -S_ / 2 + (i + 0.5) * S_ / n
                y = -S_ / 2 + (j + 0.5) * S_ / n
                box((x, y, 0.08), (S_ / n - 0.025, S_ / n - 0.025, 0.1), "concrete", bev=0.012, dirt=False, jit=0.025)
        mk = 0.132
        # sarı TDPM halkası ve beyaz kare çerçeve, beyaz H
        for k in range(48):
            a = k * math.tau / 48
            box((math.cos(a) * 3.9, math.sin(a) * 3.9, mk), (0.32, 0.52, 0.004), "yellow", r=(0, 0, a), bev=0.0, dirt=False)
        for s in (-1, 1):
            box((s * 4.95, 0, mk), (0.2, 9.9, 0.004), "white", bev=0.0, dirt=False)
            box((0, s * 4.95, mk), (9.9, 0.2, 0.004), "white", bev=0.0, dirt=False)
            box((s * 0.85, 0, mk), (0.42, 3.0, 0.004), "white", bev=0.0, dirt=False)
        box((0, 0, mk), (1.3, 0.42, 0.004), "white", bev=0.0, dirt=False)
        for k in range(4):
            cyl((RND.uniform(-2.5, 2.5), RND.uniform(-2.5, 2.5), mk + 0.001), RND.uniform(0.12, 0.3), 0.003, "concrete2", seg=10, smooth=False, dirt=False)
        # kenar ışıkları (yeşil), bağlama halkaları
        for k in range(16):
            t = k / 16
            per = t * 4
            side = int(per)
            f = per - side
            p = [(-5.15 + f * 10.3, -5.15), (5.15, -5.15 + f * 10.3), (5.15 - f * 10.3, 5.15), (-5.15, 5.15 - f * 10.3)][side]
            cyl((p[0], p[1], 0.17), 0.06, 0.14, "dark", "metal", seg=8)
            cyl((p[0], p[1], 0.27), 0.05, 0.08, "lamp_g", "lamp_g", seg=8)
        for x, y in ((-2.2, -2.2), (2.2, -2.2), (-2.2, 2.2), (2.2, 2.2)):
            lathe([(0.05, 0.0), (0.07, 0.0), (0.07, 0.015), (0.05, 0.015)], "steel", c=(x, y, mk), seg=8, mat="metal")
        # rüzgâr tulumu (ön sağ köşe), yakıt mesanesi (arka sol), operasyon kulübesi (arka sağ), yangın arabası
        windsock((-4.9, -4.9, 0.03), h=4.5, rz=0.6)
        with at((-4.3, 4.1, 0.03), rz=0.785):
            for s in (-1, 1):
                box((0, s * 1.15, 0.2), (3.2, 0.25, 0.4), "fill", bev=0.08, seg=2)
                box((s * 1.7, 0, 0.2), (0.25, 2.5, 0.4), "fill", bev=0.08, seg=2)
            box((0, 0, 0.26), (2.6, 1.6, 0.5), "olive2", "cloth", bev=0.2, seg=3)
            for k in range(3):
                box((-0.8 + k * 0.8, 0, 0.51), (0.06, 1.5, 0.03), "olive", bev=0.0)
            cyl_ab((1.3, 0.0, 0.25), (2.0, 0.6, 0.05), 0.04, "black", seg=6)
        with at((4.35, 4.35, 0.03), rz=-0.785):
            box((0, 0, 0.18), (1.9, 1.5, 0.36), "concrete2", bev=0.02)
            box((0, 0, 1.45), (1.8, 1.4, 2.2), "ply", bev=0.02)
            for k in range(int(1.8 / 0.6)):
                box((-0.6 + k * 0.6, -0.71, 1.45), (0.02, 0.01, 2.2), "wood", bev=0.0)
            with at((0, -0.7, 0.36)):
                door(0.3, 0.75, 1.9, col="ply", frame="wood", panels=False)
                window(-0.5, 1.4, 0.5, 0.45, frame="wood", mull=0, sill=False, flush=True)
            corr((-1.05, 0.95, 2.62), (1, 0, 0), (0, -1, -0.12), 2.1, 1.95, "roof", pitch=0.2, depth=0.03, back="dark")
            ac_unit((0.95, 0.2, 0.36), rz=math.pi / 2, col="paint", w=0.6, d=0.4, h=0.5)
            whip((-0.6, 0.4, 2.56), 2.5)
        with at((4.7, -4.6, 0.03), rz=2.2):
            for s in (-1, 1):
                tyre((0, s * 0.32, 0.22), 0.22, 0.1, (math.pi / 2, 0, 0), seg=12)
            cyl((0, 0, 0.6), 0.2, 0.8, "red", seg=14, bev=0.02)
            bar_ab((0, 0, 0.3), (-0.6, 0, 0.9), 0.04, 0.04, "dark", "metal")
            lathe([(0.1, 0.0), (0.16, 0.0), (0.16, 0.08), (0.1, 0.08)], "black", c=(0.25, 0, 0.75), rot=(math.pi / 2, 0, 0), seg=10)
        for x, y in ((-1.5, 3.2), (1.5, 3.2)):
            box((x, y, 0.2), (0.35, 0.15, 0.12), "yellow", bev=0.02)     # takoz
    else:
        # PAG uçak pisti plakaları (2 x 5 m), ızgara desen, gri beton
        for i in range(5):
            for j in range(2):
                x = -S_ / 2 + (i + 0.5) * S_ / 5
                y = -S_ / 2 + (j + 0.5) * S_ / 2
                box((x, y, 0.08), (S_ / 5 - 0.03, S_ / 2 - 0.03, 0.1), "concrete", bev=0.015, dirt=False, jit=0.04)
                for k in range(1, 4):
                    box((x - S_ / 10 + k * S_ / 20, y, 0.131), (0.025, S_ / 2 - 0.2, 0.003), "concrete2", bev=0.0, dirt=False)
                for k in range(1, 10):
                    box((x, y - S_ / 4 + k * S_ / 20, 0.131), (S_ / 5 - 0.2, 0.025, 0.003), "concrete2", bev=0.0, dirt=False)
        mk = 0.134
        for k in range(48):
            a = k * math.tau / 48
            box((math.cos(a) * 3.8, math.sin(a) * 3.8, mk), (0.3, 0.52, 0.004), "white" if k % 6 else "red", r=(0, 0, a), bev=0.0, dirt=False)
        for s in (-1, 1):
            box((s * 0.85, 0, mk), (0.42, 3.0, 0.004), "white", bev=0.0, dirt=False)
        box((0, 0, mk), (1.3, 0.42, 0.004), "white", bev=0.0, dirt=False)
        for (x, y) in ((-5.0, -5.0), (5.0, -5.0), (-5.0, 5.0), (5.0, 5.0)):
            for k in range(4):
                box((x + (k % 2 - 0.5) * 0.4, y + (k // 2 - 0.5) * 0.4, mk), (0.4, 0.4, 0.004), "red" if (k in (0, 3)) else "white", bev=0.0, dirt=False)
        for k in range(12):
            t = k / 12
            per = t * 4
            side = int(per)
            f = per - side
            p = [(-5.2 + f * 10.4, -5.3), (5.3, -5.2 + f * 10.4), (5.2 - f * 10.4, 5.3), (-5.3, 5.2 - f * 10.4)][side]
            cyl((p[0], p[1], 0.12), 0.07, 0.2, "white", seg=8)
            cyl((p[0], p[1], 0.25), 0.06, 0.08, "lamp_b", "lamp_b", seg=8)
        windsock((-4.95, -4.95, 0.03), h=5.0, rz=0.6)
        # balok (tekerlekli kabin): yeşil, merdivenli, sobalı
        with at((4.0, 4.3, 0.03), rz=math.pi / 2 + 0.3):
            for x in (-0.9, 0.9):
                for s in (-1, 1):
                    tyre((x, s * 0.95, 0.4), 0.4, 0.25, (math.pi / 2, 0, 0), seg=14)
            box((0, 0, 0.75), (3.6, 1.6, 0.18), "dark", "metal", bev=0.01)
            box((0, 0, 1.95), (3.4, 2.2, 2.2), "olive", bev=0.03)
            for k in range(6):
                box((-1.5 + k * 0.6, -1.11, 1.95), (0.03, 0.02, 2.1), "olive2", bev=0.0)
            with at((0, -1.1, 0.86)):
                door(1.0, 0.75, 1.8, col="olive", frame="olive2", panels=False)
                window(-0.6, 1.3, 0.6, 0.5, frame="white", mull=1, sill=False, flush=True)
            box((1.0, -1.5, 0.45), (0.8, 0.6, 0.06), "steel", "metal", bev=0.0)
            for k in range(2):
                box((1.0, -1.4, 0.2 + k * 0.22), (0.7, 0.25, 0.03), "steel", "metal", bev=0.0)
            box((0, 0, 3.08), (3.5, 2.3, 0.06), "olive2", "metal", bev=0.01)
            cyl((-1.2, 0.6, 3.5), 0.06, 0.8, "dark", "metal", seg=8)
            bar_ab((-1.7, 0, 0.6), (-2.6, 0, 0.55), 0.08, 0.08, "dark", "metal")
        # yakıt varilleri + el pompası, yangın panosu
        with at((-4.3, 4.3, 0.03), rz=0.785):
            pallet((0, 0, 0), 1.3, 1.2)
            for i, (x, y) in enumerate(((-0.32, -0.3), (0.32, -0.3), (-0.32, 0.3), (0.32, 0.3))):
                drum((x, y, 0.14), col="olive" if i != 2 else "rust")
            cyl((0.32, -0.3, 1.25), 0.03, 0.5, "red", "metal", seg=6)
            box((0.32, -0.3, 1.5), (0.18, 0.08, 0.12), "red", "metal", bev=0.006)
            cyl_ab((0.32, -0.3, 1.45), (1.0, -0.8, 0.05), 0.02, "black", seg=5)
        with at((4.9, -4.2, 0.03), rz=math.pi / 2):
            for x in (-0.6, 0.6):
                box((x, 0, 0.9), (0.08, 0.08, 1.8), "wood", bev=0.005)
            box((0, -0.05, 1.15), (1.3, 0.05, 1.1), "red", bev=0.008)
            for x in (-0.3, 0.1):
                lathe([(0.0, 0.0), (0.12, 0.28)], "red", c=(x, -0.18, 1.3), seg=12, cap1=True)
            box((0.42, -0.11, 1.15), (0.05, 0.03, 0.8), "wood", bev=0.0)
            box((0, 0.35, 0.3), (0.7, 0.6, 0.6), "red", bev=0.02)


# ------------------------------------------------------------ UAZ-452 tipi ambulans (Doğu)
def van_uaz(p, rz=0.0, col="olive"):
    """Yuvarlak hatlı 4x4 minibüs ambulans: kaput yok, sivri ön, yan pencereler, kızıl haç."""
    with at(p, rz=rz):
        z0 = 0.5
        L, W, H = 4.4, 1.94, 1.55
        def rr(w, h, r, n=3):
            pts = []
            for i in range(n + 1):
                a = -math.pi / 2 + (math.pi / 2) * i / n
                pts.append((w / 2 - r + math.cos(a) * r, z0 + r + math.sin(a) * r))
            for i in range(n + 1):
                a = (math.pi / 2) * i / n
                pts.append((w / 2 - r + math.cos(a) * r, z0 + h - r + math.sin(a) * r))
            return pts
        sec = rr(W, H, 0.22)
        prof = [(-x, z) for x, z in reversed(sec)] + sec
        prism_x([(y, z) for y, z in prof], -L / 2, L / 2 - 0.35, col, bev=0.0)
        # yuvarlak burun
        nose = rr(W - 0.1, H - 0.1, 0.3)
        prism_x([(y, z + 0.05) for y, z in [(-x, z) for x, z in reversed(nose)] + nose], L / 2 - 0.35, L / 2, col, bev=0.0)
        box((L / 2 - 0.12, 0, z0 + H * 0.72), (0.12, W * 0.82, 0.48), "glass", "glass", r=(0, -0.3, 0), bev=0.0)
        box((L / 2 + 0.02, 0, z0 + 0.3), (0.1, W * 0.9, 0.18), "dark", bev=0.01)
        for s in (-1, 1):
            cyl((L / 2 + 0.01, s * 0.65, z0 + 0.62), 0.09, 0.04, "lamp", "lamp", rot=(0, math.pi / 2, 0), seg=10)
            for x in (0.95, 0.15, -0.65, -1.45):
                box((x, s * (W / 2 + 0.005), z0 + H * 0.72), (0.62 if x != 0.95 else 0.7, 0.02, 0.42), "glass" if x > 0 else (0.85, 0.85, 0.82), "glass" if x > 0 else "vc", bev=0.0)
            box((1.4, s * (W / 2 + 0.01), z0 + 0.55), (0.7, 0.015, 0.95), col, bev=0.004)
            red_cross((-0.9, s * (W / 2 + 0.012), z0 + 0.65), 0.55, rz=(0 if s < 0 else math.pi), circle=True)
            for x in (1.25, -1.15):
                tyre((x, s * 0.82, 0.38), 0.38, 0.24, (math.pi / 2, 0, 0), seg=14)
        box((-L / 2 - 0.01, 0, z0 + 0.8), (0.03, 1.4, 1.1), col, bev=0.004)
        box((-L / 2 - 0.02, 0, z0 + 1.1), (0.02, 1.0, 0.35), "glass", "glass", bev=0.0)
        red_cross((0.0, 0.0, z0 + H + 0.01), 0.7, rx=-math.pi / 2)
        cyl((1.6, 0, z0 + H + 0.06), 0.08, 0.1, "lamp_b", "lamp_b", seg=8)


def gator(p, rz=0.0, col="paint"):
    """Küçük 6x4 tıbbi destek aracı (M-Gator tipi) üzerinde sedye."""
    with at(p, rz=rz):
        for x in (0.95, -0.15, -0.75):
            for s in (-1, 1):
                tyre((x, s * 0.62, 0.28), 0.28, 0.2, (math.pi / 2, 0, 0), seg=12)
        box((0.1, 0, 0.5), (2.5, 1.2, 0.18), "dark", "metal", bev=0.01)
        prism_x([(-0.6, 0.55), (0.6, 0.55), (0.55, 0.9), (-0.55, 0.9)], 0.75, 1.4, col, bev=0.02)
        box((0.35, 0, 0.75), (0.5, 1.0, 0.45), col, bev=0.02)
        box((0.45, 0, 1.0), (0.3, 0.9, 0.1), "black", bev=0.01)
        for s in (-1, 1):
            cyl_ab((0.6, s * 0.55, 0.6), (0.4, s * 0.55, 1.6), 0.025, "dark", "metal", seg=6)
        cyl_ab((0.4, -0.55, 1.6), (0.4, 0.55, 1.6), 0.025, "dark", "metal", seg=6)
        box((0.95, 0.0, 1.0), (0.04, 0.35, 0.2), "dark", bev=0.0)
        box((-0.55, 0, 0.62), (1.2, 1.15, 0.06), col, bev=0.01)
        stretcher((-0.55, 0, 0.66), rz=0.0, legs=False, col="olive")


# ============================================================ SAHRA HASTANESİ (7 x 6)
def hospital():
    global BODY_H
    usa = SIDE == "usa"
    BODY_H = 3.0
    box2((-3.45, -2.95, 0), (3.45, 2.95, 0.03), "gravel", bev=0.0, dirt=False, jit=0.02)
    if usa:
        # DRASH tipi kemerli tıbbi çadır + giriş çadırı, ECU, jeneratör
        box2((-3.3, -0.55, 0.03), (2.6, 2.85, 0.08), "ply", bev=0.005)
        arch_tent((-0.35, 1.15, 0.08), 5.8, 3.4, 2.75, col="canvas", rz=0.0, door_ends=(False, True), wins=0)
        # ön giriş çıkıntısı (vestibül)
        with at((-0.6, -0.55, 0.08), rz=-math.pi / 2):
            arch_tent((0.6, 0, 0), 1.3, 1.7, 2.05, col="canvas", rz=0.0, door_ends=(False, True), ribs=False, n=8)
        # çatıda ve yan duvarda kızıl haç panoları
        with at((-0.35, 1.15, 0.08)):
            red_cross((-1.5, 0.0, 2.68), 1.3, rx=-math.pi / 2, th=0.02)
            red_cross((1.5, 0.0, 2.68), 1.3, rx=-math.pi / 2, th=0.02)
        red_cross((2.6 + 0.05, 1.15, 1.75), 0.9, rz=math.pi / 2)
        # ECU (çevresel kontrol ünitesi) + esnek kanallar
        ac_unit((3.0, 2.3, 0.03), rz=math.pi / 2, col="paint", w=1.0, d=0.8, h=1.0)
        for dz in (0.75, 0.45):
            pts = [Vector((3.0, 2.3 - 0.0, dz)), Vector((2.8, 2.0, dz + 0.5)), Vector((2.7, 1.8, 1.4 - dz * 0.2))]
            for a, b in zip(pts, pts[1:]):
                cyl_ab(a, b, 0.14, "canvas2", seg=10)
        generator((3.05, -0.4, 0.03), rz=math.pi / 2, col="olive", trailer=False, big=0.5)
        # ambulans körfezi: sedyeler, sedye sehpaları, oksijen tüpleri, tıbbi sandıklar
        stretcher((-2.4, -1.85, 0.03), rz=0.0, legs=True, col="olive")
        stretcher((0.9, -1.95, 0.03), rz=0.1, legs=True, col="olive")
        stretcher((-2.6, -2.55, 0.03), rz=-0.05, legs=False, col="canvas")
        with at((2.3, -2.4, 0.03)):
            box((0, 0, 0.6), (0.6, 0.3, 0.04), "steel", "metal", bev=0.0)
            for i in range(4):
                gas_bottle((-0.22 + i * 0.15, 0.0, 0.03), col=(0.2, 0.5, 0.25), h=1.1, r=0.07)
        for k, (x, y) in enumerate(((-0.8, -2.5), (-0.3, -2.55))):
            crate((x, y, 0.03), (0.5, 0.4, 0.4), "wall2", rz=0.05 * k, bands=False)
            red_cross((x, y - 0.21, 0.27), 0.22)
        flagpole((-3.2, -2.6, 0.03), h=4.0)
        # sandbag'li koruma: tek sıra arka
        sandbag_wall((-3.3, 2.95, 0.03), (2.6, 2.95, 0.03), rows=3, thick=1)
    else:
        BODY_H = 3.2
        ridge_tent((0.0, 1.0, 0.03), 6.2, 3.6, 1.65, 3.0, col="canvas", rz=0.0, wins=3)
        # kızıl haç: beyaz daire üstünde, çatıda ve yan duvarda
        with at((0.0, 1.0, 0.03)):
            red_cross((-1.4, -1.8 * 0.97 - 0.02, 1.0), 0.8, circle=True)
            with at((1.6, -0.97, 2.33), rx=-(math.pi / 2 - math.atan2(3.0 - 1.65, 1.92))):
                red_cross((0, 0.0, 0), 1.0, circle=True, th=0.02)
        van_uaz((0.1, -2.05, 0.03), rz=0.0, col="olive")
        stretcher((3.0, -0.5, 0.03), rz=math.pi / 2, legs=False, col="canvas")
        for i in range(2):
            ru_crate((-3.0 + i * 0.0, -0.35 - i * 0.5, 0.03), s=(0.7, 0.4, 0.35))
        red_cross((-3.0, -0.57, 0.22), 0.2)
        gas_bottle((3.25, 0.6, 0.03), col="blue", h=1.2, r=0.1)
        gas_bottle((3.25, 0.85, 0.03), col="blue", h=1.2, r=0.1)
        drum((3.2, 2.6, 0.03), col="olive")
        flagpole((-3.25, 2.7, 0.03), h=4.0)


# ------------------------------------------------------------ ana akış
BUILDERS = {"factory": factory, "hq": hq, "barracks": barracks, "fob": fob, "helipad": helipad, "hospital": hospital}



def main():
    argv = sys.argv[1:]
    only = None
    prev = None
    ao = True
    for i, a in enumerate(argv):
        if a == "--only":
            only = set(argv[i + 1].split(","))
        elif a == "--preview":
            prev = argv[i + 1]
        elif a == "--noao":
            ao = False
    for key, fn in BUILDERS.items():
        for side in ("usa", "rus"):
            name = "struct_%s_%s" % (key, side)
            if only and name not in only and key not in only:
                continue
            begin(side, seed=sum(map(ord, name)))
            fn()
            ob = finish(name, ao=ao)
            if prev:
                os.makedirs(prev, exist_ok=True)
                sc = {"hq": 24, "fob": 15, "barracks": 13, "factory": 17, "helipad": 16, "hospital": 11}.get(key, 16)
                preview(ob, os.path.join(prev, name), scale=sc, focus=(0, 0, 1.2))
    print("STRUCT DONE")


if __name__ == "__main__":
    main()
