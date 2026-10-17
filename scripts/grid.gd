class_name Grid extends RefCounted
# Engel yükseklik ızgarası (0.5 m), yol bulma (1 m, üç hareket sınıfı) ve görüş hattı.

# hücre boyutları haritaya göre (main.build_world): ≤1 km 0,5 m ince / 1 m yol bulma;
# 2 km 0,5 m / 2 m; 4-8 km 1 m / 4 m. FPN: bir yol bulma hücresindeki ince hücre sayısı (kenar)
static var CS := 0.5
static var NAV := 1.0
static var FPN := 2
static var N := 512
static var NN := 256
# iri en yüksek engel ızgarası (8 m): uzun görüş hattı yalnız engeli ışından yüksek olabilecek iri
# hücrelerde ince adım atar (gerçek menzilde 2 km'lik ışın 6000 ince adım yerine ~250 iri adım)
const CC := 8.0
static var NCC := 32

static func configure(map_size: float) -> void:
	if map_size <= 1024.0:
		CS = 0.5
		NAV = 1.0
	elif map_size <= 2048.0:
		CS = 0.5
		NAV = 2.0
	else:
		CS = 1.0
		NAV = 4.0
	FPN = int(round(NAV / CS))
	N = int(map_size / CS)
	NN = int(map_size / NAV)
	NCC = int(ceil(map_size / CC))
enum { K_NONE, K_WALL, K_HOUSE, K_WRECK, K_TRAP, K_WIRE, K_TREE, K_BUILDING }
# ham yükseklikler (hs sabit engel, hb bina blokları) bayt olarak 1/10 m biriminde tutulur (en çok 25,5 m):
# 8 km haritada 67 M hücre × 2 dizi = 134 MB (float ile 537 MB). Birleşik h float kalır (görüş hattı).
const HQ := 10.0
static func hq(v: float) -> int:
	return clampi(int(round(v * HQ)), 0, 255)
enum { M_INF, M_LIGHT, M_HEAVY }

var hs := PackedByteArray()
var hb := PackedByteArray()
var h := PackedFloat32Array()
var kind := PackedByteArray()
var trench := PackedByteArray()
var water := PackedByteArray()
var bridge := PackedByteArray()
var door := PackedByteArray()       # kapı boşluğu ince hücreleri: piyade yol bulmasında o yol hücresi kapanmaz
var base_l := PackedByteArray()
var vault := PackedByteArray()      # piyadenin üstünden atlayabildiği alçak engel hücreleri
var base_h := PackedByteArray()
var crat := PackedByteArray()       # (163) krater yol bulma hücreleri: araç yolu pahalı (gevşek toprak, dik duvar)
var nav: Array = []
var bridges: Array = []       # {c, d, L, w}: araçlar köprüde eksene hizalanır
var _dirty := {}
var hm := PackedFloat32Array()      # iri hücrede en yüksek engel (m)
var _hm_dirty := {}                 # yükseklik düşen iri hücreler (yeniden hesap)

func _init() -> void:
	hs.resize(N * N)
	hb.resize(N * N)
	h.resize(N * N)
	kind.resize(N * N)
	trench.resize(N * N)
	water.resize(N * N)
	bridge.resize(N * N)
	door.resize(N * N)
	hm.resize(NCC * NCC)
	base_l.resize(NN * NN)
	vault.resize(NN * NN)
	base_h.resize(NN * NN)
	crat.resize(NN * NN)
	for i in 3:
		var a := AStarGrid2D.new()
		a.region = Rect2i(0, 0, NN, NN)
		a.cell_size = Vector2(1, 1)
		a.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
		a.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		a.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
		a.update()
		nav.append(a)
	# büyük haritada işçi iş parçacığı için kopya ızgaralar (uzun A* ana döngüyü dondurmasın)
	if NN > 512:
		for i in 3:
			var w := AStarGrid2D.new()
			w.region = Rect2i(0, 0, NN, NN)
			w.cell_size = Vector2(1, 1)
			w.diagonal_mode = AStarGrid2D.DIAGONAL_MODE_ONLY_IF_NO_OBSTACLES
			w.default_compute_heuristic = AStarGrid2D.HEURISTIC_OCTILE
			w.default_estimate_heuristic = AStarGrid2D.HEURISTIC_OCTILE
			w.update()
			navw.append(w)

# ------------------------------------------------------------ hücre yardımcıları
static func ci(x: float) -> int:
	return clampi(int(x / CS), 0, N - 1)

func idx(p: Vector3) -> int:
	return ci(p.z) * N + ci(p.x)

func height_at(p: Vector3) -> float:
	return h[idx(p)]

func kind_at(p: Vector3) -> int:
	return kind[idx(p)]

func in_trench(p: Vector3) -> bool:
	return trench[idx(p)] > 0

