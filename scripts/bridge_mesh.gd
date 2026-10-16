class_name BridgeMesh extends RefCounted
# Köprü örgüleri (Roadmap 41). Yerel eksenler: x köprü boyunca, z enine, y yukarı; yol yüzü y≈0, su -0.6.
# Kısa köprüler (≤ STONE_MAX) kesme taş kemerli: parke taşı yol, kemer taşları, kordon silmesi, akıntı
# burunlu ayaklar, harpuştalı taş korkuluk, uçlarda dışa açılan kanat korkulukları. Uzunlar betonarme:
# açıklık başına döşeme (asfalt, tekerlek izi, yama, şerit çizgileri, bordürlü kaldırım, ızgara, genleşme
# derzi, damlalıklı ön yüz kirişi), yuvarlak burunlu duvar ayaklar, çelik korkuluk + W kiriş, aydınlatma
# direkleri, uç ayak + kanat duvarı, yaklaşımda bariyer.
# Döşeme her açıklıkta iki yarı (açıklık ortasından): hasarda yalnız vurulan yarı delikleriyle yeniden
# örülür (karo karo; delik çevresinde 12,5 cm'lik alt karolar, kırık kenar yüzleri; betonda delikten su
# görünür ve kopuk donatı sarkar, taşta dolgu görünür). Çöküşte yarılar mesnetleri etrafında suya döner.

const STONE_MAX := 30.0         # ≤ 20 m hep taş, 20–30 m arası konuma göre taş ya da beton
const TILE := 0.5
const SUB := 4
const SLAB_B := -0.42           # betonarme döşeme altı
const FASCIA_B := -0.55         # ön yüz kirişi altı (su -0.6)
const EB := 0.22                # kenar kirişi üstü (korkuluk ayağı)
const SW := 0.45                # kaldırım
const CURB := 0.15
const PAR := 0.4                # taş korkuluk duvarı kalınlığı
const WATER := -0.6

# köşe rengi alfası = masonry malzeme kodu (1 - a) × 10: 0 → beton dokusu, 0.9 → kesme taş, 0.5 → kaba sıva, 0.2 → çelik
const C_ASPH := Color(0.35, 0.35, 0.355, 0.0)
const C_PATCH := Color(0.315, 0.315, 0.32, 0.0)
const C_PAINT := Color(0.84, 0.84, 0.8, 0.0)
const C_CONC := Color(0.6, 0.59, 0.56, 0.0)
const C_WALK := Color(0.53, 0.52, 0.5, 0.0)
const C_CURB := Color(0.67, 0.66, 0.63, 0.0)
const C_STEEL := Color(0.24, 0.24, 0.25, 0.2)
const C_STONE := Color(0.64, 0.6, 0.53, 0.9)
const C_SETT := Color(0.52, 0.5, 0.46, 0.9)
const C_DARK := Color(0.05, 0.05, 0.05, 0.0)
const C_FILL := Color(0.34, 0.29, 0.23, 0.5)
const C_REBAR := Color(0.36, 0.25, 0.19, 0.2)

static func span_count(stone: bool, Ld: float) -> int:
	if stone:
		return clampi(int(round(Ld / 9.0)), 1, 3)
	return maxi(2, int(ceil(Ld / 16.0)))

# enine kesit şeritleri: [z0, z1, üst y, renk]
static func strips(stone: bool, W: float) -> Array:
	var hw := W * 0.5
	if stone:
		var g := hw - PAR
		var gc := C_SETT.darkened(0.14)
		return [[-hw, -g, 0.0, C_STONE], [-g, -g + 0.3, 0.02, gc], [-g + 0.3, g - 0.3, 0.03, C_SETT], [g - 0.3, g, 0.02, gc], [g, hw, 0.0, C_STONE]]
	var wc := hw - EB - SW
	return [[-hw, -hw + EB, 0.2, C_CONC], [-hw + EB, -wc - CURB, 0.12, C_WALK], [-wc - CURB, -wc, 0.12, C_CURB], [-wc, wc, 0.03, C_ASPH],
		[wc, wc + CURB, 0.12, C_CURB], [wc + CURB, hw - EB, 0.12, C_WALK], [hw - EB, hw, 0.2, C_CONC]]

static func _sy(strs: Array, z: float) -> float:
	for st in strs:
		if z >= float(st[0]) - 0.001 and z <= float(st[1]) + 0.001:
			return st[2]
	return 0.0

