class_name AICmd extends Node
# Yapay zekâ komutanı: oyuncuyla aynı kurallarla üs kurar, üretir, savunur ve saldırır.

var team := 1
var tick := 0.0
var wave_t := 150.0
var target_pos := Vector3.INF
var target_b: Building = null
var attackers: Array = []
var reissue := 0.0
var think_n := 0

func _init(t: int) -> void:
	team = t

func _process(dt: float) -> void:
	if not G.running or G.game_over or dt <= 0.0:
		return
	tick -= dt
	reissue -= dt
	wave_t -= dt
	if tick > 0.0:
		return
	tick = 1.0
	think_n += 1
	var mult = [0.6, 1.0, 1.35][G.difficulty] if team != G.player_team else 1.0
	# zorluk: ikmal desteği
	G.supply[team] += (mult - 1.0) * 1.2
	_economy()
	_builders()
	_production()
	_defend()
	_attack()

func _mine() -> Array:
	var out: Array = []
	for u in G.units:
		if is_instance_valid(u) and u.alive and u.team == team:
			out.append(u)
	return out

func _buildings(bt: String, include_site := true) -> Array:
	var out: Array = []
	for u in G.units:
		if is_instance_valid(u) and u.alive and u.team == team and u is Building and u.btype == bt and (include_site or u.done):
			out.append(u)
	return out

func _hq() -> Building:
	var h := _buildings("hq")
	return h[0] if not h.is_empty() else null

func _place_near(bt: String, around: Vector3, r0: float, r1: float) -> Building:
	var B: Dictionary = Building.BDEF[bt]
	if G.supply[team] < B["cost"]:
		return null
	for i in 30:
		var a := randf() * TAU
		var r := randf_range(r0, r1)
		var p := around + Vector3(cos(a) * r, 0, sin(a) * r)
		p = Vector3(snappedf(p.x, 0.5), 0, snappedf(p.z, 0.5))
		var rot = [0.0, PI * 0.5, PI, PI * 1.5][randi() % 4]
		if PlayerCtl.can_place(bt, p, rot, team) == "":
			G.supply[team] -= B["cost"]
			return G.main.place_building(team, bt, p, rot)
	return null

func _economy() -> void:
	var hq := _hq()
	if hq == null:
		return
	var fobs := _buildings("fob")
	var t := G.time
	if _buildings("barracks").is_empty() and t > 8.0:
		_place_near("barracks", hq.position, 14.0, 26.0)
	elif _buildings("factory").is_empty() and t > 50.0:
		_place_near("factory", hq.position, 16.0, 30.0)
	var want_fobs := mini(5, 1 + int(t / 140.0))
	if fobs.size() < want_fobs and G.supply[team] >= 300:
		var sites: Array = G.fob_sites.duplicate()
		sites.sort_custom(func(a, b): return a.distance_to(hq.position) < b.distance_to(hq.position))
		for s in sites:
			if PlayerCtl.can_place("fob", s, 0.0, team) == "":
				G.supply[team] -= 300
				G.main.place_building(team, "fob", s, 0.0)
				break
	if t > 420.0 and _buildings("helipad").is_empty() and G.supply[team] > 600:
		_place_near("helipad", hq.position, 16.0, 32.0)
	if t > 220.0 and _buildings("hospital").is_empty():
		_place_near("hospital", hq.position, 12.0, 26.0)
	if t > 300.0 and _buildings("barracks").size() < 2 and G.supply[team] > 500:
		var fd := _buildings("fob", false)
		if not fd.is_empty():
			_place_near("barracks", fd[randi() % fd.size()].position, 12.0, 30.0)
	# savunma: ileri üslere MG yuvası
	if think_n % 20 == 0 and G.supply[team] > 350:
		for f in _buildings("fob", false):
			var has := false
			for m in _buildings("mgnest"):
				if m.position.distance_to(f.position) < 25.0:
					has = true
			if not has:
				var enemy_hq: Vector3 = G.hq_pos[1 - team]
				var dir: Vector3 = (enemy_hq - f.position).normalized()
				_place_near("mgnest", f.position + dir * 14.0, 0.0, 6.0)
				break

