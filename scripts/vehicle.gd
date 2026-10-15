class_name Vehicle extends Unit
# Araçlar: tank, ZPT, makineli pikap, ikmal kamyonu.

const DEF := {
	"tank": {"title": "Tank", "hp": 900.0, "armor": 2, "speed": 6.2, "accel": 2.5, "turn": 0.75, "radius": 2.7, "len": 6.2, "nav": Grid.M_HEAVY, "sight": 50.0, "cap": 4, "tturn": 0.85, "icon": "tank"},
	"apc": {"title": "ZPT", "hp": 450.0, "armor": 1, "speed": 9.5, "accel": 3.5, "turn": 1.0, "radius": 2.5, "len": 7.2, "nav": Grid.M_HEAVY, "sight": 48.0, "cap": 3, "tturn": 1.8, "icon": "apc"},
	"technical": {"title": "Teknik Araç", "hp": 170.0, "armor": 0, "speed": 13.0, "accel": 5.0, "turn": 1.4, "radius": 1.9, "len": 5.0, "nav": Grid.M_LIGHT, "sight": 46.0, "cap": 2, "tturn": 3.0, "icon": "tech"},
	"heli": {"title": "Saldırı Helikopteri", "hp": 650.0, "armor": 1, "speed": 17.0, "accel": 6.0, "turn": 1.4, "radius": 3.6, "len": 11.0, "nav": Grid.M_LIGHT, "sight": 62.0, "cap": 5, "tturn": 0.0, "icon": "heli"},
	"ifv": {"title": "Piyade Savaş Aracı", "hp": 620.0, "armor": 1, "speed": 8.0, "accel": 3.0, "turn": 0.9, "radius": 2.6, "len": 6.8, "nav": Grid.M_HEAVY, "sight": 50.0, "cap": 3, "tturn": 1.5, "icon": "apc"},
	"aa": {"title": "Uçaksavar", "hp": 480.0, "armor": 1, "speed": 7.5, "accel": 2.8, "turn": 0.9, "radius": 2.6, "len": 6.6, "nav": Grid.M_HEAVY, "sight": 70.0, "cap": 3, "tturn": 2.4, "icon": "aa"},
	"arty": {"title": "Kundağı Motorlu Obüs", "hp": 420.0, "armor": 1, "speed": 6.0, "accel": 2.2, "turn": 0.7, "radius": 2.8, "len": 7.0, "nav": Grid.M_HEAVY, "sight": 34.0, "cap": 4, "tturn": 0.6, "icon": "arty"},
	"transport": {"title": "Nakliye Helikopteri", "hp": 520.0, "armor": 1, "speed": 20.0, "accel": 6.0, "turn": 1.3, "radius": 4.0, "len": 12.0, "nav": Grid.M_LIGHT, "sight": 50.0, "cap": 3, "tturn": 0.0, "icon": "heli"},
	"uav": {"title": "Keşif İHA", "hp": 120.0, "armor": 0, "speed": 14.0, "accel": 4.0, "turn": 0.8, "radius": 2.6, "len": 6.0, "nav": Grid.M_LIGHT, "sight": 85.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"uav_armed": {"title": "Silahlı İHA", "hp": 180.0, "armor": 0, "speed": 15.0, "accel": 4.0, "turn": 0.7, "radius": 3.0, "len": 8.0, "nav": Grid.M_LIGHT, "sight": 80.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"loiter": {"title": "Kamikaze İHA", "hp": 30.0, "armor": 0, "speed": 24.0, "accel": 14.0, "turn": 3.0, "radius": 0.8, "len": 1.5, "nav": Grid.M_LIGHT, "sight": 50.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"fpv": {"title": "FPV Drone", "hp": 22.0, "armor": 0, "speed": 21.0, "accel": 16.0, "turn": 4.0, "radius": 0.6, "len": 0.5, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 0, "tturn": 0.0, "icon": "fpv"},
	"fieldgun": {"title": "Sahra Topu", "hp": 360.0, "armor": 0, "speed": 1.6, "accel": 1.5, "turn": 0.6, "radius": 1.6, "len": 4.0, "nav": Grid.M_LIGHT, "sight": 40.0, "cap": 3, "tturn": 0.7, "icon": "arty"},
	"howitzer": {"title": "Çekili Obüs", "hp": 380.0, "armor": 0, "speed": 1.1, "accel": 1.0, "turn": 0.45, "radius": 2.0, "len": 5.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 3, "tturn": 0.45, "icon": "arty"},
	"atgun": {"title": "Tanksavar Topu", "hp": 300.0, "armor": 0, "speed": 1.5, "accel": 1.5, "turn": 0.7, "radius": 1.5, "len": 4.0, "nav": Grid.M_LIGHT, "sight": 44.0, "cap": 3, "tturn": 0.8, "icon": "arty"},
	"aagun": {"title": "Uçaksavar Topu", "hp": 260.0, "armor": 0, "speed": 1.7, "accel": 1.6, "turn": 0.8, "radius": 1.6, "len": 3.6, "nav": Grid.M_LIGHT, "sight": 62.0, "cap": 2, "tturn": 2.6, "icon": "aa"},
	"hmortar": {"title": "Ağır Havan", "hp": 200.0, "armor": 0, "speed": 1.3, "accel": 1.4, "turn": 1.0, "radius": 1.2, "len": 2.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 2, "tturn": 1.2, "icon": "arty"},
	"mtngun": {"title": "Dağ Topu", "hp": 240.0, "armor": 0, "speed": 2.3, "accel": 2.0, "turn": 0.9, "radius": 1.3, "len": 3.0, "nav": Grid.M_LIGHT, "sight": 34.0, "cap": 2, "tturn": 0.9, "icon": "arty"},
	"mlrs": {"title": "Roketatar", "hp": 320.0, "armor": 0, "speed": 10.0, "accel": 3.0, "turn": 1.0, "radius": 2.3, "len": 7.0, "nav": Grid.M_LIGHT, "sight": 32.0, "cap": 4, "tturn": 0.6, "icon": "arty"},
	"truck": {"title": "İkmal Kamyonu", "hp": 160.0, "armor": 0, "speed": 10.0, "accel": 3.0, "turn": 1.0, "radius": 2.3, "len": 7.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 0, "tturn": 0.0, "icon": "truck"},
}

var vtype := "tank"
var D: Dictionary
var hull: Node3D
var hull_mi: MeshInstance3D
var turret: Node3D
var barrel: Node3D
var wheels: Array = []
var gunner: SoldierBody
var M: Dictionary
var armor := 0
var ext := Vector2(1.5, 3.0)   # zemin izi yarı boyutları (genişlik, uzunluk) — modelden
var deployed := 1.0       # topçu kurulum durumu: 1 kurulu (ateşe hazır), 0 toplanmış (yürüyüşe hazır)
var vid := ""            # katalog kimliği (boşsa taban araç)
# gerçek performans (data/real_perf.json, roadmap 2): yol hızı, ana silah dolumu, otomatik top, salvo
var road_speed := -1.0     # yolda azami hız (m/sn); <0: yol farkı yok
var reload_s := -1.0       # ana silah atış arası (sn); <0: tipin varsayılanı
var rpm := -1.0            # otomatik top dakikada atım
var burst_n := 0
var salvo_n := 0           # roketatar salvosu (roket), aralık, yeniden dolum
var salvo_ival := 0.0
var rearm_s := 0.0
var _road_t := 0.0
var _on_road := false
# mühimmat (data/ammo.json, roadmap 6): zırh delici / patlayıcı / otomatik top mermisi kimliği
var ammo_ke := ""
var ammo_he := ""
var ammo_auto := ""
var cat: Dictionary = {}
# 4 yön x 2 tip zırh: [ön, yan, arka, üst] (kinetik / HEAT). Mayın alttan = üst değeri.
const ARMOR := {
	"tank": [[22, 8, 5, 3], [26, 11, 5, 3]],
	"ifv": [[8, 4, 3, 2], [10, 5, 3, 2]],
	"apc": [[5, 3, 2, 1], [6, 3, 2, 1]],
	"aa": [[6, 3, 2, 1], [7, 3, 2, 1]],
	"arty": [[4, 3, 2, 1], [5, 3, 2, 1]],
	"heli": [[2, 2, 2, 1], [2, 2, 2, 1]],
	"transport": [[1, 1, 1, 1], [1, 1, 1, 1]],
	"fieldgun": [[2, 0, 0, 0], [2, 0, 0, 0]],
	"atgun": [[2, 0, 0, 0], [2, 0, 0, 0]],
	"howitzer": [[1, 0, 0, 0], [1, 0, 0, 0]],
	"mtngun": [[1, 0, 0, 0], [1, 0, 0, 0]],
}
# silah delmesi: [tip 0=kinetik 1=HEAT, yakın delme, 60 m+ delme, üstten saldırı]
const PEN := {
	"bullet": [0, 1, 0, false], "sniper": [0, 3, 2, false], "hmg": [0, 5, 3, false], "auto": [0, 10, 7, false],
	"crush": [0, 0, 0, false], "melee": [0, 0, 0, false], "blast": [1, 2, 2, false],
	"ap": [0, 28, 23, false], "he": [1, 7, 7, false], "rpg": [1, 17, 17, false], "atgm": [1, 27, 27, false],
	"topatk": [1, 24, 24, true], "grenade": [1, 2, 2, false], "shell": [1, 6, 6, true], "big": [1, 9, 9, true],
	"mortar": [1, 4, 4, true], "mine": [0, 12, 12, true], "fpv": [1, 10, 10, true], "sam": [1, 12, 12, false],
}
const SIDE_NAME := ["ÖN", "YAN", "ARKA", "ÜST"]
static var shot_from := Vector3.INF
# mermiye özel delme (Ammo tablosu): [tür, yakın, 60 m+]; take_damage öncesi kurulur, bir kez kullanılır
static var shot_pen: Array = []
# kritik hasar (BA): 4 tür x 2 seviye (1 sarı, 2 kırmızı); mürettebat zamanla onarır
const CRIT_NAME := {"mob": "HAREKET", "opt": "OPTİK", "tgt": "NİŞAN", "load": "DOLUM"}
var crit := {"mob": 0, "opt": 0, "tgt": 0, "load": 0}
var crit_t := {"mob": 0.0, "opt": 0.0, "tgt": 0.0, "load": 0.0}
var vstress := 0.0
var vstress_t := -99.0
var vstress_lv := 0
var _nopen_t := 0.0
var last_side := -1
var last_pen := 0.0
var speed_max := 6.0
var cur_speed := 0.0
var heading := 0.0
var path := PackedVector3Array()
var path_i := 0
var dest := Vector3.ZERO
var order := ""
var force_move := false
var nav_mode := Grid.M_HEAVY
var target: Unit = null
var coax_target: Unit = null
var forced_target: Unit = null
var main_cd := 0.0
var coax_cd := 0.0
var burst := 0
var coax_burst := 0
var turret_yaw := 0.0
var recoil := 0.0
var tracks_broken := 0.0
var wreck := false
var engine: AudioStreamPlayer3D
var think_t := 0.0
var _crush_t := 0.0
var _track_acc := 0.0
var _dust_t := 0.0
var _stuck_t := 0.0
var _last_pos := Vector3.ZERO
var shots := 0
var job: Dictionary = {}      # kamyon görevi (Logistics)
var rock := 0.0
var rock_v := 0.0
var burn_t := 0.0
const ALT := 9.0
const UAV_ALT := 13.0
var uav_ang := 0.0
var missiles := 0
var missile_cd := 0.0
var rotor: Node3D
var trotor: Node3D
var hvel := Vector3.ZERO
var rocket_cd := 4.0
var salvo := 0
var salvo_t := 0.0
var _hb := 0.0
var cargo: Array = []
var operator = null
var atgm_cd := 8.0
var landing := false
var fire_mode := 0          # 0 serbest, 1 karşılık, 2 ateşi kes
var reverse := false
var retreating := false
var amove_dest := Vector3.INF
var smoke_charges := 2
var ground_pt := Vector3.ZERO
var ground_until := 0.0
const TRACKED := ["tank", "ifv", "aa", "arty"]
const WHEELED := ["technical", "apc", "truck", "mlrs"]
const CREWED := {"tank": 3, "ifv": 3, "aa": 3, "arty": 4, "apc": 2, "technical": 2, "truck": 1, "mlrs": 2}
var crew_max := 0
var crew_n := 0
var driver_ok := true
var gunner_ok := true
var tires := 0
var abandon_t := -1.0
var repair_body: SoldierBody = null
const TOWED := ["fieldgun", "howitzer", "atgun", "aagun", "hmortar", "mtngun"]
const INDIRECT := ["arty", "howitzer", "hmortar", "mtngun", "mlrs"]
var crew: Array = []
var mlrs_left := 0
var mlrs_t := 0.0
const CAPACITY := {"apc": 8, "ifv": 6, "transport": 8, "tank": 4, "technical": 2}

# hava araçları: yere düşen yumuşak gölge — irtifa arttıkça büyür, dağılır, güneş yönünde kayar
var _shadow: Decal = null
static var _shadow_tex: Texture2D = null

func _air_shadow_tick() -> void:
	if _shadow == null:
		if _shadow_tex == null:
			var gr := Gradient.new()
			gr.set_color(0, Color(0, 0, 0, 1))
			gr.set_color(1, Color(0, 0, 0, 0))
			gr.add_point(0.55, Color(0, 0, 0, 0.75))
			var gt := GradientTexture2D.new()
			gt.gradient = gr
			gt.fill = GradientTexture2D.FILL_RADIAL
			gt.fill_from = Vector2(0.5, 0.5)
			gt.fill_to = Vector2(0.5, 0.0)
			gt.width = 128
			gt.height = 128
			_shadow_tex = gt
		_shadow = Decal.new()
		_shadow.texture_albedo = _shadow_tex
		_shadow.cull_mask = 1
		_shadow.upper_fade = 0.2
		_shadow.lower_fade = 0.2
		G.world.add_child(_shadow)
		tree_exiting.connect(func(): if is_instance_valid(_shadow): _shadow.queue_free())
	var gp := hull.global_position
	var gh := G.terrain.ground_h(gp)
	var alt := maxf(gp.y - gh, 0.0)
	var sd := Vector3(0.35, 0, 0.2) * alt      # güneş eğimi: yükseldikçe gölge kayar
	_shadow.global_position = Vector3(gp.x + sd.x, gh + 1.0, gp.z + sd.z)
	_shadow.rotation.y = hull.global_rotation.y
	var spread := 1.0 + alt * 0.035
	var hs := hull.scale.x
	_shadow.size = Vector3(minf(ext.x, 2.2) * 2.0 * spread * hs, 4.0, ext.y * 1.9 * spread * hs)
	_shadow.modulate = Color(1, 1, 1, clampf(0.55 - alt * 0.015, 0.18, 0.5))
	_shadow.visible = visible and hull.visible

func is_air() -> bool:
	return vtype in ["heli", "transport", "fpv", "uav", "uav_armed", "loiter"]

# katalog biriminin gerçek boyut ölçeği: "scale": 1.18 (eşit) ya da [x, y, z] (eksen başına; sabit kanatlı
# İHA'da kanat açıklığı ve boy ayrı düzeltilir). Yoksa 1.
static func cat_scale(id: String) -> Vector3:
	Catalog.load_all()
	var s = Catalog.units.get(id, {}).get("scale", 1.0)
	if s is Array and (s as Array).size() == 3:
		return Vector3(float(s[0]), float(s[1]), float(s[2]))
	return Vector3.ONE * float(s)

func is_drone() -> bool:
	return vtype in ["fpv", "uav", "uav_armed", "loiter"]

func capacity() -> int:
	if is_cargo():
		return 20 if heavy_lift() else 16
	return CAPACITY.get(vtype, 0)

func is_cargo() -> bool:
	return M.get("meta", {}).get("cargo", false)

func heavy_lift() -> bool:
	return M.get("meta", {}).get("heavy_lift", false)

func crates_max() -> int:
	return 4 if heavy_lift() else 3

# askıya alınabilir mi: hafif araçlar ve çekili toplar; ağır kaldırıcı (Mi-26 tipi) ZPT/PSA da taşır
func can_sling(v) -> bool:
	if not is_cargo() or v == null or not is_instance_valid(v) or v == self or not (v is Vehicle) or not v.alive:
		return false
	if v.is_air() or v.team != team or v.slung_by != null:
		return false
	if v.vtype in TOWED or v.vtype in ["technical", "truck"]:
		return true
	return heavy_lift() and v.vtype in ["apc", "ifv", "aa"]

func cmd_sling(v: Vehicle) -> void:
	if sling != null or not can_sling(v):
		return
	sling_tgt = v
	drop_pt = Vector3.INF
	landing = false
	land_hold = false
	order = "move"
	dest = v.position
	path = PackedVector3Array([dest])
	path_i = 0
	say("YÜKÜ ALIYORUZ")

func cmd_airdrop(p: Vector3) -> bool:
	if not is_cargo() or crates <= 0:
		return false
	drop_pt = G.on_ground(p)
	sling_tgt = null
	landing = false
	land_hold = false
	order = "move"
	dest = drop_pt
	path = PackedVector3Array([dest])
	path_i = 0
	say("İKMAL YOLDA")
	return true

# yolcu almak için bulunduğu yere in ve bekle
func request_land() -> void:
	if not is_air() or landing or sling != null:
		return
	landing = true
	land_hold = true
	dest = G.on_ground(position)
	path = PackedVector3Array([dest])
	path_i = 0
	say("İNİŞE GEÇİYORUZ")

# binme/inme kapısı: zırhlılarda arka rampa/kapı, kamyonda arka kasa, helikopterde rampa/yan kapı
func entry_point(k := 0) -> Vector3:
	var side := ((k % 2) - 0.5) * 0.9
	if is_air():
		if is_cargo():
			return position - forward() * (ext.y + 0.8) + right() * side
		return position + right() * (ext.x + 0.9) * (1.0 if k % 2 == 0 else -1.0)
	return position - forward() * (ext.y + 0.7) + right() * side

func inside_point() -> Vector3:
	if is_air() and not is_cargo():
		return position
	return position - forward() * maxf(ext.y - 1.0, 0.3)

func can_load() -> bool:
	return alive and cargo.size() < capacity() and (not is_air() or hull.position.y < 2.5)

func riders_visible() -> bool:
	return vtype in ["tank", "technical"]

func seat_pos(s) -> Vector3:
	var i := cargo.find(s)
	if vtype == "tank":
		var seats := [Vector3(-1.1, 1.55, 1.2), Vector3(1.1, 1.55, 1.2), Vector3(-1.1, 1.55, 2.4), Vector3(1.1, 1.55, 2.4)]
		return hull.global_transform * seats[clampi(i, 0, 3)]
	if vtype == "technical":
		return hull.global_transform * Vector3(0.5 * (1 if i % 2 == 0 else -1), 1.0, 1.6)
	return position + Vector3(0, -50, 0)

func unload() -> void:
	if sling != null:
		sling_drop = true
		dest = G.on_ground(position)
		say("YÜK BIRAKILIYOR")
		return
	if cargo.is_empty():
		return
	if is_air() and hull.position.y > 1.2:
		landing = true
		say("İNİŞE GEÇİYORUZ")
		return
	var n := cargo.size()
	var back := -forward()
	var side := Vector3(-back.z, 0, back.x)
	for k in n:
		var s = cargo[0]
		if is_instance_valid(s):
			# kapıdan tek tek çıkar, sonra arkada yelpaze şeklinde açılır
			s.dismount(position + back * (D["len"] * 0.5 + 1.6) + side * ((k % 3) - 1) * 1.5 - back * (k / 3) * 1.3, self, k * 0.38)
		else:
			cargo.remove_at(0)
	landing = false
	say("İNDİR!")

func hook_pos() -> Vector3:
	var hk = M.get("meta", {}).get("hook", Vector3(0, 0.6, 0))
	var hv: Vector3 = hk if hk is Vector3 else Art.v3(hk)
	return hull.global_transform * hv

func _attach_sling(v: Vehicle) -> void:
	sling = v
	sling_tgt = null
	v.slung_by = self
	v.cmd_stop()
	v.sling_vel = Vector3.ZERO
	order = ""
	say("YÜK ALINDI")

func _release_sling() -> void:
	var v := sling
	sling = null
	sling_drop = false
	if v != null and is_instance_valid(v):
		v.slung_by = null
		v.position.y = G.terrain.ground_h(v.position)
		v.position = G.grid.nearest_free(v.position, v.nav_mode, 12)
		v.dest = v.position
		v.hull.rotation.x = 0.0
		v.hull.rotation.z = 0.0
		G.fx.vehicle_dust(v.position)
	say("YÜK BIRAKILDI")

func _drop_crate() -> void:
	drop_pt = Vector3.INF
	order = ""
	crates -= 1
	var pal := MeshInstance3D.new()
	pal.mesh = Building.cache_mesh()
	G.world.add_child(pal)
	pal.global_position = hook_pos()
	var gp := G.on_ground(position)
	var tw := pal.create_tween()
	tw.tween_property(pal, "global_position", gp, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tm := team
	tw.tween_callback(func():
		pal.queue_free()
		var b: Building = G.main.place_building(tm, "cache", G.grid.nearest_free(gp, Grid.M_INF, 8), randf() * TAU)
		if b != null:
			b.complete()
			b.stock = 320.0
		G.fx.vehicle_dust(gp))
	say("İKMAL BIRAKILDI")

# askı halatı ve kayışlar + rampa + yerde palet yenileme
func _cargo_visuals(dt: float) -> void:
	if ramp:
		var open := hull.position.y < 0.6 and (landing or land_hold or (not cargo.is_empty() and cur_speed < 0.3))
		ramp_k = move_toward(ramp_k, 1.0 if open else 0.0, dt * 0.7)
		ramp.rotation.x = ramp_k * float(M.get("meta", {}).get("ramp_open", 1.0))
	if hull.position.y < 0.6 and crates < crates_max():
		for b in G.near(position, 26.0):
			if b is Building and b.team == team and b.btype in ["hq", "helipad", "fob"] and b.done:
				crates = crates_max()
				break
	if sling == null or not is_instance_valid(sling):
		for c in _cables:
			c.visible = false
		return
	if _cables.is_empty():
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.03
		cm.height = 1.0
		cm.radial_segments = 5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.12, 0.1)
		mat.roughness = 0.8
		for i in 5:
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = mat
			G.world.add_child(mi)
			_cables.append(mi)
		tree_exiting.connect(_free_cables)
	var hk := hook_pos()
	var top: Vector3 = sling.position + Vector3(0, sling.top_h + 1.2, 0)
	_seg(_cables[0], hk, top)
	var f := sling.forward()
	var r := sling.right()
	var k := 0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k += 1
			var corner: Vector3 = sling.position + Vector3(0, sling.top_h * 0.85, 0) + r * sx * sling.ext.x * 0.8 + f * sz * sling.ext.y * 0.75
			_seg(_cables[k], top, corner)

func _free_cables() -> void:
	for c in _cables:
		if is_instance_valid(c):
			c.queue_free()

static func _seg(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	mi.visible = true
	var d := b - a
	var L := maxf(d.length(), 0.01)
	var y := d / L
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.global_transform = Transform3D(Basis(x, y * L, z), (a + b) * 0.5)

# askıdaki araç: kancanın altında, gecikmeli salınım
func _slung_tick(dt: float) -> void:
	var h := slung_by
	if h == null or not is_instance_valid(h) or not h.alive:
		# helikopter düştü: yük serbest düşer
		slung_by = null
		var gy := G.terrain.ground_h(position)
		var fall := position.y - gy
		var tw := create_tween()
		tw.tween_property(self, "position:y", gy, clampf(sqrt(maxf(fall, 0.1) / 4.9), 0.2, 2.0)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			G.fx.vehicle_dust(position)
			take_damage(max_hp * clampf(fall * 0.06, 0.1, 0.9), null, "blast"))
		return
	var want: Vector3 = h.hook_pos() - Vector3(0, SLING_L + top_h + 1.2, 0)
	var acc := (want - position) * 6.0 - sling_vel * 2.2
	sling_vel += acc * dt
	position += sling_vel * dt
	heading = lerp_angle(heading, h.heading, dt * 1.5)
	hull.rotation.y = heading
	hull.rotation.x = clampf(-sling_vel.dot(forward()) * 0.04, -0.25, 0.25)
	hull.rotation.z = clampf(sling_vel.dot(right()) * 0.04, -0.25, 0.25)
	cur_speed = 0.0

func _cargo_lost() -> void:
	for s in cargo.duplicate():
		if is_instance_valid(s) and s.alive:
			s.dismount(position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
			s.add_stress(65.0)
			if randf() < 0.5:
				s.die(null)
			else:
				s.take_damage(60.0, null, "blast")
	cargo.clear()
var rotor_blades: MeshInstance3D
var rotor_disc: MeshInstance3D
# kargo helikopteri: arka rampa, askı yükü (araç), havadan ikmal paletleri
const SLING_L := 5.5
var ramp: Node3D = null
var ramp_k := 0.0
var land_hold := false          # yolcu almak için inip bekle (indirme yapma)
var sling: Vehicle = null       # askıdaki araç
var sling_tgt: Vehicle = null   # alınacak araç
var slung_by: Vehicle = null    # bu araç bir helikopterin askısında
var sling_drop := false
var sling_vel := Vector3.ZERO
var drop_pt := Vector3.INF      # havadan ikmal noktası
var crates := 0
var top_h := 2.0
var _cables: Array = []
var station = null              # İHA: bağlı yer istasyonu (DroneStation)
var high_alt := false           # yüksek irtifa keşif İHA'sı: geniş görüş, vurulması zor
var link_lost := false
var link_t := 0.0
var loiter_pt := Vector3.INF    # mini drone: hedef yoksa bu noktada asılı kalır
var battery := 70.0             # mini drone uçuş süresi (sn)
const HIGH_ALT := 24.0
# hava savunma füzesi / fişek / kaçış
var sams := 0
var sam_cd := 0.0
var sam_big := false
var sam_range := 0.0
var flares := 0
var flare_q := 0                # kuyruktaki fişek çifti
var flare_t := 0.0
var evade_t := 0.0
var evade_side := 1.0
var hf_left := 0                # helikopter güdümlü füzesi (Hellfire / Vikhr)
var hf_cd := 3.0
# saldırı helikopterinin atış konumu: hedefe göre yön + mesafe; görüş hattı kapalıysa (ağaç, bina)
# konum hedef çevresinde döndürülür ve mesafe daraltılır (yoksa helikopter aynı noktada sonsuza dek asılı kalırdı)
var atk_for: Unit = null
var atk_dir := Vector3.ZERO
var atk_r := 32.0
var atk_t := 0.0
var atk_n := 0
# halatla iniş (fast-rope) / halatla çekme (SPIES)
var rope_pt := Vector3.INF
var rope_mode := ""             # "down": asker indir, "up": asker al
var rope_t := 0.0
var rope_next := 0.0
var rope_side := 0
var ropes: Array = []           # [MeshInstance3D, yerel bağlantı noktası]
var rope_riders: Array = []     # halattaki askerler
const ROPE_ALT := 8.0
static var _disc_mat: ShaderMaterial

func setup(t: int, vt: String) -> void:
	team = t
	if Catalog.has(vt):
		vid = vt
		cat = Catalog.get_unit(vt)
		vt = Catalog.base(vt)
	vtype = vt
	kind = vt
	D = DEF[vt]
	if vid != "":
		D = D.duplicate()
		D["title"] = cat.get("name", D["title"])
		D["hp"] = float(cat.get("hp", D["hp"]))
		D["speed"] = float(cat.get("speed", D["speed"]))
		var pf := Catalog.perf(vid)
		var air_t: bool = vt in ["heli", "transport", "fpv", "uav", "uav_armed", "loiter"]
		if air_t and pf.has("cruise"):
			# gerçek seyir hızı (km/h) × hava ölçeği
			D["speed"] = float(pf["cruise"]) / 3.6 * Catalog.K_AIR
		elif float(pf.get("off", 0.0)) > 0.0:
			# gerçek arazi / yol hızı ve 0→32 km/h ivmesi × kara ölçeği
			D["speed"] = float(pf["off"]) / 3.6 * Catalog.K_GROUND
			road_speed = float(pf.get("road", pf["off"])) / 3.6 * Catalog.K_GROUND
			D["accel"] = (32.0 / 3.6 * Catalog.K_GROUND) / maxf(float(pf.get("acc", 8.0)), 1.0)
		else:
			# veri yoksa: ağır araç yavaş — ön zırh ve cana göre hız çarpanı
			var fa: float = float(cat["armor"][0][0]) if cat.has("armor") else 6.0
			D["speed"] *= clampf(1.15 - fa * 0.012 - float(D["hp"]) * 0.0002, 0.7, 1.1)
			D["accel"] = float(D["accel"]) * clampf(1.2 - float(D["hp"]) * 0.0005, 0.6, 1.2)
		reload_s = float(pf.get("reload", -1.0))
		rpm = float(pf.get("rpm", -1.0))
		burst_n = int(pf.get("burst", 0))
		salvo_n = int(pf.get("salvo", 0))
		salvo_ival = float(pf.get("ival", 0.0))
		rearm_s = float(pf.get("rearm", 0.0))
	title = D["title"]
	max_hp = D["hp"]
	hp = max_hp
	armor = D["armor"]
	speed_max = D["speed"]
	radius = D["radius"]
	nav_mode = D["nav"]
	sight = D["sight"]
	cap_cost = D["cap"]
	icon = D["icon"]
	crew_max = CREWED.get(vt, 0)
	crew_n = crew_max
	var am := Ammo.for_vehicle(vid, vt, G.nation[t] if t >= 0 and t < G.nation.size() else "")
	ammo_ke = String(am.get("ke", ""))
	ammo_he = String(am.get("he", ""))
	ammo_auto = String(am.get("auto", ""))
	M = Art.vehicle_model(vid, t) if vid != "" and Art.has(vid) else Art.vehicle(vt, t)
	if M.is_empty() and vid == "":
		# taban tipin kendi modeli yoksa katalogdan aynı tabandaki bir birimin modeli
		# (keşif İHA'sı: katalogdaki ilk — en büyük, RQ-4 sınıfı — değil, küçük taktik sınıf)
		var alt := DroneStation.uav_id(t) if vt == "uav" else Catalog.first_of_base(vt, G.nation[t] if t >= 0 and t < G.nation.size() else "")
		if alt != "" and Art.has(alt):
			M = Art.vehicle_model(alt, t)
	if M.is_empty():
		M = VehicleModels.get_model(vt, t, G.map_kind == "winter")
	hull = Node3D.new()
	add_child(hull)
	if vid != "":
		# gerçek boyut düzeltmesi (data/real_dims.json → tools/size_audit.gd → katalog 'scale')
		hull.scale = cat_scale(vid)
	if M.has("hulls"):
		for hm in M["hulls"]:
			var hmi := MeshInstance3D.new()
			hmi.mesh = hm[0]
			hmi.position = hm[1]
			hull.add_child(hmi)
			if hull_mi == null:
				hull_mi = hmi
	else:
		hull_mi = MeshInstance3D.new()
		hull_mi.mesh = M["hull"]
		hull.add_child(hull_mi)
	if M["turret"] != null:
		turret = Node3D.new()
		turret.position = M["turret_pos"]
		hull.add_child(turret)
		var tmi := MeshInstance3D.new()
		tmi.mesh = M["turret"]
		turret.add_child(tmi)
		barrel = Node3D.new()
		barrel.position = M["barrel_pos"]
		turret.add_child(barrel)
		var bmi := MeshInstance3D.new()
		bmi.mesh = M["barrel"]
		barrel.add_child(bmi)
	for w in M["wheels"]:
		var wn := MeshInstance3D.new()
		wn.mesh = w[3] if w.size() > 3 else VehicleModels.wheel(w[1], w[2])
		wn.position = w[0]
		hull.add_child(wn)
		wheels.append([wn, w[1]])
	if M.has("gunner"):
		gunner = SoldierBody.new()
		gunner.position = M["gunner"] - M["turret_pos"]
		turret.add_child(gunner)
		gunner.build(t, "rifle", G.map_kind == "winter")
		gunner.weapon.visible = false
	if vt in TOWED:
		# çekili top: yanında çömelmiş mürettebat
		var spots := [Vector3(-0.9, 0, 1.3), Vector3(0.9, 0, 1.1), Vector3(0.3, 0, 2.2)]
		for i in (2 if vt in ["hmortar", "mtngun", "aagun"] else 3):
			var cb := SoldierBody.new()
			cb.position = spots[i]
			cb.rotation.y = randf_range(-0.4, 0.4)
			hull.add_child(cb)
			cb.build(t, "rifle", G.map_kind == "winter")
			cb.weapon.visible = false
			crew.append(cb)
	if vt == "fpv":
		hull.position.y = 2.2
		Sfx.loop3d("drone", self, -6.0)
	if vt in ["uav", "uav_armed"]:
		# gerçek ölçek (eskiden görünürlük için 1,6 kat büyütülüyordu); görünürlüğü irtifa gölgesi sağlar
		hull.position.y = UAV_ALT
		uav_ang = randf() * TAU
		missiles = 4 if vt == "uav_armed" else 0
		Sfx.loop3d("drone", self, -14.0)
	if vt == "loiter":
		hull.position.y = 18.0
		Sfx.loop3d("drone", self, -8.0)
	_setup_air_defense(vt)
	if vt in ["heli", "transport"]:
		hull.position.y = ALT
		rotor = Node3D.new()
		rotor.position = M["rotor_pos"]
		hull.add_child(rotor)
		var rmi := MeshInstance3D.new()
		rmi.mesh = M["rotor"]
		rotor.add_child(rmi)
		rotor_blades = rmi
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var rr: float = M["rotor"].get_aabb().size.x * 0.5
		cm.top_radius = rr
		cm.bottom_radius = rr
		cm.height = 0.02
		cm.radial_segments = 32
		disc.mesh = cm
		disc.position.y = 0.3
		disc.material_override = _rotor_disc_mat()
		rotor_disc = disc
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		rotor.add_child(disc)
		trotor = Node3D.new()
		trotor.position = M["trotor_pos"]
		hull.add_child(trotor)
		var tmi2 := MeshInstance3D.new()
		tmi2.mesh = M["trotor"]
		trotor.add_child(tmi2)
		if M.has("ramp"):
			ramp = Node3D.new()
			ramp.position = M["ramp_pos"]
			hull.add_child(ramp)
			var rmi2 := MeshInstance3D.new()
			rmi2.mesh = M["ramp"]
			ramp.add_child(rmi2)
		if is_cargo():
			crates = crates_max()
	set_layer(self, 2)
	_calc_ext()
	heading = rotation.y
	rotation.y = 0.0
	hull.rotation.y = heading
	dest = position
	_last_pos = position
	think_t = randf() * 0.5
	if not is_drone() and not (vt in TOWED):
		engine = Sfx.loop3d("heli" if vt in ["heli", "transport"] else ("engine_tank" if vt in ["tank", "apc", "ifv", "aa", "arty"] else "engine_truck"), self, -8.0 if vt in ["heli", "transport"] else -10.0)

func _calc_ext() -> void:
	var a := AABB()
	var first := true
	for mi in _meshes(hull):
		if mi.mesh == null or mi == rotor_disc:
			continue
		var bb: AABB = mi.transform * mi.mesh.get_aabb()
		if mi.get_parent() != hull and mi.get_parent() is Node3D:
			bb = (mi.get_parent() as Node3D).transform * bb
		a = bb if first else a.merge(bb)
		first = false
	if not first:
		# gövde ölçeği (gerçek boyut düzeltmesi) kapsama da yansısın
		a = Transform3D(Basis.from_scale(hull.scale), Vector3.ZERO) * a
		ext = Vector2(clampf(a.size.x * 0.5, 0.4, 3.0), clampf(a.size.z * 0.5, 0.4, 7.0))
		top_h = clampf(a.end.y - hull.position.y, 0.8, 5.0)

func right() -> Vector3:
	return Vector3(cos(heading), 0, -sin(heading))

# bir noktayı araç izinin (yönlü dikdörtgen) dışına iten vektör
func obb_push(p: Vector3, pad: float) -> Vector3:
	var d := p - position
	d.y = 0.0
	var f := forward()
	var r := right()
	var lx := d.dot(r)
	var lz := d.dot(f)
	var ex := ext.x + pad
	var ez := ext.y + pad
	if absf(lx) >= ex or absf(lz) >= ez:
		return Vector3.ZERO
	var px := ex - absf(lx)
	var pz := ez - absf(lz)
	if px < pz:
		return r * (px * signf(lx if lx != 0.0 else 1.0))
	return f * (pz * signf(lz if lz != 0.0 else 1.0))

# araç–araç çakışması: yönlü dikdörtgenlerde ayırıcı eksen (SAT) ile en küçük itme
func _sep_vehicles() -> void:
	for o in G.near(position, radius + 8.0):
		if o == self or not (o is Vehicle) or o.is_air() or (not o.alive and not o.wreck):
			continue
		var d: Vector3 = o.position - position
		d.y = 0.0
		var axes := [forward(), right(), o.forward(), o.right()]
		var best := 1e9
		var bax := Vector3.ZERO
		var sep := false
		for ax in axes:
			var ra := absf(forward().dot(ax)) * ext.y + absf(right().dot(ax)) * ext.x
			var rb: float = absf(o.forward().dot(ax)) * o.ext.y + absf(o.right().dot(ax)) * o.ext.x
			var dist := absf(d.dot(ax))
			var ov: float = ra + rb + 0.15 - dist
			if ov <= 0.0:
				sep = true
				break
			if ov < best:
				best = ov
				bax = ax * (-1.0 if d.dot(ax) > 0.0 else 1.0)
		if sep:
			continue
		var other_static: bool = not o.alive or o.immobile() or absf(o.cur_speed) < 0.2
		var me_moving := absf(cur_speed) > 0.3
		var ahead: bool = d.dot(forward()) * signf(cur_speed) > 0.0
		# önündekine doğru giden araç yana itilmez (köprü korkuluğuna sıkışmasın): yavaşlar/durur
		if me_moving and ahead:
			if not other_static:
				# hareketli aracı takip et
				cur_speed = signf(cur_speed) * minf(absf(cur_speed), absf(o.cur_speed) * 0.9 + 0.3)
				continue
			# duran araç/enkaz önde: yanından sıyrıl (yan eksende it), yavaşla
			var sd2 := right() * (-1.0 if d.dot(right()) > 0.0 else 1.0)
			var np2 := position + sd2 * minf(best, 0.4) * 0.35
			if _cell_ok(np2) and G.grid.height_at(np2) < 0.3:
				position = np2
			cur_speed *= 0.85
			continue
		var k := 1.0 if other_static else 0.5
		var np := position + bax * minf(best, 0.6) * k
		if _cell_ok(np) and G.grid.height_at(np) < 0.3:
			position = np

func forward() -> Vector3:
	return Vector3(-sin(heading), 0, -cos(heading))

# Araç piyadeyi asla itmez: gidiş şeridindeki dost (ve ezilmeyecek yavaşlıktaki düşman)
# askerler için yavaşlar/durur, askere kenara çekilmesini söyler; asker kendi yürüyerek açılır.
var _honk_t := 0.0
func _give_way(dt: float) -> void:
	_honk_t -= dt
	var dir := signf(cur_speed)
	var f := forward() * dir
	var r := right()
	var look := ext.y + 1.2 + absf(cur_speed) * 1.1
	var nearest := 1e9
	for o in G.near(position + f * (ext.y + look * 0.5), look * 0.5 + ext.x + 1.5):
		if not (o is Soldier) or not o.alive or o.state in ["aboard", "hospital"] or o.vehicle_in != null:
			continue
		if o.team != team and absf(cur_speed) > 2.0 and nav_mode == Grid.M_HEAVY:
			continue    # düşman piyade: paletli hızla gelir (ezme ayrı denetlenir)
		var d: Vector3 = o.position - position
		d.y = 0.0
		var lz := d.dot(f) - ext.y
		var lx := absf(d.dot(r))
		if lz < -ext.y * 2.0 or lz > look or lx > ext.x + 0.7:
			continue
		nearest = minf(nearest, maxf(lz, 0.0))
		o.give_way(self)
	if nearest > 1e8:
		return
	# 0.8 m'de tam dur, ileride kademeli yavaşla
	var vmax := clampf((nearest - 0.8) / 1.1, 0.0, 1.0) * speed_max
	if absf(cur_speed) > vmax:
		cur_speed = dir * vmax
		if vmax < 0.3 and _honk_t <= 0.0:
			_honk_t = 6.0
			if randf() < 0.5:
				say("YOLU AÇIN!")

func aim_point() -> Vector3:
	if is_air():
		return position + Vector3(0, hull.position.y + 0.6, 0)
	return position + Vector3(0, 1.3 if vtype != "technical" else 1.0, 0)

func turret_world_pos() -> Vector3:
	return hull.global_transform * (M["turret_pos"] as Vector3)

func muzzle_world() -> Vector3:
	if barrel == null:
		return aim_point()
	return barrel.global_transform * (M["muzzle"] as Vector3)

# ------------------------------------------------------------ emirler
func cmd_move(p: Vector3, force := false) -> void:
	if not alive:
		return
	order = "move"
	force_move = force
	forced_target = null
	reverse = false
	retreating = false
	amove_dest = Vector3.INF
	ground_until = 0.0
	dest = G.on_ground(p)
	landing = false
	land_hold = false
	sling_tgt = null
	sling_drop = false
	drop_pt = Vector3.INF
	if rope_pt != Vector3.INF and rope_riders.is_empty():
		_rope_reset()
	if is_air():
		path = PackedVector3Array([dest])
		path_i = 0
	else:
		_repath(dest)

# saldırı emri yapılabilir mi: silah bu hedefe hiç ateş edemiyorsa nedeni ("" = yapılabilir).
# Eskiden emir sessizce kabul ediliyor, araç hedefe bakıp sonsuza dek bekliyordu.
func _attack_block(u: Unit) -> String:
	var air: bool = u is Vehicle and u.is_air()
	if vtype in ["truck", "uav"]:
		return "SİLAHIM YOK"
	if crew_max > 0 and crew_n <= 0:
		return "MÜRETTEBAT YOK"
	if not gunner_ok:
		return "NİŞANCI YOK"
	if air and not (vtype in ["apc", "ifv", "technical", "heli", "aa", "aagun"]):
		return "HAVA HEDEFİNE ATEŞ EDEMEM"
	if vtype == "aagun" and (u is Building or (u is Vehicle and u.armor > 0)):
		return "ZIRHA ETKİSİZ"
	if vtype == "aa" and u is Building:
		return "YALNIZ HAVA HEDEFİ"
	return ""

# dolaylı atışlı topçunun asgari menzili (bunun içindeki hedefe ateş edemez)
func _min_range() -> float:
	return 18.0 if vtype == "hmortar" else 30.0

func cmd_attack(u: Unit) -> void:
	if not alive:
		return
	var why := _attack_block(u)
	if why != "":
		if team == G.player_team and not G.spectate:
			say(why, 2.5)
		return
	forced_target = u
	order = "attack"
	var rng_w := _range()
	if dist2(u) > rng_w * 0.85:
		dest = u.position + (position - u.position).normalized() * rng_w * 0.7
		_repath(dest)

func cmd_stop() -> void:
	order = ""
	forced_target = null
	reverse = false
	retreating = false
	amove_dest = Vector3.INF
	ground_until = 0.0
	path = PackedVector3Array()
	dest = position

func cmd_attack_move(p: Vector3) -> void:
	cmd_move(p)
	order = "amove"
	amove_dest = dest

func cmd_reverse(p: Vector3) -> void:
	cmd_move(p)
	reverse = not is_air()

func cmd_hold() -> void:
	cmd_stop()
	order = "hold"

func cmd_retreat() -> void:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == team and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	if best == null:
		return
	var away := position - best.position
	away.y = 0
	cmd_move(best.position + (away.normalized() if away.length() > 0.1 else Vector3(1, 0, 0)) * (best.radius + 6.0), true)
	order = "retreat"
	retreating = true

func cmd_refund() -> void:
	if is_air():
		return
	cmd_retreat()
	if order == "retreat":
		order = "refund"

func _refund_check() -> void:
	if order != "refund":
		return
	for u in G.friends_near(position, 22.0, team):
		if u is Building and u.is_base() and u.done and position.distance_to(u.position) < u.radius + 9.0:
			var v := G.unit_value(self) * clampf(hp / max_hp, 0.0, 1.0) * 0.8
			for c in cargo:
				if is_instance_valid(c):
					v += G.unit_value(c) * 0.8
					c.queue_free()
			cargo.clear()
			G.supply[team] += v
			if team == G.player_team and not G.spectate:
				G.say(I18n.s("İade +%d") % int(v), position, team)
			alive = false
			G.remove_unit(self)
			queue_free()
			return

func has_smoke() -> bool:
	return vtype in ["tank", "apc", "ifv", "aa"]

func cmd_smoke() -> bool:
	if not alive or not has_smoke() or smoke_charges <= 0:
		return false
	smoke_charges -= 1
	var yaw := heading + turret_yaw
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var side := Vector3(-fwd.z, 0, fwd.x)
	for k in 5:
		var p := position + fwd * 9.0 + side * (k - 2) * 3.4 - fwd * absf(k - 2) * 1.2
		var pp := p
		get_tree().create_timer(0.08 * k).timeout.connect(func():
			G.fx.smoke_screen(pp, 22.0)
			G.add_smoke(pp, 4.0, 23.0))
	Sfx.play3d("smoke_pop", position, 2.0)
	G.fx.muzzle(position + Vector3(0, 2.0, 0), fwd, false)
	return true

func can_ground_fire() -> bool:
	return vtype in ["tank", "apc", "ifv", "technical", "arty", "fieldgun", "howitzer", "atgun", "hmortar", "mtngun", "mlrs"]

func cmd_suppress(p: Vector3) -> void:
	if not alive or not can_ground_fire():
		return
	ground_pt = G.on_ground(p)
	ground_until = G.time + (24.0 if vtype in INDIRECT else 12.0)
	if order != "retreat":
		path = PackedVector3Array()
		order = ""

# yol bul; büyük haritada uzun yol iş parçacığında (o sırada hedefe doğru düz parça)
var path_req := 0

func _repath(to: Vector3) -> void:
	path_req += 1
	path_i = 0
	if G.grid.wants_async(position, to):
		path = G.grid.cached_path(position, to, nav_mode)
		if path.size() > 0:
			return
		path = G.grid.provisional(position, to, nav_mode)
		if path.size() > 0:
			G.grid.request_path(position, to, nav_mode, _on_path.bind(path_req))
			return
	path = G.grid.find_path(position, to, nav_mode)

func _on_path(res: PackedVector3Array, req: int) -> void:
	if req != path_req or not alive or order == "":
		return
	path = G.grid.splice(res, position, nav_mode)
	path_i = 0

func follow_route(pts: PackedVector3Array) -> void:
	path = pts
	path_i = 0
	order = "route"

func _range() -> float:
	match vtype:
		"tank":
			return 58.0
		"apc":
			return 50.0
		"technical":
			return 46.0
		"heli":
			return 52.0
		"ifv":
			return 50.0
		"aa":
			return 72.0
		"arty":
			return 150.0
		"transport":
			return 30.0
		"fieldgun":
			return 64.0
		"howitzer":
			return 175.0
		"atgun":
			return 60.0
		"aagun":
			return 64.0
		"hmortar":
			return 110.0
		"mtngun":
			return 125.0
		"mlrs":
			return 180.0
	return 0.0

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	tick_bubble(dt)
	if is_air():
		_air_shadow_tick()
	if slung_by != null and alive:
		_slung_tick(dt)
		return
	if not alive:
		_wreck_tick(dt)
		return
	main_cd -= dt * (0.5 if (crew_max >= 3 and crew_n == 1) else 1.0) / load_mult()
	_stress_tick(dt)
	coax_cd -= dt
	if abandon_t >= 0.0:
		abandon_t -= dt
		if abandon_t <= 0.0:
			say("İMHA!")
			destroy(null)
			return
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.45 + randf() * 0.15
		if not is_air() and G.grid.is_water(position):
			position = G.grid.nearest_free(position, nav_mode, 30)
		# emir yarıda kaldıysa (yol boşaldı ama hedefe varılmadı) yeniden yol bul
		if not is_air() and order in ["move", "amove", "retreat"] and path_i >= path.size() and dist2_p(dest) > 4.0 and not immobile():
			_repath(dest)
		_scan()
		_refund_check()
	atgm_cd -= dt
	sam_cd -= dt
	if flare_q > 0:
		_flares_tick(dt)
	if vtype in ["uav", "uav_armed"]:
		_uav(dt)
		return
	if vtype == "loiter":
		_fpv(dt)
		return
	if vtype == "fpv":
		_fpv(dt)
		return
	if vtype in ["heli", "transport"]:
		_heli(dt)
		return
	_guard_drive(dt)
	_drive(dt)
	_sep_vehicles()
	_aim_fire(dt)
	_visuals(dt)

# tekerli mi (katalog ailesinden): lastikler patlar ve tamir edilir
func needs_setup() -> bool:
	return vtype in TOWED or vtype in ["arty", "mlrs"]

func pack_time() -> float:
	return {"howitzer": 9.0, "fieldgun": 5.0, "atgun": 4.0, "aagun": 4.0, "hmortar": 4.0, "mtngun": 5.0, "arty": 3.0, "mlrs": 4.0}.get(vtype, 4.0)

func deploy_time() -> float:
	return pack_time() * 1.2

func wheeled() -> bool:
	if vid != "":
		var fam: String = cat.get("fam", "")
		return not (fam.begins_with("mbt") or fam.contains("_tr") or fam in ["lt", "apc_box", "apc_amph", "apc_mtlb", "ifv_bmp", "ifv_bmd", "ifv_heavy", "bmpt", "td_box", "td_ontos", "spg", "spg_ru", "spg_open", "mortar_tr", "mlrs_t", "mlrs_tos", "eng_breach", "eng_dozer", "eng_bridge", "eng_recovery", "sam_ru_tr"]) and wheels.size() > 0
	return vtype in WHEELED

func tracked() -> bool:
	return not wheeled() and not is_air() and not (vtype in TOWED)

func immobile() -> bool:
	return crit["mob"] >= 2 or tracks_broken > 0.0 or not driver_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0 or (wheeled() and tires >= maxi(wheels.size(), 4))

func speed_factor() -> float:
	var mud: float = G.weather.mud() if G.weather != null and wheeled() else 1.0
	return clampf(1.0 - 0.2 * tires, 0.3, 1.0) * (0.55 if crit["mob"] == 1 else 1.0) * mud

func has_crit() -> bool:
	for k in crit:
		if crit[k] > 0:
			return true
	return false

func load_mult() -> float:
	return [1.0, 1.6, 2.6][crit["load"]] * (1.3 if vstress_lv >= 1 else 1.0)

func aim_mult() -> float:
	return [1.0, 1.8, 3.0][crit["tgt"]] * (1.3 if vstress_lv >= 1 else 1.0)

func tturn_mult() -> float:
	return [1.0, 0.65, 0.35][crit["tgt"]]

func add_crit(k: String, lvl: int) -> void:
	if not alive or is_air():
		return
	crit[k] = mini(2, crit[k] + lvl)
	crit_t[k] = 22.0 if crit[k] == 1 else 40.0
	sight = D["sight"] * [1.0, 0.7, 0.4][crit["opt"]]
	say(I18n.s(CRIT_NAME[k]) + (" " + I18n.s("HASARLI!") if crit[k] == 1 else " " + I18n.s("KRİTİK!")), 2.5)

func _crit_roll(dmg: float, m: float, k: String) -> void:
	if crew_max <= 0 and ARMOR.get(vtype, []).is_empty():
		return
	var pen := m > 0.46
	var light_at := k in ["rpg", "atgm", "topatk", "fpv"]
	var ch := 0.0
	if pen:
		ch = 1.0 if light_at else 0.1 + dmg / max_hp * 1.2
	elif k in ["rpg", "atgm", "ap", "he", "shell", "big", "mortar", "topatk"]:
		ch = 0.2
	if randf() >= ch:
		return
	var lvl := 2 if (pen and (dmg > max_hp * 0.2 or randf() < 0.3)) else 1
	var r := randf()
	var top := k in ["topatk", "shell", "big", "mortar", "fpv"]
	var kk := "mob" if r < 0.3 else ("opt" if r < (0.65 if top else 0.55) else ("tgt" if r < 0.8 else "load"))
	add_crit(kk, lvl)

func add_vstress(v: float) -> void:
	if crew_max <= 0 or is_air():
		return
	vstress = minf(100.0, vstress + v)
	vstress_t = G.time

func _stress_tick(dt: float) -> void:
	if vstress > 0.0 and G.time - vstress_t > 5.0:
		vstress = maxf(0.0, vstress - dt * 4.0)
	var nl := 2 if vstress >= 85.0 else (1 if vstress >= 50.0 else 0)
	if vstress_lv == 2 and vstress > 55.0:
		nl = 2
	if nl > vstress_lv:
		say("MÜRETTEBAT PANİKTE!" if nl == 2 else "MÜRETTEBAT SARSILDI!", 2.5)
		if nl == 2 and order != "retreat" and not immobile() and hp < max_hp * 0.6:
			cmd_retreat()
	vstress_lv = nl
	# kritik onarımı: mürettebat ateş altında değilken
	if crew_n > 0 and G.time - last_hit > 5.0:
		for k in crit:
			if crit[k] > 0:
				crit_t[k] -= dt
				if crit_t[k] <= 0.0:
					crit[k] -= 1
					crit_t[k] = 22.0
					sight = D["sight"] * [1.0, 0.7, 0.4][crit["opt"]]
					if crit[k] == 0:
						say(I18n.s(CRIT_NAME[k]) + " " + I18n.s("ONARILDI"), 2.0)

func needs_crew() -> bool:
	return alive and abandon_t < 0.0 and crew_max > 0 and (crew_n < crew_max or not driver_ok or not gunner_ok)

# piyade araca binip eksik mürettebatın yerine geçer
func add_crew(s) -> void:
	if not driver_ok:
		driver_ok = true
	elif not gunner_ok:
		gunner_ok = true
		if gunner:
			gunner.visible = true
	crew_n = mini(crew_max, crew_n + 1)
	say("MÜRETTEBAT TAMAM" if crew_n >= crew_max and driver_ok and gunner_ok else "YERİME GEÇTİ")
	if s != null and is_instance_valid(s):
		s.vanish()

# palet: mürettebat ateş altında değilken onarır (mühendis daha hızlı)
func _repair_tick(dt: float) -> void:
	var busy := tracks_broken > 0.0 and crew_n > 0 and G.time - last_hit > 7.0
	if busy:
		tracks_broken -= dt
		if tracks_broken <= 0.0:
			tracks_broken = 0.0
			say("PALET ONARILDI")
	if busy and repair_body == null:
		repair_body = SoldierBody.new()
		hull.add_child(repair_body)
		repair_body.build(team, "engineer", G.map_kind == "winter")
		repair_body.position = Vector3(1.9 if randf() < 0.5 else -1.9, 0, 1.0)
		repair_body.rotation.y = PI * 0.5 * signf(repair_body.position.x)
	elif not busy and repair_body != null:
		repair_body.queue_free()
		repair_body = null
	if repair_body:
		repair_body.animate(dt, "build", 0.0)

func cmd_abandon() -> void:
	if not alive or crew_n <= 0 or abandon_t >= 0.0 or is_air():
		return
	unload()
	var sq := Squad.new(team, "Mürettebat")
	G.squads.append(sq)
	var back := -forward()
	var sd := Vector3(-back.z, 0, back.x)
	for i in crew_n:
		var p: Vector3 = position + back * (D["len"] * 0.5 + 1.0) + sd * (i - 1) * 1.3
		var s: Soldier = G.main.spawn_soldier(team, "crew", G.grid.nearest_free(p, Grid.M_INF), sq)
		s.cmd_move(G.grid.nearest_free(p + back * 6.0, Grid.M_INF), true)
	crew_n = 0
	abandon_t = 6.0
	target = null
	path = PackedVector3Array()
	say("ARAÇ TERK EDİLDİ!", 3.0)
	if selected and G.player:
		G.player.deselect(self)

func _kill_gunner(src) -> void:
	if not gunner_ok:
		return
	gunner_ok = false
	crew_n = maxi(0, crew_n - 1)
	target = null
	if gunner and gunner.visible:
		var gp := gunner.global_position
		gunner.visible = false
		var s: Soldier = G.main.spawn_soldier(team, "rifle", G.on_ground(gp), null)
		s.position = gp
		s.die(src)
	say("NİŞANCI VURULDU!", 2.5)

func _kill_driver(src) -> void:
	if not driver_ok:
		return
	driver_ok = false
	crew_n = maxi(0, crew_n - 1)
	cur_speed = 0.0
	path = PackedVector3Array()
	say("SÜRÜCÜ VURULDU!", 2.5)
	src = src

func _cell_ok(p: Vector3) -> bool:
	if G.grid.is_water(p):
		return false
	var h := G.grid.height_at(p)
	var k := G.grid.kind_at(p)
	if k == Grid.K_TRAP:
		return false
	return h < 0.3 or k == Grid.K_TREE or (nav_mode == Grid.M_HEAVY and k == Grid.K_WALL)

# azami hız: yoldaysa gerçek yol hızı (tekerlekli araç asfaltta belirgin hızlı), değilse arazi hızı
func _vmax(dt: float) -> float:
	_road_t -= dt
	if _road_t <= 0.0:
		_road_t = 0.3
		_on_road = road_speed > 0.0 and G.terrain != null and G.terrain.on_road(position)
	return road_speed if _on_road else speed_max

func _drive(dt: float) -> void:
	_repair_tick(dt)
	if immobile():
		cur_speed = move_toward(cur_speed, 0.0, 6.0 * dt)
	var target_speed := 0.0
	var vm := _vmax(dt)
	if not immobile():
		while path_i < path.size():
			var tp := path[path_i]
			var d := Vector3(tp.x - position.x, 0, tp.z - position.z)
			var L := d.length()
			var last := path_i == path.size() - 1
			if L < (1.6 if last else 3.0):
				path_i += 1
				if path_i >= path.size():
					_arrive()
				continue
			var want := Soldier._yaw_of(-d if reverse else d)
			# köprüde: eksene hizalan, korkuluğa sürtünme
			var br := G.grid.bridge_at(position)
			if not br.is_empty():
				var ax: Vector3 = br["d"]
				var mv := -d if reverse else d
				if ax.dot(mv) < 0.0:
					ax = -ax
				var rel: Vector3 = position - br["c"]
				rel.y = 0
				var on_axis: Vector3 = br["c"] + br["d"] * rel.dot(br["d"])
				var aim: Vector3 = on_axis + ax * 6.0 - position
				want = Soldier._yaw_of(-aim if reverse else aim)
			var diff := absf(angle_difference(heading, want))
			var tr: float = D["turn"]
			if armor < 2:
				tr *= clampf(0.35 + absf(cur_speed) / speed_max, 0.35, 1.2)
			heading = rotate_toward(heading, want, tr * dt)
			if vtype == "tank":
				target_speed = vm * clampf(1.0 - diff / 0.9, 0.0, 1.0)
			else:
				target_speed = vm * clampf(1.0 - diff / 1.6, 0.25, 1.0)
			var rem := L
			for k in range(path_i + 1, path.size()):
				rem += path[k].distance_to(path[k - 1])
				if rem > 15.0:
					break
			if rem < 8.0:
				target_speed = minf(target_speed, maxf(1.5, rem * 0.8))
			if order == "attack" and target != null and target == forced_target:
				target_speed = 0.0
				path = PackedVector3Array()
			elif order == "amove" and target != null and fire_mode != 2:
				target_speed = 0.0
			target_speed *= speed_factor()
			if reverse:
				target_speed = -minf(target_speed, speed_max * 0.45)
			break
	# çekili top / havan / roketatar / obüs: yürümeden önce toplanır, durunca kurulur
	if needs_setup():
		if absf(target_speed) > 0.05:
			if deployed > 0.0:
				deployed = maxf(0.0, deployed - dt / pack_time())
				target_speed = 0.0
				if deployed <= 0.0:
					say("TOPLANDI, YÜRÜYÜŞE HAZIR")
		elif absf(cur_speed) < 0.1 and deployed < 1.0:
			deployed = minf(1.0, deployed + dt / deploy_time())
			if deployed >= 1.0:
				say("TOP KURULDU, ATEŞE HAZIR")
	cur_speed = move_toward(cur_speed, target_speed, D["accel"] * dt * (2.0 if target_speed < cur_speed else 1.0))
	if absf(cur_speed) < 0.01:
		return
	_give_way(dt)
	if absf(cur_speed) < 0.01:
		return
	var f := forward()
	var np := position + f * cur_speed * dt
	# engel denetimi (ön nokta)
	var front: Vector3 = np + f * signf(cur_speed) * (D["len"] * 0.45)
	var hf := G.grid.height_at(front)
	var kf := G.grid.kind_at(front)
	var blocked := (hf >= 0.3 and kf != Grid.K_TREE and not (nav_mode == Grid.M_HEAVY and kf == Grid.K_WALL)) or kf == Grid.K_TRAP
	if blocked:
		# boş tarafa dönerek kaymaya çalış
		var sd := Vector3(-f.z, 0, f.x)
		var lf := _cell_ok(front + sd * 1.4)
		var rf := _cell_ok(front - sd * 1.4)
		if lf and not rf:
			heading -= D["turn"] * dt
		elif rf and not lf:
			heading += D["turn"] * dt
		cur_speed = 0.0
		_stuck_t += dt
		if _stuck_t > 1.2:
			_stuck_t = 0.0
			# biraz geri çekil ve yeniden yol bul
			var bp := position - f * signf(cur_speed + 0.001) * 0.8
			if _cell_ok(bp):
				position = bp
			if path_i < path.size():
				_repath(path[path.size() - 1])
		return
	# diğer araçlarla ayrışma
	for o in G.near(np, 7.0):
		if o == self or not (o is Vehicle):
			continue
		var dv = np - o.position
		dv.y = 0
		var dl = dv.length()
		var rr: float = (radius + o.radius) * 0.75
		if dl < rr and dl > 0.01:
			np += dv / dl * (rr - dl) * 0.5
	np.x = clampf(np.x, 2.0, G.MAP - 2.0)
	np.z = clampf(np.z, 2.0, G.MAP - 2.0)
	if not _cell_ok(np):
		# ayrışma itmesi suya / korkuluğa sokmasın
		np = position + f * cur_speed * dt
		if not _cell_ok(np) and G.grid.is_water(np):
			cur_speed = 0.0
			return
	var moved := np.distance_to(position)
	position = np
	# ezme
	if nav_mode == Grid.M_HEAVY:
		_crush_t -= dt
		if _crush_t <= 0.0:
			_crush_t = 0.12
			var fp = position + f * (D["len"] * 0.42)
			if G.blocks.crush(fp, 1.7, f, 0.5):
				cur_speed *= 0.6
				rock_v -= 1.5
			G.props.crush(fp, 2.0, f)
	for o in G.near(position + f * 2.0, 2.2):
		if o is Soldier and o.alive and o.team != team and absf(cur_speed) > 2.0:
			o.take_damage(200.0, self, "crush")
	# izler
	_track_acc += moved
	if _track_acc > 0.3:
		_track_acc = 0.0
		var side := Vector3(-f.z, 0, f.x)
		var tw := 1.25 if vtype == "tank" else 1.0
		G.terrain.track(position + side * tw, 0.4)
		G.terrain.track(position - side * tw, 0.4)
	_dust_t -= dt
	if _dust_t <= 0.0 and absf(cur_speed) > 2.5:
		_dust_t = 0.12
		G.fx.vehicle_dust(position - f * (D["len"] * 0.45) + Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1)))
		if randf() < 0.4:
			G.fx.exhaust(position - f * (D["len"] * 0.5) + Vector3(0, 1.0, 0), 1.0)

# ------------------------------------------------------------ takılma bekçisi (kara aracı)
# Yürüyüş emrinde ilerleme ölçütü: 15 sn'de 1 m yer değiştirmeyen araç biraz geri çekilip yolu yeniden
# arar; üç denemede (45 sn) ilerleyemezse emri bırakır ve bir kez "STUCK-RESOLVE Vehicle move <sn>" yazar.
# Bilerek duran araç sayılmaz: saldırı hareketinde çatışan, toplanan/kurulan top, hareketsiz (palet/sürücü).
# İkmal kamyonu emri bırakmaz (lojistik hattı), yalnız yeniden yol arar.
var _vg_goal := Vector3.INF
var _vg_best := 0.0
var _vg_t := 0.0
var _vg_n := 0

func _guard_drive(dt: float) -> void:
	var moving := order in ["move", "amove", "retreat", "refund", "route", "attack"] and path_i < path.size() and not immobile()
	if moving and order == "amove" and target != null and fire_mode != 2:
		moving = false
	if moving and needs_setup() and deployed > 0.0:
		moving = false
	if not moving:
		_vg_goal = Vector3.INF
		_vg_t = 0.0
		_vg_n = 0
		return
	# ilerleme ölçütü: yolun sonuna kalan mesafe azalıyor mu (yer değiştirme değil — engelde geri çekilip
	# yeniden deneyen araç salınır, yer değiştirir ama ilerlemez)
	var goal := path[path.size() - 1]
	var dd := Vector2(goal.x - position.x, goal.z - position.z).length()
	if _vg_goal == Vector3.INF or goal.distance_to(_vg_goal) > 2.0:
		_vg_goal = goal
		_vg_best = dd
		_vg_t = 0.0
		_vg_n = 0
		return
	if dd < _vg_best - 1.0:
		_vg_best = dd
		_vg_t = 0.0
		return
	_vg_t += dt
	if _vg_t < 15.0:
		return
	_vg_t = 0.0
	_vg_n += 1
	if _vg_n >= 3 and vtype != "truck":
		print("STUCK-RESOLVE Vehicle move %d %s order=%s p=(%.0f,%.0f)" % [_vg_n * 15, vid if vid != "" else vtype, order, position.x, position.z])
		_vg_n = 0
		if order == "attack":
			forced_target = null
			order = ""
		_arrive()
		if team == G.player_team and not G.spectate:
			say("YOL YOK!", 2.0)
		return
	# engelden kurtul: biraz geri çekil (ya da en yakın boş hücreye çık), yolu yeniden ara
	var bp := position - forward() * 1.5
	if _cell_ok(bp):
		position = bp
	elif not _cell_ok(position):
		position = G.grid.nearest_free(position, nav_mode)
	_repath(path[path.size() - 1])

func _arrive() -> void:
	path = PackedVector3Array()
	path_i = 0
	if order in ["move", "amove", "retreat"]:
		order = ""
	reverse = false
	retreating = false
	if vtype == "truck" and G.logi:
		G.logi.truck_arrived(self)

func _scan() -> void:
	if vtype == "truck":
		return
	# "ateş kes" kendiliğinden ateşi keser; oyuncunun açık saldırı emri (forced_target) bunu geçersiz kılar
	var hold := fire_mode == 2 and not (order == "attack" and forced_target != null)
	if retreating or hold or (fire_mode == 1 and G.time - last_hit > 10.0) or not gunner_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0:
		target = null
		coax_target = null
		return
	var rng_w := _range()
	var eye := turret_world_pos() + Vector3(0, 0.4, 0)
	if forced_target != null and (not is_instance_valid(forced_target) or not forced_target.hostile()):
		forced_target = null
		if order == "attack":
			order = ""
	var best: Unit = null
	var bs := 1e9
	var best_inf: Unit = null
	var bsi := 1e9
	var cands: Array = []
	for e in G.enemies_near(position, rng_w + 4.0, team):
		if not e.alive or not G.is_seen(e, team):
			continue
		if e is Soldier and e.incapacitated():
			continue
		var d := dist2(e)
		var sc := d
		var air: bool = e is Vehicle and e.is_air()
		if vtype == "aa":
			if air:
				sc -= 200.0
			elif d > 46.0 or e is Building:
				continue
		elif air and not (vtype in ["apc", "ifv", "technical", "heli"]) :
			continue
		elif air:
			sc += 15.0
		if vtype == "aagun":
			if air:
				sc -= 200.0
			elif d > 40.0 or e is Building or (e is Vehicle and e.armor > 0):
				continue
		elif vtype == "atgun":
			if air:
				continue
			sc -= 60.0 if (e is Vehicle and e.armor > 0) else (0.0 if e is Vehicle else -25.0)
		elif vtype == "fieldgun" and air:
			continue
		if vtype in INDIRECT:
			if d < _min_range() or air:
				continue
			sc -= G.enemies_near(e.position, 8.0, team).size() * 6.0 + (25.0 if e is Building else 0.0)
		if vtype == "tank":
			if e is Vehicle:
				sc -= 30.0 + (20.0 if e.vtype in ["tank", "apc"] else 0.0)
			elif e is Building:
				sc -= 5.0
		elif vtype == "apc":
			if e is Vehicle and e.vtype == "technical":
				sc -= 15.0
			elif e is Vehicle and e.vtype == "tank":
				sc += 10.0
		else:
			if e is Vehicle and e.armor > 0:
				sc += 40.0
			elif e is Building:
				sc += 30.0
		if e == forced_target:
			sc -= 200.0
		cands.append([sc, e])
		if e is Soldier and d < 42.0 and d < bsi:
			bsi = d
			best_inf = e
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var n := 0
	for cc in cands:
		n += 1
		if n > 4:
			break
		var e: Unit = cc[1]
		if (vtype in INDIRECT) or (e is Vehicle and e.is_air()) or G.grid.los(eye, e.aim_point(), D["len"] * 0.5, 1.6 if e is Soldier and e.house_id >= 0 else 0.5):
			best = e
			break
	target = best
	coax_target = null
	if vtype == "tank" and best_inf != null and G.grid.los(eye, best_inf.aim_point(), 3.0, 1.6 if best_inf.house_id >= 0 else 0.5):
		coax_target = best_inf
	if order == "attack" and forced_target != null and best != forced_target:
		_close_on_forced()

# saldırı emri verilen hedef vurulamıyor (görülmüyor / menzil dışı / görüş hattı kapalı): doğrudan atışlı kara
# aracı (çekili top dahil) piyadedeki gibi hedefe yaklaşır — yoksa emir sessizce askıda kalır. Dolaylı atışlı
# topçu yaklaşmaz (asgari menzil); gözcü gerektiğini söyler.
var _chase_t := 0.0

func _close_on_forced() -> void:
	var ft: Unit = forced_target
	if not is_instance_valid(ft) or not ft.hostile() or is_air() or immobile() or (ft is Vehicle and ft.is_air()):
		return
	if G.time < _chase_t:
		return
	if vtype in INDIRECT:
		if not G.is_seen(ft, team):
			_chase_t = G.time + 8.0
			say("HEDEF GÖRÜLMÜYOR, GÖZCÜ GEREK", 2.5)
		elif dist2(ft) < _min_range():
			_chase_t = G.time + 6.0
			say("ASGARİ MENZİLİN İÇİNDE", 2.5)
			if vtype in ["arty", "mlrs"] and not immobile():
				# kundağı motorlu: hedeften asgari menzilin dışına çekil (emir sürer, sonra ateş eder)
				var away := position - ft.position
				away.y = 0.0
				if away.length() < 0.1:
					away = -forward()
				dest = G.grid.nearest_free(ft.position + away.normalized() * (_min_range() + 10.0), nav_mode)
				_repath(dest)
			else:
				# çekili top kendi kendine çekilemez: emir bırakılır
				forced_target = null
				order = ""
		return
	var d := dist2(ft)
	if d < 8.0:
		return
	var stand := minf(minf(sight, _range()) * 0.7, d * 0.6)
	var goal: Vector3 = G.grid.nearest_free(ft.position + (position - ft.position).normalized() * stand, nav_mode)
	if path_i < path.size() and goal.distance_to(dest) < 4.0:
		return
	_chase_t = G.time + 1.5
	dest = goal
	_repath(dest)

func _aim_fire(dt: float) -> void:
	if turret == null or G.deploy_t > 0.0:
		return
	if needs_setup() and deployed < 1.0:
		return
	if G.time < ground_until and fire_mode != 2:
		var wl := wrapf(Soldier._yaw_of(ground_pt - position) - heading, -PI, PI)
		turret_yaw = rotate_toward(turret_yaw, wl, D["tturn"] * tturn_mult() * dt)
		turret.rotation.y = turret_yaw
		if barrel:
			recoil = move_toward(recoil, 0.0, dt * 1.4)
			barrel.position = (M["barrel_pos"] as Vector3) + Vector3(0, 0, recoil * 0.6)
		if absf(angle_difference(turret_yaw, wl)) < 0.1 and main_cd <= 0.0 and dist2_p(ground_pt) <= _range():
			_fire_ground()
		return
	var t := target
	var want_local := 0.0
	if t != null and is_instance_valid(t) and t.alive:
		var d := t.position - position
		want_local = wrapf(Soldier._yaw_of(d) - heading, -PI, PI)
	turret_yaw = rotate_toward(turret_yaw, want_local, D["tturn"] * tturn_mult() * dt)
	turret.rotation.y = turret_yaw
	if barrel:
		recoil = move_toward(recoil, 0.0, dt * 1.4)
		barrel.position = (M["barrel_pos"] as Vector3) + Vector3(0, 0, recoil * 0.6)
	if t == null or not is_instance_valid(t) or not t.alive:
		_coax(dt)
		return
	var aligned := absf(angle_difference(turret_yaw, want_local)) < (0.05 if vtype == "tank" else 0.12)
	var dist := dist2(t)
	if aligned and dist <= _range() and main_cd <= 0.0:
		match vtype:
			"tank":
				_fire_cannon(t)
			"apc":
				_fire_auto(t)
			"technical":
				_fire_hmg(t)
			"ifv":
				_fire_auto(t)
				if atgm_cd <= 0.0 and t is Vehicle and t.armor > 0 and not t.is_air():
					atgm_cd = 14.0
					var mp := muzzle_world() + Vector3(0, 0.4, 0)
					G.bal.rocket(mp, t.aim_point(), team, self, t, "atgm")
					Sfx.play3d("rpg", mp, 2.0)
			"aa", "aagun":
				if not _fire_sam(t):
					_fire_flak(t)
			"arty":
				_fire_arty(t)
			"fieldgun":
				_fire_cannon(t)
				main_cd = _rl(5.0)
				on_crew_fire()
			"atgun":
				_fire_atgun(t)
			"howitzer":
				_fire_arty(t)
				main_cd = _rl(11.0)
				on_crew_fire()
			"mtngun":
				_fire_arty(t)
				main_cd = _rl(7.0)
				on_crew_fire()
			"hmortar":
				_fire_hmortar(t.position)
			"mlrs":
				if mlrs_left <= 0:
					mlrs_left = salvo_n if salvo_n > 0 else 12
					mlrs_aim = t.position
	_coax(dt)
	_mlrs_tick(dt)
	_crew_anim(dt)

var mlrs_aim := Vector3.ZERO

# roketatar: 12 roketlik salvo, sonra uzun dolum
func _mlrs_tick(dt: float) -> void:
	if vtype != "mlrs" or mlrs_left <= 0:
		return
	mlrs_t -= dt
	if mlrs_t > 0.0:
		return
	mlrs_t = salvo_ival if salvo_ival > 0.0 else 0.22
	mlrs_left -= 1
	var mp := muzzle_world() + Vector3(randf_range(-0.6, 0.6), randf_range(-0.2, 0.2), 0)
	var d := dist2_p(mlrs_aim)
	var err := d * 0.07 + 4.0
	G.bal.mlrs_rocket(mp, mlrs_aim + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self)
	Sfx.play3d("rpg", mp, 3.0, 0.15, 0.05)
	var back := -(mlrs_aim - position).normalized()
	for i in 3:
		G.fx.emit(Fx.P_SMOKE, mp, back * randf_range(3, 7) + Vector3(randf_range(-1, 1), randf_range(0.5, 2), randf_range(-1, 1)), randf_range(1.5, 2.8), 0.6, 2.6, -0.1, 1.5, Color(0.82, 0.8, 0.76, 0.55))
	G.fx.muzzle(mp, -back, true)
	if mlrs_left <= 0:
		main_cd = rearm_s if rearm_s > 0.0 else 32.0

# atış hızı (roadmap 2): gerçek veri varsa onu, yoksa tipin varsayılanını kullan
func _rl(def: float) -> float:
	return reload_s if reload_s > 0.0 else def

func _burst_len(a: int, b: int) -> int:
	return maxi(1, burst_n + randi_range(-1, 1)) if burst_n > 0 else randi_range(a, b)

func _auto_ival(def: float) -> float:
	return maxf(60.0 / rpm, 0.04) if rpm > 0.0 else def

func _fire_atgun(t: Unit) -> void:
	main_cd = _rl(4.2)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var spread := mp.distance_to(tp) * 0.015
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.2), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "ap" if t is Vehicle or t is Building else "he")
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 3.0)
	recoil = 1.0
	on_crew_fire()

