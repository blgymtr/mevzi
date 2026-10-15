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
var ops: Array = []          # kayıtlı yerleştirme işlemleri (harita dosyası / editör)
var _depth := 0
var data_in: Dictionary = {}
const MAPS := {
	"desert_canal": {"title": "Çöl Kanalı", "biome": "desert", "desc": "Turkuaz bir sulama kanalı iki orduyu ayırıyor. Üç köprüyü tutan kazanır."},
	"green_valley": {"title": "Yeşil Vadi", "biome": "green", "desc": "Kıvrılan nehir, toprak yollar ve tek taş köprü. Ağaçlıklar pusu için ideal."},
	"winter_village": {"title": "Karlı Köy", "biome": "winter", "desc": "Karla kaplı köy, tuğla duvarlar ve kazılmış siperler."},
	"big_city": {"title": "Büyük Şehir", "biome": "green", "size": 512, "desc": "512 m: nehirle bölünmüş şehir, sokak sokak girilebilir binalar, sanayi bölgesi ve dış mahalleler."},
	"large_front": {"title": "Geniş Cephe", "biome": "green", "size": 1024, "desc": "1 km: büyük nehir ve kolu, otoyol, altı köy, ormanlar ve tarlalar. Helikopter, hava indirme ve uzun menzilli topçu için."},
	"desert_town": {"title": "Çöl Kasabası", "biome": "desert", "desc": "Düz çatılı beyaz evler ve yıkıntılarla dolu kasabada sokak sokak savaş."},
}

const STONE := Color(0.9, 0.8, 0.62)
const WHITE := Color(0.94, 0.93, 0.89)
const FACADES := [Color(0.86, 0.72, 0.5), Color(0.9, 0.82, 0.62), Color(0.82, 0.6, 0.5), Color(0.62, 0.7, 0.78), Color(0.88, 0.86, 0.78),
	Color(0.78, 0.68, 0.56), Color(0.92, 0.88, 0.8), Color(0.72, 0.56, 0.42), Color(0.55, 0.62, 0.66), Color(0.86, 0.78, 0.68)]
const ROOFS := [Color(0.62, 0.28, 0.16), Color(0.55, 0.24, 0.15), Color(0.68, 0.35, 0.2), Color(0.42, 0.3, 0.26), Color(0.5, 0.42, 0.38)]

func facade() -> Color:
	if kind == "desert":
		return [WHITE, Color(0.9, 0.84, 0.72), Color(0.86, 0.78, 0.64)][rng.randi() % 3]
	return FACADES[rng.randi() % FACADES.size()].darkened(rng.randf_range(0.0, 0.08))

func roof_col() -> Color:
	if kind == "desert":
		return Color(0.62, 0.5, 0.35)
	return ROOFS[rng.randi() % ROOFS.size()]
const BH := 0.42

func build(id: String, seed_v: int) -> void:
	map_id = id
	kind = String(data_in.get("biome", "desert")) if id == "custom" else MAPS[id]["biome"]
	rng.seed = seed_v
	B = G.blocks
	P = G.props
	T = G.terrain
	P.winter = kind == "winter"
	P.biome_id = kind
	ops.clear()
	if id == "custom":
		build_ops(data_in)
	match id:
		"custom":
			pass
		"desert_canal":
			_desert_canal()
		"green_valley":
			_green_valley()
		"winter_village":
			_winter()
		"big_city":
			_city()
		"large_front":
			MapGenLarge.new().build(self)
		_:
			_desert()
	if id != "custom" and id != "big_city":
		_footpaths()
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

func _x_road(ctrl: Array, w := 6.0) -> PackedVector3Array:
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

func _x_river(ctrl: Array, w: float, depth := 1.7) -> PackedVector3Array:
	var pts := _spline(ctrl, 2.0)
	rivers.append([pts, w])
	T.carve(pts, w, depth)
	return pts

# yol-nehir kesişimlerine köprü
func _x_auto_bridges() -> void:
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

# ---- parça kovası: büyük haritada yol/nehir mesafesi her çağrıda tüm noktaları taramasın
const SEG_CELL := 24.0
var _seg_road := {}
var _seg_road_n := -1
var _seg_riv := {}
var _seg_riv_n := -1

func _seg_index(lines: Array, with_w: bool) -> Dictionary:
	var out := {}
	for ln in lines:
		var pts: PackedVector3Array = ln[0] if with_w else ln
		var w: float = ln[1] if with_w else 0.0
		for i in pts.size() - 1:
			var a := Vector2(pts[i].x, pts[i].z)
			var b := Vector2(pts[i + 1].x, pts[i + 1].z)
			var c0 := Vector2i(int(minf(a.x, b.x) / SEG_CELL), int(minf(a.y, b.y) / SEG_CELL))
			var c1 := Vector2i(int(maxf(a.x, b.x) / SEG_CELL), int(maxf(a.y, b.y) / SEG_CELL))
			for cz in range(c0.y, c1.y + 1):
				for cx in range(c0.x, c1.x + 1):
					var k := Vector2i(cx, cz)
					if not out.has(k):
						out[k] = []
					out[k].append([a, b, w])
	return out

func _seg_near(idx: Dictionary, p: Vector3, reach: int) -> float:
	# en yakın parçaya uzaklık − (nehirse) yarı genişlik; menzil dışında 1e9
	var q := Vector2(p.x, p.z)
	var c := Vector2i(int(p.x / SEG_CELL), int(p.z / SEG_CELL))
	var best := 1e9
	for dz in range(-reach, reach + 1):
		for dx in range(-reach, reach + 1):
			var arr = idx.get(c + Vector2i(dx, dz))
			if arr == null:
				continue
			for sg in arr:
				var a: Vector2 = sg[0]
				var ab: Vector2 = sg[1] - a
				var t := clampf((q - a).dot(ab) / maxf(ab.length_squared(), 1e-5), 0.0, 1.0)
				best = minf(best, (q - (a + ab * t)).length() - float(sg[2]) * 0.5)
	return best

func river_clear(p: Vector3, r: float) -> bool:
	if _seg_riv_n != rivers.size():
		_seg_riv = _seg_index(rivers, true)
		_seg_riv_n = rivers.size()
	return _seg_near(_seg_riv, p, 2) >= 3.0 + r

