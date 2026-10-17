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

# ulus boya şemaları (biyoma göre)
static func nation_paint(nat: String) -> String:
	var b: String = G.map_kind
	if b == "winter":
		return "camo_snow"
	match nat:
		"usa", "gbr":
			return "paint_sand" if b == "desert" else "camo_wood"
		"rus":
			return "paint_sand" if b == "desert" else "paint_olive"
		"chn":
			return "camo_desert" if b == "desert" else "camo_wood"
	return paint_tex(0)

static func uniform_tex(team: int) -> String:
	var b: String = G.map_kind
	if b == "winter":
		return "fab_snow"
	if team == 0:
		return "fab_ocp"
	return "fab_emr_desert" if b == "desert" else "fab_emr"

static func vest_tex(team: int) -> String:
	if G.map_kind == "winter":
		return "fab_snow"
	return "fab_coyote" if team == 0 else ("fab_emr_desert" if G.map_kind == "desert" else "fab_ratnik")

static var _armor_shader: Shader
static var _soldier_shader: Shader

# derili asker (tools/anim/build_soldier.py): tek yüzey, malzeme kimliği UV2.x'te → kimliğe göre renk/doku
# sıra build_soldier.MAT_ID ile aynı: uniform vest pack helmet boot glove skin dark gun team lens red rubber canvas eye strap
static func soldier_material(model: String, team: int) -> Material:
	var key := "soldier|%s|%d|%s" % [model, team, G.map_kind]
	if _mat.has(key):
		return _mat[key]
	if _soldier_shader == null:
		_soldier_shader = load("res://shaders/soldier.gdshader")
	var sm := ShaderMaterial.new()
	sm.shader = _soldier_shader
	sm.set_shader_parameter("camo_a", tex(uniform_tex(team)))
	sm.set_shader_parameter("camo_b", tex(vest_tex(team)))
	sm.set_shader_parameter("leather", tex("leather"))
	sm.set_shader_parameter("fab_nrm", mat_tex("hessian_230", "normal"))
	sm.set_shader_parameter("grime_tex", mat_tex("rust_coarse_01", "albedo"))
	var fp := "res://assets/models/%s_fold_n.png" % model.trim_suffix("_rig")
	sm.set_shader_parameter("has_fold", ResourceLoader.exists(fp))
	if ResourceLoader.exists(fp):
		sm.set_shader_parameter("fold_nrm", load(fp))
	var k := 3.2
	var jf := FileAccess.open("res://assets/models/%s.json" % model, FileAccess.READ)
	if jf:
		var js = JSON.parse_string(jf.get_as_text())
		if js is Dictionary and js.has("camo_k"):
			k = float(js["camo_k"])
	sm.set_shader_parameter("camo_k", k)
	var winter: bool = G.map_kind == "winter"
	var us := team == 0
	var boot := Color(0.62, 0.5, 0.36) if us else Color(0.09, 0.08, 0.07)
	var glove := Color(0.55, 0.47, 0.35) if us else Color(0.16, 0.16, 0.15)
	var strap := Color(0.47, 0.4, 0.29) if us else Color(0.26, 0.28, 0.19)
	if winter:
		glove = Color(0.75, 0.75, 0.72)
		strap = Color(0.8, 0.8, 0.78)
	var team_c: Color = Color(0.12, 0.45, 0.95) if us else Color(0.85, 0.12, 0.08)
	# [renk (sRGB), pürüzlülük, metal, doku, ışıma]
	var spec := [
		[Color(1, 1, 1), 0.95, 0.0, 1, 0.0],            # 0 üniforma
		[Color(1, 1, 1), 0.95, 0.0, 2, 0.0],            # 1 yelek
		[Color(0.9, 0.9, 0.88), 0.95, 0.0, 2, 0.0],     # 2 çanta / cep
		[Color(0.92, 0.92, 0.9), 0.8, 0.0, 2, 0.0],     # 3 kask
		[boot, 0.75, 0.0, 3, 0.0],                      # 4 bot
		[glove, 0.9, 0.0, 0, 0.0],                      # 5 eldiven
		[Color(0.72, 0.55, 0.42), 0.6, 0.0, 0, 0.0],    # 6 ten
		[Color(0.07, 0.07, 0.07), 0.55, 0.0, 0, 0.0],   # 7 koyu plastik
		[Color(0.13, 0.13, 0.13), 0.45, 0.5, 0, 0.0],   # 8 metal / şarjör
		[team_c, 0.6, 0.0, 0, 0.25],                    # 9 takım rengi
		[Color(0.95, 0.5, 0.08), 0.15, 0.3, 0, 0.25],   # 10 mercek
		[Color(0.8, 0.08, 0.08), 0.7, 0.0, 0, 0.0],     # 11 kırmızı (turnike)
		[Color(0.06, 0.06, 0.06), 0.95, 0.0, 0, 0.0],   # 12 kauçuk
		[Color(0.6, 0.56, 0.42), 0.95, 0.0, 0, 0.0],    # 13 branda
		[Color(0.85, 0.85, 0.83), 0.3, 0.0, 0, 0.0],    # 14 göz
		[strap, 0.9, 0.0, 0, 0.0],                      # 15 kayış (dokuma)
	]
	# Vector4 dizileri: Color dizisi verilirse motor sRGB→doğrusal çevirir (doku seçicisi bozulur)
	var tints := PackedVector4Array()
	var props := PackedVector4Array()
	for s in spec:
		var c: Color = (s[0] as Color).srgb_to_linear()
		tints.append(Vector4(c.r, c.g, c.b, 1.0))
		props.append(Vector4(s[1], s[2], float(s[3]), s[4]))
	sm.set_shader_parameter("tints", tints)
	sm.set_shader_parameter("props", props)
	var dd := _dirt()
	sm.set_shader_parameter("dirt_col", dd["dirt"])
	sm.set_shader_parameter("dust_col", dd["dust"])
	sm.set_shader_parameter("dust_amount", dd["dust_a"])
	_mat[key] = sm
	return sm

