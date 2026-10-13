class_name Terrain extends Node3D
# Arazi: fotoğraf dokulu karışım, yükseklik (nehir yatağı), su yüzeyi ve boyanabilir harita
# (R yol, G iz, B yanık, A yama).

const RES := 1024
const HRES := 512
const WATER_Y := -0.6

var mi: MeshInstance3D
var mat: ShaderMaterial
var img: Image
var tex: ImageTexture
var himg: Image
var htex: ImageTexture
var water: MeshInstance3D
var water_mat: ShaderMaterial
var has_water := false
var biome: Dictionary
var kind := "desert"
var _dirty := false
var _upd := 0.0

func build(b: Dictionary) -> void:
	biome = b
	kind = b["id"]
	img = Image.create(RES, RES, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	tex = ImageTexture.create_from_image(img)
	himg = Image.create(HRES, HRES, false, Image.FORMAT_RF)
	himg.fill(Color(0, 0, 0, 1))
	htex = ImageTexture.create_from_image(himg)
	var pm := PlaneMesh.new()
	pm.size = Vector2(G.MAP, G.MAP)
	pm.subdivide_width = 383
	pm.subdivide_depth = 383
	mi = MeshInstance3D.new()
	mi.mesh = pm
	mi.position = Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mi.extra_cull_margin = 4.0
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	_apply_material(mat)
	mi.material_override = mat
	add_child(mi)
	# harita dışı: aynı malzemeyle düz çevre halkası
	var E := 260.0
	for r in [Rect2(-E, -E, G.MAP + 2 * E, E), Rect2(-E, G.MAP, G.MAP + 2 * E, E), Rect2(-E, 0, E, G.MAP), Rect2(G.MAP, 0, E, G.MAP)]:
		var outer := PlaneMesh.new()
		outer.size = r.size
		var omi := MeshInstance3D.new()
		omi.mesh = outer
		omi.position = Vector3(r.get_center().x, -0.01, r.get_center().y)
		omi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		omi.material_override = mat
		add_child(omi)

func _apply_material(m: ShaderMaterial) -> void:
	var b := biome
	m.set_shader_parameter("map_tex", tex)
	m.set_shader_parameter("height_tex", htex)
	m.set_shader_parameter("map_size", G.MAP)
	m.set_shader_parameter("tex_a", Biomes.tex(b["a"]))
	m.set_shader_parameter("nrm_a", Biomes.tex(b["a"], "normal"))
	m.set_shader_parameter("tex_b", Biomes.tex(b["b"]))
	m.set_shader_parameter("nrm_b", Biomes.tex(b["b"], "normal"))
	m.set_shader_parameter("tex_road", Biomes.tex(b["road"]))
	m.set_shader_parameter("nrm_road", Biomes.tex(b["road"], "normal"))
	m.set_shader_parameter("tex_bank", Biomes.tex(b["bank"]))
	m.set_shader_parameter("tex_burn", Biomes.tex(b["burn"]))
	m.set_shader_parameter("macro", _noise_tex(256, 0.012, 4, FastNoiseLite.FRACTAL_FBM, false, 0.0, 41))
	m.set_shader_parameter("dune_n", _noise_tex(512, 0.006, 5, FastNoiseLite.FRACTAL_RIDGED, true, 9.0, 11))
	for k in ["tint_a", "tint_a2", "tint_b", "tint_road", "tint_bank", "tint_track"]:
		m.set_shader_parameter(k, b[k])
	m.set_shader_parameter("scale_a", b["scale_a"])
	m.set_shader_parameter("scale_b", b["scale_b"])
	m.set_shader_parameter("scale_road", b["scale_road"])
	m.set_shader_parameter("patch_noise", b["patch_noise"])
	m.set_shader_parameter("dune_strength", b["dune"])
	m.set_shader_parameter("normal_strength", b["nstr"])
	m.set_shader_parameter("macro_strength", b["macro"])
	m.set_shader_parameter("road_amt", b.get("road_amt", 1.0))

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
	htex.update(himg)
	_dirty = false

# ------------------------------------------------------------ yükseklik / su
func carve(pts: PackedVector3Array, width: float, depth: float) -> void:
	# nehir/kanal yatağı: merkezde -depth, kıyıda yumuşak geçiş
	var bank := width * 0.5 + 2.5
	var k := float(HRES) / G.MAP
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var x0 := maxi(0, int((minf(a.x, b.x) - bank) * k))
		var x1 := mini(HRES - 1, int((maxf(a.x, b.x) + bank) * k))
		var z0 := maxi(0, int((minf(a.z, b.z) - bank) * k))
		var z1 := mini(HRES - 1, int((maxf(a.z, b.z) + bank) * k))
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x, b.z) - a2
		var L2 := maxf(ab.length_squared(), 1e-5)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var q := Vector2((x + 0.5) / k, (z + 0.5) / k)
				var t := clampf((q - a2).dot(ab) / L2, 0.0, 1.0)
				var d := (q - (a2 + ab * t)).length()
				var hh := 0.0
				if d < width * 0.5:
					hh = -depth * (1.0 - pow(d / (width * 0.5), 4.0) * 0.35)
				elif d < bank:
					var u := (d - width * 0.5) / (bank - width * 0.5)
					hh = lerpf(-depth * 0.65, 0.0, smoothstep(0.0, 1.0, u))
				else:
					continue
				var cur := himg.get_pixel(x, z).r
				if hh < cur:
					himg.set_pixel(x, z, Color(hh, 0, 0, 1))
	has_water = true

