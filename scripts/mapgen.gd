class_name MapGen extends RefCounted
# Prosedürel harita: çöl kasabası ve karlı köy.

var rng := RandomNumberGenerator.new()
var B: Blocks
var P: Props
var T: Terrain
var roads: Array = []
var keep: Array = []     # [merkez, yarıçap]
var kind := "desert"
var map_id := "desert_town"
var rivers: Array = []   # [noktalar, genişlik]
var bridges: Array = []
const MAPS := {
	"desert_canal": {"title": "Çöl Kanalı", "biome": "desert", "desc": "Turkuaz bir sulama kanalı iki orduyu ayırıyor. Üç köprüyü tutan kazanır."},
	"green_valley": {"title": "Yeşil Vadi", "biome": "green", "desc": "Kıvrılan nehir, toprak yollar ve tek taş köprü. Ağaçlıklar pusu için ideal."},
	"winter_village": {"title": "Karlı Köy", "biome": "winter", "desc": "Karla kaplı köy, tuğla duvarlar ve kazılmış siperler."},
	"desert_town": {"title": "Çöl Kasabası", "biome": "desert", "desc": "Düz çatılı beyaz evler ve yıkıntılarla dolu kasabada sokak sokak savaş."},
}

const STONE := Color(0.9, 0.8, 0.62)
const WHITE := Color(0.94, 0.93, 0.89)
const BH := 0.42

func build(id: String, seed_v: int) -> void:
	map_id = id
	kind = MAPS[id]["biome"]
	rng.seed = seed_v
	B = G.blocks
	P = G.props
	T = G.terrain
	P.winter = kind == "winter"
	match id:
		"desert_canal":
			_desert_canal()
		"green_valley":
			_green_valley()
		"winter_village":
			_winter()
		_:
			_desert()
	T.make_water()
	B.finalize()
	G.grid.flush_all()
	T.scatter(rng)
	T.flush()

# ------------------------------------------------------------ yardımcılar
func _spline(ctrl: Array, step := 3.0) -> PackedVector3Array:
	var out := PackedVector3Array()
	for i in ctrl.size() - 1:
		var p0: Vector3 = ctrl[maxi(i - 1, 0)]
		var p1: Vector3 = ctrl[i]
		var p2: Vector3 = ctrl[i + 1]
		var p3: Vector3 = ctrl[mini(i + 2, ctrl.size() - 1)]
		var n := int(p1.distance_to(p2) / step) + 1
		for s in n:
			var t := float(s) / n
			var t2 := t * t
			var t3 := t2 * t
			out.append(0.5 * ((2.0 * p1) + (-p0 + p2) * t + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * t2 + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * t3))
	out.append(ctrl[ctrl.size() - 1])
	return out

func road(ctrl: Array, w := 6.0) -> PackedVector3Array:
	var pts := _spline(ctrl)
	roads.append(pts)
	T.road_polyline(pts, w, rng)
	return pts

func _poly_dist(pts: PackedVector3Array, p: Vector3) -> float:
	var best := 1e9
	var q := Vector2(p.x, p.z)
	for i in pts.size() - 1:
		var a := Vector2(pts[i].x, pts[i].z)
		var ab := Vector2(pts[i + 1].x, pts[i + 1].z) - a
		var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-5), 0.0, 1.0)
		best = minf(best, (q - (a + ab * t)).length())
	return best

func river(ctrl: Array, w: float, depth := 1.7) -> PackedVector3Array:
	var pts := _spline(ctrl, 2.0)
	rivers.append([pts, w])
	T.carve(pts, w, depth)
	return pts

# yol-nehir kesişimlerine köprü
func auto_bridges() -> void:
	for r in roads:
		var rp: PackedVector3Array = r
		for rv in rivers:
			var vp: PackedVector3Array = rv[0]
			var w: float = rv[1]
			var last := Vector3(-999, 0, -999)
			for i in rp.size() - 1:
				for j in vp.size() - 1:
					var hit = Geometry2D.segment_intersects_segment(Vector2(rp[i].x, rp[i].z), Vector2(rp[i + 1].x, rp[i + 1].z), Vector2(vp[j].x, vp[j].z), Vector2(vp[j + 1].x, vp[j + 1].z))
					if hit != null:
						var c := Vector3(hit.x, 0, hit.y)
						if c.distance_to(last) < 12.0:
							continue
						var near := false
						for bb in bridges:
							if bb.distance_to(c) < 22.0:
								near = true
						if near:
							continue
						bridges.append(c)
						last = c
						var dir := (rp[i + 1] - rp[i]).normalized()
						var vd := (vp[j + 1] - vp[j]).normalized()
						var s := absf(dir.cross(vd).y)
						P.bridge(c, dir, (w + 5.0) / maxf(s, 0.5))
						reserve(c, w * 0.5 + 6.0)

func road_dist(p: Vector3) -> float:
	var best := 1e9
	for r in roads:
		var pts: PackedVector3Array = r
		for i in pts.size() - 1:
			var a := Vector2(pts[i].x, pts[i].z)
			var b := Vector2(pts[i + 1].x, pts[i + 1].z)
			var q := Vector2(p.x, p.z)
			var ab := b - a
			var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-5), 0.0, 1.0)
			best = minf(best, (q - (a + ab * t)).length())
	return best

func free_at(p: Vector3, r: float, road_m := 4.0) -> bool:
	if p.x < r + 3 or p.z < r + 3 or p.x > G.MAP - r - 3 or p.z > G.MAP - r - 3:
		return false
	for k in keep:
		if Vector2(p.x - k[0].x, p.z - k[0].z).length() < k[1] + r:
			return false
	if road_dist(p) < r + road_m:
		return false
	for rv in rivers:
		if _poly_dist(rv[0], p) < rv[1] * 0.5 + 3.0 + r:
			return false
	var s := maxf(r, 0.5)
	for dz in [-s, 0.0, s]:
		for dx in [-s, 0.0, s]:
			if G.grid.height_at(p + Vector3(dx, 0, dz)) > 0.05:
				return false
	return true

