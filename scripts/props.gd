class_name Props extends Node3D
# Dekor nesneleri: palmiye, ağaç, sivil araba, direk, tente, sandık… (bir kısmı hasar alır)

var items: Array = []   # {node, pos, kind, hp, alive, r}
var _cache := {}
var rng := RandomNumberGenerator.new()
var winter := false

func _ready() -> void:
	rng.seed = 4242

func _cached(key: String, maker: Callable) -> Mesh:
	if not _cache.has(key):
		_cache[key] = maker.call()
	return _cache[key]

func _place(mesh: Mesh, p: Vector3, rot: float, s := 1.0, shadow := true) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = p
	mi.rotation.y = rot
	mi.scale = Vector3(s, s, s)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON if shadow else GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(mi)
	return mi

# ------------------------------------------------------------ palmiye
func palm(p: Vector3) -> void:
	var v := rng.randi() % 5
	var mesh := _cached("palm%d" % v, func(): return _palm_mesh(v))
	var mi := _place(mesh, p, rng.randf() * TAU, rng.randf_range(0.85, 1.15))
	items.append({"node": mi, "pos": p, "kind": "tree", "hp": 60.0, "alive": true, "r": 0.4})
	G.grid.set_static_circle(p, 0.3, 3.0, Grid.K_TREE)

