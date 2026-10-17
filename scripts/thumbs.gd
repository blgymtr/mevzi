class_name Thumbs extends Node
# Arayüz kartları için model küçük resimleri: her öğe ayrı bir SubViewport'ta bir kez çizilir.

var _cache := {}
var _vps: Array = []

func get_thumb(id: String, team: int) -> Texture2D:
	var key := "%s|%d|%s" % [id, team, G.map_kind]
	if _cache.has(key):
		return _cache[key]
	var vp := SubViewport.new()
	vp.size = Vector2i(220, 150)
	vp.own_world_3d = true
	vp.transparent_bg = false
	vp.msaa_3d = Viewport.MSAA_4X
	vp.render_target_update_mode = SubViewport.UPDATE_ONCE
	add_child(vp)
	_vps.append(vp)
	var we := WorldEnvironment.new()
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	# eskiz arayüzü: zemin kâğıt tonunda (gölgeler HUD gölgelendiricisinde taramaya döner)
	env.background_color = Color(0.78, 0.75, 0.68)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.8, 0.75, 0.68)
	env.ambient_light_energy = 0.6
	env.tonemap_exposure = 1.0
	env.tonemap_mode = Environment.TONE_MAPPER_ACES
	we.environment = env
	vp.add_child(we)
	var sun := DirectionalLight3D.new()
	sun.light_energy = 1.6
	sun.light_color = Color(1.0, 0.9, 0.78)
	sun.shadow_enabled = true
	sun.rotation = Vector3(deg_to_rad(-50), deg_to_rad(-30), 0)
	vp.add_child(sun)
	var holder := Node3D.new()
	vp.add_child(holder)
	var model := _model(id, team)
	holder.add_child(model)
	# zemin
	var gp := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(60, 60)
	gp.mesh = pm
	var gm := StandardMaterial3D.new()
	gm.albedo_color = env.background_color
	gp.material_override = gm
	vp.add_child(gp)
	# kamera: modelin sınırlarına göre
	var aabb := _aabb(model)
	var cam := Camera3D.new()
	cam.projection = Camera3D.PROJECTION_ORTHOGONAL
	var ext := maxf(aabb.size.x, aabb.size.z)
	cam.size = maxf(ext * 0.95, aabb.size.y * 1.6) + 0.6
	var c := aabb.get_center()
	var dir := Vector3(1, 0.95, 1).normalized()
	cam.transform = Transform3D(Basis.looking_at(-dir, Vector3.UP), c + dir * 60.0)
	cam.far = 200.0
	vp.add_child(cam)
	cam.current = true
	var tex := vp.get_texture()
	_cache[key] = tex
	return tex

func _aabb(n: Node) -> AABB:
	var out := AABB()
	var first := true
	var stack: Array = [n]
	while not stack.is_empty():
		var x: Node = stack.pop_back()
		if x is MeshInstance3D and x.mesh:
			var a: AABB = (x as MeshInstance3D).global_transform * x.mesh.get_aabb() if x.is_inside_tree() else _local_xf(x) * x.mesh.get_aabb()
			out = a if first else out.merge(a)
			first = false
		stack.append_array(x.get_children())
	return out

func _local_xf(n: Node3D) -> Transform3D:
	var xf := n.transform
	var p := n.get_parent()
	while p is Node3D:
		xf = (p as Node3D).transform * xf
		p = p.get_parent()
	return xf

func _model(id: String, team: int) -> Node3D:
	if id.begins_with("s:"):
		# tek asker portresi
		var sr := Node3D.new()
		var sb := SoldierBody.new()
		sb.rotation.y = PI * 0.15
		sr.add_child(sb)
		sb.build(team, id.substr(2), G.map_kind == "winter")
		sb.animate(1.0, "aim", 0.0)
		return sr
	if id.begins_with("v:"):
		return _vehicle_model(id.substr(2), team)
	if Building.BDEF.has(id):
		var b := Building.new()
		b.setup(team, id, 0.0)
		b.done = true
		b._apply_construct_look()
		var m := b.model
		b.remove_child(m)
		if b.gun_pivot:
			var gpv := b.gun_pivot
			b.remove_child(gpv)
			m.add_child(gpv)
		b.free()
		return m
	var P: Dictionary = Building.PDEF.get(id, {})
	if P.has("vehicle"):
		return _vehicle_model(P["vehicle"], team)
	# piyade timi: birkaç asker
	var root := Node3D.new()
	var units: Array = P.get("units", ["rifle"])
	var n := mini(units.size(), 4)
	for i in n:
		var sb := SoldierBody.new()
		sb.position = Vector3((i % 2) * 0.9 - 0.45, 0, (i / 2) * 0.9 - 0.45)
		sb.rotation.y = PI * 0.25
		root.add_child(sb)
		sb.build(team, units[i], G.map_kind == "winter")
		sb.animate(1.0, "aim" if i % 2 == 0 else "stand", 0.0)
	return root

func _vehicle_model(vt: String, team: int) -> Node3D:
	var root := Node3D.new()
	var M := Art.vehicle_model(vt, team) if Catalog.has(vt) and Art.has(vt) else Art.vehicle(Catalog.base(vt) if Catalog.has(vt) else vt, team)
	if M.is_empty():
		return root
	for hm in M["hulls"]:
		var mi := MeshInstance3D.new()
		mi.mesh = hm[0]
		mi.position = hm[1]
		root.add_child(mi)
	if M["turret"] != null:
		var t := MeshInstance3D.new()
		t.mesh = M["turret"]
		t.position = M["turret_pos"]
		root.add_child(t)
		if M["barrel"] != null:
			var b := MeshInstance3D.new()
			b.mesh = M["barrel"]
			b.position = M["barrel_pos"]
			t.add_child(b)
	for w in M["wheels"]:
		var wm := MeshInstance3D.new()
		wm.mesh = w[3]
		wm.position = w[0]
		root.add_child(wm)
	if M.has("rotor"):
		var r := MeshInstance3D.new()
		r.mesh = M["rotor"]
		r.position = M["rotor_pos"]
		root.add_child(r)
	root.rotation.y = PI * 0.75
	return root
