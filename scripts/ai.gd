class_name AICmd extends Node
# Yapay zekâ komutanı: oyuncuyla aynı kurallarla üs kurar, üretir, savunur ve saldırır.

var team := 1
var tick := 0.0
var wave_t := 150.0
var target_pos := Vector3.INF
var target_b: Building = null
var attackers: Array = []
var target_zone = null
var reissue := 0.0
var think_n := 0
var guards := {}        # bölge adı -> o bölgeyi tutmak için bırakılan askerler
var arty_t := 0.0
var route := PackedVector3Array()   # saldırı grubunun hedefe giden yol rotası (nehir/köprü dolanır)
var route_for := Vector3.INF
var route_from := Vector3.ZERO
var route_n := 0
var route_mode := Grid.M_LIGHT
var stall_t := 0.0             # saldırı grubu hedefe yaklaşmıyorsa artar; 90 sn'de hedef değişir
var best_d := 1e9
var avoid := {}                # bölge adı -> bu zamana dek seçilmez (ulaşılamadı)

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
	var md := _mode()
	# Bölgeyi Savun: saldıran yapay zekâ dalga dalga gelir (ek ikmal)
	if md == "defend":
		G.supply[team] += 1.6
	# Tarihsel operasyon: kurulu kuvvetle savaşılır, üretim yok
	if md != "historical":
		_economy()
		_builders()
		_production()
	_defend()
	if md in ["assault", "historical"]:
		_hold_zones()
	else:
		_attack()
	_artillery()

func _mode() -> String:
	return G.modes.mode if G.modes != null and is_instance_valid(G.modes) else ""

# savunan yapay zekâ (Saldırı, Tarihsel): her bölgede bir koruma timi; kalan kuvvet tehdit altındaki (düşmanın
# yaklaştığı ya da kaybedilen) bölgeye, yoksa düşman karargâhına en yakın (cephe) bölgeye
func _hold_zones() -> void:
	if think_n % 4 != 0:
		return
	var zs: Array = G.modes.zones
	if zs.is_empty():
		return
	var foe: int = 1 - team
	var tz = null
	var bd := 1e18
	for i in zs.size():
		var z: Dictionary = zs[i]
		if G.modes.locked(i) and i < G.modes.obj_i:
			continue
		var threat: bool = z["owner"] != team or not G.enemies_near(z["p"], G.modes.zone_r * 3.0, team).is_empty()
		var d: float = (z["p"] as Vector3).distance_to(G.hq_pos[foe]) - (1e6 if threat else 0.0)
		if G.modes.mode == "historical" and i == G.modes.obj_i:
			d -= 5e5
		if d < bd:
			bd = d
			tz = z
	var pool: Array = []
	for u in _combat_units():
		if not _guarding(u) and not _is_gun(u):
			pool.append(u)
	for i in zs.size():
		if G.modes.locked(i) and i < G.modes.obj_i:
			continue
		_guard_zone(zs[i], pool)
	if tz == null:
		return
	var go: Array = pool.filter(func(u): return u.position.distance_to(tz["p"]) > G.modes.zone_r * 0.8 and (u is Vehicle or u.state == "idle"))
	if not go.is_empty():
		G.player.move_group(go, tz["p"])

func _guard_zone(z: Dictionary, pool: Array) -> void:
	var key := String(z["name"])
	var g: Array = (guards.get(key, []) as Array).filter(func(u): return is_instance_valid(u) and u.alive)
	guards[key] = g
	if g.size() >= 3:
		return
	var zp: Vector3 = z["p"]
	pool.sort_custom(func(a, b): return a.position.distance_to(zp) < b.position.distance_to(zp))
	var add: Array = []
	for u in pool:
		if add.size() >= 4 - g.size():
			break
		if u is Soldier:
			add.append(u)
	for u in add:
		pool.erase(u)
		g.append(u)
	guards[key] = g
	if not add.is_empty():
		G.player.move_group(add, zp)

# büyük harita ölçeği: yürüme, inşaat ve savunma yarıçapları haritayla büyür (8 km'de inşaatçı ~1,3 km öteye gider)
func _reach(base: float, frac: float) -> float:
	return maxf(base, G.MAP * frac)

