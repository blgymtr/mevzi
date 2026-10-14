# Hava aileleri: taarruz/hafif/genel maksat/tandem/ağır helikopter, tiltrotor, dörtpervaneli kamikaze;
# ayrıca çekili topçu (obüs, sahra topu, ağır havan).
# Helikopter düğümleri: body, rotor (ana rotor göbeği), trotor (kuyruk rotoru; tandem/tiltrotor'da ikinci ana rotor).
import math
from vlib import *

def blades(cx, cy, cz, n, R, chord=0.32, droop=0.0, mname="dark", y_axis=True, phase=0.0):
    """Rotor palleri: göbek etrafında n adet (Z ekseni etrafında)."""
    cyl((cx, cy, cz), 0.22, 0.25, "metal", seg=10)
    for k in range(n):
        a = phase + k * math.tau / n
        # R = rotor çapı; her pal göbekten uca R/2
        mx, my = math.cos(a) * R * 0.25, math.sin(a) * R * 0.25
        box((cx + mx, cy + my, cz + 0.05 - droop), (R * 0.5, chord, 0.05), mname, rot=(0, 0, a), bev=0.0)

def tail_blades(cx, cy, cz, n, R, side=-1):
    """Kuyruk rotoru: X ekseni etrafında dönen diskte (YZ düzleminde) paller."""
    cyl((cx, cy, cz), 0.12, 0.2, "metal", "X", seg=8)
    for k in range(n):
        a = k * math.tau / n
        box((cx + side * 0.05, cy + math.cos(a) * R * 0.25, cz + math.sin(a) * R * 0.25), (0.04, R * 0.5, 0.16), "dark", rot=(a, 0, 0), bev=0.0)

def canopy(y0, y1, z0, z1, w, mname="glass"):
    slab(y1, y1 - 0.25, y0, y0, z0, z1, w, w * 0.8, mname, bev=0.02)

def skids(L, W, z=0.12):
    for s in (-1, 1):
        cyl((s * W, 0.0, z), 0.05, L, "dark", "Y", seg=6)
        for y in (0.8, -0.8):
            box((s * W * 0.7, y, z + 0.4), (W * 0.6, 0.06, 0.06), "dark", rot=(0, s * 0.9, 0), bev=0.0)

def heli_atk(v):
    # tandem kokpit, dar gövde, yan motorlar, kanatçıklarda füze/roket, burun altı top
    slab(2.1, 1.6, -1.6, -1.8, 0.55, 1.5, 0.5, 0.42, "paint", bev=0.05, wf=0.3)
    slab(3.4, 3.1, 2.1, 2.1, 0.6, 1.25, 0.35, 0.3, "paint", bev=0.05, wf=0.18)              # burun
    canopy(0.9, 2.9, 1.25, 1.85, 0.4)
    box((0, 1.9, 1.62), (0.82, 0.06, 0.5), "paint", bev=0.0)                                # kokpit ayırıcı
    for s in (-1, 1):
        box((s * 0.68, -0.4, 1.45), (0.42, 2.0, 0.5), "paint", bev=0.06)                    # motor
        cyl((s * 0.68, -1.45, 1.5), 0.18, 0.3, "dark", "Y", seg=10)
        box((s * 1.25, 0.2, 0.95), (1.4, 0.7, 0.1), "paint", rot=(0, s * -0.08, 0), bev=0.02)  # kanatçık
        for k, x in enumerate((1.15, 1.75)):
            if k == 0:
                for i in range(2):
                    for j in range(2):
                        cyl((s * (x - 0.1 + i * 0.2), 0.35, 0.72 - j * 0.2), 0.08, 1.5, "paint", "Y", seg=8)   # füzeler
            else:
                cyl((s * x, 0.4, 0.7), 0.24, 1.6, "paint", "Y", seg=12)                    # roket kovanı
                cyl((s * x, 1.2, 0.7), 0.2, 0.04, "dark", "Y", seg=12)
        cyl((s * 0.55, 1.3, 0.25), 0.22, 0.14, "rubber", "X", seg=12)                       # tekerlek
        box((s * 0.45, 1.3, 0.5), (0.08, 0.1, 0.5), "dark", rot=(0, s * 0.4, 0), bev=0.0)
    # kuyruk
    slab(-1.6, -1.6, -6.6, -6.6, 0.95, 1.45, 0.32, 0.25, "paint", bev=0.03, wf=0.28)
    slab(-5.9, -6.2, -7.1, -6.9, 1.2, 3.0, 0.08, 0.06, "paint", bev=0.02)                  # dikey kuyruk
    box((0, -6.6, 1.35), (2.2, 0.55, 0.06), "paint", bev=0.01)                              # yatay stab
    cyl((0, -6.7, 0.35), 0.1, 0.08, "rubber", "X", seg=8)
    # burun altı top + sensör
    cyl((0, 2.6, 0.45), 0.2, 0.25, "dark", seg=10)
    gun(2.6, 0.32, 1.1, 0.03, "dark")
    cyl((0, 3.35, 0.95), 0.22, 0.35, "paint", "Y", seg=12)
    mast_z = 2.05
    cyl((0, 0.2, 1.75), 0.14, 0.6, "metal", seg=8)
    if v.get("radar"):
        cyl((0, 0.2, mast_z + 0.55), 0.42, 0.32, "paint", seg=14)                          # direk radarı
    node("rotor")
    blades(0, 0.2, mast_z, 4, 14.6)
    node("trotor")
    tail_blades(-0.12, -6.75, 2.6, 4, 2.8, -1)
    return {"body": (0, 0, 0), "rotor": (0, 0.2, mast_z), "trotor": (-0.12, -6.75, 2.6)}, {"muzzle": (0, 3.7, 0.32), "radius": 3.6}

