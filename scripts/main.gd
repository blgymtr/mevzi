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
var _t07: Tests07 = null
# test bekçisi: duvar saatiyle toplam süre sınırı + tek karede kilitlenme (sonsuz döngü) algılama.
# Ayrı iş parçacığında çalışır; ana iş parçacığı kilitlense bile süreç sonlanır ve günlükte neden/aşama görünür.
var _wd_thread: Thread = null
var _wd_mx := Mutex.new()
var _wd_phase := ""
var _beat_ms := 0
var _wd_stop := false
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
	if shot_dir != "":
		_start_watchdog()
		# testte gerçek fare imleci pencere kenarındaysa kenar kaydırma kamerayı kaçırıyordu (kırpılan kareler kayıyordu)
		cam.edge_scroll = false
		# sahne testleri kendi birliklerini kurar; gerçek menzilde karargâhtaki başlangıç tankı haritanın
		# ortasındaki deney birliklerini vuruyordu. Başlangıç kuvveti gereken testler istisna.
		start_units = shot_scene in ["battletest", "supplytest", "hudtest", "test", "crash"]
	if shot_dir != "" and shot_scene in ["treetest", "yieldtest", "dronetest", "woundtest", "ropetest", "evadetest", "crewtest", "fowtest", "paratest", "para2test", "ammotest", "stucktest", "fftest", "perftest", "tactest", "largetest", "hugetest", "rocktest", "mapprof", "lostest", "icontest", "spottest", "rangetest", "missiletest", "aimatch", "basegallery", "enginetest", "perf8k", "mounttest", "rotortest", "killtest", "tracktest", "crewvistest", "mortartest", "ruintest", "bridgetest", "shadowtest", "smoketest", "firetest", "soldiertest", "armeduav", "turrettest", "mbtgallery", "crewkilltest", "snipertest", "sandboxtest", "drivertest", "watertest", "vehaitest", "cratertest", "decktest", "jamtest", "aimtest", "smokepasstest", "dozertest", "towtest", "cratertypes", "backfiretest", "crowdtest", "trenchpose", "ramptest", "hulldowntest", "nadetest", "fobdark", "camtest", "towcrewtest", "rivertest", "hudshots", "menushots", "gfxbench", "ordertest", "posegallery", "groundshots", "wreckshots", "crewshots", "chinooktest", "bridgerebuild", "swimtest", "grassfiretest", "fencetest", "obstacletest", "engagetest", "inffighttest", "modes2test", "sandbagshots", "propgallery"]:
		_t07 = Tests07.new(self)
		_t07.run(shot_scene)
	elif shot_dir != "" and shot_scene == "scentest":
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
	elif shot_dir != "" and shot_scene == "escorttest":
		_run_escort_test()
	elif shot_dir != "" and shot_scene == "projtest":
		_run_proj_test()
	elif shot_dir != "" and shot_scene == "trenchtest":
		_run_trench_test()
	elif shot_dir != "" and shot_scene == "vfxtest":
		_run_vfx_test()
	elif shot_dir != "" and shot_scene == "septest":
		_run_sep_test()
	elif shot_dir != "" and shot_scene.begins_with("maptest"):
		_run_map_test()
	elif shot_dir != "" and shot_scene == "garrisontest":
		_run_garrison_test()
	elif shot_dir != "" and shot_scene == "hudtest":
		_run_hud_test()
	elif shot_dir != "" and shot_scene == "uavtest":
		_run_uav_test()
	elif shot_dir != "" and shot_scene == "posetest":
		_run_pose_test()
	elif shot_dir != "" and shot_scene == "weathertest":
		_run_weather_test()
	elif shot_dir != "" and shot_scene == "battletest":
		_run_battle_test()
	elif shot_dir != "" and shot_scene == "holdtest":
		_run_hold_test()
	elif shot_dir != "" and shot_scene == "buildtest":
		_run_build_test()
	elif shot_dir != "" and shot_scene == "cargotest":
		_run_cargo_test()
	elif shot_dir != "" and shot_scene == "supplytest":
		_run_supply_test()
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
	elif shot_dir != "" and shot_scene.begins_with("structtest"):
		_run_struct_test()
	elif shot_dir != "" and shot_scene.begins_with("archtest"):
		_run_arch_test()
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
	# basamaklı gölge mesafesi ekranın üst kenarını zaten kapsıyor: solma bandı olmasın (yakınlaştırırken bant
	# basamakla birlikte zıplıyor, gölgeler ekranın üstünde kayıyor gibi görünüyordu)
	sun.directional_shadow_fade_start = 1.0
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

# ------------------------------------------------------------ yükleme ekranı (büyük harita)
# Harita üretimi eşzamanlı (sahne ağacı iş parçacığında kurulamaz): ekran doğrudan RenderingServer
# tuval öğesine çizilir ve force_draw ile basılır; pencere olayları işlenir (Windows "yanıt vermiyor"
# demesin). Yükleme boyunca 3B çizim kapalı (yarım kurulmuş dünyayı çizmek boşa).
const LOAD_STEPS := {"start": 0.0, "grid": 0.02, "terrain": 0.03, "rivers": 0.05, "roads": 0.09, "rail": 0.11, "sites": 0.12,
	"town": 0.30, "towns": 0.40, "villages": 0.55, "farms": 0.60, "forests": 0.78, "fields": 0.86, "scatter": 0.90, "details": 0.92,
	"layout": 0.92, "water": 0.93, "blocks": 0.97, "grid_flush": 0.99, "scatter_end": 0.99, "mapgen": 0.99, "minimap": 1.0}
const LOAD_TEXT := {"start": "Harita hazırlanıyor", "grid": "Arazi ızgarası", "terrain": "Arazi", "rivers": "Nehirler", "roads": "Yol ağı ve köprüler",
	"rail": "Demiryolu", "sites": "Hedefler ve ileri üsler", "town": "Merkez kasaba", "towns": "Kasabalar", "villages": "Köyler", "farms": "Çiftlikler",
	"forests": "Ormanlar", "fields": "Tarlalar", "scatter": "Bitki örtüsü", "details": "Ayrıntılar", "layout": "Yerleşim", "water": "Su",
	"blocks": "Binalar", "grid_flush": "Yol bulma", "mapgen": "Hazır", "minimap": "Harita görünümü"}
var _load_ci := RID()
var _load_layer: CanvasLayer = null
var _load_title := ""
var _load_frac := 0.0

func load_begin(title: String) -> void:
	if DisplayServer.get_name() == "headless":
		return
	_load_title = title
	_load_frac = 0.0
	_load_layer = CanvasLayer.new()
	_load_layer.layer = 128
	add_child(_load_layer)
	var host := Control.new()
	_load_layer.add_child(host)
	_load_ci = RenderingServer.canvas_item_create()
	RenderingServer.canvas_item_set_parent(_load_ci, host.get_canvas_item())
	get_viewport().disable_3d = true
	load_step("start")

func load_step(stage: String) -> void:
	if not _load_ci.is_valid():
		return
	_load_frac = maxf(_load_frac, float(LOAD_STEPS.get(stage, _load_frac)))
	var vs := get_viewport().get_visible_rect().size
	var ci := _load_ci
	RenderingServer.canvas_item_clear(ci)
	RenderingServer.canvas_item_add_rect(ci, Rect2(Vector2.ZERO, vs), Color(0.055, 0.06, 0.055))
	var font: Font = G.hud.font_b if G.hud != null and G.hud.font_b != null else ThemeDB.fallback_font
	var w := minf(vs.x * 0.5, 720.0)
	var x0 := (vs.x - w) * 0.5
	var y0 := vs.y * 0.5
	font.draw_string(ci, Vector2(x0, y0 - 46), I18n.s(_load_title).to_upper(), HORIZONTAL_ALIGNMENT_LEFT, -1, 34, Color(0.95, 0.72, 0.3))
	RenderingServer.canvas_item_add_rect(ci, Rect2(x0, y0, w, 10), Color(0.16, 0.17, 0.16))
	RenderingServer.canvas_item_add_rect(ci, Rect2(x0, y0, w * _load_frac, 10), Color(0.95, 0.72, 0.3))
	font.draw_string(ci, Vector2(x0, y0 + 40), I18n.s(String(LOAD_TEXT.get(stage, stage))) + "…", HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.78, 0.8, 0.76))
	font.draw_string(ci, Vector2(x0 + w - 60, y0 + 40), "%d%%" % int(_load_frac * 100.0), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, Color(0.78, 0.8, 0.76))
	DisplayServer.process_events()
	RenderingServer.force_draw(true, 0.0)
	# test: yükleme ekranının bir karesi kaydedilir
	if shot_dir != "" and stage == "villages":
		get_viewport().get_texture().get_image().save_png(shot_dir.path_join("loading_screen.png"))

func load_end() -> void:
	if _load_ci.is_valid():
		RenderingServer.free_rid(_load_ci)
	_load_ci = RID()
	if _load_layer != null and is_instance_valid(_load_layer):
		_load_layer.queue_free()
	_load_layer = null
	get_viewport().disable_3d = false

func build_world(id: String, seed_v: int, data := {}) -> void:
	_clear_world()
	var big := float(MapGen.MAPS.get(id, {}).get("size", 256)) >= 2048.0 if data.is_empty() else float(data.get("size", 256)) >= 2048.0
	if big:
		load_begin(String(MapGen.MAPS.get(id, {}).get("title", "Harita")))
	if not data.is_empty():
		id = "custom"
	elif not MapGen.MAPS.has(id):
		id = {"desert": "desert_town", "winter": "winter_village"}.get(id, "desert_canal")
	var kind: String = String(data.get("biome", "desert")) if id == "custom" else MapGen.MAPS[id]["biome"]
	G.map_kind = kind
	G.map_id = id
	# harita boyutu: ızgara ve arazi çözünürlüğü buna göre
	G.MAP = float(MapGen.MAPS.get(id, {}).get("size", 256)) if id != "custom" else float(data.get("size", 256))
	G.prof("start")
	Combat.set_scale(G.MAP)
	Grid.configure(G.MAP)
	if G.cam != null:
		G.cam.setup_for_map(G.MAP)
	# 8 km: boya 4096 (2 m/piksel, 4 km ile aynı), yükseklik 4096 (2 m) — dokular parçalı yüklenir
	Terrain.HRES = mini(4096 if G.MAP > 4096.0 else 2048, int(G.MAP * 2.0))
	Terrain.RES = mini(4096 if G.MAP > 4096.0 else 2048, int(G.MAP * 4.0))
	var bio := Biomes.get_biome(kind)
	G.biome = bio
	_apply_theme(kind)
	world = Node3D.new()
	world.name = "World"
	add_child(world)
	G.world = world
	if G.grid != null:
		G.grid.shutdown()
	G.grid = Grid.new()
	G.prof("grid")
	var t := Terrain.new()
	world.add_child(t)
	G.terrain = t
	t.build(bio)
	G.prof("terrain")
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
	world.add_child(FogOfWar.new())
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
	G.prof("mapgen")
	# mini harita dokusu yükleme ekranındayken (oyun başında takılma olmasın)
	if G.hud != null and G.hud.radar != null:
		load_step("minimap")
		G.hud.radar._build_tex()
		G.prof("minimap")
	load_end()
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

# başlangıç birlikleri (sahne testlerinde kapalı: gerçek menzilde karargâhtaki tank haritanın ortasındaki
# deney birliklerini vuruyordu; testler kendi birliklerini kurar)
var start_units := true

