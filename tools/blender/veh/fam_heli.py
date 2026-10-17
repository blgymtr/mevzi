# Helikopterler (Roadmap 10): kesitlerden örülen (loft) pürüzsüz gövdeler, gerçek boyutlar (data/real_dims.json),
# ayrıntılı kokpit camları ve çerçeveleri, motor kaportaları + egzoz, kanatçık ve silah istasyonları, iniş takımı,
# kuyruk dikmesi + stabilizatör. fam_air / fam_ru'daki eski kutu-dilim ailelerin yerine geçer (gen.py en son ekler).
# Eksenler: +X sağ, +Y ileri (burun), Z yukarı; taban z = 0 (tekerlek/kızak yere değer).
# Düğümler: body, rotor (ana rotor), trotor (kuyruk rotoru; eş eksenli / tiltrotorda ikinci ana rotor → meta trotor_y)
import math
import bmesh
import vlib
from vlib import *
from fam_air import blades, tail_blades


def _se(a, e):
    c, s = math.cos(a), math.sin(a)
    return (math.copysign(abs(c) ** (2.0 / e), c), math.copysign(abs(s) ** (2.0 / e), s))


def tube(st, m="paint", n=16, cap=True, sharp=False):
    """Y boyunca kesitlerden gövde. st: [(y, cx, cz, rx, rz_üst, rz_alt, e)] — süperelips kesit
    (e=2 elips, e>2 köşeli). Alt/üst yarıçap ayrı: düz taban, şişkin sırt."""
    bm = bmesh.new()
    rings = []
    for (y, cx, cz, rx, rzt, rzb, e) in st:
        ring = []
        for i in range(n):
            a = math.tau * i / n
            u, w = _se(a, e)
            ring.append(bm.verts.new((cx + max(rx, 0.01) * u, y, cz + (max(rzt, 0.01) if w > 0 else max(rzb, 0.01)) * w)))
        rings.append(ring)
    for r1, r2 in zip(rings, rings[1:]):
        for i in range(n):
            j = (i + 1) % n
            bm.faces.new((r1[i], r1[j], r2[j], r2[i]))
    if cap:
        bm.faces.new(rings[0][::-1])
        bm.faces.new(rings[-1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return vlib._add(bm, m, 0.0, vlib.SHARP if sharp else vlib.SMOOTH)


def body(st, m="paint", n=18):
    """simetrik gövde: st [(y, yarı_en, alt_z, üst_z, e)] — üst yarı biraz daha dolgun"""
    tube([(y, 0.0, (zb + zt) * 0.5, w, (zt - zb) * 0.5, (zt - zb) * 0.5, e) for (y, w, zb, zt, e) in st], m, n)


def wing(x0, x1, y0, y1, z0, z1, c0, c1, t0, t1, m="paint", n=10):
    """X boyunca kanat/kanatçık: kökte (x0, y0, z0) veter c0 kalınlık t0, uçta (x1, y1, z1) c1 t1 (elips kesit)"""
    bm = bmesh.new()
    rings = []
    for (x, y, z, c, t) in ((x0, y0, z0, c0, t0), (x1, y1, z1, c1, t1)):
        ring = []
        for i in range(n):
            a = math.tau * i / n
            ring.append(bm.verts.new((x, y + math.cos(a) * c * 0.5, z + math.sin(a) * t * 0.5)))
        rings.append(ring)
    for i in range(n):
        j = (i + 1) % n
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return vlib._add(bm, m, 0.0, vlib.SMOOTH)


def fin(y0, y1, z0, z1, sweep, chord0, chord1, t, x=0.0, m="paint"):
    """dikey kuyruk dikmesi: tabanda y0..y0-chord0, tepede geriye 'sweep' kaymış chord1"""
    bm = bmesh.new()
    rings = []
    for (z, yc, c) in ((z0, y0 - chord0 * 0.5, chord0), (z1, y0 - sweep - chord1 * 0.5, chord1)):
        ring = []
        for i in range(10):
            a = math.tau * i / 10
            ring.append(bm.verts.new((x + math.sin(a) * t * 0.5, yc + math.cos(a) * c * 0.5, z)))
        rings.append(ring)
    for i in range(10):
        j = (i + 1) % 10
        bm.faces.new((rings[0][i], rings[0][j], rings[1][j], rings[1][i]))
    bm.faces.new(rings[0][::-1])
    bm.faces.new(rings[1])
    bmesh.ops.recalc_face_normals(bm, faces=bm.faces)
    return vlib._add(bm, m, 0.0, vlib.SMOOTH)


def frame(pts, w=0.03, m="dark"):
    """cam çerçevesi / kapı çizgisi: noktalar boyunca ince çubuk"""
    for p0, p1 in zip(pts, pts[1:]):
        rod(p0, p1, w * 0.5, m, 5)


def wheel(x, y, z, r, w, strut_to=None):
    cyl((x, y, z), r, w, "rubber", "X", seg=14)
    cyl((x, y, z), r * 0.55, w + 0.02, "metal", "X", seg=10)
    if strut_to is not None:
        rod((x, y, z), strut_to, 0.045, "metal", 6)


def hydra(x, y, z, L=1.65, r=0.21):
    """19'luk roket kovanı: gövde, ön/arka kapak halkası, delikler"""
    cyl((x, y, z), r, L, "paint", "Y", seg=16)
    cyl((x, y + L * 0.5, z), r * 0.92, 0.04, "dark", "Y", seg=16)
    for k in range(6):
        a = k * math.tau / 6
        cyl((x + math.cos(a) * r * 0.55, y + L * 0.5 + 0.005, z + math.sin(a) * r * 0.55), 0.035, 0.02, "gun", "Y", seg=6)
    ring((x, y + L * 0.32, z), r + 0.01, 0.012, "trim", "Y", seg=16, tseg=4)
    ring((x, y - L * 0.32, z), r + 0.01, 0.012, "trim", "Y", seg=16, tseg=4)


def atgm_rack(x, y, z, n=4, L=1.6, r=0.09, rail_w=0.42):
    """güdümlü füze rafı (Hellfire / Ataka / Vikhr): ray + 2×2 füze, burun konisi"""
    box((x, y, z + 0.18), (rail_w, L * 0.7, 0.08), "dark", bev=0.006)
    for i in range(2):
        for j in range(n // 2):
            xx = x + (i - 0.5) * rail_w * 0.55
            zz = z - j * r * 2.3
            cyl((xx, y, zz), r, L, "paint", "Y", seg=10)
            cyl((xx, y + L * 0.5 + 0.08, zz), r, 0.16, "dark", "Y", seg=10, r2=0.02)
            for k in range(4):
                a = k * math.tau / 4 + math.pi / 4
                box((xx + math.cos(a) * r * 1.5, y - L * 0.42, zz + math.sin(a) * r * 1.5), (0.012, 0.18, 0.012), "paint", rot=(0, a, 0), bev=0.0)


def pylon(x, y, z_top, z_bot, chord=0.7):
    box((x, y, (z_top + z_bot) * 0.5), (0.07, chord, z_top - z_bot), "paint", bev=0.008)


def sensor_ball(x, y, z, r, windows=2):
    cyl((x, y, z), r, r * 1.6, "paint", "Z", seg=16)
    for k in range(windows):
        cyl((x + (k - (windows - 1) * 0.5) * r * 0.7, y + r * 0.92, z), r * 0.28, 0.04, "glass", "Y", seg=10)


def exhaust_box(x, y, z, side, L=0.6, w=0.32, h=0.3):
    """IR bastırıcılı egzoz (yana-yukarı açılı ağız, içi koyu)"""
    box((x, y, z), (w, L, h), "paint", rot=(0, side * 0.35, 0), bev=0.01)
    box((x + side * 0.1, y - L * 0.5, z + 0.02), (w * 0.7, 0.04, h * 0.7), "dark", rot=(0, side * 0.35, 0), bev=0.0)


def mast_hub(y, z0, z1, r=0.16):
    cyl((0, y, (z0 + z1) * 0.5), r, z1 - z0, "metal", seg=12)
    cyl((0, y, z0 + 0.1), r * 2.2, 0.2, "paint", seg=14)      # salıncak plaka örtüsü


# ------------------------------------------------------------------ AH-64D/E Apache · Mi-28N/NM (ru)
def heli_atk(v):
    ru = v.get("ru", False)
    rot_d = 17.2 if ru else 14.63
    my = 0.25                                       # rotor mili
    hub_z = 3.62 if ru else 3.6
    # gövde: dar, kademeli tandem kokpit, uzun kuyruk konisi
    body([(7.25, 0.12, 1.08, 1.3, 2.2), (7.0, 0.32, 0.86, 1.52, 2.4), (6.4, 0.46, 0.66, 1.66, 2.6),
          (5.4, 0.5, 0.56, 1.72, 2.8), (4.1, 0.52, 0.52, 1.84, 2.8), (2.6, 0.55, 0.52, 2.02, 2.8),
          (1.2, 0.56, 0.58, 2.18, 2.8), (-0.4, 0.52, 0.66, 2.22, 2.7), (-1.6, 0.42, 0.86, 2.06, 2.5),
          (-2.8, 0.3, 1.12, 1.86, 2.3), (-5.4, 0.2, 1.3, 1.74, 2.2), (-7.2, 0.16, 1.38, 1.76, 2.2), (-7.55, 0.1, 1.42, 1.72, 2.2)])
    # kokpit yanı aviyonik bölmeleri ("yanaklar")
    for s in (-1, 1):
        tube([(5.2, s * 0.45, 0.95, 0.06, 0.12, 0.12, 2.6), (4.6, s * 0.58, 0.95, 0.15, 0.28, 0.3, 3.0),
              (2.0, s * 0.62, 0.98, 0.16, 0.32, 0.34, 3.0), (1.0, s * 0.55, 1.0, 0.06, 0.24, 0.24, 2.6)], "paint")
    # kokpit camları: önde nişancı (alçak), arkada pilot (yüksek); çerçeveler
    tube([(6.15, 0.0, 1.62, 0.12, 0.08, 0.05, 2.0), (5.8, 0.0, 1.66, 0.4, 0.3, 0.1, 2.4), (4.7, 0.0, 1.7, 0.47, 0.4, 0.12, 2.6),
          (4.15, 0.0, 1.74, 0.42, 0.34, 0.12, 2.4)], "glass")
    tube([(4.3, 0.0, 1.82, 0.12, 0.08, 0.05, 2.0), (3.95, 0.0, 1.86, 0.44, 0.42, 0.1, 2.4), (2.7, 0.0, 1.96, 0.5, 0.5, 0.12, 2.6),
          (2.15, 0.0, 2.0, 0.44, 0.38, 0.12, 2.4)], "glass")
    for (y0, y1, zt, zb, w) in ((5.8, 4.15, 2.04, 1.62, 0.46), (3.95, 2.15, 2.46, 1.84, 0.5)):
        for s in (-1, 1):
            frame([(s * w * 0.75, y0, zb + 0.05), (s * w, (y0 + y1) * 0.5, zb + 0.06), (s * w * 0.8, y1, zb + 0.05)], 0.035, "dark")
        frame([(0, y0 - 0.05, zt - 0.06), (0, y1, zt - 0.02)], 0.03, "dark")
        frame([(-w * 0.95, (y0 + y1) * 0.5, zb + 0.1), (0, (y0 + y1) * 0.5, zt + 0.02), (w * 0.95, (y0 + y1) * 0.5, zb + 0.1)], 0.03, "dark")
    # burun: TADS/PNVS (Apache) ya da radar/optik kule (Mi-28)
    if ru:
        cyl((0, 7.05, 1.05), 0.36, 0.5, "paint", "Y", seg=16)
        sensor_ball(0, 7.0, 0.62, 0.3, 2)
    else:
        sensor_ball(0, 7.05, 0.98, 0.34, 2)                                           # TADS (alt)
        cyl((0, 7.0, 1.42), 0.17, 0.22, "paint", "Z", seg=12)                          # PNVS (üst)
        cyl((0, 7.16, 1.42), 0.09, 0.04, "glass", "Y", seg=10)
    # motor kaportaları (yanlarda, rotor milinin arkasında) + egzoz
    for s in (-1, 1):
        ex = s * 0.86
        tube([(1.55, ex, 1.98, 0.2, 0.2, 0.2, 2.2), (1.2, ex, 1.98, 0.36, 0.36, 0.34, 2.4), (-0.6, ex, 2.0, 0.38, 0.38, 0.36, 2.6),
              (-1.6, ex, 2.04, 0.3, 0.3, 0.28, 2.4), (-2.0, ex, 2.06, 0.2, 0.2, 0.2, 2.2)], "paint")
        cyl((ex, 1.58, 1.98), 0.17, 0.06, "dark", "Y", seg=14)                         # hava girişi
        rod((s * 0.5, 0.4, 2.0), (ex, 0.4, 2.0), 0.08, "paint", 8)                      # gövdeye bağlantı
        if ru:
            exhaust_box(ex + s * 0.12, -2.0, 2.18, s, 0.5, 0.28, 0.3)
        else:
            exhaust_box(ex + s * 0.15, -1.9, 2.1, s, 0.55, 0.3, 0.28)               # "black hole" egzoz
        # kanatçık (hafif eğik) + iki istasyon: içte roket, dışta füze
        wing(s * 0.55, s * 2.6, 0.55, 0.45, 1.36, 1.28, 1.05, 0.8, 0.14, 0.1, "paint")
        for k, xx in enumerate((1.35, 2.2)):
            pylon(s * xx, 0.45, 1.3, 1.02)
            if (k == 0) != ru:
                hydra(s * xx, 0.5, 0.78)
            else:
                atgm_rack(s * xx, 0.45, 0.86, 4, 1.65 if not ru else 1.8, 0.09)
        box((s * 2.66, 0.45, 1.3), (0.12, 0.7, 0.16), "paint", bev=0.008)            # kanat ucu (ESM/Stinger yeri)
        # ana iniş takımı (kuyruk tekerlekli): bacak + amortisör + tekerlek
        wheel(s * 1.0, 4.0, 0.32, 0.32, 0.2, (s * 0.5, 4.15, 0.95))
        rod((s * 1.0, 4.0, 0.32), (s * 0.55, 3.4, 0.9), 0.035, "metal", 6)
    # kuyruk tekerleği
    wheel(0.0, -6.85, 0.2, 0.18, 0.12, (0.0, -6.6, 1.36))
    # burun altı top (M230 30 mm / Mi-28 2A42 sağda)
    if ru:
        cyl((0, 5.6, 0.4), 0.22, 0.32, "paint", "Z", seg=12)
        gun(5.6, 0.36, 1.9, 0.045, "gun")
    else:
        cyl((0, 4.75, 0.42), 0.2, 0.26, "dark", "Z", seg=12)
        box((0, 4.75, 0.28), (0.22, 0.4, 0.14), "dark", bev=0.008)
        gun(4.85, 0.26, 1.7, 0.035, "gun")
    # sırt: aviyonik / şanzıman örtüsü, anten
    tube([(1.4, 0.0, 2.2, 0.22, 0.12, 0.05, 2.4), (0.9, 0.0, 2.24, 0.42, 0.3, 0.08, 2.6), (-0.6, 0.0, 2.24, 0.42, 0.3, 0.08, 2.6),
          (-1.4, 0.0, 2.15, 0.2, 0.1, 0.05, 2.2)], "paint")
    rod((0.2, -2.2, 2.0), (0.2, -2.5, 2.55), 0.012, "dark", 4)
    # kuyruk: dikme (sola yatık değil, dik), alçak stabilizatör, kuyruk rotoru solda (Apache) / sağda (Mi-28)
    fin(-6.9, -7.7, 1.65, 3.75, 0.55, 1.15, 0.6, 0.16)
    wing(-0.05, -1.75, -7.2, -7.35, 1.62, 1.66, 0.75, 0.55, 0.08, 0.06, "paint")
    wing(0.05, 1.75, -7.2, -7.35, 1.62, 1.66, 0.75, 0.55, 0.08, 0.06, "paint")
    mast_hub(my, 2.3, hub_z)
    if v.get("radar"):
        cyl((0, my, hub_z + 0.62), 0.48, 0.34, "paint", seg=20)                     # Longbow / NM direk radarı
        cyl((0, my, hub_z + 0.36), 0.12, 0.2, "metal", seg=10)
    ts = 1 if ru else -1
    tr_x = ts * 0.2
    tr_y = -7.62
    tr_z = 3.32
    node("rotor")
    blades(0, my, hub_z, 5 if ru else 4, rot_d, chord=0.53 if not ru else 0.6)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 4, 3.84 if ru else 2.79, ts)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (0, 6.6 if ru else 6.5, 0.32), "radius": 3.6}


# ------------------------------------------------------------------ UH-60M Black Hawk · MH-60M DAP (armed)
def heli_utility(v):
    armed = v.get("armed", False)
    my = 0.55
    hub_z = 3.62
    body([(5.75, 0.2, 1.12, 1.48, 2.2), (5.45, 0.62, 0.78, 1.8, 2.6), (4.8, 0.95, 0.58, 2.02, 3.0),
          (3.8, 1.1, 0.5, 2.18, 3.4), (2.4, 1.16, 0.48, 2.24, 3.6), (-0.6, 1.16, 0.48, 2.24, 3.6),
          (-1.9, 1.02, 0.62, 2.2, 3.2), (-3.2, 0.66, 1.08, 2.12, 2.8), (-4.6, 0.36, 1.48, 2.08, 2.4),
          (-8.2, 0.24, 1.66, 2.02, 2.2), (-8.9, 0.2, 1.7, 2.02, 2.2)])
    # kokpit camları: iki büyük ön cam, yan camlar, çene camları
    for s in (-1, 1):
        tube([(5.5, s * 0.36, 1.68, 0.3, 0.22, 0.2, 2.2), (4.9, s * 0.52, 1.82, 0.42, 0.26, 0.26, 2.6), (4.55, s * 0.6, 1.86, 0.38, 0.22, 0.24, 2.4)], "glass")
        box((s * 1.09, 3.95, 1.62), (0.05, 1.1, 0.62), "glass", bev=0.0)                       # kokpit yan camı
        box((s * 0.5, 5.25, 0.86), (0.36, 0.38, 0.05), "glass", rot=(-0.6, 0, 0), bev=0.0)    # çene camı
        frame([(s * 0.05, 5.62, 1.55), (s * 0.08, 4.62, 2.06)], 0.035, "dark")
        frame([(s * 1.12, 4.52, 1.28), (s * 1.12, 4.52, 2.0)], 0.03, "dark")
        # kayar kabin kapısı: çerçeve + iki pencere; kapı rayı
        x = s * 1.17
        frame([(x, 2.35, 0.62), (x, 2.35, 2.0), (x, 0.55, 2.0), (x, 0.55, 0.62), (x, 2.35, 0.62)], 0.03, "dark")
        for (yy, zz) in ((1.85, 1.55), (1.05, 1.55)):
            box((x + s * 0.005, yy, zz), (0.03, 0.62, 0.48), "glass", bev=0.0)
        rod((x + s * 0.02, 2.4, 2.05), (x + s * 0.02, -0.6, 2.05), 0.02, "metal", 5)
        box((s * 1.15, -1.1, 1.65), (0.04, 0.42, 0.36), "glass", bev=0.0)                     # kabin arka penceresi
        # ana iniş takımı: sürükleme kirişi + amortisör
        wheel(s * 1.42, 2.6, 0.38, 0.38, 0.24, (s * 1.0, 2.3, 0.9))
        rod((s * 1.42, 2.6, 0.38), (s * 1.06, 3.4, 0.62), 0.05, "metal", 6)
        # motorlar (üstte, iki kaporta) + IR egzoz
        ex = s * 0.48
        tube([(1.95, ex, 2.46, 0.16, 0.14, 0.12, 2.2), (1.6, ex, 2.5, 0.34, 0.3, 0.24, 2.6), (-0.9, ex, 2.52, 0.36, 0.3, 0.24, 2.8),
              (-1.6, ex, 2.5, 0.24, 0.22, 0.18, 2.4)], "paint")
        cyl((ex, 1.98, 2.46), 0.13, 0.06, "dark", "Y", seg=12)
        exhaust_box(ex + s * 0.2, -1.8, 2.58, s, 0.62, 0.36, 0.28)
    # sırt: şanzıman kaportası
    tube([(2.4, 0.0, 2.3, 0.3, 0.2, 0.05, 2.4), (1.6, 0.0, 2.36, 0.58, 0.42, 0.06, 2.8), (-0.4, 0.0, 2.36, 0.58, 0.42, 0.06, 2.8),
          (-1.6, 0.0, 2.3, 0.36, 0.26, 0.05, 2.4)], "paint")
    box((0, 3.0, 2.3), (0.5, 0.6, 0.12), "paint", bev=0.01)                                     # tel kesici tabanı
    rod((0, 3.3, 2.3), (0, 3.55, 2.9), 0.02, "metal", 4)
    # kuyruk: dikme (sağ yanda 20° yatık kuyruk rotoru), büyük stabilatör, kuyruk tekerleği
    fin(-8.3, -9.3, 1.9, 4.25, 0.75, 1.15, 0.7, 0.2)
    for s in (-1, 1):
        wing(s * 0.1, s * 2.2, -8.75, -8.85, 2.18, 2.2, 1.0, 0.75, 0.08, 0.06, "paint")
    wheel(0.0, -7.7, 0.22, 0.2, 0.14, (0.0, -7.5, 1.7))
    # silahlı (DAP): ESSS kanatçıkları, roket kovanı + Hellfire, 30 mm top kovanı
    if armed:
        for s in (-1, 1):
            wing(s * 1.1, s * 3.0, 0.9, 0.85, 2.16, 2.0, 0.9, 0.7, 0.1, 0.08, "paint")
            rod((s * 1.15, 0.9, 1.0), (s * 2.3, 0.88, 2.04), 0.04, "metal", 6)
            pylon(s * 2.0, 0.88, 2.05, 1.8)
            hydra(s * 2.0, 0.95, 1.55)
            pylon(s * 2.8, 0.85, 2.0, 1.78)
            atgm_rack(s * 2.8, 0.85, 1.62, 4, 1.6, 0.09)
    mast_hub(my, 2.6, hub_z)
    tr_x, tr_y, tr_z = 0.24, -9.2, 3.7
    node("rotor")
    blades(0, my, hub_z, 4, 16.36, chord=0.53)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 4, 3.35, 1)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (1.6, 2.2, 1.4), "radius": 4.2}


