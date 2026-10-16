class_name Logistics extends Node
# İkmal hattı: her üs bir öncekine yolla bağlanır, kamyonlar karargâhtan üslere ikmal taşır.
# İkmal geliri: karargâh az miktar üretir; asıl gelir kamyonların üslere teslimatıdır.

const DELIVERY := 160.0
const HQ_TRICKLE := 3.2
const STOCK_DELIVERY := 450.0   # kg / sefer

var nodes := [[], []]      # {b: Building, parent: Building, route: PackedVector3Array}
var trucks := [[], []]
var respawn := [[], []]    # zaman damgaları
var _rr := [0, 0]

func register_base(b: Building) -> void:
	var t := b.team
	for n in nodes[t]:
		if n["b"] == b:
			return
	var parent: Building = null
	var best := 1e9
	for n in nodes[t]:
		var o: Building = n["b"]
		if not is_instance_valid(o) or not o.alive:
			continue
		var d := o.position.distance_to(b.position)
		if d < best:
			best = d
			parent = o
	var node := {"b": b, "parent": parent, "route": PackedVector3Array()}
	nodes[t].append(node)
	if parent != null:
		var a := _door(parent)
		var z := _door(b)
		# büyük haritada üsler arası yol (1–2 km) işçi iş parçacığında aranır; gelince yol boyanır
		_route_async(a, z, func(rt: PackedVector3Array):
			var r2 := rt.duplicate()
			r2.insert(0, a)
			node["route"] = r2
			G.terrain.road_polyline(r2, 4.2, G.rng))
	_ensure_trucks(t)

func _route_async(a: Vector3, z: Vector3, cb: Callable) -> void:
	if G.grid.wants_async(a, z) and not G.grid.direct(a, z, Grid.M_LIGHT):
		G.grid.request_path(a, z, Grid.M_LIGHT, cb)
	else:
		cb.call(G.grid.find_path(a, z, Grid.M_LIGHT))

func _door(b: Building) -> Vector3:
	return G.grid.nearest_free(b.position + Vector3(0, 0, b.size.y * 0.5 + 3.5).rotated(Vector3.UP, b.rot), Grid.M_LIGHT)

func _node_of(b: Building) -> Dictionary:
	for n in nodes[b.team]:
		if n["b"] == b:
			return n
	return {}

func base_lost(b: Building) -> void:
	var t := b.team
	var n := _node_of(b)
	if n.is_empty():
		return
	nodes[t].erase(n)
	# çocukları en yakın düğüme yeniden bağla
	for c in nodes[t]:
		if c["parent"] == b:
			var cb: Building = c["b"]
			var best := 1e9
			var np: Building = null
			for o in nodes[t]:
				var ob: Building = o["b"]
				if ob == cb or not is_instance_valid(ob):
					continue
				var d := ob.position.distance_to(cb.position)
				if d < best:
					best = d
					np = ob
			c["parent"] = np
			c["route"] = PackedVector3Array()
			if np != null:
				var a := _door(np)
				var cc: Dictionary = c
				_route_async(a, _door(cb), func(rt: PackedVector3Array):
					var r2 := rt.duplicate()
					r2.insert(0, a)
					cc["route"] = r2)

func _hq(t: int) -> Building:
	for n in nodes[t]:
		var b: Building = n["b"]
		if is_instance_valid(b) and b.alive and b.btype == "hq":
			return b
	return null

func route_to(b: Building) -> PackedVector3Array:
	var chain: Array = []
	var cur := _node_of(b)
	var guard := 0
	while not cur.is_empty() and cur["parent"] != null and guard < 20:
		guard += 1
		chain.push_front(cur["route"])
		cur = _node_of(cur["parent"])
	var out := PackedVector3Array()
	for r in chain:
		out.append_array(r)
	# rota üs kurulunca bir kez hesaplanır; sonradan üstüne yapı dikildiyse kamyon binanın içinden geçerdi
	# (roadmap 96) → kapanmış rota yeniden aranır, o sırada çağıran doğrudan yol bulur
	if not route_clear(out):
		var n := _node_of(b)
		while not n.is_empty() and n["parent"] != null:
			if not route_clear(n["route"]):
				_reroute(n)
			n = _node_of(n["parent"])
		return PackedVector3Array()
	return out

static func route_clear(r: PackedVector3Array, from := 0) -> bool:
	for q in range(maxi(from, 1), r.size()):
		if not G.grid.walkable_line(r[q - 1], r[q], Grid.M_LIGHT):
			return false
	return true

