class_name Building extends Unit
# Yapılar: karargâh, ileri üs, kışla, fabrika, hastane, MG yuvası, kule ve hat yapıları.

const BDEF := {
	"hq": {"title": "Karargâh", "hp": 3200.0, "size": Vector2(17, 13), "cost": 0, "time": 1.0, "cap": 40, "sight": 46.0, "prod": ["rifle_squad", "medic_team"], "desc": "Ana üs. Kaybedilirse ve ileri üs kalmazsa savaş biter."},
	"fob": {"title": "İleri Üs", "hp": 1800.0, "size": Vector2(10, 10), "cost": 300, "time": 40.0, "cap": 12, "sight": 40.0, "prod": ["rifle_squad", "medic_team"], "desc": "Birlik sınırını artırır, mühimmat verir, yol ve ikmal kamyonu getirir. Ele geçirilebilir."},
	"barracks": {"title": "Kışla", "hp": 1200.0, "size": Vector2(9, 6), "cost": 250, "time": 30.0, "cap": 0, "sight": 30.0, "prod": ["rifle_squad", "mg_team", "at_squad", "medic_team", "sniper_team", "engineer_squad", "mortar_team", "drone_team", "atgm_team"], "desc": "Tüm piyade timlerini eğitir."},
	"factory": {"title": "Araç Fabrikası", "hp": 1600.0, "size": Vector2(12, 9), "cost": 400, "time": 45.0, "cap": 0, "sight": 30.0, "prod": ["technical", "apc", "ifv", "aa", "tank", "arty", "fieldgun", "howitzer", "atgun", "aagun", "hmortar", "mtngun", "mlrs"], "desc": "Zırhlı araçlar ve topçu üretir."},
	"helipad": {"title": "Helikopter Pisti", "hp": 900.0, "size": Vector2(11, 11), "cost": 450, "time": 40.0, "cap": 0, "sight": 32.0, "prod": ["heli", "transport", "para_squad"], "desc": "Saldırı helikopteri üretir."},
	"hospital": {"title": "Sahra Hastanesi", "hp": 700.0, "size": Vector2(7, 6), "cost": 180, "time": 22.0, "cap": 0, "sight": 28.0, "prod": [], "desc": "Sedyeciler 45 m içindeki yaralıları toplar; yakındakiler iyileşir."},
	"mgnest": {"title": "MG Yuvası", "hp": 600.0, "size": Vector2(4, 4), "cost": 120, "time": 18.0, "cap": 0, "sight": 46.0, "prod": [], "desc": "Kum torbalı sabit makineli tüfek."},
	"tower": {"title": "Gözetleme Kulesi", "hp": 400.0, "size": Vector2(3, 3), "cost": 90, "time": 15.0, "cap": 0, "sight": 85.0, "prod": [], "desc": "Geniş görüş alanı."},
	"sandbags": {"title": "Kum Torbası", "hp": 200.0, "size": Vector2(1, 1), "cost": 6, "time": 1.2, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Alçak siper (metre başına)."},
	"concrete": {"title": "Beton Duvar", "hp": 300.0, "size": Vector2(1, 1), "cost": 12, "time": 2.0, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Yüksek, sağlam duvar (metre başına)."},
	"wire": {"title": "Dikenli Tel", "hp": 100.0, "size": Vector2(1, 1), "cost": 3, "time": 0.6, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Piyadeyi yavaşlatır."},
	"trench": {"title": "Siper Hendeği", "hp": 100.0, "size": Vector2(1, 1), "cost": 4, "time": 1.4, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Her yönden korunma sağlar."},
	"coastal": {"title": "Sahil Topçusu", "hp": 2600.0, "size": Vector2(6, 6), "cost": 550, "time": 45.0, "cap": 0, "sight": 50.0, "prod": [], "desc": "Sabit ağır top: 190 m menzil, araçları ve yığınakları döver."},
	"cache": {"title": "İkmal Sandıkları", "hp": 300.0, "size": Vector2(3, 3), "cost": 0, "time": 1.0, "cap": 0, "sight": 12.0, "prod": [], "desc": "Havadan bırakılan mühimmat paleti; yakındaki askerler ikmal alır, bitince kaybolur."},
	"trap": {"title": "Tank Tuzağı", "hp": 100.0, "size": Vector2(2, 2), "cost": 30, "time": 6.0, "cap": 0, "sight": 10.0, "prod": [], "desc": "Araçları durdurur."},
}

static var PDEF := {
	"rifle_squad": {"title": "Tüfek Timi", "cost": 180, "time": 14.0, "cap": 6, "units": ["leader", "rifle", "rifle", "mg", "rifle", "medic"], "icon": "inf"},
	"mg_team": {"title": "Makineli Tim", "cost": 150, "time": 12.0, "cap": 3, "units": ["mg", "mg", "rifle"], "icon": "mg"},
	"at_squad": {"title": "Tanksavar Timi", "cost": 220, "time": 16.0, "cap": 4, "units": ["at", "at", "at", "rifle"], "icon": "at"},
	"medic_team": {"title": "Sıhhiye Timi", "cost": 90, "time": 9.0, "cap": 2, "units": ["medic", "medic"], "icon": "medic"},
	"sniper_team": {"title": "Keskin Nişancı", "cost": 200, "time": 14.0, "cap": 2, "units": ["sniper", "sniper"], "icon": "inf"},
	"engineer_squad": {"title": "İstihkâm Timi", "cost": 160, "time": 12.0, "cap": 4, "units": ["engineer", "engineer", "engineer", "engineer"], "icon": "inf"},
	"mortar_team": {"title": "Havan Timi", "cost": 210, "time": 15.0, "cap": 3, "units": ["mortar", "mortar", "rifle"], "icon": "inf"},
	"para_squad": {"title": "Paraşütçü Timi", "cost": 300, "time": 20.0, "cap": 8, "units": ["leader", "rifle", "rifle", "mg", "rifle", "at", "medic", "rifle"], "icon": "inf", "para": true},
	"atgm_team": {"title": "Güdümlü Tanksavar Timi", "cost": 260, "time": 16.0, "cap": 3, "units": ["atgm", "atgm", "rifle"], "icon": "at"},
	"drone_team": {"title": "Drone Ekibi", "cost": 190, "time": 14.0, "cap": 2, "units": ["drone", "drone"], "icon": "inf"},
	"ifv": {"title": "Piyade Savaş Aracı", "cost": 480, "time": 24.0, "cap": 3, "vehicle": "ifv", "icon": "apc"},
	"aa": {"title": "Uçaksavar", "cost": 420, "time": 22.0, "cap": 3, "vehicle": "aa", "icon": "aa"},
	"arty": {"title": "Kundağı Motorlu Obüs", "cost": 600, "time": 30.0, "cap": 4, "vehicle": "arty", "icon": "arty"},
	"transport": {"title": "Nakliye Helikopteri", "cost": 520, "time": 28.0, "cap": 3, "vehicle": "transport", "icon": "heli"},
	"technical": {"title": "Teknik Araç", "cost": 160, "time": 14.0, "cap": 2, "vehicle": "technical", "icon": "tech"},
	"apc": {"title": "ZPT", "cost": 380, "time": 22.0, "cap": 3, "vehicle": "apc", "icon": "apc"},
	"tank": {"title": "Tank", "cost": 650, "time": 30.0, "cap": 4, "vehicle": "tank", "icon": "tank"},
	"fieldgun": {"title": "Sahra Topu", "cost": 280, "time": 16.0, "cap": 3, "vehicle": "fieldgun", "icon": "arty"},
	"howitzer": {"title": "Çekili Obüs", "cost": 420, "time": 22.0, "cap": 3, "vehicle": "howitzer", "icon": "arty"},
	"atgun": {"title": "Tanksavar Topu", "cost": 300, "time": 16.0, "cap": 3, "vehicle": "atgun", "icon": "arty"},
	"aagun": {"title": "Uçaksavar Topu", "cost": 240, "time": 14.0, "cap": 2, "vehicle": "aagun", "icon": "aa"},
	"hmortar": {"title": "Ağır Havan", "cost": 220, "time": 12.0, "cap": 2, "vehicle": "hmortar", "icon": "arty"},
	"mtngun": {"title": "Dağ Topu", "cost": 260, "time": 14.0, "cap": 2, "vehicle": "mtngun", "icon": "arty"},
	"mlrs": {"title": "Roketatar", "cost": 700, "time": 32.0, "cap": 4, "vehicle": "mlrs", "icon": "arty"},
	"heli": {"title": "Saldırı Helikopteri", "cost": 800, "time": 36.0, "cap": 5, "vehicle": "heli", "icon": "heli"},
}

var btype := "fob"
var B: Dictionary
var size := Vector2(10, 10)
var rot := 0.0
var done := false
var progress := 0.0
var cap_bonus := 0
var queue: Array = []
var rally := Vector3.ZERO
var model: Node3D
var capture_t := 0.0
var capture_team := -1
var a := Vector3.ZERO      # hat yapıları için uçlar
var b := Vector3.ZERO
var supplied_t := -999.0
# ikmal stoğu (kg): ileri üs mühimmat/onarımı buradan verir, kamyonlar doldurur. Karargâh sınırsız.
const STOCK_MAX := 1500.0
var stock := 400.0
var gun_cd := 0.0
var gun_burst := 0
var gun_target: Unit = null
var gunner: SoldierBody
var gun_pivot: Node3D
var gun_muzzle := Vector3.ZERO
var think_t := 0.0
var bearers: Array = []
var job: Stretcher = null
var inside: Array = []          # hastanedeki askerler: [asker, kalan süre]
var _work_flash := 0.0

func setup(t: int, bt: String, r := 0.0) -> void:
	team = t
	btype = bt
	kind = bt
	B = BDEF[bt]
	title = B["title"]
	max_hp = B["hp"]
	hp = max_hp * 0.15
	size = B["size"]
	rot = r
	sight = B["sight"]
	cap_cost = 0
	icon = "bld"
	radius = maxf(size.x, size.y) * 0.5
	rally = position + Vector3(0, 0, size.y * 0.5 + 5.0).rotated(Vector3.UP, rot)
	_build_model()
	_apply_construct_look()

# katalog birimlerini üretim tablosuna ekle (fabrika: kara, pist: hava)
static func add_catalog() -> void:
	for id in Catalog.units:
		var u: Dictionary = Catalog.units[id]
		var base: String = Catalog.FAM_BASE.get(u["fam"], "")
		if base == "" or PDEF.has(id):
			continue
		var air := base in ["heli", "transport", "uav", "uav_armed", "loiter"]
		var cost := float(u.get("cost", 200))
		PDEF[id] = {"title": u["name"], "cost": int(cost), "time": clampf(cost / 22.0, 8.0, 45.0),
			"cap": 1 if base in ["loiter", "fpv"] else (2 if base in ["technical", "uav", "truck"] else (4 if base in ["tank", "arty", "mlrs", "heli"] else 3)),
			"vehicle": id, "icon": Vehicle.DEF.get(base, {}).get("icon", "tank"), "nation": u["nation"], "cat": u["cat"],
			"producer": "helipad" if air else "factory"}

func can_produce(id: String) -> bool:
	if B["prod"].has(id):
		return true
	var P: Dictionary = PDEF.get(id, {})
	if not P.has("producer") or P["producer"] != btype:
		return false
	return team >= 0 and team < G.nation.size() and P["nation"] == G.nation[team]

func is_base() -> bool:
	return btype == "hq" or btype == "fob"

# stoktan kg çek; yetmezse false
func draw_stock(kg: float) -> bool:
	if btype == "hq" or G.sandbox:
		return true
	if stock < kg:
		return false
	stock -= kg
	if btype == "cache" and stock < 1.0:
		# palet boşaldı: boş sandıklar kalır, yapı kalkar
		alive = false
		G.grid.set_static_rect(position, size, rot, 0.0, Grid.K_NONE, true)
		var tw := create_tween()
		tw.tween_property(self, "scale", Vector3(1, 0.05, 1), 1.5)
		tw.tween_callback(queue_free)
	return true

static var _cache_mesh: Mesh = null

# ikmal paleti: tahta palet, kayışlı yeşil mühimmat sandıkları, üstünde ağ
static func cache_mesh() -> Mesh:
	if _cache_mesh != null:
		return _cache_mesh
	var mb := MB.new()
	var wood := Color(0.52, 0.4, 0.26)
	for i in 3:
		mb.box(Vector3(0, 0.06, -0.55 + i * 0.55), Vector3(1.6, 0.12, 0.14), wood.darkened(0.1))
	for i in 7:
		mb.box(Vector3(-0.69 + i * 0.23, 0.15, 0), Vector3(0.18, 0.04, 1.3), wood)
	var olive := Color(0.32, 0.35, 0.22)
	for lx in 2:
		for lz in 2:
			for ly in 2:
				var c := Vector3(-0.38 + lx * 0.76, 0.35 + ly * 0.38, -0.3 + lz * 0.6)
				mb.box(c, Vector3(0.72, 0.36, 0.56), olive.darkened(0.06 * ((lx + lz + ly) % 2)))
				mb.box(c + Vector3(0, 0.185, 0), Vector3(0.6, 0.02, 0.1), Color(0.2, 0.2, 0.16))
				mb.box(c + Vector3(0.365, 0.0, 0), Vector3(0.02, 0.08, 0.3), Color(0.85, 0.75, 0.2))
	for x in [-0.5, 0.5]:
		mb.box(Vector3(x, 0.55, 0), Vector3(0.05, 0.82, 1.34), Color(0.75, 0.62, 0.2))
	mb.box(Vector3(0, 0.94, 0), Vector3(1.52, 0.02, 1.22), Color(0.25, 0.28, 0.18))
	_cache_mesh = mb.commit(Mats.vcs())
	return _cache_mesh

# üs yakınındaki araçları onar (stoktan): gövde, palet, teker, kritik
func _service_vehicles() -> void:
	for u in G.friends_near(position, radius + 10.0, team):
		if not (u is Vehicle) or u.is_air() or u.vtype == "fpv" or not u.alive:
			continue
		if G.time - u.last_hit < 6.0:
			continue
		var need: bool = u.hp < u.max_hp or u.tracks_broken > 0.0 or u.tires > 0 or u.has_crit()
		if not need or not draw_stock(3.0):
			continue
		u.hp = minf(u.max_hp, u.hp + u.max_hp * 0.02)
		u.tracks_broken = maxf(0.0, u.tracks_broken - 4.0)
		if u.tires > 0 and randf() < 0.2:
			u.tires -= 1
		for ck in u.crit:
			if u.crit[ck] > 0:
				u.crit_t[ck] -= 6.0

func is_line() -> bool:
	return B.get("line", false)

func setup_line(t: int, bt: String, pa: Vector3, pb: Vector3) -> void:
	a = pa
	b = pb
	position = (pa + pb) * 0.5
	team = t
	btype = bt
	kind = bt
	B = BDEF[bt]
	title = B["title"]
	var L := pa.distance_to(pb)
	max_hp = 100.0
	hp = 100.0
	size = Vector2(L, 1.0)
	rot = atan2(-(pb - pa).z, (pb - pa).x)
	sight = 8.0
	radius = L * 0.5
	icon = "bld"
	model = Node3D.new()
	add_child(model)
	var mb := MB.new()
	var dir := (pb - pa).normalized()
	var n := maxi(1, int(L / 0.8))
	for i in n + 1:
		var p := pa.lerp(pb, float(i) / n) - position
		mb.cyl(p, 0.04, 0.04, 0.5, 4, Color(0.55, 0.42, 0.25))
	mb.box(Vector3(0, 0.03, 0), Vector3(L, 0.04, 0.5), Color(0.8, 0.7, 0.4), Basis(Vector3.UP, rot))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vc())
	model.add_child(mi)
	var _d := dir

func build_time() -> float:
	if is_line():
		return maxf(2.0, B["time"] * size.x)
	return B["time"]

func full_cost() -> int:
	if is_line():
		return int(ceil(B["cost"] * size.x))
	return B["cost"]

# ------------------------------------------------------------ model
func _build_model() -> void:
	if model:
		model.queue_free()
	model = Node3D.new()
	model.rotation.y = rot
	if btype == "hq":
		model.scale = Vector3(1.35, 1.25, 1.35)
	add_child(model)
	var mb := MB.new()
	var tc: Color = G.TEAM_COL[team] if team >= 0 else Color(0.8, 0.8, 0.8)
	var winter := G.map_kind == "winter"
	var olive := Color(0.36, 0.38, 0.26) if not winter else Color(0.72, 0.72, 0.66)
	var tan := Color(0.74, 0.66, 0.48)
	var white := Color(0.92, 0.91, 0.87)
	if btype == "cache":
		for k in 3:
			var cm := MeshInstance3D.new()
			cm.mesh = cache_mesh()
			cm.position = [Vector3(-0.7, 0, -0.4), Vector3(0.8, 0, 0.3), Vector3(-0.2, 0, 1.0)][k]
			cm.rotation.y = [0.1, -0.35, 0.6][k]
			model.add_child(cm)
		var chute := MB.new()
		chute.box(Vector3(1.3, 0.08, -1.1), Vector3(1.4, 0.12, 0.9), Color(0.55, 0.55, 0.42))
		_flag(chute, Vector3(-1.2, 0, 1.2), tc, 1.6)
		var cmi := MeshInstance3D.new()
		cmi.mesh = chute.commit(Mats.vcs())
		model.add_child(cmi)
		return
	match btype:
		"hq":
			mb.box(Vector3(0, 2.0, 0), Vector3(12.0, 4.0, 8.0), white)
			mb.box(Vector3(-2.0, 5.2, -0.5), Vector3(6.5, 2.4, 5.5), white.darkened(0.03))
			mb.box(Vector3(0, 4.05, 0), Vector3(12.4, 0.12, 8.4), Color(0.8, 0.79, 0.76))
			mb.box(Vector3(-2.0, 6.45, -0.5), Vector3(6.9, 0.12, 5.9), Color(0.8, 0.79, 0.76))
			for i in 9:
				var x := -5.2 + i * 1.3
				mb.box(Vector3(x, 2.6, -4.01), Vector3(0.7, 0.9, 0.04), Color(0.08, 0.08, 0.09))
				mb.box(Vector3(x, 2.6, 4.01), Vector3(0.7, 0.9, 0.04), Color(0.08, 0.08, 0.09))
				mb.box(Vector3(x, 1.0, 4.01), Vector3(0.7, 0.9, 0.04), Color(0.08, 0.08, 0.09))
			for i in 5:
				mb.box(Vector3(-4.6 + i * 1.3, 5.3, -3.26), Vector3(0.6, 0.8, 0.04), Color(0.08, 0.08, 0.09))
			mb.box(Vector3(0, 1.2, -4.02), Vector3(2.2, 2.4, 0.06), Color(0.15, 0.13, 0.11))
			for i in 4:
				mb.box(Vector3(2.5 + (i % 2) * 1.6, 4.4, -2.0 + (i / 2) * 2.5), Vector3(1.1, 0.6, 0.8), Color(0.7, 0.7, 0.7))
			mb.cyl(Vector3(4.6, 4.1, 2.6), 0.6, 0.6, 1.2, 10, Color(0.85, 0.45, 0.2))
			mb.cyl(Vector3(-4.0, 6.5, 1.2), 0.06, 0.03, 6.0, 4, Color(0.4, 0.4, 0.4))
			mb.sphere(Vector3(0.5, 6.9, 1.2), Vector3(0.6, 0.15, 0.6), 8, 4, Color(0.85, 0.85, 0.85), Basis(Vector3.RIGHT, 0.6), true)
			for sx in [-1.0, 1.0]:
				for z in range(-5, 6):
					mb.box(Vector3(sx * 7.6, 0.45, z * 1.0), Vector3(1.0, 0.9, 1.0), tan.darkened(0.05 * (absi(z) % 2)))
			_flag(mb, Vector3(5.5, 4.1, -3.5), tc, 4.0)
		"fob":
			for i in 16:
				var ang := TAU * i / 16.0
				if i == 4 or i == 5:
					continue
				var p := Vector3(cos(ang) * 4.6, 0.55, sin(ang) * 4.6)
				mb.box(p, Vector3(1.0, 1.1, 1.8), tan.darkened(0.04 * (i % 2)), Basis(Vector3.UP, -ang))
			mb.prism(PackedVector2Array([Vector2(-1.8, 0), Vector2(1.8, 0), Vector2(1.0, 1.9), Vector2(-1.0, 1.9)]), 3.6, olive, Vector3(-0.8, 0, -0.8))
			mb.box(Vector3(1.8, 0.35, 1.6), Vector3(1.2, 0.7, 0.8), Color(0.35, 0.36, 0.24))
			mb.box(Vector3(2.0, 0.35, 0.5), Vector3(1.2, 0.7, 0.8), Color(0.35, 0.36, 0.24))
			mb.box(Vector3(1.9, 0.9, 1.0), Vector3(1.2, 0.4, 0.8), Color(0.3, 0.32, 0.2))
			mb.cyl(Vector3(-2.4, 0, 2.0), 0.04, 0.02, 6.0, 4, Color(0.3, 0.3, 0.3))
			_flag(mb, Vector3(0.8, 0, 2.6), tc, 4.5)
		"barracks":
			for z in [-1.4, 1.4]:
				mb.prism(PackedVector2Array([Vector2(-4.0, 0), Vector2(4.0, 0), Vector2(4.0, 1.4), Vector2(0, 2.6), Vector2(-4.0, 1.4)]), 2.4, olive, Vector3(0, 0, z), Basis(), olive.darkened(0.1))
			mb.box(Vector3(-3.6, 0.4, 3.2), Vector3(1.0, 0.8, 0.8), Color(0.4, 0.36, 0.24))
			_flag(mb, Vector3(4.2, 0, 2.6), tc, 3.5)
		"factory":
			var nseg := 8
			for i in nseg:
				var a0 := PI * i / nseg
				var a1 := PI * (i + 1) / nseg
				var p0 := Vector3(cos(a0) * 5.0, sin(a0) * 4.2, 0)
				var p1 := Vector3(cos(a1) * 5.0, sin(a1) * 4.2, 0)
				var c := Color(0.62, 0.63, 0.6).darkened(0.03 * (i % 2))
				if winter and i > 1 and i < 6:
					c = Color(0.94, 0.95, 0.97)
				mb.quad(p0 + Vector3(0, 0, -4.2), p1 + Vector3(0, 0, -4.2), p1 + Vector3(0, 0, 4.2), p0 + Vector3(0, 0, 4.2), c, Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0))
			var prof := PackedVector2Array()
			for i in nseg + 1:
				prof.append(Vector2(cos(PI * i / nseg) * 5.0, sin(PI * i / nseg) * 4.2))
			mb.prism(prof, 0.1, Color(0.5, 0.5, 0.48), Vector3(0, 0, 4.2))
			mb.box(Vector3(0, 1.6, -4.25), Vector3(5.0, 3.2, 0.1), Color(0.12, 0.12, 0.12))
			mb.box(Vector3(-5.6, 0.6, 0), Vector3(1.2, 1.2, 3.0), Color(0.4, 0.4, 0.38))
			_flag(mb, Vector3(5.6, 0, -4.4), tc, 4.0)
		"helipad":
			mb.box(Vector3(0, 0.06, 0), Vector3(10.5, 0.12, 10.5), Color(0.42, 0.42, 0.4))
			for i in 24:
				var ang := TAU * i / 24.0
				mb.box(Vector3(cos(ang) * 4.2, 0.13, sin(ang) * 4.2), Vector3(0.7, 0.02, 0.2), Color(0.95, 0.85, 0.3), Basis(Vector3.UP, -ang + PI * 0.5))
			mb.box(Vector3(-1.0, 0.13, 0), Vector3(0.35, 0.02, 3.2), Color(0.95, 0.95, 0.92))
			mb.box(Vector3(1.0, 0.13, 0), Vector3(0.35, 0.02, 3.2), Color(0.95, 0.95, 0.92))
			mb.box(Vector3(0, 0.13, 0), Vector3(2.0, 0.02, 0.35), Color(0.95, 0.95, 0.92))
			mb.box(Vector3(5.6, 0.6, 4.6), Vector3(1.2, 1.2, 1.2), Color(0.35, 0.36, 0.24))
			mb.cyl(Vector3(5.6, 0, -4.8), 0.05, 0.05, 3.0, 4, Color(0.6, 0.6, 0.6))
			mb.cyl(Vector3(5.6, 2.6, -4.8), 0.12, 0.3, 0.8, 6, Color(1.0, 0.5, 0.2), Basis(Vector3.FORWARD, PI * 0.5))
			_flag(mb, Vector3(-5.6, 0, -4.8), tc, 3.5)
		"hospital":
			mb.prism(PackedVector2Array([Vector2(-3.2, 0), Vector2(3.2, 0), Vector2(3.2, 1.5), Vector2(0, 2.8), Vector2(-3.2, 1.5)]), 5.0, Color(0.88, 0.88, 0.85), Vector3.ZERO, Basis(), Color(0.8, 0.8, 0.78))
			mb.box(Vector3(0, 2.2, -2.55), Vector3(1.2, 0.35, 0.03), Color(0.8, 0.1, 0.1))
			mb.box(Vector3(0, 2.2, -2.55), Vector3(0.35, 1.2, 0.03), Color(0.8, 0.1, 0.1))
			mb.box(Vector3(0, 2.84, 0), Vector3(1.4, 0.03, 0.4), Color(0.8, 0.1, 0.1))
			for i in 3:
				mb.box(Vector3(-2.5 + i * 2.0, 0.25, 3.4), Vector3(0.6, 0.12, 1.9), Color(0.4, 0.42, 0.3))
			_flag(mb, Vector3(3.6, 0, 3.0), tc, 3.0)
		"mgnest":
			for i in 10:
				var ang := TAU * i / 10.0
				if i == 7:
					continue
				for rr in 2:
					mb.box(Vector3(cos(ang) * 1.7, 0.18 + rr * 0.3, sin(ang) * 1.7), Vector3(0.95, 0.3, 0.5), Color(0.74, 0.65, 0.45).darkened(0.05 * ((i + rr) % 2)), Basis(Vector3.UP, -ang + PI * 0.5))
		"tower":
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					mb.cyl_between(Vector3(sx * 1.2, 0, sz * 1.2), Vector3(sx * 0.9, 5.5, sz * 0.9), 0.1, 0.09, 5, Color(0.42, 0.32, 0.22))
			mb.box(Vector3(0, 5.5, 0), Vector3(2.6, 0.15, 2.6), Color(0.45, 0.35, 0.24))
			for i in 4:
				var ang := PI * 0.5 * i
				mb.box(Vector3(cos(ang) * 1.25, 5.95, sin(ang) * 1.25), Vector3(0.1 if i % 2 == 0 else 2.6, 0.8, 2.6 if i % 2 == 0 else 0.1), Color(0.72, 0.64, 0.44))
			mb.prism(PackedVector2Array([Vector2(-1.6, 7.2), Vector2(1.6, 7.2), Vector2(0, 8.0)]), 3.0, Color(0.38, 0.3, 0.2))
			for sx in [-1.0, 1.0]:
				mb.cyl(Vector3(sx * 0.9, 6.4, 0.9), 0.04, 0.04, 0.8, 4, Color(0.4, 0.3, 0.2))
			_flag(mb, Vector3(1.4, 7.2, 1.4), tc, 1.5)
		"trap":
			for i in 3:
				var bb := Basis(Vector3.UP, i * 2.1) * Basis(Vector3.RIGHT, 0.95)
				mb.box(Vector3(0, 0.55, 0), Vector3(0.14, 1.6, 0.14), Color(0.25, 0.24, 0.22), bb)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vc())
	model.add_child(mi)
	set_layer(model, 1)
	if btype == "coastal":
		var CM := Art.vehicle("coastal", team)
		if not CM.is_empty():
			for hm in CM["hulls"]:
				var hmi := MeshInstance3D.new()
				hmi.mesh = hm[0]
				hmi.position = hm[1]
				model.add_child(hmi)
			gun_pivot = Node3D.new()
			gun_pivot.position = CM["turret_pos"]
			gun_pivot.rotation.y = rot
			add_child(gun_pivot)
			var tmi := MeshInstance3D.new()
			tmi.mesh = CM["turret"]
			gun_pivot.add_child(tmi)
			var bmi := MeshInstance3D.new()
			bmi.mesh = CM["barrel"]
			bmi.position = CM["barrel_pos"]
			gun_pivot.add_child(bmi)
			gun_muzzle = CM["barrel_pos"] + CM["muzzle"]
			set_layer(gun_pivot, 2)
	if btype == "mgnest":
		gun_pivot = Node3D.new()
		gun_pivot.position = Vector3(0, 0, 0.3)
		add_child(gun_pivot)
		var gm := MB.new()
		gm.cyl(Vector3(0, 0, -0.2), 0.03, 0.03, 0.75, 4, Color(0.2, 0.2, 0.2))
		gm.box(Vector3(0, 0.78, -0.6), Vector3(0.1, 0.12, 0.9), Color(0.12, 0.12, 0.12))
		var gmi := MeshInstance3D.new()
		gmi.mesh = gm.commit(Mats.vc())
		gun_pivot.add_child(gmi)
		gunner = SoldierBody.new()
		gunner.position = Vector3(0, 0, 0.2)
		gun_pivot.add_child(gunner)
		gunner.build(team, "mg", winter)
		gunner.weapon.visible = false
		set_layer(gun_pivot, 2)

func _flag(mb: MB, p: Vector3, col: Color, h: float) -> void:
	mb.cyl(p, 0.05, 0.04, h, 5, Color(0.6, 0.6, 0.6))
	mb.quad(p + Vector3(0, h - 0.05, 0), p + Vector3(1.2, h - 0.12, 0.1), p + Vector3(1.2, h - 0.85, 0.1), p + Vector3(0, h - 0.8, 0), col, Vector3(0, 0, 1))
	mb.quad(p + Vector3(0, h - 0.05, 0), p + Vector3(1.2, h - 0.12, 0.1), p + Vector3(1.2, h - 0.85, 0.1), p + Vector3(0, h - 0.8, 0), col.darkened(0.2), Vector3(0, 0, -1))

# inşaat: duvarlar alttan yukarı örülür (kesme shader'ı), çevrede iskele, yanda malzeme yığını;
# işçiler çevrede farklı yerlere dağılır (diz çökerek çakan, ayakta yukarı çakan, malzeme taşıyan).
var scaffold: MeshInstance3D = null
var pile: Node3D = null
var model_h := 3.0
var workers: Array = []
var _reveal: Array = []

func _model_meshes(n: Node, out: Array) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		_model_meshes(c, out)

func _apply_construct_look() -> void:
	if model == null:
		return
	var bs := Vector3(1.35, 1.25, 1.35) if btype == "hq" else Vector3.ONE
	model.scale = bs
	var ms: Array = []
	_model_meshes(model, ms)
	if done or is_line():
		for c in ms:
			c.material_override = null
		_reveal.clear()
		if scaffold:
			for k in 6:
				G.fx.vehicle_dust(position + Vector3(randf_range(-size.x, size.x), 0.3, randf_range(-size.y, size.y)) * 0.6)
			scaffold.queue_free()
			scaffold = null
		if pile:
			pile.queue_free()
			pile = null
		if gun_pivot:
			gun_pivot.visible = done
		return
	if _reveal.is_empty():
		var top := 0.5
		for c in ms:
			if c.mesh == null:
				continue
			var xf := Transform3D()
			var n: Node = c
			while n != model and n is Node3D:
				xf = (n as Node3D).transform * xf
				n = n.get_parent()
			top = maxf(top, (xf * c.mesh.get_aabb()).end.y * bs.y)
		model_h = top
		var lin := Mats.reveal(false)
		var srg := Mats.reveal(true)
		_reveal = [lin, srg]
		for c in ms:
			var m0 = c.mesh.surface_get_material(0) if c.mesh and c.mesh.get_surface_count() > 0 else null
			var is_s: bool = m0 is StandardMaterial3D and (m0 as StandardMaterial3D).vertex_color_is_srgb
			c.material_override = srg if is_s else lin
		_build_scaffold()
		_build_pile()
	var cut := lerpf(0.12, model_h + 0.05, progress)
	for m in _reveal:
		m.set_shader_parameter("cut", cut)
		m.set_shader_parameter("base_y", global_position.y if is_inside_tree() else position.y)
	if scaffold:
		scaffold.scale.y = clampf(progress * 1.4 + 0.35, 0.35, 1.0)
	if pile:
		pile.scale = Vector3.ONE * clampf(1.0 - progress * 0.75, 0.25, 1.0)
	if gun_pivot:
		gun_pivot.visible = false

func _build_scaffold() -> void:
	var mb := MB.new()
	var steel := Color(0.55, 0.56, 0.56)
	var wood := Color(0.6, 0.47, 0.3)
	var H := model_h + 0.9
	var hx := size.x * 0.5 * (1.35 if btype == "hq" else 1.0)
	var hz := size.y * 0.5 * (1.35 if btype == "hq" else 1.0)
	for ring in 2:
		var m := 0.45 + ring * 0.85
		var ax := hx + m
		var az := hz + m
		var corners := [Vector3(-ax, 0, -az), Vector3(ax, 0, -az), Vector3(ax, 0, az), Vector3(-ax, 0, az)]
		for e in 4:
			var a: Vector3 = corners[e]
			var b: Vector3 = corners[(e + 1) % 4]
			var n := maxi(1, int(ceil(a.distance_to(b) / 2.4)))
			for i in n + 1:
				var p := a.lerp(b, float(i) / n)
				mb.cyl_between(p, p + Vector3(0, H, 0), 0.035, 0.035, 5, steel, false)
				mb.box(p + Vector3(0, 0.04, 0), Vector3(0.18, 0.04, 0.18), wood.darkened(0.3))
			var lv := 1.8
			while lv < H:
				mb.cyl_between(a + Vector3(0, lv, 0), b + Vector3(0, lv, 0), 0.03, 0.03, 5, steel, false)
				lv += 1.8
			# çapraz destek (her yüzde bir)
			if ring == 1:
				mb.cyl_between(a + Vector3(0, 0.1, 0), b.lerp(a, 0.5) + Vector3(0, minf(H, 3.6), 0), 0.028, 0.028, 4, steel, false)
	# kalas döşeme (iki sıra arası), her kat
	var lv2 := 1.8
	while lv2 < H:
		for sx in [-1.0, 1.0]:
			mb.box(Vector3(sx * (hx + 0.87), lv2 + 0.04, 0), Vector3(0.8, 0.05, hz * 2.0 + 1.7), wood)
		for sz in [-1.0, 1.0]:
			mb.box(Vector3(0, lv2 + 0.04, sz * (hz + 0.87)), Vector3(hx * 2.0 + 1.7, 0.05, 0.8), wood.darkened(0.06))
		lv2 += 1.8
	scaffold = MeshInstance3D.new()
	scaffold.mesh = mb.commit(Mats.vcs())
	scaffold.rotation.y = rot
	add_child(scaffold)

func _build_pile() -> void:
	pile = Node3D.new()
	add_child(pile)
	pile.position = pile_pos() - position
	pile.rotation.y = rot
	var mb := MB.new()
	var wood := Color(0.6, 0.47, 0.3)
	# kalas destesi
	for l in 4:
		for i in 5:
			mb.box(Vector3(-0.5 + i * 0.25, 0.08 + l * 0.1, 0), Vector3(0.22, 0.08, 2.4), wood.darkened(0.04 * ((i + l) % 3)))
	# tuğla / blok paleti
	for i in 3:
		mb.box(Vector3(1.4, 0.06, -0.5 + i * 0.5), Vector3(1.1, 0.12, 0.12), wood.darkened(0.2))
	for lx in 3:
		for lz in 3:
			for ly in 3:
				mb.box(Vector3(1.05 + lx * 0.36, 0.25 + ly * 0.2, -0.4 + lz * 0.4), Vector3(0.34, 0.19, 0.38), Color(0.62, 0.62, 0.6).darkened(0.05 * ((lx + ly + lz) % 2)))
	# çimento torbaları
	for i in 4:
		mb.box(Vector3(-1.5, 0.1 + (i / 2) * 0.17, -0.4 + (i % 2) * 0.55), Vector3(0.8, 0.16, 0.5), Color(0.78, 0.74, 0.62))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	pile.add_child(mi)

func pile_pos() -> Vector3:
	var hx := size.x * 0.5 * (1.35 if btype == "hq" else 1.0)
	var hz := size.y * 0.5 * (1.35 if btype == "hq" else 1.0)
	return position + Vector3(hx + 3.2, 0, hz * 0.4).rotated(Vector3.UP, rot)

# çevrede en çok 6 işçi yeri: dikdörtgen çevresine eşit aralıklı, iskelenin hemen dışında
func claim_slot(s: Node) -> int:
	for i in workers.size():
		var w = workers[i]
		if w != null and (not is_instance_valid(w) or not w.alive or w.build_site != self):
			workers[i] = null
	var k := workers.find(s)
	if k >= 0:
		return k
	k = workers.find(null)
	if k < 0:
		workers.append(s)
		return workers.size() - 1
	workers[k] = s
	return k

func active_workers() -> int:
	var n := 0
	for w in workers:
		if w != null and is_instance_valid(w) and w.alive and w.build_site == self:
			n += 1
	return n

func slot_pos(k: int) -> Vector3:
	var hx := size.x * 0.5 * (1.35 if btype == "hq" else 1.0) + 0.95
	var hz := size.y * 0.5 * (1.35 if btype == "hq" else 1.0) + 0.95
	if is_line():
		return position
	# öncelik sırası: ön, arka, sağ, sol, ön-sağ, arka-sol ... (farklı yönler)
	var t: float = [0.08, 0.58, 0.33, 0.83, 0.2, 0.7, 0.45, 0.95][k % 8]
	var per := 4.0 * (hx + hz)
	var d := t * per
	var lp: Vector3
	if d < 2.0 * hx:
		lp = Vector3(-hx + d, 0, hz)
	elif d < 2.0 * hx + 2.0 * hz:
		lp = Vector3(hx, 0, hz - (d - 2.0 * hx))
	elif d < 4.0 * hx + 2.0 * hz:
		lp = Vector3(hx - (d - 2.0 * hx - 2.0 * hz), 0, -hz)
	else:
		lp = Vector3(-hx, 0, -hz + (d - 4.0 * hx - 2.0 * hz))
	return G.grid.nearest_free(position + lp.rotated(Vector3.UP, rot), Grid.M_INF, 4)

# yerleştirme önizlemesi: gerçek model (dünyaya eklenmeyen geçici yapıdan)
static func preview_model(t: int, bt: String) -> Node3D:
	var b := Building.new()
	b.team = t
	b.btype = bt
	b.kind = bt
	b.B = BDEF[bt]
	b.size = b.B["size"]
	b.rot = 0.0
	b.done = true
	b._build_model()
	var m := b.model
	b.remove_child(m)
	b.free()
	m.rotation.y = 0.0
	return m

func occupy_grid() -> void:
	var h := 2.5
	match btype:
		"hq":
			h = 4.0
		"fob", "mgnest":
			h = 1.0
		"cache":
			h = 0.95
		"coastal":
			h = 1.1
		"helipad":
			h = 0.0
		"tower":
			h = 0.0
		"trap":
			G.grid.set_static_rect(position, Vector2(2.0, 2.0), rot, 0.0, Grid.K_TRAP)
			return
	if btype == "fob":
		# kum torbası çemberi: içi yürünebilir, kenarı siper
		for i in 16:
			if i == 4 or i == 5:
				continue
			var ang := TAU * i / 16.0
			var p := position + Vector3(cos(ang) * 4.6, 0, sin(ang) * 4.6).rotated(Vector3.UP, rot)
			G.grid.set_static_rect(p, Vector2(1.2, 1.8), -ang + rot, 1.1, Grid.K_BUILDING)
		G.grid.set_static_rect(position + Vector3(-0.8, 0, -0.8).rotated(Vector3.UP, rot), Vector2(3.6, 3.6), rot, 1.9, Grid.K_BUILDING)
		return
	if btype == "mgnest":
		for i in 10:
			if i == 7:
				continue
			var ang := TAU * i / 10.0
			G.grid.set_static_rect(position + Vector3(cos(ang) * 1.7, 0, sin(ang) * 1.7), Vector2(0.95, 0.5), -ang + PI * 0.5, 0.75, Grid.K_BUILDING)
		return
	if h > 0.0:
		G.grid.set_static_rect(position, size, rot, h, Grid.K_BUILDING)

# ------------------------------------------------------------ inşa
func add_work(amount: float) -> void:
	if done or not alive:
		return
	progress = minf(1.0, progress + amount / build_time())
	hp = maxf(hp, max_hp * (0.15 + 0.85 * progress))
	if not is_line() and not _reveal.is_empty():
		var cut := lerpf(0.12, model_h + 0.05, progress)
		for m in _reveal:
			m.set_shader_parameter("cut", cut)
	_work_flash -= amount
	if btype == "trench" and is_line():
		_dig_progress()
	if _work_flash <= 0.0:
		_work_flash = 0.6
		Sfx.play3d("hammer" if btype != "trench" else "crumble", position, -8.0 if btype != "trench" else -14.0, 0.15, 0.2)
		if not is_line():
			_apply_construct_look()
	if progress >= 1.0:
		complete()

func complete() -> void:
	done = true
	progress = 1.0
	G.stats["built"][team] += 1
	if is_line():
		_make_line()
		alive = false
		queue_free()
		return
	hp = max_hp
	cap_bonus = B["cap"]
	_apply_construct_look()
	if is_base() and G.logi:
		G.logi.register_base(self)
	if team == G.player_team and not G.spectate:
		G.say(I18n.s("%s tamamlandı") % I18n.s(title), position, team)
		Sfx.play2d("ui_done", -4.0)

var _dug := 0.0
# siper: kazıldıkça zemin derinleşir, çıkan toprak kenara savrulur
func _dig_progress() -> void:
	var want := snappedf(progress, 0.2)
	if want <= _dug:
		return
	_dug = want
	G.terrain.carve_trench(a, b, 1.5, 1.35 * _dug)
	var dir := (b - a).normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	var sand := G.fx.sand_col.darkened(0.35)
	for i in 10:
		var p := a.lerp(b, randf())
		var sg := -1.0 if randf() < 0.5 else 1.0
		G.fx.emit(Fx.P_STREAK, p, side * sg * randf_range(1.5, 3.0) + Vector3(0, randf_range(2.5, 4.0), 0), randf_range(0.5, 0.8), 0.07, 0.05, 12.0, 0.8, Color(sand.r, sand.g, sand.b, 0.95))

func _make_line() -> void:
	var L := a.distance_to(b)
	match btype:
		"sandbags":
			var from := G.blocks.bpos.size()
			G.blocks.wall_line(a, b, 3, Color(0.73, 0.64, 0.44), Grid.K_WALL, {"len": 0.62, "h": 0.27, "t": 0.42, "type": Blocks.T_SANDBAG, "jit": 0.06})
			G.blocks.commit_runtime(from)
		"concrete":
			var from := G.blocks.bpos.size()
			G.blocks.wall_line(a, b, 2, Color(0.66, 0.66, 0.64), Grid.K_HOUSE, {"len": 1.2, "h": 1.15, "t": 0.45, "type": Blocks.T_CONCRETE, "jit": 0.03})
			G.blocks.commit_runtime(from)
		"wire":
			var mb := MB.new()
			var n := maxi(1, int(L / 0.35))
			var dir := (b - a).normalized()
			var side := Vector3(-dir.z, 0, dir.x)
			for i in n:
				var p := a.lerp(b, (i + 0.5) / n)
				var q := a.lerp(b, (i + 1.0) / n)
				for k in 6:
					var a0 := TAU * k / 6.0
					var a1 := TAU * (k + 1) / 6.0
					var p0 := p + side * cos(a0) * 0.35 + Vector3(0, 0.38 + sin(a0) * 0.35, 0)
					var p1 := p.lerp(q, 0.5) + side * cos(a1) * 0.35 + Vector3(0, 0.38 + sin(a1) * 0.35, 0)
					mb.cyl_between(p0, p1, 0.012, 0.012, 3, Color(0.35, 0.33, 0.3), false)
			var mi := MeshInstance3D.new()
			mi.mesh = mb.commit(Mats.vc())
			G.world.add_child(mi)
			var steps := int(L / 0.5) + 1
			for i in steps + 1:
				var p := a.lerp(b, float(i) / steps)
				var ci := G.grid.idx(p)
				G.grid.kind[ci] = Grid.K_WIRE
				G.grid.refresh([ci])
		"trench":
			G.grid.set_trench(a, b, 1.5)
			G.terrain.carve_trench(a, b, 1.5, 1.35)
			G.terrain.paint_line(a, b, 3.2, 1, 0.7)
			var dir := (b - a).normalized()
			var side := Vector3(-dir.z, 0, dir.x)
			var rotm := Basis(Vector3.UP, atan2(-dir.z, dir.x))
			var mb := MB.new()
			var snow := G.map_kind == "winter"
			var wood := Color(0.47, 0.38, 0.28) if not snow else Color(0.5, 0.45, 0.38)
			var berm := Color(0.92, 0.93, 0.95) if snow else (Color(0.56, 0.45, 0.32) if G.map_kind == "desert" else Color(0.36, 0.3, 0.22))
			var bag := Color(0.68, 0.6, 0.44) if not snow else Color(0.82, 0.8, 0.74)
			var c0 := (a + b) * 0.5
			# taban ızgarası (duckboard): iki kiriş + enine çıtalar
			for sg2 in [-0.3, 0.3]:
				mb.box(side * sg2 + Vector3(0, -1.3, 0), Vector3(L, 0.06, 0.08), wood.darkened(0.3), rotm)
			var nb := maxi(1, int(L / 0.22))
			for i in nb:
				var p := a.lerp(b, (i + 0.5) / nb) - c0
				mb.box(p + Vector3(0, -1.25, 0), Vector3(0.14, 0.04, 0.85), wood.darkened(0.08 * (i % 3)), rotm)
			for sg in [-1.0, 1.0]:
				var off: Vector3 = side * float(sg) * 0.74
				# yatay kalaslar (aralıklı, hafif renk farkı) — hafif içe yatık
				for row in 5:
					var y := -1.2 + row * 0.27
					var tone := wood.darkened(0.05 * ((row * 7) % 3)).lightened(0.04 * (row % 2))
					mb.box(off + side * sg * (row * 0.025) + Vector3(0, y, 0), Vector3(L, 0.22, 0.05), tone, rotm * Basis(Vector3.FORWARD, -sg * 0.08))
				# dikmeler (yuvarlak kazık)
				var np := maxi(1, int(L / 1.4))
				for i in np + 1:
					var p := a.lerp(b, float(i) / np) - c0 + off * 1.03
					mb.cyl(p + Vector3(0, -0.6, 0), 0.06, 0.06, 1.55, 6, wood.darkened(0.25))
				# kum torbası korkuluk (ön kenar)
				var nbag := maxi(1, int(L / 0.55))
				for i in nbag:
					var p2: Vector3 = a.lerp(b, (i + 0.5) / nbag) - c0 + side * sg * 0.98
					var j := Vector3(randf_range(-0.03, 0.03), 0, randf_range(-0.03, 0.03))
					mb.box(p2 + j + Vector3(0, 0.12, 0), Vector3(0.5, 0.2, 0.32), bag.darkened(randf_range(0.0, 0.12)), rotm * Basis(Vector3.UP, randf_range(-0.12, 0.12)))
					if i % 2 == 0:
						mb.box(p2 + j + Vector3(0.0, 0.31, 0) + dir * 0.27, Vector3(0.5, 0.18, 0.3), bag.darkened(randf_range(0.0, 0.12)), rotm * Basis(Vector3.UP, randf_range(-0.12, 0.12)))
				# çıkan toprak seti: yuvarlatılmış, dış yana yayılan
				mb.prism(PackedVector2Array([Vector2(-0.9, -0.06), Vector2(0.9, -0.06), Vector2(0.6, 0.18), Vector2(0.25, 0.32), Vector2(-0.15, 0.3), Vector2(-0.55, 0.16)]), L + 0.8, berm, off + side * sg * 0.95, rotm * Basis(Vector3.UP, PI * 0.5))
			var mi := MeshInstance3D.new()
			mi.mesh = mb.commit(Mats.vcs())
			mi.position = c0
			G.world.add_child(mi)

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not G.running or dt <= 0.0 or not alive:
		return
	tick_bubble(dt)
	if not done:
		return
	if btype == "hospital":
		_hospital(dt)
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.5
		_think()
	_production(dt)
	if btype == "mgnest":
		_mg(dt)
	elif btype == "coastal" and gun_pivot:
		_coastal(dt)

func _think() -> void:
	if btype == "fob" or btype == "hq":
		_capture(0.5)
		if done:
			_service_vehicles()
	if btype == "hospital":
		for u in G.friends_near(position, 12.0, team):
			if u is Soldier and u.can_fight() and u.hp < u.max_hp:
				u.hp = minf(u.max_hp, u.hp + 6.0)
		_bearers()

func _capture(dt: float) -> void:
	var mine := 0
	var other := 0
	var other_team := -1
	for u in G.near(position, 13.0):
		if not u.alive or not (u is Soldier) or not u.can_fight():
			continue
		if u.team == team:
			mine += 1
		else:
			other += 1
			other_team = u.team
	if other > 0 and mine == 0:
		if capture_team != other_team:
			capture_team = other_team
			capture_t = 0.0
		capture_t += dt
		if capture_t >= capture_time():
			_flip(other_team)
	else:
		capture_t = maxf(0.0, capture_t - dt * 2.0)

func capture_time() -> float:
	return 25.0 if btype == "hq" else 10.0

func _flip(t: int) -> void:
	var old := team
	if G.logi:
		G.logi.base_lost(self)
	team = t
	capture_t = 0.0
	queue.clear()
	_build_model()
	_apply_construct_look()
	if G.logi:
		G.logi.register_base(self)
	G.say((I18n.s("%s ele geçirildi!") % I18n.s(title)) if t == G.player_team else (I18n.s("%s kaybedildi!") % I18n.s(title)), position, t)
	G.say((I18n.s("%s kaybedildi!") % I18n.s(title)), position, old)
	Sfx.play2d("ui_alert", -2.0)
	G.check_victory()

func door_pos() -> Vector3:
	return position + Vector3(0, 0, size.y * 0.5 + 2.0).rotated(Vector3.UP, rot)

func admit(p: Soldier) -> void:
	if p == null or not is_instance_valid(p):
		return
	p.enter_hospital(self)
	inside.append([p, 16.0 if p.alive else 26.0])

func _hospital(dt: float) -> void:
	if job != null and not job.update(dt):
		job = null
	var i := inside.size() - 1
	while i >= 0:
		var e: Array = inside[i]
		if not is_instance_valid(e[0]):
			inside.remove_at(i)
		else:
			e[1] -= dt
			if e[1] <= 0.0:
				e[0].leave_hospital(door_pos() + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1, 1)))
				inside.remove_at(i)
		i -= 1

