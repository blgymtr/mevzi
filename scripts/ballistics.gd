class_name Ballistics extends Node3D
# Mermi dışı atışlar: tank mermisi, otomatik top, roket, el bombası, sis bombası.

class Proj:
	var kind := ""
	var pos := Vector3.ZERO
	var vel := Vector3.ZERO
	var team := 0
	var src = null
	var target = null
	var t := 0.0
	var life := 0.0
	var fuse := 0.0
	var node: Node3D = null
	var smoke := false
	var landed := false
	var trail := 0.0
	var aim := Vector3.ZERO

var projs: Array = []
var _gmesh: Mesh
var _rmesh: Mesh

func _ready() -> void:
	var mb := MB.new()
	mb.sphere(Vector3.ZERO, Vector3(0.07, 0.08, 0.07), 6, 4, Color(0.2, 0.24, 0.16))
	_gmesh = mb.commit(Mats.vc())
	var rb := MB.new()
	rb.cyl(Vector3(0, 0, 0.25), 0.045, 0.045, 0.5, 6, Color(0.3, 0.32, 0.22), Basis(Vector3.RIGHT, -PI * 0.5))
	rb.cyl(Vector3(0, 0, -0.25), 0.08, 0.0, 0.3, 6, Color(0.32, 0.33, 0.25), Basis(Vector3.RIGHT, -PI * 0.5))
	_rmesh = rb.commit(Mats.vc())

