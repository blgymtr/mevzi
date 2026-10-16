class_name Vehicle extends Unit
# Araçlar: tank, ZPT, makineli pikap, ikmal kamyonu.

const DEF := {
	"tank": {"title": "Tank", "hp": 900.0, "armor": 2, "speed": 6.2, "accel": 2.5, "turn": 0.75, "radius": 2.7, "len": 6.2, "nav": Grid.M_HEAVY, "sight": 50.0, "cap": 4, "tturn": 0.85, "icon": "tank"},
	"apc": {"title": "ZPT", "hp": 450.0, "armor": 1, "speed": 9.5, "accel": 3.5, "turn": 1.0, "radius": 2.5, "len": 7.2, "nav": Grid.M_HEAVY, "sight": 48.0, "cap": 3, "tturn": 1.8, "icon": "apc"},
	"technical": {"title": "Teknik Araç", "hp": 170.0, "armor": 0, "speed": 13.0, "accel": 5.0, "turn": 1.4, "radius": 1.9, "len": 5.0, "nav": Grid.M_LIGHT, "sight": 46.0, "cap": 2, "tturn": 3.0, "icon": "tech"},
	"heli": {"title": "Saldırı Helikopteri", "hp": 650.0, "armor": 1, "speed": 17.0, "accel": 6.0, "turn": 1.4, "radius": 3.6, "len": 11.0, "nav": Grid.M_LIGHT, "sight": 62.0, "cap": 5, "tturn": 0.0, "icon": "heli"},
	"ifv": {"title": "Piyade Savaş Aracı", "hp": 620.0, "armor": 1, "speed": 8.0, "accel": 3.0, "turn": 0.9, "radius": 2.6, "len": 6.8, "nav": Grid.M_HEAVY, "sight": 50.0, "cap": 3, "tturn": 1.5, "icon": "apc"},
	"aa": {"title": "Uçaksavar", "hp": 480.0, "armor": 1, "speed": 7.5, "accel": 2.8, "turn": 0.9, "radius": 2.6, "len": 6.6, "nav": Grid.M_HEAVY, "sight": 70.0, "cap": 3, "tturn": 2.4, "icon": "aa"},
	"arty": {"title": "Kundağı Motorlu Obüs", "hp": 420.0, "armor": 1, "speed": 6.0, "accel": 2.2, "turn": 0.7, "radius": 2.8, "len": 7.0, "nav": Grid.M_HEAVY, "sight": 34.0, "cap": 4, "tturn": 0.6, "icon": "arty"},
	"transport": {"title": "Nakliye Helikopteri", "hp": 520.0, "armor": 1, "speed": 20.0, "accel": 6.0, "turn": 1.3, "radius": 4.0, "len": 12.0, "nav": Grid.M_LIGHT, "sight": 50.0, "cap": 3, "tturn": 0.0, "icon": "heli"},
	"uav": {"title": "Keşif İHA", "hp": 120.0, "armor": 0, "speed": 14.0, "accel": 4.0, "turn": 0.8, "radius": 2.6, "len": 6.0, "nav": Grid.M_LIGHT, "sight": 85.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"uav_armed": {"title": "Silahlı İHA", "hp": 180.0, "armor": 0, "speed": 15.0, "accel": 4.0, "turn": 0.7, "radius": 3.0, "len": 8.0, "nav": Grid.M_LIGHT, "sight": 80.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"loiter": {"title": "Kamikaze İHA", "hp": 30.0, "armor": 0, "speed": 24.0, "accel": 14.0, "turn": 3.0, "radius": 0.8, "len": 1.5, "nav": Grid.M_LIGHT, "sight": 50.0, "cap": 0, "tturn": 0.0, "icon": "fpv", "air": true},
	"fpv": {"title": "FPV Drone", "hp": 22.0, "armor": 0, "speed": 21.0, "accel": 16.0, "turn": 4.0, "radius": 0.6, "len": 0.5, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 0, "tturn": 0.0, "icon": "fpv"},
	"fieldgun": {"title": "Sahra Topu", "hp": 360.0, "armor": 0, "speed": 1.6, "accel": 1.5, "turn": 0.6, "radius": 1.6, "len": 4.0, "nav": Grid.M_LIGHT, "sight": 40.0, "cap": 3, "tturn": 0.7, "icon": "arty"},
	"howitzer": {"title": "Çekili Obüs", "hp": 380.0, "armor": 0, "speed": 1.1, "accel": 1.0, "turn": 0.45, "radius": 2.0, "len": 5.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 3, "tturn": 0.45, "icon": "arty"},
	"atgun": {"title": "Tanksavar Topu", "hp": 300.0, "armor": 0, "speed": 1.5, "accel": 1.5, "turn": 0.7, "radius": 1.5, "len": 4.0, "nav": Grid.M_LIGHT, "sight": 44.0, "cap": 3, "tturn": 0.8, "icon": "arty"},
	"aagun": {"title": "Uçaksavar Topu", "hp": 260.0, "armor": 0, "speed": 1.7, "accel": 1.6, "turn": 0.8, "radius": 1.6, "len": 3.6, "nav": Grid.M_LIGHT, "sight": 62.0, "cap": 2, "tturn": 2.6, "icon": "aa"},
	"hmortar": {"title": "Ağır Havan", "hp": 200.0, "armor": 0, "speed": 1.3, "accel": 1.4, "turn": 1.0, "radius": 1.2, "len": 2.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 2, "tturn": 1.2, "icon": "arty"},
	"mtngun": {"title": "Dağ Topu", "hp": 240.0, "armor": 0, "speed": 2.3, "accel": 2.0, "turn": 0.9, "radius": 1.3, "len": 3.0, "nav": Grid.M_LIGHT, "sight": 34.0, "cap": 2, "tturn": 0.9, "icon": "arty"},
	"mlrs": {"title": "Roketatar", "hp": 320.0, "armor": 0, "speed": 10.0, "accel": 3.0, "turn": 1.0, "radius": 2.3, "len": 7.0, "nav": Grid.M_LIGHT, "sight": 32.0, "cap": 4, "tturn": 0.6, "icon": "arty"},
	"truck": {"title": "İkmal Kamyonu", "hp": 160.0, "armor": 0, "speed": 10.0, "accel": 3.0, "turn": 1.0, "radius": 2.3, "len": 7.0, "nav": Grid.M_LIGHT, "sight": 30.0, "cap": 0, "tturn": 0.0, "icon": "truck"},
}

var vtype := "tank"
var D: Dictionary
var hull: Node3D
var hull_mi: MeshInstance3D
var turret: Node3D
var barrel: Node3D
var wheels: Array = []
var gunner: SoldierBody
var M: Dictionary
var armor := 0
var ext := Vector2(1.5, 3.0)   # zemin izi yarı boyutları (genişlik, uzunluk) — modelden
var escorts: Array = []        # aracı izleyen piyade (Soldier.cmd_follow_vehicle); araç onların yürüyüşüne uyar
var deployed := 1.0       # topçu kurulum durumu: 1 kurulu (ateşe hazır), 0 toplanmış (yürüyüşe hazır)
var vid := ""            # katalog kimliği (boşsa taban araç)
# gerçek performans (data/real_perf.json, roadmap 2): yol hızı, ana silah dolumu, otomatik top, salvo
var road_speed := -1.0     # yolda azami hız (m/sn); <0: yol farkı yok
var reload_s := -1.0       # ana silah atış arası (sn); <0: tipin varsayılanı
var rpm := -1.0            # otomatik top dakikada atım
var burst_n := 0
var salvo_n := 0           # roketatar salvosu (roket), aralık, yeniden dolum
var salvo_ival := 0.0
var rearm_s := 0.0
var _road_t := 0.0
var _on_road := false
# mühimmat (data/ammo.json, roadmap 6): zırh delici / patlayıcı / otomatik top mermisi kimliği
var ammo_ke := ""
var ammo_he := ""
var ammo_auto := ""
var cat: Dictionary = {}
# gerçek savaş verisi (data/real_combat.json, roadmap 49/50/51)
var cdat: Dictionary = {}
var rng: Dictionary = {}      # silah başına oyun menzili (m): main, atgm, auto, mg, rkt, aa, ind
var arm_tab: Array = []       # zırh (oyun birimi = 20 mm RHA), [[kinetik ön, yan, arka, üst], [HEAT ...]]
var fcs := 0.001              # atış kontrolü: mesafe başına dağılım (m/m)
var radar := 0.0              # hava hedefini algılama menzili (m)
var slat := false             # kafes zırh: RPG/HEAT'in bir kısmını boşa çıkarır
var aps_n := 0                # aktif koruma şarjı (Trophy / Afganit)
var cram_ammo := 20           # C-RAM angajman sayısı (Centurion)
var cram_cd := 0.0
var aps_cd := 0.0
var atgm_lock := 0.0          # güdümlü füze nişan/kilit süresi birikimi
var sam_lock := 0.0
var hf_lock := 0.0
# 4 yön x 2 tip zırh: [ön, yan, arka, üst] (kinetik / HEAT). Mayın alttan = üst değeri.
const ARMOR := {
	"tank": [[22, 8, 5, 3], [26, 11, 5, 3]],
	"ifv": [[8, 4, 3, 2], [10, 5, 3, 2]],
	"apc": [[5, 3, 2, 1], [6, 3, 2, 1]],
	"aa": [[6, 3, 2, 1], [7, 3, 2, 1]],
	"arty": [[4, 3, 2, 1], [5, 3, 2, 1]],
	"heli": [[2, 2, 2, 1], [2, 2, 2, 1]],
	"transport": [[1, 1, 1, 1], [1, 1, 1, 1]],
	"fieldgun": [[2, 0, 0, 0], [2, 0, 0, 0]],
	"atgun": [[2, 0, 0, 0], [2, 0, 0, 0]],
	"howitzer": [[1, 0, 0, 0], [1, 0, 0, 0]],
	"mtngun": [[1, 0, 0, 0], [1, 0, 0, 0]],
}
# silah delmesi (roadmap 51, gerçek ölçek: birim = 20 mm RHA): [tip 0=kinetik 1=HEAT, namlu önünde, 2 km'de,
# üstten saldırı]. Tüfek ~10 mm, 12,7 mm AP ~30 mm, RPG-7 ~500 mm, Kornet ~1200 mm, Javelin üstten.
# Mühimmata / füzeye özel değer varsa (Ammo tablosu, füze modeli) o kullanılır.
const PEN := {
	"bullet": [0, 0.5, 0.1, false], "sniper": [0, 0.9, 0.5, false], "hmg": [0, 1.5, 0.8, false], "auto": [0, 5.0, 3.5, false],
	"crush": [0, 0, 0, false], "melee": [0, 0, 0, false], "blast": [1, 1.5, 1.5, false],
	"ap": [0, 32, 29, false], "he": [1, 4, 4, false], "rpg": [1, 23, 23, false], "atgm": [1, 45, 45, false],
	"topatk": [1, 37.5, 37.5, true], "grenade": [1, 1, 1, false], "shell": [1, 3, 3, true], "big": [1, 6, 6, true],
	"mortar": [1, 2.5, 2.5, true], "mine": [0, 12, 12, true], "fpv": [1, 15, 15, true], "sam": [1, 12, 12, false],
}
const SIDE_NAME := ["ÖN", "YAN", "ARKA", "ÜST"]
static var shot_from := Vector3.INF
# mermiye özel delme (Ammo tablosu): [tür, yakın, 60 m+]; take_damage öncesi kurulur, bir kez kullanılır
static var shot_pen: Array = []
# kritik hasar (BA): 4 tür x 2 seviye (1 sarı, 2 kırmızı); mürettebat zamanla onarır
const CRIT_NAME := {"mob": "HAREKET", "opt": "OPTİK", "tgt": "NİŞAN", "load": "DOLUM", "eng": "MOTOR"}
var crit := {"mob": 0, "opt": 0, "tgt": 0, "load": 0, "eng": 0}
var crit_t := {"mob": 0.0, "opt": 0.0, "tgt": 0.0, "load": 0.0, "eng": 0.0}
# roadmap 3: birikimli yıpranma (0..1) — delen isabetlerle artar; hasar (en çok +%25) ve kritik olasılığını
# biraz büyütür (dengeli), istihkâm onarımıyla yavaşça azalır. Motor arızası: 1 → hız %60 + duman,
# 2 → motor durdu (yürüyemez, taret elle döner) + yangın olasılığı; mürettebat söndürür ya da yangın büyür.
var wear := 0.0
var eng_fire := 0.0          # motor yangını kalan süre (sn); söndürülmezse can kaybettirir
var _eng_fx_t := 0.0
var vstress := 0.0
var vstress_t := -99.0
var vstress_lv := 0
var _nopen_t := 0.0
var last_side := -1
var last_pen := 0.0
# öldüren isabet (roadmap 12): mühimmat türü ve geliş yönü imha biçimini belirler
var kill_k := ""
var kill_dir := Vector3.ZERO
var kill_over := 0.0          # öldüren isabetin fazlası (can 0'ın altına ne kadar indi) / azami can
var kill_mode := ""
# 94: taret kopması katı cisim olarak (DebrisBody); biçim vuruş yönü / mühimmat / imha türünden
var turret_mi: MeshInstance3D = null
var barrel_mi: MeshInstance3D = null
var turret_body: DebrisBody = null   # kopan taret (enkazla birlikte kalır)
var turret_style := ""               # pop, toss, flipback, lift, slide, vent (test ve günlük için)
var force_style := ""                # testler: biçimi zorla
var force_mode := ""                 # testler: imha türünü zorla
var force_gun_off := -1              # testler: namlu kopması (1 evet, 0 hayır)
var speed_max := 6.0
var cur_speed := 0.0
var heading := 0.0
var path := PackedVector3Array()
var path_i := 0
var dest := Vector3.ZERO
var order := ""
var force_move := false
var nav_mode := Grid.M_HEAVY
var target: Unit = null
var coax_target: Unit = null
var forced_target: Unit = null
var main_cd := 0.0
var coax_cd := 0.0
var burst := 0
var coax_burst := 0
var turret_yaw := 0.0
var recoil := 0.0
var tracks_broken := 0.0
var wreck := false
var engine: AudioStreamPlayer3D
var think_t := 0.0
var _crush_t := 0.0
var _track_acc := 0.0
var _dust_t := 0.0
var _stuck_t := 0.0
var _repath_ok := 0.0
var _scan_next := 0.0         # tam hedef taraması zamanı (hedef sürerken / boştayken seyrek)
var _last_pos := Vector3.ZERO
var shots := 0
var job: Dictionary = {}      # kamyon görevi (Logistics)
var rock := 0.0
var rock_v := 0.0
var burn_t := 0.0
const ALT := 9.0
const UAV_ALT := 13.0
# görsel irtifa ölçeği (roadmap 93): gerçek İHA kilometrelerce yukarıda uçar; oyunda 13–24 m'de gerçek boyutuyla
# "maket uçak" gibi dev görünür → kanat açıklığı yumuşak tavanla sıkıştırılarak çizilir (model ve boyut denetimi
# gerçek boyutta kalır): 4 m'ye kadar gerçek, üstü ×0,15 — MQ-9 20 m → ~6,4 m, RQ-4 40 m → ~9,4 m, Orlan 3 m aynı
const UAV_VIS_KNEE := 4.0
const UAV_VIS_SLOPE := 0.15
var uav_vis := 1.0
var uav_ang := 0.0
var missiles := 0
var missile_cd := 0.0
var rotor: Node3D
var trotor: Node3D
var hvel := Vector3.ZERO
var rocket_cd := 4.0
var salvo := 0
var salvo_t := 0.0
var _hb := 0.0
var cargo: Array = []
var operator = null
var atgm_cd := 8.0
var landing := false
var fire_mode := 0          # 0 serbest, 1 karşılık, 2 ateşi kes
var reverse := false
var retreating := false
var amove_dest := Vector3.INF
var smoke_charges := 2
var ground_pt := Vector3.ZERO
var ground_until := 0.0
const TRACKED := ["tank", "ifv", "aa", "arty"]
const WHEELED := ["technical", "apc", "truck", "mlrs"]
const CREWED := {"tank": 3, "ifv": 3, "aa": 3, "arty": 4, "apc": 2, "technical": 2, "truck": 1, "mlrs": 2}
var crew_max := 0
var crew_n := 0
var driver_ok := true
var gunner_ok := true
var tires := 0
var abandon_t := -1.0
var repair_body: SoldierBody = null
const TOWED := ["fieldgun", "howitzer", "atgun", "aagun", "hmortar", "mtngun"]
const INDIRECT := ["arty", "howitzer", "hmortar", "mtngun", "mlrs"]
var crew: Array = []
# roadmap 18: görünür mürettebat — kulede açık kapaktan bakan komutan (ateş altında içeri girer) ve açık
# bölmeli kundağı motorlu topçuda güvertede çalışan mürettebat
var cmdr: SoldierBody = null
var _cmdr_t := 0.0
var crew_deck := 0.0
var mlrs_left := 0
var mlrs_t := 0.0
const CAPACITY := {"apc": 8, "ifv": 6, "transport": 8, "tank": 4, "technical": 2}

# hava araçları: yere düşen yumuşak gölge — irtifa arttıkça büyür, dağılır, güneş yönünde kayar
var _shadow: Decal = null
static var _shadow_tex: Texture2D = null

# irtifa çizgisi (Broken Arrow gibi): havadaki aracın altındaki yer noktasından gövdeye ince, takım renkli dikey
# çizgi + yerde halka — eğik kamerada uçak yer konumundan uzakta çizildiği için nerede olduğu kaybolmasın.
# Birimin çocuğu: görünürlüğü (sis, tespit) birimle aynı.
var _alt_line: MeshInstance3D = null
var _alt_ring: MeshInstance3D = null

func _alt_line_tick(gp: Vector3, gh: float, alt: float) -> void:
	if _alt_line == null:
		var col: Color = G.TEAM_COL[team] if team >= 0 and team < G.TEAM_COL.size() else Color(0.9, 0.9, 0.85)
		var cm := CylinderMesh.new()
		cm.top_radius = 0.045
		cm.bottom_radius = 0.045
		cm.height = 1.0
		cm.radial_segments = 6
		cm.rings = 1
		_alt_line = MeshInstance3D.new()
		_alt_line.mesh = cm
		_alt_line.material_override = Mats.unshaded(Color(col.r, col.g, col.b, 0.42))
		_alt_line.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_alt_line)
		var tm := TorusMesh.new()
		tm.inner_radius = 0.86
		tm.outer_radius = 1.0
		tm.rings = 24
		tm.ring_segments = 4
		_alt_ring = MeshInstance3D.new()
		_alt_ring.mesh = tm
		_alt_ring.material_override = Mats.unshaded(Color(col.r, col.g, col.b, 0.5))
		_alt_ring.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		add_child(_alt_ring)
	var on := alive and alt > 2.0
	_alt_line.visible = on
	_alt_ring.visible = on
	if not on:
		return
	var base := to_local(Vector3(gp.x, gh, gp.z))
	_alt_line.position = base + Vector3(0, alt * 0.5, 0)
	_alt_line.scale = Vector3(1, maxf(alt - 0.6, 0.1), 1)
	var rr := clampf(ext.x * 0.5, 0.9, 3.0)
	_alt_ring.position = base + Vector3(0, 0.08, 0)
	_alt_ring.scale = Vector3(rr, 0.15, rr)

func _air_shadow_tick() -> void:
	if _shadow == null:
		if _shadow_tex == null:
			var gr := Gradient.new()
			gr.set_color(0, Color(0, 0, 0, 1))
			gr.set_color(1, Color(0, 0, 0, 0))
			gr.add_point(0.55, Color(0, 0, 0, 0.75))
			var gt := GradientTexture2D.new()
			gt.gradient = gr
			gt.fill = GradientTexture2D.FILL_RADIAL
			gt.fill_from = Vector2(0.5, 0.5)
			gt.fill_to = Vector2(0.5, 0.0)
			gt.width = 128
			gt.height = 128
			_shadow_tex = gt
		_shadow = Decal.new()
		_shadow.texture_albedo = _shadow_tex
		_shadow.cull_mask = 1
		_shadow.upper_fade = 0.2
		_shadow.lower_fade = 0.2
		G.world.add_child(_shadow)
		tree_exiting.connect(func(): if is_instance_valid(_shadow): _shadow.queue_free())
	var gp := hull.global_position
	var gh := G.terrain.ground_h(gp)
	var alt := maxf(gp.y - gh, 0.0)
	_alt_line_tick(gp, gh, alt)
	var sd := Vector3(0.35, 0, 0.2) * alt      # güneş eğimi: yükseldikçe gölge kayar
	_shadow.global_position = Vector3(gp.x + sd.x, gh + 1.0, gp.z + sd.z)
	_shadow.rotation.y = hull.global_rotation.y
	var spread := 1.0 + alt * 0.035
	var hs := hull.scale.x
	_shadow.size = Vector3(minf(ext.x, 2.2) * 2.0 * spread * hs, 4.0, ext.y * 1.9 * spread * hs)
	_shadow.modulate = Color(1, 1, 1, clampf(0.55 - alt * 0.015, 0.18, 0.5))
	_shadow.visible = visible and hull.visible

func is_air() -> bool:
	return vtype in ["heli", "transport", "fpv", "uav", "uav_armed", "loiter"]

# katalog biriminin gerçek boyut ölçeği: "scale": 1.18 (eşit) ya da [x, y, z] (eksen başına; sabit kanatlı
# İHA'da kanat açıklığı ve boy ayrı düzeltilir). Yoksa 1.
static func cat_scale(id: String) -> Vector3:
	Catalog.load_all()
	var s = Catalog.units.get(id, {}).get("scale", 1.0)
	if s is Array and (s as Array).size() == 3:
		return Vector3(float(s[0]), float(s[1]), float(s[2]))
	return Vector3.ONE * float(s)

func is_drone() -> bool:
	return vtype in ["fpv", "uav", "uav_armed", "loiter"]

# kapalı gövdeli hafif araçların gerçek yolcu yeri (sürücü / nişancı hariç) — taban tip "technical" (2) yerine
# (roadmap 98: M1301 ISV 9 kişilik ama 2 asker binebiliyordu); katalogda "seats" birime özel değeri geçersiz kılar
const SEATS_FAM := {"lv_isv": 8, "mrap6": 6, "mrap4": 4, "lv_hmmwv": 3, "lv_jltv": 3}

func capacity() -> int:
	if is_cargo():
		return 20 if heavy_lift() else 16
	if cat.has("seats"):
		return int(cat["seats"])
	var fam := String(cat.get("fam", ""))
	if SEATS_FAM.has(fam):
		return SEATS_FAM[fam]
	return CAPACITY.get(vtype, 0)

func is_cargo() -> bool:
	return M.get("meta", {}).get("cargo", false)

func heavy_lift() -> bool:
	return M.get("meta", {}).get("heavy_lift", false)

func crates_max() -> int:
	return 4 if heavy_lift() else 3

# askıya alınabilir mi: hafif araçlar ve çekili toplar; ağır kaldırıcı (Mi-26 tipi) ZPT/PSA da taşır
func can_sling(v) -> bool:
	if not is_cargo() or v == null or not is_instance_valid(v) or v == self or not (v is Vehicle) or not v.alive:
		return false
	if v.is_air() or v.team != team or v.slung_by != null:
		return false
	if v.vtype in TOWED or v.vtype in ["technical", "truck"]:
		return true
	return heavy_lift() and v.vtype in ["apc", "ifv", "aa"]

func cmd_sling(v: Vehicle) -> void:
	if sling != null or not can_sling(v):
		return
	sling_tgt = v
	drop_pt = Vector3.INF
	landing = false
	land_hold = false
	order = "move"
	dest = v.position
	path = PackedVector3Array([dest])
	path_i = 0
	say("YÜKÜ ALIYORUZ")

func cmd_airdrop(p: Vector3) -> bool:
	if not is_cargo() or crates <= 0:
		return false
	drop_pt = G.on_ground(p)
	sling_tgt = null
	landing = false
	land_hold = false
	order = "move"
	dest = drop_pt
	path = PackedVector3Array([dest])
	path_i = 0
	say("İKMAL YOLDA")
	return true

# yolcu almak için bulunduğu yere in ve bekle
func request_land() -> void:
	if not is_air() or landing or sling != null:
		return
	landing = true
	land_hold = true
	dest = G.on_ground(position)
	path = PackedVector3Array([dest])
	path_i = 0
	say("İNİŞE GEÇİYORUZ")

# binme/inme kapısı: zırhlılarda arka rampa/kapı, kamyonda arka kasa, helikopterde rampa/yan kapı
func entry_point(k := 0) -> Vector3:
	var side := ((k % 2) - 0.5) * 0.9
	if is_air():
		if is_cargo():
			return position - forward() * (ext.y + 0.8) + right() * side
		return position + right() * (ext.x + 0.9) * (1.0 if k % 2 == 0 else -1.0)
	return position - forward() * (ext.y + 0.7) + right() * side

func inside_point() -> Vector3:
	if is_air() and not is_cargo():
		return position
	return position - forward() * maxf(ext.y - 1.0, 0.3)

func can_load() -> bool:
	return alive and cargo.size() < capacity() and (not is_air() or hull.position.y < 2.5)

func riders_visible() -> bool:
	# açık kasalı pikap (technical) ve tank güvertesi; kapalı gövdeli hafif araçta yolcu içeride
	return vtype == "tank" or (vtype == "technical" and not SEATS_FAM.has(String(cat.get("fam", ""))))

func seat_pos(s) -> Vector3:
	var i := cargo.find(s)
	if vtype == "tank":
		var seats := [Vector3(-1.1, 1.55, 1.2), Vector3(1.1, 1.55, 1.2), Vector3(-1.1, 1.55, 2.4), Vector3(1.1, 1.55, 2.4)]
		return hull.global_transform * seats[clampi(i, 0, 3)]
	if vtype == "technical" and riders_visible():
		return hull.global_transform * Vector3(0.5 * (1 if i % 2 == 0 else -1), 1.0, 1.6)
	return position + Vector3(0, -50, 0)

func unload() -> void:
	if sling != null:
		sling_drop = true
		dest = G.on_ground(position)
		say("YÜK BIRAKILIYOR")
		return
	if cargo.is_empty():
		return
	if is_air() and hull.position.y > 1.2:
		landing = true
		say("İNİŞE GEÇİYORUZ")
		return
	var n := cargo.size()
	var back := -forward()
	var side := Vector3(-back.z, 0, back.x)
	for k in n:
		var s = cargo[0]
		if is_instance_valid(s):
			# kapıdan tek tek çıkar, sonra arkada yelpaze şeklinde açılır
			s.dismount(position + back * (D["len"] * 0.5 + 1.6) + side * ((k % 3) - 1) * 1.5 - back * (k / 3) * 1.3, self, k * 0.38)
		else:
			cargo.remove_at(0)
	landing = false
	say("İNDİR!")

func hook_pos() -> Vector3:
	var hk = M.get("meta", {}).get("hook", Vector3(0, 0.6, 0))
	var hv: Vector3 = hk if hk is Vector3 else Art.v3(hk)
	return hull.global_transform * hv

func _attach_sling(v: Vehicle) -> void:
	sling = v
	sling_tgt = null
	v.slung_by = self
	v.cmd_stop()
	v.sling_vel = Vector3.ZERO
	order = ""
	say("YÜK ALINDI")

func _release_sling() -> void:
	var v := sling
	sling = null
	sling_drop = false
	if v != null and is_instance_valid(v):
		v.slung_by = null
		v.position.y = G.terrain.ground_h(v.position)
		v.position = G.grid.nearest_free(v.position, v.nav_mode, 12)
		v.dest = v.position
		v.hull.rotation.x = 0.0
		v.hull.rotation.z = 0.0
		G.fx.vehicle_dust(v.position)
	say("YÜK BIRAKILDI")

func _drop_crate() -> void:
	drop_pt = Vector3.INF
	order = ""
	crates -= 1
	var pal := MeshInstance3D.new()
	pal.mesh = Building.cache_mesh()
	G.world.add_child(pal)
	pal.global_position = hook_pos()
	var gp := G.on_ground(position)
	var tw := pal.create_tween()
	tw.tween_property(pal, "global_position", gp, 2.2).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	var tm := team
	tw.tween_callback(func():
		pal.queue_free()
		var b: Building = G.main.place_building(tm, "cache", G.grid.nearest_free(gp, Grid.M_INF, 8), randf() * TAU)
		if b != null:
			b.complete()
			b.stock = 320.0
		G.fx.vehicle_dust(gp))
	say("İKMAL BIRAKILDI")

# askı halatı ve kayışlar + rampa + yerde palet yenileme
func _cargo_visuals(dt: float) -> void:
	if ramp:
		var open := hull.position.y < 0.6 and (landing or land_hold or (not cargo.is_empty() and cur_speed < 0.3))
		ramp_k = move_toward(ramp_k, 1.0 if open else 0.0, dt * 0.7)
		ramp.rotation.x = ramp_k * float(M.get("meta", {}).get("ramp_open", 1.0))
	if hull.position.y < 0.6 and crates < crates_max():
		for b in G.near(position, 26.0):
			if b is Building and b.team == team and b.btype in ["hq", "helipad", "fob"] and b.done:
				crates = crates_max()
				break
	if sling == null or not is_instance_valid(sling):
		for c in _cables:
			c.visible = false
		return
	if _cables.is_empty():
		var cm := CylinderMesh.new()
		cm.top_radius = 0.03
		cm.bottom_radius = 0.03
		cm.height = 1.0
		cm.radial_segments = 5
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(0.12, 0.12, 0.1)
		mat.roughness = 0.8
		for i in 5:
			var mi := MeshInstance3D.new()
			mi.mesh = cm
			mi.material_override = mat
			G.world.add_child(mi)
			_cables.append(mi)
		tree_exiting.connect(_free_cables)
	var hk := hook_pos()
	var top: Vector3 = sling.position + Vector3(0, sling.top_h + 1.2, 0)
	_seg(_cables[0], hk, top)
	var f := sling.forward()
	var r := sling.right()
	var k := 0
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			k += 1
			var corner: Vector3 = sling.position + Vector3(0, sling.top_h * 0.85, 0) + r * sx * sling.ext.x * 0.8 + f * sz * sling.ext.y * 0.75
			_seg(_cables[k], top, corner)

func _free_cables() -> void:
	for c in _cables:
		if is_instance_valid(c):
			c.queue_free()

static func _seg(mi: MeshInstance3D, a: Vector3, b: Vector3) -> void:
	mi.visible = true
	var d := b - a
	var L := maxf(d.length(), 0.01)
	var y := d / L
	var x := y.cross(Vector3.FORWARD if absf(y.z) < 0.9 else Vector3.RIGHT).normalized()
	var z := x.cross(y)
	mi.global_transform = Transform3D(Basis(x, y * L, z), (a + b) * 0.5)

# askıdaki araç: kancanın altında, gecikmeli salınım
func _slung_tick(dt: float) -> void:
	var h := slung_by
	if h == null or not is_instance_valid(h) or not h.alive:
		# helikopter düştü: yük serbest düşer
		slung_by = null
		var gy := G.terrain.ground_h(position)
		var fall := position.y - gy
		var tw := create_tween()
		tw.tween_property(self, "position:y", gy, clampf(sqrt(maxf(fall, 0.1) / 4.9), 0.2, 2.0)).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.tween_callback(func():
			G.fx.vehicle_dust(position)
			take_damage(max_hp * clampf(fall * 0.06, 0.1, 0.9), null, "blast"))
		return
	var want: Vector3 = h.hook_pos() - Vector3(0, SLING_L + top_h + 1.2, 0)
	var acc := (want - position) * 6.0 - sling_vel * 2.2
	sling_vel += acc * dt
	position += sling_vel * dt
	heading = lerp_angle(heading, h.heading, dt * 1.5)
	hull.rotation.y = heading
	hull.rotation.x = clampf(-sling_vel.dot(forward()) * 0.04, -0.25, 0.25)
	hull.rotation.z = clampf(sling_vel.dot(right()) * 0.04, -0.25, 0.25)
	cur_speed = 0.0

# yolcular ve üstte taşınanlar (87): imha türüne göre — güvertedeki askerler patlamayla savrulur (infilakta
# çoğu ölür, yanan araçtan atlayanlar yaralı/sersem), içerideki yolcular infilaktan kurtulamaz, yanan araçtan
# yaralı çıkar, yalnız hareketsiz kalan (knocked) araçtan çoğunlukla sağ iner
func _cargo_lost(mode := "") -> void:
	var violent := mode in ["catastrophic", "cookoff", "flip", "crash"]
	for s in cargo.duplicate():
		if not is_instance_valid(s) or not s.alive:
			continue
		if riders_visible() and mode != "crash" and s.has_method("throw_off"):
			var seat: Vector3 = seat_pos(s)
			cargo.erase(s)
			var away := Vector3(seat.x - position.x, 0.0, seat.z - position.z)
			away = away.normalized() if away.length() > 0.05 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
			s.position = seat
			var k := 1.15 if violent else 0.55
			var pd := 0.85 if mode == "catastrophic" else (0.6 if violent else 0.12)
			s.throw_off(away * randf_range(2.5, 5.5) * k + Vector3(0, randf_range(2.0, 3.8) * k, 0), pd, 0.7 if mode == "catastrophic" else 0.0)
			continue
		s.dismount(position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)))
		s.add_stress(65.0)
		var pdie := 0.95 if mode == "catastrophic" else (0.75 if mode in ["cookoff", "crash"] else (0.45 if mode in ["brew", "flip"] else (0.15 if mode == "knocked" else 0.5)))
		# top / havan mermisi, bomba, üstten saldırı ile yok olan araçtan sağ çıkmak çok az (roadmap 114);
		# zırhsız araçta (kamyon, pikap) patlayıcı isabet içeridekileri de öldürür
		if kill_k in ["shell", "big", "mortar", "topatk", "fpv"] and mode != "knocked":
			pdie = maxf(pdie, 0.92)
		elif armor == 0 and kill_k in ["rpg", "atgm", "he", "shell", "big", "mortar"]:
			pdie = maxf(pdie, 0.8)
		if randf() < pdie:
			s.die(null)
		elif mode != "knocked" or randf() < 0.4:
			s.take_damage(60.0, null, "blast")
	cargo.clear()
