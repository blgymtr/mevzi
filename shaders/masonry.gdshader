shader_type spatial;
// Duvar blokları (yıkılabilir): blok rengine göre sıva / tuğla / beton (CC0 dokular),
// dünya uzayında üçlü izdüşüm (bloklar arası kesintisiz), dipte kir ve nem izi.
render_mode blend_mix, depth_draw_opaque, cull_back, diffuse_burley;

uniform sampler2D plaster_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D plaster_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brick_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D brick_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D concrete_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D streak_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D chip_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform float scale = 0.45;
uniform vec4 grime_col : source_color = vec4(0.32, 0.27, 0.2, 1.0);
uniform float grime_h = 1.1;

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

vec2 proj(vec3 p, vec3 n) {
	vec3 a = abs(n);
	if (a.y > a.x && a.y > a.z) return p.xz;
	return a.x > a.z ? p.zy : p.xy;
}

float lum(vec3 c) { return dot(c, vec3(0.299, 0.587, 0.114)); }

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	float mx = max(c.r, max(c.g, c.b));
	float mn = min(c.r, min(c.g, c.b));
	float sat = (mx - mn) / max(mx, 0.001);
	float brick = smoothstep(0.08, 0.16, c.r - c.b) * smoothstep(0.25, 0.4, sat) * step(c.g, c.r);
	float conc = (1.0 - smoothstep(0.05, 0.12, sat)) * (1.0 - smoothstep(0.35, 0.6, mx)) * (1.0 - brick);
	vec3 n = normalize(wnrm);
	vec2 uv = proj(wpos * scale, n);
	vec3 col;
	vec3 nm;
	if (brick > 0.5) {
		col = texture(brick_alb, uv * 1.2).rgb * mix(vec3(1.0), c / max(lum(c), 0.05) * 0.6, 0.35);
		nm = texture(brick_nrm, uv * 1.2).rgb;
	} else if (conc > 0.5) {
		col = vec3(lum(texture(concrete_alb, uv * 0.8).rgb) / 0.13) * c;
		nm = texture(concrete_nrm, uv * 0.8).rgb;
	} else {
		col = vec3(lum(texture(plaster_alb, uv).rgb) / 0.4) * c;
		nm = texture(plaster_nrm, uv).rgb;
		// sıva dökülmesi: yer yer altındaki tuğla görünür (dipte ve rastgele lekelerde daha çok)
		float nz = texture(noise_tex, wpos.xz * 0.11 + wpos.y * vec2(0.07, 0.13)).r * 0.65 + texture(noise_tex, uv * 0.9).r * 0.35;
		float chip = smoothstep(0.76, 0.82, nz + clamp(1.0 - wpos.y / 1.4, 0.0, 1.0) * 0.12) * (1.0 - abs(n.y));
		vec3 bk = texture(chip_alb, uv * 1.1).rgb;
		col = mix(col, bk * 0.95, chip);
		// leke / nem halkası
		float stain = smoothstep(0.55, 0.8, texture(noise_tex, uv * 0.35 + 0.37).r);
		col *= mix(1.0, 0.82, stain * 0.6);
	}
	// yağmur izi ve dipte kir
	float sl = lum(texture(streak_tex, uv * vec2(0.7, 0.35)).rgb);
	col *= mix(1.0, clamp(0.7 + sl * 0.9, 0.7, 1.15), 0.35 * (1.0 - abs(n.y)));
	float g = clamp(1.0 - wpos.y / grime_h, 0.0, 1.0);
	col *= mix(vec3(1.0), vec3(0.78, 0.72, 0.62), g * g * 0.8);
	ALBEDO = col;
	// blok mesh'lerinde teğet yok: normal haritası yerine kabartıyı rengin içine kat
	col *= 0.82 + 0.36 * nm.g;
	ROUGHNESS = 0.92;
}
