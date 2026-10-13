class_name VehicleModels extends RefCounted
# Araç meshleri (ileri yön -Z). Her biri {hull, turret, barrel, wheels:[(konum, yarıçap)], turret_pos, barrel_pos, muzzle}

static var _c := {}

static func get_model(vtype: String, team: int, winter: bool) -> Dictionary:
	var key := "%s_%d_%s" % [vtype, team, winter]
	if not _c.has(key):
		match vtype:
			"tank":
				_c[key] = _tank(team, winter)
			"apc":
				_c[key] = _apc(team, winter)
			"technical":
				_c[key] = _technical(team, winter)
			"truck":
				_c[key] = _truck(team, winter)
			"heli":
				_c[key] = _heli(team, winter)
	return _c[key]

static func _paint(team: int, winter: bool) -> Array:
	# [ana, koyu, açık, işaret]
	if winter:
		if team == 0:
			return [Color(0.82, 0.83, 0.82), Color(0.42, 0.44, 0.38), Color(0.95, 0.95, 0.96), G.TEAM_COL[0]]
		return [Color(0.8, 0.74, 0.6), Color(0.48, 0.42, 0.32), Color(0.95, 0.94, 0.92), G.TEAM_COL[1]]
	if team == 0:
		return [Color(0.24, 0.29, 0.18), Color(0.16, 0.19, 0.12), Color(0.36, 0.38, 0.26), G.TEAM_COL[0]]
	return [Color(0.74, 0.69, 0.55), Color(0.55, 0.5, 0.38), Color(0.86, 0.83, 0.74), G.TEAM_COL[1]]

static func _camo(mb: MB, rng: RandomNumberGenerator, cols: Array, area: Vector3, y: float, n: int, center := Vector3.ZERO) -> void:
	for i in n:
		var c: Color = cols[1] if rng.randf() < 0.6 else cols[2]
		var p := center + Vector3(rng.randf_range(-area.x, area.x), y, rng.randf_range(-area.z, area.z))
		mb.box(p, Vector3(rng.randf_range(0.4, 1.1), 0.02, rng.randf_range(0.4, 1.3)), c, Basis(Vector3.UP, rng.randf() * TAU))

static func _wheel_mesh(r: float, w: float) -> ArrayMesh:
	var mb := MB.new()
	var bas := Basis(Vector3.FORWARD, PI * 0.5)
	mb.cyl(Vector3(-w * 0.5, 0, 0), r, r, w, 12, Color(0.07, 0.07, 0.07), bas)
	mb.cyl(Vector3(-w * 0.52, 0, 0), r * 0.55, r * 0.55, w * 1.04, 8, Color(0.3, 0.3, 0.28), bas)
	for i in 6:
		var a := TAU * i / 6.0
		mb.box(Vector3(0, cos(a) * r * 0.82, sin(a) * r * 0.82), Vector3(w * 1.05, r * 0.18, r * 0.22), Color(0.05, 0.05, 0.05), Basis(Vector3.RIGHT, a))
	return mb.commit(Mats.vc())

