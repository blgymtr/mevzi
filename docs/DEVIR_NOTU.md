# Devir notu — kaldığımız yer (17 Ekim 2026, öğleden önce)

## Son yapılanlar
- 136 kamera, 139 nehir kraterine su, 140 suda takılan asker, 141 çekili top mürettebatı (commit `33e1dad`)
- 65/57 HUD eskiz teması, ilk geçiş: `scripts/sketch.gd` (class_name Sketch: kâğıt dokusu, mürekkep çerçeve, düğme
  durumları, `Sketch.sc()` Türkçe cümle düzeni), `shaders/sketch_thumb.gdshader` (küçük resim → mürekkep çizim),
  mini harita gerçek kuşbakışı görüntü (`Hud.Radar._capture`, sis dörtgeni `FogOfWar.FOW_LAYER` katmanında) + saha
  ızgarası; test: `hudshots` (görüntüler shots/hudshots)
- Not: yeni `class_name` eklenince testler bir kez `-NoImport` OLMADAN koşulmalı (sınıf önbelleği)

## Sıradaki
1. HUD kalanı: ana menü / ayarlar / düzenleyici aynı temaya (hâlâ eski Hud.TXT / AMBER sabitleri), dünya üstü
   etiketler (Overlay), tim görünümünde boş alan; kullanıcı görüşüne göre ince ayar
2. Modelleme aşaması (aşağıdaki listeye ek: 142 hurda modelleri, 143 bina çökmesi, 144 gerçekçi su, 145 zemin dokusu —
   kullanıcının masaüstündeki `1.png` / `2.png` esin görselleri, kopyalanmaz)
3. İnceleme dersleri (146–153): başka oyunun olumsuz incelemesinden; HUD / yapay zekâ / denge işinde bu listeye bak

---

# (Tarihsel) Devir notu — 17 Ekim 2026, 3. oturumun devamı

## Bu bölümde yapılan (commit'li, push'lu; son commit `eee8bbb`)
- 103, 107 (araç zekâsı: cephe, sis, geri çekilme, tanksavarcı önceliği, **gövde gizleme**), 110 savaş sisi, 112 sürücü /
  komutan vurulması, 114, 115 suda bomba + duman, 116 keskin nişancı aralığı, 118, 119, 125 sandbox araçları
- 128 kratere oturma / devrilme (araç, hurda, sandık, varil, ağaç) · 129 / 61 / 92 güverte ve komutan yüksekliği modelden,
  kapalı kabin yolcusu içeride · 130 sıkışan araç: sabit taraf, tek dolaşma, geri manevra, köprüde bekleme · 131 dumanın
  içinden geçen birlik dumanı yarar · 132 eş eksenli makineli yalnız taret yönüne · 133 köprüde gövde döşemede, karşılaşmada
  yol verme · 134 dozer / M88 hurdayı iter / halatla çeker · 137 çekili top toplanırken cephane kalkar, tekerler döner ·
  138 mühimmata göre krater
- 83 geri çekilirken arkaya ateş yok · 84 tank dibinde kalabalık (varış yarıçapı, 0,42 m katı aralık; ev içinde değil) ·
  89 siper derinliğine göre duruş · 102 halat (kola ve yere sabit, vinçle çekilir) + rampadan sıra hâlinde biniş
- 120: canlı bombayı kapıp geri atma, ikmal hattı kesilen ileri üs kararır, girilemeyen bina garnizona kapalı
- Yeni test sahneleri: cratertest, decktest, jamtest, aimtest, smokepasstest, dozertest, towtest, cratertypes,
  backfiretest, crowdtest, trenchpose, ramptest, hulldowntest, nadetest, fobdark (+ drivertest, watertest, vehaitest,
  snipertest, sandboxtest)
- Kullanıcının yeni maddeleri ROADMAP 122–138

