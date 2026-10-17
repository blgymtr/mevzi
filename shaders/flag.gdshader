shader_type spatial;
// Dalgalanan bayrak (roadmap 33): direk kenarı sabit (UV.x = 0), serbest uca doğru genliği artan, rüzgâr yönünde
// ilerleyen iki dalga; her bayrağın evresi dünya konumundan (yan yana bayraklar aynı anda dalgalanmaz).
// Bayrak modelde XY düzleminde (Godot), dalga Z ekseninde.
render_mode cull_disabled, diffuse_burley;

uniform vec4 col : source_color = vec4(0.8, 0.1, 0.1, 1.0);
uniform float amp = 0.11;
uniform float speed = 3.2;

varying float shade;

void vertex() {
	float u = clamp(UV.x, 0.0, 1.0);
	vec3 wp = (MODEL_MATRIX * vec4(0.0, 0.0, 0.0, 1.0)).xyz;
	float ph = wp.x * 0.37 + wp.z * 0.29;
	float t = TIME * speed;
	float a1 = u * 6.0 - t + ph;
	float a2 = u * 11.0 - t * 1.7 + ph * 1.3;
	float w = (sin(a1) * amp + sin(a2) * amp * 0.35) * u;
	VERTEX.z += w;
	VERTEX.y -= u * u * 0.05 * (0.6 + 0.4 * sin(t * 0.6 + ph));
	// yaklaşık normal: dalganın eğimi
	float dw = (cos(a1) * 6.0 * amp + cos(a2) * 11.0 * amp * 0.35) * u / 1.5;
	NORMAL = normalize(NORMAL + vec3(-dw, 0.0, 0.0) * sign(NORMAL.z));
	shade = 0.82 + 0.18 * cos(a1);
}

void fragment() {
	ALBEDO = col.rgb * shade;
	ROUGHNESS = 0.95;
	SPECULAR = 0.2;
}
