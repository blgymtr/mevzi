class_name FogOfWar extends Node3D
# Görsel savaş sisi: izlenen tarafın birlik/yapı görüş çemberleri iki SubViewport'a çizilir —
# "vis" her kare temizlenir (şu an görülen), "exp" hiç temizlenmez (keşfedilmiş birikimi).
# Tam ekran sis katmanı (fow.gdshader) ikisini dünya konumuna göre okur.

var vis_vp: SubViewport
var exp_vp: SubViewport
var quad: MeshInstance3D
var mat: ShaderMaterial
var N := 256
static var _disc: Texture2D = null

class Painter extends Node2D:
	var fow: FogOfWar
	func _draw() -> void:
		var vt := G.view_team()
		if vt < 0 or FogOfWar._disc == null:
			return
		var k := float(fow.N) / G.MAP
		for u in G.units:
			if not is_instance_valid(u) or u.team != vt or not u.alive:
				continue
			if u is Soldier and (u.state == "aboard" or u.state == "hospital"):
				continue
			var r: float = u.sight * k * (G.weather.sight_mult() if G.weather != null and is_instance_valid(G.weather) and not (u is Building) else 1.0)
			var c := Vector2(u.position.x, u.position.z) * k
			draw_texture_rect(FogOfWar._disc, Rect2(c - Vector2(r, r), Vector2(r, r) * 2.0), false)

func _ready() -> void:
	if _disc == null:
		var S := 64
		var im := Image.create(S, S, false, Image.FORMAT_RGBA8)
		for y in S:
			for x in S:
				var d := Vector2(x + 0.5 - S * 0.5, y + 0.5 - S * 0.5).length() / (S * 0.5)
				var a := clampf((1.0 - d) / 0.18, 0.0, 1.0)
				im.set_pixel(x, y, Color(1, 1, 1, a))
		_disc = ImageTexture.create_from_image(im)
	N = clampi(int(G.MAP), 128, 1024)
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

var _t := 0.0
func _process(dt: float) -> void:
	quad.visible = G.running and G.view_team() >= 0 and not G.game_over
	if not quad.visible:
		return
	_t -= dt
	if _t > 0.0:
		return
	_t = 0.1
	for vp in [vis_vp, exp_vp]:
		for ch in vp.get_children():
			if ch is Painter:
				ch.queue_redraw()
