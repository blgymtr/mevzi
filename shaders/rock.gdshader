shader_type spatial;
// Kaya: dünya üç düzlemli doku + normal (whiteout karışımı, UV/teğet gerekmez),
// üst yüzeylerde kar (kış) ya da yosun; köşe rengi taban gölgesi/ton verir.
// Doku: tools/rock_tex.py

uniform sampler2D albedo_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D normal_tex : hint_normal, filter_linear_mipmap, repeat_enable;
uniform sampler2D rough_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float scale = 0.32;
uniform float normal_k = 1.3;
uniform float snow = 0.0;
uniform float moss = 0.0;
uniform vec3 moss_col : source_color = vec3(0.30, 0.37, 0.17);

varying vec3 wpos;
varying vec3 wnrm;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	wnrm = normalize((MODEL_MATRIX * vec4(NORMAL, 0.0)).xyz);
}

void fragment() {
	vec3 n0 = normalize(wnrm);
	vec3 bw = pow(abs(n0), vec3(4.0));
	bw /= (bw.x + bw.y + bw.z);
	vec2 ux = wpos.zy * scale;
	vec2 uy = wpos.xz * scale;
	vec2 uz = wpos.xy * scale;
	vec3 a = texture(albedo_tex, ux).rgb * bw.x + texture(albedo_tex, uy).rgb * bw.y + texture(albedo_tex, uz).rgb * bw.z;
	float rg = texture(rough_tex, ux).r * bw.x + texture(rough_tex, uy).r * bw.y + texture(rough_tex, uz).r * bw.z;
	vec3 tx = texture(normal_tex, ux).xyz * 2.0 - 1.0;
	vec3 ty = texture(normal_tex, uy).xyz * 2.0 - 1.0;
	vec3 tz = texture(normal_tex, uz).xyz * 2.0 - 1.0;
	tx.xy *= normal_k;
	ty.xy *= normal_k;
	tz.xy *= normal_k;
	vec3 nx = vec3(tx.xy + n0.zy, abs(tx.z) * n0.x);
	vec3 ny = vec3(ty.xy + n0.xz, abs(ty.z) * n0.y);
	vec3 nz = vec3(tz.xy + n0.xy, abs(tz.z) * n0.z);
	vec3 wn = normalize(nx.zyx * bw.x + ny.xzy * bw.y + nz.xyz * bw.z);
	float lum = dot(a, vec3(0.333));
	float up = wn.y;
	float mo = smoothstep(0.5, 0.85, up + (lum - 0.42) * 0.9) * moss;
	a = mix(a, moss_col * (0.75 + lum * 0.8), mo * 0.75);
	float sn = smoothstep(0.3, 0.6, up + (lum - 0.42) * 0.7) * snow;
	a = mix(a * COLOR.rgb, vec3(0.9, 0.92, 0.96), sn);
	wn = normalize(mix(wn, n0, sn * 0.7));
	ALBEDO = a;
	ROUGHNESS = mix(clamp(rg, 0.0, 1.0), 0.55, sn);
	NORMAL = normalize((VIEW_MATRIX * vec4(wn, 0.0)).xyz);
}
