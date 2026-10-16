class_name Terrain extends Node3D
# Arazi: fotoğraf dokulu karışım, yükseklik (nehir yatağı), su yüzeyi ve boyanabilir harita
# (R yol, G iz, B yanık, A yama).
# Büyük harita: boya ve yükseklik dokuları parçalara (chunk) bölünür — iz/krater/siper yalnız değişen
# parçayı GPU'ya yükler (eskiden her patlamada 16 MB'lık tam doku yükleniyordu). Arazi karoları tek ortak
# örgüyü paylaşır (4 km'de karo başına ayrı örgü ~1,2 GB VRAM tutuyordu); kamera uzaklaştıkça seyrek
# örgüye geçilir.

static var RES := 1024
static var HRES := 512
const WATER_Y := -0.6
const CHP := 1024            # boya dokusu parça kenarı (piksel)
const TILE := 256.0          # arazi karosu kenarı (m)

var mat: ShaderMaterial      # taban malzeme (parça malzemeleri bundan çoğaltılır; harita dışı halka)
var img: Image
var himg: Image
var NC := 1                  # kenar başına parça sayısı
var _cp := 1024              # parça başına boya pikseli
var _hcp := 512              # parça başına yükseklik pikseli
var _cw := 256.0             # parça dünya kenarı (m)
var _cmats: Array = []
var _ctex: Array = []
var _chtex: Array = []
var _cdirty := {}            # GPU'ya yüklenecek boya parçaları
var _hdirty := {}            # GPU'ya yüklenecek yükseklik parçaları
var _tiles: Array = []
var _lod := -1
var _lod_mesh: Array = []    # ortak örgüler: ince / orta / seyrek
var water: Node3D            # nehir şeritleri (taşkında hep birlikte yükselir)
var water_mat: ShaderMaterial
var has_water := false
var biome: Dictionary
var kind := "desert"
var wet_rects: Array = []
var _rivers: Array = []      # [noktalar, genişlik] — su şeridi örgüsü için
# tarla dokusu (büyük harita): r tür/5 (1 buğday, 2 yeşil ekin, 3 sürülmüş, 4 çayır, 5 orman zemini),
# g sıra açısı/π, b ton, a kapsama (kenar yumuşatmalı: doğrusal süzmede kenar düz kalır, basamak yok).
# Yükleme sonrası değişmez (tek doku, 8 km'de 2048² = 4 m/piksel)
var fimg: Image
var ftex: ImageTexture
var FRES := 256
var _fdirty := false
var _upd := 0.0

func build(b: Dictionary) -> void:
	biome = b
	kind = b["id"]
	img = Image.create(RES, RES, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))
	himg = Image.create(HRES, HRES, false, Image.FORMAT_RF)
	himg.fill(Color(0, 0, 0, 1))
	NC = maxi(1, RES / CHP)
	_cp = RES / NC
	_hcp = HRES / NC
	_cw = G.MAP / NC
	FRES = clampi(int(G.MAP / 4.0), 64, 2048)
	fimg = Image.create(FRES, FRES, false, Image.FORMAT_RGBA8)
	ftex = ImageTexture.create_from_image(fimg)
	mat = ShaderMaterial.new()
	mat.shader = load("res://shaders/terrain.gdshader")
	_apply_material(mat)
	mat.set_shader_parameter("field_tex", ftex)
	mat.set_shader_parameter("field_mask", ftex)
	for cz in NC:
		for cx in NC:
			var m: ShaderMaterial = mat.duplicate()
			var t := ImageTexture.create_from_image(_chunk_img(img, cx, cz, _cp))
			var ht := ImageTexture.create_from_image(_chunk_img(himg, cx, cz, _hcp))
			m.set_shader_parameter("map_tex", t)
			m.set_shader_parameter("height_tex", ht)
			m.set_shader_parameter("chunk_org", Vector2(cx, cz) * _cw)
			m.set_shader_parameter("chunk_size", _cw)
			m.set_shader_parameter("chunk_px", float(_cp))
			m.set_shader_parameter("chunk_hpx", float(_hcp))
			_cmats.append(m)
			_ctex.append(t)
			_chtex.append(ht)
	# arazi karoları: 256 m, hepsi aynı örgüyü paylaşır (dünya konumuyla dokulanır); köşe aralığı ~0,67 m
	var tiles := maxi(1, int(ceil(G.MAP / TILE)))
	var ts := G.MAP / tiles
	for sub in [383, 95, 23]:
		var pm := PlaneMesh.new()
		pm.size = Vector2(ts, ts)
		pm.subdivide_width = sub
		pm.subdivide_depth = sub
		_lod_mesh.append(pm)
	for tz in tiles:
		for tx in tiles:
			var t := MeshInstance3D.new()
			t.mesh = _lod_mesh[0]
			t.position = Vector3((tx + 0.5) * ts, 0, (tz + 0.5) * ts)
			t.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			t.extra_cull_margin = 4.0
			var cx := clampi(int(t.position.x / _cw), 0, NC - 1)
			var cz := clampi(int(t.position.z / _cw), 0, NC - 1)
			t.material_override = _cmats[cz * NC + cx]
			add_child(t)
			_tiles.append(t)
	_lod = 0
	# harita dışı: aynı malzemeyle düz çevre halkası (büyük haritada stratejik yakınlaştırmaya yetecek genişlik)
	var E := 260.0 if G.MAP <= 1024.0 else 3000.0
	for r in [Rect2(-E, -E, G.MAP + 2 * E, E), Rect2(-E, G.MAP, G.MAP + 2 * E, E), Rect2(-E, 0, E, G.MAP), Rect2(G.MAP, 0, E, G.MAP)]:
		var outer := PlaneMesh.new()
		outer.size = r.size
		var omi := MeshInstance3D.new()
		omi.mesh = outer
		omi.position = Vector3(r.get_center().x, -0.01, r.get_center().y)
		omi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		omi.material_override = _cmats[0]
		add_child(omi)

