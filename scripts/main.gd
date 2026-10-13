extends Node3D
# Ana sahne: ortam/ışık, oyun kurulumu, menü (arka planda yapay zekâ savaşı), test kancaları.

var env: Environment
var sun: DirectionalLight3D
var we: WorldEnvironment
var world: Node3D
var bodies: Array = []
var shot_dir := ""
var shot_scene := ""
var autoplay := 0.0
var ambience: AudioStreamPlayer
var ambience2: AudioStreamPlayer
var cfg := {"volume": 0.8, "difficulty": 1}

func _ready() -> void:
	G.main = self
	process_mode = Node.PROCESS_MODE_ALWAYS
	_load_cfg()
	_setup_env()
	var cam := CamRig.new()
	add_child(cam)
	cam.light = sun
	G.cam = cam
	var hud := Hud.new()
	add_child(hud)
	G.hud = hud
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--shot="):
			shot_dir = a.substr(7)
		elif a.begins_with("--scene="):
			shot_scene = a.substr(8)
		elif a.begins_with("--autoplay="):
			autoplay = float(a.substr(11))
	if shot_dir != "":
		_run_shots()
	elif autoplay > 0.0:
		_run_autoplay()
	else:
		to_menu()

# ------------------------------------------------------------ ortam
func _setup_env() -> void:
	we = WorldEnvironment.new()
	env = Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.85, 0.66, 0.42)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	env.tonemap_exposure = 1.0
	env.tonemap_white = 6.0
	env.ssao_enabled = true
	env.ssao_radius = 1.2
	env.ssao_intensity = 1.6
	env.ssao_power = 1.4
	env.glow_enabled = true
	env.glow_intensity = 0.75
	env.glow_strength = 1.0
	env.glow_bloom = 0.06
	env.glow_hdr_threshold = 0.95
	env.glow_blend_mode = Environment.GLOW_BLEND_MODE_SOFTLIGHT
	env.set_glow_level(1, 0.0)
	env.set_glow_level(2, 0.6)
	env.set_glow_level(3, 1.0)
	env.set_glow_level(4, 0.8)
	env.set_glow_level(5, 0.4)
	env.adjustment_enabled = true
	env.adjustment_contrast = 1.08
	env.adjustment_saturation = 1.05
	we.environment = env
	add_child(we)
	sun = DirectionalLight3D.new()
	sun.shadow_enabled = true
	sun.directional_shadow_mode = DirectionalLight3D.SHADOW_ORTHOGONAL
	sun.shadow_blur = 1.4
	sun.shadow_bias = 0.04
	sun.shadow_normal_bias = 1.2
	sun.directional_shadow_max_distance = 200.0
	add_child(sun)
	_apply_theme("desert")

func _apply_theme(kind: String) -> void:
	# güneş: gölgeler ekranda sol-aşağıya, uzun
	var elev := deg_to_rad(30.0)
	var dir := Vector3(-0.25, 0, 1).normalized() * cos(elev) + Vector3(0, -sin(elev), 0)
	sun.look_at_from_position(Vector3.ZERO, dir, Vector3.UP)
	if kind == "winter":
		sun.light_color = Color(1.0, 0.94, 0.86)
		sun.light_energy = 1.9
		env.ambient_light_color = Color(0.62, 0.68, 0.8)
		env.ambient_light_energy = 0.75
		env.background_color = Color(0.9, 0.92, 0.95)
		env.adjustment_saturation = 1.05
		env.tonemap_exposure = 0.92
	else:
		sun.light_color = Color(1.0, 0.85, 0.66)
		sun.light_energy = 2.5
		env.ambient_light_color = Color(0.78, 0.66, 0.52)
		env.ambient_light_energy = 0.62
		env.background_color = Color(0.85, 0.66, 0.42)
		env.adjustment_saturation = 1.04
		env.tonemap_exposure = 1.0

# ------------------------------------------------------------ kurulum
func _clear_world() -> void:
	get_tree().paused = false
	Engine.time_scale = 1.0
	G.running = false
	if world:
		world.queue_free()
		world = null
	for a in G.ais:
		if is_instance_valid(a):
			a.queue_free()
	if G.player and is_instance_valid(G.player):
		G.player.queue_free()
	if G.logi and is_instance_valid(G.logi):
		G.logi.queue_free()
	G.reset()
	bodies.clear()

