class_name Tests07 extends RefCounted
# Hotfix 0.0.7 sahne testleri: --scene=treetest | yieldtest | dronetest | woundtest | ropetest | evadetest | crewtest

var m: Main

func _init(main: Main) -> void:
	m = main

func run(scene: String) -> void:
	match scene:
		"treetest":
			await tree_test()
		"dronetest":
			await drone_test()
		"evadetest":
			await evade_test()
		"woundtest":
			await wound_test()
		"ropetest":
			await rope_test()
		"crewtest":
			await crew_test()
		"fowtest":
			await fow_test()
		"paratest":
			await para_test()
		"tactest":
			await tac_test()
		"largetest":
			await large_test()
		"hugetest":
			await huge_test()
		"rocktest":
			await rock_test()
	m.get_tree().quit()

func _densest(kind: String) -> Vector3:
	var best := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var bn := -1
	var its: Array = G.props.items.filter(func(it): return it["kind"] == kind and it["alive"])
	for i in range(0, its.size(), maxi(1, its.size() / 60)):
		var p: Vector3 = its[i]["pos"]
		var n := 0
		for it in its:
			if (it["pos"] as Vector3).distance_to(p) < 14.0:
				n += 1
		if n > bn:
			bn = n
			best = p
	return best

func _cam(c: Vector3, size: float) -> void:
	# yüksekteki nesne (halat, paraşüt, helikopter): yer odağı, ekranda aynı yere düşecek kadar kaydırılır
	if c.y > 0.5:
		var th := deg_to_rad(CamRig.PITCH)
		c = Vector3(c.x, 0, c.z) + G.cam.up_vec() * (c.y / tan(th))
	G.cam.jump_to(c, true)
	G.cam.size = size
	G.cam.target_size = size

# ağaç modelleri (yeşil / kış / çöl) + büyük patlamada sallanma
func tree_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	for mp in ["green_valley", "winter_village", "desert_canal"]:
		m.start_game(mp, {}, true)
		var c := _densest("tree")
		var n := G.props.items.filter(func(it): return it["kind"] == "tree").size()
		print("TREE map=%s trees=%d" % [mp, n])
		_cam(c, 26.0)
		await m._wait(1.0)
		await m._shot("tree_%s_00" % mp)
		if mp == "green_valley":
			for i in 4:
				m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(i * 1.5, 0, 6), Grid.M_INF), null).cmd_hold()
			G.explode(c + Vector3(3, 0, 2), 8.0, 400.0, "big", 1, null)
			await m._wait(0.18)
			await m._shot("tree_%s_01_blast" % mp)
			await m._wait(0.45)
			await m._shot("tree_%s_02_sway" % mp)
			_cam(c, 60.0)
			await m._wait(2.0)
			await m._shot("tree_%s_03_wide" % mp)
	print("TREETEST RESULT fails=%d" % fails)

# drone operatörü: kendiliğinden kaldırmaz; mini drone emri; istasyon kurulumu + İHA fırlatma
func drone_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var op: Soldier = m.spawn_soldier(G.player_team, "drone", c, null)
	op.cmd_hold()
	var en: Vehicle = m.spawn_vehicle(1 - G.player_team, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(40, 0, 10), Grid.M_HEAVY), 0.0)
	en.cmd_hold()
	en.fire_mode = 2
	G.reveal = [999.0, 999.0]
	await m._wait(6.0)
	if op.my_drone != null:
		print("DRONE fail: spawned without order")
		fails += 1
	_cam(c, 22.0)
	op.cmd_minidrone(en.position, en)
	await m._wait(0.7)
	await m._shot("drone_00_prep")
	await m._wait(1.0)
	var dr = op.my_drone
	if dr == null:
		print("DRONE fail: no mini drone after order")
		fails += 1
	await m._wait(0.5)
	await m._shot("drone_01_launch")
	# istasyon
	op.cmd_station(c + Vector3(-6, 0, 4))
	await m._wait(5.0)
	_cam(op.station.position, 16.0)
	await m._shot("drone_02_setup")
	await m._wait(15.0)
	var st: DroneStation = op.station
	print("DRONE station_done=%s progress=%.2f" % [st.done, st.progress])
	await m._wait(3.5)
	await m._shot("drone_03_station")
	var uav = st.uav
	if uav == null or not is_instance_valid(uav) or not uav.high_alt:
		print("DRONE fail: no high-alt uav")
		fails += 1
	await m._wait(8.0)
	if uav != null and is_instance_valid(uav):
		print("DRONE uav_alt=%.1f sight=%.0f" % [uav.hull.position.y, uav.sight])
		_cam(uav.position, 40.0)
		await m._wait(0.5)
		await m._shot("drone_04_uav")
	# operatör ölünce bağ kopar
	op.die(null)
	await m._wait(1.0)
	if uav != null and is_instance_valid(uav) and not uav.link_lost:
		print("DRONE fail: link not lost")
		fails += 1
	print("DRONETEST RESULT fails=%d" % fails)