func road_dist(p: Vector3) -> float:
	if G.MAP > 512.0:
		if _seg_road_n != roads.size():
			_seg_road = _seg_index(roads, false)
			_seg_road_n = roads.size()
		return _seg_near(_seg_road, p, 2)
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
	if G.MAP > 512.0:
		if not river_clear(p, r):
			return false
	else:
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
# girilebilir bina: pencere boşlukları atış yuvası, kapı boşluğu giriş
func _house_slots(hid: int, a: Vector3, b: Vector3, gaps: Array, c: Vector3) -> void:
	var h: Dictionary = B.houses[hid]
	if not h.has("slots"):
		h["slots"] = []
		h["out"] = []
		h["occ"] = {}
		h["door"] = Vector3.INF
	var dir := (b - a).normalized()
	for g in gaps:
		var sc: float = (float(g[0]) + float(g[1])) * 0.5
		var p := a + dir * sc
		var inward := c - p
		inward.y = 0.0
		inward = inward.normalized()
		if int(g[2]) == 0:
			h["door"] = p - inward * 1.4
		else:
			h["slots"].append(p + inward * 1.05)
			h["out"].append(-inward)

func _x_house_flat(c: Vector3, w: float, d: float, rows := 6, rot90 := false, col := WHITE) -> void:
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
	var deco: Array = []
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
				gaps.append([s - 0.9, s + 0.9, 0, 4, true])
			else:
				gaps.append([s - 0.55, s + 0.55, 2, 3, true, rng.randf() < 0.5])
		B.wall_line(a, b, rows, col, Grid.K_HOUSE, {"len": 0.5, "h": BH, "t": t2, "gaps": gaps, "house": hid, "jit": 0.012, "type": Blocks.T_CONCRETE})
		_house_slots(hid, a, b, gaps, c)
		deco.append([a - c, b - c, gaps, si])
	# düz çatı + korkuluk + çatı eşyaları
	var mb := MB.new()
	var rc := Color(0.42, 0.41, 0.4)
	mb.box(Vector3(0, top + 0.1, 0), Vector3(w + 0.5, 0.2, d + 0.5), rc)
	var nx := int(w)
	var nz := int(d)
	for ix in nx:
		for iz in nz:
			if (ix + iz) % 2 == 0:
				mb.box(Vector3(-w * 0.5 + (ix + 0.5) * w / nx, top + 0.205, -d * 0.5 + (iz + 0.5) * d / nz), Vector3(w / nx * 0.96, 0.01, d / nz * 0.96), rc.darkened(0.05))
	var pc := col.darkened(0.15)
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
	var rmesh := mb.commit(Mats.vcs())
	roof.mesh = _facade(deco, top, t2, col, false, rmesh)
	roof.position = Vector3(c.x, 0, c.z)
	B.add_child(roof)
	_floor(c, w, d)

# cephe detayı: cam, çerçeve, denizlik, kepenk, kapı, basamak, saçak ve süpürgelik bandı, klima, oluk
# (çatı düğümüne eklenir; ev çökünce çatıyla birlikte kaybolur)
func _facade(deco: Array, top: float, t2: float, wall: Color, pitched: bool, mesh: ArrayMesh) -> ArrayMesh:
	var mb := MB.new()
	var frame := Color(0.92, 0.9, 0.86) if not pitched else Color(0.42, 0.3, 0.2)
	var glass := Color(0.12, 0.16, 0.2)
	var shut: Color = [Color(0.3, 0.42, 0.5), Color(0.38, 0.32, 0.22), Color(0.3, 0.38, 0.26), Color(0.55, 0.5, 0.42)][rng.randi() % 4]
	var door: Color = [Color(0.35, 0.24, 0.15), Color(0.22, 0.26, 0.3), Color(0.45, 0.2, 0.12)][rng.randi() % 3]
	var band := wall.darkened(0.12)
	for e in deco:
		var a: Vector3 = e[0]
		var b: Vector3 = e[1]
		var gaps: Array = e[2]
		var d := b - a
		d.y = 0
		var L := d.length()
		var dir := d / L
		# dışa bakan normal: duvarın orta noktasından ev merkezinden uzağa
		var mid := (a + b) * 0.5
		var out := Vector3(-dir.z, 0, dir.x)
		if out.dot(mid) < 0.0:
			out = -out
		var bas := Basis(dir, Vector3.UP, -out)
		var off := out * (t2 * 0.5)
		# süpürgelik ve saçak bandı
		mb.box(mid + off + out * 0.02 + Vector3(0, 0.2, 0), Vector3(L + 0.06, 0.4, 0.05), band, bas)
		mb.box(mid + off + out * 0.05 + Vector3(0, top - 0.08, 0), Vector3(L + 0.2, 0.16, 0.12), wall.lightened(0.05), bas)
		for gp in gaps:
			var s0: float = gp[0]
			var s1: float = gp[1]
			var ylo: float = BH * gp[2]
			var yhi: float = BH * (gp[3] + 1)
			var cw := s1 - s0
			var cpos := a + dir * ((s0 + s1) * 0.5)
			if gp[2] == 0:
				# kapı: kanat (içe gömük), kasa, üst atkı, basamak
				mb.box(cpos + Vector3(0, yhi * 0.5, 0) - out * 0.05, Vector3(cw - 0.08, yhi - 0.05, 0.06), door, bas)
				mb.box(cpos + off + Vector3(0, yhi + 0.05, 0), Vector3(cw + 0.2, 0.1, 0.08), frame, bas)
				for sx in [-1.0, 1.0]:
					mb.box(cpos + dir * sx * (cw * 0.5 + 0.04) + off + Vector3(0, yhi * 0.5, 0), Vector3(0.08, yhi, 0.08), frame, bas)
				mb.box(cpos + off + out * 0.25 + Vector3(0, 0.08, 0), Vector3(cw + 0.5, 0.16, 0.5), Color(0.6, 0.58, 0.55), bas)
				mb.box(cpos + dir * (cw * 0.28) + Vector3(0, yhi * 0.48, 0) - out * 0.01, Vector3(0.04, 0.04, 0.04), Color(0.7, 0.65, 0.4), bas)
			else:
				# pencere: cam, kayıt (artı), çerçeve, denizlik, kepenk ya da demir parmaklık
				var cy := (ylo + yhi) * 0.5
				var ch := yhi - ylo
				mb.box(cpos + Vector3(0, cy, 0) - out * 0.08, Vector3(cw, ch, 0.03), glass, bas)
				mb.box(cpos + Vector3(0, cy, 0) - out * 0.06, Vector3(0.04, ch, 0.04), frame, bas)
				mb.box(cpos + Vector3(0, cy, 0) - out * 0.06, Vector3(cw, 0.04, 0.04), frame, bas)
				for sx in [-1.0, 1.0]:
					mb.box(cpos + dir * sx * (cw * 0.5 + 0.03) + off + Vector3(0, cy, 0), Vector3(0.06, ch + 0.06, 0.05), frame, bas)
				mb.box(cpos + off + Vector3(0, yhi + 0.03, 0), Vector3(cw + 0.12, 0.06, 0.06), frame, bas)
				mb.box(cpos + off + out * 0.05 + Vector3(0, ylo - 0.03, 0), Vector3(cw + 0.18, 0.06, 0.16), wall.lightened(0.08), bas)
				if pitched or rng.randf() < 0.4:
					for sx in [-1.0, 1.0]:
						var sp: Vector3 = cpos + dir * sx * (cw * 0.5 + 0.3) + off + out * 0.03 + Vector3(0, cy, 0)
						mb.box(sp, Vector3(0.5, ch, 0.04), shut, bas)
						for k in 4:
							mb.box(sp + out * 0.025 + Vector3(0, -ch * 0.4 + k * ch * 0.27, 0), Vector3(0.46, 0.03, 0.01), shut.darkened(0.2), bas)
				elif rng.randf() < 0.5:
					for k in 4:
						mb.box(cpos + dir * (-cw * 0.5 + (k + 0.5) * cw / 4.0) + off + out * 0.03 + Vector3(0, cy, 0), Vector3(0.025, ch, 0.025), Color(0.15, 0.15, 0.15), bas)
		# klima / oluk borusu
		if not pitched and rng.randf() < 0.5 and L > 4.0:
			var ap := a + dir * (L * rng.randf_range(0.2, 0.8)) + off + out * 0.2 + Vector3(0, top - 0.7, 0)
			mb.box(ap, Vector3(0.8, 0.55, 0.32), Color(0.85, 0.85, 0.83), bas)
			mb.cyl(ap + out * 0.17, 0.2, 0.2, 0.02, 12, Color(0.3, 0.3, 0.3), bas * Basis(Vector3.RIGHT, PI * 0.5))
		if rng.randf() < 0.5:
			var gp2 := a + dir * (0.15 if rng.randf() < 0.5 else L - 0.15) + off + out * 0.06
			mb.cyl(gp2 + Vector3(0, top * 0.5, 0), 0.05, 0.05, top, 6, Color(0.45, 0.45, 0.45) if not pitched else Color(0.4, 0.36, 0.3))
	if mb.count == 0:
		return mesh
	return mb.commit(Mats.vc(), mesh)

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

