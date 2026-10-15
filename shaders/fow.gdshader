shader_type spatial;
// Görsel savaş sisi (CoH / Sudden Strike / Broken Arrow): keşfedilmemiş alan koyu, görülmüş ama
// şu an görüş dışında kalan alan soluk, birliklerin görüşü içi tam renk. Tam ekran dörtgen;
// derinlikten dünya konumu kurulur, görüş/keşif dokuları (SubViewport) haritaya göre okunur.
render_mode unshaded, blend_mix, depth_test_disabled, depth_draw_never, cull_disabled, shadows_disabled, fog_disabled;

uniform sampler2D depth_tex : hint_depth_texture, filter_nearest;
uniform sampler2D vis_tex : filter_linear, repeat_disable;
uniform sampler2D exp_tex : filter_linear, repeat_disable;
uniform float map_size = 256.0;
uniform float unexplored = 0.78;
uniform float remembered = 0.42;
uniform vec4 fog_col : source_color = vec4(0.03, 0.035, 0.045, 1.0);

void vertex() {
	POSITION = vec4(VERTEX.xy, 1.0, 1.0);
}

void fragment() {
	float depth = textureLod(depth_tex, SCREEN_UV, 0.0).r;
#if CURRENT_RENDERER == RENDERER_COMPATIBILITY
	vec3 ndc = vec3(SCREEN_UV, depth) * 2.0 - 1.0;
#else
	vec3 ndc = vec3(SCREEN_UV * 2.0 - 1.0, depth);
#endif
	vec4 vp = INV_PROJECTION_MATRIX * vec4(ndc, 1.0);
	vp.xyz /= vp.w;
	vec3 wp = (INV_VIEW_MATRIX * vec4(vp.xyz, 1.0)).xyz;
	vec2 uv = wp.xz / map_size;
	float vis = 0.0;
	float ex = 0.0;
	if (uv.x >= 0.0 && uv.y >= 0.0 && uv.x <= 1.0 && uv.y <= 1.0) {
		vis = texture(vis_tex, uv).r;
		ex = texture(exp_tex, uv).r;
	}
	float dark = mix(unexplored, remembered, smoothstep(0.05, 0.6, ex));
	ALBEDO = fog_col.rgb;
	ALPHA = dark * (1.0 - smoothstep(0.15, 0.85, vis));
}
