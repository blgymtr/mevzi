class_name Tests07 extends RefCounted
# Hotfix 0.0.7 sahne testleri: --scene=treetest | yieldtest | dronetest | woundtest | ropetest | evadetest | crewtest

var m: Main

func _init(main: Main) -> void:
	m = main

func run(scene: String) -> void:
	m.start_units = false
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
		"para2test":
			await para2_test()
		"ammotest":
			await ammo_test()
		"stucktest":
			await stuck_test()
		"fftest":
			await ff_test()
		"perftest":
			await perf_test()
		"tactest":
			await tac_test()
		"largetest":
			await large_test()
		"hugetest":
			await huge_test()
		"rocktest":
			await rock_test()
		"mapprof":
			await map_prof()
		"lostest":
			await los_test()
		"icontest":
			await icon_test()
		"spottest":
			await spot_test()
		"rangetest":
			await range_test()
		"missiletest":
			await missile_test()
		"aimatch":
			await ai_match()
		"basegallery":
			await base_gallery()
		"enginetest":
			await engine_test()
		"perf8k":
			await perf_8k()
		"mounttest":
			await mount_test()
		"rotortest":
			await rotor_test()
		"killtest":
			await kill_test()
		"tracktest":
			await track_test()
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

# test hızlandırma: kareler arası çizimi kapat, yalnız Main._shot çizsin. llvmpipe'ta 1280x720 bir kare
# ~2-7 sn sürer (oyun mantığı ~15-30 ms); döngüler çizimle birlikte 1500 sn sınırını aşıyordu.
# Savaş sisi "keşfedildi" katmanı yalnız çizilen karelerde birikir: fow_test'te kullanma.
func _fast() -> void:
	RenderingServer.render_loop_enabled = false

# teşhis: duman perdeleri yok sayılarak görüş hattı (yalnız arazi/engel yüksekliği)
func _los_nosmoke(a: Vector3, b: Vector3) -> bool:
	var sm: Array = G.smokes
	G.smokes = []
	var r := G.grid.los(a, b, 0.75, 0.5)
	G.smokes = sm
	return r

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
		print("DRONE dbg state=%s job=%s cd=%.1f fpv=%d fight=%s alive=%s hp=%.0f target=%s attacker=%s last_hit=%.1f now=%.1f" % [op.state, op.drone_job, op.drone_cd, op.fpv_left, op.can_fight(), op.alive, op.hp, op.target, (op.attacker.title if op.attacker != null and is_instance_valid(op.attacker) else "?"), op.last_hit, G.time])
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
	# 2 kişilik ekip (roadmap 8): istasyoncu + kumandalı pilot; istasyoncu düşerse pilot devralır
	var sq := Squad.new(G.player_team, "Drone Ekibi")
	G.squads.append(sq)
	var c2 := G.grid.nearest_free(c + Vector3(-20, 0, -14), Grid.M_INF)
	var op2: Soldier = m.spawn_soldier(G.player_team, "drone", c2, sq)
	var pl2: Soldier = m.spawn_soldier(G.player_team, "drone", G.grid.nearest_free(c2 + Vector3(2, 0, 0), Grid.M_INF), sq)
	op2.cmd_station(c2 + Vector3(-4, 0, 3))
	await m._wait(26.0)
	var st2: DroneStation = op2.station
	var u2 = st2.uav if st2 != null else null
	var spun := false
	if u2 != null and is_instance_valid(u2) and not u2.props_n.is_empty():
		var b0: Basis = u2.props_n[0][0].transform.basis
		await m._wait(0.3)
		spun = not u2.props_n[0][0].transform.basis.is_equal_approx(b0)
	var piloting: bool = pl2.drone_job == "pilot" and pl2._piloting()
	_cam(st2.position if st2 != null else c2, 14.0)
	await m._wait(0.4)
	await m._shot("drone_05_crew")
	op2.die(null)
	await m._wait(1.5)
	var took_over: bool = st2 != null and st2.operator == pl2 and u2 != null and is_instance_valid(u2) and not u2.link_lost
	print("DRONE crew uav=%s props_spin=%s pilot=%s takeover=%s" % [u2 != null, spun, piloting, took_over])
	if u2 == null or not spun or not piloting or not took_over:
		fails += 1
	print("DRONETEST RESULT fails=%d" % fails)

# karadan havaya füze: helikopter fişek atar + kırar; İHA manevra; Hellfire/Vikhr görünümü
func evade_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	_fast()
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
	m.test_phase("evade_sam")
	for i in 240:
		await m._wait(0.05)
		var nsam := G.bal.projs.filter(func(p): return p.kind == "sam").size()
		var nfl := G.bal.projs.filter(func(p): return p.kind == "flare").size()
		if nsam > 0:
			seen_sam = true
		if i % 30 == 0:
			print("EVADE loop i=%d ms=%d fps=%d projs=%d heli=%s" % [i, Time.get_ticks_msec(), Engine.get_frames_per_second(), G.bal.projs.size(), is_instance_valid(heli) and heli.alive])
			print("EVADE aa tgt=%s seen=%s dist=%.0f rng=%.0f sam_r=%.0f sams=%d cd=%.2f samcd=%.2f atgmcd=%.2f think=%.2f proc=%s gt=%.2f yaw=%.2f alive=%s hp=%.0f by=%s" % [aa.target.title if aa.target != null else "-", G.is_seen(heli, 0), aa.dist2(heli), aa._range(), aa.sam_range, aa.sams, aa.main_cd, aa.sam_cd, aa.atgm_cd, aa.think_t, aa.is_processing(), G.time, aa.turret_yaw, aa.alive, aa.hp, (aa.attacker.title if aa.attacker != null and is_instance_valid(aa.attacker) else "-")])
		if (nsam > 0 or nfl > 0) and shot_n < 4 and i % 6 == 0:
			if is_instance_valid(heli):
				_cam(heli.position + Vector3(0, heli.hull.position.y, 0), 34.0)
			await m._shot("evade_%02d" % shot_n)
			shot_n += 1
		# başarı ölçütü sağlandı ya da helikopter düştü: kalan döngüyü bekleme
		if seen_sam and shot_n >= 4 and is_instance_valid(heli) and heli.flares < flares0:
			break
		if not is_instance_valid(heli) or not heli.alive:
			break
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
	m.test_phase("evade_hellfire")
	# oyun süresiyle sınırlı: görüş hattı kapalıysa helikopter hedef çevresinde atış açısı arar (bkz. Vehicle._attack_spot)
	var th := G.time
	var dbg_h := -9.0
	while G.time - th < 40.0:
		await m._wait(0.05)
		if not is_instance_valid(h2) or not is_instance_valid(tk):
			break
		if G.time - dbg_h > 2.0:
			dbg_h = G.time
			var eye := h2.turret_world_pos() + Vector3(0, 0.4, 0)
			print("EVADE dbg t=%.1f tgt=%s hf=%d cd=%.1f dist=%.0f seen=%s los=%s los_nosmoke=%s smokes=%d atk_n=%d atk_r=%.0f tk_alive=%s" % [G.time - th, h2.target != null, h2.hf_left, h2.hf_cd, h2.dist2(tk), G.is_seen(tk, h2.team), G.grid.los(eye, tk.aim_point(), h2.D["len"] * 0.5, 0.5), _los_nosmoke(eye, tk.aim_point()), G.smokes.size(), h2.atk_n, h2.atk_r, tk.alive])
		var ms: Array = G.bal.projs.filter(func(p): return p.kind == "atgm" and p.src == h2)
		if not ms.is_empty() and not shot_h and ms[0].t > 0.35:
			shot_h = true
			_cam(ms[0].pos, 14.0)
			await m._shot("evade_10_hellfire")
			_cam(ms[0].pos, 30.0)
			await m._wait(0.3)
			await m._shot("evade_11_hellfire_trail")
			break
		if not is_instance_valid(h2) or not h2.alive:
			break
	print("EVADE hellfire_seen=%s" % shot_h)
	if not shot_h:
		fails += 1
	# görüş hattı kapalı hedef: tankın çevresinde 6 m yüksek engel halkası, yalnız batıda (helikopterin
	# tersinde) boşluk. Helikopter doğudan gelir; ilk atış konumundan göremez → hedef çevresinde açı
	# arayıp boşluğu bulmalı (Vehicle._attack_spot). Eskiden aynı noktada sonsuza dek asılı kalıyordu.
	var fp := G.grid.nearest_free(c + Vector3(-60, 0, 60), Grid.M_HEAVY)
	var tk2: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b3", fp, 0.0)
	tk2.cmd_hold()
	tk2.fire_mode = 2
	tk2.hp = 99999.0
	for k in 60:
		var a := k * TAU / 60.0
		if absf(angle_difference(a, PI)) < deg_to_rad(40.0):
			continue
		G.grid.set_static_circle(fp + Vector3(cos(a), 0, sin(a)) * 6.0, 0.45, 6.0, Grid.K_WALL)
	var h3: Vehicle = m.spawn_vehicle(0, "heli", G.grid.nearest_free(fp + Vector3(60, 0, 0), Grid.M_HEAVY), 0.0)
	h3.cmd_attack(tk2)
	m.test_phase("evade_blocked")
	var tf := G.time
	var fired := false
	var blind0 := false
	while G.time - tf < 90.0:
		await m._wait(0.1)
		if not is_instance_valid(h3) or not h3.alive or not is_instance_valid(tk2):
			break
		if G.time - tf > 6.0 and G.time - tf < 6.2:
			blind0 = h3.target == null
		if h3.hf_left < 8 or G.bal.projs.any(func(p): return p.src == h3):
			fired = true
			break
	var hok := is_instance_valid(h3)
	print("EVADE blocked fired=%s t=%.1f blind_at_first_spot=%s atk_n=%d atk_r=%.0f bearing=%.0f" % [fired, G.time - tf, blind0, h3.atk_n if hok else -1, h3.atk_r if hok else -1.0, rad_to_deg(atan2(h3.position.z - fp.z, h3.position.x - fp.x)) if hok else 0.0])
	if not fired:
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
	_fast()
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
	m.test_phase("rope_down")
	for i in 600:
		await m._wait(0.05)
		var on_rope := sq.members.filter(func(x): return x.state == "rope")
		if not on_rope.is_empty() and shots < 4 and i % 14 == 0:
			_cam(on_rope[0].position, 10.0 if shots % 2 == 0 else 16.0)
			await m._wait(0.05)
			await m._shot("rope_%02d" % shots)
			shots += 1
		landed = sq.members.filter(func(x): return x.state != "rope" and x.vehicle_in == null and x.position.y < 0.05).size()
		if not is_instance_valid(h) or not h.alive:
			break
		if landed == 8 and h.ropes.is_empty():
			break
	if not is_instance_valid(h) or not h.alive:
		print("ROPE heli lost landed=%d" % landed)
		print("ROPETEST RESULT fails=%d" % (fails + 1))
		return
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
	m.test_phase("rope_spies")
	h.cmd_rope_pick(c)
	var up_shot := false
	for i in 900:
		await m._wait(0.05)
		var ups := sq.members.filter(func(x): return x.state == "rope_up")
		if ups.size() >= 3 and not up_shot and ups[0].position.y > 3.0:
			up_shot = true
			_cam(ups[0].position, 16.0)
			await m._shot("rope_11_spies")
		# helikopter yok, alım bitti/iptal (halat kesildi) ya da dolu: kalan döngüyü bekleme
		if not is_instance_valid(h) or not h.alive or h.cargo.size() >= 8 or (h.rope_mode == "" and i > 10):
			break
	var hv := is_instance_valid(h)
	var extracted: int = h.cargo.size() if hv else 0
	var sts: Array = sq.members.filter(func(x): return is_instance_valid(x)).map(func(x): return "%s/%s" % [x.state, x.order])
	print("ROPE extracted=%d rope_t=%.1f members=%s" % [extracted, h.rope_t if hv else -1.0, " ".join(sts)])
	if extracted < 6:
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
	# hedef topun kendi görüşü içinde olmalı (sahra topu: görüş 40 m, menzil 64 m); G.reveal yalnız yapıları
	# açar — 45 m'deki tank hiç görülmüyordu, top hedef almıyor, döngü hiç başlamıyordu
	var tk: Vehicle = m.spawn_vehicle(1 - G.player_team, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(0, 0, -32), Grid.M_HEAVY), 0.0)
	tk.cmd_hold()
	tk.fire_mode = 2
	tk.hp = 99999.0
	gun.cmd_attack(tk)
	_cam(c, 9.0)
	var marks := [0.04, 0.35, 0.55, 0.8]
	var mi := 0
	var cycles := 0
	var last_cd := 0.0
	var t0 := G.time
	var dbg_t := -9.0
	# kare sayısıyla değil oyun süresiyle sınırlı (yazılım çiziminde kare başına 0.13 sn oyun zamanı geçer)
	while G.time - t0 < 45.0 and mi < marks.size():
		await m._wait(0.03)
		if G.time - dbg_t > 3.0:
			dbg_t = G.time
			print("CREW dbg t=%.1f ms=%d fps=%d cycle=%.1f cd=%.2f cycles=%d tgt=%s seen=%s" % [G.time - t0, Time.get_ticks_msec(), Engine.get_frames_per_second(), gun.crew_cycle, gun.main_cd, cycles, gun.target != null, G.is_seen(tk, gun.team)])
		if gun.crew_cycle > 0.0 and gun.main_cd > last_cd + 0.5:
			cycles += 1
		last_cd = gun.main_cd
		# hızlı başarısızlık: 15 sn'de ilk atış yoksa nedenini yaz, boşuna bekleme
		if cycles == 0 and G.time - t0 > 15.0:
			print("CREW no fire: seen=%s dist=%.1f sight=%.1f range=%.1f tgt=%s order=%s deployed=%.2f" % [G.is_seen(tk, gun.team), gun.dist2(tk), gun.sight, gun._range(), gun.target != null, gun.order, gun.deployed])
			var eye := gun.turret_world_pos() + Vector3(0, 0.4, 0)
			print("CREW dbg2 vis=%d los=%s smokes=%d gunner_ok=%s crew=%d/%d hold=%s fire_mode=%d abandon=%.1f retreat=%s" % [G.visible_enemies(gun.team).size(), G.grid.los(eye, tk.aim_point(), gun.D["len"] * 0.5, 0.5), G.smokes.size(), gun.gunner_ok, gun.crew_n, gun.crew_max, gun.order, gun.fire_mode, gun.abandon_t, gun.retreating])
			break
		if cycles >= 2:
			var p := 1.0 - gun.main_cd / gun.crew_cycle
			if p >= marks[mi] and p < marks[mi] + 0.08:
				await m._shot("crew_%02d" % mi)
				mi += 1
	print("CREW cycles=%d shots=%d t=%.1f" % [cycles, mi, G.time - t0])
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
	var t1 := G.time
	while G.time - t1 < 40.0 and apc.cargo.size() < 6:
		await m._wait(0.05)
		if not shot_in and ss.any(func(x): return x.state == "entering"):
			shot_in = true
			await m._shot("crew_10_board")
	print("CREW boarded=%d t=%.1f" % [apc.cargo.size(), G.time - t1])
	if apc.cargo.size() < 6:
		fails += 1
	apc.unload()
	var shot_out := 0
	var t2 := G.time
	var n := 0
	while G.time - t2 < 20.0:
		await m._wait(0.05)
		n += 1
		if shot_out < 2 and ss.filter(func(x): return x.state == "exiting" and x.visible).size() > 0 and n % 3 == 0:
			await m._shot("crew_%02d_exit" % (11 + shot_out))
			shot_out += 1
		if G.time - t2 > 4.0 and ss.all(func(x): return x.vehicle_in == null and x.state != "exiting"):
			break
	var out := ss.filter(func(x): return x.vehicle_in == null and x.state != "exiting").size()
	print("CREW unloaded=%d exit_shots=%d t=%.1f" % [out, shot_out, G.time - t2])
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

