extends Node
# Tuş atama testi: varsayılanlar, çakışma denetimi, yeniden atamanın oyun davranışını
# gerçekten değiştirmesi (PlayerCtl girdisi), kalıcılık (JSON gidiş-dönüş) ve menüdeki
# Klavye Ayarları sekmesi (tuş yakalama, çakışma uyarısı, üstüne yazma).
#   godot --path . res://tools/keybinds_test.tscn
# Her denetim PASS/FAIL yazar; sonunda "KEYBINDS n/m PASS". Gerçek ayar dosyasına
# yazmaz (sahte Main.save_cfg).

var ok := 0
var fail := 0

class FakeMain extends Node3D:
	var cfg := {"volume": 0.8, "difficulty": 1, "lang": "tr", "fullscreen": true, "shadows": true, "edge_scroll": true}
	var saves := 0
	func save_cfg() -> void:
		saves += 1
	func apply_video() -> void:
		pass

# emirleri ve seçimleri kaydeden oyuncu (birlik gerektirmez)
class RecPlayer extends PlayerCtl:
	var orders: Array = []
	var sel_types: Array = []
	func order_button(id: String) -> void:
		orders.append(id)
	func _select_type_on_screen(t: String) -> void:
		sel_types.append(t)

func check(name: String, cond: bool) -> void:
	print(("PASS  " if cond else "FAIL  ") + name)
	if cond:
		ok += 1
	else:
		fail += 1

func key(code: int) -> InputEventKey:
	var e := InputEventKey.new()
	e.keycode = (code & ~Keybinds.MODS) as Key
	e.ctrl_pressed = (code & KEY_MASK_CTRL) != 0
	e.shift_pressed = (code & KEY_MASK_SHIFT) != 0
	e.alt_pressed = (code & KEY_MASK_ALT) != 0
	e.pressed = true
	return e

func act(code: int, placing := false) -> String:
	return Keybinds.action_for(key(code), placing)

