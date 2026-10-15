class_name SoldierBody extends Node3D
# Prosedürel asker figürü ve kodla poz animasyonu. İleri yön: -Z.

const HIP := 0.92
static var _mesh := {}

var pelvis: Node3D
var spine: Node3D
var arm_r: Node3D
var arm_l: Node3D
var fore_r: Node3D
var fore_l: Node3D
var leg_r: Node3D
var leg_l: Node3D
var knee_r: Node3D
var knee_l: Node3D
var weapon: MeshInstance3D
var head: MeshInstance3D

# eklem durumları (anlık)
var j := {"py": HIP, "prx": 0.0, "prz": 0.0, "srx": 0.0, "sry": 0.0, "arx": 0.0, "arz": 0.0, "frx": 0.0, "alx": 0.0, "alz": 0.0, "flx": 0.0, "lrx": 0.0, "krx": 0.0, "llx": 0.0, "klx": 0.0, "lrz": 0.0, "llz": 0.0, "pry": 0.0}
var wp_cur := Transform3D()
var phase := 0.0
var move_yaw := 0.0     # hareket yönünün gövdeye göre açısı (kalça bu yöne döner, gövde hedefte kalır)
var rng := RandomNumberGenerator.new()
var role := "rifle"
var dead_pose := {}
var pistol := false

func build(team: int, rl: String, winter: bool) -> void:
	role = rl
	rng.randomize()
	var key := "%d_%s_%s" % [team, rl, G.map_kind]
	if not _mesh.has(key):
		_mesh[key] = _art_meshes(team, rl) if Art.has("soldier_blue") else _make_meshes(team, rl, winter)
	var M: Dictionary = _mesh[key]
	pelvis = Node3D.new()
	pelvis.position.y = HIP
	add_child(pelvis)
	spine = Node3D.new()
	pelvis.add_child(spine)
	var rig_model := "soldier_%s_rig" % ("usa" if team == 0 else "rus")
	var skinned := Art.has(rig_model)
	arm_r = _pivot(spine, Vector3(-0.21, 0.5, 0))
	fore_r = _pivot(arm_r, Vector3(0, -0.29, 0))
	arm_l = _pivot(spine, Vector3(0.21, 0.5, 0))
	fore_l = _pivot(arm_l, Vector3(0, -0.29, 0))
	leg_r = _pivot(pelvis, Vector3(-0.1, 0, 0))
	knee_r = _pivot(leg_r, Vector3(0, -0.44, 0))
	leg_l = _pivot(pelvis, Vector3(0.1, 0, 0))
	knee_l = _pivot(leg_l, Vector3(0, -0.44, 0))
	if skinned:
		_build_skin(rig_model, team)
	else:
		_mi(spine, M["torso"])
		head = _mi(spine, M["head"])
		_mi(arm_r, M["upper"])
		_mi(fore_r, M["fore"])
		_mi(arm_l, M["upper"])
		_mi(fore_l, M["fore"])
		_mi(leg_r, M["thigh"])
		_mi(knee_r, M["shin"])
		_mi(leg_l, M["thigh"])
		_mi(knee_l, M["shin"])
	weapon = _mi(spine, M["weapon"])
	if M.has("extra") and M["extra"] != null and not (skinned and rl in ["leader", "rifle"]):
		_mi(spine, M["extra"])
	phase = rng.randf() * TAU
	for n in [spine, arm_r, arm_l, fore_r, fore_l, leg_r, leg_l, knee_r, knee_l]:
		rest[n] = n.position

var rest := {}

# ------------------------------------------------------------ iskeletli (Blender) gövde
var skel: Skeleton3D = null
var bone_map: Array = []       # [kemik indeksi, pivot düğümü, dinlenme farkı D]
static var _rig_scenes := {}

