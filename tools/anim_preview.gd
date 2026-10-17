extends Node3D
# İskeletli animasyon önizleme / doğrulama sahnesi (bkz. docs/ANIM_PIPELINE.md).
# Çalıştırma:
#   godot --path . res://tools/anim_preview.tscn -- --out=/mutlak/klasör [--samples=4] [--only=walk,run]
# Her klip ayrı bir askerde oynar; ayrıca AnimationTree ile hız karışımı (BlendSpace1D),
# tüfek üst gövde katmanı (kol kemiği süzgeçli Blend2) ve OneShot darbe tepkisi gösterilir.
# Her sayfa (PER_PAGE asker) için birkaç zaman örneğinde iki açıdan görüntü + sayfa özet görüntüsü kaydedilir.

const GLB := "res://assets/anim/soldier_anim.glb"
const META := "res://assets/anim/soldier_anim.json"
const PER_PAGE := 3
const SPACING := 2.4
const TILE := Vector2i(640, 360)

var out_dir := ""
var samples := 4
var only: PackedStringArray = []
var meta: Dictionary = {}
var scene: PackedScene
var cams: Array[Camera3D] = []
var cam_names: PackedStringArray = ["front", "rts"]

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--out="):
			out_dir = a.substr(6)
		elif a.begins_with("--samples="):
			samples = maxi(1, a.substr(10).to_int())
		elif a.begins_with("--only="):
			only = a.substr(7).split(",")
	if out_dir == "":
		out_dir = ProjectSettings.globalize_path("user://anim_preview")
	DirAccess.make_dir_recursive_absolute(out_dir)
	meta = JSON.parse_string(FileAccess.get_file_as_string(META))
	scene = load(GLB)
	_build_world()
	_run.call_deferred()

# ------------------------------------------------------------ dünya
func _build_world() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.62, 0.68, 0.74)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.75, 0.78, 0.82)
	env.ambient_light_energy = 0.45
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	var we := WorldEnvironment.new()
	we.environment = env
	add_child(we)
	var sun := DirectionalLight3D.new()
	sun.rotation_degrees = Vector3(-55, 160, 0)   # önden-soldan (asker -Z'ye bakar)
	sun.light_energy = 0.9
	sun.shadow_enabled = true
	add_child(sun)
	# 0.5 m'lik dama zemin (ayak kayması / yere basma kontrolü)
	var img := Image.create(2, 2, false, Image.FORMAT_RGB8)
	img.set_pixel(0, 0, Color(0.55, 0.53, 0.48))
	img.set_pixel(1, 1, Color(0.55, 0.53, 0.48))
	img.set_pixel(1, 0, Color(0.42, 0.41, 0.37))
	img.set_pixel(0, 1, Color(0.42, 0.41, 0.37))
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = ImageTexture.create_from_image(img)
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mat.uv1_scale = Vector3(40, 40, 1)
	var pm := PlaneMesh.new()
	pm.size = Vector2(40, 40)
	var g := MeshInstance3D.new()
	g.mesh = pm
	g.material_override = mat
	add_child(g)
	# kameralar: ön 3/4 (asker -Z'ye bakar) ve yüksek RTS açısı (arkadan-yandan)
	var c1 := Camera3D.new()
	c1.fov = 34
	add_child(c1)
	c1.look_at_from_position(Vector3(2.6, 1.9, -8.6), Vector3(0, 0.95, 0))
	var c2 := Camera3D.new()
	c2.fov = 34
	add_child(c2)
	c2.look_at_from_position(Vector3(-5.0, 7.5, -6.5), Vector3(0, 0.6, 0))
	cams = [c1, c2]
	# yakın planlar: her asker için ön-sağ 3/4 (konumu sayfada ayarlanır)
	for k in PER_PAGE:
		var cc := Camera3D.new()
		cc.fov = 34
		add_child(cc)
		cams.append(cc)
		cam_names.append("close%d" % k)

