class_name Hud extends CanvasLayer
# Arayüz: ikmal paneli, Sektör Radarı, komut paneli, uyarılar, konuşma balonları, menüler.

const AMBER := Color(1.0, 0.76, 0.32)
const TXT := Color(0.92, 0.9, 0.84)
const DIM := Color(0.62, 0.6, 0.55)
const PANEL := Color(0.07, 0.07, 0.065, 0.86)

var font: Font
var font_b: Font
var root: Control
var overlay: Control
var top_panel: PanelContainer
var lbl_supply: Label
var lbl_cap: Label
var lbl_time: Label
var radar: Control
var bottom: PanelContainer
var info_box: VBoxContainer
var btn_grid: GridContainer
var tabs: HBoxContainer
var alerts: VBoxContainer
var menu: Control
var pause_menu: Control
var over_menu: Control
var tooltip: Label
var build_tab := "base"
var _sel_sig := ""
var _ui_rects: Array = []
var _radar_drag := false
var _sweep := 0.0
var _toast: Array = []

func _ready() -> void:
	layer = 5
	font = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	font_b = load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	root = Control.new()
	root.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.theme = _theme()
	add_child(root)
	overlay = Overlay.new()
	overlay.hud = self
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	_build_top()
	_build_radar()
	_build_bottom()
	alerts = VBoxContainer.new()
	alerts.position = Vector2(18, 96)
	alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alerts.add_theme_constant_override("separation", 3)
	root.add_child(alerts)
	tooltip = Label.new()
	tooltip.visible = false
	tooltip.add_theme_color_override("font_color", TXT)
	tooltip.add_theme_font_size_override("font_size", 17)
	var tsb := _sb(Color(0.05, 0.05, 0.05, 0.94), Color(0.6, 0.5, 0.3, 0.7))
	tsb.content_margin_left = 10
	tsb.content_margin_right = 10
	tsb.content_margin_top = 6
	tsb.content_margin_bottom = 6
	tooltip.add_theme_stylebox_override("normal", tsb)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 50
	root.add_child(tooltip)
	G.alert.connect(_on_alert)

func _theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 18
	var bn := _sb(Color(0.12, 0.12, 0.11, 0.95), Color(0.42, 0.38, 0.3, 0.8))
	var bh := _sb(Color(0.2, 0.18, 0.14, 0.98), AMBER)
	var bp := _sb(Color(0.3, 0.24, 0.12, 1.0), AMBER)
	var bd := _sb(Color(0.08, 0.08, 0.08, 0.8), Color(0.25, 0.25, 0.22, 0.6))
	for s in [bn, bh, bp, bd]:
		s.content_margin_left = 8
		s.content_margin_right = 8
		s.content_margin_top = 4
		s.content_margin_bottom = 4
	th.set_stylebox("normal", "Button", bn)
	th.set_stylebox("hover", "Button", bh)
	th.set_stylebox("pressed", "Button", bp)
	th.set_stylebox("disabled", "Button", bd)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", TXT)
	th.set_color("font_hover_color", "Button", AMBER)
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.43, 0.4))
	th.set_color("font_color", "Label", TXT)
	th.set_stylebox("panel", "PanelContainer", _sb(PANEL, Color(0.45, 0.4, 0.3, 0.55)))
	return th

func _sb(bg: Color, border: Color) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(1)
	s.set_corner_radius_all(2)
	return s

func mouse_over_ui() -> bool:
	var m := root.get_viewport().get_mouse_position()
	for c in [top_panel, radar, bottom]:
		if c.visible and c.get_global_rect().has_point(m):
			return true
	if menu and menu.visible:
		return true
	return false

# ------------------------------------------------------------ üst panel
func _build_top() -> void:
	top_panel = PanelContainer.new()
	top_panel.position = Vector2(14, 12)
	root.add_child(top_panel)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 22)
	top_panel.add_child(hb)
	lbl_supply = _stat(hb, "İKMAL")
	lbl_cap = _stat(hb, "BİRLİK")
	lbl_time = _stat(hb, "SÜRE")

func _stat(parent: Control, title: String) -> Label:
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", -4)
	parent.add_child(vb)
	var t := Label.new()
	t.text = title
	t.add_theme_font_size_override("font_size", 13)
	t.add_theme_color_override("font_color", DIM)
	vb.add_child(t)
	var v := Label.new()
	v.add_theme_font_override("font", font_b)
	v.add_theme_font_size_override("font_size", 26)
	vb.add_child(v)
	return v

