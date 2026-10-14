class_name MapEditor extends CanvasLayer
# Harita editörü: zemin türü, yol / nehir çizimi, yapı ve doğa yerleştirme, karargâh ve üs noktaları.
# Haritalar user://maps/<ad>.json olarak kaydedilir; "ÖZEL HARİTALAR" menüsünden oynanır.

const DIR := "user://maps/"
const TOOLS := [
	["sec", "SİL", "Sağ tık: en yakın nesneyi sil"],
	["road", "YOL", "Tıkla: nokta ekle · Enter / sağ tık: bitir"],
	["river", "NEHİR", "Tıkla: nokta ekle · Enter / sağ tık: bitir"],
	["house_flat", "DÜZ ÇATILI EV", "R: döndür · 1-3: boyut"],
	["house_pitched", "KİREMİT ÇATILI EV", "R: döndür · 1-3: boyut"],
	["compound", "AVLU DUVARI", "Tıkla: yerleştir · R: kapıyı çevir"],
	["wall", "TAŞ DUVAR", "İki tık: başlangıç / bitiş"],
	["fence", "ÇİT", "İki tık: başlangıç / bitiş"],
	["ruin", "YIKINTI", "Tıkla: rastgele yıkıntı"],
	["palm", "PALMİYE", "Shift: fırça"],
	["tree", "AĞAÇ", "Shift: fırça"],
	["pine", "ÇAM", "Shift: fırça"],
	["bush", "ÇALI", "Shift: fırça"],
	["rock", "KAYA", "Shift: fırça"],
	["hay", "SAMAN", "Tıkla"],
	["car", "ARABA", "R: döndür"],
	["canopy", "TENTE", "Tıkla"],
	["pole", "DİREK", "Tıkla"],
	["crater", "KRATER", "Tıkla"],
	["patch", "ÇİM / KAR YAMASI", "Tıkla"],
	["hq0", "MÜTTEFİK KARARGÂHI", "Müttefiklerin başlangıcı"],
	["hq1", "MİHVER KARARGÂHI", "Mihverin başlangıcı"],
	["fob", "İLERİ ÜS NOKTASI", "Yapay zekânın üs kuracağı yer · sağ tık: sil"],
]

var data: Dictionary = {}
var tool := "house_flat"
var pts: Array = []
var rot90 := false
var size_i := 1
var root: Control
var panel: PanelContainer
var name_edit: LineEdit
var info: Label
var list_box: Control
var hud: Hud
var dirty := false
var mode := "map"
var team := 0
var grid: GridContainer
var rules: VBoxContainer

func open(d: Dictionary) -> void:
	data = d
	hud = G.hud
	_build_ui()

func _build_ui() -> void:
	layer = 6
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = hud.root.theme
	add_child(root)
	var ov := EdOverlay.new()
	ov.ed = self
	ov.set_anchors_preset(Control.PRESET_FULL_RECT)
	ov.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(ov)
	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.anchor_bottom = 1.0
	panel.offset_left = -330
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 6)
	panel.add_child(v)
	hud._label(v, "HARİTA EDİTÖRÜ", 30, Hud.AMBER, hud.font_b)
	var nh := HBoxContainer.new()
	v.add_child(nh)
	name_edit = LineEdit.new()
	name_edit.text = String(data.get("name", "yeni_harita"))
	name_edit.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_edit.placeholder_text = "harita adı"
	nh.add_child(name_edit)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 4)
	v.add_child(bh)
	_btn(bh, "KAYDET", func(): save())
	_btn(bh, "YÜKLE", func(): _show_list())
	_btn(bh, "TEST ET", func(): _test())
	_btn(bh, "ÇIKIŞ", func(): _exit())
	var biome_row := HBoxContainer.new()
	biome_row.add_theme_constant_override("separation", 4)
	v.add_child(biome_row)
	for b in [["desert", "ÇÖL"], ["green", "YEŞİL"], ["winter", "KIŞ"]]:
		var bid: String = b[0]
		var bb := _btn(biome_row, b[1], func(): _set_biome(bid))
		bb.toggle_mode = true
		bb.button_pressed = data.get("biome", "desert") == bid
	var mr := HBoxContainer.new()
	mr.add_theme_constant_override("separation", 4)
	v.add_child(mr)
	var bm := _btn(mr, "HARİTA", func(): _set_mode("map"))
	bm.toggle_mode = true
	bm.button_pressed = mode == "map"
	bm.set_meta("mode", "map")
	var bs := _btn(mr, "SENARYO", func(): _set_mode("scen"))
	bs.toggle_mode = true
	bs.button_pressed = mode == "scen"
	bs.set_meta("mode", "scen")
	mr.set_meta("is_mode", true)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	var sv := VBoxContainer.new()
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sc.add_child(sv)
	rules = VBoxContainer.new()
	rules.add_theme_constant_override("separation", 4)
	sv.add_child(rules)
	grid = GridContainer.new()
	grid.columns = 2
	grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	grid.add_theme_constant_override("h_separation", 4)
	grid.add_theme_constant_override("v_separation", 4)
	sv.add_child(grid)
	_fill_tools()
	info = hud._label(v, "", 14, Hud.DIM, hud.font_m)
	info.autowrap_mode = TextServer.AUTOWRAP_WORD
	info.custom_minimum_size = Vector2(300, 60)
	_update_info()

