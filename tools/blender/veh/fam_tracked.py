# Paletli aileler: kutu ZPT, AMPV/Bradley şasisi, amfibi, tanksavar, kundağı motorlu obüs, açık obüs,
# havan aracı, paletli roketatar, istihkâm (mayın açma, dozer, köprü, kurtarma).
import math
from vlib import *

def tracked(L, W, n, r, xc, tw, zt, nose=1.0, rear=0.15, glacis_z=None, sprocket_front=False, rollers=(), skirts=False):
    """Genel paletli şasi. L uzunluk, W gövde genişliği (paletler dahil), n yol tekeri, zt gövde üstü."""
    y0 = L / 2 - 0.45
    y1 = -L / 2 + 0.5
    wy = [y0 - 0.25 - i * (y0 - y1 - 0.5) / (n - 1) for i in range(n)]
    yf = y0 + 0.2
    yr = y1 - 0.15
    running_gear(xc, tw, wy, r, yf if not sprocket_front else yr, yr if not sprocket_front else yf, 0.27, 0.3, z_top_run=r * 2 + 0.28, rollers_y=rollers)
    zg = glacis_z if glacis_z is not None else zt - 0.45
    # alt gövde + üst gövde (yandan profil)
    poly_extrude_x([(L / 2, zg), (L / 2 - 0.35, 0.38), (-L / 2 + 0.2, 0.38), (-L / 2, 0.6), (-L / 2, zt)], -(xc - tw / 2 - 0.02), xc - tw / 2 - 0.02, "paint")
    poly_extrude_x([(L / 2 - nose, zt), (L / 2 + 0.05, zg), (L / 2 + 0.05, r * 2 + 0.25), (-L / 2, r * 2 + 0.25), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.03)
    for s in (-1, 1):
        light(s * (W / 2 - 0.3), L / 2 - 0.1, zg + 0.05)
        box((s * (W / 2 - 0.2), -L / 2 - 0.02, zt - 0.3), (0.14, 0.04, 0.1), "red", bev=0.0)
        if skirts:
            for k in range(4):
                Lp = (L - 0.8) / 4
                box((s * (W / 2 + 0.03), L / 2 - 0.6 - Lp * (k + 0.5), r * 2 + 0.05), (0.06, Lp - 0.03, 0.5), "paint", bev=0.015)
    return wy

def apc_box(v):
    # kutu gövdeli paletli ZPT: dik yanlar, eğik ön, arka rampa
    L, W, zt = 4.9, 2.7, 1.85
    tracked(L, W, 5, 0.3, 1.1, 0.4, zt, nose=0.9, rollers=())
    hatch(-0.55, 1.4, zt, 0.28)
    cyl((0.45, 0.4, zt + 0.12), 0.38, 0.24, "paint", seg=12, bev=0.02)
    box((0, -2.47, 1.05), (1.9, 0.06, 1.4), "paint", bev=0.02)                                 # rampa
    for k in range(5):
        box((0.6, 1.9 - k * 0.12, zt - 0.3), (0.9, 0.06, 0.04), "dark", rot=(-0.95, 0, 0), bev=0.0)   # dalga kırıcı çizgileri
    grille(-0.6, 1.2, zt + 0.01, 0.6, 0.6, 5)
    antenna(-1.1, -2.1, zt, 1.8); antenna(1.1, -2.1, zt, 1.8)
    for s in (-1, 1):
        jerrycan(s * 1.05, -2.5, 1.3)
    node("turret")
    tp = (0.45, 0.4, zt + 0.24)
    for k in range(3):
        a = math.pi * (0.3 + k * 0.2)
        box((0.45 + math.cos(a) * 0.4, 0.4 + math.sin(a) * 0.4, zt + 0.5), (0.4, 0.05, 0.45), "paint", rot=(0, 0, a - math.pi / 2), bev=0.01)
    node("barrel")
    mg(0.45, 0.8, zt + 0.55, 0.0, 1.1, True)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.45, 0.8, zt + 0.55)}, {"muzzle": (0.45, 1.9, zt + 0.55), "radius": 2.3}

