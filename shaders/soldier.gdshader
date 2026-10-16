shader_type spatial;
// Asker (tek yüzey, tek çizim çağrısı): malzeme kimliği UV2.x'te (tools/anim/build_soldier.py MAT_ID),
// köşe rengi = kıyafet kıvrım gölgesi (AO) / ten ayrıntısı (kaş, dudak). Kamuflaj, yelek ve deri dokuları
// kimliğe göre seçilir; üniformada kıyafetin kendi kıvrım normali + kumaş dokuma normali; altta çamur, üstte toz.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D camo_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;   // üniforma
uniform sampler2D camo_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;   // yelek / çanta / kask
uniform sampler2D leather : source_color, filter_linear_mipmap_anisotropic, repeat_enable;  // bot
uniform sampler2D fab_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;   // kumaş dokuma
uniform sampler2D fold_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;  // kıyafet kıvrımları (UV atlası)
uniform bool has_fold = false;
uniform sampler2D grime_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float camo_k = 3.2;         // kıyafet UV atlası → kamuflaj tekrarı
uniform vec4 tints[16];             // kimliğe göre renk (doğrusal)
uniform vec4 props[16];             // x pürüzlülük, y metal, z doku (0 yok, 1 üniforma, 2 yelek, 3 deri), w ışıma
uniform vec4 dirt_col : source_color = vec4(0.36, 0.30, 0.22, 1.0);
uniform vec4 dust_col : source_color = vec4(0.6, 0.55, 0.45, 1.0);
uniform float dirt_amount = 0.55;
uniform float dust_amount = 0.1;

varying flat int mid;
varying float wy;

void vertex() {
	mid = int(UV2.x + 0.5);
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y - NODE_POSITION_WORLD.y;
}

void fragment() {
	int id = clamp(mid, 0, 15);
	vec4 tn = tints[id];
	vec4 pr = props[id];
	int tx = int(pr.z + 0.5);
	vec2 uv = UV * (id == 0 ? camo_k : 1.0);
	vec3 base = tn.rgb * COLOR.rgb;
	if (tx == 1) {
		base *= texture(camo_a, uv).rgb;
	} else if (tx == 2) {
		base *= texture(camo_b, uv).rgb;
	} else if (tx == 3) {
		base *= texture(leather, uv).rgb;
	}
	// çamur altta (ayak tabanından yükseklik), toz yukarı bakan yüzeylerde; leke gürültüsü UV'de (deriyle yüzmez)
	float g = dot(texture(grime_tex, uv * 0.6).rgb, vec3(0.3333));
	float skin = (id == 6 || id == 14) ? 0.0 : 1.0;
	float dh = clamp(1.0 - wy / 0.6, 0.0, 1.0);
	float dirt = clamp(dh * dh * dirt_amount * (0.6 + g * 1.4), 0.0, 1.0) * skin;
	base = mix(base, dirt_col.rgb, dirt);
	vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
	float dust = clamp(smoothstep(0.5, 0.95, wn.y) * dust_amount * (0.5 + g), 0.0, 1.0) * skin;
	base = mix(base, dust_col.rgb, dust);
	ALBEDO = base;
	ROUGHNESS = clamp(pr.x + dirt * 0.2, 0.05, 1.0);
	METALLIC = pr.y * (1.0 - dirt);
	if (pr.w > 0.0) {
		EMISSION = tn.rgb * pr.w;
	}
	vec3 nm = vec3(0.5, 0.5, 1.0);
	if (tx == 1 || tx == 2) {
		nm = texture(fab_nrm, uv * 2.0).rgb;
	} else if (tx == 3) {
		nm = vec3(0.5, 0.5, 1.0);
	}
	if (id == 0 && has_fold) {
		vec3 f = texture(fold_nrm, UV).rgb;
		nm = normalize(vec3((nm.xy - 0.5) * 0.6 + (f.xy - 0.5), 0.5)) * 0.5 + 0.5;
	}
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = 1.0;
}