# paraşüt sağlamlığı: nehre / binaya / harita köşesine düşen, havada yaralanan / ölen / patlamada
# kalan, havada emir alan ve dev kare süresiyle işlenen paraşütçülerin hepsi sınırlı sürede
# harita içinde boş bir zemin hücresine iner (ölüler: ceset zemine)
func para2_test() -> void:
	m.get_window().size = Vector2i(480, 270)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	# haritanın ortasına en yakın nehir hücresi
	var wp := Vector3.INF
	for z in range(2, int(G.MAP) - 2, 2):
		for x in range(2, int(G.MAP) - 2, 2):
			var p := Vector3(x + 0.5, 0, z + 0.5)
			if G.grid.is_water(p) and (wp == Vector3.INF or p.distance_to(c) < wp.distance_to(c)):
				wp = p
	var hq: Vector3 = G.hq_pos[0]
	var sq := Squad.new(G.player_team, "P2")
	G.squads.append(sq)
	# "hurt": vurulup düşer (yüzde 30 havada ölür, yoksa kubbe altında yaralı iner) — üç kez
	var cases := ["water", "hq", "corner", "hurt", "kill", "blast", "order", "bigdt", "hurt", "hurt"]
	var ss: Array = []
	for i in cases.size():
		var k: String = cases[i]
		var at := c + Vector3((i % 4) * 6.0 - 9.0, 0, (i / 4) * 6.0)
		var goal := at
		if k == "water" and wp != Vector3.INF:
			at = wp
			goal = wp
		elif k == "hq":
			at = hq
			goal = hq
		elif k == "corner":
			at = Vector3(-15, 0, -15)
			goal = Vector3(-40, 0, -40)
		var s: Soldier = m.spawn_soldier(G.player_team, "rifle", at, sq)
		s.start_para(at + Vector3(0, 40, 0), Vector3.ZERO, goal)
		# rüzgâr hedefi dolu hücreye itmiş gibi: yön noktası da dolu hücre
		if k in ["water", "hq", "corner"]:
			s.para_goal = goal
		ss.append(s)
	print("P2 water=%s hq=%s c=%s" % [wp, hq, c])
	var t0 := G.time
	var seen_w := {}
	var hurt_done := false
	var shot := false
	while G.time - t0 < 40.0:
		await m._wait(0.1)
		var el := G.time - t0
		if not hurt_done and el > 3.0:
			hurt_done = true
			for i in cases.size():
				if cases[i] == "hurt":
					ss[i].take_damage(110.0, null)
			ss[4].die(null)
			ss[5].on_blast(ss[5].position + Vector3(1.5, 0, 0), 6.0, 300.0, 1.5, null)
			ss[6].cmd_move(c + Vector3(10, 0, -10))
			for st in 4:
				if ss[7].state == "para":
					ss[7]._para_process(2.5)
			print("P2 mid: hurt=%s/%s,%s/%s,%s/%s kill=%s blast=%s/%s/y=%.1f order=%s bigdt=%s/ph=%d/y=%.1f" % [ss[3].state, ss[3].para_hurt, ss[8].state, ss[8].para_hurt, ss[9].state, ss[9].para_hurt, ss[4].alive, ss[5].state, ss[5].alive, ss[5].position.y, ss[6].state, ss[7].state, ss[7].para_phase, ss[7].position.y])
		if not shot and el > 4.0:
			shot = true
			_cam(ss[0].position, 30.0)
			await m._wait(0.1)
			await m._shot("para2_00")
		for i in ss.size():
			if is_instance_valid(ss[i]) and ss[i].state == "wounded":
				seen_w[i] = true
		var air := ss.filter(func(x): return is_instance_valid(x) and x.alive and x.state == "para")
		if air.is_empty() and el > 14.0:
			break
	await m._wait(8.0)
	var el := G.time - t0
	for i in ss.size():
		var s: Soldier = ss[i]
		if not is_instance_valid(s):
			print("P2 %s freed" % cases[i])
			fails += 1
			continue
		var ok := false
		if s.alive:
			ok = s.state != "para" and G.grid.free_at(s.position, Grid.M_INF) and s.position.y < 0.3
		else:
			ok = s.position.y < 0.6 and s.canopy == null
		print("P2 %s ok=%s alive=%s st=%s wounded_seen=%s p=%s free=%s h=%.2f" % [cases[i], ok, s.alive, s.state, seen_w.has(i), s.position, G.grid.free_at(s.position, Grid.M_INF), G.grid.height_at(s.position)])
		if not ok:
			fails += 1
	if ss[6].alive and Vector2(ss[6].dest.x - c.x - 10.0, ss[6].dest.z - c.z + 10.0).length() > 3.0:
		print("P2 order lost: dest=%s" % ss[6].dest)
		fails += 1
	_cam(c, 30.0)
	await m._wait(0.1)
	await m._shot("para2_10")
	print("P2 elapsed=%.1f" % el)
	print("PARA2TEST RESULT fails=%d" % fails)

