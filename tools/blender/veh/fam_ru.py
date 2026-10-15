# Doğu bloku (Rusya) aileleri. Ortak parçalar vlib'den; tasarım dili: alçak kubbe/köşeli taret, reaktif zırh,
# büyük yol tekerleri + üst makaralar, tekne burunlu tekerlekli araçlar, kaputlu kamyon kabini.
import math
from vlib import *

# ------------------------------------------------------------ yardımcılar
def ru_tracks(L, xc, tw, n, r, zt, rollers=3, front_idler=True, holes=8):
    y0 = L / 2 - 0.55
    y1 = -L / 2 + 0.75
    wy = [y0 - i * (y0 - y1) / (n - 1) for i in range(n)]
    ry = [y0 - (i + 0.5) * (y0 - y1) / rollers for i in range(rollers)] if rollers else ()
    running_gear(xc, tw, wy, r, L / 2 - 0.15, -L / 2 + 0.2, 0.28, 0.31, z_top_run=2 * r + 0.14, rollers_y=ry, holes=holes)
    return wy

def kontakt_rows(x0, x1, y, z, rows=2, pitch=-0.95, n=6):
    """Ön zırh üzerinde reaktif zırh tuğla sıraları (glacis): cıvatalı kapaklı tuğlalar."""
    for rr in range(rows):
        for i in range(n):
            x = x0 + (x1 - x0) * (i + 0.5) / n
            era_brick((x, y - rr * 0.32, z + rr * 0.12), ((x1 - x0) / n * 0.9, 0.3, 0.1), rot=(pitch, 0, 0), nrm=(0, 0, 1))

def fuel_drums(y, z, W):
    """Arka yedek yakıt varilleri: nervürlü varil + kayış + taşıyıcı konsol."""
    for s in (-1, 1):
        x = s * W * 0.25
        cyl((x, y, z), 0.3, 0.9, "paint", "X", seg=16)
        for t in (-0.22, 0.22):
            cyl((x + t, y, z), 0.31, 0.03, "paint", "X", seg=16)
        for t in (-0.3, 0.3):
            ring((x + t, y, z), 0.315, 0.012, "dark", axis="X", seg=14, tseg=3)
            box((x + t, y + 0.12, z - 0.33), (0.05, 0.35, 0.06), "metal", bev=0.0)
        cyl((x + s * 0.46, y, z + 0.12), 0.04, 0.03, "metal", "X", seg=8)

def cage(y0, y1, z, w, h):
    """Kafes zırh (taret üstü) — dikmeler + ızgara + seyrek tel örgü."""
    for s in (-1, 1):
        for y in (y0, (y0 + y1) / 2, y1):
            rod((s * w * 0.85, y, z - 0.25), (s * w, y, z + h), 0.022, "metal", 6)
    for k in range(6):
        x = -w + k * (2 * w) / 5
        rod((x, y0, z + h), (x, y1, z + h), 0.016, "metal", 5)
    for k in range(5):
        y = y0 + k * (y1 - y0) / 4
        rod((-w, y, z + h), (w, y, z + h), 0.016, "metal", 5)
    for k in range(11):
        x = -w + k * (2 * w) / 10
        rod((x, y0, z + h + 0.01), (x, y1, z + h + 0.01), 0.005, "dark", 3)

def hood_cab(y, zb, w=2.4):
    """Kaputlu kamyon kabini (Ural tipi): kaput + menteşe, ızgara, çamurluklar, çerçeveli ön cam, kapılar, aynalar."""
    slab(y + 2.2, y + 2.1, y + 0.9, y + 0.9, zb, zb + 0.95, w / 2 - 0.25, w / 2 - 0.35, "paint", wf=w / 2 - 0.45)   # kaput
    seam((0, y + 2.1, zb + 0.955), (0, y + 0.95, zb + 0.955))
    for s in (-1, 1):
        for k in range(4):
            box((s * (w / 2 - 0.32), y + 1.3 + k * 0.15, zb + 0.65), (0.012, 0.1, 0.3), "dark", bev=0.0)      # kaput yan panjurları
    # ızgara: koyu taban + dikey çubuklar + çerçeve
    box((0, y + 2.25, zb + 0.45), (w * 0.6, 0.12, 0.62), "dark", bev=0.0)
    for k in range(9):
        box(((k - 4) * w * 0.065, y + 2.315, zb + 0.45), (0.025, 0.02, 0.56), "paint", bev=0.0)
    box((0, y + 2.3, zb + 0.78), (w * 0.64, 0.06, 0.06), "paint", bev=0.0)
    box((0, y + 2.35, zb + 0.08), (w * 0.95, 0.15, 0.18), "paint", bev=0.008)                                     # tampon
    for s in (-1, 1):
        box((s * (w / 2 - 0.15), y + 1.6, zb + 0.55), (0.4, 1.3, 0.15), "paint", rot=(0.25, 0, 0), bev=0.008)        # çamurluk
        light(s * (w / 2 - 0.3), y + 2.25, zb + 0.75)
        shackle(s * 0.6, y + 2.4, zb + 0.08, 1)
    slab(y + 0.95, y + 0.75, y - 0.6, y - 0.6, zb, zb + 1.7, w / 2, w / 2 - 0.1, "paint", bev=0.012)
    for s in (-1, 1):
        box((s * w * 0.21, y + 0.85, zb + 1.3), (w * 0.4, 0.04, 0.5), "glass", rot=(-0.2, 0, 0), bev=0.0)
        box((s * w * 0.21, y + 0.88, zb + 1.12), (0.02, 0.02, 0.3), "dark", rot=(-0.2, 0, 0.5 * s), bev=0.0)          # silecek
        box((s * (w / 2 - 0.02), y + 0.15, zb + 1.3), (0.03, 0.8, 0.45), "glass", bev=0.0)
        seam((s * (w / 2 - 0.03), y + 0.62, zb + 0.15), (s * (w / 2 - 0.03), y + 0.62, zb + 1.55), (s, 0, 0))
        seam((s * (w / 2 - 0.03), y - 0.45, zb + 0.15), (s * (w / 2 - 0.03), y - 0.45, zb + 1.55), (s, 0, 0))
        box((s * (w / 2), y - 0.25, zb + 0.95), (0.03, 0.12, 0.03), "metal", bev=0.0)
        box((s * (w / 2 - 0.1), y + 0.1, zb - 0.15), (0.25, 0.5, 0.04), "metal", bev=0.0)                              # basamak
        mirror(s * (w / 2 - 0.02), y + 0.75, zb + 1.2, s)
    box((0, y + 0.88, zb + 1.3), (0.06, 0.06, 0.52), "paint", rot=(-0.2, 0, 0), bev=0.0)
    box((0, y + 0.88, zb + 1.58), (w * 0.86, 0.06, 0.05), "paint", rot=(-0.2, 0, 0), bev=0.0)
    for k in (-1, 0, 1):
        box((k * 0.2, y + 0.7, zb + 1.73), (0.07, 0.05, 0.05), "lens", bev=0.0)

def _truck_chassis(ax, zb, L, w=1.0):
    """Şasi kirişleri + yakıt deposu + akü kutusu + yedek teker + arka lambalar, çamurluklar."""
    for s in (-1, 1):
        box((s * w * 0.42, -0.3, zb + 0.1), (0.14, L, 0.3), "dark", bev=0.0)
    for y in (L * 0.35, 0.0, -L * 0.35):
        box((0, y - 0.3, zb + 0.1), (w * 0.84, 0.1, 0.22), "dark", bev=0.0)
    taillight(-0.95, -0.3 - L / 2 - 0.02, zb + 0.15)
    taillight(0.95, -0.3 - L / 2 - 0.02, zb + 0.15)

def truck_ru(n_ax=3, kamaz=False, big=False):
    if big:
        ax = [3.0, 1.6, -1.4, -2.8]
        wheels_axles(ax, 1.25, 0.68, 0.48, "dark")
    else:
        ax = [2.5, -0.6, -2.0] if n_ax == 3 else [2.5, -1.5]
        wheels_axles(ax, 1.08, 0.6, 0.42, "dark")
    zb = 0.8 if not big else 0.95
    L = 7.2 if big else 6.6
    _truck_chassis(ax, zb, L)
    if kamaz or big:
        cab(2.9 if big else 2.45, zb + 0.15, 2.5 if not big else 2.8, 2.0 if not big else 2.4, 1.75)
        yb = (2.9 if big else 2.45) + (1.0 if not big else 1.2)
        box((0, yb + 0.05, zb + 0.35), (2.4 if not big else 2.7, 0.15, 0.3), "dark", bev=0.0)                    # tampon
        for s in (-1, 1):
            light(s * 0.85, yb + 0.12, zb + 0.4)
            shackle(s * 0.5, yb + 0.12, zb + 0.15, 1)
        box((0, yb + 0.02, zb + 0.95), (1.2, 0.03, 0.35), "dark", bev=0.0)                                    # ızgara
        for k in range(5):
            box((0, yb + 0.04, zb + 0.82 + k * 0.065), (1.15, 0.02, 0.025), "paint", bev=0.0)
    else:
        hood_cab(1.6, zb + 0.15)
    for s in (-1, 1):
        f = F((s * 1.25, 0.5, zb + 0.45), (0, 0, 0))
        f.box((0, 0, 0), (0.15, 0.7, 0.45), "paint", bev=0.01)                                       # yakıt deposu
        f.cyl((0, 0.15, 0.24), 0.05, 0.04, "metal", seg=10)
        for t in (-0.25, 0.25):
            f.box((0, t, 0), (0.17, 0.04, 0.47), "dark")
        # çamurluklar (arka akslar üstünde)
        for y in ax[1:]:
            box((s * 1.1, y, zb + 0.35 if not big else zb + 0.4), (0.55, 1.5, 0.03), "paint", bev=0.0)
            box((s * 1.1, y - 0.78, zb + 0.1), (0.5, 0.02, 0.4), "rubber", bev=0.0)
    box((0.95 if not big else 1.1, -0.2, zb + 0.35), (0.3, 0.45, 0.3), "trim", bev=0.008)                      # akü kutusu
    return zb + 0.3

def _ru_turret_rails(R, rx, ry, z):
    """Taret çevresi tutamak rayları (Sovyet tankı imzası)."""
    for s in (-1, 1):
        for a0, a1 in ((0.3, 1.0), (1.3, 2.0)):
            pts = [(math.cos(a0 + (a1 - a0) * t / 3) * rx * s, math.sin(a0 + (a1 - a0) * t / 3) * ry * -1, z) for t in range(4)]
            for p, q in zip(pts, pts[1:]):
                rod(p, q, 0.012, "metal", 5)
            for p in (pts[0], pts[-1]):
                rod(p, (p[0] * 0.97, p[1] * 0.97, z - 0.06), 0.01, "metal", 4)