func _btn(parent: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = t
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.add_theme_font_override("font", hud.font_b)
	b.add_theme_font_size_override("font_size", 15)
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _tool_list() -> Array:
	if mode == "map":
		return TOOLS
	var out: Array = [["sec", "SİL", "Sağ tık: en yakın birliği sil"], ["zone", "HEDEF BÖLGE", "Bölgeyi tut koşulu için nokta"]]
	for id in Main.SCEN_UNITS:
		out.append([id, Main.SCEN_UNITS[id], "Tıkla: yerleştir · R: 90° döndür"])
	return out

func _fill_tools() -> void:
	for c in grid.get_children():
		c.queue_free()
	for c in rules.get_children():
		c.queue_free()
	if mode == "scen":
		_build_rules()
	for t in _tool_list():
		var tid: String = t[0]
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.button_pressed = tid == tool
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 34)
		b.add_theme_font_size_override("font_size", 13)
		b.set_meta("tool", tid)
		b.pressed.connect(func(): _set_tool(tid, grid))
		grid.add_child(b)

func _set_mode(m: String) -> void:
	mode = m
	tool = "house_flat" if m == "map" else "rifle_squad"
	pts.clear()
	for c in panel.get_child(0).get_children():
		if c is HBoxContainer and c.has_meta("is_mode"):
			for b in c.get_children():
				b.button_pressed = b.get_meta("mode") == m
	_fill_tools()
	_update_info()

func _scen() -> Dictionary:
	if not data.has("scenario"):
		data["scenario"] = {"enabled": true, "units": [], "supply": [650, 650], "ai": [false, true], "hq": [true, true], "win": "bases", "time": 600, "zone": [128, 128], "brief": ""}
	return data["scenario"]

func _build_rules() -> void:
	var sc := _scen()
	var tr := HBoxContainer.new()
	tr.add_theme_constant_override("separation", 4)
	rules.add_child(tr)
	for t in 2:
		var tt := t
		var b := _btn(tr, ["MÜTTEFİKLER", "MİHVER"][t], func(): _set_team(tt, tr))
		b.toggle_mode = true
		b.button_pressed = team == t
		b.add_theme_color_override("font_color", G.TEAM_COL[t])
	var en := CheckBox.new()
	en.text = "Senaryo etkin (kapalıysa normal çatışma)"
	en.button_pressed = bool(sc.get("enabled", true))
	en.toggled.connect(func(v): sc["enabled"] = v)
	rules.add_child(en)
	var wr := HBoxContainer.new()
	rules.add_child(wr)
	hud._label(wr, "ZAFER:", 14, Hud.DIM, hud.font_m)
	var ob := OptionButton.new()
	var wins := ["bases", "annihilate", "survive", "hold"]
	for w in ["Üsleri yok et", "Tüm düşmanı yok et", "Süre boyunca dayan", "Bölgeyi tut"]:
		ob.add_item(w)
	ob.selected = maxi(0, wins.find(String(sc.get("win", "bases"))))
	ob.item_selected.connect(func(i): sc["win"] = wins[i])
	ob.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	wr.add_child(ob)
	_spin(rules, "SÜRE (sn)", float(sc.get("time", 600)), 30, 3600, func(v): sc["time"] = v)
	var sup: Array = sc.get("supply", [650, 650])
	_spin(rules, "MÜTTEFİK İKMALİ", float(sup[0]), 0, 20000, func(v): sup[0] = v)
	_spin(rules, "MİHVER İKMALİ", float(sup[1]), 0, 20000, func(v): sup[1] = v)
	var ai: Array = sc.get("ai", [false, true])
	var hq: Array = sc.get("hq", [true, true])
	var cr := GridContainer.new()
	cr.columns = 2
	rules.add_child(cr)
	for t in 2:
		var tt := t
		var c1 := CheckBox.new()
		c1.text = ["Müttefik karargâhı", "Mihver karargâhı"][t]
		c1.button_pressed = bool(hq[t])
		c1.toggled.connect(func(v): hq[tt] = v)
		cr.add_child(c1)
	var c2 := CheckBox.new()
	c2.text = "Mihver: yapay zekâ"
	c2.button_pressed = bool(ai[1])
	c2.toggled.connect(func(v): ai[1] = v)
	cr.add_child(c2)
	var br := LineEdit.new()
	br.placeholder_text = "Brifing metni (oyun başında görünür)"
	br.text = String(sc.get("brief", ""))
	br.text_changed.connect(func(t): sc["brief"] = t)
	rules.add_child(br)
	hud._label(rules, "BİRLİK YERLEŞTİR", 15, Hud.AMBER, hud.font_b)

