shader_type spatial;
render_mode blend_mix, depth_draw_always, cull_disabled, diffuse_burley, specular_schlick_ggx;

// Kanal / nehir suyu: nehir boyunca akan dalga ve köpük (iki evreli akış haritası), derinliğe göre renk,
// kıyıda köpük. Şerit örgünün köşe rengi: rg akış yönü, b şerit kesiti (orta hızlı, kıyı yavaş); UV: x nehir
// boyunca metre, y kesit (-1..1). Akıntıyla taşınan ince köpük çizgileri (kesitte farklı hızla: kayma), köprü
// ayaklarında akıntıyı karşılayan burunda kabarma + köpük yayı, mansapta genişleyen türbülans izi ve iki sıra
// dönüşümlü girdap (Kármán dizisi) — girdaplar suyun yüzey normalini döndürür, kenarlarında köpük.
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
// (144) gerçekçilik: dalga yüzlerinde gökyüzü yansıması, kıyıda kesik ince köpük
uniform vec3 sky_col : source_color = vec3(0.6, 0.68, 0.74);
uniform float sky_refl = 0.1;
uniform sampler2D river_mask : filter_linear, repeat_disable;
uniform float map_size = 256.0;
uniform vec4 piers[32];            // köprü ayakları: (x, z, akış yönünde yarı boy, yarı kalınlık)
uniform int pier_n = 0;
uniform vec4 ripples[16];          // suya düşüş dalgaları: (x, z, başlangıç zamanı, büyüklük — araç boyuna göre)

varying vec3 wpos;
varying vec2 v_flow;
varying float v_across;
varying vec2 v_uv;
// görsel savaş sisi (FogOfWar global dokuları): su şeffaf geçişte sisin üstüne çizildiği için kendisi kararır
global uniform sampler2D fow_vis;
global uniform sampler2D fow_exp;
global uniform float fow_on;

