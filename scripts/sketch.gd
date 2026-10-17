class_name Sketch extends RefCounted
# Eskiz (el çizimi) arayüz takımı (roadmap 65/57): saha defteri kâğıdı üstüne mürekkep. Kâğıt dokusu ve
# mürekkep çerçeveleri yordamsal üretilir (lif, leke, kenar kararması; hafif titrek, köşede taşan çift çizgi) —
# hazır görsel / parlama / gradyan yok. Renkler: kâğıt, mürekkep, kırmızı ve mavi kopya kalemi.

const PAPER := Color(0.87, 0.84, 0.76)
const PAPER_D := Color(0.8, 0.76, 0.66)
const INK := Color(0.13, 0.12, 0.1)
const INK2 := Color(0.36, 0.34, 0.29)
const INK3 := Color(0.52, 0.49, 0.42)
const RED := Color(0.64, 0.19, 0.14)
const BLUE := Color(0.17, 0.31, 0.55)
const OLIVE := Color(0.27, 0.4, 0.18)

static var _cache := {}

# ------------------------------------------------------------ kâğıt
static func _paper(img: Image, rng: RandomNumberGenerator, base: Color, alpha: float) -> void:
	var w := img.get_width()
	var h := img.get_height()
	var fn := FastNoiseLite.new()
	fn.seed = rng.randi()
	fn.frequency = 0.035
	var fl := FastNoiseLite.new()
	fl.seed = rng.randi()
	fl.frequency = 0.22
	fl.fractal_octaves = 2
	for y in h:
		for x in w:
			var n := fn.get_noise_2d(x, y) * 0.035 + fl.get_noise_2d(x * 0.4, y * 2.2) * 0.018
			# kenarlara doğru hafif sararma
			var ex := minf(float(x), float(w - 1 - x)) / maxf(w * 0.5, 1.0)
			var ey := minf(float(y), float(h - 1 - y)) / maxf(h * 0.5, 1.0)
			var edge := 1.0 - clampf(minf(ex, ey) * 6.0, 0.0, 1.0)
			var c := base.darkened(0.06 * edge) + Color(n, n, n * 0.9, 0.0)
			img.set_pixel(x, y, Color(c.r, c.g, c.b, alpha))
	# lekeler
	for i in int(w * h / 900.0):
		var px := rng.randi_range(0, w - 1)
		var py := rng.randi_range(0, h - 1)
		var c2 := img.get_pixel(px, py)
		img.set_pixel(px, py, c2.darkened(rng.randf_range(0.05, 0.18)))

# titrek mürekkep çizgisi (a → b), w kalınlık
static func ink_line(img: Image, a: Vector2, b: Vector2, col: Color, w: float, rng: RandomNumberGenerator, wob := 0.7) -> void:
	var L := a.distance_to(b)
	var n := maxi(2, int(L))
	var d := (b - a) / maxf(L, 0.001)
	var nrm := Vector2(-d.y, d.x)
	var off := 0.0
	var ww := w
	for i in n + 1:
		var t := float(i) / n
		off = clampf(off + rng.randf_range(-0.18, 0.18), -wob, wob)
		ww = clampf(ww + rng.randf_range(-0.08, 0.08), w * 0.7, w * 1.25)
		var p := a.lerp(b, t) + nrm * off
		var r := int(ceil(ww))
		for oy in range(-r, r + 1):
			for ox in range(-r, r + 1):
				var q := Vector2(p.x + ox, p.y + oy)
				var dd := Vector2(ox, oy).length()
				if dd > ww:
					continue
				var xi := int(q.x)
				var yi := int(q.y)
				if xi < 0 or yi < 0 or xi >= img.get_width() or yi >= img.get_height():
					continue
				var k := clampf(ww - dd, 0.0, 1.0) * col.a
				var bg := img.get_pixel(xi, yi)
				img.set_pixel(xi, yi, Color(lerpf(bg.r, col.r, k), lerpf(bg.g, col.g, k), lerpf(bg.b, col.b, k), maxf(bg.a, k)))

# çift çizgili çerçeve; köşelerde çizgiler hafifçe taşar (elle çizilmiş)
static func ink_frame(img: Image, inset: float, col: Color, rng: RandomNumberGenerator, w := 1.1, double := true) -> void:
	var W := float(img.get_width())
	var H := float(img.get_height())
	var ov := 3.0
	var i0 := inset
	ink_line(img, Vector2(i0 - ov, i0), Vector2(W - i0 + ov * 0.5, i0 + rng.randf_range(-0.6, 0.6)), col, w, rng)
	ink_line(img, Vector2(i0, H - i0), Vector2(W - i0 + ov, H - i0 + rng.randf_range(-0.6, 0.6)), col, w, rng)
	ink_line(img, Vector2(i0, i0 - ov * 0.5), Vector2(i0 + rng.randf_range(-0.6, 0.6), H - i0 + ov), col, w, rng)
	ink_line(img, Vector2(W - i0, i0 - ov), Vector2(W - i0 + rng.randf_range(-0.6, 0.6), H - i0 + ov * 0.5), col, w, rng)
	if double:
		var i1 := inset + 3.0
		var c2 := Color(col.r, col.g, col.b, col.a * 0.55)
		ink_line(img, Vector2(i1, i1), Vector2(W - i1, i1), c2, w * 0.6, rng, 0.5)
		ink_line(img, Vector2(i1, H - i1), Vector2(W - i1, H - i1), c2, w * 0.6, rng, 0.5)
		ink_line(img, Vector2(i1, i1), Vector2(i1, H - i1), c2, w * 0.6, rng, 0.5)
		ink_line(img, Vector2(W - i1, i1), Vector2(W - i1, H - i1), c2, w * 0.6, rng, 0.5)

