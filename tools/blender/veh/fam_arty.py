# Çekili topçu (roadmap 10/38/54): obüs (açık ayaklı ya da D-30 tipi üç ayaklı kuyruk), sahra topu (kutu, yay ya da
# açık kuyruk), otomatik havan. Gerçek yerleşim: namlunun ~%75-80'i muylu ekseninin önünde, kama arkada; beşik ve
# namlu üstünde geri tepme / toparlanma silindirleri; dengeleyiciler; kalkan (yarığı namluyla yükselen kayar levha
# kapatır); yükseliş ve yön volanları, panoramik nişangâh; kuyruk ucunda toprağa gömülü pençe, çekme halkası, el
# kolları; atış tablası; çift bölmeli ya da çok delikli namlu freni.
# Düğümler: body (alt kundak, aks, kuyruk, tekerler) · turret (üst kundak; yön) · barrel (beşik + namlu; yükseliş).
# Katalog 'v': gl namlu boyu · bf namlunun muylu arkasındaki payı · tl kuyruk ucu uzaklığı · tw teker izi yarısı ·
# wr/ww teker yarıçapı/eni · wn yan başına teker · cal kalibre (mm) · bz muylu yüksekliği · brake db|multi|none ·
# shield kalkan eni (0 yok) · spread kuyruk ucu yarı açıklığı · tri üç ayak (D-30) · base atış tablası ·
# outrig ön destek ayakları (M777) · trail split|box|bow (sahra topu) · roller kuyruk makarası (M102) ·
# jacket soğutma ceketi (otomatik havan)
import math
from vlib import *
from mathutils import Vector

UP = Vector((0, 0, 1))


def _beam(p0, p1, w0, h0, w1, h1, m="paint"):
    """p0→p1 arası konik kutu kesitli kiriş (kuyruk ayağı)."""
    p0, p1 = Vector(p0), Vector(p1)
    d = (p1 - p0).normalized()
    x = d.cross(UP)
    if x.length < 1e-4:
        x = Vector((1, 0, 0))
    x.normalize()
    z = x.cross(d)
    pts = []
    for p, w, h in ((p0, w0, h0), (p1, w1, h1)):
        for sx in (-1, 1):
            for sz in (-1, 1):
                pts.append(tuple(p + x * (sx * w / 2) + z * (sz * h / 2)))
    return hull_pts(pts, m, bev=0.01)


def _spade(p, dh, w=0.62, h=0.62):
    """Kuyruk ucunda toprağa gömülü pençe; dh kuyruk yönü (topa göre dışa)."""
    f = F(tuple(p), (0, 0, math.atan2(-dh.x, dh.y)))
    f.box((0, 0.12, 0.04), (w, 0.06, h), "metal", rot=(0.4, 0, 0), bev=0.006)
    f.box((0, 0.0, 0.2), (0.05, 0.3, 0.2), "metal")                                      # takviye kulağı
    for s in (-1, 1):
        f.box((s * w * 0.32, 0.02, 0.18), (0.04, 0.24, 0.18), "metal")