func _reroute(n: Dictionary) -> void:
	if n.get("rerouting", false) or not is_instance_valid(n["parent"]):
		return
	n["rerouting"] = true
	var a := _door(n["parent"])
	var z := _door(n["b"])
	_route_async(a, z, func(rt: PackedVector3Array):
		var r2 := rt.duplicate()
		r2.insert(0, a)
		n["route"] = r2
		n["rerouting"] = false)

# yapı yerleşti (main.place_building): yoldaki kamyonların kalan yolu kapandıysa yeniden aranır
func static_changed() -> void:
	for t in trucks.size():
		for tr in trucks[t]:
			if is_instance_valid(tr) and tr.alive and tr.order == "route" and tr.path_i < tr.path.size():
				if not route_clear(tr.path, tr.path_i) or not G.grid.walkable_line(tr.position, tr.path[tr.path_i], Grid.M_LIGHT):
					var goal: Vector3 = tr.path[tr.path.size() - 1]
					_route_async(tr.position, goal, func(p: PackedVector3Array):
						if is_instance_valid(tr) and tr.alive and p.size() > 0:
							tr.follow_route(p))

func _fobs(t: int) -> Array:
	var out: Array = []
	for n in nodes[t]:
		var b: Building = n["b"]
		if is_instance_valid(b) and b.alive and b.btype == "fob" and b.team == t:
			out.append(b)
	return out

func _ensure_trucks(t: int) -> void:
	var want := mini(5, _fobs(t).size() + 1) if _fobs(t).size() > 0 else 0
	var have := 0
	for tr in trucks[t]:
		if is_instance_valid(tr) and tr.alive:
			have += 1
	have += respawn[t].size()
	var hq := _hq(t)
	if hq == null:
		return
	for i in range(have, want):
		_spawn_truck(t)

func _spawn_truck(t: int) -> void:
	var hq := _hq(t)
	if hq == null:
		return
	var p := _door(hq)
	var tr: Vehicle = G.main.spawn_vehicle(t, "truck", p, hq.rot + PI)
	trucks[t].append(tr)
	tr.job = {"state": "load", "t": 3.0, "to": null}

func truck_arrived(tr: Vehicle) -> void:
	var j := tr.job
	if j.is_empty():
		return
	if j["state"] == "out":
		j["state"] = "unload"
		j["t"] = 6.0
		return
	if j["state"] == "unload":
		var b = j["to"]
		if b != null and is_instance_valid(b) and b.alive and b.team == tr.team:
			G.supply[tr.team] += DELIVERY
			b.stock = minf(Building.STOCK_MAX, b.stock + STOCK_DELIVERY)
			b.supplied_t = G.time
			if tr.team == G.player_team and not G.spectate:
				G.say(I18n.s("+%d ikmal") % int(DELIVERY) + "  ·  +%d kg" % int(STOCK_DELIVERY), b.position, tr.team)
		j["state"] = "back"
		var r := route_to(b) if (b != null and is_instance_valid(b)) else PackedVector3Array()
		r.reverse()
		var hq := _hq(tr.team)
		if hq != null:
			r.append(_door(hq))
		if r.size() >= 2:
			tr.follow_route(r)
		else:
			var trk := tr
			_route_async(tr.position, _door(hq), func(p: PackedVector3Array):
				if is_instance_valid(trk) and trk.alive and trk.job.get("state", "") == "back":
					trk.follow_route(p))
	elif j["state"] == "back":
		j["state"] = "load"
		j["t"] = 4.0

# yükleme/boşaltma: iki asker kamyonun arkasıyla üs kapısı arasında kutu taşır
var _crate_mesh: Mesh = null

