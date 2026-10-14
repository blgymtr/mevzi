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
var vid := ""            # katalog kimliği (boşsa taban araç)
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
	"mortar": [1, 4, 4, true], "mine": [0, 12, 12, true], "fpv": [1, 10, 10, true],
}
const SIDE_NAME := ["ÖN", "YAN", "ARKA", "ÜST"]
static var shot_from := Vector3.INF
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

func is_air() -> bool:
	return vtype in ["heli", "transport", "fpv"]

func capacity() -> int:
	return CAPACITY.get(vtype, 0)

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
			s.dismount(position + back * (D["len"] * 0.5 + 1.0) + side * ((k % 3) - 1) * 1.3 - back * (k / 3) * 1.2)
		else:
			cargo.remove_at(0)
	landing = false
	say("İNDİR!")

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
	M = Art.vehicle_model(vid, t) if vid != "" and Art.has(vid) else Art.vehicle(vt, t)
	if M.is_empty():
		M = VehicleModels.get_model(vt, t, G.map_kind == "winter")
	hull = Node3D.new()
	add_child(hull)
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
	set_layer(self, 2)
	heading = rotation.y
	rotation.y = 0.0
	hull.rotation.y = heading
	dest = position
	_last_pos = position
	think_t = randf() * 0.5
	if vt != "fpv" and not (vt in TOWED):
		engine = Sfx.loop3d("heli" if vt in ["heli", "transport"] else ("engine_tank" if vt in ["tank", "apc", "ifv", "aa", "arty"] else "engine_truck"), self, -8.0 if vt in ["heli", "transport"] else -10.0)

func forward() -> Vector3:
	return Vector3(-sin(heading), 0, -cos(heading))

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
	if is_air():
		path = PackedVector3Array([dest])
	else:
		path = G.grid.find_path(position, dest, nav_mode)
	path_i = 0

func cmd_attack(u: Unit) -> void:
	if not alive or vtype == "truck":
		return
	forced_target = u
	order = "attack"
	var rng_w := _range()
	if dist2(u) > rng_w * 0.85:
		dest = u.position + (position - u.position).normalized() * rng_w * 0.7
		path = G.grid.find_path(position, dest, nav_mode)
		path_i = 0

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
			path = G.grid.find_path(position, dest, nav_mode)
			path_i = 0
		_scan()
		_refund_check()
	atgm_cd -= dt
	if vtype == "fpv":
		_fpv(dt)
		return
	if vtype in ["heli", "transport"]:
		_heli(dt)
		return
	_drive(dt)
	_aim_fire(dt)
	_visuals(dt)

func immobile() -> bool:
	return crit["mob"] >= 2 or tracks_broken > 0.0 or not driver_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0 or (vtype in WHEELED and tires >= maxi(wheels.size(), 4))

func speed_factor() -> float:
	var mud: float = G.weather.mud() if G.weather != null and vtype in WHEELED else 1.0
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

func _drive(dt: float) -> void:
	_repair_tick(dt)
	if immobile():
		cur_speed = move_toward(cur_speed, 0.0, 6.0 * dt)
	var target_speed := 0.0
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
				target_speed = speed_max * clampf(1.0 - diff / 0.9, 0.0, 1.0)
			else:
				target_speed = speed_max * clampf(1.0 - diff / 1.6, 0.25, 1.0)
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
	cur_speed = move_toward(cur_speed, target_speed, D["accel"] * dt * (2.0 if target_speed < cur_speed else 1.0))
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
				path = G.grid.find_path(position, path[path.size() - 1], nav_mode)
				path_i = 0
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
	if retreating or fire_mode == 2 or (fire_mode == 1 and G.time - last_hit > 10.0) or not gunner_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0:
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
			if d < (18.0 if vtype == "hmortar" else 30.0) or air:
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
		if (vtype in INDIRECT) or (e is Vehicle and e.is_air()) or G.grid.los(eye, e.aim_point(), D["len"] * 0.5, 0.5):
			best = e
			break
	target = best
	coax_target = null
	if vtype == "tank" and best_inf != null and G.grid.los(eye, best_inf.aim_point(), 3.0, 0.5):
		coax_target = best_inf

