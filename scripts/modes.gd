class_name Modes extends Node3D
# Oyun modları: hedef bölgeler + puan.
#  conquest  (Fetih): tutulan her bölge sürekli puan verir; hedef puana ilk ulaşan kazanır.
#  wargoals  (Savaş Hedefleri): aşamalar; aşama sonunda tutulan bölgeler × aşama çarpanı
#            + imha puanı (yok edilen düşman değeri). Son aşamada önde olan kazanır.
# Bölge ele geçirme: yalnız bir taraf varsa ilerler, iki taraf varsa çekişmeli (donar).

const MODE_NAME := {"bases": "KLASİK", "conquest": "FETİH", "wargoals": "SAVAŞ HEDEFLERİ"}
const ZONE_R := 13.0
const CONQ_GOAL := 600.0
const CONQ_RATE := 1.0 / 2.5      # bölge başına puan/sn
const PHASE_LEN := 240.0
const PHASES := 3
const PHASE_ZONE_PTS := 40.0

var mode := "conquest"
var zone_r := ZONE_R          # büyük haritada bölge daha geniş (8 km: 49 m)
var goal := CONQ_GOAL         # büyük haritada hedef puan ve aşama süresi uzar (yol uzun)
var phase_len := PHASE_LEN
var zones: Array = []            # {p, owner, prog(-1..1), name, ring, flag, label, contested}
var score := [0.0, 0.0]
var destroy_pts := [0.0, 0.0]
var phase := 1
var phase_t := PHASE_LEN
var _tick := 0.0
var ui: Control

func setup(m: String) -> void:
	mode = m
	zone_r = clampf(G.MAP * 0.006, ZONE_R, 50.0)
	var big := clampf(G.MAP / 2048.0, 1.0, 4.0)
	goal = CONQ_GOAL * big
	phase_len = PHASE_LEN * big
	phase_t = phase_len
	_place_zones()
	_build_ui()

# bölgeler: iki karargâh arasındaki eksende, yanlara serpiştirilmiş 5 nokta
func _place_zones() -> void:
	# haritada tanımlı hedefler (Büyük Muharebe: kasabalar, köprüler, istasyon, sanayi)
	if not G.zone_sites.is_empty():
		for zs in G.zone_sites:
			var z := {"p": zs["p"], "owner": -1, "prog": 0.0, "name": String(zs["name"]), "contested": false}
			_zone_visual(z)
			zones.append(z)
		return
	var a: Vector3 = G.hq_pos[0]
	var b: Vector3 = G.hq_pos[1]
	var ax := b - a
	ax.y = 0.0
	var L := ax.length()
	var dir := ax / maxf(L, 0.01)
	var side := Vector3(-dir.z, 0, dir.x)
	var names := ["A", "B", "C", "D", "E"]
	var offs := [0.0, 0.32, -0.3, 0.3, -0.32]
	for i in 5:
		var f := 0.2 + 0.6 * float(i) / 4.0
		var p: Vector3 = a + ax * f + side * L * float(offs[i]) * 0.55
		p = G.on_ground(p)
		p = G.grid.nearest_free(p, Grid.M_INF)
		var z := {"p": p, "owner": -1, "prog": 0.0, "name": names[i], "contested": false}
		_zone_visual(z)
		zones.append(z)

func _zone_visual(z: Dictionary) -> void:
	var root := Node3D.new()
	root.position = z["p"]
	add_child(root)
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = zone_r - 0.35 * zone_r / ZONE_R
	tm.outer_radius = zone_r
	tm.rings = 64
	tm.ring_segments = 4
	ring.mesh = tm
	ring.scale = Vector3(1, 0.15, 1)
	ring.position.y = 0.12
	ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var m := StandardMaterial3D.new()
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(1, 1, 1, 0.55)
	ring.material_override = m
	root.add_child(ring)
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.08
	cm.height = 6.0
	pole.mesh = cm
	pole.position.y = 3.0
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.55, 0.55, 0.52)
	pm.metallic = 0.6
	pm.roughness = 0.4
	pole.material_override = pm
	root.add_child(pole)
	var flag := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 1.0, 0.04)
	flag.mesh = bm
	flag.position = Vector3(0.85, 5.4, 0)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.85, 0.85, 0.82)
	flag.material_override = fm
	root.add_child(flag)
	var lb := Label3D.new()
	lb.text = z["name"]
	lb.font_size = 160
	lb.outline_size = 24
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position.y = 7.6
	lb.pixel_size = 0.012
	root.add_child(lb)
	z["ring"] = m
	z["flag"] = fm
	z["label"] = lb

func _team_col(t: int) -> Color:
	if t < 0:
		return Color(0.88, 0.88, 0.84)
	return [Color(0.12, 0.45, 0.95), Color(0.85, 0.12, 0.08)][t]

func _process(dt: float) -> void:
	if not G.running or G.game_over or dt <= 0.0:
		return
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.5
		_capture(0.5)
	# puan
	for z in zones:
		if z["owner"] >= 0 and mode == "conquest":
			score[z["owner"]] += CONQ_RATE * dt
	if mode == "conquest":
		for t in 2:
			if score[t] >= goal:
				G._end(t)
				return
	else:
		phase_t -= dt
		if phase_t <= 0.0:
			_phase_end()
	_update_ui()