# ------------------------------------------------------------ tanklar
def mbt_ru(v):
    t80 = v.get("t80", False)
    welded = v.get("welded", False)
    era = v.get("era", "k1")
    L, W, zt = 6.9, 3.5, 1.45
    ru_tracks(L, 1.42, 0.58, 6, 0.36 if not t80 else 0.32, zt, rollers=3 if not t80 else 5, holes=8 if not t80 else 0)
    poly_extrude_x([(L / 2, 0.95), (L / 2 - 0.4, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    poly_extrude_x([(L / 2 - 1.5, zt), (L / 2 + 0.05, 1.0), (L / 2 + 0.05, 0.92), (-L / 2, 0.92), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.012)
    for s in (-1, 1):
        weld((s * W / 2, L / 2 - 1.5, zt), (s * W / 2, L / 2 + 0.05, 1.0))
    # glacis reaktif zırh + V su siperi + dozer bıçağı
    if era in ("k5", "relikt"):
        kontakt_rows(-1.55, 1.55, L / 2 - 0.55, 1.15, 2, -1.15, 7)
    else:
        kontakt_rows(-1.4, 1.4, L / 2 - 0.6, 1.1, 2, -1.15, 8)
    for s in (-1, 1):
        box((s * 0.45, L / 2 - 1.25, zt - 0.02), (0.95, 0.05, 0.14), "paint", rot=(0, 0, s * 0.45), bev=0.0)   # V siper
    box((0, L / 2 + 0.15, 0.55), (2.8, 0.15, 0.4), "paint", rot=(-0.3, 0, 0), bev=0.012)
    for k in range(5):
        box(((k - 2) * 0.6, L / 2 + 0.08, 0.6), (0.04, 0.08, 0.36), "paint", rot=(-0.3, 0, 0), bev=0.0)
    # yan etek (lastik + reaktif zırh panelleri ön yarıda)
    for s in (-1, 1):
        box((s * 1.78, 0.1, 0.92), (0.04, L - 0.8, 0.45), "rubber", bev=0.0)
        bolt_row((s * 1.805, L / 2 - 0.6, 1.12), (s * 1.805, -L / 2 + 0.6, 1.12), 14, (s, 0, 0), 0.016)
        for k in range(5 if era != "k1" else 4):
            era_brick((s * 1.82, L / 2 - 0.85 - k * 0.62, 0.92), (0.1, 0.58, 0.5), nrm=(s, 0, 0))
        # çamurluk yakıt depoları / zula kutuları (kapakları, kayışları)
        for k in range(3):
            stowage_box(s * 1.6, -0.2 - k * 0.85, zt + 0.15, 0.35, 0.8, 0.28, side=s)
        light(s * 1.3, L / 2 - 0.4, zt - 0.05)
        # çekme halatları (glacis yanlarından)
        tow_cable(s * 1.55, L / 2 - 1.3, L / 2 - 0.25, zt - 0.1, (0, 0, 1))
    # sol arkada egzoz panjuru (gövde yanında)
    f = F((-W / 2 - 0.01, -1.9, 1.2), (0, 0, math.pi / 2))
    f.box((0, 0, 0), (0.7, 0.04, 0.32), "paint", bev=0.006)
    for k in range(4):
        f.box((0, 0.03, -0.12 + k * 0.08), (0.62, 0.012, 0.05), "dark", rot=(0.5, 0, 0))
    fuel_drums(-L / 2 - 0.4, 1.2, W)
    # kurtarma kütüğü (arka, variller üstü)
    cyl((0, -L / 2 - 0.45, 1.68), 0.13, 3.0, "wood", "X", seg=10)
    for s in (-1, 1):
        box((s * 1.25, -L / 2 - 0.45, 1.68), (0.04, 0.3, 0.3), "dark", bev=0.0)
    dress_hull(L, W, zt, zf=0.82, front=False, tails=True, cable=False)
    hatch(0, L / 2 - 1.55, zt, 0.26)
    periscope(0, L / 2 - 1.25, zt - 0.02)
    grille(0, -2.3, zt + 0.01, 2.2, 1.4, 8)
    roof_panels(-1.6, 1.6, -3.3, -1.5, zt + 0.003, 2, 2)
    # ---------------- taret
    node("turret")
    tz = zt
    if welded:
        pts = []
        for s in (-1, 1):
            for (x, y, h) in ((0.45, 1.85, 0.0), (1.45, 1.3, 0.0), (1.55, -0.6, 0.0), (1.2, -1.45, 0.0)):
                pts += [(s * x, y, tz), (s * x * 0.82, y * 0.88, tz + 0.72)]
        hull_pts(pts, "paint", bev=0.014)
        for s in (-1, 1):
            weld((s * 0.37, 1.63, tz + 0.72), (s * 1.19, 1.14, tz + 0.72))
            weld((s * 1.27, -0.53, tz + 0.72), (s * 0.98, -1.28, tz + 0.72))
    else:
        # dökme kubbe taret (sert fasetli)
        pts = []
        for k in range(20):
            a = k * math.tau / 20
            rx, ry = 1.45, 1.55
            pts.append((math.cos(a) * rx, math.sin(a) * ry * (1.1 if math.sin(a) > 0 else 0.9), tz))
            pts.append((math.cos(a) * rx * 0.86, math.sin(a) * ry * 0.86 * (1.05 if math.sin(a) > 0 else 0.9), tz + 0.38))
            pts.append((math.cos(a) * rx * 0.66, math.sin(a) * ry * 0.64, tz + 0.64))
            pts.append((math.cos(a) * rx * 0.35, math.sin(a) * ry * 0.35, tz + 0.78))
        hull_pts(pts, "paint", bev=0.0, thr=math.radians(24))
    R = tz + 0.72
    # taret ön reaktif zırh "kaşları"
    for s in (-1, 1):
        for k in range(3):
            era_brick((s * (0.55 + k * 0.32), 1.55 - k * 0.12, tz + 0.5), (0.3, 0.55, 0.14), rot=(0.35, 0, s * (0.35 + k * 0.08)), nrm=(0, 0, 1))
    if era == "relikt":
        for s in (-1, 1):
            for k in range(3):
                era_brick((s * (1.42 - k * 0.04), 0.4 - k * 0.5, tz + 0.32), (0.1, 0.46, 0.34), rot=(0, 0, s * 0.12), nrm=(s, 0, 0))
    if v.get("bustle"):
        box((0, -1.65, tz + 0.4), (2.0, 0.7, 0.55), "paint", bev=0.014)
        side_panels(-1.0, -1.3, -2.0, tz + 0.15, tz + 0.65, -1, 2)
        side_panels(1.0, -1.3, -2.0, tz + 0.15, tz + 0.65, 1, 2)
        basket(-1.0, 1.0, -2.0, -2.35, tz + 0.2, 0.4)
        bag(0.3, -2.17, tz + 0.4, 0.8, 0.3, 0.3)
    else:
        # arka zula kutuları (taretin arkasını saran)
        for k, a in enumerate((-0.45, 0.0, 0.45)):
            f = F((math.sin(a) * 1.3, -math.cos(a) * 1.45, tz + 0.3), (0, 0, a))
            f.box((0, 0, 0), (0.75, 0.32, 0.4), "paint", bev=0.012)
            f.box((0, 0, 0.21), (0.7, 0.3, 0.02), "trim")
            for t in (-0.22, 0.22):
                f.box((t, -0.17, 0.08), (0.06, 0.02, 0.08), "metal")
    _ru_turret_rails(R, 1.25, 1.2, tz + 0.45)
    # komutan kubbesi + makineli / RWS, nişangâhlar, şnorkel, sis atarlar
    if v.get("rws"):
        rws(-0.55, -0.1, R, True, True)
    else:
        cyl((-0.55, -0.1, tz + 0.8), 0.36, 0.18, "paint", seg=16)
        for k in range(5):
            a = k * math.tau / 5 + 0.9
            periscope(-0.55 + math.cos(a) * 0.32, -0.1 + math.sin(a) * 0.32, tz + 0.84, a + math.pi / 2, small=True)
        hatch(-0.55, -0.1, tz + 0.89, 0.24)
        mg(-0.55, 0.15, tz + 1.1, 0.0, 1.1, True)
        box((-0.55, 0.42, tz + 1.12), (0.42, 0.03, 0.3), "paint", bev=0.0)                    # MG kalkanı
    hatch(0.55, -0.3, R, 0.28, peri=1)
    # nişancı nişangâhı (1A40 / Sosna-U) — zırhlı kutu + kapaklı pencere
    box((0.6, 0.85, tz + 0.82), (0.32, 0.4, 0.3), "paint", bev=0.012)
    box((0.6, 1.06, tz + 0.84), (0.22, 0.02, 0.14), "glass", bev=0.0)
    box((0.6, 1.08, tz + 0.95), (0.3, 0.1, 0.02), "trim", bev=0.0)
    if era == "relikt" and not welded and not t80:
        box((-0.15, 1.05, tz + 0.88), (0.42, 0.3, 0.3), "paint", bev=0.012)                    # Sosna-U
        for k in range(2):
            box((-0.25 + k * 0.2, 1.21, tz + 0.88), (0.12, 0.02, 0.12), "glass", bev=0.0)
    if era == "k1" or t80:
        ir_light(0.75, 1.55, tz + 0.55, 0.16, 0.3)                                             # Luna IR projektörü
    cyl((-0.3, -1.6, tz + 0.55), 0.1, 1.8, "paint", "X", seg=10)                                  # şnorkel
    for t in (-0.6, 0.6):
        box((-0.3 + t, -1.52, tz + 0.48), (0.06, 0.12, 0.14), "metal", bev=0.0)
    rod((0.35, -0.6, R), (0.35, -0.6, R + 0.45), 0.014, "dark", 6)                                # rüzgâr sensörü
    box((0.35, -0.6, R + 0.47), (0.1, 0.05, 0.05), "dark", bev=0.0)
    for s in (-1, 1):
        for k in range(4):
            a = 0.7 + k * 0.18
            cyl((s * (0.95 + k * 0.1), 0.9 - k * 0.22, tz + 0.55), 0.04, 0.2, "dark", rot=(math.pi / 2 - 0.3, 0, s * -a), seg=8)
        box((s * 1.05, 0.55, tz + 0.48), (0.4, 0.5, 0.05), "metal", rot=(0, 0, s * -0.8), bev=0.0)
        if welded and not v.get("rws"):
            box((s * 0.75, 1.75, tz + 0.35), (0.25, 0.15, 0.2), "red", bev=0.008)                 # IR karıştırıcı
            box((s * 0.75, 1.66, tz + 0.35), (0.3, 0.05, 0.25), "paint", bev=0.0)
        antenna(s * 0.7, -1.1, tz + 0.65, 1.5)
        lift_eye((s * 0.9, -0.6, tz + 0.62))
    if v.get("cage"):
        cage(-1.3, 1.5, tz + 0.8, 1.4, 0.7)
    # ---------------- namlu
    node("barrel")
    bz = tz + 0.42
    by = 1.7 if welded else 1.6
    box((0, by, bz), (0.55, 0.3, 0.42), "paint", bev=0.012)
    box((0.2, by + 0.16, bz + 0.05), (0.08, 0.02, 0.06), "dark", bev=0.0)                         # eş eksenli PKT
    gun(by + 0.1, bz, 5.2, 0.09, "paint", sleeve=0.0)
    for f in (0.3, 0.55, 0.8):
        cyl((0, by + 0.1 + 5.2 * f, bz), 0.12, 0.25, "paint", "Y", seg=14)                       # ısı kılıfı bantları
        cyl((0, by + 0.1 + 5.2 * f + 0.11, bz), 0.125, 0.03, "trim", "Y", seg=14)
    cyl((0, by + 0.1 + 5.2 * 0.42, bz), 0.135, 0.4, "paint", "Y", seg=14)                         # duman tahliye
    box((0, by + 5.15, bz + 0.1), (0.07, 0.12, 0.05), "dark", bev=0.0)                            # namlu ağzı referansı
    pivots = {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, by, bz)}
    return pivots, {"muzzle": (0, by + 5.4, bz), "radius": 2.8}

def mbt_t14(v):
    L, W, zt = 8.6, 3.5, 1.7
    ru_tracks(L, 1.45, 0.58, 7, 0.36, zt, rollers=0, holes=6)
    poly_extrude_x([(L / 2, 1.1), (L / 2 - 0.5, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    poly_extrude_x([(L / 2 - 1.8, zt), (L / 2 + 0.05, 1.15), (L / 2 + 0.05, 0.95), (-L / 2, 0.95), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.014)
    for s in (-1, 1):
        for k in range(7):
            yy = L / 2 - 0.8 - k * 1.05
            box((s * 1.8, yy, 1.05), (0.1, 1.0, 0.75), "paint", bev=0.012)
            for a in (-1, 1):
                for b in (-1, 1):
                    bolt((s * 1.856, yy + a * 0.4, 1.05 + b * 0.3), (s, 0, 0), 0.02)
            if k < 3:
                era_brick((s * 1.9, yy, 1.2), (0.08, 0.9, 0.35), nrm=(s, 0, 0))
        light(s * 1.3, L / 2 - 0.3, 1.25)
        weld((s * W / 2, L / 2 - 1.8, zt), (s * W / 2, L / 2 + 0.05, 1.15))
        stowage_box(s * 1.45, -2.6, zt + 0.15, 0.5, 1.6, 0.3, side=s)
    for k in range(10):                                                                            # arka kafes zırh
        box((-1.6 + k * 0.36, -L / 2 - 0.25, 1.2), (0.04, 0.04, 0.8), "dark", bev=0.0)
    for zz in (0.85, 1.55):
        rod((-1.7, -L / 2 - 0.25, zz), (1.7, -L / 2 - 0.25, zz), 0.02, "dark", 6)
    hatch(-0.4, L / 2 - 1.6, zt, 0.28); hatch(0.4, L / 2 - 1.6, zt, 0.28)
    for s in (-1, 1):
        periscope(s * 0.4, L / 2 - 1.25, zt - 0.02, 0)
    grille(0, -2.8, zt + 0.01, 2.2, 1.8, 9)
    roof_panels(-1.6, 1.6, -1.9, 1.5, zt + 0.003, 2, 3)
    dress_hull(L, W, zt, zf=0.9, cable=False)
    node("turret")
    tz = zt
    slab(1.7, 1.2, -1.8, -1.9, tz, tz + 0.75, 1.2, 1.0, "paint", bev=0.014, wf=0.55)
    R = tz + 0.75
    roof_panels(-0.95, 0.95, -1.75, 1.15, R + 0.003, 2, 3, bolts=False)
    rws(0.0, -0.8, R, True, True)
    for s in (-1, 1):
        f = F((s * 0.7, 0.4, tz + 0.95), (0, 0, 0))
        f.box((0, 0, 0), (0.35, 0.35, 0.32), "paint", bev=0.012)
        f.box((0, 0.18, 0.02), (0.24, 0.02, 0.16), "glass")
        f.box((0, 0.05, 0.17), (0.4, 0.45, 0.02), "trim")
        # AFAR radar panelleri (taret köşelerinde)
        for yy in (1.1, -1.5):
            box((s * 1.13, yy, tz + 0.45), (0.04, 0.5, 0.35), "dark", rot=(0, 0, s * 0.35 * (1 if yy > 0 else -1)), bev=0.0)
        aps(s * 1.25, -0.3, tz + 0.45, s)
        antenna(s * 0.9, -1.6, R, 1.4)
        # Afganit fırlatıcı tüpleri (taret alt kuşağı)
        for k in range(5):
            cyl((s * (1.0 + k * 0.03), 1.0 - k * 0.3, tz + 0.12), 0.06, 0.22, "dark", seg=8, rot=(0, s * 1.2, 0))
    node("barrel")
    bz = tz + 0.45
    box((0, 1.75, bz), (0.5, 0.3, 0.35), "paint", bev=0.012)
    gun(1.85, bz, 5.6, 0.09, "paint", sleeve=0.6, bands=3)
    return {"body": (0, 0, 0), "turret": (0, 0.3, tz), "barrel": (0, 1.75, bz)}, {"muzzle": (0, 7.5, bz), "radius": 3.2}

# ------------------------------------------------------------ tekerlekli / hafif paletli
def apc_btr(v):
    big = v.get("big", False)
    L, W = (7.6, 2.9) if not big else (8.0, 3.1)
    r = 0.55
    ax = [2.55, 1.35, -0.6, -1.8] if not big else [2.75, 1.5, -0.7, -1.95]
    wheels_axles(ax, W / 2 - 0.25, r, 0.38, "dark")
    zb = r
    zt = zb + 1.35
    # tekne gövde: eğimli yanlar, sivri burun
    pts = []
    for s in (-1, 1):
        pts += [(s * 0.6, L / 2 + 0.2, zb + 0.15), (s * (W / 2 - 0.2), L / 2 - 0.6, zb - 0.15), (s * (W / 2 - 0.25), -L / 2, zb - 0.1),
                (s * (W / 2), L / 2 - 1.4, zb + 0.75), (s * (W / 2), -L / 2 + 0.2, zb + 0.75),
                (s * (W / 2 - 0.4), L / 2 - 1.9, zt), (s * (W / 2 - 0.45), -L / 2 + 0.3, zt), (s * 0.8, L / 2 - 0.4, zb + 0.95)]
    hull_pts(pts, "paint", bev=0.014)
    for s in (-1, 1):
        # yan kapı (2. ve 3. aks arası) + menteşeler + tutamak
        f = F((s * (W / 2 - 0.08), 0.35, zb + 0.6), (0, -s * 0.18, 0))
        f.box((0, 0, 0), (0.06, 0.9, 0.75), "paint", bev=0.01)
        f.box((s * 0.035, 0.0, 0.2), (0.02, 0.6, 0.25), "trim")
        for t in (-0.28, 0.28):
            f.box((s * 0.04, t, -0.4), (0.04, 0.12, 0.06), "metal")
        grab_handle(f.P((s * 0.04, 0.0, 0.42)), (0, 1, 0), (s, 0, 0), L=0.4, h=0.04)
        for k in range(3):
            box((s * (W / 2 - 0.12), -1.5 + k * 0.6, zb + 1.05), (0.04, 0.12, 0.12), "dark", bev=0.0)  # atış delikleri
            cyl((s * (W / 2 - 0.1), -1.5 + k * 0.6, zb + 1.05), 0.08, 0.03, "paint", "X", seg=10)
        light(s * 0.55, L / 2 + 0.05, zb + 0.4)
        # çamurluk kemerleri (aks gruplarının üstü)
        for (ya, yb) in ((ax[0], ax[1]), (ax[2], ax[3])):
            box((s * (W / 2 - 0.08), (ya + yb) / 2, zb + 0.72), (0.2, abs(ya - yb) + 1.25, 0.04), "paint", rot=(0, s * 0.3, 0), bev=0.0)
        # üst kenar tutamak rayı
        rod((s * (W / 2 - 0.42), 1.5, zt + 0.06), (s * (W / 2 - 0.47), -2.6, zt + 0.06), 0.014, "metal", 5)
        for yy in (1.5, -0.5, -2.6):
            rod((s * (W / 2 - 0.44), yy, zt), (s * (W / 2 - 0.44), yy, zt + 0.06), 0.012, "metal", 4)
        taillight(s * (W / 2 - 0.45), -L / 2 - 0.02, zt - 0.3)
        shackle(s * 0.6, L / 2 + 0.1, zb + 0.15, 1)
        shackle(s * 0.6, -L / 2 - 0.02, zb + 0.2, -1)
    # dalga kırıcı (burun) + ön camlar zırh kapaklı
    box((0, L / 2 - 0.15, zb + 0.6), (1.4, 0.05, 0.35), "paint", rot=(-0.9, 0, 0), bev=0.008)
    for s in (-1, 1):
        box((s * 0.4, L / 2 - 1.2, zt - 0.05), (0.7, 0.04, 0.4), "glass", rot=(-0.9, 0, 0), bev=0.0)
        box((s * 0.4, L / 2 - 1.15, zt + 0.08), (0.75, 0.04, 0.42), "paint", rot=(-1.45, 0, 0), bev=0.0)   # kalkık kapak
        hatch(s * 0.45, L / 2 - 1.75, zt, 0.24)
    grille(0, -2.3, zt + 0.01, 1.6, 1.2, 7)
    box((0, -L / 2 - 0.02, zb + 0.35), (0.5, 0.04, 0.35), "dark", bev=0.0)                         # su jeti kapağı
    for s in (-1, 1):
        hatch(s * 0.5, -0.8, zt, 0.26)
        tools(s * 0.95, -1.4, zt, (0, 0, 1), ("shovel",) if s < 0 else ("bar",))
    antenna(-0.9, -1.8, zt, 2.0); antenna(0.9, -1.8, zt, 1.6)
    node("turret")
    tz = zt
    ty = 0.9
    if v.get("nona"):
        slab(ty + 1.0, ty + 0.8, ty - 1.0, ty - 1.1, tz, tz + 0.6, 0.95, 0.8, "paint", wf=0.6, bev=0.014)
        hatch(0.4, ty - 0.4, tz + 0.6, 0.24); hatch(-0.4, ty - 0.4, tz + 0.6, 0.24)
        for s in (-1, 1):
            smoke_launchers(s * 0.85, ty + 0.5, tz + 0.3, s * 0.6, 3, s)
        node("barrel")
        box((0, ty + 0.85, tz + 0.35), (0.4, 0.25, 0.32), "paint", bev=0.01)
        gun(ty + 0.8, tz + 0.35, 1.6, 0.09, "paint")
        return wheel_pivots({"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.8, tz + 0.35)}), {"muzzle": (0, ty + 2.5, tz + 0.35), "radius": 2.8}
    cyl((0, ty, tz + 0.25), 0.6, 0.5, "paint", seg=16, r2=0.45)
    cyl((0, ty, tz + 0.03), 0.66, 0.06, "paint", seg=16)
    box((0.35, ty + 0.35, tz + 0.55), (0.2, 0.2, 0.18), "paint", bev=0.008)
    box((0.35, ty + 0.46, tz + 0.55), (0.14, 0.02, 0.1), "glass", bev=0.0)
    hatch(-0.15, ty - 0.15, tz + 0.5, 0.2)
    if v.get("gun30"):
        for s in (-1, 1):
            smoke_launchers(s * 0.55, ty - 0.1, tz + 0.35, s * 1.2, 3, s)
        box((-0.35, ty + 0.3, tz + 0.6), (0.22, 0.25, 0.2), "paint", bev=0.008)
        box((-0.35, ty + 0.43, tz + 0.6), (0.16, 0.02, 0.12), "glass", bev=0.0)
    node("barrel")
    bz = tz + 0.3
    box((0, ty + 0.5, bz), (0.3, 0.25, 0.25), "paint", bev=0.008)
    gun(ty + 0.4, bz, 2.2 if v.get("gun30") else 1.6, 0.045 if v.get("gun30") else 0.04, "gun", sleeve=0.3)
    gun(ty + 0.45, bz, 0.9, 0.022, "gun", x=0.2)                                                    # eş eksenli PKT
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.4, bz)}), {"muzzle": (0, ty + 2.7, bz), "radius": 2.8}

def apc_mtlb(v):
    L, W, zt = 6.4, 2.85, 1.55
    ru_tracks(L, 1.18, 0.38, 6, 0.3, zt, rollers=0, holes=6)
    poly_extrude_x([(L / 2 - 0.9, zt), (L / 2 + 0.05, 0.9), (L / 2 + 0.05, 0.75), (-L / 2, 0.75), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.014)
    # ön camlar + zırh kapakları
    for s in (-1, 1):
        box((s * 0.45, L / 2 - 0.6, zt - 0.2), (0.75, 0.04, 0.28), "glass", rot=(-1.0, 0, 0), bev=0.0)
        box((s * 0.45, L / 2 - 0.68, zt + 0.02), (0.8, 0.04, 0.3), "paint", rot=(-1.5, 0, 0), bev=0.0)
        weld((s * W / 2, L / 2 - 0.9, zt), (s * W / 2, L / 2 + 0.05, 0.9))
    if v.get("gmz"):
        box((0, -1.2, zt + 0.35), (2.4, 3.0, 0.7), "paint", bev=0.012)                                 # mayın deposu
        roof_panels(-1.2, 1.2, -2.7, 0.3, zt + 0.703, 2, 2)
        for s in (-1, 1):
            grab_handle((s * 1.21, -1.2, zt + 0.35), (0, 1, 0), (s, 0, 0), L=1.6)
        box((0, -L / 2 - 0.6, 0.6), (0.5, 1.4, 0.3), "metal", rot=(0.5, 0, 0), bev=0.008)              # döşeme oluğu
        for s in (-1, 1):
            box((s * 0.26, -L / 2 - 0.6, 0.72), (0.03, 1.4, 0.2), "metal", rot=(0.5, 0, 0), bev=0.0)
    for s in (-1, 1):
        stowage_box(s * (W / 2 - 0.3), -1.5, zt + 0.12, 0.5, 2.2, 0.24, side=s)
        light(s * 0.9, L / 2 + 0.02, 0.95)
        tools(s * (W / 2 - 0.2), 0.6, zt, (0, 0, 1), ("shovel", "pick") if s < 0 else ("bar", "sledge"))
    hatch(0.5, -2.0, zt, 0.3); hatch(-0.5, -2.0, zt, 0.3)
    grille(0.6, 0.5, zt + 0.01, 0.7, 0.9, 5)
    exhaust(1.1, L / 2 - 0.7, zt - 0.1, 0.07, fy=1)
    # arka kapılar
    for s in (-1, 1):
        box((s * 0.42, -L / 2 - 0.03, 1.15), (0.75, 0.05, 0.75), "paint", bev=0.008)
        grab_handle((s * 0.15, -L / 2 - 0.06, 1.15), (0, 0, 1), (0, -1, 0), L=0.2, h=0.04)
        box((s * 0.42, -L / 2 - 0.06, 1.3), (0.12, 0.02, 0.1), "dark", bev=0.0)
    dress_hull(L, W, zt, zf=0.75, cable=False, ties=False)
    antenna(-1.1, -2.7, zt, 1.8)
    node("turret")
    if v.get("atgm"):
        tp = (0.0, -0.4, zt)
        cyl((0, -0.4, zt + 0.15), 0.45, 0.3, "paint", seg=16)
        node("barrel")
        canister(0.0, 0.1, zt + 0.7, 1.4, 0.1, 0.1)
        box((0, -0.4, zt + 0.6), (0.4, 0.5, 0.3), "paint", bev=0.008)
        box((0.22, -0.3, zt + 0.62), (0.04, 0.2, 0.15), "glass", bev=0.0)
        return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.4, zt + 0.65)}, {"muzzle": (0, 0.8, zt + 0.75), "radius": 2.6}
    tp = (-0.75, L / 2 - 1.3, zt)
    cyl((tp[0], tp[1], zt + 0.2), 0.42, 0.4, "paint", seg=16, r2=0.32)
    cyl((tp[0], tp[1], zt + 0.43), 0.2, 0.06, "paint", seg=12)
    node("barrel")
    mg(tp[0], tp[1] + 0.4, zt + 0.25, 0.0, 0.9, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (tp[0], tp[1] + 0.3, zt + 0.25)}, {"muzzle": (tp[0], tp[1] + 1.3, zt + 0.25), "radius": 2.6}

def _bmp_hull(L, W, zt, ribbed=True):
    ru_tracks(L, W / 2 - 0.3, 0.42, 6, 0.36, zt, rollers=3, holes=8)
    # alçak, keskin burunlu tekne gövde
    poly_extrude_x([(L / 2 - 2.2, zt), (L / 2 + 0.25, 0.95), (L / 2 - 0.3, 0.5), (-L / 2 + 0.2, 0.5), (-L / 2, 0.8), (-L / 2, zt)], -W / 2 + 0.05, W / 2 - 0.05, "paint", bev=0.014)
    if ribbed:
        for k in range(5):
            box((0, L / 2 - 0.5 - k * 0.3, 1.05 + k * 0.12), (W - 0.4, 0.06, 0.05), "paint", rot=(-0.4, 0, 0), bev=0.0)
    for s in (-1, 1):
        light(s * 0.9, L / 2 - 0.2, 1.05)
        weld((s * (W / 2 - 0.05), L / 2 - 2.2, zt), (s * (W / 2 - 0.05), L / 2 + 0.25, 0.95))
        # ince yan etekler (lastik) + cıvata sırası
        box((s * (W / 2 - 0.02), 0.0, 0.95), (0.03, L - 1.0, 0.25), "rubber", bev=0.0)
        bolt_row((s * (W / 2), L / 2 - 0.8, 1.06), (s * (W / 2), -L / 2 + 0.6, 1.06), 10, (s, 0, 0), 0.014)
    # arka kapılar (yakıt depolu) + menteşeler + periskop
    for s in (-1, 1):
        f = F((s * 0.42, -L / 2 - 0.02, 0.95), (0, 0, 0))
        f.box((0, 0, 0), (0.72, 0.08, 0.65), "paint", bev=0.01)
        for t in (-0.2, 0.2):
            f.box((s * 0.38, -0.03, t), (0.05, 0.05, 0.12), "metal")
        grab_handle(f.P((-s * 0.25, -0.05, 0.05)), (0, 0, 1), (0, -1, 0), L=0.2, h=0.04)
        vision_block(s * 0.42, -L / 2 - 0.07, 1.12, math.pi, 0.14)
    # sırt kapakları (asker bölmesi, 4 adet)
    for s in (-1, 1):
        for yy in (-1.0, -2.0):
            f = F((s * 0.45, yy, zt), (0, 0, 0))
            f.box((0, 0, 0.02), (0.75, 0.85, 0.04), "paint", bev=0.008)
            f.box((s * 0.36, 0, 0.05), (0.05, 0.5, 0.04), "metal")
            grab_handle(f.P((-s * 0.2, 0, 0.04)), (0, 1, 0), (0, 0, 1), L=0.18, h=0.04)
    dress_hull(L, W, zt, zf=0.8, front=True, rear=False, tails=True, cable=False, ties=True)

def ifv_bmp(v):
    bmp3 = v.get("bmp3", False)
    L, W, zt = (6.75, 3.15, 1.6) if not bmp3 else (7.1, 3.2, 1.75)
    _bmp_hull(L, W, zt, not bmp3)
    hatch(-0.85, L / 2 - 1.9, zt, 0.24)
    for k in range(3):
        periscope(-0.85 + (k - 1) * 0.15, L / 2 - 1.62, zt - 0.03, (1 - k) * 0.25, small=True)
    grille(0.75, L / 2 - 1.7, zt + 0.0, 0.8, 0.7, 5)                                            # motor (sağ ön)
    for s in (-1, 1):
        tools(s * (W / 2 - 0.3), -L / 2 + 0.9, zt, (0, 0, 1), ("shovel", "pick") if s < 0 else ("bar",))
    tow_cable(-(W / 2 - 0.1), -L / 2 + 0.3, 0.3, zt - 0.05, (0, 0, 1))
    node("turret")
    tz = zt
    if v.get("atgm_launcher"):
        box((0, -0.8, tz + 0.2), (1.6, 1.8, 0.4), "paint", bev=0.012)
        node("barrel")
        for s in (-1, 1):
            canister(s * 0.5, -0.4, tz + 0.75, 2.0, 0.12, 0.15)
            box((s * 0.5, -0.7, tz + 0.6), (0.06, 0.3, 0.25), "metal", bev=0.0)
        cyl((0, -0.4, tz + 1.2), 0.35, 0.3, "paint", seg=16)
        box((0, -0.15, tz + 1.2), (0.3, 0.05, 0.18), "glass", bev=0.0)
        return {"body": (0, 0, 0), "turret": (0, -0.8, tz), "barrel": (0, -0.6, tz + 0.75)}, {"muzzle": (0, 0.6, tz + 0.9), "radius": 2.9}
    # konik taret (kaynaklı faset)
    pts = []
    for k in range(12):
        a = k * math.tau / 12
        pts += [(math.cos(a) * 1.0, math.sin(a) * 1.0 + 0.0, tz), (math.cos(a) * 0.62, math.sin(a) * 0.62, tz + 0.55)]
    hull_pts(pts, "paint", bev=0.012)
    R = tz + 0.55
    hatch(-0.35, -0.3, R, 0.22); hatch(0.35, -0.3, R, 0.22, peri=1)
    box((0.5, 0.35, tz + 0.7), (0.22, 0.3, 0.22), "paint", bev=0.008)
    box((0.5, 0.51, tz + 0.7), (0.16, 0.02, 0.12), "glass", bev=0.0)
    box((-0.25, 0.4, tz + 0.66), (0.16, 0.2, 0.16), "paint", bev=0.008)
    if v.get("atgm") or not bmp3:
        box((0, -0.1, tz + 0.75), (0.25, 1.4, 0.2), "paint", rot=(0.05, 0, 0), bev=0.008)               # üstte füze rayı
        canister(0, 0.0, tz + 0.92, 1.3, 0.07, 0.05)
    if v.get("atgm"):
        for s in (-1, 1):
            box((s * 0.95, -0.2, tz + 0.4), (0.28, 1.2, 0.35), "paint", bev=0.008)
            box((s * 0.95, 0.41, tz + 0.4), (0.2, 0.02, 0.25), "dark", bev=0.0)
    for s in (-1, 1):
        smoke_launchers(s * 0.85, 0.3, tz + 0.3, s * 1.1, 3, s)
        antenna(s * 0.5, -0.75, R, 1.5)
    for k in range(6):
        a = k * math.tau / 6 + 0.3
        lift_eye((math.cos(a) * 0.72, math.sin(a) * 0.72, tz + 0.38), (math.cos(a), math.sin(a), 0.8), a)
    node("barrel")
    bz = tz + 0.3
    box((0, 0.65, bz), (0.36, 0.25, 0.28), "paint", bev=0.008)
    if bmp3:
        gun(0.6, bz, 2.0, 0.08, "paint", sleeve=0.3, bands=1)
        gun(0.6, bz, 2.3, 0.035, "gun", x=0.25)
        L2 = 2.6
    else:
        gun(0.6, bz, 2.4, 0.04, "gun", sleeve=0.4)
        cyl((0, 3.0, bz), 0.055, 0.08, "gun", "Y", seg=8)
        L2 = 3.0
    return {"body": (0, 0, 0), "turret": (0, 0.0, tz), "barrel": (0, 0.6, bz)}, {"muzzle": (0, L2 + 0.1, bz), "radius": 2.9}

def ifv_bmd(v):
    L, W, zt = 6.1, 3.0, 1.5
    ru_tracks(L, 1.25, 0.36, 5, 0.33, zt, rollers=4, holes=6)
    poly_extrude_x([(L / 2 - 1.6, zt), (L / 2 + 0.2, 0.95), (L / 2 - 0.25, 0.5), (-L / 2 + 0.2, 0.5), (-L / 2, 0.8), (-L / 2, zt)], -W / 2 + 0.05, W / 2 - 0.05, "paint", bev=0.014)
    for k in range(4):
        box((0, L / 2 - 0.4 - k * 0.28, 1.05 + k * 0.12), (W - 0.5, 0.05, 0.04), "paint", rot=(-0.4, 0, 0), bev=0.0)
    for s in (-1, 1):
        light(s * 0.85, L / 2 - 0.1, 1.05)
        weld((s * (W / 2 - 0.05), L / 2 - 1.6, zt), (s * (W / 2 - 0.05), L / 2 + 0.2, 0.95))
        stowage_box(s * 1.2, -1.9, zt + 0.12, 0.45, 1.2, 0.24, side=s)
        box((s * (W / 2 - 0.03), 0.1, 0.92), (0.03, L - 1.0, 0.2), "rubber", bev=0.0)
    hatch(-0.6, L / 2 - 1.3, zt, 0.24)
    for k in range(3):
        periscope(-0.6 + (k - 1) * 0.14, L / 2 - 1.05, zt - 0.03, (1 - k) * 0.25, small=True)
    grille(0, -2.2, zt + 0.01, 1.8, 1.0, 6)
    dress_hull(L, W, zt, zf=0.78, cable=False)
    node("turret")
    tz = zt
    if v.get("apc"):
        box((0, -1.0, zt + 0.3), (2.4, 2.6, 0.6), "paint", bev=0.014)
        roof_panels(-1.2, 1.2, -2.3, 0.3, zt + 0.603, 2, 2)
        for s in (-1, 1):
            for k in range(3):
                vision_block(s * 1.2, -0.4 - k * 0.6, zt + 0.42, -s * math.pi / 2, 0.14)
            hatch(s * 0.5, -1.8, zt + 0.6, 0.25)
        rws(0.5, -0.5, zt + 0.6, False, True)
        node("barrel")
        mg(0.45, -0.1, zt + 0.85, 0.0, 0.9, False)
        return {"body": (0, 0, 0), "turret": (0.5, -0.5, zt + 0.6), "barrel": (0.45, -0.3, zt + 0.85)}, {"muzzle": (0.45, 0.7, zt + 0.85), "radius": 2.6}
    if v.get("gun125"):
        pts = []
        for s in (-1, 1):
            for (x, y) in ((0.45, 1.4), (1.3, 1.0), (1.4, -0.9), (1.1, -1.5)):
                pts += [(s * x, y, tz), (s * x * 0.82, y * 0.88, tz + 0.6)]
        hull_pts(pts, "paint", bev=0.014)
        R = tz + 0.6
        if v.get("rws"):
            rws(-0.5, -0.4, R, False, True)
        else:
            cyl((-0.5, -0.4, tz + 0.68), 0.3, 0.16, "paint", seg=16)
            hatch(-0.5, -0.4, tz + 0.76, 0.22)
        hatch(0.5, -0.3, R, 0.24)
        box((0.6, 0.6, R + 0.13), (0.3, 0.35, 0.26), "paint", bev=0.01)
        box((0.6, 0.79, R + 0.14), (0.2, 0.02, 0.12), "glass", bev=0.0)
        for s in (-1, 1):
            smoke_launchers(s * 1.05, 0.6, tz + 0.35, s * 0.8, 4, s)
            stowage_box(s * 1.1, -1.25, tz + 0.3, 0.3, 0.6, 0.35, side=s)
            antenna(s * 0.7, -1.0, R, 1.4)
            weld((s * 0.37, 1.23, R), (s * 1.07, 0.88, R))
        node("barrel")
        bz = tz + 0.35
        box((0, 1.35, bz), (0.45, 0.3, 0.35), "paint", bev=0.012)
        gun(1.45, bz, 5.0, 0.085, "paint", sleeve=0.5, bands=2)
        return {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, 1.35, bz)}, {"muzzle": (0, 6.5, bz), "radius": 2.6}
    if v.get("nona"):
        slab(1.0, 0.8, -1.0, -1.1, tz, tz + 0.55, 1.0, 0.85, "paint", wf=0.6, bev=0.014)
        hatch(0.4, -0.4, tz + 0.55, 0.24); hatch(-0.4, -0.4, tz + 0.55, 0.24)
        for s in (-1, 1):
            smoke_launchers(s * 0.9, 0.5, tz + 0.3, s * 0.6, 3, s)
        node("barrel")
        box((0, 0.85, tz + 0.3), (0.42, 0.25, 0.32), "paint", bev=0.01)
        gun(0.8, tz + 0.3, 1.5, 0.09, "paint")
        return {"body": (0, 0, 0), "turret": (0, 0.2, tz), "barrel": (0, 0.8, tz + 0.3)}, {"muzzle": (0, 2.4, tz + 0.3), "radius": 2.6}
    pts = []
    for k in range(12):
        a = k * math.tau / 12
        pts += [(math.cos(a) * 0.95, math.sin(a) * 0.95, tz), (math.cos(a) * 0.6, math.sin(a) * 0.6, tz + 0.5)]
    hull_pts(pts, "paint", bev=0.012)
    hatch(-0.3, -0.3, tz + 0.5, 0.2); hatch(0.3, -0.3, tz + 0.5, 0.2)
    box((0.45, 0.35, tz + 0.62), (0.2, 0.26, 0.2), "paint", bev=0.008)
    for s in (-1, 1):
        smoke_launchers(s * 0.8, 0.3, tz + 0.28, s * 1.1, 3, s)
    node("barrel")
    gun(0.55, tz + 0.28, 1.9, 0.075, "paint", sleeve=0.3)
    gun(0.55, tz + 0.28, 2.2, 0.033, "gun", x=0.24)
    return {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, 0.55, tz + 0.28)}, {"muzzle": (0, 2.6, tz + 0.28), "radius": 2.6}

def ifv_heavy(v):
    light_ = v.get("light", False)
    L, W, zt = (9.5, 3.5, 1.9) if not light_ else (7.8, 3.3, 1.8)
    ru_tracks(L, 1.45, 0.56, 7 if not light_ else 7, 0.36, zt, rollers=0, holes=6)
    poly_extrude_x([(L / 2 - 1.2, zt), (L / 2 + 0.05, 1.2), (L / 2 + 0.05, 0.95), (-L / 2, 0.95), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.014)
    poly_extrude_x([(L / 2, 1.1), (L / 2 - 0.5, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    for s in (-1, 1):
        for k in range(6):
            yy = L / 2 - 0.9 - k * (L - 1.6) / 6
            box((s * 1.8, yy, 1.1), (0.1, (L - 1.6) / 6 - 0.04, 0.75), "paint", bev=0.012)
            bolt_row((s * 1.856, yy - 0.45, 1.4), (s * 1.856, yy + 0.45, 1.4), 3, (s, 0, 0), 0.018)
            bolt_row((s * 1.856, yy - 0.45, 0.8), (s * 1.856, yy + 0.45, 0.8), 3, (s, 0, 0), 0.018)
        light(s * 1.3, L / 2 - 0.2, 1.35)
        weld((s * W / 2, L / 2 - 1.2, zt), (s * W / 2, L / 2 + 0.05, 1.2))
        tools(s * (W / 2 - 0.25), -1.8, zt, (0, 0, 1), ("shovel", "pick") if s < 0 else ("bar", "sledge"))
    _ramp(L, 2.0, 1.4, 0.9, zt)
    hatch(-0.6, L / 2 - 1.5, zt, 0.26); hatch(0.6, L / 2 - 1.5, zt, 0.26)
    roof_panels(-1.5, 1.5, -L / 2 + 0.3, -1.6, zt + 0.003, 2, 2)
    grille(0.8, L / 2 - 2.3, zt + 0.01, 1.0, 0.8, 5)
    dress_hull(L, W, zt, zf=0.85, cable=False)
    node("turret")
    tz = zt
    ty = -0.6
    slab(ty + 1.1, ty + 0.9, ty - 1.0, ty - 1.1, tz, tz + 0.6, 1.0, 0.85, "paint", bev=0.014, wf=0.55)
    box((0.55, ty + 0.4, tz + 0.8), (0.3, 0.32, 0.25), "paint", bev=0.008)
    box((0.55, ty + 0.57, tz + 0.8), (0.22, 0.02, 0.14), "glass", bev=0.0)
    box((-0.45, ty - 0.2, tz + 0.78), (0.28, 0.3, 0.22), "paint", bev=0.008)
    box((-0.45, ty - 0.04, tz + 0.78), (0.2, 0.02, 0.12), "glass", bev=0.0)
    for s in (-1, 1):
        for k in range(2):
            canister(s * 1.15, ty + 0.1, tz + 0.3 + k * 0.24, 1.6, 0.1, 0.05)                         # yan füze tüpleri
        smoke_launchers(s * 0.95, ty + 0.75, tz + 0.35, s * 0.6, 4, s)
        antenna(s * 0.6, ty - 0.9, tz + 0.6, 1.4)
    node("barrel")
    bz = tz + 0.32
    box((0, ty + 1.0, bz), (0.36, 0.25, 0.28), "paint", bev=0.008)
    gun(ty + 1.0, bz, 2.4, 0.045, "gun", sleeve=0.45)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.95, bz)}, {"muzzle": (0, ty + 3.5, bz), "radius": 3.3}

# ------------------------------------------------------------ topçu
def spg_ru(v):
    small = v.get("small", False)
    lt = v.get("light", False)
    koal = v.get("koal", False)
    if lt:
        L, W, zt = 7.2, 2.85, 1.45
        ru_tracks(L, 1.2, 0.4, 7, 0.3, zt, rollers=0, holes=6)
    else:
        L, W, zt = (7.15, 3.4, 1.5) if not small else (6.5, 3.2, 1.45)
        ru_tracks(L, 1.4, 0.55 if not small else 0.48, 6, 0.34, zt, rollers=5 if not small else 4)
    poly_extrude_x([(L / 2 - 1.1, zt), (L / 2 + 0.05, 0.95), (L / 2 + 0.05, 0.9), (-L / 2, 0.9), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.014)
    for s in (-1, 1):
        light(s * 1.1, L / 2 - 0.2, 1.1)
        weld((s * W / 2, L / 2 - 1.1, zt), (s * W / 2, L / 2 + 0.05, 0.95))
        box((s * (W / 2 + 0.02), 0.0, 0.95), (0.03, L - 0.6, 0.18), "rubber", bev=0.0)
        tools(s * (W / 2 - 0.22), L / 2 - 1.5, zt, (0, 0, 1), ("shovel", "pick") if s < 0 else ("bar", "sledge"))
    hatch(-0.85, L / 2 - 1.0, zt, 0.24)
    periscope(-0.85, L / 2 - 0.72, zt - 0.02)
    grille(0.6, L / 2 - 1.0, zt + 0.01, 0.9, 0.6, 4)
    louvers(0, -L / 2 - 0.02, zt - 0.3, 1.4, 0.3, 4)
    dress_hull(L, W, zt, zf=0.8, cable=False)
    if not lt:
        # dozer bıçağı (ön) + namlu seyahat kilidi
        box((0, L / 2 + 0.15, 0.55), (2.6, 0.15, 0.35), "paint", rot=(-0.3, 0, 0), bev=0.012)
        for s in (-1, 1):
            bar((s * 0.25, L / 2 - 0.4, zt - 0.1), (0, L / 2 - 0.9, zt + 0.35), 0.06, 0.06, "paint")
        box((0, L / 2 - 0.9, zt + 0.37), (0.3, 0.12, 0.1), "metal", bev=0.0)
    node("turret")
    tz = zt
    ty = -0.9 if not lt else -0.8
    tw, tl, th = (1.6, 2.1, 1.2) if not (small or lt) else ((1.4, 1.8, 1.0) if small else (1.1, 1.4, 0.75))
    slab(ty + tl * 0.55, ty + tl * 0.45, ty - tl * 0.55, ty - tl * 0.6, tz, tz + th, tw, tw - 0.1, "paint", bev=0.014, wf=tw - 0.35)
    R = tz + th
    roof_panels(-(tw - 0.2), tw - 0.2, ty - tl * 0.5, ty + tl * 0.4, R + 0.003, 2, 2)
    if not koal and not lt:
        cyl((-0.7, ty - 0.2, R + 0.12), 0.35, 0.24, "paint", seg=16)
        for k in range(5):
            a = k * math.tau / 5 + 0.6
            periscope(-0.7 + math.cos(a) * 0.32, ty - 0.2 + math.sin(a) * 0.32, R + 0.15, a + math.pi / 2, small=True)
        mg(-0.7, ty + 0.05, R + 0.35, 0.0, 1.0, True)
    elif koal:
        rws(-0.7, ty - 0.4, R, True, True)
    if koal:
        box((0.6, ty + 0.3, R + 0.15), (0.35, 0.4, 0.3), "paint", bev=0.008)
        box((0.6, ty + 0.51, R + 0.16), (0.24, 0.02, 0.14), "glass", bev=0.0)
    hatch(0.55, ty - 0.5, R, 0.26)
    for s in (-1, 1):
        smoke_launchers(s * (tw - 0.05), ty + tl * 0.35, tz + th * 0.6, s * 0.6, 4, s)
        box((s * (tw + 0.04), ty - 0.2, tz + th * 0.5), (0.08, 1.2, 0.5), "canvas", bev=0.008)
        for t in (-0.4, 0.0, 0.4):
            box((s * (tw + 0.085), ty - 0.2 + t, tz + th * 0.5), (0.012, 0.04, 0.52), "dark", bev=0.0)
        side_panels(s * tw * 0.98, ty - tl * 0.5, ty + tl * 0.3, tz + 0.1, R - 0.08, s, 2)
        antenna(s * (tw - 0.3), ty - tl * 0.4, R, 1.5)
        lift_eye((s * (tw - 0.25), ty + tl * 0.35, R))
    # arka mühimmat besleme kapağı + sepet
    yb = ty - tl * 0.6
    box((0, yb - 0.03, tz + th * 0.45), (tw * 0.9, 0.05, th * 0.6), "paint", bev=0.008)
    seam((0, yb - 0.06, tz + 0.1), (0, yb - 0.06, tz + th * 0.75), (0, -1, 0))
    if not lt:
        basket(-tw * 0.75, tw * 0.75, yb, yb - 0.4, tz + th * 0.65, 0.35)
        bag(0.4, yb - 0.2, tz + th * 0.65 + 0.18, 0.7, 0.32, 0.3)
    node("barrel")
    bz = tz + th * 0.5
    by = ty + tl * 0.55
    Lb = 7.0 if not (small or lt) else (5.0 if small else 3.2)
    if v.get("short"):
        Lb = 2.2
    box((0, by + 0.1, bz), (0.55, 0.4, 0.45), "paint", bev=0.012)
    bolt_row((-0.22, by + 0.305, bz + 0.16), (0.22, by + 0.305, bz + 0.16), 4, (0, 1, 0), 0.015)
    gun(by + 0.25, bz, Lb, 0.1 if not lt else 0.075, "paint", brake=True, sleeve=0.7 if Lb > 3 else 0.0, bands=2 if Lb > 3 else 0)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, by, bz)}, {"muzzle": (0, by + Lb + 0.4, bz), "radius": 3.0}

def mlrs_ru(v):
    n = v.get("tubes", 40)
    big = v.get("big", False)
    zd = truck_ru(4 if v.get("eight") else 3, v.get("kamaz", False), big or v.get("eight", False))
    # arka dengeleme ayakları (krikolar)
    for s in (-1, 1):
        cyl((s * 1.05, -3.3 if big else -3.0, zd - 0.45), 0.07, 0.8, "metal", seg=10)
        box((s * 1.05, -3.3 if big else -3.0, 0.08), (0.3, 0.3, 0.06), "metal", bev=0.0)
    node("turret")
    tp = (0, -1.8, zd)
    cyl((0, -1.8, zd + 0.15), 0.7, 0.3, "paint", seg=16)
    for s in (-1, 1):
        box((s * 0.55, -1.8, zd + 0.45), (0.1, 0.8, 0.35), "paint", bev=0.008)                       # yükseliş yatakları
        cyl((s * 0.5, -2.4, zd + 0.55), 0.06, 0.6, "metal", seg=10, rot=(0.9, 0, 0))                    # yükseliş pistonu
    node("barrel")
    # tüp demeti: bağlantı çerçeveleri + tüp ağızları
    if n >= 40:
        cols, rows, r = 10, 4, 0.065
    elif n >= 16:
        cols, rows, r = 4, 4, 0.13
    else:
        cols, rows, r = 4, 3, 0.17
    pitch = 0.18
    Lt = 3.1 if not big else 4.6
    for i in range(cols):
        for k in range(rows):
            x = (i - (cols - 1) / 2) * r * 2.2
            z = zd + 0.65 + k * r * 2.2
            canister(x, -1.6, z, Lt, r, pitch, "paint", seg=8 if n >= 40 else 12)
    wx = cols * r * 2.2 + 0.1
    hz = rows * r * 2.2 + 0.08
    d = Vector((0, math.cos(pitch), math.sin(pitch)))
    c0 = Vector((0, -1.6, zd + 0.65 + (rows - 1) * r * 1.1))
    for t in (-0.35, 0.0, 0.35):
        c = c0 + d * (Lt * t)
        f = F(c, (pitch, 0, 0))
        for zz in (-hz / 2, hz / 2):
            f.box((0, 0, zz), (wx, 0.08, 0.05), "paint")
        for xx in (-wx / 2, wx / 2):
            f.box((xx, 0, 0), (0.05, 0.08, hz), "paint")
    box((0, -2.8, zd + 0.55), (cols * r * 2.2 + 0.1, 0.25, 0.3), "dark", bev=0.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.0, zd + 0.7)}), {"muzzle": (0, 0.0, zd + 1.0), "radius": 2.6}

def mlrs_tos(v):
    pv, md = mbt_ru({"era": "k5"})
    # T-72 gövdesi; taret yerine büyük roket kutusu
    _clear_turret()
    node("turret")
    zt = 1.45
    box((0, -0.6, zt + 0.25), (2.2, 2.4, 0.5), "paint", bev=0.014)
    for s in (-1, 1):
        box((s * 0.9, -0.6, zt + 0.7), (0.15, 1.6, 0.45), "paint", bev=0.01)
        cyl((s * 0.8, -1.5, zt + 0.75), 0.07, 0.8, "metal", seg=10, rot=(0.8, 0, 0))
    box((0.6, 0.3, zt + 0.65), (0.4, 0.4, 0.3), "paint", bev=0.01)
    box((0.6, 0.51, zt + 0.66), (0.28, 0.02, 0.16), "glass", bev=0.0)
    node("barrel")
    f = F((0, -0.6, zt + 1.3), (0.12, 0, 0))
    f.box((0, 0, 0), (2.6, 4.4, 1.5), "paint", bev=0.014)
    for t in (-1.6, -0.6, 0.4, 1.4):
        f.box((0, t, 0.76), (2.64, 0.08, 0.04), "paint")
        for sx in (-1, 1):
            f.box((sx * 1.31, t, 0), (0.04, 0.08, 1.52), "paint")
    for sx in (-1, 1):
        for t in (-1.2, 1.2):
            lift_eye(f.P((sx * 1.0, t, 0.75)), f.R @ Vector((0, 0, 1)))
    for i in range(6):
        for k in range(4):
            off = Vector(((i - 2.5) * 0.4, 2.21, (k - 1.5) * 0.34))
            off.rotate(Euler((0.12, 0, 0)))
            cyl((off.x, -0.6 + off.y, zt + 1.3 + off.z), 0.15, 0.03, "trim", rot=(math.pi / 2 - 0.12, 0, 0), seg=12)
            cyl((off.x, -0.6 + off.y + 0.01, zt + 1.3 + off.z), 0.12, 0.04, "dark", rot=(math.pi / 2 - 0.12, 0, 0), seg=12)
    return {"body": (0, 0, 0), "turret": (0, -0.6, zt), "barrel": (0, -2.6, zt + 1.0)}, {"muzzle": (0, 1.6, zt + 1.5), "radius": 2.8}

def missile_ru(v):
    zd = truck_ru(4, False, True)
    node("turret")
    tp = (0, -1.4, zd)
    box((0, -1.4, zd + 0.15), (2.4, 4.2, 0.3), "paint", bev=0.012)
    roof_panels(-1.2, 1.2, -3.5, 0.7, zd + 0.303, 2, 3)
    for s in (-1, 1):
        cyl((s * 1.0, -3.6, zd - 0.3), 0.08, 0.9, "metal", seg=10)                                    # dengeleme krikosu
        stowage_box(s * 1.05, 0.5, zd + 0.45, 0.3, 0.6, 0.3, side=s)
    node("barrel")
    for s in (-1, 1):
        x = s * 0.55
        cyl((x, -1.4, zd + 0.75), 0.47, 6.6, "paint", "Y", seg=16)
        cyl((x, 1.95, zd + 0.75), 0.47, 0.6, "paint", "Y", seg=16, r2=0.1)
        for t in (-2.6, -0.6, 1.3):
            cyl((x, -1.4 + t, zd + 0.75), 0.49, 0.06, "trim", "Y", seg=16)
        # kuyruk kanatçıkları + taşıyıcı beşik
        for a in range(4):
            aa = a * math.pi / 2 + math.pi / 4
            box((x + math.cos(aa) * 0.5, -4.4, zd + 0.75 + math.sin(aa) * 0.5), (0.04, 0.6, 0.18), "paint", rot=(0, -aa, 0), bev=0.0)
        for t in (-3.2, 0.4):
            box((x, -1.4 + t, zd + 0.3), (0.7, 0.2, 0.15), "metal", bev=0.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.5, zd + 0.6)}), {"muzzle": (0, 2.3, zd + 0.75), "radius": 2.8}

