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
// malzeme kodu blok renginin alfasında (1 = otomatik; Arch.FAC_A): taş, ahşap, sac, panel, kerpiç, tuğla, sıva, çelik, kütük
uniform sampler2D wood_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D metal_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D panel_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D rough_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D steel_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform float scale = 0.45;
uniform vec4 grime_col : source_color = vec4(0.32, 0.27, 0.2, 1.0);
uniform float grime_h = 1.1;
uniform float grime_y0 = 0.0;       // kir/nem bandının tabanı (köprüde su çizgisi)

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
	vec3 nm = vec3(0.5, 0.6, 1.0);
	int mid = int(round((1.0 - COLOR.a) * 10.0));
	if (mid == 6) { brick = 1.0; conc = 0.0; }
	if (mid == 7) { brick = 0.0; conc = 0.0; }
	if (mid == 10) { brick = 0.0; conc = 1.0; }
	if (mid == 1) {
		// moloz / kesme taş: taş dokusu, blok renginde
		vec3 st = texture(chip_alb, uv * 0.75).rgb;
		col = vec3(lum(st) / 0.36) * c * mix(vec3(1.0), st / max(lum(st), 0.05), 0.25);
		nm = texture(brick_nrm, uv * 0.6).rgb;
	} else if (mid == 2 || mid == 9) {
		// ahşap kaplama (yatay tahta) / kütük (kalın)
		vec2 wu = mid == 9 ? uv * vec2(0.5, 0.33) : uv * vec2(0.7, 0.62);
		col = vec3(lum(texture(wood_alb, wu).rgb) / 0.55) * c;
		col *= 0.9 + 0.2 * texture(noise_tex, wpos.xz * 0.6 + wpos.y * 0.3).r;
	} else if (mid == 3) {
		// oluklu sac (dikey oluk)
		col = vec3(lum(texture(metal_alb, uv * vec2(0.55, 0.4)).rgb) / 0.3) * c;
		col *= mix(1.0, 0.75, smoothstep(0.6, 0.85, texture(noise_tex, uv * 0.4 + 0.2).r));
	} else if (mid == 4) {
		// prefabrik beton panel
		col = vec3(lum(texture(panel_alb, uv * 0.35).rgb) / 0.5) * c;
	} else if (mid == 5) {
		// kerpiç / kaba sıva
		vec3 rt = texture(rough_alb, uv * 0.8).rgb;
		col = vec3(lum(rt) / 0.42) * c;
		col *= mix(0.88, 1.08, texture(noise_tex, uv * 0.5).r);
	} else if (mid == 8) {
		// çelik sac (tank, silo)
		col = c * mix(1.0, lum(texture(steel_alb, uv * 0.5).rgb) / 0.3, 0.22);
	} else if (brick > 0.5) {
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
	float g = clamp(1.0 - (wpos.y - grime_y0) / grime_h, 0.0, 1.0);
	col *= mix(vec3(1.0), vec3(0.78, 0.72, 0.62), g * g * 0.8);
	ALBEDO = col;
	// blok mesh'lerinde teğet yok: normal haritası yerine kabartıyı rengin içine kat
	col *= 0.82 + 0.36 * nm.g;
	ROUGHNESS = 0.92;
}
