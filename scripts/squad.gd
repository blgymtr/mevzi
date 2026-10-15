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

func update(dt: float) -> void:
	_merge_t -= dt
	if _merge_t <= 0.0 and team >= 0:
		_merge_t = 3.0
		_reorganize()
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