func _assign_stretcher() -> void:
	if job != null or bearers.size() < 2:
		return
	for b in bearers:
		if not b.can_fight() or b.state == "stretcher" or b.job != null:
			return
	var best: Soldier = null
	var bs := 1e9
	for u in G.units:
		if not is_instance_valid(u) or not (u is Soldier) or u.team != team or u.bearer:
			continue
		var d: float = u.dist2(self)
		if d > 62.0:
			continue
		var sc := d
		if u.alive:
			if u.state != "wounded" or u.rescuer != null:
				continue
			sc -= 30.0
		else:
			if u.carried or G.time - u.died_at < 1.5 or G.time - u.died_at > 120.0 or u.state == "hospital" or u.loot < 0:
				continue
		if sc < bs:
			bs = sc
			best = u
	if best != null:
		job = Stretcher.new(self, bearers[0], bearers[1], best)

func _bearers() -> void:
	# sahra hastanesi: iki sıhhiye eri (sedyeci) bulundurur; yaralıları onlar sürükleyip tedavi eder
	bearers = bearers.filter(func(x): return is_instance_valid(x) and x.alive)
	if bearers.size() < 2 and G.time - supplied_t > 45.0:
		supplied_t = G.time
		var door := G.grid.nearest_free(position + Vector3(0, 0, size.y * 0.5 + 2.0).rotated(Vector3.UP, rot), Grid.M_INF)
		var sq := Squad.new(team, "Sedyeciler")
		G.squads.append(sq)
		for i in 2 - bearers.size():
			var s: Soldier = G.main.spawn_soldier(team, "medic", door + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), sq)
			s.cap_cost = 0
			s.bearer = true
			s.fire_mode = 2
			s.grenades = 0
			s.smoke_nades = 0
			bearers.append(s)
	_assign_stretcher()
	for b in bearers:
		if b.state == "idle" and b.dist2(self) > 14.0 and b.patient == null and b.job == null:
			b.cmd_move(position + Vector3(randf_range(-4, 4), 0, size.y * 0.5 + 3.0).rotated(Vector3.UP, rot))

