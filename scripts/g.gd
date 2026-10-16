extends Node
# Küresel oyun durumu, birim kayıtları ve ortak savaş yardımcıları (autoload "G").

signal alert(text: String, pos: Vector3, team: int)

var MAP := 256.0          # harita kenarı (m); haritaya göre değişir
const TEAM_COL := [Color(0.32, 0.66, 1.0), Color(1.0, 0.3, 0.22)]
const TEAM_NAME := ["MÜTTEFİKLER", "MİHVER"]
# uluslar (ileride: Alman, Rus, ABD, İngiliz, Türk); şimdilik ABD (Müttefik) - Rusya (Mihver)
const NATIONS := {"usa": "ABD", "rus": "Rusya", "ger": "Almanya", "gbr": "Birleşik Krallık", "tur": "Türkiye"}
var nation := ["usa", "rus"]
const HC := 8.0

var main: Node3D
var world: Node3D
var terrain: Terrain
var grid: Grid
var blocks: Blocks
var props: Props
var fx: Fx
var bal: Ballistics
var hud: Hud
var player: PlayerCtl
var logi: Logistics
var mode := "bases"        # bases | conquest | wargoals
var modes: Modes = null
var weather: Weather = null
var weather_pref := "dynamic"
var night_pref := false
var deploy_t := 0.0        # konuşlanma aşaması (sn): ateş yok, üretim hızlı
const DEPLOY_TIME := 45.0
var cam: CamRig
var ais: Array = []

var units: Array = []
var squads: Array = []
var time := 0.0
var running := false
var speed := 1.0
var map_kind := "desert"
var map_id := "desert_canal"
var biome: Dictionary = {}
var mapgen: MapGen
var editor := false
var scenario: Dictionary = {}     # boşsa normal çatışma
var zone_t := [0.0, 0.0]
var player_team := 0
var sandbox := false       # sınırsız ikmal / birlik sınırı yok / geliştirici komutları
var fog_off := false
var spectate := false
var difficulty := 1
var supply := [600.0, 600.0]
var cap_max := [0, 0]
var cap_used := [0, 0]
var game_over := false
var vis_freeze := false       # ölçüm (perf8k): tespit güncellemesi kapalı
var winner := -1
var rng := RandomNumberGenerator.new()
var smokes: Array = []      # [Vector3 merkez, yarıçap, bitiş zamanı]
var stats := {"kills": [0, 0], "lost": [0, 0], "built": [0, 0], "pows": [0, 0]}
var reveal := [0.0, 0.0]      # istihbarat: bu zamana kadar düşman yapıları görünür
var fob_sites: Array = []   # harita üzerindeki ileri üs noktaları
var zone_sites: Array = []  # haritada tanımlı hedef bölgeleri ({p, name}); boşsa Modes kendisi yerleştirir
var grass_stream := false   # büyük harita: ot yalnız kameranın çevresinde üretilir
var hq_pos := [Vector3.ZERO, Vector3.ZERO]

var _hash := {}
var _vis_t := 0.0

