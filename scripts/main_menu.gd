class_name MainMenu extends Control
# Ana menü: solda başlık + ana girişler (Kampanya, Klasik Harita, Sandbox Test,
# Senaryo Oluşturucu, Ayarlar, Masaüstüne Çık), sağda açılan sayfa paneli. Arka planda
# yapay zekâ savaşı (Main.to_menu) sürer. Ayarlar: Grafik / Ses / Oynanış / Klavye Ayarları
# (tuş atama: Keybinds). Bu dosyadaki yeni metinlerin İngilizcesi EN sözlüğünde —
# ileride I18n.EN'e taşınacak (t() önce burada, sonra I18n'de arar).

const PX := 610.0       # sayfa paneli sol kenarı
const PY := 120.0       # sayfa paneli üst kenarı
const PW := 820.0       # sayfa paneli genişliği
const NAV_W := 400.0
const WEATHERS := ["dynamic", "clear", "rain", "storm", "sandstorm", "snowstorm"]
const DIFF := ["KOLAY", "NORMAL", "ZOR"]
const BIOME := {"desert": "ÇÖL", "green": "ILIMAN", "winter": "KIŞ"}
const SET_TABS := [["graphics", "GRAFİK"], ["audio", "SES"], ["gameplay", "OYNANIŞ"], ["keys", "KLAVYE AYARLARI"]]
# Klavye Ayarları sekmesinin altında: fare değiştiricileri ve editör tuşları (player.gd / editor.gd)
const MOUSE_HELP := [
	"Sol tık: seç · çift tık ya da Ctrl+tık: aynı türü seç · Shift+tık: seçime ekle · Alt+tık: tim yerine tek asker",
	"Sağ tık: emir · Ctrl+sağ tık dost araca: piyade aracın arkasında ilerler · Alt+sağ tık: araç geri vitesle gider",
	"Hedefli emirde Shift+sol tık: emir açık kalır, art arda uygula",
	"Orta tuş sürükle: kamera · Tekerlek: yakınlaştır · Shift basılı: hızlı kaydırma",
	"Senaryo Oluşturucu: R döndür · 1 / 2 / 3 fırça boyutu · Enter çizgiyi bitir · Esc iptal",
]
# planlanan kampanya harekâtları — henüz oynanamaz, kilitli gösterilir
const OPS := [
	{"t": "EĞİTİM: İLK KOMUTA", "map": "", "d": "Seçim, emir, siper ve ikmal hattının temelleri."},
	{"t": "KANAL GEÇİDİ", "map": "desert_canal", "d": "Üç köprüyü ele geçir, ikmal hattını kanalın ötesine taşı."},
	{"t": "VADİ SAVUNMASI", "map": "green_valley", "d": "Taş köprüyü tut, zırhlı karşı taarruzu durdur."},
	{"t": "KIŞ BASKINI", "map": "winter_village", "d": "Kazılı siperlerdeki düşmanı köyden sök."},
	{"t": "ŞEHİR MUHAREBESİ", "map": "big_city", "d": "Nehirle bölünen şehirde sokak sokak ilerle."},
	{"t": "HAVA İNDİRME", "map": "airborne_4k", "d": "Paraşütçü ve helikopter harekâtıyla köprübaşı kur."},
]