func build_world(kind: String, seed_v: int) -> void:
	_clear_world()
	G.map_kind = kind
	_apply_theme(kind)
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	G.world = world
	G.grid = Grid.new()
	var t := Terrain.new()
	world.add_child(t)
	G.terrain = t
	t.build(kind)
	var fx := Fx.new()
	fx.winter = kind == "winter"
	world.add_child(fx)
	G.fx = fx
	var bl := Blocks.new()
	world.add_child(bl)
	G.blocks = bl
	var pr := Props.new()
	world.add_child(pr)
	G.props = pr
	var bal := Ballistics.new()
	world.add_child(bal)
	G.bal = bal
	var ground := StaticBody3D.new()
	ground.collision_layer = 1
	var gs := CollisionShape3D.new()
	gs.shape = WorldBoundaryShape3D.new()
	ground.add_child(gs)
	world.add_child(ground)
	var mg := MapGen.new()
	mg.build(kind, seed_v)
	var lg := Logistics.new()
	add_child(lg)
	G.logi = lg
	var pc := PlayerCtl.new()
	add_child(pc)
	G.player = pc
	pc.team = G.player_team
	_start_forces()
	G.running = true
	if ambience:
		ambience.queue_free()
	if ambience2:
		ambience2.queue_free()
	ambience = Sfx.ambience("wind", -14.0)
	ambience2 = Sfx.ambience("battle_far", -20.0)

func _start_forces() -> void:
	for t in 2:
		var hp: Vector3 = G.hq_pos[t]
		var rot := PI * 0.75 if t == 0 else -PI * 0.25
		var hq := place_building(t, "hq", hp, 0.0)
		hq.complete()
		var toward: Vector3 = (G.hq_pos[1 - t] - hp).normalized()
		var side := Vector3(-toward.z, 0, toward.x)
		var base := hp + toward * 16.0
		for k in 3:
			var sq := Squad.new(t, "Tim %d" % (k + 1))
			G.squads.append(sq)
			var roles: Array = ["rifle", "rifle", "rifle", "mg", "rifle", "rifle"] if k < 2 else ["at", "at", "rifle", "medic"]
			var c := base + side * (k - 1) * 7.0
			for i in roles.size():
				var p := G.grid.nearest_free(c + Vector3((i % 3 - 1) * 1.6, 0, (i / 3) * 1.6), Grid.M_INF)
				var s := spawn_soldier(t, roles[i], p, sq)
				s.rotation.y = Soldier._yaw_of(toward)
				s.face_yaw = s.rotation.y
		spawn_vehicle(t, "tank", G.grid.nearest_free(base - toward * 6.0 + side * 6.0, Grid.M_HEAVY), Soldier._yaw_of(toward))
		spawn_vehicle(t, "technical", G.grid.nearest_free(base - toward * 6.0 - side * 6.0, Grid.M_LIGHT), Soldier._yaw_of(toward))
		G.supply[t] = 650.0
		var _r := rot

func spawn_soldier(t: int, role: String, p: Vector3, sq: Squad, hp_v := 100.0) -> Soldier:
	var s := Soldier.new()
	s.position = G.on_ground(p)
	world.add_child(s)
	s.setup(t, role)
	s.hp = hp_v
	if sq == null:
		sq = Squad.new(t, "Mürettebat")
		G.squads.append(sq)
	sq.add(s)
	return s

func spawn_vehicle(t: int, vt: String, p: Vector3, yaw: float) -> Vehicle:
	var v := Vehicle.new()
	v.position = G.on_ground(p)
	v.rotation.y = yaw
	world.add_child(v)
	v.setup(t, vt)
	return v

func place_building(t: int, bt: String, p: Vector3, rot: float) -> Building:
	var b := Building.new()
	b.position = G.on_ground(p)
	world.add_child(b)
	b.setup(t, bt, rot)
	b.occupy_grid()
	return b

func place_line(t: int, bt: String, a: Vector3, b2: Vector3) -> Building:
	var b := Building.new()
	world.add_child(b)
	b.setup_line(t, bt, a, b2)
	return b

func register_body(s: Soldier) -> void:
	bodies.append(s)
	while bodies.size() > 160:
		var o = bodies.pop_front()
		if is_instance_valid(o):
			o.queue_free()

# ------------------------------------------------------------ akış
func to_menu() -> void:
	G.spectate = true
	build_world("desert" if randf() < 0.6 else "winter", randi())
	_spectate_ai()
	G.cam.auto_pan = true
	G.cam.input_enabled = false
	G.cam.jump_to(Vector3(128, 0, 128), true)
	G.cam.target_size = 60.0
	G.hud.show_menu()

func _spectate_ai() -> void:
	for t in 2:
		var a := AICmd.new(t)
		add_child(a)
		G.ais.append(a)
		a.wave_t = 40.0
	G.supply = [1400.0, 1400.0]

func restart_spectate() -> void:
	call_deferred("to_menu")

func start_game(kind: String) -> void:
	G.hud.hide_menu()
	G.spectate = false
	G.player_team = 0
	build_world(kind, randi())
	var a := AICmd.new(1)
	add_child(a)
	G.ais.append(a)
	G.cam.auto_pan = false
	G.cam.input_enabled = true
	G.cam.jump_to(G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 18.0, true)
	G.cam.target_size = 40.0
	G.say("Karargâh kuruldu. İleri üs kurarak ilerleyin.", G.hq_pos[0], 0)

