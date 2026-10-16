class_name Blocks extends Node3D
# Yıkılabilir blok duvar sistemi: parça (chunk) başına MultiMesh, destek zinciri,
# fizik enkazı ve kalıcı moloz.

var CH := 32.0          # MultiMesh parçası (m); büyük haritada 64 m (çizim çağrısı ¼)
const BH := 2.0
enum { T_BOX, T_SANDBAG, T_FENCE, T_CONCRETE }
const MAX_DEBRIS := 110
const RUBBLE_CAP := 9000

var meshes: Array = []
var bpos := PackedVector3Array()
var bsize := PackedVector3Array()
var brot := PackedFloat32Array()
var bcol := PackedColorArray()
var balive := PackedByteArray()
var bwall := PackedInt32Array()
var brow := PackedInt32Array()
var btype := PackedByteArray()
var bsolid := PackedByteArray()
var bkind := PackedByteArray()
var bmm: Array = []
var bidx := PackedInt32Array()
var bsup: Array = []      # destekçiler
var bdep: Array = []      # bağımlılar
var bcells: Array = []    # ızgara hücreleri
var walls: Array = []     # {blocks: Array, house: int, owner: Object}
var houses: Array = []    # {total, alive, roof: Node3D, collapsed, center, size, top}
var cell_blocks := {}
var bhash := {}
var _pending := {}
var finalized := false
var debris: Array = []
var rubble: MultiMesh               # (geriye uyum) ilk bölgenin ilk çeşidi
var rub_mm := {}                     # Vector3i(bölge x, bölge z, çeşit) → [MultiMesh, sayaç]; görüş dışı kırpılır
const RUB_REGION := 128.0
const RUB_PER_REGION := 1200
var rubble_n := 0
var chunks: Array = []               # kırık parça örgüleri (uçan enkaz ve moloz)
var bscar := PackedByteArray()       # delik kenarında yerinden oynamış / kararmış blok
var collapsing: Array = []           # kat kat çöken binalar

var _mat_cache := {}
var rng := RandomNumberGenerator.new()
# uzak görüş: pahlı blok (108 üçgen) yerine düz kutu (12); 8 km haritada 600 bin blok 65 M üçgen ediyordu
var meshes_far: Array = []
var _mmis: Array = []      # [MultiMeshInstance3D, tip]
var far_lod := false

func _ready() -> void:
	rng.seed = 777
	CH = 32.0 if G.MAP <= 2048.0 else 64.0
	meshes = [bevel_box(0.07), sandbag_mesh(), fence_panel(), bevel_box(0.006)]
	var bx := MB.new()
	bx.box(Vector3.ZERO, Vector3.ONE, Color(1, 1, 1))
	var plain := bx.commit()
	var fb := MB.new()
	fb.box(Vector3.ZERO, Vector3(1.0, 1.0, 0.06), Color(1, 1, 1))
	meshes_far = [plain, plain, fb.commit(), plain]
	for k in 3:
		chunks.append(chunk_mesh(k))

# ------------------------------------------------------------ meshler
static func bevel_box(r: float) -> ArrayMesh:
	var mb := MB.new()
	var cs := [-0.5, -0.5 + r, 0.5 - r, 0.5]
	var w := Color(1, 1, 1)
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			for iu in 3:
				for iv in 3:
					var q := [Vector2(cs[iu], cs[iv]), Vector2(cs[iu + 1], cs[iv]), Vector2(cs[iu + 1], cs[iv + 1]), Vector2(cs[iu], cs[iv + 1])]
					var P: Array = []
					var Nn: Array = []
					for k in 4:
						var p := Vector3.ZERO
						p[axis] = 0.5 * sgn
						p[(axis + 1) % 3] = q[k].x
						p[(axis + 2) % 3] = q[k].y
						var inner := p.clamp(Vector3.ONE * (-0.5 + r), Vector3.ONE * (0.5 - r))
						var dv := p - inner
						var n := dv.normalized() if dv.length() > 1e-5 else Vector3.ZERO
						if n == Vector3.ZERO:
							n[axis] = sgn
						P.append(inner + n * r)
						Nn.append(n)
					var fc := w
					mb.tri_s(P[0], P[1], P[2], Nn[0], Nn[1], Nn[2], fc)
					mb.tri_s(P[0], P[2], P[3], Nn[0], Nn[2], Nn[3], fc)
	return mb.commit()

# dolu kum torbası (Roadmap 36): üstü-altı yassı yastık, kenarları yuvarlak, ortası hafif çökük; bir ucu katlanıp
# bağlanmış kulak, uzun kenar boyunca dikiş. Birim kutuya sığar (x boy, y kalınlık, z en); UV çuval dokusu için.
static func sandbag_mesh() -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_color(Color(1, 1, 1))
	var NU := 14
	var NV := 8
	var pts := []
	for side in 2:
		var sg := 1.0 if side == 0 else -1.0
		var rows := []
		for i in NU + 1:
			var u := -1.0 + 2.0 * i / NU
			var row := []
			for k in NV + 1:
				var v := -1.0 + 2.0 * k / NV
				# kesit: yastık profili (kenara doğru incelir); bağlı uçta (u>0.7) daha da yassı
				var fu := pow(maxf(0.0, 1.0 - pow(absf(u), 6.0)), 0.5)
				var fv := pow(maxf(0.0, 1.0 - pow(absf(v), 4.0)), 0.45)
				var tie := 1.0 - 0.45 * smoothstep(0.55, 1.0, u)
				var hgt := 0.5 * fu * fv * tie
				if side == 0:
					hgt -= 0.06 * (1.0 - u * u) * (1.0 - v * v)       # üstte hafif çökme (dolgu yatışır)
				var x := u * 0.5 * (1.0 - 0.05 * absf(v))
				var z := v * 0.5 * (1.0 - 0.08 * smoothstep(0.5, 1.0, u))
				row.append(Vector3(x, sg * maxf(hgt, 0.0), z))
			rows.append(row)
		pts.append(rows)
	for side in 2:
		var R: Array = pts[side]
		for i in NU:
			for k in NV:
				var a: Vector3 = R[i][k]
				var b: Vector3 = R[i + 1][k]
				var c: Vector3 = R[i + 1][k + 1]
				var d: Vector3 = R[i][k + 1]
				# Godot: Plane(p1, p2, p3) normali (p1-p3)×(p1-p2) → üst yüz a,b,c; alt yüz ters sıra
				var quad := [a, b, c, a, c, d] if side == 0 else [a, c, b, a, d, c]
				for q in quad:
					st.set_uv(Vector2(q.x * 0.66, q.z * 0.36))
					st.add_vertex(q)
	# bağlı uç kulağı: katlanmış çuval kenarı (ince, yukarı kıvrık)
	for sgn in [-1.0, 1.0]:
		var p0 := Vector3(0.48, 0.0, sgn * 0.0)
		var p1 := Vector3(0.6, 0.06, sgn * 0.12)
		var p2 := Vector3(0.6, 0.06, -sgn * 0.12)
		# iki yüzlü (ince kulak her yönden görünsün)
		for tri in [[p0, p1, p2], [p0, p2, p1]]:
			for q in tri:
				st.set_uv(Vector2(q.x * 0.66, q.z * 0.36))
				st.add_vertex(q)
	st.generate_normals()
	st.generate_tangents()
	return st.commit()

