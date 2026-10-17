# İHA ve dolanan mühimmat aileleri (Roadmap 10 / 91 / 93): kesitlerden örülen (loft) pürüzsüz gövdeler, gerçek
# boyutlar (data/real_dims.json), türe özgü düzen — MQ-9 Y kuyruk + sırt uydu çıkıntısı, MQ-1C ters V kuyruk,
# Orion V kuyruk, Forpost / RQ-7 çift kuyruk kirişi, RQ-4 sırt turbofan + V kuyruk, Orlan / ZALA / Eleron;
# itici pervaneler ayrı düğümde (oyunda döner). Boya: açık gri hava aracı boyası ("airgray"), kamuflaj değil.
# Eksenler: +X sağ, +Y ileri (burun), Z yukarı. Türü katalogdaki v["type"] seçer.
import math
import vlib
from vlib import *
from fam_heli import tube, wing, fin

G = "airgray"


def sensor_ball(x, y, z, r, windows=2):
    """EO/IR sensör küresi (MTS-B, ...): boyun + küre + ön camlar"""
    cyl((x, y, z + r * 0.9), r * 0.55, r * 0.5, G, "Z", seg=12)
    cyl((x, y, z), r, r * 1.5, G, "Z", seg=16, bev=0.0)
    for k in range(windows):
        cyl((x + (k - (windows - 1) * 0.5) * r * 0.7, y + r * 0.92, z - r * 0.1), r * 0.26, 0.04, "glass", "Y", seg=10)


def atgm_rack(x, y, z, n=2, L=1.63, r=0.09, rail_w=0.32):
    """Hellfire rafı (M299): ray + n füze (koyu gövde, burun arayıcısı, kuyruk kanatçıkları)"""
    box((x, y, z + r + 0.04), (0.08, L * 0.75, 0.06), "dark", bev=0.0)
    for i in range(n):
        xx = x + ((i - (n - 1) * 0.5) * rail_w * 0.6 if n > 1 else 0.0)
        cyl((xx, y, z), r, L * 0.86, "gun", "Y", seg=10)
        cyl((xx, y + L * 0.5, z), r * 0.35, L * 0.14, "dark", "Y", seg=10, r2=r)     # Y ekseninde r1 +Y ucunda
        for k in range(4):
            a = k * math.tau / 4 + math.pi / 4
            box((xx + math.cos(a) * r * 1.4, y - L * 0.4, z + math.sin(a) * r * 1.4), (0.012, 0.16, 0.012), "gun", rot=(0, a, 0), bev=0.0)


def prop(x, y, z, r, n=3, axis="Y", hub=0.06):
    # pervane ayrı düğümde (oyunda döner — roadmap 8): propy_N (ileri eksen, itici) / propz_N (dikey)
    prev = vlib.CUR
    name = "prop%s_%d" % (axis.lower(), len([k for k in vlib.EXTRA_PIVOTS if k.startswith("prop")]))
    vlib.node(name)
    vlib.EXTRA_PIVOTS[name] = (x, y, z)
    cyl((x, y, z), hub * 1.6, hub * 2.2, "dark", axis, seg=10)
    for k in range(n):
        a = k * math.tau / n
        if axis == "Y":
            # kanat profili gibi bükük, uca doğru incelen pal
            box((x + math.cos(a) * r * 0.5, y, z + math.sin(a) * r * 0.5), (r * 0.98, 0.025, r * 0.11), "dark", rot=(0, -a, 0), bev=0.0)
        else:
            box((x + math.cos(a) * r * 0.5, y + math.sin(a) * r * 0.5, z), (r, r * 0.1, 0.02), "dark", rot=(0, 0, a), bev=0.0)
    vlib.node(prev)


def _vtail(y, z, span, c0, c1, ang, t=0.07, inverted=False, sweep=0.35):
    """V / ters V kuyruk: iki yüzey, yataydan 'ang' derece (ters V'de aşağı)"""
    s = -1.0 if inverted else 1.0
    for sd in (-1, 1):
        x1 = sd * span * math.cos(math.radians(ang))
        z1 = z + s * span * math.sin(math.radians(ang))
        wing(sd * 0.05, x1, y, y - sweep, z, z1, c0, c1, t, t * 0.6, G)