# yükleme ölçümü (mapprof testi): aşama süresi ve bellek
var prof_on := false
var _prof_t := 0
func prof(label: String) -> void:
	if main != null and main.has_method("load_step"):
		main.load_step(label)
	if not prof_on:
		return
	var now := Time.get_ticks_msec()
	print("PROF %-16s +%6d ms  static=%5d MB  vram=%5d MB" % [label, now - _prof_t, OS.get_static_memory_usage() / 1048576, int(Performance.get_monitor(Performance.RENDER_VIDEO_MEM_USED)) / 1048576])
	_prof_t = now

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	RenderingServer.global_shader_parameter_add("game_time", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	# görsel savaş sisi (FogOfWar dokuları atanana kadar kapalı)
	RenderingServer.global_shader_parameter_add("fow_on", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)
	RenderingServer.global_shader_parameter_add("fow_vis", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, null)
	RenderingServer.global_shader_parameter_add("fow_exp", RenderingServer.GLOBAL_VAR_TYPE_SAMPLER2D, null)
	# ağaç/çalı şok dalgası için son 4 büyük patlama: (x, z, başlangıç, güç)
	for i in 4:
		RenderingServer.global_shader_parameter_add("blast%d" % i, RenderingServer.GLOBAL_VAR_TYPE_VEC4, Vector4(0, 0, -100, 0))
	# rotor rüzgârı (roadmap 22): alçaktaki 4 helikopter (x, z, güç 0..1, yarıçap m) — ağaç ve ot savrulur
	for i in 4:
		RenderingServer.global_shader_parameter_add("rotor%d" % i, RenderingServer.GLOBAL_VAR_TYPE_VEC4, Vector4(0, 0, 0, 1))

var _rotor_t := 0.0
var rotor_wash: Array = [Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1), Vector4(0, 0, 0, 1)]
# kameraya en yakın, alçakta uçan / inen 4 helikopterin rotor rüzgârı
func _update_rotor_wash() -> void:
	var cands: Array = []
	var cp: Vector3 = cam.position if cam != null else Vector3.ZERO
	for u in units:
		if not is_instance_valid(u) or not u.alive or not (u is Vehicle) or not (u.vtype in ["heli", "transport"]):
			continue
		var alt: float = u.hull.position.y
		var k: float = u.rotor_rpm * clampf(1.0 - alt / 26.0, 0.0, 1.0)
		if k <= 0.02:
			continue
		cands.append([Vector2(u.position.x - cp.x, u.position.z - cp.z).length(), u, k, alt])
	cands.sort_custom(func(a, b): return a[0] < b[0])
	for i in 4:
		if i < cands.size():
			var u: Vehicle = cands[i][1]
			var rr: float = u.ext.y * 2.2 + cands[i][3] * 0.6
			rotor_wash[i] = Vector4(u.position.x, u.position.z, cands[i][2], rr)
		else:
			rotor_wash[i] = Vector4(0, 0, 0, 1)
		RenderingServer.global_shader_parameter_set("rotor%d" % i, rotor_wash[i])

var _blast_i := 0
func push_blast(p: Vector3, power: float) -> void:
	RenderingServer.global_shader_parameter_set("blast%d" % _blast_i, Vector4(p.x, p.z, time, power))
	_blast_i = (_blast_i + 1) % 4

func reset() -> void:
	units.clear()
	squads.clear()
	smokes.clear()
	ais.clear()
	time = 0.0
	for i in 4:
		RenderingServer.global_shader_parameter_set("blast%d" % i, Vector4(0, 0, -100, 0))
	supply = [600.0, 600.0]
	cap_max = [0, 0]
	cap_used = [0, 0]
	game_over = false
	winner = -1
	deploy_t = 0.0
	stats = {"kills": [0, 0], "lost": [0, 0], "built": [0, 0], "pows": [0, 0]}
	reveal = [0.0, 0.0]
	zone_t = [0.0, 0.0]
	fob_sites.clear()
	zone_sites.clear()
	grass_stream = false
	_hash.clear()
	Squad._count = [0, 0]

func step(dt: float) -> void:
	time += dt
	if deploy_t > 0.0:
		deploy_t -= dt
		if deploy_t <= 0.0:
			deploy_t = 0.0
			say(I18n.s("KONUŞLANMA BİTTİ — ÇATIŞMA BAŞLADI"), hq_pos[player_team], player_team)
			Sfx.play2d("ui_alert", -2.0)
	RenderingServer.global_shader_parameter_set("game_time", time)
	_rebuild_hash()
	var i := smokes.size() - 1
	while i >= 0:
		if smokes[i][2] < time:
			smokes.remove_at(i)
		i -= 1
	_rotor_t -= dt
	if _rotor_t <= 0.0:
		_rotor_t = 0.1
		_update_rotor_wash()
	_vis_t -= dt
	if _vis_t <= 0.0:
		_vis_t = 0.25
		if not vis_freeze:
			_update_visibility()
		_update_cap()

