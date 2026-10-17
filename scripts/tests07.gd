class_name Tests07 extends RefCounted
# Hotfix 0.0.7 sahne testleri: --scene=treetest | yieldtest | dronetest | woundtest | ropetest | evadetest | crewtest

var m: Main

func _init(main: Main) -> void:
	m = main

func run(scene: String) -> void:
	m.start_units = false
	match scene:
		"yieldtest":
			await yield_test()
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
		"mbtgallery":
			await mbt_gallery()
		"crewkilltest":
			await crew_kill_test()
		"snipertest":
			await sniper_test()
		"sandboxtest":
			await sandbox_test()
		"drivertest":
			await driver_test()
		"watertest":
			await water_test()
		"vehaitest":
			await veh_ai_test()
		"cratertest":
			await crater_test()
		"decktest":
			await deck_test()
		"jamtest":
			await jam_test()
		"aimtest":
			await aim_test()
		"smokepasstest":
			await smokepass_test()
		"dozertest":
			await dozer_test()
		"towtest":
			await tow_test()
		"cratertypes":
			await cratertypes_test()
		"backfiretest":
			await backfire_test()
		"crowdtest":
			await crowd_test()
		"trenchpose":
			await trenchpose_test()
		"ramptest":
			await ramp_test()
		"hulldowntest":
			await hulldown_test()
		"nadetest":
			await nade_test()
		"fobdark":
			await fobdark_test()
		"camtest":
			await cam_test()
		"towcrewtest":
			await towcrew_test()
		"rivertest":
			await river_test()
		"bridgerebuild":
			await bridge_rebuild_test()
		"chinooktest":
			await chinook_test()
		"crewshots":
			await crew_shots()
		"obstacletest":
			await obstacle_test()
		"fencetest":
			await fence_test()
		"grassfiretest":
			await grassfire_test()
		"swimtest":
			await swim_test()
		"wreckshots":
			await wreck_shots()
		"groundshots":
			await ground_shots()
		"posegallery":
			await pose_gallery()
		"ordertest":
			await order_test()
		"gfxbench":
			await gfx_bench()
		"menushots":
			await menu_shots()
		"hudshots":
			await hud_shots()
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
		"crewvistest":
			await crewvis_test()
		"mortartest":
			await mortar_test()
		"ruintest":
			await ruin_test()
		"bridgetest":
			await bridge_test()
		"shadowtest":
			await shadow_test()
		"smoketest":
			await smoke_test()
		"firetest":
			await fire_test()
		"soldiertest":
			await soldier_test()
		"armeduav":
			await armed_uav_test()
		"turrettest":
			await turret_test()
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
	m.start_game("green_valley", {}, true, 267636)
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
	# halkanın içi ve boşluğun önü açık olmalı (eskiden harita içeriği değişince hedefin 2 m yanına düşen ev
	# boşluğu kapatıyordu → çözümsüz kurulum)
	var fp := _open_spot(c + Vector3(-60, 0, 60), 16.0)
	G.props.clear_area(fp, 16.0)
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
	var dbg_b := -9.0
	while G.time - tf < 90.0:
		await m._wait(0.1)
		if not is_instance_valid(h3) or not h3.alive or not is_instance_valid(tk2):
			break
		if G.time - tf > 6.0 and G.time - tf < 6.2:
			blind0 = h3.target == null
		if G.time - dbg_b > 3.0:
			dbg_b = G.time
			var eye3 := h3.turret_world_pos() + Vector3(0, 0.4, 0)
			print("EVADE bdbg t=%.1f n=%d r=%.0f brg=%.0f alt=%.1f tgt=%s order=%s ft=%s seen=%s los=%s los_ns=%s d=%.0f blk=%s" % [G.time - tf, h3.atk_n, h3.atk_r, rad_to_deg(atan2(h3.position.z - fp.z, h3.position.x - fp.x)), h3.hull.position.y, h3.target != null, h3.order, h3.forced_target != null, G.is_seen(tk2, 0), G.grid.los(eye3, tk2.aim_point(), h3.D["len"] * 0.5, 0.5), _los_nosmoke(eye3, tk2.aim_point()), h3.dist2(tk2), _los_block(eye3, tk2.aim_point(), h3.D["len"] * 0.5, 0.5)])
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
	# 9: oyuncu emriyle tim birleştirme (4 + 4 → tek manga)
	var sa := Squad.new(G.player_team, "Tim")
	var sb := Squad.new(G.player_team, "Tim")
	G.squads.append(sa)
	G.squads.append(sb)
	var sel: Array = []
	for i in 8:
		var x: Soldier = m.spawn_soldier(G.player_team, ["leader", "rifle", "rifle", "mg"][i % 4], c + Vector3(10 + i, 0, 20), sa if i < 4 else sb)
		sel.append(x)
	var into := Squad.merge_selected(sel)
	var same := 0
	for x in sel:
		if x.squad == into:
			same += 1
	print("WOUND merge_cmd into=%s same=%d/8 merge_ok_after=%s" % [into != null, same, Squad.merge_ok(sel)])
	if into == null or same < 8:
		fails += 1
	# 9: isabet bölgesi → kan yeri ve yara türü; baş isabeti daha öldürücü
	var zc := {}
	var hs: Soldier = m.spawn_soldier(G.player_team, "rifle", c + Vector3(30, 0, 30), null)
	for i in 400:
		var z: String = hs._hit_zone()
		zc[z] = zc.get(z, 0) + 1
	print("WOUND zones %s" % [zc])
	if zc.get("head", 0) < 10 or zc.get("torso", 0) < 120 or zc.get("arm", 0) < 40 or zc.get("leg", 0) < 60:
		fails += 1
	var hp0 := hs.hp
	hs.last_zone = "leg"
	hs._injure(false)
	print("WOUND leg_zone_injury=%s" % hs.injury)
	if hs.injury != "leg":
		fails += 1
	hs.hp = hp0
	# 9: yakın ağır patlamada ölen askerde uzuv kopar, parça savrulur
	var g0: int = G.fx.gibs.size()
	var severed := 0
	for i in 6:
		var v: Soldier = m.spawn_soldier(1 - G.player_team, "rifle", c + Vector3(40 + i * 6, 0, 40), null)
		v.hp = 5.0
		v.downs = 2
		v.on_blast(v.position + Vector3(0.6, 0, 0), 6.0, 160.0, 0.6, null)
		if not v.alive and v.body.severed.size() > 0:
			severed += 1
	await m._wait(1.5)
	print("WOUND sever=%d/6 gibs=%d" % [severed, G.fx.gibs.size() - g0])
	if severed < 2 or G.fx.gibs.size() - g0 < 2:
		fails += 1
	_cam(c + Vector3(55, 0, 40), 14.0)
	await m._wait(1.0)
	await m._shot("wound_09_sever")
	print("WOUNDTEST RESULT fails=%d" % fails)

# 140: nehre düşen asker yürüme pozunda takılı kalmaz, en yakın kıyıya çıkar; 139: kıyıdaki krater suyla dolar
func river_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	# nehir hücresi: haritada su olan bir nokta ara (köprüden uzak)
	var wp := Vector3.INF
	var z := 10.0
	while z < G.MAP - 10.0 and wp == Vector3.INF:
		var x := 10.0
		while x < G.MAP - 10.0:
			var q := Vector3(x, 0, z)
			if G.grid.is_water(q) and G.grid.bridge_at(q).is_empty() and G.grid.is_water(q + Vector3(3, 0, 0)) and G.grid.is_water(q - Vector3(3, 0, 0)) \
					and Vector2(q.x - G.MAP * 0.5, q.z - G.MAP * 0.5).length() > 40.0:
				wp = q
				break
			x += 4.0
		z += 4.0
	if wp == Vector3.INF:
		print("RIVER no water")
		print("RIVERTEST RESULT fails=1")
		return
	var ss: Array = []
	for i in 6:
		var s: Soldier = m.spawn_soldier(0, "rifle", wp, null)
		s.position = wp + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
		ss.append(s)
	await m._wait(25.0)
	var wet := 0
	var stuck := 0
	for s in ss:
		if G.grid.is_water(s.position) and not G.grid.on_bridge(s.position):
			wet += 1
			if s.state == "move":
				stuck += 1
			print("RIVER wet soldier state=%s order=%s pos=%s path=%d/%d dry=%s alive=%s" % [s.state, s.order, s.position, s.path_i, s.path.size(), G.grid.nearest_dry(s.position, 30.0), s.alive])
	print("RIVER soldiers=6 still_in_water=%d walking_in_water=%d" % [wet, stuck])
	if wet > 0:
		fails += 1
	# 139: kıyıdaki top mermisi kraterinde su
	var bank: Vector3 = G.grid.nearest_dry(wp, 30.0)
	var away: Vector3 = (bank - wp)
	away.y = 0.0
	var cp: Vector3 = G.grid.nearest_free(bank + away.normalized() * 4.0, Grid.M_INF)
	cp.y = 0.0
	var p0: int = G.terrain.pools.size()
	G.explode(cp, 4.5, 10.0, "shell", 1, null)
	await m._wait(7.0)
	var pool_y := -99.0
	if G.terrain.pools.size() > p0:
		pool_y = (G.terrain.pools[G.terrain.pools.size() - 1] as Node3D).position.y
	print("RIVER crater near=%s depth=%.2f pools=+%d pool_y=%.2f" % [G.terrain.near_river(cp, 12.0), -G.terrain.ground_hs(cp), G.terrain.pools.size() - p0, pool_y])
	if G.terrain.pools.size() == p0 or absf(pool_y - (Terrain.WATER_Y + 0.03)) > 0.05:
		fails += 1
	_cam(cp, 18.0)
	await m._wait(0.2)
	await m._shot("river_crater")
	print("RIVERTEST RESULT fails=%d" % fails)

# 141: çekili topa / uçaksavar topuna gelen ateş başındaki askerlere işler; hafif silahla yıpratılan top patlamaz,
# devre dışı kalır; ağır isabette mürettebat ölür; mürettebatı düşen top susar, gelen asker yerine geçer
func towcrew_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 50.0)
	var dead0 := 0
	for u in G.units:
		if u is Soldier and not u.alive:
			dead0 += 1
	# 1) uçaksavar topu hafif silahla: mermi başına mürettebat düşer
	var ag: Vehicle = m.spawn_vehicle(1, "aagun", c, 0.0)
	ag.fire_mode = 2
	await m._wait(0.5)
	var crew0 := ag.crew_n
	var first_cas := -1
	for i in 60:
		if not ag.alive:
			break
		ag.take_damage(18.0, null, "bullet")
		if first_cas < 0 and ag.crew_n < crew0:
			first_cas = i
	await m._wait(0.5)
	var bodies := 0
	for u in G.units:
		if u is Soldier and u.team == 1 and u.role == "crew" and (not u.alive or u.state == "wounded"):
			bodies += 1
	print("TOWCREW aagun crew %d -> %d first_casualty_hit=%d alive=%s mode=%s down_or_dead=%d" % [crew0, ag.crew_n, first_cas, ag.alive, ag.kill_mode, bodies])
	if first_cas < 0 or (not ag.alive and ag.kill_mode != "knocked") or bodies < crew0 - 1:
		fails += 1
	# 2) obüse top mermisi: mürettebat büyük ölçüde ölür
	var hw: Vehicle = m.spawn_vehicle(1, "howitzer", G.grid.nearest_free(c + Vector3(0, 0, 60), Grid.M_HEAVY), 0.0)
	hw.fire_mode = 2
	await m._wait(0.5)
	var known := {}
	for u in G.units:
		if u is Soldier:
			known[u] = true
	G.explode(hw.position + Vector3(0.5, 0, 0.5), 4.5, 400.0, "shell", 0, null)
	await m._wait(3.0)
	var n_after := 0
	var n_before := 0
	var survivors := 0
	for u in G.units:
		if u is Soldier and u.team == 1 and not known.has(u):
			# yalnız bu obüsün mürettebatından doğan askerler: ölü ya da yaralı / hırpalanmış sayılır
			if not u.alive or u.state == "wounded" or u.hp < 90.0:
				n_after += 1
			else:
				survivors += 1
	print("TOWCREW howitzer shell alive=%s crew_left=%d dead_or_hurt=%d unhurt_survivors=%d" % [hw.alive, hw.crew_n, n_after - n_before, survivors])
	if survivors > 1 or n_after - n_before < 2:
		fails += 1
	# 3) mürettebatı düşen top susar, gelen asker yerine geçer
	var fg: Vehicle = m.spawn_vehicle(0, "fieldgun", c + Vector3(-20, 0, 0), 0.0)
	await m._wait(0.5)
	while not fg.crew.is_empty():
		fg._crew_casualty(fg.crew[0], null)
	var silent := fg.crew_n == 0
	var rep: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(fg.position + Vector3(4, 0, 0), Grid.M_INF), null)
	rep.cmd_board(fg)
	for k in 30:
		await m._wait(0.5)
		if fg.crew_n > 0:
			break
	await m._wait(0.5)
	print("TOWCREW fieldgun silent=%s recrewed=%d bodies=%d needs_crew=%s rep=%s/%s d_entry=%.1f board_t=%s" % [silent, fg.crew_n, fg.crew.size(), fg.needs_crew(), rep.state if is_instance_valid(rep) else "-", rep.order if is_instance_valid(rep) else "-", rep.dist2_p(fg.entry_point(0)) if is_instance_valid(rep) else -1.0, rep.board_target != null if is_instance_valid(rep) else false])
	if not silent or fg.crew_n < 1 or fg.crew.size() != fg.crew_n:
		fails += 1
	_cam(c + Vector3(5, 0, 0), 30.0)
	await m._wait(0.3)
	await m._shot("towcrew")
	print("TOWCREWTEST RESULT fails=%d" % fails)

# 65/57: HUD görüntüleri — tim seçili, tek asker, tank, uyarılar (tasarım incelemesi için)
func hud_shots() -> void:
	m.get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	m.start_game("green_valley", {}, false, 11)
	G.deploy_t = 0.0
	await m._wait(1.0)
	var c := G.grid.nearest_free(G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 30.0, Grid.M_HEAVY)
	var sq := Squad.new(0, "1. Tim")
	G.squads.append(sq)
	var ss: Array = []
	for i in 6:
		ss.append(m.spawn_soldier(0, ["leader", "rifle", "rifle", "mg", "at", "medic"][i], G.grid.nearest_free(c + Vector3(i * 1.4, 0, 0), Grid.M_INF), sq))
	var tk: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(0, 0, 10), Grid.M_HEAVY), 0.0)
	G.say("İleri üs için uygun yer bulundu", c, 0)
	G.say("Düşman zırhlısı görüldü", c + Vector3(40, 0, 40), 0)
	_cam(c + Vector3(3, 0, 4), 34.0)
	G.player.clear_sel()
	for s in ss:
		G.player.select(s)
	await m._wait(1.0)
	await m._shot("hud_squad")
	G.player.clear_sel()
	G.player.select(ss[3])
	await m._wait(0.6)
	await m._shot("hud_soldier")
	G.player.clear_sel()
	G.player.select(tk)
	await m._wait(0.6)
	await m._shot("hud_tank")
	# drone operatörü: kendi emir ızgarası (Drone Kaldır / Drone İndir / İstasyon)
	var op: Soldier = m.spawn_soldier(0, "drone", G.grid.nearest_free(c + Vector3(-4, 0, 3), Grid.M_INF), sq)
	await m._wait(0.3)
	G.player.clear_sel()
	G.player.select(op)
	await m._wait(0.6)
	await m._shot("hud_drone")
	var fails := 0
	var ids: Array = []
	for b in G.hud._cmd_live:
		ids.append(b[1])
	print("HUD drone orders=%s" % [ids])
	if not ("minidrone" in ids and "dronerecall" in ids and "dronestation" in ids):
		fails += 1
	# tank: araç ızgarası (Saldır, Sis, Gövde Gizle)
	G.player.clear_sel()
	G.player.select(tk)
	await m._wait(0.4)
	ids.clear()
	for b in G.hud._cmd_live:
		ids.append(b[1])
	print("HUD tank orders=%s" % [ids])
	if not ("attack" in ids and "smoke" in ids and "hulldown" in ids) or "grenade" in ids:
		fails += 1
	# üzerine gelme kartı: tim seçiliyken düşman askerin üstüne gel
	var en: Soldier = m.spawn_soldier(1, "mg", G.grid.nearest_free(c + Vector3(16, 0, -10), Grid.M_INF), null)
	G.player.clear_sel()
	for s in ss:
		G.player.select(s)
	await m._wait(1.0)
	m.get_viewport().warp_mouse(G.cam.screen(en.position + Vector3(0, 0.7, 0)))
	await m._wait(0.4)
	print("HUD hover=%s visible=%s text=%s / %s" % [G.hud.hover_u, G.hud.hover_card.visible, G.hud._hv_title.text, G.hud._hv_info.text])
	await m._shot("hud_hover")
	G.hud.toggle_pause()
	await m._wait(0.3)
	await m._shot("hud_pause")
	G.hud.toggle_pause()
	print("HUDSHOTS RESULT fails=%d" % fails)

# 146: grafik ön ayarlarının gerçek başarım farkı. Büyük çatışma (iki karşılaşma ~110 birlik) yakın kamerada;
# ön ayarlar sırayla dönüşümlü (savaşın gidişi bir ön ayarı kayırmasın) ölçülür: kare süresi ve GPU çizim
# süresi. Düşük ön ayarın GPU süresi yüksektekinin %70'inden azsa geçer. Oyuncunun ayarları sonda geri yüklenir.
func gfx_bench() -> void:
	m.get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var keep: Dictionary = m.cfg.duplicate(true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	m.start_game("green_valley", {}, false, 5)
	G.deploy_t = 0.0
	await m._wait(1.0)
	var c := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	m._skirmish(c)
	m._skirmish(c + Vector3(40, 0, -30))
	_cam(c + Vector3(15, 0, -10), 70.0)
	var vp := m.get_viewport()
	RenderingServer.viewport_set_measure_render_time(vp.get_viewport_rid(), true)
	await m._wait(3.0)
	# (154) zaman dizisi: sabit ön ayarda (düşük) çatışma ilerledikçe GPU ve çizim sayıları
	m.set_gfx_preset(0)
	var vr := vp.get_viewport_rid()
	for step in 8:
		var gs := 0.0
		for i in 20:
			await m.get_tree().process_frame
			gs += RenderingServer.viewport_get_measured_render_time_gpu(vr)
		print("GFXBENCH ts t=%.0f gpu_ms=%.1f draws=%d objs=%d prims=%dk units=%d nodes=%d" % [G.time, gs / 20.0, int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_OBJECTS_IN_FRAME)), int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000), G.units.size(), int(Performance.get_monitor(Performance.OBJECT_NODE_COUNT))])
		await m._wait(3.0)
	var names := ["düşük", "orta", "yüksek"]
	var frame := [0.0, 0.0, 0.0]
	var gpu := [0.0, 0.0, 0.0]
	var cnt := [0, 0, 0]
	for _rd in 1:
		for p in [2, 1, 0]:
			m.set_gfx_preset(p)
			m.test_phase("gfx %d/%d" % [_rd, p])
			for i in 20:
				await m.get_tree().process_frame
			var t0 := Time.get_ticks_usec()
			var g := 0.0
			var n := 90
			print("GFXBENCH tur=%d %s ms=%d" % [_rd, names[p], Time.get_ticks_msec()])
			for i in n:
				await m.get_tree().process_frame
				g += RenderingServer.viewport_get_measured_render_time_gpu(vp.get_viewport_rid())
			frame[p] += (Time.get_ticks_usec() - t0) / 1000.0 / n
			gpu[p] += g / n
			cnt[p] += 1
	var fails := 0
	for p in 3:
		frame[p] /= cnt[p]
		gpu[p] /= cnt[p]
		print("GFXBENCH %s frame_ms=%.1f fps=%.0f gpu_ms=%.2f" % [names[p], frame[p], 1000.0 / frame[p], gpu[p]])
	print("GFXBENCH units=%d" % G.units.size())
	# (154) bölüm ölçümü: her sistem tek tek kapatılıp kare süresindeki kazanç (işlemci payı)
	m.set_gfx_preset(0)
	for sec in ["all", "soldiers", "vehicles", "visibility", "fog", "hud", "icons", "ballistics", "props"]:
		_perf_part(sec, false)
		for i in 10:
			await m.get_tree().process_frame
		var t1 := Time.get_ticks_usec()
		var tp := 0.0
		var tph := 0.0
		for i in 60:
			await m.get_tree().process_frame
			tp += Performance.get_monitor(Performance.TIME_PROCESS)
			tph += Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)
		var ms := float(Time.get_ticks_usec() - t1) / 1000.0 / 60.0
		print("GFXBENCH off=%-10s frame_ms=%.1f process_ms=%.1f physics_ms=%.1f" % [sec, ms, tp / 60.0 * 1000.0, tph / 60.0 * 1000.0])
		_perf_part(sec, true)
	# GPU payı: yüksek ön ayarda kategori kategori gizleyip GPU süresi
	m.set_gfx_preset(2)
	var vrid := vp.get_viewport_rid()
	for part in ["none", "fx", "grass", "shadows", "trees", "units", "ssao", "msaa", "props_all", "world"]:
		var undo := _gpu_part(part, false)
		for i in 10:
			await m.get_tree().process_frame
		var g2 := 0.0
		for i in 40:
			await m.get_tree().process_frame
			g2 += RenderingServer.viewport_get_measured_render_time_gpu(vrid)
		print("GFXBENCH gpu_off=%-8s gpu_ms=%.1f prims=%dk draws=%d" % [part, g2 / 40.0, int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME) / 1000), int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))])
		undo.call()
	m.set_gfx_preset(0)
	Vehicle.prof = {}
	Vehicle.prof_on = true
	for f in 30:
		await m.get_tree().process_frame
	Vehicle.prof_on = false
	var ks: Array = Vehicle.prof.keys()
	ks.sort_custom(func(a, b): return Vehicle.prof[a] > Vehicle.prof[b])
	var line := ""
	for k in ks:
		line += "%s=%.1f " % [k, Vehicle.prof[k] / 30.0 / 1000.0]
	print("GFXBENCH unit_ms_per_frame %s" % line)
	if not (gpu[0] < gpu[2] * 0.7):
		fails += 1
		print("GFXBENCH FAIL düşük ön ayar GPU süresini yeterince düşürmüyor")
	m.cfg = keep
	m.apply_video()
	m.save_cfg()
	print("GFXBENCH RESULT fails=%d" % fails)

