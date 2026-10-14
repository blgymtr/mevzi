class_name Fx extends Node3D
# Görsel efektler: GPU-hesaplı parçacık halkaları, iz mermileri, parlama ışıkları, krater izleri.

enum { P_SMOKE, P_FIRE, P_SPARK, P_DEBRIS }
const CAP := [5000, 2400, 3000, 1800]

var mms: Array = []
var heads := [0, 0, 0, 0]
var tr_mm: MultiMesh
var tr_head := 0
const TR_CAP := 900
var lights: Array = []
var _light_i := 0
var decals: Array = []
var _decal_i := 0
const DECAL_CAP := 160
var emitters: Array = []    # sürekli kaynaklar: [konum, bitiş, tür, güç, birikim]
var rng := RandomNumberGenerator.new()
var puff_tex: ImageTexture
var dot_tex: ImageTexture
var crater_tex: ImageTexture
var scorch_tex: ImageTexture
var winter := false
var sand_col := Color(0.78, 0.6, 0.4)

func _ready() -> void:
	rng.randomize()
	puff_tex = _make_puff()
	dot_tex = _make_dot()
	crater_tex = _make_crater()
	scorch_tex = _make_scorch()
	var base: Shader = load("res://shaders/puff.gdshader")
	var add_sh := Shader.new()
	add_sh.code = base.code.replace("render_mode unshaded", "render_mode blend_add, unshaded")
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	for k in 4:
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.use_custom_data = true
		mm.mesh = quad
		mm.instance_count = CAP[k]
		var dead := Transform3D(Basis(Vector3(0.01, 0, 0), Vector3(-1000, 0.1, 0), Vector3(0, 0, 0.01)), Vector3(0, -50, 0))
		for i in CAP[k]:
			mm.set_instance_transform(i, dead)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.custom_aabb = AABB(Vector3(-500, -100, -500), Vector3(1300, 400, 1300))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = add_sh if (k == P_FIRE or k == P_SPARK) else base
		mat.set_shader_parameter("tex", dot_tex if k == P_SPARK else puff_tex)
		mat.set_shader_parameter("mode", k)
		mat.set_shader_parameter("intensity", 2.2 if k == P_FIRE else 4.0)
		mat.set_shader_parameter("ground_stop", 1.0 if k == P_DEBRIS or k == P_SPARK else 0.0)
		mat.render_priority = [1, 3, 4, 0][k]
		mi.material_override = mat
		add_child(mi)
		mms.append(mm)
	tr_mm = MultiMesh.new()
	tr_mm.transform_format = MultiMesh.TRANSFORM_3D
	tr_mm.use_colors = true
	tr_mm.mesh = quad
	tr_mm.instance_count = TR_CAP
	for i in TR_CAP:
		tr_mm.set_instance_transform(i, Transform3D(Basis(Vector3(0.01, 0, 0), Vector3(-1000, 0.1, 0.1), Vector3(0, 0, 0.01)), Vector3(0, -50, 0)))
	var tmi := MultiMeshInstance3D.new()
	tmi.multimesh = tr_mm
	tmi.custom_aabb = AABB(Vector3(-500, -100, -500), Vector3(1300, 400, 1300))
	tmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var tmat := ShaderMaterial.new()
	tmat.shader = load("res://shaders/tracer.gdshader")
	tmat.render_priority = 5
	tmi.material_override = tmat
	add_child(tmi)
	for i in 10:
		var l := OmniLight3D.new()
		l.light_energy = 0.0
		l.omni_range = 10.0
		l.light_color = Color(1.0, 0.62, 0.28)
		l.shadow_enabled = false
		l.visible = false
		add_child(l)
		lights.append([l, 0.0, 0.0, 0.0])