# ------------------------------------------------------------------ Mi-24P / Mi-35M Hind
def heli_hind(v):
    m35 = v.get("m", False)
    my = 0.0
    hub_z = 3.95
    body([(7.6, 0.16, 1.05, 1.32, 2.2), (7.2, 0.42, 0.8, 1.58, 2.4), (6.4, 0.55, 0.66, 1.78, 2.6),
          (5.2, 0.66, 0.6, 2.05, 2.8), (3.6, 0.9, 0.52, 2.3, 3.2), (1.6, 1.0, 0.5, 2.42, 3.4), (-1.0, 1.0, 0.52, 2.42, 3.4),
          (-2.6, 0.82, 0.72, 2.36, 3.0), (-4.0, 0.46, 1.42, 2.28, 2.6), (-8.8, 0.3, 1.72, 2.2, 2.2), (-9.5, 0.24, 1.78, 2.2, 2.2)])
    # tandem kabarcık kokpitler (önde nişancı, arkada yüksek pilot)
    tube([(7.0, 0.0, 1.62, 0.14, 0.1, 0.05, 2.0), (6.6, 0.0, 1.66, 0.46, 0.36, 0.1, 2.2), (5.6, 0.0, 1.8, 0.56, 0.42, 0.12, 2.4),
          (5.2, 0.0, 1.84, 0.46, 0.3, 0.12, 2.2)], "glass")
    tube([(5.3, 0.0, 2.0, 0.16, 0.12, 0.06, 2.0), (5.0, 0.0, 2.06, 0.58, 0.46, 0.12, 2.4), (3.8, 0.0, 2.2, 0.66, 0.5, 0.12, 2.4),
          (3.4, 0.0, 2.24, 0.56, 0.36, 0.12, 2.2)], "glass")
    for (yy, zz, w) in ((6.1, 2.02, 0.55), (4.4, 2.6, 0.66)):
        frame([(-w, yy, zz - 0.36), (0, yy, zz + 0.1), (w, yy, zz - 0.36)], 0.035, "dark")
    for s in (-1, 1):
        # kabin: üst/alt açılan ikili kapı + üç pencere
        x = s * 1.0
        frame([(x, 2.6, 0.7), (x, 2.6, 2.1), (x, 1.1, 2.1), (x, 1.1, 0.7)], 0.03, "dark")
        for k in range(3):
            cyl((x + s * 0.005, 0.9 - k * 0.55, 1.75), 0.15, 0.03, "glass", "X", seg=12)
        # motorlar (üstte), toz filtreleri, egzoz
        ex = s * 0.56
        tube([(3.0, ex, 2.6, 0.2, 0.18, 0.14, 2.4), (2.6, ex, 2.62, 0.4, 0.34, 0.24, 2.8), (-0.6, ex, 2.62, 0.4, 0.34, 0.24, 2.8),
              (-1.2, ex, 2.58, 0.28, 0.24, 0.18, 2.4)], "paint")
        box((ex, 3.25, 2.62), (0.5, 0.5, 0.5), "metal", bev=0.012)                              # PZU toz filtresi
        cyl((ex, 3.52, 2.62), 0.2, 0.04, "dark", "Y", seg=14)
        exhaust_box(ex + s * 0.2, -1.4, 2.66, s, 0.6, 0.34, 0.34)
        # kanatlar (12° aşağı), 2 altında istasyon + uçta füze rayı
        wing(s * 1.0, s * 3.3, 0.1, 0.2, 1.56, 1.08, 1.5, 1.0, 0.18, 0.12, "paint")
        for k, xx in enumerate((1.75, 2.6)):
            zz = 1.56 - (xx - 1.0) * 0.21
            pylon(s * xx, 0.15, zz, zz - 0.26)
            if k == 0:
                hydra(s * xx, 0.25, zz - 0.5, 1.7, 0.26)
            else:
                hydra(s * xx, 0.22, zz - 0.5, 1.5, 0.22) if not m35 else atgm_rack(s * xx, 0.2, zz - 0.42, 4, 1.8, 0.1)
        box((s * 3.32, 0.2, 0.98), (0.12, 1.0, 0.25), "dark", bev=0.008)
        canister(s * 3.32, 0.25, 0.78, 1.7, 0.1, 0.0)
        canister(s * 3.32, 0.25, 0.56, 1.7, 0.1, 0.0)
        # ana iniş takımı (kanat altından)
        wheel(s * 1.55, -0.7, 0.36, 0.36, 0.24, (s * 1.1, -0.5, 0.95))
    wheel(0.3, 5.9, 0.3, 0.28, 0.18, (0.2, 5.7, 0.85))
    wheel(-0.3, 5.9, 0.3, 0.28, 0.18, (-0.2, 5.7, 0.85))
    # burun: top kulesi (Mi-24P sağda çift namlu GSh-30 → kuleli Mi-35M de burun altı)
    if m35 or True:
        cyl((0, 6.7, 0.66), 0.28, 0.36, "paint", "Z", seg=14)
        gun(6.8, 0.6, 1.2 if not m35 else 1.0, 0.045, "gun")
    sensor_ball(0.42, 7.0, 0.82, 0.18, 1)
    # sırt örtüsü, kuyruk (dikme + sağ yanda... Mi-24'te kuyruk rotoru solda), stabilizatör
    tube([(2.4, 0.0, 2.5, 0.3, 0.2, 0.05, 2.4), (1.4, 0.0, 2.56, 0.5, 0.36, 0.06, 2.6), (-0.8, 0.0, 2.56, 0.5, 0.36, 0.06, 2.6),
          (-1.8, 0.0, 2.48, 0.3, 0.2, 0.05, 2.4)], "paint")
    fin(-9.0, -10.0, 1.95, 4.05, 0.85, 1.1, 0.75, 0.22)
    for s in (-1, 1):
        wing(s * 0.1, s * 1.5, -8.2, -8.4, 1.95, 1.95, 0.85, 0.6, 0.08, 0.06, "paint")
    wheel(0.0, -8.6, 0.24, 0.2, 0.12, (0.0, -8.3, 1.75))
    mast_hub(my, 2.75, hub_z)
    tr_x, tr_y, tr_z = -0.24, -9.85, 3.55
    node("rotor")
    blades(0, my, hub_z, 5, 17.3, chord=0.58)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 3, 3.91, -1)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (0, 8.0, 0.6), "radius": 4.6}