# kırık duvar parçası: köşeleri yontulmuş, yüzeyleri eğri düzensiz parça (düz gölgeleme = kırık yüz);
# aynı konuma aynı sapma → su geçirmez örgü
static func chunk_mesh(seed: int) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	st.set_color(Color(1, 1, 1))
	var sc := Vector3(1.0, 0.8 + 0.15 * seed, 1.0 - 0.1 * seed)
	var warp := func(p: Vector3) -> Vector3:
		# köşe ve kenarlar içeri (pah), her köşe noktası konumuna bağlı rastgele (komşu yüzlerle aynı)
		var nE := int(absf(p.x) > 0.49) + int(absf(p.y) > 0.49) + int(absf(p.z) > 0.49)
		var k: float = [1.0, 1.0, 0.86, 0.7][nE]
		var q := (p * 100.0).round()
		var h := fposmod(sin(q.x * 0.317 + q.y * 0.173 + q.z * 0.231 + seed * 5.1) * 43758.5453, 1.0)
		var h2 := fposmod(sin(q.x * 0.113 + q.y * 0.419 + q.z * 0.077 + seed * 2.3) * 24634.6345, 1.0)
		return p * sc * k * (0.8 + 0.32 * h) + Vector3((h2 - 0.5) * 0.12, (h - 0.5) * 0.1, (h2 - 0.5) * 0.08)
	for axis in 3:
		for sgn in [-1.0, 1.0]:
			var g := []
			for i in 3:
				var row := []
				for j in 3:
					var p := Vector3.ZERO
					p[axis] = 0.5 * sgn
					p[(axis + 1) % 3] = -0.5 + 0.5 * i
					p[(axis + 2) % 3] = -0.5 + 0.5 * j
					row.append(warp.call(p))
				g.append(row)
			for i in 2:
				for j in 2:
					var a: Vector3 = g[i][j]
					var b: Vector3 = g[i + 1][j]
					var c: Vector3 = g[i + 1][j + 1]
					var d: Vector3 = g[i][j + 1]
					# dışa bakan yüz (Godot: Plane(p1,p2,p3) normali (p1-p3)×(p1-p2))
					# yüz çerçevesi u×v = eksen yönü; (a,c,b) dışa bakar
					var tris := [a, c, b, a, d, c] if sgn > 0.0 else [a, b, c, a, c, d]
					for t in tris:
						st.add_vertex(t)
	st.generate_normals()
	return st.commit()

static func fence_panel() -> ArrayMesh:
	var mb := MB.new()
	var c := Color(1, 1, 1)
	for i in 7:
		var x := -0.5 + (i + 0.5) / 7.0
		mb.box(Vector3(x, 0.0, 0), Vector3(0.09, 1.0, 0.06), c)
	mb.box(Vector3(0, 0.25, -0.05), Vector3(1.0, 0.08, 0.04), c.darkened(0.1))
	mb.box(Vector3(0, -0.25, -0.05), Vector3(1.0, 0.08, 0.04), c.darkened(0.1))
	return mb.commit()

func _type_mat(t: int) -> Material:
	match t:
		T_BOX, T_CONCRETE:
			return Mats.masonry()
		T_FENCE:
			return Mats.vc2()
		T_SANDBAG:
			return Mats.sandbag()
	return Mats.vc()

func _color_mat(col: Color, t: int) -> Material:
	var q := Color(snappedf(col.r, 0.06), snappedf(col.g, 0.06), snappedf(col.b, 0.06))
	var key := "%s_%d" % [q.to_html(), t]
	if not _mat_cache.has(key):
		var base: StandardMaterial3D = Mats.stone() if t != T_FENCE else Mats.vc2()
		var m: StandardMaterial3D = base.duplicate()
		m.vertex_color_use_as_albedo = false
		m.albedo_color = q
		_mat_cache[key] = m
	return _mat_cache[key]

# ------------------------------------------------------------ kurulum
func new_wall(house := -1, owner: Object = null) -> int:
	walls.append({"blocks": [], "house": house, "owner": owner})
	return walls.size() - 1

# nokta hangi binanın içinde (yoksa -1)
func house_at(p: Vector3) -> int:
	for i in houses.size():
		var h: Dictionary = houses[i]
		if h["collapsed"] or not h.has("slots") or h["slots"].is_empty():
			continue
		var c: Vector3 = h["center"]
		var sz: Vector2 = h["size"]
		if absf(p.x - c.x) < sz.x * 0.5 + 0.3 and absf(p.z - c.z) < sz.y * 0.5 + 0.3:
			return i
	return -1

func house_free_slot(hid: int) -> int:
	var h: Dictionary = houses[hid]
	if not h.has("ok"):
		# girilebilir mi: kapıdan içeri yol var mı
		h["ok"] = h.get("door", Vector3.INF) != Vector3.INF and G.grid.find_path(h["door"], h["center"], Grid.M_INF).size() > 0
	if not h["ok"] or h["collapsed"]:
		return -1
	var occ: Dictionary = h["occ"]
	for k in h["slots"].size():
		var o = occ.get(k, null)
		if o == null or not is_instance_valid(o) or not o.alive or o.house_id != hid:
			return k
	return -1