# topçu ve çekili silahlar saldırı grubuyla yürümez
func _is_gun(u) -> bool:
	return u is Vehicle and (u.vtype in Vehicle.INDIRECT or u.vtype in Vehicle.TOWED)

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
	var want_fobs := mini(7, 1 + int(t / 120.0) + (1 if G.supply[team] > 1500 else 0))
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
			if s is Soldier and s.can_fight() and s.state == "idle" and not attackers.has(s) and not _guarding(s) and s.dist2(b) < (_reach(110.0, 0.35) if b.btype == "fob" else _reach(110.0, 0.16)):
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
				pick = "tank" if (r < 0.26 and t > 200.0) else ("ifv" if r < 0.38 else ("apc" if r < 0.5 else ("aa" if r < 0.57 else ("arty" if r < 0.62 and t > 300.0 else ("atgun" if r < 0.7 else ("fieldgun" if r < 0.76 else ("howitzer" if r < 0.81 and t > 240.0 else ("mlrs" if r < 0.85 and t > 360.0 else ("hmortar" if r < 0.89 else "technical")))))))))
			"barracks":
				var r2 := randf()
				pick = "at_squad" if r2 < 0.22 else ("mg_team" if r2 < 0.34 else ("medic_team" if r2 < 0.42 else ("sniper_team" if r2 < 0.5 else ("mortar_team" if r2 < 0.58 else ("drone_team" if r2 < 0.66 else ("engineer_squad" if r2 < 0.72 else "rifle_squad"))))))
			_:
				pick = "rifle_squad" if randf() < 0.8 else "medic_team"
		if not opts.has(pick):
			pick = opts[0]
		# araç: ulusun gerçek katalog birimi (oyuncu gibi: gerçek can/zırh/menzil, ayrıntılı model)
		if b.btype in ["factory", "helipad"]:
			var cid := _cat_pick(pick, b)
			if cid != "":
				pick = cid
		var P: Dictionary = Building.PDEF[pick]
		if G.cap_used[team] + P["cap"] <= G.cap_max[team] and G.supply[team] >= P["cost"] + (150 if b.btype == "hq" and t > 120 else 0):
			b.enqueue(pick)

const PICK_CATS := {"tank": ["tank"], "apc": ["apc"], "ifv": ["ifv", "td"], "aa": ["aa"], "arty": ["spg"], "mlrs": ["mlrs"],
	"howitzer": ["towed"], "fieldgun": ["towed"], "hmortar": ["mortar"], "technical": ["mrap", "light"], "heli": ["heli_atk"],
	"transport": ["heli_tr"]}

