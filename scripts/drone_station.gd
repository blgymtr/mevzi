class_name DroneStation extends Node3D
# Drone operatörünün kurduğu yer kontrol istasyonu: kurulum ilerledikçe parçalar belirir
# (Pelican çanta + dizüstü, tripod anten direği, jeneratör, mancınık rampası). Bitince
# keşif İHA'sı rampadan fırlatılır, yüksek irtifada daire çizer (vurulması zor).
# İHA düşerse istasyon bekleme sonrası yenisini fırlatır; istasyon/operatör kaybedilirse bağ kopar.

const SETUP_TIME := 16.0
const RELAUNCH := 40.0

var team := 0
var operator = null          # Soldier
var progress := 0.0          # 0..1 kurulum
var done := false
var hp := 90.0
var alive := true
var uav = null               # Vehicle
var relaunch_t := 0.0
var launch_t := -1.0         # >= 0: rampada fırlatma geri sayımı
var parts: Array = []        # [düğüm, görünme eşiği]
var rail_yaw := 0.0
var _rail_uav: Node3D = null
var _screen: MeshInstance3D = null

static var all: Array = []

func _ready() -> void:
	all.append(self)
	rail_yaw = rotation.y
	_build_model()
	_apply_progress()

func _exit_tree() -> void:
	all.erase(self)

static func of_operator(s) -> DroneStation:
	for st in all:
		if is_instance_valid(st) and st.alive and st.operator == s:
			return st
	return null

# İstasyonun fırlattığı İHA: mancınıkla atılan küçük taktik keşif İHA'sı (ABD: RQ-7 sınıfı, Rusya: Orlan-10
# sınıfı), gerçek ölçekte. Eskiden temel "uav" tipi doğuyordu: o tipin kendi modeli olmadığından katalogdaki
# ilk keşif İHA'sı (ABD'de RQ-4 sınıfı, en büyüğü) 1,6 kat büyütülerek rampadan kalkıyordu.
static func uav_id(t: int) -> String:
	var nat: String = G.nation[t] if t >= 0 and t < G.nation.size() else ""
	var id := "rus_uav_orlan10" if nat == "rus" or (nat == "" and t == 1) else "usa_uav_rq7"
	return id if Art.has(id) else ""

# ------------------------------------------------------------ model
func _part(mesh: Mesh, at: float, mat: Material = null) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	if mat:
		mi.material_override = mat
	add_child(mi)
	parts.append([mi, at])
	return mi

