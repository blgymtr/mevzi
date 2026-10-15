class_name Fx extends Node3D
# Görsel efektler: GPU-hesaplı parçacık halkaları, iz mermileri, parlama ışıkları, krater izleri.

enum { P_SMOKE, P_FIRE, P_SPARK, P_DEBRIS, P_STREAK, P_FLIP, P_FLIPS, P_FLIPD }
const CAP := [7000, 4000, 3000, 1800, 2400, 300, 400, 300]
# flipbook atlasları (tools/blender/fx_flipbook.py, Mantaflow simülasyonu): yoksa bu türler kullanılmaz
var has_flip := false
var has_flip_smoke := false
var has_flip_dust := false

var mms: Array = []
var heads := [0, 0, 0, 0, 0, 0, 0, 0]
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
var debris_tex: ImageTexture
var crater_tex: ImageTexture
var scorch_tex: ImageTexture
var winter := false
var sand_col := Color(0.78, 0.6, 0.4)

func _ready() -> void:
	rng.randomize()
	puff_tex = _make_puff()
	dot_tex = _make_dot()
	debris_tex = _make_debris()
	crater_tex = _make_crater()
	scorch_tex = _make_scorch()
	var base: Shader = load("res://shaders/puff.gdshader")
	var add_sh := Shader.new()
	add_sh.code = base.code.replace("render_mode unshaded", "render_mode blend_add, unshaded")
	var quad := QuadMesh.new()
	quad.size = Vector2(1, 1)
	has_flip = ResourceLoader.exists("res://assets/fx/expl_flip.png")
	has_flip_smoke = ResourceLoader.exists("res://assets/fx/smoke_flip.png")
	has_flip_dust = ResourceLoader.exists("res://assets/fx/dust_flip.png")
	for k in 8:
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
		mi.custom_aabb = AABB(Vector3(-500, -100, -500), Vector3(G.MAP + 1000.0, 400, G.MAP + 1000.0))
		mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		var mat := ShaderMaterial.new()
		mat.shader = add_sh if k == P_SPARK else base
		mat.set_shader_parameter("tex", dot_tex if k == P_SPARK else (debris_tex if k == P_DEBRIS else puff_tex))
		if k == P_FLIP and has_flip:
			mat.set_shader_parameter("tex", load("res://assets/fx/expl_flip.png"))
		elif k == P_FLIPS and has_flip_smoke:
			mat.set_shader_parameter("tex", load("res://assets/fx/smoke_flip.png"))
		elif k == P_FLIPD and has_flip_dust:
			mat.set_shader_parameter("tex", load("res://assets/fx/dust_flip.png"))
		mat.set_shader_parameter("mode", k)
		mat.set_shader_parameter("intensity", 1.35 if k == P_FIRE else 4.0)
		mat.set_shader_parameter("ground_stop", 1.0 if k == P_DEBRIS or k == P_SPARK or k == P_STREAK else 0.0)
		mat.render_priority = [1, 3, 4, 0, 2, 3, 1, 1][k]
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
	tmi.custom_aabb = AABB(Vector3(-500, -100, -500), Vector3(G.MAP + 1000.0, 400, G.MAP + 1000.0))
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