func _fire_hmortar(tp: Vector3) -> void:
	main_cd = _rl(randf_range(4.5, 5.5))
	var d := dist2_p(tp)
	var err := d * 0.05 + 2.0
	var mp := muzzle_world()
	G.bal.mortar(mp, tp + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self, ammo_he)
	Sfx.play3d("mortar", mp, 3.0)
	G.fx.muzzle(mp, Vector3.UP, true)
	recoil = 0.6
	on_crew_fire()

# ------------------------------------------------------------ çekili top mürettebatı
# Döngü (atıştan sonra main_cd boyunca): herkes kulak kapatır → doldurucu kamayı açar, boş kovan
# geriye fırlar → cephaneci sandık yığınından mermi alıp doldurucuya taşır → doldurucu mermiyi
# kamaya sürer, kapatır → nişancı yükseliş volanını çevirir → nişancı ipi çeker (atış).
# Havan: doldurucu mermiyi namlu ağzına bırakır ve eğilir.
var crew_cycle := 0.0
var _crew_spots: Array = []
var _casing_done := false
var _ammo_pile: Node3D = null
static var _shell_m: Mesh = null
static var _case_m: Mesh = null

func _crew_meshes() -> void:
	if _shell_m != null:
		return
	var X := Basis(Vector3.RIGHT, -PI * 0.5)
	var mb := MB.new()
	mb.cyl(Vector3(0, 0, -0.32), 0.0, 0.05, 0.12, 10, Color(0.6, 0.5, 0.22), X)
	mb.cyl(Vector3(0, 0, -0.1), 0.05, 0.065, 0.32, 10, Color(0.32, 0.35, 0.26), X)
	mb.cyl(Vector3(0, 0, 0.12), 0.065, 0.065, 0.14, 10, Color(0.32, 0.35, 0.26), X)
	mb.cyl(Vector3(0, 0, 0.2), 0.068, 0.068, 0.03, 10, Color(0.62, 0.42, 0.22), X)
	_shell_m = mb.commit(Mats.vc())
	var cb := MB.new()
	cb.cyl(Vector3(0, 0, 0), 0.062, 0.066, 0.42, 10, Color(0.78, 0.6, 0.25), X)
	cb.cyl(Vector3(0, 0, 0.21), 0.072, 0.072, 0.02, 10, Color(0.7, 0.52, 0.2), X)
	_case_m = cb.commit(Mats.metal())