# çekili top / açık bölmeli obüs mürettebatı (süs gövdeleri) imhada yerinde çömelip kalıyordu (roadmap 99):
# her biri gerçek askere dönüşür ve patlamadan payını alır — savrulur, çoğu ölür, kalanı yaralı / sersem
func _crew_lost(mode: String) -> void:
	if crew.is_empty() or G.main == null:
		return
	var heavy_hit := kill_k in ["shell", "big", "mortar", "topatk", "fpv"] or mode in ["catastrophic", "cookoff"]
	for cb in crew:
		if not is_instance_valid(cb):
			continue
		var gp: Vector3 = (cb as Node3D).global_position
		gp.y = 0.0
		cb.queue_free()
		var s: Soldier = G.main.spawn_soldier(team, "crew", gp, null)
		if s == null:
			continue
		var away := Vector3(gp.x - position.x, 0.0, gp.z - position.z)
		away = away.normalized() if away.length() > 0.05 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		var k := 1.1 if heavy_hit else 0.6
		var pd := 0.85 if heavy_hit else (0.45 if mode != "knocked" else 0.15)
		s.throw_off(away * randf_range(2.0, 4.5) * k + Vector3(0, randf_range(1.6, 3.2) * k, 0), pd, 0.5 if heavy_hit else 0.0)
	crew.clear()
	_crew_spots.clear()

var rotor_blades: MeshInstance3D
var rotor_disc: MeshInstance3D
var props_n: Array = []        # İHA pervaneleri: [düğüm, yerel dönüş ekseni] (roadmap 8)
# rotor devri (0 durgun … 1 uçuş): kalkışta açılır, inişte rölantiye düşer, düşüşte söner. Ses perdesi ve
# pal görüntüsü bundan (roadmap 39/44, 22). Görüntü: paller hep görünür; kare başına dönüş, pal aralığının
# ~%38'iyle sınırlanır (yoksa düşük FPS'te paller geriye dönüyor ya da duruyor gibi görünür), üstte hafif bulanık disk.
var rotor_rpm := 0.0
var rotor_nb := 4
const ROTOR_W := 30.0          # tam devirde açısal hız (rad/sn, ~290 dev/dk)
# kargo helikopteri: arka rampa, askı yükü (araç), havadan ikmal paletleri
const SLING_L := 5.5
var ramp: Node3D = null
var ramp_k := 0.0
var land_hold := false          # yolcu almak için inip bekle (indirme yapma)
var sling: Vehicle = null       # askıdaki araç
var sling_tgt: Vehicle = null   # alınacak araç
var slung_by: Vehicle = null    # bu araç bir helikopterin askısında
var sling_drop := false
var sling_vel := Vector3.ZERO
var drop_pt := Vector3.INF      # havadan ikmal noktası
var crates := 0
var top_h := 2.0
var _cables: Array = []
var station = null              # İHA: bağlı yer istasyonu (DroneStation)
var high_alt := false           # yüksek irtifa keşif İHA'sı: geniş görüş, vurulması zor
var link_lost := false
var link_t := 0.0
var loiter_pt := Vector3.INF    # mini drone: hedef yoksa bu noktada asılı kalır
var battery := 70.0             # mini drone uçuş süresi (sn)
const HIGH_ALT := 24.0
# hava savunma füzesi / fişek / kaçış
var sams := 0
var sam_cd := 0.0
var sam_big := false
var sam_range := 0.0
var flares := 0
var flare_q := 0                # kuyruktaki fişek çifti
var flare_t := 0.0
var evade_t := 0.0
var evade_side := 1.0
var hf_left := 0                # helikopter güdümlü füzesi (Hellfire / Vikhr)
var hf_cd := 3.0
# saldırı helikopterinin atış konumu: hedefe göre yön + mesafe; görüş hattı kapalıysa (ağaç, bina)
# konum hedef çevresinde döndürülür ve mesafe daraltılır (yoksa helikopter aynı noktada sonsuza dek asılı kalırdı)
var atk_for: Unit = null
var atk_dir := Vector3.ZERO
var atk_r := 32.0
var atk_t := 0.0
var atk_n := 0
# halatla iniş (fast-rope) / halatla çekme (SPIES)
var rope_pt := Vector3.INF
var rope_mode := ""             # "down": asker indir, "up": asker al
var rope_t := 0.0
var rope_next := 0.0
var rope_side := 0
var ropes: Array = []           # [MeshInstance3D, yerel bağlantı noktası]
var rope_riders: Array = []     # halattaki askerler
const ROPE_ALT := 8.0
static var _disc_mat: ShaderMaterial

func setup(t: int, vt: String) -> void:
	team = t
	if Catalog.has(vt):
		vid = vt
		cat = Catalog.get_unit(vt)
		vt = Catalog.base(vt)
	vtype = vt
	kind = vt
	D = DEF[vt]
	if vid != "":
		D = D.duplicate()
		D["title"] = cat.get("name", D["title"])
		D["hp"] = float(cat.get("hp", D["hp"]))
		D["speed"] = float(cat.get("speed", D["speed"]))
		var pf := Catalog.perf(vid)
		var air_t: bool = vt in ["heli", "transport", "fpv", "uav", "uav_armed", "loiter"]
		if air_t and pf.has("cruise"):
			# gerçek seyir hızı (km/h) × hava ölçeği
			D["speed"] = float(pf["cruise"]) / 3.6 * Catalog.K_AIR
		elif float(pf.get("off", 0.0)) > 0.0:
			# gerçek arazi / yol hızı ve 0→32 km/h ivmesi × kara ölçeği
			D["speed"] = float(pf["off"]) / 3.6 * Catalog.K_GROUND
			road_speed = float(pf.get("road", pf["off"])) / 3.6 * Catalog.K_GROUND
			D["accel"] = (32.0 / 3.6 * Catalog.K_GROUND) / maxf(float(pf.get("acc", 8.0)), 1.0)
		else:
			# veri yoksa: ağır araç yavaş — ön zırh ve cana göre hız çarpanı
			var fa: float = float(cat["armor"][0][0]) if cat.has("armor") else 6.0
			D["speed"] *= clampf(1.15 - fa * 0.012 - float(D["hp"]) * 0.0002, 0.7, 1.1)
			D["accel"] = float(D["accel"]) * clampf(1.2 - float(D["hp"]) * 0.0005, 0.6, 1.2)
		reload_s = float(pf.get("reload", -1.0))
		rpm = float(pf.get("rpm", -1.0))
		burst_n = int(pf.get("burst", 0))
		salvo_n = int(pf.get("salvo", 0))
		salvo_ival = float(pf.get("ival", 0.0))
		rearm_s = float(pf.get("rearm", 0.0))
	cdat = Combat.vehicle(vid, vt)
	if not cdat.is_empty():
		if vid == "":
			D = D.duplicate()
		if cdat.has("hp"):
			D["hp"] = float(cdat["hp"])
		arm_tab = Combat.armor_units(cdat)
		rng = Combat.ranges(cdat)
		var on := String(cdat.get("opt", "day"))
		opt_k = Combat.optic(on)
		fcs = float({"th3": 0.0004, "th": 0.0006, "rad": 0.0007, "uav": 0.0006, "cl": 0.0006, "scope": 0.0008, "day": 0.0011, "bino": 0.0015}.get(on, 0.002))
		radar = float(cdat.get("radar", 0.0)) * Combat.K_RANGE
		slat = bool(cdat.get("slat", false))
		aps_n = 4 if bool(cdat.get("aps", false)) else 0
		# görüş (savaş sisi yarıçapı): açıktaki ayakta piyadeyi seçebileceği mesafe
		D["sight"] = Combat.detect_range(opt_k, 0.32)
	title = D["title"]
	max_hp = D["hp"]
	hp = max_hp
	armor = D["armor"]
	if not arm_tab.is_empty():
		# zırh sınıfı: 0 açık (kurşun işler), 1 hafif zırhlı, 2 ağır zırhlı (≥ 300 mm ön)
		armor = 0 if float(arm_tab[0][0]) < 0.5 else (2 if float(arm_tab[0][0]) >= 15.0 else 1)
	speed_max = D["speed"]
	radius = D["radius"]
	nav_mode = D["nav"]
	sight = D["sight"]
	cap_cost = D["cap"]
	icon = D["icon"]
	crew_max = CREWED.get(vt, 0)
	crew_n = crew_max
	var am := Ammo.for_vehicle(vid, vt, G.nation[t] if t >= 0 and t < G.nation.size() else "")
	ammo_ke = String(am.get("ke", ""))
	ammo_he = String(am.get("he", ""))
	ammo_auto = String(am.get("auto", ""))
	M = Art.vehicle_model(vid, t) if vid != "" and Art.has(vid) else Art.vehicle(vt, t)
	if M.is_empty() and vid == "":
		# taban tipin kendi modeli yoksa katalogdan aynı tabandaki bir birimin modeli
		# (keşif İHA'sı: katalogdaki ilk — en büyük, RQ-4 sınıfı — değil, küçük taktik sınıf)
		var alt := DroneStation.uav_id(t) if vt == "uav" else Catalog.first_of_base(vt, G.nation[t] if t >= 0 and t < G.nation.size() else "")
		if alt != "" and Art.has(alt):
			M = Art.vehicle_model(alt, t)
	if M.is_empty():
		M = VehicleModels.get_model(vt, t, G.map_kind == "winter")
	hull = Node3D.new()
	add_child(hull)
	if vid != "":
		# gerçek boyut düzeltmesi (data/real_dims.json → tools/size_audit.gd → katalog 'scale')
		hull.scale = cat_scale(vid)
	if M.has("hulls"):
		for hm in M["hulls"]:
			var hmi := MeshInstance3D.new()
			hmi.mesh = hm[0]
			hmi.position = hm[1]
			hull.add_child(hmi)
			if hull_mi == null:
				hull_mi = hmi
	else:
		hull_mi = MeshInstance3D.new()
		hull_mi.mesh = M["hull"]
		hull.add_child(hull_mi)
	if M["turret"] != null:
		turret = Node3D.new()
		turret.position = M["turret_pos"]
		hull.add_child(turret)
		var tmi := MeshInstance3D.new()
		tmi.mesh = M["turret"]
		turret.add_child(tmi)
		turret_mi = tmi
		barrel = Node3D.new()
		barrel.position = M["barrel_pos"]
		turret.add_child(barrel)
		var bmi := MeshInstance3D.new()
		bmi.mesh = M["barrel"]
		barrel.add_child(bmi)
		barrel_mi = bmi
	for w in M["wheels"]:
		var wn := MeshInstance3D.new()
		wn.mesh = w[3] if w.size() > 3 else VehicleModels.wheel(w[1], w[2])
		wn.position = w[0]
		hull.add_child(wn)
		wheels.append([wn, w[1]])
	if M.has("gunner"):
		gunner = SoldierBody.new()
		gunner.position = M["gunner"] - M["turret_pos"]
		turret.add_child(gunner)
		gunner.build(t, "rifle", G.map_kind == "winter")
		gunner.weapon.visible = false
	# açık kapakta komutan (tank, PSA, ZPT, uçaksavar, kapalı kundağı motorlu)
	if turret != null and M["turret"] != null and vt in ["tank", "ifv", "apc", "aa", "arty"] and cat.get("fam", "") != "spg_open":
		var ta: AABB = (M["turret"] as Mesh).get_aabb()
		if ta.size.y > 0.3:
			cmdr = SoldierBody.new()
			if M.get("meta", {}).has("hatch"):
				# modeldeki komutan kapağı: kapaktan beline kadar çıkmış (roadmap 97 — taret kutusunun tepesi antenle
				# yükseliyor, komutan tavanda tam boy ayakta görünüyordu)
				cmdr.position = Art.v3(M["meta"]["hatch"]) - M["turret_pos"] + Vector3(0, -1.05, 0)
			else:
				cmdr.position = Vector3(ta.position.x + ta.size.x * 0.68, ta.end.y - 1.08, ta.position.z + ta.size.z * 0.62)
			turret.add_child(cmdr)
			cmdr.build(t, "crew", G.map_kind == "winter")
			cmdr.weapon.visible = false
			cmdr.visible = false
	if cat.get("fam", "") == "spg_open":
		# açık bölmeli obüs (M110, M107, 2S7 Malka): güvertede nişancı ve doldurucu, yerde cephaneci
		crew_deck = 1.4 * hull.scale.y
		var dspots := [Vector3(-1.0, crew_deck, 1.7), Vector3(1.0, crew_deck, 1.5), Vector3(0.5, 0, ext.y + 1.4)]
		for i in 3:
			var cb2 := SoldierBody.new()
			cb2.position = dspots[i]
			hull.add_child(cb2)
			cb2.build(t, "crew", G.map_kind == "winter")
			cb2.weapon.visible = false
			crew.append(cb2)
	if vt in TOWED:
		# çekili top: yanında çömelmiş mürettebat
		var spots := [Vector3(-0.9, 0, 1.3), Vector3(0.9, 0, 1.1), Vector3(0.3, 0, 2.2)]
		for i in (2 if vt in ["hmortar", "mtngun", "aagun"] else 3):
			var cb := SoldierBody.new()
			cb.position = spots[i]
			cb.rotation.y = randf_range(-0.4, 0.4)
			hull.add_child(cb)
			cb.build(t, "rifle", G.map_kind == "winter")
			cb.weapon.visible = false
			crew.append(cb)
	if vt == "fpv":
		hull.position.y = 2.2
		Sfx.loop3d("drone", self, -6.0)
	if vt in ["uav", "uav_armed"]:
		# gerçek ölçek (eskiden görünürlük için 1,6 kat büyütülüyordu); görünürlüğü irtifa gölgesi sağlar
		hull.position.y = UAV_ALT
		var span := 0.0
		for mi in hull.get_children():
			if mi is MeshInstance3D and (mi as MeshInstance3D).mesh != null:
				span = maxf(span, (mi as MeshInstance3D).mesh.get_aabb().size.x * hull.scale.x)
		if span > UAV_VIS_KNEE:
			uav_vis = (UAV_VIS_KNEE + (span - UAV_VIS_KNEE) * UAV_VIS_SLOPE) / span
		hull.scale *= uav_vis
		uav_ang = randf() * TAU
		missiles = 4 if vt == "uav_armed" else 0
		Sfx.loop3d("drone", self, -14.0)
	if vt == "loiter":
		hull.position.y = 18.0
		Sfx.loop3d("drone", self, -8.0)
	_setup_air_defense(vt)
	if M.has("props"):
		for pr in M["props"]:
			var pn := Node3D.new()
			pn.position = pr[1]
			hull.add_child(pn)
			var pmi := MeshInstance3D.new()
			pmi.mesh = pr[0]
			pn.add_child(pmi)
			props_n.append([pn, Vector3.BACK if pr[2] == "y" else Vector3.UP])
	if vt in ["heli", "transport"]:
		hull.position.y = ALT
		rotor = Node3D.new()
		rotor.position = M["rotor_pos"]
		hull.add_child(rotor)
		var rmi := MeshInstance3D.new()
		rmi.mesh = M["rotor"]
		rotor.add_child(rmi)
		rotor_blades = rmi
		var disc := MeshInstance3D.new()
		var cm := CylinderMesh.new()
		var rr: float = M["rotor"].get_aabb().size.x * 0.5
		cm.top_radius = rr
		cm.bottom_radius = rr
		cm.height = 0.02
		cm.radial_segments = 32
		disc.mesh = cm
		disc.position.y = 0.3
		disc.material_override = _rotor_disc_mat()
		rotor_disc = disc
		disc.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		rotor.add_child(disc)
		rotor_nb = int(M.get("meta", {}).get("nb", 4))
		rotor_rpm = 1.0 if hull.position.y > 2.0 else 0.6
		trotor = Node3D.new()
		trotor.position = M["trotor_pos"]
		hull.add_child(trotor)
		var tmi2 := MeshInstance3D.new()
		tmi2.mesh = M["trotor"]
		trotor.add_child(tmi2)
		if M.has("ramp"):
			ramp = Node3D.new()
			ramp.position = M["ramp_pos"]
			hull.add_child(ramp)
			var rmi2 := MeshInstance3D.new()
			rmi2.mesh = M["ramp"]
			ramp.add_child(rmi2)
		if is_cargo():
			crates = crates_max()
	set_layer(self, 2)
	_calc_ext()
	# modeller gerçek boyutlu (roadmap 38, taban tipler base_models): gövde boyu modelden (önündeki engel,
	# iniş, enkaz, krater, egzoz yeri bununla)
	if not is_air() and ext.y * 2.0 > float(D["len"]) + 0.5:
		D = D.duplicate()
		D["len"] = ext.y * 2.0
	_calc_sig()
	heading = rotation.y
	rotation.y = 0.0
	hull.rotation.y = heading
	dest = position
	_last_pos = position
	think_t = randf() * 0.5
	if not is_drone() and not (vt in TOWED):
		engine = Sfx.loop3d("heli" if vt in ["heli", "transport"] else ("engine_tank" if vt in ["tank", "apc", "ifv", "aa", "arty"] else "engine_truck"), self, -8.0 if vt in ["heli", "transport"] else -10.0)

func _calc_ext() -> void:
	var a := AABB()
	var first := true
	for mi in _meshes(hull):
		# namlu taşması iz sayılmaz (piyade namlunun altından geçer; tank izi gövde + taret)
		if mi.mesh == null or mi == rotor_disc or (barrel != null and barrel.is_ancestor_of(mi)):
			continue
		# gövdeye göre tam dönüşüm zinciri (taret → namlu düğümleri)
		var t: Transform3D = mi.transform
		var pn: Node = mi.get_parent()
		while pn != null and pn != hull:
			if pn is Node3D:
				t = (pn as Node3D).transform * t
			pn = pn.get_parent()
		var bb: AABB = t * mi.mesh.get_aabb()
		a = bb if first else a.merge(bb)
		first = false
	if not first:
		# gövde ölçeği (gerçek boyut düzeltmesi) kapsama da yansısın
		a = Transform3D(Basis.from_scale(hull.scale), Vector3.ZERO) * a
		ext = Vector2(clampf(a.size.x * 0.5, 0.4, 3.0), clampf(a.size.z * 0.5, 0.4, 7.0))
		top_h = clampf(a.end.y - hull.position.y, 0.8, 5.0)

# izin (yönlü dikdörtgen) p'ye en yakın noktası — p içerideyse kendisi (istihkâm onarımı, yaklaşma)
func obb_closest(p: Vector3) -> Vector3:
	var d := p - position
	d.y = 0.0
	var f := forward()
	var r := right()
	return position + f * clampf(d.dot(f), -ext.y, ext.y) + r * clampf(d.dot(r), -ext.x, ext.x)

