shader_type spatial;
// Kum torbası (roadmap 36, kullanıcı: "hâlâ çok yapay"): çuval dokusunun yalnız parlaklığı (örgü) kısık
// karşıtlıkla kullanılır — renk torba başına örnek renkten (solgun haki, zeytin, gri-ten, kirli) gelir; doku
// kendi sarılığını katmaz. Üst yüz güneşte solmuş, alt yüz ve torba araları koyu (birikmiş gölge / toprak),
// dünya konumuna bağlı lekeler (toz, çamur sıçraması).
render_mode cull_back;

uniform sampler2D alb : source_color, filter_linear_mipmap, repeat_enable;
uniform sampler2D nrm : hint_normal, filter_linear_mipmap, repeat_enable;
uniform float uv_scale = 3.0;
uniform float weave = 0.5;        // örgü karşıtlığı
uniform float avg_l = 0.48;       // dokunun ortalama parlaklığı (doğrusal)

varying vec3 wp;
varying float up;

float h3(vec3 p) {
	return fract(sin(dot(p, vec3(127.1, 311.7, 74.7))) * 43758.5453);
}

float vnoise(vec3 p) {
	vec3 i = floor(p);
	vec3 f = fract(p);
	f = f * f * (3.0 - 2.0 * f);
	float a = mix(mix(h3(i), h3(i + vec3(1, 0, 0)), f.x), mix(h3(i + vec3(0, 1, 0)), h3(i + vec3(1, 1, 0)), f.x), f.y);
	float b = mix(mix(h3(i + vec3(0, 0, 1)), h3(i + vec3(1, 0, 1)), f.x), mix(h3(i + vec3(0, 1, 1)), h3(i + vec3(1, 1, 1)), f.x), f.y);
	return mix(a, b, f.z);
}

void vertex() {
	wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	up = NORMAL.y;
}

void fragment() {
	vec2 uv = UV * uv_scale;
	vec3 t = texture(alb, uv).rgb;
	float l = dot(t, vec3(0.299, 0.587, 0.114));
	float wv = mix(1.0, l / avg_l, weave);
	vec3 c = COLOR.rgb * wv;
	// üst yüz solgun, yan / alt koyu (torba araları)
	c *= mix(0.62, 1.0, smoothstep(-0.7, 0.55, up));
	c = mix(c, c * 1.12 + vec3(0.015), smoothstep(0.6, 0.95, up));
	// toz / çamur lekeleri (iki ölçek)
	float n = vnoise(wp * 2.3) * 0.65 + vnoise(wp * 7.1) * 0.35;
	c *= 0.86 + 0.24 * n;
	float mud = smoothstep(0.62, 0.8, vnoise(wp * 1.3 + vec3(5.0)));
	c = mix(c, c * vec3(0.72, 0.66, 0.58), mud * 0.6);
	ALBEDO = c;
	ROUGHNESS = 0.96;
	SPECULAR = 0.25;
	NORMAL_MAP = texture(nrm, uv).rgb;
	NORMAL_MAP_DEPTH = 0.7;
}