# taban türü → ulusun katalog birimlerinden biri (ucuz olan biraz daha sık; istihkâm vb. rol dışı alt sınıflar hariç)
func _cat_pick(base: String, b: Building) -> String:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else ""
	if nat == "" or not PICK_CATS.has(base):
		return ""
	var cats: Array = PICK_CATS[base]
	var cands: Array = []
	var wsum := 0.0
	for id in Catalog.units:
		var u: Dictionary = Catalog.units[id]
		if u.get("nation", "") != nat or Catalog.FAM_BASE.get(u.get("fam", ""), "") != base or not cats.has(u.get("cat", "")):
			continue
		if not b.can_produce(id):
			continue
		var w := 1.0 / maxf(float(u.get("cost", 200)), 60.0)
		cands.append([id, w])
		wsum += w
	if cands.is_empty():
		return ""
	var r := randf() * wsum
	for c in cands:
		r -= c[1]
		if r <= 0.0:
			return c[0]
	return cands[cands.size() - 1][0]

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
			if not attackers.has(u) and not _is_gun(u) and u.position.distance_to(b.position) < _reach(70.0, 0.03) and (u is Vehicle or u.order == ""):
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
	if G.modes != null and is_instance_valid(G.modes):
		need = int(need * (0.35 if G.modes.mode == "defend" else 0.5))
	need += int(G.time / 120.0)
	if G.time > 600.0:
		need = 16
	if G.cap_used[team] >= G.cap_max[team] - 2:
		need = mini(need, 12)
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
			if not near_base and not _is_gun(u) and not _guarding(u):
				attackers.append(u)
		_pick_target()
		reissue = 0.0
	if attackers.size() >= 3 and think_n % 10 == 0:
		# takviye: üste boşta bekleyen birlikler (yeni üretilenler) saldırı grubuna katılır; her dört boştakinden
		# biri üs savunmasında kalır (büyük haritada üretilen 150 asker üste bekliyordu)
		var idle_n := 0
		for u in units:
			if attackers.has(u) or _guarding(u) or _is_gun(u):
				continue
			if u is Soldier and (u.state != "idle" or u.order != "" or u.build_site != null):
				continue
			if u is Vehicle and u.order != "":
				continue
			idle_n += 1
			if idle_n % 4 != 0:
				attackers.append(u)
	if attackers.size() >= 3 and _mode() == "ctf":
		_ctf()
	elif attackers.size() >= 3:
		if target_zone != null:
			if target_zone["owner"] == team:
				_leave_guard(target_zone)
				_pick_target()
		elif target_b == null or not is_instance_valid(target_b) or not target_b.alive or target_b.team == team:
			_pick_target()
		if reissue <= 0.0 and target_pos != Vector3.INF:
			reissue = 14.0
			var lead := _centroid(attackers)
			# takılma: grup 90 sn'dir hedefe yaklaşamıyorsa (yol yok / tıkalı) bu hedef bir süre bırakılır
			var dnow := lead.distance_to(target_pos)
			if dnow < best_d - 15.0:
				best_d = dnow
				stall_t = 0.0
			else:
				stall_t += 14.0
			if stall_t >= 90.0:
				if target_zone != null:
					avoid[String(target_zone["name"])] = G.time + 300.0
				stall_t = 0.0
				best_d = 1e9
				_pick_target()
				if target_pos == Vector3.INF:
					return
			var p := target_pos
			# kademeli ilerle: küçük haritada 45 m, büyük haritada ~160 m adımlar (grup dağılmasın); adım
			# hedefe düz çizgide değil yol rotası üzerinde (düz adım nehre düşüp grubu kıyıda kilitliyordu)
			var step := clampf(G.MAP * 0.02, 45.0, 200.0)
			p = _route_step(lead, step)
			G.player.move_group(attackers, p)

# bayrak kapma: bir tim kendi bayrağını korur; taşıyıcı kendi bayrağına koşar, grup ona eşlik eder; düşen kendi
# bayrağı varsa önce o geri alınır; yoksa grup düşman bayrağına yürür
func _ctf() -> void:
	var own: Dictionary = G.modes.flags[team]
	var ef: Dictionary = G.modes.flags[1 - team]
	if attackers.size() >= 8:
		_leave_guard({"name": "bayrak", "p": own["home"]})
	var carrier = ef["carrier"] if ef["state"] == "carried" else null
	if carrier != null and is_instance_valid(carrier) and carrier.team == team:
		target_pos = own["home"]
		if carrier.dest.distance_to(own["home"]) > 2.0:
			carrier.cmd_move(own["home"], true)
	elif own["state"] == "dropped":
		target_pos = own["pos"]
	else:
		target_pos = ef["pos"]
	target_zone = null
	target_b = null
	if reissue <= 0.0:
		reissue = 8.0
		var grp: Array = attackers.filter(func(u): return u != carrier)
		if not grp.is_empty():
			G.player.move_group(grp, target_pos)

func _pick_target() -> void:
	best_d = 1e9
	stall_t = 0.0
	if _mode() == "ctf":
		return
	if G.modes != null and is_instance_valid(G.modes):
		var lead: Vector3 = _centroid(attackers) if not attackers.is_empty() else G.hq_pos[team]
		var bz = null
		var bzd := 1e9
		for z in G.modes.zones:
			if z["owner"] == team or float(avoid.get(String(z["name"]), 0.0)) > G.time:
				continue
			var d: float = lead.distance_to(z["p"])
			if d < bzd:
				bzd = d
				bz = z
		if bz != null:
			target_zone = bz
			target_b = null
			target_pos = bz["p"]
			return
	target_zone = null
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