static func mat_tex(id: String, map: String) -> Texture2D:
	var p := "res://assets/materials/%s/%s.jpg" % [id, map]
	return load(p) if ResourceLoader.exists(p) else null

# biyoma göre çamur / toz
static func _dirt() -> Dictionary:
	match G.map_kind:
		"desert":
			return {"dirt": Color(0.62, 0.52, 0.38), "dust": Color(0.74, 0.65, 0.5), "dust_a": 0.35}
		"winter":
			return {"dirt": Color(0.42, 0.4, 0.37), "dust": Color(0.92, 0.93, 0.96), "dust_a": 0.45}
	return {"dirt": Color(0.4, 0.34, 0.24), "dust": Color(0.52, 0.5, 0.4), "dust_a": 0.1}

static func material(name: String, team: int) -> Material:
	var key := "%s|%d|%s" % [name, team, G.map_kind]
	if _mat.has(key):
		return _mat[key]
	var t := ""
	var tint := Color.WHITE
	var uvs := 1.0
	var rough := 0.85
	var metal := 0.0
	# katman şiddetleri: [akıntı, pas, mikro, çamur]
	var lay := [0.0, 0.0, 0.3, 0.3]
	var normal_tex := ""
	var shaded := true
	# katalog modelleri: "paint_usa", "trim_rus" → ulusun boya şeması
	var nat := ""
	for nn in ["usa", "rus", "chn", "gbr"]:
		if name.ends_with("_" + nn):
			nat = nn
			name = name.substr(0, name.length() - nn.length() - 1)
	match name:
		"paint":
			t = paint_tex(team) if nat == "" else nation_paint(nat)
			rough = 0.7
			metal = 0.12
			uvs = 0.6
			# katalog araçları: belirgin akıntı, pas, mikro yüzey ve alt gövde çamuru
			lay = [0.4, 0.22, 0.7, 0.75] if nat == "" else [0.7, 0.38, 0.95, 1.0]
		"trim":
			t = paint_tex(team) if nat == "" else nation_paint(nat)
			tint = Color(0.62, 0.62, 0.6)
			uvs = 0.6
			rough = 0.72
			metal = 0.12
			lay = [0.45, 0.3, 0.7, 0.8]
		"metal":
			t = "metal"
			metal = 0.55
			rough = 0.45
			lay = [0.2, 0.35, 0.9, 0.6]
		"track":
			t = "track"
			rough = 0.85
			metal = 0.3
			lay = [0.1, 0.5, 0.6, 1.0]
		"rubber":
			t = "rubber"
			rough = 0.95
			lay = [0.0, 0.0, 0.2, 1.0]
		"canvas":
			t = "canvas" if tex("canvas") != null else ""
			tint = Color(0.6, 0.56, 0.42)
			rough = 0.95
			normal_tex = "hessian_230"
			lay = [0.25, 0.0, 0.0, 0.5]
		"uniform", "vest", "helmet":
			t = uniform_tex(team) if name == "uniform" else vest_tex(team)
			rough = 0.95 if name != "helmet" else 0.8
			uvs = 2.5
			normal_tex = "hessian_230"
			if name == "helmet":
				tint = Color(0.92, 0.92, 0.9)
			lay = [0.0, 0.0, 0.0, 0.55]
		"pack":
			t = vest_tex(team)
			uvs = 2.5
			normal_tex = "hessian_230"
			lay = [0.0, 0.0, 0.0, 0.5]
		"boot":
			t = "leather"
			tint = Color(0.62, 0.5, 0.36) if team == 0 else Color(0.09, 0.08, 0.07)
			normal_tex = "brown_leather"
			lay = [0.0, 0.0, 0.0, 0.9]
		"gun":
			t = "metal"
			tint = Color(0.45, 0.45, 0.45)
			metal = 0.4
			rough = 0.55
			lay = [0.0, 0.1, 0.6, 0.0]
		"glove":
			tint = Color(0.36, 0.3, 0.22)
			rough = 0.9
			lay = [0.0, 0.0, 0.0, 0.3]
		"wood":
			tint = Color(0.42, 0.26, 0.14)
			lay = [0.2, 0.0, 0.3, 0.3]
		"airgray":
			# hava aracı boyası (İHA): kamuflajsız açık gri (FS 36375 benzeri), hafif yağ akıntısı, çamur yok
			tint = Color(0.6, 0.62, 0.63) if team != 1 else Color(0.66, 0.67, 0.66)
			rough = 0.5
			metal = 0.08
			lay = [0.3, 0.0, 0.55, 0.0]
		_:
			shaded = false
	if shaded:
		if _armor_shader == null:
			_armor_shader = load("res://shaders/armor.gdshader")
		var sm := ShaderMaterial.new()
		sm.shader = _armor_shader
		var at := tex(t) if t != "" else null
		sm.set_shader_parameter("has_albedo", at != null)
		if at:
			sm.set_shader_parameter("albedo_tex", at)
		var nt: Texture2D = mat_tex(normal_tex, "normal") if normal_tex != "" else (tex(t + "_n") if t != "" else null)
		sm.set_shader_parameter("has_normal", nt != null)
		if nt:
			sm.set_shader_parameter("normal_tex", nt)
		sm.set_shader_parameter("tint", tint)
		sm.set_shader_parameter("uv_scale", uvs)
		sm.set_shader_parameter("roughness", rough)
		sm.set_shader_parameter("metallic", metal)
		sm.set_shader_parameter("streak_tex", mat_tex("rusty_painted_metal", "albedo"))
		sm.set_shader_parameter("grime_tex", mat_tex("rust_coarse_01", "albedo"))
		sm.set_shader_parameter("micro_nrm", mat_tex("metal_plate_02", "normal"))
		sm.set_shader_parameter("micro_rough", mat_tex("metal_plate_02", "rough"))
		sm.set_shader_parameter("streaks", lay[0])
		sm.set_shader_parameter("rust", lay[1])
		sm.set_shader_parameter("micro", lay[2])
		var dd := _dirt()
		sm.set_shader_parameter("dirt_amount", lay[3])
		sm.set_shader_parameter("dirt_col", dd["dirt"])
		sm.set_shader_parameter("dust_col", dd["dust"])
		sm.set_shader_parameter("dust_amount", dd["dust_a"] if name in ["paint", "trim", "canvas", "pack", "helmet"] else 0.0)
		sm.set_shader_parameter("dirt_height", 0.5 if name in ["uniform", "vest", "helmet", "pack", "boot"] else 1.0)
		_mat[key] = sm
		return sm
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.vertex_color_is_srgb = true
	m.roughness = 0.85
	match name:
		"glass":
			tint = Color(0.1, 0.13, 0.16)
			m.roughness = 0.12
			m.metallic = 0.4
		"mark":
			tint = G.TEAM_COL[team].lerp(Color(0.85, 0.85, 0.8), 0.25)
			m.roughness = 0.6
		"light":
			tint = Color(1.0, 0.95, 0.8)
			m.emission_enabled = true
			m.emission = Color(1.0, 0.9, 0.7)
			m.emission_energy_multiplier = 0.4
		"dark":
			tint = Color(0.07, 0.07, 0.07)
		"lens":
			tint = Color(0.95, 0.5, 0.08)
			m.roughness = 0.15
			m.metallic = 0.3
			m.emission_enabled = true
			m.emission = Color(0.9, 0.45, 0.05)
			m.emission_energy_multiplier = 0.25
		"skin":
			tint = Color(0.72, 0.55, 0.42)
			m.roughness = 0.7
		"team":
			tint = Color(0.12, 0.45, 0.95) if team == 0 else Color(0.85, 0.12, 0.08)
			m.emission_enabled = true
			m.emission = tint
			m.emission_energy_multiplier = 0.25
		"medic":
			tint = Color(0.95, 0.95, 0.95)
		"red":
			tint = Color(0.8, 0.08, 0.08)
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