func right() -> Vector3:
	return Vector3(cos(heading), 0, -sin(heading))

# bir noktayı araç izinin (yönlü dikdörtgen) dışına iten vektör
func obb_push(p: Vector3, pad: float) -> Vector3:
	var d := p - position
	d.y = 0.0
	var f := forward()
	var r := right()
	var lx := d.dot(r)
	var lz := d.dot(f)
	var ex := ext.x + pad
	var ez := ext.y + pad
	if absf(lx) >= ex or absf(lz) >= ez:
		return Vector3.ZERO
	var px := ex - absf(lx)
	var pz := ez - absf(lz)
	if px < pz:
		return r * (px * signf(lx if lx != 0.0 else 1.0))
	return f * (pz * signf(lz if lz != 0.0 else 1.0))

# araç–araç çakışması: yönlü dikdörtgenlerde ayırıcı eksen (SAT) ile en küçük itme
func _sep_vehicles(dt: float) -> void:
	var blocked_now := false
	var push := Vector3.ZERO
	for o in G.near(position, radius + 8.0):
		if o == self or not (o is Vehicle) or o.is_air() or (not o.alive and not o.wreck):
			continue
		var d: Vector3 = o.position - position
		d.y = 0.0
		var axes := [forward(), right(), o.forward(), o.right()]
		var best := 1e9
		var bax := Vector3.ZERO
		var sep := false
		for ax in axes:
			var ra := absf(forward().dot(ax)) * ext.y + absf(right().dot(ax)) * ext.x
			var rb: float = absf(o.forward().dot(ax)) * o.ext.y + absf(o.right().dot(ax)) * o.ext.x
			var dist := absf(d.dot(ax))
			var ov: float = ra + rb + 0.15 - dist
			if ov <= 0.0:
				sep = true
				break
			if ov < best:
				best = ov
				bax = ax * (-1.0 if d.dot(ax) > 0.0 else 1.0)
		if sep:
			continue
		var other_static: bool = not o.alive or o.immobile() or absf(o.cur_speed) < 0.2
		var sgn := signf(cur_speed) if absf(cur_speed) > 0.05 else (-1.0 if reverse else 1.0)
		var wants_move := absf(cur_speed) > 0.3 or path_i < path.size()
		var ahead: bool = d.dot(forward()) * sgn > 0.0
		# araçlar birbirini itmez / yana kaydırmaz (roadmap 104: sıkışmada "saçılır gibi" yana kayıyorlardı):
		# öndekine yaklaşan yavaşlar / durur; duran araç önünü kesiyorsa sürerek yanından dolaşır
		if wants_move and ahead:
			if not other_static:
				# hareketli aracı takip et
				cur_speed = sgn * minf(absf(cur_speed), absf(o.cur_speed) * 0.9 + 0.3)
				continue
			cur_speed *= 0.85
			blocked_now = true
			_block_t += dt
			if _block_t > 1.5:
				_block_t = 0.0
				if not _detour_around(o) and o.alive and o.team == team and not o.immobile() and o.path_i >= o.path.size() and o.order != "hold":
					# yan yol yok (köprü, dar geçit): boşta bekleyen dost araç ileri çeker
					var fwd: Vector3 = o.forward() if o.forward().dot(o.position - position) > 0.0 else -o.forward()
					var pull: Vector3 = o.position + fwd * (o.ext.y + ext.y + 4.0)
					if o._cell_ok(pull) and G.grid.walkable_line(o.position, pull, o.nav_mode):
						o._repath(pull)
			# yanından sıyrıl (aşağıda toplam hız sınırıyla)
			push += right() * (-1.0 if d.dot(right()) > 0.0 else 1.0) * best
			continue
		# gerçek örtüşme (aynı noktada doğma, enkaz düşmesi; temas payı hariç): yavaşça açılır — kare başına
		# ışınlama değil; temas eden ama örtüşmeyen araç hiç itilmez
		if best <= 0.15:
			continue
		push += bax * (best - 0.15) * (1.0 if other_static else 0.5)
	# tüm komşulardan gelen itme toplanır ve karede bir kez, en çok 2,5 m/sn uygulanır — komşu başına ayrı
	# itme kalabalıkta katlanıp araçları saçıyordu (roadmap 104)
	if push != Vector3.ZERO:
		var np := position + push.normalized() * minf(push.length(), 2.5 * dt)
		if _cell_ok(np) and G.grid.height_at(np) < 0.3:
			position = np
	if not blocked_now:
		_block_t = 0.0

var _block_t := 0.0

# önünü kesen duran aracın yanına ara nokta: araç dönüp gerçekten sürerek dolaşır (ışınlanmaz)
func _detour_around(o: Vehicle) -> bool:
	if path_i >= path.size():
		return false
	var d: Vector3 = o.position - position
	d.y = 0.0
	var f := forward()
	var sd := Vector3(-f.z, 0, f.x)
	var off: float = o.ext.x + ext.x + 1.6
	for fo in [0.3, 1.0, 1.8]:
		for sgn in ([1.0, -1.0] if sd.dot(d) < 0.0 else [-1.0, 1.0]):
			var p: Vector3 = o.position + sd * off * sgn + f * (o.ext.y * fo)
			if _cell_ok(p) and G.grid.height_at(p) < 0.3 and G.grid.walkable_line(position, p, nav_mode):
				path.insert(path_i, p)
				return true
	return false

func forward() -> Vector3:
	return Vector3(-sin(heading), 0, -cos(heading))

# Araç piyadeyi asla itmez: gidiş şeridindeki dost (ve ezilmeyecek yavaşlıktaki düşman)
# askerler için yavaşlar/durur, askere kenara çekilmesini söyler; asker kendi yürüyerek açılır.
var _honk_t := 0.0
func _give_way(dt: float) -> void:
	_honk_t -= dt
	var dir := signf(cur_speed)
	var f := forward() * dir
	var r := right()
	var look := ext.y + 1.2 + absf(cur_speed) * 1.1
	var nearest := 1e9
	for o in G.near(position + f * (ext.y + look * 0.5), look * 0.5 + ext.x + 1.5):
		if not (o is Soldier) or not o.alive or o.state in ["aboard", "hospital"] or o.vehicle_in != null:
			continue
		if o.team != team and absf(cur_speed) > 2.0 and nav_mode == Grid.M_HEAVY:
			continue    # düşman piyade: paletli hızla gelir (ezme ayrı denetlenir)
		var d: Vector3 = o.position - position
		d.y = 0.0
		var lz := d.dot(f) - ext.y
		var lx := absf(d.dot(r))
		if lz < -ext.y * 2.0 or lz > look or lx > ext.x + 0.7:
			continue
		nearest = minf(nearest, maxf(lz, 0.0))
		o.give_way(self)
	if nearest > 1e8:
		return
	# 0.8 m'de tam dur, ileride kademeli yavaşla
	var vmax := clampf((nearest - 0.8) / 1.1, 0.0, 1.0) * speed_max
	if absf(cur_speed) > vmax:
		cur_speed = dir * vmax
		if vmax < 0.3 and _honk_t <= 0.0:
			_honk_t = 6.0
			if randf() < 0.5:
				say("YOLU AÇIN!")

func aim_point() -> Vector3:
	if is_air():
		return position + Vector3(0, hull.position.y + 0.6, 0)
	return position + Vector3(0, 1.3 if vtype != "technical" else 1.0, 0)

func turret_world_pos() -> Vector3:
	return hull.global_transform * (M["turret_pos"] as Vector3)

func muzzle_world() -> Vector3:
	if barrel == null:
		return aim_point()
	return barrel.global_transform * (M["muzzle"] as Vector3)

# ------------------------------------------------------------ emirler
func cmd_move(p: Vector3, force := false) -> void:
	if not alive:
		return
	order = "move"
	force_move = force
	forced_target = null
	reverse = false
	retreating = false
	amove_dest = Vector3.INF
	ground_until = 0.0
	dest = G.on_ground(p)
	landing = false
	land_hold = false
	sling_tgt = null
	sling_drop = false
	drop_pt = Vector3.INF
	if rope_pt != Vector3.INF and rope_riders.is_empty():
		_rope_reset()
	if is_air():
		path = PackedVector3Array([dest])
		path_i = 0
	else:
		dest = _free_dest(dest)
		_repath(dest)

# hedef yeri ayırma (roadmap 104): istenen noktada başka araç duruyorsa / oraya gidiyorsa yakındaki boş yer —
# araçlar aynı noktaya yığılıp birbirini itmez, yan yana park eder
func _free_dest(p: Vector3) -> Vector3:
	var others: Array = []
	# konumu ya da gittiği yer yakın olanlar (konvoyda öndeki araç henüz uzakta ama hedefi burada)
	for o in G.units:
		if o != self and is_instance_valid(o) and o is Vehicle and not o.is_air() and (o.alive or o.wreck):
			if Vector2(o.position.x - p.x, o.position.z - p.z).length() < 30.0 or Vector2(o.dest.x - p.x, o.dest.z - p.z).length() < 30.0:
				others.append(o)
	if others.is_empty():
		return p
	var step := radius * 2.0 + 1.5
	for ring in 4:
		var n := 1 if ring == 0 else 8
		for i in n:
			var a := TAU * i / n + ring * 0.4
			var c := p + Vector3(cos(a), 0, sin(a)) * step * ring
			if ring > 0 and (not _cell_ok(c) or not G.grid.free_at(c, nav_mode)):
				continue
			var ok := true
			for o in others:
				var need: float = (radius + o.radius) * 0.9
				var od: Vector3 = o.dest if (o.alive and o.path_i < o.path.size()) else o.position
				if Vector2(c.x - o.position.x, c.z - o.position.z).length() < need or Vector2(c.x - od.x, c.z - od.z).length() < need:
					ok = false
					break
			if ok:
				return c
	return p

# saldırı emri yapılabilir mi: silah bu hedefe hiç ateş edemiyorsa nedeni ("" = yapılabilir).
# Eskiden emir sessizce kabul ediliyor, araç hedefe bakıp sonsuza dek bekliyordu.
func _attack_block(u: Unit) -> String:
	var air: bool = u is Vehicle and u.is_air()
	if vtype in ["truck", "uav"]:
		return "SİLAHIM YOK"
	if crew_max > 0 and crew_n <= 0:
		return "MÜRETTEBAT YOK"
	if not gunner_ok:
		return "NİŞANCI YOK"
	if air and not (vtype in ["apc", "ifv", "technical", "heli", "aa", "aagun"]):
		return "HAVA HEDEFİNE ATEŞ EDEMEM"
	if vtype == "aagun" and (u is Building or (u is Vehicle and u.armor > 0)):
		return "ZIRHA ETKİSİZ"
	if vtype == "aa" and u is Building:
		return "YALNIZ HAVA HEDEFİ"
	return ""

# dolaylı atışlı topçunun asgari menzili (bunun içindeki hedefe ateş edemez)
func _min_range() -> float:
	# gerçekçi asgari menzil: havan ~100 m, obüs (yüksek açı) ~600 m, roketatar ~1,5 km (oyun ölçeğiyle)
	var r := 100.0 if vtype == "hmortar" else (1500.0 if vtype == "mlrs" else 600.0)
	if vid in ["rus_mlrs_tos"]:
		r = 400.0
	return r * Combat.K_RANGE if not rng.is_empty() else (18.0 if vtype == "hmortar" else 30.0)

func cmd_attack(u: Unit) -> void:
	if not alive:
		return
	var why := _attack_block(u)
	if why != "":
		if team == G.player_team and not G.spectate:
			say(why, 2.5)
		return
	forced_target = u
	order = "attack"
	var rng_w := _range()
	if dist2(u) > rng_w * 0.85:
		dest = u.position + (position - u.position).normalized() * rng_w * 0.7
		_repath(dest)

func cmd_stop() -> void:
	order = ""
	forced_target = null
	reverse = false
	retreating = false
	amove_dest = Vector3.INF
	ground_until = 0.0
	path = PackedVector3Array()
	dest = position

func cmd_attack_move(p: Vector3) -> void:
	cmd_move(p)
	order = "amove"
	amove_dest = dest

func cmd_reverse(p: Vector3) -> void:
	cmd_move(p)
	reverse = not is_air()

func cmd_hold() -> void:
	cmd_stop()
	order = "hold"

func cmd_retreat() -> void:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == team and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	if best == null:
		return
	var away := position - best.position
	away.y = 0
	cmd_move(best.position + (away.normalized() if away.length() > 0.1 else Vector3(1, 0, 0)) * (best.radius + 6.0), true)
	order = "retreat"
	retreating = true

func cmd_refund() -> void:
	if is_air():
		return
	cmd_retreat()
	if order == "retreat":
		order = "refund"

func _refund_check() -> void:
	if order != "refund":
		return
	for u in G.friends_near(position, 22.0, team):
		if u is Building and u.is_base() and u.done and position.distance_to(u.position) < u.radius + 9.0:
			var v := G.unit_value(self) * clampf(hp / max_hp, 0.0, 1.0) * 0.8
			for c in cargo:
				if is_instance_valid(c):
					v += G.unit_value(c) * 0.8
					c.queue_free()
			cargo.clear()
			G.supply[team] += v
			if team == G.player_team and not G.spectate:
				G.say(I18n.s("İade +%d") % int(v), position, team)
			alive = false
			G.remove_unit(self)
			queue_free()
			return

func has_smoke() -> bool:
	return vtype in ["tank", "apc", "ifv", "aa"]

func cmd_smoke() -> bool:
	if not alive or not has_smoke() or smoke_charges <= 0:
		return false
	smoke_charges -= 1
	var yaw := heading + turret_yaw
	var fwd := Vector3(-sin(yaw), 0, -cos(yaw))
	var side := Vector3(-fwd.z, 0, fwd.x)
	for k in 5:
		var p := position + fwd * 9.0 + side * (k - 2) * 3.4 - fwd * absf(k - 2) * 1.2
		var pp := p
		get_tree().create_timer(0.08 * k).timeout.connect(func():
			G.fx.smoke_screen(pp, 22.0)
			G.add_smoke(pp, 4.0, 23.0))
	Sfx.play3d("smoke_pop", position, 2.0)
	G.fx.muzzle(position + Vector3(0, 2.0, 0), fwd, false)
	return true

func can_ground_fire() -> bool:
	return vtype in ["tank", "apc", "ifv", "technical", "arty", "fieldgun", "howitzer", "atgun", "hmortar", "mtngun", "mlrs"]

func cmd_suppress(p: Vector3) -> void:
	if not alive or not can_ground_fire():
		return
	ground_pt = G.on_ground(p)
	ground_until = G.time + (24.0 if vtype in INDIRECT else 12.0)
	if order != "retreat":
		path = PackedVector3Array()
		order = ""

# yol bul; büyük haritada uzun yol iş parçacığında (o sırada hedefe doğru düz parça)
var path_req := 0

func _repath(to: Vector3) -> void:
	path_req += 1
	path_i = 0
	if G.grid.wants_async(position, to):
		path = G.grid.cached_path(position, to, nav_mode)
		if path.size() > 0:
			return
		if G.grid.direct(position, to, nav_mode):
			path = PackedVector3Array([G.grid.nearest_free(to, nav_mode)])
			return
		# sonuç gelene dek hedefe doğru engelsiz parça (boş olabilir: araç bekler)
		path = G.grid.provisional(position, to, nav_mode)
		G.grid.request_path(position, to, nav_mode, _on_path.bind(path_req))
		return
	path = G.grid.find_path(position, to, nav_mode)

func _on_path(res: PackedVector3Array, req: int) -> void:
	if req != path_req or not alive or order == "":
		return
	path = G.grid.splice(res, position, nav_mode)
	path_i = 0

func follow_route(pts: PackedVector3Array) -> void:
	path = pts
	path_i = 0
	order = "route"

# en uzun doğrudan atış silahının menzili (tarama yarıçapı); dolaylı atışlıda azami menzil
func _range() -> float:
	if rng.is_empty():
		return _range_old()
	if vtype in INDIRECT:
		return float(rng.get("ind", 0.0))
	var r := 0.0
	for k in ["main", "auto", "atgm", "mg", "rkt", "aa"]:
		r = maxf(r, float(rng.get(k, 0.0)))
	return r

# tek silahın menzili (veri yoksa eski tip menzili)
func _wr(k: String, def := -1.0) -> float:
	if rng.is_empty():
		return _range_old()
	if rng.has(k):
		return float(rng[k])
	return def if def >= 0.0 else 0.0

# ana silah bu hedefe bu mesafeden ateş edebilir mi
func _can_fire_at(t: Unit, dist: float) -> bool:
	var air: bool = t is Vehicle and t.is_air()
	match vtype:
		"tank", "fieldgun", "atgun":
			return dist <= _wr("main")
		"apc", "ifv":
			return dist <= maxf(_wr("auto"), _wr("mg"))
		"technical", "transport", "truck":
			return dist <= _wr("mg", 1000.0)
		"aa", "aagun":
			return dist <= (_wr("aa") if air else _wr("auto", _wr("mg")))
	if vtype in INDIRECT:
		return dist <= _wr("ind")
	return dist <= _range()

func _range_old() -> float:
	match vtype:
		"tank":
			return 58.0
		"apc":
			return 50.0
		"technical":
			return 46.0
		"heli":
			return 52.0
		"ifv":
			return 50.0
		"aa":
			return 72.0
		"arty":
			return 150.0
		"transport":
			return 30.0
		"fieldgun":
			return 64.0
		"howitzer":
			return 175.0
		"atgun":
			return 60.0
		"aagun":
			return 64.0
		"hmortar":
			return 110.0
		"mtngun":
			return 125.0
		"mlrs":
			return 180.0
	return 0.0

# ------------------------------------------------------------ döngü
func _process(dt: float) -> void:
	if not G.running or dt <= 0.0:
		return
	var th := Time.get_ticks_usec() if prof_on else 0
	tick_bubble(dt)
	if is_air():
		_air_shadow_tick()
	if slung_by != null and alive:
		_slung_tick(dt)
		return
	if not alive:
		_wreck_tick(dt)
		if prof_on:
			_pf("wreck", th)
		return
	main_cd -= dt * (0.5 if (crew_max >= 3 and crew_n == 1) else 1.0) / load_mult()
	_stress_tick(dt)
	if prof_on:
		th = _pf("head", th)
	coax_cd -= dt
	if abandon_t >= 0.0:
		abandon_t -= dt
		if abandon_t <= 0.0:
			say("İMHA!")
			destroy(null)
			return
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.45 + randf() * 0.15
		if not is_air() and G.grid.is_water(position):
			# suya düşmüş / köprü kenarından su hücresine taşmış: en yakın kuru zemine ya da köprüye
			var dry: Vector3 = G.grid.nearest_dry(position, 12.0)
			position = dry if dry != position else G.grid.nearest_free(position, nav_mode, 30)
		# emir yarıda kaldıysa (yol boşaldı ama hedefe varılmadı) yeniden yol bul
		if not is_air() and order in ["move", "amove", "retreat"] and path_i >= path.size() and dist2_p(dest) > 4.0 and not immobile() and G.time >= _repath_ok:
			# ulaşılamayan hedefte her düşünmede yeniden arama yapılmaz (3 sn ara)
			_repath_ok = G.time + 3.0
			_repath(dest)
		if prof_on:
			th = _pf("think_repath", th)
		var tq := Time.get_ticks_usec() if prof_on else 0
		_scan()
		if prof_on:
			_pf("scan", tq)
		_refund_check()
	atgm_cd -= dt
	sam_cd -= dt
	if flare_q > 0:
		_flares_tick(dt)
	if vtype in ["uav", "uav_armed"]:
		_uav(dt)
		return
	if vtype == "loiter":
		_fpv(dt)
		return
	if vtype == "fpv":
		_fpv(dt)
		return
	if vtype in ["heli", "transport"]:
		var tz := Time.get_ticks_usec() if prof_on else 0
		_heli(dt)
		if prof_on:
			_pf("heli", tz)
		return
	var t0 := Time.get_ticks_usec() if prof_on else 0
	_guard_drive(dt)
	if prof_on:
		t0 = _pf("guard", t0)
	_drive(dt)
	if prof_on:
		t0 = _pf("drive", t0)
	_sep_vehicles(dt)
	if prof_on:
		t0 = _pf("sep", t0)
	_aim_fire(dt)
	if prof_on:
		t0 = _pf("aim_fire", t0)
	_visuals(dt)
	if prof_on:
		_pf("visuals", t0)
	_cmdr_tick(dt)

# çalışma zamanı ölçümü (perf8k): bölüm başına toplam mikro saniye
static var prof := {}
static var prof_on := false
static func _pf(k: String, t0: int) -> int:
	var t1 := Time.get_ticks_usec()
	prof[k] = int(prof.get(k, 0)) + t1 - t0
	return t1

# tekerli mi (katalog ailesinden): lastikler patlar ve tamir edilir
func needs_setup() -> bool:
	return vtype in TOWED or vtype in ["arty", "mlrs"]

func pack_time() -> float:
	return {"howitzer": 9.0, "fieldgun": 5.0, "atgun": 4.0, "aagun": 4.0, "hmortar": 4.0, "mtngun": 5.0, "arty": 3.0, "mlrs": 4.0}.get(vtype, 4.0)

func deploy_time() -> float:
	return pack_time() * 1.2

func wheeled() -> bool:
	if vid != "":
		var fam: String = cat.get("fam", "")
		return not (fam.begins_with("mbt") or fam.contains("_tr") or fam in ["lt", "apc_box", "apc_amph", "apc_mtlb", "ifv_bmp", "ifv_bmd", "ifv_heavy", "bmpt", "td_box", "td_ontos", "spg", "spg_ru", "spg_open", "mortar_tr", "mlrs_t", "mlrs_tos", "eng_breach", "eng_dozer", "eng_bridge", "eng_recovery", "sam_ru_tr"]) and wheels.size() > 0
	return vtype in WHEELED

func tracked() -> bool:
	return not wheeled() and not is_air() and not (vtype in TOWED)

func immobile() -> bool:
	return crit["mob"] >= 2 or crit["eng"] >= 2 or tracks_broken > 0.0 or not driver_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0 or (wheeled() and tires >= maxi(wheels.size(), 4))

# piyade eskortu: araç arkasındaki piyadenin koşusuna uyar (koşudan biraz yavaş), geride kalanı bekler
func _escort_pace() -> float:
	var far := 0.0
	var n := 0
	for i in range(escorts.size() - 1, -1, -1):
		var s = escorts[i]
		if not is_instance_valid(s) or not s.alive or s.order != "follow_veh" or s.cover_veh != self:
			escorts.remove_at(i)
			continue
		if not s.can_fight():
			continue
		n += 1
		far = maxf(far, Vector2(s.position.x - position.x, s.position.z - position.z).length())
	if n == 0:
		return INF
	var gap: float = ext.y + 5.0
	if far > gap + 9.0:
		return 0.0
	return Soldier.RUN_SPEED * clampf(1.0 - (far - gap) / 9.0, 0.3, 0.85)

func speed_factor() -> float:
	var mud: float = G.weather.mud() if G.weather != null and wheeled() else 1.0
	return clampf(1.0 - 0.2 * tires, 0.3, 1.0) * (0.55 if crit["mob"] == 1 else 1.0) * (0.6 if crit["eng"] == 1 else 1.0) * mud

func has_crit() -> bool:
	for k in crit:
		if crit[k] > 0:
			return true
	return false

func load_mult() -> float:
	return [1.0, 1.6, 2.6][crit["load"]] * (1.3 if vstress_lv >= 1 else 1.0)

func aim_mult() -> float:
	return [1.0, 1.8, 3.0][crit["tgt"]] * (1.3 if vstress_lv >= 1 else 1.0)

func tturn_mult() -> float:
	return [1.0, 0.65, 0.35][crit["tgt"]]

func add_crit(k: String, lvl: int) -> void:
	if not alive or is_air():
		return
	crit[k] = mini(2, crit[k] + lvl)
	crit_t[k] = 22.0 if crit[k] == 1 else 40.0
	sight = D["sight"] * [1.0, 0.7, 0.4][crit["opt"]]
	say(I18n.s(CRIT_NAME[k]) + (" " + I18n.s("HASARLI!") if crit[k] == 1 else " " + I18n.s("KRİTİK!")), 2.5)

func _crit_roll(dmg: float, m: float, k: String) -> void:
	if crew_max <= 0 and ARMOR.get(vtype, []).is_empty():
		return
	var pen := m > 0.46
	var light_at := k in ["rpg", "atgm", "topatk", "fpv"]
	var ch := 0.0
	if pen:
		ch = 1.0 if light_at else 0.1 + dmg / max_hp * 1.2
	elif k in ["rpg", "atgm", "ap", "he", "shell", "big", "mortar", "topatk"]:
		ch = 0.2
	ch *= 1.0 + wear * 0.5
	if randf() >= ch:
		return
	var lvl := 2 if (pen and (dmg > max_hp * 0.2 or randf() < 0.3)) else 1
	var r := randf()
	var top := k in ["topatk", "shell", "big", "mortar", "fpv"]
	# arkadan (motor bölmesi) ve üstten gelen isabet motoru daha sık vurur
	var eng_ch := 0.45 if last_side == 2 else (0.25 if last_side == 3 else 0.1)
	var kk := "eng" if randf() < eng_ch else ("mob" if r < 0.3 else ("opt" if r < (0.65 if top else 0.55) else ("tgt" if r < 0.8 else "load")))
	add_crit(kk, lvl)
	if kk == "eng" and lvl >= 2 and pen and randf() < 0.4:
		eng_fire = 25.0
		say(I18n.s("MOTOR YANIYOR!"), 3.0)

func add_vstress(v: float) -> void:
	if crew_max <= 0 or is_air():
		return
	vstress = minf(100.0, vstress + v)
	vstress_t = G.time

