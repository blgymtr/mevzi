class_name MapGenBattle extends RefCounted
# Büyük Muharebe (4×4 km — kullanıcı kararı 17 Ekim: 8 km aşırı büyüktü; roadmap 21/53): Broken Arrow büyüklüğünde, CoH3 yoğunluğunda cephe haritası.
# Kuzeyden güneye kıvrılan ana nehir cepheyi ikiye böler — batı yaka Mihver (RUS), doğu yaka Müttefik (ABD).
# Altı geçit: otoyol ve kasaba köprüsü (merkez), kuzey ve güney köprübaşları, iki uç köprü; doğudan bir kol.
# Merkez kasaba nehrin iki yakasında sokak ızgarası (meydan, simge yapılar, sanayi), iki yan kasaba,
# on üç köy, çiftlikler; büyük ormanlar, koruluklar, kıyı ormanı, ağaç sıraları; ekin desenli tarlalar;
# demiryolu ve istasyon; haritada tanımlı hedef bölgeleri ve ileri üs noktaları.
# Yerleşim MapGen'in kayıtlı işlemleriyle yapılır (editörde açılır/kaydedilir).

var mg: MapGen
var rng: RandomNumberGenerator
var S := 8192.0
var towns: Array = []      # [merkez, yarıçap] — orman/tarla bunlardan uzak durur
var woods: Array = []      # [merkez, rx, rz, açı]
var riv: PackedVector3Array

func F(x: float, z: float) -> Vector3:
	return Vector3(x * S, 0, z * S)

func FA(a: Array) -> Array:
	var out: Array = []
	for q in a:
		out.append(F(q[0], q[1]))
	return out

func build(m: MapGen) -> void:
	mg = m
	rng = m.rng
	S = G.MAP
	# karargâhlar: doğu (ABD) ve batı (RUS), cepheye ~2,7 km
	G.hq_pos = [F(0.90, 0.70), F(0.10, 0.30)]
	mg.reserve(G.hq_pos[0], 60)
	mg.reserve(G.hq_pos[1], 60)
	G.prof("rivers")
	_rivers()
	G.prof("roads")
	_roads()
	mg.auto_bridges()
	mg.p_reeds_along(riv, 14.0)
	G.prof("rail")
	_rail()
	G.prof("sites")
	_sites()
	_central_town()
	G.prof("town")
	_grid_town(F(0.22, 0.46), 4, 5, 46.0, "west")
	_grid_town(F(0.80, 0.60), 4, 5, 46.0, "east")
	G.prof("towns")
	_villages()
	G.prof("villages")
	_farms(44)
	G.prof("farms")
	_forests()
	G.prof("forests")
	_fields()
	G.prof("fields")
	_scatter()
	G.prof("scatter")
	_details()
	G.prof("details")
	G.grass_stream = true

# ------------------------------------------------------------ su
func _rivers() -> void:
	riv = mg.river(FA([[0.47, -0.01], [0.50, 0.08], [0.46, 0.17], [0.44, 0.24], [0.49, 0.31], [0.53, 0.38], [0.555, 0.45],
		[0.548, 0.52], [0.50, 0.60], [0.46, 0.68], [0.47, 0.76], [0.505, 0.84], [0.49, 0.92], [0.47, 1.01]]), 26.0, 2.3)
	var trib := mg.river(FA([[1.01, 0.27], [0.92, 0.29], [0.84, 0.25], [0.76, 0.28], [0.68, 0.33], [0.60, 0.36], [0.534, 0.385]]), 12.0, 1.7)
	mg.p_reeds_along(trib, 7.0)

