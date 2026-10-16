# İHA ve dolanan mühimmat aileleri (oyun okunabilirliği için gerçek ölçeğin ~%70'i).
import math
from vlib import *

K = 0.7

def _wing(x0, x1, y, z, chord, t, sweep=0.0, dihedral=0.0, mname="paint"):
    """Kanat: x0→x1 açıklık (tek taraf), y konumunda; sweep ile uç geride."""
    pts = []
    for (x, c) in ((x0, chord), (x1, chord * 0.6)):
        yy = y - sweep * abs(x1 - x0) * (0 if x == x0 else 1)
        zz = z + dihedral * (0 if x == x0 else abs(x1 - x0))
        pts += [(x, yy + c * 0.5, zz), (x, yy - c * 0.5, zz), (x, yy + c * 0.1, zz + t), (x, yy - c * 0.3, zz + t)]
    return hull_pts(pts, mname, bev=0.0)

def _fuselage(L, r, y0=0.0, z=0.0, nose=0.3, tail=0.25, mname="paint", seg=10):
    """Yuvarlatılmış gövde: dışbükey halkalardan."""
    pts = []
    for (f, rr) in ((0.0, r * 0.3), (nose * 0.5, r * 0.85), (nose, r), (1.0 - tail, r * 0.9), (1.0, r * 0.35)):
        y = y0 + L / 2 - f * L
        for k in range(seg):
            a = k * math.tau / seg
            pts.append((math.cos(a) * rr, y, z + math.sin(a) * rr))
    return hull_pts(pts, mname, bev=0.0)

def prop(x, y, z, r, n=3, axis="Y"):
    # pervane ayrı düğümde (oyunda döner — roadmap 8): propy_N (ileri eksen, itici) / propz_N (dikey)
    import vlib
    prev = vlib.CUR
    name = "prop%s_%d" % (axis.lower(), len([k for k in vlib.EXTRA_PIVOTS if k.startswith("prop")]))
    vlib.node(name)
    vlib.EXTRA_PIVOTS[name] = (x, y, z)
    cyl((x, y, z), 0.06 * K * 3, 0.15, "dark", axis, seg=8)
    for k in range(n):
        a = k * math.tau / n
        if axis == "Y":
            box((x + math.cos(a) * r * 0.5, y, z + math.sin(a) * r * 0.5), (r, 0.02, 0.08), "dark", rot=(0, -a, 0), bev=0.0)
        else:
            box((x + math.cos(a) * r * 0.5, y + math.sin(a) * r * 0.5, z), (r, 0.08, 0.02), "dark", rot=(0, 0, a), bev=0.0)
    vlib.node(prev)

def uav_male(v):
    s = K * (1.15 if v.get("big") else 1.0)
    _fuselage(11.0 * s, 0.55 * s)
    cyl((0, 4.4 * s, 0.25 * s), 0.42 * s, 0.9 * s, "paint", "Y", seg=12)                       # burun şişkinliği (uydu anteni)
    for sd in (-1, 1):
        _wing(sd * 0.4 * s, sd * 10.0 * s, 0.3 * s, 0.25 * s, 1.1 * s, 0.12 * s)
        # V kuyruk
        box((sd * 1.1 * s, -4.9 * s, 0.6 * s), (2.2 * s, 0.8 * s, 0.06 * s), "paint", rot=(0, sd * -0.6, 0), bev=0.0)
        # füze rayları + füzeler
        for k in (0, 1):
            x = sd * (2.6 + k * 1.6) * s
            box((x, 0.4 * s, 0.05 * s), (0.08 * s, 0.7 * s, 0.25 * s), "dark", bev=0.0)
            cyl((x, 0.5 * s, -0.22 * s), 0.09 * s, 1.6 * s, "paint", "Y", seg=8)
    cyl((0, -1.0 * s, -0.55 * s), 0.25 * s, 0.35 * s, "glass", seg=10)                           # sensör küresi
    prop(0, -5.6 * s, 0.0, 1.6 * s, 3, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 1.0, -0.3), "radius": 3.0}

def uav_hale(v):
    s = K * 1.2
    _fuselage(14.0 * s, 0.7 * s)
    cyl((0, -3.5 * s, 0.85 * s), 0.55 * s, 3.0 * s, "paint", "Y", seg=12)                        # sırt motoru
    for sd in (-1, 1):
        _wing(sd * 0.5 * s, sd * 19.0 * s, 0.0, 0.3 * s, 1.4 * s, 0.14 * s)
        box((sd * 1.3 * s, -6.2 * s, 1.3 * s), (2.6 * s, 1.1 * s, 0.07 * s), "paint", rot=(0, sd * -0.75, 0), bev=0.0)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 3.5}

