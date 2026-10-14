class_name Sandbox extends CanvasLayer
# Sandbox: sınırsız ikmal, birlik sınırı yok, imleçte birim/yapı oluşturma, geliştirici
# komutları (konsol: ` / F10). Yenilikleri test etmek için.

var hud: Hud
var panel: PanelContainer
var list: VBoxContainer
var console: LineEdit
var log_lbl: Label
var team_btn: Button
var spawn_team := 0
var pending := ""          # imleçte yerleştirilecek: "p:<üretim>", "s:<rol>", "b:<yapı>", "fx:<tip>"
var god := false
var instant := true
var shown := true
var _log: Array = []

const ROLES := ["rifle", "mg", "at", "medic", "sniper", "engineer", "mortar", "drone", "leader"]
const FX := ["boom_s", "boom_m", "boom_l", "arty", "smoke"]

func _ready() -> void:
	layer = 6
	hud = G.hud
	var root := Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = hud.root.theme
	root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(root)
	panel = PanelContainer.new()
	panel.anchor_left = 1.0
	panel.anchor_right = 1.0
	panel.offset_left = -314
	panel.offset_right = -14
	panel.offset_top = 64
	panel.custom_minimum_size = Vector2(300, 0)
	panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(panel)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 4)
	panel.add_child(v)
	hud._label(v, "SANDBOX", 20, Hud.AMBER, hud.font_b)
	hud._label(v, "` / F10: gizle · sol tık: yerleştir · sağ tık: iptal", 12, Hud.DIM, hud.font_m)
	var row := HBoxContainer.new()
	v.add_child(row)
	team_btn = _btn(row, "", func(): _set_team(1 - spawn_team))
	_btn(row, "SİS", func(): run("fog"))
	_btn(row, "TANRI", func(): run("god"))
	_btn(row, "YZ", func(): run("ai"))
	var row2 := HBoxContainer.new()
	v.add_child(row2)
	for sp in [0.25, 1.0, 2.0, 4.0]:
		var s: float = sp
		_btn(row2, "×%s" % str(s), func(): run("speed %s" % s))
	_btn(row2, "TEMİZLE", func(): run("clear"))
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	_section("PİYADE TİMLERİ")
	for id in ["rifle_squad", "mg_team", "at_squad", "medic_team", "sniper_team", "engineer_squad", "mortar_team", "drone_team"]:
		_spawn_btn("p:" + id, I18n.s(Building.PDEF[id]["title"]))
	_section("TEK ASKER")
	for r in ROLES:
		_spawn_btn("s:" + r, I18n.s(Soldier.ROLE_TITLE.get(r, r)))
	_section("ARAÇLAR")
	for id in ["technical", "apc", "ifv", "aa", "tank", "arty", "heli", "transport"]:
		_spawn_btn("p:" + id, I18n.s(Building.PDEF[id]["title"]))
	_spawn_btn("v:truck", I18n.s("İkmal Kamyonu"))
	_section("YAPILAR (anında)")
	for id in ["fob", "barracks", "factory", "helipad", "hospital", "mgnest", "tower", "trap"]:
		_spawn_btn("b:" + id, I18n.s(Building.BDEF[id]["title"]))
	_section("EFEKTLER")
	for f in FX:
		_spawn_btn("fx:" + f, {"boom_s": "El bombası", "boom_m": "Tank mermisi", "boom_l": "Büyük patlama", "arty": "Topçu atışı", "smoke": "Sis perdesi"}[f])
	console = LineEdit.new()
	console.placeholder_text = I18n.s("komut: help")
	console.text_submitted.connect(func(t):
		run(t)
		console.text = ""
		console.release_focus())
	v.add_child(console)
	log_lbl = hud._label(v, "", 12, Hud.TXT, hud.font_m)
	log_lbl.autowrap_mode = TextServer.AUTOWRAP_WORD
	log_lbl.custom_minimum_size = Vector2(280, 0)
	_set_team(0)
	_print("help: komut listesi")