func rand_free(r: float, tries := 60, region := Rect2(4, 4, 248, 248), road_m := 4.0) -> Vector3:
	for i in tries:
		var p := Vector3(rng.randf_range(region.position.x, region.end.x), 0, rng.randf_range(region.position.y, region.end.y))
		if free_at(p, r, road_m):
			return p
	return Vector3(-1, 0, -1)

func reserve(p: Vector3, r: float) -> void:
	keep.append([p, r])

# ------------------------------------------------------------ yapılar
func house_flat(c: Vector3, w: float, d: float, rows := 6, rot90 := false, col := WHITE) -> void:
	if rot90:
		var t := w
		w = d
		d = t
	var t2 := 0.42
	var top := rows * BH
	var roof := MeshInstance3D.new()
	var hid := B.new_house(c, Vector2(w, d), top, roof)
	var x0 := c.x - w * 0.5
	var x1 := c.x + w * 0.5
	var z0 := c.z - d * 0.5
	var z1 := c.z + d * 0.5
	var door_side := rng.randi() % 4
	var sides := [
		[Vector3(x0 - t2 * 0.5, 0, z0), Vector3(x1 + t2 * 0.5, 0, z0)],
		[Vector3(x0 - t2 * 0.5, 0, z1), Vector3(x1 + t2 * 0.5, 0, z1)],
		[Vector3(x0, 0, z0 + t2 * 0.5), Vector3(x0, 0, z1 - t2 * 0.5)],
		[Vector3(x1, 0, z0 + t2 * 0.5), Vector3(x1, 0, z1 - t2 * 0.5)]]
	for si in 4:
		var a: Vector3 = sides[si][0]
		var b: Vector3 = sides[si][1]
		var L := a.distance_to(b)
		var gaps: Array = []
		var nwin := int((L - 1.2) / 2.4)
		var door_at := -1
		if si == door_side and nwin >= 1:
			door_at = rng.randi() % maxi(nwin, 1)
		for i in nwin:
			var s := (i + 0.5) * (L / nwin)
			if i == door_at:
				gaps.append([s - 0.6, s + 0.6, 0, 4, true])
			else:
				gaps.append([s - 0.55, s + 0.55, 2, 3, true, rng.randf() < 0.5])
		B.wall_line(a, b, rows, col, Grid.K_HOUSE, {"len": 0.5, "h": BH, "t": t2, "gaps": gaps, "house": hid, "jit": 0.012, "type": Blocks.T_CONCRETE})
	# düz çatı + korkuluk + çatı eşyaları
	var mb := MB.new()
	var rc := Color(0.84, 0.83, 0.8)
	mb.box(Vector3(0, top + 0.1, 0), Vector3(w + 0.5, 0.2, d + 0.5), rc)
	var nx := int(w)
	var nz := int(d)
	for ix in nx:
		for iz in nz:
			if (ix + iz) % 2 == 0:
				mb.box(Vector3(-w * 0.5 + (ix + 0.5) * w / nx, top + 0.205, -d * 0.5 + (iz + 0.5) * d / nz), Vector3(w / nx * 0.96, 0.01, d / nz * 0.96), rc.darkened(0.05))
	var pc := Color(0.93, 0.92, 0.88)
	mb.box(Vector3(0, top + 0.35, -d * 0.5 - 0.12), Vector3(w + 0.5, 0.35, 0.26), pc)
	mb.box(Vector3(0, top + 0.35, d * 0.5 + 0.12), Vector3(w + 0.5, 0.35, 0.26), pc)
	mb.box(Vector3(-w * 0.5 - 0.12, top + 0.35, 0), Vector3(0.26, 0.35, d + 0.5), pc)
	mb.box(Vector3(w * 0.5 + 0.12, top + 0.35, 0), Vector3(0.26, 0.35, d + 0.5), pc)
	for i in rng.randi_range(1, 4):
		var px := rng.randf_range(-w * 0.35, w * 0.35)
		var pz := rng.randf_range(-d * 0.35, d * 0.35)
		match rng.randi() % 4:
			0:
				mb.cyl(Vector3(px, top + 0.2, pz), 0.42, 0.42, 0.9, 10, Color(0.85, 0.45, 0.2))
			1:
				mb.box(Vector3(px, top + 0.45, pz), Vector3(0.9, 0.5, 0.6), Color(0.7, 0.7, 0.7))
				mb.box(Vector3(px, top + 0.71, pz), Vector3(0.5, 0.02, 0.5), Color(0.25, 0.25, 0.25))
			2:
				mb.box(Vector3(px, top + 0.7, pz), Vector3(1.4, 1.0, 1.2), pc.darkened(0.04))
			3:
				mb.cyl(Vector3(px, top + 0.2, pz), 0.04, 0.03, 2.6, 4, Color(0.3, 0.3, 0.3))
	roof.mesh = mb.commit(Mats.vc())
	roof.position = Vector3(c.x, 0, c.z)
	B.add_child(roof)
	_floor(c, w, d)

func _floor(c: Vector3, w: float, d: float) -> void:
	var mb := MB.new()
	var n1 := int(w / 0.5)
	var n2 := int(d / 0.5)
	for ix in n1:
		for iz in n2:
			var col := Color(0.3, 0.3, 0.31) if (ix + iz) % 2 == 0 else Color(0.44, 0.43, 0.42)
			var x := -w * 0.5 + (ix + 0.5) * w / n1
			var z := -d * 0.5 + (iz + 0.5) * d / n2
			mb.box(Vector3(x, 0.02, z), Vector3(w / n1 * 0.94, 0.04, d / n2 * 0.94), col)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vc())
	mi.position = Vector3(c.x, 0, c.z)
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	B.add_child(mi)

