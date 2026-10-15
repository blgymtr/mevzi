class_name TacIcons extends Control
# Stratejik görüş simgeleri (roadmap 21/53): kamera uzaklaştıkça (≥ 160 m görüş) birlikler NATO
# APP-6 benzeri sembollerle gösterilir — dost mavi dikdörtgen, düşman kırmızı eşkenar dörtgen; içte tür
# işareti (piyade X, zırh oval, mekanize X+oval, topçu nokta, tanksavar Λ, hava savunma kubbe, helikopter
# papyon, İHA ok ucu, ikmal çizgi, sıhhiye artı, istihkâm köprü). Piyade timi tek simge (ağırlık merkezi),
# altında can çubuğu. Hedef bölgeleri harf ve sahip rengiyle. Simgeye tıklamak birliği/timi seçer.

const START := 160.0     # bu görüşten sonra belirmeye başlar
const FULL := 260.0
const FRIEND := Color(0.36, 0.66, 1.0)
const FOE := Color(1.0, 0.33, 0.26)
const NEUTRAL := Color(0.86, 0.86, 0.82)

var _alpha := 0.0
var _hits: Array = []     # [ekran konumu, birim] — tıklama için

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	set_anchors_preset(Control.PRESET_FULL_RECT)

func _process(_dt: float) -> void:
	var a := 0.0
	if G.cam != null and G.world != null and is_instance_valid(G.world):
		a = clampf((G.cam.size - START) / (FULL - START), 0.0, 1.0)
	if a != _alpha or a > 0.0:
		_alpha = a
		queue_redraw()

func active() -> bool:
	return _alpha > 0.35

# tıklanan simgenin birimi (yoksa null); tim simgesi timin ilk canlı askerini verir
func pick(sp: Vector2) -> Unit:
	if not active():
		return null
	var best: Unit = null
	var bd := 15.0
	for h in _hits:
		var d: float = (h[0] as Vector2).distance_to(sp)
		if d < bd:
			bd = d
			best = h[1]
	return best

func _viewer() -> int:
	return G.player_team if not G.spectate else 0

func _draw() -> void:
	_hits.clear()
	if _alpha <= 0.0 or G.cam == null:
		return
	var vt := G.view_team()
	var me := _viewer()
	var font: Font = G.hud.font_b if G.hud != null and G.hud.font_b != null else ThemeDB.fallback_font
	var vs := get_viewport_rect().size
	# hedef bölgeleri
	if G.modes != null and is_instance_valid(G.modes):
		var px_per_m: float = vs.y / G.cam.size
		for z in G.modes.zones:
			var sp := G.cam.screen(z["p"])
			var r := maxf(10.0, float(G.modes.zone_r) * px_per_m)
			var col := NEUTRAL if int(z["owner"]) < 0 else (FRIEND if int(z["owner"]) == me else FOE)
			col.a = _alpha
			draw_arc(sp, r, 0.0, TAU, 32, col, 2.0, true)
			var c2 := col
			c2.a *= 0.18
			draw_circle(sp, r, c2)
			draw_string(font, sp + Vector2(-6, 7), String(z["name"]), HORIZONTAL_ALIGNMENT_LEFT, -1, 20, col)
	# piyade timleri: tek simge
	var done := {}
	for sq in G.squads:
		if sq == null or sq.members.is_empty():
			continue
		var c := Vector3.ZERO
		var n := 0
		var hp := 0.0
		var hpm := 0.0
		var lead: Unit = null
		var roles := {}
		for s in sq.members:
			if not is_instance_valid(s) or not s.alive or s.state in ["aboard", "hospital"]:
				continue
			if vt >= 0 and s.team != vt and not s.visible:
				continue
			c += s.position
			n += 1
			hp += s.hp
			hpm += s.max_hp
			roles[s.role] = int(roles.get(s.role, 0)) + 1
			if lead == null:
				lead = s
			done[s] = true
		if n == 0:
			continue
		c /= n
		var sp2 := G.cam.screen(c + Vector3(0, 1.0, 0))
		if not _on(sp2, vs):
			continue
		var sym := _inf_sym(roles)
		_icon(sp2, lead.team == me, sym, clampf(hp / maxf(hpm, 1.0), 0.0, 1.0), _selected(sq.members), str(n) if n > 1 else "", font)
		_hits.append([sp2, lead])
	for u in G.units:
		if not is_instance_valid(u) or not u.alive or done.has(u):
			continue
		if vt >= 0 and u.team != vt and not u.visible:
			continue
		if u.team < 0:
			continue
		var sym := ""
		var hpf := 1.0
		if u is Vehicle:
			sym = _veh_sym(u.vtype)
			hpf = clampf(u.hp / maxf(u.max_hp, 1.0), 0.0, 1.0)
		elif u is Building:
			if not u.btype in ["hq", "barracks", "factory", "helipad", "fob", "hospital"]:
				continue
			sym = "base"
		elif u is Soldier:
			if u.state in ["aboard", "hospital"]:
				continue
			sym = "inf_one"
		else:
			continue
		var sp3 := G.cam.screen(u.position + Vector3(0, 1.0, 0))
		if not _on(sp3, vs):
			continue
		_icon(sp3, u.team == me, sym, hpf, G.player != null and G.player.selected.has(u), "", font)
		_hits.append([sp3, u])

