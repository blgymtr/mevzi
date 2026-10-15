# Kargo / ağır nakliye helikopterleri (hava indirme): tandem rotorlu (CH-47F tipi) ve tek rotorlu dev (Mi-26 tipi).
# Düğümler: body, rotor (ön / ana rotor), trotor (arka / kuyruk rotoru), ramp (arka rampa, menteşe pivotu).
# Gövde yuvarlatılmış dikdörtgen kesitlerden loft; kokpit camları, pencereler, sponsonlar, iniş takımı, motorlar ayrı parça.
import math
from vlib import *


def rr(w, z0, z1, r, n=3):
    """Yuvarlatılmış dikdörtgen yarım kesit (alt merkezden üst merkeze, x >= 0)."""
    r = min(r, w * 0.95, (z1 - z0) * 0.48)
    pts = [(0.0, z0)]
    for i in range(n + 1):
        a = -math.pi / 2 + (math.pi / 2) * i / n
        pts.append((w - r + math.cos(a) * r, z0 + r + math.sin(a) * r))
    for i in range(n + 1):
        a = (math.pi / 2) * i / n
        pts.append((w - r + math.cos(a) * r, z1 - r + math.sin(a) * r))
    pts.append((0.0, z1))
    return pts


def body_loft(secs, mname="paint", n=3):
    loft([(y, rr(w, z0, z1, r, n)) for y, w, z0, z1, r in secs], mname, bev=0.0)


def rotor_head(cx, cy, cz, nb, D, chord, droop=0.12, phase=0.0, tip="mark", hub_r=0.32):
    """Rotor göbeği + pal bağlantıları + palller (uç şeritli). D = rotor çapı."""
    cyl((cx, cy, cz), hub_r, 0.34, "metal", seg=14)
    cyl((cx, cy, cz + 0.24), hub_r * 0.55, 0.22, "dark", seg=10)
    R = D * 0.5
    for k in range(nb):
        a = phase + k * math.tau / nb
        ca, sa = math.cos(a), math.sin(a)
        # pal manşonu + hatve kolu
        box((cx + ca * (hub_r + 0.3), cy + sa * (hub_r + 0.3), cz), (0.62, 0.2, 0.16), "metal", rot=(0, 0, a), bev=0.0)
        box((cx + ca * (hub_r + 0.1) - sa * 0.14, cy + sa * (hub_r + 0.1) + ca * 0.14, cz - 0.16), (0.06, 0.06, 0.36), "dark", rot=(0, 0, a), bev=0.0)
        # pal: tek parça, hafif sarkık; uçta renkli şerit
        L = R - hub_r - 0.55
        d = math.atan2(droop, R)
        rm = hub_r + 0.6 + L * 0.5
        box((cx + ca * rm, cy + sa * rm, cz + 0.02 - math.sin(d) * rm), (L, chord, 0.06), "dark", rot=(0, d, a), bev=0.0)
        rt = R - 0.3
        box((cx + ca * rt, cy + sa * rt, cz + 0.03 - math.sin(d) * rt), (0.5, chord + 0.01, 0.066), tip, rot=(0, d, a), bev=0.0)


def tail_rotor(cx, cy, cz, nb, D, side=1):
    cyl((cx, cy, cz), 0.18, 0.3, "metal", "X", seg=10)
    R = D * 0.5
    for k in range(nb):
        a = k * math.tau / nb
        box((cx + side * 0.1, cy + math.cos(a) * R * 0.5, cz + math.sin(a) * R * 0.5), (0.05, R - 0.1, 0.24), "dark", rot=(-a, 0, 0), bev=0.0)
        box((cx + side * 0.1, cy + math.cos(a) * (R - 0.2), cz + math.sin(a) * (R - 0.2)), (0.055, 0.35, 0.25), "mark", rot=(-a, 0, 0), bev=0.0)


def gear_leg(x, y, z_top, r, w, twin=False, tandem=False):
    """İniş takımı: amortisör + makas + tekerler (zemin z=0)."""
    zc = r
    cyl((x, y, (z_top + zc) * 0.5), 0.09, z_top - zc, "metal", seg=8)
    cyl((x, y, zc + 0.35), 0.13, 0.4, "dark", seg=8)
    box((x, y + 0.18, zc + 0.6), (0.06, 0.32, 0.06), "metal", rot=(0.6, 0, 0), bev=0.0)
    offs = [(-0.2, 0), (0.2, 0)] if twin else [(0, 0)]
    if tandem:
        offs = [(0, -r * 1.15), (0, r * 1.15)]
        box((x, y, zc), (0.12, r * 2.6, 0.14), "metal", bev=0.0)
    for dx, dy in offs:
        cyl((x + dx, y + dy, zc), r, w, "rubber", "X", seg=16)
        cyl((x + dx, y + dy, zc), r * 0.55, w + 0.02, "metal", "X", seg=12)
        cyl((x + dx, y + dy, zc), r * 0.2, w + 0.06, "dark", "X", seg=8)