func house_team(hid: int) -> int:
	# pencere yuvası olmayan yapı (silo, tank, sera) kimse tarafından tutulmaz
	for o in houses[hid].get("occ", {}).values():
		if o != null and is_instance_valid(o) and o.alive and o.house_id == hid:
			return o.team
	return -1

var _cut_t := 0.0
func _roof_cut(dt: float) -> void:
	_cut_t -= dt
	if _cut_t > 0.0 or not G.running:
		return
	_cut_t = 0.3
	# içinde görüş tarafından asker olan binanın çatısını gizle (içerisi görünsün)
	var vt := G.view_team()
	for h in houses:
		if h["collapsed"] or not h.has("occ"):
			continue
		var show := true
		for o in h["occ"].values():
			if o != null and is_instance_valid(o) and o.alive and o.house_id >= 0 and (vt < 0 or o.team == vt):
				show = false
				break
		var roof: Node3D = h["roof"]
		if roof and is_instance_valid(roof):
			roof.visible = show

func new_house(center: Vector3, size: Vector2, top: float, roof: Node3D) -> int:
	houses.append({"total": 0, "alive": 0, "roof": roof, "collapsed": false, "center": center, "size": size, "top": top})
	return houses.size() - 1

func add_block(pos: Vector3, size: Vector3, rot: float, col: Color, t: int, wall: int, row: int, k: int, solid := true) -> int:
	var id := bpos.size()
	bpos.append(pos)
	bsize.append(size)
	brot.append(rot)
	bcol.append(col)
	balive.append(1)
	bwall.append(wall)
	brow.append(row)
	btype.append(t)
	bsolid.append(1 if solid else 0)
	bkind.append(k)
	bmm.append(null)
	bidx.append(-1)
	bsup.append(PackedInt32Array())
	bdep.append(PackedInt32Array())
	bcells.append(PackedInt32Array())
	bscar.append(0)
	if wall >= 0:
		walls[wall]["blocks"].append(id)
		var hh: int = walls[wall]["house"]
		if hh >= 0:
			houses[hh]["total"] += 1
			houses[hh]["alive"] += 1
	var hk := Vector2i(int(pos.x / BH), int(pos.z / BH))
	if bhash.has(hk):
		bhash[hk].append(id)
	else:
		bhash[hk] = [id]
	var ck := Vector3i(int(pos.x / CH), int(pos.z / CH), t)
	if _pending.has(ck):
		_pending[ck].append(id)
	else:
		_pending[ck] = [id]
	return id

# kurulumda blok rengini değiştir (kaide, köşe taşı); dışarıdan dizi yazmak her seferinde kopyalar
func set_col(id: int, c: Color) -> void:
	bcol[id] = c

func _xform(id: int) -> Transform3D:
	var k := 0.997 if bkind[id] == Grid.K_HOUSE else 0.965
	return Transform3D(Basis(Vector3.UP, brot[id]).scaled(bsize[id] * k), bpos[id])

# a→b arası blok duvar. gaps: [[s0, s1, r0, r1, frame], ...] (duvar boyunca metre, sıra aralığı)
func wall_line(a: Vector3, b: Vector3, rows: int, col: Color, k: int, opt := {}) -> int:
	var blen: float = opt.get("len", 0.5)
	var bh: float = opt.get("h", 0.42)
	var bt: float = opt.get("t", 0.45)
	var ruin: float = opt.get("ruin", 0.0)
	var gaps: Array = opt.get("gaps", [])
	var t: int = opt.get("type", T_BOX)
	var jit: float = opt.get("jit", 0.07)
	var house: int = opt.get("house", -1)
	var solid: bool = opt.get("solid", true)
	var y0: float = opt.get("y0", 0.0)
	var w := new_wall(house, opt.get("owner", null))
	var d := b - a
	d.y = 0
	var L := d.length()
	if L < 0.1:
		return w
	var dir := d / L
	var rot := atan2(-dir.z, dir.x)
	var n := maxi(1, int(round(L / blen)))
	var bl := L / n
	# yıkık profil: konum başına sütun yüksekliği
	var prof: Array = []
	var cols := n * 2 + 2
	var hv := float(rows)
	for i in cols:
		if ruin > 0.0:
			hv += rng.randf_range(-1.6, 1.6) * ruin
			hv = clampf(hv, 0.0, float(rows))
			if rng.randf() < ruin * 0.18:
				hv = maxf(0.0, hv - rng.randf_range(1.0, 3.0))
		prof.append(hv)
	for r in rows:
		var segs: Array = []
		if r % 2 == 0:
			for i in n:
				segs.append([bl * i, bl * (i + 1)])
		else:
			segs.append([0.0, bl * 0.5])
			for i in n - 1:
				segs.append([bl * (i + 0.5), bl * (i + 1.5)])
			segs.append([L - bl * 0.5, L])
		for sg in segs:
			var s0: float = sg[0]
			var s1: float = sg[1]
			var sc := (s0 + s1) * 0.5
			var pi := clampi(int(sc / L * (cols - 1)), 0, cols - 1)
			if r >= int(prof[pi]):
				continue
			var skip := false
			for gp in gaps:
				if sc > gp[0] and sc < gp[1] and r >= gp[2] and r <= gp[3]:
					skip = true
					break
			if skip:
				continue
			var c := MB.jit(col, rng, jit)
			if rng.randf() < 0.06:
				c = c.darkened(0.12)
			var pos := a + dir * sc + Vector3(0, y0 + bh * (r + 0.5), 0)
			if t == T_SANDBAG:
				# elle dizilmiş torbalar: birkaç derece dönük, öne-arkaya kaymış, biraz farklı boyda
				var nrm := Vector3(-dir.z, 0, dir.x)
				add_block(pos + nrm * rng.randf_range(-0.025, 0.025) + dir * rng.randf_range(-0.02, 0.02), Vector3((s1 - s0) * rng.randf_range(0.94, 1.04), bh * rng.randf_range(0.92, 1.06), bt * rng.randf_range(0.95, 1.05)), rot + rng.randf_range(-0.07, 0.07), c, t, w, r, k, solid)
				continue
			add_block(pos, Vector3(s1 - s0, bh, bt), rot, c, t, w, r, k, solid)
	# pencere çerçeveleri (siyah, görüşü kesmeyen)
	for gp in gaps:
		if gp.size() > 4 and gp[4]:
			var s0: float = gp[0]
			var s1: float = gp[1]
			var ylo = y0 + bh * gp[2]
			var yhi = y0 + bh * (gp[3] + 1)
			var fcol := Color(0.07, 0.07, 0.07)
			var mid := a + dir * ((s0 + s1) * 0.5)
			var fw := s1 - s0
			add_block(mid + Vector3(0, yhi - 0.04, 0), Vector3(fw, 0.08, bt * 0.6), rot, fcol, T_BOX, w, gp[3], k, false)
			if gp[2] > 0:
				add_block(mid + Vector3(0, ylo + 0.04, 0), Vector3(fw, 0.08, bt * 1.1), rot, fcol, T_BOX, w, gp[2], k, false)
			for sx in [s0 + 0.04, s1 - 0.04]:
				add_block(a + dir * sx + Vector3(0, (ylo + yhi) * 0.5, 0), Vector3(0.08, yhi - ylo, bt * 0.6), rot, fcol, T_BOX, w, gp[2], k, false)
			if gp.size() > 5 and gp[5]:
				# kepenk/ızgara: ortada ince dikme
				add_block(mid + Vector3(0, (ylo + yhi) * 0.5, 0), Vector3(0.05, yhi - ylo, bt * 0.4), rot, fcol, T_BOX, w, gp[2], k, false)
	return w

