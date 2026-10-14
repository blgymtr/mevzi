class_name PlayerCtl extends Node
# Oyuncu girdisi: seçim, emir, inşa yerleştirme, kontrol grupları.

var selected: Array = []
var groups := {}
var box_start := Vector2.ZERO
var boxing := false
var box_now := Vector2.ZERO
var place_type := ""
var place_a := Vector3.INF
var place_rot := 0.0
var ghost: MeshInstance3D
var ghost_ok := false
var markers: Array = []     # [konum, zaman, renk]
var _last_click := 0.0
var _last_click_unit: Unit = null
var team := 0
var pending_order := ""      # hedef bekleyen emir (el bombası, baskı ateşi...)

func _ready() -> void:
	ghost = MeshInstance3D.new()
	ghost.visible = false
	ghost.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	G.world.add_child(ghost)

func deselect(u) -> void:
	selected.erase(u)
	if is_instance_valid(u):
		u.set_selected(false)

func clear_sel() -> void:
	for u in selected:
		if is_instance_valid(u):
			u.set_selected(false)
	selected.clear()

func select(u) -> void:
	if not selected.has(u):
		selected.append(u)
		u.set_selected(true)

func _vp_mouse() -> Vector2:
	return get_viewport().get_mouse_position()

func over_ui() -> bool:
	return G.hud != null and G.hud.mouse_over_ui()

# ------------------------------------------------------------ girdi
func _unhandled_input(e: InputEvent) -> void:
	if not G.running or G.spectate or G.game_over:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		if mb.button_index == MOUSE_BUTTON_LEFT:
			if mb.pressed:
				if place_type != "":
					_place_click()
					return
				if pending_order != "":
					exec_order(pending_order, G.cam.mouse_ground(mb.position))
					if not mb.shift_pressed:
						pending_order = ""
					return
				box_start = mb.position
				box_now = mb.position
				boxing = true
			elif boxing:
				boxing = false
				_finish_box(mb.shift_pressed, mb.ctrl_pressed)
		elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed:
			if place_type != "":
				cancel_place()
				return
			if pending_order != "":
				pending_order = ""
				return
			_command(mb.position, mb.ctrl_pressed, mb.shift_pressed, mb.alt_pressed)
	elif e is InputEventMouseMotion:
		if boxing:
			box_now = (e as InputEventMouseMotion).position
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := e as InputEventKey
		var code := k.keycode
		if code >= KEY_0 and code <= KEY_9:
			var n := code - KEY_0
			if k.ctrl_pressed:
				groups[n] = selected.duplicate()
				G.say("Grup %d atandı" % n, Vector3.ZERO, team)
			elif groups.has(n):
				var g: Array = groups[n].filter(func(u): return is_instance_valid(u) and u.alive)
				if not g.is_empty():
					var same := selected.size() == g.size() and selected.all(func(u): return g.has(u))
					clear_sel()
					for u in g:
						select(u)
					if same:
						G.cam.jump_to(_centroid(g))
			return
		if Hud.ORDER_KEYS.has(code) and not k.ctrl_pressed and not (code == KEY_R and place_type != ""):
			order_button(Hud.ORDER_KEYS[code])
			return
		match code:
			KEY_ESCAPE:
				if pending_order != "":
					pending_order = ""
				elif place_type != "":
					cancel_place()
				elif not selected.is_empty():
					clear_sel()
				else:
					G.hud.toggle_pause()
			KEY_HOME, KEY_BACKSPACE:
				for u in G.units:
					if is_instance_valid(u) and u is Building and u.team == team and u.btype == "hq":
						G.cam.jump_to(u.position)
			KEY_R:
				place_rot += PI * 0.5
			KEY_F1, KEY_F2, KEY_F3:
				Engine.time_scale = [1.0, 2.0, 3.0][code - KEY_F1]
			KEY_PAUSE, KEY_P:
				G.hud.toggle_pause()
			KEY_Q:
				_select_type_on_screen("inf")
			KEY_E:
				_select_type_on_screen("veh")

func _process(_dt: float) -> void:
	if place_type != "":
		_update_ghost()
	selected = selected.filter(func(u): return is_instance_valid(u) and u.alive)
	var now := G.time
	markers = markers.filter(func(m): return now - m[1] < 1.2)

