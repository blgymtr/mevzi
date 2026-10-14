class_name Ragdoll extends RefCounted
# Hafif verlet ragdoll: asker gövdesinin eklemlerini noktalarla taşır, zemine (siper/nehir
# yatağı dahil) çarptırır ve sonucu SoldierBody pivotlarına uygular. Silah ayrı düşer.

enum { HIP, NECK, HEAD, SH_R, EL_R, HA_R, SH_L, EL_L, HA_L, HP_R, KN_R, FT_R, HP_L, KN_L, FT_L, W0, W1 }

var b: SoldierBody
var p := PackedVector3Array()
var q := PackedVector3Array()     # önceki konumlar
var cons: Array = []              # [a, b, uzunluk, min_mi]
var t := 0.0
var rest_t := 0.0
var asleep := false
var spine_len := 0.55

func start(body: SoldierBody, vel: Vector3, spin := 0.0) -> void:
	b = body
	var sp := body.spine.global_transform
	var fr := body.fore_r.global_transform
	var fl := body.fore_l.global_transform
	var kr := body.knee_r.global_transform
	var kl := body.knee_l.global_transform
	p.resize(17)
	p[HIP] = body.pelvis.global_position
	p[NECK] = sp * Vector3(0, spine_len, 0)
	p[HEAD] = sp * Vector3(0, 0.78, 0)
	p[SH_R] = body.arm_r.global_position
	p[EL_R] = fr.origin
	p[HA_R] = fr * Vector3(0, -0.3, 0)
	p[SH_L] = body.arm_l.global_position
	p[EL_L] = fl.origin
	p[HA_L] = fl * Vector3(0, -0.3, 0)
	p[HP_R] = body.leg_r.global_position
	p[KN_R] = kr.origin
	p[FT_R] = kr * Vector3(0, -0.46, 0)
	p[HP_L] = body.leg_l.global_position
	p[KN_L] = kl.origin
	p[FT_L] = kl * Vector3(0, -0.46, 0)
	var wt := body.weapon.global_transform
	p[W0] = wt.origin
	p[W1] = wt * Vector3(0, 0, -0.7)
	# uzuvların önce yere değmesi için rastgele küçük sapmalar
	q = p.duplicate()
	var dt := 1.0 / 60.0
	var up_axis := (p[NECK] - p[HIP]).normalized()
	var spin_dir := up_axis.cross(Vector3.UP)
	spin_dir = spin_dir.normalized() if spin_dir.length() > 0.01 else Vector3.ZERO
	for i in p.size():
		var v := vel * randf_range(0.85, 1.15)
		if spin != 0.0:
			v += spin_dir * spin * (p[i] - p[HIP]).length() * 0.6
		if i == HEAD or i == NECK:
			v *= 1.25
		if i >= W0:
			v = vel * 1.3 + Vector3(randf_range(-1.5, 1.5), randf_range(0.5, 2.0), randf_range(-1.5, 1.5))
		q[i] = p[i] - v * dt
	var bones := [[HIP, NECK], [NECK, HEAD], [SH_R, SH_L], [HP_R, HP_L], [HIP, SH_R], [HIP, SH_L], [NECK, SH_R], [NECK, SH_L],
		[HP_R, NECK], [HP_L, NECK], [HIP, HP_R], [HIP, HP_L], [SH_R, HP_R], [SH_L, HP_L], [HEAD, SH_R], [HEAD, SH_L],
		[SH_R, EL_R], [EL_R, HA_R], [SH_L, EL_L], [EL_L, HA_L], [HP_R, KN_R], [KN_R, FT_R], [HP_L, KN_L], [KN_L, FT_L], [W0, W1]]
	for bn in bones:
		cons.append([bn[0], bn[1], p[bn[0]].distance_to(p[bn[1]]), false])
	# eklem sınırı yerine: dirsek / diz tamamen katlanmasın
	cons.append([SH_R, HA_R, 0.32, true])
	cons.append([SH_L, HA_L, 0.32, true])
	cons.append([HP_R, FT_R, 0.5, true])
	cons.append([HP_L, FT_L, 0.5, true])
	cons.append([HEAD, HIP, 0.7, true])
	cons.append([KN_R, KN_L, 0.12, true])