def _trail(p0, p1, w0, h0, w1, h1, lunette=False, toolbox=False, staff=False, spade=True):
    P0, P1 = Vector(p0), Vector(p1)
    _beam(P0, P1, w0, h0, w1, h1)
    d = P1 - P0
    dh = Vector((d.x, d.y, 0)).normalized()
    x = dh.cross(UP).normalized()
    bar(tuple(P0 + UP * (h0 / 2)), tuple(P1 + UP * (h1 / 2)), min(w0, w1) * 0.5, 0.012, "trim")      # sırt levhası
    for t in (0.3, 0.6):
        q = P0 + d * t
        for s in (-1, 1):
            cyl(tuple(q + x * s * ((w0 + w1) / 4 + 0.004)), 0.04, 0.012, "dark", "X", seg=10)       # hafifletme deliği
    if spade:
        _spade(P1 + dh * 0.04, dh)
    grab_handle(tuple(P1 - dh * 0.42 + UP * (h1 / 2 + 0.005)), along=tuple(dh), normal=(0, 0, 1), L=0.3, h=0.08, r=0.015)
    for s in (-1, 1):
        q = P1 - dh * 0.75 + x * s * (w1 / 2)
        rod(tuple(q), tuple(q + x * s * 0.22), 0.018, "metal")                                  # kaldırma kolları
    if lunette:
        ring(tuple(P1 + dh * 0.14 + UP * 0.1), 0.1, 0.026, "metal", "Z", seg=12, tseg=5)          # çekme halkası
        box(tuple(P1 + dh * 0.02 + UP * 0.1), (0.08, 0.12, 0.06), "metal", bev=0.0)
    if toolbox:
        m = P0 + d * 0.42
        f = F(tuple(m + UP * ((h0 + h1) / 4)), (0, 0, math.atan2(-dh.x, dh.y)))
        f.box((0, 0, 0.1), (0.32, 0.8, 0.2), "paint", bev=0.008)                                # alet sandığı
        f.box((0, 0, 0.205), (0.28, 0.76, 0.01), "trim")
        for t in (-0.25, 0.25):
            f.box((0.165, t, 0.13), (0.01, 0.06, 0.04), "dark")
    if staff:
        q0 = P0 + d * 0.18 + x * (w0 * 0.22) + UP * ((h0 + h1) / 4 + 0.07)
        q1 = P0 + d * 0.86 + x * (w1 * 0.22) + UP * (h1 / 2 + 0.06)
        rod(tuple(q0), tuple(q1), 0.022, "wood", seg=8)                                         # sürme / temizleme çubuğu
        for t in (0.2, 0.8):
            box(tuple(q0 + (q1 - q0) * t - UP * 0.035), (0.06, 0.04, 0.06), "dark", bev=0.0)


def _brake(y, z, rm, kind):
    """Namlu ağzı freni y'den ileri; boyunu döndürür."""
    if kind == "none":
        cyl((0, y + 0.002, z), rm * 0.62, 0.01, "dark", "Y", seg=12)
        return 0.0
    if kind == "multi":
        # çok delikli ("biber kutusu") fren
        Lb = rm * 6.5
        cyl((0, y + Lb / 2, z), rm * 1.4, Lb, "trim", "Y", seg=16, r2=rm * 1.3)
        for k in range(6):
            for a in range(10):
                ang = (a + 0.5 * (k % 2)) * math.tau / 10
                cyl((math.cos(ang) * rm * 1.39, y + Lb * (0.13 + k * 0.148), z + math.sin(ang) * rm * 1.39), rm * 0.16, 0.03, "dark",
                    seg=6, rot=(0, math.pi / 2 - ang, 0))
        cyl((0, y + Lb + 0.002, z), rm * 0.66, 0.01, "dark", "Y", seg=12)
        return Lb
    # çift bölmeli: üç perde, üst/alt kayış, yanlarda açık pencereler
    Lb = rm * 5.0
    cyl((0, y + Lb / 2, z), rm * 1.0, Lb, "dark", "Y", seg=14)
    for t in (0.05, 0.5, 0.95):
        box((0, y + Lb * t, z), (rm * 3.3, Lb * 0.1, rm * 2.5), "trim", bev=0.01)
    for s in (-1, 1):
        box((0, y + Lb / 2, z + s * rm * 1.2), (rm * 2.7, Lb, rm * 0.16), "trim", bev=0.006)
    cyl((0, y + Lb + 0.002, z), rm * 0.66, 0.01, "dark", "Y", seg=12)
    return Lb