func finalize() -> void:
	_build_support(0)
	for ck in _pending:
		var ids: Array = _pending[ck]
		var mm := _make_mm(ids, ck.z)
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = mm
		mi.material_override = _type_mat(ck.z)
		add_child(mi)
		_mmis.append([mi, ck.z])
	_pending.clear()
	var cells: Array = []
	for id in bpos.size():
		_register_cells(id, cells)
	G.grid.refresh(cells)
	finalized = true

func set_far(on: bool) -> void:
	if on == far_lod:
		return
	far_lod = on
	for e in _mmis:
		var mi: MultiMeshInstance3D = e[0]
		if is_instance_valid(mi) and mi.multimesh != null:
			mi.multimesh.mesh = meshes_far[e[1]] if on else meshes[e[1]]

func _make_mm(ids: Array, t: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = meshes_far[t] if far_lod else meshes[t]
	mm.instance_count = ids.size()
	for i in ids.size():
		var id: int = ids[i]
		mm.set_instance_transform(i, _xform(id))
		mm.set_instance_color(i, bcol[id])
		bmm[id] = mm
		bidx[id] = i
	return mm

# çalışma zamanında (inşa edilen savunma) duvarları anında kur
func commit_runtime(from_id: int) -> MultiMeshInstance3D:
	var by_t := {}
	for id in range(from_id, bpos.size()):
		var t := btype[id]
		if by_t.has(t):
			by_t[t].append(id)
		else:
			by_t[t] = [id]
	var last: MultiMeshInstance3D = null
	for t in by_t:
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = _make_mm(by_t[t], t)
		mi.material_override = _type_mat(t)
		add_child(mi)
		_mmis.append([mi, t])
		last = mi
	_pending.clear()
	_build_support(from_id)
	var cells: Array = []
	for id in range(from_id, bpos.size()):
		_register_cells(id, cells)
	G.grid.refresh(cells)
	return last

const LINTEL := 1.85

func _register_cells(id: int, cells: Array) -> void:
	if bsolid[id] == 0 or balive[id] == 0:
		return
	var p := bpos[id]
	var s := bsize[id]
	var bas := Basis(Vector3.UP, brot[id])
	var top := p.y + s.y * 0.5
	var set := {}
	var nx := maxi(1, int(s.x / 0.22))
	var nz := maxi(1, int(s.z / 0.22))
	for ix in nx + 1:
		for iz in nz + 1:
			var lp := Vector3((float(ix) / nx - 0.5) * s.x * 0.92, 0, (float(iz) / nz - 0.5) * s.z * 0.92)
			var wp := p + bas * lp
			set[G.grid.idx(wp)] = true
	var arr := PackedInt32Array()
	for ci in set:
		arr.append(ci)
		if cell_blocks.has(ci):
			cell_blocks[ci].append(id)
		else:
			cell_blocks[ci] = PackedInt32Array([id])
		# lento / pencere üstü: tabanı insan boyundan yüksek blok yerdeki geçişi kapatmaz (kapı, pencere)
		if top > G.grid.hb[ci] / Grid.HQ and p.y - s.y * 0.5 < LINTEL:
			G.grid.hb[ci] = Grid.hq(top)
		if G.grid.kind[ci] < bkind[id] or G.grid.kind[ci] == Grid.K_NONE:
			G.grid.kind[ci] = bkind[id]
		cells.append(ci)
	bcells[id] = arr

func _build_support(from_id: int) -> void:
	var by_wall := {}
	for id in range(from_id, bpos.size()):
		var w := bwall[id]
		if w < 0:
			continue
		if by_wall.has(w):
			by_wall[w].append(id)
		else:
			by_wall[w] = [id]
	for w in by_wall:
		var ids: Array = by_wall[w]
		var rows := {}
		for id in ids:
			var r := brow[id]
			if rows.has(r):
				rows[r].append(id)
			else:
				rows[r] = [id]
		for id in ids:
			var r := brow[id]
			if r == 0:
				continue
			var sup := PackedInt32Array()
			var p := bpos[id]
			var lim := bsize[id].x * 0.78
			if rows.has(r - 1):
				for o in rows[r - 1]:
					if bsolid[o] == 0:
						continue
					var q := bpos[o]
					if Vector2(q.x - p.x, q.z - p.z).length() < lim + bsize[o].x * 0.25:
						sup.append(o)
			if sup.is_empty() and rows.has(r):
				# pencere üstü lento: aynı sıradaki komşular taşır
				for o in rows[r]:
					if o == id:
						continue
					var q := bpos[o]
					if Vector2(q.x - p.x, q.z - p.z).length() < bsize[id].x * 1.15:
						sup.append(o)
			bsup[id] = sup
			for o in sup:
				var dl: PackedInt32Array = bdep[o]
				dl.append(id)
				bdep[o] = dl

# ------------------------------------------------------------ yıkım
func blocks_near(p: Vector3, r: float) -> Array:
	var out: Array = []
	var x0 := int((p.x - r) / BH)
	var x1 := int((p.x + r) / BH)
	var z0 := int((p.z - r) / BH)
	var z1 := int((p.z + r) / BH)
	for x in range(x0, x1 + 1):
		for z in range(z0, z1 + 1):
			var k := Vector2i(x, z)
			if bhash.has(k):
				for id in bhash[k]:
					if balive[id] == 1:
						out.append(id)
	return out

func blast(center: Vector3, radius: float, power: float) -> int:
	var killed: Array = []
	for id in blocks_near(center, radius + 0.5):
		var d := bpos[id].distance_to(center)
		if d < radius * rng.randf_range(0.7, 1.08):
			killed.append(id)
	if killed.is_empty():
		return 0
	_destroy_many(killed, center, power)
	return killed.size()

func crush(center: Vector3, radius: float, dir: Vector3, power := 0.6) -> bool:
	var killed: Array = []
	for id in blocks_near(center, radius + 0.4):
		var p := bpos[id]
		if Vector2(p.x - center.x, p.z - center.z).length() < radius:
			killed.append(id)
	if killed.is_empty():
		return false
	_destroy_many(killed, center - dir * 2.0, power)
	return true

func _destroy_many(ids: Array, center: Vector3, power: float) -> void:
	var cells := {}
	var queue: Array = []
	for id in ids:
		if balive[id] == 1:
			_kill(id, center, power, cells)
			queue.append(id)
	# destek zinciri: dayanağı kalmayanlar düşer
	var guard := 0
	while not queue.is_empty() and guard < 4000:
		guard += 1
		var id: int = queue.pop_back()
		for dep in bdep[id]:
			if balive[dep] == 0:
				continue
			var ok := false
			for s in bsup[dep]:
				if balive[s] == 1:
					ok = true
					break
			if not ok:
				_kill(dep, bpos[dep] + Vector3(rng.randf_range(-1, 1), 2.0, rng.randf_range(-1, 1)), power * 0.25, cells)
				queue.append(dep)
	# delik kenarı: kalan komşu bloklar hafifçe yerinden oynar, kırık yüz kararır (basamaklı "lego" deliği olmaz)
	var scar_n := 0
	for id in ids:
		for nb in blocks_near(bpos[id], 0.8):
			if bscar[nb] == 0 and balive[nb] == 1 and scar_n < 60:
				_scar(nb, bpos[id])
				scar_n += 1
	# toz bulutu (yıkılan blok sayısıyla büyür)
	if ids.size() > 0 and G.fx:
		var cm := Vector3.ZERO
		for id in ids:
			cm += bpos[id]
		cm /= ids.size()
		G.fx.dust_burst(cm + Vector3(0, 0.6, 0), clampf(sqrt(float(ids.size())) * 0.45, 0.6, 4.5))
	var changed: Array = []
	for ci in cells:
		var mx := 0.0
		if cell_blocks.has(ci):
			for o in cell_blocks[ci]:
				if balive[o] == 1 and bpos[o].y - bsize[o].y * 0.5 < LINTEL:
					mx = maxf(mx, bpos[o].y + bsize[o].y * 0.5)
		G.grid.hb[ci] = Grid.hq(mx)
		changed.append(ci)
	G.grid.refresh(changed)
	if ids.size() > 0:
		Sfx.play3d("crumble", center, -2.0)

func _kill(id: int, center: Vector3, power: float, cells: Dictionary) -> void:
	balive[id] = 0
	var mm: MultiMesh = bmm[id]
	if mm != null:
		mm.set_instance_transform(bidx[id], Transform3D(Basis().scaled(Vector3(0.001, 0.001, 0.001)), Vector3(bpos[id].x, -5, bpos[id].z)))
	for ci in bcells[id]:
		cells[ci] = true
	var w := bwall[id]
	if w >= 0:
		var hh: int = walls[w]["house"]
		if hh >= 0:
			houses[hh]["alive"] -= 1
			_check_house(hh)
		var ow = walls[w]["owner"]
		if ow != null and is_instance_valid(ow) and ow.has_method("on_block_lost"):
			ow.on_block_lost()
	if btype[id] == T_FENCE:
		_spawn_debris(id, center, power * 0.6)
		return
	_spawn_debris(id, center, power)

# delik kenarındaki blok: 2–4° eğilir, 1–3 cm dışa kayar, kırık yüz ve isle kararır
func _scar(id: int, from: Vector3) -> void:
	bscar[id] = 1
	var mm: MultiMesh = bmm[id]
	if mm == null:
		return
	var out := bpos[id] - from
	out.y = 0
	out = out.normalized() * rng.randf_range(0.01, 0.03) if out.length() > 0.01 else Vector3.ZERO
	var b := Basis(Vector3.UP, brot[id] + rng.randf_range(-0.05, 0.05)) * Basis(Vector3(rng.randf_range(-1, 1), 0.001, rng.randf_range(-1, 1)).normalized(), rng.randf_range(0.03, 0.07))
	var k := 0.997 if bkind[id] == Grid.K_HOUSE else 0.965
	mm.set_instance_transform(bidx[id], Transform3D(b.scaled(bsize[id] * k * rng.randf_range(0.9, 0.98)), bpos[id] + out))
	var c := bcol[id]
	var d := c.darkened(rng.randf_range(0.12, 0.3))
	d.a = c.a
	mm.set_instance_color(bidx[id], d)

func _spawn_debris(id: int, center: Vector3, power: float) -> void:
	var p := bpos[id]
	var s := bsize[id]
	if btype[id] == T_FENCE:
		_fence_debris(id, center, power)
		return
	if btype[id] == T_SANDBAG:
		_bag_burst(id, center, power)
		return
	# blok tek parça uçmaz: 2–3 düzensiz parçaya ayrılır; biri fizikle savrulur (sınır dolmadıysa), kalanı dibe
	# moloz olur; ince kırıntılar parçacık
	var col := bcol[id]
	if G.fx:
		for i in 3:
			var cc := col.darkened(rng.randf_range(0.0, 0.25))
			G.fx.emit(Fx.P_DEBRIS, p + Vector3(rng.randf_range(-0.2, 0.2), rng.randf_range(-0.15, 0.15), rng.randf_range(-0.2, 0.2)),
				Vector3(rng.randf_range(-3, 3), rng.randf_range(1.5, 5.0), rng.randf_range(-3, 3)) * clampf(power, 0.3, 1.5), rng.randf_range(0.6, 1.1), 0.05, 0.05, 11.0, 0.4, Color(cc.r, cc.g, cc.b, 1.0))
	var parts := 2 if s.length() < 0.6 else 3
	for i in parts:
		var ps := Vector3(s.x * rng.randf_range(0.35, 0.6), s.y * rng.randf_range(0.5, 0.9), s.z * rng.randf_range(0.6, 1.0))
		var pp := p + Basis(Vector3.UP, brot[id]) * Vector3((float(i) - (parts - 1) * 0.5) * s.x * 0.45, rng.randf_range(-0.1, 0.1), 0.0)
		if i == 0 and debris.size() < MAX_DEBRIS and s.length() >= 0.15:
			_debris_body(pp, ps, col, brot[id], center, power)
		elif i == 0 or rng.randf() < 0.55:
			var dd := pp - center
			dd.y = 0
			var fall := Vector3(rng.randf_range(-0.9, 0.9), 0, rng.randf_range(-0.9, 0.9)) + (dd.normalized() if dd.length() > 0.01 else Vector3.ZERO) * rng.randf_range(0.2, 1.4) * clampf(power, 0.2, 1.2)
			_add_rubble(Vector3(pp.x + fall.x, 0.0, pp.z + fall.z), ps, col)

# kum torbası parçalanmaz: yırtılır, kum fışkırır, sönmüş torba dibe düşer
var bag_rubble: MultiMesh = null
var bag_n := 0
func _bag_burst(id: int, center: Vector3, power: float) -> void:
	var p := bpos[id]
	var s := bsize[id]
	if G.fx:
		var sand := G.fx.sand_col.darkened(0.15)
		for i in 5:
			G.fx.emit(Fx.P_DEBRIS, p, Vector3(rng.randf_range(-2.5, 2.5), rng.randf_range(1.0, 3.5), rng.randf_range(-2.5, 2.5)) * clampf(power, 0.4, 1.4), rng.randf_range(0.5, 0.9), 0.04, 0.04, 10.0, 0.5, Color(sand.r, sand.g, sand.b, 1.0))
	if bag_rubble == null:
		bag_rubble = MultiMesh.new()
		bag_rubble.transform_format = MultiMesh.TRANSFORM_3D
		bag_rubble.use_colors = true
		bag_rubble.mesh = meshes[T_SANDBAG]
		bag_rubble.instance_count = 2000
		bag_rubble.visible_instance_count = 0
		var mi := MultiMeshInstance3D.new()
		mi.multimesh = bag_rubble
		mi.material_override = Mats.sandbag()
		add_child(mi)
	var away := p - center
	away.y = 0
	var off := (away.normalized() if away.length() > 0.01 else Vector3.ZERO) * rng.randf_range(0.1, 0.8) + Vector3(rng.randf_range(-0.3, 0.3), 0, rng.randf_range(-0.3, 0.3))
	var gy: float = G.terrain.ground_h(p) if G.terrain else 0.0
	var sc := Vector3(s.x * rng.randf_range(0.9, 1.05), s.y * 0.4, s.z * rng.randf_range(0.95, 1.15))
	var b := Basis(Vector3.UP, brot[id] + rng.randf_range(-0.6, 0.6)) * Basis(Vector3.RIGHT, rng.randf_range(-0.15, 0.15))
	var i := bag_n % 2000
	bag_rubble.set_instance_transform(i, Transform3D(b.scaled(sc), Vector3(p.x + off.x, gy + sc.y * 0.3, p.z + off.z)))
	bag_rubble.set_instance_color(i, bcol[id].darkened(0.12))
	bag_n += 1
	bag_rubble.visible_instance_count = mini(bag_n, 2000)

func _fence_debris(id: int, center: Vector3, power: float) -> void:
	var p := bpos[id]
	var s := bsize[id]
	if debris.size() >= MAX_DEBRIS:
		return
	var rb := RigidBody3D.new()
	rb.collision_layer = 2
	rb.collision_mask = 1 | 2
	rb.mass = 8.0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s * 0.9
	cs.shape = bs
	rb.add_child(cs)
	var m := MeshInstance3D.new()
	m.mesh = meshes[T_FENCE]
	m.scale = s * 0.97
	m.material_override = _color_mat(bcol[id], T_FENCE)
	rb.add_child(m)
	add_child(rb)
	rb.global_transform = Transform3D(Basis(Vector3.UP, brot[id]), p)
	var away := p - center
	away.y = 0
	var dir := away.normalized() if away.length() > 0.01 else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
	rb.linear_velocity = dir * rng.randf_range(1.5, 5.0) * power + Vector3(0, rng.randf_range(1.0, 4.0) * power, 0)
	rb.angular_velocity = Vector3(rng.randf_range(-6, 6), rng.randf_range(-6, 6), rng.randf_range(-6, 6))
	debris.append([rb, G.time + rng.randf_range(3.0, 5.0), bcol[id], s, T_FENCE])

func _debris_body(p: Vector3, s: Vector3, col: Color, rot: float, center: Vector3, power: float) -> void:
	var rb := RigidBody3D.new()
	rb.collision_layer = 2
	rb.collision_mask = 1 | 2
	rb.mass = 20.0
	var cs := CollisionShape3D.new()
	var bs := BoxShape3D.new()
	bs.size = s * 0.9
	cs.shape = bs
	rb.add_child(cs)
	var m := MeshInstance3D.new()
	m.mesh = chunks[rng.randi() % chunks.size()]
	m.scale = s * 0.97
	m.material_override = _color_mat(col, T_BOX)
	rb.add_child(m)
	add_child(rb)
	rb.global_transform = Transform3D(Basis(Vector3.UP, rot), p)
	var away := p - center
	away.y = 0
	var dl := away.length()
	var dir := away / dl if dl > 0.01 else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
	var k := clampf(1.0 - dl / 6.0, 0.25, 1.0)
	rb.linear_velocity = dir * rng.randf_range(2.0, 7.5) * power * k + Vector3(0, rng.randf_range(1.5, 6.0) * power * k, 0)
	rb.angular_velocity = Vector3(rng.randf_range(-8, 8), rng.randf_range(-8, 8), rng.randf_range(-8, 8)) * minf(power, 1.5)
	debris.append([rb, G.time + rng.randf_range(3.0, 5.0), col, s, T_BOX])

func _rub_mm(p: Vector3, v: int) -> Array:
	var k := Vector3i(int(floor(p.x / RUB_REGION)), int(floor(p.z / RUB_REGION)), v)
	if not rub_mm.has(k):
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = chunks[v]
		mm.instance_count = RUB_PER_REGION
		mm.visible_instance_count = 0
		var rmi := MultiMeshInstance3D.new()
		rmi.multimesh = mm
		rmi.material_override = Mats.masonry()
		add_child(rmi)
		rub_mm[k] = [mm, 0]
		if rubble == null:
			rubble = mm
	return rub_mm[k]

func _add_rubble(p: Vector3, s: Vector3, col: Color, xf := Transform3D()) -> void:
	var v := rng.randi() % chunks.size()
	var e: Array = _rub_mm(xf.origin if xf != Transform3D() else p, v)
	var mm: MultiMesh = e[0]
	var i: int = int(e[1]) % RUB_PER_REGION
	if xf == Transform3D():
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.5, 0.5)) * Basis(Vector3.FORWARD, rng.randf_range(-0.4, 0.4))
		var gy: float = G.terrain.ground_h(p) if G.terrain else 0.0
		xf = Transform3D(b.scaled(s), Vector3(p.x, maxf(p.y, gy) + s.y * 0.22, p.z))
	mm.set_instance_transform(i, xf)
	var c := col.darkened(rng.randf_range(0.04, 0.2))
	c.a = col.a
	mm.set_instance_color(i, c)
	e[1] = int(e[1]) + 1
	rubble_n += 1
	mm.visible_instance_count = mini(int(e[1]), RUB_PER_REGION)

