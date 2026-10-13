class_name Hud extends CanvasLayer
# Arayüz: sağda KOMUTA paneli (ikmal sayacı, Sektör Radarı, sekmeler, resimli kartlar),
# solda asker kartı / tim listesi, terfi bildirimleri, uyarılar, konuşma balonları, menüler.

const AMBER := Color(1.0, 0.76, 0.32)
const TXT := Color(0.92, 0.9, 0.84)
const DIM := Color(0.6, 0.58, 0.53)
const PANEL := Color(0.075, 0.072, 0.065, 0.94)
const EDGE := Color(0.4, 0.36, 0.28, 0.7)
const PW := 400.0

var font: Font
var font_b: Font
var font_m: Font
var root: Control
var overlay: Control
var side: Control
var hdr_ops: Label
var supply_digits: Label
var supply_link: Label
var cap_lbl: Label
var time_lbl: Label
var radar: Control
var tabs: HBoxContainer
var sect_lbl: Label
var cards: GridContainer
var cards_scroll: ScrollContainer
var card_box: PanelContainer
var card_v: VBoxContainer
var promo_box: VBoxContainer
var alerts: VBoxContainer
var menu: Control
var pause_menu: Control
var over_menu: Control
var tooltip: Label
var thumbs: Thumbs
var tab := "base"
var _sel_sig := ""
var _tab_sig := ""
var _radar_drag := false
var _sweep := 0.0
var _toast: Array = []
var _card_live: Array = []

func _ready() -> void:
	layer = 5
	font = load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
	font_b = load("res://assets/fonts/BarlowCondensed-Bold.ttf")
	font_m = load("res://assets/fonts/BarlowCondensed-Medium.ttf")
	thumbs = Thumbs.new()
	add_child(thumbs)
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
	_build_side()
	_build_left()
	alerts = VBoxContainer.new()
	alerts.position = Vector2(18, 64)
	alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alerts.add_theme_constant_override("separation", 3)
	root.add_child(alerts)
	time_lbl = Label.new()
	time_lbl.add_theme_font_override("font", font_b)
	time_lbl.add_theme_font_size_override("font_size", 20)
	time_lbl.add_theme_color_override("font_color", TXT)
	time_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
	time_lbl.add_theme_constant_override("shadow_offset_y", 2)
	time_lbl.position = Vector2(20, 18)
	root.add_child(time_lbl)
	tooltip = Label.new()
	tooltip.visible = false
	tooltip.add_theme_color_override("font_color", TXT)
	tooltip.add_theme_font_size_override("font_size", 17)
	var tsb := _sb(Color(0.05, 0.05, 0.05, 0.96), Color(0.6, 0.5, 0.3, 0.7))
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
	var bn := _sb(Color(0.12, 0.115, 0.1, 0.95), Color(0.35, 0.32, 0.26, 0.8))
	var bh := _sb(Color(0.2, 0.17, 0.12, 0.98), AMBER)
	var bp := _sb(Color(0.45, 0.16, 0.1, 1.0), Color(0.9, 0.35, 0.25))
	var bd := _sb(Color(0.08, 0.08, 0.08, 0.8), Color(0.25, 0.25, 0.22, 0.6))
	for s in [bn, bh, bp, bd]:
		s.content_margin_left = 8
		s.content_margin_right = 8
		s.content_margin_top = 4
		s.content_margin_bottom = 4
	th.set_stylebox("normal", "Button", bn)
	th.set_stylebox("hover", "Button", bh)
	th.set_stylebox("pressed", "Button", bp)
	th.set_stylebox("hover_pressed", "Button", bp)
	th.set_stylebox("disabled", "Button", bd)
	th.set_stylebox("focus", "Button", StyleBoxEmpty.new())
	th.set_color("font_color", "Button", TXT)
	th.set_color("font_hover_color", "Button", AMBER)
	th.set_color("font_pressed_color", "Button", Color(1, 1, 1))
	th.set_color("font_hover_pressed_color", "Button", Color(1, 1, 1))
	th.set_color("font_disabled_color", "Button", Color(0.45, 0.43, 0.4))
	th.set_color("font_color", "Label", TXT)
	th.set_stylebox("panel", "PanelContainer", _sb(PANEL, EDGE))
	var sbv := StyleBoxFlat.new()
	sbv.bg_color = Color(0.4, 0.36, 0.28, 0.6)
	th.set_stylebox("grabber", "VScrollBar", sbv)
	th.set_stylebox("grabber_highlight", "VScrollBar", sbv)
	th.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	return th

