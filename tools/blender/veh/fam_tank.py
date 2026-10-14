# Tank aileleri: mbt (Batı tipi ağır tank, varyantlar), lt (hafif / piyade destek tankı)
import math
from vlib import *

def mbt(v):
    small = v.get("small_turret", False)
    # ---------------- yürüyen aksam: 7 yol tekeri, önde avara, arkada dişli
    wy = [2.62 - i * 0.88 for i in range(7)]
    running_gear(1.47, 0.64, wy, 0.32, 3.3, -3.42, 0.3, 0.33, z_top_run=0.98, rollers_y=(1.6, -0.6))
    # ---------------- alt gövde (paletler arası)
    poly_extrude_x([(3.9, 0.95), (3.62, 0.42), (-3.6, 0.42), (-3.92, 0.6), (-3.95, 0.98)], -1.08, 1.08, "paint")
    # üst gövde / sponsonlar: yandan profil (y,z) X boyunca
    poly_extrude_x([(3.25, 1.38), (3.98, 1.02), (3.98, 0.95), (-3.95, 0.95), (-3.95, 1.36), (-3.2, 1.4)], -1.83, 1.83, "paint", bev=0.008)
    # yan etekler: paneller + cıvatalar + ön eğik panel
    for s in (-1, 1):
        X = s * 1.87
        for (y, L) in ((2.75, 1.1), (1.6, 1.15), (0.42, 1.15), (-0.76, 1.15), (-1.94, 1.15), (-3.05, 0.95)):
            box((X, y, 0.86), (0.08, L - 0.03, 0.62), "paint", bev=0.008)
            for k in range(4):
                cyl((X + s * 0.045, y - L / 2 + 0.18 + k * (L - 0.36) / 3, 1.1), 0.022, 0.02, "dark", "X", seg=6)
        box((X, 3.55, 0.92), (0.08, 0.7, 0.55), "paint", rot=(-0.45, 0, 0), bev=0.008)
        light(s * 1.45, 3.88, 1.12)
        box((s * 1.6, -3.95, 1.18), (0.16, 0.04, 0.1), "red", bev=0.0)
        # çamurluk üstü takım kutuları + çekme halatı
        box((s * 1.55, -2.2, 1.5), (0.5, 1.3, 0.24), "paint", bev=0.008)
        cyl((s * 1.3, 0.2, 1.43), 0.03, 4.0, "dark", "Y", seg=6)
        if v.get("tusk"):
            # TUSK: yan etek üzerinde reaktif zırh tuğlaları
            era_grid(X + s * 0.1, X + s * 0.1, -0.2, 3.2, 0.62, 1.16, s, nx=2, ny=10, depth=0.14)
    # sürücü kapağı + periskoplar
    hatch(0, 2.85, 1.38, 0.3)
    for k in (-1, 0, 1):
        periscope(k * 0.24, 3.15, 1.36, -k * 0.3)
    # motor güvertesi + egzoz
    grille(0, -2.3, 1.4, 2.5, 2.4, 10)
    box((0, -0.95, 1.43), (2.6, 0.5, 0.08), "paint", bev=0.008)
    box((0, -3.97, 1.1), (1.7, 0.08, 0.32), "dark", bev=0.0)
    for k in range(8):
        box((-0.75 + k * 0.215, -4.0, 1.1), (0.04, 0.04, 0.3), "paint", bev=0.0)
    for s in (-1, 1):
        jerrycan(s * 1.25, -3.75, 1.65, math.pi / 2)
    # ---------------- taret (halka pivotu: y=0.25, z=1.4)
    node("turret")
    tz = 1.4
    th = 0.62 if small else 0.86
    W = 1.55 if small else 1.82
    pts = []
    # plan görünüşü (x,y): namlu yanı V, yanaklar, yanlar, bagaj
    plan = [(0.5, 2.5), (W - 0.02, 1.62), (W, -1.25), (W - 0.2, -2.55 if not small else -1.7), (W - 0.45, -2.9 if not small else -1.95)]
    for s in (-1, 1):
        for (x, y) in plan:
            pts.append((s * x, y + 0.25, tz))
            pts.append((s * x * 0.94, y * 0.97 + 0.25, tz + th))
    hull_pts(pts, "paint", bev=0.008)
    # kalkan (mantle): V'nin ucunda, gövdeye gömülü
    box((0, 2.42 + 0.25, tz + th * 0.48), (0.7, 0.3, th * 0.7), "paint", bev=0.008)
    # yanak birleşim çizgisi (zırh modülü kapağı)
    for s in (-1, 1):
        box((s * 1.1, 1.2 + 0.25, tz + th + 0.005), (0.9, 1.2, 0.02), "paint", rot=(0, 0, s * 0.25), bev=0.0)
    # nişancı ana nişangâhı (sağ ön), komutan kubbesi (sağ), yükleyici kapağı (sol)
    box((0.72, 1.55 + 0.25, tz + th + 0.13), (0.5, 0.55, 0.26), "paint", bev=0.008)
    box((0.72, 1.84 + 0.25, tz + th + 0.15), (0.38, 0.02, 0.14), "glass", bev=0.0)
    cupola = v.get("cupola", "m2")
    if cupola in ("crows", "crows_low", "rws"):
        rws(0.55, -0.1 + 0.25, tz + th, True, cupola != "crows")
    else:
        cyl((0.6, -0.1 + 0.25, tz + th + 0.12), 0.42, 0.24, "paint", seg=12, bev=0.008)
        for k in range(6):
            a = k * math.tau / 6
            periscope(0.6 + math.cos(a) * 0.38, -0.1 + 0.25 + math.sin(a) * 0.38, tz + th + 0.15, a + math.pi / 2)
        mg(0.6, 0.15 + 0.25, tz + th + 0.38, 0.0, 1.2, True)
    hatch(-0.6, -0.2 + 0.25, tz + th, 0.32)
    mg(-0.95, 0.15 + 0.25, tz + th + 0.32, 0.25, 1.0, False)
    if v.get("tusk"):
        box((-0.95, 0.38 + 0.25, tz + th + 0.38), (0.6, 0.03, 0.42), "glass", rot=(0, 0, 0.25), bev=0.0)   # yükleyici kalkanı
    if v.get("citv"):
        cyl((-0.85, 1.0 + 0.25, tz + th + 0.22), 0.07, 0.44, "paint", seg=8)
        box((-0.85, 1.0 + 0.25, tz + th + 0.5), (0.34, 0.36, 0.3), "paint", bev=0.008)
        box((-0.85, 1.19 + 0.25, tz + th + 0.5), (0.24, 0.02, 0.16), "glass", bev=0.0)
    # sis atarlar
    for s in (-1, 1):
        smoke_launchers(s * (W - 0.1), 1.45 + 0.25, tz + th * 0.72, s * 0.5, 6, s)
        antenna(s * 0.95, -1.9 + 0.25 if not small else -1.3 + 0.25, tz + th, 1.5)
    if not small:
        # bagaj sepeti: çerçeve borular + çantalar
        for s in (-1, 1):
            box((s * 1.62, -2.15 + 0.25, tz + th * 0.75), (0.04, 1.4, 0.04), "dark", bev=0.0)
            box((s * 1.62, -2.15 + 0.25, tz + th * 0.4), (0.04, 1.4, 0.04), "dark", bev=0.0)
            for k in range(4):
                box((s * 1.62, -1.55 - k * 0.42 + 0.25, tz + th * 0.6), (0.03, 0.03, th * 0.5), "dark", bev=0.0)
        box((0, -2.88 + 0.25, tz + th * 0.75), (3.0, 0.04, 0.04), "dark", bev=0.0)
        bag(0.6, -2.55 + 0.25, tz + th + 0.15, 0.9, 0.6, 0.35)
        bag(-0.7, -2.6 + 0.25, tz + th + 0.13, 1.0, 0.55, 0.3)
        bag(1.4, -2.3 + 0.25, tz + th + 0.12, 0.35, 0.8, 0.28)
        if v.get("apu"):
            box((-1.3, -2.75 + 0.25, tz + th * 0.5), (0.6, 0.45, 0.55), "paint", bev=0.008)
    if v.get("aps"):
        for s in (-1, 1):
            aps(s * (W + 0.06), 0.2 + 0.25, tz + th * 0.55, s)
    # ---------------- namlu (muylu: y=2.55+0.25, z=tz+th*0.5)
    node("barrel")
    bz = tz + th * 0.5
    by = 2.6 + 0.25
    cyl((0, by + 0.3, bz), 0.2, 0.6, "paint", "Y", seg=14)
    cyl((0, by + 2.6, bz), 0.105, 4.6, "paint", "Y", seg=14, r2=0.095)
    cyl((0, by + 2.4, bz), 0.15, 0.7, "paint", "Y", seg=14)                  # duman tahliye
    cyl((0, by + 4.95, bz), 0.1, 0.12, "dark", "Y", seg=14)                  # namlu ağzı
    box((0, by + 4.8, bz + 0.11), (0.08, 0.14, 0.06), "dark", bev=0.0)        # namlu referans sensörü
    pivots = {"body": (0, 0, 0), "turret": (0, 0.25, tz), "barrel": (0, by, bz)}
    meta = {"muzzle": (0, by + 5.0, bz), "radius": 2.9}
    return pivots, meta

