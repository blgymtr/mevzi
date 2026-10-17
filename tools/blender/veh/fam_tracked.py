# Paletli aileler: kutu ZPT, AMPV/Bradley şasisi, amfibi, tanksavar, kundağı motorlu obüs, açık obüs,
# havan aracı, paletli roketatar, istihkâm (mayın açma, dozer, köprü, kurtarma).
import math
from vlib import *
import vlib

def tracked(L, W, n, r, xc, tw, zt, nose=1.0, rear=0.15, glacis_z=None, sprocket_front=False, rollers=(), skirts=False,
            dress=True, tools_side=True):
    """Genel paletli şasi. L uzunluk, W gövde genişliği (paletler dahil), n yol tekeri, zt gövde üstü."""
    y0 = L / 2 - 0.45
    y1 = -L / 2 + 0.5
    wy = [y0 - 0.25 - i * (y0 - y1 - 0.5) / (n - 1) for i in range(n)]
    yf = y0 + 0.2
    yr = y1 - 0.15
    running_gear(xc, tw, wy, r, yf if not sprocket_front else yr, yr if not sprocket_front else yf, 0.27, 0.3, z_top_run=r * 2 + 0.28, rollers_y=rollers)
    zg = glacis_z if glacis_z is not None else zt - 0.45
    zs = r * 2 + 0.25                                       # sponson alt kenarı (palet üstü)
    # alt gövde + üst gövde (yandan profil)
    poly_extrude_x([(L / 2, zg), (L / 2 - 0.35, 0.38), (-L / 2 + 0.2, 0.38), (-L / 2, 0.6), (-L / 2, zt)], -(xc - tw / 2 - 0.02), xc - tw / 2 - 0.02, "paint")
    poly_extrude_x([(L / 2 - nose, zt), (L / 2 + 0.05, zg), (L / 2 + 0.05, zs), (-L / 2, zs), (-L / 2, zt)], -W / 2, W / 2, "paint", bev=0.012)
    for s in (-1, 1):
        # üst kenar ve burun kaynakları, sponson alt kenarında cıvata sırası
        weld((s * W / 2, L / 2 - nose, zt), (s * W / 2, -L / 2, zt))
        weld((s * W / 2, L / 2 - nose, zt), (s * W / 2, L / 2 + 0.05, zg))
        bolt_row((s * (W / 2 + 0.004), L / 2 - 0.3, zs + 0.06), (s * (W / 2 + 0.004), -L / 2 + 0.3, zs + 0.06), int(L / 0.45), (s, 0, 0), 0.018)
        light(s * (W / 2 - 0.3), L / 2 - 0.1, zg + 0.05)
        if skirts:
            Lp = (L - 0.8) / 4
            for k in range(4):
                yy = L / 2 - 0.6 - Lp * (k + 0.5)
                box((s * (W / 2 + 0.03), yy, zs - 0.2), (0.06, Lp - 0.03, 0.5), "paint", bev=0.01)
                bolt_row((s * (W / 2 + 0.064), yy - Lp / 2 + 0.08, zs - 0.02), (s * (W / 2 + 0.064), yy + Lp / 2 - 0.08, zs - 0.02), 4, (s, 0, 0), 0.02)
                bolt_row((s * (W / 2 + 0.064), yy - Lp / 2 + 0.08, zs - 0.38), (s * (W / 2 + 0.064), yy + Lp / 2 - 0.08, zs - 0.38), 3, (s, 0, 0), 0.016)
        # ön paçalık (lastik)
        box((s * xc, L / 2 + 0.02, zs - 0.15), (tw * 0.95, 0.02, 0.3), "rubber", rot=(0.3, 0, 0), bev=0.0)
    if dress:
        dress_hull(L, W, zt, zf=max(0.6, zs - 0.15), tools_y=None, cable=False)
        if tools_side:
            # gövde yanlarında alet takımı (sol) ve çekme halatı (sağ)
            zz = (zs + zt) / 2 + 0.05
            if zt - zs > 0.45:
                tools(-(W / 2), -L * 0.12, zz, (-1, 0, 0), ("shovel", "pick", "bar"), spacing=0.13)
                tow_cable(W / 2, -L * 0.35, L * 0.15, zz, (1, 0, 0))
    return wy

def _ramp(L, W, z, h, zt, door=True):
    """Arka rampa: levha + kenar çerçevesi + menteşeler + rampa kapısı + tutamaklar + lambalar.
    (79) Ayrı 'door' düğümü: menteşe rampanın ALT kenarında; oyunda biniş / inişte aşağı açılır (vlib.DOOR)."""
    door_begin((0, -L / 2 - 0.03, z - h / 2), 1.35)
    _ramp_geo(L, W, z, h, zt, door)
    door_end()

def _ramp_geo(L, W, z, h, zt, door=True):
    y = -L / 2 - 0.03
    box((0, y, z), (W, 0.06, h), "paint", bev=0.012)
    for s in (-1, 1):
        box((s * (W / 2 - 0.03), y - 0.03, z), (0.05, 0.03, h - 0.06), "paint", bev=0.0)
        box((s * W * 0.3, y - 0.02, z - h / 2 + 0.06), (0.22, 0.06, 0.1), "metal", bev=0.0)          # menteşe
    seam((-W / 2 + 0.04, y - 0.033, z + h / 2 - 0.04), (W / 2 - 0.04, y - 0.033, z + h / 2 - 0.04), (0, -1, 0))
    if door:
        dw, dh = W * 0.42, h * 0.75
        dx = W * 0.22
        for (a, b) in (((dx - dw / 2, z - dh / 2), (dx + dw / 2, z - dh / 2)), ((dx - dw / 2, z + dh / 2), (dx + dw / 2, z + dh / 2)),
                       ((dx - dw / 2, z - dh / 2), (dx - dw / 2, z + dh / 2)), ((dx + dw / 2, z - dh / 2), (dx + dw / 2, z + dh / 2))):
            seam((a[0], y - 0.033, a[1]), (b[0], y - 0.033, b[1]), (0, -1, 0))
        grab_handle((dx - dw * 0.3, y - 0.035, z), (0, 0, 1), (0, -1, 0), L=0.2, h=0.05)
        vision_block(dx, y - 0.04, z + dh * 0.3, math.pi, 0.18)
    for s in (-1, 1):
        grab_handle((s * W * 0.38, y - 0.035, z + h * 0.3), (0, 0, 1), (0, -1, 0), L=0.25, h=0.05)

