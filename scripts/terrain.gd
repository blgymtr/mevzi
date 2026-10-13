class_name Terrain extends Node3D
# Zemin düzlemi + çalışma zamanı boyanabilir harita (R yol, G iz, B yanık).

const RES := 1024
var mi: MeshInstance3D
var mat: ShaderMaterial
var img: Image
var tex: ImageTexture
var _dirty := false
var _upd := 0.0
var kind := "desert"

func build(k: String) -> void:
	kind = k
	img = Image.create(RES, RES, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	tex = ImageTexture.create_from_image(img)
	var pm := PlaneMesh.new()
	pm.size = Vector2(G.MAP + 420.0, G.MAP + 420.0)
	pm.subdivide_width = 8
	pm.subdivide_depth = 8
	mi = MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/ground.gdshader")
	mat.set_shader_parameter("map_tex", tex)
	mat.set_shader_parameter("map_size", G.MAP)
	mat.set_shader_parameter("dune_n", _noise_tex(512, 0.006, 5, FastNoiseLite.FRACTAL_RIDGED, true, 9.0, 11))
	mat.set_shader_parameter("ripple_n", _noise_tex(256, 0.045, 2, FastNoiseLite.FRACTAL_FBM, true, 6.0, 23))
	mat.set_shader_parameter("grain", _noise_tex(256, 0.02, 4, FastNoiseLite.FRACTAL_FBM, false, 0.0, 37))
	if k == "winter":
		mat.set_shader_parameter("col_a", Color(0.95, 0.96, 0.98))
		mat.set_shader_parameter("col_b", Color(0.86, 0.88, 0.92))
		mat.set_shader_parameter("col_crest", Color(1.0, 1.0, 1.0))
		mat.set_shader_parameter("col_road", Color(0.78, 0.77, 0.76))
		mat.set_shader_parameter("col_track", Color(0.52, 0.5, 0.48))
		mat.set_shader_parameter("col_scorch", Color(0.16, 0.15, 0.14))
		mat.set_shader_parameter("dune_strength", 0.45)
		mat.set_shader_parameter("ripple_strength", 0.12)
		mat.set_shader_parameter("rough", 0.8)
	mi.material_override = mat
	add_child(mi)

func _noise_tex(size: int, freq: float, oct: int, frac: int, normal: bool, bump: float, seed_v: int) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	nt.width = size
	nt.height = size
	nt.seamless = true
	nt.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.seed = seed_v
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = freq
	fn.fractal_type = frac
	fn.fractal_octaves = oct
	nt.noise = fn
	if normal:
		nt.as_normal_map = true
		nt.bump_strength = bump
	return nt

func _process(dt: float) -> void:
	_upd -= dt
	if _dirty and _upd <= 0.0:
		tex.update(img)
		_dirty = false
		_upd = 0.35

func flush() -> void:
	tex.update(img)
	_dirty = false

# ------------------------------------------------------------ boyama
func _px(v: float) -> int:
	return int(v / G.MAP * RES)

func paint_circle(p: Vector3, r: float, ch: int, amount: float, soft := true) -> void:
	var cx := p.x / G.MAP * RES
	var cz := p.z / G.MAP * RES
	var rp := r / G.MAP * RES
	var x0 := maxi(0, int(cx - rp))
	var x1 := mini(RES - 1, int(cx + rp))
	var z0 := maxi(0, int(cz - rp))
	var z1 := mini(RES - 1, int(cz + rp))
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var d := Vector2(x + 0.5 - cx, z + 0.5 - cz).length() / maxf(rp, 0.5)
			if d > 1.0:
				continue
			var a := amount * ((1.0 - d * d) if soft else 1.0)
			var c := img.get_pixel(x, z)
			c[ch] = clampf(maxf(c[ch], a) if soft else c[ch] + a, 0.0, 1.0)
			img.set_pixel(x, z, c)
	_dirty = true

func paint_line(a: Vector3, b: Vector3, w: float, ch: int, amount: float, jitter := 0.0, rng: RandomNumberGenerator = null) -> void:
	var L := a.distance_to(b)
	var step := maxf(0.3, w * 0.35)
	var n := int(L / step) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if jitter > 0.0 and rng != null:
			p += Vector3(rng.randf_range(-jitter, jitter), 0, rng.randf_range(-jitter, jitter))
		paint_circle(p, w * 0.5, ch, amount)

func track(p: Vector3, amount := 0.35) -> void:
	# tek piksel hızlı iz
	var x := _px(p.x)
	var z := _px(p.z)
	if x < 0 or z < 0 or x >= RES or z >= RES:
		return
	var c := img.get_pixel(x, z)
	c.g = minf(1.0, c.g + amount)
	img.set_pixel(x, z, c)
	_dirty = true

func road_polyline(pts: PackedVector3Array, w: float, rng: RandomNumberGenerator) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		paint_line(a, b, w, 0, 0.9)
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		for s in [-0.9, 0.9]:
			paint_line(a + side * s, b + side * s, 0.55, 1, 0.6, 0.12, rng)
		for s in [-2.2, 2.2]:
			paint_line(a + side * s, b + side * s, 0.4, 1, 0.25, 0.3, rng)

# ------------------------------------------------------------ küçük ayrıntılar (taş, çalı, kaktüs)
func scatter(rng: RandomNumberGenerator) -> void:
	var winter := kind == "winter"
	# taşlar
	var mb := MB.new()
	mb.sphere(Vector3.ZERO, Vector3(0.18, 0.1, 0.14), 5, 3, Color(0.55, 0.45, 0.35) if not winter else Color(0.4, 0.38, 0.36), Basis(), true)
	_mm(mb.commit(Mats.vc()), 1600, rng, 0.6, 2.2, false)
	# kuru çalı / ot
	var mb2 := MB.new()
	for i in 7:
		var a := TAU * i / 7.0
		var tip := Vector3(cos(a) * 0.35, 0.32 + rng.randf() * 0.15, sin(a) * 0.35)
		mb2.cyl_between(Vector3.ZERO, tip, 0.03, 0.005, 3, Color(0.45, 0.38, 0.22) if not winter else Color(0.5, 0.42, 0.3), false)
	_mm(mb2.commit(Mats.vc()), 500, rng, 0.7, 1.6, false)
	if not winter:
		# küçük kaktüs/agav
		var mb3 := MB.new()
		mb3.cyl(Vector3.ZERO, 0.07, 0.06, 0.9, 6, Color(0.3, 0.42, 0.25))
		mb3.cyl(Vector3(0.12, 0.35, 0), 0.05, 0.045, 0.35, 5, Color(0.3, 0.42, 0.25))
		mb3.box(Vector3(0.07, 0.36, 0), Vector3(0.12, 0.07, 0.07), Color(0.3, 0.42, 0.25))
		_mm(mb3.commit(Mats.vc()), 140, rng, 0.8, 1.5, true)

func _mm(mesh: Mesh, n: int, rng: RandomNumberGenerator, s0: float, s1: float, avoid_roads: bool) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var xs: Array = []
	var tries := 0
	while xs.size() < n and tries < n * 4:
		tries += 1
		var p := Vector3(rng.randf_range(2, G.MAP - 2), 0, rng.randf_range(2, G.MAP - 2))
		if G.grid.height_at(p) > 0.05:
			continue
		var c := img.get_pixel(_px(p.x), _px(p.z))
		if c.r > 0.3 and (avoid_roads or rng.randf() < 0.8):
			continue
		var s := rng.randf_range(s0, s1)
		xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var m := MultiMeshInstance3D.new()
	m.multimesh = mm
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	add_child(m)