func _spin(parent: Control, label: String, val: float, lo: float, hi: float, cb: Callable) -> void:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var l := hud._label(h, label, 14, Hud.DIM, hud.font_m)
	l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var sp := SpinBox.new()
	sp.min_value = lo
	sp.max_value = hi
	sp.step = 10
	sp.value = val
	sp.value_changed.connect(cb)
	h.add_child(sp)

func _set_team(t: int, row: Control) -> void:
	team = t
	for i in row.get_child_count():
		row.get_child(i).button_pressed = i == t

func _set_tool(t: String, g: Control) -> void:
	tool = t
	pts.clear()
	for b in g.get_children():
		b.button_pressed = b.get_meta("tool") == t
	_update_info()
	Sfx.play2d("ui_click", -10.0)

func _update_info() -> void:
	var hint := ""
	for t in TOOLS:
		if t[0] == tool:
			hint = t[2]
	for t in _tool_list():
		if t[0] == tool:
			hint = t[2]
	var nu: int = data.get("scenario", {}).get("units", []).size()
	info.text = "%s\nBoyut: %s   Döndür: %s\nOrta tuş / WASD: kamera · Tekerlek: yakınlaştır\nİşlem: %d   Senaryo birliği: %d" % [hint, ["KÜÇÜK", "ORTA", "BÜYÜK"][size_i], "EVET" if rot90 else "HAYIR", data.get("ops", []).size(), nu]

func over_ui() -> bool:
	var m := root.get_viewport().get_mouse_position()
	if panel.get_global_rect().has_point(m):
		return true
	if list_box and is_instance_valid(list_box) and list_box.get_global_rect().has_point(m):
		return true
	return false

# ------------------------------------------------------------ girdi
func _unhandled_input(e: InputEvent) -> void:
	if over_ui():
		return
	if e is InputEventMouseButton and e.pressed:
		var mb := e as InputEventMouseButton
		var gp := G.cam.mouse_ground(mb.position)
		gp = Vector3(snappedf(clampf(gp.x, 2, G.MAP - 2), 0.5), 0, snappedf(clampf(gp.z, 2, G.MAP - 2), 0.5))
		if mb.button_index == MOUSE_BUTTON_LEFT:
			_click(gp, mb.shift_pressed)
			get_viewport().set_input_as_handled()
		elif mb.button_index == MOUSE_BUTTON_RIGHT:
			if tool in ["road", "river"] and pts.size() >= 2:
				_finish_line()
			elif not pts.is_empty():
				pts.clear()
			else:
				_delete_near(gp)
			get_viewport().set_input_as_handled()
	elif e is InputEventKey and e.pressed and not e.echo:
		var k := e as InputEventKey
		if name_edit.has_focus():
			return
		match k.keycode:
			KEY_R:
				rot90 = not rot90
			KEY_1, KEY_2, KEY_3:
				size_i = k.keycode - KEY_1
			KEY_ENTER, KEY_KP_ENTER:
				if pts.size() >= 2:
					_finish_line()
			KEY_ESCAPE:
				pts.clear()
		_update_info()

