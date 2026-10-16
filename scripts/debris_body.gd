class_name DebrisBody extends Node3D
# Kopan ağır parça (taret, namlu, kapak, panel...) için basit katı cisim benzetimi (roadmap 94):
# yerçekimi, takla (açısal hız + kütle dağılımından atalet), arazi yüzeyine ve engel kutularına (ör. enkaz
# gövdesinin güvertesi) nokta temaslı çarpışma — itme + sürtünme impulsları, sekme, yuvarlanma, kayma;
# suya düşüş; durunca uyku. Godot fizik motoru kullanılmaz (arazinin çarpışma şekli yok, yükseklik haritası
# var). Temas noktaları örgünün dış bükey kabuğundan (26 yönde destek noktası, ince çıkıntılar sayılmaz).

const GRAV := 9.81
const SUB := 1.0 / 240.0
const DIRS := [
	Vector3(1, 0, 0), Vector3(-1, 0, 0), Vector3(0, 1, 0), Vector3(0, -1, 0), Vector3(0, 0, 1), Vector3(0, 0, -1),
	Vector3(0.7071, 0.7071, 0), Vector3(0.7071, -0.7071, 0), Vector3(-0.7071, 0.7071, 0), Vector3(-0.7071, -0.7071, 0),
	Vector3(0.7071, 0, 0.7071), Vector3(0.7071, 0, -0.7071), Vector3(-0.7071, 0, 0.7071), Vector3(-0.7071, 0, -0.7071),
	Vector3(0, 0.7071, 0.7071), Vector3(0, 0.7071, -0.7071), Vector3(0, -0.7071, 0.7071), Vector3(0, -0.7071, -0.7071),
	Vector3(0.5774, 0.5774, 0.5774), Vector3(0.5774, 0.5774, -0.5774), Vector3(0.5774, -0.5774, 0.5774), Vector3(0.5774, -0.5774, -0.5774),
	Vector3(-0.5774, 0.5774, 0.5774), Vector3(-0.5774, 0.5774, -0.5774), Vector3(-0.5774, -0.5774, 0.5774), Vector3(-0.5774, -0.5774, -0.5774)]
static var _sup_cache := {}

var vel := Vector3.ZERO           # m/sn (dünya)
var angv := Vector3.ZERO          # rad/sn (dünya)
var inv_i := Vector3.ONE          # yerel atalet tensörü tersinin köşegeni (kütle 1)
var pts := PackedVector3Array()   # yerel temas noktaları (kütle merkezine göre)
var rad := 0.1                    # kütle merkezinden en uzak temas noktası
var rest := 0.2                   # sekme katsayısı (çelik → toprak)
var mu := 0.7                     # sürtünme katsayısı
var obbs: Array = []              # engel kutuları: [merkez, Basis (birim eksenler), yarı boyut] — dünya
var asleep := false
var hits := 0                     # sert çarpma sayısı
var on_impact := Callable()       # func(p: Vector3, speed: float, n: int, metal: bool)
var on_sleep := Callable()        # func(body: DebrisBody)
var max_age := 25.0
var age := 0.0
var wet := false
var peak := 0.0                   # fırlatıldığı yükseklikten en çok ne kadar yükseldi (m; test / ayar)
var _y0 := 0.0
var fx_size := 1.0                # çarpma tozu / kıvılcım / ses büyüklüğü (0: efekt yok)
var smolder := 0.0                # durunca içinden tüten yangın / duman süresi (sn)
var block := Vector2.ZERO         # durunca ızgarada enkaz engeli (genişlik, boy; m) — piyade siper alabilir
var _p := Vector3.ZERO
var _b := Basis.IDENTITY
var _still := 0.0
var _nudges := 0
var _imp_cd := 0.0
var _touch := false
var _touch_metal := false

