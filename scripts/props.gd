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

# ------------------------------------------------------------ gerçek ağaç modelleri (tools/trees: ez-tree + CC0 kabuk/yaprak)
# tür kimliği -> [kabuk dokusu uv ölçeği]; GLB yoksa eski prosedürel ağaca düşer
const TREE_DIR := "res://assets/trees/"
const TREE_SETS := {
	"green": ["oak_s", "oak_m", "oak_l", "oak_m", "ash_s", "ash_m", "ash_l", "aspen_m", "aspen_l", "birch_m", "willow_m"],
	"desert": ["ash_s", "oak_s", "ash_s", "willow_m"],
	"pine": ["pine_s", "pine_m", "pine_l", "pine_m"],
	"bush": ["bush_1", "bush_2", "bush_3", "bush_2"],
}
var biome_id := "green"

func _tree_shader_mat(surf_name: String, h: float, crown: float) -> ShaderMaterial:
	var key := "tm_%s_%d_%s_%s" % [surf_name, int(h * 10.0), biome_id, str(winter)]
	if _cache.has(key):
		return _cache[key]
	var m := ShaderMaterial.new()
	m.shader = preload("res://shaders/tree.gdshader")
	var leaf := surf_name.begins_with("leaf_")
	var tex_id := surf_name.substr(5) if leaf else surf_name.substr(5)
	m.set_shader_parameter("leaf", leaf)
	m.set_shader_parameter("tree_h", h)
	m.set_shader_parameter("crown_y", crown)
	if leaf:
		m.set_shader_parameter("albedo_tex", load(TREE_DIR + "tex/leaf_%s.png" % tex_id))
		var tint := Color(0.86, 0.92, 0.74)
		if biome_id == "desert":
			tint = Color(0.82, 0.84, 0.62)      # tozlu, solgun zeytin yeşili
		elif tex_id == "pine":
			tint = Color(0.78, 0.86, 0.72)
		elif tex_id == "aspen":
			tint = Color(0.52, 0.84, 0.42)      # yaz kavağı: sarıya değil yeşile
		m.set_shader_parameter("tint", tint)
	else:
		m.set_shader_parameter("albedo_tex", load(TREE_DIR + "tex/bark_%s_color.jpg" % tex_id))
		m.set_shader_parameter("normal_tex", load(TREE_DIR + "tex/bark_%s_normal.jpg" % tex_id))
		m.set_shader_parameter("has_normal", true)
		m.set_shader_parameter("uv_scale", Vector2(1.0, 0.35) if tex_id != "birch" else Vector2(1.0, 0.25))
		m.set_shader_parameter("tint", Color(0.92, 0.9, 0.86) if tex_id != "birch" else Color(0.95, 0.95, 0.93))
	if winter:
		m.set_shader_parameter("snow", 0.85 if leaf else 0.55)
	m.set_shader_parameter("sway_amp", 0.5 if surf_name.contains("pine") else 1.0)
	_cache[key] = m
	return m

func _tree_model(id: String) -> Mesh:
	var key := "glb_" + id
	if _cache.has(key):
		return _cache[key]
	var path := TREE_DIR + id + ".glb"
	if not ResourceLoader.exists(path):
		_cache[key] = null
		return null
	var sc: Node = (load(path) as PackedScene).instantiate()
	var src: MeshInstance3D = sc.find_children("*", "MeshInstance3D", true, false)[0] if not sc is MeshInstance3D else sc
	var mesh: Mesh = src.mesh.duplicate()
	sc.free()
	var aabb := mesh.get_aabb()
	var h := maxf(aabb.end.y, 0.5)
	var crown := 0.45 if id.begins_with("bush") else (0.55 if id.begins_with("pine") else 0.68)
	for i in mesh.get_surface_count():
		var mat := mesh.surface_get_material(i)
		var nm := mat.resource_name if mat != null else ("leaf_oak" if i > 0 else "bark_oak")
		mesh.surface_set_material(i, _tree_shader_mat(nm, h, crown))
	_cache[key] = mesh
	return mesh

func _real_tree(p: Vector3, set_name: String, sc := 1.0) -> bool:
	var ids: Array = TREE_SETS[set_name]
	var id: String = ids[rng.randi() % ids.size()]
	if winter and not id.begins_with("pine") and not id.begins_with("bush"):
		id += "_bare"
	# büyük haritada tek tohum (banka/çizim çağrısı sayısı 3'te 1)
	var mesh := _tree_model("%s_%d" % [id, rng.randi() % (3 if G.MAP <= 1024.0 else 1)])
	if mesh == null:
		return false
	var s2 := sc * rng.randf_range(0.85, 1.15)
	var xf := Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s2, s2, s2)), p)
	var it: Dictionary
	if set_name == "bush":
		it = {"node": null, "pos": p, "kind": "bush", "hp": 20.0, "alive": true, "r": 0.6}
	else:
		var big := id.contains("_l")
		it = {"node": null, "pos": p, "kind": "tree", "hp": (110.0 if big else 75.0) * sc, "alive": true, "r": 0.5 if big else 0.4}
		G.grid.set_static_circle(p, 0.35 if big else 0.3, 3.0, Grid.K_TREE)
	it["mesh"] = mesh
	it["xf"] = xf
	items.append(it)
	_mm_add(it, set_name == "bush")
	return true

