# Tekerlekli aileler: 8x8 (ZPT/ZMA/tanksavar/topçu destek/havan/hava savunma), 4x4 zırhlı, MRAP 4x4/6x6,
# hafif taktik araçlar, kamyon tabanlı roketatar / füze / hava savunma sistemleri.
import math
from vlib import *

# ------------------------------------------------------------ 8x8 şasi
def chassis8(v):
    lav = v.get("lav", False) or v.get("light", False)
    amph = v.get("amph", False)
    L = 6.4 if lav else 6.95
    W = 2.5 if lav else 2.72
    r = 0.5 if lav else 0.56
    ax = [2.15, 1.0, -0.85, -2.05] if not lav else [2.0, 0.85, -0.8, -1.95]
    if amph:
        ax = [2.45, 1.05, -0.95, -2.35]
        L = 7.6
    wheels_axles(ax, W / 2 - 0.22, r, 0.4)
    zb = r * 0.95
    zt = zb + (1.25 if not amph else 1.35)
    # alt V gövde + üst kutu + eğik burun + çamurluk kemerleri
    slab(L / 2 - 0.9, L / 2 - 0.1, -L / 2 + 0.2, -L / 2 + 0.4, zb - 0.35, zb + 0.15, 0.55, W / 2 - 0.45, "paint")
    slab(L / 2 - 0.05 if not amph else L / 2 + 0.25, L / 2 - 1.05, -L / 2, -L / 2, zb + 0.1, zt, W / 2 - 0.02, W / 2 - 0.12, "paint", bev=0.04, wf=W / 2 - 0.35)
    if amph:
        slab(L / 2 + 0.3, L / 2 - 0.2, L / 2 - 0.3, L / 2 + 0.05, zb - 0.1, zb + 0.35, 0.6, W / 2 - 0.1, "paint")   # tekne burnu
    for s in (-1, 1):
        for y in ax:
            box((s * (W / 2 - 0.05), y, zb + r * 0.62), (0.18, r * 2.3, 0.08), "paint", bev=0.02)
        light(s * (W / 2 - 0.35), L / 2 - 0.25 if not amph else L / 2 + 0.05, zb + 0.55)
        box((s * (W / 2 + 0.02), -0.3, zt - 0.35), (0.06, 2.6, 0.4), "paint", bev=0.015)        # yan zırh paneli
        for k in range(3):
            box((s * (W / 2 + 0.06), -1.3 + k * 1.0, zt - 0.35), (0.04, 0.12, 0.3), "dark", bev=0.0)
        jerrycan(s * (W / 2 - 0.3), -L / 2 - 0.05, zb + 0.7, 0.0)
    # sürücü kapağı + periskoplar, arka rampa
    hatch(-0.55 if not lav else 0.55, L / 2 - 1.35, zt, 0.28)
    for k in (-1, 0, 1):
        periscope((-0.55 if not lav else 0.55) + k * 0.2, L / 2 - 1.05, zt - 0.02, -k * 0.3)
    box((0, -L / 2 - 0.03, zb + 0.75), (W * 0.62, 0.06, 1.1), "paint", bev=0.02)
    grille(0.75, L / 2 - 2.0, zt + 0.01, 0.7, 0.9, 6)
    antenna(-1.0, -L / 2 + 0.5, zt, 1.6)
    antenna(1.0, -L / 2 + 0.5, zt, 1.6 if not v.get("cmd") else 2.4)
    if v.get("cmd"):
        antenna(0.0, -L / 2 + 0.8, zt, 2.6)
        box((0, -1.2, zt + 0.15), (1.2, 1.3, 0.3), "paint", bev=0.03)
    return L, W, zt

def apc_8x8(v):
    L, W, zt = chassis8(v)
    node("turret")
    tp = (0.35, 0.1, zt)
    rws(tp[0], tp[1], tp[2], True, False)
    node("barrel")
    mg(tp[0] - 0.05, tp[1] + 0.5, tp[2] + 0.32, 0.0, 1.15, True)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (tp[0], tp[1] + 0.3, tp[2] + 0.3)}), {"muzzle": (tp[0], tp[1] + 1.4, tp[2] + 0.32), "radius": 2.5}