def heli_slim(v):
    util = v.get("utility", False)
    W = 0.6 if util else 0.45
    slab(2.4, 1.8, -1.5, -1.7, 0.45, 1.75, W, W - 0.08, "paint", bev=0.05, wf=W - 0.2)
    slab(3.3, 3.0, 2.4, 2.4, 0.5, 1.35, W - 0.1, W - 0.2, "paint", bev=0.05, wf=0.15)
    canopy(1.0, 3.0, 1.35, 1.95, W - 0.08) if not util else canopy(1.6, 3.1, 1.0, 1.75, W - 0.05)
    if util:
        for s in (-1, 1):
            box((s * W, 0.2, 1.1), (0.04, 1.4, 0.7), "glass", bev=0.0)
    box((0, -0.6, 1.95), (0.9, 1.8, 0.45), "paint", bev=0.06)                                # motor
    for s in (-1, 1):
        if not util:
            box((s * 0.95, 0.2, 0.95), (1.1, 0.6, 0.1), "paint", bev=0.02)
            for i in range(2):
                cyl((s * (0.8 + i * 0.4), 0.3, 0.75), 0.11, 1.4, "paint", "Y", seg=8)
    skids(3.6, W + 0.4)
    slab(-1.5, -1.5, -6.8, -6.8, 1.0, 1.55, 0.3, 0.2, "paint", bev=0.03, wf=0.25)
    slab(-6.2, -6.4, -7.2, -7.1, 1.3, 2.9, 0.07, 0.06, "paint", bev=0.02)
    box((0, -5.9, 1.25), (1.8, 0.45, 0.06), "paint", bev=0.01)
    if not util:
        cyl((0, 2.7, 0.35), 0.18, 0.2, "dark", seg=10)
        gun(2.7, 0.25, 0.9, 0.03, "dark")
    mast_z = 2.45
    cyl((0, 0.0, 2.2), 0.12, 0.5, "metal", seg=8)
    node("rotor")
    blades(0, 0.0, mast_z, 4, 14.6)
    node("trotor")
    tail_blades(0.1, -6.9, 2.5, 4, 2.6, 1)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, mast_z), "trotor": (0.1, -6.9, 2.5)}, {"muzzle": (0, 3.6, 0.25), "radius": 3.6}

