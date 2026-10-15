class_name Weather extends Node3D
# Hava durumu ve gece.
#  rain      : görüş %80, tekerli araçlar çamurda yavaş
#  storm     : sağanak; nehir taşar (kıyı hücreleri geçilmez sel olur), görüş %65
#  sandstorm : hava araçları ve dronlar uçamaz, görüş %45
#  snowstorm : görüş %50, askerler üşür (yavaşlar, isabet düşer, sonunda donar);
#              üs/ileri üs/hastane yakınında ve araç içinde ısınırlar
#  night     : ayrı bayrak; görüş %60, ateş eden birim açığa çıkar
# "dynamic": biyoma uygun hava 3-4 dakikada bir değişir.

const KINDS := ["clear", "rain", "storm", "sandstorm", "snowstorm"]
const NAME := {"clear": "AÇIK HAVA", "rain": "YAĞMUR", "storm": "SAĞANAK", "sandstorm": "KUM FIRTINASI", "snowstorm": "KAR FIRTINASI", "dynamic": "DEĞİŞKEN"}
const FLOOD_LEVEL := -0.12

var kind := "clear"
var night := false
var dynamic := false
var next_t := 0.0
var flooded := false
var parts: GPUParticles3D
var pmat: ParticleProcessMaterial
var _quad: QuadMesh
var _qmat: StandardMaterial3D
var _base := {}
var _soft: GradientTexture2D

func setup(k: String, is_night: bool) -> void:
	night = is_night
	_base = {"sun_e": G.main.sun.light_energy, "amb": G.main.env.ambient_light_energy, "amb_c": G.main.env.ambient_light_color,
		"bg": G.main.env.background_color, "exp": G.main.env.tonemap_exposure, "sun_c": G.main.sun.light_color}
	_make_particles()
	if k == "dynamic":
		dynamic = true
		k = _pick()
		next_t = randf_range(180.0, 240.0)
	set_kind(k)

func _pick() -> String:
	match G.map_kind:
		"desert":
			return ["clear", "sandstorm", "clear"][randi() % 3]
		"winter":
			return ["clear", "snowstorm"][randi() % 2]
		_:
			return ["clear", "rain", "storm"][randi() % 3]

# ------------------------------------------------------------ oyun etkileri
func sight_mult() -> float:
	var m: float = {"clear": 1.0, "rain": 0.8, "storm": 0.65, "sandstorm": 0.45, "snowstorm": 0.5}[kind]
	if night:
		m *= 0.6
	return m

func no_air() -> bool:
	return kind == "sandstorm"

func mud() -> float:
	return 0.82 if kind in ["rain", "storm"] else 1.0

func cold() -> bool:
	return kind == "snowstorm"

func set_kind(k: String) -> void:
	kind = k
	var flood := k == "storm"
	if flood != flooded:
		_flood(flood)
	_visuals()
	if G.running and k != "clear":
		G.say("%s: %s" % [I18n.s("HAVA DURUMU"), I18n.s(NAME[k])], G.cam.focus, G.player_team)

# sağanakta nehir taşar: kıyıdaki alçak hücreler geçilmez olur
func _flood(on: bool) -> void:
	flooded = on
	if not G.terrain.has_water:
		return
	var cells: Array = []
	for z in Grid.N:
		for x in Grid.N:
			var i := z * Grid.N + x
			if on:
				if G.grid.water[i] == 0 and G.terrain.ground_h(Vector3((x + 0.5) * Grid.CS, 0, (z + 0.5) * Grid.CS)) < FLOOD_LEVEL:
					G.grid.water[i] = 2
					cells.append(i)
			elif G.grid.water[i] == 2:
				G.grid.water[i] = 0
				cells.append(i)
	G.grid.refresh(cells)
	G.grid.flush_nav()
	if G.terrain.water:
		var tw := create_tween()
		tw.tween_property(G.terrain.water, "position:y", Terrain.WATER_Y + (0.45 if on else 0.0), 6.0)
	if on:
		G.say(I18n.s("NEHİR TAŞTI! Kıyılar geçilmez."), G.cam.focus, G.player_team)
		# selde kalanları kenara al
		for u in G.units:
			if is_instance_valid(u) and u.alive and (u is Soldier or (u is Vehicle and not u.is_air())) and G.grid.is_water(u.position):
				u.position = G.grid.nearest_free(u.position, Grid.M_INF if u is Soldier else u.nav_mode, 40)

