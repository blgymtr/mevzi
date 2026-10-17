class_name SoldierBody extends Node3D
# Asker gövdesi (derili gerçekçi model ya da yedek segment gövde) ve kodla poz animasyonu. İleri yön: -Z,
# anatomik sağ +X (arm_r/leg_r +X'te).
# Pozlar (animate, _weapon_xf, IK) tarihsel olarak AYNA uzayında yazılıdır (sağ kol -X'te idi): uygulanırken
# X'e göre aynalanır — konum x → -x, Euler (x, y, z) → (x, -y, -z) (_mx/_mr/_mxf). Böylece asker sağ elle
# nişan alır ve tüm elle ayarlanmış poz sayıları geçerli kalır.

const HIP := 0.92
# iskelet ölçüleri (tools/anim/build_soldier.py ile aynı; MakeHuman 1,78 m erkek oranları)
const SH_X := 0.19        # omuz eklemi, gövde ekseninden
const SH_Y := 0.46        # omuz eklemi, kalça üstü (1,38 m)
const UPPER := 0.26       # omuz → dirsek
const LEG_X := 0.1
const THIGH := 0.40       # kalça → diz
const SHIN := 0.52        # diz → taban

static func _mx(v: Vector3) -> Vector3:
	return Vector3(-v.x, v.y, v.z)

static func _mxf(t: Transform3D) -> Transform3D:
	var M := Basis(Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, 0, 1))
	return Transform3D(M * t.basis * M, _mx(t.origin))
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
var pistol_k := 0.0              # 0 kılıfta, 1 çekili ve nişanda
var recoil := 0.0                # atış geri tepmesi (kick() ile, hızla söner)
var reload_k := -1.0             # şarjör değiştirme ilerlemesi 0..1 (Soldier her kare yazar; -1 yok)

func kick() -> void:
	recoil = minf(recoil + (0.55 if role == "mg" else (1.4 if role == "sniper" else 1.0)), 1.6)
var _pistol_mi: MeshInstance3D = null
static var _pistol_mesh: Mesh = null

# ulusa özel Blender silahı (tools/blender/weapons.py): ABD M4A1/M249/AT4/M110/M17, Rusya AK-12/PKP/RPG-7/SV-98/PL-15
static func _nation_weapon(wpn: String, team: int) -> ArrayMesh:
	var wm := "weapons_%s" % ("usa" if team == 0 else "rus")
	if not Art.has(wm):
		return null
	return Art.skinned(wm, wpn, team)

func _pistol_model() -> void:
	var nw := _nation_weapon("pistol", team_id)
	if nw != null:
		_pistol_mi = MeshInstance3D.new()
		_pistol_mi.mesh = nw
		fore_r.add_child(_pistol_mi)
		_pistol_mi.position = Vector3(0, -HAND_LEN, -0.02)
		_pistol_mi.rotation = Vector3(-PI * 0.5, 0, 0)
		return
	if _pistol_mesh == null:
		var mb := MB.new()
		var blk := Color(0.09, 0.09, 0.1)
		mb.box(Vector3(0, 0.035, -0.08), Vector3(0.032, 0.035, 0.19), blk)                 # sürgü
		mb.box(Vector3(0, 0.005, -0.07), Vector3(0.03, 0.03, 0.16), Color(0.16, 0.15, 0.13)) # gövde
		mb.box(Vector3(0, -0.045, 0.0), Vector3(0.03, 0.1, 0.045), Color(0.16, 0.15, 0.13), Basis(Vector3.RIGHT, -0.25))  # kabza
		mb.box(Vector3(0, -0.012, -0.035), Vector3(0.012, 0.025, 0.035), blk)               # tetik korkuluğu
		_pistol_mesh = mb.commit(Mats.vcs())
	_pistol_mi = MeshInstance3D.new()
	_pistol_mi.mesh = _pistol_mesh
	fore_r.add_child(_pistol_mi)
	# el kemiği ucunda; namlu önkolun -Y yönünde (kol uzanınca ileri bakar)
	_pistol_mi.position = Vector3(0, -HAND_LEN, -0.02)
	_pistol_mi.rotation = Vector3(-PI * 0.5, 0, 0)
	_pistol_mi.visible = false

var team_id := 0
func build(team: int, rl: String, winter: bool) -> void:
	role = rl
	team_id = team
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
	arm_r = _pivot(spine, Vector3(SH_X, SH_Y, 0))
	fore_r = _pivot(arm_r, Vector3(0, -UPPER, 0))
	arm_l = _pivot(spine, Vector3(-SH_X, SH_Y, 0))
	fore_l = _pivot(arm_l, Vector3(0, -UPPER, 0))
	leg_r = _pivot(pelvis, Vector3(LEG_X, 0, 0))
	knee_r = _pivot(leg_r, Vector3(0, -THIGH, 0))
	leg_l = _pivot(pelvis, Vector3(-LEG_X, 0, 0))
	knee_l = _pivot(leg_l, Vector3(0, -THIGH, 0))
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
		rest[n] = _mx(n.position)     # poz (ayna) uzayında

var rest := {}

# ------------------------------------------------------------ yara görselleri
# arm: sol ön kolda alçı + boyun askısı (kol göğüste, silah tek elle) · leg: sağ uylukta kanlı sargı
# (topallama) · shoulder: sağ omuzda sargı · head: kask altından alna sarılı bandaj · torso: karın sargısı
var injury := ""
var limp := false
var _inj_nodes: Array = []
static var _inj_mesh := {}