func set_static_rect(center: Vector3, size: Vector2, rot: float, height: float, k: int, replace := false) -> void:
	var c := cos(rot)
	var s := sin(rot)
	var ext := (absf(size.x * c) + absf(size.y * s)) * 0.5 + CS
	var ext2 := (absf(size.x * s) + absf(size.y * c)) * 0.5 + CS
	var x0 := ci(center.x - ext)
	var x1 := ci(center.x + ext)
	var z0 := ci(center.z - ext2)
	var z1 := ci(center.z + ext2)
	var hv := hq(height)
	var changed: Array = []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var px := (x + 0.5) * CS - center.x
			var pz := (z + 0.5) * CS - center.z
			# yerel eksene döndür (rot: Y etrafında)
			var lx := px * c - pz * s
			var lz := px * s + pz * c
			if absf(lx) <= size.x * 0.5 and absf(lz) <= size.y * 0.5:
				var i := z * N + x
				if replace:
					hs[i] = hv
					kind[i] = k
				elif hv >= hs[i]:
					hs[i] = hv
					kind[i] = k
				changed.append(i)
	refresh(changed)

func set_static_circle(center: Vector3, r: float, height: float, k: int, replace := false) -> void:
	var x0 := ci(center.x - r)
	var x1 := ci(center.x + r)
	var z0 := ci(center.z - r)
	var z1 := ci(center.z + r)
	var hv := hq(height)
	var changed: Array = []
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var px := (x + 0.5) * CS - center.x
			var pz := (z + 0.5) * CS - center.z
			if px * px + pz * pz <= r * r:
				var i := z * N + x
				if replace or hv >= hs[i]:
					hs[i] = hv
					kind[i] = k
				changed.append(i)
	refresh(changed)

# kapı boşluğu işaretle: c kapı merkezi (duvar çizgisi üzerinde), dir duvar doğrultusu, w açıklık genişliği;
# duvarın iki yanına dep kadar (eşik + iç/dış basamak) — o hücreleri kapsayan yol hücreleri piyadeye açık kalır
func mark_door(c: Vector3, dir: Vector3, w: float, dep := 0.9) -> void:
	var d := Vector3(dir.x, 0, dir.z).normalized()
	var nrm := Vector3(-d.z, 0, d.x)
	var r := maxf(w * 0.5, dep) + CS
	for z in range(maxi(0, ci(c.z - r)), mini(N - 1, ci(c.z + r)) + 1):
		for x in range(maxi(0, ci(c.x - r)), mini(N - 1, ci(c.x + r)) + 1):
			var p := Vector3((x + 0.5) * CS - c.x, 0, (z + 0.5) * CS - c.z)
			if absf(p.dot(d)) <= w * 0.5 and absf(p.dot(nrm)) <= dep:
				door[z * N + x] = 1
				_dirty[Vector2i(x / FPN, z / FPN)] = true

func set_crater(p: Vector3, r: float) -> void:
	for z in range(ci(p.z - r), ci(p.z + r) + 1):
		for x in range(ci(p.x - r), ci(p.x + r) + 1):
			if Vector2((x + 0.5) * CS - p.x, (z + 0.5) * CS - p.z).length() < r:
				trench[z * N + x] = 1
	# (163) araç yol bulması kraterin çevresinden dolaşır; geçilebilir ama pahalı (tekerlekli 3×, paletli 1,6×)
	for z in range(clampi(int((p.z - r) / NAV), 0, NN - 1), clampi(int((p.z + r) / NAV), 0, NN - 1) + 1):
		for x in range(clampi(int((p.x - r) / NAV), 0, NN - 1), clampi(int((p.x + r) / NAV), 0, NN - 1) + 1):
			if Vector2((x + 0.5) * NAV - p.x, (z + 0.5) * NAV - p.z).length() < r + NAV * 0.5:
				crat[z * NN + x] = 1
				_dirty[Vector2i(x, z)] = true

func set_trench(a: Vector3, b: Vector3, w: float, on := true) -> void:
	var L := a.distance_to(b)
	var steps := int(L / (CS * 0.5)) + 1
	for i in steps + 1:
		var p := a.lerp(b, float(i) / steps)
		var r := w * 0.5
		for z in range(ci(p.z - r), ci(p.z + r) + 1):
			for x in range(ci(p.x - r), ci(p.x + r) + 1):
				trench[z * N + x] = 1 if on else 0

func refresh(cells: Array) -> void:
	var k := CS / CC
	for i in cells:
		var old := h[i]
		var v: float = maxi(hs[i], hb[i]) / HQ
		h[i] = v
		var c := int(int(i / N) * k) * NCC + int((i % N) * k)
		if v > hm[c]:
			hm[c] = v
		elif v < old and old >= hm[c]:
			_hm_dirty[c] = true
		_dirty[Vector2i((i % N) / FPN, (i / N) / FPN)] = true

# yüksekliği düşen iri hücrelerin en yükseğini yeniden hesapla (yıkım)
func _hm_flush() -> void:
	if _hm_dirty.is_empty():
		return
	var per := int(CC / CS)
	for c in _hm_dirty:
		var cx: int = c % NCC
		var cz: int = c / NCC
		var mx := 0.0
		for z in range(cz * per, mini(N, (cz + 1) * per)):
			var row := z * N
			for x in range(cx * per, mini(N, (cx + 1) * per)):
				mx = maxf(mx, h[row + x])
		hm[c] = mx
	_hm_dirty.clear()