func _x_house_pitched(c: Vector3, w: float, d: float, rot90: bool, wall_col: Color, roof_col: Color, snow: bool, rows := 6) -> void:
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
	var deco: Array = []
	for si in 4:
		var a: Vector3 = sides[si][0]
		var b: Vector3 = sides[si][1]
		var L := a.distance_to(b)
		var gaps: Array = []
		var nwin := int((L - 1.0) / 2.2)
		for i in nwin:
			var s := (i + 0.5) * (L / nwin)
			if si == door_side and i == 0:
				gaps.append([s - 0.9, s + 0.9, 0, 4, true])
			else:
				gaps.append([s - 0.5, s + 0.5, 2, 3, true, true])
		B.wall_line(a, b, rows, wall_col, Grid.K_HOUSE, {"len": 0.5, "h": BH, "t": t2, "gaps": gaps, "house": hid, "jit": 0.025, "type": Blocks.T_CONCRETE})
		_house_slots(hid, a, b, gaps, c)
		deco.append([a - c, b - c, gaps, si])
	roof.mesh = _facade(deco, top, t2, wall_col, true, pitched_roof(w, d, top, roof_col, wall_col, snow))
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
	var nu := 2
	var nv := 2
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
				var cc := col
				var a := bas * Vector3(x0, y0, v0)
				var b := bas * Vector3(x1, y1, v0)
				var c2 := bas * Vector3(x1, y1, v1)
				var dd := bas * Vector3(x0, y0, v1)
				var n2 := bas * Vector3(side * rh, hw, 0).normalized()
				mb.quad(a, b, c2, dd, cc, n2)
	var rmesh := mb.commit(Mats.roof(snow))
	mb = MB.new()
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
	return mb.commit(Mats.masonry(), rmesh)

func _x_wall(a: Vector3, b: Vector3, rows: int, ruin := 0.0, col := STONE) -> void:
	B.wall_line(a, b, rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.52, "ruin": ruin, "jit": 0.07})

func _x_ruin_cluster(c: Vector3) -> void:
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

func _x_compound(c: Vector3, w: float, d: float, rows: int, gate_side: int, col := STONE) -> void:
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