def _bradley_hull(L=6.55, W=3.28, zt=2.0, era=False):
    tracked(L, W, 6, 0.32, 1.42, 0.53, zt, nose=1.3, glacis_z=1.25, sprocket_front=True, rollers=(1.4, -0.2, -1.8), skirts=True)
    hatch(-0.85, 2.3, zt - 0.05, 0.26)
    box((0, -L / 2 - 0.03, 1.3), (2.2, 0.06, 1.5), "paint", bev=0.02)                           # rampa
    grille(0.8, 2.0, zt - 0.1, 1.0, 0.6, 5)
    if era:
        for s in (-1, 1):
            era_grid(s * (W / 2 + 0.1), 0, -2.6, 2.4, 0.75, 1.55, s, nx=2, ny=10, depth=0.12)
            era_grid(s * (W / 2 - 0.15), 0, -2.0, 1.8, zt - 0.3, zt - 0.05, s, nx=1, ny=6, depth=0.1)
    for s in (-1, 1):
        box((s * 1.4, -2.8, zt + 0.15), (0.5, 0.6, 0.3), "canvas", bev=0.05)
    return zt

def apc_tr(v):
    zt = _bradley_hull(zt=2.15)
    box((0, -0.8, zt + 0.12), (2.6, 3.8, 0.24), "paint", bev=0.03)                             # yükseltilmiş tavan
    hatch(0.7, -2.2, zt + 0.24, 0.3)
    node("turret")
    tp = (0.4, 0.4, zt + 0.24)
    rws(0.4, 0.4, zt + 0.24, True, True)
    node("barrel")
    mg(0.35, 0.9, zt + 0.5, 0.0, 1.15, True)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.35, 0.7, zt + 0.5)}, {"muzzle": (0.35, 1.9, zt + 0.5), "radius": 2.7}

def ifv_tr(v):
    zt = _bradley_hull(era=v.get("era", False))
    node("turret")
    tz = zt
    # iki kişilik taret: eğimli ön, yanlarda TOW kutusu (sol)
    slab(1.15, 0.85, -1.15, -1.3, tz, tz + 0.75, 1.0, 0.85, "paint", wf=0.6)
    box((0.6, 0.55, tz + 0.95), (0.4, 0.45, 0.35), "paint", bev=0.02)                          # nişangâh
    box((0.6, 0.79, tz + 0.95), (0.3, 0.02, 0.18), "glass", bev=0.0)
    if v.get("scout") or True:
        box((-0.5, -0.4, tz + 0.95), (0.35, 0.35, 0.3), "paint", bev=0.02)                     # komutan bağımsız görüş
    hatch(-0.45, -0.7, tz + 0.75, 0.26); hatch(0.45, -0.75, tz + 0.75, 0.26)
    box((-1.2, -0.1, tz + 0.55), (0.42, 1.4, 0.5), "paint", bev=0.03)                          # TOW kutusu
    for s in (-1, 1):
        box((-1.2 + s * 0.1, 0.61, tz + 0.55), (0.16, 0.02, 0.36), "dark", bev=0.0)
    for s in (-1, 1):
        smoke_launchers(s * 0.95, 0.75, tz + 0.5, s * 0.5, 4, s)
    antenna(-0.8, -1.1, tz + 0.75, 1.6); antenna(0.8, -1.1, tz + 0.75, 1.6)
    node("barrel")
    bz = tz + 0.4
    box((0, 1.15, bz), (0.42, 0.3, 0.34), "paint", bev=0.02)
    gun(1.25, bz, 2.1, 0.045, "dark", sleeve=0.45)
    mg(0.25, 1.4, bz - 0.05, 0.0, 0.6, False)
    return {"body": (0, 0, 0), "turret": (0, 0.1, tz), "barrel": (0, 1.1, bz)}, {"muzzle": (0, 3.4, bz), "radius": 2.8}

