class_name Unit extends Node3D
# Tüm birimlerin (piyade, araç, yapı) ortak tabanı.

var team := 0
var kind := ""
var title := ""
var hp := 100.0
var max_hp := 100.0
var radius := 0.4
var alive := true
var selected := false
var sight := 40.0
var seen := [true, true]
var cap_cost := 1
var last_hit := -99.0
var attacker: Unit = null
var bubble := ""
var bubble_t := 0.0
var icon := "inf"

func _enter_tree() -> void:
	if not G.units.has(self):
		G.add_unit(self)

func _exit_tree() -> void:
	G.remove_unit(self)

func apply_visibility() -> void:
	var v := G.view_team()
	visible = (not alive) or v < 0 or seen[v]

func hostile() -> bool:
	return alive

func is_enemy(u) -> bool:
	return u != null and is_instance_valid(u) and u.team != team and u.team >= 0 and team >= 0

func aim_point() -> Vector3:
	return position + Vector3(0, 1.0, 0)

func take_damage(_amount: float, _src, _kind := "bullet") -> void:
	pass

func set_selected(v: bool) -> void:
	selected = v

func say(t: String, dur := 2.2) -> void:
	bubble = I18n.s(t)
	bubble_t = dur

func tick_bubble(dt: float) -> void:
	if bubble_t > 0.0:
		bubble_t -= dt
		if bubble_t <= 0.0:
			bubble = ""

func cmd_move(_p: Vector3, _force := false) -> void:
	pass

func cmd_attack(_u: Unit) -> void:
	pass

func cmd_stop() -> void:
	pass

func pos2() -> Vector2:
	return Vector2(position.x, position.z)

func dist2(u: Node3D) -> float:
	return Vector2(position.x - u.position.x, position.z - u.position.z).length()

static func set_layer(n: Node, layer: int) -> void:
	if n is VisualInstance3D:
		(n as VisualInstance3D).layers = layer
	for c in n.get_children():
		set_layer(c, layer)