def _bomb(x, y, z, L, r, m=G):
    """güdümlü bomba (GBU-12 / KAB): (x, y, z) merkezli L boyunda — gövde, burun arayıcı kafası, kuyruk kanatçıkları"""
    cyl((x, y - L * 0.1, z), r, L * 0.8, m, "Y", seg=10)
    cyl((x, y + L * 0.4, z), r * 0.4, L * 0.2, "dark", "Y", seg=10, r2=r * 0.8)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        box((x + math.cos(a) * r * 1.3, y - L * 0.42, z + math.sin(a) * r * 1.3), (r * 1.2, L * 0.12, 0.01), m, rot=(0, -a, 0), bev=0.0)


def _pylon(x, y, z_top, z_bot, chord=0.5):
    box((x, y, (z_top + z_bot) * 0.5), (0.06, chord, z_top - z_bot), G, bev=0.004)


def _antenna(x, y, z, h, down=False):
    box((x, y, z + (-h if down else h) * 0.5), (0.015, 0.12, h), "dark", rot=(0.35 if not down else -0.35, 0, 0), bev=0.0)


# ---------------------------------------------------------------- orta irtifa (MALE)
def _mq9():
    # MQ-9A Reaper: L 11,0 · W 20,1 · H 3,8 (kuyruk dahil). Gövde ekseni z≈1,2 (gövde altı ~0,7)
    zc = 1.2
    tube([(5.5, 0, zc - 0.05, 0.05, 0.05, 0.05, 2.0),
          (5.25, 0, zc - 0.02, 0.3, 0.32, 0.26, 2.0),
          (4.7, 0, zc + 0.05, 0.5, 0.56, 0.42, 2.2),
          (3.9, 0, zc + 0.08, 0.56, 0.66, 0.46, 2.2),      # uydu anteni çıkıntısı (sırt şişkinliği)
          (2.9, 0, zc + 0.02, 0.55, 0.52, 0.46, 2.3),
          (1.2, 0, zc, 0.52, 0.46, 0.45, 2.3),
          (-1.2, 0, zc + 0.02, 0.45, 0.4, 0.38, 2.2),
          (-3.4, 0, zc + 0.06, 0.33, 0.3, 0.27, 2.1),
          (-4.8, 0, zc + 0.08, 0.2, 0.2, 0.17, 2.0),
          (-5.15, 0, zc + 0.08, 0.1, 0.1, 0.1, 2.0)], G, n=20)
    # kanat: düz, yüksek açıklık oranı, hafif uç daralması ve dihedral
    for sd in (-1, 1):
        wing(sd * 0.4, sd * 10.05, 0.55, 0.35, zc + 0.12, zc + 0.42, 1.35, 0.62, 0.22, 0.08, G, n=12)
        box((sd * 10.0, 0.3, zc + 0.42), (0.05, 0.5, 0.06), "dark", bev=0.0)                 # uç lambası
    # Y kuyruk: iki üst yüzey (~45°) + karın dikmesi
    _vtail(-4.35, zc + 0.15, 2.45, 1.05, 0.55, 45.0, 0.1)
    fin(-4.2, -4.25, zc - 0.2, zc - 1.05, 0.25, 0.9, 0.5, 0.08, 0.0, G)
    # itici pervane (3 pal), egzoz, hava girişleri
    prop(0, -5.3, zc + 0.08, 1.15, 3, "Y", hub=0.1)
    for sd in (-1, 1):
        box((sd * 0.38, -3.6, zc + 0.28), (0.12, 0.6, 0.12), "dark", bev=0.01)               # egzoz çıkışı
        box((sd * 0.46, -1.0, zc + 0.22), (0.06, 0.5, 0.18), "dark", bev=0.008)              # yan hava girişi
    box((0, -2.0, zc + 0.42), (0.28, 0.9, 0.08), "dark", bev=0.01)                           # sırt girişi
    # MTS-B sensör küresi (burun altı), SAR anteni çıkıntısı
    sensor_ball(0, 3.9, zc - 0.62, 0.3)
    box((0, 1.6, zc - 0.48), (0.5, 1.1, 0.12), G, bev=0.02)
    # silah istasyonları: iç pilonda GBU-12, orta pilonda 2'li Hellfire rafı
    for sd in (-1, 1):
        _pylon(sd * 2.3, 0.55, zc + 0.05, zc - 0.25)
        _bomb(sd * 2.3, 0.6, zc - 0.42, 3.3, 0.14)
        _pylon(sd * 3.9, 0.5, zc + 0.08, zc - 0.2)
        atgm_rack(sd * 3.9, 0.55, zc - 0.32, n=2, L=1.63, r=0.09, rail_w=0.32)
    _antenna(0, 2.4, zc + 0.5, 0.35)
    _antenna(0, -0.4, zc - 0.45, 0.3, True)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 1.0, zc - 0.5), "radius": 4.0}