# parça görüntüsü: kenarlarda komşu parçadan 1 piksel pay (doğrusal süzmede parça dikişi olmasın)
func _chunk_img(src: Image, cx: int, cz: int, cp: int) -> Image:
	var ci := Image.create(cp + 2, cp + 2, false, src.get_format())
	ci.blit_rect(src, Rect2i(cx * cp - 1, cz * cp - 1, cp + 2, cp + 2), Vector2i.ZERO)
	return ci

# piksel aralığının (kapsayıcı) dokunduğu parçalar kirli; komşunun payı da değişir
func _mark(x0: int, z0: int, x1: int, z1: int) -> void:
	for cz in range(clampi((z0 - 1) / _cp, 0, NC - 1), clampi((z1 + 1) / _cp, 0, NC - 1) + 1):
		for cx in range(clampi((x0 - 1) / _cp, 0, NC - 1), clampi((x1 + 1) / _cp, 0, NC - 1) + 1):
			_cdirty[cz * NC + cx] = true

func _hmark(x0: int, z0: int, x1: int, z1: int) -> void:
	for cz in range(clampi((z0 - 1) / _hcp, 0, NC - 1), clampi((z1 + 1) / _hcp, 0, NC - 1) + 1):
		for cx in range(clampi((x0 - 1) / _hcp, 0, NC - 1), clampi((x1 + 1) / _hcp, 0, NC - 1) + 1):
			_hdirty[cz * NC + cx] = true

func _apply_material(m: ShaderMaterial) -> void:
	var b := biome
	m.set_shader_parameter("map_size", G.MAP)
	m.set_shader_parameter("tex_a", Biomes.tex(b["a"]))
	m.set_shader_parameter("nrm_a", Biomes.tex(b["a"], "normal"))
	m.set_shader_parameter("tex_b", Biomes.tex(b["b"]))
	m.set_shader_parameter("nrm_b", Biomes.tex(b["b"], "normal"))
	m.set_shader_parameter("tex_road", Biomes.tex(b["road"]))
	m.set_shader_parameter("nrm_road", Biomes.tex(b["road"], "normal"))
	m.set_shader_parameter("tex_bank", Biomes.tex(b["bank"]))
	m.set_shader_parameter("tex_burn", Biomes.tex(b["burn"]))
	m.set_shader_parameter("macro", _noise_tex(256, 0.012, 4, FastNoiseLite.FRACTAL_FBM, false, 0.0, 41))
	m.set_shader_parameter("dune_n", _noise_tex(512, 0.006, 5, FastNoiseLite.FRACTAL_RIDGED, true, 9.0, 11))
	for k in ["tint_a", "tint_a2", "tint_b", "tint_road", "tint_bank", "tint_track"]:
		m.set_shader_parameter(k, b[k])
	m.set_shader_parameter("scale_a", b["scale_a"])
	m.set_shader_parameter("scale_b", b["scale_b"])
	m.set_shader_parameter("scale_road", b["scale_road"])
	m.set_shader_parameter("patch_noise", b["patch_noise"])
	m.set_shader_parameter("dune_strength", b["dune"])
	m.set_shader_parameter("normal_strength", b["nstr"])
	m.set_shader_parameter("macro_strength", b["macro"])
	m.set_shader_parameter("road_amt", b.get("road_amt", 1.0))
	m.set_shader_parameter("paved", 1.0 if G.map_id in ["big_city", "winter_village", "desert_town"] else 0.0)