def heli_light(v):
    cabin = v.get("cabin", False)
    if cabin:
        slab(2.3, 1.7, -1.8, -2.0, 0.4, 1.9, 0.75, 0.65, "paint", bev=0.08, wf=0.45)
        canopy(1.3, 2.4, 0.9, 1.75, 0.6)
        for s in (-1, 1):
            box((s * 0.74, 0.1, 1.25), (0.03, 1.5, 0.6), "glass", bev=0.0)
        L_tail = -5.5
    else:
        # yumurta gövde (dışbükey nokta bulutu)
        pts = []
        for k in range(12):
            a = k * math.tau / 12
            for (y, rr, zc) in ((1.7, 0.25, 1.0), (1.1, 0.7, 1.05), (0.0, 0.75, 1.1), (-1.0, 0.55, 1.2)):
                pts.append((math.cos(a) * rr, y, zc + math.sin(a) * rr * 0.95))
        hull_pts(pts, "paint", bev=0.0)
        canopy(0.4, 1.7, 1.1, 1.8, 0.6)
        L_tail = -4.6
        if not v.get("mast"):
            for s in (-1, 1):
                box((s * 0.95, 0.0, 0.85), (0.8, 0.2, 0.08), "dark", bev=0.0)
                cyl((s * 1.25, 0.2, 0.7), 0.15, 1.2, "paint", "Y", seg=10)
                gun(-0.2, 0.7, 1.1, 0.03, "dark", x=s * 0.85)
    skids(2.8, 0.85)
    slab(-0.9, -0.9, L_tail, L_tail, 1.15, 1.45, 0.18, 0.12, "paint", bev=0.02, wf=0.14)
    slab(L_tail + 0.4, L_tail + 0.2, L_tail - 0.3, L_tail - 0.25, 1.3, 2.4, 0.06, 0.05, "paint", bev=0.0)
    box((0, L_tail + 0.4, 1.35), (1.3, 0.35, 0.05), "paint", bev=0.0)
    mast_z = 2.2 if not cabin else 2.35
    cyl((0, 0.0, mast_z - 0.25), 0.1, 0.5, "metal", seg=8)
    if v.get("mast"):
        cyl((0, 0.0, mast_z + 0.45), 0.3, 0.45, "paint", seg=12)                          # direk üstü nişangâh
    node("rotor")
    blades(0, 0.0, mast_z, 5 if not cabin else 4, 8.6 if not cabin else 11.0, chord=0.25)
    node("trotor")
    tail_blades(0.08, L_tail - 0.05, 2.0, 2, 1.6, 1)
    return {"body": (0, 0, 0), "rotor": (0, 0.0, mast_z), "trotor": (0.08, L_tail - 0.05, 2.0)}, {"muzzle": (0, 1.4, 0.7), "radius": 2.8}

