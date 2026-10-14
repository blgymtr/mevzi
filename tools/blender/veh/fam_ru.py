# Doğu bloku (Rusya) aileleri. Ortak parçalar vlib'den; tasarım dili: alçak kubbe/köşeli taret, reaktif zırh,
# büyük yol tekerleri + üst makaralar, tekne burunlu tekerlekli araçlar, kaputlu kamyon kabini.
import math
from vlib import *

# ------------------------------------------------------------ yardımcılar
def ru_tracks(L, xc, tw, n, r, zt, rollers=3, front_idler=True):
    y0 = L / 2 - 0.55
    y1 = -L / 2 + 0.75
    wy = [y0 - i * (y0 - y1) / (n - 1) for i in range(n)]
    ry = [y0 - (i + 0.5) * (y0 - y1) / rollers for i in range(rollers)] if rollers else ()
    running_gear(xc, tw, wy, r, L / 2 - 0.15, -L / 2 + 0.2, 0.28, 0.31, z_top_run=2 * r + 0.14, rollers_y=ry)
    return wy

def kontakt_rows(x0, x1, y, z, rows=2, pitch=-0.95, n=6):
    """Ön zırh üzerinde reaktif zırh tuğla sıraları (glacis)."""
    for rr in range(rows):
        for i in range(n):
            x = x0 + (x1 - x0) * (i + 0.5) / n
            box((x, y - rr * 0.32, z + rr * 0.12), ((x1 - x0) / n * 0.9, 0.3, 0.1), "paint", rot=(pitch, 0, 0), bev=0.008)

def fuel_drums(y, z, W):
    for s in (-1, 1):
        cyl((s * W * 0.25, y, z), 0.3, 0.9, "paint", "X", seg=14)

def cage(y0, y1, z, w, h):
    """Kafes zırh (taret üstü) — ince çubuk ızgara."""
    for s in (-1, 1):
        for y in (y0, (y0 + y1) / 2, y1):
            box((s * w, y, z + h / 2), (0.04, 0.04, h), "dark", bev=0.0)
    for k in range(6):
        x = -w + k * (2 * w) / 5
        box((x, (y0 + y1) / 2, z + h), (0.03, abs(y1 - y0), 0.03), "dark", bev=0.0)
    for k in range(5):
        y = y0 + k * (y1 - y0) / 4
        box((0, y, z + h), (2 * w, 0.03, 0.03), "dark", bev=0.0)

def hood_cab(y, zb, w=2.4):
    """Kaputlu kamyon kabini (Ural tipi)."""
    slab(y + 2.2, y + 2.1, y + 0.9, y + 0.9, zb, zb + 0.95, w / 2 - 0.25, w / 2 - 0.35, "paint", wf=w / 2 - 0.45)   # kaput
    box((0, y + 2.25, zb + 0.4), (w * 0.6, 0.12, 0.6), "dark", bev=0.008)                                           # ızgara
    for s in (-1, 1):
        box((s * (w / 2 - 0.15), y + 1.6, zb + 0.55), (0.4, 1.3, 0.15), "paint", rot=(0.25, 0, 0), bev=0.008)        # çamurluk
        light(s * (w / 2 - 0.3), y + 2.25, zb + 0.75)
    slab(y + 0.95, y + 0.75, y - 0.6, y - 0.6, zb, zb + 1.7, w / 2, w / 2 - 0.1, "paint", bev=0.008)
    box((0, y + 0.85, zb + 1.3), (w * 0.82, 0.04, 0.5), "glass", rot=(-0.2, 0, 0), bev=0.0)
    for s in (-1, 1):
        box((s * (w / 2 - 0.02), y + 0.15, zb + 1.3), (0.03, 0.8, 0.45), "glass", bev=0.0)

def truck_ru(n_ax=3, kamaz=False, big=False):
    if big:
        ax = [3.0, 1.6, -1.4, -2.8]
        wheels_axles(ax, 1.25, 0.68, 0.48, "dark")
    else:
        ax = [2.5, -0.6, -2.0] if n_ax == 3 else [2.5, -1.5]
        wheels_axles(ax, 1.08, 0.6, 0.42, "dark")
    zb = 0.8 if not big else 0.95
    box((0, -0.3, zb + 0.1), (1.0, 7.2 if big else 6.6, 0.3), "dark", bev=0.0)
    if kamaz or big:
        cab(2.9 if big else 2.45, zb + 0.15, 2.5 if not big else 2.8, 2.0 if not big else 2.4, 1.75)
    else:
        hood_cab(1.6, zb + 0.15)
    for s in (-1, 1):
        box((s * 1.25, 0.5, zb + 0.45), (0.15, 0.7, 0.45), "paint", bev=0.008)
    return zb + 0.3

