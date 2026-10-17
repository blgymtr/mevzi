shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;

// Fotoğraf dokulu arazi: taban + yama + yol + yanık + kıyı çamuru; yükseklik haritası ile oyulmuş nehir yatakları.
uniform sampler2D map_tex : filter_linear, repeat_disable;      // r yol, g iz, b yanık, a yama
uniform sampler2D height_tex : filter_linear, repeat_disable;   // r yükseklik (m)
// tarla deseni: r ekin türü/4, g sıra açısı/π, b ton, a maske (aynı doku: tür en yakın, maske doğrusal)
uniform sampler2D field_tex : filter_nearest, repeat_disable;
uniform sampler2D field_mask : filter_linear, repeat_disable;
uniform sampler2D tex_a : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_a : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_b : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_b : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_road : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D nrm_road : hint_normal, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_bank : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D tex_burn : source_color, filter_linear_mipmap_anisotropic, repeat_enable;
uniform sampler2D macro : filter_linear_mipmap, repeat_enable;  // büyük ölçek gürültü (renk varyasyonu)
uniform sampler2D dune_n : filter_linear_mipmap, repeat_enable; // kumul normal gürültüsü
uniform float map_size = 256.0;
// parça (chunk): bu malzemenin boya/yükseklik dokusu haritanın bir karesini 1 piksel komşu payıyla tutar
uniform vec2 chunk_org = vec2(0.0);
uniform float chunk_size = 256.0;
uniform float chunk_px = 1024.0;
uniform float chunk_hpx = 512.0;
uniform vec3 tint_a : source_color = vec3(1.0);
uniform vec3 tint_a2 : source_color = vec3(1.0);
uniform vec3 tint_b : source_color = vec3(1.0);
uniform vec3 tint_road : source_color = vec3(1.0);
uniform vec3 tint_bank : source_color = vec3(1.0);
uniform vec3 tint_track : source_color = vec3(0.5, 0.4, 0.3);
uniform float scale_a = 14.0;
uniform float scale_b = 10.0;
uniform float scale_road = 6.0;
uniform float patch_noise = 0.5;
uniform float dune_strength = 0.0;
uniform float normal_strength = 1.0;
uniform float macro_strength = 0.18;
uniform float rough = 0.92;
uniform float road_amt = 1.0;
uniform float paved = 0.0;   // 1: yollar parke taşı
// (145) gerçekçilik: soluk doğal renk, büyük ölçekli aşınmış / çıplak toprak lekeleri, toprak yolda tekerlek izi
uniform float desat = 0.0;        // zemini gri tona doğru çek (doygun sarı-yeşili soldurur)
uniform float worn_amt = 0.0;     // büyük çıplak toprak lekeleri
uniform vec3 tint_worn : source_color = vec3(0.62, 0.52, 0.42);
uniform float rut_amt = 0.0;      // toprak yolda iki tekerlek izi
uniform float road_desat = 0.0;   // yol dokusunun kırmızılığını al

varying vec3 wpos;
varying float vh;

float hgt(vec2 w) {
	vec2 cuv = (w - chunk_org) / chunk_size;
	return texture(height_tex, (cuv * chunk_hpx + 1.0) / (chunk_hpx + 2.0)).r;
}

void vertex() {
	vec3 wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	vec2 muv = wp.xz / map_size;
	float inside = step(0.0, muv.x) * step(0.0, muv.y) * step(muv.x, 1.0) * step(muv.y, 1.0);
	float h = hgt(wp.xz) * inside;
	VERTEX.y += h;
	vh = h;
	float e = 0.6;
	float hx = (hgt(wp.xz + vec2(e, 0.0)) - hgt(wp.xz - vec2(e, 0.0))) * inside;
	float hz = (hgt(wp.xz + vec2(0.0, e)) - hgt(wp.xz - vec2(0.0, e))) * inside;
	NORMAL = normalize(vec3(-hx / (2.0 * e), 1.0, -hz / (2.0 * e)));
	wpos = wp + vec3(0.0, h, 0.0);
}

vec3 unpack_n(vec4 t) {
	return vec3(t.xy * 2.0 - 1.0, 0.0);
}