func _x_fence(a: Vector3, b: Vector3, col := Color(0.88, 0.86, 0.8)) -> void:
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
			house_flat(p, w, d, rng.randi_range(5, 7), rot, facade() if kind != "desert" else WHITE)
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
				p_palm(p)
	for i in 70:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			if rng.randf() < 0.82:
				p_palm(p)
			else:
				p_tree(p)
	# direkler yol boyunca
	_poles_along(roads[0], 16.0, 5.5)
	_poles_along(roads[1], 18.0, 5.0)
	# sivil arabalar, tenteler
	for i in 26:
		var p := rand_free(2.2, 30, Rect2(80, 80, 96, 96), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			p_car(p, rng.randf() * TAU)
	for i in 10:
		var p := rand_free(2.0, 30, Rect2(30, 30, 196, 196), 1.0)
		if p.x > 0:
			p_car(p, rng.randf() * TAU)
	for i in 12:
		var p := rand_free(1.6, 30, Rect2(90, 90, 76, 76), 1.0)
		if p.x > 0:
			p_canopy(p, rng.randf() * TAU)
	# eski kraterler
	for i in 40:
		var p := Vector3(rng.randf_range(60, 196), 0, rng.randf_range(60, 196))
		if road_dist(p) > 3.0:
			var s := rng.randf_range(2.0, 4.5)
			crater(p, s)

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
					p_pole(p, rng.randf() < 0.25)
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
						p_shed(sp, rng.randf() * TAU)
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
					p_pine(p)
				else:
					p_tree(p)
	for i in 110:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			p_tree(p)
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
			p_car(p, rng.randf() * TAU)
	for i in 20:
		var p := Vector3(rng.randf_range(60, 196), 0, rng.randf_range(60, 196))
		if road_dist(p) > 3.0:
			var s := rng.randf_range(2.0, 4.0)
			crater(p, s)


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
			house_flat(p, w, d, rng.randi_range(5, 7), rot, facade() if kind != "desert" else WHITE)
		else:
			house_pitched(p, w, d, rot, facade(), roof_col(), kind == "winter")
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

# ------------------------------------------------------------ Büyük Şehir (512 m)
func _city() -> void:
	var S := G.MAP
	var R := Rect2(6, 6, S - 12, S - 12)
	G.hq_pos = [Vector3(S - 48, 0, S - 48), Vector3(48, 0, 48)]
	reserve(G.hq_pos[0], 28)
	reserve(G.hq_pos[1], 28)
	# nehir şehri ikiye böler
	var riv := river([Vector3(-10, 0, S * 0.62), Vector3(S * 0.2, 0, S * 0.56), Vector3(S * 0.42, 0, S * 0.5), Vector3(S * 0.6, 0, S * 0.44), Vector3(S * 0.8, 0, S * 0.36), Vector3(S + 10, 0, S * 0.3)], 15.0, 1.9)
	# ana bulvar (karargâhtan karargâha) + çevre yolları
	road([Vector3(S - 6, 0, S - 6), Vector3(S - 48, 0, S - 48), Vector3(S * 0.72, 0, S * 0.7), Vector3(S * 0.5, 0, S * 0.5), Vector3(S * 0.3, 0, S * 0.3), Vector3(48, 0, 48), Vector3(6, 0, 6)], 7.0)
	road([Vector3(6, 0, S * 0.3), Vector3(S * 0.3, 0, S * 0.28), Vector3(S * 0.55, 0, S * 0.18), Vector3(S - 6, 0, S * 0.12)], 5.5)
	road([Vector3(S * 0.1, 0, S - 6), Vector3(S * 0.4, 0, S * 0.78), Vector3(S * 0.75, 0, S * 0.72), Vector3(S - 6, 0, S * 0.7)], 5.5)
	# şehir merkezi sokak ızgarası
	var c0 := S * 0.5 - 120.0
	var step := 40.0
	for i in 7:
		var x := c0 + i * step
		road([Vector3(x, 0, c0 - 10), Vector3(x, 0, c0 + 6 * step + 10)], 5.0)
		road([Vector3(c0 - 10, 0, x), Vector3(c0 + 6 * step + 10, 0, x)], 5.0)
	auto_bridges()
	p_reeds_along(riv, 7.0)
	# merkez: kaldırım/meydan dokusu (parke)
	for gx in range(int(c0), int(c0 + 6 * step), 6):
		for gz in range(int(c0), int(c0 + 6 * step), 6):
			var gp := Vector3(gx + rng.randf_range(-2, 2), 0, gz + rng.randf_range(-2, 2))
			if not (T.has_water and T.ground_h(gp) < -0.2):
				T.paint_circle(gp, rng.randf_range(4.5, 6.5), 0, 0.55)
	for i in 140:
		patch(Vector3(rng.randf_range(0, S), 0, rng.randf_range(0, S)), rng.randf_range(5, 16), rng.randf_range(0.4, 0.9))
	G.fob_sites = []
	for k in 14:
		var a := float(k) / 14.0 * TAU
		var fp := Vector3(S * 0.5 + cos(a) * S * 0.3, 0, S * 0.5 + sin(a) * S * 0.3)
		G.fob_sites.append(fp)
		reserve(fp, 10.0)
	# meydan (merkez) + demiryolu (güney kenarı boyunca)
	# meydan: sudan ve yoldan uzak bir blok ortası
	for cand in [Vector2(2.5, 3.5), Vector2(3.5, 2.5), Vector2(1.5, 3.5), Vector2(3.5, 1.5), Vector2(2.5, 1.5)]:
		var pc0 := Vector3(c0 + cand.x * step, 0, c0 + cand.y * step)
		if T.has_water and T.ground_h(pc0) < -0.1:
			continue
		if road_dist(pc0) < 10.0 or G.grid.is_water(pc0):
			continue
		P.plaza(pc0)
		reserve(pc0, 10.0)
		break
	var rail := PackedVector3Array()
	for k in 17:
		rail.append(Vector3(16.0 + k * (S - 32.0) / 16.0, 0, S * 0.86 + sin(k * 0.6) * 6.0))
	for q in rail:
		reserve(q, 3.0)
	P.railway(rail)
	# sıra evler: merkez bloklarda sokak cephesine bitişik, iki katlı
	for bx in range(1, 5):
		for bz in range(1, 5):
			var bc2 := Vector3(c0 + (bx + 0.5) * step, 0, c0 + (bz + 0.5) * step)
			if T.has_water and T.ground_h(bc2) < -0.2:
				continue
			var z0 := bc2.z - step * 0.5 + 6.0
			var x := bc2.x - step * 0.5 + 6.0
			while x < bc2.x + step * 0.5 - 6.0:
				var w2 := rng.randf_range(5.6, 7.0)
				var hp2 := Vector3(x + w2 * 0.5, 0, z0)
				if free_at(hp2, 3.2, 1.5) and not (T.has_water and T.ground_h(hp2) < -0.2):
					house_pitched(hp2, w2, 6.2, false, facade(), roof_col(), false, 9)
					reserve(hp2, 3.4)
					if rng.randf() < 0.22:
						P.roof_damage(hp2, w2, 6.2, 9 * BH, 0.0)
				x += w2 + 0.25
	# bloklar: her blokta 2-4 girilebilir bina, merkezde düz çatı, kenarda kırma çatı
	var houses := 0
	for bx in 6:
		for bz in 6:
			var bc := Vector3(c0 + (bx + 0.5) * step, 0, c0 + (bz + 0.5) * step)
			if T.has_water and T.ground_h(bc) < -0.2:
				continue
			var centre := absf(bx - 2.5) < 1.6 and absf(bz - 2.5) < 1.6
			var n := rng.randi_range(4, 6) if centre else rng.randi_range(3, 4)
			for k in n:
				var w := rng.randf_range(6.0, 9.0)
				var d := rng.randf_range(5.5, 7.5)
				var r := maxf(w, d) * 0.6
				var p := rand_free(r, 40, Rect2(bc.x - step * 0.5 + 3.5, bc.z - step * 0.5 + 3.5, step - 7, step - 7), 1.5)
				if p.x < 0:
					continue
				var rot := rng.randf() < 0.5
				var bt := rng.randf()
				if centre and bt < 0.22 and free_at(p, 6.0, 1.5):
					# apartman: 3-4 katlı geniş blok
					house_flat(p, w + 3.0, d + 1.5, rng.randi_range(13, 16), rot, facade())
				elif centre and bt < 0.42:
					# dükkân: tente + tabela
					house_flat(p, w, d, 7, rot, facade())
					var fr := (d if not rot else w) * 0.5 + 0.1
					P.awning(p + (Vector3(0, 0, fr) if not rot else Vector3(fr, 0, 0)), 0.0 if not rot else PI * 0.5, (w if not rot else d) * 0.8, [Color(0.7, 0.1, 0.08), Color(0.1, 0.35, 0.2), Color(0.12, 0.25, 0.55), Color(0.85, 0.6, 0.1)][rng.randi() % 4])
				elif not centre and bt < 0.08 and free_at(p, 8.0, 2.0):
					# kilise: uzun nef + taş kule + sivri
					house_pitched(p, 8.0, 15.0, rot, Color(0.78, 0.74, 0.66), Color(0.32, 0.33, 0.34), false, 11)
					var tp := p + (Vector3(0, 0, 9.5) if not rot else Vector3(9.5, 0, 0))
					if free_at(tp, 2.5, 1.0):
						house_flat(tp, 4.2, 4.2, 26, false, Color(0.76, 0.72, 0.64))
						P.spire(tp + Vector3(0, 26 * BH + 0.5, 0), 6.0)
						reserve(tp, 3.0)
				elif not centre and bt < 0.18:
					# ambar: büyük, ahşap kahve duvar, gri çatı
					house_pitched(p, w + 3.0, d + 2.0, rot, Color(0.45, 0.32, 0.22), Color(0.4, 0.4, 0.42), false, 8)
				elif not centre and bt < 0.22 and free_at(p, 7.0, 0.0) and road_dist(p) < 14.0:
					P.gas_station(p, 0.0 if not rot else PI * 0.5)
				elif centre and rng.randf() < 0.75:
					house_flat(p, w, d, rng.randi_range(6, 8), rot, facade())
				else:
					house_pitched(p, w, d, rot, facade(), roof_col(), false)
					if rng.randf() < 0.2:
						P.roof_damage(p, w, d, 6 * BH, PI * 0.5 if rot else 0.0)
					# bahçe çiti
					if not centre and rng.randf() < 0.5:
						var fw := (d if rot else w) * 0.5 + 2.2
						var fd := (w if rot else d) * 0.5 + 2.2
						var fz := p.z + fd
						if free_at(Vector3(p.x, 0, fz), 0.5, 1.0):
							P.picket(Vector3(p.x - fw, 0, fz), Vector3(p.x + fw, 0, fz))
				reserve(p, r + 1.0)
				houses += 1
			# bahçe duvarı / çalılar
			for k in 3:
				var q := rand_free(0.8, 10, Rect2(bc.x - step * 0.5 + 3, bc.z - step * 0.5 + 3, step - 6, step - 6), 1.5)
				if q.x > 0:
					p_bush(q, rng.randf() < 0.3)
	# dış mahalleler: köyler + çiftlik yıkıntıları
	for tc in [Vector3(S * 0.18, 0, S * 0.78), Vector3(S * 0.82, 0, S * 0.22), Vector3(S * 0.15, 0, S * 0.15 + 70), Vector3(S * 0.85, 0, S * 0.85 - 70)]:
		_town(tc, 26, 7, false)
	# sanayi bölgesi: büyük duvarlı avlular
	for k in 5:
		var ip := rand_free(10.0, 40, Rect2(S * 0.62, S * 0.05, S * 0.3, S * 0.2), 3.0)
		if ip.x > 0:
			compound(ip, rng.randf_range(16, 24), rng.randf_range(14, 20), 5, rng.randi() % 4, Color(0.7, 0.68, 0.64))
			house_flat(ip, rng.randf_range(8, 11), rng.randf_range(6, 8), 8, rng.randf() < 0.5, Color(0.76, 0.74, 0.7))
			reserve(ip, 14.0)
	for i in 50:
		var p := rand_free(3.0, 30, R, 3.0)
		if p.x > 0:
			_brick_ruin(p, Color(0.78, 0.5, 0.36))
			reserve(p, 4.0)
	# parklar / ağaçlıklar
	for g in 40:
		var c := rand_free(6.0, 40, R, 2.0)
		if c.x < 0:
			continue
		for i in rng.randi_range(5, 12):
			var p := c + Vector3(rng.randf_range(-11, 11), 0, rng.randf_range(-11, 11))
			if free_at(p, 0.7, 1.5):
				p_tree(p)
		for i in rng.randi_range(6, 12):
			var p := c + Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-13, 13))
			if free_at(p, 0.6, 1.0):
				p_bush(p, rng.randf() < 0.3)
	for i in 300:
		var p := rand_free(0.8, 20, R, 2.0)
		if p.x > 0:
			var r2 := rng.randf()
			if r2 < 0.35:
				p_tree(p)
			elif r2 < 0.8:
				p_bush(p)
			else:
				p_rock(p, rng.randf_range(0.6, 1.3))
	_poles_along(roads[0], 18.0, 6.0)
	for k in 10:
		var mp := riv[clampi(int(float(k) / 10.0 * riv.size()), 0, riv.size() - 1)]
		G.fx.ground_mist(mp + Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12)), 14.0)
	# sokak lambaları: ızgara sokaklar boyunca
	for i in 7:
		for k in 12:
			var lx := c0 + i * step + 3.4
			var lz := c0 + k * step * 0.5 + 2.0
			for lp in [Vector3(lx, 0, lz), Vector3(lz, 0, lx)]:
				if free_at(lp, 0.5, 0.0) and not (T.has_water and T.ground_h(lp) < -0.2):
					P.pole(lp, true)
	# savaş izleri: kraterler, yanık lekeleri, moloz
	for i in 45:
		var bp := Vector3(rng.randf_range(20, S - 20), 0, rng.randf_range(20, S - 20))
		if T.has_water and T.ground_h(bp) < -0.2:
			continue
		var cr := rng.randf_range(2.0, 4.5)
		G.fx.crater(bp, cr)
		if rng.randf() < 0.5:
			G.fx.scorch(bp + Vector3(rng.randf_range(-2, 2), 0, rng.randf_range(-2, 2)), cr * 1.4)
		T.paint_circle(bp, cr * 0.9, 2, 0.6)
	# sokak eşyaları: varil grupları, kasa yığınları, çam sıraları
	for i in 90:
		var q := rand_free(1.0, 20, R, 1.0)
		if q.x < 0 or road_dist(q) > 9.0:
			continue
		var r3 := rng.randf()
		if r3 < 0.4:
			for k in rng.randi_range(2, 5):
				P.barrel(q + Vector3(rng.randf_range(-0.8, 0.8), 0, rng.randf_range(-0.8, 0.8)), [Color(0.55, 0.12, 0.08), Color(0.25, 0.32, 0.2), Color(0.3, 0.3, 0.32)][rng.randi() % 3])
		elif r3 < 0.75:
			for k in rng.randi_range(2, 4):
				P.crate(q + Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.9, 0.9)), rng.randf() * TAU, rng.randf_range(0.7, 1.1))
		else:
			P.pine(q)
	for i in 30:
		var p := rand_free(2.2, 30, R, 0.0)
		if p.x > 0 and road_dist(p) < 8.0:
			p_car(p, rng.randf() * TAU)
	_tracks(30, 0.25)
	p_grass_field(42000, Color(0.42, 0.55, 0.24), Rect2(2, 2, S - 4, S - 4), 0.5)
	print("CITY houses=%d" % houses)

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
	p_reeds_along(canal, 5.5)
	for i in range(0, canal.size() - 1, 2):
		var a := canal[i]
		var b := canal[i + 1]
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		for sg in [-1.0, 1.0]:
			if rng.randf() < 0.42:
				var q: Vector3 = a + side * sg * rng.randf_range(9.0, 12.0)
				if free_at(q, 0.6, 1.5):
					p_palm(q)
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
				p_palm(p)
	for i in 50:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.5)
		if p.x > 0:
			if rng.randf() < 0.8:
				p_palm(p)
			else:
				p_tree(p)
	_poles_along(roads[0], 16.0, 5.5)
	for i in 22:
		var p := rand_free(2.2, 30, Rect2(30, 30, 196, 196), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			p_car(p, rng.randf() * TAU)
	for i in 10:
		var p := rand_free(1.6, 30, Rect2(40, 40, 176, 176), 1.0)
		if p.x > 0:
			p_canopy(p, rng.randf() * TAU)
	for i in 30:
		var p := Vector3(rng.randf_range(50, 206), 0, rng.randf_range(50, 206))
		if road_dist(p) > 3.0 and T.ground_h(p) > -0.05:
			var s := rng.randf_range(2.0, 4.0)
			crater(p, s)
	_tracks(30, 0.3)
	p_grass_field(900, Color(0.55, 0.48, 0.3), Rect2(2, 2, 252, 252), 0.4)

func _x_tracks(n: int, amt: float) -> void:
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
	p_reeds_along(riv, 6.5)
	# çayır yamaları (toprak/çim)
	for i in 70:
		patch(Vector3(rng.randf_range(0, 256), 0, rng.randf_range(0, 256)), rng.randf_range(4, 14), rng.randf_range(0.5, 1.0))
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
				p_tree(p)
		for i in rng.randi_range(6, 14):
			var p := c + Vector3(rng.randf_range(-13, 13), 0, rng.randf_range(-13, 13))
			if free_at(p, 0.6, 1.0):
				p_bush(p, rng.randf() < 0.3)
	for i in 120:
		var p := rand_free(0.8, 20, Rect2(6, 6, 244, 244), 2.0)
		if p.x > 0:
			var r := rng.randf()
			if r < 0.35:
				p_tree(p)
			elif r < 0.8:
				p_bush(p)
			else:
				p_rock(p, rng.randf_range(0.6, 1.3))
	for i in 30:
		var p := rand_free(1.0, 20, Rect2(20, 20, 216, 216), 2.0)
		if p.x > 0:
			p_hay(p)
	_poles_along(roads[0], 18.0, 5.0)
	for i in 8:
		var p := rand_free(2.2, 30, Rect2(30, 30, 196, 196), 0.0)
		if p.x > 0 and road_dist(p) < 9.0:
			p_car(p, rng.randf() * TAU)
	_tracks(14, 0.25)
	p_grass_field(16000, Color(0.42, 0.55, 0.24), Rect2(2, 2, 252, 252), 0.5)
	for k in 6:
		var mp := riv[clampi(int(float(k) / 6.0 * riv.size()), 0, riv.size() - 1)]
		G.fx.ground_mist(mp + Vector3(rng.randf_range(-10, 10), 0, rng.randf_range(-10, 10)), 12.0)

func _x_brick_ruin(c: Vector3, col: Color) -> void:
	var ax := Vector3.RIGHT if rng.randf() < 0.5 else Vector3.BACK
	var bx := Vector3(-ax.z, 0, ax.x)
	var L1 := rng.randf_range(2.5, 5.0)
	var L2 := rng.randf_range(2.0, 4.0)
	var rows := rng.randi_range(2, 4)
	var ruin := rng.randf_range(0.3, 0.8)
	B.wall_line(c, c + ax * L1, rows, col, Grid.K_WALL, {"len": 0.7, "h": 0.5, "t": 0.6, "ruin": ruin, "jit": 0.12})
	if rng.randf() < 0.7:
		B.wall_line(c + bx * 0.7, c + bx * L2, rows, col, Grid.K_WALL, {"len": 0.7, "h": 0.5, "t": 0.6, "ruin": ruin, "jit": 0.12})


func _x_snow_brick_wall(c: Vector3) -> void:
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


# ============================================================ İŞLEMLER (kayıt + tekrar)
# Her yerleştirme bir sözlük olarak kaydedilir; aynı tohumla yeniden çalıştırılınca aynı sonucu verir.
static func vv(p: Vector3) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.z, 0.01)]