func _build_model() -> void:
	var od := Color(0.27, 0.29, 0.2)
	var blk := Color(0.08, 0.08, 0.085)
	var steel := Color(0.42, 0.43, 0.44)
	# 1) Pelican çanta + açık kapak + dizüstü/kumanda (ilk kurulan)
	var mb := MB.new()
	mb.box(Vector3(0.0, 0.2, 0.0), Vector3(0.62, 0.4, 0.42), od)
	mb.box(Vector3(0.0, 0.42, 0.0), Vector3(0.64, 0.04, 0.44), od.darkened(0.15))
	mb.box(Vector3(0.0, 0.62, -0.2), Vector3(0.6, 0.4, 0.04), od, Basis(Vector3.RIGHT, -0.25))
	mb.box(Vector3(0.0, 0.46, 0.05), Vector3(0.46, 0.03, 0.3), blk)            # klavye/kumanda
	mb.cyl(Vector3(-0.18, 0.5, 0.12), 0.012, 0.012, 0.12, 4, blk)               # kumanda çubukları
	mb.cyl(Vector3(0.18, 0.5, 0.12), 0.012, 0.012, 0.12, 4, blk)
	mb.box(Vector3(0.36, 0.08, 0.0), Vector3(0.1, 0.16, 0.08), Color(0.6, 0.55, 0.2))   # akü
	var case_mi := _part(mb.commit(Mats.vcs()), 0.0)
	case_mi.position = Vector3(-0.9, 0.0, 0.7)
	_screen = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(0.5, 0.32)
	_screen.mesh = qm
	var sm := StandardMaterial3D.new()
	sm.albedo_color = Color(0.1, 0.3, 0.25)
	sm.emission_enabled = true
	sm.emission = Color(0.3, 0.9, 0.7)
	sm.emission_energy_multiplier = 1.2
	_screen.material_override = sm
	_screen.position = Vector3(0.0, 0.63, -0.17)
	_screen.rotation.x = -0.25
	case_mi.add_child(_screen)
	# 2) tripod anten direği (kurulumun %30'u)
	mb = MB.new()
	for i in 3:
		var a := TAU * i / 3.0
		mb.cyl_between(Vector3(cos(a) * 0.55, 0.0, sin(a) * 0.55), Vector3(0, 1.1, 0), 0.018, 0.015, 4, steel, false)
	mb.cyl_between(Vector3(0, 0.0, 0), Vector3(0, 3.1, 0), 0.03, 0.022, 6, steel, false)
	# yagi anten + panel
	mb.box(Vector3(0, 3.15, 0), Vector3(0.05, 0.05, 0.9), blk)
	for k in 6:
		mb.box(Vector3(0, 3.15, -0.4 + k * 0.16), Vector3(0.36 - k * 0.03, 0.012, 0.012), steel)
	mb.box(Vector3(0.0, 2.6, 0.06), Vector3(0.24, 0.32, 0.04), Color(0.82, 0.82, 0.78))
	mb.cyl(Vector3(0, 3.35, 0), 0.006, 0.006, 0.6, 3, blk)                      # kırbaç anten
	var mast := _part(mb.commit(Mats.vcs()), 0.3)
	mast.position = Vector3(-1.9, 0.0, -0.2)
	# kablo (çantadan direğe)
	mb = MB.new()
	mb.cyl_between(Vector3(-0.9, 0.04, 0.7), Vector3(-1.4, 0.03, 0.3), 0.012, 0.012, 3, blk, false)
	mb.cyl_between(Vector3(-1.4, 0.03, 0.3), Vector3(-1.9, 0.04, -0.2), 0.012, 0.012, 3, blk, false)
	_part(mb.commit(Mats.vcs()), 0.35)
	# 3) jeneratör
	mb = MB.new()
	mb.box(Vector3(0, 0.25, 0), Vector3(0.7, 0.45, 0.45), Color(0.62, 0.12, 0.08))
	mb.box(Vector3(0, 0.25, 0), Vector3(0.74, 0.5, 0.06), blk)
	mb.cyl(Vector3(0.0, 0.53, 0.0), 0.08, 0.08, 0.06, 8, blk)
	for k in 4:
		mb.box(Vector3(-0.2 + k * 0.13, 0.25, 0.23), Vector3(0.03, 0.3, 0.01), blk)
	var gen := _part(mb.commit(Mats.vcs()), 0.5)
	gen.position = Vector3(-0.6, 0.0, -1.3)
	# 4) mancınık rampası (pnömatik fırlatıcı): eğimli ray + A ayağı
	mb = MB.new()
	var L := 4.2
	var tilt := 0.2
	var b := Basis(Vector3.RIGHT, tilt)
	mb.box(b * Vector3(0, 0, 0) + Vector3(0, 0.75, 0), Vector3(0.18, 0.1, L), steel, b)
	mb.box(b * Vector3(0, 0.07, 0) + Vector3(0, 0.75, 0), Vector3(0.06, 0.05, L * 0.98), Color(0.25, 0.26, 0.27), b)
	mb.cyl_between(Vector3(-0.45, 0.0, 1.5), b * Vector3(0, 0, 1.4) + Vector3(0, 0.75, 0), 0.035, 0.03, 5, steel, false)
	mb.cyl_between(Vector3(0.45, 0.0, 1.5), b * Vector3(0, 0, 1.4) + Vector3(0, 0.75, 0), 0.035, 0.03, 5, steel, false)
	mb.cyl_between(Vector3(-0.35, 0.0, -1.9), b * Vector3(0, 0, -1.8) + Vector3(0, 0.75, 0), 0.03, 0.03, 5, steel, false)
	mb.cyl_between(Vector3(0.35, 0.0, -1.9), b * Vector3(0, 0, -1.8) + Vector3(0, 0.75, 0), 0.03, 0.03, 5, steel, false)
	mb.cyl(Vector3(0.25, 0.25, 1.9), 0.13, 0.13, 0.5, 10, Color(0.25, 0.3, 0.22))   # hava tankı
	var rail := _part(mb.commit(Mats.vcs()), 0.65)
	rail.position = Vector3(1.2, 0.0, 0.0)
	# rampada bekleyen İHA: fırlatılacak modelin kendisi (gerçek ölçek) — yoksa basit sabit kanatlı model
	var uid := uav_id(team)
	if uid != "":
		_rail_uav = _rail_model(uid)
		parts.append([_rail_uav, 0.85])
		add_child(_rail_uav)
		_rail_uav.position = Vector3(1.2, 0.9, 1.2)
		_rail_uav.rotation.x = tilt
		_build_net()
		return
	mb = MB.new()
	var grey := Color(0.55, 0.57, 0.56)
	mb.cyl(Vector3.ZERO, 0.09, 0.07, 1.3, 8, grey, Basis(Vector3.RIGHT, PI * 0.5))
	mb.sphere(Vector3(0, 0, -0.66), Vector3(0.09, 0.09, 0.14), 8, 5, grey)
	mb.box(Vector3(0, 0.04, -0.1), Vector3(2.6, 0.025, 0.24), grey)
	mb.box(Vector3(0.18, 0.12, 0.6), Vector3(0.36, 0.02, 0.16), grey, Basis(Vector3.FORWARD, 0.6))
	mb.box(Vector3(-0.18, 0.12, 0.6), Vector3(0.36, 0.02, 0.16), grey, Basis(Vector3.FORWARD, -0.6))
	mb.sphere(Vector3(0, -0.08, -0.45), Vector3(0.06, 0.05, 0.08), 6, 4, blk)        # kamera kubbesi
	mb.box(Vector3(0, 0, 0.7), Vector3(0.36, 0.03, 0.04), blk)
	_rail_uav = _part(mb.commit(Mats.vcs()), 0.85)
	_rail_uav.position = Vector3(1.2, 0.9, 1.2)
	_rail_uav.rotation.x = tilt
	_build_net()