func _stress_tick(dt: float) -> void:
	if vstress > 0.0 and G.time - vstress_t > 5.0:
		vstress = maxf(0.0, vstress - dt * 4.0)
	var nl := 2 if vstress >= 85.0 else (1 if vstress >= 50.0 else 0)
	if vstress_lv == 2 and vstress > 55.0:
		nl = 2
	if nl > vstress_lv:
		say("MÜRETTEBAT PANİKTE!" if nl == 2 else "MÜRETTEBAT SARSILDI!", 2.5)
		if nl == 2 and order != "retreat" and not immobile() and hp < max_hp * 0.6:
			cmd_retreat()
	vstress_lv = nl
	# kritik onarımı: mürettebat ateş altında değilken
	if crew_n > 0 and G.time - last_hit > 5.0:
		for k in crit:
			if crit[k] > 0:
				crit_t[k] -= dt
				if crit_t[k] <= 0.0:
					crit[k] -= 1
					crit_t[k] = 22.0
					sight = D["sight"] * [1.0, 0.7, 0.4][crit["opt"]]
					if crit[k] == 0:
						say(I18n.s(CRIT_NAME[k]) + " " + I18n.s("ONARILDI"), 2.0)

func needs_crew() -> bool:
	return alive and abandon_t < 0.0 and crew_max > 0 and (crew_n < crew_max or not driver_ok or not gunner_ok)

# piyade araca binip eksik mürettebatın yerine geçer
func add_crew(s) -> void:
	if not driver_ok:
		driver_ok = true
	elif not gunner_ok:
		gunner_ok = true
		if gunner:
			gunner.visible = true
	crew_n = mini(crew_max, crew_n + 1)
	say("MÜRETTEBAT TAMAM" if crew_n >= crew_max and driver_ok and gunner_ok else "YERİME GEÇTİ")
	if s != null and is_instance_valid(s):
		crew_out.erase(s)
		s.vanish()

# palet: mürettebat ateş altında değilken onarır (mühendis daha hızlı)
func _repair_tick(dt: float) -> void:
	_engine_tick(dt)
	# mürettebat dışarı çıkıp palet / motor onarır (ateş altında değilken): paletin yanında diz çöküp çekiçle,
	# motor bölmesinde (arka güverte) eğilerek; kıvılcım ve çekiç sesi
	var quiet := crew_n > 0 and G.time - last_hit > 7.0
	var work := ""
	if quiet and tracks_broken > 0.0:
		work = "track"
		tracks_broken -= dt
		if tracks_broken <= 0.0:
			tracks_broken = 0.0
			say("PALET ONARILDI")
	elif quiet and eng_fire <= 0.0 and crit["eng"] > 0:
		work = "engine"
	if work != "" and repair_body == null:
		repair_body = SoldierBody.new()
		hull.add_child(repair_body)
		repair_body.build(team, "engineer", G.map_kind == "winter")
		repair_body.set_tool("hammer")
		var sx := 1.0 if randf() < 0.5 else -1.0
		if work == "track":
			repair_body.position = Vector3(sx * (ext.x + 0.45), 0, ext.y * 0.35)
			repair_body.rotation.y = PI * 0.5 * sx
		else:
			repair_body.position = Vector3(sx * (ext.x + 0.4), 0, ext.y * 0.75)
			repair_body.rotation.y = PI * 0.5 * sx
	elif work == "" and repair_body != null:
		repair_body.queue_free()
		repair_body = null
	if repair_body:
		repair_body.animate(dt, "build" if work == "track" else "build_hi", 0.0)
		_eng_fx_t -= dt
		if _eng_fx_t <= 0.0:
			_eng_fx_t = randf_range(0.5, 1.1)
			var hp_w: Vector3 = repair_body.global_position + repair_body.global_transform.basis.z * -0.55 + Vector3(0, 0.5 if work == "track" else 1.2, 0)
			G.fx.sparks(hp_w, 0.5)
			Sfx.play3d("hammer", hp_w, -12.0, 0.15, 0.2)

# motor arızası: hasarlı motordan duman, yanan motorda alev; mürettebat söndürmeye çalışır
func _engine_tick(dt: float) -> void:
	if crit["eng"] <= 0 and eng_fire <= 0.0:
		return
	var rear: Vector3 = position - forward() * (D["len"] * 0.4) + Vector3(0, top_h * 0.8, 0)
	if eng_fire > 0.0:
		eng_fire -= dt * (1.6 if crew_n > 0 else 0.6)      # mürettebat yangın tüpüyle söndürür
		hp -= dt * max_hp * 0.006
		if randf() < dt * 6.0:
			G.fx.burn(rear, 0.6, 0.5)
		if hp <= 0.0:
			destroy(null)
			return
		if eng_fire <= 0.0:
			say(I18n.s("YANGIN SÖNDÜRÜLDÜ"), 2.0)
	if randf() < dt * (3.0 if crit["eng"] >= 2 else 1.5):
		G.fx.exhaust(rear, 1.4 if crit["eng"] >= 2 else 0.8)

# roadmap 11: mürettebat iner — araç sağlam kalır ama sürücüsüz yürüyemez, nişancısız ateş edemez; mürettebat
# ayrı askerler (tim) olarak aracın arkasında toplanır. "Mürettebat Bin" ile (ya da tankçılar araca sağ tıkla)
# geri biner; araca başka piyade de binip eksik mürettebatın yerine geçebilir.
var crew_out: Array = []

func cmd_dismount_crew() -> void:
	if not alive or crew_n <= 0 or is_air() or abandon_t >= 0.0:
		return
	unload()
	var sq := Squad.new(team, "Mürettebat")
	G.squads.append(sq)
	var back := -forward()
	var sd := Vector3(-back.z, 0, back.x)
	for i in crew_n:
		var p: Vector3 = position + back * (D["len"] * 0.5 + 1.0) + sd * (i - (crew_n - 1) * 0.5) * 1.3
		var s: Soldier = G.main.spawn_soldier(team, "crew", G.grid.nearest_free(p, Grid.M_INF), sq)
		s.home_vehicle = self
		s.cmd_move(G.grid.nearest_free(p + back * 3.0, Grid.M_INF))
		crew_out.append(s)
	crew_n = 0
	driver_ok = false
	gunner_ok = false
	if gunner:
		gunner.visible = false
	target = null
	coax_target = null
	path = PackedVector3Array()
	order = ""
	say("MÜRETTEBAT İNDİ", 2.5)

func cmd_mount_crew() -> void:
	crew_out = crew_out.filter(func(s): return is_instance_valid(s) and s.alive and s.can_fight() and s.vehicle_in == null)
	if crew_out.is_empty():
		say("MÜRETTEBAT YOK", 2.0)
		return
	for s in crew_out:
		s.cmd_board(self)
	say("MÜRETTEBAT BİNİYOR", 2.0)

func cmd_abandon() -> void:
	if not alive or crew_n <= 0 or abandon_t >= 0.0 or is_air():
		return
	unload()
	var sq := Squad.new(team, "Mürettebat")
	G.squads.append(sq)
	var back := -forward()
	var sd := Vector3(-back.z, 0, back.x)
	for i in crew_n:
		var p: Vector3 = position + back * (D["len"] * 0.5 + 1.0) + sd * (i - 1) * 1.3
		var s: Soldier = G.main.spawn_soldier(team, "crew", G.grid.nearest_free(p, Grid.M_INF), sq)
		s.cmd_move(G.grid.nearest_free(p + back * 6.0, Grid.M_INF), true)
	crew_n = 0
	abandon_t = 6.0
	target = null
	path = PackedVector3Array()
	say("ARAÇ TERK EDİLDİ!", 3.0)
	if selected and G.player:
		G.player.deselect(self)

func _kill_gunner(src) -> void:
	if not gunner_ok:
		return
	gunner_ok = false
	crew_n = maxi(0, crew_n - 1)
	target = null
	if gunner and gunner.visible:
		var gp := gunner.global_position
		gunner.visible = false
		var s: Soldier = G.main.spawn_soldier(team, "rifle", G.on_ground(gp), null)
		s.position = gp
		s.die(src)
	say("NİŞANCI VURULDU!", 2.5)

func _kill_driver(src) -> void:
	if not driver_ok:
		return
	driver_ok = false
	crew_n = maxi(0, crew_n - 1)
	cur_speed = 0.0
	path = PackedVector3Array()
	say("SÜRÜCÜ VURULDU!", 2.5)
	src = src

func _cell_ok(p: Vector3) -> bool:
	if G.grid.is_water(p):
		return false
	var h := G.grid.height_at(p)
	var k := G.grid.kind_at(p)
	if k == Grid.K_TRAP:
		return false
	return h < 0.3 or k == Grid.K_TREE or (nav_mode == Grid.M_HEAVY and k == Grid.K_WALL)

# azami hız: yoldaysa gerçek yol hızı (tekerlekli araç asfaltta belirgin hızlı), değilse arazi hızı
func _vmax(dt: float) -> float:
	_road_t -= dt
	if _road_t <= 0.0:
		_road_t = 0.3
		_on_road = road_speed > 0.0 and G.terrain != null and G.terrain.on_road(position)
	return road_speed if _on_road else speed_max

func _drive(dt: float) -> void:
	_repair_tick(dt)
	if immobile():
		cur_speed = move_toward(cur_speed, 0.0, 6.0 * dt)
	var target_speed := 0.0
	var vm := _vmax(dt)
	if not immobile():
		while path_i < path.size():
			var tp := path[path_i]
			var d := Vector3(tp.x - position.x, 0, tp.z - position.z)
			var L := d.length()
			var last := path_i == path.size() - 1
			if L < (1.6 if last else 3.0):
				path_i += 1
				if path_i >= path.size():
					_arrive()
				continue
			var want := Soldier._yaw_of(-d if reverse else d)
			# köprüde: eksene hizalan, korkuluğa sürtünme
			var br := G.grid.bridge_at(position)
			if not br.is_empty():
				var ax: Vector3 = br["d"]
				var mv := -d if reverse else d
				if ax.dot(mv) < 0.0:
					ax = -ax
				var rel: Vector3 = position - br["c"]
				rel.y = 0
				var on_axis: Vector3 = br["c"] + br["d"] * rel.dot(br["d"])
				var aim: Vector3 = on_axis + ax * 6.0 - position
				want = Soldier._yaw_of(-aim if reverse else aim)
			var diff := absf(angle_difference(heading, want))
			var tr: float = D["turn"]
			if armor < 2:
				tr *= clampf(0.35 + absf(cur_speed) / speed_max, 0.35, 1.2)
			heading = rotate_toward(heading, want, tr * dt)
			if vtype == "tank":
				target_speed = vm * clampf(1.0 - diff / 0.9, 0.0, 1.0)
			else:
				target_speed = vm * clampf(1.0 - diff / 1.6, 0.25, 1.0)
			var rem := L
			for k in range(path_i + 1, path.size()):
				rem += path[k].distance_to(path[k - 1])
				if rem > 15.0:
					break
			if rem < 8.0:
				target_speed = minf(target_speed, maxf(1.5, rem * 0.8))
			if order == "attack" and target != null and target == forced_target:
				target_speed = 0.0
				path = PackedVector3Array()
			elif order == "amove" and target != null and fire_mode != 2:
				target_speed = 0.0
			target_speed *= speed_factor()
			if not escorts.is_empty():
				target_speed = minf(target_speed, _escort_pace())
			if reverse:
				target_speed = -minf(target_speed, speed_max * 0.45)
			break
	# çekili top / havan / roketatar / obüs: yürümeden önce toplanır, durunca kurulur
	if needs_setup():
		if absf(target_speed) > 0.05:
			if deployed > 0.0:
				deployed = maxf(0.0, deployed - dt / pack_time())
				target_speed = 0.0
				if deployed <= 0.0:
					say("TOPLANDI, YÜRÜYÜŞE HAZIR")
		elif absf(cur_speed) < 0.1 and deployed < 1.0:
			deployed = minf(1.0, deployed + dt / deploy_time())
			if deployed >= 1.0:
				say("TOP KURULDU, ATEŞE HAZIR")
		_pod_pose()
	cur_speed = move_toward(cur_speed, target_speed, D["accel"] * dt * (2.0 if target_speed < cur_speed else 1.0))
	if absf(cur_speed) < 0.01:
		return
	_give_way(dt)
	if absf(cur_speed) < 0.01:
		return
	var f := forward()
	var np := position + f * cur_speed * dt
	# engel denetimi (ön nokta)
	var front: Vector3 = np + f * signf(cur_speed) * (D["len"] * 0.45)
	var hf := G.grid.height_at(front)
	var kf := G.grid.kind_at(front)
	var blocked := (hf >= 0.3 and kf != Grid.K_TREE and not (nav_mode == Grid.M_HEAVY and kf == Grid.K_WALL)) or kf == Grid.K_TRAP
	if blocked:
		# boş tarafa dönerek kaymaya çalış
		var sd := Vector3(-f.z, 0, f.x)
		var lf := _cell_ok(front + sd * 1.4)
		var rf := _cell_ok(front - sd * 1.4)
		if lf and not rf:
			heading -= D["turn"] * dt
		elif rf and not lf:
			heading += D["turn"] * dt
		cur_speed = 0.0
		_stuck_t += dt
		if _stuck_t > 1.2:
			_stuck_t = 0.0
			# biraz geri çekil ve yeniden yol bul
			var bp := position - f * signf(cur_speed + 0.001) * 0.8
			if _cell_ok(bp):
				position = bp
			if path_i < path.size():
				_repath(path[path.size() - 1])
		return
	# diğer araçlarla ayrışma: hızla sınırlı (en çok 2 m/sn) — kare başına itme sıkışmada araçları saçıyordu
	for o in G.near(np, 7.0):
		if o == self or not (o is Vehicle) or o.is_air():
			continue
		var dv = np - o.position
		dv.y = 0
		var dl = dv.length()
		var rr: float = (radius + o.radius) * 0.75
		if dl < rr and dl > 0.01:
			np += dv / dl * minf((rr - dl) * 0.5, 2.0 * dt)
	np.x = clampf(np.x, 2.0, G.MAP - 2.0)
	np.z = clampf(np.z, 2.0, G.MAP - 2.0)
	if not _cell_ok(np):
		# ayrışma itmesi suya / korkuluğa sokmasın
		np = position + f * cur_speed * dt
		if not _cell_ok(np) and G.grid.is_water(np):
			var brq := G.grid.bridge_at(position)
			if not brq.is_empty():
				# köprü kenarına dayandı (kenardaki hücre su): eksene doğru çekilerek köprü boyunca ilerle
				var axq: Vector3 = brq["d"] * signf(f.dot(brq["d"]) * cur_speed + 0.0001)
				var relq: Vector3 = position - brq["c"]
				relq.y = 0.0
				var onax: Vector3 = brq["c"] + brq["d"] * relq.dot(brq["d"])
				onax.y = position.y
				var npq: Vector3 = position + axq * absf(cur_speed) * dt + (onax - position).limit_length(maxf(absf(cur_speed), 1.0) * dt * 0.7)
				if not G.grid.is_water(npq):
					position = npq
					return
			if G.grid.is_water(position):
				# köprü kenarında su hücresine taşmış: durup kalmasın, köprüye / kuru zemine doğru kay
				position = position.move_toward(G.grid.nearest_dry(position, 6.0), maxf(absf(cur_speed), 1.5) * dt)
				return
			cur_speed = 0.0
			return
	var moved := np.distance_to(position)
	position = np
	# ezme
	if nav_mode == Grid.M_HEAVY:
		_crush_t -= dt
		if _crush_t <= 0.0:
			_crush_t = 0.12
			var fp = position + f * (D["len"] * 0.42)
			if G.blocks.crush(fp, 1.7, f, 0.5):
				cur_speed *= 0.6
				rock_v -= 1.5
			G.props.crush(fp, 2.0, f)
	for o in G.near(position + f * 2.0, 2.2):
		if o is Soldier and o.alive and o.team != team and absf(cur_speed) > 2.0:
			o.take_damage(200.0, self, "crush")
	# izler (savaş sisine uyumlu: oyuncunun görmediği düşman aracı iz bırakmaz — yoksa sisin içindeki hareketi ele verirdi)
	_track_acc += moved
	var vt_v := G.view_team()
	if _track_acc > 0.3 and (vt_v < 0 or team == vt_v or seen[vt_v]):
		_track_acc = 0.0
		var side := Vector3(-f.z, 0, f.x)
		var tw := 1.25 if vtype == "tank" else 1.0
		G.terrain.track(position + side * tw, 0.4)
		G.terrain.track(position - side * tw, 0.4)
	_dust_t -= dt
	if _dust_t <= 0.0 and absf(cur_speed) > 2.5:
		_dust_t = 0.12
		G.fx.vehicle_dust(position - f * (D["len"] * 0.45) + Vector3(randf_range(-1, 1), 0.2, randf_range(-1, 1)))
		if randf() < 0.4:
			G.fx.exhaust(position - f * (D["len"] * 0.5) + Vector3(0, 1.0, 0), 1.0)

# ------------------------------------------------------------ takılma bekçisi (kara aracı)
# Yürüyüş emrinde ilerleme ölçütü: 15 sn'de 1 m yer değiştirmeyen araç biraz geri çekilip yolu yeniden
# arar; üç denemede (45 sn) ilerleyemezse emri bırakır ve bir kez "STUCK-RESOLVE Vehicle move <sn>" yazar.
# Bilerek duran araç sayılmaz: saldırı hareketinde çatışan, toplanan/kurulan top, hareketsiz (palet/sürücü).
# İkmal kamyonu emri bırakmaz (lojistik hattı), yalnız yeniden yol arar.
var _vg_goal := Vector3.INF
var _vg_best := 0.0
var _vg_t := 0.0
var _vg_n := 0

func _guard_drive(dt: float) -> void:
	var moving := order in ["move", "amove", "retreat", "refund", "route", "attack"] and path_i < path.size() and not immobile()
	if moving and order == "amove" and target != null and fire_mode != 2:
		moving = false
	if moving and needs_setup() and deployed > 0.0:
		moving = false
	if not moving:
		_vg_goal = Vector3.INF
		_vg_t = 0.0
		_vg_n = 0
		return
	# ilerleme ölçütü: yolun sonuna kalan mesafe azalıyor mu (yer değiştirme değil — engelde geri çekilip
	# yeniden deneyen araç salınır, yer değiştirir ama ilerlemez)
	var goal := path[path.size() - 1]
	var dd := Vector2(goal.x - position.x, goal.z - position.z).length()
	if _vg_goal == Vector3.INF or goal.distance_to(_vg_goal) > 2.0:
		_vg_goal = goal
		_vg_best = dd
		_vg_t = 0.0
		_vg_n = 0
		return
	if dd < _vg_best - 1.0:
		_vg_best = dd
		_vg_t = 0.0
		return
	_vg_t += dt
	if _vg_t < 15.0:
		return
	_vg_t = 0.0
	_vg_n += 1
	if _vg_n >= 3 and vtype != "truck":
		print("STUCK-RESOLVE Vehicle move %d %s order=%s p=(%.0f,%.0f)" % [_vg_n * 15, vid if vid != "" else vtype, order, position.x, position.z])
		_vg_n = 0
		if order == "attack":
			forced_target = null
			order = ""
		_arrive()
		if team == G.player_team and not G.spectate:
			say("YOL YOK!", 2.0)
		return
	# engelden kurtul: biraz geri çekil (ya da en yakın boş hücreye çık), yolu yeniden ara
	var bp := position - forward() * 1.5
	if _cell_ok(bp):
		position = bp
	elif not _cell_ok(position):
		position = G.grid.nearest_free(position, nav_mode)
	_repath(path[path.size() - 1])

func _arrive() -> void:
	path = PackedVector3Array()
	path_i = 0
	if order in ["move", "amove", "retreat"]:
		order = ""
	reverse = false
	retreating = false
	if vtype == "truck" and G.logi:
		G.logi.truck_arrived(self)

# kendiliğinden (emirsiz) ateş (roadmap 109): doğrudan atışlı araç yalnız kendi optiğiyle seçebildiği hedefe ve
# silahın etkili menziline (azami menzilin ~%65'i) kadar ateş açar — takımın uzaktan gördüğü her hedefe azami
# menzilden sıkmaz. Oyuncunun saldırı emri tam menzili ve takım görüşünü kullanır; dolaylı atış gözcüyle çalışır.
const AUTO_RNG_K := 0.65

func _auto_engage_ok(e: Unit, d: float, rng_w: float) -> bool:
	if e == forced_target or vtype in INDIRECT or (e is Vehicle and e.is_air()):
		return true
	return d <= rng_w * AUTO_RNG_K + 4.0 and d <= Combat.detect_range(opt_k, e.spot_sig())

func _scan() -> void:
	if vtype == "truck":
		return
	# "ateş kes" kendiliğinden ateşi keser; oyuncunun açık saldırı emri (forced_target) bunu geçersiz kılar
	var hold := fire_mode == 2 and not (order == "attack" and forced_target != null)
	if retreating or hold or (fire_mode == 1 and G.time - last_hit > 10.0) or not gunner_ok or (crew_max > 0 and crew_n <= 0) or abandon_t >= 0.0:
		target = null
		coax_target = null
		return
	var rng_w := _range()
	var eye := turret_world_pos() + Vector3(0, 0.4, 0)
	if forced_target != null and (not is_instance_valid(forced_target) or not forced_target.hostile()):
		forced_target = null
		if order == "attack":
			order = ""
	# seyrek tam tarama: hedef hâlâ geçerliyse (görülüyor, menzilde) ya da son taramada aday yoksa tüm görünür
	# düşmanlar her 0,5 sn'de taranmaz (yüzlerce birimde kare süresinin büyük payıydı); vurulunca hemen taranır
	if G.time < _scan_next and forced_target == null and G.time - last_hit > 1.0:
		if target == null:
			return
		if is_instance_valid(target) and target.alive and G.is_seen(target, team) and dist2(target) <= rng_w + 4.0 and _auto_engage_ok(target, dist2(target), rng_w):
			return
	var best: Unit = null
	var bs := 1e9
	var best_inf: Unit = null
	var bsi := 1e9
	var cands: Array = []
	for e in G.visible_enemies(team):
		if not is_instance_valid(e) or not e.alive:
			continue
		if e is Soldier and e.incapacitated():
			continue
		var d := dist2(e)
		if d > rng_w + 4.0 or not _auto_engage_ok(e, d, rng_w):
			continue
		var sc := d
		var air: bool = e is Vehicle and e.is_air()
		if vtype == "aa":
			if air:
				sc -= 200.0
				if d > _wr("aa"):
					continue
			elif d > _wr("auto", _wr("mg")) or e is Building:
				continue
		elif air and not (vtype in ["apc", "ifv", "technical", "heli"]) :
			continue
		elif air:
			sc += 15.0
		if vtype == "aagun":
			if air:
				sc -= 200.0
			elif d > _wr("auto", 2000.0) or e is Building or (e is Vehicle and e.armor > 0):
				continue
		elif vtype == "atgun":
			if air:
				continue
			sc -= 60.0 if (e is Vehicle and e.armor > 0) else (0.0 if e is Vehicle else -25.0)
		elif vtype == "fieldgun" and air:
			continue
		if vtype in INDIRECT:
			if d < _min_range() or air:
				continue
			sc -= G.enemies_near(e.position, 8.0, team).size() * 6.0 + (25.0 if e is Building else 0.0)
		if vtype == "tank":
			if e is Vehicle:
				sc -= 30.0 + (20.0 if e.vtype in ["tank", "apc"] else 0.0)
			elif e is Building:
				sc -= 5.0
		elif vtype == "apc":
			if e is Vehicle and e.vtype == "technical":
				sc -= 15.0
			elif e is Vehicle and e.vtype == "tank":
				sc += 10.0
		else:
			if e is Vehicle and e.armor > 0:
				sc += 40.0
			elif e is Building:
				sc += 30.0
		if e == forced_target:
			sc -= 200.0
		cands.append([sc, e])
		if e is Soldier and d < _wr("mg", 1000.0) and d < bsi:
			bsi = d
			best_inf = e
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var n := 0
	for cc in cands:
		n += 1
		if n > 4:
			break
		var e: Unit = cc[1]
		if (vtype in INDIRECT) or (e is Vehicle and e.is_air()) or G.grid.los(eye, e.aim_point(), D["len"] * 0.5, 1.6 if e is Soldier and e.house_id >= 0 else 0.5):
			best = e
			break
	target = best
	_scan_next = G.time + (randf_range(1.6, 2.2) if best != null else (randf_range(0.9, 1.3) if cands.is_empty() else 0.0))
	coax_target = null
	if vtype == "tank" and best_inf != null and G.grid.los(eye, best_inf.aim_point(), 3.0, 1.6 if best_inf.house_id >= 0 else 0.5):
		coax_target = best_inf
	if order == "attack" and forced_target != null and best != forced_target:
		_close_on_forced()

# saldırı emri verilen hedef vurulamıyor (görülmüyor / menzil dışı / görüş hattı kapalı): doğrudan atışlı kara
# aracı (çekili top dahil) piyadedeki gibi hedefe yaklaşır — yoksa emir sessizce askıda kalır. Dolaylı atışlı
# topçu yaklaşmaz (asgari menzil); gözcü gerektiğini söyler.
var _chase_t := 0.0

func _close_on_forced() -> void:
	var ft: Unit = forced_target
	if not is_instance_valid(ft) or not ft.hostile() or is_air() or immobile() or (ft is Vehicle and ft.is_air()):
		return
	if G.time < _chase_t:
		return
	if vtype in INDIRECT:
		if not G.is_seen(ft, team):
			_chase_t = G.time + 8.0
			say("HEDEF GÖRÜLMÜYOR, GÖZCÜ GEREK", 2.5)
		elif dist2(ft) < _min_range():
			_chase_t = G.time + 6.0
			say("ASGARİ MENZİLİN İÇİNDE", 2.5)
			if vtype in ["arty", "mlrs"] and not immobile():
				# kundağı motorlu: hedeften asgari menzilin dışına çekil (emir sürer, sonra ateş eder)
				var away := position - ft.position
				away.y = 0.0
				if away.length() < 0.1:
					away = -forward()
				dest = G.grid.nearest_free(ft.position + away.normalized() * (_min_range() + 10.0), nav_mode)
				_repath(dest)
			else:
				# çekili top kendi kendine çekilemez: emir bırakılır
				forced_target = null
				order = ""
		return
	var d := dist2(ft)
	if d < 8.0:
		return
	var stand := minf(minf(sight, _range()) * 0.7, d * 0.6)
	var goal: Vector3 = G.grid.nearest_free(ft.position + (position - ft.position).normalized() * stand, nav_mode)
	if path_i < path.size() and goal.distance_to(dest) < 4.0:
		return
	_chase_t = G.time + 1.5
	dest = goal
	_repath(dest)