# 135: yıkık köprüye mühendislik aracı panel köprü kurar; bitince araç karşıya geçebilir
func bridge_rebuild_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	await m._wait(1.0)
	var br: Dictionary = {}
	for it in G.props.items:
		if it.get("kind", "") == "bridge" and it["alive"]:
			br = it
			break
	if br.is_empty():
		print("BRIDGEREBUILD no bridge")
		print("BRIDGEREBUILDTEST RESULT fails=1")
		return
	var c: Vector3 = br["pos"]
	var dir: Vector3 = br["dir"]
	# ortasından yık
	for k in 4:
		G.props.blast(c, 4.0, 900.0)
		if not br["alive"]:
			break
	await m._wait(2.0)
	print("BRIDGEREBUILD collapsed=%s gap=%s" % [not br["alive"], br.get("gap", {}).get("len", -1.0)])
	if br["alive"] or not br.has("gap"):
		fails += 1
	var gc: Vector3 = br["gap"]["gc"]
	var side_a: Vector3 = G.grid.nearest_free(c - dir * (float(br["L"]) * 0.5 + 12.0), Grid.M_HEAVY)
	var side_b: Vector3 = G.grid.nearest_free(c + dir * (float(br["L"]) * 0.5 + 12.0), Grid.M_HEAVY)
	var blocked := G.grid.find_path(side_a, side_b, Grid.M_HEAVY)
	var dz: Vehicle = m.spawn_vehicle(0, "usa_eng_m88", side_a, 0.0)
	await m._wait(0.5)
	# oyuncu yolu: araç seçili, yıkık köprüye sağ tık
	G.player.clear_sel()
	G.player.select(dz)
	_cam(gc, 45.0)
	await m._wait(0.5)
	G.player._command(G.cam.screen(gc), false, false)
	print("BRIDGEREBUILD job=%s order=%s" % [not dz.bridge_job.is_empty(), dz.order])
	if dz.bridge_job.is_empty():
		fails += 1
	var t0 := G.time
	var shot := false
	while G.time - t0 < 120.0 and not bool(br.get("repaired", false)):
		await m._wait(0.5)
		if not shot and float(br["gap"].get("built", 0.0)) > 0.5:
			shot = true
			_cam(gc, 30.0)
			await m._wait(0.2)
			await m._shot("bridge_building")
	print("BRIDGEREBUILD repaired=%s in %.0f s" % [br.get("repaired", false), G.time - t0])
	if not bool(br.get("repaired", false)):
		fails += 1
	await m._wait(1.0)
	_cam(gc, 30.0)
	await m._wait(0.4)
	await m._shot("bridge_done")
	# karşıya geçiş: bir araç öbür kıyıya
	var tr: Vehicle = m.spawn_vehicle(0, "truck", G.grid.nearest_free(side_a + Vector3(4, 0, 0), Grid.M_HEAVY), 0.0)
	tr.cmd_move(side_b)
	t0 = G.time
	var lt := -1
	while G.time - t0 < 60.0 and tr.position.distance_to(side_b) > 6.0:
		await m._wait(0.5)
		if int(G.time - t0) / 3 != lt:
			lt = int(G.time - t0) / 3
			print("BRIDGEREBUILD trk t=%d pos=(%.1f,%.1f) spd=%.1f order=%s path=%d/%d dest=(%.0f,%.0f) yield=%s" % [int(G.time - t0), tr.position.x, tr.position.z, tr.cur_speed, tr.order, tr.path_i, tr.path.size(), tr.dest.x, tr.dest.z, tr.get("_yield_to") != null])
	var crossed := tr.position.distance_to(side_b) < 8.0
	var pa := G.grid.find_path(side_a, side_b, Grid.M_HEAVY)
	var cells := PackedStringArray()
	for k in range(-8, 9):
		var q: Vector3 = gc + dir * float(k)
		cells.append("%d:w%d h%.2f k%d" % [k, int(G.grid.is_water(q)), G.grid.height_at(q), G.grid.kind_at(q)])
	print("BRIDGEREBUILD cells %s" % [" ".join(cells)])
	print("BRIDGEREBUILD dbg path_after=%d truck=(%.0f,%.0f) gc=(%.0f,%.0f) dz=(%.0f,%.0f) truck_path=%d/%d order=%s gap_cell_bridge=%s water=%s" % [pa.size(), tr.position.x, tr.position.z, gc.x, gc.z, dz.position.x, dz.position.z, tr.path_i, tr.path.size(), tr.order, G.grid.on_bridge(gc), G.grid.is_water(gc)])
	print("BRIDGEREBUILD path_before=%d crossed=%s truck_to_b=%.0f" % [blocked.size(), crossed, tr.position.distance_to(side_b)])
	if not crossed:
		fails += 1
	print("BRIDGEREBUILDTEST RESULT fails=%d" % fails)

# 76: Chinook tipi nakliye — en çok 7 asker YA DA 1 ZPT; ZPT rampadan içeri girer (gizli, görülmez), taşınır,
# inişte rampadan çıkar; ZPT taşırken asker almaz
func chinook_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 60.0)
	var h: Vehicle = m.spawn_vehicle(0, "usa_heli_ch47", c + Vector3(-25, 0, 0), 0.0)
	h.fire_mode = 2
	var apc: Vehicle = m.spawn_vehicle(0, "apc", G.grid.nearest_free(c + Vector3(15, 0, 0), Grid.M_HEAVY), 0.0)
	await m._wait(2.0)
	print("CHINOOK capacity=%d can_sling_apc=%s" % [h.capacity(), h.can_sling(apc)])
	if h.capacity() != 7 or not h.can_sling(apc):
		fails += 1
	# oyuncu yolu: ZPT seçili, helikoptere sağ tık
	G.player.clear_sel()
	G.player.select(apc)
	_cam(h.position, 60.0)
	await m._wait(0.5)
	G.player._command(G.cam.screen(h.aim_point()), false, false)
	print("CHINOOK rightclick sling_tgt=%s" % [h.sling_tgt == apc])
	if h.sling_tgt != apc:
		fails += 1
		h.cmd_sling(apc)
	var t0 := G.time
	var lastp := -1
	while G.time - t0 < 60.0 and apc.carried_in != h:
		await m._wait(0.2)
		if int(G.time - t0) != lastp:
			lastp = int(G.time - t0)
			print("CHINOOK dbg t=%d heli=(%.0f,%.0f) alt=%.2f tgt=%s inner=%s land_hold=%s order=%s apc=(%.0f,%.0f) apc_order=%s mouth_d=%.1f" % [lastp, h.position.x, h.position.z, h.hull.position.y, h.sling_tgt != null, h.inner_load, h.land_hold, h.order, apc.position.x, apc.position.z, apc.order, apc.position.distance_to(h.ramp_mouth())])
	var inside := apc.carried_in == h
	print("CHINOOK loaded=%s (%.1f s) apc_visible=%s" % [inside, G.time - t0, apc.visible])
	if not inside or apc.visible:
		fails += 1
	# ZPT taşırken asker alamaz
	var s: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(h.position + Vector3(6, 0, 0), Grid.M_INF), null)
	print("CHINOOK can_load_while_apc=%s" % h.can_load())
	if h.can_load():
		fails += 1
	s.queue_free()
	# taşı ve indir
	await m._wait(3.0)
	var drop := G.grid.nearest_free(c + Vector3(-25, 0, 70), Grid.M_HEAVY)
	h.cmd_move(drop)
	t0 = G.time
	while G.time - t0 < 40.0 and h.position.distance_to(drop) > 3.0:
		await m._wait(0.2)
	h.unload()
	t0 = G.time
	while G.time - t0 < 30.0 and apc.carried_in != null:
		await m._wait(0.2)
	await m._wait(3.0)
	var moved: float = apc.position.distance_to(c)
	print("CHINOOK unloaded=%s apc_visible=%s apc_from_start=%.0f m on_ground=%s" % [apc.carried_in == null, apc.visible, moved, absf(apc.position.y - G.terrain.ground_h(apc.position)) < 0.5])
	if apc.carried_in != null or not apc.visible or moved < 40.0:
		fails += 1
	print("CHINOOKTEST RESULT fails=%d" % fails)

# 101 / 111: obüs mürettebatı yakın çekim — ateşleme ipi (gergin / çekiş), mermi taşıma (bel hizasında, ellerde)
func crew_shots() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 31)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(1.0)
	G.hud.root.visible = false
	if G.main.sandbox_ui and is_instance_valid(G.main.sandbox_ui):
		G.main.sandbox_ui.visible = false
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 - 30.0, 0, G.MAP * 0.5 + 20.0), Grid.M_HEAVY)
	G.props.clear_area(c, 25.0)
	var gun: Vehicle = m.spawn_vehicle(0, "howitzer", c, 0.0)
	var tgt: Vehicle = m.spawn_vehicle(1, "truck", G.grid.nearest_open(c + gun.forward() * 300.0, Grid.M_HEAVY), 0.0)
	tgt.hp = 1e9
	tgt.max_hp = 1e9
	await m._wait(1.0)
	gun.cmd_attack(tgt)
	var shots := {}
	var t0 := G.time
	var fails := 0
	while G.time - t0 < 60.0 and shots.size() < 3:
		await m._wait(0.05)
		if gun.crew_cycle <= 0.0 or gun.main_cd <= 0.0:
			continue
		var p: float = 1.0 - clampf(gun.main_cd / gun.crew_cycle, 0.0, 1.0)
		var key := ""
		if p > 0.95 and not shots.has("lanyard"):
			key = "lanyard"
		elif p < 0.05 and not shots.has("pull"):
			key = "pull"
		elif p > 0.64 and p < 0.7 and not shots.has("carry"):
			key = "carry"
		if key != "":
			shots[key] = true
			G.cam.size = 7.0
			G.cam.target_size = 7.0
			G.cam.jump_to(gun.position, true)
			await m._shot("crew_" + key)
			if key == "carry":
				var cb: SoldierBody = gun.crew[1]
				var hr: Vector3 = cb.fore_r.global_transform * Vector3(0, -SoldierBody.HAND_LEN, 0)
				var hl: Vector3 = cb.fore_l.global_transform * Vector3(0, -SoldierBody.HAND_LEN, 0)
				var sp: Vector3 = cb._tool_mi.global_position if cb._tool_mi != null else Vector3.INF
				print("CREW carry hands_dist=%.2f shell_to_mid=%.2f hand_h=%.2f" % [hr.distance_to(hl), sp.distance_to((hr + hl) * 0.5) if sp != Vector3.INF else -1.0, (hr.y + hl.y) * 0.5 - cb.global_position.y])
				if sp == Vector3.INF or sp.distance_to((hr + hl) * 0.5) > 0.2:
					fails += 1
			if key == "lanyard":
				print("CREW cord visible=%s" % [gun._cord != null and gun._cord.visible])
				if gun._cord == null or not gun._cord.visible:
					fails += 1
	print("CREW shots=%s" % [shots.keys()])
	if shots.size() < 3:
		fails += 1
	print("CREWSHOTS RESULT fails=%d" % fails)

# 149 (inceleme dersi): oyuncunun yerleştirdiği siper hendekleri, tel ve hurdalar arasından büyük grup (12 asker +
# 4 araç) hedefe ulaşabilmeli; kimse 60 sn'de takılıp kalmamalı, asker araç gövdesinin içine girmemeli
func obstacle_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 23)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	await m._wait(1.0)
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 - 40.0, 0, G.MAP * 0.5 + 50.0), Grid.M_HEAVY)
	G.props.clear_area(c, 45.0)
	# engel kuşağı: üç kesik hendek hattı, bir tel, iki hurda (aralarında boşluk var)
	for k in 3:
		var z := -8.0 + k * 8.0
		var sh := 6.0 if k == 1 else -6.0
		var ln: Building = m.place_line(0, "trench", c + Vector3(-14 + sh, 0, z), c + Vector3(10 + sh, 0, z))
		ln.complete()
	var wr: Building = m.place_line(0, "wire", c + Vector3(-20, 0, 14), c + Vector3(4, 0, 14))
	wr.complete()
	for p in [c + Vector3(-4, 0, -14), c + Vector3(8, 0, 4)]:
		var w: Vehicle = m.spawn_vehicle(1, "truck", G.grid.nearest_open(p, Grid.M_HEAVY), 0.7)
		w.force_mode = "knocked"
		w.take_damage(1e6, null, "ap")
	await m._wait(1.5)
	var start := c + Vector3(0, 0, -28)
	var goal := c + Vector3(0, 0, 30)
	var units: Array = []
	var sq := Squad.new(0, "Tim")
	G.squads.append(sq)
	for i in 12:
		var s: Soldier = m.spawn_soldier(0, ["rifle", "mg", "at", "rifle"][i % 4], G.grid.nearest_free(start + Vector3((i % 6) * 1.5 - 4, 0, (i / 6) * 1.5), Grid.M_INF), sq)
		s.fire_mode = 2
		units.append(s)
	for i in 4:
		var v: Vehicle = m.spawn_vehicle(0, ["tank", "apc", "truck", "technical"][i], G.grid.nearest_open(start + Vector3(-12 + i * 8, 0, -8), Grid.M_HEAVY), 0.0)
		v.fire_mode = 2
		units.append(v)
	await m._wait(0.5)
	G.player.clear_sel()
	for u in units:
		G.player.select(u)
	G.player.move_group(units, goal)
	await m._wait(2.0)
	for u in units:
		if u is Vehicle:
			print("OBSTACLE dbg %s pos=(%.0f,%.0f) order=%s path=%d/%d dest=(%.0f,%.0f) speed=%.1f immobile=%s crew=%d" % [u.vtype, u.position.x, u.position.z, u.order, u.path_i, u.path.size(), u.dest.x, u.dest.z, u.cur_speed, u.immobile(), u.crew_n])
	var t0 := G.time
	var inside_max := 0.0
	while G.time - t0 < 60.0:
		await m._wait(0.5)
		var arrived := units.filter(func(u): return is_instance_valid(u) and u.alive and Vector2(u.position.x - goal.x, u.position.z - goal.z).length() < 16.0).size()
		# araç gövdesi içinde asker
		for s in units:
			if s is Soldier and s.alive and s.state != "aboard":
				for v in units:
					if v is Vehicle and v.alive:
						var q: Vector3 = v.obb_closest(s.position)
						var d := Vector2(q.x - s.position.x, q.z - s.position.z).length()
						if d < 0.05:
							inside_max = maxf(inside_max, 1.0)
		if arrived == units.size():
			break
	var stuck: Array = []
	for u in units:
		if is_instance_valid(u) and u.alive and Vector2(u.position.x - goal.x, u.position.z - goal.z).length() >= 16.0:
			stuck.append("%s@(%.0f,%.0f)" % [u.role if u is Soldier else u.vtype, u.position.x, u.position.z])
	_cam(c, 50.0)
	await m._wait(0.2)
	await m._shot("obstacle_end")
	print("OBSTACLE arrived=%d/%d t=%.0f stuck=%s soldier_inside_vehicle=%s" % [units.size() - stuck.size(), units.size(), G.time - t0, stuck, inside_max > 0.0])
	if not stuck.is_empty() or inside_max > 0.0:
		fails += 1
	print("OBSTACLETEST RESULT fails=%d" % fails)

# 113: iki çit arasında kalan / çitlerin arasından geçen asker kendiliğinden yere yatmamalı
func fence_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 31)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	await m._wait(1.0)
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 - 50.0, 0, G.MAP * 0.5 + 40.0), Grid.M_INF)
	G.props.clear_area(c, 16.0)
	# 1,6 m aralıklı iki paralel çit (koridor) + geçiş
	G.mapgen.fence(c + Vector3(-8, 0, -0.8), c + Vector3(8, 0, -0.8))
	G.mapgen.fence(c + Vector3(-8, 0, 0.8), c + Vector3(8, 0, 0.8))
	await m._wait(0.5)
	var ss: Array = []
	for i in 3:
		var s: Soldier = m.spawn_soldier(0, ["rifle", "mg", "at"][i], c + Vector3(-6.0 + i * 1.5, 0, 0), null)
		s.fire_mode = 2
		ss.append(s)
	await m._wait(0.5)
	for s in ss:
		s.cmd_move(s.position + Vector3(10, 0, 0))
	var prone_t := 0.0
	var poses := {}
	var t0 := G.time
	while G.time - t0 < 10.0:
		await m._wait(0.2)
		for s in ss:
			var pz: String = s._pose()
			poses[pz] = int(poses.get(pz, 0)) + 1
			if s.stance == Soldier.PRONE or pz in ["prone", "crawl", "vault"]:
				prone_t += 0.2
	_cam(c, 14.0)
	await m._wait(0.2)
	await m._shot("fence_corridor")
	print("FENCE poses=%s prone_or_vault_s=%.1f body_lift=%s" % [poses, prone_t, ss.map(func(s): return snappedf(s.body_lift, 0.01))])
	if prone_t > 1.0:
		fails += 1
	# (2) dik geçiş: iki çitin üstünden karşıya, sonra iki çit arasında dur — uzaktan hafif ateş altında
	for s in ss:
		s.position = G.grid.nearest_free(Vector3(s.position.x, 0, c.z - 4.0), Grid.M_INF, 2)
		s.cmd_move(Vector3(s.position.x, 0, c.z + 4.0))
	poses.clear()
	var prone2 := 0.0
	t0 = G.time
	while G.time - t0 < 8.0:
		await m._wait(0.2)
		for s in ss:
			var pz: String = s._pose()
			poses[pz] = int(poses.get(pz, 0)) + 1
			if pz in ["prone", "crawl"]:
				prone2 += 0.2
	print("FENCE cross poses=%s prone_s=%.1f" % [poses, prone2])
	if prone2 > 1.0:
		fails += 1
	var foe: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(0, 0, 60), Grid.M_INF), null)
	foe.hp = 1e9
	for s in ss:
		s.cmd_move(Vector3(s.position.x, 0, c.z))
	await m._wait(4.0)
	for s in ss:
		s.add_suppression(30.0, foe.position)
	poses.clear()
	var prone3 := 0.0
	t0 = G.time
	while G.time - t0 < 6.0:
		await m._wait(0.2)
		for s in ss:
			var pz: String = s._pose()
			poses[pz] = int(poses.get(pz, 0)) + 1
			if pz in ["prone", "crawl", "prone_aim"]:
				prone3 += 0.2
	await m._shot("fence_between")
	print("FENCE between poses=%s prone_s=%.1f cover=%s" % [poses, prone3, ss.map(func(s): return s.cover_type)])
	print("FENCETEST RESULT fails=%d" % fails)

# 127: patlayan araç çevresindeki ot tutuşur, alev halkası yayılır, bitince yanmış iz + kararmış ot
func grassfire_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 31)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	await m._wait(1.0)
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 + 40.0, 0, G.MAP * 0.5 - 30.0), Grid.M_HEAVY)
	var tries := 0
	while G.terrain.on_road(c) and tries < 20:
		c = G.grid.nearest_open(c + Vector3(8, 0, 6), Grid.M_HEAVY)
		tries += 1
	_cam(c, 30.0)
	await m._wait(2.0)
	var v: Vehicle = m.spawn_vehicle(1, "truck", c, 0.3)
	v.force_mode = "brew"
	await m._wait(0.5)
	var n_em0: int = G.fx.emitters.filter(func(e): return e[2] == "grassfire").size()
	v.take_damage(1e6, null, "rpg")
	await m._wait(0.3)
	var gf: Array = G.fx.emitters.filter(func(e): return e[2] == "grassfire")
	print("GRASSFIRE started=%d" % (gf.size() - n_em0))
	if gf.size() <= n_em0:
		fails += 1
	await m._wait(8.0)
	_cam(c, 22.0)
	await m._wait(0.2)
	await m._shot("grassfire_spread")
	var mr: float = gf[0][6] if not gf.is_empty() else 6.0
	await m._wait(mr / 0.3 + 2.0)
	# kararmış ot sayısı
	var burnt := 0
	for n in m.get_tree().get_nodes_in_group("zoom_grass"):
		var mm: MultiMesh = (n as MultiMeshInstance3D).multimesh
		if mm == null or not mm.use_colors:
			continue
		for i in mm.instance_count:
			var o := mm.get_instance_transform(i).origin
			if Vector2(o.x - c.x, o.z - c.z).length() < mr and mm.get_instance_color(i).r < 0.12:
				burnt += 1
	_cam(c, 22.0)
	await m._wait(0.3)
	await m._shot("grassfire_after")
	print("GRASSFIRE max_r=%.1f burnt_grass=%d" % [mr, burnt])
	if burnt < 10:
		fails += 1
	print("GRASSFIRETEST RESULT fails=%d" % fails)

# 155: derin suda yüzme — asker nehrin karşısına gönderilir: derin kısımda "swim" pozu, gövde su yüzeyinde
# (dipte yürümez), karşı kıyıya çıkar
func swim_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	await m._wait(1.0)
	# en derin nehir noktası (köprüden uzak)
	var best := Vector3.INF
	var bd := 0.0
	for i in 3000:
		var q := Vector3(randf_range(20, G.MAP - 20), 0, randf_range(20, G.MAP - 20))
		if not G.grid.is_water(q) or G.grid.on_bridge(q) or not G.grid.bridge_at(q).is_empty():
			continue
		var dep := Terrain.WATER_Y - G.terrain.ground_hs(q)
		var near_br := false
		for b in G.grid.bridges:
			if (b["c"] as Vector3).distance_to(q) < 40.0:
				near_br = true
		if dep > bd and not near_br:
			bd = dep
			best = q
	print("SWIM deepest=%.2f m at %s" % [bd, best])
	if best == Vector3.INF or bd < 1.21:
		print("SWIMTEST RESULT fails=1")
		return
	# kıyıdan kıyıya: en yakın iki kuru nokta (karşılıklı)
	var dirs := [Vector3(1, 0, 0), Vector3(0, 0, 1), Vector3(1, 0, 1).normalized(), Vector3(1, 0, -1).normalized()]
	var a_pt := Vector3.INF
	var b_pt := Vector3.INF
	var bw := 1e9
	for d in dirs:
		var pa := Vector3.INF
		var pb := Vector3.INF
		for k in range(1, 60):
			if pa == Vector3.INF and not G.grid.is_water(best - d * k):
				pa = best - d * (k + 4)
			if pb == Vector3.INF and not G.grid.is_water(best + d * k):
				pb = best + d * (k + 4)
		if pa != Vector3.INF and pb != Vector3.INF and pa.distance_to(pb) < bw:
			bw = pa.distance_to(pb)
			a_pt = pa
			b_pt = pb
	# yaya yol bulma suyu dolaşır (asker nehri kendiliğinden yüzerek geçmez); yüzme suya düşen / itilen askerde:
	# asker derin noktaya konur, kıyıya çıkması beklenir (140'taki "en yakın kuru yer" davranışı)
	var s: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(a_pt, Grid.M_INF, 4), null)
	s.fire_mode = 2
	await m._wait(0.3)
	s.position = Vector3(best.x, Terrain.WATER_Y - 1.0, best.z)
	s.cmd_stop()
	b_pt = G.grid.nearest_dry(best, 30.0)
	var swam := false
	var min_y := 9.0
	var shot := false
	var t0 := G.time
	while G.time - t0 < 90.0 and s.position.distance_to(b_pt) > 3.0:
		await m._wait(0.2)
		if s.swimming():
			if s._pose() == "swim":
				swam = true
			min_y = minf(min_y, s.position.y)
			if not shot and s.position.distance_to(best) < 6.0:
				shot = true
				_cam(s.position, 9.0)
				await m._wait(0.1)
				await m._shot("swim_mid")
	print("SWIM swam=%s min_body_y=%.2f (surface %.2f) reached=%s t=%.0f" % [swam, min_y, Terrain.WATER_Y, s.position.distance_to(b_pt) <= 3.5, G.time - t0])
	if not swam or min_y < Terrain.WATER_Y - 1.5 or s.position.distance_to(b_pt) > 3.5:
		fails += 1
	print("SWIMTEST RESULT fails=%d" % fails)

# 142: hurda görünümü yakın çekim — tank, ZPT, kamyon "knocked" (uzun alev yok) imha, yangın sönünce
func wreck_shots() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 31)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(1.0)
	G.hud.root.visible = false
	if G.main.sandbox_ui and is_instance_valid(G.main.sandbox_ui):
		G.main.sandbox_ui.visible = false
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5 + 30.0, 0, G.MAP * 0.5 + 30.0), Grid.M_HEAVY)
	G.props.clear_area(c, 30.0)
	var vs: Array = []
	var kinds := ["rus_mbt_72b3", "apc", "truck", "rus_mbt_90m"]
	for i in kinds.size():
		var v: Vehicle = m.spawn_vehicle(1, kinds[i], G.grid.nearest_open(c + Vector3(-9.0 + i * 9.0, 0, 0), Grid.M_HEAVY), 0.5)
		v.cmd_hold()
		v.fire_mode = 2
		v.force_mode = "knocked" if i < 3 else "catastrophic"
		vs.append(v)
	await m._wait(1.0)
	for v in vs:
		v.take_damage(1e6, null, "ap")
	# alev ve duman (fx) sahnede kalır; görüntüden önce efektleri temizle
	await m._wait(3.0)
	if G.fx != null and G.fx.has_method("clear_all"):
		G.fx.clear_all()
	for v in vs:
		var kinds_m := {}
		for mi in v._meshes(v):
			var mm: MeshInstance3D = mi
			if mm.mesh == null:
				continue
			for s in mm.mesh.get_surface_count():
				var mt = mm.get_surface_override_material(s)
				if mt == null:
					mt = mm.material_override
				var key := "null"
				if mt is ShaderMaterial:
					key = "SM:" + String((mt as ShaderMaterial).shader.resource_path).get_file() + (" burnt=%s" % (mt as ShaderMaterial).get_shader_parameter("burnt"))
				elif mt != null:
					key = mt.get_class() + ":" + String(mt.resource_name)
				kinds_m[key] = int(kinds_m.get(key, 0)) + 1
		print("WRECK mats %s %s" % [v.vtype, kinds_m])
	for i in vs.size():
		G.cam.size = 11.0
		G.cam.target_size = 11.0
		G.cam.jump_to(vs[i].position, true)
		await m._wait(0.5)
		G.cam.jump_to(vs[i].position, true)
		await m._shot("wreck_%d_%s" % [i, kinds[i]])
	print("WRECKSHOTS RESULT fails=0")