func _noise_tex(size: int, freq: float, oct: int, frac: int, normal: bool, bump: float, seed_v: int) -> NoiseTexture2D:
	var nt := NoiseTexture2D.new()
	nt.width = size
	nt.height = size
	nt.seamless = true
	nt.generate_mipmaps = true
	var fn := FastNoiseLite.new()
	fn.seed = seed_v
	fn.noise_type = FastNoiseLite.TYPE_SIMPLEX_SMOOTH
	fn.frequency = freq
	fn.fractal_type = frac
	fn.fractal_octaves = oct
	nt.noise = fn
	if normal:
		nt.as_normal_map = true
		nt.bump_strength = bump
	return nt

func _process(dt: float) -> void:
	_trk_t -= dt
	if _trk_t <= 0.0:
		_trk_t = 2.0
		_track_fade()
	_upd -= dt
	if _upd <= 0.0 and (not _cdirty.is_empty() or not _hdirty.is_empty()):
		_upd = 0.25
		# kare başına en çok iki parça (büyük haritada parça 4 MB)
		var n := 0
		for k in _cdirty.keys():
			(_ctex[k] as ImageTexture).update(_chunk_img(img, k % NC, k / NC, _cp))
			_cdirty.erase(k)
			n += 1
			if n >= 2:
				break
		n = 0
		for k in _hdirty.keys():
			(_chtex[k] as ImageTexture).update(_chunk_img(himg, k % NC, k / NC, _hcp))
			_hdirty.erase(k)
			n += 1
			if n >= 2:
				break
	_lod_tick()

# kamera uzaklaştıkça seyrek arazi örgüsü (ortografik kamerada mesafe değil yakınlaştırma belirler)
func _lod_tick() -> void:
	if G.cam == null or _tiles.is_empty():
		return
	var s: float = G.cam.size
	var l := _lod
	if s < 150.0:
		l = 0
	elif s > 170.0 and s < 650.0:
		l = 1
	elif s > 700.0:
		l = 2
	if l != _lod:
		_lod = l
		for t in _tiles:
			(t as MeshInstance3D).mesh = _lod_mesh[l]

# tarla: döndürülmüş dikdörtgen (ang: uzun kenarın yönü), ekin türü ve ton. Kapsama işaretli uzaklıktan:
# kenar pikselinde kısmi değer (çizgi doğrusal süzmede düz çıkar)
func field_rect(c: Vector3, size: Vector2, ang: float, crop: int, tone: float) -> void:
	var k := float(FRES) / G.MAP
	var tm := 1.0 / k
	var ca := cos(ang)
	var sa := sin(ang)
	var ex := (absf(size.x * ca) + absf(size.y * sa)) * 0.5 + tm * 2.0
	var ez := (absf(size.x * sa) + absf(size.y * ca)) * 0.5 + tm * 2.0
	for z in range(maxi(0, int((c.z - ez) * k)), mini(FRES - 1, int((c.z + ez) * k)) + 1):
		for x in range(maxi(0, int((c.x - ex) * k)), mini(FRES - 1, int((c.x + ex) * k)) + 1):
			var px := (x + 0.5) * tm - c.x
			var pz := (z + 0.5) * tm - c.z
			var sd := maxf(absf(px * ca + pz * sa) - size.x * 0.5, absf(-px * sa + pz * ca) - size.y * 0.5)
			_fpaint(x, z, clampf(0.5 - sd / tm, 0.0, 1.0), crop, ang, tone)
	_fdirty = true

