class_name Combat extends RefCounted
# Gerçek savaş verisi (data/real_combat.json, roadmap 49/50/51; üretici tools/gen_combat.js):
# birim başına zırh (mm RHA → oyunda ÷20), can, silah başına gerçek etkili menzil, optik sınıfı,
# hava radarı, APS / kafes zırh. Oyun menzili = gerçek × K_range; dolaylı atış harita köşegeniyle sınırlı.
# Tespit: menzil = det_base × optik × hedef izi (boyut, hareket, ateş, örtü) × K_detect.
# Harita ölçeği: 8 km haritada K = 1 (tam gerçek); küçük haritada aynı oranlarla küçülür (256 m: 0,07 —
# piyade çatışması eski mesafede kalır, araç/füze menzilleri piyadeye göre gerçek oranda uzun).

static var _d := {}
static var K_RANGE := 1.0
static var K_DETECT := 1.0
static var K_BASE := 1.0     # veri dosyasındaki ölçek (8 km haritanın değeri)
static var map_scale := 1.0

# harita ölçeği: K = 0,07 × (kenar / 256 m)^0,77 (256 m 0,07; 1 km 0,2; 2 km 0,35; 4 km 0,59; 8 km 1)
static func set_scale(map_size: float) -> void:
	_load()
	map_scale = clampf(0.07 * pow(map_size / 256.0, 0.77), 0.07, 1.0)
	K_RANGE = K_BASE * map_scale
	K_DETECT = K_BASE * map_scale
	# mermi/füze hızı da aynı ölçekte: uçuş süreleri gerçekle oransal (8 km'de gerçek hız)
	Ammo.get_def("")
	Ammo._load()
	Ammo.K_PROJ = Ammo.K_PROJ_BASE * map_scale
	Soldier._wpn.clear()
static var DET_BASE := 2200.0
const RHA := 20.0      # zırh birimi (mm RHA)

static func _load() -> void:
	if not _d.is_empty():
		return
	_d = {"units": {}, "base": {}, "inf": {}, "optics": {}}
	var f := FileAccess.open("res://data/real_combat.json", FileAccess.READ)
	if f == null:
		return
	var js = JSON.parse_string(f.get_as_text())
	if js is Dictionary:
		_d = js
		K_BASE = float(js.get("K_range", 1.0))
		K_RANGE = K_BASE * map_scale
		K_DETECT = float(js.get("K_detect", 1.0)) * map_scale
		DET_BASE = float(js.get("det_base", DET_BASE))

# araç verisi: birime özel > taban tip
static func vehicle(vid: String, vtype: String) -> Dictionary:
	_load()
	var u: Dictionary = _d.get("units", {}).get(vid, {})
	if not u.is_empty():
		return u
	return _d.get("base", {}).get(vtype, {})

static func inf(role: String) -> Dictionary:
	_load()
	return _d.get("inf", {}).get(role, {})

static func optic(name: String) -> float:
	_load()
	return float(_d.get("optics", {}).get(name, 1.0))

# zırh tablosu oyun biriminde ([[KE ön, yan, arka, üst], [HEAT ...]]); veri yoksa boş
static func armor_units(d: Dictionary) -> Array:
	if not d.has("arm"):
		return []
	var out: Array = []
	for row in d["arm"]:
		var r: Array = []
		for v in row:
			r.append(float(v) / RHA)
		out.append(r)
	return out

# silah menzilleri oyun metresi: doğrudan atış × K_range; dolaylı atış haritanın köşegeniyle sınırlı
static func ranges(d: Dictionary) -> Dictionary:
	_load()
	var out := {}
	var cap := G.MAP * 1.42
	for k in d.get("rng", {}):
		var v := float(d["rng"][k]) * K_RANGE
		if k in ["ind", "fly", "aa"]:
			v = minf(v, cap)
		out[k] = v
	return out

# gerçek genişlik/yükseklik (data/real_dims.json); yoksa (0, 0)
static var _dims := {}
static func dims(vid: String) -> Vector2:
	if _dims.is_empty():
		_dims = {"_": true}
		var f := FileAccess.open("res://data/real_dims.json", FileAccess.READ)
		if f != null:
			var js = JSON.parse_string(f.get_as_text())
			if js is Dictionary:
				for k in js.get("units", {}):
					var u: Dictionary = js["units"][k]
					_dims[k] = Vector2(float(u.get("W", 0.0)), float(u.get("H", 0.0)))
	return _dims.get(vid, Vector2.ZERO)

# tespit menzili (oyun metresi): gözcü optiği × hedef izi
static func detect_range(opt_k: float, sig: float) -> float:
	_load()
	return DET_BASE * opt_k * sig * K_DETECT
