class_name Paradrop extends Node3D
# Hava indirme: nakliye uçağı (ABD: C-130 tipi pervaneli, Rusya: Il-76 tipi jet) haritanın
# kenarından girer, atlama bölgesinin üstünden geçerken askerler arka rampadan iki sıra hâlinde atlar
# (statik hat → kubbe paraşüt açılır → süzülme → iniş yuvarlanması), uçak öbür kenardan çıkar.

const ALT := 42.0
const SPEED := 46.0
const GAP := 0.21 * SPEED      # ardışık iki atlayış arası uçuş mesafesi (m): rampadan iki sıra, her sıra 0,42 sn arayla
const DRIFT := 12.0            # statik hat serbest düşüşünde ileri savrulma (m): çıkış noktaları bu kadar geri alınır

var team := 0
var target := Vector3.ZERO
var roles: Array = []
var squad: Squad = null
var cost_share := 0.0
var dir := Vector3.FORWARD
var plane: Node3D
var props: Array = []
var jumped := 0
var ramp: MeshInstance3D = null
var ramp_open := 0.4
var ramp_k := 0.0
var door_l := Vector3.ZERO      # atlama kapısı (uçak yerel): rampa ağzı
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
	position = target - dir * minf(G.MAP * 0.9 + 60.0, 650.0)
	position.y = 0.0
	plane = Node3D.new()
	add_child(plane)
	plane.position.y = ALT
	plane.rotation.y = atan2(-dir.x, -dir.z)
	# (122) ayrıntılı model: tools/blender/veh/fam_plane.py → plane_<ulus>.glb (C-130 / Il-76 tipi): gövde, açılan
	# arka rampa, dönen pervaneler. Model yoksa eski yordamsal biçim
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	var VM: Dictionary = Art.vehicle_model("plane_%s" % ("rus" if nat == "rus" else "usa"), team)
	if not VM.is_empty():
		var md: Dictionary = VM.get("meta", {})
		door_l = Art.v3(md["door"]) if md.has("door") else Vector3(0, 1.2, 9.0)
		ramp_open = float(md.get("ramp_open", 0.4))
		for h in VM["hulls"]:
			var hm := MeshInstance3D.new()
			hm.mesh = h[0]
			hm.position = h[1]
			plane.add_child(hm)
		if VM.get("ramp") != null:
			ramp = MeshInstance3D.new()
			ramp.mesh = VM["ramp"]
			ramp.position = VM["ramp_pos"]
			plane.add_child(ramp)
		for p in VM.get("props", []):
			var pm := MeshInstance3D.new()
			pm.mesh = p[0]
			pm.position = p[1]
			plane.add_child(pm)
			props.append(pm)
		# model tabanı yerde (z=0): gövde ekseni ~3 m yukarıda; uçuş irtifası gövde eksenine göre
		plane.position.y = ALT - 3.0
	else:
		var mi := MeshInstance3D.new()
		mi.mesh = _plane_mesh(team)
		plane.add_child(mi)
		door_l = Vector3(0, -1.6, (30.0 if team == 0 else 44.0) * 0.36)
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
		# yeni modelde pervane ekseni Godot -Z (Blender +Y): kendi Z ekseni etrafında; eski disk Y etrafında
		if ramp != null or door_l.y > 0.0:
			pr.rotation.z += dt * 40.0
		else:
			pr.rotation.y += dt * 40.0
	# arka rampa: atlama bölgesine ~450 m kala açılır, son asker atlayınca kapanır
	var along0 := (position - target).dot(dir)
	var want := 1.0 if (along0 > _exit_along(0) - 450.0 and jumped < roles.size()) else 0.0
	ramp_k = move_toward(ramp_k, want, dt / 3.0)
	if ramp:
		ramp.rotation.x = ramp_k * ramp_open
	# atlama bölgesi: çıkış noktaları uçuş hattı boyunca hedefe ortalanmış, sabit aralıklı.
	# Kare süresinden bağımsız: yavaş bir karede birden çok nokta geçildiyse o askerler de
	# atlar, kapı konumu geçilen mesafe kadar geri alınır (eskiden aralık kare süresine
	# yuvarlanıyor, sıra hedefin çok ötesine — düşman mevzisinin üstüne — uzuyordu)
	var along := (position - target).dot(dir)
	while jumped < roles.size():
		var at := _exit_along(jumped)
		if along < at:
			break
		_jump(jumped, along - at)
		jumped += 1
	if along > minf(G.MAP * 0.9 + 80.0, 700.0):
		queue_free()

# i. askerin çıkış noktası (hedefe göre uçuş hattı üzerindeki mesafe)
func _exit_along(i: int) -> float:
	return (i - (roles.size() - 1) * 0.5) * GAP - DRIFT

func _jump(i: int, back := 0.0) -> void:
	var file := 0.7 if i % 2 == 0 else -0.7
	var door := plane.global_transform * (door_l + Vector3(file, 0, 0)) - dir * back
	var s: Soldier = G.main.spawn_soldier(team, roles[i], Vector3(door.x, 0, door.z), squad)
	s.cost_share = cost_share
	s.start_para(door, dir * SPEED * 0.35, target + Vector3((i % 3 - 1) * 2.5, 0, (i / 3) * 2.5))
	if i == 0:
		Sfx.play3d("smoke_pop", door, -6.0)