# gerçek performans verisi (roadmap 2): azami hız = km/h ÷ 3,6 × ölçek; tekerlekli araç yolda araziden hızlı;
# ana top dolum süresi ve otomatik top atış aralığı veriden
func perf_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	_fast()
	# yol: toplam boyu ≥ 90 m olan ilk çoklu çizginin ilk 90 m'si
	var route := PackedVector3Array()
	for r in G.mapgen.roads:
		var pts: PackedVector3Array = r
		var L := 0.0
		for i in pts.size() - 1:
			L += pts[i].distance_to(pts[i + 1])
		if L < 150.0:
			continue
		var acc := 0.0
		route.append(pts[0])
		for i in range(1, pts.size()):
			acc += pts[i - 1].distance_to(pts[i])
			route.append(pts[i])
			if acc >= 150.0:
				break
		break
	var dir := (route[1] - route[0]).normalized()
	var ids := ["usa_mbt_a1", "usa_apc_icv", "usa_lv_m1151"]
	var rows: Array = []
	for k in ids.size():
		# yol testi yalnız tekerlekli HMMWV ile (konvoyda öndeki yavaş araç arkadakini bekletir)
		var vr: Vehicle = m.spawn_vehicle(G.player_team, ids[k], route[0] if k == 2 else G.grid.nearest_free(route[0] - Vector3(-dir.z, 0, dir.x) * (90.0 + k * 12.0), Grid.M_HEAVY), Soldier._yaw_of(dir))
		if k == 2:
			vr.follow_route(route)
		# arazi: yoldan uzak, düz 70 m
		var side := Vector3(-dir.z, 0, dir.x) * (45.0 + k * 10.0)
		var vo: Vehicle = m.spawn_vehicle(G.player_team, ids[k], G.grid.nearest_free(route[0] + side, Grid.M_HEAVY), Soldier._yaw_of(dir))
		vo.cmd_move(G.grid.nearest_free(vo.position + dir * 70.0, Grid.M_HEAVY))
		rows.append([ids[k], vr, vo, 0.0, 0.0, -1.0])
	var t0 := G.time
	while G.time - t0 < 26.0:
		await m._wait(0.1)
		for rw in rows:
			var vr2: Vehicle = rw[1]
			var vo2: Vehicle = rw[2]
			if vr2._on_road:
				rw[3] = maxf(rw[3], absf(vr2.cur_speed))
			if not vo2._on_road:
				rw[4] = maxf(rw[4], absf(vo2.cur_speed))
			if rw[5] < 0.0 and absf(vo2.cur_speed) >= 4.4:
				rw[5] = G.time - t0       # 4,4 m/sn (≈ 32 km/h × 0,5) varış süresi
	for rw in rows:
		var v: Vehicle = rw[1]
		var pf := Catalog.perf(rw[0])
		print("PERF %s road=%.1f/%.1f off=%.1f/%.1f t32=%.1fs(data %.1f) reload=%.1f" % [rw[0], rw[3], v.road_speed, rw[4], v.speed_max, rw[5], float(pf.get("acc", 0)), v.reload_s])
		if absf(v.speed_max - float(pf["off"]) / 3.6 * Catalog.K_GROUND) > 0.05:
			fails += 1
		if rw[2].speed_max > 0.0 and (rw[4] > v.speed_max + 0.3 or rw[3] > v.road_speed + 0.3):
			fails += 1
	# yol hızı: yoldaki noktada azami hız yol hızı (HMMWV 113 km/h), arazide arazi hızı (65 km/h)
	var hm: Vehicle = rows[2][2]
	hm.position = route[0]
	hm._road_t = 0.0
	var on_r := hm._vmax(0.0)
	hm.position = rows[2][2].position + Vector3(-dir.z, 0, dir.x) * 30.0
	hm._road_t = 0.0
	var off_r := hm._vmax(0.0)
	print("PERF vmax road=%.1f off=%.1f (beklenen %.1f / %.1f)" % [on_r, off_r, hm.road_speed, hm.speed_max])
	if absf(on_r - hm.road_speed) > 0.01 or (G.terrain.on_road(hm.position) == false and absf(off_r - hm.speed_max) > 0.01):
		fails += 1
	print("PERFTEST RESULT fails=%d" % fails)

# dost ateşi kuralı (roadmap 27): kendi aracının patlaması kendi askerine zarar vermez (yalnız bastırır);
# bina patlaması iki tarafa da zarar verir
func ff_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	_fast()
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var f1: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(2, 0, 0), Grid.M_INF), null)
	var e1: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(-2, 0, 0), Grid.M_INF), null)
	await m._wait(0.3)
	var f_hp := f1.hp
	var f_sup := f1.suppression
	G.explode(c + Vector3(0, 1.0, 0), 6.5, 90.0, "big", 0, null, 0)   # 0. takımın aracı patladı
	await m._wait(1.0)
	var f_ok := f1.alive and f1.hp >= f_hp - 0.01 and f1.state != "fly"
	var f_sup_ok := f1.suppression > f_sup
	var e_hit := not e1.alive or e1.hp < e1.max_hp or e1.state in ["fly", "wounded", "dazed"]
	print("FF vehicle_blast friendly_unhurt=%s friendly_suppressed=%s enemy_hit=%s" % [f_ok, f_sup_ok, e_hit])
	if not f_ok or not e_hit or not f_sup_ok:
		fails += 1
	var b: Building = m.place_building(0, "barracks", G.grid.nearest_free(c + Vector3(0, 0, 40), Grid.M_HEAVY), 0.0)
	b.add_work(99999.0)
	var f2: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(b.position + Vector3(b.radius * 0.6, 0, 0), Grid.M_INF), null)
	var e2: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(b.position - Vector3(b.radius * 0.6, 0, 0), Grid.M_INF), null)
	await m._wait(0.3)
	b.destroy(null)
	await m._wait(1.0)
	var hit := func(s: Soldier) -> bool: return not s.alive or s.hp < s.max_hp or s.state in ["fly", "wounded", "dazed"]
	print("FF building_blast friendly_hit=%s enemy_hit=%s d=%.1f/%.1f r=%.1f" % [hit.call(f2), hit.call(e2), f2.position.distance_to(b.position), e2.position.distance_to(b.position), b.radius * 0.8 + 2.0])
	if not hit.call(f2) or not hit.call(e2):
		fails += 1
	print("FFTEST RESULT fails=%d" % fails)

# Faz 0 takılma bekçisi + emir geri bildirimi (oyun süresiyle sınırlı, ~70 sn)
func stuck_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	_fast()
	G.reveal = [999.0, 999.0]
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	# (1) asker: hedefi duvarın ardında; yol ızgarası geçit sanıyor (kapı işareti) ama ince ızgarada duvar
	#     kesintisiz → asker duvara dayanıp kalır. Bekçi: 8 sn'de yeniden yol, 30 sn'de vazgeç.
	var wa := c + Vector3(-30, 0, -20)
	for k in 9:
		G.grid.set_static_circle(wa + Vector3(k * 0.4 - 1.6, 0, 0), 0.35, 2.4, Grid.K_WALL)
	G.grid.mark_door(wa, Vector3(1, 0, 0), 2.0)
	G.grid.flush_nav()
	var s1: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(wa + Vector3(0, 0, -6), Grid.M_INF), null)
	s1.cmd_move(wa + Vector3(0, 0, 6))
	# (2) araç: her yanı duvarla kapalı kutuda, kutunun dışına gitmesi emredilir → itip durur
	var vb := G.grid.nearest_free(c + Vector3(30, 0, -20), Grid.M_HEAVY)
	var v1: Vehicle = m.spawn_vehicle(G.player_team, "apc", vb, 0.0)
	v1.cmd_move(G.grid.nearest_free(vb + Vector3(0, 0, 30), Grid.M_HEAVY))
	# yol bulunduktan sonra kutuya kapat: yol dışarıyı gösterir, araç fiziksel olarak çıkamaz
	for k in 28:
		var a := k * TAU / 28.0
		G.grid.set_static_circle(vb + Vector3(cos(a) * 4.2, 0, sin(a) * 4.2), 0.5, 2.6, Grid.K_HOUSE)
	G.grid.flush_nav()
	print("STUCK vehicle path=%d order=%s" % [v1.path.size(), v1.order])
	# (3) sedye: hastane + yanında yaralı; sedye taşınırken hastane yıkılır
	var hp: Building = m.place_building(G.player_team, "hospital", G.grid.nearest_free(c + Vector3(0, 0, 30), Grid.M_HEAVY), 0.0)
	hp.add_work(99999.0)
	var wnd: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(hp.position + Vector3(14, 0, 4), Grid.M_INF), null)
	wnd.take_damage(110.0, null)
	# (4) uçaksavar topuna tank: emir reddedilir (sessiz bekleme yok)
	var aag: Vehicle = m.spawn_vehicle(G.player_team, "aagun", G.grid.nearest_free(c + Vector3(-20, 0, 25), Grid.M_HEAVY), 0.0)
	var tk: Vehicle = m.spawn_vehicle(1 - G.player_team, "tank", G.grid.nearest_free(c + Vector3(-20, 0, 55), Grid.M_HEAVY), PI)
	tk.cmd_hold()
	tk.fire_mode = 2
	tk.hp = 99999.0
	aag.cmd_attack(tk)
	var refused := aag.forced_target == null and aag.order != "attack"
	# (5) "ateş kes"teki tank, açık saldırı emriyle ateş eder
	var t2: Vehicle = m.spawn_vehicle(G.player_team, "tank", G.grid.nearest_free(c + Vector3(-5, 0, 25), Grid.M_HEAVY), 0.0)
	t2.fire_mode = 2
	t2.cmd_hold()
	t2.cmd_attack(tk)
	# (6) asgari menzil içindeki hedefe çekili obüs: emir bırakılır
	var hw: Vehicle = m.spawn_vehicle(G.player_team, "howitzer", G.grid.nearest_free(tk.position + Vector3(14, 0, -10), Grid.M_HEAVY), 0.0)
	hw.cmd_attack(tk)
	m.test_phase("stuck")
	var t0 := G.time
	var hosp_killed := false
	var s1_t := -1.0
	var v1_t := -1.0
	var t2_fired := false
	var str_ok := false
	while G.time - t0 < 75.0:
		await m._wait(0.25)
		var el := G.time - t0
		if s1_t < 0.0 and s1.state != "move":
			s1_t = el
		if v1_t < 0.0 and v1.order == "":
			v1_t = el
		if t2.main_cd > 0.5:
			t2_fired = true
		if not hosp_killed and hp.job != null and hp.job.stage == "carry":
			hosp_killed = true
			var bs: Array = [hp.job.a, hp.job.b]
			hp.destroy(null)
			await m._wait(0.5)
			str_ok = bs.all(func(b): return not is_instance_valid(b) or not b.alive or b.state != "stretcher") and (not wnd.alive or wnd.state != "stretchered")
			print("STUCK stretcher dropped=%s wounded_state=%s" % [str_ok, wnd.state])
		if s1_t >= 0.0 and v1_t >= 0.0 and t2_fired and (hosp_killed or el > 60.0):
			break
	print("STUCK soldier_resolved_at=%.1f state=%s order=%s" % [s1_t, s1.state, s1.order])
	print("STUCK vehicle_resolved_at=%.1f order=%s" % [v1_t, v1.order])
	print("STUCK aagun_refused=%s holdfire_attack_fired=%s howitzer_order=%s forced=%s" % [refused, t2_fired, hw.order, hw.forced_target != null])
	if s1_t < 0.0 or s1_t > 40.0:
		fails += 1
	if v1_t < 0.0 or v1_t > 60.0:
		fails += 1
	if not refused or not t2_fired or hw.order == "attack":
		fails += 1
	if hosp_killed and not str_ok:
		fails += 1
	print("STUCK stretcher_tested=%s" % hosp_killed)
	print("STUCKTEST RESULT fails=%d" % fails)