# ------------------------------------------------------------ yollar
func _roads() -> void:
	# otoyol (doğu-batı): batı kasabası → istasyon → merkez kasaba (köprü) → doğu kasabası
	mg.road(FA([[-0.01, 0.50], [0.10, 0.49], [0.22, 0.47], [0.30, 0.485], [0.37, 0.50], [0.45, 0.49], [0.50, 0.485], [0.56, 0.485],
		[0.62, 0.49], [0.70, 0.53], [0.80, 0.585], [0.90, 0.60], [1.01, 0.62]]), 9.0)
	# yaka yolları (kuzey-güney)
	mg.road(FA([[0.30, -0.01], [0.33, 0.12], [0.36, 0.22], [0.38, 0.35], [0.40, 0.495], [0.39, 0.62], [0.36, 0.75], [0.34, 0.88], [0.33, 1.01]]), 6.5)
	mg.road(FA([[0.66, -0.01], [0.64, 0.12], [0.66, 0.24], [0.655, 0.34], [0.63, 0.43], [0.62, 0.49], [0.66, 0.60], [0.70, 0.72], [0.68, 0.86], [0.70, 1.01]]), 6.5)
	# geçitler: kuzey uç, kuzey köprübaşı, güney köprübaşı, güney uç
	mg.road(FA([[0.33, 0.05], [0.42, 0.045], [0.50, 0.05], [0.58, 0.04], [0.65, 0.05]]), 5.0)
	mg.road(FA([[0.36, 0.22], [0.41, 0.19], [0.46, 0.17], [0.52, 0.15], [0.58, 0.14], [0.64, 0.13]]), 6.0)
	mg.road(FA([[0.36, 0.75], [0.42, 0.785], [0.49, 0.80], [0.56, 0.815], [0.62, 0.83], [0.68, 0.85]]), 6.0)
	mg.road(FA([[0.34, 0.94], [0.42, 0.95], [0.49, 0.95], [0.57, 0.955], [0.69, 0.96]]), 5.0)
	# köy yolları
	mg.road(FA([[0.10, 0.30], [0.14, 0.24], [0.14, 0.16], [0.20, 0.12], [0.33, 0.12]]), 4.5)
	mg.road(FA([[0.10, 0.30], [0.20, 0.30], [0.30, 0.30], [0.38, 0.33]]), 4.5)
	mg.road(FA([[0.22, 0.47], [0.18, 0.58], [0.12, 0.70], [0.14, 0.80], [0.25, 0.86], [0.34, 0.88]]), 4.5)
	mg.road(FA([[0.39, 0.62], [0.33, 0.62], [0.28, 0.62], [0.22, 0.60]]), 4.5)
	mg.road(FA([[0.64, 0.12], [0.72, 0.13], [0.78, 0.14], [0.86, 0.18], [0.90, 0.28], [0.90, 0.40], [0.86, 0.50], [0.80, 0.585]]), 4.5)
	mg.road(FA([[0.70, 0.72], [0.74, 0.72], [0.82, 0.70], [0.90, 0.70]]), 5.0)
	mg.road(FA([[0.68, 0.86], [0.76, 0.87], [0.86, 0.86], [0.92, 0.80], [0.90, 0.70]]), 4.5)
	# tarla yolları (toprak, dar)
	for q in [[[0.20, 0.30], [0.20, 0.40], [0.22, 0.47]], [[0.30, 0.30], [0.28, 0.20], [0.24, 0.12]], [[0.16, 0.58], [0.06, 0.58], [0.02, 0.52]],
			[[0.39, 0.62], [0.42, 0.70], [0.42, 0.785]], [[0.74, 0.72], [0.76, 0.80], [0.76, 0.87]], [[0.78, 0.14], [0.80, 0.04]],
			[[0.86, 0.50], [0.94, 0.50], [0.99, 0.44]], [[0.25, 0.86], [0.20, 0.96]], [[0.70, 0.53], [0.74, 0.44], [0.78, 0.40]]]:
		mg.road(FA(q), 3.4)
	mg._poles_along(mg.roads[0], 34.0, 7.0)

# ------------------------------------------------------------ demiryolu (batı yaka) + istasyon
func _rail() -> void:
	var rail := PackedVector3Array()
	for k in 33:
		var t := float(k) / 32.0
		rail.append(Vector3(S * (0.375 + sin(t * 4.0) * 0.008), 0, -10.0 + t * (S + 20.0)))
	for q in rail:
		mg.reserve(q, 4.0)
	# ~500 m'lik parçalar (görüş kesimi)
	for i in range(0, rail.size() - 1, 2):
		mg.P.railway(rail.slice(i, mini(i + 3, rail.size())))
	var stp := Vector3(S * 0.375 + 16.0, 0, S * 0.52)
	if mg.free_at(stp, 7.0, 2.0):
		mg.bld(stp, "istasyon", mg._face_rot(stp, Vector3(-1, 0, 0)), Arch.pick_size("istasyon", rng))
		mg.reserve(stp, 14.0)
	towns.append([F(0.375, 0.52), 160.0])
	mg._town(F(0.36, 0.53), 110.0, 16, false)

