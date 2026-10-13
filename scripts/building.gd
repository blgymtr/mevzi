class_name Building extends Unit
# Yapılar: karargâh, ileri üs, kışla, fabrika, hastane, MG yuvası, kule ve hat yapıları.

const BDEF := {
	"hq": {"title": "Karargâh", "hp": 3200.0, "size": Vector2(17, 13), "cost": 0, "time": 1.0, "cap": 40, "sight": 46.0, "prod": ["rifle_squad", "medic_team"], "desc": "Ana üs. Kaybedilirse ve ileri üs kalmazsa savaş biter."},
	"fob": {"title": "İleri Üs", "hp": 1800.0, "size": Vector2(10, 10), "cost": 300, "time": 40.0, "cap": 12, "sight": 40.0, "prod": ["rifle_squad", "medic_team"], "desc": "Birlik sınırını artırır, mühimmat verir, yol ve ikmal kamyonu getirir. Ele geçirilebilir."},
	"barracks": {"title": "Kışla", "hp": 1200.0, "size": Vector2(9, 6), "cost": 250, "time": 30.0, "cap": 0, "sight": 30.0, "prod": ["rifle_squad", "mg_team", "at_squad", "medic_team", "sniper_team", "engineer_squad", "mortar_team", "drone_team"], "desc": "Tüm piyade timlerini eğitir."},
	"factory": {"title": "Araç Fabrikası", "hp": 1600.0, "size": Vector2(12, 9), "cost": 400, "time": 45.0, "cap": 0, "sight": 30.0, "prod": ["technical", "apc", "ifv", "aa", "tank", "arty"], "desc": "Teknik araç, ZPT ve tank üretir."},
	"helipad": {"title": "Helikopter Pisti", "hp": 900.0, "size": Vector2(11, 11), "cost": 450, "time": 40.0, "cap": 0, "sight": 32.0, "prod": ["heli", "transport"], "desc": "Saldırı helikopteri üretir."},
	"hospital": {"title": "Sahra Hastanesi", "hp": 700.0, "size": Vector2(7, 6), "cost": 180, "time": 22.0, "cap": 0, "sight": 28.0, "prod": [], "desc": "Sedyeciler 45 m içindeki yaralıları toplar; yakındakiler iyileşir."},
	"mgnest": {"title": "MG Yuvası", "hp": 600.0, "size": Vector2(4, 4), "cost": 120, "time": 18.0, "cap": 0, "sight": 46.0, "prod": [], "desc": "Kum torbalı sabit makineli tüfek."},
	"tower": {"title": "Gözetleme Kulesi", "hp": 400.0, "size": Vector2(3, 3), "cost": 90, "time": 15.0, "cap": 0, "sight": 85.0, "prod": [], "desc": "Geniş görüş alanı."},
	"sandbags": {"title": "Kum Torbası", "hp": 200.0, "size": Vector2(1, 1), "cost": 6, "time": 1.2, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Alçak siper (metre başına)."},
	"concrete": {"title": "Beton Duvar", "hp": 300.0, "size": Vector2(1, 1), "cost": 12, "time": 2.0, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Yüksek, sağlam duvar (metre başına)."},
	"wire": {"title": "Dikenli Tel", "hp": 100.0, "size": Vector2(1, 1), "cost": 3, "time": 0.6, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Piyadeyi yavaşlatır."},
	"trench": {"title": "Siper Hendeği", "hp": 100.0, "size": Vector2(1, 1), "cost": 4, "time": 1.4, "cap": 0, "sight": 10.0, "prod": [], "line": true, "desc": "Her yönden korunma sağlar."},
	"trap": {"title": "Tank Tuzağı", "hp": 100.0, "size": Vector2(2, 2), "cost": 30, "time": 6.0, "cap": 0, "sight": 10.0, "prod": [], "desc": "Araçları durdurur."},
}

const PDEF := {
	"rifle_squad": {"title": "Tüfek Timi", "cost": 180, "time": 14.0, "cap": 6, "units": ["rifle", "rifle", "rifle", "mg", "rifle", "rifle"], "icon": "inf"},
	"mg_team": {"title": "Makineli Tim", "cost": 150, "time": 12.0, "cap": 3, "units": ["mg", "mg", "rifle"], "icon": "mg"},
	"at_squad": {"title": "Tanksavar Timi", "cost": 220, "time": 16.0, "cap": 4, "units": ["at", "at", "at", "rifle"], "icon": "at"},
	"medic_team": {"title": "Sıhhiye Timi", "cost": 90, "time": 9.0, "cap": 2, "units": ["medic", "medic"], "icon": "medic"},
	"sniper_team": {"title": "Keskin Nişancı", "cost": 200, "time": 14.0, "cap": 2, "units": ["sniper", "sniper"], "icon": "inf"},
	"engineer_squad": {"title": "İstihkâm Timi", "cost": 160, "time": 12.0, "cap": 4, "units": ["engineer", "engineer", "engineer", "engineer"], "icon": "inf"},
	"mortar_team": {"title": "Havan Timi", "cost": 210, "time": 15.0, "cap": 3, "units": ["mortar", "mortar", "rifle"], "icon": "inf"},
	"drone_team": {"title": "Drone Ekibi", "cost": 190, "time": 14.0, "cap": 2, "units": ["drone", "drone"], "icon": "inf"},
	"ifv": {"title": "Piyade Savaş Aracı", "cost": 480, "time": 24.0, "cap": 3, "vehicle": "ifv", "icon": "apc"},
	"aa": {"title": "Uçaksavar", "cost": 420, "time": 22.0, "cap": 3, "vehicle": "aa", "icon": "aa"},
	"arty": {"title": "Obüs", "cost": 600, "time": 30.0, "cap": 4, "vehicle": "arty", "icon": "arty"},
	"transport": {"title": "Nakliye Helikopteri", "cost": 520, "time": 28.0, "cap": 3, "vehicle": "transport", "icon": "heli"},
	"technical": {"title": "Teknik Araç", "cost": 160, "time": 14.0, "cap": 2, "vehicle": "technical", "icon": "tech"},
	"apc": {"title": "ZPT", "cost": 380, "time": 22.0, "cap": 3, "vehicle": "apc", "icon": "apc"},
	"tank": {"title": "Tank", "cost": 650, "time": 30.0, "cap": 4, "vehicle": "tank", "icon": "tank"},
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
var gun_cd := 0.0
var gun_burst := 0
var gun_target: Unit = null
var gunner: SoldierBody
var gun_pivot: Node3D
var think_t := 0.0
var bearers: Array = []
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

func is_base() -> bool:
	return btype == "hq" or btype == "fob"

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

func _apply_construct_look() -> void:
	if model == null:
		return
	for c in model.get_children():
		if c is MeshInstance3D:
			c.material_override = null if done else Mats.construct()
	var bs := Vector3(1.35, 1.25, 1.35) if btype == "hq" else Vector3.ONE
	model.scale = bs if done else Vector3(bs.x, bs.y * lerpf(0.25, 1.0, progress), bs.z)
	if gunner:
		gun_pivot.visible = done

func occupy_grid() -> void:
	var h := 2.5
	match btype:
		"hq":
			h = 4.0
		"fob", "mgnest":
			h = 1.0
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
	_work_flash -= amount
	if _work_flash <= 0.0:
		_work_flash = 0.6
		Sfx.play3d("hammer", position, -8.0, 0.15, 0.2)
		if not is_line():
			model.scale = Vector3(1, lerpf(0.25, 1.0, progress), 1)
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
		G.say("%s tamamlandı" % title, position, team)
		Sfx.play2d("ui_done", -4.0)

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
			G.grid.set_trench(a, b, 1.3)
			G.terrain.paint_line(a, b, 1.5, 2, 0.35)
			G.terrain.paint_line(a, b, 1.0, 1, 0.9)
			var from := G.blocks.bpos.size()
			var dir := (b - a).normalized()
			var side := Vector3(-dir.z, 0, dir.x)
			G.blocks.wall_line(a + side * 0.95, b + side * 0.95, 1, Color(0.7, 0.62, 0.44), Grid.K_WALL, {"len": 0.62, "h": 0.25, "t": 0.4, "type": Blocks.T_SANDBAG, "solid": false})
			G.blocks.commit_runtime(from)
			var mb := MB.new()
			mb.box(Vector3.ZERO, Vector3(L, 0.02, 1.1), Color(0.25, 0.2, 0.14), Basis(Vector3.UP, atan2(-dir.z, dir.x)))
			var mi := MeshInstance3D.new()
			mi.mesh = mb.commit(Mats.vc())
			mi.position = (a + b) * 0.5 + Vector3(0, 0.02, 0)
			G.world.add_child(mi)

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not G.running or dt <= 0.0 or not alive:
		return
	tick_bubble(dt)
	if not done:
		return
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.5
		_think()
	_production(dt)
	if btype == "mgnest":
		_mg(dt)

func _think() -> void:
	if btype == "fob" or btype == "hq":
		_capture(0.5)
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
	G.say(("%s ele geçirildi!" % title) if t == G.player_team else ("%s kaybedildi!" % title), position, t)
	G.say(("%s kaybedildi!" % title), position, old)
	Sfx.play2d("ui_alert", -2.0)
	G.check_victory()

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
			bearers.append(s)
	for b in bearers:
		if b.state == "idle" and b.dist2(self) > 14.0 and b.patient == null:
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
	item["t"] += dt
	if item["t"] >= P["time"]:
		queue.pop_front()
		_spawn(item["id"])

func enqueue(id: String) -> bool:
	var P: Dictionary = PDEF[id]
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
		var sp := position if P["vehicle"] in ["heli", "transport"] else G.grid.nearest_free(door + Vector3(0, 0, 2).rotated(Vector3.UP, rot), Grid.M_HEAVY)
		var v: Vehicle = G.main.spawn_vehicle(team, P["vehicle"], sp, rot + PI)
		v.cmd_move(rally)
		if team == G.player_team and not G.spectate:
			G.say("%s hazır" % P["title"], door, team)
	else:
		var sq := Squad.new(team, P["title"])
		G.squads.append(sq)
		var units: Array = P["units"]
		for i in units.size():
			var s: Soldier = G.main.spawn_soldier(team, units[i], door + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)), sq)
			var off := Vector3((i % 3 - 1) * 1.5, 0, (i / 3) * 1.5)
			s.cmd_move(rally + off)
		if team == G.player_team and not G.spectate:
			G.say("%s hazır" % P["title"], door, team)
	if team == G.player_team and not G.spectate:
		Sfx.play2d("ui_done", -6.0)

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
		G.say("%s saldırı altında!" % title, position, team)
	if hp <= 0.0:
		destroy(src)

func destroy(src) -> void:
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
		G.say("%s yok edildi!" % title, position, team)
	G.check_victory()