# ------------------------------------------------------------ hücreler
func _cells() -> Array:
	var out: Array = []
	var clips: Dictionary = meta["clips"]
	for n in clips:
		if only.size() > 0 and not only.has(n):
			continue
		out.append({"kind": "clip", "clip": n, "label": n})
	if only.size() == 0 or only.has("demo"):
		out.append({"kind": "tree", "label": "hız 2.0 m/s karışım + rifle_ready", "loco": ["idle", "walk", "run", "sprint"], "speed": 2.0, "upper": "rifle_ready"})
		out.append({"kind": "tree", "label": "walk + rifle_aim katmanı", "loco": ["walk"], "speed": 0.0, "upper": "rifle_aim"})
		out.append({"kind": "tree", "label": "strafe_left + rifle_aim", "loco": ["strafe_left"], "speed": 0.0, "upper": "rifle_aim"})
		out.append({"kind": "tree", "label": "kneel_idle + rifle_aim", "loco": ["kneel_idle"], "speed": 0.0, "upper": "rifle_aim"})
		out.append({"kind": "tree", "label": "crouch_walk + rifle_ready", "loco": ["crouch_walk"], "speed": 0.0, "upper": "rifle_ready"})
		out.append({"kind": "tree", "label": "sprint + rifle_ready", "loco": ["sprint"], "speed": 0.0, "upper": "rifle_ready"})
		out.append({"kind": "tree", "label": "idle + rifle_aim + OneShot hit", "loco": ["idle"], "speed": 0.0, "upper": "rifle_aim", "shot": "hit_stagger"})
	return out

func _find(n: Node, cls: String) -> Node:
	if n.is_class(cls):
		return n
	for c in n.get_children():
		var r := _find(c, cls)
		if r:
			return r
	return null

func _find_name(n: Node, nm: String) -> Node:
	if String(n.name) == nm:
		return n
	for c in n.get_children():
		var r := _find_name(c, nm)
		if r:
			return r
	return null

func _spawn(cell: Dictionary, x: float) -> Dictionary:
	var ch: Node3D = scene.instantiate()
	add_child(ch)
	ch.position = Vector3(x, 0, 0)
	var ap: AnimationPlayer = _find(ch, "AnimationPlayer")
	for n in meta["clips"]:
		var info: Dictionary = meta["clips"][n]
		if ap.has_animation(n):
			ap.get_animation(n).loop_mode = Animation.LOOP_LINEAR if info.get("loop", false) else Animation.LOOP_NONE
	var rifle := _find_name(ch, "Rifle") as Node3D
	var lab := Label3D.new()
	lab.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lab.font_size = 40
	lab.pixel_size = 0.0045
	lab.outline_size = 8
	lab.position = Vector3(x, 2.25, 0)
	add_child(lab)
	var d := {"cell": cell, "node": ch, "ap": ap, "label": lab, "t": 0.0}
	if cell["kind"] == "clip":
		var clip: String = cell["clip"]
		if rifle:
			rifle.visible = clip.begins_with("rifle_")
		ap.play(clip)
		ap.speed_scale = 0.0
		d["len"] = ap.get_animation(clip).length
	else:
		if rifle:
			rifle.visible = true
		var tree := _make_tree(ch, ap, cell)
		d["tree"] = tree
		d["len"] = 2.4
	return d

func _arm_paths(ap: AnimationPlayer) -> Array:
	var arm: Array = meta["arm_layer_bones"]
	var out: Array = []
	var anim := ap.get_animation("walk")
	for i in anim.get_track_count():
		var p := anim.track_get_path(i)
		if arm.has(String(p.get_concatenated_subnames())):
			out.append(p)
	return out

func _make_tree(ch: Node3D, ap: AnimationPlayer, cell: Dictionary) -> AnimationTree:
	var bt := AnimationNodeBlendTree.new()
	var loco: Array = cell["loco"]
	if loco.size() > 1:
		var bs := AnimationNodeBlendSpace1D.new()
		bs.min_space = 0.0
		bs.max_space = 8.0
		bs.sync = true
		for n in loco:
			var an := AnimationNodeAnimation.new()
			an.animation = n
			var sp: float = 0.0 if n == "idle" else float(meta["clips"][n].get("speed", 0.0))
			bs.add_blend_point(an, sp)
		bt.add_node("loco", bs)
	else:
		var an1 := AnimationNodeAnimation.new()
		an1.animation = loco[0]
		bt.add_node("loco", an1)
	var up := AnimationNodeAnimation.new()
	up.animation = cell["upper"]
	bt.add_node("upper", up)
	# sıra: hareket → OneShot (tam gövde tepki) → tüfek katmanı (kollar silahta kalır)
	var base := "loco"
	if cell.has("shot"):
		var os := AnimationNodeOneShot.new()
		os.fadein_time = 0.15
		os.fadeout_time = 0.3
		var sa := AnimationNodeAnimation.new()
		sa.animation = cell["shot"]
		bt.add_node("shot_anim", sa)
		bt.add_node("shot", os)
		bt.connect_node("shot", 0, "loco")
		bt.connect_node("shot", 1, "shot_anim")
		base = "shot"
	var b2 := AnimationNodeBlend2.new()
	b2.filter_enabled = true
	for p in _arm_paths(ap):
		b2.set_filter_path(p, true)
	bt.add_node("layer", b2)
	bt.connect_node("layer", 0, base)
	bt.connect_node("layer", 1, "upper")
	bt.connect_node("output", 0, "layer")
	var tree := AnimationTree.new()
	ch.add_child(tree)
	tree.anim_player = tree.get_path_to(ap)
	tree.tree_root = bt
	tree.callback_mode_process = AnimationMixer.ANIMATION_CALLBACK_MODE_PROCESS_MANUAL
	tree.active = true
	if loco.size() > 1:
		tree.set("parameters/loco/blend_position", float(cell["speed"]))
	tree.set("parameters/layer/blend_amount", 1.0)
	if cell.has("shot"):
		tree.set("parameters/shot/request", AnimationNodeOneShot.ONE_SHOT_REQUEST_FIRE)
	ap.active = false
	return tree