# ------------------------------------------------------------ ağaç örnekleme (MultiMesh)
# Aynı modeldeki tüm ağaçlar tek MultiMesh: çizim çağrısı az, büyük haritada binlerce ağaç.
# Örnek gizleme: ölçek 0; saydamlaşma: özel veri r (shader'da titreşimli kesim).
var _banks := {}          # "mesh_karoX_karoZ" -> {"mm": MultiMesh, "items": Array, "dirty": bool}

func _mm_add(it: Dictionary, bush: bool) -> void:
	var mesh: Mesh = it["mesh"]
	# banka = model × 256 m karo (karo dışı görüşte kırpılır)
	var p: Vector3 = it["pos"]
	var bt := 256.0 if G.MAP <= 1024.0 else 512.0
	var key := "%d_%d_%d" % [mesh.get_instance_id(), int(p.x / bt), int(p.z / bt)]
	if not _banks.has(key):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_custom_data = true
		mm.mesh = mesh
		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF if bush else GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		add_child(mmi)
		_banks[key] = {"mm": mm, "items": [], "dirty": true}
	var b: Dictionary = _banks[key]
	it["bank"] = b
	it["mi_idx"] = b["items"].size()
	b["items"].append(it)
	b["dirty"] = true
	if not _bank_pending:
		_bank_pending = true
		_flush_banks.call_deferred()

var _bank_pending := false
func _flush_banks() -> void:
	_bank_pending = false
	for key in _banks:
		var b: Dictionary = _banks[key]
		if not b["dirty"]:
			continue
		b["dirty"] = false
		var mm: MultiMesh = b["mm"]
		var its: Array = b["items"]
		mm.instance_count = its.size()
		for i in its.size():
			var it: Dictionary = its[i]
			var shown: bool = it["alive"] and it["node"] == null
			mm.set_instance_transform(i, it["xf"] if shown else Transform3D(Basis().scaled(Vector3.ZERO), it["pos"]))
			mm.set_instance_custom_data(i, Color(0, 0, 0, 0))

func _mm_hide(it: Dictionary) -> void:
	var b: Dictionary = it["bank"]
	(b["mm"] as MultiMesh).set_instance_transform(it["mi_idx"], Transform3D(Basis().scaled(Vector3.ZERO), it["pos"]))

func _mm_fade(it: Dictionary, a: float) -> void:
	var b: Dictionary = it["bank"]
	(b["mm"] as MultiMesh).set_instance_custom_data(it["mi_idx"], Color(a, 0, 0, 0))

# devrilecek/yanacak örnek: MultiMesh'ten çıkarılıp ayrı düğüm olur
func _detach(it: Dictionary) -> MeshInstance3D:
	if it["node"] != null:
		return it["node"]
	_mm_hide(it)
	var mi := MeshInstance3D.new()
	mi.mesh = it["mesh"]
	mi.transform = it["xf"]
	add_child(mi)
	it["node"] = mi
	return mi

# patlama şok dalgası: ağaç shader'ı son 4 büyük patlamayı (global) okuyup uzaktan yatar/sallanır
func shake_trees(center: Vector3, power: float) -> void:
	G.push_blast(center, power)

# ------------------------------------------------------------ yapraklı ağaç (kış: sarı kuru yaprak + kar, çöl: koyu yeşil)
func tree(p: Vector3) -> void:
	if _real_tree(p, "desert" if biome_id == "desert" else "green"):
		return
	var v := rng.randi() % 5
	var key := ("wtree%d" if winter else "dtree%d") % v
	var mesh := _cached(key, func(): return _tree_mesh(v, winter))
	var sc: float = [rng.randf_range(0.55, 0.75), rng.randf_range(0.85, 1.15), rng.randf_range(1.3, 1.7)][rng.randi() % 3]
	var mi := _place(mesh, p, rng.randf() * TAU, sc)
	if rng.randf() < 0.22:
		mi.scale = Vector3(0.55, 1.75, 0.55) * sc     # kavak: uzun ve ince
	items.append({"node": mi, "pos": p, "kind": "tree", "hp": 70.0 * sc, "alive": true, "r": 0.4})
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
	return _bare_tree(seed_v)