def round_windows(x, ys, z, r=0.17, side=1):
    for y in ys:
        cyl((x, y, z), r + 0.04, 0.035, "trim", "X", seg=14)
        cyl((x + side * 0.012, y, z), r, 0.04, "glass", "X", seg=14)


def panel_lines(x, y0, y1, z0, z1, side, step=1.2):
    """Sac panel ek yerleri: yüzeyde ince koyu çizgiler."""
    n = int((y0 - y1) / step)
    for i in range(n + 1):
        y = y0 - i * step
        box((x + side * 0.005, y, (z0 + z1) * 0.5), (0.012, 0.025, z1 - z0), "trim", bev=0.0)
    box((x + side * 0.005, (y0 + y1) * 0.5, z0 + (z1 - z0) * 0.33), (0.012, y0 - y1, 0.022), "trim", bev=0.0)


def sec_at(secs, y):
    for (y0, *p0), (y1, *p1) in zip(secs, secs[1:]):
        lo, hi = min(y0, y1), max(y0, y1)
        if lo <= y <= hi:
            t = (y - y0) / (y1 - y0) if y1 != y0 else 0.0
            return [a + (b - a) * t for a, b in zip(p0, p1)]
    return list(secs[0][1:]) if abs(y - secs[0][0]) < abs(y - secs[-1][0]) else list(secs[-1][1:])


def rr_pt(w, z0, z1, r, u):
    """Yarım kesitte yay uzunluğu oranı u (0 alt merkez, 1 üst merkez) noktası + dışa normal."""
    pts = rr(w, z0, z1, r, 8)
    L = [0.0]
    for p, q in zip(pts, pts[1:]):
        L.append(L[-1] + math.dist(p, q))
    d = u * L[-1]
    for i in range(1, len(pts)):
        if d <= L[i] or i == len(pts) - 1:
            p, q = pts[i - 1], pts[i]
            t = (d - L[i - 1]) / max(L[i] - L[i - 1], 1e-6)
            x, z = p[0] + (q[0] - p[0]) * t, p[1] + (q[1] - p[1]) * t
            tx, tz = q[0] - p[0], q[1] - p[1]
            n = math.hypot(tx, tz) or 1.0
            return x, z, tz / n, -tx / n


def surf_panel(secs, y0, y1, u0, u1, side, mname="glass", off=0.02, depth=0.05, n=3):
    pts = []
    for i in range(n + 1):
        y = y0 + (y1 - y0) * i / n
        w, z0, z1, r = sec_at(secs, y)
        for k in range(n + 1):
            x, z, nx, nz = rr_pt(w, z0, z1, r, u0 + (u1 - u0) * k / n)
            for o in (off, off - depth):
                pts.append((side * (x + nx * o), y, z + nz * o))
    hull_pts(pts, mname, bev=0.0)


def window(secs, y0, y1, u0, u1, side):
    """Çerçeveli cam: koyu çerçeve biraz geniş ve alçak, cam üstte."""
    surf_panel(secs, y0 - 0.05, y1 + 0.05, u0 - 0.012, u1 + 0.012, side, "dark", 0.012, 0.05)
    surf_panel(secs, y0, y1, u0, u1, side, "glass", 0.022, 0.05)


def glass_panel(c, size, rot, frame=True):
    box(c, size, "glass", rot=rot, bev=0.0)
    if frame:
        sx, sy, sz = size
        box(c, (sx + 0.06, max(sy - 0.01, 0.02), sz + 0.06), "dark", rot=rot, bev=0.0)


# ------------------------------------------------------------ CH-47F tipi tandem
CH47_NOSE = [(4.6, 1.3, 0.75, 3.3, 0.45), (5.6, 1.28, 0.8, 3.22, 0.5), (6.4, 1.18, 0.95, 3.02, 0.55),
             (7.0, 1.0, 1.15, 2.72, 0.5), (7.45, 0.7, 1.38, 2.36, 0.35), (7.72, 0.34, 1.58, 2.06, 0.15)]