func flush_nav() -> void:
	_hm_flush()
	if _dirty.is_empty():
		return
	if not _pcache.is_empty():
		var lo := Vector2(INF, INF)
		var hi := Vector2(-INF, -INF)
		for c in _dirty:
			lo = lo.min(Vector2(c))
			hi = hi.max(Vector2(c))
		_pcache_invalidate(lo * NAV - Vector2(2, 2), (hi + Vector2.ONE) * NAV + Vector2(2, 2))
	var locked := false
	if not navw.is_empty():
		locked = _wmx.try_lock()
		if locked:
			_qmx.lock()
			_apply_pend()
			_qmx.unlock()
	_direct = locked
	var touched := {}
	for c in _dirty:
		_update_base(c)
		for dz in range(-1, 2):
			for dx in range(-1, 2):
				var q: Vector2i = c + Vector2i(dx, dz)
				if q.x >= 0 and q.y >= 0 and q.x < NN and q.y < NN:
					touched[q] = true
	for q in touched:
		_update_inflated(q)
	_dirty.clear()
	_direct = false
	if locked:
		_wmx.unlock()

func flush_all() -> void:
	if NN > 512:
		# büyük harita: boş hücrelerde AStar varsayılanı (açık, ağırlık 1) zaten doğru;
		# yalnız değişen hücreler + kenar halkası işlenir (1 km'de 1 M hücrelik tam tarama yok)
		for k in NN:
			for c in [Vector2i(k, 0), Vector2i(k, NN - 1), Vector2i(0, k), Vector2i(NN - 1, k)]:
				_dirty[c] = true
		flush_nav()
		return
	for z in NN:
		for x in NN:
			_update_base(Vector2i(x, z))
	for z in NN:
		for x in NN:
			_update_inflated(Vector2i(x, z))
	_dirty.clear()

func _update_base(c: Vector2i) -> void:
	var mx := 0.0
	var nblk := 0
	var wire := false
	var hard_l := false
	var hard_h := false
	var wall_h := false
	var wet := false
	var dr := false
	var bld := false
	for dz in FPN:
		for dx in FPN:
			var i := (c.y * FPN + dz) * N + c.x * FPN + dx
			var v := h[i]
			var k := kind[i]
			if door[i] == 1 and v < 0.45:
				dr = true
			if water[i] >= 1 and bridge[i] == 0:
				wet = true
			mx = maxf(mx, v)
			if v >= 0.45:
				nblk += 1
				if k == K_BUILDING:
					bld = true
			if k == K_WIRE:
				wire = true
			if k == K_TRAP:
				hard_l = true
				hard_h = true
			if v >= 0.3:
				hard_l = true
				if k == K_WALL and hs[i] < 3:
					wall_h = true
				elif k == K_TREE:
					pass
				else:
					hard_h = true
	if wet:
		hard_l = true
		hard_h = true
		wall_h = false
	var inf: AStarGrid2D = nav[M_INF]
	var vlt := mx >= 0.45 and mx < 1.15 and not wet
	# iri yol bulma hücresinde (2 km+) ince duvar tüm hücreyi kapatmasın: piyade için çoğunluk kuralı
	var blk := mx >= 0.45 and not vlt
	if FPN > 2:
		# taraf yapısı (karargâh, fabrika, kışla ...) dolu gövdedir: köşesi değen hücre de kapalı — çoğunluk
		# kuralıyla 45° dönük yapının köşe hücreleri açık kalıyor, işçiler / kamyonlar köşeyi içinden kesiyordu
		blk = blk and (nblk * 2 > FPN * FPN or bld)
	# kapı boşluğu: 1 m'lik yol hücresi kapı pervazıyla kesişse de piyadeye açık (asıl geçiş ince ızgarada
	# çarpışmayla) — 1,3 m'lik kapılar hizaya göre tam açık hücre bırakmıyor, bina içi erişilemez kalıyordu
	if dr:
		blk = false
	inf.set_point_solid(c, blk or wet)
	inf.set_point_weight_scale(c, 5.0 if wire else (6.0 if vlt else 1.0))
	if not navw.is_empty():
		_mset(M_INF, c, blk or wet, 5.0 if wire else (6.0 if vlt else 1.0))
	vault[c.y * NN + c.x] = 1 if vlt else 0
	base_l[c.y * NN + c.x] = 1 if hard_l else 0
	base_h[c.y * NN + c.x] = 1 if hard_h else (2 if wall_h else 0)