# dolaylı atış görünümü: topçu/havan mermisi yüksek yayla çıkar (tepe ≥ 45 m), uçuşta top değil hareket
# bulanıklığı izi; isabette moloz köşeli parça dokusuyla. Eskiden ~7 m tepeli alçak yay: taş atar gibiydi.
func ammo_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true)
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var to := G.grid.nearest_free(c + Vector3(0, 0, -60), Grid.M_HEAVY)
	G.bal.artillery(c + Vector3(0, 1.5, 0), to, 0, null)
	G.bal.mortar(c + Vector3(4, 1.0, 0), to + Vector3(6, 0, 0), 0, null)
	var arty: Ballistics.Proj = null
	var mor: Ballistics.Proj = null
	for p in G.bal.projs:
		if p.kind == "arty":
			arty = p
		elif p.kind == "mortar":
			mor = p
	var apex := 0.0
	var apex_m := 0.0
	var blur := arty != null and (arty.node as MeshInstance3D).mesh == G.bal._blur_m
	var t0 := G.time
	var shot := 0
	_cam(to + Vector3(0, 0, 25), 60.0)
	while G.time - t0 < 16.0:
		await m._wait(0.05)
		if arty != null and is_instance_valid(arty.node):
			apex = maxf(apex, arty.pos.y)
			if shot < 2 and arty.vel.y < 0.0 and arty.pos.y < 40.0 - shot * 20.0:
				await m._shot("ammo_%02d_descent" % shot)
				shot += 1
		if mor != null and is_instance_valid(mor.node):
			apex_m = maxf(apex_m, mor.pos.y)
		if not G.bal.projs.any(func(p): return p.kind in ["arty", "mortar"]):
			break
	await m._wait(0.25)
	await m._shot("ammo_10_impact")
	var flight := G.time - t0
	print("AMMO arty_apex=%.1f mortar_apex=%.1f blur=%s flight=%.1f" % [apex, apex_m, blur, flight])
	if apex < 45.0 or apex_m < 40.0 or not blur:
		fails += 1
	# mühimmat tablosu (roadmap 6): ulusa göre mermi, gerçek hız oranı, iz rengi, delme, patlama yarıçapı
	var us: Vehicle = m.spawn_vehicle(0, "usa_mbt_a1", G.grid.nearest_free(c + Vector3(-30, 0, 30), Grid.M_HEAVY), 0.0)
	var ru: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b3", G.grid.nearest_free(c + Vector3(30, 0, 30), Grid.M_HEAVY), 0.0)
	var v_us := Ammo.speed(us.ammo_ke, 0.0)
	var v_ru := Ammo.speed(ru.ammo_ke, 0.0)
	var v_he := Ammo.speed(ru.ammo_he, 0.0)
	print("AMMO tank us=%s/%s ru=%s/%s v=%.0f/%.0f he=%.0f m/sn" % [us.ammo_ke, us.ammo_he, ru.ammo_ke, ru.ammo_he, v_us, v_ru, v_he])
	if us.ammo_ke != "120_apfsds" or ru.ammo_ke != "125_apfsds" or not (v_ru > v_us and v_us > v_he):
		fails += 1
	var tc0 := Ammo.team_tracer(0)
	var tc1 := Ammo.team_tracer(1)
	print("AMMO tracer usa=%s rus=%s" % [tc0.to_html(false), tc1.to_html(false)])
	if not (tc0.r > tc0.g and tc1.g > tc1.r):
		fails += 1
	# delme: APFSDS ana tankın önünü deler; 30 mm otomatik top delemez
	var p_us := 0.0
	var p_auto := 0.0
	Vehicle.shot_pen = Ammo.get_def("120_apfsds")["pen"]
	p_us = ru.pen_mult("ap", ru.position + ru.forward() * 40.0)
	Vehicle.shot_pen = Ammo.get_def("30_ru")["pen"]
	p_auto = us.pen_mult("auto", us.position + us.forward() * 40.0)
	print("AMMO pen 120_apfsds->T72 front=%.2f  30mm->M1 front=%.2f" % [p_us, p_auto])
	if p_us <= 0.0 or p_auto > 0.0:
		fails += 1
	var m110: Vehicle = m.spawn_vehicle(0, "usa_spg_m110", G.grid.nearest_free(c + Vector3(0, 0, 60), Grid.M_HEAVY), 0.0)
	var blast := float(Ammo.get_def(m110.ammo_he).get("blast", 0.0))
	print("AMMO m110=%s blast=%.1f" % [m110.ammo_he, blast])
	if blast < 8.0:
		fails += 1
	# roadmap 26: iz kalınlığı kalibreyle artar; yerden atılan roket/füzede motor alevi + ışık
	var cals := [5.56, 7.62, 12.7, 30.0, 125.0]
	var ws: Array = cals.map(func(k): return Ammo.tracer_dims(k).x)
	print("AMMO tracer_w %s" % str(ws))
	for i in range(1, ws.size()):
		if ws[i] <= ws[i - 1]:
			fails += 1
	var W: Weather = G.weather
	W.night = true
	W.set_kind_silent("clear")
	var rc := G.grid.nearest_free(c + Vector3(-40, 0, -20), Grid.M_INF)
	G.bal.rocket(rc + Vector3(0, 1.4, 0), rc + Vector3(0, 1.0, -70), 0, null, null, "rpg")
	G.bal.rocket(rc + Vector3(6, 1.0, 0), rc + Vector3(6, 1.0, -70), 1, null, ru, "atgm")
	G.bal.mlrs_rocket(rc + Vector3(-8, 2.5, 6), rc + Vector3(-8, 0, -160), 0, null)
	var lit := 0
	var flamed := 0
	for p in G.bal.projs:
		if p.kind in ["rpg", "atgm", "rkt"]:
			for ch in p.node.get_children():
				if ch is OmniLight3D:
					lit += 1
				elif ch is MeshInstance3D and (ch as MeshInstance3D).mesh == G.bal._flame_m:
					flamed += 1
	print("AMMO rockets flame=%d light=%d" % [flamed, lit])
	if flamed < 3 or lit < 3:
		fails += 1
	_cam(rc + Vector3(0, 0, -20), 34.0)
	await m._wait(0.35)
	await m._shot("ammo_20_rockets_night")
	W.night = false
	W.set_kind_silent("clear")
	print("AMMOTEST RESULT fails=%d" % fails)

# tim beyni: YZ timi uzun çatışmada kanattan dolanır, taban kolu baskı ateşi açar
func tac_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 1234)
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
		# saldıran tim savunmaya doğru saldırı hareketiyle gelir (gerçek menzilde 44 m tüfek menzilinin dışı)
		a.cmd_attack_move(G.grid.nearest_free(c + Vector3(i * 1.5, 0, -6), Grid.M_INF))
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
		# kare sayısıyla değil süreyle sınırlı: GPU'da 60 kare ~0,4 sn, 4 km'de tek A* ~300 ms sürer
		# (yazılım çiziminde 60 kare saniyelerdi). Yollar gelene kadar en çok 10 sn bekle.
		var worst := 0
		var last := Time.get_ticks_msec()
		var long_n := 0
		var frames := 0
		while Time.get_ticks_msec() - tq < 10000:
			await m.get_tree().process_frame
			frames += 1
			var now := Time.get_ticks_msec()
			worst = maxi(worst, now - last)
			last = now
			long_n = grp.filter(func(u): return u.path.size() >= 3).size()
			if long_n >= grp.size() and frames >= 60:
				break
		print("HUGE id=%s async=%s issue_ms=%d worst_frame_ms=%d units_with_full_path=%d/%d wait_ms=%d frames=%d" % [id, G.grid.wants_async(G.hq_pos[0], goal), issue_ms, worst, long_n, grp.size(), Time.get_ticks_msec() - tq, frames])
		if G.grid.wants_async(G.hq_pos[0], goal) and long_n < grp.size() - 1:
			fails += 1
		_cam(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), 115.0)
		G.fog_off = true
		await m._wait(1.0)
		await m._shot("huge_%s" % id)
	print("HUGETEST RESULT fails=%d" % fails)

# büyük harita ölçümü: yükleme aşamaları (süre, bellek, VRAM) ve yakınlaştırma düzeyine göre çizim
# yükü (çizim çağrısı, üçgen, nesne, kare süresi). --map=<id> ile harita seçilir (varsayılan airborne_4k).
func map_prof() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var id := "airborne_4k"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			id = a.substr(6)
	G.prof_on = true
	G._prof_t = Time.get_ticks_msec()
	var t0 := Time.get_ticks_msec()
	m.start_game(id, {}, true, 4242)
	G.prof("ready")
	G.prof_on = false
	print("MAPPROF id=%s map=%.0f load_ms=%d houses=%d props=%d units=%d" % [id, G.MAP, Time.get_ticks_msec() - t0, G.blocks.houses.size(), G.props.items.size(), G.units.size()])
	G.fog_off = true
	var c := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	for sz in [40.0, 115.0, 300.0, 800.0, 2000.0]:
		if sz > G.cam.max_size + 1.0:
			continue
		_cam(c, sz)
		await m._wait(0.6)
		var n := 0
		var t1 := Time.get_ticks_usec()
		var dc := 0.0
		var prim := 0.0
		var obj := 0.0
		while n < 90:
			await m.get_tree().process_frame
			n += 1
			dc += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			prim += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
			obj += Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)
		var ms := float(Time.get_ticks_usec() - t1) / 1000.0 / n
		print("MAPPROF zoom=%4.0f frame_ms=%.1f fps=%.0f draw=%d prim=%dk obj=%d grass_tiles=%d" % [sz, ms, 1000.0 / ms, int(dc / n), int(prim / n / 1000.0), int(obj / n), G.props._gtiles.size()])
		await m._shot("mapprof_%s_%d" % [id, int(sz)])
		# döküm: ot, gölge, ağaç, bina ayrı ayrı kapatılarak çizim payı
		if sz in [115.0, 2000.0]:
			for part in ["grass", "shadow", "trees", "blocks"]:
				_prof_toggle(part, false)
				await m._wait(0.2)
				var dc2 := 0.0
				var pr2 := 0.0
				var t2 := Time.get_ticks_usec()
				for k in 30:
					await m.get_tree().process_frame
					dc2 += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
					pr2 += Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME)
				print("MAPPROF   -%s frame_ms=%.1f draw=%d prim=%dk" % [part, float(Time.get_ticks_usec() - t2) / 1000.0 / 30.0, int(dc2 / 30.0), int(pr2 / 30.0 / 1000.0)])
				_prof_toggle(part, true)
	# ek görünümler: orman, köy, tarla, nehir geçidi (oran konumu, yakınlaştırma)
	var k := 0
	for v in [[0.16, 0.08, 400.0], [0.30, 0.30, 90.0], [0.72, 0.78, 700.0], [0.46, 0.17, 140.0], [0.535, 0.475, 90.0], [0.555, 0.477, 420.0]]:
		_cam(Vector3(G.MAP * v[0], 0, G.MAP * v[1]), v[2])
		await m._wait(1.2)
		await m._shot("mapprof_%s_view%d" % [id, k])
		k += 1
	print("MAPPROF RESULT fails=0")

