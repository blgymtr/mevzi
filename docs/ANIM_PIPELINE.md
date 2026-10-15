# İskeletli animasyon hattı (MEVZİ)

Unreal Engine / ticari mocap kütüphaneleri yerine kendi hattımız: **gerçekçi insan örgüsü (MakeHuman, CC0)
+ kendi oyun iskeletimiz + CMU hareket yakalama verisi (BVH) → Python/Blender'da yeniden hedefleme
(retarget) → adlı kliplerle tek GLB → Godot'ta AnimationTree ile oynatma / karıştırma.**

Bu belge prototipi anlatır: kaynaklar ve lisanslar, iskelet ve kemik eşlemesi, klip listesi, Godot tarafı,
`soldier_body.gd`'ye nasıl bağlanacağı ve eksikler. (Henüz oyuna bağlı değil; `soldier.gd` başka ekipte.)

## 1. Hat — tek komut

```
python3 tools/anim/build_anims.py          # kaynakları indirir (tools/anim/.cache, git dışı) + GLB üretir
godot --headless --path . --import         # GLB'yi içe aktar
godot --path . res://tools/anim_preview.tscn -- --out=/mutlak/klasor [--samples=4] [--only=walk,run,demo]
```

| Adım | Dosya | Ne yapar |
|---|---|---|
| Kaynak indirme | `build_anims.py: fetch_all` | MakeHuman ve CMU yansısından **sabit işlemelerden** (commit) ham dosyaları `curl` ile indirir |
| İnsan örgüsü | `mh.py`, `build_human` | `base.obj` + makro hedefler (erkek, genç, ~%67 kas, boy biraz uzun, ideal oran) → 1.80 m'ye ölçek; göz örgüsü dahil, yardımcı (helper) örgüler atılır |
| İskelet | `rig_layout` | MakeHuman `default.mhskel` eklem köşe gruplarından 35 kemiklik oyun iskeleti (Godot humanoid adları) |
| Ağırlık | `vertex_weights` | MakeHuman'ın elle boyanmış 163 kemik ağırlıkları (CC0) 35 kemiğe birleştirilir (Blender ısı ağırlığından daha temiz); köşe başına en çok 4 kemik |
| Görünüm | `blender_build` | malzeme bölgeleri (üniforma / bot / eldiven / ten / göz / miğfer), Head kemiğine bağlı miğfer, simetrik inceltme (varsayılan %40 → ~10.9k üçgen) |
| Retarget | `bvh.py`, `retarget` | BVH ileri kinematiği → dünya uzayı dönüş farkları → hedef kemiklere; uzuvlar T-pozu/A-pozu farkına göre hizalanır |
| Temizlik | `loop_cut`, `once_cut`, `foot_lock`, `leg_ik` | yere oturtma, en iyi döngü kesiti + çapraz geçiş, kök hareketinin çıkarılması, ayak kilidi (bacak IK), çömelme derinleştirme |
| Tüfek katmanı | `rifle_pose` | iki kemikli analitik IK ile anahtar pozlar: `rifle_ready`, `rifle_aim` (yalnız kol/omuz/parmak kemikleri) |
| Dışa aktarım | Blender glTF | `assets/anim/soldier_anim.glb` (+ `soldier_anim.json` klip bilgisi, `.import` ayarı) |
| Doğrulama | `tools/anim_preview.tscn/.gd` | her klip ayrı askerde, AnimationTree demoları, çok açılı ekran görüntüleri + ayak yüksekliği raporu |

Bağımlılık: Blender Python modülü `bpy` (5.x; sunucuda `python3 -c "import bpy"`) ve numpy. Tam üretim ~15 s.

## 2. Kaynaklar ve lisanslar (ayrıntı: `assets/anim/CREDITS.txt`)

