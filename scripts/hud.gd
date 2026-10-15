class_name Hud extends CanvasLayer
# Arayüz: üstte ince durum şeridi, sol altta harita, ortada seçim + emir paneli,
# sağ altta üretim paneli; uyarılar, terfiler, konuşma balonları, menüler.

const AMBER := Color(1.0, 0.74, 0.3)
const TXT := Color(0.93, 0.92, 0.88)
const DIM := Color(0.58, 0.58, 0.55)
const GREEN := Color(0.52, 0.9, 0.56)
const RED := Color(1.0, 0.42, 0.33)
const BG := Color(0.045, 0.048, 0.046, 0.88)
const BG2 := Color(1, 1, 1, 0.035)
const EDGE := Color(1, 1, 1, 0.1)
const PH := 200.0       # alt panel yüksekliği
const PRW := 452.0      # üretim paneli genişliği
const UPW := 690.0      # seçim paneli genişliği
const GAP := 14.0

# emirler: CoH2 / Sudden Strike / Broken Arrow tarzı
const ORDERS := {
	"move": {"t": "Hareket", "k": "M", "tgt": true, "d": "Seçili birlikler yürüyerek gider, siper kullanır."},
	"fast": {"t": "Hızlı Hareket", "k": "F", "tgt": true, "d": "Koşarak gider; siper aramaz, baskılanmayı yok sayar."},
	"amove": {"t": "Saldırı Hareketi", "k": "T", "tgt": true, "d": "Yolda düşman görünce durur ve çatışır."},
	"reverse": {"t": "Geri Vites", "k": "N", "tgt": true, "d": "Aracı geri geri sür; ön zırh düşmana dönük kalır."},
	"stop": {"t": "Dur", "k": "X", "tgt": false, "d": "Tüm emirleri iptal et."},
	"hold": {"t": "Mevzi Tut", "k": "H", "tgt": false, "d": "Yerinde kal, siper için bile kımıldama."},
	"retreat": {"t": "Geri Çekil", "k": "R", "tgt": false, "d": "En yakın üsse koşarak çekil; daha az hasar ve baskı alır."},
	"fire": {"t": "Ateş Modu", "k": "V", "tgt": false, "d": "Serbest ateş / Sadece karşılık / Ateşi kes"},
	"stance": {"t": "Duruş", "k": "C", "tgt": false, "d": "Otomatik / Ayakta / Çömel / Yat"},
	"unload": {"t": "İndir", "k": "U", "tgt": false, "d": "Yolcuları indir. Askıda araç varsa önce onu yere bırakır."},
	"airdrop": {"t": "İkmal At", "k": "Y", "tgt": true, "d": "Kargo helikopteri seçilen noktaya mühimmat paleti bırakır; paletler üste/pistte yenilenir. Dost hafif araca sağ tık: askıya al."},
	"refund": {"t": "Üsse Dön (İade)", "k": "J", "tgt": false, "d": "Birlik en yakın üsse döner ve sahadan çekilir; kalan değerinin %80'i iade edilir."},
	"abandon": {"t": "Terk Et", "k": "K", "tgt": false, "d": "Mürettebat aracı terk eder; araç 6 sn sonra kendini imha eder."},
	"grenade": {"t": "El Bombası", "k": "G", "tgt": true, "d": "Seçilen noktaya el bombası at."},
	"smoke": {"t": "Sis", "k": "Z", "tgt": true, "d": "Sis bombası at / sis atarları ateşle."},
	"suppress": {"t": "Baskı Ateşi", "k": "B", "tgt": true, "d": "Bir bölgeyi 12 sn boyunca ateş altında tut."},
	"fastrope": {"t": "Halatla İndir", "k": "I", "tgt": true, "d": "Nakliye helikopteri noktada 8 m'de asılı kalır, iki halat sarkıtır; askerler tüfeği sırta atıp halattan kayarak iner. Bitince halatlar bırakılır."},
	"ropepick": {"t": "Halatla Al", "k": "-", "tgt": true, "d": "Helikopter noktada asılı kalıp halat sarkıtır; yakındaki (ya da seçili) askerler kancalanır ve hep birlikte yukarı çekilir."},
	"minidrone": {"t": "Mini Drone Kaldır", "k": "L", "tgt": true, "d": "Operatör sırt çantasından FPV drone çıkarıp elden kaldırır. Düşmana tıkla: saldırır; boş noktaya tıkla: orada asılı kalıp tarar."},
	"dronestation": {"t": "Drone İstasyonu Kur", "k": "O", "tgt": true, "d": "Operatör seçilen yere yer kontrol istasyonu kurar (16 sn). Bitince mancınıktan keşif İHA'sı fırlatılır: yüksek irtifa, geniş görüş, vurulması zor."},
	"demolish": {"t": "Yık", "k": "DEL", "tgt": false, "d": "İnşaatı iptal et (%75 iade)."},
}
const ORDER_SEQ := ["move", "fast", "amove", "reverse", "stop", "hold", "retreat", "fire", "stance", "unload", "airdrop", "grenade", "smoke", "suppress", "fastrope", "ropepick", "minidrone", "dronestation", "refund", "abandon", "demolish"]
# emir kısayollarının VARSAYILANLARI; oyuncu atamaları ve eşleşme Keybinds üzerinden (Ayarlar > Klavye Ayarları)
const ORDER_KEYS := {KEY_M: "move", KEY_F: "fast", KEY_T: "amove", KEY_N: "reverse", KEY_X: "stop", KEY_H: "hold", KEY_R: "retreat", KEY_V: "fire", KEY_C: "stance", KEY_U: "unload", KEY_Y: "airdrop", KEY_G: "grenade", KEY_Z: "smoke", KEY_B: "suppress", KEY_K: "abandon", KEY_J: "refund", KEY_L: "minidrone", KEY_O: "dronestation", KEY_I: "fastrope", KEY_DELETE: "demolish"}
const FIRE_TXT := ["SERBEST", "KARŞILIK", "ATEŞ KES"]
const STANCE_TXT := ["OTO", "AYAKTA", "ÇÖMEL", "YAT"]
const ROLE_PROD := {"rifle": "rifle_squad", "mg": "mg_team", "at": "at_squad", "atgm": "atgm_team", "medic": "medic_team", "sniper": "sniper_team", "engineer": "engineer_squad", "mortar": "mortar_team", "drone": "drone_team"}

var font: Font
var font_b: Font
var icons: TacIcons
var font_m: Font
var root: Control
var overlay: Control
var top: PanelContainer
var supply_lbl: Label
var link_lbl: Label
var cap_lbl: Label
var time_lbl: Label
var mini: PanelContainer
var radar: Control
var unit_panel: PanelContainer
var info_box: Control
var cmd_grid: GridContainer
var prod: PanelContainer
var tabs: HBoxContainer
var cards: GridContainer
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
var _cmd_sig := ""
var _radar_drag := false
var _sweep := 0.0
var _toast: Array = []
var _card_live: Array = []
var _cmd_live: Array = []
var _info_live := {}
var _tip_owner: Control = null

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
	root.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	add_child(root)
	overlay = Overlay.new()
	overlay.hud = self
	overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(overlay)
	# stratejik görüş simgeleri (uzaklaşınca birlik sembolleri, hedef bölgeleri)
	icons = TacIcons.new()
	root.add_child(icons)
	_build_top()
	_build_mini()
	_build_unit_panel()
	_build_prod()
	alerts = VBoxContainer.new()
	alerts.position = Vector2(20, 18)
	alerts.mouse_filter = Control.MOUSE_FILTER_IGNORE
	alerts.add_theme_constant_override("separation", 2)
	root.add_child(alerts)
	promo_box = VBoxContainer.new()
	promo_box.anchor_top = 1.0
	promo_box.anchor_bottom = 1.0
	promo_box.offset_left = GAP
	promo_box.offset_top = -PH - GAP - 150
	promo_box.offset_bottom = -PH - GAP - 8
	promo_box.alignment = BoxContainer.ALIGNMENT_END
	promo_box.add_theme_constant_override("separation", 4)
	promo_box.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(promo_box)
	tooltip = Label.new()
	tooltip.visible = false
	tooltip.add_theme_color_override("font_color", TXT)
	tooltip.add_theme_font_size_override("font_size", 16)
	tooltip.add_theme_font_override("font", font_m)
	var tsb := _sb(Color(0.03, 0.032, 0.03, 0.97), Color(1, 1, 1, 0.16))
	tsb.content_margin_left = 10
	tsb.content_margin_right = 10
	tsb.content_margin_top = 6
	tsb.content_margin_bottom = 7
	tooltip.add_theme_stylebox_override("normal", tsb)
	tooltip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	tooltip.z_index = 50
	root.add_child(tooltip)
	G.alert.connect(_on_alert)
	MainMenu.apply_cfg()      # ayar dosyasındaki ek seçenekler (v-sync, arayüz sesleri)

func _theme() -> Theme:
	var th := Theme.new()
	th.default_font = font
	th.default_font_size = 17
	var bn := _sb(Color(1, 1, 1, 0.045), Color(1, 1, 1, 0.08))
	var bh := _sb(Color(1, 0.74, 0.3, 0.12), Color(1, 0.74, 0.3, 0.7))
	var bp := _sb(Color(1, 0.74, 0.3, 0.26), AMBER)
	var bd := _sb(Color(1, 1, 1, 0.02), Color(1, 1, 1, 0.04))
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
	th.set_color("font_disabled_color", "Button", Color(0.4, 0.4, 0.38))
	th.set_color("font_color", "Label", TXT)
	var pan := _sb(BG, EDGE)
	pan.content_margin_left = 10
	pan.content_margin_right = 10
	pan.content_margin_top = 10
	pan.content_margin_bottom = 10
	th.set_stylebox("panel", "PanelContainer", pan)
	var sbv := StyleBoxFlat.new()
	sbv.bg_color = Color(1, 1, 1, 0.18)
	th.set_stylebox("grabber", "VScrollBar", sbv)
	th.set_stylebox("grabber_highlight", "VScrollBar", sbv)
	th.set_stylebox("scroll", "VScrollBar", StyleBoxEmpty.new())
	return th

func _sb(bg: Color, border: Color, bw := 1) -> StyleBoxFlat:
	var s := StyleBoxFlat.new()
	s.bg_color = bg
	s.border_color = border
	s.set_border_width_all(bw)
	s.set_corner_radius_all(3)
	return s

func mouse_over_ui() -> bool:
	var m := root.get_viewport().get_mouse_position()
	for c in [top, mini, unit_panel, prod]:
		if c.visible and c.get_global_rect().has_point(m):
			return true
	if menu and menu.visible:
		return true
	if G.sandbox and G.main.sandbox_ui and is_instance_valid(G.main.sandbox_ui) and G.main.sandbox_ui.over_ui():
		return true
	return false