func _palm_mesh(seed_v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 100 + seed_v
	var trunk := MB.new()
	var leaves := MB.new()
	var H := r.randf_range(5.5, 8.0)
	var lean := Vector3(r.randf_range(-1, 1), 0, r.randf_range(-1, 1)).normalized() * r.randf_range(0.6, 2.2)
	var segs := 9
	var prev := Vector3.ZERO
	for i in segs:
		var t1 := float(i + 1) / segs
		var q := lean * pow(t1, 1.7) + Vector3(0, H * t1, 0)
		var c := Color(0.42, 0.33, 0.22) if i % 2 == 0 else Color(0.36, 0.28, 0.19)
		trunk.cyl_between(prev, q, lerpf(0.24, 0.15, float(i) / segs), lerpf(0.24, 0.15, t1), 7, c, false)
		prev = q
	var top := prev
	trunk.sphere(top, Vector3(0.28, 0.32, 0.28), 6, 4, Color(0.35, 0.3, 0.2))
	var n := r.randi_range(11, 14)
	for i in n:
		var a := TAU * i / n + r.randf_range(-0.2, 0.2)
		var el := r.randf_range(0.15, 0.75)
		var L := r.randf_range(2.6, 3.6)
		var droop := r.randf_range(1.0, 1.8)
		var hd := Vector3(cos(a), 0, sin(a))
		var side := Vector3(-hd.z, 0, hd.x)
		var dead := r.randf() < 0.12
		var base_c := Color(0.045, 0.1, 0.03) if not dead else Color(0.36, 0.3, 0.17)
		if dead:
			el = -0.9
		var steps := 7
		var pts: Array = []
		for s in steps + 1:
			var t := float(s) / steps
			pts.append(top + hd * cos(el) * L * t + Vector3(0, sin(el) * L * t - droop * t * t * L * 0.35, 0))
		for s in steps:
			var t0 := float(s) / steps
			var t1 := float(s + 1) / steps
			var w0 := sin(PI * minf(t0 * 1.15, 1.0)) * 0.42 + 0.04
			var w1 := sin(PI * minf(t1 * 1.15, 1.0)) * 0.42 + 0.04
			var p0: Vector3 = pts[s]
			var p1: Vector3 = pts[s + 1]
			var fwd := (p1 - p0).normalized()
			var col := MB.jit(base_c, r, 0.12)
			for sg in [-1.0, 1.0]:
				# yaprakçık: dış uç geriye ve aşağı
				var o0 = p0 + side * sg * w0 - fwd * 0.12 + Vector3(0, -0.18 * w0, 0)
				var o1 = p1 + side * sg * w1 - fwd * 0.18 + Vector3(0, -0.22 * w1, 0)
				leaves.quad(p0, p1, o1, o0, col if sg > 0 else col.darkened(0.12), Vector3(0, 1, 0))
	for i in 4:
		var a := r.randf() * TAU
		trunk.sphere(top + Vector3(cos(a) * 0.25, -0.25, sin(a) * 0.25), Vector3(0.11, 0.11, 0.11), 5, 4, Color(0.38, 0.3, 0.12))
	var m := trunk.commit(Mats.vc())
	return leaves.commit(Mats.vc2(), m)

# ------------------------------------------------------------ yapraklı ağaç (kış: sarı kuru yaprak + kar, çöl: koyu yeşil)
func tree(p: Vector3) -> void:
	var v := rng.randi() % 5
	var key := ("wtree%d" if winter else "dtree%d") % v
	var mesh := _cached(key, func(): return _tree_mesh(v, winter))
	var mi := _place(mesh, p, rng.randf() * TAU, rng.randf_range(0.8, 1.2))
	items.append({"node": mi, "pos": p, "kind": "tree", "hp": 70.0, "alive": true, "r": 0.4})
	G.grid.set_static_circle(p, 0.3, 3.0, Grid.K_TREE)

func _leaf_material() -> StandardMaterial3D:
	if not _cache.has("leafmat"):
		var S := 128
		var im := Image.create(S, S, false, Image.FORMAT_RGBA8)
		im.fill(Color(0, 0, 0, 0))
		var r := RandomNumberGenerator.new()
		r.seed = 77
		for i in 140:
			var cx := r.randf_range(8, S - 8)
			var cy := r.randf_range(8, S - 8)
			var dd := Vector2(cx - S * 0.5, cy - S * 0.5).length() / (S * 0.5)
			if dd > 0.95 or r.randf() < dd * 0.5:
				continue
			var a := r.randf() * TAU
			var lw := r.randf_range(3.0, 6.0)
			var lh := lw * r.randf_range(1.6, 2.2)
			var sh := r.randf_range(0.65, 1.0) * (1.0 - dd * 0.25)
			var ca := cos(a)
			var sa := sin(a)
			for y in range(int(cy - lh), int(cy + lh) + 1):
				for x in range(int(cx - lh), int(cx + lh) + 1):
					if x < 0 or y < 0 or x >= S or y >= S:
						continue
					var dx := x - cx
					var dy := y - cy
					var u := (dx * ca + dy * sa) / lh
					var v := (-dx * sa + dy * ca) / lw
					if u * u + v * v <= 1.0:
						var lit := sh * (0.85 + 0.15 * (-u))
						im.set_pixel(x, y, Color(lit, lit, lit, 1))
		im.generate_mipmaps()
		var m := StandardMaterial3D.new()
		m.albedo_texture = ImageTexture.create_from_image(im)
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.5
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.9
		_cache["leafmat"] = m
	return _cache["leafmat"]

func _leaf_cards(st: SurfaceTool, r: RandomNumberGenerator, center: Vector3, radius: float, n: int, cols: Array, snow := false) -> void:
	for i in n:
		var c := center + Vector3(r.randf_range(-1, 1), r.randf_range(-0.7, 0.8), r.randf_range(-1, 1)).normalized() * radius * pow(r.randf(), 0.4)
		var bas := Basis(Vector3(r.randf_range(-1, 1), r.randf_range(0.2, 1.0), r.randf_range(-1, 1)).normalized(), r.randf() * TAU)
		var s := r.randf_range(0.45, 0.8) * radius * 0.7
		var col: Color = cols[r.randi() % cols.size()]
		# üstteki kartlar daha açık (güneş), alttakiler koyu
		var k := clampf((c.y - center.y) / maxf(radius, 0.1) * 0.5 + 0.5, 0.0, 1.0)
		col = col.darkened(0.25 * (1.0 - k)).lightened(0.1 * k)
		if snow and c.y > center.y + radius * 0.2 and r.randf() < 0.5:
			col = Color(0.92, 0.94, 0.97)
		var q := [bas * Vector3(-s, 0, -s), bas * Vector3(s, 0, -s), bas * Vector3(s, 0, s), bas * Vector3(-s, 0, s)]
		var uv := [Vector2(0, 0), Vector2(1, 0), Vector2(1, 1), Vector2(0, 1)]
		var nrm := (c - center).normalized()
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_color(col)
			st.set_normal(nrm.lerp(Vector3.UP, 0.4).normalized())
			st.set_uv(uv[idx])
			st.add_vertex(c + q[idx])

func _tree_mesh(seed_v: int, win: bool) -> ArrayMesh:
	if not win:
		return _leafy_tree(seed_v)
	return _tree_mesh_old(seed_v, win)

func _leafy_tree(seed_v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 1300 + seed_v
	var wood := MB.new()
	var H := r.randf_range(2.4, 3.6)
	var trunk_c := Color(0.32, 0.25, 0.18)
	wood.cyl(Vector3.ZERO, 0.2, 0.12, H, 7, trunk_c, Basis(), false)
	var tips: Array = [Vector3(0, H + 1.2, 0)]
	var nb := r.randi_range(4, 6)
	for i in nb:
		var a := TAU * i / nb + r.randf_range(-0.4, 0.4)
		var b0 := Vector3(0, H * r.randf_range(0.55, 0.95), 0)
		var b1 := b0 + Vector3(cos(a) * r.randf_range(1.0, 1.8), r.randf_range(0.8, 1.6), sin(a) * r.randf_range(1.0, 1.8))
		wood.cyl_between(b0, b1, 0.09, 0.04, 5, trunk_c, false)
		tips.append(b1)
	var m := wood.commit(Mats.vc())
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := [Color(0.22, 0.36, 0.12), Color(0.28, 0.42, 0.14), Color(0.18, 0.3, 0.1), Color(0.34, 0.46, 0.16)]
	for t in tips:
		_leaf_cards(st, r, t, r.randf_range(1.1, 1.6), r.randi_range(22, 32), cols)
	st.set_material(_leaf_material())
	return st.commit(m)

func _tree_mesh_old(seed_v: int, win: bool) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 300 + seed_v
	var wood := MB.new()
	var leaf := MB.new()
	var H := r.randf_range(3.0, 4.2) if win else r.randf_range(2.0, 3.0)
	var trunk_c := Color(0.33, 0.28, 0.23) if win else Color(0.3, 0.24, 0.17)
	wood.cyl(Vector3.ZERO, 0.17, 0.11, H, 7, trunk_c, Basis(), false)
	var tips: Array = []
	var nb := r.randi_range(4, 6)
	for i in nb:
		var a := TAU * i / nb + r.randf_range(-0.3, 0.3)
		var h0 := H * r.randf_range(0.45, 0.95)
		var b0 := Vector3(0, h0, 0)
		var b1 := b0 + Vector3(cos(a) * r.randf_range(1.0, 1.9), r.randf_range(1.0, 2.0), sin(a) * r.randf_range(1.0, 1.9))
		wood.cyl_between(b0, b1, 0.08, 0.04, 5, trunk_c, false)
		tips.append(b1)
		for j in 2:
			var a2 := a + r.randf_range(-0.9, 0.9)
			var b2 := b1 + Vector3(cos(a2) * r.randf_range(0.5, 1.1), r.randf_range(0.4, 1.0), sin(a2) * r.randf_range(0.5, 1.1))
			wood.cyl_between(b1, b2, 0.04, 0.015, 4, trunk_c, false)
			tips.append(b2)
	tips.append(Vector3(0, H + 0.6, 0))
	if win:
		var cols := [Color(0.86, 0.64, 0.3), Color(0.78, 0.55, 0.24), Color(0.92, 0.75, 0.42), Color(0.7, 0.48, 0.25)]
		for t in tips:
			var nleaf := r.randi_range(38, 55)
			for k in nleaf:
				var c: Vector3 = t + Vector3(r.randf_range(-0.9, 0.9), r.randf_range(-0.7, 0.7), r.randf_range(-0.9, 0.9)) * pow(r.randf(), 0.5)
				var bas := Basis(Vector3(r.randf(), r.randf(), r.randf()).normalized(), r.randf() * TAU)
				var s := r.randf_range(0.09, 0.17)
				var col: Color = cols[r.randi() % 4]
				if c.y > H and r.randf() < 0.3:
					col = Color(0.95, 0.96, 0.98)
				leaf.quad(c + bas * Vector3(-s, 0, -s), c + bas * Vector3(s, 0, -s), c + bas * Vector3(s, 0, s), c + bas * Vector3(-s, 0, s), col, bas.y)
	else:
		for t in tips:
			leaf.sphere(t, Vector3(0.9, 0.75, 0.9) * r.randf_range(0.7, 1.1), 7, 5, MB.jit(Color(0.16, 0.27, 0.12), r, 0.15), Basis(), false, 0.25, r)
	var m := wood.commit(Mats.vc())
	return leaf.commit(Mats.vc2() if win else Mats.vc(), m)

# ------------------------------------------------------------ sivil araba
func car(p: Vector3, rot: float, color_idx := -1) -> void:
	var v := color_idx if color_idx >= 0 else rng.randi() % 5
	var mesh := _cached("car%d" % v, func(): return car_mesh(v))
	var mi := _place(mesh, p, rot)
	items.append({"node": mi, "pos": p, "kind": "car", "hp": 50.0, "alive": true, "r": 1.6})
	G.grid.set_static_rect(p, Vector2(4.2, 1.8), rot, 1.25, Grid.K_WRECK)

static func car_mesh(v: int) -> ArrayMesh:
	var cols := [Color(0.07, 0.09, 0.18), Color(0.05, 0.05, 0.06), Color(0.1, 0.12, 0.22), Color(0.75, 0.75, 0.73), Color(0.08, 0.08, 0.1)]
	var c: Color = cols[v % cols.size()]
	var mb := MB.new()
	var glass := Color(0.05, 0.06, 0.08)
	mb.box(Vector3(0, 0.55, 0), Vector3(4.3, 0.55, 1.8), c)
	mb.hull(Vector3(-0.2, 0.82, 0), Vector2(2.3, 1.7), Vector2(1.6, 1.4), 0.5, glass)
	mb.box(Vector3(-0.2, 1.33, 0), Vector3(1.6, 0.05, 1.42), c)
	mb.box(Vector3(2.12, 0.62, 0), Vector3(0.08, 0.25, 1.5), Color(0.6, 0.6, 0.55))
	for x in [-1.35, 1.35]:
		for z in [-0.93, 0.71]:
			mb.cyl(Vector3(x, 0.33, z), 0.33, 0.33, 0.22, 10, Color(0.05, 0.05, 0.05), Basis(Vector3.RIGHT, PI * 0.5))
	# yerel X ekseni araba boyu; mesh +X ileri
	return mb.commit(Mats.metal())

# ------------------------------------------------------------ direkler / tente / sandık
func pole(p: Vector3, lamp := false) -> void:
	var mesh := _cached("lamp" if lamp else "pole", func(): return _pole_mesh(lamp))
	var mi := _place(mesh, p, rng.randf_range(-0.1, 0.1) + (PI * 0.25 if not lamp else rng.randf() * TAU))
	items.append({"node": mi, "pos": p, "kind": "tree", "hp": 30.0, "alive": true, "r": 0.2})

func _pole_mesh(lamp: bool) -> ArrayMesh:
	var mb := MB.new()
	if lamp:
		mb.cyl(Vector3.ZERO, 0.08, 0.06, 5.0, 6, Color(0.25, 0.25, 0.27))
		mb.box(Vector3(0.6, 4.95, 0), Vector3(1.3, 0.06, 0.06), Color(0.25, 0.25, 0.27))
		mb.box(Vector3(1.2, 4.88, 0), Vector3(0.4, 0.1, 0.18), Color(0.2, 0.2, 0.2))
	else:
		mb.cyl(Vector3.ZERO, 0.12, 0.09, 7.5, 6, Color(0.36, 0.28, 0.2))
		mb.box(Vector3(0, 7.1, 0), Vector3(1.8, 0.1, 0.1), Color(0.33, 0.26, 0.19))
		for x in [-0.75, 0.0, 0.75]:
			mb.cyl(Vector3(x, 7.15, 0), 0.04, 0.03, 0.15, 5, Color(0.6, 0.62, 0.6))
	return mb.commit(Mats.vc())

func canopy(p: Vector3, rot: float) -> void:
	var mesh := _cached("canopy", func():
		var mb := MB.new()
		for x in [-0.95, 0.95]:
			for z in [-0.95, 0.95]:
				mb.cyl(Vector3(x, 0, z), 0.04, 0.04, 2.2, 5, Color(0.4, 0.38, 0.35))
		var c := Color(0.86, 0.8, 0.66)
		var tp := Vector3(0, 2.55, 0)
		var cs := [Vector3(-1.15, 2.2, -1.15), Vector3(1.15, 2.2, -1.15), Vector3(1.15, 2.2, 1.15), Vector3(-1.15, 2.2, 1.15)]
		for i in 4:
			mb.tri(tp, cs[i], cs[(i + 1) % 4], c.darkened(0.06 * i), Vector3.UP)
		return mb.commit(Mats.vc2()))
	_place(mesh, p, rot)

func crate(p: Vector3, rot: float, s := 1.0) -> void:
	var mesh := _cached("crate", func():
		var mb := MB.new()
		mb.box(Vector3(0, 0.35, 0), Vector3(1.1, 0.7, 0.7), Color(0.45, 0.4, 0.26))
		mb.box(Vector3(0, 0.71, 0), Vector3(1.12, 0.03, 0.2), Color(0.35, 0.3, 0.2))
		return mb.commit(Mats.vc()))
	_place(mesh, p, rot, s)

func barrel(p: Vector3, col := Color(0.25, 0.32, 0.2)) -> void:
	var key := "barrel" + col.to_html()
	var mesh := _cached(key, func():
		var mb := MB.new()
		mb.cyl(Vector3.ZERO, 0.3, 0.3, 0.9, 9, col)
		mb.cyl(Vector3(0, 0.3, 0), 0.31, 0.31, 0.05, 9, col.darkened(0.2))
		return mb.commit(Mats.metal()))
	_place(mesh, p, rng.randf() * TAU)

func shed(p: Vector3, rot: float) -> void:
	var mesh := _cached("shed", func():
		var mb := MB.new()
		mb.box(Vector3(0, 1.0, 0), Vector3(2.6, 2.0, 2.0), Color(0.78, 0.74, 0.66))
		mb.prism(PackedVector2Array([Vector2(-1.55, 2.0), Vector2(1.55, 2.0), Vector2(0, 2.8)]), 2.4, Color(0.55, 0.55, 0.58), Vector3.ZERO, Basis(), Color(0.78, 0.74, 0.66))
		mb.box(Vector3(0, 0.8, 1.01), Vector3(0.9, 1.6, 0.04), Color(0.4, 0.3, 0.2))
		return mb.commit(Mats.vc()))
	_place(mesh, p, rot)
	G.grid.set_static_rect(p, Vector2(2.6, 2.0), rot, 2.0, Grid.K_HOUSE)

# ------------------------------------------------------------ hasar
func blast(center: Vector3, radius: float, dmg: float) -> void:
	for it in items:
		if not it["alive"]:
			continue
		var p: Vector3 = it["pos"]
		var d := Vector2(p.x - center.x, p.z - center.z).length()
		if d > radius + it["r"]:
			continue
		it["hp"] -= dmg * (1.0 - clampf(d / (radius + it["r"]), 0.0, 0.9))
		if it["hp"] <= 0.0:
			_destroy(it, center)

func crush(center: Vector3, r: float, dir: Vector3) -> void:
	for it in items:
		if not it["alive"] or it["kind"] != "tree":
			continue
		var p: Vector3 = it["pos"]
		if Vector2(p.x - center.x, p.z - center.z).length() < r:
			_fell(it, dir)

func _destroy(it: Dictionary, center: Vector3) -> void:
	it["alive"] = false
	var mi: MeshInstance3D = it["node"]
	match it["kind"]:
		"car":
			mi.material_override = Mats.burnt()
			G.fx.burn(it["pos"] + Vector3(0, 0.8, 0), rng.randf_range(15, 30), 0.7)
			G.fx.explosion(it["pos"] + Vector3(0, 0.6, 0), 1.2, "big")
			Sfx.play3d("expl_med", it["pos"], 0.0)
			var tw := create_tween()
			tw.tween_property(mi, "position:y", 0.6, 0.15).set_ease(Tween.EASE_OUT)
			tw.tween_property(mi, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
		"tree":
			var away: Vector3 = it["pos"] - center
			away.y = 0
			_fell(it, away.normalized() if away.length() > 0.1 else Vector3.RIGHT)
		_:
			mi.visible = false

func _fell(it: Dictionary, dir: Vector3) -> void:
	it["alive"] = false
	var mi: MeshInstance3D = it["node"]
	var axis := Vector3(dir.z, 0, -dir.x).normalized()
	if axis.length() < 0.1:
		axis = Vector3.RIGHT
	var start := mi.transform.basis
	var tw := create_tween()
	tw.tween_method(func(t: float):
		mi.transform.basis = Basis(axis, t * 1.45) * start, 0.0, 1.0, 1.1).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
	G.grid.set_static_circle(it["pos"], 0.4, 0.0, Grid.K_NONE, true)
	Sfx.play3d("crumble", it["pos"], -4.0)

func clear_area(c: Vector3, r: float) -> void:
	for it in items:
		if not it["alive"]:
			continue
		var p: Vector3 = it["pos"]
		if Vector2(p.x - c.x, p.z - c.z).length() < r:
			it["alive"] = false
			(it["node"] as Node3D).visible = false
			G.grid.set_static_circle(p, 0.5, 0.0, Grid.K_NONE, true)

# ------------------------------------------------------------ bitki örtüsü (çam, çalı, kaya, saman, ot, kamış)
func pine(p: Vector3) -> void:
	var v := rng.randi() % 4
	var key := ("pine_w%d" if winter else "pine%d") % v
	var mesh := _cached(key, func(): return _pine_mesh(v, winter))
	var mi := _place(mesh, p, rng.randf() * TAU, rng.randf_range(0.8, 1.25))
	items.append({"node": mi, "pos": p, "kind": "tree", "hp": 70.0, "alive": true, "r": 0.4})
	G.grid.set_static_circle(p, 0.3, 3.0, Grid.K_TREE)

func _pine_mesh(seed_v: int, win: bool) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 500 + seed_v
	var wood := MB.new()
	var nd := MB.new()
	var H := r.randf_range(5.5, 8.0)
	wood.cyl(Vector3.ZERO, 0.16, 0.06, H, 6, Color(0.3, 0.22, 0.16), Basis(), false)
	var layers := r.randi_range(7, 10)
	for i in layers:
		var t := float(i) / layers
		var y := lerpf(H * 0.22, H * 0.95, t)
		var rad := lerpf(1.6, 0.25, t) * r.randf_range(0.85, 1.1)
		var n := r.randi_range(6, 9)
		for k in n:
			var a := TAU * k / n + r.randf_range(-0.2, 0.2) + i * 0.4
			var tip := Vector3(cos(a) * rad, y - rad * 0.45, sin(a) * rad)
			var base := Vector3(0, y + 0.1, 0)
			var side := Vector3(-sin(a), 0, cos(a)) * rad * 0.42
			var col := MB.jit(Color(0.1, 0.2, 0.12), r, 0.15)
			nd.tri(base, tip + side, tip - side, col, Vector3.UP)
			if win and r.randf() < 0.55:
				nd.tri(base + Vector3(0, 0.04, 0), (tip + side) * 0.8 + base * 0.2 + Vector3(0, 0.06, 0), (tip - side) * 0.8 + base * 0.2 + Vector3(0, 0.06, 0), Color(0.93, 0.95, 0.98), Vector3.UP)
	var m := wood.commit(Mats.vc())
	return nd.commit(Mats.vc2(), m)

func bush(p: Vector3, big := false) -> void:
	var v := rng.randi() % 5
	var key := ("bushw%d" if winter else "bush%d") % v
	var mesh := _cached(key, func(): return _bush_mesh(v))
	_place(mesh, p, rng.randf() * TAU, rng.randf_range(0.8, 1.4) * (1.6 if big else 1.0))

func _bush_mesh(v: int) -> ArrayMesh:
	var r0 := RandomNumberGenerator.new()
	r0.seed = 700 + v
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var cols := [Color(0.2, 0.32, 0.1), Color(0.26, 0.38, 0.12), Color(0.16, 0.27, 0.09), Color(0.32, 0.4, 0.14)] if not winter else [Color(0.36, 0.3, 0.22), Color(0.3, 0.26, 0.2)]
	for i in r0.randi_range(2, 4):
		var c := Vector3(r0.randf_range(-0.5, 0.5), r0.randf_range(0.35, 0.6), r0.randf_range(-0.5, 0.5))
		_leaf_cards(st, r0, c, r0.randf_range(0.5, 0.8), r0.randi_range(10, 16), cols, winter)
	st.set_material(_leaf_material())
	return st.commit()

func _bush_mesh_old(v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 700 + v
	var mb := MB.new()
	var base_c := Color(0.16, 0.26, 0.1) if not winter else Color(0.3, 0.26, 0.2)
	for i in r.randi_range(3, 6):
		var c := Vector3(r.randf_range(-0.6, 0.6), r.randf_range(0.3, 0.7), r.randf_range(-0.6, 0.6))
		var rad := r.randf_range(0.35, 0.7)
		var col := MB.jit(base_c, r, 0.25)
		if r.randf() < 0.3 and not winter:
			col = col.lerp(Color(0.45, 0.5, 0.15), 0.4)
		mb.sphere(c, Vector3(rad, rad * 0.8, rad), 6, 4, col, Basis(), false, 0.3, r)
		if winter:
			mb.sphere(c + Vector3(0, rad * 0.35, 0), Vector3(rad * 0.8, rad * 0.4, rad * 0.8), 6, 3, Color(0.94, 0.95, 0.98), Basis(), true, 0.2, r)
	return mb.commit(Mats.vc())

func rock(p: Vector3, s := 1.0) -> void:
	var v := rng.randi() % 4
	var mesh := _cached("rock%d" % v, func(): return _rock_mesh(v))
	_place(mesh, p, rng.randf() * TAU, s)
	if s > 0.9:
		G.grid.set_static_circle(p, 0.7 * s, 0.8 * s, Grid.K_WRECK)

func _rock_mesh(v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 900 + v
	var mb := MB.new()
	mb.sphere(Vector3(0, 0.25, 0), Vector3(0.9, 0.6, 0.75), 7, 5, Color(0.42, 0.42, 0.42), Basis(), false, 0.28, r)
	mb.sphere(Vector3(0.5, 0.15, 0.3), Vector3(0.5, 0.35, 0.45), 6, 4, Color(0.38, 0.38, 0.37), Basis(), false, 0.3, r)
	return mb.commit(Mats.stone())

func hay(p: Vector3) -> void:
	var mesh := _cached("hay", func(): return _hay_mesh())
	_place(mesh, p, rng.randf() * TAU)
	G.grid.set_static_circle(p, 0.6, 1.1, Grid.K_WRECK)

func _hay_mesh() -> ArrayMesh:
	var mb := MB.new()
	mb.cyl(Vector3(-0.6, 0.6, 0), 0.6, 0.6, 1.2, 12, Color(0.86, 0.68, 0.3), Basis(Vector3.FORWARD, PI * 0.5))
	return mb.commit(Mats.vc())

func _grass_material() -> StandardMaterial3D:
	if not _cache.has("grassmat"):
		var S := 128
		var im := Image.create(S, S, false, Image.FORMAT_RGBA8)
		im.fill(Color(0, 0, 0, 0))
		var r := RandomNumberGenerator.new()
		r.seed = 31
		for b in 26:
			var x0 := r.randf_range(10, S - 10)
			var lean := r.randf_range(-22, 22)
			var hgt := r.randf_range(0.45, 1.0) * S
			var w := r.randf_range(2.0, 4.5)
			var shade := r.randf_range(0.7, 1.0)
			for y in int(hgt):
				var t := float(y) / hgt
				var cx := x0 + lean * t * t
				var ww := w * (1.0 - t)
				for x in range(int(cx - ww), int(cx + ww) + 1):
					if x >= 0 and x < S:
						im.set_pixel(x, S - 1 - y, Color(shade * (0.6 + 0.4 * t), shade * (0.75 + 0.25 * t), shade * 0.5, 1))
		im.generate_mipmaps()
		var m := StandardMaterial3D.new()
		m.albedo_texture = ImageTexture.create_from_image(im)
		m.vertex_color_use_as_albedo = true
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
		m.alpha_scissor_threshold = 0.45
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		m.roughness = 0.95
		_cache["grassmat"] = m
	return _cache["grassmat"]

func _grass_card() -> ArrayMesh:
	if _cache.has("grasscard"):
		return _cache["grasscard"]
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for k in 3:
		var a := PI * k / 3.0
		var d := Vector3(cos(a), 0, sin(a)) * 0.5
		var v := [[-d, Vector2(0, 1)], [d, Vector2(1, 1)], [d + Vector3(0, 1, 0), Vector2(1, 0)], [-d + Vector3(0, 1, 0), Vector2(0, 0)]]
		for idx in [0, 1, 2, 0, 2, 3]:
			st.set_normal(Vector3(0, 1, 0))
			st.set_uv(v[idx][1])
			st.set_color(Color(1, 1, 1))
			st.add_vertex(v[idx][0])
	var m := st.commit()
	_cache["grasscard"] = m
	return m

func grass_field(n: int, col: Color, region := Rect2(2, 2, 252, 252), size := 0.55, avoid_fn: Callable = Callable()) -> void:
	# çapraz kartlı ot öbekleri (tek MultiMesh, gölge atmaz)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = _grass_card()
	var xs: Array = []
	var cs: Array = []
	var tries := 0
	while xs.size() < n and tries < n * 3:
		tries += 1
		var p := Vector3(rng.randf_range(region.position.x, region.end.x), 0, rng.randf_range(region.position.y, region.end.y))
		if G.grid.height_at(p) > 0.05 or G.terrain.ground_h(p) < -0.45:
			continue
		if avoid_fn.is_valid() and avoid_fn.call(p):
			continue
		var s := rng.randf_range(0.6, 1.4) * size
		xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s * 1.4, s, s * 1.4)), p + Vector3(0, G.terrain.ground_h(p), 0)))
		cs.append(MB.jit(col, rng, 0.18))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
		mm.set_instance_color(i, cs[i])
	var m := MultiMeshInstance3D.new()
	m.multimesh = mm
	m.material_override = _grass_material()
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)