## Sıradaki adımlar
1. HUD (65/57) + tüm emirlerin HUD ile bütünleşmesi; 136 kamera (360° döndürme, birime kilitlenme, serbest bakış)
2. Modelleme / animasyon aşaması (CC0: Poly Haven, ambientCG): 60 / 66 / 74 / 80 / 85 asker pozları, 100 araç–asker
   uyumu (rampa, kapak düğümleri), 101 / 111 topçu mermi animasyonları, 113, 122–124, 126, 127, 135 köprü kurma, 76 rampa +
   ZPT yükleme, uçak modelleri (hava indirme)
3. 120 kalanı: CPR (animasyon), engel yüksekliğine göre duruşun tüm siper türlerinde tutarlılığı; 107 kalanı: ilerlerken
   piyadeyle uyum
4. Kararsız testler: garrisontest rastgele haritada nadiren (≈1/7) bir asker kapıda takılır; vehtest istihkâmcı onarımı
   (30 sn bekleme ile seyrek)

---

# (Tarihsel) Devir notu — 16 Ekim 2026, 3. oturum

Dal: `claude/fervent-euler-a8emja` (PR #1) — **push edildi**; iş worktree'de (`.claude/worktrees/mevzi-uav-soldier`,
dal `worktree-mevzi-uav-soldier`, `git push origin HEAD:claude/fervent-euler-a8emja`), her push'tan sonra kullanıcının
oynadığı `C:\mevzi` ff-only güncellenir (kullanıcı isteği). Ayrıntılar ROADMAP günlüğünde.

## 3. oturumda yapılan (commit'li, push'lu)
- 93 İHA: 22 model üretildi (gerçek boyut, türe özgü), katalog `v.type` / `v.L/W`, boyut denetimi 190/190 (X kanatta
  çapraz); görsel ölçek kanat açıklığına yumuşak tavan (MQ-9 6,4 m, RQ-4 9,4 m)
- 95 inşaat: bitince taşıyıcı bırakır; yol önbelleği (12 m kova) ilk parça denetimi + ızgara değişince silme; iri hücrede
  taraf yapısının köşesi kapalı; malzeme yığını açık yana · 96 kamyon rotası kapanınca yeniden aranır
- 98 kapalı hafif araç yolcu yeri (ISV 8 …) · 103/106 vurulan kamyonun hamalları temizlenir, boşaltma sonrası dönüş
- 104 araç sıkışması: hedef yeri ayırma, itme toplamı ≤2,5 m/sn, dolaşma / ileri çektirme · 105 asker araç gövdesine
  girmez (izdüşüm + köşelerden dolaşma; kalan: araç–çit dar boşluğu)
- 97 Abrams: komutan kubbe kapağında (`meta.hatch`), `turret_k` 0,88 · 99 vurulan topun mürettebatı gerçek askere
  dönüşür · 108 yakına düşüş ≤%40 can · 109 kendiliğinden ateş: kendi optiği + etkili menzil · 114 ağır isabetli
  araçtan sağ çıkış çok az · 117 fare ağacı saydamlaştırmaz, mat yaprak · 118 evden herkes çıkar · 119/60 asker
  oyuk arazide zemine basar
- Yeni test sahneleri: `crewkilltest`, `mbtgallery`; genişleyenler: buildtest (`--map=`), logitest, supplytest
  (artık geçiyor), septest (artık geçiyor), vehtest, rangetest, crewtest, garrisontest, soldiertest, armeduav
- Kullanıcının yeni maddeleri ROADMAP 95–121 (tabloda); 120 piyade YZ hedef listesi, 121 CC0 varlıklar
  (`docs/ASSET_KAYNAKLARI.md`)

## Sıradaki adımlar
1. Kalan kullanıcı hataları: 110 savaş sisi (yamuk kenar, birim başına görüş), 112 sürücü / açıktaki mürettebat
   vurulması, 115 sudaki el bombası efekti + duman, 116 keskin nişancı siperde kayma, 107 araç zekâsı, 102 halat +
   arka rampa (76), 101/111 topçu mermi animasyonları, 113 çit arasında yatma (modellemeden sonra)
