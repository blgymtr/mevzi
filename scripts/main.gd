class_name Main extends Node3D
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
var cfg := {"volume": 0.8, "difficulty": 1, "lang": "", "fullscreen": true, "shadows": true, "edge_scroll": true}

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
	apply_video()
	if shot_dir != "" and shot_scene == "scentest":
		_run_scen_test()
	elif shot_dir != "" and shot_scene == "orders":
		_run_orders_test()
	elif shot_dir != "" and shot_scene == "behav":
		_run_behav_test()
	elif shot_dir != "" and shot_scene == "sandbox":
		_run_sandbox_test()
	elif shot_dir != "" and shot_scene == "arttest":
		_run_art_test()
	elif shot_dir != "" and shot_scene == "vehtest":
		_run_veh_test()
	elif shot_dir != "" and shot_scene.begins_with("cattest"):
		_run_cat_test()
	elif shot_dir != "" and shot_scene == "posetest":
		_run_pose_test()
	elif shot_dir != "" and shot_scene == "weathertest":
		_run_weather_test()
	elif shot_dir != "" and shot_scene == "logitest":
		_run_logi_test()
	elif shot_dir != "" and shot_scene == "modetest":
		_run_mode_test()
	elif shot_dir != "" and shot_scene == "stresstest":
		_run_stress_test()
	elif shot_dir != "" and shot_scene == "armortest":
		_run_armor_test()
	elif shot_dir != "" and shot_scene == "crash":
		_run_crash_test()
	elif shot_dir != "" and shot_scene == "editortest":
		_run_editor_test()
	elif shot_dir != "" and shot_scene.begins_with("roundtrip"):
		_run_roundtrip()
	elif shot_dir != "" and shot_scene.begins_with("gallery"):
		_run_gallery()
	elif shot_dir != "" and shot_scene.begins_with("show"):
		_run_showroom()
	elif shot_dir != "" and shot_scene == "test":
		_run_test()
	elif shot_dir != "":
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
	var b := Biomes.get_biome(kind)
	sun.light_color = b["sun"]
	sun.light_energy = b["sun_e"]
	env.ambient_light_color = b["amb"]
	env.ambient_light_energy = b["amb_e"]
	env.background_color = b["bg"]
	env.adjustment_saturation = b["sat"]
	env.tonemap_exposure = b["exp"]

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
	if G.modes and is_instance_valid(G.modes):
		G.modes.queue_free()
	G.modes = null
	if G.weather and is_instance_valid(G.weather):
		G.weather.restore()
		G.weather.queue_free()
	G.weather = null
	G.reset()
	bodies.clear()

func build_world(id: String, seed_v: int, data := {}) -> void:
	_clear_world()
	if not data.is_empty():
		id = "custom"
	elif not MapGen.MAPS.has(id):
		id = {"desert": "desert_town", "winter": "winter_village"}.get(id, "desert_canal")
	var kind: String = String(data.get("biome", "desert")) if id == "custom" else MapGen.MAPS[id]["biome"]
	G.map_kind = kind
	G.map_id = id
	var bio := Biomes.get_biome(kind)
	G.biome = bio
	_apply_theme(kind)
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	G.world = world
	G.grid = Grid.new()
	var t := Terrain.new()
	world.add_child(t)
	G.terrain = t
	t.build(bio)
	var fx := Fx.new()
	fx.winter = kind == "winter"
	fx.sand_col = bio["sand"]
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
	mg.data_in = data
	G.mapgen = mg
	mg.build(id, seed_v)
	var lg := Logistics.new()
	add_child(lg)
	G.logi = lg
	var pc := PlayerCtl.new()
	add_child(pc)
	G.player = pc
	pc.team = G.player_team
	var scen: Dictionary = data.get("scenario", {}) if data is Dictionary else {}
	G.scenario = scen if (not scen.is_empty() and scen.get("enabled", false)) else {}
	if G.editor:
		G.running = false
		if not scen.is_empty():
			spawn_scenario_units(scen, true)
		return
	if G.scenario.is_empty():
		_start_forces()
	else:
		_start_scenario(G.scenario)
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

func _start_scenario(sc: Dictionary) -> void:
	var hqs: Array = sc.get("hq", [true, true])
	for t in 2:
		if hqs[t]:
			var hq := place_building(t, "hq", G.hq_pos[t], 0.0)
			hq.complete()
	spawn_scenario_units(sc, false)
	var sup: Array = sc.get("supply", [650, 650])
	G.supply = [float(sup[0]), float(sup[1])]

const SCEN_UNITS := {
	"rifle_squad": "TÜFEK TİMİ", "mg_team": "MAKİNELİ TİM", "at_squad": "TANKSAVAR TİMİ", "medic_team": "SIHHİYE TİMİ",
	"sniper_team": "KESKİN NİŞANCI", "engineer_squad": "İSTİHKÂM TİMİ", "mortar_team": "HAVAN TİMİ", "drone_team": "DRONE EKİBİ",
	"technical": "TEKNİK ARAÇ", "apc": "ZPT", "ifv": "PSA", "aa": "UÇAKSAVAR", "tank": "TANK", "arty": "OBÜS", "heli": "SALDIRI HELİ.", "transport": "NAKLİYE HELİ.",
	"fob": "İLERİ ÜS", "barracks": "KIŞLA", "factory": "FABRİKA", "helipad": "HELİKOPTER PİSTİ", "hospital": "HASTANE", "mgnest": "MG YUVASI", "tower": "KULE",
}

func spawn_scenario_units(sc: Dictionary, preview: bool) -> void:
	for e in sc.get("units", []):
		var t := int(e["team"])
		var id := String(e["id"])
		var p := MapGen.v3(e["p"])
		var r := float(e.get("r", 0.0))
		if Building.BDEF.has(id):
			var b := place_building(t, id, p, r)
			b.complete()
		elif Building.PDEF.has(id):
			var P: Dictionary = Building.PDEF[id]
			if P.has("vehicle"):
				var v := spawn_vehicle(t, P["vehicle"], p, r)
				if preview:
					v.set_process(false)
			else:
				var sq := Squad.new(t, P["title"])
				G.squads.append(sq)
				var us: Array = P["units"]
				for i in us.size():
					var q := G.grid.nearest_free(p + Vector3((i % 3 - 1) * 1.4, 0, (i / 3) * 1.4).rotated(Vector3.UP, r), Grid.M_INF)
					var s := spawn_soldier(t, us[i], q, sq)
					s.rotation.y = r
					s.face_yaw = r

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
	G.props.clear_area(b.position, b.radius + 0.5)
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
var editor: MapEditor

func _close_editor() -> void:
	if editor and is_instance_valid(editor):
		editor.queue_free()
	editor = null
	G.editor = false

func open_editor(d: Dictionary, reset_cam := true) -> void:
	G.hud.hide_menu()
	_close_editor()
	G.editor = true
	G.spectate = false
	build_world("", 1, d)
	editor = MapEditor.new()
	add_child(editor)
	editor.open(d)
	G.cam.auto_pan = false
	G.cam.input_enabled = true
	if reset_cam:
		G.cam.jump_to(Vector3(128, 0, 128), true)
		G.cam.target_size = 70.0

func open_editor_from_builtin(id: String) -> void:
	G.editor = true
	build_world(id, randi())
	var d := G.mapgen.to_data(MapGen.MAPS[id]["title"].to_lower().replace(" ", "_"))
	open_editor(d, false)

func new_map(biome: String) -> void:
	open_editor({"v": 1, "name": "yeni_harita", "biome": biome, "hq": [[214, 214], [42, 42]], "fobs": [[186, 160], [160, 186], [70, 96], [96, 70], [128, 128]], "ops": []})

func to_menu() -> void:
	_close_editor()
	if sandbox_ui and is_instance_valid(sandbox_ui):
		sandbox_ui.queue_free()
	sandbox_ui = null
	G.sandbox = false
	G.fog_off = false
	Engine.time_scale = 1.0
	G.spectate = true
	build_world(MapGen.MAPS.keys()[randi() % MapGen.MAPS.size()], randi())
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

var _restarting := false

func restart_spectate() -> void:
	if _restarting:
		return
	_restarting = true
	call_deferred("_do_restart")

func _do_restart() -> void:
	_restarting = false
	to_menu()
	if autoplay > 0.0:
		Engine.time_scale = 4.0

var sandbox_ui: Sandbox = null

