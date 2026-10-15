class_name MapGenLarge extends RefCounted
# Geniş Cephe (1024 m) / Kuzey Cephesi (2048 m) / Hava İndirme Bölgesi (4096 m): ölçeklenen büyük harita.
# İki karargâh arası ~1,2 km; büyük nehir + kol, otoyol ve köy yolları, altı köy,
# ormanlık alanlar, tarlalar, ileri üs noktaları. MapGen'in kayıtlı işlemlerini kullanır
# (editörde açılır/kaydedilir).

var mg: MapGen
var rng: RandomNumberGenerator

func build(m: MapGen) -> void:
	mg = m
	rng = m.rng
	var S := G.MAP
	var A := (S / 1024.0) * (S / 1024.0)     # alan çarpanı (2 km: 4, 4 km: 16)
	G.hq_pos = [Vector3(S - 80, 0, S - 80), Vector3(80, 0, 80)]
	mg.reserve(G.hq_pos[0], 30)
	mg.reserve(G.hq_pos[1], 30)
	# ana nehir (haritayı çaprazlamasına böler) + kuzeyden katılan kol
	var riv := mg.river([Vector3(-12, 0, S * 0.78), Vector3(S * 0.18, 0, S * 0.7), Vector3(S * 0.33, 0, S * 0.6), Vector3(S * 0.47, 0, S * 0.5),
		Vector3(S * 0.6, 0, S * 0.42), Vector3(S * 0.76, 0, S * 0.3), Vector3(S * 0.9, 0, S * 0.24), Vector3(S + 12, 0, S * 0.18)], 18.0, 2.0)
	var trib := mg.river([Vector3(S * 0.62, 0, -12), Vector3(S * 0.6, 0, S * 0.14), Vector3(S * 0.66, 0, S * 0.28), Vector3(S * 0.68, 0, S * 0.36)], 10.0, 1.6)
	# otoyol: karargâhtan karargâha, iki köprü
	mg.road([Vector3(S - 8, 0, S - 8), Vector3(S - 80, 0, S - 80), Vector3(S * 0.8, 0, S * 0.74), Vector3(S * 0.66, 0, S * 0.62), Vector3(S * 0.52, 0, S * 0.56),
		Vector3(S * 0.42, 0, S * 0.42), Vector3(S * 0.3, 0, S * 0.3), Vector3(S * 0.18, 0, S * 0.16), Vector3(80, 0, 80), Vector3(8, 0, 8)], 7.0)
	# köy yolları
	var V := [Vector3(S * 0.78, 0, S * 0.55), Vector3(S * 0.58, 0, S * 0.8), Vector3(S * 0.3, 0, S * 0.82), Vector3(S * 0.22, 0, S * 0.45),
		Vector3(S * 0.45, 0, S * 0.22), Vector3(S * 0.82, 0, S * 0.12)]
	mg.road([Vector3(S * 0.66, 0, S * 0.62), V[0], Vector3(S * 0.86, 0, S * 0.4), Vector3(S - 8, 0, S * 0.36)], 5.0)
	mg.road([Vector3(S * 0.52, 0, S * 0.56), V[1], Vector3(S * 0.5, 0, S - 8)], 5.0)
	mg.road([Vector3(S * 0.52, 0, S * 0.56), Vector3(S * 0.4, 0, S * 0.7), V[2], Vector3(S * 0.12, 0, S - 8)], 4.5)
	mg.road([Vector3(S * 0.3, 0, S * 0.3), V[3], Vector3(8, 0, S * 0.5)], 4.5)
	mg.road([Vector3(S * 0.42, 0, S * 0.42), V[4], Vector3(S * 0.52, 0, 8)], 4.5)
	mg.road([Vector3(S * 0.66, 0, S * 0.62), Vector3(S * 0.74, 0, S * 0.3), V[5], Vector3(S - 8, 0, S * 0.06)], 4.5)
	mg.auto_bridges()
	mg.p_reeds_along(riv, 7.5)
	mg.p_reeds_along(trib, 4.5)
	# ileri üs noktaları: cephe hattı boyunca simetrik
	G.fob_sites = [Vector3(S * 0.85, 0, S * 0.68), Vector3(S * 0.7, 0, S * 0.86), Vector3(S * 0.72, 0, S * 0.5), Vector3(S * 0.55, 0, S * 0.68),
		Vector3(S * 0.15, 0, S * 0.32), Vector3(S * 0.3, 0, S * 0.14), Vector3(S * 0.28, 0, S * 0.5), Vector3(S * 0.45, 0, S * 0.32),
		Vector3(S * 0.4, 0, S * 0.86), Vector3(S * 0.86, 0, S * 0.22), Vector3(S * 0.14, 0, S * 0.62), Vector3(S * 0.6, 0, S * 0.12)]
	for s in G.fob_sites:
		mg.reserve(s, 10.0)
	# köyler
	for v in V:
		mg._town(v, 34.0 * sqrt(sqrt(A)), int(rng.randi_range(12, 20) * sqrt(A)), false)
	mg._town(Vector3(S * 0.5, 0, S * 0.5) + Vector3(18, 0, 26), 28.0, 10, false)
	# büyük haritada ek mezralar
	for i in int((A - 1.0) * 5.0):
		var hc := mg.rand_free(20.0, 40, Rect2(80, 80, S - 160, S - 160), 6.0)
		if hc.x > 0:
			mg._town(hc, 26.0, rng.randi_range(5, 10), false)
	# tarlalar: dikdörtgen toprak/ekin yamaları, saman balyaları, tarla kenarı çit
	for i in int(40 * A):
		var c := Vector3(rng.randf_range(40, S - 40), 0, rng.randf_range(40, S - 40))
		if not mg.free_at(c, 14.0, 6.0):
			continue
		var w := rng.randf_range(24, 46)
		var d := rng.randf_range(18, 34)
		var a := rng.randf() * PI
		var ax := Vector3(cos(a), 0, sin(a))
		var bx := Vector3(-ax.z, 0, ax.x)
		for k in int(w / 6.0):
			mg.patch(c + ax * (-w * 0.5 + k * 6.0 + 3.0), d * 0.45, rng.randf_range(0.55, 0.85))
		for k in rng.randi_range(2, 7):
			var hp := c + ax * rng.randf_range(-w * 0.4, w * 0.4) + bx * rng.randf_range(-d * 0.4, d * 0.4)
			if mg.free_at(hp, 1.0, 2.0):
				mg.p_hay(hp)
		if rng.randf() < 0.45:
			var p0 := c - ax * w * 0.5 - bx * d * 0.5
			mg.fence(p0, p0 + ax * w)
	# ormanlar (yapraklı + çam karışık) ve dağınık ağaçlar
	for g in int(26 * A):
		var c2 := mg.rand_free(8.0, 60, Rect2(20, 20, S - 40, S - 40), 4.0)
		if c2.x < 0:
			continue
		var R := rng.randf_range(18, 42)
		var pine_k := rng.randf()
		for i in int(R * rng.randf_range(1.0, 1.7)):
			var p := c2 + Vector3(rng.randf_range(-R, R), 0, rng.randf_range(-R, R))
			if Vector2(p.x - c2.x, p.z - c2.z).length() > R or not mg.free_at(p, 0.8, 2.0):
				continue
			if rng.randf() < pine_k * 0.8:
				mg.p_pine(p)
			else:
				mg.p_tree(p)
		for i in int(R * 1.2):
			var p := c2 + Vector3(rng.randf_range(-R * 1.15, R * 1.15), 0, rng.randf_range(-R * 1.15, R * 1.15))
			if mg.free_at(p, 0.6, 1.0):
				mg.p_bush(p, rng.randf() < 0.3)
	for i in int(520 * A):
		var p := mg.rand_free(0.8, 20, Rect2(10, 10, S - 20, S - 20), 2.0)
		if p.x > 0:
			var r := rng.randf()
			if r < 0.35:
				mg.p_tree(p)
			elif r < 0.8:
				mg.p_bush(p)
			else:
				mg.p_rock(p, rng.randf_range(0.6, 1.4))
	# yol kenarı direkleri, park etmiş araçlar, çayır yamaları
	mg._poles_along(mg.roads[0], 22.0, 5.5)
	for i in int(30 * A):
		var p := mg.rand_free(2.2, 30, Rect2(40, 40, S - 80, S - 80), 0.0)
		if p.x > 0 and mg.road_dist(p) < 9.0:
			mg.p_car(p, rng.randf() * TAU)
	for i in int(240 * A):
		mg.patch(Vector3(rng.randf_range(0, S), 0, rng.randf_range(0, S)), rng.randf_range(5, 18), rng.randf_range(0.4, 1.0))
	# ot: 256 m'lik karolar halinde (ekran dışı karolar kırpılır)
	var tiles := int(S / 256.0)
	for tz in tiles:
		for tx in tiles:
			mg.p_grass_field(int(9000 / sqrt(A)), Color(0.42, 0.55, 0.24), Rect2(tx * 256 + 2, tz * 256 + 2, 252, 252), 0.5)
	for k in 10:
		var mp: Vector3 = riv[clampi(int(float(k) / 10.0 * riv.size()), 0, riv.size() - 1)]
		G.fx.ground_mist(mp + Vector3(rng.randf_range(-12, 12), 0, rng.randf_range(-12, 12)), 16.0)