# yeni metinler (TR -> EN). I18n.EN'de aynı anahtar varsa bu sözlük önceliklidir.
const EN := {
	"KAMPANYA": "CAMPAIGN",
	"KLASİK HARİTA": "SKIRMISH",
	"SANDBOX TEST": "SANDBOX TEST",
	"SENARYO OLUŞTURUCU": "SCENARIO EDITOR",
	"MASAÜSTÜNE ÇIK": "QUIT TO DESKTOP",
	"HAZIRLANIYOR": "IN PREPARATION",
	"YZ'YE KARŞI": "VS AI",
	"SINIRSIZ İKMAL": "UNLIMITED SUPPLY",
	"HARİTA + SENARYO": "MAP + SCENARIO",
	"ANA MENÜ": "MAIN MENU",
	"GERİ": "BACK",
	"İPTAL": "CANCEL",
	"ÇIK": "QUIT",
	"Oyun kapatılsın mı?": "Close the game?",
	"Seferberlik: birbirine bağlı harekâtlar. Birlikleriniz deneyim kazanır ve görevden göreve taşınır.": "Mobilisation: linked operations. Your units gain experience and carry over from mission to mission.",
	"Kampanya henüz oynanabilir değil. Aşağıdaki harekâtlar planlanıyor ve hazır oldukça açılacak. Şimdilik Klasik Harita ve Sandbox Test oynanabilir.": "The campaign is not playable yet. The operations below are planned and will unlock as they are finished. For now, Skirmish and Sandbox Test are playable.",
	"PLANLANAN HAREKÂTLAR": "PLANNED OPERATIONS",
	"HRK": "OP",
	"Eğitim sahası": "Training ground",
	"EĞİTİM: İLK KOMUTA": "TRAINING: FIRST COMMAND",
	"KANAL GEÇİDİ": "CANAL CROSSING",
	"VADİ SAVUNMASI": "VALLEY DEFENCE",
	"KIŞ BASKINI": "WINTER RAID",
	"ŞEHİR MUHAREBESİ": "URBAN BATTLE",
	"HAVA İNDİRME": "AIRBORNE ASSAULT",
	"Seçim, emir, siper ve ikmal hattının temelleri.": "Basics of selection, orders, cover and supply lines.",
	"Üç köprüyü ele geçir, ikmal hattını kanalın ötesine taşı.": "Seize the three bridges and push the supply line across the canal.",
	"Taş köprüyü tut, zırhlı karşı taarruzu durdur.": "Hold the stone bridge and stop the armoured counter-attack.",
	"Kazılı siperlerdeki düşmanı köyden sök.": "Drive the dug-in enemy out of the village.",
	"Nehirle bölünen şehirde sokak sokak ilerle.": "Advance street by street through the river-split city.",
	"Paraşütçü ve helikopter harekâtıyla köprübaşı kur.": "Seize a bridgehead with paratroopers and helicopters.",
	"KLASİK HARİTAYA GEÇ": "GO TO SKIRMISH",
	"Yapay zekâya karşı çatışma: üs kur, ikmal hattını koru, cepheyi it.": "Battle against the AI: build bases, guard your supply line, push the front.",
	"HARİTA SEÇ": "SELECT MAP",
	"MAÇ AYARLARI": "MATCH SETTINGS",
	"BRİFİNG": "BRIEFING",
	"ÖZEL": "CUSTOM",
	"SAVAŞA BAŞLA": "START BATTLE",
	"ILIMAN": "TEMPERATE",
	"Kayıtlı özel harita": "Saved custom map",
	"NASIL KULLANILIR": "HOW TO USE",
	"` / F10: sandbox panelini aç / gizle": "` / F10: show / hide the sandbox panel",
	"Panelden birlik, araç ve yapı seç; sol tık: yerleştir · sağ tık: iptal": "Pick units, vehicles and structures from the panel; left click: place · right click: cancel",
	"Kataloğa eklenen her yeni birim ve yapı listede kendiliğinden çıkar": "Every new unit and structure added to the catalogue shows up in the list automatically",
	"SANDBOX'I BAŞLAT": "START SANDBOX",
	"Harita ve senaryo editörü: arazi, yol, nehir, yapı; senaryo modunda birlik, hedef ve brifing.": "Map and scenario editor: terrain, roads, rivers, structures; units, objectives and briefing in scenario mode.",
	"YENİ HARİTA": "NEW MAP",
	"HAZIR HARİTAYI DÜZENLE": "EDIT A BUILT-IN MAP",
	"Değişiklikler hemen uygulanır ve kaydedilir.": "Changes apply immediately and are saved.",
	"GRAFİK": "GRAPHICS",
	"SES": "AUDIO",
	"OYNANIŞ": "GAMEPLAY",
	"KLAVYE AYARLARI": "KEY BINDINGS",
	"GÖRÜNTÜ": "DISPLAY",
	"DİKEY SENKRON (V-SYNC)": "VERTICAL SYNC (V-SYNC)",
	"SES DÜZEYİ": "VOLUME",
	"ANA SES": "MASTER VOLUME",
	"ARAYÜZ VE UYARI SESLERİ": "INTERFACE AND ALERT SOUNDS",
	"OYUN": "GAME",
	"ARAYÜZ": "INTERFACE",
	"MİNİ HARİTA BOYUTU": "MINIMAP SIZE",
	"Tuşa tıklayın, sonra yeni tuşa basın. Sağ tık: tuşu temizle · Esc: vazgeç.": "Click a key, then press the new key. Right click: clear key · Esc: cancel.",
	"VARSAYILANLARA DÖN": "RESET TO DEFAULTS",
	"EMİN MİSİNİZ? TEKRAR TIKLAYIN": "ARE YOU SURE? CLICK AGAIN",
	"EYLEM": "ACTION",
	"BİRİNCİL": "PRIMARY",
	"İKİNCİL": "SECONDARY",
	"TUŞA BASIN…": "PRESS A KEY…",
	"«%s» zaten şuna atanmış: %s. Üstüne yazılsın mı?": "«%s» is already bound to: %s. Overwrite?",
	"«%s» sabit bir tuş (%s). Başka bir tuş seçin.": "«%s» is a fixed key (%s). Choose another key.",
	"ÜSTÜNE YAZ": "OVERWRITE",
	"Çakışan tuşlar kırmızıyla işaretli: aynı tuş birden çok eyleme atanmış.": "Conflicting keys are marked red: the same key is bound to more than one action.",
	"Tüm tuşlar varsayılana döndü.": "All keys reset to defaults.",
	"«%s» → %s": "«%s» → %s",
	"BİRLİK EMİRLERİ": "UNIT ORDERS",
	"SEÇİM VE KONTROL GRUPLARI": "SELECTION AND CONTROL GROUPS",
	"SABİT TUŞLAR": "FIXED KEYS",
	"Ekrandaki piyadeyi seç": "Select infantry on screen",
	"Ekrandaki araçları seç": "Select vehicles on screen",
	"Grup %d: seç (ikinci basış: kamera)": "Group %d: select (press again: camera)",
	"Grup %d: ata": "Group %d: assign",
	"Karargâha git": "Jump to HQ",
	"Konuşlanmayı bitir (hazır)": "End deployment (ready)",
	"Yapıyı döndür (Shift: ters yön)": "Rotate structure (Shift: reverse)",
	"Duraklat": "Pause",
	"Oyun hızı ×1": "Game speed ×1",
	"Oyun hızı ×2": "Game speed ×2",
	"Oyun hızı ×3": "Game speed ×3",
	"İptal / duraklatma menüsü": "Cancel / pause menu",
	"Kamera: yukarı": "Camera: up",
	"Kamera: aşağı": "Camera: down",
	"Kamera: sola": "Camera: left",
	"Kamera: sağa": "Camera: right",
	"Sandbox paneli (yalnız sandbox)": "Sandbox panel (sandbox only)",
	"sabit": "fixed",
	"FARE VE EDİTÖR (SABİT)": "MOUSE AND EDITOR (FIXED)",
	"Sol tık: seç · çift tık ya da Ctrl+tık: aynı türü seç · Shift+tık: seçime ekle · Alt+tık: tim yerine tek asker": "Left click: select · double click or Ctrl+click: select same type · Shift+click: add to selection · Alt+click: single soldier instead of squad",
	"Sağ tık: emir · Ctrl+sağ tık dost araca: piyade aracın arkasında ilerler · Alt+sağ tık: araç geri vitesle gider": "Right click: order · Ctrl+right click a friendly vehicle: infantry advance behind it · Alt+right click: vehicles reverse",
	"Hedefli emirde Shift+sol tık: emir açık kalır, art arda uygula": "Targeted orders with Shift+left click: the order stays active for repeated use",
	"Orta tuş sürükle: kamera · Tekerlek: yakınlaştır · Shift basılı: hızlı kaydırma": "Middle-drag: camera · Wheel: zoom · Hold Shift: fast scrolling",
	"Senaryo Oluşturucu: R döndür · 1 / 2 / 3 fırça boyutu · Enter çizgiyi bitir · Esc iptal": "Scenario editor: R rotate · 1 / 2 / 3 brush size · Enter finish line · Esc cancel",
	"Modern savaş · gerçek siper · ikmal hatları": "Modern war · real cover · supply lines",
	"FPS sınırı": "FPS cap",
	"Sınırsız": "Unlimited",
	"Kalite": "Quality",
	"Ön ayar": "Preset",
	"Düşük": "Low",
	"Orta": "Medium",
	"Yüksek": "High",
	"Özel": "Custom",
	"Kapalı": "Off",
	"Çizim çözünürlüğü": "Render resolution",
	"En büyük etki. %100 altında FSR ile ölçeklenir.": "Biggest impact. Below 100% it is upscaled with FSR.",
	"Kenar yumuşatma": "Anti-aliasing",
	"Gölgeler": "Shadows",
	"Büyük etki: gölge haritası boyu ve yumuşatma süzgeci.": "High impact: shadow map size and soft filter.",
	"Ortam gölgelemesi (SSAO)": "Ambient occlusion (SSAO)",
	"Parlama": "Glow",
	"Ot yoğunluğu": "Grass density",
	"Yeni yüklenen bölgelerde ve yeni haritada geçerli.": "Applies to newly loaded areas and the next map.",
}

static var _reopen := ""            # dil değişince yeniden kurulan menü bu sayfayı açar
static var _set_tab := "graphics"
static var _sel_map := ""

var hud: Hud
var page := ""
var _nav := {}
var _page_box: PanelContainer = null
var _help: Label
var _confirm: Control = null
# klasik / sandbox sayfası
var _map_btns := {}
var _brief: VBoxContainer = null
# tuş atama
var _kb_btns := {}          # "id:yuva" -> Button
var _kb_warn: PanelContainer = null
var _kb_reset: Button = null
var _cap_id := ""
var _cap_slot := 0
var _reset_arm := 0.0

static func t(s: String) -> String:
	if I18n.lang == "tr" or s == "":
		return s
	if EN.has(s):
		return EN[s]
	return I18n.s(s)

# eskiden Türkçe büyük harfe çeviriyordu; eskiz temasında (65/57) metin olduğu gibi kalır, büyük harfli anahtarlar
# Sketch.sc ile cümle düzenine iner
static func up(s: String) -> String:
	return s

# ayarlar dosyasındaki ek seçenekleri uygula (Hud._ready'den; main.gd'ye dokunmadan)
static func apply_cfg() -> void:
	if G.main == null or not (G.main.get("cfg") is Dictionary):
		return
	var cfg: Dictionary = G.main.cfg
	if cfg.has("ui_sfx"):
		Sfx.ui_muted = not bool(cfg["ui_sfx"])
	if cfg.has("vsync") and DisplayServer.get_name() != "headless":
		DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_ENABLED if bool(cfg["vsync"]) else DisplayServer.VSYNC_DISABLED)

func _cfg() -> Dictionary:
	if G.main != null and G.main.get("cfg") is Dictionary:
		return G.main.cfg
	return {}

func _save() -> void:
	if G.main != null and G.main.has_method("save_cfg"):
		G.main.save_cfg()