# ------------------------------------------------------------ ileri üsler + hedef bölgeleri
func _sites() -> void:
	G.fob_sites = FA([[0.18, 0.40], [0.29, 0.52], [0.33, 0.20], [0.35, 0.66], [0.30, 0.80], [0.20, 0.12], [0.42, 0.40], [0.42, 0.60],
		[0.82, 0.64], [0.70, 0.50], [0.69, 0.20], [0.64, 0.66], [0.72, 0.84], [0.84, 0.32], [0.60, 0.40], [0.60, 0.70]])
	for s in G.fob_sites:
		mg.reserve(s, 14.0)
	# hedefler: iki yan kasaba, istasyon, sanayi, merkez kasabanın iki yakası, kuzey ve güney köprüleri
	# (köprü noktaları auto_bridges sonrası gerçek köprüye çekilir)
	G.zone_sites = [
		{"p": F(0.22, 0.46), "name": "A"}, {"p": _bridge_near(F(0.46, 0.17)), "name": "B"}, {"p": F(0.375, 0.52), "name": "C"},
		{"p": F(0.525, 0.47), "name": "D"}, {"p": F(0.59, 0.495), "name": "E"}, {"p": F(0.655, 0.56), "name": "F"},
		{"p": _bridge_near(F(0.49, 0.80)), "name": "G"}, {"p": F(0.80, 0.60), "name": "H"}]

func _bridge_near(p: Vector3) -> Vector3:
	var best := p
	var bd := 1e9
	for b in mg.bridges:
		var d: float = (b as Vector3).distance_to(p)
		if d < bd:
			bd = d
			best = b
	return best

# ------------------------------------------------------------ merkez kasaba (iki yaka)
func _central_town() -> void:
	# iki yaka: ızgaralar nehre bitişik (kıyı şeridi + sahil yolu payı ~20 m)
	var cz := S * 0.475
	var rx := _river_x_at(cz)
	var nx := 6
	var nz := 9
	var step := 44.0
	var half := nx * step * 0.5
	towns.append([Vector3(rx, 0, cz), half * 2.0 + 260.0])
	_grid_town(Vector3(rx - 13.0 - 22.0 - half, 0, cz), nx, nz, step, "cw", Vector3(rx - 13.0 - 22.0 - half, 0, cz))
	_grid_town(Vector3(rx + 13.0 + 22.0 + half, 0, cz + 10.0), nx, nz, step, "ce", Vector3(rx + 13.0 + 22.0 + half, 0, cz + 10.0))
	# sanayi bölgesi (güneydoğu): depo, fabrika, silo; bir kısmı duvarlı avlu
	var ind := mg.arch_pool(["sanayi"])
	for k in 22:
		var ip := mg.rand_free(8.0, 40, Rect2(S * 0.625, S * 0.52, S * 0.06, S * 0.06), 3.0)
		if ip.x < 0:
			continue
		var rot := mg._face_rot(ip)
		var r := mg.arch_near(ip, "ind", ind, 6.0, 3.0)
		if r > 0.0 and r < 11.0 and rng.randf() < 0.35 and mg.road_dist(ip) > r + 6.0:
			mg.compound(ip, r * 2.0 + 6.0, r * 2.0 + 5.0, 5, [2, 1, 0, 3][rot], Color(0.7, 0.68, 0.64))
			mg.reserve(ip, r + 4.0)
	towns.append([F(0.655, 0.55), 280.0])

# ana nehrin verilen z'deki x'i (en yakın nokta)
func _river_x_at(z: float) -> float:
	var best := S * 0.55
	var bd := 1e9
	for q in riv:
		var d := absf(q.z - z)
		if d < bd:
			bd = d
			best = q.x
	return best