# ------------------------------------------------------------ uzamsal karma
func _rebuild_hash() -> void:
	_hash.clear()
	for u in units:
		if not is_instance_valid(u):
			continue
		var k := Vector2i(int(u.position.x / HC), int(u.position.z / HC))
		if _hash.has(k):
			_hash[k].append(u)
		else:
			_hash[k] = [u]

func near(p: Vector3, r: float) -> Array:
	var out: Array = []
	var x0 := int((p.x - r) / HC)
	var x1 := int((p.x + r) / HC)
	var z0 := int((p.z - r) / HC)
	var z1 := int((p.z + r) / HC)
	var r2 := r * r
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var k := Vector2i(x, z)
			if not _hash.has(k):
				continue
			for u in _hash[k]:
				if not is_instance_valid(u):
					continue
				var dx: float = u.position.x - p.x
				var dz: float = u.position.z - p.z
				if dx * dx + dz * dz <= r2:
					out.append(u)
	return out

func enemies_near(p: Vector3, r: float, team: int, need_alive := true) -> Array:
	var out: Array = []
	for u in near(p, r):
		if u.team != team and u.team >= 0 and (not need_alive or u.hostile()):
			out.append(u)
	return out

func friends_near(p: Vector3, r: float, team: int) -> Array:
	var out: Array = []
	for u in near(p, r):
		if u.team == team and u.alive:
			out.append(u)
	return out

# ------------------------------------------------------------ görüş / tespit (roadmap 50)
# Takım görüşü: düşman, takımdan bir gözcünün tespit menzili içinde ve görüş hattındaysa görülür.
# Tespit menzili = det_base × gözcü optiği (çıplak göz 1, dürbün 1,3, gündüz nişangâhı 1,4, termal 2-2,4,
# İHA 2,6) × hedef izi (boyut, duruş, hareket, ateş, bina/siper/bitki örtüsü) × hava/gece (termal az
# etkilenir). Hava hedefini radar uzaktan görür. Hedefler dört dilimde sırayla değerlendirilir (her biri
# ~1 sn); son gören gözcü önce denenir; görülen 2 sn hafızada kalır (titreme olmaz).
var _vis_list := [[], []]
var _spot_slice := 0

func visible_enemies(t: int) -> Array:
	return _vis_list[t] if t >= 0 and t < 2 else []

func _update_visibility() -> void:
	var obs := [[], []]
	for u in units:
		if not is_instance_valid(u) or not u.alive or u.team < 0 or u.team > 1:
			continue
		if u is Soldier and (u.state in ["aboard", "hospital", "prisoner", "surrender"] or u.incapacitated()):
			continue
		obs[u.team].append(u)
	var wm: float = weather.sight_mult() if weather != null and is_instance_valid(weather) else 1.0
	var night: bool = weather != null and is_instance_valid(weather) and weather.night
	_spot_slice = (_spot_slice + 1) % 4
	var i := 0
	for u in units:
		i += 1
		if not is_instance_valid(u):
			continue
		for t in 2:
			if u.team == t or u.team < 0:
				u.seen[t] = true
				continue
			if (i & 3) != _spot_slice:
				if u.seen[t] and u.spot_mem[t] <= time and not (u is Building and time < reveal[t]):
					u.seen[t] = false
				continue
			var s: bool = u is Building and time < reveal[t]
			if not s and u.alive:
				s = _spotted(u, obs[t], t, wm, night)
			if s:
				u.spot_mem[t] = time + 2.0
			u.seen[t] = s or u.spot_mem[t] > time
		u.apply_visibility()
	_vis_list = [[], []]
	for u in units:
		if is_instance_valid(u) and u.alive and u.team >= 0 and u.team < 2:
			var e: int = 1 - u.team
			if u.seen[e]:
				_vis_list[e].append(u)

func _spotted(u, observers: Array, t: int, wm: float, night: bool) -> bool:
	var sig: float = u.spot_sig()
	if sig <= 0.0:
		return false
	var tp: Vector3 = u.aim_point()
	var air: bool = u is Vehicle and u.is_air()
	var last = u.spot_by[t]
	if last != null and is_instance_valid(last) and last.alive and _obs_sees(last, u, tp, sig, air, wm, night):
		return true
	for o in observers:
		if o == last:
			continue
		if _obs_sees(o, u, tp, sig, air, wm, night):
			u.spot_by[t] = o
			return true
	return false