func reeds_along(pts: PackedVector3Array, half_w: float) -> void:
	# kanal/nehir kıyısına çalı
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		var L := a.distance_to(b)
		var n := maxi(1, int(L / 1.6))
		for k in n:
			var p := a.lerp(b, rng.randf())
			for sg in [-1.0, 1.0]:
				var q: Vector3 = p + side * sg * (half_w + rng.randf_range(0.5, 2.6))
				if rng.randf() < 0.35 and G.grid.height_at(q) < 0.05:
					bush(q + Vector3(0, G.terrain.ground_h(q), 0))

func bridge(center: Vector3, dir: Vector3, length: float, width := 6.5) -> void:
	var rot := atan2(-dir.z, dir.x)
	var mesh := _cached("bridge_%d_%d" % [int(length), int(width)], func(): return _bridge_mesh(length, width))
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	mi.position = Vector3(center.x, 0, center.z)
	mi.rotation.y = rot
	add_child(mi)
	G.grid.set_bridge(center, Vector2(length + 2.0, width - 0.8), rot)
	G.grid.add_bridge(center, dir, length + 2.0, width - 0.8)
	var side := Vector3(-dir.z, 0, dir.x)
	for sg in [-1.0, 1.0]:
		G.grid.set_static_rect(center + side * sg * (width * 0.5 - 0.15), Vector2(length, 0.3), rot, 0.75, Grid.K_HOUSE)