# 145: zemin görüntüleri (arayüz gizli): yeşil / çöl / kış haritası, orta ve geniş yakınlaştırma — zemin dokusu
# değişikliklerini önce / sonra karşılaştırmak için (gs_<harita>_<boy>)
func ground_shots() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	for mp in ["green_valley", "desert_canal", "winter_village"]:
		m.start_game(mp, {}, true, 7)
		G.fog_off = true
		G.reveal = [999.0, 999.0]
		for a in G.ais:
			a.queue_free()
		G.ais.clear()
		await m._wait(4.5)
		G.hud.root.visible = false
		if G.main.sandbox_ui and is_instance_valid(G.main.sandbox_ui):
			G.main.sandbox_ui.visible = false
		var c := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
		for sz in [45.0, 110.0]:
			G.cam.size = sz
			G.cam.target_size = sz
			G.cam.pitch = CamRig.PITCH
			G.cam.target_pitch = CamRig.PITCH
			G.cam.jump_to(c, true)
			await m._wait(0.8)
			G.cam.size = sz
			G.cam.jump_to(c, true)
			await m._shot("gs_%s_%d" % [mp, int(sz)])
		G.hud.root.visible = true
	print("GROUNDSHOTS RESULT fails=0")

# Modelleme aşaması (60/66/74/80/85/124/126): asker pozları yan / alçak açıdan yakın çekim. Düz, kuru, temizlenmiş
# alan; askerler kameraya yandan (profil) bakar. pg_aim: nişan duruşları (ayakta / çömel / yüzüstü tüfek, MG, AT,
# keskin nişancı), pg_idle: aynı duruşlar ateş kesik (bekleme), pg_walk_k / pg_run_k / pg_crouch_k: yürüyüş, koşu,
# çömelerek yürüyüş döngüsünden kareler (ayak yere basıyor mu, kollar, silah).
func pose_gallery() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(1.5)
	if G.main.sandbox_ui and is_instance_valid(G.main.sandbox_ui):
		G.main.sandbox_ui.visible = false
	# kuru, düz yer: haritanın ortasından halka halka ara
	var c := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var far_from_houses := func(q: Vector3) -> bool:
		for h in G.blocks.houses:
			if (h["center"] as Vector3).distance_to(q) < 45.0:
				return false
		return true
	for r in [0.0, 30.0, 60.0, 90.0, 120.0, 150.0]:
		var found := false
		for k in 16:
			var q := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5) + Vector3(cos(k * TAU / 16.0), 0, sin(k * TAU / 16.0)) * float(r)
			q = Vector3(clampf(q.x, 40.0, G.MAP - 40.0), 0, clampf(q.z, 40.0, G.MAP - 40.0))
			if not G.terrain.near_river(q, 40.0) and far_from_houses.call(q) and absf(G.terrain.ground_h(q + Vector3(6, 0, 0)) - G.terrain.ground_h(q - Vector3(6, 0, 0))) < 0.3:
				c = q
				found = true
				break
		if found:
			break
	G.props.clear_area(c, 26.0)
	# boşta asker kendiliğinden bir yöne (düşman üssü) bakar: o yönü ölç, kamerayı ona dik çevir (profil)
	var probe := m.spawn_soldier(0, "rifle", G.grid.nearest_free(c, Grid.M_INF, 2), null)
	probe.cmd_hold()
	probe.fire_mode = 2
	await m._wait(2.0)
	var ry: float = probe.rotation.y
	probe.queue_free()
	G.cam.yaw = ry + PI * 0.5
	G.cam.target_yaw = G.cam.yaw
	await m._wait(0.2)
	# ekranın sağı ve derinliği doğrudan kameranın kendi ekseninden (askerler profilden görünsün)
	var cb: Basis = G.cam.cam.global_transform.basis
	var R: Vector3 = Vector3(cb.x.x, 0, cb.x.z).normalized()
	var F: Vector3 = Vector3(-cb.z.x, 0, -cb.z.z).normalized()
	var foe := m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + R * 32.0, Grid.M_INF), null)
	foe.cmd_hold()
	foe.hp = 1e9
	foe.fire_mode = 2
	var kinds := [["rifle", Soldier.STAND], ["rifle", Soldier.CROUCH], ["rifle", Soldier.PRONE], ["mg", Soldier.STAND], ["at", Soldier.STAND], ["sniper", Soldier.CROUCH], ["medic", Soldier.STAND]]
	var rows: Array = [[], []]
	for row in 2:
		for i in kinds.size():
			var p: Vector3 = c - R * 6.0 + R * (i * 2.0) + F * (row * 5.0)
			var s := m.spawn_soldier(0, kinds[i][0], G.grid.nearest_free(p, Grid.M_INF, 2), null)
			s.stance_lock = kinds[i][1]
			s.stance = kinds[i][1]
			s.cmd_hold()
			s.fire_mode = 0 if row == 0 else 2
			s.rotation.y = Soldier._yaw_of(R)
			rows[row].append(s)
	await m._wait(4.0)
	var close := func(p: Vector3, sz: float) -> void:
		# açılış kamera uçuşu yakınlaştırmayı ezmesin: her çekimden önce yeniden
		G.cam.pitch = 12.0
		G.cam.target_pitch = 12.0
		G.cam.size = sz
		G.cam.target_size = sz
		G.cam.jump_to(p, true)
	close.call(c + R * 0.5, 9.0)
	await m._wait(0.5)
	close.call(c + R * 0.5, 9.0)
	await m._shot("pg_aim")
	close.call(c + R * 0.5 + F * 5.0, 9.0)
	await m._wait(0.5)
	close.call(c + R * 0.5 + F * 5.0, 9.0)
	await m._shot("pg_idle")
	# yakın: ikişer asker (el, tutuş, ayak)
	for row in 2:
		for i in range(0, kinds.size(), 2):
			var s0: Soldier = rows[row][i]
			close.call(s0.position + R * 1.0 + Vector3(0, 0, 0), 3.6)
			await m._wait(0.25)
			close.call(s0.position + R * 1.0, 3.6)
			await m._shot("pg_%s_%d" % ["aimc" if row == 0 else "idlec", i / 2])
	# çok yakın: eller ve tutuş (ayakta tüfek nişanda / beklemede, MG nişanda)
	for pr in [[0, 0], [1, 0], [0, 3]]:
		var sh: Soldier = rows[pr[0]][pr[1]]
		var chest: Vector3 = sh.position + F * (1.0 / tan(deg_to_rad(12.0)))
		close.call(chest, 2.0)
		await m._wait(0.25)
		close.call(chest, 2.0)
		await m._shot("pg_hand_%d_%d" % [pr[0], pr[1]])
		# tutuş ölçümü: avuç (ön kol pivotu + 0,33 m) ile silahın kabza / el kundağı noktası arası
		var bd: SoldierBody = sh.body
		var g: Array = bd._grip_points()
		var gr: Vector3 = bd.weapon.global_transform * (g[0] as Vector3)
		var gl: Vector3 = bd.weapon.global_transform * (g[1] as Vector3)
		var hr: Vector3 = bd.fore_r.global_transform * Vector3(0, -SoldierBody.HAND_LEN, 0)
		var hl: Vector3 = bd.fore_l.global_transform * Vector3(0, -SoldierBody.HAND_LEN, 0)
		print("POSE grip %s/%s pose=%s r=%.2f m l=%.2f m (r_to_l=%.2f gr_to_gl=%.2f)" % [sh.role, pr, sh._pose(), hr.distance_to(gr), hl.distance_to(gl), hr.distance_to(hl), gr.distance_to(gl)])
		# görünen deri iskeleti: el / ön kol kemiklerinin dünya konumu
		var sk: Skeleton3D = bd.skel
		if sk != null:
			var names := PackedStringArray()
			for bi in sk.get_bone_count():
				var bn := sk.get_bone_name(bi)
				if bn.to_lower().contains("hand") or bn.to_lower().contains("fore") or bn.to_lower().contains("lowerarm") or bn.to_lower().contains("wrist"):
					var bp: Transform3D = sk.global_transform * sk.get_bone_global_pose(bi)
					var wp: Vector3 = bp.origin
					# kemik +Y boyunca 0,33 m (glTF kemik ekseni) — görünen avucun yaklaşık yeri
					var tip: Vector3 = bp * Vector3(0, SoldierBody.HAND_LEN, 0)
					var piv: Vector3 = (bd.fore_r if bn.ends_with("r") else bd.fore_l).global_transform * Vector3(0, -SoldierBody.HAND_LEN, 0)
					names.append("%s d_r=%.2f d_l=%.2f tip_r=%.2f tip_l=%.2f tip_vs_pivot=%.2f" % [bn, wp.distance_to(gr), wp.distance_to(gl), tip.distance_to(gr), tip.distance_to(gl), tip.distance_to(piv)])
			print("POSE skin %s" % [", ".join(names)])
	for row in rows:
		for s in row:
			s.queue_free()
	# yürüyüş / koşu / çömelerek: üç asker (tüfek, MG, AT) aynı hızla yan yana
	for mode in ["walk", "run", "crouch"]:
		var ws: Array = []
		for i in 3:
			var p: Vector3 = c - R * 14.0 + F * (i * 1.6 - 1.6)
			var s := m.spawn_soldier(0, ["rifle", "mg", "at"][i], G.grid.nearest_free(p, Grid.M_INF, 2), null)
			s.fire_mode = 2
			if mode == "crouch":
				s.stance_lock = Soldier.CROUCH
			ws.append(s)
		await m._wait(0.3)
		for s in ws:
			s.cmd_move(s.position + R * 40.0, mode == "run")
		await m._wait(2.2)
		for k in 6:
			close.call(ws[1].position, 3.6)
			await m._wait(0.09)
			close.call(ws[1].position, 3.6)
			await m._shot("pg_%s_%d" % [mode, k])
		for s in ws:
			s.queue_free()
		await m._wait(0.3)
	print("POSEGALLERY RESULT fails=0")

# 65/57: HUD'a eklenen emirler oyunda gerçekten çalışıyor mu — Drone Kaldır → Drone İndir (çantaya döner),
# Binaya Gir → Binadan Çık, Saldır (imleç altındaki düşman), Gövde Gizle (uygun yer ya da yerinde mevzi)
func order_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, false, 11)
	G.deploy_t = 0.0
	await m._wait(1.0)
	var fails := 0
	# (1) drone
	var c := G.grid.nearest_free(G.hq_pos[0] + (G.hq_pos[1] - G.hq_pos[0]).normalized() * 30.0, Grid.M_HEAVY)
	var sq := Squad.new(0, "Drone")
	G.squads.append(sq)
	var op: Soldier = m.spawn_soldier(0, "drone", c, sq)
	await m._wait(0.5)
	var n0 := op.fpv_left
	op.cmd_minidrone(c + Vector3(25, 0, 10))
	var t0 := G.time
	while G.time - t0 < 8.0 and (op.my_drone == null or not is_instance_valid(op.my_drone)):
		await m._wait(0.2)
	var up := op.my_drone != null and is_instance_valid(op.my_drone)
	await m._wait(3.0)
	var rec := op.cmd_recall_drone()
	t0 = G.time
	while G.time - t0 < 25.0 and op.my_drone != null and is_instance_valid(op.my_drone):
		await m._wait(0.2)
	print("ORDER drone up=%s recall=%s back=%s fpv %d->%d (%.1f s)" % [up, rec, op.my_drone == null, n0, op.fpv_left, G.time - t0])
	if not (up and rec and op.my_drone == null and op.fpv_left == n0):
		fails += 1
	# (2) binaya gir / çık (oyuncu emri üzerinden)
	var hid := -1
	var bd := 1e9
	for i in G.blocks.houses.size():
		if Soldier.house_enterable(i):
			var d: float = G.blocks.houses[i]["center"].distance_to(c)
			if d < bd:
				bd = d
				hid = i
	var hc: Vector3 = G.blocks.houses[hid]["center"] if hid >= 0 else c
	var sq2 := Squad.new(0, "Tim")
	G.squads.append(sq2)
	var ss: Array = []
	for i in 4:
		ss.append(m.spawn_soldier(0, "rifle", G.grid.nearest_free(hc + Vector3(12 + i * 1.3, 0, 6), Grid.M_INF), sq2))
	await m._wait(0.5)
	G.player.clear_sel()
	for s in ss:
		G.player.select(s)
	print("ORDER dbg house_at(center)=%d sel=%d slot=%d team=%d" % [G.blocks.house_at(hc), G.player.selected.size(), G.blocks.house_free_slot(hid), G.blocks.house_team(hid)])
	G.player.exec_order("garrison", hc)
	print("ORDER dbg after: %s" % [ss.map(func(s): return [s.house_id, s.order, s.state])])
	t0 = G.time
	while G.time - t0 < 25.0 and not ss.all(func(s): return s.house_id >= 0 and s.state == "idle"):
		await m._wait(0.3)
	var inside := ss.filter(func(s): return s.house_id >= 0).size()
	G.player.exec_order("exitbldg", Vector3.INF)
	t0 = G.time
	while G.time - t0 < 25.0 and ss.any(func(s): return s.house_id >= 0 or s.state == "move"):
		await m._wait(0.3)
	var out := ss.filter(func(s): return s.house_id < 0 and G.blocks.house_at(s.position) != hid).size()
	print("ORDER garrison hid=%d inside=%d/4 out=%d/4" % [hid, inside, out])
	if hid < 0 or inside < 3 or out < 4:
		fails += 1
	# (3) saldır: imleç altındaki düşman
	var en: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(ss[0].position + Vector3(30, 0, 0), Grid.M_INF), null)
	en.fire_mode = 2
	_cam(en.position, 40.0)
	await m._wait(1.0)
	m.get_viewport().warp_mouse(G.cam.screen(en.position + Vector3(0, 0.7, 0)))
	await m._wait(0.5)
	var tu := G.player.unit_at(m.get_viewport().get_mouse_position())
	print("ORDER dbg mouse=%s en_scr=%s tu=%s en_vis=%s sel=%d" % [m.get_viewport().get_mouse_position(), G.cam.screen(en.position), tu, en.visible, G.player.selected.size()])
	G.player.exec_order("attack", en.position)
	var att := ss.filter(func(s): return s.forced_target == en).size()
	print("ORDER attack forced=%d/4" % att)
	if att < 4:
		fails += 1
	# (4) gövde gizle: tank, tehdit yönü verilir — uygun yer bulursa gider ve mevzi tutar, bulamazsa false
	var tk: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(-20, 0, -20), Grid.M_HEAVY), 0.0)
	await m._wait(0.5)
	var thr := tk.position + Vector3(120, 0, 0)
	var ok := tk.cmd_hulldown(thr)
	t0 = G.time
	while ok and G.time - t0 < 20.0 and not (tk.order == "hold" and tk.path_i >= tk.path.size()):
		await m._wait(0.3)
	print("ORDER hulldown ok=%s order=%s cover=%.2f" % [ok, tk.order, tk._cover_score(tk.position, thr)])
	if ok and tk.order != "hold":
		fails += 1
	print("ORDERTEST RESULT fails=%d" % fails)

# 65/57 + 146: ana menü eskiz teması görüntüleri; grafik ön ayarları gerçekten çizimi değiştiriyor mu
# (ayar dosyası oyuncunun gerçek dosyası: test sonunda eski hâline döner)
func menu_shots() -> void:
	m.get_window().size = Vector2i(1920, 1080)
	Sfx.muted = true
	var keep: Dictionary = m.cfg.duplicate(true)
	var fails := 0
	m.to_menu()
	await m._wait(2.5)
	await m._shot("menu_home")
	var mm: MainMenu = G.hud.menu
	mm.open_page("classic")
	await m._wait(0.4)
	await m._shot("menu_classic")
	mm.open_settings_tab("graphics")
	await m._wait(0.4)
	await m._shot("menu_graphics")
	# ön ayarlar
	var vp := m.get_viewport()
	m.set_gfx_preset(0)
	var low := [vp.scaling_3d_scale, vp.msaa_3d, m.env.ssao_enabled, Props.grass_k]
	print("MENU low scale=%.2f msaa=%d ssao=%s grass=%.2f" % low)
	if absf(low[0] - 0.67) > 0.01 or low[1] != Viewport.MSAA_DISABLED or low[2] or absf(low[3] - 0.35) > 0.01:
		fails += 1
		print("MENU FAIL düşük ön ayar uygulanmadı")
	m.set_gfx_preset(2)
	var high := [vp.scaling_3d_scale, vp.msaa_3d, m.env.ssao_enabled, Props.grass_k]
	print("MENU high scale=%.2f msaa=%d ssao=%s grass=%.2f" % high)
	if absf(high[0] - 1.0) > 0.01 or high[1] != Viewport.MSAA_2X or not high[2] or absf(high[3] - 1.0) > 0.01:
		fails += 1
		print("MENU FAIL yüksek ön ayar uygulanmadı")
	# tek ayar değişince "Özel" olur, diğer değerler korunur
	m.set_gfx("msaa", 1)
	print("MENU custom gfx=%d msaa=%d scale=%.2f" % [int(m.cfg.get("gfx", -1)), vp.msaa_3d, vp.scaling_3d_scale])
	if int(m.cfg.get("gfx", -1)) != 3 or vp.msaa_3d != Viewport.MSAA_2X or absf(vp.scaling_3d_scale - 1.0) > 0.01:
		fails += 1
		print("MENU FAIL özel ayar")
	mm.open_settings_tab("graphics")
	await m._wait(0.4)
	await m._shot("menu_graphics_custom")
	mm.open_settings_tab("keys")
	await m._wait(0.4)
	await m._shot("menu_keys")
	mm.open_page("")
	mm.confirm_quit()
	await m._wait(0.3)
	await m._shot("menu_quit")
	mm._close_confirm()
	# oyuncunun ayarlarını geri yükle
	m.cfg = keep
	m.apply_video()
	m.save_cfg()
	print("MENUSHOTS RESULT fails=%d" % fails)

# 136: kamera 360° döner (45° adım), serbest bakışta eğilir, seçili birime kilitlenir ve bırakılır
func cam_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tk: Vehicle = m.spawn_vehicle(0, "tank", c, 0.0)
	tk.fire_mode = 2
	_cam(c, 30.0)
	await m._wait(0.5)
	var vp := m.get_viewport().get_visible_rect().size
	var r0 := G.cam.right_vec()
	var center_err := 0.0
	for k in 4:
		await m._shot("cam_yaw_%d" % k)
		var g := G.cam.mouse_ground(vp * 0.5)
		center_err = maxf(center_err, Vector2(g.x - G.cam.focus.x, g.z - G.cam.focus.z).length())
		G.cam.rotate_step(1.0)
		await m._wait(0.8)
	var r4 := G.cam.right_vec()
	print("CAM after 4 steps yaw=%.2f right %s -> %s dot=%.2f center_err=%.2f" % [G.cam.yaw, r0, r4, r0.dot(r4), center_err])
	if r0.dot(r4) > -0.95 or center_err > 1.0:
		fails += 1
	# serbest bakış: dik eğim
	G.cam.target_pitch = 70.0
	await m._wait(0.8)
	await m._shot("cam_pitch70")
	G.cam.reset_view()
	await m._wait(0.9)
	var back_ok := absf(angle_difference(G.cam.yaw, CamRig.YAW0)) < 0.02 and absf(G.cam.pitch - CamRig.PITCH) < 0.5
	print("CAM reset yaw=%.2f pitch=%.1f ok=%s" % [G.cam.yaw, G.cam.pitch, back_ok])
	if not back_ok:
		fails += 1
	# kilit: hareket eden tankı izler
	G.cam.toggle_follow(tk)
	tk.cmd_move(G.grid.nearest_free(c + Vector3(40, 0, 25), Grid.M_HEAVY))
	await m._wait(6.0)
	var lag := Vector2(G.cam.focus.x - tk.position.x, G.cam.focus.z - tk.position.z).length()
	G.cam.toggle_follow(null)
	var released := G.cam.follow_unit == null
	print("CAM follow lag=%.2f moved=%.1f released=%s" % [lag, tk.position.distance_to(c), released])
	if lag > 2.0 or tk.position.distance_to(c) < 10.0 or not released:
		fails += 1
	print("CAMTEST RESULT fails=%d" % fails)

# 120: ikmal hattı kesilen ileri üs kararır (üretim durur, görüş daralır), teslimat gelince canlanır; normal
# ikmal döngüsünde kararmaz
func fobdark_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var hq: Vector3 = G.hq_pos[0]
	var fob: Building = m.place_building(0, "fob", G.grid.nearest_free(hq.lerp(G.hq_pos[1], 0.3), Grid.M_HEAVY), 0.0)
	fob.complete()
	G.logi.register_base(fob)
	await m._wait(1.0)
	var s0 := fob.sight
	# normal döngü: 40 sn içinde kamyon gelir, kararmaz
	var dark_seen := false
	for k in 40:
		await m._wait(1.0)
		if fob.dark:
			dark_seen = true
	print("FOBDARK normal_cycle dark_seen=%s supplied_ago=%.0f" % [dark_seen, G.time - fob.supplied_t])
	# hat kesildi: 200 sn teslimat yok
	fob.supplied_t = G.time - 200.0
	G.supply[0] = 99999
	fob.enqueue("rifle_squad")
	await m._wait(1.2)
	var dark_on := fob.dark
	var s1 := fob.sight
	var q_blocked: bool = not fob.queue.is_empty() and fob.queue[0]["blocked"]
	_cam(fob.position, 26.0)
	await m._wait(0.2)
	await m._shot("fob_dark")
	# teslimat
	fob.supplied_t = G.time
	await m._wait(1.2)
	print("FOBDARK cut dark=%s sight %.1f -> %.1f prod_blocked=%s | after_delivery dark=%s sight=%.1f" % [dark_on, s0, s1, q_blocked, fob.dark, fob.sight])
	if dark_seen or not dark_on or s1 >= s0 or not q_blocked or fob.dark or absf(fob.sight - s0) > 0.01:
		fails += 1
	print("FOBDARKTEST RESULT fails=%d" % fails)