func _aim_fire(dt: float) -> void:
	# başlamış salvo hedef / görüş kaybolsa da sürer (eskiden hedef yokken erken dönüş salvoyu donduruyordu)
	_mlrs_tick(dt)
	if turret == null or G.deploy_t > 0.0:
		return
	if needs_setup() and deployed < 1.0:
		return
	if G.time < ground_until and fire_mode != 2:
		var wl := wrapf(Soldier._yaw_of(ground_pt - position) - heading, -PI, PI)
		turret_yaw = rotate_toward(turret_yaw, wl, D["tturn"] * tturn_mult() * dt)
		turret.rotation.y = turret_yaw
		if barrel:
			recoil = move_toward(recoil, 0.0, dt * 1.4)
			barrel.position = (M["barrel_pos"] as Vector3) + Vector3(0, 0, recoil * 0.6)
		if absf(angle_difference(turret_yaw, wl)) < 0.1 and main_cd <= 0.0 and dist2_p(ground_pt) <= _range():
			_fire_ground()
		return
	var t := target
	var want_local := 0.0
	if t != null and is_instance_valid(t) and t.alive:
		var d := t.position - position
		want_local = wrapf(Soldier._yaw_of(d) - heading, -PI, PI)
	turret_yaw = rotate_toward(turret_yaw, want_local, D["tturn"] * tturn_mult() * dt)
	turret.rotation.y = turret_yaw
	if barrel:
		recoil = move_toward(recoil, 0.0, dt * 1.4)
		barrel.position = (M["barrel_pos"] as Vector3) + Vector3(0, 0, recoil * 0.6)
	if t == null or not is_instance_valid(t) or not t.alive:
		_coax(dt)
		return
	var aligned := absf(angle_difference(turret_yaw, want_local)) < (0.05 if vtype == "tank" else 0.12)
	var dist := dist2(t)
	# güdümlü tanksavar füzesi: PSA (TOW / Konkurs / Kornet) ve namludan füze atan tank — ana silahın
	# menzili dışındaki zırhlıya da
	if aligned and atgm_cd <= 0.0 and vtype in ["ifv", "tank"] and t is Vehicle and t.armor > 0 and not t.is_air() and _wr("atgm") > 0.0 and dist <= _wr("atgm") and (vtype == "ifv" or dist > _wr("main") * 0.85):
		# nişan / kilit (roadmap 15): TOW, Konkurs ~1,5 sn, Refleks 1,2 sn — hedef izlenirken birikir
		atgm_lock += dt
		if atgm_lock >= Ballistics.lock_time(_atgm_model()):
			atgm_lock = 0.0
			_fire_atgm(t, dist)
	else:
		atgm_lock = maxf(0.0, atgm_lock - dt * 2.0)
	if aligned and main_cd <= 0.0 and _can_fire_at(t, dist):
		match vtype:
			"tank":
				_fire_cannon(t)
			"apc":
				_fire_auto(t)
			"technical":
				_fire_hmg(t)
			"ifv":
				if dist <= _wr("auto", _range()):
					_fire_auto(t)
			"aa", "aagun":
				if not _fire_sam(t):
					_fire_flak(t)
			"arty":
				_fire_arty(t)
				if not crew.is_empty():
					on_crew_fire()
			"fieldgun":
				_fire_cannon(t)
				main_cd = _rl(5.0)
				on_crew_fire()
			"atgun":
				_fire_atgun(t)
			"howitzer":
				_fire_arty(t)
				main_cd = _rl(11.0)
				on_crew_fire()
			"mtngun":
				_fire_arty(t)
				main_cd = _rl(7.0)
				on_crew_fire()
			"hmortar":
				_fire_hmortar(t.position)
			"mlrs":
				if mlrs_left <= 0:
					mlrs_left = salvo_n if salvo_n > 0 else 12
					mlrs_aim = t.position
	_coax(dt)
	_crew_anim(dt)

var mlrs_aim := Vector3.ZERO

# roketatar: fırlatıcı (pod) kurulumla birlikte atış açısına kalkar, toplanırken iner (arka mafsal düğümü)
const POD_ELEV := 0.52
func _pod_pose() -> void:
	if vtype != "mlrs" or barrel == null:
		return
	var e := deployed * deployed * (3.0 - 2.0 * deployed) * POD_ELEV
	barrel.rotation.x = e
	if tube_caps == null and salvo_n > 0 and salvo_n <= 16:
		_make_caps()

# tüp kapakları (M270 / HIMARS gibi kapalı podlar): her tüpün ağzında kırılabilir kapak; roket kapağı delip çıkar
var tube_caps: MultiMeshInstance3D = null
var caps_left := 0
func _pod_frame() -> Array:
	var mz: Vector3 = M["muzzle"]
	var ax := mz.normalized() if mz.length() > 0.2 else Vector3(0, 0, -1)
	var rt := ax.cross(Vector3.UP).normalized() if absf(ax.y) < 0.95 else Vector3.RIGHT
	var up := rt.cross(ax).normalized()
	return [mz, ax, rt, up]

func _make_caps() -> void:
	var fr := _pod_frame()
	var n := salvo_n
	var pitch := 0.17 if n >= 30 else (0.3 if n >= 16 else 0.36)
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var cm := CylinderMesh.new()
	cm.top_radius = pitch * 0.42
	cm.bottom_radius = pitch * 0.42
	cm.height = 0.03
	cm.radial_segments = 12
	cm.rings = 1
	mm.mesh = cm
	mm.instance_count = n
	for i in n:
		mm.set_instance_transform(i, _cap_xf(fr, i, n, 1.0))
	tube_caps = MultiMeshInstance3D.new()
	tube_caps.multimesh = mm
	tube_caps.material_override = Mats.flat(Color(0.27, 0.29, 0.24), 0.8)
	barrel.add_child(tube_caps)
	caps_left = n

func _cap_xf(fr: Array, i: int, n: int, s: float) -> Transform3D:
	var o := _tube_off(i, n)
	var ax: Vector3 = fr[1]
	var rt: Vector3 = fr[2]
	var up: Vector3 = fr[3]
	var p: Vector3 = (fr[0] as Vector3) + rt * o.x + up * o.y + ax * 0.02
	return Transform3D(Basis(rt, ax, rt.cross(ax)).scaled(Vector3(s, s, s)), p)

# roket kapağı deler: kapak gizlenir, iki yarım parça öne fırlayıp dönerek yere düşer, bir süre yerde kalır
func _cap_burst(i: int) -> void:
	if tube_caps == null:
		return
	var mm := tube_caps.multimesh
	var fr := _pod_frame()
	var xf := mm.get_instance_transform(i)
	if xf.basis.get_scale().x < 0.01:
		return
	mm.set_instance_transform(i, _cap_xf(fr, i, salvo_n, 0.0))
	caps_left -= 1
	var wp := barrel.global_transform * xf.origin
	var wax := (barrel.global_transform.basis * (fr[1] as Vector3)).normalized()
	var r: float = (mm.mesh as CylinderMesh).top_radius
	for k in 2:
		var pc := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(r * 2.0, 0.025, r)
		pc.mesh = bm
		pc.material_override = tube_caps.material_override
		G.world.add_child(pc)
		pc.global_position = wp
		var v := wax * randf_range(5.0, 11.0) + Vector3(randf_range(-2.0, 2.0), randf_range(1.0, 3.0), randf_range(-2.0, 2.0))
		var gy := G.terrain.ground_h(wp) if G.terrain else 0.0
		# yere iniş süresi: y(t) = y0 + vy·t − 4,9·t²
		var y0 := wp.y - gy - 0.02
		var tt := (v.y + sqrt(v.y * v.y + 19.6 * maxf(y0, 0.0))) / 9.8
		var land := wp + Vector3(v.x, 0, v.z) * tt * 0.85
		land.y = gy + 0.02
		var tw := pc.create_tween()
		tw.tween_method(func(t: float):
			if is_instance_valid(pc):
				pc.global_position = wp + Vector3(v.x * t * 0.85, v.y * t - 4.9 * t * t, v.z * t * 0.85)
				pc.rotation = Vector3(t * 14.0, t * 9.0, t * 6.0), 0.0, tt, tt)
		tw.tween_callback(func():
			if is_instance_valid(pc):
				pc.global_position = land
				pc.rotation = Vector3(0, randf() * TAU, 0))
		tw.tween_interval(25.0)
		tw.tween_callback(pc.queue_free)

func _caps_reload() -> void:
	if tube_caps == null:
		return
	var fr := _pod_frame()
	for i in salvo_n:
		tube_caps.multimesh.set_instance_transform(i, _cap_xf(fr, i, salvo_n, 1.0))
	caps_left = salvo_n

# roketatar tüp kafesi: satır × sütun, aralık çapa göre (122 mm ~0,17 m, 220 mm ~0,3 m, 227 mm ~0,36 m)
func _tube_off(i: int, n: int) -> Vector2:
	var rows := 2 if n <= 6 else (3 if n <= 12 else 4)
	var cols := int(ceil(float(n) / rows))
	var pitch := 0.17 if n >= 30 else (0.3 if n >= 16 else 0.36)
	var c := i % cols
	var r := i / cols
	return Vector2((c - (cols - 1) * 0.5) * pitch, (r - (rows - 1) * 0.5) * pitch)

# roketatar: 12 roketlik salvo, sonra uzun dolum
func _mlrs_tick(dt: float) -> void:
	if vtype != "mlrs" or mlrs_left <= 0:
		return
	# toplanırken / kurulum sürerken salvo bekler
	if needs_setup() and deployed < 1.0:
		return
	mlrs_t -= dt
	if mlrs_t > 0.0:
		return
	mlrs_t = salvo_ival if salvo_ival > 0.0 else 0.22
	mlrs_left -= 1
	fired_t = G.time
	# her roket podun kendi tüpünden: tüp dizilimi salvo sayısından (HIMARS 2×3, M270 3×4, BM-21 4×10...),
	# atış sırası dağınık (gerçek roketatar gibi kafes boyunca sıçrar)
	var n_tot := salvo_n if salvo_n > 0 else 12
	var ti := ((n_tot - 1 - mlrs_left) * 7) % n_tot
	var mw := muzzle_world()
	var axis := (mw - barrel.global_position).normalized() if barrel != null and mw.distance_to(barrel.global_position) > 0.1 else forward()
	var rt := axis.cross(Vector3.UP).normalized() if absf(axis.y) < 0.95 else right()
	var upv := rt.cross(axis).normalized()
	var to := _tube_off(ti, n_tot)
	var mp := mw + rt * to.x + upv * to.y
	if mlrs_left == n_tot - 1 and caps_left <= 0:
		_caps_reload()          # yeni salvo: dolumda yeni pod takıldı
	_cap_burst(ti)
	var d := dist2_p(mlrs_aim)
	var err := d * 0.07 + 4.0
	G.bal.mlrs_rocket(mp, mlrs_aim + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self, axis)
	Sfx.play3d("rpg", mp, 3.0, 0.15, 0.05)
	G.fx.pod_launch(mp, axis, mlrs_left == n_tot - 1)
	if mlrs_left <= 0:
		main_cd = rearm_s if rearm_s > 0.0 else 32.0

# atış hızı (roadmap 2): gerçek veri varsa onu, yoksa tipin varsayılanını kullan
func _rl(def: float) -> float:
	return reload_s if reload_s > 0.0 else def

func _burst_len(a: int, b: int) -> int:
	return maxi(1, burst_n + randi_range(-1, 1)) if burst_n > 0 else randi_range(a, b)

func _auto_ival(def: float) -> float:
	return maxf(60.0 / rpm, 0.04) if rpm > 0.0 else def

func _fire_atgun(t: Unit) -> void:
	main_cd = _rl(4.2)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var spread := mp.distance_to(tp) * 0.015
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.2), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "ap" if t is Vehicle or t is Building else "he")
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 3.0)
	recoil = 1.0
	on_crew_fire()

func _fire_hmortar(tp: Vector3) -> void:
	main_cd = _rl(randf_range(4.5, 5.5))
	var d := dist2_p(tp)
	var err := d * 0.05 + 2.0
	var mp := muzzle_world()
	G.bal.mortar(mp, tp + Vector3(randf_range(-err, err), 0, randf_range(-err, err)), team, self, ammo_he)
	Sfx.play3d("mortar", mp, 3.0)
	G.fx.muzzle(mp, Vector3.UP, true)
	recoil = 0.6
	on_crew_fire()

# ------------------------------------------------------------ çekili top mürettebatı
# Döngü (atıştan sonra main_cd boyunca): herkes kulak kapatır → doldurucu kamayı açar, boş kovan
# geriye fırlar → cephaneci sandık yığınından mermi alıp doldurucuya taşır → doldurucu mermiyi
# kamaya sürer, kapatır → nişancı yükseliş volanını çevirir → nişancı ipi çeker (atış).
# Havan: doldurucu mermiyi namlu ağzına bırakır ve eğilir.
var crew_cycle := 0.0
var _crew_spots: Array = []
var _casing_done := false
var _ammo_pile: Node3D = null
static var _shell_m: Mesh = null
static var _case_m: Mesh = null

func _crew_meshes() -> void:
	if _shell_m != null:
		return
	var X := Basis(Vector3.RIGHT, -PI * 0.5)
	var mb := MB.new()
	mb.cyl(Vector3(0, 0, -0.32), 0.0, 0.05, 0.12, 10, Color(0.6, 0.5, 0.22), X)
	mb.cyl(Vector3(0, 0, -0.1), 0.05, 0.065, 0.32, 10, Color(0.32, 0.35, 0.26), X)
	mb.cyl(Vector3(0, 0, 0.12), 0.065, 0.065, 0.14, 10, Color(0.32, 0.35, 0.26), X)
	mb.cyl(Vector3(0, 0, 0.2), 0.068, 0.068, 0.03, 10, Color(0.62, 0.42, 0.22), X)
	_shell_m = mb.commit(Mats.vc())
	var cb := MB.new()
	cb.cyl(Vector3(0, 0, 0), 0.062, 0.066, 0.42, 10, Color(0.78, 0.6, 0.25), X)
	cb.cyl(Vector3(0, 0, 0.21), 0.072, 0.072, 0.02, 10, Color(0.7, 0.52, 0.2), X)
	_case_m = cb.commit(Mats.metal())

func _crew_setup_props() -> void:
	_crew_meshes()
	# cephane sandıkları: topun arkasında iki sıra, üstte açık kapaklı sandık
	var mb := MB.new()
	var od := Color(0.3, 0.33, 0.22)
	for k in 4:
		var x := (k % 2) * 0.62
		var y := (k / 2) * 0.3
		mb.box(Vector3(x, 0.15 + y, 0), Vector3(0.58, 0.28, 0.42), od.darkened(0.05 * k))
		mb.box(Vector3(x + 0.3, 0.15 + y, 0), Vector3(0.02, 0.08, 0.2), Color(0.15, 0.15, 0.12))
	mb.box(Vector3(0.31, 0.68, 0), Vector3(0.58, 0.04, 0.42), od.lightened(0.05), Basis(Vector3.RIGHT, -1.1))
	for k in 3:
		mb.cyl(Vector3(0.12 + k * 0.17, 0.62, 0.0), 0.06, 0.06, 0.12, 8, Color(0.6, 0.5, 0.22))
	_ammo_pile = MeshInstance3D.new()
	(_ammo_pile as MeshInstance3D).mesh = mb.commit(Mats.vcs())
	hull.add_child(_ammo_pile)
	_ammo_pile.position = Vector3(0.9, 0, ext.y + 1.6)
	for cb in crew:
		_crew_spots.append(cb.position)

func _breech_local() -> Vector3:
	if barrel == null:
		return Vector3(0, 0.9, 0.6)
	var w := barrel.global_transform * (M["breech"] as Vector3 if M.has("breech") else Vector3(0, 0, 0.55))
	return hull.to_local(w)

func _muzzle_local() -> Vector3:
	if barrel == null:
		return Vector3(0, 1.2, -0.6)
	return hull.to_local(barrel.global_transform * (M["muzzle"] as Vector3))

func on_crew_fire() -> void:
	crew_cycle = maxf(main_cd, 0.1)
	_casing_done = false

func _eject_casing() -> void:
	if vtype in ["hmortar", "aagun"]:
		return
	var bw := hull.to_global(_breech_local() + Vector3(0, 0, 0.25))
	var mi := MeshInstance3D.new()
	mi.mesh = _case_m
	G.main.world.add_child(mi)
	mi.global_position = bw
	var back := -forward()
	var land := bw + back * randf_range(0.9, 1.6) + right() * randf_range(-0.5, 0.5)
	land.y = 0.07
	var tw := mi.create_tween()
	var mid := (bw + land) * 0.5 + Vector3(0, 0.5, 0)
	tw.tween_property(mi, "global_position", mid, 0.18).set_ease(Tween.EASE_OUT)
	tw.parallel().tween_property(mi, "rotation", Vector3(randf_range(2, 4), randf_range(0, 3), 0), 0.4)
	tw.tween_property(mi, "global_position", land, 0.22).set_ease(Tween.EASE_IN)
	tw.tween_property(mi, "rotation:x", PI * 0.5, 0.05)
	tw.tween_interval(30.0)
	tw.tween_callback(mi.queue_free)
	G.fx.exhaust(bw, 0.8)
	Sfx.play3d("hit_metal", land, -14.0, 0.2, 0.1)

func _crew_anim(dt: float) -> void:
	if crew.is_empty():
		return
	if _crew_spots.is_empty():
		_crew_setup_props()
	var busy := crew_cycle > 0.0 and main_cd > 0.0 and alive
	var p := 1.0 - clampf(main_cd / maxf(crew_cycle, 0.01), 0.0, 1.0) if busy else 1.0
	var br := _breech_local()
	var mortar := vtype == "hmortar"
	var pile: Vector3 = _ammo_pile.position + Vector3(0.3, 0, -0.35) if _ammo_pile else Vector3(1, 0, 3)
	var load_pt: Vector3 = (_muzzle_local() + Vector3(0.45, -_muzzle_local().y, 0.25)) if mortar else Vector3(br.x + 0.75, 0, br.z + 0.35)
	if busy and p > 0.14 and not _casing_done:
		_casing_done = true
		_eject_casing()
	for i in crew.size():
		var cb: SoldierBody = crew[i]
		var home: Vector3 = _crew_spots[i]
		var pose := "crouch_aim" if target != null else "crouch"
		var spd := 0.0
		var goal := home
		var face := br
		var extra := 0.0
		var tool := ""
		if busy:
			if p < 0.12:
				pose = "cover"          # atış: kulak kapat, başı eğ
			elif i == 0:
				# nişancı: yükseliş/yön volanı
				goal = Vector3(br.x - 0.75, 0, br.z + 0.1)
				pose = "lay" if p < 0.92 else "crouch_aim"
			elif i == 1:
				# doldurucu: kamayı aç → mermiyi al → kamaya sür
				goal = load_pt
				if p < 0.3:
					pose = "ram"
					extra = 0.3
				elif p < 0.62:
					pose = "crouch"
				elif p < 0.72:
					pose = "carry"
					extra = 1.0
					tool = "shell"
				elif p < 0.9:
					pose = "ram" if not mortar else "drop"
					extra = clampf((p - 0.72) / 0.18, 0.0, 1.0)
					tool = "shell" if extra < 0.7 else ""
				else:
					pose = "crouch"
			elif i == 2:
				# cephaneci: yığından mermi al, doldurucuya taşı
				if p < 0.4:
					goal = pile
					face = pile + Vector3(0, 0, 1)
					pose = "build" if p > 0.3 else "crouch"
				elif p < 0.62:
					goal = load_pt + Vector3(0.6, 0, 0.6)
					pose = "carry"
					extra = 1.0
					tool = "shell"
					face = load_pt
				else:
					goal = home
					pose = "crouch"
		var cur := cb.position
		var mv := goal - cur
		mv.y = 0.0
		if mv.length() > 0.08:
			var st := minf(mv.length(), dt * 2.4)
			cb.position = cur + mv.normalized() * st
			spd = 2.0
			face = goal + mv.normalized()
			if pose == "crouch" or pose == "crouch_aim":
				pose = "stand"
		var fd := face - cb.position
		if fd.length() > 0.05:
			cb.rotation.y = lerp_angle(cb.rotation.y, atan2(-fd.x, -fd.z), clampf(dt * 6.0, 0.0, 1.0))
		cb.set_tool(tool)
		cb.weapon.visible = false
		cb.animate(dt, pose, spd, extra)

func dist2_p(p: Vector3) -> float:
	return Vector2(position.x - p.x, position.z - p.z).length()

func _fire_ground() -> void:
	# baskı / bombardıman: yere ateş
	fired_t = G.time
	var mp := muzzle_world()
	var p := ground_pt + Vector3(randf_range(-3.5, 3.5), 0.1, randf_range(-3.5, 3.5))
	match vtype:
		"tank":
			main_cd = _rl(6.5)
			G.bal.shell(mp, p, team, self, null, "he", ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
			rock_v += 2.5
		"apc", "ifv":
			if burst <= 0:
				burst = _burst_len(3, 5)
			burst -= 1
			main_cd = _auto_ival(0.26) if burst > 0 else randf_range(1.0, 1.8)
			G.bal.shell(mp, p, team, self, null, "auto", ammo_auto)
			G.fx.muzzle(mp, (p - mp).normalized(), true)
			Sfx.play3d("autocannon", mp, 0.0)
			recoil = 0.4
		"technical":
			if burst <= 0:
				burst = randi_range(6, 12)
			burst -= 1
			main_cd = 0.11 if burst > 0 else randf_range(0.6, 1.2)
			shots += 1
			G.fx.muzzle(mp, (p - mp).normalized(), true)
			Sfx.play3d("hmg", mp, 1.0, 0.08, 0.03)
			G.fx.impact(Vector3(p.x, 0.02, p.z), "dirt")
			for o in G.near(p, 3.5):
				if o is Soldier and o.team != team and o.alive:
					o.add_suppression(12.0, position)
			if shots % 2 == 0:
				G.fx.tracer_cal(mp, p, 260.0, Ammo.team_tracer(team), 12.7)
		"arty":
			main_cd = _rl(9.0)
			G.bal.artillery(mp, p, team, self, ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 6.0)
			recoil = 1.0
			rock_v += 3.0
		"fieldgun", "atgun":
			main_cd = _rl(5.0)
			G.bal.shell(mp, p, team, self, null, "he", ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 3.0)
			recoil = 1.0
		"howitzer", "mtngun":
			main_cd = _rl(10.0 if vtype == "howitzer" else 7.0)
			G.bal.artillery(mp, p, team, self, ammo_he)
			G.fx.cannon_blast(mp, (p - mp).normalized())
			Sfx.play3d("tank_fire", mp, 5.0)
			recoil = 1.0
		"hmortar":
			_fire_hmortar(p)
		"mlrs":
			if mlrs_left <= 0:
				mlrs_left = salvo_n if salvo_n > 0 else 12
				mlrs_aim = ground_pt
			main_cd = 0.5
		_:
			main_cd = 1.0

func _fire_flak(t: Unit) -> void:
	fired_t = G.time
	if burst <= 0:
		burst = _burst_len(6, 12)
	burst -= 1
	main_cd = _auto_ival(0.07) if burst > 0 else randf_range(0.6, 1.1)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var air: bool = t is Vehicle and t.is_air()
	G.fx.muzzle(mp, (tp - mp).normalized(), true)
	Sfx.play3d("autocannon", mp, -3.0, 0.1, 0.03)
	recoil = 0.25
	var c := 0.32 if air else 0.25
	if t is Vehicle and t.vtype == "fpv":
		c = 0.45
	if t is Vehicle and t.high_alt:
		c *= 0.3     # yüksek irtifa İHA: menzil sınırında, küçük hedef
	var impact := tp + Vector3(randf_range(-2, 2), randf_range(-1, 2), randf_range(-2, 2))
	if randf() < c:
		t.take_damage(26.0, self, "auto")
		impact = tp
	if air:
		if randf() < 0.3:
			G.fx.explosion(impact, 0.35, "flak")
	else:
		impact.y = 0.02
		G.fx.impact(impact, "dirt")
		for o in G.near(impact, 3.0):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(12.0, position)
	G.fx.tracer_cal(mp, impact, 300.0, Ammo.team_tracer(team).lightened(0.2), 30.0)

func _fire_arty(t: Unit) -> void:
	main_cd = _rl(9.0)
	fired_t = G.time
	var mp := muzzle_world()
	var d := dist2(t)
	var err := d * (0.012 if not rng.is_empty() else 0.05) + 4.0
	var tp := t.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	G.bal.artillery(mp, tp, team, self, ammo_he)
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 6.0)
	recoil = 1.0
	rock_v += 3.0
	G.cam.shake(0.2, position)

func _fire_cannon(t: Unit) -> void:
	fired_t = G.time
	main_cd = _rl(6.5)
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var ap = t is Vehicle and t.armor > 0
	# atış kontrolü: termal nişangâhlı modern top 2 km'de ~1 m dağılır; yürürken dengesiz/eski top kötüleşir
	var moving := absf(cur_speed) > 1.0
	var spread := (d * fcs + 0.25) * (1.0 if t is Vehicle else 1.4) * aim_mult() * (1.8 if moving and fcs > 0.0008 else (1.2 if moving else 1.0))
	tp = _lead(t, mp, tp, Ammo.speed(ammo_ke if ap else ammo_he, 900.0))
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.3, 0.3), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "ap" if ap else "he", ammo_ke if ap else ammo_he)
	G.fx.cannon_blast(mp, (tp - mp).normalized())
	Sfx.play3d("tank_fire", mp, 5.0)
	recoil = 1.0
	rock_v += 2.5
	G.cam.shake(0.25, position)

# hareketli hedefe öndeleme (atış kontrolü): uçuş süresince hedefin alacağı yol; iyi atış kontrolü daha isabetli
func _lead(t: Unit, from: Vector3, tp: Vector3, spd: float) -> Vector3:
	var v := t.move_vel()
	if v.length_squared() < 0.04 or spd <= 1.0:
		return tp
	var ft := from.distance_to(tp) / spd
	return tp + v * ft * (0.9 if fcs <= 0.0008 else 0.6)

func move_vel() -> Vector3:
	if is_air():
		return hvel
	return forward() * cur_speed