func _sb(bg: Color, border: Color, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(2)
	return s

func mouse_over_ui() -> bool:
	var m := root.get_viewport().get_mouse_position()
	for c in [side, card_box]:
		if c.visible and c.get_global_rect().has_point(m):
			return true
	if menu and menu.visible:
		return true
	return false

func _label(parent: Control, t: String, size := 18, col := TXT, f: Font = null) -> Label:
	var l := Label.new()
	l.text = t
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	if f:
		l.add_theme_font_override("font", f)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(l)
	return l

func _clear(c: Node) -> void:
	for ch in c.get_children():
		ch.queue_free()

# ------------------------------------------------------------ sağ panel
func _build_side() -> void:
	side = PanelContainer.new()
	side.anchor_left = 1.0
	side.anchor_right = 1.0
	side.anchor_bottom = 1.0
	side.offset_left = -PW
	side.offset_right = 0
	var sb := _sb(Color(0.06, 0.058, 0.052, 0.97), Color(0.3, 0.27, 0.21, 0.9))
	sb.content_margin_left = 10
	sb.content_margin_right = 10
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	side.add_theme_stylebox_override("panel", sb)
	side.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(side)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	side.add_child(v)
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 8)
	v.add_child(hb)
	var cmd := PanelContainer.new()
	cmd.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cmd.add_theme_stylebox_override("panel", _inner_sb())
	hb.add_child(cmd)
	var cv := VBoxContainer.new()
	cv.add_theme_constant_override("separation", -6)
	cmd.add_child(cv)
	hdr_ops = _label(cv, "OPERASYON / 01", 13, DIM, font_m)
	_label(cv, "KOMUTA", 34, Color(0.96, 0.94, 0.88), font_b)
	_label(cv, "KARA KUVVETLERİ  ////", 13, DIM, font_m)
	var sup := PanelContainer.new()
	sup.custom_minimum_size = Vector2(170, 0)
	sup.add_theme_stylebox_override("panel", _inner_sb())
	hb.add_child(sup)
	var sv := VBoxContainer.new()
	sv.add_theme_constant_override("separation", 0)
	sup.add_child(sv)
	_label(sv, "⬢  İKMAL", 13, DIM, font_m)
	supply_digits = _label(sv, "00000", 32, Color(0.96, 0.94, 0.88), font_b)
	supply_link = _label(sv, "▲ 0 HAT AKTİF", 12, Color(0.45, 0.9, 0.55), font_m)
	cap_lbl = _label(sv, "BİRLİK 0/0", 12, DIM, font_m)
	radar = Radar.new()
	radar.hud = self
	radar.custom_minimum_size = Vector2(0, 330)
	radar.mouse_filter = Control.MOUSE_FILTER_STOP
	v.add_child(radar)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 4)
	v.add_child(tabs)
	for t in [["base", "ÜS"], ["def", "SAVUNMA"], ["inf", "PİYADE"], ["armor", "ZIRH"], ["air", "HAVA"]]:
		var b := Button.new()
		b.text = t[1]
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.add_theme_font_override("font", font_b)
		b.add_theme_font_size_override("font_size", 16)
		var key: String = t[0]
		b.set_meta("tab", key)
		b.pressed.connect(func(): set_tab(key))
		tabs.add_child(b)
	var sh := HBoxContainer.new()
	v.add_child(sh)
	sect_lbl = _label(sh, "◇  ÜS YAPILARI", 15, AMBER, font_b)
	sect_lbl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_label(sh, "SAĞ TIK: İPTAL", 13, DIM, font_m)
	cards_scroll = ScrollContainer.new()
	cards_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cards_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(cards_scroll)
	cards = GridContainer.new()
	cards.columns = 2
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 6)
	cards.add_theme_constant_override("v_separation", 6)
	cards_scroll.add_child(cards)