func start_game(kind: String, data := {}, sandbox := false) -> void:
	G.hud.hide_menu()
	_close_editor()
	G.spectate = false
	G.player_team = 0
	if sandbox_ui and is_instance_valid(sandbox_ui):
		sandbox_ui.queue_free()
	sandbox_ui = null
	G.sandbox = sandbox
	G.fog_off = false
	build_world(kind, randi(), data)
	if sandbox:
		sandbox_ui = Sandbox.new()
		add_child(sandbox_ui)
	if not sandbox and G.scenario.is_empty() and shot_dir == "":
		G.deploy_t = G.DEPLOY_TIME
	G.weather = Weather.new()
	add_child(G.weather)
	G.weather.setup("clear" if (sandbox or shot_dir != "") else G.weather_pref, G.night_pref and not sandbox and shot_dir == "")
	if sandbox:
		pass
	elif G.scenario.is_empty() and G.mode != "bases":
		G.modes = Modes.new()
		add_child(G.modes)
		G.modes.setup(G.mode)
	var ai_on: Array = [false, true]
	if not G.scenario.is_empty():
		ai_on = G.scenario.get("ai", [false, true])
	if sandbox:
		ai_on = [false, false]
	for t in 2:
		if ai_on[t] and t != G.player_team:
			var a := AICmd.new(t)
			add_child(a)
			G.ais.append(a)
	if not G.scenario.is_empty() and String(G.scenario.get("brief", "")) != "":
		G.say(String(G.scenario["brief"]), G.hq_pos[0], 0)
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
		G.scenario_step(dt)

# ------------------------------------------------------------ ayarlar
func _load_cfg() -> void:
	var f := FileAccess.open("user://settings.json", FileAccess.READ)
	if f:
		var d = JSON.parse_string(f.get_as_text())
		if d is Dictionary:
			cfg.merge(d, true)
	Sfx.set_volume(float(cfg["volume"]))
	G.difficulty = int(cfg["difficulty"])
	var lg := String(cfg.get("lang", ""))
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--lang="):
			lg = a.substr(7)
	I18n.setup(lg if lg != "" else I18n.default_lang())

func set_lang(l: String) -> void:
	cfg["lang"] = l
	I18n.setup(l)
	save_cfg()

func apply_video() -> void:
	if shot_dir == "":
		var fs: bool = cfg.get("fullscreen", true)
		var want := DisplayServer.WINDOW_MODE_EXCLUSIVE_FULLSCREEN if fs else DisplayServer.WINDOW_MODE_MAXIMIZED
		if DisplayServer.window_get_mode() != want:
			DisplayServer.window_set_mode(want)
	if sun:
		sun.shadow_enabled = cfg.get("shadows", true)
	if G.cam:
		G.cam.edge_scroll = cfg.get("edge_scroll", true)

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
	var kind := shot_scene if MapGen.MAPS.has(shot_scene) else "desert_canal"
	G.spectate = true
	build_world(kind, 12345)
	_spectate_ai()
	G.cam.input_enabled = false
	G.cam.jump_to(Vector3(128, 0, 128), true)
	G.cam.size = 40.0
	G.cam.target_size = 40.0
	await _wait(2.0)
	print("DBG h=", G.terrain.ground_h(Vector3(110, 0, 120)), " water=", G.terrain.has_water, " wnode=", G.terrain.water)
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
	G.player.clear_sel()
	for u in G.units:
		if u is Soldier and u.team == 0 and u.alive:
			u.add_xp(20)
			G.player.select(u)
			break
	G.hud.set_tab("inf")
	G.cam.jump_to(G.player.selected[0].position if not G.player.selected.is_empty() else G.hq_pos[0], true)
	G.cam.size = 11.0
	G.cam.target_size = 11.0
	await _wait(0.8)
	await _shot(kind + "_10_soldier")
	G.player.clear_sel()
	var sq: Squad = null
	for u in G.units:
		if u is Soldier and u.team == 0 and u.alive and u.squad:
			sq = u.squad
			break
	if sq:
		G.player.select_squad_of(sq.alive_members()[0])
	G.hud.set_tab("armor")
	await _wait(0.8)
	await _shot(kind + "_11_squad")
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
	# yeni sınıflar
	for t in 2:
		var off2 := Vector3(-1, 0, -1).normalized() * (34.0 if t == 1 else -34.0)
		var sq2 := Squad.new(t, "Destek")
		G.squads.append(sq2)
		for i in 6:
			var rl: String = ["mortar", "mortar", "sniper", "drone", "drone", "engineer"][i]
			var sp := spawn_soldier(t, rl, G.grid.nearest_free(c + off2 + Vector3(i * 1.5 - 4, 0, 6), Grid.M_INF), sq2)
			sp.rotation.y = Soldier._yaw_of(-off2)
		var aa := spawn_vehicle(t, "aa", G.grid.nearest_free(c + off2 * 1.2 + Vector3(-8, 0, 8), Grid.M_HEAVY), Soldier._yaw_of(-off2))
		aa.cmd_move(c + off2 * 0.9 + Vector3(-8, 0, 8))
		var ar := spawn_vehicle(t, "arty", G.grid.nearest_free(c + off2 * 1.8, Grid.M_HEAVY), Soldier._yaw_of(-off2))
		var ifv := spawn_vehicle(t, "ifv", G.grid.nearest_free(c + off2 * 1.3 + Vector3(8, 0, 0), Grid.M_HEAVY), Soldier._yaw_of(-off2))
		ifv.cmd_move(c + off2 * 0.4 + Vector3(8, 0, 0))
	var tr := spawn_vehicle(0, "transport", c + Vector3(-40, 0, -40), Soldier._yaw_of(Vector3(1, 0, 1)))
	var sqt := Squad.new(0, "İndirme")
	G.squads.append(sqt)
	for i in 6:
		var ps := spawn_soldier(0, "rifle", tr.position, sqt)
		ps.board(tr)
	tr.cmd_move(c + Vector3(-14, 0, -18))
	tr.landing = true
	var h := spawn_vehicle(0, "heli", c + Vector3(30, 0, 30), Soldier._yaw_of(Vector3(-1, 0, -1)))
	h.cmd_move(c + Vector3(8, 0, 8))
	G.explode(c + Vector3(3, 0, 5), 4.0, 100.0, "shell", -1, null)

func _run_autoplay() -> void:
	Sfx.muted = true
	G.spectate = true
	build_world(shot_scene if shot_scene != "" else "desert_canal", 777)
	_spectate_ai()
	Engine.time_scale = 4.0
	var t0 := Time.get_ticks_msec()
	var last := 0
	while (Time.get_ticks_msec() - t0) / 1000.0 * 4.0 < autoplay:
		await get_tree().process_frame
		if int(G.time) / 30 != last or G.time < 1.0 and last != 0:
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

# oyuncu akışı testi: üs kur, üret, ikmal, savunma hattı
func _run_crash_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("desert_canal", {}, true)
	sandbox_ui.run("fog")
	var c: Vector3 = G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 30.0
	var h1 := spawn_vehicle(0, "heli", c, 0.0)
	var h2 := spawn_vehicle(1, "transport", c + Vector3(14, 0, -6), 1.0)
	G.cam.jump_to(c + Vector3(6, 0, -2), true)
	G.cam.size = 30.0
	G.cam.target_size = 30.0
	await _wait(2.0)
	h1.destroy(null)
	h2.destroy(null)
	for k in 6:
		await _wait(0.35)
		await _shot("crash_%02d" % k)
	await _wait(2.0)
	await _shot("crash_end")
	print("CRASH done alive=%s,%s" % [h1.alive, h2.alive])
	get_tree().quit()