def apc_box(v):
    # kutu gövdeli paletli ZPT (M113 tipi): dik yanlar, eğik ön, arka rampa
    L, W, zt = 4.9, 2.7, 1.85
    tracked(L, W, 5, 0.3, 1.1, 0.4, zt, nose=0.9, rollers=())
    hatch(-0.55, 1.4, zt, 0.28, peri=0)
    for k in range(4):
        periscope(-0.55 + (k - 1.5) * 0.15, 1.75, zt - 0.02, 0)
    cyl((0.45, 0.4, zt + 0.12), 0.38, 0.24, "paint", seg=16, bev=0.01)
    for k in range(5):
        a = k * math.tau / 5 + 0.6
        periscope(0.45 + math.cos(a) * 0.36, 0.4 + math.sin(a) * 0.36, zt + 0.16, a + math.pi / 2, small=True)
    _ramp(L, 1.9, 1.05, 1.4, zt)
    # dalga kırıcı (öne yatık levha) + çizgileri
    box((0, L / 2 - 0.15, zt - 0.32), (2.2, 0.05, 0.45), "paint", rot=(-0.95, 0, 0), bev=0.008)
    for k in range(5):
        box((0.6, 1.9 - k * 0.12, zt - 0.3), (0.9, 0.06, 0.04), "dark", rot=(-0.95, 0, 0), bev=0.0)
    grille(-0.6, 1.2, zt + 0.01, 0.6, 0.6, 5)
    exhaust(-1.15, 1.35, zt - 0.2, 0.07, fy=1)
    # üst kargo kapağı (arka) + menteşeler
    box((0, -1.3, zt + 0.02), (1.4, 1.4, 0.04), "paint", bev=0.008)
    for s in (-1, 1):
        box((s * 0.5, -0.58, zt + 0.05), (0.2, 0.06, 0.04), "metal", bev=0.0)
    grab_handle((0, -1.9, zt + 0.04), (1, 0, 0), (0, 0, 1), L=0.3, h=0.05)
    antenna(-1.1, -2.1, zt, 1.8); antenna(1.1, -2.1, zt, 1.8)
    for s in (-1, 1):
        jerrycan(s * 1.05, -2.5, 1.3)
    node("turret")
    tp = (0.45, 0.4, zt + 0.24)
    # mürettebat kalkanı (3 levha) + kurşun geçirmez camlar
    for k in range(3):
        a = math.pi * (0.3 + k * 0.2)
        f = F((0.45 + math.cos(a) * 0.4, 0.4 + math.sin(a) * 0.4, zt + 0.5), (0, 0, a - math.pi / 2))
        f.box((0, 0, 0), (0.4, 0.05, 0.45), "paint", bev=0.01)
        f.box((0, 0.03, 0.1), (0.16, 0.012, 0.1), "glass")
        bolt_row(f.P((-0.16, 0.03, -0.18)), f.P((0.16, 0.03, -0.18)), 3, f.R @ Vector((0, 1, 0)), 0.014)
    node("barrel")
    mg(0.45, 0.8, zt + 0.55, 0.0, 1.1, True)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.45, 0.8, zt + 0.55)}, {"muzzle": (0.45, 1.9, zt + 0.55), "radius": 2.3}

def _bradley_hull(L=6.55, W=3.28, zt=2.0, era=False):
    tracked(L, W, 6, 0.32, 1.42, 0.53, zt, nose=1.3, glacis_z=1.25, sprocket_front=True, rollers=(1.4, -0.2, -1.8), skirts=True)
    hatch(-0.85, 2.3, zt - 0.05, 0.26)
    for k in range(3):
        periscope(-0.85 + (k - 1) * 0.17, 2.6, zt - 0.08, (1 - k) * 0.25)
    _ramp(L, 2.2, 1.3, 1.5, zt)
    grille(0.8, 2.0, zt - 0.1, 1.0, 0.6, 5)
    exhaust(1.4, 2.15, zt - 0.05, 0.08, fy=1)
    # dalga levhası (trim vane) burunda katlanmış
    box((0, L / 2 - 0.45, zt - 0.32), (2.6, 0.05, 0.6), "paint", rot=(-1.05, 0, 0), bev=0.008)
    for s in (-1, 1):
        box((s * 1.1, L / 2 - 0.35, zt - 0.25), (0.06, 0.25, 0.08), "metal", rot=(-1.05, 0, 0), bev=0.0)
    # yan ek zırh levhaları (cıvatalı)
    zs = 0.32 * 2 + 0.25
    if not era:
        for s in (-1, 1):
            for k in range(5):
                yy = 2.0 - k * 1.0
                box((s * (W / 2 + 0.02), yy, (zs + zt) / 2), (0.04, 0.95, zt - zs - 0.12), "paint", bev=0.008)
                for zz in (zs + 0.12, zt - 0.14):
                    bolt_row((s * (W / 2 + 0.045), yy - 0.4, zz), (s * (W / 2 + 0.045), yy + 0.4, zz), 3, (s, 0, 0), 0.018)
    if era:
        for s in (-1, 1):
            era_grid(s * (W / 2 + 0.1), 0, -2.6, 2.4, 0.75, 1.55, s, nx=2, ny=10, depth=0.12)
            era_grid(s * (W / 2 - 0.15), 0, -2.0, 1.8, zt - 0.3, zt - 0.05, s, nx=1, ny=6, depth=0.1)
    for s in (-1, 1):
        stowage_box(s * 1.35, -2.8, zt + 0.15, 0.5, 0.6, 0.3, side=s)
        bag(s * 1.35, -2.25, zt + 0.12, 0.45, 0.45, 0.24)
    deck_seams(-1.5, 1.5, (-1.7,), zt + 0.003)
    return zt