# delik sınırı: açıya göre girintili (kırık beton / taş)
static func _in_hole(x: float, z: float, holes: Array) -> bool:
	for h in holes:
		var c: Vector2 = h[0]
		var r: float = h[1]
		var dx := x - c.x
		var dz := z - c.y
		var d2 := dx * dx + dz * dz
		if d2 > r * r * 1.25:
			continue
		var sd: float = h[2]
		var a := atan2(dz, dx)
		var rr := r * (0.82 + 0.13 * sin(a * 3.0 + sd) + 0.09 * sin(a * 5.0 + sd * 2.3) + 0.06 * sin(a * 9.0 + sd * 0.7))
		if d2 < rr * rr:
			return true
	return false

static func _near_hole(x: float, z: float, ext: float, holes: Array) -> bool:
	for h in holes:
		var c: Vector2 = h[0]
		if Vector2(x - c.x, z - c.y).length() < float(h[1]) * 1.15 + ext:
			return true
	return false

static func _top(mb: MB, x: float, z: float, dx: float, dz: float, y: float, col: Color) -> void:
	mb.quad(Vector3(x, y, z), Vector3(x + dx, y, z), Vector3(x + dx, y, z + dz), Vector3(x, y, z + dz), col, Vector3.UP)

static func _asph_col(x: float, z: float, wc: float, patches: Array) -> Color:
	for p in patches:
		if (p as Rect2).has_point(Vector2(x, z)):
			return C_PATCH
	# tekerlek yolu cilalı (açık), şerit ortası yağ lekeli (koyu)
	var lane := absf(absf(z) - wc * 0.5)
	if lane > 0.55 and lane < 1.05:
		return C_ASPH.lightened(0.025)
	if lane < 0.3:
		return C_ASPH.darkened(0.035)
	return C_ASPH

# döşeme yüzü: enine şeritler × boyuna karolar; delik çevresinde alt karolar ve deliğe bakan kırık yüzler
static func _deck(mb: MB, x0: float, x1: float, s: float, hw: float, strs: Array, holes: Array, wb: float, fill: bool, wall_col: Color, patches: Array, wc: float) -> void:
	var nx := maxi(1, int(ceil((x1 - x0) / TILE - 0.01)))
	var dx := (x1 - x0) / nx
	for st in strs:
		var z0: float = st[0]
		var z1: float = st[1]
		var y: float = st[2]
		var base: Color = st[3]
		var nz := maxi(1, int(ceil((z1 - z0) / TILE - 0.01)))
		var dz := (z1 - z0) / nz
		for i in nx:
			var ax := x0 + i * dx
			for j in nz:
				var az := z0 + j * dz
				var col := _asph_col(ax + dx * 0.5, az + dz * 0.5, wc, patches) if base == C_ASPH else base
				if holes.is_empty() or not _near_hole(ax + dx * 0.5, az + dz * 0.5, dx + dz, holes):
					_top(mb, ax, az, dx, dz, y, col)
					continue
				var sx := dx / SUB
				var sz := dz / SUB
				for a in SUB:
					for b in SUB:
						var cx := ax + (a + 0.5) * sx
						var cz := az + (b + 0.5) * sz
						if not _in_hole(cx, cz, holes):
							_top(mb, ax + a * sx, az + b * sz, sx, sz, y, col)
							continue
						if fill:
							_top(mb, ax + a * sx, az + b * sz, sx, sz, wb, C_FILL)
						for e in 4:
							var ex: float = [1.0, -1.0, 0.0, 0.0][e]
							var ez: float = [0.0, 0.0, 1.0, -1.0][e]
							var nxp := cx + ex * sx
							var nzp := cz + ez * sz
							if absf(nxp) > s * 0.5 or absf(nzp) > hw or _in_hole(nxp, nzp, holes):
								continue
							var ny := _sy(strs, nzp)
							var px := cx + ex * sx * 0.5
							var pz := cz + ez * sz * 0.5
							var hx := absf(ez) * sx * 0.5
							var hz := absf(ex) * sz * 0.5
							mb.quad(Vector3(px - hx, wb, pz - hz), Vector3(px + hx, wb, pz + hz), Vector3(px + hx, ny, pz + hz), Vector3(px - hx, ny, pz - hz), wall_col, Vector3(-ex, 0, -ez))

# şerit çizgileri: ortada kesikli (3 m çizgi, 5 m boşluk), kenarda sürekli
static func _marks(mb: MB, x0: float, x1: float, wc: float, holes: Array) -> void:
	var nx := maxi(1, int(ceil((x1 - x0) / TILE - 0.01)))
	var dx := (x1 - x0) / nx
	for ln in [[0.0, true], [wc - 0.3, false], [-(wc - 0.3), false]]:
		var zc: float = ln[0]
		for i in nx:
			var xa := x0 + i * dx
			var xm := xa + dx * 0.5
			if ln[1] and fposmod(xm + 1.5, 8.0) > 3.0:
				continue
			if _in_hole(xm, zc, holes) or _in_hole(xa, zc, holes) or _in_hole(xa + dx, zc, holes):
				continue
			_top(mb, xa, zc - 0.06, dx, 0.12, 0.036, C_PAINT)