func _run_cat_test() -> void:
	# katalog: modeli olan birimler yan yana, katalog zırhı/canı uygulanıyor mu, hareket ve atış
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	var pref := shot_scene.substr(8) if shot_scene.length() > 8 else "usa_"
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.55), Grid.M_HEAVY)
	var vs: Array = []
	var i := 0
	for e in Catalog.order:
		var id: String = e[2]
		if not id.begins_with(pref) or not Art.has(id):
			continue
		var v := spawn_vehicle(0, id, G.grid.nearest_free(c + Vector3((i % 6) * 9.0 - 22.0, 0, (i / 6) * 11.0), Grid.M_HEAVY), PI * 0.8)
		vs.append(v)
		i += 1
	print("CAT spawned=%d of %d catalog units" % [vs.size(), Catalog.units.size()])
	if vs.is_empty():
		fails += 1
	else:
		var v: Vehicle = vs[0]
		print("CAT %s title=%s hp=%d armor=%s base=%s" % [v.vid, v.title, int(v.max_hp), v.armor_text(), v.vtype])
		if v.vid == "" or v.armor_tab().is_empty():
			fails += 1
	G.cam.jump_to(c + Vector3(0, 0, 4), true)
	G.cam.size = 30.0
	G.cam.target_size = 30.0
	await _wait(1.5)
	await _shot("cat_01_row")
	G.cam.jump_to(c + Vector3(-13, 0, 0), true)
	G.cam.size = 12.0
	G.cam.target_size = 12.0
	await _wait(1.0)
	await _shot("cat_02_close")
	# hareket + düşmana ateş
	var e1 := spawn_vehicle(1, "tank", G.grid.nearest_free(c + Vector3(0, 0, -40), Grid.M_HEAVY), 0.0)
	for v in vs:
		v.cmd_attack(e1)
	await _wait(12.0)
	print("CAT enemy hp=%d/%d" % [int(e1.hp), int(e1.max_hp)])
	if e1.alive and e1.hp >= e1.max_hp:
		fails += 1
	print("CATTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_pose_test() -> void:
	# iskeletli asker: tüm pozlar yan yana (ABD üst sıra, Rusya alt sıra), yakın çekim
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	G.spectate = true
	build_world("green_valley", 4242)
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	await get_tree().process_frame
	var c := Vector3(170, 0, 170)
	G.props.clear_area(c, 30.0)
	var poses := [["stand", 0.0], ["walk", 1.6], ["run", 4.0], ["aim", 0.0], ["crouch", 0.0], ["crouch_aim", 0.0], ["prone", 0.0], ["crawl", 0.6], ["vault", 0.0], ["slide", 0.0], ["carry", 1.5], ["wounded", 0.0]]
	var bodies: Array = []
	for t in 2:
		for i in poses.size():
			var s := spawn_soldier(t, ["rifle", "mg", "at", "rifle"][i % 4], c + Vector3(-11 + i * 2.0, 0, t * 3.2), null)
			s.position = c + Vector3(-11 + i * 2.0, 0, t * 3.2)
			s.rotation.y = PI * 1.3
			s.set_process(false)
			bodies.append([s, poses[i]])
	G.running = false
	G.cam.input_enabled = false
	for k in 40:
		for b in bodies:
			b[0].body.animate(0.033, b[1][0], b[1][1], 0.5)
		await get_tree().process_frame
	G.cam.jump_to(c + Vector3(0, 0, 1.6), true)
	G.cam.size = 13.0
	G.cam.target_size = 13.0
	await _wait(0.8)
	for b in bodies:
		b[0].body.animate(0.0, b[1][0], b[1][1], 0.5)
	await _shot("pose_all")
	G.cam.jump_to(c + Vector3(-6, 0, 1.6), true)
	G.cam.size = 5.0
	G.cam.target_size = 5.0
	await _wait(0.8)
	await _shot("pose_close")
	print("POSETEST DONE")
	get_tree().quit()

func _run_weather_test() -> void:
	# yağmur/sağanak (sel), kum fırtınası (uçuş yok), kar fırtınası (üşüme/ısınma), gece
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	var W := G.weather
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var sq := Squad.new(0, "T")
	for i in 6:
		spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(i * 1.5, 0, 0), Grid.M_INF), sq)
	var tech := spawn_vehicle(0, "technical", G.grid.nearest_free(c + Vector3(0, 0, 8), Grid.M_LIGHT), 0.0)
	G.cam.jump_to(c, true)
	G.cam.target_size = 45.0
	W.set_kind("rain")
	await _wait(2.0)
	await _shot("weather_01_rain")
	print("WEATHER rain sight=%.2f mud_speed=%.2f" % [W.sight_mult(), tech.speed_factor()])
	if W.sight_mult() >= 1.0 or tech.speed_factor() >= 1.0:
		fails += 1
	var wet0 := 0
	for i in G.grid.water.size():
		if G.grid.water[i] >= 1:
			wet0 += 1
	W.set_kind("storm")
	await _wait(3.0)
	var wet1 := 0
	for i in G.grid.water.size():
		if G.grid.water[i] >= 1:
			wet1 += 1
	if not G.grid.bridges.is_empty():
		G.cam.jump_to(G.grid.bridges[0]["c"], true)
	await _wait(4.0)
	await _shot("weather_02_storm_flood")
	print("WEATHER storm water cells %d -> %d" % [wet0, wet1])
	if G.terrain.has_water and wet1 <= wet0:
		fails += 1
	W.set_kind("clear")
	await _wait(1.0)
	var wet2 := 0
	for i in G.grid.water.size():
		if G.grid.water[i] >= 1:
			wet2 += 1
	print("WEATHER flood receded %d" % wet2)
	if wet2 != wet0:
		fails += 1
	# kum fırtınası
	var h := spawn_vehicle(0, "heli", c + Vector3(10, 0, -10), 0.0)
	await _wait(3.0)
	var alt0: float = h.hull.position.y
	W.set_kind("sandstorm")
	G.cam.jump_to(c, true)
	await _wait(6.0)
	await _shot("weather_03_sandstorm")
	print("WEATHER sandstorm heli alt %.1f -> %.1f no_air=%s" % [alt0, h.hull.position.y, W.no_air()])
	if h.hull.position.y > 1.0 or alt0 < 2.0:
		fails += 1
	# kar fırtınası: sahada üşür, karargâhta ısınır
	W.set_kind("snowstorm")
	var s0: Soldier = sq.members[0]
	var hqs := spawn_soldier(0, "rifle", G.grid.nearest_free(G.hq_pos[0] + Vector3(10, 0, 0), Grid.M_INF), null)
	await _wait(20.0)
	await _shot("weather_04_snow")
	print("WEATHER snow field_cold=%d hq_cold=%d" % [int(s0.cold), int(hqs.cold)])
	if s0.cold < 10.0 or hqs.cold > 1.0:
		fails += 1
	W.set_kind("clear")
	W.night = true
	W.set_kind_silent("clear")
	await _wait(1.0)
	await _shot("weather_05_night")
	print("WEATHER night sight=%.2f" % W.sight_mult())
	if W.sight_mult() >= 1.0:
		fails += 1
	print("WEATHERTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_logi_test() -> void:
	# kg stok: ileri üs mühimmatı stoktan verir, araç onarımı, üsse dönüş iadesi, konuşlanma aşaması
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var hq: Vector3 = G.hq_pos[0]
	var mid: Vector3 = hq.lerp(G.hq_pos[1], 0.35)
	var fob := place_building(0, "fob", G.grid.nearest_free(mid, Grid.M_HEAVY), 0.0)
	fob.complete()
	var st0: float = fob.stock
	var s := spawn_soldier(0, "at", G.grid.nearest_free(fob.position + Vector3(fob.radius + 2.0, 0, 0), Grid.M_INF), null)
	s.ammo = 0
	s.mag = 0
	s.rockets = 0
	s.cmd_hold()
	await _wait(4.0)
	print("LOGI ammo=%d rockets=%d stock %d -> %d" % [s.ammo, s.rockets, int(st0), int(fob.stock)])
	if s.ammo <= 0 or fob.stock >= st0:
		fails += 1
	fob.stock = 0.0
	var a0: int = s.ammo
	s.ammo = 0
	await _wait(3.0)
	print("LOGI empty stock ammo=%d" % s.ammo)
	if s.ammo > 0:
		fails += 1
	a0 = a0
	# araç onarımı (karargâh: sınırsız)
	var tk := spawn_vehicle(0, "tank", G.grid.nearest_free(hq + Vector3(14, 0, 0), Grid.M_HEAVY), 0.0)
	tk.hp = tk.max_hp * 0.5
	tk.add_crit("opt", 1)
	await _wait(9.0)
	print("LOGI repair hp=%d/%d crit_opt=%d" % [int(tk.hp), int(tk.max_hp), tk.crit["opt"]])
	if tk.hp <= tk.max_hp * 0.5:
		fails += 1
	# iade
	var sup0: float = G.supply[0]
	var r := spawn_soldier(0, "rifle", G.grid.nearest_free(hq + Vector3(30, 0, 20), Grid.M_INF), null)
	r.cost_share = 30.0
	r.cmd_refund()
	var ifv := spawn_vehicle(0, "ifv", G.grid.nearest_free(hq + Vector3(-30, 0, 25), Grid.M_HEAVY), 0.0)
	ifv.cmd_refund()
	await _wait(16.0)
	var gone := not is_instance_valid(r) or not r.alive
	var vgone := not is_instance_valid(ifv) or not ifv.alive
	print("LOGI refund soldier_gone=%s ifv_gone=%s supply +%d" % [gone, vgone, int(G.supply[0] - sup0)])
	if not gone or not vgone or G.supply[0] - sup0 < 100.0:
		fails += 1
	# konuşlanma: ateş yok
	G.deploy_t = 8.0
	var b1 := spawn_soldier(0, "rifle", G.grid.nearest_free(mid + Vector3(0, 0, 10), Grid.M_INF), null)
	var e1 := spawn_soldier(1, "rifle", G.grid.nearest_free(mid + Vector3(12, 0, 10), Grid.M_INF), null)
	b1.cmd_hold()
	e1.cmd_hold()
	await _wait(4.0)
	G.cam.jump_to(mid, true)
	await _shot("logi_01_deploy")
	var quiet: bool = b1.shots == 0 and e1.shots == 0
	await _wait(8.0)
	var fought: bool = b1.shots > 0 or e1.shots > 0
	print("LOGI deploy quiet=%s fought_after=%s" % [quiet, fought])
	if not quiet or not fought:
		fails += 1
	print("LOGITEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_mode_test() -> void:
	# Fetih: bölge ele geçirme, çekişme, puan; Savaş Hedefleri: aşama sonu puanı
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	G.mode = "conquest"
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var zs: Array = G.modes.zones
	print("MODE zones=%d" % zs.size())
	if zs.size() != 5:
		fails += 1
	var za: Vector3 = zs[0]["p"]
	var ze: Vector3 = zs[4]["p"]
	var zc: Vector3 = zs[2]["p"]
	for i in 3:
		spawn_soldier(0, "rifle", G.grid.nearest_free(za + Vector3(i, 0, 0), Grid.M_INF), null).cmd_hold()
		spawn_soldier(1, "rifle", G.grid.nearest_free(ze + Vector3(i, 0, 0), Grid.M_INF), null).cmd_hold()
	var b0 := spawn_soldier(0, "rifle", G.grid.nearest_free(zc, Grid.M_INF), null)
	var r0 := spawn_soldier(1, "rifle", G.grid.nearest_free(zc + Vector3(2, 0, 0), Grid.M_INF), null)
	b0.fire_mode = 2
	r0.fire_mode = 2
	b0.cmd_hold()
	r0.cmd_hold()
	await _wait(9.0)
	G.cam.jump_to(za, true)
	G.cam.target_size = 45.0
	await _wait(1.0)
	await _shot("mode_01_conquest")
	print("MODE A owner=%d prog=%.2f  E owner=%d  C contested=%s owner=%d  score=%s" % [zs[0]["owner"], zs[0]["prog"], zs[4]["owner"], zs[2]["contested"], zs[2]["owner"], G.modes.score])
	if zs[0]["owner"] != 0 or zs[4]["owner"] != 1 or not zs[2]["contested"] or zs[2]["owner"] != -1:
		fails += 1
	await _wait(5.0)
	if G.modes.score[0] <= 0.0 or G.modes.score[1] <= 0.0:
		fails += 1
	# Savaş Hedefleri
	G.mode = "wargoals"
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var z0: Vector3 = G.modes.zones[1]["p"]
	for i in 4:
		spawn_soldier(0, "rifle", G.grid.nearest_free(z0 + Vector3(i, 0, 0), Grid.M_INF), null).cmd_hold()
	await _wait(8.0)
	G.modes.phase_t = 0.5
	await _wait(1.0)
	print("MODE wargoals phase=%d score=%s owner=%d" % [G.modes.phase, G.modes.score, G.modes.zones[1]["owner"]])
	if G.modes.phase != 2 or G.modes.score[0] < 40.0:
		fails += 1
	G.mode = "bases"
	print("MODETEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_stress_test() -> void:
	# stres: baskı → sarsılmış → panik (kaçar, ateş etmez) → toparlanma; araç kritikleri ve onarım
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	sandbox_ui.run("fog")
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var s := spawn_soldier(0, "rifle", c, null)
	await _wait(0.5)
	for i in 6:
		s.add_suppression(30.0, c + Vector3(20, 0, 0))
	var lv1 := s.stress_lv
	for i in 10:
		s.add_suppression(40.0, c + Vector3(20, 0, 0))
	var lv2 := s.stress_lv
	await _wait(1.0)
	var fled := s.order == "panic" or s.position.distance_to(c) > 2.0
	var shots0: int = s.shots
	var e := spawn_soldier(1, "rifle", c + Vector3(15, 0, 0), null)
	e.cmd_hold()
	await _wait(3.0)
	var fired := s.shots > shots0
	G.cam.jump_to(s.position, true)
	await _shot("stress_01_panic")
	e.queue_free()
	G.units.erase(e)
	print("STRESS lv1=%d lv2=%d fled=%s fired_while_panic=%s stress=%d" % [lv1, lv2, fled, fired, int(s.stress)])
	if lv1 < 1 or lv2 != 2 or not fled or fired:
		fails += 1
	var st0: float = s.stress
	await _wait(12.0)
	print("STRESS recover %d -> %d lv=%d" % [int(st0), int(s.stress), s.stress_lv])
	if s.stress > st0 - 15.0:
		fails += 1
	# araç: hafif tanksavar delerse her zaman kritik
	var vc := G.grid.nearest_free(c + Vector3(0, 0, 25), Grid.M_HEAVY)
	var tk := spawn_vehicle(1, "tank", vc, 0.0)
	tk.cmd_hold()
	Vehicle.shot_from = tk.position - tk.forward() * 20.0
	tk.take_damage(270.0, null, "rpg")
	var crits := tk.has_crit()
	var txt := ""
	for k in tk.crit:
		txt += "%s=%d " % [k, tk.crit[k]]
	print("STRESS tank crit=%s %s vstress=%d" % [crits, txt, int(tk.vstress)])
	if not crits:
		fails += 1
	tk.add_crit("mob", 2)
	var imm := tk.immobile()
	tk.add_crit("load", 1)
	var lm := tk.load_mult()
	G.cam.jump_to(tk.position, true)
	G.player.selected = [tk]
	await _wait(0.5)
	await _shot("stress_02_crit")
	await _wait(50.0)
	var left := 0
	for k in tk.crit:
		left += tk.crit[k]
	print("STRESS mob_red_immobile=%s load_mult=%.2f crit_left_after_50s=%d" % [imm, lm, left])
	if not imm or lm <= 1.0 or left >= 4:
		fails += 1
	print("STRESSTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_armor_test() -> void:
	# 4 yönlü zırh + mesafeye bağlı delme: aynı atış önden/yandan/arkadan/üstten farklı hasar verir
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	sandbox_ui.run("fog")
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var res := {}
	for vt in ["tank", "ifv", "apc", "technical"]:
		for k in ["bullet", "hmg", "auto", "rpg", "atgm", "ap", "shell"]:
			var row: Array = []
			for side in 4:
				var v := spawn_vehicle(1, vt, c, 0.0)
				v.cmd_hold()
				var dirs := [v.forward(), v.forward().cross(Vector3.UP), -v.forward(), Vector3.UP]
				var from: Vector3 = v.position + dirs[side] * 25.0
				Vehicle.shot_from = from
				var h0: float = v.hp
				v.take_damage(100.0, null, k)
				row.append(int(h0 - v.hp))
				v.queue_free()
				G.units.erase(v)
			res[vt + ":" + k] = row
			print("ARMOR %-10s %-7s ön/yan/arka/üst = %s" % [vt, k, row])
	# beklentiler
	if res["tank:rpg"][0] > 10 or res["tank:rpg"][2] < 90:
		fails += 1
	if res["tank:auto"][0] > 0 or res["tank:auto"][1] < 50:
		fails += 1
	if res["tank:bullet"].max() > 0:
		fails += 1
	if res["apc:hmg"][1] < 90 or res["apc:hmg"][0] >= res["apc:hmg"][1]:
		fails += 1
	if res["tank:ap"][0] < 90:
		fails += 1
	if res["technical:bullet"][0] <= 0:
		fails += 1
	# mesafe: yakın ve uzak kinetik delme
	var tk := spawn_vehicle(1, "ifv", c, 0.0)
	var near_p: float = tk.pen_at("auto", 5.0)
	var far_p: float = tk.pen_at("auto", 80.0)
	print("ARMOR pen auto near=%.1f far=%.1f" % [near_p, far_p])
	if near_p <= far_p:
		fails += 1
	# gerçek mermi: piyade tanksavarı tankı önden ve arkadan vurur
	var tank := spawn_vehicle(1, "tank", c, 0.0)
	tank.cmd_hold()
	tk.queue_free()
	G.units.erase(tk)
	var h0: float = tank.hp
	G.bal.rocket(tank.position + tank.forward() * 20.0 + Vector3(0, 1.2, 0), tank.aim_point(), 0, null, tank)
	await _wait(1.5)
	var d_front: float = h0 - tank.hp
	h0 = tank.hp
	G.bal.rocket(tank.position - tank.forward() * 20.0 + Vector3(0, 1.2, 0), tank.aim_point(), 0, null, tank)
	await _wait(1.5)
	var d_rear: float = h0 - tank.hp
	print("ARMOR live rpg front=%d rear=%d side=%s" % [int(d_front), int(d_rear), tank.SIDE_NAME[maxi(tank.last_side, 0)]])
	if d_rear <= d_front:
		fails += 1
	G.cam.jump_to(tank.position, true)
	await _shot("armor_01")
	print("ARMORTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_veh_test() -> void:
	# köprü geçişi, suya düşmeme, palet/teker/nişancı/sürücü hasarı, terk etme
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	sandbox_ui.run("fog")
	if G.grid.bridges.is_empty():
		print("VEH no bridge")
		get_tree().quit()
		return
	var br: Dictionary = G.grid.bridges[0]
	var bc: Vector3 = br["c"]
	var ax: Vector3 = br["d"]
	var vs: Array = []
	for i in 5:
		var vt: String = ["tank", "apc", "ifv", "truck", "technical"][i]
		var p := G.grid.nearest_free(bc - ax * (22.0 + i * 8.0), Vehicle.DEF[vt]["nav"])
		var v := spawn_vehicle(0, vt, p, Soldier._yaw_of(ax))
		v.cmd_move(bc + ax * (28.0 + i * 3.0))
		print("VEH spawn %s p=%s path=%d" % [vt, v.position, v.path.size()])
		vs.append(v)
	G.cam.jump_to(bc, true)
	G.cam.size = 50.0
	G.cam.target_size = 50.0
	for k in 70:
		await _wait(0.5)
		if k == 24:
			await _shot("veh_01_bridge")
	var crossed := 0
	var wet := 0
	for v in vs:
		if (v.position - bc).dot(ax) > 10.0:
			crossed += 1
		if G.grid.is_water(v.position):
			wet += 1
	print("VEH bridge crossed=%d/5 wet=%d fps=%d t=%.1f" % [crossed, wet, Engine.get_frames_per_second(), G.time])
	for v in vs:
		print("VEH  %s along=%.1f path=%d/%d spd=%.1f imm=%s" % [v.vtype, (v.position - bc).dot(ax), v.path_i, v.path.size(), v.cur_speed, v.immobile()])
	if crossed < 5 or wet > 0:
		fails += 1
	# palet
	var tk: Vehicle = vs[0]
	tk.take_damage(80.0, null, "mine")
	var broke := tk.tracks_broken > 0.0 and tk.immobile()
	tk.tracks_broken = 2.0
	await _wait(10.0)
	print("VEH tracks broke=%s repaired=%s" % [broke, tk.tracks_broken <= 0.0])
	if not broke or tk.tracks_broken > 0.0:
		fails += 1
	# nişancı: keskin nişancı vurur, piyade yerine geçer
	var tech: Vehicle = vs[4]
	var sn := spawn_soldier(1, "sniper", tech.position + Vector3(30, 0, 30), null)
	for i in 20:
		if not tech.gunner_ok:
			break
		tech.take_damage(5.0, sn, "bullet")
	var g_dead := not tech.gunner_ok
	sn.die(null)
	var rep := spawn_soldier(0, "rifle", G.grid.nearest_free(tech.position + Vector3(4, 0, 0), Grid.M_INF), null)
	rep.cmd_board(tech)
	await _wait(6.0)
	print("VEH gunner killed=%s replaced=%s" % [g_dead, tech.gunner_ok])
	if not g_dead or not tech.gunner_ok:
		fails += 1
	# teker
	for i in 10:
		tech.take_damage(5.0, null, "grenade")
	var flat := tech.tires
	var eng := spawn_soldier(0, "engineer", G.grid.nearest_free(tech.position + Vector3(-3, 0, 0), Grid.M_INF), null)
	await _wait(12.0)
	print("VEH tires flat=%d after_engineer=%d" % [flat, tech.tires])
	if flat == 0 or tech.tires >= flat:
		fails += 1
	eng = eng
	# terk et
	var n0 := 0
	for u in G.units:
		if u is Soldier and u.role == "crew":
			n0 += 1
	var ifv: Vehicle = vs[2]
	ifv.cmd_abandon()
	await _wait(1.0)
	var n1 := 0
	for u in G.units:
		if u is Soldier and u.role == "crew" and u.alive:
			n1 += 1
	await _shot("veh_02_abandon")
	await _wait(6.5)
	print("VEH abandon crew=%d destroyed=%s" % [n1 - n0, not ifv.alive])
	if n1 - n0 < 3 or ifv.alive:
		fails += 1
	print("VEHTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_art_test() -> void:
	# topçu: her tip düşman hedeflere ateş ediyor mu
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	sandbox_ui.run("fog")
	var c: Vector3 = G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 30.0
	var fwd: Vector3 = (G.hq_pos[1] - G.hq_pos[0]).normalized()
	var side := Vector3(-fwd.z, 0, fwd.x)
	var types := ["fieldgun", "howitzer", "atgun", "aagun", "hmortar", "mtngun", "arty", "mlrs"]
	var guns: Array = []
	for i in types.size():
		var g := spawn_vehicle(0, types[i], G.grid.nearest_free(c + side * (i - 3.5) * 6.0, Grid.M_LIGHT), Soldier._yaw_of(fwd))
		guns.append(g)
	var cb: Building = place_building(0, "coastal", G.grid.nearest_free(c - fwd * 12.0, Grid.M_HEAVY), 0.0)
	cb.add_work(99999.0)
	# hedefler
	for i in 4:
		spawn_vehicle(1, "tank" if i % 2 == 0 else "apc", G.grid.nearest_free(c + fwd * (45.0 + i * 12.0) + side * (i - 1.5) * 8.0, Grid.M_HEAVY), Soldier._yaw_of(-fwd))
	var sq := Squad.new(1, "T")
	for i in 6:
		spawn_soldier(1, "rifle", G.grid.nearest_free(c + fwd * 40.0 + side * (i - 3) * 2.0, Grid.M_INF), sq)
	spawn_vehicle(1, "heli", c + fwd * 50.0, 0.0)
	G.cam.jump_to(c + fwd * 15.0, true)
	G.cam.size = 52.0
	G.cam.target_size = 52.0
	var fired := {}
	for k in 50:
		await _wait(0.5)
		if k == 8 or k == 20:
			spawn_vehicle(1, "heli", guns[3].position + fwd * 35.0, 0.0)
		for g in guns:
			if is_instance_valid(g) and (g.main_cd > 0.5 or g.mlrs_left > 0 or (g.vtype == "aagun" and g.target != null)):
				fired[g.vtype] = true
		if k % 10 == 0:
			var aa = guns[3]
			print("ART dbg aa target=%s cd=%.2f yaw=%.2f" % [aa.target, aa.main_cd, aa.turret_yaw])
		if k == 14:
			await _shot("art_01")
	var coastal_fired := cb.gun_cd > 0.0 or cb.gun_target != null
	print("ART fired=%s coastal=%s" % [fired.keys(), coastal_fired])
	for t in types:
		if not fired.has(t):
			print("ART not fired: ", t)
			fails += 1
	await _shot("art_02")
	print("ART RESULT fails=%d" % fails)
	get_tree().quit()

func _run_sandbox_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("desert_canal", {}, true)
	var c: Vector3 = G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 40.0
	G.cam.jump_to(c, true)
	G.cam.size = 40.0
	G.cam.target_size = 40.0
	var n0 := G.units.size()
	sandbox_ui.place("p:tank", c)
	sandbox_ui.place("p:rifle_squad", c + Vector3(-8, 0, 6))
	sandbox_ui._set_team(1)
	sandbox_ui.place("p:apc", c + Vector3(25, 0, -25))
	sandbox_ui.place("s:leader", c + Vector3(-6, 0, 12))
	sandbox_ui.place("b:mgnest", c + Vector3(12, 0, 14))
	sandbox_ui.run("fog")
	sandbox_ui.run("god")
	await _wait(1.0)
	var spawned := G.units.size() - n0
	print("SBX spawned=%d supply=%d cap=%d fog_off=%s" % [spawned, int(G.supply[0]), G.cap_max[0], G.fog_off])
	if spawned < 10 or G.supply[0] < 90000.0 or G.cap_max[0] < 999 or not G.fog_off:
		fails += 1
	sandbox_ui.place("fx:boom_l", c + Vector3(20, 0, -20))
	await _wait(0.3)
	await _shot("sandbox_01")
	sandbox_ui.run("ai")
	print("SBX ai=%d" % G.ais.size())
	if G.ais.size() != 1:
		fails += 1
	sandbox_ui.run("ai")
	sandbox_ui.run("speed 2")
	sandbox_ui.run("clear")
	await _wait(0.5)
	var enemies := 0
	for u in G.units:
		if is_instance_valid(u) and u.alive and u.team == 1 and (u is Soldier or u is Vehicle):
			enemies += 1
	print("SBX after_clear enemies=%d speed=%.1f" % [enemies, Engine.time_scale])
	if enemies > 0:
		fails += 1
	var led := false
	for u in G.units:
		if u is Soldier and u.team == 0 and u.role == "rifle" and u.led():
			led = true
	print("SBX leader_bonus=%s" % led)
	if not led:
		fails += 1
	Engine.time_scale = 1.0
	print("SANDBOX RESULT fails=%d" % fails)
	get_tree().quit()

func _run_behav_test() -> void:
	# ragdoll, teslim/esir/istihbarat, sedye, yakın dövüş, irkilme
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c: Vector3 = G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 30.0
	c = G.grid.nearest_free(c, Grid.M_INF)
	G.cam.jump_to(c, true)
	G.cam.size = 26.0
	G.cam.target_size = 26.0
	# 1) ragdoll: patlama ile ölen askerler
	var victims: Array = []
	for i in 4:
		var v := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-6 + i * 1.2, 0, -6), Grid.M_INF), null)
		v.fire_mode = 2
		victims.append(v)
	await _wait(0.5)
	G.explode(c + Vector3(-4.5, 0, -6.5), 4.5, 300.0, "shell", 1, null)
	await _wait(0.35)
	await _shot("behav_01_ragdoll_fly")
	await _wait(2.5)
	await _shot("behav_02_ragdoll_rest")
	var dead := victims.filter(func(v): return is_instance_valid(v) and not v.alive and v.rag != null).size()
	print("BEH ragdoll dead_with_rag=%d" % dead)
	if dead == 0:
		fails += 1
	# 2) sahra hastanesi + sedye
	var hosp := place_building(0, "hospital", G.grid.nearest_free(c + Vector3(10, 0, 8), Grid.M_HEAVY), 0.0)
	hosp.progress = 1.0
	hosp.add_work(999.0)
	var wsq := Squad.new(0, "T")
	G.squads.append(wsq)
	var w := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-2, 0, 4), Grid.M_INF), wsq)
	await _wait(0.3)
	w.die(null)
	var w_state0 := w.state
	var job_seen := false
	var carried_seen := false
	for k in 60:
		await _wait(1.0)
		if hosp.job != null:
			job_seen = true
			if hosp.job.stage == "carry":
				carried_seen = true
				if k % 6 == 0:
					await _shot("behav_03_stretcher_%02d" % k)
		if k < 6:
			print("BEH dbg k=%d done=%s bearers=%d w=%s rescuer=%s" % [k, hosp.done, hosp.bearers.size(), w.state, w.rescuer])
		if is_instance_valid(w) and w.state == "hospital":
			break
	var in_hosp := is_instance_valid(w) and w.state == "hospital"
	print("BEH stretcher state0=%s job=%s carried=%s in_hospital=%s" % [w_state0, job_seen, carried_seen, in_hosp])
	if not in_hosp:
		fails += 1
	# 3) teslim olma ve esir
	var lone := spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(4, 0, -2), Grid.M_INF), null)
	var cap := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(1, 0, 1), Grid.M_INF), null)
	cap.fire_mode = 2
	await _wait(0.3)
	lone.surrender()
	await _wait(2.0)
	var pris := lone.state == "prisoner"
	await _shot("behav_04_prisoner")
	print("BEH surrender->%s" % lone.state)
	if not pris:
		fails += 1
	await _wait(8.0)
	await _shot("behav_05_intel")
	# 4) yakın dövüş
	var m1 := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-8, 0, 6), Grid.M_INF), null)
	var m2 := spawn_soldier(1, "rifle", m1.position + Vector3(1.0, 0, 0.3), null)
	var hp0 := m2.hp
	var melee_seen := false
	for k in 12:
		await _wait(0.25)
		if m1.state == "melee" or m2.state == "melee":
			melee_seen = true
	print("BEH melee=%s hp %d->%d" % [melee_seen, int(hp0), int(m2.hp) if is_instance_valid(m2) else -1])
	if not melee_seen:
		fails += 1
	# 5) irkilme
	var f1 := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(0, 0, 10), Grid.M_INF), null)
	await _wait(0.3)
	G.explode(f1.position + Vector3(6.5, 0, 0), 4.0, 50.0, "grenade", 1, null)
	await _wait(0.1)
	print("BEH flinch=%s" % (f1.flinch_t > 0.0))
	if not f1.flinch_t > 0.0:
		fails += 1
	await _shot("behav_06_flinch")
	# hastaneden çıkış
	await _wait(18.0)
	print("BEH after_hospital state=%s alive=%s limp=%s" % [w.state if is_instance_valid(w) else "-", is_instance_valid(w) and w.alive, is_instance_valid(w) and w.limp_t > 0])
	print("BEHAV RESULT fails=%d" % fails)
	get_tree().quit()