func house_pitched(c: Vector3, w: float, d: float, rot90: bool, wall_col: Color, roof_col: Color, snow: bool, rows := 6) -> void:
	if rot90:
		var t := w
		w = d
		d = t
	var t2 := 0.42
	var top := rows * BH
	var roof := MeshInstance3D.new()
	var hid := B.new_house(c, Vector2(w, d), top, roof)
	var x0 := c.x - w * 0.5
	var x1 := c.x + w * 0.5
	var z0 := c.z - d * 0.5
	var z1 := c.z + d * 0.5
	var sides := [
		[Vector3(x0 - t2 * 0.5, 0, z0), Vector3(x1 + t2 * 0.5, 0, z0)],
		[Vector3(x0 - t2 * 0.5, 0, z1), Vector3(x1 + t2 * 0.5, 0, z1)],
		[Vector3(x0, 0, z0 + t2 * 0.5), Vector3(x0, 0, z1 - t2 * 0.5)],
		[Vector3(x1, 0, z0 + t2 * 0.5), Vector3(x1, 0, z1 - t2 * 0.5)]]
	var door_side := rng.randi() % 4
	for si in 4:
		var a: Vector3 = sides[si][0]
		var b: Vector3 = sides[si][1]
		var L := a.distance_to(b)
		var gaps: Array = []
		var nwin := int((L - 1.0) / 2.2)
		for i in nwin:
			var s := (i + 0.5) * (L / nwin)
			if si == door_side and i == 0:
				gaps.append([s - 0.55, s + 0.55, 0, 4, true])
			else:
				gaps.append([s - 0.5, s + 0.5, 2, 3, true, true])
		B.wall_line(a, b, rows, wall_col, Grid.K_HOUSE, {"len": 0.5, "h": BH, "t": t2, "gaps": gaps, "house": hid, "jit": 0.025, "type": Blocks.T_CONCRETE})
	roof.mesh = pitched_roof(w, d, top, roof_col, wall_col, snow)
	roof.position = Vector3(c.x, 0, c.z)
	B.add_child(roof)
	_floor(c, w, d)

func pitched_roof(w: float, d: float, top: float, col: Color, wall_col: Color, snow: bool) -> ArrayMesh:
	var mb := MB.new()
	var along_z := d >= w
	var hw := (w if along_z else d) * 0.5
	var hl := (d if along_z else w) * 0.5
	var ov := 0.38
	var rh := hw * 0.75
	var bas := Basis() if along_z else Basis(Vector3.UP, PI * 0.5)
	var fn := FastNoiseLite.new()
	fn.seed = rng.randi()
	fn.frequency = 0.09
	fn.fractal_octaves = 3
	var nu := 22
	var nv := maxi(12, int(hl * 2.0 / 0.18))
	for side in [-1.0, 1.0]:
		for iu in nu:
			for iv in nv:
				var u0 := float(iu) / nu
				var u1 := float(iu + 1) / nu
				var v0 := -hl - ov + (hl + ov) * 2.0 * iv / nv
				var v1 := -hl - ov + (hl + ov) * 2.0 * (iv + 1) / nv
				var x0 = side * (hw + ov) * (1.0 - u0)
				var x1 = side * (hw + ov) * (1.0 - u1)
				var y0 := top - ov * rh / hw + (rh + ov * rh / hw) * u0
				var y1 := top - ov * rh / hw + (rh + ov * rh / hw) * u1
				var cc := MB.jit(col, rng, 0.05)
				if iv % 2 == 0:
					cc = cc.darkened(0.04)
				if snow:
					var n := fn.get_noise_2d(iu * 1.0 + side * 37.0, iv * 1.0)
					if n > -0.22:
						cc = Color(0.94, 0.95, 0.97).darkened(0.02 * iu)
				var a := bas * Vector3(x0, y0, v0)
				var b := bas * Vector3(x1, y1, v0)
				var c2 := bas * Vector3(x1, y1, v1)
				var dd := bas * Vector3(x0, y0, v1)
				var n2 := bas * Vector3(side * rh, hw, 0).normalized()
				mb.quad(a, b, c2, dd, cc, n2)
	# alın (üçgen) duvarlar
	for e in [-1.0, 1.0]:
		var p0 := bas * Vector3(-hw, top, e * hl)
		var p1 := bas * Vector3(hw, top, e * hl)
		var p2 := bas * Vector3(0, top + rh, e * hl)
		mb.tri(p0, p1, p2, wall_col.darkened(0.05), bas * Vector3(0, 0, e))
	# saçak altı koyu kenar
	for side in [-1.0, 1.0]:
		var ex := bas * Vector3(side * (hw + ov), top - ov * rh / hw - 0.06, 0)
		mb.box(ex, (Vector3(0.08, 0.12, (hl + ov) * 2.0) if along_z else Vector3((hl + ov) * 2.0, 0.12, 0.08)), Color(0.25, 0.22, 0.2))
	# baca
	var chx := rng.randf_range(-hl * 0.5, hl * 0.5)
	mb.box(bas * Vector3(hw * 0.4, top + rh * 0.8, chx), Vector3(0.55, 1.3, 0.55), Color(0.55, 0.25, 0.18))
	mb.box(bas * Vector3(hw * 0.4, top + rh * 0.8 + 0.66, chx), Vector3(0.62, 0.06, 0.62), Color(0.95, 0.95, 0.97) if snow else Color(0.4, 0.2, 0.15))
	return mb.commit(Mats.vc())

func wall(a: Vector3, b: Vector3, rows: int, ruin := 0.0, col := STONE) -> void:
	B.wall_line(a, b, rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.52, "ruin": ruin, "jit": 0.07})

