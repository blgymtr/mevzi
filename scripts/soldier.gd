class_name Soldier extends Unit
# Piyade: gerçek siper kullanımı, baskılanma, mühimmat, el bombası, yaralanma / sürükleme / tedavi.

const WPN := {
	"rifle": {"range": 34.0, "dmg": 24.0, "rof": 0.13, "b0": 2, "b1": 4, "p0": 0.45, "p1": 1.2, "mag": 30, "ammo": 270, "acc": 0.5, "sup": 6.0, "snd": "rifle", "tr": 3, "reload": 2.2},
	"mg": {"range": 44.0, "dmg": 20.0, "rof": 0.085, "b0": 6, "b1": 14, "p0": 0.6, "p1": 1.4, "mag": 100, "ammo": 600, "acc": 0.36, "sup": 11.0, "snd": "mg", "tr": 2, "reload": 4.5},
	"atgm": {"range": 70.0, "dmg": 16.0, "rof": 0.3, "b0": 1, "b1": 2, "p0": 0.9, "p1": 1.7, "mag": 20, "ammo": 100, "acc": 0.32, "sup": 4.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"at": {"range": 28.0, "dmg": 18.0, "rof": 0.28, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.6, "mag": 20, "ammo": 120, "acc": 0.4, "sup": 5.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"sniper": {"range": 72.0, "dmg": 110.0, "rof": 0.1, "b0": 1, "b1": 1, "p0": 3.2, "p1": 4.6, "mag": 5, "ammo": 60, "acc": 0.85, "sup": 16.0, "snd": "sniper", "tr": 1, "reload": 3.0},
	"engineer": {"range": 24.0, "dmg": 15.0, "rof": 0.08, "b0": 3, "b1": 6, "p0": 0.5, "p1": 1.1, "mag": 30, "ammo": 240, "acc": 0.42, "sup": 5.0, "snd": "rifle", "tr": 3, "reload": 2.0},
	"mortar": {"range": 24.0, "dmg": 18.0, "rof": 0.2, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.5, "mag": 15, "ammo": 60, "acc": 0.35, "sup": 4.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"drone": {"range": 24.0, "dmg": 18.0, "rof": 0.2, "b0": 1, "b1": 2, "p0": 0.8, "p1": 1.5, "mag": 15, "ammo": 60, "acc": 0.35, "sup": 4.0, "snd": "pistol", "tr": 4, "reload": 2.0},
	"leader": {"range": 36.0, "dmg": 24.0, "rof": 0.13, "b0": 2, "b1": 4, "p0": 0.5, "p1": 1.2, "mag": 30, "ammo": 240, "acc": 0.52, "sup": 6.0, "snd": "rifle", "tr": 3, "reload": 2.2},
	"crew": {"range": 22.0, "dmg": 14.0, "rof": 0.09, "b0": 3, "b1": 6, "p0": 0.6, "p1": 1.2, "mag": 30, "ammo": 120, "acc": 0.34, "sup": 4.0, "snd": "rifle", "tr": 3, "reload": 2.0},
	"medic": {"range": 28.0, "dmg": 20.0, "rof": 0.2, "b0": 1, "b1": 3, "p0": 0.7, "p1": 1.4, "mag": 30, "ammo": 150, "acc": 0.4, "sup": 5.0, "snd": "rifle", "tr": 4, "reload": 2.2},
}
const STAND := 0
const CROUCH := 1
const PRONE := 2
const RUN_SPEED := 3.7

var role := "rifle"
var body: SoldierBody
var squad: Squad
var state := "idle"
var stance := STAND
var order := ""
var force_move := false
var dest := Vector3.ZERO
var path := PackedVector3Array()
var path_i := 0
var vel := Vector3.ZERO
var face_yaw := 0.0
var target: Unit = null
var forced_target: Unit = null
var threat_pos := Vector3.ZERO
var threat_time := -99.0
var cover_type := 0
var cover_pos := Vector3.ZERO
var house_id := -1                # girilen bina (Blocks.houses)
var house_slot := -1
var cover_veh: Vehicle = null    # araç arkası siper (araç ilerlerse birlikte ilerler)
var blind_t := 0.0               # kör ateş (silahı siperin üstünden/yanından uzatır)
var blind_side := false
var cover_cd := 0.0
var to_cover := false
var suppression := 0.0
# stres (BA): baskıdan ayrı, yavaş birikir/yavaş iner. 1 = sarsılmış, 2 = panik
var stress := 0.0
var bandages := 2          # her askerde: ana silah, tabanca, bıçak, sargı
var bandage_t := 0.0
var blood_t := 0.0
var mortar_setup := 0.0     # havancı: durunca kurar (sn birikir), yürüyünce söker
# roadmap 7: kurulan havan görünür — taban plakası, iki ayak, namlu kademeyle belirir; atışta namlu geri teper
var mortar_prop: Node3D = null
var _mortar_fired := -9.0
static var _mortar_parts: Array = []
var cold := 0.0           # kar fırtınasında üşüme (0-100)
var cost_share := 0.0      # üretim maliyetinden payı (iade/imha puanı)
var stress_lv := 0
var stress_t := -99.0
var panic_fled := false
var sup_t := -99.0
var ammo := 0
var mag := 0
var reload_t := 0.0
var fire_cd := 0.0
var burst_left := 0
var grenades := 2
var smoke_nades := 1
var gren_cd := 0.0
var rockets := 0
var rocket_aim := 0.0
var downs := 0
var bleed := 0.0
var rescuer: Soldier = null
var patient: Soldier = null
var drag_dest := Vector3.ZERO
var heal_t := 0.0
var think_t := 0.0
var popped := false
var popup_t := 0.0
var lean := Vector3.ZERO
var lean_cur := Vector3.ZERO
var fly_vel := Vector3.ZERO
var fly_spin := 0.0
var fly_ang := 0.0
var fly_end := -99.0      # son savrulmanın yere iniş anı (tekrar savrulmayı engeller)
var state_t := 0.0
var throw_to := Vector3.ZERO
var throw_smoke := false
var throw_released := false
var covering_until := 0.0
var build_site: Node3D = null
var build_slot := -1
var haul := false           # malzeme taşıyor (inşaat)
var lift_t := 0.0           # kutuyu alma / bırakma hareketi (sn)
const LIFT_T := 0.9
var build_goal := Vector3.INF
var loot := 0
var dead_t := 0.0
var died_at := 0.0
var shots := 0
var res_t := 0.0
var winter := false
var held_by_vehicle := false
var sname := ""
var rank := 0
var xp := 0
const RANKS := ["ER", "ONBAŞI", "ÇAVUŞ", "ÜSTÇAVUŞ", "KD. ÇAVUŞ"]
const RANK_S := ["ER", "ONB", "ÇVŞ", "ÜÇV", "KÇV"]
const RANK_XP := [0, 15, 40, 80, 140]
const NAMES_A := ["Ahmet", "Mehmet", "Mustafa", "Ali", "Hüseyin", "Hasan", "İbrahim", "Murat", "Emre", "Burak", "Serkan", "Volkan", "Kemal", "Yusuf", "Ömer", "Caner", "Tolga", "Kaan", "Barış", "Deniz", "Onur", "Cem", "Eren", "Uğur", "Selim", "Tarık", "Levent", "Erdem", "Okan", "Halil"]
const NAMES_B := ["Yılmaz", "Kaya", "Demir", "Şahin", "Çelik", "Yıldız", "Aydın", "Öztürk", "Arslan", "Doğan", "Kılıç", "Aslan", "Çetin", "Kara", "Koç", "Kurt", "Özdemir", "Şimşek", "Polat", "Erdoğan", "Güneş", "Tekin", "Bulut", "Korkmaz", "Akın", "Ateş", "Bozkurt", "Tunç", "Uysal", "Keskin"]
const NAMES_RA := ["Viktor", "Dmitri", "Ivan", "Sergei", "Alexei", "Pavel", "Nikolai", "Oleg", "Yuri", "Boris", "Mikhail", "Andrei", "Roman", "Artem", "Kirill", "Stepan", "Fyodor", "Leonid", "Grigori", "Maxim"]
const NAMES_RB := ["Volkov", "Petrov", "Sokolov", "Morozov", "Popov", "Lebedev", "Kozlov", "Novikov", "Orlov", "Pavlov", "Zaitsev", "Belov", "Gusev", "Titov", "Krylov", "Frolov", "Sorokin", "Egorov", "Vlasov", "Antonov"]

func add_xp(v: int) -> void:
	if not alive:
		return
	xp += v
	while rank < RANK_XP.size() - 1 and xp >= RANK_XP[rank + 1]:
		rank += 1
		accuracy_bonus = 0.06 * rank
		if team == G.player_team and not G.spectate and G.hud:
			G.hud.promoted(self)

# arayüzde kişi adı yok: rütbe + sınıf
func display_name() -> String:
	return "%s %s" % [I18n.s(RANK_S[rank]), I18n.s(ROLE_TITLE.get(role, "Piyade"))]

const ROLE_TITLE := {"rifle": "Piyade", "mg": "Makineli Tüfekçi", "at": "Tanksavar", "atgm": "Füze Tanksavarcı", "medic": "Sıhhiye", "sniper": "Keskin Nişancı", "engineer": "İstihkâmcı", "mortar": "Havancı", "drone": "Drone Operatörü", "leader": "Ekip Lideri", "crew": "Mürettebat"}

func role_title() -> String:
	return {"rifle": "TÜFEKÇİ", "mg": "MAKİNELİ", "at": "TANKSAVAR", "atgm": "FÜZECİ", "medic": "SIHHİYE", "sniper": "KESKİN NİŞANCI", "engineer": "İSTİHKÂMCI", "mortar": "HAVANCI", "drone": "DRONE OPERATÖRÜ", "leader": "EKİP LİDERİ", "crew": "MÜRETTEBAT"}.get(role, "ER")

# timde yakında canlı ekip lideri var mı (isabet ve toparlanma bonusu)
func led() -> bool:
	if squad == null or role == "leader":
		return role == "leader"
	for m in squad.members:
		if is_instance_valid(m) and m.alive and m.role == "leader" and m.can_fight() and dist2(m) < 20.0:
			return true
	return false

var accuracy_bonus := 0.0
var mortar_rounds := 0
var mortar_cd := 0.0
var drone_cd := 0.0
var my_drone = null
var fpv_left := 3            # sırt çantasındaki mini drone sayısı
var drone_job := ""          # "launch": mini drone kaldırıyor, "station": istasyon kuruyor
var job_pt := Vector3.INF
var job_tgt: Unit = null
var station: DroneStation = null
var pilot_of: DroneStation = null    # 2 kişilik drone ekibi: istasyon İHA'sını kumandayla uçuran (roadmap 8)
var repair_target: Unit = null
var repair_vis_t := -1.0      # onarım görüntüsü (çekiç, eğilme, kıvılcım) bu zamana dek
var _anim_acc := 0.0
var _scan_next := 0.0         # boştaki askerin bir sonraki tam taraması (menzilde düşman yoksa seyrek)
var _sep_t := 0.0             # komşu ayrışması / araç izi denetimi aralığı (duran askerde seyrek)
var _sep_c := Vector3.ZERO
var _veh_c := Vector3.ZERO
var _vp_t := 0.0              # araç izi itmesi denetimi (10 kez/sn; araçlar yavaş yaklaşır)
var _vp_c := Vector3.ZERO
var _near_veh: Array = []        # 8 m içindeki araçlar (10 kez/sn tazelenir): adımda gövdeye girmeme
var _escaping := false           # araç izinin içinde: dışarı çıkarken izdüşüm uygulanmaz (gövdeler arasından sıyrılır)
var _slide_veh = null            # kenarı boyunca kayılan araç ve seçilen yön (+1 / -1)
var _slide_sgn := 1.0
var _slide_t := 0.0
var vehicle_in: Vehicle = null
var home_vehicle: Vehicle = null     # inmiş tank mürettebatının aracı (roadmap 11)
var board_target: Vehicle = null
var fire_mode := 0          # 0 serbest ateş, 1 sadece karşılık, 2 ateşi kes
var stance_lock := -1       # -1 otomatik, yoksa STAND/CROUCH/PRONE
var retreating := false
var amove_dest := Vector3.INF
var order_pt := Vector3.ZERO
var suppress_pt := Vector3.ZERO
var suppress_until := 0.0
var rag: Ragdoll = null
var captor := -1
var intel_n := 0
var intel_t := 0.0
var escort_of: Soldier = null
var guard_of: Soldier = null      # esiri silah doğrultarak karargâha götüren muhafız
var guard_by: Soldier = null      # (esirde) muhafızı
var flinch_t := 0.0
var melee_cd := 0.0
var melee_target: Soldier = null
var melee_hit := false
var limp_t := 0.0
var pistol_cd := 0.0
var pistol_t := 0.0
var bearer := false
var carried := false
var body_lift := 0.0
var surrender_chk := 0.0
var low_ammo_said := false
var hosp_b: Building = null
# bölgesel yara: "" | leg | arm | shoulder | head | torso — tedavi (sahra/hastane) görseli + etkisi
var injury := ""
var injury_t := -1.0          # >0: hastane sonrası iyileşme süresi; -1: hastaneye kadar kalıcı
const INJ_TXT := {"leg": "BACAĞIMDAN VURULDUM!", "arm": "KOLUM!", "shoulder": "OMZUM!", "head": "KAFAMA SIYIRDI!", "torso": "KARNIMA ALDIM!"}

func setup(t: int, rl: String) -> void:
	team = t
	role = rl
	kind = rl
	cap_cost = 1
	radius = 0.35
	# görüş: rolün optiği (çıplak göz, dürbün, nişancı dürbünü, güdümlü füze termal komuta birimi) ile açıktaki
	# ayakta piyadeyi seçebileceği mesafe (gerçek ölçek, roadmap 50)
	opt_k = Combat.optic(String(Combat.inf(rl).get("opt", "eye")))
	sight = Combat.detect_range(opt_k, 0.32)
	max_hp = 100.0
	hp = 100.0
	icon = "inf"
	title = ROLE_TITLE.get(rl, "Piyade")
	if rl == "mortar":
		mortar_rounds = 24
	var W: Dictionary = WPN[rl]
	ammo = W["ammo"]
	mag = W["mag"]
	rockets = 4 if rl == "at" else (3 if rl == "atgm" else 0)
	grenades = 2 if not (rl in ["medic", "sniper", "drone"]) else 0
	smoke_nades = 1 if rl in ["rifle", "medic"] else 0
	if team == 1:
		sname = "%s %s" % [NAMES_RA[randi() % NAMES_RA.size()], NAMES_RB[randi() % NAMES_RB.size()]]
	else:
		sname = "%s %s" % [NAMES_A[randi() % NAMES_A.size()], NAMES_B[randi() % NAMES_B.size()]]
	body = SoldierBody.new()
	add_child(body)
	body.build(t, rl, G.map_kind == "winter")
	think_t = randf() * 0.4
	face_yaw = rotation.y
	dest = position

# silah: rol tablosu + gerçek etkili menzil (ulusa göre; data/real_combat.json "inf", oyunda × K_range)
static var _wpn := {}
func weapon() -> Dictionary:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	var key := role + "_" + nat
	if not _wpn.has(key):
		var w: Dictionary = WPN[role].duplicate()
		var ci := Combat.inf(role)
		w["range"] = float(ci.get("rng_" + nat, ci.get("rng", w["range"]))) * Combat.K_RANGE
		_wpn[key] = w
	return _wpn[key]

# dolaylı atış menzili (havan timi 60/82 mm, drone ekibi kumanda menzili)
func ind_range() -> float:
	var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
	var ci := Combat.inf(role)
	return float(ci.get("ind_" + nat, ci.get("ind", 85.0))) * Combat.K_RANGE

# tespit: duruş (ayakta / çömelik / yüzüstü), hareket, ateş (namlu alevi, toz), bina içi, siper, bitki örtüsü
func spot_sig() -> float:
	if not alive or state in ["aboard", "hospital"]:
		return 0.0
	var s: float = [0.32, 0.22, 0.12][stance]
	if vel.length() > 0.6:
		s *= 1.5
	if G.time - fired_t < 3.0:
		s *= 1.6 if role == "sniper" else 2.6
	if house_id >= 0:
		s *= 0.7 if popped else 0.45
	elif G.grid.in_trench(position):
		s *= 0.55
	# bitki örtüsü: orman (ağaç gövdesi + tepe örtüsü) her duruşta gizler; çalı yalnız alçaktakini
	if G.props != null:
		var trees: int = G.props.veg_count(position, 6.0, "tree")
		if trees >= 3:
			s *= 0.4
		elif trees >= 1:
			s *= 0.8
		if G.props.veg_count(position, 3.0, "bush") >= 1:
			s *= 0.85 if stance == STAND else 0.5
	return s

func eye_point() -> Vector3:
	return position + Vector3(0, eye_h(), 0)

func los_skip() -> float:
	return 2.3 if house_id >= 0 else 0.75

func thermal() -> bool:
	return role == "atgm"

func move_vel() -> Vector3:
	return vel

func can_fight() -> bool:
	return alive and not (state in ["wounded", "dragged", "healing", "dead", "fly", "surrender", "prisoner", "dive", "aboard", "stretchered", "hospital", "stretcher", "slide", "rope", "rope_up", "rope_wait", "exiting", "entering", "para"])

func incapacitated() -> bool:
	return state in ["wounded", "dragged", "healing", "stretchered"]

func hostile() -> bool:
	if not alive or state in ["surrender", "prisoner", "hospital"]:
		return false
	return not (state == "aboard" and not visible)

func apply_visibility() -> void:
	if state == "hospital":
		visible = false
		return
	if state == "aboard" and vehicle_in != null and is_instance_valid(vehicle_in) and not vehicle_in.riders_visible():
		visible = false          # kapalı araçtaki yolcu: savaş sisi güncellemesi onu yeniden göstermesin
		return
	super.apply_visibility()

func torso_h() -> float:
	if state in ["wounded", "dragged", "healing", "dead", "stretchered"]:
		return 0.2
	return [1.2, 0.72, 0.25][stance]

func eye_h() -> float:
	return [1.55, 0.95, 0.32][stance]

func aim_point() -> Vector3:
	return position + lean_cur + Vector3(0, torso_h(), 0)

# ------------------------------------------------------------ emirler
func cmd_move(p: Vector3, force := false) -> void:
	if alive and state == "fly":
		# patlamayla savrulurken verilen emir kaybolmasın (roadmap 118): yere inince uygulanır
		_queued_move = p
		_queued_force = force
		return
	if not alive or incapacitated():
		return
	_queued_move = Vector3.INF
	if state == "para":
		# paraşütle inerken: emir toplanma noktasını değiştirir (yere değince oraya yürür);
		# durumu burada "move" yapmak askeri havadan yere ışınlardı
		para_goal = _free_ground(p, para_goal)
		return
	var in_house := G.blocks.house_at(position) if G.blocks else -1
	_leave_house()
	_release_patient()
	build_site = null
	order = "move"
	force_move = force
	forced_target = null
	retreating = false
	amove_dest = Vector3.INF
	suppress_until = 0.0
	dest = G.on_ground(p)
	cover_type = 0
	to_cover = false
	popped = false
	_exit_goal = Vector3.INF
	if in_house >= 0 and G.blocks.house_at(dest) != in_house and G.blocks.houses[in_house].get("door", Vector3.INF) != Vector3.INF:
		# evden çıkış (roadmap 118): önce girişte kullanılan yoldan kapıya, sonra hedefe — düz parça iç duvara
		# dayanıp askerler içeride kalıyordu (9 askerden 2'si)
		_exit_goal = dest
		path = G.grid.find_path(position, G.blocks.houses[in_house]["door"], Grid.M_INF)
		path_i = 0
	else:
		_set_path(dest)
	state = "move"

func cmd_attack(u: Unit) -> void:
	if not alive or incapacitated() or state == "para":
		return
	_release_patient()
	forced_target = u
	order = "attack"
	force_move = false
	cover_type = 0
	var p := u.position
	var d := position.distance_to(p)
	var rng_w: float = weapon()["range"] * 0.8
	if d > rng_w:
		dest = p + (position - p).normalized() * rng_w
		_set_path(dest)
		state = "move"
	else:
		dest = position
		state = "idle"

func cmd_stop() -> void:
	if not alive or incapacitated():
		return
	_release_patient()
	order = ""
	forced_target = null
	retreating = false
	amove_dest = Vector3.INF
	suppress_until = 0.0
	build_site = null
	drone_job = ""
	dest = position
	path = PackedVector3Array()
	if state in ["move", "build", "rescue", "setup", "launch"]:
		state = "idle"

func cmd_attack_move(p: Vector3) -> void:
	cmd_move(p)
	if order == "move":
		order = "amove"
		amove_dest = dest

func cmd_hold() -> void:
	cmd_stop()
	if alive and not incapacitated():
		order = "hold"

func cmd_retreat() -> void:
	if not alive or incapacitated() or state == "aboard":
		return
	_leave_house()
	var b := nearest_base()
	if b == null:
		return
	var away := position - b.position
	away.y = 0
	var p := b.position + (away.normalized() if away.length() > 0.1 else Vector3(1, 0, 0)) * (b.radius + 2.5)
	p += Vector3(randf_range(-3, 3), 0, randf_range(-3, 3))
	cmd_move(G.grid.nearest_free(G.on_ground(p), Grid.M_INF), true)
	order = "retreat"
	retreating = true
	target = null
	cover_type = 0

# üsse dön ve iade: karargâha varınca birim sahadan çekilir, değeri (sağlıkla orantılı) iade edilir
func cmd_refund() -> void:
	cmd_retreat()
	if order == "retreat":
		order = "refund"
		refund_b = nearest_base()

var refund_b: Building = null

func _refund_check() -> void:
	if order != "refund" or refund_b == null or not is_instance_valid(refund_b):
		return
	if dist2(refund_b) < refund_b.radius + 6.0:
		var v := G.unit_value(self) * clampf(hp / max_hp, 0.0, 1.0) * 0.8
		G.supply[team] += v
		if team == G.player_team and not G.spectate:
			G.say(I18n.s("İade +%d") % int(v), position, team)
		alive = false
		G.remove_unit(self)
		if squad:
			squad.members.erase(self)
		queue_free()

# görüş hattı: pencere başındaki asker (ve ona bakan) pencere hücresinden görür
func sees(from: Vector3, p: Vector3, tgt = null) -> bool:
	var sa := 2.3 if house_id >= 0 else 0.75
	var sb := 2.3 if tgt != null and tgt is Soldier and tgt.house_id >= 0 else 0.3
	return G.grid.los(from, p, sa, sb)

# araç eskortu: aracın düşmana göre arkasında yan yana siper alıp onunla ilerler
func cmd_follow_vehicle(v: Vehicle, slot: int, n: int) -> void:
	if state == "para":
		return
	_leave_house()
	cover_veh = v
	cover_type = 3
	cover_slot = (float(slot) - (n - 1) * 0.5) * 1.1
	order = "follow_veh"
	force_move = false
	if not v.escorts.has(self):
		v.escorts.append(self)
	_follow_veh_tick()

func _follow_veh_tick() -> void:
	if cover_veh == null or not is_instance_valid(cover_veh) or (not cover_veh.alive and not cover_veh.wreck):
		order = ""
		cover_type = 0
		return
	var back: Vector3 = -cover_veh.forward()
	if G.time - threat_time < 8.0:
		back = cover_veh.position - threat_pos
		back.y = 0.0
		back = back.normalized()
	var side := Vector3(-back.z, 0, back.x)
	var cp: Vector3 = cover_veh.position + back * (cover_veh.ext.y + 1.0) + side * cover_slot
	cp = G.grid.nearest_free(cp, Grid.M_INF, 4)
	if cp.distance_to(position) > 0.8:
		if path_i >= path.size() or path.size() == 0 or path[path.size() - 1].distance_to(cp) > 1.5:
			_set_path(cp)
		state = "move"
	cover_pos = cp

func cmd_garrison(hid: int) -> bool:
	if not can_fight() or state == "aboard":
		return false
	var other := G.blocks.house_team(hid)
	if other >= 0 and other != team:
		return false
	var k := G.blocks.house_free_slot(hid)
	if k < 0:
		return false
	var sp: Vector3 = G.blocks.houses[hid]["slots"][k]
	sp = G.grid.nearest_free(sp, Grid.M_INF, 3)
	if G.blocks.house_at(sp) != hid:
		return false
	cmd_move(sp, false)
	house_id = hid
	house_slot = k
	G.blocks.houses[hid]["occ"][k] = self
	order = "garrison"
	cover_pos = sp
	return true

func _leave_house() -> void:
	if house_id >= 0 and house_id < G.blocks.houses.size():
		var occ: Dictionary = G.blocks.houses[house_id].get("occ", {})
		if occ.get(house_slot, null) == self:
			occ.erase(house_slot)
	house_id = -1
	house_slot = -1

func cmd_throw(p: Vector3, smoke: bool) -> bool:
	if not can_fight() or state in ["throw", "drag", "heal"]:
		return false
	if (smoke and smoke_nades <= 0) or (not smoke and grenades <= 0):
		return false
	_release_patient()
	build_site = null
	order_pt = G.on_ground(p)
	var d := Vector2(order_pt.x - position.x, order_pt.z - position.z).length()
	if d <= 20.0:
		order = ""
		_start_throw(order_pt, smoke)
	else:
		order = "smoke" if smoke else "grenade"
		var dir := (position - order_pt)
		dir.y = 0
		_set_path(G.grid.nearest_free(order_pt + dir.normalized() * 17.0, Grid.M_INF))
		state = "move"
		force_move = false
	return true

func cmd_suppress(p: Vector3) -> void:
	if not can_fight():
		return
	if state == "move" and order != "retreat":
		cmd_stop()
	suppress_pt = G.on_ground(p)
	suppress_until = G.time + 12.0
	threat_pos = suppress_pt
	threat_time = G.time

func nearest_base() -> Building:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == team and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	return best

func cmd_board(v: Vehicle) -> void:
	if not alive or incapacitated() or vehicle_in != null or state == "para":
		return
	_release_patient()
	build_site = null
	board_target = v
	order = "board"
	if v.is_air() and v.hull.position.y > 2.0:
		v.request_land()
	_set_path(v.position - v.forward() * (v.ext.y * 0.9) if v.is_air() else v.position)
	state = "move"

func board(v: Vehicle) -> void:
	vehicle_in = v
	board_target = null
	order = ""
	state = "aboard"
	target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	v.cargo.append(self)
	visible = v.riders_visible()
	if selected and G.player and not v.riders_visible():
		G.player.deselect(self)

# ------------------------------------------------------------ halatla iniş (fast-rope) / çekilme (SPIES)
# Kapıda: tüfeği sırta atar (0-0.7 sn) → iki elle halatı kavrar, bacaklarını sarar (0.7-1.0) →
# kayar (hızlanır, dibe yakın frenler) → yere basınca çömelir, halatı bırakır, tüfeği sırttan alır → açılır.
var rope_heli: Vehicle = null
var rope_i := 0
var rope_h := 0.0
var rope_v := 0.0
var rope_phase := 0          # 0 kapı/silah sırta, 1 kavrama, 2 kayma, 3 yere iniş, 4 silahı al

func start_rope_down(v: Vehicle, idx: int) -> void:
	vehicle_in = null
	rope_heli = v
	rope_i = idx
	state = "rope"
	state_t = 0.0
	rope_phase = 0
	rope_v = 0.0
	visible = true
	var a := v.rope_anchor(idx)
	rope_h = a.y - 1.25
	position = Vector3(a.x, rope_h, a.z)
	rotation.y = v.heading + (PI * 0.5 if idx % 2 == 0 else -PI * 0.5)
	path = PackedVector3Array()

func start_rope_up(v: Vehicle) -> void:
	rope_heli = v
	rope_i = 0
	state = "move"
	order = "rope_up"
	to_cover = false
	_set_path(G.grid.nearest_free(v.rope_pt + Vector3(randf_range(-0.6, 0.6), 0, randf_range(-0.6, 0.6)), Grid.M_INF))
	say("HALATA!", 2.0)

func rope_fall() -> void:
	var h := position.y
	state = "fly"
	state_t = 0.0
	fly_vel = Vector3(randf_range(-1, 1), 0.0, randf_range(-1, 1))
	position.y = maxf(h, 0.1)
	hp -= h * 14.0
	if hp <= 0.0:
		die(null, true)

# patlayan aracın üstünden savrulma (87): bulunduğu yerden (güverte) havaya fırlar; ölür (ceset savrulur)
# ya da yere çakılıp sersemler / yaralanır
func throw_off(v: Vector3, p_die: float, sever_k := 0.0) -> void:
	vehicle_in = null
	_release_patient()
	path = PackedVector3Array()
	target = null
	state = "fly"
	state_t = 0.0
	fly_vel = v
	fly_spin = randf_range(6.0, 12.0) * (1.0 if randf() < 0.5 else -1.0)
	fly_ang = 0.0
	visible = true
	blast_k = sever_k
	blast_t = G.time
	blast_p = position - Vector3(v.x, 0.0, v.z).normalized() * 1.5
	if randf() < p_die:
		die(null, true)
	else:
		hp -= randf_range(35.0, 75.0)
		add_stress(75.0)

func _rope_process(dt: float) -> void:
	var v := rope_heli
	var ok := v != null and is_instance_valid(v) and v.alive and not v.ropes.is_empty()
	match state:
		"rope":
			if not ok and rope_phase < 3:
				rope_fall()
				return
			if ok:
				var a := v.rope_anchor(rope_i % v.ropes.size())
				position.x = a.x
				position.z = a.z
			if rope_phase == 0:
				body.animate(dt, "sling", 0.0, clampf(state_t / 0.7, 0.0, 1.0))
				if state_t > 0.7:
					rope_phase = 1
					state_t = 0.0
			elif rope_phase == 1:
				body.animate(dt, "rope", 0.0, 0.0)
				if state_t > 0.3:
					rope_phase = 2
					state_t = 0.0
			elif rope_phase == 2:
				var gh := G.terrain.ground_h(position) if G.terrain else 0.0
				var left := position.y - gh
				var vmax := 5.0 if left > 2.0 else maxf(1.2, left * 2.0)
				rope_v = move_toward(rope_v, vmax, dt * 9.0)
				position.y = maxf(gh, position.y - rope_v * dt)
				body.animate(dt, "rope", rope_v, 1.0)
				if position.y <= gh + 0.01:
					rope_phase = 3
					state_t = 0.0
					G.fx.dust_burst(position, 0.6)
			elif rope_phase == 3:
				body.animate(dt, "crouch", 0.0)
				if state_t > 0.35:
					rope_phase = 4
					state_t = 0.0
			else:
				body.animate(dt, "unsling", 0.0, clampf(state_t / 0.55, 0.0, 1.0))
				if state_t > 0.55:
					# halattan uzaklaş: iniş noktası çevresinde çember emniyet
					state = "idle"
					stance = CROUCH
					position.y = 0.0
					var out := Vector3(cos(randf() * TAU), 0, sin(randf() * TAU)) * randf_range(5.0, 9.0)
					cmd_move(G.grid.nearest_free(position + out, Grid.M_INF))
		"rope_wait":
			# kancalandı: iki elle halatı tutar, çekilmeyi bekler
			if not ok:
				state = "idle"
				return
			body.animate(dt, "rope", 0.0, 0.0)
			position.x = lerpf(position.x, v.rope_anchor(0).x, dt * 4.0)
			position.z = lerpf(position.z, v.rope_anchor(0).z, dt * 4.0)
		"rope_up":
			if not ok:
				rope_fall()
				return
			var a2 := v.rope_anchor(0)
			position.x = lerpf(position.x, a2.x, dt * 3.0)
			position.z = lerpf(position.z, a2.z, dt * 3.0)
			position.y = move_toward(position.y, a2.y - 1.3, dt * 2.2)
			body.animate(dt, "rope", 0.0, 0.0)
			if position.y >= a2.y - 1.35:
				position.y = 0.0
				board(v)
				v.rope_riders.erase(self)
	body.position = Vector3.ZERO

# araçtan iniş: kapı içinden eğilerek çıkar (sıradaki bekler), dışarıda çömelip mevziye açılır
var door_a := Vector3.ZERO
var door_b := Vector3.ZERO
var door_c := Vector3.ZERO
var door_wait := 0.0
var door_veh: Vehicle = null

# ------------------------------------------------------------ paraşüt (hava indirme)
# statik hat 0.9 sn serbest düşüş → kubbe açılır (0.7 sn) → 5 m/sn süzülme, hedefe doğru
# yönlendirme → yere değince yuvarlanma (PLF) → kubbe çöker → tüfeği alıp toplanma noktasına.
# Ne olursa olsun asker sınırlı sürede harita içinde boş bir zemin hücresine iner: altı dolu
# (bina, su, ağaç) ise son metrelerde boş hücreye yönelir, yine de doluysa oraya kayar;
# PARA_MAX_T aşılırsa zorunlu iniş; havada vurulursa kubbe altında yaralı süzülür, yerde yatar.
const PARA_MAX_T := 30.0
var para_vel := Vector3.ZERO
var para_goal := Vector3.ZERO
var para_phase := 0
var para_t := 0.0
var para_hurt := false
var para_spot := Vector3.INF
var canopy: Node3D = null
static var _canopy_m: Mesh = null

func start_para(p: Vector3, v0: Vector3, goal: Vector3) -> void:
	state = "para"
	state_t = 0.0
	para_phase = 0
	para_t = 0.0
	para_hurt = false
	para_spot = Vector3.INF
	position = p
	para_vel = v0
	para_goal = _free_ground(goal)
	path = PackedVector3Array()

# p'ye en yakın, piyadenin durabileceği boş zemin hücresi (harita içi; su/bina/ağaç/duvar değil);
# yakında yoksa arama genişler, hiç yoksa yedek nokta
func _free_ground(p: Vector3, fallback := Vector3.INF) -> Vector3:
	var c := G.on_ground(p)
	if G.grid.free_at(c, Grid.M_INF):
		return c
	var q := G.grid.nearest_free(c, Grid.M_INF, 96)
	if G.grid.free_at(q, Grid.M_INF):
		return q
	return fallback if fallback != Vector3.INF else c

func _para_clamp() -> void:
	position.x = clampf(position.x, 2.0, G.MAP - 2.0)
	position.z = clampf(position.z, 2.0, G.MAP - 2.0)

func _canopy_mesh() -> Mesh:
	if _canopy_m != null:
		return _canopy_m
	# yuvarlak kubbe (T-11 / D-10): dilimli kubbe + etek + askı ipleri
	var mb := MB.new()
	var R := 3.4
	var segs := 16
	var olive := Color(0.36, 0.4, 0.27)
	for i in segs:
		var a0 := TAU * i / segs
		var a1 := TAU * (i + 1) / segs
		var col := olive if i % 2 == 0 else olive.darkened(0.12)
		for r in 4:
			var t0 := float(r) / 4.0
			var t1 := float(r + 1) / 4.0
			var p00 := Vector3(cos(a0) * R * sin(t0 * PI * 0.5), cos(t0 * PI * 0.5) * R * 0.55, sin(a0) * R * sin(t0 * PI * 0.5))
			var p01 := Vector3(cos(a1) * R * sin(t0 * PI * 0.5), cos(t0 * PI * 0.5) * R * 0.55, sin(a1) * R * sin(t0 * PI * 0.5))
			var p10 := Vector3(cos(a0) * R * sin(t1 * PI * 0.5), cos(t1 * PI * 0.5) * R * 0.55, sin(a0) * R * sin(t1 * PI * 0.5))
			var p11 := Vector3(cos(a1) * R * sin(t1 * PI * 0.5), cos(t1 * PI * 0.5) * R * 0.55, sin(a1) * R * sin(t1 * PI * 0.5))
			mb.quad(p00, p01, p11, p10, col.lightened(0.05 * (3 - r)))
		# askı ipi: etekten omuza
		mb.cyl_between(Vector3(cos(a0) * R, 0.0, sin(a0) * R), Vector3(cos(a0) * 0.25, -5.2, sin(a0) * 0.2), 0.012, 0.012, 3, Color(0.75, 0.74, 0.68), false)
	_canopy_m = mb.commit(Mats.vc2())
	return _canopy_m

func _para_process(dt: float) -> void:
	para_t += dt
	var gh := G.terrain.ground_h(position) if G.terrain else 0.0
	match para_phase:
		0:
			# serbest düşüş (statik hat çekiyor); sönümler kare süresinden bağımsız (üstel)
			para_vel.y -= 9.8 * dt
			var dmp := exp(-dt * 0.8)
			para_vel.x *= dmp
			para_vel.z *= dmp
			position += para_vel * dt
			_para_clamp()
			body.animate(dt, "fly", 0.0, 0.4)
			if position.y <= gh + 0.02 or para_t > PARA_MAX_T:
				_para_touchdown()
			elif state_t > 0.9:
				para_phase = 1
				state_t = 0.0
				canopy = MeshInstance3D.new()
				(canopy as MeshInstance3D).mesh = _canopy_mesh()
				add_child(canopy)
				canopy.position = Vector3(0, 6.6, 0)
				canopy.scale = Vector3(0.1, 0.6, 0.1)
		1, 2:
			var cv := canopy != null and is_instance_valid(canopy)
			if para_phase == 1:
				var k := clampf(state_t / 0.7, 0.0, 1.0)
				if cv:
					canopy.scale = Vector3(lerpf(0.1, 1.0, k * k), lerpf(0.6, 1.0, k), lerpf(0.1, 1.0, k * k))
				if k >= 1.0:
					para_phase = 2
			# son 12 m: altı dolu (bina, su, ağaç) ise en yakın boş hücreye yönel
			if para_spot == Vector3.INF and position.y - gh < 12.0 and not G.grid.free_at(G.on_ground(position), Grid.M_INF):
				para_spot = _free_ground(position, para_goal)
			# süzülme: dikey 5 m/sn, hedefe yatay yönlenme + rüzgâr salınımı. Yumuşatma ağırlıkları
			# üstel: düşük kare hızında (büyük dt) lerp ağırlığı 1'i aşıp hızı salındırmasın
			var aim := para_goal if para_spot == Vector3.INF else para_spot
			var to := aim - position
			to.y = 0.0
			var vmax := 3.2 if para_spot == Vector3.INF else 4.5
			var hv := to.normalized() * minf(to.length() * (0.35 if para_spot == Vector3.INF else 1.2), vmax) if to.length() > 0.3 else Vector3.ZERO
			var kh := 1.0 - exp(-dt * 1.5)
			var sway := sin(G.time * 0.7 + position.x) * 0.5 if para_spot == Vector3.INF else 0.0
			para_vel.x = lerpf(para_vel.x, hv.x + sway, kh)
			para_vel.z = lerpf(para_vel.z, hv.z, kh)
			para_vel.y = lerpf(para_vel.y, -5.0, 1.0 - exp(-dt * 3.0))
			position += para_vel * dt
			_para_clamp()
			if hv.length() > 0.2:
				rotation.y = lerp_angle(rotation.y, _yaw_of(hv), clampf(dt * 1.5, 0.0, 1.0))
			if cv:
				canopy.rotation.z = sin(G.time * 1.3 + position.z) * 0.08
				canopy.rotation.x = cos(G.time * 1.1) * 0.06
			body.animate(dt, "para", 0.0, 0.0)
			if position.y <= gh + 0.02 or para_t > PARA_MAX_T:
				_para_touchdown()
		3:
			# iniş yuvarlanması: yan yatıp kalkar
			body.animate(dt, "prone" if state_t < 0.7 else "crouch", 0.0)
			if state_t > 1.1:
				para_phase = 4
				state_t = 0.0
		4:
			body.animate(dt, "unsling", 0.0, clampf(state_t / 0.55, 0.0, 1.0))
			if state_t > 0.55:
				state = "idle"
				position.y = 0.0
				stance = CROUCH
				cmd_move(para_goal)
	body.position = Vector3.ZERO

# yere değiş: iniş noktası her durumda harita içinde boş bir zemin hücresi (dolu hücreye
# düşen en yakın boş hücreye kayar); kubbe çöker. Havada vurulmuşsa yuvarlanmaz, yaralı yatar.
func _para_touchdown() -> void:
	var lp := _free_ground(position, para_goal)
	position = Vector3(lp.x, G.terrain.ground_h(lp) if G.terrain else 0.0, lp.z)
	para_vel = Vector3.ZERO
	para_phase = 3
	state_t = 0.0
	G.fx.dust_burst(position, 0.8)
	_drop_canopy()
	if para_hurt:
		para_hurt = false
		state = "wounded"
		stance = PRONE
		target = null
		vel = Vector3.ZERO
		G.fx.blood_pool(position)
		say(["SIHHİYE!", "SIHHİYE! VURULDUM!", "YARDIM EDİN!"][randi() % 3], 3.0)

func _drop_canopy() -> void:
	if canopy == null:
		return
	var c := canopy
	var gp := c.global_position
	remove_child(c)
	G.main.world.add_child(c)
	c.global_position = gp
	var side := Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	var tw := c.create_tween()
	tw.tween_property(c, "global_position", Vector3(gp.x, 0.4, gp.z) + side * 3.0, 1.4).set_ease(Tween.EASE_IN)
	tw.parallel().tween_property(c, "scale", Vector3(1.1, 0.12, 0.8), 1.4)
	tw.parallel().tween_property(c, "rotation:z", 1.2, 1.4)
	tw.tween_interval(40.0)
	tw.tween_callback(c.queue_free)
	canopy = null

func dismount(p: Vector3, from_v: Vehicle = null, delay := 0.0) -> void:
	if vehicle_in:
		vehicle_in.cargo.erase(self)
	var v := from_v if from_v != null else vehicle_in
	vehicle_in = null
	var dst := G.grid.nearest_free(G.on_ground(p), Grid.M_INF)
	if v != null and is_instance_valid(v) and v.alive and not (v.is_air() and v.hull.position.y > 1.2) and not v.riders_visible():
		door_veh = v
		door_a = v.inside_point()
		door_b = v.entry_point(randi() % 2)
		door_c = dst
		door_wait = delay
		state = "exiting"
		state_t = 0.0
		position = door_a
		visible = false
		stance = CROUCH
		dest = dst
		return
	position = dst
	state = "idle"
	stance = CROUCH
	dest = position
	visible = true

func _door_process(dt: float) -> void:
	# exiting: bekle → kapıdan çık (0.55 sn eğik) → hedefe yürü; entering: tersi
	if state == "exiting":
		if door_wait > 0.0:
			door_wait -= dt
			state_t = 0.0
			body.animate(dt, "crouch", 0.0)
			return
		visible = true
		if state_t < 0.55:
			var k := state_t / 0.55
			var np := door_a.lerp(door_b, k)
			_face_to(door_b + (door_b - door_a))
			rotation.y = face_yaw
			position = Vector3(np.x, 0.0, np.z)
			body.animate(dt, "crouch", 2.0)
		else:
			state = "idle"
			cmd_move(door_c)
			stance = CROUCH
		return
	# entering
	var v := door_veh
	if v == null or not is_instance_valid(v) or not v.alive:
		state = "idle"
		visible = true
		return
	var k2 := clampf(state_t / 0.6, 0.0, 1.0)
	var a := v.entry_point(0)
	var np2 := a.lerp(v.inside_point(), k2)
	position = Vector3(np2.x, 0.0, np2.z)
	_face_to(v.inside_point() + (v.inside_point() - a))
	rotation.y = face_yaw
	body.animate(dt, "crouch", 2.0)
	if k2 >= 1.0:
		if v.needs_crew():
			v.add_crew(self)
		elif v.can_load():
			board(v)
		else:
			state = "idle"
			say("ARAÇ DOLU!")

func _build_over() -> bool:
	return build_site == null or not is_instance_valid(build_site) or build_site.done or not build_site.alive

func _end_build() -> void:
	build_site = null
	haul = false
	lift_t = 0.0
	build_goal = Vector3.INF
	state = "idle"
	order = ""

func cmd_build(site: Node3D) -> void:
	if not alive or incapacitated() or state == "para":
		return
	_release_patient()
	build_site = site
	order = "build"
	haul = false
	build_slot = -1
	var p: Vector3 = site.position + (position - site.position).normalized() * (site.radius + 0.8)
	if site is Building and not site.is_line():
		build_slot = site.claim_slot(self)
		p = site.slot_pos(build_slot)
	build_goal = p
	dest = p
	_set_path(p)
	state = "move"

func _set_path(p: Vector3) -> void:
	path_req += 1
	path_i = 0
	# büyük haritada uzun yol iş parçacığında aranır; o sırada hedefe doğru düz parça yürünür
	if G.grid.wants_async(position, p):
		path = G.grid.cached_path(position, p, Grid.M_INF)
		if path.size() > 0:
			return
		if G.grid.direct(position, p, Grid.M_INF):
			path = PackedVector3Array([G.grid.nearest_free(p, Grid.M_INF)])
			return
		path = G.grid.provisional(position, p, Grid.M_INF)
		G.grid.request_path(position, p, Grid.M_INF, _on_path.bind(path_req))
		return
	path = G.grid.find_path(position, p, Grid.M_INF)

var path_req := 0

func _on_path(res: PackedVector3Array, req: int) -> void:
	if req != path_req or not alive:
		return
	path = G.grid.splice(res, position, Grid.M_INF)
	path_i = 0

# ------------------------------------------------------------ ana döngü
func _process(dt: float) -> void:
	if not G.running:
		if body:
			body.animate(dt, _pose(), 0.0)
		return
	if dt <= 0.0:
		return
	tick_bubble(dt)
	state_t += dt
	if not alive:
		dead_t += dt
		if carried:
			body.animate(dt, "dead", 0.0)
			return
		if rag != null:
			if not rag.step(dt) and dead_t > 1.0:
				_settle_body()
				set_process(false)
			return
		if state == "fly":
			_fly(dt)
		body.animate(dt, "dead" if state != "fly" else "fly", 0.0, fly_ang)
		if dead_t > 3.0 and state != "fly":
			set_process(false)
		return
	_guard(dt)
	if state == "aboard":
		_aboard(dt)
		return
	if state in ["rope", "rope_up", "rope_wait"]:
		_rope_process(dt)
		return
	if state in ["exiting", "entering"]:
		_door_process(dt)
		return
	if state == "para":
		_para_process(dt)
		return
	if state == "hospital":
		return
	if state == "stretchered":
		bleed = maxf(bleed, 20.0)
		body.animate(dt, "healing", 0.0)
		return
	var t0 := Time.get_ticks_usec() if Vehicle.prof_on else 0
	_timers(dt)
	if Vehicle.prof_on:
		t0 = Vehicle._pf("s_timers", t0)
	think_t -= dt
	if think_t <= 0.0:
		think_t = 0.28 + randf() * 0.12
		_think()
		if Vehicle.prof_on:
			t0 = Vehicle._pf("s_think", t0)
	_movement(dt)
	if Vehicle.prof_on:
		t0 = Vehicle._pf("s_move", t0)
	_combat(dt)
	if Vehicle.prof_on:
		t0 = Vehicle._pf("s_combat", t0)
	if state == "dragged" or (state == "wounded" and downs <= 1):
		_pistol()
	elif state in ["idle", "move"] and can_fight() and G.time - threat_time < 4.0 and threat_pos.distance_to(position) < 14.0 and ((ammo <= 0 and mag <= 0) or reload_t > 0.8):
		# tüfek boş / şarjör değişiyor ve düşman yakın: tabancaya geç
		_pistol()
	var sp := vel.length()
	body.move_yaw = angle_difference(rotation.y, _yaw_of(vel)) if sp > 0.3 else 0.0
	body.pistol = G.time - pistol_t < 2.5 or (one_armed() and G.time - threat_time < 10.0)
	body.limp = injury == "leg"
	body.set_tool(_tool_kind())
	# animasyon ayrıntı düzeyi: sisin içindeki ya da ekran dışındaki asker ~3 kez/sn, stratejik yakınlaştırmada
	# (simgeler) ~10 kez/sn güncellenir — yüzlerce askerde iskelet animasyonu kare süresinin büyük payıydı
	_anim_acc += dt
	var alim := 0.0
	if not visible or G.cam == null or not G.cam.view_ground_rect().has_point(Vector2(position.x, position.z)):
		alim = 0.33
	elif G.cam.size > 220.0:
		alim = 0.1
	if _anim_acc >= alim:
		body.reload_k = (1.0 - reload_t / maxf(float(weapon()["reload"]) * (1.0 + stress_lv * 0.4), 0.1)) if reload_t > 0.0 else -1.0
		body.animate(_anim_acc, _pose(), sp, fly_ang if state == "fly" else (state_t / 0.7 if state == "throw" else (state_t / 0.5 if state == "melee" else (lift_t / LIFT_T if (state == "build" and lift_t > 0.0) else (1.0 if haul else 0.0)))))
		_anim_acc = 0.0
	if Vehicle.prof_on:
		Vehicle._pf("s_anim", t0)
	lean_cur = lean_cur.lerp(lean if (popped and cover_type == 2) else Vector3.ZERO, clampf(dt * 6.0, 0, 1))
	body.position = Vector3(lean_cur.x, body_lift, lean_cur.z).rotated(Vector3.UP, -rotation.y)

# ------------------------------------------------------------ takılma bekçisi
# Geçici durumların azami süresi (sn). Aşılırsa durum güvenle çözülür (eylem tamamlanır / iptal edilir /
# asker en yakın boş zemin hücresine konur) ve bir kez "STUCK-RESOLVE Soldier <durum> <sn>" yazılır.
# Meşru uzun eylemler tabloda yok (araçta yolculuk, hastane, inşaat, teslim/esir, yaralı bekleyişi) ya da
# ilerlemeye bağlı ("move": yer değiştirmeden geçen süre). Sayaç durum değişince sıfırlanır (state_t her
# geçişte sıfırlanmadığı için ayrı sayaç tutulur).
const STATE_MAX := {"entering": 8.0, "exiting": 20.0, "rope": 30.0, "rope_wait": 75.0, "rope_up": 45.0,
	"para": 45.0, "fly": 8.0, "dive": 4.0, "slide": 4.0, "throw": 5.0, "melee": 6.0, "dazed": 8.0,
	"launch": 12.0, "setup": 120.0, "rescue": 90.0, "drag": 30.0, "heal": 30.0, "escort": 30.0, "guard": 260.0,
	"stretcher": 240.0, "dragged": 60.0, "healing": 60.0}
const MOVE_REPATH := 8.0      # yer değiştirmeyen yürüyüş bu kadar sn sonra yeniden yol arar
const MOVE_GIVEUP := 30.0     # ... bu kadar sn sonra bırakılır
var _gd_state := ""
var _gd_t := 0.0
var _gd_pos := Vector3.ZERO
var _gd_still := 0.0
var _gd_repath := 0.0

func _guard(dt: float) -> void:
	if state != _gd_state:
		_gd_state = state
		_gd_t = 0.0
		_gd_pos = position
		_gd_still = 0.0
		_gd_repath = 0.0
		return
	_gd_t += dt
	var lim: float = STATE_MAX.get(state, 0.0)
	if lim > 0.0 and _gd_t > lim:
		_unstick(state, _gd_t)
		return
	if state != "move" or order == "follow_veh":
		return
	if Vector2(position.x - _gd_pos.x, position.z - _gd_pos.z).length() > 0.6:
		_gd_pos = position
		_gd_still = 0.0
		_gd_repath = 0.0
		return
	_gd_still += dt
	_gd_repath += dt
	if _gd_still > MOVE_GIVEUP:
		_unstick("move", _gd_still)
	elif _gd_repath > MOVE_REPATH and path.size() > 0:
		_gd_repath = 0.0
		# engel içinde kaldıysa önce boş hücreye çık, sonra yolu yeniden ara
		if not G.grid.free_at(position, Grid.M_INF):
			position = G.grid.nearest_free(position, Grid.M_INF)
		_set_path(path[path.size() - 1])

func _unstick(st: String, secs: float) -> void:
	print("STUCK-RESOLVE Soldier %s %.0f team=%d role=%s order=%s p=(%.0f,%.0f)" % [st, secs, team, role, order, position.x, position.z])
	match st:
		"entering":
			var v := door_veh
			if v != null and is_instance_valid(v) and v.alive and v.needs_crew():
				v.add_crew(self)
			elif v != null and is_instance_valid(v) and v.can_load():
				board(v)
			else:
				state = "idle"
		"exiting":
			door_wait = 0.0
			state = "idle"
		"rope", "rope_wait", "rope_up":
			var h := rope_heli
			if h != null and is_instance_valid(h):
				h.rope_riders.erase(self)
			if st == "rope_up" and h != null and is_instance_valid(h) and h.alive and h.can_load():
				position.y = 0.0
				board(h)
			else:
				state = "idle"
				stance = CROUCH
		"para":
			_para_touchdown()
		"fly":
			fly_vel = Vector3.ZERO
			fly_ang = 0.0
			fly_end = G.time
			if hp <= 0.0:
				_down(null, true)
			else:
				state = "idle"
		"stretcher":
			if job != null:
				job._drop()
			job = null
			state = "idle"
			force_move = false
		"dragged", "healing":
			rescuer = null
			state = "wounded"
		"drag", "heal", "rescue":
			_release_patient()
			state = "idle"
		"move":
			path = PackedVector3Array()
			state = "idle"
			board_target = null
			force_move = false
			dest = position
			if order == "garrison":
				_leave_house()          # pencere yuvasını bırak (yoksa bina dışarıdan tutulmuş sayılır)
			if order != "hold":
				order = ""
			if team == G.player_team and not G.spectate:
				say("YOL YOK!", 2.0)
		_:
			state = "idle"
	if alive and state != "aboard":
		visible = true
		if state != "wounded" and not G.grid.free_at(position, Grid.M_INF):
			position = G.grid.nearest_free(position, Grid.M_INF)
		if not G.grid.in_trench(position):
			position.y = 0.0
	_gd_state = ""

func _aboard(dt: float) -> void:
	var v := vehicle_in
	if v == null or not is_instance_valid(v) or not v.alive:
		dismount(position)
		return
	var seat: Vector3 = v.seat_pos(self)
	position = seat
	rotation.y = v.heading + PI * (0.5 if v.cargo.find(self) % 2 == 0 else -0.5)
	body.animate(dt, "crouch", 0.0)
	body.position = Vector3.ZERO

func _timers(dt: float) -> void:
	flinch_t -= dt
	melee_cd -= dt
	pistol_cd -= dt
	limp_t -= dt
	fire_cd -= dt
	gren_cd -= dt
	mortar_cd -= dt
	drone_cd -= dt
	if injury_t > 0.0:
		injury_t -= dt
		if injury_t <= 0.0:
			injury_t = -1.0
			if injury != "head":
				body.set_injury("")
			injury = ""
	if state == "setup":
		if station != null and is_instance_valid(station) and station.alive and not station.done and dist2_p(station.position) < 3.4:
			station.add_work(dt)
			if randf() < dt * 1.5:
				Sfx.play3d("hammer", position, -14.0, 0.15, 0.2)
		else:
			state = "idle"
			if station != null and is_instance_valid(station) and station.done:
				drone_job = ""
				order = ""
	elif state == "launch":
		_launch_tick()
	cover_cd -= dt
	popup_t -= dt
	blind_t -= dt
	# kendi kendine sargı: hafif yaralı, son 6 sn ateş altında değil
	if bandage_t > 0.0:
		bandage_t -= dt
		if bandage_t <= 0.0:
			hp = minf(max_hp, hp + 25.0)
			bandages -= 1
	elif bandages > 0 and hp < max_hp * 0.65 and can_fight() and state == "idle" and G.time - last_hit > 6.0 and G.time - sup_t > 4.0 and randf() < dt * 0.4:
		bandage_t = 3.5
		say("SARGI YAPIYORUM", 2.5)
	if role == "mortar" and state == "move" and vel.length() > 0.5:
		mortar_setup = 0.0
	if role == "mortar":
		_mortar_visual()
	# sürüklenen / yerde kanayan yaralı arkasında kan izi bırakır
	if state in ["dragged", "wounded", "stretchered"]:
		blood_t -= dt
		if blood_t <= 0.0:
			blood_t = 0.35 if state == "dragged" else 2.5
			G.fx.blood_pool(position + Vector3(randf_range(-0.2, 0.2), 0, randf_range(-0.2, 0.2)))
	if G.time - sup_t > 1.2:
		suppression = maxf(0.0, suppression - dt * (22.0 if led() else 16.0))
	if stress > 0.0 and G.time - stress_t > 3.0:
		stress = maxf(0.0, stress - dt * (5.0 if led() else 3.2) * (0.5 if suppression > 40.0 else 1.0))
		_stress_level()
	if reload_t > 0.0:
		reload_t -= dt
		if reload_t <= 0.0:
			var W := weapon()
			mag = mini(W["mag"], ammo)
	if state == "wounded" or state == "dragged" or state == "healing":
		if state != "healing":
			bleed -= dt
			if bleed <= 0.0:
				die(null)
				return
	res_t -= dt
	if res_t <= 0.0:
		res_t = 1.0
		_resupply()

func _resupply() -> void:
	var W := weapon()
	if ammo >= W["ammo"] and (not (role in ["at", "atgm"]) or rockets >= 3) and grenades >= 2 and (role != "mortar" or mortar_rounds >= 24):
		return
	for u in G.near(position, 16.0):
		if u is Building and u.team == team and u.done and (u.is_base() or u.btype == "cache"):
			# kg: 50 mermi 2 kg, roket 6 kg, 4 havan mermisi 8 kg, el bombası 1 kg
			if ammo < W["ammo"] and u.draw_stock(2.0):
				ammo = mini(W["ammo"], ammo + 50)
			if role in ["at", "atgm"] and rockets < (4 if role == "at" else 3) and u.draw_stock(6.0 if role == "at" else 12.0):
				rockets = mini(4 if role == "at" else 3, rockets + 1)
			if role == "mortar" and mortar_rounds < 24 and u.draw_stock(8.0):
				mortar_rounds = mini(24, mortar_rounds + 4)
			if role != "medic" and grenades < 2 and u.draw_stock(1.0):
				grenades = mini(2, grenades + 1)
			if u.stock < 1.0 and u.btype == "fob" and randf() < 0.05:
				say("İKMAL YOK!")
			return
		if u is Soldier and not u.alive and u.loot > 0 and u.dist2(self) < 1.8:
			var take := mini(u.loot, W["ammo"] - ammo)
			ammo += take
			u.loot -= take
			return

# ------------------------------------------------------------ karar
var _queued_move := Vector3.INF   # savrulurken gelen hareket emri
var _queued_force := false
var _prog_p := Vector3.INF          # yürüyüş ilerleme denetimi (duvara dayanıp kalma)
var _prog_t := 0.0

func _think() -> void:
	if order == "follow_veh" and alive and can_fight():
		_follow_veh_tick()
	if _queued_move != Vector3.INF and alive and state != "fly" and not incapacitated():
		var q := _queued_move
		_queued_move = Vector3.INF
		cmd_move(q, _queued_force)
	if state == "idle" and order == "move" and path_i < path.size() and alive and can_fight():
		# yere atılma / irkilme / sersemleme gibi kısa tepki hareket emrini yarıda bırakıyordu (roadmap 118):
		# tepki bitince yürüyüşe devam
		state = "move"
	if state == "move" and path_i < path.size() and order != "board":
		if _prog_p == Vector3.INF or position.distance_to(_prog_p) > 0.4:
			_prog_p = position
			_prog_t = G.time
		elif G.time - _prog_t > 2.0:
			# 2 sn'dir ilerlemiyor (iç duvara / köşeye dayandı): evdeyse evin ortası → kapı, değilse yeniden yol
			_prog_t = G.time
			var hid := G.blocks.house_at(position) if G.blocks else -1
			var goal: Vector3 = path[path.size() - 1] if _exit_goal == Vector3.INF else _exit_goal
			if hid >= 0 and G.blocks.house_at(goal) != hid and G.blocks.houses[hid].get("door", Vector3.INF) != Vector3.INF:
				var h: Dictionary = G.blocks.houses[hid]
				_exit_goal = goal
				path = G.grid.find_path(position, h["center"], Grid.M_INF)
				path.append_array(G.grid.find_path(h["center"], h["door"], Grid.M_INF))
				path_i = 0
			else:
				_set_path(goal)
	else:
		_prog_p = Vector3.INF
	match state:
		"fly", "dive", "dragged", "healing", "aboard", "slide", "stretcher", "stretchered", "hospital", "melee":
			return
		"launch":
			return
		"setup":
			if G.time - last_hit < 1.0 or suppression > 70.0:
				state = "idle"     # ateş altında kurulumu bırakır (sonra döner)
			return
		"surrender":
			_think_surrender_wait()
			return
		"prisoner":
			_think_prisoner()
			return
		"wounded":
			_think_wounded()
			return
		"escort":
			_think_escort()
			return
		"guard":
			_think_guard()
			return
		"throw":
			return
		"dazed":
			if state_t > 2.4:
				state = "idle"
			return
	if stress_lv == 2 and not panic_fled and can_fight() and order != "retreat" and state in ["idle", "move"]:
		_panic_flee()
		return
	var tsc := Time.get_ticks_usec() if Vehicle.prof_on else 0
	_scan()
	if Vehicle.prof_on:
		Vehicle._pf("s_scan", tsc)
	if can_fight() and _think_melee():
		return
	if can_fight() and _think_surrender():
		return
	match state:
		"rescue":
			_think_rescue()
		"drag", "heal":
			pass
		"build":
			if _build_over():
				_end_build()
		"move":
			if order == "build" and _build_over():
				# inşaat yürürken bitti / yıkıldı: kutu taşıyan ya da yerine yürüyen işçi yarıda bırakır
				# (yoksa yolunu tamamlayıp kaldırılmış malzeme yığınına kutu götürüyordu)
				_end_build()
				path = PackedVector3Array()
				return
			if order == "rope_up" and rope_heli != null and is_instance_valid(rope_heli) and rope_heli.rope_pt != Vector3.INF and dist2_p(rope_heli.rope_pt) < 2.5:
				# halatın dibine vardı: tam yol sonunu bekleme — kalabalıkta ayrışma itişi askerleri
				# 0.25 m varış eşiğinin dışında dengede tutar, "move"da sonsuza dek kalırlardı
				path = PackedVector3Array()
				_arrive()
				return
			if order == "build" and build_goal != Vector3.INF and randf() < 0.06:
				# yol bina ızgaraya işlenmeden hesaplanmış olabilir: ara sıra yeniden bul
				_set_path(build_goal)
			if order == "board" and board_target != null:
				if not is_instance_valid(board_target) or not board_target.alive:
					board_target = null
					order = ""
				elif not board_target.is_air() and not board_target.riders_visible() and dist2_p(board_target.entry_point(0)) < 1.3 and (board_target.needs_crew() or board_target.can_load()):
					# kapıya vardı: eğilerek içeri gir
					door_veh = board_target
					board_target = null
					order = ""
					state = "entering"
					state_t = 0.0
					path = PackedVector3Array()
					return
				elif not board_target.is_air() and not board_target.riders_visible() and dist2(board_target) < board_target.radius + 4.0:
					if path_i >= path.size() or randf() < 0.3:
						_set_path(board_target.entry_point(0))
					return
				elif dist2(board_target) < board_target.radius + 2.0:
					if board_target.needs_crew():
						board_target.add_crew(self)
						return
					if board_target.can_load():
						board(board_target)
						return
					elif board_target.is_air() and board_target.cargo.size() < board_target.capacity():
						# helikopter iniyor: rampada bekle
						if not board_target.landing:
							board_target.request_land()
						return
					else:
						say("ARAÇ DOLU!")
						board_target = null
						order = ""
				elif path_i >= path.size() or randf() < 0.2:
					_set_path(board_target.position)
				return
			if order == "amove" and target != null and not to_cover and fire_mode != 2:
				# saldırı hareketi: düşman görünce dur ve çatış
				state = "idle"
				dest = position
				path = PackedVector3Array()
			elif (order == "grenade" or order == "smoke") and Vector2(order_pt.x - position.x, order_pt.z - position.z).length() <= 19.0:
				path = PackedVector3Array()
				var sm := order == "smoke"
				order = ""
				if (sm and smoke_nades > 0) or (not sm and grenades > 0):
					_start_throw(order_pt, sm)
				else:
					state = "idle"
				return
			elif path_i >= path.size():
				_arrive()
			elif not force_move and suppression > 80 and randf() < 0.3:
				# ağır ateş altında yerde kal
				stance = PRONE
		"idle":
			_think_idle()
			_think_role()
	_stance()

var _exit_goal := Vector3.INF     # evden çıkarken kapıdan sonra gidilecek asıl hedef

func _arrive() -> void:
	if _exit_goal != Vector3.INF and order == "move":
		# kapıya vardı: asıl hedefe yol
		var g := _exit_goal
		_exit_goal = Vector3.INF
		_set_path(g)
		state = "move"
		return
	_exit_goal = Vector3.INF
	state = "idle"
	path = PackedVector3Array()
	if to_cover:
		to_cover = false
		if vel.length() > 2.8 and randf() < 0.75:
			# koşarken siperin arkasına kayarak gir
			state = "slide"
			state_t = 0.0
			fly_vel = vel * 0.95
			return
	elif order == "build" and build_site != null and is_instance_valid(build_site):
		state = "build"
		return
	if order == "refund":
		_refund_check()
		return
	if order == "rope_up":
		order = ""
		if rope_heli != null and is_instance_valid(rope_heli) and rope_heli.alive and dist2_p(rope_heli.rope_pt) < 3.0:
			state = "rope_wait"
			state_t = 0.0
			_face_to(rope_heli.position)
		return
	if order == "hospital":
		order = ""
		if hosp_b != null and is_instance_valid(hosp_b) and hosp_b.alive and dist2_p(hosp_b.door_pos()) < 4.0:
			hosp_b.admit(self)
		return
	if order == "follow_veh":
		return
	if order == "garrison":
		order = "hold" if house_id >= 0 else ""
		if house_id >= 0:
			cover_type = 1
			cover_pos = position
			var outv: Vector3 = G.blocks.houses[house_id]["out"][house_slot]
			face_yaw = _yaw_of(outv)
		return
	if order == "move" or order == "retreat" or order == "grenade" or order == "smoke" or order == "panic":
		if order == "retreat":
			suppression = 0.0
		order = ""
		force_move = false
		retreating = false
	elif order == "amove" and (amove_dest == Vector3.INF or position.distance_to(amove_dest) < 3.0):
		order = ""
		amove_dest = Vector3.INF
	elif order == "resupply" or order == "loot":
		order = ""

var cover_slot := 0.0

func _vehicle_cover_seek() -> bool:
	var best: Vehicle = null
	var bd := 11.0
	for u in G.near(position, 11.0):
		if u is Vehicle and (u.alive and u.team == team or u.wreck) and not u.is_air() and u.radius > 1.4:
			var d := position.distance_to(u.position)
			# aracın tehdide göre arkasında başka kimse çok yoksa
			if d < bd:
				bd = d
				best = u
	if best == null:
		return false
	var grid_c := G.grid.cover_factor(position, 1.0, threat_pos)
	if grid_c > 0.6:
		return false
	cover_veh = best
	cover_type = 3
	cover_slot = randf_range(-1.0, 1.0) * best.radius * 0.5
	var away := best.position - threat_pos
	away.y = 0.0
	cover_pos = G.grid.nearest_free(best.position + away.normalized() * (best.radius + 0.9) + Vector3(-away.z, 0, away.x).normalized() * cover_slot, Grid.M_INF, 4)
	to_cover = true
	_set_path(cover_pos)
	state = "move"
	if randf() < 0.2:
		say("ARACIN ARKASINA!")
	return true

func _think_idle() -> void:
	var recent := G.time - threat_time < 9.0
	if order == "amove" and amove_dest != Vector3.INF and target == null and G.time - threat_time > 3.5 and G.time - last_hit > 3.0:
		dest = amove_dest
		cover_type = 0
		_set_path(dest)
		state = "move"
		return
	if recent and order != "hold" and cover_cd <= 0.0 and not force_move:
		cover_cd = 2.5 + randf()
		var prot := 0.0
		if cover_type > 0:
			prot = G.grid.cover_factor(position, 1.0, threat_pos)
		if cover_type == 3:
			prot = 1.0 if cover_veh != null and is_instance_valid(cover_veh) and (cover_veh.alive or cover_veh.wreck) else 0.0
		if house_id >= 0 and order == "hold":
			return
		if (cover_type == 0 or prot < 0.5) and _vehicle_cover_seek():
			return
		if (cover_type == 0 or prot < 0.5) and G.player != null and (team != G.player_team or G.spectate) and randf() < 0.5:
			var hb := -1
			var hbd := 16.0
			for i in G.blocks.houses.size():
				var hh: Dictionary = G.blocks.houses[i]
				if hh["collapsed"] or not hh.has("slots") or hh["slots"].is_empty():
					continue
				var dd: float = position.distance_to(hh["center"])
				if dd < hbd and G.blocks.house_free_slot(i) >= 0 and G.blocks.house_team(i) in [-1, team]:
					hbd = dd
					hb = i
			if hb >= 0 and cmd_garrison(hb):
				if randf() < 0.3:
					say("BİNAYA GİR!")
				return
		if cover_type == 0 or prot < 0.5:
			var claimed: Array = squad.claimed(self) if squad else []
			var c: Dictionary = G.grid.find_cover(dest, threat_pos, 6.5, claimed, position, 2.5 if role == "sniper" else 1.6)
			if c["type"] > 0:
				cover_pos = c["pos"]
				cover_type = c["type"]
				if cover_pos.distance_to(position) > 0.3:
					to_cover = true
					_set_path(cover_pos)
					state = "move"
					if randf() < 0.15:
						say("SİPER AL!")
					return
			else:
				cover_type = 0
	if cover_type == 3 and cover_veh != null and is_instance_valid(cover_veh):
		# araçla birlikte ilerle: siper noktası aracın tehdide göre arkası
		var away := cover_veh.position - threat_pos
		away.y = 0.0
		var cp := cover_veh.position + away.normalized() * (cover_veh.radius + 0.9) + Vector3(-away.z, 0, away.x).normalized() * cover_slot
		if cp.distance_to(cover_pos) > 1.0:
			cover_pos = G.grid.nearest_free(cp, Grid.M_INF, 4)
			if state == "idle":
				_set_path(cover_pos)
				state = "move"
		return
	if cover_type > 0 and position.distance_to(cover_pos) > 1.2 and state == "idle":
		cover_type = 0
	# hedefe yaklaş (saldırı emri)
	if forced_target != null and order != "hold":
		if not is_instance_valid(forced_target) or not forced_target.hostile():
			forced_target = null
			order = ""
		elif target != forced_target and dist2(forced_target) > 6.0:
			var p := forced_target.position
			dest = p + (position - p).normalized() * minf(dist2(forced_target) * 0.6, weapon()["range"] * 0.7)
			_set_path(dest)
			state = "move"
			return
	_think_grenade()
	_think_ammo()

func _think_role() -> void:
	match role:
		"engineer":
			_think_repair()
		"drone":
			_think_drone()

func _think_repair() -> void:
	if state != "idle" or G.time - threat_time < 4.0:
		repair_target = null
		return
	if repair_target == null or not is_instance_valid(repair_target) or not repair_target.alive or (repair_target.hp >= repair_target.max_hp and not (repair_target is Vehicle and (repair_target.has_crit() or repair_target.tracks_broken > 0.0 or repair_target.tires > 0))):
		repair_target = null
		var best := 20.0
		for u in G.friends_near(position, 20.0, team):
			if (u is Vehicle and u.vtype != "fpv" and (u.hp < u.max_hp or u.tracks_broken > 0.0 or u.tires > 0 or u.has_crit())) or (u is Building and u.done and u.hp < u.max_hp):
				var d := dist2(u)
				if d < best:
					best = d
					repair_target = u
	if repair_target == null:
		return
	# araçta merkeze değil gövdenin en yakın kenarına yaklaşılır (gerçek boyutlu tank 8–10 m)
	var rp: Vector3 = repair_target.obb_closest(position) if repair_target is Vehicle else repair_target.position
	var rr: float = 1.2 if repair_target is Vehicle else repair_target.radius + 1.2
	if Vector2(position.x - rp.x, position.z - rp.z).length() > rr + 0.8:
		if path_i >= path.size():
			var away := position - rp
			away.y = 0.0
			if away.length() < 0.1:
				away = Vector3.RIGHT
			_set_path(G.grid.nearest_free(rp + away.normalized() * rr, Grid.M_INF, 4))
		state = "move"
		return
	repair_vis_t = G.time + 0.7
	if randf() < 0.45:
		G.fx.sparks(repair_target.position.lerp(position, 0.55) + Vector3(0, 0.6, 0), 0.5)
	repair_target.hp = minf(repair_target.max_hp, repair_target.hp + 40.0 * 0.32)
	if repair_target is Vehicle and repair_target.tires > 0 and randf() < 0.25:
		repair_target.tires -= 1
	if repair_target is Vehicle and repair_target.tracks_broken > 0.0:
		repair_target.tracks_broken = maxf(0.0, repair_target.tracks_broken - 3.0)
	if repair_target is Vehicle:
		for ck in repair_target.crit:
			if repair_target.crit[ck] > 0:
				repair_target.crit_t[ck] -= 4.0
		# istihkâm yıpranmayı da yavaşça giderir; yangını söndürür
		repair_target.wear = maxf(0.0, repair_target.wear - 0.006)
		repair_target.eng_fire = maxf(0.0, repair_target.eng_fire - 3.0)
	_face_to(repair_target.position)
	state_t = 0.0
	if randf() < 0.3:
		Sfx.play3d("hammer", position, -10.0, 0.15, 0.2)

func _ai_ctrl() -> bool:
	return G.spectate or team != G.player_team

# Drone operatörü artık kendiliğinden drone kaldırmaz: oyuncu "Mini Drone" (anında, sırt
# çantasından) ya da "Drone İstasyonu" (kurulum → mancınıkla yüksek irtifa keşif İHA'sı) emri verir.
# YZ tarafı aynı iki eylemi kendi kararıyla kullanır.
func cmd_minidrone(p: Vector3, tgt: Unit = null) -> void:
	if not alive or not can_fight() or role != "drone":
		return
	if fpv_left <= 0:
		say("DRONE KALMADI")
		return
	if my_drone != null and is_instance_valid(my_drone) and my_drone.alive:
		# havadaki drone'u yeni hedefe yönlendir
		my_drone.forced_target = tgt
		my_drone.loiter_pt = G.on_ground(p)
		return
	if drone_cd > 0.0:
		say("DRONE HAZIRLANIYOR")
		return
	drone_job = "launch"
	job_pt = G.on_ground(p)
	job_tgt = tgt
	path = PackedVector3Array()
	state = "launch"
	state_t = 0.0
	_face_to(job_pt)
	say("DRONE HAZIRLIYORUM")

func cmd_station(p: Vector3) -> void:
	if not alive or not can_fight() or role != "drone":
		return
	if station != null and is_instance_valid(station) and station.alive:
		if station.done:
			say("İSTASYON ZATEN KURULU")
			return
		station.destroy()
	var gp := G.grid.nearest_free(G.on_ground(p), Grid.M_INF)
	station = DroneStation.new()
	station.team = team
	station.operator = self
	station.position = gp
	station.rotation.y = rotation.y
	G.main.world.add_child(station)
	drone_job = "station"
	job_pt = gp
	order = "station"
	_set_path(gp + Vector3(-0.9, 0, 1.6).rotated(Vector3.UP, rotation.y))
	state = "move"
	say("İSTASYON KURMAYA GİDİYORUM")

func _think_drone() -> void:
	if station != null and (not is_instance_valid(station) or not station.alive):
		station = null
	if drone_job == "pilot":
		# istasyonun yanında kumandayla İHA'yı uçurur; İHA düşer / istasyon giderse görev biter
		if pilot_of == null or not is_instance_valid(pilot_of) or not pilot_of.alive or pilot_of.uav == null or not is_instance_valid(pilot_of.uav) or not pilot_of.uav.alive:
			drone_job = ""
			pilot_of = null
		else:
			var spot: Vector3 = pilot_of.position + Vector3(-2.6, 0, 2.2).rotated(Vector3.UP, pilot_of.rotation.y)
			if dist2_p(spot) > 2.0 and state == "idle":
				_set_path(G.grid.nearest_free(spot, Grid.M_INF, 4))
				state = "move"
			elif state == "idle":
				face_yaw = _yaw_of(pilot_of.uav.position - position)
			return
	if drone_job == "station" and station != null:
		if dist2_p(station.position) > 3.2:
			if state == "idle":
				_set_path(station.position + Vector3(-0.9, 0, 1.6).rotated(Vector3.UP, station.rotation.y))
				state = "move"
		else:
			state = "setup"
			state_t = 0.0
		return
	if not _ai_ctrl():
		return
	# --- YZ operatörü
	if G.weather != null and G.weather.no_air():
		return
	if station == null and G.time - threat_time > 8.0 and suppression < 10.0 and randf() < 0.25:
		cmd_station(position + Vector3(randf_range(-4, 4), 0, randf_range(-4, 4)))
		return
	if my_drone != null and is_instance_valid(my_drone) and my_drone.alive:
		return
	my_drone = null
	if drone_cd > 0.0 or fpv_left <= 0:
		return
	var best: Unit = null
	var bs := 1e9
	var dr := ind_range()
	for e in G.visible_enemies(team):
		if not is_instance_valid(e) or not e.alive or e is Building or dist2(e) > dr:
			continue
		if e is Vehicle and e.is_air():
			continue
		var sc := dist2(e) - (40.0 if e is Vehicle else 0.0)
		if e is Soldier and e.incapacitated():
			continue
		if sc < bs:
			bs = sc
			best = e
	if best != null:
		cmd_minidrone(best.position, best)

# kumandayla drone uçuruyor mu (FPV mini drone ya da istasyon İHA'sının pilotu)
func _piloting() -> bool:
	if role != "drone" or state != "idle":
		return false
	if my_drone != null and is_instance_valid(my_drone) and my_drone.alive:
		return true
	return drone_job == "pilot" and pilot_of != null and is_instance_valid(pilot_of)

func dist2_p(p: Vector3) -> float:
	return Vector2(p.x - position.x, p.z - position.z).length()

# mini drone kaldırma: diz çök, çantadan çıkar, kollarını aç, elden havalanır
func _launch_tick() -> void:
	if state_t >= 1.4 and drone_job == "launch":
		drone_job = ""
		fpv_left -= 1
		drone_cd = 18.0
		var hp0 := position + Vector3(0, 1.0, 0) + (-basis.z) * 0.45
		var dr: Vehicle = G.main.spawn_vehicle(team, "fpv", Vector3(hp0.x, 0, hp0.z), rotation.y)
		dr.hull.position.y = 1.0
		dr.forced_target = job_tgt if job_tgt != null and is_instance_valid(job_tgt) and job_tgt.alive else null
		dr.loiter_pt = job_pt
		dr.operator = self
		my_drone = dr
		say("DRONE HAVADA!")
		Sfx.play3d("drone", position, -8.0)
	if state_t >= 2.0:
		state = "idle"

func _think_grenade() -> void:
	if grenades <= 0 or gren_cd > 0.0 or state != "idle" or suppression > 75 or fire_mode != 0:
		return
	var tp := Vector3.ZERO
	var ok := false
	if target is Soldier and target.alive:
		var d := dist2(target)
		if d > 8.0 and d < 24.0:
			var cov := G.grid.cover_factor(target.position, target.torso_h(), position)
			var cluster := 0
			for e in G.enemies_near(target.position, 4.0, team):
				if e is Soldier and e.can_fight():
					cluster += 1
			if cov > 0.45 or cluster >= 3:
				tp = target.position
				ok = true
	elif target == null and G.time - threat_time < 3.0:
		var d2 := Vector2(threat_pos.x - position.x, threat_pos.z - position.z).length()
		if d2 > 8.0 and d2 < 20.0 and randf() < 0.25:
			tp = threat_pos
			ok = true
	if ok and randf() < 0.35:
		_start_throw(tp, false)

func _start_throw(tp: Vector3, smoke: bool) -> void:
	state = "throw"
	state_t = 0.0
	throw_released = false
	throw_smoke = smoke
	var d := position.distance_to(tp)
	var err := d * 0.09
	throw_to = tp + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	gren_cd = 14.0 + randf() * 8.0
	_face_to(tp, true)
	say("SİS!" if smoke else "EL BOMBASI!")

func _scan() -> void:
	if not can_fight() or retreating or fire_mode == 2:
		target = null
		return
	if fire_mode == 1 and G.time - last_hit > 10.0 and G.time - sup_t > 8.0:
		target = null
		return
	var W := weapon()
	var rng_w: float = W["range"]
	var eye := position + Vector3(0, 1.55 if cover_type == 1 else eye_h(), 0)
	if cover_type == 2:
		eye += lean
	# keskin nişancı: açıktaki mürettebatı içeri giren araca boşuna ateş etmez (komutan yeniden çıkınca sürer)
	if role == "sniper" and target != null and is_instance_valid(target) and target is Vehicle and not target.exposed_crew() and target != forced_target:
		target = null
	# mevcut hedefi koru
	if target != null and is_instance_valid(target) and target.hostile() and dist2(target) < rng_w * 1.1 and G.is_seen(target, team):
		if not (target is Soldier and target.incapacitated()) and sees(eye, target.aim_point(), target):
			threat_pos = target.position
			threat_time = G.time
			return
	target = null
	# boştaki asker (son taramada menzilde kimse yoktu, ateş altında değil): tam tarama ~1 sn'de bir
	# (yüzlerce askerde her 0,3 sn'lik tarama kare süresinin en büyük payıydı)
	if G.time < _scan_next and G.time - last_hit > 1.0 and G.time - sup_t > 1.0 and forced_target == null:
		return
	var cands: Array = []
	for e in G.visible_enemies(team):
		if not is_instance_valid(e) or not e.hostile():
			continue
		var d := dist2(e)
		if d > rng_w + 12.0:
			continue
		var sc := d
		if e is Soldier:
			if not e.alive:
				continue
			if e.incapacitated():
				sc += 40.0
		elif e is Vehicle:
			if not e.alive:
				continue
			if role in ["at", "atgm"] and rockets > 0:
				sc -= 40.0
			elif e.vtype == "fpv":
				sc -= 30.0 if d < 30.0 else 0.0
			elif role == "sniper":
				# açıkta mürettebat (kapaktaki komutan, açık aracın nişancısı / sürücüsü) keskin nişancının hedefi
				sc += -15.0 if e.exposed_crew() else 1000.0
			else:
				sc += 12.0
		elif e is Building:
			if not e.alive:
				continue
			sc += 30.0 if not (role in ["at", "atgm"] and rockets > 0) else -10.0
		if d > rng_w * (1.25 if (role == "at" and not (e is Soldier)) else 1.0):
			if d < rng_w + 12.0:
				threat_pos = e.position
				threat_time = maxf(threat_time, G.time - 6.0)
			continue
		if e == forced_target:
			sc -= 100.0
		elif e == attacker:
			sc -= 6.0
		cands.append([sc, e])
	if cands.is_empty():
		_scan_next = G.time + randf_range(0.8, 1.3)
		return
	cands.sort_custom(func(a, b): return a[0] < b[0])
	var n := 0
	for c in cands:
		n += 1
		if n > 4:
			break
		var e: Unit = c[1]
		var ap: Vector3 = e.aim_point()
		var ok := sees(eye, ap, e)
		if not ok and cover_type == 2:
			# diğer köşeden dene
			var alt := position + Vector3(0, 1.55, 0) - lean
			if G.grid.los(alt, ap):
				lean = -lean
				ok = true
		if ok:
			target = e
			threat_pos = e.position
			threat_time = G.time
			return

func _stance() -> void:
	if stress_lv == 2 and state == "idle":
		stance = PRONE
		return
	if state == "escort" or state == "guard":
		stance = CROUCH if suppression > 50 else STAND
		return
	if stance_lock >= 0 and state in ["idle", "move"] and not force_move:
		stance = stance_lock
		return
	if state == "move":
		stance = CROUCH if (suppression > 55 and not force_move) else STAND
		if suppression > 85 and not force_move:
			stance = PRONE
		return
	if state != "idle":
		return
	var recent := G.time - threat_time < 8.0
	if G.grid.in_trench(position):
		stance = CROUCH if (popped or target != null) else PRONE
		return
	if cover_type == 1:
		stance = STAND if popped else CROUCH
	elif cover_type == 2:
		stance = STAND
	elif recent:
		stance = PRONE if suppression > 40 else CROUCH
	else:
		stance = STAND
	if role == "sniper" and cover_type == 0 and not G.grid.in_trench(position):
		stance = PRONE
	if suppression > 80 and cover_type != 1:
		stance = PRONE

# ------------------------------------------------------------ hareket
func _movement(dt: float) -> void:
	var want := Vector3.ZERO
	var spd := 0.0
	match state:
		"move", "rescue":
			spd = RUN_SPEED
			if target != null and is_instance_valid(target) and (popped or burst_left > 0) and not force_move and state == "move":
				spd = 2.0
			if stance == CROUCH:
				spd = 1.9
			elif stance == PRONE:
				spd = 0.7
			if state == "rescue":
				spd = RUN_SPEED * 1.05
			if limp_t > 0.0:
				spd = minf(spd, 1.5)
			if injury != "":
				spd = minf(spd, injury_speed())
			if flinch_t > 0.0:
				spd *= 0.4
			if body_lift > 0.2:
				spd = minf(spd, 2.0)
			if cold > 50.0:
				spd *= 0.78
			want = _follow(spd)
		"escort":
			want = _escort_move()
		"guard":
			want = _guard_move()
		"stretcher":
			want = _stretcher_move()
		"prisoner":
			want = _follow(1.5)
		"slide":
			want = fly_vel
			fly_vel = fly_vel.lerp(Vector3.ZERO, clampf(dt * 4.5, 0, 1))
			if state_t > 0.5:
				state = "idle"
				stance = CROUCH
		"melee":
			if state_t > 0.22 and not melee_hit:
				melee_hit = true
				if melee_target != null and is_instance_valid(melee_target) and melee_target.alive and dist2(melee_target) < 2.3:
					melee_target.take_damage(randf_range(45.0, 80.0), self, "melee")
					melee_target.add_suppression(40.0, position)
					Sfx.play3d("hammer", position, -4.0, 0.25)
			if state_t > 0.6:
				state = "idle"
				melee_cd = randf_range(1.0, 1.6)
		"drag":
			want = _follow(1.25)
		"wounded":
			want = _follow(0.35)
		"dive":
			want = fly_vel
			fly_vel = fly_vel.lerp(Vector3.ZERO, clampf(dt * 4.0, 0, 1))
			if state_t > 0.5:
				state = "idle"
				stance = PRONE
				suppression = maxf(suppression, 60.0)
		"fly":
			_fly(dt)
			return
		"dazed":
			want = Vector3(sin(G.time * 1.7 + position.x), 0, cos(G.time * 1.3 + position.z)) * 0.6
		"throw":
			_throw(dt)
	# ayrışma
	var sep := Vector3.ZERO
	var veh_step := Vector3.ZERO
	# yürürken her kare; dururken ~5 kez/sn (yüzlerce askerde komşu sorguları kare süresinin payıydı)
	_sep_t -= dt
	var do_sep := _sep_t <= 0.0 or want.length_squared() > 0.01
	if not do_sep:
		sep = _sep_c
		veh_step = _veh_c
		if veh_step != Vector3.ZERO:
			want = (want + veh_step).limit_length(RUN_SPEED)
	elif state != "dragged" and state != "drag":
		_sep_t = 0.2
		for o in G.near(position, 1.6):
			if o == self or o == patient:
				continue
			var dv = position - o.position
			dv.y = 0
			var dl = dv.length()
			if o is Soldier:
				if not o.alive or o.state == "dragged":
					continue
				if dl < 0.75 and dl > 0.001:
					sep += dv / dl * (0.75 - dl) * 7.0
				elif dl <= 0.001:
					sep += Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
			elif o is Vehicle and o.alive:
				pass
		# araç izi içindeysek araç itmez: asker kendi adımlarıyla izin dışına yürür (10 kez/sn denetim)
		_vp_t -= dt
		if _vp_t <= 0.0:
			_vp_t = 0.1
			_vp_c = Vector3.ZERO
			_near_veh.clear()
			var n_in := 0
			for o in G.near(position, 8.0):
				if o is Vehicle and (o.alive or o.wreck) and not o.is_air() and state != "aboard":
					_near_veh.append(o)
					# yürürken yalnız gerçekten izin içindeyse dışarı it (adım izdüşümü zaten girmeyi önler; geniş bölgede
					# itme köşede kaymayla çatışıyordu); dururken 0,35 m — üstüne gelen / yanında doğan araçtan açılır
					var pv: Vector3 = o.obb_push(position, 0.05 if want.length() > 0.5 else 0.35)
					if pv != Vector3.ZERO:
						n_in += 1
						_vp_c += pv.normalized() * clampf(pv.length() * 6.0, 1.2, 2.6)
			_escaping = false
			for o in _near_veh:
				if o.obb_push(position, -0.05) != Vector3.ZERO:
					_escaping = true          # gerçekten gövdenin içinde (doğma / araç üstüne geldi)
					break
			if n_in > 1 or _vp_c.length() < 1.0 and n_in > 0:
				# iki araç arasına sıkıştı (itmeler birbirini götürüyor): tüm araçların dışındaki en yakın açık nokta —
				# halkada itme yönüne en yakın olanı
				var pref := _vp_c.normalized() if _vp_c.length() > 0.01 else Vector3.ZERO
				_vp_c = Vector3.ZERO
				for r in [0.6, 1.2, 2.0, 3.0, 4.0]:
					var bestc := Vector3.INF
					var bdot := -2.0
					for i in 12:
						var a := TAU * i / 12.0
						var dirv := Vector3(cos(a), 0, sin(a))
						var c: Vector3 = position + dirv * float(r)
						var free := G.grid.height_at(c) < 0.45 and not G.grid.is_water(c)
						for o in _near_veh:
							if free and o.obb_push(c, 0.4) != Vector3.ZERO:
								free = false
						if free and dirv.dot(pref) > bdot:
							bdot = dirv.dot(pref)
							bestc = c
					if bestc != Vector3.INF:
						_vp_c = (bestc - position).normalized() * 2.4
						break
		veh_step += _vp_c
		if G.time < yield_until and yield_veh != null and is_instance_valid(yield_veh) and state in ["idle", "move", "escort", "build"]:
			veh_step += _yield_step()
		if veh_step != Vector3.ZERO:
			want = (want + veh_step).limit_length(RUN_SPEED)
		_sep_c = sep
		_veh_c = veh_step
	vel = want
	var mv := (want + sep) * dt
	if mv.length_squared() > 0.0:
		var np := position + mv
		# araç gövdesinin içinden geçilmez (roadmap 105): adım aracın izine giriyorsa izin kenarına izdüşülür
		# (asker aracın yanından kayarak dolaşır); zaten içindeyse (araç üstüne geldi) yukarıdaki itme çıkarır
		if not _escaping:
			for o in _near_veh:
				if not is_instance_valid(o):
					continue
				if o == board_target and dist2(o) < o.radius + 4.0:
					continue          # binmeye gittiği araç: kapıya yanaşabilsin (kendi biniş yaklaşması var)
				var pv: Vector3 = o.obb_push(np, 0.15)
				if pv == Vector3.ZERO:
					continue
				np += pv
				# gövde kenarı boyunca kay: adımın teğet yönü hedefe doğru; tam karşıdan geliyorsa yakın köşeye
				# UP × dış normal: her yüzde aracın çevresinde aynı dönüş yönü — köşelerde de aynı yöne dolaşılır
				var tn := Vector3.UP.cross(pv.normalized())
				var md := mv.normalized()
				if (_slide_veh != o or G.time - _slide_t > 3.0) and state == "move" and path_i < path.size():
					# ilk temas: aracın bir yanından köşe noktalarıyla dolaşan rota (araçlar gibi, ışınlanmadan)
					_detour_vehicle(o)
				if _slide_veh != o or G.time - _slide_t > 3.0:
					# yön ilk temasta bir kez seçilir (tam karşıdan gelende sağ/sol arasında titremesin)
					var td := tn.dot(md)
					if absf(td) < 0.15:
						td = (position - o.position).dot(tn)
						if absf(td) < 0.05:
							td = 1.0 if (get_instance_id() & 1) == 0 else -1.0
					_slide_veh = o
					_slide_sgn = signf(td)
				_slide_t = G.time
				tn *= _slide_sgn
				np += tn * mv.length()
				if o.obb_push(np, 0.15) != Vector3.ZERO:
					np = position + tn * mv.length()
				if G.grid.height_at(np) >= 0.45:
					# kayma yönü duvara / eşyaya çıkıyor (araç ile engel arasında sıkıştı): öbür köşeden dolaş
					_slide_sgn = -_slide_sgn
					np = position
		np.x = clampf(np.x, 1.0, G.MAP - 1.0)
		np.z = clampf(np.z, 1.0, G.MAP - 1.0)
		var hn := G.grid.height_at(np)
		var vault_ok := want.length() > 0.5 and state in ["move", "rescue", "escort", "prisoner", "stretcher"] and hn < 1.15
		if ((hn < 0.45 or vault_ok) and not G.grid.is_water(np)) or G.grid.height_at(position) >= 0.45:
			position = np
		else:
			var nx := Vector3(np.x, 0, position.z)
			var nz := Vector3(position.x, 0, np.z)
			if G.grid.height_at(nx) < 0.45:
				position = nx
			elif G.grid.height_at(nz) < 0.45:
				position = nz
	position.y = _ground_y(position)
	# alçak duvar / engelin üstünden atlama
	var hh := G.grid.height_at(position)
	body_lift = lerpf(body_lift, hh + 0.02 if (hh >= 0.3 and hh < 1.15) else 0.0, clampf(dt * 14.0, 0, 1))
	# yön
	var aiming := target != null and is_instance_valid(target) and can_fight() and state in ["idle", "move", "escort", "guard"] and (burst_left > 0 or fire_cd < 0.6 or popped)
	if state == "melee" and melee_target != null and is_instance_valid(melee_target):
		face_yaw = _yaw_of(melee_target.position - position)
	elif state == "drag" or (state == "stretcher" and _stretcher_back()):
		if want.length() > 0.05:
			face_yaw = _yaw_of(-want)
	elif state == "guard" and guard_of != null and is_instance_valid(guard_of) and not aiming:
		face_yaw = _yaw_of(guard_of.position - position)
	elif state == "escort" and not aiming:
		face_yaw = _yaw_of(threat_pos - position) if G.time - threat_time < 10.0 else _yaw_of(want) if want.length() > 0.2 else face_yaw
	elif state == "heal" or state == "build" or state == "rescue":
		var tp: Vector3 = patient.position if patient != null and is_instance_valid(patient) else (build_site.position if build_site != null and is_instance_valid(build_site) else position + want)
		if state == "rescue" and want.length() > 0.1:
			face_yaw = _yaw_of(want)
		elif tp.distance_to(position) > 0.1:
			face_yaw = _yaw_of(tp - position)
	elif aiming and (want.length() < 2.0 or randf() < 1.0):
		face_yaw = _yaw_of(target.position - position)
	elif want.length() > 0.2:
		face_yaw = _yaw_of(want)
	elif G.time - threat_time < 8.0 and state == "idle":
		face_yaw = _yaw_of(threat_pos - position)
	rotation.y = lerp_angle(rotation.y, face_yaw, clampf(dt * 8.0, 0, 1))

func _follow(spd: float) -> Vector3:
	while path_i < path.size():
		var tp := path[path_i]
		var d := Vector3(tp.x - position.x, 0, tp.z - position.z)
		var L := d.length()
		var near_end := path_i == path.size() - 1
		# aynı noktaya giden komşu itiyorsa (ayrışma) 1 m'de varmış say — ikisi de 0,25 m'ye giremeyip sonsuza dek
		# kıpırdanıyordu (roadmap 116: "sıkışmış gibi sağa sola kayma")
		var crowded := near_end and _sep_c.length() > 0.4
		if L < (0.25 if not near_end else (1.0 if crowded else 0.25)) or (not near_end and L < 0.6):
			path_i += 1
			continue
		var s := spd
		if near_end and L < 1.0:
			s = maxf(0.6, spd * L)
		return d / L * s
	return Vector3.ZERO

static func _yaw_of(d: Vector3) -> float:
	return atan2(-d.x, -d.z)

func _face_to(p: Vector3, instant := false) -> void:
	face_yaw = _yaw_of(p - position)
	if instant:
		rotation.y = face_yaw

# yolu araç gövdesinden geçen asker için aracın sağından ya da solundan köşe noktaları (0,8 m pay): ızgarada
# yürünebilir olan ve kısa olan taraf yola eklenir (roadmap 105 — araç ile çit arasına sıkışıp kalıyordu)
func _detour_vehicle(o) -> void:
	var goal: Vector3 = path[path.size() - 1]
	var f: Vector3 = o.forward()
	var r: Vector3 = o.right()
	var ex: float = o.ext.x + 0.8
	var ez: float = o.ext.y + 0.8
	var best: Array = []
	var bl := INF
	for sx in [1.0, -1.0]:
		var c1: Vector3 = o.position + r * sx * ex + f * ez
		var c2: Vector3 = o.position + r * sx * ex - f * ez
		var wp: Array = [c1, c2] if position.distance_to(c1) < position.distance_to(c2) else [c2, c1]
		var pts: Array = [position] + wp + [goal]
		var ok := true
		var L := 0.0
		for k in range(1, pts.size()):
			var a: Vector3 = pts[k - 1]
			var b: Vector3 = pts[k]
			L += b.distance_to(a)
			if not G.grid.walkable_line(a, b, Grid.M_INF) or not G.grid.free_at(b, Grid.M_INF):
				ok = false
				break
			# ince ızgarada da açık mı (çit / eşya ile araç arasındaki dar boşluk iri ızgarada açık görünür)
			var n := int(a.distance_to(b) / 0.25) + 1
			for s in range(1, n + 1):
				var q := a.lerp(b, float(s) / n)
				if G.grid.height_at(q) >= 0.45 or G.grid.is_water(q):
					ok = false
					break
			if not ok:
				break
		if ok and L < bl:
			bl = L
			best = wp
	if not best.is_empty():
		var np := PackedVector3Array()
		for p in best:
			np.append(Vector3(p.x, 0.0, p.z))
		for k in range(path_i, path.size()):
			np.append(path[k])
		path = np
		path_i = 0

# askerin bastığı zemin (roadmap 60 / 119): arazi yalnız oyuklarda (nehir yatağı ve şevi, krater, siper)
# sıfırın altına iner — eskiden y = 0 tutuluyordu, nehir kıyısında / kraterde asker havada duruyordu.
# Köprü güvertesi 0'da.
func _ground_y(p: Vector3) -> float:
	if G.terrain == null or G.grid.on_bridge(p):
		return 0.0
	return minf(0.0, G.terrain.ground_hs(p))

func _fly(dt: float) -> void:
	position += fly_vel * dt
	fly_vel.y -= 15.0 * dt
	fly_ang += fly_spin * dt
	var gy := _ground_y(position)
	if position.y <= gy and fly_vel.y < 0.0:
		position.y = gy
		fly_ang = 0.0
		fly_end = G.time
		G.fx.impact(position, "dirt")
		if not alive:
			state = "dead"
		elif hp <= 0.0:
			_down(null, true)
		else:
			state = "dazed"
			state_t = 0.0
			stance = STAND
			if randf() < 0.4:
				say("...")
	position.x = clampf(position.x, 1.0, G.MAP - 1.0)
	position.z = clampf(position.z, 1.0, G.MAP - 1.0)

func _throw(_dt: float) -> void:
	if not throw_released and state_t > 0.42:
		throw_released = true
		var hand := position + Vector3(0, 1.8, 0)
		if throw_smoke:
			smoke_nades -= 1
		else:
			grenades -= 1
		G.bal.grenade(hand, throw_to, team, self, throw_smoke)
	if state_t > 0.75:
		state = "rescue" if patient != null else "idle"

# ------------------------------------------------------------ ateş
func _combat(_dt: float) -> void:
	if G.deploy_t > 0.0 or not can_fight() or state in ["throw", "drag", "heal", "build", "dazed", "rescue", "melee"] or flinch_t > 0.0 or bearer:
		popped = false
		return
	if one_armed():
		popped = false
		if state in ["idle", "move"]:
			_pistol()
		return
	if role == "mortar" and state == "idle":
		_mortar_fire()
	if reload_t > 0.0:
		popped = false if cover_type == 1 else popped
		return
	if G.time < suppress_until and state == "idle" and fire_mode != 2 and role != "mortar":
		# baskı ateşi emri: hedef görünmese de bölgeyi ateş altında tut
		popped = true
		if fire_cd <= 0.0 and ammo > 0:
			_area_fire(suppress_pt, 4.0)
		return
	var t := target
	var covering := G.time < covering_until
	if t == null or not is_instance_valid(t) or not t.alive:
		target = null
		popped = false
		if covering and G.time - threat_time < 6.0 and fire_cd <= 0.0 and ammo > 0:
			_area_fire()
		return
	if state == "move" and (force_move or stance == PRONE):
		return
	if role == "mortar":
		return
	# tanksavar roket
	if role in ["at", "atgm"] and rockets > 0 and (t is Vehicle or t is Building):
		if state == "move":
			return
		rocket_aim += _dt
		popped = true
		var gm := role == "atgm"
		# nişan / kilit (roadmap 15): Javelin ~4 sn (komuta birimi soğutma + kilit), Kornet 1,5, RPG 1,3, AT4 1
		var lk := Ballistics.lock_time(Ballistics.missile_key(("topatk" if (G.nation[team] if team >= 0 and team < G.nation.size() else "usa") in ["usa", "gbr"] else "atgm") if gm else "rpg", "", team))
		if rocket_aim > lk and fire_cd <= 0.0:
			rocket_aim = 0.0
			rockets -= 1
			fire_cd = 9.0 if gm else 4.5
			var mp := body.muzzle_pos()
			# ABD/İngiltere: ateşle-unut üstten saldırı; Rusya/Çin: lazer güdümlü doğrudan
			var nat: String = G.nation[team] if team >= 0 and team < G.nation.size() else "usa"
			G.bal.rocket(mp, t.aim_point(), team, self, t, ("topatk" if nat in ["usa", "gbr"] else "atgm") if gm else "rpg")
			Sfx.play3d("rpg", position, 2.0)
			G.fx.muzzle(mp, (t.aim_point() - mp).normalized(), true)
			for i in 4:
				G.fx.emit(Fx.P_SMOKE, position + Vector3(0, 1.2, 0), (position - t.position).normalized() * randf_range(2, 5) + Vector3(0, 0.5, 0), randf_range(1.0, 1.8), 0.4, 1.6, -0.1, 2.0, Color(0.8, 0.78, 0.74, 0.5))
			say("ROKET!")
		return
	rocket_aim = 0.0
	# alçak siperde: kalk-ateş et-eğil döngüsü
	if cover_type == 1 and state == "idle":
		if not popped and popup_t <= 0.0 and suppression < 62.0:
			popped = true
			popup_t = randf_range(1.6, 3.4) * (1.5 if covering else 1.0)
		elif popped and (popup_t <= 0.0 or suppression > 72.0):
			popped = false
			popup_t = randf_range(0.8, 2.0)
		if not popped:
			_blind_fire(t, false)
			return
	elif cover_type == 2 and state == "idle":
		if lean == Vector3.ZERO:
			var d := (t.position - position)
			d.y = 0
			lean = Vector3(-d.z, 0, d.x).normalized() * 0.55
		popped = suppression < 85.0
		if not popped:
			_blind_fire(t, true)
			return
	elif cover_type == 3 and state == "idle" and cover_veh != null and is_instance_valid(cover_veh):
		# araç arkası: yandan uzanıp ateş et, ağır ateşte kör ateş
		if lean == Vector3.ZERO:
			var d2 := (t.position - position)
			d2.y = 0
			lean = Vector3(-d2.z, 0, d2.x).normalized() * 0.6
		popped = suppression < 75.0
		if not popped:
			_blind_fire(t, true)
			return
	else:
		popped = true
		if suppression > 88.0 and randf() < 0.7:
			return
	if fire_cd > 0.0 or stress_lv == 2:
		return
	var W := weapon()
	if burst_left <= 0:
		burst_left = randi_range(W["b0"], W["b1"])
		if ammo < 40:
			burst_left = 1
	_shoot(t)
	burst_left -= 1
	var rof: float = W["rof"] * (0.75 if covering else 1.0)
	if ammo < 40:
		rof *= 4.0
	fire_cd = rof if burst_left > 0 else randf_range(W["p0"], W["p1"]) * (0.7 if covering else 1.0)
	fire_cd *= [1.0, 1.35, 2.0][stress_lv]

func _blind_fire(t: Unit, side: bool) -> void:
	if fire_cd > 0.0 or stress_lv == 2 or ammo <= 0 or role in ["at", "atgm", "mortar", "sniper", "medic"] or not is_instance_valid(t) or not t.hostile() or (t is Soldier and t.incapacitated()):
		return
	if suppression < 45.0 and not side:
		return
	blind_t = 0.6
	blind_side = side
	var W := weapon()
	if burst_left <= 0:
		burst_left = randi_range(W["b0"], W["b1"] + 2)
	_shoot(t)
	burst_left -= 1
	fire_cd = (W["rof"] if burst_left > 0 else randf_range(W["p0"], W["p1"]) * 1.3)
	if randf() < 0.03:
		say(["KÖR ATEŞ!", "KAFANI KALDIRMA!", "ÖRTÜ ATEŞİ!"][randi() % 3])

func _mortar_meshes() -> void:
	if not _mortar_parts.is_empty():
		return
	var od := Color(0.28, 0.31, 0.22)
	var dk := Color(0.12, 0.12, 0.12)
	var b := MB.new()
	b.cyl(Vector3(0, 0.02, 0), 0.28, 0.24, 0.05, 14, dk)                       # taban plakası
	b.box(Vector3(0, 0.05, 0), Vector3(0.06, 0.05, 0.5), dk)
	b.box(Vector3(0, 0.05, 0), Vector3(0.5, 0.05, 0.06), dk)
	var bp := MB.new()
	for sx in [-1.0, 1.0]:
		bp.cyl_between(Vector3(sx * 0.32, 0.0, -0.55), Vector3(sx * 0.05, 0.62, -0.32), 0.016, 0.016, 6, dk, false)
	bp.box(Vector3(0, 0.62, -0.32), Vector3(0.16, 0.05, 0.05), dk)
	bp.box(Vector3(-0.1, 0.72, -0.3), Vector3(0.06, 0.08, 0.1), Color(0.2, 0.22, 0.2))        # nişangâh
	var tb := MB.new()
	tb.cyl_between(Vector3(0, 0.05, 0), Vector3(0, 0.05, 0) + Vector3(0, sin(1.15), -cos(1.15)) * 1.25, 0.045, 0.042, 10, od, true)
	_mortar_parts = [b.commit(Mats.vc()), bp.commit(Mats.vc()), tb.commit(Mats.vc())]

func _mortar_visual() -> void:
	var k := clampf(mortar_setup / 4.0, 0.0, 1.0)
	if k <= 0.0 or not alive:
		if mortar_prop != null:
			mortar_prop.queue_free()
			mortar_prop = null
		return
	if mortar_prop == null:
		_mortar_meshes()
		mortar_prop = Node3D.new()
		G.main.world.add_child(mortar_prop)
		var fw := Vector3(-sin(rotation.y), 0, -cos(rotation.y))
		mortar_prop.position = G.on_ground(position + fw * 0.85)
		mortar_prop.rotation.y = rotation.y
		for i in 3:
			var mi := MeshInstance3D.new()
			mi.mesh = _mortar_parts[i]
			mortar_prop.add_child(mi)
	var parts := mortar_prop.get_children()
	(parts[0] as Node3D).visible = k > 0.05
	(parts[1] as Node3D).visible = k > 0.4
	(parts[2] as Node3D).visible = k > 0.75
	# atış: namlu kısa süre geri teper, taban plakası toz kaldırır
	var rk := clampf(1.0 - (G.time - _mortar_fired) / 0.35, 0.0, 1.0)
	(parts[2] as Node3D).position = Vector3(0, -0.05 * rk, 0.06 * rk)

func _mortar_muzzle() -> Vector3:
	if mortar_prop != null:
		return mortar_prop.global_transform * (Vector3(0, 0.05, 0) + Vector3(0, sin(1.15), -cos(1.15)) * 1.25)
	return position + Vector3(0, 1.0, 0)

func _mortar_fire() -> void:
	if mortar_setup < 4.0:
		if mortar_setup == 0.0:
			say("HAVANI KURUYORUM")
		mortar_setup += 0.45
		return
	if mortar_cd > 0.0 or mortar_rounds <= 0:
		return
	var best: Unit = null
	var bs := 1e9
	var mr := ind_range()
	for e in G.visible_enemies(team):
		if not is_instance_valid(e) or not e.alive or (e is Vehicle and e.is_air()):
			continue
		var d := dist2(e)
		if d < 16.0 or d > mr:
			continue
		var sc := d
		if e is Soldier:
			if e.incapacitated():
				continue
			# kalabalık hedefleri tercih et
			sc -= G.enemies_near(e.position, 6.0, team).size() * 8.0
		if sc < bs:
			bs = sc
			best = e
	if best == null:
		return
	mortar_cd = randf_range(4.0, 5.5)
	mortar_rounds -= 1
	var d2 := dist2(best)
	var err := d2 * 0.06 + 1.5
	var tp := best.position + Vector3(randf_range(-err, err), 0, randf_range(-err, err))
	_mortar_fired = G.time
	var mz := _mortar_muzzle()
	G.bal.mortar(mz, tp, team, self)
	if mortar_prop != null:
		G.fx.vehicle_dust(mortar_prop.global_position + Vector3(0, 0.1, 0))
	_face_to(best.position)
	Sfx.play3d("mortar", position, 0.0)
	G.fx.muzzle(position + Vector3(0, 1.2, 0), Vector3.UP, true)
	if randf() < 0.2:
		say("ATEŞ! HAVAN!")

func _shoot(t: Unit) -> void:
	var W := weapon()
	if ammo <= 0:
		if randf() < 0.05:
			say("MERMİ BİTTİ!")
		fire_cd = 2.0
		return
	mag -= 1
	ammo -= 1
	shots += 1
	fired_t = G.time
	body.kick()
	if ammo < 40 and not low_ammo_said:
		low_ammo_said = true
		say("MERMİ AZ!")
	if mag <= 0:
		reload_t = W["reload"] * (1.0 + stress_lv * 0.4)
		burst_left = 0
		if randf() < 0.15:
			say("ŞARJÖR!")
	var mp := body.muzzle_pos()
	var tp := t.aim_point()
	var dir := (tp - mp).normalized()
	G.fx.muzzle(mp, dir, role == "mg")
	Sfx.play3d(W["snd"], mp, -2.0 if role != "mg" else 0.0, 0.1, 0.02)
	var d := mp.distance_to(tp)
	var chance := _hit_chance(t, d)
	var impact := tp
	var hit := randf() < chance
	if hit:
		var dmg: float = W["dmg"] * randf_range(0.8, 1.25)
		t.take_damage(dmg, self, "bullet")
		if t is Vehicle and t.armor > 0:
			G.fx.impact(tp, "metal")
	else:
		var side := Vector3(-dir.z, 0, dir.x)
		impact = tp + side * randf_range(-1.3, 1.3) + dir * randf_range(-0.5, 3.0)
		impact.y = randf_range(0.0, tp.y + 0.4)
		# alçaksa yere çarpar
		if impact.y < 0.25 or randf() < 0.5:
			impact.y = 0.02
		var hv := G.grid.height_at(impact)
		G.fx.impact(impact, "wall" if hv > impact.y else "dirt")
		if t is Soldier:
			t.add_suppression(W["sup"], position)
		for o in G.near(impact, 2.5):
			if o is Soldier and o != t and o.team != team and o.alive:
				o.add_suppression(W["sup"] * 0.5, position)
		if randf() < 0.18:
			Sfx.play3d("whiz", impact, -8.0, 0.2, 0.08)
	if shots % W["tr"] == 0:
		_tracer(mp, impact, 240.0)

# iz kalibresi: makineli 7,62 (kalın, uzun), tüfek 5,56 (ince, kısa); nişancı izi soluk ve ince
# (gerçekte iz mermisi kullanmaz, yalnız havadaki iz dalgası seçilir)
func _tracer(a: Vector3, b: Vector3, spd: float) -> void:
	var col := Ammo.team_tracer(team)
	if role == "sniper":
		col.a = 0.35
		G.fx.tracer(a, b, spd * 1.4, col, 0.018, 6.0)
		return
	G.fx.tracer_cal(a, b, spd, col, 7.62 if role == "mg" else 5.56)

func _area_fire(center := Vector3.INF, spread := 3.0) -> void:
	# örtme ateşi: hedef görünmese de tehdit bölgesine
	if center == Vector3.INF:
		center = threat_pos
	var W := weapon()
	var mp := body.muzzle_pos()
	var p := center + Vector3(randf_range(-spread, spread), randf_range(0.2, 1.4), randf_range(-spread, spread))
	if not G.grid.los(position + Vector3(0, eye_h(), 0), p, 0.75, 1.5):
		fire_cd = 0.6
		return
	mag -= 1
	ammo -= 1
	shots += 1
	body.kick()
	if mag <= 0:
		reload_t = W["reload"] * (1.0 + stress_lv * 0.4)
	G.fx.muzzle(mp, (p - mp).normalized(), role == "mg")
	Sfx.play3d(W["snd"], mp, -3.0, 0.1, 0.02)
	G.fx.impact(Vector3(p.x, 0.02, p.z), "dirt")
	for o in G.near(p, 3.0):
		if o is Soldier and o.team != team and o.alive:
			o.add_suppression(W["sup"] * 1.2, position)
	if shots % W["tr"] == 0:
		_tracer(mp, p, 240.0)
	fire_cd = W["rof"] * 1.3 if randf() < 0.8 else randf_range(0.4, 0.9)
	_face_to(p)

func _hit_chance(t: Unit, d: float) -> float:
	var W := weapon()
	var c: float = W["acc"] * (1.0 - pow(clampf(d / W["range"], 0.0, 1.0), 1.3) * 0.65)
	if led():
		c *= 1.12
	if t is Soldier:
		c *= [1.0, 0.72, 0.45][t.stance]
		if t.vel.length() > 1.5:
			c *= 0.75
		var cov := maxf(G.grid.cover_factor(t.position, t.torso_h(), position), t.vehicle_cover(position))
		if t.house_id >= 0 and t.state == "idle":
			cov = 0.72 if not t.popped else 0.55
		c *= 1.0 - cov * 0.78
	else:
		c = clampf(c * 2.0, 0.0, 0.95)
	if vel.length() > 0.5:
		c *= 0.5
	c *= 1.0 - suppression / 170.0
	c *= [1.0, 0.78, 0.5][stress_lv]
	if blind_t > 0.0:
		c *= 0.28
	if cold > 50.0:
		c *= 0.8
	c *= 1.0 + accuracy_bonus
	c *= injury_acc()
	return clampf(c, 0.02, 0.95)

# araç arkası siper: atıcı ile aramızda bir araç varsa koruma
func vehicle_cover(from: Vector3) -> float:
	if cover_veh == null or not is_instance_valid(cover_veh) or not cover_veh.alive and not cover_veh.wreck:
		return 0.0
	var a := from - position
	a.y = 0
	var b := cover_veh.position - position
	b.y = 0
	if b.length() > cover_veh.radius + 2.2 or a.length() < 0.1:
		return 0.0
	return 0.85 if a.normalized().dot(b.normalized()) > 0.55 else 0.0

func add_stress(v: float) -> void:
	if not alive or incapacitated() or state in ["prisoner", "surrender", "hospital", "aboard"]:
		return
	if led():
		v *= 0.7
	stress = minf(100.0, stress + v)
	stress_t = G.time
	_stress_level()

func _stress_level() -> void:
	var nl := 2 if stress >= 85.0 else (1 if stress >= 50.0 else 0)
	# gecikmeli dönüş: panik 55'in altına, sarsılma 35'in altına inince biter
	if stress_lv == 2 and stress > 55.0:
		nl = 2
	elif stress_lv >= 1 and nl == 0 and stress > 35.0:
		nl = 1
	if nl == stress_lv:
		return
	if nl > stress_lv:
		say("PANİK!" if nl == 2 else ["SARSILDIM!", "KAFAM GİTTİ!", "ÇOK YAKINDI!"][randi() % 3], 2.0)
	if nl < 2:
		panic_fled = false
	stress_lv = nl

# panik: tehditten uzağa kaç (en yakın siper/üs yönü), sonra yere yat
func _panic_flee() -> void:
	panic_fled = true
	var away := position - threat_pos
	away.y = 0.0
	if away.length() < 0.5 or G.time - threat_time > 12.0:
		var b := nearest_base()
		away = (b.position - position) if b != null else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1))
		away.y = 0.0
	var p := position + away.normalized() * 16.0
	cmd_move(G.grid.nearest_free(G.on_ground(p), Grid.M_INF), true)
	order = "panic"
	target = null
	burst_left = 0

func add_suppression(v: float, from: Vector3) -> void:
	if not alive:
		return
	if retreating:
		v *= 0.3
	suppression = minf(100.0, suppression + v)
	sup_t = G.time
	add_stress(v * 0.32)
	if G.time - threat_time > 2.0 or target == null:
		threat_pos = from
		threat_time = G.time
	if suppression > 75.0 and randf() < 0.02:
		say(["BASTIRILDIK!", "KAFANI KALDIRMA!", "SİPER!"][randi() % 3])

# ------------------------------------------------------------ hasar
# yelek (roadmap 51): seramik plakalı yelek gövdeye gelen tüfek mermisini çoğunlukla durdurur (darbe hasarı
# kalır), nişancı / makineli AP mermisi kısmen geçer; yumuşak yelek (nişancı, araç mürettebatı) yalnız
# parçacığa karşı. İsabetin ~yarısı gövdeye (plaka) gelir.
const VEST := {"rifle": "plate", "leader": "plate", "mg": "plate", "at": "plate", "atgm": "plate", "engineer": "plate",
	"medic": "plate", "mortar": "plate", "drone": "plate", "sniper": "soft", "crew": "soft"}

func _vest_mult(kind: String) -> float:
	var v := String(VEST.get(role, "soft"))
	if kind in ["bullet", "sniper", "hmg"]:
		if randf() < 0.5 and v == "plate":
			return {"bullet": 0.25, "sniper": 0.6, "hmg": 0.85}.get(kind, 1.0)
		return 1.0
	if kind in ["grenade", "shell", "mortar", "blast", "big", "rpg", "auto"]:
		return 0.7 if v == "plate" else 0.85
	return 1.0

# isabet bölgesi: baş / gövde / kol / bacak — yüzüstü, siperde ya da siper arkasında baş ve omuz daha açık
var last_zone := ""

func _hit_zone() -> String:
	var r := randf()
	if stance == PRONE or cover_type > 0 or G.grid.in_trench(position):
		return "head" if r < 0.2 else ("torso" if r < 0.6 else ("arm" if r < 0.9 else "leg"))
	return "head" if r < 0.08 else ("torso" if r < 0.5 else ("arm" if r < 0.7 else "leg"))

# bölgeye göre hasar çarpanı: kask parçaların çoğunu, tüfek mermisini nadiren durdurur; plaka gövdenin
# ortasını (isabetlerin ~%65'i) korur, yumuşak yelek tabanca/parça düzeyinde; uzuv isabeti daha az öldürücü
func _zone_mult(zone: String, kind: String) -> float:
	var v := String(VEST.get(role, "soft"))
	var frag := kind in ["grenade", "shell", "mortar", "blast", "big", "auto", "rpg"]
	match zone:
		"head":
			if frag:
				return 0.3 if randf() < 0.7 else 1.8
			return 0.35 if randf() < 0.12 else 2.6
		"torso":
			if frag:
				return 0.6 if v == "plate" else 0.85
			if v == "plate" and randf() < 0.65:
				return {"bullet": 0.2, "sniper": 0.55, "hmg": 0.85}.get(kind, 1.0)
			if v == "soft" and kind == "bullet" and randf() < 0.3:
				return 0.6
			return 1.0
		"arm":
			return 0.55
		"leg":
			return 0.7
	return 1.0

# isabet bölgesinin dünyadaki yeri (kan sıçraması orada)
func zone_point(zone: String) -> Vector3:
	if body == null or body.spine == null:
		return aim_point()
	match zone:
		"head":
			return body.spine.global_transform * Vector3(0, 0.77, -0.04)
		"arm":
			return (body.arm_r if randf() < 0.5 else body.arm_l).global_transform * Vector3(0, -0.14, 0)
		"leg":
			return (body.leg_r if randf() < 0.5 else body.leg_l).global_transform * Vector3(0, -0.2, 0)
	return body.spine.global_transform * Vector3(0, 0.3, -0.06)

func take_damage(amount: float, src, _kind := "bullet") -> void:
	if not alive:
		return
	var zone := _hit_zone()
	last_zone = zone
	amount *= _zone_mult(zone, _kind)
	if src != null and is_instance_valid(src):
		attacker = src
		threat_pos = src.position
		threat_time = G.time
	last_hit = G.time
	G.fx.impact(zone_point(zone), "blood")
	if incapacitated():
		if _kind != "bullet" or randf() < 0.6:
			die(src)
		return
	if retreating:
		amount *= 0.7
	hp -= amount
	suppression = minf(100.0, suppression + 18.0)
	sup_t = G.time
	add_stress(20.0)
	if hp <= 0.0:
		_down(src, _kind != "bullet")
	elif randf() < 0.2:
		say("VURULDUM!")

func on_blast(p: Vector3, r: float, dmg: float, d: float, src) -> void:
	if alive:
		add_stress(clampf(1.0 - d / (r * 2.6), 0.0, 1.0) * (35.0 + dmg * 0.15))
	var away := position - p
	away.y = 0
	var al := away.length()
	away = away / al if al > 0.01 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
	if not alive:
		# ceset bir kez savrulur; sonraki patlamalar (ikincil infilak, salvo) yalnızca hafifçe sarsar
		if d < r * 0.6 and not carried and rag != null and rag.pushes < 1 and G.time - died_at > 2.5:
			rag.pushes += 1
			rag.push(away * randf_range(0.8, 1.6) * (1.0 - d / r) + Vector3(0, randf_range(0.4, 0.9), 0))
			set_process(true)
			dead_t = 0.0
		return
	if state in ["hospital", "stretchered"]:
		return
	if d > r:
		if d < r * 1.8 and can_fight() and state != "fly":
			add_suppression(25.0, p)
			flinch_t = randf_range(0.35, 0.6)
		return
	var k := 1.0 - clampf(d / r, 0.0, 1.0)
	blast_k = k if dmg >= 50.0 else 0.0
	blast_t = G.time
	blast_p = p
	var blocked := not G.grid.los(p + Vector3(0, 0.4, 0), aim_point(), 0.2, 0.2)
	if blocked:
		blast_k = 0.0
	var dm := dmg * (0.3 + 0.7 * k)
	if blocked:
		dm *= 0.25
	if stance == PRONE or G.grid.in_trench(position):
		dm *= 0.55
	dm *= _vest_mult("blast")
	if incapacitated():
		die(src)
	else:
		hp -= dm
	if src != null and is_instance_valid(src):
		threat_pos = src.position
		threat_time = G.time
	if state == "para" and para_phase < 3:
		# kubbe altında savrulmaz ("fly" yere ışınlardı); hasar işlenir, düşerse süzülerek iner
		if hp <= 0.0 and alive:
			_down(src, true)
		return
	if not blocked and k > 0.2 and alive and state != "fly" and G.time - fly_end > 3.0:
		_release_patient()
		state = "fly"
		state_t = 0.0
		fly_vel = away * randf_range(3.0, 6.5) * (0.4 + k) + Vector3(0, randf_range(3.0, 6.0) * (0.5 + k * 0.6), 0)
		fly_spin = randf_range(6, 12) * (1.0 if randf() < 0.5 else -1.0)
		fly_ang = 0.0
		position.y = 0.05
		if hp <= 0.0 and randf() < 0.7:
			die(src, true)
		return
	if hp <= 0.0 and alive:
		_down(src, true)
	elif alive:
		add_suppression(40.0, p)

func _down(src, explosive := false) -> void:
	if not alive:
		return
	var p_die := 0.3 + 0.18 * downs + (0.3 if explosive else 0.0) + (0.45 if last_zone == "head" and not explosive else 0.0)
	if downs >= 2 or hp < -70.0 or randf() < p_die:
		die(src)
		return
	downs += 1
	hp = 1.0
	_release_patient()
	_injure(explosive)
	bleed = randf_range(38.0, 55.0)
	if state == "para" and para_phase < 3:
		# kubbe altında: durum burada değişirse asker havada kalır ya da yere ışınlanır;
		# yaralı süzülmeye devam eder, yere değince (_para_touchdown) yatar
		para_hurt = true
		say("VURULDUM!", 2.0)
		return
	_drop_canopy()
	state = "wounded"
	state_t = 0.0
	stance = PRONE
	target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	say(["SIHHİYE!", "SIHHİYE! VURULDUM!", "YARDIM EDİN!"][randi() % 3], 3.0)
	G.fx.blood_pool(position)

func _injure(explosive: bool) -> void:
	# patlamada uzuvlar, kurşunda gövde/kol daha olası
	var w: Dictionary = {"leg": 3.5, "arm": 2.5, "shoulder": 1.5, "head": 1.0, "torso": 1.5} if explosive else {"leg": 2.5, "arm": 2.0, "shoulder": 2.0, "head": 1.0, "torso": 2.5}
	var tot := 0.0
	for k in w:
		tot += w[k]
	var r := randf() * tot
	var pick := "torso"
	for k in w:
		r -= w[k]
		if r <= 0.0:
			pick = k
			break
	if not explosive and last_zone != "":
		# kurşun yarası isabet bölgesinde
		match last_zone:
			"head":
				pick = "head"
			"torso":
				pick = "torso" if randf() < 0.7 else "shoulder"
			"arm":
				pick = "arm" if randf() < 0.65 else "shoulder"
			"leg":
				pick = "leg"
	# daha ağır yara öncekini ezer (bacak/kol en kalıcı)
	if injury == "" or ["head", "torso", "shoulder", "arm", "leg"].find(pick) >= ["head", "torso", "shoulder", "arm", "leg"].find(injury):
		injury = pick
	injury_t = -1.0
	if randf() < 0.6:
		say(INJ_TXT[injury], 2.5)

# yaranın görsel tedavisi (sargı/alçı/askı) — sıhhiye ya da hastane
func _treat_injury() -> void:
	if body:
		body.set_injury(injury)

func injury_speed() -> float:
	match injury:
		"leg":
			return 1.55
		"shoulder":
			return 2.3
		"torso":
			return 2.9
	return 99.0

func injury_acc() -> float:
	match injury:
		"arm":
			return 0.55
		"shoulder":
			return 0.8
		"head":
			return 0.85
	return 1.0

# ağır silahı (makineli, roketatar, dürbünlü, havan) tek kolla kullanamaz: tabancaya geçer
func one_armed() -> bool:
	return injury == "arm" and role in ["mg", "at", "atgm", "sniper", "mortar"]

# yakın ağır patlamada ölen askerde uzuv kopar (iskelette kemik büzülür, uzuv parçası savrulur, kan)
var blast_k := 0.0
var blast_t := -10.0
var blast_p := Vector3.ZERO

func _sever() -> void:
	if body == null or body.spine == null:
		return
	var parts := ["fore_r", "fore_l", "knee_r", "knee_l"]
	parts.shuffle()
	var n := 1 if randf() < 0.7 else 2
	for i in n:
		var pn: String = parts[i]
		var piv: Node3D = body.get(pn)
		var at := piv.global_position
		var away := at - blast_p
		away.y = 0.0
		away = away.normalized() if away.length() > 0.01 else Vector3(randf_range(-1, 1), 0, randf_range(-1, 1)).normalized()
		body.sever(pn)
		G.fx.gib(at, piv.global_transform.basis, away * randf_range(3.0, 7.0) + Vector3(0, randf_range(3.0, 6.0), 0), team, pn.begins_with("knee"))
		G.fx.impact(at, "blood")
	G.fx.blood_pool(position, true)

func die(src, keep_fly := false) -> void:
	if not alive:
		return
	alive = false
	if G.time - blast_t < 0.1 and blast_k > 0.55 and randf() < 0.35 + blast_k * 0.5:
		_sever()
	_release_patient()
	if rescuer != null and is_instance_valid(rescuer):
		rescuer.patient = null
		if rescuer.state in ["drag", "heal", "rescue"]:
			rescuer.state = "idle"
	rescuer = null
	var rv := Vector3(randf_range(-0.6, 0.6), 0.4, randf_range(-0.6, 0.6))
	var spin := 0.0
	var airborne := state == "para" and para_phase < 3
	_drop_canopy()
	if state == "fly":
		rv = fly_vel
		spin = fly_spin * 0.3
	elif airborne:
		# kubbe altında ölen: beden süzülme hızıyla düşer (ragdoll zemine indirir)
		rv = para_vel
	elif src != null and is_instance_valid(src):
		var away: Vector3 = position - src.position
		away.y = 0
		if away.length() > 0.01:
			rv = away.normalized() * randf_range(1.2, 2.8) + Vector3(0, randf_range(0.4, 1.4), 0)
	state = "dead"
	keep_fly = keep_fly
	_leave_house()
	for f in G.friends_near(position, 10.0, team):
		if f is Soldier and f != self:
			f.add_stress(10.0)
	if role == "leader" and squad:
		for m in squad.members:
			if is_instance_valid(m) and m != self:
				m.add_stress(20.0)
	rag = Ragdoll.new()
	rag.start(body, rv, spin)
	set_process(true)
	dead_t = 0.0
	died_at = G.time
	target = null
	vel = Vector3.ZERO
	if escort_of != null:
		escort_of = null
	loot = mini(ammo, 90)
	lean = Vector3.ZERO
	G.credit_kill(src, self)
	if not airborne:
		G.fx.blood_pool(position)
	if selected and G.player:
		G.player.deselect(self)
	if squad:
		squad.on_death(self)
	G.main.register_body(self)

# ------------------------------------------------------------ yaralı / kurtarma
func _think_wounded() -> void:
	if rescuer != null and (not is_instance_valid(rescuer) or not rescuer.alive or rescuer.patient != self):
		rescuer = null
	if rescuer != null:
		path = PackedVector3Array()
		return
	if downs <= 1 and G.time - threat_time < 8.0 and path_i >= path.size() and randf() < 0.3:
		var c: Dictionary = G.grid.find_cover(position, threat_pos, 4.0, [], position)
		if c["type"] > 0 and c["pos"].distance_to(position) > 0.5:
			_set_path(c["pos"])
	if randf() < 0.06:
		say("SIHHİYE!", 2.0)

func start_rescue(p: Soldier) -> void:
	_release_patient()
	patient = p
	p.rescuer = self
	state = "rescue"
	state_t = 0.0
	build_site = null
	_set_path(p.position)
	say("GELİYORUM!" if randf() < 0.5 else "ÖRT BENİ!")
	# sis bombası ile gizle
	if smoke_nades > 0 and G.time - threat_time < 6.0 and randf() < 0.45:
		var dir := (threat_pos - p.position)
		dir.y = 0
		if dir.length() > 6.0:
			_start_throw(p.position + dir.normalized() * 4.0, true)

func _think_rescue() -> void:
	if patient == null or not is_instance_valid(patient) or not patient.alive or not patient.incapacitated():
		_release_patient()
		state = "idle"
		return
	var d := dist2(patient)
	if d > 1.2:
		if path_i >= path.size() or path.size() > 0 and path[path.size() - 1].distance_to(patient.position) > 1.5:
			_set_path(patient.position)
		return
	# ulaştı: açıkta mı?
	var exposed := G.time - threat_time < 7.0 and G.grid.cover_factor(patient.position, 0.6, threat_pos) < 0.5
	if exposed:
		var c: Dictionary = G.grid.find_cover(patient.position, threat_pos, 9.0, [], position)
		var dd: Vector3
		if c["type"] > 0:
			dd = c["pos"]
		else:
			var away := patient.position - threat_pos
			away.y = 0
			dd = G.grid.nearest_free(patient.position + away.normalized() * 7.0, Grid.M_INF)
		drag_dest = dd
		state = "drag"
		state_t = 0.0
		patient.state = "dragged"
		_set_path(drag_dest)
		# biri yanında geri geri yürüyüp ateş ederek örtsün
		var esc: Soldier = null
		var be := 20.0
		for fr in G.friends_near(position, 20.0, team):
			if fr is Soldier and fr != self and fr != patient and fr.can_fight() and fr.state == "idle" and fr.ammo > 20 and not fr.bearer and fr.order != "hold":
				var de: float = fr.dist2(self)
				if de < be:
					be = de
					esc = fr
		if esc != null:
			esc.start_escort(self)
		if randf() < 0.5:
			say("DAYAN!")
	else:
		_begin_heal()

func _begin_heal() -> void:
	state = "heal"
	heal_t = 4.0 if role == "medic" else 8.0
	if patient:
		patient.state = "healing"

func _process_drag_heal(dt: float) -> void:
	if state == "drag":
		if patient == null or not is_instance_valid(patient) or not patient.alive:
			_release_patient()
			state = "idle"
			return
		var mdir := vel
		mdir.y = 0
		if mdir.length() > 0.05:
			mdir = mdir.normalized()
			patient.position = position - mdir * 0.95
			patient.rotation.y = atan2(mdir.x, mdir.z)
		if path_i >= path.size() or state_t > 14.0:
			_begin_heal()
	elif state == "heal":
		if patient == null or not is_instance_valid(patient) or not patient.alive:
			_release_patient()
			state = "idle"
			return
		heal_t -= dt
		if heal_t <= 0.0:
			add_xp(5)
			patient.revive()
			patient = null
			state = "idle"
			dest = position

func revive() -> void:
	state = "idle"
	state_t = 0.0
	_treat_injury()
	max_hp = maxf(40.0, 100.0 - 25.0 * downs)
	hp = max_hp
	rescuer = null
	stance = CROUCH
	suppression = 40.0
	dest = position
	order = ""
	say("TEŞEKKÜRLER!" if randf() < 0.5 else "İYİYİM!")

func _release_patient() -> void:
	if patient != null and is_instance_valid(patient):
		if patient.rescuer == self:
			patient.rescuer = null
		if patient.alive and patient.state in ["dragged", "healing"]:
			patient.state = "wounded"
	patient = null

# yaklaşan araç için kenara çekil (yürüyerek; koşu hızını geçmez)
var yield_veh: Vehicle = null
var yield_until := 0.0
func give_way(v: Vehicle) -> void:
	if not can_fight() and state != "move":
		return
	yield_veh = v
	yield_until = G.time + 0.6

func _yield_step() -> Vector3:
	var v := yield_veh
	var d := position - v.position
	d.y = 0.0
	var side: float = d.dot(v.right())
	var lat: Vector3 = v.right() * (1.0 if side >= 0.0 else -1.0)
	# şerit dışındaysak kımıldama
	if absf(side) > v.ext.x + 0.9:
		return Vector3.ZERO
	var ok := lat
	if G.grid.height_at(position + lat * 1.2) >= 0.45 or G.grid.is_water(position + lat * 1.2):
		ok = -lat
	if stance == PRONE and stance_lock != PRONE:
		stance = CROUCH
	return ok * 2.6

# gelen roket / füze: görüyorsa roketin yolundan yana atılır
func on_rocket(from: Vector3, v: Vector3) -> void:
	if not can_fight() or state in ["throw", "drag", "heal", "dive", "aboard", "build", "setup"] or house_id >= 0 or flinch_t > 0.0:
		return
	if randf() > 0.45 or not sees(position + Vector3(0, eye_h(), 0), from, null):
		return
	var dir := v
	dir.y = 0.0
	dir = dir.normalized()
	var side := Vector3(-dir.z, 0, dir.x)
	if side.dot(position - from) < 0.0:
		side = -side
	state = "dive"
	state_t = 0.0
	fly_vel = side * 5.5
	stance = PRONE
	face_yaw = _yaw_of(side)
	popped = false
	if randf() < 0.4:
		say("ROKET!")

func on_drone(p: Vector3) -> void:
	if not can_fight() or state in ["throw", "drag", "heal", "dive", "aboard"]:
		return
	if randf() < 0.55:
		var away := position - p
		away.y = 0
		away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0)
		state = "dive"
		state_t = 0.0
		fly_vel = away * 5.0
		stance = PRONE
		face_yaw = _yaw_of(away)
		say("DRONE!")

