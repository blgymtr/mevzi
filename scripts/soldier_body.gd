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
var j := {"py": HIP, "prx": 0.0, "prz": 0.0, "srx": 0.0, "sry": 0.0, "arx": 0.0, "arz": 0.0, "frx": 0.0, "alx": 0.0, "alz": 0.0, "flx": 0.0, "lrx": 0.0, "krx": 0.0, "llx": 0.0, "klx": 0.0, "lrz": 0.0, "llz": 0.0}
var wp_cur := Transform3D()
var phase := 0.0
var rng := RandomNumberGenerator.new()
var role := "rifle"
var dead_pose := {}

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
	_mi(spine, M["torso"])
	head = _mi(spine, M["head"])
	arm_r = _pivot(spine, Vector3(-0.21, 0.5, 0))
	_mi(arm_r, M["upper"])
	fore_r = _pivot(arm_r, Vector3(0, -0.29, 0))
	_mi(fore_r, M["fore"])
	arm_l = _pivot(spine, Vector3(0.21, 0.5, 0))
	_mi(arm_l, M["upper"])
	fore_l = _pivot(arm_l, Vector3(0, -0.29, 0))
	_mi(fore_l, M["fore"])
	leg_r = _pivot(pelvis, Vector3(-0.1, 0, 0))
	_mi(leg_r, M["thigh"])
	knee_r = _pivot(leg_r, Vector3(0, -0.44, 0))
	_mi(knee_r, M["shin"])
	leg_l = _pivot(pelvis, Vector3(0.1, 0, 0))
	_mi(leg_l, M["thigh"])
	knee_l = _pivot(leg_l, Vector3(0, -0.44, 0))
	_mi(knee_l, M["shin"])
	weapon = _mi(spine, M["weapon"])
	if M.has("extra") and M["extra"] != null:
		_mi(spine, M["extra"])
	phase = rng.randf() * TAU

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
	var wpn := {"mg": "mg", "at": "rpg"}.get(rl, "rifle")
	var M := {
		"torso": Art.skinned(model, "torso", team), "head": null,
		"upper": Art.skinned(model, "arm", team), "fore": Art.skinned(model, "fore", team),
		"thigh": Art.skinned(model, "thigh", team), "shin": Art.skinned(model, "shin", team),
		"weapon": Art.skinned(model, wpn, team), "extra": null,
	}
	if rl == "medic":
		M["extra"] = Art.skinned(model, "x_medic", team)
	elif rl == "at":
		M["extra"] = Art.skinned(model, "x_at", team)
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
	if rl == "at":
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
		"at":
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
		"stand", "aim", "run", "walk", "throw", "dragging", "surrender", "build", "dazed":
			var sw := clampf(speed / 3.5, 0.0, 1.0)
			T["py"] = HIP - absf(s) * 0.04 * sw - (0.05 if pose == "dragging" else 0.0)
			T["prx"] = 0.0
			T["srx"] = 0.12 * sw
			T["lrx"] = s * 0.75 * sw
			T["llx"] = -s * 0.75 * sw
			T["krx"] = -maxf(0.0, -c) * 1.0 * sw - 0.05
			T["klx"] = -maxf(0.0, c) * 1.0 * sw - 0.05
			T["arx"] = 0.55
			T["arz"] = 0.1
			T["frx"] = 1.2
			T["alx"] = 0.9
			T["alz"] = -0.3
			T["flx"] = 0.9
			wpn = 2
			if pose == "aim":
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
	var rate := clampf(dt * (14.0 if pose != "fly" else 30.0), 0.0, 1.0)
	for k in T:
		j[k] = lerpf(j[k], T[k], rate)
	for k in ["prz", "lrz", "llz", "sry"]:
		if not T.has(k):
			j[k] = lerpf(j[k], 0.0, rate)
	pelvis.position.y = j["py"]
	pelvis.rotation = Vector3(j["prx"], 0, j["prz"])
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

func _weapon_xf(w: int) -> Transform3D:
	match w:
		0:
			return Transform3D(Basis(Vector3.RIGHT, 0.6), Vector3(-0.16, 0.26, -0.16))
		1:
			if role == "at":
				return Transform3D(Basis(), Vector3(-0.14, 0.55, -0.1))
			return Transform3D(Basis(), Vector3(-0.1, 0.46, -0.22))
		2:
			if role == "at":
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
	return Transform3D()

func muzzle_pos() -> Vector3:
	return weapon.global_transform * Vector3(0, 0, -0.7 if role != "mg" else -0.9)