| Kaynak | Ne | Lisans | Ticari? |
|---|---|---|---|
| MakeHuman 1.x — `makehumancommunity/makehuman` @ `a8bc2d54` | taban örgü, eklem tanımları, ağırlıklar, makro hedefler | **CC0 1.0** (depodaki `LICENSE.md` bölüm C + `LICENSE.ASSETS.md`); çıktılar üzerinde hak iddia edilmez (bölüm D) | Evet |
| CMU Graphics Lab Mocap — BVH: B. Hahne (cgspeed), yansı `una-dinosauria/cmu-mocap` @ `09a07f54` | hareket verisi | "free for use in research and commercial projects worldwide"; tek kısıt verinin kendisini yeniden satmamak | Evet |

Kullanılmadı (ticari kullanıma kapalı): Bandai Namco Research Motion Dataset (CC BY-NC), Ubisoft LaFAN1
(CC BY-NC-ND), AI4Animation (CC BY-NC), Mixamo. MakeHuman'ın AGPL kaynak kodu da kullanılmadı — yalnız
veri dosyaları okunuyor (`tools/anim/mh.py` bizim). Künyeye CMU teşekkür metni eklenmeli (CREDITS.txt).

## 3. İskelet (35 kemik) ve eşleme

Yön: Blender'da +Y ileri / Z yukarı → glTF/Godot'ta **ileri −Z, yukarı +Y, anatomik sağ +X**
(oyunun mevcut `soldier_body.gd` kuralıyla aynı ileri yön). Boy 1.80 m, kalça eklemi ~0.93 m.

| Kemik | Ebeveyn | MakeHuman kemikleri (ağırlık kaynağı) | CMU eklemi (dönüş kaynağı) |
|---|---|---|---|
| Root | — | — (yerde, kök hareketi) | tek seferlik kliplerde yumuşatılmış kalça izi |
| Hips | Root | root, pelvis.L/R, spine05, upperleg01 (%30) | Hips (konum: iki UpLeg ortası) |
| Spine | Hips | spine04, spine03 | LowerBack |
| Chest | Spine | spine02 | Spine |
| UpperChest | Chest | spine01, breast.L/R | Spine1 |
| Neck | UpperChest | neck01, neck02, neck03 (%50) | Neck ⊕ Neck1 (yarı yarıya) |
| Head | Neck | head, neck03 (%50), yüz/çene/göz/dil kemikleri | Head |
| {Left,Right}Shoulder | UpperChest | clavicle, shoulder01 (%50) | LeftShoulder / RightShoulder |
| {L,R}UpperArm | Shoulder | upperarm01/02, shoulder01 (%50) | LeftArm |
| {L,R}LowerArm | UpperArm | lowerarm01/02 | LeftForeArm |
| {L,R}Hand | LowerArm | wrist, metacarpal1-4 | LeftHand |
| {L,R}ThumbMetacarpal / ThumbProximal | Hand | finger1-1 / finger1-2,1-3 | — (poz: gevşek ya da kavrama) |
| {L,R}IndexProximal / IndexIntermediate | Hand | finger2-1 / finger2-2,2-3 | — |
| {L,R}MiddleProximal / MiddleIntermediate | Hand | finger3,4,5-1 / -2,-3 (orta+yüzük+serçe birlikte) | — |
| {L,R}UpperLeg | Hips | upperleg02, upperleg01 (%70) | LeftUpLeg |
| {L,R}LowerLeg | UpperLeg | lowerleg01/02 | LeftLeg |
| {L,R}Foot | LowerLeg | foot | LeftFoot |
| {L,R}Toes | Foot | toe* | LeftToeBase |

Adlar Godot `SkeletonProfileHumanoid` ile uyumlu (parmaklar kısaltılmış: 3 parmak × 2 boğum); ileride
`BoneMap` ile başka humanoid animasyonlar da yeniden hedeflenebilir.

## 4. Yeniden hedefleme yöntemi

* **Dünya uzayı dönüş farkı:** her kaynak eklem için `Δ(t) = R_kaynak(t) · R_kaynak(T-pozu)ᵀ`
  (CMU BVH'nin 0. karesi Hahne'nin eklediği T-pozudur). Hedef kemik: `W(t) = Δ(t) · T_hedef`.
  Yerel eksen kuralları farklı olsa da dünya farkı aktarıldığı için eksen/burulma karışmaz.