static func _conc_faces(mb: MB, x0: float, x1: float, s: float, hw: float, hs: int, strs: Array, holes: Array) -> void:
	var fc := C_CONC.lightened(0.05)
	for sg in [-1.0, 1.0]:
		var zo: float = sg * hw
		mb.quad(Vector3(x0, FASCIA_B, zo), Vector3(x1, FASCIA_B, zo), Vector3(x1, 0.2, zo), Vector3(x0, 0.2, zo), fc, Vector3(0, 0, sg))
		var zd: float = sg * (hw + 0.004)
		mb.quad(Vector3(x0, -0.37, zd), Vector3(x1, -0.37, zd), Vector3(x1, -0.345, zd), Vector3(x0, -0.345, zd), fc.darkened(0.35), Vector3(0, 0, sg))
		var zi: float = sg * (hw - 0.25)
		mb.quad(Vector3(x0, FASCIA_B, zi), Vector3(x1, FASCIA_B, zi), Vector3(x1, SLAB_B, zi), Vector3(x0, SLAB_B, zi), fc.darkened(0.2), Vector3(0, 0, -sg))
		mb.quad(Vector3(x0, FASCIA_B, zi), Vector3(x1, FASCIA_B, zi), Vector3(x1, FASCIA_B, zo), Vector3(x0, FASCIA_B, zo), fc.darkened(0.3), Vector3.DOWN)
	mb.quad(Vector3(x0, SLAB_B, -hw + 0.25), Vector3(x1, SLAB_B, -hw + 0.25), Vector3(x1, SLAB_B, hw - 0.25), Vector3(x0, SLAB_B, hw - 0.25), C_CONC.darkened(0.3), Vector3.DOWN)
	# uç kesitleri
	for xe in [x0, x1]:
		var nxx := -1.0 if xe == x0 else 1.0
		for st in strs:
			var z0: float = st[0]
			var z1: float = st[1]
			var yb := FASCIA_B if (absf(z0) > hw - EB - 0.05 or absf(z1) > hw - EB - 0.05) else SLAB_B
			mb.quad(Vector3(xe, yb, z0), Vector3(xe, yb, z1), Vector3(xe, st[2], z1), Vector3(xe, st[2], z0), C_CONC.darkened(0.12), Vector3(nxx, 0, 0))
	# bordür ve kenar kirişi düşey yüzleri
	var nx := maxi(1, int(ceil((x1 - x0) / TILE - 0.01)))
	var dx := (x1 - x0) / nx
	for i in strs.size() - 1:
		var A: Array = strs[i]
		var B: Array = strs[i + 1]
		var ya: float = A[2]
		var yb2: float = B[2]
		if absf(ya - yb2) < 0.025:
			continue
		var zb: float = A[1]
		var hi_s := -1.0 if ya > yb2 else 1.0
		var col: Color = (A[3] as Color) if ya > yb2 else (B[3] as Color)
		for k in nx:
			var xa := x0 + k * dx
			var xm := xa + dx * 0.5
			if _in_hole(xm, zb + hi_s * 0.06, holes) or _in_hole(xm, zb - hi_s * 0.06, holes):
				continue
			var lo := minf(ya, yb2)
			var hi := maxf(ya, yb2)
			mb.quad(Vector3(xa, lo, zb), Vector3(xa + dx, lo, zb), Vector3(xa + dx, hi, zb), Vector3(xa, hi, zb), col.darkened(0.08), Vector3(0, 0, -hi_s))
	# genleşme derzi (açıklık ucunda çift çelik lama) ve yağmur ızgaraları
	var wc := hw - EB - SW
	var xj := x0 + 0.04 if hs < 0 else x1 - 0.14
	for st in strs:
		var z0: float = st[0]
		var z1: float = st[1]
		if absf(z0) > hw - EB - 0.01 or absf(z1) > hw - EB - 0.01:
			continue
		if _in_hole(xj + 0.05, (z0 + z1) * 0.5, holes):
			continue
		_top(mb, xj, z0, 0.1, z1 - z0, float(st[2]) + 0.006, C_STEEL)
	for k in range(-4, 5):
		var xg := k * 6.0 + 3.0
		if xg - 0.2 < x0 or xg + 0.2 > x1 or absf(xg) > s * 0.5 - 0.5:
			continue
		for sg in [-1.0, 1.0]:
			var zg: float = sg * (wc - 0.14)
			if not _in_hole(xg, zg, holes):
				_top(mb, xg - 0.22, zg - 0.11, 0.44, 0.22, 0.034, C_STEEL)