# karadan havaya füze: helikopter fişek atar + kırar; İHA manevra; Hellfire/Vikhr görünümü
func evade_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.reveal = [999.0, 999.0]
	var aa: Vehicle = m.spawn_vehicle(0, "usa_aa_avenger", c, 0.0)
	aa.cmd_hold()
	var heli: Vehicle = m.spawn_vehicle(1, "heli", c + Vector3(55, 0, -20), 0.0)
	heli.cmd_move(c + Vector3(55, 0, 20))
	heli.fire_mode = 2
	print("EVADE sams=%d flares=%d" % [aa.sams, heli.flares])
	if aa.sams <= 0 or heli.flares <= 0:
		fails += 1
	_cam(c + Vector3(30, 0, 0), 46.0)
	var shot_n := 0
	var seen_sam := false
	var flares0 := heli.flares
	for i in 240:
		await m._wait(0.05)
		var nsam := G.bal.projs.filter(func(p): return p.kind == "sam").size()
		var nfl := G.bal.projs.filter(func(p): return p.kind == "flare").size()
		if nsam > 0:
			seen_sam = true
		if i % 30 == 0:
			print("EVADE loop i=%d ms=%d fps=%d projs=%d heli=%s" % [i, Time.get_ticks_msec(), Engine.get_frames_per_second(), G.bal.projs.size(), is_instance_valid(heli) and heli.alive])
		if (nsam > 0 or nfl > 0) and shot_n < 4 and i % 6 == 0:
			if is_instance_valid(heli):
				_cam(heli.position + Vector3(0, heli.hull.position.y, 0), 34.0)
			await m._shot("evade_%02d" % shot_n)
			shot_n += 1
	var hv := is_instance_valid(heli)
	var fl_used: int = flares0 - (heli.flares if hv else 0)
	print("EVADE seen_sam=%s flares_used=%d heli_alive=%s" % [seen_sam, fl_used, hv and heli.alive])
	if not seen_sam or fl_used == 0:
		fails += 1
	# helikopter füzesi: dost helikopter düşman tanka Hellfire atar
	var h2: Vehicle = m.spawn_vehicle(0, "heli", c + Vector3(-40, 0, 40), 0.0)
	var tk: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(-40, 0, -15), Grid.M_HEAVY), 0.0)
	tk.cmd_hold()
	tk.fire_mode = 2
	h2.cmd_attack(tk)
	var shot_h := false
	for i in 300:
		await m._wait(0.05)
		if i % 40 == 0:
			print("EVADE dbg t=%.1f tgt=%s hf=%d cd=%.1f dist=%.0f alive=%s" % [G.time, h2.target, h2.hf_left, h2.hf_cd, h2.dist2(tk), h2.alive])
		var ms: Array = G.bal.projs.filter(func(p): return p.kind == "atgm" and p.src == h2)
		if not ms.is_empty() and not shot_h and ms[0].t > 0.35:
			shot_h = true
			_cam(ms[0].pos, 14.0)
			await m._shot("evade_10_hellfire")
			_cam(ms[0].pos, 30.0)
			await m._wait(0.3)
			await m._shot("evade_11_hellfire_trail")
	print("EVADE hellfire_seen=%s" % shot_h)
	if not shot_h:
		fails += 1
	print("EVADETEST RESULT fails=%d" % fails)

