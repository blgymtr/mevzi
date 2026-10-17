class_name CamRig extends Node3D
# Ortografik izometrik kamera: kaydırma (WASD / kenar / orta tuş), yakınlaştırma, sarsıntı.
# Büyük haritada stratejik yakınlaştırma: görüş yüksekliği haritaya göre (8 km'de 2,4 km'ye kadar);
# kamera uzaklığı ve kırpma düzlemi görüşle büyür. Gölge mesafesi basamaklıdır (yakınlaştırırken sürekli
# değişen gölge mesafesi gölgeleri kaydırıp parlatıyordu, roadmap 41). Uzakta ot/çakıl gizlenir.

const PITCH := 40.0
const DIST := 120.0
const YAW0 := PI * 0.25
# (136) 360° döndürme: ',' / '.' 45° adım, Alt + orta tuşla sürükleme serbest bakış (yön + eğim);
# Boşluk seçili birime kilitlenir (yeniden basınca ya da elle kaydırınca çıkar); End varsayılan görünüm
var yaw := YAW0
var target_yaw := YAW0
var pitch := PITCH
var target_pitch := PITCH
var follow_unit: Node3D = null
var _look := false
var _look_from := Vector2.ZERO
var cam: Camera3D
var listener: AudioListener3D
var size := 40.0
var target_size := 40.0
var min_size := 10.0
var max_size := 115.0
var focus := Vector3(128, 0, 128)
var target_focus := Vector3(128, 0, 128)
var _shake := 0.0
var _drag := false
var _drag_from := Vector2.ZERO
var _drag_focus := Vector3.ZERO
var edge_scroll := true
var input_enabled := true
var auto_pan := false
var _auto_t := 0.0
var light: DirectionalLight3D

func _ready() -> void:
	cam = Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	cam.size = size
	cam.near = 1.0
	cam.far = 400.0
	add_child(cam)
	cam.current = true
	listener = AudioListener3D.new()
	add_child(listener)
	listener.make_current()
	_apply()

func right_vec() -> Vector3:
	return Vector3(cos(yaw), 0, -sin(yaw))

func up_vec() -> Vector3:
	return Vector3(-sin(yaw), 0, -cos(yaw))

func rotate_step(dir: float) -> void:
	target_yaw += dir * PI * 0.25

func reset_view() -> void:
	# en yakın 360° katına dön (bir tur geri dolanmasın)
	target_yaw = YAW0 + round((target_yaw - YAW0) / TAU) * TAU
	target_pitch = PITCH

func toggle_follow(u: Node3D) -> void:
	if follow_unit != null or u == null:
		follow_unit = null
		G.say("Kamera serbest", focus, G.player_team)
	else:
		follow_unit = u
		G.say("Kamera birime kilitlendi", u.position, G.player_team)

# haritaya göre azami görüş: ≤1 km 115 m; büyük haritada stratejik görüş
func setup_for_map(map_size: float) -> void:
	max_size = 115.0 if map_size <= 1024.0 else minf(map_size * 0.3, 2400.0)
	target_size = minf(target_size, max_size)
	size = minf(size, max_size)
	_zoom_band = -1

# görüş büyüdükçe kamera geri çekilir: ekranın alt kenarı yakın kırpma düzleminin önünde kalmalı
# (ortografik kamerada yer derinliği odaktan ±0,6 × görüş)
func _dist() -> float:
	return maxf(DIST, size * 0.62 + 60.0)

# gölge mesafesi basamakları: yalnız eşik geçilince değişir
const SHADOW_STEPS := [160.0, 230.0, 330.0, 480.0, 700.0, 1000.0, 1500.0, 2200.0, 3200.0]
var _shadow_d := -1.0
var shadows_on := true          # Ayarlar > Gölgeler
var _zoom_band := -1