# ------------------------------------------------------------ tanklar
def mbt_ru(v):
    t80 = v.get("t80", False)
    welded = v.get("welded", False)
    era = v.get("era", "k1")
    L, W, zt = 6.9, 3.5, 1.45
    ru_tracks(L, 1.42, 0.58, 6, 0.36 if not t80 else 0.32, zt, rollers=3 if not t80 else 5)
    poly_extrude_x([(L / 2, 0.95), (L / 2 - 0.4, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    poly_extrude_x([(L / 2 - 1.5, zt), (L / 2 + 0.05, 1.0), (L / 2 + 0.05, 0.92), (-L / 2, 0.92), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    # glacis reaktif zırh + dozer bıçağı
    if era in ("k5", "relikt"):
        kontakt_rows(-1.55, 1.55, L / 2 - 0.55, 1.15, 2, -1.15, 7)
    else:
        kontakt_rows(-1.4, 1.4, L / 2 - 0.6, 1.1, 2, -1.15, 8)
    box((0, L / 2 + 0.15, 0.55), (2.8, 0.15, 0.4), "paint", rot=(-0.3, 0, 0), bev=0.008)
    # yan etek (lastik + reaktif zırh panelleri ön yarıda)
    for s in (-1, 1):
        box((s * 1.78, 0.1, 0.92), (0.04, L - 0.8, 0.45), "rubber", bev=0.0)
        for k in range(5 if era != "k1" else 4):
            box((s * 1.82, L / 2 - 0.85 - k * 0.62, 0.92), (0.1, 0.58, 0.5), "paint", bev=0.008)
        box((s * 1.6, -1.0, zt + 0.15), (0.35, 2.6, 0.3), "paint", bev=0.008)                     # çamurluk yakıt kutuları
        light(s * 1.3, L / 2 - 0.4, zt - 0.05)
    fuel_drums(-L / 2 - 0.4, 1.2, W)
    hatch(0, L / 2 - 1.55, zt, 0.26)
    grille(0, -2.3, zt + 0.01, 2.2, 1.4, 8)
    # ---------------- taret
    node("turret")
    tz = zt
    if welded:
        pts = []
        for s in (-1, 1):
            for (x, y, h) in ((0.45, 1.85, 0.0), (1.45, 1.3, 0.0), (1.55, -0.6, 0.0), (1.2, -1.45, 0.0)):
                pts += [(s * x, y, tz), (s * x * 0.82, y * 0.88, tz + 0.72)]
        hull_pts(pts, "paint", bev=0.008)
    else:
        # dökme kubbe taret
        pts = []
        for k in range(16):
            a = k * math.tau / 16
            rx, ry = 1.45, 1.55
            pts.append((math.cos(a) * rx, math.sin(a) * ry * (1.1 if math.sin(a) > 0 else 0.9), tz))
            pts.append((math.cos(a) * rx * 0.72, math.sin(a) * ry * 0.7, tz + 0.62))
            pts.append((math.cos(a) * rx * 0.35, math.sin(a) * ry * 0.35, tz + 0.78))
        hull_pts(pts, "paint", bev=0.0)
    # taret ön reaktif zırh "kaşları"
    for s in (-1, 1):
        for k in range(3):
            box((s * (0.55 + k * 0.32), 1.55 - k * 0.12, tz + 0.5), (0.3, 0.55, 0.14), "paint", rot=(0.35, 0, s * (0.35 + k * 0.08)), bev=0.008)
    if v.get("bustle"):
        box((0, -1.65, tz + 0.4), (2.0, 0.7, 0.55), "paint", bev=0.008)
    # komutan kubbesi + makineli / RWS, nişangâhlar, şnorkel, sis atarlar
    if v.get("rws"):
        rws(-0.55, -0.1, tz + 0.7, True, True)
    else:
        cyl((-0.55, -0.1, tz + 0.78), 0.35, 0.18, "paint", seg=12)
        mg(-0.55, 0.15, tz + 1.0, 0.0, 1.1, True)
    hatch(0.55, -0.3, tz + 0.7, 0.28)
    box((0.6, 0.85, tz + 0.82), (0.32, 0.4, 0.3), "paint", bev=0.008)
    cyl((-0.3, -1.6, tz + 0.55), 0.1, 1.8, "paint", "X", seg=8)                                  # şnorkel
    for s in (-1, 1):
        for k in range(4):
            a = 0.7 + k * 0.18
            cyl((s * (0.95 + k * 0.1), 0.9 - k * 0.22, tz + 0.55), 0.04, 0.2, "dark", rot=(math.pi / 2 - 0.3, 0, s * -a), seg=6)
        if welded and not v.get("rws"):
            box((s * 0.75, 1.75, tz + 0.35), (0.25, 0.15, 0.2), "red", bev=0.008)                 # IR karıştırıcı
        antenna(s * 0.7, -1.1, tz + 0.65, 1.5)
    if v.get("cage"):
        cage(-1.3, 1.5, tz + 0.8, 1.4, 0.7)
    # ---------------- namlu
    node("barrel")
    bz = tz + 0.42
    by = 1.7 if welded else 1.6
    box((0, by, bz), (0.55, 0.3, 0.42), "paint", bev=0.008)
    gun(by + 0.1, bz, 5.2, 0.09, "paint", sleeve=0.0)
    for f in (0.3, 0.55, 0.8):
        cyl((0, by + 0.1 + 5.2 * f, bz), 0.12, 0.25, "paint", "Y", seg=12)                       # ısı kılıfı bantları
    pivots = {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, by, bz)}
    return pivots, {"muzzle": (0, by + 5.4, bz), "radius": 2.8}

def mbt_t14(v):
    L, W, zt = 8.6, 3.5, 1.7
    ru_tracks(L, 1.45, 0.58, 7, 0.36, zt, rollers=0)
    poly_extrude_x([(L / 2, 1.1), (L / 2 - 0.5, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    poly_extrude_x([(L / 2 - 1.8, zt), (L / 2 + 0.05, 1.15), (L / 2 + 0.05, 0.95), (-L / 2, 0.95), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    for s in (-1, 1):
        for k in range(7):
            box((s * 1.8, L / 2 - 0.8 - k * 1.05, 1.05), (0.1, 1.0, 0.75), "paint", bev=0.008)
        light(s * 1.3, L / 2 - 0.3, 1.25)
    for k in range(10):                                                                            # arka kafes zırh
        box((-1.6 + k * 0.36, -L / 2 - 0.25, 1.2), (0.04, 0.04, 0.8), "dark", bev=0.0)
    hatch(-0.4, L / 2 - 1.6, zt, 0.28); hatch(0.4, L / 2 - 1.6, zt, 0.28)
    node("turret")
    tz = zt
    slab(1.7, 1.2, -1.8, -1.9, tz, tz + 0.75, 1.2, 1.0, "paint", bev=0.008, wf=0.55)
    rws(0.0, -0.8, tz + 0.75, True, True)
    box((0.7, 0.4, tz + 0.95), (0.35, 0.35, 0.32), "paint", bev=0.008)
    box((-0.7, 0.4, tz + 0.95), (0.35, 0.35, 0.32), "paint", bev=0.008)
    for s in (-1, 1):
        aps(s * 1.25, -0.3, tz + 0.45, s)
        antenna(s * 0.9, -1.6, tz + 0.75, 1.4)
    node("barrel")
    bz = tz + 0.45
    box((0, 1.75, bz), (0.5, 0.3, 0.35), "paint", bev=0.008)
    gun(1.85, bz, 5.6, 0.09, "paint", sleeve=0.6)
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
    hull_pts(pts, "paint", bev=0.008)
    for s in (-1, 1):
        box((s * (W / 2 - 0.02), 0.35, zb + 0.6), (0.06, 0.9, 0.75), "paint", bev=0.008)              # yan kapı
        for k in range(3):
            box((s * (W / 2 - 0.12), -1.5 + k * 0.6, zb + 1.05), (0.04, 0.12, 0.12), "dark", bev=0.0)  # atış delikleri
        light(s * 0.55, L / 2 + 0.05, zb + 0.4)
    box((0, L / 2 - 1.2, zt - 0.05), (1.6, 0.04, 0.4), "glass", rot=(-0.9, 0, 0), bev=0.0)
    grille(0, -2.3, zt + 0.01, 1.6, 1.2, 7)
    node("turret")
    tz = zt
    ty = 0.9
    if v.get("nona"):
        slab(ty + 1.0, ty + 0.8, ty - 1.0, ty - 1.1, tz, tz + 0.6, 0.95, 0.8, "paint", wf=0.6)
        node("barrel")
        gun(ty + 0.8, tz + 0.35, 1.6, 0.09, "paint")
        return wheel_pivots({"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.8, tz + 0.35)}), {"muzzle": (0, ty + 2.5, tz + 0.35), "radius": 2.8}
    cyl((0, ty, tz + 0.25), 0.6, 0.5, "paint", seg=10, r2=0.45)
    box((0.35, ty + 0.35, tz + 0.55), (0.2, 0.2, 0.18), "paint", bev=0.008)
    if v.get("gun30"):
        for s in (-1, 1):
            smoke_launchers(s * 0.55, ty - 0.1, tz + 0.35, s * 1.2, 3, s)
    node("barrel")
    bz = tz + 0.3
    gun(ty + 0.4, bz, 2.2 if v.get("gun30") else 1.6, 0.045 if v.get("gun30") else 0.04, "dark", sleeve=0.3)
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.4, bz)}), {"muzzle": (0, ty + 2.7, bz), "radius": 2.8}

def apc_mtlb(v):
    L, W, zt = 6.4, 2.85, 1.55
    ru_tracks(L, 1.18, 0.38, 6, 0.3, zt, rollers=0)
    poly_extrude_x([(L / 2 - 0.9, zt), (L / 2 + 0.05, 0.9), (L / 2 + 0.05, 0.75), (-L / 2, 0.75), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    box((0, L / 2 - 0.6, zt - 0.2), (1.8, 0.04, 0.3), "glass", rot=(-1.0, 0, 0), bev=0.0)
    if v.get("gmz"):
        box((0, -1.2, zt + 0.35), (2.4, 3.0, 0.7), "paint", bev=0.008)                                 # mayın deposu
        box((0, -L / 2 - 0.6, 0.6), (0.5, 1.4, 0.3), "metal", rot=(0.5, 0, 0), bev=0.008)              # döşeme oluğu
    for s in (-1, 1):
        box((s * (W / 2 - 0.3), -1.5, zt + 0.12), (0.5, 2.2, 0.24), "paint", bev=0.008)
        light(s * 0.9, L / 2 + 0.02, 0.95)
    hatch(0.5, -2.0, zt, 0.3); hatch(-0.5, -2.0, zt, 0.3)
    node("turret")
    if v.get("atgm"):
        tp = (0.0, -0.4, zt)
        cyl((0, -0.4, zt + 0.15), 0.45, 0.3, "paint", seg=10)
        node("barrel")
        canister(0.0, 0.1, zt + 0.7, 1.4, 0.1, 0.1)
        box((0, -0.4, zt + 0.6), (0.4, 0.5, 0.3), "paint", bev=0.008)
        return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.4, zt + 0.65)}, {"muzzle": (0, 0.8, zt + 0.75), "radius": 2.6}
    tp = (-0.75, L / 2 - 1.3, zt)
    cyl((tp[0], tp[1], zt + 0.2), 0.42, 0.4, "paint", seg=10, r2=0.32)
    node("barrel")
    mg(tp[0], tp[1] + 0.4, zt + 0.25, 0.0, 0.9, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (tp[0], tp[1] + 0.3, zt + 0.25)}, {"muzzle": (tp[0], tp[1] + 1.3, zt + 0.25), "radius": 2.6}

def _bmp_hull(L, W, zt, ribbed=True):
    ru_tracks(L, W / 2 - 0.3, 0.42, 6, 0.36, zt, rollers=3)
    # alçak, keskin burunlu tekne gövde
    poly_extrude_x([(L / 2 - 2.2, zt), (L / 2 + 0.25, 0.95), (L / 2 - 0.3, 0.5), (-L / 2 + 0.2, 0.5), (-L / 2, 0.8), (-L / 2, zt)], -W / 2 + 0.05, W / 2 - 0.05, "paint", bev=0.008)
    if ribbed:
        for k in range(5):
            box((0, L / 2 - 0.5 - k * 0.3, 1.05 + k * 0.12), (W - 0.4, 0.06, 0.05), "paint", rot=(-0.4, 0, 0), bev=0.0)
    for s in (-1, 1):
        light(s * 0.9, L / 2 - 0.2, 1.05)
    box((0, -L / 2 - 0.02, 0.95), (1.6, 0.06, 0.65), "paint", bev=0.008)                              # arka kapılar

def ifv_bmp(v):
    bmp3 = v.get("bmp3", False)
    L, W, zt = (6.75, 3.15, 1.6) if not bmp3 else (7.1, 3.2, 1.75)
    _bmp_hull(L, W, zt, not bmp3)
    hatch(-0.85, L / 2 - 1.9, zt, 0.24)
    node("turret")
    tz = zt
    if v.get("atgm_launcher"):
        box((0, -0.8, tz + 0.2), (1.6, 1.8, 0.4), "paint", bev=0.008)
        node("barrel")
        for s in (-1, 1):
            canister(s * 0.5, -0.4, tz + 0.75, 2.0, 0.12, 0.15)
        cyl((0, -0.4, tz + 1.2), 0.35, 0.3, "paint", seg=12)
        return {"body": (0, 0, 0), "turret": (0, -0.8, tz), "barrel": (0, -0.6, tz + 0.75)}, {"muzzle": (0, 0.6, tz + 0.9), "radius": 2.9}
    # konik taret
    pts = []
    for k in range(12):
        a = k * math.tau / 12
        pts += [(math.cos(a) * 1.0, math.sin(a) * 1.0 + 0.0, tz), (math.cos(a) * 0.62, math.sin(a) * 0.62, tz + 0.55)]
    hull_pts(pts, "paint", bev=0.0)
    hatch(-0.35, -0.3, tz + 0.55, 0.22); hatch(0.35, -0.3, tz + 0.55, 0.22)
    box((0.5, 0.35, tz + 0.7), (0.22, 0.3, 0.22), "paint", bev=0.008)
    if v.get("atgm") or not bmp3:
        box((0, -0.1, tz + 0.75), (0.25, 1.4, 0.2), "paint", rot=(0.05, 0, 0), bev=0.008)               # üstte füze rayı
    if v.get("atgm"):
        for s in (-1, 1):
            box((s * 0.95, -0.2, tz + 0.4), (0.28, 1.2, 0.35), "paint", bev=0.008)
    for s in (-1, 1):
        smoke_launchers(s * 0.85, 0.3, tz + 0.3, s * 1.1, 3, s)
    node("barrel")
    bz = tz + 0.3
    if bmp3:
        gun(0.6, bz, 2.0, 0.08, "paint", sleeve=0.3)
        gun(0.6, bz, 2.3, 0.035, "dark", x=0.25)
        L2 = 2.6
    else:
        gun(0.6, bz, 2.4, 0.04, "dark", sleeve=0.4)
        L2 = 3.0
    return {"body": (0, 0, 0), "turret": (0, 0.0, tz), "barrel": (0, 0.6, bz)}, {"muzzle": (0, L2 + 0.1, bz), "radius": 2.9}

def ifv_bmd(v):
    L, W, zt = 6.1, 3.0, 1.5
    ru_tracks(L, 1.25, 0.36, 5, 0.33, zt, rollers=4)
    poly_extrude_x([(L / 2 - 1.6, zt), (L / 2 + 0.2, 0.95), (L / 2 - 0.25, 0.5), (-L / 2 + 0.2, 0.5), (-L / 2, 0.8), (-L / 2, zt)], -W / 2 + 0.05, W / 2 - 0.05, "paint", bev=0.008)
    for s in (-1, 1):
        light(s * 0.85, L / 2 - 0.1, 1.05)
    hatch(-0.6, L / 2 - 1.3, zt, 0.24)
    node("turret")
    tz = zt
    if v.get("apc"):
        box((0, -1.0, zt + 0.3), (2.4, 2.6, 0.6), "paint", bev=0.008)
        rws(0.5, -0.5, zt + 0.6, False, True)
        node("barrel")
        mg(0.45, -0.1, zt + 0.85, 0.0, 0.9, False)
        return {"body": (0, 0, 0), "turret": (0.5, -0.5, zt + 0.6), "barrel": (0.45, -0.3, zt + 0.85)}, {"muzzle": (0.45, 0.7, zt + 0.85), "radius": 2.6}
    if v.get("gun125"):
        pts = []
        for s in (-1, 1):
            for (x, y) in ((0.45, 1.4), (1.3, 1.0), (1.4, -0.9), (1.1, -1.5)):
                pts += [(s * x, y, tz), (s * x * 0.82, y * 0.88, tz + 0.6)]
        hull_pts(pts, "paint", bev=0.008)
        if v.get("rws"):
            rws(-0.5, -0.4, tz + 0.6, False, True)
        else:
            cyl((-0.5, -0.4, tz + 0.68), 0.3, 0.16, "paint", seg=12)
        for s in (-1, 1):
            smoke_launchers(s * 1.05, 0.6, tz + 0.35, s * 0.8, 4, s)
        node("barrel")
        bz = tz + 0.35
        box((0, 1.35, bz), (0.45, 0.3, 0.35), "paint", bev=0.008)
        gun(1.45, bz, 5.0, 0.085, "paint", sleeve=0.5)
        return {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, 1.35, bz)}, {"muzzle": (0, 6.5, bz), "radius": 2.6}
    if v.get("nona"):
        slab(1.0, 0.8, -1.0, -1.1, tz, tz + 0.55, 1.0, 0.85, "paint", wf=0.6)
        node("barrel")
        gun(0.8, tz + 0.3, 1.5, 0.09, "paint")
        return {"body": (0, 0, 0), "turret": (0, 0.2, tz), "barrel": (0, 0.8, tz + 0.3)}, {"muzzle": (0, 2.4, tz + 0.3), "radius": 2.6}
    pts = []
    for k in range(12):
        a = k * math.tau / 12
        pts += [(math.cos(a) * 0.95, math.sin(a) * 0.95, tz), (math.cos(a) * 0.6, math.sin(a) * 0.6, tz + 0.5)]
    hull_pts(pts, "paint", bev=0.0)
    node("barrel")
    gun(0.55, tz + 0.28, 1.9, 0.075, "paint", sleeve=0.3)
    gun(0.55, tz + 0.28, 2.2, 0.033, "dark", x=0.24)
    return {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, 0.55, tz + 0.28)}, {"muzzle": (0, 2.6, tz + 0.28), "radius": 2.6}

def ifv_heavy(v):
    light_ = v.get("light", False)
    L, W, zt = (9.5, 3.5, 1.9) if not light_ else (7.8, 3.3, 1.8)
    ru_tracks(L, 1.45, 0.56, 7 if not light_ else 7, 0.36, zt, rollers=0)
    poly_extrude_x([(L / 2 - 1.2, zt), (L / 2 + 0.05, 1.2), (L / 2 + 0.05, 0.95), (-L / 2, 0.95), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    poly_extrude_x([(L / 2, 1.1), (L / 2 - 0.5, 0.42), (-L / 2 + 0.2, 0.42), (-L / 2, 0.65), (-L / 2, zt)], -1.05, 1.05, "paint")
    for s in (-1, 1):
        for k in range(6):
            box((s * 1.8, L / 2 - 0.9 - k * (L - 1.6) / 6, 1.1), (0.1, (L - 1.6) / 6 - 0.04, 0.75), "paint", bev=0.008)
        light(s * 1.3, L / 2 - 0.2, 1.35)
    box((0, -L / 2 - 0.03, 1.4), (2.0, 0.06, 0.9), "paint", bev=0.008)
    node("turret")
    tz = zt
    ty = -0.6
    slab(ty + 1.1, ty + 0.9, ty - 1.0, ty - 1.1, tz, tz + 0.6, 1.0, 0.85, "paint", bev=0.008, wf=0.55)
    box((ty * 0 + 0.55, ty + 0.4, tz + 0.8), (0.3, 0.32, 0.25), "paint", bev=0.008)
    for s in (-1, 1):
        for k in range(2):
            canister(s * 1.15, ty + 0.1, tz + 0.3 + k * 0.24, 1.6, 0.1, 0.05)                         # yan füze tüpleri
    node("barrel")
    bz = tz + 0.32
    gun(ty + 1.0, bz, 2.4, 0.045, "dark", sleeve=0.45)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, ty + 0.95, bz)}, {"muzzle": (0, ty + 3.5, bz), "radius": 3.3}

# ------------------------------------------------------------ topçu
def spg_ru(v):
    small = v.get("small", False)
    lt = v.get("light", False)
    koal = v.get("koal", False)
    if lt:
        L, W, zt = 7.2, 2.85, 1.45
        ru_tracks(L, 1.2, 0.4, 7, 0.3, zt, rollers=0)
    else:
        L, W, zt = (7.15, 3.4, 1.5) if not small else (6.5, 3.2, 1.45)
        ru_tracks(L, 1.4, 0.55 if not small else 0.48, 6, 0.34, zt, rollers=5 if not small else 4)
    poly_extrude_x([(L / 2 - 1.1, zt), (L / 2 + 0.05, 0.95), (L / 2 + 0.05, 0.9), (-L / 2, 0.9), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    for s in (-1, 1):
        light(s * 1.1, L / 2 - 0.2, 1.1)
    hatch(-0.85, L / 2 - 1.0, zt, 0.24)
    node("turret")
    tz = zt
    ty = -0.9 if not lt else -0.8
    tw, tl, th = (1.6, 2.1, 1.2) if not (small or lt) else ((1.4, 1.8, 1.0) if small else (1.1, 1.4, 0.75))
    slab(ty + tl * 0.55, ty + tl * 0.45, ty - tl * 0.55, ty - tl * 0.6, tz, tz + th, tw, tw - 0.1, "paint", bev=0.008, wf=tw - 0.35)
    if not koal and not lt:
        cyl((-0.7, ty - 0.2, tz + th + 0.12), 0.35, 0.24, "paint", seg=12)
        mg(-0.7, ty + 0.05, tz + th + 0.35, 0.0, 1.0, True)
    if koal:
        box((0.6, ty + 0.3, tz + th + 0.15), (0.35, 0.4, 0.3), "paint", bev=0.008)
    for s in (-1, 1):
        smoke_launchers(s * (tw - 0.05), ty + tl * 0.35, tz + th * 0.6, s * 0.6, 4, s)
        box((s * (tw + 0.04), ty - 0.2, tz + th * 0.5), (0.08, 1.2, 0.5), "canvas", bev=0.008)
    node("barrel")
    bz = tz + th * 0.5
    by = ty + tl * 0.55
    Lb = 7.0 if not (small or lt) else (5.0 if small else 3.2)
    if v.get("short"):
        Lb = 2.2
    box((0, by + 0.1, bz), (0.55, 0.4, 0.45), "paint", bev=0.008)
    gun(by + 0.25, bz, Lb, 0.1 if not lt else 0.075, "paint", brake=True, sleeve=0.7 if Lb > 3 else 0.0)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, by, bz)}, {"muzzle": (0, by + Lb + 0.4, bz), "radius": 3.0}

def mlrs_ru(v):
    n = v.get("tubes", 40)
    big = v.get("big", False)
    zd = truck_ru(4 if v.get("eight") else 3, v.get("kamaz", False), big or v.get("eight", False))
    node("turret")
    tp = (0, -1.8, zd)
    cyl((0, -1.8, zd + 0.15), 0.7, 0.3, "paint", seg=12)
    node("barrel")
    # tüp demeti
    if n >= 40:
        cols, rows, r = 10, 4, 0.065
    elif n >= 16:
        cols, rows, r = 4, 4, 0.13
    else:
        cols, rows, r = 4, 3, 0.17
    pitch = 0.18
    for i in range(cols):
        for k in range(rows):
            x = (i - (cols - 1) / 2) * r * 2.2
            z = zd + 0.65 + k * r * 2.2
            canister(x, -1.6, z, 3.1 if not big else 4.6, r, pitch, "paint", seg=8)
    box((0, -2.8, zd + 0.55), (cols * r * 2.2 + 0.1, 0.25, 0.3), "dark", bev=0.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.0, zd + 0.7)}), {"muzzle": (0, 0.0, zd + 1.0), "radius": 2.6}

def mlrs_tos(v):
    pv, md = mbt_ru({"era": "k5"})
    # T-72 gövdesi; taret yerine büyük roket kutusu
    for k in list(NODES.keys()):
        if k in ("turret", "barrel"):
            for o in NODES[k]:
                bpy.data.objects.remove(o)
            NODES[k] = []
    node("turret")
    zt = 1.45
    box((0, -0.6, zt + 0.25), (2.2, 2.4, 0.5), "paint", bev=0.008)
    node("barrel")
    box((0, -0.6, zt + 1.3), (2.6, 4.4, 1.5), "paint", rot=(0.12, 0, 0), bev=0.008)
    for i in range(6):
        for k in range(4):
            off = Vector(((i - 2.5) * 0.4, 2.21, (k - 1.5) * 0.34))
            off.rotate(Euler((0.12, 0, 0)))
            cyl((off.x, -0.6 + off.y, zt + 1.3 + off.z), 0.13, 0.04, "dark", rot=(math.pi / 2 - 0.12, 0, 0), seg=10)
    return {"body": (0, 0, 0), "turret": (0, -0.6, zt), "barrel": (0, -2.6, zt + 1.0)}, {"muzzle": (0, 1.6, zt + 1.5), "radius": 2.8}

def missile_ru(v):
    zd = truck_ru(4, False, True)
    node("turret")
    tp = (0, -1.4, zd)
    box((0, -1.4, zd + 0.15), (2.4, 4.2, 0.3), "paint", bev=0.008)
    node("barrel")
    for s in (-1, 1):
        cyl((s * 0.55, -1.4, zd + 0.75), 0.47, 6.6, "paint", "Y", seg=14)
        cyl((s * 0.55, 1.95, zd + 0.75), 0.47, 0.6, "paint", "Y", seg=14, r2=0.1)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.5, zd + 0.6)}), {"muzzle": (0, 2.3, zd + 0.75), "radius": 2.8}

def sam_ru_long(v):
    zd = truck_ru(4, False, True)
    node("turret")
    tp = (0, -1.6, zd)
    box((0, -1.6, zd + 0.15), (2.4, 4.4, 0.3), "paint", bev=0.008)
    node("barrel")
    for i in range(2):
        for k in range(2):
            canister((i - 0.5) * 1.05, -1.4, zd + 0.85 + k * 1.0, 7.0, 0.42, 0.0, "paint", seg=14)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -4.5, zd + 1.0)}), {"muzzle": (0, 2.1, zd + 1.4), "radius": 3.0}

