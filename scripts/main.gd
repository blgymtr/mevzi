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
	if shot_dir != "" and shot_scene == "editortest":
		_run_editor_test()
	elif shot_dir != "" and shot_scene.begins_with("roundtrip"):
		_run_roundtrip()
	elif shot_dir != "" and shot_scene.begins_with("gallery"):
		_run_gallery()
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
	if G.editor:
		G.running = false
		return
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

func start_game(kind: String, data := {}) -> void:
	G.hud.hide_menu()
	_close_editor()
	G.spectate = false
	G.player_team = 0
	build_world(kind, randi(), data)
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
	G.cam.size = 20.0
	G.cam.target_size = 20.0
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