# hedef izi (roadmap 50): gerçek boyut (W×H, ana muharebe tankı = 1), hareket, ateş, bitki örtüsü;
# hava aracı: helikopter belirgin, İHA küçük (yüksek irtifada yarı)
var sig := 1.0
func spot_sig() -> float:
	if not alive:
		return 0.0
	var s := sig
	if is_air():
		s = maxf(s, 0.9) if vtype in ["heli", "transport"] else s * 0.6
		if high_alt:
			s *= 0.5
		return s * (1.4 if G.time - fired_t < 3.0 else 1.0)
	if absf(cur_speed) > 1.0:
		s *= 1.3
	if G.time - fired_t < 3.0:
		s *= 2.0
	# orman kenarına girmiş araç: ağaçlar gövdeyi böler (çalı aracı saklamaz)
	var veg: int = G.props.veg_count(position, ext.y + 3.0, "tree") if G.props != null else 0
	if veg >= 6:
		s *= 0.45
	elif veg >= 3:
		s *= 0.7
	return s

func eye_point() -> Vector3:
	if is_air():
		return hull.global_position
	if turret != null:
		return turret.global_position + Vector3(0, 0.6, 0)
	return position + Vector3(0, 2.0, 0)

func los_skip() -> float:
	return float(D["len"]) * 0.5

func thermal() -> bool:
	return String(cdat.get("opt", "")) in ["th", "th3", "uav", "cl"]

# boyut izi: gerçek genişlik × yükseklik (data/real_dims.json), yoksa modelin taban izi
func _calc_sig() -> void:
	var wh := Combat.dims(vid)
	var w := wh.x if wh.x > 0.0 else ext.x * 2.0
	var h := wh.y if wh.y > 0.0 else (3.0 if vtype in ["heli", "transport"] else 2.4)
	if vtype in ["heli", "transport"]:
		w = minf(w, 4.0)
	sig = clampf(sqrt(w * h / 8.6), 0.2, 1.6)

# güdümlü tanksavar füzesi (PSA, tank namlusu): ABD TOW-2B üstten geçişli, Rus Konkurs/Kornet/Refleks doğrudan.
# Tel/lazer güdümlü füze uçarken ikinci atış yok: bekleme = uçuş süresi + dolum
const ATGM_MODEL := {"rus_ifv_bmp2": "konkurs", "rus_ifv_bmp2m": "kornet", "rus_ifv_bmp3": "arkan", "rus_ifv_bmd4": "arkan",
	"rus_ifv_kurg": "kornet", "rus_apc_boom": "kornet", "rus_ifv_bmpt": "kornet"}

func _atgm_model() -> String:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	return "refleks" if vtype == "tank" else String(ATGM_MODEL.get(vid, "tow" if nat in ["usa", "gbr"] else "konkurs"))

func _fire_atgm(t: Unit, dist: float) -> void:
	var model := _atgm_model()
	var mp := muzzle_world() + Vector3(0, 0.4, 0)
	fired_t = G.time
	G.bal.rocket(mp, t.aim_point(), team, self, t, "atgm", model, _wr("atgm"))
	atgm_cd = dist / Ballistics.missile_speed("atgm", model, team) + 9.0
	Sfx.play3d("rpg", mp, 2.0)
	say("FÜZE ATILDI", 1.5)

func _fire_auto(t: Unit) -> void:
	if burst <= 0:
		burst = _burst_len(3, 5)
	burst -= 1
	main_cd = _auto_ival(0.26) if burst > 0 else randf_range(1.2, 2.2)
	fired_t = G.time
	var mp := muzzle_world()
	var tp := t.aim_point()
	var d := mp.distance_to(tp)
	var spread := (d * fcs * 2.5 + 0.3) * aim_mult() * (1.6 if absf(cur_speed) > 1.0 else 1.0)
	tp = _lead(t, mp, tp, Ammo.speed(ammo_auto, 1000.0))
	tp += Vector3(randf_range(-spread, spread), randf_range(-0.2, 0.4), randf_range(-spread, spread))
	G.bal.shell(mp, tp, team, self, t, "auto", ammo_auto)
	G.fx.muzzle(mp, (tp - mp).normalized(), true)
	Sfx.play3d("autocannon", mp, 0.0)
	recoil = 0.4

func _fire_hmg(t: Unit) -> void:
	if burst <= 0:
		burst = randi_range(5, 10)
	burst -= 1
	main_cd = 0.11 if burst > 0 else randf_range(0.7, 1.4)
	_hitscan(t, 30.0, 0.42, 12.0, "hmg", true)
	Sfx.play3d("hmg", muzzle_world(), 1.0, 0.08, 0.03)

func _coax(_dt: float) -> void:
	if vtype != "tank" or coax_cd > 0.0:
		return
	var t := coax_target
	if t == null or not is_instance_valid(t) or not t.alive:
		return
	if coax_burst <= 0:
		coax_burst = randi_range(6, 12)
	coax_burst -= 1
	coax_cd = 0.1 if coax_burst > 0 else randf_range(0.8, 1.6)
	_hitscan(t, 18.0, 0.32, 9.0, "bullet", false)
	Sfx.play3d("mg", position, -1.0, 0.08, 0.03)

func _hitscan(t: Unit, dmg: float, acc: float, sup: float, k: String, from_barrel: bool) -> void:
	shots += 1
	fired_t = G.time
	var mp := muzzle_world() if from_barrel else turret_world_pos() + forward() * 1.2 + Vector3(0, 0.3, 0)
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	if from_barrel:
		G.fx.muzzle(mp, dir, true)
	var d := mp.distance_to(tp)
	var R := _wr("mg", 1000.0) if not rng.is_empty() else 50.0
	var c := acc * (1.0 - pow(clampf(d / maxf(R, 1.0), 0.0, 1.0), 1.2) * 0.8)
	if t is Soldier:
		c *= [1.0, 0.72, 0.45][t.stance]
		c *= 1.0 - G.grid.cover_factor(t.position, t.torso_h(), position) * 0.75
	else:
		c = 0.85 * (1.0 - clampf(d / maxf(R, 1.0), 0.0, 1.0) * 0.5)
	if absf(cur_speed) > 1.0:
		c *= 0.6
	c /= aim_mult()
	var impact := tp
	if randf() < c:
		t.take_damage(dmg * randf_range(0.8, 1.2), self, k)
	else:
		var side := Vector3(-dir.z, 0, dir.x)
		impact = tp + side * randf_range(-1.5, 1.5) + dir * randf_range(-0.5, 3.0)
		impact.y = 0.02 if randf() < 0.6 else randf_range(0.0, 1.5)
		G.fx.impact(impact, "wall" if G.grid.height_at(impact) > impact.y else "dirt")
		for o in G.near(impact, 2.8):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(sup, position)
	if shots % 2 == 0:
		G.fx.tracer_cal(mp, impact, 260.0, Ammo.team_tracer(team), 12.7 if k == "hmg" else 7.62)

func _visuals(dt: float) -> void:
	hull.rotation.y = heading
	# yaylanma
	rock_v += (-rock * 30.0 - rock_v * 5.0) * dt
	rock += rock_v * dt
	hull.rotation.x = rock * 0.02
	var spin := cur_speed * dt
	for w in wheels:
		var wn: MeshInstance3D = w[0]
		wn.rotation.x -= spin / w[1]
	if engine:
		engine.pitch_scale = 0.7 + absf(cur_speed) / speed_max * 0.6
	if gunner:
		gunner.animate(dt, "aim" if target != null else "stand", 0.0)
	if hp < max_hp * 0.4:
		burn_t -= dt
		if burn_t <= 0.0:
			burn_t = 0.3
			var g := randf_range(0.12, 0.22)
			G.fx.emit(Fx.P_SMOKE, position + Vector3(randf_range(-0.5, 0.5), 1.6, randf_range(-0.5, 0.5)), Vector3(randf_range(-0.3, 0.3), randf_range(1.2, 2.0), randf_range(-0.3, 0.3)), randf_range(2.5, 4.0), 0.6, 2.4, -0.2, 0.4, Color(g, g, g, 0.6))

# ------------------------------------------------------------ hasar
func take_damage(amount: float, src, k := "bullet") -> void:
	var from := shot_from
	shot_from = Vector3.INF
	var po := shot_pen        # erken dönen dallarda (hava aracı, ölü) bir sonraki isabete taşınmasın
	shot_pen = []
	if not alive:
		return
	var m := 1.0
	if vtype in ["fpv", "loiter"]:
		hp -= amount
		if hp <= 0.0:
			destroy(null)
		return
	if is_air():
		match k:
			"bullet":
				m = 0.12
			"hmg":
				m = 0.55
			"crush", "grenade":
				m = 0.0
		hp -= amount * m
		last_hit = G.time
		if src != null and is_instance_valid(src):
			attacker = src
		if hp <= 0.0:
			destroy(src)
		return
	if from == Vector3.INF and src != null and is_instance_valid(src):
		from = src.position
	var pk := k
	if k == "bullet" and src != null and is_instance_valid(src) and src is Soldier and src.role == "sniper":
		pk = "sniper"
	shot_pen = po
	m = pen_mult(pk, from)
	if m <= 0.0:
		# delemedi: sekme (mürettebat yine de sarsılır)
		if k in ["ap", "rpg", "atgm", "topatk", "he"]:
			add_vstress(9.0)
			_crit_roll(0.0, 0.0, k)
		if src != null and is_instance_valid(src) and src is Unit:
			attacker = src
		last_hit = G.time
		if k in ["ap", "rpg", "atgm", "auto", "hmg", "topatk"]:
			Sfx.play3d("ricochet", position, 2.0 if k in ["ap", "rpg", "atgm"] else -6.0)
			if k in ["ap", "rpg", "atgm", "topatk"]:
				var sd := (aim_point() - from).normalized() if from != Vector3.INF else -forward()
				var nrm: Vector3 = [forward(), (right() if right().dot(from - position) > 0.0 else -right()), -forward(), Vector3.UP][clampi(last_side, 0, 3)]
				if k == "ap":
					G.fx.ricochet(aim_point(), sd, nrm)
				else:
					# HEAT delemedi: dışta patlar, reaktif zırh tuğlası infilakı
					G.fx.explosion(aim_point() + nrm * 0.3, 0.8, "rpg")
				if G.time - _nopen_t > 2.0:
					_nopen_t = G.time
					say("SEKTİ!" if last_side == 0 else "DELEMEDİ!")
		return
	var dmg := amount * m * (1.0 + wear * 0.25)
	if dmg <= 0.0:
		return
	wear = minf(1.0, wear + dmg / max_hp * 0.6)
	# delme efekti: geliş yönünde içe saçılma; HEAT'te jet parlaması
	if k in ["ap", "rpg", "atgm", "topatk"] and m > 0.46:
		var pd := (aim_point() - from).normalized() if from != Vector3.INF else -forward()
		G.fx.penetration(aim_point(), pd, k != "ap")
	hp -= dmg
	last_hit = G.time
	if src != null and is_instance_valid(src):
		attacker = src
	_subsystem_hit(dmg, src, k)
	_crit_roll(dmg, m, k)
	add_vstress(dmg / max_hp * 120.0)
	if hp <= 0.0:
		kill_k = k
		var kd: Vector3 = (aim_point() - from) if from != Vector3.INF else (position - src.position if src != null and is_instance_valid(src) else -forward())
		kd.y = 0.0
		kill_dir = kd.normalized() if kd.length() > 0.01 else -forward()
		kill_over = clampf(-hp / max_hp, 0.0, 2.0)
		destroy(src)

# atışın geldiği yöne göre zırh yanı: 0 ön, 1 yan, 2 arka, 3 üst
func armor_side(from: Vector3, k: String) -> int:
	var pd: Array = PEN.get(k, PEN["bullet"])
	if pd[3] or from == Vector3.INF:
		return 3
	var to := from - position
	to.y = 0.0
	if to.length() < 0.1:
		return 3
	var f := forward().dot(to.normalized())
	if f > 0.5:
		return 0
	if f < -0.6:
		return 2
	return 1

func armor_tab() -> Array:
	if not arm_tab.is_empty():
		return arm_tab
	if cat.has("armor"):
		return cat["armor"]
	return ARMOR.get(vtype, [])

func armor_value(kind: int, side: int) -> float:
	var a: Array = armor_tab()
	if a.is_empty():
		return 0.0
	return float(a[kind][side])

func pen_at(k: String, dist: float, ov: Array = []) -> float:
	var pd: Array = ov if ov.size() >= 3 else PEN.get(k, PEN["bullet"])
	# delme mesafeyle düşer (kinetik): namlu önünden 2 km'ye doğrusal, ötesinde aynı eğimle
	var f := dist / (2000.0 * Combat.K_RANGE)
	return maxf(0.0, lerpf(float(pd[1]), float(pd[2]), f))

# delme - zırh farkına göre hasar çarpanı (0 = delemedi)
func pen_mult(k: String, from: Vector3) -> float:
	var ov := shot_pen
	shot_pen = []
	var pd: Array = PEN.get(k, PEN["bullet"])
	if ov.size() >= 3:
		pd = [int(ov[0]), float(ov[1]), float(ov[2]), pd[3]]
	var side := armor_side(from, k)
	var a := armor_value(pd[0], side)
	var dist := 0.0 if from == Vector3.INF else from.distance_to(position)
	var p := pen_at(k, dist, pd)
	last_side = side
	last_pen = p
	if a <= 0:
		return 0.6 if k == "bullet" else 1.0
	var diff := p - a
	if diff >= 0.0:
		return 1.0 + minf(diff, 8.0) * 0.025
	# delemeyen isabet: kinetik küçük kalibre hiç işlemez (sınırda hafif), patlayıcı şok/parça hasarı verir
	if pd[0] == 0 and k in ["bullet", "sniper", "hmg", "auto"]:
		return 0.25 if diff > -1.0 else 0.0
	return maxf(0.0, 1.0 + diff * 0.3) * 0.45

func armor_text() -> String:
	var a: Array = armor_tab()
	if a.is_empty():
		return "-"
	# mm RHA eşdeğeri (oyun birimi × 20)
	return "%d/%d/%d/%d · HEAT %d/%d/%d/%d mm" % [int(a[0][0] * 20.0), int(a[0][1] * 20.0), int(a[0][2] * 20.0), int(a[0][3] * 20.0), int(a[1][0] * 20.0), int(a[1][1] * 20.0), int(a[1][2] * 20.0), int(a[1][3] * 20.0)]

func _subsystem_hit(dmg: float, src, k: String) -> void:
	var boom := k in ["rpg", "atgm", "topatk", "fpv", "mortar", "ap", "he", "shell", "big", "mine", "grenade"]
	# palet: patlama ve tanksavar
	if tracked() and tracks_broken <= 0.0:
		var pc := {"mine": 1.0, "rpg": 0.2, "atgm": 0.2, "topatk": 0.1, "ap": 0.14, "he": 0.18, "shell": 0.22, "big": 0.3}.get(k, 0.0)
		if randf() < pc:
			tracks_broken = 45.0
			say("PALET KOPTU!", 3.0)
	# teker: kurşun / patlama
	if wheeled():
		var tc := {"bullet": 0.03, "hmg": 0.08, "auto": 0.15, "grenade": 0.35, "shell": 0.4, "big": 0.5, "rpg": 0.3, "mine": 0.9, "he": 0.4}.get(k, 0.0)
		if randf() < tc and tires < maxi(wheels.size(), 4):
			tires += 1
			say("TEKER PATLADI!", 2.0)
	# mürettebat
	if crew_max <= 0:
		return
	var sniper: bool = src != null and is_instance_valid(src) and src is Soldier and src.role == "sniper"
	if armor == 0 and (k == "bullet" or k == "hmg"):
		# açık araç: nişancı ve sürücü vurulabilir
		if gunner and gunner_ok and randf() < (0.7 if sniper else 0.18):
			_kill_gunner(src)
		elif driver_ok and randf() < (0.35 if sniper else 0.06):
			_kill_driver(src)
	elif boom and dmg > 60.0 and randf() < 0.22:
		crew_n = maxi(0, crew_n - 1)
		if crew_n == 0:
			driver_ok = false
			gunner_ok = false
			say("MÜRETTEBAT ÖLDÜ!", 3.0)
		else:
			say("YARALI VAR!", 2.0)
	elif armor == 0 and boom and randf() < 0.25:
		if randf() < 0.5:
			_kill_gunner(src)
		else:
			_kill_driver(src)

func _heli(dt: float) -> void:
	if G.weather != null and G.weather.no_air():
		# kum fırtınası: yere in, bekle
		hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt)
		position += hvel * dt
		hull.position.y = move_toward(hull.position.y, 0.6, dt * 2.0)
		_rotor_tick(dt, 0.35 if hull.position.y <= 0.7 else 1.0)
		target = null
		return
	var goal := dest
	var t := target
	if sling_tgt != null:
		if can_sling(sling_tgt) and sling == null:
			goal = sling_tgt.position
		else:
			sling_tgt = null
	if drop_pt != Vector3.INF:
		goal = drop_pt
	if rope_pt != Vector3.INF:
		goal = rope_pt
	if forced_target != null and is_instance_valid(forced_target) and forced_target.hostile():
		goal = _attack_spot(dt)
	var d := goal - position
	d.y = 0
	var L := d.length()
	var want := Vector3.ZERO
	if L > 0.5:
		want = d / L * speed_max * clampf(L / 18.0, 0.0, 1.0)
	for o in G.near(position, 10.0):
		if o != self and o is Vehicle and o.vtype in ["heli", "transport"] and o.alive:
			var dv: Vector3 = position - o.position
			dv.y = 0
			if dv.length() > 0.1:
				want += dv.normalized() * 4.0
	var ev := _evade_vec(dt)
	if ev != Vector3.ZERO:
		want = want * 0.4 + ev
	hvel = hvel.move_toward(want, D["accel"] * dt * (2.2 if ev != Vector3.ZERO else 1.0))
	position += hvel * dt
	position.x = clampf(position.x, 2.0, G.MAP - 2.0)
	position.z = clampf(position.z, 2.0, G.MAP - 2.0)
	cur_speed = hvel.length()
	var face := heading
	if t != null and is_instance_valid(t) and t.alive:
		face = Soldier._yaw_of(t.position - position)
	elif hvel.length() > 1.0:
		face = Soldier._yaw_of(hvel)
	heading = rotate_toward(heading, face, D["turn"] * dt)
	if L < 1.5 and order == "move":
		order = ""
	var tgt_alt := ALT + (4.5 if sling != null else 0.0) - (3.5 if evade_t > 0.0 else 0.0)
	var hover := false
	if rope_pt != Vector3.INF and L < 6.0:
		tgt_alt = ROPE_ALT
		hover = _rope_tick(dt, L) or L < 6.0
	if landing:
		tgt_alt = 0.02 if is_cargo() else 0.6
		if L < 1.5 and hull.position.y < 0.9 and not land_hold:
			unload()
	if is_cargo():
		var hook_dy := hook_pos().y - hull.global_position.y
		if sling_tgt != null and L < 2.5:
			# yükün üstünde dur, kancayı indir
			tgt_alt = SLING_L + sling_tgt.top_h + 1.2 - hook_dy + 0.2
			hover = true
			if hull.position.y < tgt_alt + 0.35:
				_attach_sling(sling_tgt)
		elif sling != null and sling_drop:
			tgt_alt = SLING_L + sling.top_h + 1.2 - hook_dy + 0.05
			hover = true
			hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt)
			if hull.position.y < tgt_alt + 0.3:
				_release_sling()
		elif drop_pt != Vector3.INF and L < 3.0:
			tgt_alt = 6.0
			hover = true
			if hull.position.y < 6.4:
				_drop_crate()
		_cargo_visuals(dt)
	var local_v := hvel.rotated(Vector3.UP, -heading)
	var bank := 0.55 if evade_t > 0.0 else 0.3
	hull.rotation = Vector3(lerpf(hull.rotation.x, clampf(local_v.z * 0.025, -0.3, 0.3), dt * 3.0), heading, lerpf(hull.rotation.z, clampf(-local_v.x * 0.035, -bank, bank), dt * 4.0))
	_hb += dt
	if landing or hover or absf(hull.position.y - tgt_alt) > 0.4:
		hull.position.y = move_toward(hull.position.y, tgt_alt, dt * (5.0 if evade_t > 0.0 else 3.0))
	else:
		hull.position.y = tgt_alt + sin(_hb * 1.3) * 0.25
	_rotor_tick(dt, 1.0 if hull.position.y > 1.2 or not landing else 0.75)
	# rotor rüzgârı: alçaldıkça yerden toz kalkar ve ses yükselir (roadmap 22)
	var low := clampf(1.0 - hull.position.y / 22.0, 0.0, 1.0) * rotor_rpm
	if randf() < dt * (1.0 + low * 14.0) and low > 0.05:
		var ra: float = randf() * TAU
		var rd: float = randf_range(0.3, 1.0) * (ext.y * 1.6 + 2.0)
		G.fx.vehicle_dust(position + Vector3(cos(ra) * rd, 0.2, sin(ra) * rd))
	if engine != null and is_instance_valid(engine):
		engine.volume_db = -8.0 + low * 6.0
	rocket_cd -= dt
	hf_cd -= dt
	if vtype == "transport":
		if t != null and is_instance_valid(t) and t.alive and main_cd <= 0.0 and dist2(t) < _wr("mg", 30.0) and not landing:
			if burst <= 0:
				burst = randi_range(5, 9)
			burst -= 1
			main_cd = 0.12 if burst > 0 else randf_range(1.0, 2.0)
			_hitscan_from(hull.global_transform * Vector3(1.0, 0.2, -0.8), t, 16.0, 0.3, 9.0)
			Sfx.play3d("mg", position, -2.0, 0.08, 0.03)
		return
	if t == null or not is_instance_valid(t) or not t.alive:
		return
	var ang := absf(angle_difference(heading, Soldier._yaw_of(t.position - position)))
	if ang > 0.35:
		return
	var dist := dist2(t)
	if salvo > 0:
		salvo_t -= dt
		if salvo_t <= 0.0:
			salvo -= 1
			salvo_t = 0.16
			var side := 1.6 if salvo % 2 == 0 else -1.6
			var mp := hull.global_transform * Vector3(side, -0.4, -1.0)
			G.bal.rocket(mp, t.aim_point(), team, self, t, "rpg", "hydra")
			Sfx.play3d("rpg", mp, 0.0, 0.1, 0.05)
	elif hf_left > 0 and hf_cd <= 0.0 and t is Vehicle and t.armor > 0 and not t.is_air() and dist < _wr("atgm", 75.0) and _hf_locked(dt):
		# kanat altı raydan güdümlü tanksavar füzesi (ABD Hellfire / Rus Vikhr); işaretleme kilidi sonrası
		hf_left -= 1
		hf_cd = 6.0
		var hs := 1.9 if hf_left % 2 == 0 else -1.9
		var hp := hull.global_transform * Vector3(hs, -0.55, -0.6)
		G.bal.rocket(hp, t.aim_point(), team, self, t, "atgm", "hellfire" if team == 0 else "vikhr")
		G.fx.flash(hp, 5.0, 8.0, 0.08, Color(1.0, 0.8, 0.5))
		Sfx.play3d("rpg", hp, 3.0)
		say("FÜZE ATILDI")
	elif rocket_cd <= 0.0 and dist < _wr("rkt", 50.0) and (t is Vehicle or t is Building or randf() < 0.5) and not (t is Vehicle and t.armor >= 2 and hf_left > 0):
		# roket salvosu yumuşak / hafif zırhlı hedefe; ağır zırha (tank) güdümlü füze kaldıkça roket harcanmaz
		salvo = 4
		salvo_t = 0.0
		rocket_cd = 9.0
	if main_cd <= 0.0 and dist < _wr("auto", _wr("mg", 46.0)):
		if burst <= 0:
			burst = randi_range(6, 12)
		burst -= 1
		main_cd = 0.1 if burst > 0 else randf_range(0.8, 1.5)
		var gp := hull.global_transform * Vector3(0, -1.3, -4.6)
		_hitscan_from(gp, t, 28.0, 0.38, 12.0)
		Sfx.play3d("hmg", gp, 2.0, 0.08, 0.03)

# Hellfire/Vikhr: hedef işaretlenir (lazer) — ~2 sn hedefte kalınca atış
func _hf_locked(dt: float) -> bool:
	hf_lock += dt
	if hf_lock >= Ballistics.lock_time("hellfire" if team == 0 else "vikhr"):
		hf_lock = 0.0
		return true
	return false

# aktif koruma (roadmap 31): yaklaşan RPG / güdümlü füzeyi ~%70 olasılıkla vurur (üstten saldırıda %15,
# Afganit kinetik mermide %20), şarj sınırlı, iki önleme arası 0,6 sn
func aps_intercept(at: Vector3, k: String) -> bool:
	if aps_n <= 0 or G.time < aps_cd or not alive:
		return false
	var pc := 0.7
	if k == "topatk":
		pc = 0.15
	elif k in ["ap", "auto"]:
		pc = 0.2 if vid == "rus_mbt_14" else 0.0
	if pc <= 0.0:
		return false
	aps_n -= 1
	aps_cd = G.time + 0.6
	var ok := randf() < pc
	G.fx.flash(at, 7.0, 8.0, 0.08, Color(1.0, 0.85, 0.6))
	G.fx.explosion(at, 0.6, "flak")
	Sfx.play3d("expl_med", at, -4.0)
	if ok:
		say("APS ÖNLEDİ", 1.5)
	return ok

# saldırı emrindeki helikopterin atış konumu. Hedef seçilemiyorsa (görüş hattı kapalı) konumda 2,5 sn
# bekledikten sonra hedef çevresinde 50° döner; her tam turda mesafe daralır (32 → 22 → 14 m: daha dik açı
# ağaç/bina üstünden görür), sonra başa döner.
func _attack_spot(dt: float) -> Vector3:
	var ft: Unit = forced_target
	if atk_for != ft:
		atk_for = ft
		var off := position - ft.position
		off.y = 0.0
		atk_dir = off.normalized() if off.length() > 0.5 else Vector3.FORWARD
		atk_r = 32.0
		atk_t = 0.0
		atk_n = 0
	var goal := ft.position + atk_dir * atk_r
	if target == ft:
		atk_t = 0.0
	elif Vector2(goal.x - position.x, goal.z - position.z).length() < 5.0:
		atk_t += dt
		if atk_t > 2.5:
			atk_t = 0.0
			atk_n += 1
			atk_dir = atk_dir.rotated(Vector3.UP, deg_to_rad(50.0))
			if atk_n % 7 == 0:
				atk_r = [32.0, 22.0, 14.0][(atk_n / 7) % 3]
			if atk_n == 1:
				say("AÇI ARIYORUM", 2.0)
			goal = ft.position + atk_dir * atk_r
	return goal