def _mq1c():
    # MQ-1C Gray Eagle: L 8,0 · W 17,0 · H 2,1 — Predator düzeni: ters V kuyruk + karın dikmesi, uydu burnu
    zc = 1.05
    tube([(4.0, 0, zc - 0.05, 0.05, 0.05, 0.05, 2.0),
          (3.75, 0, zc, 0.24, 0.26, 0.22, 2.0),
          (3.2, 0, zc + 0.06, 0.38, 0.44, 0.33, 2.1),
          (2.5, 0, zc + 0.06, 0.42, 0.47, 0.35, 2.1),         # uydu anteni burnu
          (1.4, 0, zc, 0.4, 0.38, 0.36, 2.2),
          (-0.8, 0, zc, 0.34, 0.33, 0.31, 2.2),
          (-2.6, 0, zc + 0.03, 0.24, 0.24, 0.21, 2.0),
          (-3.6, 0, zc + 0.04, 0.14, 0.14, 0.12, 2.0),
          (-3.8, 0, zc + 0.04, 0.07, 0.07, 0.07, 2.0)], G, n=18)
    for sd in (-1, 1):
        wing(sd * 0.3, sd * 8.5, 0.35, 0.2, zc + 0.08, zc + 0.3, 1.05, 0.5, 0.16, 0.06, G, n=12)
    _vtail(-3.1, zc - 0.05, 1.7, 0.8, 0.45, 40.0, 0.07, inverted=True)
    fin(-3.0, -3.05, zc - 0.15, zc - 0.85, 0.2, 0.6, 0.35, 0.05, 0.0, G)
    prop(0, -3.95, zc + 0.04, 0.95, 3, "Y", hub=0.08)
    sensor_ball(0, 2.7, zc - 0.48, 0.24)
    for sd in (-1, 1):
        for k, x in enumerate((2.2, 3.6)):
            _pylon(sd * x, 0.35, zc + 0.04, zc - 0.18)
            atgm_rack(sd * x, 0.4, zc - 0.28, n=1 if k == 1 else 2, L=1.63, r=0.09, rail_w=0.25)
        box((sd * 0.3, -2.4, zc + 0.12), (0.08, 0.4, 0.08), "dark", bev=0.0)                # egzoz
    _antenna(0, 1.6, zc + 0.36, 0.3)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0.6, zc - 0.4), "radius": 3.4}


def _orion():
    # Kronshtadt Orion: L 8,0 · W 16,3 · H 2,2 — ince gövde, sırt uydu çıkıntısı, V kuyruk, itici pervane
    zc = 1.0
    tube([(4.0, 0, zc - 0.03, 0.05, 0.05, 0.05, 2.0),
          (3.7, 0, zc, 0.26, 0.28, 0.24, 2.0),
          (3.0, 0, zc + 0.05, 0.42, 0.5, 0.36, 2.2),
          (2.0, 0, zc + 0.04, 0.44, 0.48, 0.38, 2.3),
          (0.6, 0, zc, 0.42, 0.42, 0.38, 2.3),
          (-1.4, 0, zc + 0.02, 0.33, 0.33, 0.3, 2.2),
          (-3.0, 0, zc + 0.04, 0.2, 0.2, 0.18, 2.0),
          (-3.75, 0, zc + 0.04, 0.09, 0.09, 0.09, 2.0)], G, n=18)
    for sd in (-1, 1):
        wing(sd * 0.32, sd * 8.15, 0.45, 0.3, zc + 0.1, zc + 0.3, 1.15, 0.55, 0.17, 0.07, G, n=12)
    _vtail(-3.05, zc + 0.12, 1.9, 0.85, 0.45, 38.0, 0.07)
    prop(0, -3.9, zc + 0.04, 1.0, 3, "Y", hub=0.08)
    sensor_ball(0, 2.6, zc - 0.48, 0.26)
    for sd in (-1, 1):
        _pylon(sd * 2.1, 0.45, zc + 0.06, zc - 0.18)
        _bomb(sd * 2.1, 0.5, zc - 0.34, 1.6, 0.11)                                         # KAB-20 / Kh-BPLA
        _pylon(sd * 3.4, 0.4, zc + 0.08, zc - 0.14)
        _bomb(sd * 3.4, 0.45, zc - 0.3, 1.2, 0.09)
    _antenna(0, 1.1, zc + 0.42, 0.28)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0.6, zc - 0.35), "radius": 3.4}