func _btn(parent: Control, t: String, cb: Callable) -> Button:
	var b := Button.new()
	b.text = I18n.s(t)
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_size_override("font_size", 13)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	b.pressed.connect(cb)
	parent.add_child(b)
	return b

func _section(t: String) -> void:
	hud._label(list, t, 12, Hud.AMBER, hud.font_b)

func _spawn_btn(id: String, title: String) -> void:
	var b := _btn(list, "", func():
		pending = "" if pending == id else id
		Sfx.play2d("ui_click", -10.0))
	b.text = title
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("id", id)

func _set_team(t: int) -> void:
	spawn_team = t
	team_btn.text = I18n.s("MAVİ" if t == 0 else "KIZIL")
	team_btn.add_theme_color_override("font_color", G.TEAM_COL[t])

func _process(_dt: float) -> void:
	if not G.running:
		return
	for t in 2:
		G.supply[t] = maxf(G.supply[t], 99999.0)
	if god:
		for u in G.units:
			if is_instance_valid(u) and u.alive and u.team == G.player_team and not (u is Building):
				u.hp = u.max_hp
				if u is Soldier:
					u.suppression = 0.0
	for b in list.get_children():
		if b is Button:
			b.button_pressed = b.get_meta("id", "") == pending
			b.toggle_mode = true

func over_ui() -> bool:
	return shown and panel.get_global_rect().has_point(panel.get_viewport().get_mouse_position())

func _unhandled_input(e: InputEvent) -> void:
	if not G.running:
		return
	if e is InputEventKey and e.pressed and not e.echo:
		var k := (e as InputEventKey).keycode
		if k == KEY_QUOTELEFT or k == KEY_F10:
			shown = not shown
			panel.visible = shown
			get_viewport().set_input_as_handled()
			return
	if pending == "" or not (e is InputEventMouseButton) or not e.pressed:
		return
	var mb := e as InputEventMouseButton
	if mb.button_index == MOUSE_BUTTON_RIGHT:
		pending = ""
		get_viewport().set_input_as_handled()
	elif mb.button_index == MOUSE_BUTTON_LEFT and not over_ui() and not hud.mouse_over_ui():
		place(pending, G.cam.mouse_ground(mb.position))
		if not mb.shift_pressed:
			pending = ""
		get_viewport().set_input_as_handled()

func place(id: String, p: Vector3) -> void:
	var kind := id.get_slice(":", 0)
	var what := id.get_slice(":", 1)
	var t := spawn_team
	match kind:
		"p":
			var P: Dictionary = Building.PDEF[what]
			if P.has("vehicle"):
				G.main.spawn_vehicle(t, P["vehicle"], G.grid.nearest_free(p, Grid.M_HEAVY), randf() * TAU)
			else:
				var sq := Squad.new(t, P["title"])
				G.squads.append(sq)
				var units: Array = P["units"]
				for i in units.size():
					G.main.spawn_soldier(t, units[i], G.grid.nearest_free(p + Vector3((i % 3 - 1) * 1.4, 0, (i / 3) * 1.4), Grid.M_INF), sq)
		"s":
			var sq2 := Squad.new(t, "T")
			G.squads.append(sq2)
			G.main.spawn_soldier(t, what, G.grid.nearest_free(p, Grid.M_INF), sq2)
		"v":
			G.main.spawn_vehicle(t, what, G.grid.nearest_free(p, Grid.M_HEAVY), randf() * TAU)
		"b":
			var b: Building = G.main.place_building(t, what, G.on_ground(p), 0.0)
			if instant:
				b.add_work(99999.0)
		"fx":
			match what:
				"boom_s":
					G.explode(p, 4.2, 120.0, "grenade", 1 - G.player_team, null)
				"boom_m":
					G.explode(p, 4.5, 130.0, "shell", 1 - G.player_team, null)
				"boom_l":
					G.explode(p, 8.0, 400.0, "big", 1 - G.player_team, null)
				"arty":
					for i in 6:
						G.bal.artillery(p + Vector3(-60, 40, -60), p + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), 1 - G.player_team, null)
				"smoke":
					for i in 5:
						var q := p + Vector3((i - 2) * 3.5, 0, randf_range(-1, 1))
						G.fx.smoke_screen(q, 25.0)
						G.add_smoke(q, 4.0, 26.0)
	Sfx.play2d("ui_place", -8.0)