def apc_tr(v):
    zt = _bradley_hull(zt=2.15)
    box((0, -0.8, zt + 0.12), (2.6, 3.8, 0.24), "paint", bev=0.012)                             # yükseltilmiş tavan
    weld((-1.3, 1.1, zt + 0.24), (1.3, 1.1, zt + 0.24))
    hatch(0.7, -2.2, zt + 0.24, 0.3)
    hatch(-0.7, -2.0, zt + 0.24, 0.3)
    for k in range(4):
        periscope(-1.15, 0.6 - k * 0.6, zt + 0.22, math.pi / 2, small=True)
        periscope(1.15, 0.6 - k * 0.6, zt + 0.22, -math.pi / 2, small=True)
    antenna(-1.1, -2.5, zt + 0.24, 2.0); antenna(1.1, -2.5, zt + 0.24, 1.6)
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
    # iki kişilik taret: eğimli ön, yanlarda aralıklı zırh levhaları, solda TOW kutusu
    slab(1.15, 0.85, -1.15, -1.3, tz, tz + 0.75, 1.0, 0.85, "paint", wf=0.6)
    R = tz + 0.75
    for s in (-1, 1):
        f = F((s * 1.0, -0.1, tz + 0.4), (0, 0, 0))
        f.box((0, 0, 0), (0.05, 1.9, 0.62), "paint", rot=(0, s * 0.18, 0), bev=0.008)        # aralıklı zırh
        bolt_row(f.P((s * 0.03, -0.85, 0.24)), f.P((s * 0.03, 0.85, 0.24)), 5, (s, 0, 0), 0.016)
        bolt_row(f.P((s * 0.03, -0.85, -0.24)), f.P((s * 0.03, 0.85, -0.24)), 5, (s, 0, 0), 0.016)
        lift_eye((s * 0.7, 0.6, R))
    box((0.6, 0.55, tz + 0.95), (0.4, 0.45, 0.35), "paint", bev=0.012)                          # nişangâh (ISU)
    box((0.6, 0.79, tz + 0.95), (0.3, 0.02, 0.18), "glass", bev=0.0)
    box((0.6, 0.62, tz + 1.14), (0.46, 0.55, 0.02), "trim", bev=0.0)
    if v.get("scout") or True:
        box((-0.5, -0.4, tz + 0.95), (0.35, 0.35, 0.3), "paint", bev=0.012)                     # komutan bağımsız görüş
        box((-0.5, -0.22, tz + 0.95), (0.24, 0.02, 0.14), "glass", bev=0.0)
        cyl((-0.5, -0.4, tz + 0.78), 0.08, 0.06, "metal", seg=10)
    hatch(-0.45, -0.75, R, 0.26); hatch(0.45, -0.75, R, 0.26, peri=2)
    # TOW kutusu: kapaklı uçlar, menteşeler
    box((-1.25, -0.1, tz + 0.55), (0.42, 1.4, 0.5), "paint", bev=0.012)
    for s in (-1, 1):
        box((-1.25 + s * 0.1, 0.61, tz + 0.55), (0.16, 0.02, 0.36), "dark", bev=0.0)
        box((-1.25 + s * 0.1, 0.625, tz + 0.55), (0.18, 0.012, 0.4), "trim", bev=0.0)
    cyl((-1.04, -0.1, tz + 0.3), 0.04, 1.2, "metal", "Y", seg=8)
    for s in (-1, 1):
        smoke_launchers(s * 0.95, 0.75, tz + 0.5, s * 0.5, 4, s)
    antenna(-0.8, -1.1, R, 1.6); antenna(0.8, -1.1, R, 1.6)
    # taret arkası sepet
    basket(-0.9, 0.9, -1.3, -1.75, tz + 0.15, 0.45)
    bag(0.4, -1.52, tz + 0.35, 0.7, 0.38, 0.32)
    bag(-0.45, -1.52, tz + 0.32, 0.6, 0.38, 0.28)
    node("barrel")
    bz = tz + 0.4
    box((0, 1.15, bz), (0.42, 0.3, 0.34), "paint", bev=0.012)
    bolt_row((-0.16, 1.305, bz - 0.12), (0.16, 1.305, bz - 0.12), 3, (0, 1, 0), 0.015)
    gun(1.25, bz, 2.1, 0.045, "gun", sleeve=0.45)
    cyl((0, 3.38, bz), 0.06, 0.1, "gun", "Y", seg=8)                                            # alev gizleyici
    mg(0.25, 1.4, bz - 0.05, 0.0, 0.6, False)
    return {"body": (0, 0, 0), "turret": (0, 0.1, tz), "barrel": (0, 1.1, bz)}, {"muzzle": (0, 3.4, bz), "radius": 2.8}

def apc_amph(v):
    # amfibi hücum aracı: yüksek tekne gövde, eğik burun, sağ önde küçük silah kulesi
    L, W, zt = 8.0, 3.27, 2.7
    tracked(L, W, 6, 0.32, 1.35, 0.53, zt, nose=1.6, glacis_z=1.3, rollers=(1.2, -1.2), tools_side=False)
    slab(L / 2 + 0.35, L / 2 - 0.9, L / 2 - 1.1, L / 2 - 0.1, 0.6, 1.4, W / 2 - 0.1, W / 2 - 0.05, "paint")    # tekne burnu
    hatch(-0.9, 1.9, zt, 0.28)
    for k in range(5):
        periscope(-0.9 + (k - 2) * 0.16, 2.25, zt - 0.02, 0, small=True)
    _ramp(L, 2.4, 1.6, 1.9, zt)
    # ek zırh kiti (EAAK): yanlarda cıvatalı kalın levhalar
    for s in (-1, 1):
        for k in range(6):
            for j in range(2):
                yy = 2.6 - k * 1.05
                zz = 1.25 + j * 0.62
                box((s * (W / 2 + 0.04), yy, zz), (0.08, 1.0, 0.58), "paint", bev=0.01)
                for a in (-1, 1):
                    for b in (-1, 1):
                        bolt((s * (W / 2 + 0.085), yy + a * 0.4, zz + b * 0.22), (s, 0, 0), 0.02)
        box((s * (W / 2 + 0.01), -3.7, zt - 0.6), (0.06, 0.4, 0.35), "dark", bev=0.0)          # su jeti çıkışı
    # üst kargo kapakları
    for s in (-1, 1):
        box((s * 0.5, -1.5, zt + 0.02), (0.9, 2.6, 0.04), "paint", bev=0.008)
        for t in (-0.8, 0.0, 0.8):
            box((s * 0.06, -1.5 + t, zt + 0.05), (0.06, 0.2, 0.04), "metal", bev=0.0)
        tiedown((s * 1.4, -1.0, zt))
    grille(-0.5, 0.5, zt + 0.01, 1.0, 1.0, 6)
    antenna(-1.4, -3.4, zt, 2.0); antenna(1.4, -3.4, zt, 2.0)
    node("turret")
    tp = (0.8, 1.6, zt)
    cyl((0.8, 1.6, zt + 0.25), 0.55, 0.5, "paint", seg=10, bev=0.012)
    for k in range(6):
        a = k * math.tau / 6
        vision_block(0.8 + math.cos(a) * 0.52, 1.6 + math.sin(a) * 0.52, zt + 0.32, a - math.pi / 2, 0.14)
    hatch(0.8, 1.6, zt + 0.5, 0.3)
    node("barrel")
    box((0.8, 2.15, zt + 0.3), (0.6, 0.2, 0.3), "paint", bev=0.01)
    gun(1.9, zt + 0.3, 0.9, 0.05, "gun", x=1.0)
    gun(1.9, zt + 0.3, 0.5, 0.07, "gun", x=0.6)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.8, 1.9, zt + 0.3)}, {"muzzle": (1.0, 2.9, zt + 0.3), "radius": 3.0}