# ============================================================ iskelet
func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	set_process_input(false)
	# eskiz teması (65/57, inceleme dersi 146): solda tek kâğıt kart — başlık, altı bağlantı, kısa ipucu. Numara,
	# ipucu etiketi, amber çizgi, koyu degrade yok; arkada yapay zekâ savaşı görünür kalır.
	var card := PanelContainer.new()
	card.add_theme_stylebox_override("panel", Sketch.panel(0.95, 30, 51))
	card.position = Vector2(70, PY - 20)
	card.custom_minimum_size = Vector2(NAV_W + 40, 0)
	add_child(card)
	var vb := VBoxContainer.new()
	vb.add_theme_constant_override("separation", 2)
	card.add_child(vb)
	var title := _lbl(vb, "MEVZİ", 92, Sketch.INK, hud.font_b)
	title.text = "MEVZİ"
	_lbl(vb, "Modern savaş · gerçek siper · ikmal hatları", 19, Sketch.INK2, hud.font_m)
	var ul := Panel.new()
	ul.add_theme_stylebox_override("panel", Sketch.underline("red"))
	ul.custom_minimum_size = Vector2(150, 16)
	ul.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	ul.mouse_filter = Control.MOUSE_FILTER_IGNORE
	vb.add_child(ul)
	_gap(vb, 22)
	_nav_btn(vb, "classic", 1, "KLASİK HARİTA", "")
	_nav_btn(vb, "campaign", 2, "KAMPANYA", "HAZIRLANIYOR")
	_nav_btn(vb, "sandbox", 3, "SANDBOX TEST", "")
	_nav_btn(vb, "editor", 4, "SENARYO OLUŞTURUCU", "")
	_nav_btn(vb, "settings", 5, "AYARLAR", "")
	_gap(vb, 10)
	_nav_btn(vb, "quit", 6, "MASAÜSTÜNE ÇIK", "")
	_gap(vb, 18)
	_help = _lbl(vb, "Sol tık seç · Sağ tık emir ver · Askerler kendi siperlerini bulur, yaralıları kurtarır.\nÜs kur, yolu koru: ikmal kamyonları ileri üslere ulaşmazsa gelir kesilir.", 14, Sketch.INK2, hud.font_m)
	_help.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_help.custom_minimum_size = Vector2(NAV_W, 0)
	var cr := _lbl(vb, "", 12, Sketch.INK3, hud.font_m)
	cr.text = "v0.2"
	if _reopen != "":
		var p := _reopen
		_reopen = ""
		open_page(p)

func _process(dt: float) -> void:
	if _reset_arm > 0.0:
		_reset_arm -= dt
		if _reset_arm <= 0.0 and is_instance_valid(_kb_reset):
			_kb_reset.text = t("VARSAYILANLARA DÖN")

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo and (e as InputEventKey).keycode == KEY_ESCAPE:
		if _confirm != null:
			_close_confirm()
		elif page != "":
			open_page("")
		else:
			return
		get_viewport().set_input_as_handled()

# ------------------------------------------------------------ yardımcılar
func _lbl(parent: Node, text: String, size := 17, col := Sketch.INK, f: Font = null, wrap := false) -> Label:
	var l := Label.new()
	l.text = Sketch.sc(t(text))
	l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	l.add_theme_font_size_override("font_size", size)
	l.add_theme_color_override("font_color", col)
	l.add_theme_font_override("font", f if f != null else hud.font_m)
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	if wrap:
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		l.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(l)
	return l

func _btn(parent: Node, text: String, cb: Callable, fsize := 18, minw := 0.0, h := 38.0) -> Button:
	var b := Button.new()
	b.text = Sketch.sc(t(text))
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.focus_mode = Control.FOCUS_NONE
	b.add_theme_font_override("font", hud.font_m)
	b.add_theme_font_size_override("font_size", fsize)
	b.custom_minimum_size = Vector2(minw, h)
	b.pressed.connect(func():
		Sfx.play2d("ui_click", -4.0)
		cb.call())
	parent.add_child(b)
	return b

func _sb(bg: Color, border: Color, bw := 1, m := -1.0) -> StyleBoxFlat:
	var s := hud._sb(bg, border, bw)
	if m >= 0.0:
		s.set_content_margin_all(m)
	return s

# kâğıt şerit (kutu, satır, brifing)
func _slip(m := 12.0, seed := 7) -> StyleBoxTexture:
	var s := Sketch.slip(0.9, int(m), seed)
	s.content_margin_top = m * 0.8
	s.content_margin_bottom = m * 0.8
	return s

# ana eylem düğmesi: mürekkep dolgu, kâğıt yazı; üzerinde kırmızı kalem
func _primary(b: Button) -> void:
	var n := Sketch.button("pressed", 22)
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", n)
	b.add_theme_stylebox_override("pressed", n)
	b.add_theme_stylebox_override("hover_pressed", n)
	b.add_theme_font_override("font", hud.font_b)
	for c in ["font_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, Sketch.PAPER)
	b.add_theme_color_override("font_hover_color", Color(0.95, 0.62, 0.5))

func _gap(parent: Node, h: float) -> void:
	var c := Control.new()
	c.custom_minimum_size = Vector2(0, h)
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)

func _hline(parent: Node, col := Color(0.13, 0.12, 0.1, 0.22)) -> void:
	var r := ColorRect.new()
	r.color = col
	r.custom_minimum_size = Vector2(0, 1)
	r.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(r)

func _expand(parent: Node) -> Control:
	var c := Control.new()
	c.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	c.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(c)
	return c

func _margin(parent: Node, l: int, tp: int, r: int, b: int) -> MarginContainer:
	var m := MarginContainer.new()
	m.add_theme_constant_override("margin_left", l)
	m.add_theme_constant_override("margin_top", tp)
	m.add_theme_constant_override("margin_right", r)
	m.add_theme_constant_override("margin_bottom", b)
	parent.add_child(m)
	return m

# bölüm başlığı: mürekkep yazı, altında ince çizgi
func _caption(parent: Node, text: String) -> void:
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 1)
	parent.add_child(v)
	_lbl(v, text, 17, Sketch.INK, hud.font_b)
	_hline(v)

func _scroll(parent: Node) -> VBoxContainer:
	var sc := ScrollContainer.new()
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	parent.add_child(sc)
	var v := VBoxContainer.new()
	v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_theme_constant_override("separation", 4)
	sc.add_child(v)
	return v

static func map_size_tag(id: String) -> String:
	var s := int(MapGen.MAPS.get(id, {}).get("size", 256))
	return ("%d KM" % (s / 1024)) if s >= 1024 else ("%d M" % s)

static func map_title(id: String) -> String:
	return up(I18n.s(String(MapGen.MAPS[id]["title"])))

# ------------------------------------------------------------ sol menü
func _nav_btn(parent: Node, id: String, _idx: int, text: String, hint: String) -> void:
	var b := Button.new()
	b.text = Sketch.sc(t(text))
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.custom_minimum_size = Vector2(NAV_W, 44)
	b.add_theme_font_size_override("font_size", 26 if id != "quit" else 20)
	b.add_theme_font_override("font", hud.font_m)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.focus_mode = Control.FOCUS_NONE
	b.toggle_mode = id != "quit"
	# düz mürekkep yazı; üzerinde kırmızı kalem alt çizgi, açık sayfada mürekkep alt çizgi
	var none := StyleBoxEmpty.new()
	none.content_margin_left = 2
	none.content_margin_bottom = 6
	var red := Sketch.underline("red", 0)
	red.content_margin_left = 2
	red.content_margin_bottom = 6
	var ink := Sketch.underline("ink", 0)
	ink.content_margin_left = 2
	ink.content_margin_bottom = 6
	b.add_theme_stylebox_override("normal", none)
	b.add_theme_stylebox_override("hover", red)
	b.add_theme_stylebox_override("pressed", ink)
	b.add_theme_stylebox_override("hover_pressed", ink)
	var fc := Sketch.INK2 if id == "quit" else Sketch.INK
	for c in ["font_color", "font_pressed_color", "font_hover_pressed_color"]:
		b.add_theme_color_override(c, fc)
	b.add_theme_color_override("font_hover_color", Sketch.RED)
	if hint != "":
		var hl := _lbl(b, hint, 14, Sketch.INK3, hud.font_m)
		hl.text = Sketch.sc(t(hint))
		hl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		hl.anchor_left = 1.0
		hl.anchor_right = 1.0
		hl.offset_left = -200
		hl.offset_right = -4
		hl.offset_top = 14
	b.pressed.connect(func():
		Sfx.play2d("ui_click", -4.0)
		if id == "quit":
			confirm_quit()
		else:
			open_page("" if page == id else id))
	parent.add_child(b)
	_nav[id] = b

func _nav_sep(parent: Node) -> void:
	_gap(parent, 4)
	var r := ColorRect.new()
	r.color = Color(0.13, 0.12, 0.1, 0.18)
	r.custom_minimum_size = Vector2(NAV_W, 1)
	r.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	parent.add_child(r)
	_gap(parent, 4)