func _porters(tr: Vehicle, dt: float, j: Dictionary) -> void:
	var st: String = j.get("state", "")
	var active := (st == "load" or st == "unload") and tr.cur_speed < 0.2
	var ps: Array = tr.get_meta("porters", [])
	if not active:
		if not ps.is_empty():
			for p in ps:
				if is_instance_valid(p[0]):
					p[0].queue_free()
			tr.set_meta("porters", [])
		return
	var b = j.get("to") if st == "unload" else _hq(tr.team)
	if b == null or not is_instance_valid(b):
		return
	var rear: Vector3 = tr.position - tr.forward() * 4.6
	rear.y = G.terrain.ground_h(rear)
	# binanın kenarı (kamyonun arkasına bakan taraf)
	var to_r: Vector3 = rear - b.position
	to_r.y = 0.0
	var door: Vector3 = b.position + to_r.normalized() * maxf(b.radius * 0.85, 2.0)
	door.y = G.terrain.ground_h(door)
	if ps.is_empty():
		if _crate_mesh == null:
			var mb := MB.new()
			mb.box(Vector3(0, 0, 0), Vector3(0.55, 0.32, 0.4), Color(0.4, 0.42, 0.26))
			mb.box(Vector3(0, 0.17, 0), Vector3(0.57, 0.03, 0.12), Color(0.25, 0.25, 0.2))
			_crate_mesh = mb.commit(Mats.vc())
		for k in 2:
			var sb := SoldierBody.new()
			G.world.add_child(sb)
			sb.build(tr.team, "crew", G.map_kind == "winter")
			sb.weapon.visible = false
			var cr := MeshInstance3D.new()
			cr.mesh = _crate_mesh
			cr.position = Vector3(0, 1.12, -0.36)
			sb.add_child(cr)
			ps.append([sb, k * 0.5, cr])
		tr.set_meta("porters", ps)
	var fw := tr.forward()
	var side := Vector3(-fw.z, 0, fw.x)
	for i in ps.size():
		var p: Array = ps[i]
		var sb: SoldierBody = p[0]
		p[1] = fmod(p[1] + dt / 7.0, 1.0)
		var t: float = p[1]
		# her hamal kamyonun bir yanından: arka kapak -> yan -> ön -> bina kenarı
		var sg := 1.0 if i == 0 else -1.0
		var path: Array[Vector3] = [rear + side * sg * 0.35, rear + side * sg * 1.7, tr.position + fw * 3.4 + side * sg * 1.7, door + side * sg * 0.6]
		if st == "load":
			path.reverse()
		# 0-0.5 dolu gidiş, 0.5-1 boş dönüş
		var carrying := t < 0.5
		var k2 := t * 2.0 if carrying else 1.0 - (t - 0.5) * 2.0
		var L := 0.0
		for q in range(1, path.size()):
			L += path[q].distance_to(path[q - 1])
		var d := k2 * L
		var pos := path[0]
		var dirv := path[1] - path[0]
		for q in range(1, path.size()):
			var seg := path[q].distance_to(path[q - 1])
			if d <= seg or q == path.size() - 1:
				pos = path[q - 1].lerp(path[q], clampf(d / maxf(seg, 0.01), 0.0, 1.0))
				dirv = path[q] - path[q - 1]
				break
			d -= seg
		if not carrying:
			dirv = -dirv
		pos.y = G.terrain.ground_h(pos)
		sb.position = pos
		sb.rotation.y = atan2(-dirv.x, -dirv.z)
		(p[2] as MeshInstance3D).visible = carrying
		sb.animate(dt, "carry" if carrying else "walk", 1.3 if carrying else 1.8, 1.0)

func truck_lost(tr: Vehicle) -> void:
	trucks[tr.team].erase(tr)
	respawn[tr.team].append(G.time + 30.0)
	if tr.team == G.player_team and not G.spectate:
		G.say("İkmal kamyonu vuruldu!", tr.position, tr.team)
		Sfx.play2d("ui_alert", -4.0)

func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	for t in 2:
		if _hq(t) != null:
			G.supply[t] += HQ_TRICKLE * dt
		var i: int = respawn[t].size() - 1
		while i >= 0:
			if G.time >= respawn[t][i]:
				respawn[t].remove_at(i)
				if _fobs(t).size() > 0:
					_spawn_truck(t)
			i -= 1
		for tr in trucks[t].duplicate():
			if not is_instance_valid(tr) or not tr.alive:
				if is_instance_valid(tr):
					_porters(tr, dt, {})
				trucks[t].erase(tr)
				continue
			var j: Dictionary = tr.job
			_porters(tr, dt, j)
			if j.get("state", "") == "unload":
				j["t"] -= dt
				if j["t"] <= 0.0:
					truck_arrived(tr)
				continue
			if j.get("state", "") == "load":
				j["t"] -= dt
				if j["t"] <= 0.0:
					var fobs := _fobs(t)
					if fobs.is_empty():
						j["t"] = 5.0
						continue
					_rr[t] = (_rr[t] + 1) % fobs.size()
					var b: Building = fobs[_rr[t]]
					var r := route_to(b)
					if r.size() < 2 and G.grid.wants_async(tr.position, _door(b)):
						# yol daha hesaplanıyor (işçi iş parçacığı): kısa süre sonra yeniden dene
						j["t"] = 2.0
						continue
					if r.size() < 2:
						r = G.grid.find_path(tr.position, _door(b), Grid.M_LIGHT)
					else:
						var lead := G.grid.find_path(tr.position, r[0], Grid.M_LIGHT)
						lead.append_array(r)
						r = lead
					j["state"] = "out"
					j["to"] = b
					tr.follow_route(r)
			elif tr.path_i >= tr.path.size() and j.get("state", "") in ["out", "back"] and tr.cur_speed < 0.2:
				truck_arrived(tr)