func set_injury(kind: String) -> void:
	if kind == injury:
		return
	injury = kind
	for n in _inj_nodes:
		if is_instance_valid(n):
			n.queue_free()
	_inj_nodes.clear()
	if kind == "" or spine == null:
		return
	var gauze := Color(0.9, 0.88, 0.82)
	var blood := Color(0.42, 0.05, 0.04)
	var cast := Color(0.95, 0.94, 0.9)
	if not _inj_mesh.has(kind):
		var mb := MB.new()
		match kind:
			"arm":
				# alçı (ön kol + bilek), kenarında pamuk
				mb.cyl(Vector3(0, -0.16, 0), 0.058, 0.05, 0.26, 10, cast)
				mb.cyl(Vector3(0, -0.035, 0), 0.062, 0.062, 0.02, 10, gauze.darkened(0.08))
				mb.cyl(Vector3(0, -0.29, 0), 0.052, 0.052, 0.02, 10, gauze.darkened(0.08))
			"leg":
				mb.cyl(Vector3(0, -0.2, 0), 0.088, 0.085, 0.13, 10, gauze)
				mb.box(Vector3(0, -0.2, -0.082), Vector3(0.06, 0.07, 0.012), blood)
			"shoulder":
				mb.cyl(Vector3(0, -0.06, 0), 0.075, 0.072, 0.11, 10, gauze)
				mb.box(Vector3(0.03, -0.05, -0.07), Vector3(0.05, 0.05, 0.012), blood)
			"head":
				mb.cyl(Vector3(0, 0.0, 0), 0.094, 0.094, 0.045, 14, gauze)
				mb.box(Vector3(0.04, -0.005, -0.1), Vector3(0.045, 0.035, 0.02), blood.lightened(0.15))
			"torso":
				mb.cyl(Vector3(0, 0.0, 0), 0.19, 0.19, 0.09, 14, gauze)
				mb.box(Vector3(0.06, 0.0, -0.185), Vector3(0.07, 0.06, 0.015), blood)
		_inj_mesh[kind] = mb.commit(Mats.vcs())
		if kind == "arm":
			# üçgen kol askısı: boyundan göğse
			var sl := MB.new()
			# sol kol -X'te: askı boyunun sağından sol göğse iner (çift yüzlü)
			sl.quad(Vector3(0.12, 0.54, -0.08), Vector3(-0.14, 0.54, -0.06), Vector3(-0.1, 0.26, -0.17), Vector3(0.06, 0.28, -0.17), gauze.darkened(0.05), Vector3(0, 0, -1))
			sl.tri(Vector3(0.06, 0.28, -0.17), Vector3(-0.1, 0.26, -0.17), Vector3(-0.05, 0.2, -0.15), gauze.darkened(0.1), Vector3(0, 0, -1))
			_inj_mesh["sling"] = sl.commit(Mats.vc2())
	var mi := MeshInstance3D.new()
	mi.mesh = _inj_mesh[kind]
	match kind:
		"arm":
			fore_l.add_child(mi)
			var s2 := MeshInstance3D.new()
			s2.mesh = _inj_mesh["sling"]
			spine.add_child(s2)
			_inj_nodes.append(s2)
		"leg":
			leg_r.add_child(mi)
		"shoulder":
			arm_r.add_child(mi)
		"head":
			spine.add_child(mi)
			mi.position = Vector3(0, 0.765, -0.045)
			mi.scale = Vector3(1.0, 1.0, 1.18)
		"torso":
			spine.add_child(mi)
			mi.position = Vector3(0, 0.1, 0)
	_inj_nodes.append(mi)

# el aletleri: çekiç (sağ el), kutu (göğüs önü)
var _tool := ""
var _tool_mi: MeshInstance3D = null
static var _tool_mesh := {}