# ------------------------------------------------------------ sayfalar
func open_page(id: String) -> void:
	_cap_cancel()
	if _page_box != null and is_instance_valid(_page_box):
		_page_box.queue_free()
	_page_box = null
	_brief = null
	_map_btns.clear()
	_kb_btns.clear()
	_kb_warn = null
	page = id
	for k in _nav:
		var nb: Button = _nav[k]
		if nb.toggle_mode:
			nb.set_pressed_no_signal(k == id)
			nb.toggled.emit(k == id)
	_help.visible = id == ""
	hud.tooltip.visible = false
	match id:
		"campaign":
			_page_campaign()
		"classic":
			_page_classic()
		"sandbox":
			_page_sandbox()
		"editor":
			_page_editor()
		"settings":
			_page_settings()

# başlık + gövde + alt şerit; {"body": VBox, "foot": HBox}
func _frame(_idx: int, title: String, sub: String) -> Dictionary:
	var pc := PanelContainer.new()
	var psb := Sketch.panel(0.97, 0, 53)
	psb.content_margin_left = 8
	psb.content_margin_right = 8
	psb.content_margin_top = 8
	psb.content_margin_bottom = 8
	pc.add_theme_stylebox_override("panel", psb)
	pc.anchor_bottom = 1.0
	pc.offset_left = PX
	pc.offset_top = PY
	pc.offset_right = PX + PW
	pc.offset_bottom = -64
	add_child(pc)
	if _confirm != null:
		move_child(_confirm, -1)
	_page_box = pc
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var hm := _margin(v, 26, 14, 26, 14)
	var hv := VBoxContainer.new()
	hv.add_theme_constant_override("separation", 0)
	hm.add_child(hv)
	_lbl(hv, title, 36, Sketch.INK, hud.font_b)
	if sub != "":
		_lbl(hv, sub, 16, Sketch.INK2, hud.font_m, true)
	_hline(v)
	var bm := _margin(v, 26, 18, 26, 14)
	bm.size_flags_vertical = Control.SIZE_EXPAND_FILL
	var body := VBoxContainer.new()
	body.add_theme_constant_override("separation", 10)
	bm.add_child(body)
	_hline(v)
	var fm := _margin(v, 26, 12, 26, 14)
	var fh := HBoxContainer.new()
	fh.add_theme_constant_override("separation", 10)
	fm.add_child(fh)
	var back := _btn(fh, "", func(): open_page(""), 19, 140, 44)
	back.text = "‹  " + Sketch.sc(t("GERİ"))
	_expand(fh)
	return {"body": body, "foot": fh}

# ---------------- kampanya
func _page_campaign() -> void:
	var f := _frame(1, "KAMPANYA", "Seferberlik: birbirine bağlı harekâtlar. Birlikleriniz deneyim kazanır ve görevden göreve taşınır.")
	var body: VBoxContainer = f["body"]
	var st := PanelContainer.new()
	var ssb := _slip(14.0, 61)
	st.add_theme_stylebox_override("panel", ssb)
	body.add_child(st)
	var sh := HBoxContainer.new()
	sh.add_theme_constant_override("separation", 14)
	st.add_child(sh)
	var lk := LockIcon.new()
	lk.custom_minimum_size = Vector2(22, 26)
	lk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sh.add_child(lk)
	var sv := VBoxContainer.new()
	sv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sv.add_theme_constant_override("separation", 2)
	sh.add_child(sv)
	_lbl(sv, "HAZIRLANIYOR", 22, Sketch.RED, hud.font_b)
	_lbl(sv, "Kampanya henüz oynanabilir değil. Aşağıdaki harekâtlar planlanıyor ve hazır oldukça açılacak. Şimdilik Klasik Harita ve Sandbox Test oynanabilir.", 16, Sketch.INK, hud.font_m, true)
	_gap(body, 4)
	_caption(body, "PLANLANAN HAREKÂTLAR")
	var list := _scroll(body)
	list.add_theme_constant_override("separation", 6)
	for i in OPS.size():
		var op: Dictionary = OPS[i]
		var row := PanelContainer.new()
		row.add_theme_stylebox_override("panel", _slip(12.0, 70 + i))
		list.add_child(row)
		var h := HBoxContainer.new()
		h.add_theme_constant_override("separation", 16)
		row.add_child(h)
		var code := _lbl(h, "", 17, Sketch.INK3, hud.font_b)
		code.text = "%s-%02d" % [t("HRK"), i]
		code.custom_minimum_size = Vector2(70, 0)
		code.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		var v := VBoxContainer.new()
		v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		v.add_theme_constant_override("separation", 0)
		h.add_child(v)
		_lbl(v, String(op["t"]), 22, Sketch.INK2, hud.font_b)
		var where := t("Eğitim sahası")
		var mid: String = op["map"]
		if MapGen.MAPS.has(mid):
			where = map_title(mid) + "  ·  " + map_size_tag(mid)
		var dl := _lbl(v, "", 15, Sketch.INK2, hud.font_m, true)
		dl.text = where + "  —  " + t(String(op["d"]))
		var tag := HBoxContainer.new()
		tag.add_theme_constant_override("separation", 6)
		tag.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(tag)
		var lk2 := LockIcon.new()
		lk2.custom_minimum_size = Vector2(12, 15)
		lk2.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		lk2.col = Sketch.RED
		tag.add_child(lk2)
		_lbl(tag, "HAZIRLANIYOR", 14, Sketch.RED, hud.font_b)
	var go := _btn(f["foot"], "", func(): open_page("classic"), 19, 0, 44)
	go.text = t("KLASİK HARİTAYA GEÇ") + "  ›"

# ---------------- klasik harita + sandbox: ortak harita listesi
func _map_list(parent: Node, with_custom: bool) -> void:
	var col := VBoxContainer.new()
	col.custom_minimum_size = Vector2(390, 0)
	col.add_theme_constant_override("separation", 8)
	parent.add_child(col)
	_caption(col, "HARİTA SEÇ")
	var list := _scroll(col)
	var ids: Array = MapGen.MAPS.keys()
	if not MapGen.MAPS.has(_sel_map) and not (with_custom and _sel_map.begins_with("custom:")):
		_sel_map = ids[0]
	for id in ids:
		var mid: String = id
		var bio := String(MapGen.MAPS[mid].get("biome", "green"))
		_map_row(list, mid, map_title(mid), map_size_tag(mid) + "  ·  " + t(BIOME.get(bio, "")))
	if with_custom:
		var maps := MapEditor.list_maps()
		if not maps.is_empty():
			_gap(list, 6)
			_caption(list, "ÖZEL HARİTALAR")
			for m in maps:
				var mn: String = m
				_map_row(list, "custom:" + mn, mn, t("ÖZEL"))
	elif _sel_map.begins_with("custom:"):
		_sel_map = ids[0]
	_select_map(_sel_map)

func _map_row(list: Node, key: String, title: String, tag: String) -> void:
	var b := Button.new()
	b.text = title
	b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	b.toggle_mode = true
	b.focus_mode = Control.FOCUS_NONE
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT
	b.custom_minimum_size = Vector2(0, 44)
	b.add_theme_font_override("font", hud.font_b)
	b.add_theme_font_size_override("font_size", 20)
	b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var tl := _lbl(b, "", 14, Sketch.INK3, hud.font_b)
	tl.text = tag
	tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	tl.anchor_left = 1.0
	tl.anchor_right = 1.0
	tl.offset_left = -170
	tl.offset_right = -12
	tl.offset_top = 13
	b.pressed.connect(func():
		Sfx.play2d("ui_click", -6.0)
		_select_map(key))
	list.add_child(b)
	_map_btns[key] = b

func _select_map(key: String) -> void:
	_sel_map = key
	for k in _map_btns:
		(_map_btns[k] as Button).set_pressed_no_signal(k == key)
	_fill_brief()

func _fill_brief() -> void:
	if _brief == null or not is_instance_valid(_brief):
		return
	for c in _brief.get_children():
		c.queue_free()
	if _sel_map.begins_with("custom:"):
		_lbl(_brief, _sel_map.substr(7), 26, Sketch.INK, hud.font_b)
		_lbl(_brief, "Kayıtlı özel harita", 15, Sketch.INK2, hud.font_m, true)
	elif MapGen.MAPS.has(_sel_map):
		var m: Dictionary = MapGen.MAPS[_sel_map]
		_lbl(_brief, map_title(_sel_map), 26, Sketch.INK, hud.font_b)
		var tg := _lbl(_brief, "", 14, Sketch.RED, hud.font_b)
		tg.text = map_size_tag(_sel_map) + "  ·  " + t(BIOME.get(String(m.get("biome", "green")), ""))
		_lbl(_brief, String(m.get("desc", "")), 16, Sketch.INK, hud.font_m, true)