# iri hücreli görüş hattı: ince adımlı eski yöntemle aynı sonucu vermeli; uzun ışında hız
func los_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	for id in ["green_valley", "large_front"]:
		m.start_game(id, {}, true, 99)
		var rng := RandomNumberGenerator.new()
		rng.seed = 5
		var bad := 0
		var n := 1500
		var t_new := 0
		var t_old := 0
		for i in n:
			var L := rng.randf_range(5.0, minf(G.MAP * 0.9, 900.0))
			var a := Vector3(rng.randf_range(2, G.MAP - 2), rng.randf_range(0.3, 2.6), rng.randf_range(2, G.MAP - 2))
			var ang := rng.randf() * TAU
			var b := a + Vector3(cos(ang) * L, 0, sin(ang) * L)
			b.x = clampf(b.x, 1, G.MAP - 1)
			b.z = clampf(b.z, 1, G.MAP - 1)
			b.y = rng.randf_range(0.3, 2.6)
			var Lr := Vector2(b.x - a.x, b.z - a.z).length()
			var t0 := Time.get_ticks_usec()
			var r1 := G.grid.los(a, b)
			var t1 := Time.get_ticks_usec()
			var r2 := G.grid._los_fine(a, b, 0.0, 1.0, Lr, 0.75, 0.3)
			var t2 := Time.get_ticks_usec()
			t_new += t1 - t0
			t_old += t2 - t1
			if r1 != r2:
				bad += 1
		print("LOS map=%s n=%d mismatch=%d new_us=%.1f old_us=%.1f" % [id, n, bad, float(t_new) / n, float(t_old) / n])
		if bad > n / 200:
			fails += 1
	print("LOSTEST RESULT fails=%d" % fails)

# stratejik görüş simgeleri: büyük haritada iki tarafın timleri ve araçları, uzaktan sembol olarak
func icon_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("front_2k", {}, true, 7)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	for t in 2:
		var side := -1.0 if t == 0 else 1.0
		for k in 3:
			var sq := Squad.new(t, "Tim")
			G.squads.append(sq)
			for i in 6:
				m.spawn_soldier(t, ["leader", "rifle", "rifle", "mg", "at", "rifle"][i], G.grid.nearest_free(c + Vector3(side * 120.0 + i * 2.0, 0, k * 40.0 - 40.0), Grid.M_INF), sq)
		for k in 3:
			m.spawn_vehicle(t, ["usa_mbt_a1", "usa_ifv_m2a3", "usa_spg_a6"][k] if t == 0 else ["rus_mbt_72b3", "rus_ifv_bmp2", "rus_spg_msta"][k], G.grid.nearest_free(c + Vector3(side * 180.0, 0, k * 30.0 - 30.0), Grid.M_HEAVY), 0.0)
	G.fog_off = true
	for sz in [120.0, 400.0, 900.0]:
		_cam(c, sz)
		await m._wait(0.6)
		await m._shot("icon_%d" % int(sz))
	var ic: TacIcons = G.hud.icons
	print("ICON active=%s hits=%d" % [ic.active(), ic._hits.size()])
	if not ic.active() or ic._hits.size() < 10:
		fails += 1
	# simgeye tıklama: ilk dost tim simgesi seçilebilmeli
	var picked: Unit = null
	for h in ic._hits:
		var u: Unit = h[1]
		if u.team == G.player_team:
			picked = G.player.unit_at(h[0], true)
			break
	print("ICON pick=%s" % (picked.name if picked != null else "yok"))
	if picked == null:
		fails += 1
	print("ICONTEST RESULT fails=%d" % fails)

# tespit modeli (roadmap 50): menzil sınırı, duruş, ateş, görüş hattı, gece/termal
func spot_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("front_2k", {}, true, 31)
	G.weather.night = false
	# açık, düz bir şerit bul: 0'dan 1,6 R'ye kadar görüş hattı açık
	var obs_p := Vector3.INF
	var dir := Vector3.RIGHT
	var rng := RandomNumberGenerator.new()
	rng.seed = 3
	var tank_R := Combat.detect_range(Combat.optic("th3"), 1.0)
	for i in 400:
		var p := Vector3(rng.randf_range(200, G.MAP - 200), 0, rng.randf_range(200, G.MAP - 200))
		var a := rng.randf() * TAU
		var d := Vector3(cos(a), 0, sin(a))
		var far := p + d * minf(tank_R * 1.2, G.MAP * 0.4)
		if far.x < 20 or far.z < 20 or far.x > G.MAP - 20 or far.z > G.MAP - 20:
			continue
		if G.grid.los(p + Vector3(0, 2.6, 0), far + Vector3(0, 0.3, 0), 2.0, 0.3) and G.props.veg_count(p, 10.0) == 0 and G.props.veg_count(far, 10.0) == 0:
			obs_p = p
			dir = d
			break
	print("SPOT strip=%s tank_R=%.0f K=%.3f" % [obs_p != Vector3.INF, tank_R, Combat.K_DETECT])
	if obs_p == Vector3.INF:
		print("SPOTTEST RESULT fails=1")
		return
	var ob: Vehicle = m.spawn_vehicle(0, "usa_mbt_s3", G.grid.nearest_free(obs_p, Grid.M_HEAVY), 0.0)
	ob.cmd_hold()
	ob.fire_mode = 2
	var place := func(u: Unit, d: float) -> void:
		u.position = G.on_ground(ob.position + dir * d)
	# (1) tank, açıkta: R'nin %70'inde görülür, %130'unda görülmez
	var tk: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b3", ob.position + dir * 50.0, 0.0)
	tk.cmd_hold()
	tk.fire_mode = 2
	var sigt: float = tk.spot_sig()
	var Rt := Combat.detect_range(ob.opt_k, sigt)
	place.call(tk, minf(Rt * 0.7, G.MAP * 0.38))
	await m._wait(2.2)
	var near_seen := G.is_seen(tk, 0)
	var far_ok := true
	if Rt * 1.3 < G.MAP * 0.4:
		place.call(tk, Rt * 1.3)
		await m._wait(3.2)
		far_ok = not G.is_seen(tk, 0)
	print("SPOT tank sig=%.2f R=%.0f near_seen=%s far_hidden=%s" % [sigt, Rt, near_seen, far_ok])
	if not near_seen or not far_ok:
		fails += 1
	tk.position = G.on_ground(ob.position - dir * 900.0)
	# (2) piyade: ayakta görülür, aynı mesafede yüzüstü görülmez
	var sol: Soldier = m.spawn_soldier(1, "rifle", ob.position + dir * 30.0, null)
	sol.cmd_hold()
	sol.fire_mode = 2
	var Rs := Combat.detect_range(ob.opt_k, 0.32)
	var dtest := Rs * 0.6
	place.call(sol, dtest)
	sol.stance_lock = Soldier.STAND
	await m._wait(2.2)
	var stand_seen := G.is_seen(sol, 0)
	sol.stance_lock = Soldier.PRONE
	sol.stance = Soldier.PRONE
	await m._wait(3.2)
	var prone_hidden := not G.is_seen(sol, 0)
	# (3) ateş eden yüzüstü asker görünür (namlu alevi, toz)
	sol.fired_t = G.time + 2.0
	await m._wait(1.6)
	var fire_seen := G.is_seen(sol, 0)
	print("SPOT inf d=%.0f stand_seen=%s prone_hidden=%s firing_seen=%s" % [dtest, stand_seen, prone_hidden, fire_seen])
	if not stand_seen or not prone_hidden or not fire_seen:
		fails += 1
	# (4) görüş hattı kapalı: arada 4 m yüksek duvar
	sol.stance_lock = Soldier.STAND
	sol.fired_t = -99.0
	var mid := ob.position + dir * dtest * 0.5
	G.grid.set_static_rect(mid, Vector2(3.0, 30.0), atan2(-dir.z, dir.x), 4.0, Grid.K_WALL)
	G.grid.flush_nav()
	await m._wait(3.2)
	var wall_hidden := not G.is_seen(sol, 0)
	print("SPOT wall_hidden=%s" % wall_hidden)
	if not wall_hidden:
		fails += 1
	G.grid.set_static_rect(mid, Vector2(3.0, 30.0), atan2(-dir.z, dir.x), 0.0, Grid.K_NONE, true)
	G.grid.flush_nav()
	# (5) gece: çıplak gözlü piyade gözcü ayakta askeri artık seçemez, termal tank seçer
	var eyeo: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(ob.position - dir * 6.0, Grid.M_INF), null)
	eyeo.cmd_hold()
	eyeo.fire_mode = 2
	var Re := Combat.detect_range(eyeo.opt_k, 0.32)
	place.call(sol, Re * 0.75)
	await m._wait(3.2)
	var day_seen := G.is_seen(sol, 0)
	ob.position = G.on_ground(ob.position - dir * 1200.0)
	await m._wait(3.2)
	var day_eye_only := G.is_seen(sol, 0)
	G.weather.night = true
	await m._wait(3.2)
	var night_eye_hidden := not G.is_seen(sol, 0)
	ob.position = G.on_ground(eyeo.position - dir * 3.0)
	await m._wait(3.2)
	var night_th_seen := G.is_seen(sol, 0)
	G.weather.night = false
	print("SPOT night day_seen=%s eye_day=%s eye_night_hidden=%s thermal_night_seen=%s" % [day_seen, day_eye_only, night_eye_hidden, night_th_seen])
	if not day_eye_only or not night_eye_hidden or not night_th_seen:
		fails += 1
	print("SPOTTEST RESULT fails=%d" % fails)