def _barrel_group(L, bf, bz, rb, rm, brake, recoil, shield_y=None, gap=0.0, jacket=False, lug=False):
    """Beşik + namlu (barrel düğümü; muylu ekseni y=0). Dönen: (ağız ucu y, kama arkası y)."""
    yb = -bf * L
    yf = yb + L
    # kama bloğu, kama kolu, ateşleme ipi kolu
    box((0, yb - 0.21, bz), (rb * 2.7, 0.42, rb * 2.6), "paint", bev=0.02)
    box((0, yb - 0.43, bz), (rb * 2.0, 0.04, rb * 2.0), "trim", bev=0.006)
    cyl((rb * 0.55, yb - 0.46, bz + rb * 0.35), 0.04, 0.05, "metal", "Y", seg=8)
    rod((rb * 1.3, yb - 0.33, bz + rb * 0.2), (rb * 1.3 + 0.2, yb - 0.5, bz + rb * 0.55), 0.02, "metal")
    cyl((rb * 1.3 + 0.2, yb - 0.5, bz + rb * 0.55), 0.03, 0.09, "dark", seg=8)
    rod((-rb * 1.35, yb - 0.3, bz - rb * 0.6), (-rb * 1.35 - 0.12, yb - 0.45, bz - rb * 0.9), 0.012, "metal")
    if jacket:
        # otomatik havan: kanatçıklı soğutma ceketi + yandan 4'lü tarak şarjör
        lj = L * 0.55
        cyl((0, yb + lj / 2, bz), rb * 1.05, lj, "paint", "Y", seg=16)
        for k in range(7):
            cyl((0, yb + 0.1 + k * (lj - 0.2) / 6, bz), rb * 1.18, 0.03, "trim", "Y", seg=16)
        cyl((0, yb + lj + (L - lj) / 2, bz), rm, L - lj, "paint", "Y", seg=14, r2=rm * 1.05)
        box((-rb * 1.7, yb + 0.15, bz + 0.03), (0.2, 0.5, 0.14), "dark", bev=0.006)
        for k in range(4):
            cyl((-rb * 1.7 - 0.06 + k * 0.04, yb + 0.15, bz + 0.13), 0.022, 0.42, "metal", "Y", seg=8)
    else:
        l1 = min(L * 0.28, 1.6)
        cyl((0, yb + l1 / 2, bz), rb * 0.9, l1, "paint", "Y", seg=18, r2=rb)                         # hazne bölümü
        cyl((0, yb + l1 + (L - l1) / 2, bz), rm, L - l1, "paint", "Y", seg=18, r2=rb * 0.8)         # konik namlu
        cyl((0, yb + l1, bz), rb * 0.93, 0.05, "trim", "Y", seg=18)                                   # omuz bileziği
        cyl((0, yf - 0.1, bz), rm * 1.1, 0.2, "paint", "Y", seg=16, r2=rm * 1.02)                      # ağız şişkinliği
    # beşik, kızak yanakları, muylu pimleri
    cl = min(L * 0.45, 3.0)
    yc0 = yb + 0.02
    box((0, yc0 + cl / 2, bz - rb - 0.06), (rb * 2.0 + 0.06, cl, 0.12), "paint", bev=0.008)
    for s in (-1, 1):
        box((s * (rb + 0.05), yc0 + cl / 2, bz - rb * 0.35), (0.05, cl, rb * 1.3), "paint", bev=0.006)
        cyl((s * (rb + 0.14), 0.0, bz), 0.085, 0.16, "metal", "X", seg=12)
    # geri tepme freni / toparlayıcı silindirleri (namlu üstünde), piston kolları kama boyunduruğuna
    zc = bz + rb + 0.1
    for k in range(recoil):
        x = (k - (recoil - 1) / 2) * rb * 1.2
        cyl((x, yc0 + cl / 2, zc), 0.09, cl * 0.96, "paint", "Y", seg=14)
        cyl((x, yc0 + cl * 0.98, zc), 0.075, 0.05, "trim", "Y", seg=12)
        rod((x, yb - 0.1, zc), (x, yc0 + 0.05, zc), 0.035, "metal", seg=8)
    box((0, yb - 0.12, zc - 0.03), (rb * 1.2 * max(recoil - 1, 0) + 0.24, 0.12, 0.16), "paint", bev=0.006)
    box((0, yc0 + cl, bz + 0.04), (rb * 2.2, 0.1, rb * 2.2 + 0.24), "paint", bev=0.008)            # beşik ön kelepçesi
    Lb = _brake(yf, bz, rm, brake)
    if lug:
        # D-30: namlu ağzından çekilir — fren altında çekme kulağı
        box((0, yf + Lb * 0.5, bz - rm * 1.3 - 0.05), (0.06, 0.18, 0.1), "metal")
        ring((0, yf + Lb * 0.5, bz - rm * 1.3 - 0.14), 0.07, 0.02, "metal", "X", seg=10)
    if shield_y is not None:
        box((0, shield_y + 0.05, bz + 0.2), (gap * 2 + 0.16, 0.03, 0.6), "paint", bev=0.004)          # kayar kalkan
    return yf + Lb, yb - 0.45