func _start_selected(sandbox: bool) -> void:
	if G.main == null or not G.main.has_method("start_game"):
		return
	if _sel_map.begins_with("custom:"):
		G.main.start_game("", MapEditor.load_map(_sel_map.substr(7)))
	else:
		G.main.start_game(_sel_map, {}, sandbox)

# ---------------- klasik harita
func _page_classic() -> void:
	var f := _frame(2, "KLASİK HARİTA", "Yapay zekâya karşı çatışma: üs kur, ikmal hattını koru, cepheyi it.")
	var body: VBoxContainer = f["body"]
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 22)
	body.add_child(h)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	_map_list(h, true)
	h.add_child(right)
	_caption(right, "MAÇ AYARLARI")
	# açıklama etiketleri seçicilerden sonra kurulur; lambdalar onlara sözlükten erişir
	var refs := {}
	var modes: Array = Modes.MODE_NAME.keys()
	# mevcut ipucu metni "Klasik: ... · Fetih: ... · Savaş Hedefleri: ..." — kip başına parçası gösterilir
	var mode_parts := I18n.s("Klasik: üsleri yok et · Fetih: bölge tut, puan topla · Savaş Hedefleri: 3 aşama, bölge + imha puanı").split(" · ")
	var mode_txt := func(i: int) -> String:
		return mode_parts[i] if mode_parts.size() == modes.size() else ""
	var set_mode := func(i: int) -> void:
		G.mode = modes[i]
		if refs.has("mode"):
			(refs["mode"] as Label).text = mode_txt.call(i)
	_selector(right, "MOD", modes.size(), func(): return maxi(0, modes.find(G.mode)), set_mode,
		func(i): return I18n.s(Modes.MODE_NAME[modes[i]]))
	refs["mode"] = _lbl(right, "", 14, Sketch.INK2, hud.font_m, true)
	(refs["mode"] as Label).text = mode_txt.call(maxi(0, modes.find(G.mode)))
	var set_weather := func(i: int) -> void:
		G.weather_pref = WEATHERS[i]
		if refs.has("weather"):
			(refs["weather"] as Label).visible = G.weather_pref == "dynamic"
	_selector(right, "HAVA DURUMU", WEATHERS.size(), func(): return maxi(0, WEATHERS.find(G.weather_pref)), set_weather,
		func(i): return I18n.s(Weather.NAME[WEATHERS[i]]))
	refs["weather"] = _lbl(right, "Değişken: biyoma göre hava 3-4 dakikada bir değişir", 14, Sketch.INK2, hud.font_m, true)
	(refs["weather"] as Label).visible = G.weather_pref == "dynamic"
	var set_night := func(i: int) -> void:
		G.night_pref = i == 1
	_selector(right, "GECE", 2, func(): return 1 if G.night_pref else 0, set_night, _onoff)
	_selector(right, "ZORLUK", 3, func(): return G.difficulty, _set_diff, func(i): return I18n.s(DIFF[i]))
	_gap(right, 10)
	_caption(right, "BRİFİNG")
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", _slip(14.0, 62))
	right.add_child(bp)
	_brief = VBoxContainer.new()
	_brief.add_theme_constant_override("separation", 4)
	bp.add_child(_brief)
	_fill_brief()
	var go := _btn(f["foot"], "SAVAŞA BAŞLA", func(): _start_selected(false), 22, 230, 44)
	_primary(go)

# ‹ değer › seçici; değer düğmesine tık da ileri alır
func _selector(parent: Node, caption: String, count: int, get_i: Callable, set_i: Callable, name_of: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 4)
	parent.add_child(h)
	if parent.get_meta("wide_caption", false):
		h.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		h.custom_minimum_size = Vector2(640, 0)
	var cl := _lbl(h, caption, 17, Sketch.INK2, hud.font_b)
	cl.custom_minimum_size = Vector2(250 if parent.get_meta("wide_caption", false) else 150, 0)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var val := Button.new()
	var refresh := func() -> void:
		val.text = Sketch.sc(String(name_of.call(int(get_i.call()))))
	var step := func(d: int) -> void:
		set_i.call(posmod(int(get_i.call()) + d, count))
		refresh.call()
	var prev := _btn(h, "", func(): step.call(-1), 22, 36, 36)
	prev.text = "‹"
	val.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	val.focus_mode = Control.FOCUS_NONE
	val.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	val.custom_minimum_size = Vector2(0, 36)
	val.add_theme_font_override("font", hud.font_b)
	val.add_theme_font_size_override("font_size", 18)
	h.add_child(val)
	var nxt := _btn(h, "", func(): step.call(1), 22, 36, 36)
	nxt.text = "›"
	val.pressed.connect(func():
		Sfx.play2d("ui_click", -4.0)
		step.call(1))
	refresh.call()

func _slider(parent: Node, caption: String, lo: float, hi: float, stp: float, value: float, fmt: Callable, on_change: Callable) -> void:
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 12)
	parent.add_child(h)
	h.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
	h.custom_minimum_size = Vector2(640, 0)
	var cl := _lbl(h, caption, 17, Sketch.INK2, hud.font_b)
	cl.custom_minimum_size = Vector2(230, 0)
	cl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	var sl := HSlider.new()
	sl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	sl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	sl.custom_minimum_size = Vector2(0, 30)
	sl.min_value = lo
	sl.max_value = hi
	sl.step = stp
	sl.focus_mode = Control.FOCUS_NONE
	var track := StyleBoxFlat.new()
	track.bg_color = Color(0.13, 0.12, 0.1, 0.2)
	track.content_margin_top = 2
	track.content_margin_bottom = 2
	var fill := StyleBoxFlat.new()
	fill.bg_color = Sketch.RED
	fill.content_margin_top = 2
	fill.content_margin_bottom = 2
	sl.add_theme_stylebox_override("slider", track)
	sl.add_theme_stylebox_override("grabber_area", fill)
	sl.add_theme_stylebox_override("grabber_area_highlight", fill)
	h.add_child(sl)
	var vl := _lbl(h, "", 17, Sketch.INK, hud.font_b)
	vl.custom_minimum_size = Vector2(64, 0)
	vl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	sl.value = value
	vl.text = String(fmt.call(value))
	sl.value_changed.connect(func(x):
		vl.text = String(fmt.call(x))
		on_change.call(x))

# ---------------- sandbox
func _page_sandbox() -> void:
	var f := _frame(3, "SANDBOX TEST", "Sınırsız ikmal, birlik sınırı yok, geliştirici komutları.")
	var body: VBoxContainer = f["body"]
	var h := HBoxContainer.new()
	h.size_flags_vertical = Control.SIZE_EXPAND_FILL
	h.add_theme_constant_override("separation", 22)
	body.add_child(h)
	_map_list(h, false)
	var right := VBoxContainer.new()
	right.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	right.add_theme_constant_override("separation", 6)
	h.add_child(right)
	_caption(right, "BRİFİNG")
	var bp := PanelContainer.new()
	bp.add_theme_stylebox_override("panel", _slip(14.0, 62))
	right.add_child(bp)
	_brief = VBoxContainer.new()
	_brief.add_theme_constant_override("separation", 4)
	bp.add_child(_brief)
	_fill_brief()
	_gap(right, 10)
	_caption(right, "NASIL KULLANILIR")
	for s in ["` / F10: sandbox panelini aç / gizle", "Panelden birlik, araç ve yapı seç; sol tık: yerleştir · sağ tık: iptal", "Kataloğa eklenen her yeni birim ve yapı listede kendiliğinden çıkar"]:
		var l := _lbl(right, "", 15, Sketch.INK2, hud.font_m, true)
		l.text = "•  " + t(s)
	var go := _btn(f["foot"], "SANDBOX'I BAŞLAT", func(): _start_selected(true), 22, 230, 44)
	_primary(go)

