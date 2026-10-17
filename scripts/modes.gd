class_name Modes extends Node3D
# Oyun modları: hedef bölgeler + puan (roadmap 156: kullanıcı listesi, 17 Ekim).
#  conquest     (Fetih): tutulan her bölge sürekli puan verir; hedef puana ilk ulaşan kazanır.
#  wargoals     (Savaş Hedefleri): aşamalar; aşama sonunda tutulan bölgeler × aşama çarpanı + imha puanı.
#  defend       (Bölgeyi Savun): oyuncu tüm bölgelerle başlar, yapay zekâ dalga dalga saldırır; süre dolunda
#               en az bir bölge elde ise kazanır, hepsi düşerse kaybeder.
#  assault      (Saldırı): tersi — bölgeler düşmanda, yapay zekâ savunur; süre içinde hepsini al.
#  ctf          (Bayrak Kapma): her karargâhın önünde bayrak; piyade düşman bayrağını taşıyıp kendi bayrağına
#               getirir (kendi bayrağı yerindeyse). Taşıyan düşerse bayrak yere düşer; sahibi dokununca ya da
#               45 sn sonra yerine döner. 3 kapan kazanır.
#  annihilation (En Çok İmha): süre sonunda yok ettiği düşman değeri yüksek olan kazanır.
#  vp           (Zafer Puanı): CoH tarzı bilet; iki taraf 500 ile başlar, fazla bölge tutan karşı tarafın
#               puanını eritir (fark başına), yok edilen birim değeri de düşer; sıfırlanan kaybeder.
#  historical   (Tarihsel Operasyon): önceden kurulu kuvvetler, sıralı hedefler (yalnız sıradaki alınabilir),
#               süre sınırı, brifing. Yapay zekâ üretmez, mevzisini savunur.
# Bölge ele geçirme: yalnız bir taraf varsa ilerler, iki taraf varsa çekişmeli (donar).

const MODE_NAME := {"bases": "KLASİK", "conquest": "FETİH", "wargoals": "SAVAŞ HEDEFLERİ", "defend": "BÖLGEYİ SAVUN", "assault": "SALDIRI", "ctf": "BAYRAK KAPMA", "annihilation": "EN ÇOK İMHA", "vp": "ZAFER PUANI", "historical": "TARİHSEL OPERASYON"}
const MODE_DESC := {"bases": "Düşman üslerini yok et", "conquest": "Bölge tut, puan topla", "wargoals": "3 aşama: bölge + imha puanı",
	"defend": "Tüm bölgeler sende; süre dolana dek en az birini tut", "assault": "Bölgeler düşmanda; süre içinde hepsini al",
	"ctf": "Düşman bayrağını kendi bayrağına getir; 3 kapan kazanır", "annihilation": "Süre sonunda en çok düşman değerini yok eden kazanır",
	"vp": "Fazla bölge tutan karşının puanını eritir; 500 puan, sıfırlanan kaybeder", "historical": "Kurulu kuvvetler, sıralı hedefler, süre sınırı"}
const MIN_MAP := 1024.0            # Klasik dışı modlar en az 1 km haritada (menü denetler)
const ZONE_R := 13.0
const CONQ_GOAL := 600.0
const CONQ_RATE := 1.0 / 2.5      # bölge başına puan/sn
const PHASE_LEN := 240.0
const PHASES := 3
const PHASE_ZONE_PTS := 40.0
const DEF_TIME := 600.0
const ASSAULT_TIME := 840.0
const ANNI_TIME := 600.0
const VP_START := 500.0
const VP_RATE := 0.5               # bölge farkı başına puan/sn
const VP_KILL := 1.0 / 25.0        # yok edilen değer → karşı tarafın puanından
const CTF_GOAL := 3
const FLAG_R := 3.0
const FLAG_RETURN := 45.0