def _shield(w, y, z0, z1, bz, gap):
    f = F((0, y, (z0 + z1) / 2), (0.12, 0, 0))
    h = z1 - z0
    zc = bz - (z0 + z1) / 2
    half = w / 2
    pw = half - gap
    nrm = f.R @ Vector((0, 1, 0))
    for s in (-1, 1):
        f.box((s * (gap + pw / 2), 0, 0), (pw, 0.022, h), "paint", bev=0.004)                       # yan levhalar
        f.box((s * (half + 0.17), -0.12, -0.04), (0.42, 0.022, h * 0.85), "paint", rot=(0, 0, -s * 0.6), bev=0.004)  # kanatlar
        f.box((s * (gap + pw * 0.55), 0.016, h * 0.22), (0.16, 0.012, 0.07), "dark")                 # görüş penceresi kapağı
        for k in range(4):
            bolt(f.P((s * (gap + 0.06 + k * (pw - 0.12) / 3), 0.014, h / 2 - 0.05)), normal=nrm)
        f.rod((s * (gap + pw * 0.6), -0.02, -h * 0.3), (s * (gap + pw * 0.25), -0.45, -h * 0.45), 0.02, "metal")   # destek
    zl = zc - gap
    f.box((0, 0, (-h / 2 + zl) / 2), (gap * 2 + 0.01, 0.022, zl + h / 2), "paint", bev=0.004)        # yarık altı
    f.box((0, 0.012, h / 2 - 0.012), (w, 0.03, 0.03), "trim", bev=0.0)                              # üst kenar bandı


def _top_carriage(zt0, bz, rb, heavy, sw, sy, gap, eq=True):
    xc = rb + 0.24
    box((0, -0.1, zt0 + 0.06), (2 * xc + 0.2, 1.3, 0.12), "paint", bev=0.01)                       # döner tabla
    cyl((0, -0.1, zt0 - 0.02), 0.45, 0.06, "metal", seg=20)                                         # yön bileziği
    for s in (-1, 1):
        x0, x1 = sorted((s * xc, s * (xc + 0.07)))
        poly_extrude_x([(-0.7, zt0 + 0.1), (0.62, zt0 + 0.1), (0.24, bz + 0.13), (-0.3, bz + 0.13)], x0, x1, "paint", bev=0.01)
        cyl((s * (xc + 0.09), 0.0, bz), 0.14, 0.05, "trim", "X", seg=14)                          # muylu yatağı
        for k in range(6):
            a = k * math.tau / 6
            cyl((s * (xc + 0.12), math.cos(a) * 0.1, bz + math.sin(a) * 0.1), 0.014, 0.02, "metal", "X", seg=6)
        if eq:
            # dengeleyici (pnömatik silindir): alt kundaktan beşiğe
            rod((s * (xc + 0.16), -0.45, zt0 + 0.2), (s * (xc + 0.16), 0.55, bz - 0.12), 0.07 if heavy else 0.055, "paint", seg=12)
            cyl((s * (xc + 0.16), -0.45, zt0 + 0.2), 0.05, 0.12, "metal", "X", seg=10)
    # yükseliş + yön volanları, panoramik nişangâh (nişancı solda)
    hx = -(xc + 0.3)
    for yy, zz, R in ((-0.15, bz - 0.22, 0.16), (-0.55, zt0 + 0.42, 0.13)):
        ring((hx, yy, zz), R, 0.014, "dark", "X", seg=16, tseg=4)
        for k in range(3):
            a = k * math.tau / 3
            rod((hx, yy, zz), (hx, yy + math.cos(a) * R, zz + math.sin(a) * R), 0.008, "dark")
        rod((hx, yy, zz), (-(xc + 0.07), yy, zz), 0.02, "metal")
        cyl((hx - 0.05, yy + R * 0.7, zz + R * 0.7), 0.012, 0.1, "dark", "X", seg=6)
    sx = -(xc + 0.16)
    box((sx, 0.08, bz + 0.18), (0.11, 0.14, 0.2), "dark", bev=0.006)
    cyl((sx, 0.08, bz + 0.33), 0.05, 0.1, "dark", seg=10)
    box((sx, 0.13, bz + 0.34), (0.06, 0.02, 0.05), "glass", bev=0.0)
    cyl((sx - 0.08, 0.02, bz + 0.2), 0.022, 0.1, "dark", "X", seg=8)
    if sw > 0:
        _shield(sw, sy, zt0 + 0.02, bz + 0.62, bz, gap)