func set_tool(kind: String) -> void:
	if kind == _tool:
		return
	_tool = kind
	if _tool_mi:
		_tool_mi.queue_free()
		_tool_mi = null
	if kind == "" or fore_r == null:
		weapon.visible = true
		return
	if not _tool_mesh.has(kind):
		var mb := MB.new()
		if kind == "hammer":
			mb.box(Vector3(0, 0, -0.12), Vector3(0.028, 0.028, 0.32), Color(0.45, 0.32, 0.2))
			mb.box(Vector3(0, 0.0, -0.28), Vector3(0.04, 0.13, 0.045), Color(0.25, 0.25, 0.26))
		elif kind == "shell":
			# top mermisi: kovanlı, sarı tapalı (göğüs önünde iki elle)
			mb.cyl(Vector3(0, 0, 0), 0.07, 0.07, 0.5, 10, Color(0.75, 0.58, 0.24), Basis(Vector3.FORWARD, PI * 0.5))
			mb.cyl(Vector3(-0.35, 0, 0), 0.07, 0.0, 0.22, 10, Color(0.32, 0.35, 0.26), Basis(Vector3.FORWARD, PI * 0.5))
		elif kind == "shovel":
			# katlanır kürek (piyade kazma küreği): sap ellerde, ağız yere doğru
			mb.cyl(Vector3(0, -0.32, 0), 0.016, 0.016, 0.7, 6, Color(0.35, 0.3, 0.22))
			mb.box(Vector3(0, -0.72, -0.02), Vector3(0.17, 0.2, 0.012), Color(0.3, 0.32, 0.28))
			mb.box(Vector3(0, 0.04, 0), Vector3(0.1, 0.03, 0.03), Color(0.2, 0.2, 0.18))
		elif kind == "flag":
			# beyaz bayrak: el boyu sopa + beyaz bez (tişört / sargı bezi), sopanın ucunda yana sarkar
			mb.cyl(Vector3(0, -0.3, 0), 0.012, 0.01, 0.62, 6, Color(0.45, 0.32, 0.2))
			var wc := Color(0.93, 0.92, 0.88)
			mb.quad(Vector3(0, -0.6, 0), Vector3(0, -0.6, -0.34), Vector3(0.02, -0.36, -0.3), Vector3(0, -0.36, 0), wc, Vector3(1, 0, 0))
			mb.quad(Vector3(0, -0.36, 0), Vector3(0.02, -0.36, -0.3), Vector3(0, -0.6, -0.34), Vector3(0, -0.6, 0), wc.darkened(0.06), Vector3(-1, 0, 0))
		elif kind == "bandage":
			# sargı rulosu (sağ elde) + açık ilk yardım çantası (dizin yanında, yerde)
			mb.cyl(Vector3(0, 0, 0), 0.035, 0.035, 0.09, 8, Color(0.92, 0.9, 0.85), Basis(Vector3.FORWARD, PI * 0.5))
			mb.box(Vector3(0, 0.0, 0.05), Vector3(0.02, 0.01, 0.12), Color(0.9, 0.88, 0.82))
		elif kind == "rc":
			# drone kumandası: iki çubuklu verici + iki anten (iki elle göğüs önünde)
			mb.box(Vector3(0, 0, 0), Vector3(0.2, 0.035, 0.12), Color(0.16, 0.17, 0.16))
			mb.box(Vector3(0, 0.03, 0.02), Vector3(0.1, 0.012, 0.06), Color(0.2, 0.35, 0.45))
			for sx in [-1.0, 1.0]:
				mb.cyl(Vector3(sx * 0.06, 0.03, -0.02), 0.008, 0.008, 0.03, 6, Color(0.1, 0.1, 0.1))
				mb.cyl_between(Vector3(sx * 0.085, 0.01, 0.05), Vector3(sx * 0.11, 0.17, 0.08), 0.004, 0.003, 5, Color(0.08, 0.08, 0.08), false)
		elif kind == "drone":
			# FPV quad: X gövde, 4 motor + pervane, kamera, sırtında patlayıcı
			var dk := Color(0.12, 0.12, 0.13)
			mb.box(Vector3(0, 0, 0), Vector3(0.09, 0.035, 0.14), dk)
			for sx in [-1.0, 1.0]:
				for sz in [-1.0, 1.0]:
					var e := Vector3(sx * 0.13, 0.0, sz * 0.13)
					mb.cyl_between(Vector3.ZERO, e, 0.012, 0.012, 4, dk, false)
					mb.cyl(e + Vector3(0, 0.02, 0), 0.018, 0.018, 0.03, 6, Color(0.3, 0.3, 0.32))
					mb.cyl(e + Vector3(0, 0.04, 0), 0.075, 0.075, 0.004, 10, Color(0.2, 0.2, 0.22, 0.6))
			mb.box(Vector3(0, -0.03, -0.08), Vector3(0.03, 0.03, 0.03), Color(0.05, 0.05, 0.05))
			mb.cyl(Vector3(0, 0.045, 0.02), 0.03, 0.03, 0.14, 8, Color(0.3, 0.34, 0.22), Basis(Vector3.RIGHT, PI * 0.5))
		else:
			mb.box(Vector3(0, 0, 0), Vector3(0.5, 0.3, 0.36), Color(0.36, 0.38, 0.24))
			mb.box(Vector3(0, 0.155, 0), Vector3(0.42, 0.02, 0.08), Color(0.2, 0.2, 0.16))
			mb.box(Vector3(0.255, 0, 0), Vector3(0.02, 0.07, 0.22), Color(0.85, 0.75, 0.2))
		_tool_mesh[kind] = mb.commit(Mats.vcs())
	_tool_mi = MeshInstance3D.new()
	_tool_mi.mesh = _tool_mesh[kind]
	if kind == "hammer":
		fore_r.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, -HAND_LEN + 0.02, 0)
		_tool_mi.rotation.x = -0.4
	elif kind == "shovel":
		# sağ el sapın üst ucunda; sap ön kolun devamında aşağı-ileri
		fore_r.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, -HAND_LEN + 0.04, 0)
		_tool_mi.rotation.x = -0.35
		weapon.visible = true
	elif kind == "flag":
		fore_r.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, -HAND_LEN + 0.02, 0)
		weapon.visible = false
	elif kind == "bandage":
		fore_r.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, -HAND_LEN + 0.03, -0.03)
		weapon.visible = true
	elif kind == "shell":
		spine.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, 0.3, -0.3)
		weapon.visible = false
	elif kind == "rc":
		spine.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, 0.22, -0.3)
		_tool_mi.rotation.x = 0.5
		weapon.visible = false
	elif kind == "drone":
		# iki elle göğüs önünde tutulur; tüfek askıda
		spine.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, 0.3, -0.38)
		weapon.visible = false
	else:
		spine.add_child(_tool_mi)
		_tool_mi.position = Vector3(0, 0.22, -0.34)
		weapon.visible = true

# ------------------------------------------------------------ iskeletli (Blender) gövde
var skel: Skeleton3D = null
var bone_map: Array = []       # [kemik indeksi, pivot düğümü, dinlenme farkı D, pivot adı]
var severed := {}              # kopan uzuvlar (pivot adı): kemiği büzülür, segment örgüsü gizlenir

func sever(pn: String) -> void:
	severed[pn] = true
	var piv: Node3D = get(pn)
	if piv:
		for c in piv.get_children():
			if c is MeshInstance3D:
				(c as MeshInstance3D).visible = false
	sync_skin()
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
				# tek yüzeyli gerçekçi asker (kimlik UV2'de) ya da eski çok yüzeyli gövde
				mi.set_surface_override_material(i, Art.soldier_material(model, team) if nm == "soldier" else Art.material(nm, team))
	var pv := {"pelvis": pelvis, "spine": spine, "arm_r": arm_r, "fore_r": fore_r, "arm_l": arm_l, "fore_l": fore_l, "leg_r": leg_r, "knee_r": knee_r, "leg_l": leg_l, "knee_l": knee_l}
	var S := _rel(skel)
	for i in skel.get_bone_count():
		var bn := skel.get_bone_name(i)
		if not pv.has(bn):
			continue
		var P_rest: Transform3D = S.affine_inverse() * _rel(pv[bn])
		var D := P_rest.affine_inverse() * skel.get_bone_global_rest(i)
		bone_map.append([i, pv[bn], D, bn])

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
		var t: Transform3D = Si * _rel(e[1]) * e[2]
		if not severed.is_empty() and severed.has(e[3]):
			t.basis = t.basis.scaled(Vector3(0.02, 0.02, 0.02))
		skel.set_bone_global_pose(e[0], t)