2. Asker işleri (devam): 61/92 araç üstü oturma + güverte yüksekliği, 66 silah tutuşu, 74 çömelince geriye yatma,
   80 sırtta tanksavar, 83 geri koşarken ateş, 84 kalabalık ayrışma, 85 ördek yürüyüşü, 89 siper derinliği pozu,
   60'ın kalanı (adım uzunluğu, animasyon seyreltmesi)
3. Sonra HUD (65/57) + tüm emirlerin HUD ile bütünleşmesi (kullanıcı sordu; öneri: bu hata grubundan hemen sonra)
4. Bilinen kararsız testler: `stucktest` bazı tohumlarda araç takılması çözülmüyor (eski koddan beri), `vehtest`
   mayınlı tohumlar, `septest` dar boşluk (toleranslı)

---

# (Tarihsel) Devir notu — 16 Ekim 2026, 2. oturum

## 2. oturumda yapılan (commit'li, testleri geçti)
- `4455cad` Roadmap 91: havadaki araçlarda irtifa çizgisi + yer halkası (görüntüde doğrulandı), "airgray" boya,
  soldiertest / armeduav sahneleri, ROADMAP 92–94
- `412b5bd` Roadmap 94 + 87: taret kopması katı cisim (`scripts/debris_body.gd` — `DebrisBody`: yerçekimi, takla,
  arazi + enkaz güvertesi teması, sekme, kayma, su; durunca tüter ve ızgarada enkaz engeli). Biçimler (pop, toss,
  flipback, lift, slide, namlu kopması, M1'de panel atma "vent", yanan tankta gecikmeli infilak "late") vuruş yönü /
  mühimmat / imha türünden. Kullanıcı "aşırı yükseğe uçuyor" dedi → tepe en çok ~3–5 m. Enkaz parçaları
  (`Vehicle._debris`) da DebrisBody. Yanmış enkaz: armor gölgelendiricisinde `burnt` (is/pas/kül, ayrıntı korunur,
  `Art.burn(mi)`). `Terrain.ground_hs` (çift doğrusal yükseklik — askerlerin zemin teması için de kullanılabilir).
  Tank üstündeki askerler savrulur (`Soldier.throw_off`), yolcuların kaderi imha türüne göre. Test: `turrettest`
- `1c7cdb0` evadetest'in "engel arkasındaki hedef" aşaması çözümsüz kurulmuştu (hedef tankın yanına düşen ev duvar
  boşluğunu kapatıyordu) → açık alanda kurulur. Regresyon: killtest, fftest, mounttest, crewvistest, vehtest,
  stucktest, evadetest, paratest, bridgetest, turrettest geçti
- DebrisBody ileride: 62 (enkaz itme), 70 (kule devrilmesi), 82 (köprüden düşen cesetler) için kullanılabilir

## Kaydedilmemiş değişiklikler (yarım: 93 İHA modelleri)
- `tools/blender/veh/fam_uav.py`: İHA aileleri baştan (loft gövde, türe özgü: mq9, mq1c, orion, forpost, rq4 (hale),
  rq7, orlan10/30, raven, zala, eleron, vbat); dolanan mühimmat birim başına gerçek boy/kanat açıklığından
  (`v.L`, `v.W`) ve türden: lm_tube `sw` (Switchblade) / `altius`, lm_wing `x` (Lancet, Red Dragon) / `flywing` (KUB) /
  `plane` (Molniya-2), lm_delta (Geran-2). **Henüz Blender'da hiç çalıştırılmadı.** `vlib.py`'de "airgray" rengi.
