class_name Squad extends RefCounted
# Tim: siper paylaşımı, yaralı kurtarma ve örtme ateşi koordinasyonu.

var team := 0
var members: Array = []
var name := ""
var _t := 0.0

static var _count := [0, 0]

func _init(t: int, n: String) -> void:
	team = t
	if t >= 0:
		_count[t] += 1
		name = I18n.s("Tim %d") % _count[t]
	else:
		name = n
	kind_name = n

var kind_name := ""

func add(s: Soldier) -> void:
	members.append(s)
	s.squad = self

func alive_members() -> Array:
	var out: Array = []
	for m in members:
		if is_instance_valid(m) and m.alive:
			out.append(m)
	return out

func claimed(me: Soldier) -> Array:
	var out: Array = []
	for m in G.friends_near(me.position, 14.0, team):
		if m == me or not (m is Soldier):
			continue
		if m.cover_type > 0:
			out.append(m.cover_pos)
		else:
			out.append(m.position)
	return out

func on_death(_s: Soldier) -> void:
	pass

var _merge_t := 3.0
var peak := 0              # en kalabalık hâli (eriyen timi tanımak için)
var had_leader := false

func has_leader() -> bool:
	for m in members:
		if is_instance_valid(m) and m.alive and m.role == "leader" and m.can_fight():
			return true
	return false

func able() -> Array:
	return members.filter(func(m): return is_instance_valid(m) and m.alive and m.can_fight() and m.squad == self and m.state != "hospital")

# ------------------------------------------------------------ oyuncu emriyle tim birleştirme (tim + tim = manga)
const MERGE_MAX := 13

static func _sel_squads(sel: Array) -> Array:
	var out: Array = []
	for u in sel:
		if is_instance_valid(u) and u is Soldier and u.alive and u.squad != null and u.squad.team >= 0 and not out.has(u.squad):
			out.append(u.squad)
	return out

static func merge_ok(sel: Array) -> bool:
	var sqs := _sel_squads(sel)
	if sqs.size() < 2:
		return false
	var n := 0
	for sq in sqs:
		n += (sq as Squad).able().size()
	return n <= MERGE_MAX

# en kalabalık (eşitse liderli) tim kalır; diğerlerinin savaşabilen üyeleri ona katılıp yanına toplanır
static func merge_selected(sel: Array) -> Squad:
	if not merge_ok(sel):
		return null
	var sqs := _sel_squads(sel)
	var into: Squad = sqs[0]
	for sq in sqs:
		var a: int = (sq as Squad).able().size() * 2 + (1 if (sq as Squad).has_leader() else 0)
		var b: int = into.able().size() * 2 + (1 if into.has_leader() else 0)
		if a > b:
			into = sq
	var lead: Soldier = null
	for m in into.able():
		if lead == null or m.role == "leader":
			lead = m
	for sq in sqs:
		if sq == into:
			continue
		for m in (sq as Squad).able():
			(sq as Squad).members.erase(m)
			into.add(m)
			if lead != null and m.order in ["", "move"] and m.state in ["idle", "move"]:
				m.cmd_move(G.grid.nearest_free(lead.position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), Grid.M_INF))
	into.peak = maxi(into.peak, into.able().size())
	into.had_leader = into.had_leader or into.has_leader()
	return into

