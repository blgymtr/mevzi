shader_type spatial;
// İz mermisi: origin=A, basis.x=B-A, basis.y=(t0, ömür, kalınlık), basis.z=(kuyruk boyu, -, -)
render_mode blend_add, unshaded, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform, fog_disabled;

global uniform float game_time;
uniform float intensity = 5.0;

varying vec4 v_col;
varying float v_u;
varying float v_v;

void vertex() {
	vec3 A = MODEL_MATRIX[3].xyz;
	vec3 D = MODEL_MATRIX[0].xyz;
	float t0 = MODEL_MATRIX[1].x;
	float life = MODEL_MATRIX[1].y;
	float wid = MODEL_MATRIX[1].z;
	float tail = MODEL_MATRIX[2].x;
	float t = game_time - t0;
	float a = t / max(life, 0.001);
	v_col = COLOR;
	v_u = UV.x;
	v_v = UV.y;
	float L = length(D);
	if (t < 0.0 || a > 1.0 || L < 0.01) {
		POSITION = vec4(2.0, 2.0, 2.0, 1.0);
	} else {
		vec3 dir = D / L;
		float head = a * L;
		float tl = min(tail, head);
		float along = head - tl + UV.x * tl;
		vec3 p = A + dir * along;
		vec3 vd = INV_VIEW_MATRIX[2].xyz;
		vec3 side = normalize(cross(dir, vd));
		p += side * (UV.y - 0.5) * wid;
		POSITION = PROJECTION_MATRIX * (VIEW_MATRIX * vec4(p, 1.0));
	}
}

void fragment() {
	float edge = 1.0 - abs(v_v - 0.5) * 2.0;
	float k = smoothstep(0.0, 1.0, v_u);
	ALBEDO = v_col.rgb * intensity * (0.3 + k);
	ALPHA = edge * k * v_col.a;
}
