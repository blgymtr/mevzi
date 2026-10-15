shader_type spatial;
// Çatı: kiremit / sac dokusu eğim yönüne hizalı; köşeli renk lekesi yok,
// kar yumuşak gürültüyle (dünya uzayı) birikir.
render_mode blend_mix, depth_draw_opaque, cull_disabled, diffuse_burley;

uniform sampler2D tile_alb : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tile_nrm : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D noise_tex : source_color, filter_linear_mipmap, repeat_enable;
uniform float scale = 0.85;
uniform float snow = 0.0;

varying vec3 mpos;
varying vec3 mnrm;
varying vec3 wpos;

void vertex() {
	mpos = VERTEX;
	mnrm = NORMAL;
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
}

void fragment() {
	vec3 c = pow(max(COLOR.rgb, vec3(0.0)), vec3(2.2));
	vec3 n = normalize(mnrm);
	vec2 sd = length(n.xz) > 0.01 ? normalize(n.xz) : vec2(0.0, 1.0);
	vec2 sp = vec2(-sd.y, sd.x);
	// eğim boyunca v, mahyaya paralel u
	vec2 uv = vec2(dot(mpos.xz, sp), dot(mpos.xz, sd) * 1.25 - mpos.y * 0.6) * scale;
	vec3 t = texture(tile_alb, uv).rgb;
	// kil kiremit kendi rengini korur; blok rengiyle hafif tonlanır, rastgele soluk/koyu kiremit lekeleri
	float pn = texture(noise_tex, wpos.xz * 0.15).r;
	vec3 col = t * mix(vec3(1.0), c / max(dot(c, vec3(0.333)), 0.05) * 0.55, 0.45) * 1.6;
	col *= mix(0.78, 1.15, pn);
	float nz = texture(noise_tex, wpos.xz * 0.07).r * 0.6 + texture(noise_tex, wpos.xz * 0.21).r * 0.4;
	// kar: üstte kalın, saçağa doğru incelir; yumuşak kenarlı
	float edge = clamp(dot(mpos.xz, -sd) * 0.4 + 0.75, 0.0, 1.0);
	float s = smoothstep(0.3, 0.75, nz * 0.7 + edge * 0.55) * snow * smoothstep(0.2, 0.6, n.y);
	col = mix(col, vec3(0.9, 0.92, 0.95), s);
	ALBEDO = col;
	ALBEDO *= mix(0.8 + 0.4 * texture(tile_nrm, uv).g, 1.0, s);
	ROUGHNESS = mix(0.8, 0.6, s);
}
