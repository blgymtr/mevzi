# Devir notu — bulut oturumundan yerel (GPU) oturuma (15 Ekim 2026)

Bu dosya, bulut oturumunda yarım kalan her şeyi ve yerel oturumun ilk adımlarını listeler.
Plan ve yapılanların tamamı: **ROADMAP.md** (en üstte değişiklik günlüğü, ardından 0.0.8 — 32 madde).
Dal: `claude/fervent-euler-a8emja` (PR: https://github.com/blgymtr/mevzi/pull/1).

## 0. Neden yerele geçtik
Bulutta GPU yok: Godot uyumluluk render'ı yazılımla (llvmpipe) 1–5 FPS çalışıyor, görsel testler saatler sürüyor
ve görüntü oyunun gerçek (Forward+) görünümünü yansıtmıyor. Ölçüm (crewtest teşhisi): kare başına ~1,1 M ilkel
çiziliyor (arazi ~400 K, ağaç/ot/kaya ~420 K), güneş gölgesi geçişi kare süresinin %40–55'i. → İleride LOD /
impostor / gölge mesafesi optimizasyonu gerekecek (300+ birimde 60 FPS hedefi, ROADMAP H).

## 1. Kurulum (bir kere)
- Godot 4.7 (Windows). Yol örneği: `C:\Godot\godot.exe`
- Python 3 + `pip install numpy pillow` (efekt/kaya doku üreticileri: `tools/fx_sim.py`, `tools/rock_tex.py`)
- Blender betikleri (`tools/blender/*.py`, `tools/anim/build_anims.py`) `import bpy` ile yazıldı:
  - ya `pip install bpy` (bpy'nin istediği Python sürümüyle, şu an 3.13), `python tools/blender/xxx.py`
  - ya da Blender uygulamasıyla: `blender -b --python tools/blender/xxx.py -- <argümanlar>`
  - GPU'lu makinede Cycles önizlemeleri için Blender Tercihler → Sistem → CUDA/OptiX seçilebilir
- Node.js (yalnız ağaç üreticisi `tools/trees/gen_trees.mjs` için, `npm install` o klasörde)

## 2. Testleri GPU ile çalıştırma
```
.\tools\run_tests.ps1 -Godot "C:\Godot\godot.exe"                         # tüm sahneler
.\tools\run_tests.ps1 -Godot "C:\Godot\godot.exe" -Scenes crewtest,paratest -Timeout 300
```
Ekran görüntüleri `shots\<sahne>\`, günlükler `shots\logs\` (git dışı). Her sahne süre sınırlı; takılırsa
TIMEOUT yazar ve süreç öldürülür. Tek sahne elle: `godot.exe --path . -- --shot=shots\x --scene=crewtest`

## 3. Faz 0 — takılma önleme (yarım; ilk iş bu)
Teşhisler bitti, düzeltme yamaları `wip/faz0/` altında. **Henüz dala uygulanmadı ve GPU'da doğrulanmadı.**

| Yama | Kök neden | İçerik |
|---|---|---|
| `crew_fix.patch` (vehicle.gd, i18n.gd, tests07.gd) | crewtest: M119 doğrudan atışlı sahra topu (görüş 40 m, menzil 64 m). Test tankı 45 m'ye koymuş → savaş sisi tankı gizliyor (`G.reveal` yalnız binalara uygulanıyor), `_scan` görülmeyen düşmanı atlıyor, top hiç hedef almıyor. **Oyunda da hata:** kara aracına verilen saldırı emrinde hedef menzil içinde ama görüş dışındaysa araç sessizce sonsuza dek bekliyor | Doğrudan atışlı araç (çekili top dahil) piyade gibi hedefe yaklaşır; dolaylı atışlı topçu yaklaşmaz, gözcü gerektiğini söyler. Test: tank görüş içine, döngü oyun süresiyle sınırlı, 15 sn'de atış yoksa nedenini yazar |
| `para_fix.patch` (grid.gd, paradrop.gd, soldier.gd, tests07.gd, main.gd) | paratest 7/8: atlama aralığı kare süresine bağlıydı → yavaş karelerde atlama sırası hedefin çok ötesine (düşman mevzisine) uzuyor; altı dolu hücreye (bina/su/ağaç) iniş | Sabit aralıklı çıkış noktaları (kare süresinden bağımsız), son 12 m'de boş hücreye yönelme, `PARA_MAX_T` zorunlu iniş, havada vurulan yaralı süzülür; `Grid.free_at`; yeni `para2test` |
| `hang_watchdog_fix.patch` (main.gd, tests07.gd, soldier.gd, vehicle.gd) | SPIES/evadetest: test döngüleri kare sayısıyla sınırlı, kilitlenmede sessiz bekleme | Ayrı iş parçacığında test bekçisi (toplam duvar saati bütçesi + tek karede kilitlenme algılama, son "PHASE" günlükte), `test_phase()` işaretleri, ekran görüntüsü dışında çizimi kapatma (hız) |

Uygulama sırası: `git apply wip/faz0/crew_fix.patch` → `git apply wip/faz0/hang_watchdog_fix.patch` →
`git apply wip/faz0/para_fix.patch` (**main.gd çakışır**: yalnız sahne listesine `"para2test"` eklemek; elle
düzelt ya da `git apply --reject` ve `.rej`'i elle uygula). Sonra crewtest, paratest, para2test, ropetest,
evadetest çalıştır; hepsi RESULT ile bitmeli.

Faz 0'ın yapılmamış kısımları:
1. **Takılma taraması (yapılmadı):** soldier.gd / vehicle.gd / squad.gd / paradrop.gd / drone_station.gd /
   building.gd içindeki her geçici durum ("entering", "exiting", "rope", "rope_up", "para", hastaneye yürüyüş,
   gitmiş/ölmüş araca binme bekleyişi, inşaat yuvası, drone kalkışı, helikopterin yolcu beklemesi, boşaltma,
   askı yükü, ilerlemeyen path_i, aracı silinmiş yolcular) için azami süre + güvenli çıkış (eylemi tamamla /
   iptal / `G.grid.nearest_free`'ye yerleştir). Merkezî tablo: Soldier `_process`'te `{durum: azami_sn}` +
   `state_t`; Vehicle'da halat/iniş/boşaltma/biniş beklemeleri. Zorla çözümde bir kez `STUCK-RESOLVE <sınıf> <durum> <sn>`.
   Meşru uzun eylemleri bozmamalı (inşaat, tedavi, topçu dolum, drone istasyonu 16 sn, paraşüt uçuşu, 4 km yürüyüş).
2. **Sessiz emir hataları:** oyuncunun açık emri yapılamıyorsa (asgari menzil altı, görülmüyor, mürettebat
   yok, taret açısı dışı) birim `say()` ile kısa Türkçe ses satırı + i18n İngilizcesi (birkaç saniyede bir),
   asgari menzilde geri çekil ya da emri temizle.
3. **Ekransız test modu:** `--headless` ile `_shot` atlanmalı ("SHOT x skipped(headless)") → mantık testleri
   çizimsiz saniyeler içinde koşar. GPU'da gerekmese de CI için faydalı.

## 4. Yarım işler — git bundle olarak `wip/bundles/`
Her biri ayrı bir dalda; birleştirmeden önce incele ve test et.
```
git fetch wip/bundles/ana_menu.bundle HEAD:wip/ana-menu
git log --oneline claude/fervent-euler-a8emja..wip/ana-menu
git merge wip/ana-menu
```

| Bundle | Taban | Durum | Bilinen |
|---|---|---|---|
| `ana_menu.bundle` | 1949722 | Madde 32: Senaryo Oluşturucu, Kampanya ("Hazırlanıyor" listesi), Klasik Harita, Sandbox Test, Ayarlar (Grafik/Ses/Oynanış/Klavye Ayarları), Masaüstüne Çık; `scripts/main_menu.gd`, `scripts/keybinds.gd` (tuş atama, `user://keybinds.cfg`), hud.gd/player.gd değişti | Tuş atama birim testi (`tools/keybinds_test.tscn`) çalışırken durduruldu; bağımsız inceleme yapılmadı. Menü ön izleme: `godot --path . res://tools/menu_preview.tscn` |
| `yapi_modelleri.bundle` | caee749 | Faction yapıları Blender modelleri (`tools/blender/structures.py` → `struct_{hq,barracks,factory,helipad,hospital,fob}_{usa,rus}.glb`), building.gd'de model yükleme | buildtest yeniden çalışırken durdu; doğrulanmadı. main.gd/building.gd çakışabilir |
| `binalar_100plus.bundle` | 4738e5a (eski) | Madde 16: `scripts/arch.gd` bina arketipleri, mapgen/blocks/mats, masonry/roof shader | Yarım (son iş: pergola, kapı evi). Eski tabanda → mapgen.gd ve main.gd'de çakışma bekle |
| `arac_detay.bundle` | caee749 | Madde 10: `tools/blender/veh/vlib.py` hızlı bmesh çekirdeği + AO pişirme, aile betikleri | Yarım: **GLB'ler yeniden üretilmedi**; betiği çalıştırıp tüm katalogu üretmek gerek |

## 5. Dala eklenen, GPU'da görsel kontrol bekleyenler
- **Animasyon hattı** (madde 1/17/19/25 temeli): `tools/anim/build_anims.py` → `assets/anim/soldier_anim.glb`
  (22 klip: idle, walk, run, sprint, walk_back, strafe, crouch_walk, crawl, prone_idle, kneel, jump,
  hit_stagger, duck, fall_back, getup, turn + tüfek üst gövde katmanı). Kaynaklar MakeHuman CC0 + CMU mocap
  (ticari kullanım serbest) — `assets/anim/CREDITS.txt`. Ön izleme: `godot --path . res://tools/anim_preview.tscn -- --out=<klasör>`.
  Oyuna henüz bağlı değil; bağlama planı ve eksik askeri hareketler: `docs/ANIM_PIPELINE.md` §7–8.
- Kaya modelleri/shader'ı, ulus silahları, iş parçacıklı yol bulma (ROADMAP günlüğünde).

## 6. Sonraki fazlar
ROADMAP.md → "0.0.8 — Uygulama sırası (fazlar)". Faz 0 bitince Faz 1 (veri gerçekçiliği: araç hızları,
mühimmat tablosu, dost ateşi kuralı, roket önleme, füze türleri).

## 7. Çalışma kuralları (öğrenilenler)
- Her test döngüsü oyun süresiyle sınırlı olmalı ve ilerleme yazmalı; kare sayısıyla sınırlı döngü yazılım/yavaş çizimde saatler sürer.
- Yeni `class_name` eklendiyse önce `godot --headless --path . --import`.
- Aynı klasörde iki Godot'u aynı anda test için çalıştırma (içe aktarma önbelleği çakışır).
- Commit mesajları Türkçe; ROADMAP günlüğüne her iş "Eklendi/Düzeltildi" olarak eklenir.