def ifv_8x8(v):
    L, W, zt = chassis8(v)
    node("turret")
    lav = v.get("light", False)
    ty = 0.2 if lav else 0.0
    tz = zt
    if lav:
        # iki kişilik taret
        slab(0.95, 0.7, -0.9, -0.95, tz, tz + 0.62, 0.85, 0.72, "paint")
        hatch(0.35, -0.3, tz + 0.62, 0.25); hatch(-0.35, -0.3, tz + 0.62, 0.25)
        box((0.45, 0.6, tz + 0.75), (0.25, 0.3, 0.22), "paint", bev=0.02)
    else:
        # insansız 30 mm taret (alçak, köşeli)
        slab(1.0, 0.7, -0.9, -1.0, tz, tz + 0.55, 0.9, 0.7, "paint", wf=0.45)
        box((0.6, 0.0, tz + 0.7), (0.3, 0.4, 0.28), "paint", bev=0.02)
        box((0.6, 0.2, tz + 0.7), (0.2, 0.02, 0.14), "glass", bev=0.0)
        box((-0.55, -0.5, tz + 0.65), (0.4, 0.45, 0.22), "paint", bev=0.02)    # mühimmat kutusu
        mg(-0.45, 0.4, tz + 0.65, 0.0, 0.8, False)
    for s in (-1, 1):
        smoke_launchers(s * 0.8, 0.55 + ty, tz + 0.35, s * 0.6, 4, s)
    node("barrel")
    bz = tz + 0.32
    cyl((0, 1.0 + ty, bz), 0.12, 0.35, "paint", "Y", seg=10)
    gun(1.1 + ty, bz, 2.2 if not lav else 1.9, 0.045, "dark", sleeve=0.4)
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, ty, tz), "barrel": (0, 0.95 + ty, bz)}), {"muzzle": (0, 3.3 + ty, bz), "radius": 2.5}

def td_8x8(v):
    L, W, zt = chassis8(v)
    node("turret")
    tz = zt
    if v.get("lav"):
        cyl((0, -0.3, tz + 0.2), 0.7, 0.4, "paint", seg=12, bev=0.02)
        box((0, -0.3, tz + 0.65), (0.6, 0.8, 0.5), "paint", bev=0.03)
        node("barrel")
        for s in (-1, 1):
            canister(s * 0.42, 0.1, tz + 0.75, 1.3, 0.11, 0.06)
        bp = (0, 0.0, tz + 0.75)
    else:
        cyl((0.2, -0.6, tz + 0.15), 0.45, 0.3, "paint", seg=12)
        cyl((0.2, -0.6, tz + 0.6), 0.12, 0.6, "metal", seg=8)                 # yükseltme direği
        node("barrel")
        box((0.2, -0.45, tz + 1.05), (0.7, 0.9, 0.5), "paint", bev=0.03)      # ikiz füze kutusu + sensör
        for s in (-1, 1):
            box((0.2 + s * 0.2, 0.02, tz + 1.05), (0.24, 0.02, 0.36), "dark", bev=0.0)
        box((0.68, -0.3, tz + 1.05), (0.22, 0.4, 0.3), "paint", bev=0.02)
        bp = (0.2, -0.45, tz + 1.05)
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, -0.3, tz), "barrel": bp}), {"muzzle": (bp[0], bp[1] + 0.9, bp[2]), "radius": 2.5}

def td_gun8x8(v):
    L, W, zt = chassis8(v)
    node("turret")
    tz = zt
    slab(1.2, 1.0, -1.4, -1.5, tz, tz + 0.5, 0.95, 0.85, "paint", wf=0.5)
    box((0.55, -0.3, tz + 0.62), (0.35, 0.4, 0.25), "paint", bev=0.02)
    rws(-0.5, -0.6, tz + 0.5, False, True)
    for s in (-1, 1):
        smoke_launchers(s * 0.85, 0.5, tz + 0.3, s * 0.6, 4, s)
    node("barrel")
    bz = tz + 0.35
    cyl((0, 1.15, bz), 0.15, 0.35, "paint", "Y", seg=12)
    gun(1.3, bz, 3.4, 0.075, "paint", brake=True, sleeve=0.4)
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0, tz), "barrel": (0, 1.1, bz)}), {"muzzle": (0, 4.9, bz), "radius": 2.6}