func carve_trench(a: Vector3, b: Vector3, w: float, depth: float) -> void:
	var k := float(HRES) / G.MAP
	var r := w * 0.5 + 1.0
	var a2 := Vector2(a.x, a.z)
	var ab := Vector2(b.x, b.z) - a2
	var L2 := maxf(ab.length_squared(), 1e-5)
	for z in range(maxi(0, int((minf(a.z, b.z) - r) * k)), mini(HRES - 1, int((maxf(a.z, b.z) + r) * k)) + 1):
		for x in range(maxi(0, int((minf(a.x, b.x) - r) * k)), mini(HRES - 1, int((maxf(a.x, b.x) + r) * k)) + 1):
			var q := Vector2((x + 0.5) / k, (z + 0.5) / k)
			var t := clampf((q - a2).dot(ab) / L2, 0.0, 1.0)
			var d := (q - (a2 + ab * t)).length()
			var hh := 0.0
			if d < w * 0.5:
				hh = -depth
			elif d < w * 0.5 + 0.9:
				hh = 0.12 * (1.0 - absf((d - w * 0.5 - 0.45) / 0.45))
			else:
				continue
			var cur := himg.get_pixel(x, z).r
			if hh < 0.0 and hh < cur or hh > 0.0 and cur >= 0.0 and hh > cur:
				himg.set_pixel(x, z, Color(hh, 0, 0, 1))
	htex.update(himg)

func raise_flat(p: Vector3, size: Vector2, rot: float) -> void:
	# köprü/yol rampası için yatağı doldur (yükseklik 0)
	var k := float(HRES) / G.MAP
	var c := cos(rot)
	var s := sin(rot)
	var ext := maxf(size.x, size.y) * 0.75
	for z in range(maxi(0, int((p.z - ext) * k)), mini(HRES - 1, int((p.z + ext) * k)) + 1):
		for x in range(maxi(0, int((p.x - ext) * k)), mini(HRES - 1, int((p.x + ext) * k)) + 1):
			var px := (x + 0.5) / k - p.x
			var pz := (z + 0.5) / k - p.z
			var lx := px * c - pz * s
			var lz := px * s + pz * c
			if absf(lx) < size.x * 0.5 and absf(lz) < size.y * 0.5:
				himg.set_pixel(x, z, Color(0, 0, 0, 1))

func ground_h(p: Vector3) -> float:
	var k := float(HRES) / G.MAP
	var x := clampi(int(p.x * k), 0, HRES - 1)
	var z := clampi(int(p.z * k), 0, HRES - 1)
	return himg.get_pixel(x, z).r

func make_water() -> void:
	if not has_water:
		return
	var pm := PlaneMesh.new()
	pm.size = Vector2(G.MAP, G.MAP)
	water = MeshInstance3D.new()
	water.mesh = pm
	water.position = Vector3(G.MAP * 0.5, WATER_Y, G.MAP * 0.5)
	water.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader")
	water_mat.set_shader_parameter("wave_n", _noise_tex(256, 0.03, 3, FastNoiseLite.FRACTAL_FBM, true, 6.0, 77))
	var fnt := _noise_tex(256, 0.05, 3, FastNoiseLite.FRACTAL_RIDGED, false, 0.0, 91)
	water_mat.set_shader_parameter("foam_tex", fnt)
	water_mat.set_shader_parameter("shallow", biome["water_shallow"])
	water_mat.set_shader_parameter("deep", biome["water_deep"])
	water_mat.set_shader_parameter("clarity", biome["clarity"])
	water.material_override = water_mat
	add_child(water)
	# suyun altında kalan yerleri ızgarada geçilmez yap
	var cells: Array = []
	for z in Grid.N:
		for x in Grid.N:
			var p := Vector3((x + 0.5) * Grid.CS, 0, (z + 0.5) * Grid.CS)
			if ground_h(p) < -0.32:
				var i := z * Grid.N + x
				G.grid.water[i] = 1
				cells.append(i)
	G.grid.refresh(cells)

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
		paint_line(a, b, w, 0, 0.95, 0.25, rng)
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		for s in [-0.95, 0.95]:
			paint_line(a + side * s, b + side * s, 0.6, 1, 0.55, 0.12, rng)
		for s in [-w * 0.42, w * 0.42]:
			paint_line(a + side * s, b + side * s, 0.5, 1, 0.22, 0.3, rng)

func patch_blob(p: Vector3, r: float, amount := 1.0) -> void:
	paint_circle(p, r, 3, amount)

# ------------------------------------------------------------ küçük ayrıntılar
func scatter(rng: RandomNumberGenerator) -> void:
	var winter: bool = biome["winter"]
	var mb := MB.new()
	mb.sphere(Vector3.ZERO, Vector3(0.18, 0.1, 0.14), 5, 3, Color(0.55, 0.47, 0.38) if not winter else Color(0.4, 0.38, 0.36), Basis(), true)
	_mm(mb.commit(Mats.vc()), 1400, rng, 0.6, 2.2)

func _mm(mesh: Mesh, n: int, rng: RandomNumberGenerator, s0: float, s1: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var xs: Array = []
	var tries := 0
	while xs.size() < n and tries < n * 4:
		tries += 1
		var p := Vector3(rng.randf_range(2, G.MAP - 2), 0, rng.randf_range(2, G.MAP - 2))
		if G.grid.height_at(p) > 0.05 or ground_h(p) < -0.1:
			continue
		var c := img.get_pixel(_px(p.x), _px(p.z))
		if c.r > 0.3:
			continue
		var s := rng.randf_range(s0, s1)
		xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var m := MultiMeshInstance3D.new()
	m.multimesh = mm
	add_child(m)