# ------------------------------------------------------------------ Mi-8MTV / Mi-17 / Mi-8AMTSh
def heli_mi8(v):
    armed = v.get("armed", False)
    my = 0.0
    hub_z = 4.62
    body([(7.75, 0.22, 1.05, 1.5, 2.2), (7.45, 0.72, 0.72, 2.0, 2.6), (6.6, 1.08, 0.56, 2.4, 3.0),
          (5.4, 1.22, 0.5, 2.62, 3.6), (1.0, 1.25, 0.5, 2.66, 3.8), (-2.6, 1.22, 0.52, 2.64, 3.6),
          (-3.6, 0.95, 0.9, 2.56, 3.0), (-4.4, 0.55, 1.75, 2.5, 2.6), (-10.6, 0.34, 2.1, 2.6, 2.2), (-11.2, 0.3, 2.14, 2.62, 2.2)])
    # cam burun (çok bölmeli), kokpit yan kabarcık pencereler
    tube([(7.7, 0.0, 1.48, 0.2, 0.18, 0.1, 2.0), (7.4, 0.0, 1.62, 0.68, 0.46, 0.3, 2.4), (6.9, 0.0, 1.84, 0.96, 0.52, 0.3, 2.6),
          (6.6, 0.0, 1.98, 0.9, 0.42, 0.3, 2.4)], "glass")
    for k in range(5):
        a = (k - 2) * 0.32
        frame([(math.sin(a) * 0.95, 6.75 + math.cos(a) * 0.55, 1.45), (math.sin(a) * 0.72, 7.0 + math.cos(a) * 0.45, 2.3)], 0.03, "dark")
    for s in (-1, 1):
        cyl((s * 1.2, 6.0, 1.9), 0.32, 0.12, "glass", "X", seg=14)                       # kabarcık yan pencere
        # kabin yuvarlak pencereleri (sağda 5, solda 4 + sürgülü kapı)
        for k in range(5 if s > 0 else 4):
            cyl((s * 1.255, 4.0 - k * 1.25, 1.85), 0.2, 0.03, "glass", "X", seg=14)
        if s < 0:
            frame([(-1.26, 5.1, 0.58), (-1.26, 5.1, 2.3), (-1.26, 4.0, 2.3), (-1.26, 4.0, 0.58)], 0.03, "dark")
            rod((-1.29, 5.2, 2.36), (-1.29, 3.2, 2.36), 0.02, "metal", 5)
        # dış yakıt tankları
        tube([(1.6, s * 1.48, 1.12, 0.06, 0.06, 0.06, 2.0), (1.3, s * 1.5, 1.12, 0.34, 0.42, 0.36, 2.6),
              (-1.4, s * 1.5, 1.12, 0.34, 0.42, 0.36, 2.6), (-1.7, s * 1.48, 1.12, 0.06, 0.06, 0.06, 2.0)], "paint")
        # motorlar (üstte önde) + egzozlar (yana)
        ex = s * 0.56
        tube([(5.4, ex, 2.92, 0.18, 0.14, 0.1, 2.2), (5.0, ex, 2.96, 0.42, 0.34, 0.26, 2.8), (2.2, ex, 3.0, 0.44, 0.36, 0.26, 3.0),
              (1.6, ex, 2.98, 0.3, 0.24, 0.18, 2.4)], "paint")
        cyl((ex, 5.45, 2.94), 0.2, 0.05, "dark", "Y", seg=14)
        exhaust_box(s * 1.05, 1.55, 3.0, s, 0.7, 0.36, 0.32)
        # iniş takımı: ana tekerlekler (yanlarda dikmeli) + burun çift tekerleği
        wheel(s * 1.55, -0.3, 0.44, 0.44, 0.28, (s * 1.18, -0.1, 1.1))
        rod((s * 1.55, -0.3, 0.44), (s * 1.18, 0.9, 0.62), 0.05, "metal", 6)
        if armed:
            # AMTSh: kirişler + roket kovanları (3'er), kapı makinelisi
            rod((s * 1.25, 1.2, 1.4), (s * 2.7, 1.2, 1.6), 0.06, "metal", 6)
            for k, xx in enumerate((1.75, 2.25, 2.7)):
                pylon(s * xx, 1.2, 1.55, 1.32)
                hydra(s * xx, 1.3, 1.08, 1.7, 0.24)
    wheel(0.22, 6.2, 0.32, 0.3, 0.16, (0.1, 6.0, 0.8))
    wheel(-0.22, 6.2, 0.32, 0.3, 0.16, (-0.1, 6.0, 0.8))
    # arka istiridye kapılar + rampa çizgisi
    frame([(-0.9, -3.6, 0.92), (0, -3.95, 0.9), (0.9, -3.6, 0.92)], 0.03, "dark")
    frame([(0, -3.95, 0.9), (0, -3.6, 2.5)], 0.03, "dark")
    # sırt: şanzıman örtüsü; kuyruk dikmesi + kuyruk rotoru (Mi-17 solda)
    tube([(3.0, 0.0, 3.0, 0.3, 0.2, 0.05, 2.4), (1.6, 0.0, 3.06, 0.62, 0.42, 0.06, 2.8), (-0.6, 0.0, 3.06, 0.62, 0.42, 0.06, 2.8),
          (-1.8, 0.0, 2.98, 0.32, 0.22, 0.05, 2.4)], "paint")
    fin(-10.8, -11.9, 2.4, 4.75, 0.75, 1.1, 0.75, 0.24)
    for s in (-1, 1):
        wing(s * 0.1, s * 1.35, -9.6, -9.8, 2.25, 2.25, 0.8, 0.55, 0.08, 0.06, "paint")
    box((0, -10.9, 2.0), (0.12, 0.5, 0.25), "dark", bev=0.0)                                # kuyruk koruma kızağı
    mast_hub(my, 3.2, hub_z, 0.2)
    ts = -1 if v.get("m17") else 1
    tr_x, tr_y, tr_z = ts * 0.25, -11.55, 4.4
    node("rotor")
    blades(0, my, hub_z, 5, 21.29, chord=0.52)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 3, 3.91, ts)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (1.5, 3.0, 1.2), "radius": 5.2}