def heli_utility(v):
    slab(3.2, 2.6, -2.2, -2.4, 0.45, 2.0, 0.95, 0.85, "paint", bev=0.08, wf=0.55)
    slab(3.8, 3.5, 3.2, 3.2, 0.55, 1.5, 0.6, 0.5, "paint", bev=0.06, wf=0.25)
    canopy(2.0, 3.6, 1.3, 2.0, 0.85)
    for s in (-1, 1):
        box((s * 0.95, 0.3, 1.25), (0.04, 1.6, 0.9), "paint", bev=0.0)                       # kayar kapı
        box((s * 0.97, 0.3, 1.45), (0.02, 0.5, 0.35), "glass", bev=0.0)
        box((s * 0.6, -0.9, 2.15), (0.5, 2.0, 0.5), "paint", bev=0.06)                       # motor
        cyl((s * 0.95, 2.3, 0.25), 0.26, 0.18, "rubber", "X", seg=12)
        box((s * 0.85, 2.3, 0.5), (0.08, 0.1, 0.5), "dark", bev=0.0)
        if v.get("armed"):
            box((s * 1.5, 0.6, 1.6), (1.4, 0.5, 0.08), "paint", rot=(0, s * -0.15, 0), bev=0.02)
            cyl((s * 1.85, 0.7, 1.4), 0.24, 1.6, "paint", "Y", seg=12)
            for i in range(2):
                cyl((s * (1.35 + i * 0.2), 0.7, 1.4), 0.08, 1.5, "paint", "Y", seg=8)
    slab(-2.2, -2.2, -8.6, -8.6, 1.2, 1.9, 0.55, 0.3, "paint", bev=0.04, wf=0.4)
    slab(-7.8, -8.2, -9.3, -9.1, 1.6, 3.3, 0.1, 0.08, "paint", bev=0.02)
    box((0, -8.6, 1.9), (2.6, 0.6, 0.06), "paint", bev=0.01)
    cyl((0, -8.4, 0.5), 0.12, 0.1, "rubber", "X", seg=8)
    mast_z = 2.75
    cyl((0, 0.2, 2.5), 0.16, 0.5, "metal", seg=8)
    node("rotor")
    blades(0, 0.2, mast_z, 4, 16.4, chord=0.5)
    node("trotor")
    tail_blades(0.15, -9.0, 3.0, 4, 3.3, 1)
    return {"body": (0, 0, 0), "rotor": (0, 0.2, mast_z), "trotor": (0.15, -9.0, 3.0)}, {"muzzle": (1.0, 0.8, 1.4), "radius": 4.0}

def heli_tandem(v):
    L = 15.5
    slab(L / 2 - 1.2, L / 2 - 2.0, -L / 2 + 1.5, -L / 2 + 1.5, 0.6, 3.4, 1.35, 1.25, "paint", bev=0.1)
    slab(L / 2, L / 2 - 0.4, L / 2 - 1.2, L / 2 - 1.2, 0.8, 2.6, 0.95, 0.85, "paint", bev=0.08, wf=0.55)
    canopy(L / 2 - 1.6, L / 2 - 0.2, 2.0, 2.75, 1.0)
    slab(-L / 2 + 1.5, -L / 2 + 1.5, -L / 2, -L / 2 + 0.3, 1.6, 3.4, 1.25, 1.1, "paint", bev=0.08)   # arka rampa bölümü
    box((0, -L / 2 + 0.6, 4.2), (1.4, 2.2, 1.6), "paint", bev=0.1)                                 # arka pilon
    box((0, L / 2 - 1.4, 3.6), (1.0, 1.2, 0.5), "paint", bev=0.08)                                  # ön pilon
    for s in (-1, 1):
        box((s * 1.6, -3.0, 3.0), (0.6, 2.4, 0.7), "paint", bev=0.1)                                # motorlar
        box((s * 1.45, 0.5, 0.9), (0.4, 7.0, 0.7), "paint", bev=0.1)                                # yan yakıt şişkinlikleri
        cyl((s * 1.45, L / 2 - 2.6, 0.3), 0.3, 0.25, "rubber", "X", seg=12)
        cyl((s * 1.45, -L / 2 + 2.6, 0.3), 0.3, 0.25, "rubber", "X", seg=12)
        for k in range(6):
            box((s * 1.37, 3.0 - k * 1.2, 2.3), (0.02, 0.4, 0.35), "glass", bev=0.0)
    node("rotor")
    blades(0, L / 2 - 1.4, 4.0, 3, 18.3, chord=0.65)
    node("trotor")
    blades(0, -L / 2 + 0.6, 5.2, 3, 18.3, chord=0.65, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (0, L / 2 - 1.4, 4.0), "trotor": (0, -L / 2 + 0.6, 5.2)}, {"muzzle": (1.3, 3.0, 2.0), "radius": 6.0, "trotor_y": True}