func _aim_fire(dt: float) -> void:
	if turret == null or G.deploy_t > 0.0:
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
				_fire_flak(t)
			"arty":
				_fire_arty(t)
			"fieldgun":
				_fire_cannon(t)
				main_cd = 5.0
			"atgun":
				_fire_atgun(t)
			"howitzer":
				_fire_arty(t)
				main_cd = 11.0
			"mtngun":
				_fire_arty(t)
				main_cd = 7.0
			"hmortar":
				_fire_hmortar(t.position)
			"mlrs":
				if mlrs_left <= 0:
					mlrs_left = 12
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
	mlrs_t = 0.22
	mlrs_left -= 1
	var mp := muzzle_world() + Vector3(randf_range(-0.6, 0.6), randf_range(-0.2, 0.2), 0)
	var d := dist2_p(mlrs_aim)
	var err := d * 0.07 + 4.0
	G.bal.artillery(mp, mlrs_aim + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self)
	Sfx.play3d("rpg", mp, 3.0, 0.15, 0.05)
	var back := -(mlrs_aim - position).normalized()
	for i in 3:
		G.fx.emit(Fx.P_SMOKE, mp, back * randf_range(3, 7) + Vector3(randf_range(-1, 1), randf_range(0.5, 2), randf_range(-1, 1)), randf_range(1.5, 2.8), 0.6, 2.6, -0.1, 1.5, Color(0.82, 0.8, 0.76, 0.55))
	G.fx.muzzle(mp, -back, true)
	if mlrs_left <= 0:
		main_cd = 32.0

func _fire_atgun(t: Unit) -> void:
	main_cd = 4.2
	var mp := muzzle_world()
	var tp := t.aim_point()
	var spread := mp.distance_to(tp) * 0.015
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.2), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "ap" if t is Vehicle or t is Building else "he")
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 3.0)
	recoil = 1.0

func _fire_hmortar(tp: Vector3) -> void:
	main_cd = randf_range(4.5, 5.5)
	var d := dist2_p(tp)
	var err := d * 0.05 + 2.0
	var mp := muzzle_world()
	G.bal.mortar(mp, tp + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self)
	Sfx.play3d("mortar", mp, 3.0)
	G.fx.muzzle(mp, Vector3.UP, true)
	recoil = 0.6

func _crew_anim(dt: float) -> void:
	for cb in crew:
		cb.animate(dt, "crouch_aim" if target != null else "crouch", 0.0)

func dist2_p(p: Vector3) -> float:
	return Vector2(position.x - p.x, position.z - p.z).length()

func _fire_ground() -> void:
	# baskı / bombardıman: yere ateş
	var mp := muzzle_world()
	var p := ground_pt + Vector3(randf_range(-3.5, 3.5), 0.1, randf_range(-3.5, 3.5))
	match vtype:
		"tank":
			main_cd = 6.5
			G.bal.shell(mp, p, team, self, null, "he")
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
			rock_v += 2.5
		"apc", "ifv":
			if burst <= 0:
				burst = randi_range(3, 5)
			burst -= 1
			main_cd = 0.26 if burst > 0 else randf_range(1.0, 1.8)
			G.bal.shell(mp, p, team, self, null, "auto")
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
				G.fx.tracer(mp, p, 260.0, Color(1.0, 0.55, 0.22), 0.09)
		"arty":
			main_cd = 9.0
			G.bal.artillery(mp, p, team, self)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 6.0)
			recoil = 1.0
			rock_v += 3.0
		"fieldgun", "atgun":
			main_cd = 5.0
			G.bal.shell(mp, p, team, self, null, "he")
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 3.0)
			recoil = 1.0
		"howitzer", "mtngun":
			main_cd = 10.0 if vtype == "howitzer" else 7.0
			G.bal.artillery(mp, p, team, self)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
		"hmortar":
			_fire_hmortar(p)
		"mlrs":
			if mlrs_left <= 0:
				mlrs_left = 12
				mlrs_aim = ground_pt
			main_cd = 0.5
		_:
			main_cd = 1.0