# ------------------------------------------------------------ dokular
func _make_puff() -> ImageTexture:
	var S := 128
	var img := Image.create(S * 2, S * 2, true, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.frequency = 0.035
	fn.fractal_octaves = 4
	var fn2 := FastNoiseLite.new()
	fn2.frequency = 0.09
	fn2.fractal_octaves = 3
	fn2.seed = 9
	var L := Vector3(0.45, 0.62, 0.64).normalized()
	for v in 4:
		var ox := (v % 2) * S
		var oy := (v / 2) * S
		for y in S:
			for x in S:
				var u := (x + 0.5) / S * 2.0 - 1.0
				var w := (y + 0.5) / S * 2.0 - 1.0
				var n := fn.get_noise_2d(x + v * 300.0, y + v * 170.0)
				var n2 := fn2.get_noise_2d(x + v * 91.0, y - v * 57.0)
				var r := sqrt(u * u + w * w) * (1.0 + n * 0.45)
				var a := clampf((1.0 - r) / 0.45, 0.0, 1.0)
				a = a * a * (3.0 - 2.0 * a)
				var nz := sqrt(maxf(0.0, 1.0 - minf(1.0, u * u + w * w)))
				var nrm := Vector3(u + n2 * 0.5, -w + n2 * 0.4, nz + 0.2).normalized()
				var lum := clampf(0.38 + 0.62 * maxf(0.0, nrm.dot(L)) + n2 * 0.12, 0.0, 1.0)
				img.set_pixel(ox + x, oy + y, Color(lum, lum, lum, a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _make_dot() -> ImageTexture:
	var S := 32
	var img := Image.create(S * 2, S * 2, true, Image.FORMAT_RGBA8)
	for y in S * 2:
		for x in S * 2:
			var u := float(x % S) / S * 2.0 - 1.0 + 1.0 / S
			var w := float(y % S) / S * 2.0 - 1.0 + 1.0 / S
			var d := sqrt(u * u + w * w)
			var a := clampf(1.0 - d, 0.0, 1.0)
			img.set_pixel(x, y, Color(1, 1, 1, a * a))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _make_crater() -> ImageTexture:
	var S := 128
	var img := Image.create(S, S, true, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.frequency = 0.08
	var rays: Array = []
	for i in 22:
		rays.append([rng.randf() * TAU, rng.randf_range(0.6, 1.0)])
	for y in S:
		for x in S:
			var u := (x + 0.5) / S * 2.0 - 1.0
			var w := (y + 0.5) / S * 2.0 - 1.0
			var r := sqrt(u * u + w * w)
			var ang := atan2(w, u)
			var n := fn.get_noise_2d(x, y)
			var rr := r * (1.0 + n * 0.18)
			var col := Color(0, 0, 0, 0)
			if rr < 0.42:
				var k := rr / 0.42
				# çukur: koyu merkez, kenara doğru gölgeli iç yamaç (ışık sağ üstten)
				var shade := 0.5 + 0.5 * (u * 0.6 - w * 0.6) * k
				var c := lerpf(0.18, 0.42, k) * (0.75 + 0.5 * (1.0 - shade))
				col = Color(c * 1.05, c * 0.82, c * 0.6, 0.95)
			elif rr < 0.58:
				var k2 := (rr - 0.42) / 0.16
				var b := 0.95 - k2 * 0.25
				col = Color(b, b * 0.86, b * 0.68, 0.85 * (1.0 - k2 * 0.6))
			else:
				# ışınsal püskürme
				var ray := 0.0
				for ry in rays:
					var da := absf(wrapf(ang - ry[0], -PI, PI))
					if da < 0.07 and r < ry[1]:
						ray = maxf(ray, (1.0 - da / 0.07) * (1.0 - (r - 0.58) / maxf(ry[1] - 0.58, 0.01)))
				var e := clampf(1.0 - (rr - 0.58) / 0.4, 0.0, 1.0)
				col = Color(0.42, 0.3, 0.2, clampf(e * 0.35 + ray * 0.5, 0.0, 1.0))
			img.set_pixel(x, y, col)
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

func _make_scorch() -> ImageTexture:
	var S := 64
	var img := Image.create(S, S, true, Image.FORMAT_RGBA8)
	var fn := FastNoiseLite.new()
	fn.frequency = 0.12
	for y in S:
		for x in S:
			var u := (x + 0.5) / S * 2.0 - 1.0
			var w := (y + 0.5) / S * 2.0 - 1.0
			var r := sqrt(u * u + w * w) * (1.0 + fn.get_noise_2d(x, y) * 0.35)
			var a := clampf(1.0 - r, 0.0, 1.0)
			img.set_pixel(x, y, Color(0.07, 0.06, 0.05, a * 0.9))
	img.generate_mipmaps()
	return ImageTexture.create_from_image(img)

# ------------------------------------------------------------ çekirdek emit
func emit(k: int, pos: Vector3, vel: Vector3, life: float, s0: float, s1: float, grav: float, drag: float, col: Color, delay := 0.0, spin := 0.0) -> void:
	var mm: MultiMesh = mms[k]
	var i: int = heads[k]
	heads[k] = (i + 1) % CAP[k]
	if vel.length_squared() < 1e-6:
		vel = Vector3(0.001, 0.0005, 0.0007)
	mm.set_instance_transform(i, Transform3D(Basis(vel, Vector3(G.time + delay, life, grav), Vector3(s0, s1, drag)), pos))
	mm.set_instance_color(i, col)
	mm.set_instance_custom_data(i, Color(rng.randf() * TAU, spin if spin != 0.0 else rng.randf_range(-0.6, 0.6), float(rng.randi() % 4), rng.randf()))

func tracer(a: Vector3, b: Vector3, speed: float, col := Color(1.0, 0.62, 0.25), width := 0.07, tail := 3.5) -> void:
	var i := tr_head
	tr_head = (tr_head + 1) % TR_CAP
	var life := maxf(a.distance_to(b) / speed, 0.03)
	tr_mm.set_instance_transform(i, Transform3D(Basis(b - a, Vector3(G.time, life, width), Vector3(tail, 0, 0.001)), a))
	tr_mm.set_instance_color(i, col)

func flash(p: Vector3, energy: float, rng_m: float, dur: float, col := Color(1.0, 0.62, 0.28)) -> void:
	var L: Array = lights[_light_i]
	_light_i = (_light_i + 1) % lights.size()
	var l: OmniLight3D = L[0]
	l.position = p + Vector3(0, 1.2, 0)
	l.omni_range = rng_m
	l.light_color = col
	l.visible = true
	L[1] = energy
	L[2] = dur
	L[3] = dur

func _process(dt: float) -> void:
	for L in lights:
		if L[3] > 0.0:
			L[3] -= dt
			var l: OmniLight3D = L[0]
			var k: float = clampf(L[3] / L[2], 0.0, 1.0)
			l.light_energy = L[1] * k * k
			if L[3] <= 0.0:
				l.visible = false
	var i := emitters.size() - 1
	while i >= 0:
		var e: Array = emitters[i]
		if G.time > e[1]:
			emitters.remove_at(i)
		else:
			_run_emitter(e, dt)
		i -= 1

func _run_emitter(e: Array, dt: float) -> void:
	var p: Vector3 = e[0]
	var kind: String = e[2]
	var pw: float = e[3]
	var left: float = e[1] - G.time
	e[4] += dt
	match kind:
		"burn":
			var fade := clampf(left / 8.0, 0.15, 1.0)
			while e[4] > 0.07:
				e[4] -= 0.07
				if rng.randf() < fade:
					emit(P_FIRE, p + _rv(0.5 * pw, 0.2), Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(1.0, 2.2), rng.randf_range(-0.3, 0.3)), rng.randf_range(0.5, 0.9), 0.7 * pw, 1.3 * pw, -0.6, 0.8, Color(1, 1, 1, 0.9))
				var g := rng.randf_range(0.08, 0.16)
				emit(P_SMOKE, p + _rv(0.4 * pw, 0.3) + Vector3(0, 0.6, 0), Vector3(rng.randf_range(0.3, 0.9), rng.randf_range(1.8, 3.0), rng.randf_range(-0.4, 0.2)), rng.randf_range(4.0, 6.5), 1.0 * pw, 4.5 * pw, -0.25, 0.35, Color(g, g, g, 0.8))
		"smoke":
			# sis bombası: yoğun beyaz-gri
			while e[4] > 0.12:
				e[4] -= 0.12
				var c := rng.randf_range(0.72, 0.86)
				emit(P_SMOKE, p + _rv(1.2, 0.2), Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(0.2, 0.9), rng.randf_range(-1.2, 1.2)), rng.randf_range(4.0, 7.0), 1.5, 5.5 * pw, -0.05, 0.6, Color(c, c, c * 0.98, 0.75))
		"smolder":
			while e[4] > 0.25:
				e[4] -= 0.25
				var g := rng.randf_range(0.18, 0.28)
				emit(P_SMOKE, p + _rv(0.6, 0.2), Vector3(rng.randf_range(0.2, 0.6), rng.randf_range(1.0, 1.8), 0), rng.randf_range(4.0, 6.0), 0.8 * pw, 3.0 * pw, -0.15, 0.3, Color(g, g, g, 0.55))

func _rv(r: float, ry := -1.0) -> Vector3:
	return Vector3(rng.randf_range(-r, r), rng.randf_range(-(ry if ry >= 0 else r), ry if ry >= 0 else r), rng.randf_range(-r, r))

func _sand() -> Color:
	return sand_col

# ------------------------------------------------------------ hazır efektler
func explosion(p: Vector3, size: float, kind := "") -> void:
	var s := size
	var ground := p.y < 1.0
	flash(p, 6.0 * s, 6.0 + 7.0 * s, 0.3 + 0.12 * s)
	# beyaz-sarı parlama çekirdeği
	emit(P_FIRE, p + Vector3(0, 0.4 * s, 0), Vector3(0, 0.5, 0), 0.16 + 0.04 * s, 2.0 * s, 3.4 * s, 0.0, 1.0, Color(1.6, 1.5, 1.3, 1.0))
	var nfire := int(9 * s)
	for i in nfire:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.3, 1.2), rng.randf_range(-1, 1)).normalized()
		emit(P_FIRE, p + d * 0.3 * s, d * rng.randf_range(2.0, 5.0) * s, rng.randf_range(0.45, 0.9), 1.0 * s, rng.randf_range(2.0, 3.2) * s, -1.5, 3.0, Color(1, 1, 1, 1), rng.randf_range(0.0, 0.06))
	# kara duman sütunu
	var nsm := int(12 * s)
	for i in nsm:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1.4), rng.randf_range(-1, 1))
		var g := rng.randf_range(0.07, 0.17)
		var tint := Color(g * 1.1, g, g * 0.95, 0.9)
		emit(P_SMOKE, p + d * 0.5 * s, d * rng.randf_range(1.2, 3.0) * s + Vector3(0, 1.0 * s, 0), rng.randf_range(2.8, 5.0) * (0.7 + 0.3 * s), 1.4 * s, rng.randf_range(3.5, 5.5) * s, -0.35, 1.1, tint, rng.randf_range(0.05, 0.25))
	# yer tozu halkası
	if ground:
		var sand := _sand()
		for i in int(10 * s):
			var a := TAU * i / int(10 * s)
			var d := Vector3(cos(a), 0.08, sin(a))
			emit(P_SMOKE, p + d * 0.5 * s, d * rng.randf_range(4.0, 7.0) * s, rng.randf_range(1.3, 2.4), 1.0 * s, 3.2 * s, 0.0, 2.5, Color(sand.r, sand.g, sand.b, 0.75), 0.02)
	# kıvılcımlar
	for i in int(22 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1.5), rng.randf_range(-1, 1)).normalized()
		emit(P_SPARK, p + Vector3(0, 0.3, 0), d * rng.randf_range(8.0, 22.0) * sqrt(s), rng.randf_range(0.4, 1.1), 0.09, 0.07, 9.8, 1.2, Color(1.0, 0.7, 0.35, 1))
	# moloz parçaları
	var dc := _sand().darkened(0.25)
	for i in int(14 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.6, 1.8), rng.randf_range(-1, 1)).normalized()
		var c := dc if rng.randf() < 0.6 else Color(0.15, 0.13, 0.12)
		emit(P_DEBRIS, p + Vector3(0, 0.2, 0), d * rng.randf_range(4.0, 13.0) * sqrt(s), rng.randf_range(1.8, 3.2), rng.randf_range(0.1, 0.24) * sqrt(s), rng.randf_range(0.1, 0.24) * sqrt(s), 13.0, 0.25, c, 0.0, rng.randf_range(-6, 6))