def td_box(v):
    pv, md = apc_box(v)
    # TOW "çekiç başı" fırlatıcı: kaldırılmış ikiz kutu
    node("turret")
    zt = 1.85
    cyl((0.45, -0.6, zt + 0.25), 0.18, 0.5, "metal", seg=10)
    node("barrel")
    box((0.45, -0.5, zt + 0.7), (1.0, 0.55, 0.5), "paint", bev=0.012)
    for s in (-1, 1):
        box((0.45 + s * 0.28, -0.22, zt + 0.7), (0.3, 0.02, 0.36), "dark", bev=0.0)
        box((0.45 + s * 0.28, -0.21, zt + 0.7), (0.33, 0.012, 0.4), "trim", bev=0.0)
    box((0.45, -0.5, zt + 0.97), (0.3, 0.35, 0.06), "glass", bev=0.0)
    pv["barrel"] = (0.45, -0.5, zt + 0.7)
    md["muzzle"] = (0.45, 0.4, zt + 0.7)
    return pv, md

def td_ontos(v):
    L, W, zt = 3.8, 2.6, 1.6
    tracked(L, W, 4, 0.3, 1.05, 0.38, zt, nose=0.7, tools_side=False)
    hatch(-0.6, 0.9, zt, 0.25)
    node("turret")
    tp = (0, 0.1, zt)
    box((0, 0.0, zt + 0.15), (0.8, 0.8, 0.3), "paint", bev=0.012)
    hatch(0.0, -0.05, zt + 0.3, 0.25)
    node("barrel")
    for s in (-1, 1):
        for k in range(3):
            gun(-0.4, zt + 0.35 + k * 0.22, 2.5, 0.07, "paint", x=s * 0.55)
        box((s * 0.55, 0.6, zt + 0.57), (0.2, 0.08, 0.7), "metal", bev=0.0)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.3, zt + 0.55)}, {"muzzle": (0.55, 2.1, zt + 0.55), "radius": 2.0}