# ------------------------------------------------------------ radar
func _build_radar() -> void:
	radar = Radar.new()
	radar.hud = self
	radar.custom_minimum_size = Vector2(330, 370)
	radar.size = Vector2(330, 370)
	radar.anchor_left = 1.0
	radar.anchor_right = 1.0
	radar.offset_left = -344
	radar.offset_right = -14
	radar.offset_top = 12
	radar.offset_bottom = 382
	radar.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(radar)

# ------------------------------------------------------------ alt panel
func _build_bottom() -> void:
	bottom = PanelContainer.new()
	bottom.anchor_top = 1.0
	bottom.anchor_bottom = 1.0
	bottom.anchor_left = 0.5
	bottom.anchor_right = 0.5
	bottom.offset_left = -470
	bottom.offset_right = 470
	bottom.offset_top = -168
	bottom.offset_bottom = -12
	root.add_child(bottom)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 14)
	bottom.add_child(hb)
	info_box = VBoxContainer.new()
	info_box.custom_minimum_size = Vector2(300, 0)
	info_box.add_theme_constant_override("separation", 2)
	hb.add_child(info_box)
	var sep := VSeparator.new()
	hb.add_child(sep)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	hb.add_child(right)
	tabs = HBoxContainer.new()
	right.add_child(tabs)
	btn_grid = GridContainer.new()
	btn_grid.columns = 6
	btn_grid.add_theme_constant_override("h_separation", 5)
	btn_grid.add_theme_constant_override("v_separation", 5)
	right.add_child(btn_grid)

func _clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()

