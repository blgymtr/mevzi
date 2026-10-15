# Ulusa özel piyade silahları (Blender, gerçek ölçü). Çıktı: assets/models/weapons_<usa|rus>.glb
# düğümler: rifle, mg, rpg, sniper, smg, mortar, tablet, pistol — oyunda Art.skinned() ile okunur.
# Eksen: Blender +Y = namlu (Godot -Z), +Z yukarı; orijin kabza üstü (sağ el), three.js silahlarıyla aynı çerçeve.
# Kullanım: python3 tools/blender/weapons.py <usa|rus> [çıktı.glb]
import bpy, bmesh, sys, os, math
from mathutils import Vector

NAT = sys.argv[1] if len(sys.argv) > 1 else "usa"
USA = NAT == "usa"
ROOT = os.path.abspath(os.path.join(os.path.dirname(__file__), "..", ".."))
OUT = sys.argv[2] if len(sys.argv) > 2 else os.path.join(ROOT, "assets", "models", "weapons_%s.glb" % NAT)

bpy.ops.wm.read_factory_settings(use_empty=True)
MATS = {}
def mat(n):
	if n not in MATS:
		MATS[n] = bpy.data.materials.new(n)
	return MATS[n]

PARTS = []
def _fin(o, m, bev):
	if bev > 0:
		bpy.ops.object.transform_apply(location=False, rotation=False, scale=True)
		b = o.modifiers.new("b", "BEVEL"); b.width = bev; b.segments = 1; b.limit_method = "ANGLE"
	o.data.materials.append(mat(m))
	PARTS.append(o)
	return o

def box(c, s, m="gun", rot=(0, 0, 0), bev=0.002):
	bpy.ops.mesh.primitive_cube_add(location=c, rotation=rot)
	o = bpy.context.active_object
	o.scale = (s[0] / 2, s[1] / 2, s[2] / 2)
	return _fin(o, m, bev)

def cyl(c, r, L, m="gun", seg=12, r2=None, rot=(-math.pi / 2, 0, 0), bev=0.0):
	# varsayılan: ekseni Y (namlu yönü)
	bpy.ops.mesh.primitive_cone_add(vertices=seg, radius1=r, radius2=r if r2 is None else r2, depth=L, location=c, rotation=rot)
	return _fin(bpy.context.active_object, m, bev)

def rail(y0, y1, z, x=0.0, w=0.022, m="gun", side=False):
	# Picatinny ray: taban + diş sırası
	L = y1 - y0
	if side:
		box((x, (y0 + y1) / 2, z), (0.006, L, w), m)
		n = int(L / 0.01)
		for i in range(n):
			box((x + math.copysign(0.004, x), y0 + (i + 0.5) * L / n, z), (0.004, 0.005, w * 0.9), m, bev=0)
	else:
		box((x, (y0 + y1) / 2, z), (w, L, 0.006), m)
		n = int(L / 0.01)
		for i in range(n):
			box((x, y0 + (i + 0.5) * L / n, z + 0.005), (w * 0.95, 0.005, 0.004), m, bev=0)

def curved_mag(y, z, w, rows, m="gun", tilt=0.15, step=0.04, curve=0.06):
	# kavisli şarjör: öne kıvrılan, üst üste binen kademeler (boşluksuz)
	py, pz, a = y, z, tilt
	for i in range(rows):
		box((0, py, pz), (w, 0.058, step * 1.45), m, rot=(-a, 0, 0), bev=0.002)
		py += step * math.sin(a)
		pz -= step * math.cos(a)
		a += curve
	box((0, py, pz + step * 0.35), (w + 0.004, 0.064, 0.012), "dark", rot=(-a, 0, 0))

def grip(y, z, m="dark", ang=0.3):
	box((0, y, z), (0.03, 0.04, 0.085), m, rot=(ang, 0, 0), bev=0.006)

def red_dot(y, z, m="dark"):
	box((0, y, z), (0.03, 0.05, 0.012), m)
	cyl((0, y, z + 0.032), 0.02, 0.06, m, seg=14)
	cyl((0, y + 0.031, z + 0.032), 0.017, 0.002, "lens", seg=14)