# ------------------------------------------------------------ biçemler
static func _tex(key: String, w: int, h: int, maker: Callable) -> ImageTexture:
	if _cache.has(key):
		return _cache[key]
	var img := Image.create(w, h, false, Image.FORMAT_RGBA8)
	maker.call(img)
	var t := ImageTexture.create_from_image(img)
	_cache[key] = t
	return t

static func _box(t: Texture2D, m: int, cm := 10) -> StyleBoxTexture:
	var s := StyleBoxTexture.new()
	s.texture = t
	s.texture_margin_left = m
	s.texture_margin_right = m
	s.texture_margin_top = m
	s.texture_margin_bottom = m
	s.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.axis_stretch_vertical = StyleBoxTexture.AXIS_STRETCH_MODE_TILE_FIT
	s.content_margin_left = cm
	s.content_margin_right = cm
	s.content_margin_top = cm * 0.8
	s.content_margin_bottom = cm * 0.8
	return s

# kâğıt pano (alt paneller, harita çerçevesi)
static func panel(alpha := 0.96, cm := 12, seed := 3) -> StyleBoxTexture:
	var t := _tex("panel%d_%.2f" % [seed, alpha], 192, 192, func(img: Image):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		_paper(img, rng, PAPER, alpha)
		ink_frame(img, 4.0, INK, rng, 1.2, true))
	return _box(t, 22, cm)

# ince şerit (üst kaynak satırı, ipucu, uyarı fişi)
static func slip(alpha := 0.94, cm := 8, seed := 7) -> StyleBoxTexture:
	var t := _tex("slip%d_%.2f" % [seed, alpha], 128, 64, func(img: Image):
		var rng := RandomNumberGenerator.new()
		rng.seed = seed
		_paper(img, rng, PAPER, alpha)
		ink_frame(img, 2.5, INK, rng, 0.9, false))
	return _box(t, 12, cm)

# düğme durumları: normal (kâğıt + ince çerçeve), üzerinde (kırmızı kalem alt çizgi), basılı (mürekkep dolgu),
# devre dışı (soluk)
static func button(state: String, cm := 6) -> StyleBoxTexture:
	var t := _tex("btn_" + state, 96, 48, _make_button.bind(state))
	return _box(t, 10, cm)

static func _make_button(img: Image, state: String) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = {"normal": 11, "hover": 12, "pressed": 13, "disabled": 14}.get(state, 11)
	if state == "pressed":
		_paper(img, rng, INK.lightened(0.08), 0.97)
		ink_frame(img, 2.0, INK, rng, 1.0, false)
	elif state == "disabled":
		_paper(img, rng, PAPER_D, 0.55)
		ink_frame(img, 2.0, INK3, rng, 0.8, false)
	else:
		_paper(img, rng, PAPER, 0.97)
		ink_frame(img, 2.0, INK, rng, 0.95, false)
		if state == "hover":
			# kırmızı kalemle iki kez çizilmiş alt çizgi
			ink_line(img, Vector2(8, 39), Vector2(88, 38), RED, 1.2, rng, 0.8)
			ink_line(img, Vector2(12, 41), Vector2(84, 40.5), Color(RED.r, RED.g, RED.b, 0.6), 0.8, rng, 0.8)

# büyük harfli Türkçe metni cümle düzenine çevirir (İ→i, I→ı); kısaltmalar (≤3 harf, sesli harf az) olduğu gibi kalır
static func sc(t: String) -> String:
	var parts := PackedStringArray()
	var first := true
	for w in t.split(" "):
		var lw := w
		var caps := w.to_upper() == w and w.to_lower() != w
		if caps and (w.length() > 3 or _has_vowel(w) or w.ends_with(".")) and not w in ACRONYMS:
			lw = _lower_tr(w)
		# cümlenin ilk sözcüğü büyük harfle başlar (biçim kodları / ayraçlar atlanır)
		if first and caps and lw.length() > 0:
			lw = _upper_tr(lw.substr(0, 1)) + lw.substr(1)
		first = false
		parts.append(lw)
	return " ".join(parts)

const ACRONYMS := ["İHA", "AT", "TOW", "XP", "HQ", "UAV", "ATGM", "RPG", "NATO"]

static func _has_vowel(w: String) -> bool:
	for c in w:
		if c in "AEIİOÖUÜaeıioöuü":
			return true
	return false

static func _lower_tr(w: String) -> String:
	if I18n.lang == "tr":
		w = w.replace("İ", "i").replace("I", "ı")
	return w.to_lower()

static func _upper_tr(c: String) -> String:
	if I18n.lang == "tr":
		if c == "i":
			return "İ"
		if c == "ı":
			return "I"
	return c.to_upper()

static func font_body() -> Font:
	return load("res://assets/fonts/BarlowCondensed-Medium.ttf")

static func font_head() -> Font:
	return load("res://assets/fonts/BarlowCondensed-SemiBold.ttf")