def lt(v):
    # ---------------- hafif tank: 6 yol tekeri, daha kısa ve dar gövde, 105 mm namlu, kutu taret
    wy = [2.15 - i * 0.84 for i in range(6)]
    running_gear(1.32, 0.55, wy, 0.3, 2.8, -2.95, 0.28, 0.3, z_top_run=0.92, rollers_y=(1.3, -0.4, -1.9))
    poly_extrude_x([(3.35, 0.92), (3.05, 0.42), (-3.1, 0.42), (-3.4, 0.62), (-3.42, 0.95)], -0.95, 0.95, "paint")
    poly_extrude_x([(2.65, 1.42), (3.42, 1.02), (3.42, 0.92), (-3.4, 0.92), (-3.4, 1.4), (-2.9, 1.44)], -1.68, 1.68, "paint", bev=0.008)
    for s in (-1, 1):
        X = s * 1.7
        for (y, L) in ((2.3, 1.1), (1.15, 1.15), (0.0, 1.15), (-1.15, 1.15), (-2.35, 1.1)):
            box((X, y, 0.85), (0.08, L - 0.03, 0.58), "paint", bev=0.008)
        light(s * 1.3, 3.33, 1.12)
        box((s * 1.4, -1.7, 1.55), (0.45, 1.3, 0.24), "paint", bev=0.008)
    hatch(0, 2.35, 1.42, 0.28)
    for k in (-1, 0, 1):
        periscope(k * 0.22, 2.62, 1.4, -k * 0.3)
    grille(0, -2.0, 1.44, 2.2, 2.0, 9)
    node("turret")
    tz = 1.44
    th = 0.8
    pts = []
    for s in (-1, 1):
        for (x, y) in ((0.55, 2.0), (1.5, 1.35), (1.55, -1.1), (1.35, -1.9)):
            pts.append((s * x, y, tz)); pts.append((s * x * 0.9, y * 0.95, tz + th))
    hull_pts(pts, "paint", bev=0.008)
    box((0, 2.05, tz + th * 0.5), (0.8, 0.3, th * 0.75), "paint", bev=0.008)
    box((0.7, 1.2, tz + th + 0.12), (0.45, 0.5, 0.24), "paint", bev=0.008)
    rws(-0.5, -0.2, tz + th, True, True)
    hatch(0.55, -0.4, tz + th, 0.3)
    for s in (-1, 1):
        smoke_launchers(s * 1.45, 1.2, tz + th * 0.7, s * 0.55, 6, s)
        antenna(s * 0.9, -1.5, tz + th, 1.4)
        bag(s * 0.8, -1.75, tz + th + 0.12, 0.7, 0.5, 0.3)
    node("barrel")
    bz = tz + th * 0.5
    by = 2.1
    cyl((0, by + 0.25, bz), 0.17, 0.5, "paint", "Y", seg=14)
    cyl((0, by + 2.1, bz), 0.085, 3.7, "paint", "Y", seg=14, r2=0.08)
    cyl((0, by + 1.9, bz), 0.12, 0.5, "paint", "Y", seg=14)
    box((0, by + 4.0, bz), (0.24, 0.3, 0.16), "dark", bev=0.008)              # namlu freni
    pivots = {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, by, bz)}
    meta = {"muzzle": (0, by + 4.2, bz), "radius": 2.6}
    return pivots, meta

FAMILIES = {"mbt": mbt, "lt": lt}