def apc_amph(v):
    # amfibi hücum aracı: yüksek tekne gövde, eğik burun, sağ önde küçük silah kulesi
    L, W, zt = 8.0, 3.27, 2.7
    tracked(L, W, 6, 0.32, 1.35, 0.53, zt, nose=1.6, glacis_z=1.3, rollers=(1.2, -1.2))
    slab(L / 2 + 0.35, L / 2 - 0.9, L / 2 - 1.1, L / 2 - 0.1, 0.6, 1.4, W / 2 - 0.1, W / 2 - 0.05, "paint")    # tekne burnu
    hatch(-0.9, 1.9, zt, 0.28)
    box((0, -L / 2 - 0.03, 1.6), (2.4, 0.06, 1.9), "paint", bev=0.02)
    for s in (-1, 1):
        for k in range(3):
            box((s * (W / 2 + 0.01), -1.5 + k * 1.2, zt - 0.5), (0.04, 0.3, 0.25), "dark", bev=0.0)
    node("turret")
    tp = (0.8, 1.6, zt)
    cyl((0.8, 1.6, zt + 0.25), 0.55, 0.5, "paint", seg=10, bev=0.02)
    node("barrel")
    gun(1.9, zt + 0.3, 0.9, 0.05, "dark", x=1.0)
    gun(1.9, zt + 0.3, 0.5, 0.07, "dark", x=0.6)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.8, 1.9, zt + 0.3)}, {"muzzle": (1.0, 2.9, zt + 0.3), "radius": 3.0}

def td_box(v):
    pv, md = apc_box(v)
    # TOW "çekiç başı" fırlatıcı: kaldırılmış ikiz kutu
    node("turret")
    zt = 1.85
    cyl((0.45, -0.6, zt + 0.25), 0.18, 0.5, "metal", seg=8)
    node("barrel")
    box((0.45, -0.5, zt + 0.7), (1.0, 0.55, 0.5), "paint", bev=0.03)
    for s in (-1, 1):
        box((0.45 + s * 0.28, -0.22, zt + 0.7), (0.3, 0.02, 0.36), "dark", bev=0.0)
    pv["barrel"] = (0.45, -0.5, zt + 0.7)
    md["muzzle"] = (0.45, 0.4, zt + 0.7)
    return pv, md

def td_ontos(v):
    L, W, zt = 3.8, 2.6, 1.6
    tracked(L, W, 4, 0.3, 1.05, 0.38, zt, nose=0.7)
    node("turret")
    tp = (0, 0.1, zt)
    box((0, 0.0, zt + 0.15), (0.8, 0.8, 0.3), "paint", bev=0.03)
    node("barrel")
    for s in (-1, 1):
        for k in range(3):
            gun(-0.4, zt + 0.35 + k * 0.22, 2.5, 0.07, "paint", x=s * 0.55)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.3, zt + 0.55)}, {"muzzle": (0.55, 2.1, zt + 0.55), "radius": 2.0}

def spg(v):
    a7 = v.get("a7", False)
    old = v.get("old", False)
    L, W, zt = (6.2, 3.2, 1.5) if not a7 else (6.4, 3.3, 1.55)
    tracked(L, W, 7 if not a7 else 6, 0.3, 1.38, 0.4 if not a7 else 0.5, zt, nose=1.0, glacis_z=1.05, sprocket_front=True)
    hatch(-0.9, 2.2, zt, 0.26)
    grille(-0.8, 1.7, zt + 0.01, 1.0, 0.7, 5)
    node("turret")
    ty = -0.6 if not old else -1.3
    tz = zt
    slab(1.4, 1.3, -1.9, -1.95, tz, tz + 1.15, 1.45, 1.35, "paint", bev=0.04)                   # büyük kutu taret
    box((0, -1.97, tz + 0.65), (2.0, 0.06, 0.9), "paint", bev=0.02)                              # arka kapak
    cyl((0.85, -0.3, tz + 1.25), 0.36, 0.2, "paint", seg=12)
    mg(0.85, 0.0, tz + 1.45, 0.0, 1.1, True)
    hatch(-0.7, -0.5, tz + 1.15, 0.28)
    for s in (-1, 1):
        box((s * 1.5, -0.6, tz + 0.55), (0.1, 1.8, 0.7), "canvas", bev=0.05)
        box((s * 1.45, 1.35, tz + 0.5), (0.25, 0.25, 0.35), "paint", bev=0.02)
    node("barrel")
    bz = tz + 0.65
    box((0, 1.45, bz), (0.6, 0.4, 0.55), "paint", bev=0.03)
    gun(1.6, bz, 5.6 if not old else 3.2, 0.1, "paint", brake=True, sleeve=0.6)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, 1.4, bz)}, {"muzzle": (0, 7.3 if not old else 4.9, bz), "radius": 2.9}