# sokak ızgaralı kasaba: c merkez, nx × nz blok, step blok aralığı. Sokaklar nehre girmez (yalnız
# otoyol ve geçit yolları köprüden geçer). Meydan merkez blokta; merkezde simge yapı + sıra ev cephesi,
# kenarda bahçeli evler.
func _grid_town(c: Vector3, nx: int, nz: int, step: float, key: String, plaza := Vector3.INF) -> void:
	var x0 := c.x - nx * step * 0.5
	var z0 := c.z - nz * step * 0.5
	if not key in ["cw", "ce"]:
		towns.append([c, maxf(nx, nz) * step * 0.75 + 60.0])
	# sokaklar: suya değmeyen parçalar
	for i in nx + 1:
		_street(Vector3(x0 + i * step, 0, z0 - 8.0), Vector3(x0 + i * step, 0, z0 + nz * step + 8.0))
	for k in nz + 1:
		_street(Vector3(x0 - 8.0, 0, z0 + k * step), Vector3(x0 + nx * step + 8.0, 0, z0 + k * step))
	# meydan
	var pc := plaza if plaza != Vector3.INF else c
	pc = Vector3(x0 + (floor((pc.x - x0) / step) + 0.5) * step, 0, z0 + (floor((pc.z - z0) / step) + 0.5) * step)
	if mg.river_clear(pc, 12.0) and mg.road_dist(pc) > 8.0:
		mg.P.plaza(pc)
		mg.reserve(pc, 11.0)
		for k in 8:
			var a := float(k) / 8.0 * TAU
			var lp := pc + Vector3(cos(a), 0, sin(a)) * 12.0
			if mg.free_at(lp, 0.5, 0.0):
				mg.P.pole(lp, true)
	var cpool := mg.arch_pool(["sehir", "kasaba"], 15.0)
	var opool := mg.arch_pool(["kasaba", "koy"], 14.0)
	opool.append_array(["atolye", "garaj_sirasi", "marangoz", "oto_tamir", "trafo", "bag_evi"])
	for bx in nx:
		for bz in nz:
			var bc := Vector3(x0 + (bx + 0.5) * step, 0, z0 + (bz + 0.5) * step)
			if not mg.river_clear(bc, step * 0.3) or (G.terrain.has_water and G.terrain.ground_h(bc) < -0.2):
				continue
			var centre := absf(bx - (nx - 1) * 0.5) < 1.6 and absf(bz - (nz - 1) * 0.5) < 1.6
			# sokak cephesi: bitişik nizam (kuzey kenar)
			if centre or rng.randf() < 0.45:
				var ze := bc.z - step * 0.5 + 2.8
				var x := bc.x - step * 0.5 + 3.5
				var xe := bc.x + step * 0.5 - 3.5
				var tries := 0
				while x < xe - 4.0 and tries < 8:
					tries += 1
					var id := mg.deck("front", MapGen.FRONT)
					var sz := Arch.pick_size(id, rng)
					if x + sz.x > xe:
						mg.undeck("front", id)
						break
					var hp := Vector3(x + sz.x * 0.5, 0, ze + sz.y * 0.5)
					if mg.river_clear(hp, 6.0) and mg.place_arch_row(hp, id, sz, Vector3(0, 0, -1)):
						x += sz.x + 0.3
					else:
						mg.undeck("front", id)
						x += 2.5
			var n := rng.randi_range(2, 4) if centre else rng.randi_range(2, 3)
			if centre and rng.randf() < 0.55:
				if mg.arch_near(bc + Vector3(0, 0, step * 0.15), "landmark", MapGen.LANDMARK, 5.0, 1.5) > 0.0:
					n -= 1
			for k in n:
				var p := mg.rand_free(3.5, 30, Rect2(bc.x - step * 0.5 + 3.5, bc.z - step * 0.5 + 3.5, step - 7, step - 7), 1.5)
				if p.x < 0:
					continue
				var r := mg.arch_near(p, key + ("c" if centre else "o"), cpool if centre else opool, 5.0, 1.5)
				if r > 0.0 and not centre and rng.randf() < 0.25:
					var fz := p.z + r + 1.2
					if mg.free_at(Vector3(p.x, 0, fz), 0.5, 1.0):
						mg.P.picket(Vector3(p.x - r, 0, fz), Vector3(p.x + r, 0, fz))
			for k in 2:
				var q := mg.rand_free(0.8, 8, Rect2(bc.x - step * 0.5 + 3, bc.z - step * 0.5 + 3, step - 6, step - 6), 1.5)
				if q.x > 0:
					if rng.randf() < 0.45:
						mg.p_tree(q)
					else:
						mg.p_bush(q, rng.randf() < 0.3)
	# sokak lambası, park etmiş araç
	for i in nx + 1:
		for k in nz * 2:
			var lp := Vector3(x0 + i * step + 3.6, 0, z0 + (k + 0.5) * step * 0.5)
			if mg.free_at(lp, 0.5, 0.0) and mg.river_clear(lp, 3.0):
				mg.P.pole(lp, true)
	for i in nx * nz / 2:
		var p := mg.rand_free(2.2, 20, Rect2(x0, z0, nx * step, nz * step), 0.0)
		if p.x > 0 and mg.road_dist(p) < 7.0:
			mg.p_car(p, rng.randf() * TAU)