# kış: yaprağı dökülmüş, özyinelemeli dallanan ağaç; dalların üstünde ince kar
func _bare_tree(seed_v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 2100 + seed_v
	var mb := MB.new()
	var bark := Color(0.2, 0.17, 0.14)
	var snow := Color(0.9, 0.92, 0.95)
	var H := r.randf_range(2.2, 3.2)
	mb.cyl_between(Vector3.ZERO, Vector3(0, H, 0), 0.2, 0.13, 7, bark, false)
	var stack: Array = [[Vector3(0, H, 0), Vector3(0, 1, 0), 1.9, 0.13, 0]]
	while not stack.is_empty():
		var it: Array = stack.pop_back()
		var p0: Vector3 = it[0]
		var dir: Vector3 = it[1]
		var L: float = it[2]
		var rad: float = it[3]
		var depth: int = it[4]
		var n := 3 if depth < 2 else 2
		for k in n:
			var d := (dir + Vector3(r.randf_range(-0.9, 0.9), r.randf_range(-0.1, 0.5), r.randf_range(-0.9, 0.9))).normalized()
			if d.y < 0.15:
				d.y = 0.15
				d = d.normalized()
			var l := L * r.randf_range(0.65, 0.9)
			var p1 := p0 + d * l
			mb.cyl_between(p0, p1, rad, rad * 0.6, 5 if depth < 2 else 4, bark, false)
			if rad > 0.03:
				mb.cyl_between(p0 + Vector3(0, rad * 0.7, 0), p1 + Vector3(0, rad * 0.45, 0), rad * 0.55, rad * 0.3, 4, snow, false)
			if depth < 3:
				stack.append([p1, d, l, rad * 0.62, depth + 1])
	return mb.commit(Mats.vc())

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
const CIV_MODELS := ["car_sedan", "car_hatch", "car_boxy", "car_pickup", "car_van", "car_sedan", "car_boxy"]
const CIV_COLS := [Color(0.82, 0.82, 0.8), Color(0.12, 0.13, 0.15), Color(0.5, 0.52, 0.55), Color(0.42, 0.08, 0.07), Color(0.12, 0.2, 0.36), Color(0.62, 0.58, 0.48), Color(0.25, 0.32, 0.22), Color(0.72, 0.62, 0.3)]

func car(p: Vector3, rot: float, color_idx := -1) -> void:
	var v := color_idx if color_idx >= 0 else rng.randi() % 5
	var model: String = CIV_MODELS[rng.randi() % CIV_MODELS.size()]
	var col: Color = CIV_COLS[(v * 3 + rng.randi()) % CIV_COLS.size()]
	var mesh: Mesh = Art.civil(model, col) if Art.has(model) else null
	if mesh == null:
		mesh = _cached("car%d" % v, func(): return car_mesh(v))
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

# çatı yarası: kararmış delik + kırık kirişler + saçılmış kiremit (hasarlı bina)
func roof_damage(p: Vector3, w: float, d: float, top: float, rot: float) -> void:
	var mb := MB.new()
	var hw := w * rng.randf_range(0.22, 0.34)
	var hd := d * rng.randf_range(0.2, 0.32)
	var off := Vector3(rng.randf_range(-w, w) * 0.15, 0, rng.randf_range(-d, d) * 0.15)
	var ry := top + 0.9
	mb.box(off + Vector3(0, ry, 0), Vector3(hw * 2.0, 0.05, hd * 2.0), Color(0.06, 0.05, 0.04))
	# kirişler: delikten görünen, bazıları kırık/eğik
	for i in 5:
		var x := off.x - hw + (i + 0.5) * hw * 2.0 / 5.0
		var tilt := rng.randf_range(-0.35, 0.35) if rng.randf() < 0.4 else 0.0
		mb.box(Vector3(x, ry + 0.12, off.z), Vector3(0.12, 0.12, hd * 2.2), Color(0.32, 0.22, 0.14), Basis(Vector3.RIGHT, tilt))
	mb.box(off + Vector3(0, ry + 0.25, 0), Vector3(hw * 2.4, 0.14, 0.14), Color(0.3, 0.2, 0.12), Basis(Vector3.FORWARD, rng.randf_range(-0.2, 0.2)))
	# yere saçılmış kiremit / moloz
	for i in 14:
		var a := rng.randf() * TAU
		var r := rng.randf_range(w * 0.55, w * 0.95)
		var q := Vector3(cos(a) * r, 0.06, sin(a) * r * d / w)
		mb.box(q, Vector3(rng.randf_range(0.2, 0.5), 0.06, rng.randf_range(0.15, 0.35)), Color(0.55, 0.26, 0.16).darkened(rng.randf_range(0.0, 0.3)), Basis(Vector3.UP, rng.randf() * TAU))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	mi.position = p
	mi.rotation.y = rot
	add_child(mi)

# ahşap bahçe çiti (tahta + direk), eğik/kırık parçalar
func picket(a: Vector3, b: Vector3) -> void:
	var mb := MB.new()
	var L := a.distance_to(b)
	var dir := (b - a).normalized()
	var bas := Basis(Vector3.UP, atan2(-dir.z, dir.x))
	var wood := Color(0.48, 0.38, 0.27)
	var n := maxi(1, int(L / 0.16))
	for i in n:
		if rng.randf() < 0.06:
			continue
		var p := a.lerp(b, (i + 0.5) / n)
		var h := rng.randf_range(0.85, 1.0)
		mb.box(p + Vector3(0, h * 0.5, 0), Vector3(0.09, h, 0.025), wood.darkened(rng.randf_range(0.0, 0.18)), bas * Basis(Vector3.FORWARD, rng.randf_range(-0.05, 0.05)))
	for y in [0.3, 0.72]:
		mb.box((a + b) * 0.5 + Vector3(0, y, 0) - Vector3(0, 0, 0), Vector3(L, 0.06, 0.03), wood.darkened(0.25), bas)
	var np := maxi(1, int(L / 2.0))
	for i in np + 1:
		mb.box(a.lerp(b, float(i) / np) + Vector3(0, 0.55, 0), Vector3(0.1, 1.1, 0.1), wood.darkened(0.35), bas)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	add_child(mi)
	G.grid.set_static_rect((a + b) * 0.5, Vector2(L, 0.2), atan2(-dir.z, dir.x) * -1.0 + 0.0, 0.9, Grid.K_WALL)

# demiryolu: balast + traversler + iki ray
func railway(pts: PackedVector3Array) -> void:
	var mb := MB.new()
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var L := a.distance_to(b)
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var bas := Basis(Vector3.UP, atan2(-dir.z, dir.x))
		mb.box((a + b) * 0.5 + Vector3(0, 0.08, 0), Vector3(L, 0.16, 3.2), Color(0.34, 0.32, 0.3), bas)
		var n := maxi(1, int(L / 0.65))
		for k in n:
			var p := a.lerp(b, (k + 0.5) / n)
			mb.box(p + Vector3(0, 0.2, 0), Vector3(0.24, 0.1, 2.5), Color(0.25, 0.19, 0.13).darkened(rng.randf_range(0.0, 0.2)), bas)
		for sg in [-0.72, 0.72]:
			mb.box((a + b) * 0.5 + side * sg + Vector3(0, 0.3, 0), Vector3(L + 0.05, 0.1, 0.08), Color(0.42, 0.36, 0.32), bas)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	add_child(mi)

# meydan: taş havuzlu çeşme + kaideli heykel + banklar
func plaza(c: Vector3) -> void:
	var mb := MB.new()
	var stone := Color(0.62, 0.6, 0.56)
	mb.cyl(Vector3(0, 0.0, 0), 3.2, 3.2, 0.5, 16, stone)
	mb.cyl(Vector3(0, 0.02, 0), 2.9, 2.9, 0.52, 16, Color(0.22, 0.32, 0.34))
	mb.box(Vector3(0, 0.9, 0), Vector3(1.1, 1.8, 1.1), stone.darkened(0.1))
	mb.box(Vector3(0, 1.85, 0), Vector3(1.3, 0.15, 1.3), stone)
	var bronze := Color(0.22, 0.3, 0.26)
	mb.cyl(Vector3(0, 2.6, 0), 0.22, 0.28, 1.4, 8, bronze)
	mb.sphere(Vector3(0, 3.45, 0), Vector3(0.18, 0.22, 0.18), 8, 6, bronze)
	mb.box(Vector3(0.35, 3.0, 0), Vector3(0.6, 0.1, 0.1), bronze, Basis(Vector3.FORWARD, 0.6))
	for k in 4:
		var a := k * TAU / 4.0 + PI * 0.25
		var q := Vector3(cos(a) * 5.0, 0, sin(a) * 5.0)
		var bb := Basis(Vector3.UP, -a)
		mb.box(q + Vector3(0, 0.42, 0), Vector3(0.45, 0.06, 1.6), Color(0.42, 0.3, 0.2), bb)
		mb.box(q + Vector3(0, 0.2, 0), Vector3(0.4, 0.4, 0.08), Color(0.2, 0.2, 0.2), bb)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	mi.position = c
	add_child(mi)
	G.grid.set_static_circle(c, 3.2, 0.5, Grid.K_WALL)
	G.grid.set_static_circle(c, 0.8, 2.0, Grid.K_HOUSE, true)

func awning(p: Vector3, rot: float, w: float, col: Color) -> void:
	var mb := MB.new()
	for i in int(w / 0.5):
		var x := -w * 0.5 + (i + 0.5) * 0.5
		mb.box(Vector3(x, 2.55, 0.55), Vector3(0.5, 0.05, 1.2), col if i % 2 == 0 else Color(0.92, 0.9, 0.84), Basis(Vector3.RIGHT, 0.32))
	mb.box(Vector3(0, 3.25, 0.0), Vector3(w * 0.7, 0.45, 0.08), Color(0.12, 0.14, 0.16))           # tabela
	mb.box(Vector3(0, 3.25, 0.05), Vector3(w * 0.6, 0.25, 0.02), col.lightened(0.4))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	mi.position = p
	mi.rotation.y = rot
	add_child(mi)

func spire(p: Vector3, h: float) -> void:
	var mb := MB.new()
	mb.cyl(Vector3(0, 0, 0), 2.3, 0.05, h, 4, Color(0.25, 0.3, 0.32), Basis(Vector3.UP, PI * 0.25))
	mb.cyl(Vector3(0, h + 0.6, 0), 0.04, 0.04, 1.2, 4, Color(0.6, 0.55, 0.3))
	mb.box(Vector3(0, h + 0.9, 0), Vector3(0.6, 0.06, 0.06), Color(0.6, 0.55, 0.3))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	mi.position = p
	add_child(mi)

func gas_station(p: Vector3, rot: float) -> void:
	var mb := MB.new()
	for x in [-3.5, 3.5]:
		for z in [-2.0, 2.0]:
			mb.box(Vector3(x, 2.3, z), Vector3(0.3, 4.6, 0.3), Color(0.85, 0.85, 0.82))
	mb.box(Vector3(0, 4.7, 0), Vector3(9.0, 0.45, 6.0), Color(0.9, 0.9, 0.88))
	mb.box(Vector3(0, 4.7, 3.02), Vector3(9.0, 0.3, 0.05), Color(0.75, 0.12, 0.08))
	for x in [-1.6, 1.6]:
		mb.box(Vector3(x, 0.15, 0), Vector3(1.2, 0.3, 3.2), Color(0.55, 0.55, 0.52))
		mb.box(Vector3(x, 0.9, 0), Vector3(0.5, 1.2, 0.8), Color(0.82, 0.18, 0.12))
		mb.box(Vector3(x, 1.2, 0.41), Vector3(0.35, 0.3, 0.02), Color(0.1, 0.12, 0.14))
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	mi.position = p
	mi.rotation.y = rot
	add_child(mi)
	for x in [-1.6, 1.6]:
		G.grid.set_static_rect(p + Vector3(x, 0, 0).rotated(Vector3.UP, rot), Vector2(1.2, 3.2), rot, 0.4, Grid.K_WALL)

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
	if radius >= 2.5:
		shake_trees(center, radius / 3.0)
	for it in items:
		if not it["alive"]:
			continue
		var p: Vector3 = it["pos"]
		var d := Vector2(p.x - center.x, p.z - center.z).length()
		if d > radius + it["r"]:
			continue
		if it["kind"] == "bridge" and dmg < 100.0:
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
	if it.has("bank") and it["kind"] != "tree":
		_mm_hide(it)
		return
	var mi: MeshInstance3D = it["node"] if not it.has("bank") else _detach(it)
	match it["kind"]:
		"car":
			mi.material_override = Mats.burnt()
			G.fx.burn(it["pos"] + Vector3(0, 0.8, 0), rng.randf_range(15, 30), 0.7)
			G.fx.explosion(it["pos"] + Vector3(0, 0.6, 0), 1.2, "big")
			Sfx.play3d("expl_med", it["pos"], 0.0)
			var tw := create_tween()
			tw.tween_property(mi, "position:y", 0.6, 0.15).set_ease(Tween.EASE_OUT)
			tw.tween_property(mi, "position:y", 0.0, 0.25).set_ease(Tween.EASE_IN)
		"bridge":
			_collapse_bridge(it)
		"tree":
			var away: Vector3 = it["pos"] - center
			away.y = 0
			_fell(it, away.normalized() if away.length() > 0.1 else Vector3.RIGHT)
		_:
			mi.visible = false

# köprü çöküşü: orta açıklık parçalanıp suya düşer, iki uçta kırık ayaklar kalır
func _collapse_bridge(it: Dictionary) -> void:
	var mi: MeshInstance3D = it["node"]
	var c: Vector3 = it["pos"]
	var dir: Vector3 = it["dir"]
	var L: float = it["L"]
	var W: float = it["W"]
	var rot: float = it["rot"]
	mi.visible = false
	var gap := L * 0.55
	var stone := Color(0.7, 0.66, 0.6)
	var bas := Basis(Vector3.UP, rot)
	# iki uçta kalan kırık köprü parçası (sarkık uç)
	for sg in [-1.0, 1.0]:
		var seg := (L - gap) * 0.5
		var mb := MB.new()
		mb.box(Vector3(0, 0.15, 0), Vector3(seg, 0.4, W), stone, Basis())
		mb.box(Vector3(-sg * seg * 0.5 + sg * 0.0, -0.3, 0), Vector3(0.6, 0.9, W * 0.9), stone.darkened(0.2), Basis(Vector3.FORWARD, sg * 0.35))
		for k in 6:
			mb.box(Vector3(randf_range(-seg * 0.5, seg * 0.5), 0.4, randf_range(-W * 0.4, W * 0.4)), Vector3(0.4, 0.2, 0.4), stone.darkened(randf_range(0.1, 0.3)), Basis(Vector3.UP, randf() * TAU))
		var e := MeshInstance3D.new()
		e.mesh = mb.commit(Mats.vcs())
		e.position = c + dir * sg * (gap * 0.5 + seg * 0.5)
		e.rotation.y = rot
		add_child(e)
	# düşen parçalar
	for k in 8:
		var pc := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(randf_range(1.0, 2.5), 0.4, randf_range(1.2, W))
		pc.mesh = bm
		pc.material_override = Mats.vcs()
		var p0 := c + dir * randf_range(-gap * 0.45, gap * 0.45) + Vector3(0, 0.2, 0)
		pc.position = p0
		pc.rotation.y = rot
		add_child(pc)
		var tw := pc.create_tween()
		var dur := randf_range(0.6, 1.1)
		tw.tween_property(pc, "position:y", -1.6, dur).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(pc, "rotation", Vector3(randf_range(-0.8, 0.8), rot, randf_range(-0.8, 0.8)), dur)
		tw.tween_callback(func(): G.fx.water_splash(Vector3(p0.x, 0, p0.z), 0.9))
	G.fx.explosion(c + Vector3(0, 0.5, 0), 2.0, "big")
	G.fx.dust_burst(c, gap * 0.5)
	Sfx.play3d("collapse", c, 6.0)
	G.grid.clear_bridge(c, Vector2(gap, W + 0.5), rot)
	# üstündekiler suya düşer
	for u in G.near(c, gap * 0.6 + W):
		if not u.alive:
			continue
		var rel: Vector3 = u.position - c
		if absf(rel.dot(dir)) < gap * 0.5 and absf(rel.cross(dir).y) < W * 0.5 + 0.5:
			if u is Vehicle and not u.is_air():
				u.destroy(null)
			elif u is Soldier:
				u.die(null)
	G.say(I18n.s("KÖPRÜ YIKILDI!"), c, G.player_team)

func _fell(it: Dictionary, dir: Vector3) -> void:
	it["alive"] = false
	var mi: MeshInstance3D = it["node"] if not it.has("bank") else _detach(it)
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
			if it.has("bank") and it["node"] == null:
				_mm_hide(it)
			else:
				(it["node"] as Node3D).visible = false
			G.grid.set_static_circle(p, 0.5, 0.0, Grid.K_NONE, true)

# ------------------------------------------------------------ bitki örtüsü (çam, çalı, kaya, saman, ot, kamış)
func pine(p: Vector3) -> void:
	if _real_tree(p, "pine"):
		return
	var v := rng.randi() % 4
	var key := ("pine_w%d" if winter else "pine%d") % v
	var mesh := _cached(key, func(): return _pine_mesh(v, winter))
	var mi := _place(mesh, p, rng.randf() * TAU, [rng.randf_range(0.5, 0.75), rng.randf_range(0.9, 1.2), rng.randf_range(1.35, 1.8)][rng.randi() % 3])
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
	if not winter and _real_tree(p, "bush", 1.5 if big else 1.0):
		return
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
	var v := rng.randi() % 8
	var mesh := _cached("rock%d_%s" % [v, str(winter)], func(): return _rock_mesh(v))
	var mi := _place(mesh, p, rng.randf() * TAU, s)
	# hafif eğik oturur, yarı gömülü
	mi.rotation.x = rng.randf_range(-0.12, 0.12)
	mi.rotation.z = rng.randf_range(-0.12, 0.12)
	if s > 0.9:
		G.grid.set_static_circle(p, 0.7 * s, 0.8 * s, Grid.K_WRECK)

# kaya: alt bölünmüş ikosfer → elipsoid → rastgele düzlem kesikleri (kırık yüzler, keskin kenar)
# → üç boyutlu gürültü; doku: tools/rock_tex.py (Voronoi kırık ağı, tabakalanma, liken)
func _rock_mesh(v: int) -> ArrayMesh:
	return rock_mesh(v, winter, not winter and biome_id != "desert", 3)

# lvl: ikosfer alt bölme düzeyi (3: kaya ~1280 üçgen, 1: çakıl ~80 üçgen)
static func rock_mesh(v: int, winter: bool, moss: bool, lvl: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 900 + v
	var t := (1.0 + sqrt(5.0)) * 0.5
	var vs: Array = [Vector3(-1, t, 0), Vector3(1, t, 0), Vector3(-1, -t, 0), Vector3(1, -t, 0),
		Vector3(0, -1, t), Vector3(0, 1, t), Vector3(0, -1, -t), Vector3(0, 1, -t),
		Vector3(t, 0, -1), Vector3(t, 0, 1), Vector3(-t, 0, -1), Vector3(-t, 0, 1)]
	for i in vs.size():
		vs[i] = vs[i].normalized()
	var fs: Array = [[0, 11, 5], [0, 5, 1], [0, 1, 7], [0, 7, 10], [0, 10, 11], [1, 5, 9], [5, 11, 4], [11, 10, 2], [10, 7, 6], [7, 1, 8],
		[3, 9, 4], [3, 4, 2], [3, 2, 6], [3, 6, 8], [3, 8, 9], [4, 9, 5], [2, 4, 11], [6, 2, 10], [8, 6, 7], [9, 8, 1]]
	for _l in lvl:
		var mid := {}
		var nf: Array = []
		for f in fs:
			var m: Array = []
			for e in 3:
				var a: int = f[e]
				var b: int = f[(e + 1) % 3]
				var key := Vector2i(mini(a, b), maxi(a, b))
				if not mid.has(key):
					vs.append(((vs[a] + vs[b]) * 0.5).normalized())
					mid[key] = vs.size() - 1
				m.append(mid[key])
			nf.append([f[0], m[0], m[2]])
			nf.append([f[1], m[1], m[0]])
			nf.append([f[2], m[2], m[1]])
			nf.append([m[0], m[1], m[2]])
		fs = nf
	var rad := Vector3(r.randf_range(0.75, 1.05), r.randf_range(0.45, 0.75), r.randf_range(0.6, 0.9))
	if v % 4 == 3:
		rad = Vector3(r.randf_range(1.1, 1.4), r.randf_range(0.35, 0.5), r.randf_range(0.7, 0.9))    # yassı levha
	var cuts: Array = []
	for k in r.randi_range(5, 8):
		var cn := Vector3(r.randf_range(-1, 1), r.randf_range(-0.35, 1.0), r.randf_range(-1, 1)).normalized()
		cuts.append([cn, r.randf_range(0.55, 0.85)])
	var fn := FastNoiseLite.new()
	fn.seed = 77 + v
	fn.frequency = 1.6
	fn.fractal_octaves = 3
	var pos := PackedVector3Array()
	pos.resize(vs.size())
	for i in vs.size():
		var n: Vector3 = vs[i]
		var p := n * rad
		for c in cuts:
			var d: float = p.dot(c[0]) - c[1] * (rad * c[0]).length()
			if d > 0.0:
				p -= c[0] * d
		p *= 1.0 + fn.get_noise_3dv(n * 1.3) * 0.16 + fn.get_noise_3dv(n * 5.0) * 0.035
		if p.y < -0.12:
			p.y = -0.12 + (p.y + 0.12) * 0.25          # taban düz, toprağa gömülü
		pos[i] = p + Vector3(0, 0.08, 0)
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for f in fs:
		for e in [0, 2, 1]:
			var p: Vector3 = pos[f[e]]
			var hgt := clampf((p.y + 0.1) / (rad.y * 0.9 + 0.1), 0.0, 1.0)
			var c := Color(0.92, 0.9, 0.86).lerp(Color(0.62, 0.6, 0.56), 1.0 - hgt)   # taban gölgeli/toprak lekeli
			st.set_color(c)
			st.add_vertex(p)
	st.index()
	st.generate_normals()
	var mesh := st.commit()
	mesh.surface_set_material(0, Mats.rock(winter, moss))
	return mesh

func hay(p: Vector3) -> void:
	var mesh := _cached("hay", func(): return _hay_mesh())
	_place(mesh, p, rng.randf() * TAU)
	G.grid.set_static_circle(p, 0.6, 1.1, Grid.K_WRECK)

func _hay_mesh() -> ArrayMesh:
	var mb := MB.new()
	mb.cyl(Vector3(-0.6, 0.6, 0), 0.6, 0.6, 1.2, 12, Color(0.86, 0.68, 0.3), Basis(Vector3.FORWARD, PI * 0.5))
	return mb.commit(Mats.vc())

# ot çeşitleri: 1 uzun kuru ot + başak, 2 kır çiçekleri (renk dokuda), 3 geniş yapraklı yabani ot
func _grass_variant_material(kind: int) -> StandardMaterial3D:
	var key := "grassmat_v%d" % kind
	if _cache.has(key):
		return _cache[key]
	var S := 128
	var im := Image.create(S, S, false, Image.FORMAT_RGBA8)
	im.fill(Color(0, 0, 0, 0))
	var r := RandomNumberGenerator.new()
	r.seed = 50 + kind
	var blades: int = [0, 18, 16, 6][kind]
	for b in blades:
		var x0 := r.randf_range(12, S - 12)
		var lean := r.randf_range(-26, 26)
		var hgt := r.randf_range(0.6, 1.0) * S if kind == 1 else r.randf_range(0.35, 0.75) * S
		var w := r.randf_range(1.2, 2.6) if kind == 1 else r.randf_range(2.0, 3.6)
		var shade := r.randf_range(0.75, 1.0)
		for y in int(hgt):
			var t := float(y) / hgt
			var cx := x0 + lean * t * t
			var ww := w * (1.0 - t * 0.8)
			for x in range(int(cx - ww), int(cx + ww) + 1):
				if x >= 0 and x < S:
					var c := Color(shade * (0.62 + 0.38 * t), shade * (0.72 + 0.28 * t), shade * 0.48, 1)
					if kind == 2:
						c = Color(0.28 * shade, 0.45 * shade, 0.16 * shade, 1)     # çiçek sapı (renk dokuda, örnek rengi beyaz)
					im.set_pixel(x, S - 1 - y, c)
		# başak / çiçek
		var tx := int(x0 + lean)
		var ty := S - 1 - int(hgt)
		if kind == 1:
			for k in 10:
				var px := tx + r.randi_range(-2, 2)
				var py := ty + k
				if px >= 0 and px < S and py >= 0 and py < S:
					im.set_pixel(px, py, Color(0.95, 0.85, 0.6, 1))
		elif kind == 2:
			var pal := [Color(0.95, 0.92, 0.85), Color(0.95, 0.85, 0.2), Color(0.75, 0.25, 0.85), Color(0.95, 0.3, 0.25), Color(0.45, 0.55, 0.95)]
			var fc: Color = pal[r.randi() % pal.size()]
			for dy in range(-4, 5):
				for dx in range(-4, 5):
					var d2 := dx * dx + dy * dy
					if d2 <= 16 and tx + dx >= 0 and tx + dx < S and ty + dy >= 0 and ty + dy < S:
						im.set_pixel(tx + dx, ty + dy, Color(0.95, 0.85, 0.3) if d2 <= 2 else fc)
	if kind == 3:
		# yuvarlak geniş yapraklar
		for k in 9:
			var cx2 := r.randf_range(25, S - 25)
			var cy2 := r.randf_range(S * 0.35, S - 15)
			var rr := r.randf_range(9, 16)
			for y in range(int(cy2 - rr), int(cy2 + rr)):
				for x in range(int(cx2 - rr), int(cx2 + rr)):
					var dd := Vector2(x - cx2, (y - cy2) * 1.6).length()
					if dd < rr and x >= 0 and x < S and y >= 0 and y < S:
						var sh := 0.65 + 0.35 * (1.0 - dd / rr)
						im.set_pixel(x, y, Color(0.5 * sh, 0.72 * sh, 0.38 * sh, 1))
	im.generate_mipmaps()
	var m := StandardMaterial3D.new()
	m.albedo_texture = ImageTexture.create_from_image(im)
	m.vertex_color_use_as_albedo = true
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	m.alpha_scissor_threshold = 0.45
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.roughness = 0.95
	_cache[key] = m
	return m

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
	_grass_field_v(n, col, region, size, avoid_fn, 0)
	if biome_id == "green" and not winter:
		# çeşit: uzun kuru ot + başak, kır çiçekleri, geniş yapraklı yabani ot
		_grass_field_v(int(n * 0.22), Color(0.82, 0.76, 0.5), region, size * 1.5, avoid_fn, 1)
		_grass_field_v(int(n * 0.1), Color(1, 1, 1), region, size * 0.9, avoid_fn, 2)
		_grass_field_v(int(n * 0.08), col.lightened(0.1), region, size * 0.8, avoid_fn, 3)
	elif biome_id == "desert":
		_grass_field_v(int(n * 0.3), Color(0.78, 0.7, 0.45), region, size * 1.3, avoid_fn, 1)

func _grass_field_v(n: int, col: Color, region: Rect2, size: float, avoid_fn: Callable, kind: int) -> void:
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
	m.material_override = _grass_material() if kind == 0 else _grass_variant_material(kind)
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
	# yıkılabilir: yalnız ağır patlamalar (topçu, tank mermisi, büyük) hasar verir
	items.append({"node": mi, "pos": Vector3(center.x, 0, center.z), "kind": "bridge", "hp": 1600.0, "alive": true, "r": length * 0.4, "dir": dir, "L": length, "W": width, "rot": rot})

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
	return mb.commit(Mats.masonry())

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
				now.append(it)
				break
	for it2 in _faded:
		if not now.has(it2):
			_set_fade(it2, 0.0)
	for it2 in now:
		_set_fade(it2, 0.65)
	_faded = now

func _set_fade(it: Dictionary, a: float) -> void:
	if it.has("bank") and it["node"] == null:
		if it["alive"]:
			_mm_fade(it, a)
	elif it["node"] != null and is_instance_valid(it["node"]):
		(it["node"] as GeometryInstance3D).transparency = a