func ruin_cluster(c: Vector3) -> void:
	var t := rng.randi() % 5
	var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
	var bx := Vector3(-ax.z, 0, ax.x)
	var L1 := rng.randf_range(2.5, 6.0)
	var L2 := rng.randf_range(2.0, 5.0)
	var rows := rng.randi_range(2, 5)
	var ruin := rng.randf_range(0.2, 0.75)
	match t:
		0:
			wall(c, c + ax * L1, rows, ruin)
			wall(c + bx * 0.6, c + bx * L2, rows, ruin)
		1:
			wall(c, c + ax * L1, rows, ruin)
			wall(c + bx * 0.6, c + bx * L2, rows, ruin)
			wall(c + ax * L1 + bx * 0.6, c + ax * L1 + bx * L2, rows - 1, ruin)
		2:
			wall(c, c + ax * L1, rng.randi_range(1, 3), ruin * 0.6)
		3:
			wall(c, c + ax * L1, 2, 0.1)
			wall(c + bx * 3.0, c + bx * 3.0 + ax * L1 * 0.7, 2, 0.3)
		4:
			for i in rng.randi_range(3, 8):
				var p := c + Vector3(rng.randf_range(-1.5, 1.5), 0.23, rng.randf_range(-1.5, 1.5))
				var id := B.add_block(p, Vector3(0.62, 0.46, 0.52), rng.randf() * TAU, MB.jit(STONE, rng, 0.08), Blocks.T_BOX, -1, 0, Grid.K_WALL, rng.randf() < 0.5)
				if rng.randf() < 0.4:
					B.add_block(p + Vector3(rng.randf_range(-0.2, 0.2), 0.46, rng.randf_range(-0.2, 0.2)), Vector3(0.62, 0.46, 0.52), rng.randf() * TAU, MB.jit(STONE, rng, 0.08), Blocks.T_BOX, -1, 1, Grid.K_WALL, false)
				var _u := id

func compound(c: Vector3, w: float, d: float, rows: int, gate_side: int, col := STONE) -> void:
	var x0 := c.x - w * 0.5
	var x1 := c.x + w * 0.5
	var z0 := c.z - d * 0.5
	var z1 := c.z + d * 0.5
	var segs := [[Vector3(x0, 0, z0), Vector3(x1, 0, z0)], [Vector3(x1, 0, z0), Vector3(x1, 0, z1)], [Vector3(x1, 0, z1), Vector3(x0, 0, z1)], [Vector3(x0, 0, z1), Vector3(x0, 0, z0)]]
	for i in 4:
		var a: Vector3 = segs[i][0]
		var b: Vector3 = segs[i][1]
		if i == gate_side:
			var m := (a + b) * 0.5
			var dir := (b - a).normalized()
			B.wall_line(a, m - dir * 2.0, rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.5, "jit": 0.05})
			B.wall_line(m + dir * 2.0, b, rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.5, "jit": 0.05})
		else:
			B.wall_line(a, b, rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.5, "jit": 0.05, "ruin": rng.randf_range(0.0, 0.3)})

func fence(a: Vector3, b: Vector3, col := Color(0.88, 0.86, 0.8)) -> void:
	var L := a.distance_to(b)
	var n := maxi(1, int(L / 2.0))
	var dir := (b - a) / L
	var rot := atan2(-dir.z, dir.x)
	var w := B.new_wall()
	for i in n:
		var s := (i + 0.5) * L / n
		if rng.randf() < 0.07:
			continue
		B.add_block(a + dir * s + Vector3(0, 0.55, 0), Vector3(L / n, 1.1, 1.0), rot, MB.jit(col, rng, 0.05), Blocks.T_FENCE, w, 0, Grid.K_WALL, false)