func _process(_dt: float) -> void:
	_roof_cut(_dt)
	if not collapsing.is_empty():
		_collapse_tick(_dt)
	var i := debris.size() - 1
	while i >= 0:
		var d: Array = debris[i]
		var rb: RigidBody3D = d[0]
		if not is_instance_valid(rb):
			debris.remove_at(i)
		elif G.time > d[1] and (rb.sleeping or rb.linear_velocity.length() < 0.4 or G.time > d[1] + 3.0):
			var xf := rb.global_transform
			var s: Vector3 = d[3]
			if d[4] != T_FENCE and xf.origin.y > -1.0:
				_add_rubble(xf.origin, s, d[2], Transform3D(xf.basis.orthonormalized().scaled(s * 0.97), Vector3(xf.origin.x, maxf(xf.origin.y, s.y * 0.2), xf.origin.z)))
			rb.queue_free()
			debris.remove_at(i)
		i -= 1

func _collapse_tick(dt: float) -> void:
	var i := collapsing.size() - 1
	while i >= 0:
		var e: Dictionary = collapsing[i]
		e["t"] = float(e["t"]) + dt
		var t: float = e["t"]
		var h: Dictionary = houses[e["h"]]
		var c: Vector3 = h["center"]
		var sz: Vector2 = h["size"]
		var top: float = h["top"]
		var roof: Node3D = e["roof"]
		# çatı 1,3 sn'de eğilerek çöker; yere değince kırık levhalara ayrılır
		if roof != null and is_instance_valid(roof) and roof.visible:
			var k := clampf(t / 1.3, 0.0, 1.0)
			roof.position.y = float(e["y0"]) - maxf(top - 0.9, 0.5) * k * k
			roof.basis = Basis(e["ax"], 0.3 * k * k) * (e["b0"] as Basis)
			if k >= 1.0:
				roof.visible = false
				for j in 8:
					var p := c + Vector3(rng.randf_range(-sz.x, sz.x) * 0.38, 1.0, rng.randf_range(-sz.y, sz.y) * 0.38)
					if debris.size() < MAX_DEBRIS:
						_debris_body(p, Vector3(rng.randf_range(0.7, 1.5), 0.2, rng.randf_range(0.6, 1.3)), Color(0.55, 0.36, 0.28, 0.9), rng.randf() * TAU, p + Vector3(0, 2, 0), 0.25)
					else:
						_add_rubble(Vector3(p.x, 0.0, p.z), Vector3(rng.randf_range(0.7, 1.4), 0.2, rng.randf_range(0.6, 1.2)), Color(0.55, 0.36, 0.28, 0.9))
		# duvarlar tepeden aşağı: kesme yüksekliği 2,2 sn'de tepeden 1 m'ye iner; üstündekiler (kalıntı payı hariç) yıkılır
		var cut := lerpf(top, 1.0, clampf(t / 2.2, 0.0, 1.0))
		var kill: Array = []
		var keep: Dictionary = e["keep"]
		for id in e["ids"]:
			if balive[id] == 1 and bpos[id].y > cut and not keep.has(id):
				kill.append(id)
				if kill.size() >= 45:
					break
		if not kill.is_empty():
			_destroy_many(kill, Vector3(c.x, top + 1.0, c.z), 0.22)
		# toz: çöküş boyunca üç dalga
		var dw: int = e["dust"]
		if dw < 3 and t > dw * 0.8:
			e["dust"] = dw + 1
			if G.fx:
				G.fx.dust_burst(c + Vector3(0, maxf(cut, 1.0), 0), maxf(sz.x, sz.y) * (0.5 + dw * 0.25))
		if t > 2.6:
			_rubble_heap(c, sz, e["ids"])
			collapsing.remove_at(i)
		i -= 1