func _bridge_mesh(L: float, W: float) -> ArrayMesh:
	var mb := MB.new()
	var st := Color(0.66, 0.63, 0.58)
	mb.box(Vector3(0, -0.25, 0), Vector3(L + 2.0, 0.54, W), st)
	mb.box(Vector3(0, 0.0, 0), Vector3(L + 2.0, 0.04, W - 0.9), Color(0.48, 0.45, 0.42))
	for sg in [-1.0, 1.0]:
		mb.box(Vector3(0, 0.38, sg * (W * 0.5 - 0.15)), Vector3(L + 2.0, 0.7, 0.3), st.lightened(0.05))
		var n := int((L + 2.0) / 2.2)
		for k in n + 1:
			var x := -(L + 2.0) * 0.5 + k * (L + 2.0) / n
			mb.box(Vector3(x, 0.5, sg * (W * 0.5 - 0.15)), Vector3(0.45, 1.0, 0.45), st.lightened(0.1))
	var np := maxi(1, int(L / 5.0))
	for k in np + 1:
		var x := -L * 0.5 + k * L / np
		mb.box(Vector3(x, -1.2, 0), Vector3(0.9, 1.9, W * 0.92), st.darkened(0.1))
	for k in np:
		var x0 := -L * 0.5 + k * L / np + 0.45
		var x1 := -L * 0.5 + (k + 1) * L / np - 0.45
		var cx := (x0 + x1) * 0.5
		var rr := (x1 - x0) * 0.5
		var seg := 8
		for s in seg:
			var a0 := PI * s / seg
			var a1 := PI * (s + 1) / seg
			for sg in [-1.0, 1.0]:
				var z: float = sg * W * 0.46
				var p0 := Vector3(cx + cos(a0) * rr, -0.52, z)
				var q0 := Vector3(cx + cos(a0) * rr, -1.9 + sin(a0) * 1.2, z)
				var q1 := Vector3(cx + cos(a1) * rr, -1.9 + sin(a1) * 1.2, z)
				var p1 := Vector3(cx + cos(a1) * rr, -0.52, z)
				mb.quad(p0, p1, q1, q0, st.darkened(0.15), Vector3(0, 0, sg))
	return mb.commit(Mats.stone())

# ------------------------------------------------------------ seçili birliklerin üstündeki ağaçları saydamlaştır
var _fade_t := 0.0
var _faded: Array = []

func _process(dt: float) -> void:
	_fade_t -= dt
	if _fade_t > 0.0 or G.player == null or not is_instance_valid(G.player):
		return
	_fade_t = 0.2
	var pts: Array = []
	for u in G.player.selected:
		if is_instance_valid(u) and not (u is Building):
			pts.append(u.position)
	if G.cam and G.cam.cam:
		pts.append(G.cam.mouse_ground(get_viewport().get_mouse_position()))
	var now: Array = []
	for it in items:
		if it["kind"] != "tree" or not it["alive"]:
			continue
		var p: Vector3 = it["pos"]
		for q in pts:
			# ağaç tepesi ekranda yukarı (-x -z yönündeki zemin) düşer: birliğin +x +z kadar ötesindeki ağaçlar örter
			var d := Vector2(p.x - 2.2 - q.x, p.z - 2.2 - q.z).length()
			if d < 4.5:
				now.append(it["node"])
				break
	for n in _faded:
		if is_instance_valid(n) and not now.has(n):
			n.transparency = 0.0
	for n in now:
		n.transparency = 0.65
	_faded = now