# orman zemini: gürültülü elips (orman üreticisiyle aynı kenar), uzaktan koyu yeşil kütle okunur
func forest_floor(c: Vector3, rx: float, rz: float, ang: float, ph: float) -> void:
	var k := float(FRES) / G.MAP
	var tm := 1.0 / k
	var ca := cos(ang)
	var sa := sin(ang)
	var R := maxf(rx, rz) * 1.25 + tm * 2.0
	var rm := minf(rx, rz)
	for z in range(maxi(0, int((c.z - R) * k)), mini(FRES - 1, int((c.z + R) * k)) + 1):
		for x in range(maxi(0, int((c.x - R) * k)), mini(FRES - 1, int((c.x + R) * k)) + 1):
			var px := (x + 0.5) * tm - c.x
			var pz := (z + 0.5) * tm - c.z
			var lx := px * ca + pz * sa
			var lz := -px * sa + pz * ca
			var e := (lx * lx) / (rx * rx) + (lz * lz) / (rz * rz)
			var th := atan2(lz, lx)
			var edge := 1.0 + 0.16 * sin(th * 5.0 + ph) + 0.08 * sin(th * 11.0 + ph * 2.0)
			var sd := (sqrt(e) - sqrt(edge)) * rm
			_fpaint(x, z, clampf(0.5 - sd / tm, 0.0, 1.0), 5, 0.0, fposmod(px * 0.013 + pz * 0.017, 1.0))
	_fdirty = true

func _fpaint(x: int, z: int, cov: float, crop: int, ang: float, tone: float) -> void:
	if cov <= 0.0:
		return
	var c := fimg.get_pixel(x, z)
	if cov >= c.a:
		fimg.set_pixel(x, z, Color(float(crop) / 5.0, fposmod(ang, PI) / PI, tone, cov))

# p'deki ekin türü (0 tarla değil, 5 orman zemini)
func field_at(p: Vector3) -> int:
	var x := int(p.x / G.MAP * FRES)
	var z := int(p.z / G.MAP * FRES)
	if x < 0 or z < 0 or x >= FRES or z >= FRES:
		return 0
	var c := fimg.get_pixel(x, z)
	return int(round(c.r * 5.0)) if c.a > 0.5 else 0

func flush() -> void:
	if _fdirty:
		ftex.update(fimg)
		_fdirty = false
	for k in NC * NC:
		(_ctex[k] as ImageTexture).update(_chunk_img(img, k % NC, k / NC, _cp))
		(_chtex[k] as ImageTexture).update(_chunk_img(himg, k % NC, k / NC, _hcp))
	_cdirty.clear()
	_hdirty.clear()

# ------------------------------------------------------------ yükseklik / su
func carve(pts: PackedVector3Array, width: float, depth: float) -> void:
	# nehir/kanal yatağı: merkezde -depth, kıyıda yumuşak geçiş
	var bank := width * 0.5 + 2.5
	var k := float(HRES) / G.MAP
	# ıslak alan kutuları: 8 noktalık parçalar (su maskesi/ızgara yalnız burada taranır). Eskiden tüm
	# nehrin tek kutusu alınıyordu; çapraz nehirde bu bütün harita demekti (4 km'de 4 sn)
	for i0 in range(0, pts.size(), 8):
		var bb := Rect2(pts[i0].x, pts[i0].z, 0, 0)
		for q0 in pts.slice(i0, mini(i0 + 9, pts.size())):
			bb = bb.expand(Vector2(q0.x, q0.z))
		wet_rects.append(bb.grow(bank + 1.0))
	_rivers.append([pts, width])
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		var x0 := maxi(0, int((minf(a.x, b.x) - bank) * k))
		var x1 := mini(HRES - 1, int((maxf(a.x, b.x) + bank) * k))
		var z0 := maxi(0, int((minf(a.z, b.z) - bank) * k))
		var z1 := mini(HRES - 1, int((maxf(a.z, b.z) + bank) * k))
		var a2 := Vector2(a.x, a.z)
		var ab := Vector2(b.x, b.z) - a2
		var L2 := maxf(ab.length_squared(), 1e-5)
		for z in range(z0, z1 + 1):
			for x in range(x0, x1 + 1):
				var q := Vector2((x + 0.5) / k, (z + 0.5) / k)
				var t := clampf((q - a2).dot(ab) / L2, 0.0, 1.0)
				var d := (q - (a2 + ab * t)).length()
				var hh := 0.0
				if d < width * 0.5:
					hh = -depth * (1.0 - pow(d / (width * 0.5), 4.0) * 0.35)
				elif d < bank:
					var u := (d - width * 0.5) / (bank - width * 0.5)
					hh = lerpf(-depth * 0.65, 0.0, smoothstep(0.0, 1.0, u))
				else:
					continue
				var cur := himg.get_pixel(x, z).r
				if hh < cur:
					himg.set_pixel(x, z, Color(hh, 0, 0, 1))
	has_water = true