# çöken binanın taban izinde moloz tepesi (ortası yüksek, kenarlara yayılan kırık parça yığını)
func _rubble_heap(c: Vector3, sz: Vector2, ids: Array) -> void:
	var col := Color(0.7, 0.68, 0.64)
	if not ids.is_empty():
		col = bcol[ids[rng.randi() % ids.size()]]
	var R := Vector2(sz.x * 0.55 + 0.6, sz.y * 0.55 + 0.6)
	var n := clampi(int(sz.x * sz.y * 1.6), 30, 160)
	var gy: float = G.terrain.ground_h(c) if G.terrain else 0.0
	# taban: düzensiz moloz tepesi örgüsü (ortası yüksek, kenarda yere iner); üstüne parçalar serpilir
	var mound_h := clampf(minf(sz.x, sz.y) * 0.14, 0.45, 1.3)
	var mi := MeshInstance3D.new()
	mi.mesh = _heap_mesh(R * 1.02, mound_h, col.lerp(Color(0.6, 0.57, 0.52, col.a), 0.35).darkened(0.12))
	mi.material_override = Mats.masonry()
	add_child(mi)
	mi.position = Vector3(c.x, gy - 0.02, c.z)
	for j in n:
		var a := rng.randf() * TAU
		var r := sqrt(rng.randf())
		var off := Vector3(cos(a) * R.x * r, 0, sin(a) * R.y * r)
		var hgt := (1.0 - r * r) * clampf(minf(sz.x, sz.y) * 0.16, 0.4, 1.3)
		var cc := col
		if rng.randf() < 0.18:
			cc = Color(0.55, 0.36, 0.28, col.a)
		elif rng.randf() < 0.15:
			cc = col.darkened(0.35)
		# çoğu küçük kırıntı, arada büyük duvar/döşeme parçası
		var big := rng.randf() < 0.18
		var sc := Vector3(rng.randf_range(0.6, 1.3), rng.randf_range(0.18, 0.4), rng.randf_range(0.5, 1.1)) if big else Vector3(rng.randf_range(0.18, 0.5), rng.randf_range(0.12, 0.3), rng.randf_range(0.16, 0.45))
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.6, 0.6))
		_add_rubble(c + off, sc, cc, Transform3D(b.scaled(sc), Vector3(c.x + off.x, gy + hgt * rng.randf_range(0.6, 1.0), c.z + off.z)))