def spg(v):
    a7 = v.get("a7", False)
    old = v.get("old", False)
    L, W, zt = (6.2, 3.2, 1.5) if not a7 else (6.4, 3.3, 1.55)
    tracked(L, W, 7 if not a7 else 6, 0.3, 1.38, 0.4 if not a7 else 0.5, zt, nose=1.0, glacis_z=1.05, sprocket_front=True, tools_side=False)
    hatch(-0.9, 2.2, zt, 0.26)
    for k in range(3):
        periscope(-0.9 + (k - 1) * 0.16, 2.48, zt - 0.02, (1 - k) * 0.25, small=True)
    grille(-0.8, 1.7, zt + 0.01, 1.0, 0.7, 5)
    grille(0.6, 1.9, zt + 0.01, 0.9, 0.6, 4)
    # namlu seyahat kilidi (ön güvertede A çerçeve, yatık)
    for s in (-1, 1):
        bar((s * 0.25, L / 2 - 0.5, zt), (0, L / 2 - 0.95, zt + 0.25), 0.06, 0.06, "paint")
    box((0, L / 2 - 0.95, zt + 0.27), (0.3, 0.12, 0.1), "metal", bev=0.0)
    _ramp(L, 1.4, 0.95, 1.0, zt, door=False)
    node("turret")
    ty = -0.6 if not old else -1.3
    tz = zt
    slab(1.4, 1.3, -1.9, -1.95, tz, tz + 1.15, 1.45, 1.35, "paint", bev=0.014)                   # büyük kutu taret
    R = tz + 1.15
    box((0, -1.97, tz + 0.65), (2.0, 0.06, 0.9), "paint", bev=0.01)                              # arka kapak
    for s in (-1, 1):
        box((s * 0.48, -2.02, tz + 0.65), (0.04, 0.04, 0.8), "metal", bev=0.0)
        grab_handle((s * 0.85, -2.0, tz + 0.65), (0, 0, 1), (0, -1, 0), L=0.4, h=0.05)
        # yan kapılar (taret yanında) + tutamak
        for (a, b) in (((-0.2, tz + 0.2), (-0.2, tz + 0.95)), ((-1.0, tz + 0.2), (-1.0, tz + 0.95)), ((-1.0, tz + 0.95), (-0.2, tz + 0.95))):
            seam((s * 1.44, a[0], a[1]), (s * 1.44, b[0], b[1]), (s, 0, 0))
        grab_handle((s * 1.45, -0.35, tz + 0.6), (0, 0, 1), (s, 0, 0), L=0.2, h=0.04)
        lift_eye((s * 1.15, 1.1, R))
        lift_eye((s * 1.15, -1.6, R))
    cyl((0.85, -0.3, R + 0.1), 0.36, 0.2, "paint", seg=16)
    for k in range(5):
        a = k * math.tau / 5 + 0.3
        periscope(0.85 + math.cos(a) * 0.33, -0.3 + math.sin(a) * 0.33, R + 0.12, a + math.pi / 2, small=True)
    mg(0.85, 0.0, R + 0.3, 0.0, 1.1, True)
    hatch(-0.7, -0.5, R, 0.28)
    roof_panels(-1.3, 1.3, -1.85, 1.25, R + 0.003, 2, 3)
    box((-0.2, -1.4, R + 0.08), (0.5, 0.4, 0.16), "paint", bev=0.01)                             # havalandırma
    grille(-0.2, -1.4, R + 0.16, 0.4, 0.3, 4)
    for s in (-1, 1):
        side_panels(s * 1.42, -1.9, 1.3, tz + 0.1, R - 0.05, s, 3)
        stowage_box(s * 1.56, -1.45, tz + 0.95, 0.24, 0.8, 0.3, side=s)
        for k in range(3):
            tiedown((s * 1.2, 0.8 - k * 1.1, R))
    for s in (-1, 1):
        box((s * 1.5, -0.6, tz + 0.55), (0.1, 1.8, 0.7), "canvas", bev=0.012)
        box((s * 1.45, 1.35, tz + 0.5), (0.25, 0.25, 0.35), "paint", bev=0.012)
        antenna(s * 1.1, -1.7, R, 1.5)
        smoke_launchers(s * 1.3, 1.2, tz + 0.9, s * 0.45, 4, s)
    basket(-1.2, 1.2, -1.98, -2.4, tz + 0.3, 0.45)
    bag(0.5, -2.2, tz + 0.5, 0.8, 0.35, 0.35)
    ammo_box(-0.6, -2.2, tz + 0.42, math.pi / 2, big=True)
    node("barrel")
    bz = tz + 0.65
    box((0, 1.45, bz), (0.6, 0.4, 0.55), "paint", bev=0.012)
    bolt_row((-0.25, 1.655, bz + 0.2), (0.25, 1.655, bz + 0.2), 4, (0, 1, 0), 0.016)
    gun(1.6, bz, 5.6 if not old else 3.2, 0.1, "paint", brake=True, sleeve=0.6, bands=2)
    return {"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, 1.4, bz)}, {"muzzle": (0, 7.3 if not old else 4.9, bz), "radius": 2.9}

def spg_open(v):
    cal = v.get("cal", 203)
    L, W, zt = 5.7, 3.15, 1.4
    tracked(L, W, 5, 0.38, 1.3, 0.46, zt, nose=0.9, sprocket_front=True, tools_side=False)
    # geri tepme pençesi (kürek) + hidrolik silindirleri
    box((0, -L / 2 - 0.4, 0.55), (2.6, 0.25, 0.9), "paint", rot=(0.6, 0, 0), bev=0.012)
    for k in range(5):
        box(((k - 2) * 0.55, -L / 2 - 0.55, 0.3), (0.06, 0.3, 0.5), "paint", rot=(0.6, 0, 0), bev=0.0)
    for s in (-1, 1):
        rod((s * 0.9, -L / 2 + 0.1, zt - 0.2), (s * 0.9, -L / 2 - 0.35, 0.75), 0.06, "metal", 8)
        rod((s * 0.9, -L / 2 + 0.1, zt - 0.2), (s * 0.9, -L / 2 - 0.15, 0.95), 0.04, "metal", 8)
    for s in (-1, 1):
        f = F((s * 0.95, -1.6, zt + 0.35), (0, 0, 0))
        f.box((0, 0, -0.1), (0.5, 0.5, 0.3), "paint", bev=0.01)                                  # mürettebat koltukları
        f.box((0, 0, 0.1), (0.45, 0.45, 0.08), "canvas", bev=0.01)
        f.box((0, -0.25, 0.35), (0.45, 0.08, 0.5), "canvas", bev=0.01)
        ammo_box(s * 1.2, -0.6, zt + 0.12, 0.0, big=True)
    hatch(-0.9, 2.0, zt, 0.26)
    node("turret")
    tz = zt
    box((0, -1.0, tz + 0.25), (1.6, 1.6, 0.5), "paint", bev=0.012)
    for s in (-1, 1):
        box((s * 0.55, -1.0, tz + 0.75), (0.12, 1.2, 0.55), "paint", bev=0.01)                  # muylu yatakları
        cyl((s * 0.62, -1.0, tz + 0.85), 0.14, 0.08, "metal", "X", seg=12)
        # yükseliş dişli yayı
        for k in range(7):
            a = -0.6 + k * 0.2
            box((s * 0.5, -1.0 + math.cos(a) * 0.5, tz + 0.85 + math.sin(a) * 0.5), (0.04, 0.06, 0.06), "metal", rot=(a, 0, 0), bev=0.0)
    node("barrel")
    bz = tz + 0.85
    box((0, -1.0, bz), (0.9, 1.4, 0.7), "paint", bev=0.012)
    for s in (-1, 1):
        cyl((s * 0.28, -0.6, bz + 0.38), 0.09, 1.8, "metal", "Y", seg=12)                         # geri tepme silindirleri
        cyl((s * 0.28, -0.6, bz - 0.38), 0.09, 1.8, "metal", "Y", seg=12)
    if v.get("mortar"):
        gun(-0.3, bz, 4.0, 0.2, "paint", bands=2)
    elif cal == 203:
        gun(-0.3, bz, 5.2, 0.17, "paint", sleeve=1.0, bands=2)
    else:
        gun(-0.3, bz, 9.5, 0.11, "paint", sleeve=1.0, bands=3)
    L2 = 4.0 if v.get("mortar") else (5.2 if cal == 203 else 9.5)
    return {"body": (0, 0, 0), "turret": (0, -1.0, tz), "barrel": (0, -1.0, bz)}, {"muzzle": (0, -0.3 + L2, bz), "radius": 2.8}

def _mortar(x, y, z, p, L=1.75, r=0.1):
    """Havan: namlu + taban halkası + çift ayak + nişangâh."""
    canister(x, y, z, L, r, p, "dark", caps=False)
    d = Vector((0, math.cos(p), math.sin(p)))
    c = Vector((x, y, z))
    cyl(c + d * (L * 0.5 + 0.02), r * 1.15, 0.05, "dark", rot=(math.pi / 2 - p, 0, 0), seg=12)
    cyl(c - d * (L * 0.5), r * 1.6, 0.14, "metal", rot=(math.pi / 2 - p, 0, 0), seg=12)
    for s in (-1, 1):
        rod(c + d * (L * 0.2), (x + s * 0.35, y + 0.45, z - 0.55), 0.025, "metal", 6)
    box((x + 0.15, y + 0.1, z + 0.1), (0.1, 0.12, 0.12), "dark", bev=0.0)

def mortar_tr(v):
    if v.get("ampv"):
        zt = _bradley_hull(zt=2.15)
        box((0, -0.3, zt + 0.12), (2.6, 3.4, 0.24), "paint", bev=0.012)
    else:
        L, W, zt = 4.9, 2.7, 1.85
        tracked(L, W, 5, 0.3, 1.1, 0.4, zt, nose=0.9)
        hatch(-0.55, 1.4, zt, 0.28)
        _ramp(L, 1.9, 1.05, 1.4, zt)
        exhaust(-1.15, 1.35, zt - 0.2, 0.07, fy=1)
    # açık tavan kapakları + iç mühimmat rafları
    for s in (-1, 1):
        f = F((s * 0.95, -1.0, zt + 0.35), (0, s * 0.45, 0))
        f.box((0, 0, 0), (0.06, 1.6, 0.7), "paint", bev=0.01)
        for t in (-0.6, 0.0, 0.6):
            f.box((-s * 0.04, t, -0.32), (0.04, 0.18, 0.05), "metal")
        f.box((s * 0.04, 0, 0), (0.012, 1.4, 0.55), "trim")
        for k in range(4):
            cyl((s * 1.0, -1.8 + k * 0.22, zt - 0.2), 0.06, 0.5, "dark", seg=8)
    node("turret")
    tz = zt - 0.35
    tp = (0, -1.0, tz)
    cyl((0, -1.0, tz + 0.1), 0.45, 0.2, "metal", seg=16)
    node("barrel")
    p = 1.0
    _mortar(0, -0.8, tz + 0.75, p)
    mz = (0, -0.8 + 0.88 * math.cos(p), tz + 0.75 + 0.88 * math.sin(p))
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.8, tz + 0.75)}, {"muzzle": mz, "radius": 2.5}

