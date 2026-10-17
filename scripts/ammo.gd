class_name Ammo extends RefCounted
# Mühimmat tablosu (data/ammo.json, roadmap 6): kalibre başına gerçek namlu çıkış hızı, kütle, delme,
# doğrudan isabet hasarı, patlama yarıçapı/hasarı; ulusa göre iz rengi; araç → mühimmat eşlemesi.
# Hızlar oyunda K_proj ile ölçeklenir (harita ölçeği), mühimmatlar arası oran gerçek kalır.

static var _d := {}
static var K_PROJ := 1.0
static var K_PROJ_BASE := 1.0     # veri (8 km haritada gerçek hız); haritada × harita ölçeği (uçuş süreleri oransal)

static func _load() -> void:
	if not _d.is_empty():
		return
	_d = {"ammo": {}, "vehicles": {}, "units": {}, "tracer": {}}
	var f := FileAccess.open("res://data/ammo.json", FileAccess.READ)
	if f == null:
		return
	var js = JSON.parse_string(f.get_as_text())
	if js is Dictionary:
		_d = js
		K_PROJ_BASE = float(js.get("K_proj", 1.0))
		K_PROJ = K_PROJ_BASE * Combat.map_scale

static func get_def(id: String) -> Dictionary:
	if id == "":
		return {}
	_load()
	return _d.get("ammo", {}).get(id, {})

# oyun hızı (m/sn): gerçek namlu çıkış hızı × K_proj; tanımsızsa varsayılan
static func speed(id: String, def: float) -> float:
	var a := get_def(id)
	return float(a["v"]) * K_PROJ if a.has("v") else def

# aracın mühimmatı ({ke, he, auto}): birime özel > taban tip + ulus
static func for_vehicle(vid: String, vtype: String, nation: String) -> Dictionary:
	_load()
	var out := {}
	out.merge(_d.get("vehicles", {}).get(vtype, {}).get(nation, {}), true)
	out.merge(_d.get("units", {}).get(vid, {}), true)
	return out

static func tracer(nation: String) -> Color:
	_load()
	var tr: Dictionary = _d.get("tracer", {})
	return Color.html(String(tr.get(nation, tr.get("default", "ffb04a"))))

# iz boyutu kalibreden (roadmap 26): (kalınlık m, kuyruk boyu m). Tüfek ince ve kısa, makineli orta,
# 12,7 mm kalın, otomatik top ve tank topu kalın/uzun ve parlak.
static func tracer_dims(cal: float) -> Vector2:
	if cal <= 6.0:
		return Vector2(0.028, 3.2)
	if cal <= 8.0:
		return Vector2(0.042, 5.0)
	if cal <= 15.0:
		return Vector2(0.075, 7.5)
	if cal <= 40.0:
		return Vector2(0.12, 6.5)
	if cal <= 60.0:
		return Vector2(0.15, 7.5)
	return Vector2(0.22, 10.0)

# takımın iz rengi (NATO kırmızı-turuncu, doğu bloku yeşil)
static func team_tracer(team: int) -> Color:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else ""
	return tracer(nat)
