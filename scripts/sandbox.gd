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

var ROLES: Array = Soldier.WPN.keys()
var search: LineEdit
# efekt denemesi (roadmap 125): imleçte patlama / mühimmat / ortam efektleri
const FX := ["boom_s", "rpg", "mortar", "mine", "boom_m", "boom_l", "arty", "mlrs", "smoke", "fire", "fireball", "water", "crater", "flare"]
const FX_TITLE := {"boom_s": "El bombası", "rpg": "RPG isabeti", "mortar": "Havan mermisi", "mine": "Mayın", "boom_m": "Tank mermisi",
	"boom_l": "Büyük patlama", "arty": "Topçu atışı (6)", "mlrs": "Roketatar salvosu (12)", "smoke": "Sis perdesi", "fire": "Yangın (30 sn)",
	"fireball": "Ateş topu", "water": "Suya düşüş", "crater": "Krater izi", "flare": "Aydınlatma / parlama"}
# geliştirici araçları: imleçte tıklanan nesneye uygulanır
const TOOLS := ["del", "wreck", "tp", "info"]
const TOOL_TITLE := {"del": "Sil (imleçteki birim, patlamadan)", "wreck": "Yık (birim / yapı / ev / köprü)", "tp": "Işınla (seçili → imleç)", "info": "Bilgi (imleçteki birim)"}

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
	# birlik / yapı / efekt arama: liste anında süzülür (ad ya da kimlik, büyük-küçük harf duyarsız)
	search = LineEdit.new()
	search.placeholder_text = I18n.s("ara: birlik, yapı, efekt…")
	search.text_changed.connect(func(t): _filter(t))
	search.text_submitted.connect(func(_t): search.release_focus())
	v.add_child(search)
	var sc := ScrollContainer.new()
	sc.custom_minimum_size = Vector2(0, 360)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	v.add_child(sc)
	list = VBoxContainer.new()
	list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	list.add_theme_constant_override("separation", 2)
	sc.add_child(list)
	# listeler tanımlardan otomatik üretilir: yeni eklenen her birim burada görünür
	Catalog.load_all()
	_section("PİYADE TİMLERİ")
	for id in Building.PDEF:
		if not Building.PDEF[id].has("vehicle"):
			_spawn_btn("p:" + id, I18n.s(Building.PDEF[id]["title"]))
	_section("TEK ASKER")
	for r in Soldier.WPN:
		_spawn_btn("s:" + r, I18n.s(Soldier.ROLE_TITLE.get(r, r)))
	_section("KARA ARAÇLARI")
	for vt in Vehicle.DEF:
		if not (vt in Vehicle.TOWED or vt in Vehicle.INDIRECT) and not Vehicle.DEF[vt]["nav"] == -1 and not (vt in ["heli", "transport", "fpv"]):
			_spawn_btn("v:" + vt, I18n.s(Vehicle.DEF[vt]["title"]))
	_section("TOPÇU")
	for vt in Vehicle.DEF:
		if vt in Vehicle.TOWED or vt in Vehicle.INDIRECT:
			_spawn_btn("v:" + vt, I18n.s(Vehicle.DEF[vt]["title"]))
	_section("HAVA")
	for vt in ["heli", "transport", "fpv"]:
		if Vehicle.DEF.has(vt):
			_spawn_btn("v:" + vt, I18n.s(Vehicle.DEF[vt]["title"]))
	for vt in Vehicle.DEF:
		if Vehicle.DEF[vt].get("air", false) and not (vt in ["heli", "transport", "fpv"]):
			_spawn_btn("v:" + vt, I18n.s(Vehicle.DEF[vt]["title"]))
	# ulus katalogları (data/catalog/*.json): her birim otomatik
	var last := ""
	for e in Catalog.order:
		var hdr: String = Catalog.NATION_TITLE.get(e[0], e[0]) + " — " + I18n.s(Catalog.CAT_TITLE.get(e[1], e[1]))
		if hdr != last:
			_section(hdr)
			last = hdr
		var cu: Dictionary = Catalog.units[e[2]]
		_spawn_btn("v:" + e[2], I18n.s(cu["name"]) + ("  ◆" if Art.has(e[2]) else ""), String(cu.get("ref", "")))
	_section("YAPILAR (anında)")
	for id in Building.BDEF:
		if id != "hq" and not Building.BDEF[id].get("line", false):
			_spawn_btn("b:" + id, I18n.s(Building.BDEF[id]["title"]))
	_spawn_btn("b:hq", I18n.s(Building.BDEF["hq"]["title"]))
	_section("ARAÇLAR (geliştirici)")
	for t2 in TOOLS:
		_spawn_btn("t:" + t2, TOOL_TITLE[t2])
	_section("EFEKTLER")
	for f in FX:
		_spawn_btn("fx:" + f, FX_TITLE[f])
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
	var l: Label = hud._label(list, t, 12, Hud.AMBER, hud.font_b)
	l.set_meta("section", true)