func carve_trench(a: Vector3, b: Vector3, w: float, depth: float) -> void:
	var k := float(HRES) / G.MAP
	var r := w * 0.5 + 1.0
	var a2 := Vector2(a.x, a.z)
	var ab := Vector2(b.x, b.z) - a2
	var L2 := maxf(ab.length_squared(), 1e-5)
	for z in range(maxi(0, int((minf(a.z, b.z) - r) * k)), mini(HRES - 1, int((maxf(a.z, b.z) + r) * k)) + 1):
		for x in range(maxi(0, int((minf(a.x, b.x) - r) * k)), mini(HRES - 1, int((maxf(a.x, b.x) + r) * k)) + 1):
			var q := Vector2((x + 0.5) / k, (z + 0.5) / k)
			var t := clampf((q - a2).dot(ab) / L2, 0.0, 1.0)
			var d := (q - (a2 + ab * t)).length()
			var hh := 0.0
			if d < w * 0.5:
				hh = -depth
			elif d < w * 0.5 + 0.9:
				hh = 0.12 * (1.0 - absf((d - w * 0.5 - 0.45) / 0.45))
			else:
				continue
			var cur := himg.get_pixel(x, z).r
			if hh < 0.0 and hh < cur or hh > 0.0 and cur >= 0.0 and hh > cur:
				himg.set_pixel(x, z, Color(hh, 0, 0, 1))
	_hmark(int((minf(a.x, b.x) - r) * k), int((minf(a.z, b.z) - r) * k), int((maxf(a.x, b.x) + r) * k), int((maxf(a.z, b.z) + r) * k))

# krater: çanak çukur + kenarda kabarık toprak halkası (içine asker girer)
func carve_crater(p: Vector3, r: float, depth: float) -> void:
	var k := float(HRES) / G.MAP
	var ext := r * 1.5
	for z in range(maxi(0, int((p.z - ext) * k)), mini(HRES - 1, int((p.z + ext) * k)) + 1):
		for x in range(maxi(0, int((p.x - ext) * k)), mini(HRES - 1, int((p.x + ext) * k)) + 1):
			var q := Vector2((x + 0.5) / k - p.x, (z + 0.5) / k - p.z)
			var d := q.length() / r
			var hh := 0.0
			if d < 1.0:
				hh = -depth * (1.0 - d * d)
			elif d < 1.45:
				hh = depth * 0.25 * (1.0 - absf((d - 1.2) / 0.25))
			else:
				continue
			var cur := himg.get_pixel(x, z).r
			if hh < cur - 0.01 or (hh > 0.0 and cur >= -0.05 and hh > cur):
				himg.set_pixel(x, z, Color(minf(hh, cur) if hh < 0.0 else hh, 0, 0, 1))
	_hmark(int((p.x - ext) * k), int((p.z - ext) * k), int((p.x + ext) * k), int((p.z + ext) * k))

func raise_flat(p: Vector3, size: Vector2, rot: float) -> void:
	# köprü/yol rampası için yatağı doldur (yükseklik 0)
	var k := float(HRES) / G.MAP
	var c := cos(rot)
	var s := sin(rot)
	var ext := maxf(size.x, size.y) * 0.75
	for z in range(maxi(0, int((p.z - ext) * k)), mini(HRES - 1, int((p.z + ext) * k)) + 1):
		for x in range(maxi(0, int((p.x - ext) * k)), mini(HRES - 1, int((p.x + ext) * k)) + 1):
			var px := (x + 0.5) / k - p.x
			var pz := (z + 0.5) / k - p.z
			var lx := px * c - pz * s
			var lz := px * s + pz * c
			if absf(lx) < size.x * 0.5 and absf(lz) < size.y * 0.5:
				himg.set_pixel(x, z, Color(0, 0, 0, 1))
	_hmark(int((p.x - ext) * k), int((p.z - ext) * k), int((p.x + ext) * k), int((p.z + ext) * k))