func _street(a: Vector3, b: Vector3) -> void:
	# suya değmeyen ardışık parçalar (≥ 24 m)
	var L := a.distance_to(b)
	var n := maxi(2, int(L / 6.0))
	var run: Array = []
	for k in n + 1:
		var p := a.lerp(b, float(k) / n)
		var dry := mg.river_clear(p, 7.0)
		if dry:
			run.append(p)
		if (not dry or k == n) and run.size() >= 2:
			if (run[0] as Vector3).distance_to(run[run.size() - 1]) >= 24.0:
				mg.road([run[0], run[run.size() - 1]], 5.0)
			run = []
		elif not dry:
			run = []

# ------------------------------------------------------------ köyler ve çiftlikler
func _villages() -> void:
	var V := [[0.14, 0.16, 26], [0.30, 0.30, 30], [0.40, 0.19, 34], [0.12, 0.70, 28], [0.28, 0.62, 30], [0.43, 0.785, 36], [0.25, 0.86, 26],
		[0.565, 0.14, 34], [0.78, 0.14, 28], [0.90, 0.40, 28], [0.74, 0.72, 30], [0.565, 0.82, 36], [0.86, 0.86, 26]]
	for v in V:
		var c := F(v[0], v[1])
		var R := 70.0 + float(v[2]) * 1.4
		towns.append([c, R + 40.0])
		_road_village(c, R, int(v[2]))
		# köy kenarı: bahçe ağaçları
		for k in 14:
			var q := c + Vector3(rng.randf_range(-R, R), 0, rng.randf_range(-R, R))
			if mg.free_at(q, 0.8, 2.0):
				mg.p_tree(q, rng.randf_range(0.9, 1.4))

# yol köyü: evler köyden geçen yolların iki yanına, yola dönük dizilir (ikinci sıra ve ahırlar arkada);
# kalan evler köy içine serpilir. Gerçek köyler yol boyunca uzanır, dağınık değil.
func _road_village(c: Vector3, R: float, n: int) -> void:
	var pool := mg.village_pool()
	var placed := 0
	var rp: Array = []
	for rd in mg.roads:
		var pts: PackedVector3Array = rd
		var acc := 0.0
		for i in pts.size() - 1:
			acc += pts[i].distance_to(pts[i + 1])
			if acc < rng.randf_range(15.0, 22.0):
				continue
			acc = 0.0
			if Vector2(pts[i].x - c.x, pts[i].z - c.z).length() < R:
				rp.append([pts[i], (pts[i + 1] - pts[i]).normalized()])
	# tohumlu karıştırma (aynı tohum aynı harita)
	for i in range(rp.size() - 1, 0, -1):
		var j := rng.randi() % (i + 1)
		var t = rp[i]
		rp[i] = rp[j]
		rp[j] = t
	for e in rp:
		if placed >= n:
			break
		var p: Vector3 = e[0]
		var d: Vector3 = e[1]
		var side := Vector3(-d.z, 0, d.x) * (1.0 if rng.randf() < 0.5 else -1.0)
		var hp := p + side * rng.randf_range(10.0, 13.0)
		if mg.place_arch(hp, mg.deck("village", pool), 2.0, -side) > 0.0:
			placed += 1
			# arka sıra: ahır / ambar / ikinci ev
			if rng.randf() < 0.35:
				var bp := hp + side * rng.randf_range(16.0, 22.0)
				if mg.arch_near(bp, "farm", mg.farm_pool(), 5.0, 2.0) > 0.0:
					placed += 1
	if placed < n:
		mg._town(c, R * 0.7, n - placed, false)