# ------------------------------------------------------------ seçim
func unit_at(sp: Vector2, only_own := false) -> Unit:
	var best: Unit = null
	var bd := 1e9
	var px_per_m: float = get_viewport().get_visible_rect().size.y / G.cam.size
	for u in G.units:
		if not is_instance_valid(u) or not u.alive or not u.visible:
			continue
		if only_own and u.team != team:
			continue
		var s := G.cam.screen(u.aim_point() if u is Vehicle else u.position + Vector3(0, 0.7 if not (u is Building) else 1.5, 0))
		var r: float = maxf(14.0, u.radius * px_per_m * (1.2 if not (u is Building) else 0.9))
		var d := s.distance_to(sp)
		if d < r and d < bd:
			bd = d
			best = u
	return best

func _finish_box(add: bool, ctrl: bool) -> void:
	var r := Rect2(box_start, box_now - box_start).abs()
	if r.size.length() < 6.0:
		var u := unit_at(box_start)
		if not add:
			clear_sel()
		if u != null and u.team == team:
			var now := Time.get_ticks_msec() / 1000.0
			if (now - _last_click < 0.35 and _last_click_unit == u) or ctrl:
				_select_same(u)
			else:
				if add and selected.has(u):
					deselect(u)
				elif u is Soldier and u.squad and not Input.is_key_pressed(KEY_ALT):
					select_squad_of(u)
				else:
					select(u)
			_last_click = now
			_last_click_unit = u
			if u is Soldier and u.squad and not add and not ctrl and now - _last_click > 0.01:
				pass
		elif u != null:
			select(u)
		Sfx.play2d("ui_click", -10.0)
		return
	if not add:
		clear_sel()
	var got_mobile := false
	for u in G.units:
		if not is_instance_valid(u) or not u.alive or u.team != team or u is Building:
			continue
		if u is Vehicle and u.vtype in ["truck", "fpv"]:
			continue
		if u is Soldier and u.state == "aboard" and not u.visible:
			continue
		if r.has_point(G.cam.screen((u.aim_point() if u is Vehicle else u.position + Vector3(0, 0.6, 0)))):
			select(u)
			got_mobile = true
	if not got_mobile:
		for u in G.units:
			if is_instance_valid(u) and u.alive and u.team == team and r.has_point(G.cam.screen(u.position)):
				select(u)
	if not selected.is_empty():
		Sfx.play2d("ui_select", -8.0)

func unload_selected() -> void:
	for u in selected:
		if is_instance_valid(u) and u is Vehicle and not u.cargo.is_empty():
			u.unload()

# ------------------------------------------------------------ emir paneli
func order_button(id: String) -> void:
	if selected.is_empty() or G.hud.order_state(id, selected) < 1:
		Sfx.play2d("ui_error", -10.0)
		return
	var O: Dictionary = Hud.ORDERS[id]
	var tgt: bool = O["tgt"]
	if id == "smoke" and not selected.any(func(u): return is_instance_valid(u) and u is Soldier and u.smoke_nades > 0):
		tgt = false
	if tgt:
		pending_order = "" if pending_order == id else id
		Sfx.play2d("ui_click", -10.0)
	else:
		exec_order(id, Vector3.INF)