func _production(dt: float) -> void:
	if queue.is_empty():
		return
	var item: Dictionary = queue[0]
	var P: Dictionary = PDEF[item["id"]]
	if G.cap_used[team] + P["cap"] > G.cap_max[team]:
		item["blocked"] = true
		return
	item["blocked"] = false
	item["t"] += dt * (6.0 if G.deploy_t > 0.0 else 1.0)
	if item["t"] >= P["time"]:
		queue.pop_front()
		_spawn(item["id"])

func enqueue(id: String) -> bool:
	var P: Dictionary = PDEF[id]
	if not can_produce(id):
		return false
	if not done or queue.size() >= 6 or G.supply[team] < P["cost"]:
		return false
	G.supply[team] -= P["cost"]
	queue.append({"id": id, "t": 0.0, "blocked": false})
	return true

func cancel_last() -> void:
	if queue.is_empty():
		return
	var it: Dictionary = queue.pop_back()
	G.supply[team] += PDEF[it["id"]]["cost"]

func _spawn(id: String) -> void:
	var P: Dictionary = PDEF[id]
	var door := position + Vector3(0, 0, size.y * 0.5 + 2.0).rotated(Vector3.UP, rot)
	door = G.grid.nearest_free(door, Grid.M_INF)
	if P.has("vehicle"):
		var vbase: String = Catalog.base(P["vehicle"]) if Catalog.has(P["vehicle"]) else P["vehicle"]
		var sp := position if vbase in ["heli", "transport", "uav", "uav_armed", "loiter"] else G.grid.nearest_free(door + Vector3(0, 0, 2).rotated(Vector3.UP, rot), Grid.M_HEAVY)
		var v: Vehicle = G.main.spawn_vehicle(team, P["vehicle"], sp, rot + PI)
		v.cmd_move(rally)
		if team == G.player_team and not G.spectate:
			G.say(I18n.s("%s hazır") % I18n.s(P["title"]), door, team)
	elif P.get("para", false):
		# hava indirme: uçak toplanma noktasının üstünden geçerken atlarlar
		var sqp := Squad.new(team, P["title"])
		G.squads.append(sqp)
		Paradrop.launch(team, rally, P["units"], sqp, float(P["cost"]) / P["units"].size())
		if team == G.player_team and not G.spectate:
			G.say(I18n.s("%s hazır") % I18n.s(P["title"]), door, team)
	else:
		var sq := Squad.new(team, P["title"])
		G.squads.append(sq)
		var units: Array = P["units"]
		for i in units.size():
			var s: Soldier = G.main.spawn_soldier(team, units[i], door + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)), sq)
			s.cost_share = float(P["cost"]) / units.size()
			var off := Vector3((i % 3 - 1) * 1.5, 0, (i / 3) * 1.5)
			s.cmd_move(rally + off)
		if team == G.player_team and not G.spectate:
			G.say(I18n.s("%s hazır") % I18n.s(P["title"]), door, team)
	if team == G.player_team and not G.spectate:
		Sfx.play2d("ui_done", -6.0)