def sam_ru_tr(v):
    L, W, zt = 7.3, 3.25, 1.5
    ru_tracks(L, 1.35, 0.5, 6, 0.34, zt, rollers=3)
    poly_extrude_x([(L / 2 - 1.2, zt), (L / 2 + 0.05, 0.95), (L / 2 + 0.05, 0.9), (-L / 2, 0.9), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.008)
    for s in (-1, 1):
        light(s * 1.0, L / 2 - 0.2, 1.1)
    node("turret")
    tz = zt
    if v.get("tor"):
        slab(1.1, 1.0, -1.6, -1.7, tz, tz + 1.5, 1.35, 1.25, "paint", bev=0.008)
        box((0, -0.2, tz + 2.0), (1.6, 0.1, 1.0), "paint", rot=(0.3, 0, 0), bev=0.008)                    # arama radarı
        cyl((0, 1.2, tz + 0.8), 0.4, 0.5, "paint", "Y", seg=12)                                         # takip radarı
        node("barrel")
        box((0, -0.3, tz + 1.55), (1.0, 1.0, 0.08), "dark", bev=0.0)
        return {"body": (0, 0, 0), "turret": (0, -0.3, tz), "barrel": (0, -0.3, tz + 1.5)}, {"muzzle": (0, -0.3, tz + 1.6), "radius": 3.0}
    if v.get("tung"):
        slab(1.0, 0.8, -1.4, -1.5, tz, tz + 1.0, 1.25, 1.1, "paint", bev=0.008)
        cyl((0, -1.2, tz + 1.4), 0.9, 0.08, "paint", seg=16, rot=(0.4, 0, 0))                            # radar çanağı
        cyl((0, 1.0, tz + 0.9), 0.35, 0.4, "paint", "Y", seg=12)
        node("barrel")
        bz = tz + 0.65
        for s in (-1, 1):
            gun(0.6, bz, 2.6, 0.035, "dark", x=s * 1.35)
            gun(0.6, bz + 0.15, 2.6, 0.035, "dark", x=s * 1.35)
            for k in range(2):
                canister(s * 1.65, 0.0, bz + 0.4 + k * 0.22, 1.8, 0.09, 0.15)
        return {"body": (0, 0, 0), "turret": (0, -0.2, tz), "barrel": (0, 0.0, bz)}, {"muzzle": (1.35, 3.3, bz), "radius": 3.0}
    # Buk: döner platform, 4 füze rayı, ön radar
    cyl((0, -0.6, tz + 0.2), 1.2, 0.4, "paint", seg=14)
    box((0, 0.6, tz + 0.9), (1.4, 0.5, 1.1), "paint", bev=0.008)
    node("barrel")
    for i in range(4):
        x = (i - 1.5) * 0.5
        box((x, -0.8, tz + 1.0), (0.08, 3.6, 0.08), "metal", rot=(0.2, 0, 0), bev=0.0)
        cyl((x, -0.8, tz + 1.15), 0.2, 5.2, "trim", rot=(math.pi / 2 - 0.2, 0, 0), seg=10)
    return {"body": (0, 0, 0), "turret": (0, -0.6, tz), "barrel": (0, -2.5, tz + 0.8)}, {"muzzle": (0, 1.8, tz + 1.6), "radius": 3.0}

def sam_ru_truck(v):
    zd = truck_ru(4, True, True)
    node("turret")
    tp = (0, -1.8, zd)
    box((0, -1.8, zd + 0.65), (1.8, 1.8, 1.3), "paint", bev=0.008)
    box((0, -2.5, zd + 1.9), (1.3, 0.12, 1.0), "paint", rot=(0.25, 0, 0), bev=0.008)                     # arama radarı
    cyl((0, -1.0, zd + 1.0), 0.4, 0.3, "paint", "Y", seg=12)
    node("barrel")
    bz = zd + 0.9
    for s in (-1, 1):
        for k in range(2):
            for j in range(3):
                canister(s * (1.15 + j * 0.2), -1.6, bz + 0.15 + k * 0.22, 2.4, 0.09, 0.2)
        gun(-1.4, bz - 0.25, 2.6, 0.035, "dark", x=s * 1.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.6, bz)}), {"muzzle": (1.0, 1.2, bz - 0.25), "radius": 3.0}