func _label(parent: Control, t: String, size := 17, col := TXT, f: Font = null) -> Label:
	var l := Label.new()
	l.text = I18n.s(t)
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
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

func _tip(c: Control, text_fn: Callable) -> void:
	c.mouse_entered.connect(func():
		_tip_owner = c
		tooltip.text = text_fn.call()
		tooltip.visible = true)
	c.mouse_exited.connect(func():
		if _tip_owner == c:
			tooltip.visible = false
			_tip_owner = null)

# ------------------------------------------------------------ üst şerit
func _build_top() -> void:
	top = PanelContainer.new()
	top.anchor_left = 0.5
	top.anchor_right = 0.5
	top.offset_top = 10
	top.grow_horizontal = Control.GROW_DIRECTION_BOTH
	var sb := _sb(BG, EDGE)
	sb.content_margin_left = 16
	sb.content_margin_right = 8
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	top.add_theme_stylebox_override("panel", sb)
	top.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(top)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 14)
	top.add_child(h)
	var s1 := _top_item(h, "İKMAL")
	supply_lbl = _label(s1, "0", 21, TXT, font_b)
	link_lbl = _label(s1, "", 14, GREEN, font_m)
	_top_sep(h)
	var s2 := _top_item(h, "BİRLİK")
	cap_lbl = _label(s2, "0/0", 21, TXT, font_b)
	_top_sep(h)
	time_lbl = _label(h, "00:00", 21, TXT, font_b)
	time_lbl.custom_minimum_size = Vector2(58, 0)
	var mb := Button.new()
	mb.text = "≡"
	mb.custom_minimum_size = Vector2(34, 30)
	mb.add_theme_font_size_override("font_size", 20)
	mb.focus_mode = Control.FOCUS_NONE
	mb.pressed.connect(func(): toggle_pause())
	h.add_child(mb)
	_tip(s1, func(): return "%s\n%s" % [I18n.s("İKMAL"), link_lbl.text])

func _top_item(h: HBoxContainer, cap: String) -> HBoxContainer:
	var b := HBoxContainer.new()
	b.add_theme_constant_override("separation", 7)
	b.mouse_filter = Control.MOUSE_FILTER_PASS
	h.add_child(b)
	var l := _label(b, cap, 13, DIM, font_m)
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return b

func _top_sep(h: HBoxContainer) -> void:
	var r := ColorRect.new()
	r.color = Color(1, 1, 1, 0.12)
	r.custom_minimum_size = Vector2(1, 22)
	r.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(r)

# ------------------------------------------------------------ harita
static var mini_scale := 1.25

func apply_mini_size() -> void:
	var ms := PH * mini_scale
	mini.offset_left = GAP
	mini.offset_right = GAP + ms
	mini.offset_top = -ms - GAP
	mini.offset_bottom = -GAP

func _build_mini() -> void:
	mini = PanelContainer.new()
	mini.anchor_top = 1.0
	mini.anchor_bottom = 1.0
	mini.offset_left = GAP
	mini.offset_right = GAP + PH
	mini.offset_top = -PH - GAP
	mini.offset_bottom = -GAP
	var sb := _sb(BG, EDGE)
	sb.set_content_margin_all(4)
	mini.add_theme_stylebox_override("panel", sb)
	mini.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(mini)
	radar = Radar.new()
	radar.hud = self
	radar.mouse_filter = Control.MOUSE_FILTER_STOP
	mini.add_child(radar)
	mini_scale = float(G.main.cfg.get("minimap", 1.25)) if G.main and "cfg" in G.main else 1.25
	apply_mini_size()

# ------------------------------------------------------------ seçim + emir paneli
func _build_unit_panel() -> void:
	unit_panel = PanelContainer.new()
	unit_panel.anchor_top = 1.0
	unit_panel.anchor_bottom = 1.0
	unit_panel.offset_top = -PH - GAP
	unit_panel.offset_bottom = -GAP
	unit_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(unit_panel)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	unit_panel.add_child(h)
	info_box = Control.new()
	info_box.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	info_box.clip_contents = true
	h.add_child(info_box)
	var sep := ColorRect.new()
	sep.color = Color(1, 1, 1, 0.08)
	sep.custom_minimum_size = Vector2(1, 0)
	sep.mouse_filter = Control.MOUSE_FILTER_IGNORE
	h.add_child(sep)
	cmd_grid = GridContainer.new()
	cmd_grid.columns = 5
	cmd_grid.add_theme_constant_override("h_separation", 5)
	cmd_grid.add_theme_constant_override("v_separation", 5)
	cmd_grid.custom_minimum_size = Vector2(5 * 58 + 4 * 5, 0)
	h.add_child(cmd_grid)

func _layout() -> void:
	var w := root.get_viewport_rect().size.x
	var left := GAP + PH * mini_scale + GAP
	var right := w - GAP - PRW - GAP
	var pw := minf(UPW, right - left)
	var x := left + (right - left - pw) * 0.5
	unit_panel.offset_left = x
	unit_panel.offset_right = x + pw

# emir mevcut mu (seçime göre)
func order_state(id: String, sel: Array) -> int:
	# -1 yok, 0 pasif, 1 aktif
	var any := false
	var ok := false
	for u in sel:
		if not is_instance_valid(u) or not u.alive:
			continue
		var sol: bool = u is Soldier and u.state != "aboard"
		var veh: bool = u is Vehicle and not (u.vtype in ["truck", "fpv"])
		match id:
			"move", "fast", "amove", "stop", "hold", "retreat", "fire":
				if sol or veh:
					return 1
			"refund":
				if sol or (veh and not u.is_air()):
					return 1
			"reverse":
				if veh and not u.is_air():
					return 1
			"stance":
				if sol:
					return 1
			"unload":
				if veh and u.capacity() > 0:
					any = true
					ok = ok or not u.cargo.is_empty() or u.sling != null
			"airdrop":
				if veh and u.is_cargo():
					any = true
					ok = ok or u.crates > 0
			"grenade":
				if sol:
					any = true
					ok = ok or (u.grenades > 0 and u.can_fight())
			"smoke":
				if sol:
					any = true
					ok = ok or (u.smoke_nades > 0 and u.can_fight())
				elif veh and u.has_smoke():
					any = true
					ok = ok or u.smoke_charges > 0
			"fastrope":
				if veh and u.vtype == "transport":
					any = true
					ok = ok or not u.cargo.is_empty()
			"ropepick":
				if veh and u.vtype == "transport":
					any = true
					ok = ok or u.cargo.size() < u.capacity()
			"minidrone":
				if sol and u.role == "drone":
					any = true
					ok = ok or (u.fpv_left > 0 and u.drone_cd <= 0.0 and u.can_fight())
			"dronestation":
				if sol and u.role == "drone":
					any = true
					ok = ok or u.can_fight()
			"suppress":
				if sol and not (u.role in ["mortar", "drone"]):
					return 1
				if veh and u.can_ground_fire():
					return 1
			"demolish":
				if u is Building and not u.done and u.team == G.player_team:
					return 1
			"abandon":
				if veh and u.crew_max > 0 and not u.is_air():
					any = true
					ok = ok or (u.crew_n > 0 and u.abandon_t < 0.0)
	if not any:
		return -1
	return 1 if ok else 0

func _rebuild_cmds() -> void:
	_clear(cmd_grid)
	_cmd_live.clear()
	var sel: Array = G.player.selected
	if sel.is_empty() or sel[0].team != G.player_team:
		return
	for id in ORDER_SEQ:
		if order_state(id, sel) < 0:
			continue
		cmd_grid.add_child(_cmd_btn(id))

func _cmd_btn(id: String) -> Control:
	var O: Dictionary = ORDERS[id]
	var b := Button.new()
	b.custom_minimum_size = Vector2(58, 50)
	b.focus_mode = Control.FOCUS_NONE
	var ic := CmdIcon.new()
	ic.kind = id
	ic.hud = self
	ic.set_anchors_preset(Control.PRESET_FULL_RECT)
	ic.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(ic)
	var k := Label.new()
	k.text = Keybinds.short("o." + id)
	k.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	k.add_theme_font_override("font", font_b)
	k.add_theme_font_size_override("font_size", 11)
	k.add_theme_color_override("font_color", Color(1, 1, 1, 0.42))
	k.position = Vector2(4, 1)
	k.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(k)
	var st := Label.new()
	st.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	st.add_theme_font_override("font", font_b)
	st.add_theme_font_size_override("font_size", 11)
	st.add_theme_color_override("font_color", AMBER)
	st.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	st.anchor_left = 1.0
	st.anchor_right = 1.0
	st.offset_left = -50
	st.offset_right = -4
	st.offset_top = 1
	st.mouse_filter = Control.MOUSE_FILTER_IGNORE
	b.add_child(st)
	b.pressed.connect(func(): G.player.order_button(id))
	_tip(b, func(): return "%s  [%s]\n%s" % [I18n.s(O["t"]), Keybinds.label("o." + id), I18n.s(O["d"])])
	_cmd_live.append([b, id, st, ic])
	return b

func _update_cmds() -> void:
	var sel: Array = G.player.selected
	for c in _cmd_live:
		var b: Button = c[0]
		if not is_instance_valid(b):
			continue
		var id: String = c[1]
		var st: Label = c[2]
		var ic: CmdIcon = c[3]
		var s := order_state(id, sel)
		b.disabled = s == 0
		ic.active = G.player.pending_order == id
		match id:
			"fire":
				var fm: int = _first_val(sel, "fire_mode", 0)
				st.text = I18n.s(FIRE_TXT[fm])
				st.add_theme_color_override("font_color", [GREEN, AMBER, RED][fm])
				ic.variant = fm
			"stance":
				var sl: int = _first_val(sel, "stance_lock", -1)
				st.text = I18n.s(STANCE_TXT[sl + 1])
				ic.variant = sl + 1
			"grenade":
				st.text = str(_sum_val(sel, "grenades"))
			"smoke":
				st.text = str(_sum_val(sel, "smoke_nades") + _sum_val(sel, "smoke_charges"))
			"unload":
				var n := 0
				for u in sel:
					if is_instance_valid(u) and u is Vehicle:
						n += u.cargo.size()
				st.text = str(n) if n > 0 else ""
			"airdrop":
				st.text = str(_sum_val(sel, "crates"))
			"minidrone":
				st.text = str(_sum_val(sel, "fpv_left"))
			"hold":
				ic.active = ic.active or _first_val(sel, "order", "") == "hold"

func _first_val(sel: Array, prop: String, def):
	for u in sel:
		if is_instance_valid(u) and u.alive and (u is Soldier or u is Vehicle):
			var v = u.get(prop)
			if v != null:
				return v
	return def

func _sum_val(sel: Array, prop: String) -> int:
	var n := 0
	for u in sel:
		if is_instance_valid(u) and u.alive:
			var v = u.get(prop)
			if v is int:
				n += v
	return n