# ---------------- senaryo oluşturucu (harita + senaryo editörü)
func _page_editor() -> void:
	var f := _frame(4, "SENARYO OLUŞTURUCU", "Harita ve senaryo editörü: arazi, yol, nehir, yapı; senaryo modunda birlik, hedef ve brifing.")
	var body := _scroll(f["body"])
	body.add_theme_constant_override("separation", 8)
	_caption(body, "YENİ HARİTA")
	var nh := HBoxContainer.new()
	nh.add_theme_constant_override("separation", 8)
	body.add_child(nh)
	for p in [["BOŞ ÇÖL HARİTASI", "desert"], ["BOŞ YEŞİL HARİTA", "green"], ["BOŞ KIŞ HARİTASI", "winter"]]:
		var bio: String = p[1]
		var b := _btn(nh, p[0], func(): G.main.new_map(bio), 18, 0, 44)
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_gap(body, 8)
	_caption(body, "HAZIR HARİTAYI DÜZENLE")
	var gr := GridContainer.new()
	gr.columns = 2
	gr.add_theme_constant_override("h_separation", 8)
	gr.add_theme_constant_override("v_separation", 6)
	body.add_child(gr)
	for id in MapGen.MAPS:
		var mid: String = id
		var b := _btn(gr, "", func(): G.main.open_editor_from_builtin(mid), 18, 0, 42)
		b.text = map_title(mid)
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		var tl := _lbl(b, "", 13, Sketch.INK3, hud.font_b)
		tl.text = map_size_tag(mid)
		tl.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
		tl.anchor_left = 1.0
		tl.anchor_right = 1.0
		tl.offset_left = -80
		tl.offset_right = -10
		tl.offset_top = 12
	_gap(body, 8)
	_caption(body, "KAYITLI HARİTALAR")
	var maps := MapEditor.list_maps()
	if maps.is_empty():
		_lbl(body, "Henüz kayıt yok", 15, Sketch.INK2, hud.font_m)
	for m in maps:
		var mn: String = m
		var b := _btn(body, "", func(): G.main.open_editor(MapEditor.load_map(mn)), 18, 0, 40)
		b.text = I18n.s("AÇ: ") + mn
		b.alignment = HORIZONTAL_ALIGNMENT_LEFT

# ---------------- ayarlar
func _page_settings() -> void:
	var f := _frame(5, "AYARLAR", "Değişiklikler hemen uygulanır ve kaydedilir.")
	var body: VBoxContainer = f["body"]
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 6)
	body.add_child(tabs)
	var content := VBoxContainer.new()
	content.size_flags_vertical = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 8)
	var tbtns := {}
	for tt in SET_TABS:
		var tid: String = tt[0]
		var b := _btn(tabs, tt[1], func(): pass, 18, 0, 40)
		b.toggle_mode = true
		b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tbtns[tid] = b
		b.pressed.connect(func():
			_set_tab = tid
			for k in tbtns:
				(tbtns[k] as Button).set_pressed_no_signal(k == tid)
			_fill_settings(content))
	(tbtns.get(_set_tab, tbtns["graphics"]) as Button).set_pressed_no_signal(true)
	_hline(body)
	body.add_child(content)
	_fill_settings(content)

func open_settings_tab(tid: String) -> void:
	_set_tab = tid
	open_page("settings")

func _fill_settings(content: VBoxContainer) -> void:
	_cap_cancel()
	_kb_btns.clear()
	_kb_warn = null
	for c in content.get_children():
		content.remove_child(c)
		c.queue_free()
	content.set_meta("wide_caption", true)
	match _set_tab:
		"graphics":
			_fill_graphics(content)
		"audio":
			_caption(content, "SES DÜZEYİ")
			var set_vol := func(x: float) -> void:
				Sfx.set_volume(x)
				_save()
			_slider(content, "ANA SES", 0.0, 1.0, 0.05, Sfx.volume, func(x): return "%d%%" % int(round(x * 100.0)), set_vol)
			var set_ui := func(i: int) -> void:
				Sfx.ui_muted = i == 0
				var cf := _cfg()
				cf["ui_sfx"] = i == 1
				_save()
			_selector(content, "ARAYÜZ VE UYARI SESLERİ", 2, func(): return 0 if Sfx.ui_muted else 1, set_ui, _onoff)
		"gameplay":
			_caption(content, "OYUN")
			_selector(content, "ZORLUK", 3, func(): return G.difficulty, _set_diff, func(i): return I18n.s(DIFF[i]))
			_selector(content, "DİL", 2, func(): return 1 if I18n.lang == "en" else 0,
				func(i): _set_lang("en" if i == 1 else "tr"), func(i): return ["TÜRKÇE", "ENGLISH"][i])
			_toggle(content, up(t("Kenar kaydırma")), "edge_scroll", true, true)
			_gap(content, 8)
			_caption(content, "ARAYÜZ")
			var set_mini := func(x: float) -> void:
				Hud.mini_scale = x
				var cf := _cfg()
				cf["minimap"] = x
				if hud.radar != null:
					hud.apply_mini_size()
					hud.radar.tex = null
				_save()
			_slider(content, "MİNİ HARİTA BOYUTU", 0.8, 2.0, 0.05, Hud.mini_scale, func(x): return "×%.2f" % x, set_mini)
		"keys":
			_keys_tab(content)

# Grafik sekmesi (roadmap 146): ön ayar + her biri ölçülebilir başarım farkı yaratan ayarlar; yanında etkisi
func _fill_graphics(root_box: VBoxContainer) -> void:
	var m = G.main
	if m == null or not m.has_method("gfx"):
		return
	var refill := func() -> void:
		_fill_settings.call_deferred(root_box)
	var content := _scroll(root_box)
	content.set_meta("wide_caption", true)
	content.add_theme_constant_override("separation", 8)
	_caption(content, "GÖRÜNTÜ")
	_toggle(content, t("Tam ekran"), "fullscreen", true, true)
	var set_vsync := func(i: int) -> void:
		var cf := _cfg()
		cf["vsync"] = i == 1
		apply_cfg()
		_save()
	_selector(content, "DİKEY SENKRON (V-SYNC)", 2, func(): return 1 if bool(_cfg().get("vsync", true)) else 0, set_vsync, _onoff)
	var caps := [0, 30, 60, 120, 144]
	_selector(content, "FPS sınırı", caps.size(), func(): return maxi(0, caps.find(int(m.gfx("fps_cap")))),
		func(i): m.set_gfx("fps_cap", caps[i]),
		func(i): return t("Sınırsız") if caps[i] == 0 else str(caps[i]))
	_gap(content, 8)
	_caption(content, "Kalite")
	var set_preset := func(i: int) -> void:
		if i < 3:
			m.set_gfx_preset(i)
		refill.call()
	_selector(content, "Ön ayar", 4, func(): return clampi(int(_cfg().get("gfx", 2)), 0, 3), set_preset,
		func(i): return t(["Düşük", "Orta", "Yüksek", "Özel"][i]))
	var pct := func(x: float) -> String:
		return "%d%%" % int(round(x * 100.0))
	var set_scale := func(x: float) -> void:
		m.set_gfx("scale", x)
	_slider(content, "Çizim çözünürlüğü", 0.5, 1.0, 0.05, float(m.gfx("scale")), pct, set_scale)
	_hint(content, "En büyük etki. %100 altında FSR ile ölçeklenir.")
	var set_msaa := func(i: int) -> void:
		m.set_gfx("msaa", i)
		refill.call()
	_selector(content, "Kenar yumuşatma", 3, func(): return clampi(int(m.gfx("msaa")), 0, 2), set_msaa,
		func(i): return t(["Kapalı", "MSAA 2×", "MSAA 4×"][i]))
	var set_sh := func(i: int) -> void:
		m.set_gfx("shadow_q", i)
		refill.call()
	_selector(content, "Gölgeler", 4, func(): return clampi(int(m.gfx("shadow_q")), 0, 3), set_sh,
		func(i): return t(["Kapalı", "Düşük", "Orta", "Yüksek"][i]))
	_hint(content, "Büyük etki: gölge haritası boyu ve yumuşatma süzgeci.")
	var set_ao := func(i: int) -> void:
		m.set_gfx("ssao", i == 1)
		refill.call()
	_selector(content, "Ortam gölgelemesi (SSAO)", 2, func(): return 1 if bool(m.gfx("ssao")) else 0, set_ao, _onoff)
	var set_glow := func(i: int) -> void:
		m.set_gfx("glow", i == 1)
		refill.call()
	_selector(content, "Parlama", 2, func(): return 1 if bool(m.gfx("glow")) else 0, set_glow, _onoff)
	var set_grass := func(x: float) -> void:
		m.set_gfx("grass", x)
	_slider(content, "Ot yoğunluğu", 0.1, 1.0, 0.05, float(m.gfx("grass")), pct, set_grass)
	_hint(content, "Yeni yüklenen bölgelerde ve yeni haritada geçerli.")