def mlrs_t(v):
    # Bradley türevi şasi: önde kabin, arkada dönebilen ikiz roket kutusu
    L, W, zt = 6.9, 2.97, 1.35
    tracked(L, W, 6, 0.32, 1.25, 0.53, zt, nose=0.6, sprocket_front=True, rollers=(1.4, -1.4), tools_side=False)
    armored = v.get("armored_cab", False)
    slab(L / 2 + 0.02, L / 2 - 0.5, L / 2 - 1.9, L / 2 - 1.9, zt, zt + 1.1, W / 2, W / 2 - 0.08, "paint", bev=0.014)
    yc = L / 2 - 0.2
    for s in (-1, 1):
        box((s * 0.6, yc, zt + 0.75), (1.1, 0.04, 0.45 if not armored else 0.25), "glass", rot=(-0.6, 0, 0), bev=0.0)
        # cam zırh panjurları (kalkık), silecekler
        box((s * 0.6, yc + 0.05, zt + 1.02), (1.15, 0.04, 0.3), "paint", rot=(-1.3, 0, 0), bev=0.0)
        box((s * 0.6, yc + 0.03, zt + 0.62), (0.02, 0.02, 0.3), "dark", rot=(-0.6, 0, 0.3), bev=0.0)
        box((s * (W / 2 - 0.01), L / 2 - 1.0, zt + 0.75), (0.03, 0.6, 0.35), "glass", bev=0.0)
        seam((s * (W / 2 + 0.002), L / 2 - 0.65, zt + 0.1), (s * (W / 2 + 0.002), L / 2 - 0.65, zt + 1.0), (s, 0, 0))
        grab_handle((s * (W / 2 + 0.005), L / 2 - 1.5, zt + 0.6), (0, 0, 1), (s, 0, 0), L=0.4)
        mirror(s * (W / 2 - 0.05), L / 2 - 0.3, zt + 0.85, s, 0.25)
    box((0, yc, zt + 0.75), (0.08, 0.06, 0.45), "paint", rot=(-0.6, 0, 0), bev=0.0)
    hatch(0.6, L / 2 - 1.4, zt + 1.1, 0.28)
    antenna(-1.2, L / 2 - 1.7, zt + 1.1, 1.8)
    if armored:
        for s in (-1, 1):
            era_grid(s * (W / 2 + 0.05), 0, L / 2 - 1.8, L / 2 - 0.2, zt + 0.1, zt + 0.9, s, nx=2, ny=4, depth=0.1)
    node("turret")
    tp = (0, -1.3, zt)
    box((0, -1.3, zt + 0.2), (2.6, 3.4, 0.4), "paint", bev=0.012)
    for s in (-1, 1):
        cyl((s * 1.1, -2.8, zt + 0.55), 0.08, 0.6, "metal", seg=10, rot=(0.6, 0, 0))              # kaldırma pistonu
        box((s * 1.25, -0.2, zt + 0.25), (0.1, 0.6, 0.3), "trim", bev=0.0)
    node("barrel")
    for s in (-1, 1):
        podbox(s * 0.64, -1.3, zt + 0.95, 1.15, 4.0, 0.95, 0.0, (2, 3))
    box((0, -1.3, zt + 1.5), (0.12, 3.6, 0.08), "metal", bev=0.0)                                # kablo kanalı
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -3.2, zt + 0.6)}, {"muzzle": (0, 0.7, zt + 0.95), "radius": 3.0}

# ------------------------------------------------------------ istihkâm
def _abrams_hull():
    wy = [2.62 - i * 0.88 for i in range(7)]
    running_gear(1.47, 0.64, wy, 0.32, 3.3, -3.42, 0.3, 0.33, z_top_run=0.98, rollers_y=(1.6, -0.6), holes=0)
    poly_extrude_x([(3.9, 0.95), (3.62, 0.42), (-3.6, 0.42), (-3.92, 0.6), (-3.95, 0.98)], -1.08, 1.08, "paint")
    poly_extrude_x([(3.25, 1.38), (3.98, 1.02), (3.98, 0.95), (-3.95, 0.95), (-3.95, 1.36), (-3.2, 1.4)], -1.83, 1.83, "paint", bev=0.012)
    for s in (-1, 1):
        for (y, L) in ((2.75, 1.1), (1.6, 1.15), (0.42, 1.15), (-0.76, 1.15), (-1.94, 1.15), (-3.05, 0.95)):
            box((s * 1.87, y, 0.86), (0.08, L - 0.03, 0.62), "paint", bev=0.01)
            bolt_row((s * 1.912, y - L / 2 + 0.05, 1.08), (s * 1.912, y + L / 2 - 0.05, 1.08), 4, (s, 0, 0), 0.02)
        light(s * 1.45, 3.88, 1.12)
    grille(0, -2.3, 1.4, 2.5, 2.4, 10)
    louvers(0, -3.98, 1.12, 1.7, 0.3, 6)
    dress_hull(7.9, 3.66, 1.4, zf=0.82, cable=False)
    hatch(0, 2.85, 1.38, 0.3)
    for k in (-1, 0, 1):
        periscope(k * 0.24, 3.15, 1.36, -k * 0.3)
    return 1.4