# arama süzgeci: eşleşmeyen düğmeler gizlenir; boş bölüm başlıkları da
func _filter(q: String) -> void:
	var s := q.strip_edges().to_lower()
	var hdr: Control = null
	var any := false
	for ch in list.get_children():
		if ch.has_meta("section"):
			if hdr != null:
				hdr.visible = any or s == ""
			hdr = ch
			any = false
			continue
		if ch is Button:
			var ok: bool = s == "" or String(ch.get_meta("q", (ch as Button).text.to_lower())).contains(s)
			ch.visible = ok
			any = any or ok
	if hdr != null:
		hdr.visible = any or s == ""

# arama: katalog birimleri, taban araç tipleri, roller, timler, yapılar (kimlik + ad)
func find(q: String) -> Array:
	var s := q.to_lower()
	var out: Array = []
	for id in Building.PDEF:
		if id.contains(s) or I18n.s(Building.PDEF[id]["title"]).to_lower().contains(s):
			out.append([id, I18n.s(Building.PDEF[id]["title"])])
	for r in ROLES:
		if String(r).contains(s) or I18n.s(Soldier.ROLE_TITLE.get(r, r)).to_lower().contains(s):
			out.append([r, I18n.s(Soldier.ROLE_TITLE.get(r, r))])
	for vt in Vehicle.DEF:
		if String(vt).contains(s) or I18n.s(Vehicle.DEF[vt]["title"]).to_lower().contains(s):
			out.append([vt, I18n.s(Vehicle.DEF[vt]["title"])])
	for id2 in Catalog.units:
		var cu: Dictionary = Catalog.units[id2]
		if String(id2).contains(s) or I18n.s(cu["name"]).to_lower().contains(s) or String(cu.get("ref", "")).to_lower().contains(s):
			out.append([id2, "%s (%s)" % [I18n.s(cu["name"]), cu.get("ref", "")]])
	for b in Building.BDEF:
		if String(b).contains(s) or I18n.s(Building.BDEF[b]["title"]).to_lower().contains(s):
			out.append([b, I18n.s(Building.BDEF[b]["title"])])
	return out

# imlecin altındaki birim (asker, araç, yapı): en yakın, yapıda yarıçap hesaba katılır
func unit_at(p: Vector3, r := 4.0):
	var best = null
	var bd := 1e9
	for u in G.near(p, r + 12.0):
		if not is_instance_valid(u) or not (u is Soldier or u is Vehicle or u is Building):
			continue
		var d: float = Vector2(u.position.x - p.x, u.position.z - p.z).length() - (u.radius if u is Building else 0.0)
		if d < r and d < bd:
			bd = d
			best = u
	return best

func _info(u) -> String:
	if u == null or not is_instance_valid(u):
		return "—"
	var t := "%s team=%d hp=%d/%d" % [u.get_class() if not ("vid" in u) else (u.vid if u.vid != "" else u.vtype), u.team, int(u.hp), int(u.max_hp)]
	if u is Soldier:
		t = "asker %s %s team=%d hp=%d state=%s order=%s ammo=%d sup=%d" % [u.role, u.name, u.team, int(u.hp), u.state, u.order, u.ammo, int(u.suppression)]
	elif u is Vehicle:
		t = "araç %s (%s) team=%d hp=%d/%d order=%s spd=%.1f imm=%s yolcu=%d/%d" % [u.vid, u.vtype, u.team, int(u.hp), int(u.max_hp), u.order, u.cur_speed, u.immobile(), u.cargo.size(), u.capacity()]
	elif u is Building:
		t = "yapı %s team=%d hp=%d/%d bitti=%s" % [u.btype, u.team, int(u.hp), int(u.max_hp), u.done]
	return t