def _forpost():
    # Forpost-R (Searcher Mk II): L 5,85 · W 8,55 · H 1,25 — kısa gövde, yüksek kanat, çift kiriş, H kuyruk
    zc = 0.75
    tube([(2.2, 0, zc - 0.02, 0.05, 0.05, 0.05, 2.0),
          (2.0, 0, zc, 0.22, 0.24, 0.2, 2.0),
          (1.4, 0, zc + 0.04, 0.34, 0.38, 0.3, 2.3),
          (0.2, 0, zc + 0.04, 0.36, 0.38, 0.32, 2.4),
          (-0.9, 0, zc + 0.06, 0.28, 0.3, 0.24, 2.2),
          (-1.35, 0, zc + 0.06, 0.12, 0.12, 0.12, 2.0)], G, n=16)
    for sd in (-1, 1):
        wing(sd * 0.3, sd * 4.27, 0.2, 0.12, zc + 0.38, zc + 0.5, 0.8, 0.5, 0.12, 0.05, G, n=10)
        # kuyruk kirişleri ve dikmeler
        tube([(0.0, sd * 1.05, zc + 0.36, 0.05, 0.05, 0.05, 2.0), (-3.4, sd * 1.05, zc + 0.3, 0.04, 0.04, 0.04, 2.0)], G, n=8)
        fin(-3.0, -3.1, zc + 0.3, zc + 0.95, 0.15, 0.55, 0.38, 0.04, sd * 1.05, G)
    wing(-1.05, 1.05, -3.25, -3.3, zc + 0.62, zc + 0.62, 0.42, 0.42, 0.05, 0.05, G, n=8)      # yatay kuyruk
    prop(0, -1.45, zc + 0.06, 0.65, 2, "Y", hub=0.06)
    sensor_ball(0, 1.0, zc - 0.36, 0.2)
    for sd in (-1, 1):
        box((sd * 0.25, 0.9, zc - 0.32), (0.03, 0.03, 0.4), "dark", bev=0.0)                 # sabit iniş takımı
        cyl((sd * 0.25, 0.9, zc - 0.52), 0.08, 0.05, "rubber", "X", seg=10)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0.5, zc - 0.3), "radius": 2.6}


def uav_male(v):
    t = v.get("type", "mq9" if v.get("big") else "mq1c")
    return {"mq9": _mq9, "mq1c": _mq1c, "orion": _orion, "forpost": _forpost}.get(t, _mq9)()


# ---------------------------------------------------------------- yüksek irtifa (HALE)
def uav_hale(v):
    # RQ-4 Global Hawk: L 14,5 · W 39,9 · H 4,7 — iri uydu burnu, sırtta turbofan, V kuyruk
    zc = 1.6
    tube([(7.25, 0, zc - 0.1, 0.06, 0.06, 0.06, 2.0),
          (6.9, 0, zc + 0.02, 0.5, 0.55, 0.45, 2.0),
          (6.1, 0, zc + 0.18, 0.78, 0.9, 0.62, 2.1),        # uydu anteni burnu (kambur)
          (4.8, 0, zc + 0.15, 0.8, 0.86, 0.66, 2.2),
          (2.8, 0, zc + 0.05, 0.72, 0.66, 0.62, 2.3),
          (0.0, 0, zc, 0.66, 0.6, 0.58, 2.3),
          (-3.5, 0, zc + 0.05, 0.52, 0.5, 0.45, 2.2),
          (-6.4, 0, zc + 0.12, 0.3, 0.3, 0.26, 2.0),
          (-7.25, 0, zc + 0.14, 0.12, 0.12, 0.12, 2.0)], G, n=22)
    for sd in (-1, 1):
        wing(sd * 0.6, sd * 19.95, 0.2, -0.4, zc + 0.35, zc + 0.95, 1.95, 0.75, 0.32, 0.1, G, n=12)
    # sırt motoru (Rolls-Royce AE 3007H): giriş ağzı, nasel, çıkış
    tube([(-1.8, 0, zc + 0.95, 0.32, 0.3, 0.3, 2.0), (-2.3, 0, zc + 0.98, 0.48, 0.42, 0.4, 2.0),
          (-4.6, 0, zc + 1.0, 0.5, 0.42, 0.4, 2.0), (-6.0, 0, zc + 0.92, 0.36, 0.3, 0.3, 2.0)], G, n=16)
    cyl((0, -1.8, zc + 0.95), 0.27, 0.06, "dark", "Y", seg=16)
    cyl((0, -6.05, zc + 0.92), 0.3, 0.05, "dark", "Y", seg=16)
    _vtail(-6.0, zc + 0.6, 3.6, 1.6, 0.8, 50.0, 0.12)
    sensor_ball(0, 5.0, zc - 0.62, 0.32)
    box((0, 1.5, zc - 0.62), (0.9, 2.4, 0.18), G, bev=0.03)                                  # SAR / ISS anteni
    _antenna(0, 3.0, zc + 0.7, 0.5)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 6.0}


