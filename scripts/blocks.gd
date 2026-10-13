class_name Blocks extends Node3D
# Yıkılabilir blok duvar sistemi: parça (chunk) başına MultiMesh, destek zinciri,
# fizik enkazı ve kalıcı moloz.

const CH := 32.0
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
var rubble: MultiMesh
var rubble_n := 0
var _mat_cache := {}
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	rng.seed = 777
	meshes = [bevel_box(0.07), bevel_box(0.42), fence_panel(), bevel_box(0.03)]
	rubble = MultiMesh.new()
	rubble.transform_format = MultiMesh.TRANSFORM_3D
	rubble.use_colors = true
	rubble.mesh = meshes[T_BOX]
	rubble.instance_count = RUBBLE_CAP
	rubble.visible_instance_count = 0
	var rmi := MultiMeshInstance3D.new()
	rmi.multimesh = rubble
	rmi.material_override = Mats.stone()
	add_child(rmi)

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
			return Mats.stone()
		T_FENCE:
			return Mats.vc2()
	return Mats.vc()

func _color_mat(col: Color, t: int) -> Material:
	var q := Color(snappedf(col.r, 0.06), snappedf(col.g, 0.06), snappedf(col.b, 0.06))
	var key := "%s_%d" % [q.to_html(), t]
	if not _mat_cache.has(key):
		var base: StandardMaterial3D = _type_mat(t)
		var m: StandardMaterial3D = base.duplicate()
		m.vertex_color_use_as_albedo = false
		m.albedo_color = q
		_mat_cache[key] = m
	return _mat_cache[key]

# ------------------------------------------------------------ kurulum
func new_wall(house := -1, owner: Object = null) -> int:
	walls.append({"blocks": [], "house": house, "owner": owner})
	return walls.size() - 1

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

func _xform(id: int) -> Transform3D:
	return Transform3D(Basis(Vector3.UP, brot[id]).scaled(bsize[id] * 0.97), bpos[id])

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
			add_block(pos, Vector3(s1 - s0, bh, bt), rot, c, t, w, r, k, solid)
	# pencere çerçeveleri (siyah, görüşü kesmeyen)
	for gp in gaps:
		if gp.size() > 4 and gp[4]:
			var s0: float = gp[0]
			var s1: float = gp[1]
			var ylo := y0 + bh * gp[2]
			var yhi := y0 + bh * (gp[3] + 1)
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
	_pending.clear()
	var cells: Array = []
	for id in bpos.size():
		_register_cells(id, cells)
	G.grid.refresh(cells)
	finalized = true

func _make_mm(ids: Array, t: int) -> MultiMesh:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = meshes[t]
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
		last = mi
	_pending.clear()
	_build_support(from_id)
	var cells: Array = []
	for id in range(from_id, bpos.size()):
		_register_cells(id, cells)
	G.grid.refresh(cells)
	return last

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
		if top > G.grid.hb[ci]:
			G.grid.hb[ci] = top
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
	var changed: Array = []
	for ci in cells:
		var mx := 0.0
		if cell_blocks.has(ci):
			for o in cell_blocks[ci]:
				if balive[o] == 1:
					mx = maxf(mx, bpos[o].y + bsize[o].y * 0.5)
		G.grid.hb[ci] = mx
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

func _spawn_debris(id: int, center: Vector3, power: float) -> void:
	var p := bpos[id]
	var s := bsize[id]
	if debris.size() >= MAX_DEBRIS or s.length() < 0.15:
		_add_rubble(p + Vector3(rng.randf_range(-1.2, 1.2), 0, rng.randf_range(-1.2, 1.2)), s * rng.randf_range(0.7, 0.95), bcol[id])
		return
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
	m.mesh = meshes[btype[id]]
	m.scale = s * 0.97
	m.material_override = _color_mat(bcol[id], btype[id])
	rb.add_child(m)
	add_child(rb)
	rb.global_transform = Transform3D(Basis(Vector3.UP, brot[id]), p)
	var away := p - center
	away.y = 0
	var dl := away.length()
	var dir := away / dl if dl > 0.01 else Vector3(rng.randf_range(-1, 1), 0, rng.randf_range(-1, 1)).normalized()
	var k := clampf(1.0 - dl / 6.0, 0.25, 1.0)
	rb.linear_velocity = dir * rng.randf_range(2.0, 7.5) * power * k + Vector3(0, rng.randf_range(1.5, 6.0) * power * k, 0)
	rb.angular_velocity = Vector3(rng.randf_range(-8, 8), rng.randf_range(-8, 8), rng.randf_range(-8, 8)) * minf(power, 1.5)
	debris.append([rb, G.time + rng.randf_range(3.0, 5.0), bcol[id], s, btype[id]])

func _add_rubble(p: Vector3, s: Vector3, col: Color, xf := Transform3D()) -> void:
	var i := rubble_n % RUBBLE_CAP
	if xf == Transform3D():
		var b := Basis(Vector3.UP, rng.randf() * TAU) * Basis(Vector3.RIGHT, rng.randf_range(-0.4, 0.4))
		xf = Transform3D(b.scaled(s), Vector3(p.x, s.y * 0.35, p.z))
	rubble.set_instance_transform(i, xf)
	rubble.set_instance_color(i, col.darkened(0.08))
	rubble_n += 1
	rubble.visible_instance_count = mini(rubble_n, RUBBLE_CAP)

func _process(_dt: float) -> void:
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

func _check_house(hh: int) -> void:
	var h: Dictionary = houses[hh]
	if h["collapsed"] or h["total"] == 0:
		return
	if float(h["alive"]) / float(h["total"]) < 0.74:
		h["collapsed"] = true
		var roof: Node3D = h["roof"]
		if roof and is_instance_valid(roof):
			roof.visible = false
		# çatı parçaları
		var c: Vector3 = h["center"]
		var sz: Vector2 = h["size"]
		for i in 10:
			var p := c + Vector3(rng.randf_range(-sz.x, sz.x) * 0.4, h["top"], rng.randf_range(-sz.y, sz.y) * 0.4)
			var id := add_block(p, Vector3(rng.randf_range(0.8, 1.8), 0.22, rng.randf_range(0.8, 1.6)), rng.randf() * TAU, Color(0.78, 0.76, 0.72), T_BOX, -1, 0, Grid.K_NONE, false)
			balive[id] = 0
			_pending.clear()
			_spawn_debris(id, p + Vector3(0, 2, 0), 0.4)
		G.fx.dust_burst(c + Vector3(0, 1.5, 0), maxf(sz.x, sz.y) * 0.5)
		Sfx.play3d("collapse", c, 2.0)
