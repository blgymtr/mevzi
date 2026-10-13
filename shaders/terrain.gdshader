shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Fotoğraf dokulu arazi: taban + yama + yol + yanık + kıyı çamuru; yükseklik haritası ile oyulmuş nehir yatakları.
uniform sampler2D map_tex : filter_linear, repeat_disable;      // r yol, g iz, b yanık, a yama
uniform sampler2D height_tex : filter_linear, repeat_disable;   // r yükseklik (m)
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_a : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_road : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_road : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_bank : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_burn : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro : filter_linear_mipmap, repeat_enable;  // büyük ölçek gürültü (renk varyasyonu)
uniform sampler2D dune_n : filter_linear_mipmap, repeat_enable; // kumul normal gürültüsü
uniform float map_size = 256.0;
uniform vec3 tint_a : source_color = vec3(1.0);
uniform vec3 tint_a2 : source_color = vec3(1.0);
uniform vec3 tint_b : source_color = vec3(1.0);
uniform vec3 tint_road : source_color = vec3(1.0);
uniform vec3 tint_bank : source_color = vec3(1.0);
uniform vec3 tint_track : source_color = vec3(0.5, 0.4, 0.3);
uniform float scale_a = 14.0;
uniform float scale_b = 10.0;
uniform float scale_road = 6.0;
uniform float patch_noise = 0.5;
uniform float dune_strength = 0.0;
uniform float normal_strength = 1.0;
uniform float macro_strength = 0.18;
uniform float rough = 0.92;
uniform float road_amt = 1.0;

varying vec3 wpos;
varying float vh;

float hgt(vec2 w) {
	return texture(height_tex, w / map_size).r;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 muv = wp.xz / map_size;
	float inside = step(0.0, muv.x) * step(0.0, muv.y) * step(muv.x, 1.0) * step(muv.y, 1.0);
	float h = hgt(wp.xz) * inside;
	VERTEX.y += h;
	vh = h;
	float e = 0.6;
	float hx = (hgt(wp.xz + vec2(e, 0.0)) - hgt(wp.xz - vec2(e, 0.0))) * inside;
	float hz = (hgt(wp.xz + vec2(0.0, e)) - hgt(wp.xz - vec2(0.0, e))) * inside;
	NORMAL = normalize(vec3(-hx / (2.0 * e), 1.0, -hz / (2.0 * e)));
	wpos = wp + vec3(0.0, h, 0.0);
}

vec3 unpack_n(vec4 t) {
	return vec3(t.xy * 2.0 - 1.0, 0.0);
}

void fragment() {
	vec2 w = wpos.xz;
	vec2 muv = w / map_size;
	float inside = step(0.0, muv.x) * step(0.0, muv.y) * step(muv.x, 1.0) * step(muv.y, 1.0);
	vec4 m = texture(map_tex, muv) * inside;
	float mac = texture(macro, w / 97.0).r;
	float mac2 = texture(macro, w / 23.0 + vec2(0.31, 0.77)).r;
	// taban: iki ölçek karışımı (tekrarı kırar)
	vec2 ua = w / scale_a;
	vec2 ua2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * w / (scale_a * 2.7) + vec2(0.37, 0.11);
	vec3 a1 = texture(tex_a, ua).rgb;
	vec3 a2 = texture(tex_a, ua2).rgb;
	float k = smoothstep(0.35, 0.65, mac2);
	vec3 base = mix(a1, a2, k * 0.6) * mix(tint_a, tint_a2, smoothstep(0.3, 0.7, mac));
	vec3 nb = mix(unpack_n(texture(nrm_a, ua)), unpack_n(texture(nrm_a, ua2)), k * 0.6);
	// yama (çim/toprak, kar/çamur…)
	float pm = clamp(m.a + (mac - 0.5) * patch_noise, 0.0, 1.0);
	pm = smoothstep(0.35, 0.65, pm);
	vec2 ub = w / scale_b;
	vec3 bcol = texture(tex_b, ub).rgb * tint_b;
	base = mix(base, bcol, pm);
	nb = mix(nb, unpack_n(texture(nrm_b, ub)), pm);
	// kıyı çamuru (yükseklik < 0)
	float bank = smoothstep(-0.05, -0.7, vh);
	base = mix(base, texture(tex_bank, w / 5.0).rgb * tint_bank, bank);
	// yol
	vec2 ur = w / scale_road;
	float road = smoothstep(0.15, 0.7, m.r) * road_amt * (0.75 + 0.5 * texture(macro, w / 6.0).r);
	base = mix(base, texture(tex_road, ur).rgb * tint_road, road);
	nb = mix(nb, unpack_n(texture(nrm_road, ur)), road);
	// tekerlek / palet izi
	float tr = clamp(m.g, 0.0, 1.0);
	base = mix(base, base * tint_track, tr * 0.85);
	// yanık
	float sc = clamp(m.b, 0.0, 1.0);
	base = mix(base, texture(tex_burn, w / 4.0).rgb * 0.45, sc * 0.9);
	// büyük ölçek ton
	base *= 1.0 + (mac - 0.5) * macro_strength * 2.0;
	// kumullar
	if (dune_strength > 0.0) {
		mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
		vec2 dw = rot * w;
		vec3 dn = texture(dune_n, dw * vec2(1.0 / 140.0, 1.0 / 50.0)).xyz * 2.0 - 1.0;
		nb.xy += dn.xy * dune_strength * (1.0 - road);
		base *= 1.0 + dn.x * 0.06 * dune_strength;
	}
	ALBEDO = base;
	NORMAL_MAP = normalize(vec3(nb.xy * normal_strength, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = mix(rough, 0.35, bank * 0.6);
	SPECULAR = 0.25;
}