static func _stone_faces(mb: MB, x0: float, x1: float, s: float, hw: float, hs: int) -> void:
	var yb := WATER - 0.03
	for sg in [-1.0, 1.0]:
		var zo: float = sg * hw
		mb.quad(Vector3(x0, yb, zo), Vector3(x1, yb, zo), Vector3(x1, 0.0, zo), Vector3(x0, 0.0, zo), C_STONE, Vector3(0, 0, sg))
		# kordon silmesi
		var zc: float = sg * (hw + 0.05)
		var sc := C_STONE.lightened(0.1)
		mb.quad(Vector3(x0, -0.13, zc), Vector3(x1, -0.13, zc), Vector3(x1, -0.03, zc), Vector3(x0, -0.03, zc), sc, Vector3(0, 0, sg))
		mb.quad(Vector3(x0, -0.03, zo), Vector3(x1, -0.03, zo), Vector3(x1, -0.03, zc), Vector3(x0, -0.03, zc), sc.lightened(0.05), Vector3.UP)
		mb.quad(Vector3(x0, -0.13, zo), Vector3(x1, -0.13, zo), Vector3(x1, -0.13, zc), Vector3(x0, -0.13, zc), sc.darkened(0.3), Vector3.DOWN)
		for xe in [x0, x1]:
			var nxx := -1.0 if xe == x0 else 1.0
			mb.quad(Vector3(xe, -0.13, zo), Vector3(xe, -0.13, zc), Vector3(xe, -0.03, zc), Vector3(xe, -0.03, zo), sc.darkened(0.1), Vector3(nxx, 0, 0))
		_arch_face(mb, x0, x1, s, hw, hs, sg)
	mb.quad(Vector3(x0, yb, -hw), Vector3(x1, yb, -hw), Vector3(x1, yb, hw), Vector3(x0, yb, hw), C_STONE.darkened(0.3), Vector3.DOWN)
	for xe in [x0, x1]:
		var nxx := -1.0 if xe == x0 else 1.0
		mb.quad(Vector3(xe, yb, -hw), Vector3(xe, yb, hw), Vector3(xe, 0.03, hw), Vector3(xe, 0.03, -hw), C_STONE.darkened(0.1), Vector3(nxx, 0, 0))

# kemer: ön yüzde su üstünde kalan açıklık (karanlık) + çıkıntılı kemer taşları (kilit taşı açık renk)
static func _arch_face(mb: MB, x0: float, x1: float, s: float, hw: float, hs: int, sg: float) -> void:
	var R := s * 0.5 - 0.8
	if R < 0.8:
		return
	var yi := -0.34
	var t := 0.26
	var yc := yi - R
	var yw := WATER - 0.03
	var xa := sqrt(maxf(R * R - pow(yw - yc, 2.0), 0.0))
	var lo := maxf(-xa, x0)
	var hi := minf(xa, x1)
	var zo := sg * (hw + 0.008)
	if hi > lo:
		var N := 10
		for i in N:
			var u0 := lerpf(lo, hi, float(i) / N)
			var u1 := lerpf(lo, hi, float(i + 1) / N)
			var v0 := yc + sqrt(maxf(R * R - u0 * u0, 0.0))
			var v1 := yc + sqrt(maxf(R * R - u1 * u1, 0.0))
			mb.quad(Vector3(u0, yw, zo), Vector3(u1, yw, zo), Vector3(u1, maxf(v1, yw), zo), Vector3(u0, maxf(v0, yw), zo), C_DARK, Vector3(0, 0, sg))
	var nv := maxi(7, int(round(PI * R / 0.34)))
	if nv % 2 == 0:
		nv += 1
	var zr := sg * (hw + 0.02)
	for j in nv:
		var ta := PI * j / nv
		var tb := PI * (j + 1) / nv
		var xm := cos((ta + tb) * 0.5) * (R + t * 0.5)
		if (hs < 0 and xm >= -0.001) or (hs > 0 and xm < -0.001):
			continue
		var pa := Vector3(cos(ta) * R, maxf(yc + sin(ta) * R, yw), zr)
		var pb := Vector3(cos(tb) * R, maxf(yc + sin(tb) * R, yw), zr)
		var qa := Vector3(cos(ta) * (R + t), maxf(yc + sin(ta) * (R + t), yw), zr)
		var qb := Vector3(cos(tb) * (R + t), maxf(yc + sin(tb) * (R + t), yw), zr)
		if qa.y <= yw + 0.001 and qb.y <= yw + 0.001:
			continue
		var col := C_STONE.lightened(0.16) if j == nv / 2 else (C_STONE.lightened(0.07) if j % 2 == 0 else C_STONE.darkened(0.03))
		mb.quad(pa, pb, qb, qa, col, Vector3(0, 0, sg))