def heli_heavy(v):
    slab(5.0, 4.0, -3.5, -4.0, 0.6, 3.3, 1.45, 1.35, "paint", bev=0.12, wf=0.9)
    slab(5.9, 5.5, 5.0, 5.0, 0.8, 2.4, 0.9, 0.7, "paint", bev=0.1, wf=0.4)
    canopy(4.2, 5.6, 1.9, 2.75, 1.05)
    for s in (-1, 1):
        box((s * 1.8, 0.0, 0.9), (0.8, 3.0, 0.9), "paint", bev=0.12)                                # sponson
        box((s * 0.9, -1.0, 3.6), (0.8, 3.2, 0.8), "paint", bev=0.1)                                # motor
        cyl((s * 1.8, 0.2, 0.3), 0.32, 0.3, "rubber", "X", seg=12)
        for k in range(4):
            box((s * 1.47, 2.5 - k * 1.1, 2.2), (0.02, 0.4, 0.35), "glass", bev=0.0)
    box((0, 0.2, 3.6), (1.2, 2.2, 0.8), "paint", bev=0.12)
    slab(-4.0, -4.0, -12.5, -12.5, 1.8, 3.2, 0.9, 0.4, "paint", bev=0.06, wf=0.6)
    slab(-11.6, -12.2, -13.4, -13.1, 2.4, 5.6, 0.14, 0.1, "paint", bev=0.03)
    box((1.3, -12.6, 5.2), (2.5, 0.8, 0.08), "paint", rot=(0, -0.3, 0), bev=0.0)
    cyl((0, 0.2, 4.2), 0.25, 0.6, "metal", seg=10)
    node("rotor")
    blades(0, 0.2, 4.55, 7, 24.0, chord=0.75)
    node("trotor")
    tail_blades(-0.2, -12.9, 5.0, 4, 6.0, -1)
    return {"body": (0, 0, 0), "rotor": (0, 0.2, 4.55), "trotor": (-0.2, -12.9, 5.0)}, {"muzzle": (1.4, 3.0, 2.0), "radius": 7.0}

def tiltrotor(v):
    slab(5.0, 3.8, -4.5, -5.0, 0.6, 3.0, 1.35, 1.2, "paint", bev=0.12, wf=0.85)
    slab(6.4, 6.0, 5.0, 5.0, 0.9, 2.3, 0.85, 0.65, "paint", bev=0.1, wf=0.35)
    canopy(4.4, 6.2, 1.9, 2.7, 1.0)
    slab(-5.0, -5.0, -8.6, -8.4, 1.5, 3.0, 0.8, 0.5, "paint", bev=0.06)
    box((0, -8.3, 3.0), (5.4, 1.0, 0.1), "paint", bev=0.02)
    for s in (-1, 1):
        slab(-7.8, -8.2, -9.0, -8.8, 3.0, 5.2, 0.08, 0.06, "paint", bev=0.0)
        box((s * 2.7, -8.4, 4.0), (0.1, 1.0, 2.0), "paint", bev=0.02)                               # ikiz kuyruk
        box((s * 1.75, 0.5, 0.9), (0.6, 3.4, 0.9), "paint", bev=0.12)
        cyl((s * 1.75, 0.6, 0.3), 0.3, 0.3, "rubber", "X", seg=12)
    box((0, 0.2, 3.35), (14.0, 1.8, 0.28), "paint", bev=0.04)                                       # kanat
    for s in (-1, 1):
        cyl((s * 7.0, 0.4, 3.6), 0.55, 2.4, "paint", seg=12)                                       # dikey nasel
    node("rotor")
    blades(-7.0, 0.4, 5.0, 3, 11.6, chord=0.6)
    node("trotor")
    blades(7.0, 0.4, 5.0, 3, 11.6, chord=0.6, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (-7.0, 0.4, 5.0), "trotor": (7.0, 0.4, 5.0)}, {"muzzle": (0, 6.2, 1.2), "radius": 7.0, "trotor_y": True}

def fpv(v):
    box((0, 0, 0.1), (0.18, 0.26, 0.08), "dark", bev=0.01)
    box((0, 0.05, 0.02), (0.08, 0.14, 0.08), "paint", bev=0.01)                                    # harp başlığı
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        box((math.cos(a) * 0.17, math.sin(a) * 0.17, 0.12), (0.34, 0.03, 0.02), "dark", rot=(0, 0, a), bev=0.0)
        cyl((math.cos(a) * 0.3, math.sin(a) * 0.3, 0.15), 0.12, 0.01, "metal", seg=12)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0.2, 0.0), "radius": 0.6}

