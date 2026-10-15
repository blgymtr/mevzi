class_name Ammo extends RefCounted
# Mühimmat tablosu (data/ammo.json, roadmap 6): kalibre başına gerçek namlu çıkış hızı, kütle, delme,
# doğrudan isabet hasarı, patlama yarıçapı/hasarı; ulusa göre iz rengi; araç → mühimmat eşlemesi.
# Hızlar oyunda K_proj ile ölçeklenir (harita ölçeği), mühimmatlar arası oran gerçek kalır.

static var _d := {}
static var K_PROJ := 0.11

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
		K_PROJ = float(js.get("K_proj", K_PROJ))

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

# takımın iz rengi (NATO kırmızı-turuncu, doğu bloku yeşil)
static func team_tracer(team: int) -> Color:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else ""
	return tracer(nat)
