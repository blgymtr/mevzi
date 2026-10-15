class_name Paradrop extends Node3D
# Hava indirme: nakliye uçağı (ABD: C-130 tipi pervaneli, Rusya: Il-76 tipi jet) haritanın
# kenarından girer, atlama bölgesinin üstünden geçerken askerler arka rampadan sırayla atlar
# (statik hat → kubbe paraşüt açılır → süzülme → iniş yuvarlanması), uçak öbür kenardan çıkar.

const ALT := 42.0
const SPEED := 46.0

var team := 0
var target := Vector3.ZERO
var roles: Array = []
var squad: Squad = null
var cost_share := 0.0
var dir := Vector3.FORWARD
var plane: Node3D
var props: Array = []
var jumped := 0
var _jt := 0.0
static var _plane_m := {}

static func launch(t: int, tgt: Vector3, unit_roles: Array, sq: Squad, share: float) -> void:
	var p := Paradrop.new()
	p.team = t
	p.target = tgt
	p.roles = unit_roles
	p.squad = sq
	p.cost_share = share
	G.main.world.add_child(p)

func _ready() -> void:
	# dost karargâh yönünden gelir
	var from: Vector3 = G.hq_pos[team] if G.hq_pos.size() > team else Vector3.ZERO
	dir = target - from
	dir.y = 0.0
	dir = dir.normalized() if dir.length() > 1.0 else Vector3(1, 0, 0)
	position = target - dir * (G.MAP * 0.9 + 60.0)
	position.y = 0.0
	plane = Node3D.new()
	add_child(plane)
	var mi := MeshInstance3D.new()
	mi.mesh = _plane_mesh(team)
	plane.add_child(mi)
	plane.position.y = ALT
	plane.rotation.y = atan2(-dir.x, -dir.z)
	# pervane diskleri / jet sesi
	if team == 0:
		for x in [-9.5, -4.6, 4.6, 9.5]:
			var pr := MeshInstance3D.new()
			var cm := CylinderMesh.new()
			cm.top_radius = 2.0
			cm.bottom_radius = 2.0
			cm.height = 0.02
			cm.radial_segments = 24
			pr.mesh = cm
			var pm := StandardMaterial3D.new()
			pm.albedo_color = Color(0.1, 0.1, 0.1, 0.22)
			pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
			pr.material_override = pm
			pr.rotation.x = PI * 0.5
			pr.position = Vector3(x, 1.45, -6.6)
			plane.add_child(pr)
			props.append(pr)
	Sfx.loop3d("heli", plane, 2.0)
	G.say(I18n.s("HAVA İNDİRME YOLDA"), target, team)

