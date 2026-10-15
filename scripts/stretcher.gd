class_name Stretcher extends RefCounted
# Sahra hastanesi sedye görevi: iki sedyeci yaralıya (ya da yeni ölmüş askere) koşar,
# sedyeye alır ve hastaneye taşır. Biri vurulursa diğeri sedyeyi tek başına sürükler.

var hosp: Building
var a: Soldier
var b: Soldier
var patient: Soldier
var stage := "go"
var node: MeshInstance3D
var t := 0.0
static var _mesh: Mesh

func _init(h: Building, s1: Soldier, s2: Soldier, p: Soldier) -> void:
	hosp = h
	a = s1
	b = s2
	patient = p
	for s in [a, b]:
		s.job = self
		s.state = "stretcher"
		s.force_move = true
		s.target = null
		s._set_path(p.position)
	if p.alive:
		p.rescuer = a

func alive_bearers() -> Array:
	var out: Array = []
	for s in [a, b]:
		if s != null and is_instance_valid(s) and s.alive and s.state == "stretcher" and s.job == self:
			out.append(s)
	return out

func alone() -> bool:
	return stage == "carry" and alive_bearers().size() == 1

func leader() -> Soldier:
	var al := alive_bearers()
	return al[0] if not al.is_empty() else null

func valid_patient() -> bool:
	if patient == null or not is_instance_valid(patient):
		return false
	if patient.alive:
		return patient.state in ["wounded", "dragged", "healing", "stretchered"]
	return G.time - patient.died_at < 150.0 or patient.carried

# true: görev sürüyor
func update(dt: float) -> bool:
	t += dt
	var al := alive_bearers()
	if al.is_empty() or not is_instance_valid(hosp) or not hosp.alive:
		_drop()
		return false
	match stage:
		"go":
			if not valid_patient() or t > 60.0:
				_finish()
				return false
			var ready := true
			for s in al:
				if s.dist2(patient) > 1.6:
					ready = false
					if s.path_i >= s.path.size():
						s._set_path(patient.position)
			if ready:
				_load()
		"carry":
			if patient == null or not is_instance_valid(patient):
				_finish()
				return false
			if t > 150.0:
				# hastane kapısına yol yok (yıkıntı, kuşatma): sonsuza dek dolaşma, yaralıyı bırak
				print("STUCK-RESOLVE Stretcher carry %.0f" % t)
				_drop()
				return false
			var L := leader()
			if L.path_i >= L.path.size() and L.dist2(hosp) > hosp.radius + 4.0:
				L._set_path(_door())
			_place_stretcher(al)
			if L.position.distance_to(_door()) < 3.0 or L.dist2(hosp) < hosp.radius + 3.0:
				hosp.admit(patient)
				patient = null
				_finish()
				return false
	return true

func _door() -> Vector3:
	return hosp.door_pos()

func _load() -> void:
	stage = "carry"
	t = 0.0
	if patient.alive:
		patient.state = "stretchered"
		patient.rescuer = a
		patient.path = PackedVector3Array()
	else:
		patient.carried = true
		patient.rag = null
		patient.body.reset_rig()
		patient.set_process(true)
	patient.body.dead_pose = {"arz": 0.15, "alz": -0.15, "lrz": 0.05, "llz": -0.05, "prz": 0.0, "srz": 0.0}
	node = MeshInstance3D.new()
	node.mesh = _stretcher_mesh()
	node.layers = 2
	G.world.add_child(node)
	var L := leader()
	L._set_path(_door())
	L.say("SEDYE!")

func _place_stretcher(al: Array) -> void:
	var L: Soldier = al[0]
	var dir := -L.vel
	dir.y = 0
	if dir.length() < 0.1:
		dir = (L.position - hosp.position)
		dir.y = 0
	dir = dir.normalized() if dir.length() > 0.01 else Vector3(0, 0, 1)
	var back: Vector3 = al[1].position if al.size() > 1 else L.position + dir * 2.2
	var front: Vector3 = L.position
	var mid := (front + back) * 0.5
	var h := 0.78 if al.size() > 1 else 0.4
	var fwd := front - back
	fwd.y = 0
	var yaw := atan2(fwd.x, fwd.z) if fwd.length() > 0.05 else 0.0
	var tilt := 0.0 if al.size() > 1 else -0.32
	node.global_transform = Transform3D(Basis(Vector3.UP, yaw) * Basis(Vector3.RIGHT, tilt), mid + Vector3(0, h, 0))
	patient.position = Vector3(mid.x, 0.0, mid.z)
	patient.rotation.y = yaw + PI
	patient.body.position = Vector3(0, h - 0.05, 0)

# takipçi: liderin 2 m arkası
func want_for(s: Soldier) -> Vector3:
	if stage == "go":
		return s._follow(Soldier.RUN_SPEED)
	var al := alive_bearers()
	if al.is_empty():
		return Vector3.ZERO
	var L: Soldier = al[0]
	if s == L:
		return s._follow(1.15 if al.size() == 1 else 1.9)
	var dir := L.vel
	dir.y = 0
	var tp := L.position - (dir.normalized() if dir.length() > 0.1 else (L.position - s.position).normalized()) * 2.0
	var d := tp - s.position
	d.y = 0
	var dl := d.length()
	if dl < 0.15:
		return Vector3.ZERO
	return d / dl * minf(dl * 3.0, 2.6)

func _drop() -> void:
	# taşıyan kalmadı: hasta yere bırakılır
	if patient != null and is_instance_valid(patient):
		patient.body.position = Vector3.ZERO
		if patient.alive and patient.state == "stretchered":
			patient.state = "wounded"
			patient.rescuer = null
		elif not patient.alive:
			patient.carried = false
	_finish()

func _finish() -> void:
	if node and is_instance_valid(node):
		node.queue_free()
	node = null
	for s in [a, b]:
		if s != null and is_instance_valid(s) and s.job == self:
			s.job = null
			if s.alive and s.state == "stretcher":
				s.state = "idle"
				s.force_move = false
				s.path = PackedVector3Array()
	if patient != null and is_instance_valid(patient) and patient.alive and patient.rescuer == a:
		patient.rescuer = null

static func _stretcher_mesh() -> Mesh:
	if _mesh:
		return _mesh
	var mb := MB.new()
	var cloth := Color(0.36, 0.38, 0.27)
	var pole := Color(0.22, 0.2, 0.17)
	mb.box(Vector3(0, 0, 0), Vector3(0.55, 0.04, 1.85), cloth)
	mb.box(Vector3(-0.3, 0.0, 0), Vector3(0.04, 0.04, 2.3), pole)
	mb.box(Vector3(0.3, 0.0, 0), Vector3(0.04, 0.04, 2.3), pole)
	_mesh = mb.commit(Mats.vc())
	return _mesh