def acog(y, z):
	box((0, y, z), (0.03, 0.06, 0.012), "dark")
	cyl((0, y - 0.02, z + 0.03), 0.018, 0.08, "dark", seg=14)
	cyl((0, y + 0.04, z + 0.03), 0.022, 0.05, "dark", seg=14, r2=0.018)
	cyl((0, y + 0.066, z + 0.03), 0.02, 0.002, "lens", seg=14)
	box((0, y, z + 0.06), (0.01, 0.03, 0.01), "dark")

def scope(y, z, L=0.32):
	box((0, y, z), (0.025, L * 0.55, 0.012), "dark")
	cyl((0, y, z + 0.035), 0.016, L * 0.62, "dark", seg=14)
	cyl((0, y + L * 0.38, z + 0.035), 0.026, L * 0.18, "dark", seg=14, r2=0.016)
	cyl((0, y - L * 0.36, z + 0.035), 0.02, L * 0.1, "dark", seg=14, r2=0.016)
	cyl((0, y + L * 0.47, z + 0.035), 0.024, 0.002, "lens", seg=14)
	cyl((0, y, z + 0.06), 0.012, 0.02, "dark", seg=10, rot=(0, 0, 0))
	cyl((0.022, y, z + 0.035), 0.012, 0.02, "dark", seg=10, rot=(0, math.pi / 2, 0))

def bipod(y, z, L=0.22, spread=0.3, folded=False):
	box((0, y, z), (0.03, 0.03, 0.02), "gun")
	for s in (-1, 1):
		if folded:
			cyl((s * 0.014, y - L / 2, z - 0.01), 0.005, L, "gun", seg=6)
		else:
			o = cyl((s * 0.03, y + 0.02, z - L / 2), 0.005, L, "gun", seg=6, rot=(0.25, s * spread, 0))

def finish(name):
	global PARTS
	bpy.ops.object.select_all(action="DESELECT")
	for o in PARTS:
		o.select_set(True)
		bpy.context.view_layer.objects.active = o
		for md in list(o.modifiers):
			bpy.ops.object.modifier_apply(modifier=md.name)
	bpy.context.view_layer.objects.active = PARTS[0]
	bpy.ops.object.join()
	o = bpy.context.active_object
	o.name = name
	o.data.name = name
	bpy.ops.object.transform_apply(location=False, rotation=True, scale=True)
	PARTS = []
	return o

FUR = "canvas" if USA else "dark"   # mobilya: ABD toprak rengi (FDE) polimer, Rus siyah polimer

# ================================================================ tüfek
if USA:
	# M4A1 (SOPMOD): üst/alt gövde, M-LOK el kundağı, CTR dipçik, ACOG, PEQ-15, dikey tutamak
	box((0, 0.05, 0.03), (0.03, 0.2, 0.045), "gun", bev=0.003)                      # üst gövde
	box((0, 0.03, -0.008), (0.028, 0.16, 0.035), "gun", bev=0.003)                  # alt gövde
	box((0.016, 0.07, 0.03), (0.004, 0.06, 0.02), "dark")                           # atım penceresi
	box((-0.012, -0.03, 0.045), (0.02, 0.03, 0.01), "gun")                          # kurma kolu
	rail(-0.04, 0.15, 0.056)
	box((0, 0.3, 0.03), (0.042, 0.3, 0.046), FUR, bev=0.006)                        # el kundağı
	for i in range(5):
		for s in (-1, 1):
			box((s * 0.021, 0.19 + i * 0.05, 0.03), (0.003, 0.03, 0.01), "dark", bev=0)  # M-LOK yuvası
	rail(0.16, 0.44, 0.056)
	cyl((0, 0.55, 0.033), 0.008, 0.22, "gun", seg=10)                               # namlu
	cyl((0, 0.47, 0.033), 0.011, 0.03, "gun", seg=10)                               # gaz bloğu
	cyl((0, 0.68, 0.033), 0.011, 0.05, "dark", seg=10)                              # alev gizleyici
	curved_mag(0.075, -0.03, 0.022, 4, "canvas" if True else "gun", tilt=0.1, step=0.038, curve=0.07)
	box((0, 0.072, -0.03), (0.026, 0.07, 0.03), "gun")                              # şarjör yuvası
	grip(-0.01, -0.06, FUR)
	box((0, 0.045, -0.03), (0.006, 0.05, 0.004), "gun")                             # tetik korkuluğu
	cyl((0, -0.13, 0.03), 0.015, 0.17, "dark", seg=12)                              # tampon borusu
	box((0, -0.21, 0.015), (0.04, 0.1, 0.07), FUR, bev=0.008)                       # CTR dipçik
	box((0, -0.255, 0.01), (0.042, 0.012, 0.08), "dark", bev=0.003)                 # dipçik pedi
	acog(0.06, 0.062)
	box((0.028, 0.36, 0.05), (0.03, 0.07, 0.028), "canvas", bev=0.004)              # PEQ-15
	cyl((0.028, 0.4, 0.052), 0.007, 0.01, "lens", seg=8)
	box((0, 0.33, -0.015), (0.025, 0.028, 0.07), "dark", rot=(0.15, 0, 0), bev=0.005)  # dikey tutamak
	cyl((-0.026, 0.36, 0.03), 0.012, 0.07, "dark", seg=10)                          # el feneri
