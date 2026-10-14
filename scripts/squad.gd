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

func update(dt: float) -> void:
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