static func v3(a) -> Vector3:
	return Vector3(float(a[0]), 0, float(a[1]))

static func cc(c: Color) -> Array:
	return [snappedf(c.r, 0.001), snappedf(c.g, 0.001), snappedf(c.b, 0.001)]

static func col(a) -> Color:
	return Color(float(a[0]), float(a[1]), float(a[2]))

static func pts_out(arr: Array) -> Array:
	var o: Array = []
	for q in arr:
		o.append(vv(q))
	return o

static func pts_in(arr: Array) -> Array:
	var o: Array = []
	for q in arr:
		o.append(v3(q))
	return o

func exec(op: Dictionary):
	if not op.has("s"):
		op["s"] = rng.randi() % 1000000
	var top := _depth == 0
	if top:
		ops.append(op)
		var sd: int = int(op["s"])
		rng.seed = sd
		B.rng.seed = sd + 1
		P.rng.seed = sd + 2
	_depth += 1
	var r = _run(op)
	_depth -= 1
	return r

func _run(op: Dictionary):
	match String(op["t"]):
		"road":
			return _x_road(pts_in(op["pts"]), float(op["w"]))
		"river":
			return _x_river(pts_in(op["pts"]), float(op["w"]), float(op.get("d", 1.7)))
		"bridges":
			_x_auto_bridges()
		"house_flat":
			_x_house_flat(v3(op["p"]), float(op["w"]), float(op["d"]), int(op["rows"]), bool(op["r90"]), col(op["col"]))
		"house_pitched":
			_x_house_pitched(v3(op["p"]), float(op["w"]), float(op["d"]), bool(op["r90"]), col(op["col"]), col(op["roof"]), bool(op["snow"]), int(op["rows"]))
		"wall":
			_x_wall(v3(op["a"]), v3(op["b"]), int(op["rows"]), float(op["ruin"]), col(op["col"]))
		"ruin":
			_x_ruin_cluster(v3(op["p"]))
		"compound":
			_x_compound(v3(op["p"]), float(op["w"]), float(op["d"]), int(op["rows"]), int(op["gate"]), col(op["col"]))
		"fence":
			_x_fence(v3(op["a"]), v3(op["b"]), col(op["col"]))
		"brick_ruin":
			_x_brick_ruin(v3(op["p"]), col(op["col"]))
		"snow_wall":
			_x_snow_brick_wall(v3(op["p"]))
		"tracks":
			_x_tracks(int(op["n"]), float(op["amt"]))
		"path":
			_x_path(pts_in(op["pts"]), float(op["w"]), bool(op.get("stone", false)))
		"palm":
			P.palm(v3(op["p"]))
		"tree":
			P.tree(v3(op["p"]))
		"pine":
			P.pine(v3(op["p"]))
		"bush":
			P.bush(v3(op["p"]), bool(op.get("big", false)))
		"rock":
			P.rock(v3(op["p"]), float(op.get("sc", 1.0)))
		"hay":
			P.hay(v3(op["p"]))
		"car":
			P.car(v3(op["p"]), float(op["r"]), int(op.get("v", -1)))
		"canopy":
			P.canopy(v3(op["p"]), float(op["r"]))
		"shed":
			P.shed(v3(op["p"]), float(op["r"]))
		"pole":
			P.pole(v3(op["p"]), bool(op.get("lamp", false)))
		"grass":
			var rg: Array = op.get("rect", [2, 2, 252, 252])
			P.grass_field(int(op["n"]), col(op["col"]), Rect2(rg[0], rg[1], rg[2], rg[3]), float(op.get("size", 0.5)))
		"reeds":
			P.reeds_along(PackedVector3Array(pts_in(op["pts"])), float(op["hw"]))
		"crater":
			var cp := v3(op["p"])
			G.fx.crater(cp, float(op["sc"]))
			T.paint_circle(cp, float(op["sc"]) * 0.65, 2, 0.3)
		"patch":
			T.patch_blob(v3(op["p"]), float(op["r"]), float(op["a"]))
	return null