def spg_open(v):
    cal = v.get("cal", 203)
    L, W, zt = 5.7, 3.15, 1.4
    tracked(L, W, 5, 0.38, 1.3, 0.46, zt, nose=0.9, sprocket_front=True)
    box((0, -L / 2 - 0.4, 0.55), (2.6, 0.25, 0.9), "paint", rot=(0.6, 0, 0), bev=0.02)         # geri tepme pençesi
    for s in (-1, 1):
        box((s * 0.95, -1.6, zt + 0.35), (0.6, 0.6, 0.7), "paint", bev=0.03)                    # mürettebat koltukları
    node("turret")
    tz = zt
    box((0, -1.0, tz + 0.25), (1.6, 1.6, 0.5), "paint", bev=0.03)
    node("barrel")
    bz = tz + 0.85
    box((0, -1.0, bz), (0.9, 1.4, 0.7), "paint", bev=0.03)
    if cal == 203:
        gun(-0.3, bz, 5.2, 0.17, "paint", sleeve=1.0)
    else:
        gun(-0.3, bz, 9.5, 0.11, "paint", sleeve=1.0)
    L2 = 5.2 if cal == 203 else 9.5
    return {"body": (0, 0, 0), "turret": (0, -1.0, tz), "barrel": (0, -1.0, bz)}, {"muzzle": (0, -0.3 + L2, bz), "radius": 2.8}

def mortar_tr(v):
    if v.get("ampv"):
        zt = _bradley_hull(zt=2.15)
        box((0, -0.3, zt + 0.12), (2.6, 3.4, 0.24), "paint", bev=0.03)
    else:
        L, W, zt = 4.9, 2.7, 1.85
        tracked(L, W, 5, 0.3, 1.1, 0.4, zt, nose=0.9)
        hatch(-0.55, 1.4, zt, 0.28)
        box((0, -2.47, 1.05), (1.9, 0.06, 1.4), "paint", bev=0.02)
    # açık tavan kapakları
    for s in (-1, 1):
        box((s * 0.95, -1.0, zt + 0.35), (0.06, 1.6, 0.7), "paint", rot=(0, s * 0.45, 0), bev=0.02)
    node("turret")
    tz = zt - 0.35
    tp = (0, -1.0, tz)
    cyl((0, -1.0, tz + 0.1), 0.45, 0.2, "metal", seg=12)
    node("barrel")
    p = 1.0
    canister(0, -0.8, tz + 0.75, 1.75, 0.1, p, "dark")
    mz = (0, -0.8 + 0.88 * math.cos(p), tz + 0.75 + 0.88 * math.sin(p))
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.8, tz + 0.75)}, {"muzzle": mz, "radius": 2.5}

def mlrs_t(v):
    # Bradley türevi şasi: önde kabin, arkada dönebilen ikiz roket kutusu
    L, W, zt = 6.9, 2.97, 1.35
    tracked(L, W, 6, 0.32, 1.25, 0.53, zt, nose=0.6, sprocket_front=True, rollers=(1.4, -1.4))
    armored = v.get("armored_cab", False)
    slab(L / 2 + 0.02, L / 2 - 0.5, L / 2 - 1.9, L / 2 - 1.9, zt, zt + 1.1, W / 2, W / 2 - 0.08, "paint", bev=0.04)
    box((0, L / 2 - 0.2, zt + 0.75), (2.4, 0.04, 0.45 if not armored else 0.25), "glass", rot=(-0.6, 0, 0), bev=0.0)
    if armored:
        for s in (-1, 1):
            era_grid(s * (W / 2 + 0.05), 0, L / 2 - 1.8, L / 2 - 0.2, zt + 0.1, zt + 0.9, s, nx=2, ny=4, depth=0.1)
    node("turret")
    tp = (0, -1.3, zt)
    box((0, -1.3, zt + 0.2), (2.6, 3.4, 0.4), "paint", bev=0.03)
    node("barrel")
    for s in (-1, 1):
        podbox(s * 0.64, -1.3, zt + 0.95, 1.15, 4.0, 0.95, 0.0, (2, 3))
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.2, zt + 0.6)}, {"muzzle": (0, 0.7, zt + 0.95), "radius": 3.0}