# ------------------------------------------------------------------ Ka-52 Alligator · Ka-226 (light)
def heli_coax(v):
    lt = v.get("light", False)
    my = 0.2
    if lt:
        # Ka-226: kısa, yüksek kabin, iki kuyruk kirişi, eş eksenli rotor
        hub = 3.2
        body([(3.9, 0.3, 0.9, 1.5, 2.2), (3.4, 0.76, 0.62, 1.95, 2.6), (2.4, 0.88, 0.55, 2.2, 3.2), (0.0, 0.9, 0.55, 2.3, 3.4),
              (-1.4, 0.82, 0.62, 2.28, 3.0), (-1.9, 0.5, 0.95, 2.2, 2.4)])
        tube([(3.85, 0.0, 1.5, 0.3, 0.2, 0.1, 2.0), (3.3, 0.0, 1.68, 0.78, 0.5, 0.3, 2.6), (2.4, 0.0, 1.8, 0.88, 0.45, 0.3, 2.6)], "glass")
        for s in (-1, 1):
            box((s * 0.9, 1.2, 1.55), (0.04, 1.5, 0.75), "glass", bev=0.0)
            tube([(-1.6, s * 0.75, 1.75, 0.1, 0.1, 0.1, 2.2), (-4.4, s * 0.75, 1.85, 0.08, 0.08, 0.08, 2.2)], "paint", 10)
            fin(-4.3, -4.9, 1.4, 2.6, 0.2, 0.75, 0.5, 0.1, x=s * 0.75)
            rod((s * 0.95, 1.8, 0.1), (s * 0.95, -1.4, 0.1), 0.05, "dark", 6)            # kızak
            rod((s * 0.95, 1.2, 0.1), (s * 0.7, 1.2, 0.62), 0.04, "dark", 6)
            rod((s * 0.95, -0.9, 0.1), (s * 0.7, -0.9, 0.62), 0.04, "dark", 6)
        wing(-0.75, 0.75, -4.6, -4.6, 1.95, 1.95, 0.5, 0.5, 0.06, 0.06, "paint")
        tube([(0.9, 0.0, 2.3, 0.4, 0.22, 0.05, 2.6), (-1.2, 0.0, 2.32, 0.44, 0.26, 0.05, 2.6)], "paint")
        mast_hub(my, 2.5, hub + 1.0, 0.13)
        D = 13.0
        node("rotor")
        blades(0, my, hub, 3, D, chord=0.35)
        node("trotor")
        blades(0, my, hub + 0.85, 3, D, chord=0.35, phase=math.pi / 3)
        return {"body": (0, 0, 0), "rotor": (0, my, hub), "trotor": (0, my, hub + 0.85)}, {"muzzle": (0.8, 2.6, 1.0), "radius": 3.0, "trotor_y": True}
    hub = 3.62
    # Ka-52: yan yana iki kişilik geniş kokpit, burun radarı, iki uçlu kuyruk (ikiz dikme)
    body([(6.6, 0.18, 1.15, 1.45, 2.2), (6.25, 0.5, 0.86, 1.76, 2.4), (5.4, 0.78, 0.68, 2.0, 2.8),
          (4.0, 0.9, 0.6, 2.22, 3.0), (2.2, 0.8, 0.62, 2.36, 3.0), (0.4, 0.68, 0.7, 2.34, 2.8),
          (-1.2, 0.5, 0.9, 2.18, 2.6), (-2.6, 0.32, 1.24, 1.98, 2.4), (-5.9, 0.22, 1.42, 1.86, 2.2), (-6.4, 0.18, 1.45, 1.84, 2.2)])
    tube([(5.6, 0.0, 1.66, 0.3, 0.12, 0.08, 2.0), (5.15, 0.0, 1.72, 0.82, 0.42, 0.12, 2.4), (4.0, 0.0, 1.86, 0.9, 0.56, 0.12, 2.6),
          (3.4, 0.0, 1.92, 0.8, 0.44, 0.12, 2.4)], "glass")
    frame([(0, 5.5, 1.78), (0, 3.45, 2.4)], 0.035, "dark")
    for s in (-1, 1):
        frame([(s * 0.86, 5.0, 1.78), (s * 0.9, 4.0, 1.84), (s * 0.78, 3.4, 1.86)], 0.035, "dark")
    cyl((0, 6.55, 1.3), 0.5, 0.35, "paint", "Y", seg=18, r2=0.3)                                # radar kubbesi
    sensor_ball(0, 5.7, 0.6, 0.32, 2)                                                            # GOES optik kule
    for s in (-1, 1):
        ex = s * 0.62
        tube([(1.9, ex, 2.22, 0.18, 0.18, 0.16, 2.2), (1.5, ex, 2.24, 0.34, 0.32, 0.28, 2.6), (-0.6, ex, 2.24, 0.34, 0.32, 0.28, 2.6),
              (-1.2, ex, 2.22, 0.22, 0.2, 0.18, 2.4)], "paint")
        cyl((ex, 1.94, 2.22), 0.15, 0.05, "dark", "Y", seg=12)
        exhaust_box(ex + s * 0.16, -1.2, 2.32, s, 0.5, 0.3, 0.3)
        wing(s * 0.66, s * 3.65, 0.6, 0.45, 1.5, 1.42, 1.25, 0.85, 0.15, 0.1, "paint")
        for k, xx in enumerate((1.5, 2.4, 3.2)):
            zz = 1.47
            pylon(s * xx, 0.5, zz, zz - 0.24)
            if k == 1:
                hydra(s * xx, 0.6, zz - 0.5, 1.6, 0.24)
            elif k == 2:
                atgm_rack(s * xx, 0.5, zz - 0.42, 4, 1.8, 0.1)
            else:
                hydra(s * xx, 0.6, zz - 0.5, 1.4, 0.2)
        wheel(s * 1.05, 0.9, 0.32, 0.32, 0.2, (s * 0.62, 1.05, 0.95))
        # ikiz dikme (yatay stabilizatör uçlarında)
        fin(-5.3, -6.0, 1.3, 2.85, 0.4, 0.9, 0.55, 0.12, x=s * 1.6)
    wing(-1.65, 1.65, -5.6, -5.6, 1.62, 1.62, 0.8, 0.8, 0.08, 0.08, "paint")
    wheel(0.0, 5.3, 0.3, 0.26, 0.16, (0.0, 5.1, 0.7))
    # 2A42 30 mm top: gövdenin sağında yarı gömülü
    box((0.72, 2.2, 1.0), (0.3, 1.4, 0.34), "paint", bev=0.012)
    gun(2.9, 1.0, 1.5, 0.045, "gun", x=0.72)
    tube([(1.6, 0.0, 2.34, 0.3, 0.2, 0.05, 2.4), (0.4, 0.0, 2.38, 0.46, 0.34, 0.06, 2.6), (-0.8, 0.0, 2.32, 0.3, 0.2, 0.05, 2.4)], "paint")
    mast_hub(my, 2.5, hub + 1.08, 0.18)
    D = 14.5
    node("rotor")
    blades(0, my, hub, 3, D, chord=0.5)
    node("trotor")
    blades(0, my, hub + 1.0, 3, D, chord=0.5, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (0, my, hub), "trotor": (0, my, hub + 1.0)}, {"muzzle": (0.72, 3.7, 1.0), "radius": 4.0, "trotor_y": True}