func _fire_flak(t: Unit) -> void:
	if burst <= 0:
		burst = randi_range(6, 12)
	burst -= 1
	main_cd = 0.07 if burst > 0 else randf_range(0.6, 1.1)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var air: bool = t is Vehicle and t.is_air()
	G.fx.muzzle(mp, (tp - mp).normalized(), true)
	Sfx.play3d("autocannon", mp, -3.0, 0.1, 0.03)
	recoil = 0.25
	var c := 0.32 if air else 0.25
	if t is Vehicle and t.vtype == "fpv":
		c = 0.45
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
	G.fx.tracer(mp, impact, 300.0, Color(1.0, 0.7, 0.3), 0.1)

func _fire_arty(t: Unit) -> void:
	main_cd = 9.0
	var mp := muzzle_world()
	var d := dist2(t)
	var err := d * 0.05 + 2.0
	var tp := t.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	G.bal.artillery(mp, tp, team, self)
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 6.0)
	recoil = 1.0
	rock_v += 3.0
	G.cam.shake(0.2, position)

func _fire_cannon(t: Unit) -> void:
	main_cd = 6.5
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := d * 0.025 * (1.0 if t is Vehicle else 1.5) * aim_mult()
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.3, 0.3), randf_range(-spread, spread))
	var ap = t is Vehicle and t.armor > 0
	G.bal.shell(mp, tp, team, self, t, "ap" if ap else "he")
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 5.0)
	recoil = 1.0
	rock_v += 2.5
	G.cam.shake(0.25, position)

func _fire_auto(t: Unit) -> void:
	if burst <= 0:
		burst = randi_range(3, 5)
	burst -= 1
	main_cd = 0.26 if burst > 0 else randf_range(1.2, 2.2)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := d * 0.04 * aim_mult()
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.4), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "auto")
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
		G.fx.tracer(mp, impact, 260.0, Color(1.0, 0.55, 0.22), 0.09)

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
	if not alive:
		return
	var m := 1.0
	if vtype == "fpv":
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
				G.fx.impact(aim_point(), "metal")
				G.fx.flash(aim_point(), 3.0, 4.0, 0.08, Color(1.0, 0.85, 0.5))
				if G.time - _nopen_t > 2.0:
					_nopen_t = G.time
					say("SEKTİ!" if last_side == 0 else "DELEMEDİ!")
		return
	var dmg := amount * m
	if dmg <= 0.0:
		return
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

func pen_at(k: String, dist: float) -> float:
	var pd: Array = PEN.get(k, PEN["bullet"])
	return lerpf(float(pd[1]), float(pd[2]), clampf(dist / 60.0, 0.0, 1.0))

# delme - zırh farkına göre hasar çarpanı (0 = delemedi)
func pen_mult(k: String, from: Vector3) -> float:
	var pd: Array = PEN.get(k, PEN["bullet"])
	var side := armor_side(from, k)
	var a := armor_value(pd[0], side)
	var dist := 0.0 if from == Vector3.INF else from.distance_to(position)
	var p := pen_at(k, dist)
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
	if vtype in TRACKED and tracks_broken <= 0.0:
		var pc := {"mine": 1.0, "rpg": 0.2, "atgm": 0.2, "topatk": 0.1, "ap": 0.14, "he": 0.18, "shell": 0.22, "big": 0.3}.get(k, 0.0)
		if randf() < pc:
			tracks_broken = 45.0
			say("PALET KOPTU!", 3.0)
	# teker: kurşun / patlama
	if vtype in WHEELED:
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
	if forced_target != null and is_instance_valid(forced_target) and forced_target.hostile():
		var off := position - forced_target.position
		off.y = 0
		goal = forced_target.position + off.normalized() * 32.0
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
	hvel = hvel.move_toward(want, D["accel"] * dt)
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
	var tgt_alt := ALT
	if landing:
		tgt_alt = 0.6
		if L < 1.5 and hull.position.y < 0.9:
			unload()
	var local_v := hvel.rotated(Vector3.UP, -heading)
	hull.rotation = Vector3(lerpf(hull.rotation.x, clampf(local_v.z * 0.025, -0.3, 0.3), dt * 3.0), heading, lerpf(hull.rotation.z, clampf(-local_v.x * 0.025, -0.3, 0.3), dt * 3.0))
	_hb += dt
	if landing or hull.position.y < ALT - 0.4:
		hull.position.y = move_toward(hull.position.y, tgt_alt, dt * 3.0)
	else:
		hull.position.y = ALT + sin(_hb * 1.3) * 0.25
	rotor.rotation.y += dt * 28.0
	if rotor_blades:
		rotor_blades.visible = false
	trotor.rotation.x += dt * 40.0
	if randf() < dt * 3.0:
		G.fx.vehicle_dust(position + Vector3(randf_range(-4, 4), 0.2, randf_range(-4, 4)))
	rocket_cd -= dt
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
			G.bal.rocket(mp, t.aim_point(), team, self, t)
			Sfx.play3d("rpg", mp, 0.0, 0.1, 0.05)
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