# moloz parçası atlası (2x2): her hücrede düzensiz, köşeli bir kırık parça — 5-8 köşeli çokgen, gelişigüzel
# uzatılmış; yüzeyler (iç noktadan üçgen yelpaze) ayrı ayrı gölgeli → yontulmuş taş/toprak kesiği görünümü.
# Eskiden yuvarlak, küre gibi ışıklı "puf" dokusu kullanılıyordu: parçalar taş atılmış top gibi görünüyordu.
func _make_debris() -> ImageTexture:
	var S := 64
	var img := Image.create(S * 2, S * 2, true, Image.FORMAT_RGBA8)
	var r := RandomNumberGenerator.new()
	r.seed = 4711
	for v in 4:
		var n := r.randi_range(5, 8)
		var stretch := r.randf_range(0.45, 0.95)
		var rot := r.randf() * TAU
		var poly: PackedVector2Array = []
		for k in n:
			var a := TAU * (k + r.randf_range(-0.3, 0.3)) / n
			var rad := r.randf_range(0.55, 0.95)
			var q := Vector2(cos(a) * rad, sin(a) * rad * stretch).rotated(rot)
			poly.append(q)
		var c0 := Vector2(r.randf_range(-0.15, 0.15), r.randf_range(-0.15, 0.15))
		var shade: Array = []
		for k in n:
			shade.append(r.randf_range(0.3, 1.0))
		var ox := (v % 2) * S
		var oy := (v / 2) * S
		for y in S:
			for x in S:
				var p := Vector2((x + 0.5) / S * 2.0 - 1.0, (y + 0.5) / S * 2.0 - 1.0)
				if not Geometry2D.is_point_in_polygon(p, poly):
					img.set_pixel(ox + x, oy + y, Color(0, 0, 0, 0))
					continue
				# hangi yüzey (merkezden açıya göre yelpaze dilimi)
				var ang := fposmod((p - c0).angle() - (poly[0] - c0).angle(), TAU)
				var f := 0
				for k in n:
					var a0 := fposmod((poly[k] - c0).angle() - (poly[0] - c0).angle(), TAU)
					if ang >= a0:
						f = k
				var lum: float = shade[f] * (0.85 + 0.15 * r.randf())
				img.set_pixel(ox + x, oy + y, Color(lum, lum, lum, 1.0))
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

func tracer(a: Vector3, b: Vector3, speed: float, col := Color(1.0, 0.62, 0.25), width := 0.035, tail := 4.5) -> void:
	var i := tr_head
	tr_head = (tr_head + 1) % TR_CAP
	var life := maxf(a.distance_to(b) / speed, 0.03)
	tr_mm.set_instance_transform(i, Transform3D(Basis(b - a, Vector3(G.time, life, width), Vector3(tail, 0, 0.001)), a))
	tr_mm.set_instance_color(i, col)