func _farms(n: int) -> void:
	for i in n:
		var c := mg.rand_free(24.0, 40, Rect2(S * 0.04, S * 0.04, S * 0.92, S * 0.92), 8.0)
		if c.x < 0 or _in_town(c, 60.0):
			continue
		mg._farm(c, rng.randi_range(2, 4))
		towns.append([c, 55.0])
		# çiftliğe toprak yol (en yakın yola)
		var rp := mg.nearest_road(c, 260.0)
		if rp != Vector3.INF and rp.distance_to(c) > 20.0:
			mg.road([c + (rp - c).normalized() * 14.0, rp], 3.0)

func _in_town(p: Vector3, m := 0.0) -> bool:
	for t in towns:
		if Vector2(p.x - t[0].x, p.z - t[0].z).length() < float(t[1]) + m:
			return true
	return false

func _in_wood(p: Vector3, m := 0.0) -> bool:
	for w in woods:
		var d: Vector3 = p - w[0]
		var a: float = w[3]
		var lx := d.x * cos(a) + d.z * sin(a)
		var lz := -d.x * sin(a) + d.z * cos(a)
		var rx: float = w[1] + m
		var rz: float = w[2] + m
		if (lx * lx) / (rx * rx) + (lz * lz) / (rz * rz) < 1.0:
			return true
	return false

# ------------------------------------------------------------ ormanlar
func _forests() -> void:
	# büyük ormanlar: [x, z, rx, rz, açı, çam oranı]
	for f in [[0.16, 0.06, 820, 360, 0.1, 0.7], [0.30, 0.56, 230, 470, 0.15, 0.3], [0.75, 0.40, 330, 230, -0.3, 0.35], [0.92, 0.92, 430, 360, 0.4, 0.5],
			[0.09, 0.91, 470, 330, -0.2, 0.55], [0.89, 0.07, 400, 280, 0.2, 0.6], [0.425, 0.69, 170, 330, 0.25, 0.2], [0.585, 0.27, 170, 290, -0.15, 0.25],
			[0.20, 0.74, 260, 180, 0.6, 0.4], [0.70, 0.94, 300, 160, 0.0, 0.45]]:
		_forest(F(f[0], f[1]), float(f[2]), float(f[3]), float(f[4]), float(f[5]), 9.5)
	# koruluklar
	for i in 70:
		var c := mg.rand_free(30.0, 30, Rect2(S * 0.03, S * 0.03, S * 0.94, S * 0.94), 10.0)
		if c.x < 0 or _in_town(c, 80.0) or _in_wood(c, 60.0):
			continue
		var r := rng.randf_range(40.0, 130.0)
		_forest(c, r * rng.randf_range(0.8, 1.3), r * rng.randf_range(0.6, 1.0), rng.randf() * PI, rng.randf(), 8.5)
	# kıyı ormanı: ana nehrin bazı bölümlerinde iki yakada
	var i := 0
	while i < riv.size() - 30:
		if rng.randf() < 0.4:
			var a := riv[i]
			var b := riv[i + 30]
			var mid := (a + b) * 0.5
			if not _in_town(mid, 120.0):
				var d := (b - a).normalized()
				var side := Vector3(-d.z, 0, d.x)
				for sg in [-1.0, 1.0]:
					var c: Vector3 = mid + side * sg * rng.randf_range(45.0, 70.0)
					_forest(c, a.distance_to(b) * 0.5, rng.randf_range(22.0, 40.0), atan2(d.z, d.x), 0.1, 7.5)
		i += 30

