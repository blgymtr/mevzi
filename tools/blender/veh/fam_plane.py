# Nakliye uçakları (roadmap 122): C-130 tipi (ABD, 4 turboprop, klasik kuyruk) ve Il-76 tipi (Rusya, 4 turbofan,
# T kuyruk, camlı seyrüsefer burnu). Gerçek ölçü: C-130H boy 29,8 m / açıklık 40,4 m / yükseklik 11,6 m;
# Il-76MD boy 46,6 m / açıklık 50,5 m / yükseklik 14,8 m. Koordinat vlib gibi: +Y ileri, Z yukarı, yer z=0.
# Düğümler: body, ramp (menteşe = rampanın ön kenarı; oyunda aşağı açılır), propy_N (C-130 pervaneleri, +Y ekseni).
# Kullanım: blender -b --factory-startup -P tools/blender/veh/planes.py -- <çıkış_klasörü>
import math
import bmesh
from vlib import *
import vlib


def sect(w, h, zc, n=10, e=2.6, flat=0.0):
    """Yarım kesit (alt merkezden üst merkeze, x>=0): süper elips w yarı genişlik, h yükseklik, zc merkez; flat: alt düzlük."""
    pts = []
    for i in range(n + 1):
        a = -math.pi / 2 + math.pi * i / n
        c, s = math.cos(a), math.sin(a)
        x = w * (abs(c) ** (2.0 / e))
        z = (h * 0.5) * (abs(s) ** (2.0 / e)) * (1 if s >= 0 else -1)
        if z < 0:
            z *= (1.0 - flat)
        pts.append((round(x, 4) if i not in (0, n) else 0.0, zc + z))
    return pts


def wing(y_root_le, chord_root, chord_tip, half_span, z_root, thick, sweep_deg, dihedral_deg, x0=0.0, mname="airtrans", n=6):
    """Kanat / dengeleyici: kök (x0) → uç (x0 + half_span); merceksi profil; iki yan aynalanır."""
    sw = math.tan(math.radians(sweep_deg))
    dh = math.tan(math.radians(dihedral_deg))
    for side in (-1, 1):
        bm = bmesh.new()
        rings = []
        for k in range(n + 1):
            t = k / n
            x = x0 + half_span * t
            c = chord_root + (chord_tip - chord_root) * t
            yle = y_root_le - half_span * t * sw
            z = z_root + half_span * t * dh
            th = thick * (1.0 - 0.55 * t)
            prof = []
            m = 8
            for i in range(m + 1):
                u = i / m
                yy = yle - c * u
                # önden %30'da en kalın
                tt = th * 0.5 * math.sin(math.pi * min(1.0, u / 0.3 * 0.5 if u < 0.3 else 0.5 + (u - 0.3) / 0.7 * 0.5))
                prof.append((yy, z + tt))
            for i in range(m - 1, 0, -1):
                u = i / m
                yy = yle - c * u
                tt = th * 0.32 * math.sin(math.pi * min(1.0, u / 0.3 * 0.5 if u < 0.3 else 0.5 + (u - 0.3) / 0.7 * 0.5))
                prof.append((yy, z - tt))
            rings.append([bm.verts.new((side * x, yy, zz)) for yy, zz in prof])
        for r1, r2 in zip(rings, rings[1:]):
            L = len(r1)
            for i in range(L):
                j = (i + 1) % L
                bm.faces.new((r1[i], r1[j], r2[j], r2[i]))
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])
        bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
        vlib._add(bm, mname, 0.0, vlib.SMOOTH)


def fin(y_root_le, chord_root, chord_tip, height, z_root, thick, sweep_deg, mname="airtrans"):
    """Dikey dengeleyici: YZ düzleminde yamuk, X boyunca ince."""
    sw = math.tan(math.radians(sweep_deg))
    prof = [(y_root_le, z_root), (y_root_le - height * sw, z_root + height),
            (y_root_le - height * sw - chord_tip, z_root + height), (y_root_le - chord_root, z_root)]
    poly_extrude_x([(y, z) for y, z in prof], -thick * 0.5, thick * 0.5, mname, bev=0.01)


def windows_row(y0, y1, n, x, z, h=0.32, w=0.28):
    for i in range(n):
        y = y0 + (y1 - y0) * (i + 0.5) / n
        for s in (-1, 1):
            box((s * x, y, z), (0.04, w, h), "glass", bev=0.0)


def prop4(i, x, y, z, R, nb=4):
    """C-130 pervanesi: ayrı düğüm propy_i (pivot göbek); kök geniş, uca doğru incelen paller."""
    prev = vlib.CUR
    node("propy_%d" % i)
    cyl((x, y + 0.25, z), 0.32, 0.9, "airtrans", "Y", seg=14, r2=0.06)          # sivri göbek kapağı
    for k in range(nb):
        a = k * math.tau / nb + 0.35
        for seg in range(3):
            r0 = 0.3 + (R - 0.3) * seg / 3
            r1 = 0.3 + (R - 0.3) * (seg + 1) / 3
            rm = (r0 + r1) * 0.5
            cw = 0.36 * (1.0 - 0.45 * seg / 3)
            box((x + math.cos(a) * rm, y - 0.05, z + math.sin(a) * rm), (cw, 0.05, r1 - r0), "dark",
                rot=(0.35, a + math.pi / 2, 0), bev=0.0)
    vlib.EXTRA_PIVOTS["propy_%d" % i] = (x, y, z)
    node(prev)