else:
	# AK-12: toz kapağı üstünde ray, ray'li el kundağı, gaz tüpü, namlu freni, kavisli şarjör, katlanır dipçik, kolimatör
	box((0, 0.04, 0.02), (0.034, 0.24, 0.05), "gun", bev=0.003)                     # gövde
	box((0, 0.03, 0.05), (0.032, 0.2, 0.012), "gun", bev=0.004)                     # toz kapağı
	rail(-0.04, 0.14, 0.058)
	box((0.018, 0.06, 0.03), (0.004, 0.08, 0.008), "gun")                           # emniyet kolu
	box((0, 0.27, 0.02), (0.044, 0.2, 0.05), "dark", bev=0.006)                     # el kundağı
	rail(0.18, 0.36, 0.047)
	for s in (-1, 1):
		rail(0.2, 0.34, 0.02, x=s * 0.024, w=0.016, side=True)
	cyl((0, 0.28, 0.06), 0.009, 0.2, "gun", seg=10)                                 # gaz tüpü
	cyl((0, 0.5, 0.025), 0.008, 0.26, "gun", seg=10)                                # namlu
	cyl((0, 0.65, 0.025), 0.012, 0.06, "gun", seg=10)                               # namlu freni
	for i in range(3):
		box((0, 0.635 + i * 0.015, 0.037), (0.006, 0.004, 0.006), "dark", bev=0)
	curved_mag(0.11, -0.02, 0.026, 5, "dark", tilt=0.2, step=0.04, curve=0.1)
	grip(-0.01, -0.05, "dark")
	box((0, 0.04, -0.025), (0.006, 0.05, 0.004), "gun")
	box((0, -0.17, 0.0), (0.035, 0.22, 0.04), "dark", bev=0.006)                     # dipçik
	box((0, -0.2, -0.03), (0.03, 0.12, 0.03), "dark", rot=(0.25, 0, 0), bev=0.005)
	box((0, -0.28, -0.005), (0.037, 0.012, 0.09), "dark", bev=0.003)
	red_dot(0.06, 0.064)
finish("rifle")