func _run_orders_test() -> void:
	# emir paneli: saldırı hareketi, ateş modu, duruş, el bombası, baskı, geri çekil, geri vites, sis
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c := Vector3(128, 0, 128)
	var blue := Squad.new(0, "T")
	var red := Squad.new(1, "T")
	G.squads.append(blue)
	G.squads.append(red)
	for i in 6:
		spawn_soldier(0, ["rifle", "rifle", "mg", "rifle", "at", "medic"][i], G.grid.nearest_free(c + Vector3(-20 + i * 1.5, 0, 14), Grid.M_INF), blue)
		spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(-18 + i * 1.5, 0, -22), Grid.M_INF), red)
	var tank := spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(10, 0, 20), Grid.M_HEAVY), 0.0)
	G.cam.jump_to(c, true)
	G.cam.size = 46.0
	G.cam.target_size = 46.0
	G.player.clear_sel()
	for m in blue.alive_members():
		G.player.select(m)
	await _wait(0.5)
	G.player.exec_order("amove", c + Vector3(-15, 0, -30))
	await _wait(6.0)
	var engaged := 0
	for m in blue.alive_members():
		if m.order == "amove" and m.state != "move":
			engaged += 1
	print("ORD amove engaged=%d" % engaged)
	if engaged == 0:
		fails += 1
	G.player.exec_order("fire", Vector3.INF)
	var fm_ok := blue.alive_members().all(func(m): return m.fire_mode == 1)
	G.player.exec_order("stance", Vector3.INF)
	var st_ok := blue.alive_members().all(func(m): return m.stance_lock == Soldier.STAND)
	G.player.exec_order("stance", Vector3.INF)
	G.player.exec_order("stance", Vector3.INF)
	G.player.exec_order("stance", Vector3.INF)
	G.player.exec_order("fire", Vector3.INF)
	G.player.exec_order("fire", Vector3.INF)
	print("ORD fire_mode=%s stance=%s back=%d/%d" % [fm_ok, st_ok, blue.alive_members()[0].fire_mode, blue.alive_members()[0].stance_lock])
	if not fm_ok or not st_ok or blue.alive_members()[0].fire_mode != 0 or blue.alive_members()[0].stance_lock != -1:
		fails += 1
	var g0 := 0
	for m in blue.alive_members():
		g0 += m.grenades
	G.player.order_button("grenade")
	var pend := G.player.pending_order
	await _wait(0.3)
	await _shot("orders_01_pending")
	G.player.exec_order("grenade", red.alive_members()[0].position if not red.alive_members().is_empty() else c)
	G.player.pending_order = ""
	await _wait(12.0)
	var g1 := 0
	for m in blue.alive_members():
		g1 += m.grenades
	print("ORD grenade pending=%s %d->%d" % [pend, g0, g1])
	if pend != "grenade" or g1 >= g0:
		fails += 1
	G.player.exec_order("suppress", c + Vector3(-14, 0, -22))
	var sup_ok := blue.alive_members().any(func(m): return m.suppress_until > G.time)
	await _wait(3.0)
	await _shot("orders_02_suppress")
	G.player.exec_order("retreat", Vector3.INF)
	await _wait(0.5)
	var ret_ok := blue.alive_members().any(func(m): return m.retreating and m.state == "move")
	print("ORD suppress=%s retreat=%s" % [sup_ok, ret_ok])
	if not sup_ok or not ret_ok:
		fails += 1
	G.player.clear_sel()
	G.player.select(tank)
	G.player.exec_order("reverse", tank.position + Vector3(0, 0, 25))
	await _wait(3.0)
	var rev_ok := tank.cur_speed < -0.2
	var sm_ok := false
	G.player.exec_order("smoke", Vector3.INF)
	sm_ok = tank.smoke_charges == 1
	G.player.exec_order("suppress", c + Vector3(-10, 0, -20))
	var gr_ok := tank.ground_until > G.time
	await _wait(2.0)
	await _shot("orders_03_tank")
	print("ORD reverse=%s (%.1f) smoke=%s ground=%s" % [rev_ok, tank.cur_speed, sm_ok, gr_ok])
	if not rev_ok or not sm_ok or not gr_ok:
		fails += 1
	print("ORDERS RESULT fails=%d" % fails)
	get_tree().quit()