# moloz tepesi: kutupsal ızgara, yükseklik (1-r²)·h + gürültü; kenarlar toprağa gömülü
func _heap_mesh(R: Vector2, h: float, col: Color) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	st.set_smooth_group(-1)
	var NA := 26
	var NR := 8
	var P := []
	var seed := rng.randf() * 100.0
	for ir in NR + 1:
		var r := (float(ir) + 0.5) / (float(NR) + 0.5)
		var ring := []
		for ia in NA:
			var a := TAU * ia / NA
			var n := sin(a * 3.0 + seed) * 0.12 + sin(a * 7.0 + seed * 1.7) * 0.06 + rng.randf_range(-0.1, 0.1)
			var rr := r * (1.0 + n * 0.5)
			var y := h * (1.0 - r * r) * (0.75 + 0.5 * rng.randf()) - 0.06 * r
			if ir == NR:
				y = -0.05
			ring.append(Vector3(cos(a) * R.x * rr, maxf(y, -0.05), sin(a) * R.y * rr))
		P.append(ring)
	var c0 := Vector3(0, h * 1.05, 0)
	for ia in NA:
		var a: Vector3 = P[0][ia]
		var b: Vector3 = P[0][(ia + 1) % NA]
		for q in [c0, a, b]:
			st.set_color(col.darkened(rng.randf_range(0.0, 0.15)))
			st.add_vertex(q)
	for ir in NR:
		for ia in NA:
			var a: Vector3 = P[ir][ia]
			var b: Vector3 = P[ir][(ia + 1) % NA]
			var cc: Vector3 = P[ir + 1][(ia + 1) % NA]
			var d: Vector3 = P[ir + 1][ia]
			for q in [a, cc, b, a, d, cc]:
				st.set_color(col.darkened(rng.randf_range(0.0, 0.18)))
				st.add_vertex(q)
	st.generate_normals()
	return st.commit()