func _hint(parent: Node, text: String) -> void:
	var h := HBoxContainer.new()
	parent.add_child(h)
	var sp := Control.new()
	sp.custom_minimum_size = Vector2(254, 0)
	h.add_child(sp)
	_lbl(h, text, 13, Sketch.INK3, hud.font_m)

func _onoff(i: int) -> String:
	return I18n.s(["KAPALI", "AÇIK"][i])

func _set_diff(i: int) -> void:
	G.difficulty = i
	_save()

# cfg'deki açık/kapalı ayar (main.apply_video ile uygulanır)
func _toggle(parent: Node, caption: String, key: String, def: bool, video: bool) -> void:
	var set_v := func(i: int) -> void:
		var cf := _cfg()
		cf[key] = i == 1
		if video and G.main != null and G.main.has_method("apply_video"):
			G.main.apply_video()
		_save()
	_selector(parent, caption, 2, func(): return 1 if bool(_cfg().get(key, def)) else 0, set_v, _onoff)

func _set_lang(l: String) -> void:
	if G.main != null and G.main.has_method("set_lang"):
		G.main.set_lang(l)
	else:
		I18n.setup(l)
	_reopen = "settings"
	hud.show_menu()

# ============================================================ klavye ayarları
func _keys_tab(content: VBoxContainer) -> void:
	var top := HBoxContainer.new()
	top.add_theme_constant_override("separation", 12)
	content.add_child(top)
	var info := _lbl(top, "Tuşa tıklayın, sonra yeni tuşa basın. Sağ tık: tuşu temizle · Esc: vazgeç.", 15, Sketch.INK2, hud.font_m, true)
	info.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	_kb_reset = _btn(top, "VARSAYILANLARA DÖN", func(): _reset_keys(), 16, 0, 36)
	_kb_warn = PanelContainer.new()
	_kb_warn.visible = false
	content.add_child(_kb_warn)
	var hdr := HBoxContainer.new()
	hdr.add_theme_constant_override("separation", 8)
	content.add_child(hdr)
	var hl := _lbl(hdr, "", 13, Sketch.INK3, hud.font_b)
	hl.text = "   " + t("EYLEM")
	hl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	for s in ["BİRİNCİL", "İKİNCİL"]:
		var l := _lbl(hdr, s, 13, Sketch.INK3, hud.font_b)
		l.custom_minimum_size = Vector2(158, 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	var list := _scroll(content)
	list.add_theme_constant_override("separation", 1)
	var n := 0
	for cat in Keybinds.CATS:
		var cid: String = cat[0]
		_gap(list, 6 if n > 0 else 0)
		_caption(list, cat[1])
		_gap(list, 2)
		for d in Keybinds.defs():
			if d["cat"] != cid:
				continue
			_key_row(list, d, n)
			n += 1
	# fare kısayolları ve editör tuşları: bilgi (atanamaz)
	_gap(list, 6)
	_caption(list, "FARE VE EDİTÖR (SABİT)")
	for s in MOUSE_HELP:
		var l := _lbl(list, "", 15, Sketch.INK2, hud.font_m, true)
		l.text = "•  " + t(s)
	_refresh_keys()
	if not Keybinds.all_conflicts().is_empty():
		_warn(t("Çakışan tuşlar kırmızıyla işaretli: aynı tuş birden çok eyleme atanmış."), true)

func act_name(d: Dictionary) -> String:
	var s := t(String(d["t"]))
	if int(d.get("n", -1)) >= 0:
		s = s % int(d["n"])
	return s

func _key_row(list: Node, d: Dictionary, i: int) -> void:
	var row := PanelContainer.new()
	var rsb := StyleBoxFlat.new()
	rsb.bg_color = Color(0.13, 0.12, 0.1, 0.05 if i % 2 == 0 else 0.0)
	rsb.content_margin_left = 10
	rsb.content_margin_right = 6
	rsb.content_margin_top = 2
	rsb.content_margin_bottom = 2
	row.add_theme_stylebox_override("panel", rsb)
	list.add_child(row)
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 8)
	row.add_child(h)
	var fixed: bool = d["fixed"]
	var nl := _lbl(h, "", 17, Sketch.INK2 if fixed else Sketch.INK, hud.font_m)
	nl.text = act_name(d)
	nl.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	nl.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if fixed:
		var lk := LockIcon.new()
		lk.custom_minimum_size = Vector2(11, 14)
		lk.col = Sketch.INK3
		lk.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		h.add_child(lk)
	for slot in 2:
		var id: String = d["id"]
		var sl: int = slot
		var b := Button.new()
		b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(158, 32)
		b.add_theme_font_override("font", hud.font_b)
		b.add_theme_font_size_override("font_size", 16)
		b.disabled = fixed
		b.clip_text = true
		if not fixed:
			b.pressed.connect(func():
				Sfx.play2d("ui_click", -6.0)
				_cap_start(id, sl))
			b.gui_input.connect(func(ev):
				if ev is InputEventMouseButton and ev.pressed and ev.button_index == MOUSE_BUTTON_RIGHT:
					_cap_cancel()
					Keybinds.set_bind(id, sl, 0)
					Sfx.play2d("ui_click", -8.0)
					_after_change())
		h.add_child(b)
		_kb_btns["%s:%d" % [id, sl]] = b

func _key_style(b: Button, mode: String) -> void:
	# mode: "" normal, "cap" tuş bekleniyor, "bad" çakışma, "fixed"
	var fc := Sketch.INK
	var n: StyleBox = Sketch.button("normal", 4)
	var hv: StyleBox = Sketch.button("hover", 4)
	match mode:
		"cap":
			n = Sketch.button("pressed", 4)
			fc = Sketch.PAPER
		"bad":
			var sb := _sb(Color(Sketch.RED.r, Sketch.RED.g, Sketch.RED.b, 0.12), Sketch.RED, 1, 4.0)
			n = sb
			fc = Sketch.RED
		"fixed":
			n = Sketch.button("disabled", 4)
			hv = n
			fc = Sketch.INK3
	b.add_theme_stylebox_override("normal", n)
	b.add_theme_stylebox_override("hover", hv if mode != "cap" else n)
	b.add_theme_stylebox_override("pressed", n)
	b.add_theme_stylebox_override("hover_pressed", n)
	b.add_theme_stylebox_override("disabled", n)
	for c in ["font_color", "font_pressed_color", "font_hover_pressed_color", "font_disabled_color"]:
		b.add_theme_color_override(c, fc)
	b.add_theme_color_override("font_hover_color", Sketch.RED if mode in ["", "bad"] else fc)

func _refresh_keys() -> void:
	var bad := Keybinds.all_conflicts()
	for key in _kb_btns:
		var b: Button = _kb_btns[key]
		if not is_instance_valid(b):
			continue
		var id: String = key.get_slice(":", 0)
		var sl := int(key.get_slice(":", 1))
		var d := Keybinds.def_of(id)
		var code: int = Keybinds.binds(id)[sl]
		if id == _cap_id and sl == _cap_slot:
			b.text = t("TUŞA BASIN…")
			_key_style(b, "cap")
		else:
			b.text = Keybinds.key_text(code) if code != 0 else "—"
			_key_style(b, "fixed" if d.get("fixed", false) else ("bad" if bad.has(key) else ""))

func _after_change() -> void:
	_refresh_keys()
	if hud != null:
		hud._cmd_sig = ""

func _cap_start(id: String, slot: int) -> void:
	_cap_id = id
	_cap_slot = slot
	_hide_warn()
	set_process_input(true)
	_refresh_keys()

func _cap_cancel() -> void:
	if _cap_id == "":
		return
	_cap_id = ""
	set_process_input(false)
	if not _kb_btns.is_empty():
		_refresh_keys()