func _update_inflated(c: Vector2i) -> void:
	var sl := false
	var sh := false
	var wh := false
	for dz in range(-1, 2):
		for dx in range(-1, 2):
			var x := c.x + dx
			var z := c.y + dz
			if x < 0 or z < 0 or x >= NN or z >= NN:
				sl = true
				sh = true
				continue
			if base_l[z * NN + x] == 1:
				sl = true
			var bh := base_h[z * NN + x]
			if bh == 1:
				sh = true
			elif bh == 2:
				wh = true
	var cr := crat[c.y * NN + c.x] == 1
	var wl := 3.0 if cr else 1.0
	var wv := (4.0 if wh else 1.0) * (1.6 if cr else 1.0)
	var l: AStarGrid2D = nav[M_LIGHT]
	l.set_point_solid(c, sl)
	l.set_point_weight_scale(c, wl)
	var hv: AStarGrid2D = nav[M_HEAVY]
	hv.set_point_solid(c, sh)
	hv.set_point_weight_scale(c, wv)
	if not navw.is_empty():
		_mset(M_LIGHT, c, sl, wl)
		_mset(M_HEAVY, c, sh, wv)

# ------------------------------------------------------------ yol bulma
static func cell_of(p: Vector3) -> Vector2i:
	return Vector2i(clampi(int(p.x / NAV), 0, NN - 1), clampi(int(p.z / NAV), 0, NN - 1))

static func cell_center(c: Vector2i) -> Vector3:
	return Vector3((c.x + 0.5) * NAV, 0, (c.y + 0.5) * NAV)

func solid(c: Vector2i, mode: int) -> bool:
	if c.x < 0 or c.y < 0 or c.x >= NN or c.y >= NN:
		return true
	return nav[mode].is_point_solid(c)

# hedef olarak durulamayan hücre (katı ya da atlanacak alçak engel)
func _occupied(c: Vector2i, mode: int) -> bool:
	if solid(c, mode):
		return true
	return mode == M_INF and vault[c.y * NN + c.x] == 1

# p'nin hücresinde durulabilir mi (harita içi, katı/su/atlanacak engel değil)
func free_at(p: Vector3, mode: int) -> bool:
	if p.x < 0.0 or p.z < 0.0:
		return false
	return not _occupied(Vector2i(int(p.x / NAV), int(p.z / NAV)), mode)

func nearest_free(p: Vector3, mode: int, maxr := 8) -> Vector3:
	var c := cell_of(p)
	if not _occupied(c, mode):
		return p
	for r in range(1, maxr + 1):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var q := c + Vector2i(dx, dz)
				if not _occupied(q, mode):
					var d := Vector2((q.x + 0.5) * NAV - p.x, (q.y + 0.5) * NAV - p.z).length_squared()
					if d < bd:
						bd = d
						best = q
		if best.x >= 0:
			return cell_center(best)
	return p

# kapalı cep: hücreden sınırlı taşmayla en çok 'need' hücreye ulaşılabiliyorsa (her yanı ağaç/duvar/su) true
func _pocket(c: Vector2i, mode: int, need := 64) -> bool:
	var g: AStarGrid2D = nav[mode]
	var seen := {c: true}
	var q: Array[Vector2i] = [c]
	var i := 0
	while i < q.size():
		var p: Vector2i = q[i]
		i += 1
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var n: Vector2i = p + d
			if seen.has(n) or n.x < 0 or n.y < 0 or n.x >= NN or n.y >= NN or g.is_point_solid(n):
				continue
			seen[n] = true
			q.append(n)
			if q.size() >= need:
				return false
	return true

# nearest_free gibi, ama kapalı cebe düşen hücreyi atlar (doğan araç hareket edebilsin)
func nearest_open(p: Vector3, mode: int, maxr := 16) -> Vector3:
	var c := cell_of(p)
	if not _occupied(c, mode) and not _pocket(c, mode):
		return p
	for r in range(1, maxr + 1):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var q := c + Vector2i(dx, dz)
				if _occupied(q, mode):
					continue
				var d := Vector2((q.x + 0.5) * NAV - p.x, (q.y + 0.5) * NAV - p.z).length_squared()
				if d < bd and not _pocket(q, mode):
					bd = d
					best = q
		if best.x >= 0:
			return cell_center(best)
	return nearest_free(p, mode)

# uzun yol önbelleği (büyük harita): aynı bölgeden aynı hedefe kısa sürede gelen istekler
# (bir grubun tüm askerleri) A*'ı tekrar çalıştırmaz; ara noktalar paylaşılır
var _pcache := {}
var _pcache_t := 0.0

func find_path(from: Vector3, to: Vector3, mode: int) -> PackedVector3Array:
	if NN > 1024 or from.distance_to(to) > 160.0:
		var cp := cached_path(from, to, mode)
		if cp.size() > 0:
			return cp
		var res := _find_path(from, to, mode)
		_pcache[_pkey(from, to, mode)] = res
		return res
	return _find_path(from, to, mode)

func _find_path(from: Vector3, to: Vector3, mode: int) -> PackedVector3Array:
	return _search(nav[mode], from, nearest_free(from, mode), nearest_free(to, mode), mode)