func _click(p: Vector3, brush: bool) -> void:
	if mode == "scen":
		_scen_click(p)
		return
	var mg: MapGen = G.mapgen
	var r := G.rng
	match tool:
		"road", "river":
			pts.append(p)
			return
		"wall", "fence":
			if pts.is_empty():
				pts.append(p)
				return
			var a: Vector3 = pts[0]
			pts.clear()
			if a.distance_to(p) < 1.0:
				return
			if tool == "wall":
				_op(func(): mg.wall(a, p, [2, 3, 5][size_i], 0.0))
			else:
				_op(func(): mg.fence(a, p))
		"house_flat", "house_pitched":
			var w: float = [6.0, 8.0, 10.0][size_i]
			var d: float = [5.0, 6.0, 7.0][size_i]
			if tool == "house_flat":
				_op(func(): mg.house_flat(p, w, d, [5, 6, 7][size_i], rot90))
			else:
				var snow := String(data.get("biome", "")) == "winter"
				var roof: Color = [Color(0.52, 0.18, 0.12), Color(0.22, 0.38, 0.26), Color(0.42, 0.3, 0.18), Color(0.4, 0.42, 0.45)][r.randi() % 4]
				_op(func(): mg.house_pitched(p, w, d, rot90, MapGen.WHITE if not snow else Color(0.88, 0.85, 0.72), roof, snow))
		"compound":
			var cw: float = [12.0, 15.0, 19.0][size_i]
			var cd: float = [10.0, 13.0, 15.0][size_i]
			_op(func(): mg.compound(p, cw if not rot90 else cd, cd if not rot90 else cw, 4, 0 if not rot90 else 1))
		"ruin":
			_op(func(): mg.ruin_cluster(p))
		"palm", "tree", "pine", "bush", "rock":
			var n := 7 if brush else 1
			var tk := tool
			_op(func(): _nature(tk, p, n))
		"hay":
			_op(func(): mg.p_hay(p))
		"car":
			_op(func(): mg.p_car(p, PI * 0.5 if rot90 else 0.0))
		"canopy":
			_op(func(): mg.p_canopy(p, 0.0))
		"pole":
			_op(func(): mg.p_pole(p, false))
		"crater":
			_op(func(): mg.crater(p, [2.5, 3.5, 5.0][size_i]))
		"patch":
			_op(func(): mg.patch(p, [5.0, 9.0, 14.0][size_i], 1.0))
		"hq0", "hq1":
			var hq: Array = data.get("hq", [[214, 214], [42, 42]])
			hq[0 if tool == "hq0" else 1] = MapGen.vv(p)
			data["hq"] = hq
			dirty = true
		"fob":
			var f: Array = data.get("fobs", [])
			f.append(MapGen.vv(p))
			data["fobs"] = f
			dirty = true
	Sfx.play2d("ui_place", -8.0)

func _nature(tk: String, p: Vector3, n: int) -> void:
	var mg: MapGen = G.mapgen
	var r := G.rng
	for i in n:
		var q := p if i == 0 else p + Vector3(r.randf_range(-7, 7), 0, r.randf_range(-7, 7))
		match tk:
			"palm":
				mg.p_palm(q)
			"tree":
				mg.p_tree(q)
			"pine":
				mg.p_pine(q)
			"bush":
				mg.p_bush(q, r.randf() < 0.3)
			"rock":
				mg.p_rock(q, r.randf_range(0.6, 1.4))

func _scen_click(p: Vector3) -> void:
	var sc := _scen()
	if tool == "zone":
		sc["zone"] = MapGen.vv(p)
		return
	if tool == "sec":
		return
	var yaw := Soldier._yaw_of(G.hq_pos[1 - team] - G.hq_pos[team])
	if rot90:
		yaw += PI * 0.5
	var e := {"team": team, "id": tool, "p": MapGen.vv(p), "r": snappedf(yaw, 0.01)}
	var arr: Array = sc.get("units", [])
	arr.append(e)
	sc["units"] = arr
	G.main.spawn_scenario_units({"units": [e]}, true)
	Sfx.play2d("ui_place", -8.0)
	_update_info()

func _finish_line() -> void:
	var mg: MapGen = G.mapgen
	var line := pts.duplicate()
	pts.clear()
	if tool == "road":
		_op(func(): mg.road(line, [4.5, 6.0, 7.5][size_i]))
	else:
		var si := size_i
		_op(func(): _river(line, si))
		_rebuild()
		return
	# yol nehri keserse köprü
	if not mg.rivers.is_empty():
		_op(func(): mg.auto_bridges())