static func _tank(team: int, winter: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 55 + team
	var C := _paint(team, winter)
	var main: Color = C[0]
	var dark := Color(0.15, 0.15, 0.14)
	var mb := MB.new()
	# paletler
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.28, 0.46, 0), Vector3(0.62, 0.8, 5.9), dark)
		mb.box(Vector3(sx * 1.28, 0.05, 0), Vector3(0.64, 0.1, 5.5), Color(0.1, 0.1, 0.1))
		for i in 5:
			var z := -2.15 + i * 1.07
			mb.cyl(Vector3(sx * 1.6, 0.42, z), 0.38, 0.38, 0.06, 12, Color(0.25, 0.26, 0.22), Basis(Vector3.FORWARD, PI * 0.5 * -sx))
			mb.cyl(Vector3(sx * 1.66, 0.42, z), 0.12, 0.12, 0.04, 8, Color(0.18, 0.18, 0.16), Basis(Vector3.FORWARD, PI * 0.5 * -sx))
		mb.cyl(Vector3(sx * 1.6, 0.6, -2.9), 0.3, 0.3, 0.05, 10, dark.lightened(0.1), Basis(Vector3.FORWARD, PI * 0.5 * -sx))
		mb.cyl(Vector3(sx * 1.6, 0.6, 2.9), 0.3, 0.3, 0.05, 10, dark.lightened(0.1), Basis(Vector3.FORWARD, PI * 0.5 * -sx))
	# gövde
	mb.box(Vector3(0, 0.68, 0.15), Vector3(2.0, 0.62, 5.6), main.darkened(0.1))
	mb.box(Vector3(0, 1.0, 0.25), Vector3(3.24, 0.1, 5.3), main)
	var bas := Basis(Vector3.UP, PI * 0.5)
	mb.prism(PackedVector2Array([Vector2(3.05, 0.38), Vector2(2.35, 0.38), Vector2(2.4, 1.05), Vector2(2.95, 0.72)]), 2.4, main, Vector3.ZERO, bas)
	mb.box(Vector3(0, 1.08, 1.6), Vector3(2.4, 0.14, 2.4), main.darkened(0.05))
	for i in 5:
		mb.box(Vector3(0, 1.16, 0.9 + i * 0.36), Vector3(1.9, 0.03, 0.12), Color(0.12, 0.12, 0.11))
	for sx in [-0.5, 0.5]:
		mb.cyl(Vector3(sx - 0.45, 1.25, 2.95), 0.3, 0.3, 0.9, 10, main.darkened(0.2), Basis(Vector3.FORWARD, PI * 0.5))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.4, 1.14, -0.6), Vector3(0.36, 0.2, 1.6), main.darkened(0.15))
		mb.box(Vector3(sx * 1.38, 1.14, 1.2), Vector3(0.4, 0.26, 0.6), C[2])
	mb.box(Vector3(0.65, 1.12, -2.05), Vector3(0.35, 0.16, 0.25), Color(0.6, 0.62, 0.55))
	_camo(mb, rng, C, Vector3(1.3, 0, 2.4), 1.06, 8)
	var hull := mb.commit(Mats.metal())
	# taret
	var tb := MB.new()
	tb.sphere(Vector3(0, 0, 0), Vector3(1.18, 0.62, 1.32), 14, 8, main, Basis(), true)
	tb.cyl(Vector3(0.45, 0.42, 0.25), 0.3, 0.27, 0.22, 10, main.darkened(0.1))
	tb.sphere(Vector3(0.45, 0.64, 0.25), Vector3(0.27, 0.1, 0.27), 8, 4, main.darkened(0.05), Basis(), true)
	tb.cyl(Vector3(-0.45, 0.45, 0.35), 0.24, 0.24, 0.12, 8, main.darkened(0.1))
	tb.box(Vector3(-0.85, 0.32, -0.35), Vector3(0.32, 0.2, 0.3), Color(0.2, 0.2, 0.2))
	tb.box(Vector3(0, 0.12, -1.18), Vector3(0.52, 0.42, 0.4), main.darkened(0.08))
	tb.box(Vector3(0, 0.25, 1.3), Vector3(1.1, 0.25, 0.35), main.darkened(0.2))
	for sx in [-1.0, 1.0]:
		tb.box(Vector3(sx * 1.12, 0.22, 0.1), Vector3(0.05, 0.22, 0.6), C[3])
	tb.cyl(Vector3(0.2, 0.62, 0.9), 0.025, 0.02, 1.5, 4, Color(0.15, 0.15, 0.15))
	_camo(tb, rng, C, Vector3(0.7, 0, 0.8), 0.6, 4)
	var turret := tb.commit(Mats.metal())
	var bb := MB.new()
	var bz := Basis(Vector3.RIGHT, -PI * 0.5)
	bb.cyl(Vector3(0, 0, 0), 0.09, 0.075, 3.6, 8, main.darkened(0.12), bz)
	bb.cyl(Vector3(0, 0, -2.2), 0.12, 0.12, 0.5, 8, main.darkened(0.12), bz)
	bb.cyl(Vector3(0, 0, -3.55), 0.085, 0.085, 0.12, 8, Color(0.1, 0.1, 0.1), bz)
	var barrel := bb.commit(Mats.metal())
	return {"hull": hull, "turret": turret, "barrel": barrel, "turret_pos": Vector3(0, 1.08, -0.25), "barrel_pos": Vector3(0, 0.2, -1.3), "muzzle": Vector3(0, 0, -3.65), "wheels": []}

