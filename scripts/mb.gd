class_name MB extends RefCounted
# Vertex renkli düşük poligonlu prosedürel mesh kurucu.
# Godot ön yüzleri saat yönünde sarar; tri() istenen dış normale göre sırayı kendisi düzeltir.

var st := SurfaceTool.new()
var count := 0

func _init() -> void:
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

func tri(a: Vector3, b: Vector3, c: Vector3, col: Color, n: Vector3) -> void:
	var cw := (c - a).cross(b - a)
	if cw.dot(n) < 0.0:
		var t := b
		b = c
		c = t
	n = n.normalized()
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(a)
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(b)
	st.set_color(col)
	st.set_normal(n)
	st.add_vertex(c)
	count += 3

func tri_s(a: Vector3, b: Vector3, c: Vector3, na: Vector3, nb: Vector3, nc: Vector3, col: Color) -> void:
	# yumuşak gölgeli üçgen (köşe normalleri)
	var n := na + nb + nc
	var cw := (c - a).cross(b - a)
	if cw.dot(n) < 0.0:
		var t := b
		b = c
		c = t
		var tn := nb
		nb = nc
		nc = tn
	st.set_color(col)
	st.set_normal(na)
	st.add_vertex(a)
	st.set_color(col)
	st.set_normal(nb)
	st.add_vertex(b)
	st.set_color(col)
	st.set_normal(nc)
	st.add_vertex(c)
	count += 3

func quad(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, n := Vector3.ZERO) -> void:
	if n == Vector3.ZERO:
		n = (b - a).cross(d - a)
		if n.length_squared() < 1e-10:
			n = Vector3.UP
	tri(a, b, c, col, n)
	tri(a, c, d, col, n)

func quad2(a: Vector3, b: Vector3, c: Vector3, d: Vector3, col: Color, n: Vector3) -> void:
	# çift yüzlü
	quad(a, b, c, d, col, n)
	quad(a, b, c, d, col.darkened(0.15), -n)

func box(center: Vector3, size: Vector3, col: Color, basis := Basis(), shade := true) -> void:
	var h := size * 0.5
	var p := [
		Vector3(-h.x, -h.y, -h.z), Vector3(h.x, -h.y, -h.z), Vector3(h.x, h.y, -h.z), Vector3(-h.x, h.y, -h.z),
		Vector3(-h.x, -h.y, h.z), Vector3(h.x, -h.y, h.z), Vector3(h.x, h.y, h.z), Vector3(-h.x, h.y, h.z)]
	for i in 8:
		p[i] = center + basis * p[i]
	var top := col
	var side := col.darkened(0.04) if shade else col
	var bot := col.darkened(0.25) if shade else col
	quad(p[3], p[2], p[6], p[7], top, basis.y)
	quad(p[0], p[1], p[5], p[4], bot, -basis.y)
	quad(p[4], p[5], p[6], p[7], side, basis.z)
	quad(p[0], p[1], p[2], p[3], side, -basis.z)
	quad(p[1], p[5], p[6], p[2], side, basis.x)
	quad(p[0], p[4], p[7], p[3], side, -basis.x)

func hull(center: Vector3, bot: Vector2, top: Vector2, h: float, col: Color, basis := Basis(), top_off := Vector2.ZERO) -> void:
	# bot/top: tam genişlik(x) ve uzunluk(z) ölçüleri
	var b := [Vector3(-bot.x, 0, -bot.y), Vector3(bot.x, 0, -bot.y), Vector3(bot.x, 0, bot.y), Vector3(-bot.x, 0, bot.y)]
	var t := [Vector3(-top.x, 0, -top.y), Vector3(top.x, 0, -top.y), Vector3(top.x, 0, top.y), Vector3(-top.x, 0, top.y)]
	var pb: Array = []
	var pt: Array = []
	for i in 4:
		pb.append(center + basis * (b[i] * 0.5))
		pt.append(center + basis * (t[i] * 0.5 + Vector3(top_off.x, h, top_off.y)))
	var cc := center + basis * Vector3(top_off.x * 0.5, h * 0.5, top_off.y * 0.5)
	quad(pt[0], pt[1], pt[2], pt[3], col, basis.y)
	quad(pb[0], pb[1], pb[2], pb[3], col.darkened(0.3), -basis.y)
	for i in 4:
		var j := (i + 1) % 4
		var n: Vector3 = (pb[j] - pb[i]).cross(pt[i] - pb[i])
		var mid: Vector3 = (pb[i] + pb[j] + pt[i] + pt[j]) * 0.25
		if n.dot(mid - cc) < 0.0:
			n = -n
		quad(pb[i], pb[j], pt[j], pt[i], col.darkened(0.05), n)

func cyl(center: Vector3, r0: float, r1: float, h: float, segs: int, col: Color, basis := Basis(), caps := true, smooth := true) -> void:
	# yerel Y ekseni boyunca; center alt merkez
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		var p0 := center + basis * (d0 * r0)
		var p1 := center + basis * (d1 * r0)
		var p2 := center + basis * (d1 * r1 + Vector3(0, h, 0))
		var p3 := center + basis * (d0 * r1 + Vector3(0, h, 0))
		if smooth:
			var n0 := basis * d0
			var n1 := basis * d1
			tri_s(p0, p1, p2, n0, n1, n1, col)
			tri_s(p0, p2, p3, n0, n1, n0, col)
		else:
			quad(p0, p1, p2, p3, col, basis * ((d0 + d1) * 0.5))
		if caps:
			var top := center + basis * Vector3(0, h, 0)
			if r1 > 0.0:
				tri(top, p3, p2, col, basis.y)
			if r0 > 0.0:
				tri(center, p0, p1, col.darkened(0.2), -basis.y)

