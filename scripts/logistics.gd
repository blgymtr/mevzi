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
	var route := PackedVector3Array()
	if parent != null:
		var a := _door(parent)
		var z := _door(b)
		route = G.grid.find_path(a, z, Grid.M_LIGHT)
		route.insert(0, a)
		var pts := PackedVector3Array()
		for p in route:
			pts.append(p)
		G.terrain.road_polyline(pts, 4.2, G.rng)
	nodes[t].append({"b": b, "parent": parent, "route": route})
	_ensure_trucks(t)

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
			if np != null:
				c["route"] = G.grid.find_path(_door(np), _door(cb), Grid.M_LIGHT)
				c["route"].insert(0, _door(np))
			else:
				c["route"] = PackedVector3Array()

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
	return out

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
		tr.follow_route(G.grid.find_path(tr.position, _door(hq), Grid.M_LIGHT) if r.size() < 2 else r)
	elif j["state"] == "back":
		j["state"] = "load"
		j["t"] = 4.0

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
				trucks[t].erase(tr)
				continue
			var j: Dictionary = tr.job
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