func _process(dt: float) -> void:
	if parts:
		parts.global_position = G.cam.focus + Vector3(0, 0, 0)
	if not G.running or dt <= 0.0:
		return
	if dynamic:
		next_t -= dt
		if next_t <= 0.0:
			next_t = randf_range(180.0, 240.0)
			set_kind(_pick())
	if cold():
		_cold_tick(dt)
	elif int(G.time * 2.0) % 4 == 0:
		_warm_all(dt)

func _warm_spot(p: Vector3, team: int) -> bool:
	for u in G.friends_near(p, 22.0, team):
		if u is Building and u.done and (u.is_base() or u.btype == "hospital" or u.btype == "barracks"):
			return true
	return false

func _cold_tick(dt: float) -> void:
	for u in G.units:
		if not is_instance_valid(u) or not (u is Soldier) or not u.alive or u.state in ["hospital", "prisoner"]:
			continue
		var warm: bool = u.state == "aboard" or _warm_spot(u.position, u.team)
		if warm:
			if u.cold > 0.0:
				u.cold = maxf(0.0, u.cold - dt * 8.0)
		else:
			u.cold = minf(100.0, u.cold + dt * (0.55 if u.vel.length() > 1.0 else 0.85))
			if u.cold >= 90.0 and not u.incapacitated():
				u.hp -= dt * 0.8
				if randf() < dt * 0.05:
					u.say("DONUYORUM!")
				if u.hp <= 0.0:
					u.take_damage(1.0, null, "cold")
			elif u.cold >= 60.0 and randf() < dt * 0.02:
				u.say("ÇOK SOĞUK!")

func _warm_all(dt: float) -> void:
	for u in G.units:
		if is_instance_valid(u) and u is Soldier and u.cold > 0.0:
			u.cold = maxf(0.0, u.cold - dt * 6.0)

func restore() -> void:
	if night or kind != "clear":
		night = false
		set_kind_silent("clear")
	if flooded:
		_flood(false)

func set_kind_silent(k: String) -> void:
	kind = k
	_visuals()

# ------------------------------------------------------------ görsel
func _make_particles() -> void:
	parts = GPUParticles3D.new()
	parts.amount = 9000
	parts.lifetime = 1.6
	parts.preprocess = 2.0
	parts.visibility_aabb = AABB(Vector3(-120, -30, -120), Vector3(240, 90, 240))
	parts.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	pmat = ParticleProcessMaterial.new()
	pmat.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pmat.emission_box_extents = Vector3(90, 1, 90)
	parts.process_material = pmat
	_quad = QuadMesh.new()
	_qmat = StandardMaterial3D.new()
	_qmat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_qmat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_qmat.vertex_color_use_as_albedo = true
	_qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
	_quad.material = _qmat
	parts.draw_pass_1 = _quad
	_soft = GradientTexture2D.new()
	_soft.fill = GradientTexture2D.FILL_RADIAL
	_soft.fill_from = Vector2(0.5, 0.5)
	_soft.fill_to = Vector2(0.5, 0.0)
	var gr := Gradient.new()
	gr.set_color(0, Color(1, 1, 1, 1))
	gr.set_color(1, Color(1, 1, 1, 0))
	_soft.gradient = gr
	add_child(parts)