# ---------------------------------------------------------------- taktik
def _rq7():
    # RQ-7B Shadow: L 3,4 · W 4,3 · H 1,0 — gövde podu, yüksek kanat, çift kiriş + ters V kuyruk, sabit takım
    zc = 0.55
    tube([(1.15, 0, zc, 0.05, 0.05, 0.05, 2.0), (1.0, 0, zc + 0.02, 0.17, 0.18, 0.15, 2.2),
          (0.3, 0, zc + 0.04, 0.2, 0.22, 0.18, 2.6), (-0.6, 0, zc + 0.04, 0.17, 0.2, 0.15, 2.4),
          (-0.85, 0, zc + 0.04, 0.08, 0.08, 0.08, 2.0)], G, n=14)
    for sd in (-1, 1):
        wing(sd * 0.1, sd * 2.15, 0.05, 0.0, zc + 0.24, zc + 0.3, 0.55, 0.38, 0.07, 0.04, G, n=10)
        tube([(0.0, sd * 0.62, zc + 0.24, 0.03, 0.03, 0.03, 2.0), (-2.0, sd * 0.62, zc + 0.2, 0.025, 0.025, 0.025, 2.0)], G, n=8)
        wing(sd * 0.62, 0.0, -1.95, -2.05, zc + 0.2, zc + 0.48, 0.32, 0.24, 0.03, 0.03, G, n=8)    # ters V yüzeyi
        box((sd * 0.28, 0.65, zc - 0.28), (0.02, 0.02, 0.32), "dark", bev=0.0)
        cyl((sd * 0.28, 0.65, zc - 0.44), 0.07, 0.04, "rubber", "X", seg=10)
    prop(0, -0.92, zc + 0.04, 0.42, 2, "Y", hub=0.04)
    sensor_ball(0, 0.65, zc - 0.22, 0.12)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 2.2}


def _orlan(big=False):
    # Orlan-10 (L 1,8 · W 3,1) / Orlan-30 (L 2,1 · W 3,4): yüksek kanat, itici pervane, kiriş üstünde ters T kuyruk
    k = 1.15 if big else 1.0
    zc = 0.32 * k
    tube([(0.92 * k, 0, zc, 0.04, 0.04, 0.04, 2.0), (0.8 * k, 0, zc + 0.01, 0.1 * k, 0.11 * k, 0.09 * k, 2.2),
          (0.2 * k, 0, zc + 0.02, 0.12 * k, 0.13 * k, 0.11 * k, 2.6), (-0.35 * k, 0, zc + 0.02, 0.09 * k, 0.1 * k, 0.08 * k, 2.3),
          (-0.5 * k, 0, zc + 0.02, 0.04, 0.04, 0.04, 2.0)], G, n=12)
    for sd in (-1, 1):
        wing(sd * 0.08 * k, sd * 1.55 * k, 0.2 * k, 0.12 * k, zc + 0.14 * k, zc + 0.2 * k, 0.32 * k, 0.22 * k, 0.04 * k, 0.025 * k, G, n=8)
    tube([(-0.3 * k, 0, zc + 0.16 * k, 0.025, 0.025, 0.025, 2.0), (-1.0 * k, 0, zc + 0.16 * k, 0.02, 0.02, 0.02, 2.0)], G, n=6)
    wing(-0.4 * k, 0.4 * k, -0.95 * k, -0.98 * k, zc + 0.16 * k, zc + 0.16 * k, 0.2 * k, 0.2 * k, 0.02, 0.02, G, n=6)
    fin(-0.88 * k, -0.95 * k, zc + 0.16 * k, zc + 0.42 * k, 0.06, 0.2 * k, 0.13 * k, 0.015, 0.0, G)
    prop(0, -0.55 * k, zc + 0.02, 0.24 * k, 2, "Y", hub=0.025)
    sensor_ball(0, 0.45 * k, zc - 0.12 * k, 0.06 * k)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.6}