# ------------------------------------------------------------ seçim bilgisi
func _rebuild_info() -> void:
	_clear(info_box)
	_info_live.clear()
	var sel: Array = G.player.selected
	if sel.is_empty():
		return
	var u = sel[0]
	if sel.size() == 1 and u is Soldier:
		_info_soldier(u)
	elif sel.size() == 1 and u is Vehicle:
		_info_vehicle(u)
	elif sel.size() == 1 and u is Building:
		_info_building(u)
	else:
		_info_group(sel)

func _portrait(id: String, team: int, sz := Vector2(104, 104)) -> TextureRect:
	var fr := Panel.new()
	fr.custom_minimum_size = sz
	fr.size = sz
	var sb := _sb(Color(0, 0, 0, 0.3), Color(1, 1, 1, 0.1))
	fr.add_theme_stylebox_override("panel", sb)
	fr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(fr)
	var tr := TextureRect.new()
	tr.texture = thumbs.get_thumb(id, team)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 2
	tr.offset_top = 2
	tr.offset_right = -2
	tr.offset_bottom = -2
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	fr.add_child(tr)
	return tr

func _vbox_at(x: float, y: float, w: float) -> VBoxContainer:
	var v := VBoxContainer.new()
	v.position = Vector2(x, y)
	v.custom_minimum_size = Vector2(w, 0)
	v.size = Vector2(w, 0)
	v.add_theme_constant_override("separation", 0)
	v.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(v)
	return v

func _bar(parent: Control, h := 5.0) -> Bar:
	var b := Bar.new()
	b.custom_minimum_size = Vector2(0, h)
	b.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(b)
	return b

func _spacer(parent: Control, h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)

func _info_soldier(s: Soldier) -> void:
	_portrait("s:" + s.role, s.team)
	var w := info_box.size.x - 118.0
	if w < 100:
		w = 240
	var v := _vbox_at(118, 0, w)
	var sq_name: String = s.squad.name if s.squad else "-"
	_label(v, "%s  ·  %s" % [I18n.s("PİYADE"), sq_name.to_upper()], 13, DIM, font_m)
	var nm := HBoxContainer.new()
	nm.add_theme_constant_override("separation", 6)
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	v.add_child(nm)
	var l1 := _label(nm, "", 27, Color(0.85, 0.84, 0.8), font_m)
	l1.text = I18n.s(Soldier.RANKS[s.rank])
	var l2 := _label(nm, "", 27, Color(1, 1, 1), font_b)
	l2.text = I18n.s(Soldier.ROLE_TITLE.get(s.role, "Piyade")).to_upper()
	var rk := RankBar.new()
	rk.hud = self
	rk.soldier = s
	rk.custom_minimum_size = Vector2(0, 30)
	v.add_child(rk)
	_spacer(v, 4)
	_info_live["hp"] = _bar(v, 5)
	_spacer(v, 6)
	_info_live["stats"] = _label(v, "", 15, TXT, font_m)
	_info_live["status"] = _label(v, "", 15, AMBER, font_b)
	_info_live["unit"] = s

func _info_vehicle(u: Vehicle) -> void:
	_portrait("v:" + u.vtype, u.team)
	var v := _vbox_at(118, 0, maxf(info_box.size.x - 118.0, 240))
	_label(v, "HAVA UNSURU" if u.is_air() else "ZIRHLI BİRLİK", 13, DIM, font_m)
	_label(v, I18n.s(u.title).to_upper(), 27, Color(1, 1, 1), font_b)
	_spacer(v, 6)
	_info_live["hp"] = _bar(v, 5)
	_spacer(v, 8)
	_info_live["stats"] = _label(v, "", 15, TXT, font_m)
	_info_live["status"] = _label(v, "", 15, AMBER, font_b)
	_info_live["unit"] = u

func _info_building(u: Building) -> void:
	_portrait(u.btype, u.team)
	var v := _vbox_at(118, 0, maxf(info_box.size.x - 118.0, 240))
	_label(v, "YAPI", 13, DIM, font_m)
	_label(v, I18n.s(u.title).to_upper(), 27, Color(1, 1, 1), font_b)
	_spacer(v, 6)
	_info_live["hp"] = _bar(v, 5)
	_spacer(v, 6)
	var d := _label(v, u.B["desc"], 14, DIM, font_m)
	d.autowrap_mode = TextServer.AUTOWRAP_WORD
	d.custom_minimum_size = Vector2(maxf(info_box.size.x - 120.0, 220), 0)
	_info_live["status"] = _label(v, "", 15, AMBER, font_b)
	var q := HBoxContainer.new()
	q.add_theme_constant_override("separation", 4)
	q.position = Vector2(0, 116)
	info_box.add_child(q)
	_info_live["queue"] = q
	_info_live["qsig"] = ""
	_info_live["unit"] = u

func _info_group(sel: Array) -> void:
	var soldiers := sel.filter(func(x): return x is Soldier)
	var sqn := "SEÇİLİ BİRLİKLER"
	if not soldiers.is_empty() and soldiers[0].squad:
		var same: bool = soldiers.all(func(x): return x.squad == soldiers[0].squad)
		if same:
			sqn = soldiers[0].squad.name.to_upper()
	var hb := HBoxContainer.new()
	hb.position = Vector2(0, 0)
	hb.custom_minimum_size = Vector2(maxf(info_box.size.x, 300), 0)
	hb.mouse_filter = Control.MOUSE_FILTER_IGNORE
	info_box.add_child(hb)
	var hl := _label(hb, "", 15, TXT, font_b)
	hl.text = "%s   ·   %s" % [I18n.s(sqn), I18n.s("%d BİRLİK") % sel.size()]
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_info_live["status"] = _label(hb, "", 14, GREEN, font_m)
	var g := GridContainer.new()
	g.columns = maxi(4, int((maxf(info_box.size.x, 300) + 4) / 52.0))
	g.position = Vector2(0, 28)
	g.add_theme_constant_override("h_separation", 4)
	g.add_theme_constant_override("v_separation", 4)
	info_box.add_child(g)
	var n := 0
	for x in sel:
		n += 1
		if n > g.columns * 3:
			break
		var ch := Chip.new()
		ch.hud = self
		ch.u = x
		ch.custom_minimum_size = Vector2(48, 56)
		g.add_child(ch)
	_info_live["group"] = sel

func _update_info() -> void:
	if _info_live.is_empty():
		return
	if _info_live.has("group"):
		var sel: Array = G.player.selected
		var fight := false
		var hurt := 0
		for x in sel:
			if x is Soldier:
				if G.time - x.threat_time < 4.0:
					fight = true
				if x.incapacitated():
					hurt += 1
			elif x is Vehicle and G.time - x.last_hit < 4.0:
				fight = true
		var st: Label = _info_live["status"]
		st.text = (I18n.s("%d YARALI") % hurt) if hurt > 0 else I18n.s("ÇATIŞMADA" if fight else "HAZIR")
		st.add_theme_color_override("font_color", RED if hurt > 0 or fight else GREEN)
		return
	var u = _info_live.get("unit")
	if u == null or not is_instance_valid(u):
		return
	var hp: Bar = _info_live["hp"]
	if u is Building and not u.done:
		hp.value = u.progress
		hp.col = AMBER
	else:
		hp.value = clampf(u.hp / u.max_hp, 0.0, 1.0)
		hp.col = GREEN.lerp(RED, 1.0 - hp.value)
	var stats: Label = _info_live.get("stats")
	var status: Label = _info_live["status"]
	if u is Soldier:
		var stt: String = {"idle": "BEKLEMEDE", "move": "İLERLİYOR", "wounded": "YARALI", "dragged": "SÜRÜKLENİYOR", "healing": "TEDAVİDE", "rescue": "YARALIYA KOŞUYOR", "drag": "YARALI TAŞIYOR", "heal": "TEDAVİ EDİYOR", "build": "İNŞA EDİYOR", "throw": "EL BOMBASI", "dazed": "SERSEM", "fly": "SAVRULDU", "dive": "SİPER ALIYOR", "surrender": "TESLİM OLDU", "prisoner": "ESİR", "aboard": "ARAÇTA"}.get(u.state, "BEKLEMEDE")
		if u.state == "idle" and u.cover_type > 0:
			stt = "SİPERDE"
		if u.retreating:
			stt = "GERİ ÇEKİLİYOR"
		elif u.order == "hold" and u.state == "idle":
			stt = "MEVZİDE"
		var tm := "SAKİN" if u.suppression < 30 else ("GERGİN" if u.suppression < 70 else "BASTIRILDI")
		if u.stress_lv > 0:
			tm = "PANİK" if u.stress_lv == 2 else "SARSILMIŞ"
		if u.cold >= 50.0:
			tm += "  ·  " + I18n.s("DONUYOR" if u.cold >= 90.0 else "ÜŞÜYOR")
		stats.text = "%s %d   ·   %s %d   ·   %s %d   ·   %s %d" % [I18n.s("MERMİ"), u.ammo, I18n.s("BOMBA"), u.grenades, I18n.s("YARALANMA"), u.downs, I18n.s("STRES"), int(u.stress)]
		status.text = "%s   ·   %s" % [I18n.s(stt), I18n.s(tm)]
		status.add_theme_color_override("font_color", RED if u.suppression >= 70 or u.stress_lv == 2 or u.incapacitated() else (AMBER if u.suppression >= 30 or u.stress_lv == 1 else GREEN))
	elif u is Vehicle:
		var parts: Array = ["%s %d / %d" % [I18n.s("GÖVDE"), int(u.hp), int(u.max_hp)]]
		if not u.armor_tab().is_empty():
			# ön/yan/arka/üst kinetik zırh, mm RHA eşdeğeri (roadmap 51)
			var ar: Array = u.armor_tab()[0]
			parts.append("%s %d·%d·%d·%d mm" % [I18n.s("ZIRH"), int(ar[0] * 20.0), int(ar[1] * 20.0), int(ar[2] * 20.0), int(ar[3] * 20.0)])
		var rg: float = u._range()
		if rg > 0.0:
			# en uzun silahın oyundaki menzili (harita ölçeğinde; 8 km haritada gerçek)
			parts.append("%s %s" % [I18n.s("MENZİL"), ("%.1f km" % (rg / 1000.0)) if rg >= 1000.0 else ("%d m" % int(rg))])
		if u.crew_max > 0:
			parts.append("%s %d/%d" % [I18n.s("MÜRETTEBAT"), u.crew_n, u.crew_max])
		if u.capacity() > 0:
			parts.append(I18n.s("YOLCU %d / %d") % [u.cargo.size(), u.capacity()])
		if u.has_smoke():
			parts.append("%s %d" % [I18n.s("Sis").to_upper(), u.smoke_charges])
		stats.text = "  ·  ".join(parts)
		var s2 := ""
		var probs: Array = []
		if u.tracks_broken > 0.0:
			probs.append(I18n.s("PALET KOPUK") + " %d" % int(u.tracks_broken))
		if u.tires > 0:
			probs.append(I18n.s("%d TEKER PATLAK") % u.tires)
		if not u.driver_ok:
			probs.append(I18n.s("SÜRÜCÜ YOK"))
		if not u.gunner_ok and u.gunner:
			probs.append(I18n.s("NİŞANCI YOK"))
		if u.abandon_t >= 0.0:
			probs.append(I18n.s("İMHA EDİLİYOR") + " %d" % int(u.abandon_t + 1))
		if u.needs_setup() and u.deployed < 1.0:
			probs.append((I18n.s("TOPLANIYOR") if absf(u.cur_speed) < 0.1 and u.path_i < u.path.size() else I18n.s("KURULUYOR")) + " %%%d" % int(u.deployed * 100))
		for ck in u.crit:
			if u.crit[ck] > 0:
				probs.append(I18n.s(Vehicle.CRIT_NAME[ck]) + (" ●" if u.crit[ck] == 1 else " ●●"))
		if u.vstress_lv > 0:
			probs.append(I18n.s("PANİK" if u.vstress_lv == 2 else "SARSILMIŞ"))
		if not probs.is_empty():
			s2 = "  ·  ".join(probs)
		elif u.retreating and s2 == "":
			s2 = I18n.s("GERİ ÇEKİLİYOR")
		elif G.time - u.last_hit < 4.0 or u.target != null:
			s2 = I18n.s("ÇATIŞMADA")
		else:
			s2 = I18n.s("HAZIR")
		status.text = s2
		status.add_theme_color_override("font_color", RED if (not probs.is_empty() or u.target != null) else GREEN)
	elif u is Building:
		var q := ""
		if not u.done:
			q = "%s %%%d" % [I18n.s("İNŞA"), int(u.progress * 100)]
		elif not u.queue.is_empty():
			var it: Dictionary = u.queue[0]
			var P: Dictionary = Building.PDEF[it["id"]]
			q = "%s: %s %%%d%s" % [I18n.s("ÜRETİM"), I18n.s(P["title"]).to_upper(), int(it["t"] / P["time"] * 100), ("  ·  " + I18n.s("BİRLİK SINIRI")) if it.get("blocked", false) else ""]
		else:
			q = "%s %%%d" % [I18n.s("SAĞLAM"), int(u.hp / u.max_hp * 100)]
		if u.btype == "fob" and u.done:
			q += "  ·  %s %d / %d kg" % [I18n.s("STOK"), int(u.stock), int(Building.STOCK_MAX)]
		status.text = q
		var qsig := ""
		for it in u.queue:
			qsig += it["id"] + ","
		if qsig != _info_live["qsig"]:
			_info_live["qsig"] = qsig
			var qb: HBoxContainer = _info_live["queue"]
			_clear(qb)
			for k in mini(u.queue.size(), 8):
				var id: String = u.queue[k]["id"]
				var kk := k
				var bb := Button.new()
				bb.custom_minimum_size = Vector2(52, 40)
				bb.focus_mode = Control.FOCUS_NONE
				var tr := TextureRect.new()
				tr.texture = thumbs.get_thumb(id, u.team)
				tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
				tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
				tr.set_anchors_preset(Control.PRESET_FULL_RECT)
				tr.offset_left = 2
				tr.offset_top = 2
				tr.offset_right = -2
				tr.offset_bottom = -2
				tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
				bb.add_child(tr)
				var bld: Building = u
				bb.pressed.connect(func(): _cancel_queue(bld, kk))
				qb.add_child(bb)