* **T-pozu hizalaması yalnız uzuvlarda:** UpperArm/LowerArm/Hand/UpperLeg/LowerLeg'de hedefin A-pozu
  kemik yönü kaynağın T-pozu yönüne en kısa yayla döndürülür. Gövde, köprücük, boyun, baş, ayakta
  kaynağın T-pozu = hedefin doğal duruşu kabul edilir (aksi hâlde omuzlar sürekli kalkık / gövde eğik kalıyordu).
* **Ölçek:** kalça→bilek bacak boyu oranı (`scale` JSON'da, ~0.93–1.0).
* **Yere oturtma:** her karede hedefin ve kaynağın en alçak "temas noktası" (bilek, ayak tabanı/parmak ucu,
  diz, el, dirsek, kalça, göğüs, baş — her biri deri kalınlığı yarıçapıyla) eşlenir; kalça yüksekliği buna göre
  düzeltilir (yatma, sürünme, diz çökme dahil tüm kliplerde tutarlı).
* **Döngüler:** belirtilen aralıkta poz + hız farkı en küçük (başlangıç, uzunluk) çifti aranır; son 6 kare
  başlangıç öncesine çapraz geçişle bağlanır; son kare = ilk kare. Kök hareketi çıkarılır (**yerinde**),
  hız vektörü JSON'a yazılır. Yürüme yönüne göre (geri/yana kliplerde gövde yönüne göre) +Y'ye döndürülür.
* **Ayak kilidi:** yerinde döngüde dünya konumu = yerinde + hız·t. Bilek alçak ve yavaş olduğu temas
  karelerinde bilek dünya konumu sabitlenir; iki kemikli bacak IK'sı diz düzlemini koruyarak çözer
  (ayak dünya yönü korunur). Ölçülen temas kayması: walk 0.17→0.02 m/s, run 0.49→0.06, sprint 0.45→0.04
  (JSON `foot_slide`: [önce, sonra]).
* **Çömelme derinleştirme:** CMU'daki "creeping walk" hafif çömelik; kalça 10 cm indirilip gövde 10° öne
  eğilir, bilekler yerinde tutulur (bacak IK) → `crouch_walk`.
* **Tek seferlik klipler:** yatay kayma `Root` kemiğine (Gauss yumuşatılmış kalça izi) yazılır; dönüş
  kliplerinde Root yalnız sapma (yaw) taşır. Godot'ta `root_motion_track` ile birime aktarılabilir.

## 5. Klip listesi

(Değerler `assets/anim/soldier_anim.json`'dan; 30 fps. Döngüler yerinde; hız m/s, Godot çerçevesinde
`velocity` = [x, 0, z], ileri −Z.)

| Klip | Tür | Süre (s) / kare | Hız / kök hareketi | Kaynak (CMU, 120 fps kare) | Açıklama |
|---|---|---|---|---|---|
| `idle` | döngü (yerinde) | 3.43 / 103 | — | 77_02 452–864 | ayakta bekleme (hafif ağırlık aktarma) |
| `walk` | döngü (yerinde) | 1.13 / 34 | 1.29 m/s, v=[0.02, 0, -1.29]; ayak kayması 0.166→0.021 | 35_01 190–326 | yürüyüş |
| `run` | döngü (yerinde) | 0.73 / 22 | 3.15 m/s, v=[0.04, 0, -3.15]; ayak kayması 0.492→0.062 | 35_17 29–117 | koşu |
| `sprint` | döngü (yerinde) | 0.67 / 20 | 4.56 m/s, v=[-0.04, 0, -4.56]; ayak kayması 0.45→0.038 | 127_07 61–141 | depar |
| `walk_back` | döngü (yerinde) | 1.00 / 30 | 2.59 m/s, v=[-0.23, 0, 2.58]; ayak kayması 0.195→0.031 | 141_31 64–184 | geri geri (hızlı) yürüme |
| `strafe_right` | döngü (yerinde) | 1.30 / 39 | 1.33 m/s, v=[1.33, 0, 0.05]; ayak kayması 0.271→0.027 | 141_33 152–308 | yana (sağa) adımlama |
| `strafe_left` | döngü (yerinde) | 1.17 / 35 | 1.41 m/s, v=[-1.41, 0, -0.01]; ayak kayması 0.329→0.029 | 141_33 765–905 | yana (sola) adımlama |
| `crouch_walk` | döngü (yerinde) | 1.50 / 45 | 0.63 m/s, v=[0.14, 0, -0.62]; ayak kayması 0.151→0.021 | 77_29 914–1094 | çömelerek / sinsice yürüme (+10 cm IK ile alçaltılmış) |
| `crawl` | döngü (yerinde) | 1.37 / 41 | 0.15 m/s, v=[-0.03, 0, -0.14] | 111_03 936–1100 | dört ayak (el-diz) sürünme |
| `prone_idle` | döngü (yerinde) | 1.00 / 30 | — | 140_01 25–145 | yüzüstü yatış (bekleme) |
| `kneel_idle` | döngü (yerinde) | 1.20 / 36 | — | 23_03 310–454 | tek diz çökmüş bekleme |
| `jump` | tek sefer | 2.03 / 61 | Root: x -0.07, ileri 1.32 m, dönüş 0° | 13_11 150–394 | ileri atlama |
| `hit_stagger` | tek sefer | 1.07 / 32 | Root: x -0.03, ileri 0.57 m, dönüş 0° | 22_12 1–129 | darbe / sendeleme ve toparlanma |
| `duck` | tek sefer | 3.23 / 97 | Root: x -0.01, ileri 0.13 m, dönüş 0° | 77_09 170–558 | patlamadan korunma: çömelip başı kollarla kapatma |
| `fall_back` | tek sefer | 0.93 / 28 | Root: x -0.01, ileri 0.03 m, dönüş 0° | 90_18 70–182 | sırt üstü düşme (ölüm / devrilme) |
| `getup` | tek sefer | 3.23 / 97 | Root: x -0.05, ileri -0.52 m, dönüş 0° | 77_16 170–558 | yüzüstü yatıştan kalkıp tetikte duruşa geçme |
| `turn_left` | tek sefer | 1.93 / 58 | Root: x 0.00, ileri 0.00 m, dönüş 93° | 69_16 175–407 | yerinde 90° sola dönüş |
| `turn_right` | tek sefer | 1.83 / 55 | Root: x 0.00, ileri 0.00 m, dönüş -91° | 69_18 125–345 | yerinde 90° sağa dönüş |
| `kneel_down` | tek sefer | 1.67 / 50 | Root: x -0.03, ileri 0.07 m, dönüş 0° | 23_03 35–235 | tek dize çökme |
| `kneel_up` | tek sefer | 1.07 / 32 | Root: x -0.10, ileri 0.11 m, dönüş 0° | 23_03 485–613 | dizden kalkma |
| `rifle_ready` | katman pozu | 0.03 / 1 | — | anahtar poz (IK) | tüfek alçak hazır üst gövde katmanı |
| `rifle_aim` | katman pozu | 0.03 / 1 | — | anahtar poz (IK) | tüfek nişan üst gövde katmanı |

Tüfek katmanı (`rifle_ready`, `rifle_aim`): yalnız `arm_layer_bones` (2×Shoulder, UpperArm, LowerArm,
Hand, 6 parmak) anahtarlı, 1 karelik sabit poz. Sağ el tabanca kabzasını (kabza ekseni 18° geri), sol el el
kundağını alttan kavrar; dipçik sağ omuz cebinde. `ready` = namlu 38° aşağı (alçak hazır), `aim` = omuz
hizasında nişan. GLB'deki `Rifle` düğümü (basit karabina) `RightHand` kemiğine bağlıdır; oyunda gerçek silah
modeli aynı kemiğe `BoneAttachment3D` ile takılır.

## 6. Godot tarafı

* **İçe aktarma:** döngü klipleri Blender'da `-loop` sonekiyle adlandırılır → Godot `LOOP_LINEAR` yapar ve
  soneki atar (ad `walk`). `.import`'ta `animation/remove_immutable_tracks=false` şart (tüfek pozu yalnız
  sabit izlerden oluşur; açık kalırsa poz silinir). Godot GLB'den otomatik LOD üretir.