func dust_burst(p: Vector3, r: float) -> void:
	var sand := _sand().lightened(0.1)
	for i in int(14 + r * 4):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.0, 0.6), rng.randf_range(-1, 1))
		emit(P_SMOKE, p + d * r * 0.6, d * rng.randf_range(1.0, 3.0), rng.randf_range(2.5, 4.5), 1.5, 4.0 + r, -0.1, 1.2, Color(sand.r, sand.g, sand.b, 0.8), rng.randf_range(0.0, 0.3))

func muzzle(p: Vector3, dir: Vector3, big := false) -> void:
	var s := 0.55 if big else 0.32
	emit(P_FIRE, p + dir * 0.15, dir * 2.0, 0.06, s, s * 1.4, 0.0, 1.0, Color(1.8, 1.5, 1.0, 1))
	if big:
		emit(P_FIRE, p + dir * 0.5, dir * 6.0, 0.09, s * 1.4, s * 2.2, 0.0, 3.0, Color(1.5, 1.2, 0.9, 1))
		var g := 0.7
		for i in 3:
			emit(P_SMOKE, p + dir * 0.6, dir * rng.randf_range(2.0, 5.0) + _rv(0.6), rng.randf_range(0.8, 1.4), 0.4, 1.4, -0.2, 2.5, Color(g, g, g, 0.35))