func _cancel_queue(b: Building, k: int) -> void:
	if not is_instance_valid(b) or k >= b.queue.size():
		return
	var id: String = b.queue[k]["id"]
	b.queue.remove_at(k)
	G.supply[b.team] += Building.PDEF[id]["cost"]
	Sfx.play2d("ui_click", -8.0)

func promoted(s: Soldier) -> void:
	promoted_text("TERFİ", s.display_name().to_upper())

func promoted_text(a: String, b: String) -> void:
	var pc := PanelContainer.new()
	var sb := _sb(Color(0.04, 0.042, 0.04, 0.9), Color(1, 1, 1, 0.08))
	sb.content_margin_left = 10
	sb.content_margin_right = 14
	sb.content_margin_top = 3
	sb.content_margin_bottom = 3
	sb.border_width_left = 3
	sb.border_color = AMBER
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var hb := HBoxContainer.new()
	hb.add_theme_constant_override("separation", 10)
	pc.add_child(hb)
	_label(hb, a, 13, AMBER, font_m)
	var bl := _label(hb, "", 15, TXT, font_b)
	bl.text = b
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

# ------------------------------------------------------------ üretim paneli
func _build_prod() -> void:
	prod = PanelContainer.new()
	prod.anchor_left = 1.0
	prod.anchor_right = 1.0
	prod.anchor_top = 1.0
	prod.anchor_bottom = 1.0
	prod.offset_left = -PRW - GAP
	prod.offset_right = -GAP
	prod.offset_top = -PH - GAP
	prod.offset_bottom = -GAP
	prod.mouse_filter = Control.MOUSE_FILTER_STOP
	root.add_child(prod)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 7)
	prod.add_child(v)
	tabs = HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 3)
	v.add_child(tabs)
	for t in [["base", "ÜS"], ["def", "SAVUNMA"], ["inf", "PİYADE"], ["armor", "ZIRH"], ["art", "TOPÇU"], ["air", "HAVA"]]:
		var b := Button.new()
		b.text = I18n.s(t[1])
		b.toggle_mode = true
		b.focus_mode = Control.FOCUS_NONE
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		b.custom_minimum_size = Vector2(0, 26)
		b.add_theme_font_override("font", font_b)
		b.add_theme_font_size_override("font_size", 14)
		var key: String = t[0]
		b.set_meta("tab", key)
		b.pressed.connect(func(): set_tab(key))
		tabs.add_child(b)
	var sc := ScrollContainer.new()
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	v.add_child(sc)
	cards = GridContainer.new()
	cards.columns = 4
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 4)
	cards.add_theme_constant_override("v_separation", 4)
	sc.add_child(cards)

func set_tab(t: String) -> void:
	tab = t
	_tab_sig = ""
	Sfx.play2d("ui_click", -10.0)

const TAB_CATS := {"armor": ["tank", "ifv", "apc", "td", "mrap", "light", "eng"], "art": ["spg", "towed", "mlrs", "mortar", "aa", "coastal"], "air": ["heli_atk", "heli_tr", "uav", "loiter"]}

func _tab_items() -> Array:
	Catalog.load_all()
	if TAB_CATS.has(tab):
		var nat: String = G.nation[G.player_team] if G.player_team < G.nation.size() else "usa"
		var out: Array = []
		for c in TAB_CATS[tab]:
			for e in Catalog.order:
				if e[0] == nat and e[1] == c and Building.PDEF.has(e[2]):
					out.append(e[2])
		if not out.is_empty():
			if tab == "art":
				out.append_array(["fieldgun", "hmortar"])
			if tab == "air":
				out.append("para_squad")
			return out
	match tab:
		"base":
			return ["fob", "barracks", "factory", "helipad", "hospital"]
		"def":
			return ["sandbags", "concrete", "trench", "wire", "trap", "mgnest", "tower", "coastal"]
		"inf":
			return ["rifle_squad", "mg_team", "at_squad", "atgm_team", "medic_team", "sniper_team", "engineer_squad", "mortar_team", "drone_team"]
		"armor":
			return ["technical", "apc", "ifv", "aa", "tank"]
		"art":
			return ["fieldgun", "howitzer", "atgun", "aagun", "hmortar", "mtngun", "arty", "mlrs"]
		"air":
			return ["heli", "transport", "para_squad"]
	return []

func _producer(id: String) -> Building:
	var best: Building = null
	var bq := 99
	for u in G.units:
		if not is_instance_valid(u) or not (u is Building) or u.team != G.player_team or not u.alive or not u.done:
			continue
		if not u.can_produce(id):
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
	for b in tabs.get_children():
		b.button_pressed = b.get_meta("tab") == tab
	for id in _tab_items():
		cards.add_child(_card(id))

func _card(id: String) -> Control:
	var is_b: bool = Building.BDEF.has(id)
	var D: Dictionary = Building.BDEF[id] if is_b else Building.PDEF[id]
	var btn := Button.new()
	btn.custom_minimum_size = Vector2(100, 74)
	var cs := StyleBoxFlat.new()
	cs.bg_color = Color(0.09, 0.1, 0.09, 0.95)
	cs.border_color = Color(1, 1, 1, 0.08)
	cs.set_border_width_all(1)
	cs.set_corner_radius_all(3)
	btn.add_theme_stylebox_override("normal", cs)
	var ch := cs.duplicate()
	ch.border_color = Color(0.95, 0.75, 0.3, 0.8)
	btn.add_theme_stylebox_override("hover", ch)
	btn.add_theme_stylebox_override("pressed", ch)
	btn.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	btn.clip_contents = true
	btn.focus_mode = Control.FOCUS_NONE
	var tr := TextureRect.new()
	tr.texture = thumbs.get_thumb(id, G.player_team)
	tr.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	tr.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	tr.set_anchors_preset(Control.PRESET_FULL_RECT)
	tr.offset_left = 2
	tr.offset_top = 2
	tr.offset_right = -2
	tr.offset_bottom = -2
	tr.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(tr)
	var shade := ColorRect.new()
	shade.color = Color(0, 0, 0, 0.72)
	shade.anchor_top = 1.0
	shade.anchor_bottom = 1.0
	shade.anchor_right = 1.0
	shade.offset_top = -20
	shade.offset_left = 2
	shade.offset_right = -2
	shade.offset_bottom = -2
	shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(shade)
	var nm := Label.new()
	nm.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	nm.text = I18n.s(D["title"]).to_upper()
	nm.clip_text = true
	nm.add_theme_font_override("font", font_b)
	nm.add_theme_font_size_override("font_size", 11)
	nm.add_theme_color_override("font_color", Color(0.93, 0.92, 0.86))
	nm.anchor_top = 1.0
	nm.anchor_bottom = 1.0
	nm.anchor_right = 1.0
	nm.offset_top = -19
	nm.offset_left = 6
	nm.offset_right = -4
	nm.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(nm)
	var cost := Label.new()
	cost.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	var line: bool = D.get("line", false)
	cost.text = ("%d/m" % D["cost"]) if line else str(D["cost"])
	cost.add_theme_font_override("font", font_b)
	cost.add_theme_font_size_override("font_size", 14)
	cost.add_theme_color_override("font_color", AMBER)
	cost.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	cost.add_theme_constant_override("shadow_offset_y", 1)
	cost.anchor_left = 1.0
	cost.anchor_right = 1.0
	cost.offset_left = -60
	cost.offset_right = -6
	cost.offset_top = 2
	cost.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	cost.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(cost)
	var bar := ColorRect.new()
	bar.color = AMBER
	bar.anchor_top = 1.0
	bar.anchor_bottom = 1.0
	bar.offset_top = -22
	bar.offset_bottom = -20
	bar.offset_left = 2
	bar.offset_right = 2
	bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(bar)
	var qn := Label.new()
	qn.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	qn.add_theme_font_override("font", font_b)
	qn.add_theme_font_size_override("font_size", 19)
	qn.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	qn.add_theme_constant_override("shadow_offset_y", 1)
	qn.position = Vector2(7, 1)
	qn.mouse_filter = Control.MOUSE_FILTER_IGNORE
	btn.add_child(qn)
	_tip(btn, func():
		var desc: String = I18n.s(D.get("desc", "")) if is_b else I18n.s("%d ikmal · %d sn · %d birlik") % [D["cost"], int(D["time"]), D["cap"]]
		return "%s\n%s%s" % [I18n.s(D["title"]), desc, "" if is_b else "\n" + I18n.s("SAĞ TIK: İPTAL")])
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
					_cancel_queue(u, k)
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
			tr.modulate = Color(1, 1, 1) if G.supply[t] >= cost else Color(0.45, 0.45, 0.45)
			bar.offset_right = 2
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
			tr.modulate = Color(1, 1, 1) if (pb != null and G.supply[t] >= Building.PDEF[id]["cost"]) else Color(0.38, 0.38, 0.38)
			bar.offset_right = 2 + (btn.size.x - 4) * prog
			qn.text = str(n) if n > 0 else ""