func _coastal(dt: float) -> void:
	gun_cd -= dt
	if gun_target == null or not is_instance_valid(gun_target) or not gun_target.alive or randf() < 0.01:
		gun_target = null
		var best := 1e9
		for e in G.enemies_near(position, 190.0, team):
			if not G.is_seen(e, team) or (e is Vehicle and e.is_air()):
				continue
			var d := dist2(e)
			if d < 25.0:
				continue
			var sc := d - (60.0 if e is Vehicle else 0.0) - G.enemies_near(e.position, 8.0, team).size() * 6.0
			if sc < best:
				best = sc
				gun_target = e
	if gun_target == null:
		return
	var want := Soldier._yaw_of(gun_target.position - position)
	gun_pivot.rotation.y = rotate_toward(gun_pivot.rotation.y, want, dt * 0.35)
	if gun_cd > 0.0 or absf(angle_difference(gun_pivot.rotation.y, want)) > 0.06:
		return
	gun_cd = 9.0
	var mp := gun_pivot.global_transform * gun_muzzle
	var d2 := dist2(gun_target)
	var err := d2 * 0.04 + 2.0
	G.bal.artillery(mp, gun_target.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self)
	G.fx.cannon_blast(mp, (gun_target.position - mp).normalized())
	Sfx.play3d("tank_fire", mp, 8.0)
	G.cam.shake(0.25, position)