# ------------------------------------------------------------------ AH-1Z Viper · UH-1Y Venom (utility)
def heli_slim(v):
    util = v.get("utility", False)
    my = 0.2
    hub_z = 3.85
    if util:
        body([(6.1, 0.24, 1.0, 1.5, 2.2), (5.7, 0.72, 0.72, 1.98, 2.6), (4.8, 0.95, 0.56, 2.2, 3.2), (1.6, 1.0, 0.52, 2.3, 3.6),
              (-0.6, 0.95, 0.58, 2.3, 3.4), (-1.8, 0.6, 1.0, 2.28, 2.8), (-3.0, 0.32, 1.42, 2.08, 2.4), (-8.9, 0.2, 1.62, 2.0, 2.2)])
        tube([(6.0, 0.0, 1.5, 0.24, 0.16, 0.1, 2.0), (5.6, 0.0, 1.66, 0.74, 0.36, 0.2, 2.4), (4.8, 0.0, 1.82, 0.94, 0.42, 0.2, 2.6),
              (4.3, 0.0, 1.9, 0.9, 0.36, 0.2, 2.4)], "glass")
        for s in (-1, 1):
            box((s * 1.0, 3.6, 1.6), (0.04, 1.0, 0.7), "glass", bev=0.0)
            frame([(s * 1.01, 3.0, 0.6), (s * 1.01, 3.0, 2.1), (s * 1.01, 0.6, 2.1), (s * 1.01, 0.6, 0.6)], 0.03, "dark")
            box((s * 1.02, 1.8, 1.65), (0.03, 0.9, 0.5), "glass", bev=0.0)
    else:
        body([(6.6, 0.12, 1.05, 1.32, 2.2), (6.2, 0.36, 0.8, 1.58, 2.4), (5.2, 0.48, 0.62, 1.8, 2.6), (3.0, 0.52, 0.56, 2.0, 2.8),
              (1.0, 0.56, 0.58, 2.25, 2.8), (-1.0, 0.5, 0.7, 2.25, 2.6), (-2.4, 0.32, 1.12, 2.0, 2.4), (-8.9, 0.2, 1.6, 2.0, 2.2)])
        tube([(5.9, 0.0, 1.55, 0.14, 0.08, 0.05, 2.0), (5.5, 0.0, 1.6, 0.42, 0.36, 0.1, 2.4), (4.2, 0.0, 1.74, 0.48, 0.44, 0.12, 2.6),
              (2.7, 0.0, 1.9, 0.5, 0.52, 0.12, 2.6), (2.2, 0.0, 1.95, 0.42, 0.36, 0.12, 2.4)], "glass")
        frame([(0, 5.4, 1.92), (0, 2.3, 2.42)], 0.035, "dark")
        frame([(-0.48, 3.8, 1.82), (0, 3.8, 2.25), (0.48, 3.8, 1.82)], 0.035, "dark")
        sensor_ball(0, 6.45, 1.15, 0.3, 2)
        cyl((0, 5.0, 0.42), 0.18, 0.24, "dark", "Z", seg=12)
        gun(5.1, 0.32, 1.4, 0.035, "gun")
        for s in (-1, 1):
            wing(s * 0.5, s * 2.6, 0.3, 0.2, 1.3, 1.24, 1.0, 0.75, 0.13, 0.1, "paint")
            pylon(s * 1.4, 0.25, 1.26, 1.02)
            hydra(s * 1.4, 0.32, 0.78)
            pylon(s * 2.25, 0.2, 1.24, 1.0)
            atgm_rack(s * 2.25, 0.2, 0.84, 4, 1.65, 0.09)
            box((s * 2.66, 0.2, 1.24), (0.12, 0.6, 0.14), "dark", bev=0.006)
    for s in (-1, 1):
        ex = s * 0.62
        tube([(1.4, ex, 2.36, 0.16, 0.14, 0.12, 2.2), (1.1, ex, 2.38, 0.32, 0.28, 0.22, 2.6), (-1.0, ex, 2.4, 0.34, 0.28, 0.22, 2.6),
              (-1.6, ex, 2.4, 0.22, 0.18, 0.16, 2.4)], "paint")
        exhaust_box(ex, -1.75, 2.5, s, 0.5, 0.3, 0.26)
        # kızaklar
        sw = 1.25 if util else 1.05
        rod((s * sw, 3.6, 0.1), (s * sw, -1.6, 0.1), 0.055, "dark", 8)
        rod((s * sw, 3.6, 0.1), (s * sw, 4.0, 0.3), 0.055, "dark", 8)
        rod((s * sw, 2.4, 0.1), (s * 0.5, 2.4, 0.62), 0.05, "dark", 6)
        rod((s * sw, -0.6, 0.1), (s * 0.5, -0.6, 0.7), 0.05, "dark", 6)
    tube([(1.6, 0.0, 2.3, 0.3, 0.2, 0.05, 2.4), (0.6, 0.0, 2.36, 0.46, 0.34, 0.06, 2.6), (-1.0, 0.0, 2.32, 0.3, 0.22, 0.05, 2.4)], "paint")
    fin(-8.3, -9.3, 1.85, 3.9, 0.7, 1.1, 0.7, 0.2)
    for s in (-1, 1):
        wing(s * 0.1, s * 1.45, -6.4, -6.5, 1.78, 1.82, 0.7, 0.5, 0.08, 0.06, "paint")
    mast_hub(my, 2.45, hub_z)
    tr_x, tr_y, tr_z = -0.24, -9.0, 3.4
    node("rotor")
    blades(0, my, hub_z, 4, 14.88, chord=0.55)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 4, 2.9, -1)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (0, 6.4, 0.32) if not util else (1.2, 2.0, 1.3), "radius": 3.8}