# A* + ip çekme düzleştirmesi; gr: ana ya da işçi ızgarası
func _search(gr: AStarGrid2D, from: Vector3, a: Vector3, b: Vector3, mode: int) -> PackedVector3Array:
	var out := PackedVector3Array()
	var ca := cell_of(a)
	var cb := cell_of(b)
	if ca == cb:
		out.append(b)
		return out
	var ids: Array[Vector2i] = gr.get_id_path(ca, cb, true)
	if ids.is_empty():
		out.append(b)
		return out
	var pts := PackedVector3Array()
	pts.append(from)
	for i in range(1, ids.size()):
		pts.append(cell_center(ids[i]))
	if cell_of(pts[pts.size() - 1]) == cb:
		pts[pts.size() - 1] = b
	# ip çekme düzleştirmesi
	var i := 0
	while i < pts.size() - 1:
		var j := mini(pts.size() - 1, i + 24)
		while j > i + 1 and not walkable_line(pts[i], pts[j], mode, gr):
			j -= 1
		out.append(pts[j])
		i = j
	return out

# ------------------------------------------------------------ iş parçacıklı uzun yol (2 km+)
# Uzun A* (büyük haritada 0,1–0,8 sn) işçi iş parçacığında ızgaranın kopyasında (navw) çalışır.
# Kopyaya yazımlar işçi meşgulken kuyruğa alınır (_pend), iş başında ya da işçi boştayken uygulanır.
# Kilit sırası her yerde _wmx → _qmx (kilitlenme olmaz).
var navw: Array = []
var _wmx := Mutex.new()       # işçi arama yaparken tutulur
var _qmx := Mutex.new()       # _pend, _jobs, _busy
var _pend: Array = []         # [mode, hücre, katı, ağırlık]
var _jobs: Array = []         # [key, from, a, b, mode]
var _waiters := {}            # key -> [[cb, to], ...]
var _busy := false
var _direct := false
var _task := -1

# ızgara değişmeden önce (yeni oyun) süren aramayı bekle
func shutdown() -> void:
	_qmx.lock()
	_jobs.clear()
	_qmx.unlock()
	if _task >= 0:
		WorkerThreadPool.wait_for_task_completion(_task)
		_task = -1
	_waiters.clear()

func _mset(mode: int, c: Vector2i, sol: bool, w: float) -> void:
	if _direct:
		var g: AStarGrid2D = navw[mode]
		g.set_point_solid(c, sol)
		g.set_point_weight_scale(c, w)
	else:
		_qmx.lock()
		_pend.append([mode, c, sol, w])
		_qmx.unlock()

func _apply_pend() -> void:
	for e in _pend:
		var g: AStarGrid2D = navw[e[0]]
		g.set_point_solid(e[1], e[2])
		g.set_point_weight_scale(e[1], e[3])
	_pend.clear()

# bu istek iş parçacığına gitmeli mi (uzun yol, büyük harita)
# büyük haritada (işçi ızgaralı) ana iş parçacığında A* yapılmaz: ulaşılamayan hedefte A* 4 M hücrelik tüm
# bölgeyi tarıyordu (araç başına 0,1–0,5 sn; 8 km çatışmasında kare 1 sn'ye çıkıyordu). Kısa ve engelsiz
# yolda arama hiç yapılmaz (direct), gerisi işçide.
func wants_async(from: Vector3, to: Vector3) -> bool:
	return not navw.is_empty() and Vector2(to.x - from.x, to.z - from.z).length() > 6.0

# hedef 48 m içinde ve düz çizgide engelsizse arama gereksiz
func direct(from: Vector3, to: Vector3, mode: int) -> bool:
	var L := Vector2(to.x - from.x, to.z - from.z).length()
	return L <= 48.0 and walkable_line(from, to, mode)

func _pkey(from: Vector3, to: Vector3, mode: int) -> Vector4i:
	return Vector4i(int(from.x / 12.0), int(from.z / 12.0), int(to.x / 12.0) * 4 + mode, int(to.z / 12.0))

func _cache_tick() -> void:
	var now := G.time
	if now - _pcache_t > 8.0:
		_pcache.clear()
		_pcache_t = now

# önbellekte varsa kopyası (son nokta isteğin hedefine çekilir), yoksa boş
func cached_path(from: Vector3, to: Vector3, mode: int) -> PackedVector3Array:
	_cache_tick()
	var key := _pkey(from, to, mode)
	var out := PackedVector3Array()
	if _pcache.has(key):
		out.append_array(_pcache[key])
		# anahtar 12 m'lik bölgeye yuvarlı: aynı bölgede ama binanın öbür yanındaki birim ilk noktaya düz
		# yürürken binanın içinden geçerdi → ilk parça buradan yürünemiyorsa önbellek kullanılmaz
		if out.size() > 0 and not walkable_line(from, out[0], mode):
			return PackedVector3Array()
		if out.size() > 0:
			out[out.size() - 1] = nearest_free(to, mode)
	return out

# ızgara değişti (yapı yerleşti / yıkıldı): değişen bölgeden geçen önbellekli yollar silinir
func _pcache_invalidate(lo: Vector2, hi: Vector2) -> void:
	for key in _pcache.keys():
		var pts: PackedVector3Array = _pcache[key]
		var prev := Vector2(key.x * 12.0 + 6.0, key.y * 12.0 + 6.0)
		for p in pts:
			var q := Vector2(p.x, p.z)
			if minf(prev.x, q.x) <= hi.x and maxf(prev.x, q.x) >= lo.x and minf(prev.y, q.y) <= hi.y and maxf(prev.y, q.y) >= lo.y:
				_pcache.erase(key)
				break
			prev = q