# gerçekçi menzil (roadmap 49): veri tüm araçları kapsar, silahlar arası oranlar gerçek
func range_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 5)
	var K := Combat.K_RANGE
	var missing: Array = []
	Catalog.load_all()
	for id in Catalog.units:
		var u: Dictionary = Catalog.units[id]
		var base: String = Catalog.FAM_BASE.get(u["fam"], "")
		if Combat.vehicle(id, base).is_empty():
			missing.append(id)
	print("RANGE K=%.3f catalog=%d missing=%d %s" % [K, Catalog.units.size(), missing.size(), str(missing.slice(0, 8))])
	if not missing.is_empty():
		fails += 1
	var r := func(id: String, k: String) -> float:
		return float(Combat.vehicle(id, "").get("rng", {}).get(k, 0.0))
	var checks := [
		["M1A2 SEP v3 > T-72B (ana top)", r.call("usa_mbt_s3", "main") > r.call("rus_mbt_72b", "main")],
		["Kornet > Javelin", float(Combat.inf("atgm").get("rng_rus", 0)) > float(Combat.inf("atgm").get("rng_usa", 0))],
		["tank topu > 25 mm > 12,7 mm", r.call("usa_mbt_a1", "main") > r.call("usa_ifv_m2a3", "auto") and r.call("usa_ifv_m2a3", "auto") > r.call("usa_mbt_a1", "mg")],
		["TOW > 25 mm", r.call("usa_ifv_m2a3", "atgm") > r.call("usa_ifv_m2a3", "auto")],
		["obüs > havan", r.call("usa_spg_a6", "ind") > r.call("usa_mor_120", "ind")],
		["roketatar > obüs", r.call("usa_mlrs_m270a1", "ind") > r.call("usa_spg_a6", "ind")],
		["Hellfire > tank topu", r.call("usa_heli_ah64e", "atgm") > r.call("usa_mbt_a1", "main")],
		["S-400 > Tor > Pantsir topu", r.call("rus_aa_s400", "aa") > r.call("rus_aa_tor", "aa") and r.call("rus_aa_tor", "aa") > r.call("rus_aa_pantsir", "auto")],
		["tüfek < makineli < keskin nişancı (RUS)", float(Combat.inf("rifle")["rng"]) < float(Combat.inf("mg")["rng_rus"]) and float(Combat.inf("mg")["rng_rus"]) <= float(Combat.inf("sniper")["rng_rus"])],
	]
	for c in checks:
		print("RANGE %s: %s" % [c[0], c[1]])
		if not c[1]:
			fails += 1
	# oyundaki araç: menzil = gerçek × K
	var tk: Vehicle = m.spawn_vehicle(0, "usa_mbt_a1", G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY), 0.0)
	var exp := 3500.0 * K
	print("RANGE M1A1 game_main=%.1f expected=%.1f armor=%s" % [tk._wr("main"), exp, tk.armor_text()])
	if absf(tk._wr("main") - exp) > 0.5:
		fails += 1
	print("RANGETEST RESULT fails=%d" % fails)

# füze türleri (15) ve önleme (31): tel güdümlü füze nişancı bastırılınca sapar, APS roketi vurur,
# C-RAM havan mermisini düşürür, kilit süreleri ve fişeğe kanma füzeye göre
func missile_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("front_2k", {}, true, 77)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	# açık şerit: 120 m boyunca görüş hattı açık iki nokta
	var a0 := Vector3.INF
	var b0 := Vector3.INF
	var rr := RandomNumberGenerator.new()
	rr.seed = 9
	for i in 600:
		var p := Vector3(rr.randf_range(150, G.MAP - 150), 0, rr.randf_range(150, G.MAP - 150))
		var q := p + Vector3(0, 0, -110)
		if G.grid.free_at(p, Grid.M_INF) and G.grid.free_at(q, Grid.M_HEAVY) and G.grid.los(p + Vector3(0, 1.6, 0), q + Vector3(0, 1.0, 0), 0.75, 2.5) and G.grid.los(p + Vector3(40, 1.6, 0), q + Vector3(40, 1.0, 0), 0.75, 2.5):
			a0 = p
			b0 = q
			break
	print("MISSILE strip=%s" % (a0 != Vector3.INF))
	if a0 != Vector3.INF:
		c = a0
	# (1) tel güdümlü TOW: sağlam nişancı vurur, bastırılan nişancının füzesi sapar
	var hits := [0, 0]
	for case in 2:
		var gun: Soldier = m.spawn_soldier(0, "rifle", c + Vector3(case * 40.0, 0, 0), null)
		gun.cmd_hold()
		gun.fire_mode = 2
		var tk: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b", c + Vector3(case * 40.0, 0, -110), 0.0)
		tk.cmd_hold()
		tk.fire_mode = 2
		tk.hp = 100000.0
		await m._wait(0.3)
		var hp0 := tk.hp
		G.bal.rocket(gun.eye_point() + Vector3(0, 0, -1), tk.aim_point(), 0, gun, tk, "atgm", "tow", 4000.0 * Combat.K_RANGE)
		if case == 0:
			_cam(c + Vector3(0, 0, -40), 40.0)
			await m._wait(0.25)
			await m._shot("missile_00_tow_wire")
		if case == 1:
			await m._wait(0.15)
			gun.suppression = 95.0
		var t0 := G.time
		while G.time - t0 < 10.0 and G.bal.projs.any(func(p): return p.src == gun):
			await m._wait(0.05)
			if case == 1:
				gun.suppression = 95.0
		hits[case] = 1 if tk.hp < hp0 - 50.0 else 0
		tk.queue_free()
		gun.queue_free()
	print("MISSILE tow_hit_ok=%d tow_hit_suppressed=%d" % [hits[0], hits[1]])
	if hits[0] != 1 or hits[1] != 0:
		fails += 1
	# (2) APS: Kurganets'e (Afganit) 6 RPG — 4 şarj, sonrakiler gövdeye ulaşır
	var t14: Vehicle = m.spawn_vehicle(1, "rus_ifv_kurg", G.grid.nearest_free(c + Vector3(0, 0, 60), Grid.M_HEAVY), 0.0)
	t14.cmd_hold()
	t14.fire_mode = 2
	t14.hp = 100000.0
	var aps0 := t14.aps_n
	var hit_n := 0
	for k in 6:
		var hp1 := t14.hp
		G.bal.rocket(t14.position + Vector3(-60, 1.2, 0), t14.aim_point(), 0, null, t14, "rpg")
		var t1 := G.time
		while G.time - t1 < 4.0 and G.bal.projs.any(func(p): return p.kind == "rpg"):
			await m._wait(0.05)
		if t14.hp < hp1:
			hit_n += 1
	var used := aps0 - t14.aps_n
	print("MISSILE aps charges=%d used=%d hits=%d/6" % [aps0, used, hit_n])
	if aps0 != 4 or used != 4 or hit_n < 2 or hit_n == 6:
		fails += 1
	# (3) C-RAM: düşman havan mermilerinin bir kısmı inişte düşürülür
	var cram: Vehicle = m.spawn_vehicle(0, "usa_aa_cram", G.grid.nearest_free(c + Vector3(80, 0, 0), Grid.M_HEAVY), 0.0)
	cram.cmd_hold()
	var am0 := cram.cram_ammo
	var landed := 0
	for k in 10:
		G.bal.mortar(cram.position + Vector3(-120, 1, 30), cram.position + Vector3(randf_range(-8, 8), 0, randf_range(-8, 8)), 1, null)
		await m._wait(1.5)
	var t2 := G.time
	var live := 10
	while G.time - t2 < 40.0 and G.bal.projs.any(func(p): return p.kind == "mortar"):
		await m._wait(0.1)
	print("MISSILE cram engaged=%d (ammo %d->%d)" % [am0 - cram.cram_ammo, am0, cram.cram_ammo])
	if am0 - cram.cram_ammo < 3:
		fails += 1
	# (4) kilit süreleri ve fişeğe kanma
	var lj := Ballistics.lock_time("javelin")
	var lk := Ballistics.lock_time("kornet")
	var dv := Ballistics.decoy_chance("verba", false)
	var ds := Ballistics.decoy_chance("stinger", false)
	print("MISSILE lock javelin=%.1f kornet=%.1f decoy verba=%.2f stinger=%.2f" % [lj, lk, dv, ds])
	if not (lj > lk and dv < ds):
		fails += 1
	print("MISSILETEST RESULT fails=%d" % fails)

# yapay zekâ maçı (roadmap 21/47): iki YZ komutanı seçilen haritada (--map=, varsayılan battle_8k) Fetih
# kipinde --minutes= oyun dakikası (varsayılan 30) hızlandırılmış (--ts=, varsayılan 4) oynar. Her oyun dakikası:
# birlik/ikmal/bölge/puan/kayıp, saldırı gruplarının hedefe uzaklığı, FPS; 5 dakikada bir stratejik görüntü.
# Sonda maç özeti: kazanan (ya da puan durumu), oyun süresi, gerçek süre.
func ai_match() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var map_id := "battle_8k"
	var minutes := 30.0
	var ts := 4.0
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			map_id = a.substr(6)
		elif a.begins_with("--minutes="):
			minutes = float(a.substr(10))
		elif a.begins_with("--ts="):
			ts = float(a.substr(5))
	m.start_units = true
	G.mode = "conquest"
	var t_real := Time.get_ticks_msec()
	m.start_game(map_id, {}, false, 7)
	G.spectate = true
	var a0 := AICmd.new(0)
	m.add_child(a0)
	G.ais.append(a0)
	G.deploy_t = 0.0
	print("AIM start map=%s MAP=%.0f load_s=%.1f units=%d zones=%d goal=%.0f" % [map_id, G.MAP, (Time.get_ticks_msec() - t_real) / 1000.0, G.units.size(), G.modes.zones.size() if G.modes != null else 0, G.modes.goal if G.modes != null else 0.0])
	# mini harita dokusu (yükleme ekranında üretildi) ayrıca kaydedilir
	if G.hud != null and G.hud.radar != null and G.hud.radar.tex != null:
		var mi: Image = G.hud.radar.tex.get_image()
		mi.save_png(m.shot_dir.path_join("minimap_tex.png"))
		print("AIM minimap %dx%d" % [mi.get_width(), mi.get_height()])
	for t in 2:
		var ds: Array = []
		for s in G.fob_sites:
			ds.append(int((s as Vector3).distance_to(G.hq_pos[t])))
		ds.sort()
		print("AIM fob_sites T%d nearest=%s" % [t, str(ds.slice(0, 5))])
	Engine.time_scale = ts
	var t0 := Time.get_ticks_msec()
	var minute := 0
	var first_cap := -1.0
	var fps_min := 999.0
	while G.time < minutes * 60.0 and not G.game_over:
		await m._wait(60.0)
		minute += 1
		var n := [[0, 0, 0], [0, 0, 0]]
		for u in G.units:
			if is_instance_valid(u) and u.alive and u.team >= 0 and u.team < 2:
				n[u.team][0 if u is Soldier else (1 if u is Vehicle else 2)] += 1
		var zs := ""
		if G.modes != null:
			for z in G.modes.zones:
				zs += "%s%s " % [String(z["name"]).substr(0, 1), "-" if z["owner"] < 0 else str(z["owner"])]
				if z["owner"] >= 0 and first_cap < 0.0:
					first_cap = G.time
		var att := ""
		for ai in G.ais:
			if is_instance_valid(ai):
				var live: Array = ai.attackers.filter(func(u): return is_instance_valid(u) and u.alive)
				var c: Vector3 = ai._centroid(live) if not live.is_empty() else Vector3.INF
				att += "T%d att=%d d_tgt=%s  " % [ai.team, live.size(), ("%.0f" % c.distance_to(ai.target_pos)) if (c != Vector3.INF and ai.target_pos != Vector3.INF) else "-"]
		var fps := Engine.get_frames_per_second()
		fps_min = minf(fps_min, fps)
		var fob := ["", ""]
		for u in G.units:
			if is_instance_valid(u) and u.alive and u is Building and u.btype in ["fob", "barracks", "factory", "helipad", "hospital"] and u.team >= 0 and u.team < 2:
				fob[u.team] += "%s%s " % [u.btype.substr(0, 2), "" if u.done else "*"]
		print("AIM    cap=%d/%d %d/%d  bld A: %s B: %s" % [G.cap_used[0], G.cap_max[0], G.cap_used[1], G.cap_max[1], fob[0], fob[1]])
		for ai in G.ais:
			if not is_instance_valid(ai):
				continue
			var live: Array = ai.attackers.filter(func(u): return is_instance_valid(u) and u.alive)
			var st := {}
			var nopath := 0
			for u in live:
				var k: String = ("V:" if u is Vehicle else "S:") + (u.state if u is Soldier else ("mv" if absf(u.cur_speed) > 0.3 else "st")) + "/" + u.order
				st[k] = st.get(k, 0) + 1
				if u.path_i >= u.path.size():
					nopath += 1
			var c: Vector3 = ai._centroid(live) if not live.is_empty() else Vector3.ZERO
			print("AIM    T%d lead=(%.0f,%.0f) tgt=%s zone=%s route=%d nopath=%d %s" % [ai.team, c.x, c.z, ("(%.0f,%.0f)" % [ai.target_pos.x, ai.target_pos.z]) if ai.target_pos != Vector3.INF else "-", String(ai.target_zone["name"]) if ai.target_zone != null else "-", ai.route.size(), nopath, st])
		print("AIM t=%dm sol/veh/bld A=%s B=%s supply=%d/%d score=%.0f/%.0f zones=%s kills=%s %s fps=%d" % [minute, n[0], n[1], int(G.supply[0]), int(G.supply[1]), G.modes.score[0] if G.modes != null else 0.0, G.modes.score[1] if G.modes != null else 0.0, zs, G.stats["kills"], att, fps])
		if minute % 5 == 0:
			var live_all: Array = []
			for ai in G.ais:
				if is_instance_valid(ai):
					live_all.append_array(ai.attackers.filter(func(u): return is_instance_valid(u) and u.alive))
			var cc: Vector3 = G.ais[0]._centroid(live_all) if not live_all.is_empty() else Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
			Engine.time_scale = 1.0
			_cam(cc, minf(G.cam.max_size, 1200.0))
			await m._wait(0.5)
			await m._shot("aim_%02d_strat" % minute)
			_cam(cc, 90.0)
			await m._wait(0.5)
			await m._shot("aim_%02d_close" % minute)
			Engine.time_scale = ts
	Engine.time_scale = 1.0
	print("AIMATCH RESULT fails=%d t=%.1fm winner=%d score=%.0f/%.0f first_capture=%.1fm real=%ds fps_min=%d" % [0 if first_cap >= 0.0 else 1, G.time / 60.0, G.winner, G.modes.score[0] if G.modes != null else 0.0, G.modes.score[1] if G.modes != null else 0.0, first_cap / 60.0, (Time.get_ticks_msec() - t0) / 1000, int(fps_min)])