* **AnimationTree örneği** (`anim_preview.gd: _make_tree`):
  ```
  BlendTree  (loco → shot → layer → output)
   ├─ loco  : BlendSpace1D (sync) idle@0, walk@1.29, run@3.15, sprint@4.56  ← parameters/loco/blend_position = hız
   ├─ shot  : OneShot(loco, hit_stagger|duck|jump…) fade 0.15/0.3      ← parameters/shot/request = FIRE
   ├─ upper : Animation rifle_ready | rifle_aim
   └─ layer : Blend2(shot, upper), süzgeç = arm_layer_bones, amount 1    ← tüfek üst gövde katmanı
  ```
  Katman OneShot'tan **sonra** gelir; böylece darbe tepkisinde de eller silahta kalır (ilk denemede OneShot
  sonda olduğundan sol el tüfeği bırakıyordu). Süzgeç yolları animasyon izlerinden alınır
  (`Armature/Skeleton3D:LeftUpperArm` biçimi). Geri/yan hareket için `walk`, `walk_back`, `strafe_left`,
  `strafe_right` JSON'daki `velocity` (x, z) noktalarıyla bir BlendSpace2D'ye konabilir.
* **Kök hareketi:** tek seferlik kliplerde `AnimationTree.root_motion_track = "Armature/Skeleton3D:Root"`
  verilirse Root izi iskelete uygulanmaz, `get_root_motion_position()` / `_rotation()` birim düğümüne eklenir.
  Döngülerde Root sabittir; birimi oyun kodu `velocity`'ye göre yürütür (ayak kilidi bu hıza göre yapıldı,
  oynatma hızı `anim_speed = birim_hızı / klip_hızı` ile ölçeklenmeli).

