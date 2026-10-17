class_name FogOfWar extends Node3D
# Görsel savaş sisi (roadmap 43): izlenen tarafın birlik/yapılarının GÖRÜŞ ÇOKGENLERİ iki SubViewport'a
# çizilir — "vis" her kare temizlenir (şu an görülen), "exp" hiç temizlenmez (keşfedilmiş birikimi).
# Çokgen: gözcünün göz noktasından ışınlar; orman, bina, yüksek duvar görüşü keser (orman kenarının ardı
# karanlık kalır). Yarıçap = birimin optiğiyle açıktaki ayakta piyadeyi seçebildiği mesafe. Her birim kendi
# çokgeni (roadmap 110: tim tek lider çokgeniydi). Işın mesafeleri medyan + bulanıklaştırmayla yumuşatılıp
# açısal olarak 4 kat sıklaştırılır (köşeli "geometrik açı" kenarlar yerine yuvarlak); tek ağaç görüşü kesmez,
# ancak sık orman (ışın boyunca ~4 m yaprak) keser. Kenarda gözcüden ölçülen sabit genişlikli yumuşak halka.
# Önbellek: birim yerinden oynamadıkça çokgen yeniden hesaplanmaz (kare başına sınırlı hesap).
# Tam ekran sis katmanı (fow.gdshader) iki dokuyu dünya konumuna göre okur.

const FOW_LAYER := 1 << 19

var vis_vp: SubViewport
var exp_vp: SubViewport
var quad: MeshInstance3D
var mat: ShaderMaterial
var N := 256
var _cache := {}          # sahip kimliği -> {"p": Vector3, "r": float, "t": float, "pts": PackedVector2Array, "c": Vector2}
var _budget := 0
const PER_UNIT_MAX := 120        # takımda bundan çok asker varsa tim tek çokgene döner (başarım)
const FOLIAGE_BLOCK := 4.0       # ışın boyunca bu kadar metre yaprak görüşü keser
const UPSAMPLE := 4

class Painter extends Node2D:
	var fow: FogOfWar
	func _draw() -> void:
		var vt := G.view_team()
		if vt < 0:
			return
		var k := float(fow.N) / G.MAP
		var rid := get_canvas_item()
		for o in fow.owners(vt):
			var pts: PackedVector2Array = fow.poly_of(o)
			if pts.size() < 3:
				continue
			# (154) önbellekli üçgen dizisi, gözcü başına tek çizim çağrısı
			var tri: Array = fow.tris_of(o, pts, k)
			RenderingServer.canvas_item_add_triangle_array(rid, tri[0], tri[1], tri[2])

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
	# kendi katmanında: mini harita için alınan kuşbakışı görüntüye girmez (Hud.Radar._capture)
	quad.layers = FOW_LAYER
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

# görüş sahipleri: her birim kendi gözcüsü; takımda çok asker varsa (büyük muharebe) tim tek gözcü
# (lider / ilk canlı üye) — başarım
func owners(vt: int) -> Array:
	var out: Array = []
	var done := {}
	var n_sol := 0
	for u in G.units:
		if is_instance_valid(u) and u is Soldier and u.team == vt and u.alive:
			n_sol += 1
	if n_sol > PER_UNIT_MAX:
		return _owners_merged(vt)
	for u in G.units:
		if not is_instance_valid(u) or u.team != vt or not u.alive:
			continue
		if u is Soldier and (u.state in ["aboard", "hospital", "prisoner", "surrender"]):
			continue
		out.append(u)
	return out

func _owners_merged(vt: int) -> Array:
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
	var eye: Vector3 = o.eye_point()
	var pts := _compute(o, r)
	_cache[id] = {"p": p, "r": r, "t": G.time, "pts": pts, "c": Vector2(eye.x, eye.z)}
	return pts

func center_of(o) -> Vector2:
	var c = _cache.get(o.get_instance_id())
	return c["c"] if c != null else Vector2(o.position.x, o.position.z)