# sivil araç: tek mesh, boya rengi verilir; tozlu / kirli araç boyası
static func civil(model: String, col: Color) -> ArrayMesh:
	var key := "civ|%s|%s|%s" % [model, col.to_html(), G.map_kind]
	if _skin.has(key):
		return _skin[key]
	var nd := nodes(model)
	if not nd.has("body"):
		return null
	var out: ArrayMesh = (nd["body"]["mesh"] as ArrayMesh).duplicate()
	for i in out.get_surface_count():
		var sm := out.surface_get_material(i)
		var nm := String(sm.resource_name) if sm else "body"
		out.surface_set_material(i, _civil_mat(nm, col))
	_skin[key] = out
	return out

static func _civil_mat(nm: String, col: Color) -> Material:
	var key := "civm|%s|%s|%s" % [nm, col.to_html() if nm == "body" else "", G.map_kind]
	if _mat.has(key):
		return _mat[key]
	var m: Material
	match nm:
		"body":
			if _armor_shader == null:
				_armor_shader = load("res://shaders/armor.gdshader")
			var sm := ShaderMaterial.new()
			sm.shader = _armor_shader
			sm.set_shader_parameter("tint", col)
			sm.set_shader_parameter("roughness", 0.42)
			sm.set_shader_parameter("metallic", 0.35)
			sm.set_shader_parameter("streak_tex", mat_tex("rusty_painted_metal", "albedo"))
			sm.set_shader_parameter("grime_tex", mat_tex("rust_coarse_01", "albedo"))
			sm.set_shader_parameter("micro_nrm", mat_tex("metal_plate_02", "normal"))
			sm.set_shader_parameter("micro_rough", mat_tex("metal_plate_02", "rough"))
			sm.set_shader_parameter("streaks", 0.25)
			sm.set_shader_parameter("rust", 0.08)
			sm.set_shader_parameter("micro", 0.2)
			var dd := _dirt()
			sm.set_shader_parameter("dirt_amount", 0.6)
			sm.set_shader_parameter("dirt_height", 0.7)
			sm.set_shader_parameter("dirt_col", dd["dirt"])
			sm.set_shader_parameter("dust_col", dd["dust"])
			sm.set_shader_parameter("dust_amount", dd["dust_a"] * 1.5)
			m = sm
		"chrome":
			var c := StandardMaterial3D.new()
			c.albedo_color = Color(0.7, 0.7, 0.72)
			c.metallic = 0.9
			c.roughness = 0.25
			m = c
		"rubber":
			var r := StandardMaterial3D.new()
			r.albedo_color = Color(0.06, 0.06, 0.06)
			r.roughness = 0.95
			m = r
		"trim":
			var t := StandardMaterial3D.new()
			t.albedo_color = Color(0.1, 0.1, 0.1)
			t.roughness = 0.7
			m = t
		_:
			m = material(nm, 0)
	_mat[key] = m
	return m