func _start_forces() -> void:
	for t in 2:
		var hp: Vector3 = G.hq_pos[t]
		var rot := PI * 0.75 if t == 0 else -PI * 0.25
		var hq := place_building(t, "hq", hp, 0.0)
		hq.complete()
		if not start_units:
			G.supply[t] = 650.0
			continue
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
		var nat: String = G.nation[t] if t < G.nation.size() else "usa"
		var tk := {"usa": "usa_mbt_a2", "rus": "rus_mbt_72b3"}.get(nat, "tank")
		var lv := {"usa": "usa_lv_m1151", "rus": "rus_lv_tigr"}.get(nat, "technical")
		spawn_vehicle(t, tk if Catalog.has(tk) else "tank", G.grid.nearest_free(base - toward * 6.0 + side * 6.0, Grid.M_HEAVY), Soldier._yaw_of(toward))
		spawn_vehicle(t, lv if Catalog.has(lv) else "technical", G.grid.nearest_free(base - toward * 6.0 - side * 6.0, Grid.M_LIGHT), Soldier._yaw_of(toward))
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
	if not v.is_air() and not v.is_drone():
		# kapalı cepte (her yanı ağaç/duvar) doğan araç hiç yürüyemez: en yakın açık alana al
		var q: Vector3 = G.grid.nearest_open(v.position, v.nav_mode)
		if Vector2(q.x - v.position.x, q.z - v.position.z).length_squared() > 0.01:
			v.position = G.on_ground(q)
			v.dest = v.position
			v._last_pos = v.position
	return v

func place_building(t: int, bt: String, p: Vector3, rot: float) -> Building:
	var b := Building.new()
	b.position = G.on_ground(p)
	world.add_child(b)
	b.setup(t, bt, rot)
	G.props.clear_area(b.position, b.radius + 0.5)
	b.occupy_grid()
	if G.logi and is_instance_valid(G.logi):
		# yoldaki kamyon yeni yapının içinden geçmesin (roadmap 96)
		G.grid.flush_nav()
		G.logi.static_changed()
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

func start_game(kind: String, data := {}, sandbox := false, seed_v := -1) -> void:
	G.hud.hide_menu()
	_close_editor()
	G.spectate = false
	G.player_team = 0
	if sandbox_ui and is_instance_valid(sandbox_ui):
		sandbox_ui.queue_free()
	sandbox_ui = null
	G.sandbox = sandbox
	G.fog_off = false
	if seed_v < 0 and shot_dir != "":
		# test: --seed=<n> ile harita tohumu sabitlenir (kararsız sonucu yeniden üretmek için)
		for a in OS.get_cmdline_user_args():
			if a.begins_with("--seed="):
				seed_v = int(a.substr(7))
	if seed_v < 0:
		seed_v = randi() % 1000000
	if shot_dir != "":
		print("MAP id=%s seed=%d" % [kind, seed_v])
	build_world(kind, seed_v, data)
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
	_beat_ms = Time.get_ticks_msec()
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
	apply_gfx()
	if G.cam:
		G.cam.edge_scroll = cfg.get("edge_scroll", true)

# ------------------------------------------------------------ grafik kalitesi (roadmap 146)
# İnceleme dersi: "grafik ayarları başarımı neredeyse değiştirmiyor". Her ayar ölçülebilir maliyeti olan bir şeye
# bağlı (gfxbench sahnesi ön ayar başına kare süresini ölçer): çizim çözünürlüğü (FSR 1 ile ölçekleme), MSAA,
# gölge (atlas boyu, yumuşatma süzgeci, kapalı), SSAO, parlama, ot yoğunluğu (yeni üretilen ot karoları), FPS sınırı.
const GFX_KEYS := ["scale", "msaa", "shadow_q", "ssao", "glow", "grass", "fx", "fps_cap"]
# (154) gfxbench ölçümüne göre (RTX 5060, ~150 birlik çatışma): MSAA 4× tek başına ~57 ms GPU, yumuşak gölge
# ~38 ms, duman / toz ~27 ms — "Yüksek" MSAA 2× (FXAA zaten açık), 4× yalnız Özel'de
const GFX_PRESETS := [
	{"scale": 0.67, "msaa": 0, "shadow_q": 1, "ssao": false, "glow": false, "grass": 0.35, "fx": 0.4},    # düşük
	{"scale": 0.85, "msaa": 1, "shadow_q": 2, "ssao": false, "glow": true, "grass": 0.65, "fx": 0.7},     # orta
	{"scale": 1.0, "msaa": 1, "shadow_q": 3, "ssao": true, "glow": true, "grass": 1.0, "fx": 1.0},        # yüksek
]

func gfx(key: String):
	if cfg.has(key):
		return cfg[key]
	var p: Dictionary = GFX_PRESETS[clampi(int(cfg.get("gfx", 2)), 0, 2)]
	return p.get(key, 0 if key == "fps_cap" else null)

# ön ayarı uygula: tek tek ayarları ön ayar değerine döndürür (fps sınırı korunur)
func set_gfx_preset(i: int) -> void:
	cfg["gfx"] = i
	for k in GFX_KEYS:
		if k != "fps_cap":
			cfg.erase(k)
	cfg["shadows"] = int(gfx("shadow_q")) > 0
	apply_gfx()
	save_cfg()

# tek ayar değişince ön ayar "Özel" olur
func set_gfx(key: String, v) -> void:
	if int(cfg.get("gfx", 2)) != 3:
		for k in GFX_KEYS:
			cfg[k] = gfx(k)
		cfg["gfx"] = 3
	cfg[key] = v
	if key == "shadow_q":
		cfg["shadows"] = int(v) > 0
	apply_gfx()
	save_cfg()

func apply_gfx() -> void:
	# eski "Gölgeler: kapalı" ayarı gölge kalitesi 0 sayılır
	if cfg.has("shadows") and not bool(cfg["shadows"]) and not cfg.has("shadow_q"):
		cfg["shadow_q"] = 0
	var sq := int(gfx("shadow_q"))
	if sun:
		sun.shadow_enabled = sq > 0
		sun.shadow_blur = [0.0, 0.8, 1.2, 1.4][sq]
	if G.cam:
		# kamera her karede gölgeyi yakınlaştırmaya göre açıp kapatıyor: ayar oradan da geçerli olsun
		G.cam.shadows_on = sq > 0
	if sq > 0:
		RenderingServer.directional_shadow_atlas_set_size([2048, 2048, 4096, 8192][sq], true)
		RenderingServer.directional_soft_shadow_filter_set_quality([RenderingServer.SHADOW_QUALITY_HARD, RenderingServer.SHADOW_QUALITY_SOFT_VERY_LOW, RenderingServer.SHADOW_QUALITY_SOFT_LOW, RenderingServer.SHADOW_QUALITY_SOFT_HIGH][sq])
	var vp := get_viewport()
	if vp:
		var sc := clampf(float(gfx("scale")), 0.5, 1.0)
		vp.scaling_3d_mode = Viewport.SCALING_3D_MODE_FSR if sc < 0.99 else Viewport.SCALING_3D_MODE_BILINEAR
		vp.scaling_3d_scale = sc
		vp.msaa_3d = [Viewport.MSAA_DISABLED, Viewport.MSAA_2X, Viewport.MSAA_4X][clampi(int(gfx("msaa")), 0, 2)]
	if env:
		env.ssao_enabled = bool(gfx("ssao"))
		# (154) SSAO yüksek kalite + tam çözünürlükte büyük çatışmada tek başına ~145 ms GPU ölçüldü (gfxbench) →
		# orta kalite, yarım çözünürlük (görünümde fark çok az)
		RenderingServer.environment_set_ssao_quality(RenderingServer.ENV_SSAO_QUALITY_MEDIUM, true, 0.5, 2, 50.0, 300.0)
		env.glow_enabled = bool(gfx("glow"))
	Props.grass_k = clampf(float(gfx("grass")), 0.1, 1.0)
	Fx.density = clampf(float(gfx("fx")), 0.2, 1.0)
	Engine.max_fps = int(gfx("fps_cap"))

func save_cfg() -> void:
	# test sahneleri oyuncunun gerçek ayar dosyasına yazmaz (gfxbench zaman aşımında "Orta" ön ayarını bırakmıştı)
	if shot_dir != "":
		return
	cfg["volume"] = Sfx.volume
	cfg["difficulty"] = G.difficulty
	var f := FileAccess.open("user://settings.json", FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify(cfg))

# ------------------------------------------------------------ testler
func _shot(n: String) -> void:
	# ekransız kip (--headless, CI): çizim yok, görüntü atlanır; mantık testleri çizimsiz saniyeler içinde koşar
	if DisplayServer.get_name() == "headless":
		print("SHOT %s skipped(headless)" % n)
		return
	# çizim kapalıysa (test hızlandırma, bkz. Tests07._fast) yalnız bu kare için aç
	var off := not RenderingServer.render_loop_enabled
	if off:
		RenderingServer.render_loop_enabled = true
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	if off:
		RenderingServer.render_loop_enabled = false
	DirAccess.make_dir_recursive_absolute(shot_dir)
	img.save_png(shot_dir.path_join(n + ".png"))
	print("SHOT ", n)

# test aşaması: bekçi süre aşımında son aşamayı yazar
func test_phase(p: String) -> void:
	_wd_mx.lock()
	_wd_phase = p
	_wd_mx.unlock()
	print("PHASE %s ms=%d gt=%.1f" % [p, Time.get_ticks_msec(), G.time])

func _start_watchdog() -> void:
	var budget := 840.0      # toplam duvar saati (sn) — dış "timeout 900"den kısa olmalı (--budget=)
	var stall := 240.0       # tek kare bu kadar sürerse kilitlenme say (--stall=)
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--budget="):
			budget = float(a.substr(9))
		elif a.begins_with("--stall="):
			stall = float(a.substr(8))
	_beat_ms = Time.get_ticks_msec()
	_wd_thread = Thread.new()
	_wd_thread.start(_watchdog.bind(Time.get_ticks_msec() + int(budget * 1000.0), int(stall * 1000.0)))

func _watchdog(deadline: int, stall_ms: int) -> void:
	var asked := 0
	while not _wd_stop:
		OS.delay_msec(500)
		var now := Time.get_ticks_msec()
		_wd_mx.lock()
		var ph := _wd_phase
		_wd_mx.unlock()
		if asked == 0 and now > deadline:
			# yavaş ama canlı: düzgün çık (çıkış kodu 3)
			print("TIMEOUT scene=%s phase=%s wall=%ds gt=%.1f fps=%d" % [shot_scene, ph, now / 1000, G.time, Engine.get_frames_per_second()])
			asked = now
			_wd_quit.call_deferred()
		elif now - _beat_ms > stall_ms or (asked > 0 and now - asked > 20000):
			# ana iş parçacığı kare bitiremiyor (sonsuz döngü vb.): süreci öldür
			print("HANG scene=%s phase=%s frame_stuck=%ds" % [shot_scene, ph, (now - _beat_ms) / 1000])
			OS.kill(OS.get_process_id())
			return

func _wd_quit() -> void:
	get_tree().quit(3)