# taban tip modelleri (roadmap 10) ve rotorlar (39/44): iki ulusun tüm taban araçları yan yana; helikopterler
# havada pervane dönerken; yakın çekimler
func base_gallery() -> void:
	m.get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 11)
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 60.0)
	var types := ["tank", "ifv", "apc", "technical", "truck", "aa", "arty", "mlrs", "howitzer", "fieldgun", "hmortar", "atgun", "aagun"]
	var air: Array = []
	for t in 2:
		for i in types.size():
			var p := c + Vector3(-60 + i * 10.0, 0, -12 + t * 24.0)
			var v := m.spawn_vehicle(t, types[i], p, PI * 0.75)
			v.cmd_hold()
			v.fire_mode = 2
		for k in 2:
			var h := m.spawn_vehicle(t, ["heli", "transport"][k], c + Vector3(-20 + k * 24.0, 0, -36 + t * 72.0), PI * 0.75)
			h.cmd_hold()
			h.fire_mode = 2
			air.append(h)
	print("BASEGAL nations=%s units=%d" % [G.nation, G.units.size()])
	await m._wait(5.0)
	_cam(c, 75.0)
	await m._wait(1.0)
	await m._shot("base_01_all")
	_cam(c + Vector3(-45, 0, 0), 30.0)
	await m._wait(0.6)
	await m._shot("base_02_armor")
	_cam(c + Vector3(5, 0, 0), 30.0)
	await m._wait(0.6)
	await m._shot("base_03_arty")
	for i in air.size():
		var h: Vehicle = air[i]
		_cam(h.position + Vector3(0, h.hull.position.y, 0), 18.0)
		await m._wait(0.6)
		print("BASEGAL %s team=%d rpm=%.2f nb=%d blades_vis=%s" % [h.vtype, h.team, h.rotor_rpm, h.rotor_nb, h.rotor_blades.visible if h.rotor_blades else false])
		await m._shot("base_heli_%d" % i)
	print("BASEGALLERY RESULT fails=0")

# roadmap 3: motor arızası (hız düşer / durur, duman), motor yangını ve söndürme, birikimli yıpranma,
# palet onarımında mürettebat, istihkâm onarımı (çekiç, kıvılcım, yıpranma azalır)
func engine_test() -> void:
	m.get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 21)
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tk: Vehicle = m.spawn_vehicle(0, "usa_mbt_a2", c, 0.0)
	tk.cmd_hold()
	var sf0 := tk.speed_factor()
	tk.add_crit("eng", 1)
	var sf1 := tk.speed_factor()
	tk.add_crit("eng", 1)
	var imm := tk.immobile()
	print("ENG speed_factor %.2f -> %.2f immobile_at_2=%s" % [sf0, sf1, imm])
	if not (sf1 < sf0 * 0.7) or not imm:
		fails += 1
	# yangın: söndürülmezse can kaybı, mürettebat söndürür
	tk.eng_fire = 12.0
	var hp0: float = tk.hp
	_cam(tk.position, 18.0)
	await m._wait(2.0)
	await m._shot("eng_01_fire")
	await m._wait(8.0)
	print("ENG fire hp %.0f -> %.0f fire_left=%.1f alive=%s" % [hp0, tk.hp, tk.eng_fire, tk.alive])
	if tk.hp >= hp0 or tk.eng_fire > 0.0 or not tk.alive:
		fails += 1
	# yıpranma: aynı isabet yıpranmış araçta daha çok hasar verir (en çok +%25)
	var a: Vehicle = m.spawn_vehicle(0, "usa_mbt_a1", G.grid.nearest_free(c + Vector3(20, 0, 0), Grid.M_HEAVY), 0.0)
	var b: Vehicle = m.spawn_vehicle(0, "usa_mbt_a1", G.grid.nearest_free(c + Vector3(30, 0, 0), Grid.M_HEAVY), 0.0)
	for v in [a, b]:
		v.cmd_hold()
		v.fire_mode = 2
	b.wear = 1.0
	for v in [a, b]:
		Vehicle.shot_from = v.position - v.forward() * 30.0
		v.take_damage(200.0, null, "atgm")
	var da: float = a.max_hp - a.hp
	var db: float = b.max_hp - b.hp
	print("ENG wear dmg fresh=%.0f worn=%.0f ratio=%.2f wear_after=%.2f" % [da, db, db / maxf(da, 1.0), a.wear])
	if db <= da or db > da * 1.3 or a.wear <= 0.0:
		fails += 1
	# palet onarımı: mürettebat dışarıda, çekiçle
	tk.crit["eng"] = 0
	tk.tracks_broken = 14.0
	tk.last_hit = -99.0
	_cam(tk.position, 14.0)
	await m._wait(2.5)
	var rb := tk.repair_body != null
	await m._shot("eng_02_trackrepair")
	print("ENG track_repair body=%s left=%.1f" % [rb, tk.tracks_broken])
	if not rb:
		fails += 1
	# istihkâm: hasarlı araca gelir, çekiçle onarır, yıpranma azalır
	a.wear = 0.8
	var w0: float = a.wear
	var hp_a: float = a.hp
	var eng: Soldier = m.spawn_soldier(0, "engineer", G.grid.nearest_free(a.position + Vector3(0, 0, 8), Grid.M_INF), null)
	await m._wait(12.0)
	_cam(a.position, 12.0)
	await m._wait(0.3)
	await m._shot("eng_03_engineer")
	print("ENG engineer hp %.0f -> %.0f wear %.2f -> %.2f vis=%s" % [hp_a, a.hp, w0, a.wear, G.time < eng.repair_vis_t])
	if a.hp <= hp_a or a.wear >= w0:
		fails += 1
	print("ENGINETEST RESULT fails=%d" % fails)

# büyük harita çalışma yükü (roadmap 21/55): 8 km'de ~300 birimlik çatışma; kare süresi ve alt sistemleri
# tek tek kapatarak payları (asker, araç, tespit, savaş sisi, mini harita/HUD, simgeler, mermiler, ot/ağaç)
func perf_8k() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	var id := "battle_8k"
	var n_sq := 12
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):
			id = a.substr(6)
		elif a.begins_with("--squads="):
			n_sq = int(a.substr(9))
	m.start_game(id, {}, true, 7)
	G.fog_off = false
	var c := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var gap := clampf(G.MAP * 0.05, 60.0, 450.0)
	var vtypes := ["tank", "ifv", "apc", "technical", "aa", "arty"]
	for t in 2:
		var side := -1.0 if t == 0 else 1.0
		for k in n_sq:
			var sp := G.grid.nearest_open(c + Vector3(side * gap, 0, (k - n_sq * 0.5) * 22.0), Grid.M_INF)
			var sq := Squad.new(t, "T%d" % k)
			G.squads.append(sq)
			for i in 8:
				var s := m.spawn_soldier(t, ["leader", "rifle", "rifle", "mg", "rifle", "at", "rifle", "medic"][i], G.grid.nearest_free(sp + Vector3(i % 3 * 1.5, 0, i / 3 * 1.5), Grid.M_INF), sq)
				s.cmd_move(G.grid.nearest_free(c + Vector3(side * gap * 0.3, 0, (k - n_sq * 0.5) * 22.0), Grid.M_INF))
		for k in n_sq * 2:
			var v := m.spawn_vehicle(t, vtypes[k % vtypes.size()], G.grid.nearest_open(c + Vector3(side * (gap + 40.0), 0, (k - n_sq) * 14.0), Grid.M_HEAVY), PI * 0.5 * side)
			v.cmd_move(G.grid.nearest_free(c + Vector3(side * gap * 0.4, 0, (k - n_sq) * 14.0), Grid.M_HEAVY))
	var cnt := [0, 0]
	for u in G.units:
		if u is Soldier:
			cnt[0] += 1
		elif u is Vehicle:
			cnt[1] += 1
	print("PERF8K map=%s MAP=%.0f soldiers=%d vehicles=%d units=%d" % [id, G.MAP, cnt[0], cnt[1], G.units.size()])
	_cam(c, 115.0)
	await m._wait(8.0)
	# araç içi bölümler
	Vehicle.prof = {}
	Vehicle.prof_on = true
	for f in 60:
		await m.get_tree().process_frame
	Vehicle.prof_on = false
	var ks: Array = Vehicle.prof.keys()
	ks.sort_custom(func(a, b): return Vehicle.prof[a] > Vehicle.prof[b])
	var line := ""
	for k in ks:
		line += "%s=%.1f " % [k, Vehicle.prof[k] / 60.0 / 1000.0]
	print("PERF8K vehicle_ms_per_frame %s" % line)
	var sections := ["all", "nofire", "soldiers", "vehicles", "visibility", "fog", "hud", "icons", "ballistics", "props"]
	for sec in sections:
		_perf_part(sec, false)
		await m.get_tree().process_frame
		await m.get_tree().process_frame
		var n := 0
		var t1 := Time.get_ticks_usec()
		var tp := 0.0
		while n < 90:
			await m.get_tree().process_frame
			n += 1
			tp += Performance.get_monitor(Performance.TIME_PROCESS)
		var ms := float(Time.get_ticks_usec() - t1) / 1000.0 / n
		print("PERF8K off=%-10s frame_ms=%.1f process_ms=%.1f fps=%d" % [sec, ms, tp / n * 1000.0, int(1000.0 / maxf(ms, 0.01))])
		_perf_part(sec, true)
	print("PERF8K RESULT fails=0")

