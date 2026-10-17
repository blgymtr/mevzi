class_name Ballistics extends Node3D
# Mermi dışı atışlar: tank mermisi, otomatik top, roket, el bombası, sis bombası.

class Proj:
	var kind := ""
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var team := 0
	var src = null
	var target = null
	var t := 0.0
	var life := 0.0
	var fuse := 0.0
	var node: Node3D = null
	var smoke := false
	var landed := false
	var sunk := false      # suya düşen el bombası battı
	var trail := 0.0
	var aim := Vector3.ZERO
	var decoy := Vector3.INF      # füze fişeğe kandı: bu noktaya gider
	var big := false
	var spd := 0.0
	var aid := ""          # mühimmat kimliği (data/ammo.json)
	var glow := false      # motor ışığı taşıyor (eşzamanlı ışık sınırı için)
	var guide := ""        # füze güdümü: ir (ateşle-unut), wire (tel), beam (lazer hüzme), sal (lazer işaretleme), radar
	var guide_ok := true   # güdüm sürüyor mu (nişancı bastırıldı / öldü / görüş kesildi / tel bitti → sapar)
	var gchk := 0.0
	var max_r := 0.0
	var launch := Vector3.ZERO
	var wire: MeshInstance3D = null
	var aps_tried := false
	var boost := 0.0       # roketatar: tüp ekseninde hızlanarak çıkış süresi (sn)
	var axis := Vector3.ZERO

var projs: Array = []
var _gmesh: Mesh
var _rmesh: Mesh
var _apfsds_m: Mesh
var _he_m: Mesh
var _atgm_m: Mesh
var _hellfire_m: Mesh
var _vikhr_m: Mesh
var _hydra_m: Mesh
var _sam_m: Mesh
var _flame_m: Mesh
var _flare_m: Mesh
var _blur_m: Mesh       # topçu/havan mermisinin uçuş izi (hareket bulanıklığı)

func _ready() -> void:
	# ileri -Z: look_at(hız) ile uçuş yönüne döner
	var X := Basis(Vector3.RIGHT, -PI * 0.5)
	var mb := MB.new()
	# el bombası (M67/RGD tipi): gövde + kaşık + pim halkası
	mb.sphere(Vector3.ZERO, Vector3(0.032, 0.04, 0.032), 8, 6, Color(0.22, 0.26, 0.18))
	mb.box(Vector3(0.025, 0.035, 0), Vector3(0.012, 0.06, 0.018), Color(0.35, 0.35, 0.33))
	mb.cyl(Vector3(0, 0.05, 0), 0.012, 0.012, 0.02, 6, Color(0.3, 0.3, 0.3))
	_gmesh = mb.commit(Mats.vc())
	# RPG (PG-7 tipi): sivri burun konisi + şişkin harp başlığı + gövde + açılmış kanatçıklar
	var rb := MB.new()
	rb.cyl(Vector3(0, 0, -0.42), 0.0, 0.03, 0.18, 8, Color(0.3, 0.32, 0.24), X)
	rb.cyl(Vector3(0, 0, -0.26), 0.03, 0.045, 0.14, 8, Color(0.34, 0.36, 0.26), X)
	rb.cyl(Vector3(0, 0, -0.14), 0.045, 0.02, 0.1, 8, Color(0.34, 0.36, 0.26), X)
	rb.cyl(Vector3(0, 0, 0.12), 0.02, 0.02, 0.42, 6, Color(0.2, 0.2, 0.2), X)
	for k in 4:
		var a := k * PI * 0.5
		rb.box(Vector3(cos(a) * 0.04, sin(a) * 0.04, 0.3), Vector3(0.005 + absf(cos(a)) * 0.06, 0.005 + absf(sin(a)) * 0.06, 0.08), Color(0.25, 0.25, 0.24))
	_rmesh = rb.commit(Mats.vc())
	# tank zırh delici ok (APFSDS): uzun ince çubuk + kuyruk kanatçıkları
	var ap := MB.new()
	ap.cyl(Vector3(0, 0, -0.42), 0.0, 0.014, 0.08, 6, Color(0.55, 0.55, 0.55), X)
	ap.cyl(Vector3(0, 0, 0.0), 0.014, 0.014, 0.76, 6, Color(0.45, 0.45, 0.45), X)
	for k in 4:
		var a := k * PI * 0.5
		ap.box(Vector3(cos(a) * 0.022, sin(a) * 0.022, 0.34), Vector3(0.003 + absf(cos(a)) * 0.035, 0.003 + absf(sin(a)) * 0.035, 0.1), Color(0.4, 0.4, 0.4))
	_apfsds_m = ap.commit(Mats.vc())
	# tank HE mermisi
	var he := MB.new()
	he.cyl(Vector3(0, 0, -0.3), 0.0, 0.04, 0.1, 10, Color(0.6, 0.5, 0.2), X)
	he.cyl(Vector3(0, 0, -0.1), 0.04, 0.06, 0.2, 10, Color(0.3, 0.32, 0.24), X)
	he.cyl(Vector3(0, 0, 0.12), 0.06, 0.06, 0.26, 10, Color(0.3, 0.32, 0.24), X)
	_he_m = he.commit(Mats.vc())
	# güdümlü tanksavar füzesi: uzun gövde + orta kanatlar + kuyruk
	var at := MB.new()
	at.cyl(Vector3(0, 0, -0.5), 0.02, 0.06, 0.12, 10, Color(0.35, 0.38, 0.3), X)
	at.cyl(Vector3(0, 0, -0.05), 0.06, 0.06, 0.8, 10, Color(0.35, 0.38, 0.3), X)
	for k in 4:
		var a := k * PI * 0.5 + PI * 0.25
		at.box(Vector3(cos(a) * 0.08, sin(a) * 0.08, 0.0), Vector3(0.004 + absf(cos(a)) * 0.1, 0.004 + absf(sin(a)) * 0.1, 0.2), Color(0.3, 0.32, 0.26))
		at.box(Vector3(cos(a) * 0.07, sin(a) * 0.07, 0.32), Vector3(0.004 + absf(cos(a)) * 0.08, 0.004 + absf(sin(a)) * 0.08, 0.08), Color(0.3, 0.32, 0.26))
	_atgm_m = at.commit(Mats.vc())
	_air_models(X)
	_blur_m = _make_blur()

# topçu/havan mermisi uçuşta: çapraz iki şerit, baş (z=0) koyu ve opak, kuyruk (z=1) saydam; boyu
# hıza göre ölçeklenir. İleri -Z (look_at), iz +Z yönünde geride kalır.
func _make_blur() -> Mesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var head := Color(0.14, 0.14, 0.13, 0.95)
	var tail := Color(0.55, 0.55, 0.52, 0.0)
	for ax in [Vector3(0.07, 0, 0), Vector3(0, 0.07, 0)]:
		var back := Vector3(0, 0, 1)
		for v in [[-ax, head], [ax, head], [ax + back, tail], [-ax, head], [ax + back, tail], [-ax + back, tail]]:
			st.set_color(v[1])
			st.add_vertex(v[0])
	var m := st.commit()
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.vertex_color_use_as_albedo = true
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.surface_set_material(0, mat)
	return m