func _river(line: Array, si: int) -> void:
	var mg: MapGen = G.mapgen
	var rp := mg.river(line, [8.0, 11.0, 15.0][si], 1.8)
	mg.p_reeds_along(rp, [4.0, 5.5, 7.5][si])

# işlemi çalıştır ve dünyaya anında işle
func _op(f: Callable) -> void:
	var mg: MapGen = G.mapgen
	var from := G.blocks.bpos.size()
	var n0 := mg.ops.size()
	f.call()
	if G.blocks.bpos.size() > from:
		G.blocks.commit_runtime(from)
	G.grid.flush_nav()
	data["ops"] = mg.ops.duplicate(true)
	dirty = true
	_update_info()
	var _n := n0

func _delete_near(p: Vector3) -> void:
	if mode == "scen":
		var sc := _scen()
		var arr: Array = sc.get("units", [])
		var bi := -1
		var bd2 := 6.0
		for i in arr.size():
			var d := MapGen.v3(arr[i]["p"]).distance_to(p)
			if d < bd2:
				bd2 = d
				bi = i
		if bi >= 0:
			arr.remove_at(bi)
			_rebuild()
		return
	if tool == "fob" or tool == "sec":
		var f: Array = data.get("fobs", [])
		for i in f.size():
			if MapGen.v3(f[i]).distance_to(p) < 6.0:
				f.remove_at(i)
				data["fobs"] = f
				return
	var ops: Array = data.get("ops", [])
	var best := -1
	var bd := 4.0
	for i in ops.size():
		var op: Dictionary = ops[i]
		var q := _op_pos(op)
		if q == Vector3.INF:
			continue
		var d := q.distance_to(p)
		if d < bd:
			bd = d
			best = i
	if best < 0:
		return
	ops.remove_at(best)
	data["ops"] = ops
	Sfx.play2d("ui_click", -6.0)
	_rebuild()

func _op_pos(op: Dictionary) -> Vector3:
	if op.has("p"):
		return MapGen.v3(op["p"])
	if op.has("a") and op.has("b"):
		return (MapGen.v3(op["a"]) + MapGen.v3(op["b"])) * 0.5
	if op.has("pts"):
		var best := Vector3.INF
		var arr: Array = op["pts"]
		if arr.size() > 0:
			best = MapGen.v3(arr[arr.size() / 2])
		return best
	return Vector3.INF

func _rebuild() -> void:
	var focus: Vector3 = G.cam.target_focus
	var size: float = G.cam.target_size
	var m := mode
	var t := team
	var tl := tool
	G.main.open_editor(data, false)
	G.cam.jump_to(focus, true)
	G.cam.target_size = size
	var ne: MapEditor = G.main.editor
	ne.team = t
	if m != "map":
		ne._set_mode(m)
	ne.tool = tl
	ne._fill_tools()

func _set_biome(b: String) -> void:
	data["biome"] = b
	_rebuild()