static func _apc(team: int, winter: bool) -> Dictionary:
	var rng := RandomNumberGenerator.new()
	rng.seed = 77 + team
	var C := _paint(team, winter)
	var main: Color = C[0]
	var mb := MB.new()
	var bas := Basis(Vector3.UP, PI * 0.5)
	# tekne biçimli gövde profili (yandan)
	mb.prism(PackedVector2Array([Vector2(-3.7, 1.15), Vector2(-3.3, 0.55), Vector2(3.4, 0.55), Vector2(3.6, 1.0), Vector2(3.4, 1.85), Vector2(-2.6, 2.0), Vector2(-3.5, 1.6)]), 2.5, main, Vector3.ZERO, bas)
	mb.box(Vector3(0, 1.97, 0.4), Vector3(2.3, 0.08, 5.6), main.darkened(0.06))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.28, 1.6, 0.2), Vector3(0.06, 0.5, 6.0), main.darkened(0.12))
		for i in 3:
			mb.box(Vector3(sx * 1.31, 1.5, -1.0 + i * 1.2), Vector3(0.04, 0.25, 0.35), Color(0.1, 0.1, 0.1))
		mb.box(Vector3(sx * 1.31, 1.75, -2.0), Vector3(0.04, 0.18, 0.5), C[3])
	mb.box(Vector3(0.5, 2.05, 1.8), Vector3(0.7, 0.1, 0.8), main.darkened(0.15))
	mb.box(Vector3(-0.6, 2.05, 1.6), Vector3(0.6, 0.1, 0.6), main.darkened(0.15))
	mb.box(Vector3(0, 1.75, -3.45), Vector3(2.0, 0.08, 0.3), Color(0.08, 0.08, 0.08))
	_camo(mb, rng, C, Vector3(1.0, 0, 2.6), 2.02, 7)
	var hull := mb.commit(Mats.metal())
	var tb := MB.new()
	tb.cyl(Vector3.ZERO, 0.62, 0.55, 0.45, 12, main.darkened(0.04))
	tb.box(Vector3(0, 0.3, -0.55), Vector3(0.5, 0.3, 0.35), main.darkened(0.1))
	tb.box(Vector3(0.45, 0.35, 0.1), Vector3(0.18, 0.18, 0.4), Color(0.15, 0.15, 0.15))
	for sx in [-1.0, 1.0]:
		tb.box(Vector3(sx * 0.6, 0.22, 0.0), Vector3(0.04, 0.14, 0.4), C[3])
	var turret := tb.commit(Mats.metal())
	var bb := MB.new()
	bb.cyl(Vector3.ZERO, 0.055, 0.045, 2.2, 6, Color(0.14, 0.14, 0.13), Basis(Vector3.RIGHT, -PI * 0.5))
	var barrel := bb.commit(Mats.metal())
	var wheels: Array = []
	for sx in [-1.0, 1.0]:
		for z in [-2.4, -1.1, 1.0, 2.3]:
			wheels.append([Vector3(sx * 1.22, 0.58, z), 0.58, 0.42])
	return {"hull": hull, "turret": turret, "barrel": barrel, "turret_pos": Vector3(0, 2.0, -0.7), "barrel_pos": Vector3(0, 0.3, -0.7), "muzzle": Vector3(0, 0, -2.25), "wheels": wheels}

static func _technical(team: int, winter: bool) -> Dictionary:
	var C := _paint(team, winter)
	var main: Color = C[0].lightened(0.05) if team == 0 else Color(0.9, 0.88, 0.82)
	if team == 0 and not winter:
		main = Color(0.3, 0.34, 0.22)
	var mb := MB.new()
	var glass := Color(0.06, 0.07, 0.09)
	mb.box(Vector3(0, 0.75, 0), Vector3(1.9, 0.45, 5.0), main)
	mb.box(Vector3(0, 0.98, -1.9), Vector3(1.86, 0.08, 1.2), main.darkened(0.05))
	mb.hull(Vector3(0, 0.98, -0.65), Vector2(1.84, 1.5), Vector2(1.7, 1.05), 0.68, glass)
	mb.box(Vector3(0, 1.67, -0.55), Vector3(1.72, 0.06, 1.1), main)
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 0.92, 1.25, 1.35), Vector3(0.08, 0.5, 2.3), main.darkened(0.08))
	mb.box(Vector3(0, 1.25, 2.47), Vector3(1.9, 0.5, 0.08), main.darkened(0.08))
	mb.box(Vector3(0, 1.0, 1.35), Vector3(1.76, 0.06, 2.3), Color(0.2, 0.2, 0.2))
	mb.box(Vector3(0, 0.7, -2.52), Vector3(1.7, 0.3, 0.06), Color(0.15, 0.15, 0.15))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 0.96, 1.15, -1.4), Vector3(0.05, 0.12, 0.3), C[3])
	var hull := mb.commit(Mats.metal())
	var tb := MB.new()
	tb.cyl(Vector3.ZERO, 0.08, 0.06, 0.8, 6, Color(0.2, 0.2, 0.2))
	tb.box(Vector3(0, 0.85, 0.15), Vector3(0.2, 0.22, 0.6), Color(0.15, 0.15, 0.15))
	tb.box(Vector3(0, 1.0, -0.3), Vector3(0.6, 0.35, 0.04), Color(0.25, 0.27, 0.2))
	var turret := tb.commit(Mats.metal())
	var bb := MB.new()
	bb.cyl(Vector3.ZERO, 0.04, 0.035, 1.4, 6, Color(0.1, 0.1, 0.1), Basis(Vector3.RIGHT, -PI * 0.5))
	var barrel := bb.commit(Mats.metal())
	var wheels: Array = []
	for sx in [-1.0, 1.0]:
		for z in [-1.65, 1.55]:
			wheels.append([Vector3(sx * 0.86, 0.42, z), 0.42, 0.3])
	return {"hull": hull, "turret": turret, "barrel": barrel, "turret_pos": Vector3(0, 1.05, 1.2), "barrel_pos": Vector3(0, 0.85, -0.15), "muzzle": Vector3(0, 0, -1.45), "wheels": wheels, "gunner": Vector3(0, 1.03, 1.85)}