func _input(e: InputEvent) -> void:
	if _cap_id == "":
		return
	if e is InputEventMouseButton and e.pressed:
		# başka yere tıklamak yakalamayı bırakır (başka tuş düğmesi kendi yakalamasını başlatır)
		call_deferred("_cap_cancel_if", _cap_id, _cap_slot)
		return
	if not (e is InputEventKey) or not e.pressed or e.echo:
		return
	var k := e as InputEventKey
	get_viewport().set_input_as_handled()
	if k.keycode in [KEY_SHIFT, KEY_CTRL, KEY_ALT, KEY_META, KEY_CAPSLOCK]:
		return      # yalnız değiştirici: asıl tuşu bekle
	if k.keycode == KEY_ESCAPE:
		_cap_cancel()
		return
	_try_assign(_cap_id, _cap_slot, Keybinds.event_code(k))

func _cap_cancel_if(id: String, slot: int) -> void:
	if _cap_id == id and _cap_slot == slot:
		_cap_cancel()

func _try_assign(id: String, slot: int, code: int) -> void:
	_cap_cancel()
	var conf := Keybinds.conflicts(id, code)
	if conf.is_empty():
		Keybinds.set_bind(id, slot, code)
		_after_change()
		return
	var names: Array = []
	var fixed := ""
	for c in conf:
		var d := Keybinds.def_of(c[0])
		names.append(act_name(d))
		if d["fixed"]:
			fixed = act_name(d)
	var kt := Keybinds.key_text(code)
	if fixed != "":
		Sfx.play2d("ui_error", -6.0)
		_warn(t("«%s» sabit bir tuş (%s). Başka bir tuş seçin.") % [kt, fixed], true)
		return
	var overwrite := func() -> void:
		for c in conf:
			Keybinds.set_bind(c[0], c[1], 0, false)
		Keybinds.set_bind(id, slot, code)
		_hide_warn()
		_after_change()
	_warn(t("«%s» zaten şuna atanmış: %s. Üstüne yazılsın mı?") % [kt, ", ".join(names)], false, overwrite)

func _warn(text: String, bad: bool, on_ok := Callable()) -> void:
	if _kb_warn == null or not is_instance_valid(_kb_warn):
		return
	for c in _kb_warn.get_children():
		c.queue_free()
	var col := Sketch.RED if bad else Sketch.INK
	_kb_warn.add_theme_stylebox_override("panel", _sb(Color(col.r, col.g, col.b, 0.1), Color(col.r, col.g, col.b, 0.7), 1, 10.0))
	var h := HBoxContainer.new()
	h.add_theme_constant_override("separation", 10)
	_kb_warn.add_child(h)
	var l := _lbl(h, "", 16, Sketch.INK, hud.font_m, true)
	l.text = text
	l.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	if on_ok.is_valid():
		var ok := _btn(h, "ÜSTÜNE YAZ", on_ok, 16, 0, 34)
		_primary(ok)
		_btn(h, "İPTAL", func(): _hide_warn(), 16, 0, 34)
	_kb_warn.visible = true

func _hide_warn() -> void:
	if _kb_warn != null and is_instance_valid(_kb_warn):
		_kb_warn.visible = false

func _reset_keys() -> void:
	if _reset_arm <= 0.0:
		_reset_arm = 3.0
		_kb_reset.text = t("EMİN MİSİNİZ? TEKRAR TIKLAYIN")
		return
	_reset_arm = 0.0
	_kb_reset.text = t("VARSAYILANLARA DÖN")
	_cap_cancel()
	Keybinds.reset_all()
	_after_change()
	_warn(t("Tüm tuşlar varsayılana döndü."), false)

# ============================================================ çıkış onayı
func confirm_quit() -> void:
	if _confirm != null:
		return
	_confirm = make_confirm(hud, self, "MASAÜSTÜNE ÇIK", "Oyun kapatılsın mı?", "ÇIK", func(): get_tree().quit(), func(): _close_confirm())

func _close_confirm() -> void:
	if _confirm != null and is_instance_valid(_confirm):
		_confirm.queue_free()
	_confirm = null

# ortak onay kutusu (duraklatma menüsü de kullanır). İPTAL kutuyu kendisi kapatır, sonra on_cancel.
static func make_confirm(h: Hud, parent: Control, title: String, text: String, ok_text: String, on_ok: Callable, on_cancel: Callable) -> Control:
	var c := Control.new()
	c.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.process_mode = Node.PROCESS_MODE_ALWAYS
	c.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	parent.add_child(c)
	var shade := ColorRect.new()
	shade.set_anchors_preset(Control.PRESET_FULL_RECT)
	shade.color = Color(0, 0, 0, 0.6)
	c.add_child(shade)
	var cc := CenterContainer.new()
	cc.set_anchors_preset(Control.PRESET_FULL_RECT)
	c.add_child(cc)
	var pc := PanelContainer.new()
	var sb := Sketch.panel(0.98, 0, 41)
	pc.add_theme_stylebox_override("panel", sb)
	pc.custom_minimum_size = Vector2(460, 0)
	cc.add_child(pc)
	var v := VBoxContainer.new()
	v.add_theme_constant_override("separation", 0)
	pc.add_child(v)
	var m := MarginContainer.new()
	for s in ["margin_left", "margin_right"]:
		m.add_theme_constant_override(s, 26)
	m.add_theme_constant_override("margin_top", 18)
	m.add_theme_constant_override("margin_bottom", 20)
	v.add_child(m)
	var iv := VBoxContainer.new()
	iv.add_theme_constant_override("separation", 6)
	m.add_child(iv)
	for p in [[title, 32, Sketch.INK, h.font_b], [text, 18, Sketch.INK2, h.font_m]]:
		var l := Label.new()
		l.text = Sketch.sc(t(p[0]))
		l.add_theme_font_size_override("font_size", p[1])
		l.add_theme_color_override("font_color", p[2])
		l.add_theme_font_override("font", p[3])
		iv.add_child(l)
	var gap := Control.new()
	gap.custom_minimum_size = Vector2(0, 14)
	iv.add_child(gap)
	var bh := HBoxContainer.new()
	bh.add_theme_constant_override("separation", 10)
	bh.alignment = BoxContainer.ALIGNMENT_END
	iv.add_child(bh)
	for p in [["İPTAL", on_cancel, false], [ok_text, on_ok, true]]:
		var b := Button.new()
		b.text = Sketch.sc(t(p[0]))
		b.focus_mode = Control.FOCUS_NONE
		b.custom_minimum_size = Vector2(150, 44)
		b.add_theme_font_override("font", h.font_m)
		b.add_theme_font_size_override("font_size", 20)
		var cb: Callable = p[1]
		var is_ok: bool = p[2]
		b.pressed.connect(func():
			Sfx.play2d("ui_click", -4.0)
			if not is_ok:
				c.queue_free()      # İPTAL kutuyu her durumda kapatır
			if cb.is_valid():
				cb.call())
		if p[2]:
			# onay: mürekkep dolgu, üzerinde kırmızı yazı
			var n := Sketch.button("pressed", 8)
			b.add_theme_stylebox_override("normal", n)
			b.add_theme_stylebox_override("hover", n)
			b.add_theme_stylebox_override("pressed", n)
			b.add_theme_font_override("font", h.font_b)
			for k in ["font_color", "font_pressed_color"]:
				b.add_theme_color_override(k, Sketch.PAPER)
			b.add_theme_color_override("font_hover_color", Color(0.95, 0.62, 0.5))
		bh.add_child(b)
	return c

# ============================================================ küçük bileşenler
class LockIcon extends Control:
	var col := Sketch.INK2

	func _init() -> void:
		mouse_filter = Control.MOUSE_FILTER_IGNORE

	func _draw() -> void:
		var w := size.x
		var h := size.y
		var bt := h * 0.45
		var r := w * 0.3
		draw_arc(Vector2(w * 0.5, bt), r, PI, TAU, 12, col, maxf(1.4, w * 0.12))
		draw_line(Vector2(w * 0.5 - r, bt), Vector2(w * 0.5 - r, bt + 1), col, maxf(1.4, w * 0.12))
		draw_line(Vector2(w * 0.5 + r, bt), Vector2(w * 0.5 + r, bt + 1), col, maxf(1.4, w * 0.12))
		draw_rect(Rect2(Vector2(0, bt), Vector2(w, h - bt)), col)