func _delete(u) -> void:
	if u == null or not is_instance_valid(u):
		return
	if u is Building and u.has_method("destroy"):
		u.alive = false
	G.units.erase(u)
	u.queue_free()

func _refill(u) -> void:
	if u is Soldier and u.alive:
		var W: Dictionary = u.weapon()
		u.ammo = int(W["ammo"])
		u.mag = int(W.get("mag", u.mag))
		u.grenades = maxi(u.grenades, 2)
		if u.role in ["at", "atgm"]:
			u.rockets = 4 if u.role == "at" else 3
		if u.role == "mortar":
			u.mortar_rounds = 24
	elif u is Vehicle and u.alive:
		if u.vtype == "uav_armed":
			u.missiles = 4

func _spawn_btn(id: String, title: String, extra := "") -> void:
	var b := _btn(list, "", func():
		pending = "" if pending == id else id
		Sfx.play2d("ui_click", -10.0))
	b.text = title
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.set_meta("id", id)
	b.set_meta("q", (title + " " + id + " " + extra).to_lower())     # süzgeçte aranan metin (ad, kimlik, özgün ad)

func _set_team(t: int) -> void:
	spawn_team = t
	team_btn.text = I18n.s("MÜTTEFİK" if t == 0 else "MİHVER")
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
		"t":
			match what:
				"del":
					var u = unit_at(p)
					_print("silindi: " + _info(u) if u != null else "imleçte birim yok")
					_delete(u)
				"wreck":
					# yık: imleçteki birim / yapı yok edilir; harita evleri, duvarlar ve köprü bloğu çöker
					var u2 = unit_at(p)
					if u2 != null and u2.alive:
						if u2 is Soldier:
							u2.die(null)
						else:
							u2.destroy(null)
					G.blocks.blast(p, 5.0, 3.0)
					G.props.blast(p, 6.0, 5000.0)
					_print("yıkıldı @ %.0f, %.0f" % [p.x, p.z])
				"tp":
					var k := 0
					for s in G.player.selected:
						if is_instance_valid(s) and s.alive and not (s is Building):
							var q: Vector3 = G.grid.nearest_free(p + Vector3((k % 4) * 2.5, 0, (k / 4) * 2.5), Grid.M_HEAVY if s is Vehicle else Grid.M_INF)
							s.position = G.on_ground(q)
							if s is Soldier:
								s.path = PackedVector3Array()
								s.state = "idle"
							elif s is Vehicle:
								s.path = PackedVector3Array()
								s.dest = s.position
							k += 1
					_print("ışınlandı: %d birim" % k)
				"info":
					_print(_info(unit_at(p)))
		"fx":
			var en := 1 - G.player_team
			match what:
				"boom_s":
					G.explode(p, 4.2, 120.0, "grenade", en, null)
				"rpg":
					G.explode(p + Vector3(0, 0.6, 0), 2.6, 150.0, "rpg", en, null)
				"mortar":
					G.explode(p, 4.0, 110.0, "mortar", en, null)
				"mine":
					G.explode(p, 3.4, 260.0, "mine", en, null)
				"boom_m":
					G.explode(p, 4.5, 130.0, "shell", en, null)
				"boom_l":
					G.explode(p, 8.0, 400.0, "big", en, null)
				"arty":
					for i in 6:
						G.bal.artillery(p + Vector3(-60, 40, -60), p + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), en, null)
				"mlrs":
					for i in 12:
						G.bal.mlrs_rocket(p + Vector3(-120, 6, -120), p + Vector3(randf_range(-14, 14), 0, randf_range(-14, 14)), en, null)
				"smoke":
					for i in 5:
						var q := p + Vector3((i - 2) * 3.5, 0, randf_range(-1, 1))
						G.fx.smoke_screen(q, 25.0)
						G.add_smoke(q, 4.0, 26.0)
				"fire":
					G.fx.burn(p, 30.0, 1.0)
				"fireball":
					G.fx.fireball(p + Vector3(0, 1.0, 0), 2.0)
				"water":
					G.fx.water_splash(p, 1.5)
				"crater":
					G.fx.crater(p, 4.0)
				"flare":
					G.fx.flash(p + Vector3(0, 12.0, 0), 6.0, 60.0, 8.0, Color(1.0, 0.95, 0.85))
	Sfx.play2d("ui_place", -8.0)