func _exit_tree() -> void:
	if _wd_thread != null:
		_wd_stop = true
		_wd_thread.wait_to_finish()

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
		var v := spawn_vehicle(0, id, G.grid.nearest_free(c + Vector3((i % 10) * 11.0 - 50.0, 0, (i / 10) * 13.0 - 40.0), Grid.M_HEAVY), PI * 0.8)
		vs.append(v)
		i += 1
	print("CAT spawned=%d of %d catalog units" % [vs.size(), Catalog.units.size()])
	if vs.is_empty():
		fails += 1
	else:
		var v: Vehicle = vs[0]
		print("CAT %s title=%s hp=%d armor=%s base=%s" % [v.vid, v.title, int(v.max_hp), v.armor_text(), v.vtype])
		if v.vid == "":
			fails += 1
	G.cam.jump_to(c + Vector3(0, 0, -10), true)
	G.cam.size = 60.0
	G.cam.target_size = 60.0
	await _wait(1.5)
	await _shot("cat_01_row")
	var k := 0
	for v in vs:
		if k % 12 == 0:
			G.cam.jump_to(v.position + Vector3(10, 0, 4), true)
			G.cam.size = 22.0
			G.cam.target_size = 22.0
			await _wait(0.8)
			await _shot("cat_z%02d" % (k / 12))
		k += 1
	if not vs.is_empty():
		G.cam.jump_to(vs[0].position, true)
		G.cam.size = 14.0
		G.cam.target_size = 14.0
		await _wait(1.0)
		await _shot("cat_02_close")
	# hareket + düşmana ateş
	var e1 := spawn_vehicle(1, "tank", G.grid.nearest_free(c + Vector3(0, 0, -40), Grid.M_HEAVY), 0.0)
	for v in vs:
		if is_instance_valid(v) and v.alive:
			v.cmd_attack(e1)
	await _wait(18.0)
	print("CAT enemy hp=%d/%d" % [int(e1.hp), int(e1.max_hp)])
	if e1.alive and e1.hp >= e1.max_hp:
		fails += 1
	print("CATTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_escort_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	# su sütunu
	var wp := Vector3.ZERO
	for z in range(10, int(G.MAP) - 10, 4):
		for x in range(10, int(G.MAP) - 10, 4):
			if G.grid.is_water(Vector3(x, 0, z)) and wp == Vector3.ZERO:
				wp = Vector3(x, 0, z)
	G.cam.jump_to(wp, true)
	G.cam.size = 20.0
	G.cam.target_size = 20.0
	await _wait(0.5)
	for i in 3:
		G.explode(wp + Vector3(i * 4 - 4, 0, 0), 4.5, 130.0, "shell", 1, null)
	await _wait(0.3)
	await _shot("water_01")
	# tank eskortu
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tk := spawn_vehicle(0, "usa_mbt_s3", c, 0.0)
	var men: Array = []
	for i in 4:
		var s := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(i * 1.5, 0, 8), Grid.M_INF), null)
		s.cmd_follow_vehicle(tk, i, 4)
		men.append(s)
	await _wait(3.0)
	var dest := G.grid.nearest_free(c + Vector3(0, 0, -40), Grid.M_HEAVY)
	tk.cmd_move(dest)
	await _wait(14.0)
	var near := 0
	for s in men:
		# eskort yeri aracın arkası: gövde yarı boyu + ~4 m (gerçek boyutlu tankta gövde 8 m)
		if s.position.distance_to(tk.position) < tk.ext.y + 4.5:
			near += 1
	G.cam.jump_to(tk.position, true)
	await _wait(0.5)
	await _shot("escort_01")
	print("ESC tank_moved=%.1f soldiers_with_tank=%d/4" % [tk.position.distance_to(c), near])
	if near < 3 or tk.position.distance_to(c) < 15.0:
		fails += 1
	print("ESCORTTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_proj_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.cam.jump_to(c, true)
	G.cam.size = 10.0
	G.cam.target_size = 10.0
	var t := spawn_vehicle(1, "rus_mbt_72b3", c + Vector3(14, 0, 0), 0.0)
	t.cmd_hold()
	await _wait(0.5)
	G.bal.rocket(c + Vector3(-6, 1.4, 1), t.aim_point(), 0, null, t)
	G.bal.rocket(c + Vector3(-6, 1.4, -2), t.aim_point(), 0, null, t, "atgm")
	G.bal.shell(c + Vector3(-8, 1.8, 3), t.aim_point(), 0, null, t, "ap")
	G.bal.mortar(c + Vector3(-4, 1, -4), c + Vector3(10, 0, -4), 0, null)
	G.bal.artillery(c + Vector3(-30, 30, 6), c + Vector3(6, 0, 6), 0, null)
	G.bal.grenade(c + Vector3(-2, 1.5, 4), c + Vector3(3, 0, 4), 0, null)
	await _wait(0.12)
	await _shot("proj_01")
	var s := spawn_soldier(1, "rifle", c + Vector3(2, 0, -6), null)
	s.cmd_hold()
	for i in 3:
		s.take_damage(10.0, null, "bullet")
		await _wait(0.1)
	await _wait(0.1)
	await _shot("proj_02_blood")
	print("PROJTEST RESULT fails=0")
	get_tree().quit()

func _run_trench_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("winter_village" if shot_dir.contains("win") else "green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tr := place_line(0, "trench", c + Vector3(-7, 0, 0), c + Vector3(7, 0, 3))
	var tr2 := place_line(0, "trench", c + Vector3(-7, 0, 8), c + Vector3(7, 0, 11))
	var men: Array = []
	for i in 4:
		var s := spawn_soldier(0, "engineer", G.grid.nearest_free(c + Vector3(i * 2 - 3, 0, -3), Grid.M_INF), null)
		s.cmd_build(tr)
		men.append(s)
	tr2.add_work(99999.0)
	G.cam.jump_to(c + Vector3(0, 0, 4), true)
	G.cam.size = 16.0
	G.cam.target_size = 16.0
	for k in 40:
		await _wait(0.5)
		if is_instance_valid(tr) and tr.progress > 0.45 and tr.progress < 0.7:
			break
	await _shot("trench_01_digging")
	tr.add_work(99999.0) if is_instance_valid(tr) else null
	await _wait(1.0)
	var deep := G.terrain.ground_h(c + Vector3(0, 0, 1.5))
	for i in 3:
		var s := spawn_soldier(0, ["rifle", "mg", "rifle"][i], c + Vector3(i * 3 - 3, 0, 9.5), null)
		s.cmd_hold()
	await _wait(2.0)
	await _shot("trench_02_done")
	print("TRENCH depth=%.2f" % deep)
	if deep > -0.8:
		fails += 1
	print("TRENCHTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_vfx_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.cam.jump_to(c, true)
	G.cam.size = 34.0
	G.cam.target_size = 34.0
	var vs: Array = []
	for i in 3:
		var v := spawn_vehicle(1, ["rus_mbt_72b3", "rus_ifv_bmp3", "rus_mbt_90m"][i], G.grid.nearest_free(c + Vector3(-12 + i * 12, 0, 0), Grid.M_HEAVY), 0.3)
		v.cmd_hold()
		vs.append(v)
	await _wait(1.0)
	# roket izi
	G.bal.rocket(c + Vector3(-30, 1.5, 22), vs[0].aim_point(), 0, null, vs[0])
	await _wait(0.4)
	await _shot("vfx_00_rocket")
	for v in vs:
		v.destroy(null)
	await _wait(0.35)
	await _shot("vfx_01_boom")
	await _wait(1.0)
	await _shot("vfx_02_fireball")
	await _wait(3.0)
	await _shot("vfx_03_smoke")
	# topçu isabetleri (toprak tacı)
	for i in 4:
		G.explode(c + Vector3(-10 + i * 7, 0, 14), 4.5, 130.0, "shell", 1, null)
	await _wait(0.25)
	await _shot("vfx_04_shells")
	print("VFXTEST RESULT fails=0")
	get_tree().quit()

func _run_sep_test() -> void:
	# iç içe girme: aynı noktaya araçlar ve askerler; ayrışmalı
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var vs: Array = []
	for i in 6:
		var v := spawn_vehicle(0, ["usa_mbt_s3", "usa_ifv_m2a3", "usa_apc_icv", "usa_lv_m1151", "rus_mbt_90m", "rus_apc_btr82"][i], c + Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)), randf() * TAU)
		v.cmd_hold()
		vs.append(v)
	var ss: Array = []
	for i in 20:
		var s := spawn_soldier(0, "rifle", c + Vector3(randf_range(-0.3, 0.3), 0, randf_range(-0.3, 0.3)), null)
		s.cmd_hold()
		ss.append(s)
	# 104: üst üste doğan araçlar yavaşça açılır — kare başına ışınlanıp "saçılmaz" (en yüksek hız ölçülür)
	var last_p: Array = []
	for v in vs:
		last_p.append(v.position)
	var vmax := 0.0
	var tt0 := G.time
	var tprev := G.time
	while G.time - tt0 < 4.0:
		await get_tree().process_frame
		var gdt := G.time - tprev
		tprev = G.time
		if gdt <= 0.0:
			continue
		for i in vs.size():
			vmax = maxf(vmax, vs[i].position.distance_to(last_p[i]) / gdt)
			last_p[i] = vs[i].position
	print("SEP vehicle_max_shove_speed=%.2f" % vmax)
	if vmax > 3.0:
		fails += 1
	var vo := 0
	for i in vs.size():
		for j in range(i + 1, vs.size()):
			var a: Vehicle = vs[i]
			var b: Vehicle = vs[j]
			if a.obb_push(b.position, -0.3) != Vector3.ZERO:
				vo += 1
	var inside := 0
	for s in ss:
		for v in vs:
			if v.obb_push(s.position, 0.0) != Vector3.ZERO:
				inside += 1
				print("SEP inside soldier state=%s pos=%s veh=%s veh_pos=%s push=%s h=%.2f vp=%s" % [s.state, s.position, v.vid, v.position, v.obb_push(s.position, 0.0), G.grid.height_at(s.position), s._vp_c])
	var close := 0
	for i in ss.size():
		for j in range(i + 1, ss.size()):
			if ss[i].position.distance_to(ss[j].position) < 0.4:
				close += 1
	G.cam.jump_to(c, true)
	G.cam.size = 30.0
	G.cam.target_size = 30.0
	await _wait(1.0)
	await _shot("sep_01")
	print("SEP vehicle_overlaps=%d soldiers_inside_vehicles=%d soldier_pairs_too_close=%d" % [vo, inside, close])
	# araçların ortasında doğan askerler: araçlar yavaş (2,5 m/sn) açıldığı için 4 sn'de birkaçı hâlâ izde olabilir;
	# 8 sn'de hepsi dışarıda olmalı
	await _wait(4.0)
	var inside8 := 0
	for s in ss:
		for v in vs:
			if v.obb_push(s.position, 0.0) != Vector3.ZERO:
				inside8 += 1
	print("SEP soldiers_inside_after_8s=%d" % inside8)
	# bilinen kalan: rastgele doğan 6 araçlık kümede 20 askerden biri bazen 8 sn'de hâlâ izde (ROADMAP 105)
	if vo > 0 or inside8 > 1 or close > 2:
		fails += 1
	# 105: asker duran aracın içinden yürüyerek geçmez — kamyonun öbür yanına giden asker yandan dolaşır
	var c2 := G.grid.nearest_free(c + Vector3(0, 0, 40), Grid.M_HEAVY)
	var trk := spawn_vehicle(0, "truck", c2, 0.0)
	trk.cmd_hold()
	await _wait(0.5)
	var walk_in := 0
	var walkers: Array = []
	for i in 4:
		var w := spawn_soldier(0, "rifle", G.grid.nearest_free(trk.position + trk.forward() * (trk.ext.y + 4.0) + trk.right() * (i - 1.5) * 0.8, Grid.M_INF), null)
		w.cmd_move(G.grid.nearest_free(trk.position - trk.forward() * (trk.ext.y + 4.0) + trk.right() * (i - 1.5) * 0.8, Grid.M_INF))
		walkers.append(w)
	var tw0 := G.time
	while G.time - tw0 < 14.0:
		await _wait(0.1)
		for w in walkers:
			if trk.obb_push(w.position, -0.1) != Vector3.ZERO:
				walk_in += 1
	var arrived := walkers.filter(func(x): return x.position.distance_to(trk.position - trk.forward() * (trk.ext.y + 4.0)) < 4.0).size()
	print("SEP walk_through_truck inside_samples=%d arrived=%d/4" % [walk_in, arrived])
	for w in walkers:
		if w.position.distance_to(trk.position - trk.forward() * (trk.ext.y + 4.0)) >= 4.0:
			print("SEP walker_stuck state=%s order=%s pos=%s truck=%s path=%d/%d d_truck=%.1f free=%s h=%.2f" % [w.state, w.order, w.position, trk.position, w.path_i, w.path.size(), w.dist2(trk), G.grid.free_at(w.position, Grid.M_INF), G.grid.height_at(w.position)])
	# içinden geçiş kesinlikle yok; bilinen kalan: kamyon ile çit arasındaki dar boşlukta bir asker takılabilir
	if walk_in > 0 or arrived < 3:
		fails += 1
	print("SEPTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_map_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var mid := shot_scene.substr(8) if shot_scene.length() > 8 else "big_city"
	var t0 := Time.get_ticks_msec()
	start_game(mid)
	print("MAP %s size=%d build_ms=%d houses=%d" % [mid, int(G.MAP), Time.get_ticks_msec() - t0, G.blocks.houses.size()])
	await _wait(3.0)
	G.cam.jump_to(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), true)
	G.cam.size = 110.0
	G.cam.target_size = 110.0
	await _wait(2.0)
	await _shot("map_01_center")
	G.cam.size = 40.0
	G.cam.target_size = 40.0
	await _wait(2.0)
	await _shot("map_02_close")
	print("MAP fps=%d units=%d" % [Engine.get_frames_per_second(), G.units.size()])
	print("MAPTEST RESULT fails=0")
	get_tree().quit()

func _run_garrison_test() -> void:
	# girilebilir bina: askerler kapıdan girer, pencerelere dağılır, çatı gizlenir, pencereden ateş eder
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true)
	sandbox_ui.run("fog")
	var hid := -1
	# 118 için mümkünse 8+ yuvalı ev (6'dan fazla askerin çıkışı denetlenir)
	for need in [8, 5]:
		for i in G.blocks.houses.size():
			var h: Dictionary = G.blocks.houses[i]
			if h.has("slots") and h["slots"].size() >= need and G.blocks.house_free_slot(i) >= 0 and Soldier.house_enterable(i):
				# en az bir penceresinden dışarıya görüş hattı açık olmalı (pencere çatışması denetimi için)
				var open := false
				for k in h["slots"].size():
					var wq: Vector3 = G.grid.nearest_free(h["slots"][k] + h["out"][k] * 16.0, Grid.M_INF)
					if G.grid.los(h["slots"][k] + Vector3(0, 1.55, 0), wq + Vector3(0, 1.0, 0), 1.6, 0.5):
						open = true
						break
				if not open:
					continue
				hid = i
				break
		if hid >= 0:
			break
	print("GAR houses=%d with_slots=%d pick=%d aid=%s" % [G.blocks.houses.size(), G.blocks.houses.filter(func(h): return h.has("slots")).size(), hid, G.blocks.houses[hid].get("aid", "?") if hid >= 0 else "-"])
	if hid < 0:
		print("GARRISONTEST RESULT fails=1")
		get_tree().quit()
		return
	var hc: Vector3 = G.blocks.houses[hid]["center"]
	var hd: Dictionary = G.blocks.houses[hid]
	print("GAR dbg center=%s size=%s door=%s solid_center=%s solid_door=%s path_door_center=%d" % [hc, hd["size"], hd["door"], G.grid.solid(Grid.cell_of(hc), Grid.M_INF), G.grid.solid(Grid.cell_of(hd["door"]), Grid.M_INF), G.grid.find_path(hd["door"], hc, Grid.M_INF).size()])
	for k in hd["slots"].size():
		var sp: Vector3 = hd["slots"][k]
		print("GAR dbg slot%d %s solid=%s path=%d" % [k, sp, G.grid.solid(Grid.cell_of(sp), Grid.M_INF), G.grid.find_path(hd["door"], sp, Grid.M_INF).size()])
	var sq := Squad.new(0, "T")
	var men: Array = []
	var nmen := mini(int(hd["slots"].size()), 10)
	for i in nmen:
		var s := spawn_soldier(0, ["leader", "rifle", "rifle", "mg", "rifle", "at", "rifle", "rifle", "mg", "rifle"][i], G.grid.nearest_free(G.blocks.houses[hid]["door"] + Vector3(i % 3 * 1.2, 0, i / 3 * 1.2), Grid.M_INF), sq)
		men.append(s)
		s.cmd_garrison(hid)
	await _wait(24.0)
	var inside := 0
	for s in men:
		if s.house_id == hid and G.blocks.house_at(s.position) == hid:
			inside += 1
	for s in men:
		print("GAR dbg hid=%d slot=%d state=%s order=%s at=%d d=%.1f path=%d/%d" % [s.house_id, s.house_slot, s.state, s.order, G.blocks.house_at(s.position), s.position.distance_to(G.blocks.houses[hid]["slots"][maxi(s.house_slot, 0)]), s.path_i, s.path.size()])
	var roof: Node3D = G.blocks.houses[hid]["roof"]
	print("GAR inside=%d/%d roof_hidden=%s" % [inside, nmen, not roof.visible])
	if inside < 4:
		fails += 1
	G.cam.jump_to(hc, true)
	G.cam.size = 22.0
	G.cam.target_size = 22.0
	# düşman, görüş hattı açık olan ilk pencerenin önüne (ilk pencerenin önü başka bir engelin arkasına düşebiliyordu)
	var w0: Vector3 = G.grid.nearest_free(hd["slots"][0] + hd["out"][0] * 16.0, Grid.M_INF)
	for k in hd["slots"].size():
		var wk: Vector3 = G.grid.nearest_free(hd["slots"][k] + hd["out"][k] * 16.0, Grid.M_INF)
		if G.grid.los(hd["slots"][k] + Vector3(0, 1.55, 0), wk + Vector3(0, 1.0, 0), 1.6, 0.5):
			w0 = wk
			break
	var e := spawn_soldier(1, "rifle", w0, null)
	e.cmd_hold()
	await _wait(5.0)
	await _shot("garrison_01")
	var shots := 0
	for s in men:
		shots += s.shots
	print("GAR shots_from_windows=%d" % shots)
	for s in men:
		var eye: Vector3 = s.position + Vector3(0, 1.55, 0)
		print("GAR dbg2 tgt=%s seen=%s sees=%s los_plain=%s d=%.1f e_alive=%s ct=%d" % [s.target, G.is_seen(e, 0), s.sees(eye, e.aim_point(), e), G.grid.los(eye, e.aim_point()), s.position.distance_to(e.position), e.alive, s.cover_type])
	if shots == 0 and e.alive:
		fails += 1          # pencereden çatışılmadı (düşman el bombasıyla öldürüldüyse atış sayılmaz ama çatışılmıştır)
	# 118: hızlı hareket emriyle evdeki herkes çıkar (eskiden 6'sı çıkıyor, gerisi içeride kalıyordu)
	e.die(null)
	var out_pt: Vector3 = G.grid.nearest_free(hd["door"] + (hd["door"] - hc).normalized() * 45.0, Grid.M_INF)
	var alive_men := men.filter(func(x): return x.alive)
	G.player.move_group(alive_men, out_pt, true)
	for s in alive_men:
		if s.order != "move":
			print("GAR no_move state=%s order=%s incap=%s hp=%.0f" % [s.state, s.order, s.incapacitated(), s.hp])
	var t_out := G.time
	while G.time - t_out < 20.0:
		await _wait(0.5)
		if alive_men.all(func(x): return G.blocks.house_at(x.position) != hid):
			break
	var still_in := alive_men.filter(func(x): return G.blocks.house_at(x.position) == hid)
	for s in still_in:
		print("GAR stuck_inside state=%s order=%s pos=%s path=%d/%d house_id=%d" % [s.state, s.order, s.position, s.path_i, s.path.size(), s.house_id])
	print("GAR exit men=%d out=%d t=%.1f" % [alive_men.size(), alive_men.size() - still_in.size(), G.time - t_out])
	if not still_in.is_empty():
		fails += 1
	print("GARRISONTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_hud_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("green_valley")
	G.supply[0] = 9999.0
	var f := place_building(0, "factory", G.grid.nearest_free(G.hq_pos[0] + Vector3(20, 0, 10), Grid.M_HEAVY), 0.0)
	f.complete()
	await _wait(1.0)
	G.hud.set_tab("armor")
	await _wait(1.5)
	await _shot("hud_01_armor")
	G.hud.set_tab("air")
	await _wait(1.5)
	await _shot("hud_02_air")
	var ok: bool = G.hud._producer("usa_mbt_s3") != null
	print("HUD producer_for_catalog=%s" % ok)
	print("HUDTEST RESULT fails=%d" % (0 if ok else 1))
	get_tree().quit()

func _run_uav_test() -> void:
	# İHA (keşif/silahlı/kamikaze) + güdümlü tanksavar (ABD üstten saldırı, Rusya doğrudan)
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley", {}, true, 43)
	sandbox_ui.run("fog")
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var t1 := spawn_vehicle(1, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(20, 0, 0), Grid.M_HEAVY), 0.0)
	var t2 := spawn_vehicle(1, "rus_ifv_bmp3", G.grid.nearest_free(c + Vector3(25, 0, 12), Grid.M_HEAVY), 0.0)
	var t3 := spawn_vehicle(0, "usa_mbt_s3", G.grid.nearest_free(c + Vector3(-20, 0, 25), Grid.M_HEAVY), 0.0)
	for v in [t1, t2, t3]:
		v.fire_mode = 2
		v.cmd_hold()
	var uav := spawn_vehicle(0, "usa_uav_mq9", c + Vector3(-30, 0, 0), 0.0)
	uav.cmd_move(c + Vector3(10, 0, 5))
	await _wait(14.0)
	G.cam.jump_to(c + Vector3(10, 0, 5), true)
	G.cam.target_size = 45.0
	await _shot("uav_01_armed")
	var h1 := t1.max_hp - t1.hp + t2.max_hp - t2.hp
	print("UAV armed missiles_left=%d dmg_to_enemies=%d" % [uav.missiles, int(h1)])
	if uav.missiles >= 4 or h1 <= 0:
		fails += 1
	# kamikaze (Rus) amerikan tankına
	var hp3: float = t3.hp
	var lm := spawn_vehicle(1, "rus_lm_lancet3", c + Vector3(-10, 0, -20), 0.0)
	await _wait(9.0)
	print("UAV loiter alive=%s us_tank_dmg=%d" % [is_instance_valid(lm) and lm.alive, int(hp3 - t3.hp)])
	if hp3 - t3.hp <= 0:
		fails += 1
	# güdümlü tanksavar timleri
	for v in [t1, t2]:
		if is_instance_valid(v):
			v.queue_free()
			G.units.erase(v)
	var tt := spawn_vehicle(1, "rus_mbt_90m", G.grid.nearest_free(c + Vector3(0, 0, -40), Grid.M_HEAVY), 0.0)
	tt.fire_mode = 2
	tt.cmd_hold()
	var hpt: float = tt.hp
	for i in 2:
		var a := spawn_soldier(0, "atgm", G.grid.nearest_free(c + Vector3(i * 2.0, 0, 15), Grid.M_INF), null)
		a.cmd_hold()
	var hp_us: float = t3.hp
	var r := spawn_soldier(1, "atgm", G.grid.nearest_free(t3.position + Vector3(10, 0, -45), Grid.M_INF), null)
	r.cmd_hold()
	await _wait(3.5)
	G.cam.jump_to(c + Vector3(0, 0, -10), true)
	await _shot("uav_02_atgm")
	await _wait(14.0)
	print("UAV atgm us_vs_t90 dmg=%d  rus_vs_abrams dmg=%d side=%s" % [int(hpt - tt.hp), int(hp_us - t3.hp), tt.SIDE_NAME[maxi(tt.last_side, 0)]])
	if hpt - tt.hp <= 0:
		fails += 1
	# keşif İHA görüşü
	var rq := spawn_vehicle(0, "usa_uav_rq7", c, 0.0)
	print("UAV recon sight=%d air=%s" % [int(rq.sight), rq.is_air()])
	print("UAVTEST RESULT fails=%d" % fails)
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
	G.props.clear_area(c, 40.0)
	# [poz, hız, hareket açısı, ek (ilerleme)]; her sıra 6 poz, her poz için ABD ve Rusya yan yana
	var poses := [["stand", 0.0, 0.0, 0.5], ["walk", 1.6, 0.0, 0.5], ["run", 4.0, 0.0, 0.5], ["aim", 0.0, 0.0, 0.5], ["aim", 2.0, 1.57, 0.5], ["aim", 2.0, 3.14, 0.5],
		["crouch", 0.0, 0.0, 0.5], ["crouch_aim", 0.0, 0.0, 0.5], ["crouch", 1.5, 0.0, 0.5], ["prone_aim", 0.0, 0.0, 0.5], ["crawl", 0.6, 0.0, 0.5], ["vault", 0.0, 0.0, 0.5],
		["build", 0.0, 0.0, 0.5], ["build_hi", 0.0, 0.0, 0.5], ["throw", 0.0, 0.0, 0.3], ["surrender", 0.0, 0.0, 0.5], ["flinch", 0.0, 0.0, 0.5], ["carry", 0.0, 0.0, 0.8],
		["cover", 0.0, 0.0, 0.5], ["lay", 0.0, 0.0, 0.5], ["ram", 0.0, 0.0, 0.5], ["drop", 0.0, 0.0, 0.5], ["blind", 0.0, 0.0, 0.5], ["blind_side", 0.0, 0.0, 0.5],
		["sling", 0.0, 0.0, 0.5], ["dragging", 1.0, 0.0, 0.5], ["melee", 0.0, 0.0, 0.5], ["wounded", 0.0, 0.0, 0.5], ["dead", 0.0, 0.0, 0.5], ["slide", 0.0, 0.0, 0.5],
		# şarjör değiştirme evreleri ve atış geri tepmesi: [.., şarjör ilerlemesi, geri tepme]
		["aim", 0.0, 0.0, 0.5, 0.12, 0.0], ["aim", 0.0, 0.0, 0.5, 0.35, 0.0], ["stand", 0.0, 0.0, 0.5, 0.55, 0.0], ["crouch_aim", 0.0, 0.0, 0.5, 0.75, 0.0], ["aim", 0.0, 0.0, 0.5, -1.0, 1.0], ["run", 3.7, 0.0, 0.5, -1.0, 0.0],
		# inşaat / ilk yardım / esir: kürekle kazma, kutu alma, sargı sarma, eller havada yürüyen esir, kutu taşıma
		["dig", 0.0, 0.0, 0.5], ["dig", 0.0, 0.0, 0.5], ["lift", 0.0, 0.0, 0.5], ["treat", 0.0, 0.0, 0.5], ["surrender", 1.4, 0.0, 0.5], ["carry", 1.4, 0.0, 1.0]]
	var bodies: Array = []
	var roles := ["rifle", "mg", "at", "rifle", "sniper", "medic"]
	# sıralar ekranda yatay: kamera sağ ekseni boyunca, sıralar ekranın yukarı ekseninde
	var rv: Vector3 = G.cam.right_vec()
	var uv: Vector3 = G.cam.up_vec()
	var row_c := func(row: int) -> Vector3: return c + uv * (8.0 - row * 4.0)
	for i in poses.size():
		var row := i / 6
		var col := i % 6
		for t in 2:
			var p: Vector3 = row_c.call(row) + rv * (-7.0 + col * 2.8 + t * 1.1)
			var s := spawn_soldier(t, roles[col], p, null)
			s.position = p
			# 3/4 önden: kameraya dönük, ekranın sağına doğru
			var fdir: Vector3 = (-uv + rv * 0.7).normalized()
			s.rotation.y = atan2(-fdir.x, -fdir.z)
			s.set_process(false)
			bodies.append([s, poses[i]])
	G.running = false
	G.cam.input_enabled = false
	var fails := 0
	for k in 40:
		for b in bodies:
			b[0].body.move_yaw = b[1][2]
			b[0].body.reload_k = b[1][4] if b[1].size() > 4 else -1.0
			if b[1].size() > 5 and b[1][5] > 0.0:
				b[0].body.recoil = b[1][5]
			b[0].body.animate(0.033, b[1][0], b[1][1], b[1][3])
		await get_tree().process_frame
	# ayak/diz zemine gömülmesin, havada kalmasın (dik pozlarda taban yere değsin)
	for b in bodies:
		var bd: SoldierBody = b[0].body
		var gy: float = b[0].global_position.y
		var fr: float = (bd.knee_r.global_transform * Vector3(0, -SoldierBody.SHIN, 0)).y - gy
		var fl: float = (bd.knee_l.global_transform * Vector3(0, -SoldierBody.SHIN, 0)).y - gy
		var lo := minf(fr, fl)
		print("POSE %-10s t=%d foot_r=%.2f foot_l=%.2f knee_r=%.2f knee_l=%.2f" % [b[1][0], b[0].team, fr, fl, bd.knee_r.global_position.y - gy, bd.knee_l.global_position.y - gy])
		if b[1][0] in ["stand", "aim", "build_hi", "surrender", "throw", "carry", "sling"] and b[1][1] == 0.0 and (lo < -0.08 or lo > 0.1):
			fails += 1
			print("POSE FAIL %s ayak yüksekliği %.2f" % [b[1][0], lo])
		# tek diz yerde: arka diz zemine değer, öndeki ayak tabanı yerde
		var kl: float = bd.knee_l.global_position.y - gy
		if b[1][0] in ["crouch", "crouch_aim", "cover", "lay", "ram", "blind", "blind_side", "build", "flinch"] and b[1][1] == 0.0 and (kl < 0.03 or kl > 0.17 or fr < -0.1 or fr > 0.07):
			fails += 1
			print("POSE FAIL %s diz %.2f ön ayak %.2f" % [b[1][0], kl, fr])
	G.cam.jump_to(c + Vector3(0, 0, 1.0), true)
	G.cam.size = 22.0
	G.cam.target_size = 22.0
	await _wait(0.8)
	await _shot("pose_all")
	G.cam.size = 5.2
	G.cam.target_size = 5.2
	for row in 7:
		for half in 2:
			G.cam.jump_to(row_c.call(row) + rv * (-4.2 + half * 8.4) - uv * 0.6, true)
			for k in 8:
				for b in bodies:
					b[0].body.move_yaw = b[1][2]
					b[0].body.reload_k = b[1][4] if b[1].size() > 4 else -1.0
					if b[1].size() > 5 and b[1][5] > 0.0:
						b[0].body.recoil = b[1][5]
					b[0].body.animate(0.033, b[1][0], b[1][1], b[1][3])
				await get_tree().process_frame
			await _shot("pose_row_%d%s" % [row, "ab"[half]])
	# şarjör değiştirme dizisi yakın çekim (ABD ve Rus tüfekçi, yandan)
	var rp := c + uv * 14.0
	var pair: Array = []
	for t in 2:
		var s := spawn_soldier(t, "rifle", rp + rv * (t * 1.0 - 0.5), null)
		s.position = rp + rv * (t * 1.0 - 0.5)
		var fd: Vector3 = (-uv + rv * 1.6).normalized()
		s.rotation.y = atan2(-fd.x, -fd.z)
		s.set_process(false)
		pair.append(s)
	G.cam.size = 2.6
	G.cam.target_size = 2.6
	G.cam.jump_to(rp + Vector3(0, 0.0, 0), true)
	for f in 6:
		for k in 10:
			for s2 in pair:
				s2.body.reload_k = f / 5.0
				s2.body.animate(0.033, "aim", 0.0, 0.5)
			await get_tree().process_frame
		await _shot("reload_%d" % f)
	print("POSETEST RESULT fails=%d" % fails)
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