# bölgesel yaralar (görsel + yürüyüş) ve tim dağılıp başka time katılma
func wound_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var kinds := ["leg", "arm", "shoulder", "head", "torso"]
	var ss: Array = []
	for i in kinds.size():
		var s: Soldier = m.spawn_soldier(G.player_team, "mg" if kinds[i] == "arm" else "rifle", c + Vector3(i * 1.6, 0, 0), null)
		s.injury = kinds[i]
		s._treat_injury()
		ss.append(s)
	await m._wait(0.5)
	_cam(c + Vector3(3.2, 0, 0), 9.0)
	await m._wait(0.6)
	await m._shot("wound_00_static")
	for s in ss:
		s.cmd_move(s.position + Vector3(0, 0, 14))
	await m._wait(1.2)
	_cam(c + Vector3(3.2, 0, 4), 10.0)
	await m._shot("wound_01_walk")
	for s in ss:
		print("WOUND %s speed=%.2f" % [s.injury, s.vel.length()])
	if ss[0].vel.length() > 1.7:
		fails += 1
	# tim birleştirme
	var sq1 := Squad.new(G.player_team, "Tim")
	G.squads.append(sq1)
	var sq2 := Squad.new(G.player_team, "Tim")
	G.squads.append(sq2)
	var a: Array = []
	for i in 5:
		a.append(m.spawn_soldier(G.player_team, ["leader", "rifle", "rifle", "mg", "at"][i], c + Vector3(-20 + i, 0, -10), sq1))
	for i in 5:
		m.spawn_soldier(G.player_team, ["leader", "rifle", "rifle", "rifle", "medic"][i], c + Vector3(-20 + i, 0, 10), sq2)
	await m._wait(4.0)
	a[0].die(null)
	await m._wait(7.0)
	var moved := 0
	for x in a.slice(1):
		if x.squad == sq2:
			moved += 1
	print("WOUND squad_merge moved=%d/4 sq2=%d" % [moved, sq2.able().size()])
	if moved < 4:
		fails += 1
	print("WOUNDTEST RESULT fails=%d" % fails)

# halatla iniş: kargo helikopteri 8 askeri iki halattan indirir, halatlar bırakılır; sonra SPIES ile geri alır
func rope_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var h: Vehicle = m.spawn_vehicle(G.player_team, "usa_heli_uh60", c + Vector3(-40, 0, 0), 0.0)
	var sq := Squad.new(G.player_team, "Tim")
	G.squads.append(sq)
	for i in 8:
		var s: Soldier = m.spawn_soldier(G.player_team, ["leader", "rifle", "rifle", "mg", "rifle", "at", "medic", "rifle"][i], h.position, sq)
		s.board(h)
	print("ROPE cargo=%d can_rope=%s" % [h.cargo.size(), h.can_rope()])
	h.cmd_fastrope(c)
	var shots := 0
	var landed := 0
	for i in 600:
		await m._wait(0.05)
		var on_rope := sq.members.filter(func(x): return x.state == "rope")
		if not on_rope.is_empty() and shots < 4 and i % 14 == 0:
			_cam(on_rope[0].position, 10.0 if shots % 2 == 0 else 16.0)
			await m._wait(0.05)
			await m._shot("rope_%02d" % shots)
			shots += 1
		landed = sq.members.filter(func(x): return x.state != "rope" and x.vehicle_in == null and x.position.y < 0.05).size()
		if landed == 8 and h.ropes.is_empty():
			break
	print("ROPE landed=%d ropes_left=%d" % [landed, h.ropes.size()])
	if landed < 8 or not h.ropes.is_empty():
		fails += 1
	await m._wait(2.0)
	_cam(c, 22.0)
	await m._shot("rope_10_after")
	# SPIES
	for x in sq.members:
		x.cmd_move(G.grid.nearest_free(c + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)), Grid.M_INF))
	await m._wait(3.0)
	h.cmd_rope_pick(c)
	var up_shot := false
	for i in 900:
		await m._wait(0.05)
		var ups := sq.members.filter(func(x): return x.state == "rope_up")
		if ups.size() >= 3 and not up_shot and ups[0].position.y > 3.0:
			up_shot = true
			_cam(ups[0].position, 16.0)
			await m._shot("rope_11_spies")
		if h.cargo.size() >= 8:
			break
	print("ROPE extracted=%d" % h.cargo.size())
	if h.cargo.size() < 6:
		fails += 1
	print("ROPETEST RESULT fails=%d" % fails)