# ---- sarmalayıcılar (prosedürel üretici ve editör bunları çağırır)
func road(ctrl: Array, w := 6.0) -> PackedVector3Array:
	return exec({"t": "road", "pts": pts_out(ctrl), "w": w})

func river(ctrl: Array, w: float, depth := 1.7) -> PackedVector3Array:
	return exec({"t": "river", "pts": pts_out(ctrl), "w": w, "d": depth})

func auto_bridges() -> void:
	exec({"t": "bridges"})

func house_flat(c: Vector3, w: float, d: float, rows := 6, rot90 := false, cl := WHITE) -> void:
	exec({"t": "house_flat", "p": vv(c), "w": w, "d": d, "rows": rows, "r90": rot90, "col": cc(cl)})

func house_pitched(c: Vector3, w: float, d: float, rot90: bool, wall_col: Color, roof_col: Color, snow: bool, rows := 6) -> void:
	exec({"t": "house_pitched", "p": vv(c), "w": w, "d": d, "r90": rot90, "col": cc(wall_col), "roof": cc(roof_col), "snow": snow, "rows": rows})

func wall(a: Vector3, b: Vector3, rows: int, ruin := 0.0, cl := STONE) -> void:
	exec({"t": "wall", "a": vv(a), "b": vv(b), "rows": rows, "ruin": ruin, "col": cc(cl)})

