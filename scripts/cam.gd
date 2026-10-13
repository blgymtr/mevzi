class_name CamRig extends Node3D
# Ortografik izometrik kamera: kaydırma (WASD / kenar / orta tuş), yakınlaştırma, sarsıntı.

const PITCH := 40.0
const DIST := 120.0
var cam: Camera3D
var listener: AudioListener3D
var size := 40.0
var target_size := 40.0
var min_size := 22.0
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
	return Vector3(1, 0, -1).normalized()

func up_vec() -> Vector3:
	return Vector3(-1, 0, -1).normalized()

func _apply() -> void:
	var p := deg_to_rad(PITCH)
	var off := Vector3(1, 0, 1).normalized() * cos(p) * DIST + Vector3(0, sin(p) * DIST, 0)
	var sh := Vector3.ZERO
	if _shake > 0.0:
		sh = (right_vec() * randf_range(-1, 1) + up_vec() * randf_range(-1, 1)) * _shake * 0.6
	position = focus + sh
	cam.transform = Transform3D(Basis.looking_at(-off, Vector3.UP), off)
	cam.size = size
	listener.position = Vector3.ZERO
	if light:
		light.directional_shadow_max_distance = DIST + size * 1.6

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
		if mb.button_index == MOUSE_BUTTON_WHEEL_UP and mb.pressed:
			target_size = maxf(min_size, target_size * 0.88)
		elif mb.button_index == MOUSE_BUTTON_WHEEL_DOWN and mb.pressed:
			target_size = minf(max_size, target_size * 1.13)
		elif mb.button_index == MOUSE_BUTTON_MIDDLE:
			_drag = mb.pressed
			_drag_from = mb.position
			_drag_focus = target_focus
	elif e is InputEventMouseMotion and _drag:
		var mm := e as InputEventMouseMotion
		var vp := get_viewport().get_visible_rect().size
		var wpp := size / vp.y
		var d := mm.position - _drag_from
		target_focus = _clamp(_drag_focus - right_vec() * d.x * wpp + up_vec() * d.y * wpp / sin(deg_to_rad(PITCH)))
		focus = target_focus

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
			var sp := size * 1.1 * rdt
			if Input.is_key_pressed(KEY_SHIFT):
				sp *= 2.0
			target_focus = _clamp(target_focus + right_vec() * mv.x * sp + up_vec() * mv.y * sp / sin(deg_to_rad(PITCH)))
	if auto_pan:
		_auto_t += rdt
		target_focus = _clamp(Vector3(128 + sin(_auto_t * 0.05) * 50.0, 0, 128 + cos(_auto_t * 0.037) * 50.0))
	focus = focus.lerp(target_focus, clampf(rdt * 10.0, 0.0, 1.0))
	size = lerpf(size, target_size, clampf(rdt * 9.0, 0.0, 1.0))
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