# top mürettebatı döngüsü + araca kapıdan binme/inme
func crew_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.reveal = [999.0, 999.0]
	var gun: Vehicle = m.spawn_vehicle(G.player_team, "usa_tow_m119", c, 0.0)
	gun.cmd_hold()
	var tk: Vehicle = m.spawn_vehicle(1 - G.player_team, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(0, 0, -45), Grid.M_HEAVY), 0.0)
	tk.cmd_hold()
	tk.fire_mode = 2
	tk.hp = 99999.0
	gun.cmd_attack(tk)
	_cam(c, 9.0)
	var marks := [0.04, 0.35, 0.55, 0.8]
	var mi := 0
	var cycles := 0
	var last_cd := 0.0
	for i in 900:
		await m._wait(0.03)
		if i % 50 == 0:
			print("CREW dbg i=%d ms=%d fps=%d cycle=%.1f cd=%.2f emit=%d tgt=%s" % [i, Time.get_ticks_msec(), Engine.get_frames_per_second(), gun.crew_cycle, gun.main_cd, G.fx.emitters.size(), gun.target != null])
		if gun.crew_cycle > 0.0 and gun.main_cd > last_cd + 0.5:
			cycles += 1
		last_cd = gun.main_cd
		if cycles >= 2 and mi < marks.size():
			var p := 1.0 - gun.main_cd / gun.crew_cycle
			if p >= marks[mi] and p < marks[mi] + 0.08:
				await m._shot("crew_%02d" % mi)
				mi += 1
		if mi >= marks.size():
			break
	print("CREW cycles=%d shots=%d" % [cycles, mi])
	if cycles < 2 or mi < 4:
		fails += 1
	# araca kapıdan binme / inme
	var apc: Vehicle = m.spawn_vehicle(G.player_team, "usa_apc_icv", G.grid.nearest_free(c + Vector3(25, 0, 10), Grid.M_HEAVY), 0.6)
	apc.cmd_hold()
	var ss: Array = []
	for i in 6:
		var s: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(apc.position + Vector3(-6 + i * 1.5, 0, 9), Grid.M_INF), null)
		s.cmd_board(apc)
		ss.append(s)
	_cam(apc.position, 13.0)
	var shot_in := false
	for i in 400:
		await m._wait(0.05)
		if not shot_in and ss.any(func(x): return x.state == "entering"):
			shot_in = true
			await m._shot("crew_10_board")
		if apc.cargo.size() >= 6:
			break
	print("CREW boarded=%d" % apc.cargo.size())
	if apc.cargo.size() < 6:
		fails += 1
	apc.unload()
	var shot_out := 0
	for i in 200:
		await m._wait(0.05)
		if shot_out < 2 and ss.filter(func(x): return x.state == "exiting" and x.visible).size() > 0 and i % 6 == 0:
			await m._shot("crew_%02d_exit" % (11 + shot_out))
			shot_out += 1
	var out := ss.filter(func(x): return x.vehicle_in == null and x.state != "exiting").size()
	print("CREW unloaded=%d" % out)
	if out < 6:
		fails += 1
	print("CREWTEST RESULT fails=%d" % fails)

# görsel savaş sisi: başlangıçta yalnız karargâh çevresi açık; ilerleyen tim yolu açar
func fow_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, false)
	var hq: Vector3 = G.hq_pos[G.player_team]
	var other: Vector3 = G.hq_pos[1 - G.player_team]
	_cam(hq, 70.0)
	await m._wait(1.5)
	await m._shot("fow_00_start")
	var sq := Squad.new(G.player_team, "Tim")
	G.squads.append(sq)
	var ss: Array = []
	for i in 4:
		var s: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(hq + Vector3(i, 0, 0), Grid.M_INF), sq)
		ss.append(s)
	var mid := hq.lerp(other, 0.45)
	for s in ss:
		s.cmd_move(G.grid.nearest_free(mid + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), Grid.M_INF), true)
	await m._wait(20.0)
	_cam(hq.lerp(mid, 0.6), 80.0)
	await m._wait(0.5)
	await m._shot("fow_01_advance")
	print("FOWTEST RESULT fails=%d" % fails)