func on_grenade(g_pos: Vector3, fuse_left: float, thrower: Unit) -> bool:
	# true: geri attı (bomba yok edilir)
	if not can_fight() or state in ["throw", "drag", "heal"]:
		return false
	var d := Vector2(g_pos.x - position.x, g_pos.z - position.z).length()
	if d < 1.7 and fuse_left > 1.3 and suppression < 60.0 and randf() < 0.12 and thrower != null and is_instance_valid(thrower):
		_start_throw(thrower.position, false)
		grenades += 1
		say("GERİ AL!")
		return true
	if randf() < 0.75:
		var away := position - g_pos
		away.y = 0
		away = away.normalized() if away.length() > 0.05 else Vector3(1, 0, 0)
		state = "dive"
		state_t = 0.0
		fly_vel = away * 5.5
		stance = PRONE
		face_yaw = _yaw_of(away)
		popped = false
		if randf() < 0.4:
			say("BOMBA!")
	return false

# elde / göğüste taşınan alet
func _tool_kind() -> String:
	if state in ["surrender", "prisoner"]:
		return "flag"
	if haul and order == "build" and state == "move":
		return "crate"
	if state == "build":
		if lift_t > 0.0:
			var k := lift_t / LIFT_T
			# yığından alırken yarıdan sonra elinde, iskeleye bırakırken yarıya kadar elinde
			return "crate" if ((not haul and k > 0.5) or (haul and k < 0.5)) else ""
		return "shovel" if _digging() else "hammer"
	if G.time < repair_vis_t and state == "idle":
		return "hammer"
	if state == "heal":
		return "bandage"
	if state == "launch" and state_t < 1.4:
		return "drone"
	return "rc" if _piloting() else ""

