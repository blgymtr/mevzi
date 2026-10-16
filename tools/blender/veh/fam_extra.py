# Katalogda karşılığı olmayan taban tipler (Roadmap 10): eski JS modellerinin yerine Blender hattı.
#   atgun   — 100 mm MT-12 Rapira tipi çekili tanksavar topu (uzun namlu, biber kutusu fren, eğik kalkan)
#   mtngun  — 76/75 mm dağ topu (hafif, küçük tekerlek, kısa namlu, sökülebilir kutu kuyruk)
#   aagun   — ZU-23-2 (ikiz 23 mm, iki tekerlekli kundak) / M167 VADS (6 namlulu döner top + radar), ulusa göre
#   coastal — sahil topçusu: beton kaide üstünde 130 mm zırhlı kule (namlu kule düğümünde)
#   truck_fmtv — M1083 FMTV 6×6 kargo kamyonu (branda + kemerler)
import math
from vlib import *
import vlib
import fam_arty
from fam_wheeled import _truck6


def atgun(v):
    p = {"cal": 100, "gl": 6.1, "bf": 0.2, "tl": 4.0, "tw": 1.05, "wr": 0.46, "ww": 0.24, "bz": 0.96, "shield": 1.7,
         "trail": "split", "spread": 1.0, "brake": "multi"}
    p.update(v)
    return fam_arty.fieldgun(p)


def mtngun(v):
    p = {"cal": 76, "gl": 1.75, "bf": 0.2, "tl": 2.5, "tw": 0.78, "wr": 0.33, "ww": 0.12, "bz": 0.78, "shield": 0.0,
         "trail": "box", "brake": "none"}
    p.update(v)
    return fam_arty.fieldgun(p)


def aagun(v):
    vads = vlib.NAT == "usa" or v.get("vads", False)
    # iki tekerlekli kundak + açılır dengeleme ayakları
    za = 0.42
    for i, s in enumerate((-1, 1)):
        tyre(i, s * 0.95, 0.0, za, za, 0.24, s, hub="metal")                                    # döner teker (ayrı düğüm, 137)
        box((s * 0.8, 0.0, za + 0.18), (0.22, 0.9, 0.06), "paint", bev=0.006)                 # çamurluk
        rod((s * 0.5, 0.9, 0.5), (s * 1.6, 1.6, 0.08), 0.05, "metal", 6)                       # dengeleme ayağı
        cyl((s * 1.6, 1.6, 0.04), 0.13, 0.05, "metal", seg=12)
        rod((s * 0.5, -0.9, 0.5), (s * 1.6, -1.6, 0.08), 0.05, "metal", 6)
        cyl((s * 1.6, -1.6, 0.04), 0.13, 0.05, "metal", seg=12)
    box((0, 0.0, 0.52), (1.3, 2.0, 0.22), "paint", bev=0.012)                                  # kundak platformu
    rod((0, 1.0, 0.5), (0, 2.6, 0.45), 0.06, "metal", 8)                                       # çeki oku
    ring((0, 2.62, 0.45), 0.09, 0.025, "metal", "X", seg=10, tseg=4)
    node("turret")
    zt = 0.66
    cyl((0, 0.0, zt), 0.6, 0.12, "paint", seg=24)                                               # döner tabla
    if vads:
        # M167: koltuk, radar çanağı, 6 namlulu M168 döner top, mermi tamburu
        box((0, -0.45, zt + 0.35), (0.5, 0.45, 0.5), "dark", bev=0.01)                         # nişancı koltuğu
        box((0.45, 0.1, zt + 0.42), (0.55, 0.9, 0.62), "paint", bev=0.012)                     # mermi tamburu
        cyl((-0.55, 0.0, zt + 0.95), 0.32, 0.06, "paint", "X", seg=18)                          # radar çanağı
        rod((-0.4, 0.0, zt + 0.3), (-0.5, 0.0, zt + 0.95), 0.03, "metal", 6)
        node("barrel")
        bz = zt + 0.62
        for k in range(6):
            a = k * math.tau / 6
            gun(0.0, bz + math.sin(a) * 0.075, 1.9, 0.022, "gun", x=math.cos(a) * 0.075, bore=True)
        cyl((0, 0.35, bz), 0.12, 0.6, "dark", "Y", seg=12)                                     # namlu demeti gövdesi
        ring((0, 1.4, bz), 0.12, 0.018, "dark", "Y", seg=14, tseg=4)                           # namlu kelepçesi
        return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.0, zt), "barrel": (0, 0.0, bz)}), {"muzzle": (0, 2.0, bz), "radius": 1.8}
    # ZU-23-2: iki koltuk, ikiz top, şarjör kutuları, alev gizleyiciler
    for s in (-1, 1):
        box((s * 0.42, -0.5, zt + 0.32), (0.36, 0.4, 0.42), "dark", bev=0.01)                  # koltuk
        rod((s * 0.42, -0.4, zt + 0.1), (s * 0.42, -0.45, zt + 0.32), 0.03, "metal", 6)
    box((0, 0.0, zt + 0.35), (0.42, 0.75, 0.48), "paint", bev=0.012)                           # beşik
    node("barrel")
    bz = zt + 0.6
    for s in (-1, 1):
        gun(-0.3, bz, 2.45, 0.028, "gun", x=s * 0.13, bands=1)
        cyl((s * 0.13, 2.2, bz), 0.05, 0.12, "gun", "Y", seg=10)                                # alev gizleyici
        box((s * 0.38, -0.1, bz + 0.12), (0.26, 0.42, 0.24), "trim", bev=0.008)                # şarjör kutusu (50 mermi)
        box((s * 0.13, 0.1, bz), (0.12, 0.7, 0.16), "gun", bev=0.006)                           # gövde
    return wheel_pivots({"body": (0, 0, 0), "turret": (0, 0.0, zt), "barrel": (0, 0.0, bz)}), {"muzzle": (0.13, 2.3, bz), "radius": 1.9}