# tarihsel operasyonlar: harita bağımsız (kuvvetler karargâhların ve hedeflerin çevresine kurulur)
const OPS := {
	"easting73": {"title": "73 EASTING", "year": "26 Şubat 1991", "time": 900.0,
		"brief": "Irak çölü, kum fırtınası. Zırhlı süvari bölüğü, savunma hattına gömülü zırhlı tümenin ileri mevzilerine çarpar. Hedefleri sırayla al: ileri karakol, sırt hattı, ikmal kavşağı. Görüş kısa — tanklarını piyadesiz bırakma.",
		"player": ["tank", "tank", "tank", "tank", "ifv", "ifv", "ifv", "rifle_squad", "rifle_squad"],
		"enemy": ["tank", "tank", "tank", "apc", "apc", "rifle_squad", "rifle_squad", "rifle_squad", "at_squad", "at_squad", "mg_team"]},
	"anaconda": {"title": "ANAKONDA HAREKÂTI", "year": "2 Mart 2002", "time": 1080.0,
		"brief": "Dağlık vadi, yüksek rakım. Hafif piyade bölüğü, sırtlara yerleşmiş direnişin mevzilerini temizler. Hedefleri sırayla al: vadi girişi, köy, yüksek sırt. Havan ve keskin nişancılar sırtları tutuyor — siper ve dolaylı ateş kullan.",
		"player": ["rifle_squad", "rifle_squad", "rifle_squad", "rifle_squad", "mg_team", "mortar_team", "sniper_team", "medic_team"],
		"enemy": ["rifle_squad", "rifle_squad", "rifle_squad", "rifle_squad", "mg_team", "mg_team", "mortar_team", "mortar_team", "sniper_team"]},
}

var mode := "conquest"
var zone_r := ZONE_R          # büyük haritada bölge daha geniş (8 km: 49 m)
var goal := CONQ_GOAL         # büyük haritada hedef puan ve aşama süresi uzar (yol uzun)
var phase_len := PHASE_LEN
var zones: Array = []            # {p, owner, prog(-1..1), name, ring, flag, label, contested}
var score := [0.0, 0.0]
var destroy_pts := [0.0, 0.0]
var phase := 1
var phase_t := PHASE_LEN
var time_left := 0.0
var tickets := [VP_START, VP_START]
var caps := [0, 0]
var flags: Array = []            # takım sırasıyla: {team, home, pos, carrier, state(home/carried/dropped), drop_t, node}
var obj_i := 0
var op: Dictionary = {}
var _tick := 0.0
var _alive_t := 0.0
var ui: Control

func me() -> int:
	return G.player_team

func foe() -> int:
	return 1 - G.player_team

func setup(m: String) -> void:
	mode = m
	zone_r = clampf(G.MAP * 0.006, ZONE_R, 50.0)
	var big := clampf(G.MAP / 2048.0, 1.0, 4.0)
	goal = CONQ_GOAL * big
	phase_len = PHASE_LEN * big
	phase_t = phase_len
	match mode:
		"ctf":
			_place_flags()
		"annihilation":
			pass
		_:
			_place_zones()
	match mode:
		"defend":
			time_left = DEF_TIME * big
			_own_all(me())
		"assault":
			time_left = ASSAULT_TIME * big
			_own_all(foe())
		"annihilation":
			time_left = ANNI_TIME * big
		"historical":
			op = OPS.get(G.op_id, OPS[OPS.keys()[0]])
			time_left = float(op["time"]) * big
			_own_all(foe())
			_spawn_op()
		"vp":
			tickets = [VP_START, VP_START]
	_paint()
	_build_ui()
	if mode == "historical":
		_briefing()

# bölgeler: iki karargâh arasındaki eksende, yanlara serpiştirilmiş 5 nokta (tarihsel: 3 sıralı hedef)
func _place_zones() -> void:
	# haritada tanımlı hedefler (Büyük Muharebe: kasabalar, köprüler, istasyon, sanayi)
	if not G.zone_sites.is_empty() and mode != "historical":
		for zs in G.zone_sites:
			var z := {"p": zs["p"], "owner": -1, "prog": 0.0, "name": String(zs["name"]), "contested": false}
			_zone_visual(z)
			zones.append(z)
		return
	var a: Vector3 = G.hq_pos[me()] if mode == "historical" else G.hq_pos[0]
	var b: Vector3 = G.hq_pos[foe()] if mode == "historical" else G.hq_pos[1]
	var ax := b - a
	ax.y = 0.0
	var L := ax.length()
	var dir := ax / maxf(L, 0.01)
	var side := Vector3(-dir.z, 0, dir.x)
	var names := ["A", "B", "C", "D", "E"]
	var offs := [0.0, 0.32, -0.3, 0.3, -0.32]
	var n := 3 if mode == "historical" else 5
	for i in n:
		var f := (0.3 + 0.45 * float(i) / 2.0) if mode == "historical" else (0.2 + 0.6 * float(i) / 4.0)
		var off: float = ([0.0, 0.18, -0.12][i] if mode == "historical" else offs[i])
		var p: Vector3 = a + ax * f + side * L * off * 0.55
		p = G.on_ground(p)
		p = G.grid.nearest_free(p, Grid.M_INF)
		var z := {"p": p, "owner": -1, "prog": 0.0, "name": names[i], "contested": false}
		_zone_visual(z)
		zones.append(z)