func _rebuild_bottom() -> void:
	if info_box.has_meta("live"):
		info_box.remove_meta("live")
	_clear(info_box)
	_clear(btn_grid)
	_clear(tabs)
	var sel: Array = G.player.selected
	var bld: Building = null
	if sel.size() == 1 and sel[0] is Building:
		bld = sel[0]
	if bld != null:
		_info_building(bld)
		if bld.team == G.player_team and bld.done:
			for id in bld.B["prod"]:
				var P: Dictionary = Building.PDEF[id]
				_btn("%s\n%d" % [P["title"].to_upper(), P["cost"]], func(): _produce(bld, id), "%s — %d ikmal, %d sn, %d birlik" % [P["title"], P["cost"], int(P["time"]), P["cap"]])
			if not bld.queue.is_empty():
				_btn("İPTAL", func(): bld.cancel_last(), "Son siparişi iptal et (iade)")
		return
	_info_units(sel)
	# inşa sekmeleri
	for t in [["base", "ÜS YAPILARI"], ["def", "SAVUNMA"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.button_pressed = build_tab == t[0]
		var key: String = t[0]
		b.pressed.connect(func():
			build_tab = key
			_sel_sig = ""
		)
		b.add_theme_font_size_override("font_size", 15)
		tabs.add_child(b)
	var list := ["fob", "barracks", "factory", "helipad", "hospital"] if build_tab == "base" else ["sandbags", "concrete", "trench", "wire", "trap", "mgnest", "tower"]
	for bt in list:
		var B: Dictionary = Building.BDEF[bt]
		var cost_t := ("%d/m" % B["cost"]) if B.get("line", false) else str(B["cost"])
		_btn("%s\n%s" % [B["title"].to_upper(), cost_t], func(): G.player.start_place(bt), "%s — %s\n%s" % [B["title"], cost_t + " ikmal", B["desc"]])
	if not sel.is_empty():
		_btn("DUR\n[X]", func():
			for u in G.player.selected:
				u.cmd_stop(), "Birlikleri durdur")

func _produce(b: Building, id: String) -> void:
	if not b.enqueue(id):
		if G.supply[G.player_team] < Building.PDEF[id]["cost"]:
			G.say("Yetersiz ikmal", b.position, G.player_team)
		Sfx.play2d("ui_error", -6.0)
	else:
		Sfx.play2d("ui_click", -6.0)

func _btn(text: String, cb: Callable, tip := "") -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(98, 54)
	b.add_theme_font_size_override("font_size", 14)
	b.pressed.connect(cb)
	if tip != "":
		b.mouse_entered.connect(func():
			tooltip.text = tip
			tooltip.visible = true)
		b.mouse_exited.connect(func(): tooltip.visible = false)
	btn_grid.add_child(b)

func _label(parent: Control, t: String, size := 18, col := TXT, bold := false) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if bold:
		l.add_theme_font_override("font", font_b)
	parent.add_child(l)
	return l

func _info_building(b: Building) -> void:
	_label(info_box, b.title.to_upper(), 24, AMBER, true)
	var st := "İnşa ediliyor %%%d" % int(b.progress * 100) if not b.done else "Sağlam %%%d" % int(b.hp / b.max_hp * 100)
	_label(info_box, st, 17, TXT)
	_label(info_box, b.B["desc"], 14, DIM).autowrap_mode = TextServer.AUTOWRAP_WORD
	info_box.get_child(2).custom_minimum_size = Vector2(290, 0)

func _info_units(sel: Array) -> void:
	if sel.is_empty():
		_label(info_box, "BİRLİK SEÇİLMEDİ", 22, AMBER, true)
		_label(info_box, "Sol tık / sürükle: seç   Sağ tık: emir", 15, DIM)
		_label(info_box, "Ctrl+sağ: koşarak git   Ctrl+1-9: grup", 15, DIM)
		_label(info_box, "Q: piyade   E: araç   F1-F3: hız", 15, DIM)
		return
	var counts := {}
	for u in sel:
		var t: String = u.title
		counts[t] = counts.get(t, 0) + 1
	if sel.size() == 1:
		var u: Unit = sel[0]
		_label(info_box, u.title.to_upper(), 24, AMBER, true)
	else:
		_label(info_box, "%d BİRLİK" % sel.size(), 24, AMBER, true)
	var lines := []
	for k in counts:
		lines.append("%d× %s" % [counts[k], k])
	_label(info_box, ", ".join(lines), 15, TXT).autowrap_mode = TextServer.AUTOWRAP_WORD
	info_box.get_child(1).custom_minimum_size = Vector2(290, 0)

func _update_info_live() -> void:
	# tek birlik seçiliyken canlı durum satırı
	var sel: Array = G.player.selected
	if sel.size() != 1 or info_box.get_child_count() < 1:
		return
	var u = sel[0]
	if not is_instance_valid(u):
		return
	var live: Label
	if info_box.has_meta("live"):
		live = info_box.get_meta("live")
		if not is_instance_valid(live):
			info_box.remove_meta("live")
			return
	else:
		live = _label(info_box, "", 15, DIM)
		info_box.set_meta("live", live)
	if u is Soldier:
		var st = {"idle": "Beklemede", "move": "Hareket", "wounded": "YARALI — kanaması var", "dragged": "Sürükleniyor", "healing": "Tedavi ediliyor", "rescue": "Yaralıya koşuyor", "drag": "Yaralıyı sürüklüyor", "heal": "Tedavi ediyor", "build": "İnşa ediyor", "throw": "El bombası", "dazed": "Sersem", "fly": "Savruldu", "dive": "Siper alıyor"}.get(u.state, u.state)
		if u.state == "idle" and u.cover_type > 0:
			st = "Siperde"
		live.text = "Can %d/%d · Mermi %d · %s · Baskı %%%d" % [int(maxf(u.hp, 0)), int(u.max_hp), u.ammo, st, int(u.suppression)]
	elif u is Vehicle:
		live.text = "Zırh %d/%d%s" % [int(u.hp), int(u.max_hp), " · PALET KOPUK" if u.tracks_broken > 0 else ""]
	elif u is Building:
		var q := ""
		if not u.queue.is_empty():
			var it: Dictionary = u.queue[0]
			var P: Dictionary = Building.PDEF[it["id"]]
			q = "Üretim: %s %%%d%s (+%d)" % [P["title"], int(it["t"] / P["time"] * 100), " — BİRLİK SINIRI" if it.get("blocked", false) else "", u.queue.size() - 1]
		elif not u.done:
			q = "İnşa %%%d" % int(u.progress * 100)
		else:
			q = "Sağlam %%%d" % int(u.hp / u.max_hp * 100)
		live.text = q

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	_sweep += dt * 1.6
	var t := G.player_team
	var running := G.running and not G.spectate
	top_panel.visible = running
	bottom.visible = running
	radar.visible = G.running and not G.spectate
	if running:
		lbl_supply.text = str(int(G.supply[t]))
		lbl_cap.text = "%d / %d" % [G.cap_used[t], G.cap_max[t]]
		lbl_cap.add_theme_color_override("font_color", Color(1, 0.45, 0.35) if G.cap_used[t] >= G.cap_max[t] else TXT)
		var s := int(G.time)
		lbl_time.text = "%02d:%02d%s" % [s / 60, s % 60, "" if Engine.time_scale <= 1.0 else "  ×%d" % int(Engine.time_scale)]
		var sig := ""
		for u in G.player.selected:
			sig += str(u.get_instance_id()) + ","
		if G.player.selected.size() == 1 and G.player.selected[0] is Building:
			var bb: Building = G.player.selected[0]
			sig += "%s%d%d" % [bb.done, bb.queue.size(), bb.team]
		sig += build_tab
		if sig != _sel_sig:
			_sel_sig = sig
			_rebuild_bottom()
		_update_info_live()
	if tooltip.visible:
		var m := root.get_viewport().get_mouse_position()
		tooltip.position = m + Vector2(14, -tooltip.size.y - 10)
		if not bottom.get_global_rect().has_point(m):
			tooltip.visible = false
	overlay.queue_redraw()
	radar.queue_redraw()
	var i := _toast.size() - 1
	while i >= 0:
		var e: Array = _toast[i]
		e[1] -= dt / maxf(Engine.time_scale, 0.01)
		if e[1] <= 0.0:
			e[0].queue_free()
			_toast.remove_at(i)
		elif e[1] < 0.6:
			e[0].modulate.a = e[1] / 0.6
		i -= 1

func _on_alert(text: String, pos: Vector3, team: int) -> void:
	if G.spectate or team != G.player_team:
		return
	var l := Label.new()
	l.text = "▸ " + text
	l.add_theme_font_size_override("font_size", 18)
	l.add_theme_color_override("font_color", AMBER)
	l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	l.add_theme_constant_override("shadow_offset_x", 1)
	l.add_theme_constant_override("shadow_offset_y", 1)
	alerts.add_child(l)
	_toast.append([l, 5.0, pos])
	while alerts.get_child_count() > 7:
		var f := alerts.get_child(0)
		for e in _toast:
			if e[0] == f:
				_toast.erase(e)
				break
		f.free()

# ------------------------------------------------------------ menüler
func show_menu() -> void:
	if menu:
		menu.queue_free()
	menu = Control.new()
	menu.set_anchors_preset(Control.PRESET_FULL_RECT)
	root.add_child(menu)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.0)
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(shade)
	var grad := TextureRect.new()
	var gt := GradientTexture2D.new()
	var gr := Gradient.new()
	gr.set_color(0, Color(0, 0, 0, 0.82))
	gr.set_color(1, Color(0, 0, 0, 0.0))
	gt.gradient = gr
	gt.fill_from = Vector2(0, 0)
	gt.fill_to = Vector2(1, 0)
	grad.texture = gt
	grad.set_anchors_preset(Control.PRESET_LEFT_WIDE)
	grad.offset_right = 760
	grad.stretch_mode = TextureRect.STRETCH_SCALE
	grad.mouse_filter = Control.MOUSE_FILTER_IGNORE
	menu.add_child(grad)
	var vb := VBoxContainer.new()
	vb.position = Vector2(90, 150)
	vb.add_theme_constant_override("separation", 8)
	menu.add_child(vb)
	var t := _label(vb, "MEVZİ", 120, Color(0.97, 0.94, 0.86), true)
	t.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.6))
	t.add_theme_constant_override("shadow_offset_y", 4)
	_label(vb, "MODERN SAVAŞ · GERÇEK SİPER · İKMAL HATLARI", 22, AMBER)
	var spacer := Control.new()
	spacer.custom_minimum_size = Vector2(0, 40)
	vb.add_child(spacer)
	for id in MapGen.MAPS:
		var mid: String = id
		_menu_btn(vb, MapGen.MAPS[id]["title"].to_upper(), func(): G.main.start_game(mid))
	var diff := Button.new()
	diff.custom_minimum_size = Vector2(360, 50)
	diff.add_theme_font_size_override("font_size", 22)
	var names := ["ZORLUK: KOLAY", "ZORLUK: NORMAL", "ZORLUK: ZOR"]
	diff.text = names[G.difficulty]
	diff.alignment = HORIZONTAL_ALIGNMENT_LEFT
	diff.pressed.connect(func():
		G.difficulty = (G.difficulty + 1) % 3
		diff.text = names[G.difficulty]
		G.main.save_cfg())
	vb.add_child(diff)
	var vol := HBoxContainer.new()
	vb.add_child(vol)
	_label(vol, "SES  ", 20, DIM)
	var sl := HSlider.new()
	sl.custom_minimum_size = Vector2(280, 30)
	sl.min_value = 0.0
	sl.max_value = 1.0
	sl.step = 0.05
	sl.value = Sfx.volume
	sl.value_changed.connect(func(v):
		Sfx.set_volume(v)
		G.main.save_cfg())
	vol.add_child(sl)
	_menu_btn(vb, "ÇIKIŞ", func(): get_tree().quit())
	var help := _label(menu, "Sol tık seç · Sağ tık emir ver · Askerler kendi siperlerini bulur, yaralıları kurtarır.\nÜs kur, yolu koru: ikmal kamyonları ileri üslere ulaşmazsa gelir kesilir.", 17, Color(0.85, 0.82, 0.75))
	help.position = Vector2(90, 760)
	var cr := _label(menu, "v0.1 · Prosedürel grafik ve ses", 14, DIM)
	cr.anchor_top = 1.0
	cr.anchor_bottom = 1.0
	cr.offset_top = -34
	cr.offset_left = 24