func _run_test() -> void:
	Sfx.muted = true
	var fails := 0
	start_game("desert_town")
	Engine.time_scale = 3.0
	var hq: Building = null
	for u in G.units:
		if u is Building and u.team == 0 and u.btype == "hq":
			hq = u
	var toward: Vector3 = (G.hq_pos[1] - G.hq_pos[0]).normalized()
	# ileri üs yeri ara
	var fob: Building = null
	for r in [55.0, 60.0, 65.0, 70.0, 50.0]:
		for k in 12:
			var p: Vector3 = G.hq_pos[0] + toward.rotated(Vector3.UP, (k - 6) * 0.15) * r
			if PlayerCtl.can_place("fob", p, 0.0, 0) == "":
				G.supply[0] -= 300
				fob = place_building(0, "fob", p, 0.0)
				break
		if fob:
			break
	print("TEST fob placed: ", fob != null)
	var soldiers: Array = []
	for u in G.units:
		if u is Soldier and u.team == 0:
			soldiers.append(u)
	G.player.clear_sel()
	for s in soldiers.slice(0, 6):
		G.player.select(s)
	G.player._assign_builders(fob)
	print("TEST enqueue=", hq.enqueue("rifle_squad"), " supply=", G.supply[0], " q=", hq.queue.size())
	var bar: Building = null
	await _wait(8.0)
	for r in [16.0, 20.0, 24.0, 28.0]:
		for k in 16:
			var p2: Vector3 = G.hq_pos[0] + Vector3(cos(k * 0.4), 0, sin(k * 0.4)) * r
			if PlayerCtl.can_place("barracks", p2, 0.0, 0) == "":
				G.supply[0] -= 250
				bar = place_building(0, "barracks", p2, 0.0)
				break
		if bar:
			break
	print("TEST barracks placed: ", bar != null)
	G.player.clear_sel()
	for s in soldiers.slice(6, 12):
		G.player.select(s)
	G.player._assign_builders(bar)
	G.cam.jump_to(fob.position, true)
	await _wait(15.0)
	await _shot("test_01_building")
	await _wait(40.0)
	print("TEST fob done=%s progress=%.2f barracks done=%s" % [fob.done, fob.progress, bar.done if bar else false])
	if not fob.done:
		fails += 1
	var n0 := 0
	for u in G.units:
		if u is Soldier and u.team == 0 and u.alive:
			n0 += 1
	print("TEST soldiers=%d (start %d) supply=%d cap=%d/%d" % [n0, soldiers.size(), int(G.supply[0]), G.cap_used[0], G.cap_max[0]])
	if n0 <= soldiers.size():
		fails += 1
	var trucks := 0
	for u in G.units:
		if u is Vehicle and u.vtype == "truck" and u.team == 0:
			trucks += 1
	print("TEST trucks=%d roads=%d" % [trucks, G.logi.nodes[0].size()])
	if trucks == 0:
		fails += 1
	var s0: float = G.supply[0]
	# savunma hattı
	var a: Vector3 = fob.position + toward * 9.0 + Vector3(-toward.z, 0, toward.x) * 5.0
	var b: Vector3 = a - Vector3(-toward.z, 0, toward.x) * 10.0
	var line := place_line(0, "sandbags", a, b)
	G.player.clear_sel()
	for s in soldiers.slice(0, 4):
		G.player.select(s)
	G.player._assign_builders(line)
	await _wait(60.0)
	print("TEST supply after 60s: %d -> %d" % [int(s0), int(G.supply[0])])
	print("TEST sandbag line done=", not is_instance_valid(line))
	var ta: Vector3 = fob.position + toward * 14.0 - Vector3(-toward.z, 0, toward.x) * 6.0
	var tb: Vector3 = ta + Vector3(-toward.z, 0, toward.x) * 12.0
	var tl := place_line(0, "trench", ta, tb)
	tl.complete()
	var tc := place_line(0, "trench", tb, tb + toward * 6.0)
	tc.complete()
	G.player.clear_sel()
	var k := 0
	for s2 in soldiers.slice(0, 6):
		if is_instance_valid(s2) and s2.alive:
			s2.cmd_move(ta.lerp(tb, (k + 0.5) / 6.0))
			k += 1
	await _wait(12.0)
	G.cam.jump_to((ta + tb) * 0.5, true)
	G.cam.size = 18.0
	G.cam.target_size = 18.0
	await _wait(1.0)
	await _shot("test_03_trench")
	G.cam.jump_to(fob.position, true)
	await _wait(1.0)
	await _shot("test_02_fob")
	print("TEST RESULT fails=%d" % fails)
	get_tree().quit()