func _builders() -> void:
	for b in _mine():
		if not (b is Building) or b.done:
			continue
		var working := 0
		for s in G.near(b.position, b.radius + 4.0):
			if s is Soldier and s.team == team and s.state == "build" and s.build_site == b:
				working += 1
		if working >= 3:
			continue
		var cands: Array = []
		for s in _mine():
			if s is Soldier and s.can_fight() and s.state == "idle" and not attackers.has(s) and s.dist2(b) < 110.0:
				cands.append(s)
		cands.sort_custom(func(x, y): return x.dist2(b) < y.dist2(b))
		for i in mini(3 - working, cands.size()):
			cands[i].cmd_build(b)

func _production() -> void:
	var t := G.time
	for b in _mine():
		if not (b is Building) or not b.done or b.B["prod"].is_empty() or not b.queue.is_empty():
			continue
		var opts: Array = b.B["prod"]
		var pick := ""
		match b.btype:
			"factory":
				var r := randf()
				pick = "tank" if (r < 0.3 and t > 200.0) else ("ifv" if r < 0.45 else ("apc" if r < 0.6 else ("aa" if r < 0.7 else ("arty" if r < 0.78 and t > 300.0 else "technical"))))
			"barracks":
				var r2 := randf()
				pick = "at_squad" if r2 < 0.22 else ("mg_team" if r2 < 0.34 else ("medic_team" if r2 < 0.42 else ("sniper_team" if r2 < 0.5 else ("mortar_team" if r2 < 0.58 else ("drone_team" if r2 < 0.66 else ("engineer_squad" if r2 < 0.72 else "rifle_squad"))))))
			_:
				pick = "rifle_squad" if randf() < 0.8 else "medic_team"
		if not opts.has(pick):
			pick = opts[0]
		var P: Dictionary = Building.PDEF[pick]
		if G.cap_used[team] + P["cap"] <= G.cap_max[team] and G.supply[team] >= P["cost"] + (150 if b.btype == "hq" and t > 120 else 0):
			b.enqueue(pick)

func _combat_units() -> Array:
	var out: Array = []
	for u in _mine():
		if u is Soldier and u.can_fight() and u.state != "build" and u.role != "medic":
			out.append(u)
		elif u is Vehicle and u.vtype != "truck":
			out.append(u)
	return out

func _defend() -> void:
	for b in _mine():
		if not (b is Building) or G.time - b.last_hit > 6.0:
			continue
		var src: Unit = b.attacker
		var p: Vector3 = src.position if src != null and is_instance_valid(src) else b.position
		var units: Array = []
		for u in _combat_units():
			if not attackers.has(u) and u.position.distance_to(b.position) < 70.0 and (u is Vehicle or u.order == ""):
				units.append(u)
		if not units.is_empty():
			G.player.move_group(units, p)
		return

func _attack() -> void:
	attackers = attackers.filter(func(u): return is_instance_valid(u) and u.alive)
	var units := _combat_units()
	var power := 0
	for u in units:
		power += 4 if u is Vehicle else 1
	var need = [16, 22, 26][G.difficulty] if team != G.player_team else 20
	need += int(G.time / 120.0)
	if attackers.size() < 3 and (power >= need or (wave_t <= 0.0 and power >= 10)):
		wave_t = 160.0
		attackers.clear()
		# her üste bir tim bırak
		var keep := {}
		for u in units:
			var near_base := false
			for b in _buildings("fob", false):
				if u.position.distance_to(b.position) < 30.0 and not keep.has(b) and u is Soldier:
					keep[b] = true
					near_base = true
			if not near_base:
				attackers.append(u)
		_pick_target()
		reissue = 0.0
	if attackers.size() >= 3:
		if target_b == null or not is_instance_valid(target_b) or not target_b.alive or target_b.team == team:
			_pick_target()
		if reissue <= 0.0 and target_pos != Vector3.INF:
			reissue = 14.0
			var lead := _centroid(attackers)
			var p := target_pos
			# kademeli ilerle: 45 m adımlar
			var d := p - lead
			if d.length() > 50.0:
				p = lead + d.normalized() * 45.0
			G.player.move_group(attackers, p)

func _pick_target() -> void:
	var best: Building = null
	var bd := 1e9
	var from: Vector3 = G.hq_pos[team]
	for u in G.units:
		if is_instance_valid(u) and u.alive and u is Building and u.team == 1 - team and u.done and u.is_base():
			var d = u.position.distance_to(from)
			if d < bd:
				bd = d
				best = u
	target_b = best
	target_pos = best.position if best else Vector3.INF

func _centroid(units: Array) -> Vector3:
	var c := Vector3.ZERO
	for u in units:
		c += u.position
	return c / maxf(units.size(), 1)