# Lideri ölen ya da 2 kişiye düşen tim dağılır: tedavi gereken yaralılar sahra hastanesine
# yürür, kalanlar yakındaki liderli dost time katılıp onun yanına gider.
func _reorganize() -> void:
	var ab := able()
	peak = maxi(peak, ab.size())
	var hl := has_leader()
	had_leader = had_leader or hl
	if ab.is_empty():
		return
	# dağılma: lideri vardı ve öldü/yaralandı, ya da 4+ kişilik tim 2 kişiye eridi
	if not ((had_leader and not hl) or (peak >= 4 and ab.size() <= 2)):
		return
	var hosp: Building = null
	var hd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == team and u.done and u.alive and u.btype == "hospital":
			var d: float = u.position.distance_to(ab[0].position)
			if d < hd and d < 160.0:
				hd = d
				hosp = u
	var best: Squad = null
	var bd := 70.0
	for sq in G.squads:
		if sq == self or sq.team != team or not sq.has_leader():
			continue
		var am: Array = sq.able()
		if am.is_empty() or am.size() + ab.size() > 12:
			continue
		var d: float = am[0].position.distance_to(ab[0].position)
		if d < bd:
			bd = d
			best = sq
	for m in ab:
		if m.order in ["hold", "board", "station"] or m.state in ["setup", "launch", "build", "aboard"] or m.vehicle_in != null:
			continue
		if m.order == "hospital":
			continue
		if hosp != null and m.injury != "" and m.injury_t < 0.0:
			m.cmd_hospital(hosp)
			continue
		if best == null:
			continue
		members.erase(m)
		best.add(m)
		var lead: Soldier = best.able()[0]
		for x in best.able():
			if x.role == "leader":
				lead = x
		if m.state == "idle" and m.order == "":
			m.cmd_move(G.grid.nearest_free(lead.position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), Grid.M_INF))
		m.say("%s'E KATILIYORUM" % best.name.to_upper() if I18n.lang == "tr" else "JOINING %s" % best.name.to_upper(), 2.5)

# ------------------------------------------------------------ tim beyni (taktik)
# Çatışmada: ilerleyen arkadaşlar için örtme ateşi; YZ timleri uzun çatışmada kanattan dolanır
# (taban kolu baskı ateşi açar, manevra kolu 70° yandan yaklaşıp saldırı hareketiyle bastırır),
# düşmanın tuttuğu binaya el bombası atıp baskın yapar.
var brain_t := 1.5
var engaged_t := 0.0
var flankers: Array = []
var flank_pt := Vector3.INF
var flank_t := 0.0
var flank_cd := 0.0
var assault_t := -1.0
var assault_house := -1
var last_threat := Vector3.INF

func _ai_side() -> bool:
	return G.spectate or team != G.player_team