# kalibreye göre iz: kalınlık ve kuyruk boyu Ammo.tracer_dims'ten
func tracer_cal(a: Vector3, b: Vector3, speed: float, col: Color, cal: float) -> void:
	var d := Ammo.tracer_dims(cal)
	tracer(a, b, speed, col, d.x, d.y)

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
		"mist":
			while e[4] > 1.6:
				e[4] -= 1.6
				var q := p + Vector3(rng.randf_range(-pw, pw), 0.4, rng.randf_range(-pw, pw))
				emit(P_SMOKE, q, Vector3(rng.randf_range(0.1, 0.35), 0.02, rng.randf_range(-0.1, 0.1)), rng.randf_range(9.0, 14.0), 3.0, rng.randf_range(6.0, 9.0), 0.0, 0.05, Color(0.92, 0.94, 0.95, 0.16))
		"column":
			var fade2 := clampf(left / 10.0, 0.2, 1.0)
			while e[4] > 0.05:
				e[4] -= 0.05
				if rng.randf() < fade2:
					emit(P_FIRE, p + _rv(0.6 * pw, 0.2), Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(2.0, 4.0), rng.randf_range(-0.4, 0.4)), rng.randf_range(0.5, 1.0), 0.9 * pw, 1.8 * pw, -1.0, 1.0, Color(1, 1, 1, 0.95))
				var g := rng.randf_range(0.03, 0.09)
				emit(P_SMOKE, p + _rv(0.5 * pw, 0.3) + Vector3(0, 1.0, 0), Vector3(rng.randf_range(0.2, 1.0), rng.randf_range(4.0, 7.0), rng.randf_range(-0.5, 0.3)), rng.randf_range(6.0, 9.0), 1.4 * pw, 6.5 * pw, -0.1, 0.25, Color(g, g, g, 0.92))
			# simüle edilmiş kalın duman (flipbook): seyrek, büyük, kıvrılarak yükselen
			if e.size() < 6:
				e.append(0.0)
			e[5] += dt
			if has_flip_smoke and e[5] > 1.1:
				e[5] = 0.0
				var dk := Color(0.32, 0.31, 0.3, 0.85) if rng.randf() < 0.7 else Color(0.5, 0.48, 0.46, 0.7)
				emit(P_FLIPS, p + Vector3(rng.randf_range(-0.6, 0.6), 4.0 * pw, rng.randf_range(-0.6, 0.6)), Vector3(rng.randf_range(0.3, 0.9), 2.2, rng.randf_range(-0.3, 0.3)), rng.randf_range(5.5, 7.5), 6.0 * pw, 10.0 * pw, -0.15, 0.25, dk, 0.0, rng.randf_range(-0.2, 0.2))
		"jet":
			var fade3 := clampf(left / 6.0, 0.0, 1.0)
			var pulse := 0.6 + 0.4 * sin(G.time * 7.0 + p.x)
			while e[4] > 0.03:
				e[4] -= 0.03
				if rng.randf() < fade3:
					emit(P_FIRE, p + _rv(0.25 * pw, 0.1), Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(7.0, 12.0) * pulse, rng.randf_range(-0.6, 0.6)), rng.randf_range(0.35, 0.6), 0.6 * pw, 1.3 * pw, -2.0, 0.6, Color(1.15, 0.85, 0.45, 1))
					if rng.randf() < 0.3:
						emit(P_SPARK, p, Vector3(rng.randf_range(-4, 4), rng.randf_range(6, 14), rng.randf_range(-4, 4)), rng.randf_range(0.6, 1.2), 0.06, 0.04, 9.8, 0.2, Color(1, 0.8, 0.4, 1))
				var c := rng.randf_range(0.62, 0.8)
				emit(P_SMOKE, p + Vector3(0, 4.5 * pw * pulse, 0) + _rv(0.6 * pw, 0.4), Vector3(rng.randf_range(0.1, 0.8), rng.randf_range(3.0, 5.0), rng.randf_range(-0.4, 0.3)), rng.randf_range(4.0, 6.5), 1.2 * pw, 5.0 * pw, -0.15, 0.3, Color(c, c, c * 0.97, 0.7))
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
	if ground and kind != "auto":
		dirt_crown(Vector3(p.x, 0.15, p.z), s)
	if kind == "big" and s >= 1.4:
		fireball(p + Vector3(0, 0.5, 0), s * 0.7)
		if s >= 2.0:
			mushroom(p, s * 0.6)
	flash(p, (1.6 if kind in ["shell", "mine", "mortar", "grenade"] else 2.6) * s, 5.0 + 5.0 * s, 0.22 + 0.1 * s)
	var shell := kind in ["shell", "mine", "mortar", "grenade"]
	# parlama çekirdeği (kısa, turuncu-sarı)
	emit(P_FIRE, p + Vector3(0, 0.4 * s, 0), Vector3(0, 0.5, 0), 0.1 + 0.03 * s, 1.2 * s, 2.2 * s, 0.0, 1.0, Color(1.05, 0.85, 0.6, 1.0))
	var nfire := int((4 if shell else 9) * s)
	for i in nfire:
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.3, 1.2), rng.randf_range(-1, 1)).normalized()
		emit(P_FIRE, p + d * 0.3 * s, d * rng.randf_range(2.0, 5.0) * s, rng.randf_range(0.3, 0.7) if shell else rng.randf_range(0.45, 0.9), 0.8 * s, rng.randf_range(1.6, 2.6) * s, -1.5, 3.0, Color(0.85, 0.7, 0.55, 1), rng.randf_range(0.0, 0.06))
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
			var dsc := sand.darkened(0.3)
			emit(P_SMOKE, p + d * 0.5 * s, d * rng.randf_range(4.0, 7.0) * s, rng.randf_range(1.3, 2.4), 1.0 * s, 3.2 * s, 0.0, 2.5, Color(dsc.r, dsc.g, dsc.b, 0.75), 0.02)
	# kıvılcımlar
	for i in int(22 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1.5), rng.randf_range(-1, 1)).normalized()
		emit(P_SPARK, p + Vector3(0, 0.3, 0), d * rng.randf_range(8.0, 22.0) * sqrt(s), rng.randf_range(0.4, 1.1), 0.09, 0.07, 9.8, 1.2, Color(1.0, 0.7, 0.35, 1))
	# moloz parçaları: köşeli kırık parçalar (debris_tex), çoğu küçük, azı iri; dönerek uçar
	var dc := _sand().darkened(0.25)
	for i in int(14 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.6, 1.8), rng.randf_range(-1, 1)).normalized()
		var c := dc if rng.randf() < 0.6 else Color(0.15, 0.13, 0.12)
		var sz := (rng.randf_range(0.14, 0.24) if rng.randf() < 0.12 else rng.randf_range(0.04, 0.11)) * sqrt(s)
		emit(P_DEBRIS, p + Vector3(0, 0.2, 0), d * rng.randf_range(4.0, 13.0) * sqrt(s), rng.randf_range(1.6, 2.8), sz, sz, 13.0, 0.25, c, 0.0, rng.randf_range(-9, 9))