func exec_order(id: String, gp: Vector3) -> void:
	var mobile := selected.filter(func(u): return is_instance_valid(u) and u.alive and (u is Soldier or (u is Vehicle and not (u.vtype in ["truck", "fpv"]))))
	var sol := mobile.filter(func(u): return u is Soldier)
	var veh := mobile.filter(func(u): return u is Vehicle)
	match id:
		"move", "fast", "amove":
			move_group(mobile, gp, id == "fast", "amove" if id == "amove" else "")
			markers.append([gp, G.time, Color(1.0, 0.45, 0.3) if id == "amove" else Color(0.4, 1.0, 0.5)])
			Sfx.play2d("ui_attack" if id == "amove" else "ui_move", -9.0)
			_voice(mobile, ["Saldırıyoruz!", "İlerliyoruz!"] if id == "amove" else (["Koş!", "Hareket!"] if id == "fast" else ["Anlaşıldı!", "Tamam!"]))
		"reverse":
			move_group(veh.filter(func(v): return not v.is_air()), gp, false, "reverse")
			markers.append([gp, G.time, Color(0.4, 0.8, 1.0)])
			Sfx.play2d("ui_move", -9.0)
		"stop":
			for u in mobile:
				u.cmd_stop()
			Sfx.play2d("ui_click", -8.0)
		"hold":
			for u in mobile:
				u.cmd_hold()
			_voice(sol, ["Mevzi tut!"])
			Sfx.play2d("ui_click", -8.0)
		"retreat":
			for u in mobile:
				u.cmd_retreat()
			_voice(sol, ["Geri çekil!"])
			G.say("Geri çekiliyoruz!", Vector3.ZERO, team)
			Sfx.play2d("ui_move", -8.0)
		"fire":
			var cur := 0
			if not mobile.is_empty():
				cur = mobile[0].fire_mode
			var nx := (cur + 1) % 3
			for u in mobile:
				u.fire_mode = nx
				if nx == 2:
					u.target = null
			_voice(sol, [["Serbest ateş!"], ["Sadece karşılık!"], ["Ateşi kes!"]][nx])
			Sfx.play2d("ui_click", -8.0)
		"stance":
			var cur2 := -1
			if not sol.is_empty():
				cur2 = sol[0].stance_lock
			var nx2 := cur2 + 1
			if nx2 > Soldier.PRONE:
				nx2 = -1
			for u in sol:
				u.stance_lock = nx2
			Sfx.play2d("ui_click", -8.0)
		"unload":
			unload_selected()
		"grenade", "smoke":
			var sm := id == "smoke"
			var best: Soldier = null
			var bd := 1e9
			for u in sol:
				if not u.can_fight() or (sm and u.smoke_nades <= 0) or (not sm and u.grenades <= 0):
					continue
				var d := Vector2(u.position.x - gp.x, u.position.z - gp.z).length() if gp != Vector3.INF else 0.0
				d += 30.0 if u.role == "mg" else 0.0
				if d < bd:
					bd = d
					best = u
			if best != null and gp != Vector3.INF:
				best.cmd_throw(gp, sm)
				markers.append([gp, G.time, Color(1.0, 0.74, 0.3)])
			var popped := false
			if sm:
				for v in veh:
					if v.cmd_smoke():
						popped = true
			if best == null and not popped:
				G.say("Sis atar boş" if sm and not veh.is_empty() else ("Sis bombası yok" if sm else "El bombası yok"), Vector3.ZERO, team)
				Sfx.play2d("ui_error", -6.0)
		"suppress":
			for u in mobile:
				u.cmd_suppress(gp)
			markers.append([gp, G.time, Color(1.0, 0.6, 0.2)])
			_voice(sol, ["Bastırın!"])
			Sfx.play2d("ui_attack", -8.0)
		"demolish":
			for u in selected.duplicate():
				if u is Building and not u.done and u.team == team:
					G.supply[team] += int(u.full_cost() * 0.75)
					u.alive = false
					deselect(u)
					u.queue_free()

func _select_same(u: Unit) -> void:
	for o in G.units:
		if is_instance_valid(o) and o.alive and o.team == team and o.kind == u.kind and G.cam.on_screen(o.position, 0.0):
			select(o)

func _select_type_on_screen(t: String) -> void:
	clear_sel()
	for o in G.units:
		if not is_instance_valid(o) or not o.alive or o.team != team or not G.cam.on_screen(o.position, 0.0):
			continue
		if (t == "inf" and o is Soldier and o.can_fight()) or (t == "veh" and o is Vehicle and o.vtype != "truck"):
			select(o)

func select_squad_of(s: Soldier) -> void:
	if s.squad:
		for m in s.squad.alive_members():
			select(m)

# ------------------------------------------------------------ emirler
func _command(sp: Vector2, force: bool, _queue: bool, alt := false) -> void:
	var mobile := selected.filter(func(u): return is_instance_valid(u) and not (u is Building))
	var gp := G.cam.mouse_ground(sp)
	if mobile.is_empty():
		for u in selected:
			if u is Building and u.team == team:
				u.rally = G.on_ground(gp)
				markers.append([u.rally, G.time, Color(0.4, 0.9, 1.0)])
		return
	var tu := unit_at(sp)
	if tu != null and tu.team != team and tu.team >= 0:
		for u in mobile:
			u.cmd_attack(tu)
		markers.append([tu.position, G.time, Color(1.0, 0.3, 0.2)])
		Sfx.play2d("ui_attack", -8.0)
		_voice(mobile, ["Saldırıyoruz!", "Hedef alındı!", "Ateş!"])
		return
	if tu != null and tu is Vehicle and tu.team == team and tu.capacity() > 0:
		var inf := mobile.filter(func(u): return u is Soldier and u.can_fight())
		if not inf.is_empty():
			for u in inf:
				u.cmd_board(tu)
			markers.append([tu.position, G.time, Color(0.4, 0.8, 1.0)])
			_voice(inf, ["Biniyoruz!", "Araca!"])
			return
	if tu != null and tu is Building and tu.team == team and not tu.done:
		for u in mobile:
			if u is Soldier:
				u.cmd_build(tu)
		markers.append([tu.position, G.time, Color(1.0, 0.8, 0.3)])
		_voice(mobile, ["İnşaya başlıyoruz!", "Anlaşıldı!"])
		return
	if tu != null and tu is Soldier and tu.team == team and tu.state == "wounded":
		var best: Soldier = null
		var bd := 1e9
		for u in mobile:
			if u is Soldier and u.can_fight() and u.dist2(tu) < bd:
				bd = u.dist2(tu)
				best = u
		if best:
			best.start_rescue(tu)
			return
	var rev := alt and mobile.any(func(u): return u is Vehicle)
	move_group(mobile, gp, force, "reverse" if rev else "")
	markers.append([gp, G.time, Color(0.4, 1.0, 0.5)])
	Sfx.play2d("ui_move", -9.0)
	_voice(mobile, ["Anlaşıldı!", "İlerliyoruz!", "Tamam!", "Hareket!"])