func ruin_cluster(c: Vector3) -> void:
	exec({"t": "ruin", "p": vv(c)})

func compound(c: Vector3, w: float, d: float, rows: int, gate_side: int, cl := STONE) -> void:
	exec({"t": "compound", "p": vv(c), "w": w, "d": d, "rows": rows, "gate": gate_side, "col": cc(cl)})

func fence(a: Vector3, b: Vector3, cl := Color(0.88, 0.86, 0.8)) -> void:
	exec({"t": "fence", "a": vv(a), "b": vv(b), "col": cc(cl)})

func _brick_ruin(c: Vector3, cl: Color) -> void:
	exec({"t": "brick_ruin", "p": vv(c), "col": cc(cl)})

func _snow_brick_wall(c: Vector3) -> void:
	exec({"t": "snow_wall", "p": vv(c)})

func _tracks(n: int, amt: float) -> void:
	exec({"t": "tracks", "n": n, "amt": amt})

# ---- patikalar: evden yola taş döşeme, evler/üs alanları arasında çiğnenmiş toprak patika
func _nearest_road_pt(p: Vector3) -> Vector3:
	var best := Vector3.INF
	var bd := 1e9
	for r in roads:
		var pts: PackedVector3Array = r
		for q in pts:
			var d := Vector2(q.x - p.x, q.z - p.z).length()
			if d < bd:
				bd = d
				best = q
	return best