func _visuals() -> void:
	var env: Environment = G.main.env
	var sun: DirectionalLight3D = G.main.sun
	parts.emitting = kind != "clear"
	env.fog_enabled = kind != "clear" or night
	# sinematik renk derecelendirmesi
	env.adjustment_saturation = 1.12
	env.adjustment_contrast = 1.06
	env.adjustment_brightness = 1.04
	env.fog_mode = Environment.FOG_MODE_EXPONENTIAL
	env.fog_sky_affect = 0.0
	var sun_e: float = _base["sun_e"]
	var amb: float = _base["amb"]
	match kind:
		"rain", "storm":
			var heavy := kind == "storm"
			parts.amount = 12000 if heavy else 7000
			parts.lifetime = 0.9
			pmat.direction = Vector3(0.15, -1, 0.05)
			pmat.spread = 3.0
			pmat.initial_velocity_min = 38.0
			pmat.initial_velocity_max = 46.0
			pmat.gravity = Vector3(0, -10, 0)
			pmat.emission_box_extents = Vector3(80, 1, 80)
			parts.position = Vector3.ZERO
			_quad.size = Vector2(0.09, 2.4)
			_qmat.albedo_texture = null
			_qmat.billboard_mode = BaseMaterial3D.BILLBOARD_FIXED_Y
			pmat.color = Color(0.8, 0.85, 0.92, 0.45)
			env.fog_light_color = Color(0.45, 0.5, 0.55)
			env.fog_density = 0.0028 if heavy else 0.0014
			sun_e *= 0.45 if heavy else 0.65
			amb *= 0.9
		"snowstorm":
			parts.amount = 9000
			parts.lifetime = 5.0
			pmat.direction = Vector3(0.6, -1, 0.2)
			pmat.spread = 25.0
			pmat.initial_velocity_min = 5.0
			pmat.initial_velocity_max = 9.0
			pmat.gravity = Vector3(1.5, -1.2, 0.4)
			pmat.emission_box_extents = Vector3(80, 1, 80)
			_quad.size = Vector2(0.3, 0.3)
			_qmat.albedo_texture = _soft
			_qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			pmat.color = Color(1, 1, 1, 0.85)
			env.fog_light_color = Color(0.82, 0.85, 0.9)
			env.fog_density = 0.0032
			sun_e *= 0.5
		"sandstorm":
			parts.amount = 2600
			parts.lifetime = 4.0
			pmat.direction = Vector3(1, -0.05, 0.3)
			pmat.spread = 12.0
			pmat.initial_velocity_min = 14.0
			pmat.initial_velocity_max = 22.0
			pmat.gravity = Vector3(0, 0, 0)
			pmat.emission_box_extents = Vector3(90, 8, 90)
			_quad.size = Vector2(9.0, 6.0)
			_qmat.albedo_texture = _soft
			_qmat.billboard_mode = BaseMaterial3D.BILLBOARD_PARTICLES
			pmat.color = Color(0.8, 0.62, 0.4, 0.22)
			env.fog_light_color = Color(0.72, 0.55, 0.33)
			env.fog_density = 0.005
			sun_e *= 0.5
	parts.position.y = 26.0 if kind != "sandstorm" else 6.0
	if night:
		sun_e *= 0.4
		amb *= 0.75
		sun.light_color = Color(0.55, 0.65, 0.95)
		env.ambient_light_color = Color(0.35, 0.42, 0.6)
		env.background_color = Color(0.03, 0.04, 0.07)
		if kind == "clear":
			env.fog_light_color = Color(0.05, 0.06, 0.1)
			env.fog_density = 0.004
		env.tonemap_exposure = float(_base["exp"]) * 1.35
	else:
		sun.light_color = _base["sun_c"]
		env.ambient_light_color = _base["amb_c"]
		env.background_color = _base["bg"]
		env.tonemap_exposure = _base["exp"]
	sun.light_energy = sun_e
	env.ambient_light_energy = amb
	if kind != "clear":
		parts.restart()