# ------------------------------------------------------------ kaydet / yükle / test
func save() -> void:
	var nm := name_edit.text.strip_edges().replace("/", "_").replace("\\\\", "_")
	if nm == "":
		nm = "yeni_harita"
	data["name"] = nm
	data["v"] = 1
	DirAccess.make_dir_recursive_absolute(DIR)
	var f := FileAccess.open(DIR + nm + ".json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(data))
		dirty = false
		hud.promoted_text("KAYDEDİLDİ", nm.to_upper())
		Sfx.play2d("ui_done", -4.0)

static func list_maps() -> Array:
	var out: Array = []
	var d := DirAccess.open(DIR)
	if d == null:
		return out
	for fn in d.get_files():
		if fn.ends_with(".json"):
			out.append(fn.get_basename())
	out.sort()
	return out

static func load_map(nm: String) -> Dictionary:
	var f := FileAccess.open(DIR + nm + ".json", FileAccess.READ)
	if f == null:
		return {}
	var d = JSON.parse_string(f.get_as_text())
	return d if d is Dictionary else {}

func _show_list() -> void:
	if list_box and is_instance_valid(list_box):
		list_box.queue_free()
		list_box = null
		return
	var pc := PanelContainer.new()
	pc.position = Vector2(root.get_viewport().get_visible_rect().size.x - 640, 120)
	pc.custom_minimum_size = Vector2(290, 0)
	root.add_child(pc)
	list_box = pc
	var v := VBoxContainer.new()
	pc.add_child(v)
	hud._label(v, "KAYITLI HARİTALAR", 18, Hud.AMBER, hud.font_b)
	var maps := list_maps()
	if maps.is_empty():
		hud._label(v, "Henüz kayıt yok", 14, Hud.DIM, hud.font_m)
	for m in maps:
		var mn: String = m
		_btn(v, mn.to_upper(), func(): _open_saved(mn))
	hud._label(v, "Hazır haritadan başla:", 14, Hud.DIM, hud.font_m)
	for id in MapGen.MAPS:
		var mid: String = id
		_btn(v, MapGen.MAPS[id]["title"].to_upper(), func(): G.main.open_editor_from_builtin(mid))

func _open_saved(mn: String) -> void:
	var d := load_map(mn)
	if not d.is_empty():
		G.main.open_editor(d, true)

func _test() -> void:
	G.main.start_game("", data)

func _exit() -> void:
	G.main.to_menu()

# ------------------------------------------------------------ çizim
class EdOverlay extends Control:
	var ed: MapEditor

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if ed == null or G.cam == null:
			return
		var f: Font = ed.hud.font_b
		var m := get_viewport().get_mouse_position()
		var gp := G.cam.mouse_ground(m)
		# karargâh ve üs noktaları
		var hq: Array = ed.data.get("hq", [[214, 214], [42, 42]])
		for t in 2:
			var p := MapGen.v3(hq[t])
			_ring(p, 13.0, G.TEAM_COL[t], 3.0)
			draw_string(f, G.cam.screen(p) + Vector2(-50, -10), ["MÜTTEFİK KARARGÂHI", "MİHVER KARARGÂHI"][t], HORIZONTAL_ALIGNMENT_CENTER, 100, 16, G.TEAM_COL[t])
		for fp in ed.data.get("fobs", []):
			var p := MapGen.v3(fp)
			_ring(p, 7.0, Hud.AMBER, 2.0)
			draw_string(f, G.cam.screen(p) + Vector2(-40, -6), "ÜS NOKTASI", HORIZONTAL_ALIGNMENT_CENTER, 80, 13, Hud.AMBER)
		var scd: Dictionary = ed.data.get("scenario", {})
		if not scd.is_empty() and String(scd.get("win", "")) == "hold":
			var zp := MapGen.v3(scd.get("zone", [128, 128]))
			_ring(zp, 14.0, Color(1, 1, 1, 0.9), 3.0)
			draw_string(f, G.cam.screen(zp) + Vector2(-50, -8), "HEDEF BÖLGE", HORIZONTAL_ALIGNMENT_CENTER, 100, 15, Color(1, 1, 1))
		# çizilmekte olan çizgi
		var prev := Vector2.INF
		for q in ed.pts:
			var s := G.cam.screen(q)
			draw_circle(s, 5, Color(1, 1, 1))
			if prev != Vector2.INF:
				draw_line(prev, s, Color(1, 1, 1, 0.9), 2.0)
			prev = s
		if prev != Vector2.INF:
			draw_line(prev, m, Color(1, 1, 1, 0.5), 1.5)
		# imleç
		var r: float = {"house_flat": 5.0, "house_pitched": 5.0, "compound": 8.0, "ruin": 3.0, "crater": 2.5, "patch": 8.0, "hq0": 13.0, "hq1": 13.0, "fob": 7.0}.get(ed.tool, 1.5)
		_ring(gp, r * ([0.8, 1.0, 1.3][ed.size_i] if ed.tool in ["house_flat", "house_pitched", "compound", "patch", "crater"] else 1.0), Color(0.5, 1.0, 0.7, 0.9), 2.0)
		var title := ""
		for t in ed._tool_list():
			if t[0] == ed.tool:
				title = t[1]
		draw_string(f, m + Vector2(18, 28), title, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))

	func _ring(p: Vector3, r: float, c: Color, w: float) -> void:
		var arr := PackedVector2Array()
		for i in 33:
			var a := TAU * i / 32.0
			arr.append(G.cam.screen(p + Vector3(cos(a) * r, 0.1, sin(a) * r)))
		draw_polyline(arr, c, w, true)
