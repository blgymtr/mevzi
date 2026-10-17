shader_type spatial;
// Araç / asker malzemesi: kamuflaj ya da kumaş tabanı + gerçek (CC0) doku katmanları:
// yağmur akıntısı izleri, pas lekeleri, metal mikro yüzey normali, altta çamur, üstte toz.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_albedo = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform float uv_scale = 1.0;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_normal = false;
uniform float normal_strength = 0.8;
uniform float roughness = 0.8;
uniform float metallic = 0.0;

// ayrıntı katmanları (model uzayında üçlü izdüşüm)
uniform sampler2D streak_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;   // akıntı/pas izleri
uniform sampler2D grime_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;    // leke / kir gürültüsü
uniform sampler2D micro_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;     // metal yüzey normali
uniform sampler2D micro_rough : hint_default_white, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float detail_scale = 0.45;
uniform float streaks = 0.35;
uniform float rust = 0.25;
uniform float micro = 0.6;
uniform vec4 rust_col : source_color = vec4(0.30, 0.17, 0.09, 1.0);
uniform vec4 dirt_col : source_color = vec4(0.36, 0.30, 0.22, 1.0);
uniform float dirt_height = 0.9;
uniform float dirt_amount = 0.6;
uniform vec4 dust_col : source_color = vec4(0.6, 0.55, 0.45, 1.0);
uniform float dust_amount = 0.0;
// yanmış enkaz (0..1): boya yanar — is (siyah), pas (kahve-turuncu), kül (açık gri) lekeleri; köşe rengindeki
// pişmiş AO ve normal ayrıntısı korunur (düz siyah siluet değil)
uniform float burnt = 0.0;

varying vec3 mpos;
varying vec3 mnrm;
varying float wy;

void vertex() {
	mpos = VERTEX;
	mnrm = NORMAL;
	wy = (MODEL_MATRIX * vec4(VERTEX, 1.0)).y;
}

vec4 tri(sampler2D t, vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y > a.x && a.y > a.z) return texture(t, p.xz);
	return a.x > a.z ? texture(t, p.zy) : texture(t, p.xy);
}

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
	vec3 vc = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 base = tint.rgb * vc;
	if (has_albedo) {
		base *= texture(albedo_tex, UV * uv_scale).rgb;
	}
	vec3 p = mpos * detail_scale;
	vec3 n = normalize(mnrm);
	// yağmur akıntısı: dikey izler yan yüzlerde, dokunun parlaklık sapması kadar
	vec3 st = tri(streak_tex, p * vec3(1.0, 0.6, 1.0), n).rgb;
	float sl = lum(st);
	float side = 1.0 - abs(n.y);
	base *= mix(1.0, clamp(0.55 + sl * 1.15, 0.6, 1.25), streaks * (0.4 + side * 0.6));
	// pas / aşınma: koyu izlerde pas rengine kay
	float rmask = smoothstep(0.28, 0.12, sl) * rust;
	base = mix(base, rust_col.rgb * (0.7 + sl), clamp(rmask, 0.0, 1.0));
	// kir lekeleri
	float g = lum(tri(grime_tex, p * 1.7 + vec3(3.1, 0.0, 1.7), n).rgb);
	// alt kısımda çamur, üst yüzeyde toz
	float dh = clamp(1.0 - wy / max(dirt_height, 0.01), 0.0, 1.0);
	float dirt = clamp(dh * dh * dirt_amount * (0.6 + g * 1.4), 0.0, 1.0);
	base = mix(base, dirt_col.rgb, dirt);
	float dust = clamp(smoothstep(0.55, 0.95, n.y) * dust_amount * (0.5 + g), 0.0, 1.0);
	base = mix(base, dust_col.rgb, dust);
	if (burnt > 0.0) {
		// (142) köşe rengi çoğu modelde boyanın kendisi (koyu zeytin ~0,05–0,1): mutlak parlaklığı AO saymak tüm
		// hurdayı ×0,3 karartıp lekeleri yok ediyordu → yalnız boyaya göre bağıl karanlık (pişmiş AO) alınır
		float ao = clamp(lum(vc) / 0.12, 0.55, 1.0);
		// (142) lekeler büyük ölçekte (araç boyunda birkaç leke, uzaktan okunur) + ince ayrıntı; dokunun
		// parlaklığı yayılarak kontrast açılır
		float gn = clamp((lum(tri(grime_tex, p * 0.35 + vec3(5.3, 2.1, 7.7), n).rgb) - 0.5) * 2.2 + 0.5, 0.0, 1.0) * 0.75
			+ lum(tri(grime_tex, p * 1.4 + vec3(1.1, 3.3, 0.7), n).rgb) * 0.25;
		float gn2 = clamp((lum(tri(streak_tex, p * 0.6 + vec3(1.7, 4.2, 0.3), n).rgb) - 0.5) * 2.2 + 0.5, 0.0, 1.0);
		vec3 soot = vec3(0.04, 0.037, 0.034);
		vec3 rustc = vec3(0.34, 0.155, 0.065) * (0.7 + gn2 * 0.6);
		vec3 ash = vec3(0.4, 0.39, 0.37) * (0.85 + gn * 0.3);
		float rm = smoothstep(0.22, 0.48, gn + side * 0.14 - n.y * 0.06);
		float am = smoothstep(0.5, 0.78, gn2 + n.y * 0.2) * 0.8;
		vec3 bc = mix(soot, rustc, rm * 0.85);
		bc = mix(bc, ash, am * (1.0 - rm * 0.5));
		// (142) yanmış ama tamamen kararmamış: alt kısımlarda ve büyük lekelerde özgün boya kalır (kabarmış,
		// koyulaşmış, kahveye dönmüş); tek renk siyah siluet yerine okunabilir araç biçimi
		float keep = smoothstep(0.35, 0.65, lum(tri(grime_tex, p * 0.18 + vec3(2.9, 0.4, 6.1), n).rgb)) * (1.0 - smoothstep(-0.3, 0.6, n.y));
		keep *= clamp(1.0 - (wy - 0.5) * 0.45, 0.25, 1.0);
		vec3 scorched = mix(base, vec3(0.16, 0.11, 0.07), 0.45) * 0.55;
		bc = mix(bc, scorched, keep * 0.75);
		// ısıyla kabaran boya: küçük açık kenarlı pullar
		float blister = smoothstep(0.78, 0.86, gn2) * (1.0 - rm);
		bc = mix(bc, ash * 1.15, blister * 0.4);
		base = mix(base, bc * ao, burnt);
	}
	ALBEDO = base;
	// yüzey ayrıntısı
	float mr = tri(micro_rough, p * 2.0, n).r;
	ROUGHNESS = mix(clamp(roughness * mix(1.0, 0.75 + mr * 0.5, micro) + dirt * 0.25, 0.05, 1.0), 0.93, burnt);
	METALLIC = mix(metallic * (1.0 - dirt), 0.1, burnt);
	vec3 nm = vec3(0.5, 0.5, 1.0);
	if (has_normal) {
		nm = texture(normal_tex, UV * uv_scale).rgb;
	}
	vec3 dn = tri(micro_nrm, p * 2.0, n).rgb;
	nm = normalize(vec3((nm.xy - 0.5) + (dn.xy - 0.5) * micro, 0.5)) * 0.5 + 0.5;
	NORMAL_MAP = nm;
	NORMAL_MAP_DEPTH = normal_strength;
}