def eng_breach(v):
    zt = _abrams_hull()
    # ön saban (mayın kazıcı): kollar, dişler, derinlik kızakları
    box((0, 4.55, 0.4), (3.9, 0.5, 0.7), "paint", rot=(0.5, 0, 0), bev=0.012)
    for k in range(9):
        box((-1.8 + k * 0.45, 4.85, 0.15), (0.12, 0.35, 0.3), "metal", rot=(0.9, 0, 0), bev=0.0)
    for s in (-1, 1):
        box((s * 1.6, 3.95, 0.8), (0.15, 1.2, 0.2), "metal", rot=(-0.4, 0, 0), bev=0.0)
        box((s * 1.85, 4.6, 0.12), (0.12, 0.7, 0.08), "metal", bev=0.0)
        cyl((s * 1.2, 4.1, 0.95), 0.07, 0.8, "metal", seg=10, rot=(1.1, 0, 0))
    node("turret")
    tz = zt
    slab(1.8, 1.5, -1.6, -1.7, tz, tz + 0.75, 1.5, 1.35, "paint", bev=0.014)
    R = tz + 0.75
    rws(0.6, 0.0, R, False, True)
    hatch(-0.6, 0.0, R, 0.3)
    for s in (-1, 1):
        lift_eye((s * 1.1, 1.2, R))
        bolt_row((s * 0.4, 1.7, R + 0.01), (s * 1.3, 1.5, R + 0.01), 4, (0, 0, 1), 0.02)
        smoke_launchers(s * 1.4, 1.2, tz + 0.5, s * 0.5, 4, s)
    node("barrel")
    for s in (-1, 1):
        f = F((s * 0.8, -0.8, tz + 1.05), (0.4, 0, 0))
        f.box((0, 0, 0), (0.8, 1.8, 0.55), "paint", bev=0.012)                                  # hat açma roket kutuları
        f.box((0, 0.91, 0), (0.6, 0.02, 0.4), "dark")
        for t in (-0.5, 0.5):
            f.box((0, t, 0.29), (0.82, 0.06, 0.03), "metal")
    return {"body": (0, 0, 0), "turret": (0, 0.2, tz), "barrel": (0, -0.8, tz + 1.0)}, {"muzzle": (0, 0.4, tz + 1.4), "radius": 3.0}

def eng_dozer(v):
    big = v.get("big", False)
    if big:
        # zırhlı buldozer: yüksek kabin, geniş bıçak, arkada sökücü (L: gövde boyu, BAT-2 için uzun)
        L, W, zt = float(v.get("L", 5.0)), 3.2, 1.5
        cy = (L - 5.0) * 0.8         # uzun gövdede (BAT-2) mürettebat kabini önde, motor ve vinç arkada
        tracked(L, W, 6, 0.32, 1.25, 0.6, zt, nose=0.3, tools_side=False)
        slab(0.6 + cy, 0.5 + cy, -1.4 + cy, -1.5 + cy, zt, zt + 1.6, 1.0, 0.9, "paint", bev=0.014)
        for s in (-1, 1):
            box((s * 0.92, -0.45 + cy, zt + 1.05), (0.03, 1.4, 0.5), "glass", bev=0.0)
            for t in (-0.5, 0.0, 0.5):
                box((s * 0.95, -0.45 + cy + t, zt + 1.05), (0.04, 0.04, 0.55), "dark", bev=0.0)  # cam koruma ızgarası
            box((s * 1.4, L / 2 - 0.1, 0.8), (0.2, 1.8, 0.25), "metal", bev=0.0)
            cyl((s * 1.1, L / 2 - 0.9, 1.2), 0.08, 1.2, "metal", seg=10, rot=(1.2, 0, 0))
        box((0, 0.55 + cy, zt + 1.05), (1.6, 0.04, 0.5), "glass", bev=0.0)
        if cy > 0.5:
            # motor güvertesi ızgaraları + katlanmış vinç kolu ve kancası (arka)
            grille(-0.7, cy - 2.6, zt + 0.01, 1.0, 1.3, 6)
            box((0.95, -L / 2 + 1.9, zt + 0.32), (0.32, 3.0, 0.32), "paint", bev=0.01)
            box((0.95, -L / 2 + 0.35, zt + 0.2), (0.5, 0.4, 0.4), "paint", bev=0.01)            # vinç tabanı
            cyl((0.95, -L / 2 + 3.45, zt + 0.25), 0.08, 0.25, "dark", seg=10)                   # kanca makarası
            box((0.95, -L / 2 + 3.45, zt + 0.06), (0.1, 0.06, 0.16), "metal", bev=0.0)
        yb = L / 2 + 0.8
        box((0, yb, 0.9), (4.0, 0.25, 1.6), "paint", rot=(-0.15, 0, 0), bev=0.012)
        for k in range(7):
            box(((k - 3) * 0.55, yb - 0.12, 0.9), (0.04, 0.1, 1.5), "paint", rot=(-0.15, 0, 0), bev=0.0)   # bıçak nervürleri
        box((0, yb + 0.15, 0.12), (4.0, 0.12, 0.12), "metal", bev=0.0)
        box((0, -L / 2 - 0.5, 0.6), (0.2, 0.9, 1.0), "metal", rot=(0.3, 0, 0), bev=0.0)
        zr = zt + 1.6
        hatch(0, -0.4 + cy, zr, 0.3)
        exhaust(0.6, -0.9 + cy, zr + 0.2, 0.08, fy=1)
    else:
        cy = 0.0
        L, W, zt = 6.2, 3.2, 1.2
        tracked(L, W, 4, 0.36, 1.3, 0.46, zt, nose=0.5, tools_side=False)
        box((0, 3.4, 0.7), (3.4, 0.22, 1.0), "paint", rot=(-0.2, 0, 0), bev=0.012)
        for k in range(6):
            box(((k - 2.5) * 0.6, 3.28, 0.7), (0.04, 0.1, 0.95), "paint", rot=(-0.2, 0, 0), bev=0.0)
        for s in (-1, 1):
            cyl((s * 1.1, 2.4, 1.0), 0.08, 1.4, "metal", seg=10, rot=(1.2, 0, 0))
        slab(-0.8, -1.0, -2.6, -2.7, zt, zt + 0.7, 0.8, 0.7, "paint", bev=0.014)
        zr = zt + 0.7
        hatch(0, -1.9, zr, 0.3)
    node("turret")
    tp = (0, -1.5 + cy, zr)
    cyl((0, -1.5 + cy, zr + 0.05), 0.2, 0.1, "dark", seg=10)
    node("barrel")
    mg(0, -1.2 + cy, zr + 0.2, 0.0, 0.8, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.2 + cy, zr + 0.2)}, {"muzzle": (0, -0.4 + cy, zr + 0.2), "radius": 2.8}