# ------------------------------------------------------------------ hafif: AH-6M / OH-58D (direk nişangâhı) / UH-72 · Ansat (kabin)
def heli_light(v):
    cabin = v.get("cabin", False)
    mast_sight = v.get("mast", False)
    my = 0.0
    if cabin:
        # UH-72 Lakota / Ansat: yüksek kabin, sürgülü kapı, kuyruk kirişi, kızak
        hub_z = 3.2
        body([(4.3, 0.28, 0.92, 1.48, 2.2), (3.9, 0.74, 0.62, 1.92, 2.6), (2.9, 0.88, 0.5, 2.2, 3.2), (0.4, 0.9, 0.5, 2.3, 3.4),
              (-1.2, 0.8, 0.62, 2.26, 3.0), (-1.9, 0.42, 1.2, 2.1, 2.4), (-6.8, 0.18, 1.5, 1.95, 2.2)])
        tube([(4.25, 0.0, 1.46, 0.28, 0.18, 0.1, 2.0), (3.8, 0.0, 1.62, 0.76, 0.44, 0.3, 2.4), (2.9, 0.0, 1.76, 0.88, 0.48, 0.3, 2.6)], "glass")
        for s in (-1, 1):
            box((s * 0.9, 1.6, 1.62), (0.04, 1.3, 0.8), "glass", bev=0.0)
            frame([(s * 0.91, 1.0, 0.55), (s * 0.91, 1.0, 2.2), (s * 0.91, -0.6, 2.2), (s * 0.91, -0.6, 0.55)], 0.03, "dark")
            rod((s * 1.0, 2.6, 0.1), (s * 1.0, -1.4, 0.1), 0.05, "dark", 6)
            rod((s * 1.0, 1.8, 0.1), (s * 0.6, 1.8, 0.56), 0.045, "dark", 6)
            rod((s * 1.0, -0.6, 0.1), (s * 0.6, -0.6, 0.6), 0.045, "dark", 6)
        tube([(1.4, 0.0, 2.28, 0.4, 0.24, 0.05, 2.6), (-1.0, 0.0, 2.3, 0.5, 0.3, 0.05, 2.6)], "paint")
        fin(-6.4, -7.2, 1.6, 3.0, 0.5, 0.9, 0.6, 0.12)
        for s in (-1, 1):
            wing(s * 0.1, s * 1.1, -5.6, -5.7, 1.74, 1.74, 0.55, 0.45, 0.06, 0.05, "paint")
        D = 11.0
        nb = 4
        tr = (0.16, -6.95, 2.4)
        tdia = 1.9
    else:
        # MH-6 / AH-6 (yumurta gövde) ve OH-58D (dar, direk üstü nişangâh)
        hub_z = 2.62 if not mast_sight else 2.95
        if mast_sight:
            body([(3.1, 0.24, 0.8, 1.35, 2.2), (2.7, 0.6, 0.55, 1.75, 2.6), (1.8, 0.7, 0.45, 1.95, 3.0), (0.0, 0.7, 0.45, 2.0, 3.2),
                  (-1.0, 0.6, 0.55, 1.95, 2.8), (-1.6, 0.3, 1.0, 1.78, 2.4), (-6.9, 0.16, 1.3, 1.6, 2.2)])
            tube([(3.05, 0.0, 1.32, 0.24, 0.18, 0.1, 2.0), (2.6, 0.0, 1.48, 0.62, 0.42, 0.28, 2.4), (1.4, 0.0, 1.62, 0.7, 0.42, 0.28, 2.6)], "glass")
            D = 10.67
            tr = (0.16, -6.95, 2.05)
            tdia = 1.65
        else:
            body([(2.55, 0.18, 0.86, 1.25, 2.0), (2.2, 0.62, 0.55, 1.68, 2.2), (1.2, 0.8, 0.45, 1.9, 2.2), (0.0, 0.78, 0.46, 1.92, 2.2),
                  (-0.9, 0.6, 0.58, 1.82, 2.2), (-1.4, 0.3, 0.95, 1.65, 2.2), (-5.3, 0.13, 1.18, 1.42, 2.2)])
            tube([(2.5, 0.0, 1.22, 0.2, 0.14, 0.1, 2.0), (2.1, 0.0, 1.38, 0.62, 0.4, 0.3, 2.2), (0.9, 0.0, 1.5, 0.78, 0.44, 0.3, 2.2)], "glass")
            D = 8.3
            tr = (0.14, -5.3, 1.85)
            tdia = 1.4
            # silah kirişleri: 7,62 mini top + roket kovanı
            for s in (-1, 1):
                rod((s * 0.7, 0.2, 0.75), (s * 1.6, 0.2, 0.75), 0.05, "metal", 6)
                hydra(s * 1.45, 0.3, 0.55, 1.2, 0.18)
                gun(0.9, 0.95, 1.0, 0.03, "gun", x=s * 1.05)
        for s in (-1, 1):
            rod((s * 0.85, 1.6, 0.1), (s * 0.85, -1.2, 0.1), 0.045, "dark", 6)
            rod((s * 0.85, 1.0, 0.1), (s * 0.5, 1.0, 0.5), 0.04, "dark", 6)
            rod((s * 0.85, -0.6, 0.1), (s * 0.5, -0.6, 0.55), 0.04, "dark", 6)
        fin(tr[1] + 0.35, tr[1] - 0.25, 1.15, tr[2] + 0.55, 0.35, 0.7, 0.45, 0.1)
        for s in (-1, 1):
            wing(s * 0.1, s * 0.75, tr[1] + 0.9, tr[1] + 0.85, 1.32, 1.32, 0.4, 0.32, 0.05, 0.04, "paint")
        nb = 5 if not mast_sight else 4
        if mast_sight:
            cyl((0, my, hub_z + 0.55), 0.32, 0.5, "paint", seg=16)                      # direk üstü nişangâh (MMS)
            for k in range(2):
                cyl((-0.12 + k * 0.24, my + 0.3, hub_z + 0.58), 0.08, 0.04, "glass", "Y", seg=10)
        tube([(0.8, 0.0, 1.92, 0.36, 0.2, 0.05, 2.4), (-0.8, 0.0, 1.9, 0.36, 0.22, 0.05, 2.4)], "paint")
    mast_hub(my, 2.0 if not cabin else 2.3, hub_z, 0.12)
    node("rotor")
    blades(0, my, hub_z, nb, D, chord=0.27 if not cabin else 0.33)
    node("trotor")
    tail_blades(tr[0], tr[1], tr[2], 2, tdia, 1)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": tr}, {"muzzle": (1.05, 1.5, 0.95) if not cabin else (0.9, 2.0, 1.0), "radius": 2.6 if not cabin else 3.2}