func _ready() -> void:
	Sfx.muted = true
	I18n.setup("tr")
	var fm := FakeMain.new()
	add_child(fm)
	G.main = fm
	Keybinds._inited = false
	Keybinds.ensure()

	# ---------------- varsayılanlar
	check("varsayılan: G -> el bombası", act(KEY_G) == "o.grenade")
	check("varsayılan: Shift+G -> el bombası (Shift yok sayılır)", act(KEY_G | KEY_MASK_SHIFT) == "o.grenade")
	check("varsayılan: Ctrl+G -> hiçbiri", act(KEY_G | KEY_MASK_CTRL) == "")
	check("varsayılan: L -> mini drone, O -> drone istasyonu, I -> halatla indir", act(KEY_L) == "o.minidrone" and act(KEY_O) == "o.dronestation" and act(KEY_I) == "o.fastrope")
	check("varsayılan: 1 -> grup 1 seç, Ctrl+1 -> grup 1 ata", act(KEY_1) == "grp.sel.1" and act(KEY_1 | KEY_MASK_CTRL) == "grp.set.1")
	check("varsayılan: Ctrl+0 -> grup 0 ata", act(KEY_0 | KEY_MASK_CTRL) == "grp.set.0")
	check("varsayılan: R -> geri çekil; yerleştirirken R -> döndür", act(KEY_R) == "o.retreat" and act(KEY_R, true) == "place.rot")
	check("varsayılan: F2 hız ×2, Num Enter konuşlanma, Backspace karargâh", act(KEY_F2) == "speed.2" and act(KEY_KP_ENTER) == "deploy" and act(KEY_BACKSPACE) == "hq")
	check("varsayılan: W (sabit kamera) eylem değil", act(KEY_W) == "")
	check("varsayılanlarda çakışma yok", Keybinds.all_conflicts().is_empty())
	var n_orders := 0
	for d in Keybinds.defs():
		if d["cat"] == "orders":
			n_orders += 1
	check("tüm emirler listede (%d)" % n_orders, n_orders == Hud.ORDER_SEQ.size())

	# ---------------- çakışma denetimi
	var cp := Keybinds.conflicts("o.grenade", KEY_P)
	check("çakışma: G'yi P'ye atamak 'duraklat' ile çakışır", cp.size() == 1 and cp[0][0] == "pause")
	check("çakışma: sabit kamera tuşu W", Keybinds.conflicts("o.grenade", KEY_W).any(func(c): return c[0] == "cam.up"))
	check("çakışma: Ctrl+W de kamerayı kaydırır (basılı sabit tuş)", Keybinds.conflicts("o.grenade", KEY_W | KEY_MASK_CTRL).any(func(c): return c[0] == "cam.up"))
	check("çakışma yok: yerleştirme döndürme (place) ile emir (unit) aynı tuşu paylaşabilir", Keybinds.conflicts("place.rot", KEY_M).is_empty())

	# ---------------- yeniden atama oyun davranışını değiştirir
	var was_running := G.running
	var was_spec := G.spectate
	G.running = true
	G.spectate = false
	G.game_over = false
	var rp := RecPlayer.new()
	rp._unhandled_input(key(KEY_G))
	check("oyun: G -> el bombası emri", rp.orders == ["grenade"])
	Keybinds.set_bind("o.grenade", 0, KEY_SEMICOLON)
	rp.orders.clear()
	rp._unhandled_input(key(KEY_G))
	check("oyun: atamadan sonra G artık el bombası değil", rp.orders.is_empty())
	rp._unhandled_input(key(KEY_SEMICOLON))
	check("oyun: atamadan sonra ';' el bombası", rp.orders == ["grenade"])

	Engine.time_scale = 1.0
	Keybinds.set_bind("speed.2", 0, KEY_F7)
	rp._unhandled_input(key(KEY_F2))
	check("oyun: F2 artık hız değiştirmez", is_equal_approx(Engine.time_scale, 1.0))
	rp._unhandled_input(key(KEY_F7))
	check("oyun: F7 hızı ×2 yapar", is_equal_approx(Engine.time_scale, 2.0))
	Engine.time_scale = 1.0

	G.deploy_t = 5.0
	Keybinds.set_bind("deploy", 0, KEY_F8)
	rp._unhandled_input(key(KEY_ENTER))
	check("oyun: Enter artık konuşlanmayı bitirmez", G.deploy_t == 5.0)
	rp._unhandled_input(key(KEY_F8))
	check("oyun: F8 konuşlanmayı bitirir", G.deploy_t < 0.1)
	G.deploy_t = 0.0

	Keybinds.set_bind("grp.set.1", 0, KEY_F9)
	rp._unhandled_input(key(KEY_1 | KEY_MASK_CTRL))
	check("oyun: Ctrl+1 artık grup atamaz", not rp.groups.has(1))
	rp._unhandled_input(key(KEY_F9))
	check("oyun: F9 grup 1'i atar", rp.groups.has(1))

	rp.place_type = "fob"
	rp.place_rot = 0.0
	rp._unhandled_input(key(KEY_R))
	check("oyun: yerleştirirken R döndürür", is_equal_approx(rp.place_rot, PI * 0.25))
	Keybinds.set_bind("place.rot", 0, KEY_T)
	rp.orders.clear()
	rp._unhandled_input(key(KEY_T))
	check("oyun: döndürme T'ye atandı, T döndürür", is_equal_approx(rp.place_rot, PI * 0.5) and rp.orders.is_empty())
	rp._unhandled_input(key(KEY_T | KEY_MASK_SHIFT))
	check("oyun: Shift+T ters döndürür", is_equal_approx(rp.place_rot, PI * 0.25))
	rp.place_type = ""
	rp._unhandled_input(key(KEY_T))
	check("oyun: yerleştirme dışında T yine saldırı hareketi", rp.orders == ["amove"])

	rp._unhandled_input(key(KEY_Q))
	Keybinds.set_bind("sel.inf", 0, KEY_F6)
	rp._unhandled_input(key(KEY_Q))
	rp._unhandled_input(key(KEY_F6))
	check("oyun: piyade seçimi Q'dan F6'ya taşındı", rp.sel_types == ["inf", "inf"])
	rp.free()
	G.running = was_running
	G.spectate = was_spec

	# ---------------- kalıcılık
	check("kayıt: her atamada save_cfg çağrıldı", fm.saves >= 6)
	var kd: Dictionary = fm.cfg.get("keys", {})
	check("kayıt: cfg['keys'] yalnız değişenleri tutar", kd.has("o.grenade") and not kd.has("o.move") and int(kd["o.grenade"][0]) == KEY_SEMICOLON)
	var txt := JSON.stringify(fm.cfg)
	fm.cfg = JSON.parse_string(txt)
	Keybinds._inited = false
	Keybinds.reset_all(false)
	Keybinds._inited = false
	Keybinds.ensure()
	check("kayıt: JSON gidiş-dönüşten sonra ';' hâlâ el bombası", act(KEY_SEMICOLON) == "o.grenade" and act(KEY_G) == "")
	check("kayıt: JSON'dan gelen tuşlar tamsayı", typeof(Keybinds.binds("o.grenade")[0]) == TYPE_INT)
	check("emir düğmesi etiketi yeni tuşu gösterir", Keybinds.short("o.grenade") == ";" or Keybinds.short("o.grenade") == "SEMICOLON")
	Keybinds.reset_all()
	check("varsayılana dön: G yine el bombası, kayıt boş", act(KEY_G) == "o.grenade" and (fm.cfg["keys"] as Dictionary).is_empty())

	# ---------------- menü: Klavye Ayarları sekmesi
	var hud := Hud.new()
	add_child(hud)
	G.hud = hud
	var m := hud.show_menu()
	await get_tree().process_frame
	m.open_settings_tab("keys")
	await get_tree().process_frame
	check("menü: tuş satırları kuruldu", m._kb_btns.has("o.smoke:0") and m._kb_btns.has("grp.set.9:0"))
	check("menü: sabit satır düğmesi devre dışı", (m._kb_btns["cam.up:0"] as Button).disabled)
	m._cap_start("o.smoke", 0)
	check("menü: yakalama 'TUŞA BASIN…' gösterir", (m._kb_btns["o.smoke:0"] as Button).text == MainMenu.t("TUŞA BASIN…"))
	m._input(key(KEY_COMMA))
	check("menü: ',' sis emrine atandı", Keybinds.binds("o.smoke")[0] == KEY_COMMA and act(KEY_COMMA) == "o.smoke")
	m._cap_start("o.smoke", 0)
	m._input(key(KEY_CTRL | KEY_MASK_CTRL))
	check("menü: yalnız Ctrl basmak atamaz, beklemeye devam", m._cap_id == "o.smoke")
	m._input(key(KEY_ESCAPE))
	check("menü: Esc yakalamayı iptal eder, tuş değişmez", m._cap_id == "" and Keybinds.binds("o.smoke")[0] == KEY_COMMA)
	m._cap_start("o.smoke", 0)
	m._input(key(KEY_P))
	await get_tree().process_frame
	check("menü: P çakışması uyarı gösterir, atama beklemede", m._kb_warn.visible and Keybinds.binds("o.smoke")[0] == KEY_COMMA)
	var ow: Button = null
	for b in m._kb_warn.find_children("*", "Button", true, false):
		if (b as Button).text == MainMenu.t("ÜSTÜNE YAZ"):
			ow = b
	check("menü: 'ÜSTÜNE YAZ' düğmesi var", ow != null)
	if ow != null:
		ow.pressed.emit()
	check("menü: üstüne yaz -> P sis, duraklat P'yi kaybetti (Pause kaldı)", Keybinds.binds("o.smoke")[0] == KEY_P and not Keybinds.binds("pause").has(KEY_P) and Keybinds.binds("pause").has(KEY_PAUSE))
	check("menü: düğme yeni tuşu yazar", (m._kb_btns["o.smoke:0"] as Button).text == "P")
	m._cap_start("o.smoke", 1)
	m._input(key(KEY_W))
	check("menü: sabit tuş W atanamaz", Keybinds.binds("o.smoke")[1] == 0 and m._kb_warn.visible)
	m._cap_start("o.smoke", 1)
	m._input(key(KEY_Z | KEY_MASK_CTRL))
	check("menü: Ctrl+Z ikincil tuş olarak atandı", Keybinds.binds("o.smoke")[1] == (KEY_Z | KEY_MASK_CTRL) and act(KEY_Z | KEY_MASK_CTRL) == "o.smoke")
	m._reset_keys()
	check("menü: varsayılana dön ilk tıkta onay ister", Keybinds.binds("o.smoke")[0] == KEY_P)
	m._reset_keys()
	check("menü: ikinci tıkta tüm tuşlar varsayılan", Keybinds.binds("o.smoke")[0] == KEY_Z and Keybinds.binds("pause")[0] == KEY_P and Keybinds.to_dict().is_empty())
	# masaüstüne çık onayı: ana menüde ve duraklatma menüsünde tek kutu açılır
	m.confirm_quit()
	m.confirm_quit()
	check("çıkış onayı: ana menüde tek kutu", m._confirm != null and m.find_children("*", "CenterContainer", true, false).size() == 1)
	m._close_confirm()
	var pm := Control.new()
	hud.root.add_child(pm)
	hud._confirm_quit(pm)
	hud._confirm_quit(pm)
	check("çıkış onayı: duraklatma menüsünde tek kutu", pm.get_child_count() == 1 and pm.has_meta("confirm"))
	var cancel: Button = null
	for b in pm.find_children("*", "Button", true, false):
		if (b as Button).text == MainMenu.t("İPTAL"):
			cancel = b
	if cancel != null:
		cancel.pressed.emit()
	await get_tree().process_frame
	check("çıkış onayı: İPTAL kutuyu kapatır", cancel != null and pm.get_child_count() == 0)
	hud._confirm_quit(pm)
	check("çıkış onayı: kapandıktan sonra yeniden açılır", pm.get_child_count() == 1)
	pm.queue_free()
	# İngilizce adlar
	I18n.setup("en")
	check("çeviri: grup adı İngilizce", m.act_name(Keybinds.def_of("grp.sel.3")) == "Group 3: select (press again: camera)")
	check("çeviri: emir adı I18n'den", m.act_name(Keybinds.def_of("o.move")) == "Move")
	I18n.setup("tr")

	print("KEYBINDS %d/%d PASS" % [ok, ok + fail])
	get_tree().quit(0 if fail == 0 else 1)