func _route_step(lead: Vector3, step: float) -> Vector3:
	if route_for.distance_to(target_pos) > 1.0:
		route_for = target_pos
		route_from = lead
		route_n += 1
		route = PackedVector3Array()
		# grup çoğunlukla piyadeyse piyade yolu (ormandan geçer), değilse hafif araç yolu
		var sol := 0
		for u in attackers:
			if is_instance_valid(u) and u is Soldier:
				sol += 1
		route_mode = Grid.M_INF if sol * 2 >= attackers.size() else Grid.M_LIGHT
		_request_route()
	if route.size() < 2:
		var d := target_pos - lead
		return lead + d.normalized() * step if d.length() > step + 5.0 else target_pos
	var bi := 0
	var bd := 1e18
	for i in route.size():
		var dd := Vector2(route[i].x - lead.x, route[i].z - lead.z).length_squared()
		if dd < bd:
			bd = dd
			bi = i
	var acc := 0.0
	for i in range(bi + 1, route.size()):
		var seg := route[i - 1].distance_to(route[i])
		if acc + seg >= step:
			return route[i - 1].lerp(route[i], (step - acc) / maxf(seg, 0.01))
		acc += seg
	return route[route.size() - 1]

func _request_route() -> void:
	if G.grid.wants_async(route_from, route_for):
		G.grid.request_path(route_from, route_for, route_mode, _on_route.bind(route_n))
	else:
		route = G.grid.find_path(route_from, route_for, route_mode)

func _on_route(res: PackedVector3Array, n: int) -> void:
	if n != route_n:
		return
	route = res
	if res.size() < 2 and route_mode != Grid.M_INF:
		# araç yolu yok (nehir / orman): piyade yoluyla yeniden dene
		route_mode = Grid.M_INF
		route_n += 1
		_request_route()

# ele geçirilen bölgeye bir tim bırakılır (tutulmazsa düşman kolayca geri alır)
func _leave_guard(z) -> void:
	var key := String(z["name"])
	if guards.has(key) and not (guards[key] as Array).filter(func(u): return is_instance_valid(u) and u.alive).is_empty():
		return
	var zp: Vector3 = z["p"]
	var best: Squad = null
	var bd := 1e9
	for u in attackers:
		if u is Soldier and u.squad != null and u.can_fight():
			var d: float = u.position.distance_to(zp)
			if d < bd:
				bd = d
				best = u.squad
	if best == null or attackers.size() < 8:
		return
	var men: Array = best.alive_members()
	for s in men:
		attackers.erase(s)
	guards[key] = men
	G.player.move_group(men, zp)

func _guarding(u) -> bool:
	for k in guards:
		if (guards[k] as Array).has(u):
			return true
	return false

# topçu: saldırı hedefini menzile alacak, cephenin gerisinde bir mevziye geçer; görülen hedefe kendisi ateş eder
func _artillery() -> void:
	arty_t -= 1.0
	if arty_t > 0.0 or target_pos == Vector3.INF:
		return
	arty_t = 20.0
	var hq := _hq()
	var home: Vector3 = hq.position if hq != null else G.hq_pos[team]
	for u in _mine():
		if not (u is Vehicle) or not (u.vtype in Vehicle.INDIRECT) or u.order != "" or u.immobile():
			continue
		var rg: float = u._range()
		if rg <= 0.0:
			continue
		var d: float = u.position.distance_to(target_pos)
		if d <= rg * 0.85 and d >= u._min_range() * 1.3:
			continue
		var dir := (home - target_pos)
		dir.y = 0.0
		if dir.length() < 1.0:
			continue
		var p: Vector3 = target_pos + dir.normalized() * clampf(rg * 0.6, u._min_range() * 1.5, dir.length())
		u.cmd_move(G.grid.nearest_free(p, u.nav_mode))

func _centroid(units: Array) -> Vector3:
	var c := Vector3.ZERO
	for u in units:
		c += u.position
	return c / maxf(units.size(), 1)