# `root` düğümünü (dünya dönüşümü korunarak) yeni gövdeye taşır. parts: [[MeshInstance3D, ağırlık, yüzdelik]] —
# kütle merkezi ve atalet parçaların kutularından (ağırlıkla), temas noktaları örgü köşelerinden.
# yüzdelik < 1: o yönde köşelerin en uçtaki küçük payı yok sayılır (anten, makineli gibi ince çıkıntılar).
static func make(root: Node3D, parts: Array, world: Node) -> DebrisBody:
	var db := DebrisBody.new()
	world.add_child(db)
	var com := Vector3.ZERO
	var wsum := 0.0
	for pr in parts:
		var mi: MeshInstance3D = pr[0]
		com += mi.global_transform * mi.mesh.get_aabb().get_center() * float(pr[1])
		wsum += float(pr[1])
	com /= maxf(wsum, 1e-4)
	db.global_transform = Transform3D(root.global_transform.basis.orthonormalized(), com)
	root.reparent(db, true)
	var inv := db.global_transform.affine_inverse()
	var ii := Vector3.ZERO
	var seen := {}
	for pr in parts:
		var mi: MeshInstance3D = pr[0]
		var w: float = float(pr[1]) / maxf(wsum, 1e-4)
		var t: Transform3D = inv * mi.global_transform
		var ab: AABB = t * mi.mesh.get_aabb()
		var s := ab.size
		var c := ab.get_center()
		# kutu ataleti + paralel eksen (köşegen yaklaşık)
		ii += Vector3(s.y * s.y + s.z * s.z, s.x * s.x + s.z * s.z, s.x * s.x + s.y * s.y) * (w / 12.0)
		ii += Vector3(c.y * c.y + c.z * c.z, c.x * c.x + c.z * c.z, c.x * c.x + c.y * c.y) * w
		for q in support_points(mi.mesh, float(pr[2]) if pr.size() > 2 else 1.0):
			var lp: Vector3 = t * q
			var key := Vector3i(roundi(lp.x * 12.0), roundi(lp.y * 12.0), roundi(lp.z * 12.0))
			if seen.has(key):
				continue
			seen[key] = true
			db.pts.append(lp)
			db.rad = maxf(db.rad, lp.length())
	db.inv_i = Vector3(1.0 / maxf(ii.x, 0.005), 1.0 / maxf(ii.y, 0.005), 1.0 / maxf(ii.z, 0.005))
	db._p = db.global_position
	db._b = db.global_transform.basis
	return db

# örgünün 26 yöndeki destek noktaları (örgü yerel uzayı; örgü başına önbellekli)
static func support_points(m: Mesh, pct := 1.0) -> PackedVector3Array:
	var key := "%d_%.3f" % [m.get_instance_id(), pct]
	if _sup_cache.has(key):
		return _sup_cache[key]
	var verts := PackedVector3Array()
	for s in m.get_surface_count():
		var arr := m.surface_get_arrays(s)
		if arr.size() > Mesh.ARRAY_VERTEX and typeof(arr[Mesh.ARRAY_VERTEX]) == TYPE_PACKED_VECTOR3_ARRAY:
			verts.append_array(arr[Mesh.ARRAY_VERTEX])
	var out := PackedVector3Array()
	if verts.size() < 8:
		var ab := m.get_aabb()
		for i in 8:
			out.append(ab.get_endpoint(i))
		_sup_cache[key] = out
		return out
	var step := maxi(1, verts.size() / 6000)
	for k in DIRS.size():
		var d: Vector3 = DIRS[k]
		var lim := INF
		if pct < 1.0:
			# yüzdelik eşiği: o yöndeki izdüşümlerin pct'lik değeri (ince çıkıntılar altta kalır)
			var ds := PackedFloat32Array()
			var i := 0
			while i < verts.size():
				ds.append(verts[i].dot(d))
				i += step
			ds.sort()
			lim = ds[clampi(int(ds.size() * pct), 0, ds.size() - 1)]
		var best := -INF
		var bv := Vector3.ZERO
		var j := 0
		while j < verts.size():
			var v: Vector3 = verts[j]
			var dd := v.dot(d)
			if dd > best and dd <= lim:
				best = dd
				bv = v
			j += step
		out.append(bv)
	_sup_cache[key] = out
	return out

# engel kutusu: düğümün (ör. enkaz gövdesi) yerel AABB'si, üstü `top_y`'de kırpılmış (güverte yüksekliği).
# ring (x, z, yarıçap, derinlik; düğüm yerel): üst yüzde dairesel çukur — boşalan taret yuvası; geri düşen
# taretin bir yanı yuvaya oturur, öbürü güvertede kalır (çarpık oturuş)
func add_obstacle(n: Node3D, ab: AABB, top_y := INF, ring := Vector4.ZERO) -> void:
	if top_y < ab.end.y:
		ab.size.y = maxf(top_y - ab.position.y, 0.05)
	var t := n.global_transform
	var sc := t.basis.get_scale()
	var c := ab.get_center()
	var rv := Vector4.ZERO
	if ring.z > 0.0:
		rv = Vector4((ring.x - c.x) * sc.x, (ring.y - c.z) * sc.z, ring.z * sc.x, ring.w * sc.y)
	obbs.append([t * c, t.basis.orthonormalized(), ab.size * 0.5 * sc, rv])