# ragdoll sonrası iskeleti kurulum konumlarına döndür
func reset_rig() -> void:
	pelvis.transform = Transform3D(Basis(), Vector3(0, HIP, 0))
	for n in rest:
		n.transform = Transform3D(Basis(), _mx(rest[n]))
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
		"weapon": _nation_weapon(wpn, team) if _nation_weapon(wpn, team) != null else Art.skinned(model, wpn, team), "extra": null,
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
		"stand", "aim", "run", "walk", "throw", "dragging", "surrender", "build", "build_hi", "dazed", "carry", "melee":
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
				T["py"] = HIP - 0.045 - absf(s) * 0.015 * sw3
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
				T["py"] = HIP - 0.07
				wpn = 4
			elif pose == "surrender":
				T["arx"] = 3.0
				T["alx"] = 3.0
				T["arz"] = 0.25
				T["alz"] = -0.25
				T["frx"] = 0.3
				T["flx"] = 0.3
				wpn = 5
			elif pose == "build_hi":
				# ayakta, sol el kalası duvara bastırır, sağ el çekici baş hizasından savurur
				var sw2 := sin(phase * 3.0 + G.time * 8.0)
				T["py"] = HIP - 0.02
				T["srx"] = -0.06 + maxf(0.0, sw2) * 0.08
				T["lrz"] = 0.12
				T["llz"] = -0.12
				T["lrx"] = 0.05
				T["llx"] = -0.05
				T["krx"] = -0.08
				T["klx"] = -0.08
				T["arx"] = 2.25 + sw2 * 0.65
				T["arz"] = 0.18
				T["frx"] = 0.55 - sw2 * 0.35
				T["alx"] = 1.75
				T["alz"] = -0.2
				T["flx"] = 0.35
				wpn = 4
			elif pose == "build":
				T["py"] = 0.53
				T["lrx"] = 1.45
				T["krx"] = -1.47
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
				if extra > 1.5:
					# (111) top mermisi: bel hizasında, gövdenin önünde enine; iki el mermi uçlarının altından
					# kavrar, kollar aşağıda hafif bükük (eskiden kutu gibi göğse bastırılıyordu — "kucaklıyor")
					T["srx"] = 0.14
					T["arx"] = 0.5
					T["alx"] = 0.5
					T["arz"] = -0.12
					T["alz"] = 0.12
					T["frx"] = 0.75
					T["flx"] = 0.75
				elif extra > 0.5:
					# kutu: göğüs hizasında iki elle, dirsekler bükük, hafif geriye yaslanma
					T["srx"] = -0.05
					T["arx"] = 0.75
					T["alx"] = 0.75
					T["arz"] = 0.32
					T["alz"] = -0.32
					T["frx"] = 1.25
					T["flx"] = 1.25
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
		"dig":
			# kürekle kazma: ayaklar açık, dizler bükük; batır (gövde öne, kollar aşağı itme) → kaldır → yana at
			var w := fmod(G.time * 0.45 + phase * 0.16, 1.0)
			var push := smoothstep(0.0, 0.35, w) * (1.0 - smoothstep(0.45, 0.6, w))
			var throw_k := smoothstep(0.55, 0.8, w) * (1.0 - smoothstep(0.85, 1.0, w))
			T["py"] = HIP - 0.06 - push * 0.12
			T["lrx"] = 0.25 + push * 0.35
			T["krx"] = -0.25 - push * 0.55
			T["llx"] = -0.15
			T["klx"] = -0.2 - push * 0.3
			T["lrz"] = 0.1
			T["llz"] = -0.1
			T["srx"] = 0.3 + push * 0.45 - throw_k * 0.2
			T["sry"] = throw_k * 0.6
			T["arx"] = 0.55 + push * 0.35 + throw_k * 0.6
			T["arz"] = 0.15
			T["frx"] = 0.6 - push * 0.3
			T["alx"] = 0.95 + push * 0.4 + throw_k * 0.5
			T["alz"] = -0.25
			T["flx"] = 0.9
			wpn = 4
		"lift":
			# kutuyu yerden alma / yere bırakma: çömel, öne eğil, kollar aşağı
			var bend := sin(clampf(extra, 0.0, 1.0) * PI)
			T["py"] = HIP - 0.04 - bend * 0.36
			T["lrx"] = bend * 1.05
			T["llx"] = bend * 0.95
			T["krx"] = -bend * 1.7
			T["klx"] = -bend * 1.6
			T["srx"] = 0.12 + bend * 0.55
			T["arx"] = 0.45 + bend * 0.45
			T["alx"] = 0.45 + bend * 0.45
			T["arz"] = 0.3
			T["alz"] = -0.3
			T["frx"] = 1.2 - bend * 0.7
			T["flx"] = 1.2 - bend * 0.7
			wpn = 4
		"treat":
			# ilk yardım: yaralının yanında diz çöker, öne eğilir; iki el yaranın üstünde sırayla sargı sarar /
			# bastırır (turnike, basınçlı sargı)
			var tw := sin(G.time * 5.0 + phase)
			T["py"] = 0.53
			T["lrx"] = 1.45
			T["krx"] = -1.47
			T["llx"] = -0.1
			T["klx"] = -1.6
			T["srx"] = 0.75
			T["arx"] = 1.05 + tw * 0.18
			T["arz"] = 0.15
			T["frx"] = 0.75 - tw * 0.2
			T["alx"] = 0.95 - tw * 0.18
			T["alz"] = -0.2
			T["flx"] = 0.85 + tw * 0.2
			wpn = 4
		"flinch":
			# patlama yakınında: çömel, kollar başı korur
			T["py"] = 0.5
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
			T["py"] = 0.5
			T["lrx"] = 1.5
			T["krx"] = -1.52
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
		"cover", "lay", "ram", "drop":
			# top başında: çömelik taban (arka diz yerde)
			T["py"] = 0.5
			T["srx"] = 0.35
			T["lrx"] = 1.5
			T["krx"] = -1.52
			T["llx"] = -0.05
			T["klx"] = -1.62
			wpn = 4
			match pose:
				"cover":
					# atış anı: iki el kulakta, baş öne eğik
					T["srx"] = 0.6
					T["arx"] = 2.3
					T["arz"] = 0.75
					T["frx"] = 2.5
					T["alx"] = 2.3
					T["alz"] = -0.75
					T["flx"] = 2.5
				"lay":
					# nişancı: sağ el volanı döndürür, sol el nişangâha yakın
					var w := G.time * 4.0
					T["srx"] = 0.25
					T["arx"] = 1.25 + sin(w) * 0.25
					T["arz"] = 0.1 + cos(w) * 0.12
					T["frx"] = 0.7 + cos(w) * 0.25
					T["alx"] = 1.6
					T["alz"] = -0.3
					T["flx"] = 0.9
				"ram":
					# mermiyi kamaya sür: iki kol öne uzanır, gövde ileri itilir
					var k := clampf(extra, 0.0, 1.0)
					T["py"] = 0.52
					T["srx"] = 0.55 + k * 0.25
					T["arx"] = lerpf(1.0, 1.55, k)
					T["alx"] = lerpf(1.0, 1.55, k)
					T["arz"] = 0.05
					T["alz"] = -0.05
					T["frx"] = lerpf(1.2, 0.15, k)
					T["flx"] = lerpf(1.2, 0.15, k)
					T["lrx"] = 1.5
					T["llx"] = -0.3
				"drop":
					# havan: mermiyi namlu ağzına kaldır, bırak, eğil
					var k2 := clampf(extra, 0.0, 1.0)
					var q := maxf(0.0, k2 - 0.7) / 0.3
					T["py"] = lerpf(HIP - 0.05, 0.5, q)
					T["srx"] = lerpf(0.1, 0.7, maxf(0.0, k2 - 0.7) / 0.3)
					T["arx"] = lerpf(1.2, 2.2, minf(k2 / 0.6, 1.0))
					T["alx"] = lerpf(1.2, 2.2, minf(k2 / 0.6, 1.0))
					T["frx"] = 0.6
					T["flx"] = 0.6
					T["lrx"] = lerpf(0.1, 1.5, q)
					T["llx"] = lerpf(0.0, -0.05, q)
					T["krx"] = lerpf(-0.1, -1.52, q)
					T["klx"] = lerpf(-0.1, -1.62, q)
		"lanyard":
			# (101) obüs ateşleme ipi: topun yanında ayakta, gövde toptan yana dönük; sağ el ipi gergin tutar,
			# extra 0 → 1: ipi sertçe geri çeker (kol geri, gövde geri yaslanır, ağırlık arka ayağa)
			var k := clampf(extra, 0.0, 1.0)
			T["py"] = HIP - 0.04 - k * 0.04
			T["srx"] = 0.1 - k * 0.3
			T["lrx"] = 0.25
			T["llx"] = -0.2 - k * 0.15
			T["krx"] = -0.25
			T["klx"] = -0.1
			T["arx"] = lerpf(0.55, -0.45, k)
			T["arz"] = 0.18
			T["frx"] = lerpf(0.5, 0.25, k)
			T["alx"] = 0.25 + k * 0.3
			T["alz"] = -0.2
			T["flx"] = 0.6
			wpn = 4
		"sling", "unsling":
			# tüfeği sağ omuz üstünden sırta atma / sırttan alma (extra: 0..1 ilerleme)
			var k := clampf(extra, 0.0, 1.0)
			if pose == "unsling":
				k = 1.0 - k
			var reach := sin(k * PI)
			T["py"] = HIP - 0.03
			T["srx"] = 0.12 - reach * 0.1
			T["sry"] = reach * 0.25
			T["arx"] = lerpf(0.7, 2.7, reach)
			T["arz"] = lerpf(0.1, 0.35, reach)
			T["frx"] = lerpf(1.1, 1.7, reach)
			T["alx"] = lerpf(0.9, 0.3, k)
			T["alz"] = -0.25
			T["flx"] = lerpf(0.9, 0.4, k)
			T["lrx"] = 0.0
			T["llx"] = 0.0
			T["krx"] = -0.05
			T["klx"] = -0.05
			wpn = 4 if k > 0.55 else 2
		"para":
			# paraşütte asılı: eller askı kayışlarında (omuz üstü), bacaklar bitişik, dizler hafif bükük
			T["py"] = HIP
			T["srx"] = -0.05
			T["arx"] = 2.6
			T["arz"] = -0.25
			T["frx"] = 1.0
			T["alx"] = 2.6
			T["alz"] = 0.25
			T["flx"] = 1.0
			T["lrx"] = 0.25
			T["llx"] = 0.25
			T["krx"] = -0.35
			T["klx"] = -0.35
			wpn = 4
		"rope":
			# iki el başın üstünde halatta (el ele kayarak), bacaklar halata sarılı: sağ diz önde
			# bükük, sol ayak çaprazda halatı ayak üstüyle kilitler; kayarken gövde hafif geride
			var sl := clampf(speed / 5.0, 0.0, 1.0)
			var hw := sin(G.time * 9.0) * 0.06 * (1.0 - sl)
			T["py"] = HIP + 0.04
			T["prx"] = -0.08
			T["srx"] = -0.12 + sl * 0.05
			T["arx"] = 2.95 + hw
			T["arz"] = -0.12
			T["frx"] = 0.35 - hw
			T["alx"] = 2.8 - hw
			T["alz"] = 0.12
			T["flx"] = 0.45 + hw
			T["lrx"] = 0.55
			T["lrz"] = -0.12
			T["krx"] = -1.0
			T["llx"] = 0.25
			T["llz"] = 0.16
			T["klx"] = -0.55 - sl * 0.2
			wpn = 4
		"crouch", "crouch_aim":
			# diz çökme: kalça ve gövde öne, ağırlık öndeki dizin üstünde (srx tablo uzlaşımında: artı = öne, aşağıda
			# ters çevrilir; prx doğrudan: eksi = öne)
			T["py"] = 0.5
			T["prx"] = -0.1
			T["srx"] = 0.2
			T["lrx"] = 1.5
			T["krx"] = -1.52
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
				T["py"] = 0.75 - absf(s) * 0.04
				T["lrx"] = 0.7 + s * 0.6
				T["llx"] = 0.7 - s * 0.6
				T["krx"] = -1.2
				T["klx"] = -1.2
				T["srx"] = 0.45
			if pose == "crouch_aim":
				# nişanda gövde silaha doğru öne (omuz namlunun arkasında)
				T["prx"] = -0.08
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
			elif pose == "dragged" and pistol and false:
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
	# (74) yukarıdaki elle yazılmış poz tablosu "srx artı = gövde öne" varsayımıyla yazıldı; gerçekte X ekseni
	# çevresinde artı dönüş gövdeyi GERİ (+Z) yatırır — kulak kapatma, mermi sürme, ilk yardım, kazı, kaldırma,
	# irkilme, çömelme pozlarında asker geriye yatıyordu. Tek yerde ters çevrilir (mocap verisi doğru işaretli,
	# aşağıda eklenir).
	if T.has("srx"):
		T["srx"] = -float(T["srx"])
	# mocap yürüyüş: bacak, kalça ve gövde salınımı gerçek hareket verisinden (CMU, build_loco.py); kollar IK'da kalır
	var loco_pry := 0.0
	var loco := false
	if pose in ["aim", "stand", "walk", "run", "crouch", "crouch_aim", "surrender", "carry"] and injury != "leg" and _loco_ready():
		loco = true
		loco_pry = _loco_apply(T, dt, pose, speed, moving)
	if moving and pose in ["aim", "stand", "walk", "run", "crouch", "crouch_aim", "surrender"]:
		var a := -move_yaw      # ayna uzayı: uygulanırken yeniden işaret değiştirir
		var back := absf(a) > 1.9
		if back:
			a = wrapf(a - PI, -PI, PI)
			if not loco:
				for lk in ["lrx", "llx"]:
					if T.has(lk):
						T[lk] = -T[lk] + (0.6 if pose == "aim" else 0.0)
		var py_ := clampf(a, -1.2, 1.2)
		T["pry"] = py_ + loco_pry
		T["sry"] = float(T.get("sry", 0.0)) - py_
	else:
		T["pry"] = loco_pry
	# tabanca: sağ el önce kılıfa iner (k<0.45), sonra tabancayı nişana kaldırır; destek eli kavrar
	pistol_k = move_toward(pistol_k, 1.0 if pistol else 0.0, dt * 2.4)
	if pistol_k > 0.0 and fore_r and pose in ["stand", "walk", "run", "aim", "crouch", "crouch_aim", "dragged"]:
		if _pistol_mi == null:
			_pistol_model()
		var k := pistol_k
		if k < 0.45:
			var a := k / 0.45
			T["arx"] = lerpf(float(T.get("arx", 0.3)), -0.12, a)
			T["arz"] = lerpf(float(T.get("arz", 0.1)), 0.34, a)
			T["frx"] = lerpf(float(T.get("frx", 0.6)), 0.3, a)
		else:
			var b := smoothstep(0.45, 1.0, k)
			var up := 1.42 if pose != "dragged" else 0.85
			T["arx"] = lerpf(-0.12, up, b)
			T["arz"] = lerpf(0.34, 0.06, b)
			T["frx"] = lerpf(0.3, 0.06, b)
			if pose != "dragged":
				T["alx"] = lerpf(0.4, 1.32, b)
				T["alz"] = lerpf(-0.2, -0.62, b)
				T["flx"] = lerpf(0.4, 0.5, b)
		wpn = 4
		_pistol_mi.visible = k > 0.42
	elif _pistol_mi:
		_pistol_mi.visible = false
	# tanksavarcı, roketatar sırtta (taşıma, wpn 2): eller sırttaki tüpe uzanmaz (80: kollar gövdenin arkasında
	# kaybolup asker kolsuz görünüyordu) — sağ el göğüsteki kayışı tutar, sol kol yürüyüşle doğal sallanır
	var at_slung: bool = role in ["at", "atgm"] and wpn == 2 and not pistol and pistol_k <= 0.0
	if at_slung:
		var swing := -s * 0.38 * clampf(speed / 3.0, 0.0, 1.0)
		T["arx"] = 0.32
		T["arz"] = 0.14
		T["frx"] = 1.6
		T["alx"] = 0.12 + swing
		T["alz"] = -0.12
		T["flx"] = 0.35 + maxf(0.0, swing) * 0.6
	# nişan / taşıma / yüzüstü: eller silaha IK ile oturur
	if wpn in [1, 2, 3] and not at_slung and not pistol and pistol_k <= 0.0 and arm_r and rest.has(arm_r) and not (pose in ["sling", "unsling"]):
		var ik := _ik_pose(wpn)
		T["arx"] = ik[0].x
		T["arz"] = ik[0].y
		T["frx"] = ik[0].z
		T["alx"] = ik[1].x
		T["alz"] = ik[1].y
		T["flx"] = ik[1].z
	# şarjör değiştirme: sol el şarjör yuvası → yelekteki cep → yuvaya takar → el kundağı; tüfek sola yatar
	var reloading := reload_k >= 0.0 and wpn in [1, 2] and not pistol and pistol_k <= 0.0 and rest.has(arm_l) and not (role in ["at", "atgm", "mortar"]) and pose in ["stand", "aim", "walk", "run", "crouch", "crouch_aim"]
	if reloading:
		var hg := Vector3(float(T.get("alx", 1.4)), float(T.get("alz", -0.45)), float(T.get("flx", 0.2)))
		var mg := _ik_extra("mag", wpn)
		var pc := _ik_extra("pouch", wpn)
		var k := clampf(reload_k, 0.0, 1.0)
		var al := hg
		if k < 0.2:
			al = hg.lerp(mg, smoothstep(0.0, 0.2, k))
		elif k < 0.45:
			al = mg.lerp(pc, smoothstep(0.2, 0.45, k))
		elif k < 0.7:
			al = pc.lerp(mg, smoothstep(0.45, 0.7, k))
		elif k < 0.82:
			al = mg
		else:
			al = mg.lerp(hg, smoothstep(0.82, 1.0, k))
		T["alx"] = al.x
		T["alz"] = al.y
		T["flx"] = al.z
	# geri tepme: omuz geri itilir (namlu kalkışı silah dönüşünde)
	recoil = maxf(0.0, recoil - dt * 8.0)
	if recoil > 0.0 and wpn == 1:
		T["srx"] = float(T.get("srx", 0.0)) + 0.045 * recoil
	# kol alçıda: destek kolu askıda göğse katlı, silah yalnız sağ elde
	if injury == "arm" and pose in ["stand", "aim", "walk", "run", "crouch", "crouch_aim", "build", "build_hi", "carry", "throw"]:
		T["alx"] = 0.45
		T["alz"] = -0.55
		T["flx"] = 1.95
	# topallama: sağ bacak kilitli, o adımda kalça düşer ve gövde yana kayar
	if limp and moving and pose in ["stand", "aim", "walk", "run"]:
		T["krx"] = float(T.get("krx", 0.0)) * 0.25
		T["lrx"] = float(T.get("lrx", 0.0)) * 0.55
		var st := maxf(0.0, -s)
		T["py"] = float(T.get("py", HIP)) - st * 0.06
		T["prz"] = float(T.get("prz", 0.0)) + st * 0.1
		T["srx"] = float(T.get("srx", 0.0)) - 0.08
	var rate := clampf(dt * (14.0 if pose != "fly" else 30.0), 0.0, 1.0)
	for k in T:
		j[k] = lerpf(j[k], T[k], rate)
	for k in ["prz", "lrz", "llz", "sry"]:
		if not T.has(k):
			j[k] = lerpf(j[k], 0.0, rate)
	# ayna uzayından gerçek gövdeye: Euler (x, y, z) → (x, -y, -z)
	pelvis.position.y = j["py"]
	pelvis.rotation = Vector3(j["prx"], -j["pry"], -j["prz"])
	spine.rotation = Vector3(j["srx"], -j["sry"], 0)
	arm_r.rotation = Vector3(j["arx"], 0, -j["arz"])
	fore_r.rotation = Vector3(j["frx"], 0, 0)
	arm_l.rotation = Vector3(j["alx"], 0, -j["alz"])
	fore_l.rotation = Vector3(j["flx"], 0, 0)
	leg_r.rotation = Vector3(j["lrx"], 0, -j["lrz"])
	knee_r.rotation = Vector3(j["krx"], 0, 0)
	leg_l.rotation = Vector3(j["llx"], 0, -j["llz"])
	knee_l.rotation = Vector3(j["klx"], 0, 0)
	var wt := _weapon_xf(wpn)
	if reloading or (recoil > 0.0 and wpn == 1):
		# kabza (sağ el) çevresinde: şarjörde sola yatırma, atışta namlu kalkışı
		var g0: Vector3 = _grip_points()[0]
		var rb := Basis(Vector3.FORWARD, -0.55 * sin(clampf(reload_k, 0.0, 1.0) * PI)) if reloading else Basis()
		rb = Basis(Vector3.RIGHT, 0.06 * recoil) * rb
		wt = wt * Transform3D(Basis(), g0) * Transform3D(rb, Vector3(0, 0, 0.02 * recoil)) * Transform3D(Basis(), -g0)
	wp_cur = wp_cur.interpolate_with(wt, rate)
	weapon.transform = _mxf(wp_cur)
	_place_shell()
	sync_skin()