# model galerisi: iki ordunun araç ve askerleri yakın plan
# model vitrini: --scene=show_<harita>[_tip1,tip2]  (yakın çekim + oyun yakınlığı)
func _run_showroom() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var parts := shot_scene.split("_", false, 1)
	var rest: String = parts[1] if parts.size() > 1 else "green_valley"
	var mid := "green_valley"
	for k in MapGen.MAPS:
		if rest.begins_with(k):
			mid = k
			rest = rest.substr(k.length())
	var types: Array = ["tank", "apc", "ifv", "technical", "truck", "aa", "arty"]
	if rest.begins_with(":"):
		types = Array(rest.substr(1).split(","))
	G.spectate = true
	build_world(mid, 4242)
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	await get_tree().process_frame
	var c := Vector3(170, 0, 170)
	G.props.clear_area(c, 40.0)
	for t in 2:
		for i in types.size():
			var vt: String = types[i]
			var p := c + Vector3(-18 + i * 10.0, 0, -8 + t * 11.0)
			var v := spawn_vehicle(t, vt, p, PI * 0.9)
			v.set_process(false)
			v.hull.rotation.y = PI * 0.9
			if v.is_air():
				v.hull.position.y = 2.0
				if v.rotor_blades:
					v.rotor_blades.visible = false
		var roles := ["rifle", "mg", "at", "medic", "sniper", "engineer"]
		for i in roles.size():
			var s := spawn_soldier(t, roles[i], c + Vector3(-22 + i * 1.4, 0, 6 + t * 2.4), null)
			s.rotation.y = PI * 0.9
			s.set_process(false)
			s.body.animate(0.5, ["stand", "aim", "crouch_aim", "stand", "prone_aim", "stand"][i], 0.0)
	G.running = false
	G.cam.input_enabled = false
	G.cam.jump_to(c, true)
	G.cam.size = 40.0
	G.cam.target_size = 40.0
	await _wait(1.5)
	await _shot("show_" + mid + "_overview")
	for i in types.size():
		G.cam.jump_to(c + Vector3(-18 + i * 10.0, 0, -2.5), true)
		G.cam.size = 15.0
		G.cam.target_size = 15.0
		await _wait(0.6)
		await _shot("show_" + mid + "_" + types[i])
	G.cam.jump_to(c + Vector3(-18.5, 0, 7.2), true)
	G.cam.size = 6.5
	G.cam.target_size = 6.5
	await _wait(0.6)
	await _shot("show_" + mid + "_soldiers")
	G.cam.jump_to(c + Vector3(-12, 0, 0), true)
	G.cam.size = 22.0
	G.cam.target_size = 22.0
	await _wait(0.6)
	await _shot("show_" + mid + "_minzoom")
	get_tree().quit()