# hava indirme: uçak geçer, 8 paraşütçü atlar, kubbeler açılır, iner ve toplanır
func para_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var sq := Squad.new(G.player_team, "Paraşütçü Timi")
	G.squads.append(sq)
	var P: Dictionary = Building.PDEF["para_squad"]
	Paradrop.launch(G.player_team, c, P["units"], sq, 30.0)
	var shots := 0
	for i in 800:
		await m._wait(0.05)
		var air := sq.members.filter(func(x): return is_instance_valid(x) and x.state == "para")
		if air.size() >= 3 and shots < 3 and i % 25 == 0:
			_cam(air[0].position, 34.0 if shots == 0 else 22.0)
			await m._wait(0.05)
			await m._shot("para_%02d" % shots)
			shots += 1
		if sq.members.size() >= 8 and air.is_empty() and i > 100:
			break
	await m._wait(3.0)
	var down := sq.members.filter(func(x): return is_instance_valid(x) and x.alive and x.state != "para").size()
	_cam(c, 22.0)
	await m._shot("para_10_landed")
	print("PARA jumped=%d landed=%d" % [sq.members.size(), down])
	if down < 8:
		fails += 1
	print("PARATEST RESULT fails=%d" % fails)

# tim beyni: YZ timi uzun çatışmada kanattan dolanır, taban kolu baskı ateşi açar
func tac_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var def := Squad.new(G.player_team, "Tim")
	G.squads.append(def)
	for i in 4:
		var d: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(c + Vector3(i * 2.0, 0, -22), Grid.M_INF), def)
		d.cmd_hold()
		d.hp = 4000.0
	var att := Squad.new(1 - G.player_team, "Tim")
	G.squads.append(att)
	for i in 6:
		var a: Soldier = m.spawn_soldier(1 - G.player_team, ["leader", "rifle", "rifle", "mg", "rifle", "at"][i], G.grid.nearest_free(c + Vector3(i * 1.5, 0, 22), Grid.M_INF), att)
		a.hp = 4000.0
	var flanked := false
	var shot := false
	for i in 500:
		await m._wait(0.1)
		if not att.flankers.is_empty():
			flanked = true
			if not shot and att.flank_t > 3.0:
				shot = true
				_cam(c + Vector3(0, 0, 4), 40.0)
				await m._shot("tac_00_flank")
		if flanked and att.flankers.is_empty():
			break
	print("TAC flanked=%s engaged=%.0f" % [flanked, att.engaged_t])
	if not flanked:
		fails += 1
	print("TACTEST RESULT fails=%d" % fails)

# 1 km harita: üretim süresi, ağaç/bina sayısı, genel ve yakın görünüm, uzun yol bulma
func large_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	var t0 := Time.get_ticks_msec()
	m.start_game("large_front", {}, true)
	var ms := Time.get_ticks_msec() - t0
	var trees := G.props.items.filter(func(it): return it["kind"] == "tree").size()
	print("LARGE map=%.0f load_ms=%d trees=%d houses=%d banks=%d" % [G.MAP, ms, trees, G.blocks.houses.size(), G.props._banks.size()])
	if G.MAP < 1000.0:
		fails += 1
	var t1 := Time.get_ticks_msec()
	var path := G.grid.find_path(G.hq_pos[0], G.hq_pos[1], Grid.M_HEAVY)
	print("LARGE path_pts=%d path_ms=%d" % [path.size(), Time.get_ticks_msec() - t1])
	if path.size() < 3:
		fails += 1
	_cam(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), 115.0)
	await m._wait(1.0)
	await m._shot("large_00_mid")
	_cam(G.hq_pos[0], 60.0)
	await m._wait(0.5)
	await m._shot("large_01_hq")
	_cam(Vector3(G.MAP * 0.78, 0, G.MAP * 0.55), 50.0)
	await m._wait(0.5)
	await m._shot("large_02_village")
	print("LARGETEST RESULT fails=%d" % fails)