# ================================================================ makineli tüfek
if USA:
	# M249: gövde, ısı kalkanı, taşıma kolu, bipod, 200'lük kumaş fişeklik, iskelet dipçik
	box((0, 0.06, 0.02), (0.06, 0.32, 0.075), "gun", bev=0.004)
	box((0, 0.06, 0.065), (0.055, 0.16, 0.015), "gun", bev=0.004)                   # besleme kapağı
	rail(-0.02, 0.18, 0.074)
	cyl((0, 0.42, 0.03), 0.012, 0.42, "gun", seg=10)
	box((0, 0.32, 0.055), (0.04, 0.22, 0.012), "dark", bev=0.003)                   # ısı kalkanı
	box((0, 0.3, 0.09), (0.012, 0.1, 0.05), "dark", bev=0.004)                      # taşıma kolu
	cyl((0, 0.65, 0.03), 0.016, 0.06, "dark", seg=10)
	box((0.07, 0.04, -0.06), (0.1, 0.12, 0.12), "canvas", bev=0.015)                # fişeklik
	for k in range(6):
		box((0.035, 0.02 + k * 0.012, 0.0), (0.012, 0.008, 0.02), "gun", rot=(0, 0.6, 0), bev=0)   # fişek şeridi
	grip(-0.04, -0.06, "dark")
	box((0, -0.2, 0.0), (0.04, 0.2, 0.06), "dark", bev=0.008)
	box((0, -0.3, -0.005), (0.045, 0.015, 0.09), "dark")
	bipod(0.5, 0.0, L=0.26)
	red_dot(0.04, 0.08)
else:
	# PKP Pecheneg: soğutma gömleği, namlu ucunda bipod, 100'lük kutu, iskelet dipçik
	box((0, 0.05, 0.02), (0.055, 0.3, 0.075), "gun", bev=0.004)
	box((0, 0.05, 0.063), (0.05, 0.18, 0.012), "gun", bev=0.004)
	rail(-0.02, 0.16, 0.07)
	cyl((0, 0.38, 0.03), 0.026, 0.32, "gun", seg=14)                                 # soğutma gömleği
	for i in range(8):
		cyl((0, 0.24 + i * 0.035, 0.03), 0.028, 0.006, "dark", seg=14)              # gömlek kanalları
	cyl((0, 0.6, 0.03), 0.012, 0.14, "gun", seg=10)
	cyl((0, 0.68, 0.03), 0.018, 0.04, "dark", seg=10)
	box((0.065, 0.02, -0.07), (0.07, 0.13, 0.13), "pack", bev=0.008)                 # 100'lük kutu
	box((0.065, 0.02, -0.003), (0.072, 0.135, 0.008), "gun")
	grip(-0.04, -0.06, "dark")
	box((0, -0.2, -0.005), (0.035, 0.22, 0.05), "dark", bev=0.008)
	box((0, -0.18, -0.04), (0.03, 0.16, 0.012), "dark")
	bipod(0.6, 0.0, L=0.26)
	box((0, 0.2, 0.09), (0.015, 0.08, 0.04), "gun", bev=0.004)                       # taşıma kolu
finish("mg")

# ================================================================ tanksavar
if USA:
	# AT4: kompozit tüp, uç kapakları, nişangâh kapağı, tetik grubu, omuz pedi
	cyl((0, 0.1, 0.0), 0.042, 1.02, "canvas", seg=18)
	cyl((0, -0.42, 0.0), 0.05, 0.06, "dark", seg=18)                                 # arka koni
	cyl((0, 0.62, 0.0), 0.047, 0.04, "dark", seg=18)
	for y in (-0.2, 0.1, 0.4):
		cyl((0, y, 0.0), 0.044, 0.012, "dark", seg=18)                               # kayış bilezikleri
	box((0, 0.12, 0.05), (0.03, 0.08, 0.02), "dark", bev=0.004)                      # nişangâh
	box((0, 0.0, -0.06), (0.03, 0.1, 0.04), "dark", bev=0.006)                       # tetik grubu
	box((0, -0.12, -0.04), (0.04, 0.08, 0.025), "dark", bev=0.006)                   # omuz pedi
	box((-0.048, -0.05, 0.0), (0.006, 0.6, 0.02), "dark")                            # kayış
