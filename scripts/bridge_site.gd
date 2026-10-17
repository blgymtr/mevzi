class_name BridgeSite extends Node3D
# İstihkâm köprü kurma işçiliği (kullanıcı, 17 Ekim: "araç sürücüsü dışında 3 asker inecek, gerçekte nasılsa öyle
# kuracaklar"). Panel (Bailey) köprüde gerçek akış: araç köprü başının gerisinde durur, ekip panelleri araçtan
# köprü başına taşır, kıyıda birleştirip pimler, köprü boşluğun üzerine itilerek uzatılır. Burada üç istihkâmcı:
#  slot 0 — köprü başı solu, diz çökmüş birleştirme / pimleme ("build")
#  slot 1 — köprü başı sağı, ayakta çakma ("build_hi")
#  slot 2 — taşıyıcı: aracın arkasından paneli alır, köprü başına götürür ("lift" / "carry")
# Soldier'ın yapı inşaatı davranışını (build_site arayüzü) kullanır; işçilik köprü ilerlemesini sürer — ekip yoksa
# ya da vurulduysa köprü ilerlemez.

var veh: Node3D = null      # istihkâm aracı
var head := Vector3.ZERO    # köprü başı (boşluğun bu ucu)
var dirv := Vector3.FORWARD # köprü başından boşluğa doğru
var done := false
var alive := true
var radius := 2.0
var work := 0.0
var _slots: Array = [null, null, null]

func is_line() -> bool:
	return false

func claim_slot(s) -> int:
	for i in 3:
		if _slots[i] == null or not is_instance_valid(_slots[i]) or not _slots[i].alive:
			_slots[i] = s
			return i
	return 2

func active_workers() -> int:
	var n := 0
	for s in _slots:
		if s != null and is_instance_valid(s) and s.alive and s.state in ["build", "move"] and s.build_site == self:
			n += 1
	return maxi(1, n)

func slot_pos(i: int) -> Vector3:
	var side := Vector3(-dirv.z, 0, dirv.x)
	var p: Vector3
	match i % 3:
		0:
			p = head + side * 1.5 - dirv * 0.5
		1:
			p = head - side * 1.5 - dirv * 0.5
		_:
			p = head - dirv * 1.4
	return G.grid.nearest_free(p, Grid.M_INF, 6)

# panel yığını: aracın arkası
func pile_reach() -> Vector3:
	if veh == null or not is_instance_valid(veh):
		return head - dirv * 6.0
	return G.grid.nearest_free(veh.position - veh.forward() * (veh.ext.y + 1.0), Grid.M_INF, 6)

func add_work(w: float) -> void:
	work += w

# sahada çalışan (yaralı / ölü olmayan) istihkâmcı sayısı
func crew_alive() -> int:
	var n := 0
	for s in _slots:
		if s != null and is_instance_valid(s) and s.alive and not s.incapacitated():
			n += 1
	return n