func _own_all(t: int) -> void:
	for z in zones:
		z["owner"] = t
		z["prog"] = 1.0 if t == 0 else -1.0

func _ring_mesh(r: float) -> MeshInstance3D:
	var ring := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = r - 0.35 * r / ZONE_R
	tm.outer_radius = r
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
	return ring

# direk + bez (bölge ve bayrak kapma bayrağı)
func _pole(root: Node3D, h := 6.0) -> StandardMaterial3D:
	var pole := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = 0.06
	cm.bottom_radius = 0.08
	cm.height = h
	pole.mesh = cm
	pole.position.y = h * 0.5
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.55, 0.55, 0.52)
	pm.metallic = 0.6
	pm.roughness = 0.4
	pole.material_override = pm
	root.add_child(pole)
	var flag := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(1.6, 1.0, 0.04) * (h / 6.0)
	flag.mesh = bm
	flag.position = Vector3(0.85, h - 0.6, 0) * Vector3(h / 6.0, 1, 1)
	var fm := StandardMaterial3D.new()
	fm.albedo_color = Color(0.85, 0.85, 0.82)
	flag.material_override = fm
	root.add_child(flag)
	return fm

func _zone_visual(z: Dictionary) -> void:
	var root := Node3D.new()
	root.position = z["p"]
	add_child(root)
	var ring := _ring_mesh(zone_r)
	root.add_child(ring)
	var fm := _pole(root)
	var lb := Label3D.new()
	lb.text = z["name"]
	lb.font_size = 160
	lb.outline_size = 24
	lb.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lb.no_depth_test = true
	lb.position.y = 7.6
	lb.pixel_size = 0.012
	root.add_child(lb)
	z["ring"] = ring.material_override
	z["flag"] = fm
	z["label"] = lb

func _team_col(t: int) -> Color:
	if t < 0:
		return Color(0.88, 0.88, 0.84)
	return [Color(0.12, 0.45, 0.95), Color(0.85, 0.12, 0.08)][t]

func _process(dt: float) -> void:
	# yeni oyun başlarken eski mod düğümü (queue_free bekliyor) bir kare daha işler — eski bölgelerle yeni oyunu
	# bitirmesin (yeni maçı t=0'da sonlandırıyordu)
	if G.modes != self or not G.running or G.game_over or dt <= 0.0:
		return
	_tick -= dt
	if _tick <= 0.0:
		_tick = 0.5
		_capture(0.5)
	match mode:
		"conquest":
			for z in zones:
				if z["owner"] >= 0:
					score[z["owner"]] += CONQ_RATE * dt
			for t in 2:
				if score[t] >= goal:
					G._end(t)
					return
		"wargoals":
			phase_t -= dt
			if phase_t <= 0.0:
				_phase_end()
		"defend":
			time_left -= dt
			if owned(foe()) == zones.size():
				G._end(foe())
				return
			if time_left <= 0.0:
				G._end(me() if owned(me()) > 0 else foe())
				return
		"assault":
			time_left -= dt
			if owned(me()) == zones.size():
				G._end(me())
				return
			if time_left <= 0.0:
				G._end(foe())
				return
		"historical":
			time_left -= dt
			if obj_i < zones.size() and zones[obj_i]["owner"] == me():
				obj_i += 1
				if obj_i >= zones.size():
					G._end(me())
					return
				_announce(I18n.s("Hedef alındı — sıradaki: %s") % zones[obj_i]["name"], zones[obj_i]["p"], me())
				_paint()
			if time_left <= 0.0:
				G._end(foe())
				return
			# kuvvet tükendi (üretim yok)
			_alive_t -= dt
			if _alive_t <= 0.0:
				_alive_t = 2.0
				var any := false
				for u in G.units:
					if is_instance_valid(u) and u.alive and u.team == me() and ((u is Soldier and u.can_fight()) or (u is Vehicle and u.vtype != "truck")):
						any = true
						break
				if not any:
					G._end(foe())
					return
		"vp":
			var d := owned(0) - owned(1)
			if d != 0:
				var loser := 1 if d > 0 else 0
				tickets[loser] -= VP_RATE * absf(d) * dt
			for t in 2:
				if tickets[t] <= 0.0:
					tickets[t] = 0.0
					G._end(1 - t)
					return
		"ctf":
			_flags_tick()
		"annihilation":
			time_left -= dt
			score = destroy_pts.duplicate()
			if time_left <= 0.0:
				G._end(0 if destroy_pts[0] >= destroy_pts[1] else 1)
				return
	_update_ui()

