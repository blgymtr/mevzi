class_name Catalog extends RefCounted
# Ulus araç kataloğu (data/catalog/*.json). Her birim bir "aile"den davranış tabanını alır
# (tank, ZPT, PSA, obüs...) ve kendi adı, canı, hızı, zırhı, maliyeti ve Blender modeliyle oyuna girer.
# Model yoksa taban aracın modeli kullanılır; yeni model eklendikçe otomatik değişir.

const FAM_BASE := {
	"mbt": "tank", "lt": "tank",
	"apc_box": "apc", "apc_tr": "apc", "apc_8x8": "apc", "apc_4x4": "apc", "apc_amph": "apc",
	"ifv_tr": "ifv", "ifv_8x8": "ifv", "td_8x8": "ifv", "td_box": "ifv", "td_ontos": "ifv", "td_gun8x8": "tank",
	"spg": "arty", "spg_open": "arty", "mortar_tr": "arty", "mortar_8x8": "arty",
	"howitzer": "howitzer", "fieldgun": "fieldgun", "hmortar": "hmortar",
	"mlrs_w": "mlrs", "mlrs_t": "mlrs", "missile_launcher": "mlrs",
	"aa_8x8": "aa", "sam_long": "aa", "sam_mid": "aa", "lv_sam": "aa", "ciws": "aa",
	"mrap4": "technical", "mrap6": "technical", "lv_hmmwv": "technical", "lv_jltv": "technical", "lv_isv": "technical", "lv_tow": "technical",
	"eng_breach": "apc", "eng_dozer": "apc", "eng_bridge": "apc", "eng_recovery": "apc", "eng_detect": "technical",
	"heli_atk": "heli", "heli_slim": "heli", "heli_light": "heli",
	"heli_utility": "transport", "heli_tandem": "transport", "heli_heavy": "transport", "tiltrotor": "transport",
	"fpv": "fpv",
}
const CAT_TITLE := {"tank": "Tanklar", "apc": "ZPT", "ifv": "ZMA / PSA", "td": "Tanksavar Araçları", "spg": "Kundağı Motorlu Obüs",
	"towed": "Çekili Topçu", "mlrs": "Roketatar / Füze", "mortar": "Havan", "aa": "Hava Savunma", "eng": "İstihkâm",
	"mrap": "MRAP", "light": "Hafif Araçlar", "heli_atk": "Taarruz Helikopteri", "heli_tr": "Nakliye Helikopteri", "coastal": "Kıyı / Deniz Piyadesi"}
const NATION_TITLE := {"usa": "ABD", "rus": "RUSYA", "chn": "ÇİN", "gbr": "İNGİLTERE"}

static var units := {}        # id -> birim sözlüğü (+ "nation")
static var order: Array = []  # [nation, cat, id]
static var _loaded := false

static func load_all() -> void:
	if _loaded:
		return
	_loaded = true
	var d := DirAccess.open("res://data/catalog")
	if d == null:
		return
	for f in d.get_files():
		if not f.ends_with(".json"):
			continue
		var fa := FileAccess.open("res://data/catalog/" + f, FileAccess.READ)
		if fa == null:
			continue
		var js = JSON.parse_string(fa.get_as_text())
		if not (js is Dictionary):
			continue
		var nat: String = js.get("nation", f.get_basename())
		for u in js.get("units", []):
			if not FAM_BASE.has(u.get("fam", "")):
				continue
			u["nation"] = nat
			units[u["id"]] = u
			order.append([nat, u["cat"], u["id"]])

static func has(id: String) -> bool:
	load_all()
	return units.has(id)

static func get_unit(id: String) -> Dictionary:
	load_all()
	return units.get(id, {})

static func base(id: String) -> String:
	return FAM_BASE.get(get_unit(id).get("fam", ""), "tank")