def mortar_8x8(v):
    L, W, zt = chassis8(v)
    # açık tavan kapakları + içte havan
    for s in (-1, 1):
        box((s * 0.9, -1.4, zt + 0.35), (0.06, 1.8, 0.7), "paint", rot=(0, s * 0.5, 0), bev=0.02)
    node("turret")
    tz = zt - 0.3
    cyl((0, -1.4, tz + 0.1), 0.45, 0.2, "metal", seg=12)
    node("barrel")
    canister(0, -1.2, tz + 0.75, 1.7, 0.09, 1.0, "dark")
    cyl((0, -1.2 + 0.85 * math.cos(1.0), tz + 0.75 + 0.85 * math.sin(1.0)), 0.11, 0.1, "dark", rot=(math.pi / 2 - 1.0, 0, 0))
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, -1.4, tz), "barrel": (0, -1.2, tz + 0.75)}), {"muzzle": (0, -1.2 + 0.85 * math.cos(1.0), tz + 0.75 + 0.85 * math.sin(1.0)), "radius": 2.5}

def aa_8x8(v):
    L, W, zt = chassis8(v)
    node("turret")
    tz = zt
    cyl((0, -0.4, tz + 0.18), 0.65, 0.36, "paint", seg=12, bev=0.02)
    box((0, -0.4, tz + 0.6), (0.9, 0.95, 0.5), "paint", bev=0.03)
    box((0.3, 0.05, tz + 0.95), (0.3, 0.3, 0.22), "paint", bev=0.02)                # sensör kafası
    box((0.3, 0.21, tz + 0.95), (0.2, 0.02, 0.14), "glass", bev=0.0)
    node("barrel")
    bz = tz + 0.62
    for s in (-1, 1):
        podbox(s * 0.72, -0.35, bz + 0.1, 0.36, 0.95, 0.42, 0.18, (2, 2))            # füze kutuları
    gun(0.1, bz - 0.05, 1.8 if not v.get("lav") else 1.4, 0.04, "dark", sleeve=0.3)
    if v.get("lav"):
        for k in range(5):
            a = k * math.tau / 5
            gun(0.1, bz - 0.05 + math.sin(a) * 0.06, 1.4, 0.018, "dark", x=math.cos(a) * 0.06)
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, -0.4, tz), "barrel": (0, -0.3, bz)}), {"muzzle": (0, 1.9, bz - 0.05), "radius": 2.5}

# ------------------------------------------------------------ 4x4 zırhlı keşif (V gövde)
def apc_4x4(v):
    wheels_axles([1.55, -1.55], 1.02, 0.55, 0.38)
    zb = 0.55
    slab(2.6, 2.3, -2.5, -2.6, zb - 0.25, zb + 0.35, 0.4, 1.12, "paint")                  # V taban
    slab(2.75, 1.7, -2.6, -2.6, zb + 0.3, zb + 1.45, 1.18, 1.05, "paint", bev=0.04, wf=0.95)
    for s in (-1, 1):
        box((s * 1.2, 1.55, zb + 0.5), (0.2, 1.2, 0.1), "paint", bev=0.02)
        box((s * 1.2, -1.55, zb + 0.5), (0.2, 1.2, 0.1), "paint", bev=0.02)
        box((s * 1.19, 0.0, zb + 1.05), (0.03, 0.6, 0.35), "glass", bev=0.0)
        light(s * 0.85, 2.72, zb + 0.55)
    box((0, 2.25, zb + 1.15), (1.6, 0.03, 0.35), "glass", rot=(-0.6, 0, 0), bev=0.0)
    zt = zb + 1.45
    node("turret")
    tp = (0, -0.4, zt)
    cyl((0, -0.4, zt + 0.2), 0.55, 0.4, "paint", seg=10, bev=0.02)
    node("barrel")
    gun(-0.2, zt + 0.25, 1.0, 0.045, "dark", x=0.15)
    gun(-0.2, zt + 0.25, 0.5, 0.06, "dark", x=-0.18)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.2, zt + 0.25)}), {"muzzle": (0.15, 0.85, zt + 0.25), "radius": 2.1}