def sam_ru_long(v):
    zd = truck_ru(4, False, True)
    for s in (-1, 1):
        cyl((s * 1.05, -3.8, zd - 0.35), 0.08, 0.9, "metal", seg=10)
        box((s * 1.05, -3.8, 0.08), (0.35, 0.35, 0.06), "metal", bev=0.0)
    node("turret")
    tp = (0, -1.6, zd)
    box((0, -1.6, zd + 0.15), (2.4, 4.4, 0.3), "paint", bev=0.012)
    for s in (-1, 1):
        cyl((s * 0.9, -3.3, zd + 0.6), 0.1, 1.4, "metal", seg=10, rot=(0.6, 0, 0))
    node("barrel")
    for i in range(2):
        for k in range(2):
            x = (i - 0.5) * 1.05
            canister(x, -1.4, zd + 0.85 + k * 1.0, 7.0, 0.42, 0.0, "paint", seg=16)
            for t in (-2.0, 0.0, 2.0):
                cyl((x, -1.4 + t, zd + 0.85 + k * 1.0), 0.44, 0.08, "trim", "Y", seg=16)
    for t in (-3.0, 0.5):
        box((0, -1.4 + t, zd + 1.35), (2.3, 0.15, 2.1), "paint", bev=0.008)                             # kanister kafesi
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -4.5, zd + 1.0)}), {"muzzle": (0, 2.1, zd + 1.4), "radius": 3.0}