func _capture(dt: float) -> void:
	for z in zones:
		var cnt := [0, 0]
		for u in G.near(z["p"], zone_r):
			if not u.alive or u.team < 0:
				continue
			if u is Soldier and u.can_fight():
				cnt[u.team] += 1
			elif u is Vehicle and not u.is_air() and u.vtype != "truck":
				cnt[u.team] += 2
		z["contested"] = cnt[0] > 0 and cnt[1] > 0
		if z["contested"] or (cnt[0] == 0 and cnt[1] == 0):
			# boş bölge yavaşça sahibine döner
			if not z["contested"] and z["owner"] >= 0:
				var want := 1.0 if z["owner"] == 0 else -1.0
				z["prog"] = move_toward(z["prog"], want, dt * 0.05)
			continue
		var t := 0 if cnt[0] > 0 else 1
		var dirv := 1.0 if t == 0 else -1.0
		var rate := 0.06 * minf(float(cnt[t]), 5.0)
		var before: float = z["prog"]
		z["prog"] = clampf(before + dirv * rate * dt, -1.0, 1.0)
		# sıfırı geçince nötr, uca varınca sahiplenir
		if z["owner"] >= 0 and z["owner"] != t and signf(z["prog"]) == dirv:
			z["owner"] = -1
			_announce(I18n.s("%s bölgesi nötr") % z["name"], z["p"])
		if z["owner"] != t and absf(z["prog"]) >= 1.0:
			z["owner"] = t
			_announce(I18n.s("%s bölgesi ele geçirildi") % z["name"], z["p"], t)
	for z in zones:
		var c := _team_col(z["owner"])
		var mat: StandardMaterial3D = z["ring"]
		mat.albedo_color = Color(c.r, c.g, c.b, 0.85 if z["contested"] else 0.55)
		(z["flag"] as StandardMaterial3D).albedo_color = c
		(z["label"] as Label3D).modulate = c

func _announce(txt: String, p: Vector3, t := -1) -> void:
	G.say(txt, p, G.player_team)
	if t == G.player_team:
		Sfx.play2d("ui_click", -4.0)
	elif t >= 0:
		Sfx.play2d("ui_alert", -6.0)

func add_destruction(team: int, value: float) -> void:
	if team < 0:
		return
	destroy_pts[team] += value
	if mode == "wargoals":
		score[team] += value

func _phase_end() -> void:
	var mult := float(phase)
	for z in zones:
		if z["owner"] >= 0:
			score[z["owner"]] += PHASE_ZONE_PTS * mult
	G.say(I18n.s("AŞAMA %d BİTTİ") % phase, G.hq_pos[G.player_team], G.player_team)
	if phase >= PHASES:
		var w := 0 if score[0] >= score[1] else 1
		G._end(w)
		return
	phase += 1
	phase_t = phase_len

func owned(t: int) -> int:
	var n := 0
	for z in zones:
		if z["owner"] == t:
			n += 1
	return n

# ------------------------------------------------------------ arayüz (üst orta)
func _build_ui() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 5
	add_child(cl)
	ui = Control.new()
	ui.set_anchors_preset(Control.PRESET_CENTER_TOP)
	ui.position = Vector2(-230, 62)
	ui.size = Vector2(460, 54)
	ui.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.draw.connect(_draw_ui)
	cl.add_child(ui)

func _update_ui() -> void:
	if ui:
		ui.queue_redraw()

func _draw_ui() -> void:
	var f: Font = G.hud.font_b if G.hud and "font_b" in G.hud else ThemeDB.fallback_font
	var w := ui.size.x
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.06, 0.78)
	sb.set_corner_radius_all(6)
	ui.draw_style_box(sb, Rect2(Vector2.ZERO, ui.size))
	var me := G.player_team
	var col := [_team_col(0), _team_col(1)]
	# puanlar
	ui.draw_string(f, Vector2(12, 34), str(int(score[0])), HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col[0])
	ui.draw_string(f, Vector2(w - 92, 34), str(int(score[1])), HORIZONTAL_ALIGNMENT_RIGHT, 80, 24, col[1])
	# bölgeler
	var n := zones.size()
	for i in n:
		var z: Dictionary = zones[i]
		var cx := w * 0.5 + (i - (n - 1) * 0.5) * 42.0
		var c := _team_col(z["owner"])
		var r := Rect2(cx - 16, 8, 32, 26)
		var bsb := StyleBoxFlat.new()
		bsb.bg_color = Color(c.r, c.g, c.b, 0.9 if z["owner"] >= 0 else 0.25)
		bsb.set_corner_radius_all(4)
		if z["contested"]:
			bsb.border_color = Color(1, 0.8, 0.2)
			bsb.set_border_width_all(2)
		ui.draw_style_box(bsb, r)
		# ilerleme çubuğu
		var pr: float = z["prog"]
		if absf(pr) > 0.01 and absf(pr) < 0.999:
			var pc: Color = col[0] if pr > 0 else col[1]
			ui.draw_rect(Rect2(cx - 16, 36, 32.0 * absf(pr), 3), pc)
		ui.draw_string(f, Vector2(cx - 16, 28), z["name"], HORIZONTAL_ALIGNMENT_CENTER, 32, 17, Color(1, 1, 1))
	var sub := ""
	if mode == "conquest":
		sub = "%s · %d" % [I18n.s("FETİH"), int(goal)]
	else:
		sub = "%s %d/%d · %d:%02d" % [I18n.s("AŞAMA"), phase, PHASES, int(phase_t) / 60, int(phase_t) % 60]
	ui.draw_string(f, Vector2(0, 52), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(0.85, 0.82, 0.72))
	me = me