# ------------------------------------------------------------ MRAP
def mrap4(v):
    tall = v.get("tall", False)
    boxy = v.get("box", False)
    wheels_axles([1.75, -1.6], 1.08, 0.6, 0.42)
    zb = 0.7
    slab(2.9, 2.6, -2.9, -3.0, zb - 0.3, zb + 0.4, 0.35, 1.15, "paint")
    h = 1.75 if tall else 1.5
    slab(3.05, 1.6, -3.0, -3.0, zb + 0.35, zb + 1.0, 1.2, 1.2, "paint", wf=1.15)            # motor kaputu + gövde alt
    slab(1.65, 1.2, -3.0, -3.0, zb + 0.95, zb + h + 0.2, 1.25, 1.15 if not boxy else 1.22, "paint", bev=0.04)
    box((0, 1.45, zb + h - 0.15), (2.0, 0.04, 0.55), "glass", rot=(-0.35, 0, 0), bev=0.0)
    for s in (-1, 1):
        for y in (0.7, -0.4):
            box((s * 1.24, y, zb + h - 0.15), (0.03, 0.55, 0.42), "glass", bev=0.0)
        box((s * 1.2, 1.75, zb + 0.55), (0.25, 1.35, 0.1), "paint", bev=0.02)
        box((s * 1.2, -1.6, zb + 0.55), (0.25, 1.35, 0.1), "paint", bev=0.02)
        light(s * 0.85, 3.05, zb + 0.7)
        box((s * 1.3, 0.2, zb + 0.3), (0.12, 0.6, 0.18), "metal", bev=0.0)                  # basamak
    box((0, 3.1, zb + 0.6), (2.0, 0.12, 0.35), "dark", bev=0.0)                             # tampon
    box((0, -3.02, zb + 1.1), (1.0, 0.05, 1.3), "paint", bev=0.02)                           # arka kapı
    zt = zb + h + 0.2
    node("turret")
    tp = (0, -0.5, zt)
    cyl((0, -0.5, zt + 0.12), 0.55, 0.24, "paint", seg=12)
    for k in range(5):
        a = math.pi * (0.1 + k * 0.2)
        box((math.cos(a) * 0.62, -0.5 + math.sin(a) * 0.62, zt + 0.45), (0.5, 0.06, 0.5), "paint", rot=(0, 0, a - math.pi / 2), bev=0.01)
    node("barrel")
    mg(0, -0.1, zt + 0.5, 0.0, 1.1, True)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.1, zt + 0.5)}), {"muzzle": (0, 1.0, zt + 0.5), "gunner": (0, -0.5, zt - 0.85), "radius": 2.3}

def mrap6(v):
    truck = v.get("truck", False)
    wheels_axles([2.1, -0.9, -2.3], 1.1, 0.6, 0.42)
    zb = 0.72
    slab(3.2, 2.9, -3.4, -3.5, zb - 0.3, zb + 0.4, 0.35, 1.15, "paint")
    if truck:
        cab(2.0, zb + 0.3, 2.4, 2.1, 1.6)
        slab(0.9, 0.9, -3.4, -3.4, zb + 0.35, zb + 1.7, 1.2, 1.2, "paint")
    else:
        slab(3.3, 2.0, -3.4, -3.4, zb + 0.35, zb + 1.0, 1.2, 1.2, "paint", wf=1.12)
        slab(2.05, 1.6, -3.4, -3.4, zb + 0.95, zb + 2.0, 1.25, 1.15, "paint", bev=0.04)
        box((0, 1.85, zb + 1.65), (2.0, 0.04, 0.55), "glass", rot=(-0.35, 0, 0), bev=0.0)
        for s in (-1, 1):
            for y in (1.0, -0.2, -1.4):
                box((s * 1.24, y, zb + 1.65), (0.03, 0.5, 0.4), "glass", bev=0.0)
    for s in (-1, 1):
        for y in (2.1, -0.9, -2.3):
            box((s * 1.2, y, zb + 0.55), (0.25, 1.3, 0.1), "paint", bev=0.02)
        light(s * 0.85, 3.3, zb + 0.7)
    if v.get("arm"):
        # mayın arama kolu (öne uzanan, ucunda pençe)
        box((0.7, 3.6, zb + 1.3), (0.15, 2.2, 0.15), "paint", rot=(0.25, 0, 0), bev=0.0)
        box((0.7, 4.75, zb + 1.0), (0.3, 0.4, 0.25), "metal", bev=0.02)
    zt = zb + 2.0 if not truck else zb + 1.9
    node("turret")
    tp = (0, 0.6 if truck else -0.3, zt)
    cyl((tp[0], tp[1], zt + 0.12), 0.55, 0.24, "paint", seg=12)
    node("barrel")
    mg(0, tp[1] + 0.4, zt + 0.5, 0.0, 1.1, True)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, tp[1] + 0.4, zt + 0.5)}), {"muzzle": (0, tp[1] + 1.5, zt + 0.5), "radius": 2.6}