# siper hendeği / kum torbası: kürekle kazılır, torba doldurulur
func _digging() -> bool:
	return build_site != null and is_instance_valid(build_site) and build_site is Building and build_site.btype in ["trench", "sandbags"]

func _pose() -> String:
	if role == "mortar" and state == "idle":
		if mortar_setup > 0.0 and mortar_setup < 4.0:
			return "build"                            # havanı kuruyor
		if G.time - _mortar_fired < 0.8:
			return "cover"                            # atış: kulak kapatır, eğilir
		if mortar_prop != null and mortar_cd > 0.0 and mortar_cd < 1.4:
			return "drop"                             # sıradaki mermiyi namluya bırakır
		if mortar_cd > 2.5:
			return "crouch_aim"
	if flinch_t > 0.0 and state in ["idle", "move", "escort", "guard"]:
		return "flinch"
	if body_lift > 0.2 and state in ["move", "rescue", "escort", "prisoner", "stretcher"]:
		return "vault"
	match state:
		"slide":
			return "slide"
		"melee":
			return "melee"
		"prisoner":
			return "surrender"
		"stretcher":
			return "carry" if not _stretcher_back() else "dragging"
		"stretchered":
			return "healing"
		"escort":
			return "aim" if target != null else "stand"
		"guard":
			return "aim"                                # tüfek esire doğrultulmuş
		"dead":
			return "dead"
		"wounded":
			return "wounded"
		"healing":
			return "healing"
		"dragged":
			return "dragged"
		"fly":
			return "fly"
		"dazed":
			return "dazed"
		"dive":
			return "prone"
		"throw":
			return "throw"
		"drag":
			return "dragging"
		"heal":
			return "treat"
		"build":
			if lift_t > 0.0:
				return "lift"                               # eğilip kutuyu yığından alır / iskeleye bırakır
			if _digging():
				return "dig"
			return "build_hi" if build_slot >= 0 and build_slot % 3 == 1 else "build"
		"setup":
			return "build_hi" if fmod(state_t, 7.0) > 4.5 else "build"
		"launch":
			return "crouch" if state_t < 1.0 else "stand"
		"surrender":
			return "surrender"
	if haul and order == "build" and state == "move":
		return "carry"
	if blind_t > 0.0 and state == "idle":
		return "blind_side" if blind_side else "blind"
	if bandage_t > 0.0 and state == "idle":
		return "build"
	if G.time < repair_vis_t and state == "idle":
		return "build"
	var aiming := target != null and is_instance_valid(target) and (popped or burst_left > 0) and can_fight()
	match stance:
		STAND:
			return "aim" if aiming and vel.length() < 2.5 else "stand"
		CROUCH:
			return "crouch_aim" if aiming else "crouch"
	return "prone_aim" if aiming else ("crawl" if vel.length() > 0.1 else "prone")