def _bottom(tw, wr, ww, wn, za, raised=0.0, fenders=False):
    box((0, 0.0, za), (2 * tw - ww - 0.1, 0.22, 0.2), "paint", bev=0.008)                          # aks kirişi
    box((0, -0.12, za + 0.1), (1.0, 1.25, 0.34), "paint", bev=0.012)                              # alt kundak gövdesi
    box((0, -0.12, za + 0.28), (0.9, 1.1, 0.03), "trim", bev=0.0)
    ys = [0.0] if wn == 1 else [wr * 1.12, -wr * 1.12]
    n = 0
    for s in (-1, 1):
        box((s * (tw - ww / 2 - 0.18), 0.0, za + 0.05), (0.2, 0.42, 0.24), "paint", bev=0.008)    # aks başı / süspansiyon
        for y in ys:
            tyre(n, s * tw, y, wr + raised, wr, ww, s)
            n += 1
        if wn == 2:
            box((s * (tw - ww / 2 - 0.07), 0.0, wr + raised), (0.08, wr * 2.4, 0.16), "paint", bev=0.006)   # boji kolu
        if fenders:
            R = wr + 0.1
            for y in ys:
                for a in (-0.75, -0.25, 0.25, 0.75):
                    box((s * tw, y + math.sin(a) * R, wr + raised + math.cos(a) * R), (ww + 0.08, R * 0.52, 0.025), "paint",
                        rot=(-a, 0, 0), bev=0.0)
    return n


def howitzer(v):
    cal = float(v.get("cal", 155)) / 1000.0
    rb, rm = 0.03 + cal * 1.1, 0.015 + cal * 0.62
    L = float(v.get("gl", 5.2))
    bf = float(v.get("bf", 0.22))
    tl = float(v.get("tl", 4.15))
    tw = float(v.get("tw", 1.05))
    wr = float(v.get("wr", 0.5))
    ww = float(v.get("ww", 0.3))
    wn = int(v.get("wn", 1))
    bz = float(v.get("bz", 1.45))
    sw = float(v.get("shield", 0.0))
    tri = bool(v.get("tri", False))
    heavy = cal > 0.14
    raised = 0.1 if tri else 0.0
    za = wr + raised
    _bottom(tw, wr, ww, wn, za, raised, fenders=heavy and sw > 0)
    if tri:
        # D-30: üç ayak 120° açık, orta kriko tablası; tekerler yerden kalkık
        for k, a in enumerate((math.pi, math.pi / 3, -math.pi / 3)):
            d = Vector((math.sin(a), math.cos(a), 0))
            _trail(d * 0.4 + Vector((0, 0, za - 0.05)), d * tl + Vector((0, 0, 0.16)), 0.24, 0.26, 0.18, 0.16,
                   lunette=(k == 0), toolbox=(k == 1), staff=(k == 2))
        cyl((0, 0.0, 0.05), 0.55, 0.1, "metal", seg=24)
        cyl((0, 0.0, za * 0.5), 0.12, za, "metal", seg=14, r2=0.2)
    else:
        spread = float(v.get("spread", min(tw * 0.85, 1.15)))
        for s in (-1, 1):
            p0 = (s * 0.42, -0.55, za + 0.02)
            _trail(p0, (s * spread, -tl, 0.18), 0.26 if heavy else 0.22, 0.34 if heavy else 0.28, 0.2, 0.18,
                   lunette=(s < 0), toolbox=(s > 0), staff=(s < 0))
            cyl(p0, 0.1, 0.38, "metal", seg=12)                                                  # kuyruk menteşesi
    if v.get("base"):
        cyl((0, 0.05, 0.04), 0.55, 0.08, "metal", seg=24)                                        # atış tablası
        rod((0, 0.05, 0.08), (0, 0.05, za - 0.05), 0.07, "metal", seg=10)
    if v.get("outrig"):
        for s in (-1, 1):
            _beam((s * 0.45, 0.45, za + 0.05), (s * 1.2, 1.55, 0.12), 0.14, 0.16, 0.1, 0.1)       # ön destek ayağı
            cyl((s * 1.2, 1.6, 0.03), 0.17, 0.06, "metal", seg=14)
    node("turret")
    zt0 = za + 0.27
    gap = rb * 1.25 + 0.06
    sy = 0.66
    _top_carriage(zt0, bz, rb, heavy, sw, sy, gap)
    node("barrel")
    front, back = _barrel_group(L, bf, bz, rb, rm, v.get("brake", "db"), 2 if heavy else 1, sy if sw > 0 else None, gap, lug=tri)
    pv = wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.0, zt0), "barrel": (0, 0.0, bz)})
    return pv, {"muzzle": (0, front, bz), "breech": (0, back, bz), "radius": 2.0}