# ------------------------------------------------------------ hafif taktik araçlar
def _hmmwv_body(tall=False):
    wheels_axles([1.65, -1.65], 0.92, 0.46, 0.34, "dark")
    zb = 0.5
    slab(2.4, 2.2, -2.4, -2.4, zb, zb + 0.5, 1.08, 1.08, "paint", bev=0.03)
    slab(2.45, 0.9, -2.4, -2.4, zb + 0.45, zb + 0.75, 1.08, 1.0, "paint", bev=0.03, wf=0.95)    # kaput
    slab(0.95, 0.65, -2.4, -2.4, zb + 0.7, zb + 1.35 + (0.15 if tall else 0), 1.05, 1.0, "paint", bev=0.03)
    box((0, 0.75, zb + 1.1), (1.8, 0.04, 0.4), "glass", rot=(-0.3, 0, 0), bev=0.0)
    for s in (-1, 1):
        box((s * 1.06, 0.1, zb + 1.08), (0.03, 0.7, 0.35), "glass", bev=0.0)
        box((s * 1.06, -0.85, zb + 1.08), (0.03, 0.6, 0.35), "glass", bev=0.0)
        light(s * 0.7, 2.42, zb + 0.6)
        box((s * 0.98, 1.65, zb + 0.35), (0.3, 1.0, 0.08), "paint", bev=0.01)
        box((s * 0.98, -1.65, zb + 0.35), (0.3, 1.0, 0.08), "paint", bev=0.01)
    grille(0, 2.42, zb + 0.5, 1.0, 0.04, 1)
    return zb + 1.35 + (0.15 if tall else 0)

def lv_hmmwv(v):
    zt = _hmmwv_body()
    if v.get("cmd"):
        for x in (-0.8, 0.8):
            antenna(x, -2.1, zt - 0.4, 2.4)
        box((0, -1.5, zt + 0.12), (1.6, 1.4, 0.25), "canvas", bev=0.05)
    node("turret")
    tp = (0, -0.4, zt)
    cyl((0, -0.4, zt + 0.08), 0.5, 0.16, "paint", seg=12)
    for k in range(5):
        a = math.pi * (0.1 + k * 0.2)
        box((math.cos(a) * 0.55, -0.4 + math.sin(a) * 0.55, zt + 0.4), (0.45, 0.05, 0.5), "paint", rot=(0, 0, a - math.pi / 2), bev=0.01)
    node("barrel")
    if v.get("cmd"):
        mg(0, 0.0, zt + 0.42, 0.0, 0.8, False)
    else:
        mg(0, 0.0, zt + 0.45, 0.0, 1.1, True)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, 0.0, zt + 0.45)}), {"muzzle": (0, 1.1, zt + 0.45), "gunner": (0, -0.4, zt - 0.85), "radius": 1.9}

def lv_tow(v):
    zt = _hmmwv_body()
    node("turret")
    tp = (0, -0.4, zt)
    cyl((0, -0.4, zt + 0.08), 0.5, 0.16, "paint", seg=12)
    node("barrel")
    box((0, -0.3, zt + 0.55), (0.35, 0.45, 0.35), "paint", bev=0.02)
    canister(0, 0.3, zt + 0.6, 1.6, 0.11, 0.05)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.3, zt + 0.55)}), {"muzzle": (0, 1.1, zt + 0.6), "gunner": (0, -0.4, zt - 0.85), "radius": 1.9}

def lv_sam(v):
    zt = _hmmwv_body()
    node("turret")
    tp = (0, -1.2, zt - 0.2)
    cyl((0, -1.2, zt), 0.6, 0.3, "paint", seg=12)
    box((0, -1.2, zt + 0.5), (0.8, 0.8, 0.75), "paint", bev=0.03)
    box((0, -0.79, zt + 0.6), (0.5, 0.02, 0.4), "glass", bev=0.0)
    node("barrel")
    for s in (-1, 1):
        podbox(s * 0.62, -1.15, zt + 0.6, 0.36, 1.2, 0.36, 0.1, (2, 2))
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.15, zt + 0.6)}), {"muzzle": (0, -0.5, zt + 0.66), "radius": 1.9}