# yatay levha (W kiriş): a → b boyunca, yükseklik h, kalınlık th
static func _beam(mb: MB, a: Vector3, b: Vector3, h: float, th: float, col: Color) -> void:
	var d := b - a
	var L := Vector2(d.x, d.z).length()
	if L < 0.01:
		return
	var x := Vector3(d.x, 0, d.z) / L
	mb.box((a + b) * 0.5, Vector3(L, h, th), col, Basis(x, Vector3.UP, x.cross(Vector3.UP)))

static func _rod(mb: MB, a: Vector3, b: Vector3, th: float, col: Color) -> void:
	var d := b - a
	var L := d.length()
	if L < 0.01:
		return
	var x := d / L
	var up := Vector3.UP if absf(x.y) < 0.9 else Vector3.RIGHT
	var z := x.cross(up).normalized()
	var y := z.cross(x).normalized()
	mb.box((a + b) * 0.5, Vector3(L, th, th), col, Basis(x, y, z))

# delik ayrıntısı: kenarda kalkmış parçalar; betonda iki yönde kopuk / sarkık donatı
static func _hole_detail(mb: MB, h: Array, x0: float, x1: float, stone: bool) -> void:
	var c: Vector2 = h[0]
	var r: float = h[1]
	var sd: float = h[2]
	var rr := RandomNumberGenerator.new()
	rr.seed = int(sd * 1000.0) + 17
	for k in 8:
		var a := rr.randf() * TAU
		var d := r * rr.randf_range(0.95, 1.7)
		var p := Vector2(c.x + cos(a) * d, c.y + sin(a) * d)
		if p.x < x0 or p.x > x1:
			continue
		var sz := rr.randf_range(0.07, 0.24)
		var col := (C_SETT if stone else C_CONC).darkened(rr.randf_range(0.0, 0.25))
		mb.box(Vector3(p.x, 0.05 + sz * 0.25, p.y), Vector3(sz * 1.3, sz * 0.55, sz), col, Basis.from_euler(Vector3(rr.randf_range(-0.5, 0.5), rr.randf() * TAU, rr.randf_range(-0.5, 0.5))))
	if stone:
		return
	for axis in 2:
		var t := -r * 0.75
		while t <= r * 0.75:
			var hl := sqrt(maxf(r * r * 0.55 - t * t, 0.0))
			if hl > 0.12:
				var y := -0.07 if axis == 0 else -0.1
				var sag := rr.randf_range(0.04, 0.32)
				var m := rr.randf_range(-0.3, 0.3) * hl
				var a3: Vector3
				var b3: Vector3
				var m3: Vector3
				if axis == 0:
					a3 = Vector3(c.x - hl - 0.1, y, c.y + t)
					b3 = Vector3(c.x + hl + 0.1, y, c.y + t)
					m3 = Vector3(c.x + m, y - sag, c.y + t)
				else:
					a3 = Vector3(c.x + t, y, c.y - hl - 0.1)
					b3 = Vector3(c.x + t, y, c.y + hl + 0.1)
					m3 = Vector3(c.x + t, y - sag, c.y + m)
				var cut := rr.randf()
				if m3.x >= x0 and m3.x <= x1:
					if cut < 0.25:
						# kopmuş: tek uç aşağı sarkar
						_rod(mb, a3, m3 + (m3 - a3).normalized() * 0.05 + Vector3(0, -0.25, 0), 0.022, C_REBAR)
					elif cut < 0.4:
						_rod(mb, b3, m3 + (m3 - b3).normalized() * 0.05 + Vector3(0, -0.25, 0), 0.022, C_REBAR)
					else:
						_rod(mb, a3, m3, 0.022, C_REBAR)
						_rod(mb, m3, b3, 0.022, C_REBAR)
			t += 0.2

# açıklık yarısı: hs -1 → x ∈ [-s/2, 0], +1 → [0, s/2]; holes: [[Vector2(x, z) açıklık yerel, r, tohum], ...]
static func half(stone: bool, s: float, W: float, hs: int, holes: Array) -> ArrayMesh:
	var mb := MB.new()
	var hw := W * 0.5
	var x0 := -s * 0.5 if hs < 0 else 0.0
	var x1 := 0.0 if hs < 0 else s * 0.5
	var strs := strips(stone, W)
	if stone:
		_deck(mb, x0, x1, s, hw, strs, holes, -0.42, true, C_STONE.darkened(0.12), [], 0.0)
		_stone_faces(mb, x0, x1, s, hw, hs)
	else:
		var wc := hw - EB - SW
		var r := RandomNumberGenerator.new()
		r.seed = int(s * 100.0) * 7 + int(W * 100.0) * 13 + hs * 5 + 3
		var patches: Array = []
		for k in r.randi_range(1, 2):
			var pw := r.randf_range(0.8, 2.2)
			patches.append(Rect2(r.randf_range(x0 + 0.3, x1 - pw - 0.3), r.randf_range(-wc, wc - 1.2), pw, r.randf_range(0.6, 1.3)))
		_deck(mb, x0, x1, s, hw, strs, holes, SLAB_B, false, C_CONC.darkened(0.15), patches, wc)
		_marks(mb, x0, x1, wc, holes)
		_conc_faces(mb, x0, x1, s, hw, hs, strs, holes)
	for h in holes:
		_hole_detail(mb, h, x0, x1, stone)
	return mb.commit(Mats.bridge())

