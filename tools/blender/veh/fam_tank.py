# Tank aileleri: mbt (Batı tipi ağır tank, varyantlar), lt (hafif / piyade destek tankı)
import math
from vlib import *

def _skirts(X, s, panels, z=0.86, h=0.62, heavy_front=True):
    """Yan etek: cıvatalı paneller, üst menteşe şeridi, alt kenar, ilk iki panel kalın (zırhlı)."""
    for i, (y, L) in enumerate(panels):
        t = 0.12 if (heavy_front and i < 2) else 0.08
        box((X + s * (t - 0.08) * 0.5, y, z), (t, L - 0.03, h), "paint", bev=0.01)
        bolt_row((X + s * (t * 0.5 + 0.004), y - L / 2 + 0.05, z + h * 0.36), (X + s * (t * 0.5 + 0.004), y + L / 2 - 0.05, z + h * 0.36), 4, (s, 0, 0), 0.022)
        bolt_row((X + s * (t * 0.5 + 0.004), y - L / 2 + 0.05, z - h * 0.38), (X + s * (t * 0.5 + 0.004), y + L / 2 - 0.05, z - h * 0.38), 3, (s, 0, 0), 0.018)
        if i < 2 and heavy_front:
            seam((X + s * (t * 0.5 + 0.002), y - L / 2 + 0.1, z + 0.05), (X + s * (t * 0.5 + 0.002), y + L / 2 - 0.1, z + 0.05), (s, 0, 0))
        grab_handle((X + s * (t * 0.5 + 0.004), y, z - h * 0.12), (0, 1, 0), (s, 0, 0), L=0.16, h=0.04, r=0.009)
    y0 = panels[0][0] + panels[0][1] / 2
    y1 = panels[-1][0] - panels[-1][1] / 2
    rod((X, y0, z + h / 2 + 0.01), (X, y1, z + h / 2 + 0.01), 0.02, "metal", 6)              # menteşe borusu

def _bustle_rack(y0, y1, x, z, h):
    """Taret arkası sepet + içerik (çantalar, ağ rulosu, mühimmat kutuları)."""
    basket(-x, x, y0, y1, z, h)
    bag(x * 0.55, (y0 + y1) / 2 + 0.05, z + 0.2, x * 0.65, abs(y1 - y0) * 0.75, 0.36)
    bag(-x * 0.5, (y0 + y1) / 2, z + 0.17, x * 0.7, abs(y1 - y0) * 0.7, 0.3)
    net_roll(0, y1 + 0.18 if y1 > y0 else y1 - 0.18, z + h + 0.1, x * 1.7, 0.13)
    ammo_box(-x * 0.1, (y0 + y1) / 2 - 0.05, z + 0.12, math.pi / 2)
    bag(x * 0.05, (y0 + y1) / 2, z + 0.42, 0.45, 0.35, 0.22, straps=1)