# ------------------------------------------------------------ istihkâm
def _abrams_hull():
    import fam_tank
    wy = [2.62 - i * 0.88 for i in range(7)]
    running_gear(1.47, 0.64, wy, 0.32, 3.3, -3.42, 0.3, 0.33, z_top_run=0.98, rollers_y=(1.6, -0.6))
    poly_extrude_x([(3.9, 0.95), (3.62, 0.42), (-3.6, 0.42), (-3.92, 0.6), (-3.95, 0.98)], -1.08, 1.08, "paint")
    poly_extrude_x([(3.25, 1.38), (3.98, 1.02), (3.98, 0.95), (-3.95, 0.95), (-3.95, 1.36), (-3.2, 1.4)], -1.83, 1.83, "paint", bev=0.03)
    for s in (-1, 1):
        for (y, L) in ((2.75, 1.1), (1.6, 1.15), (0.42, 1.15), (-0.76, 1.15), (-1.94, 1.15), (-3.05, 0.95)):
            box((s * 1.87, y, 0.86), (0.08, L - 0.03, 0.62), "paint", bev=0.02)
    grille(0, -2.3, 1.4, 2.5, 2.4, 10)
    return 1.4

def eng_breach(v):
    zt = _abrams_hull()
    # ön saban (mayın kazıcı)
    box((0, 4.55, 0.4), (3.9, 0.5, 0.7), "paint", rot=(0.5, 0, 0), bev=0.03)
    for k in range(9):
        box((-1.8 + k * 0.45, 4.85, 0.15), (0.12, 0.35, 0.3), "metal", rot=(0.9, 0, 0), bev=0.0)
    for s in (-1, 1):
        box((s * 1.6, 3.95, 0.8), (0.15, 1.2, 0.2), "metal", rot=(-0.4, 0, 0), bev=0.0)
    node("turret")
    tz = zt
    slab(1.8, 1.5, -1.6, -1.7, tz, tz + 0.75, 1.5, 1.35, "paint", bev=0.04)
    rws(0.6, 0.0, tz + 0.75, False, True)
    node("barrel")
    for s in (-1, 1):
        box((s * 0.8, -0.8, tz + 1.05), (0.8, 1.8, 0.55), "paint", rot=(0.4, 0, 0), bev=0.03)   # hat açma roket kutuları
    return {"body": (0, 0, 0), "turret": (0, 0.2, tz), "barrel": (0, -0.8, tz + 1.0)}, {"muzzle": (0, 0.4, tz + 1.4), "radius": 3.0}