func _build_skin(model: String, team: int) -> void:
	if not _rig_scenes.has(model):
		_rig_scenes[model] = load("res://assets/models/%s.glb" % model)
	var inst: Node3D = (_rig_scenes[model] as PackedScene).instantiate()
	add_child(inst)
	skel = _find_skel(inst)
	if skel == null:
		return
	for c in skel.get_children():
		if c is MeshInstance3D:
			var mi := c as MeshInstance3D
			mi.layers = 2
			for i in mi.mesh.get_surface_count():
				var sm := mi.mesh.surface_get_material(i)
				var nm := String(sm.resource_name) if sm else "uniform"
				mi.set_surface_override_material(i, Art.material(nm, team))
	var pv := {"pelvis": pelvis, "spine": spine, "arm_r": arm_r, "fore_r": fore_r, "arm_l": arm_l, "fore_l": fore_l, "leg_r": leg_r, "knee_r": knee_r, "leg_l": leg_l, "knee_l": knee_l}
	var S := _rel(skel)
	for i in skel.get_bone_count():
		var bn := skel.get_bone_name(i)
		if not pv.has(bn):
			continue
		var P_rest: Transform3D = S.affine_inverse() * _rel(pv[bn])
		var D := P_rest.affine_inverse() * skel.get_bone_global_rest(i)
		bone_map.append([i, pv[bn], D])

func _find_skel(n: Node) -> Skeleton3D:
	if n is Skeleton3D:
		return n
	for c in n.get_children():
		var r := _find_skel(c)
		if r:
			return r
	return null

# düğümün bu gövdeye göre dönüşümü (ağaçta olmasa da çalışır)
func _rel(n: Node3D) -> Transform3D:
	var t := n.transform
	var p := n.get_parent()
	while p != null and p != self and p is Node3D:
		t = (p as Node3D).transform * t
		p = p.get_parent()
	return t

# pivotlar (poz / ragdoll) → kemikler
func sync_skin() -> void:
	if skel == null:
		return
	var Si := _rel(skel).affine_inverse()
	for e in bone_map:
		skel.set_bone_global_pose(e[0], Si * _rel(e[1]) * e[2])

# ragdoll sonrası iskeleti kurulum konumlarına döndür
func reset_rig() -> void:
	pelvis.transform = Transform3D(Basis(), Vector3(0, HIP, 0))
	for n in rest:
		n.transform = Transform3D(Basis(), rest[n])
	wp_cur = Transform3D()

func _pivot(parent: Node3D, p: Vector3) -> Node3D:
	var n := Node3D.new()
	n.position = p
	parent.add_child(n)
	return n

func _mi(parent: Node3D, m: Mesh) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.layers = 2
	parent.add_child(mi)
	return mi

static func _art_meshes(team: int, rl: String) -> Dictionary:
	var model := "soldier_blue" if team == 0 else "soldier_red"
	var wpn: String = {"mg": "mg", "at": "rpg", "atgm": "rpg", "sniper": "sniper", "engineer": "smg", "crew": "smg", "mortar": "mortar", "drone": "tablet"}.get(rl, "rifle")
	# gövde parçaları Blender'dan (varsa), silahlar three.js üreticisinden
	var bm := model + "_body" if Art.has(model + "_body") else model
	var M := {
		"torso": Art.skinned(bm, "torso", team), "head": null,
		"upper": Art.skinned(bm, "arm", team), "fore": Art.skinned(bm, "fore", team),
		"thigh": Art.skinned(bm, "thigh", team), "shin": Art.skinned(bm, "shin", team),
		"weapon": Art.skinned(model, wpn, team), "extra": null,
	}
	if rl == "medic":
		M["extra"] = Art.skinned(model, "x_medic", team)
	elif rl in ["at", "atgm"]:
		M["extra"] = Art.skinned(model, "x_at", team)
	elif rl == "engineer":
		M["extra"] = Art.skinned(model, "x_eng", team)
	elif rl == "sniper":
		M["extra"] = Art.skinned(model, "x_sniper", team)
	elif rl == "mortar":
		M["extra"] = Art.skinned(model, "x_mortar", team)
	elif rl == "drone" or rl == "leader":
		M["extra"] = Art.skinned(model, "x_radio", team)
	return M