func _apply() -> void:
	var p := deg_to_rad(pitch)
	var dist := _dist()
	var off := Vector3(sin(yaw), 0, cos(yaw)) * cos(p) * dist + Vector3(0, sin(p) * dist, 0)
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = (right_vec() * randf_range(-1, 1) + up_vec() * randf_range(-1, 1)) * _shake * 0.6
	position = focus + sh
	cam.transform = Transform3D(Basis.looking_at(-off, Vector3.UP), off)
	cam.size = size
	cam.far = dist + size * 0.62 + 400.0
	listener.position = Vector3.ZERO
	if light:
		var need := dist + size * 0.62 + 20.0
		var sd: float = SHADOW_STEPS[SHADOW_STEPS.size() - 1]
		for st in SHADOW_STEPS:
			if st >= need:
				sd = st
				break
		if sd != _shadow_d:
			_shadow_d = sd
			light.directional_shadow_max_distance = sd
		# stratejik görüşe çıkarken gölgeler bir anda kapanıp sahne parlamasın: 700–1100 arası yumuşakça söner
		light.shadow_enabled = size < 1100.0 and shadows_on
		light.shadow_opacity = clampf((1100.0 - size) / 400.0, 0.0, 1.0)
	_zoom_groups()

# yakınlaştırma bandı değişince küçük ayrıntılar: ot 200 m, çakıl/küçük eşya 420 m görüşten sonra gizli
func _zoom_groups() -> void:
	var band := 0 if size < 180.0 else (1 if size < 200.0 else (2 if size < 420.0 else (3 if size < 600.0 else 4)))
	if band == _zoom_band or not is_inside_tree():
		return
	_zoom_band = band
	for n in get_tree().get_nodes_in_group("zoom_grass"):
		n.visible = band <= 1
	for n in get_tree().get_nodes_in_group("zoom_small"):
		n.visible = band <= 2
	if G.props != null and is_instance_valid(G.props):
		G.props.set_far(size >= 600.0)
	if G.blocks != null and is_instance_valid(G.blocks):
		G.blocks.set_far(size >= 180.0)

func jump_to(p: Vector3, instant := false) -> void:
	target_focus = _clamp(p)
	if instant:
		focus = target_focus

func _clamp(p: Vector3) -> Vector3:
	return Vector3(clampf(p.x, 0.0, G.MAP), 0, clampf(p.z, 0.0, G.MAP))

func shake(amount: float, at: Vector3) -> void:
	var d := Vector2(at.x - focus.x, at.z - focus.z).length()
	var k := clampf(1.0 - d / (size * 1.2), 0.0, 1.0)
	_shake = maxf(_shake, amount * k)

func _unhandled_input(e: InputEvent) -> void:
	if not input_enabled:
		return
	if e is InputEventMouseButton:
		var mb := e as InputEventMouseButton
		# uzakta adım büyür (stratejik görüşe birkaç tıkta çıkılır)
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_size = maxf(min_size, target_size * (0.88 if target_size <= 130.0 else 0.8))
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_size = minf(max_size, target_size * (1.13 if target_size < 115.0 else 1.25))
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			if mb.pressed and mb.alt_pressed:
				# serbest bakış: sürükleme yönü döndürür, dikey eğer
				_look = true
				_look_from = mb.position
				return
			if not mb.pressed:
				_look = false
			_drag = mb.pressed and not _look
			_drag_from = mb.position
			_drag_focus = target_focus
			if _drag:
				follow_unit = null
	elif e is InputEventMouseMotion and _look:
		var ml := e as InputEventMouseMotion
		var dl := ml.position - _look_from
		_look_from = ml.position
		target_yaw -= dl.x * 0.006
		target_pitch = clampf(target_pitch + dl.y * 0.12, 25.0, 75.0)
		yaw = target_yaw
		pitch = target_pitch
	elif e is InputEventMouseMotion and _drag:
		var mm := e as InputEventMouseMotion
		var vp := get_viewport().get_visible_rect().size
		var wpp := size / vp.y
		var d := mm.position - _drag_from
		target_focus = _clamp(_drag_focus - right_vec() * d.x * wpp + up_vec() * d.y * wpp / sin(deg_to_rad(pitch)))
		focus = target_focus