# (111) top mermisi iki avucun arasında: ekseni elden ele, merkezi ellerin ortası (her karede; poz ne olursa
# olsun eller mermiyi gerçekten tutar)
func _place_shell() -> void:
	if _tool != "shell" or _tool_mi == null or not _tool_mi.is_inside_tree() or fore_r == null or fore_l == null:
		return
	var hr: Vector3 = fore_r.global_transform * Vector3(0, -HAND_LEN, 0)
	var hl: Vector3 = fore_l.global_transform * Vector3(0, -HAND_LEN, 0)
	var ax := hl - hr
	if ax.length() < 0.05:
		return
	var x := ax.normalized()
	var up := Vector3.UP if absf(x.dot(Vector3.UP)) < 0.95 else Vector3.FORWARD
	var z := x.cross(up).normalized()
	var y := z.cross(x).normalized()
	# mermi biraz ellerin üstünde (eller alttan kavrar); kovanın tabanı sağ elde
	_tool_mi.global_transform = Transform3D(Basis(x, y, z), (hr + hl) * 0.5 + Vector3(0, 0.06, 0) - x * 0.08)

# ---------------- mocap yürüyüş verisi (assets/anim/loco.json)
static var _loco := {}
static var _loco_tried := false
const LOCO_CH := ["py", "prx", "pry", "prz", "srx", "sry", "lrx", "lrz", "krx", "llx", "llz", "klx"]
var loco_ph := 0.0           # yürüme döngüsü evresi (0..1)
var idle_ph := 0.0