static func _make_meshes(team: int, rl: String, winter: bool) -> Dictionary:
	var uni := Color(0.33, 0.37, 0.22) if team == 0 else Color(0.43, 0.39, 0.26)
	if winter:
		uni = Color(0.62, 0.58, 0.46) if team == 0 else Color(0.5, 0.45, 0.33)
	var vest := uni.darkened(0.18) if team == 0 else Color(0.3, 0.3, 0.2)
	var skin := Color(0.74, 0.56, 0.42)
	var band: Color = G.TEAM_COL[team]
	var boot := Color(0.16, 0.13, 0.1)
	var gun := Color(0.12, 0.12, 0.12)
	var M := {}
	var mb := MB.new()
	# gövde (kalçadan omuza)
	mb.box(Vector3(0, 0.27, 0), Vector3(0.36, 0.56, 0.21), uni)
	mb.box(Vector3(0, 0.33, -0.02), Vector3(0.39, 0.34, 0.26), vest)
	mb.box(Vector3(0, 0.12, 0.13), Vector3(0.26, 0.24, 0.1), vest.darkened(0.15))
	mb.box(Vector3(0.0, 0.02, 0), Vector3(0.37, 0.12, 0.22), uni.darkened(0.1))
	# kol bandı rengi omuzda
	mb.box(Vector3(-0.2, 0.42, 0), Vector3(0.05, 0.08, 0.13), band)
	if rl == "medic":
		mb.box(Vector3(0, 0.36, 0.145), Vector3(0.16, 0.16, 0.02), Color(0.95, 0.95, 0.95))
		mb.box(Vector3(0, 0.36, 0.156), Vector3(0.1, 0.03, 0.01), Color(0.8, 0.1, 0.1))
		mb.box(Vector3(0, 0.36, 0.156), Vector3(0.03, 0.1, 0.01), Color(0.8, 0.1, 0.1))
	if rl in ["at", "atgm"]:
		mb.cyl(Vector3(0.1, 0.05, 0.16), 0.055, 0.055, 0.7, 6, Color(0.3, 0.32, 0.22), Basis(Vector3.FORWARD, 0.5))
	M["torso"] = mb.commit(Mats.vc())
	mb = MB.new()
	mb.box(Vector3(0, 0.6, 0), Vector3(0.1, 0.08, 0.1), skin)
	mb.sphere(Vector3(0, 0.73, 0), Vector3(0.105, 0.12, 0.11), 7, 5, skin)
	if team == 0:
		mb.sphere(Vector3(0, 0.765, 0.01), Vector3(0.14, 0.12, 0.15), 8, 6, uni.darkened(0.1), Basis(), true)
		mb.cyl(Vector3(0, 0.765, 0.01), 0.142, 0.142, 0.035, 8, band, Basis(), false)
	else:
		# kızıl bere / bandana
		mb.sphere(Vector3(0.0, 0.79, 0.0), Vector3(0.125, 0.07, 0.13), 8, 5, Color(0.72, 0.1, 0.08), Basis(), true)
		mb.box(Vector3(0.0, 0.775, 0.0), Vector3(0.23, 0.04, 0.22), Color(0.62, 0.08, 0.06))
	M["head"] = mb.commit(Mats.vc())
	mb = MB.new()
	mb.box(Vector3(0, -0.14, 0), Vector3(0.1, 0.3, 0.11), uni)
	M["upper"] = mb.commit(Mats.vc())
	mb = MB.new()
	mb.box(Vector3(0, -0.13, 0), Vector3(0.09, 0.27, 0.095), uni.darkened(0.05))
	mb.box(Vector3(0, -0.29, 0), Vector3(0.08, 0.08, 0.08), skin)
	M["fore"] = mb.commit(Mats.vc())
	mb = MB.new()
	mb.box(Vector3(0, -0.22, 0), Vector3(0.14, 0.45, 0.15), uni.darkened(0.06))
	M["thigh"] = mb.commit(Mats.vc())
	mb = MB.new()
	mb.box(Vector3(0, -0.2, 0), Vector3(0.12, 0.42, 0.13), uni.darkened(0.08))
	mb.box(Vector3(0, -0.43, -0.04), Vector3(0.13, 0.08, 0.24), boot)
	M["shin"] = mb.commit(Mats.vc())
	mb = MB.new()
	match rl:
		"mg":
			mb.box(Vector3(0, 0, -0.3), Vector3(0.08, 0.1, 0.95), gun)
			mb.box(Vector3(0, -0.07, -0.05), Vector3(0.1, 0.12, 0.14), Color(0.25, 0.27, 0.18))
			mb.cyl(Vector3(0, 0, -0.78), 0.02, 0.02, 0.25, 4, gun, Basis(Vector3.RIGHT, -PI * 0.5))
		"at", "atgm":
			mb.cyl(Vector3(0, 0, 0.35), 0.05, 0.05, 1.0, 7, Color(0.28, 0.3, 0.2), Basis(Vector3.RIGHT, -PI * 0.5))
			mb.cyl(Vector3(0, 0, -0.65), 0.07, 0.0, 0.25, 7, Color(0.3, 0.32, 0.24), Basis(Vector3.RIGHT, -PI * 0.5))
			mb.box(Vector3(0, -0.08, 0.0), Vector3(0.04, 0.12, 0.05), gun)
		_:
			mb.box(Vector3(0, 0, -0.22), Vector3(0.06, 0.08, 0.8), gun)
			mb.box(Vector3(0, -0.08, -0.25), Vector3(0.04, 0.12, 0.06), gun)
			mb.box(Vector3(0, -0.03, 0.12), Vector3(0.05, 0.1, 0.14), Color(0.3, 0.22, 0.14))
	M["weapon"] = mb.commit(Mats.vc())
	return M