static func clear_cache() -> void:
	_mat.clear()
	_skin.clear()
	_burnt.clear()

# yanmış enkaz (94): örgünün her yüzeyine aynı malzemenin yanmış çeşidi (armor gölgelendiricisinde burnt = 1:
# is / pas / kül, doku + AO ayrıntısı korunur); başka malzemeler (cam, işaret, ışık) düz yanık
static var _burnt := {}
static func burnt_of(m: Material) -> Material:
	if m == null:
		return Mats.burnt()
	var k := m.get_instance_id()
	if _burnt.has(k):
		return _burnt[k]
	var out: Material = Mats.burnt()
	if m is ShaderMaterial and _armor_shader != null and (m as ShaderMaterial).shader == _armor_shader:
		var d := (m as ShaderMaterial).duplicate() as ShaderMaterial
		d.set_shader_parameter("burnt", 1.0)
		out = d
	elif m is StandardMaterial3D and (m as StandardMaterial3D).vertex_color_use_as_albedo:
		# (142) köşe renkli düz malzeme (çoğu araç gövdesi, teker, ayrıntı): zırh gölgelendiricisinin yanık kipine
		# aktarılır — özgün renk (köşe rengi × ton) korunur, üstüne is / pas / kül / kabarmış boya lekeleri
		# (eskiden hepsi tek düz koyu kahve: hurda tek renk siluet gibiydi)
		var base_m = material("paint", 0)
		if base_m is ShaderMaterial:
			var d2 := (base_m as ShaderMaterial).duplicate() as ShaderMaterial
			var c: Color = (m as StandardMaterial3D).albedo_color
			d2.set_shader_parameter("tint", c)
			d2.set_shader_parameter("has_albedo", false)
			d2.set_shader_parameter("has_normal", false)
			d2.set_shader_parameter("burnt", 1.0)
			out = d2
	_burnt[k] = out
	return out

