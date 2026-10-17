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
uniform float burnt_seed = 0.0;   // araç başına leke deseni

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

// (142) yordamsal 3B değer gürültüsü: hurda lekeleri doku mipmap'ine bağlı kalmasın (büyük ölçekte doku tek
// gri tona ortalanıyor, tüm leke eşikleri aynı sonucu veriyordu)
float h31(vec3 p) {
	p = fract(p * 0.3183099 + vec3(0.71, 0.113, 0.419));
	p *= 17.0;
	return fract(p.x * p.y * p.z * (p.x + p.y + p.z));
}
float vnoise(vec3 x) {
	vec3 i = floor(x);
	vec3 f = fract(x);
	f = f * f * (3.0 - 2.0 * f);
	return mix(mix(mix(h31(i), h31(i + vec3(1, 0, 0)), f.x), mix(h31(i + vec3(0, 1, 0)), h31(i + vec3(1, 1, 0)), f.x), f.y),
		mix(mix(h31(i + vec3(0, 0, 1)), h31(i + vec3(1, 0, 1)), f.x), mix(h31(i + vec3(0, 1, 1)), h31(i + vec3(1, 1, 1)), f.x), f.y), f.z);
}
float fbm3(vec3 x) {
	return vnoise(x) * 0.55 + vnoise(x * 2.1 + 3.7) * 0.28 + vnoise(x * 4.3 + 9.1) * 0.17;
}

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
		// (142) lekeler yordamsal gürültüden (model uzayı metre: ~1,2 m leke + ince ayrıntı) — gerçek yanmış araç:
		// üst yüzler ve kapak çevresi is / kül, yan levhalarda pas-kahve akıntı ve lekeler, altta ve kenarlarda
		// kahveye dönmüş özgün boya; ısıyla kabarmış boya pulları
		vec3 q = mpos / 1.2 + vec3(burnt_seed * 7.3, 0.0, burnt_seed * 3.1);
		float nA = fbm3(q);
		float nB = fbm3(q * 0.55 + vec3(11.2, 4.4, 7.9));
		float nC = vnoise(mpos * 6.0 + 2.3);
		// renkler doğrusal uzayda (sRGB karşılığı: is ~0,1, pas ~(0,33, 0,2, 0,12), kül ~0,4)
		vec3 soot = vec3(0.012, 0.011, 0.01);
		vec3 rustc = mix(vec3(0.07, 0.03, 0.012), vec3(0.13, 0.055, 0.02), nC);
		vec3 ash = vec3(0.12, 0.115, 0.105) * (0.8 + nC * 0.4);
		// pas: yan yüzlerde, aşağı doğru akıntı (y ekseninde uzatılmış gürültü)
		float drip = fbm3(vec3(mpos.x * 1.6, mpos.y * 0.35, mpos.z * 1.6) + 5.1);
		float rm = smoothstep(0.5, 0.66, nA * 0.6 + drip * 0.4 + side * 0.08 - n.y * 0.15);
		// kül: üst yüzlerde seyrek açık gri lekeler
		float am = smoothstep(0.6, 0.74, nB) * smoothstep(0.3, 0.8, n.y);
		vec3 bc = mix(soot, rustc, rm);
		bc = mix(bc, ash, am * 0.85);
		// özgün boya kalıntısı: alt kısım ve büyük lekelerde, koyulaşmış / kahveye dönmüş
		float keep = smoothstep(0.55, 0.75, nB) * (1.0 - smoothstep(0.2, 0.8, n.y)) * clamp(1.4 - wy * 0.5, 0.2, 1.0);
		vec3 scorched = mix(base, vec3(0.2, 0.14, 0.08), 0.4) * 0.7;
		bc = mix(bc, scorched, keep);
		// kabarmış boya pulları
		float blister = smoothstep(0.88, 0.94, nC) * (1.0 - rm) * (1.0 - keep);
		bc = mix(bc, ash, blister * 0.35);
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