# sonuç gelene kadar yürünecek düz parça: hedefe doğru engelsiz en çok 48 m; yoksa boş
func provisional(from: Vector3, to: Vector3, mode: int) -> PackedVector3Array:
	var dv := Vector3(to.x - from.x, 0, to.z - from.z)
	var L := dv.length()
	var d := dv / maxf(L, 0.001)
	var best := from
	for k in range(1, 13):
		if k * 4.0 > L:
			break
		var p := from + d * k * 4.0
		if not walkable_line(from, p, mode):
			break
		best = p
	if best.distance_to(from) < 3.0:
		return PackedVector3Array()
	return PackedVector3Array([best])

# uzun yol isteği: cb(path) ana iş parçacığında çağrılır; aynı bölge→hedef istekleri tek aramada birleşir
func request_path(from: Vector3, to: Vector3, mode: int, cb: Callable) -> void:
	var key := _pkey(from, to, mode)
	if _waiters.has(key):
		_waiters[key].append([cb, to])
		return
	_waiters[key] = [[cb, to]]
	var job := [key, from, nearest_free(from, mode), nearest_free(to, mode), mode]
	_qmx.lock()
	_jobs.append(job)
	var start := not _busy
	_busy = true
	_qmx.unlock()
	if start:
		if _task >= 0:
			WorkerThreadPool.wait_for_task_completion(_task)     # önceki görev bitmişti (_busy false)
		_task = WorkerThreadPool.add_task(_work, false, "yol bulma")

func _work() -> void:
	while true:
		_wmx.lock()
		_qmx.lock()
		if _jobs.is_empty():
			_busy = false
			_qmx.unlock()
			_wmx.unlock()
			return
		var j: Array = _jobs.pop_front()
		_apply_pend()
		_qmx.unlock()
		var res := _search(navw[j[4]], j[1], j[2], j[3], j[4])
		_wmx.unlock()
		_deliver.call_deferred(j[0], res)

func _deliver(key: Vector4i, res: PackedVector3Array) -> void:
	# çıkışta işçinin ertelenmiş teslimi G serbest kaldıktan sonra gelebilir
	if not is_instance_valid(G):
		return
	_cache_tick()
	_pcache[key] = res
	var ws: Array = _waiters.get(key, [])
	_waiters.erase(key)
	for w in ws:
		var cb: Callable = w[0]
		if not cb.is_valid():
			continue
		var out := PackedVector3Array()
		out.append_array(res)
		if out.size() > 0:
			out[out.size() - 1] = nearest_free(w[1], key.z % 4)
		cb.call(out)

# gelen yolu birimin şimdiki konumundan devam ettir (geçici parçada ilerlemişti)
func splice(res: PackedVector3Array, pos: Vector3, mode: int) -> PackedVector3Array:
	if res.size() < 2:
		return res
	var best := 0
	var bd := INF
	for k in mini(res.size(), 12):
		var d := Vector2(res[k].x - pos.x, res[k].z - pos.z).length_squared()
		if d < bd:
			bd = d
			best = k
	if best + 1 < res.size() and walkable_line(pos, res[best + 1], mode):
		best += 1
	return res.slice(best)

func walkable_line(a: Vector3, b: Vector3, mode: int, nv: AStarGrid2D = null) -> bool:
	var d := Vector2(b.x - a.x, b.z - a.z)
	var L := d.length()
	var steps := int(L / (NAV * 0.4)) + 1
	if nv == null:
		nv = nav[mode]
	for s in range(1, steps + 1):
		var t := float(s) / steps
		var c := Vector2i(int((a.x + d.x * t) / NAV), int((a.z + d.y * t) / NAV))
		if c.x < 0 or c.y < 0 or c.x >= NN or c.y >= NN:
			return false
		if nv.is_point_solid(c):
			return false
	return true

# ------------------------------------------------------------ görüş hattı
func los(a: Vector3, b: Vector3, skip_a := 0.75, skip_b := 0.3) -> bool:
	var dx := b.x - a.x
	var dz := b.z - a.z
	var L := sqrt(dx * dx + dz * dz)
	if L < 0.05:
		return true
	if L < 24.0:
		if not _los_fine(a, b, 0.0, 1.0, L, skip_a, skip_b):
			return false
	else:
		# iri hücre geçişi (Amanatides-Woo): engeli ışından alçak iri hücre atlanır
		var cx := int(a.x / CC)
		var cz := int(a.z / CC)
		var sx := 1 if dx > 0.0 else -1
		var sz := 1 if dz > 0.0 else -1
		var tdx := CC / absf(dx) if absf(dx) > 1e-6 else INF
		var tdz := CC / absf(dz) if absf(dz) > 1e-6 else INF
		var tmx := ((cx + (1 if dx > 0.0 else 0)) * CC - a.x) / dx if absf(dx) > 1e-6 else INF
		var tmz := ((cz + (1 if dz > 0.0 else 0)) * CC - a.z) / dz if absf(dz) > 1e-6 else INF
		var t := 0.0
		var dy := b.y - a.y
		for guard in 4096:
			var tn := minf(minf(tmx, tmz), 1.0)
			if cx >= 0 and cz >= 0 and cx < NCC and cz < NCC:
				var hx := hm[cz * NCC + cx]
				if hx > 0.0 and hx > minf(a.y + dy * t, a.y + dy * tn):
					if not _los_fine(a, b, t, tn, L, skip_a, skip_b):
						return false
			if tn >= 1.0:
				break
			if tmx < tmz:
				cx += sx
				t = tmx
				tmx += tdx
			else:
				cz += sz
				t = tmz
				tmz += tdz
	if not G.smokes.is_empty():
		for sm in G.smokes:
			if _seg_circle(a, b, sm[0], sm[1]):
				return false
	return true