# ------------------------------------------------------------ çöl haritası
func _desert() -> void:
	_desert_extras()
	G.hq_pos = [Vector3(214, 0, 214), Vector3(42, 0, 42)]
	reserve(G.hq_pos[0], 26)
	reserve(G.hq_pos[1], 26)
	road([Vector3(250, 0, 246), Vector3(222, 0, 222), Vector3(196, 0, 204), Vector3(170, 0, 176), Vector3(140, 0, 150), Vector3(126, 0, 128), Vector3(104, 0, 98), Vector3(76, 0, 80), Vector3(56, 0, 52), Vector3(26, 0, 30), Vector3(4, 0, 8)], 6.5)
	road([Vector3(20, 0, 236), Vector3(62, 0, 196), Vector3(98, 0, 160), Vector3(126, 0, 128), Vector3(156, 0, 98), Vector3(196, 0, 62), Vector3(236, 0, 20)], 6.0)
	road([Vector3(150, 0, 150), Vector3(170, 0, 128), Vector3(200, 0, 120), Vector3(232, 0, 104)], 5.0)
	road([Vector3(104, 0, 98), Vector3(86, 0, 124), Vector3(56, 0, 140), Vector3(24, 0, 150)], 5.0)
	# eski izler
	for i in 26:
		var a := Vector3(rng.randf_range(0, 256), 0, rng.randf_range(0, 256))
		var dir := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		var pts: Array = [a]
		for k in 5:
			dir = (dir + Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))).normalized()
			pts.append(pts[pts.size() - 1] + dir * rng.randf_range(15, 35))
		var sp := _spline(pts, 2.0)
		for j in sp.size() - 1:
			var d := (sp[j + 1] - sp[j]).normalized()
			var side := Vector3(-d.z, 0, d.x)
			for s in [-1.4, 1.4]:
				T.paint_line(sp[j] + side * s, sp[j + 1] + side * s, 0.55, 1, 0.32)
	# merkez kasaba
	var town := Vector3(128, 0, 128)
	var spots := [[Vector3(114, 0, 116), 8.0, 6.0], [Vector3(141, 0, 116), 7.0, 6.0], [Vector3(114, 0, 141), 7.0, 7.0], [Vector3(142, 0, 141), 9.0, 6.0],
		[Vector3(100, 0, 128), 6.0, 5.0], [Vector3(156, 0, 128), 6.0, 6.0], [Vector3(128, 0, 102), 6.0, 5.0], [Vector3(128, 0, 156), 7.0, 5.0],
		[Vector3(96, 0, 106), 6.0, 5.0], [Vector3(160, 0, 150), 6.0, 5.0], [Vector3(150, 0, 104), 5.0, 5.0], [Vector3(104, 0, 152), 6.0, 5.0],
		[Vector3(178, 0, 140), 6.0, 5.0], [Vector3(78, 0, 116), 6.0, 5.0]]
	for s in spots:
		var p: Vector3 = s[0]
		var w: float = s[1]
		var d: float = s[2]
		var rot := rng.randf() < 0.5
		var r := maxf(w, d) * 0.75
		if not free_at(p, r, 1.5):
			p = rand_free(r, 40, Rect2(p.x - 14, p.z - 14, 28, 28), 1.5)
			if p.x < 0:
				continue
		if rng.randf() < 0.22:
			house_pitched(p, w, d, rot, WHITE, Color(0.62, 0.5, 0.35), false)
		else:
			house_flat(p, w, d, rng.randi_range(5, 7), rot)
		reserve(p, r + 1.0)
		if rng.randf() < 0.55:
			var cw := w + rng.randf_range(5, 8)
			var cd := d + rng.randf_range(5, 8)
			if rot:
				var tt := cw
				cw = cd
				cd = tt
			var cp := p + Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1))
			if road_dist(cp) > maxf(cw, cd) * 0.5 + 1.5:
				compound(cp, cw, cd, rng.randi_range(3, 5), rng.randi() % 4)
				reserve(cp, maxf(cw, cd) * 0.6)
	# karargah yakın binalar (kenarda büyük yapı)
	for i in 6:
		var p := rand_free(4.0, 50, Rect2(170, 30, 70, 70), 2.0)
		if p.x > 0:
			house_flat(p, rng.randf_range(5, 8), rng.randf_range(4, 6), 5, rng.randf() < 0.5)
			reserve(p, 6)
		p = rand_free(4.0, 50, Rect2(30, 170, 70, 70), 2.0)
		if p.x > 0:
			house_flat(p, rng.randf_range(5, 8), rng.randf_range(4, 6), 5, rng.randf() < 0.5)
			reserve(p, 6)
	# ileri üs noktaları (boş bırak)
	G.fob_sites = [Vector3(186, 0, 160), Vector3(160, 0, 188), Vector3(196, 0, 128), Vector3(128, 0, 196),
		Vector3(70, 0, 96), Vector3(96, 0, 70), Vector3(60, 0, 128), Vector3(128, 0, 60),
		Vector3(160, 0, 66), Vector3(66, 0, 160), Vector3(126, 0, 128)]
	for i in G.fob_sites.size() - 1:
		reserve(G.fob_sites[i], 9.0)
	# yıkıntılar
	for i in 70:
		var p := rand_free(3.0, 30)
		if p.x > 0:
			ruin_cluster(p)
			reserve(p, 4.5)
	# alçak tarla duvarları
	for i in 24:
		var p := rand_free(4.0, 30)
		if p.x > 0:
			var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
			var L := rng.randf_range(5, 12)
			wall(p, p + ax * L, rng.randi_range(2, 3), rng.randf_range(0.0, 0.35))
			reserve(p + ax * L * 0.5, L * 0.5 + 1.0)
	# palmiye kümeleri
	for g in 9:
		var c := rand_free(5.0, 40, Rect2(10, 10, 236, 236), 2.0)
		if c.x < 0:
			continue
		for i in rng.randi_range(4, 11):
			var p := c + Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7))
			if free_at(p, 0.6, 1.5):
				P.palm(p)
	for i in 70:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			if rng.randf() < 0.82:
				P.palm(p)
			else:
				P.tree(p)
	# direkler yol boyunca
	_poles_along(roads[0], 16.0, 5.5)
	_poles_along(roads[1], 18.0, 5.0)
	# sivil arabalar, tenteler
	for i in 26:
		var p := rand_free(2.2, 30, Rect2(80, 80, 96, 96), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			P.car(p, rng.randf() * TAU)
	for i in 10:
		var p := rand_free(2.0, 30, Rect2(30, 30, 196, 196), 1.0)
		if p.x > 0:
			P.car(p, rng.randf() * TAU)
	for i in 12:
		var p := rand_free(1.6, 30, Rect2(90, 90, 76, 76), 1.0)
		if p.x > 0:
			P.canopy(p, rng.randf() * TAU)
	# eski kraterler
	for i in 40:
		var p := Vector3(rng.randf_range(60, 196), 0, rng.randf_range(60, 196))
		if road_dist(p) > 3.0:
			var s := rng.randf_range(2.0, 4.5)
			G.fx.crater(p, s)
			T.paint_circle(p, s * 0.7, 2, 0.3)

func _poles_along(pts: PackedVector3Array, spacing: float, off: float) -> void:
	var acc := 0.0
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var L := a.distance_to(b)
		var d := (b - a) / maxf(L, 0.001)
		var side := Vector3(-d.z, 0, d.x)
		var s := 0.0
		while s < L:
			if acc >= spacing:
				acc = 0.0
				var p := a + d * s + side * off
				if G.grid.height_at(p) < 0.1 and p.x > 2 and p.z > 2 and p.x < 254 and p.z < 254:
					P.pole(p, rng.randf() < 0.25)
			s += 1.0
			acc += 1.0

# ------------------------------------------------------------ kış haritası
func _winter() -> void:
	G.hq_pos = [Vector3(214, 0, 214), Vector3(42, 0, 42)]
	reserve(G.hq_pos[0], 26)
	reserve(G.hq_pos[1], 26)
	road([Vector3(250, 0, 240), Vector3(214, 0, 214), Vector3(180, 0, 176), Vector3(150, 0, 140), Vector3(128, 0, 128), Vector3(104, 0, 106), Vector3(74, 0, 76), Vector3(42, 0, 42), Vector3(6, 0, 10)], 6.0)
	road([Vector3(8, 0, 128), Vector3(60, 0, 128), Vector3(128, 0, 128), Vector3(196, 0, 128), Vector3(250, 0, 128)], 6.0)
	road([Vector3(128, 0, 8), Vector3(128, 0, 70), Vector3(128, 0, 128), Vector3(128, 0, 190), Vector3(128, 0, 250)], 6.0)
	road([Vector3(80, 0, 100), Vector3(100, 0, 160), Vector3(160, 0, 176)], 5.0)
	var wall_cols := [Color(0.88, 0.85, 0.72), Color(0.76, 0.82, 0.68), Color(0.9, 0.86, 0.66), Color(0.82, 0.78, 0.7), Color(0.86, 0.84, 0.8)]
	var roof_cols := [Color(0.52, 0.18, 0.12), Color(0.22, 0.38, 0.26), Color(0.42, 0.3, 0.18), Color(0.4, 0.42, 0.45), Color(0.48, 0.35, 0.22)]
	# yollar boyunca evler (bahçe çitli)
	var placed := 0
	for r in roads:
		var pts: PackedVector3Array = r
		var i := 2
		while i < pts.size() - 2:
			var a := pts[i]
			var b := pts[i + 1]
			var d := (b - a).normalized()
			var side := Vector3(-d.z, 0, d.x)
			for sg in [-1.0, 1.0]:
				if rng.randf() < 0.42:
					continue
				var w := rng.randf_range(6.0, 9.0)
				var dd := rng.randf_range(5.0, 7.0)
				var p = a + side * sg * (dd * 0.5 + 6.5)
				p.x = snappedf(p.x, 0.5)
				p.z = snappedf(p.z, 0.5)
				if not free_at(p, maxf(w, dd) * 0.6 + 1.0, 2.0):
					continue
				var rot := absf(d.x) > absf(d.z)
				var wc: Color = wall_cols[rng.randi() % wall_cols.size()]
				house_pitched(p, w, dd, not rot, wc, roof_cols[rng.randi() % roof_cols.size()], true)
				reserve(p, maxf(w, dd) * 0.6 + 2.0)
				placed += 1
				# çit
				var fw := w + 6.0
				var fd := dd + 6.0
				if rot:
					var tt := fw
					fw = fd
					fd = tt
				var x0 = p.x - fd * 0.5 if rot else p.x - fw * 0.5
				var x1 = p.x + fd * 0.5 if rot else p.x + fw * 0.5
				var z0 = p.z - fw * 0.5 if rot else p.z - fd * 0.5
				var z1 = p.z + fw * 0.5 if rot else p.z + fd * 0.5
				if rng.randf() < 0.75:
					var fpts := [Vector3(x0, 0, z0), Vector3(x1, 0, z0), Vector3(x1, 0, z1), Vector3(x0, 0, z1)]
					for k in 4:
						var fa: Vector3 = fpts[k]
						var fb: Vector3 = fpts[(k + 1) % 4]
						var mid := (fa + fb) * 0.5
						if road_dist(mid) > 3.4 and rng.randf() < 0.85:
							fence(fa, fb)
				if rng.randf() < 0.5:
					var sp = p + side * sg * (dd * 0.5 + 3.0) + d * rng.randf_range(-4, 4)
					if free_at(sp, 1.6, 2.0):
						P.shed(sp, rng.randf() * TAU)
						reserve(sp, 2.0)
			i += 3
	# karlı tuğla duvar parçaları
	for i in 46:
		var p := rand_free(2.5, 30)
		if p.x > 0:
			_snow_brick_wall(p)
			reserve(p, 3.5)
	# ileri üs noktaları
	G.fob_sites = [Vector3(186, 0, 160), Vector3(160, 0, 188), Vector3(196, 0, 100), Vector3(100, 0, 196),
		Vector3(70, 0, 96), Vector3(96, 0, 70), Vector3(60, 0, 156), Vector3(156, 0, 60),
		Vector3(170, 0, 40), Vector3(40, 0, 170), Vector3(140, 0, 116)]
	for i in G.fob_sites.size():
		reserve(G.fob_sites[i], 8.0)
	# ağaçlar
	for g in 16:
		var c := rand_free(4.0, 40, Rect2(8, 8, 240, 240), 2.0)
		if c.x < 0:
			continue
		var conifer := rng.randf() < 0.55
		for i in rng.randi_range(4, 10):
			var p := c + Vector3(rng.randf_range(-8, 8), 0, rng.randf_range(-8, 8))
			if free_at(p, 0.8, 1.5):
				if conifer:
					P.pine(p)
				else:
					P.tree(p)
	for i in 110:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			P.tree(p)
	# taş duvar yıkıntıları
	for i in 26:
		var p := rand_free(3.0, 30)
		if p.x > 0:
			ruin_cluster(p)
			reserve(p, 4.5)
	_poles_along(roads[0], 17.0, 5.0)
	_poles_along(roads[1], 17.0, 5.0)
	_poles_along(roads[2], 17.0, 5.0)
	for i in 14:
		var p := rand_free(2.2, 30, Rect2(60, 60, 136, 136), 0.0)
		if p.x > 0 and road_dist(p) < 8.0:
			P.car(p, rng.randf() * TAU)
	for i in 20:
		var p := Vector3(rng.randf_range(60, 196), 0, rng.randf_range(60, 196))
		if road_dist(p) > 3.0:
			var s := rng.randf_range(2.0, 4.0)
			G.fx.crater(p, s)
			T.paint_circle(p, s * 0.6, 2, 0.3)


# ------------------------------------------------------------ ortak süs: çöl
func _desert_extras() -> void:
	pass

func _ruins_and_walls(n_ruins: int, n_walls: int, col := STONE) -> void:
	for i in n_ruins:
		var p := rand_free(3.0, 30)
		if p.x > 0:
			ruin_cluster(p)
			reserve(p, 4.5)
	for i in n_walls:
		var p := rand_free(4.0, 30)
		if p.x > 0:
			var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
			var L := rng.randf_range(5, 12)
			wall(p, p + ax * L, rng.randi_range(2, 3), rng.randf_range(0.0, 0.35), col)
			reserve(p + ax * L * 0.5, L * 0.5 + 1.0)

func _town(c: Vector3, radius: float, n: int, flat := true) -> void:
	for i in n:
		var w := rng.randf_range(5.5, 9.0)
		var d := rng.randf_range(5.0, 7.0)
		var r := maxf(w, d) * 0.75
		var p := rand_free(r, 40, Rect2(c.x - radius, c.z - radius, radius * 2, radius * 2), 1.5)
		if p.x < 0:
			continue
		var rot := rng.randf() < 0.5
		if flat and rng.randf() > 0.2:
			house_flat(p, w, d, rng.randi_range(5, 7), rot)
		else:
			house_pitched(p, w, d, rot, WHITE, Color(0.62, 0.5, 0.35) if kind == "desert" else Color(0.5, 0.2, 0.14), kind == "winter")
		reserve(p, r + 1.0)
		if rng.randf() < 0.45:
			var cw := w + rng.randf_range(5, 8)
			var cd := d + rng.randf_range(5, 8)
			if rot:
				var tt := cw
				cw = cd
				cd = tt
			if road_dist(p) > maxf(cw, cd) * 0.5 + 1.5:
				compound(p, cw, cd, rng.randi_range(3, 5), rng.randi() % 4)
				reserve(p, maxf(cw, cd) * 0.6)

# ------------------------------------------------------------ Çöl Kanalı
func _desert_canal() -> void:
	G.hq_pos = [Vector3(214, 0, 214), Vector3(42, 0, 42)]
	reserve(G.hq_pos[0], 26)
	reserve(G.hq_pos[1], 26)
	var canal := river([Vector3(-10, 0, 60), Vector3(60, 0, 98), Vector3(110, 0, 120), Vector3(150, 0, 136), Vector3(205, 0, 160), Vector3(266, 0, 196)], 11.0, 1.8)
	road([Vector3(250, 0, 246), Vector3(214, 0, 214), Vector3(180, 0, 186), Vector3(150, 0, 156), Vector3(128, 0, 128), Vector3(100, 0, 96), Vector3(70, 0, 66), Vector3(42, 0, 42), Vector3(6, 0, 8)], 6.5)
	road([Vector3(236, 0, 70), Vector3(200, 0, 110), Vector3(176, 0, 132), Vector3(150, 0, 190), Vector3(120, 0, 236)], 5.5)
	road([Vector3(20, 0, 160), Vector3(54, 0, 118), Vector3(74, 0, 96), Vector3(100, 0, 52), Vector3(110, 0, 10)], 5.5)
	auto_bridges()
	# kanal kıyısı: palmiye sırası ve çalı
	P.reeds_along(canal, 5.5)
	for i in range(0, canal.size() - 1, 2):
		var a := canal[i]
		var b := canal[i + 1]
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		for sg in [-1.0, 1.0]:
			if rng.randf() < 0.42:
				var q: Vector3 = a + side * sg * rng.randf_range(9.0, 12.0)
				if free_at(q, 0.6, 1.5):
					P.palm(q)
	# kasabalar
	_town(Vector3(176, 0, 92), 22, 7, true)
	_town(Vector3(84, 0, 168), 22, 7, true)
	_town(Vector3(196, 0, 196), 14, 3, true)
	_town(Vector3(60, 0, 60), 14, 3, true)
	G.fob_sites = [Vector3(186, 0, 160), Vector3(160, 0, 196), Vector3(206, 0, 124), Vector3(140, 0, 160), Vector3(70, 0, 96), Vector3(96, 0, 64),
		Vector3(50, 0, 128), Vector3(116, 0, 92), Vector3(176, 0, 60), Vector3(84, 0, 200)]
	for s in G.fob_sites:
		reserve(s, 9.0)
	_ruins_and_walls(80, 26)
	for g in 8:
		var c := rand_free(5.0, 40, Rect2(10, 10, 236, 236), 2.0)
		if c.x < 0:
			continue
		for i in rng.randi_range(4, 10):
			var p := c + Vector3(rng.randf_range(-7, 7), 0, rng.randf_range(-7, 7))
			if free_at(p, 0.6, 1.5):
				P.palm(p)
	for i in 50:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			if rng.randf() < 0.8:
				P.palm(p)
			else:
				P.tree(p)
	_poles_along(roads[0], 16.0, 5.5)
	for i in 22:
		var p := rand_free(2.2, 30, Rect2(30, 30, 196, 196), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			P.car(p, rng.randf() * TAU)
	for i in 10:
		var p := rand_free(1.6, 30, Rect2(40, 40, 176, 176), 1.0)
		if p.x > 0:
			P.canopy(p, rng.randf() * TAU)
	for i in 30:
		var p := Vector3(rng.randf_range(50, 206), 0, rng.randf_range(50, 206))
		if road_dist(p) > 3.0 and T.ground_h(p) > -0.05:
			var s := rng.randf_range(2.0, 4.0)
			G.fx.crater(p, s)
	_tracks(30, 0.3)
	P.grass_field(900, Color(0.55, 0.48, 0.3), Rect2(2, 2, 252, 252), 0.4)

func _tracks(n: int, amt: float) -> void:
	for i in n:
		var a := Vector3(rng.randf_range(0, 256), 0, rng.randf_range(0, 256))
		var dir := Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
		var pts: Array = [a]
		for k in 5:
			dir = (dir + Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5))).normalized()
			pts.append(pts[pts.size() - 1] + dir * rng.randf_range(15, 35))
		var sp := _spline(pts, 2.0)
		for j in sp.size() - 1:
			var d := (sp[j + 1] - sp[j]).normalized()
			var side := Vector3(-d.z, 0, d.x)
			for s in [-1.4, 1.4]:
				T.paint_line(sp[j] + side * s, sp[j + 1] + side * s, 0.55, 1, amt)

