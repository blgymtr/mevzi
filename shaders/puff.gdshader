shader_type spatial;
// GPU'da hesaplanan parçacık: MultiMesh örnek verisi = doğuş parametreleri.
// origin=konum, basis.x=hız, basis.y=(t0, ömür, yerçekimi), basis.z=(boy0, boy1, sürtünme)
// COLOR=renk, INSTANCE_CUSTOM=(dönüş0, dönüş hızı, atlas varyantı, tohum)
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform, fog_disabled;

global uniform float game_time;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform int mode = 0;          // 0 duman/toz, 1 ateş, 2 kıvılcım, 3 moloz
uniform float intensity = 1.0;
uniform float ground_stop = 0.0;

varying vec4 v_col;
varying float v_age;
varying vec2 v_uv;

void vertex() {
	vec3 o = MODEL_MATRIX[3].xyz;
	vec3 vel = MODEL_MATRIX[0].xyz;
	float t0 = MODEL_MATRIX[1].x;
	float life = MODEL_MATRIX[1].y;
	float grav = MODEL_MATRIX[1].z;
	float s0 = MODEL_MATRIX[2].x;
	float s1 = MODEL_MATRIX[2].y;
	float drag = MODEL_MATRIX[2].z;
	float t = game_time - t0;
	float a = t / max(life, 0.001);
	v_col = COLOR;
	v_age = a;
	if (t < 0.0 || a >= 1.0) {
		POSITION = vec4(2.0, 2.0, 2.0, 1.0);
	} else {
		float k = max(drag, 0.0001);
		float f = (1.0 - exp(-k * t)) / k;
		vec3 p = o + vel * f;
		p.y -= 0.5 * grav * t * t;
		if (ground_stop > 0.5) {
			p.y = max(p.y, 0.04);
		}
		float sz = mix(s0, s1, 1.0 - (1.0 - a) * (1.0 - a));
		float rot = INSTANCE_CUSTOM.x + INSTANCE_CUSTOM.y * t;
		vec2 q = VERTEX.xy;
		vec3 right = (INV_VIEW_MATRIX[0]).xyz;
		vec3 up = (INV_VIEW_MATRIX[1]).xyz;
		vec3 wp;
		if (mode == 2 || mode == 4) {
			// hıza göre uzat
			vec3 cv = vel * exp(-k * t) - vec3(0.0, grav * t, 0.0);
			vec3 vd = cv - dot(cv, INV_VIEW_MATRIX[2].xyz) * INV_VIEW_MATRIX[2].xyz;
			float sp = length(vd);
			vec3 ax = sp > 0.001 ? vd / sp : right;
			vec3 nx = normalize(cross(ax, INV_VIEW_MATRIX[2].xyz));
			float len = sz * (1.0 + sp * 0.06);
			wp = p + ax * q.y * len * 2.5 + nx * q.x * sz * 0.5;
		} else {
			float c = cos(rot);
			float s = sin(rot);
			q = vec2(q.x * c - q.y * s, q.x * s + q.y * c) * sz;
			wp = p + right * q.x + up * q.y;
		}
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(wp, 1.0));
	}
	float var_i = INSTANCE_CUSTOM.z;
	vec2 cell = vec2(mod(var_i, 2.0), floor(mod(var_i, 4.0) / 2.0));
	v_uv = (UV + cell) * 0.5;
}

void fragment() {
	vec4 tx = texture(tex, v_uv);
	float a = v_age;
	if (mode == 0) {
		// duman: önceden ışıklandırılmış puf; başta hızlı belir, sona doğru sön
		float fade = smoothstep(0.0, 0.08, a) * (1.0 - smoothstep(0.55, 1.0, a));
		ALBEDO = v_col.rgb * (0.45 + 0.75 * tx.r);
		ALPHA = tx.a * v_col.a * fade * 0.72;
	} else if (mode == 1) {
		float heat = 1.0 - a;
		vec3 hot = vec3(1.0, 0.92, 0.7);
		vec3 mid = vec3(1.0, 0.5, 0.12);
		vec3 cold = vec3(0.45, 0.08, 0.02);
		vec3 c = mix(cold, mid, smoothstep(0.0, 0.6, heat * tx.r * 1.3));
		c = mix(c, hot, smoothstep(0.55, 1.0, heat * tx.r * 1.2));
		c = mix(c, vec3(0.08, 0.06, 0.05), smoothstep(0.55, 1.0, a));
		ALBEDO = c * intensity * v_col.rgb * (0.75 + heat * 0.6);
		ALPHA = clamp(tx.a * 1.4, 0.0, 1.0) * v_col.a * (1.0 - smoothstep(0.5, 1.0, a));
	} else if (mode == 2) {
		ALBEDO = v_col.rgb * intensity;
		ALPHA = tx.a * (1.0 - a);
	} else if (mode == 4) {
		// toprak/şarapnel çizgisi: opak, sona doğru incelip söner
		ALBEDO = v_col.rgb * (0.6 + 0.4 * tx.r);
		ALPHA = tx.a * v_col.a * (1.0 - smoothstep(0.6, 1.0, a));
	} else {
		if (tx.a < 0.5) {
			discard;
		}
		ALBEDO = v_col.rgb * (0.55 + 0.45 * tx.r);
		ALPHA = v_col.a * (1.0 - smoothstep(0.85, 1.0, a));
	}
}