# 120: yakına düşen canlı el bombasını kapıp kalan fitille geri atma
func nade_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_INF)
	G.props.clear_area(c, 60.0)
	var grabs := 0
	var thrown := 0
	var in_hand := 0
	var shot := false
	for round in 3:
		var pairs: Array = []
		for i in 6:
			var base := G.grid.nearest_free(c + Vector3(-40 + i * 16.0, 0, -10 + round * 0.0), Grid.M_INF)
			var df: Soldier = m.spawn_soldier(0, "rifle", base, null)
			var en: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(base + Vector3(0, 0, -16), Grid.M_INF), null)
			for s in [df, en]:
				s.fire_mode = 2
				s.cmd_hold()
			pairs.append([df, en, false, false])
		await m._wait(0.5)
		for pr in pairs:
			var df: Soldier = pr[0]
			var en: Soldier = pr[1]
			G.bal.grenade(en.position + Vector3(0, 1.8, 0), df.position + Vector3(randf_range(-1.5, 1.5), 0, 1.8), 1, en)
		for k in 100:
			await m._wait(0.05)
			for pr in pairs:
				var df: Soldier = pr[0]
				if not is_instance_valid(df):
					continue
				if df.state == "nade" and not pr[2]:
					pr[2] = true
					grabs += 1
					if not shot and df.nade_picked:
						shot = true
				if pr[2] and not pr[3] and df.state == "throw" and df.throw_released:
					pr[3] = true
					thrown += 1
		for pr in pairs:
			if pr[2] and not pr[3]:
				in_hand += 1
			for s in [pr[0], pr[1]]:
				if is_instance_valid(s):
					G.remove_unit(s)
					s.queue_free()
		await m._wait(0.3)
	print("NADE trials=18 grabs=%d thrown_back=%d blew_in_hand=%d" % [grabs, thrown, in_hand])
	if grabs == 0 or thrown < grabs - 1:
		fails += 1
	print("NADETEST RESULT fails=%d" % fails)

# 107: açıkta ateş altındaki tank yakındaki alçak duvarın arkasına geçip gövdesini gizler (taret duvarın üstünden
# görür); mevzi tut emrinde yerinden oynamaz
func hulldown_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var res: Array = []
	for hold in [false, true]:
		var base := c + Vector3(0 if not hold else -40.0, 0, 0)
		var tk: Vehicle = m.spawn_vehicle(0, "tank", base, 0.0)
		tk.fire_mode = 2
		var en: Vehicle = m.spawn_vehicle(1, "tank", base + Vector3(0, 0, -60), PI)
		en.cmd_hold()
		en.fire_mode = 2
		# alçak duvar: tankın 10 m sağında, tehdide 4 m önde
		var wc := base + Vector3(10, 0, -4.5)
		G.grid.set_static_rect(wc, Vector2(7.0, 0.6), 0.0, 1.25, Grid.K_WALL)
		var wm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(7.0, 1.25, 0.6)
		wm.mesh = bm
		G.main.world.add_child(wm)
		wm.global_position = wc + Vector3(0, 0.62, 0)
		G.grid.flush_nav()
		if hold:
			tk.cmd_hold()
		await m._wait(0.5)
		var s0 := tk._cover_score(tk.position, en.position)
		for k in 20:
			tk.last_hit = G.time
			tk._last_from = en.position
			tk.attacker = en
			await m._wait(0.5)
		var s1 := tk._cover_score(tk.position, en.position)
		var moved := tk.position.distance_to(base)
		print("HULLDOWN hold=%s cover %.2f -> %.2f moved=%.1f log=%s" % [hold, s0, s1, moved, tk.tac_log])
		res.append([hold, s1, moved])
		if not hold and (s1 < 0.5 or moved < 4.0):
			fails += 1
		if hold and moved > 1.0:
			fails += 1
		if not hold:
			_cam(tk.position + Vector3(0, 0, -6), 18.0)
			await m._wait(0.2)
			await m._shot("hulldown")
	print("HULLDOWNTEST RESULT fails=%d" % fails)

# 76 / 102: inmiş nakliye helikopterine (CH-47 arka rampa, UH-60 yan kapı) askerler sıra hâlinde, tek tek biner
func ramp_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	for hid in ["usa_heli_ch47", "usa_heli_uh60"]:
		var h: Vehicle = m.spawn_vehicle(0, hid, c, 0.0)
		h.fire_mode = 2
		h.request_land()
		await m._wait(6.0)
		var ss: Array = []
		var n := mini(7, h.capacity())
		for i in n:
			var s: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-10 + i * 1.4, 0, 16), Grid.M_INF), null)
			ss.append(s)
		await m._wait(0.3)
		for s in ss:
			s.cmd_board(h)
		var max_enter := 0
		var enter_t: Array = []
		var was := {}
		var t := 0.0
		var shot := false
		while t < 45.0 and h.cargo.size() < n:
			await m._wait(0.1)
			t += 0.1
			var ent := 0
			for s in ss:
				if s.state == "entering":
					ent += 1
					if not was.has(s):
						was[s] = true
						enter_t.append(t)
			max_enter = maxi(max_enter, ent)
			if not shot and h._ramp_q.size() >= 3:
				shot = true
				_cam(h.position - h.forward() * 6.0, 14.0)
				await m._wait(0.1)
				await m._shot("ramp_queue_%s" % hid)
		var min_gap := 99.0
		for i in range(1, enter_t.size()):
			min_gap = minf(min_gap, enter_t[i] - enter_t[i - 1])
		print("RAMP %s boarded=%d/%d t=%.1f max_on_ramp=%d min_gap=%.2f" % [hid, h.cargo.size(), n, t, max_enter, min_gap])
		if h.cargo.size() < n or max_enter > 1 or min_gap < 0.5:
			fails += 1
		for s in ss:
			if is_instance_valid(s):
				G.remove_unit(s)
				s.queue_free()
		G.remove_unit(h)
		h.queue_free()
		await m._wait(0.5)
	print("RAMPTEST RESULT fails=%d" % fails)

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
	var rope_gap := 0.0          # (102) halatın dibi yerden, tepesi koldan en çok ne kadar ayrık
	m.test_phase("rope_down")
	for i in 600:
		await m._wait(0.05)
		for r in h.ropes:
			var rm: MeshInstance3D = r[0]
			if is_instance_valid(rm) and float(rm.get_meta("ext", 0.0)) >= 0.999:
				var bot: Vector3 = rm.global_transform * Vector3(0, -1, 0)
				var top: Vector3 = rm.global_transform.origin
				rope_gap = maxf(rope_gap, maxf(absf(bot.y - G.terrain.ground_hs(bot)), top.distance_to(h.rope_anchor(r[1]))))
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
	await m._wait(3.0)
	# halatlar yere bırakılmaz, vinçle helikoptere çekilir: dünyada halat kalmamalı
	var left_ropes := 0
	for ch in G.main.world.get_children():
		if ch is MeshInstance3D and (ch as MeshInstance3D).mesh == Vehicle._rope_unit and Vehicle._rope_unit != null:
			left_ropes += 1
	print("ROPE gap_max=%.2f ropes_in_world_after=%d" % [rope_gap, left_ropes])
	if rope_gap > 0.2 or left_ropes > 0:
		fails += 1
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
		for s in ss:
			if not apc.cargo.has(s):
				print("CREW not_boarded state=%s order=%s pos=%s entry=%s d_entry=%.2f bt=%s path=%d/%d esc=%s cap=%d needs_crew=%s can_load=%s" % [s.state, s.order, s.position, apc.entry_point(0), s.dist2_p(apc.entry_point(0)), s.board_target != null, s.path_i, s.path.size(), s._escaping, apc.capacity(), apc.needs_crew(), apc.can_load()])
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
	# 98: piyade taşıma aracı (M1301 ISV, taban tip technical) 8 yolcu alır, yolcular içeride
	var isv: Vehicle = m.spawn_vehicle(G.player_team, "usa_lv_isv", G.grid.nearest_free(c + Vector3(-25, 0, 10), Grid.M_LIGHT), 0.6)
	isv.cmd_hold()
	for i in 8:
		var s: Soldier = m.spawn_soldier(G.player_team, "rifle", G.grid.nearest_free(isv.position + Vector3(-6 + i * 1.5, 0, 9), Grid.M_INF), null)
		s.cmd_board(isv)
	var t3 := G.time
	while G.time - t3 < 45.0 and isv.cargo.size() < 8:
		await m._wait(0.1)
	var vis_r: int = isv.cargo.filter(func(x): return x.visible).size()
	print("CREW isv capacity=%d boarded=%d visible_riders=%d t=%.1f" % [isv.capacity(), isv.cargo.size(), vis_r, G.time - t3])
	if isv.cargo.size() < 8 or vis_r > 0:
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
	# 110: her asker kendi görüşüyle (tim tek lider çokgeni değil) — timin dağılmış hâli
	for i in ss.size():
		var s: Soldier = ss[i]
		s.cmd_move(G.grid.nearest_free(mid + Vector3(-18.0 + i * 12.0, 0, 6.0), Grid.M_INF), true)
	await m._wait(8.0)
	var fow: FogOfWar = null
	for ch in G.main.world.get_children():
		if ch is FogOfWar:
			fow = ch
	if fow == null:
		for ch in G.main.get_children():
			if ch is FogOfWar:
				fow = ch
	var own := fow.owners(G.player_team).filter(func(x): return x is Soldier and ss.has(x)).size() if fow else -1
	print("FOW per_unit_owners=%d/%d" % [own, ss.size()])
	if fow != null and own < ss.size():
		fails += 1
	_cam(mid, 45.0)
	await m._wait(0.6)
	await m._shot("fow_02_squad")
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
	# (123) yerde kumaş gibi serili kubbeler
	_cam(c, 12.0)
	await m._wait(0.3)
	await m._shot("para_11_canopies")
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
	# binanın dar yanında, duvarın hemen dışında (iri yol hücresinde yapının köşesi kapalı: nearest_free dışarı iter)
	var f2: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(b.position + Vector3(0, 0, b.size.y * 0.5 + 0.8), Grid.M_INF), null)
	var e2: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(b.position - Vector3(0, 0, b.size.y * 0.5 + 0.8), Grid.M_INF), null)
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
	# doğurma engelden kaçırıp asgari menzilin dışına itebiliyordu (o zaman saldırı emri geçerli olur): yakına al
	if hw.dist2(tk) >= hw._min_range():
		hw.position = tk.position + (hw.position - tk.position).normalized() * hw._min_range() * 0.6
	print("STUCK howitzer d=%.1f min_range=%.1f" % [hw.dist2(tk), hw._min_range()])
	hw.cmd_attack(tk)
	m.test_phase("stuck")
	var t0 := G.time
	var hosp_killed := false
	var s1_t := -1.0
	var v1_t := -1.0
	var t2_fired := false
	var str_ok := false
	var hw_t := -1.0
	while G.time - t0 < 75.0:
		await m._wait(0.25)
		var el := G.time - t0
		if s1_t < 0.0 and s1.state != "move":
			s1_t = el
		if v1_t < 0.0 and v1.order == "":
			v1_t = el
		if hw_t < 0.0 and hw.order != "attack":
			hw_t = el
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
	print("STUCK aagun_refused=%s holdfire_attack_fired=%s howitzer_order=%s forced=%s dropped_at=%.1f tipped=%s imm=%s deployed=%.2f" % [refused, t2_fired, hw.order, hw.forced_target != null, hw_t, hw.tipped, hw.immobile(), hw.deployed])
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
	# 109: kendiliğinden ateş etkili menzil + kendi optiğiyle sınırlı; saldırı emri tam menzil
	var rw: float = tk._range()
	var far: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b", tk.position + Vector3(rw * 0.8, 0, 0), 0.0)
	var near: Vehicle = m.spawn_vehicle(1, "rus_mbt_72b", tk.position + Vector3(0, 0, rw * 0.45), 0.0)
	# doğurma engelden kaçırıp yerini değiştirebilir: ölçüm için tam uzaklığa konur
	far.position = tk.position + Vector3(rw * 0.8, 0, 0)
	near.position = tk.position + Vector3(0, 0, rw * 0.45)
	var own := Combat.detect_range(tk.opt_k, far.spot_sig())
	var far_auto: bool = tk._auto_engage_ok(far, tk.dist2(far), rw)
	var near_auto: bool = tk._auto_engage_ok(near, tk.dist2(near), rw)
	tk.forced_target = far
	var far_forced: bool = tk._auto_engage_ok(far, tk.dist2(far), rw)
	tk.forced_target = null
	print("RANGE auto_engage range=%.0f own_detect=%.0f far(%.0f) auto=%s forced=%s near(%.0f) auto=%s" % [rw, own, tk.dist2(far), far_auto, far_forced, tk.dist2(near), near_auto])
	if far_auto or not far_forced or not near_auto:
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
# 128: araç / hurda araziye oturur; kraterin ortasında çukura iner, kenarında yana devrilir
func crater_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var t1: Vehicle = m.spawn_vehicle(0, "tank", c, 0.0)
	var t2: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(16, 0, 0), Grid.M_HEAVY), 0.0)
	var w: Vehicle = m.spawn_vehicle(1, "ifv", G.grid.nearest_free(c + Vector3(-16, 0, 0), Grid.M_HEAVY), 0.0)
	for v in [t1, t2, w]:
		v.cmd_hold()
		v.fire_mode = 2
	await m._wait(1.0)
	w.destroy(null)
	await m._wait(1.0)
	G.terrain.carve_crater(t1.position, 3.0, 1.0)                                # ortada sığ krater: çukura iner
	G.terrain.carve_crater(t2.position + t2.right() * 2.2, 3.4, 2.6)             # sağ kenarda derin krater: devrilir
	G.terrain.carve_crater(w.position, 3.0, 1.2)
	# dekor: gerçek top mermisi kraterinin ortasında sandık (oturur), kenarında varil (devrilir)
	var pc := c + Vector3(0, 0, 24)
	G.props.crate(pc, 0.3)
	G.props.barrel(pc + Vector3(2.4, 0, 0))
	var crate_mi: Node3D = G.props.loose[G.props.loose.size() - 2]["node"]
	var barrel_mi: Node3D = G.props.loose[G.props.loose.size() - 1]["node"]
	G.explode(pc, 6.67, 10.0, "shell", 1, null)
	await m._wait(3.0)
	var b_up := barrel_mi.transform.basis.y.normalized().dot(Vector3.UP)
	# krater boyu mühimmatla rastgele değişir (138): varilin altındaki eğim devrilme eşiğini aşıyorsa devrilmiş,
	# aşmıyorsa dik ve zemine oturmuş olmalı
	var bslope: float = G.props._slope(pc + Vector3(2.4, 0, 0), 0.4)[1]
	var tip_need := bslope > atan(0.3 / 0.45) * 0.8
	print("CRATER props crate y=%.2f up=%.2f | barrel y=%.2f up=%.2f moved=%.2f slope=%.2f tip_expected=%s" % [crate_mi.position.y, crate_mi.transform.basis.y.normalized().dot(Vector3.UP), barrel_mi.position.y, b_up, Vector2(barrel_mi.position.x - pc.x - 2.4, barrel_mi.position.z - pc.z).length(), bslope, tip_need])
	if crate_mi.position.y > -0.5 or barrel_mi.position.y > -0.2 or (tip_need and b_up > 0.4) or (not tip_need and b_up < 0.6):
		fails += 1
	print("CRATER center y=%.2f roll=%.2f tipped=%s | edge roll=%.2f tipped=%s imm=%s | wreck y=%.2f mode=%s" % [t1.hull.position.y, t1.hull.rotation.z, t1.tipped, t2.hull.rotation.z, t2.tipped, t2.immobile(), w.hull.position.y, w.kill_mode])
	if t1.hull.position.y > -0.2 or t1.tipped:
		fails += 1
	if not t2.tipped or absf(t2.hull.rotation.z) < 1.0 or not t2.immobile():
		fails += 1
	if w.kill_mode != "flip" and w.hull.position.y > -0.3:
		fails += 1
	_cam(c + Vector3(4, 0, 0), 22.0)
	await m._wait(0.3)
	await m._shot("crater")
	print("CRATERTEST RESULT fails=%d" % fails)

# 107: araç zekâsı — vurulduğu yöne cephe, tanksavar isabetinde sis, ağır yarada geri vitesle çekilme
# (mevzi tut emrinde çekilmez), tanksavar askerini öncelikli hedef
func veh_ai_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	for u in G.units.duplicate():
		if is_instance_valid(u) and u.team == 1 and not (u is Building):
			u.queue_free()
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 45.0)
	await m._wait(0.3)
	# 1) cephe + sis
	var tk: Vehicle = m.spawn_vehicle(0, "tank", c, 0.0)
	tk.fire_mode = 2
	var rpg: Soldier = m.spawn_soldier(1, "at", G.grid.nearest_free(c + Vector3(25, 0, 0), Grid.M_INF), null)
	rpg.cmd_hold()
	rpg.fire_mode = 2
	await m._wait(0.5)
	Vehicle.shot_from = rpg.position
	tk.take_damage(60.0, rpg, "rpg")
	await m._wait(6.0)
	var want := Soldier._yaw_of(rpg.position - tk.position)
	var dang := absf(angle_difference(tk.heading, want))
	print("VAI face_smoke log=%s angle_left=%.2f smoke_left=%d immobile=%s" % [tk.tac_log, dang, tk.smoke_n, tk.immobile()])
	# RPG paleti koparabilir (rastgele): paleti kopan tank yerinde dönemez
	if not tk.tac_log.has("smoke") or (not tk.immobile() and dang > 0.45):
		fails += 1
	# 2) ağır yaralı İFV geri vitesle çekilir
	var ifv: Vehicle = m.spawn_vehicle(0, "ifv", G.grid.nearest_free(c + Vector3(-20, 0, 20), Grid.M_HEAVY), 0.0)
	ifv.fire_mode = 2
	await m._wait(0.5)
	ifv.hp = ifv.max_hp * 0.45
	var thr: Vector3 = ifv.position + Vector3(0, 0, -30)
	var d0 := Vector2(ifv.position.x - thr.x, ifv.position.z - thr.z).length()
	Vehicle.shot_from = thr
	ifv.take_damage(20.0, null, "atgm")
	await m._wait(8.0)
	var d1 := Vector2(ifv.position.x - thr.x, ifv.position.z - thr.z).length()
	print("VAI withdraw log=%s dist %.1f -> %.1f reverse=%s immobile=%s" % [ifv.tac_log, d0, d1, ifv.reverse, ifv.immobile()])
	# isabet paleti koparabilir (rastgele): hareketsiz araç çekilemez ama sis atar
	if not ifv.tac_log.has("smoke") or (not ifv.immobile() and (not ifv.tac_log.has("withdraw") or d1 - d0 < 6.0)):
		fails += 1
	# 3) mevzi tut: çekilmez
	var tk2: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(20, 0, 25), Grid.M_HEAVY), 0.0)
	tk2.fire_mode = 2
	tk2.cmd_hold()
	await m._wait(0.5)
	tk2.hp = tk2.max_hp * 0.4
	var p2 := tk2.position
	Vehicle.shot_from = tk2.position + Vector3(0, 0, -30)
	tk2.take_damage(20.0, null, "atgm")
	await m._wait(5.0)
	print("VAI hold log=%s moved=%.1f" % [tk2.tac_log, tk2.position.distance_to(p2)])
	if tk2.tac_log.has("withdraw") or tk2.position.distance_to(p2) > 2.0:
		fails += 1
	# 4) tanksavar askeri öncelikli
	var tk3: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(-25, 0, -25), Grid.M_HEAVY), 0.0)
	var rf: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(tk3.position + Vector3(0, 0, -18), Grid.M_INF), null)
	var at2: Soldier = m.spawn_soldier(1, "at", G.grid.nearest_free(tk3.position + Vector3(8, 0, -30), Grid.M_INF), null)
	for s in [rf, at2]:
		s.cmd_hold()
		s.fire_mode = 2
	# önce ikisi de görülür olsun (tank ateş kesik), sonra hedef seçimi
	tk3.fire_mode = 2
	for k in 8:
		await m._wait(0.2)
		for s in [rf, at2]:
			s.spot_mem[0] = G.time + 3.0
	tk3.fire_mode = 0
	tk3._scan_next = 0.0
	var t4 := G.time
	while G.time - t4 < 6.0 and tk3.target == null:
		await m._wait(0.2)
		for s in [rf, at2]:
			s.spot_mem[0] = G.time + 3.0
	print("VAI priority target=%s (at=%s) at_rockets=%d d_rf=%.1f d_at=%.1f los_at=%s seen_at=%s" % [tk3.target, tk3.target == at2, at2.rockets, tk3.dist2(rf), tk3.dist2(at2), G.grid.los(tk3.turret_world_pos() + Vector3(0, 0.4, 0), at2.aim_point(), 3.0, 0.5), G.is_seen(at2, 0)])
	if tk3.target != at2:
		fails += 1
	_cam(c, 40.0)
	await m._wait(0.3)
	await m._shot("vehai")
	print("VEHAITEST RESULT fails=%d" % fails)

# 115: suya düşen el bombası / mermi görünür (su sütunu, köpük, halka), karada duman — görsel kareler
func water_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var wpt := Vector3.INF
	var rr := RandomNumberGenerator.new()
	rr.seed = 7
	for i in 6000:
		var p := Vector3(rr.randf_range(20, G.MAP - 20), 0, rr.randf_range(20, G.MAP - 20))
		if G.grid.is_water(p) and G.grid.is_water(p + Vector3(4, 0, 0)) and G.grid.is_water(p - Vector3(4, 0, 0)) and not G.grid.on_bridge(p):
			wpt = p
			break
	print("WATER point=%s" % wpt)
	if wpt == Vector3.INF:
		print("WATERTEST RESULT fails=1")
		return
	_cam(wpt, 16.0)
	await m._wait(1.0)
	G.explode(wpt + Vector3(-3, 0, 0), 4.2, 120.0, "grenade", 1, null)
	G.explode(wpt + Vector3(3, 0, 0), 4.5, 130.0, "shell", 1, null)
	for k in [0.08, 0.25, 0.6, 1.4, 3.0]:
		await m._wait(k if k == 0.08 else 0.0)
		await m._shot("water_%04d" % int(k * 1000))
		await m._wait(k)
	# kıyıdan nehre atılan el bombası batar (yüzeyde sekip yuvarlanmaz), fitil bitince su altında patlar
	var bank: Vector3 = G.grid.nearest_free(wpt, Grid.M_INF, 30)
	var fails := 0
	G.bal.grenade(bank + Vector3(0, 1.4, 0), wpt, 1, null)
	var sunk_seen := false
	var gone := false
	for k in 50:
		await m._wait(0.1)
		var live := G.bal.projs.filter(func(x): return x.kind == "grenade")
		if live.any(func(x): return x.sunk):
			sunk_seen = true
		if sunk_seen and live.is_empty():
			gone = true
			break
		if k == 34:
			_cam(wpt, 16.0)
			await m._shot("water_uw")
	print("WATER grenade_sunk=%s exploded=%s" % [sunk_seen, gone])
	if not sunk_seen or not gone:
		fails += 1
	# karada: patlama dumanı ve sis perdesi
	var land := G.grid.nearest_free(wpt + Vector3(0, 0, 30), Grid.M_INF)
	G.props.clear_area(land, 12.0)
	_cam(land, 22.0)
	await m._wait(0.5)
	G.explode(land + Vector3(-6, 0, 0), 4.5, 130.0, "shell", 1, null)
	for i in 3:
		G.fx.smoke_screen(land + Vector3(4 + i * 3.0, 0, 0), 25.0)
	await m._wait(2.5)
	await m._shot("smoke_2s")
	await m._wait(6.0)
	await m._shot("smoke_8s")
	print("WATERTEST RESULT fails=%d" % fails)