# dikey prizma (xz çokgeni), dış yüzler + üst kapak
static func _prism_y(mb: MB, pts: Array, y0: float, y1: float, col: Color, top := true) -> void:
	var cc := Vector2.ZERO
	for p in pts:
		cc += p
	cc /= pts.size()
	for i in pts.size():
		var a: Vector2 = pts[i]
		var b: Vector2 = pts[(i + 1) % pts.size()]
		var e := b - a
		var n := Vector2(e.y, -e.x)
		if n.dot((a + b) * 0.5 - cc) < 0.0:
			n = -n
		mb.quad(Vector3(a.x, y0, a.y), Vector3(b.x, y0, b.y), Vector3(b.x, y1, b.y), Vector3(a.x, y1, a.y), col.darkened(0.04), Vector3(n.x, 0, n.y))
	if top:
		for i in range(1, pts.size() - 1):
			var a: Vector2 = pts[0]
			var b: Vector2 = pts[i]
			var c: Vector2 = pts[i + 1]
			mb.tri(Vector3(a.x, y1, a.y), Vector3(b.x, y1, b.y), Vector3(c.x, y1, c.y), col, Vector3.UP)

# eğimli üstlü duvar parçası: a → b (xz), kalınlık, a ucunda [alt, üst], b ucunda [alt, üst]
static func _wall(mb: MB, a: Vector3, b: Vector3, th: float, ya0: float, ya1: float, yb0: float, yb1: float, col: Color) -> void:
	var d := Vector3(b.x - a.x, 0, b.z - a.z).normalized()
	var n := Vector3(-d.z, 0, d.x) * th * 0.5
	var a0 := Vector3(a.x, 0, a.z) - n
	var a1 := Vector3(a.x, 0, a.z) + n
	var b0 := Vector3(b.x, 0, b.z) - n
	var b1 := Vector3(b.x, 0, b.z) + n
	var top := [a0 + Vector3(0, ya1, 0), a1 + Vector3(0, ya1, 0), b1 + Vector3(0, yb1, 0), b0 + Vector3(0, yb1, 0)]
	var bot := [a0 + Vector3(0, ya0, 0), a1 + Vector3(0, ya0, 0), b1 + Vector3(0, yb0, 0), b0 + Vector3(0, yb0, 0)]
	var tn: Vector3 = ((top[1] - top[0]).cross(top[3] - top[0])).normalized()
	if tn.y < 0.0:
		tn = -tn
	mb.quad(top[0], top[1], top[2], top[3], col.lightened(0.04), tn)
	mb.quad(bot[0], bot[3], top[3], top[0], col, -n)
	mb.quad(bot[1], bot[2], top[2], top[1], col, n)
	mb.quad(bot[0], bot[1], top[1], top[0], col.darkened(0.05), -d)
	mb.quad(bot[3], bot[2], top[2], top[3], col.darkened(0.05), d)

static func _stone_pier(mb: MB, xb: float, hw: float) -> void:
	mb.box(Vector3(xb, -1.5, 0), Vector3(1.6, 2.2, 2.0 * hw), C_STONE.darkened(0.08))
	for sg in [-1.0, 1.0]:
		var b0 := Vector2(xb - 0.8, sg * hw)
		var b1 := Vector2(xb + 0.8, sg * hw)
		var tip := Vector2(xb, sg * (hw + 1.3))
		_prism_y(mb, [b0, b1, tip], -2.6, -0.38, C_STONE, false)
		# burun başlığı: ayak yüzünden uca inen eğik yüzler
		var apex := Vector3(xb, 0.04, sg * hw)
		var t3 := Vector3(tip.x, -0.38, tip.y)
		var c := C_STONE.lightened(0.08)
		mb.tri(Vector3(b0.x, -0.38, b0.y), t3, apex, c, Vector3(-0.6, 1.0, sg * 0.8))
		mb.tri(Vector3(b1.x, -0.38, b1.y), t3, apex, c, Vector3(0.6, 1.0, sg * 0.8))