func _plane_mesh(t: int) -> Mesh:
	if _plane_m.has(t):
		return _plane_m[t]
	var mb := MB.new()
	var grey := Color(0.46, 0.49, 0.5) if t == 0 else Color(0.55, 0.6, 0.62)
	var dk := Color(0.2, 0.21, 0.22)
	var glass := Color(0.12, 0.16, 0.2)
	var X := Basis(Vector3.RIGHT, PI * 0.5)
	var L := 30.0 if t == 0 else 44.0
	var R := 2.2 if t == 0 else 2.6
	# gövde: burun → silindir → yukarı kalkık kuyruk konisi (rampa altta)
	mb.cyl(Vector3(0, 0, -L * 0.5 + 1.6), R * 0.55, R, 3.2, 16, grey, X)
	mb.sphere(Vector3(0, -0.2, -L * 0.5 - 0.1), Vector3(R * 0.55, R * 0.5, 1.4), 12, 6, grey)
	mb.cyl(Vector3(0, 0, -L * 0.05), R, R, L * 0.6, 16, grey, X)
	mb.cyl(Vector3(0, R * 0.45, L * 0.38), R, R * 0.35, L * 0.28, 16, grey, Basis(Vector3.RIGHT, PI * 0.5 - 0.12))
	# kokpit camları
	if t == 0:
		mb.box(Vector3(0, R * 0.55, -L * 0.5 + 1.0), Vector3(R * 1.0, 0.45, 0.9), glass, Basis(Vector3.RIGHT, -0.5))
	else:
		mb.box(Vector3(0, R * 0.55, -L * 0.5 + 1.4), Vector3(R * 1.0, 0.45, 0.9), glass, Basis(Vector3.RIGHT, -0.5))
		mb.sphere(Vector3(0, -0.6, -L * 0.5 - 0.6), Vector3(R * 0.42, R * 0.32, 0.8), 10, 5, glass)   # seyrüsefer camlı burun
	# omuz kanat (yüksek kanat) + kanat kökü kaporta
	var span := 40.0 if t == 0 else 50.0
	mb.hull(Vector3(0, R * 0.95, -L * 0.08), Vector2(span, 4.6), Vector2(span * 0.96, 4.2), 0.45, grey)
	mb.box(Vector3(0, R * 0.8, -L * 0.08), Vector3(3.2, 0.6, 6.0), grey.darkened(0.05))
	# motorlar
	if t == 0:
		for x in [-9.5, -4.6, 4.6, 9.5]:
			mb.cyl(Vector3(x, R * 0.7, -L * 0.08 - 2.0), 0.75, 0.6, 5.2, 12, grey, X)
			mb.sphere(Vector3(x, R * 0.7, -L * 0.08 - 4.7), Vector3(0.35, 0.35, 0.5), 8, 4, dk)
	else:
		for x in [-14.0, -7.5, 7.5, 14.0]:
			mb.cyl(Vector3(x, R * 0.2, -L * 0.08 - 2.0), 0.95, 0.85, 5.6, 14, grey, X)
			mb.cyl(Vector3(x, R * 0.2, -L * 0.08 - 4.85), 0.8, 0.8, 0.1, 14, dk, X)
			mb.box(Vector3(x, R * 0.7, -L * 0.08 - 1.5), Vector3(0.3, 1.0, 3.5), grey)       # pilon
	# kuyruk: dikey + yatay (Il-76'da T kuyruk)
	var tz := L * 0.5 - 1.5
	mb.box(Vector3(0, R + 3.0, tz), Vector3(0.4, 6.0, 4.8), grey, Basis(Vector3.RIGHT, -0.38))
	mb.box(Vector3(0, R + (6.2 if t == 1 else 1.2), tz + 1.0), Vector3(15.0 if t == 0 else 17.0, 0.3, 3.6), grey)
	# iniş takımı kaportası (sponson) + arka rampa çizgisi
	for sg in [-1.0, 1.0]:
		mb.box(Vector3(sg * (R + 0.2), -R * 0.55, -L * 0.05), Vector3(0.9, 1.4, 7.5), grey.darkened(0.08))
	mb.box(Vector3(0, -R * 0.7, L * 0.33), Vector3(R * 1.6, 0.06, 5.0), dk)
	# ulusal işaret yerine takım bandı
	mb.cyl(Vector3(0, 0, L * 0.18), R + 0.02, R + 0.02, 0.5, 16, G.TEAM_COL[t].darkened(0.3), X)
	var m := mb.commit(Mats.vcs())
	_plane_m[t] = m
	return m

func _process(dt: float) -> void:
	if not G.running:
		return
	position += dir * SPEED * dt
	for pr in props:
		pr.rotation.y += dt * 40.0
	# atlama bölgesi: hedefin ±(n*0.5*aralık) kadarında, 0.42 sn arayla
	var along := (position - target).dot(dir)
	var spread := roles.size() * 0.42 * SPEED * 0.5
	if jumped < roles.size() and along > -spread - 6.0:
		_jt -= dt
		if _jt <= 0.0:
			_jt = 0.42
			_jump(jumped)
			jumped += 1
	if along > G.MAP * 0.9 + 80.0:
		queue_free()

func _jump(i: int) -> void:
	var door := plane.global_transform * Vector3(0, -1.6, (30.0 if team == 0 else 44.0) * 0.36)
	var s: Soldier = G.main.spawn_soldier(team, roles[i], Vector3(door.x, 0, door.z), squad)
	s.cost_share = cost_share
	s.start_para(door, dir * SPEED * 0.35, target + Vector3((i % 3 - 1) * 2.5, 0, (i / 3) * 2.5))
	if i == 0:
		Sfx.play3d("smoke_pop", door, -6.0)