void fragment() {
	vec2 w = wpos.xz;
	vec2 muv = w / map_size;
	float inside = step(0.0, muv.x) * step(0.0, muv.y) * step(muv.x, 1.0) * step(muv.y, 1.0);
	vec2 cuv = (w - chunk_org) / chunk_size;
	vec4 m = texture(map_tex, (cuv * chunk_px + 1.0) / (chunk_px + 2.0)) * inside;
	float mac = texture(macro, w / 97.0).r;
	float mac2 = texture(macro, w / 23.0 + vec2(0.31, 0.77)).r;
	// taban: iki ölçek karışımı (tekrarı kırar)
	vec2 ua = w / scale_a;
	vec2 ua2 = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8)) * w / (scale_a * 2.7) + vec2(0.37, 0.11);
	vec3 a1 = texture(tex_a, ua).rgb;
	vec3 a2 = texture(tex_a, ua2).rgb;
	float k = smoothstep(0.35, 0.65, mac2);
	vec3 base = mix(a1, a2, k * 0.6) * mix(tint_a, tint_a2, smoothstep(0.3, 0.7, mac));
	vec3 nb = mix(unpack_n(texture(nrm_a, ua)), unpack_n(texture(nrm_a, ua2)), k * 0.6);
	// yama (çim/toprak, kar/çamur…)
	float pm = clamp(m.a + (mac - 0.5) * patch_noise, 0.0, 1.0);
	pm = smoothstep(0.35, 0.65, pm);
	vec2 ub = w / scale_b;
	vec3 bcol = texture(tex_b, ub).rgb * tint_b;
	base = mix(base, bcol, pm);
	nb = mix(nb, unpack_n(texture(nrm_b, ub)), pm);
	// tarla: ekin rengi + ekim/sürüm sıraları (uzakta sıralar ortalamaya söner); sınır gürültüyle kırılır
	float fmk = smoothstep(0.3, 0.7, texture(field_mask, muv).a) * inside;
	if (fmk > 0.002) {
		vec4 fl = texture(field_tex, muv);
		int ct = int(fl.r * 5.0 + 0.5);
		float ang = fl.g * 3.14159265;
		float rowc = dot(w, vec2(-sin(ang), cos(ang)));
		float lum = dot(base, vec3(0.299, 0.587, 0.114));
		float fvar = texture(macro, w / 41.0 + vec2(0.23, 0.71)).r;
		// renkler doğrusal uzayda (sRGB karşılığı yorumda); taban dokusunun ayrıntısı parlaklık oranıyla korunur
		vec3 cc = vec3(0.115, 0.165, 0.034);                                              // çayır  ~(0.38, 0.45, 0.21)
		float rowk = 0.08;
		float rw = 1.6;
		float amt = 0.9;
		if (ct == 1) { cc = vec3(0.30, 0.205, 0.068); rowk = 0.18; rw = 0.4; }          // buğday ~(0.59, 0.49, 0.30)
		else if (ct == 2) { cc = vec3(0.047, 0.10, 0.013); rowk = 0.45; rw = 0.75; }     // yeşil ekin ~(0.25, 0.35, 0.14)
		else if (ct == 3) { cc = vec3(0.07, 0.04, 0.018); rowk = 0.45; rw = 0.6; }       // sürülmüş ~(0.30, 0.23, 0.16)
		else if (ct == 5) { cc = vec3(0.018, 0.027, 0.0065); rowk = 0.0; amt = 0.88; }   // orman zemini ~(0.16, 0.19, 0.10)
		cc *= (0.8 + 0.4 * fl.b) * (0.75 + 0.5 * fvar);
		float rows = 0.5 + 0.5 * sin(rowc * 6.2831853 / rw);
		rows = mix(rows, 0.5, smoothstep(rw * 0.2, rw * 0.55, fwidth(rowc)));
		vec3 fcol = cc * (1.0 - rowk * rows) * clamp(lum / 0.13, 0.6, 1.45);
		base = mix(base, fcol, fmk * amt);
	}
	// (145) çıplak / aşınmış toprak: çok düşük frekanslı leke + kenarı orta ölçekle kırılır; tarla ve yol dışı
	float bank0 = smoothstep(-0.05, -0.7, vh);
	if (worn_amt > 0.0) {
		float wn = texture(macro, w / 263.0 + vec2(0.57, 0.19)).r + (mac2 - 0.5) * 0.35 + (texture(macro, w / 9.0).r - 0.5) * 0.18;
		float worn = smoothstep(0.62, 0.74, wn) * worn_amt * (1.0 - fmk) * (1.0 - bank0);
		vec3 soil = texture(tex_bank, w / 6.5).rgb * tint_worn;
		base = mix(base, soil, worn * 0.8);
	}
	// kıyı çamuru (yükseklik < 0)
	float bank = bank0;
	base = mix(base, texture(tex_bank, w / 5.0).rgb * tint_bank, bank);
	// yol
	vec2 ur = w / scale_road;
	float road = smoothstep(0.15, 0.7, m.r) * road_amt * (0.75 + 0.5 * texture(macro, w / 6.0).r);
	vec3 road_t = texture(tex_road, ur).rgb;
	road_t = mix(road_t, vec3(dot(road_t, vec3(0.299, 0.587, 0.114))), road_desat);
	vec3 road_col = road_t * tint_road;
	// (145) toprak yolda iki tekerlek izi: yol maskesinin iç kenarına paralel koyu bant
	if (rut_amt > 0.0 && paved < 0.5) {
		float rut = exp(-pow((m.r - 0.78) / 0.07, 2.0)) * (0.7 + 0.6 * texture(macro, w / 3.0).r);
		road_col *= 1.0 - rut * 0.32 * rut_amt;
	}
	vec3 road_n = unpack_n(texture(nrm_road, ur));
	if (paved > 0.5) {
		// parke taşı: voronoi hücreleri, taş arası koyu derz, taş başına ton farkı
		vec2 g = w * 3.2;
		vec2 gi = floor(g);
		vec2 gf = fract(g);
		float d1 = 8.0;
		float d2 = 8.0;
		float hid = 0.0;
		for (int y = -1; y <= 1; y++) {
			for (int x = -1; x <= 1; x++) {
				vec2 o = vec2(float(x), float(y));
				vec2 h = fract(sin(vec2(dot(gi + o, vec2(127.1, 311.7)), dot(gi + o, vec2(269.5, 183.3)))) * 43758.5453);
				vec2 r = o + 0.15 + h * 0.7 - gf;
				float dd = dot(r, r);
				if (dd < d1) { d2 = d1; d1 = dd; hid = h.x; } else if (dd < d2) { d2 = dd; }
			}
		}
		float edge = smoothstep(0.0, 0.12, sqrt(d2) - sqrt(d1));
		vec3 stone = mix(vec3(0.2, 0.19, 0.18), vec3(0.34, 0.32, 0.29), hid) * (0.85 + 0.3 * texture(macro, w / 3.0).r);
		road_col = mix(vec3(0.08, 0.075, 0.07), stone, edge);
		road_n = normalize(vec3((gf - 0.5) * (1.0 - edge) * 0.6, 1.0));
	}
	base = mix(base, road_col, road);
	nb = mix(nb, road_n, road);
	// tekerlek / palet izi
	float tr = clamp(m.g, 0.0, 1.0);
	base = mix(base, base * tint_track, tr * 0.85);
	// yanık
	float sc = clamp(m.b, 0.0, 1.0);
	base = mix(base, texture(tex_burn, w / 4.0).rgb * 0.45, sc * 0.9);
	// büyük ölçek ton
	base *= 1.0 + (mac - 0.5) * macro_strength * 2.0;
	// (145) soluk doğal renk
	base = mix(base, vec3(dot(base, vec3(0.299, 0.587, 0.114))), desat);
	// kumullar
	if (dune_strength > 0.0) {
		mat2 rot = mat2(vec2(0.8, 0.6), vec2(-0.6, 0.8));
		vec2 dw = rot * w;
		vec3 dn = texture(dune_n, dw * vec2(1.0 / 140.0, 1.0 / 50.0)).xyz * 2.0 - 1.0;
		nb.xy += dn.xy * dune_strength * (1.0 - road);
		base *= 1.0 + dn.x * 0.06 * dune_strength;
	}
	ALBEDO = base;
	NORMAL_MAP = normalize(vec3(nb.xy * normal_strength, 1.0)) * 0.5 + 0.5;
	ROUGHNESS = mix(rough, 0.35, bank * 0.6);
	SPECULAR = 0.25;
}