# ------------------------------------------------------------------ CH-53K King Stallion
def heli_heavy(v):
    my = 0.4
    hub_z = 5.6
    body([(8.9, 0.3, 1.25, 1.95, 2.2), (8.5, 1.05, 0.9, 2.5, 2.6), (7.4, 1.45, 0.62, 2.95, 3.2), (5.8, 1.6, 0.55, 3.15, 3.8),
          (-3.4, 1.62, 0.55, 3.2, 4.0), (-5.4, 1.4, 0.95, 3.15, 3.4), (-6.8, 0.75, 2.2, 3.1, 2.6), (-12.2, 0.42, 2.7, 3.15, 2.2)])
    tube([(8.85, 0.0, 1.95, 0.3, 0.24, 0.14, 2.0), (8.4, 0.0, 2.12, 1.05, 0.52, 0.3, 2.4), (7.5, 0.0, 2.32, 1.44, 0.6, 0.3, 2.6)], "glass")
    frame([(0, 8.7, 2.1), (0, 7.4, 2.95)], 0.04, "dark")
    for s in (-1, 1):
        box((s * 1.6, 6.6, 2.3), (0.05, 1.0, 0.75), "glass", bev=0.0)
        frame([(s * 1.62, 6.0, 0.62), (s * 1.62, 6.0, 2.6), (s * 1.62, 5.0, 2.6), (s * 1.62, 5.0, 0.62)], 0.035, "dark")
        for k in range(4):
            box((s * 1.63, 3.0 - k * 1.6, 2.3), (0.03, 0.5, 0.4), "glass", bev=0.0)
        # sponsonlar (yakıt + iniş takımı)
        tube([(2.4, s * 1.85, 1.1, 0.1, 0.1, 0.1, 2.0), (1.8, s * 2.05, 1.12, 0.5, 0.42, 0.5, 2.6), (-2.6, s * 2.05, 1.12, 0.5, 0.42, 0.5, 2.6),
              (-3.2, s * 1.85, 1.12, 0.1, 0.1, 0.1, 2.0)], "paint")
        wheel(s * 2.2, -0.6, 0.5, 0.5, 0.32, (s * 2.0, -0.4, 1.0))
        # motorlar (üst yanlarda, üç motordan ikisi) + egzoz
        ex = s * 1.25
        tube([(2.2, ex, 3.3, 0.24, 0.22, 0.2, 2.2), (1.8, ex, 3.32, 0.48, 0.42, 0.38, 2.6), (-1.2, ex, 3.36, 0.5, 0.42, 0.38, 2.8),
              (-1.8, ex, 3.34, 0.34, 0.3, 0.26, 2.4)], "paint")
        exhaust_box(ex + s * 0.24, -2.0, 3.45, s, 0.7, 0.42, 0.36)
    wheel(0.3, 6.4, 0.42, 0.42, 0.22, (0.15, 6.2, 1.0))
    wheel(-0.3, 6.4, 0.42, 0.42, 0.22, (-0.15, 6.2, 1.0))
    tube([(2.8, 0.0, 3.3, 0.4, 0.3, 0.06, 2.4), (1.2, 0.0, 3.36, 0.9, 0.62, 0.08, 2.8), (-2.2, 0.0, 3.36, 0.9, 0.62, 0.08, 2.8)], "paint")
    tube([(-0.6, 0.0, 3.4, 0.4, 0.4, 0.3, 2.4), (-2.6, 0.0, 3.5, 0.36, 0.36, 0.3, 2.4)], "paint")      # 3. motor (arkada üst)
    rod((0, 9.0, 2.0), (0, 11.0, 2.5), 0.04, "metal", 6)                                    # yakıt ikmal sondası
    fin(-11.6, -12.7, 2.9, 6.6, 0.9, 1.6, 1.0, 0.3)
    wing(0.2, 3.4, -12.3, -12.4, 5.6, 5.4, 1.1, 0.8, 0.1, 0.08, "paint")                    # tek taraflı stabilizatör (sağda)
    mast_hub(my, 3.6, hub_z, 0.28)
    tr_x, tr_y, tr_z = -0.34, -12.6, 5.7
    node("rotor")
    blades(0, my, hub_z, 7, 24.08, chord=0.78)
    node("trotor")
    tail_blades(tr_x, tr_y, tr_z, 4, 6.1, -1)
    return {"body": (0, 0, 0), "rotor": (0, my, hub_z), "trotor": (tr_x, tr_y, tr_z)}, {"muzzle": (1.6, 6.0, 2.0), "radius": 7.0}