# kenar yumuşaklığı: yarıçapın ~%12'si, 4–20 m (gözcüden ölçülür)
func feather_of(o) -> float:
	var c = _cache.get(o.get_instance_id())
	var r: float = float(c["r"]) if c != null else 30.0
	return clampf(r * 0.12, 4.0, 20.0)

# ışın sayısı yarıçapla artar; havadaki gözcü (İHA, helikopter) engel görmez. Mesafeler yumuşatılır ve açısal
# olarak sıklaştırılır (köşesiz kenar)
func _compute(o, r: float) -> PackedVector2Array:
	var eye: Vector3 = o.eye_point()
	var air: bool = o is Vehicle and o.is_air()
	var n := clampi(48 + int(r / 6.0), 48, 120)
	var block_h := maxf(1.7, minf(eye.y, 2.4))
	var raw := PackedFloat32Array()
	raw.resize(n)
	for i in n:
		var a := float(i) / n * TAU
		raw[i] = r if air else _ray(eye, Vector2(cos(a), sin(a)), r, block_h, float(o.los_skip()) + 0.5)
	# 3'lü medyan: tek ışınlık sivri çıkıntı / çentik (ağaç arası boşluk, direk) silinir
	var med := PackedFloat32Array()
	med.resize(n)
	for i in n:
		var a0 := raw[(i - 1 + n) % n]
		var a1 := raw[i]
		var a2 := raw[(i + 1) % n]
		med[i] = maxf(minf(a0, a1), minf(maxf(a0, a1), a2))
	# hafif bulanıklaştırma (0,25 · 0,5 · 0,25); gözcüye en az ham mesafenin yarısı kadar görüş kalır
	var sm := PackedFloat32Array()
	sm.resize(n)
	for i in n:
		sm[i] = med[(i - 1 + n) % n] * 0.25 + med[i] * 0.5 + med[(i + 1) % n] * 0.25
	# açısal sıklaştırma: kübik (Catmull-Rom) ara değerleme
	var pts := PackedVector2Array()
	var m := n * UPSAMPLE
	for j in m:
		var t := float(j) / UPSAMPLE
		var i1 := int(t)
		var f := t - i1
		var p0 := sm[(i1 - 1 + n) % n]
		var p1 := sm[i1 % n]
		var p2 := sm[(i1 + 1) % n]
		var p3 := sm[(i1 + 2) % n]
		var d := 0.5 * ((2.0 * p1) + (-p0 + p2) * f + (2.0 * p0 - 5.0 * p1 + 4.0 * p2 - p3) * f * f + (-p0 + 3.0 * p1 - 3.0 * p2 + p3) * f * f * f)
		d = clampf(d, 0.5, r)
		var a := float(j) / m * TAU
		pts.append(Vector2(eye.x + cos(a) * d, eye.z + sin(a) * d))
	return pts

# ışında ilk görüş kesen engele kadar mesafe: büyük haritada iri ızgara (8 m), küçükte ince ızgara.
# Ağaç hücresi tek başına kesmez: ışın boyunca toplanan yaprak FOLIAGE_BLOCK'u aşınca keser (sık orman)
func _ray(eye: Vector3, dir: Vector2, r: float, block_h: float, skip: float) -> float:
	var gr: Grid = G.grid
	var leaf := 0.0
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
				var d2 := maxf(d - step, skip)
				while d2 < d + step and d2 < r:
					var fx := int((eye.x + dir.x * d2) / Grid.CS)
					var fz := int((eye.z + dir.y * d2) / Grid.CS)
					if fx >= 0 and fz >= 0 and fx < Grid.N and fz < Grid.N:
						var fi := fz * Grid.N + fx
						if gr.h[fi] > block_h:
							if gr.kind[fi] != Grid.K_TREE:
								return maxf(d2, skip)
							leaf += Grid.CS
							if leaf >= FOLIAGE_BLOCK:
								return maxf(d2, skip)
					d2 += Grid.CS
				d = d2
				continue
			d += step
		return r
	var st := maxf(Grid.CS, 0.5)
	var dd := skip
	while dd < r:
		var fx2 := int((eye.x + dir.x * dd) / Grid.CS)
		var fz2 := int((eye.z + dir.y * dd) / Grid.CS)
		if fx2 < 0 or fz2 < 0 or fx2 >= Grid.N or fz2 >= Grid.N:
			return dd
		var fi2 := fz2 * Grid.N + fx2
		if gr.h[fi2] > block_h:
			if gr.kind[fi2] != Grid.K_TREE:
				return dd
			leaf += st
			if leaf >= FOLIAGE_BLOCK:
				return dd
		dd += st
	return r