def uav_tac(v):
    t = v.get("type", "rq7")
    if t == "orlan10":
        return _orlan(False)
    if t == "orlan30":
        return _orlan(True)
    return _rq7()


def uav_hand(v):
    t = v.get("type", "raven")
    zc = 0.15
    if t in ("zala", "eleron"):
        # uçan kanat (ZALA 421-16E W 2,8 / Eleron-3 W 1,47): ok açılı kanat, kanat ucu dikmeleri, itici pervane
        span = 1.4 if t == "zala" else 0.735
        root = 0.55 if t == "zala" else 0.36
        tube([(root * 0.6, 0, zc, 0.03, 0.03, 0.03, 2.0), (root * 0.4, 0, zc, 0.07 * span, 0.06 * span, 0.04 * span, 2.4),
              (-root * 0.45, 0, zc + 0.01, 0.06 * span, 0.05 * span, 0.04 * span, 2.2), (-root * 0.6, 0, zc + 0.01, 0.02, 0.02, 0.02, 2.0)], G, n=12)
        for sd in (-1, 1):
            wing(sd * 0.05, sd * span, 0.0, -root * 0.55, zc, zc + 0.03, root, root * 0.42, 0.06 * span, 0.02, G, n=8)
            fin(-root * 0.5, -root * 0.6, zc + 0.03, zc + 0.16 * span, 0.06, root * 0.38, root * 0.25, 0.008, sd * span, G)
        prop(0, -root * 0.66, zc + 0.01, 0.18 * span + 0.05, 2, "Y", hub=0.02)
        return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.2}
    # RQ-11B Raven: L 0,9 · W 1,4 — gövde, direk üstünde yüksek kanat, klasik kuyruk, burunda pervane
    tube([(0.42, 0, zc, 0.03, 0.03, 0.03, 2.0), (0.3, 0, zc, 0.045, 0.05, 0.04, 2.2), (-0.1, 0, zc, 0.04, 0.045, 0.035, 2.2),
          (-0.45, 0, zc + 0.01, 0.015, 0.015, 0.015, 2.0)], G, n=10)
    box((0, 0.08, zc + 0.08), (0.03, 0.14, 0.09), G, bev=0.0)
    for sd in (-1, 1):
        wing(sd * 0.02, sd * 0.7, 0.1, 0.06, zc + 0.12, zc + 0.16, 0.2, 0.14, 0.02, 0.012, G, n=8)
    wing(-0.18, 0.18, -0.38, -0.4, zc + 0.01, zc + 0.01, 0.1, 0.08, 0.008, 0.008, G, n=6)
    fin(-0.36, -0.4, zc + 0.01, zc + 0.12, 0.03, 0.1, 0.07, 0.006, 0.0, G)
    prop(0, 0.44, zc, 0.13, 2, "Y", hub=0.015)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.0}


def uav_vtol(v):
    # V-BAT (kuyruğu üstüne kalkan kanallı fanlı): L 2,74 · W 2,97 — uçuşta yatay; arkada kanal + kanatçıklar
    zc = 0.4
    tube([(1.37, 0, zc, 0.04, 0.04, 0.04, 2.0), (1.1, 0, zc, 0.16, 0.17, 0.15, 2.0), (0.0, 0, zc, 0.2, 0.2, 0.19, 2.2),
          (-0.8, 0, zc, 0.16, 0.16, 0.15, 2.0)], G, n=14)
    for sd in (-1, 1):
        wing(sd * 0.15, sd * 1.48, 0.1, 0.0, zc, zc + 0.04, 0.42, 0.28, 0.05, 0.03, G, n=8)
    tube([(-0.8, 0, zc, 0.38, 0.38, 0.38, 2.0), (-1.37, 0, zc, 0.38, 0.38, 0.38, 2.0)], G, n=20, cap=False)     # kanal
    cyl((0, -1.1, zc), 0.36, 0.05, "dark", "Y", seg=20)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        box((math.cos(a) * 0.4, -1.3, zc + math.sin(a) * 0.4), (0.18, 0.2, 0.012), G, rot=(0, -a, 0), bev=0.0)
    prop(0, -1.0, zc, 0.34, 2, "Y", hub=0.04)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.4}