# ------------------------------------------------------------------ MV-22B Osprey (devrilen rotor; helikopter kipinde)
def tiltrotor(v):
    hub_z = 6.3
    body([(8.7, 0.3, 1.0, 1.8, 2.2), (8.2, 0.95, 0.72, 2.35, 2.6), (6.8, 1.25, 0.55, 2.8, 3.4), (4.0, 1.3, 0.5, 2.9, 3.8),
          (-3.6, 1.3, 0.5, 2.92, 3.8), (-5.6, 1.0, 1.0, 2.9, 3.0), (-8.0, 0.4, 2.2, 2.85, 2.4), (-8.5, 0.3, 2.3, 2.85, 2.2)])
    tube([(8.6, 0.0, 1.78, 0.3, 0.22, 0.12, 2.0), (8.1, 0.0, 1.98, 0.98, 0.5, 0.28, 2.4), (7.0, 0.0, 2.18, 1.24, 0.56, 0.28, 2.6)], "glass")
    rod((0.6, 8.6, 2.1), (0.9, 10.8, 2.5), 0.04, "metal", 6)                                # yakıt ikmal sondası
    for s in (-1, 1):
        box((s * 1.3, 6.2, 2.2), (0.05, 0.8, 0.6), "glass", bev=0.0)
        tube([(2.0, s * 1.45, 1.0, 0.1, 0.1, 0.1, 2.0), (1.4, s * 1.6, 1.0, 0.36, 0.42, 0.42, 2.6), (-2.0, s * 1.6, 1.0, 0.36, 0.42, 0.42, 2.6),
              (-2.6, s * 1.45, 1.0, 0.1, 0.1, 0.1, 2.0)], "paint")
        wheel(s * 1.65, -0.6, 0.44, 0.44, 0.3, (s * 1.5, -0.4, 0.9))
        # kanat (üstte) + motor nasel (dik konumda)
        wing(0.0, s * 6.95, 0.45, 0.45, 3.1, 3.1, 2.55, 2.3, 0.4, 0.34, "paint")
        tube([(0.4, s * 7.0, 3.1, 0.55, 0.55, 0.55, 2.4)] * 1 + [(-1.4, s * 7.0, 3.1, 0.55, 0.55, 0.55, 2.4)], "paint")
        cyl((s * 7.0, 0.4, 4.4), 0.6, 2.6, "paint", "Z", seg=16)                                 # dik nasel
        cyl((s * 7.0, 0.4, 5.75), 0.5, 0.5, "paint", "Z", seg=16, r2=0.25)                       # spinner
    wheel(0.25, 6.6, 0.38, 0.38, 0.2, (0.12, 6.4, 0.9))
    wheel(-0.25, 6.6, 0.38, 0.38, 0.2, (-0.12, 6.4, 0.9))
    # rampa ve ikiz dikme + stabilizatör
    frame([(-1.2, -5.6, 1.0), (0, -6.0, 1.0), (1.2, -5.6, 1.0)], 0.035, "dark")
    wing(-2.8, 2.8, -7.9, -7.9, 2.95, 2.95, 1.3, 1.3, 0.12, 0.12, "paint")
    for s in (-1, 1):
        fin(-7.4, -8.4, 2.95, 5.2, 0.5, 1.3, 0.9, 0.16, x=s * 2.8)
    node("rotor")
    blades(-7.0, 0.4, hub_z, 3, 11.6, chord=0.62)
    node("trotor")
    blades(7.0, 0.4, hub_z, 3, 11.6, chord=0.62, phase=math.pi / 3)
    return {"body": (0, 0, 0), "rotor": (-7.0, 0.4, hub_z), "trotor": (7.0, 0.4, hub_z)}, {"muzzle": (0, 6.2, 1.2), "radius": 7.0, "trotor_y": True}


FAMILIES = {"heli_atk": heli_atk, "heli_utility": heli_utility, "heli_hind": heli_hind, "heli_mi8": heli_mi8,
            "heli_coax": heli_coax, "heli_slim": heli_slim, "heli_light": heli_light, "heli_heavy": heli_heavy,
            "tiltrotor": tiltrotor}