# eliptik orman, kenarı gürültülü; iç ağaç aralığı step (m), kenarda çalılık
func _forest(c: Vector3, rx: float, rz: float, ang: float, pine_k: float, step: float) -> void:
	woods.append([c, rx, rz, ang])
	var ca := cos(ang)
	var sa := sin(ang)
	var R := maxf(rx, rz)
	var ph := rng.randf() * TAU
	G.terrain.forest_floor(c, rx, rz, ang, ph)
	var x := -R
	while x <= R:
		var z := -R
		while z <= R:
			var lx := x + rng.randf_range(-step * 0.35, step * 0.35)
			var lz := z + rng.randf_range(-step * 0.35, step * 0.35)
			var e := (lx * lx) / (rx * rx) + (lz * lz) / (rz * rz)
			var edge := 1.0 + 0.16 * sin(atan2(lz, lx) * 5.0 + ph) + 0.08 * sin(atan2(lz, lx) * 11.0 + ph * 2.0)
			if e < edge:
				var p := c + Vector3(lx * ca - lz * sa, 0, lx * sa + lz * ca)
				if mg.free_at(p, 0.8, 2.5) and not _in_town(p, 10.0):
					# iç kısım: kapalı tepe örtüsü için büyük ağaç; kenar: çalılık ve genç ağaç
					var big := 1.0 if e > edge * 0.7 else rng.randf_range(1.3, 1.9)
					if e > edge * 0.82 and rng.randf() < 0.45:
						mg.p_bush(p, rng.randf() < 0.4)
					elif rng.randf() < pine_k:
						mg.p_pine(p, big)
					else:
						mg.p_tree(p, big)
					# (145) alt bitki: kenar kuşağında ağaç aralarında sık çalı (saçak), içeride seyrek çalı ve ara sıra devrik gövde
					var off := Vector3(rng.randf_range(-0.5, 0.5), 0, rng.randf_range(-0.5, 0.5)) * step
					var q := p + off
					if e > edge * 0.7:
						if rng.randf() < 0.6 and mg.free_at(q, 0.6, 2.0):
							mg.p_bush(q, rng.randf() < 0.4, rng.randf_range(1.3, 1.8))
					elif rng.randf() < 0.12 and mg.free_at(q, 0.6, 2.0):
						mg.p_bush(q, false)
					elif rng.randf() < 0.008 and mg.free_at(q, 1.2, 2.5):
						mg.p_asset("dead_tree_trunk_02" if rng.randf() < 0.6 else "tree_stump_01", q, rng.randf() * TAU, rng.randf_range(0.85, 1.2))
			z += step
		x += step

# ------------------------------------------------------------ tarlalar
# Gerçek tarım arazisi gibi: harita ~1,4 km'lik bölgelere ayrılır; her bölgede (en yakın yolun yönünde)
# döndürülmüş bir kafes, hücrede 1-3 şerit tarla (farklı ekin), aralarında 5-9 m sınır. Kafes içinde
# tarlalar örtüşmez; kasaba, orman, nehir ve bölge dışına taşan tarla atlanır. Ekin: 1 buğday, 2 yeşil
# ekin, 3 sürülmüş toprak, 4 çayır. Kenarlarda ağaç sırası/çit, buğdayda saman balyası.
func _fields() -> void:
	var R := S / 6.0
	for rz in 6:
		for rx in 6:
			var rc := Vector3((rx + 0.5) * R, 0, (rz + 0.5) * R)
			var rd := mg.nearest_road_dir(rc, 600.0)
			var ang := atan2(rd.z, rd.x) if rd != Vector3.ZERO else rng.randf() * PI
			ang += rng.randf_range(-0.08, 0.08)
			var ax := Vector3(cos(ang), 0, sin(ang))
			var bx := Vector3(-ax.z, 0, ax.x)
			var L1 := rng.randf_range(250.0, 360.0)
			var L2 := rng.randf_range(200.0, 300.0)
			var m := int(R / minf(L1, L2)) + 2
			var rect := Rect2(rx * R + 12.0, rz * R + 12.0, R - 24.0, R - 24.0)
			for i in range(-m, m + 1):
				for j in range(-m, m + 1):
					var c := rc + ax * i * L1 + bx * j * L2
					var corners := [c + ax * L1 * 0.5 + bx * L2 * 0.5, c - ax * L1 * 0.5 + bx * L2 * 0.5, c + ax * L1 * 0.5 - bx * L2 * 0.5, c - ax * L1 * 0.5 - bx * L2 * 0.5]
					var ok := rect.has_point(Vector2(c.x, c.z))
					for q in corners:
						var qv: Vector3 = q
						if not rect.has_point(Vector2(qv.x, qv.z)) or _in_town(qv, 10.0) or _in_wood(qv, 8.0) or not mg.river_clear(qv, 30.0):
							ok = false
							break
					if not ok or _in_town(c, 30.0) or _in_wood(c, 20.0) or not mg.river_clear(c, 40.0) or rng.randf() < 0.06:
						continue
					_field_cell(c, ax, bx, L1, L2)