def gear(y, x, z, r=0.62, n=2):
    for k in range(n):
        for s in (-1, 1):
            cyl((s * x, y - k * 1.4, z), r, 0.42, "rubber", "X", seg=16)
            cyl((s * (x + 0.22), y - k * 1.4, z), r * 0.55, 0.04, "metal", "X", seg=12)


def plane_c130(v):
    L = 29.8
    node("body")
    # gövde: burun radomu → kokpit → silindirik kargo bölümü → yukarı kalkan kuyruk (altında rampa)
    secs = [
        (14.9, sect(0.18, 0.4, 2.55, flat=0.0)),
        (14.4, sect(0.75, 1.5, 2.45)),
        (13.6, sect(1.35, 2.7, 2.6)),
        (12.4, sect(1.9, 3.7, 2.75, flat=0.15)),
        (10.6, sect(2.15, 4.2, 2.85, flat=0.25)),
        (-6.0, sect(2.15, 4.2, 2.85, flat=0.25)),
        (-7.8, sect(2.05, 3.8, 3.1, flat=0.25)),
        (-9.8, sect(1.75, 3.0, 3.6, flat=0.2)),
        (-12.0, sect(1.3, 2.2, 4.2)),
        (-14.2, sect(0.6, 1.2, 4.8)),
        (-14.9, sect(0.2, 0.5, 5.0)),
    ]
    loft(secs, "airtrans", bev=0.0)
    # kokpit camları (çok parçalı ön cam + yan camlar) ve tavan pencereleri
    for s in (-1, 0, 1):
        box((s * 0.62, 13.55, 3.75), (0.58, 0.42, 0.46), "glass", rot=(-0.65, 0, s * -0.35), bev=0.0)
    for s in (-1, 1):
        box((s * 1.55, 12.9, 3.6), (0.05, 1.1, 0.5), "glass", rot=(0, 0, s * 0.35), bev=0.0)
    windows_row(-4.5, 8.5, 6, 2.16, 3.25)
    # kanat (yüksek kanat, gövde üstü), kanat kökü kaportası
    wing(1.2, 4.9, 2.7, 20.2, 4.95, 0.75, 1.5, 0.6)
    box((0, -0.8, 4.95), (2.6, 5.6, 0.7), "airtrans", bev=0.02)
    # motorlar: dört turboprop nasel, egzoz, pervaneler
    for i, x in enumerate((-9.8, -4.9, 4.9, 9.8)):
        cyl((x, 2.0, 4.55), 0.62, 5.8, "airtrans", "Y", seg=16, r2=0.5)
        cyl((x, 4.95, 4.6), 0.5, 0.25, "airtrans", "Y", seg=14, r2=0.42)
        box((x, 0.2, 4.15), (0.55, 1.6, 0.4), "airtrans", bev=0.02)                     # alt hava alığı
        cyl((x + (0.35 if x > 0 else -0.35), -0.6, 4.75), 0.16, 0.6, "dark", "Y", seg=8)   # egzoz
        prop4(i, x, 5.15, 4.6, 2.05)
    # kanat altı yakıt tankları (dış)
    for x in (-14.2, 14.2):
        cyl((x, 1.3, 4.25), 0.55, 6.5, "airtrans", "Y", seg=14, r2=0.15)
    # kuyruk: dikey dengeleyici + yatay dengeleyici
    fin(-9.4, 5.8, 2.6, 6.6, 5.0, 0.45, 32)
    wing(-11.6, 3.6, 1.8, 7.8, 5.25, 0.38, 6, 0.0)
    # iniş takımı kaportası (sponson) + tekerlekler (yarı içeride)
    for s in (-1, 1):
        box((s * 2.35, -0.8, 1.25), (0.9, 6.4, 1.5), "airtrans", bev=0.02)
    gear(0.5, 2.35, 0.62)
    cyl((0, 11.6, 0.55), 0.5, 0.36, "rubber", "X", seg=14)                              # burun tekeri
    # anten, işaret
    cyl((0, 6.0, 5.1), 0.04, 0.9, "dark", "Z", seg=6)
    box((0, -14.3, 6.2), (0.5, 0.3, 0.3), "light", bev=0.0)
    # arka rampa (ayrı düğüm): kalkık kuyruğun altındaki düz levha; menteşe ön kenarda
    node("ramp")
    slab(-7.4, -7.5, -11.2, -11.2, 0.95, 1.12, 1.55, 1.55, "airtrans", bev=0.01)
    box((0, -9.3, 1.14), (2.9, 3.4, 0.03), "dark", bev=0.0)
    node("body")
    return {"body": (0, 0, 0), "ramp": (0, -7.45, 1.0)}, {"len": L, "door": (0, -9.0, 1.2), "ramp_open": 0.42}