func cyl_between(a: Vector3, b: Vector3, r0: float, r1: float, segs: int, col: Color, caps := true) -> void:
	var d := b - a
	var L := d.length()
	if L < 1e-4:
		return
	var y := d / L
	var x := y.cross(Vector3.UP)
	if x.length_squared() < 1e-4:
		x = y.cross(Vector3.RIGHT)
	x = x.normalized()
	var z := x.cross(y).normalized()
	cyl(a, r0, r1, L, segs, col, Basis(x, y, z), caps)

func sphere(center: Vector3, rad: Vector3, segs: int, rings: int, col: Color, basis := Basis(), hemi := false, jitter := 0.0, rng: RandomNumberGenerator = null) -> void:
	var pts: Array = []
	var r_end := rings / 2 if hemi else rings
	for r in r_end + 1:
		var row: Array = []
		var phi := PI * r / rings
		for s in segs + 1:
			var th := TAU * s / segs
			var n := Vector3(sin(phi) * cos(th), cos(phi), sin(phi) * sin(th))
			var k := 1.0
			if jitter > 0.0 and rng != null and s < segs and r > 0 and r < rings:
				k = 1.0 + rng.randf_range(-jitter, jitter)
			row.append(n * k)
		if jitter > 0.0 and segs > 0:
			row[segs] = row[0]
		pts.append(row)
	for r in r_end:
		for s in segs:
			var n00: Vector3 = pts[r][s]
			var n01: Vector3 = pts[r][s + 1]
			var n10: Vector3 = pts[r + 1][s]
			var n11: Vector3 = pts[r + 1][s + 1]
			var p00 := center + basis * (n00 * rad)
			var p01 := center + basis * (n01 * rad)
			var p10 := center + basis * (n10 * rad)
			var p11 := center + basis * (n11 * rad)
			var m00 := (basis * (n00 / rad)).normalized()
			var m01 := (basis * (n01 / rad)).normalized()
			var m10 := (basis * (n10 / rad)).normalized()
			var m11 := (basis * (n11 / rad)).normalized()
			if r > 0:
				tri_s(p00, p01, p11, m00, m01, m11, col)
			if r < rings - 1 or hemi:
				tri_s(p00, p11, p10, m00, m11, m10, col)
	if hemi:
		# taban kapağı
		var c := center
		for s in segs:
			var a: Vector3 = center + basis * (pts[r_end][s] * rad)
			var b: Vector3 = center + basis * (pts[r_end][s + 1] * rad)
			tri(c, a, b, col.darkened(0.3), -basis.y)

func prism(profile: PackedVector2Array, depth: float, col: Color, center := Vector3.ZERO, basis := Basis(), cap_col := Color(-1, 0, 0)) -> void:
	# XY düzlemindeki dışbükey profil, Z boyunca ekstrüde (-depth/2..depth/2)
	var n := profile.size()
	var cc := Vector2.ZERO
	for p in profile:
		cc += p
	cc /= n
	var cap := col if cap_col.r < 0.0 else cap_col
	var hz := depth * 0.5
	for i in n:
		var a := profile[i]
		var b := profile[(i + 1) % n]
		var pa0 := center + basis * Vector3(a.x, a.y, -hz)
		var pb0 := center + basis * Vector3(b.x, b.y, -hz)
		var pb1 := center + basis * Vector3(b.x, b.y, hz)
		var pa1 := center + basis * Vector3(a.x, a.y, hz)
		var e := b - a
		var nn := Vector2(e.y, -e.x)
		if nn.dot((a + b) * 0.5 - cc) < 0.0:
			nn = -nn
		var shade := clampf(0.5 + 0.5 * nn.normalized().y, 0.0, 1.0)
		quad(pa0, pb0, pb1, pa1, col.darkened(0.12 * (1.0 - shade)), basis * Vector3(nn.x, nn.y, 0))
		var c0 := center + basis * Vector3(cc.x, cc.y, -hz)
		var c1 := center + basis * Vector3(cc.x, cc.y, hz)
		tri(c0, pa0, pb0, cap.darkened(0.06), -basis.z)
		tri(c1, pa1, pb1, cap.darkened(0.06), basis.z)

func commit(mat: Material = null, mesh: ArrayMesh = null) -> ArrayMesh:
	if count == 0:
		return mesh if mesh != null else ArrayMesh.new()
	if mat:
		st.set_material(mat)
	var m := st.commit(mesh)
	return m

static func jit(c: Color, rng: RandomNumberGenerator, amt: float) -> Color:
	var k := 1.0 + rng.randf_range(-amt, amt)
	return Color(clampf(c.r * k, 0, 1), clampf(c.g * k, 0, 1), clampf(c.b * k, 0, 1), c.a)
