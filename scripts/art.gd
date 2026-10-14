class_name Art extends RefCounted
# three.js ile üretilen modeller (assets/models/*.glb + .json) ve dokular (assets/gen/*.png).
# GLB malzeme adları → ordu (takım) ve iklime göre dokulu malzemeler.

static var _nodes := {}     # model → {düğüm: {mesh, pos}}
static var _meta := {}
static var _mat := {}
static var _skin := {}      # anahtar → malzemesi atanmış mesh

static func has(model: String) -> bool:
	return ResourceLoader.exists("res://assets/models/%s.glb" % model)

static func nodes(model: String) -> Dictionary:
	if _nodes.has(model):
		return _nodes[model]
	var out := {}
	if has(model):
		var scene: PackedScene = load("res://assets/models/%s.glb" % model)
		var root := scene.instantiate()
		_collect(root, out)
		root.free()
	_nodes[model] = out
	return out

static func _collect(n: Node, out: Dictionary) -> void:
	if n is MeshInstance3D:
		var mi := n as MeshInstance3D
		out[String(mi.name)] = {"mesh": mi.mesh, "pos": mi.position}
	for c in n.get_children():
		_collect(c, out)

static func meta(model: String) -> Dictionary:
	if not _meta.has(model):
		var f := FileAccess.open("res://assets/models/%s.json" % model, FileAccess.READ)
		var d = JSON.parse_string(f.get_as_text()) if f else {}
		_meta[model] = d if d is Dictionary else {}
	return _meta[model]

static func v3(a) -> Vector3:
	if a is Array and a.size() >= 3:
		return Vector3(a[0], a[1], a[2])
	return Vector3.ZERO

static func tex(name: String) -> Texture2D:
	var p := "res://assets/gen/%s.png" % name
	return load(p) if ResourceLoader.exists(p) else null

# ------------------------------------------------------------ ordu görünümü
static func paint_tex(team: int) -> String:
	var b: String = G.map_kind
	if team == 0:
		return {"desert": "camo_desert", "green": "camo_wood", "winter": "camo_snow"}.get(b, "camo_wood")
	return {"desert": "paint_sand", "green": "paint_olive", "winter": "camo_snow"}.get(b, "paint_olive")

static func uniform_tex(team: int) -> String:
	var b: String = G.map_kind
	if team == 0:
		return {"desert": "fab_desert", "green": "fab_multicam", "winter": "fab_snow"}.get(b, "fab_multicam")
	return {"desert": "fab_khaki", "green": "fab_olive", "winter": "fab_snow"}.get(b, "fab_olive")