func launch(v0: Vector3, w0: Vector3) -> void:
	vel = v0
	angv = w0
	_p = global_position
	_b = global_transform.basis.orthonormalized()
	_y0 = _p.y
	peak = 0.0
	asleep = false
	set_process(true)

func _process(dt: float) -> void:
	if asleep or not G.running or dt <= 0.0:
		return
	dt = minf(dt, 0.05)
	age += dt
	_imp_cd -= dt
	var n := clampi(ceili(dt / SUB), 1, 12)
	var h := dt / n
	var touched := false
	for i in n:
		_step(h)
		touched = touched or _touch
	peak = maxf(peak, _p.y - _y0)
	global_transform = Transform3D(_b, _p)
	if touched and vel.length_squared() < 0.04 and angv.length_squared() < 0.05:
		_still += dt
		if _still > 0.12 and _nudges < 2:
			# kusursuz denge yok: kenar / köşe üstünde dengede kalmış parça devrilsin (kararlı duruş sönümlenir)
			_nudges += 1
			_still = 0.0
			angv += Vector3(randf_range(-1.0, 1.0), 0.0, randf_range(-1.0, 1.0)) * 0.3
		elif _still > 0.6:
			_sleep()
	else:
		_still = 0.0
	if age > max_age:
		_sleep()

func _sleep() -> void:
	if asleep:
		return
	asleep = true
	vel = Vector3.ZERO
	angv = Vector3.ZERO
	set_process(false)
	if smolder > 0.0:
		G.fx.burn(_p + Vector3(0, 0.3, 0), smolder, clampf(fx_size * 0.4, 0.25, 0.8))
	if block != Vector2.ZERO and not wet and G.grid != null:
		var f := -_b.z
		f.y = 0.0
		var yaw := atan2(-f.x, -f.z) if f.length() > 0.05 else 0.0
		G.grid.set_static_rect(Vector3(_p.x, 0.0, _p.z), block, yaw, 1.0, Grid.K_WRECK)
	if on_sleep.is_valid():
		on_sleep.call(self)

# çarpma: toprağa düşüşte toz bulutu + toprak parçaları + oyuk izi, çeliğe (enkaz gövdesi) çarpışta kıvılcım;
# ağır çelik sesi hızla büyür
func _impact_fx(p: Vector3, sp: float, metal: bool) -> void:
	if fx_size <= 0.0:
		return
	var s := clampf(fx_size * (0.4 + sp * 0.08), 0.3, 2.5)
	if metal:
		G.fx.sparks(p, 2.0 + sp * 0.3)
		G.fx.impact(p, "metal")
		Sfx.play3d("hit_metal", p, clampf(-16.0 + sp * 1.5, -16.0, 2.0))
		return
	var g := Vector3(p.x, _ground(p) + 0.1, p.z)
	if wet:
		G.fx.water_splash(Vector3(p.x, Terrain.WATER_Y, p.z), clampf(s * 0.5, 0.3, 1.2))
		return
	G.fx.dust_burst(g, s * 1.6)
	for i in 2:
		G.fx.impact(g + Vector3(randf_range(-0.4, 0.4), 0.0, randf_range(-0.4, 0.4)) * s, "dirt")
	if hits <= 2 and sp > 4.0:
		G.fx.scorch(g, s * 1.1)
	Sfx.play3d("hit_metal", p, clampf(-20.0 + sp * 1.3, -20.0, -2.0))
	if sp > 5.0:
		Sfx.play3d("crumble", p, clampf(-14.0 + sp, -14.0, 0.0))

func _step(h: float) -> void:
	vel.y -= GRAV * h
	if wet:
		# suda: sürüklenme (çelik batar, yavaşça dibe iner)
		vel *= exp(-2.6 * h)
		angv *= exp(-2.2 * h)
	_touch = false
	var gh0 := _ground(_p)
	var near := _p.y - rad < gh0 + rad * 0.6 + 0.3
	if not near:
		for o in obbs:
			if _p.distance_to(o[0]) < rad + (o[2] as Vector3).length():
				near = true
				break
	if near:
		_contacts(h)
	_p += vel * h
	var wl := angv.length()
	if wl > 1e-5:
		_b = (Basis(angv / wl, wl * h) * _b).orthonormalized()
	if not wet and _p.y < Terrain.WATER_Y + 0.3 and G.grid != null and G.grid.is_water(_p):
		wet = true
		G.fx.water_splash(Vector3(_p.x, Terrain.WATER_Y, _p.z), clampf(rad * 0.9, 0.5, 2.6))
		Sfx.play3d("expl_small", _p, -6.0)