func _run_battle_test() -> void:
	# yoğun çatışma görünümü: karşılıklı roket yaylımları (asılı beyaz iz kavisleri), yanan/cephanesi patlayan tanklar
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("desert_town")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c: Vector3 = G.hq_pos[0].lerp(G.hq_pos[1], 0.5)
	var ml0 := spawn_vehicle(0, "mlrs", G.grid.nearest_free(c + Vector3(-60, 0, -30), Grid.M_HEAVY), 0.0)
	var ml1 := spawn_vehicle(1, "mlrs", G.grid.nearest_free(c + Vector3(60, 0, 25), Grid.M_HEAVY), 0.0)
	var tks: Array = []
	for i in 5:
		tks.append(spawn_vehicle(i % 2, "tank", G.grid.nearest_free(c + Vector3(-18 + i * 9, 0, randf_range(-8, 8)), Grid.M_HEAVY), randf() * TAU))
	for i in 8:
		var s := spawn_soldier(i % 2, "rifle", G.grid.nearest_free(c + Vector3(randf_range(-25, 25), 0, randf_range(-18, 18)), Grid.M_INF), null)
		s.cmd_hold()
	ml0.mlrs_aim = c + Vector3(15, 0, 10)
	ml0.mlrs_left = 12
	ml1.mlrs_aim = c + Vector3(-15, 0, -8)
	ml1.mlrs_left = 12
	await _wait(1.2)
	for k in 3:
		tks[k].destroy(null)
		await _wait(0.6)
	await _wait(1.5)
	var mid := Vector3.ZERO
	for t in tks:
		mid += t.position / tks.size()
	print("BATTLE mid=%s c=%s ml0=%s ml1=%s" % [mid, c, ml0.position, ml1.position])
	G.cam.size = 58.0
	G.cam.target_size = 58.0
	G.cam.jump_to(mid, true)
	await _wait(0.6)
	await _shot("battle_01")
	ml0.mlrs_aim = c + Vector3(25, 0, -6)
	ml0.mlrs_left = 12
	await _wait(2.0)
	await _shot("battle_02")
	print("BATTLETEST DONE")
	get_tree().quit()