def _radar_panel(c, w, h, rot, m="paint"):
    """Dizi radar paneli: çerçeve + koyu anten yüzü + eleman ızgarası."""
    f = F(c, rot)
    f.box((0, 0, 0), (w, 0.1, h), m, bev=0.01)
    f.box((0, 0.055, 0), (w * 0.9, 0.012, h * 0.9), "dark")
    for k in range(1, 4):
        f.box((-w * 0.45 + w * 0.9 * k / 4, 0.062, 0), (0.012, 0.006, h * 0.88), "trim")
    for k in range(1, 3):
        f.box((0, 0.062, -h * 0.45 + h * 0.9 * k / 3), (w * 0.88, 0.006, 0.012), "trim")

def sam_ru_tr(v):
    L, W, zt = 7.3, 3.25, 1.5
    ru_tracks(L, 1.35, 0.5, 6, 0.34, zt, rollers=3)
    poly_extrude_x([(L / 2 - 1.2, zt), (L / 2 + 0.05, 0.95), (L / 2 + 0.05, 0.9), (-L / 2, 0.9), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.014)
    for s in (-1, 1):
        light(s * 1.0, L / 2 - 0.2, 1.1)
        weld((s * W / 2, L / 2 - 1.2, zt), (s * W / 2, L / 2 + 0.05, 0.95))
        box((s * (W / 2 + 0.02), 0.0, 0.95), (0.03, L - 0.6, 0.18), "rubber", bev=0.0)
        tools(s * (W / 2 - 0.22), L / 2 - 1.6, zt, (0, 0, 1), ("shovel", "pick") if s < 0 else ("bar",))
    hatch(-0.8, L / 2 - 0.9, zt, 0.24)
    grille(0, -2.6, zt + 0.01, 2.0, 1.2, 7)
    dress_hull(L, W, zt, zf=0.8, cable=False)
    node("turret")
    tz = zt
    if v.get("tor"):
        slab(1.1, 1.0, -1.6, -1.7, tz, tz + 1.5, 1.35, 1.25, "paint", bev=0.014)
        R = tz + 1.5
        side_panels(1.3, -1.6, 1.0, tz + 0.15, R - 0.1, 1, 3)
        side_panels(-1.3, -1.6, 1.0, tz + 0.15, R - 0.1, -1, 3)
        # arama radarı (kalkık, dönen) + destek kolları
        _radar_panel((0, -0.2, tz + 2.0), 1.6, 1.0, (0.3, 0, 0))
        for s in (-1, 1):
            bar((s * 0.6, -0.4, R), (s * 0.6, -0.25, tz + 1.6), 0.06, 0.06, "paint")
        # takip radarı (önde): çanak + yan TV/IR kutusu
        cyl((0, 1.2, tz + 0.8), 0.4, 0.5, "paint", "Y", seg=16)
        cyl((0, 1.46, tz + 0.8), 0.36, 0.03, "dark", "Y", seg=16)
        box((0.6, 1.1, tz + 1.1), (0.3, 0.3, 0.3), "paint", bev=0.01)
        box((0.6, 1.26, tz + 1.1), (0.2, 0.02, 0.16), "glass", bev=0.0)
        hatch(-0.7, -1.2, R, 0.24)
        for s in (-1, 1):
            antenna(s * 1.1, -1.5, R, 1.2)
        node("barrel")
        box((0, -0.3, tz + 1.55), (1.0, 1.0, 0.08), "dark", bev=0.0)
        for i in range(2):
            for k in range(2):
                box(((i - 0.5) * 0.45, -0.3 + (k - 0.5) * 0.45, tz + 1.6), (0.36, 0.36, 0.02), "trim", bev=0.0)   # dikey hücre kapakları
        return {"body": (0, 0, 0), "turret": (0, -0.3, tz), "barrel": (0, -0.3, tz + 1.5)}, {"muzzle": (0, -0.3, tz + 1.6), "radius": 3.0}
    if v.get("tung"):
        slab(1.0, 0.8, -1.4, -1.5, tz, tz + 1.0, 1.25, 1.1, "paint", bev=0.014)
        R = tz + 1.0
        # arama radarı çanağı (arka, katlanır) + direği
        cyl((0, -1.25, tz + 1.3), 0.12, 0.6, "metal", seg=10)
        cyl((0, -1.2, tz + 1.6), 0.9, 0.08, "paint", seg=20, rot=(0.4, 0, 0))
        cyl((0, -1.17, tz + 1.62), 0.8, 0.02, "dark", seg=20, rot=(0.4, 0, 0))
        cyl((0, 1.0, tz + 0.9), 0.35, 0.4, "paint", "Y", seg=16)
        cyl((0, 1.21, tz + 0.9), 0.3, 0.02, "dark", "Y", seg=16)
        hatch(0.5, -0.6, R, 0.24); hatch(-0.5, -0.6, R, 0.24)
        for s in (-1, 1):
            side_panels(s * 1.2, -1.4, 0.9, tz + 0.15, R - 0.1, s, 2)
        node("barrel")
        bz = tz + 0.65
        for s in (-1, 1):
            box((s * 1.35, 0.2, bz + 0.07), (0.3, 0.9, 0.45), "paint", bev=0.01)                           # top yuvası
            gun(0.6, bz, 2.6, 0.035, "gun", x=s * 1.35)
            gun(0.6, bz + 0.15, 2.6, 0.035, "gun", x=s * 1.35)
            for k in range(2):
                canister(s * 1.65, 0.0, bz + 0.4 + k * 0.22, 1.8, 0.09, 0.15)
        return {"body": (0, 0, 0), "turret": (0, -0.2, tz), "barrel": (0, 0.0, bz)}, {"muzzle": (1.35, 3.3, bz), "radius": 3.0}
    # Buk: döner platform, 4 füze rayı, ön radar
    cyl((0, -0.6, tz + 0.2), 1.2, 0.4, "paint", seg=20)
    box((0, 0.6, tz + 0.9), (1.4, 0.5, 1.1), "paint", bev=0.012)
    _radar_panel((0, 0.88, tz + 1.0), 1.2, 0.9, (0, 0, 0))
    box((0.5, 0.4, tz + 1.55), (0.3, 0.3, 0.2), "paint", bev=0.01)
    for s in (-1, 1):
        cyl((s * 0.6, -1.4, tz + 0.7), 0.07, 0.8, "metal", seg=10, rot=(0.7, 0, 0))
    node("barrel")
    for i in range(4):
        x = (i - 1.5) * 0.5
        box((x, -0.8, tz + 1.0), (0.08, 3.6, 0.08), "metal", rot=(0.2, 0, 0), bev=0.0)
        cyl((x, -0.8, tz + 1.15), 0.2, 5.2, "trim", rot=(math.pi / 2 - 0.2, 0, 0), seg=12)
        d = Vector((0, math.cos(0.2), math.sin(0.2)))
        c = Vector((x, -0.8, tz + 1.15))
        cyl(c + d * 2.85, 0.2, 0.5, "trim", rot=(math.pi / 2 - 0.2, 0, 0), seg=12, r2=0.03)                 # burun
        for a in range(4):
            aa = a * math.pi / 2 + math.pi / 4
            for t in (-2.2, 0.6):
                p = c + d * t
                box((p.x + math.cos(aa) * 0.27, p.y, p.z + math.sin(aa) * 0.27), (0.02, 0.6, 0.14), "trim", rot=(0.2, -aa, 0), bev=0.0)
    return {"body": (0, 0, 0), "turret": (0, -0.6, tz), "barrel": (0, -2.5, tz + 0.8)}, {"muzzle": (0, 1.8, tz + 1.6), "radius": 3.0}

def sam_ru_truck(v):
    zd = truck_ru(4, True, True)
    for s in (-1, 1):
        cyl((s * 1.15, -3.4, zd - 0.4), 0.07, 0.8, "metal", seg=10)
        box((s * 1.15, -3.4, 0.08), (0.3, 0.3, 0.06), "metal", bev=0.0)
        stowage_box(s * 1.2, -0.3, zd + 0.2, 0.3, 0.9, 0.35, side=s)
    node("turret")
    tp = (0, -1.8, zd)
    box((0, -1.8, zd + 0.65), (1.8, 1.8, 1.3), "paint", bev=0.014)
    side_panels(0.9, -2.7, -0.9, zd + 0.1, zd + 1.25, 1, 2)
    side_panels(-0.9, -2.7, -0.9, zd + 0.1, zd + 1.25, -1, 2)
    _radar_panel((0, -2.5, zd + 1.9), 1.3, 1.0, (0.25, 0, 0))                                             # arama radarı
    for s in (-1, 1):
        bar((s * 0.4, -2.6, zd + 1.3), (s * 0.4, -2.45, zd + 1.5), 0.06, 0.06, "paint")
    cyl((0, -1.0, zd + 1.0), 0.4, 0.3, "paint", "Y", seg=16)
    cyl((0, -0.84, zd + 1.0), 0.35, 0.02, "dark", "Y", seg=16)
    box((0, -1.0, zd + 1.45), (0.3, 0.3, 0.25), "paint", bev=0.01)
    box((0, -0.84, zd + 1.45), (0.2, 0.02, 0.14), "glass", bev=0.0)
    node("barrel")
    bz = zd + 0.9
    for s in (-1, 1):
        box((s * 1.4, -1.6, bz + 0.25), (0.65, 0.4, 0.55), "paint", bev=0.01)                              # füze paketi kafesi
        for k in range(2):
            for j in range(3):
                canister(s * (1.15 + j * 0.2), -1.6, bz + 0.15 + k * 0.22, 2.4, 0.09, 0.2)
        box((s * 1.0, -1.6, bz - 0.25), (0.3, 0.7, 0.3), "paint", bev=0.01)
        gun(-1.4, bz - 0.25, 2.6, 0.035, "gun", x=s * 1.0)
        gun(-1.4, bz - 0.35, 2.6, 0.035, "gun", x=s * 1.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.6, bz)}), {"muzzle": (1.0, 1.2, bz - 0.25), "radius": 3.0}