func _fpv(dt: float) -> void:
	if G.weather != null and G.weather.no_air():
		hull.position.y = move_toward(hull.position.y, 0.2, dt * 3.0)
		return
	var t: Unit = forced_target
	if t == null or not is_instance_valid(t) or not t.alive:
		# yeni hedef: yakındaki düşman
		t = null
		var bd := 60.0
		for e in G.enemies_near(position, 60.0, team):
			if e.alive and not (e is Building) and not (e is Vehicle and e.is_air()) and dist2(e) < bd:
				bd = dist2(e)
				t = e
		forced_target = t
		if t == null:
			hp -= dt * 2.0
			if hp <= 0.0:
				destroy(null)
			return
	var tp := t.aim_point()
	var to := tp - (position + Vector3(0, hull.position.y, 0))
	var flat := Vector3(to.x, 0, to.z)
	var dist := flat.length()
	var want := flat.normalized() * speed_max
	hvel = hvel.move_toward(want, D["accel"] * dt)
	position += hvel * dt
	heading = Soldier._yaw_of(hvel) if hvel.length() > 0.5 else heading
	hull.rotation = Vector3(-0.35, heading, sin(G.time * 9.0) * 0.08)
	# alçal ve dal
	var alt := clampf(dist * 0.25, tp.y, 9.0)
	hull.position.y = move_toward(hull.position.y, alt, dt * 6.0)
	cur_speed = hvel.length()
	if dist < 14.0 and randf() < dt * 4.0:
		for s in G.enemies_near(position, 10.0, team):
			if s is Soldier:
				s.on_drone(position)
				break
	if dist < 1.2 and absf(to.y) < 1.8:
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
		G.fx.tracer(mp, impact, 260.0, Color(1.0, 0.55, 0.22), 0.09)

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
		G.explode(position + Vector3(0, 0.8, 0), 4.5, 90.0, "big", team, self)
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
	if vtype == "fpv":
		alive = false
		var p := position + Vector3(0, hull.position.y, 0)
		G.explode(p, 2.6, 150.0, "rpg", team, operator if operator != null and is_instance_valid(operator) else self)
		for v in G.near(p, 3.0):
			if v is Vehicle and v != self and v.alive and v.team != team:
				v.take_damage(240.0, self, "rpg")
		queue_free()
		return
	_cargo_lost()
	if vtype in ["heli", "transport"]:
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
	G.explode(position + Vector3(0, 1.0, 0), 4.0, 60.0, "big", team, self)
	G.fx.burn(position + Vector3(0, 1.3, 0), randf_range(25.0, 45.0), 1.2 if vtype == "tank" else 0.9)
	G.fx.scorch(position, D["len"] * 1.1)
	for mi in _meshes(self):
		mi.material_override = Mats.burnt()
	if gunner:
		gunner.visible = false
	if engine:
		engine.stop()
	if vtype == "tank" and turret and randf() < 0.45:
		# taret fırlar
		var tw := create_tween()
		var start := turret.position
		var side := Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		tw.tween_property(turret, "position", start + Vector3(side.x * 0.5, 5.0, side.z * 0.5), 0.45).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(turret, "rotation", Vector3(randf_range(-1, 1), randf_range(-3, 3), randf_range(-1, 1)), 0.9)
		tw.tween_property(turret, "position", start + Vector3(side.x, -0.6, side.z), 0.45).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	G.grid.set_static_rect(position, Vector2(D["len"] * 0.45, D["len"] * 0.85), heading, 1.3, Grid.K_WRECK)
	if vtype == "truck" and G.logi:
		G.logi.truck_lost(self)
	# mürettebat kaçar
	if vtype in ["tank", "apc"] and randf() < 0.5:
		for i in randi_range(1, 2):
			G.main.spawn_soldier(team, "rifle", position + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)), null, 50.0)

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