func cannon_blast(p: Vector3, dir: Vector3) -> void:
	flash(p, 3.5, 9.0, 0.18, Color(1.0, 0.75, 0.4))
	emit(P_FIRE, p + dir * 0.6, dir * 4.0, 0.12, 1.4, 2.6, 0.0, 3.0, Color(1.7, 1.4, 1.0, 1))
	for i in 6:
		emit(P_FIRE, p + dir * 0.8, dir * rng.randf_range(6, 14) + _rv(2.0), rng.randf_range(0.08, 0.18), 0.6, 1.4, 0.0, 6.0, Color(1, 1, 1, 1))
	var sand := _sand()
	for i in 10:
		var d := (dir * 0.7 + _rv(1.0)).normalized()
		emit(P_SMOKE, p + dir * 1.0, d * rng.randf_range(3.0, 9.0), rng.randf_range(1.5, 2.8), 0.8, 3.0, -0.1, 2.2, Color(0.75, 0.72, 0.68, 0.55))
	# yerden kalkan toz
	for i in 10:
		var a := TAU * i / 10.0
		var d := Vector3(cos(a), 0.05, sin(a))
		emit(P_SMOKE, Vector3(p.x, 0.2, p.z) + d * 1.5, d * rng.randf_range(3.0, 6.0), rng.randf_range(1.2, 2.2), 1.0, 3.0, 0.0, 2.2, Color(sand.r, sand.g, sand.b, 0.55))