func _brain(ab: Array) -> void:
	flank_cd -= 1.5
	# tehdit merkezi: son 6 sn içinde üyelerin gördüğü tehditler
	var tc := Vector3.ZERO
	var n := 0
	for m in ab:
		if G.time - m.threat_time < 6.0:
			tc += m.threat_pos
			n += 1
	if n == 0:
		engaged_t = maxf(0.0, engaged_t - 3.0)
		if flankers.is_empty():
			return
	else:
		tc /= n
		last_threat = tc
		engaged_t += 1.5
	var center := Vector3.ZERO
	for m in ab:
		center += m.position
	center /= ab.size()
	# 1) örtme ateşi: hareket eden arkadaş varken duranlar tehdit bölgesine ateş eder
	if n > 0:
		var moving := ab.filter(func(m): return m.state == "move" and m.order != "hold")
		if not moving.is_empty():
			for m in ab:
				if m.state == "idle" and m.ammo > 20 and m.role != "medic" and G.time > m.covering_until:
					m.covering_until = G.time + 4.0
	if not _ai_side():
		return
	# 2) kanat manevrası
	if not flankers.is_empty():
		flank_t += 1.5
		flankers = flankers.filter(func(m): return is_instance_valid(m) and m.alive and m.can_fight())
		var arrived := flankers.all(func(m): return m.dist2_p(flank_pt) < 4.0 or m.state == "idle")
		if flankers.is_empty() or flank_t > 30.0 or (arrived and flank_t > 6.0):
			for m in flankers:
				m.cmd_attack_move(last_threat)
				if randf() < 0.4:
					m.say("YANDAN VURUYORUZ!")
			flankers.clear()
			flank_pt = Vector3.INF
			flank_cd = 40.0
		return
	if n > 0 and engaged_t > 12.0 and flank_cd <= 0.0 and ab.size() >= 4 and center.distance_to(tc) > 14.0 and center.distance_to(tc) < 70.0:
		var to := tc - center
		to.y = 0.0
		var dist := to.length()
		var best := Vector3.INF
		var bs := -1e9
		for sg in [-1.0, 1.0]:
			var side := to.normalized().rotated(Vector3.UP, sg * 1.2)
			var p := G.grid.nearest_free(tc - side * dist * 0.75, Grid.M_INF, 6)
			var sc := -float(G.enemies_near(p, 25.0, team).size()) * 10.0 + G.grid.cover_factor(p, 1.0, tc) * 5.0
			if sc > bs:
				bs = sc
				best = p
		if best == Vector3.INF:
			return
		var cand := ab.filter(func(m): return m.role in ["rifle", "at", "engineer"] and m.order != "hold")
		if cand.size() < 2:
			return
		flankers = cand.slice(0, mini(3, cand.size() - (1 if ab.size() <= 4 else 0)))
		if flankers.size() < 2:
			flankers.clear()
			return
		flank_pt = best
		flank_t = 0.0
		for m in flankers:
			m.cmd_move(G.grid.nearest_free(best + Vector3(randf_range(-2, 2), 0, randf_range(-2, 2)), Grid.M_INF), true)
		flankers[0].say("KANATTAN DOLANIYORUZ!", 2.5)
		for m in ab:
			if not flankers.has(m) and m.role != "medic":
				m.cmd_suppress(tc)
		return
	# 3) düşmanın tuttuğu bina: el bombası, ardından baskın
	if n > 0 and assault_t < 0.0:
		for i in G.blocks.houses.size():
			var h: Dictionary = G.blocks.houses[i]
			if h["collapsed"]:
				continue
			var ht := G.blocks.house_team(i)
			if ht < 0 or ht == team or (h["center"] as Vector3).distance_to(tc) > 8.0 or center.distance_to(h["center"]) > 30.0:
				continue
			var thrown := 0
			for m in ab:
				if m.grenades > 0 and thrown < 2 and m.dist2_p(h["center"]) < 22.0:
					if m.cmd_throw(h["center"], false):
						thrown += 1
			if thrown > 0:
				assault_t = 0.0
				assault_house = i
				ab[0].say("BİNAYA BOMBA!", 2.0)
			break
	elif assault_t >= 0.0:
		assault_t += 1.5
		if assault_t > 4.0:
			var hc: Vector3 = G.blocks.houses[assault_house]["center"]
			for m in ab:
				if m.role != "medic" and m.dist2_p(hc) < 35.0:
					m.cmd_attack_move(hc)
			assault_t = -1.0

func update(dt: float) -> void:
	_merge_t -= dt
	if _merge_t <= 0.0 and team >= 0:
		_merge_t = 3.0
		_reorganize()
	brain_t -= dt
	if brain_t <= 0.0 and team >= 0:
		brain_t = 1.5
		var ab := able()
		if ab.size() >= 2:
			_brain(ab)
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.5
	for m in members:
		if not is_instance_valid(m) or not m.alive or m.state != "wounded" or m.rescuer != null:
			continue
		_assign_rescue(m)

func _assign_rescue(w: Soldier) -> void:
	var best: Soldier = null
	var bs := 1e9
	for c in G.friends_near(w.position, 40.0, team):
		if not (c is Soldier) or c == w or not c.can_fight():
			continue
		if c.patient != null or c.state in ["throw", "drag", "heal", "rescue", "build"]:
			continue
		if c.suppression > 65.0 or c.order == "hold" or c.retreating or c.bearer:
			continue
		var d: float = c.dist2(w)
		var sc := d
		if c.role == "medic":
			sc -= 18.0
		elif c.squad != self:
			sc += 10.0
			if d > 25.0:
				continue
		if c.selected and c.order == "move":
			sc += 20.0
		if sc < bs:
			bs = sc
			best = c
	if best == null:
		return
	best.start_rescue(w)
	# biri örtme ateşi açsın
	for c in G.friends_near(w.position, 30.0, team):
		if c is Soldier and c != best and c.can_fight() and c.state == "idle" and c.ammo > 30:
			c.covering_until = G.time + 9.0
			c.threat_time = maxf(c.threat_time, w.threat_time)
			if c.threat_time < G.time - 8.0:
				c.threat_pos = w.threat_pos
				c.threat_time = G.time
			c.say("ÖRTME ATEŞİ!")
			break