static func burn(mi: MeshInstance3D) -> void:
	if mi.mesh == null:
		return
	mi.material_override = null
	for s in mi.mesh.get_surface_count():
		var src: Material = mi.get_surface_override_material(s)
		if src == null:
			src = mi.mesh.surface_get_material(s)
		mi.set_surface_override_material(s, burnt_of(src))

# ------------------------------------------------------------ araç
static func vehicle(vtype: String, team: int) -> Dictionary:
	# taban tip: ulusun ayrıntılı modeli (data/catalog/base_models.json → <tip>_<ulus>.glb), yoksa eski mavi/kırmızı
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else ""
	if nat != "" and _has_model("%s_%s" % [vtype, nat]):
		return vehicle_model("%s_%s" % [vtype, nat], team)
	var model := "%s_%s" % [vtype, "blue" if team == 0 else "red"]
	return vehicle_model(model, team)

static var _model_ok := {}
static func _has_model(name: String) -> bool:
	if not _model_ok.has(name):
		_model_ok[name] = ResourceLoader.exists("res://assets/models/%s.glb" % name)
	return _model_ok[name]

static func vehicle_model(model: String, team: int) -> Dictionary:
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
		elif key.begins_with("prop"):
			# İHA pervanesi: [örgü, konum, eksen ('y' ileri → Godot Z, 'z' dikey → Godot Y)]
			if not out.has("props"):
				out["props"] = []
			out["props"].append([skinned(model, key, team), nd[key]["pos"], key.substr(4, 1)])
		elif key == "rotor" or key == "trotor" or key == "ramp":
			out[key] = skinned(model, key, team)
			out[key + "_pos"] = nd[key]["pos"]
		else:
			out["hulls"].append([skinned(model, key, team), nd[key]["pos"]])
	if md.has("muzzle"):
		out["muzzle"] = v3(md["muzzle"]) - bp
	if md.has("gunner"):
		out["gunner"] = v3(md["gunner"])
	if md.has("breech"):
		# çekili top: kama arkası (doldurucunun durduğu yer), namlu düğümüne göre
		out["breech"] = v3(md["breech"]) - bp
	out["meta"] = md
	return out