# ------------------------------------------------------------ helikopterler
def heli_coax(v):
    from fam_air import blades, canopy, skids
    lt = v.get("light", False)
    util = v.get("utility", False)
    single = v.get("single", False)
    if lt:
        slab(1.6, 1.2, -1.2, -1.3, 0.4, 1.7, 0.7, 0.6, "paint", bev=0.008, wf=0.4)
        canopy(0.6, 1.7, 0.9, 1.6, 0.6)
        skids(2.6, 0.8)
        for s in (-1, 1):
            box((s * 0.6, -3.0, 1.3), (0.15, 3.6, 0.2), "paint", bev=0.008)                              # ikiz kuyruk kirişi
        box((0, -4.6, 1.5), (1.6, 0.4, 0.06), "paint", bev=0.0)
        mast = 2.2; R = 13.0; tail_y = -4.6
    elif util:
        slab(2.4, 2.0, -1.8, -2.0, 0.5, 2.3, 1.0, 0.9, "paint", bev=0.008, wf=0.6)
        canopy(1.6, 2.6, 1.3, 2.1, 0.85)
        slab(-2.0, -2.0, -4.6, -4.6, 1.2, 2.0, 0.55, 0.4, "paint", bev=0.008)
        box((0, -4.4, 2.0), (2.6, 0.5, 0.08), "paint", bev=0.008)
        for s in (-1, 1):
            box((s * 1.3, -4.4, 2.3), (0.08, 0.7, 1.0), "paint", bev=0.008)
            cyl((s * 1.0, 1.6, 0.25), 0.28, 0.18, "rubber", "X", seg=12)
        mast = 3.0; R = 15.8; tail_y = -4.6
    else:
        W = 0.55 if single else 0.85
        slab(2.6, 2.0, -1.6, -1.8, 0.55, 1.95, W, W - 0.1, "paint", bev=0.008, wf=W - 0.35)
        slab(3.6, 3.2, 2.6, 2.6, 0.65, 1.5, W - 0.2, W - 0.3, "paint", bev=0.008, wf=0.2)
        canopy(1.4, 3.2, 1.45, 2.05, W - 0.05)
        for s in (-1, 1):
            box((s * 0.75, -0.6, 1.95), (0.45, 2.0, 0.5), "paint", bev=0.008)                             # motor
            box((s * 1.4, 0.2, 1.1), (1.6, 0.7, 0.1), "paint", rot=(0, s * 0.1, 0), bev=0.008)          # kanatçık
            cyl((s * 1.3, 0.3, 0.85), 0.22, 1.6, "paint", "Y", seg=12)
            for i in range(2):
                cyl((s * (1.8 + i * 0.22), 0.35, 0.85), 0.09, 1.5, "paint", "Y", seg=8)
            cyl((s * 0.65, 1.8, 0.25), 0.25, 0.16, "rubber", "X", seg=12)
        gun(0.5, 1.0, 2.2, 0.035, "dark", x=0.75)                                                       # yan top
        slab(-1.6, -1.6, -6.5, -6.5, 1.1, 1.65, 0.35, 0.22, "paint", bev=0.008, wf=0.28)
        box((0, -6.0, 1.5), (2.0, 0.5, 0.06), "paint", bev=0.01)
        for s in (-1, 1):
            box((s * 1.0, -6.0, 1.9), (0.08, 0.6, 0.9), "paint", bev=0.008)
        mast = 2.6; R = 14.4; tail_y = -6.0
    cyl((0, 0.0, mast - 0.2), 0.14, 1.4, "metal", seg=8)
    node("rotor")
    blades(0, 0.0, mast, 3, R, chord=0.4)
    node("trotor")
    blades(0, 0.0, mast + 0.9, 3, R, chord=0.4, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, mast), "trotor": (0, 0.0, mast + 0.9)}, {"muzzle": (0.75, 2.8, 1.0), "radius": 3.6, "trotor_y": True}