func _obs_sees(o, u, tp: Vector3, sig: float, air: bool, wm: float, night: bool) -> bool:
	var th: bool = o.thermal()
	var w := wm if not th else lerpf(wm, 1.0, 0.7)
	if night and not th:
		w *= 0.45
	var R: float = Combat.detect_range(o.opt_k, sig) * w
	if air and o is Vehicle and o.radar > 0.0:
		R = maxf(R, o.radar)
	var dx: float = tp.x - o.position.x
	var dz: float = tp.z - o.position.z
	if dx * dx + dz * dz > R * R:
		return false
	# hava hedefi ya da havadaki gözcü: görüş hattı yukarıdan açık say (orman örtüsü izde)
	if air or (o is Vehicle and o.is_air()):
		return true
	return grid.los(o.eye_point(), tp, o.los_skip(), 1.6 if (u is Soldier and u.house_id >= 0) else 0.4)

func is_seen(u, by_team: int) -> bool:
	if by_team < 0:
		return true
	return u.seen[by_team]

func view_team() -> int:
	return -1 if (spectate or fog_off) else player_team

func _update_cap() -> void:
	cap_used = [0, 0]
	cap_max = [0, 0]
	for u in units:
		if not is_instance_valid(u) or not u.alive or u.team < 0:
			continue
		if u is Building:
			if u.done:
				cap_max[u.team] += u.cap_bonus
		else:
			cap_used[u.team] += u.cap_cost
	if sandbox:
		cap_max = [999, 999]

# ------------------------------------------------------------ kayıt
func add_unit(u) -> void:
	units.append(u)

func remove_unit(u) -> void:
	units.erase(u)

func say(text: String, pos: Vector3, team: int) -> void:
	alert.emit(text, pos, team)

func on_ground(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, 2.0, MAP - 2.0), 0.0, clampf(p.z, 2.0, MAP - 2.0))

# ------------------------------------------------------------ patlama hasarı
# kind: "grenade", "rpg", "shell", "big", "mine", "auto"
# spare: bu takımın askerleri hasar almaz (yalnız bastırılır) — kendi aracının patlaması/helikopterinin
# düşüşü kendi askerine zarar vermez (roadmap 27). Bina patlaması ve silah patlamaları herkese işler.
func explode(p: Vector3, radius: float, dmg: float, kind: String, team: int, src = null, spare := -1) -> void:
	var size := clampf(radius / 3.0, 0.5, 3.0)
	if p.y < 1.0 and grid.is_water(p):
		fx.water_splash(p, size)
		Sfx.play3d("expl_small", p, -2.0)
		for u in near(p, radius * 1.5):
			if u is Soldier and u.alive:
				u.add_suppression(20.0, p)
		return
	fx.explosion(p, size, kind)
	if kind in ["grenade", "mortar", "rpg"]:
		fx.surface_burst(Vector3(p.x, 0.1, p.z), size)
	Sfx.play3d("expl_big" if size >= 1.6 else ("expl_med" if size >= 1.0 else "expl_small"), p, 4.0 if size >= 1.6 else 1.0)
	if p.y < 1.5:
		fx.crater(p, radius * 1.15)
		# gerçek çukur: top/havan/büyük patlama araziyi oyar (askerler içine girip siper alır)
		if kind in ["shell", "big", "mine", "rpg"] and radius >= 3.0 and not grid.is_water(p) and grid.height_at(p) < 0.3:
			var cr := radius * (0.45 if kind != "big" else 0.6)
			terrain.carve_crater(p, cr, cr * 0.42)
			grid.set_crater(p, cr * 0.8)
		terrain.paint_circle(p, radius * 0.9, 2, 0.75)
	blocks.blast(p, radius * (0.55 if kind == "grenade" else 0.75), size)
	props.blast(p, radius, dmg)
	cam.shake(size * 0.35, p)
	for u in near(p, radius * 2.2):
		if not u.alive and not (u is Soldier):
			continue
		var d: float = u.position.distance_to(p)
		if u is Soldier:
			if spare >= 0 and u.team == spare:
				continue
			u.on_blast(p, radius, dmg, d, src)
		else:
			var r_eff: float = radius + u.radius
			if d < r_eff:
				var f := 1.0 - clampf((d - u.radius) / radius, 0.0, 1.0) * 0.7
				if u is Vehicle:
					Vehicle.shot_from = p
				u.take_damage(dmg * f, src, kind)
	for st in DroneStation.all:
		if is_instance_valid(st) and st.alive and st.position.distance_to(p) < radius * 1.3:
			st.take_blast(dmg * (1.0 - clampf(st.position.distance_to(p) / (radius * 1.3), 0.0, 0.8)))
	for s in near(p, radius * 4.0):
		if s is Soldier and s.alive:
			s.add_suppression(30.0 * size * (1.0 - clampf(s.position.distance_to(p) / (radius * 4.0), 0.0, 1.0)), p)