# toprak tacı: patlamadan yukarı/dışa fırlayan dikenli toprak çizgileri (mermi/top isabeti, havan)
func dirt_crown(p: Vector3, s: float) -> void:
	if has_flip_dust:
		# simüle edilmiş toprak sütunu (flipbook): fışkırıp yayılan, yavaş çöken toz
		var sand := _sand()
		var c := Color(lerpf(sand.r, 0.9, 0.3) * 1.1, sand.g * 1.05, sand.b, 0.95)
		emit(P_FLIPD, p + Vector3(0, 1.6 * s, 0), Vector3(0, 0.3, 0), rng.randf_range(2.6, 3.4), 5.0 * s, 7.5 * s, 0.0, 1.0, c, 0.0, rng.randf_range(-0.2, 0.2))
	var sand := _sand().darkened(0.35)
	for i in int(18 * s) + 6:
		var d := Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.9, 1.6), rng.randf_range(-0.6, 0.6)).normalized()
		var c := sand.lerp(Color(0.12, 0.1, 0.08), rng.randf() * 0.6)
		emit(P_STREAK, p, d * rng.randf_range(7.0, 16.0) * sqrt(s), rng.randf_range(0.7, 1.3), rng.randf_range(0.06, 0.14) * sqrt(s), rng.randf_range(0.04, 0.09), 14.0, 0.6, Color(c.r, c.g, c.b, 0.95))
	# toprak bulutu kolonu
	for i in int(6 * s) + 3:
		var g := _sand().darkened(rng.randf_range(0.1, 0.4))
		emit(P_SMOKE, p + _rv(0.4 * s, 0.1), Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(2.5, 6.0) * s, rng.randf_range(-0.6, 0.6)), rng.randf_range(1.6, 3.0), 0.6 * s, rng.randf_range(2.0, 3.4) * s, 1.4, 1.6, Color(g.r, g.g, g.b, 0.85), rng.randf_range(0.0, 0.1))