func _crew_setup_props() -> void:
	_crew_meshes()
	# cephane sandıkları: topun arkasında iki sıra, üstte açık kapaklı sandık
	var mb := MB.new()
	var od := Color(0.3, 0.33, 0.22)
	for k in 4:
		var x := (k % 2) * 0.62
		var y := (k / 2) * 0.3
		mb.box(Vector3(x, 0.15 + y, 0), Vector3(0.58, 0.28, 0.42), od.darkened(0.05 * k))
		mb.box(Vector3(x + 0.3, 0.15 + y, 0), Vector3(0.02, 0.08, 0.2), Color(0.15, 0.15, 0.12))
	mb.box(Vector3(0.31, 0.68, 0), Vector3(0.58, 0.04, 0.42), od.lightened(0.05), Basis(Vector3.RIGHT, -1.1))
	for k in 3:
		mb.cyl(Vector3(0.12 + k * 0.17, 0.62, 0.0), 0.06, 0.06, 0.12, 8, Color(0.6, 0.5, 0.22))
	_ammo_pile = MeshInstance3D.new()
	(_ammo_pile as MeshInstance3D).mesh = mb.commit(Mats.vcs())
	hull.add_child(_ammo_pile)
	_ammo_pile.position = Vector3(0.9, 0, ext.y + 1.6)
	for cb in crew:
		_crew_spots.append(cb.position)