## 7. `soldier_body.gd`'ye bağlama planı (henüz yapılmadı)

Bugünkü `SoldierBody` 10 pivotlu prosedürel figür + `_build_skin` ile 10 kemikli basit iskelet kullanıyor;
`animate(dt, pose, speed)` her karede pivot açılarını hesaplıyor, silah elleri `_solve_arm` IK'sıyla oturuyor.
Önerilen geçiş (ayrı bir `SoldierAnimBody` sınıfı, aynı genel arayüz: `build`, `animate`, `muzzle_pos`,
`sync_skin`, `reset_rig`), böylece `soldier.gd` değişmeden bayrakla seçilebilir:

| Kod pozu (`animate`) | Klip / ağaç durumu | Not |
|---|---|---|
| stand | idle + rifle_ready katmanı | |
| aim (duran / yürüyen) | idle veya loco + rifle_aim katmanı | gövde/baş nişanı için `AimModifier3D` / `LookAtModifier3D` (UpperChest, Head) |
| walk / run | loco BlendSpace1D (walk, run, sprint) + rifle_ready | `blend_position = speed`; geri/yan için BlendSpace2D: walk, walk_back, strafe_left/right |
| crouch (hareketli) / crouch_aim | crouch_walk + rifle_ready/aim | |
| crouch (duran) | kneel_down → kneel_idle (+rifle_aim) → kneel_up | |
| prone / prone_aim | prone_idle (+ tüfek için ayrı yüzüstü nişan pozu GEREKİR) | eksik |
| crawl | crawl (el-diz) | gerçek yüzüstü sürünme eksik |
| flinch | duck (OneShot) | |
| dazed | hit_stagger (OneShot) | |
| dead | fall_back → ragdoll | ragdoll.gd şimdilik pivotlara bağlı; 35 kemiğe `PhysicalBoneSimulator3D` gerekir |
| (yerinde dönüş > 45°) | turn_left / turn_right | Root yaw kök hareketi |
| (yerden kalkma) | getup | |
| vault / slide / throw / blind / surrender / build / carry / melee / dragging / wounded / healing / fly | — | şimdilik eski prosedürel kodda kalabilir ya da Blender'da anahtarlanır (bkz. §8) |