func _inner_sb() -> StyleBoxFlat:
	var s := _sb(Color(0.1, 0.095, 0.085, 1.0), Color(0.28, 0.25, 0.2, 0.9))
	s.content_margin_left = 10
	s.content_margin_right = 10
	s.content_margin_top = 6
	s.content_margin_bottom = 6
	return s

func set_tab(t: String) -> void:
	tab = t
	_tab_sig = ""
	Sfx.play2d("ui_click", -10.0)

func _tab_items() -> Array:
	match tab:
		"base":
			return ["fob", "barracks", "factory", "helipad", "hospital"]
		"def":
			return ["sandbags", "concrete", "trench", "wire", "trap", "mgnest", "tower"]
		"inf":
			return ["rifle_squad", "mg_team", "at_squad", "medic_team"]
		"armor":
			return ["technical", "apc", "tank"]
		"air":
			return ["heli"]
	return []

func _producer(id: String) -> Building:
	var best: Building = null
	var bq := 99
	for u in G.units:
		if not is_instance_valid(u) or not (u is Building) or u.team != G.player_team or not u.alive or not u.done:
			continue
		if not u.B["prod"].has(id):
			continue
		var sel: bool = G.player.selected.has(u)
		var q: int = u.queue.size() - (10 if sel else 0)
		if q < bq:
			bq = q
			best = u
	return best

func _rebuild_cards() -> void:
	_clear(cards)
	_card_live.clear()
	sect_lbl.text = {"base": "◇  ÜS YAPILARI", "def": "◇  SAVUNMA HATTI", "inf": "◇  PİYADE TİMLERİ", "armor": "◇  ZIRHLI BİRLİKLER", "air": "◇  HAVA UNSURLARI"}[tab]
	for b in tabs.get_children():
		b.button_pressed = b.get_meta("tab") == tab
	for id in _tab_items():
		cards.add_child(_card(id))

func _card(id: String) -> Control:
	var is_b: bool = Building.BDEF.has(id)
	var D: Dictionary = Building.BDEF[id] if is_b else Building.PDEF[id]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(184, 150)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_contents = true
	var tr := TextureRect.new()
	tr.texture = thumbs.get_thumb(id, G.player_team)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 3
	tr.offset_top = 3
	tr.offset_right = -3
	tr.offset_bottom = -30
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tr)
	var nm := Label.new()
	nm.text = D["title"].to_upper()
	nm.add_theme_font_override("font", font_b)
	nm.add_theme_font_size_override("font_size", 16)
	nm.anchor_top = 1.0
	nm.anchor_bottom = 1.0
	nm.offset_top = -28
	nm.offset_left = 8
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(nm)
	var cost := Label.new()
	var line: bool = D.get("line", false)
	cost.text = ("%d/m ⬢" % D["cost"]) if line else ("%d ⬢" % D["cost"])
	cost.add_theme_font_override("font", font_b)
	cost.add_theme_font_size_override("font_size", 16)
	cost.add_theme_color_override("font_color", AMBER)
	cost.anchor_left = 1.0
	cost.anchor_right = 1.0
	cost.anchor_top = 1.0
	cost.anchor_bottom = 1.0
	cost.offset_top = -28
	cost.offset_left = -80
	cost.offset_right = -8
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cost)
	var bar := ColorRect.new()
	bar.color = Color(1.0, 0.76, 0.32, 0.85)
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -31
	bar.offset_bottom = -29
	bar.offset_left = 3
	bar.offset_right = 3
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bar)
	var qn := Label.new()
	qn.add_theme_font_override("font", font_b)
	qn.add_theme_font_size_override("font_size", 22)
	qn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	qn.add_theme_constant_override("shadow_offset_y", 2)
	qn.position = Vector2(10, 6)
	qn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(qn)
	var desc: String = D.get("desc", "")
	if not is_b:
		desc = "%d ikmal · %d sn · %d birlik" % [D["cost"], int(D["time"]), D["cap"]]
	btn.mouse_entered.connect(func():
		tooltip.text = "%s\n%s" % [D["title"], desc]
		tooltip.visible = true)
	btn.mouse_exited.connect(func(): tooltip.visible = false)
	if is_b:
		btn.pressed.connect(func(): G.player.start_place(id))
	else:
		btn.pressed.connect(func(): _order(id))
		btn.gui_input.connect(func(e): _card_rmb(e, id))
	_card_live.append([btn, id, is_b, bar, qn, tr])
	return btn