def uav_tac(v):
    s = K * 1.1
    _fuselage(3.6 * s, 0.32 * s)
    for sd in (-1, 1):
        _wing(sd * 0.2 * s, sd * 3.0 * s, 0.1 * s, 0.25 * s, 0.6 * s, 0.07 * s)
        box((sd * 0.9 * s, -1.6 * s, 0.2 * s), (0.08 * s, 2.6 * s, 0.1 * s), "paint", bev=0.0)    # kuyruk kirişi
        box((sd * 0.9 * s, -2.8 * s, 0.5 * s), (0.05 * s, 0.4 * s, 0.6 * s), "paint", bev=0.0)
    box((0, -2.8 * s, 0.75 * s), (1.9 * s, 0.35 * s, 0.05 * s), "paint", bev=0.0)
    cyl((0, 0.8 * s, -0.32 * s), 0.14 * s, 0.2 * s, "glass", seg=10)
    prop(0, -1.9 * s, 0.1 * s, 0.9 * s, 2, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 2.2}

def uav_hand(v):
    s = K * 1.6
    _fuselage(1.0 * s, 0.07 * s)
    for sd in (-1, 1):
        _wing(sd * 0.05 * s, sd * 0.7 * s, 0.05 * s, 0.07 * s, 0.22 * s, 0.03 * s, dihedral=0.08)
    box((0, -0.45 * s, 0.1 * s), (0.4 * s, 0.12 * s, 0.02 * s), "paint", bev=0.0)
    box((0, -0.45 * s, 0.16 * s), (0.02 * s, 0.12 * s, 0.14 * s), "paint", bev=0.0)
    prop(0, -0.55 * s, 0.0, 0.3 * s, 2, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.2}

def uav_vtol(v):
    s = K * 1.4
    _fuselage(2.4 * s, 0.22 * s)
    cyl((0, -1.0 * s, 0.0), 0.42 * s, 0.4 * s, "paint", "Y", seg=16)                            # kanallı fan
    for sd in (-1, 1):
        _wing(sd * 0.2 * s, sd * 1.4 * s, -0.3 * s, 0.0, 0.35 * s, 0.05 * s)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.4}

def lm_tube(v):
    s = K * (1.6 if v.get("big") else 1.0) * 1.4
    _fuselage(1.3 * s, 0.07 * s)
    for sd in (-1, 1):
        _wing(sd * 0.05 * s, sd * 0.55 * s, 0.25 * s, 0.03 * s, 0.1 * s, 0.015 * s, sweep=0.2)
        _wing(sd * 0.05 * s, sd * 0.45 * s, -0.4 * s, -0.03 * s, 0.1 * s, 0.015 * s, sweep=-0.2)
    prop(0, -0.7 * s, 0.0, 0.25 * s, 2, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 0.9}

def lm_wing(v):
    # X kanatlı (çapraz) dolanan mühimmat: önde ve arkada çift X kanat
    s = K * (1.4 if v.get("big") else 1.15) * 1.4
    _fuselage(1.4 * s, 0.09 * s)
    for (y, span) in ((0.35 * s, 0.6 * s), (-0.45 * s, 0.6 * s)):
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            box((math.cos(a) * span * 0.5, y, math.sin(a) * span * 0.5), (span, 0.18 * s, 0.015 * s), "paint", rot=(0, -a, 0), bev=0.0)
    prop(0, -0.75 * s, 0.0, 0.3 * s, 2, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 0.9}

def lm_delta(v):
    # delta kanatlı uzun menzilli kamikaze İHA
    s = K * 1.3
    _fuselage(3.5 * s, 0.22 * s)
    pts = []
    for sd in (-1, 1):
        pts += [(sd * 0.15 * s, 1.0 * s, 0.0), (sd * 1.25 * s, -1.4 * s, 0.0), (sd * 0.2 * s, -1.6 * s, 0.0),
                (sd * 0.15 * s, 0.9 * s, 0.05 * s), (sd * 1.2 * s, -1.35 * s, 0.04 * s)]
    hull_pts(pts, "paint", bev=0.0)
    for sd in (-1, 1):
        box((sd * 1.2 * s, -1.25 * s, 0.25 * s), (0.04 * s, 0.4 * s, 0.5 * s), "paint", bev=0.0)
    prop(0, -1.85 * s, 0.0, 0.6 * s, 2, "Y")
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.6}

FAMILIES = {"uav_male": uav_male, "uav_hale": uav_hale, "uav_tac": uav_tac, "uav_hand": uav_hand, "uav_vtol": uav_vtol,
            "lm_tube": lm_tube, "lm_wing": lm_wing, "lm_delta": lm_delta}