# ------------------------------------------------------------ poz
# p: {pose, speed, aim, t, ...}
func animate(dt: float, pose: String, speed: float, extra := 0.0) -> void:
	var T := {}
	var wpn := 0
	var moving := speed > 0.15
	phase += dt * (speed * 2.6 + (0.0 if moving else 0.0))
	var s := sin(phase)
	var c := cos(phase)
	match pose:
		"stand", "aim", "run", "walk", "throw", "dragging", "surrender", "build", "dazed", "carry", "melee":
			var sw := clampf(speed / 3.5, 0.0, 1.0)
			var run := clampf((speed - 2.2) / 1.6, 0.0, 1.0)
			# yürüyüş/koşu: geniş adım, arkadaki bacakta güçlü diz bükümü, adım başına iniş-kalkış, gövde öne eğik
			T["py"] = HIP - absf(s) * (0.035 + 0.05 * run) * sw + absf(c) * 0.02 * run - (0.05 if pose == "dragging" else 0.0) - 0.04 * run
			T["prx"] = -0.06 * run
			T["prz"] = s * 0.04 * sw
			T["srx"] = 0.1 * sw + 0.22 * run
			T["sry"] = -s * 0.1 * sw
			T["lrx"] = s * (0.6 + 0.45 * run) * sw
			T["llx"] = -s * (0.6 + 0.45 * run) * sw
			T["krx"] = -(maxf(0.0, -c) * (0.9 + 0.8 * run) + 0.15 * run) * sw - 0.05
			T["klx"] = -(maxf(0.0, c) * (0.9 + 0.8 * run) + 0.15 * run) * sw - 0.05
			T["arx"] = 0.55
			T["arz"] = 0.1
			T["frx"] = 1.2
			T["alx"] = 0.9
			T["alz"] = -0.3
			T["flx"] = 0.9
			wpn = 2
			if pose == "aim" and moving:
				var sw3 := clampf(speed / 2.2, 0.0, 1.0)
				T["py"] = HIP - 0.07 - absf(s) * 0.015 * sw3
				T["lrx"] = 0.3 + s * 0.42 * sw3
				T["llx"] = 0.3 - s * 0.42 * sw3
				T["krx"] = -0.5 - maxf(0.0, -c) * 0.55 * sw3
				T["klx"] = -0.5 - maxf(0.0, c) * 0.55 * sw3
				T["prx"] = -0.22
				T["srx"] = 0.28
			if pose == "aim":
				if not moving:
					T["srx"] = 0.06
				T["arx"] = 1.35
				T["arz"] = 0.25
				T["frx"] = 0.25
				T["alx"] = 1.45
				T["alz"] = -0.45
				T["flx"] = 0.1
				wpn = 1
			elif pose == "throw":
				var k := clampf(extra, 0.0, 1.0)
				T["arx"] = lerpf(2.9, 0.9, k * k)
				T["frx"] = lerpf(0.8, 0.1, k)
				T["srx"] = lerpf(-0.25, 0.35, k)
				wpn = 0
			elif pose == "dragging":
				T["srx"] = 0.75
				T["arx"] = 1.0
				T["alx"] = 1.0
				T["frx"] = 0.2
				T["flx"] = 0.2
				T["arz"] = 0.0
				T["alz"] = 0.0
				T["krx"] = T["krx"] - 0.35
				T["klx"] = T["klx"] - 0.35
				T["py"] = HIP - 0.1
				wpn = 4
			elif pose == "surrender":
				T["arx"] = 3.0
				T["alx"] = 3.0
				T["arz"] = 0.25
				T["alz"] = -0.25
				T["frx"] = 0.3
				T["flx"] = 0.3
				wpn = 5
			elif pose == "build":
				T["py"] = 0.62
				T["lrx"] = 1.4
				T["krx"] = -1.45
				T["llx"] = -0.1
				T["klx"] = -1.6
				T["srx"] = 0.5
				T["arx"] = 1.2 + sin(phase * 3.0 + G.time * 9.0) * 0.5
				T["frx"] = 0.4
				T["alx"] = 0.8
				wpn = 4
			elif pose == "carry":
				# sedye: kollar aşağıda önde, tutamakları kavrar
				T["srx"] = 0.1
				T["arx"] = 0.35
				T["alx"] = 0.35
				T["arz"] = 0.12
				T["alz"] = -0.12
				T["frx"] = 0.45
				T["flx"] = 0.45
				wpn = 4
			elif pose == "melee":
				# dipçik darbesi: geri çek, ileri savur
				var k2 := clampf(extra, 0.0, 1.0)
				var sw2 := sin(k2 * PI)
				T["srx"] = lerpf(-0.2, 0.45, k2)
				T["sry"] = lerpf(0.6, -0.5, k2)
				T["arx"] = 1.4 + sw2 * 0.6
				T["alx"] = 1.6 + sw2 * 0.4
				T["frx"] = 0.6
				T["flx"] = 0.3
				T["lrx"] = 0.45
				T["llx"] = -0.35
				T["krx"] = -0.3
				wpn = 1
			elif pose == "dazed":
				T["prz"] = sin(G.time * 3.0) * 0.18
				T["srx"] = 0.3
				T["arx"] = 0.3
				T["alx"] = 0.4
				wpn = 0
			elif not moving:
				T["arx"] = 0.45
				T["frx"] = 1.0
				wpn = 2
		"flinch":
			# patlama yakınında: çömel, kollar başı korur
			T["py"] = 0.56
			T["prx"] = 0.0
			T["srx"] = 0.7
			T["lrx"] = 1.5
			T["krx"] = -1.6
			T["llx"] = 0.2
			T["klx"] = -1.7
			T["arx"] = 2.6
			T["arz"] = 0.6
			T["frx"] = 2.0
			T["alx"] = 2.6
			T["alz"] = -0.6
			T["flx"] = 2.0
			wpn = 4
		"vault":
			# alçak duvarın üstünden: bir el destek, bacaklar toplanmış
			T["py"] = 0.7
			T["prx"] = 0.2
			T["srx"] = 0.45
			T["lrx"] = 1.3
			T["krx"] = -1.8
			T["llx"] = 0.9
			T["klx"] = -1.2
			T["lrz"] = 0.3
			T["arx"] = 0.9
			T["arz"] = 0.2
			T["frx"] = 0.2
			T["alx"] = 0.5
			T["flx"] = 0.9
			wpn = 2
		"slide":
			# siper arkasına kayma: yana yatık, ayaklar önde
			T["py"] = 0.3
			T["prx"] = 0.95
			T["prz"] = 0.25
			T["srx"] = -0.35
			T["lrx"] = 1.2
			T["krx"] = -0.25
			T["llx"] = 0.9
			T["klx"] = -1.1
			T["arx"] = 0.4
			T["arz"] = 0.9
			T["frx"] = 0.3
			T["alx"] = 1.4
			T["flx"] = 1.1
			wpn = 2
		"blind", "blind_side":
			# kör ateş: çömelik, silah başın üstünden (duvar) veya yandan (köşe) uzatılmış
			T["py"] = 0.58
			T["lrx"] = 1.45
			T["krx"] = -1.5
			T["llx"] = -0.05
			T["klx"] = -1.62
			T["srx"] = 0.35
			if pose == "blind":
				T["arx"] = 2.55
				T["arz"] = 0.15
				T["frx"] = 0.35
				T["alx"] = 2.45
				T["alz"] = -0.2
				T["flx"] = 0.35
				wpn = 8
			else:
				T["sry"] = 0.5
				T["arx"] = 1.5
				T["arz"] = 0.9
				T["frx"] = 0.1
				T["alx"] = 1.4
				T["alz"] = 0.4
				T["flx"] = 0.2
				wpn = 9
		"crouch", "crouch_aim":
			T["py"] = 0.6
			T["prx"] = 0.0
			T["srx"] = 0.28
			T["lrx"] = 1.45
			T["krx"] = -1.5
			T["llx"] = -0.05
			T["klx"] = -1.62
			T["arx"] = 0.7
			T["arz"] = 0.1
			T["frx"] = 1.1
			T["alx"] = 1.0
			T["alz"] = -0.3
			T["flx"] = 0.8
			wpn = 2
			if moving:
				T["py"] = 0.68 - absf(s) * 0.04
				T["lrx"] = 0.7 + s * 0.6
				T["llx"] = 0.7 - s * 0.6
				T["krx"] = -1.2
				T["klx"] = -1.2
				T["srx"] = 0.45
			if pose == "crouch_aim":
				T["srx"] = 0.12
				T["arx"] = 1.35
				T["arz"] = 0.25
				T["frx"] = 0.25
				T["alx"] = 1.45
				T["alz"] = -0.45
				T["flx"] = 0.1
				wpn = 1
		"prone", "prone_aim", "crawl":
			T["py"] = 0.14
			T["prx"] = -PI * 0.5
			T["srx"] = -0.15
			var cs := sin(phase * 1.4) * (0.35 if moving else 0.0)
			T["lrx"] = -0.05 + cs
			T["llx"] = -0.05 - cs
			T["krx"] = -0.1 - maxf(0.0, cs) * 1.2
			T["klx"] = -0.1 - maxf(0.0, -cs) * 1.2
			T["lrz"] = 0.12
			T["llz"] = -0.12
			T["arx"] = 2.5 + cs * 0.3
			T["arz"] = 0.3
			T["frx"] = 0.8
			T["alx"] = 2.7 - cs * 0.3
			T["alz"] = -0.4
			T["flx"] = 0.4
			wpn = 3
		"dead", "wounded", "dragged", "healing":
			if dead_pose.is_empty():
				dead_pose = {"arz": rng.randf_range(0.4, 1.5), "alz": -rng.randf_range(0.4, 1.5), "lrz": rng.randf_range(0.0, 0.4), "llz": -rng.randf_range(0.0, 0.4), "prz": rng.randf_range(-0.3, 0.3), "srz": rng.randf_range(-0.2, 0.2)}
			T["py"] = 0.13
			T["prx"] = PI * 0.5
			T["prz"] = dead_pose["prz"]
			T["srx"] = 0.0
			T["arx"] = 0.2
			T["arz"] = dead_pose["arz"]
			T["frx"] = 0.3
			T["alx"] = 0.2
			T["alz"] = dead_pose["alz"]
			T["flx"] = 0.3
			T["lrx"] = 0.0
			T["llx"] = 0.0
			T["krx"] = 0.0
			T["klx"] = 0.0
			T["lrz"] = dead_pose["lrz"]
			T["llz"] = dead_pose["llz"]
			wpn = 6
			if pose == "wounded" or pose == "healing":
				var wr := sin(G.time * 2.2 + phase)
				T["lrx"] = 0.5 + wr * 0.25
				T["krx"] = -0.9 - wr * 0.3
				T["arx"] = 1.6 + sin(G.time * 1.7 + phase) * 0.6
				T["arz"] = 0.2
				T["frx"] = 1.4
				T["srx"] = 0.15
				T["prz"] = sin(G.time * 1.3) * 0.15
				wpn = 6
			elif pose == "dragged" and pistol:
				# sürüklenirken tabancayla ateş: sağ kol tehdide uzanır
				T["arx"] = 0.85
				T["arz"] = 0.05
				T["frx"] = 0.0
				T["alx"] = 2.9
				T["alz"] = -0.15
				T["flx"] = 0.1
				T["srx"] = -0.25
				T["lrx"] = 0.25
				T["krx"] = -0.5
				wpn = 7
			elif pose == "dragged":
				T["arx"] = 2.9
				T["alx"] = 2.9
				T["arz"] = 0.15
				T["alz"] = -0.15
				T["frx"] = 0.1
				T["flx"] = 0.1
				T["lrx"] = 0.25
				T["llx"] = 0.1
				T["krx"] = -0.5
				T["klx"] = -0.2
				wpn = 7
		"fly":
			T["py"] = 0.7
			T["prx"] = extra
			T["prz"] = extra * 0.6
			T["arx"] = 2.5
			T["alx"] = 2.2
			T["arz"] = 0.9
			T["alz"] = -0.9
			T["lrx"] = 0.6
			T["llx"] = -0.4
			T["krx"] = -0.6
			T["klx"] = -0.9
			wpn = 6
	if moving and pose in ["aim", "stand", "walk", "run", "crouch", "crouch_aim"]:
		var a := move_yaw
		var back := absf(a) > 1.9
		if back:
			a = wrapf(a - PI, -PI, PI)
			for lk in ["lrx", "llx"]:
				if T.has(lk):
					T[lk] = -T[lk] + (0.6 if pose == "aim" else 0.0)
		var py_ := clampf(a, -1.2, 1.2)
		T["pry"] = py_
		T["sry"] = float(T.get("sry", 0.0)) - py_
	else:
		T["pry"] = 0.0
	var rate := clampf(dt * (14.0 if pose != "fly" else 30.0), 0.0, 1.0)
	for k in T:
		j[k] = lerpf(j[k], T[k], rate)
	for k in ["prz", "lrz", "llz", "sry"]:
		if not T.has(k):
			j[k] = lerpf(j[k], 0.0, rate)
	pelvis.position.y = j["py"]
	pelvis.rotation = Vector3(j["prx"], j["pry"], j["prz"])
	spine.rotation = Vector3(j["srx"], j["sry"], 0)
	arm_r.rotation = Vector3(j["arx"], 0, j["arz"])
	fore_r.rotation = Vector3(j["frx"], 0, 0)
	arm_l.rotation = Vector3(j["alx"], 0, j["alz"])
	fore_l.rotation = Vector3(j["flx"], 0, 0)
	leg_r.rotation = Vector3(j["lrx"], 0, j["lrz"])
	knee_r.rotation = Vector3(j["krx"], 0, 0)
	leg_l.rotation = Vector3(j["llx"], 0, j["llz"])
	knee_l.rotation = Vector3(j["klx"], 0, 0)
	var wt := _weapon_xf(wpn)
	wp_cur = wp_cur.interpolate_with(wt, rate)
	weapon.transform = wp_cur
	sync_skin()