func _breech_local() -> Vector3:
	if barrel == null:
		return Vector3(0, 0.9, 0.6)
	var w := barrel.global_transform * Vector3(0, 0, 0.55)
	return hull.to_local(w)

func _muzzle_local() -> Vector3:
	if barrel == null:
		return Vector3(0, 1.2, -0.6)
	return hull.to_local(barrel.global_transform * (M["muzzle"] as Vector3))

func on_crew_fire() -> void:
	crew_cycle = maxf(main_cd, 0.1)
	_casing_done = false

func _eject_casing() -> void:
	if vtype in ["hmortar", "aagun"]:
		return
	var bw := hull.to_global(_breech_local() + Vector3(0, 0, 0.25))
	var mi := MeshInstance3D.new()
	mi.mesh = _case_m
	G.main.world.add_child(mi)
	mi.global_position = bw
	var back := -forward()
	var land := bw + back * randf_range(0.9, 1.6) + right() * randf_range(-0.5, 0.5)
	land.y = 0.07
	var tw := mi.create_tween()
	var mid := (bw + land) * 0.5 + Vector3(0, 0.5, 0)
	tw.tween_property(mi, "global_position", mid, 0.18).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "rotation", Vector3(randf_range(2, 4), randf_range(0, 3), 0), 0.4)
	tw.tween_property(mi, "global_position", land, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(mi, "rotation:x", PI * 0.5, 0.05)
	tw.tween_interval(30.0)
	tw.tween_callback(mi.queue_free)
	G.fx.exhaust(bw, 0.8)
	Sfx.play3d("hit_metal", land, -14.0, 0.2, 0.1)

func _crew_anim(dt: float) -> void:
	if crew.is_empty():
		return
	if _crew_spots.is_empty():
		_crew_setup_props()
	var busy := crew_cycle > 0.0 and main_cd > 0.0 and alive
	var p := 1.0 - clampf(main_cd / maxf(crew_cycle, 0.01), 0.0, 1.0) if busy else 1.0
	var br := _breech_local()
	var mortar := vtype == "hmortar"
	var pile: Vector3 = _ammo_pile.position + Vector3(0.3, 0, -0.35) if _ammo_pile else Vector3(1, 0, 3)
	var load_pt: Vector3 = (_muzzle_local() + Vector3(0.45, -_muzzle_local().y, 0.25)) if mortar else Vector3(br.x + 0.75, 0, br.z + 0.35)
	if busy and p > 0.14 and not _casing_done:
		_casing_done = true
		_eject_casing()
	for i in crew.size():
		var cb: SoldierBody = crew[i]
		var home: Vector3 = _crew_spots[i]
		var pose := "crouch_aim" if target != null else "crouch"
		var spd := 0.0
		var goal := home
		var face := br
		var extra := 0.0
		var tool := ""
		if busy:
			if p < 0.12:
				pose = "cover"          # atış: kulak kapat, başı eğ
			elif i == 0:
				# nişancı: yükseliş/yön volanı
				goal = Vector3(br.x - 0.75, 0, br.z + 0.1)
				pose = "lay" if p < 0.92 else "crouch_aim"
			elif i == 1:
				# doldurucu: kamayı aç → mermiyi al → kamaya sür
				goal = load_pt
				if p < 0.3:
					pose = "ram"
					extra = 0.3
				elif p < 0.62:
					pose = "crouch"
				elif p < 0.72:
					pose = "carry"
					extra = 1.0
					tool = "shell"
				elif p < 0.9:
					pose = "ram" if not mortar else "drop"
					extra = clampf((p - 0.72) / 0.18, 0.0, 1.0)
					tool = "shell" if extra < 0.7 else ""
				else:
					pose = "crouch"
			elif i == 2:
				# cephaneci: yığından mermi al, doldurucuya taşı
				if p < 0.4:
					goal = pile
					face = pile + Vector3(0, 0, 1)
					pose = "build" if p > 0.3 else "crouch"
				elif p < 0.62:
					goal = load_pt + Vector3(0.6, 0, 0.6)
					pose = "carry"
					extra = 1.0
					tool = "shell"
					face = load_pt
				else:
					goal = home
					pose = "crouch"
		var cur := cb.position
		var mv := goal - cur
		mv.y = 0.0
		if mv.length() > 0.08:
			var st := minf(mv.length(), dt * 2.4)
			cb.position = cur + mv.normalized() * st
			spd = 2.0
			face = goal + mv.normalized()
			if pose == "crouch" or pose == "crouch_aim":
				pose = "stand"
		var fd := face - cb.position
		if fd.length() > 0.05:
			cb.rotation.y = lerp_angle(cb.rotation.y, atan2(-fd.x, -fd.z), clampf(dt * 6.0, 0.0, 1.0))
		cb.set_tool(tool)
		cb.weapon.visible = false
		cb.animate(dt, pose, spd, extra)

func dist2_p(p: Vector3) -> float:
	return Vector2(position.x - p.x, position.z - p.z).length()

func _fire_ground() -> void:
	# baskı / bombardıman: yere ateş
	var mp := muzzle_world()
	var p := ground_pt + Vector3(randf_range(-3.5, 3.5), 0.1, randf_range(-3.5, 3.5))
	match vtype:
		"tank":
			main_cd = _rl(6.5)
			G.bal.shell(mp, p, team, self, null, "he", ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
			rock_v += 2.5
		"apc", "ifv":
			if burst <= 0:
				burst = _burst_len(3, 5)
			burst -= 1
			main_cd = _auto_ival(0.26) if burst > 0 else randf_range(1.0, 1.8)
			G.bal.shell(mp, p, team, self, null, "auto", ammo_auto)
			G.fx.muzzle(mp, (p - mp).normalized(), true)
			Sfx.play3d("autocannon", mp, 0.0)
			recoil = 0.4
		"technical":
			if burst <= 0:
				burst = randi_range(6, 12)
			burst -= 1
			main_cd = 0.11 if burst > 0 else randf_range(0.6, 1.2)
			shots += 1
			G.fx.muzzle(mp, (p - mp).normalized(), true)
			Sfx.play3d("hmg", mp, 1.0, 0.08, 0.03)
			G.fx.impact(Vector3(p.x, 0.02, p.z), "dirt")
			for o in G.near(p, 3.5):
				if o is Soldier and o.team != team and o.alive:
					o.add_suppression(12.0, position)
			if shots % 2 == 0:
				G.fx.tracer(mp, p, 260.0, Ammo.team_tracer(team), 0.09)
		"arty":
			main_cd = _rl(9.0)
			G.bal.artillery(mp, p, team, self, ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 6.0)
			recoil = 1.0
			rock_v += 3.0
		"fieldgun", "atgun":
			main_cd = _rl(5.0)
			G.bal.shell(mp, p, team, self, null, "he", ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 3.0)
			recoil = 1.0
		"howitzer", "mtngun":
			main_cd = _rl(10.0 if vtype == "howitzer" else 7.0)
			G.bal.artillery(mp, p, team, self, ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
		"hmortar":
			_fire_hmortar(p)
		"mlrs":
			if mlrs_left <= 0:
				mlrs_left = salvo_n if salvo_n > 0 else 12
				mlrs_aim = ground_pt
			main_cd = 0.5
		_:
			main_cd = 1.0

func _fire_flak(t: Unit) -> void:
	if burst <= 0:
		burst = _burst_len(6, 12)
	burst -= 1
	main_cd = _auto_ival(0.07) if burst > 0 else randf_range(0.6, 1.1)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var air: bool = t is Vehicle and t.is_air()
	G.fx.muzzle(mp, (tp - mp).normalized(), true)
	Sfx.play3d("autocannon", mp, -3.0, 0.1, 0.03)
	recoil = 0.25
	var c := 0.32 if air else 0.25
	if t is Vehicle and t.vtype == "fpv":
		c = 0.45
	if t is Vehicle and t.high_alt:
		c *= 0.3     # yüksek irtifa İHA: menzil sınırında, küçük hedef
	var impact := tp + Vector3(randf_range(-2, 2), randf_range(-1, 2), randf_range(-2, 2))
	if randf() < c:
		t.take_damage(26.0, self, "auto")
		impact = tp
	if air:
		if randf() < 0.3:
			G.fx.explosion(impact, 0.35, "flak")
	else:
		impact.y = 0.02
		G.fx.impact(impact, "dirt")
		for o in G.near(impact, 3.0):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(12.0, position)
	G.fx.tracer(mp, impact, 300.0, Ammo.team_tracer(team).lightened(0.2), 0.1)

func _fire_arty(t: Unit) -> void:
	main_cd = _rl(9.0)
	var mp := muzzle_world()
	var d := dist2(t)
	var err := d * 0.05 + 2.0
	var tp := t.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	G.bal.artillery(mp, tp, team, self, ammo_he)
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 6.0)
	recoil = 1.0
	rock_v += 3.0
	G.cam.shake(0.2, position)

func _fire_cannon(t: Unit) -> void:
	main_cd = _rl(6.5)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := d * 0.025 * (1.0 if t is Vehicle else 1.5) * aim_mult()
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.3, 0.3), randf_range(-spread, spread))
	var ap = t is Vehicle and t.armor > 0
	G.bal.shell(mp, tp, team, self, t, "ap" if ap else "he", ammo_ke if ap else ammo_he)
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 5.0)
	recoil = 1.0
	rock_v += 2.5
	G.cam.shake(0.25, position)