func _run_gallery() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var mid := shot_scene.substr(8) if shot_scene.length() > 8 else "desert_canal"
	if not MapGen.MAPS.has(mid):
		mid = "desert_canal"
	G.spectate = true
	build_world(mid, 4242)
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	await get_tree().process_frame
	var c := Vector3(186, 0, 160)
	G.props.clear_area(c, 22.0)
	var types := ["tank", "apc", "technical", "truck"]
	for t in 2:
		for i in types.size():
			var p := c + Vector3(-12 + i * 8.0, 0, -6 + t * 12.0)
			var v := spawn_vehicle(t, types[i], p, PI * 0.25)
			v.set_process(false)
			v.hull.rotation.y = PI * 0.25
		var h := spawn_vehicle(t, "heli", c + Vector3(20, 0, -6 + t * 12.0), PI * 0.25)
		h.set_process(false)
		h.hull.position.y = 3.0
		h.hull.rotation.y = PI * 0.25
		var roles := ["rifle", "mg", "at", "medic"]
		for i in roles.size():
			var s := spawn_soldier(t, roles[i], c + Vector3(-14 + i * 1.6, 0, 1 + t * 3.0), null)
			s.rotation.y = PI * 0.25
			s.set_process(false)
			s.body.animate(0.5, ["stand", "aim", "crouch_aim", "stand"][i], 0.0)
	G.running = false
	G.cam.input_enabled = false
	G.cam.jump_to(c + Vector3(2, 0, 0), true)
	G.cam.size = 26.0
	G.cam.target_size = 26.0
	await _wait(1.5)
	await _shot("gallery_" + mid + "_a")
	G.cam.jump_to(c + Vector3(-12, 0, 2), true)
	G.cam.size = 9.0
	G.cam.target_size = 9.0
	await _wait(1.0)
	await _shot("gallery_" + mid + "_soldiers")
	G.cam.jump_to(c + Vector3(-8, 0, 0), true)
	G.cam.size = 14.0
	G.cam.target_size = 14.0
	await _wait(1.0)
	await _shot("gallery_" + mid + "_tanks")
	get_tree().quit()

