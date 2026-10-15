shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Kanal / nehir suyu: nehir boyunca akan dalga ve köpük (iki evreli akış haritası), derinliğe göre renk,
// kıyıda köpük. Şerit örgünün köşe rengi: rg akış yönü, b şerit kesiti (orta hızlı, kıyı yavaş).
global uniform float game_time;
uniform sampler2D depth_tex : hint_depth_texture, filter_linear;
uniform sampler2D screen_tex : hint_screen_texture, filter_linear_mipmap;
uniform sampler2D wave_n : filter_linear_mipmap, repeat_enable;
uniform sampler2D foam_tex : filter_linear_mipmap, repeat_enable;
uniform vec3 shallow : source_color = vec3(0.25, 0.75, 0.78);
uniform vec3 deep : source_color = vec3(0.05, 0.35, 0.45);
uniform float depth_scale = 1.4;
uniform float foam_amt = 1.0;
uniform float flow_speed = 0.55;   // m/sn (oyun ölçeği)
uniform float clarity = 0.35;
uniform sampler2D river_mask : filter_linear, repeat_disable;
uniform float map_size = 256.0;

varying vec3 wpos;
varying vec2 v_flow;
varying float v_across;
// görsel savaş sisi (FogOfWar global dokuları): su şeffaf geçişte sisin üstüne çizildiği için kendisi kararır
global uniform sampler2D fow_vis;
global uniform sampler2D fow_exp;
global uniform float fow_on;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_flow = COLOR.rg * 2.0 - 1.0;
	v_across = COLOR.b * 2.0 - 1.0;
}

void fragment() {
	// yalnızca nehir/göl yatağında (siper, krater gibi sonradan kazılan çukurlarda su görünmez)
	if (texture(river_mask, wpos.xz / map_size).r < 0.5) {
		discard;
	}
	float t = game_time;
	vec2 w = wpos.xz;
	// akış: nehrin yönünde, ortada hızlı kıyıda yavaş; iki evre karıştırılarak doku gerilmesi gizlenir
	vec2 fd = length(v_flow) > 0.01 ? normalize(v_flow) : vec2(1.0, 0.0);
	float spd = flow_speed * (1.0 - 0.7 * v_across * v_across);
	float ph0 = fract(t * 0.18);
	float ph1 = fract(t * 0.18 + 0.5);
	float bw = abs(ph0 - 0.5) * 2.0;
	vec2 off0 = fd * spd * ph0 * 5.5;
	vec2 off1 = fd * spd * ph1 * 5.5;
	vec3 a1 = texture(wave_n, (w - off0) / 6.5).xyz * 2.0 - 1.0;
	vec3 b1 = texture(wave_n, (w - off1) / 6.5 + vec2(0.37, 0.61)).xyz * 2.0 - 1.0;
	vec3 n1 = mix(a1, b1, bw);
	vec3 a2 = texture(wave_n, (w - off0 * 1.6) / 2.4 + vec2(0.11, 0.53)).xyz * 2.0 - 1.0;
	vec3 b2 = texture(wave_n, (w - off1 * 1.6) / 2.4 + vec2(0.71, 0.29)).xyz * 2.0 - 1.0;
	vec3 n2 = mix(a2, b2, bw);
	// küçük, yönsüz rüzgâr kırışıkları
	vec3 n3 = texture(wave_n, w / 1.3 + vec2(t * 0.03, -t * 0.02)).xyz * 2.0 - 1.0;
	vec2 nxy = n1.xy * 0.55 + n2.xy * 0.35 + n3.xy * 0.15;
	NORMAL_MAP = normalize(vec3(nxy, 1.0)) * 0.5 + 0.5;
	// sahne derinliği → su kalınlığı
	float d = texture(depth_tex, SCREEN_UV).r;
	vec4 vp = INV_PROJECTION_MATRIX * vec4(SCREEN_UV * 2.0 - 1.0, d, 1.0);
	vp.xyz /= vp.w;
	float thick = clamp((VERTEX.z - vp.z), 0.0, 10.0);
	float k = clamp(thick / depth_scale, 0.0, 1.0);
	vec3 refr = texture(screen_tex, SCREEN_UV + nxy * 0.01).rgb;
	vec3 col = mix(shallow, deep, k);
	col = mix(refr * shallow * 1.2, col, clamp(k + (1.0 - clarity), 0.0, 1.0));
	// köpük: kıyıda ve dalga tepelerinde
	float f = mix(texture(foam_tex, (w - off0 * 1.2) / 3.0).r, texture(foam_tex, (w - off1 * 1.2) / 3.0 + vec2(0.5, 0.25)).r, bw);
	float shore = 1.0 - smoothstep(0.0, 0.35, thick);
	float crest = smoothstep(0.62, 0.9, f * (0.6 + 0.6 * n1.x + 0.3 * n2.y));
	float foam = clamp(shore * (0.5 + f) + crest * 0.35, 0.0, 1.0) * foam_amt;
	col = mix(col, vec3(0.95, 0.97, 0.98), foam);
	ALBEDO = col;
	ROUGHNESS = 0.08;
	SPECULAR = 0.6;
	METALLIC = 0.0;
	ALPHA = clamp(0.75 + k * 0.25 + foam, 0.0, 1.0);
	if (fow_on > 0.5) {
		vec2 fuv = wpos.xz / map_size;
		float fv = texture(fow_vis, fuv).r;
		float fe = texture(fow_exp, fuv).r;
		float dark = mix(0.78, 0.42, smoothstep(0.05, 0.6, fe)) * (1.0 - smoothstep(0.15, 0.85, fv));
		ALBEDO = mix(ALBEDO, vec3(0.03, 0.035, 0.045), dark);
		SPECULAR *= 1.0 - dark;
	}
}