else:
	# RPG-7: çelik tüp, ahşap ısı kalkanı, PGO-7 optik, iki kabza, arka koni, PG-7V harp başlığı
	cyl((0, 0.1, 0.0), 0.022, 0.95, "gun", seg=14)
	cyl((0, 0.0, 0.0), 0.034, 0.26, "wood", seg=14)                                  # ahşap kalkan
	cyl((0, -0.44, 0.0), 0.034, 0.14, "gun", seg=14, r2=0.026)                       # arka koni
	cyl((0, 0.53, 0.0), 0.026, 0.04, "gun", seg=14)
	box((0, 0.0, -0.055), (0.03, 0.04, 0.08), "wood", rot=(0.25, 0, 0), bev=0.005)   # arka kabza
	box((0, 0.16, -0.055), (0.03, 0.04, 0.08), "wood", rot=(0.25, 0, 0), bev=0.005)  # ön kabza
	box((-0.04, 0.03, 0.04), (0.02, 0.1, 0.03), "dark", bev=0.004)                   # PGO-7
	cyl((-0.04, 0.09, 0.045), 0.012, 0.04, "dark", seg=10)
	# PG-7V: harp başlığı (koni + gövde + kanatçık)
	cyl((0, 0.66, 0.0), 0.04, 0.12, "pack", seg=16, r2=0.034)
	cyl((0, 0.77, 0.0), 0.034, 0.1, "pack", seg=16, r2=0.008)
	cyl((0, 0.83, 0.0), 0.005, 0.03, "gun", seg=8)
finish("rpg")

# ================================================================ keskin nişancı
if USA:
	# M110 SASS: uzun AR-10, susturucu, dürbün, bipod
	box((0, 0.05, 0.03), (0.034, 0.24, 0.05), "gun", bev=0.003)
	box((0, 0.03, -0.008), (0.032, 0.18, 0.04), "gun", bev=0.003)
	rail(-0.06, 0.48, 0.058)
	box((0, 0.36, 0.03), (0.046, 0.36, 0.05), FUR, bev=0.006)
	cyl((0, 0.66, 0.033), 0.009, 0.26, "gun", seg=10)
	cyl((0, 0.86, 0.033), 0.019, 0.2, "dark", seg=14)                                # susturucu
	box((0, 0.09, -0.04), (0.026, 0.06, 0.08), "gun", bev=0.003)                     # 20'lik şarjör
	grip(-0.02, -0.06, FUR)
	cyl((0, -0.14, 0.03), 0.016, 0.18, "dark", seg=12)
	box((0, -0.23, 0.01), (0.042, 0.12, 0.075), FUR, bev=0.008)
	scope(0.1, 0.064, 0.34)
	bipod(0.42, 0.0, L=0.22, folded=True)
else:
	# SV-98: sürgülü, tam boy kundak, susturucu, dürbün, bipod
	box((0, 0.05, 0.02), (0.032, 0.24, 0.04), "gun", bev=0.003)
	box((0.022, 0.0, 0.03), (0.04, 0.012, 0.012), "gun", bev=0.003)                 # sürgü kolu
	box((0, 0.2, 0.0), (0.05, 0.5, 0.05), "dark", bev=0.008)                         # kundak
	box((0, -0.22, -0.01), (0.045, 0.24, 0.085), "dark", bev=0.01)
	box((0, -0.15, -0.06), (0.03, 0.06, 0.06), "dark", rot=(0.4, 0, 0), bev=0.006)   # kabza boynu
	cyl((0, 0.58, 0.025), 0.01, 0.34, "gun", seg=10)
	cyl((0, 0.8, 0.025), 0.02, 0.14, "dark", seg=14)
	box((0, 0.1, -0.035), (0.024, 0.06, 0.05), "gun")
	scope(0.08, 0.06, 0.34)
	bipod(0.38, -0.02, L=0.22, folded=True)
finish("sniper")

# ================================================================ kısa tüfek (istihkâm / mürettebat)
if USA:
	box((0, 0.05, 0.03), (0.03, 0.2, 0.045), "gun", bev=0.003)
	box((0, 0.03, -0.008), (0.028, 0.16, 0.035), "gun", bev=0.003)
	rail(-0.04, 0.3, 0.056)
	box((0, 0.22, 0.03), (0.042, 0.16, 0.046), FUR, bev=0.006)
	cyl((0, 0.36, 0.033), 0.008, 0.12, "gun", seg=10)
	cyl((0, 0.43, 0.033), 0.011, 0.04, "dark", seg=10)
	curved_mag(0.075, -0.03, 0.022, 4, "canvas", tilt=0.1, step=0.038, curve=0.07)
	grip(-0.01, -0.06, FUR)
	cyl((0, -0.12, 0.03), 0.015, 0.15, "dark", seg=12)
	box((0, -0.19, 0.015), (0.04, 0.09, 0.065), FUR, bev=0.008)
	red_dot(0.05, 0.062)