func _node(m: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.layers = 2
	add_child(mi)
	return mi

func shell(from: Vector3, to: Vector3, team: int, src, target, mode: String) -> void:
	var p := Proj.new()
	p.kind = mode
	p.pos = from
	var sp := 170.0 if mode == "ap" else (140.0 if mode == "he" else 110.0)
	var d := to - from
	var L := d.length()
	# hedefin biraz ötesine kadar uçar
	p.vel = d / maxf(L, 0.01) * sp
	p.life = (L + (3.0 if mode != "he" else 0.0)) / sp
	p.aim = to
	p.team = team
	p.src = src
	p.target = target
	projs.append(p)
	G.fx.tracer(from, from + p.vel * p.life, sp, Color(1.0, 0.8, 0.45) if mode != "auto" else Color(1.0, 0.6, 0.3), 0.16 if mode != "auto" else 0.1, 6.0 if mode != "auto" else 3.0)

func rocket(from: Vector3, to: Vector3, team: int, src, target) -> void:
	var p := Proj.new()
	p.kind = "rpg"
	p.pos = from
	var d := to - from
	var L := d.length()
	var err := L * 0.035
	p.aim = to + Vector3(randf_range(-err, err), randf_range(-0.25, 0.25), randf_range(-err, err))
	p.vel = (p.aim - from).normalized() * 48.0
	p.life = 70.0 / 48.0
	p.team = team
	p.src = src
	p.target = target
	p.node = _node(_rmesh)
	p.node.position = from
	projs.append(p)

func mortar(from: Vector3, to: Vector3, team: int, src) -> void:
	_lob(from, to, team, src, "mortar", 2.2 + from.distance_to(to) * 0.02)

func artillery(from: Vector3, to: Vector3, team: int, src) -> void:
	_lob(from, to, team, src, "arty", 2.5 + from.distance_to(to) * 0.025)

func _lob(from: Vector3, to: Vector3, team: int, src, kind: String, T: float) -> void:
	var p := Proj.new()
	p.kind = kind
	p.pos = from
	var g := Vector3(0, -9.8, 0)
	p.vel = (to - from - 0.5 * g * T * T) / T
	p.team = team
	p.src = src
	p.life = T + 0.5
	p.aim = to
	p.node = _node(_gmesh)
	p.node.scale = Vector3(1.6, 2.2, 1.6)
	p.node.position = from
	projs.append(p)

func _step_lob(p: Proj, dt: float) -> bool:
	p.t += dt
	p.vel.y -= 9.8 * dt
	var np := p.pos + p.vel * dt
	p.trail -= dt
	if p.trail <= 0.0:
		p.trail = 0.05
		G.fx.emit(Fx.P_SMOKE, p.pos, Vector3.ZERO, 0.6, 0.15, 0.4, 0.0, 1.0, Color(0.8, 0.8, 0.78, 0.35))
	# düşüş ıslığı
	if p.vel.y < 0.0 and not p.landed and np.y < 18.0:
		p.landed = true
		Sfx.play3d("incoming", p.aim, -2.0, 0.1, 0.1)
	var hit := np.y <= 0.0 or (np.y < 6.0 and G.grid.height_at(np) > np.y)
	p.pos = np
	p.node.position = np
	if hit or p.t > p.life:
		var at := Vector3(np.x, maxf(np.y, 0.0), np.z)
		if p.kind == "mortar":
			G.explode(at, 4.0, 110.0, "shell", p.team, p.src)
		else:
			G.explode(at, 6.0, 180.0, "big", p.team, p.src)
		return true
	return false

func grenade(from: Vector3, to: Vector3, team: int, src, smoke := false) -> void:
	var p := Proj.new()
	p.kind = "grenade"
	p.smoke = smoke
	p.pos = from
	var L := Vector2(to.x - from.x, to.z - from.z).length()
	var T := 0.7 + L * 0.035
	var g := Vector3(0, -9.8, 0)
	p.vel = (to - from - 0.5 * g * T * T) / T
	p.fuse = 3.0 if not smoke else 2.2
	p.team = team
	p.src = src
	p.node = _node(_gmesh)
	p.node.position = from
	projs.append(p)
	Sfx.play3d("throw", from, -6.0)

func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	var i := projs.size() - 1
	while i >= 0:
		var p: Proj = projs[i]
		var done := false
		match p.kind:
			"ap", "he", "auto":
				done = _step_shell(p, dt)
			"rpg":
				done = _step_rocket(p, dt)
			"grenade":
				done = _step_grenade(p, dt)
			"mortar", "arty":
				done = _step_lob(p, dt)
		if done:
			if p.node:
				p.node.queue_free()
			projs.remove_at(i)
		i -= 1

func _seg_block(a: Vector3, b: Vector3) -> Vector3:
	# a→b doğrusunda engel varsa çarpma noktası, yoksa Vector3.INF
	var L := a.distance_to(b)
	var n := int(L / 0.4) + 1
	for s in range(1, n + 1):
		var q := a.lerp(b, float(s) / n)
		if q.y <= 0.0:
			return Vector3(q.x, 0.02, q.z)
		if G.grid.height_at(q) > q.y:
			return q
	return Vector3.INF

func _step_shell(p: Proj, dt: float) -> bool:
	var np := p.pos + p.vel * dt
	p.t += dt
	var tgt: Unit = p.target if p.target != null and is_instance_valid(p.target) else null
	# doğrudan isabet (araç/yapı gövdesi)
	if tgt != null and tgt.alive and not (tgt is Soldier):
		var tp := tgt.aim_point()
		var seg := np - p.pos
		var t := clampf((tp - p.pos).dot(seg) / maxf(seg.length_squared(), 1e-5), 0.0, 1.0)
		var closest := p.pos + seg * t
		if closest.distance_to(tp) < tgt.radius * 0.7:
			_shell_hit(p, closest, tgt)
			return true
	var hit := _seg_block(p.pos, np)
	if hit != Vector3.INF and p.t > 0.02:
		_shell_hit(p, hit, null)
		return true
	p.pos = np
	if p.t >= p.life:
		_shell_hit(p, p.pos, null)
		return true
	return false

func _shell_hit(p: Proj, at: Vector3, direct: Unit) -> void:
	match p.kind:
		"ap":
			if direct:
				direct.take_damage(230.0, p.src, "ap")
				G.fx.impact(at, "metal")
				G.fx.explosion(at, 0.8, "ap")
				Sfx.play3d("hit_metal", at, 3.0)
			else:
				G.explode(at, 2.5, 60.0, "shell", p.team, p.src)
		"he":
			if direct:
				direct.take_damage(140.0, p.src, "he")
			G.explode(at, 4.5, 130.0, "shell", p.team, p.src)
		"auto":
			if direct:
				direct.take_damage(32.0, p.src, "auto")
				G.fx.impact(at, "metal")
			G.explode(at, 1.7, 40.0, "auto", p.team, p.src)

func _step_rocket(p: Proj, dt: float) -> bool:
	p.t += dt
	var wob := Vector3(sin(p.t * 23.0), cos(p.t * 19.0), sin(p.t * 17.0)) * 0.6
	var np := p.pos + (p.vel + wob) * dt
	p.trail -= dt
	if p.trail <= 0.0:
		p.trail = 0.025
		G.fx.rocket_trail(p.pos)
	var tgt: Unit = p.target if p.target != null and is_instance_valid(p.target) else null
	if tgt != null and tgt.alive and not (tgt is Soldier):
		if np.distance_to(tgt.aim_point()) < tgt.radius * 0.85:
			tgt.take_damage(270.0, p.src, "rpg")
			G.fx.explosion(np, 1.1, "rpg")
			Sfx.play3d("expl_med", np, 2.0)
			G.fx.impact(np, "metal")
			for s in G.near(np, 4.0):
				if s is Soldier and s.alive:
					s.on_blast(np, 2.5, 50.0, s.position.distance_to(np), p.src)
			return true
	var hit := _seg_block(p.pos, np)
	if hit != Vector3.INF and p.t > 0.05:
		G.explode(hit, 3.0, 95.0, "rpg", p.team, p.src)
		return true
	p.pos = np
	p.node.position = np
	p.node.look_at(np + p.vel, Vector3.UP)
	if p.t >= p.life:
		G.explode(Vector3(p.pos.x, maxf(p.pos.y, 0.0), p.pos.z), 3.0, 95.0, "rpg", p.team, p.src)
		return true
	return false

func _step_grenade(p: Proj, dt: float) -> bool:
	p.t += dt
	p.fuse -= dt
	p.vel.y -= 9.8 * dt
	var np := p.pos + p.vel * dt
	# duvara çarpma
	if G.grid.height_at(np) > np.y and np.y > 0.05:
		p.vel.x *= -0.3
		p.vel.z *= -0.3
		np = p.pos + Vector3(p.vel.x, 0, p.vel.z) * dt
	if np.y <= 0.05:
		np.y = 0.05
		if p.vel.y < -1.5:
			p.vel.y = -p.vel.y * 0.3
			p.vel.x *= 0.45
			p.vel.z *= 0.45
		else:
			p.vel = Vector3(p.vel.x * (1.0 - dt * 5.0), 0, p.vel.z * (1.0 - dt * 5.0))
		if not p.landed:
			p.landed = true
			if not p.smoke:
				for s in G.near(np, 5.0):
					if s is Soldier and s.alive and s.team != p.team:
						if s.on_grenade(np, p.fuse, p.src):
							return true
					elif s is Soldier and s.alive and s.team == p.team and s.position.distance_to(np) < 3.0 and s != p.src:
						s.on_grenade(np, p.fuse, null)
	p.pos = np
	p.node.position = np
	p.node.rotation += Vector3(dt * 9.0, dt * 6.0, 0)
	if p.fuse <= 0.0:
		if p.smoke:
			G.fx.smoke_screen(p.pos, 18.0)
			G.add_smoke(p.pos, 4.5, 19.0)
			Sfx.play3d("smoke_pop", p.pos, -2.0)
		else:
			G.explode(p.pos, 4.2, 120.0, "grenade", p.team, p.src)
		return true
	return false