# ---------------------------------------------------------------- dolanan mühimmat
# Birim başına gerçek boy (L) ve kanat açıklığı (W) katalogdaki v["L"], v["W"]'den (data/real_dims.json ile aynı);
# geometri bunlardan kurulur (sonradan eğri ölçek yok).
def _seeker(L, zc, r):
    cyl((0, L * 0.5 - r * 0.3, zc), r * 0.75, r * 0.5, "glass", "Y", seg=12)


def lm_tube(v):
    t = v.get("type", "sw")
    big = v.get("big")
    L = float(v.get("L", 1.3 if big else 0.61))
    W = float(v.get("W", L * 1.15))
    r = L * 0.065
    zc = r * 1.3
    tube([(L * 0.5, 0, zc, r * 0.35, r * 0.35, r * 0.35, 2.0), (L * 0.43, 0, zc, r, r, r, 2.0),
          (-L * 0.42, 0, zc, r, r, r, 2.0), (-L * 0.5, 0, zc, r * 0.55, r * 0.55, r * 0.55, 2.0)], G, n=12)
    _seeker(L, zc, r)
    if t == "altius":
        # ALTIUS-600/700: sırtta tek, uzun, düz açılır kanat; arkada X kuyruk; itici pervane
        for sd in (-1, 1):
            wing(sd * 0.02, sd * W * 0.5, L * 0.06, L * 0.03, zc + r * 1.05, zc + r * 1.05, L * 0.13, L * 0.09, r * 0.3, r * 0.15, G, n=8)
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            wing(math.cos(a) * r * 0.8, math.cos(a) * r * 3.4, -L * 0.38, -L * 0.43, zc + math.sin(a) * r * 0.8,
                 zc + math.sin(a) * r * 3.4, L * 0.1, L * 0.065, 0.008, 0.005, G, n=6)
        prop(0, -L * 0.53, zc, r * 2.6, 2, "Y", hub=r * 0.4)
    else:
        # Switchblade: ön kanat çifti gövde altında, arka çift üstte (tüpte katlı, açılınca X'e yakın), itici pervane
        for sd in (-1, 1):
            wing(sd * r * 0.3, sd * W * 0.5, L * 0.24, L * 0.19, zc - r * 0.6, zc - r * 0.9, L * 0.11, L * 0.08, 0.008, 0.005, G, n=6)
            wing(sd * r * 0.3, sd * W * 0.46, -L * 0.28, -L * 0.33, zc + r * 0.6, zc + r * 0.9, L * 0.11, L * 0.08, 0.008, 0.005, G, n=6)
        prop(0, -L * 0.53, zc, W * 0.14, 2, "Y", hub=r * 0.4)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": max(0.6, W * 0.5)}