func _menu_btn(parent: Control, text: String, cb: Callable) -> void:
	var b := Button.new()
	b.text = text
	b.custom_minimum_size = Vector2(360, 54)
	b.add_theme_font_size_override("font_size", 26)
	b.add_theme_font_override("font", font_b)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.pressed.connect(func():
		Sfx.play2d("ui_click", -4.0)
		cb.call())
	parent.add_child(b)

func hide_menu() -> void:
	if menu:
		menu.queue_free()
		menu = null

func toggle_pause() -> void:
	if G.game_over or G.spectate:
		return
	if pause_menu:
		pause_menu.queue_free()
		pause_menu = null
		get_tree().paused = false
		return
	get_tree().paused = true
	pause_menu = _center_box("DURAKLATILDI")
	var vb: VBoxContainer = pause_menu.get_meta("vb")
	_menu_btn(vb, "DEVAM", func(): toggle_pause())
	_menu_btn(vb, "ANA MENÜ", func():
		toggle_pause()
		G.main.to_menu())
	_menu_btn(vb, "ÇIKIŞ", func(): get_tree().quit())

func _center_box(title: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(c)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.55)
	c.add_child(shade)
	var pc := PanelContainer.new()
	pc.set_anchors_preset(Control.PRESET_CENTER)
	c.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 10)
	pc.add_child(vb)
	_label(vb, title, 44, AMBER, true).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.set_meta("vb", vb)
	pc.position = Vector2(-200, -160)
	return c