func _weapon_xf(w: int) -> Transform3D:
	match w:
		0:
			return Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(-0.16, 0.26, -0.16))
		1:
			if role in ["at", "atgm"]:
				return Transform3D(Basis(), Vector3(-0.14, 0.55, -0.1))
			return Transform3D(Basis(), Vector3(-0.1, 0.46, -0.22))
		2:
			if role in ["at", "atgm"]:
				return Transform3D(Basis(Vector3.FORWARD, 0.8) * Basis(Vector3.RIGHT, -1.2), Vector3(0.0, 0.3, 0.2))
			return Transform3D(Basis(Vector3.UP, 0.35) * Basis(Vector3.RIGHT, -0.35) * Basis(Vector3.FORWARD, 0.7), Vector3(-0.02, 0.3, -0.2))
		3:
			return Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.08, 0.7, 0.14))
		4:
			return Transform3D(Basis(Vector3.FORWARD, 0.9) * Basis(Vector3.RIGHT, -1.3), Vector3(0.0, 0.32, 0.17))
		5:
			return Transform3D(Basis(Vector3.RIGHT, 1.2), Vector3(0.6, -0.9, -0.4))
		6:
			return Transform3D(Basis(Vector3.UP, 1.2) * Basis(Vector3.RIGHT, PI * 0.5), Vector3(0.5, 0.25, 0.3))
		7:
			return Transform3D(Basis(Vector3.RIGHT, PI * 0.5), Vector3(-0.1, 0.3, 0.15))
		8:
			return Transform3D(Basis(Vector3.RIGHT, 0.15), Vector3(-0.05, 0.98, -0.3))
		9:
			return Transform3D(Basis(Vector3.UP, 0.6), Vector3(-0.55, 0.5, -0.35))
	return Transform3D()

func muzzle_pos() -> Vector3:
	return weapon.global_transform * Vector3(0, 0, -0.7 if role != "mg" else -0.9)