func _voice(units: Array, lines: Array) -> void:
	for u in units:
		if is_instance_valid(u) and u is Soldier and u.can_fight():
			u.say(lines[randi() % lines.size()], 1.6)
			return

func _send(u, p: Vector3, force: bool, mode: String) -> void:
	if mode == "amove":
		u.cmd_attack_move(p)
	elif mode == "reverse" and u is Vehicle:
		u.cmd_reverse(p)
	else:
		u.cmd_move(p, force)

func move_group(units: Array, gp: Vector3, force := false, mode := "") -> void:
	var c := _centroid(units)
	var dir := gp - c
	dir.y = 0
	if dir.length() < 0.5:
		dir = Vector3(-1, 0, -1)
	dir = dir.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	# timlere göre grupla
	var buckets := {}
	var vehicles: Array = []
	for u in units:
		if u is Vehicle:
			vehicles.append(u)
		elif u is Soldier:
			var key = u.squad if u.squad else u
			if buckets.has(key):
				buckets[key].append(u)
			else:
				buckets[key] = [u]
	var keys := buckets.keys()
	var n := keys.size()
	for i in n:
		var slot := gp + side * (i - (n - 1) * 0.5) * 7.0
		var mem: Array = buckets[keys[i]]
		for k in mem.size():
			var row := k / 3
			var col := k % 3
			var p := slot + side * (col - 1) * 1.7 - dir * row * 1.7
			_send(mem[k], G.grid.nearest_free(p, Grid.M_INF), force, mode)
	var nv := vehicles.size()
	for i in nv:
		var p := gp - dir * (6.0 if n > 0 else 0.0) + side * (i - (nv - 1) * 0.5) * 7.5
		_send(vehicles[i], p, force, mode)

func _centroid(units: Array) -> Vector3:
	var c := Vector3.ZERO
	var k := 0
	for u in units:
		if is_instance_valid(u):
			c += u.position
			k += 1
	return c / maxf(k, 1)

# ------------------------------------------------------------ inşa yerleştirme
func start_place(bt: String) -> void:
	place_type = bt
	place_a = Vector3.INF
	ghost.visible = true
	Sfx.play2d("ui_click", -8.0)

func cancel_place() -> void:
	place_type = ""
	place_a = Vector3.INF
	ghost.visible = false

func _update_ghost() -> void:
	var gp := G.cam.mouse_ground(_vp_mouse())
	gp.x = snappedf(gp.x, 0.5)
	gp.z = snappedf(gp.z, 0.5)
	var B: Dictionary = Building.BDEF[place_type]
	var bm := BoxMesh.new()
	if B.get("line", false):
		if place_a == Vector3.INF:
			bm.size = Vector3(1.0, 0.6, 1.0)
			ghost.position = gp + Vector3(0, 0.3, 0)
			ghost.rotation.y = 0
			ghost_ok = _line_ok(gp, gp)
		else:
			var L := maxf(0.5, place_a.distance_to(gp))
			L = minf(L, 30.0)
			var d := (gp - place_a).normalized() if place_a.distance_to(gp) > 0.1 else Vector3.RIGHT
			var b2 := place_a + d * L
			bm.size = Vector3(L, 0.6, 0.8)
			ghost.position = (place_a + b2) * 0.5 + Vector3(0, 0.3, 0)
			ghost.rotation.y = atan2(-d.z, d.x)
			ghost_ok = _line_ok(place_a, b2)
	else:
		var s: Vector2 = B["size"]
		bm.size = Vector3(s.x, 1.5, s.y)
		ghost.position = gp + Vector3(0, 0.75, 0)
		ghost.rotation.y = place_rot
		ghost_ok = can_place(place_type, gp, place_rot, team) == ""
	ghost.mesh = bm
	ghost.material_override = Mats.ghost(ghost_ok)