# bölge kilitli mi: tarihsel operasyonda yalnız sıradaki hedef alınabilir (alınanlar oyuncuda kalır)
func locked(i: int) -> bool:
	return mode == "historical" and i != obj_i

func _capture(dt: float) -> void:
	for i in zones.size():
		var z: Dictionary = zones[i]
		if locked(i):
			z["contested"] = false
			continue
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
	_paint()

func _paint() -> void:
	for i in zones.size():
		var z: Dictionary = zones[i]
		var c := _team_col(z["owner"])
		var mat: StandardMaterial3D = z["ring"]
		var a := 0.85 if z["contested"] else 0.55
		if locked(i) and i > obj_i:
			a = 0.2
		mat.albedo_color = Color(c.r, c.g, c.b, a)
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
	elif mode == "vp":
		tickets[1 - team] = maxf(0.0, tickets[1 - team] - value * VP_KILL)

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

# ------------------------------------------------------------ bayrak kapma
func _place_flags() -> void:
	for t in 2:
		var to: Vector3 = G.hq_pos[1 - t] - G.hq_pos[t]
		to.y = 0.0
		var home := G.grid.nearest_free(G.hq_pos[t] + to.normalized() * 22.0, Grid.M_INF)
		home.y = G.terrain.ground_h(home) if G.terrain else 0.0
		var base := _ring_mesh(FLAG_R)
		base.position = home + Vector3(0, 0.05, 0)
		(base.material_override as StandardMaterial3D).albedo_color = Color(_team_col(t).r, _team_col(t).g, _team_col(t).b, 0.7)
		add_child(base)
		var node := Node3D.new()
		add_child(node)
		var fm := _pole(node, 3.2)
		fm.albedo_color = _team_col(t)
		node.position = home
		flags.append({"team": t, "home": home, "pos": home, "carrier": null, "state": "home", "drop_t": 0.0, "node": node})

func _flag_home(f: Dictionary) -> void:
	f["state"] = "home"
	f["carrier"] = null
	f["pos"] = f["home"]

func _flags_tick() -> void:
	for f in flags:
		var t: int = f["team"]
		var name := I18n.s("Mavi bayrak") if t == 0 else I18n.s("Kırmızı bayrak")
		match f["state"]:
			"carried":
				var c = f["carrier"]
				if c == null or not is_instance_valid(c) or not c.alive or c.incapacitated() or c.state in ["aboard", "prisoner", "surrender", "hospital"]:
					f["state"] = "dropped"
					f["carrier"] = null
					f["drop_t"] = G.time
					_announce(I18n.s("%s düştü") % name, f["pos"], t)
				else:
					f["pos"] = c.position
					var own: Dictionary = flags[1 - t]
					if own["state"] == "home" and Vector2(c.position.x - own["home"].x, c.position.z - own["home"].z).length() < FLAG_R + 1.0:
						caps[1 - t] += 1
						score[1 - t] = caps[1 - t]
						_flag_home(f)
						_announce(I18n.s("%s kapıldı!") % name, own["home"], 1 - t)
						if caps[1 - t] >= CTF_GOAL:
							G._end(1 - t)
							return
			_:
				for u in G.near(f["pos"], FLAG_R):
					if not (u is Soldier) or not u.alive or not u.can_fight() or u.state == "aboard":
						continue
					if u.team != t:
						f["state"] = "carried"
						f["carrier"] = u
						_announce(I18n.s("%s alındı") % name, f["pos"], u.team)
						break
					elif f["state"] == "dropped":
						_flag_home(f)
						_announce(I18n.s("%s yerine döndü") % name, f["home"], t)
						break
				if f["state"] == "dropped" and G.time - float(f["drop_t"]) > FLAG_RETURN:
					_flag_home(f)
		var node: Node3D = f["node"]
		node.position = f["pos"] + (Vector3(-0.3, 0.6, 0) if f["state"] == "carried" else Vector3.ZERO)