def lv_jltv(v):
    wheels_axles([1.8, -1.6], 1.0, 0.55, 0.38, "dark")
    zb = 0.62
    slab(2.6, 2.4, -2.6, -2.7, zb - 0.15, zb + 0.4, 0.4, 1.1, "paint")
    slab(2.75, 1.0, -2.65, -2.65, zb + 0.35, zb + 0.95, 1.12, 1.08, "paint", wf=1.0)
    slab(1.05, 0.7, -1.4, -1.5, zb + 0.9, zb + 1.65, 1.15, 1.02, "paint", bev=0.04)
    box((0, 0.88, zb + 1.35), (1.9, 0.04, 0.45), "glass", rot=(-0.4, 0, 0), bev=0.0)
    for s in (-1, 1):
        box((s * 1.13, 0.2, zb + 1.3), (0.03, 0.6, 0.4), "glass", bev=0.0)
        box((s * 1.13, -0.75, zb + 1.3), (0.03, 0.5, 0.4), "glass", bev=0.0)
        light(s * 0.8, 2.77, zb + 0.7)
        box((s * 1.1, 1.8, zb + 0.45), (0.28, 1.2, 0.08), "paint", bev=0.01)
        box((s * 1.1, -1.6, zb + 0.45), (0.28, 1.2, 0.08), "paint", bev=0.01)
    box((0, -2.1, zb + 0.75), (2.1, 1.1, 0.35), "paint", bev=0.03)                            # arka bölme
    zt = zb + 1.65
    if v.get("cmd"):
        antenna(-0.8, -2.3, zb + 0.95, 2.4); antenna(0.8, -2.3, zb + 0.95, 2.4)
    node("turret")
    tp = (0, -0.3, zt)
    cyl((0, -0.3, zt + 0.1), 0.52, 0.2, "paint", seg=12)
    for k in range(5):
        a = math.pi * (0.1 + k * 0.2)
        box((math.cos(a) * 0.58, -0.3 + math.sin(a) * 0.58, zt + 0.42), (0.47, 0.05, 0.5), "paint", rot=(0, 0, a - math.pi / 2), bev=0.01)
    node("barrel")
    if v.get("atgm"):
        box((0, -0.3, zt + 0.6), (0.5, 0.5, 0.4), "paint", bev=0.03)
        for s in (-1, 1):
            canister(s * 0.32, 0.2, zt + 0.7, 1.4, 0.1, 0.08)
        return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -0.3, zt + 0.6)}), {"muzzle": (0, 0.9, zt + 0.75), "radius": 2.0}
    mg(0, 0.1, zt + 0.45, 0.0, 1.0 if v.get("cmd") else 1.1, not v.get("cmd"))
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, 0.1, zt + 0.45)}), {"muzzle": (0, 1.2, zt + 0.45), "gunner": (0, -0.3, zt - 0.85), "radius": 2.0}

def lv_isv(v):
    wheels_axles([1.65, -1.55], 0.95, 0.45, 0.32, "dark")
    zb = 0.55
    slab(2.45, 2.1, -2.3, -2.4, zb - 0.05, zb + 0.4, 0.8, 1.0, "paint")
    slab(2.5, 1.3, 1.3, 1.25, zb + 0.35, zb + 0.75, 0.98, 0.95, "paint", wf=0.9)
    # açık kafes (roll bar) + koltuklar
    for s in (-1, 1):
        for y in (1.05, -0.3, -1.9):
            box((s * 0.95, y, zb + 1.05), (0.06, 0.06, 1.25), "dark", bev=0.0)
        box((s * 0.95, -0.4, zb + 1.65), (0.06, 3.0, 0.06), "dark", bev=0.0)
        light(s * 0.7, 2.47, zb + 0.6)
    box((0, 1.05, zb + 1.65), (1.9, 0.06, 0.06), "dark", bev=0.0)
    box((0, -1.9, zb + 1.65), (1.9, 0.06, 0.06), "dark", bev=0.0)
    for y in (0.6, -0.4, -1.4):
        for s in (-1, 1):
            box((s * 0.45, y, zb + 0.6), (0.5, 0.5, 0.15), "canvas", bev=0.04)
    zt = zb + 1.7
    node("turret")
    tp = (0, -0.3, zt)
    cyl((0, -0.3, zt + 0.03), 0.15, 0.06, "dark", seg=8)
    node("barrel")
    mg(0, 0.0, zt + 0.15, 0.0, 1.1 if v.get("gun") else 0.8, bool(v.get("gun")))
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, 0.0, zt + 0.15)}), {"muzzle": (0, 1.0, zt + 0.15), "radius": 1.9}

