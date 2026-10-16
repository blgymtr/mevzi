shader_type spatial;
// Ağaç / çalı: gerçek kabuk dokusu (renk + normal) ve alfa kesimli yaprak kartları.
// Rüzgâr salınımı + patlama şok dalgası (instance uniform): ağaç önce patlamadan
// uzağa yatar, sonra sönümlenerek ileri geri sallanır; yapraklar titrer.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform bool has_normal = false;
uniform bool leaf = false;
uniform vec4 tint : source_color = vec4(1.0);
uniform vec2 uv_scale = vec2(1.0, 1.0);
uniform float tree_h = 6.0;
uniform float crown_y = 0.65;      // taç merkezi (boyun oranı) — yaprak normalleri buradan dışa
uniform float snow = 0.0;          // kış: yukarı bakan yüzeylerde kar
uniform float sway_amp = 1.0;

global uniform float game_time;
global uniform vec4 blast0;     // (x, z, başlangıç, güç) — son 4 büyük patlama
global uniform vec4 blast1;
global uniform vec4 blast2;
global uniform vec4 blast3;
global uniform vec4 rotor0;     // (x, z, güç, yarıçap) — alçaktaki helikopter rotor rüzgârı
global uniform vec4 rotor1;
global uniform vec4 rotor2;
global uniform vec4 rotor3;

varying float v_h;
varying float v_fade;
varying vec3 v_crown_n;

void vertex() {
	float h = clamp(VERTEX.y / tree_h, 0.0, 1.0);
	v_h = h;
	v_fade = INSTANCE_CUSTOM.r;
	float w = h * h;
	float t = game_time;
	float phase = fract(sin(dot(MODEL_MATRIX[3].xz, vec2(12.9898, 78.233))) * 43758.5453) * 6.2831;
	vec3 off = vec3(0.0);
	// rüzgâr: yavaş gövde salınımı + hızlı dal/yaprak titreşimi
	float s1 = sin(t * 1.1 + phase) * 0.6 + sin(t * 2.3 + phase * 1.7) * 0.4;
	off.x += s1 * 0.035 * w * tree_h * sway_amp;
	off.z += cos(t * 0.9 + phase * 1.3) * 0.022 * w * tree_h * sway_amp;
	if (leaf) {
		float j = VERTEX.x * 2.1 + VERTEX.z * 1.7 + VERTEX.y * 1.3;
		off += vec3(sin(t * 5.3 + j), sin(t * 4.1 + j * 1.3) * 0.6, cos(t * 4.7 + j)) * 0.03 * (0.3 + h) * sway_amp;
	}
	// patlama şok dalgası: patlamadan uzağa yatar, sonra sönümlenerek sallanır (ses hızıyla gecikmeli)
	vec3 org = MODEL_MATRIX[3].xyz;
	mat3 inv = inverse(mat3(MODEL_MATRIX));
	vec4 bl[4] = vec4[4](blast0, blast1, blast2, blast3);
	for (int i = 0; i < 4; i++) {
		vec4 b = bl[i];
		vec2 dv = org.xz - b.xy;
		float d = length(dv);
		float reach = 6.0 + b.w * 9.0;
		float age = t - b.z - d / 340.0;
		if (b.w <= 0.0 || d > reach || age < 0.0 || age > 7.0) continue;
		float kk = 1.0 - d / reach;
		kk = kk * kk * clamp(b.w, 0.3, 3.0) * 0.55;
		vec3 ld = inv * vec3(dv.x, 0.0, dv.y) / max(d, 0.05);
		ld.y = 0.0;
		float osc = exp(-age * 1.25) * cos(age * 5.2) * smoothstep(0.0, 0.06, age);
		off += normalize(ld + vec3(1e-4)) * kk * osc * w * tree_h * 0.22;
		if (leaf) {
			float j2 = VERTEX.x * 5.0 + VERTEX.y * 3.0;
			off += vec3(sin(age * 31.0 + j2), cos(age * 27.0 + j2) * 0.5, cos(age * 29.0 + j2)) * 0.12 * exp(-age * 2.5) * kk;
		}
	}
	// rotor rüzgârı: göbekten dışa yatar, türbülansla hızlı titrer
	vec4 rw[4] = vec4[4](rotor0, rotor1, rotor2, rotor3);
	for (int i = 0; i < 4; i++) {
		vec4 r = rw[i];
		if (r.z <= 0.0) continue;
		vec2 dv = org.xz - r.xy;
		float d = length(dv);
		if (d > r.w) continue;
		float kk = (1.0 - d / r.w) * r.z;
		vec3 ld = inv * vec3(dv.x, 0.0, dv.y) / max(d, 0.3);
		ld.y = 0.0;
		float gust = 0.75 + 0.25 * sin(t * 7.0 + d * 0.9 + phase);
		off += normalize(ld + vec3(1e-4)) * kk * gust * w * tree_h * 0.12;
		if (leaf) {
			float j3 = VERTEX.x * 4.0 + VERTEX.z * 3.0 + VERTEX.y * 2.0;
			off += vec3(sin(t * 23.0 + j3), cos(t * 19.0 + j3) * 0.5, cos(t * 21.0 + j3)) * 0.07 * kk;
		}
	}
	VERTEX += off;
	if (leaf) {
		// küre normali: taç dışa doğru aydınlanır (kartlar tek tek parlamaz)
		vec3 cn = normalize(VERTEX - vec3(0.0, tree_h * crown_y, 0.0) + vec3(0.0, 0.3, 0.0));
		NORMAL = normalize(mix(NORMAL, cn, 0.85));
	}
}

void fragment() {
	// seçili birliği örten ağaç: titreşimli (dither) kesimle yarı saydam
	if (v_fade > 0.0) {
		float d = fract(sin(dot(floor(FRAGCOORD.xy), vec2(12.9898, 78.233))) * 43758.5453);
		if (d < v_fade) discard;
	}
	vec4 c = texture(albedo_tex, UV * uv_scale);
	vec3 col = c.rgb * tint.rgb;
	if (leaf) {
		ALPHA = c.a;
		ALPHA_SCISSOR_THRESHOLD = 0.45;
		// taç içi gölgesi: alçak ve içteki kartlar koyu
		col *= mix(0.55, 1.08, smoothstep(0.15, 0.95, v_h));
		BACKLIGHT = col * 0.35;
		ROUGHNESS = 0.78;
		SPECULAR = 0.25;
	} else {
		ROUGHNESS = 0.92;
		SPECULAR = 0.2;
		if (has_normal) {
			NORMAL_MAP = texture(normal_tex, UV * uv_scale).rgb;
			NORMAL_MAP_DEPTH = 1.3;
		}
		// dibe doğru toprak/yosun
		col *= mix(0.72, 1.0, smoothstep(0.0, 0.12, v_h));
	}
	if (snow > 0.0) {
		vec3 wn = (INV_VIEW_MATRIX * vec4(NORMAL, 0.0)).xyz;
		float s = smoothstep(0.35, 0.8, wn.y) * snow;
		col = mix(col, vec3(0.92, 0.94, 0.97), s);
	}
	ALBEDO = col;
}