func _footpaths() -> void:
	var doors: Array = []
	for h in G.blocks.houses:
		var dp: Vector3 = h.get("door", Vector3.INF)
		if dp != Vector3.INF:
			doors.append(dp)
	# evden en yakın yola taş döşeme (kısa olanlar)
	for dp in doors:
		var rp := _nearest_road_pt(dp)
		if rp == Vector3.INF:
			continue
		var L := Vector2(rp.x - dp.x, rp.z - dp.z).length()
		if L > 2.5 and L < 22.0 and rng.randf() < 0.75:
			var mid: Vector3 = dp.lerp(rp, 0.5) + Vector3(rng.randf_range(-1.5, 1.5), 0, rng.randf_range(-1.5, 1.5))
			exec({"t": "path", "pts": pts_out([dp, mid, rp]), "w": 1.2, "stone": kind != "desert"})
	# evler arası / alanlar arası toprak patika
	var spots: Array = doors.duplicate()
	for f in G.fob_sites:
		spots.append(f)
	for i in mini(14, spots.size()):
		var a: Vector3 = spots[rng.randi() % spots.size()]
		var b: Vector3 = spots[rng.randi() % spots.size()]
		var L2 := a.distance_to(b)
		if L2 < 20.0 or L2 > 90.0:
			continue
		var dir := (b - a).normalized()
		var side := Vector3(-dir.z, 0, dir.x)
		var pts: Array = [a]
		for k in 3:
			pts.append(a.lerp(b, (k + 1) / 4.0) + side * rng.randf_range(-L2 * 0.12, L2 * 0.12))
		pts.append(b)
		exec({"t": "path", "pts": pts_out(pts), "w": 1.3, "stone": false})

static var _slab_m: Mesh = null
func _x_path(pts: Array, w: float, stone: bool) -> void:
	var sp := _spline(pts, 1.0)
	for j in sp.size() - 1:
		if G.grid.is_water(sp[j]):
			continue
		T.paint_line(sp[j], sp[j + 1], w, 0, 0.5 if not stone else 0.35, 0.15, rng)
		var d := (sp[j + 1] - sp[j]).normalized()
		var sd := Vector3(-d.z, 0, d.x)
		for s in [-w * 0.5, w * 0.5]:
			T.paint_line(sp[j] + sd * s, sp[j + 1] + sd * s, 0.35, 1, 0.18)
	if not stone:
		return
	# taş döşeme: düzensiz, hafif yüksek yassı kayrak plakalar
	if _slab_m == null:
		var mb := MB.new()
		mb.hull(Vector3(0, 0.0, 0), Vector2(0.62, 0.5), Vector2(0.56, 0.44), 0.05, Color(0.46, 0.44, 0.41))
		_slab_m = mb.commit(Mats.stone())
	var xs: Array = []
	var acc := 0.0
	for j in sp.size() - 1:
		var a2 := sp[j]
		var b2 := sp[j + 1]
		var seg := a2.distance_to(b2)
		var d2 := (b2 - a2).normalized()
		var sd2 := Vector3(-d2.z, 0, d2.x)
		while acc < seg:
			var p := a2 + d2 * acc
			for o in ([-0.28, 0.28] if w > 1.0 else [0.0]):
				var q: Vector3 = p + sd2 * (float(o) + rng.randf_range(-0.06, 0.06))
				if G.grid.height_at(q) < 0.1 and not G.grid.is_water(q):
					var sc := rng.randf_range(0.8, 1.15)
					var bs := Basis(Vector3.UP, atan2(d2.x, d2.z) + rng.randf_range(-0.25, 0.25)).scaled(Vector3(sc, 1, sc * rng.randf_range(0.8, 1.2)))
					xs.append(Transform3D(bs, Vector3(q.x, T.ground_h(q) + 0.015, q.z)))
			acc += 0.56
		acc -= seg
	if xs.is_empty():
		return
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = _slab_m
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	T.add_child(mi)

func p_palm(p: Vector3) -> void:
	exec({"t": "palm", "p": vv(p)})

func p_tree(p: Vector3) -> void:
	exec({"t": "tree", "p": vv(p)})

func p_pine(p: Vector3) -> void:
	exec({"t": "pine", "p": vv(p)})

func p_bush(p: Vector3, big := false) -> void:
	exec({"t": "bush", "p": vv(p), "big": big})

func p_rock(p: Vector3, sc := 1.0) -> void:
	exec({"t": "rock", "p": vv(p), "sc": sc})

func p_hay(p: Vector3) -> void:
	exec({"t": "hay", "p": vv(p)})

func p_car(p: Vector3, r: float, v := -1) -> void:
	exec({"t": "car", "p": vv(p), "r": r, "v": v})

func p_canopy(p: Vector3, r: float) -> void:
	exec({"t": "canopy", "p": vv(p), "r": r})

func p_shed(p: Vector3, r: float) -> void:
	exec({"t": "shed", "p": vv(p), "r": r})

func p_pole(p: Vector3, lamp := false) -> void:
	exec({"t": "pole", "p": vv(p), "lamp": lamp})

func p_grass_field(n: int, cl: Color, region := Rect2(2, 2, 252, 252), size := 0.55, _avoid: Callable = Callable()) -> void:
	exec({"t": "grass", "n": n, "col": cc(cl), "rect": [region.position.x, region.position.y, region.size.x, region.size.y], "size": size})

func p_reeds_along(pts: PackedVector3Array, hw: float) -> void:
	exec({"t": "reeds", "pts": pts_out(Array(pts)), "hw": hw})

func crater(p: Vector3, sc: float) -> void:
	exec({"t": "crater", "p": vv(p), "sc": sc})

func patch(p: Vector3, r: float, a: float) -> void:
	exec({"t": "patch", "p": vv(p), "r": r, "a": a})

# ---- harita verisi
func to_data(name: String) -> Dictionary:
	return {"v": 1, "name": name, "map": map_id, "biome": kind, "hq": [vv(G.hq_pos[0]), vv(G.hq_pos[1])], "fobs": pts_out(G.fob_sites), "ops": ops.duplicate(true)}

func build_ops(d: Dictionary) -> void:
	var hq: Array = d.get("hq", [[214, 214], [42, 42]])
	G.hq_pos = [v3(hq[0]), v3(hq[1])]
	reserve(G.hq_pos[0], 26)
	reserve(G.hq_pos[1], 26)
	G.fob_sites = pts_in(d.get("fobs", []))
	for f in G.fob_sites:
		reserve(f, 8.0)
	for op in d.get("ops", []):
		exec(op.duplicate(true))