static func material(name: String, team: int) -> StandardMaterial3D:
	var key := "%s|%d|%s" % [name, team, G.map_kind]
	if _mat.has(key):
		return _mat[key]
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.85
	m.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS_ANISOTROPIC
	var t := ""
	var tint := Color.WHITE
	var uvs := 1.0
	match name:
		"paint":
			t = paint_tex(team)
			m.roughness = 0.7
			m.metallic = 0.1
			uvs = 0.6
		"trim":
			t = paint_tex(team)
			tint = Color(0.72, 0.72, 0.72)
			uvs = 0.6
			m.roughness = 0.75
		"metal":
			t = "metal"
			m.metallic = 0.45
			m.roughness = 0.5
		"track":
			t = "track"
			m.roughness = 0.9
			m.metallic = 0.2
		"rubber":
			t = "rubber"
			m.roughness = 0.95
		"glass":
			tint = Color(0.1, 0.13, 0.16)
			m.roughness = 0.12
			m.metallic = 0.4
		"canvas":
			t = "canvas"
			m.roughness = 0.95
		"mark":
			tint = G.TEAM_COL[team]
			tint = G.TEAM_COL[team].lerp(Color(0.85, 0.85, 0.8), 0.25)
			m.roughness = 0.6
		"light":
			tint = Color(1.0, 0.95, 0.8)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.9, 0.7)
			m.emission_energy_multiplier = 0.4
		"dark":
			tint = Color(0.07, 0.07, 0.07)
		"uniform":
			t = uniform_tex(team)
			m.roughness = 0.95
			uvs = 2.5
		"vest":
			t = uniform_tex(team)
			tint = Color(0.82, 0.82, 0.78) if team == 0 else Color(0.62, 0.6, 0.5)
			m.roughness = 0.95
			uvs = 2.5
		"helmet":
			t = uniform_tex(team)
			tint = Color(0.85, 0.85, 0.82)
			m.roughness = 0.8
			uvs = 2.5
		"pack":
			t = "canvas"
			tint = Color(0.48, 0.48, 0.36) if G.map_kind != "desert" else Color(0.7, 0.62, 0.46)
			if G.map_kind == "winter":
				tint = Color(0.82, 0.83, 0.82)
		"skin":
			tint = Color(0.72, 0.55, 0.42)
			m.roughness = 0.7
		"team":
			tint = Color(0.28, 0.48, 0.78) if team == 0 else Color(0.72, 0.2, 0.14)
		"boot":
			t = "leather"
			tint = Color(0.2, 0.16, 0.12) if G.map_kind != "desert" else Color(0.55, 0.45, 0.32)
		"gun":
			t = "metal"
			tint = Color(0.45, 0.45, 0.45)
			m.metallic = 0.4
			m.roughness = 0.55
		"wood":
			tint = Color(0.42, 0.26, 0.14)
		"medic":
			tint = Color(0.95, 0.95, 0.95)
		"red":
			tint = Color(0.8, 0.08, 0.08)
	if t != "":
		m.albedo_texture = tex(t)
		var n := tex(t + "_n")
		if n:
			m.normal_enabled = true
			m.normal_texture = n
			m.normal_scale = 0.8
		m.uv1_scale = Vector3(uvs, uvs, uvs)
	m.albedo_color = tint
	_mat[key] = m
	return m

static func skinned(model: String, node: String, team: int) -> ArrayMesh:
	var key := "%s|%s|%d|%s" % [model, node, team, G.map_kind]
	if _skin.has(key):
		return _skin[key]
	var nd: Dictionary = nodes(model)
	if not nd.has(node):
		return null
	var src: ArrayMesh = nd[node]["mesh"]
	var out: ArrayMesh = src.duplicate()
	for i in out.get_surface_count():
		var sm := out.surface_get_material(i)
		var nm := String(sm.resource_name) if sm else "paint"
		out.surface_set_material(i, material(nm, team))
	_skin[key] = out
	return out

static func clear_cache() -> void:
	_mat.clear()
	_skin.clear()

# ------------------------------------------------------------ araç
static func vehicle(vtype: String, team: int) -> Dictionary:
	var model := "%s_%s" % [vtype, "blue" if team == 0 else "red"]
	if not has(model):
		return {}
	var nd := nodes(model)
	var md: Dictionary = meta(model).get("meta", {})
	var out := {"hulls": [], "turret": null, "barrel": null, "turret_pos": Vector3.ZERO, "barrel_pos": Vector3.ZERO, "muzzle": Vector3.ZERO, "wheels": []}
	var tp := Vector3.ZERO
	var bp := Vector3.ZERO
	if nd.has("turret"):
		tp = nd["turret"]["pos"]
	if nd.has("barrel"):
		bp = nd["barrel"]["pos"]
	for k in nd:
		var key: String = k
		if key == "turret":
			out["turret"] = skinned(model, key, team)
			out["turret_pos"] = tp
		elif key == "barrel":
			out["barrel"] = skinned(model, key, team)
			out["barrel_pos"] = bp - tp
		elif key.begins_with("wheel_"):
			var wm := skinned(model, key, team)
			var r := wm.get_aabb().size.y * 0.5
			out["wheels"].append([nd[key]["pos"], r, 0.4, wm])
		elif key == "rotor" or key == "trotor":
			out[key] = skinned(model, key, team)
			out[key + "_pos"] = nd[key]["pos"]
		else:
			out["hulls"].append([skinned(model, key, team), nd[key]["pos"]])
	if md.has("muzzle"):
		out["muzzle"] = v3(md["muzzle"]) - bp
	if md.has("gunner"):
		out["gunner"] = v3(md["gunner"])
	return out