func add_smoke(p: Vector3, r: float, dur: float) -> void:
	smokes.append([p, r, time + dur])

func credit_kill(src, victim) -> void:
	if victim.team >= 0:
		stats["lost"][victim.team] += 1
	if src != null and is_instance_valid(src) and src.team >= 0 and src.team != victim.team:
		stats["kills"][src.team] += 1
		if modes != null and is_instance_valid(modes):
			modes.add_destruction(src.team, unit_value(victim) * 0.1)
		if src is Soldier:
			src.add_xp(20 if victim is Vehicle else (30 if victim is Building else 6))
			if src.squad:
				for m in src.squad.alive_members():
					if m != src:
						m.add_xp(1)

# birim değeri (imha puanı / iade için)
func unit_value(u) -> float:
	if u is Vehicle:
		if u.vid != "":
			return float(u.cat.get("cost", 100))
		return float(Building.PDEF.get(u.vtype, {}).get("cost", 100))
	if u is Building:
		return float(Building.BDEF.get(u.btype, {}).get("cost", 100))
	if u is Soldier:
		return u.cost_share if u.cost_share > 0.0 else 30.0
	return 0.0

func _end(w: int) -> void:
	game_over = true
	winner = w
	if hud:
		hud.show_game_over(winner)

func scenario_step(dt: float) -> void:
	if scenario.is_empty() or game_over:
		return
	var win := String(scenario.get("win", "bases"))
	match win:
		"survive":
			if time >= float(scenario.get("time", 600)):
				_end(player_team)
		"hold":
			var z := MapGen.v3(scenario.get("zone", [128, 128]))
			var cnt := [0, 0]
			for u in near(z, 14.0):
				if u.alive and u.team >= 0 and (u is Soldier and u.can_fight() or u is Vehicle and not u.is_air()):
					cnt[u.team] += 1
			for t in 2:
				if cnt[t] > 0 and cnt[1 - t] == 0:
					zone_t[t] += dt
					if zone_t[t] >= float(scenario.get("time", 120)):
						_end(t)
						return
		"annihilate":
			for t in 2:
				var any := false
				for u in units:
					if is_instance_valid(u) and u.alive and u.team == t and (u is Soldier and not u.incapacitated() or u is Vehicle and u.vtype != "truck"):
						any = true
						break
				if not any:
					_end(1 - t)
					return

func check_victory() -> void:
	if game_over or not running:
		return
	if modes != null and is_instance_valid(modes):
		return
	if not scenario.is_empty():
		var win := String(scenario.get("win", "bases"))
		if win != "bases":
			# her iki tarafın da üssü yoksa üs kontrolünü atla
			return
	for t in 2:
		var has := false
		for u in units:
			if is_instance_valid(u) and u.alive and u.team == t and u is Building and u.is_base() and u.done:
				has = true
				break
		if not has:
			game_over = true
			winner = 1 - t
			if hud:
				hud.show_game_over(winner)
			return