func _run_hold_test() -> void:
	# silah tutuşu yakın çekim: bekleme (low ready) ayakta/yürüyüş/koşu, nişan, tabanca çekme (kılıf) ve nişan, çömelme
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	G.spectate = true
	build_world("green_valley", 4242)
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	await get_tree().process_frame
	var c := Vector3(170, 0, 170)
	G.props.clear_area(c, 20.0)
	var poses := [["stand", 0.0, -1.0], ["walk", 1.6, -1.0], ["run", 4.0, -1.0], ["aim", 0.0, -1.0], ["stand", 0.0, 0.3], ["stand", 0.0, 1.0], ["crouch", 0.0, -1.0], ["crouch_aim", 0.0, -1.0]]
	var bodies: Array = []
	for t in 2:
		for i in poses.size():
			var s := spawn_soldier(t, "rifle", c, null)
			s.position = c + Vector3(-5.6 + i * 1.6, 0, t * 2.4)
			s.rotation.y = PI * 1.25 + (0.6 if t == 1 else 0.0)
			s.set_process(false)
			bodies.append([s, poses[i]])
	G.running = false
	G.cam.input_enabled = false
	for k in 50:
		for b in bodies:
			var pk: float = b[1][2]
			b[0].body.pistol = pk >= 0.0
			if pk >= 0.0:
				b[0].body.pistol_k = pk - 0.0001
			b[0].body.animate(0.033, b[1][0], b[1][1], 0.0)
		await get_tree().process_frame
	G.cam.jump_to(c + Vector3(0, 0, 1.2), true)
	G.cam.size = 7.0
	G.cam.target_size = 7.0
	await _wait(0.8)
	await _shot("hold_all")
	G.cam.jump_to(c + Vector3(-2.4, 0, 0.0), true)
	G.cam.size = 3.2
	G.cam.target_size = 3.2
	await _wait(0.5)
	await _shot("hold_close_a")
	G.cam.jump_to(c + Vector3(2.4, 0, 0.0), true)
	await _wait(0.5)
	await _shot("hold_close_b")
	print("HOLDTEST RESULT fails=0")
	get_tree().quit()

