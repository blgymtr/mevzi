extends Node
# Küresel oyun durumu, birim kayıtları ve ortak savaş yardımcıları (autoload "G").

signal alert(text: String, pos: Vector3, team: int)

const MAP := 256.0
const TEAM_COL := [Color(0.32, 0.66, 1.0), Color(1.0, 0.3, 0.22)]
const TEAM_NAME := ["MAVİ KUVVET", "KIZIL CEPHE"]
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
var cam: CamRig
var ais: Array = []

var units: Array = []
var squads: Array = []
var time := 0.0
var running := false
var speed := 1.0
var map_kind := "desert"
var player_team := 0
var spectate := false
var difficulty := 1
var supply := [600.0, 600.0]
var cap_max := [0, 0]
var cap_used := [0, 0]
var game_over := false
var winner := -1
var rng := RandomNumberGenerator.new()
var smokes: Array = []      # [Vector3 merkez, yarıçap, bitiş zamanı]
var stats := {"kills": [0, 0], "lost": [0, 0], "built": [0, 0]}
var fob_sites: Array = []   # harita üzerindeki ileri üs noktaları
var hq_pos := [Vector3.ZERO, Vector3.ZERO]

var _hash := {}
var _vis_t := 0.0

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	rng.randomize()
	RenderingServer.global_shader_parameter_add("game_time", RenderingServer.GLOBAL_VAR_TYPE_FLOAT, 0.0)

func reset() -> void:
	units.clear()
	squads.clear()
	smokes.clear()
	ais.clear()
	time = 0.0
	supply = [600.0, 600.0]
	cap_max = [0, 0]
	cap_used = [0, 0]
	game_over = false
	winner = -1
	stats = {"kills": [0, 0], "lost": [0, 0], "built": [0, 0]}
	fob_sites.clear()
	_hash.clear()

func step(dt: float) -> void:
	time += dt
	RenderingServer.global_shader_parameter_set("game_time", time)
	_rebuild_hash()
	var i := smokes.size() - 1
	while i >= 0:
		if smokes[i][2] < time:
			smokes.remove_at(i)
		i -= 1
	_vis_t -= dt
	if _vis_t <= 0.0:
		_vis_t = 0.25
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
		if u.team != team and u.team >= 0 and (not need_alive or u.alive):
			out.append(u)
	return out

func friends_near(p: Vector3, r: float, team: int) -> Array:
	var out: Array = []
	for u in near(p, r):
		if u.team == team and u.alive:
			out.append(u)
	return out

# ------------------------------------------------------------ görüş (sis)
func _update_visibility() -> void:
	for u in units:
		if not is_instance_valid(u):
			continue
		for t in 2:
			if u.team == t or u.team < 0:
				u.seen[t] = true
				continue
			var s := false
			for f in near(u.position, 85.0):
				if f.team == t and f.alive and f.position.distance_to(u.position) <= f.sight:
					s = true
					break
			u.seen[t] = s
		u.apply_visibility()

func is_seen(u, by_team: int) -> bool:
	if by_team < 0:
		return true
	return u.seen[by_team]

func view_team() -> int:
	return -1 if spectate else player_team

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
func explode(p: Vector3, radius: float, dmg: float, kind: String, team: int, src = null) -> void:
	var size := clampf(radius / 3.0, 0.5, 3.0)
	fx.explosion(p, size, kind)
	Sfx.play3d("expl_big" if size >= 1.6 else ("expl_med" if size >= 1.0 else "expl_small"), p, 4.0 if size >= 1.6 else 1.0)
	if p.y < 1.5:
		fx.crater(p, radius * 1.15)
		terrain.paint_circle(p, radius * 0.9, 2, 0.75)
	blocks.blast(p, radius * (0.55 if kind == "grenade" else 0.75), size)
	props.blast(p, radius, dmg)
	cam.shake(size * 0.35, p)
	for u in near(p, radius * 2.2):
		if not u.alive and not (u is Soldier):
			continue
		var d: float = u.position.distance_to(p)
		if u is Soldier:
			u.on_blast(p, radius, dmg, d, src)
		else:
			var r_eff: float = radius + u.radius
			if d < r_eff:
				var f := 1.0 - clampf((d - u.radius) / radius, 0.0, 1.0) * 0.7
				u.take_damage(dmg * f, src, kind)
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

func check_victory() -> void:
	if game_over or not running:
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