func _place_click() -> void:
	var gp := G.cam.mouse_ground(_vp_mouse())
	gp.x = snappedf(gp.x, 0.5)
	gp.z = snappedf(gp.z, 0.5)
	var B: Dictionary = Building.BDEF[place_type]
	if B.get("line", false):
		if place_a == Vector3.INF:
			place_a = gp
			return
		var L := minf(place_a.distance_to(gp), 30.0)
		if L < 1.0:
			return
		var b2 := place_a + (gp - place_a).normalized() * L
		var cost := int(ceil(B["cost"] * L))
		if not _line_ok(place_a, b2):
			G.say("Buraya yapılamaz", gp, team)
			Sfx.play2d("ui_error", -6.0)
			return
		if G.supply[team] < cost:
			G.say("Yetersiz ikmal", gp, team)
			Sfx.play2d("ui_error", -6.0)
			return
		G.supply[team] -= cost
		var bl: Building = G.main.place_line(team, place_type, place_a, b2)
		_assign_builders(bl)
		place_a = Vector3.INF
		if not Input.is_key_pressed(KEY_SHIFT):
			cancel_place()
		return
	var why := can_place(place_type, gp, place_rot, team)
	if why != "":
		G.say(why, gp, team)
		Sfx.play2d("ui_error", -6.0)
		return
	if G.supply[team] < B["cost"]:
		G.say("Yetersiz ikmal", gp, team)
		Sfx.play2d("ui_error", -6.0)
		return
	G.supply[team] -= B["cost"]
	var b: Building = G.main.place_building(team, place_type, gp, place_rot)
	_assign_builders(b)
	Sfx.play2d("ui_place", -4.0)
	if not Input.is_key_pressed(KEY_SHIFT):
		cancel_place()

func _assign_builders(b: Building) -> void:
	var inf := selected.filter(func(u): return u is Soldier and u.can_fight())
	if inf.is_empty():
		var cands: Array = []
		for u in G.units:
			if is_instance_valid(u) and u is Soldier and u.team == team and u.can_fight() and u.state == "idle" and u.dist2(b) < 70.0:
				cands.append(u)
		cands.sort_custom(func(x, y): return x.dist2(b) < y.dist2(b))
		inf = cands.slice(0, 4)
	for u in inf:
		u.cmd_build(b)

func _line_ok(a: Vector3, b: Vector3) -> bool:
	if not _near_base((a + b) * 0.5, 75.0, team):
		return false
	var L := a.distance_to(b)
	var n := int(L / 0.5) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if p.x < 2 or p.z < 2 or p.x > G.MAP - 2 or p.z > G.MAP - 2:
			return false
		if G.grid.height_at(p) > 0.3:
			return false
	return true

static func _near_base(p: Vector3, r: float, t: int) -> bool:
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == t and u.alive and u.is_base() and u.done and u.position.distance_to(p) < r:
			return true
	return false

static func can_place(bt: String, p: Vector3, rot: float, t: int) -> String:
	var B: Dictionary = Building.BDEF[bt]
	var s: Vector2 = B["size"]
	var r := maxf(s.x, s.y) * 0.5
	if p.x < r + 3 or p.z < r + 3 or p.x > G.MAP - r - 3 or p.z > G.MAP - r - 3:
		return "Harita dışı"
	if bt == "fob":
		for u in G.units:
			if is_instance_valid(u) and u is Building and u.alive and u.is_base() and u.position.distance_to(p) < 38.0:
				return "Başka bir üsse çok yakın"
		if not _near_base(p, 95.0, t):
			return "Mevcut üsse çok uzak (95 m)"
	elif not _near_base(p, 42.0, t):
		return "Bir üssün 42 m yakınına kurulmalı"
	var c := cos(rot)
	var sn := sin(rot)
	var x := -s.x * 0.5
	while x <= s.x * 0.5:
		var z := -s.y * 0.5
		while z <= s.y * 0.5:
			var q := p + Vector3(x * c + z * sn, 0, -x * sn + z * c)
			if G.grid.height_at(q) > 0.25 or G.grid.kind_at(q) == Grid.K_TRAP:
				return "Alan dolu"
			z += 1.0
		x += 1.0
	for u in G.near(p, r + 6.0):
		if u is Building and u.alive and u.position.distance_to(p) < r + u.radius:
			return "Alan dolu"
		if u is Vehicle and u.alive and u.position.distance_to(p) < r:
			return "Alan dolu"
	return ""