func _process(dt: float) -> void:
	if not G.running or get_tree().paused:
		return
	G.step(dt)
	G.grid.flush_nav()
	for sq in G.squads:
		sq.update(dt)
	if fmod(G.time, 5.0) < dt:
		G.squads = G.squads.filter(func(s): return not s.alive_members().is_empty())
	if not G.spectate:
		G.check_victory()

# ------------------------------------------------------------ ayarlar
func _load_cfg() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			cfg.merge(d, true)
	Sfx.set_volume(float(cfg["volume"]))
	G.difficulty = int(cfg["difficulty"])

func save_cfg() -> void:
	cfg["volume"] = Sfx.volume
	cfg["difficulty"] = G.difficulty
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))

# ------------------------------------------------------------ testler
func _shot(n: String) -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	DirAccess.make_dir_recursive_absolute(shot_dir)
	img.save_png(shot_dir.path_join(n + ".png"))
	print("SHOT ", n)

func _wait(sec: float) -> void:
	var t := 0.0
	while t < sec:
		await get_tree().process_frame
		t += get_process_delta_time()

func _run_shots() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var kind := "winter" if shot_scene.begins_with("winter") else "desert"
	G.spectate = true
	build_world(kind, 12345)
	_spectate_ai()
	G.cam.input_enabled = false
	G.cam.jump_to(Vector3(128, 0, 128), true)
	G.cam.size = 40.0
	G.cam.target_size = 40.0
	await _wait(2.0)
	await _shot(kind + "_00_town")
	# karşılaşma kur: iki grup merkezde
	_skirmish(Vector3(128, 0, 128))
	G.cam.jump_to(Vector3(128, 0, 128), true)
	for i in 6:
		await _wait(4.0)
		await _shot("%s_%02d_battle" % [kind, i + 1])
	G.cam.target_size = 100.0
	G.cam.size = 100.0
	await _wait(1.0)
	await _shot(kind + "_07_wide")
	G.spectate = false
	G.hud.show_menu()
	G.cam.jump_to(G.hq_pos[0], true)
	G.cam.size = 52.0
	await _wait(1.0)
	await _shot(kind + "_08_menu")
	G.hud.hide_menu()
	G.player.select(G.units[0])
	await _wait(0.5)
	await _shot(kind + "_09_hud")
	print("SHOTS DONE units=%d fps=%d" % [G.units.size(), Engine.get_frames_per_second()])
	get_tree().quit()

func _skirmish(c: Vector3) -> void:
	for t in 2:
		var off := Vector3(-1, 0, -1).normalized() * (22.0 if t == 1 else -22.0)
		var toward := -off.normalized()
		for k in 3:
			var sq := Squad.new(t, "T")
			G.squads.append(sq)
			var side := Vector3(-toward.z, 0, toward.x)
			for i in 6:
				var p := G.grid.nearest_free(c + off + side * (k - 1) * 8.0 + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), Grid.M_INF)
				var s := spawn_soldier(t, ["rifle", "rifle", "mg", "rifle", "at", "rifle"][i], p, sq)
				s.cmd_move(c + off * 0.3 + side * (k - 1) * 8.0)
		var v := spawn_vehicle(t, "tank" if t == 0 else "apc", G.grid.nearest_free(c + off * 1.6, Grid.M_HEAVY), Soldier._yaw_of(toward))
		v.cmd_move(c + off * 0.5)
		var v2 := spawn_vehicle(t, "technical", G.grid.nearest_free(c + off * 1.5 + Vector3(8, 0, -8), Grid.M_LIGHT), Soldier._yaw_of(toward))
		v2.cmd_move(c + off * 0.6 + Vector3(6, 0, -6))
	G.explode(c + Vector3(3, 0, 5), 4.0, 100.0, "shell", -1, null)

func _run_autoplay() -> void:
	Sfx.muted = true
	G.spectate = true
	build_world(shot_scene if shot_scene != "" else "desert", 777)
	_spectate_ai()
	Engine.time_scale = 4.0
	var t0 := Time.get_ticks_msec()
	var last := 0
	while G.time < autoplay and not G.game_over:
		await get_tree().process_frame
		if int(G.time) / 30 != last:
			last = int(G.time) / 30
			var n := [0, 0]
			var bl := ["", ""]
			for u in G.units:
				if is_instance_valid(u) and u.alive and u.team >= 0:
					n[u.team] += 1
					if u is Building:
						bl[u.team] += u.btype.substr(0, 2) + ("" if u.done else "*") + " "
					elif u is Vehicle:
						bl[u.team] += u.vtype.substr(0, 1).to_upper() + " "
			print("t=%d units=%s supply=%d/%d kills=%s fps=%d
   A: %s
   B: %s" % [int(G.time), n, int(G.supply[0]), int(G.supply[1]), G.stats["kills"], Engine.get_frames_per_second(), bl[0], bl[1]])
	print("AUTOPLAY DONE t=%d winner=%d real=%ds" % [int(G.time), G.winner, (Time.get_ticks_msec() - t0) / 1000])
	get_tree().quit()