# ------------------------------------------------------------ helikopterler
def _heli_ru_bits(y_nose, z_nose, y_tail, eng_y, eng_z, eng_x, chaff_y, chaff_z, chaff_x):
    """Rus helikopter ayrıntıları: pitot, egzoz saptırıcıları, ısı fişeği kutuları, IR karıştırıcı, antenler."""
    cyl((0.2, y_nose + 0.6, z_nose), 0.015, 1.2, "metal", "Y", seg=6)
    cyl((-0.2, y_nose + 0.5, z_nose), 0.015, 1.0, "metal", "Y", seg=6)
    for s in (-1, 1):
        # egzoz saptırıcı (EVU): dışa ve yukarı kıvrık kutu
        f = F((s * eng_x, eng_y, eng_z), (0, 0, 0))
        f.box((0, 0, 0), (0.35, 0.8, 0.4), "metal", rot=(0, 0, s * 0.3), bev=0.01)
        f.box((s * 0.12, -0.4, 0.05), (0.3, 0.05, 0.3), "dark")
        # ısı fişeği kutuları
        box((s * chaff_x, chaff_y, chaff_z), (0.12, 0.6, 0.25), "dark", bev=0.008)
        for k in range(3):
            box((s * (chaff_x + 0.065), chaff_y - 0.2 + k * 0.2, chaff_z), (0.01, 0.15, 0.2), "trim", bev=0.0)
    cyl((0, eng_y - 1.0, eng_z + 0.35), 0.15, 0.3, "dark", seg=10)                                          # IR karıştırıcı
    cyl((0, eng_y - 1.0, eng_z + 0.52), 0.12, 0.06, "red", seg=10)
    antenna(0, y_tail + 2.0, eng_z, 0.6)
    box((0, y_tail + 1.0, eng_z - 0.4), (0.04, 0.6, 0.25), "dark", bev=0.0)