func impact(p: Vector3, kind := "dirt") -> void:
	match kind:
		"dirt":
			var sand := _sand()
			emit(P_SMOKE, p, Vector3(rng.randf_range(-0.3, 0.3), rng.randf_range(1.2, 2.4), rng.randf_range(-0.3, 0.3)), rng.randf_range(0.5, 0.9), 0.18, 0.7, 2.0, 1.5, Color(sand.r, sand.g, sand.b, 0.8))
			for i in 2:
				emit(P_DEBRIS, p, Vector3(rng.randf_range(-1.5, 1.5), rng.randf_range(2.0, 4.0), rng.randf_range(-1.5, 1.5)), 0.6, 0.06, 0.06, 12.0, 0.3, sand.darkened(0.3))
		"wall":
			emit(P_SMOKE, p, Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.4, 1.2), rng.randf_range(-0.5, 0.5)), rng.randf_range(0.6, 1.0), 0.2, 0.8, 0.5, 1.5, Color(0.85, 0.8, 0.72, 0.8))
			for i in 3:
				emit(P_DEBRIS, p, Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(1.0, 3.0), rng.randf_range(-2.0, 2.0)), 0.7, 0.05, 0.05, 12.0, 0.3, Color(0.8, 0.76, 0.66))
		"metal":
			for i in 5:
				emit(P_SPARK, p, Vector3(rng.randf_range(-4, 4), rng.randf_range(1, 5), rng.randf_range(-4, 4)), rng.randf_range(0.15, 0.35), 0.05, 0.04, 9.8, 1.0, Color(1.0, 0.85, 0.5))
		"blood":
			emit(P_SMOKE, p, Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.3, 0.8), rng.randf_range(-0.4, 0.4)), 0.35, 0.15, 0.4, 3.0, 2.0, Color(0.45, 0.06, 0.04, 0.7))

