class_name Keybinds extends RefCounted
# Tuş atamaları: oyundaki tüm klavye kısayolları tek tabloda. Her eylemin en çok iki
# tuşu var (birincil / ikincil). Tuş = keycode | değiştirici maskesi (KEY_MASK_CTRL...),
# OS.get_keycode_string ile "Ctrl+1" gibi yazılır. Oyuncunun değiştirdikleri
# user://settings.json içinde "keys" anahtarında (G.main.cfg) saklanır; yalnızca
# varsayılandan farklı olanlar yazılır.
#
# Bağlam (ctx): "global" her zaman, "unit" birlik emirleri, "place" bina yerleştirirken.
# İki eylem ancak bağlamları kesişirse çakışır ("place" ile "unit" kesişmez: R hem geri
# çekil hem yerleştirmede döndür olabilir). Sabit (fixed) eylemler atanamaz; yalnızca
# listede görünür ve çakışma denetimine girer (kamera tuşları cam.gd'de doğrudan okunur).

const CATS := [
	["orders", "BİRLİK EMİRLERİ"],
	["select", "SEÇİM VE KONTROL GRUPLARI"],
	["game", "OYUN"],
	["fixed", "SABİT TUŞLAR"],
]
const MODS := KEY_MASK_CTRL | KEY_MASK_SHIFT | KEY_MASK_ALT | KEY_MASK_META
const LENIENT := KEY_MASK_SHIFT | KEY_MASK_ALT     # eşleşme yoksa bunlar yok sayılır (Shift+G = G)

static var _defs: Array = []        # [{id, t, cat, ctx, def: [a, b], fixed, held, n}]
static var _idx := {}               # id -> tanım
static var _binds := {}             # id -> [a, b]
static var _inited := false
static var version := 0             # her değişiklikte artar (HUD emir düğmeleri yeniden çizilir)

# ------------------------------------------------------------ tanımlar
static func _add(id: String, t: String, cat: String, ctx: String, a: int, b := 0, fixed := false, held := false, n := -1) -> void:
	# t: Türkçe ad (çeviri anahtarı); n >= 0 ise ad bir "%d" şablonudur (grup numarası)
	var d := {"id": id, "t": t, "cat": cat, "ctx": ctx, "def": [a, b], "fixed": fixed, "held": held, "n": n}
	_defs.append(d)
	_idx[id] = d

static func _build_defs() -> void:
	_defs.clear()
	_idx.clear()
	# emirler: varsayılanlar Hud.ORDER_KEYS'ten — yeni emir eklendiğinde listeye kendiliğinden girer
	var okey := {}
	for k in Hud.ORDER_KEYS:
		okey[Hud.ORDER_KEYS[k]] = int(k)
	for id in Hud.ORDER_SEQ:
		_add("o." + id, Hud.ORDERS[id]["t"], "orders", "unit", int(okey.get(id, 0)))
	for id in okey:
		if not _idx.has("o." + id) and Hud.ORDERS.has(id):
			_add("o." + id, Hud.ORDERS[id]["t"], "orders", "unit", int(okey[id]))
	# seçim + kontrol grupları (1..9, 0)
	_add("sel.inf", "Ekrandaki piyadeyi seç", "select", "global", KEY_Q)
	_add("sel.veh", "Ekrandaki araçları seç", "select", "global", KEY_E)
	for i in [1, 2, 3, 4, 5, 6, 7, 8, 9, 0]:
		var kc: int = KEY_0 + i
		_add("grp.sel.%d" % i, "Grup %d: seç (ikinci basış: kamera)", "select", "global", kc, 0, false, false, i)
		_add("grp.set.%d" % i, "Grup %d: ata", "select", "global", kc | KEY_MASK_CTRL, 0, false, false, i)
	# oyun
	_add("hq", "Karargâha git", "game", "global", KEY_HOME, KEY_BACKSPACE)
	_add("deploy", "Konuşlanmayı bitir (hazır)", "game", "global", KEY_ENTER, KEY_KP_ENTER)
	_add("place.rot", "Yapıyı döndür (Shift: ters yön)", "game", "place", KEY_R)
	_add("pause", "Duraklat", "game", "global", KEY_P, KEY_PAUSE)
	_add("speed.1", "Oyun hızı ×1", "game", "global", KEY_F1)
	_add("speed.2", "Oyun hızı ×2", "game", "global", KEY_F2)
	_add("speed.3", "Oyun hızı ×3", "game", "global", KEY_F3)
	# sabit: atanamaz, çakışma denetimi için listede
	_add("esc", "İptal / duraklatma menüsü", "fixed", "global", KEY_ESCAPE, 0, true)
	_add("cam.up", "Kamera: yukarı", "fixed", "global", KEY_W, KEY_UP, true, true)
	_add("cam.down", "Kamera: aşağı", "fixed", "global", KEY_S, KEY_DOWN, true, true)
	_add("cam.left", "Kamera: sola", "fixed", "global", KEY_A, KEY_LEFT, true, true)
	_add("cam.right", "Kamera: sağa", "fixed", "global", KEY_D, KEY_RIGHT, true, true)
	_add("sandbox", "Sandbox paneli (yalnız sandbox)", "fixed", "global", KEY_QUOTELEFT, KEY_F10, true)

static func ensure() -> void:
	if _inited:
		return
	_inited = true
	_build_defs()
	reset_all(false)
	if G.main != null and is_instance_valid(G.main) and G.main.get("cfg") is Dictionary:
		load_dict(G.main.cfg.get("keys", {}))

static func defs() -> Array:
	ensure()
	return _defs

static func has(id: String) -> bool:
	ensure()
	return _idx.has(id)

static func def_of(id: String) -> Dictionary:
	ensure()
	return _idx.get(id, {})