# 112: sürücü vurulunca araç son hızıyla gider ve önündeki duvara çarpar; kapaktaki komutanı keskin nişancı vurur
func driver_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	for u in G.units.duplicate():
		if is_instance_valid(u) and u.team == 1 and not (u is Building):
			u.queue_free()
	# açık şerit: 70 m boyunca araç geçebilir, ucuna beton duvar
	var a0 := Vector3.INF
	var rr := RandomNumberGenerator.new()
	rr.seed = 5
	for i in 3000:
		var p := Vector3(rr.randf_range(30, G.MAP - 30), 0, rr.randf_range(30, G.MAP - 30))
		var q := p + Vector3(0, 0, -60)
		if G.grid.free_at(p, Grid.M_LIGHT) and G.grid.free_at(q, Grid.M_LIGHT) and G.grid.walkable_line(p, q, Grid.M_LIGHT) and not G.grid.on_bridge(p):
			a0 = p
			break
	print("DRV strip=%s" % (a0 != Vector3.INF))
	if a0 == Vector3.INF:
		print("DRIVERTEST RESULT fails=1")
		return
	G.props.clear_area(a0 + Vector3(0, 0, -30), 35.0)
	var wall := m.place_line(1, "concrete", a0 + Vector3(-5, 0, -42), a0 + Vector3(5, 0, -42))
	wall.add_work(99999.0)
	await m._wait(0.5)
	G.grid.flush_nav()
	var tv: Vehicle = m.spawn_vehicle(0, "technical", a0, 0.0)
	tv.heading = 0.0      # ileri = -z (duvara doğru)
	tv.hull.rotation.y = 0.0
	tv.cmd_move(a0 + Vector3(0, 0, -36), true)
	var t0 := G.time
	while G.time - t0 < 8.0 and absf(tv.cur_speed) < 4.0:
		await m._wait(0.1)
	var v0 := absf(tv.cur_speed)
	var p0 := tv.position
	var hp0 := tv.hp
	tv._kill_driver(null)
	await m._wait(1.0)
	var rolled := tv.position.distance_to(p0)
	var t1 := G.time
	var kk := 0
	while G.time - t1 < 14.0 and absf(tv.cur_speed) > 0.05:
		await m._wait(0.1)
		kk += 1
		if kk % 5 == 0:
			print("DRV run t=%.1f spd=%.2f runaway=%.1f drv=%s z_to_wall=%.1f order=%s path=%d/%d abandon=%.1f" % [G.time - t1, tv.cur_speed, tv._runaway, tv.driver_ok, tv.position.z - (a0.z - 42.0), tv.order, tv.path_i, tv.path.size(), tv.abandon_t])
	var stop_z := tv.position.z - (a0.z - 42.0)
	_cam(tv.position, 18.0)
	await m._wait(0.3)
	await m._shot("driver_crash")
	print("DRV speed_at_hit=%.1f rolled_1s=%.1f stop_dist_to_wall=%.1f hp %d -> %d driver_ok=%s imm=%s crashes=%d runaway=%.1f" % [v0, rolled, stop_z, int(hp0), int(tv.hp), tv.driver_ok, tv.immobile(), tv.crash_n, tv._runaway])
	# 1 sn'de en az hızın yarısı kadar yol, duvarın önünde (gövde boyu kadar) durur, çarpma hasarı
	if rolled < v0 * 0.5 or absf(stop_z) > tv.ext.y + 3.0 or tv.hp >= hp0:
		fails += 1
	# komutan: kapakta açıkta, keskin nişancı vurur
	var c := G.grid.nearest_free(a0 + Vector3(40, 0, 0), Grid.M_HEAVY)
	var tk: Vehicle = m.spawn_vehicle(1, "tank", c, PI)
	tk.cmd_hold()
	tk.fire_mode = 2
	tk.last_hit = -100.0
	var sn: Soldier = m.spawn_soldier(0, "sniper", G.grid.nearest_free(c + Vector3(0, 0, 42), Grid.M_INF), null)
	sn.cmd_hold()
	var t2 := G.time
	var seen_out := false
	while G.time - t2 < 25.0 and not tk._cmdr_dead:
		await m._wait(0.25)
		if tk.cmdr != null and tk.cmdr.visible:
			seen_out = true
		tk.spot_mem[0] = G.time + 2.0
	print("DRV cmdr_out=%s cmdr_killed=%s t=%.1f crew=%d exposed_after=%s sniper_shots=%d range=%.0f d=%.0f seen=%s tgt=%s" % [seen_out, tk._cmdr_dead, G.time - t2, tk.crew_n, tk.exposed_crew(), sn.shots, float(sn.weapon()["range"]), sn.dist2(tk), G.is_seen(tk, 0), sn.target])
	if not seen_out or not tk._cmdr_dead:
		fails += 1
	print("DRIVERTEST RESULT fails=%d" % fails)

# 125: sandbox geliştirici araçları — arama, bulanık doğurma, silme, yıkma, ışınlama, ikmal, bilgi, tüm efektler
func sandbox_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var sb: Sandbox = m.sandbox_ui
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var res: Array = sb.find("abrams")
	var res2: Array = sb.find("t-90")
	print("SBX find abrams=%d t-90=%d first=%s" % [res.size(), res2.size(), res[0][0] if res.size() > 0 else "-"])
	if res.is_empty() or res2.is_empty():
		fails += 1
	# bulanık doğurma: imleç ekran ortasında; kamera c'ye
	_cam(c, 30.0)
	await m._wait(0.3)
	m.get_viewport().warp_mouse(Vector2(800, 450))
	var n0 := G.units.size()
	sb.run("spawn abrams 2")
	await m._wait(0.3)
	var n1 := G.units.size()
	print("SBX spawn_fuzzy added=%d" % (n1 - n0))
	if n1 - n0 < 2:
		fails += 1
	# süzgeç: "abrams" araması yalnız eşleşen düğmeleri bırakır
	sb.search.text = "abrams"
	sb._filter("abrams")
	var shown := 0
	for ch in sb.list.get_children():
		if ch is Button and ch.visible:
			shown += 1
	sb._filter("")
	print("SBX filter shown=%d" % shown)
	if shown < 2 or shown > 20:
		fails += 1
	# sil / yık / ışınla / bilgi / ikmal
	var v1: Vehicle = m.spawn_vehicle(0, "tank", G.grid.nearest_free(c + Vector3(12, 0, 0), Grid.M_HEAVY), 0.0)
	var s1: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-12, 0, 0), Grid.M_INF), null)
	var s2: Soldier = m.spawn_soldier(0, "at", G.grid.nearest_free(c + Vector3(-14, 0, 0), Grid.M_INF), null)
	await m._wait(0.3)
	sb.place("t:info", v1.position)
	G.player.clear_sel()
	G.player.select(s2)
	s2.ammo = 0
	s2.rockets = 0
	sb.run("ammo")
	var ammo_ok: bool = s2.ammo > 0 and s2.rockets > 0
	sb.place("t:tp", c + Vector3(0, 0, 18))
	await m._wait(0.2)
	var tp_ok: bool = s2.position.distance_to(c + Vector3(0, 0, 18)) < 4.0
	sb.place("t:del", s1.position)
	await m._wait(0.2)
	var del_ok := not is_instance_valid(s1)
	sb.place("t:wreck", v1.position)
	await m._wait(0.3)
	var wreck_ok := not v1.alive
	print("SBX ammo=%s tp=%s del=%s wreck=%s" % [ammo_ok, tp_ok, del_ok, wreck_ok])
	if not (ammo_ok and tp_ok and del_ok and wreck_ok):
		fails += 1
	# ev yıkma: en yakın harita evi
	var hid := -1
	var hd2 := 1e9
	for i in G.blocks.houses.size():
		var h: Dictionary = G.blocks.houses[i]
		var d: float = (h["center"] as Vector3).distance_to(c)
		if not h["collapsed"] and d < hd2:
			hd2 = d
			hid = i
	if hid >= 0:
		var hc: Vector3 = G.blocks.houses[hid]["center"]
		var b0: int = G.blocks.blocks_near(hc, 6.0).size()
		for k in 3:
			sb.place("t:wreck", hc + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)))
		await m._wait(1.0)
		var b1: int = G.blocks.blocks_near(hc, 6.0).size()
		print("SBX house_wreck blocks %d -> %d" % [b0, b1])
		if b1 >= b0:
			fails += 1
	# tüm efektler hatasız
	for f in Sandbox.FX:
		sb.place("fx:" + f, c + Vector3(randf_range(-20, 20), 0, randf_range(-30, -10)))
		await m._wait(0.15)
	await m._wait(1.0)
	_cam(c, 40.0)
	await m._shot("sbx_fx")
	sb.run("stats")
	sb.run("info")
	print("SBX log=%s" % str(sb._log))
	print("SANDBOXTEST RESULT fails=%d" % fails)

# 116: keskin nişancı timi siper arkasında sağa sola kaymaz — vardıktan sonra 10 sn'deki toplam yol
func sniper_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 30.0)
	var wall := m.place_line(0, "sandbags", c + Vector3(-4, 0, -2), c + Vector3(4, 0, -2))
	wall.add_work(99999.0)
	await m._wait(0.5)
	var sq := Squad.new(0, "Keskin Nişancı")
	G.squads.append(sq)
	var sn: Array = []
	for i in 2:
		var s: Soldier = m.spawn_soldier(0, "sniper", G.grid.nearest_free(c + Vector3(i * 1.5, 0, 14), Grid.M_INF), sq)
		sn.append(s)
	var e: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(0, 0, -55), Grid.M_INF), null)
	e.cmd_hold()
	e.hp = 99999.0
	for s in sn:
		s.cmd_move(c + Vector3(0, 0, 0.2))
	await m._wait(12.0)
	var last: Array = sn.map(func(x): return x.position)
	var start: Array = sn.map(func(x): return x.position)
	var walked := [0.0, 0.0]
	for k in 100:
		await m._wait(0.1)
		for i in 2:
			walked[i] += Vector2(sn[i].position.x - last[i].x, sn[i].position.z - last[i].z).length()
			last[i] = sn[i].position
	var gap: float = sn[0].position.distance_to(sn[1].position)
	# titreme = toplam yol − net yer değiştirme (bilinçli siper değişimi net yer değiştirir, titreme değiştirmez)
	var jit := [walked[0] - start[0].distance_to(sn[0].position), walked[1] - start[1].distance_to(sn[1].position)]
	print("SNIPER walked=%.2f/%.2f jitter=%.2f/%.2f gap=%.2f cover=%d/%d states=%s/%s shots=%d" % [walked[0], walked[1], jit[0], jit[1], gap, sn[0].cover_type, sn[1].cover_type, sn[0].state, sn[1].state, sn[0].shots + sn[1].shots])
	_cam(c, 10.0)
	await m._wait(0.4)
	await m._shot("sniper_cover")
	if jit[0] > 1.0 or jit[1] > 1.0 or gap < 1.5:
		fails += 1
	print("SNIPERTEST RESULT fails=%d" % fails)

# 99 / 114: top mermisi yiyen çekili topun mürettebatı ve araçtaki yolcular "hiçbir şey olmamış gibi" kalmaz
func crew_kill_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var gun: Vehicle = m.spawn_vehicle(1, "howitzer", c, 0.0)
	gun.cmd_hold()
	gun.fire_mode = 2
	var isv: Vehicle = m.spawn_vehicle(0, "usa_lv_isv", G.grid.nearest_free(c + Vector3(25, 0, 0), Grid.M_LIGHT), 0.0)
	isv.cmd_hold()
	for i in 8:
		var s: Soldier = m.spawn_soldier(0, "rifle", isv.position + Vector3(0, 0, 4), null)
		s.board(isv)
	await m._wait(2.0)
	var n_bodies := gun.crew.size()
	var before := G.units.size()
	gun.hp = gun.max_hp * 0.3
	G.explode(gun.position + Vector3(0, 0.5, 0), 4.5, 300.0, "shell", 0, null)
	isv.hp = isv.max_hp * 0.3
	G.explode(isv.position + Vector3(0, 0.5, 0), 4.5, 300.0, "shell", 1, null)
	await m._wait(4.0)
	var crew_dead := 0
	var crew_alive := 0
	var pax_dead := 0
	var pax_alive := 0
	for u in G.units:
		if u is Soldier and is_instance_valid(u):
			if u.team == 1 and u.role == "crew" and u.position.distance_to(c) < 30.0:      # sağ kalan hurdadan kaçar
				if u.alive:
					crew_alive += 1
				else:
					crew_dead += 1
	for u in G.units:
		if u is Soldier and is_instance_valid(u) and u.team == 0 and u.role == "rifle" and u.position.distance_to(isv.position) < 15.0:
			if u.alive:
				pax_alive += 1
			else:
				pax_dead += 1
	_cam(c, 14.0)
	await m._wait(0.4)
	await m._shot("crewkill_gun")
	print("CREWKILL gun_alive=%s bodies=%d -> left=%d crew dead=%d alive=%d | isv_alive=%s pax dead=%d alive=%d units %d->%d" % [gun.alive, n_bodies, gun.crew.size(), crew_dead, crew_alive, isv.alive, pax_dead, pax_alive, before, G.units.size()])
	# ağır isabette her biri %85 ölür (olasılıklı): tüm gövdeler askere dönüşmeli, en az biri ölmeli
	if gun.alive or gun.crew.size() > 0 or crew_dead + crew_alive < n_bodies or crew_dead < 1:
		fails += 1
	if isv.alive or pax_dead < 6:
		fails += 1
	# 103: hafif hasarla yok olan (knocked) araçtan sağ çıkanlar yerinde donmaz — hurdadan uzaklaşır
	var apc: Vehicle = m.spawn_vehicle(0, "apc", G.grid.nearest_free(c + Vector3(-25, 0, 10), Grid.M_HEAVY), 0.0)
	apc.cmd_hold()
	for i in 6:
		var s: Soldier = m.spawn_soldier(0, "rifle", apc.position + Vector3(0, 0, 4), null)
		s.board(apc)
	await m._wait(1.0)
	apc.force_mode = "knocked"
	apc.kill_k = "ap"
	apc.destroy(null)
	await m._wait(8.0)
	var surv := 0
	var moved := 0
	var frozen := 0
	for u in G.units:
		if u is Soldier and is_instance_valid(u) and u.team == 0 and u.alive and u.can_fight() and u.position.distance_to(apc.position) < 25.0 and u.role == "rifle" and not (u.state in ["aboard"]):
			surv += 1
			if u.position.distance_to(apc.position) > apc.radius + 4.0:
				moved += 1
			else:
				if u.state == "idle" and u.order == "" and u.path_i >= u.path.size():
					frozen += 1          # hurdanın dibinde kımıldamadan duran (yaralı tedavisi / panik kaçışı sayılmaz)
				print("CREWKILL stay state=%s order=%s d=%.1f dest_d=%.1f path=%d/%d stress=%d sup=%d esc=%s obb=%s h=%.2f kind=%d pos=%s apc=%s ext=%s first_wp=%s" % [u.state, u.order, u.position.distance_to(apc.position), u.dest.distance_to(apc.position), u.path_i, u.path.size(), int(u.stress), int(u.suppression), u._escaping, apc.obb_push(u.position, 0.0), G.grid.height_at(u.position), G.grid.kind_at(u.position), u.position, apc.position, apc.ext, u.path[u.path_i] if u.path_i < u.path.size() else Vector3.ZERO])
	print("CREWKILL knocked_apc survivors=%d fled=%d frozen=%d" % [surv, moved, frozen])
	if surv > 0 and (frozen > 0 or moved * 2 < surv):
		fails += 1
	print("CREWKILLTEST RESULT fails=%d" % fails)

# 89: siper derinliğine göre duruş — derin siperde ateş ederken ayakta, gözü korkuluğun hemen üstünde; ağır
# baskıda kenarın altına çömelir; kraterde / sığ çukurda alçak duruş
func trenchpose_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var tr := m.place_line(0, "trench", c + Vector3(-6.0, 0, 0.0), c + Vector3(6.0, 0, 0.0))
	tr.add_work(99999.0)
	await m._wait(1.0)
	var cp := c + Vector3(0, 0, 9)
	G.explode(cp, 4.5, 5.0, "shell", 1, null)
	var rp := c + Vector3(8, 0, 9)
	G.explode(rp, 3.0, 5.0, "rpg", 1, null)
	await m._wait(0.5)
	var en: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(0, 0, -26), Grid.M_INF), null)
	en.cmd_hold()
	en.fire_mode = 2
	en.hp = 999999.0
	en.stance_lock = Soldier.STAND
	var ts: Array = []
	for i in 3:
		var s: Soldier = m.spawn_soldier(0, "rifle", c + Vector3(-3.0 + i * 3.0, 0, 0.0), null)
		s.cmd_hold()
		ts.append(s)
	var cs: Soldier = m.spawn_soldier(0, "rifle", cp, null)
	cs.cmd_hold()
	var rs: Soldier = m.spawn_soldier(0, "rifle", rp, null)
	rs.cmd_hold()
	await m._wait(5.0)
	var names := ["STAND", "CROUCH", "PRONE"]
	for s in ts:
		print("TPOSE trench depth=%.2f stance=%s eye_above_lip=%.2f target=%s popped=%s" % [s.trench_depth(), names[s.stance], s.eye_point().y, s.target != null, s.popped])
		if s.target != null and (s.stance != Soldier.STAND or s.eye_point().y < 0.05 or s.eye_point().y > 0.7):
			fails += 1
	print("TPOSE crater depth=%.2f stance=%s | rpg pit depth=%.2f stance=%s" % [cs.trench_depth(), names[cs.stance], rs.trench_depth(), names[rs.stance]])
	_cam(c, 12.0)
	await m._wait(0.2)
	await m._shot("trench_fire")
	# ağır baskı: kenarın altına çömelir
	for s in ts:
		s.add_suppression(95.0, en.position)
	await m._wait(0.6)
	for s in ts:
		print("TPOSE suppressed stance=%s eye_above_lip=%.2f" % [names[s.stance], s.eye_point().y])
		if s.stance == Soldier.STAND or s.eye_point().y > -0.05:
			fails += 1
	await m._shot("trench_duck")
	print("TRENCHPOSE RESULT fails=%d" % fails)

# 84: kalabalık tankın yanına yığılınca askerler iç içe girmez, tankın içine girmez, takılıp kalmaz
func crowd_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var tk: Vehicle = m.spawn_vehicle(0, "tank", c, 0.3)
	tk.cmd_hold()
	tk.fire_mode = 2
	var ss: Array = []
	for i in 24:
		var p := G.grid.nearest_free(c + Vector3(-18 + (i % 6) * 1.5, 0, 14 + (i / 6) * 1.5), Grid.M_INF)
		ss.append(m.spawn_soldier(0, "rifle", p, null))
	await m._wait(1.0)
	# hepsi tankın iki yanındaki iki noktaya (kalabalık, tankın dibinde)
	for i in ss.size():
		var side := 1.0 if i % 2 == 0 else -1.0
		ss[i].cmd_move(tk.position + tk.right() * side * (tk.ext.x + 1.2))
	# iç içe girme: omuz genişliği ~0,45 m — merkezler 0,4 m'den yakınsa gövdeler görünür biçimde iç içe
	var worst_pairs := 0
	var min_d := 99.0
	for k in 24:
		await m._wait(0.5)
		if k >= 16:
			var pairs := 0
			for a in ss.size():
				for b in range(a + 1, ss.size()):
					var dd := Vector2(ss[a].position.x - ss[b].position.x, ss[a].position.z - ss[b].position.z).length()
					min_d = minf(min_d, dd)
					if dd < 0.4:
						pairs += 1
			worst_pairs = maxi(worst_pairs, pairs)
	var inside := 0
	var moving := 0
	for s in ss:
		var q: Vector3 = tk.obb_closest(s.position)
		if Vector2(q.x - s.position.x, q.z - s.position.z).length() < 0.05:
			inside += 1
		if s.state == "move":
			moving += 1
			var dq: Vector3 = s.path[s.path.size() - 1] if s.path.size() > 0 else s.position
			var wp: Vector3 = s.path[s.path_i] if s.path_i < s.path.size() else s.position
			var wq: Vector3 = tk.obb_closest(wp)
			print("CROWD stuck L=%.2f sep=%.2f path=%d/%d d_tank=%.2f wp_dist=%.2f wp_in_tank=%.2f slide=%s detour=%s" % [Vector2(dq.x - s.position.x, dq.z - s.position.z).length(), s._sep_c.length(), s.path_i, s.path.size(), Vector2(q.x - s.position.x, q.z - s.position.z).length(), Vector2(wp.x - s.position.x, wp.z - s.position.z).length(), Vector2(wq.x - wp.x, wq.z - wp.z).length(), s._slide_sgn, s.get("_detour_t")])
	_cam(c, 16.0)
	await m._wait(0.2)
	await m._shot("crowd_tank")
	print("CROWD pairs_lt_0.4m=%d min_dist=%.2f inside_tank=%d still_moving=%d" % [worst_pairs, min_d, inside, moving])
	if worst_pairs > 1 or inside > 0 or moving > 2:
		fails += 1
	print("CROWDTEST RESULT fails=%d" % fails)

# 83: geri çekilen asker arkasına bakmadan ateş etmez — normal harekette hedef arkadaysa geri geri yürüyerek
# (koşmadan) ve gövdesi hedefe dönükken ateş eder; geri çekilme emrinde dönüp koşar, ateş etmez
func backfire_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_INF)
	G.props.clear_area(c, 40.0)
	var en: Vehicle = m.spawn_vehicle(1, "truck", c + Vector3(0, 0, -34), 0.0)
	en.cmd_hold()
	en.hp = 999999.0
	var s1: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-3, 0, 0), Grid.M_INF), null)
	var s2: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(3, 0, 0), Grid.M_INF), null)
	await m._wait(3.0)
	s1.cmd_move(G.grid.nearest_free(s1.position + Vector3(0, 0, 26), Grid.M_INF))
	s2.cmd_move(G.grid.nearest_free(s2.position + Vector3(0, 0, 26), Grid.M_INF))
	s2.order = "retreat"
	var r := {s1: [0, 0, 0.0], s2: [0, 0, 0.0]}   # atış, arkaya bakmadan atış, hedef arkadayken en yüksek hız
	var am := {s1: s1.ammo, s2: s2.ammo}
	var p0 := {s1: s1.position, s2: s2.position}
	for k in 160:
		await m._wait(0.05)
		for s in [s1, s2]:
			var shot: bool = s.ammo < am[s]
			am[s] = s.ammo
			var off := absf(angle_difference(s.rotation.y, Soldier._yaw_of(en.position - s.position)))
			if shot:
				r[s][0] += 1
				if off > 0.5:
					r[s][1] += 1
			if k % 10 == 9:
				if s.state == "move" and s._back_to_target():
					var sp := Vector2(s.position.x - p0[s].x, s.position.z - p0[s].z).length() / 0.5
					r[s][2] = maxf(r[s][2], sp)
				p0[s] = s.position
	print("BACKFIRE move shots=%d blind=%d back_speed=%.1f | retreat shots=%d blind=%d" % [r[s1][0], r[s1][1], r[s1][2], r[s2][0], r[s2][1]])
	if r[s1][1] > 0 or r[s2][0] > 0 or r[s1][2] > 1.9:
		fails += 1
	print("BACKFIRETEST RESULT fails=%d" % fails)

# 138: krater mühimmata göre değişir — gerçek patlama yarıçaplarıyla sırayla patlatılır, çukurun derinliği ve
# çapı araziden ölçülür
func cratertypes_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 60.0)
	var kinds := [["grenade", 4.2], ["auto", 1.7], ["rpg", 3.0], ["mortar", 4.0], ["shell", 4.5], ["mine", 3.4], ["big", 8.0]]
	var res := {}
	for i in kinds.size():
		var p := c + Vector3(-36.0 + i * 12.0, 0, 0)
		p.y = 0.0
		G.explode(p, float(kinds[i][1]), 10.0, kinds[i][0], 1, null)
		await m._wait(0.2)
		var dmin := 0.0
		var rad := 0.0
		for k in 48:
			var a := k * TAU / 48.0
			for s in 40:
				var q := p + Vector3(cos(a), 0, sin(a)) * (s * 0.2)
				var h := G.terrain.ground_hs(q)
				dmin = minf(dmin, h)
				if h < -0.05:
					rad = maxf(rad, s * 0.2)
		res[kinds[i][0]] = [dmin, rad]
		print("CRATERT %s depth=%.2f radius=%.1f" % [kinds[i][0], -dmin, rad])
	var d := func(k): return -float(res[k][0])
	var r := func(k): return float(res[k][1])
	if d.call("grenade") > 0.05 or d.call("auto") > 0.05:
		fails += 1
	if not (d.call("rpg") > 0.1 and d.call("mortar") > d.call("rpg") and d.call("shell") > d.call("mortar")):
		fails += 1
	if not (r.call("big") > r.call("shell") and d.call("big") > d.call("shell") and d.call("mine") > d.call("mortar")):
		fails += 1
	await m._wait(16.0)
	_cam(c, 34.0)
	await m._wait(0.3)
	await m._shot("cratertypes_all")
	_cam(c + Vector3(12, 0, 0), 14.0)
	await m._wait(0.3)
	await m._shot("cratertypes_close")
	print("CRATERTYPES RESULT fails=%d" % fails)