# ince adım (0,33 m) ışının [t0, t1] parçasında; uçlara yakın engeller (pencere, siper kenarı) atlanır.
# Örnek noktaları tüm ışının adım ızgarasındandır: parça parça tarama tek seferlik taramayla aynı sonucu verir.
func _los_fine(a: Vector3, b: Vector3, t0: float, t1: float, L: float, skip_a: float, skip_b: float) -> bool:
	var dx := b.x - a.x
	var dz := b.z - a.z
	var dy := b.y - a.y
	var steps := int(L / 0.33) + 1
	var inv := 1.0 / steps
	for s in range(maxi(1, int(ceil(t0 * steps))), mini(steps - 1, int(floor(t1 * steps))) + 1):
		var t := s * inv
		var dist := t * L
		if dist < skip_a or dist > L - skip_b:
			continue
		var x := int((a.x + dx * t) / CS)
		var z := int((a.z + dz * t) / CS)
		if x < 0 or z < 0 or x >= N or z >= N:
			continue
		if h[z * N + x] > a.y + dy * t:
			return false
	return true

func _seg_circle(a: Vector3, b: Vector3, c: Vector3, r: float) -> bool:
	var ab := Vector2(b.x - a.x, b.z - a.z)
	var ac := Vector2(c.x - a.x, c.z - a.z)
	var L2 := ab.length_squared()
	if L2 < 1e-6:
		return ac.length() < r
	var t := clampf(ac.dot(ab) / L2, 0.0, 1.0)
	return (ac - ab * t).length() < r

# hedefin, atıcıya doğru 1.6 m içinde onu kısmen örten engel var mı (0..1 koruma)
func cover_factor(target: Vector3, target_h: float, shooter: Vector3) -> float:
	var d := Vector2(shooter.x - target.x, shooter.z - target.z)
	var L := d.length()
	if L < 0.5:
		return 0.0
	d /= L
	var best := 0.0
	var k := 0.35
	while k <= 1.6:
		var x := int((target.x + d.x * k) / CS)
		var z := int((target.z + d.y * k) / CS)
		if x >= 0 and z >= 0 and x < N and z < N:
			var v := h[z * N + x]
			if v > 0.25:
				best = maxf(best, clampf(v / maxf(target_h, 0.3), 0.0, 1.0))
		k += 0.3
	if trench[idx(target)] > 0:
		best = maxf(best, 0.8)
	return best

# siper araması: tehdide karşı korunaklı, ulaşılabilir nokta
# dönüş: {pos, type(0 yok,1 alçak,2 yüksek/köşe), score}
# spacing: aynı timin talep ettiği siper noktalarıyla en az aralık (m) — 0,9 m'de askerler omuz omuza
# sıkışıyordu (roadmap 116); keskin nişancı 2,5 m
func find_cover(around: Vector3, threat: Vector3, radius: float, claimed: Array, me: Vector3, spacing := 1.6) -> Dictionary:
	var best := {"pos": around, "type": 0, "score": -1e9}
	var r := int(radius / CS)
	var cx := ci(around.x)
	var cz := ci(around.z)
	var inf: AStarGrid2D = nav[M_INF]
	for dz in range(-r, r + 1):
		for dx in range(-r, r + 1):
			if dx * dx + dz * dz > r * r:
				continue
			var x := cx + dx
			var z := cz + dz
			if x < 1 or z < 1 or x >= N - 1 or z >= N - 1:
				continue
			var i := z * N + x
			if h[i] >= 0.3:
				continue
			var p := Vector3((x + 0.5) * CS, 0, (z + 0.5) * CS)
			if inf.is_point_solid(cell_of(p)):
				continue
			var td := Vector2(threat.x - p.x, threat.z - p.z)
			var tl := td.length()
			if tl < 2.0:
				continue
			td /= tl
			var hc := 0.0
			for k in [0.45, 0.8, 1.15]:
				var qx := int((p.x + td.x * k) / CS)
				var qz := int((p.z + td.y * k) / CS)
				hc = maxf(hc, h[clampi(qz, 0, N - 1) * N + clampi(qx, 0, N - 1)])
			var tr := trench[i] > 0
			var typ := 0
			var sc := 0.0
			if tr:
				typ = 1
				sc = 14.0
			elif hc >= 0.55 and hc <= 1.3:
				typ = 1
				sc = 12.0 + hc * 2.0
			elif hc > 1.3:
				# yüksek duvar: yanından eğilip ateş edebiliyor mu?
				var side := Vector2(-td.y, td.x)
				var corner := false
				for sgn in [-1.0, 1.0]:
					var sx := int((p.x + side.x * 0.7 * sgn + td.x * 0.6) / CS)
					var sz := int((p.z + side.y * 0.7 * sgn + td.y * 0.6) / CS)
					if h[clampi(sz, 0, N - 1) * N + clampi(sx, 0, N - 1)] < 0.4:
						corner = true
				typ = 2
				sc = 9.0 + (5.0 if corner else 0.0)
			else:
				continue
			var dd := Vector2(p.x - around.x, p.z - around.z).length()
			sc -= dd * 0.9
			sc -= Vector2(p.x - me.x, p.z - me.z).length() * 0.25
			for c in claimed:
				var cd := Vector2(c.x - p.x, c.z - p.z).length()
				if cd < spacing:
					sc -= (spacing - cd) * 20.0
			if sc > best["score"]:
				best = {"pos": p, "type": typ, "score": sc}
	return best