func _fire_auto(t: Unit) -> void:
	if burst <= 0:
		burst = _burst_len(3, 5)
	burst -= 1
	main_cd = _auto_ival(0.26) if burst > 0 else randf_range(1.2, 2.2)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := d * 0.04 * aim_mult()
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.4), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "auto", ammo_auto)
	G.fx.muzzle(mp, (tp - mp).normalized(), true)
	Sfx.play3d("autocannon", mp, 0.0)
	recoil = 0.4

func _fire_hmg(t: Unit) -> void:
	if burst <= 0:
		burst = randi_range(5, 10)
	burst -= 1
	main_cd = 0.11 if burst > 0 else randf_range(0.7, 1.4)
	_hitscan(t, 30.0, 0.42, 12.0, "hmg", true)
	Sfx.play3d("hmg", muzzle_world(), 1.0, 0.08, 0.03)

func _coax(_dt: float) -> void:
	if vtype != "tank" or coax_cd > 0.0:
		return
	var t := coax_target
	if t == null or not is_instance_valid(t) or not t.alive:
		return
	if coax_burst <= 0:
		coax_burst = randi_range(6, 12)
	coax_burst -= 1
	coax_cd = 0.1 if coax_burst > 0 else randf_range(0.8, 1.6)
	_hitscan(t, 18.0, 0.32, 9.0, "bullet", false)
	Sfx.play3d("mg", position, -1.0, 0.08, 0.03)