func _physics_process(dt: float) -> void:
	if alive and (state == "drag" or state == "heal"):
		_process_drag_heal(dt)
	if alive and state == "build" and build_site != null and is_instance_valid(build_site):
		var mult := 1.6 if role == "engineer" else (0.7 if role == "medic" else 1.0)
		if build_site is Building and not build_site.is_line() and build_slot >= 0:
			# kalabalık ekipte verim azalır (√n): 6 kişi tek kişinin ~2.4 katı
			mult /= sqrt(float(maxi(1, build_site.active_workers())))
			var sp: Vector3 = build_site.slot_pos(build_slot)
			if build_slot % 3 == 2:
				# malzeme taşıyıcı: yığından kutu/kalas al, iskeleye götür
				var tgt: Vector3 = sp if haul else build_site.pile_reach()
				if Vector2(tgt.x - position.x, tgt.z - position.z).length() > (2.6 if not haul else 1.6):
					build_goal = tgt
					_set_path(tgt)
					state = "move"
					lift_t = 0.0
					return
				if lift_t < LIFT_T:
					lift_t += dt                            # eğil, kutuyu kavra / yere koy
					return
				lift_t = 0.0
				if haul:
					build_site.add_work(2.4 * mult)
				haul = not haul
				build_goal = build_site.pile_reach() if not haul else sp
				_set_path(build_goal)
				state = "move"
				return
			if Vector2(sp.x - position.x, sp.z - position.z).length() > 1.2:
				build_goal = sp
				_set_path(sp)
				state = "move"
				return
			build_site.add_work(dt * mult)
		elif dist2(build_site) < build_site.radius + 2.5:
			build_site.add_work(dt * mult)
		else:
			_set_path(build_site.position + (position - build_site.position).normalized() * (build_site.radius + 0.8))
			state = "move"