func _on(sp: Vector2, vs: Vector2) -> bool:
	return sp.x > -30 and sp.y > -30 and sp.x < vs.x + 30 and sp.y < vs.y + 30

func _selected(members: Array) -> bool:
	if G.player == null:
		return false
	for s in members:
		if G.player.selected.has(s):
			return true
	return false

func _inf_sym(roles: Dictionary) -> String:
	var best := "rifle"
	var bn := 0
	for r in roles:
		var k := int(roles[r]) * (3 if r in ["at", "atgm", "mortar", "sniper", "drone", "engineer", "medic", "mg"] else 1)
		if k > bn:
			bn = k
			best = r
	match best:
		"at", "atgm":
			return "at"
		"mortar":
			return "mortar"
		"sniper":
			return "recon"
		"drone":
			return "uav"
		"engineer":
			return "eng"
		"medic":
			return "med"
		"mg":
			return "mg"
	return "inf"

func _veh_sym(vt: String) -> String:
	match vt:
		"tank":
			return "armor"
		"ifv", "apc":
			return "mech"
		"technical":
			return "motor"
		"aa", "aagun":
			return "ad"
		"arty", "howitzer", "fieldgun", "mtngun", "hmortar":
			return "arty"
		"mlrs":
			return "mlrs"
		"atgun":
			return "at"
		"heli", "transport":
			return "heli"
		"uav", "uav_armed", "loiter", "fpv":
			return "uav"
		"truck":
			return "supply"
	return "armor"