func _hitscan(t: Unit, dmg: float, acc: float, sup: float, k: String, from_barrel: bool) -> void:
	shots += 1
	var mp := muzzle_world() if from_barrel else turret_world_pos() + forward() * 1.2 + Vector3(0, 0.3, 0)
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	if from_barrel:
		G.fx.muzzle(mp, dir, true)
	var d := mp.distance_to(tp)
	var c := acc * (1.0 - clampf(d / 50.0, 0.0, 1.0) * 0.6)
	if t is Soldier:
		c *= [1.0, 0.72, 0.45][t.stance]
		c *= 1.0 - G.grid.cover_factor(t.position, t.torso_h(), position) * 0.75
	else:
		c = 0.85
	if absf(cur_speed) > 1.0:
		c *= 0.6
	c /= aim_mult()
	var impact := tp
	if randf() < c:
		t.take_damage(dmg * randf_range(0.8, 1.2), self, k)
	else:
		var side := Vector3(-dir.z, 0, dir.x)
		impact = tp + side * randf_range(-1.5, 1.5) + dir * randf_range(-0.5, 3.0)
		impact.y = 0.02 if randf() < 0.6 else randf_range(0.0, 1.5)
		G.fx.impact(impact, "wall" if G.grid.height_at(impact) > impact.y else "dirt")
		for o in G.near(impact, 2.8):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(sup, position)
	if shots % 2 == 0:
		G.fx.tracer(mp, impact, 260.0, Ammo.team_tracer(team), 0.09)

func _visuals(dt: float) -> void:
	hull.rotation.y = heading
	# yaylanma
	rock_v += (-rock * 30.0 - rock_v * 5.0) * dt
	rock += rock_v * dt
	hull.rotation.x = rock * 0.02
	var spin := cur_speed * dt
	for w in wheels:
		var wn: MeshInstance3D = w[0]
		wn.rotation.x -= spin / w[1]
	if engine:
		engine.pitch_scale = 0.7 + absf(cur_speed) / speed_max * 0.6
	if gunner:
		gunner.animate(dt, "aim" if target != null else "stand", 0.0)
	if hp < max_hp * 0.4:
		burn_t -= dt
		if burn_t <= 0.0:
			burn_t = 0.3
			var g := randf_range(0.12, 0.22)
			G.fx.emit(Fx.P_SMOKE, position + Vector3(randf_range(-0.5, 0.5), 1.6, randf_range(-0.5, 0.5)), Vector3(randf_range(-0.3, 0.3), randf_range(1.2, 2.0), randf_range(-0.3, 0.3)), randf_range(2.5, 4.0), 0.6, 2.4, -0.2, 0.4, Color(g, g, g, 0.6))

# ------------------------------------------------------------ hasar
func take_damage(amount: float, src, k := "bullet") -> void:
	var from := shot_from
	shot_from = Vector3.INF
	var po := shot_pen        # erken dönen dallarda (hava aracı, ölü) bir sonraki isabete taşınmasın
	shot_pen = []
	if not alive:
		return
	var m := 1.0
	if vtype in ["fpv", "loiter"]:
		hp -= amount
		if hp <= 0.0:
			destroy(null)
		return
	if is_air():
		match k:
			"bullet":
				m = 0.12
			"hmg":
				m = 0.55
			"crush", "grenade":
				m = 0.0
		hp -= amount * m
		last_hit = G.time
		if src != null and is_instance_valid(src):
			attacker = src
		if hp <= 0.0:
			destroy(src)
		return
	if from == Vector3.INF and src != null and is_instance_valid(src):
		from = src.position
	var pk := k
	if k == "bullet" and src != null and is_instance_valid(src) and src is Soldier and src.role == "sniper":
		pk = "sniper"
	shot_pen = po
	m = pen_mult(pk, from)
	if m <= 0.0:
		# delemedi: sekme (mürettebat yine de sarsılır)
		if k in ["ap", "rpg", "atgm", "topatk", "he"]:
			add_vstress(9.0)
			_crit_roll(0.0, 0.0, k)
		if src != null and is_instance_valid(src) and src is Unit:
			attacker = src
		last_hit = G.time
		if k in ["ap", "rpg", "atgm", "auto", "hmg", "topatk"]:
			Sfx.play3d("ricochet", position, 2.0 if k in ["ap", "rpg", "atgm"] else -6.0)
			if k in ["ap", "rpg", "atgm", "topatk"]:
				var sd := (aim_point() - from).normalized() if from != Vector3.INF else -forward()
				var nrm: Vector3 = [forward(), (right() if right().dot(from - position) > 0.0 else -right()), -forward(), Vector3.UP][clampi(last_side, 0, 3)]
				if k == "ap":
					G.fx.ricochet(aim_point(), sd, nrm)
				else:
					# HEAT delemedi: dışta patlar, reaktif zırh tuğlası infilakı
					G.fx.explosion(aim_point() + nrm * 0.3, 0.8, "rpg")
				if G.time - _nopen_t > 2.0:
					_nopen_t = G.time
					say("SEKTİ!" if last_side == 0 else "DELEMEDİ!")
		return
	var dmg := amount * m
	if dmg <= 0.0:
		return
	# delme efekti: geliş yönünde içe saçılma; HEAT'te jet parlaması
	if k in ["ap", "rpg", "atgm", "topatk"] and m > 0.46:
		var pd := (aim_point() - from).normalized() if from != Vector3.INF else -forward()
		G.fx.penetration(aim_point(), pd, k != "ap")
	hp -= dmg
	last_hit = G.time
	if src != null and is_instance_valid(src):
		attacker = src
	_subsystem_hit(dmg, src, k)
	_crit_roll(dmg, m, k)
	add_vstress(dmg / max_hp * 120.0)
	if hp <= 0.0:
		destroy(src)

# atışın geldiği yöne göre zırh yanı: 0 ön, 1 yan, 2 arka, 3 üst
func armor_side(from: Vector3, k: String) -> int:
	var pd: Array = PEN.get(k, PEN["bullet"])
	if pd[3] or from == Vector3.INF:
		return 3
	var to := from - position
	to.y = 0.0
	if to.length() < 0.1:
		return 3
	var f := forward().dot(to.normalized())
	if f > 0.5:
		return 0
	if f < -0.6:
		return 2
	return 1

func armor_tab() -> Array:
	if cat.has("armor"):
		return cat["armor"]
	return ARMOR.get(vtype, [])

func armor_value(kind: int, side: int) -> int:
	var a: Array = armor_tab()
	if a.is_empty():
		return 0
	return a[kind][side]

func pen_at(k: String, dist: float, ov: Array = []) -> float:
	var pd: Array = ov if ov.size() >= 3 else PEN.get(k, PEN["bullet"])
	return lerpf(float(pd[1]), float(pd[2]), clampf(dist / 60.0, 0.0, 1.0))

# delme - zırh farkına göre hasar çarpanı (0 = delemedi)
func pen_mult(k: String, from: Vector3) -> float:
	var ov := shot_pen
	shot_pen = []
	var pd: Array = PEN.get(k, PEN["bullet"])
	if ov.size() >= 3:
		pd = [int(ov[0]), float(ov[1]), float(ov[2]), pd[3]]
	var side := armor_side(from, k)
	var a := armor_value(pd[0], side)
	var dist := 0.0 if from == Vector3.INF else from.distance_to(position)
	var p := pen_at(k, dist, pd)
	last_side = side
	last_pen = p
	if a <= 0:
		return 0.6 if k == "bullet" else 1.0
	var diff := p - a
	if diff >= 0.0:
		return 1.0 + minf(diff, 8.0) * 0.025
	# delemeyen isabet: kinetik küçük kalibre hiç işlemez (sınırda hafif), patlayıcı şok/parça hasarı verir
	if pd[0] == 0 and k in ["bullet", "sniper", "hmg", "auto"]:
		return 0.25 if diff > -1.0 else 0.0
	return maxf(0.0, 1.0 + diff * 0.3) * 0.45

func armor_text() -> String:
	var a: Array = armor_tab()
	if a.is_empty():
		return "-"
	return "%d/%d/%d/%d · HEAT %d/%d/%d/%d" % [a[0][0], a[0][1], a[0][2], a[0][3], a[1][0], a[1][1], a[1][2], a[1][3]]

func _subsystem_hit(dmg: float, src, k: String) -> void:
	var boom := k in ["rpg", "atgm", "topatk", "fpv", "mortar", "ap", "he", "shell", "big", "mine", "grenade"]
	# palet: patlama ve tanksavar
	if tracked() and tracks_broken <= 0.0:
		var pc := {"mine": 1.0, "rpg": 0.2, "atgm": 0.2, "topatk": 0.1, "ap": 0.14, "he": 0.18, "shell": 0.22, "big": 0.3}.get(k, 0.0)
		if randf() < pc:
			tracks_broken = 45.0
			say("PALET KOPTU!", 3.0)
	# teker: kurşun / patlama
	if wheeled():
		var tc := {"bullet": 0.03, "hmg": 0.08, "auto": 0.15, "grenade": 0.35, "shell": 0.4, "big": 0.5, "rpg": 0.3, "mine": 0.9, "he": 0.4}.get(k, 0.0)
		if randf() < tc and tires < maxi(wheels.size(), 4):
			tires += 1
			say("TEKER PATLADI!", 2.0)
	# mürettebat
	if crew_max <= 0:
		return
	var sniper: bool = src != null and is_instance_valid(src) and src is Soldier and src.role == "sniper"
	if armor == 0 and (k == "bullet" or k == "hmg"):
		# açık araç: nişancı ve sürücü vurulabilir
		if gunner and gunner_ok and randf() < (0.7 if sniper else 0.18):
			_kill_gunner(src)
		elif driver_ok and randf() < (0.35 if sniper else 0.06):
			_kill_driver(src)
	elif boom and dmg > 60.0 and randf() < 0.22:
		crew_n = maxi(0, crew_n - 1)
		if crew_n == 0:
			driver_ok = false
			gunner_ok = false
			say("MÜRETTEBAT ÖLDÜ!", 3.0)
		else:
			say("YARALI VAR!", 2.0)
	elif armor == 0 and boom and randf() < 0.25:
		if randf() < 0.5:
			_kill_gunner(src)
		else:
			_kill_driver(src)