- Katalog düzenlemesi **yapılmadı** (komut bu noktada engellendi). Yapılacak: `data/catalog/usa.json` ve `rus.json`'da
  (satır başına bir birim) şu birimlerden `"scale"` silinecek ve `"v"`ye eklenecek (`"fam"`dan hemen sonra):
  usa_uav_mq1c type=mq1c · usa_uav_mq9 type=mq9 (big korunur) · usa_uav_rq7 type=rq7 · usa_uav_rq11 type=raven ·
  usa_uav_rq4, usa_uav_vbat (yalnız scale silinir) · rus_uav_orlan10 type=orlan10 · rus_uav_orlan30 type=orlan30 ·
  rus_uav_zala42116e type=zala · rus_uav_eleron3 type=eleron · rus_uav_forpostr type=forpost · rus_uav_orion type=orion ·
  dolanan mühimmatta tür + `L`/`W` (değerler `data/real_dims.json`'dan): usa_lm_sw300/sw600 type=sw · usa_lm_alt600/
  alt700 type=altius · usa_lm_red, rus_lm_lancet3, rus_lm_lancet3m type=x · rus_lm_kub type=flywing ·
  rus_lm_molniya2 type=plane · rus_lm_geran2 (yalnız L/W + scale silinir)

## Sıradaki adımlar (sırayla)
1. Katalog düzenlemesi (yukarıda), sonra üretim (usa ve rus):
   `blender -b --factory-startup -P tools/blender/veh/gen.py -- data/catalog/usa.json assets/models "" uav_male,uav_hale,uav_tac,uav_hand,uav_vtol,lm_tube,lm_wing,lm_delta`
   → `godot --headless --path . -s res://tools/size_audit.gd` (hava araçlarında ölçüt kanat açıklığı W) → armeduav,
   dronetest, uavtest. Ortografik kamerada yüksek uçan İHA dev görünmesin: Vehicle.setup'ta görsel irtifa ölçeği
   (MALE ~×0,5, HALE ~×0,4), yörünge yarıçapını büyüt. Kullanıcı (93): "maket uçak gibi, çok büyük".
2. Askerler (kullanıcının en sık şikâyeti — 60/61/66/74/80/83/84/85/89/92): soldier.gd'de `position.y = 0.0` → arazi
   yüksekliği (`Terrain.ground_hs`; krater/şev/tepede süzülme ve gömülme — soldiertest'te askerler nehir yüzeyinde
   yürüyordu), mocap adım uzunluğu kalibrasyonu (ayak kayması), ekrandaki askerde animasyon seyreltmesini kapat, araç
   üstünde oturma pozu + gerçek güverte yüksekliği (seat_pos sabit 1,55 m), siper derinliğine göre poz, geriye koşarken
   ateş etmeme, çömelince geriye yatma, silah tutuşu, sırtta tanksavarda kollar, kalabalıkta tank çevresinde ayrışma.
3. Sonra ROADMAP 60–93 ve Faz 7: HUD (65/57), Broken Arrow tipi silah/atış modları (72/88), roket hızları (90), binalar
   (35 farklı evler, 67 malzemeye göre yıkım, 69 girilebilir + üst kat, 70 kule devrilmesi), köprü mühimmata göre (68),
   kum torbası (36), Chinook rampası (76), askı halatı/kanca/yük bırakma (77/78), araç kapıları (79), enkaz itme (62),
   nehir akışı (71), mat harita (63), tüm birlikler görünür (64), kayıt (58), ses (56), performans (55), fragman (59).
   Bilinen başarısız testler: `septest` (araç içinde kalan 4 asker), `supplytest`.

## Ortam
Godot `C:\Godot\Godot_v4.7.2-stable_win64_console.exe` · Blender 5.2 `C:\Program Files\Blender Foundation\Blender 5.2\blender.exe`
(Python'u: `...\5.2\python\bin\python.exe`, numpy var, PIL yok) · Node `C:\Program Files\nodejs\node.exe` · test kopyası
`C:\mevzi_test` (git worktree; `robocopy C:\mevzi C:\mevzi_test /MIR /XD C:\mevzi\.git C:\mevzi\.godot C:\mevzi\shots ...`).
Kural: oyunda cami/mescit/kilise/minare ve **benzeri (kubbe, ince halkalı kule)** asla yok.

---

# (Tarihsel) Devir notu — bulut oturumundan yerel (GPU) oturuma (15 Ekim 2026)

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