def heli_coax(v):
    from fam_air import blades, canopy, skids
    lt = v.get("light", False)
    util = v.get("utility", False)
    single = v.get("single", False)
    if lt:
        slab(1.6, 1.2, -1.2, -1.3, 0.4, 1.7, 0.7, 0.6, "paint", bev=0.012, wf=0.4)
        canopy(0.6, 1.7, 0.9, 1.6, 0.6)
        skids(2.6, 0.8)
        for s in (-1, 1):
            box((s * 0.6, -3.0, 1.3), (0.15, 3.6, 0.2), "paint", bev=0.012)                              # ikiz kuyruk kirişi
            box((s * 0.71, 0.0, 1.0), (0.02, 1.2, 0.6), "glass", bev=0.0)
        box((0, -4.6, 1.5), (1.6, 0.4, 0.06), "paint", bev=0.0)
        for s in (-1, 1):
            box((s * 0.8, -4.6, 1.75), (0.06, 0.45, 0.6), "paint", bev=0.008)
        mast = 2.2; R = 13.0; tail_y = -4.6
    elif util:
        slab(2.4, 2.0, -1.8, -2.0, 0.5, 2.3, 1.0, 0.9, "paint", bev=0.012, wf=0.6)
        canopy(1.6, 2.6, 1.3, 2.1, 0.85)
        slab(-2.0, -2.0, -4.6, -4.6, 1.2, 2.0, 0.55, 0.4, "paint", bev=0.012)
        box((0, -4.4, 2.0), (2.6, 0.5, 0.08), "paint", bev=0.008)
        for s in (-1, 1):
            box((s * 1.3, -4.4, 2.3), (0.08, 0.7, 1.0), "paint", bev=0.008)
            cyl((s * 1.0, 1.6, 0.25), 0.28, 0.18, "rubber", "X", seg=12)
        mast = 3.0; R = 15.8; tail_y = -4.6
    else:
        W = 0.55 if single else 0.85
        slab(2.6, 2.0, -1.6, -1.8, 0.55, 1.95, W, W - 0.1, "paint", bev=0.012, wf=W - 0.35)
        slab(3.6, 3.2, 2.6, 2.6, 0.65, 1.5, W - 0.2, W - 0.3, "paint", bev=0.012, wf=0.2)
        canopy(1.4, 3.2, 1.45, 2.05, W - 0.05)
        box((0, 2.3, 1.95), (0.05, 1.6, 0.06), "dark", bev=0.0)                                           # kanopi orta çerçeve
        cyl((0, 3.55, 1.05), 0.28, 0.35, "paint", "Y", seg=16)                                            # burun radomu / sensör
        cyl((0, 3.3, 0.55), 0.25, 0.4, "paint", seg=14)                                                   # GOES taretı
        cyl((0, 3.3, 0.38), 0.23, 0.08, "glass", seg=14)
        for s in (-1, 1):
            box((s * 0.75, -0.6, 1.95), (0.45, 2.0, 0.5), "paint", bev=0.012)                             # motor
            cyl((s * 0.75, 0.42, 2.0), 0.2, 0.06, "dark", "Y", seg=12)                                     # hava girişi
            box((s * 1.4, 0.2, 1.1), (1.6, 0.7, 0.1), "paint", rot=(0, s * 0.1, 0), bev=0.012)            # kanatçık
            # pilonlar + B-8 roket kovanı + Ataka/Vikhr tüpleri
            for i, xx in enumerate((1.3, 1.95)):
                box((s * xx, 0.25, 0.98), (0.08, 0.5, 0.15), "dark", bev=0.0)
            cyl((s * 1.3, 0.3, 0.75), 0.22, 1.6, "paint", "Y", seg=14)
            cyl((s * 1.3, 1.11, 0.75), 0.2, 0.02, "dark", "Y", seg=14)
            cyl((s * 1.3, 1.08, 0.75), 0.17, 0.12, "paint", "Y", seg=14, r2=0.2)
            for i in range(2):
                for j in range(2):
                    cyl((s * (1.85 + i * 0.2), 0.35, 0.82 - j * 0.2), 0.08, 1.5, "paint", "Y", seg=8)
            cyl((s * 0.65, 1.8, 0.25), 0.25, 0.16, "rubber", "X", seg=12)
            rod((s * 0.6, 1.8, 0.3), (s * 0.5, 1.6, 0.7), 0.04, "metal", 6)
            box((s * (W - 0.04), 1.0, 1.5), (0.03, 0.8, 0.45), "glass", bev=0.0)                            # kapı camı
        gun(0.5, 1.0, 2.2, 0.035, "gun", x=0.75)                                                         # yan top
        box((0.75, 0.6, 1.0), (0.22, 1.0, 0.3), "paint", bev=0.01)
        slab(-1.6, -1.6, -6.5, -6.5, 1.1, 1.65, 0.35, 0.22, "paint", bev=0.012, wf=0.28)
        box((0, -6.0, 1.5), (2.0, 0.5, 0.06), "paint", bev=0.01)
        for s in (-1, 1):
            box((s * 1.0, -6.0, 1.9), (0.08, 0.6, 0.9), "paint", bev=0.008)
        _heli_ru_bits(3.6, 1.0, -6.5, -1.5, 2.0, 0.78, -1.5, 1.2, W - 0.05)
        mast = 2.6; R = 14.4; tail_y = -6.0
    cyl((0, 0.0, mast - 0.2), 0.14, 1.4, "metal", seg=10)
    cyl((0, 0.0, mast - 0.75), 0.4, 0.25, "paint", seg=14)                                               # şanzıman kaportası
    node("rotor")
    blades(0, 0.0, mast, 3, R, chord=0.4)
    node("trotor")
    blades(0, 0.0, mast + 0.9, 3, R, chord=0.4, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, mast), "trotor": (0, 0.0, mast + 0.9)}, {"muzzle": (0.75, 2.8, 1.0), "radius": 3.6, "trotor_y": True}