# ------------------------------------------------------------ halatla iniş / çekme
func can_rope() -> bool:
	return vtype == "transport" and alive

func cmd_fastrope(p: Vector3) -> void:
	if not can_rope() or cargo.is_empty():
		return
	_rope_reset()
	rope_pt = G.on_ground(p)
	rope_mode = "down"
	dest = rope_pt
	order = "move"
	landing = false
	say("HALATLA İNİŞE GİDİYORUZ")

func cmd_rope_pick(p: Vector3) -> void:
	if not can_rope() or cargo.size() >= capacity():
		return
	_rope_reset()
	rope_pt = G.on_ground(p)
	rope_mode = "up"
	dest = rope_pt
	order = "move"
	landing = false
	say("HALATLA ALIM NOKTASINA")

func rope_anchor(i: int) -> Vector3:
	# halat kapı üstündeki koldan sarkar (sağ/sol kapı), ağır nakliyede arka rampa ağzı
	var lp: Vector3
	if is_cargo():
		lp = Vector3((-0.7 if i % 2 == 0 else 0.7), 0.6, ext.y * 0.85)
	else:
		lp = Vector3((ext.x + 0.35) * (1.0 if i % 2 == 0 else -1.0), 2.0, -ext.y * 0.1)
	return hull.global_transform * lp

func _rope_mesh(len_m: float) -> MeshInstance3D:
	var mb := MB.new()
	var segs := int(len_m / 0.5) + 1
	var col := Color(0.12, 0.11, 0.1)
	for k in segs:
		var y0 := -float(k) * len_m / segs
		var y1 := -float(k + 1) * len_m / segs
		mb.cyl_between(Vector3(sin(k * 0.7) * 0.02, y0, 0), Vector3(sin((k + 1) * 0.7) * 0.02, y1, 0), 0.03, 0.03, 5, col, false)
	var mi := MeshInstance3D.new()
	mi.mesh = mb.commit(Mats.vcs())
	return mi

func _rope_deploy(n: int) -> void:
	_free_ropes()
	for i in n:
		var a := rope_anchor(i)
		var L := maxf(a.y + 0.3, 1.0)
		var mi := _rope_mesh(L)
		G.main.world.add_child(mi)
		mi.global_position = a
		mi.scale = Vector3(1, 0.05, 1)
		var tw := mi.create_tween()
		tw.tween_property(mi, "scale:y", 1.0, 0.7).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		ropes.append([mi, i, L])
	Sfx.play3d("crumble", position, -12.0)

func _ropes_follow() -> void:
	for r in ropes:
		var mi: MeshInstance3D = r[0]
		if is_instance_valid(mi) and mi.get_meta("cut", false) == false:
			mi.global_position = rope_anchor(r[1])

# iniş bitti: halatlar koldan bırakılır, yere düşüp yığılır
func _rope_cut() -> void:
	for r in ropes:
		var mi: MeshInstance3D = r[0]
		if not is_instance_valid(mi):
			continue
		mi.set_meta("cut", true)
		var g := mi.global_position
		var tw := mi.create_tween()
		tw.tween_property(mi, "global_position:y", r[2] * 0.15, 0.6).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		tw.parallel().tween_property(mi, "scale:y", 0.15, 0.6)
		tw.parallel().tween_property(mi, "rotation:z", 1.4, 0.6)
		tw.tween_property(mi, "global_position:y", 0.05, 0.25)
		tw.tween_interval(25.0)
		tw.tween_callback(mi.queue_free)
		mi.global_position = g
	ropes.clear()
	say("HALATLAR BIRAKILDI")

func _free_ropes() -> void:
	for r in ropes:
		if is_instance_valid(r[0]):
			(r[0] as Node).queue_free()
	ropes.clear()

func _rope_reset() -> void:
	_free_ropes()
	rope_pt = Vector3.INF
	rope_mode = ""
	rope_t = 0.0
	rope_riders.clear()

# askı noktasında asılı kal; askerleri sırayla halattan indir / topla
func _rope_tick(dt: float, L: float) -> bool:
	if rope_pt == Vector3.INF:
		return false
	if L > 2.0 or absf(hull.position.y - ROPE_ALT) > 0.6:
		return false
	hvel = hvel.move_toward(Vector3.ZERO, D["accel"] * dt * 2.0)
	rope_t += dt
	if ropes.is_empty():
		if rope_t > 0.8:
			_rope_deploy(2 if rope_mode == "down" else 1)
			rope_next = 0.9
		return true
	_ropes_follow()
	rope_next -= dt
	if rope_mode == "down":
		rope_riders = rope_riders.filter(func(x): return is_instance_valid(x) and x.alive and x.state == "rope")
		if rope_next <= 0.0 and not cargo.is_empty():
			var sd = cargo[0]
			if is_instance_valid(sd):
				rope_next = 1.1
				cargo.erase(sd)
				sd.start_rope_down(self, rope_side % ropes.size())
				rope_side += 1
				rope_riders.append(sd)
			else:
				cargo.remove_at(0)
		if cargo.is_empty() and rope_riders.is_empty():
			if rope_next < -1.2:
				_rope_cut()
				rope_pt = Vector3.INF
				rope_mode = ""
				order = ""
	else:
		# SPIES: yakındaki dost askerler halata koşar, kancalanır, hep birlikte yukarı çekilir
		if rope_t < 1.6:
			for u in G.friends_near(rope_pt, 26.0, team):
				if u is Soldier and u.can_fight() and u.state in ["idle", "move"] and u.vehicle_in == null and rope_riders.size() + cargo.size() < capacity() and not rope_riders.has(u) and u.order != "hold":
					if u.selected or u.position.distance_to(rope_pt) < 14.0:
						rope_riders.append(u)
						u.start_rope_up(self)
		rope_riders = rope_riders.filter(func(x): return is_instance_valid(x) and x.alive and x.state in ["rope_wait", "rope_up", "move"] )
		var ready := rope_riders.filter(func(x): return x.state == "rope_wait")
		# hepsi kancalanınca çek; geciken varsa 12 sn sonra kancalı olanları çek (geç gelenler ardından çekilir)
		if not ready.is_empty() and rope_t > 2.0 and (ready.size() == rope_riders.size() or rope_t > 12.0):
			for x in ready:
				x.state = "rope_up"
				x.state_t = 0.0
		# süre sınırı: tırmanan varken halatı kesme (düşerlerdi); 60 sn kesin üst sınır
		var climbing := rope_riders.any(func(x): return x.state == "rope_up")
		if (rope_t > 40.0 and not climbing) or rope_t > 60.0 or (rope_riders.is_empty() and rope_t > 4.0):
			_rope_cut()
			rope_pt = Vector3.INF
			rope_mode = ""
			order = ""
	return true

# ------------------------------------------------------------ hava savunması / füze kaçınma
func _setup_air_defense(vt: String) -> void:
	var fam: String = cat.get("fam", "")
	if vt == "aa":
		if fam in ["sam_long", "sam_ru_long"]:
			sams = 8; sam_big = true; sam_range = 140.0
		elif fam in ["sam_mid", "sam_ru_tr", "sam_ru_truck"]:
			sams = 8; sam_big = true; sam_range = 110.0
		elif fam == "ciws":
			sams = 0
		else:
			sams = 6 if fam in ["lv_sam", "inf_manpads"] else 4
			sam_range = 85.0
	if vt in ["heli", "transport"]:
		flares = 12 if vt == "heli" else 16
		hf_left = 8 if vt == "heli" else 0
	# gerçek füze menzili (roadmap 49): Stinger 4,8 km, Tor 15 km, Buk 70 km, S-400 250 km (harita ölçeğinde,
	# köşegenle sınırlı); hedefi radar ya da optik bulur
	if vt == "aa" and rng.has("aa") and sams > 0:
		sam_range = float(rng["aa"])

# gelen güdümlü füze: helikopter fişek atar ve kırar; İHA yalnız manevra yapar
func on_missile(p) -> void:
	if not alive:
		return
	evade_t = 2.6
	evade_side = 1.0 if randf() < 0.5 else -1.0
	if vtype in ["heli", "transport"]:
		if flares > 0:
			flare_q += 3
			say("FÜZE! FİŞEK!", 2.0)
			# kızılötesi arayıcı fişeğe kanar (füzeye göre: Stinger %45, Igla %35, Verba %15, radar güdümlü %5-10)
			if randf() < Ballistics.decoy_chance(String(p.aid), p.big):
				var tw := create_tween()
				tw.tween_interval(randf_range(0.35, 0.8))
				tw.tween_callback(func():
					if is_instance_valid(self):
						p.decoy = position + Vector3(0, hull.position.y - 2.0, 0) - hvel * 0.3 + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
		else:
			say("FÜZE! FİŞEK BİTTİ!", 2.0)
	elif is_drone() and vtype != "fpv":
		if randf() < 0.18:
			p.decoy = position + Vector3(randf_range(-10, 10), hull.position.y + randf_range(-6, 2), randf_range(-10, 10))

func _flares_tick(dt: float) -> void:
	if flare_q <= 0 or flares <= 0:
		return
	flare_t -= dt
	if flare_t > 0.0:
		return
	flare_t = 0.22
	flare_q -= 1
	flares -= 1
	var base := position + Vector3(0, hull.position.y - 0.4, 0)
	var r := right()
	var b := -forward()
	for sg in [-1.0, 1.0]:
		G.bal.flare(base + r * sg * 0.9, hvel * 0.6 + r * sg * randf_range(9.0, 13.0) + b * randf_range(3.0, 6.0) + Vector3(0, randf_range(1.0, 4.0), 0))
	Sfx.play3d("smoke_pop", base, -4.0, 0.2, 0.1)

# kaçış: sert yana kırış + alçalma; yatış açısı artar
func _evade_vec(dt: float) -> Vector3:
	if evade_t <= 0.0:
		return Vector3.ZERO
	evade_t -= dt
	return right() * evade_side * speed_max * 1.3

func _sam_key() -> String:
	var fam: String = cat.get("fam", "")
	if fam in ["sam_long", "sam_ru_long"]:
		return "sam_long"
	if sam_big:
		return "sam_mid"
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	return "stinger" if nat in ["usa", "gbr"] else "verba"

func _fire_sam(t: Unit) -> bool:
	if sams <= 0 or sam_cd > 0.0 or not (t is Vehicle) or not t.is_air() or not t.alive:
		sam_lock = 0.0
		return false
	var d := dist2(t)
	if d > sam_range or d < 12.0:
		sam_lock = 0.0
		return false
	# arayıcı soğutma + kilit (Stinger ~3 sn, Verba 2,5, orta menzil 2, uzun 3): hedef izlenirken
	sam_lock += get_process_delta_time()
	if sam_lock < Ballistics.lock_time(_sam_key()):
		return not rng.has("auto")
	sam_lock = 0.0
	sams -= 1
	sam_cd = 7.0 if sam_big else 5.0
	var mp := (turret.global_position if turret else position) + Vector3(0, 1.4, 0)
	G.bal.sam(mp, t, team, self, sam_big, _sam_key())
	say("FÜZE ATILDI")
	return true

# İHA: emir noktası çevresinde yüksekte daire çizer; silahlı olan araçlara üstten füze atar
func lose_link() -> void:
	if link_lost or not alive:
		return
	link_lost = true
	link_t = 0.0
	say("BAĞLANTI KOPTU", 3.0)
	forced_target = null

# pervaneler: havadayken hızlı (stroboskop olmasın diye kare başına adım sınırlı), yerdeyken durgun
func _spin_props(dt: float) -> void:
	if props_n.is_empty():
		return
	var up := hull.position.y > 0.5 and alive
	for pr in props_n:
		(pr[0] as Node3D).rotate_object_local(pr[1], minf(dt * (70.0 if up else 0.0), 1.1))

func _uav(dt: float) -> void:
	_spin_props(dt)
	if link_lost:
		# bağ koptu: düz uçar, alçalır ve düşer
		link_t += dt
		position += hvel * dt
		hull.position.y = move_toward(hull.position.y, 0.0, dt * (0.6 + link_t * 0.25))
		hull.rotation = Vector3(-0.12 - link_t * 0.02, heading, -0.1)
		if hull.position.y <= 0.4 or position.x < 3.0 or position.z < 3.0 or position.x > G.MAP - 3.0 or position.z > G.MAP - 3.0:
			destroy(null)
		return
	var alt := HIGH_ALT if high_alt else UAV_ALT
	if G.weather != null and G.weather.no_air():
		hull.position.y = move_toward(hull.position.y, 6.0, dt * 3.0)
	else:
		hull.position.y = move_toward(hull.position.y, alt, dt * (2.2 if high_alt else 4.0))
	# büyük (görsel olarak küçültülmüş) İHA geniş yörüngede döner: MALE ~35 m, HALE ~47 m
	var R := (34.0 if high_alt else 26.0) * (1.0 + (1.0 - uav_vis) * 0.5)
	var c := dest
	var to_c := c - position
	to_c.y = 0.0
	var want: Vector3
	if to_c.length() > R + 6.0:
		want = to_c.normalized() * speed_max
	else:
		uav_ang += dt * speed_max / R
		var goal := c + Vector3(cos(uav_ang), 0, sin(uav_ang)) * R
		want = (goal - position)
		want.y = 0.0
		want = want.normalized() * speed_max
	var ev := _evade_vec(dt)
	if ev != Vector3.ZERO:
		want = (want * 0.3 + ev).limit_length(speed_max * 1.3)
		hull.position.y = move_toward(hull.position.y, alt - 5.0, dt * 6.0)
	hvel = hvel.move_toward(want, D["accel"] * dt * (2.5 if ev != Vector3.ZERO else 1.0))
	position += hvel * dt
	position.x = clampf(position.x, 2.0, G.MAP - 2.0)
	position.z = clampf(position.z, 2.0, G.MAP - 2.0)
	cur_speed = hvel.length()
	if hvel.length() > 0.5:
		heading = rotate_toward(heading, Soldier._yaw_of(hvel), D["turn"] * (5.0 if ev != Vector3.ZERO else 2.0) * dt)
	hull.rotation = Vector3(0.0, heading, -0.28 - (0.5 * evade_side if evade_t > 0.0 else 0.0))
	if vtype != "uav_armed":
		return
	missile_cd -= dt
	if missiles <= 0 or missile_cd > 0.0:
		return
	var best: Vehicle = null
	var bd := 1e9
	var mr := _wr("atgm", 75.0)
	for e in G.visible_enemies(team):
		if is_instance_valid(e) and e is Vehicle and e.alive and not e.is_air() and dist2(e) <= mr:
			var d: float = dist2(e) - e.max_hp * 0.02
			if forced_target == e:
				d -= 999.0
			if d < bd:
				bd = d
				best = e
	if best == null:
		return
	missiles -= 1
	missile_cd = 9.0
	var mp := position + Vector3(0, hull.position.y - 0.4, 0)
	G.bal.rocket(mp, best.aim_point(), team, self, best, "topatk")
	Sfx.play3d("rpg", mp, -2.0)
	say("FÜZE ATILDI")
	if missiles <= 0:
		say("MÜHİMMAT BİTTİ — ÜSSE DÖN", 3.0)

func _fpv(dt: float) -> void:
	_spin_props(dt)
	if G.weather != null and G.weather.no_air():
		hull.position.y = move_toward(hull.position.y, 0.2, dt * 3.0)
		return
	var t: Unit = forced_target
	if t == null or not is_instance_valid(t) or not t.alive:
		# yeni hedef: yakındaki düşman
		t = null
		# arama yarıçapı: dolanan mühimmat ~3 km, FPV ~1,5 km (kendi kamerasıyla; takımın gördükleri)
		var lm := vtype == "loiter"
		var bd := (3000.0 if lm else 1500.0) * Combat.K_RANGE
		for e in G.visible_enemies(team):
			if is_instance_valid(e) and e.alive and not (e is Building) and not (e is Vehicle and e.is_air()) and dist2(e) <= bd:
				var sc := dist2(e) - (40.0 if lm and e is Vehicle else 0.0)
				if sc < bd:
					bd = sc
					t = e
		forced_target = t
		if t == null:
			battery -= dt
			if loiter_pt != Vector3.INF and vtype == "fpv" and battery > 0.0:
				# hedef yoksa gösterilen noktada asılı kal, çevreyi tara
				var to_l := Vector3(loiter_pt.x - position.x, 0.0, loiter_pt.z - position.z)
				var wv := to_l.normalized() * minf(speed_max, to_l.length() * 1.5) if to_l.length() > 0.5 else Vector3.ZERO
				hvel = hvel.move_toward(wv, D["accel"] * dt)
				position += hvel * dt
				if hvel.length() > 0.5:
					heading = Soldier._yaw_of(hvel)
				hull.position.y = move_toward(hull.position.y, 7.0, dt * 3.0)
				hull.rotation = Vector3(-hvel.length() * 0.02, heading, sin(G.time * 7.0) * 0.04)
				return
			hp -= dt * 2.0
			if hp <= 0.0 or battery <= -10.0:
				destroy(null)
			return
	var tp := t.aim_point()
	var to := tp - (position + Vector3(0, hull.position.y, 0))
	var flat := Vector3(to.x, 0, to.z)
	var dist := flat.length()
	var want := flat.normalized() * speed_max
	if vtype == "loiter":
		# dalış: yakınken yavaşla, irtifayı hızla düşür
		want *= clampf(dist / 10.0, 0.35, 1.0)
	hvel = hvel.move_toward(want, D["accel"] * dt)
	position += hvel * dt
	heading = Soldier._yaw_of(hvel) if hvel.length() > 0.5 else heading
	hull.rotation = Vector3(-0.35, heading, sin(G.time * 9.0) * 0.08)
	# alçal ve dal
	var alt := clampf(dist * 0.25, tp.y, 9.0) if vtype == "fpv" else clampf(dist * 0.6, tp.y, 18.0)
	hull.position.y = move_toward(hull.position.y, alt, dt * (6.0 if vtype == "fpv" else 16.0))
	cur_speed = hvel.length()
	if dist < 14.0 and randf() < dt * 4.0:
		for s in G.enemies_near(position, 10.0, team):
			if s is Soldier:
				s.on_drone(position)
				break
	if (dist < 1.2 and absf(to.y) < 1.8) or (vtype == "loiter" and dist < 2.4 and to.y > -2.6):
		destroy(t)

func _hitscan_from(mp: Vector3, t: Unit, dmg: float, acc: float, sup: float) -> void:
	shots += 1
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	G.fx.muzzle(mp, dir, true)
	var c := acc
	if t is Soldier:
		c *= [1.0, 0.8, 0.6][t.stance]
	else:
		c = 0.8
	var impact := tp
	if randf() < c:
		t.take_damage(dmg, self, "hmg")
	else:
		impact = Vector3(tp.x + randf_range(-2, 2), 0.02, tp.z + randf_range(-2, 2))
		G.fx.impact(impact, "dirt")
		for o in G.near(impact, 3.0):
			if o is Soldier and o.team != team and o.alive:
				o.add_suppression(sup, position)
	if shots % 2 == 0:
		G.fx.tracer_cal(mp, impact, 260.0, Ammo.team_tracer(team), 12.7)

# rotor devri ve görüntüsü: devir hedefe yumuşak yaklaşır (açılış ~4 sn); paller hep görünür, kare başına
# dönüş pal aralığının %38'iyle sınırlı (stroboskop etkisi yok); disk yalnız yüksek devirde, hafif
func _rotor_tick(dt: float, want: float) -> void:
	rotor_rpm = move_toward(rotor_rpm, want, dt * (0.25 if want > rotor_rpm else 0.4))
	var period := TAU / float(maxi(rotor_nb, 2))
	var step := minf(ROTOR_W * rotor_rpm * dt, period * 0.38)
	rotor.rotation.y += step
	if rotor_blades:
		rotor_blades.visible = true
	if rotor_disc:
		rotor_disc.visible = rotor_rpm > 0.5
		rotor_disc.transparency = clampf(1.0 - (rotor_rpm - 0.5) * 2.0, 0.0, 1.0)
	if trotor:
		if M.get("meta", {}).get("trotor_y", false):
			trotor.rotation.y -= step
		else:
			trotor.rotation.x += minf(ROTOR_W * 4.5 * rotor_rpm * dt, PI * 0.3)
	if engine != null and is_instance_valid(engine):
		engine.pitch_scale = 0.55 + 0.45 * rotor_rpm

static func _rotor_disc_mat() -> ShaderMaterial:
	if _disc_mat == null:
		var sh := Shader.new()
		sh.code = """shader_type spatial;
render_mode unshaded, cull_disabled, depth_draw_never, shadows_disabled;
global uniform float game_time;
void fragment() {
	vec2 p = UV * 2.0 - 1.0;
	float r = length(p);
	float a = atan(p.y, p.x);
	float blades = 0.5 + 0.5 * sin(a * 5.0 - game_time * 60.0);
	// hafif bulanıklık: palin süpürdüğü halka uca doğru belirginleşir (uç hızı yüksek), uç şeridi izi
	float ring = smoothstep(1.0, 0.94, r) * smoothstep(0.08, 0.3, r) * (0.45 + 0.55 * r);
	ALBEDO = vec3(0.07);
	ALPHA = ring * (0.07 + 0.05 * blades) + smoothstep(0.985, 0.95, r) * smoothstep(0.9, 0.95, r) * 0.14;
}
"""
		_disc_mat = ShaderMaterial.new()
		_disc_mat.shader = sh
	return _disc_mat

func _heli_crash() -> void:
	# kontrolsüz düşüş: kuyruk rotoru gider, gövde kendi ekseninde döner, pal yavaşlar;
	# bulanık disk kaybolur, gerçek pallar görünür; yere çarpınca pallar kırılıp savrulur
	if rotor_disc:
		rotor_disc.visible = false
	if rotor_blades:
		rotor_blades.visible = true
	var tw := create_tween()
	var dur := clampf(hull.position.y / 6.0, 1.2, 2.6)
	var spin := randf_range(5.0, 9.0) * dur
	var start_y := hull.position.y
	var h0 := heading
	var drift := hvel * 0.6
	var tilt := randf_range(0.35, 0.7) * (1.0 if randf() < 0.5 else -1.0)
	var last := [0.0]
	tw.tween_method(func(k: float):
		var dk: float = k - last[0]
		last[0] = k
		hull.position.y = lerpf(start_y, 0.5, k * k)
		hull.rotation.y = h0 + spin * (k * k * 0.6 + k * 0.4)
		hull.rotation.z = tilt * k
		hull.rotation.x = -0.25 * k
		position += drift * dk * dur
		if rotor:
			rotor.rotation.y += (1.0 - k * 0.7) * 1.1
		if trotor:
			trotor.rotation.x += (1.0 - k) * 0.6
		if randf() < 0.7:
			G.fx.emit(Fx.P_SMOKE, hull.global_position + Vector3(0, 0.6, 0), Vector3(randf_range(-0.4, 0.4), 1.5, randf_range(-0.4, 0.4)), randf_range(2.5, 4.0), 0.8, 3.2, -0.25, 0.6, Color(0.08, 0.08, 0.08, 0.85))
		if randf() < 0.35:
			G.fx.emit(Fx.P_FIRE, hull.global_position + Vector3(0, 0.9, 0), Vector3(0, 1.0, 0), 0.5, 0.6, 1.3, -0.5, 1.0, Color(1.0, 0.55, 0.2, 1.0)), 0.0, 1.0, dur)
	tw.tween_callback(func():
		G.explode(position + Vector3(0, 0.8, 0), 4.5, 90.0, "big", team, self, team)
		G.fx.burn(position + Vector3(0, 0.8, 0), 35.0, 1.2)
		G.cam.shake(0.4, position)
		# pallar kırılır: dönen göbek gizlenir, kırık pal parçaları savrulur
		if rotor:
			rotor.visible = false
			for i in 4:
				var a := randf() * TAU
				var piece := MeshInstance3D.new()
				var bm := BoxMesh.new()
				bm.size = Vector3(randf_range(1.5, 3.0), 0.04, 0.35)
				piece.mesh = bm
				piece.material_override = Mats.burnt()
				G.world.add_child(piece)
				piece.global_position = position + Vector3(0, 1.6, 0)
				piece.rotation.y = a
				var to := position + Vector3(cos(a), 0, sin(a)) * randf_range(4.0, 9.0)
				var pt := piece.create_tween()
				pt.set_parallel(true)
				pt.tween_property(piece, "global_position", Vector3(to.x, 0.05, to.z), 0.7).set_ease(Tween.EASE_OUT)
				pt.tween_property(piece, "rotation:y", a + randf_range(4.0, 9.0), 0.7)
		if trotor:
			trotor.visible = false
		hull.rotation.x = 0.0
		G.grid.set_static_rect(position, Vector2(3.0, 9.0), h0, 1.2, Grid.K_WRECK))

func destroy(src) -> void:
	if not alive:
		return
	if vtype in ["fpv", "loiter"]:
		alive = false
		var p := position + Vector3(0, hull.position.y, 0)
		var big := vtype == "loiter"
		G.explode(p, 3.4 if big else 2.6, 180.0 if big else 150.0, "rpg", team, operator if operator != null and is_instance_valid(operator) else self)
		for v in G.near(p, 3.5):
			if v is Vehicle and v != self and v.alive and v.team != team:
				v.take_damage(330.0 if big else 240.0, self, "topatk" if big else "rpg")
		queue_free()
		return
	if vtype in ["uav", "uav_armed"]:
		alive = false
		G.credit_kill(src, self)
		var p2 := position + Vector3(0, hull.position.y, 0)
		G.fx.explosion(p2, 1.0, "big")
		Sfx.play3d("expl_med", p2, 2.0)
		# enkaz düşer
		var tw := create_tween()
		tw.tween_property(hull, "position:y", 0.3, 2.2).set_ease(Tween.EASE_IN)
		tw.parallel().tween_property(hull, "rotation:z", 1.4, 2.2)
		tw.tween_callback(func():
			G.explode(position + Vector3(0, 0.3, 0), 2.5, 40.0, "grenade", -1, null, team)
			queue_free())
		return
	if vtype in ["heli", "transport"]:
		for r in rope_riders:
			if is_instance_valid(r) and r.alive and r.state in ["rope", "rope_up"]:
				r.rope_fall()
		rope_riders.clear()
		_free_ropes()
		alive = false
		wreck = true
		_cargo_lost("crash")
		G.credit_kill(src, self)
		if selected and G.player:
			G.player.deselect(self)
		if engine:
			engine.stop()
		G.fx.explosion(aim_point(), 1.2, "big")
		Sfx.play3d("expl_med", aim_point(), 4.0)
		for mi in _meshes(self):
			if mi != rotor_disc and mi != rotor_blades:
				Art.burn(mi)
		_heli_crash()
		return
	alive = false
	wreck = true
	cur_speed = 0.0
	G.credit_kill(src, self)
	if selected and G.player:
		G.player.deselect(self)
	# imha biçimi (roadmap 12) öldüren isabete göre: mühimmat türü, vuruş yönü (yan/arka cephane), fazla hasar.
	# Üstten saldırı / topçu / FPV: cephane infilakı, taret dimdik fırlar. Yandan-arkadan HEAT / kinetik:
	# taret ve gövde cephanesi — taret vuruş yönünde savrulur; önden delme çoğunlukla etkisiz bırakır.
	# Mayın: alttan kaldırır (hafif araç devrilir). Hafif araç ağır patlamada yan yatar / ters döner.
	var heavy := vtype in ["tank", "ifv", "arty", "aa"]
	var light := armor == 0 or vtype in ["technical", "truck"]
	var r := randf()
	var mode := "brew"
	match kill_k:
		"topatk", "fpv", "big", "shell", "mortar":
			if heavy:
				mode = "cookoff" if r < 0.55 else ("catastrophic" if r < 0.8 else "brew")
			else:
				mode = "flip" if (light and kill_k in ["big", "shell"] and r < 0.5) else ("catastrophic" if r < 0.6 else "brew")
		"mine":
			mode = "flip" if light else ("brew" if r < 0.6 else "knocked")
		"atgm", "rpg", "ap":
			var flank := last_side in [1, 2]
			if heavy:
				if flank:
					mode = "cookoff" if r < 0.45 else ("brew" if r < 0.8 else "knocked")
				else:
					mode = "knocked" if r < 0.5 else ("brew" if r < 0.85 else "cookoff")
			else:
				mode = "flip" if (light and kill_k != "ap" and kill_over > 0.5 and r < 0.45) else ("catastrophic" if r < 0.35 else ("brew" if r < 0.8 else "knocked"))
		_:
			if heavy:
				mode = "cookoff" if r < 0.35 else ("catastrophic" if r < 0.5 else ("brew" if r < 0.8 else "knocked"))
			else:
				mode = "catastrophic" if r < 0.25 else ("brew" if r < 0.75 else "knocked")
	if kill_over > 1.2 and heavy and mode in ["brew", "knocked"]:
		mode = "catastrophic"
	var late := false
	if force_mode == "late":
		mode = "brew"
		late = true
	elif force_mode != "":
		mode = force_mode
	kill_mode = mode
	_cargo_lost(mode)
	_crew_lost(mode)
	var cp := position + Vector3(0, 1.0, 0)
	if G.grid.is_water(position):
		# gövde boyuna göre sıçrama ve dalga halkası (cip ~0.9, tank ~2.4)
		var wsz := clampf(float(D.get("len", 6.0)) / 3.6, 0.7, 3.0)
		G.fx.water_splash(position, wsz)
		for mi in _meshes(self):
			Art.burn(mi)
		var tw2 := create_tween()
		tw2.tween_property(hull, "position:y", -2.6, 6.0).set_ease(Tween.EASE_IN)
		tw2.parallel().tween_property(hull, "rotation:z", randf_range(-0.5, 0.5), 6.0)
		tw2.tween_callback(func(): visible = false)
		for i in 6:
			var tw3 := create_tween()
			tw3.tween_interval(randf_range(0.3, 5.0))
			tw3.tween_callback(func(): G.fx.water_splash(position + Vector3(randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)) * wsz, 0.3 + 0.1 * wsz))
		return
	# 94: taretli ağır araçta cephane infilakı taret kopmasıyla birlikte (katı cisim, _turret_event)
	var has_t := turret != null and turret_mi != null and turret_mi.mesh != null
	var blow := has_t and heavy and mode in ["cookoff", "catastrophic"]
	match mode:
		"catastrophic":
			G.explode(cp, 6.5, 90.0, "big", team, self, team)
			G.fx.fireball(cp + Vector3(0, 0.6, 0), 2.0 if heavy else 1.4)
			G.fx.mushroom(cp, 1.6 if heavy else 1.0)
			G.fx.fire_column(position + Vector3(0, 1.2, 0), randf_range(40.0, 70.0), 1.3)
			G.fx.crater(position, D["len"] * 0.75)
			_debris(8 if heavy else 5, 9.0)
			G.fx.burn(position + Vector3(0, 1.0, 0), randf_range(40.0, 70.0), 1.5)
			hull.rotation.z += randf_range(-0.25, 0.25)
			hull.position.y -= 0.15
		"cookoff":
			if blow:
				# delme anı: içeride yangın, kapak ağızlarından alev dili ve duman; asıl cephane infilakı taret
				# kopmasıyla birlikte (0,5–2,2 sn sonra, _turret_blow)
				G.fx.explosion(cp + Vector3(0, 0.5, 0), 0.7, "rpg")
				Sfx.play3d("expl_med", cp, 0.0)
				G.fx.cookoff(turret_world_pos() + Vector3(0, 0.7, 0), randf_range(2.0, 3.0), 0.45)
				G.fx.burn(position + Vector3(0, 1.6, 0), randf_range(45.0, 80.0), 1.6)
			else:
				_cookoff_boom(cp)
		"brew":
			G.explode(cp, 3.0, 40.0, "big", team, self, team)
			G.fx.fireball(cp, 0.9)
			G.fx.fire_column(position + Vector3(0, 1.3, 0), randf_range(30.0, 55.0), 1.0 if heavy else 0.8)
			_debris(2, 4.0)
		"flip":
			# patlama aracı kaldırır, patlamanın ters yönüne yan yatar ya da ters döner
			G.explode(cp, 3.5, 50.0, "big", team, self, team)
			G.fx.fireball(cp, 1.0)
			G.fx.fire_column(position + Vector3(0, 0.8, 0), randf_range(25.0, 45.0), 0.8)
			_debris(3, 6.0)
			var away := kill_dir
			var roll_s := signf(away.dot(right())) if absf(away.dot(right())) > 0.2 else (1.0 if randf() < 0.5 else -1.0)
			var full := kill_over > 0.9 or randf() < 0.35
			var twf := create_tween()
			var y0 := hull.position.y
			twf.tween_property(hull, "position:y", y0 + 1.4, 0.28).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
			twf.parallel().tween_property(hull, "rotation:z", hull.rotation.z - roll_s * (PI if full else PI * 0.5), 0.75)
			twf.parallel().tween_property(self, "position", position + Vector3(away.x, 0, away.z) * 1.6, 0.75)
			twf.tween_property(hull, "position:y", y0 + (0.25 if full else ext.x * 0.6), 0.3).set_ease(Tween.EASE_IN).set_trans(Tween.TRANS_QUAD)
		_:
			G.fx.explosion(cp, 0.8, "rpg")
			Sfx.play3d("expl_med", cp, 0.0)
			G.fx.burn(position + Vector3(0, 1.5, 0), randf_range(15.0, 25.0), 0.5)
	G.fx.scorch(position, D["len"] * 1.2)
	for mi in _meshes(self):
		Art.burn(mi)
	if gunner:
		gunner.visible = false
	if cmdr:
		cmdr.visible = false
	if engine:
		engine.stop()
	if blow:
		# öldüren isabet cephaneyi hemen patlattıysa (infilak) taret anında, cephane yangınında birkaç saniye sonra
		_turret_event(mode, 0.0 if mode == "catastrophic" else randf_range(0.5, 2.2))
	elif has_t and heavy and mode == "brew" and (late or randf() < (0.42 if _carousel() else 0.25)):
		# yanan araçta gecikmeli cephane infilakı: alev cephaneye ulaşınca (6–24 sn)
		_turret_event("late", 3.0 if late else randf_range(6.0, 24.0))
	G.grid.set_static_rect(position, Vector2(D["len"] * 0.45, D["len"] * 0.85), heading, 1.3, Grid.K_WRECK)
	if vtype == "truck" and G.logi:
		G.logi.truck_lost(self)
	# mürettebat kaçar
	if vtype in ["tank", "apc", "ifv"] and (mode == "knocked" or (mode == "brew" and randf() < 0.5)):
		for i in randi_range(1, 3):
			G.main.spawn_soldier(team, "rifle", position + Vector3(randf_range(-2.5, 2.5), 0, randf_range(-2.5, 2.5)), null, 50.0)