func _mg(dt: float) -> void:
	gun_cd -= dt
	if gunner:
		gunner.animate(dt, "aim" if gun_target != null else "stand", 0.0)
	if gun_target == null or not is_instance_valid(gun_target) or not gun_target.alive or randf() < 0.02:
		gun_target = null
		var best := 1e9
		for e in G.enemies_near(position, 46.0, team):
			if e is Soldier and e.can_fight() and G.is_seen(e, team):
				var d := dist2(e)
				if d < best and G.grid.los(position + Vector3(0, 1.4, 0), e.aim_point(), 2.2, 0.3):
					best = d
					gun_target = e
	if gun_target == null:
		return
	var dvec := gun_target.position - position
	gun_pivot.rotation.y = rotate_toward(gun_pivot.rotation.y, Soldier._yaw_of(dvec), dt * 3.0)
	if gun_cd > 0.0:
		return
	if gun_burst <= 0:
		gun_burst = randi_range(6, 12)
	gun_burst -= 1
	gun_cd = 0.09 if gun_burst > 0 else randf_range(0.6, 1.3)
	var mp := gun_pivot.global_transform * Vector3(0, 0.8, -1.05)
	var tp := gun_target.aim_point()
	var dir := (tp - mp).normalized()
	G.fx.muzzle(mp, dir, true)
	Sfx.play3d("mg", mp, 0.0, 0.08, 0.03)
	var c := 0.4 * (1.0 - clampf(mp.distance_to(tp) / 50.0, 0.0, 1.0) * 0.6)
	c *= [1.0, 0.72, 0.45][gun_target.stance]
	c *= 1.0 - G.grid.cover_factor(gun_target.position, gun_target.torso_h(), position) * 0.78
	var impact := tp
	if randf() < c:
		gun_target.take_damage(20.0, self, "bullet")
	else:
		var side := Vector3(-dir.z, 0, dir.x)
		impact = tp + side * randf_range(-1.4, 1.4) + dir * randf_range(-0.5, 3.0)
		impact.y = 0.02
		G.fx.impact(impact, "dirt")
		for o in G.near(impact, 2.6):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(11.0, position)
	if randi() % 2 == 0:
		G.fx.tracer(mp, impact, 250.0)

