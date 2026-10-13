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
		var base_c := Color(0.07, 0.16, 0.045) if not dead else Color(0.4, 0.32, 0.18)
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
			var w0 := sin(PI * minf(t0 * 1.15, 1.0)) * 0.55 + 0.05
			var w1 := sin(PI * minf(t1 * 1.15, 1.0)) * 0.55 + 0.05
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

func _tree_mesh(seed_v: int, win: bool) -> ArrayMesh:
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