func ground_h(p: Vector3) -> float:
	var k := float(HRES) / G.MAP
	var x := clampi(int(p.x * k), 0, HRES - 1)
	var z := clampi(int(p.z * k), 0, HRES - 1)
	return himg.get_pixel(x, z).r

func make_water() -> void:
	if not has_water:
		return
	water = Node3D.new()
	water.position = Vector3(0, WATER_Y, 0)
	add_child(water)
	water_mat = ShaderMaterial.new()
	water_mat.shader = load("res://shaders/water.gdshader")
	water_mat.set_shader_parameter("wave_n", _noise_tex(256, 0.03, 3, FastNoiseLite.FRACTAL_FBM, true, 6.0, 77))
	var fnt := _noise_tex(256, 0.05, 3, FastNoiseLite.FRACTAL_RIDGED, false, 0.0, 91)
	water_mat.set_shader_parameter("foam_tex", fnt)
	water_mat.set_shader_parameter("shallow", biome["water_shallow"])
	water_mat.set_shader_parameter("deep", biome["water_deep"])
	water_mat.set_shader_parameter("clarity", biome["clarity"])
	var mi := Image.create(HRES, HRES, false, Image.FORMAT_L8)
	var kk := float(HRES) / G.MAP
	for rc in wet_rects:
		var r2: Rect2 = rc
		for z in range(maxi(0, int(r2.position.y * kk)), mini(HRES, int(r2.end.y * kk) + 1)):
			for x in range(maxi(0, int(r2.position.x * kk)), mini(HRES, int(r2.end.x * kk) + 1)):
				if himg.get_pixel(x, z).r < -0.05:
					mi.set_pixel(x, z, Color(1, 1, 1))
	water_mat.set_shader_parameter("river_mask", ImageTexture.create_from_image(mi))
	water_mat.set_shader_parameter("map_size", G.MAP)
	# su yüzeyi yalnız nehir boyunca şerit örgüler (eskiden harita boyu tek düzlem; 8 km'de tüm ekranda
	# kırılma gölgelendiricisi çalışırdı). Köşe rengi: akış yönü (rg) ve şerit kesiti (b) — akıntı nehri izler
	for rv in _rivers:
		for m in _river_ribbons(rv[0], rv[1]):
			var w := MeshInstance3D.new()
			w.mesh = m
			w.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
			w.material_override = water_mat
			water.add_child(w)
	# suyun altında kalan yerleri ızgarada geçilmez yap
	var cells: Array = []
	for rc in wet_rects:
		var r3: Rect2 = rc
		for z in range(maxi(0, int(r3.position.y / Grid.CS)), mini(Grid.N, int(r3.end.y / Grid.CS) + 1)):
			for x in range(maxi(0, int(r3.position.x / Grid.CS)), mini(Grid.N, int(r3.end.x / Grid.CS) + 1)):
				var i := z * Grid.N + x
				if G.grid.water[i] == 1:
					continue
				var p := Vector3((x + 0.5) * Grid.CS, 0, (z + 0.5) * Grid.CS)
				if ground_h(p) < -0.32:
					G.grid.water[i] = 1
					cells.append(i)
	G.grid.refresh(cells)