# Hava füzeleri gerçek boyutta: Hellfire (AGM-114), Vikhr (9K121), Hydra-70/S-8 roket,
# karadan havaya füze (Stinger/Igla tipi; büyük olanlar Buk/Tor ölçeğinde büyütülür)
func _air_models(X: Basis) -> void:
	var olive := Color(0.33, 0.36, 0.27)
	var glass := Color(0.08, 0.1, 0.14)
	var yel := Color(0.85, 0.7, 0.15)
	var brn := Color(0.45, 0.3, 0.16)
	var dk := Color(0.2, 0.21, 0.2)
	# --- Hellfire: yarım küre arayıcı camı, ön kanard, orta kanat, kuyruk kontrol yüzeyi
	var h := MB.new()
	h.sphere(Vector3(0, 0, -0.78), Vector3(0.088, 0.088, 0.07), 10, 6, glass)
	h.cyl(Vector3(0, 0, -0.74), 0.088, 0.089, 0.06, 12, Color(0.5, 0.5, 0.48), X)
	h.cyl(Vector3(0, 0, -0.45), 0.089, 0.089, 0.52, 12, olive, X)
	h.cyl(Vector3(0, 0, -0.3), 0.0905, 0.0905, 0.05, 12, yel, X)           # HE bandı
	h.cyl(Vector3(0, 0, 0.32), 0.089, 0.085, 1.0, 12, olive, X)
	h.cyl(Vector3(0, 0, 0.2), 0.0905, 0.0905, 0.05, 12, brn, X)            # motor bandı
	h.cyl(Vector3(0, 0, 0.84), 0.07, 0.055, 0.06, 10, dk, X)               # lüle
	for k in 4:
		var a := k * PI * 0.5 + PI * 0.25
		var cx := cos(a)
		var cy := sin(a)
		h.box(Vector3(cx * 0.12, cy * 0.12, -0.58), Vector3(0.004 + absf(cx) * 0.07, 0.004 + absf(cy) * 0.07, 0.07), olive)
		h.box(Vector3(cx * 0.15, cy * 0.15, 0.05), Vector3(0.005 + absf(cx) * 0.13, 0.005 + absf(cy) * 0.13, 0.32), olive)
		h.box(Vector3(cx * 0.14, cy * 0.14, 0.72), Vector3(0.005 + absf(cx) * 0.11, 0.005 + absf(cy) * 0.11, 0.14), olive)
	_hellfire_m = h.commit(Mats.vc())
	# --- Vikhr: uzun ince gövde, sivri burun, açılır kuyruk kanatları, beyaz-gri
	var v := MB.new()
	var gry := Color(0.62, 0.64, 0.6)
	v.cyl(Vector3(0, 0, -1.2), 0.0, 0.065, 0.32, 10, gry, X)
	v.cyl(Vector3(0, 0, -0.2), 0.065, 0.065, 1.7, 10, gry, X)
	v.cyl(Vector3(0, 0, -0.6), 0.067, 0.067, 0.05, 10, Color(0.75, 0.15, 0.1), X)
	v.cyl(Vector3(0, 0, 0.7), 0.065, 0.05, 0.12, 10, dk, X)
	for k in 4:
		var a := k * PI * 0.5
		var cx := cos(a)
		var cy := sin(a)
		v.box(Vector3(cx * 0.1, cy * 0.1, -0.9), Vector3(0.004 + absf(cx) * 0.07, 0.004 + absf(cy) * 0.07, 0.08), gry)
		v.box(Vector3(cx * 0.16, cy * 0.16, 0.5), Vector3(0.004 + absf(cx) * 0.2, 0.004 + absf(cy) * 0.2, 0.18), gry)
	_vikhr_m = v.commit(Mats.vc())
	# --- Hydra-70 / S-8 roket: ince gövde, sivri tapalı harp başlığı, sarmal kuyruk kanatçığı
	var r := MB.new()
	r.cyl(Vector3(0, 0, -0.78), 0.0, 0.035, 0.16, 8, Color(0.55, 0.5, 0.25), X)
	r.cyl(Vector3(0, 0, -0.55), 0.035, 0.035, 0.3, 8, olive, X)
	r.cyl(Vector3(0, 0, 0.1), 0.035, 0.035, 1.0, 8, Color(0.6, 0.62, 0.6), X)
	for k in 4:
		var a := k * PI * 0.5 + 0.3
		r.box(Vector3(cos(a) * 0.05, sin(a) * 0.05, 0.56), Vector3(0.003 + absf(cos(a)) * 0.05, 0.003 + absf(sin(a)) * 0.05, 0.1), dk)
	_hydra_m = r.commit(Mats.vc())
	# --- karadan havaya füze: kör sivri arayıcı, ön kanard, açılmış kuyruk, mavi eğitim değil savaş (sarı-kahve bant)
	var sm := MB.new()
	sm.sphere(Vector3(0, 0, -0.74), Vector3(0.035, 0.035, 0.06), 8, 5, Color(0.55, 0.6, 0.65))
	sm.cyl(Vector3(0, 0, -0.62), 0.03, 0.035, 0.14, 8, Color(0.3, 0.3, 0.3), X)
	sm.cyl(Vector3(0, 0, 0.05), 0.035, 0.035, 1.2, 8, olive, X)
	sm.cyl(Vector3(0, 0, -0.4), 0.036, 0.036, 0.03, 8, yel, X)
	sm.cyl(Vector3(0, 0, -0.32), 0.036, 0.036, 0.03, 8, brn, X)
	for k in 4:
		var a := k * PI * 0.5 + PI * 0.25
		sm.box(Vector3(cos(a) * 0.055, sin(a) * 0.055, -0.5), Vector3(0.003 + absf(cos(a)) * 0.05, 0.003 + absf(sin(a)) * 0.05, 0.06), olive)
		sm.box(Vector3(cos(a) * 0.07, sin(a) * 0.07, 0.6), Vector3(0.003 + absf(cos(a)) * 0.09, 0.003 + absf(sin(a)) * 0.09, 0.1), olive)
	_sam_m = sm.commit(Mats.vc())
	# --- motor alevi: parlak sarı çekirdek, saydam turuncu dış koni (eklemeli, gölgesiz)
	var fm := StandardMaterial3D.new()
	fm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	fm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	fm.vertex_color_use_as_albedo = true
	fm.cull_mode = BaseMaterial3D.CULL_DISABLED
	fm.no_depth_test = false
	var fl := MB.new()
	fl.cyl(Vector3(0, 0, 0.35), 0.06, 0.0, 0.7, 8, Color(1.0, 0.55, 0.15, 1), X, false, false)
	fl.cyl(Vector3(0, 0, 0.18), 0.035, 0.0, 0.36, 8, Color(1.0, 0.95, 0.7, 1), X, false, false)
	_flame_m = fl.commit(fm)
	var flm := StandardMaterial3D.new()
	flm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	flm.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	flm.albedo_color = Color(1.0, 0.95, 0.8)
	var fs := SphereMesh.new()
	fs.radius = 0.22
	fs.height = 0.44
	fs.radial_segments = 8
	fs.rings = 4
	fs.material = flm
	_flare_m = fs