def heli_hind(v):
    from fam_air import blades, tail_blades, canopy
    slab(2.8, 2.2, -2.0, -2.2, 0.6, 2.1, 0.85, 0.75, "paint", bev=0.008, wf=0.5)
    slab(4.6, 4.2, 2.8, 2.8, 0.7, 1.5, 0.5, 0.4, "paint", bev=0.008, wf=0.2)
    canopy(3.2, 4.5, 1.2, 1.8, 0.45)                                                                     # ön (nişancı)
    canopy(2.0, 3.2, 1.5, 2.2, 0.55)                                                                     # arka (pilot)
    for s in (-1, 1):
        box((s * 0.85, 0.0, 1.35), (0.04, 1.6, 0.6), "paint", bev=0.0)                                   # kabin kapısı
        box((s * 0.55, -0.6, 2.3), (0.5, 2.4, 0.55), "paint", bev=0.008)                                  # motor
        box((s * 1.7, 0.2, 1.3), (1.9, 0.9, 0.12), "paint", rot=(0, s * 0.25, 0), bev=0.008)             # kanat (aşağı eğik)
        for i in range(2):
            cyl((s * (1.2 + i * 0.75), 0.3, 1.0), 0.24, 1.5, "paint", "Y", seg=12)
        canister(s * 2.65, 0.3, 1.0, 1.4, 0.08, 0.0)
        cyl((s * 0.8, 2.4, 0.3), 0.26, 0.18, "rubber", "X", seg=12)
    cyl((0, 4.3, 0.6), 0.22, 0.3, "dark", seg=10)
    gun(4.3, 0.5, 0.8, 0.04, "dark") if not v.get("m") else gun(4.2, 0.5, 1.2, 0.05, "dark", x=0.3)
    slab(-2.2, -2.2, -9.0, -9.0, 1.4, 2.0, 0.42, 0.25, "paint", bev=0.008, wf=0.3)
    slab(-8.4, -8.8, -9.6, -9.4, 1.8, 3.4, 0.1, 0.08, "paint", bev=0.008)
    box((0, -7.8, 1.7), (2.4, 0.5, 0.06), "paint", bev=0.01)
    cyl((0, 0.0, 2.65), 0.15, 0.5, "metal", seg=8)
    node("rotor")
    blades(0, 0.0, 2.95, 5, 17.3, chord=0.55)
    node("trotor")
    tail_blades(-0.15, -9.4, 3.1, 3, 3.9, -1)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, 2.95), "trotor": (-0.15, -9.4, 3.1)}, {"muzzle": (0, 5.1, 0.5), "radius": 4.2}