func _card_rmb(e: InputEvent, id: String) -> void:
	if not (e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_RIGHT):
		return
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == G.player_team:
			for k in range(u.queue.size() - 1, -1, -1):
				if u.queue[k]["id"] == id:
					u.queue.remove_at(k)
					G.supply[G.player_team] += Building.PDEF[id]["cost"]
					Sfx.play2d("ui_click", -8.0)
					return

func _order(id: String) -> void:
	var b := _producer(id)
	if b == null:
		G.say("Üretim için uygun yapı yok", Vector3.ZERO, G.player_team)
		Sfx.play2d("ui_error", -6.0)
		return
	if not b.enqueue(id):
		if G.supply[G.player_team] < Building.PDEF[id]["cost"]:
			G.say("Yetersiz ikmal", b.position, G.player_team)
		Sfx.play2d("ui_error", -6.0)
	else:
		Sfx.play2d("ui_click", -6.0)

func _update_cards() -> void:
	var t := G.player_team
	for c in _card_live:
		var btn: Button = c[0]
		var id: String = c[1]
		if not is_instance_valid(btn):
			continue
		var bar: ColorRect = c[3]
		var qn: Label = c[4]
		var tr: TextureRect = c[5]
		if c[2]:
			var cost: int = Building.BDEF[id]["cost"]
			tr.modulate = Color(1, 1, 1) if G.supply[t] >= cost else Color(0.5, 0.5, 0.5)
			bar.offset_right = 3
			qn.text = ""
		else:
			var pb := _producer(id)
			var n := 0
			var prog := 0.0
			for u in G.units:
				if is_instance_valid(u) and u is Building and u.team == t and u.done:
					for k in u.queue.size():
						if u.queue[k]["id"] == id:
							n += 1
							if k == 0:
								prog = maxf(prog, u.queue[k]["t"] / Building.PDEF[id]["time"])
			tr.modulate = Color(1, 1, 1) if (pb != null and G.supply[t] >= Building.PDEF[id]["cost"]) else Color(0.42, 0.42, 0.42)
			bar.offset_right = 3 + (btn.size.x - 6) * prog
			qn.text = str(n) if n > 0 else ""

# ------------------------------------------------------------ sol: asker kartı / tim listesi / terfiler
func _build_left() -> void:
	card_box = PanelContainer.new()
	card_box.anchor_top = 1.0
	card_box.anchor_bottom = 1.0
	card_box.offset_left = 16
	card_box.offset_top = -190
	card_box.offset_bottom = -16
	card_box.offset_right = 400
	card_box.grow_vertical = Control.GROW_DIRECTION_BEGIN
	var sb := _sb(Color(0.07, 0.068, 0.06, 0.93), Color(0.32, 0.29, 0.22, 0.85))
	sb.content_margin_left = 14
	sb.content_margin_right = 14
	sb.content_margin_top = 10
	sb.content_margin_bottom = 10
	card_box.add_theme_stylebox_override("panel", sb)
	card_box.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(card_box)
	card_v = VBoxContainer.new()
	card_v.add_theme_constant_override("separation", 2)
	card_box.add_child(card_v)
	promo_box = VBoxContainer.new()
	promo_box.anchor_top = 1.0
	promo_box.anchor_bottom = 1.0
	promo_box.offset_left = 16
	promo_box.offset_top = -340
	promo_box.offset_bottom = -210
	promo_box.alignment = BoxContainer.ALIGNMENT_END
	promo_box.add_theme_constant_override("separation", 4)
	promo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(promo_box)