static func binds(id: String) -> Array:
	ensure()
	return _binds.get(id, [0, 0])

# ------------------------------------------------------------ kayıt
static func load_dict(d) -> void:
	ensure()
	if not (d is Dictionary):
		return
	for id in d:
		if not _idx.has(id) or _idx[id]["fixed"]:
			continue
		var arr = d[id]
		if not (arr is Array):
			continue
		var b := [0, 0]
		for i in mini(2, arr.size()):
			b[i] = int(arr[i])
		_binds[id] = b
	version += 1

static func to_dict() -> Dictionary:
	ensure()
	var out := {}
	for a in _defs:
		if a["fixed"]:
			continue
		var b: Array = _binds[a["id"]]
		if b != a["def"]:
			out[a["id"]] = b.duplicate()
	return out

static func save() -> void:
	if G.main != null and is_instance_valid(G.main) and G.main.get("cfg") is Dictionary:
		G.main.cfg["keys"] = to_dict()
		G.main.save_cfg()

static func reset_all(persist := true) -> void:
	for a in _defs:
		_binds[a["id"]] = (a["def"] as Array).duplicate()
	version += 1
	if persist:
		save()

static func set_bind(id: String, slot: int, code: int, persist := true) -> void:
	ensure()
	if not _idx.has(id) or _idx[id]["fixed"]:
		return
	var b: Array = _binds[id]
	b[slot] = code
	# aynı tuş iki yuvada olmasın
	if code != 0 and b[1 - slot] == code:
		b[1 - slot] = 0
	version += 1
	if persist:
		save()

# ------------------------------------------------------------ çakışma
static func _ctx_overlap(a: String, b: String) -> bool:
	return a == b or a == "global" or b == "global"

static func _same_key(a: int, b: int, held: bool) -> bool:
	if a == 0 or b == 0:
		return false
	if held:
		# basılı tutulan sabit tuşlar (kamera) değiştiriciye bakmaz: Ctrl+W de kamerayı kaydırır
		return (a & ~MODS) == (b & ~MODS)
	return a == b

# code tuşunu id eylemine atarsak çakışacak eylemler: [[eylem, yuva], ...]
static func conflicts(id: String, code: int) -> Array:
	ensure()
	var out: Array = []
	if code == 0 or not _idx.has(id):
		return out
	var me: Dictionary = _idx[id]
	for a in _defs:
		if a["id"] == id or not _ctx_overlap(me["ctx"], a["ctx"]):
			continue
		var b: Array = _binds[a["id"]]
		for s in 2:
			if _same_key(b[s], code, a["held"] or me["held"]):
				out.append([a["id"], s])
	return out

# şu an çakışan tüm yuvalar: {"id:yuva": true}
static func all_conflicts() -> Dictionary:
	ensure()
	var out := {}
	for a in _defs:
		var b: Array = _binds[a["id"]]
		for s in 2:
			if b[s] != 0 and not conflicts(a["id"], b[s]).is_empty():
				out["%s:%d" % [a["id"], s]] = true
	return out

# ------------------------------------------------------------ eşleşme
static func event_code(e: InputEventKey) -> int:
	var kc := int(e.keycode)
	if kc == 0:
		kc = int(e.physical_keycode)
	return kc | int(e.get_modifiers_mask())

static func _find(code: int, place_mode: bool) -> String:
	if place_mode:
		for a in _defs:
			if a["ctx"] == "place" and not a["fixed"] and (_binds[a["id"]] as Array).has(code):
				return a["id"]
	for a in _defs:
		if a["fixed"] or a["ctx"] == "place":
			continue
		if (_binds[a["id"]] as Array).has(code):
			return a["id"]
	return ""

# basılan tuşa karşılık gelen eylem ("" = yok). Önce tam eşleşme (değiştiricilerle),
# bulunamazsa Shift/Alt yok sayılır — böylece Shift basılıyken de emir kısayolları çalışır.
static func action_for(e: InputEventKey, place_mode := false) -> String:
	ensure()
	var code := event_code(e)
	var r := _find(code, place_mode)
	if r == "" and (code & LENIENT) != 0:
		r = _find(code & ~LENIENT, place_mode)
	return r

# ------------------------------------------------------------ yazım
const SYMBOLS := {"Semicolon": ";", "Comma": ",", "Period": ".", "Slash": "/", "Backslash": "\\", "Apostrophe": "'",
	"BracketLeft": "[", "BracketRight": "]", "Minus": "-", "Equal": "=", "QuoteLeft": "`"}

static func key_text(code: int) -> String:
	if code == 0:
		return "—"
	var parts := OS.get_keycode_string(code).split("+")
	for i in parts.size():
		parts[i] = SYMBOLS.get(parts[i], parts[i])
	return "+".join(parts).replace("Kp ", "Num ").to_upper()

# emir düğmelerindeki küçük etiket ("DEL", "CTRL+G"...)
static func short_text(code: int) -> String:
	if code == 0:
		return ""
	var s := key_text(code)
	for p in [["DELETE", "DEL"], ["ESCAPE", "ESC"], ["BACKSPACE", "BKSP"], ["ENTER", "ENT"], ["INSERT", "INS"], ["PAGEUP", "PGUP"], ["PAGEDOWN", "PGDN"], ["SPACE", "SPC"], ["CTRL+", "^"], ["SHIFT+", "SH+"], ["ALT+", "ALT "]]:
		s = s.replace(p[0], p[1])
	return s

# eylemin birincil (yoksa ikincil) tuşu
static func label(id: String) -> String:
	var b := binds(id)
	return key_text(b[0] if b[0] != 0 else b[1])

static func short(id: String) -> String:
	var b := binds(id)
	return short_text(b[0] if b[0] != 0 else b[1])