MI26_NOSE = [(6.0, 1.75, 0.95, 4.3, 0.7), (7.4, 1.72, 1.0, 4.2, 0.75), (8.6, 1.6, 1.15, 4.0, 0.8), (9.6, 1.35, 1.35, 3.72, 0.75),
             (10.4, 1.0, 1.62, 3.36, 0.6), (10.9, 0.56, 1.92, 3.02, 0.35), (11.12, 0.2, 2.2, 2.7, 0.1)]


def cargo_ch47(v):
    # ana gövde (kabin) + burun
    body_loft([
        (-6.0, 1.3, 0.75, 3.3, 0.45),
        (-3.0, 1.3, 0.75, 3.3, 0.45),
        (4.6, 1.3, 0.75, 3.3, 0.45),
        (5.6, 1.28, 0.8, 3.22, 0.5),
        (6.4, 1.18, 0.95, 3.02, 0.55),
        (7.0, 1.0, 1.15, 2.72, 0.5),
        (7.45, 0.7, 1.38, 2.36, 0.35),
        (7.72, 0.34, 1.58, 2.06, 0.15),
    ])
    # arka üst gövde: alt hat rampaya doğru yükselir
    body_loft([
        (-5.95, 1.3, 0.8, 3.3, 0.45),
        (-6.9, 1.26, 1.65, 3.3, 0.45),
        (-7.75, 1.12, 2.6, 3.22, 0.4),
        (-7.95, 0.9, 2.85, 3.1, 0.12),
    ])
    # arka pilon (uzun, motorlar ve arka rotor)
    body_loft([
        (-2.4, 0.5, 3.2, 3.36, 0.08),
        (-3.6, 0.7, 3.2, 4.2, 0.3),
        (-5.0, 0.76, 3.2, 4.88, 0.35),
        (-6.6, 0.7, 3.0, 5.18, 0.35),
        (-7.6, 0.55, 2.95, 5.02, 0.3),
        (-8.05, 0.3, 3.15, 4.6, 0.12),
    ])
    # ön pilon
    body_loft([
        (3.4, 0.45, 3.2, 3.32, 0.06),
        (4.3, 0.62, 3.2, 3.78, 0.25),
        (5.6, 0.6, 3.1, 3.88, 0.25),
        (6.3, 0.45, 3.0, 3.62, 0.2),
        (6.7, 0.18, 3.0, 3.2, 0.06),
    ])
    # üst geçit tüneli (pilonlar arası)
    box((0, 0.4, 3.4), (0.95, 6.2, 0.2), "paint", bev=0.008)
    box((0, 0.4, 3.51), (0.7, 6.0, 0.03), "trim", bev=0.0)
    # sponsonlar (yan yakıt depoları)
    for s in (-1, 1):
        hull_pts([(s * 1.22, y, z) for y in (-4.7, 3.95) for z in (0.62, 1.78)] +
                 [(s * 1.88, y, z) for y in (-4.1, 3.3) for z in (0.82, 1.58)] +
                 [(s * 1.6, y, z) for y in (-4.55, 3.8) for z in (0.68, 1.72)], "paint", bev=0.0)
        box((s * 1.885, -0.4, 1.2), (0.015, 6.8, 0.03), "trim", bev=0.0)
        # motor naseli + bağlantı
        cyl((s * 1.32, -5.2, 4.05), 0.43, 3.0, "paint", "Y", seg=18, r2=0.4)
        cyl((s * 1.32, -3.66, 4.05), 0.36, 0.08, "metal", "Y", seg=18)
        cyl((s * 1.32, -3.62, 4.05), 0.3, 0.06, "dark", "Y", seg=16)
        cyl((s * 1.32, -3.55, 4.05), 0.12, 0.25, "metal", "Y", seg=10, r2=0.04)
        cyl((s * 1.32, -6.9, 4.05), 0.33, 0.5, "metal", "Y", seg=16, r2=0.29)
        cyl((s * 1.32, -7.16, 4.05), 0.26, 0.04, "dark", "Y", seg=14)
        box((s * 0.98, -5.2, 4.05), (0.55, 1.7, 0.24), "paint", bev=0.008)
        for k in range(4):
            box((s * 1.32, -4.3 - k * 0.6, 4.05 + 0.43), (0.25, 0.02, 0.02), "trim", bev=0.0)
        # pencereler, panel çizgileri
        round_windows(s * 1.305, [3.1, 1.9, 0.7, -0.5, -1.7, -2.9, -4.1], 2.35, side=s)
        panel_lines(s * 1.3, 4.4, -5.6, 0.85, 3.2, s, 1.25)
        # kokpit camları: ön (iki panel), yan (iki panel), çene, tavan
        window(CH47_NOSE, 6.75, 7.32, 0.8, 0.975, s)
        window(CH47_NOSE, 6.75, 7.36, 0.62, 0.785, s)
        window(CH47_NOSE, 6.0, 6.68, 0.47, 0.66, s)
        window(CH47_NOSE, 5.35, 5.92, 0.48, 0.66, s)
        window(CH47_NOSE, 6.95, 7.5, 0.13, 0.33, s)
        window(CH47_NOSE, 6.0, 6.6, 0.87, 0.97, s)
        # pitot tüpleri, aynalar, seyir ışıkları
        cyl((s * 0.5, 7.6, 1.95), 0.02, 0.7, "metal", "Y", seg=6)
        box((s * 1.36, 7.0, 2.05), (0.18, 0.06, 0.14), "dark", bev=0.0)
        box((s * 1.9, 0.0, 1.62), (0.05, 0.12, 0.05), "red" if s < 0 else "light", bev=0.0)
        # iniş takımları: ön çift teker, arka tek teker
        gear_leg(s * 1.5, 4.25, 0.9, 0.38, 0.22, twin=True)
        gear_leg(s * 1.68, -4.35, 0.85, 0.42, 0.32)
        # basamaklar
        box((s * 1.33, 4.6, 0.62), (0.18, 0.5, 0.04), "dark", bev=0.0)
    # sağ ön kapı + vinç, burun antenleri, alt kanca, işaret/çarpışma ışıkları
    box((1.31, 4.15, 1.75), (0.03, 0.95, 1.65), "trim", bev=0.0)
    box((1.325, 4.15, 1.75), (0.02, 0.85, 1.55), "paint", bev=0.0)
    cyl((1.42, 4.15, 3.25), 0.12, 0.6, "metal", "Y", seg=10)
    box((1.42, 4.6, 3.25), (0.25, 0.25, 0.08), "metal", bev=0.0)
    for y in (2.6, 0.2, -2.2):
        cyl((0, y, 0.68), 0.08, 0.14, "metal", seg=8)
        box((0, y, 0.6), (0.06, 0.18, 0.06), "dark", bev=0.0)
    antenna(0.4, 2.0, 3.5, 0.6)
    antenna(-0.4, -1.0, 3.5, 0.5)
    box((0, 1.0, 0.72), (0.5, 0.25, 0.06), "dark", bev=0.0)
    cyl((0, -7.9, 4.0), 0.08, 0.1, "red", "Y", seg=8)
    cyl((0, 6.8, 3.3), 0.06, 0.1, "red", seg=8)
    # arka kapak üstü (rampa yukarı kapı)
    box((0, -7.86, 3.0), (2.0, 0.04, 0.35), "trim", bev=0.0)
    # rotor direkleri
    cyl((0, 5.2, 4.1), 0.2, 0.7, "metal", seg=12)
    cyl((0, -6.3, 5.42), 0.22, 0.6, "metal", seg=12)
    node("ramp")
    # arka rampa: menteşe (y=-6.0, z=0.75) — kapalıyken 45° yukarı
    L = 2.55
    a = math.radians(45)
    c = (0, -6.0 - math.cos(a) * L * 0.5, 0.75 + math.sin(a) * L * 0.5)
    box(c, (2.42, L, 0.12), "paint", rot=(-a, 0, 0), bev=0.0)
    for x in (-0.8, 0.0, 0.8):
        box((x, c[1] + 0.03, c[2] + 0.03), (0.06, L * 0.95, 0.04), "trim", rot=(-a, 0, 0), bev=0.0)
    node("rotor")
    rotor_head(0, 5.2, 4.48, 3, 18.3, 0.82, droop=0.25)
    node("trotor")
    rotor_head(0, -6.3, 5.8, 3, 18.3, 0.82, droop=0.25, phase=math.pi / 3)
    return ({"body": (0, 0, 0), "rotor": (0, 5.2, 4.48), "trotor": (0, -6.3, 5.8), "ramp": (0, -6.0, 0.75)},
            {"muzzle": (1.3, 3.0, 2.0), "radius": 6.5, "trotor_y": True, "ramp_open": 1.05, "hook": (0, 0.2, 0.6), "cargo": True})