def plane_il76(v):
    L = 46.6
    node("body")
    secs = [
        (23.3, sect(0.25, 0.6, 2.5)),
        (22.6, sect(1.0, 2.0, 2.5)),
        (21.4, sect(1.75, 3.4, 2.8)),
        (19.8, sect(2.3, 4.4, 3.1, flat=0.1)),
        (17.2, sect(2.45, 4.8, 3.25, flat=0.15)),
        (-10.0, sect(2.45, 4.8, 3.25, flat=0.15)),
        (-13.0, sect(2.3, 4.2, 3.6, flat=0.15)),
        (-16.0, sect(1.9, 3.3, 4.2)),
        (-19.0, sect(1.35, 2.4, 4.9)),
        (-22.2, sect(0.7, 1.4, 5.6)),
        (-23.3, sect(0.25, 0.6, 5.8)),
    ]
    loft(secs, "airtrans", bev=0.0)
    # kokpit camları ve camlı seyrüsefer burnu (kokpitin altında)
    for s in (-1, 0, 1):
        box((s * 0.75, 21.7, 4.6), (0.66, 0.45, 0.5), "glass", rot=(-0.6, 0, s * -0.32), bev=0.0)
    for s in (-1, 1):
        box((s * 1.95, 21.0, 4.35), (0.05, 1.3, 0.55), "glass", rot=(0, 0, s * 0.32), bev=0.0)
    for k in range(4):
        a = -0.9 + k * 0.6
        box((math.sin(a) * 0.9, 22.95 - abs(math.sin(a)) * 0.3, 2.2 + math.cos(a) * 0.1), (0.42, 0.06, 0.55), "glass", rot=(0.25, 0, a), bev=0.0)
    box((0, 22.4, 1.6), (0.9, 0.9, 0.5), "dark", bev=0.02)                              # radar çenesi
    windows_row(-7.0, 14.0, 7, 2.46, 3.7)
    # kanat: yüksek, okbaşı 25°, aşağı kırık (anhedral)
    wing(3.2, 7.8, 3.0, 25.2, 5.6, 1.0, 25, -3.0)
    box((0, -1.0, 5.7), (3.4, 8.2, 0.9), "airtrans", bev=0.02)
    # motorlar: pilonlu turbofan podları
    for x in (-15.0, -8.6, 8.6, 15.0):
        yy = 3.2 - abs(x) * math.tan(math.radians(25)) + 1.8
        zz = 5.6 - abs(x) * math.tan(math.radians(3)) - 1.3
        cyl((x, yy, zz), 0.95, 5.4, "airtrans", "Y", seg=18, r2=0.78)
        cyl((x, yy + 2.75, zz), 0.82, 0.12, "dark", "Y", seg=18)                        # fan yüzü
        cyl((x, yy - 3.0, zz), 0.55, 0.9, "dark", "Y", seg=12, r2=0.4)                  # egzoz konisi
        box((x, yy - 0.6, zz + 0.95), (0.32, 3.6, 0.9), "airtrans", bev=0.02)            # pilon
    # T kuyruk
    fin(-15.5, 8.4, 4.4, 7.4, 6.4, 0.55, 38)
    wing(-15.5 - 7.4 * math.tan(math.radians(38)) - 0.2, 4.6, 2.2, 8.7, 13.75, 0.45, 25, -1.5)
    # iniş takımı kaportaları (uzun yan çıkıntılar) + çok tekerli boji
    for s in (-1, 1):
        box((s * 2.7, -1.0, 1.4), (1.2, 11.0, 1.9), "airtrans", bev=0.03)
    for y in (2.4, 0.0, -2.4, -4.8):
        gear(y, 2.75, 0.68, r=0.66, n=1)
    for s in (-0.4, 0.4):
        cyl((s, 18.6, 0.6), 0.55, 0.38, "rubber", "X", seg=14)
    # kuyruk topçu kabini yeri (camsız sivri kuyruk konisi) ve arka kapaklar
    cyl((0, -23.0, 5.8), 0.35, 1.2, "dark", "Y", seg=10, r2=0.08)
    node("ramp")
    slab(-11.4, -11.5, -17.0, -17.0, 1.0, 1.2, 1.85, 1.85, "airtrans", bev=0.01)
    box((0, -14.2, 1.22), (3.4, 5.0, 0.03), "dark", bev=0.0)
    node("body")
    return {"body": (0, 0, 0), "ramp": (0, -11.45, 1.05)}, {"len": L, "door": (0, -14.0, 1.3), "ramp_open": 0.38}


FAMILIES = {"plane_c130": plane_c130, "plane_il76": plane_il76}