func _heli(dt: float) -> void:
	if G.weather != null and G.weather.no_air():
		# kum fırtınası: yere in, bekle
		hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt)
		position += hvel * dt
		hull.position.y = move_toward(hull.position.y, 0.6, dt * 2.0)
		rotor.rotation.y += dt * (28.0 if hull.position.y > 0.7 else 6.0)
		target = null
		return
	var goal := dest
	var t := target
	if sling_tgt != null:
		if can_sling(sling_tgt) and sling == null:
			goal = sling_tgt.position
		else:
			sling_tgt = null
	if drop_pt != Vector3.INF:
		goal = drop_pt
	if rope_pt != Vector3.INF:
		goal = rope_pt
	if forced_target != null and is_instance_valid(forced_target) and forced_target.hostile():
		goal = _attack_spot(dt)
	var d := goal - position
	d.y = 0
	var L := d.length()
	var want := Vector3.ZERO
	if L > 0.5:
		want = d / L * speed_max * clampf(L / 18.0, 0.0, 1.0)
	for o in G.near(position, 10.0):
		if o != self and o is Vehicle and o.vtype in ["heli", "transport"] and o.alive:
			var dv: Vector3 = position - o.position
			dv.y = 0
			if dv.length() > 0.1:
				want += dv.normalized() * 4.0
	var ev := _evade_vec(dt)
	if ev != Vector3.ZERO:
		want = want * 0.4 + ev
	hvel = hvel.move_toward(want, D["accel"] * dt * (2.2 if ev != Vector3.ZERO else 1.0))
	position += hvel * dt
	position.x = clampf(position.x, 2.0, G.MAP - 2.0)
	position.z = clampf(position.z, 2.0, G.MAP - 2.0)
	cur_speed = hvel.length()
	var face := heading
	if t != null and is_instance_valid(t) and t.alive:
		face = Soldier._yaw_of(t.position - position)
	elif hvel.length() > 1.0:
		face = Soldier._yaw_of(hvel)
	heading = rotate_toward(heading, face, D["turn"] * dt)
	if L < 1.5 and order == "move":
		order = ""
	var tgt_alt := ALT + (4.5 if sling != null else 0.0) - (3.5 if evade_t > 0.0 else 0.0)
	var hover := false
	if rope_pt != Vector3.INF and L < 6.0:
		tgt_alt = ROPE_ALT
		hover = _rope_tick(dt, L) or L < 6.0
	if landing:
		tgt_alt = 0.02 if is_cargo() else 0.6
		if L < 1.5 and hull.position.y < 0.9 and not land_hold:
			unload()
	if is_cargo():
		var hook_dy := hook_pos().y - hull.global_position.y
		if sling_tgt != null and L < 2.5:
			# yükün üstünde dur, kancayı indir
			tgt_alt = SLING_L + sling_tgt.top_h + 1.2 - hook_dy + 0.2
			hover = true
			if hull.position.y < tgt_alt + 0.35:
				_attach_sling(sling_tgt)
		elif sling != null and sling_drop:
			tgt_alt = SLING_L + sling.top_h + 1.2 - hook_dy + 0.05
			hover = true
			hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt)
			if hull.position.y < tgt_alt + 0.3:
				_release_sling()
		elif drop_pt != Vector3.INF and L < 3.0:
			tgt_alt = 6.0
			hover = true
			if hull.position.y < 6.4:
				_drop_crate()
		_cargo_visuals(dt)
	var local_v := hvel.rotated(Vector3.UP, -heading)
	var bank := 0.55 if evade_t > 0.0 else 0.3
	hull.rotation = Vector3(lerpf(hull.rotation.x, clampf(local_v.z * 0.025, -0.3, 0.3), dt * 3.0), heading, lerpf(hull.rotation.z, clampf(-local_v.x * 0.035, -bank, bank), dt * 4.0))
	_hb += dt
	if landing or hover or absf(hull.position.y - tgt_alt) > 0.4:
		hull.position.y = move_toward(hull.position.y, tgt_alt, dt * (5.0 if evade_t > 0.0 else 3.0))
	else:
		hull.position.y = tgt_alt + sin(_hb * 1.3) * 0.25
	rotor.rotation.y += dt * 28.0
	if rotor_blades:
		rotor_blades.visible = false
	if M.get("meta", {}).get("trotor_y", false):
		trotor.rotation.y -= dt * 28.0
	else:
		trotor.rotation.x += dt * 40.0
	if randf() < dt * 3.0:
		G.fx.vehicle_dust(position + Vector3(randf_range(-4, 4), 0.2, randf_range(-4, 4)))
	rocket_cd -= dt
	hf_cd -= dt
	if vtype == "transport":
		if t != null and is_instance_valid(t) and t.alive and main_cd <= 0.0 and dist2(t) < 30.0 and not landing:
			if burst <= 0:
				burst = randi_range(5, 9)
			burst -= 1
			main_cd = 0.12 if burst > 0 else randf_range(1.0, 2.0)
			_hitscan_from(hull.global_transform * Vector3(1.0, 0.2, -0.8), t, 16.0, 0.3, 9.0)
			Sfx.play3d("mg", position, -2.0, 0.08, 0.03)
		return
	if t == null or not is_instance_valid(t) or not t.alive:
		return
	var ang := absf(angle_difference(heading, Soldier._yaw_of(t.position - position)))
	if ang > 0.35:
		return
	var dist := dist2(t)
	if salvo > 0:
		salvo_t -= dt
		if salvo_t <= 0.0:
			salvo -= 1
			salvo_t = 0.16
			var side := 1.6 if salvo % 2 == 0 else -1.6
			var mp := hull.global_transform * Vector3(side, -0.4, -1.0)
			G.bal.rocket(mp, t.aim_point(), team, self, t, "rpg", "hydra")
			Sfx.play3d("rpg", mp, 0.0, 0.1, 0.05)
	elif hf_left > 0 and hf_cd <= 0.0 and t is Vehicle and t.armor > 0 and not t.is_air() and dist < 75.0:
		# kanat altı raydan güdümlü tanksavar füzesi (ABD Hellfire / Rus Vikhr)
		hf_left -= 1
		hf_cd = 6.0
		var hs := 1.9 if hf_left % 2 == 0 else -1.9
		var hp := hull.global_transform * Vector3(hs, -0.55, -0.6)
		G.bal.rocket(hp, t.aim_point(), team, self, t, "atgm", "hellfire" if team == 0 else "vikhr")
		G.fx.flash(hp, 5.0, 8.0, 0.08, Color(1.0, 0.8, 0.5))
		Sfx.play3d("rpg", hp, 3.0)
		say("FÜZE ATILDI")
	elif rocket_cd <= 0.0 and dist < 50.0 and (t is Vehicle or t is Building or randf() < 0.5):
		salvo = 4
		salvo_t = 0.0
		rocket_cd = 9.0
	if main_cd <= 0.0 and dist < 46.0:
		if burst <= 0:
			burst = randi_range(6, 12)
		burst -= 1
		main_cd = 0.1 if burst > 0 else randf_range(0.8, 1.5)
		var gp := hull.global_transform * Vector3(0, -1.3, -4.6)
		_hitscan_from(gp, t, 28.0, 0.38, 12.0)
		Sfx.play3d("hmg", gp, 2.0, 0.08, 0.03)

# saldırı emrindeki helikopterin atış konumu. Hedef seçilemiyorsa (görüş hattı kapalı) konumda 2,5 sn
# bekledikten sonra hedef çevresinde 50° döner; her tam turda mesafe daralır (32 → 22 → 14 m: daha dik açı
# ağaç/bina üstünden görür), sonra başa döner.
func _attack_spot(dt: float) -> Vector3:
	var ft: Unit = forced_target
	if atk_for != ft:
		atk_for = ft
		var off := position - ft.position
		off.y = 0.0
		atk_dir = off.normalized() if off.length() > 0.5 else Vector3.FORWARD
		atk_r = 32.0
		atk_t = 0.0
		atk_n = 0
	var goal := ft.position + atk_dir * atk_r
	if target == ft:
		atk_t = 0.0
	elif Vector2(goal.x - position.x, goal.z - position.z).length() < 5.0:
		atk_t += dt
		if atk_t > 2.5:
			atk_t = 0.0
			atk_n += 1
			atk_dir = atk_dir.rotated(Vector3.UP, deg_to_rad(50.0))
			if atk_n % 7 == 0:
				atk_r = [32.0, 22.0, 14.0][(atk_n / 7) % 3]
			if atk_n == 1:
				say("AÇI ARIYORUM", 2.0)
			goal = ft.position + atk_dir * atk_r
	return goal

# ------------------------------------------------------------ halatla iniş / çekme
func can_rope() -> bool:
	return vtype == "transport" and alive

func cmd_fastrope(p: Vector3) -> void:
	if not can_rope() or cargo.is_empty():
		return
	_rope_reset()
	rope_pt = G.on_ground(p)
	rope_mode = "down"
	dest = rope_pt
	order = "move"
	landing = false
	say("HALATLA İNİŞE GİDİYORUZ")

func cmd_rope_pick(p: Vector3) -> void:
	if not can_rope() or cargo.size() >= capacity():
		return
	_rope_reset()
	rope_pt = G.on_ground(p)
	rope_mode = "up"
	dest = rope_pt
	order = "move"
	landing = false
	say("HALATLA ALIM NOKTASINA")

func rope_anchor(i: int) -> Vector3:
	# halat kapı üstündeki koldan sarkar (sağ/sol kapı), ağır nakliyede arka rampa ağzı
	var lp: Vector3
	if is_cargo():
		lp = Vector3((-0.7 if i % 2 == 0 else 0.7), 0.6, ext.y * 0.85)
	else:
		lp = Vector3((ext.x + 0.35) * (1.0 if i % 2 == 0 else -1.0), 2.0, -ext.y * 0.1)
	return hull.global_transform * lp

func _rope_mesh(len_m: float) -> MeshInstance3D:
	var mb := MB.new()
	var segs := int(len_m / 0.5) + 1
	var col := Color(0.12, 0.11, 0.1)
	for k in segs:
		var y0 := -float(k) * len_m / segs
		var y1 := -float(k + 1) * len_m / segs
		mb.cyl_between(Vector3(sin(k * 0.7) * 0.02, y0, 0), Vector3(sin((k + 1) * 0.7) * 0.02, y1, 0), 0.03, 0.03, 5, col, false)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	return mi