# çerçeve: dost dikdörtgen, düşman eşkenar dörtgen; iç sembol; altta can çubuğu; seçiliyse beyaz kenar
func _icon(p: Vector2, friend: bool, sym: String, hpf: float, sel: bool, cnt: String, font: Font) -> void:
	var col := FRIEND if friend else FOE
	col.a = _alpha
	var fill := col.darkened(0.55)
	fill.a = 0.62 * _alpha
	var ink := Color(0.98, 0.98, 0.95, _alpha)
	var w := 13.0 if sym != "inf_one" else 6.0
	var h := 9.0 if sym != "inf_one" else 5.0
	if friend:
		var r := Rect2(p - Vector2(w, h), Vector2(w, h) * 2.0)
		draw_rect(r, fill, true)
		draw_rect(r, Color(1, 1, 1, _alpha) if sel else col, false, 2.0 if sel else 1.4)
	else:
		var d := h * 1.45
		var pts := PackedVector2Array([p + Vector2(0, -d), p + Vector2(w * 1.05, 0), p + Vector2(0, d), p + Vector2(-w * 1.05, 0)])
		draw_colored_polygon(pts, fill)
		pts.append(pts[0])
		draw_polyline(pts, Color(1, 1, 1, _alpha) if sel else col, 2.0 if sel else 1.4, true)
	var iw := w * 0.72
	var ih := h * 0.62
	match sym:
		"inf", "mg", "inf_one":
			if sym != "inf_one":
				draw_line(p + Vector2(-iw, -ih), p + Vector2(iw, ih), ink, 1.3, true)
				draw_line(p + Vector2(-iw, ih), p + Vector2(iw, -ih), ink, 1.3, true)
			if sym == "mg":
				draw_circle(p + Vector2(0, ih + 1.0), 1.6, ink)
		"armor":
			_oval(p, iw * 0.95, ih * 0.75, ink)
		"mech":
			_oval(p, iw * 0.95, ih * 0.75, ink)
			draw_line(p + Vector2(-iw, -ih), p + Vector2(iw, ih), ink, 1.1, true)
			draw_line(p + Vector2(-iw, ih), p + Vector2(iw, -ih), ink, 1.1, true)
		"motor":
			draw_line(p + Vector2(-iw, -ih), p + Vector2(iw, ih), ink, 1.2, true)
			draw_line(p + Vector2(-iw, ih), p + Vector2(iw, -ih), ink, 1.2, true)
			draw_line(p + Vector2(0, -ih), p + Vector2(0, ih), ink, 1.2, true)
		"arty", "mortar":
			draw_circle(p, 2.8, ink)
			if sym == "mortar":
				draw_line(p + Vector2(0, -ih), p + Vector2(0, -2.8), ink, 1.2, true)
		"mlrs":
			draw_circle(p + Vector2(-3.5, 0), 2.2, ink)
			draw_circle(p + Vector2(3.5, 0), 2.2, ink)
		"at":
			draw_line(p + Vector2(-iw, ih), p + Vector2(0, -ih), ink, 1.4, true)
			draw_line(p + Vector2(0, -ih), p + Vector2(iw, ih), ink, 1.4, true)
		"ad":
			draw_arc(p + Vector2(0, ih), iw * 0.8, PI, TAU, 12, ink, 1.4, true)
		"heli":
			draw_colored_polygon(PackedVector2Array([p + Vector2(-iw, -ih), p, p + Vector2(-iw, ih)]), ink)
			draw_colored_polygon(PackedVector2Array([p + Vector2(iw, -ih), p, p + Vector2(iw, ih)]), ink)
		"uav":
			draw_polyline(PackedVector2Array([p + Vector2(-iw, -ih * 0.6), p + Vector2(0, ih * 0.6), p + Vector2(iw, -ih * 0.6)]), ink, 1.4, true)
		"recon":
			draw_line(p + Vector2(-iw, ih), p + Vector2(iw, -ih), ink, 1.4, true)
		"supply":
			draw_line(p + Vector2(-iw, ih * 0.6), p + Vector2(iw, ih * 0.6), ink, 1.6, true)
		"med":
			draw_line(p + Vector2(-ih, 0), p + Vector2(ih, 0), ink, 1.8, true)
			draw_line(p + Vector2(0, -ih), p + Vector2(0, ih), ink, 1.8, true)
		"eng":
			draw_polyline(PackedVector2Array([p + Vector2(-iw, ih * 0.5), p + Vector2(-iw, -ih * 0.5), p + Vector2(iw, -ih * 0.5), p + Vector2(iw, ih * 0.5)]), ink, 1.3, true)
			draw_line(p + Vector2(0, -ih * 0.5), p + Vector2(0, ih * 0.5), ink, 1.3, true)
		"base":
			draw_rect(Rect2(p - Vector2(iw * 0.5, ih * 0.6), Vector2(iw, ih * 1.2)), ink, false, 1.3)
	# can çubuğu
	if sym != "inf_one" and hpf < 0.999:
		var bw := w * 2.0
		var by := p.y + h + (4.0 if friend else h * 0.5 + 4.0)
		draw_rect(Rect2(p.x - bw * 0.5, by, bw, 3.0), Color(0, 0, 0, 0.55 * _alpha), true)
		var hc := Color(0.4, 0.9, 0.35) if hpf > 0.5 else (Color(0.95, 0.8, 0.25) if hpf > 0.25 else Color(0.95, 0.3, 0.2))
		hc.a = _alpha
		draw_rect(Rect2(p.x - bw * 0.5, by, bw * hpf, 3.0), hc, true)
	if cnt != "":
		draw_string(font, p + Vector2(w + 2.0, -h + 9.0), cnt, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color(1, 1, 1, 0.85 * _alpha))

func _oval(c: Vector2, rx: float, ry: float, col: Color) -> void:
	var pts := PackedVector2Array()
	for i in 21:
		var a := float(i) / 20.0 * TAU
		pts.append(c + Vector2(cos(a) * rx, sin(a) * ry))
	draw_polyline(pts, col, 1.3, true)