# ------------------------------------------------------------ döngü
var _dep_lbl: Label = null
func _deploy_banner() -> void:
	if G.deploy_t <= 0.0:
		if _dep_lbl:
			_dep_lbl.visible = false
		return
	if _dep_lbl == null:
		_dep_lbl = _label(root, "", 22, AMBER, font_b)
		_dep_lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		_dep_lbl.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.8))
		_dep_lbl.add_theme_constant_override("shadow_offset_y", 2)
	_dep_lbl.visible = true
	_dep_lbl.size = Vector2(900, 30)
	_dep_lbl.position = Vector2(root.size.x * 0.5 - 450, 128)
	_dep_lbl.text = "%s  %d   ·   %s" % [I18n.s("KONUŞLANMA"), int(ceil(G.deploy_t)), I18n.s("birlik yerleştir, üretim hızlı · Enter: hazır").replace("Enter", Keybinds.label("deploy"))]

func _process(dt: float) -> void:
	_sweep += dt * 1.6
	var t := G.player_team
	var running := G.running and not G.spectate and menu == null
	top.visible = running
	mini.visible = running
	prod.visible = running
	if not running:
		unit_panel.visible = false
	if running:
		_layout()
		supply_lbl.text = str(int(G.supply[t]))
		_deploy_banner()
		var links := 0
		if G.logi:
			for tr in G.logi.trucks[t]:
				if is_instance_valid(tr) and tr.alive:
					links += 1
		link_lbl.text = ("▲ %d" % links) if links > 0 else "▼"
		link_lbl.add_theme_color_override("font_color", GREEN if links > 0 else RED)
		cap_lbl.text = "%d/%d" % [G.cap_used[t], G.cap_max[t]]
		cap_lbl.add_theme_color_override("font_color", RED if G.cap_used[t] >= G.cap_max[t] else TXT)
		var s := int(G.time)
		time_lbl.text = "%02d:%02d%s" % [s / 60, s % 60, "" if Engine.time_scale <= 1.0 else "  ×%d" % int(Engine.time_scale)]
		var ts := tab + G.map_kind + I18n.lang
		if ts != _tab_sig:
			_tab_sig = ts
			_rebuild_cards()
		_update_cards()
		var sel: Array = G.player.selected
		unit_panel.visible = not sel.is_empty()
		var sig := ""
		for u in sel:
			sig += str(u.get_instance_id()) + ","
		if sel.size() == 1 and sel[0] is Soldier:
			sig += "r%d" % sel[0].rank
		if sig != _sel_sig:
			_sel_sig = sig
			call_deferred("_rebuild_info")
		var csig := sig + "k%d" % Keybinds.version
		for id in ORDER_SEQ:
			csig += str(order_state(id, sel) >= 0)
		if csig != _cmd_sig:
			_cmd_sig = csig
			_rebuild_cmds()
		_update_info()
		_update_cmds()
	if tooltip.visible:
		var m := root.get_viewport().get_mouse_position()
		var vs := root.get_viewport_rect().size
		tooltip.position = Vector2(clampf(m.x - tooltip.size.x * 0.5, 8, vs.x - tooltip.size.x - 8), m.y - tooltip.size.y - 16)
		if _tip_owner == null or not is_instance_valid(_tip_owner) or not _tip_owner.is_visible_in_tree():
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

func _on_alert(text: String, pos: Vector3, team: int) -> void:
	if G.spectate or team != G.player_team:
		return
	var pc := PanelContainer.new()
	var sb := _sb(Color(0.03, 0.032, 0.03, 0.78), Color(0, 0, 0, 0))
	sb.border_width_left = 2
	sb.border_color = AMBER
	sb.content_margin_left = 9
	sb.content_margin_right = 12
	sb.content_margin_top = 2
	sb.content_margin_bottom = 3
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var l := _label(pc, "", 16, TXT, font_m)
	l.text = I18n.s(text)
	alerts.add_child(pc)
	_toast.append([pc, 5.0, pos])
	while alerts.get_child_count() > 6:
		var f := alerts.get_child(0)
		for e in _toast:
			if e[0] == f:
				_toast.erase(e)
				break
		f.free()

# esirden gelen istihbarat: sohbet balonu tarzı
func intel(who: String, text: String, pos: Vector3) -> void:
	if G.spectate:
		return
	var pc := PanelContainer.new()
	var sb := _sb(Color(0.03, 0.04, 0.05, 0.9), Color(0.45, 0.7, 1.0, 0.35))
	sb.border_width_left = 3
	sb.border_color = Color(0.45, 0.7, 1.0)
	sb.content_margin_left = 10
	sb.content_margin_right = 14
	sb.content_margin_top = 4
	sb.content_margin_bottom = 5
	pc.add_theme_stylebox_override("panel", sb)
	pc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var h := _label(v, "", 12, Color(0.55, 0.75, 1.0), font_b)
	h.text = "%s  ·  %s" % [I18n.s("İSTİHBARAT"), I18n.s("ESİR").to_upper()]
	who = who
	var l := _label(v, "", 16, TXT, font_m)
	l.text = "“%s”" % text
	alerts.add_child(pc)
	_toast.append([pc, 10.0, pos])
	Sfx.play2d("ui_alert", -8.0)
	while alerts.get_child_count() > 6:
		var f := alerts.get_child(0)
		for e in _toast:
			if e[0] == f:
				_toast.erase(e)
				break
		f.free()

# ------------------------------------------------------------ menüler
# ana menü scripts/main_menu.gd'de (Kampanya, Klasik Harita, Sandbox Test, Senaryo
# Oluşturucu, Ayarlar, Masaüstüne Çık)
func show_menu() -> MainMenu:
	if menu:
		menu.queue_free()
	var mm := MainMenu.new()
	mm.hud = self
	menu = mm
	root.add_child(mm)
	return mm

func _menu_btn(parent: Control, text: String, cb: Callable, tip := "") -> Button:
	var b := Button.new()
	b.text = I18n.s(text)
	b.custom_minimum_size = Vector2(360, 50)
	b.add_theme_font_size_override("font_size", 24)
	b.add_theme_font_override("font", font_b)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.pressed.connect(func():
		Sfx.play2d("ui_click", -4.0)
		cb.call())
	if tip != "":
		_tip(b, func(): return tip)
	parent.add_child(b)
	return b

func hide_menu() -> void:
	if menu:
		menu.queue_free()
		menu = null
	tooltip.visible = false

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
	var qb := _menu_btn(vb, "", func(): _confirm_quit(pause_menu))
	qb.text = MainMenu.t("MASAÜSTÜNE ÇIK")

# duraklatma menüsünden çıkış: onay kutusu (İPTAL kutuyu kapatır)
func _confirm_quit(parent: Control) -> void:
	if parent == null:
		return
	if parent.has_meta("confirm") and is_instance_valid(parent.get_meta("confirm")):
		return
	parent.set_meta("confirm", MainMenu.make_confirm(self, parent, "MASAÜSTÜNE ÇIK", "Oyun kapatılsın mı?", "ÇIK", func(): get_tree().quit(), Callable()))

func _center_box(title: String) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	root.add_child(c)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.55)
	c.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(cc)
	var pc := PanelContainer.new()
	var sb := _sb(BG, EDGE)
	sb.set_content_margin_all(22)
	pc.add_theme_stylebox_override("panel", sb)
	cc.add_child(pc)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 8)
	pc.add_child(vb)
	_label(vb, title, 40, AMBER, font_b).horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	c.set_meta("vb", vb)
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
	_label(vb, "", 19).text = I18n.s("Süre: %02d:%02d") % [int(G.time) / 60, int(G.time) % 60]
	_label(vb, "", 19).text = I18n.s("Etkisiz hâle getirilen düşman: %d") % G.stats["kills"][t]
	_label(vb, "", 19).text = I18n.s("Kayıplar: %d") % G.stats["lost"][t]
	_label(vb, "", 19).text = I18n.s("Tamamlanan yapı: %d") % G.stats["built"][t]
	_label(vb, "", 19).text = I18n.s("Alınan esir: %d") % G.stats.get("pows", [0, 0])[t]
	_menu_btn(vb, "ANA MENÜ", func():
		over_menu.queue_free()
		over_menu = null
		G.main.to_menu())
	Sfx.play2d("win" if win else "lose", -2.0)

# ============================================================ küçük bileşenler
class Bar extends Control:
	var value := 1.0
	var col := Color(0.5, 0.9, 0.55)

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.08))
		draw_rect(Rect2(Vector2.ZERO, Vector2(size.x * clampf(value, 0.0, 1.0), size.y)), col)

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
		var y := 7.0
		var n := Soldier.RANK_S.size()
		var r := soldier.rank
		var frac := 0.0
		if r < n - 1:
			frac = clampf(float(soldier.xp - Soldier.RANK_XP[r]) / float(Soldier.RANK_XP[r + 1] - Soldier.RANK_XP[r]), 0.0, 1.0)
		var x0 := 6.0
		var x1 := w - 70.0
		draw_line(Vector2(x0, y), Vector2(x1, y), Color(1, 1, 1, 0.14), 2.0)
		var px := x0 + (x1 - x0) * (float(r) + frac) / float(n - 1)
		draw_line(Vector2(x0, y), Vector2(px, y), Hud.AMBER, 2.0)
		for i in n:
			var x := x0 + (x1 - x0) * float(i) / float(n - 1)
			var c := Hud.AMBER if i <= r else Color(0.42, 0.42, 0.4)
			var pts := PackedVector2Array([Vector2(x, y - 5), Vector2(x + 5, y), Vector2(x, y + 5), Vector2(x - 5, y)])
			if i <= r:
				draw_colored_polygon(pts, c)
			else:
				pts.append(pts[0])
				draw_polyline(pts, c, 1.2)
			draw_string(hud.font_m, Vector2(x - 14, y + 20), I18n.s(Soldier.RANK_S[i]), HORIZONTAL_ALIGNMENT_CENTER, 28, 11, c)
		var nx: int = Soldier.RANK_XP[mini(r + 1, n - 1)]
		draw_string(hud.font_b, Vector2(x1 + 10, y + 5), "%d/%d XP" % [soldier.xp, nx], HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(0.75, 0.74, 0.7))