static func _loco_ready() -> bool:
	if not _loco_tried:
		_loco_tried = true
		var f := FileAccess.open("res://assets/anim/loco.json", FileAccess.READ)
		if f:
			var js = JSON.parse_string(f.get_as_text())
			if js is Dictionary and js.has("clips"):
				for k in js["clips"]:
					var c: Dictionary = js["clips"][k]
					var rows: Array = c["data"]
					var d := PackedFloat32Array()
					for r in rows:
						for v in r:
							d.append(float(v))
					_loco[k] = {"n": rows.size() - 1, "ch": (rows[0] as Array).size(), "d": d, "len": float(c["length"]),
						"speed": float(c["speed"]), "ph0": float(c.get("ph0", 0.0))}
	return not _loco.is_empty()

static func _loco_sample(name: String, ph: float) -> PackedFloat32Array:
	var c: Dictionary = _loco[name]
	var n: int = c["n"]
	var ch: int = c["ch"]
	var x := fposmod(ph + float(c["ph0"]), 1.0) * n
	var i := mini(int(x), n - 1)
	var f := x - i
	var d: PackedFloat32Array = c["d"]
	var out := PackedFloat32Array()
	out.resize(ch)
	for k in ch:
		out[k] = lerpf(d[i * ch + k], d[(i + 1) * ch + k], f)
	return out

