shader_type spatial;
// Ot kartları: hafif rüzgâr salınımı + alçaktaki helikopterin rotor rüzgârı (roadmap 22): göbekten dışa
// yatar, ezilir ve hızlı titrer. Görünüm StandardMaterial ile aynı (doku × köşe/örnek rengi, alfa kesimi).
render_mode cull_disabled, diffuse_burley, specular_schlick_ggx;

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_disable;
global uniform float game_time;
global uniform vec4 rotor0;
global uniform vec4 rotor1;
global uniform vec4 rotor2;
global uniform vec4 rotor3;

void vertex() {
	float h = clamp(1.0 - UV.y, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	float t = game_time;
	vec3 off = vec3(0.0);
	off.x += (sin(t * 1.7 + wp.x * 0.35 + wp.z * 0.21) * 0.6 + sin(t * 3.1 + wp.z * 0.5) * 0.4) * 0.05 * h;
	off.z += cos(t * 1.3 + wp.z * 0.3 + wp.x * 0.17) * 0.035 * h;
	vec4 rw[4] = vec4[4](rotor0, rotor1, rotor2, rotor3);
	for (int i = 0; i < 4; i++) {
		vec4 r = rw[i];
		if (r.z <= 0.0) continue;
		vec2 dv = wp.xz - r.xy;
		float d = length(dv);
		if (d > r.w) continue;
		float kk = (1.0 - d / r.w) * r.z;
		vec2 dir = dv / max(d, 0.3);
		float gust = 0.7 + 0.3 * sin(t * 15.0 + d * 1.3 + wp.x);
		off.xz += dir * kk * h * 0.42 * gust;
		off.y -= kk * h * 0.28;
	}
	VERTEX += inverse(mat3(MODEL_MATRIX)) * off;
}

void fragment() {
	vec4 c = texture(albedo_tex, UV);
	ALBEDO = c.rgb * COLOR.rgb;
	ALPHA = c.a;
	ALPHA_SCISSOR_THRESHOLD = 0.45;
	ROUGHNESS = 0.95;
	SPECULAR = 0.3;
}