# kamuflaj ağı (kurulumun son parçası)
func _build_net() -> void:
	var mb := MB.new()
	var net := Color(0.3, 0.33, 0.2)
	mb.quad(Vector3(-1.7, 1.25, 1.4), Vector3(0.0, 1.35, 1.4), Vector3(0.0, 1.35, -1.6), Vector3(-1.7, 1.2, -1.6), net, Vector3.UP)
	for c in [Vector3(-1.7, 0, 1.4), Vector3(0.0, 0, 1.4), Vector3(0.0, 0, -1.6), Vector3(-1.7, 0, -1.6)]:
		mb.cyl_between(c, c + Vector3(0, 1.3, 0), 0.02, 0.02, 4, Color(0.35, 0.28, 0.18), false)
	_part(mb.commit(Mats.vc2()), 0.95)

# katalog İHA modelinin gövde parçaları (rampada bekleyen, fırlatılacak olanın aynısı)
func _rail_model(id: String) -> Node3D:
	# kök: kurulum animasyonu ölçeği (_apply_progress) · iç düğüm: katalog gerçek boyut ölçeği
	var root := Node3D.new()
	var inner := Node3D.new()
	inner.scale = Vehicle.cat_scale(id)
	root.add_child(inner)
	var M := Art.vehicle_model(id, team)
	for hm in M.get("hulls", []):
		var mi := MeshInstance3D.new()
		mi.mesh = hm[0]
		mi.position = hm[1]
		inner.add_child(mi)
	return root