# yürüme / koşu / depar / geri / tetikte / çömelerek yürüyüş ve ayakta bekleme salınımı; kalça yalpasını döndürür
func _loco_apply(T: Dictionary, dt: float, pose: String, speed: float, moving: bool) -> float:
	if not moving:
		# ayakta bekleme: ağırlık aktarma ve nefes (yalnız kalça yüksekliği ve yan eğimleri, hafifçe)
		if not (pose in ["stand", "aim"]):
			return 0.0
		var ci: Dictionary = _loco["idle"]
		idle_ph = fposmod(idle_ph + dt / float(ci["len"]), 1.0)
		var I := _loco_sample("idle", idle_ph)
		T["py"] = float(T.get("py", HIP)) + (I[0] - HIP) * 0.6
		T["prz"] = float(T.get("prz", 0.0)) + I[3] * 0.6
		T["lrz"] = float(T.get("lrz", 0.0)) + I[7] * 0.6
		T["llz"] = float(T.get("llz", 0.0)) + I[10] * 0.6
		return I[2] * 0.4
	var back := absf(move_yaw) > 1.9
	var a := "walk"
	var b := "walk"
	var w := 0.0
	if pose in ["crouch", "crouch_aim"]:
		a = "crouch_walk"
		b = a
	elif back:
		# (126) geri geri koşu: hız arttıkça geri yürüyüş, tersten oynatılan koşu döngüsüne karışır
		a = "walk_back"
		b = a
		if speed > 1.8 and _loco.has("run"):
			b = "run"
			w = clampf((speed - 1.8) / 0.6, 0.0, 1.0)
	elif pose == "aim":
		# tetikte yürüyüş: dizler bükük, adımlar kısa, gövde nişanda sabit
		a = "crouch_walk"
		b = "walk"
		w = 0.55
	elif speed > 3.15:
		a = "run"
		b = "sprint"
		w = clampf((speed - 3.15) / 1.4, 0.0, 1.0)
	elif speed > 1.3:
		a = "walk"
		b = "run"
		w = clampf((speed - 1.3) / 1.85, 0.0, 1.0)
	var ca: Dictionary = _loco[a]
	var cb: Dictionary = _loco[b]
	# evre: bir döngüde alınan yol kadar ilerlendikçe tamamlanır (ayak kaymaz)
	var stride := lerpf(float(ca["len"]) * float(ca["speed"]), float(cb["len"]) * float(cb["speed"]), w)
	loco_ph = fposmod(loco_ph + dt * speed / maxf(stride, 0.25), 1.0)
	var A := _loco_sample(a, loco_ph)
	# geri koşuda koşu döngüsü tersten (1 − evre)
	var Bv := A if b == a else _loco_sample(b, (1.0 - loco_ph) if (back and b == "run") else loco_ph)
	var v := PackedFloat32Array()
	v.resize(A.size())
	for k in A.size():
		v[k] = lerpf(A[k], Bv[k], w)
	T["py"] = v[0]
	T["prx"] = v[1]
	T["prz"] = v[3]
	T["lrx"] = v[6]
	T["lrz"] = v[7]
	T["krx"] = v[8]
	T["llx"] = v[9]
	T["llz"] = v[10]
	T["klx"] = v[11]
	if not (pose in ["aim", "crouch_aim"]):
		# gövde öne eğilir, omuzlar kalçanın tersine döner (nişanda gövde hedefte sabit kalır)
		T["srx"] = float(T.get("srx", 0.0)) * 0.4 + v[4]
		T["sry"] = v[5]
	return v[2]