func _flame(p: Proj, length := 1.0, width := 1.0) -> void:
	var f := MeshInstance3D.new()
	f.mesh = _flame_m
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.scale = Vector3(width, width, length)
	p.node.add_child(f)
	var bounds: AABB = p.node.mesh.get_aabb() if p.node is MeshInstance3D and p.node.mesh else AABB()
	f.position = Vector3(0, 0, bounds.end.z)

# roket/füze kuyruğunda iz fişeği (eklemeli küçük küre)
func _tail_flare(p: Proj, size: float, col: Color) -> void:
	var f := MeshInstance3D.new()
	f.mesh = _flare_m
	f.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	f.scale = Vector3.ONE * size
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	m.albedo_color = col
	f.material_override = m
	p.node.add_child(f)
	var bounds: AABB = p.node.mesh.get_aabb() if p.node is MeshInstance3D and p.node.mesh else AABB()
	f.position = Vector3(0, 0, bounds.end.z)

# motor ışığı: uçan roket çevresini (yer, duvar, duman) aydınlatır. Eşzamanlı ışık sayısı sınırlı
# (yaylım ateşinde her rokete değil); ışık roketle birlikte silinir.
const GLOW_MAX := 24
func _glow(p: Proj, energy: float, rng_m: float, col: Color) -> void:
	var n := 0
	for q in projs:
		if q.glow:
			n += 1
	if n >= GLOW_MAX:
		return
	var l := OmniLight3D.new()
	l.light_energy = energy
	l.omni_range = rng_m
	l.omni_attenuation = 1.6
	l.light_color = col
	l.shadow_enabled = false
	p.node.add_child(l)
	var bounds: AABB = p.node.mesh.get_aabb() if p.node is MeshInstance3D and p.node.mesh else AABB()
	l.position = Vector3(0, 0, bounds.end.z + 0.4)
	p.glow = true