# 137: çekili top yer değiştirirken süzülmez — yerdeki cephane toplanır (yığın kalkar), tekerler döner,
# mürettebat yürür; durup kurulunca cephane yeniden yere konur
func tow_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 50.0)
	var types := ["howitzer", "fieldgun", "atgun", "mtngun", "hmortar", "aagun"]
	for t in 2:
		for i in types.size():
			var v: Vehicle = m.spawn_vehicle(t, types[i], c + Vector3(-25 + i * 10.0, 0, -10 + t * 20.0), 0.0)
			v.fire_mode = 2
			await m._wait(0.1)
			# kurulu başla: cephane yığını yerde
			v.deployed = 1.0
			v._crew_anim(0.1)
			var pile_before: bool = v._ammo_pile != null and v._ammo_pile.visible
			var w0: Array = []
			for w in v.wheels:
				w0.append((w[0] as Node3D).rotation.x)
			v.cmd_move(v.position + Vector3(0, 0, -18))
			var moving_pile := false
			var crew_walk := false
			var spun := 0
			var pile_glide := 0.0
			var pp0: Vector3 = v._ammo_pile.global_position if v._ammo_pile else Vector3.ZERO
			for k in 90:
				await m._wait(0.25)
				if k > 20 and v.path_i >= v.path.size() and absf(v.cur_speed) < 0.05:
					break
				if absf(v.cur_speed) > 0.3:
					if v._ammo_pile != null and v._ammo_pile.visible:
						moving_pile = true
						pile_glide = maxf(pile_glide, v._ammo_pile.global_position.distance_to(pp0))
					for cb in v.crew:
						if (cb as SoldierBody).visible and (cb as SoldierBody).get_meta("walk", false):
							crew_walk = true
			for wi in v.wheels.size():
				if absf((v.wheels[wi][0] as Node3D).rotation.x - float(w0[wi])) > 0.5:
					spun += 1
			var tw2 := 0.0
			while v.deployed < 1.0 and tw2 < 20.0:
				await m._wait(0.5)
				tw2 += 0.5
			await m._wait(0.3)
			var pile_after: bool = v._ammo_pile != null and v._ammo_pile.visible
			print("TOW %s t=%d wheels=%d spun=%d pile_before=%s pile_while_moving=%s glide=%.1f pile_after_deploy=%s crew_walk=%s deployed=%.2f" % [types[i], t, v.wheels.size(), spun, pile_before, moving_pile, pile_glide, pile_after, crew_walk, v.deployed])
			if moving_pile or spun == 0 or v.wheels.size() == 0 or not crew_walk or not pile_after:
				fails += 1
	_cam(c, 30.0)
	await m._wait(0.3)
	await m._shot("tow_all")
	print("TOWTEST RESULT fails=%d" % fails)

# 134: yol açma dozeri yoldaki hurdayı kendiliğinden bıçakla iterek, kurtarma aracı emirle halatla çekerek yol dışına
# kaldırır; hurdanın ızgara izi yeni yerine taşınır
func dozer_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	# yol üstünde, köprüden uzak, iki hurdalık yer
	var roads: Array = []
	var step := 6.0
	var z := 20.0
	while z < G.MAP - 20.0 and roads.size() < 2:
		var x := 20.0
		while x < G.MAP - 20.0 and roads.size() < 2:
			var p := Vector3(x, 0, z)
			if G.terrain.on_road(p) and G.grid.free_at(p, Grid.M_HEAVY) and G.grid.bridge_at(p).is_empty() and Vector2(p.x - G.MAP * 0.5, p.z - G.MAP * 0.5).length() > 40.0:
				if roads.is_empty() or roads[0].distance_to(p) > 70.0:
					roads.append(p)
			x += step
		z += step
	if roads.size() < 2:
		print("DOZER no road spots")
		print("DOZERTEST RESULT fails=1")
		return
	var res: Array = []
	for ci in 2:
		var rp: Vector3 = roads[ci]
		G.props.clear_area(rp, 30.0)
		var w: Vehicle = m.spawn_vehicle(1, "truck" if ci == 0 else "apc", rp, 0.7)
		await m._wait(0.3)
		w.destroy(null)
		await m._wait(2.0)
		var p0 := w.position
		var blocked0 := G.grid.kind_at(p0) == Grid.K_WRECK
		var dz: Vehicle = m.spawn_vehicle(0, "usa_eng_d7" if ci == 0 else "usa_eng_m88", G.grid.nearest_free(rp + Vector3(14, 0, 10), Grid.M_HEAVY), 0.0)
		dz.fire_mode = 2
		if ci == 1:
			dz.cmd_clear(w)
		var mode := ""
		var t := 0.0
		while t < 70.0:
			await m._wait(0.5)
			t += 0.5
			if dz.clear_mode != "":
				mode = dz.clear_mode
			if ci == 0 and t == 12.0:
				_cam(dz.position, 18.0)
				await m._wait(0.1)
				await m._shot("dozer_push")
			if ci == 1 and dz.clear_stage == "haul" and dz._cable != null and not res.has("shot1"):
				res.append("shot1")
				await m._wait(1.5)
				_cam(dz.position, 16.0)
				await m._wait(0.1)
				await m._shot("dozer_tow")
			if w.get_meta("cleared", false):
				break
		var moved := Vector2(w.position.x - p0.x, w.position.z - p0.z).length()
		var on_road := G.terrain.on_road(w.position)
		var old_free := G.grid.kind_at(p0) != Grid.K_WRECK
		var new_mark := G.grid.kind_at(w.position) == Grid.K_WRECK
		print("DOZER %s %s mode=%s t=%.1f moved=%.1f on_road=%s old_cell_wreck=%s->%s new_marked=%s" % [dz.vid, w.vtype, mode, t, moved, on_road, blocked0, not old_free, new_mark])
		if not w.get_meta("cleared", false) or moved < 6.0 or on_road or not old_free or not new_mark:
			fails += 1
		if mode != ("push" if ci == 0 else "tow"):
			fails += 1
		_cam(w.position, 20.0)
		await m._wait(0.2)
		await m._shot("dozer_after_%d" % ci)
	print("DOZERTEST RESULT fails=%d" % fails)

# 131: sis perdesinin içinden geçen tank ve piyade dumanı yarar, arkasında iz bırakır (görsel) — hareketli birlik
# duman gölgelendiricisine aktarılır
func smokepass_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	for off in [Vector3(-4, 0, 0), Vector3(4, 0, 0), Vector3(0, 0, 3)]:
		G.fx.smoke_screen(c + off, 40.0)
		G.add_smoke(c + off, 5.0, 40.0)
	var tk: Vehicle = m.spawn_vehicle(0, "tank", c + Vector3(0, 0, 22), 0.0)
	tk.fire_mode = 2
	var sq: Array = []
	for k in 4:
		var s: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-6 + k * 1.6, 0, -20), Grid.M_INF), null)
		sq.append(s)
	_cam(c, 30.0)
	await m._wait(5.0)
	await m._shot("smokepass_0_before")
	tk.cmd_move(c + Vector3(0, 0, -24))
	for s in sq:
		s.cmd_move(s.position + Vector3(0, 0, 40))
	await m._wait(3.2)
	var n := 0
	for mat in G.fx._mover_mats:
		n = maxi(n, int((mat as ShaderMaterial).get_shader_parameter("mover_n")))
	await m._shot("smokepass_1_entering")
	await m._wait(1.8)
	await m._shot("smokepass_2_inside")
	await m._wait(2.5)
	await m._shot("smokepass_3_after")
	print("SMOKEPASS movers=%d tank_speed=%.1f fps=%d" % [n, tk.cur_speed, Engine.get_frames_per_second()])
	if n < 2:
		fails += 1
	print("SMOKEPASSTEST RESULT fails=%d" % fails)

# 132: taret hedefe döndüğünde görünen namlu da hedefe bakmalı (Rus araçlarında mermi namlunun bakmadığı
# yöne gidiyordu) — katalogdaki taretli her araç, yan tarafa konan hedefe nişan alır; namlu ucu yönü ölçülür
func aim_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.72, 0, G.MAP * 0.75), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	Catalog.load_all()
	var ids: Array = []
	for o in Catalog.order:
		if Catalog.base(o[2]) in ["tank", "ifv", "apc", "technical", "aa", "arty"]:
			ids.append(o[2])
	var bad := 0
	for i in ids.size():
		var v: Vehicle = m.spawn_vehicle(0, ids[i], c, 0.0)
		if v.turret == null or v.barrel == null:
			G.remove_unit(v)
			v.queue_free()
			continue
		v.cmd_hold()
		var tgt: Vehicle = m.spawn_vehicle(1, "truck", c + v.right() * 30.0 + v.forward() * 6.0, 0.0)
		tgt.cmd_hold()
		tgt.fire_mode = 2
		tgt.hp = 99999.0
		v.target = tgt
		v.fire_mode = 2
		await m._wait(1.5)
		v.target = tgt
		for k in 30:
			v._aim_fire(0.1)
		var want: Vector3 = tgt.position - v.position
		want.y = 0.0
		var mz: Vector3 = v.muzzle_world() - v.turret_world_pos()
		mz.y = 0.0
		var bn: Vector3 = v.barrel.global_transform.basis.z
		bn.y = 0.0
		var err := rad_to_deg(want.angle_to(mz)) if mz.length() > 0.2 else -1.0
		var line := "AIM %s %s err=%.0f° muzzle_len=%.2f turret_yaw=%.2f want_local=%.2f" % [ids[i], v.vtype, err, mz.length(), v.turret_yaw, wrapf(Soldier._yaw_of(want) - v.heading, -PI, PI)]
		if err > 15.0 or err < 0.0:
			line += " BAD"
			bad += 1
			if ids[i].begins_with("rus") or bad <= 6:
				_cam(v.position, 10.0)
				await m._wait(0.2)
				await m._shot("aim_%s" % ids[i])
		print(line)
		for u in [v, tgt]:
			G.remove_unit(u)
			u.queue_free()
		await m._wait(0.2)
	print("AIM bad=%d of %d" % [bad, ids.size()])
	# yan / arkadan saldıran düşman fırkası: eş eksenli makineli taretin baktığı yöne ateş eder
	var coax_bad := 0
	var coax_shots := 0
	for vid2 in ["rus_mbt_72b", "rus_mbt_90m", "usa_mbt_a2"]:
		var tk: Vehicle = m.spawn_vehicle(0, vid2, c, 0.0)
		tk.cmd_hold()
		await m._wait(0.5)
		if tk.cmdr:
			tk.cmdr.visible = false
		var en: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c - tk.forward() * 22.0 + tk.right() * 6.0, Grid.M_INF), null)
		en.hp = 99999.0
		var s0 := tk.shots
		for k in 120:
			tk.target = null
			tk.coax_target = en
			tk.coax_cd -= 0.05
			var before := tk.shots
			tk._aim_fire(0.05)
			if tk.shots > before:
				coax_shots += 1
				var bear := Soldier._yaw_of(en.position - tk.position)
				if absf(angle_difference(tk.heading + tk.turret_yaw, bear)) > 0.15:
					coax_bad += 1
		print("AIM coax %s shots=%d turret_err=%.2f" % [vid2, tk.shots - s0, absf(angle_difference(tk.heading + tk.turret_yaw, Soldier._yaw_of(en.position - tk.position)))])
		for u in [tk, en]:
			G.remove_unit(u)
			u.queue_free()
		await m._wait(0.2)
	print("AIM coax shots=%d off_turret=%d" % [coax_shots, coax_bad])
	# yan fırlatıcılı araçların (Tor, Tunguska, ITV, Ontos) namlu ucu taret ekseninin yanında: ölçüm yanılgısı
	fails = 0 if coax_bad == 0 and coax_shots > 0 else 1
	print("AIMTEST RESULT fails=%d" % fails)

# köprü üstündeki aracın gövde köşelerinin döşeme kenarından taşma miktarı (köprü dışındaysa 0)
func _bridge_overhang(v: Vehicle, br: Dictionary) -> float:
	if v == null or not is_instance_valid(v) or G.grid.bridge_at(v.position).is_empty():
		return 0.0
	var d: Vector3 = br["d"]
	var rel: Vector3 = v.position - br["c"]
	rel.y = 0.0
	if absf(rel.dot(d)) > float(br["L"]) * 0.5 - 1.0:
		return 0.0
	var worst := 0.0
	for sf in [-1.0, 1.0]:
		for sr in [-1.0, 1.0]:
			var q: Vector3 = rel + v.forward() * v.ext.y * 0.85 * sf + v.right() * v.ext.x * sr
			if absf(q.dot(d)) > float(br["L"]) * 0.5:
				continue
			worst = maxf(worst, absf(q.cross(d).y) - float(br["w"]) * 0.5)
	return worst

# 130: önü kesilen araç sağa sola yalpalamaz — bir taraf seçip ondan dolaşır (gerekirse geri manevra);
# köprüde yol kapalıysa suya girmeden durup bekler
func jam_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	# açık arazi: nehirden uzak, 40 m boyunca kuru bir şerit
	var land := Vector3.INF
	for cand in [Vector3(0.72, 0, 0.75), Vector3(0.25, 0, 0.3), Vector3(0.75, 0, 0.3), Vector3(0.3, 0, 0.8)]:
		var p := G.grid.nearest_free(Vector3(G.MAP * cand.x, 0, G.MAP * cand.z), Grid.M_HEAVY)
		var dry := true
		for k in 21:
			for sx in [-8.0, 0.0, 8.0]:
				var q: Vector3 = p + Vector3(sx, 0, -20.0 + k * 2.0)
				if G.grid.is_water(q) or not G.grid.bridge_at(q).is_empty():
					dry = false
		if dry:
			land = p
			break
	var br: Dictionary = G.grid.bridges[0] if not G.grid.bridges.is_empty() else {}
	var cases: Array = []
	if land != Vector3.INF:
		G.props.clear_area(land, 30.0)
		cases.append(["land", "truck", land])
		cases.append(["land", "technical", land])
	if not br.is_empty():
		cases.append(["bridge", "truck", br["c"]])
		cases.append(["bridge", "tank", br["c"]])
	var flips_all := 0
	for cs in cases:
		var kind: String = cs[0]
		var vt: String = cs[1]
		var base: Vector3 = cs[2]
		var b1: Vehicle
		var b2: Vehicle
		var tr: Vehicle
		var goal: Vector3
		if kind == "land":
			# önde iki park etmiş (tut emrinde) tank yan yana, arkalarında hedef
			b1 = m.spawn_vehicle(0, "tank", base, 0.0)
			b2 = m.spawn_vehicle(0, "tank", base + Vector3(4.2, 0, 0.5), 0.0)
			tr = m.spawn_vehicle(0, vt, base + Vector3(0, 0, 16), 0.0)
			goal = base + Vector3(0, 0, -16)
		else:
			# köprüde ard arda iki tank (tut emrinde): yol kapalı
			var d: Vector3 = br["d"]
			var yaw := Soldier._yaw_of(d)
			b1 = m.spawn_vehicle(0, "tank", base, yaw)
			b2 = m.spawn_vehicle(0, "tank", base + d * 9.0, yaw)
			if vt == "tank":
				# 133: köprüye giren tank, karşıdan gelen tankla köprüde burun buruna sıkışır
				tr = m.spawn_vehicle(0, vt, G.grid.nearest_free(base - d * (float(br["L"]) * 0.5 + 6.0), Grid.M_HEAVY), yaw)
			else:
				tr = m.spawn_vehicle(0, vt, G.grid.nearest_free(base - d * (float(br["L"]) * 0.5 + 12.0), Grid.M_LIGHT), yaw)
			goal = G.grid.nearest_free(base + d * (float(br["L"]) * 0.5 + 14.0), Grid.M_LIGHT)
		for b in [b1, b2]:
			b.cmd_hold()
			b.fire_mode = 2
		if kind == "bridge" and vt == "tank":
			# karşıdan gelen tank: köprünün ortasında burun buruna
			var d2: Vector3 = br["d"]
			G.remove_unit(b2)
			b2.queue_free()
			b2 = m.spawn_vehicle(0, "tank", G.grid.nearest_free(base + d2 * (float(br["L"]) * 0.5 + 10.0), Grid.M_HEAVY), Soldier._yaw_of(-d2))
			b1.cmd_stop()
			G.remove_unit(b1)
			b1.queue_free()
			b1 = null
			await m._wait(0.3)
			b2.cmd_move(G.grid.nearest_free(base - d2 * (float(br["L"]) * 0.5 + 14.0), Grid.M_HEAVY))
		# ateş kes: köprü yakınındaki düşman karargâhını vurup oyunu bitirmesinler (yeni harita yükleniyordu)
		for v in [b1, b2, tr]:
			if v != null:
				v.fire_mode = 2
		await m._wait(0.5)
		tr.cmd_move(goal)
		var flips := 0
		var last_sgn := 0.0
		var h0 := tr.heading
		var reached := false
		var wet := false
		var over := 0.0
		var inside := -99.0
		var t := 0.0
		while t < (60.0 if kind == "bridge" and vt == "tank" else 40.0):
			await m._wait(0.25)
			t += 0.25
			var dh := angle_difference(h0, tr.heading)
			h0 = tr.heading
			if absf(dh) > 0.02:
				var sg := signf(dh)
				if last_sgn != 0.0 and sg != last_sgn:
					flips += 1
				last_sgn = sg
			if G.grid.is_water(tr.position) and G.grid.bridge_at(tr.position).is_empty():
				wet = true
			# 133: köprüdeki araçların gövde köşeleri döşemenin dışına (korkuluğun içinden) taşmamalı
			if kind == "bridge":
				for v in [b1, b2, tr]:
					over = maxf(over, _bridge_overhang(v, br))
				if vt == "tank" and is_instance_valid(b2):
					# karşılaşan iki tank birbirinin içinden geçmemeli
					var q: Vector3 = tr.obb_closest(b2.position)
					inside = maxf(inside, b2.ext.x - Vector2(q.x - b2.position.x, q.z - b2.position.z).length())
			if Vector2(tr.position.x - goal.x, tr.position.z - goal.z).length() < 6.0:
				reached = true
				if not (kind == "bridge" and vt == "tank"):
					break
			if kind == "bridge" and vt == "tank" and is_instance_valid(b2) and reached and (b2.position - br["c"]).dot(br["d"]) < -float(br["L"]) * 0.5 - 2.0:
				break
		_cam(tr.position, 22.0)
		await m._wait(0.2)
		await m._shot("jam_%s_%s" % [kind, vt])
		print("JAM %s %s reached=%s t=%.1f heading_flips=%d wet=%s waited=%s overhang=%.2f pos=%s" % [kind, vt, reached, t, flips, wet, tr._jam_said, over, tr.position])
		if kind == "bridge" and vt == "tank":
			var d3: Vector3 = br["d"]
			var tra: float = (tr.position - br["c"]).dot(d3)
			var b2a: float = (b2.position - br["c"]).dot(d3)
			var half_l := float(br["L"]) * 0.5
			print("JAM meet tr_along=%.1f b2_along=%.1f L=%.1f max_interpenetration=%.2f yielded=%s/%s" % [tra, b2a, float(br["L"]), inside, tr._yield_dest != Vector3.INF, b2._yield_dest != Vector3.INF])
			# ikisi de karşıya geçmeli, gövdeler iç içe girmemeli (temas payı 0,6 m)
			if tra < half_l or b2a > -half_l or inside > 0.6:
				fails += 1
		flips_all += flips
		if kind == "land" and (not reached or flips > 4):
			fails += 1
		# karşılaşmada geri çekilen tankı izleyip köprü sonrası virajlı yola dönerken birkaç gerçek yön değişimi olur
		if kind == "bridge" and (wet or flips > (8 if vt == "tank" else 4) or over > 0.25):
			fails += 1
		for v in [b1, b2, tr]:
			if v != null and is_instance_valid(v):
				G.remove_unit(v)
				v.queue_free()
		await m._wait(0.5)
	if cases.is_empty():
		fails += 1
	print("JAM cases=%d total_flips=%d" % [cases.size(), flips_all])
	print("JAMTEST RESULT fails=%d" % fails)

# 129: güvertedeki askerler ve komutan gövde / taret yüzeyine oturur (havada durmaz) — katalogdaki her tank ve pikap
func deck_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 60.0)
	Catalog.load_all()
	var ids: Array = []
	for o in Catalog.order:
		if Catalog.base(o[2]) in ["tank", "technical"]:
			ids.append(o[2])
	var vs: Array = []
	for i in ids.size():
		var p := G.grid.nearest_free(c + Vector3(-40.0 + (i % 8) * 11.0, 0, -30.0 + (i / 8) * 13.0), Grid.M_HEAVY)
		var v: Vehicle = m.spawn_vehicle(0, ids[i], p, PI * 0.75)
		v.cmd_hold()
		v.fire_mode = 2
		vs.append(v)
	await m._wait(1.0)
	for v in vs:
		if not v.riders_visible():
			continue
		for k in 4:
			var s: Soldier = m.spawn_soldier(0, "rifle", v.position + Vector3(0, 0, 6), null)
			s.board(v)
	await m._wait(1.5)
	for i in vs.size():
		var v: Vehicle = vs[i]
		if not v.riders_visible():
			continue
		var a := AABB()
		var first := true
		for ch in v.hull.get_children():
			if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
				var bb: AABB = (ch as MeshInstance3D).transform * (ch as MeshInstance3D).mesh.get_aabb()
				a = bb if first else a.merge(bb)
				first = false
		var ys := []
		var bad := false
		for st in v._deck_seats():
			ys.append(snappedf(st.y, 0.01))
			if st.y < 0.3 or st.y > a.end.y + 0.02:
				bad = true
		var cm := ""
		if v.cmdr != null:
			cm = " cmdr_y=%.2f" % v.cmdr.position.y
		print("DECK %s %s seats_y=%s hull_top=%.2f%s%s" % [ids[i], v.vtype, ys, a.end.y, cm, " BAD" if bad else ""])
		if bad:
			fails += 1
	# 92: açık nişancı (kapak / kasa) — ayakları gövde yüzeyinin altında (kapağın içinde) olmalı, tavanda ayakta değil
	var gun_bad := 0
	for o in Catalog.order:
		if Catalog.base(o[2]) not in ["apc", "ifv", "technical", "aa", "tank"]:
			continue
		var gv: Vehicle = m.spawn_vehicle(0, o[2], c + Vector3(0, 0, 40), 0.0)
		if gv.gunner != null:
			var hf := PackedVector3Array()
			for ch in gv.hull.get_children():
				if ch is MeshInstance3D and (ch as MeshInstance3D).mesh != null:
					var f := (ch as MeshInstance3D).mesh.get_faces()
					for k in f.size():
						f[k] = (ch as MeshInstance3D).transform * f[k]
					hf.append_array(f)
			var gl: Vector3 = gv.hull.to_local(gv.gunner.global_position)
			var surf := Vehicle._deck_h(hf, gl.x, gl.z, -1.0)
			var line := "DECK gunner %s %s feet=%.2f hull_surface=%.2f" % [o[2], gv.vtype, gl.y, surf]
			if surf > 0.0 and gl.y > surf - 0.35:
				line += " STANDING_ON_TOP"
				gun_bad += 1
			print(line)
		G.remove_unit(gv)
		gv.queue_free()
	print("DECK gunners_on_top=%d" % gun_bad)
	if gun_bad > 0:
		fails += 1
	_cam(c + Vector3(-4, 0, -12), 40.0)
	await m._wait(0.5)
	await m._shot("deck_00_all")
	var shown := 0
	for i in vs.size():
		if shown >= 4 or not vs[i].riders_visible():
			continue
		if i % 3 != 0:
			continue
		_cam(vs[i].position, 8.0)
		await m._wait(0.4)
		await m._shot("deck_%02d_%s" % [shown + 1, ids[i]])
		shown += 1
	print("DECKTEST RESULT fails=%d" % fails)