def eng_detect(v):
    # mayın tespit aracı: ince yüksek kabin, büyük tekerler, ön/göbek radar paneli
    wheels_axles([1.9, -1.9], 1.15, 0.68, 0.45)
    zb = 0.85
    slab(2.4, 2.2, -2.4, -2.5, zb, zb + 0.5, 0.5, 0.65, "paint")
    slab(0.9, 0.7, -0.6, -0.7, zb + 0.45, zb + 1.9, 0.55, 0.5, "paint", bev=0.04)
    box((0, 0.8, zb + 1.5), (0.9, 0.04, 0.5), "glass", rot=(-0.2, 0, 0), bev=0.0)
    box((0, 0.0, 0.25), (2.4, 1.0, 0.12), "dark", bev=0.02)                                  # yere gömülü radar
    node("turret")
    tp = (0, -0.2, zb + 1.9)
    cyl((0, -0.2, zb + 2.0), 0.3, 0.2, "paint", seg=10)
    node("barrel")
    mg(0, 0.1, zb + 2.15, 0.0, 0.8, False)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, 0.1, zb + 2.15)}), {"muzzle": (0, 0.9, zb + 2.15), "radius": 2.0}

# ------------------------------------------------------------ kamyon tabanlı sistemler
def _truck6(L_bed=4.2):
    wheels_axles([2.6, -0.6, -1.95], 1.05, 0.58, 0.4, "dark")
    zb = 0.75
    box((0, -0.3, zb + 0.15), (1.0, 6.6, 0.3), "dark", bev=0.0)                              # şasi
    cab(2.45, zb + 0.15, 2.45, 2.0, 1.75)
    box((0, 3.48, zb + 0.4), (2.3, 0.1, 0.35), "dark", bev=0.0)
    for s in (-1, 1):
        light(s * 0.9, 3.47, zb + 0.55)
        box((s * 1.2, 2.6, zb + 0.6), (0.2, 1.3, 0.08), "paint", bev=0.01)
        box((s * 1.2, -1.3, zb + 0.6), (0.2, 2.6, 0.08), "paint", bev=0.01)
        box((s * 1.25, 1.2, zb + 0.4), (0.15, 0.6, 0.45), "paint", bev=0.02)                # yakıt deposu
    return zb + 0.3

def mlrs_w(v):
    zd = _truck6()
    node("turret")
    tp = (0, -1.4, zd)
    box((0, -1.4, zd + 0.15), (2.2, 2.6, 0.3), "paint", bev=0.02)
    node("barrel")
    podbox(0, -1.4, zd + 0.85, 1.2, 3.0, 0.9, 0.0, (2, 3))
    for s in (-1, 1):
        box((s * 0.62, -1.4, zd + 0.85), (0.04, 3.0, 0.9), "paint", bev=0.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -2.4, zd + 0.5)}), {"muzzle": (0, 0.1, zd + 0.85), "radius": 2.3}