func _node(m: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.layers = 2
	add_child(mi)
	return mi

func shell(from: Vector3, to: Vector3, team: int, src, target, mode: String, aid := "") -> void:
	var p := Proj.new()
	p.kind = mode
	p.pos = from
	p.aid = aid
	# hız: mühimmatın gerçek namlu çıkış hızı × K_proj (APFSDS 1555-1660, HE 850, 25 mm 1385 m/sn...)
	var sp := Ammo.speed(aid, 170.0 if mode == "ap" else (140.0 if mode == "he" else 110.0))
	var d := to - from
	var L := d.length()
	# hedefin biraz ötesine kadar uçar
	p.vel = d / maxf(L, 0.01) * sp
	p.life = (L + (3.0 if mode != "he" else 0.0)) / sp
	p.aim = to
	p.team = team
	p.src = src
	p.target = target
	if mode != "auto":
		p.node = _node(_apfsds_m if mode == "ap" else _he_m)
		p.node.position = from
		p.node.look_at(from + p.vel, Vector3.UP if absf(p.vel.normalized().y) < 0.97 else Vector3.FORWARD)
	projs.append(p)
	# iz rengi ulusa göre (NATO kırmızı-turuncu, doğu bloku yeşil); kalınlık ve kuyruk kalibreden
	# (25-30 mm otomatik top orta, 100-125 mm tank topu kalın, uzun ve parlak)
	var tc := Ammo.team_tracer(team)
	var cal := float(Ammo.get_def(aid).get("cal", 120.0 if mode != "auto" else 30.0))
	G.fx.tracer_cal(from, from + p.vel * p.life, sp, tc.lightened(0.25) if mode != "auto" else tc, cal)

# gerçek ortalama uçuş hızları (m/sn; oyunda × K_proj): roadmap 49. Model ipucu yoksa tür ve ulustan
const MISSILE_V := {"rpg": 180.0, "javelin": 150.0, "tow": 280.0, "kornet": 250.0, "konkurs": 200.0, "metis": 200.0,
	"refleks": 350.0, "arkan": 300.0, "hellfire": 425.0, "vikhr": 550.0, "hydra": 700.0}
const MISSILE_R := {"rpg": 500.0, "atgm": 4000.0, "topatk": 2500.0}
# füze/roket başına delme (birim = 20 mm RHA) ve delen isabette hasar (roadmap 51)
const MISSILE_PEN := {"rpg": 25.0, "at4": 21.0, "javelin": 37.5, "tow": 45.0, "tow2b": 10.0, "kornet": 60.0, "konkurs": 37.5,
	"metis": 47.5, "refleks": 45.0, "arkan": 45.0, "hellfire": 50.0, "vikhr": 50.0, "hydra": 6.0}
const MISSILE_DMG := {"rpg": 330.0, "at4": 300.0, "javelin": 520.0, "tow": 480.0, "tow2b": 460.0, "kornet": 520.0, "konkurs": 420.0,
	"metis": 450.0, "refleks": 450.0, "arkan": 450.0, "hellfire": 520.0, "vikhr": 520.0, "hydra": 180.0}

# füze türleri (roadmap 15): güdüm, kilitlenme/nişan süresi (sn), fişeğe kanma olasılığı
#  ir: ateşle-unut kızılötesi (Javelin görüntülü IIR, Stinger, Igla, Verba) — atıcı atışta serbest
#  wire: tel güdümlü SACLOS (TOW, Konkurs, Metis) — nişancı hedefi izlemeli; bastırılır, ölür, görüş kesilir
#        ya da tel menzili biterse füze sapar
#  beam: lazer hüzme binici (Kornet, Refleks, Arkan, Vikhr) — nişancı izlemeli, karıştırmaya dayanıklı
#  sal: yarı aktif lazer (Hellfire) — atan hava aracı hedefi işaretler
#  radar: orta/uzun menzil karadan havaya (komuta / aktif radar) — fişeğe neredeyse kanmaz
const MISSILES := {
	"rpg": {"guide": "", "lock": 1.3}, "at4": {"guide": "", "lock": 1.0},
	"javelin": {"guide": "ir", "lock": 4.0}, "tow": {"guide": "wire", "lock": 1.5}, "konkurs": {"guide": "wire", "lock": 1.5},
	"metis": {"guide": "wire", "lock": 1.2}, "kornet": {"guide": "beam", "lock": 1.5}, "refleks": {"guide": "beam", "lock": 1.2},
	"arkan": {"guide": "beam", "lock": 1.2}, "vikhr": {"guide": "beam", "lock": 1.5}, "hellfire": {"guide": "sal", "lock": 2.0},
	"hydra": {"guide": "", "lock": 0.5},
	"stinger": {"guide": "ir", "lock": 3.0, "decoy": 0.45}, "igla": {"guide": "ir", "lock": 3.5, "decoy": 0.35},
	"verba": {"guide": "ir", "lock": 2.5, "decoy": 0.15}, "sam_mid": {"guide": "radar", "lock": 2.0, "decoy": 0.1},
	"sam_long": {"guide": "radar", "lock": 3.0, "decoy": 0.05},
}

static func lock_time(key: String) -> float:
	return float(MISSILES.get(key, {}).get("lock", 1.5))

static func decoy_chance(key: String, big: bool) -> float:
	var m: Dictionary = MISSILES.get(key, {})
	return float(m.get("decoy", 0.35 if big else 0.62))

static func missile_key(kind: String, model: String, team: int) -> String:
	if model != "":
		return model
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	match kind:
		"rpg":
			return "at4" if nat in ["usa", "gbr"] else "rpg"
		"topatk":
			return "javelin" if nat in ["usa", "gbr"] else "kornet"
	return "tow" if nat in ["usa", "gbr"] else "kornet"

static func missile_speed(kind: String, model: String, team: int) -> float:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	var key := model
	if key == "":
		match kind:
			"rpg":
				key = "rpg"
			"topatk":
				key = "javelin" if nat in ["usa", "gbr"] else "kornet"
			_:
				key = "tow" if nat in ["usa", "gbr"] else "kornet"
	return float(MISSILE_V.get(key, 200.0)) * Ammo.K_PROJ

func rocket(from: Vector3, to: Vector3, team: int, src, target, kind := "rpg", model := "", max_r := -1.0) -> void:
	var p := Proj.new()
	p.kind = kind
	var guided := kind == "atgm" or kind == "topatk"
	p.pos = from
	var d := to - from
	var L := d.length()
	var spd := missile_speed(kind, model, team)
	var reach := (max_r if max_r > 0.0 else float(MISSILE_R.get(kind, 2000.0)) * Combat.K_RANGE)
	# güdümsüz roket dağılımı: ~0,6 % mesafe (RPG-7 100 m'de ~0,6 m)
	var err := L * 0.006 + 0.3
	p.aim = to + Vector3(randf_range(-err, err), randf_range(-0.25, 0.25), randf_range(-err, err))
	p.vel = (p.aim - from).normalized() * spd
	p.life = maxf(L, reach) * 1.08 / spd
	G.fx.backblast(from, p.vel.normalized())
	if guided:
		p.aim = to
		var up := Vector3(0, 0.6 if kind == "topatk" else 0.05, 0)
		p.vel = ((to - from).normalized() + up).normalized() * spd
		p.life = maxf(L, reach) * 1.15 / spd + 1.0
	p.team = team
	p.src = src
	p.target = target
	p.aid = missile_key(kind, model, team)
	p.max_r = reach
	p.launch = from
	if guided:
		p.guide = String(MISSILES.get(p.aid, {}).get("guide", "ir"))
		if p.guide == "wire":
			p.wire = MeshInstance3D.new()
			p.wire.mesh = ImmediateMesh.new()
			p.wire.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			p.wire.material_override = _wire_mat()
			add_child(p.wire)
	var mm: Mesh = _atgm_m if guided else _rmesh
	match model:
		"hellfire":
			mm = _hellfire_m
		"vikhr":
			mm = _vikhr_m
		"hydra":
			mm = _hydra_m
	p.node = _node(mm)
	p.node.position = from
	p.node.look_at(from + p.vel, Vector3.UP if absf(p.vel.normalized().y) < 0.97 else Vector3.FORWARD)
	if model in ["hellfire", "vikhr", "hydra"]:
		_flame(p, 1.4 if model == "hydra" else 1.0)
		_glow(p, 2.2, 6.0, Color(1.0, 0.7, 0.35))
	elif guided:
		# tanksavar füzesi: küçük motor alevi + kuyrukta parlak iz fişeği (nişancı füzeyi bununla izler)
		_flame(p, 0.45, 0.7)
		_tail_flare(p, 0.3, Color(1.0, 0.9, 0.75))
		_glow(p, 1.4, 4.5, Color(1.0, 0.85, 0.65))
	else:
		# RPG: roket motoru namludan ~10 m sonra ateşlenir, kısa ve parlak alev
		_flame(p, 0.6, 0.85)
		_glow(p, 1.8, 5.0, Color(1.0, 0.68, 0.3))
	projs.append(p)

# karadan havaya güdümlü füze: hedefe orantılı seyrüsefer, yakınlık tapası, fişeğe kanabilir
func sam(from: Vector3, target, team: int, src, big := false, key := "") -> void:
	var p := Proj.new()
	p.kind = "sam"
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	p.aid = key if key != "" else ("sam_mid" if big else ("stinger" if nat in ["usa", "gbr"] else "verba"))
	p.pos = from
	p.big = big
	p.team = team
	p.src = src
	p.target = target
	p.spd = 30.0 * Ammo.K_PROJ
	var tp: Vector3 = target.aim_point()
	p.vel = ((tp - from).normalized() + Vector3(0, 0.9, 0)).normalized() * p.spd
	# gerçek hız (uzun/orta menzil ~1200 m/sn, omuzdan atılan ~700 m/sn × K_proj); ömür menzile yeter
	var vmax := (1200.0 if big else 700.0) * Ammo.K_PROJ
	var reach: float = src.sam_range if src != null and is_instance_valid(src) and "sam_range" in src else 300.0
	p.life = maxf(7.0, reach / maxf(vmax, 1.0) * 1.4 + 2.0)
	p.node = _node(_sam_m)
	p.node.scale = Vector3.ONE * (2.4 if big else 1.0)
	p.node.position = from
	p.node.look_at(from + p.vel, Vector3.UP)
	_flame(p, 1.6)
	projs.append(p)
	G.fx.backblast(from, -p.vel.normalized())
	G.fx.flash(from, 6.0, 10.0, 0.12, Color(1.0, 0.8, 0.5))
	Sfx.play3d("rpg", from, 2.0)
	if target is Vehicle:
		target.on_missile(p)

# ısı fişeği (magnezyum): parlak, kavis çizerek düşer, arkasında kalın beyaz duman
func flare(from: Vector3, vel: Vector3) -> void:
	var p := Proj.new()
	p.kind = "flare"
	p.pos = from
	p.vel = vel
	p.life = randf_range(2.6, 3.4)
	var mi := MeshInstance3D.new()
	mi.mesh = _flare_m
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	p.node = mi
	p.node.position = from
	projs.append(p)

# Dolaylı atış yörüngesi gerçekçi: mermi yüksek bir yayla (havan çok dik) ekrandan çıkar, hedefe dik iner.
# Eskiden ~7 m tepeli, 2,5 sn'lik alçak yay çiziyordu — mancınıktan atılan taş gibi görünüyordu.
# Uçuşta top/taş gibi değil, hız yönünde uzayan hareket bulanıklığı izi olarak çizilir (gerçekte mermi
# gözle seçilmez); roketatar roketi görünür kalır (motor alevi + duman izi).
# gerçek menzilde gerçek uçuş: havan yüksek açı (tepe ≈ mesafenin yarısı, 3 km'de ~30 sn), obüs tepe ≈
# mesafenin %18'i (8 km'de ~34 sn), roket ~600 m/sn ortalama
func mortar(from: Vector3, to: Vector3, team: int, src, aid := "") -> void:
	_lob(from, to, team, src, "mortar", _flight_t(from.distance_to(to), 0.5, 45.0, 2500.0), aid)

func mlrs_rocket(from: Vector3, to: Vector3, team: int, src, axis := Vector3.ZERO) -> void:
	_lob(from, to, team, src, "rkt", 3.2 + from.distance_to(to) / 600.0)
	var p: Proj = projs[projs.size() - 1]
	p.node.queue_free()
	p.node = _node(_rmesh)
	p.node.scale = Vector3.ONE * 1.6
	p.node.position = from
	if axis != Vector3.ZERO:
		# tüpten çıkış: ilk anlarda yavaş süzülür, hızlanarak (≈ t³) tüp ekseninde havalanır, sonra yörüngeye girer
		p.boost = 0.6
		p.axis = axis.normalized()
		p.launch = from
		p.spd = p.vel.length()
		p.node.look_at(from + p.axis, Vector3.UP if absf(p.axis.y) < 0.97 else Vector3.FORWARD)
	# roketatar roketi: uzun motor alevi + ışık (yaylımda ışık sayısı sınırlı)
	_flame(p, 1.5, 1.2)
	_glow(p, 2.6, 7.0, Color(1.0, 0.7, 0.35))

func artillery(from: Vector3, to: Vector3, team: int, src, aid := "") -> void:
	_lob(from, to, team, src, "arty", _flight_t(from.distance_to(to), 0.18, 60.0, 2500.0), aid)

# tepe yüksekliğinden uçuş süresi: H = mesafe × k (sınırlı), T = 2·√(2H/g)
func _flight_t(dist: float, k: float, hmin: float, hmax: float) -> float:
	var H := clampf(dist * k, hmin, hmax)
	return 2.0 * sqrt(2.0 * H / 9.8)

func _lob(from: Vector3, to: Vector3, team: int, src, kind: String, T: float, aid := "") -> void:
	T = maxf(T, 0.5)
	var p := Proj.new()
	p.kind = kind
	p.aid = aid
	p.pos = from
	var g := Vector3(0, -9.8, 0)
	p.vel = (to - from - 0.5 * g * T * T) / T
	p.team = team
	p.src = src
	p.life = T + 0.5
	p.aim = to
	p.node = _node(_blur_m if kind != "rkt" else _rmesh)
	if kind != "rkt":
		(p.node as MeshInstance3D).cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	p.node.position = from
	projs.append(p)

# C-RAM (roadmap 31): havan / topçu / roket mermisini inişte 20 mm Gatling ile vurur — düşük olasılık (%35),
# sınırlı mühimmat (20 angajman), angajmanlar arası 1,2 sn. Listede yalnız C-RAM birimleri.
var _crams: Array = []
var _cram_t := 0.0

func _cram_try(p: Proj) -> bool:
	if G.time > _cram_t:
		_cram_t = G.time + 1.0
		_crams = G.units.filter(func(u): return is_instance_valid(u) and u is Vehicle and u.alive and u.vid == "usa_aa_cram")
	for c in _crams:
		if not is_instance_valid(c) or not c.alive or c.team == p.team or c.cram_ammo <= 0 or G.time < c.cram_cd:
			continue
		if Vector2(c.position.x - p.pos.x, c.position.z - p.pos.z).length() > c._wr("aa", 100.0):
			continue
		p.aps_tried = true
		c.cram_ammo -= 1
		c.cram_cd = G.time + 1.2
		c.fired_t = G.time
		var mp: Vector3 = c.eye_point()
		for k in 4:
			G.fx.tracer_cal(mp, p.pos + Vector3(randf_range(-3, 3), randf_range(-3, 3), randf_range(-3, 3)), 600.0, Ammo.team_tracer(c.team).lightened(0.3), 20.0)
		Sfx.play3d("autocannon", mp, 2.0, 0.05, 0.02)
		if randf() < 0.35:
			_air_burst(p.pos, false)
			return true
		return false
	return false

func _step_lob(p: Proj, dt: float) -> bool:
	p.t += dt
	if p.boost > 0.0 and p.t <= p.boost:
		var k := p.t / p.boost
		var bp := p.launch + p.axis * (p.spd * p.boost * k * k * k / 3.0)
		_rkt_trail(p, p.pos, bp)
		p.pos = bp
		p.node.position = bp
		if p.t + dt > p.boost:
			# serbest uçuş: kalan sürede hedefe inecek yörünge yeniden çözülür
			var tr := maxf(p.life - 0.5 - p.t, 0.6)
			p.vel = (p.aim - p.pos - 0.5 * Vector3(0, -9.8, 0) * tr * tr) / tr
		return false
	p.vel.y -= 9.8 * dt
	var np := p.pos + p.vel * dt
	if not p.aps_tried and p.vel.y < 0.0 and p.pos.y > 12.0 and _cram_try(p):
		return true
	p.trail -= dt
	if p.kind == "rkt":
		_rkt_trail(p, p.pos, np)
	elif p.trail <= 0.0:
		p.trail = 0.05
		G.fx.emit(Fx.P_SMOKE, p.pos, Vector3.ZERO, 0.6, 0.15, 0.4, 0.0, 1.0, Color(0.8, 0.8, 0.78, 0.35))
	# düşüş ıslığı
	if p.vel.y < 0.0 and not p.landed and np.y < 18.0:
		p.landed = true
		Sfx.play3d("incoming", p.aim, -2.0, 0.1, 0.1)
	var hit := np.y <= 0.0 or (np.y < 6.0 and G.grid.height_at(np) > np.y)
	p.pos = np
	p.node.position = np
	if p.vel.length() > 0.1:
		p.node.look_at(np + p.vel, Vector3.UP if absf(p.vel.normalized().y) < 0.97 else Vector3.FORWARD)
		if p.kind != "rkt":
			# hareket bulanıklığı: iz boyu ≈ 1/25 sn'de alınan yol (tepede kısalır, inişte uzar)
			p.node.scale = Vector3(1.0, 1.0, clampf(p.vel.length() * 0.04, 0.6, 6.0))
	if hit or p.t > p.life:
		var at := Vector3(np.x, maxf(np.y, 0.0), np.z)
		# patlama yarıçapı ve hasarı kalibreden (155 mm 7 m, 122 mm 5,5 m, 203 mm 9 m, 120 mm havan 6 m...)
		var am := Ammo.get_def(p.aid)
		if p.kind == "mortar":
			G.explode(at, float(am.get("blast", 4.0)), float(am.get("bdmg", 110.0)), "shell", p.team, p.src)
		else:
			G.explode(at, float(am.get("blast", 6.0)), float(am.get("bdmg", 180.0)), "big", p.team, p.src)
		return true
	return false

# roketatar roketi izi: motor yanarken (~1,9 sn) yol boyunca aralıksız beyaz duman (eşit aralıkla, kare hızından
# bağımsız) + kuyrukta parlak alev çizgisi; yanma bitince iz kesilir, roket balistik süzülür
const RKT_BURN := 1.9
func _rkt_trail(p: Proj, a: Vector3, b: Vector3) -> void:
	if p.t > RKT_BURN:
		return
	var L := a.distance_to(b)
	var step := clampf(p.vel.length() * 0.008, 0.6, 3.0) if p.t > p.boost else 0.35
	p.trail -= L
	var dir := (b - a) / maxf(L, 0.001)
	var n := 0
	while p.trail <= 0.0 and n < 24:
		var q := b + dir * p.trail
		p.trail += step
		n += 1
		var fade := 1.0 - smoothstep(RKT_BURN * 0.7, RKT_BURN, p.t)
		G.fx.emit(Fx.P_SMOKE, q, Vector3(randf_range(-0.2, 0.2), randf_range(0.0, 0.25), randf_range(-0.2, 0.2)), randf_range(4.0, 6.0), 0.5, randf_range(1.6, 2.4), -0.02, 0.4, Color(0.95, 0.94, 0.92, 0.55 * fade + 0.1))
	if n > 0:
		G.fx.emit(Fx.P_SPARK, b, -dir * 30.0, 0.05, 0.16, 0.1, 0.0, 6.0, Color(1.0, 0.78, 0.4, 1))

# fuse_left ≥ 0: geri atılan bomba — kalan fitille uçar (yeni fitil başlamaz)
func grenade(from: Vector3, to: Vector3, team: int, src, smoke := false, fuse_left := -1.0) -> void:
	var p := Proj.new()
	p.kind = "grenade"
	p.smoke = smoke
	p.pos = from
	var L := Vector2(to.x - from.x, to.z - from.z).length()
	var T := 0.7 + L * 0.035
	var g := Vector3(0, -9.8, 0)
	p.vel = (to - from - 0.5 * g * T * T) / T
	p.fuse = (3.0 if not smoke else 2.2) if fuse_left < 0.0 else maxf(fuse_left, 0.05)
	p.team = team
	p.src = src
	p.node = _node(_gmesh)
	p.node.position = from
	projs.append(p)
	Sfx.play3d("throw", from, -6.0)

func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	var i := projs.size() - 1
	while i >= 0:
		var p: Proj = projs[i]
		var done := false
		match p.kind:
			"ap", "he", "auto":
				done = _step_shell(p, dt)
			"rpg", "atgm", "topatk":
				done = _step_rocket(p, dt)
			"grenade":
				done = _step_grenade(p, dt)
			"mortar", "arty", "rkt":
				done = _step_lob(p, dt)
			"sam":
				done = _step_sam(p, dt)
			"flare":
				done = _step_flare(p, dt)
		if done:
			if p.node:
				p.node.queue_free()
			if p.wire != null:
				p.wire.queue_free()
			projs.remove_at(i)
		i -= 1

func _seg_block(a: Vector3, b: Vector3) -> Vector3:
	# a→b doğrusunda engel varsa çarpma noktası, yoksa Vector3.INF
	var L := a.distance_to(b)
	var n := int(L / 0.4) + 1
	for s in range(1, n + 1):
		var q := a.lerp(b, float(s) / n)
		if q.y <= 0.0:
			return Vector3(q.x, 0.02, q.z)
		if G.grid.height_at(q) > q.y:
			return q
	return Vector3.INF

func _step_shell(p: Proj, dt: float) -> bool:
	var np := p.pos + p.vel * dt
	p.t += dt
	if p.node:
		p.node.position = np
	var tgt: Unit = p.target if p.target != null and is_instance_valid(p.target) else null
	# doğrudan isabet (araç/yapı gövdesi)
	if tgt != null and tgt.alive and not (tgt is Soldier):
		var tp := tgt.aim_point()
		var seg := np - p.pos
		var t := clampf((tp - p.pos).dot(seg) / maxf(seg.length_squared(), 1e-5), 0.0, 1.0)
		var closest := p.pos + seg * t
		if closest.distance_to(tp) < tgt.radius * 0.7:
			_shell_hit(p, closest, tgt)
			return true
	var hit := _seg_block(p.pos, np)
	if hit != Vector3.INF and p.t > 0.02:
		_shell_hit(p, hit, null)
		return true
	p.pos = np
	if p.t >= p.life:
		_shell_hit(p, p.pos, null)
		return true
	return false

func _shell_hit(p: Proj, at: Vector3, direct: Unit) -> void:
	# mühimmat tablosu: doğrudan hasar, delme, patlama yarıçapı/hasarı (yoksa eski sabitler)
	var am := Ammo.get_def(p.aid)
	if direct and direct is Vehicle and am.has("pen"):
		Vehicle.shot_pen = am["pen"]
	match p.kind:
		"ap":
			if direct:
				if direct is Vehicle: Vehicle.shot_from = p.pos - p.vel * p.t
				direct.take_damage(float(am.get("dmg", 230.0)), p.src, "ap")
				G.fx.impact(at, "metal")
				G.fx.explosion(at, 0.8, "ap")
				Sfx.play3d("hit_metal", at, 3.0)
			else:
				G.explode(at, 2.5, 60.0, "shell", p.team, p.src)
		"he":
			if direct:
				if direct is Vehicle: Vehicle.shot_from = p.pos - p.vel * p.t
				direct.take_damage(float(am.get("dmg", 140.0)), p.src, "he")
			G.explode(at, float(am.get("blast", 4.5)), float(am.get("bdmg", 130.0)), "shell", p.team, p.src)
		"auto":
			if direct:
				if direct is Vehicle: Vehicle.shot_from = p.pos - p.vel * p.t
				direct.take_damage(float(am.get("dmg", 32.0)), p.src, "auto")
				G.fx.impact(at, "metal")
			G.explode(at, 1.7, 40.0, "auto", p.team, p.src)

func _step_rocket(p: Proj, dt: float) -> bool:
	p.t += dt
	var wob := Vector3(sin(p.t * 23.0), cos(p.t * 19.0), sin(p.t * 17.0)) * 0.6
	if p.kind == "atgm" or p.kind == "topatk":
		wob *= 0.15
		var gt: Unit = p.target if p.target != null and is_instance_valid(p.target) else null
		if p.guide in ["wire", "beam", "sal"] and p.guide_ok:
			p.gchk -= dt
			if p.gchk <= 0.0:
				p.gchk = 0.15
				if not _guidance_ok(p, gt):
					p.guide_ok = false
					# güdüm koptu: füze son doğrultusundan rastgele sapar, artık hedefe dönmez
					p.vel = p.vel.rotated(Vector3(randf_range(-1, 1), randf_range(-0.3, 0.3), randf_range(-1, 1)).normalized(), deg_to_rad(randf_range(4.0, 11.0)))
					if p.src != null and is_instance_valid(p.src) and p.src.team == G.player_team and not G.spectate and p.src.has_method("say"):
						p.src.say("FÜZE SAPTI", 1.5)
		if p.wire != null:
			_draw_wire(p)
		if not p.guide_ok:
			wob *= 6.0
			gt = null
		elif p.guide == "wire" and p.src != null and is_instance_valid(p.src) and p.src is Soldier and p.src.suppression > 45.0:
			# bastırılan nişancının eli titrer: tel güdümlü füze yalpalar
			wob *= 1.0 + (p.src.suppression - 45.0) / 10.0
		if gt != null and gt.alive:
			var aimp := gt.aim_point()
			var dd := Vector2(aimp.x - p.pos.x, aimp.z - p.pos.z).length()
			if p.kind == "topatk" and dd > 14.0 and p.pos.y < 10.0:
				aimp.y += clampf(dd * 0.4, 0.0, 14.0)
			var spd := p.vel.length()
			if p.pos.distance_to(gt.aim_point()) < 14.0:
				p.vel = (gt.aim_point() - p.pos).normalized() * spd     # son evre: doğrudan
			else:
				p.vel = p.vel.lerp((aimp - p.pos).normalized() * spd, clampf(dt * 6.0, 0.0, 1.0))
	var np := p.pos + (p.vel + wob) * dt
	# yaklaşan roketi gören piyade yana atılır (hedefin çevresi, son ~0.6 sn)
	p.fuse -= dt
	if p.fuse <= 0.0:
		p.fuse = 0.1
		var ahead := p.pos + p.vel * 0.45
		for s in G.near(ahead, 5.0):
			if s is Soldier and s.alive and s.team != p.team:
				s.on_rocket(p.pos, p.vel)
	p.trail -= dt
	if p.trail <= 0.0:
		p.trail = 0.008
		G.fx.rocket_trail(p.pos, p.vel.normalized())
	var tgt: Unit = p.target if p.target != null and is_instance_valid(p.target) else null
	# aktif koruma (APS, roadmap 31): yaklaşan roket/füzeyi ~15 m'de vurur (sınırlı şarj)
	if not p.aps_tried and tgt != null and tgt is Vehicle and tgt.alive and tgt.aps_n > 0 and np.distance_to(tgt.aim_point()) < 15.0:
		p.aps_tried = true
		if tgt.aps_intercept(p.pos, p.kind):
			return true
	if tgt != null and tgt.alive and not (tgt is Soldier):
		if np.distance_to(tgt.aim_point()) < tgt.radius * (1.1 if p.kind in ["atgm", "topatk"] else 0.85):
			if tgt is Vehicle: Vehicle.shot_from = p.pos - p.vel * p.t
			if tgt is Vehicle:
				var pv := float(MISSILE_PEN.get(p.aid, 25.0))
				Vehicle.shot_pen = [1, pv, pv]
			tgt.take_damage(float(MISSILE_DMG.get(p.aid, 330.0)), p.src, p.kind)
			G.fx.explosion(np, 1.3, "rpg")
			G.fx.flash(np, 9.0, 9.0, 0.12, Color(1.0, 0.75, 0.4))
			Sfx.play3d("expl_med", np, 3.0)
			G.fx.impact(np, "metal")
			for s in G.near(np, 4.0):
				if s is Soldier and s.alive:
					s.on_blast(np, 2.5, 50.0, s.position.distance_to(np), p.src)
			return true
	var hit := _seg_block(p.pos, np)
	if hit != Vector3.INF and p.t > 0.05:
		G.explode(hit, 3.0, 95.0, "rpg", p.team, p.src)
		return true
	p.pos = np
	p.node.position = np
	if p.vel.length() > 0.01:
		p.node.look_at(np + p.vel, Vector3.UP if absf(p.vel.normalized().y) < 0.97 else Vector3.FORWARD)
	if p.t >= p.life:
		G.explode(Vector3(p.pos.x, maxf(p.pos.y, 0.0), p.pos.z), 3.0, 95.0, "rpg", p.team, p.src)
		return true
	return false

# tel/hüzme/işaretleme güdümü sürüyor mu: atıcı hayatta ve ateş edebilir, ağır bastırılmamış, hedefi
# görüyor; tel güdümlüde tel menzili aşılmamış
func _guidance_ok(p: Proj, gt: Unit) -> bool:
	var s = p.src
	if s == null or not is_instance_valid(s) or not s.alive:
		return false
	if s is Soldier and (not s.can_fight() or s.suppression > 85.0 or s.state in ["dive", "fly", "dazed"]):
		return false
	if gt == null or not gt.alive:
		return true
	if p.guide == "wire" and p.pos.distance_to(p.launch) > p.max_r * 1.05:
		return false
	if s is Vehicle and s.is_air():
		return true
	return G.grid.los(s.eye_point(), gt.aim_point(), s.los_skip(), 0.5)

var _wmat: StandardMaterial3D = null
func _wire_mat() -> StandardMaterial3D:
	if _wmat == null:
		_wmat = StandardMaterial3D.new()
		_wmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_wmat.albedo_color = Color(0.12, 0.12, 0.11, 0.85)
		_wmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	return _wmat

# güdüm teli: atıcıdan füzeye hafif sarkan ince çizgi (kopunca serbest ucu düşer)
func _draw_wire(p: Proj) -> void:
	var im := p.wire.mesh as ImmediateMesh
	im.clear_surfaces()
	var a := p.launch
	if p.guide_ok and p.src != null and is_instance_valid(p.src):
		a = p.src.eye_point() if not (p.src is Vehicle) else p.launch
	var b := p.pos
	var L := a.distance_to(b)
	if L < 0.5:
		return
	im.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for i in 13:
		var t := float(i) / 12.0
		var q := a.lerp(b, t)
		q.y -= sin(t * PI) * minf(L * 0.02, 2.5) * (3.0 if not p.guide_ok else 1.0)
		im.surface_add_vertex(q)
	im.surface_end()

func _step_sam(p: Proj, dt: float) -> bool:
	p.t += dt
	# motor: 0.4 sn fırlatma, sonra hızlanma
	var vmax := (1200.0 if p.big else 700.0) * Ammo.K_PROJ
	p.spd = minf(p.spd + dt * (vmax / 1.6 if p.t > 0.35 else vmax * 0.1), vmax)
	var tgt = p.target if p.target != null and is_instance_valid(p.target) else null
	var aimp := p.pos + p.vel
	if p.decoy != Vector3.INF:
		aimp = p.decoy
	elif tgt != null and tgt.alive:
		var tp: Vector3 = tgt.aim_point()
		var tv: Vector3 = tgt.hvel if tgt is Vehicle else Vector3.ZERO
		var tt := p.pos.distance_to(tp) / maxf(p.spd, 1.0)
		aimp = tp + tv * tt * 0.9
	var want := (aimp - p.pos).normalized() * p.spd
	var turn := (3.2 if p.big else 3.8) * dt
	var cur := p.vel.normalized()
	var nd := cur.slerp(want.normalized(), clampf(turn / maxf(cur.angle_to(want.normalized()), 0.001), 0.0, 1.0)) if p.t > 0.25 else cur
	p.vel = nd * p.spd
	var np := p.pos + p.vel * dt
	p.trail -= dt
	if p.trail <= 0.0:
		p.trail = 0.012
		# keskin, kalın beyaz duman şeridi + parlak alev
		G.fx.emit(Fx.P_SMOKE, p.pos, G.fx._rv(0.15), randf_range(4.5, 7.0), 0.5 if not p.big else 0.9, 1.8 if not p.big else 2.8, -0.03, 1.4, Color(0.95, 0.95, 0.94, 0.7))
		G.fx.emit(Fx.P_SPARK, p.pos, -p.vel.normalized() * 30.0, 0.04, 0.2, 0.1, 0.0, 6.0, Color(1.0, 0.85, 0.5, 1))
	p.node.position = np
	if p.vel.length() > 0.01:
		p.node.look_at(np + p.vel, Vector3.UP if absf(p.vel.normalized().y) < 0.97 else Vector3.FORWARD)
	p.pos = np
	if p.decoy != Vector3.INF and p.pos.distance_to(p.decoy) < 3.0:
		_air_burst(p.pos, p.big)
		return true
	if tgt != null and tgt.alive and p.decoy == Vector3.INF and p.pos.distance_to(tgt.aim_point()) < (3.2 if p.big else 2.2):
		_air_burst(p.pos, p.big)
		tgt.take_damage(420.0 if p.big else 260.0, p.src, "sam")
		return true
	if p.pos.y < 0.3 or p.t >= p.life:
		_air_burst(p.pos, p.big)    # kendini imha
		return true
	return false

func _air_burst(at: Vector3, big: bool) -> void:
	G.fx.explosion(at, 1.2 if big else 0.8, "flak")
	G.fx.flash(at, 8.0, 14.0, 0.12, Color(1.0, 0.75, 0.45))
	for i in 14:
		G.fx.emit(Fx.P_SPARK, at, G.fx._rv(14.0), randf_range(0.2, 0.5), 0.12, 0.05, 6.0, 1.5, Color(1.0, 0.8, 0.4, 1))
	Sfx.play3d("expl_med", at, 0.0)

func _step_flare(p: Proj, dt: float) -> bool:
	p.t += dt
	p.vel.y -= 4.5 * dt
	p.vel *= 1.0 - dt * 1.1
	p.pos += p.vel * dt
	p.node.position = p.pos
	var k := 1.0 - p.t / p.life
	p.node.scale = Vector3.ONE * (0.6 + 0.6 * k) * (0.85 + 0.3 * randf())
	p.trail -= dt
	if p.trail <= 0.0:
		p.trail = 0.03
		G.fx.emit(Fx.P_SMOKE, p.pos, G.fx._rv(0.2), randf_range(2.5, 4.0), 0.3, 1.3, -0.04, 1.2, Color(0.96, 0.96, 0.95, 0.6))
		G.fx.emit(Fx.P_SPARK, p.pos, G.fx._rv(2.0), 0.12, 0.25, 0.05, 2.0, 1.0, Color(1.0, 0.95, 0.8, 1))
	return p.t >= p.life or p.pos.y < 0.2

func _step_grenade(p: Proj, dt: float) -> bool:
	p.t += dt
	p.fuse -= dt
	if p.sunk:
		# suda batmış: fitil bitince su altında boğuk patlama (yüzey kabarır, sütun); sis bombası yalnız buhar
		if p.fuse <= 0.0:
			if p.smoke:
				for k in 6:
					G.fx.emit(Fx.P_SMOKE, p.pos + Vector3(randf_range(-0.4, 0.4), 0.1, randf_range(-0.4, 0.4)), Vector3(randf_range(-0.3, 0.3), randf_range(0.6, 1.2), randf_range(-0.3, 0.3)), randf_range(1.5, 2.5), 0.3, 1.2, -0.1, 0.5, Color(0.9, 0.93, 0.95, 0.35))
			else:
				G.explode(p.pos, 3.0, 60.0, "uw", p.team, p.src)
			return true
		return false
	p.vel.y -= 9.8 * dt
	var np := p.pos + p.vel * dt
	if np.y <= 0.05 and G.grid.is_water(np) and not G.grid.on_bridge(np):
		# suya düştü (roadmap 115): sekmez, yüzeyde yuvarlanmaz — küçük sıçrama ve batar
		p.sunk = true
		p.pos = Vector3(np.x, 0.0, np.z)
		G.fx.water_splash(p.pos, 0.22)
		Sfx.play3d("throw", p.pos, -16.0)
		if p.node:
			p.node.visible = false
		return false
	# duvara çarpma
	if G.grid.height_at(np) > np.y and np.y > 0.05:
		p.vel.x *= -0.3
		p.vel.z *= -0.3
		np = p.pos + Vector3(p.vel.x, 0, p.vel.z) * dt
	if np.y <= 0.05:
		np.y = 0.05
		if p.vel.y < -1.5:
			p.vel.y = -p.vel.y * 0.3
			p.vel.x *= 0.45
			p.vel.z *= 0.45
		else:
			p.vel = Vector3(p.vel.x * (1.0 - dt * 5.0), 0, p.vel.z * (1.0 - dt * 5.0))
		if not p.landed:
			p.landed = true
			if not p.smoke:
				for s in G.near(np, 5.0):
					if s is Soldier and s.alive and s.team != p.team:
						if s.on_grenade(np, p.fuse, p.src):
							return true
					elif s is Soldier and s.alive and s.team == p.team and s.position.distance_to(np) < 3.0 and s != p.src:
						s.on_grenade(np, p.fuse, null)
	p.pos = np
	p.node.position = np
	p.node.rotation += Vector3(dt * 9.0, dt * 6.0, 0)
	if p.fuse <= 0.0:
		if p.smoke:
			G.fx.smoke_screen(p.pos, 18.0)
			G.add_smoke(p.pos, 4.5, 19.0)
			Sfx.play3d("smoke_pop", p.pos, -2.0)
		else:
			G.explode(p.pos, 4.2, 120.0, "grenade", p.team, p.src)
		return true
	return false
