shader_type spatial;
// GPU'da hesaplanan parçacık: MultiMesh örnek verisi = doğuş parametreleri.
// origin=konum, basis.x=hız, basis.y=(t0, ömür, yerçekimi), basis.z=(boy0, boy1, sürtünme)
// COLOR=renk, INSTANCE_CUSTOM=(dönüş0, dönüş hızı, atlas varyantı, tohum)
// Duman (mode 0): smoke_tex = yüzey normali (RG) + kalınlık (B) + örtme (A) → güneş yönüne göre ışık / öz gölge
// (hacim hissi), yaşlandıkça ince kısımlar önce dağılır (arkası görünür). Duman, ateş ve flipbook'larda
// yumuşak parçacık: zemine / yapıya değdiği yerde sert kesik yerine derinliğe göre söner.
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled, skip_vertex_transform, fog_disabled;

global uniform float game_time;
uniform sampler2D tex : source_color, filter_linear_mipmap;
uniform sampler2D smoke_tex : hint_default_white, filter_linear_mipmap;
uniform sampler2D depth_tex : hint_depth_texture, filter_nearest, repeat_disable;
uniform sampler2D noise_tex : filter_linear_mipmap, repeat_enable;
uniform int mode = 0;          // 0 duman/toz, 1 ateş, 2 kıvılcım, 3 moloz, 4 çizgi, 5-7 flipbook, 8 alev dili
uniform float intensity = 1.0;
uniform float ground_stop = 0.0;
uniform float soft = 0.0;      // yumuşak parçacık mesafesi (m); 0 kapalı
uniform vec3 sun_dir = vec3(0.217, 0.5, -0.866);   // güneşe doğru (dünya)
// dumanın içinden geçen birlikler (131): xyz konum, w yarıçap · hız xyz, w gövde yüksekliği
uniform int mover_n = 0;
uniform vec4 movers[16];
uniform vec4 mover_vel[16];

varying vec4 v_col;
varying float v_age;
varying vec2 v_uv;
varying vec2 v_rot;
varying float v_vz;
varying float v_seed;
varying float v_thin;

void vertex() {
	v_thin = 0.0;
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
	v_rot = vec2(1.0, 0.0);
	v_vz = 0.0;
	v_seed = INSTANCE_CUSTOM.w;
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
		// dumanın içinden geçen araç / asker: gövde dumanı yanlara iter (çekirdek incelir), arkasında iz —
		// duman hareket yönünde sürüklenir, yanlara kıvrılır, hafif yükselir; geçtikten sonra yavaşça kapanır
		if ((mode == 0 || mode == 6 || mode == 7) && mover_n > 0) {
			for (int i = 0; i < mover_n; i++) {
				vec3 m = movers[i].xyz;
				float r = movers[i].w;
				vec3 mv = mover_vel[i].xyz;
				float hh = mover_vel[i].w;
				vec2 d = p.xz - m.xz;
				float dl = length(d);
				if (dl > r * 5.0) {
					continue;
				}
				float hf = 1.0 - smoothstep(hh * 0.8, hh * 1.8 + 0.5, p.y - m.y);
				float infl = (1.0 - smoothstep(r * 0.4, r * 1.6, dl)) * hf;
				vec2 dir = dl > 0.01 ? d / dl : vec2(1.0, 0.0);
				p.xz += dir * infl * r * 0.6;
				v_thin = max(v_thin, infl * (1.0 - smoothstep(0.0, r * 0.9, dl)));
				float sp = length(mv.xz);
				if (sp > 0.15) {
					vec2 vd = mv.xz / sp;
					vec2 side = vec2(-vd.y, vd.x);
					float behind = -dot(d, vd);
					float lat = dot(d, side);
					float wk = smoothstep(-r * 0.3, r * 0.6, behind) * (1.0 - smoothstep(r * 1.5, r * 5.0, behind))
						* (1.0 - smoothstep(r * 0.7, r * 1.8, abs(lat))) * hf;
					float spk = min(sp, 8.0);
					p.xz += vd * wk * spk * 0.3;
					p.xz += side * sign(lat + 0.001) * wk * (0.35 + 0.25 * sin(behind * 1.4 - game_time * 2.6 + v_seed * 6.0)) * min(spk, 4.0) * 0.4;
					p.y += wk * min(spk, 6.0) * 0.08;
				}
			}
		}
		float sz = mix(s0, s1, 1.0 - (1.0 - a) * (1.0 - a));
		float rot = (mode >= 5) ? INSTANCE_CUSTOM.y * 0.15 : INSTANCE_CUSTOM.x + INSTANCE_CUSTOM.y * t;
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
		} else if (mode == 8) {
			// alev dili: dik duran (silindirik) pano, tabanı kaynakta; hafif yalpalar
			float sway = sin(game_time * 3.1 + INSTANCE_CUSTOM.w * 20.0) * 0.12;
			wp = p + right * (q.x * sz * 0.62 + q.y * sz * sway) + vec3(0.0, 1.0, 0.0) * (q.y + 0.5) * sz;
		} else {
			float c = cos(rot);
			float s = sin(rot);
			v_rot = vec2(c, s);
			q = vec2(q.x * c - q.y * s, q.x * s + q.y * c) * sz;
			wp = p + right * q.x + up * q.y;
		}
		vec4 vp = VIEW_MATRIX * vec4(wp, 1.0);
		v_vz = vp.z;
		POSITION = PROJECTION_MATRIX * vp;
	}
	float var_i = INSTANCE_CUSTOM.z;
	vec2 cell = vec2(mod(var_i, 2.0), floor(mod(var_i, 4.0) / 2.0));
	v_uv = (mode >= 5) ? UV : (UV + cell) * 0.5;
	if (mode == 8) {
		v_uv = UV;
	}
}