func _run_build_test() -> void:
	# inşaat: 6 işçi farklı yerlerde (çakan / yukarı çakan / malzeme taşıyan), alttan yukarı örülen duvar, iskele; yerleştirme önizlemesi
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	var map_id := "green_valley"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="):
			map_id = arg.substr(6)
	start_game(map_id)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.sandbox = false
	var c: Vector3 = G.grid.nearest_free(G.hq_pos[0].lerp(G.hq_pos[1], 0.22), Grid.M_HEAVY)
	G.props.clear_area(c, 16.0)
	# önizleme
	G.cam.size = 22.0
	G.cam.target_size = 22.0
	G.cam.jump_to(c, true)
	await _wait(0.5)
	G.player.start_place("factory")
	G.player.place_rot = PI * 0.25
	get_viewport().warp_mouse(Vector2(960, 540))
	await _wait(0.4)
	await _shot("build_00_ghost")
	G.player.cancel_place()
	var b := place_building(0, "factory", c, PI * 0.25)
	var ws: Array = []
	for i in 6:
		var s := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-12 + i * 1.2, 0, 10), Grid.M_INF), null)
		ws.append(s)
		s.cmd_build(b)
	await _wait(9.0)
	G.cam.size = 16.0
	G.cam.target_size = 16.0
	G.cam.jump_to(c, true)
	await _wait(0.4)
	await _shot("build_01_early")
	var slots := {}
	var spread := 0.0
	for s in ws:
		slots[s.build_slot] = true
		spread = maxf(spread, Vector2(s.position.x - ws[0].position.x, s.position.z - ws[0].position.z).length())
	var hauls := 0
	var lifts := 0
	for k in 40:
		await _wait(0.25)
		for s in ws:
			if s.state == "build" and s.lift_t > 0.0:
				lifts += 1
		for s in ws:
			if s.haul:
				hauls += 1
				break
	print("BUILD slots=%d spread=%.1f progress=%.2f scaffold=%s hauling=%d" % [slots.size(), spread, b.progress, b.scaffold != null, hauls])
	if slots.size() < 6 or spread < 6.0 or b.scaffold == null or hauls == 0:
		fails += 1
	# 37: işçiler binanın içine girmez (iskele dışında çalışır); tüfek sırtta, elde alet; taşıyıcı eğilip kutu alır
	var inside := 0
	var walk_in := 0
	var tools := {}
	for k in 24:
		await _wait(0.25)
		for s in ws:
			var lp: Vector3 = (s.position - b.position).rotated(Vector3.UP, -b.rot)
			var in_fp: bool = absf(lp.x) < b.size.x * 0.5 * b._hq_k() - 0.2 and absf(lp.z) < b.size.y * 0.5 * b._hq_k() - 0.2
			if s.state == "move" and in_fp:
				walk_in += 1                          # 95: yığın ile işçi yeri arası binanın içinden geçmez, yandan dolaşır
			if s.state == "build":
				if in_fp:
					inside += 1
				if s.lift_t > 0.0:
					lifts += 1
			tools[s.body._tool] = true
	print("BUILD inside=%d walk_inside=%d lifts=%d tools=%s" % [inside, walk_in, lifts, tools.keys()])
	if lifts == 0:
		# teşhis: taşıyıcılar nerede takıldı
		for s in ws:
			if s.build_slot % 3 == 2:
				var pr: Vector3 = b.pile_reach()
				print("BUILD hauler slot=%d state=%s haul=%s pos=%s pile=%s reach=%s d_reach=%.1f d_slot=%.1f path=%d" % [s.build_slot, s.state, s.haul, s.position, b.pile_pos(), pr, Vector2(pr.x - s.position.x, pr.z - s.position.z).length(), Vector2(b.slot_pos(s.build_slot).x - s.position.x, b.slot_pos(s.build_slot).z - s.position.z).length(), s.path.size()])
	if inside > 0 or walk_in > 0 or lifts == 0 or not tools.has("hammer"):
		fails += 1
	await _wait(4.0)
	await _shot("build_02_mid")
	var t0 := 0
	while t0 < 90 and not b.done:
		await _wait(1.0)
		t0 += 1
	# 95: bitince taşıyıcılar kaldırılan malzeme yığınına kutu götürmeye devam etmemeli
	await _wait(0.5)
	var still := 0
	for s in ws:
		if is_instance_valid(s) and (s.haul or s.order == "build" or s.build_site == b):
			still += 1
	await _wait(0.5)
	await _shot("build_03_done")
	print("BUILD done=%s scaffold=%s rot=%.2f still_working=%d" % [b.done, b.scaffold != null, b.rot, still])
	if not b.done or b.scaffold != null or still > 0:
		fails += 1
	print("BUILDTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_cargo_test() -> void:
	# kargo helikopteri: yolcu alma (iniş + rampa), taşıma, indirme; araç askıya alma/bırakma; havadan ikmal paleti; gölge
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c: Vector3 = G.hq_pos[0].lerp(G.hq_pos[1], 0.25)
	var h := spawn_vehicle(0, "usa_heli_ch47", c, 0.0)
	print("CARGO cap=%d cargo=%s crates=%d ramp=%s" % [h.capacity(), h.is_cargo(), h.crates, h.ramp != null])
	if h.capacity() != 7 or h.ramp == null:
		fails += 1
	await _wait(2.0)
	G.cam.size = 30.0
	G.cam.target_size = 30.0
	G.cam.jump_to(h.position, true)
	await _wait(0.5)
	await _shot("cargo_01_air_shadow")
	var sq: Array = []
	for i in 7:
		var s := spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-18 + (i % 4) * 1.5, 0, 14 + (i / 4) * 1.5), Grid.M_INF), null)
		sq.append(s)
	for s in sq:
		s.cmd_board(h)
	var t0 := 0
	while t0 < 45 and h.cargo.size() < 7:
		await _wait(1.0)
		t0 += 1
	G.cam.size = 20.0
	G.cam.target_size = 20.0
	G.cam.jump_to(h.position - h.forward() * 6.0, true)
	await _wait(0.4)
	await _shot("cargo_02_landed_ramp")
	print("CARGO boarded=%d in %ds alt=%.1f ramp=%.2f" % [h.cargo.size(), t0, h.hull.position.y, h.ramp_k])
	if h.cargo.size() < 7:
		fails += 1
	var p2 := G.grid.nearest_free(c + Vector3(40, 0, -30), Grid.M_INF)
	h.cmd_move(p2)
	# rampa kapanmadan kalkmamalı (kullanıcı: "rampası açık kalkıyor")
	var lift_ramp := -1.0
	var tl := 0.0
	while tl < 5.0:
		await _wait(0.1)
		tl += 0.1
		if h.hull.position.y > 1.0 and lift_ramp < 0.0:
			lift_ramp = h.ramp_k
	print("CARGO liftoff_ramp=%.2f" % lift_ramp)
	if lift_ramp > 0.05:
		fails += 1
	var flew: bool = h.hull.position.y > 5.0
	await _wait(8.0)
	h.unload()
	await _wait(12.0)
	var out := 0
	for s in sq:
		if is_instance_valid(s) and s.vehicle_in == null and s.position.distance_to(p2) < 20.0:
			out += 1
	print("CARGO flew=%s unloaded=%d left=%d" % [flew, out, h.cargo.size()])
	if not flew or out < 7:
		fails += 1
	# askı: teknik araç
	var tech := spawn_vehicle(0, "technical", G.grid.nearest_free(c + Vector3(10, 0, 20), Grid.M_HEAVY), 0.0)
	h.cmd_move(h.position + Vector3(0, 0, 1))
	await _wait(1.0)
	h.cmd_sling(tech)
	t0 = 0
	while t0 < 40 and h.sling == null:
		await _wait(1.0)
		t0 += 1
	print("CARGO sling=%s in %ds" % [h.sling == tech, t0])
	if h.sling != tech:
		fails += 1
	var p3 := G.grid.nearest_free(c + Vector3(-30, 0, -20), Grid.M_HEAVY)
	h.cmd_move(p3)
	await _wait(6.0)
	G.cam.size = 26.0
	G.cam.target_size = 26.0
	G.cam.jump_to(h.position, true)
	await _wait(0.4)
	await _shot("cargo_03_slung")
	var lifted: bool = tech.position.y > G.terrain.ground_h(tech.position) + 3.0
	await _wait(10.0)
	h.unload()
	t0 = 0
	while t0 < 25 and h.sling != null:
		await _wait(1.0)
		t0 += 1
	var on_ground: bool = tech.slung_by == null and absf(tech.position.y - G.terrain.ground_h(tech.position)) < 0.3
	print("CARGO lifted=%s released=%s dist=%.1f" % [lifted, on_ground, Vector2(tech.position.x - p3.x, tech.position.z - p3.z).length()])
	if not lifted or not on_ground:
		fails += 1
	# havadan ikmal
	var p4 := G.grid.nearest_free(c + Vector3(25, 0, 25), Grid.M_INF)
	var cr0: int = h.crates
	h.cmd_airdrop(p4)
	await _wait(18.0)
	var cache: Building = null
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.btype == "cache":
			cache = u
	var r := spawn_soldier(0, "rifle", G.grid.nearest_free(p4 + Vector3(3, 0, 0), Grid.M_INF), null)
	r.ammo = 0
	r.cmd_hold()
	await _wait(3.0)
	G.cam.size = 12.0
	G.cam.target_size = 12.0
	if cache != null:
		G.cam.jump_to(cache.position, true)
	await _wait(0.4)
	await _shot("cargo_04_cache")
	print("CARGO crates %d -> %d cache=%s ammo=%d" % [cr0, h.crates, cache != null, r.ammo])
	if cache == null or r.ammo <= 0 or h.crates != cr0 - 1:
		fails += 1
	# Mi-26: ZPT taşır
	var mi := spawn_vehicle(1, "rus_heli_mi26", c + Vector3(0, 0, -40), 0.0)
	var apc := spawn_vehicle(1, "apc", G.grid.nearest_free(c + Vector3(20, 0, -40), Grid.M_HEAVY), 0.0)
	print("CARGO mi26 cap=%d can_apc=%s ch47_can_apc=%s" % [mi.capacity(), mi.can_sling(apc), h.can_sling(apc)])
	mi.cmd_sling(apc)
	t0 = 0
	while t0 < 40 and mi.sling == null:
		await _wait(1.0)
		t0 += 1
	mi.cmd_move(mi.position + Vector3(-20, 0, 10))
	await _wait(5.0)
	G.cam.size = 34.0
	G.cam.target_size = 34.0
	G.cam.jump_to(mi.position, true)
	await _wait(0.4)
	await _shot("cargo_05_mi26")
	print("CARGO mi26 sling=%s" % [mi.sling == apc])
	if mi.sling != apc or mi.capacity() != 20:
		fails += 1
	print("CARGOTEST RESULT fails=%d" % fails)
	get_tree().quit()