# ------------------------------------------------------------ konsol
func run(cmd: String) -> void:
	var a := cmd.strip_edges().split(" ", false)
	if a.is_empty():
		return
	var sel: Array = G.player.selected
	match a[0].to_lower():
		"help":
			_print("spawn <id|ara> [n] [blue|red] · find <metin> · del · destroy · tp · hp <n> · ammo · info · fx <%s> · stats · supply <n> · god · fog · ai · speed <x> · kill · heal · build · clear · clearall · team · boom <r> · rank · weather <clear|rain|storm|sandstorm|snowstorm> · night" % "|".join(FX))
		"find", "ara":
			if a.size() < 2:
				return
			var res := find(" ".join(a.slice(1)))
			var lines: Array = []
			for k2 in mini(res.size(), 6):
				lines.append("%s — %s" % [res[k2][0], res[k2][1]])
			_print("%d sonuç: %s" % [res.size(), " · ".join(lines)])
			search.text = " ".join(a.slice(1))
			_filter(search.text)
		"del", "sil":
			var nd := 0
			for u in sel.duplicate():
				if is_instance_valid(u):
					_delete(u)
					nd += 1
			G.player.clear_sel()
			_print("silindi: %d" % nd)
		"destroy", "yik", "yık":
			for u in sel.duplicate():
				if is_instance_valid(u) and u.alive:
					if u is Soldier:
						u.die(null)
					else:
						u.destroy(null)
		"tp":
			place("t:tp", G.cam.mouse_ground(get_viewport().get_mouse_position()))
		"hp":
			for u in sel:
				if is_instance_valid(u) and u.alive:
					u.hp = clampf(float(a[1]) if a.size() > 1 else u.max_hp, 1.0, 1e6)
		"ammo", "mermi":
			for u in sel:
				if is_instance_valid(u):
					_refill(u)
			_print("ikmal: %d birim" % sel.size())
		"info", "bilgi":
			if sel.is_empty():
				_print(_info(unit_at(G.cam.mouse_ground(get_viewport().get_mouse_position()))))
			for u in sel.slice(0, 3):
				_print(_info(u))
		"fx":
			if a.size() > 1 and a[1] in FX:
				place("fx:" + a[1], G.cam.mouse_ground(get_viewport().get_mouse_position()))
			else:
				_print("fx: " + ", ".join(FX))
		"stats":
			var ns := [0, 0]
			var nv := [0, 0]
			for u in G.units:
				if is_instance_valid(u) and u.alive and u.team >= 0 and u.team < 2:
					if u is Soldier:
						ns[u.team] += 1
					elif u is Vehicle:
						nv[u.team] += 1
			_print("FPS %d · asker %d/%d · araç %d/%d · zaman ×%.2f · harita %d m" % [Engine.get_frames_per_second(), ns[0], ns[1], nv[0], nv[1], Engine.time_scale, int(G.MAP)])
		"clearall":
			for u in G.units.duplicate():
				if is_instance_valid(u) and (u is Soldier or u is Vehicle):
					u.queue_free()
			_print("tüm birlikler silindi")
		"spawn":
			if a.size() < 2:
				return
			var n := int(a[2]) if a.size() > 2 else 1
			if a.size() > 3:
				_set_team(1 if a[3].begins_with("r") or a[3].begins_with("k") else 0)
			var id: String = a[1]
			if not (Building.PDEF.has(id) or Building.BDEF.has(id) or id in ROLES or Vehicle.DEF.has(id) or Catalog.units.has(id)):
				# tam kimlik değil: aramadaki ilk sonuç (ör. "spawn abrams", "spawn t-90")
				var fr := find(id)
				if fr.is_empty():
					_print("bulunamadı: " + id)
					return
				id = fr[0][0]
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
		"weather", "hava":
			if G.weather and a.size() > 1 and a[1] in Weather.KINDS:
				G.weather.dynamic = false
				G.weather.set_kind(a[1])
			_print("weather: %s (%s)" % [G.weather.kind if G.weather else "-", ", ".join(Weather.KINDS)])
		"night", "gece":
			if G.weather:
				G.weather.night = not G.weather.night
				G.weather.set_kind_silent(G.weather.kind)
				_print("night: %s" % G.weather.night)
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
			_print("kontrol: %s" % ("MÜTTEFİK" if G.player_team == 0 else "MİHVER"))
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