# 2 km ve 4 km haritalar: yükleme süresi, bellek, ağaç/bina sayısı, uçtan uca yol bulma
func huge_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	for id in ["front_2k", "airborne_4k"]:
		var t0 := Time.get_ticks_msec()
		m.start_game(id, {}, true)
		var ms := Time.get_ticks_msec() - t0
		var trees := G.props.items.filter(func(it): return it["kind"] == "tree").size()
		print("HUGE id=%s map=%.0f cs=%.1f nav=%.1f load_ms=%d mem_mb=%d trees=%d houses=%d banks=%d" % [id, G.MAP, Grid.CS, Grid.NAV, ms, OS.get_static_memory_usage() / 1048576, trees, G.blocks.houses.size(), G.props._banks.size()])
		var t1 := Time.get_ticks_msec()
		var path := G.grid.find_path(G.hq_pos[0], G.hq_pos[1], Grid.M_HEAVY)
		var pi := G.grid.find_path(G.hq_pos[0], G.hq_pos[1], Grid.M_INF)
		print("HUGE id=%s path_heavy=%d path_inf=%d path_ms=%d" % [id, path.size(), pi.size(), Time.get_ticks_msec() - t1])
		if path.size() < 3 or pi.size() < 3:
			fails += 1
		# iş parçacıklı uzun yol: 10 kişilik grup + 2 araç haritanın öbür ucuna; kare süresi ölçülür
		G.grid._pcache.clear()
		var grp: Array = []
		for k in 10:
			grp.append(m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(G.hq_pos[0] + Vector3(-40 - k * 2.0, 0, -30), Grid.M_INF), null))
		for k in 2:
			grp.append(m.spawn_vehicle(G.player_team, "truck", G.grid.nearest_free(G.hq_pos[0] + Vector3(-60, 0, -50 - k * 12.0), Grid.M_HEAVY), 0.0))
		await m._wait(0.2)
		var goal := G.grid.nearest_free(G.hq_pos[1] + Vector3(60, 0, 60), Grid.M_INF)
		var tq := Time.get_ticks_msec()
		for u in grp:
			u.cmd_move(goal)
		var issue_ms := Time.get_ticks_msec() - tq
		var worst := 0
		var last := Time.get_ticks_msec()
		for k in 60:
			await m.get_tree().process_frame
			var now := Time.get_ticks_msec()
			worst = maxi(worst, now - last)
			last = now
		var long_n := grp.filter(func(u): return u.path.size() >= 3).size()
		print("HUGE id=%s async=%s issue_ms=%d worst_frame_ms=%d units_with_full_path=%d/%d" % [id, G.grid.wants_async(G.hq_pos[0], goal), issue_ms, worst, long_n, grp.size()])
		if G.grid.wants_async(G.hq_pos[0], goal) and long_n < grp.size() - 1:
			fails += 1
		_cam(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), 115.0)
		G.fog_off = true
		await m._wait(1.0)
		await m._shot("huge_%s" % id)
	print("HUGETEST RESULT fails=%d" % fails)

# kaya modelleri: kırık yüzlü, dokulu; yaz ve kış
func rock_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	for mp in ["green_valley", "winter_village"]:
		m.start_game(mp, {}, true)
		G.fog_off = true
		var c := G.grid.nearest_free(Vector3(G.MAP * 0.5 + 20, 0, G.MAP * 0.5 + 20), Grid.M_HEAVY)
		for k in 14:
			var a := k * 0.9
			var p := c + Vector3(cos(a), 0, sin(a)) * (2.0 + k * 0.45)
			G.props.rock(G.on_ground(p), 0.5 + (k % 5) * 0.3)
		var sq := m.spawn_soldier(G.player_team, "rifle", c + Vector3(1.5, 0, 0), null)
		await m._wait(0.6)
		_cam(c, 10.0)
		await m._wait(0.4)
		await m._shot("rock_%s_close" % mp)
		_cam(c, 24.0)
		await m._shot("rock_%s_mid" % mp)
		print("ROCK map=%s soldier=%s" % [mp, sq != null])
	print("ROCKTEST RESULT fails=0")