# ------------------------------------------------------------ hasar
func take_damage(amount: float, src, k := "bullet") -> void:
	if not alive:
		return
	var m := 1.0
	match k:
		"bullet", "hmg", "crush":
			m = 0.0
		"grenade":
			m = 0.5
		"auto":
			m = 0.6
	if m <= 0.0:
		return
	hp -= amount * m
	last_hit = G.time
	if src != null and is_instance_valid(src):
		attacker = src
	if team == G.player_team and randf() < 0.1 and not G.spectate:
		G.say(I18n.s("%s saldırı altında!") % I18n.s(title), position, team)
	if hp <= 0.0:
		destroy(src)

func destroy(src) -> void:
	for e in inside:
		if is_instance_valid(e[0]):
			e[0].vanish()
	inside.clear()
	if not alive:
		return
	alive = false
	G.credit_kill(src, self)
	if selected and G.player:
		G.player.deselect(self)
	if is_base() and done and G.logi:
		G.logi.base_lost(self)
	G.explode(position + Vector3(0, 1.0, 0), radius * 0.8 + 2.0, 50.0, "big", team, self)
	G.fx.burn(position + Vector3(0, 1.5, 0), 40.0, minf(radius * 0.4, 2.0))
	G.fx.dust_burst(position, radius)
	G.fx.scorch(position, radius * 2.2)
	if gun_pivot:
		gun_pivot.visible = false
	for c in model.get_children():
		if c is MeshInstance3D:
			c.material_override = Mats.burnt()
	var tw := create_tween()
	tw.tween_property(model, "scale", Vector3(1.05, 0.25, 1.05), 1.2).set_ease(Tween.EASE_IN)
	for i in int(radius * 4):
		G.blocks._add_rubble(position + Vector3(randf_range(-radius, radius), 0, randf_range(-radius, radius)) * 0.8, Vector3(0.6, 0.45, 0.5) * randf_range(0.7, 1.3), Color(0.8, 0.78, 0.72))
	queue.clear()
	if team == G.player_team and not G.spectate:
		G.say(I18n.s("%s yok edildi!") % I18n.s(title), position, team)
	G.check_victory()