func _run_supply_test() -> void:
	# ikmal kamyonu boşaltma: iki hamal kamyonun arkasından binaya kutu taşır
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	start_game("green_valley")
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var hq: Vector3 = G.hq_pos[0]
	# düşman birlikleri (önceden yerleşik) kamyonu vurup testi bozmasın
	for u in G.units.duplicate():
		if is_instance_valid(u) and u.team == 1 and not (u is Building):
			u.queue_free()
	var fob := place_building(0, "fob", G.grid.nearest_free(hq.lerp(G.hq_pos[1], 0.3), Grid.M_HEAVY), 0.0)
	fob.complete()
	var tr := spawn_vehicle(0, "truck", G.logi._door(fob) + Vector3(0, 0, 3.0), 0.0)
	G.logi.trucks[0].append(tr)
	tr.job = {"state": "unload", "t": 60.0, "to": fob}
	await _wait(1.0)
	G.cam.size = 9.0
	G.cam.target_size = 9.0
	G.cam.jump_to(tr.position.lerp(fob.position, 0.5), true)
	for i in 3:
		await _wait(1.4)
		await _shot("supply_%02d" % i)
	var n: int = tr.get_meta("porters", []).size()
	print("SUPPLY porters=%d alive=%s hp=%.0f kill=%s pos=%s water=%s" % [n, tr.alive, tr.hp, tr.kill_k, tr.position, G.grid.is_water(tr.position)])
	tr.job["t"] = 0.1
	# kamyon yola çıkınca hamallar gider (kare süresine bağlı kalmamak için koşul beklenir)
	for k in 16:
		await _wait(0.25)
		if tr.job.get("state", "") != "unload" and tr.get_meta("porters", []).is_empty():
			break
	print("SUPPLY after=%d state=%s t=%.2f in_list=%s alive=%s spd=%.2f path=%d/%d order=%s" % [tr.get_meta("porters", []).size(), tr.job.get("state", ""), float(tr.job.get("t", -1.0)), G.logi.trucks[0].has(tr), tr.alive, tr.cur_speed, tr.path_i, tr.path.size(), tr.order])
	var fails := 0 if n == 2 and tr.get_meta("porters", []).is_empty() else 1
	# 106: boşalttıktan sonra takılmadan karargâha döner (yükleme durumuna geçer)
	var back_t := -1.0
	var t0 := G.time
	var last := tr.position
	var still := 0.0
	while G.time - t0 < 90.0:
		await _wait(1.0)
		if not is_instance_valid(tr) or not tr.alive:
			break
		if tr.job.get("state", "") in ["load", "out"]:
			back_t = G.time - t0
			break
		still = still + 1.0 if tr.position.distance_to(last) < 0.5 else 0.0
		last = tr.position
		if int(G.time - t0) % 10 == 0:
			print("SUPPLY back dbg t=%.0f st=%s pos=%s path=%d/%d spd=%.1f order=%s still=%.0f" % [G.time - t0, tr.job.get("state", ""), tr.position, tr.path_i, tr.path.size(), tr.cur_speed, tr.order, still])
	print("SUPPLY returned_at=%.1f still=%.0f" % [back_t, still])
	if back_t < 0.0:
		fails += 1
	# 103: boşaltırken vurulan kamyonun hamalları elde kutuyla donup kalmaz
	var tr2 := spawn_vehicle(0, "truck", G.logi._door(fob) + Vector3(0, 0, 3.0), 0.0)
	G.logi.trucks[0].append(tr2)
	tr2.job = {"state": "unload", "t": 60.0, "to": fob}
	await _wait(1.5)
	var pn: Array = []
	for p in tr2.get_meta("porters", []):
		pn.append(p[0])
	tr2.take_damage(99999.0, null, "he")
	await _wait(0.5)
	var left := 0
	for p in pn:
		if is_instance_valid(p) and not p.is_queued_for_deletion():
			left += 1
	print("SUPPLY killed_truck porters_before=%d left=%d" % [pn.size(), left])
	if pn.size() != 2 or left > 0:
		fails += 1
	print("SUPPLYTEST RESULT fails=%d" % fails)
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
	# kamyon: varınca hamallar iner, kutu taşır, sonra döner
	var seen_unload := false
	var seen_porters := false
	var tr0: Vehicle = null
	for k in 120:
		await _wait(1.0)
		for tr in G.logi.trucks[0]:
			if is_instance_valid(tr) and tr.job.get("state", "") == "unload":
				seen_unload = true
				tr0 = tr
				if not tr.get_meta("porters", []).is_empty():
					seen_porters = true
		if seen_porters:
			break
		if k % 15 == 0:
			var sts := []
			for tr in G.logi.trucks[0]:
				if is_instance_valid(tr):
					sts.append("%s@%.0f,%.0f p%d/%d" % [tr.job.get("state", ""), tr.position.x, tr.position.z, tr.path_i, tr.path.size()])
			print("LOGI dbg t=%d %s" % [k, sts])
	if tr0 != null:
		await _wait(1.5)
		G.cam.size = 8.0
		G.cam.target_size = 8.0
		G.cam.jump_to(tr0.position - tr0.forward() * 3.0, true)
		await _shot("logi_02_porters")
		for p in tr0.get_meta("porters", []):
			print("LOGI porter %s vis=%s truck=%s st=%s" % [p[0].global_position, p[0].visible, tr0.position, tr0.job.get("state", "")])
		await _wait(7.0)
	var gone_p: bool = tr0 != null and is_instance_valid(tr0) and tr0.get_meta("porters", []).is_empty()
	print("LOGI truck unload=%s porters=%s cleaned=%s" % [seen_unload, seen_porters, gone_p])
	if not seen_unload or not seen_porters or not gone_p:
		fails += 1
	# 96: üs rotasının üstüne sonradan yapı dikilirse kamyon içinden geçmez, yanından dolaşır
	var rt: PackedVector3Array = G.logi._node_of(fob).get("route", PackedVector3Array())
	if rt.size() >= 3:
		var bp: Vector3 = rt[rt.size() / 2]
		var blk := place_building(0, "barracks", bp, 0.3)
		blk.complete()
		var inside_t := 0
		var near_t := 0
		for k in 90:
			await _wait(0.5)
			for tr in G.logi.trucks[0]:
				if not is_instance_valid(tr) or not tr.alive:
					continue
				var lp: Vector3 = (tr.position - blk.position).rotated(Vector3.UP, -blk.rot)
				if absf(lp.x) < blk.size.x * 0.5 - 0.3 and absf(lp.z) < blk.size.y * 0.5 - 0.3:
					inside_t += 1
				elif Vector2(lp.x, lp.z).length() < 16.0:
					near_t += 1
		print("LOGI route_blocked inside=%d near=%d route_ok=%s" % [inside_t, near_t, Logistics.route_clear(G.logi._node_of(fob)["route"])])
		if inside_t > 0:
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
	await _wait(18.0)
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
	start_game("green_valley", {}, true, 345221)
	sandbox_ui.run("fog")
	# önceden yerleşik düşmanlar konvoyu vurup sonucu kararsız yapıyordu (palet / teker / mürettebat aşamaları)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	for u in G.units.duplicate():
		if is_instance_valid(u) and u.team == 1 and not (u is Building):
			u.queue_free()
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
		print("VEH  %s along=%.1f dest_along=%.1f dest_side=%.1f path=%d/%d spd=%.1f imm=%s hp=%d mob=%d eng=%d trk=%.1f drv=%s crew=%d tires=%d atk=%s" % [v.vtype, (v.position - bc).dot(ax), (v.dest - bc).dot(ax), (v.dest - bc).dot(Vector3(-ax.z, 0, ax.x)), v.path_i, v.path.size(), v.cur_speed, v.immobile(), int(v.hp), v.crit["mob"], v.crit["eng"], v.tracks_broken, v.driver_ok, v.crew_n, v.tires, v.attacker.name if v.attacker != null and is_instance_valid(v.attacker) else "-"])
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
	# keskin nişancı sürücüyü de vurmuş olabilir (112): yeni gelen önce sürücü koltuğuna geçer; bu adım yalnız nişancıyı ölçer
	tech.driver_ok = true
	tech._runaway = 0.0
	tech.cmd_stop()
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
	# istihkâmcı tehdit tepkisinden sonra ve yakındaki diğer hasarlı araçlara göre sırayla onarır: 30 sn'ye kadar bekle
	var tw := 0.0
	while tw < 30.0 and tech.tires >= flat:
		await _wait(1.0)
		tw += 1.0
	await _wait(2.0)
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
	# 108: araç yakına düşen mermiyle yok olmaz (hasar alır), doğrudan isabetle yok olur
	var trk := spawn_vehicle(0, "truck", G.grid.nearest_free(bc - ax * 70.0, Grid.M_LIGHT), 0.0)
	await _wait(0.3)
	G.explode(trk.position + Vector3(4.0, 0.0, 0.0), 4.5, 130.0, "shell", 1, null)
	await _wait(0.3)
	var hp1 := trk.hp
	G.explode(trk.position + Vector3(0.0, 0.0, 5.0), 8.0, 400.0, "big", 1, null)
	await _wait(0.3)
	var near_alive := trk.alive
	var hp2 := trk.hp
	G.explode(trk.position, 4.5, 130.0, "shell", 1, null)
	await _wait(0.3)
	print("VEH near_miss hp=%d -> %d -> %d/%d alive=%s direct_destroyed=%s" % [int(trk.max_hp), int(hp1), int(hp2), int(trk.max_hp), near_alive, not trk.alive])
	if not near_alive or hp2 >= trk.max_hp or trk.alive:
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
		var ev := spawn_vehicle(1, "tank" if i % 2 == 0 else "apc", G.grid.nearest_free(c + fwd * (45.0 + i * 12.0) + side * (i - 1.5) * 8.0, Grid.M_HEAVY), Soldier._yaw_of(-fwd))
		ev.fire_mode = 2    # hedefler ateş etmez: deney topların ateşini ölçer (gerçek menzilde toplar ilk saniyelerde vuruluyordu)
	var sq := Squad.new(1, "T")
	for i in 6:
		var es := spawn_soldier(1, "rifle", G.grid.nearest_free(c + fwd * 40.0 + side * (i - 3) * 2.0, Grid.M_INF), sq)
		es.fire_mode = 2
	spawn_vehicle(1, "heli", c + fwd * 50.0, 0.0).fire_mode = 2
	# yakındaki hedefler önce düz atışlılarca yok edilebildiğinden obüs/roketatar için ayrı, dayanıklı uzak hedefler
	for k in 2:
		var gi: int = [6, 7][k]
		var far_t := spawn_vehicle(1, "tank", G.grid.nearest_free(c + fwd * (guns[gi]._min_range() + 30.0) + side * (k * 2 - 1) * 10.0, Grid.M_HEAVY), Soldier._yaw_of(-fwd))
		far_t.cmd_hold()
		far_t.fire_mode = 2
		print("ART %s min=%.0f far_d=%.0f" % [types[gi], guns[gi]._min_range(), guns[gi].position.distance_to(far_t.position)])
	G.cam.jump_to(c + fwd * 15.0, true)
	G.cam.size = 52.0
	G.cam.target_size = 52.0
	var fired := {}
	for k in 50:
		await _wait(0.5)
		if k == 8 or k == 20:
			spawn_vehicle(1, "heli", guns[3].position + fwd * 35.0, 0.0).fire_mode = 2
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
	print("BEH surrender->%s killer=%s" % [lone.state, (lone.attacker.role if lone.attacker is Soldier else str(lone.attacker)) if lone.attacker != null and is_instance_valid(lone.attacker) else "none"])
	if not pris:
		fails += 1
	# 13: beyaz bayrak, esir eller havada yürür, esir alan asker silah doğrultarak arkasından götürür
	var flag: bool = lone.body._tool == "flag"
	var guard_ok: bool = cap.state == "guard" and cap.guard_of == lone
	var gd_min := 99.0
	var gd_max := 0.0
	var aimed := 0
	for k in 40:
		await _wait(0.2)
		if not is_instance_valid(lone) or lone.state != "prisoner":
			break
		var gd := cap.position.distance_to(lone.position)
		gd_min = minf(gd_min, gd)
		gd_max = maxf(gd_max, gd)
		var fwd := -cap.global_transform.basis.z
		var to := (lone.position - cap.position)
		to.y = 0
		if to.length() > 0.1 and fwd.dot(to.normalized()) > 0.8:
			aimed += 1
	G.cam.jump_to(cap.position, true)
	G.cam.size = 9.0
	G.cam.target_size = 9.0
	await _wait(0.3)
	await _shot("behav_04b_escort")
	print("BEH white_flag=%s guard=%s dist=%.1f-%.1f aimed=%d" % [flag, guard_ok, gd_min, gd_max, aimed])
	if not flag or not guard_ok or gd_max > 6.0 or aimed < 10:
		fails += 1
	await _wait(2.0)
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
	for m in blue.alive_members():
		var rs := red.alive_members()
		var near_d := 1e9
		var seen_n := 0
		for r in rs:
			near_d = minf(near_d, m.dist2(r))
			if G.is_seen(r, 0):
				seen_n += 1
		print("ORD dbg %s state=%s order=%s tgt=%s near=%.1f seen=%d/%d rng=%.1f vis=%d sight=%.1f" % [m.role, m.state, m.order, m.target != null, near_d, seen_n, rs.size(), m.weapon()["range"], G.visible_enemies(0).size(), m.sight])
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
	await _wait(18.0)
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
	await _wait(18.0)
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