func _rope_deploy(n: int) -> void:
	_free_ropes()
	for i in n:
		var a := rope_anchor(i)
		var L := maxf(a.y + 0.3, 1.0)
		var mi := _rope_mesh(L)
		G.main.world.add_child(mi)
		mi.global_position = a
		mi.scale = Vector3(1, 0.05, 1)
		var tw := mi.create_tween()
		tw.tween_property(mi, "scale:y", 1.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		ropes.append([mi, i, L])
	Sfx.play3d("crumble", position, -12.0)

func _ropes_follow() -> void:
	for r in ropes:
		var mi: MeshInstance3D = r[0]
		if is_instance_valid(mi) and mi.get_meta("cut", false) == false:
			mi.global_position = rope_anchor(r[1])

# iniş bitti: halatlar koldan bırakılır, yere düşüp yığılır
func _rope_cut() -> void:
	for r in ropes:
		var mi: MeshInstance3D = r[0]
		if not is_instance_valid(mi):
			continue
		mi.set_meta("cut", true)
		var g := mi.global_position
		var tw := mi.create_tween()
		tw.tween_property(mi, "global_position:y", r[2] * 0.15, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(mi, "scale:y", 0.15, 0.6)
		tw.parallel().tween_property(mi, "rotation:z", 1.4, 0.6)
		tw.tween_property(mi, "global_position:y", 0.05, 0.25)
		tw.tween_interval(25.0)
		tw.tween_callback(mi.queue_free)
		mi.global_position = g
	ropes.clear()
	say("HALATLAR BIRAKILDI")

func _free_ropes() -> void:
	for r in ropes:
		if is_instance_valid(r[0]):
			(r[0] as Node).queue_free()
	ropes.clear()

func _rope_reset() -> void:
	_free_ropes()
	rope_pt = Vector3.INF
	rope_mode = ""
	rope_t = 0.0
	rope_riders.clear()

# askı noktasında asılı kal; askerleri sırayla halattan indir / topla
func _rope_tick(dt: float, L: float) -> bool:
	if rope_pt == Vector3.INF:
		return false
	if L > 2.0 or absf(hull.position.y - ROPE_ALT) > 0.6:
		return false
	hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt * 2.0)
	rope_t += dt
	if ropes.is_empty():
		if rope_t > 0.8:
			_rope_deploy(2 if rope_mode == "down" else 1)
			rope_next = 0.9
		return true
	_ropes_follow()
	rope_next -= dt
	if rope_mode == "down":
		rope_riders = rope_riders.filter(func(x): return is_instance_valid(x) and x.alive and x.state == "rope")
		if rope_next <= 0.0 and not cargo.is_empty():
			var sd = cargo[0]
			if is_instance_valid(sd):
				rope_next = 1.1
				cargo.erase(sd)
				sd.start_rope_down(self, rope_side % ropes.size())
				rope_side += 1
				rope_riders.append(sd)
			else:
				cargo.remove_at(0)
		if cargo.is_empty() and rope_riders.is_empty():
			if rope_next < -1.2:
				_rope_cut()
				rope_pt = Vector3.INF
				rope_mode = ""
				order = ""
	else:
		# SPIES: yakındaki dost askerler halata koşar, kancalanır, hep birlikte yukarı çekilir
		if rope_t < 1.6:
			for u in G.friends_near(rope_pt, 26.0, team):
				if u is Soldier and u.can_fight() and u.state in ["idle", "move"] and u.vehicle_in == null and rope_riders.size() + cargo.size() < capacity() and not rope_riders.has(u) and u.order != "hold":
					if u.selected or u.position.distance_to(rope_pt) < 14.0:
						rope_riders.append(u)
						u.start_rope_up(self)
		rope_riders = rope_riders.filter(func(x): return is_instance_valid(x) and x.alive and x.state in ["rope_wait", "rope_up", "move"] )
		var ready := rope_riders.filter(func(x): return x.state == "rope_wait")
		# hepsi kancalanınca çek; geciken varsa 12 sn sonra kancalı olanları çek (geç gelenler ardından çekilir)
		if not ready.is_empty() and rope_t > 2.0 and (ready.size() == rope_riders.size() or rope_t > 12.0):
			for x in ready:
				x.state = "rope_up"
				x.state_t = 0.0
		# süre sınırı: tırmanan varken halatı kesme (düşerlerdi); 60 sn kesin üst sınır
		var climbing := rope_riders.any(func(x): return x.state == "rope_up")
		if (rope_t > 40.0 and not climbing) or rope_t > 60.0 or (rope_riders.is_empty() and rope_t > 4.0):
			_rope_cut()
			rope_pt = Vector3.INF
			rope_mode = ""
			order = ""
	return true

# ------------------------------------------------------------ hava savunması / füze kaçınma
func _setup_air_defense(vt: String) -> void:
	var fam: String = cat.get("fam", "")
	if vt == "aa":
		if fam in ["sam_long", "sam_ru_long"]:
			sams = 8; sam_big = true; sam_range = 140.0
		elif fam in ["sam_mid", "sam_ru_tr", "sam_ru_truck"]:
			sams = 8; sam_big = true; sam_range = 110.0
		elif fam == "ciws":
			sams = 0
		else:
			sams = 6 if fam in ["lv_sam", "inf_manpads"] else 4
			sam_range = 85.0
	if vt in ["heli", "transport"]:
		flares = 12 if vt == "heli" else 16
		hf_left = 8 if vt == "heli" else 0

# gelen güdümlü füze: helikopter fişek atar ve kırar; İHA yalnız manevra yapar
func on_missile(p) -> void:
	if not alive:
		return
	evade_t = 2.6
	evade_side = 1.0 if randf() < 0.5 else -1.0
	if vtype in ["heli", "transport"]:
		if flares > 0:
			flare_q += 3
			say("FÜZE! FİŞEK!", 2.0)
			# kızılötesi arayıcı fişeğe kanar (büyük radar güdümlüde daha az)
			if randf() < (0.35 if p.big else 0.62):
				var tw := create_tween()
				tw.tween_interval(randf_range(0.35, 0.8))
				tw.tween_callback(func():
					if is_instance_valid(self):
						p.decoy = position + Vector3(0, hull.position.y - 2.0, 0) - hvel * 0.3 + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
		else:
			say("FÜZE! FİŞEK BİTTİ!", 2.0)
	elif is_drone() and vtype != "fpv":
		if randf() < 0.18:
			p.decoy = position + Vector3(randf_range(-10, 10), hull.position.y + randf_range(-6, 2), randf_range(-10, 10))

func _flares_tick(dt: float) -> void:
	if flare_q <= 0 or flares <= 0:
		return
	flare_t -= dt
	if flare_t > 0.0:
		return
	flare_t = 0.22
	flare_q -= 1
	flares -= 1
	var base := position + Vector3(0, hull.position.y - 0.4, 0)
	var r := right()
	var b := -forward()
	for sg in [-1.0, 1.0]:
		G.bal.flare(base + r * sg * 0.9, hvel * 0.6 + r * sg * randf_range(9.0, 13.0) + b * randf_range(3.0, 6.0) + Vector3(0, randf_range(1.0, 4.0), 0))
	Sfx.play3d("smoke_pop", base, -4.0, 0.2, 0.1)

# kaçış: sert yana kırış + alçalma; yatış açısı artar
func _evade_vec(dt: float) -> Vector3:
	if evade_t <= 0.0:
		return Vector3.ZERO
	evade_t -= dt
	return right() * evade_side * speed_max * 1.3

func _fire_sam(t: Unit) -> bool:
	if sams <= 0 or sam_cd > 0.0 or not (t is Vehicle) or not t.is_air() or not t.alive:
		return false
	var d := dist2(t)
	if d > sam_range or d < 12.0:
		return false
	sams -= 1
	sam_cd = 7.0 if sam_big else 5.0
	var mp := (turret.global_position if turret else position) + Vector3(0, 1.4, 0)
	G.bal.sam(mp, t, team, self, sam_big)
	say("FÜZE ATILDI")
	return true

# İHA: emir noktası çevresinde yüksekte daire çizer; silahlı olan araçlara üstten füze atar
func lose_link() -> void:
	if link_lost or not alive:
		return
	link_lost = true
	link_t = 0.0
	say("BAĞLANTI KOPTU", 3.0)
	forced_target = null

func _uav(dt: float) -> void:
	if link_lost:
		# bağ koptu: düz uçar, alçalır ve düşer
		link_t += dt
		position += hvel * dt
		hull.position.y = move_toward(hull.position.y, 0.0, dt * (0.6 + link_t * 0.25))
		hull.rotation = Vector3(-0.12 - link_t * 0.02, heading, -0.1)
		if hull.position.y <= 0.4 or position.x < 3.0 or position.z < 3.0 or position.x > G.MAP - 3.0 or position.z > G.MAP - 3.0:
			destroy(null)
		return
	var alt := HIGH_ALT if high_alt else UAV_ALT
	if G.weather != null and G.weather.no_air():
		hull.position.y = move_toward(hull.position.y, 6.0, dt * 3.0)
	else:
		hull.position.y = move_toward(hull.position.y, alt, dt * (2.2 if high_alt else 4.0))
	var R := 34.0 if high_alt else 26.0
	var c := dest
	var to_c := c - position
	to_c.y = 0.0
	var want: Vector3
	if to_c.length() > R + 6.0:
		want = to_c.normalized() * speed_max
	else:
		uav_ang += dt * speed_max / R
		var goal := c + Vector3(cos(uav_ang), 0, sin(uav_ang)) * R
		want = (goal - position)
		want.y = 0.0
		want = want.normalized() * speed_max
	var ev := _evade_vec(dt)
	if ev != Vector3.ZERO:
		want = (want * 0.3 + ev).limit_length(speed_max * 1.3)
		hull.position.y = move_toward(hull.position.y, alt - 5.0, dt * 6.0)
	hvel = hvel.move_toward(want, D["accel"] * dt * (2.5 if ev != Vector3.ZERO else 1.0))
	position += hvel * dt
	position.x = clampf(position.x, 2.0, G.MAP - 2.0)
	position.z = clampf(position.z, 2.0, G.MAP - 2.0)
	cur_speed = hvel.length()
	if hvel.length() > 0.5:
		heading = rotate_toward(heading, Soldier._yaw_of(hvel), D["turn"] * (5.0 if ev != Vector3.ZERO else 2.0) * dt)
	hull.rotation = Vector3(0.0, heading, -0.28 - (0.5 * evade_side if evade_t > 0.0 else 0.0))
	if vtype != "uav_armed":
		return
	missile_cd -= dt
	if missiles <= 0 or missile_cd > 0.0:
		return
	var best: Vehicle = null
	var bd := 1e9
	for e in G.enemies_near(position, 75.0, team):
		if e is Vehicle and e.alive and not e.is_air() and G.is_seen(e, team):
			var d: float = dist2(e) - e.max_hp * 0.02
			if forced_target == e:
				d -= 999.0
			if d < bd:
				bd = d
				best = e
	if best == null:
		return
	missiles -= 1
	missile_cd = 9.0
	var mp := position + Vector3(0, hull.position.y - 0.4, 0)
	G.bal.rocket(mp, best.aim_point(), team, self, best, "topatk")
	Sfx.play3d("rpg", mp, -2.0)
	say("FÜZE ATILDI")
	if missiles <= 0:
		say("MÜHİMMAT BİTTİ — ÜSSE DÖN", 3.0)

func _fpv(dt: float) -> void:
	if G.weather != null and G.weather.no_air():
		hull.position.y = move_toward(hull.position.y, 0.2, dt * 3.0)
		return
	var t: Unit = forced_target
	if t == null or not is_instance_valid(t) or not t.alive:
		# yeni hedef: yakındaki düşman
		t = null
		var lm := vtype == "loiter"
		var bd := 95.0 if lm else 60.0
		for e in G.enemies_near(position, bd, team):
			if e.alive and not (e is Building) and not (e is Vehicle and e.is_air()):
				var sc := dist2(e) - (40.0 if lm and e is Vehicle else 0.0)
				if sc < bd:
					bd = sc
					t = e
		forced_target = t
		if t == null:
			battery -= dt
			if loiter_pt != Vector3.INF and vtype == "fpv" and battery > 0.0:
				# hedef yoksa gösterilen noktada asılı kal, çevreyi tara
				var to_l := Vector3(loiter_pt.x - position.x, 0.0, loiter_pt.z - position.z)
				var wv := to_l.normalized() * minf(speed_max, to_l.length() * 1.5) if to_l.length() > 0.5 else Vector3.ZERO
				hvel = hvel.move_toward(wv, D["accel"] * dt)
				position += hvel * dt
				if hvel.length() > 0.5:
					heading = Soldier._yaw_of(hvel)
				hull.position.y = move_toward(hull.position.y, 7.0, dt * 3.0)
				hull.rotation = Vector3(-hvel.length() * 0.02, heading, sin(G.time * 7.0) * 0.04)
				return
			hp -= dt * 2.0
			if hp <= 0.0 or battery <= -10.0:
				destroy(null)
			return
	var tp := t.aim_point()
	var to := tp - (position + Vector3(0, hull.position.y, 0))
	var flat := Vector3(to.x, 0, to.z)
	var dist := flat.length()
	var want := flat.normalized() * speed_max
	if vtype == "loiter":
		# dalış: yakınken yavaşla, irtifayı hızla düşür
		want *= clampf(dist / 10.0, 0.35, 1.0)
	hvel = hvel.move_toward(want, D["accel"] * dt)
	position += hvel * dt
	heading = Soldier._yaw_of(hvel) if hvel.length() > 0.5 else heading
	hull.rotation = Vector3(-0.35, heading, sin(G.time * 9.0) * 0.08)
	# alçal ve dal
	var alt := clampf(dist * 0.25, tp.y, 9.0) if vtype == "fpv" else clampf(dist * 0.6, tp.y, 18.0)
	hull.position.y = move_toward(hull.position.y, alt, dt * (6.0 if vtype == "fpv" else 16.0))
	cur_speed = hvel.length()
	if dist < 14.0 and randf() < dt * 4.0:
		for s in G.enemies_near(position, 10.0, team):
			if s is Soldier:
				s.on_drone(position)
				break
	if (dist < 1.2 and absf(to.y) < 1.8) or (vtype == "loiter" and dist < 2.4 and to.y > -2.6):
		destroy(t)

func _hitscan_from(mp: Vector3, t: Unit, dmg: float, acc: float, sup: float) -> void:
	shots += 1
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	G.fx.muzzle(mp, dir, true)
	var c := acc
	if t is Soldier:
		c *= [1.0, 0.8, 0.6][t.stance]
	else:
		c = 0.8
	var impact := tp
	if randf() < c:
		t.take_damage(dmg, self, "hmg")
	else:
		impact = Vector3(tp.x + randf_range(-2, 2), 0.02, tp.z + randf_range(-2, 2))
		G.fx.impact(impact, "dirt")
		for o in G.near(impact, 3.0):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(sup, position)
	if shots % 2 == 0:
		G.fx.tracer(mp, impact, 260.0, Ammo.team_tracer(team), 0.09)

static func _rotor_disc_mat() -> ShaderMaterial:
	if _disc_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
global uniform float game_time;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float blades = 0.5 + 0.5 * sin(a * 5.0 - game_time * 60.0);
	float ring = smoothstep(1.0, 0.92, r) * smoothstep(0.05, 0.15, r);
	ALBEDO = vec3(0.12);
	ALPHA = ring * (0.16 + 0.12 * blades) + smoothstep(0.97, 0.93, r) * smoothstep(0.9, 0.95, r) * 0.25;
}
"""
		_disc_mat = ShaderMaterial.new()
		_disc_mat.shader = sh
	return _disc_mat

func _heli_crash() -> void:
	# kontrolsüz düşüş: kuyruk rotoru gider, gövde kendi ekseninde döner, pal yavaşlar;
	# bulanık disk kaybolur, gerçek pallar görünür; yere çarpınca pallar kırılıp savrulur
	if rotor_disc:
		rotor_disc.visible = false
	if rotor_blades:
		rotor_blades.visible = true
	var tw := create_tween()
	var dur := clampf(hull.position.y / 6.0, 1.2, 2.6)
	var spin := randf_range(5.0, 9.0) * dur
	var start_y := hull.position.y
	var h0 := heading
	var drift := hvel * 0.6
	var tilt := randf_range(0.35, 0.7) * (1.0 if randf() < 0.5 else -1.0)
	var last := [0.0]
	tw.tween_method(func(k: float):
		var dk: float = k - last[0]
		last[0] = k
		hull.position.y = lerpf(start_y, 0.5, k * k)
		hull.rotation.y = h0 + spin * (k * k * 0.6 + k * 0.4)
		hull.rotation.z = tilt * k
		hull.rotation.x = -0.25 * k
		position += drift * dk * dur
		if rotor:
			rotor.rotation.y += (1.0 - k * 0.7) * 1.1
		if trotor:
			trotor.rotation.x += (1.0 - k) * 0.6
		if randf() < 0.7:
			G.fx.emit(Fx.P_SMOKE, hull.global_position + Vector3(0, 0.6, 0), Vector3(randf_range(-0.4, 0.4), 1.5, randf_range(-0.4, 0.4)), randf_range(2.5, 4.0), 0.8, 3.2, -0.25, 0.6, Color(0.08, 0.08, 0.08, 0.85))
		if randf() < 0.35:
			G.fx.emit(Fx.P_FIRE, hull.global_position + Vector3(0, 0.9, 0), Vector3(0, 1.0, 0), 0.5, 0.6, 1.3, -0.5, 1.0, Color(1.0, 0.55, 0.2, 1.0)), 0.0, 1.0, dur)
	tw.tween_callback(func():
		G.explode(position + Vector3(0, 0.8, 0), 4.5, 90.0, "big", team, self, team)
		G.fx.burn(position + Vector3(0, 0.8, 0), 35.0, 1.2)
		G.cam.shake(0.4, position)
		# pallar kırılır: dönen göbek gizlenir, kırık pal parçaları savrulur
		if rotor:
			rotor.visible = false
			for i in 4:
				var a := randf() * TAU
				var piece := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(randf_range(1.5, 3.0), 0.04, 0.35)
				piece.mesh = bm
				piece.material_override = Mats.burnt()
				G.world.add_child(piece)
				piece.global_position = position + Vector3(0, 1.6, 0)
				piece.rotation.y = a
				var to := position + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 9.0)
				var pt := piece.create_tween()
				pt.set_parallel(true)
				pt.tween_property(piece, "global_position", Vector3(to.x, 0.05, to.z), 0.7).set_ease(Tween.EASE_OUT)
				pt.tween_property(piece, "rotation:y", a + randf_range(4.0, 9.0), 0.7)
		if trotor:
			trotor.visible = false
		hull.rotation.x = 0.0
		G.grid.set_static_rect(position, Vector2(3.0, 9.0), h0, 1.2, Grid.K_WRECK))

func destroy(src) -> void:
	if not alive:
		return
	if vtype in ["fpv", "loiter"]:
		alive = false
		var p := position + Vector3(0, hull.position.y, 0)
		var big := vtype == "loiter"
		G.explode(p, 3.4 if big else 2.6, 180.0 if big else 150.0, "rpg", team, operator if operator != null and is_instance_valid(operator) else self)
		for v in G.near(p, 3.5):
			if v is Vehicle and v != self and v.alive and v.team != team:
				v.take_damage(330.0 if big else 240.0, self, "topatk" if big else "rpg")
		queue_free()
		return
	if vtype in ["uav", "uav_armed"]:
		alive = false
		G.credit_kill(src, self)
		var p2 := position + Vector3(0, hull.position.y, 0)
		G.fx.explosion(p2, 1.0, "big")
		Sfx.play3d("expl_med", p2, 2.0)
		# enkaz düşer
		var tw := create_tween()
		tw.tween_property(hull, "position:y", 0.3, 2.2).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(hull, "rotation:z", 1.4, 2.2)
		tw.tween_callback(func():
			G.explode(position + Vector3(0, 0.3, 0), 2.5, 40.0, "grenade", -1, null, team)
			queue_free())
		return
	_cargo_lost()
	if vtype in ["heli", "transport"]:
		for r in rope_riders:
			if is_instance_valid(r) and r.alive and r.state in ["rope", "rope_up"]:
				r.rope_fall()
		rope_riders.clear()
		_free_ropes()
		alive = false
		wreck = true
		G.credit_kill(src, self)
		if selected and G.player:
			G.player.deselect(self)
		if engine:
			engine.stop()
		G.fx.explosion(aim_point(), 1.2, "big")
		Sfx.play3d("expl_med", aim_point(), 4.0)
		for mi in _meshes(self):
			if mi != rotor_disc and mi != rotor_blades:
				mi.material_override = Mats.burnt()
		_heli_crash()
		return
	alive = false
	wreck = true
	cur_speed = 0.0
	G.credit_kill(src, self)
	if selected and G.player:
		G.player.deselect(self)
	# imha biçimi: mühimmat infilakı / felaket / yanma / sadece etkisiz
	var heavy := vtype in ["tank", "ifv", "arty", "aa"]
	var r := randf()
	var mode := "brew"
	if heavy:
		mode = "cookoff" if r < 0.35 else ("catastrophic" if r < 0.5 else ("brew" if r < 0.8 else "knocked"))
	else:
		mode = "catastrophic" if r < 0.25 else ("brew" if r < 0.75 else "knocked")
	var cp := position + Vector3(0, 1.0, 0)
	if G.grid.is_water(position):
		G.fx.water_splash(position, 1.6)
		for mi in _meshes(self):
			mi.material_override = Mats.burnt()
		var tw2 := create_tween()
		tw2.tween_property(hull, "position:y", -2.6, 6.0).set_ease(Tween.EASE_IN)
		tw2.parallel().tween_property(hull, "rotation:z", randf_range(-0.5, 0.5), 6.0)
		tw2.tween_callback(func(): visible = false)
		for i in 6:
			var tw3 := create_tween()
			tw3.tween_interval(randf_range(0.3, 5.0))
			tw3.tween_callback(func(): G.fx.water_splash(position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)), 0.4))
		return
	match mode:
		"catastrophic":
			G.explode(cp, 6.5, 90.0, "big", team, self, team)
			G.fx.fireball(cp + Vector3(0, 0.6, 0), 2.0 if heavy else 1.4)
			G.fx.mushroom(cp, 1.6 if heavy else 1.0)
			G.fx.fire_column(position + Vector3(0, 1.2, 0), randf_range(40.0, 70.0), 1.3)
			G.fx.crater(position, D["len"] * 0.75)
			_debris(8 if heavy else 5, 9.0)
			G.fx.burn(position + Vector3(0, 1.0, 0), randf_range(40.0, 70.0), 1.5)
			hull.rotation.z += randf_range(-0.25, 0.25)
			hull.position.y -= 0.15
		"cookoff":
			G.explode(cp, 4.5, 70.0, "big", team, self, team)
			G.fx.fireball(cp + Vector3(0, 0.8, 0), 1.5)
			G.fx.fire_column(position + Vector3(0, 1.6, 0), randf_range(45.0, 80.0), 1.2)
			# taret ambarından yükselen cephane alevi jeti (birkaç saniye, aralıklı)
			G.fx.cookoff(position + Vector3(0, 2.0, 0), randf_range(6.0, 11.0), 1.0)
			G.fx.crater(position, D["len"] * 0.55)
			_debris(4, 6.0)
			G.fx.burn(position + Vector3(0, 1.6, 0), randf_range(45.0, 80.0), 1.6)
			# ikincil infilaklar + kapaktan alev püskürmesi
			for i in randi_range(3, 6):
				var tw0 := create_tween()
				tw0.tween_interval(randf_range(0.8, 6.0))
				tw0.tween_callback(func():
					var q := position + Vector3(randf_range(-1.0, 1.0), 1.8, randf_range(-1.0, 1.0))
					G.fx.explosion(q, 0.7, "rpg")
					G.fx.flash(q, 6.0, 8.0, 0.08)
					Sfx.play3d("expl_small", q, 0.0)
					for k in 6:
						G.fx.emit(Fx.P_FIRE, q, Vector3(randf_range(-1, 1), randf_range(6, 11), randf_range(-1, 1)), randf_range(0.4, 0.8), 0.6, 1.6, -2.0, 0.6, Color(1.8, 0.9, 0.3, 1)))
		"brew":
			G.explode(cp, 3.0, 40.0, "big", team, self, team)
			G.fx.fireball(cp, 0.9)
			G.fx.fire_column(position + Vector3(0, 1.3, 0), randf_range(30.0, 55.0), 1.0 if heavy else 0.8)
			_debris(2, 4.0)
		_:
			G.fx.explosion(cp, 0.8, "rpg")
			Sfx.play3d("expl_med", cp, 0.0)
			G.fx.burn(position + Vector3(0, 1.5, 0), randf_range(15.0, 25.0), 0.5)
	G.fx.scorch(position, D["len"] * 1.2)
	for mi in _meshes(self):
		mi.material_override = Mats.burnt()
	if gunner:
		gunner.visible = false
	if engine:
		engine.stop()
	if turret and ((mode == "cookoff" and vtype in ["tank", "ifv", "arty", "aa"]) or mode == "catastrophic"):
		# taret fırlar
		var tw := create_tween()
		var start := turret.position
		var side := Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		var hgt := 9.0 if mode == "cookoff" else 5.0
		tw.tween_property(turret, "position", start + Vector3(side.x * 0.5, hgt, side.z * 0.5), 0.5 if mode == "cookoff" else 0.4).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(turret, "rotation", Vector3(randf_range(-1, 1), randf_range(-3, 3), randf_range(-1, 1)), 0.9)
		tw.tween_property(turret, "position", start + Vector3(side.x, -0.6, side.z), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	G.grid.set_static_rect(position, Vector2(D["len"] * 0.45, D["len"] * 0.85), heading, 1.3, Grid.K_WRECK)
	if vtype == "truck" and G.logi:
		G.logi.truck_lost(self)
	# mürettebat kaçar
	if vtype in ["tank", "apc", "ifv"] and (mode == "knocked" or (mode == "brew" and randf() < 0.5)):
		for i in randi_range(1, 3):
			G.main.spawn_soldier(team, "rifle", position + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)), null, 50.0)

# parçalar etrafa saçılır ve sahnede kalır (çevrenin parçası)
func _debris(n: int, force: float) -> void:
	var src_meshes := _meshes(self)
	for i in n:
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(randf_range(0.3, 1.1), randf_range(0.08, 0.3), randf_range(0.3, 1.2))
		mi.mesh = bm
		mi.material_override = Mats.burnt()
		G.main.world.add_child(mi)
		var p0 := position + Vector3(randf_range(-1, 1), 1.4, randf_range(-1, 1))
		mi.position = p0
		var dir := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var land := G.on_ground(p0 + dir * randf_range(force * 0.4, force))
		land.y = G.terrain.ground_h(land) + bm.size.y * 0.5 if G.terrain else 0.1
		var top := p0.lerp(land, 0.5) + Vector3(0, randf_range(2.0, force * 0.6), 0)
		var tw := mi.create_tween()
		var dur := randf_range(0.7, 1.2)
		tw.tween_method(func(k: float):
			mi.position = p0.lerp(top, k).lerp(top.lerp(land, k), k)
			mi.rotation += Vector3(0.2, 0.15, 0.1), 0.0, 1.0, dur)
		tw.tween_callback(func():
			G.fx.emit(Fx.P_SMOKE, land, Vector3(0, 0.6, 0), 1.5, 0.4, 1.2, -0.1, 1.0, Color(0.2, 0.2, 0.2, 0.5)))
		if i == 0 and src_meshes.size() > 0:
			G.fx.burn(land + Vector3(0, 0.2, 0), randf_range(8.0, 16.0), 0.35)

func _meshes(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		if not (c is SoldierBody):
			out.append_array(_meshes(c))
	return out

func _wreck_tick(_dt: float) -> void:
	pass