func _perf_part(part: String, on: bool) -> void:
	match part:
		"nofire":
			for u in G.units:
				if u is Vehicle or u is Soldier:
					u.fire_mode = 0 if on else 2
		"soldiers":
			for u in G.units:
				if u is Soldier:
					u.set_process(on)
		"vehicles":
			for u in G.units:
				if u is Vehicle:
					u.set_process(on)
		"visibility":
			G.vis_freeze = not on
		"fog":
			for n in m.world.get_children():
				if n is FogOfWar:
					n.set_process(on)
		"hud":
			G.hud.set_process(on)
			G.hud.radar.visible = on
		"icons":
			G.hud.icons.set_process(on)
			G.hud.icons.visible = on
		"ballistics":
			G.bal.set_process(on)
		"props":
			G.props.set_process(on)

# roadmap 11: tank mürettebatı iner (ayrı askerler, araç yürüyemez/ateş edemez) ve geri biner
func mount_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 23)
	G.fog_off = true
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tk: Vehicle = m.spawn_vehicle(0, "usa_mbt_a2", c, 0.0)
	tk.cmd_hold()
	await m._wait(1.0)
	var n0: int = tk.crew_n
	tk.cmd_dismount_crew()
	await m._wait(2.5)
	var crew_soldiers := 0
	for u in G.units:
		if u is Soldier and u.alive and u.home_vehicle == tk:
			crew_soldiers += 1
	tk.cmd_move(c + Vector3(30, 0, 0))
	var p0 := tk.position
	await m._wait(3.0)
	var moved := tk.position.distance_to(p0)
	_cam(tk.position, 22.0)
	await m._wait(0.3)
	await m._shot("mount_01_out")
	print("MOUNT crew_before=%d out_soldiers=%d crew_now=%d immobile=%s moved=%.1f" % [n0, crew_soldiers, tk.crew_n, tk.immobile(), moved])
	if crew_soldiers != n0 or tk.crew_n != 0 or not tk.immobile() or moved > 1.0:
		fails += 1
	tk.cmd_mount_crew()
	await m._wait(12.0)
	var left := 0
	for u in G.units:
		if u is Soldier and u.alive and u.home_vehicle == tk and u.state != "aboard":
			left += 1
	print("MOUNT after crew=%d/%d driver=%s gunner=%s soldiers_left=%d" % [tk.crew_n, tk.crew_max, tk.driver_ok, tk.gunner_ok, left])
	if tk.crew_n != n0 or not tk.driver_ok or not tk.gunner_ok:
		fails += 1
	print("MOUNTTEST RESULT fails=%d" % fails)

# roadmap 22/39/44: alçalan helikopter — paller görünür, rotor rüzgârı otu ve ağaçları savurur, toz kalkar,
# ses alçaldıkça yükselir; rotor devri inişte rölantiye düşer
func rotor_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 29)
	G.fog_off = true
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 - 30, 0, G.MAP * 0.5 + 20), Grid.M_LIGHT)
	var h: Vehicle = m.spawn_vehicle(0, "transport", c + Vector3(0, 0, 30), 0.0)
	h.fire_mode = 2
	h.cmd_move(c)
	await m._wait(6.0)
	h.request_land()
	var vol_hi := h.engine.volume_db if h.engine != null else 0.0
	await m._wait(2.5)
	_cam(c, 30.0)
	await m._wait(0.4)
	await m._shot("rotor_01_landing")
	var r0: Vector4 = G.rotor_wash[0]
	var vol_lo := h.engine.volume_db if h.engine != null else 0.0
	print("ROTOR alt=%.1f rpm=%.2f wash=(%.0f,%.0f k=%.2f r=%.1f) vol %.1f -> %.1f blades=%s" % [h.hull.position.y, h.rotor_rpm, r0.x, r0.y, r0.z, r0.w, vol_hi, vol_lo, h.rotor_blades.visible])
	if r0.z <= 0.05 or not h.rotor_blades.visible:
		fails += 1
	await m._wait(6.0)
	_cam(c, 18.0)
	await m._wait(0.4)
	await m._shot("rotor_02_landed")
	print("ROTOR landed alt=%.2f rpm=%.2f" % [h.hull.position.y, h.rotor_rpm])
	if h.rotor_rpm > 0.9:
		fails += 1
	print("ROTORTEST RESULT fails=%d" % fails)

# roadmap 12: imha biçimi öldüren isabete göre (üstten → cephane infilakı ve dikey taret, yandan → yan
# savrulan taret, mayın → hafif araç devrilir, ağır topçu → hafif araç yan yatar)
func kill_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 31)
	G.fog_off = true
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var cases := [["rus_mbt_72b3", "topatk", 0], ["rus_mbt_72b3", "atgm", 1], ["rus_mbt_72b3", "ap", 0], ["rus_lv_tigr", "mine", 0], ["rus_lv_tigr", "big", 1], ["rus_ifv_bmp2m", "rpg", 2]]
	var vs: Array = []
	for i in cases.size():
		var v: Vehicle = m.spawn_vehicle(1, cases[i][0], G.grid.nearest_open(c + Vector3((i - 2.5) * 14.0, 0, 0), Grid.M_HEAVY), 0.0)
		v.cmd_hold()
		v.fire_mode = 2
		vs.append(v)
	await m._wait(1.0)
	var counts := {}
	for rep in 3:
		for i in vs.size():
			var v: Vehicle = vs[i]
			if not v.alive:
				continue
			var side: int = cases[i][2]
			var dir: Vector3 = [v.forward(), v.right(), -v.forward()][side]
			Vehicle.shot_from = v.position + dir * 40.0 + Vector3(0, 30.0 if cases[i][1] in ["topatk", "big"] else 1.0, 0)
			v.take_damage((v.hp + v.max_hp * 0.3) * 4.0, null, cases[i][1])
	await m._wait(1.2)
	_cam(c, 60.0)
	await m._wait(0.5)
	await m._shot("kill_01")
	var res := []
	for i in vs.size():
		var v: Vehicle = vs[i]
		var tp: Vector3 = v.turret.position if v.turret != null else Vector3.ZERO
		res.append("%s/%s→%s(roll=%.1f tz=%.1f)" % [cases[i][0].substr(4), cases[i][1], v.kill_mode, v.hull.rotation.z, tp.y])
	print("KILL %s" % str(res))
	if vs[3].kill_mode != "flip" or vs[0].kill_mode == "" or vs[1].kill_mode == "":
		fails += 1
	await m._wait(2.0)
	_cam(c, 40.0)
	await m._wait(0.3)
	await m._shot("kill_02")
	print("KILLTEST RESULT fails=%d" % fails)

# roadmap 23: palet izi — çölde silinir, karda kalır; görülmeyen düşman aracı iz bırakmaz (savaş sisi)
func track_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	for mp in ["desert_canal", "winter_village"]:
		m.start_game(mp, {}, true, 37)
		var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
		var tk: Vehicle = m.spawn_vehicle(0, "tank", c, 0.0)
		tk.cmd_move(G.grid.nearest_free(c + Vector3(0, 0, -30), Grid.M_HEAVY))
		await m._wait(6.0)
		var n_own: int = G.terrain._trk.size() - G.terrain._trk_h
		# görülmeyen düşman tankı: iz bırakmamalı
		var e: Vehicle = m.spawn_vehicle(1, "tank", G.grid.nearest_open(c + Vector3(60, 0, 40), Grid.M_HEAVY), 0.0)
		e.fire_mode = 2
		tk.fire_mode = 2
		tk.cmd_stop()
		await m._wait(1.5)
		var before: int = G.terrain._trk.size()
		e.cmd_move(G.grid.nearest_free(e.position + Vector3(0, 0, -25), Grid.M_HEAVY))
		await m._wait(4.0)
		var enemy_stamps: int = G.terrain._trk.size() - before
		var seen: bool = e.seen[0]
		_cam(c + Vector3(0, 0, -15), 26.0)
		await m._wait(0.3)
		await m._shot("track_%s_fresh" % mp)
		# yaşlandır: tüm damgalar eski sayılır
		var probe: Array = G.terrain._trk[G.terrain._trk.size() - 1] if G.terrain._trk.size() > 0 else [0, 0, 0]
		var g0: float = G.terrain.img.get_pixel(probe[0], probe[1]).g
		for s in G.terrain._trk:
			s[2] = -10000.0
		G.terrain._track_fade()
		var g1: float = G.terrain.img.get_pixel(probe[0], probe[1]).g
		print("TRACK map=%s own_stamps=%d enemy_unseen_stamps=%d enemy_seen=%s g %.2f -> %.2f fade_age=%.0f" % [mp, n_own, enemy_stamps, seen, g0, g1, G.terrain._track_fade_age()])
		if n_own <= 0 or (not seen and enemy_stamps > 0):
			fails += 1
		if mp == "desert_canal" and g1 >= g0:
			fails += 1
		if mp == "winter_village" and g1 < g0:
			fails += 1
	print("TRACKTEST RESULT fails=%d" % fails)

func _prof_toggle(part: String, on: bool) -> void:
	match part:
		"grass":
			for n in m.get_tree().get_nodes_in_group("zoom_grass"):
				n.visible = on and G.cam.size < 200.0
		"shadow":
			G.cam.light.shadow_enabled = on and G.cam.size < 1100.0
		"trees":
			for b in G.props._banks.values():
				(b["mmi"] as Node3D).visible = on
		"blocks":
			G.blocks.visible = on

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
