extends Node
# Ses havuzu: konumlu 3B sesler, 2B arayüz sesleri, döngüler. Sesler tools/gen_audio.py ile sentezlenir.

var _streams := {}
var _variants := {}
var pool: Array = []
var pool2d: Array = []
var _last := {}
var _pi := 0
var volume := 0.8
var muted := false       # tüm sesler (testler)
var ui_muted := false    # yalnız 2B arayüz/uyarı sesleri (Ayarlar > Ses); savaş sesleri sürer

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	for i in 48:
		var p := AudioStreamPlayer3D.new()
		p.unit_size = 22.0
		p.max_distance = 170.0
		p.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		p.panning_strength = 0.6
		add_child(p)
		pool.append(p)
	for i in 8:
		var q := AudioStreamPlayer.new()
		add_child(q)
		pool2d.append(q)
	set_volume(volume)

func set_volume(v: float) -> void:
	volume = v
	AudioServer.set_bus_volume_db(0, linear_to_db(maxf(v, 0.0001)))
	AudioServer.set_bus_mute(0, v <= 0.001)

func _get_stream(n: String) -> AudioStream:
	if not _variants.has(n):
		var vs: Array = []
		var base := "res://audio/%s.wav" % n
		if ResourceLoader.exists(base):
			vs.append(load(base))
		for i in range(1, 7):
			var p := "res://audio/%s%d.wav" % [n, i]
			if ResourceLoader.exists(p):
				vs.append(load(p))
		_variants[n] = vs
	var arr: Array = _variants[n]
	if arr.is_empty():
		return null
	return arr[randi() % arr.size()]

func play3d(n: String, pos: Vector3, vol_db := 0.0, pitch_var := 0.08, min_gap := 0.025) -> void:
	if muted:
		return
	var now := Time.get_ticks_msec() / 1000.0
	if _last.has(n) and now - _last[n] < min_gap:
		return
	_last[n] = now
	var st := _get_stream(n)
	if st == null:
		return
	if G.cam and G.cam.cam:
		var f: Vector3 = G.cam.focus
		var d := Vector2(pos.x - f.x, pos.z - f.z).length()
		if d > 175.0:
			return
	var p: AudioStreamPlayer3D = null
	for k in pool.size():
		var c: AudioStreamPlayer3D = pool[(_pi + k) % pool.size()]
		if not c.playing:
			p = c
			_pi = (_pi + k + 1) % pool.size()
			break
	if p == null:
		p = pool[_pi]
		_pi = (_pi + 1) % pool.size()
	p.stream = st
	p.global_position = pos
	p.volume_db = vol_db
	p.pitch_scale = 1.0 + randf_range(-pitch_var, pitch_var)
	p.play()

func play2d(n: String, vol_db := 0.0) -> void:
	if muted or ui_muted:
		return
	var st := _get_stream(n)
	if st == null:
		return
	for q in pool2d:
		if not q.playing:
			q.stream = st
			q.volume_db = vol_db
			q.play()
			return

func loop3d(n: String, parent: Node3D, vol_db := 0.0) -> AudioStreamPlayer3D:
	var st := _get_stream(n)
	if st == null:
		return null
	var p := AudioStreamPlayer3D.new()
	p.stream = st
	p.unit_size = 14.0
	p.max_distance = 110.0
	p.volume_db = vol_db
	p.autoplay = true
	parent.add_child(p)
	return p

func ambience(n: String, vol_db := -12.0) -> AudioStreamPlayer:
	var st := _get_stream(n)
	if st == null:
		return null
	var q := AudioStreamPlayer.new()
	q.stream = st
	q.volume_db = vol_db
	q.autoplay = true
	add_child(q)
	return q