# büyük ateş topu: türbülanslı turuncu-sarı alev kütlesi, içinden kara duman çıkar
func fireball(p: Vector3, s: float) -> void:
	flash(p, 4.5 * s, 9.0 + 8.0 * s, 0.4 + 0.15 * s, Color(1.0, 0.6, 0.28))
	if has_flip:
		# simüle edilmiş ateş topu (flipbook): gerçek girdaplı alev + kara duman
		emit(P_FLIP, p + Vector3(0, 1.4 * s, 0), Vector3(0, 0.6, 0), rng.randf_range(1.5, 1.9), 6.5 * s, 8.5 * s, 0.0, 1.0, Color(1, 1, 1, 1), 0.0, rng.randf_range(-0.2, 0.2))
		if s > 1.2:
			emit(P_FLIP, p + Vector3(rng.randf_range(-1, 1), 1.0 * s, rng.randf_range(-1, 1)), Vector3(0, 0.8, 0), rng.randf_range(1.6, 2.0), 5.0 * s, 7.0 * s, 0.0, 1.0, Color(1, 1, 1, 0.9), 0.12, rng.randf_range(-0.3, 0.3))
	emit(P_FIRE, p + Vector3(0, 0.6 * s, 0), Vector3(0, 1.0, 0), 0.16, 2.0 * s, 3.8 * s, 0.0, 1.0, Color(1.1, 0.9, 0.65, 1))
	for i in int(34 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.2, 1.4), rng.randf_range(-1, 1)).normalized()
		var hot := rng.randf()
		var col := Color(0.95, 0.82, 0.62, 1.0) if hot < 0.3 else (Color(0.85, 0.6, 0.4, 1.0) if hot < 0.75 else Color(0.65, 0.32, 0.18, 1.0))
		emit(P_FIRE, p + d * rng.randf_range(0.2, 1.0) * s, d * rng.randf_range(2.0, 6.5) * s + Vector3(0, 1.5 * s, 0), rng.randf_range(0.7, 1.6), rng.randf_range(0.9, 1.6) * s, rng.randf_range(2.4, 4.2) * s, -2.2, 2.2, col, rng.randf_range(0.0, 0.18))
	# içten yükselen kara duman (alevin arasında)
	for i in int(22 * s):
		var d := Vector3(rng.randf_range(-1, 1), rng.randf_range(0.6, 1.8), rng.randf_range(-1, 1)).normalized()
		var g := rng.randf_range(0.04, 0.12)
		emit(P_SMOKE, p + d * 0.6 * s, d * rng.randf_range(1.5, 4.0) * s + Vector3(0, 2.2 * s, 0), rng.randf_range(4.0, 7.0), 1.6 * s, rng.randf_range(4.5, 7.5) * s, -0.6, 0.9, Color(g, g * 0.95, g * 0.9, 0.95), rng.randf_range(0.25, 0.7))
	# alev dilleri: yukarı fırlayan ince ateş jetleri
	for i in int(6 * s):
		var d := Vector3(rng.randf_range(-0.35, 0.35), 1.0, rng.randf_range(-0.35, 0.35)).normalized()
		for k in 5:
			emit(P_FIRE, p + d * k * 0.5 * s, d * rng.randf_range(8.0, 14.0) * s, rng.randf_range(0.4, 0.7), 0.5 * s, 1.2 * s, -1.0, 1.8, Color(0.9, 0.65, 0.4, 1), k * 0.03)

# mantar duman: hızla yükselen sap + üstte yayılan kara başlık
func mushroom(p: Vector3, s: float) -> void:
	for i in int(16 * s):
		var g := rng.randf_range(0.05, 0.13)
		emit(P_SMOKE, p + _rv(0.5 * s, 0.2), Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(9.0, 14.0) * s, rng.randf_range(-0.5, 0.5)), rng.randf_range(5.0, 8.0), 1.2 * s, rng.randf_range(3.0, 4.5) * s, 0.0, 1.0, Color(g, g, g, 0.9), rng.randf_range(0.1, 0.5))
	for i in int(14 * s):
		var a := rng.randf() * TAU
		var g := rng.randf_range(0.06, 0.15)
		emit(P_SMOKE, p + Vector3(0, 9.0 * s, 0), Vector3(cos(a) * rng.randf_range(2.0, 4.0), rng.randf_range(1.0, 2.5), sin(a) * rng.randf_range(2.0, 4.0)) * s, rng.randf_range(6.0, 9.0), 2.5 * s, rng.randf_range(6.0, 9.0) * s, -0.15, 0.8, Color(g, g, g, 0.9), rng.randf_range(0.6, 1.2))

# uzun süren yangın + kara duman sütunu (yanan araç)
func cookoff(p: Vector3, dur: float, pw := 1.0) -> void:
	emitters.append([p, G.time + dur, "jet", pw, 0.0])

func fire_column(p: Vector3, dur: float, pw := 1.0) -> void:
	emitters.append([p, G.time + dur, "column", pw, 0.0])