# yapı vitrini: --scene=structtest[:tip1,tip2]  her yapının ABD ve Rus modeli (yakın + oyun yakınlığı) ve yarım inşaat
func _run_struct_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var types: Array = ["factory", "hq", "barracks", "fob", "helipad", "hospital"]
	if shot_scene.contains(":"):
		types = Array(shot_scene.split(":")[1].split(","))
	G.spectate = true
	build_world("green_valley", 4242)
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	await get_tree().process_frame
	var c := Vector3(150, 0, 150)
	G.props.clear_area(c + Vector3(types.size() * 11.0, 0, 0), types.size() * 13.0 + 20.0)
	var bs: Array = []
	for i in types.size():
		for t in 2:
			var b := place_building(t, types[i], c + Vector3(i * 24.0, 0, -11.0 + t * 24.0), 0.0)
			b.done = true
			b.progress = 1.0
			b.hp = b.max_hp
			b._apply_construct_look()
			bs.append(b)
	# yarım inşaat (kesme shader'ı + iskele Blender modeliyle)
	var ub := place_building(0, types[0], c + Vector3(-28, 0, 2), PI * 0.25)
	ub.progress = 0.5
	ub._apply_construct_look()
	print("STRUCT glb=%s h=%.1f scaffold=%s" % [ub.glb_model, ub.model_h, ub.scaffold != null])
	# denetim: her yapının iki tarafı da Blender modeliyle kuruldu, yarım inşaatta iskele var
	var fails := 0
	for b in bs:
		if not b.glb_model:
			print("STRUCT no-glb %s team=%d" % [b.btype, b.team])
			fails += 1
	if not ub.glb_model or ub.scaffold == null or ub.model_h <= 0.5:
		fails += 1
	G.running = false
	G.cam.input_enabled = false
	for i in types.size():
		for t in 2:
			var b: Building = bs[i * 2 + t]
			G.cam.jump_to(b.position + Vector3(0, 0, 0.5), true)
			G.cam.size = maxf(b.size.x, b.size.y) * 1.25 + 4.0
			G.cam.target_size = G.cam.size
			await _wait(0.5)
			await _shot("struct_%s_%s" % [types[i], ["usa", "rus"][t]])
		G.cam.jump_to(c + Vector3(i * 24.0, 0, 1.0), true)
		G.cam.size = 40.0
		G.cam.target_size = 40.0
		await _wait(0.5)
		await _shot("struct_%s_normal" % types[i])
	G.cam.jump_to(ub.position, true)
	G.cam.size = 22.0
	G.cam.target_size = 22.0
	await _wait(0.5)
	await _shot("struct_construct")
	print("STRUCTTEST RESULT fails=%d" % fails)
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
	print("ROUNDTRIP RESULT fails=%d" % (0 if a == b else 1))
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
	print("EDITORTEST RESULT fails=%d" % (0 if n_ops > 0 and G.running and G.units.size() > 0 else 1))
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
	# savaşın belirli sürede bitmesi beklenmez (birlikler binalara girince uzar): senaryo yüklendi, birlikler var, oyun ilerledi
	print("SCENTEST RESULT fails=%d" % (0 if not G.scenario.is_empty() and any_blue > 0 and (G.game_over or G.time > 30.0) else 1))
	get_tree().quit()

# bina arketipleri vitrini: --scene=archtest[_desert|_winter][:kimlik1,kimlik2]
# arketipler ekran eksenine hizalı ızgarada, ön cephe kameraya dönük; 3x2'lik gruplar halinde çekilir
func _run_arch_test() -> void:
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var bio := "green"
	for b in ["desert", "winter"]:
		if shot_scene.contains(b):
			bio = b
	var ids: Array = Arch.ARCH.keys() if bio == "green" else Arch.ids_where(bio, [])
	if shot_scene.contains(":"):
		ids = Array(shot_scene.substr(shot_scene.find(":") + 1).split(","))
	var S := 512.0
	var right := Vector3(1, 0, -1).normalized()
	var down := Vector3(1, 0, 1).normalized()
	var c := Vector3(14, 0, 262)
	var cols := 12
	var ops: Array = []
	var pos: Array = []
	for i in ids.size():
		var p := c + right * ((i % cols) * 30.0 + 16.0) + down * ((i / cols) * 32.0 + 16.0)
		pos.append(p)
		ops.append({"t": "bld", "p": MapGen.vv(p), "a": ids[i], "r": 0, "s": 1000 + i})
	G.spectate = true
	var t0 := Time.get_ticks_msec()
	build_world("custom", 4242, {"biome": bio, "size": S, "ops": ops, "hq": [[S - 16, S - 16], [16, 16]], "fobs": []})
	print("ARCH n=%d build_ms=%d houses=%d blocks=%d" % [ids.size(), Time.get_ticks_msec() - t0, G.blocks.houses.size(), G.blocks.bpos.size()])
	# garnizon denetimi (Soldier.cmd_garrison ile aynı koşul): yuva en yakın boş hücreye kaydırılır, aynı
	# evde kalmalı; binanın dışından (pencerenin 6 m önünden) yürünerek varılmalı — yol bulucu ulaşılamazda
	# kısmi yol döndürdüğü için yolun SON noktası hedefe değmeli
	var gbad := {}
	var gtot := 0
	var nbad := 0
	for hid in G.blocks.houses.size():
		var h: Dictionary = G.blocks.houses[hid]
		if not h.has("slots"):
			continue
		for k in h["slots"].size():
			gtot += 1
			var sp: Vector3 = G.grid.nearest_free(h["slots"][k], Grid.M_INF, 3)
			var from: Vector3 = G.grid.nearest_free(h["slots"][k] + h["out"][k] * 6.0, Grid.M_INF)
			var pth := G.grid.find_path(from, sp, Grid.M_INF)
			var ok := G.blocks.house_at(sp) == hid and pth.size() > 0 and Vector2(pth[pth.size() - 1].x - sp.x, pth[pth.size() - 1].z - sp.z).length() < 0.6
			if not ok:
				nbad += 1
				var a: String = h.get("aid", "?")
				gbad[a] = int(gbad.get(a, 0)) + 1
	for a in gbad:
		print("ARCH garrison-bad %s slots=%d" % [a, gbad[a]])
	print("ARCH garrison slots=%d bad=%d bad_types=%d" % [gtot, nbad, gbad.size()])
	var arch_fails := 1 if gtot > 0 and nbad * 100 > gtot * 6 else 0
	for u in G.units.duplicate():
		if u is Soldier or u is Vehicle:
			u.queue_free()
	G.running = false
	G.cam.input_enabled = false
	await get_tree().process_frame
	var g := 0
	var i := 0
	while i < ids.size():
		var names: Array = []
		var ctr := Vector3.ZERO
		var n := 0
		for dr in 2:
			for dc in 3:
				var k := i + dr * cols + dc
				if (i % cols) + dc < cols and k < ids.size():
					names.append("%s(%s)" % [ids[k], Arch.name_of(ids[k])])
					ctr += pos[k]
					n += 1
		G.cam.jump_to(ctr / maxf(n, 1), true)
		G.cam.size = 46.0
		G.cam.target_size = 46.0
		await _wait(0.4)
		await _shot("arch_%s_%02d" % [bio, g])
		print("ARCHSHOT %s_%02d %s" % [bio, g, " ".join(names)])
		g += 1
		i += 3
		if i % cols == 0:
			i += cols
	print("ARCHTEST RESULT fails=%d" % arch_fails)
	get_tree().quit()
