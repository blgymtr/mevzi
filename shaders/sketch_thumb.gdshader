shader_type canvas_item;
// Eskiz arayüzü (roadmap 65/57): üç boyutlu küçük resmi kâğıt üstüne mürekkep çizime çevirir —
// kenarlar (Sobel) mürekkep çizgisi, gölgeler eğik / çapraz tarama, özgün renk hafif suluboya yıkaması.
uniform vec4 paper : source_color = vec4(0.87, 0.84, 0.76, 1.0);
uniform vec4 ink : source_color = vec4(0.13, 0.12, 0.1, 1.0);
uniform float edge_k = 2.6;
uniform float wash = 0.32;
uniform float hatch_px = 4.0;

float lum(vec3 c) {
	return dot(c, vec3(0.299, 0.587, 0.114));
}

// TEXTURE yalnız fragment() içinde okunabilir: örnekleyici parametreyle geçer
float L(sampler2D tex, vec2 uv) {
	return lum(texture(tex, uv).rgb);
}

void fragment() {
	vec2 px = TEXTURE_PIXEL_SIZE;
	vec4 src = texture(TEXTURE, UV);
	float l = lum(src.rgb);
	float tl = L(TEXTURE, UV + px * vec2(-1.0, -1.0));
	float tc = L(TEXTURE, UV + px * vec2(0.0, -1.0));
	float tr = L(TEXTURE, UV + px * vec2(1.0, -1.0));
	float ml = L(TEXTURE, UV + px * vec2(-1.0, 0.0));
	float mr = L(TEXTURE, UV + px * vec2(1.0, 0.0));
	float bl = L(TEXTURE, UV + px * vec2(-1.0, 1.0));
	float bc = L(TEXTURE, UV + px * vec2(0.0, 1.0));
	float br = L(TEXTURE, UV + px * vec2(1.0, 1.0));
	float gx = (tr + 2.0 * mr + br) - (tl + 2.0 * ml + bl);
	float gy = (bl + 2.0 * bc + br) - (tl + 2.0 * tc + tr);
	float e = clamp(length(vec2(gx, gy)) * edge_k - 0.12, 0.0, 1.0);
	// tarama: ekran pikseline göre eğik çizgiler; koyu bölgede ikinci (çapraz) takım
	vec2 f = FRAGCOORD.xy;
	float d1 = abs(fract((f.x + f.y) / hatch_px) - 0.5);
	float d2 = abs(fract((f.x - f.y) / (hatch_px * 1.15)) - 0.5);
	float h1 = smoothstep(0.2, 0.06, d1) * smoothstep(0.62, 0.32, l);
	float h2 = smoothstep(0.2, 0.06, d2) * smoothstep(0.36, 0.14, l);
	vec3 base = mix(paper.rgb, src.rgb * 1.15, wash) * mix(0.86, 1.0, smoothstep(0.15, 0.7, l));
	float k = clamp(h1 * 0.5 + h2 * 0.55 + e * 0.9, 0.0, 1.0);
	COLOR = vec4(mix(base, ink.rgb, k), COLOR.a);
}