def coastal(v):
    # beton kaide (altıgen) + çelik kule: eğik ön levha, yan gözlem kapakları, uzun 130 mm namlu (kule düğümünde:
    # sahil topçusu binası kuleyi tek parça döndürür)
    for k in range(6):
        a = k * math.tau / 6
        box((math.cos(a) * 1.55, math.sin(a) * 1.55, 0.35), (1.1, 1.8, 0.7), "trim", rot=(0, 0, a), bev=0.02)
    cyl((0, 0, 0.72), 2.0, 0.12, "metal", seg=28)
    node("turret")
    zt = 0.78
    cyl((0, 0, zt + 0.12), 1.85, 0.24, "paint", seg=28)                                         # kule halkası
    hull_pts([(x, y, z) for x in (-1.45, 1.45) for (y, z) in ((1.55, zt + 0.3), (0.9, zt + 1.65), (-1.6, zt + 1.75), (-1.75, zt + 0.3))], "paint", bev=0.02)
    box((0, -1.2, zt + 1.9), (1.0, 0.8, 0.3), "paint", bev=0.015)                               # komutan kupolası
    for s in (-1, 1):
        cyl((s * 1.0, -0.6, zt + 1.78), 0.22, 0.12, "paint", seg=14)                           # gözlem kapakları
        box((s * 1.46, -0.2, zt + 1.0), (0.04, 1.2, 0.5), "trim", bev=0.006)                    # yan levha cıvatalı
    cyl((0, 1.6, zt + 1.0), 0.42, 0.5, "paint", "Y", seg=18)                                   # namlu mantleti
    gun(1.7, zt + 1.0, 7.4, 0.11, "gun", brake=False, sleeve=1.2, bands=2)
    antenna(-1.2, -1.4, zt + 1.75, 1.8)
    return {"body": (0, 0, 0), "turret": (0, 0, zt)}, {"muzzle": (0, 9.2, zt + 1.0), "radius": 3.2}


def truck_fmtv(v):
    # M1083 FMTV 6×6: önü düz kabin, kargo kasası, yan kapaklar, branda + kemerler, bağlama halkaları
    zd = _truck6(4.6)
    yb = -1.35
    box((0, yb, zd + 0.08), (2.4, 4.6, 0.12), "paint", bev=0.008)                              # kasa tabanı
    for s in (-1, 1):
        box((s * 1.18, yb, zd + 0.5), (0.06, 4.6, 0.75), "paint", bev=0.008)                   # yan kapak
        for k in range(5):
            box((s * 1.22, yb - 2.0 + k * 1.0, zd + 0.5), (0.04, 0.06, 0.75), "trim", bev=0.0)  # dikmeler
    box((0, yb + 2.3, zd + 0.85), (2.4, 0.08, 1.45), "paint", bev=0.008)                      # ön kalkan
    box((0, yb - 2.3, zd + 0.5), (2.4, 0.06, 0.75), "paint", bev=0.008)                       # arka kapak
    # branda (yuvarlatılmış tavan) + kemer izleri
    tz = zd + 0.9
    hull_pts([(x, y, z) for y in (yb - 2.28, yb + 2.26) for (x, z) in ((-1.2, tz), (-1.2, tz + 0.95), (-0.8, tz + 1.25), (0.8, tz + 1.25), (1.2, tz + 0.95), (1.2, tz))], "canvas", bev=0.0)
    for k in range(6):
        y = yb - 2.2 + k * 0.88
        box((0, y, tz + 1.26), (1.62, 0.05, 0.03), "canvas", bev=0.0)
    for s in (-1, 1):
        rod((s * 1.21, yb - 2.2, tz + 0.2), (s * 1.21, yb + 2.2, tz + 0.2), 0.012, "dark", 4)   # bağlama ipi
    box((0, yb - 2.36, zd - 0.2), (1.9, 0.1, 0.15), "dark", bev=0.0)                          # arka tampon
    for s in (-1, 1):
        taillight(s * 0.85, yb - 2.37, zd - 0.2)
    return wheel_pivots({"body": (0, 0, 0)}), {"muzzle": (0, 3.4, 1.5), "radius": 2.4}


FAMILIES = {"atgun": atgun, "mtngun": mtngun, "aagun": aagun, "coastal": coastal, "truck_fmtv": truck_fmtv}