# suya düşen mermi/patlama: beyaz su sütunu + halka + serpinti
func water_splash(p: Vector3, s: float) -> void:
	for i in int(14 * s) + 4:
		var d := Vector3(rng.randf_range(-0.25, 0.25), 1.0, rng.randf_range(-0.25, 0.25)).normalized()
		emit(P_STREAK, Vector3(p.x, 0.0, p.z), d * rng.randf_range(6.0, 13.0) * sqrt(s), rng.randf_range(0.7, 1.2), 0.12 * s, 0.08, 9.8, 0.8, Color(0.85, 0.92, 0.95, 0.9))
	for i in int(10 * s) + 3:
		emit(P_SMOKE, Vector3(p.x, 0.2, p.z) + _rv(0.4 * s, 0.1), Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(2.0, 5.0) * s, rng.randf_range(-0.6, 0.6)), rng.randf_range(1.2, 2.2), 0.6 * s, rng.randf_range(2.0, 3.2) * s, 3.0, 1.6, Color(0.88, 0.93, 0.96, 0.75), rng.randf_range(0.0, 0.1))
	for i in 16:
		var a := TAU * i / 16.0
		emit(P_SMOKE, Vector3(p.x, 0.1, p.z), Vector3(cos(a), 0.05, sin(a)) * rng.randf_range(2.0, 4.0) * s, rng.randf_range(0.8, 1.4), 0.5 * s, 1.6 * s, 0.0, 2.5, Color(0.92, 0.96, 0.98, 0.6))

# zırhı delen isabet: içe doğru metal parçacık + kıvılcım duşu + kapaklardan sızan duman
func penetration(p: Vector3, dir: Vector3, heat: bool) -> void:
	flash(p, 4.0 if heat else 3.0, 6.0, 0.1, Color(1.0, 0.7, 0.35) if heat else Color(1.0, 0.85, 0.6))
	for i in 18:
		var d := (dir + _rv(0.7)).normalized()
		emit(P_SPARK, p, d * rng.randf_range(8.0, 18.0), rng.randf_range(0.2, 0.5), 0.06, 0.04, 9.8, 1.5, Color(1.0, 0.8, 0.45))
	if heat:
		emit(P_FIRE, p, dir * 3.0, 0.15, 0.6, 1.4, 0.0, 3.0, Color(1.0, 0.8, 0.55, 1))
	for i in 6:
		var g := rng.randf_range(0.15, 0.3)
		emit(P_SMOKE, p + Vector3(0, 0.4, 0), Vector3(rng.randf_range(-0.4, 0.4), rng.randf_range(1.5, 3.0), rng.randf_range(-0.4, 0.4)), rng.randf_range(2.0, 3.5), 0.4, 1.8, -0.2, 1.2, Color(g, g, g, 0.7), rng.randf_range(0.0, 0.3))

# sekme: geliş açısına göre yansıyan kıvılcım yelpazesi
func ricochet(p: Vector3, dir: Vector3, nrm: Vector3) -> void:
	var r := (dir - nrm * 2.0 * dir.dot(nrm)).normalized()
	for i in 14:
		emit(P_SPARK, p, (r + _rv(0.35)).normalized() * rng.randf_range(10.0, 22.0), rng.randf_range(0.15, 0.35), 0.05, 0.035, 6.0, 1.0, Color(1.0, 0.9, 0.6))
	flash(p, 2.0, 4.0, 0.06, Color(1.0, 0.9, 0.7))

# yüzeye göre el bombası/küçük patlama ek efekti
func surface_burst(p: Vector3, s: float) -> void:
	var c: Color
	match G.map_kind:
		"winter":
			c = Color(0.9, 0.92, 0.96)
		"desert":
			c = Color(0.82, 0.68, 0.46)
		_:
			c = Color(0.3, 0.24, 0.17)
	if G.grid.height_at(p) > 0.05 or G.grid.kind_at(p) in [Grid.K_HOUSE, Grid.K_WALL]:
		c = Color(0.75, 0.73, 0.7)   # beton/taş tozu
	for i in int(10 * s) + 4:
		var a := rng.randf() * TAU
		var d := Vector3(cos(a), rng.randf_range(0.3, 1.2), sin(a)).normalized()
		emit(P_STREAK, p, d * rng.randf_range(5.0, 10.0) * sqrt(s), rng.randf_range(0.4, 0.8), 0.06 * s, 0.04, 12.0, 0.8, Color(c.r, c.g, c.b, 0.95))
	for i in int(6 * s) + 2:
		emit(P_SMOKE, p + _rv(0.5 * s, 0.1), Vector3(rng.randf_range(-1, 1), rng.randf_range(0.5, 2.0), rng.randf_range(-1, 1)) * s, rng.randf_range(1.5, 2.6), 0.6 * s, 2.4 * s, 0.3, 1.5, Color(c.r, c.g, c.b, 0.7))