func show_game_over(winner: int) -> void:
	if G.spectate:
		G.main.restart_spectate()
		return
	if over_menu:
		over_menu.queue_free()
	var win := winner == G.player_team
	over_menu = _center_box("ZAFER" if win else "YENİLGİ")
	var vb: VBoxContainer = over_menu.get_meta("vb")
	var t := G.player_team
	_label(vb, "Süre: %02d:%02d" % [int(G.time) / 60, int(G.time) % 60], 20)
	_label(vb, "Etkisiz hâle getirilen düşman: %d" % G.stats["kills"][t], 20)
	_label(vb, "Kayıplar: %d" % G.stats["lost"][t], 20)
	_label(vb, "Tamamlanan yapı: %d" % G.stats["built"][t], 20)
	_menu_btn(vb, "ANA MENÜ", func():
		over_menu.queue_free()
		over_menu = null
		G.main.to_menu())
	Sfx.play2d("win" if win else "lose", -2.0)

# ============================================================ çizim katmanı
class Overlay extends Control:
	var hud: Hud

	func _draw() -> void:
		if not G.running or G.cam == null:
			return
		var cam: CamRig = G.cam
		var vt := G.view_team()
		var px: float = get_viewport_rect().size.y / cam.size
		var f: Font = hud.font
		# emir işaretleri
		if G.player:
			for m in G.player.markers:
				var k: float = (G.time - m[1]) / 1.2
				_ellipse(m[0], 1.8 * (1.0 - k * 0.5), Color(m[2].r, m[2].g, m[2].b, 1.0 - k), 2.0)
		for u in G.units:
			if not is_instance_valid(u) or not u.visible:
				continue
			if not u.alive and not (u is Soldier and u.state == "fly"):
				continue
			var p: Vector3 = u.position
			if not cam.on_screen(p, 60.0):
				continue
			var own: bool = u.team == G.player_team and not G.spectate
			if u.selected:
				var col: Color = Color(0.45, 1.0, 0.6) if own else Color(1.0, 0.4, 0.3)
				var r: float = u.radius + (0.35 if u is Soldier else 0.4)
				if u is Building:
					r = u.radius * 0.95
				_ellipse(p, r, col, 1.6)
				_brackets(p, r, col)
			# can çubuğu
			var show_bar: bool = u.selected or (G.time - u.last_hit < 3.0 and u.hp < u.max_hp)
			if u is Building and not u.done:
				show_bar = true
			if show_bar and not (u is Soldier and u.incapacitated()):
				var top: float = 2.0 if u is Soldier else (3.2 if u is Vehicle else 4.5)
				var s := cam.screen(p + Vector3(0, top, 0))
				var w: float = clampf(u.radius * px * 1.6, 24.0, 90.0)
				var fr: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
				var c := Color(0.3, 0.9, 0.4).lerp(Color(1.0, 0.25, 0.15), 1.0 - fr)
				if u is Building and not u.done:
					fr = u.progress
					c = Color(1.0, 0.78, 0.3)
				draw_rect(Rect2(s.x - w * 0.5 - 1, s.y - 1, w + 2, 5), Color(0, 0, 0, 0.7))
				draw_rect(Rect2(s.x - w * 0.5, s.y, w * fr, 3), c)
			if u is Building and u.is_base() and u.capture_t > 0.1:
				var s2 := cam.screen(p + Vector3(0, 5.5, 0))
				draw_rect(Rect2(s2.x - 40, s2.y, 80, 5), Color(0, 0, 0, 0.7))
				draw_rect(Rect2(s2.x - 40, s2.y, 80 * u.capture_t / u.capture_time(), 5), G.TEAM_COL[u.capture_team])
				draw_string(f, s2 + Vector2(-40, -4), "ELE GEÇİRİLİYOR", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
			# yaralı simgesi
			if u is Soldier and u.state == "wounded" and (own or vt < 0):
				var s3 := cam.screen(p + Vector3(0, 1.0, 0))
				var blink := 0.6 + 0.4 * sin(G.time * 6.0)
				draw_rect(Rect2(s3.x - 6, s3.y - 2, 12, 4), Color(1, 0.2, 0.2, blink))
				draw_rect(Rect2(s3.x - 2, s3.y - 6, 4, 12), Color(1, 0.2, 0.2, blink))
			# konuşma balonu
			if u.bubble != "" and cam.size < 75.0:
				var s4 := cam.screen(p + Vector3(0, 2.3, 0))
				var tw := f.get_string_size(u.bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 14).x
				var rect := Rect2(s4.x - tw * 0.5 - 6, s4.y - 24, tw + 12, 19)
				var a: float = clampf(u.bubble_t * 2.0, 0.0, 1.0)
				draw_rect(rect, Color(0.97, 0.96, 0.92, 0.9 * a))
				draw_colored_polygon(PackedVector2Array([Vector2(s4.x - 4, s4.y - 5), Vector2(s4.x + 4, s4.y - 5), Vector2(s4.x, s4.y + 1)]), Color(0.97, 0.96, 0.92, 0.9 * a))
				draw_string(f, Vector2(rect.position.x + 6, rect.position.y + 15), u.bubble, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, Color(0.1, 0.1, 0.1, a))
		# kutu seçimi
		if G.player and G.player.boxing:
			var r := Rect2(G.player.box_start, G.player.box_now - G.player.box_start).abs()
			if r.size.length() > 6.0:
				draw_rect(r, Color(0.45, 1.0, 0.6, 0.12))
				draw_rect(r, Color(0.45, 1.0, 0.6, 0.8), false, 1.0)
		# yerleştirme ipucu
		if G.player and G.player.place_type != "":
			var B: Dictionary = Building.BDEF[G.player.place_type]
			var m := get_viewport().get_mouse_position()
			var txt: String = B["title"]
			if B.get("line", false):
				txt += "  — tıkla: başlangıç, tıkla: bitiş" if G.player.place_a == Vector3.INF else "  — %d ikmal" % int(ceil(B["cost"] * minf(30.0, G.player.place_a.distance_to(cam.mouse_ground(m)))))
			else:
				var why := PlayerCtl.can_place(G.player.place_type, cam.mouse_ground(m), G.player.place_rot, G.player_team)
				txt += "  — %d ikmal%s   [R] döndür" % [B["cost"], ("  ·  " + why) if why != "" else ""]
			draw_string(f, m + Vector2(18, 30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))

	func _ellipse(p: Vector3, r: float, col: Color, w: float) -> void:
		var pts := PackedVector2Array()
		for i in 25:
			var a := TAU * i / 24.0
			pts.append(G.cam.screen(p + Vector3(cos(a) * r, 0.05, sin(a) * r)))
		draw_polyline(pts, col, w, true)

	func _brackets(p: Vector3, r: float, col: Color) -> void:
		var c := G.cam.screen(p + Vector3(0, 0.8, 0))
		var px: float = get_viewport_rect().size.y / G.cam.size
		var h := clampf(r * px * 1.1, 12.0, 120.0)
		var L := h * 0.35
		for sx in [-1.0, 1.0]:
			for sy in [-1.0, 1.0]:
				var o := c + Vector2(sx * h, sy * h * 0.8)
				draw_line(o, o - Vector2(sx * L, 0), col, 1.5)
				draw_line(o, o - Vector2(0, sy * L), col, 1.5)

# ============================================================ sektör radarı
class Radar extends Control:
	var hud: Hud
	const R := 132.0

	func _center() -> Vector2:
		return Vector2(size.x * 0.5, 192.0)

	func w2r(p: Vector3) -> Vector2:
		var rx := p.x - G.MAP * 0.5
		var rz := p.z - G.MAP * 0.5
		var k := R / (G.MAP * 0.5 * sqrt(2.0)) * 0.98
		return _center() + Vector2((rx - rz) / sqrt(2.0), (rx + rz) / sqrt(2.0)) * k

	func r2w(s: Vector2) -> Vector3:
		var k := R / (G.MAP * 0.5 * sqrt(2.0)) * 0.98
		var d := (s - _center()) / k
		# d.x=(rx-rz)/√2, d.y=(rx+rz)/√2
		var rx := (d.x + d.y) / sqrt(2.0)
		var rz := (d.y - d.x) / sqrt(2.0)
		return Vector3(rx + G.MAP * 0.5, 0, rz + G.MAP * 0.5)

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton:
			var mb := e as InputEventMouseButton
			if mb.button_index == MOUSE_BUTTON_LEFT:
				hud._radar_drag = mb.pressed
				if mb.pressed:
					G.cam.jump_to(r2w(mb.position))
				accept_event()
			elif mb.button_index == MOUSE_BUTTON_RIGHT and mb.pressed and G.player and not G.spectate:
				var mobile := G.player.selected.filter(func(u): return not (u is Building))
				if not mobile.is_empty():
					G.player.move_group(mobile, r2w(mb.position))
				accept_event()
		elif e is InputEventMouseMotion and hud._radar_drag:
			G.cam.jump_to(r2w((e as InputEventMouseMotion).position))
			accept_event()

	func _draw() -> void:
		var f: Font = hud.font
		var c := _center()
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.06, 0.065, 0.06, 0.92))
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.45, 0.42, 0.34, 0.6), false, 1.0)
		for k in [Vector2(6, 6), Vector2(size.x - 6, 6), Vector2(6, size.y - 6), Vector2(size.x - 6, size.y - 6)]:
			draw_circle(k, 2.5, Color(0.35, 0.33, 0.28))
		draw_string(hud.font_b, Vector2(16, 30), "SEKTÖR RADARI", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.9, 0.88, 0.82))
		var info := ["IZGARA 1820-A", "ALAN %dM" % int(G.MAP), "ZOOM %.1fx" % (52.0 / G.cam.size)]
		for i in 3:
			draw_string(f, Vector2(size.x - 16, 22 + i * 13), info[i], HORIZONTAL_ALIGNMENT_RIGHT, -1, 11, Color(0.6, 0.62, 0.58))
		# kadran
		draw_circle(c, R + 14, Color(0.02, 0.025, 0.025))
		draw_arc(c, R + 14, 0, TAU, 72, Color(0.3, 0.3, 0.27), 1.5, true)
		for i in 72:
			var a := TAU * i / 72.0
			var l := 8.0 if i % 6 == 0 else 3.5
			draw_line(c + Vector2(cos(a), sin(a)) * (R + 12), c + Vector2(cos(a), sin(a)) * (R + 12 - l), Color(0.55, 0.57, 0.52, 0.8), 1.0)
		draw_circle(c, R, Color(0.07, 0.11, 0.1))
		# harita karosu
		var dia := PackedVector2Array([w2r(Vector3(0, 0, 0)), w2r(Vector3(G.MAP, 0, 0)), w2r(Vector3(G.MAP, 0, G.MAP)), w2r(Vector3(0, 0, G.MAP))])
		var gcol := Color(0.2, 0.19, 0.14) if G.map_kind == "desert" else Color(0.24, 0.26, 0.28)
		draw_colored_polygon(dia, gcol)
		for i in range(1, 8):
			var t := G.MAP * i / 8.0
			draw_line(w2r(Vector3(t, 0, 0)), w2r(Vector3(t, 0, G.MAP)), Color(0.3, 0.42, 0.38, 0.35), 1.0)
			draw_line(w2r(Vector3(0, 0, t)), w2r(Vector3(G.MAP, 0, t)), Color(0.3, 0.42, 0.38, 0.35), 1.0)
		# yollar
		if G.logi:
			for t in 2:
				for n in G.logi.nodes[t]:
					var r: PackedVector3Array = n["route"]
					for i in r.size() - 1:
						draw_line(w2r(r[i]), w2r(r[i + 1]), Color(0.75, 0.7, 0.5, 0.5), 1.5)
		# birlikler
		var vt := G.view_team()
		for u in G.units:
			if not is_instance_valid(u) or not u.alive or u.team < 0:
				continue
			if vt >= 0 and u.team != vt and not u.seen[vt]:
				continue
			var p := w2r(u.position)
			var col: Color = G.TEAM_COL[u.team]
			if u is Building:
				var s := 6.0 if u.is_base() else 4.0
				draw_rect(Rect2(p - Vector2(s, s) * 0.5, Vector2(s, s)), col if u.done else col.darkened(0.5))
				if u.is_base():
					draw_rect(Rect2(p - Vector2(s, s), Vector2(s, s) * 2.0), col, false, 1.0)
			elif u is Vehicle:
				draw_rect(Rect2(p - Vector2(2.5, 2.5), Vector2(5, 5)), col.lightened(0.2))
			else:
				draw_rect(Rect2(p - Vector2(1.2, 1.2), Vector2(2.4, 2.4)), col)
		# kamera görüş alanı
		var vp := get_viewport_rect().size
		var q := PackedVector2Array()
		for s in [Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, vp.y), Vector2(0, vp.y), Vector2(0, 0)]:
			q.append(w2r(G.cam.mouse_ground(s)))
		draw_polyline(q, Color(0.5, 1.0, 0.85, 0.85), 1.2)
		# tarama çizgisi
		var sa := hud._sweep
		draw_line(c, c + Vector2(cos(sa), sin(sa)) * R, Color(0.4, 1.0, 0.8, 0.35), 1.5)
		for k in 8:
			var a2 := sa - k * 0.04
			draw_line(c, c + Vector2(cos(a2), sin(a2)) * R, Color(0.4, 1.0, 0.8, 0.05), 2.0)
		draw_arc(c, R, 0, TAU, 72, Color(0.35, 0.6, 0.5, 0.6), 1.0, true)
		draw_string(f, Vector2(c.x + R * 0.72, c.y + R * 0.78), "K", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.7, 0.75, 0.7))
		draw_string(f, Vector2(18, size.y - 14), "⌖ TIKLA VEYA SÜRÜKLE: GÖRÜNÜMÜ TAŞI", HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(0.62, 0.64, 0.6))