func set_bridge(center: Vector3, size: Vector2, rot: float) -> void:
	var c := cos(rot)
	var s := sin(rot)
	var ext := maxf(size.x, size.y) * 0.75
	var changed: Array = []
	for z in range(ci(center.z - ext), ci(center.z + ext) + 1):
		for x in range(ci(center.x - ext), ci(center.x + ext) + 1):
			var px := (x + 0.5) * CS - center.x
			var pz := (z + 0.5) * CS - center.z
			var lx := px * c - pz * s
			var lz := px * s + pz * c
			if absf(lx) <= size.x * 0.5 and absf(lz) <= size.y * 0.5:
				var i := z * N + x
				bridge[i] = 1
				changed.append(i)
	refresh(changed)

# köprünün orta açıklığı çöktü: hücreler yeniden su, araç yönlendirmesi kaldırılır
func clear_bridge(center: Vector3, size: Vector2, rot: float) -> void:
	var c := cos(rot)
	var s := sin(rot)
	var ext := maxf(size.x, size.y) * 0.75
	var changed: Array = []
	for z in range(ci(center.z - ext), ci(center.z + ext) + 1):
		for x in range(ci(center.x - ext), ci(center.x + ext) + 1):
			var px := (x + 0.5) * CS - center.x
			var pz := (z + 0.5) * CS - center.z
			var lx := px * c - pz * s
			var lz := px * s + pz * c
			if absf(lx) <= size.x * 0.5 and absf(lz) <= size.y * 0.5 + 0.6:
				var i := z * N + x
				bridge[i] = 0
				changed.append(i)
	refresh(changed)
	flush_nav()
	for b in bridges.duplicate():
		if b["c"].distance_to(Vector3(center.x, 0, center.z)) < 1.0:
			bridges.erase(b)

func add_bridge(c: Vector3, d: Vector3, L: float, w: float) -> void:
	var dd := Vector3(d.x, 0, d.z).normalized()
	bridges.append({"c": Vector3(c.x, 0, c.z), "d": dd, "L": L, "w": w})

func bridge_at(p: Vector3) -> Dictionary:
	for b in bridges:
		var rel: Vector3 = p - b["c"]
		rel.y = 0
		var along: float = rel.dot(b["d"])
		var side: float = rel.cross(b["d"]).y
		if absf(along) <= b["L"] * 0.5 + 1.0 and absf(side) <= b["w"] * 0.5 + 0.5:
			return b
	return {}

# en yakın kuru (su olmayan ya da köprü) ve alçak engelsiz nokta — suya / köprü kenarına kaymış araç için
func nearest_dry(p: Vector3, maxr_m := 8.0) -> Vector3:
	var c := Vector2i(ci(p.x), ci(p.z))
	var R := int(maxr_m / CS)
	for r in range(0, R + 1):
		var best := Vector2i(-1, -1)
		var bd := 1e9
		for dz in range(-r, r + 1):
			for dx in range(-r, r + 1):
				if absi(dx) != r and absi(dz) != r:
					continue
				var x := c.x + dx
				var z := c.y + dz
				if x < 0 or z < 0 or x >= N or z >= N:
					continue
				var i := z * N + x
				if (water[i] >= 1 and bridge[i] == 0) or h[i] >= 0.3:
					continue
				var d := float(dx * dx + dz * dz)
				if d < bd:
					bd = d
					best = Vector2i(x, z)
		if best.x >= 0:
			return Vector3((best.x + 0.5) * CS, p.y, (best.y + 0.5) * CS)
	return p

func on_bridge(p: Vector3) -> bool:
	return bridge[idx(p)] == 1

func is_water(p: Vector3) -> bool:
	var i := idx(p)
	return water[i] >= 1 and bridge[i] == 0