else:
	box((0, 0.04, 0.02), (0.034, 0.22, 0.05), "gun", bev=0.003)
	box((0, 0.03, 0.05), (0.032, 0.18, 0.012), "gun", bev=0.004)
	box((0, 0.22, 0.02), (0.044, 0.14, 0.05), "dark", bev=0.006)
	cyl((0, 0.34, 0.025), 0.008, 0.12, "gun", seg=10)
	cyl((0, 0.41, 0.025), 0.014, 0.05, "gun", seg=10)
	curved_mag(0.1, -0.02, 0.026, 5, "dark", tilt=0.2, step=0.04, curve=0.1)
	grip(-0.01, -0.05, "dark")
	box((0, -0.12, 0.0), (0.03, 0.14, 0.035), "dark", bev=0.006)
	red_dot(0.05, 0.062)
finish("smg")

# ================================================================ havan (60 mm, taşıma pozisyonu)
cyl((0, -0.3 + 0.45, 0.0), 0.034, 0.9, "gun", seg=16)
cyl((0, 0.58, 0.0), 0.038, 0.03, "gun", seg=16)
cyl((0, -0.32, 0.0), 0.04, 0.06, "gun", seg=16)
box((0, -0.36, 0.0), (0.26, 0.04, 0.2), "gun", bev=0.01)                            # taban levhası
for s in (-1, 1):
	cyl((s * 0.05, 0.25, -0.05), 0.008, 0.4, "gun", seg=6, rot=(-math.pi / 2 + 0.1, s * 0.15, 0))   # katlı bipod
box((0.05, 0.05, 0.04), (0.04, 0.06, 0.05), "dark", bev=0.006)                       # nişangâh
box((-0.045, 0.1, 0.0), (0.012, 0.25, 0.03), "dark")                                 # kayış
finish("mortar")

# ================================================================ drone kumandası (sağlam tablet + iki çubuk + anten)
box((0, -0.05, 0.0), (0.26, 0.17, 0.035), "dark", bev=0.008)
box((0, -0.05, 0.019), (0.18, 0.11, 0.003), "lens")
for s in (-1, 1):
	cyl((s * 0.105, -0.07, 0.03), 0.012, 0.03, "gun", seg=10, rot=(0, 0, 0))
	box((s * 0.12, 0.04, 0.0), (0.03, 0.03, 0.05), "dark", bev=0.005)
cyl((0.11, 0.07, 0.07), 0.004, 0.14, "dark", seg=6, rot=(0, 0, 0))
finish("tablet")

# ================================================================ tabanca (M17 / PL-15)
box((0, 0.04, 0.03), (0.029, 0.19, 0.03), "canvas" if USA else "gun", bev=0.004)     # sürgü
box((0, 0.03, 0.002), (0.027, 0.15, 0.028), "dark", bev=0.004)                       # gövde
box((0, -0.035, -0.045), (0.027, 0.045, 0.095), "dark", rot=(0.22, 0, 0), bev=0.006) # kabza
box((0, 0.025, -0.02), (0.006, 0.04, 0.004), "dark")                                  # tetik korkuluğu
cyl((0, 0.14, 0.03), 0.006, 0.01, "dark", seg=8)                                      # namlu ağzı
finish("pistol")

for o in bpy.data.objects:
	o.select_set(True)
print("WEAPONS", NAT, sum(len(o.data.polygons) for o in bpy.data.objects if o.type == "MESH"))
bpy.ops.export_scene.gltf(filepath=OUT, export_format="GLB", export_yup=True, export_apply=True)
print("OK", OUT)