static func _conc_pier(mb: MB, xb: float, hw: float) -> void:
	var zl := hw + 0.15
	var col := C_CONC.darkened(0.06)
	mb.box(Vector3(xb, -1.62, 0), Vector3(0.9, 2.36, 2.0 * zl), col)
	for sg in [-1.0, 1.0]:
		mb.cyl(Vector3(xb, -2.8, sg * zl), 0.45, 0.45, 2.36, 14, col)
	mb.box(Vector3(xb, -0.53, 0), Vector3(1.2, 0.18, 2.0 * hw - 0.2), C_CONC)

# sabit kısımlar: ara ayaklar, uç ayaklar, kanat duvarları, (betonda) yaklaşım bariyerleri
static func static_mesh(stone: bool, Ld: float, n: int, W: float) -> ArrayMesh:
	var mb := MB.new()
	var ms := MB.new()
	var hw := W * 0.5
	var s := Ld / n
	for k in range(1, n):
		var xb := -Ld * 0.5 + k * s
		if stone:
			_stone_pier(mb, xb, hw)
		else:
			_conc_pier(mb, xb, hw)
	for e in [-1.0, 1.0]:
		var xe: float = e * Ld * 0.5
		if stone:
			mb.box(Vector3(xe + e * 0.4, -1.3, 0), Vector3(0.8, 2.6, 2.0 * hw), C_STONE.darkened(0.05))
			for sg in [-1.0, 1.0]:
				# dışa açılan kanat korkuluğu + harpuşta, uçta baba taşı
				var a := Vector3(xe, 0, sg * (hw - PAR * 0.5))
				var d := Vector3(e * cos(deg_to_rad(25.0)), 0, sg * sin(deg_to_rad(25.0)))
				var b := a + d * 3.0
				_wall(mb, a, b, PAR, -1.2, 0.82, -1.2, 0.6, C_STONE)
				_wall(mb, a, b, PAR + 0.08, 0.82, 0.96, 0.6, 0.74, C_STONE.lightened(0.12))
				mb.box(Vector3(b.x, 0.45, b.z), Vector3(0.62, 1.1, 0.62), C_STONE.lightened(0.03))
				mb.box(Vector3(b.x, 1.05, b.z), Vector3(0.74, 0.1, 0.74), C_STONE.lightened(0.14))
				mb.box(Vector3(b.x, 1.16, b.z), Vector3(0.4, 0.12, 0.4), C_STONE.lightened(0.1))
		else:
			mb.box(Vector3(xe + e * 0.35, -1.3, 0), Vector3(0.7, 2.6, 2.0 * hw + 0.3), C_CONC.darkened(0.04))
			for sg in [-1.0, 1.0]:
				# kanat duvarı: uç ayak hizasında kıyı boyunca, toprağa gömülerek alçalır
				var a := Vector3(xe + e * 0.35, 0, sg * (hw + 0.1))
				var d := Vector3(e * sin(deg_to_rad(15.0)), 0, sg * cos(deg_to_rad(15.0)))
				_wall(mb, a, a + d * 2.6, 0.3, -2.4, 0.16, -2.4, 0.0, C_CONC.darkened(0.12))
				_approach_rail(ms, xe, e, sg, hw)
	var m := mb.commit(Mats.bridge())
	if ms.count > 0:
		ms.commit(Mats.metal_s(), m)
	return m

# yaklaşım bariyeri: köprü ucundan 6 m, son 1,5 m dışa kıvrılır; 2 m'de bir dikme
static func _approach_rail(ms: MB, xe: float, e: float, sg: float, hw: float) -> void:
	var gal := Color(0.66, 0.67, 0.66)
	var pts: Array = []
	for k in 5:
		var u := k * 1.5
		var z := hw - 0.3 + (0.0 if u < 4.4 else (u - 4.4) * 0.35)
		pts.append(Vector3(xe + e * u, 0.0, sg * z))
	for k in pts.size() - 1:
		var a: Vector3 = pts[k]
		var b: Vector3 = pts[k + 1]
		_beam(ms, a + Vector3(0, 0.55, 0), b + Vector3(0, 0.55, 0), 0.31, 0.035, gal)
	for k in [0, 2, 4]:
		var p: Vector3 = pts[k]
		ms.box(Vector3(p.x, 0.36, p.z + sg * 0.12), Vector3(0.08, 0.78, 0.08), gal.darkened(0.1))