def heli_hind(v):
    from fam_air import blades, tail_blades, canopy
    slab(2.8, 2.2, -2.0, -2.2, 0.6, 2.1, 0.85, 0.75, "paint", bev=0.012, wf=0.5)
    slab(4.6, 4.2, 2.8, 2.8, 0.7, 1.5, 0.5, 0.4, "paint", bev=0.012, wf=0.2)
    canopy(3.2, 4.5, 1.2, 1.8, 0.45)                                                                     # ön (nişancı)
    canopy(2.0, 3.2, 1.5, 2.2, 0.55)                                                                     # arka (pilot)
    for y in (3.2, 2.0):
        box((0, y, 1.85 if y > 3 else 2.15), (0.05, 0.05, 0.6), "dark", bev=0.0)
    for s in (-1, 1):
        # kabin kapısı (üst/alt açılan ikili) + pencereler
        box((s * 0.85, 0.0, 1.35), (0.04, 1.6, 0.6), "paint", bev=0.0)
        for k in range(3):
            box((s * 0.86, 0.5 - k * 0.5, 1.55), (0.03, 0.3, 0.25), "glass", bev=0.0)
        box((s * 0.55, -0.6, 2.3), (0.5, 2.4, 0.55), "paint", bev=0.012)                                  # motor
        cyl((s * 0.55, 0.62, 2.3), 0.2, 0.06, "dark", "Y", seg=12)
        box((s * 0.55, 0.75, 2.3), (0.48, 0.25, 0.5), "metal", bev=0.008)                                  # toz filtresi
        box((s * 1.7, 0.2, 1.3), (1.9, 0.9, 0.12), "paint", rot=(0, s * 0.25, 0), bev=0.012)             # kanat (aşağı eğik)
        for i in range(2):
            xx = s * (1.2 + i * 0.75)
            box((xx, 0.25, 1.1), (0.08, 0.5, 0.2), "dark", bev=0.0)
            cyl((xx, 0.3, 1.0 - i * 0.18), 0.24, 1.5, "paint", "Y", seg=14)
            cyl((xx, 1.06, 1.0 - i * 0.18), 0.2, 0.02, "dark", "Y", seg=14)
        canister(s * 2.65, 0.3, 1.0 - 0.45, 1.4, 0.08, 0.0)
        canister(s * 2.65, 0.3, 1.0 - 0.25, 1.4, 0.08, 0.0)
        box((s * 2.65, 0.3, 0.88), (0.08, 0.6, 0.2), "dark", bev=0.0)
        cyl((s * 0.8, 2.4, 0.3), 0.26, 0.18, "rubber", "X", seg=12)
        rod((s * 0.8, 2.4, 0.3), (s * 0.6, 2.2, 0.8), 0.04, "metal", 6)
        cyl((s * 1.3, -0.8, 0.3), 0.3, 0.2, "rubber", "X", seg=12)
        rod((s * 1.3, -0.8, 0.3), (s * 0.8, -0.6, 0.75), 0.05, "metal", 6)
    cyl((0, 4.3, 0.6), 0.22, 0.3, "dark", seg=10)
    cyl((0.25, 4.2, 0.85), 0.12, 0.3, "glass", seg=10)                                                    # nişan kulesi
    gun(4.3, 0.5, 0.8, 0.04, "gun") if not v.get("m") else gun(4.2, 0.5, 1.2, 0.05, "gun", x=0.3)
    slab(-2.2, -2.2, -9.0, -9.0, 1.4, 2.0, 0.42, 0.25, "paint", bev=0.012, wf=0.3)
    slab(-8.4, -8.8, -9.6, -9.4, 1.8, 3.4, 0.1, 0.08, "paint", bev=0.012)
    box((0, -7.8, 1.7), (2.4, 0.5, 0.06), "paint", bev=0.01)
    _heli_ru_bits(4.6, 1.0, -9.0, -1.8, 2.3, 0.75, -2.3, 1.3, 0.8)
    cyl((0, 0.0, 2.65), 0.15, 0.5, "metal", seg=10)
    node("rotor")
    blades(0, 0.0, 2.95, 5, 17.3, chord=0.55)
    node("trotor")
    tail_blades(-0.15, -9.4, 3.1, 3, 3.9, -1)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, 2.95), "trotor": (-0.15, -9.4, 3.1)}, {"muzzle": (0, 5.1, 0.5), "radius": 4.2}