static func _truck(team: int, winter: bool) -> Dictionary:
	var C := _paint(team, winter)
	var main: Color = C[0]
	var canvas := Color(0.7, 0.64, 0.48) if not winter else Color(0.86, 0.84, 0.78)
	if team == 0 and not winter:
		canvas = Color(0.4, 0.42, 0.3)
	var mb := MB.new()
	var glass := Color(0.06, 0.07, 0.09)
	mb.box(Vector3(0, 0.95, 0.2), Vector3(1.3, 0.3, 6.6), Color(0.12, 0.12, 0.12))
	mb.box(Vector3(0, 1.45, -2.75), Vector3(2.3, 0.9, 1.3), main)
	mb.box(Vector3(0, 1.38, -3.55), Vector3(1.6, 0.75, 0.7), main.darkened(0.05))
	mb.hull(Vector3(0, 1.9, -2.6), Vector2(2.3, 1.1), Vector2(2.2, 0.9), 0.6, glass)
	mb.box(Vector3(0, 2.52, -2.55), Vector3(2.24, 0.06, 0.95), main)
	mb.box(Vector3(0, 1.3, 1.05), Vector3(2.5, 0.12, 4.4), main.darkened(0.1))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.22, 1.6, 1.05), Vector3(0.06, 0.5, 4.4), main.darkened(0.05))
	# branda (yuvarlak üst)
	var nseg := 6
	for i in nseg:
		var a0 := PI * i / nseg
		var a1 := PI * (i + 1) / nseg
		var p0 := Vector3(cos(a0) * 1.25, 1.85 + sin(a0) * 0.75, 0)
		var p1 := Vector3(cos(a1) * 1.25, 1.85 + sin(a1) * 0.75, 0)
		var n := Vector3(cos((a0 + a1) * 0.5), sin((a0 + a1) * 0.5), 0)
		mb.quad(p0 + Vector3(0, 0, -1.1), p1 + Vector3(0, 0, -1.1), p1 + Vector3(0, 0, 3.25), p0 + Vector3(0, 0, 3.25), canvas.darkened(0.03 * i), n)
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.24, 1.6, 1.05), Vector3(0.04, 0.5, 4.36), canvas.darkened(0.08))
	var prof := PackedVector2Array()
	for i in nseg + 1:
		var a := PI * i / nseg
		prof.append(Vector2(cos(a) * 1.25, 1.85 + sin(a) * 0.75))
	prof.append(Vector2(-1.25, 1.35))
	prof.append(Vector2(1.25, 1.35))
	mb.prism(prof, 0.04, canvas.darkened(0.12), Vector3(0, 0, -1.1))
	mb.prism(prof, 0.04, canvas.darkened(0.12), Vector3(0, 0, 3.25))
	mb.box(Vector3(0.9, 2.05, 0.6), Vector3(0.05, 0.4, 0.7), C[3])
	var hull := mb.commit(Mats.metal())
	var wheels: Array = []
	for sx in [-1.0, 1.0]:
		for z in [-2.7, 0.9, 2.3]:
			wheels.append([Vector3(sx * 1.05, 0.55, z), 0.55, 0.4])
	return {"hull": hull, "turret": null, "barrel": null, "turret_pos": Vector3.ZERO, "barrel_pos": Vector3.ZERO, "muzzle": Vector3.ZERO, "wheels": wheels}

static func wheel(r: float, w: float) -> ArrayMesh:
	var key := "wheel_%s_%s" % [r, w]
	if not _c.has(key):
		_c[key] = _wheel_mesh(r, w)
	return _c[key]