def mbt(v):
    small = v.get("small_turret", False)
    # ---------------- yürüyen aksam: 7 yol tekeri, önde avara, arkada dişli
    wy = [2.62 - i * 0.88 for i in range(7)]
    running_gear(1.47, 0.64, wy, 0.32, 3.3, -3.42, 0.3, 0.33, z_top_run=0.98, rollers_y=(1.6, -0.6), holes=0)
    # ---------------- alt gövde (paletler arası)
    poly_extrude_x([(3.9, 0.95), (3.62, 0.42), (-3.6, 0.42), (-3.92, 0.6), (-3.95, 0.98)], -1.08, 1.08, "paint")
    # üst gövde / sponsonlar: yandan profil (y,z) X boyunca
    poly_extrude_x([(3.25, 1.38), (3.98, 1.02), (3.98, 0.95), (-3.95, 0.95), (-3.95, 1.36), (-3.2, 1.4)], -1.83, 1.83, "paint", bev=0.012)
    # ön levha birleşimi kaynakları + çeki gözleri
    for s in (-1, 1):
        weld((s * 1.83, 3.25, 1.385), (s * 1.83, 3.98, 1.02))
        _skirts(s * 1.87, s, ((2.75, 1.1), (1.6, 1.15), (0.42, 1.15), (-0.76, 1.15), (-1.94, 1.15), (-3.05, 0.95)))
        box((s * 1.87, 3.55, 0.92), (0.1, 0.7, 0.55), "paint", rot=(-0.45, 0, 0), bev=0.01)
        bolt_row((s * 1.93, 3.3, 1.02), (s * 1.93, 3.75, 0.8), 3, (s, 0, 0), 0.02)
        # far grupları ön çamurluklarda (Abrams: kafesli far kutusu)
        light(s * 1.45, 3.88, 1.12)
        # çamurluk üstü: kaymaz şerit + bağlama halkası
        box((s * 1.5, 3.55, 1.3), (0.55, 0.6, 0.012), "trim", rot=(-0.2, 0, 0), bev=0.0)
        if v.get("tusk"):
            # TUSK: yan etek üzerinde reaktif zırh tuğlaları
            era_grid(s * 2.0, 0, -0.2, 3.2, 0.62, 1.16, s, nx=2, ny=10, depth=0.14)
    dress_hull(7.9, 3.66, 1.4, zf=0.82, tools_y=None, cable=False)
    # sürücü kapağı + periskoplar, ön güverte ek yerleri
    hatch(0, 2.85, 1.38, 0.3)
    for k in (-1, 0, 1):
        periscope(k * 0.24, 3.15, 1.36, -k * 0.3)
    deck_seams(-1.6, 1.6, (3.22,), 1.395)
    for s in (-1, 1):
        lift_eye((s * 1.3, 3.0, 1.38))
        cyl((s * 1.15, 2.85, 1.4), 0.07, 0.03, "trim", seg=12)                                    # yakıt kapağı
    # ---------------- motor güvertesi (taretin arkası): ızgaralar, kapak menteşeleri, egzoz panjuru
    grille(0, -2.3, 1.4, 2.5, 2.4, 10)
    for s in (-1, 1):
        grille(s * 1.45, -3.35, 1.4, 0.6, 0.9, 5)
        seam((s * 1.3, -1.0, 1.42), (s * 1.3, -3.9, 1.42))
        for yy in (-1.3, -2.5, -3.5):
            box((s * 1.28, yy, 1.43), (0.05, 0.22, 0.04), "metal", bev=0.0)                       # kapak menteşeleri
    box((0, -0.95, 1.43), (2.6, 0.5, 0.08), "paint", bev=0.008)
    louvers(0, -3.98, 1.12, 1.7, 0.3, 6)
    for s in (-1, 1):
        jerrycan(s * 1.25, -3.75, 1.65, math.pi / 2)
    # arka levhada çaprazlama çekme halatları
    for s in (-1, 1):
        rod((s * 1.5, -3.99, 0.95), (s * 0.2, -3.99, 1.3), 0.02, "metal", 6)
        ring((s * 0.12, -4.0, 1.32), 0.07, 0.017, "metal", axis="Y", seg=8)
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
    hull_pts(pts, "paint", bev=0.014)
    R = tz + th
    # kalkan (mantle): V'nin ucunda, gövdeye gömülü; eş eksenli MG ve yardımcı nişangâh delikleri
    box((0, 2.42 + 0.25, tz + th * 0.48), (0.7, 0.3, th * 0.7), "paint", bev=0.012)
    box((0.26, 2.83, tz + th * 0.62), (0.12, 0.04, 0.09), "dark", bev=0.0)
    box((-0.26, 2.83, tz + th * 0.62), (0.1, 0.04, 0.08), "glass", bev=0.0)
    bolt_row((-0.3, 2.84, tz + th * 0.3), (0.3, 2.84, tz + th * 0.3), 4, (0, 1, 0), 0.02)
    # yanak zırh modülü kapakları: kenar çizgileri + cıvata sıraları
    for s in (-1, 1):
        box((s * 1.1, 1.2 + 0.25, R + 0.005), (0.9, 1.2, 0.02), "paint", rot=(0, 0, s * 0.25), bev=0.0)
        bolt_row((s * 0.75, 1.95, R + 0.02), (s * 1.45, 1.65, R + 0.02), 5, (0, 0, 1), 0.02)
        bolt_row((s * 0.95, 0.95, R + 0.02), (s * 1.55, 0.75, R + 0.02), 4, (0, 0, 1), 0.02)
        lift_eye((s * 1.45, 1.05, R), (0, 0, 1), 0.2 * s)
        lift_eye((s * 1.35, -1.9 + 0.25 if not small else -1.2, R))
    # tavan: patlama panelleri (arka), ek yerleri
    if not small:
        for s in (-1, 1):
            x0, x1 = s * 0.25, s * 1.2
            for yy in (-1.0, -2.0):
                seam((x0, yy, R + 0.004), (x1, yy, R + 0.004))
            seam((x1, -1.0, R + 0.004), (x1, -2.0, R + 0.004))
        seam((0, -0.6, R + 0.004), (0, -2.3, R + 0.004))
    # nişancı ana nişangâhı (sağ ön): zırhlı kutu + iki kapak
    box((0.72, 1.55 + 0.25, R + 0.13), (0.5, 0.55, 0.26), "paint", bev=0.012)
    box((0.72, 1.84 + 0.25, R + 0.15), (0.38, 0.02, 0.14), "glass", bev=0.0)
    for s in (-1, 1):
        box((0.72 + s * 0.13, 1.86 + 0.25, R + 0.24), (0.14, 0.04, 0.06), "paint", rot=(-0.6, 0, 0), bev=0.0)
    seam((0.47, 1.6 + 0.25, R + 0.2), (0.97, 1.6 + 0.25, R + 0.2))
    cupola = v.get("cupola", "m2")
    if cupola in ("crows", "crows_low", "rws"):
        rws(0.55, -0.1 + 0.25, R, True, cupola != "crows")
        hatch(0.55, -0.6 + 0.25, R, 0.26)
    else:
        cyl((0.6, -0.1 + 0.25, R + 0.12), 0.42, 0.24, "paint", seg=16, bev=0.01)
        for k in range(6):
            a = k * math.tau / 6
            periscope(0.6 + math.cos(a) * 0.38, -0.1 + 0.25 + math.sin(a) * 0.38, R + 0.15, a + math.pi / 2)
        hatch(0.6, 0.15, R + 0.24, 0.28)
        mg(0.6, 0.15 + 0.25, R + 0.38, 0.0, 1.2, True)
    hatch(-0.6, -0.2 + 0.25, R, 0.32)
    mg(-0.95, 0.15 + 0.25, R + 0.32, 0.25, 1.0, False)
    cyl((-0.95, 0.4, R + 0.12), 0.05, 0.24, "metal", seg=8)                                    # yükleyici MG ayağı
    if v.get("tusk"):
        f = F((-0.95, 0.63, R + 0.38), (0, 0, 0.25))
        f.box((0, 0, 0), (0.6, 0.03, 0.42), "paint", bev=0.0)                                 # yükleyici kalkanı
        f.box((0, 0.02, 0.06), (0.32, 0.02, 0.16), "glass", bev=0.0)
        for sx in (-1, 1):
            f.box((sx * 0.33, -0.12, 0), (0.03, 0.25, 0.42), "paint", bev=0.0)
    if v.get("citv"):
        cyl((-0.85, 1.0 + 0.25, R + 0.22), 0.07, 0.44, "paint", seg=8)
        box((-0.85, 1.0 + 0.25, R + 0.5), (0.34, 0.36, 0.3), "paint", bev=0.012)
        box((-0.85, 1.19 + 0.25, R + 0.5), (0.24, 0.02, 0.16), "glass", bev=0.0)
        box((-0.85, 1.0 + 0.25, R + 0.66), (0.38, 0.4, 0.02), "trim", bev=0.0)
    # rüzgâr sensörü direği (tavan arka orta)
    rod((0, -1.4 if not small else -1.0, R), (0, -1.4 if not small else -1.0, R + 0.55), 0.015, "dark", 6)
    rod((-0.12, -1.4 if not small else -1.0, R + 0.55), (0.12, -1.4 if not small else -1.0, R + 0.55), 0.01, "dark", 4)
    # sis atarlar, antenler, taret yan tutamakları ve yan zula kutuları
    for s in (-1, 1):
        smoke_launchers(s * (W - 0.1), 1.45 + 0.25, tz + th * 0.72, s * 0.5, 6, s)
        antenna(s * 0.95, -1.9 + 0.25 if not small else -1.3 + 0.25, R, 1.5)
        grab_handle((s * (W - 0.02), -0.4, tz + th * 0.62), (0, 1, 0), (s, 0, 0), L=0.9, h=0.07, r=0.012)
        if not small:
            stowage_box(s * (W + 0.12), -1.6, tz + th * 0.45, 0.24, 1.0, 0.5, side=s)
    if not small:
        _bustle_rack(-2.55, -3.3, 1.45, tz + th * 0.25, th * 0.62)
        if v.get("apu"):
            stowage_box(-1.3, -2.75 + 0.25, tz + th * 0.5, 0.6, 0.45, 0.55)
            louvers(-1.3, -2.97 + 0.25 - 0.02, tz + th * 0.5, 0.4, 0.3, 4)
    else:
        bag(0.6, -1.55, R + 0.15, 0.7, 0.45, 0.3)
        net_roll(-0.4, -1.6, R + 0.12, 0.9)
    if v.get("aps"):
        for s in (-1, 1):
            aps(s * (W + 0.06), 0.2 + 0.25, tz + th * 0.55, s)
    # ---------------- namlu (muylu: y=2.55+0.25, z=tz+th*0.5)
    node("barrel")
    bz = tz + th * 0.5
    by = 2.6 + 0.25
    cyl((0, by + 0.3, bz), 0.2, 0.6, "paint", "Y", seg=16)
    cyl((0, by + 2.6, bz), 0.105, 4.6, "paint", "Y", seg=16, r2=0.095)
    for f in (0.12, 0.3, 0.75):
        cyl((0, by + 0.3 + 4.6 * f, bz), 0.118, 0.04, "trim", "Y", seg=16)                    # ısı kılıfı kayışları
    cyl((0, by + 2.4, bz), 0.15, 0.7, "paint", "Y", seg=16)                  # duman tahliye
    for t in (-0.35, 0.35):
        cyl((0, by + 2.4 + t, bz), 0.135, 0.03, "paint", "Y", seg=16)
    cyl((0, by + 4.95, bz), 0.1, 0.12, "paint", "Y", seg=16)                 # namlu ağzı
    cyl((0, by + 5.015, bz), 0.062, 0.01, "dark", "Y", seg=12)
    box((0, by + 4.8, bz + 0.11), (0.08, 0.14, 0.06), "dark", bev=0.0)        # namlu referans sensörü
    pivots = {"body": (0, 0, 0), "turret": (0, 0.25, tz), "barrel": (0, by, bz)}
    # komutan kapağı (oyunda kapaktaki komutanın yeri): kubbe ya da uzaktan kumandalı silah yanındaki kapak
    hx, hy, hz = (0.55, -0.35, R) if cupola in ("crows", "crows_low", "rws") else (0.6, 0.15, R + 0.24)
    meta = {"muzzle": (0, by + 5.0, bz), "radius": 2.9, "hatch": (hx, hy, hz)}
    return pivots, meta