// parçacığın arkasındaki sahneye uzaklık → 0..1 (yakınsa saydamlaşır: zeminde / duvarda sert kesik olmaz)
float soft_fade(vec2 suv, mat4 inv_proj) {
	float d = texture(depth_tex, suv).r;
	vec4 sp = inv_proj * vec4(suv * 2.0 - 1.0, d, 1.0);
	float scene_z = sp.z / sp.w;
	return clamp((v_vz - scene_z) / soft, 0.0, 1.0);
}

void fragment() {
	float a = v_age;
	float sf = soft > 0.0 ? soft_fade(SCREEN_UV, INV_PROJECTION_MATRIX) : 1.0;
	if (mode == 0) {
		vec4 st = texture(smoke_tex, v_uv);
		// doku uzayı normali → görüş uzayı (dörtgen kendi ekseninde döner)
		vec2 nt = st.rg * 2.0 - 1.0;
		vec2 nr = vec2(nt.x * v_rot.x - nt.y * v_rot.y, nt.x * v_rot.y + nt.y * v_rot.x);
		vec3 n = vec3(nr, sqrt(max(0.0, 1.0 - dot(nr, nr))));
		vec3 L = normalize((VIEW_MATRIX * vec4(sun_dir, 0.0)).xyz);
		float ndl = dot(n, L);
		float wrap = clamp(ndl * 0.55 + 0.45, 0.0, 1.0);
		float thick = st.b;
		// güneşe bakan kabartılar aydınlık ve sıcak, gölge yüzü serin; kalın çekirdek ışıktan uzak yanda koyulaşır
		float lit = mix(0.36, 1.15, wrap) * mix(1.0, 0.7, thick * (1.0 - wrap));
		// ince kenar arkadan gelen ışığı geçirir (hafif parlak saçak)
		lit += (1.0 - st.a) * 0.25 * wrap;
		ALBEDO = v_col.rgb * lit * mix(vec3(0.84, 0.88, 0.98), vec3(1.06, 1.0, 0.9), wrap);
		// başta hızlı belir, yaşlandıkça ince kısımlar önce dağılır (delikler açılır), en son kalın çekirdek
		float born = smoothstep(0.0, 0.06, a);
		float erode = smoothstep(a * 0.6 - 0.05, a * 0.6 + 0.3, thick + 0.1);
		ALPHA = st.a * erode * v_col.a * born * (1.0 - smoothstep(0.72, 1.0, a)) * 0.7 * sf * (1.0 - 0.45 * v_thin);
	} else if (mode == 1) {
		vec4 tx = texture(tex, v_uv);
		float heat = 1.0 - a;
		vec3 hot = vec3(1.0, 0.92, 0.7);
		vec3 mid = vec3(1.0, 0.5, 0.12);
		vec3 cold = vec3(0.45, 0.08, 0.02);
		vec3 c = mix(cold, mid, smoothstep(0.0, 0.6, heat * tx.r * 1.3));
		c = mix(c, hot, smoothstep(0.55, 1.0, heat * tx.r * 1.2));
		c = mix(c, vec3(0.08, 0.06, 0.05), smoothstep(0.55, 1.0, a));
		ALBEDO = c * intensity * v_col.rgb * (0.75 + heat * 0.6);
		// alevin dış kenarı yarı saydam (yalnız sıcak çekirdek dolu)
		ALPHA = clamp(tx.a * 1.25 * (0.55 + 0.45 * tx.r), 0.0, 1.0) * v_col.a * (1.0 - smoothstep(0.5, 1.0, a)) * sf;
	} else if (mode == 2) {
		vec4 tx = texture(tex, v_uv);
		ALBEDO = v_col.rgb * intensity;
		ALPHA = tx.a * (1.0 - a);
	} else if (mode == 8) {
		// alev dili: yukarı akan gürültüyle çarpıtılmış damla biçimi; çekirdek beyaz-sarı, kenar turuncu-kızıl,
		// uç kopuk; tabandan yukarı incelir. Üst üste binen diller hacimli alev oluşturur.
		vec2 uv = v_uv;
		float h = 1.0 - uv.y;                       // 0 taban, 1 uç
		float tt = game_time * 1.0 + v_seed * 13.0;
		float n1 = texture(noise_tex, vec2(uv.x * 0.9 + v_seed * 3.7, uv.y * 0.55 + tt * 1.35)).r;
		float n2 = texture(noise_tex, vec2(uv.x * 2.1 - v_seed * 1.3, uv.y * 1.3 + tt * 2.4)).r;
		float n = n1 * 0.65 + n2 * 0.35;
		float x = uv.x - 0.5 + (n1 - 0.5) * 0.45 * h;
		float wdt = 0.36 * pow(max(1.0 - h, 0.0), 0.55) + 0.02;
		float body = smoothstep(wdt, wdt * 0.45, abs(x));
		float tip = 1.0 - smoothstep(0.45, 1.0, h + (n - 0.5) * 0.7);
		float base = smoothstep(0.0, 0.1, h);
		float m = body * tip * base;
		float heat = clamp(m * (1.25 - h * 0.9) + (n2 - 0.5) * 0.3, 0.0, 1.0);
		vec3 c = mix(vec3(0.55, 0.06, 0.01), vec3(1.0, 0.42, 0.06), smoothstep(0.1, 0.45, heat));
		c = mix(c, vec3(1.0, 0.86, 0.5), smoothstep(0.5, 0.85, heat));
		c = mix(c, vec3(1.0, 0.97, 0.88), smoothstep(0.85, 1.0, heat));
		float fade = smoothstep(0.0, 0.12, a) * (1.0 - smoothstep(0.55, 1.0, a));
		ALBEDO = c * intensity * v_col.rgb;
		ALPHA = clamp(m * 1.6, 0.0, 1.0) * smoothstep(0.05, 0.35, heat) * v_col.a * fade * sf;
	} else if (mode >= 5) {
		// flipbook (8x6): yaşa göre kare seçilir, iki kare arası karışım
		float fr = clamp(a, 0.0, 0.999) * 48.0;
		float f0 = floor(fr);
		float f1 = min(f0 + 1.0, 47.0);
		vec2 c0 = vec2(mod(f0, 8.0), floor(f0 / 8.0));
		vec2 c1 = vec2(mod(f1, 8.0), floor(f1 / 8.0));
		vec4 t0 = texture(tex, (v_uv + c0) / vec2(8.0, 6.0));
		vec4 t1 = texture(tex, (v_uv + c1) / vec2(8.0, 6.0));
		vec4 tf = mix(t0, t1, fract(fr));
		vec3 fc = tf.rgb * (mode == 5 ? 1.25 : 1.0);
		if (mode == 5) {
			// ateş topu: alev kısa sürer, bulut hızla isli koyu dumana döner (turuncu leke gibi asılı kalmasın)
			vec3 smoky = vec3(dot(tf.rgb, vec3(0.3, 0.59, 0.11))) * vec3(0.42, 0.4, 0.38);
			fc = mix(fc, smoky, smoothstep(0.22, 0.6, a));
		}
		ALBEDO = fc * v_col.rgb;
		// yoğunluğa göre: ince duman tülü saydam, kalın kısım örter
		ALPHA = pow(tf.a, 1.35) * v_col.a * (1.0 - smoothstep(0.75, 1.0, a)) * sf * (1.0 - 0.45 * v_thin);
	} else if (mode == 4) {
		vec4 tx = texture(tex, v_uv);
		// toprak/şarapnel çizgisi: opak, sona doğru incelip söner
		ALBEDO = v_col.rgb * (0.6 + 0.4 * tx.r);
		ALPHA = tx.a * v_col.a * (1.0 - smoothstep(0.6, 1.0, a));
	} else {
		vec4 tx = texture(tex, v_uv);
		// moloz: köşeli kırık parça (Fx._make_debris), yüzeyler belirgin gölgeli
		if (tx.a < 0.5) {
			discard;
		}
		ALBEDO = v_col.rgb * (0.3 + 0.7 * tx.r);
		ALPHA = v_col.a * (1.0 - smoothstep(0.85, 1.0, a));
	}
}