# yere yakın sabit sis kümesi (ormanlık / nehir kıyısı)
func ground_mist(p: Vector3, r: float) -> void:
	emitters.append([p, 1e9, "mist", r, rng.randf() * 3.0])

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
			for i in 3:
				var dc := sand.darkened(0.3)
				emit(P_STREAK, p, Vector3(rng.randf_range(-1.2, 1.2), rng.randf_range(3.5, 6.0), rng.randf_range(-1.2, 1.2)), rng.randf_range(0.3, 0.5), 0.035, 0.02, 12.0, 0.8, Color(dc.r, dc.g, dc.b, 0.9))
		"wall":
			emit(P_SMOKE, p, Vector3(rng.randf_range(-0.5, 0.5), rng.randf_range(0.4, 1.2), rng.randf_range(-0.5, 0.5)), rng.randf_range(0.6, 1.0), 0.2, 0.8, 0.5, 1.5, Color(0.85, 0.8, 0.72, 0.8))
			for i in 3:
				emit(P_DEBRIS, p, Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(1.0, 3.0), rng.randf_range(-2.0, 2.0)), 0.7, 0.05, 0.05, 12.0, 0.3, Color(0.8, 0.76, 0.66))
		"metal":
			for i in 5:
				emit(P_SPARK, p, Vector3(rng.randf_range(-4, 4), rng.randf_range(1, 5), rng.randf_range(-4, 4)), rng.randf_range(0.15, 0.35), 0.05, 0.04, 9.8, 1.0, Color(1.0, 0.85, 0.5))
		"blood":
			emit(P_SMOKE, p, Vector3(rng.randf_range(-0.6, 0.6), rng.randf_range(0.3, 1.0), rng.randf_range(-0.6, 0.6)), 0.4, 0.12, 0.45, 3.0, 2.0, Color(0.42, 0.03, 0.02, 0.85))
			for i in 6:
				emit(P_STREAK, p, Vector3(rng.randf_range(-2.0, 2.0), rng.randf_range(0.5, 2.5), rng.randf_range(-2.0, 2.0)), rng.randf_range(0.35, 0.6), 0.03, 0.02, 10.0, 0.6, Color(0.38, 0.02, 0.02, 0.95))
			if rng.randf() < 0.6:
				_decal(Vector3(p.x + rng.randf_range(-0.6, 0.6), 0.0, p.z + rng.randf_range(-0.6, 0.6)), rng.randf_range(0.25, 0.55), scorch_tex, Color(0.3, 0.02, 0.01, 0.8))

func rocket_trail(p: Vector3, dir := Vector3.ZERO) -> void:
	# ince, uzun duman izi + motor alevi (parlak çekirdek, turuncu kuyruk)
	emit(P_SMOKE, p, _rv(0.12), rng.randf_range(3.5, 5.5), 0.45, 1.4, -0.05, 1.6, Color(0.93, 0.92, 0.9, 0.55))
	emit(P_SMOKE, p - dir * 0.5, _rv(0.12), rng.randf_range(3.5, 5.5), 0.45, 1.4, -0.05, 1.6, Color(0.93, 0.92, 0.9, 0.55))
	# motor alevi: hıza göre uzayan parlak çizgi (top değil)
	emit(P_SPARK, p, -dir * 40.0, 0.05, 0.14, 0.08, 0.0, 6.0, Color(1.0, 0.75, 0.35, 1))

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

func blood_pool(p: Vector3, big := false) -> void:
	_decal(p, rng.randf_range(0.6, 1.1) if big else rng.randf_range(0.3, 0.55), scorch_tex, Color(0.3, 0.02, 0.01, 0.8))

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