# ------------------------------------------------------------ ragdoll sonrası
func _settle_body() -> void:
	if rag == null:
		return
	var c := rag.center()
	# havada ölen (paraşüt, halat, savrulma): düğüm de cesedin yattığı zemine iner
	var gy := G.terrain.ground_h(c) if G.terrain else 0.0
	position = Vector3(c.x, gy if position.y > gy + 0.5 else position.y, c.z)
	rag._apply()

# ------------------------------------------------------------ yaralıyken tabanca
func _pistol() -> void:
	if pistol_cd > 0.0 or G.time - threat_time > 10.0:
		return
	pistol_cd = randf_range(0.55, 1.2)
	var best: Unit = null
	var bd := 22.0
	var eye := position + Vector3(0, 0.45, 0)
	for e in G.enemies_near(position, 22.0, team):
		if not (e is Soldier) or not e.can_fight() or not G.is_seen(e, team):
			continue
		var d := dist2(e)
		if d < bd and sees(eye, e.aim_point(), e):
			bd = d
			best = e
	if best == null:
		return
	pistol_t = G.time
	var mp := body.fore_r.global_transform * Vector3(0, -SoldierBody.HAND_LEN - 0.14, -0.02)
	var tp := best.aim_point()
	G.fx.muzzle(mp, (tp - mp).normalized(), false)
	Sfx.play3d("pistol", mp, -5.0, 0.1, 0.02)
	shots += 1
	var c := 0.2 * (1.0 - G.grid.cover_factor(best.position, best.torso_h(), position) * 0.8)
	if randf() < c:
		best.take_damage(randf_range(10.0, 18.0), self, "bullet")
	else:
		best.add_suppression(5.0, position)
		G.fx.impact(Vector3(tp.x + randf_range(-1, 1), 0.02, tp.z + randf_range(-1, 1)), "dirt")
	if shots % 2 == 0:
		G.fx.tracer_cal(mp, tp, 220.0, Ammo.team_tracer(team), 5.0)