# ------------------------------------------------------------ çalıştırma
func _set_time(d: Dictionary, frac: float) -> void:
	var cell: Dictionary = d["cell"]
	var t: float = d["len"] * frac
	if cell["kind"] == "clip":
		var ap: AnimationPlayer = d["ap"]
		ap.seek(t, true)
	else:
		var tree: AnimationTree = d["tree"]
		var cur: float = d["t"]
		while cur < t - 0.0001:
			var dt: float = minf(1.0 / 30.0, t - cur)
			tree.advance(dt)
			cur += dt
		d["t"] = cur
	(d["label"] as Label3D).text = "%s\nt=%.2f/%.2f s" % [cell["label"], t, d["len"]]

func _bone_pos(d: Dictionary, bone: String) -> Vector3:
	var sk: Skeleton3D = _find(d["node"], "Skeleton3D")
	return (sk.global_transform * sk.get_bone_global_pose(sk.find_bone(bone))).origin

func _foot_report(d: Dictionary) -> String:
	var sk: Skeleton3D = _find(d["node"], "Skeleton3D")
	var lo := 99.0
	var parts: Array = []
	for b in ["LeftFoot", "RightFoot", "LeftToes", "RightToes"]:
		var i := sk.find_bone(b)
		var p := (sk.global_transform * sk.get_bone_global_pose(i)).origin
		lo = minf(lo, p.y)
		parts.append("%s=%.3f" % [b, p.y])
	return "min=%.3f %s" % [lo, " ".join(parts)]

func _snap() -> Image:
	await RenderingServer.frame_post_draw
	return get_viewport().get_texture().get_image()

func _run() -> void:
	var cells := _cells()
	var page := 0
	var i := 0
	while i < cells.size():
		var group := cells.slice(i, i + PER_PAGE)
		i += PER_PAGE
		page += 1
		var live: Array = []
		for k in group.size():
			var x := (k - (group.size() - 1) * 0.5) * SPACING
			live.append(_spawn(group[k], x))
		var sheet := Image.create(TILE.x * samples, TILE.y * cams.size(), false, Image.FORMAT_RGB8)
		for s in samples:
			var frac := (s + 0.5) / float(samples)
			for k in live.size():
				_set_time(live[k], frac)
				# yakın plan kalçayı izler (kök hareketi, yatış, sürünme)
				var hp := _bone_pos(live[k], "Hips")
				var tgt := Vector3(hp.x, clampf(hp.y, 0.35, 1.0), hp.z)
				cams[2 + k].look_at_from_position(tgt + Vector3(1.6, 0.75, -2.7), tgt)
			for ci in cams.size():
				if ci >= 2 + live.size():
					continue
				cams[ci].current = true
				for _w in 2:
					await get_tree().process_frame
				var img := await _snap()
				img.convert(Image.FORMAT_RGB8)
				if ci == 0 or ci >= 2:
					img.save_png(out_dir.path_join("p%02d_%s_s%d.png" % [page, cam_names[ci], s]))
				var tile := img.duplicate() as Image
				tile.resize(TILE.x, TILE.y, Image.INTERPOLATE_BILINEAR)
				sheet.blit_rect(tile, Rect2i(Vector2i.ZERO, TILE), Vector2i(TILE.x * s, TILE.y * ci))
			for d in live:
				print("ANIM p%02d s%d %-28s %s" % [page, s, (d["cell"] as Dictionary)["label"], _foot_report(d)])
		sheet.save_png(out_dir.path_join("sheet_p%02d.png" % page))
		print("ANIM sayfa %d: %s" % [page, ", ".join(group.map(func(c: Dictionary) -> String: return String(c["label"])))])
		for d in live:
			(d["node"] as Node).queue_free()
			(d["label"] as Node).queue_free()
		await get_tree().process_frame
	print("ANIM DONE ", out_dir)
	get_tree().quit()