# ------------------------------------------------------------ tarihsel operasyon
func _spawn_op() -> void:
	# oyuncu kuvveti karargâhın önünde; düşman kuvveti hedeflere dağıtılır (son hedef en kalabalık)
	var to: Vector3 = G.hq_pos[foe()] - G.hq_pos[me()]
	to.y = 0.0
	var fw := to.normalized()
	var sd := Vector3(-fw.z, 0, fw.x)
	var pl: Array = op["player"]
	for i in pl.size():
		var p: Vector3 = G.hq_pos[me()] + fw * 30.0 + sd * (float(i) - pl.size() * 0.5) * 7.0
		_spawn_item(me(), pl[i], p, fw)
	var en: Array = op["enemy"]
	for i in en.size():
		var zi := mini(zones.size() - 1, int(float(i) * zones.size() / en.size() + 0.35))
		var zp: Vector3 = zones[zi]["p"]
		var a := float(i) * 2.399
		_spawn_item(foe(), en[i], zp + Vector3(cos(a), 0, sin(a)) * zone_r * 0.6, -fw)
	G.supply[me()] = 300.0
	G.supply[foe()] = 0.0

func _spawn_item(t: int, id: String, p: Vector3, fw: Vector3) -> void:
	var P: Dictionary = Building.PDEF.get(id, {})
	var yaw := atan2(fw.x, fw.z)
	if P.has("units"):
		var sq := Squad.new(t, P["title"])
		G.squads.append(sq)
		var units: Array = P["units"]
		for k in units.size():
			var q := G.grid.nearest_free(p + Vector3((k % 3 - 1) * 1.6, 0, (k / 3) * 1.6), Grid.M_INF)
			var s: Soldier = G.main.spawn_soldier(t, units[k], q, sq)
			s.cost_share = float(P.get("cost", 120)) / units.size()
	else:
		G.main.spawn_vehicle(t, id, G.grid.nearest_free(p, Grid.M_HEAVY), yaw)

func _briefing() -> void:
	var cl := CanvasLayer.new()
	cl.layer = 30
	add_child(cl)
	var pc := PanelContainer.new()
	pc.add_theme_stylebox_override("panel", Sketch.panel(0.96, 18))
	pc.set_anchors_preset(Control.PRESET_CENTER)
	pc.custom_minimum_size = Vector2(560, 0)
	pc.position = Vector2(-280, -150)
	cl.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 8)
	pc.add_child(v)
	var hud: Hud = G.hud
	var t1 := Label.new()
	t1.text = I18n.s("TARİHSEL OPERASYON") + "  ·  " + I18n.s(op["year"])
	t1.add_theme_font_override("font", hud.font_m)
	t1.add_theme_font_size_override("font_size", 14)
	t1.add_theme_color_override("font_color", Sketch.INK2)
	v.add_child(t1)
	var t2 := Label.new()
	t2.text = I18n.s(op["title"])
	t2.add_theme_font_override("font", hud.font_b)
	t2.add_theme_font_size_override("font_size", 28)
	v.add_child(t2)
	var t3 := Label.new()
	t3.text = I18n.s(op["brief"])
	t3.autowrap_mode = TextServer.AUTOWRAP_WORD
	t3.custom_minimum_size = Vector2(520, 0)
	t3.add_theme_font_override("font", hud.font_m)
	t3.add_theme_font_size_override("font_size", 16)
	v.add_child(t3)
	var t4 := Label.new()
	t4.text = I18n.s("Süre: %d dk  ·  Hedefler sırayla: %s") % [int(time_left / 60.0), " → ".join(PackedStringArray(zones.map(func(z): return String(z["name"]))))]
	t4.add_theme_font_override("font", hud.font_m)
	t4.add_theme_font_size_override("font_size", 14)
	t4.add_theme_color_override("font_color", Sketch.RED)
	v.add_child(t4)
	var b := Button.new()
	b.text = I18n.s("Başla")
	b.custom_minimum_size = Vector2(0, 36)
	b.pressed.connect(func(): cl.queue_free())
	v.add_child(b)
	brief_ui = cl

var brief_ui: CanvasLayer

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

func _clock(s: float) -> String:
	var k := maxi(0, int(s))
	return "%d:%02d" % [k / 60, k % 60]

