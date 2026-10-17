extends SceneTree
# Araç boyut denetimi: her katalog modelinin sınır kutusunu (katalog 'scale' uygulanmış) data/real_dims.json'daki
# gerçek boyutla karşılaştırır.
#   godot --headless --path . -s res://tools/size_audit.gd
# Hava araçlarında (helikopter, İHA, dolanan mühimmat) ölçüt W'dir (kanat açıklığı / rotor çapı), kara
# araçlarında L ve W. Satır: SIZE <id> <fam> model=L/W/H real=L/W/H scale=<s> dL=% dW=% <OK|BAD> [suggest=<s>]
# Son satır: SIZEAUDIT checked=<n> bad=<n>

const AIR_PREFIX := ["heli", "cargo_", "tiltrotor", "uav", "lm_", "fpv"]

func _init() -> void:
	var f := FileAccess.open("res://data/real_dims.json", FileAccess.READ)
	var real: Dictionary = JSON.parse_string(f.get_as_text())["units"]
	var cat := {}
	for nat in ["usa", "rus"]:
		var cf := FileAccess.open("res://data/catalog/%s.json" % nat, FileAccess.READ)
		for u in JSON.parse_string(cf.get_as_text())["units"]:
			cat[u["id"]] = u
	var checked := 0
	var bad := 0
	var ids: Array = real.keys()
	ids.sort()
	for id in ids:
		if not ResourceLoader.exists("res://assets/models/%s.glb" % id) or not cat.has(id):
			continue
		var u: Dictionary = cat[id]
		var fam: String = u.get("fam", "")
		var s = u.get("scale", 1.0)
		var sv := Vector3(float(s[0]), float(s[1]), float(s[2])) if s is Array else Vector3.ONE * float(s)
		var sc := sv.x
		var m := dims(id) * sv
		var r: Dictionary = real[id]
		if r.has("fire"):
			# kuyruğu açılan top (D-30): model atış düzeninde
			r = r["fire"]
		var tol := float(r.get("tol", 0.15))
		var air := AIR_PREFIX.any(func(p): return fam.begins_with(p))
		var dl := m.z / float(r["L"]) - 1.0
		# X kanat (Lancet, Red Dragon): kanatlar 45° çapraz — açıklık uçtan uca çapraz ölçülür (kutu eni × √2)
		var mw := m.x * sqrt(2.0) if u.get("v", {}).get("type", "") == "x" else m.x
		var dw := mw / float(r["W"]) - 1.0
		var ok := absf(dw) <= tol if air else (absf(dl) <= tol and absf(dw) <= tol + 0.05)
		checked += 1
		var line := "SIZE %s %s model=%.2f/%.2f/%.2f real=%.2f/%.2f/%.2f scale=%.2f dL=%+.0f%% dW=%+.0f%% %s" % [id, fam, m.z, m.x, m.y, float(r["L"]), float(r["W"]), float(r["H"]), sc, dl * 100.0, dw * 100.0, "OK" if ok else "BAD"]
		if not ok:
			bad += 1
			if air:
				line += " suggest=%.3f" % (sc * float(r["W"]) / mw)
		print(line)
	print("SIZEAUDIT checked=%d bad=%d" % [checked, bad])
	quit()

# modelin ölçeksiz sınır kutusu: x = en (W), y = yükseklik (H), z = boy (L)
static func dims(id: String) -> Vector3:
	var ps: PackedScene = load("res://assets/models/%s.glb" % id)
	var root := ps.instantiate()
	var box := AABB()
	var first := true
	for mi in root.find_children("*", "MeshInstance3D", true, false):
		if (mi as MeshInstance3D).mesh == null:
			continue
		var t := Transform3D()
		var c: Node = mi
		while c != null and c != root:
			if c is Node3D:
				t = (c as Node3D).transform * t
			c = c.get_parent()
		var bb: AABB = t * (mi as MeshInstance3D).mesh.get_aabb()
		box = bb if first else box.merge(bb)
		first = false
	root.free()
	return box.size