# grup seçiminde birim simgesi
class Chip extends Control:
	var hud: Hud
	var u: Unit

	func _ready() -> void:
		mouse_filter = Control.MOUSE_FILTER_STOP

	func _process(_dt: float) -> void:
		queue_redraw()

	func _gui_input(e: InputEvent) -> void:
		if e is InputEventMouseButton and e.pressed and e.button_index == MOUSE_BUTTON_LEFT and is_instance_valid(u) and u.alive:
			G.player.clear_sel()
			G.player.select(u)
			if (e as InputEventMouseButton).double_click:
				G.cam.jump_to(u.position)
			accept_event()

	func _draw() -> void:
		if not is_instance_valid(u):
			return
		var hov := get_global_rect().has_point(get_viewport().get_mouse_position())
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.09 if hov else 0.045))
		draw_rect(Rect2(Vector2.ZERO, size), Color(1, 1, 1, 0.1), false, 1.0)
		var c := Vector2(size.x * 0.5, size.y * 0.42)
		var col := Color(0.9, 0.9, 0.86)
		if not u.alive:
			col = Color(0.4, 0.4, 0.4)
		elif u is Soldier and u.incapacitated():
			col = Hud.RED
		if u is Soldier:
			CmdIcon.role_glyph(self, u.role, c, 13.0, col)
		elif u is Vehicle:
			CmdIcon.veh_glyph(self, c, 15.0, col)
		var fr := clampf(u.hp / u.max_hp, 0.0, 1.0) if u.alive else 0.0
		draw_rect(Rect2(4, size.y - 8, size.x - 8, 3), Color(1, 1, 1, 0.1))
		draw_rect(Rect2(4, size.y - 8, (size.x - 8) * fr, 3), Hud.GREEN.lerp(Hud.RED, 1.0 - fr))
		if u is Soldier and u.rank > 0:
			for k in u.rank:
				draw_line(Vector2(size.x - 9, 5 + k * 3), Vector2(size.x - 4, 5 + k * 3), Hud.AMBER, 1.5)