def heli_mi8(v):
    from fam_air import blades, tail_blades, canopy
    mi38 = v.get("mi38", False)
    slab(4.0, 3.2, -3.0, -3.2, 0.5, 2.6, 1.15, 1.05, "paint", bev=0.008, wf=0.7)
    slab(4.9, 4.6, 4.0, 4.0, 0.6, 2.0, 0.85, 0.7, "paint", bev=0.008, wf=0.35)
    canopy(3.6, 4.85, 1.5, 2.4, 0.95)
    box((0, 1.0, 2.95), (1.6, 3.2, 0.7), "paint", bev=0.008)                                               # motor kaporta
    for s in (-1, 1):
        for k in range(5):
            cyl((s * 1.16, 2.2 - k * 1.0, 1.7), 0.18, 0.04, "glass", "X", seg=12)                        # yuvarlak pencereler
        cyl((s * 1.1, 2.6, 0.3), 0.3, 0.2, "rubber", "X", seg=12)
        cyl((s * 1.2, -0.8, 0.3), 0.3, 0.2, "rubber", "X", seg=12)
        box((s * 1.2, -0.4, 0.8), (0.4, 1.8, 0.55), "paint", bev=0.008)                                    # yakıt deposu
        if v.get("armed"):
            box((s * 1.8, 0.6, 1.4), (1.4, 0.6, 0.1), "paint", bev=0.008)
            for i in range(2):
                cyl((s * (1.6 + i * 0.6), 0.7, 1.15), 0.24, 1.5, "paint", "Y", seg=12)
    slab(-3.2, -3.2, -11.0, -11.0, 1.5, 2.5, 0.55, 0.25, "paint", bev=0.008, wf=0.35)
    slab(-10.3, -10.8, -11.6, -11.4, 2.0, 3.6, 0.12, 0.1, "paint", bev=0.008)
    box((0, -9.6, 1.9), (2.4, 0.55, 0.06), "paint", bev=0.01)
    cyl((0, 0.8, 3.4), 0.18, 0.5, "metal", seg=8)
    node("rotor")
    blades(0, 0.8, 3.7, 6 if mi38 else 5, 21.3, chord=0.55)
    node("trotor")
    tail_blades(0.18, -11.4, 3.3, 3, 3.9, 1)
    return {"body": (0, 0, 0), "rotor": (0, 0.8, 3.7), "trotor": (0.18, -11.4, 3.3)}, {"muzzle": (1.8, 1.4, 1.15), "radius": 5.0}