# ------------------------------------------------------------ çekili topçu
def howitzer(v):
    heavy = v.get("heavy", False) or v.get("old", False)
    # açık ayaklı kuyruk + taban + iki teker
    for s in (-1, 1):
        box((s * 0.55, -2.4, 0.3), (0.18, 3.8, 0.2), "paint", rot=(0, 0, s * 0.22), bev=0.02)
        box((s * 1.0, -4.15, 0.12), (0.4, 0.3, 0.25), "metal", bev=0.02)                           # pençe
    n = wheels_axles([0.0], 1.05, 0.55 if heavy else 0.45, 0.32)
    box((0, 0.0, 0.55), (1.6, 0.9, 0.3), "paint", bev=0.03)
    box((0, 0.3, 0.2), (1.2, 1.0, 0.1), "metal", bev=0.02)                                         # taban plakası
    node("turret")
    box((0, 0.1, 0.95), (1.0, 1.2, 0.5), "paint", bev=0.03)
    for s in (-1, 1):
        box((s * 0.45, 0.1, 1.25), (0.08, 1.0, 0.5), "paint", bev=0.02)
    node("barrel")
    bz = 1.45
    box((0, -0.2, bz), (0.5, 1.4, 0.42), "paint", bev=0.03)                                        # geri tepme kızağı
    gun(0.3, bz, 5.2 if not v.get("old") else 3.8, 0.085, "paint", brake=True)
    L = 5.2 if not v.get("old") else 3.8
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.1, 0.95), "barrel": (0, 0.1, bz)}), {"muzzle": (0, 0.3 + L + 0.2, bz), "radius": 2.0}

def fieldgun(v):
    box((0, -1.7, 0.35), (0.3, 3.0, 0.25), "paint", rot=(0.12, 0, 0), bev=0.02)                    # kutu kuyruk
    box((0, -3.2, 0.12), (0.5, 0.3, 0.2), "metal", bev=0.02)
    wheels_axles([0.0], 0.85, 0.42, 0.26)
    box((0, 0.0, 0.5), (1.4, 0.5, 0.25), "paint", bev=0.03)
    node("turret")
    box((0, 0.0, 0.8), (0.7, 0.8, 0.35), "paint", bev=0.03)
    node("barrel")
    bz = 1.05
    box((0, -0.1, bz), (0.36, 1.0, 0.3), "paint", bev=0.03)
    gun(0.3, bz, 3.3 if not v.get("old") else 2.6, 0.06, "paint", brake=not v.get("old"))
    L = 3.3 if not v.get("old") else 2.6
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.0, 0.8), "barrel": (0, 0.0, bz)}), {"muzzle": (0, 0.3 + L + 0.15, bz), "radius": 1.6}

def hmortar(v):
    cyl((0, 0.0, 0.08), 0.55, 0.12, "metal", seg=14)                                                # taban plakası
    wheels_axles([0.6], 0.7, 0.3, 0.2, "dark")
    node("turret")
    for s in (-1, 1):
        box((s * 0.18, 0.55, 0.4), (0.05, 0.05, 0.8), "metal", rot=(0.3, s * 0.3, 0), bev=0.0)     # iki ayak
    node("barrel")
    p = 1.0
    canister(0, 0.25, 0.85, 1.75, 0.07, p, "dark")
    mz = (0, 0.25 + 0.88 * math.cos(p), 0.85 + 0.88 * math.sin(p))
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.3, 0.15), "barrel": (0, 0.25, 0.85)}), {"muzzle": mz, "radius": 1.2}

FAMILIES = {"heli_atk": heli_atk, "heli_slim": heli_slim, "heli_light": heli_light, "heli_utility": heli_utility,
            "heli_tandem": heli_tandem, "heli_heavy": heli_heavy, "tiltrotor": tiltrotor, "fpv": fpv,
            "howitzer": howitzer, "fieldgun": fieldgun, "hmortar": hmortar}