# ---------------- silah tutuşu: iki kemikli ters kinematik (önbellekli)
# Sağ el kabzaya, sol el el kundağına (RPG'de tüpün altına) oturur. Çözüm spine uzayında, poz başına bir kez.
static var _ik_cache := {}
const HAND_LEN := 0.33     # dirsek → avuç (kabza noktası)

func _hand_fk(ap: Vector3, fp: Vector3, rx: float, rz: float, fx: float) -> Vector3:
	var ba := Basis.from_euler(Vector3(rx, 0.0, rz))
	var bf := Basis.from_euler(Vector3(fx, 0.0, 0.0))
	return ap + ba * (fp + bf * Vector3(0, -HAND_LEN, 0))

func _solve_arm(ap: Vector3, fp: Vector3, target: Vector3, guess: Vector3, mirror: float) -> Vector3:
	var x := guess
	var best := (_hand_fk(ap, fp, x.x, x.y, x.z) - target).length_squared()
	var step := 0.4
	for it in 70:
		var improved := false
		for k in 3:
			for sgn in [-1.0, 1.0]:
				var y := x
				y[k] += step * sgn
				y.x = clampf(y.x, -1.2, 3.3)
				y.y = clampf(y.y * mirror, -0.6, 1.4) * mirror
				y.z = clampf(y.z, 0.0, 2.6)
				var e := (_hand_fk(ap, fp, y.x, y.y, y.z) - target).length_squared()
				if e < best:
					best = e
					x = y
					improved = true
		if not improved:
			step *= 0.55
			if step < 0.002:
				break
	return x

func _grip_points() -> Array:
	# silah mesh sınırlarından kabza ve el kundağı noktaları (silah yerel uzayı, ileri -Z)
	var a: AABB = weapon.mesh.get_aabb() if weapon and weapon.mesh else AABB(Vector3(-0.03, -0.08, -0.7), Vector3(0.06, 0.16, 1.0))
	var z0 := a.position.z
	var L := a.size.z
	var yc := a.position.y + a.size.y * 0.45
	if role in ["at", "atgm"]:
		return [Vector3(0, a.position.y - 0.02, z0 + L * 0.62), Vector3(0, a.position.y - 0.02, z0 + L * 0.38)]
	return [Vector3(0, yc - a.size.y * 0.25, z0 + L * 0.68), Vector3(0, yc, z0 + L * 0.33)]

func _ik_pose(w: int) -> Array:
	var key := "%s|%d" % [role, w]
	if _ik_cache.has(key):
		return _ik_cache[key]
	var wt := _weapon_xf(w)
	var g := _grip_points()
	var tr: Vector3 = wt * (g[0] as Vector3)
	var tl: Vector3 = wt * (g[1] as Vector3)
	var r := _solve_arm(rest[arm_r], rest[fore_r], tr, Vector3(1.3, 0.25, 0.4), 1.0)
	var l := _solve_arm(rest[arm_l], rest[fore_l], tl, Vector3(1.4, -0.45, 0.2), -1.0)
	var out := [r, l]
	_ik_cache[key] = out
	return out

# şarjör değiştirmede sol elin ek hedefleri (poz uzayı): tüfeğin şarjör yuvası ve yelekteki şarjör cebi
func _ik_extra(kind: String, w: int) -> Vector3:
	var key := "%s|%d|%s" % [role, w, kind]
	if _ik_cache.has(key):
		return _ik_cache[key]
	var tl := Vector3(0.03, 0.3, -0.23)
	var guess := Vector3(0.6, -0.2, 1.4)
	if kind == "mag":
		var a: AABB = weapon.mesh.get_aabb() if weapon and weapon.mesh else AABB(Vector3(-0.03, -0.08, -0.7), Vector3(0.06, 0.16, 1.0))
		tl = _weapon_xf(w) * Vector3(0, a.position.y + a.size.y * 0.12, a.position.z + a.size.z * 0.58)
		guess = Vector3(1.2, -0.4, 0.6)
	var r := _solve_arm(rest[arm_l], rest[fore_l], tl, guess, -1.0)
	_ik_cache[key] = r
	return r

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
			return Transform3D(Basis(Vector3.UP, -0.55) * Basis(Vector3.RIGHT, -0.62) * Basis(Vector3.FORWARD, -0.25), Vector3(-0.07, 0.33, -0.2))
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
