class_name FogOfWar extends Node3D
# Görsel savaş sisi (roadmap 43): izlenen tarafın birlik/yapılarının GÖRÜŞ ÇOKGENLERİ iki SubViewport'a
# çizilir — "vis" her kare temizlenir (şu an görülen), "exp" hiç temizlenmez (keşfedilmiş birikimi).
# Çokgen: gözcünün göz noktasından ışınlar; orman, bina, yüksek duvar görüşü keser (orman kenarının ardı
# karanlık kalır). Yarıçap = birimin optiğiyle açıktaki ayakta piyadeyi seçebildiği mesafe. Kenarlar
# yumuşak geçişli (dış halka saydamlaşır); piyade timi tek çokgen (ağırlık merkezi), araç ve yapı ayrı.
# Önbellek: birim yerinden oynamadıkça çokgen yeniden hesaplanmaz (kare başına sınırlı hesap).
# Tam ekran sis katmanı (fow.gdshader) iki dokuyu dünya konumuna göre okur.

var vis_vp: SubViewport
var exp_vp: SubViewport
var quad: MeshInstance3D
var mat: ShaderMaterial
var N := 256
var _cache := {}          # sahip kimliği -> {"p": Vector3, "r": float, "t": float, "pts": PackedVector2Array}
var _budget := 0

class Painter extends Node2D:
	var fow: FogOfWar
	func _draw() -> void:
		var vt := G.view_team()
		if vt < 0:
			return
		var k := float(fow.N) / G.MAP
		for o in fow.owners(vt):
			var pts: PackedVector2Array = fow.poly_of(o)
			if pts.size() < 3:
				continue
			fow.draw_poly(self, pts, k)

func _ready() -> void:
	# 8 km'de 2048 piksel (4 m/piksel), küçük haritada 1 m/piksel; doğrusal süzme + yumuşak kenar
	N = clampi(int(G.MAP), 256, 2048) if G.MAP <= 2048.0 else 2048
	vis_vp = _make_vp(SubViewport.CLEAR_MODE_ALWAYS)
	exp_vp = _make_vp(SubViewport.CLEAR_MODE_ONCE)
	quad = MeshInstance3D.new()
	var qm := QuadMesh.new()
	qm.size = Vector2(2, 2)
	quad.mesh = qm
	quad.extra_cull_margin = 16384.0
	quad.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	mat = ShaderMaterial.new()
	mat.shader = preload("res://shaders/fow.gdshader")
	mat.render_priority = 120
	mat.set_shader_parameter("vis_tex", vis_vp.get_texture())
	mat.set_shader_parameter("exp_tex", exp_vp.get_texture())
	mat.set_shader_parameter("map_size", G.MAP)
	quad.material_override = mat
	add_child(quad)
	RenderingServer.global_shader_parameter_set("fow_vis", vis_vp.get_texture())
	RenderingServer.global_shader_parameter_set("fow_exp", exp_vp.get_texture())

func _make_vp(clear: int) -> SubViewport:
	var vp := SubViewport.new()
	vp.size = Vector2i(N, N)
	vp.disable_3d = true
	vp.transparent_bg = clear != SubViewport.CLEAR_MODE_ALWAYS
	vp.render_target_clear_mode = clear
	vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	add_child(vp)
	var bg := ColorRect.new()
	bg.color = Color(0, 0, 0)
	bg.size = Vector2(N, N)
	if clear == SubViewport.CLEAR_MODE_ALWAYS:
		vp.add_child(bg)
	var p := Painter.new()
	p.fow = self
	vp.add_child(p)
	return vp

# görüş sahipleri: piyade timi tek gözcü (lider / ilk canlı üye), timsiz asker, araç, yapı
func owners(vt: int) -> Array:
	var out: Array = []
	var done := {}
	for sq in G.squads:
		if sq == null or sq.team != vt:
			continue
		var lead: Soldier = null
		for s in sq.members:
			if is_instance_valid(s) and s.alive and not (s.state in ["aboard", "hospital", "prisoner", "surrender"]):
				done[s] = true
				if lead == null or s.role == "leader" or (s.role == "atgm" and lead.role != "leader"):
					lead = s
		if lead != null:
			out.append(lead)
	for u in G.units:
		if not is_instance_valid(u) or u.team != vt or not u.alive or done.has(u):
			continue
		if u is Soldier and (u.state == "aboard" or u.state == "hospital"):
			continue
		out.append(u)
	return out