func _ground(p: Vector3) -> float:
	var gh := G.terrain.ground_hs(p) if G.terrain != null else 0.0
	if G.grid != null and G.grid.on_bridge(p):
		gh = maxf(gh, 0.0)
	return gh

func _gnormal(p: Vector3) -> Vector3:
	var e := 0.35
	var hx := _ground(p + Vector3(e, 0, 0)) - _ground(p - Vector3(e, 0, 0))
	var hz := _ground(p + Vector3(0, 0, e)) - _ground(p - Vector3(0, 0, e))
	return Vector3(-hx, 2.0 * e, -hz).normalized()

# noktanın engel kutusuna gömülmesi: (normal, derinlik) — alt yüz hariç en sığ yüzden dışarı
func _obb_pen(wp: Vector3, o: Array) -> Vector4:
	var d: Vector3 = wp - o[0]
	var bs: Basis = o[1]
	var he: Vector3 = o[2]
	var lx := d.dot(bs.x)
	var ly := d.dot(bs.y)
	var lz := d.dot(bs.z)
	var top := he.y
	var rg: Vector4 = o[3]
	if rg.z > 0.0 and (lx - rg.x) * (lx - rg.x) + (lz - rg.y) * (lz - rg.y) < rg.z * rg.z:
		top = he.y - rg.w
	if absf(lx) >= he.x or absf(lz) >= he.z or ly >= top or ly <= -he.y:
		return Vector4(0, 1, 0, -1.0)
	var pt := top - ly
	var px := he.x - absf(lx)
	var pz := he.z - absf(lz)
	if pt <= px and pt <= pz:
		return Vector4(bs.y.x, bs.y.y, bs.y.z, pt)
	if px <= pz:
		var nx: Vector3 = bs.x * signf(lx)
		return Vector4(nx.x, nx.y, nx.z, px)
	var nz: Vector3 = bs.z * signf(lz)
	return Vector4(nz.x, nz.y, nz.z, pz)

func _iw(v: Vector3, bt: Basis) -> Vector3:
	var l := bt * v
	return _b * Vector3(l.x * inv_i.x, l.y * inv_i.y, l.z * inv_i.z)

func _contacts(h: float) -> void:
	var bt := _b.transposed()
	var max_pen := 0.0
	var pen_n := Vector3.UP
	var any := false
	_touch_metal = false
	for lp in pts:
		var r: Vector3 = _b * lp
		var wp := _p + r
		var n := Vector3.UP
		var pen := -1.0
		var metal := false
		var gh := _ground(wp)
		if wp.y < gh:
			n = _gnormal(wp)
			pen = (gh - wp.y) * n.y
		for o in obbs:
			var res := _obb_pen(wp, o)
			if res.w > pen:
				pen = res.w
				n = Vector3(res.x, res.y, res.z)
				metal = true
		if pen <= 0.0:
			continue
		any = true
		if pen > max_pen:
			max_pen = pen
			pen_n = n
			_touch_metal = metal
		_impulse(r, n, bt, metal)
	if any:
		_touch = true
		# konum düzeltmesi (yumuşak) + yuvarlanma direnci
		_p += pen_n * minf(max_pen, 0.5) * 0.6
		angv *= exp(-1.4 * h)
		vel.x *= exp(-0.5 * h)
		vel.z *= exp(-0.5 * h)

func _impulse(r: Vector3, n: Vector3, bt: Basis, metal: bool) -> void:
	var rel := vel + angv.cross(r)
	var vn := rel.dot(n)
	if vn >= 0.0:
		return
	var rn := r.cross(n)
	var k := 1.0 + n.dot(_iw(rn, bt).cross(r))
	var e := (rest * (1.4 if metal else 1.0)) if vn < -1.5 else 0.0
	var j := -(1.0 + e) * vn / k
	vel += n * j
	angv += _iw(rn, bt) * j
	if -vn > 2.2 and _imp_cd <= 0.0:
		_imp_cd = 0.3
		hits += 1
		_impact_fx(_p + r, -vn, metal)
		if on_impact.is_valid():
			on_impact.call(_p + r, -vn, hits, metal)
	# Coulomb sürtünmesi
	rel = vel + angv.cross(r)
	var vt := rel - n * rel.dot(n)
	var vtl := vt.length()
	if vtl > 1e-4:
		var t := vt / vtl
		var rt := r.cross(t)
		var kt := 1.0 + t.dot(_iw(rt, bt).cross(r))
		var jt := minf(vtl / kt, mu * j)
		vel -= t * jt
		angv -= _iw(rt, bt) * jt
