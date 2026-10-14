class_name Soldier extends Unit
# Piyade: gerçek siper kullanımı, baskılanma, mühimmat, el bombası, yaralanma / sürükleme / tedavi.

const WPN := {
	"rifle": {"range": 34.0, "dmg": 24.0, "rof": 0.13, "b0": 2, "b1": 4, "p0": 0.45, "p1": 1.2, "mag": 30, "ammo": 270, "acc": 0.5, "sup": 6.0, "snd": "rifle", "tr": 3, "reload": 2.2},
	"mg": {"range": 44.0, "dmg": 20.0, "rof": 0.085, "b0": 6, "b1": 14, "p0": 0.6, "p1": 1.4, "mag": 100, "ammo": 600, "acc": 0.36, "sup": 11.0, "snd": "mg", "tr": 2, "reload": 4.5},
	"at": {"range": 28.0, "dmg": 18.0, "rof": 0.28, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.6, "mag": 20, "ammo": 120, "acc": 0.4, "sup": 5.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"sniper": {"range": 72.0, "dmg": 110.0, "rof": 0.1, "b0": 1, "b1": 1, "p0": 3.2, "p1": 4.6, "mag": 5, "ammo": 60, "acc": 0.85, "sup": 16.0, "snd": "sniper", "tr": 1, "reload": 3.0},
	"engineer": {"range": 24.0, "dmg": 15.0, "rof": 0.08, "b0": 3, "b1": 6, "p0": 0.5, "p1": 1.1, "mag": 30, "ammo": 240, "acc": 0.42, "sup": 5.0, "snd": "rifle", "tr": 3, "reload": 2.0},
	"mortar": {"range": 24.0, "dmg": 18.0, "rof": 0.2, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.5, "mag": 15, "ammo": 60, "acc": 0.35, "sup": 4.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"drone": {"range": 24.0, "dmg": 18.0, "rof": 0.2, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.5, "mag": 15, "ammo": 60, "acc": 0.35, "sup": 4.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"leader": {"range": 36.0, "dmg": 24.0, "rof": 0.13, "b0": 2, "b1": 4, "p0": 0.5, "p1": 1.2, "mag": 30, "ammo": 240, "acc": 0.52, "sup": 6.0, "snd": "rifle", "tr": 3, "reload": 2.2},
	"crew": {"range": 22.0, "dmg": 14.0, "rof": 0.09, "b0": 3, "b1": 6, "p0": 0.6, "p1": 1.2, "mag": 30, "ammo": 120, "acc": 0.34, "sup": 4.0, "snd": "rifle", "tr": 3, "reload": 2.0},
	"medic": {"range": 28.0, "dmg": 20.0, "rof": 0.2, "b0": 1, "b1": 3, "p0": 0.7, "p1": 1.4, "mag": 30, "ammo": 150, "acc": 0.4, "sup": 5.0, "snd": "rifle", "tr": 4, "reload": 2.2},
}
const STAND := 0
const CROUCH := 1
const PRONE := 2
const RUN_SPEED := 3.7

var role := "rifle"
var body: SoldierBody
var squad: Squad
var state := "idle"
var stance := STAND
var order := ""
var force_move := false
var dest := Vector3.ZERO
var path := PackedVector3Array()
var path_i := 0
var vel := Vector3.ZERO
var face_yaw := 0.0
var target: Unit = null
var forced_target: Unit = null
var threat_pos := Vector3.ZERO
var threat_time := -99.0
var cover_type := 0
var cover_pos := Vector3.ZERO
var cover_cd := 0.0
var to_cover := false
var suppression := 0.0
# stres (BA): baskıdan ayrı, yavaş birikir/yavaş iner. 1 = sarsılmış, 2 = panik
var stress := 0.0
var cost_share := 0.0      # üretim maliyetinden payı (iade/imha puanı)
var stress_lv := 0
var stress_t := -99.0
var panic_fled := false
var sup_t := -99.0
var ammo := 0
var mag := 0
var reload_t := 0.0
var fire_cd := 0.0
var burst_left := 0
var grenades := 2
var smoke_nades := 1
var gren_cd := 0.0
var rockets := 0
var rocket_aim := 0.0
var downs := 0
var bleed := 0.0
var rescuer: Soldier = null
var patient: Soldier = null
var drag_dest := Vector3.ZERO
var heal_t := 0.0
var think_t := 0.0
var popped := false
var popup_t := 0.0
var lean := Vector3.ZERO
var lean_cur := Vector3.ZERO
var fly_vel := Vector3.ZERO
var fly_spin := 0.0
var fly_ang := 0.0
var state_t := 0.0
var throw_to := Vector3.ZERO
var throw_smoke := false
var throw_released := false
var covering_until := 0.0
var build_site: Node3D = null
var loot := 0
var dead_t := 0.0
var died_at := 0.0
var shots := 0
var res_t := 0.0
var winter := false
var held_by_vehicle := false
var sname := ""
var rank := 0
var xp := 0
const RANKS := ["ER", "ONBAŞI", "ÇAVUŞ", "ÜSTÇAVUŞ", "KD. ÇAVUŞ"]
const RANK_S := ["ER", "ONB", "ÇVŞ", "ÜÇV", "KÇV"]
const RANK_XP := [0, 15, 40, 80, 140]
const NAMES_A := ["Ahmet", "Mehmet", "Mustafa", "Ali", "Hüseyin", "Hasan", "İbrahim", "Murat", "Emre", "Burak", "Serkan", "Volkan", "Kemal", "Yusuf", "Ömer", "Caner", "Tolga", "Kaan", "Barış", "Deniz", "Onur", "Cem", "Eren", "Uğur", "Selim", "Tarık", "Levent", "Erdem", "Okan", "Halil"]
const NAMES_B := ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Aydın", "Öztürk", "Arslan", "Doğan", "Kılıç", "Aslan", "Çetin", "Kara", "Koç", "Kurt", "Özdemir", "Şimşek", "Polat", "Erdoğan", "Güneş", "Tekin", "Bulut", "Korkmaz", "Akın", "Ateş", "Bozkurt", "Tunç", "Uysal", "Keskin"]
const NAMES_RA := ["Viktor", "Dmitri", "Ivan", "Sergei", "Alexei", "Pavel", "Nikolai", "Oleg", "Yuri", "Boris", "Mikhail", "Andrei", "Roman", "Artem", "Kirill", "Stepan", "Fyodor", "Leonid", "Grigori", "Maxim"]
const NAMES_RB := ["Volkov", "Petrov", "Sokolov", "Morozov", "Popov", "Lebedev", "Kozlov", "Novikov", "Orlov", "Pavlov", "Zaitsev", "Belov", "Gusev", "Titov", "Krylov", "Frolov", "Sorokin", "Egorov", "Vlasov", "Antonov"]

func add_xp(v: int) -> void:
	if not alive:
		return
	xp += v
	while rank < RANK_XP.size() - 1 and xp >= RANK_XP[rank + 1]:
		rank += 1
		accuracy_bonus = 0.06 * rank
		if team == G.player_team and not G.spectate and G.hud:
			G.hud.promoted(self)

# arayüzde kişi adı yok: rütbe + sınıf
func display_name() -> String:
	return "%s %s" % [I18n.s(RANK_S[rank]), I18n.s(ROLE_TITLE.get(role, "Piyade"))]

const ROLE_TITLE := {"rifle": "Piyade", "mg": "Makineli Tüfekçi", "at": "Tanksavar", "medic": "Sıhhiye", "sniper": "Keskin Nişancı", "engineer": "İstihkâmcı", "mortar": "Havancı", "drone": "Drone Operatörü", "leader": "Ekip Lideri", "crew": "Mürettebat"}

func role_title() -> String:
	return {"rifle": "TÜFEKÇİ", "mg": "MAKİNELİ", "at": "TANKSAVAR", "medic": "SIHHİYE", "sniper": "KESKİN NİŞANCI", "engineer": "İSTİHKÂMCI", "mortar": "HAVANCI", "drone": "DRONE OPERATÖRÜ", "leader": "EKİP LİDERİ", "crew": "MÜRETTEBAT"}.get(role, "ER")

# timde yakında canlı ekip lideri var mı (isabet ve toparlanma bonusu)
func led() -> bool:
	if squad == null or role == "leader":
		return role == "leader"
	for m in squad.members:
		if is_instance_valid(m) and m.alive and m.role == "leader" and m.can_fight() and dist2(m) < 20.0:
			return true
	return false

var accuracy_bonus := 0.0
var mortar_rounds := 0
var mortar_cd := 0.0
var drone_cd := 6.0
var my_drone = null
var repair_target: Unit = null
var vehicle_in: Vehicle = null
var board_target: Vehicle = null
var fire_mode := 0          # 0 serbest ateş, 1 sadece karşılık, 2 ateşi kes
var stance_lock := -1       # -1 otomatik, yoksa STAND/CROUCH/PRONE
var retreating := false
var amove_dest := Vector3.INF
var order_pt := Vector3.ZERO
var suppress_pt := Vector3.ZERO
var suppress_until := 0.0
var rag: Ragdoll = null
var captor := -1
var intel_n := 0
var intel_t := 0.0
var escort_of: Soldier = null
var flinch_t := 0.0
var melee_cd := 0.0
var melee_target: Soldier = null
var melee_hit := false
var limp_t := 0.0
var pistol_cd := 0.0
var pistol_t := 0.0
var bearer := false
var carried := false
var body_lift := 0.0
var surrender_chk := 0.0
var low_ammo_said := false
var hosp_b: Building = null

func setup(t: int, rl: String) -> void:
	team = t
	role = rl
	kind = rl
	cap_cost = 1
	radius = 0.35
	sight = 42.0
	max_hp = 100.0
	hp = 100.0
	icon = "inf"
	title = ROLE_TITLE.get(rl, "Piyade")
	if rl == "sniper":
		sight = 78.0
	elif rl == "mortar":
		mortar_rounds = 24
	var W: Dictionary = WPN[rl]
	ammo = W["ammo"]
	mag = W["mag"]
	rockets = 4 if rl == "at" else 0
	grenades = 2 if not (rl in ["medic", "sniper", "drone"]) else 0
	smoke_nades = 1 if rl in ["rifle", "medic"] else 0
	if team == 1:
		sname = "%s %s" % [NAMES_RA[randi() % NAMES_RA.size()], NAMES_RB[randi() % NAMES_RB.size()]]
	else:
		sname = "%s %s" % [NAMES_A[randi() % NAMES_A.size()], NAMES_B[randi() % NAMES_B.size()]]
	body = SoldierBody.new()
	add_child(body)
	body.build(t, rl, G.map_kind == "winter")
	think_t = randf() * 0.4
	face_yaw = rotation.y
	dest = position

func weapon() -> Dictionary:
	return WPN[role]

func can_fight() -> bool:
	return alive and not (state in ["wounded", "dragged", "healing", "dead", "fly", "surrender", "prisoner", "dive", "aboard", "stretchered", "hospital", "stretcher", "slide"])

func incapacitated() -> bool:
	return state in ["wounded", "dragged", "healing", "stretchered"]

func hostile() -> bool:
	if not alive or state in ["surrender", "prisoner", "hospital"]:
		return false
	return not (state == "aboard" and not visible)

func apply_visibility() -> void:
	if state == "hospital":
		visible = false
		return
	super.apply_visibility()

func torso_h() -> float:
	if state in ["wounded", "dragged", "healing", "dead", "stretchered"]:
		return 0.2
	return [1.2, 0.72, 0.25][stance]

func eye_h() -> float:
	return [1.55, 0.95, 0.32][stance]

func aim_point() -> Vector3:
	return position + lean_cur + Vector3(0, torso_h(), 0)

# ------------------------------------------------------------ emirler
func cmd_move(p: Vector3, force := false) -> void:
	if not alive or incapacitated() or state == "fly":
		return
	_release_patient()
	build_site = null
	order = "move"
	force_move = force
	forced_target = null
	retreating = false
	amove_dest = Vector3.INF
	suppress_until = 0.0
	dest = G.on_ground(p)
	cover_type = 0
	to_cover = false
	popped = false
	_set_path(dest)
	state = "move"

func cmd_attack(u: Unit) -> void:
	if not alive or incapacitated():
		return
	_release_patient()
	forced_target = u
	order = "attack"
	force_move = false
	cover_type = 0
	var p := u.position
	var d := position.distance_to(p)
	var rng_w: float = weapon()["range"] * 0.8
	if d > rng_w:
		dest = p + (position - p).normalized() * rng_w
		_set_path(dest)
		state = "move"
	else:
		dest = position
		state = "idle"

func cmd_stop() -> void:
	if not alive or incapacitated():
		return
	_release_patient()
	order = ""
	forced_target = null
	retreating = false
	amove_dest = Vector3.INF
	suppress_until = 0.0
	build_site = null
	dest = position
	path = PackedVector3Array()
	if state in ["move", "build", "rescue"]:
		state = "idle"

func cmd_attack_move(p: Vector3) -> void:
	cmd_move(p)
	if order == "move":
		order = "amove"
		amove_dest = dest

func cmd_hold() -> void:
	cmd_stop()
	if alive and not incapacitated():
		order = "hold"

func cmd_retreat() -> void:
	if not alive or incapacitated() or state == "aboard":
		return
	var b := nearest_base()
	if b == null:
		return
	var away := position - b.position
	away.y = 0
	var p := b.position + (away.normalized() if away.length() > 0.1 else Vector3(1, 0, 0)) * (b.radius + 2.5)
	p += Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	cmd_move(G.grid.nearest_free(G.on_ground(p), Grid.M_INF), true)
	order = "retreat"
	retreating = true
	target = null
	cover_type = 0

# üsse dön ve iade: karargâha varınca birim sahadan çekilir, değeri (sağlıkla orantılı) iade edilir
func cmd_refund() -> void:
	cmd_retreat()
	if order == "retreat":
		order = "refund"
		refund_b = nearest_base()

var refund_b: Building = null

func _refund_check() -> void:
	if order != "refund" or refund_b == null or not is_instance_valid(refund_b):
		return
	if dist2(refund_b) < refund_b.radius + 6.0:
		var v := G.unit_value(self) * clampf(hp / max_hp, 0.0, 1.0) * 0.8
		G.supply[team] += v
		if team == G.player_team and not G.spectate:
			G.say(I18n.s("İade +%d") % int(v), position, team)
		alive = false
		G.remove_unit(self)
		if squad:
			squad.members.erase(self)
		queue_free()

func cmd_throw(p: Vector3, smoke: bool) -> bool:
	if not can_fight() or state in ["throw", "drag", "heal"]:
		return false
	if (smoke and smoke_nades <= 0) or (not smoke and grenades <= 0):
		return false
	_release_patient()
	build_site = null
	order_pt = G.on_ground(p)
	var d := Vector2(order_pt.x - position.x, order_pt.z - position.z).length()
	if d <= 20.0:
		order = ""
		_start_throw(order_pt, smoke)
	else:
		order = "smoke" if smoke else "grenade"
		var dir := (position - order_pt)
		dir.y = 0
		_set_path(G.grid.nearest_free(order_pt + dir.normalized() * 17.0, Grid.M_INF))
		state = "move"
		force_move = false
	return true

func cmd_suppress(p: Vector3) -> void:
	if not can_fight():
		return
	if state == "move" and order != "retreat":
		cmd_stop()
	suppress_pt = G.on_ground(p)
	suppress_until = G.time + 12.0
	threat_pos = suppress_pt
	threat_time = G.time

func nearest_base() -> Building:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == team and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	return best

func cmd_board(v: Vehicle) -> void:
	if not alive or incapacitated() or vehicle_in != null:
		return
	_release_patient()
	build_site = null
	board_target = v
	order = "board"
	_set_path(v.position)
	state = "move"

func board(v: Vehicle) -> void:
	vehicle_in = v
	board_target = null
	order = ""
	state = "aboard"
	target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	v.cargo.append(self)
	visible = v.riders_visible()
	if selected and G.player and not v.riders_visible():
		G.player.deselect(self)

func dismount(p: Vector3) -> void:
	if vehicle_in:
		vehicle_in.cargo.erase(self)
	vehicle_in = null
	position = G.grid.nearest_free(G.on_ground(p), Grid.M_INF)
	state = "idle"
	stance = CROUCH
	dest = position
	visible = true

func cmd_build(site: Node3D) -> void:
	if not alive or incapacitated():
		return
	_release_patient()
	build_site = site
	order = "build"
	var p: Vector3 = site.position + (position - site.position).normalized() * (site.radius + 0.8)
	dest = p
	_set_path(p)
	state = "move"

func _set_path(p: Vector3) -> void:
	path = G.grid.find_path(position, p, Grid.M_INF)
	path_i = 0

# ------------------------------------------------------------ ana döngü
func _process(dt: float) -> void:
	if not G.running:
		if body:
			body.animate(dt, _pose(), 0.0)
		return
	if dt <= 0.0:
		return
	tick_bubble(dt)
	state_t += dt
	if not alive:
		dead_t += dt
		if carried:
			body.animate(dt, "dead", 0.0)
			return
		if rag != null:
			if not rag.step(dt) and dead_t > 1.0:
				_settle_body()
				set_process(false)
			return
		if state == "fly":
			_fly(dt)
		body.animate(dt, "dead" if state != "fly" else "fly", 0.0, fly_ang)
		if dead_t > 3.0 and state != "fly":
			set_process(false)
		return
	if state == "aboard":
		_aboard(dt)
		return
	if state == "hospital":
		return
	if state == "stretchered":
		bleed = maxf(bleed, 20.0)
		body.animate(dt, "healing", 0.0)
		return
	_timers(dt)
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.28 + randf() * 0.12
		_think()
	_movement(dt)
	_combat(dt)
	if state == "dragged" or (state == "wounded" and downs <= 1):
		_pistol()
	var sp := vel.length()
	body.pistol = G.time - pistol_t < 0.8
	body.animate(dt, _pose(), sp, fly_ang if state == "fly" else (state_t / 0.7 if state == "throw" else (state_t / 0.5 if state == "melee" else 0.0)))
	lean_cur = lean_cur.lerp(lean if (popped and cover_type == 2) else Vector3.ZERO, clampf(dt * 6.0, 0, 1))
	body.position = Vector3(lean_cur.x, body_lift, lean_cur.z).rotated(Vector3.UP, -rotation.y)

func _aboard(dt: float) -> void:
	var v := vehicle_in
	if v == null or not is_instance_valid(v) or not v.alive:
		dismount(position)
		return
	var seat: Vector3 = v.seat_pos(self)
	position = seat
	rotation.y = v.heading + PI * (0.5 if v.cargo.find(self) % 2 == 0 else -0.5)
	body.animate(dt, "crouch", 0.0)
	body.position = Vector3.ZERO

func _timers(dt: float) -> void:
	flinch_t -= dt
	melee_cd -= dt
	pistol_cd -= dt
	limp_t -= dt
	fire_cd -= dt
	gren_cd -= dt
	mortar_cd -= dt
	drone_cd -= dt
	cover_cd -= dt
	popup_t -= dt
	if G.time - sup_t > 1.2:
		suppression = maxf(0.0, suppression - dt * (22.0 if led() else 16.0))
	if stress > 0.0 and G.time - stress_t > 3.0:
		stress = maxf(0.0, stress - dt * (5.0 if led() else 3.2) * (0.5 if suppression > 40.0 else 1.0))
		_stress_level()
	if reload_t > 0.0:
		reload_t -= dt
		if reload_t <= 0.0:
			var W := weapon()
			mag = mini(W["mag"], ammo)
	if state == "wounded" or state == "dragged" or state == "healing":
		if state != "healing":
			bleed -= dt
			if bleed <= 0.0:
				die(null)
				return
	res_t -= dt
	if res_t <= 0.0:
		res_t = 1.0
		_resupply()

func _resupply() -> void:
	var W := weapon()
	if ammo >= W["ammo"] and (role != "at" or rockets >= 4) and grenades >= 2 and (role != "mortar" or mortar_rounds >= 24):
		return
	for u in G.near(position, 16.0):
		if u is Building and u.team == team and u.done and u.is_base():
			# kg: 50 mermi 2 kg, roket 6 kg, 4 havan mermisi 8 kg, el bombası 1 kg
			if ammo < W["ammo"] and u.draw_stock(2.0):
				ammo = mini(W["ammo"], ammo + 50)
			if role == "at" and rockets < 4 and u.draw_stock(6.0):
				rockets = mini(4, rockets + 1)
			if role == "mortar" and mortar_rounds < 24 and u.draw_stock(8.0):
				mortar_rounds = mini(24, mortar_rounds + 4)
			if role != "medic" and grenades < 2 and u.draw_stock(1.0):
				grenades = mini(2, grenades + 1)
			if u.stock < 1.0 and u.btype == "fob" and randf() < 0.05:
				say("İKMAL YOK!")
			return
		if u is Soldier and not u.alive and u.loot > 0 and u.dist2(self) < 1.8:
			var take := mini(u.loot, W["ammo"] - ammo)
			ammo += take
			u.loot -= take
			return

# ------------------------------------------------------------ karar
func _think() -> void:
	match state:
		"fly", "dive", "dragged", "healing", "aboard", "slide", "stretcher", "stretchered", "hospital", "melee":
			return
		"surrender":
			_think_surrender_wait()
			return
		"prisoner":
			_think_prisoner()
			return
		"wounded":
			_think_wounded()
			return
		"escort":
			_think_escort()
			return
		"throw":
			return
		"dazed":
			if state_t > 2.4:
				state = "idle"
			return
	if stress_lv == 2 and not panic_fled and can_fight() and order != "retreat" and state in ["idle", "move"]:
		_panic_flee()
		return
	_scan()
	if can_fight() and _think_melee():
		return
	if can_fight() and _think_surrender():
		return
	match state:
		"rescue":
			_think_rescue()
		"drag", "heal":
			pass
		"build":
			if build_site == null or not is_instance_valid(build_site) or build_site.done or not build_site.alive:
				build_site = null
				state = "idle"
				order = ""
		"move":
			if order == "board" and board_target != null:
				if not is_instance_valid(board_target) or not board_target.alive:
					board_target = null
					order = ""
				elif dist2(board_target) < board_target.radius + 2.0:
					if board_target.needs_crew():
						board_target.add_crew(self)
						return
					if board_target.can_load():
						board(board_target)
						return
					else:
						say("ARAÇ DOLU!")
						board_target = null
						order = ""
				elif path_i >= path.size() or randf() < 0.2:
					_set_path(board_target.position)
				return
			if order == "amove" and target != null and not to_cover and fire_mode != 2:
				# saldırı hareketi: düşman görünce dur ve çatış
				state = "idle"
				dest = position
				path = PackedVector3Array()
			elif (order == "grenade" or order == "smoke") and Vector2(order_pt.x - position.x, order_pt.z - position.z).length() <= 19.0:
				path = PackedVector3Array()
				var sm := order == "smoke"
				order = ""
				if (sm and smoke_nades > 0) or (not sm and grenades > 0):
					_start_throw(order_pt, sm)
				else:
					state = "idle"
				return
			elif path_i >= path.size():
				_arrive()
			elif not force_move and suppression > 80 and randf() < 0.3:
				# ağır ateş altında yerde kal
				stance = PRONE
		"idle":
			_think_idle()
			_think_role()
	_stance()

func _arrive() -> void:
	state = "idle"
	path = PackedVector3Array()
	if to_cover:
		to_cover = false
		if vel.length() > 2.8 and randf() < 0.75:
			# koşarken siperin arkasına kayarak gir
			state = "slide"
			state_t = 0.0
			fly_vel = vel * 0.95
			return
	elif order == "build" and build_site != null and is_instance_valid(build_site):
		state = "build"
		return
	if order == "refund":
		_refund_check()
		return
	if order == "move" or order == "retreat" or order == "grenade" or order == "smoke" or order == "panic":
		if order == "retreat":
			suppression = 0.0
		order = ""
		force_move = false
		retreating = false
	elif order == "amove" and (amove_dest == Vector3.INF or position.distance_to(amove_dest) < 3.0):
		order = ""
		amove_dest = Vector3.INF
	elif order == "resupply" or order == "loot":
		order = ""

func _think_idle() -> void:
	var recent := G.time - threat_time < 9.0
	if order == "amove" and amove_dest != Vector3.INF and target == null and G.time - threat_time > 3.5 and G.time - last_hit > 3.0:
		dest = amove_dest
		cover_type = 0
		_set_path(dest)
		state = "move"
		return
	if recent and order != "hold" and cover_cd <= 0.0 and not force_move:
		cover_cd = 2.5 + randf()
		var prot := 0.0
		if cover_type > 0:
			prot = G.grid.cover_factor(position, 1.0, threat_pos)
		if cover_type == 0 or prot < 0.5:
			var claimed: Array = squad.claimed(self) if squad else []
			var c: Dictionary = G.grid.find_cover(dest, threat_pos, 6.5, claimed, position)
			if c["type"] > 0:
				cover_pos = c["pos"]
				cover_type = c["type"]
				if cover_pos.distance_to(position) > 0.3:
					to_cover = true
					_set_path(cover_pos)
					state = "move"
					if randf() < 0.15:
						say("SİPER AL!")
					return
			else:
				cover_type = 0
	if cover_type > 0 and position.distance_to(cover_pos) > 1.2 and state == "idle":
		cover_type = 0
	# hedefe yaklaş (saldırı emri)
	if forced_target != null and order != "hold":
		if not is_instance_valid(forced_target) or not forced_target.hostile():
			forced_target = null
			order = ""
		elif target != forced_target and dist2(forced_target) > 6.0:
			var p := forced_target.position
			dest = p + (position - p).normalized() * minf(dist2(forced_target) * 0.6, weapon()["range"] * 0.7)
			_set_path(dest)
			state = "move"
			return
	_think_grenade()
	_think_ammo()

func _think_role() -> void:
	match role:
		"engineer":
			_think_repair()
		"drone":
			_think_drone()

func _think_repair() -> void:
	if state != "idle" or G.time - threat_time < 4.0:
		repair_target = null
		return
	if repair_target == null or not is_instance_valid(repair_target) or not repair_target.alive or (repair_target.hp >= repair_target.max_hp and not (repair_target is Vehicle and (repair_target.has_crit() or repair_target.tracks_broken > 0.0 or repair_target.tires > 0))):
		repair_target = null
		var best := 20.0
		for u in G.friends_near(position, 20.0, team):
			if (u is Vehicle and u.vtype != "fpv" and (u.hp < u.max_hp or u.tracks_broken > 0.0 or u.tires > 0 or u.has_crit())) or (u is Building and u.done and u.hp < u.max_hp):
				var d := dist2(u)
				if d < best:
					best = d
					repair_target = u
	if repair_target == null:
		return
	var rr: float = repair_target.radius + 1.2
	if dist2(repair_target) > rr + 0.8:
		if path_i >= path.size():
			_set_path(repair_target.position + (position - repair_target.position).normalized() * rr)
		state = "move"
		return
	repair_target.hp = minf(repair_target.max_hp, repair_target.hp + 40.0 * 0.32)
	if repair_target is Vehicle and repair_target.tires > 0 and randf() < 0.12:
		repair_target.tires -= 1
	if repair_target is Vehicle and repair_target.tracks_broken > 0.0:
		repair_target.tracks_broken = maxf(0.0, repair_target.tracks_broken - 3.0)
	if repair_target is Vehicle:
		for ck in repair_target.crit:
			if repair_target.crit[ck] > 0:
				repair_target.crit_t[ck] -= 4.0
	_face_to(repair_target.position)
	state_t = 0.0
	if randf() < 0.3:
		Sfx.play3d("hammer", position, -10.0, 0.15, 0.2)

func _think_drone() -> void:
	if my_drone != null and is_instance_valid(my_drone) and my_drone.alive:
		return
	my_drone = null
	if drone_cd > 0.0:
		return
	var best: Unit = null
	var bs := 1e9
	for e in G.enemies_near(position, 85.0, team):
		if not e.alive or not G.is_seen(e, team) or e is Building:
			continue
		if e is Vehicle and e.is_air():
			continue
		var sc := dist2(e) - (40.0 if e is Vehicle else 0.0)
		if e is Soldier and e.incapacitated():
			continue
		if sc < bs:
			bs = sc
			best = e
	if best == null:
		return
	drone_cd = 24.0
	var dr: Vehicle = G.main.spawn_vehicle(team, "fpv", position + Vector3(0, 0, 0), rotation.y)
	dr.forced_target = best
	dr.operator = self
	my_drone = dr
	say("DRONE HAVADA!")

func _think_grenade() -> void:
	if grenades <= 0 or gren_cd > 0.0 or state != "idle" or suppression > 75 or fire_mode != 0:
		return
	var tp := Vector3.ZERO
	var ok := false
	if target is Soldier and target.alive:
		var d := dist2(target)
		if d > 8.0 and d < 24.0:
			var cov := G.grid.cover_factor(target.position, target.torso_h(), position)
			var cluster := 0
			for e in G.enemies_near(target.position, 4.0, team):
				if e is Soldier and e.can_fight():
					cluster += 1
			if cov > 0.45 or cluster >= 3:
				tp = target.position
				ok = true
	elif target == null and G.time - threat_time < 3.0:
		var d2 := Vector2(threat_pos.x - position.x, threat_pos.z - position.z).length()
		if d2 > 8.0 and d2 < 20.0 and randf() < 0.25:
			tp = threat_pos
			ok = true
	if ok and randf() < 0.35:
		_start_throw(tp, false)

func _start_throw(tp: Vector3, smoke: bool) -> void:
	state = "throw"
	state_t = 0.0
	throw_released = false
	throw_smoke = smoke
	var d := position.distance_to(tp)
	var err := d * 0.09
	throw_to = tp + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	gren_cd = 14.0 + randf() * 8.0
	_face_to(tp, true)
	say("SİS!" if smoke else "EL BOMBASI!")

func _scan() -> void:
	if not can_fight() or retreating or fire_mode == 2:
		target = null
		return
	if fire_mode == 1 and G.time - last_hit > 10.0 and G.time - sup_t > 8.0:
		target = null
		return
	var W := weapon()
	var rng_w: float = W["range"]
	var eye := position + Vector3(0, 1.55 if cover_type == 1 else eye_h(), 0)
	if cover_type == 2:
		eye += lean
	# mevcut hedefi koru
	if target != null and is_instance_valid(target) and target.hostile() and dist2(target) < rng_w * 1.1 and G.is_seen(target, team):
		if not (target is Soldier and target.incapacitated()) and G.grid.los(eye, target.aim_point()):
			threat_pos = target.position
			threat_time = G.time
			return
	target = null
	var cands: Array = []
	for e in G.enemies_near(position, rng_w + 12.0, team):
		if not G.is_seen(e, team):
			continue
		var d := dist2(e)
		var sc := d
		if e is Soldier:
			if not e.alive:
				continue
			if e.incapacitated():
				sc += 40.0
		elif e is Vehicle:
			if not e.alive:
				continue
			if role == "at" and rockets > 0:
				sc -= 40.0
			elif e.vtype == "fpv":
				sc -= 30.0 if d < 30.0 else 0.0
			elif role == "sniper":
				sc += 1000.0
			else:
				sc += 12.0
		elif e is Building:
			if not e.alive:
				continue
			sc += 30.0 if not (role == "at" and rockets > 0) else -10.0
		if d > rng_w * (1.25 if (role == "at" and not (e is Soldier)) else 1.0):
			if d < rng_w + 12.0:
				threat_pos = e.position
				threat_time = maxf(threat_time, G.time - 6.0)
			continue
		if e == forced_target:
			sc -= 100.0
		elif e == attacker:
			sc -= 6.0
		cands.append([sc, e])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var n := 0
	for c in cands:
		n += 1
		if n > 4:
			break
		var e: Unit = c[1]
		var ap: Vector3 = e.aim_point()
		var ok := G.grid.los(eye, ap)
		if not ok and cover_type == 2:
			# diğer köşeden dene
			var alt := position + Vector3(0, 1.55, 0) - lean
			if G.grid.los(alt, ap):
				lean = -lean
				ok = true
		if ok:
			target = e
			threat_pos = e.position
			threat_time = G.time
			return

func _stance() -> void:
	if stress_lv == 2 and state == "idle":
		stance = PRONE
		return
	if state == "escort":
		stance = CROUCH if suppression > 50 else STAND
		return
	if stance_lock >= 0 and state in ["idle", "move"] and not force_move:
		stance = stance_lock
		return
	if state == "move":
		stance = CROUCH if (suppression > 55 and not force_move) else STAND
		if suppression > 85 and not force_move:
			stance = PRONE
		return
	if state != "idle":
		return
	var recent := G.time - threat_time < 8.0
	if G.grid.in_trench(position):
		stance = CROUCH if (popped or target != null) else PRONE
		return
	if cover_type == 1:
		stance = STAND if popped else CROUCH
	elif cover_type == 2:
		stance = STAND
	elif recent:
		stance = PRONE if suppression > 40 else CROUCH
	else:
		stance = STAND
	if role == "sniper" and cover_type == 0 and not G.grid.in_trench(position):
		stance = PRONE
	if suppression > 80 and cover_type != 1:
		stance = PRONE

# ------------------------------------------------------------ hareket
func _movement(dt: float) -> void:
	var want := Vector3.ZERO
	var spd := 0.0
	match state:
		"move", "rescue":
			spd = RUN_SPEED
			if stance == CROUCH:
				spd = 1.9
			elif stance == PRONE:
				spd = 0.7
			if state == "rescue":
				spd = RUN_SPEED * 1.05
			if limp_t > 0.0:
				spd = minf(spd, 1.5)
			if flinch_t > 0.0:
				spd *= 0.4
			if body_lift > 0.2:
				spd = minf(spd, 2.0)
			want = _follow(spd)
		"escort":
			want = _escort_move()
		"stretcher":
			want = _stretcher_move()
		"prisoner":
			want = _follow(1.5)
		"slide":
			want = fly_vel
			fly_vel = fly_vel.lerp(Vector3.ZERO, clampf(dt * 4.5, 0, 1))
			if state_t > 0.5:
				state = "idle"
				stance = CROUCH
		"melee":
			if state_t > 0.22 and not melee_hit:
				melee_hit = true
				if melee_target != null and is_instance_valid(melee_target) and melee_target.alive and dist2(melee_target) < 2.3:
					melee_target.take_damage(randf_range(45.0, 80.0), self, "melee")
					melee_target.add_suppression(40.0, position)
					Sfx.play3d("hammer", position, -4.0, 0.25)
			if state_t > 0.6:
				state = "idle"
				melee_cd = randf_range(1.0, 1.6)
		"drag":
			want = _follow(1.25)
		"wounded":
			want = _follow(0.35)
		"dive":
			want = fly_vel
			fly_vel = fly_vel.lerp(Vector3.ZERO, clampf(dt * 4.0, 0, 1))
			if state_t > 0.5:
				state = "idle"
				stance = PRONE
				suppression = maxf(suppression, 60.0)
		"fly":
			_fly(dt)
			return
		"dazed":
			want = Vector3(sin(G.time * 1.7 + position.x), 0, cos(G.time * 1.3 + position.z)) * 0.6
		"throw":
			_throw(dt)
	# ayrışma
	var sep := Vector3.ZERO
	if state != "dragged" and state != "drag":
		for o in G.near(position, 1.6):
			if o == self or o == patient:
				continue
			var dv = position - o.position
			dv.y = 0
			var dl = dv.length()
			if o is Soldier:
				if not o.alive or o.state == "dragged":
					continue
				if dl < 0.7 and dl > 0.001:
					sep += dv / dl * (0.7 - dl) * 3.0
			elif o is Vehicle and o.alive:
				pass
		for o in G.near(position, 4.5):
			if o is Vehicle and o.alive:
				var dv = position - o.position
				dv.y = 0
				var dl = dv.length()
				var rr: float = o.radius + 0.5
				if dl < rr and dl > 0.001:
					sep += dv / dl * (rr - dl) * 6.0
	vel = want
	var mv := (want + sep) * dt
	if mv.length_squared() > 0.0:
		var np := position + mv
		np.x = clampf(np.x, 1.0, G.MAP - 1.0)
		np.z = clampf(np.z, 1.0, G.MAP - 1.0)
		var hn := G.grid.height_at(np)
		var vault_ok := want.length() > 0.5 and state in ["move", "rescue", "escort", "prisoner", "stretcher"] and hn < 1.15
		if ((hn < 0.45 or vault_ok) and not G.grid.is_water(np)) or G.grid.height_at(position) >= 0.45:
			position = np
		else:
			var nx := Vector3(np.x, 0, position.z)
			var nz := Vector3(position.x, 0, np.z)
			if G.grid.height_at(nx) < 0.45:
				position = nx
			elif G.grid.height_at(nz) < 0.45:
				position = nz
	position.y = 0.0
	if G.grid.in_trench(position):
		position.y = G.terrain.ground_h(position)
	# alçak duvar / engelin üstünden atlama
	var hh := G.grid.height_at(position)
	body_lift = lerpf(body_lift, hh + 0.02 if (hh >= 0.3 and hh < 1.15) else 0.0, clampf(dt * 14.0, 0, 1))
	# yön
	var aiming := target != null and is_instance_valid(target) and can_fight() and state in ["idle", "move", "escort"] and (burst_left > 0 or fire_cd < 0.6 or popped)
	if state == "melee" and melee_target != null and is_instance_valid(melee_target):
		face_yaw = _yaw_of(melee_target.position - position)
	elif state == "drag" or (state == "stretcher" and _stretcher_back()):
		if want.length() > 0.05:
			face_yaw = _yaw_of(-want)
	elif state == "escort" and not aiming:
		face_yaw = _yaw_of(threat_pos - position) if G.time - threat_time < 10.0 else _yaw_of(want) if want.length() > 0.2 else face_yaw
	elif state == "heal" or state == "build" or state == "rescue":
		var tp: Vector3 = patient.position if patient != null and is_instance_valid(patient) else (build_site.position if build_site != null and is_instance_valid(build_site) else position + want)
		if state == "rescue" and want.length() > 0.1:
			face_yaw = _yaw_of(want)
		elif tp.distance_to(position) > 0.1:
			face_yaw = _yaw_of(tp - position)
	elif aiming and (want.length() < 2.0 or randf() < 1.0):
		face_yaw = _yaw_of(target.position - position)
	elif want.length() > 0.2:
		face_yaw = _yaw_of(want)
	elif G.time - threat_time < 8.0 and state == "idle":
		face_yaw = _yaw_of(threat_pos - position)
	rotation.y = lerp_angle(rotation.y, face_yaw, clampf(dt * 8.0, 0, 1))

func _follow(spd: float) -> Vector3:
	while path_i < path.size():
		var tp := path[path_i]
		var d := Vector3(tp.x - position.x, 0, tp.z - position.z)
		var L := d.length()
		var near_end := path_i == path.size() - 1
		if L < (0.25 if near_end else 0.6):
			path_i += 1
			continue
		var s := spd
		if near_end and L < 1.0:
			s = maxf(0.6, spd * L)
		return d / L * s
	return Vector3.ZERO

static func _yaw_of(d: Vector3) -> float:
	return atan2(-d.x, -d.z)

func _face_to(p: Vector3, instant := false) -> void:
	face_yaw = _yaw_of(p - position)
	if instant:
		rotation.y = face_yaw

func _fly(dt: float) -> void:
	position += fly_vel * dt
	fly_vel.y -= 15.0 * dt
	fly_ang += fly_spin * dt
	if position.y <= 0.0 and fly_vel.y < 0.0:
		position.y = 0.0
		fly_ang = 0.0
		G.fx.impact(position, "dirt")
		if not alive:
			state = "dead"
		elif hp <= 0.0:
			_down(null, true)
		else:
			state = "dazed"
			state_t = 0.0
			stance = STAND
			if randf() < 0.4:
				say("...")
	position.x = clampf(position.x, 1.0, G.MAP - 1.0)
	position.z = clampf(position.z, 1.0, G.MAP - 1.0)

func _throw(_dt: float) -> void:
	if not throw_released and state_t > 0.42:
		throw_released = true
		var hand := position + Vector3(0, 1.8, 0)
		if throw_smoke:
			smoke_nades -= 1
		else:
			grenades -= 1
		G.bal.grenade(hand, throw_to, team, self, throw_smoke)
	if state_t > 0.75:
		state = "rescue" if patient != null else "idle"

# ------------------------------------------------------------ ateş
func _combat(_dt: float) -> void:
	if G.deploy_t > 0.0 or not can_fight() or state in ["throw", "drag", "heal", "build", "dazed", "rescue", "melee"] or flinch_t > 0.0 or bearer:
		popped = false
		return
	if role == "mortar" and state == "idle":
		_mortar_fire()
	if reload_t > 0.0:
		popped = false if cover_type == 1 else popped
		return
	if G.time < suppress_until and state == "idle" and fire_mode != 2 and role != "mortar":
		# baskı ateşi emri: hedef görünmese de bölgeyi ateş altında tut
		popped = true
		if fire_cd <= 0.0 and ammo > 0:
			_area_fire(suppress_pt, 4.0)
		return
	var t := target
	var covering := G.time < covering_until
	if t == null or not is_instance_valid(t) or not t.alive:
		target = null
		popped = false
		if covering and G.time - threat_time < 6.0 and fire_cd <= 0.0 and ammo > 0:
			_area_fire()
		return
	if state == "move" and (force_move or stance == PRONE):
		return
	if role == "mortar":
		return
	# tanksavar roket
	if role == "at" and rockets > 0 and (t is Vehicle or t is Building):
		if state == "move":
			return
		rocket_aim += _dt
		popped = true
		if rocket_aim > 1.3 and fire_cd <= 0.0:
			rocket_aim = 0.0
			rockets -= 1
			fire_cd = 4.5
			var mp := body.muzzle_pos()
			G.bal.rocket(mp, t.aim_point(), team, self, t)
			Sfx.play3d("rpg", position, 2.0)
			G.fx.muzzle(mp, (t.aim_point() - mp).normalized(), true)
			for i in 4:
				G.fx.emit(Fx.P_SMOKE, position + Vector3(0, 1.2, 0), (position - t.position).normalized() * randf_range(2, 5) + Vector3(0, 0.5, 0), randf_range(1.0, 1.8), 0.4, 1.6, -0.1, 2.0, Color(0.8, 0.78, 0.74, 0.5))
			say("ROKET!")
		return
	rocket_aim = 0.0
	# alçak siperde: kalk-ateş et-eğil döngüsü
	if cover_type == 1 and state == "idle":
		if not popped and popup_t <= 0.0 and suppression < 62.0:
			popped = true
			popup_t = randf_range(1.6, 3.4) * (1.5 if covering else 1.0)
		elif popped and (popup_t <= 0.0 or suppression > 72.0):
			popped = false
			popup_t = randf_range(0.8, 2.0)
		if not popped:
			return
	elif cover_type == 2 and state == "idle":
		if lean == Vector3.ZERO:
			var d := (t.position - position)
			d.y = 0
			lean = Vector3(-d.z, 0, d.x).normalized() * 0.55
		popped = suppression < 85.0
		if not popped:
			return
	else:
		popped = true
		if suppression > 88.0 and randf() < 0.7:
			return
	if fire_cd > 0.0 or stress_lv == 2:
		return
	var W := weapon()
	if burst_left <= 0:
		burst_left = randi_range(W["b0"], W["b1"])
		if ammo < 40:
			burst_left = 1
	_shoot(t)
	burst_left -= 1
	var rof: float = W["rof"] * (0.75 if covering else 1.0)
	if ammo < 40:
		rof *= 4.0
	fire_cd = rof if burst_left > 0 else randf_range(W["p0"], W["p1"]) * (0.7 if covering else 1.0)
	fire_cd *= [1.0, 1.35, 2.0][stress_lv]

func _mortar_fire() -> void:
	if mortar_cd > 0.0 or mortar_rounds <= 0:
		return
	var best: Unit = null
	var bs := 1e9
	for e in G.enemies_near(position, 85.0, team):
		if not e.alive or not G.is_seen(e, team) or (e is Vehicle and e.is_air()):
			continue
		var d := dist2(e)
		if d < 16.0:
			continue
		var sc := d
		if e is Soldier:
			if e.incapacitated():
				continue
			# kalabalık hedefleri tercih et
			sc -= G.enemies_near(e.position, 6.0, team).size() * 8.0
		if sc < bs:
			bs = sc
			best = e
	if best == null:
		return
	mortar_cd = randf_range(4.0, 5.5)
	mortar_rounds -= 1
	var d2 := dist2(best)
	var err := d2 * 0.06 + 1.5
	var tp := best.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	G.bal.mortar(position + Vector3(0, 1.0, 0), tp, team, self)
	_face_to(best.position)
	Sfx.play3d("mortar", position, 0.0)
	G.fx.muzzle(position + Vector3(0, 1.2, 0), Vector3.UP, true)
	if randf() < 0.2:
		say("ATEŞ! HAVAN!")

func _shoot(t: Unit) -> void:
	var W := weapon()
	if ammo <= 0:
		if randf() < 0.05:
			say("MERMİ BİTTİ!")
		fire_cd = 2.0
		return
	mag -= 1
	ammo -= 1
	shots += 1
	if ammo < 40 and not low_ammo_said:
		low_ammo_said = true
		say("MERMİ AZ!")
	if mag <= 0:
		reload_t = W["reload"] * (1.0 + stress_lv * 0.4)
		burst_left = 0
		if randf() < 0.15:
			say("ŞARJÖR!")
	var mp := body.muzzle_pos()
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	G.fx.muzzle(mp, dir, role == "mg")
	Sfx.play3d(W["snd"], mp, -2.0 if role != "mg" else 0.0, 0.1, 0.02)
	var d := mp.distance_to(tp)
	var chance := _hit_chance(t, d)
	var impact := tp
	var hit := randf() < chance
	if hit:
		var dmg: float = W["dmg"] * randf_range(0.8, 1.25)
		t.take_damage(dmg, self, "bullet")
		if t is Vehicle and t.armor > 0:
			G.fx.impact(tp, "metal")
	else:
		var side := Vector3(-dir.z, 0, dir.x)
		impact = tp + side * randf_range(-1.3, 1.3) + dir * randf_range(-0.5, 3.0)
		impact.y = randf_range(0.0, tp.y + 0.4)
		# alçaksa yere çarpar
		if impact.y < 0.25 or randf() < 0.5:
			impact.y = 0.02
		var hv := G.grid.height_at(impact)
		G.fx.impact(impact, "wall" if hv > impact.y else "dirt")
		if t is Soldier:
			t.add_suppression(W["sup"], position)
		for o in G.near(impact, 2.5):
			if o is Soldier and o != t and o.team != team and o.alive:
				o.add_suppression(W["sup"] * 0.5, position)
		if randf() < 0.18:
			Sfx.play3d("whiz", impact, -8.0, 0.2, 0.08)
	if shots % W["tr"] == 0:
		G.fx.tracer(mp, impact, 240.0, Color(1.0, 0.62, 0.25) if team == 0 else Color(1.0, 0.45, 0.2))

func _area_fire(center := Vector3.INF, spread := 3.0) -> void:
	# örtme ateşi: hedef görünmese de tehdit bölgesine
	if center == Vector3.INF:
		center = threat_pos
	var W := weapon()
	var mp := body.muzzle_pos()
	var p := center + Vector3(randf_range(-spread, spread), randf_range(0.2, 1.4), randf_range(-spread, spread))
	if not G.grid.los(position + Vector3(0, eye_h(), 0), p, 0.75, 1.5):
		fire_cd = 0.6
		return
	mag -= 1
	ammo -= 1
	shots += 1
	if mag <= 0:
		reload_t = W["reload"] * (1.0 + stress_lv * 0.4)
	G.fx.muzzle(mp, (p - mp).normalized(), role == "mg")
	Sfx.play3d(W["snd"], mp, -3.0, 0.1, 0.02)
	G.fx.impact(Vector3(p.x, 0.02, p.z), "dirt")
	for o in G.near(p, 3.0):
		if o is Soldier and o.team != team and o.alive:
			o.add_suppression(W["sup"] * 1.2, position)
	if shots % W["tr"] == 0:
		G.fx.tracer(mp, p, 240.0)
	fire_cd = W["rof"] * 1.3 if randf() < 0.8 else randf_range(0.4, 0.9)
	_face_to(p)

func _hit_chance(t: Unit, d: float) -> float:
	var W := weapon()
	var c: float = W["acc"] * (1.0 - pow(clampf(d / W["range"], 0.0, 1.0), 1.3) * 0.65)
	if led():
		c *= 1.12
	if t is Soldier:
		c *= [1.0, 0.72, 0.45][t.stance]
		if t.vel.length() > 1.5:
			c *= 0.75
		var cov := G.grid.cover_factor(t.position, t.torso_h(), position)
		c *= 1.0 - cov * 0.78
	else:
		c = clampf(c * 2.0, 0.0, 0.95)
	if vel.length() > 0.5:
		c *= 0.5
	c *= 1.0 - suppression / 170.0
	c *= [1.0, 0.78, 0.5][stress_lv]
	c *= 1.0 + accuracy_bonus
	return clampf(c, 0.02, 0.95)

func add_stress(v: float) -> void:
	if not alive or incapacitated() or state in ["prisoner", "surrender", "hospital", "aboard"]:
		return
	if led():
		v *= 0.7
	stress = minf(100.0, stress + v)
	stress_t = G.time
	_stress_level()

func _stress_level() -> void:
	var nl := 2 if stress >= 85.0 else (1 if stress >= 50.0 else 0)
	# gecikmeli dönüş: panik 55'in altına, sarsılma 35'in altına inince biter
	if stress_lv == 2 and stress > 55.0:
		nl = 2
	elif stress_lv >= 1 and nl == 0 and stress > 35.0:
		nl = 1
	if nl == stress_lv:
		return
	if nl > stress_lv:
		say("PANİK!" if nl == 2 else ["SARSILDIM!", "KAFAM GİTTİ!", "ÇOK YAKINDI!"][randi() % 3], 2.0)
	if nl < 2:
		panic_fled = false
	stress_lv = nl

# panik: tehditten uzağa kaç (en yakın siper/üs yönü), sonra yere yat
func _panic_flee() -> void:
	panic_fled = true
	var away := position - threat_pos
	away.y = 0.0
	if away.length() < 0.5 or G.time - threat_time > 12.0:
		var b := nearest_base()
		away = (b.position - position) if b != null else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		away.y = 0.0
	var p := position + away.normalized() * 16.0
	cmd_move(G.grid.nearest_free(G.on_ground(p), Grid.M_INF), true)
	order = "panic"
	target = null
	burst_left = 0

func add_suppression(v: float, from: Vector3) -> void:
	if not alive:
		return
	if retreating:
		v *= 0.3
	suppression = minf(100.0, suppression + v)
	sup_t = G.time
	add_stress(v * 0.32)
	if G.time - threat_time > 2.0 or target == null:
		threat_pos = from
		threat_time = G.time
	if suppression > 75.0 and randf() < 0.02:
		say(["BASTIRILDIK!", "KAFANI KALDIRMA!", "SİPER!"][randi() % 3])

# ------------------------------------------------------------ hasar
func take_damage(amount: float, src, _kind := "bullet") -> void:
	if not alive:
		return
	if src != null and is_instance_valid(src):
		attacker = src
		threat_pos = src.position
		threat_time = G.time
	last_hit = G.time
	G.fx.impact(aim_point(), "blood")
	if incapacitated():
		if _kind != "bullet" or randf() < 0.6:
			die(src)
		return
	if retreating:
		amount *= 0.7
	hp -= amount
	suppression = minf(100.0, suppression + 18.0)
	sup_t = G.time
	add_stress(20.0)
	if hp <= 0.0:
		_down(src, _kind != "bullet")
	elif randf() < 0.2:
		say("VURULDUM!")

func on_blast(p: Vector3, r: float, dmg: float, d: float, src) -> void:
	if alive:
		add_stress(clampf(1.0 - d / (r * 2.6), 0.0, 1.0) * (35.0 + dmg * 0.15))
	var away := position - p
	away.y = 0
	var al := away.length()
	away = away / al if al > 0.01 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if not alive:
		if d < r * 0.9 and not carried and rag != null:
			rag.push(away * randf_range(3.0, 6.0) * (1.3 - d / r) + Vector3(0, randf_range(3.0, 5.5), 0))
			set_process(true)
			dead_t = 0.0
		return
	if state in ["hospital", "stretchered"]:
		return
	if d > r:
		if d < r * 1.8 and can_fight() and state != "fly":
			add_suppression(25.0, p)
			flinch_t = randf_range(0.35, 0.6)
		return
	var k := 1.0 - clampf(d / r, 0.0, 1.0)
	var blocked := not G.grid.los(p + Vector3(0, 0.4, 0), aim_point(), 0.2, 0.2)
	var dm := dmg * (0.3 + 0.7 * k)
	if blocked:
		dm *= 0.25
	if stance == PRONE or G.grid.in_trench(position):
		dm *= 0.55
	if incapacitated():
		die(src)
	else:
		hp -= dm
	if src != null and is_instance_valid(src):
		threat_pos = src.position
		threat_time = G.time
	if not blocked and k > 0.2 and alive and state != "fly":
		_release_patient()
		state = "fly"
		state_t = 0.0
		fly_vel = away * randf_range(3.0, 6.5) * (0.4 + k) + Vector3(0, randf_range(3.0, 6.0) * (0.5 + k * 0.6), 0)
		fly_spin = randf_range(6, 12) * (1.0 if randf() < 0.5 else -1.0)
		fly_ang = 0.0
		position.y = 0.05
		if hp <= 0.0 and randf() < 0.7:
			die(src, true)
		return
	if hp <= 0.0 and alive:
		_down(src, true)
	elif alive:
		add_suppression(40.0, p)

func _down(src, explosive := false) -> void:
	if not alive:
		return
	var p_die := 0.3 + 0.18 * downs + (0.3 if explosive else 0.0)
	if downs >= 2 or hp < -70.0 or randf() < p_die:
		die(src)
		return
	downs += 1
	hp = 1.0
	_release_patient()
	state = "wounded"
	state_t = 0.0
	stance = PRONE
	bleed = randf_range(38.0, 55.0)
	target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	say(["SIHHİYE!", "SIHHİYE! VURULDUM!", "YARDIM EDİN!"][randi() % 3], 3.0)
	G.fx.blood_pool(position)

func die(src, keep_fly := false) -> void:
	if not alive:
		return
	alive = false
	_release_patient()
	if rescuer != null and is_instance_valid(rescuer):
		rescuer.patient = null
		if rescuer.state in ["drag", "heal", "rescue"]:
			rescuer.state = "idle"
	rescuer = null
	var rv := Vector3(randf_range(-0.6, 0.6), 0.4, randf_range(-0.6, 0.6))
	var spin := 0.0
	if state == "fly":
		rv = fly_vel
		spin = fly_spin * 0.3
	elif src != null and is_instance_valid(src):
		var away: Vector3 = position - src.position
		away.y = 0
		if away.length() > 0.01:
			rv = away.normalized() * randf_range(1.2, 2.8) + Vector3(0, randf_range(0.4, 1.4), 0)
	state = "dead"
	keep_fly = keep_fly
	for f in G.friends_near(position, 10.0, team):
		if f is Soldier and f != self:
			f.add_stress(10.0)
	if role == "leader" and squad:
		for m in squad.members:
			if is_instance_valid(m) and m != self:
				m.add_stress(20.0)
	rag = Ragdoll.new()
	rag.start(body, rv, spin)
	set_process(true)
	dead_t = 0.0
	died_at = G.time
	target = null
	vel = Vector3.ZERO
	if escort_of != null:
		escort_of = null
	loot = mini(ammo, 90)
	lean = Vector3.ZERO
	G.credit_kill(src, self)
	G.fx.blood_pool(position)
	if selected and G.player:
		G.player.deselect(self)
	if squad:
		squad.on_death(self)
	G.main.register_body(self)

# ------------------------------------------------------------ yaralı / kurtarma
func _think_wounded() -> void:
	if rescuer != null and (not is_instance_valid(rescuer) or not rescuer.alive or rescuer.patient != self):
		rescuer = null
	if rescuer != null:
		path = PackedVector3Array()
		return
	if downs <= 1 and G.time - threat_time < 8.0 and path_i >= path.size() and randf() < 0.3:
		var c: Dictionary = G.grid.find_cover(position, threat_pos, 4.0, [], position)
		if c["type"] > 0 and c["pos"].distance_to(position) > 0.5:
			_set_path(c["pos"])
	if randf() < 0.06:
		say("SIHHİYE!", 2.0)

func start_rescue(p: Soldier) -> void:
	_release_patient()
	patient = p
	p.rescuer = self
	state = "rescue"
	state_t = 0.0
	build_site = null
	_set_path(p.position)
	say("GELİYORUM!" if randf() < 0.5 else "ÖRT BENİ!")
	# sis bombası ile gizle
	if smoke_nades > 0 and G.time - threat_time < 6.0 and randf() < 0.45:
		var dir := (threat_pos - p.position)
		dir.y = 0
		if dir.length() > 6.0:
			_start_throw(p.position + dir.normalized() * 4.0, true)

func _think_rescue() -> void:
	if patient == null or not is_instance_valid(patient) or not patient.alive or not patient.incapacitated():
		_release_patient()
		state = "idle"
		return
	var d := dist2(patient)
	if d > 1.2:
		if path_i >= path.size() or path.size() > 0 and path[path.size() - 1].distance_to(patient.position) > 1.5:
			_set_path(patient.position)
		return
	# ulaştı: açıkta mı?
	var exposed := G.time - threat_time < 7.0 and G.grid.cover_factor(patient.position, 0.6, threat_pos) < 0.5
	if exposed:
		var c: Dictionary = G.grid.find_cover(patient.position, threat_pos, 9.0, [], position)
		var dd: Vector3
		if c["type"] > 0:
			dd = c["pos"]
		else:
			var away := patient.position - threat_pos
			away.y = 0
			dd = G.grid.nearest_free(patient.position + away.normalized() * 7.0, Grid.M_INF)
		drag_dest = dd
		state = "drag"
		state_t = 0.0
		patient.state = "dragged"
		_set_path(drag_dest)
		# biri yanında geri geri yürüyüp ateş ederek örtsün
		var esc: Soldier = null
		var be := 20.0
		for fr in G.friends_near(position, 20.0, team):
			if fr is Soldier and fr != self and fr != patient and fr.can_fight() and fr.state == "idle" and fr.ammo > 20 and not fr.bearer and fr.order != "hold":
				var de: float = fr.dist2(self)
				if de < be:
					be = de
					esc = fr
		if esc != null:
			esc.start_escort(self)
		if randf() < 0.5:
			say("DAYAN!")
	else:
		_begin_heal()

func _begin_heal() -> void:
	state = "heal"
	heal_t = 4.0 if role == "medic" else 8.0
	if patient:
		patient.state = "healing"

func _process_drag_heal(dt: float) -> void:
	if state == "drag":
		if patient == null or not is_instance_valid(patient) or not patient.alive:
			_release_patient()
			state = "idle"
			return
		var mdir := vel
		mdir.y = 0
		if mdir.length() > 0.05:
			mdir = mdir.normalized()
			patient.position = position - mdir * 0.95
			patient.rotation.y = atan2(mdir.x, mdir.z)
		if path_i >= path.size() or state_t > 14.0:
			_begin_heal()
	elif state == "heal":
		if patient == null or not is_instance_valid(patient) or not patient.alive:
			_release_patient()
			state = "idle"
			return
		heal_t -= dt
		if heal_t <= 0.0:
			add_xp(5)
			patient.revive()
			patient = null
			state = "idle"
			dest = position

func revive() -> void:
	state = "idle"
	state_t = 0.0
	max_hp = maxf(40.0, 100.0 - 25.0 * downs)
	hp = max_hp
	rescuer = null
	stance = CROUCH
	suppression = 40.0
	dest = position
	order = ""
	say("TEŞEKKÜRLER!" if randf() < 0.5 else "İYİYİM!")

func _release_patient() -> void:
	if patient != null and is_instance_valid(patient):
		if patient.rescuer == self:
			patient.rescuer = null
		if patient.alive and patient.state in ["dragged", "healing"]:
			patient.state = "wounded"
	patient = null

func on_drone(p: Vector3) -> void:
	if not can_fight() or state in ["throw", "drag", "heal", "dive", "aboard"]:
		return
	if randf() < 0.55:
		var away := position - p
		away.y = 0
		away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0)
		state = "dive"
		state_t = 0.0
		fly_vel = away * 5.0
		stance = PRONE
		face_yaw = _yaw_of(away)
		say("DRONE!")

func on_grenade(g_pos: Vector3, fuse_left: float, thrower: Unit) -> bool:
	# true: geri attı (bomba yok edilir)
	if not can_fight() or state in ["throw", "drag", "heal"]:
		return false
	var d := Vector2(g_pos.x - position.x, g_pos.z - position.z).length()
	if d < 1.7 and fuse_left > 1.3 and suppression < 60.0 and randf() < 0.12 and thrower != null and is_instance_valid(thrower):
		_start_throw(thrower.position, false)
		grenades += 1
		say("GERİ AL!")
		return true
	if randf() < 0.75:
		var away := position - g_pos
		away.y = 0
		away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0)
		state = "dive"
		state_t = 0.0
		fly_vel = away * 5.5
		stance = PRONE
		face_yaw = _yaw_of(away)
		popped = false
		if randf() < 0.4:
			say("BOMBA!")
	return false

func _pose() -> String:
	if role == "mortar" and state == "idle" and mortar_cd > 2.5:
		return "crouch_aim"
	if flinch_t > 0.0 and state in ["idle", "move", "escort"]:
		return "flinch"
	if body_lift > 0.2 and state in ["move", "rescue", "escort", "prisoner", "stretcher"]:
		return "vault"
	match state:
		"slide":
			return "slide"
		"melee":
			return "melee"
		"prisoner":
			return "surrender"
		"stretcher":
			return "carry" if not _stretcher_back() else "dragging"
		"stretchered":
			return "healing"
		"escort":
			return "aim" if target != null else "stand"
		"dead":
			return "dead"
		"wounded":
			return "wounded"
		"healing":
			return "healing"
		"dragged":
			return "dragged"
		"fly":
			return "fly"
		"dazed":
			return "dazed"
		"dive":
			return "prone"
		"throw":
			return "throw"
		"drag":
			return "dragging"
		"heal", "build":
			return "build"
		"surrender":
			return "surrender"
	var aiming := target != null and is_instance_valid(target) and (popped or burst_left > 0) and can_fight()
	match stance:
		STAND:
			return "aim" if aiming and vel.length() < 2.5 else "stand"
		CROUCH:
			return "crouch_aim" if aiming else "crouch"
	return "prone_aim" if aiming else ("crawl" if vel.length() > 0.1 else "prone")

func _physics_process(dt: float) -> void:
	if alive and (state == "drag" or state == "heal"):
		_process_drag_heal(dt)
	if alive and state == "build" and build_site != null and is_instance_valid(build_site):
		if dist2(build_site) < build_site.radius + 2.5:
			build_site.add_work(dt * (2.0 if role == "engineer" else (0.7 if role == "medic" else 1.0)))
		else:
			_set_path(build_site.position + (position - build_site.position).normalized() * (build_site.radius + 0.8))
			state = "move"

# ------------------------------------------------------------ ragdoll sonrası
func _settle_body() -> void:
	if rag == null:
		return
	var c := rag.center()
	position = Vector3(c.x, position.y, c.z)
	rag._apply()

# ------------------------------------------------------------ yaralıyken tabanca
func _pistol() -> void:
	if pistol_cd > 0.0 or G.time - threat_time > 10.0:
		return
	pistol_cd = randf_range(0.55, 1.2)
	var best: Unit = null
	var bd := 22.0
	var eye := position + Vector3(0, 0.45, 0)
	for e in G.enemies_near(position, 22.0, team):
		if not (e is Soldier) or not e.can_fight() or not G.is_seen(e, team):
			continue
		var d := dist2(e)
		if d < bd and G.grid.los(eye, e.aim_point()):
			bd = d
			best = e
	if best == null:
		return
	pistol_t = G.time
	var mp := body.fore_r.global_transform * Vector3(0, -0.32, 0)
	var tp := best.aim_point()
	G.fx.muzzle(mp, (tp - mp).normalized(), false)
	Sfx.play3d("pistol", mp, -5.0, 0.1, 0.02)
	shots += 1
	var c := 0.2 * (1.0 - G.grid.cover_factor(best.position, best.torso_h(), position) * 0.8)
	if randf() < c:
		best.take_damage(randf_range(10.0, 18.0), self, "bullet")
	else:
		best.add_suppression(5.0, position)
		G.fx.impact(Vector3(tp.x + randf_range(-1, 1), 0.02, tp.z + randf_range(-1, 1)), "dirt")
	if shots % 2 == 0:
		G.fx.tracer(mp, tp, 220.0)

# ------------------------------------------------------------ yakın dövüş
func _think_melee() -> bool:
	if melee_cd > 0.0 or bearer or state in ["throw", "drag", "heal", "melee"]:
		return false
	for e in G.enemies_near(position, 1.8, team):
		if e is Soldier and e.can_fight() and e.hostile():
			state = "melee"
			state_t = 0.0
			melee_hit = false
			melee_target = e
			path = PackedVector3Array()
			_face_to(e.position, true)
			if randf() < 0.4:
				say("ÇEKİL!")
			return true
	return false

# ------------------------------------------------------------ teslim olma / esir
func _think_surrender() -> bool:
	if G.time < surrender_chk or bearer:
		return false
	surrender_chk = G.time + 1.0
	if suppression < 80.0 or (hp > 55.0 and ammo > 0):
		return false
	if squad:
		for m in squad.alive_members():
			if m != self and m.can_fight():
				return false
	var near_enemy := false
	for e in G.enemies_near(position, 16.0, team):
		if e is Soldier and e.can_fight() and G.is_seen(e, team):
			near_enemy = true
			break
	if not near_enemy:
		return false
	var b := nearest_base()
	if b != null and dist2(b) < 45.0:
		return false
	if randf() > 0.06:
		return false
	surrender()
	return true

func surrender() -> void:
	_release_patient()
	state = "surrender"
	state_t = 0.0
	order = ""
	target = null
	forced_target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	stance = STAND
	body.weapon.visible = false
	G.fx.impact(position + Vector3(0.5, 0.05, 0.3), "dirt")
	say(["TESLİM OLUYORUM!", "ATMA!"][randi() % 2], 3.0)
	if selected and G.player:
		G.player.deselect(self)

func _think_surrender_wait() -> void:
	var best: Soldier = null
	var bd := 9.0
	for e in G.enemies_near(position, 9.0, team):
		if e is Soldier and e.can_fight():
			var d := dist2(e)
			if d < bd:
				bd = d
				best = e
	if best != null:
		captor = best.team
		best.say("ELLER YUKARI!")
		best.add_xp(10)
		state = "prisoner"
		state_t = 0.0
		intel_t = G.time + 3.0
		var dst := _captor_base()
		if dst != null:
			_set_path(dst.position + (position - dst.position).normalized() * (dst.radius + 2.0))
		if captor == G.player_team or team == G.player_team:
			G.say(I18n.s("Esir alındı: %s") % sname, position, G.player_team)
		return
	# kurtarıldı mı (yanına dost geldi)
	if state_t > 4.0:
		for f in G.friends_near(position, 5.0, team):
			if f is Soldier and f != self and f.can_fight():
				_unsurrender()
				return
	if state_t > 60.0:
		_unsurrender()

func _unsurrender() -> void:
	state = "idle"
	captor = -1
	body.weapon.visible = true
	suppression = 30.0
	say("TEŞEKKÜRLER!")

func _captor_base() -> Building:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == captor and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	return best

func _think_prisoner() -> void:
	# esir: elleri başında düşman üssüne yürür, yolda istihbarat verir
	if captor < 0:
		_unsurrender()
		return
	var b := _captor_base()
	if b == null:
		_unsurrender()
		return
	if path_i >= path.size() or randf() < 0.05:
		_set_path(b.position + (position - b.position).normalized() * (b.radius + 1.5))
	if G.time > intel_t and intel_n < 3:
		intel_t = G.time + randf_range(7.0, 11.0)
		intel_n += 1
		_give_intel()
	if dist2(b) < b.radius + 3.5:
		G.stats["pows"][captor] += 1
		if intel_n < 3:
			_give_intel()
		vanish()
		return
	# kendi askerleri yaklaşırsa ve esir alan taraf yakında değilse kurtulur
	var friends := 0
	for f in G.friends_near(position, 4.0, team):
		if f is Soldier and f != self and f.can_fight():
			friends += 1
	if friends > 0:
		var guards := false
		for e in G.enemies_near(position, 10.0, team):
			if e is Soldier and e.can_fight():
				guards = true
				break
		if not guards:
			_unsurrender()

func _give_intel() -> void:
	if captor != G.player_team or G.spectate:
		return
	var facts: Array = []
	var bases: Array = []
	var veh := {}
	for u in G.units:
		if not is_instance_valid(u) or not u.alive or u.team != team:
			continue
		if u is Building and u.done:
			bases.append(u)
		elif u is Vehicle and not (u.vtype in ["truck", "fpv"]):
			veh[u.vtype] = int(veh.get(u.vtype, 0)) + 1
	if not bases.is_empty():
		var bb: Building = bases[randi() % bases.size()]
		facts.append([I18n.s("%s orada, %s yönünde.") % [I18n.s(bb.title), I18n.s(_dir_name(bb.position - position))], bb.position, true])
	if not veh.is_empty():
		var parts: Array = []
		for k in veh:
			parts.append("%d %s" % [veh[k], I18n.s(Vehicle.DEF[k]["title"])])
		facts.append([I18n.s("Elimizde %s var.") % ", ".join(parts), Vector3.ZERO, false])
	for a in G.ais:
		if is_instance_valid(a) and a.team == team and a.target_pos != Vector3.INF:
			facts.append([I18n.s("Bir saldırı hazırlanıyor, hedef %s yönünde.") % I18n.s(_dir_name(a.target_pos - position)), a.target_pos, false])
	facts.append([I18n.s("İkmalimiz %d civarında.") % (int(G.supply[team] / 50.0) * 50), Vector3.ZERO, false])
	var f: Array = facts[randi() % facts.size()]
	if f[2]:
		G.reveal[captor] = G.time + 30.0
	if G.hud:
		G.hud.intel(sname, f[0], f[1])

static func _dir_name(d: Vector3) -> String:
	# ekran yönüne göre (harita ile aynı yönelim)
	var sx := d.x - d.z
	var sy := d.x + d.z
	var a := fposmod(atan2(sy, sx) + PI * 0.5, TAU)
	var names := ["kuzey", "kuzeydoğu", "doğu", "güneydoğu", "güney", "güneybatı", "batı", "kuzeybatı"]
	return names[int(round(a / (TAU / 8.0))) % 8]

func vanish() -> void:
	alive = false
	visible = false
	_release_patient()
	if selected and G.player:
		G.player.deselect(self)
	queue_free()

# ------------------------------------------------------------ yaralıyı sürükleyeni örtme
func start_escort(dragger: Soldier) -> void:
	escort_of = dragger
	state = "escort"
	state_t = 0.0
	path = PackedVector3Array()
	build_site = null
	say("ÖRTME ATEŞİ!")

func _think_escort() -> void:
	_scan()
	if escort_of == null or not is_instance_valid(escort_of) or not escort_of.alive or escort_of.state != "drag" or state_t > 18.0:
		escort_of = null
		state = "idle"
		covering_until = G.time + 3.0

func _escort_move() -> Vector3:
	if escort_of == null or not is_instance_valid(escort_of):
		return Vector3.ZERO
	var mv := escort_of.vel
	mv.y = 0
	var want_p := escort_of.position + Vector3(1.5, 0, 0)
	if mv.length() > 0.1:
		var side := Vector3(-mv.z, 0, mv.x).normalized()
		want_p = escort_of.position + side * 1.5 - mv.normalized() * 0.6
	var d := want_p - position
	d.y = 0
	var L := d.length()
	if L < 0.3:
		return Vector3.ZERO
	return d / L * minf(L * 2.0, 2.6)

# ------------------------------------------------------------ sedyeciler
var job = null

func _stretcher_move() -> Vector3:
	if job == null:
		state = "idle"
		return Vector3.ZERO
	return job.want_for(self)

func _stretcher_back() -> bool:
	return job != null and job.alone()

# ------------------------------------------------------------ mermi
func _think_ammo() -> void:
	if ammo > 0 or mag > 0 or order in ["hold", "resupply", "loot"] or role == "mortar" or bearer:
		return
	for u in G.near(position, 14.0):
		if u is Soldier and not u.alive and u.loot > 0 and not u.carried:
			order = "loot"
			_set_path(u.position)
			state = "move"
			return
	var b := nearest_base()
	if b != null and dist2(b) < 170.0:
		say("MERMİ BİTTİ!")
		var p := b.position + (position - b.position).normalized() * (b.radius + 3.0)
		cmd_move(G.grid.nearest_free(p, Grid.M_INF))
		order = "resupply"

# ------------------------------------------------------------ hastane
func enter_hospital(b: Building) -> void:
	hosp_b = b
	carried = false
	state = "hospital"
	visible = false
	target = null
	path = PackedVector3Array()
	position = b.position
	rescuer = null

func leave_hospital(door: Vector3) -> void:
	if not alive:
		resurrect()
	state = "idle"
	visible = true
	position = G.grid.nearest_free(door, Grid.M_INF)
	max_hp = maxf(40.0, 100.0 - 25.0 * downs)
	hp = max_hp * 0.8
	bleed = 0.0
	suppression = 0.0
	stance = STAND
	limp_t = 16.0
	body.dead_pose = {}
	body.weapon.visible = true
	hosp_b = null
	var b := nearest_base()
	if b != null:
		cmd_move(G.grid.nearest_free(b.position + Vector3(randf_range(-4, 4), 0, b.radius + 3.0), Grid.M_INF))
	say("İYİYİM!" if randf() < 0.5 else "TEŞEKKÜRLER!")

func resurrect() -> void:
	alive = true
	if rag != null:
		body.reset_rig()
	rag = null
	carried = false
	downs = mini(downs + 1, 2)
	loot = 0
	set_process(true)
	if G.main:
		G.main.bodies.erase(self)
	G.stats["lost"][team] = maxi(0, G.stats["lost"][team] - 1)
	var W := weapon()
	ammo = W["ammo"]
	mag = W["mag"]