# nehir şeridi: yatağı ve şevi örten, ~400 m'lik parçalara bölünmüş (görüş kesimi) örgüler
func _river_ribbons(pts: PackedVector3Array, width: float) -> Array:
	var out: Array = []
	var half := width * 0.5 + 3.0
	var n := pts.size()
	if n < 2:
		return out
	var along := 0.0
	var seg := 200
	var i0 := 0
	while i0 < n - 1:
		var i1 := mini(i0 + seg, n - 1)
		var vs := PackedVector3Array()
		var cs := PackedColorArray()
		var uv := PackedVector2Array()
		var idx := PackedInt32Array()
		for i in range(i0, i1 + 1):
			var p := pts[i]
			var t := pts[mini(i + 1, n - 1)] - pts[maxi(i - 1, 0)]
			t.y = 0.0
			t = t.normalized() if t.length() > 0.001 else Vector3.RIGHT
			var side := Vector3(-t.z, 0, t.x)
			if i > i0:
				along += p.distance_to(pts[i - 1])
			for sg in [-1.0, 1.0]:
				vs.append(Vector3(p.x, 0, p.z) + side * half * sg)
				cs.append(Color(t.x * 0.5 + 0.5, t.z * 0.5 + 0.5, 0.5 + 0.5 * sg, 1.0))
				uv.append(Vector2(along, sg))
			if i < i1:
				var b := (i - i0) * 2
				idx.append_array(PackedInt32Array([b, b + 2, b + 1, b + 1, b + 2, b + 3]))
		var arr := []
		arr.resize(Mesh.ARRAY_MAX)
		arr[Mesh.ARRAY_VERTEX] = vs
		var nr := PackedVector3Array()
		nr.resize(vs.size())
		nr.fill(Vector3.UP)
		arr[Mesh.ARRAY_NORMAL] = nr
		arr[Mesh.ARRAY_COLOR] = cs
		arr[Mesh.ARRAY_TEX_UV] = uv
		arr[Mesh.ARRAY_INDEX] = idx
		var am := ArrayMesh.new()
		am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
		out.append(am)
		i0 = i1
	return out

# ------------------------------------------------------------ boyama
func _px(v: float) -> int:
	return int(v / G.MAP * RES)

func paint_circle(p: Vector3, r: float, ch: int, amount: float, soft := true) -> void:
	var cx := p.x / G.MAP * RES
	var cz := p.z / G.MAP * RES
	var rp := r / G.MAP * RES
	var x0 := maxi(0, int(cx - rp))
	var x1 := mini(RES - 1, int(cx + rp))
	var z0 := maxi(0, int(cz - rp))
	var z1 := mini(RES - 1, int(cz + rp))
	for z in range(z0, z1 + 1):
		for x in range(x0, x1 + 1):
			var d := Vector2(x + 0.5 - cx, z + 0.5 - cz).length() / maxf(rp, 0.5)
			if d > 1.0:
				continue
			var a := amount * ((1.0 - d * d) if soft else 1.0)
			var c := img.get_pixel(x, z)
			c[ch] = clampf(maxf(c[ch], a) if soft else c[ch] + a, 0.0, 1.0)
			img.set_pixel(x, z, c)
	_mark(x0, z0, x1, z1)

func paint_line(a: Vector3, b: Vector3, w: float, ch: int, amount: float, jitter := 0.0, rng: RandomNumberGenerator = null) -> void:
	var L := a.distance_to(b)
	var step := maxf(0.3, w * 0.35)
	var n := int(L / step) + 1
	for i in n + 1:
		var p := a.lerp(b, float(i) / n)
		if jitter > 0.0 and rng != null:
			p += Vector3(rng.randf_range(-jitter, jitter), 0, rng.randf_range(-jitter, jitter))
		paint_circle(p, w * 0.5, ch, amount)

# p yolda mı (arazi boya dokusunun kırmızı kanalı = yol, road_polyline ile boyanır)
func on_road(p: Vector3) -> bool:
	var x := _px(p.x)
	var z := _px(p.z)
	if x < 0 or z < 0 or x >= RES or z >= RES:
		return false
	return img.get_pixel(x, z).r > 0.5

# palet / teker izi (roadmap 23): çamurda (yağmur) daha derin; iklime göre silinir — çölde kum rüzgârla
# ~2,5 dk'da, ılıman arazide ~8 dk'da örter; karda iz kalıcıdır, yalnız kar fırtınası örter.
# Silinme: damga halkası (konum + zaman) tutulur, yaşlanan damgalar kademeli soldurulur (tüm doku taranmaz).
var _trk: Array = []          # [x, z, zaman] — zaman sırasıyla eklenir; baştan (en eski) işlenir
var _trk_h := 0
var _trk_t := 0.0