def fieldgun(v):
    cal = float(v.get("cal", 105)) / 1000.0
    rb, rm = 0.03 + cal * 1.1, 0.015 + cal * 0.62
    L = float(v.get("gl", 3.2))
    bf = float(v.get("bf", 0.22))
    tl = float(v.get("tl", 3.0))
    tw = float(v.get("tw", 0.8))
    wr = float(v.get("wr", 0.4))
    ww = float(v.get("ww", 0.24))
    bz = float(v.get("bz", 0.98))
    sw = float(v.get("shield", 0.0))
    trail = v.get("trail", "box")
    za = wr
    _bottom(tw, wr, ww, 1, za)
    if trail == "split":
        spread = float(v.get("spread", tw * 0.9))
        for s in (-1, 1):
            p0 = (s * 0.3, -0.45, za)
            _trail(p0, (s * spread, -tl, 0.16), 0.18, 0.22, 0.14, 0.14, lunette=(s < 0), staff=(s < 0))
            cyl(p0, 0.08, 0.28, "metal", seg=10)
    elif trail == "bow":
        # M119: yay biçimli boru kuyruk — kundaktan yükselir, uca iner
        pm = (0, -tl * 0.42, za + 0.32)
        _beam((0, -0.35, za + 0.05), pm, 0.24, 0.2, 0.22, 0.18)
        _trail(pm, (0, -tl, 0.18), 0.22, 0.18, 0.18, 0.14, lunette=True, staff=True)
    else:
        _trail((0, -0.4, za), (0, -tl, 0.2), 0.3, 0.26, 0.2, 0.16, lunette=True, toolbox=True)
    if v.get("roller"):
        cyl((0, -tl + 0.05, 0.17), 0.17, 0.2, "rubber", "X", seg=14)                               # 360° dönüş makarası
        box((0, -tl + 0.05, 0.3), (0.26, 0.3, 0.08), "metal")
    if v.get("base"):
        cyl((0, 0.0, 0.04), 0.5, 0.08, "metal", seg=24)
        rod((0, 0.0, 0.08), (0, 0.0, za - 0.05), 0.06, "metal", seg=10)
    node("turret")
    zt0 = za + 0.18
    gap = rb * 1.25 + 0.05
    sy = 0.5
    _top_carriage(zt0, bz, rb, False, sw, sy, gap, eq=sw > 0)
    node("barrel")
    front, back = _barrel_group(L, bf, bz, rb, rm, v.get("brake", "db"), 1, sy if sw > 0 else None, gap, jacket=bool(v.get("jacket", False)))
    pv = wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.0, zt0), "barrel": (0, 0.0, bz)})
    return pv, {"muzzle": (0, front, bz), "breech": (0, back, bz), "radius": 1.6}


FAMILIES = {"howitzer": howitzer, "fieldgun": fieldgun}