static func _heli(team: int, winter: bool) -> Dictionary:
	var C := _paint(team, winter)
	var main: Color = C[0].darkened(0.05) if team == 0 else Color(0.58, 0.6, 0.5)
	var rng := RandomNumberGenerator.new()
	rng.seed = 91 + team
	var mb := MB.new()
	var glass := Color(0.12, 0.16, 0.2)
	var bas := Basis(Vector3.UP, PI * 0.5)
	mb.prism(PackedVector2Array([Vector2(5.2, -0.7), Vector2(4.2, -1.3), Vector2(-1.8, -1.3), Vector2(-2.6, -0.6), Vector2(-2.4, 0.5), Vector2(1.5, 0.8), Vector2(3.4, 0.3), Vector2(5.0, -0.2)]), 1.9, main, Vector3.ZERO, bas)
	mb.hull(Vector3(0, -0.15, -3.6), Vector2(1.0, 1.1), Vector2(0.7, 0.6), 0.75, glass)
	mb.hull(Vector3(0, 0.25, -2.2), Vector2(1.2, 1.2), Vector2(0.85, 0.7), 0.7, glass)
	mb.box(Vector3(0, 1.0, 0.2), Vector3(1.5, 0.55, 3.0), main.darkened(0.08))
	for sx in [-0.45, 0.45]:
		mb.cyl(Vector3(sx, 1.0, -1.2), 0.22, 0.22, 0.4, 8, Color(0.15, 0.15, 0.15), Basis(Vector3.RIGHT, PI * 0.5))
	mb.box(Vector3(0, 0.2, 5.0), Vector3(0.4, 0.45, 5.6), main)
	mb.box(Vector3(0, -0.1, 2.6), Vector3(0.9, 0.7, 1.6), main)
	mb.box(Vector3(0, 1.0, 7.6), Vector3(0.15, 1.6, 1.0), main.darkened(0.05))
	mb.box(Vector3(0, 0.25, 7.0), Vector3(2.0, 0.08, 0.6), main.darkened(0.05))
	for sx in [-1.0, 1.0]:
		mb.box(Vector3(sx * 1.7, -0.3, -0.6), Vector3(1.6, 0.1, 0.9), main.darkened(0.1), Basis(Vector3.FORWARD, sx * 0.15))
		mb.cyl(Vector3(sx * 1.6, -0.55, -1.4), 0.22, 0.22, 1.4, 8, Color(0.2, 0.22, 0.18), Basis(Vector3.RIGHT, PI * 0.5))
		mb.cyl(Vector3(sx * 2.3, -0.55, -1.3), 0.2, 0.2, 1.2, 8, Color(0.2, 0.22, 0.18), Basis(Vector3.RIGHT, PI * 0.5))
		mb.box(Vector3(sx * 0.98, -0.2, 1.2), Vector3(0.04, 0.3, 0.8), C[3])
	mb.cyl(Vector3(0, -1.3, -4.6), 0.18, 0.18, 0.3, 8, Color(0.15, 0.15, 0.15))
	mb.box(Vector3(0, -1.25, -5.0), Vector3(0.06, 0.06, 0.8), Color(0.1, 0.1, 0.1))
	for sx in [-0.9, 0.9]:
		mb.cyl(Vector3(sx, -1.7, 0.3), 0.22, 0.22, 0.15, 8, Color(0.08, 0.08, 0.08), Basis(Vector3.FORWARD, PI * 0.5))
	_camo(mb, rng, C, Vector3(0.6, 0, 2.5), 0.85, 6)
	var hull := mb.commit(Mats.metal())
	var rb := MB.new()
	rb.cyl(Vector3(0, 0, 0), 0.18, 0.15, 0.35, 8, Color(0.15, 0.15, 0.15))
	for i in 5:
		var a := TAU * i / 5.0
		rb.box(Vector3(cos(a) * 4.2, 0.32, sin(a) * 4.2), Vector3(8.2, 0.04, 0.34), Color(0.05, 0.05, 0.05), Basis(Vector3.UP, -a))
	var rotor := rb.commit(Mats.vc())
	var tb := MB.new()
	for i in 3:
		var a := TAU * i / 3.0
		tb.box(Vector3(0, cos(a) * 0.65, sin(a) * 0.65), Vector3(0.04, 1.3, 0.18), Color(0.12, 0.12, 0.12), Basis(Vector3.RIGHT, a))
	var trotor := tb.commit(Mats.vc())
	return {"hull": hull, "turret": null, "barrel": null, "turret_pos": Vector3.ZERO, "barrel_pos": Vector3.ZERO, "muzzle": Vector3(0, -1.3, -4.6), "wheels": [], "rotor": rotor, "rotor_pos": Vector3(0, 1.3, 0.0), "trotor": trotor, "trotor_pos": Vector3(0.12, 1.1, 7.6)}