func rocket_trail(p: Vector3, dir := Vector3.ZERO) -> void:
	# ince, uzun duman izi + motor alevi (parlak çekirdek, turuncu kuyruk)
	emit(P_SMOKE, p, _rv(0.15), rng.randf_range(1.8, 3.0), 0.12, 0.9, -0.1, 1.2, Color(0.88, 0.87, 0.85, 0.5))
	emit(P_FIRE, p, -dir * 4.0, 0.08, 0.32, 0.08, 0.0, 1.0, Color(2.2, 1.6, 0.9, 1))
	emit(P_FIRE, p - dir * 0.3, -dir * 6.0 + _rv(0.6), 0.12, 0.22, 0.05, 0.0, 1.0, Color(1.8, 0.7, 0.15, 1))

func backblast(p: Vector3, dir: Vector3) -> void:
	flash(p, 5.0, 6.0, 0.07, Color(1.0, 0.7, 0.35))
	for i in 10:
		emit(P_SMOKE, p, -dir * rng.randf_range(4.0, 9.0) + _rv(1.5), rng.randf_range(1.2, 2.2), 0.4, 2.0, -0.1, 2.5, Color(0.82, 0.8, 0.76, 0.55))
	for i in 5:
		emit(P_FIRE, p, -dir * rng.randf_range(6.0, 10.0) + _rv(1.0), 0.15, 0.5, 0.2, 0.0, 2.0, Color(1.8, 0.9, 0.3, 1))

func exhaust(p: Vector3, strength := 1.0) -> void:
	var g := 0.3
	emit(P_SMOKE, p, Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(0.5, 1.0), rng.randf_range(-0.2, 0.2)), rng.randf_range(0.8, 1.4), 0.2, 0.9 * strength, -0.2, 1.0, Color(g, g, g, 0.25))

func vehicle_dust(p: Vector3) -> void:
	var sand := _sand()
	emit(P_SMOKE, p, Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(0.2, 0.6), rng.randf_range(-0.4, 0.4)), rng.randf_range(1.0, 1.8), 0.4, 1.6, -0.05, 1.5, Color(sand.r, sand.g, sand.b, 0.35))

func blood_pool(p: Vector3) -> void:
	_decal(p, rng.randf_range(0.6, 1.0), scorch_tex, Color(0.35, 0.05, 0.03, 0.75))

func burn(p: Vector3, dur: float, pw := 1.0) -> void:
	emitters.append([p, G.time + dur, "burn", pw, 0.0])
	emitters.append([p, G.time + dur + 40.0, "smolder", pw, 0.0])

func smoke_screen(p: Vector3, dur := 16.0) -> void:
	emitters.append([p, G.time + dur, "smoke", 1.0, 0.0])

func crater(p: Vector3, size: float) -> void:
	_decal(p, size, crater_tex, Color(1, 1, 1, 1))

func scorch(p: Vector3, size: float) -> void:
	_decal(p, size, scorch_tex, Color(1, 1, 1, 0.85))

func _decal(p: Vector3, size: float, tex: Texture2D, mod: Color) -> void:
	var d: Decal
	if decals.size() < DECAL_CAP:
		d = Decal.new()
		d.upper_fade = 0.3
		d.lower_fade = 0.3
		d.cull_mask = 1
		add_child(d)
		decals.append(d)
	else:
		d = decals[_decal_i]
		_decal_i = (_decal_i + 1) % DECAL_CAP
	d.texture_albedo = tex
	d.modulate = mod
	d.size = Vector3(size, 1.2, size)
	d.position = Vector3(p.x, 0.0, p.z)
	d.rotation.y = rng.randf() * TAU