def eng_dozer(v):
    big = v.get("big", False)
    if big:
        # zırhlı buldozer: yüksek kabin, geniş bıçak, arkada sökücü
        L, W, zt = 5.0, 3.2, 1.5
        tracked(L, W, 6, 0.32, 1.25, 0.6, zt, nose=0.3)
        slab(0.6, 0.5, -1.4, -1.5, zt, zt + 1.6, 1.0, 0.9, "paint", bev=0.04)
        for s in (-1, 1):
            box((s * 0.92, -0.45, zt + 1.05), (0.03, 1.4, 0.5), "glass", bev=0.0)
        box((0, 0.55, zt + 1.05), (1.6, 0.04, 0.5), "glass", bev=0.0)
        box((0, 3.3, 0.9), (4.0, 0.25, 1.6), "paint", rot=(-0.15, 0, 0), bev=0.04)
        for s in (-1, 1):
            box((s * 1.4, 2.4, 0.8), (0.2, 1.8, 0.25), "metal", bev=0.0)
        box((0, -3.0, 0.6), (0.2, 0.9, 1.0), "metal", rot=(0.3, 0, 0), bev=0.0)
        zr = zt + 1.6
    else:
        L, W, zt = 6.2, 3.2, 1.2
        tracked(L, W, 4, 0.36, 1.3, 0.46, zt, nose=0.5)
        box((0, 3.4, 0.7), (3.4, 0.22, 1.0), "paint", rot=(-0.2, 0, 0), bev=0.04)
        slab(-0.8, -1.0, -2.6, -2.7, zt, zt + 0.7, 0.8, 0.7, "paint")
        zr = zt + 0.7
    node("turret")
    tp = (0, -1.5, zr)
    cyl((0, -1.5, zr + 0.05), 0.2, 0.1, "dark", seg=8)
    node("barrel")
    mg(0, -1.2, zr + 0.2, 0.0, 0.8, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.2, zr + 0.2)}, {"muzzle": (0, -0.4, zr + 0.2), "radius": 2.8}

def eng_bridge(v):
    zt = _abrams_hull()
    # katlanmış köprü (üstte iki makas parça) + atma kolu
    box((0, 0.2, zt + 0.55), (3.9, 6.6, 0.35), "paint", bev=0.04)
    box((0, 0.2, zt + 0.95), (3.9, 6.6, 0.35), "paint", bev=0.04)
    for s in (-1, 1):
        box((s * 1.6, 0.2, zt + 0.75), (0.25, 6.4, 0.2), "dark", bev=0.0)
    box((0, 3.6, zt + 0.2), (1.2, 0.6, 0.5), "metal", bev=0.03)
    node("turret")
    tp = (0.9, -2.8, zt + 1.15)
    cyl((0.9, -2.8, zt + 1.2), 0.12, 0.1, "dark", seg=8)
    node("barrel")
    mg(0.9, -2.6, zt + 1.3, 0.0, 0.7, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.9, -2.6, zt + 1.3)}, {"muzzle": (0.9, -1.9, zt + 1.3), "radius": 3.3}

def eng_recovery(v):
    L, W, zt = 8.3, 3.4, 2.4
    tracked(L, W, 6, 0.34, 1.4, 0.6, zt, nose=1.4, glacis_z=1.3, rollers=(1.6, -0.2, -2.0))
    box((0, L / 2 + 0.25, 0.5), (3.3, 0.22, 0.9), "paint", rot=(-0.2, 0, 0), bev=0.03)          # ön bıçak
    # A çerçeve vinç (yatık)
    for s in (-1, 1):
        box((s * 1.0, 1.5, zt + 0.2), (0.2, 4.2, 0.2), "metal", rot=(0.0, 0, s * 0.18), bev=0.0)
    box((0, 3.55, zt + 0.25), (0.4, 0.5, 0.35), "metal", bev=0.02)
    box((0, -3.0, zt + 0.3), (2.6, 1.6, 0.6), "canvas", bev=0.06)
    node("turret")
    tp = (-0.9, 0.3, zt)
    cyl((-0.9, 0.3, zt + 0.15), 0.4, 0.3, "paint", seg=12)
    node("barrel")
    mg(-0.9, 0.6, zt + 0.42, 0.0, 1.1, True)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (-0.9, 0.6, zt + 0.42)}, {"muzzle": (-0.9, 1.7, zt + 0.42), "radius": 3.3}

FAMILIES = {"apc_box": apc_box, "apc_tr": apc_tr, "ifv_tr": ifv_tr, "apc_amph": apc_amph, "td_box": td_box, "td_ontos": td_ontos,
            "spg": spg, "spg_open": spg_open, "mortar_tr": mortar_tr, "mlrs_t": mlrs_t,
            "eng_breach": eng_breach, "eng_dozer": eng_dozer, "eng_bridge": eng_bridge, "eng_recovery": eng_recovery}