# harita kayıt → yeniden kurma testi
func _run_roundtrip() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var mid := shot_scene.substr(10) if shot_scene.length() > 10 else "desert_canal"
	G.spectate = true
	build_world(mid, 999)
	await _wait(0.5)
	var a := [G.blocks.bpos.size(), G.props.items.size(), G.mapgen.ops.size()]
	var data := G.mapgen.to_data("test")
	var json := JSON.stringify(data)
	G.cam.input_enabled = false
	G.cam.jump_to(Vector3(140, 0, 140), true)
	G.cam.size = 60.0
	G.cam.target_size = 60.0
	await _wait(1.0)
	await _shot("rt_a")
	var d2 = JSON.parse_string(json)
	build_world("", 1, d2)
	await _wait(0.5)
	var b := [G.blocks.bpos.size(), G.props.items.size(), G.mapgen.ops.size()]
	G.cam.jump_to(Vector3(140, 0, 140), true)
	await _wait(1.0)
	await _shot("rt_b")
	print("ROUNDTRIP a=%s b=%s json=%dKB" % [a, b, json.length() / 1024])
	get_tree().quit()

func _run_editor_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	new_map("green")
	await _wait(0.5)
	var ed := editor
	ed.tool = "river"
	ed._click(Vector3(10, 0, 150), false)
	ed._click(Vector3(90, 0, 130), false)
	ed._click(Vector3(170, 0, 110), false)
	ed._click(Vector3(250, 0, 100), false)
	ed._finish_line()
	await _wait(0.5)
	ed = editor
	ed.tool = "road"
	ed._click(Vector3(214, 0, 214), false)
	ed._click(Vector3(128, 0, 128), false)
	ed._click(Vector3(42, 0, 42), false)
	ed._finish_line()
	ed.tool = "house_pitched"
	for i in 6:
		ed._click(Vector3(110 + i * 11, 0, 150 + (i % 2) * 12), false)
	ed.tool = "house_flat"
	ed.size_i = 2
	ed._click(Vector3(150, 0, 90), false)
	ed.tool = "tree"
	for i in 6:
		ed._click(Vector3(60 + i * 9, 0, 180), true)
	ed.tool = "wall"
	ed._click(Vector3(100, 0, 100), false)
	ed._click(Vector3(112, 0, 100), false)
	ed.tool = "ruin"
	ed._click(Vector3(140, 0, 70), false)
	ed.name_edit.text = "test_haritasi"
	ed.save()
	G.cam.jump_to(Vector3(128, 0, 128), true)
	G.cam.size = 80.0
	G.cam.target_size = 80.0
	await _wait(1.0)
	await _shot("ed_01")
	var n_ops: int = ed.data["ops"].size()
	# silme testi
	ed._delete_near(Vector3(150, 0, 90))
	await _wait(0.5)
	print("EDTEST ops=%d after_delete=%d maps=%s" % [n_ops, editor.data["ops"].size(), MapEditor.list_maps()])
	var d := MapEditor.load_map("test_haritasi")
	start_game("", d)
	await _wait(3.0)
	G.cam.jump_to(Vector3(128, 0, 128), true)
	G.cam.size = 80.0
	await _wait(1.0)
	await _shot("ed_02_play")
	print("EDTEST play units=%d running=%s map=%s" % [G.units.size(), G.running, G.map_id])
	get_tree().quit()

func _run_scen_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	open_editor_from_builtin("winter_village")
	await _wait(0.5)
	var ed := editor
	ed._set_mode("scen")
	var sc := ed._scen()
	sc["hq"] = [false, false]
	sc["win"] = "annihilate"
	ed.team = 0
	for id in ["rifle_squad", "rifle_squad", "mg_team", "tank", "mortar_team"]:
		ed.tool = id
		ed._scen_click(Vector3(150 + randf_range(-10, 10), 0, 150 + randf_range(-10, 10)))
	ed.team = 1
	for id in ["rifle_squad", "at_squad", "ifv", "sniper_team", "drone_team"]:
		ed.tool = id
		ed._scen_click(Vector3(110 + randf_range(-10, 10), 0, 110 + randf_range(-10, 10)))
	G.cam.jump_to(Vector3(130, 0, 130), true)
	G.cam.size = 55.0
	G.cam.target_size = 55.0
	await _wait(1.0)
	await _shot("scen_01_editor")
	ed.name_edit.text = "test_senaryo"
	ed.save()
	var d := MapEditor.load_map("test_senaryo")
	start_game("", d)
	G.cam.jump_to(Vector3(130, 0, 130), true)
	G.cam.size = 55.0
	G.cam.target_size = 55.0
	var any_blue := 0
	for u in G.units:
		if u.team == 0:
			any_blue += 1
	print("SCENTEST units=%d blue=%d scen=%s" % [G.units.size(), any_blue, not G.scenario.is_empty()])
	# kızıl yapay zekâ yerine mavi birlikleri de saldırt
	for u in G.units:
		if u is Soldier or u is Vehicle:
			u.cmd_move(Vector3(130, 0, 130))
	Engine.time_scale = 3.0
	var t0 := Time.get_ticks_msec()
	while not G.game_over and Time.get_ticks_msec() - t0 < 60000:
		await get_tree().process_frame
	await _shot("scen_02_play")
	print("SCENTEST over=%s winner=%d t=%d" % [G.game_over, G.winner, int(G.time)])
	get_tree().quit()