# önbellekli görüş çokgeni (dünya xz); sahibi kıpırdamadıkça yeniden hesaplanmaz
func poly_of(o) -> PackedVector2Array:
	var id: int = o.get_instance_id()
	var r: float = o.sight * (G.weather.sight_mult() if G.weather != null and is_instance_valid(G.weather) and not (o is Building) else 1.0)
	var c = _cache.get(id)
	var p: Vector3 = o.position
	if c != null:
		var moved: float = Vector2(p.x - c["p"].x, p.z - c["p"].z).length()
		var fresh: bool = moved < maxf(2.0, r * 0.03) and absf(r - float(c["r"])) < r * 0.05 and G.time - float(c["t"]) < 4.0
		if fresh or _budget <= 0:
			return c["pts"]
	_budget -= 1
	var pts := _compute(o, r)
	_cache[id] = {"p": p, "r": r, "t": G.time, "pts": pts}
	return pts

# ışın sayısı yarıçapla artar; havadaki gözcü (İHA, helikopter) engel görmez
func _compute(o, r: float) -> PackedVector2Array:
	var eye: Vector3 = o.eye_point()
	var air: bool = o is Vehicle and o.is_air()
	var n := clampi(40 + int(r / 15.0), 40, 96)
	var pts := PackedVector2Array()
	var block_h := maxf(1.7, minf(eye.y, 2.4))
	for i in n:
		var a := float(i) / n * TAU
		var d := r if air else _ray(eye, Vector2(cos(a), sin(a)), r, block_h, float(o.los_skip()) + 0.5)
		pts.append(Vector2(eye.x + cos(a) * d, eye.z + sin(a) * d))
	return pts

# ışında ilk görüş kesen engele kadar mesafe: büyük haritada iri ızgara (8 m), küçükte ince ızgara
func _ray(eye: Vector3, dir: Vector2, r: float, block_h: float, skip: float) -> float:
	var gr: Grid = G.grid
	if G.MAP >= 1024.0:
		var step := Grid.CC * 0.75
		var d := skip
		while d < r:
			var x := int((eye.x + dir.x * d) / Grid.CC)
			var z := int((eye.z + dir.y * d) / Grid.CC)
			if x < 0 or z < 0 or x >= Grid.NCC or z >= Grid.NCC:
				return d
			if gr.hm[z * Grid.NCC + x] > block_h:
				# iri hücrede engel: ince ızgarada kesin noktayı bul
				var d2 := d - step
				while d2 < d + step:
					var fx := int((eye.x + dir.x * d2) / Grid.CS)
					var fz := int((eye.z + dir.y * d2) / Grid.CS)
					if fx >= 0 and fz >= 0 and fx < Grid.N and fz < Grid.N and gr.h[fz * Grid.N + fx] > block_h:
						return maxf(d2, skip)
					d2 += Grid.CS
			d += step
		return r
	var st := maxf(Grid.CS, 0.5)
	var dd := skip
	while dd < r:
		var fx2 := int((eye.x + dir.x * dd) / Grid.CS)
		var fz2 := int((eye.z + dir.y * dd) / Grid.CS)
		if fx2 < 0 or fz2 < 0 or fx2 >= Grid.N or fz2 >= Grid.N:
			return dd
		if gr.h[fz2 * Grid.N + fx2] > block_h:
			return dd
		dd += st
	return r

# çokgen + yumuşak dış halka (çokgenin ağırlık merkezinden dışa %8 genişler, saydamlaşır)
func draw_poly(ci: CanvasItem, pts: PackedVector2Array, k: float) -> void:
	var n := pts.size()
	var c := Vector2.ZERO
	for q in pts:
		c += q
	c /= n
	var inner := PackedVector2Array()
	inner.resize(n)
	for i in n:
		inner[i] = pts[i] * k
	ci.draw_colored_polygon(inner, Color(1, 1, 1, 1))
	var outer := PackedVector2Array()
	outer.resize(n)
	for i in n:
		outer[i] = (c + (pts[i] - c) * 1.08) * k
	for i in n:
		var j := (i + 1) % n
		ci.draw_polygon(PackedVector2Array([inner[i], outer[i], outer[j], inner[j]]),
			PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0), Color(1, 1, 1, 0), Color(1, 1, 1, 1)]))

var _t := 0.0
func _process(dt: float) -> void:
	quad.visible = G.running and G.view_team() >= 0 and not G.game_over and not G.sandbox
	RenderingServer.global_shader_parameter_set("fow_on", 1.0 if quad.visible else 0.0)
	if not quad.visible:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.1
	_budget = 10
	for vp in [vis_vp, exp_vp]:
		for ch in vp.get_children():
			if ch is Painter:
				ch.queue_redraw()