func _check_house(hh: int) -> void:
	var h: Dictionary = houses[hh]
	if h["collapsed"] or h["total"] == 0:
		return
	if float(h["alive"]) / float(h["total"]) < 0.74:
		h["collapsed"] = true
		var roof: Node3D = h["roof"]
		# kat kat çökme: çatı eğilerek iner, duvarlar tepeden aşağı yıkılır (bir kısmı kırık kalıntı olarak durur),
		# en sonda taban izinde moloz tepesi kalır (bkz. _collapse_tick)
		var ids: Array = []
		var keep := {}
		for w in walls:
			if w["house"] == hh:
				for id in w["blocks"]:
					if balive[id] == 1:
						ids.append(id)
						if rng.randf() < 0.18:
							keep[id] = true
		collapsing.append({"h": hh, "t": 0.0, "roof": roof, "y0": roof.position.y if roof and is_instance_valid(roof) else 0.0,
			"b0": roof.basis if roof and is_instance_valid(roof) else Basis(), "ax": Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized(),
			"ids": ids, "keep": keep, "dust": 0})
		# cephe süsü (balkon, pencere, tabela): yalnız çökünce gizlenir
		var deco = h.get("deco", null)
		if deco != null and is_instance_valid(deco):
			deco.visible = false
		var c: Vector3 = h["center"]
		var sz: Vector2 = h["size"]
		G.fx.dust_burst(c + Vector3(0, 1.5, 0), maxf(sz.x, sz.y) * 0.5)
		Sfx.play3d("collapse", c, 2.0)
		# içerideki askerler enkaz altında kalır
		if h.has("occ"):
			for o in h["occ"].values():
				if o != null and is_instance_valid(o) and o.alive and o.house_id == hh:
					o.house_id = -1
					o.take_damage(randf_range(55.0, 95.0), null, "blast")