func promoted(s: Soldier) -> void:
	var pc := PanelContainer.new()
	var sb := _sb(Color(0.06, 0.06, 0.055, 0.92), Color(0.45, 0.4, 0.3, 0.8))
	sb.content_margin_left = 12
	sb.content_margin_right = 16
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.border_width_left = 3
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 12)
	pc.add_child(hb)
	_label(hb, "TERFİ", 13, DIM, font_m)
	_label(hb, s.display_name().to_upper(), 15, TXT, font_b)
	promo_box.add_child(pc)
	_toast.append([pc, 6.0, Vector3.ZERO])
	while promo_box.get_child_count() > 4:
		var f := promo_box.get_child(0)
		for e in _toast:
			if e[0] == f:
				_toast.erase(e)
				break
		f.free()
	Sfx.play2d("ui_done", -8.0)

func _rebuild_card() -> void:
	_clear(card_v)
	if card_v.has_meta("live"):
		card_v.remove_meta("live")
	if card_v.has_meta("status"):
		card_v.remove_meta("status")
	var sel: Array = G.player.selected
	card_box.visible = not sel.is_empty()
	card_box.offset_top = -190
	if sel.is_empty():
		return
	var u = sel[0]
	if sel.size() == 1 and u is Soldier:
		var s: Soldier = u
		var sq_name: String = s.squad.name.to_upper() if s.squad else "-"
		_label(card_v, "%s  |  %s" % [s.role_title(), sq_name], 13, DIM, font_m)
		var nm := HBoxContainer.new()
		card_v.add_child(nm)
		var parts := s.sname.split(" ")
		_label(nm, parts[0].to_upper() + " ", 30, TXT, font_m)
		_label(nm, parts[1].to_upper() if parts.size() > 1 else "", 30, Color(1, 1, 1), font_b)
		_label(card_v, "%s   %d / %d XP" % [Soldier.RANKS[s.rank], s.xp, Soldier.RANK_XP[mini(s.rank + 1, 4)]], 14, DIM, font_m)
		var rk := RankBar.new()
		rk.hud = self
		rk.soldier = s
		rk.custom_minimum_size = Vector2(0, 34)
		card_v.add_child(rk)
		card_v.set_meta("live", _label(card_v, "", 14, TXT, font_m))
		return
	if sel.size() == 1 and u is Vehicle:
		_label(card_v, "ZIRHLI BİRLİK", 13, DIM, font_m)
		_label(card_v, u.title.to_upper(), 30, TXT, font_b)
		card_v.set_meta("live", _label(card_v, "", 15, TXT, font_m))
		return
	if sel.size() == 1 and u is Building:
		_label(card_v, "YAPI", 13, DIM, font_m)
		_label(card_v, u.title.to_upper(), 30, TXT, font_b)
		var d := _label(card_v, u.B["desc"], 14, DIM, font_m)
		d.autowrap_mode = TextServer.AUTOWRAP_WORD
		d.custom_minimum_size = Vector2(350, 0)
		card_v.set_meta("live", _label(card_v, "", 15, TXT, font_m))
		return
	var soldiers := sel.filter(func(x): return x is Soldier)
	var sqn := "SEÇİLİ BİRLİKLER"
	if not soldiers.is_empty() and soldiers[0].squad:
		var same: bool = soldiers.all(func(x): return x.squad == soldiers[0].squad)
		if same:
			sqn = soldiers[0].squad.name.to_upper()
	var hb := HBoxContainer.new()
	card_v.add_child(hb)
	var hl := _label(hb, "%s  |  %d BİRLİK" % [sqn, sel.size()], 13, DIM, font_m)
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	card_v.set_meta("status", _label(hb, "● HAZIR", 13, Color(0.45, 0.9, 0.55), font_m))
	var n := 0
	for x in sel:
		n += 1
		if n > 8:
			_label(card_v, "%d DAHA" % (sel.size() - 8), 12, DIM, font_m)
			break
		var row := HBoxContainer.new()
		card_v.add_child(row)
		if x is Soldier:
			_label(row, Soldier.RANK_S[x.rank], 13, DIM, font_m).custom_minimum_size = Vector2(40, 0)
			var nl := _label(row, x.sname.get_slice(" ", 1).to_upper(), 16, TXT, font_b)
			nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			_label(row, "︿" if x.rank > 0 else "", 13, AMBER, font_m)
		else:
			_label(row, "", 13, DIM, font_m).custom_minimum_size = Vector2(40, 0)
			_label(row, x.title.to_upper(), 16, TXT, font_b)
	card_box.offset_top = -60 - mini(n, 9) * 22