def lt(v):
    # ---------------- hafif tank: 6 yol tekeri, daha kısa ve dar gövde, 105 mm namlu, kutu taret
    wy = [2.15 - i * 0.84 for i in range(6)]
    running_gear(1.32, 0.55, wy, 0.3, 2.8, -2.95, 0.28, 0.3, z_top_run=0.92, rollers_y=(1.3, -0.4, -1.9), holes=6)
    poly_extrude_x([(3.35, 0.92), (3.05, 0.42), (-3.1, 0.42), (-3.4, 0.62), (-3.42, 0.95)], -0.95, 0.95, "paint")
    poly_extrude_x([(2.65, 1.42), (3.42, 1.02), (3.42, 0.92), (-3.4, 0.92), (-3.4, 1.4), (-2.9, 1.44)], -1.68, 1.68, "paint", bev=0.012)
    for s in (-1, 1):
        _skirts(s * 1.7, s, ((2.3, 1.1), (1.15, 1.15), (0.0, 1.15), (-1.15, 1.15), (-2.35, 1.1)), z=0.85, h=0.58)
        light(s * 1.3, 3.33, 1.12)
        stowage_box(s * 1.4, -1.7, 1.55, 0.45, 1.3, 0.24, side=s)
        weld((s * 1.68, 2.65, 1.425), (s * 1.68, 3.42, 1.02))
    dress_hull(6.84, 3.36, 1.42, zf=0.8, tools_y=0.3, cable=True)
    hatch(0, 2.35, 1.42, 0.28)
    for k in (-1, 0, 1):
        periscope(k * 0.22, 2.62, 1.4, -k * 0.3)
    grille(0, -2.0, 1.44, 2.2, 2.0, 9)
    louvers(0, -3.43, 1.1, 1.4, 0.26, 5)
    deck_seams(-1.5, 1.5, (2.68, -0.95), 1.43)
    node("turret")
    tz = 1.44
    th = 0.8
    R = tz + th
    pts = []
    for s in (-1, 1):
        for (x, y) in ((0.55, 2.0), (1.5, 1.35), (1.55, -1.1), (1.35, -1.9)):
            pts.append((s * x, y, tz)); pts.append((s * x * 0.9, y * 0.95, tz + th))
    hull_pts(pts, "paint", bev=0.014)
    box((0, 2.05, tz + th * 0.5), (0.8, 0.3, th * 0.75), "paint", bev=0.012)
    bolt_row((-0.32, 2.21, tz + th * 0.25), (0.32, 2.21, tz + th * 0.25), 4, (0, 1, 0), 0.02)
    box((0.7, 1.2, R + 0.12), (0.45, 0.5, 0.24), "paint", bev=0.012)
    box((0.7, 1.46, R + 0.13), (0.32, 0.02, 0.12), "glass", bev=0.0)
    rws(-0.5, -0.2, R, True, True)
    hatch(0.55, -0.4, R, 0.3)
    seam((-1.2, 0.6, R + 0.004), (1.2, 0.6, R + 0.004))
    for s in (-1, 1):
        smoke_launchers(s * 1.45, 1.2, tz + th * 0.7, s * 0.55, 6, s)
        antenna(s * 0.9, -1.5, R, 1.4)
        lift_eye((s * 1.2, 0.9, R))
        grab_handle((s * 1.48, -0.6, tz + th * 0.6), (0, 1, 0), (s, 0, 0), L=0.8)
        bolt_row((s * 0.6, 1.9, R + 0.02), (s * 1.3, 1.35, R + 0.02), 4, (0, 0, 1), 0.02)
    _bustle_rack(-1.8, -2.35, 1.2, tz + th * 0.25, th * 0.55)
    node("barrel")
    bz = tz + th * 0.5
    by = 2.1
    cyl((0, by + 0.25, bz), 0.17, 0.5, "paint", "Y", seg=16)
    cyl((0, by + 2.1, bz), 0.085, 3.7, "paint", "Y", seg=16, r2=0.08)
    cyl((0, by + 1.9, bz), 0.12, 0.5, "paint", "Y", seg=16)
    for f in (0.15, 0.7):
        cyl((0, by + 0.25 + 3.7 * f, bz), 0.098, 0.035, "trim", "Y", seg=14)
    box((0, by + 4.0, bz), (0.24, 0.3, 0.16), "trim", bev=0.01)              # namlu freni
    for s in (-1, 1):
        box((s * 0.122, by + 4.0, bz), (0.012, 0.18, 0.1), "dark", bev=0.0)
    pivots = {"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, by, bz)}
    meta = {"muzzle": (0, by + 4.2, bz), "radius": 2.6}
    return pivots, meta

FAMILIES = {"mbt": mbt, "lt": lt}
