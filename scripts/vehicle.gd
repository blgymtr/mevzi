class_name Vehicle extends Unit
# Araçlar: tank, ZPT, makineli pikap, ikmal kamyonu.

const DEF := {
	"tank": {"title": "Tank", "hp": 900.0, "armor": 2, "speed": 6.2, "accel": 2.5, "turn": 0.75, "radius": 2.7, "len": 6.2, "nav": Grid.M_HEAVY, "sight": 50.0, "cap": 4, "tturn": 0.85, "icon": "tank"},
	"apc": {"title": "ZPT", "hp": 450.0, "armor": 1, "speed": 9.5, "accel": 3.5, "turn": 1.0, "radius": 2.5, "len": 7.2, "nav": Grid.M_HEAVY, "sight": 48.0, "cap": 3, "tturn": 1.8, "icon": "apc"},
	"technical": {"title": "Teknik Araç", "hp": 170.0, "armor": 0, "speed": 13.0, "accel": 5.0, "turn": 1.4, "radius": 1.9, "len": 5.0, "nav": Grid.M_LIGHT, "sight": 46.0, "cap": 2, "tturn": 3.0, "icon": "tech"},
	"heli": {"title": "Saldırı Helikopteri", "hp": 650.0, "armor": 1, "speed": 17.0, "accel": 6.0, "turn": 1.4, "radius": 3.6, "len": 11.0, "nav": Grid.M_LIGHT, "sight": 62.0, "cap": 5, "tturn": 0.0, "icon": "heli"},
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
var rotor_blades: MeshInstance3D
static var _disc_mat: ShaderMaterial

func setup(t: int, vt: String) -> void:
	team = t
	vtype = vt
	kind = vt
	D = DEF[vt]
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
	M = Art.vehicle(vt, t)
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
	if vt == "heli":
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
	engine = Sfx.loop3d("heli" if vt == "heli" else ("engine_tank" if vt in ["tank", "apc"] else "engine_truck"), self, -8.0 if vt == "heli" else -10.0)

func forward() -> Vector3:
	return Vector3(-sin(heading), 0, -cos(heading))

func aim_point() -> Vector3:
	if vtype == "heli":
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
	dest = G.on_ground(p)
	if vtype == "heli":
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
	path = PackedVector3Array()
	dest = position

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
	return 0.0

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	tick_bubble(dt)
	if not alive:
		_wreck_tick(dt)
		return
	main_cd -= dt
	coax_cd -= dt
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.45 + randf() * 0.15
		_scan()
	if vtype == "heli":
		_heli(dt)
		return
	_drive(dt)
	_aim_fire(dt)
	_visuals(dt)

func _drive(dt: float) -> void:
	if tracks_broken > 0.0:
		tracks_broken -= dt
		cur_speed = move_toward(cur_speed, 0.0, 6.0 * dt)
		if tracks_broken <= 0.0:
			say("PALET ONARILDI")
	var target_speed := 0.0
	if tracks_broken <= 0.0:
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
			var want := Soldier._yaw_of(d)
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
			break
	cur_speed = move_toward(cur_speed, target_speed, D["accel"] * dt * (2.0 if target_speed < cur_speed else 1.0))
	if absf(cur_speed) < 0.01:
		return
	var f := forward()
	var np := position + f * cur_speed * dt
	# engel denetimi (ön nokta)
	var front: Vector3 = np + f * (D["len"] * 0.45)
	var hf := G.grid.height_at(front)
	var kf := G.grid.kind_at(front)
	var blocked := (hf >= 0.3 and kf != Grid.K_TREE and not (nav_mode == Grid.M_HEAVY and kf == Grid.K_WALL)) or kf == Grid.K_TRAP
	if blocked:
		if true:
			cur_speed = 0.0
			_stuck_t += dt
			if _stuck_t > 1.0:
				_stuck_t = 0.0
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
	if order == "move":
		order = ""
	if vtype == "truck" and G.logi:
		G.logi.truck_arrived(self)

func _scan() -> void:
	if vtype == "truck":
		return
	var rng_w := _range()
	var eye := turret_world_pos() + Vector3(0, 0.4, 0)
	if forced_target != null and (not is_instance_valid(forced_target) or not forced_target.alive):
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
		if G.grid.los(eye, e.aim_point(), D["len"] * 0.5, 0.5):
			best = e
			break
	target = best
	coax_target = null
	if vtype == "tank" and best_inf != null and G.grid.los(eye, best_inf.aim_point(), 3.0, 0.5):
		coax_target = best_inf

func _aim_fire(dt: float) -> void:
	if turret == null:
		return
	var t := target
	var want_local := 0.0
	if t != null and is_instance_valid(t) and t.alive:
		var d := t.position - position
		want_local = wrapf(Soldier._yaw_of(d) - heading, -PI, PI)
	turret_yaw = rotate_toward(turret_yaw, want_local, D["tturn"] * dt)
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
	_coax(dt)

func _fire_cannon(t: Unit) -> void:
	main_cd = 6.5
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := d * 0.025 * (1.0 if t is Vehicle else 1.5)
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
	var spread := d * 0.04
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
	if not alive:
		return
	var m := 1.0
	if vtype == "heli":
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
	match k:
		"bullet", "crush":
			m = [0.6, 0.04, 0.0][armor]
			if armor == 2 and randf() < 0.05:
				Sfx.play3d("ricochet", position, -6.0)
		"hmg":
			m = [1.0, 0.3, 0.0][armor]
		"grenade":
			m = [1.0, 0.5, 0.12][armor]
		"auto":
			m = [1.0, 0.7, 0.15][armor]
	var dmg := amount * m
	if dmg <= 0.0:
		return
	hp -= dmg
	last_hit = G.time
	if src != null and is_instance_valid(src):
		attacker = src
	if (k == "rpg" or k == "ap") and randf() < 0.14 and vtype in ["tank", "apc"] and tracks_broken <= 0.0:
		tracks_broken = 30.0
		say("PALET KOPTU!", 3.0)
	if hp <= 0.0:
		destroy(src)

func _heli(dt: float) -> void:
	var goal := dest
	var t := target
	if forced_target != null and is_instance_valid(forced_target) and forced_target.alive:
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
		if o != self and o is Vehicle and o.vtype == "heli" and o.alive:
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
	var local_v := hvel.rotated(Vector3.UP, -heading)
	hull.rotation = Vector3(lerpf(hull.rotation.x, clampf(local_v.z * 0.025, -0.3, 0.3), dt * 3.0), heading, lerpf(hull.rotation.z, clampf(-local_v.x * 0.025, -0.3, 0.3), dt * 3.0))
	_hb += dt
	hull.position.y = ALT + sin(_hb * 1.3) * 0.25
	rotor.rotation.y += dt * 28.0
	if rotor_blades:
		rotor_blades.visible = false
	trotor.rotation.x += dt * 40.0
	if randf() < dt * 3.0:
		G.fx.vehicle_dust(position + Vector3(randf_range(-4, 4), 0.2, randf_range(-4, 4)))
	rocket_cd -= dt
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
	var tw := create_tween()
	var spin := randf_range(6.0, 10.0)
	var start_y := hull.position.y
	var h0 := heading
	tw.tween_method(func(k: float):
		hull.position.y = lerpf(start_y, 0.6, k * k)
		hull.rotation.y = h0 + k * spin
		hull.rotation.z = k * 0.6
		position += hvel * 0.016 * (1.0 - k)
		if randf() < 0.5:
			G.fx.emit(Fx.P_SMOKE, hull.global_position, Vector3(0, 1, 0), 3.0, 1.0, 3.0, -0.2, 0.5, Color(0.1, 0.1, 0.1, 0.8)), 0.0, 1.0, 1.8)
	tw.tween_callback(func():
		G.explode(position + Vector3(0, 0.8, 0), 4.5, 90.0, "big", team, self)
		G.fx.burn(position + Vector3(0, 0.8, 0), 30.0, 1.0)
		if rotor:
			rotor.visible = false
		G.grid.set_static_rect(position, Vector2(3.0, 9.0), h0, 1.2, Grid.K_WRECK))

func destroy(src) -> void:
	if not alive:
		return
	if vtype == "heli":
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