def missile_launcher(v):
    hyper = v.get("hyper", False)
    if v.get("jltv"):
        # insansız taktik araç üzerinde ikiz kanister
        wheels_axles([1.8, -1.6], 1.0, 0.55, 0.38, "dark")
        zb = 0.62
        slab(2.6, 2.4, -2.6, -2.7, zb - 0.15, zb + 0.45, 0.45, 1.1, "paint")
        slab(2.75, 1.3, -2.65, -2.65, zb + 0.4, zb + 0.95, 1.12, 1.08, "paint", wf=1.0)
        zd = zb + 0.95
        node("turret")
        tp = (0, -0.8, zd)
        box((0, -0.8, zd + 0.1), (1.6, 1.8, 0.2), "paint", bev=0.02)
        node("barrel")
        for s in (-1, 1):
            box((s * 0.4, -0.8, zd + 0.45), (0.6, 3.2, 0.5), "paint", rot=(0.12, 0, 0), bev=0.03)
        return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -2.0, zd + 0.3)}), {"muzzle": (0, 0.8, zd + 0.6), "radius": 2.0}
    zd = _truck6()
    node("turret")
    tp = (0, -1.4, zd)
    box((0, -1.4, zd + 0.1), (2.2, 3.0, 0.2), "paint", bev=0.02)
    node("barrel")
    if hyper:
        for s in (-1, 1):
            canister(s * 0.55, -1.4, zd + 0.95, 5.5, 0.48, 0.0, "paint", seg=16)
            cyl((s * 0.55, 1.37, zd + 0.95), 0.5, 0.12, "dark", "Y", seg=16)
    elif v.get("twin"):
        for s in (-1, 1):
            box((s * 0.5, -1.4, zd + 0.7), (0.6, 4.0, 0.6), "paint", rot=(0.15, 0, 0), bev=0.03)
    else:
        box((0, -1.4, zd + 1.0), (1.6, 4.6, 1.5), "paint", bev=0.04)                         # dikey hücreli kutu
        for i in range(2):
            for k in range(2):
                box(((i - 0.5) * 0.7, 0.92, zd + 0.65 + k * 0.7), (0.5, 0.02, 0.5), "dark", bev=0.0)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -2.4, zd + 0.6)}), {"muzzle": (0, 1.0, zd + 1.0), "radius": 2.4}

def sam_long(v):
    zd = _truck6()
    node("turret")
    tp = (0, -1.4, zd)
    box((0, -1.4, zd + 0.15), (2.2, 3.0, 0.3), "paint", bev=0.02)
    node("barrel")
    for i in range(2):
        for k in range(2):
            box(((i - 0.5) * 0.85, -1.2, zd + 0.9 + k * 0.85), (0.8, 5.0, 0.8), "paint", rot=(0.55, 0, 0), bev=0.04)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -2.6, zd + 0.4)}), {"muzzle": (0, 0.8, zd + 2.6), "radius": 2.5}

def sam_mid(v):
    zd = _truck6()
    node("turret")
    tp = (0, -1.4, zd)
    cyl((0, -1.4, zd + 0.15), 0.8, 0.3, "paint", seg=12)
    node("barrel")
    for i in range(3):
        for k in range(2):
            canister((i - 1) * 0.42, -1.3, zd + 0.85 + k * 0.42, 3.6, 0.19, 0.4)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.3, zd + 1.0)}), {"muzzle": (0, 0.3, zd + 1.8), "radius": 2.3}

def ciws(v):
    zd = _truck6()
    node("turret")
    tp = (0, -1.4, zd)
    cyl((0, -1.4, zd + 0.3), 0.75, 0.6, "paint", seg=14)
    box((0, -1.65, zd + 1.0), (0.9, 0.8, 0.9), "paint", bev=0.05)
    node("barrel")
    cyl((0, -1.2, zd + 1.9), 0.5, 1.2, "mark", seg=16)                                      # radar kubbesi
    bpy_s = 0
    for k in range(6):
        a = k * math.tau / 6
        gun(-1.25, zd + 1.0 + math.sin(a) * 0.09, 1.6, 0.025, "dark", x=math.cos(a) * 0.09)
    return wheel_pivots({"body": (0, 0, 0), "turret": tp, "barrel": (0, -1.4, zd + 1.0)}), {"muzzle": (0, 0.4, zd + 1.0), "radius": 2.3}

FAMILIES = {"apc_8x8": apc_8x8, "ifv_8x8": ifv_8x8, "td_8x8": td_8x8, "td_gun8x8": td_gun8x8, "mortar_8x8": mortar_8x8,
            "aa_8x8": aa_8x8, "apc_4x4": apc_4x4, "mrap4": mrap4, "mrap6": mrap6, "lv_hmmwv": lv_hmmwv, "lv_tow": lv_tow,
            "lv_sam": lv_sam, "lv_jltv": lv_jltv, "lv_isv": lv_isv, "eng_detect": eng_detect, "mlrs_w": mlrs_w,
            "missile_launcher": missile_launcher, "sam_long": sam_long, "sam_mid": sam_mid, "ciws": ciws}