# ------------------------------------------------------------ konsol
func run(cmd: String) -> void:
	var a := cmd.strip_edges().split(" ", false)
	if a.is_empty():
		return
	var sel: Array = G.player.selected
	match a[0].to_lower():
		"help":
			_print("spawn <id> [n] [blue|red] · supply <n> · god · fog · ai · speed <x> · kill · heal · build · clear · team · boom <r> · rank")
		"spawn":
			if a.size() < 2:
				return
			var n := int(a[2]) if a.size() > 2 else 1
			if a.size() > 3:
				_set_team(1 if a[3].begins_with("r") or a[3].begins_with("k") else 0)
			var id: String = a[1]
			var key := "p:" + id if Building.PDEF.has(id) else ("b:" + id if Building.BDEF.has(id) else ("s:" + id if id in ROLES else ("v:" + id)))
			var p := G.cam.mouse_ground(get_viewport().get_mouse_position())
			for i in n:
				place(key, p + Vector3((i % 4) * 6.0, 0, (i / 4) * 6.0))
			_print("spawn %s ×%d" % [id, n])
		"supply":
			G.supply[G.player_team] = float(a[1]) if a.size() > 1 else 99999.0
		"god":
			god = not god
			_print("god: %s" % god)
		"fog":
			G.fog_off = not G.fog_off
			_print("fog: %s" % ("kapalı" if G.fog_off else "açık"))
		"ai":
			var on := G.ais.is_empty()
			if on:
				var ai := AICmd.new(1 - G.player_team)
				G.main.add_child(ai)
				G.ais.append(ai)
			else:
				for x in G.ais:
					if is_instance_valid(x):
						x.queue_free()
				G.ais.clear()
			_print("ai: %s" % on)
		"speed":
			Engine.time_scale = clampf(float(a[1]) if a.size() > 1 else 1.0, 0.1, 8.0)
		"kill":
			for u in sel.duplicate():
				if is_instance_valid(u) and u.alive:
					if u is Soldier:
						u.die(null)
					elif u is Vehicle or u is Building:
						u.destroy(null)
		"heal":
			for u in sel:
				if is_instance_valid(u) and u.alive:
					u.hp = u.max_hp
					if u is Soldier and u.incapacitated():
						u.revive()
		"build":
			instant = not instant
			for u in G.units:
				if is_instance_valid(u) and u is Building and not u.done:
					u.add_work(99999.0)
			_print("anında inşa: %s" % instant)
		"rank":
			for u in sel:
				if u is Soldier:
					u.add_xp(200)
		"clear":
			for u in G.units.duplicate():
				if is_instance_valid(u) and (u is Soldier or u is Vehicle) and u.team != G.player_team:
					u.queue_free()
			_print("düşman birlikleri silindi")
		"team":
			G.player.clear_sel()
			G.player_team = 1 - G.player_team
			G.player.team = G.player_team
			_print("kontrol: %s" % ("MAVİ" if G.player_team == 0 else "KIZIL"))
		"boom":
			var r := float(a[1]) if a.size() > 1 else 5.0
			G.explode(G.cam.mouse_ground(get_viewport().get_mouse_position()), r, r * 40.0, "big", 1 - G.player_team, null)
		_:
			_print("? " + cmd)

func _print(t: String) -> void:
	_log.append(t)
	while _log.size() > 4:
		_log.pop_front()
	log_lbl.text = "\n".join(_log)
