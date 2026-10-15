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

static func vcs() -> StandardMaterial3D:
	# sRGB tepe rengi (doğru doygunluk) — siper, toprak set, kalas
	if not _c.has("vcs"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.92
		_c["vcs"] = m
	return _c["vcs"]

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

static func _mt(id: String, map: String) -> Texture2D:
	var p := "res://assets/materials/%s/%s.jpg" % [id, map]
	return load(p) if ResourceLoader.exists(p) else null

# duvar blokları: sıva / tuğla / beton (CC0), kesintisiz dünya izdüşümü
static func masonry() -> Material:
	if not _c.has("masonry"):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/masonry.gdshader")
		m.set_shader_parameter("plaster_alb", _mt("painted_plaster_wall", "albedo"))
		m.set_shader_parameter("plaster_nrm", _mt("painted_plaster_wall", "normal"))
		m.set_shader_parameter("brick_alb", _mt("brick_wall_02", "albedo"))
		m.set_shader_parameter("brick_nrm", _mt("brick_wall_02", "normal"))
		m.set_shader_parameter("concrete_alb", _mt("concrete_wall_005", "albedo"))
		m.set_shader_parameter("concrete_nrm", _mt("concrete_wall_005", "normal"))
		m.set_shader_parameter("streak_tex", _mt("rusty_painted_metal", "albedo"))
		m.set_shader_parameter("chip_alb", _mt("rough_plaster_brick", "albedo"))
		m.set_shader_parameter("wood_alb", _mt("brown_planks_05", "albedo"))
		m.set_shader_parameter("metal_alb", _mt("corrugated_iron_02", "albedo"))
		m.set_shader_parameter("panel_alb", _mt("precast_concrete_wall", "albedo"))
		m.set_shader_parameter("rough_alb", _mt("white_plaster_rough_02", "albedo"))
		m.set_shader_parameter("steel_alb", _mt("metal_plate_02", "albedo"))
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.03
		fn.fractal_octaves = 4
		nt.noise = fn
		m.set_shader_parameter("noise_tex", nt)
		_c["masonry"] = m
	return _c["masonry"]

# çatı: kiremit dokusu eğime hizalı, kışta yumuşak kar
static func roof(snow: bool) -> Material:
	var key := "roof_%s" % snow
	if not _c.has(key):
		var m := ShaderMaterial.new()
		m.shader = load("res://shaders/roof.gdshader")
		m.set_shader_parameter("tile_alb", _mt("clay_roof_tiles_02", "albedo"))
		m.set_shader_parameter("tile_nrm", _mt("clay_roof_tiles_02", "normal"))
		var nt := NoiseTexture2D.new()
		nt.width = 256
		nt.height = 256
		nt.seamless = true
		var fn := FastNoiseLite.new()
		fn.frequency = 0.02
		fn.fractal_octaves = 4
		nt.noise = fn
		m.set_shader_parameter("noise_tex", nt)
		m.set_shader_parameter("snow", 1.0 if snow else 0.0)
		_c[key] = m
	return _c[key]

# çatı (doku seçmeli): kil / arduvaz / kiremit / sac / paslı sac / beton / kurşun / bakır / kerpiç / ahşap
const ROOF_TEX := {"clay": ["clay_roof_tiles_02", 0.0, 0.85, 1.0], "slate": ["grey_roof_tiles", 0.0, 0.8, 1.1], "tile": ["roof_tiles_14", 0.0, 0.8, 1.15],
	"metal": ["corrugated_iron_02", 1.0, 0.45, 1.5], "rust": ["worn_corrugated_iron", 0.0, 0.45, 1.0], "conc": ["concrete_wall_005", 1.0, 0.35, 0.75],
	"lead": ["metal_plate_02", 1.0, 0.6, 1.6], "copper": ["green_metal_rust", 0.0, 0.5, 1.0], "mud": ["white_plaster_rough_02", 1.0, 0.5, 1.0], "wood": ["brown_planks_05", 0.7, 0.6, 1.0]}

static func roof2(tex: String, snow: bool) -> Material:
	if not ROOF_TEX.has(tex):
		return roof(snow)
	var key := "roof2_%s_%s" % [tex, snow]
	if not _c.has(key):
		var m: ShaderMaterial = (roof(snow) as ShaderMaterial).duplicate()
		var t: Array = ROOF_TEX[tex]
		m.set_shader_parameter("tile_alb", _mt(t[0], "albedo"))
		m.set_shader_parameter("tile_nrm", _mt(t[0], "normal"))
		m.set_shader_parameter("mono", t[1])
		m.set_shader_parameter("gain", t[3])
		m.set_shader_parameter("scale", t[2])
		_c[key] = m
	return _c[key]

# pencere camı: koyu, hafif yansımalı
static func glass() -> StandardMaterial3D:
	if not _c.has("glass"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.12
		m.metallic = 0.35
		m.metallic_specular = 0.8
		_c["glass"] = m
	return _c["glass"]

# sRGB tepe rengi + hafif metalik (klima, depo, korkuluk)
static func metal_s() -> StandardMaterial3D:
	if not _c.has("metal_s"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.vertex_color_is_srgb = true
		m.roughness = 0.55
		m.metallic = 0.25
		_c["metal_s"] = m
	return _c["metal_s"]

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

static func ghost_model(ok: bool) -> StandardMaterial3D:
	# yerleştirme önizlemesi: gölgeli (biçim okunur), tepe rengi + yeşil/kırmızı ton, yarı saydam
	var key := "ghostm%s" % ok
	if not _c.has(key):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(0.75, 1.0, 0.8, 0.62) if ok else Color(1.0, 0.55, 0.5, 0.62)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.emission_enabled = true
		m.emission = Color(0.05, 0.25, 0.08) if ok else Color(0.3, 0.04, 0.02)
		m.roughness = 0.9
		_c[key] = m
	return _c[key]

static var _reveal_sh: Shader = null

static func reveal(srgb: bool) -> ShaderMaterial:
	if _reveal_sh == null:
		_reveal_sh = Shader.new()
		_reveal_sh.code = """
shader_type spatial;
render_mode cull_disabled;
uniform float cut = 0.0;
uniform float base_y = 0.0;
uniform bool srgb = false;
varying vec3 wpos;
void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}
void fragment() {
	float h = wpos.y - base_y;
	if (h > cut) { discard; }
	vec3 c = COLOR.rgb;
	if (srgb) { c = mix(pow((c + 0.055) / 1.055, vec3(2.4)), c / 12.92, step(c, vec3(0.04045))); }
	// en üst sıra: taze harç/kalas, biraz açık ve mat
	float e = smoothstep(cut - 0.35, cut, h);
	c = mix(c, c * 1.18 + vec3(0.03, 0.025, 0.015), e * 0.7);
	ALBEDO = c;
	ROUGHNESS = 0.92;
}
"""
	var m := ShaderMaterial.new()
	m.shader = _reveal_sh
	m.set_shader_parameter("srgb", srgb)
	return m

static func construct() -> StandardMaterial3D:
	if not _c.has("construct"):
		var m := StandardMaterial3D.new()
		m.vertex_color_use_as_albedo = true
		m.albedo_color = Color(0.85, 0.75, 0.55, 0.55)
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.roughness = 1.0
		_c["construct"] = m
	return _c["construct"]