func _field_cell(c: Vector3, ax: Vector3, bx: Vector3, L1: float, L2: float) -> void:
	var gap := rng.randf_range(5.0, 9.0)
	var n: int = [1, 2, 2, 3][rng.randi() % 4]
	var sw := (L2 - gap * n) / n
	var ang := atan2(ax.z, ax.x)
	for k in n:
		var fc := c + bx * (-L2 * 0.5 + gap * 0.5 + sw * 0.5 + k * (sw + gap))
		var crop: int = [1, 1, 1, 2, 2, 3, 3, 4][rng.randi() % 8]
		G.terrain.field_rect(fc, Vector2(L1 - gap, sw), ang, crop, rng.randf())
		if crop == 1 and rng.randf() < 0.5:
			for h in rng.randi_range(4, 12):
				var hp := fc + ax * rng.randf_range(-L1 * 0.4, L1 * 0.4) + bx * rng.randf_range(-sw * 0.4, sw * 0.4)
				if mg.free_at(hp, 1.0, 3.0):
					mg.p_hay(hp)
	# hücre kenarları: ağaç sırası (rüzgâr kıran) ya da çit
	if rng.randf() < 0.45:
		var sg := 1.0 if rng.randf() < 0.5 else -1.0
		_tree_line(c - ax * L1 * 0.5 + bx * L2 * 0.5 * sg, c + ax * L1 * 0.5 + bx * L2 * 0.5 * sg, rng.randf_range(7.0, 11.0))
	if rng.randf() < 0.25:
		var sg2 := 1.0 if rng.randf() < 0.5 else -1.0
		_tree_line(c - bx * L2 * 0.5 + ax * L1 * 0.5 * sg2, c + bx * L2 * 0.5 + ax * L1 * 0.5 * sg2, rng.randf_range(8.0, 12.0))
	elif rng.randf() < 0.15:
		var p0 := c - ax * L1 * 0.5 - bx * L2 * 0.5
		mg.fence(p0, p0 + ax * minf(L1, 120.0))

func _tree_line(a: Vector3, b: Vector3, step: float) -> void:
	var L := a.distance_to(b)
	var n := int(L / step)
	for k in n + 1:
		var p := a.lerp(b, float(k) / maxf(n, 1)) + Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2))
		if _in_town(p, 0.0) or not mg.free_at(p, 0.8, 2.5):
			continue
		if rng.randf() < 0.25:
			mg.p_bush(p, true)
		else:
			mg.p_tree(p)

# ------------------------------------------------------------ dağınık bitki, kaya
func _scatter() -> void:
	for i in 9000:
		var p := Vector3(rng.randf_range(20, S - 20), 0, rng.randf_range(20, S - 20))
		if _in_wood(p) or not mg.free_at(p, 0.8, 2.0):
			continue
		var r := rng.randf()
		if r < 0.3:
			mg.p_tree(p)
		elif r < 0.85:
			mg.p_bush(p, rng.randf() < 0.25)
		else:
			mg.p_rock(p, rng.randf_range(0.6, 1.5))
	for i in 520:
		mg.patch(Vector3(rng.randf_range(0, S), 0, rng.randf_range(0, S)), rng.randf_range(8, 26), rng.randf_range(0.4, 1.0))

# ------------------------------------------------------------ ayrıntı: yol kenarı araçları, cephe hattında savaş izi
func _details() -> void:
	for i in 160:
		var p := mg.rand_free(2.2, 30, Rect2(40, 40, S - 80, S - 80), 0.0)
		if p.x > 0 and mg.road_dist(p) < 9.0:
			mg.p_car(p, rng.randf() * TAU)
	# nehir boyunca ön hat: krater ve yanık lekeleri (yerleşim dışında)
	for i in 140:
		var k := rng.randi_range(0, riv.size() - 1)
		var q: Vector3 = riv[k] + Vector3(rng.randf_range(-260, 260), 0, rng.randf_range(-260, 260))
		if not mg.river_clear(q, 8.0) or _in_town(q, 20.0) or q.x < 10 or q.z < 10 or q.x > S - 10 or q.z > S - 10:
			continue
		var cr := rng.randf_range(2.0, 5.0)
		mg.crater(q, cr)