func push(v: Vector3) -> void:
	# patlama: uyuyan ragdoll'u yeniden savur
	asleep = false
	rest_t = 0.0
	t = minf(t, 1.0)
	var dt := 1.0 / 60.0
	for i in p.size():
		q[i] = p[i] - v * randf_range(0.8, 1.2) * dt

func step(dt: float) -> bool:
	# true: hâlâ hareketli
	if asleep:
		return false
	dt = minf(dt, 1.0 / 30.0)
	t += dt
	var g := Vector3(0, -14.0 * dt * dt, 0)
	var maxv := 0.0
	for i in p.size():
		var cur := p[i]
		var v := (cur - q[i]) * 0.995
		q[i] = cur
		p[i] = cur + v + g
		maxv = maxf(maxv, v.length() / dt)
	for _it in 6:
		for c in cons:
			var a: int = c[0]
			var bb: int = c[1]
			var d := p[bb] - p[a]
			var L := d.length()
			if L < 0.0001:
				continue
			var want: float = c[2]
			if c[3] and L >= want:
				continue
			var k := (L - want) / L * 0.5
			p[a] += d * k
			p[bb] -= d * k
		_collide()
	if maxv < 0.25 and t > 0.6:
		rest_t += dt
	else:
		rest_t = 0.0
	if rest_t > 0.4 or t > 6.0:
		asleep = true
	_apply()
	return not asleep

func _collide() -> void:
	for i in p.size():
		var x := p[i]
		var r := 0.1 if i != HEAD else 0.12
		if i == HIP or i == NECK:
			r = 0.13
		var gh := G.terrain.ground_h(x) if G.terrain else 0.0
		if x.y < gh + r:
			x.y = gh + r
			# sürtünme: yatay hareketi kes
			var pv := q[i]
			q[i] = Vector3(lerpf(pv.x, x.x, 0.55), pv.y, lerpf(pv.z, x.z, 0.55))
		# duvar bloklarına girmesin
		var hv := G.grid.height_at(x) if G.grid else 0.0
		if hv > 0.3 and x.y < hv and x.y > gh + 0.05:
			var o := q[i]
			x.x = o.x
			x.z = o.z
		p[i] = x

func _basis(y_axis: Vector3, x_ref: Vector3) -> Basis:
	var Y := y_axis.normalized()
	var Z := x_ref.cross(Y)
	if Z.length() < 0.001:
		Z = Vector3.FORWARD.cross(Y)
	Z = Z.normalized()
	var X := Y.cross(Z).normalized()
	return Basis(X, Y, Z)

func _apply() -> void:
	var hx := p[HP_L] - p[HP_R]
	var sx := p[SH_L] - p[SH_R]
	var up := p[NECK] - p[HIP]
	var pb := _basis(up, hx)
	b.pelvis.global_transform = Transform3D(pb, p[HIP])
	var sb := _basis(up, sx)
	b.spine.global_transform = Transform3D(sb, p[HIP])
	b.arm_r.global_transform = Transform3D(_basis(p[SH_R] - p[EL_R], sb.x), p[SH_R])
	b.fore_r.global_transform = Transform3D(_basis(p[EL_R] - p[HA_R], sb.x), p[EL_R])
	b.arm_l.global_transform = Transform3D(_basis(p[SH_L] - p[EL_L], sb.x), p[SH_L])
	b.fore_l.global_transform = Transform3D(_basis(p[EL_L] - p[HA_L], sb.x), p[EL_L])
	b.leg_r.global_transform = Transform3D(_basis(p[HP_R] - p[KN_R], pb.x), p[HP_R])
	b.knee_r.global_transform = Transform3D(_basis(p[KN_R] - p[FT_R], pb.x), p[KN_R])
	b.leg_l.global_transform = Transform3D(_basis(p[HP_L] - p[KN_L], pb.x), p[HP_L])
	b.knee_l.global_transform = Transform3D(_basis(p[KN_L] - p[FT_L], pb.x), p[KN_L])
	var wd := (p[W1] - p[W0]).normalized()
	var wz := -wd
	var wx := Vector3.UP.cross(wz)
	if wx.length() < 0.01:
		wx = Vector3.RIGHT
	wx = wx.normalized()
	var wy := wz.cross(wx).normalized()
	b.weapon.global_transform = Transform3D(Basis(wx, wy, wz), p[W0])

func center() -> Vector3:
	return p[HIP]