# 97: ABD tankları yan yana (I, II, II-D, III) — taret / kubbe karşılaştırması, yakın çekim
func mbt_gallery() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 11)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	G.fog_off = true
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 40.0)
	var ids := ["usa_mbt_a1", "usa_mbt_a2", "usa_mbt_s2", "usa_mbt_s3"]
	var vs: Array = []
	for i in ids.size():
		var v = m.spawn_vehicle(0, ids[i], c + Vector3(-15.0 + i * 10.0, 0, 0), PI * 0.75)
		v.cmd_hold()
		v.fire_mode = 2
		vs.append(v)
	await m._wait(2.0)
	_cam(c, 26.0)
	await m._wait(0.6)
	await m._shot("mbt_00_all")
	for i in vs.size():
		var v: Vehicle = vs[i]
		var ta := (v.turret_mi.mesh as Mesh).get_aabb() if v.turret_mi != null else AABB()
		var ha := (v.hull_mi.mesh as Mesh).get_aabb() if v.hull_mi != null else AABB()
		print("MBTGAL %s turret_aabb=%s hull_aabb=%s turret_pos=%s hull_scale=%s" % [ids[i], ta.size, ha.size, v.turret.position if v.turret else Vector3.ZERO, v.hull.scale])
		_cam(v.position, 9.0)
		await m._wait(0.4)
		await m._shot("mbt_%02d_%s" % [i + 1, ids[i]])
	print("MBTGALLERY RESULT fails=0")

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

# GPU kategorisini gizle; geri alma işlevi döndürür
func _gpu_part(part: String, _on: bool) -> Callable:
	var hidden: Array = []
	var hide := func(n: Node) -> void:
		if n is Node3D and (n as Node3D).visible:
			(n as Node3D).visible = false
			hidden.append(n)
	match part:
		"fx":
			hide.call(G.fx)
		"grass":
			for n in m.get_tree().get_nodes_in_group("zoom_grass"):
				hide.call(n)
		"shadows":
			m.sun.shadow_enabled = false
			G.cam.shadows_on = false
			return func():
				G.cam.shadows_on = true
				m.sun.shadow_enabled = true
		"trees":
			for c in G.props.get_children():
				if c is MultiMeshInstance3D and not c.is_in_group("zoom_grass"):
					hide.call(c)
		"units":
			for u in G.units:
				if is_instance_valid(u):
					hide.call(u)
		"ssao":
			m.env.ssao_enabled = false
			return func(): m.env.ssao_enabled = true
		"props_all":
			hide.call(G.props)
		"world":
			# arazi + binalar (G.props ve birimler dışı her şey)
			for c in m.world.get_children():
				if c != G.props and c != G.fx and not (c is Unit):
					hide.call(c)
		"msaa":
			m.get_viewport().msaa_3d = Viewport.MSAA_DISABLED
			return func(): m.get_viewport().msaa_3d = Viewport.MSAA_4X
	return func():
		for n in hidden:
			if is_instance_valid(n):
				n.visible = true

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

# roadmap 18: kapakta komutan (ateş altında içeri girer), açık bölmeli obüste güvertede çalışan mürettebat
func crewvis_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 41)
	G.fog_off = true
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var tk: Vehicle = m.spawn_vehicle(0, "usa_mbt_s3", c, PI * 0.25)
	var ifv: Vehicle = m.spawn_vehicle(0, "rus_ifv_bmp2m", G.grid.nearest_open(c + Vector3(12, 0, 0), Grid.M_HEAVY), PI * 0.25)
	var spg: Vehicle = m.spawn_vehicle(0, "usa_spg_m110", G.grid.nearest_open(c + Vector3(-14, 0, 6), Grid.M_HEAVY), PI * 0.25)
	for v in [tk, ifv, spg]:
		v.cmd_hold()
		v.fire_mode = 2
	await m._wait(1.5)
	var out0: bool = tk.cmdr != null and tk.cmdr.visible
	_cam(c + Vector3(-2, 0, 2), 20.0)
	await m._wait(0.4)
	await m._shot("crew_01_hatch")
	# ateş altında içeri girer
	Vehicle.shot_from = tk.position + tk.forward() * 50.0
	tk.take_damage(5.0, null, "bullet")
	await m._wait(1.0)
	var in1: bool = tk.cmdr != null and not tk.cmdr.visible
	# açık bölmeli obüs: atıştan sonra güverte mürettebatı dolum döngüsünde
	var deck := spg.crew.size()
	var e: Vehicle = m.spawn_vehicle(1, "tank", G.grid.nearest_open(spg.position + spg.forward() * 120.0, Grid.M_HEAVY), 0.0)
	e.fire_mode = 2
	spg.fire_mode = 0
	spg.cmd_attack(e)
	var cycled := false
	for k in 40:
		await m._wait(0.25)
		if spg.crew_cycle > 0.0 and spg.main_cd > 0.0:
			cycled = true
			break
	_cam(spg.position, 16.0)
	await m._wait(1.2)
	await m._shot("crew_02_spg_deck")
	print("CREWVIS cmdr_out=%s ducked_under_fire=%s spg_deck_crew=%d spg_cycle=%s" % [out0, in1, deck, cycled])
	if not out0 or not in1 or deck < 3:
		fails += 1
	print("CREWVISTEST RESULT fails=%d" % fails)

# roadmap 7: havan timi — havanı kurar (taban, ayak, namlu kademeli), namluya mermi bırakır, atışta kulak kapatır
func mortar_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_INF)
	var sq := Squad.new(0, "Havan")
	G.squads.append(sq)
	var mo: Soldier = m.spawn_soldier(0, "mortar", c, sq)
	mo.cmd_hold()
	mo.mortar_rounds = 20
	var en: Array = []
	for i in 4:
		var e: Soldier = m.spawn_soldier(1, "rifle", G.grid.nearest_free(c + Vector3(55 + i * 2.0, 0, 8), Grid.M_INF), null)
		e.cmd_hold()
		e.fire_mode = 2
		e.hp = 4000.0
		en.append(e)
	var built_at := -1.0
	var shot_at := -1.0
	for k in 160:
		await m._wait(0.1)
		if built_at < 0.0 and mo.mortar_prop != null and mo.mortar_setup >= 4.0:
			built_at = G.time
			_cam(mo.position, 8.0)
			await m._shot("mortar_01_setup")
		if mo._mortar_fired > 0.0 and shot_at < 0.0:
			shot_at = G.time
			_cam(mo.position, 8.0)
			await m._wait(0.15)
			await m._shot("mortar_02_fire")
			break
	print("MORTAR prop=%s built=%s fired=%s rounds=%d" % [mo.mortar_prop != null, built_at > 0.0, shot_at > 0.0, mo.mortar_rounds])
	if mo.mortar_prop == null or shot_at < 0.0:
		fails += 1
	# yürüyünce söker
	mo.cmd_move(G.grid.nearest_free(c + Vector3(-10, 0, 0), Grid.M_INF))
	await m._wait(2.0)
	print("MORTAR packed=%s" % (mo.mortar_prop == null))
	if mo.mortar_prop != null:
		fails += 1
	print("MORTARTEST RESULT fails=%d" % fails)

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

# 52: bina yıkımı — kısmi delik (kırık kenar, yerinden oynamış bloklar, düzensiz parçalar, toz) ve tam çökme
# (çatı eğilerek iner, duvarlar tepeden aşağı yıkılır, kalıntı duvar parçaları + moloz tepesi kalır)
func ruin_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var B: Blocks = G.blocks
	# merkeze en yakın iki sağlam ev
	var mid := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var hs: Array = []
	for i in B.houses.size():
		var h: Dictionary = B.houses[i]
		if not h["collapsed"] and h["total"] > 60:
			hs.append(i)
	hs.sort_custom(func(a, b): return (B.houses[a]["center"] as Vector3).distance_to(mid) < (B.houses[b]["center"] as Vector3).distance_to(mid))
	if hs.size() < 2:
		print("RUIN houses=%d" % hs.size())
		print("RUINTEST RESULT fails=1")
		return
	var h1: Dictionary = B.houses[hs[0]]
	var h2: Dictionary = B.houses[hs[1]]
	var c1: Vector3 = h1["center"]
	var sz1: Vector2 = h1["size"]
	# 1) kısmi: duvara tek top mermisi
	var wall_p := c1 + Vector3(sz1.x * 0.5, 1.6, 0)
	_cam(c1, 16.0)
	await m._wait(0.6)
	await m._shot("ruin_00_before")
	var r0: int = B.rubble_n
	var k0: int = B.blast(wall_p, 1.6, 1.2)
	await m._wait(0.25)
	await m._shot("ruin_01_hole_fly")
	await m._wait(3.0)
	await m._shot("ruin_02_hole_settled")
	var scars := 0
	for v in B.bscar:
		scars += v
	print("RUIN partial killed=%d scars=%d rubble=+%d collapsed=%s" % [k0, scars, B.rubble_n - r0, h1["collapsed"]])
	if k0 < 3 or scars < 5 or B.rubble_n - r0 < k0:
		fails += 1
	# 2) tam çökme: ikinci binaya ağır topçu ateşi
	var c2: Vector3 = h2["center"]
	var sz2: Vector2 = h2["size"]
	_cam(c2, 22.0)
	await m._wait(0.5)
	await m._shot("ruin_03_before_collapse")
	var r1: int = B.rubble_n
	for j in 4:
		G.explode(c2 + Vector3(randf_range(-sz2.x, sz2.x) * 0.35, 2.0, randf_range(-sz2.y, sz2.y) * 0.35), 4.0, 200.0, "shell", 1)
		await m._wait(0.15)
	await m._wait(0.4)
	await m._shot("ruin_04_collapsing")
	# (143) devrilen duvar levhası sahnede mi (blocks altında Node3D pivot + kutu)
	var slabs := 0
	for ch in B.get_children():
		if ch is Node3D and ch.get_child_count() == 1 and ch.get_child(0) is MeshInstance3D and (ch.get_child(0) as MeshInstance3D).mesh is BoxMesh:
			slabs += 1
	print("RUIN topple slabs=%d hit_recorded=%s" % [slabs, h2.has("hit")])
	if slabs < 1:
		fails += 1
	await m._wait(1.2)
	await m._shot("ruin_05_falling")
	await m._wait(3.5)
	await m._shot("ruin_06_rubble")
	var alive := 0
	for w in B.walls:
		if w["house"] == hs[1]:
			for id in w["blocks"]:
				alive += B.balive[id]
	print("RUIN collapse collapsed=%s alive_left=%d/%d rubble=+%d collapsing_left=%d roof_hidden=%s" % [h2["collapsed"], alive, h2["total"], B.rubble_n - r1, B.collapsing.size(), not (h2["roof"] != null and is_instance_valid(h2["roof"]) and h2["roof"].visible)])
	if not h2["collapsed"] or alive == 0 or B.rubble_n - r1 < 40 or not B.collapsing.is_empty():
		fails += 1
	_cam(c2, 9.0)
	await m._wait(0.4)
	await m._shot("ruin_07_close")
	# 36: kum torbası siperi (yastık torbalar, çuval dokusu) ve yırtılan torbalar
	var sp := G.grid.nearest_open(c1 + Vector3(0, 0, sz1.y * 0.5 + 12.0), Grid.M_INF)
	G.props.clear_area(sp, 8.0)
	var line: Building = m.place_line(0, "sandbags", sp + Vector3(-3, 0, 0), sp + Vector3(3, 0, 0.6))
	line.complete()
	_cam(sp, 5.0)
	await m._wait(0.5)
	await m._shot("ruin_08_sandbags")
	var bn0: int = B.bag_n
	B.blast(sp + Vector3(1.0, 0.4, 0.3), 1.0, 0.8)
	await m._wait(1.5)
	await m._shot("ruin_09_sandbags_hit")
	print("RUIN sandbags burst=%d" % (B.bag_n - bn0))
	if B.bag_n - bn0 < 2:
		fails += 1
	print("RUINTEST RESULT fails=%d" % fails)

# askerler yaklaşan araca yol verir: yolda duran tim kenara çekilir, araç durmadan geçer
func yield_test() -> void:
	m.get_window().size = Vector2i(1280, 720)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 43)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	# karargâhtan merkeze doğru, 60 m'lik düz ve engelsiz bir şerit ara (nehir/orman olmasın)
	var c := G.grid.nearest_open(G.hq_pos[0], Grid.M_HEAVY)
	for k in 40:
		var cand := G.grid.nearest_open(G.hq_pos[0].lerp(G.hq_pos[1], 0.08 + k * 0.02), Grid.M_HEAVY)
		if G.grid.walkable_line(cand + Vector3(-32, 0, 0), cand + Vector3(32, 0, 0), Grid.M_HEAVY) and not G.grid.is_water(cand):
			c = cand
			break
	G.props.clear_area(c, 36.0)
	var v: Vehicle = m.spawn_vehicle(0, "usa_lv_m1151", c + Vector3(-30, 0, 0), PI * 0.5)
	var ss: Array = []
	for i in 6:
		var s: Soldier = m.spawn_soldier(0, "rifle", G.grid.nearest_free(c + Vector3(-6 + i * 2.4, 0, randf_range(-0.4, 0.4)), Grid.M_INF), null)
		ss.append(s)
	await m._wait(1.0)
	v.cmd_move(c + Vector3(30, 0, 0))
	var yielded := 0
	var min_d := 99.0
	for k in 160:
		await m._wait(0.1)
		for s in ss:
			if s.yield_veh == v and G.time < s.yield_until:
				yielded += 1
			min_d = minf(min_d, Vector2(s.position.x - v.position.x, s.position.z - v.position.z).length())
		if v.position.x > c.x + 26.0:
			break
	var passed := v.position.x > c.x + 20.0
	_cam(c, 30.0)
	await m._shot("yield_01")
	print("YIELD passed=%s yield_frames=%d min_dist=%.2f vehx=%.1f" % [passed, yielded, min_d, v.position.x - c.x])
	if not passed or yielded == 0 or min_d < 0.5:
		fails += 1
	print("YIELDTEST RESULT fails=%d" % fails)

# 41: köprü — iki tip (taş kemer / betonarme); yakınlaştırma basamaklarında gölge (iki karede küçük kaydırma:
# titreme/kayma), kısmi hasar (delik, kopan korkuluk), çöküş (açıklık suya düşer, köprü geçilmez olur)
func bridge_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var mid := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var picks := {}
	for it in G.props.items:
		if it.get("kind", "") != "bridge" or not it["alive"]:
			continue
		var tk := "stone" if it["stone"] else "conc"
		var d: float = (it["pos"] as Vector3).distance_to(mid)
		if not picks.has(tk) or d < picks[tk][0]:
			picks[tk] = [d, it]
	for want in ["stone", "conc"]:
		if picks.has(want) or G.terrain._rivers.is_empty():
			continue
		# bu haritada o tip yoksa: nehrin ortasına, öteki köprülerden uzak (yolsuz) bir tane kur
		var rv: Array = G.terrain._rivers[0]
		var pts: PackedVector3Array = rv[0]
		for i in range(pts.size() / 3, pts.size() - 2):
			var p := pts[i]
			var far := true
			for it in G.props.items:
				if it.get("kind", "") == "bridge" and (it["pos"] as Vector3).distance_to(p) < 70.0:
					far = false
			if not far or p.x < 30.0 or p.z < 30.0 or p.x > G.MAP - 30.0 or p.z > G.MAP - 30.0:
				continue
			var t := (pts[i + 1] - pts[i - 1]).normalized()
			G.props.bridge(Vector3(p.x, 0, p.z), Vector3(-t.z, 0, t.x), minf(float(rv[1]) + 5.0, 20.0) if want == "stone" else 34.0)
			var nb: Dictionary = G.props.items[G.props.items.size() - 1]
			if nb.get("stone", false) == (want == "stone"):
				picks[want] = [0.0, nb]
			break
	print("BRIDGE kinds=%s" % [picks.keys()])
	for tk in ["conc", "stone"]:
		if not picks.has(tk):
			print("BRIDGE %s none" % tk)
			continue
		var br: Dictionary = picks[tk][1]
		var c: Vector3 = br["pos"]
		var zs := [22.0, 60.0, 160.0, 420.0, 900.0] if tk == "conc" else [22.0]
		for sz in zs:
			for k in 2:
				G.cam.size = sz
				G.cam.target_size = sz
				G.cam.jump_to(c + G.cam.right_vec() * (sz * 0.004 * k), true)
				await m._wait(0.35)
				await m._shot("%s_z%d_%d" % [tk, int(sz), k])
		# uç ayak / kanat duvarı / yaklaşım bariyeri yakın çekim
		G.cam.size = 12.0
		G.cam.target_size = 12.0
		G.cam.jump_to(c + (br["dir"] as Vector3) * (float(br["Ld"]) * 0.5), true)
		await m._wait(0.35)
		await m._shot("%s_end" % tk)
		# kısmi hasar: iki top mermisi (döşemede delik); kenara düşen mermi korkuluğu koparır
		G.cam.size = 20.0
		G.cam.target_size = 20.0
		G.cam.jump_to(c, true)
		var hp0: float = br["hp"]
		var dir: Vector3 = br["dir"]
		var side := Vector3(-dir.z, 0, dir.x)
		for k in 2:
			G.explode(c + dir * (k * 4.0 - 2.0) + Vector3(0, 0.5, 0), 3.5, 160.0, "shell", 1)
			await m._wait(0.4)
		G.explode(c + dir * 5.0 + side * (float(br["W"]) * 0.5 - 0.6) + Vector3(0, 0.5, 0), 3.5, 160.0, "shell", 1)
		await m._wait(5.0)
		await m._shot("%s_damaged" % tk)
		var rl: int = br.get("rail_lost", 0)
		var ho: int = br.get("holes", 0)
		print("BRIDGE %s hp=%.0f->%.0f alive=%s rail_lost=%d holes=%d" % [tk, hp0, br["hp"], br["alive"], rl, ho])
		if not br["alive"] or ho == 0 or rl == 0:
			fails += 1
		# çöküş
		for k in 8:
			G.explode(c + dir * randf_range(-3, 3) + Vector3(0, 0.5, 0), 4.0, 260.0, "big", 1)
			await m._wait(0.15)
		await m._wait(1.0)
		await m._shot("%s_collapsing" % tk)
		await m._wait(7.0)
		G.cam.size = 34.0
		G.cam.target_size = 34.0
		await m._wait(0.3)
		await m._shot("%s_collapsed" % tk)
		var passable := not G.grid.bridge_at(c).is_empty()
		print("BRIDGE %s collapsed=%s passable=%s" % [tk, not br["alive"], passable])
		if br["alive"] or passable:
			fails += 1
	# 14: suya düşüş dalgası araç boyuna göre — nehirde cip ve tank batırılır, yanında top mermisi suya düşer
	var wb: Dictionary = picks["conc"][1] if picks.has("conc") else {}
	if not wb.is_empty():
		var wd: Vector3 = wb["dir"]
		var ws := Vector3(-wd.z, 0, wd.x)
		var wc: Vector3 = (wb["pos"] as Vector3) + ws * 26.0
		var spots := [wc - wd * 3.0, wc + wd * 3.0 + ws * 10.0]
		var ids := ["usa_lv_m1151", "rus_mbt_90m"]
		var sunk := 0
		for i in 2:
			var q: Vector3 = spots[i]
			if not G.grid.is_water(q):
				continue
			var v = m.spawn_vehicle(1, ids[i], q, 0.3)
			v.position = q
			v.destroy(null)
			sunk += 1
		G.explode(wc + ws * 5.0 + Vector3(0, 0.3, 0), 4.0, 130.0, "shell", 1)
		G.cam.size = 40.0
		G.cam.target_size = 40.0
		G.cam.jump_to(wc + ws * 4.0, true)
		for k in 3:
			await m._wait([0.6, 1.2, 2.0][k])
			await m._shot("ripple_%d" % k)
		print("RIPPLE sunk=%d" % sunk)
	print("BRIDGETEST RESULT fails=%d" % fails)