* **Silah elleri (IK korunur):** katman pozu ortalama bir karabina içindir. Silah türü değişince (MG, RPG,
  tabanca, keskin nişancı) eller `TwoBoneIK3D` (Godot 4.7'de var) ile silah modelindeki kabza / el kundağı
  işaretlerine çekilmeli — mevcut `_grip_points()` mantığı aynen işaret noktası üretir. Sıra: AnimationTree →
  Aim/LookAt → TwoBoneIK3D (sol el, gerekirse sağ el) → BoneAttachment3D (silah RightHand'de).
* **Ölçek / kemik konumu:** oyundaki HIP 0.92 m; bu modelde kalça eklemi ~0.93 m — doğrudan uyumlu.
* **Taraf uyarısı:** eski figürde `arm_r` −X'te (−Z'ye bakan figürde anatomik sol); yeni modelde silah
  anatomik sağ elde (+X). Kamera/namlu ofsetleri (`muzzle_pos`) yeni modele göre yeniden ölçülmeli.
* **Takım renkleri:** malzeme adları `uniform`, `helmet`, `boots`, `gloves`, `skin` — `Art.material(ad, takım)`
  ile değiştirilebilir (mevcut `_build_skin` deseni).
* **Performans:** 10.9k üçgen + otomatik LOD, 35 kemik. 100+ asker için `AnimationTree` yerine uzak
  birimlerde düz `AnimationPlayer` (ya da LOD'da animasyon güncelleme sıklığını düşürme) önerilir.

## 8. Eksikler ve bilinen kusurlar

**CMU'da olmayan, Blender'da anahtarlanacak askeri hareketler:** şarjör değiştirme, silah değiştirme
(tüfek↔tabanca), el bombası atma, yüzüstü nişan / yüzüstü alçak sürünme (CMU'da yalnız el-diz sürünme var),
halatla iniş (fast-rope), paraşüt (açılma, iniş yuvarlanması), araca binme/inme, yaralı sürüklenme/taşıma,
siper arkası (blind fire), engelden atlama (vault), mevzi kazma/inşaat, teslim olma, bayrak/işaret.
Anahtarlama yöntemi: aynı GLB'yi Blender'a aç (ya da `build_anims.py`'ye yeni bir `keyed_*` işlevi ekle),
kolları `rifle_pose`'daki gibi IK hedefleriyle, gövdeyi elle anahtarla; eylemi adlandırıp yeniden dışa aktar.
`rifle_pose` deseni (hedef noktalar + iki kemikli IK + parmak bükümü) şarjör değiştirme gibi el
hareketleri için genişletilebilir.

**Kalite notları (dürüst değerlendirme):**
* Örgü pürüzsüz bir "manken": üniforma/teçhizat/yelek yok, yüz ve ayaklar basit. Kıyafet MakeHuman
  proxy'leriyle (CC0 olanlar) ya da Blender'da modellenmeli.
* CMU verisi amatör oyunculardan; bazı kliplerin üst gövdesi bağlama uygun değil (kneel_idle'da kol
  "teselli etme" hareketi, getup sonu "dikkatli" kambur duruş) — tüfek katmanı kolları örter, gövde kalır.
* Parmak verisi yok (CMU), parmaklar sabit gevşek büküm; el bilekleri CMU'da gürültülü olabilir.
* `walk_back` hızlı (2.6 m/s geri koşu benzeri), `crawl` el-diz (askeri "yüksek sürünme"), gerçek yüzüstü
  sürünme yok. `hit_stagger` bir çarpışma sendelemesi, mermi isabeti tepkisi değil.
* Tek seferlik kliplerde ayak kilidi yok (yalnız döngülerde); kök hareketi yumuşatıldığı için kalkma/diz
  çökme sırasında küçük ayak kaymaları görülebilir.
* Tüfek pozu tek karabina ölçüsüne göre; büyük silahlar için TwoBoneIK3D gerekli (§7).