# (154) çokgen + yumuşak halka tek üçgen dizisi: çokgen gözcüden ışınla kurulduğu için göze göre yıldız
# biçimli → gözden yelpaze üçgenleme doğrudur. Eskiden her çizimde içbükey çokgen genel üçgenlemeyle
# (draw_colored_polygon, 200–480 köşe) ve halka yüzlerce ayrı draw_polygon çağrısıyla çiziliyordu; büyük
# muharebede (~80 gözcü × 2 doku, saniyede 10 kez) kare süresinin %80'i buydu (153 birlikte 355 → 60 ms).
# Dizi çokgenle birlikte önbelleklenir (çokgen yenilenince yeniden kurulur).
func tris_of(o, pts: PackedVector2Array, k: float) -> Array:
	var id: int = o.get_instance_id()
	var c = _cache.get(id)
	if c != null and c.has("tri") and c["tri_pts"] == pts.size() and c["tri_k"] == k and (c["tri"] as Array).size() == 3 and c.get("tri_src") == c["t"]:
		return c["tri"]
	var ctr: Vector2 = center_of(o)
	var fe: float = feather_of(o)
	var n := pts.size()
	var P := PackedVector2Array()
	P.resize(1 + n * 2)
	var C := PackedColorArray()
	C.resize(1 + n * 2)
	P[0] = ctr * k
	C[0] = Color(1, 1, 1, 1)
	for i in n:
		var dv := pts[i] - ctr
		var L := dv.length()
		P[1 + i] = pts[i] * k
		C[1 + i] = Color(1, 1, 1, 1)
		P[1 + n + i] = (pts[i] + (dv / maxf(L, 0.01)) * minf(fe, L * 0.5 + 1.0)) * k
		C[1 + n + i] = Color(1, 1, 1, 0)
	var I := PackedInt32Array()
	I.resize(n * 9)
	for i in n:
		var j := (i + 1) % n
		var b := i * 9
		I[b] = 0
		I[b + 1] = 1 + i
		I[b + 2] = 1 + j
		I[b + 3] = 1 + i
		I[b + 4] = 1 + n + i
		I[b + 5] = 1 + n + j
		I[b + 6] = 1 + i
		I[b + 7] = 1 + n + j
		I[b + 8] = 1 + j
	var tri := [I, P, C]
	if c != null:
		c["tri"] = tri
		c["tri_pts"] = n
		c["tri_k"] = k
		c["tri_src"] = c["t"]
	return tri

# çokgen + yumuşak dış halka: gözcüden dışa sabit genişlikte (feather m) saydamlaşır (eski yol, yedek)
func draw_poly(ci: CanvasItem, pts: PackedVector2Array, k: float, c: Vector2, feather: float) -> void:
	var n := pts.size()
	var inner := PackedVector2Array()
	inner.resize(n)
	for i in n:
		inner[i] = pts[i] * k
	ci.draw_colored_polygon(inner, Color(1, 1, 1, 1))
	var outer := PackedVector2Array()
	outer.resize(n)
	for i in n:
		var dv := pts[i] - c
		var L := dv.length()
		outer[i] = (pts[i] + (dv / maxf(L, 0.01)) * minf(feather, L * 0.5 + 1.0)) * k
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