def _clear_turret():
    for k in ("turret", "barrel"):
        for o in NODES.get(k, []):
            bpy.data.objects.remove(o)
        NODES[k] = []

def bmpt(v):
    # tank gövdesi + iki 30 mm top ve dört füze tüplü alçak taret
    mbt_ru({"era": "relikt", "welded": True})
    _clear_turret()
    node("turret")
    zt = 1.45
    slab(1.3, 1.0, -1.3, -1.45, zt, zt + 0.6, 1.35, 1.2, "paint", bev=0.008, wf=0.8)
    box((0.0, 0.2, zt + 0.85), (0.5, 0.5, 0.4), "paint", bev=0.008)
    box((0.0, 0.46, zt + 0.85), (0.3, 0.02, 0.2), "glass", bev=0.0)
    node("barrel")
    bz = zt + 0.35
    for s in (-1, 1):
        gun(0.9, bz, 2.6, 0.045, "dark", sleeve=0.4, x=s * 0.4)
        box((s * 1.5, -0.2, bz + 0.15), (0.35, 1.6, 0.4), "paint", bev=0.008)
        for k in range(2):
            cyl((s * (1.42 + k * 0.17), 0.61, bz + 0.15), 0.07, 0.02, "dark", "Y", seg=8)
    return {"body": (0, 0, 0), "turret": (0, 0, zt), "barrel": (0, 0.9, bz)}, {"muzzle": (0.4, 3.6, bz), "radius": 2.8}