func _update_card_live() -> void:
	var sel: Array = G.player.selected
	if sel.is_empty():
		return
	if card_v.has_meta("status"):
		var st = card_v.get_meta("status")
		if is_instance_valid(st):
			var fight := false
			var hurt := 0
			for x in sel:
				if x is Soldier:
					if G.time - x.threat_time < 4.0:
						fight = true
					if x.incapacitated():
						hurt += 1
			st.text = ("▼ %d YARALI" % hurt) if hurt > 0 else ("● ÇATIŞMADA" if fight else "● HAZIR")
			st.add_theme_color_override("font_color", Color(1, 0.4, 0.3) if hurt > 0 or fight else Color(0.45, 0.9, 0.55))
	if not card_v.has_meta("live"):
		return
	var live = card_v.get_meta("live")
	if not is_instance_valid(live):
		return
	var u = sel[0]
	if u is Soldier:
		var stt: String = {"idle": "BEKLEMEDE", "move": "İLERLİYOR", "wounded": "YARALI", "dragged": "SÜRÜKLENİYOR", "healing": "TEDAVİDE", "rescue": "YARALIYA KOŞUYOR", "drag": "YARALI TAŞIYOR", "heal": "TEDAVİ EDİYOR", "build": "İNŞA EDİYOR", "throw": "EL BOMBASI", "dazed": "SERSEM", "fly": "SAVRULDU", "dive": "SİPER ALIYOR"}.get(u.state, u.state)
		if u.state == "idle" and u.cover_type > 0:
			stt = "SİPERDE"
		var tm := "SAKİN" if u.suppression < 30 else ("GERGİN" if u.suppression < 70 else "BASTIRILDI")
		live.text = "%d YARALANMA   ·   %s   ·   %s   ·   MERMİ %d" % [u.downs, stt, tm, u.ammo]
	elif u is Vehicle:
		live.text = "ZIRH %d / %d%s" % [int(u.hp), int(u.max_hp), "   ·   PALET KOPUK" if u.tracks_broken > 0 else ""]
	elif u is Building:
		var q := ""
		if not u.queue.is_empty():
			var it: Dictionary = u.queue[0]
			var P: Dictionary = Building.PDEF[it["id"]]
			q = "ÜRETİM: %s %%%d%s" % [P["title"].to_upper(), int(it["t"] / P["time"] * 100), "  ·  BİRLİK SINIRI" if it.get("blocked", false) else ""]
		elif not u.done:
			q = "İNŞA %%%d" % int(u.progress * 100)
		else:
			q = "SAĞLAM %%%d" % int(u.hp / u.max_hp * 100)
		live.text = q

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	_sweep += dt * 1.6
	var t := G.player_team
	var running := G.running and not G.spectate
	side.visible = running
	time_lbl.visible = running
	if not running:
		card_box.visible = false
	if running:
		supply_digits.text = "%05d" % int(G.supply[t])
		var links := 0
		if G.logi:
			for tr in G.logi.trucks[t]:
				if is_instance_valid(tr) and tr.alive:
					links += 1
		supply_link.text = ("▲ %d HAT AKTİF" % links) if links > 0 else "▼ İKMAL HATTI YOK"
		supply_link.add_theme_color_override("font_color", Color(0.45, 0.9, 0.55) if links > 0 else Color(1, 0.45, 0.35))
		cap_lbl.text = "BİRLİK  %d / %d" % [G.cap_used[t], G.cap_max[t]]
		cap_lbl.add_theme_color_override("font_color", Color(1, 0.45, 0.35) if G.cap_used[t] >= G.cap_max[t] else DIM)
		var s := int(G.time)
		time_lbl.text = "%02d:%02d%s" % [s / 60, s % 60, "" if Engine.time_scale <= 1.0 else "   ×%d" % int(Engine.time_scale)]
		var ts := tab + G.map_kind
		if ts != _tab_sig:
			_tab_sig = ts
			_rebuild_cards()
		_update_cards()
		var sig := ""
		for u in G.player.selected:
			sig += str(u.get_instance_id()) + ","
		if G.player.selected.size() == 1 and G.player.selected[0] is Soldier:
			sig += "r%d" % G.player.selected[0].rank
		if sig != _sel_sig:
			_sel_sig = sig
			_rebuild_card()
		_update_card_live()
	if tooltip.visible:
		var m := root.get_viewport().get_mouse_position()
		tooltip.position = Vector2(m.x - tooltip.size.x - 14, m.y - tooltip.size.y - 10)
		if not side.get_global_rect().has_point(m):
			tooltip.visible = false
	overlay.queue_redraw()
	radar.queue_redraw()
	var i := _toast.size() - 1
	while i >= 0:
		var e: Array = _toast[i]
		e[1] -= dt / maxf(Engine.time_scale, 0.01)
		if e[1] <= 0.0:
			if is_instance_valid(e[0]):
				e[0].queue_free()
			_toast.remove_at(i)
		elif e[1] < 0.6 and is_instance_valid(e[0]):
			e[0].modulate.a = e[1] / 0.6
		i -= 1