void vertex() {
	wpos = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz;
	v_flow = COLOR.rg * 2.0 - 1.0;
	v_across = COLOR.b * 2.0 - 1.0;
	v_uv = UV;
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
	// akıntıyla taşınan köpük çizgileri: nehir boyu / kesit uzayında akışa doğru uzamış gürültü (iki evre)
	// (boyuna ~10 m, enine ~0,3 m'lik iz: ince uzun çizgi)
	float lw0 = texture(foam_tex, vec2((v_uv.x - spd * ph0 * 5.5) / 120.0, v_uv.y * 3.0)).r;
	float lw1 = texture(foam_tex, vec2((v_uv.x - spd * ph1 * 5.5) / 120.0 + 0.41, v_uv.y * 3.0 + 0.23)).r;
	float lw2 = texture(foam_tex, vec2((v_uv.x - spd * ph0 * 5.5) / 70.0 + 0.17, v_uv.y * 5.0 + 0.6)).r;
	float lw3 = texture(foam_tex, vec2((v_uv.x - spd * ph1 * 5.5) / 70.0 + 0.63, v_uv.y * 5.0 + 0.1)).r;
	float lstr = mix(lw0, lw1, bw) * 0.6 + mix(lw2, lw3, bw) * 0.4;
	float lines = smoothstep(0.72, 0.9, lstr) * (0.25 + 0.75 * smoothstep(0.3, 0.9, abs(v_uv.y)));
	// köprü ayakları: burunda kabarma ve köpük, mansapta türbülans izi + dönüşümlü girdaplar
	vec2 pp = vec2(-fd.y, fd.x);
	vec2 swirl = vec2(0.0);
	float pfoam = 0.0;
	// ince köpük dokusu (kırık köpük lekeleri için)
	float fz = texture(foam_tex, w / 1.6 - fd * t * spd * 0.5).r;
	for (int i = 0; i < 32; i++) {
		if (i >= pier_n) {
			break;
		}
		vec4 P = piers[i];
		vec2 r = w - P.xy;
		if (dot(r, r) > 1100.0) {
			continue;
		}
		float al = dot(r, fd);
		float ac = dot(r, pp);
		float hl = P.z;
		float ht = P.w;
		// akıntıyı karşılayan burun: suyun kabarması ve köpük yayı
		float up = -al - hl;
		// burnu saran ince hilal: burun ucundan yanlara açılarak akıntıyla geriye uzanır
		float side = abs(ac) - ht * (0.9 + clamp(-up, 0.0, 2.0 * hl) * 0.04);
		float bow = (1.0 - smoothstep(0.0, 0.5, abs(up - 0.25 + max(side, 0.0) * 0.3))) * (1.0 - smoothstep(0.0, 0.6, side))
			+ (1.0 - smoothstep(0.0, 0.35, abs(side - 0.15))) * step(up, 0.3) * step(-2.0 * hl, up);
		pfoam = max(pfoam, clamp(bow, 0.0, 1.0) * smoothstep(0.3, 0.75, fz) * 0.8);
		float da = al - hl;
		if (da > -0.6 && da < 30.0) {
			float dd = max(da, 0.0);
			float wdt = ht * 1.2 + dd * 0.07;
			float fall = exp(-dd / 8.0);
			float inw = 1.0 - smoothstep(wdt * 0.55, wdt * 1.35, abs(ac));
			// girdap dizisi: 2,6 çap arayla, iki sıra dönüşümlü, akıntıyla iner
			float spc = max(ht * 2.0, 0.7) * 2.6;
			float ph = (dd - t * spd * 0.75) / spc;
			float kk = floor(ph + 0.5);
			float sd = mod(kk, 2.0) < 0.5 ? 1.0 : -1.0;
			vec2 dv = vec2((ph - kk) * spc, ac - sd * wdt * 0.42);
			float rv = max(wdt * 0.42, 0.3);
			float g = exp(-dot(dv, dv) / (rv * rv)) * smoothstep(0.0, 1.5, dd);
			swirl += (-dv.y * fd + dv.x * pp) * sd / rv * g * fall * 0.6;
			// köpük: iz boyunca kırık lekeler, girdapta dönen iki kollu sarmal
			float ang = atan(dv.y, dv.x);
			float rr = length(dv) / rv;
			float spiral = 0.5 + 0.5 * sin(ang * 2.0 * sd + rr * 5.0 - t * 2.2 * sd);
			float ring = exp(-pow(rr - 0.75, 2.0) * 6.0) * smoothstep(0.0, 1.5, dd);
			pfoam = max(pfoam, inw * fall * (0.25 * smoothstep(0.55, 0.85, fz) + 0.55 * ring * spiral * smoothstep(0.35, 0.7, fz)));
		}
	}
	nxy += swirl * 0.3;
	// suya düşüş: büyüklüğe göre genişleyen, sönümlenen eş merkezli dalga halkaları (öncü tepe köpüklü)
	float rfoam = 0.0;
	for (int i = 0; i < 16; i++) {
		vec4 R = ripples[i];
		float age = t - R.z;
		if (R.w <= 0.0 || age < 0.0 || age > 9.0) {
			continue;
		}
		vec2 rd = w - R.xy;
		float rl = length(rd);
		float sz = R.w;
		float front = age * (1.6 + 0.9 * sqrt(sz));
		float x = rl - front;
		if (x > 0.8 || x < -sz * 3.0 - 2.0) {
			continue;
		}
		float amp = sz / (1.0 + rl * 0.3) * exp(-age * 0.3);
		float wl = 0.9 + 0.35 * sqrt(sz);
		float env = smoothstep(0.8, 0.0, x) * exp(x / (sz * 0.9 + 0.7));
		float wv = cos(x / wl * 6.283) * env * amp;
		vec2 rn = rl > 0.01 ? rd / rl : vec2(0.0);
		nxy += rn * wv * 0.42;
		// köpük yalnız ilk saniyelerde öncü tepede, kırık
		rfoam = max(rfoam, smoothstep(0.4, 0.0, abs(x + wl * 0.2)) * min(amp, 1.0) * exp(-age * 1.4) * 0.6 * smoothstep(0.4, 0.75, texture(foam_tex, w / 1.8).r + 0.15));
	}
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
	// (144) dalga yüzlerinde gökyüzü yansıması: göğe bakan yüzler açık, öbürleri koyu (düz tek renk yerine
	// pırıltılı yüzey); akıntı yönündeki uzun dalga sırtları hafif aydınlık
	float facet = clamp(0.5 + nxy.x * 0.9 + nxy.y * 0.5, 0.0, 1.0);
	col = mix(col, sky_col, sky_refl * (0.35 + 0.65 * facet));
	col *= 0.94 + 0.12 * facet;
	// köpük: kıyıda ince ve kesik (eskiden iki kıyıda kesintisiz kalın beyaz çizgi — karikatür görünüm), dalga
	// tepelerinde seyrek
	float f = mix(texture(foam_tex, (w - off0 * 1.2) / 3.0).r, texture(foam_tex, (w - off1 * 1.2) / 3.0 + vec2(0.5, 0.25)).r, bw);
	float shore = (1.0 - smoothstep(0.0, 0.16, thick)) * smoothstep(0.42, 0.78, f);
	float crest = smoothstep(0.68, 0.92, f * (0.6 + 0.6 * n1.x + 0.3 * n2.y));
	float foam = clamp(shore * 0.7 + crest * 0.25 + lines * 0.22 + pfoam * 0.7 + rfoam, 0.0, 1.0) * foam_amt;
	col = mix(col, vec3(0.86, 0.88, 0.86), foam);
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