def spg_truck(v):
    zd = truck_ru(4, True, True)
    node("turret")
    tp = (0, -2.0, zd)
    box((0, -2.0, zd + 0.5), (2.2, 2.4, 1.0), "paint", bev=0.008)
    node("barrel")
    bz = zd + 0.8
    box((0, -1.2, bz), (0.6, 0.6, 0.5), "paint", bev=0.008)
    gun(-1.0, bz, 7.0, 0.1, "paint", brake=True, sleeve=0.7)
    box((0, -4.2, 0.5), (2.0, 0.25, 0.8), "paint", rot=(0.5, 0, 0), bev=0.008)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.2, bz)}), {"muzzle": (0, 6.4, bz), "radius": 2.9}

def truck_cargo(v):
    zd = truck_ru(3, False, False)
    box((0, -1.6, zd + 0.35), (2.4, 4.0, 0.12), "paint", bev=0.008)
    for s in (-1, 1):
        box((s * 1.18, -1.6, zd + 0.75), (0.06, 4.0, 0.7), "paint", bev=0.008)
    box((0, -1.6, zd + 1.45), (2.45, 4.05, 1.3), "canvas", bev=0.008)
    box((0, 0.36, zd + 0.75), (2.4, 0.06, 0.7), "paint", bev=0.008)
    return wheel_pivots({"body": (0, 0, 0)}), {"radius": 2.4}

FAMILIES = {"bmpt": bmpt, "spg_truck": spg_truck, "truck_cargo": truck_cargo, "mbt_ru": mbt_ru, "mbt_t14": mbt_t14, "apc_btr": apc_btr, "apc_mtlb": apc_mtlb, "ifv_bmp": ifv_bmp, "ifv_bmd": ifv_bmd,
            "ifv_heavy": ifv_heavy, "spg_ru": spg_ru, "mlrs_ru": mlrs_ru, "mlrs_tos": mlrs_tos, "missile_ru": missile_ru,
            "sam_ru_long": sam_ru_long, "sam_ru_tr": sam_ru_tr, "sam_ru_truck": sam_ru_truck,
            "heli_coax": heli_coax, "heli_hind": heli_hind, "heli_mi8": heli_mi8}
