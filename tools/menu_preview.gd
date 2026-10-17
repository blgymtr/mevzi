extends Node
# Ana menü önizleme: menünün her sayfasının ekran görüntüsünü PNG olarak kaydeder.
# main.gd'ye dokunmadan çalışır:
#   godot --path . res://tools/menu_preview.tscn -- --out=/mutlak/klasör [--stub] [--seed=N]
# Varsayılan: gerçek ana sahne (main.tscn) kurulur, arkada YZ savaşı sürerken menü çekilir.
# --stub: dünya kurulmaz (hızlı); sahte Main + koyu zemin, yalnız arayüz denetimi için.
# Not: gerçek kipte ayarlar user://settings.json'dan okunur — XDG_DATA_HOME ile ayrı bir
# klasöre yönlendirip çalıştırın ki oyuncu ayarları etkilenmesin.

var out := "user://menu_preview"
var stub := false
var seed_v := 3
var hud: Hud

class StubMain extends Node3D:
	var cfg := {"volume": 0.8, "difficulty": 1, "lang": "", "fullscreen": true, "shadows": true, "edge_scroll": true}
	func save_cfg() -> void:
		pass
	func apply_video() -> void:
		pass
	func set_lang(l: String) -> void:
		I18n.setup(l)

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out = a.substr(6)
		elif a == "--stub":
			stub = true
		elif a.begins_with("--seed="):
			seed_v = int(a.substr(7))
	DirAccess.make_dir_recursive_absolute(out)
	get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	if stub:
		var sm := StubMain.new()
		add_child(sm)
		G.main = sm
		I18n.setup("tr")
		var bg := ColorRect.new()
		bg.color = Color(0.16, 0.17, 0.14)
		bg.set_anchors_preset(Control.PRESET_FULL_RECT)
		var cl := CanvasLayer.new()
		cl.layer = 0
		add_child(cl)
		cl.add_child(bg)
		hud = Hud.new()
		add_child(hud)
		G.hud = hud
		hud.show_menu()
	else:
		# Main.to_menu rastgele harita seçer; küçük (256 m) bir harita gelecek tohumu bul ki
		# yazılımsal çizimde dünya kurulumu kısa sürsün (ilk randi() harita seçimidir)
		var keys: Array = MapGen.MAPS.keys()
		for s in range(seed_v, seed_v + 64):
			seed(s)
			if int(MapGen.MAPS[keys[randi() % keys.size()]].get("size", 256)) <= 256:
				seed_v = s
				break
		seed(seed_v)
		var main: Node = load("res://scenes/main.tscn").instantiate()
		add_child(main)
		hud = G.hud
		print("PREVIEW map=", G.map_id, " size=", G.MAP)
	_run()

func _frames(n: int) -> void:
	for i in n:
		await get_tree().process_frame

func _shot(n: String) -> void:
	await _frames(3)
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var p := out.path_join(n + ".png")
	img.save_png(p)
	print("SHOT ", p)

func _menu() -> MainMenu:
	return hud.menu as MainMenu

func _run() -> void:
	await _frames(20 if stub else 40)
	await _shot("01_ana_menu")
	var m := _menu()
	m.open_page("campaign")
	await _shot("02_kampanya")
	m.open_page("classic")
	await _shot("03_klasik_harita")
	m.open_page("sandbox")
	await _shot("04_sandbox_test")
	m.open_page("editor")
	await _shot("05_senaryo_olusturucu")
	m.open_settings_tab("graphics")
	await _shot("06_ayarlar_grafik")
	m.open_settings_tab("audio")
	await _shot("07_ayarlar_ses")
	m.open_settings_tab("gameplay")
	await _shot("08_ayarlar_oynanis")
	m.open_settings_tab("keys")
	await _shot("09_ayarlar_klavye")
	# tuş bekleme durumu
	m._cap_start("o.grenade", 0)
	await _shot("10_klavye_tus_bekliyor")
	# çakışma uyarısı (atama yapılmaz, yalnız uyarı gösterilir)
	var ev := InputEventKey.new()
	ev.keycode = KEY_P
	ev.pressed = true
	m._input(ev)
	await _shot("11_klavye_cakisma_uyarisi")
	m._hide_warn()
	m.open_page("")
	m.confirm_quit()
	await _shot("12_masaustune_cik_onay")
	m._close_confirm()
	# İngilizce
	I18n.setup("en")
	m = hud.show_menu()
	await _frames(2)
	m.open_page("classic")
	await _shot("13_en_skirmish")
	m.open_settings_tab("keys")
	await _shot("14_en_key_bindings")
	m.open_page("campaign")
	await _shot("15_en_campaign")
	I18n.setup("tr")
	if not stub:
		# oyun içi duraklatma menüsü + masaüstüne çık onayı (arkadaki YZ savaşı oyuncu oyunu sayılır)
		hud.hide_menu()
		G.spectate = false
		G.game_over = false
		hud.toggle_pause()
		await _shot("16_duraklatma_menusu")
		hud._confirm_quit(hud.pause_menu)
		await _shot("17_duraklatma_cikis_onayi")
		hud.toggle_pause()
	print("PREVIEW DONE")
	get_tree().quit()