# korkuluk parçası (4 m birim, köprüde boyca ölçeklenir; dış yüz +z)
static func rail_seg(stone: bool) -> ArrayMesh:
	var mb := MB.new()
	if stone:
		mb.box(Vector3(0, 0.41, 0), Vector3(4.0, 0.82, PAR), C_STONE)
		for i in 4:
			var c := C_STONE.lightened(0.1 + 0.05 * sin(i * 2.7 + 0.4))
			mb.box(Vector3(-1.5 + i, 0.89, 0), Vector3(0.985, 0.14, PAR + 0.08), c)
		return mb.commit(Mats.bridge())
	var gal := Color(0.66, 0.67, 0.66)
	var paint := Color(0.29, 0.33, 0.32)
	for x in [-1.0, 1.0]:
		mb.box(Vector3(x, 0.01, 0), Vector3(0.2, 0.02, 0.2), gal)
		mb.box(Vector3(x, 0.52, 0), Vector3(0.08, 1.02, 0.08), paint)
		mb.box(Vector3(x, 0.55, -0.1), Vector3(0.06, 0.18, 0.14), gal)
	mb.box(Vector3(0, 0.55, -0.19), Vector3(4.0, 0.31, 0.035), gal)
	mb.box(Vector3(0, 0.55, -0.212), Vector3(4.0, 0.06, 0.02), gal.darkened(0.18))
	mb.box(Vector3(0, 1.05, 0), Vector3(4.0, 0.07, 0.11), paint)
	mb.box(Vector3(0, 0.82, 0), Vector3(4.0, 0.04, 0.04), paint)
	return mb.commit(Mats.metal_s())

# aydınlatma direği (taban y=0, kol -z yönünde yola uzanır)
static func pole() -> ArrayMesh:
	var mb := MB.new()
	var gal := Color(0.62, 0.63, 0.62)
	mb.box(Vector3(0, 0.02, 0), Vector3(0.36, 0.04, 0.36), gal)
	mb.cyl(Vector3(0, 0.04, 0), 0.1, 0.065, 7.4, 8, gal)
	mb.cyl_between(Vector3(0, 7.3, 0), Vector3(0, 7.78, -1.5), 0.045, 0.04, 6, gal)
	mb.box(Vector3(0, 7.74, -1.72), Vector3(0.26, 0.12, 0.62), Color(0.32, 0.33, 0.34))
	mb.box(Vector3(0, 7.675, -1.72), Vector3(0.2, 0.01, 0.5), Color(0.92, 0.92, 0.84))
	return mb.commit(Mats.metal_s())

# kırık uç: x=0 kırık çizgisi, döşeme -x yönünde; pürüzlü parçalar + (betonda) dışarı taşan demirler
static func broken_edge(stone: bool, W: float, seed: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = seed
	var mb := MB.new()
	var hw := W * 0.5
	var z := -hw + 0.1
	while z < hw - 0.15:
		var w := r.randf_range(0.25, 0.55)
		var sz := Vector3(r.randf_range(0.22, 0.5), r.randf_range(0.18, 0.4), w)
		var col := (C_STONE if stone else C_CONC).darkened(r.randf_range(0.0, 0.2))
		var bs := Basis.from_euler(Vector3(r.randf_range(-0.4, 0.4), r.randf_range(-0.5, 0.5), r.randf_range(-0.5, 0.5)))
		mb.box(Vector3(r.randf_range(-0.25, 0.05), r.randf_range(-0.28, -0.04), z + w * 0.5), sz, col, bs)
		z += w * r.randf_range(0.7, 1.0)
	if not stone:
		for layer in [-0.08, -0.32]:
			var zz := -hw + 0.3
			while zz < hw - 0.3:
				var L := r.randf_range(0.25, 0.9)
				var droop := r.randf_range(0.0, 0.7)
				_rod(mb, Vector3(-0.15, layer, zz), Vector3(L, layer - droop * L, zz + r.randf_range(-0.08, 0.08)), 0.024, C_REBAR)
				zz += r.randf_range(0.18, 0.32)
	return mb.commit(Mats.bridge())

# beton kırığı: yassı düzensiz parça + dışarı taşan demirler
static func conc_chunk(v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 57 + v
	var mb := MB.new()
	mb.sphere(Vector3.ZERO, Vector3(0.62, 0.22, 0.46) * (1.0 + 0.25 * v), 5, 4, C_CONC.darkened(0.05 * v), Basis(), false, 0.3, r)
	for k in 3:
		_rod(mb, Vector3(r.randf_range(-0.3, 0.3), 0.05, r.randf_range(-0.2, 0.2)), Vector3(r.randf_range(-1.0, 1.0), r.randf_range(-0.2, 0.4), r.randf_range(-0.8, 0.8)), 0.024, C_REBAR)
	return mb.commit(Mats.bridge())

# yıkıntı taşı (düzensiz)
static func stone_chunk(v: int) -> ArrayMesh:
	var r := RandomNumberGenerator.new()
	r.seed = 31 + v
	var mb := MB.new()
	mb.sphere(Vector3.ZERO, Vector3(0.32, 0.22, 0.27) * (1.0 + 0.2 * v), 6, 4, C_STONE.darkened(0.05 * v), Basis(), false, 0.28, r)
	return mb.commit(Mats.bridge())