# emir simgeleri (vektör çizim)
class CmdIcon extends Control:
	var kind := ""
	var hud: Hud
	var active := false
	var variant := 0

	func _process(_dt: float) -> void:
		queue_redraw()

	func _draw() -> void:
		var c := size * 0.5 + Vector2(0, 2)
		var col := Hud.AMBER if active else Color(0.92, 0.91, 0.87)
		var p: Control = get_parent()
		if p is Button and (p as Button).disabled:
			col = Color(0.4, 0.4, 0.38)
		if active:
			draw_rect(Rect2(Vector2(1, 1), size - Vector2(2, 2)), Color(1, 0.74, 0.3, 0.9), false, 2.0)
		var w := 2.0
		match kind:
			"fastrope", "ropepick":
				# helikopter gövdesi + sarkan halat + ok
				draw_line(c + Vector2(-12, -9), c + Vector2(10, -9), col, w)
				draw_rect(Rect2(c + Vector2(-8, -8), Vector2(12, 5)), col)
				draw_line(c + Vector2(2, -3), c + Vector2(2, 12), col, 1.5)
				if kind == "fastrope":
					_arrow(c + Vector2(9, -2), c + Vector2(9, 11), col, 1.5)
				else:
					_arrow(c + Vector2(9, 11), c + Vector2(9, -2), col, 1.5)
			"minidrone":
				# quad: X kollar + 4 pervane halkası
				for sx in [-1.0, 1.0]:
					for sy in [-1.0, 1.0]:
						draw_line(c, c + Vector2(sx, sy) * 9.0, col, w)
						draw_arc(c + Vector2(sx, sy) * 9.0, 4.5, 0, TAU, 12, col, 1.2)
				draw_rect(Rect2(c - Vector2(3, 3), Vector2(6, 6)), col)
			"dronestation":
				# anten direği + yayılan dalgalar + rampa
				draw_line(c + Vector2(-6, 12), c + Vector2(-6, -8), col, w)
				draw_line(c + Vector2(-11, 12), c + Vector2(-6, 2), col, 1.2)
				draw_line(c + Vector2(-1, 12), c + Vector2(-6, 2), col, 1.2)
				draw_arc(c + Vector2(-6, -8), 5.0, -PI * 0.85, -PI * 0.15, 8, col, 1.2)
				draw_arc(c + Vector2(-6, -8), 9.0, -PI * 0.85, -PI * 0.15, 10, col, 1.2)
				draw_line(c + Vector2(2, 11), c + Vector2(13, 4), col, w)
			"move":
				_arrow(c + Vector2(-9, 7), c + Vector2(9, -7), col, w)
			"fast":
				_arrow(c + Vector2(-11, 5), c + Vector2(5, -9), col, w)
				_arrow(c + Vector2(-5, 9), c + Vector2(11, -5), col, w)
			"amove":
				_arrow(c + Vector2(-10, 8), c + Vector2(6, -6), col, w)
				draw_arc(c + Vector2(6, -6), 6.0, 0, TAU, 16, col, 1.5)
				draw_line(c + Vector2(6, -14), c + Vector2(6, 2), col, 1.2)
				draw_line(c + Vector2(-2, -6), c + Vector2(14, -6), col, 1.2)
			"reverse":
				_arrow(c + Vector2(8, -6), c + Vector2(-8, 8), col, w)
				draw_rect(Rect2(c + Vector2(2, -12), Vector2(10, 6)), col, false, 1.5)
			"stop":
				draw_rect(Rect2(c - Vector2(8, 8), Vector2(16, 16)), col, false, w)
				draw_rect(Rect2(c - Vector2(4, 4), Vector2(8, 8)), col)
			"hold":
				draw_line(c + Vector2(-9, 10), c + Vector2(9, 10), col, w)
				draw_line(c + Vector2(-4, 10), c + Vector2(-4, -10), col, w)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-4, -10), c + Vector2(9, -6), c + Vector2(-4, -2)]), col)
			"refund":
				draw_rect(Rect2(c + Vector2(-9, -2), Vector2(18, 11)), col, false, w)
				draw_polyline(PackedVector2Array([c + Vector2(-9, -2), c + Vector2(0, -11), c + Vector2(9, -2)]), col, w)
				draw_string(ThemeDB.fallback_font, c + Vector2(-4, 8), "$", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
			"retreat":
				draw_polyline(PackedVector2Array([c + Vector2(9, -8), c + Vector2(-3, -8), c + Vector2(-3, 8)]), col, w)
				draw_colored_polygon(PackedVector2Array([c + Vector2(-9, 2), c + Vector2(3, 2), c + Vector2(-3, 10)]), col)
			"fire":
				draw_arc(c, 9.0, 0, TAU, 20, col, 1.5)
				draw_line(c + Vector2(0, -13), c + Vector2(0, -5), col, 1.5)
				draw_line(c + Vector2(0, 5), c + Vector2(0, 13), col, 1.5)
				draw_line(c + Vector2(-13, 0), c + Vector2(-5, 0), col, 1.5)
				draw_line(c + Vector2(5, 0), c + Vector2(13, 0), col, 1.5)
				if variant == 2:
					draw_line(c + Vector2(-9, -9), c + Vector2(9, 9), Hud.RED, 2.0)
				elif variant == 1:
					draw_circle(c, 2.5, col)
			"stance":
				role_body(self, c, variant, col)
				if variant == 0:
					draw_string(hud.font_b, c + Vector2(5, 12), "A", HORIZONTAL_ALIGNMENT_LEFT, -1, 11, col)
			"unload":
				draw_rect(Rect2(c + Vector2(-12, -8), Vector2(14, 10)), col, false, 1.5)
				_arrow(c + Vector2(0, 2), c + Vector2(12, 10), col, w)
			"airdrop":
				draw_arc(c + Vector2(0, -4), 10.0, PI, TAU, 12, col, 1.5)
				draw_line(c + Vector2(-10, -4), c + Vector2(-3, 6), col, 1.2)
				draw_line(c + Vector2(10, -4), c + Vector2(3, 6), col, 1.2)
				draw_rect(Rect2(c + Vector2(-4, 5), Vector2(8, 7)), col)
			"grenade":
				draw_circle(c + Vector2(0, 3), 7.0, col)
				draw_rect(Rect2(c + Vector2(-3, -8), Vector2(6, 4)), col)
				draw_line(c + Vector2(3, -6), c + Vector2(9, -10), col, 1.5)
			"smoke":
				draw_circle(c + Vector2(-5, 3), 6.0, col)
				draw_circle(c + Vector2(4, 0), 7.0, col)
				draw_circle(c + Vector2(1, -6), 5.0, col)
			"suppress":
				for k in 3:
					var y0 := -7.0 + k * 7.0
					draw_line(c + Vector2(-12, y0), c + Vector2(6, y0), col, 1.5)
					draw_circle(c + Vector2(9, y0), 2.0, col)
			"demolish":
				draw_line(c + Vector2(-9, -9), c + Vector2(9, 9), col, 2.5)
				draw_line(c + Vector2(9, -9), c + Vector2(-9, 9), col, 2.5)

	func _arrow(a: Vector2, b: Vector2, col: Color, w: float) -> void:
		draw_line(a, b, col, w)
		var d := (b - a).normalized()
		var s := Vector2(-d.y, d.x)
		draw_colored_polygon(PackedVector2Array([b + d * 3.0, b - d * 6.0 + s * 4.5, b - d * 6.0 - s * 4.5]), col)

	static func role_body(ci: CanvasItem, c: Vector2, st: int, col: Color) -> void:
		match st:
			0, 1:
				ci.draw_circle(c + Vector2(0, -11), 3.0, col)
				ci.draw_line(c + Vector2(0, -8), c + Vector2(0, 3), col, 2.5)
				ci.draw_line(c + Vector2(0, 3), c + Vector2(-4, 12), col, 2.0)
				ci.draw_line(c + Vector2(0, 3), c + Vector2(4, 12), col, 2.0)
				ci.draw_line(c + Vector2(0, -5), c + Vector2(8, -6), col, 2.0)
			2:
				ci.draw_circle(c + Vector2(-1, -5), 3.0, col)
				ci.draw_line(c + Vector2(-1, -2), c + Vector2(-1, 5), col, 2.5)
				ci.draw_line(c + Vector2(-1, 5), c + Vector2(6, 6), col, 2.0)
				ci.draw_line(c + Vector2(6, 6), c + Vector2(4, 12), col, 2.0)
				ci.draw_line(c + Vector2(-1, 0), c + Vector2(8, -1), col, 2.0)
			3:
				ci.draw_circle(c + Vector2(-9, 4), 3.0, col)
				ci.draw_line(c + Vector2(-6, 6), c + Vector2(10, 8), col, 2.5)
				ci.draw_line(c + Vector2(-6, 5), c + Vector2(4, 3), col, 1.5)
		ci.draw_line(c + Vector2(-12, 13), c + Vector2(12, 13), Color(col.r, col.g, col.b, 0.35), 1.0)

	static func role_glyph(ci: CanvasItem, role: String, c: Vector2, r: float, col: Color) -> void:
		ci.draw_circle(c + Vector2(0, -r * 0.55), r * 0.28, col)
		ci.draw_rect(Rect2(c + Vector2(-r * 0.32, -r * 0.25), Vector2(r * 0.64, r * 0.9)), col)
		match role:
			"mg":
				ci.draw_line(c + Vector2(-r * 0.6, r * 0.05), c + Vector2(r * 1.1, r * 0.05), col, 2.5)
			"at":
				ci.draw_line(c + Vector2(-r * 0.7, -r * 0.35), c + Vector2(r * 1.0, -r * 0.35), col, 3.5)
			"medic":
				ci.draw_rect(Rect2(c + Vector2(-r * 0.12, -r * 0.15), Vector2(r * 0.24, r * 0.6)), Hud.RED)
				ci.draw_rect(Rect2(c + Vector2(-r * 0.3, r * 0.03), Vector2(r * 0.6, r * 0.24)), Hud.RED)
			"sniper":
				ci.draw_line(c + Vector2(-r * 0.5, 0), c + Vector2(r * 1.3, -r * 0.1), col, 1.5)
			"engineer":
				ci.draw_line(c + Vector2(r * 0.4, -r * 0.5), c + Vector2(r * 1.0, r * 0.4), col, 2.0)
				ci.draw_rect(Rect2(c + Vector2(r * 0.25, -r * 0.7), Vector2(r * 0.4, r * 0.25)), col)
			"mortar":
				ci.draw_line(c + Vector2(r * 0.4, r * 0.6), c + Vector2(r * 1.0, -r * 0.6), col, 3.0)
			"drone":
				ci.draw_line(c + Vector2(r * 0.4, -r * 0.8), c + Vector2(r * 1.2, -r * 0.8), col, 1.5)
				ci.draw_circle(c + Vector2(r * 0.8, -r * 0.8), r * 0.15, col)
			_:
				ci.draw_line(c + Vector2(-r * 0.5, r * 0.05), c + Vector2(r * 0.9, -r * 0.05), col, 2.0)

	static func veh_glyph(ci: CanvasItem, c: Vector2, r: float, col: Color) -> void:
		ci.draw_rect(Rect2(c + Vector2(-r, -r * 0.2), Vector2(r * 2.0, r * 0.7)), col)
		ci.draw_rect(Rect2(c + Vector2(-r * 0.45, -r * 0.6), Vector2(r * 0.9, r * 0.45)), col)
		ci.draw_line(c + Vector2(r * 0.3, -r * 0.4), c + Vector2(r * 1.2, -r * 0.4), col, 2.0)

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
				var col: Color = Color(0.55, 0.95, 0.65, 0.85) if own else Color(1.0, 0.45, 0.35, 0.85)
				var r: float = 0.38 if u is Soldier else u.radius + 0.3
				if u is Building:
					r = u.radius * 0.95
				_ellipse(p, r, col, 1.0 if u is Soldier else 1.4)
				if not (u is Soldier):
					_brackets(p, r, col)
			# can çubuğu
			var show_bar: bool = u.selected or (G.time - u.last_hit < 3.0 and u.hp < u.max_hp)
			if u is Building and not u.done:
				show_bar = true
			if show_bar and not (u is Soldier and u.incapacitated()):
				var topy: float = 2.0 if u is Soldier else (3.2 if u is Vehicle else 4.5)
				var s := cam.screen(p + Vector3(0, topy, 0))
				var w: float = clampf(u.radius * px * 1.6, 22.0, 90.0)
				var fr: float = clampf(u.hp / u.max_hp, 0.0, 1.0)
				var c := Color(0.3, 0.9, 0.4).lerp(Color(1.0, 0.25, 0.15), 1.0 - fr)
				if u is Building and not u.done:
					fr = u.progress
					c = Color(1.0, 0.78, 0.3)
				draw_rect(Rect2(s.x - w * 0.5 - 1, s.y - 1, w + 2, 5), Color(0, 0, 0, 0.7))
				draw_rect(Rect2(s.x - w * 0.5, s.y, w * fr, 3), c)
				if u is Soldier and own and u.suppression > 30.0:
					draw_rect(Rect2(s.x - w * 0.5, s.y + 4, w * u.suppression / 100.0, 2), Color(1.0, 0.7, 0.2, 0.9))
			if u is Building and u.is_base() and u.capture_t > 0.1:
				var s2 := cam.screen(p + Vector3(0, 5.5, 0))
				draw_rect(Rect2(s2.x - 40, s2.y, 80, 5), Color(0, 0, 0, 0.7))
				draw_rect(Rect2(s2.x - 40, s2.y, 80 * u.capture_t / u.capture_time(), 5), G.TEAM_COL[u.capture_team])
				draw_string(f, s2 + Vector2(-40, -4), I18n.s("ELE GEÇİRİLİYOR"), HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.9))
			# yaralı simgesi
			if u is Soldier and u.state == "wounded" and (own or vt < 0):
				var s3 := cam.screen(p + Vector3(0, 1.0, 0))
				var blink := 0.6 + 0.4 * sin(G.time * 6.0)
				draw_rect(Rect2(s3.x - 6, s3.y - 2, 12, 4), Color(1, 0.2, 0.2, blink))
				draw_rect(Rect2(s3.x - 2, s3.y - 6, 4, 12), Color(1, 0.2, 0.2, blink))
			# seçili asker: nişan çizgisi + bilgi etiketi (rol · durum %)
			if u is Soldier and u.selected and own and u.alive and cam.size < 70.0:
				if u.target != null and is_instance_valid(u.target) and u.target.alive and u.can_fight():
					var a0 := cam.screen(u.position + Vector3(0, 1.3, 0))
					var a1 := cam.screen(u.target.aim_point())
					draw_line(a0, a1, Color(1.0, 0.85, 0.3, 0.55), 1.2, true)
				elif u.state == "move" and u.path_i < u.path.size():
					draw_line(cam.screen(u.position + Vector3(0, 0.05, 0)), cam.screen(u.dest + Vector3(0, 0.05, 0)), Color(0.4, 0.75, 1.0, 0.35), 1.0, true)
				var ls := cam.screen(p + Vector3(0, 2.6, 0))
				var role_s: String = {"rifle": "RFL", "mg": "LMG", "at": "AT", "medic": "MED", "sniper": "SNP", "engineer": "ENG", "mortar": "MRT", "drone": "UAV", "leader": "SL", "crew": "CRW"}.get(u.role, "INF")
				var st_s := ""
				var pct := -1
				match u.state:
					"heal":
						st_s = I18n.s("TEDAVİ")
						pct = int((1.0 - u.heal_t / (4.0 if u.role == "medic" else 8.0)) * 100.0)
					"healing", "wounded", "dragged":
						st_s = I18n.s("YARALI")
						pct = int(u.bleed)
					"build":
						st_s = I18n.s("İNŞA")
					"move":
						st_s = I18n.s("İLERLİYOR")
					_:
						if u.suppression > 5.0:
							st_s = I18n.s("BASKI")
							pct = int(u.suppression)
				var lc := Color(0.45, 0.72, 1.0, 0.95)
				draw_string(hud.font_b, ls + Vector2(-30, 0), role_s, HORIZONTAL_ALIGNMENT_CENTER, 60, 11, lc)
				if st_s != "":
					draw_string(hud.font_b, ls + Vector2(-50, 13), st_s + (" %d%%" % clampi(pct, 0, 100) if pct >= 0 else ""), HORIZONTAL_ALIGNMENT_CENTER, 100, 15, lc)
			# durum ikonları (baş üstünde koyu kutucuklar)
			if u is Soldier and u.alive and cam.size < 60.0 and (own or vt < 0):
				var icons: Array = []
				if u.state in ["wounded", "dragged"]:
					icons.append("medic")
				elif u.suppression > 70.0:
					icons.append("pinned")
				elif G.time - u.sup_t < 2.0 or G.time - u.last_hit < 2.0:
					icons.append("fire")
				if u.role == "leader" and u.can_fight():
					icons.append("radio")
				if u.state == "build":
					icons.append("build")
				if not icons.is_empty():
					var hs := cam.screen(p + Vector3(0, 2.15, 0))
					for ii in icons.size():
						_status_icon(Vector2(hs.x + (ii - (icons.size() - 1) * 0.5) * 24.0, hs.y - (34.0 if u.bubble != "" else 0.0)), icons[ii])
			# konuşma balonu (yuvarlak, kenarlıklı, kuyruklu)
			if u.bubble != "" and cam.size < 75.0:
				var s4 := cam.screen(p + Vector3(0, 2.3, 0))
				var fb: Font = hud.font_b
				var txt: String = u.bubble.to_upper()
				var tw := fb.get_string_size(txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x
				var rect := Rect2(s4.x - tw * 0.5 - 9, s4.y - 30, tw + 18, 21)
				var a: float = clampf(u.bubble_t * 2.0, 0.0, 1.0)
				var enemy_side := not own and vt >= 0
				var bg := Color(0.97, 0.95, 0.9, 0.94 * a)
				var edge := Color(0.42, 0.36, 0.3, 0.85 * a)
				var tc := Color(0.62, 0.16, 0.1, a) if (u is Soldier and (u.state == "wounded" or u.suppression > 60.0)) else Color(0.25, 0.22, 0.2, a)
				if enemy_side:
					tc = Color(0.55, 0.12, 0.1, a)
				var sb := StyleBoxFlat.new()
				sb.bg_color = bg
				sb.border_color = edge
				sb.set_border_width_all(1)
				sb.set_corner_radius_all(10)
				sb.shadow_color = Color(0, 0, 0, 0.25 * a)
				sb.shadow_size = 3
				sb.shadow_offset = Vector2(1, 2)
				draw_style_box(sb, rect)
				var tl := PackedVector2Array([Vector2(s4.x - 6, rect.end.y - 1), Vector2(s4.x + 3, rect.end.y - 1), Vector2(s4.x - 4, rect.end.y + 7)])
				draw_colored_polygon(tl, bg)
				draw_polyline(PackedVector2Array([tl[0], tl[2], tl[1]]), edge, 1.0)
				draw_string(fb, Vector2(rect.position.x + 9, rect.position.y + 15), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, tc)
		# kutu seçimi
		if G.player and G.player.boxing:
			var r := Rect2(G.player.box_start, G.player.box_now - G.player.box_start).abs()
			if r.size.length() > 6.0:
				draw_rect(r, Color(0.45, 1.0, 0.6, 0.1))
				draw_rect(r, Color(0.45, 1.0, 0.6, 0.8), false, 1.0)
		var m := get_viewport().get_mouse_position()
		# hedefli emir
		if G.player and G.player.pending_order != "":
			var O: Dictionary = Hud.ORDERS[G.player.pending_order]
			var gp := cam.mouse_ground(m)
			var rr := 4.0 if G.player.pending_order in ["grenade", "suppress"] else (4.5 if G.player.pending_order == "smoke" else 1.5)
			_ellipse(gp, rr, Color(1.0, 0.74, 0.3, 0.9), 2.0)
			var hint := I18n.s("Hedef seç — sol tık: uygula · sağ tık: iptal")
			var hw := maxf(hud.font_m.get_string_size(hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13).x, 120.0)
			draw_rect(Rect2(m + Vector2(12, 10), Vector2(hw + 14, 40)), Color(0, 0, 0, 0.6))
			draw_string(hud.font_b, m + Vector2(18, 26), I18n.s(O["t"]).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Hud.AMBER)
			draw_string(hud.font_m, m + Vector2(18, 43), hint, HORIZONTAL_ALIGNMENT_LEFT, -1, 13, Color(1, 1, 1, 0.85))
		# yerleştirme ipucu
		if G.player and G.player.place_type != "":
			var B: Dictionary = Building.BDEF[G.player.place_type]
			var txt: String = I18n.s(B["title"])
			if B.get("line", false):
				if G.player.place_a == Vector3.INF:
					txt += "  — " + I18n.s("tıkla: başlangıç, tıkla: bitiş")
				else:
					txt += "  — " + I18n.s("%d ikmal") % int(ceil(B["cost"] * minf(30.0, G.player.place_a.distance_to(cam.mouse_ground(m)))))
			else:
				var why := PlayerCtl.can_place(G.player.place_type, cam.mouse_ground(m), G.player.place_rot, G.player_team)
				txt += "  — " + I18n.s("%d ikmal") % B["cost"] + (("  ·  " + I18n.s(why)) if why != "" else "") + "   " + I18n.s("[R] döndür").replace("[R]", "[%s]" % Keybinds.short("place.rot"))
			draw_string(f, m + Vector2(18, 30), txt, HORIZONTAL_ALIGNMENT_LEFT, -1, 16, Color(1, 1, 1, 0.95))

	func _status_icon(c: Vector2, kind: String) -> void:
		var r := Rect2(c - Vector2(10, 10), Vector2(20, 20))
		var sb := StyleBoxFlat.new()
		sb.bg_color = Color(0.22, 0.25, 0.28, 0.88)
		sb.set_corner_radius_all(4)
		sb.border_color = Color(1, 1, 1, 0.25)
		sb.set_border_width_all(1)
		draw_style_box(sb, r)
		draw_colored_polygon(PackedVector2Array([c + Vector2(-4, 10), c + Vector2(4, 10), c + Vector2(0, 15)]), Color(0.22, 0.25, 0.28, 0.88))
		var w := Color(0.92, 0.94, 0.95)
		match kind:
			"medic":
				draw_rect(Rect2(c - Vector2(2, 6), Vector2(4, 12)), Color(1, 0.35, 0.3))
				draw_rect(Rect2(c - Vector2(6, 2), Vector2(12, 4)), Color(1, 0.35, 0.3))
			"pinned":
				draw_polyline(PackedVector2Array([c + Vector2(-6, -1), c + Vector2(0, 5), c + Vector2(6, -1)]), w, 2.0)
				draw_polyline(PackedVector2Array([c + Vector2(-6, -6), c + Vector2(0, 0), c + Vector2(6, -6)]), w, 2.0)
			"fire":
				draw_rect(Rect2(c - Vector2(1.5, 6), Vector2(3, 8)), Color(1, 0.75, 0.3))
				draw_rect(Rect2(c + Vector2(-1.5, 4), Vector2(3, 3)), Color(1, 0.75, 0.3))
			"radio":
				draw_rect(Rect2(c - Vector2(5, 3), Vector2(10, 8)), Color(0, 0, 0, 0), false, 1.6)
				draw_line(c + Vector2(-3, -3), c + Vector2(-3, -8), w, 1.4)
				draw_rect(Rect2(c - Vector2(3, 1), Vector2(6, 3)), w)
			"build":
				draw_line(c + Vector2(-5, 5), c + Vector2(4, -4), w, 2.0)
				draw_rect(Rect2(c + Vector2(1, -7), Vector2(6, 4)), w)

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

# ============================================================ harita
class Radar extends Control:
	var hud: Hud
	var R := 100.0
	var tex: ImageTexture = null
	var tex_for := 0

	func _rect() -> Rect2:
		var s := minf(size.x, size.y) - 8.0
		return Rect2((size - Vector2(s, s)) * 0.5, Vector2(s, s))

	func w2r(p: Vector3) -> Vector2:
		var r := _rect()
		return r.position + Vector2(p.x / G.MAP, p.z / G.MAP) * r.size

	func r2w(s: Vector2) -> Vector3:
		var r := _rect()
		var k := (s - r.position) / r.size
		return Vector3(clampf(k.x, 0, 1) * G.MAP, 0, clampf(k.y, 0, 1) * G.MAP)

	# arazi görüntüsü: zemin tonu + tepe gölgesi, su, ağaçlık, yapılar, yollar
	func _build_tex() -> void:
		var n := 192
		var img := Image.create(n, n, false, Image.FORMAT_RGB8)
		var base := Color(0.86, 0.72, 0.46) if G.map_kind == "desert" else (Color(0.86, 0.89, 0.92) if G.map_kind == "winter" else Color(0.42, 0.56, 0.26))
		var cs := G.MAP / n
		for z in n:
			for x in n:
				var p := Vector3((x + 0.5) * cs, 0, (z + 0.5) * cs)
				var col := base
				var h0 := G.terrain.ground_h(p)
				var hx := G.terrain.ground_h(p + Vector3(cs, 0, 0))
				var hz := G.terrain.ground_h(p + Vector3(0, 0, cs))
				col = col.lightened(clampf((h0 - hx + h0 - hz) * 1.6, -0.3, 0.3)) if (h0 - hx + h0 - hz) > 0 else col.darkened(clampf(-(h0 - hx + h0 - hz) * 1.6, 0.0, 0.3))
				var gi := G.grid.idx(p)
				if G.grid.water[gi] >= 1 and G.grid.bridge[gi] == 0:
					col = Color(0.16, 0.42, 0.55)
				elif G.grid.kind[gi] == Grid.K_TREE:
					col = Color(0.16, 0.34, 0.14)
				elif G.grid.h[gi] >= 0.3:
					col = Color(0.78, 0.5, 0.36) if G.grid.kind[gi] == Grid.K_HOUSE else Color(0.6, 0.56, 0.5)
				elif G.grid.h[gi] > 0.05:
					col = col.lightened(0.15)
				img.set_pixel(x, z, col)
		tex = ImageTexture.create_from_image(img)
		tex_for = G.terrain.get_instance_id()

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
		if not G.running or G.cam == null:
			return
		var f: Font = hud.font
		draw_rect(Rect2(Vector2.ZERO, size), Color(0.03, 0.035, 0.034, 0.9))
		if G.terrain and (tex == null or tex_for != G.terrain.get_instance_id()):
			_build_tex()
		var rr := _rect()
		if tex:
			draw_texture_rect(tex, rr, false, Color(0.92, 0.92, 0.92))
		for i in range(1, 4):
			var t := G.MAP * i / 4.0
			draw_line(w2r(Vector3(t, 0, 0)), w2r(Vector3(t, 0, G.MAP)), Color(0, 0, 0, 0.18), 1.0)
			draw_line(w2r(Vector3(0, 0, t)), w2r(Vector3(G.MAP, 0, t)), Color(0, 0, 0, 0.18), 1.0)
		draw_rect(rr, Color(1, 1, 1, 0.25), false, 1.0)
		# hedef bölgeler
		if G.modes != null and is_instance_valid(G.modes):
			for z in G.modes.zones:
				var zc: Color = G.TEAM_COL[z["owner"]] if z["owner"] >= 0 else Color(0.9, 0.9, 0.85)
				draw_arc(w2r(z["p"]), 6.0, 0, TAU, 16, zc, 1.5)
				draw_string(hud.font_b, w2r(z["p"]) + Vector2(-4, 4), z["name"], HORIZONTAL_ALIGNMENT_LEFT, -1, 10, zc)
		# yollar
		if G.logi:
			for t in 2:
				for n in G.logi.nodes[t]:
					var r: PackedVector3Array = n["route"]
					for i in r.size() - 1:
						draw_line(w2r(r[i]), w2r(r[i + 1]), Color(0.85, 0.8, 0.6, 0.4), 1.2)
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
				if u.is_air():
					draw_colored_polygon(PackedVector2Array([p + Vector2(0, -4), p + Vector2(3.5, 3), p + Vector2(-3.5, 3)]), col.lightened(0.2))
				else:
					draw_rect(Rect2(p - Vector2(2.6, 2.6), Vector2(5.2, 5.2)), Color(0, 0, 0, 0.7))
					draw_rect(Rect2(p - Vector2(2, 2), Vector2(4, 4)), col.lightened(0.15))
			else:
				draw_circle(p, 1.6, col.lightened(0.1))
		# kamera görüş alanı
		var vp := get_viewport_rect().size
		var q := PackedVector2Array()
		for s in [Vector2(0, 0), Vector2(vp.x, 0), Vector2(vp.x, vp.y), Vector2(0, vp.y), Vector2(0, 0)]:
			q.append(w2r(G.cam.mouse_ground(s)))
		draw_polyline(q, Color(1, 1, 1, 0.75), 1.0)
		# uyarı pingleri
		for e in hud._toast:
			if e[2] != Vector3.ZERO and e[1] > 3.0:
				var k: float = fmod(e[1] * 2.0, 1.0)
				draw_arc(w2r(e[2]), 4.0 + k * 10.0, 0, TAU, 16, Color(1, 0.74, 0.3, k), 1.5)
		draw_string(hud.font_b, Vector2(8, 16), I18n.s("HARİTA"), HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.45))
		draw_string(f, Vector2(size.x - 8 - 60, 16), "%dM" % int(G.MAP), HORIZONTAL_ALIGNMENT_RIGHT, 60, 11, Color(1, 1, 1, 0.35))