# ------------------------------------------------------------ yakın dövüş
func _think_melee() -> bool:
	if melee_cd > 0.0 or bearer or state in ["throw", "drag", "heal", "melee"]:
		return false
	for e in G.enemies_near(position, 1.8, team):
		if e is Soldier and e.can_fight() and e.hostile():
			state = "melee"
			state_t = 0.0
			melee_hit = false
			melee_target = e
			path = PackedVector3Array()
			_face_to(e.position, true)
			if randf() < 0.4:
				say("ÇEKİL!")
			return true
	return false

# ------------------------------------------------------------ teslim olma / esir
func _think_surrender() -> bool:
	if G.time < surrender_chk or bearer:
		return false
	surrender_chk = G.time + 1.0
	if suppression < 80.0 or (hp > 55.0 and ammo > 0):
		return false
	if squad:
		for m in squad.alive_members():
			if m != self and m.can_fight():
				return false
	var near_enemy := false
	for e in G.enemies_near(position, 16.0, team):
		if e is Soldier and e.can_fight() and G.is_seen(e, team):
			near_enemy = true
			break
	if not near_enemy:
		return false
	var b := nearest_base()
	if b != null and dist2(b) < 45.0:
		return false
	# nadir: yalnız, yaralı/mermisiz ve paniğe kapılmış askerde düşük olasılık
	if stress_lv < 2 or randf() > 0.025:
		return false
	surrender()
	return true