# cephane infilakı: patlama, ateş topu, alev sütunu, kapaktan cephane jeti, krater, parçalar, ikincil infilaklar
func _cookoff_boom(cp: Vector3, with_burn := true) -> void:
	G.explode(cp, 4.5, 70.0, "big", team, self, team)
	G.fx.fireball(cp + Vector3(0, 0.8, 0), 1.5)
	G.fx.fire_column(position + Vector3(0, 1.6, 0), randf_range(45.0, 80.0), 1.2)
	G.fx.cookoff(position + Vector3(0, 2.0, 0), randf_range(6.0, 11.0), 1.0)
	G.fx.crater(position, D["len"] * 0.55)
	_debris(4, 6.0)
	if with_burn:
		G.fx.burn(position + Vector3(0, 1.6, 0), randf_range(45.0, 80.0), 1.6)
	for i in randi_range(3, 6):
		var tw0 := create_tween()
		tw0.tween_interval(randf_range(0.8, 6.0))
		tw0.tween_callback(func():
			var q := position + Vector3(randf_range(-1.0, 1.0), 1.8, randf_range(-1.0, 1.0))
			G.fx.explosion(q, 0.7, "rpg")
			G.fx.flash(q, 6.0, 8.0, 0.08)
			Sfx.play3d("expl_small", q, 0.0)
			for k in 6:
				G.fx.emit(Fx.P_FIRE, q, Vector3(randf_range(-1, 1), randf_range(6, 11), randf_range(-1, 1)), randf_range(0.4, 0.8), 0.6, 1.6, -2.0, 0.6, Color(1.8, 0.9, 0.3, 1)))

func _nat() -> String:
	return G.nation[team] if team >= 0 and team < G.nation.size() else ""

# taret altında karusel otomatik doldurucu (T-72 / T-80 / T-90, T-14; BMP/BMD'de taret çevresinde cephane):
# cephane infilakında taret çok daha sık ve yükseğe fırlar
func _carousel() -> bool:
	var fam := String(cat.get("fam", ""))
	if fam != "":
		return fam in ["mbt_ru", "mbt_t14", "ifv_bmp", "ifv_bmd"]
	return vtype == "tank" and _nat() == "rus"

# arka taret cephane bölmesi atılır panelli (M1 ailesi): infilak paneli dışarı atar, taret yerinde kalır
func _blowout() -> bool:
	var fam := String(cat.get("fam", ""))
	if fam != "":
		return fam == "mbt"
	return vtype == "tank" and _nat() == "usa"

# 94: cephane infilakı ve taret kopması; delay > 0: önce içeride yangın (kapaklardan alev), sonra infilak.
# "late": yanan araçta alev cephaneye ulaşınca — önce tek tek patlayan mermiler
func _turret_event(mode: String, delay: float) -> void:
	if delay <= 0.01:
		_turret_blow(mode)
		return
	var tw := create_tween()
	tw.tween_interval(delay)
	tw.tween_callback(_turret_blow.bind(mode))
	if mode == "late":
		for i in randi_range(2, 4):
			var tw2 := create_tween()
			tw2.tween_interval(maxf(delay - randf_range(0.3, 2.8), 0.1))
			tw2.tween_callback(func():
				var q := turret_world_pos() + Vector3(randf_range(-0.6, 0.6), 0.9, randf_range(-0.6, 0.6))
				G.fx.explosion(q, 0.45, "rpg")
				Sfx.play3d("expl_small", q, -4.0))

func _turret_blow(mode: String) -> void:
	if turret == null or not is_instance_valid(turret) or turret.get_parent() != hull or turret_mi == null or turret_mi.mesh == null:
		return
	var cp := position + Vector3(0, 1.0, 0)
	if _blowout() and mode != "catastrophic" and (force_style == "vent" or (force_style == "" and randf() < 0.85)):
		_bustle_vent()
		return
	if mode != "catastrophic":
		_cookoff_boom(cp, false)
	turret_style = force_style if force_style != "" else _turret_style(mode)
	var ta: AABB = turret_mi.mesh.get_aabb()
	print("TURRET %s mode=%s style=%s side=%d k=%s seat=%.2f t_aabb=%s hull_aabb=%s" % [vid if vid != "" else vtype, mode, turret_style, last_side, kill_k, turret.position.y + ta.position.y, ta, _hull_aabb()])
	_turret_launch(turret_style)

# kopma biçimi: üstten saldırı / topçu → çoğunlukla dimdik yükselip takla; yandan-arkadan delme → vuruş
# yönünde yana savrulur ya da güverteden kayar; önden → arkaya (motor güvertesine) devrilir ya da kalkıp
# gövdeye eğik oturur; yanan araçta gecikmeli infilak çoğunlukla kaldırıp düşürür
func _turret_style(mode: String) -> String:
	var top := kill_k in ["topatk", "fpv", "big", "shell", "mortar"] or last_side == 3
	var r := randf()
	if _carousel():
		r *= 0.85      # karusel: dimdik fırlama daha olası
	if mode == "catastrophic":
		if top:
			return "pop" if r < 0.6 else ("toss" if r < 0.85 else "flipback")
		return "pop" if r < 0.35 else ("toss" if r < 0.72 else "flipback")
	if mode == "late":
		return "pop" if r < 0.35 else ("lift" if r < 0.7 else ("toss" if r < 0.9 else "slide"))
	if top:
		return "pop" if r < 0.5 else ("lift" if r < 0.8 else "toss")
	if last_side in [1, 2]:
		return "toss" if r < 0.4 else ("slide" if r < 0.6 else ("pop" if r < 0.8 else "lift"))
	return "flipback" if r < 0.35 else ("lift" if r < 0.7 else "pop")

func _rand_unit() -> Vector3:
	var v := Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
	return v.normalized() if v.length() > 0.01 else Vector3.UP

func _rand_h(a: float, b: float) -> Vector3:
	var ang := randf() * TAU
	return Vector3(cos(ang), 0.0, sin(ang)) * randf_range(a, b)

# gövde örgülerinin (taret hariç) gövde uzayındaki kapsamı
func _hull_aabb() -> AABB:
	var a := AABB()
	var first := true
	for c in hull.get_children():
		if c is MeshInstance3D and (c as MeshInstance3D).mesh != null and c != rotor_disc:
			var bb: AABB = (c as MeshInstance3D).transform * (c as MeshInstance3D).mesh.get_aabb()
			a = bb if first else a.merge(bb)
			first = false
	if first:
		a = AABB(Vector3(-ext.x, 0.0, -ext.y), Vector3(ext.x * 2.0, 1.6, ext.y * 2.0))
	return a

# taret katı cisim olarak fırlar: ilk hız + takla biçime göre; gövde güvertesine / araziye çarpar, seker,
# yuvarlanır, yatar. Ara sıra namlu beşikten kopup ayrı uçar. Boşalan taret yuvası kararır, içi kor.
func _turret_launch(style: String) -> void:
	var tpos := turret.position
	var ta: AABB = turret_mi.mesh.get_aabb()
	var seat_y := tpos.y + ta.position.y
	var hab := _hull_aabb()
	var tp := turret_world_pos()
	var up := Vector3.UP
	var fw := forward()
	var rt := right()
	var dd := Vector3(kill_dir.x, 0.0, kill_dir.z)
	dd = dd.normalized() if dd.length() > 0.1 else _rand_h(1.0, 1.0)
	# yükseklik ölçülü (kullanıcı: "çok yükseğe uçuyor"): en şiddetli dimdik fırlamada tepe ~2–5 m, yana
	# savrulmada ~1–1,5 m, devrilmede ~1 m, kalkıp oturmada ~0,5 m — takla açısal hızla, yükseklikle değil
	var pw := clampf((1.0 if vtype == "tank" else (0.85 if vtype == "ifv" else 0.75)) * (0.92 + 0.12 * kill_over) * (1.06 if _carousel() else 1.0), 0.7, 1.12)
	var v0 := Vector3.ZERO
	var w0 := Vector3.ZERO
	match style:
		"pop":
			v0 = up * randf_range(6.5, 9.5) * pw + _rand_h(0.3, 1.4) + dd * randf_range(0.0, 1.0)
			w0 = _rand_unit() * randf_range(2.0, 4.5) + up * randf_range(-2.0, 2.0)
		"toss":
			v0 = up * randf_range(4.0, 5.5) * pw + dd * randf_range(2.5, 4.5) * pw
			w0 = up.cross(dd).normalized() * randf_range(2.2, 4.2) + _rand_unit() * 0.5
		"flipback":
			v0 = up * randf_range(3.6, 5.0) * pw - fw * randf_range(1.2, 2.4) * pw
			w0 = rt * randf_range(2.8, 4.2) + _rand_unit() * 0.4
		"lift":
			# cephane yanması (infilak değil): taret halkadan kalkar, eğik düşüp gövdeye çarpık oturur
			v0 = up * randf_range(2.8, 3.8) + _rand_h(0.9, 1.6)
			w0 = _rand_h(0.6, 1.2) + up * randf_range(-0.7, 0.7)
		_:
			# slide: vuruşun ters yanına, güverteden kayarak düşer
			var sd := rt * (signf(dd.dot(rt)) if absf(dd.dot(rt)) > 0.15 else (1.0 if randf() < 0.5 else -1.0))
			v0 = up * randf_range(2.0, 3.0) * pw + sd * randf_range(1.6, 2.8) * pw
			w0 = up.cross(sd) * randf_range(1.0, 2.0)
	var has_gun := barrel_mi != null and barrel_mi.mesh != null
	if has_gun and barrel != null:
		# yükseliş düzeneği kopar: namlu beşikte serbest kalır (aşağı sarkar ya da kalkık kalır)
		barrel.rotation.x = randf_range(-0.22, 0.28)
	var gun_off := has_gun and (force_gun_off == 1 or (force_gun_off < 0 and style in ["pop", "toss"] and randf() < 0.18))
	var parts: Array = [[turret_mi, 0.82, 0.985]]
	var gb: DebrisBody = null
	if gun_off:
		gb = DebrisBody.make(barrel, [[barrel_mi, 1.0, 1.0]], G.world)
	elif has_gun:
		parts.append([barrel_mi, 0.18, 1.0])
	var ring_r := clampf(minf(ta.size.x, ta.size.z) * 0.36, 0.35, 1.3)
	var db := DebrisBody.make(turret, parts, G.world)
	db.add_obstacle(hull, hab, seat_y, Vector4(tpos.x, tpos.z, ring_r, 0.22))
	db.fx_size = clampf(ta.size.x * 0.45, 0.5, 2.0)
	db.smolder = randf_range(25.0, 50.0)
	db.block = Vector2(ta.size.x, ta.size.z) * absf(hull.scale.x)
	db.launch(v0, w0)
	turret_body = db
	if gb != null:
		gb.add_obstacle(hull, hab, seat_y)
		gb.fx_size = 0.5
		gb.rest = 0.3
		gb.launch(v0 * randf_range(0.8, 1.05) + _rand_h(1.0, 2.5), w0 * 0.5 + _rand_unit() * randf_range(2.0, 4.0))
	# halka ağzından alev jeti ve parlama; boşalan yuva
	G.fx.cookoff(tp + Vector3(0, 0.2, 0), randf_range(2.0, 4.0), 1.5)
	G.fx.flash(tp, 8.0, 14.0, 0.25)
	Sfx.play3d("expl_big", tp, 3.0)
	_turret_hole(Vector3(tpos.x, seat_y, tpos.z), ring_r)

# boşalan taret yuvası: kararmış halka ağzı + içte kor (yangın sürdükçe)
func _turret_hole(p: Vector3, rr: float) -> void:
	var cm := CylinderMesh.new()
	cm.top_radius = rr
	cm.bottom_radius = rr
	cm.height = 0.05
	cm.radial_segments = 20
	cm.rings = 1
	var hole := MeshInstance3D.new()
	hole.mesh = cm
	hole.material_override = Mats.flat(Color(0.03, 0.025, 0.02), 1.0)
	hole.position = p + Vector3(0, 0.025, 0)
	hull.add_child(hole)
	var cm2 := CylinderMesh.new()
	cm2.top_radius = rr * 0.7
	cm2.bottom_radius = rr * 0.7
	cm2.height = 0.02
	cm2.radial_segments = 16
	cm2.rings = 1
	var em := MeshInstance3D.new()
	em.mesh = cm2
	em.material_override = Mats.flat(Color(1.0, 0.32, 0.06), 1.0, 2.2)
	em.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	em.position = p + Vector3(0, 0.055, 0)
	hull.add_child(em)
	var tw := em.create_tween()
	tw.tween_interval(randf_range(40.0, 70.0))
	tw.tween_callback(em.queue_free)

# M1 ailesi: arka taret cephane bölmesinin atılır panelleri — infilakta iki panel havaya uçar, bölmeden
# yukarı iki alev jeti fışkırır, taret yerinde kalır (mürettebat bölmesi korunur); araç yine de yanar
func _bustle_vent() -> void:
	turret_style = "vent"
	var ta: AABB = turret_mi.mesh.get_aabb()
	var tt := turret.global_transform
	var zb := ta.end.z - ta.size.z * 0.18          # model: -Z ileri → +Z taret arkası
	for sd in [-1.0, 1.0]:
		var lp := Vector3(ta.get_center().x + sd * ta.size.x * 0.22, ta.end.y, zb)
		var wp := tt * lp
		G.fx.cookoff(wp, randf_range(4.0, 8.0), 1.1)
		G.fx.flash(wp, 6.0, 12.0, 0.3)
		var pm := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(ta.size.x * 0.36, 0.05, ta.size.z * 0.2)
		pm.mesh = bm
		pm.material_override = Mats.burnt()
		G.world.add_child(pm)
		pm.global_transform = Transform3D(tt.basis.orthonormalized(), wp)
		var db := DebrisBody.make(pm, [[pm, 1.0, 1.0]], G.world)
		db.rest = 0.35
		db.fx_size = 0.4
		db.max_age = 15.0
		db.launch(Vector3(randf_range(-1.2, 1.2), randf_range(5.0, 7.5), randf_range(-1.2, 1.2)), _rand_unit() * randf_range(4.0, 8.0))
	Sfx.play3d("expl_big", tt.origin, 2.0)
	G.explode(tt.origin + Vector3(0, 1.0, 0), 3.0, 30.0, "big", team, self, team)
	G.fx.fire_column(position + Vector3(0, 1.6, 0), randf_range(40.0, 70.0), 1.0)
	for i in randi_range(3, 6):
		var tw0 := create_tween()
		tw0.tween_interval(randf_range(0.5, 6.0))
		tw0.tween_callback(func():
			var q := turret.global_transform * Vector3(randf_range(-0.6, 0.6), ta.end.y, zb)
			G.fx.explosion(q, 0.5, "rpg")
			Sfx.play3d("expl_small", q, -2.0))
	print("TURRET %s vent side=%d k=%s" % [vid if vid != "" else vtype, last_side, kill_k])

# parçalar (zırh plakası / yan etek / kapak, saklama kutusu, yürüyen aksam tekeri) katı cisim olarak
# saçılır: takla atar, seker, yuvarlanır ve sahnede kalır (çevrenin parçası). Yükseklik ölçülü (~1–2 m).
func _debris(n: int, force: float) -> void:
	var tracked := vtype in ["tank", "ifv", "apc", "aa", "arty"] and wheels.size() > 4
	var fk := clampf(force / 9.0 + 0.35, 0.5, 1.2)
	for i in n:
		var mi := MeshInstance3D.new()
		var r := randf()
		if r < 0.15:
			var cm := CylinderMesh.new()
			var wr := randf_range(0.28, 0.4) if tracked else randf_range(0.4, 0.55)
			cm.top_radius = wr
			cm.bottom_radius = wr
			cm.height = randf_range(0.14, 0.24) if tracked else randf_range(0.25, 0.35)
			cm.radial_segments = 14
			cm.rings = 1
			mi.mesh = cm
		elif r < 0.45:
			var bm := BoxMesh.new()
			bm.size = Vector3(randf_range(0.3, 0.7), randf_range(0.2, 0.45), randf_range(0.3, 0.8))
			mi.mesh = bm
		else:
			var bm2 := BoxMesh.new()
			bm2.size = Vector3(randf_range(0.4, 1.2), randf_range(0.03, 0.08), randf_range(0.3, 0.9))
			mi.mesh = bm2
		Art.burn(mi)
		G.world.add_child(mi)
		mi.global_transform = Transform3D(Basis.from_euler(Vector3(randf() * TAU, randf() * TAU, randf() * TAU)), position + Vector3(randf_range(-1.0, 1.0), 1.3, randf_range(-1.0, 1.0)))
		var db := DebrisBody.make(mi, [[mi, 1.0, 1.0]], G.world)
		db.rest = 0.3
		db.mu = 0.6
		db.fx_size = 0.25
		db.max_age = 12.0
		if i == 0:
			db.smolder = randf_range(8.0, 16.0)
		db.launch(_rand_h(1.0, 1.0) * randf_range(0.25, 0.5) * force + Vector3(0, randf_range(2.5, 5.0) * fk, 0), _rand_unit() * randf_range(3.0, 9.0))

# komutan kapakta: ateş altında / hedefe ateş ederken içeri girer, sakinken dışarı çıkıp bakar
func _cmdr_tick(dt: float) -> void:
	if cmdr == null:
		return
	_cmdr_t -= dt
	if _cmdr_t > 0.0:
		return
	_cmdr_t = 0.5
	var out := alive and crew_n >= 2 and G.time - last_hit > 12.0 and target == null and vstress < 30.0 and abandon_t < 0.0
	cmdr.visible = out and visible
	if cmdr.visible:
		cmdr.animate(0.5, "stand", 0.0)

func _meshes(n: Node) -> Array:
	var out: Array = []
	for c in n.get_children():
		if c is MeshInstance3D:
			out.append(c)
		if not (c is SoldierBody):
			out.append_array(_meshes(c))
	return out

func _wreck_tick(_dt: float) -> void:
	pass