func _apply_progress() -> void:
	for p in parts:
		var mi: Node3D = p[0]
		var thr: float = p[1]
		mi.visible = progress >= thr
		if mi.visible and progress < thr + 0.12 and not done:
			# yeni kurulan parça yerden kalkar (direk dikilir)
			var k := clampf((progress - thr) / 0.12, 0.0, 1.0)
			mi.scale = Vector3(1.0, lerpf(0.25, 1.0, k), 1.0)
		else:
			mi.scale = Vector3.ONE
	if _rail_uav:
		_rail_uav.visible = progress >= 0.85 and (not done or launch_t >= 0.0)

func add_work(amount: float) -> void:
	if done or not alive:
		return
	progress = minf(1.0, progress + amount / SETUP_TIME)
	_apply_progress()
	if progress >= 1.0:
		done = true
		launch_t = 2.0
		if operator != null and is_instance_valid(operator):
			operator.say("İSTASYON HAZIR — İHA FIRLATILIYOR")

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not alive or not G.running:
		return
	if _screen:
		_screen.visible = done
	var op_ok: bool = operator != null and is_instance_valid(operator) and operator.alive and operator.can_fight()
	if done and not op_ok:
		_lose_link()
		return
	if not done:
		return
	if launch_t >= 0.0:
		launch_t -= dt
		if _rail_uav:
			# fırlatma: ray boyunca hızlanıp kalkar
			if launch_t < 0.6:
				var k := 1.0 - launch_t / 0.6
				_rail_uav.position = Vector3(1.2, 0.9, 1.2) + Basis(Vector3.RIGHT, 0.2) * Vector3(0, 0, -3.8 * k * k)
			if launch_t <= 0.0:
				_launch()
		return
	if uav == null or not is_instance_valid(uav) or not uav.alive:
		uav = null
		relaunch_t += dt
		if relaunch_t >= RELAUNCH:
			relaunch_t = 0.0
			launch_t = 2.0
			if _rail_uav:
				_rail_uav.position = Vector3(1.2, 0.9, 1.2)
				_rail_uav.visible = true
	elif uav.link_lost:
		uav = null

func _launch() -> void:
	launch_t = -1.0
	if _rail_uav:
		_rail_uav.visible = false
		_rail_uav.position = Vector3(1.2, 0.9, 1.2)
	var fwd := -global_transform.basis.z
	fwd.y = 0.0
	fwd = fwd.normalized()
	var p0 := global_position + global_transform.basis * Vector3(1.2, 0, -2.6)
	var uid := uav_id(team)
	var v: Vehicle = G.main.spawn_vehicle(team, uid if uid != "" else "uav", p0, rotation.y)
	v.station = self
	v.high_alt = true
	v.sight = 120.0
	v.hull.position.y = 1.6
	v.heading = rotation.y
	v.hvel = fwd * v.speed_max * 1.1
	v.dest = global_position + fwd * 30.0
	uav = v
	G.fx.exhaust(global_position + global_transform.basis * Vector3(1.2, 1.0, 1.6), 1.6)
	Sfx.play3d("rpg", global_position, -10.0)

func _lose_link() -> void:
	if uav != null and is_instance_valid(uav) and uav.alive and not uav.link_lost:
		uav.lose_link()
	uav = null

func take_blast(dmg: float) -> void:
	if not alive:
		return
	hp -= dmg
	if hp <= 0.0:
		destroy()

func destroy() -> void:
	if not alive:
		return
	alive = false
	_lose_link()
	G.fx.explosion(global_position + Vector3(0, 0.5, 0), 0.8, "rpg")
	for p in parts:
		var n: Node3D = p[0]
		for mi in ([n] if n is MeshInstance3D else n.find_children("*", "MeshInstance3D", true, false)):
			(mi as MeshInstance3D).material_override = Mats.burnt()
	var tw := create_tween()
	tw.tween_interval(25.0)
	tw.tween_callback(queue_free)