func surrender() -> void:
	_release_patient()
	state = "surrender"
	state_t = 0.0
	order = ""
	target = null
	forced_target = null
	path = PackedVector3Array()
	vel = Vector3.ZERO
	cover_type = 0
	popped = false
	stance = STAND
	body.weapon.visible = false
	G.fx.impact(position + Vector3(0.5, 0.05, 0.3), "dirt")
	say(["TESLİM OLUYORUM!", "ATMA!"][randi() % 2], 3.0)
	if selected and G.player:
		G.player.deselect(self)

func _think_surrender_wait() -> void:
	var best: Soldier = null
	var bd := 9.0
	for e in G.enemies_near(position, 9.0, team):
		if e is Soldier and e.can_fight():
			var d := dist2(e)
			if d < bd:
				bd = d
				best = e
	if best != null:
		captor = best.team
		best.say("ELLER YUKARI!")
		best.add_xp(10)
		state = "prisoner"
		state_t = 0.0
		# esir alan asker (meşgul değilse) esiri silah doğrultarak karargâha götürür
		if best.state in ["idle", "move"] and best.order != "hold" and best.vehicle_in == null and best.guard_of == null:
			best.start_guard(self)
		intel_t = G.time + 3.0
		var dst := _captor_base()
		if dst != null:
			_set_path(dst.position + (position - dst.position).normalized() * (dst.radius + 2.0))
		if captor == G.player_team or team == G.player_team:
			G.say(I18n.s("Esir alındı: %s") % sname, position, G.player_team)
		return
	# kurtarıldı mı (yanına dost geldi)
	if state_t > 4.0:
		for f in G.friends_near(position, 5.0, team):
			if f is Soldier and f != self and f.can_fight():
				_unsurrender()
				return
	if state_t > 60.0:
		_unsurrender()