def eng_bridge(v):
    zt = _abrams_hull()
    bl = float(v.get("bl", 6.6))          # katlanmış köprü boyu (MTU-72 ~11,4 m, Wolverine ~13 m)
    # katlanmış köprü (üstte iki makas parça) + atma kolu
    for k, zz in enumerate((zt + 0.55, zt + 0.95)):
        box((0, 0.2, zz), (3.9, bl, 0.35), "paint", bev=0.012)
        for s in (-1, 1):
            box((s * 1.3, 0.2, zz + 0.18), (0.9, bl - 0.1, 0.02), "trim", bev=0.0)               # yürüyüş yolu
            nt = int((bl - 0.4) / 0.78)
            for t in range(nt):
                box((s * 1.3, 0.2 - (nt - 1) * 0.39 + t * 0.78, zz + 0.2), (0.86, 0.04, 0.02), "metal", bev=0.0)   # kaymaz çıtalar
        seam((-1.95, -0.3, zz), (1.95, -0.3, zz))
    for s in (-1, 1):
        box((s * 1.6, 0.2, zt + 0.75), (0.25, bl - 0.2, 0.2), "dark", bev=0.0)
    box((0, 3.6, zt + 0.2), (1.2, 0.6, 0.5), "metal", bev=0.008)
    for s in (-1, 1):
        cyl((s * 0.4, 3.3, zt + 0.5), 0.08, 1.0, "metal", seg=10, rot=(1.0, 0, 0))
    node("turret")
    tp = (0.9, -2.8, zt + 1.15)
    cyl((0.9, -2.8, zt + 1.2), 0.12, 0.1, "dark", seg=8)
    node("barrel")
    mg(0.9, -2.6, zt + 1.3, 0.0, 0.7, False)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (0.9, -2.6, zt + 1.3)}, {"muzzle": (0.9, -1.9, zt + 1.3), "radius": 3.3}

def eng_recovery(v):
    L, W, zt = 8.3, 3.4, 2.4
    tracked(L, W, 6, 0.34, 1.4, 0.6, zt, nose=1.4, glacis_z=1.3, rollers=(1.6, -0.2, -2.0))
    box((0, L / 2 + 0.25, 0.5), (3.3, 0.22, 0.9), "paint", rot=(-0.2, 0, 0), bev=0.012)          # ön bıçak
    for k in range(6):
        box(((k - 2.5) * 0.6, L / 2 + 0.15, 0.5), (0.04, 0.1, 0.85), "paint", rot=(-0.2, 0, 0), bev=0.0)
    for s in (-1, 1):
        cyl((s * 1.2, L / 2 - 0.3, 1.0), 0.08, 1.0, "metal", seg=10, rot=(1.3, 0, 0))
    # A çerçeve vinç (yatık) + makara + halat
    for s in (-1, 1):
        box((s * 1.0, 1.5, zt + 0.2), (0.2, 4.2, 0.2), "metal", rot=(0.0, 0, s * 0.18), bev=0.0)
        cyl((s * 0.55, -0.5, zt + 0.2), 0.12, 0.4, "metal", seg=10, rot=(0.0, math.pi / 2, 0))
    box((0, 3.55, zt + 0.25), (0.4, 0.5, 0.35), "metal", bev=0.008)
    cyl((0, 3.6, zt + 0.25), 0.15, 0.3, "dark", "X", seg=12)
    rod((0, 3.4, zt + 0.25), (0, 0.5, zt + 0.15), 0.025, "metal", 6)
    box((0, -3.0, zt + 0.3), (2.6, 1.6, 0.6), "canvas", bev=0.012)
    for t in (-0.5, 0.0, 0.5):
        box((0, -3.0 + t, zt + 0.3), (2.62, 0.04, 0.62), "dark", bev=0.0)
    hatch(-0.9, 2.2, zt, 0.28)
    grille(0.6, 1.0, zt + 0.01, 1.2, 1.4, 7)
    node("turret")
    tp = (-0.9, 0.3, zt)
    cyl((-0.9, 0.3, zt + 0.15), 0.4, 0.3, "paint", seg=16)
    for k in range(6):
        a = k * math.tau / 6
        periscope(-0.9 + math.cos(a) * 0.37, 0.3 + math.sin(a) * 0.37, zt + 0.2, a + math.pi / 2, small=True)
    node("barrel")
    mg(-0.9, 0.6, zt + 0.42, 0.0, 1.1, True)
    return {"body": (0, 0, 0), "turret": tp, "barrel": (-0.9, 0.6, zt + 0.42)}, {"muzzle": (-0.9, 1.7, zt + 0.42), "radius": 3.3}

FAMILIES = {"apc_box": apc_box, "apc_tr": apc_tr, "ifv_tr": ifv_tr, "apc_amph": apc_amph, "td_box": td_box, "td_ontos": td_ontos,
            "spg": spg, "spg_open": spg_open, "mortar_tr": mortar_tr, "mlrs_t": mlrs_t,
            "eng_breach": eng_breach, "eng_dozer": eng_dozer, "eng_bridge": eng_bridge, "eng_recovery": eng_recovery}