# 41: uzaklaşınca gölge kayması / parlaması — bir binanın çevresi (40 m) her yakınlaştırmada aynı boya kırpılıp
# yan yana dizilir: gölge binadan kopuyor mu, kenarlar titriyor mu. Ayrıca yavaş yakınlaştırmada ardışık kareler.
func shadow_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("front_2k", {}, true, 7)
	G.fog_off = true
	G.reveal = [9999.0, 9999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var mid := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var hc := mid
	var bd := 1e9
	for hs in G.blocks.houses:
		var c: Vector3 = hs["center"]
		var d := c.distance_to(mid)
		if d < bd and (hs["size"] as Vector2).x > 6.0:
			bd = d
			hc = c
	var sizes := [40.0, 80.0, 160.0, 300.0, 450.0, 614.0]
	var T := 220
	var sheet := Image.create(T * sizes.size(), T * 2, false, Image.FORMAT_RGBA8)
	for i in sizes.size():
		var sz: float = sizes[i]
		G.cam.size = sz
		G.cam.target_size = sz
		G.cam.jump_to(hc, true)
		await m._wait(0.5)
		await m._shot("shadow_z%d" % int(sz))
		await RenderingServer.frame_post_draw
		var img := m.get_viewport().get_texture().get_image()
		var sp := G.cam.cam.unproject_position(hc) * Vector2(img.get_size()) / m.get_viewport().get_visible_rect().size
		var half := int(20.0 * 900.0 / sz)
		var r := Rect2i(int(sp.x) - half, int(sp.y) - half, half * 2, half * 2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
		var cr := img.get_region(r)
		cr.convert(Image.FORMAT_RGBA8)
		cr.resize(T, T, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(cr, Rect2i(0, 0, T, T), Vector2i(i * T, 0))
		# aynı yakınlaştırmada yarım piksel kaydırılmış ikinci kare (titreme)
		G.cam.jump_to(hc + G.cam.right_vec() * (sz / 900.0) * 0.5, true)
		await m._wait(0.2)
		await RenderingServer.frame_post_draw
		var img2 := m.get_viewport().get_texture().get_image()
		var sp2 := G.cam.cam.unproject_position(hc) * Vector2(img2.get_size()) / m.get_viewport().get_visible_rect().size
		var r2 := Rect2i(int(sp2.x) - half, int(sp2.y) - half, half * 2, half * 2).intersection(Rect2i(Vector2i.ZERO, img2.get_size()))
		var cr2 := img2.get_region(r2)
		cr2.convert(Image.FORMAT_RGBA8)
		cr2.resize(T, T, Image.INTERPOLATE_BILINEAR)
		sheet.blit_rect(cr2, Rect2i(0, 0, T, T), Vector2i(i * T, T))
	sheet.save_png(m.shot_dir.path_join("shadow_sheet.png"))
	# yavaş yakınlaştırma: 150 → 170 arası 8 kare (gölge sürünmesi)
	var sheet2 := Image.create(T * 8, T, false, Image.FORMAT_RGBA8)
	for k in 8:
		var sz2 := 150.0 + k * 2.5
		G.cam.size = sz2
		G.cam.target_size = sz2
		G.cam.jump_to(hc, true)
		await m._wait(0.1)
		await RenderingServer.frame_post_draw
		var img3 := m.get_viewport().get_texture().get_image()
		var sp3 := G.cam.cam.unproject_position(hc) * Vector2(img3.get_size()) / m.get_viewport().get_visible_rect().size
		var half3 := int(12.0 * 900.0 / sz2)
		var r3 := Rect2i(int(sp3.x) - half3, int(sp3.y) - half3, half3 * 2, half3 * 2).intersection(Rect2i(Vector2i.ZERO, img3.get_size()))
		var cr3 := img3.get_region(r3)
		cr3.convert(Image.FORMAT_RGBA8)
		cr3.resize(T, T, Image.INTERPOLATE_NEAREST)
		sheet2.blit_rect(cr3, Rect2i(0, 0, T, T), Vector2i(k * T, 0))
	sheet2.save_png(m.shot_dir.path_join("shadow_zoomseq.png"))
	print("SHADOW house=%s" % [hc])
	print("SHADOWTEST RESULT fails=0")

# 14: duman / patlama bulutu — her tür için zaman dizisi (0.1 → 6 sn); arkadaki bina dumanın içinden seçilmeli
func smoke_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	var mid := Vector3(G.MAP * 0.5, 0, G.MAP * 0.5)
	var hc := mid
	var bd := 1e9
	for hs in G.blocks.houses:
		var c: Vector3 = hs["center"]
		if c.distance_to(mid) < bd:
			bd = c.distance_to(mid)
			hc = c
	await m._wait(2.5)          # açılış kamera hareketi bitsin
	var cases := [["shell", 4.5, 130.0], ["big", 6.0, 300.0], ["grenade", 2.5, 60.0], ["mortar", 4.0, 110.0], ["burn", 0.0, 0.0], ["screen", 0.0, 0.0]]
	var times := [0.12, 0.4, 0.9, 1.8, 3.5, 6.0]
	var T := 260
	var sheet := Image.create(T * times.size(), T * cases.size(), false, Image.FORMAT_RGBA8)
	for ci in cases.size():
		var cs: Array = cases[ci]
		# patlama binanın kameraya bakan yanında: bina dumanın arkasında kalır
		var p := hc + Vector3(7.0, 0, 7.0) + Vector3(ci * 0.0, 0, 0)
		G.cam.size = 34.0
		G.cam.target_size = 34.0
		G.cam.jump_to(p + Vector3(-3.0, 0, -3.0), true)
		await m._wait(0.6)
		var t0 := G.time
		match cs[0]:
			"burn":
				G.fx.burn(p, 30.0, 1.2)
				G.fx.fire_column(p, 30.0, 1.0)
			"screen":
				G.fx.smoke_screen(p, 20.0)
			_:
				G.explode(p + Vector3(0, 0.3, 0), cs[1], cs[2], cs[0], 1)
		for ti in times.size():
			while G.time - t0 < float(times[ti]):
				G.cam._shake = 0.0
				await m.get_tree().process_frame
			await RenderingServer.frame_post_draw
			var img := m.get_viewport().get_texture().get_image()
			var sp := G.cam.cam.unproject_position(p + Vector3(0, 3.0, 0)) * Vector2(img.get_size()) / m.get_viewport().get_visible_rect().size
			var half := int(15.0 * 900.0 / 34.0)
			var r := Rect2i(int(sp.x) - half, int(sp.y) - half, half * 2, half * 2).intersection(Rect2i(Vector2i.ZERO, img.get_size()))
			var cr := img.get_region(r)
			cr.convert(Image.FORMAT_RGBA8)
			cr.resize(T, T, Image.INTERPOLATE_BILINEAR)
			sheet.blit_rect(cr, Rect2i(0, 0, T, T), Vector2i(ti * T, ci * T))
		if cs[0] == "big":
			await m._shot("smoke_big_full")
		# bir sonraki tür için ortalığı temizle (dumanlar sönsün)
		G.fx.emitters.clear()
		await m._wait(7.0)
	sheet.save_png(m.shot_dir.path_join("smoke_sheet.png"))
	print("SMOKETEST RESULT fails=0")

# 24: hacimli alev (yanan araç yakın çekim, zaman dizisi) ve roketatar tüp çıkışı (M270, BM-21)
func fire_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(2.0)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5 + 30.0, 0, G.MAP * 0.5 - 20.0), Grid.M_HEAVY)
	var tk := m.spawn_vehicle(1, "rus_mbt_72b3", c, 0.6)
	tk.cmd_hold()
	await m._wait(0.3)
	tk.destroy(null)
	G.fx.burn(tk.position + Vector3(0, 1.0, 0), 60.0, 1.4)
	G.cam.size = 16.0
	G.cam.target_size = 16.0
	G.cam.jump_to(c, true)
	for k in 4:
		await m._wait([1.5, 2.0, 3.0, 6.0][k])
		await m._shot("burn_%d" % k)
	# roketatar salvoları
	var ids := ["usa_mlrs_m270", "rus_mlrs_grad"]
	for i in 2:
		var p := G.grid.nearest_free(c + Vector3(-40.0 + i * 30.0, 0, 40.0), Grid.M_HEAVY)
		var ml := m.spawn_vehicle(0, ids[i], p, 0.8)
		ml.cmd_hold()
		ml.deployed = 0.0
		G.cam.size = 14.0
		G.cam.target_size = 14.0
		G.cam.jump_to(p, true)
		await m._wait(1.5)
		await m._shot("pod_%s_rise" % ids[i])
		await m._wait(ml.deploy_time())
		ml.mlrs_aim = p + Vector3(600.0, 0, -500.0)
		ml.mlrs_left = ml.salvo_n if ml.salvo_n > 0 else 12
		ml.mlrs_t = 0.0
		var n0: int = ml.mlrs_left
		for k in 4:
			await m._wait([0.12, 0.25, 0.5, 1.2][k])
			await m._shot("pod_%s_%d" % [ids[i], k])
		print("POD %s salvo=%d left=%d vtype=%s alive=%s dep=%.2f proc=%s mt=%.2f" % [ids[i], n0, ml.mlrs_left, ml.vtype, ml.alive, ml.deployed, ml.is_processing(), ml.mlrs_t])
	print("FIRETEST RESULT fails=0")

# asker görünümü (60/61/66/74/80/85/89): oyun açısından yakın çekim — yürüyen tim (ardışık kareler, ayak teması
# ve gölge), duruşlar (bekleme, nişan, çömelme, yüzüstü), tank üstündekiler, siperdekiler, sırtında tanksavar taşıyan
func soldier_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 43)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(2.0)
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5 - 40.0, 0, G.MAP * 0.5 + 30.0), Grid.M_HEAVY)
	G.props.clear_area(c, 30.0)
	# 1) yürüyen ve koşan tim
	var walkers: Array = []
	for i in 4:
		var s := m.spawn_soldier(0, ["rifle", "mg", "at", "rifle"][i], c + Vector3(-14.0, 0, -8.0 + i * 1.8), null)
		walkers.append(s)
	for i in walkers.size():
		walkers[i].cmd_move(walkers[i].position + Vector3(30.0, 0, 0), i % 2 == 1)
	G.cam.size = 8.0
	G.cam.target_size = 8.0
	await m._wait(1.6)
	G.cam.jump_to(walkers[1].position + Vector3(2.0, 0, 0), true)
	for k in 6:
		await m._wait(0.07)
		await m._shot("walk_%d" % k)
	# 2) duruşlar: düşman uzakta (nişan alsınlar)
	var foe := m.spawn_soldier(1, "rifle", c + Vector3(70.0, 0, 0), null)
	foe.cmd_hold()
	foe.hp = 1e9
	var kinds := [["rifle", Soldier.STAND], ["rifle", Soldier.CROUCH], ["rifle", Soldier.PRONE], ["mg", Soldier.STAND], ["at", Soldier.STAND], ["sniper", Soldier.CROUCH]]
	var posed: Array = []
	for i in kinds.size():
		var s := m.spawn_soldier(0, kinds[i][0], c + Vector3(-4.0 + i * 1.7, 0, 6.0), null)
		s.stance_lock = kinds[i][1]
		s.stance = kinds[i][1]
		s.cmd_hold()
		posed.append(s)
	# 3) tank üstündekiler
	var tk := m.spawn_vehicle(0, "rus_mbt_72b3", c + Vector3(-6.0, 0, 14.0), 0.4)
	tk.cmd_hold()
	for i in 4:
		var s := m.spawn_soldier(0, "rifle", c + Vector3(-6.0, 0, 18.0), null)
		s.board(tk)
	# 4) siper
	var tr := m.place_line(0, "trench", c + Vector3(6.0, 0, 13.0), c + Vector3(16.0, 0, 15.0))
	tr.add_work(99999.0)
	await m._wait(1.0)
	for i in 3:
		var s := m.spawn_soldier(0, ["rifle", "mg", "rifle"][i], c + Vector3(8.0 + i * 3.0, 0, 13.6 + i * 0.6), null)
		s.cmd_hold()
	await m._wait(4.0)
	G.cam.size = 10.0
	G.cam.target_size = 10.0
	G.cam.jump_to(c + Vector3(0.0, 0, 6.0), true)
	await m._wait(0.6)
	await m._shot("poses")
	G.cam.size = 9.0
	G.cam.target_size = 9.0
	G.cam.jump_to(tk.position, true)
	await m._wait(0.5)
	await m._shot("riders")
	G.cam.jump_to(c + Vector3(11.0, 0, 14.0), true)
	await m._wait(0.5)
	await m._shot("trench")
	# 119 / 60: oyuk arazide (nehir şevi, krater) asker havada durmaz — ayağı zemine basar
	var fails := 0
	var bank := Vector3.INF
	var rr := RandomNumberGenerator.new()
	rr.seed = 3
	for i in 4000:
		var p := Vector3(rr.randf_range(20, G.MAP - 20), 0, rr.randf_range(20, G.MAP - 20))
		if G.terrain.ground_hs(p) < -0.4 and G.grid.free_at(p, Grid.M_INF) and not G.grid.is_water(p) and not G.grid.on_bridge(p):
			bank = p
			break
	if bank != Vector3.INF:
		var bs: Array = []
		for i in 3:
			var s := m.spawn_soldier(0, "rifle", G.grid.nearest_free(bank + Vector3(i * 0.9, 0, 0), Grid.M_INF), null)
			s.cmd_hold()
			bs.append(s)
		await m._wait(1.5)
		var worst := 0.0
		for s in bs:
			worst = maxf(worst, absf(s.position.y - minf(0.0, G.terrain.ground_hs(s.position))))
		print("SOLDIER bank=%s ground=%.2f worst_gap=%.2f ys=%s" % [bank, G.terrain.ground_hs(bank), worst, bs.map(func(x): return snappedf(x.position.y, 0.01))])
		_cam(bank, 9.0)
		await m._wait(0.4)
		await m._shot("bank")
		if worst > 0.12:
			fails += 1
	else:
		print("SOLDIER bank=none")
	print("SOLDIERTEST RESULT fails=%d" % fails)

# 91: silahlı İHA (MQ-9 / Orion) — havada kalır, görünür, yörüngede döner, hedefe füze atar
func armed_uav_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	m.start_game("green_valley", {}, true, 43)
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(1.5)
	var fails := 0
	var c := G.grid.nearest_free(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	var ids := ["usa_uav_mq9", "rus_uav_orion", "uav_armed", "uav_armed"]
	var uavs: Array = []
	for i in 4:
		var u = m.spawn_vehicle(i % 2, ids[i], c + Vector3(-30.0 + (i % 2) * 60.0, 0, 20.0 + (i / 2) * 30.0), 0.0)
		u.cmd_move(c + Vector3(-20.0 + (i % 2) * 40.0, 0, -10.0 + (i / 2) * 50.0))
		uavs.append(u)
	# 93: ABD'nin büyük İHA'ları da (MQ-1C, RQ-4) — çizilen kanat açıklığı denetimi için
	for xid in ["usa_uav_mq1c", "usa_uav_rq4"]:
		var ux = m.spawn_vehicle(0, xid, c + Vector3(-10.0 + uavs.size() * 6.0, 0, 30.0), 0.0)
		ux.cmd_move(c + Vector3(10.0, 0, 30.0))
		uavs.append(ux)
	var tk := m.spawn_vehicle(1, "rus_mbt_72b3", c + Vector3(-20.0, 0, -12.0), 0.0)
	tk.cmd_hold()
	# oyuncu yolu: helikopter pistinde üretim (sandbox para), toplanma noktasına uçuş
	var hp := m.place_building(0, "helipad", G.grid.nearest_free(c + Vector3(0, 0, 45.0), Grid.M_HEAVY), 0.0)
	hp.add_work(99999.0)
	await m._wait(0.5)
	G.supply[0] = 99999
	var ok_q: bool = hp.enqueue("usa_uav_mq9")
	print("UAV helipad queue=%s done=%s" % [ok_q, hp.done])
	for k in 15:
		await m._wait(2.0)
		for u2 in G.units:
			if is_instance_valid(u2) and u2 is Vehicle and u2.vtype == "uav_armed" and not uavs.has(u2):
				uavs.append(u2)
		for u in uavs:
			if is_instance_valid(u):
				print("UAV %s t=%d alive=%s alt=%.1f vis=%s hull_vis=%s pos=%s seen0=%s missiles=%d vt=%s" % [u.vid, k, u.alive, u.hull.position.y, u.visible, u.hull.visible, u.position, u.seen[0] if u.seen.size() > 0 else -1, u.missiles, u.vtype])
	G.cam.size = 70.0
	G.cam.target_size = 70.0
	G.cam.jump_to(c, true)
	await m._wait(0.5)
	await m._shot("armeduav_wide")
	for u in uavs:
		if is_instance_valid(u) and u.alive:
			G.cam.size = 24.0
			G.cam.target_size = 24.0
			G.cam.jump_to(u.position, true)
			await m._wait(0.3)
			await m._shot("armeduav_%s" % u.vid)
			if u.hull.position.y < 5.0 or not u.visible:
				fails += 1
			# görsel irtifa ölçeği: çizilen kanat açıklığı (tank ~7 m) en çok ~10 m
			var span := 0.0
			for mi in u.hull.get_children():
				if mi is MeshInstance3D and mi.mesh != null:
					span = maxf(span, mi.mesh.get_aabb().size.x * u.hull.scale.x)
			print("UAVSPAN %s vis=%.2f span=%.1f" % [u.vid, u.uav_vis, span])
			if span > 10.0:
				fails += 1
		else:
			fails += 1
	print("ARMEDUAV RESULT fails=%d" % fails)

# 94: taret kopması katı cisim — biçimler: dimdik takla (pop), yana savrulma (toss), arkaya devrilme (flipback),
# kalkıp gövdeye oturma (lift), güverteden kayma (slide), namlu kopması, M1 panel atma (vent), yanan tankta
# gecikmeli infilak (late). Uçuş kareleri; yerleşince yüzme / gömülme denetimi. 87: tank üstündekiler savrulur.
func turret_test() -> void:
	m.get_window().size = Vector2i(1600, 900)
	Sfx.muted = true
	var fails := 0
	m.start_game("green_valley", {}, true, 31)
	G.fog_off = true
	G.reveal = [999.0, 999.0]
	for a in G.ais:
		a.queue_free()
	G.ais.clear()
	await m._wait(1.0)
	var c := G.grid.nearest_open(Vector3(G.MAP * 0.5, 0, G.MAP * 0.5), Grid.M_HEAVY)
	G.props.clear_area(c, 45.0)
	# [araç, imha, biçim, vuruş yönü (0 ön, 1 sağ, 2 arka, 3 üst), mühimmat, namlu kopması]
	var cases := [
		["rus_mbt_72b3", "catastrophic", "pop", 3, "topatk", 0],
		["rus_mbt_90m", "cookoff", "toss", 1, "atgm", 0],
		["rus_mbt_80", "cookoff", "flipback", 0, "ap", 0],
		["rus_mbt_72b", "cookoff", "lift", 0, "ap", 0],
		["rus_ifv_bmp2m", "cookoff", "slide", 2, "rpg", 0],
		["rus_mbt_72b3", "catastrophic", "pop", 3, "big", 1],
		["usa_mbt_s3", "cookoff", "vent", 2, "atgm", 0],
		["rus_mbt_90a", "late", "", 1, "rpg", 0]]
	var vs: Array = []
	for i in cases.size():
		var p := G.grid.nearest_open(c + Vector3(-27.0 + (i % 4) * 18.0, 0, -11.0 + (i / 4) * 22.0), Grid.M_HEAVY)
		var v: Vehicle = m.spawn_vehicle(1 if String(cases[i][0]).begins_with("rus") else 0, cases[i][0], p, randf_range(-0.6, 0.6))
		v.cmd_hold()
		v.fire_mode = 2
		v.force_mode = cases[i][1]
		v.force_style = cases[i][2]
		v.force_gun_off = cases[i][5]
		vs.append(v)
	# 87: ilk tankın üstünde 4 asker
	var riders: Array = []
	for i in 4:
		var s := m.spawn_soldier(1, "rifle", vs[0].position + Vector3(0, 0, 4.0), null)
		s.board(vs[0])
		riders.append(s)
	await m._wait(1.0)
	_cam(vs[0].position, 26.0)
	await m._wait(0.3)
	await m._shot("pop_00")
	# önce yalnız ilk tank: yakın uçuş dizisi
	_tt_kill(vs[0], cases[0][3], cases[0][4])
	for k in range(1, 11):
		await m._wait(0.2)
		await m._shot("pop_%02d" % k)
	for i in range(1, vs.size()):
		_tt_kill(vs[i], cases[i][3], cases[i][4])
	_cam(c + Vector3(0, 0, 0.0), 50.0)
	for k in 7:
		await m._wait(0.4)
		await m._shot("all_%02d" % k)
	# yerleşme (oyun süresiyle sınırlı)
	var t0 := G.time
	while G.time - t0 < 28.0:
		var moving := 0
		for v in vs:
			var b: DebrisBody = v.turret_body
			if b != null and is_instance_valid(b) and not b.asleep:
				moving += 1
		if moving == 0 and G.time - t0 > 6.0:
			break
		await m._wait(0.5)
	_cam(c, 50.0)
	await m._wait(0.3)
	await m._shot("all_rest")
	var styles := {}
	for i in vs.size():
		var v: Vehicle = vs[i]
		var b: DebrisBody = v.turret_body
		if cases[i][2] == "vent":
			var stays: bool = v.turret != null and v.turret.get_parent() == v.hull
			print("TURRET %d %s style=%s stays=%s" % [i, cases[i][0], v.turret_style, stays])
			if not stays or v.turret_style != "vent":
				fails += 1
			continue
		if b == null or not is_instance_valid(b):
			print("TURRET FAIL %d %s: taret kopmadı (style=%s mode=%s)" % [i, cases[i][0], v.turret_style, v.kill_mode])
			fails += 1
			continue
		styles[v.turret_style] = true
		var gap := _tt_gap(b)
		var gh: float = G.terrain.ground_hs(b.global_position)
		var upd := b.global_transform.basis.y.dot(Vector3.UP)
		var dist := Vector2(b.global_position.x - v.position.x, b.global_position.z - v.position.z).length()
		print("TURRET %d %s style=%s asleep=%s age=%.1f hits=%d gap=%.2f up=%.2f dist=%.1f com_h=%.2f peak=%.1f pts=%d" % [i, cases[i][0], v.turret_style, b.asleep, b.age, b.hits, gap, upd, dist, b.global_position.y - gh, b.peak, b.pts.size()])
		if not b.asleep or gap < -0.3 or gap > 0.3 or b.global_position.y < gh - 0.25:
			print("TURRET FAIL %d: yüzüyor / gömülü / durmadı" % i)
			fails += 1
		# ölçülü yükseklik (kullanıcı: "aşırı yükseğe uçuyor"): en şiddetli fırlamada bile tepe ≤ 6 m
		if b.peak > 6.0:
			print("TURRET FAIL %d: çok yüksek (%.1f m)" % [i, b.peak])
			fails += 1
		if cases[i][5] == 1:
			var gp = v.barrel.get_parent()
			var sep: bool = gp is DebrisBody and gp != b
			print("TURRET %d namlu ayrı=%s" % [i, sep])
			if not sep:
				fails += 1
		_cam(Vector3(b.global_position.x, 0.0, b.global_position.z).lerp(v.position, 0.35), 15.0)
		await m._wait(0.25)
		await m._shot("rest_%d_%s" % [i, v.turret_style])
	if styles.size() < 4:
		fails += 1
	for s in riders:
		if is_instance_valid(s):
			print("RIDER alive=%s state=%s y=%.2f aboard=%s" % [s.alive, s.state, s.position.y, s.vehicle_in != null])
			if s.alive and (s.state == "aboard" or s.vehicle_in != null or s.position.y > 0.6):
				fails += 1
	print("TURRETTEST RESULT fails=%d" % fails)

# yakınında (r) bina / duvar / su olmayan ilk nokta (sarmal arama, 4 m adım); bulunamazsa en yakın boş hücre
func _open_spot(p: Vector3, r: float) -> Vector3:
	for ring in 12:
		var n := maxi(1, ring * 6)
		for k in n:
			var a := TAU * k / n
			var q := G.on_ground(p + Vector3(cos(a), 0, sin(a)) * ring * 4.0)
			var ok := true
			var x := -r
			while x <= r and ok:
				var z := -r
				while z <= r and ok:
					var s := q + Vector3(x, 0, z)
					if x * x + z * z <= r * r and ((G.grid.height_at(s) > 0.4 and G.grid.kind_at(s) != Grid.K_TREE) or G.grid.is_water(s) or G.grid.kind_at(s) in [Grid.K_HOUSE, Grid.K_BUILDING, Grid.K_WALL]):
						ok = false
					z += 1.0
				x += 1.0
			if ok:
				return q
	return G.grid.nearest_free(p, Grid.M_HEAVY)

# görüş hattını kesen ilk ızgara hücresi (teşhis): uzaklık, hücre yüksekliği, ışın yüksekliği, tür
func _los_block(a: Vector3, b: Vector3, skip_a: float, skip_b: float) -> String:
	var dx := b.x - a.x
	var dz := b.z - a.z
	var dy := b.y - a.y
	var L := sqrt(dx * dx + dz * dz)
	var steps := int(L / 0.33) + 1
	for s in range(1, steps):
		var t := float(s) / steps
		var dist := t * L
		if dist < skip_a or dist > L - skip_b:
			continue
		var p := Vector3(a.x + dx * t, 0, a.z + dz * t)
		var hh: float = G.grid.height_at(p)
		if hh > a.y + dy * t:
			return "%.1fm h=%.2f ray=%.2f k=%d" % [dist, hh, a.y + dy * t, G.grid.kind_at(p)]
	return "-"

# testte imha: isabet yönü / mühimmat doğrudan (zırh delme şansına bırakmadan)
func _tt_kill(v: Vehicle, side: int, k: String) -> void:
	v.kill_k = k
	v.last_side = side
	var d: Vector3 = [-v.forward(), -v.right(), v.forward(), Vector3.ZERO][side]
	v.kill_dir = d if d != Vector3.ZERO else -v.forward()
	v.kill_over = 0.8
	v.hp = 0.0
	v.destroy(null)

# kopan parçanın en alttaki temas noktasının zemine / engel kutusunun üstüne uzaklığı (yüzme > 0, gömülme < 0)
func _tt_gap(b: DebrisBody) -> float:
	var best := INF
	var t := b.global_transform
	for lp in b.pts:
		var wp: Vector3 = t * lp
		var sup: float = b._ground(wp)
		for o in b.obbs:
			var d: Vector3 = wp - o[0]
			var bs: Basis = o[1]
			var he: Vector3 = o[2]
			if absf(d.dot(bs.x)) < he.x and absf(d.dot(bs.z)) < he.z:
				var dt := d.dot(bs.y) - he.y
				if dt > -0.45:
					sup = maxf(sup, wp.y - dt)
		best = minf(best, wp.y - sup)
	return best
