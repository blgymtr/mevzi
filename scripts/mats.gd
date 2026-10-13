class_name Mats extends RefCounted
# Paylaşılan malzemeler (vertex renkli, düşük maliyetli).

static var _c := {}

static func vc() -> StandardMaterial3D:
	if not _c.has("vc"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.86
		m.specular_mode = BaseMaterial3D.SPECULAR_SCHLICK_GGX
		_c["vc"] = m
	return _c["vc"]

static func vc2() -> StandardMaterial3D:
	# çift yüzlü (yaprak, tente)
	if not _c.has("vc2"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		_c["vc2"] = m
	return _c["vc2"]

static func metal() -> StandardMaterial3D:
	if not _c.has("metal"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.62
		m.metallic = 0.15
		m.metallic_specular = 0.55
		_c["metal"] = m
	return _c["metal"]

static func stone() -> StandardMaterial3D:
	# taş/sıva bloklar: dünya üç düzlemli hafif gürültü dokusu
	if not _c.has("stone"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.roughness = 0.9
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.035
		fn.fractal_octaves = 4
		nt.noise = fn
		var gr := Gradient.new()
		gr.set_color(0, Color(0.8, 0.8, 0.8))
		gr.set_color(1, Color(1.0, 1.0, 1.0))
		nt.color_ramp = gr
		m.albedo_texture = nt
		m.uv1_triplanar = true
		m.uv1_world_triplanar = true
		m.uv1_scale = Vector3(0.9, 0.9, 0.9)
		_c["stone"] = m
	return _c["stone"]

static func burnt() -> StandardMaterial3D:
	if not _c.has("burnt"):
		var m := StandardMaterial3D.new()
		m.albedo_color = Color(0.11, 0.10, 0.09)
		m.roughness = 1.0
		_c["burnt"] = m
	return _c["burnt"]

static func flat(col: Color, rough := 0.85, emis := 0.0) -> StandardMaterial3D:
	var key := "f%s_%s_%s" % [col.to_html(), rough, emis]
	if not _c.has(key):
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.roughness = rough
		if emis > 0.0:
			m.emission_enabled = true
			m.emission = col
			m.emission_energy_multiplier = emis
		_c[key] = m
	return _c[key]

static func unshaded(col: Color, transparent := true, no_depth := false) -> StandardMaterial3D:
	var key := "u%s_%s_%s" % [col.to_html(), transparent, no_depth]
	if not _c.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = col
		if transparent:
			m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
		if no_depth:
			m.no_depth_test = true
		m.disable_receive_shadows = true
		_c[key] = m
	return _c[key]

static func ghost(ok: bool) -> StandardMaterial3D:
	var key := "ghost%s" % ok
	if not _c.has(key):
		var m := StandardMaterial3D.new()
		m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		m.albedo_color = Color(0.3, 1.0, 0.45, 0.42) if ok else Color(1.0, 0.25, 0.2, 0.42)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.disable_receive_shadows = true
		_c[key] = m
	return _c[key]

static func construct() -> StandardMaterial3D:
	if not _c.has("construct"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(0.85, 0.75, 0.55, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		_c["construct"] = m
	return _c["construct"]