# ------------------------------------------------------------ Mi-26 tipi dev nakliye
def cargo_mi26(v):
    body_loft([
        (-9.0, 1.75, 0.95, 4.3, 0.7),
        (6.0, 1.75, 0.95, 4.3, 0.7),
        (7.4, 1.72, 1.0, 4.2, 0.75),
        (8.6, 1.6, 1.15, 4.0, 0.8),
        (9.6, 1.35, 1.35, 3.72, 0.75),
        (10.4, 1.0, 1.62, 3.36, 0.6),
        (10.9, 0.56, 1.92, 3.02, 0.35),
        (11.12, 0.2, 2.2, 2.7, 0.1),
    ])
    # arka gövde: rampa/kapaklara doğru yükselen alt hat
    body_loft([
        (-8.95, 1.75, 1.0, 4.3, 0.7),
        (-10.2, 1.6, 1.65, 4.3, 0.7),
        (-11.4, 1.25, 2.5, 4.32, 0.55),
        (-12.5, 0.86, 3.2, 4.36, 0.4),
    ])
    # kuyruk konisi
    body_loft([
        (-12.45, 0.86, 3.2, 4.36, 0.4),
        (-16.0, 0.6, 3.55, 4.42, 0.3),
        (-21.0, 0.42, 3.85, 4.5, 0.2),
        (-22.8, 0.36, 3.92, 4.55, 0.16),
        (-23.4, 0.2, 4.0, 4.45, 0.08),
    ])
    # dikey kuyruk (geriye ok açılı) + yatay stabilize
    hull_pts([(s * 0.16, -20.6, 4.4) for s in (-1, 1)] + [(s * 0.16, -23.2, 4.4) for s in (-1, 1)] +
             [(s * 0.1, -22.3, 7.6) for s in (-1, 1)] + [(s * 0.1, -23.6, 7.7) for s in (-1, 1)], "paint", bev=0.0)
    box((0, -21.6, 4.42), (5.2, 1.2, 0.12), "paint", rot=(0.0, 0.0, 0.0), bev=0.0)
    for s in (-1, 1):
        box((s * 2.6, -21.6, 4.42), (0.06, 1.25, 0.5), "paint", bev=0.0)
    # motor güvertesi
    body_loft([
        (-4.8, 0.9, 4.2, 5.15, 0.3),
        (-3.6, 1.45, 4.2, 5.6, 0.45),
        (6.4, 1.45, 4.2, 5.6, 0.45),
        (7.2, 1.2, 4.15, 5.25, 0.4),
    ])
    for s in (-1, 1):
        # hava girişleri (ön), egzozlar (yan arka, dışa açılı)
        cyl((s * 0.72, 7.25, 4.86), 0.5, 0.3, "paint", "Y", seg=18)
        cyl((s * 0.72, 7.42, 4.86), 0.4, 0.05, "dark", "Y", seg=16)
        cyl((s * 0.72, 7.55, 4.86), 0.16, 0.4, "metal", "Y", seg=10, r2=0.04)
        cyl((s * 1.35, -4.0, 5.0), 0.4, 1.3, "metal", rot=(math.pi / 2, 0, s * 0.55), seg=16)
        cyl((s * 1.62, -4.45, 5.0), 0.3, 0.05, "dark", rot=(math.pi / 2, 0, s * 0.55), seg=14)
        for k in range(6):
            box((s * 1.455, 5.0 - k * 1.5, 4.9), (0.02, 0.9, 0.5), "trim", bev=0.0)
        # sponsonlar (yakıt depoları) + ana iniş takımı (tandem çift teker)
        hull_pts([(s * 1.7, y, z) for y in (-5.0, 4.6) for z in (1.0, 2.5)] +
                 [(s * 2.5, y, z) for y in (-4.3, 3.8) for z in (1.2, 2.25)] +
                 [(s * 2.2, y, z) for y in (-4.8, 4.4) for z in (1.05, 2.45)], "paint", bev=0.0)
        gear_leg(s * 2.2, -2.8, 1.2, 0.55, 0.34, tandem=True)
        box((s * 1.95, -2.8, 1.0), (0.55, 0.12, 0.12), "metal", bev=0.0)
        # pencereler, kapılar, panel çizgileri
        round_windows(s * 1.755, [4.4, 2.8, 1.2, -0.4, -2.0, -3.6, -5.2, -6.8], 2.75, r=0.2, side=s)
        panel_lines(s * 1.75, 5.8, -8.6, 1.0, 4.2, s, 1.6)
        box((s * 1.76, 6.6, 2.1), (0.03, 1.05, 1.9), "trim", bev=0.0)
        box((s * 1.775, 6.6, 2.1), (0.02, 0.95, 1.8), "paint", bev=0.0)
        cyl((s * 1.78, 6.6, 2.7), 0.16, 0.04, "glass", "X", seg=12)
        # kokpit camları: ön (iki panel), yan (üç panel), çene (seyrüseferci camları)
        window(MI26_NOSE, 10.0, 10.75, 0.8, 0.975, s)
        window(MI26_NOSE, 10.0, 10.8, 0.62, 0.785, s)
        window(MI26_NOSE, 9.25, 9.9, 0.47, 0.66, s)
        window(MI26_NOSE, 8.5, 9.15, 0.5, 0.68, s)
        window(MI26_NOSE, 7.7, 8.35, 0.52, 0.68, s)
        window(MI26_NOSE, 10.45, 11.0, 0.1, 0.3, s)
        window(MI26_NOSE, 10.1, 10.6, 0.3, 0.44, s)
        cyl((s * 0.35, 11.1, 2.55), 0.02, 0.8, "metal", "Y", seg=6)
        box((s * 2.5, 0.0, 2.0), (0.05, 0.14, 0.06), "red" if s < 0 else "light", bev=0.0)
        # kuyruk konisinde ısı fişeği kutuları
        box((s * 0.55, -15.0, 3.9), (0.12, 0.6, 0.3), "dark", bev=0.0)
    # burun iniş takımı (çift teker)
    gear_leg(0, 8.7, 1.25, 0.45, 0.26, twin=True)
    # ana dişli kutusu kamburu + direk
    box((0, 0.6, 5.85), (1.7, 3.4, 0.6), "paint", bev=0.008)
    cyl((0, 0.6, 6.4), 0.34, 0.75, "metal", seg=14)
    # antenler, kanca, çarpışma ışıkları, rampa üstü kapak çizgileri
    antenna(0.5, 3.0, 5.6, 0.8)
    antenna(-0.6, -2.5, 5.6, 0.6)
    antenna(0.0, -14.0, 4.42, 0.5)
    for y in (1.8, 0.6, -0.6):
        cyl((0, y, 0.92), 0.1, 0.14, "metal", seg=8)
    box((0, 0.6, 0.86), (0.7, 0.3, 0.07), "dark", bev=0.0)
    cyl((0, -3.0, 5.62), 0.08, 0.1, "red", seg=8)
    cyl((0, 8.0, 0.92), 0.08, 0.1, "red", seg=8)
    for s in (-1, 1):
        box((s * 1.0, -11.2, 2.4), (0.04, 2.2, 0.03), "trim", rot=(0.55, 0, 0), bev=0.0)
    node("ramp")
    L = 3.1
    a = math.radians(33)
    c = (0, -9.0 - math.cos(a) * L * 0.5, 0.95 + math.sin(a) * L * 0.5)
    box(c, (3.05, L, 0.14), "paint", rot=(-a, 0, 0), bev=0.0)
    for x in (-1.0, 0.0, 1.0):
        box((x, c[1] + 0.03, c[2] + 0.03), (0.07, L * 0.95, 0.05), "trim", rot=(-a, 0, 0), bev=0.0)
    node("rotor")
    rotor_head(0, 0.6, 6.85, 8, 28.8, 0.78, droop=0.35, hub_r=0.48)
    node("trotor")
    tail_rotor(0.45, -22.9, 6.9, 5, 6.8, 1)
    cyl((0.25, -22.9, 6.9), 0.2, 0.4, "paint", "X", seg=10)
    return ({"body": (0, 0, 0), "rotor": (0, 0.6, 6.85), "trotor": (0.45, -22.9, 6.9), "ramp": (0, -9.0, 0.95)},
            {"muzzle": (1.4, 3.0, 2.0), "radius": 9.0, "ramp_open": 0.85, "hook": (0, 0.6, 0.9), "cargo": True, "heavy_lift": True})


FAMILIES = {"cargo_ch47": cargo_ch47, "cargo_mi26": cargo_mi26}