# ------------------------------------------------------------ Yeşil Vadi
func _green_valley() -> void:
	G.hq_pos = [Vector3(214, 0, 214), Vector3(42, 0, 42)]
	reserve(G.hq_pos[0], 26)
	reserve(G.hq_pos[1], 26)
	var riv := river([Vector3(-10, 0, 200), Vector3(40, 0, 170), Vector3(80, 0, 150), Vector3(108, 0, 118), Vector3(140, 0, 104), Vector3(180, 0, 70), Vector3(215, 0, 40), Vector3(266, 0, 20)], 13.0, 1.9)
	road([Vector3(250, 0, 246), Vector3(214, 0, 214), Vector3(186, 0, 170), Vector3(160, 0, 150), Vector3(150, 0, 132), Vector3(124, 0, 112), Vector3(96, 0, 100), Vector3(70, 0, 80), Vector3(42, 0, 42), Vector3(6, 0, 8)], 5.5)
	road([Vector3(96, 0, 100), Vector3(104, 0, 62), Vector3(110, 0, 30), Vector3(96, 0, 4)], 4.5)
	road([Vector3(160, 0, 150), Vector3(176, 0, 196), Vector3(150, 0, 230), Vector3(128, 0, 252)], 4.5)
	auto_bridges()
	P.reeds_along(riv, 6.5)
	# çayır yamaları (toprak/çim)
	for i in 70:
		T.patch_blob(Vector3(rng.randf_range(0, 256), 0, rng.randf_range(0, 256)), rng.randf_range(4, 14), rng.randf_range(0.5, 1.0))
	G.fob_sites = [Vector3(186, 0, 160), Vector3(160, 0, 188), Vector3(196, 0, 128), Vector3(128, 0, 196), Vector3(70, 0, 96), Vector3(96, 0, 70),
		Vector3(60, 0, 128), Vector3(150, 0, 60), Vector3(84, 0, 196), Vector3(200, 0, 96)]
	for s in G.fob_sites:
		reserve(s, 9.0)
	# küçük çiftlik yıkıntıları (kiremit/tuğla tonları)
	for i in 34:
		var p := rand_free(3.0, 30)
		if p.x > 0:
			_brick_ruin(p, Color(0.78, 0.5, 0.36))
			reserve(p, 4.0)
	_town(Vector3(176, 0, 120), 16, 4, false)
	_town(Vector3(70, 0, 130), 16, 4, false)
	# ağaçlıklar
	for g in 22:
		var c := rand_free(5.0, 40, Rect2(8, 8, 240, 240), 2.0)
		if c.x < 0:
			continue
		for i in rng.randi_range(5, 12):
			var p := c + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10))
			if free_at(p, 0.7, 1.5):
				P.tree(p)
		for i in rng.randi_range(6, 14):
			var p := c + Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-13, 13))
			if free_at(p, 0.6, 1.0):
				P.bush(p, rng.randf() < 0.3)
	for i in 120:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.0)
		if p.x > 0:
			var r := rng.randf()
			if r < 0.35:
				P.tree(p)
			elif r < 0.8:
				P.bush(p)
			else:
				P.rock(p, rng.randf_range(0.6, 1.3))
	for i in 30:
		var p := rand_free(1.0, 20, Rect2(20, 20, 216, 216), 2.0)
		if p.x > 0:
			P.hay(p)
	_poles_along(roads[0], 18.0, 5.0)
	for i in 8:
		var p := rand_free(2.2, 30, Rect2(30, 30, 196, 196), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			P.car(p, rng.randf() * TAU)
	_tracks(14, 0.25)
	P.grass_field(16000, Color(0.42, 0.55, 0.24), Rect2(2, 2, 252, 252), 0.5)

func _brick_ruin(c: Vector3, col: Color) -> void:
	var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
	var bx := Vector3(-ax.z, 0, ax.x)
	var L1 := rng.randf_range(2.5, 5.0)
	var L2 := rng.randf_range(2.0, 4.0)
	var rows := rng.randi_range(2, 4)
	var ruin := rng.randf_range(0.3, 0.8)
	B.wall_line(c, c + ax * L1, rows, col, Grid.K_WALL, {"len": 0.7, "h": 0.5, "t": 0.6, "ruin": ruin, "jit": 0.12})
	if rng.randf() < 0.7:
		B.wall_line(c + bx * 0.7, c + bx * L2, rows, col, Grid.K_WALL, {"len": 0.7, "h": 0.5, "t": 0.6, "ruin": ruin, "jit": 0.12})


func _snow_brick_wall(c: Vector3) -> void:
	var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
	var L := rng.randf_range(1.6, 4.0)
	var rows := rng.randi_range(3, 5)
	var a := c
	var b := c + ax * L
	B.wall_line(a, b, rows, Color(0.5, 0.26, 0.2), Grid.K_WALL, {"len": 0.55, "h": 0.36, "t": 0.6, "jit": 0.14, "ruin": rng.randf_range(0.0, 0.3)})
	# kar başlığı
	B.wall_line(a + Vector3(0, rows * 0.36, 0), b + Vector3(0, rows * 0.36, 0), 1, Color(0.95, 0.96, 0.99), Grid.K_WALL, {"len": 0.55, "h": 0.14, "t": 0.66, "jit": 0.02, "solid": false, "y0": 0.0})
	# dibinde kar yığını
	B.wall_line(a + Vector3(0, 0, 0), b, 1, Color(0.95, 0.96, 0.99), Grid.K_WALL, {"len": 0.8, "h": 0.12, "t": 1.4, "jit": 0.02, "solid": false})
