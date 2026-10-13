shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Zemin: kum/kar, kumul ve dalgacık gölgeleri, yol / iz / yanık haritası.
uniform sampler2D map_tex : filter_linear, repeat_disable;
uniform sampler2D dune_n : filter_linear_mipmap, repeat_enable;
uniform sampler2D ripple_n : filter_linear_mipmap, repeat_enable;
uniform sampler2D grain : filter_linear_mipmap, repeat_enable;
uniform float map_size = 256.0;
uniform vec3 col_a : source_color = vec3(0.90, 0.68, 0.42);
uniform vec3 col_b : source_color = vec3(0.80, 0.56, 0.32);
uniform vec3 col_road : source_color = vec3(0.72, 0.52, 0.31);
uniform vec3 col_track : source_color = vec3(0.47, 0.32, 0.19);
uniform vec3 col_scorch : source_color = vec3(0.12, 0.10, 0.08);
uniform vec3 col_crest : source_color = vec3(0.97, 0.78, 0.52);
uniform float dune_strength = 1.1;
uniform float ripple_strength = 0.55;
uniform float rough = 0.93;

varying vec3 wpos;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec2 w = wpos.xz;
	vec2 muv = w / map_size;
	vec4 m = texture(map_tex, muv);
	float inside = step(0.0, muv.x) * step(0.0, muv.y) * step(muv.x, 1.0) * step(muv.y, 1.0);
	m *= inside;
	mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
	vec2 dw = rot * w;
	vec3 dn = texture(dune_n, dw * vec2(1.0 / 150.0, 1.0 / 55.0)).xyz * 2.0 - 1.0;
	vec3 dn2 = texture(dune_n, dw * vec2(1.0 / 47.0, 1.0 / 21.0) + vec2(0.37, 0.11)).xyz * 2.0 - 1.0;
	vec3 rn = texture(ripple_n, dw * vec2(1.0 / 2.6, 1.0 / 11.0)).xyz * 2.0 - 1.0;
	float g = texture(grain, w / 31.0).r;
	float g2 = texture(grain, w / 4.3).r;
	float g3 = texture(grain, w / 0.9).r;
	float flatten = clamp(m.r * 1.2 + m.g, 0.0, 1.0);
	vec2 nxy = (dn.xy * 1.0 + dn2.xy * 0.45) * dune_strength * (1.0 - flatten * 0.6) + rn.xy * ripple_strength * (1.0 - flatten);
	nxy = transpose(rot) * nxy;
	vec3 nw = normalize(vec3(nxy.x, 1.0, nxy.y));
	NORMAL = normalize((VIEW_MATRIX * vec4(nw, 0.0)).xyz);

	vec3 c = mix(col_b, col_a, smoothstep(0.25, 0.75, g));
	c *= 0.93 + 0.12 * g2 + 0.05 * (g3 - 0.5);
	// kumul tepeleri biraz açık
	float crest = clamp(dn.x * 0.8 + dn.y * 0.4, 0.0, 1.0);
	c = mix(c, col_crest, crest * 0.25 * (1.0 - flatten));
	// yol: sıkışmış, hafif koyu
	c = mix(c, col_road * (0.9 + 0.18 * g2), clamp(m.r, 0.0, 1.0) * 0.8);
	// izler
	c = mix(c, col_track * (0.85 + 0.3 * g3), clamp(m.g, 0.0, 1.0) * 0.75);
	// yanık / patlama izi
	float sc = clamp(m.b, 0.0, 1.0);
	c = mix(c, col_scorch * (0.8 + 0.4 * g3), sc * 0.88);
	ALBEDO = c;
	ROUGHNESS = rough;
	SPECULAR = 0.22;
}