# kameranın gördüğü zemin dikdörtgeni (kare başına bir kez; birimlerin animasyon ayrıntı düzeyi için)
var view_rect := Rect2()
var _vr_frame := -1

func view_ground_rect() -> Rect2:
	var f := Engine.get_process_frames()
	if f != _vr_frame:
		_vr_frame = f
		var vp := get_viewport().get_visible_rect().size
		var r := Rect2()
		var first := true
		for s in [Vector2.ZERO, Vector2(vp.x, 0), vp, Vector2(0, vp.y)]:
			var g := mouse_ground(s)
			if first:
				r = Rect2(Vector2(g.x, g.z), Vector2.ZERO)
				first = false
			else:
				r = r.expand(Vector2(g.x, g.z))
		view_rect = r.grow(12.0)
	return view_rect

func _process(dt: float) -> void:
	var rdt := dt / maxf(Engine.time_scale, 0.01)
	if input_enabled and not auto_pan:
		var mv := Vector2.ZERO
		if Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
			mv.y += 1
		if Input.is_key_pressed(KEY_S) or Input.is_key_pressed(KEY_DOWN):
			mv.y -= 1
		if Input.is_key_pressed(KEY_A) or Input.is_key_pressed(KEY_LEFT):
			mv.x -= 1
		if Input.is_key_pressed(KEY_D) or Input.is_key_pressed(KEY_RIGHT):
			mv.x += 1
		if edge_scroll and DisplayServer.window_is_focused() and not _drag:
			var vp := get_viewport().get_visible_rect().size
			var m := get_viewport().get_mouse_position()
			if m.x >= 0 and m.y >= 0 and m.x <= vp.x and m.y <= vp.y:
				if m.x < 6:
					mv.x -= 1
				elif m.x > vp.x - 7:
					mv.x += 1
				if m.y < 6:
					mv.y += 1
				elif m.y > vp.y - 7:
					mv.y -= 1
		if mv != Vector2.ZERO:
			# elle kaydırma kilidi bırakır
			follow_unit = null
			var sp := size * 1.1 * rdt
			if Input.is_key_pressed(KEY_SHIFT):
				sp *= 2.0
			target_focus = _clamp(target_focus + right_vec() * mv.x * sp + up_vec() * mv.y * sp / sin(deg_to_rad(pitch)))
	if auto_pan:
		_auto_t += rdt
		target_focus = _clamp(Vector3(128 + sin(_auto_t * 0.05) * 50.0, 0, 128 + cos(_auto_t * 0.037) * 50.0))
	# birime kilit: birim ölür / gemiye biner / kaybolursa bırakılır
	if follow_unit != null:
		if not is_instance_valid(follow_unit) or not follow_unit.get("alive") or not follow_unit.visible:
			follow_unit = null
		else:
			target_focus = _clamp(follow_unit.global_position)
	focus = focus.lerp(target_focus, clampf(rdt * 10.0, 0.0, 1.0))
	size = lerpf(size, target_size, clampf(rdt * 9.0, 0.0, 1.0))
	# hedef açı sarılmadan birikir (her adım ±45°): doğrusal izleme doğru yönde döner
	yaw = lerpf(yaw, target_yaw, clampf(rdt * 8.0, 0.0, 1.0))
	pitch = lerpf(pitch, target_pitch, clampf(rdt * 8.0, 0.0, 1.0))
	_shake = maxf(0.0, _shake - rdt * 2.5)
	_apply()

func mouse_ground(mpos: Vector2) -> Vector3:
	var o := cam.project_ray_origin(mpos)
	var d := cam.project_ray_normal(mpos)
	if absf(d.y) < 1e-4:
		return focus
	var t := -o.y / d.y
	return o + d * t

func screen(p: Vector3) -> Vector2:
	return cam.unproject_position(p)

func on_screen(p: Vector3, margin := 40.0) -> bool:
	var s := screen(p)
	var vp := get_viewport().get_visible_rect().size
	return s.x > -margin and s.y > -margin and s.x < vp.x + margin and s.y < vp.y + margin