def heli_mi8(v):
    from fam_air import blades, tail_blades, canopy
    mi38 = v.get("mi38", False)
    slab(4.0, 3.2, -3.0, -3.2, 0.5, 2.6, 1.15, 1.05, "paint", bev=0.012, wf=0.7)
    slab(4.9, 4.6, 4.0, 4.0, 0.6, 2.0, 0.85, 0.7, "paint", bev=0.012, wf=0.35)
    canopy(3.6, 4.85, 1.5, 2.4, 0.95)
    box((0, 4.3, 2.0), (0.05, 1.0, 0.8), "dark", bev=0.0)
    box((0, 1.0, 2.95), (1.6, 3.2, 0.7), "paint", bev=0.012)                                               # motor kaporta
    for s in (-1, 1):
        cyl((s * 0.45, 2.62, 2.95), 0.25, 0.06, "dark", "Y", seg=14)                                         # hava girişleri
        box((s * 0.45, 2.75, 2.95), (0.6, 0.3, 0.55), "metal", bev=0.008)                                     # toz filtresi
        seam((s * 0.81, 2.4, 2.8), (s * 0.81, -0.4, 2.8), (s, 0, 0))
        for k in range(5):
            cyl((s * 1.16, 2.2 - k * 1.0, 1.7), 0.21, 0.03, "trim", "X", seg=14)
            cyl((s * 1.17, 2.2 - k * 1.0, 1.7), 0.18, 0.04, "glass", "X", seg=14)                        # yuvarlak pencereler
        cyl((s * 1.1, 2.6, 0.3), 0.3, 0.2, "rubber", "X", seg=12)
        rod((s * 1.1, 2.6, 0.3), (s * 0.8, 2.6, 0.7), 0.05, "metal", 6)
        cyl((s * 1.2, -0.8, 0.3), 0.3, 0.2, "rubber", "X", seg=12)
        rod((s * 1.2, -0.8, 0.3), (s * 0.9, -0.8, 0.7), 0.05, "metal", 6)
        box((s * 1.2, -0.4, 0.8), (0.4, 1.8, 0.55), "paint", bev=0.012)                                    # yakıt deposu
        for t in (-0.6, 0.6):
            box((s * 1.2, -0.4 + t, 0.8), (0.42, 0.04, 0.57), "dark", bev=0.0)
        if v.get("armed"):
            box((s * 1.8, 0.6, 1.4), (1.4, 0.6, 0.1), "paint", bev=0.012)
            for i in range(2):
                xx = s * (1.6 + i * 0.6)
                box((xx, 0.6, 1.3), (0.08, 0.5, 0.15), "dark", bev=0.0)
                cyl((xx, 0.7, 1.15), 0.24, 1.5, "paint", "Y", seg=14)
                cyl((xx, 1.46, 1.15), 0.2, 0.02, "dark", "Y", seg=14)
    box((1.17, 3.0, 1.3), (0.03, 0.9, 1.4), "paint", bev=0.0)                                               # sürgülü kapı
    box((1.18, 3.0, 1.6), (0.02, 0.4, 0.35), "glass", bev=0.0)
    for s in (-1, 1):
        box((s * 0.5, -3.15, 1.2), (0.9, 0.04, 1.3), "paint", bev=0.0)                                     # arka kapaklar
    _heli_ru_bits(4.9, 1.2, -11.0, -0.8, 2.95, 0.85, -2.6, 1.4, 1.1)
    slab(-3.2, -3.2, -11.0, -11.0, 1.5, 2.5, 0.55, 0.25, "paint", bev=0.012, wf=0.35)
    slab(-10.3, -10.8, -11.6, -11.4, 2.0, 3.6, 0.12, 0.1, "paint", bev=0.012)
    box((0, -9.6, 1.9), (2.4, 0.55, 0.06), "paint", bev=0.01)
    cyl((0, 0.8, 3.4), 0.18, 0.5, "metal", seg=10)
    node("rotor")
    blades(0, 0.8, 3.7, 6 if mi38 else 5, 21.3, chord=0.55)
    node("trotor")
    tail_blades(0.18, -11.4, 3.3, 3, 3.9, 1)
    return {"body": (0, 0, 0), "rotor": (0, 0.8, 3.7), "trotor": (0.18, -11.4, 3.3)}, {"muzzle": (1.8, 1.4, 1.15), "radius": 5.0}

def _clear_turret():
    for k in ("turret", "barrel"):
        clear_node(k)

def bmpt(v):
    # tank gövdesi + iki 30 mm top ve dört füze tüplü alçak taret
    mbt_ru({"era": "relikt", "welded": True})
    _clear_turret()
    node("turret")
    zt = 1.45
    slab(1.3, 1.0, -1.3, -1.45, zt, zt + 0.6, 1.35, 1.2, "paint", bev=0.014, wf=0.8)
    R = zt + 0.6
    box((0.0, 0.2, zt + 0.85), (0.5, 0.5, 0.4), "paint", bev=0.012)
    box((0.0, 0.46, zt + 0.85), (0.3, 0.02, 0.2), "glass", bev=0.0)
    box((-0.6, -0.6, R + 0.15), (0.35, 0.35, 0.3), "paint", bev=0.01)
    box((-0.6, -0.42, R + 0.15), (0.22, 0.02, 0.14), "glass", bev=0.0)
    hatch(0.6, -0.6, R, 0.26)
    roof_panels(-1.1, 1.1, -1.3, 0.9, R + 0.003, 2, 2)
    for s in (-1, 1):
        era_brick((s * 1.3, 0.3, zt + 0.3), (0.1, 0.9, 0.45), nrm=(s, 0, 0))
        antenna(s * 0.9, -1.2, R, 1.4)
    node("barrel")
    bz = zt + 0.35
    for s in (-1, 1):
        gun(0.9, bz, 2.6, 0.045, "gun", sleeve=0.4, x=s * 0.4)
        box((s * 1.5, -0.2, bz + 0.15), (0.35, 1.6, 0.4), "paint", bev=0.012)
        for k in range(2):
            cyl((s * (1.42 + k * 0.17), 0.61, bz + 0.15), 0.07, 0.02, "dark", "Y", seg=10)
            cyl((s * (1.42 + k * 0.17), 0.6, bz + 0.15), 0.08, 0.02, "trim", "Y", seg=10)
    return {"body": (0, 0, 0), "turret": (0, 0, zt), "barrel": (0, 0.9, bz)}, {"muzzle": (0.4, 3.6, bz), "radius": 2.8}

def spg_truck(v):
    zd = truck_ru(4, True, True)
    for s in (-1, 1):
        stowage_box(s * 1.2, -0.3, zd + 0.2, 0.3, 0.9, 0.35, side=s)
    node("turret")
    tp = (0, -2.0, zd)
    box((0, -2.0, zd + 0.5), (2.2, 2.4, 1.0), "paint", bev=0.014)
    side_panels(1.1, -3.2, -0.8, zd + 0.1, zd + 0.95, 1, 3)
    side_panels(-1.1, -3.2, -0.8, zd + 0.1, zd + 0.95, -1, 3)
    roof_panels(-1.0, 1.0, -3.1, -0.9, zd + 1.003, 2, 2)
    hatch(0.6, -2.6, zd + 1.0, 0.26)
    node("barrel")
    bz = zd + 0.8
    box((0, -1.2, bz), (0.6, 0.6, 0.5), "paint", bev=0.012)
    gun(-1.0, bz, 7.0, 0.1, "paint", brake=True, sleeve=0.7, bands=2)
    box((0, -4.2, 0.5), (2.0, 0.25, 0.8), "paint", rot=(0.5, 0, 0), bev=0.012)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.2, bz)}), {"muzzle": (0, 6.4, bz), "radius": 2.9}

def truck_cargo(v):
    zd = truck_ru(3, False, False)
    # kasa: taban, yan kapaklar (tahta çıtalı), branda + kemerler + bağlama ipleri
    box((0, -1.6, zd + 0.35), (2.4, 4.0, 0.12), "paint", bev=0.008)
    for s in (-1, 1):
        box((s * 1.18, -1.6, zd + 0.75), (0.06, 4.0, 0.7), "paint", bev=0.008)
        for k in range(3):
            box((s * 1.215, -1.6, zd + 0.5 + k * 0.2), (0.012, 3.95, 0.03), "trim", bev=0.0)
        for k in range(5):
            box((s * 1.22, -3.4 + k * 0.9, zd + 0.75), (0.03, 0.06, 0.7), "metal", bev=0.0)
    box((0, -1.6, zd + 1.45), (2.45, 4.05, 1.3), "canvas", bev=0.012)
    for k in range(5):
        box((0, -3.4 + k * 0.9, zd + 2.11), (2.47, 0.05, 0.03), "canvas", bev=0.0)                         # kemer izleri
        for s in (-1, 1):
            box((s * 1.236, -3.4 + k * 0.9, zd + 1.45), (0.012, 0.04, 1.28), "canvas", bev=0.0)
    for s in (-1, 1):
        for k in range(8):
            box((s * 1.232, -3.5 + k * 0.54, zd + 0.85), (0.02, 0.025, 0.12), "dark", bev=0.0)            # bağlama ipleri
    box((0, 0.36, zd + 0.75), (2.4, 0.06, 0.7), "paint", bev=0.008)
    box((0, -3.62, zd + 0.75), (2.4, 0.06, 0.7), "paint", bev=0.008)
    box((0, -3.65, zd + 1.45), (2.3, 0.02, 1.25), "canvas", bev=0.0)
    spare_wheel(0, 0.55, zd + 1.0, 0.55, 0.4, "Y")
    return wheel_pivots({"body": (0, 0, 0)}), {"radius": 2.4}

FAMILIES = {"bmpt": bmpt, "spg_truck": spg_truck, "truck_cargo": truck_cargo, "mbt_ru": mbt_ru, "mbt_t14": mbt_t14, "apc_btr": apc_btr, "apc_mtlb": apc_mtlb, "ifv_bmp": ifv_bmp, "ifv_bmd": ifv_bmd,
            "ifv_heavy": ifv_heavy, "spg_ru": spg_ru, "mlrs_ru": mlrs_ru, "mlrs_tos": mlrs_tos, "missile_ru": missile_ru,
            "sam_ru_long": sam_ru_long, "sam_ru_tr": sam_ru_tr, "sam_ru_truck": sam_ru_truck,
            "heli_coax": heli_coax, "heli_hind": heli_hind, "heli_mi8": heli_mi8}