# rütbe çubuğu
class RankBar extends Control:
	var hud: Hud
	var soldier: Soldier

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		if soldier == null or not is_instance_valid(soldier):
			return
		var w := size.x
		var y := 8.0
		draw_line(Vector2(8, y), Vector2(w - 8, y), Color(0.35, 0.33, 0.28), 2.0)
		var n := Soldier.RANK_S.size()
		var r := soldier.rank
		var frac := 0.0
		if r < n - 1:
			frac = clampf(float(soldier.xp - Soldier.RANK_XP[r]) / float(Soldier.RANK_XP[r + 1] - Soldier.RANK_XP[r]), 0.0, 1.0)
		var px := 8.0 + (w - 16.0) * (float(r) + frac) / float(n - 1)
		draw_line(Vector2(8, y), Vector2(px, y), Hud.AMBER, 2.0)
		for i in n:
			var x := 8.0 + (w - 16.0) * float(i) / float(n - 1)
			var c := Hud.AMBER if i <= r else Color(0.45, 0.43, 0.38)
			draw_rect(Rect2(x - 4, y - 4, 8, 8), c, i <= r)
			draw_string(hud.font_m, Vector2(x - 12, y + 22), Soldier.RANK_S[i], HORIZONTAL_ALIGNMENT_CENTER, 24, 12, c)

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
	var t := _label(vb, "MEVZİ", 120, Color(0.97, 0.94, 0.86), font_b)
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
	_label(vb, title, 44, AMBER, font_b).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
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
	var R := 120.0

	func _center() -> Vector2:
		R = minf(size.x, size.y - 40.0) * 0.5 - 18.0
		return Vector2(size.x * 0.5, size.y * 0.5 + 6.0)

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
		draw_string(hud.font_b, Vector2(14, 26), "SEKTÖR RADARI", HORIZONTAL_ALIGNMENT_LEFT, -1, 18, Color(0.9, 0.88, 0.82))
		var info := ["IZGARA 1820-A", "ALAN %dM" % int(G.MAP), "ZOOM %.1fx" % (40.0 / G.cam.size)]
		for i in 3:
			draw_string(f, Vector2(size.x - 130, 20 + i * 13), info[i], HORIZONTAL_ALIGNMENT_RIGHT, 118, 11, Color(0.6, 0.62, 0.58))
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
				draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(4, 0), p + Vector2(0, 4), p + Vector2(-4, 0)]), col.lightened(0.2))
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
		draw_string(f, Vector2(14, size.y - 8), "⌖ TIKLA: GÖRÜNÜMÜ TAŞI   ·   SAĞ TIK: BİRLİK GÖNDER", HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.62, 0.64, 0.6))