func _unsurrender() -> void:
	state = "idle"
	captor = -1
	body.weapon.visible = true
	suppression = 30.0
	say("TEŞEKKÜRLER!")

func _captor_base() -> Building:
	var best: Building = null
	var bd := 1e9
	for u in G.units:
		if is_instance_valid(u) and u is Building and u.team == captor and u.alive and u.done and u.is_base():
			var d := dist2(u)
			if d < bd:
				bd = d
				best = u
	return best

func _think_prisoner() -> void:
	# esir: elleri başında düşman üssüne yürür, yolda istihbarat verir
	if captor < 0:
		_unsurrender()
		return
	var b := _captor_base()
	if b == null:
		_unsurrender()
		return
	if path_i >= path.size() or randf() < 0.05:
		_set_path(b.position + (position - b.position).normalized() * (b.radius + 1.5))
	if G.time > intel_t and intel_n < 3:
		intel_t = G.time + randf_range(7.0, 11.0)
		intel_n += 1
		_give_intel()
	if dist2(b) < b.radius + 3.5:
		G.stats["pows"][captor] += 1
		if intel_n < 3:
			_give_intel()
		vanish()
		return
	# kendi askerleri yaklaşırsa ve esir alan taraf yakında değilse kurtulur
	var friends := 0
	for f in G.friends_near(position, 4.0, team):
		if f is Soldier and f != self and f.can_fight():
			friends += 1
	if friends > 0:
		var guards := false
		for e in G.enemies_near(position, 10.0, team):
			if e is Soldier and e.can_fight():
				guards = true
				break
		if not guards:
			_unsurrender()

func _give_intel() -> void:
	if captor != G.player_team or G.spectate:
		return
	var facts: Array = []
	var bases: Array = []
	var veh := {}
	for u in G.units:
		if not is_instance_valid(u) or not u.alive or u.team != team:
			continue
		if u is Building and u.done:
			bases.append(u)
		elif u is Vehicle and not (u.vtype in ["truck", "fpv"]):
			veh[u.vtype] = int(veh.get(u.vtype, 0)) + 1
	if not bases.is_empty():
		var bb: Building = bases[randi() % bases.size()]
		facts.append([I18n.s("%s orada, %s yönünde.") % [I18n.s(bb.title), I18n.s(_dir_name(bb.position - position))], bb.position, true])
	if not veh.is_empty():
		var parts: Array = []
		for k in veh:
			parts.append("%d %s" % [veh[k], I18n.s(Vehicle.DEF[k]["title"])])
		facts.append([I18n.s("Elimizde %s var.") % ", ".join(parts), Vector3.ZERO, false])
	for a in G.ais:
		if is_instance_valid(a) and a.team == team and a.target_pos != Vector3.INF:
			facts.append([I18n.s("Bir saldırı hazırlanıyor, hedef %s yönünde.") % I18n.s(_dir_name(a.target_pos - position)), a.target_pos, false])
	facts.append([I18n.s("İkmalimiz %d civarında.") % (int(G.supply[team] / 50.0) * 50), Vector3.ZERO, false])
	var f: Array = facts[randi() % facts.size()]
	if f[2]:
		G.reveal[captor] = G.time + 30.0
	if G.hud:
		G.hud.intel(sname, f[0], f[1])

static func _dir_name(d: Vector3) -> String:
	# ekran yönüne göre (harita ile aynı yönelim)
	var sx := d.x - d.z
	var sy := d.x + d.z
	var a := fposmod(atan2(sy, sx) + PI * 0.5, TAU)
	var names := ["kuzey", "kuzeydoğu", "doğu", "güneydoğu", "güney", "güneybatı", "batı", "kuzeybatı"]
	return names[int(round(a / (TAU / 8.0))) % 8]

func vanish() -> void:
	alive = false
	visible = false
	_release_patient()
	if selected and G.player:
		G.player.deselect(self)
	queue_free()

# ------------------------------------------------------------ yaralıyı sürükleyeni örtme
func start_escort(dragger: Soldier) -> void:
	escort_of = dragger
	state = "escort"
	state_t = 0.0
	path = PackedVector3Array()
	build_site = null
	say("ÖRTME ATEŞİ!")

func start_guard(p: Soldier) -> void:
	guard_of = p
	p.guard_by = self
	state = "guard"
	state_t = 0.0
	order = ""
	target = null
	path = PackedVector3Array()

func _think_guard() -> void:
	# esir teslim edildi / kaçtı / öldü: muhafız timine döner
	if guard_of == null or not is_instance_valid(guard_of) or not guard_of.alive or guard_of.state != "prisoner" or state_t > 240.0:
		if guard_of != null and is_instance_valid(guard_of):
			guard_of.guard_by = null
		guard_of = null
		state = "idle"
		if squad != null:
			var ab: Array = squad.able().filter(func(x): return x != self)
			if not ab.is_empty():
				cmd_move(G.grid.nearest_free(ab[0].position + Vector3(randf_range(-3, 3), 0, randf_range(-3, 3)), Grid.M_INF))
		return
	# yakın tehdit: esiri bırakmadan karşılık verir
	_scan()

# muhafız esirin 2,5 m arkasında, hafif yanında yürür
func _guard_move() -> Vector3:
	if guard_of == null or not is_instance_valid(guard_of):
		return Vector3.ZERO
	var mv := guard_of.vel
	mv.y = 0
	var back := (position - guard_of.position)
	back.y = 0
	back = back.normalized() if back.length() > 0.1 else Vector3(0, 0, 1)
	if mv.length() > 0.2:
		back = -mv.normalized()
	var side := Vector3(-back.z, 0, back.x) * 0.7
	var want_p := guard_of.position + back * 2.5 + side
	var d := want_p - position
	d.y = 0
	var L := d.length()
	if L < 0.35:
		return Vector3.ZERO
	return d / L * minf(L * 1.6, 2.4)

func _think_escort() -> void:
	_scan()
	if escort_of == null or not is_instance_valid(escort_of) or not escort_of.alive or escort_of.state != "drag" or state_t > 18.0:
		escort_of = null
		state = "idle"
		covering_until = G.time + 3.0

func _escort_move() -> Vector3:
	if escort_of == null or not is_instance_valid(escort_of):
		return Vector3.ZERO
	var mv := escort_of.vel
	mv.y = 0
	var want_p := escort_of.position + Vector3(1.5, 0, 0)
	if mv.length() > 0.1:
		var side := Vector3(-mv.z, 0, mv.x).normalized()
		want_p = escort_of.position + side * 1.5 - mv.normalized() * 0.6
	var d := want_p - position
	d.y = 0
	var L := d.length()
	if L < 0.3:
		return Vector3.ZERO
	return d / L * minf(L * 2.0, 2.6)

# ------------------------------------------------------------ sedyeciler
var job = null

func _stretcher_move() -> Vector3:
	if job == null:
		state = "idle"
		return Vector3.ZERO
	return job.want_for(self)

func _stretcher_back() -> bool:
	return job != null and job.alone()

# ------------------------------------------------------------ mermi
func _think_ammo() -> void:
	if ammo > 0 or mag > 0 or order in ["hold", "resupply", "loot"] or role == "mortar" or bearer:
		return
	for u in G.near(position, 14.0):
		if u is Soldier and not u.alive and u.loot > 0 and not u.carried:
			order = "loot"
			_set_path(u.position)
			state = "move"
			return
	var b := nearest_base()
	if b != null and dist2(b) < 170.0:
		say("MERMİ BİTTİ!")
		var p := b.position + (position - b.position).normalized() * (b.radius + 3.0)
		cmd_move(G.grid.nearest_free(p, Grid.M_INF))
		order = "resupply"

# ------------------------------------------------------------ hastane
# yürüyebilen yaralı kendisi hastaneye gider (kapıya varınca yatırılır)
func cmd_hospital(b: Building) -> void:
	if not alive or not can_fight():
		return
	hosp_b = b
	order = "hospital"
	_set_path(G.grid.nearest_free(b.door_pos(), Grid.M_INF))
	state = "move"
	say("TEDAVİYE GİDİYORUM", 2.5)

func enter_hospital(b: Building) -> void:
	hosp_b = b
	carried = false
	state = "hospital"
	visible = false
	target = null
	path = PackedVector3Array()
	position = b.position
	rescuer = null

func leave_hospital(door: Vector3) -> void:
	if not alive:
		resurrect()
	state = "idle"
	visible = true
	position = G.grid.nearest_free(door, Grid.M_INF)
	max_hp = maxf(40.0, 100.0 - 25.0 * downs)
	hp = max_hp * 0.8
	bleed = 0.0
	suppression = 0.0
	stance = STAND
	limp_t = 16.0
	body.dead_pose = {}
	# hastanede tedavi: alçı/bandaj kalır, etkiler bir süre sonra geçer (kafa bandajı kalıcı görünür)
	if injury != "":
		injury_t = {"arm": 90.0, "leg": 45.0, "shoulder": 45.0, "torso": 30.0, "head": 20.0}.get(injury, 30.0)
		_treat_injury()
	body.weapon.visible = true
	hosp_b = null
	var b := nearest_base()
	if b != null:
		cmd_move(G.grid.nearest_free(b.position + Vector3(randf_range(-4, 4), 0, b.radius + 3.0), Grid.M_INF))
	say("İYİYİM!" if randf() < 0.5 else "TEŞEKKÜRLER!")

func resurrect() -> void:
	alive = true
	if rag != null:
		body.reset_rig()
	rag = null
	carried = false
	downs = mini(downs + 1, 2)
	loot = 0
	set_process(true)
	if G.main:
		G.main.bodies.erase(self)
	G.stats["lost"][team] = maxi(0, G.stats["lost"][team] - 1)
	var W := weapon()
	ammo = W["ammo"]
	mag = W["mag"]