func _draw_ui() -> void:
	var f: Font = G.hud.font_b if G.hud and "font_b" in G.hud else ThemeDB.fallback_font
	var w := ui.size.x
	var sb := StyleBoxFlat.new()
	sb.bg_color = Color(0.05, 0.06, 0.06, 0.78)
	sb.set_corner_radius_all(6)
	ui.draw_style_box(sb, Rect2(Vector2.ZERO, ui.size))
	var col := [_team_col(0), _team_col(1)]
	# sol / sağ sayılar: moda göre puan, bilet, kapma, imha
	var lv := ["", ""]
	match mode:
		"vp":
			lv = [str(int(ceil(tickets[0]))), str(int(ceil(tickets[1])))]
		"ctf":
			lv = ["%d/%d" % [caps[0], CTF_GOAL], "%d/%d" % [caps[1], CTF_GOAL]]
		"defend", "assault", "historical":
			lv = [str(owned(0)), str(owned(1))]
		_:
			lv = [str(int(score[0])), str(int(score[1]))]
	ui.draw_string(f, Vector2(12, 34), lv[0], HORIZONTAL_ALIGNMENT_LEFT, -1, 24, col[0])
	ui.draw_string(f, Vector2(w - 92, 34), lv[1], HORIZONTAL_ALIGNMENT_RIGHT, 80, 24, col[1])
	if mode == "ctf":
		# iki bayrağın durumu
		for i in flags.size():
			var fl: Dictionary = flags[i]
			var cx := w * 0.5 + (i - 0.5) * 70.0
			var c: Color = col[i]
			var st: String = {"home": "YERİNDE", "carried": "TAŞINIYOR", "dropped": "YERDE"}[fl["state"]]
			ui.draw_rect(Rect2(cx - 30, 8, 60, 26), Color(c.r, c.g, c.b, 0.9 if fl["state"] == "home" else 0.35))
			ui.draw_string(f, Vector2(cx - 30, 26), I18n.s(st), HORIZONTAL_ALIGNMENT_CENTER, 60, 11, Color(1, 1, 1))
	else:
		var n := zones.size()
		for i in n:
			var z: Dictionary = zones[i]
			var cx := w * 0.5 + (i - (n - 1) * 0.5) * 42.0
			var c := _team_col(z["owner"])
			var r := Rect2(cx - 16, 8, 32, 26)
			var bsb := StyleBoxFlat.new()
			bsb.bg_color = Color(c.r, c.g, c.b, (0.9 if z["owner"] >= 0 else 0.25) * (0.35 if locked(i) and i > obj_i else 1.0))
			bsb.set_corner_radius_all(4)
			if z["contested"]:
				bsb.border_color = Color(1, 0.8, 0.2)
				bsb.set_border_width_all(2)
			elif mode == "historical" and i == obj_i:
				bsb.border_color = Color(1, 1, 1, 0.8)
				bsb.set_border_width_all(2)
			ui.draw_style_box(bsb, r)
			# ilerleme çubuğu
			var pr: float = z["prog"]
			if absf(pr) > 0.01 and absf(pr) < 0.999:
				var pc: Color = col[0] if pr > 0 else col[1]
				ui.draw_rect(Rect2(cx - 16, 36, 32.0 * absf(pr), 3), pc)
			ui.draw_string(f, Vector2(cx - 16, 28), z["name"], HORIZONTAL_ALIGNMENT_CENTER, 32, 17, Color(1, 1, 1))
	var sub := ""
	match mode:
		"conquest":
			sub = "%s · %d" % [I18n.s("FETİH"), int(goal)]
		"wargoals":
			sub = "%s %d/%d · %s" % [I18n.s("AŞAMA"), phase, PHASES, _clock(phase_t)]
		"historical":
			sub = "%s · %s %d/%d · %s" % [I18n.s(op.get("title", "")), I18n.s("HEDEF"), mini(obj_i + 1, zones.size()), zones.size(), _clock(time_left)]
		"vp", "ctf":
			sub = I18n.s(MODE_NAME[mode])
		_:
			sub = "%s · %s" % [I18n.s(MODE_NAME[mode]), _clock(time_left)]
	ui.draw_string(f, Vector2(0, 52), sub, HORIZONTAL_ALIGNMENT_CENTER, w, 12, Color(0.85, 0.82, 0.72))