def lm_wing(v):
    t = v.get("type", "x")
    L = float(v.get("L", 1.65))
    W = float(v.get("W", 1.0))
    if t == "flywing":
        # ZALA KUB-BLA: uçan kanat — kalın merkez gövde, geriye ok açılı kanatlar, uçlarda dikme, itici pervane
        zc = L * 0.12
        tube([(L * 0.5, 0, zc, 0.02, 0.02, 0.02, 2.0), (L * 0.36, 0, zc, L * 0.07, L * 0.06, L * 0.05, 2.3),
              (-L * 0.2, 0, zc, L * 0.08, L * 0.065, L * 0.05, 2.4), (-L * 0.46, 0, zc, L * 0.03, L * 0.03, L * 0.03, 2.0)], G, n=14)
        for sd in (-1, 1):
            wing(sd * L * 0.05, sd * W * 0.5, L * 0.12, -L * 0.3, zc, zc + L * 0.02, L * 0.62, L * 0.24, L * 0.05, L * 0.02, G, n=8)
            fin(-L * 0.3, -L * 0.42, zc + L * 0.02, zc + L * 0.16, L * 0.06, L * 0.2, L * 0.12, 0.006, sd * W * 0.49, G)
        prop(0, -L * 0.49, zc, L * 0.12, 2, "Y", hub=0.015)
        return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": max(0.6, W * 0.5)}
    if t == "plane":
        # Molniya-2: ucuz, yüksek kanatlı küçük uçak — kutu gövde, düz kanat, klasik kuyruk, burunda çekici pervane
        zc = L * 0.13
        tube([(L * 0.5, 0, zc, L * 0.04, L * 0.04, L * 0.04, 2.0), (L * 0.42, 0, zc, L * 0.06, L * 0.07, L * 0.06, 3.0),
              (-L * 0.1, 0, zc, L * 0.055, L * 0.06, L * 0.05, 3.0), (-L * 0.48, 0, zc + L * 0.02, L * 0.02, L * 0.02, L * 0.02, 2.0)], G, n=12)
        for sd in (-1, 1):
            wing(sd * L * 0.03, sd * W * 0.5, L * 0.22, L * 0.2, zc + L * 0.08, zc + L * 0.1, L * 0.2, L * 0.16, L * 0.025, L * 0.015, G, n=8)
        wing(-W * 0.17, W * 0.17, -L * 0.4, -L * 0.42, zc + L * 0.02, zc + L * 0.02, L * 0.1, L * 0.08, 0.008, 0.006, G, n=6)
        fin(-L * 0.38, -L * 0.46, zc + L * 0.02, zc + L * 0.16, L * 0.04, L * 0.11, L * 0.07, 0.006, 0.0, G)
        box((0, L * 0.05, zc - L * 0.08), (L * 0.06, L * 0.18, L * 0.04), "dark", bev=0.0)       # savaş başlığı
        prop(0, L * 0.52, zc, W * 0.1, 2, "Y", hub=0.012)
        return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": max(0.6, W * 0.5)}
    # Lancet-3/3M, Red Dragon: uzun silindir gövde, önde ve arkada çapraz (X) kanat takımı, itici pervane
    r = L * 0.045
    zc = W * 0.36
    tube([(L * 0.5, 0, zc, r * 0.3, r * 0.3, r * 0.3, 2.0), (L * 0.4, 0, zc, r, r, r, 2.0),
          (-L * 0.36, 0, zc, r * 0.95, r * 0.95, r * 0.95, 2.0), (-L * 0.48, 0, zc, r * 0.45, r * 0.45, r * 0.45, 2.0)], G, n=12)
    _seeker(L, zc, r)
    for (y, span, ch) in ((L * 0.1, W * 0.5, L * 0.13), (-L * 0.3, W * 0.47, L * 0.11)):
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            wing(math.cos(a) * r * 0.9, math.cos(a) * span, y, y - ch * 0.35, zc + math.sin(a) * r * 0.9, zc + math.sin(a) * span,
                 ch, ch * 0.6, 0.009, 0.006, G, n=6)
    prop(0, -L * 0.5, zc, W * 0.15, 2, "Y", hub=0.015)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": max(0.6, W * 0.5)}


def lm_delta(v):
    # Geran-2 (Shahed-136): L 3,5 · W 2,5 — delta kanat, kanat ucu dikmeleri, itici pervane; koyu boya
    kL = float(v.get("L", 3.5)) / 3.5
    kW = float(v.get("W", 2.5)) / 2.5
    zc = 0.3
    D = "dark"
    tube([(1.75 * kL, 0, zc, 0.03, 0.03, 0.03, 2.0), (1.5 * kL, 0, zc, 0.12, 0.13, 0.11, 2.0), (0.0, 0, zc, 0.17, 0.18, 0.15, 2.3),
          (-1.5 * kL, 0, zc, 0.12, 0.12, 0.11, 2.1), (-1.68 * kL, 0, zc, 0.05, 0.05, 0.05, 2.0)], D, n=14)
    for sd in (-1, 1):
        wing(sd * 0.1, sd * 1.25 * kW, 0.9 * kL, -1.25 * kL, zc, zc + 0.02, 1.9 * kL, 0.45 * kL, 0.1, 0.03, D, n=8)
        fin(-1.0 * kL, -1.25 * kL, zc, zc + 0.42, 0.15, 0.5 * kL, 0.3 * kL, 0.02, sd * 1.22 * kW, D)
    prop(0, -1.74 * kL, zc, 0.38, 2, "Y", hub=0.05)
    return {"body": (0, 0, 0)}, {"muzzle": (0, 0, 0), "radius": 1.6}


FAMILIES = {"uav_male": uav_male, "uav_hale": uav_hale, "uav_tac": uav_tac, "uav_hand": uav_hand, "uav_vtol": uav_vtol,
            "lm_tube": lm_tube, "lm_wing": lm_wing, "lm_delta": lm_delta}