func track(p: Vector3, amount := 0.35) -> void:
	var x := _px(p.x)
	var z := _px(p.z)
	if x < 0 or z < 0 or x >= RES or z >= RES:
		return
	if G.weather != null and is_instance_valid(G.weather) and G.weather.kind in ["rain", "storm"]:
		amount *= 1.4
	var c := img.get_pixel(x, z)
	c.g = minf(1.0, c.g + amount)
	img.set_pixel(x, z, c)
	_mark(x, z, x, z)
	_trk.append([x, z, G.time])
	if _trk.size() - _trk_h > 60000:
		_trk_h += 1          # kalıcı izde (kar) kayıt sınırsız büyümesin; iz dokuda kalır
		if _trk_h > 8000:
			_trk = _trk.slice(_trk_h)
			_trk_h = 0

func _track_fade_age() -> float:
	var wk: String = G.weather.kind if G.weather != null and is_instance_valid(G.weather) else "clear"
	if kind == "winter":
		return 200.0 if wk == "snowstorm" else INF
	if kind == "desert":
		return 70.0 if wk == "sandstorm" else 150.0
	return 300.0 if wk in ["rain", "storm"] else 480.0

func _track_fade() -> void:
	var age := _track_fade_age()
	if age == INF or _trk_h >= _trk.size():
		return
	var now := G.time
	var n := 0
	while _trk_h < _trk.size() and n < 3000:
		var s: Array = _trk[_trk_h]
		if now - float(s[2]) < age:
			break
		_trk_h += 1
		n += 1
		var x: int = s[0]
		var z: int = s[1]
		var c := img.get_pixel(x, z)
		c.g = maxf(0.0, c.g - 0.18)
		img.set_pixel(x, z, c)
		_mark(x, z, x, z)
		if c.g > 0.02:
			_trk.append([x, z, now - age * 0.75])     # kalan iz biraz sonra yine solar
	# işlenmiş baş kısmı at (dizi büyümesin)
	if _trk_h > 8000:
		_trk = _trk.slice(_trk_h)
		_trk_h = 0

func road_polyline(pts: PackedVector3Array, w: float, rng: RandomNumberGenerator) -> void:
	for i in pts.size() - 1:
		var a := pts[i]
		var b := pts[i + 1]
		paint_line(a, b, w, 0, 0.95, 0.25, rng)
		var d := (b - a).normalized()
		var side := Vector3(-d.z, 0, d.x)
		for s in [-0.95, 0.95]:
			paint_line(a + side * s, b + side * s, 0.6, 1, 0.55, 0.12, rng)
		for s in [-w * 0.42, w * 0.42]:
			paint_line(a + side * s, b + side * s, 0.5, 1, 0.22, 0.3, rng)

func patch_blob(p: Vector3, r: float, amount := 1.0) -> void:
	paint_circle(p, r, 3, amount)

# ------------------------------------------------------------ küçük ayrıntılar
func scatter(rng: RandomNumberGenerator) -> void:
	# çakıl/taş: kaya modelinin düşük çözünürlüklü çeşitleri (kırık yüzlü, dokulu)
	var winter: bool = biome["winter"]
	var n := int(1400 * clampf(G.MAP * G.MAP / (256.0 * 256.0), 1.0, 6.0))
	for v in 4:
		_mm(Props.rock_mesh(10 + v, winter, false, 1), n / 4, rng, 0.08, 0.26)

func _mm(mesh: Mesh, n: int, rng: RandomNumberGenerator, s0: float, s1: float) -> void:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	var xs: Array = []
	var tries := 0
	while xs.size() < n and tries < n * 4:
		tries += 1
		var p := Vector3(rng.randf_range(2, G.MAP - 2), 0, rng.randf_range(2, G.MAP - 2))
		if G.grid.height_at(p) > 0.05 or ground_h(p) < -0.1:
			continue
		var c := img.get_pixel(_px(p.x), _px(p.z))
		if c.r > 0.3:
			continue
		var s := rng.randf_range(s0, s1)
		xs.append(Transform3D(Basis(Vector3.UP, rng.randf() * TAU).scaled(Vector3(s, s, s)), p))
	mm.instance_count = xs.size()
	for i in xs.size():
		mm.set_instance_transform(i, xs[i])
	var m := MultiMeshInstance3D.new()
	m.multimesh = mm
	m.add_to_group("zoom_small")
	add_child(m)
