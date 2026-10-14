# Tasarım analizi: Broken Arrow (yalnızca tasarım notları)

Kaynak: kurulu oyunun kendi kılavuzu (`Manual/BrokenArrowManualEBOOK.pdf`), görev editörü belgeleri
(`Manual/Data/MissionEditor/*.md`), çok oyunculu harita meta dosyaları (`SharedMissions/*_network/meta.json`)
ve Addressables kataloğundaki dosya adları. Hiçbir model, doku, ses veya kod alınmadı.

## Gözlemler (dosyalardan doğrudan)

**Maç yapısı**
- Standart çok oyunculu: 5v5 (meta.json'da her takım 5 slot). Hızlı maç 5v5 arar.
- Lobi ayarları (Kaliningrad_network/meta.json `pblOpt`):
  - Başlangıç parası: varsayılan 1000 (500–1500)
  - Gelir: varsayılan 300 (0–600, 25'lik adım)
  - Maç süresi: varsayılan **45 dk** (30–60 dk)
  - Harita boyu: Otomatik / Büyük / Küçük
  - Gün saati: sabah / gündüz / akşam / gece / rastgele
- Ekonomi: puan + gelir + **bakım (upkeep)**. Bakım, sahadaki birimlere bağlı; gelirden büyük olamaz (Economy.md).

**Oyun modları** (Gameplay.md)
- *War Goals* (dereceli mod): oyuncu başına imha hedefleri, aşamalar, kaybeden tarafa VP telafisi.
- *Conquest*: aşama boyunca daha çok hedef bölge tutan takım puan toplar; "ani ölüm" seçeneği.
- *Destruction*: imha odaklı.
- Ayrıca: Senaryo (topluluk/resmî), Skirmish (yapay zekâya karşı), Kampanya (ABD ve Rusya).

**Birimler**
- Deste (deck) sistemi: ulus + iki uzmanlık seçilir; birimler desteden çağrılır (Army Builder).
- Birim API'si (LuaUnit.md): maliyet, rol, can %, mühimmat %, yakıt, kargo (birim + ikmal kg), "kötü durum" sayısı (hareket kritikleri dahil), ikmal deposundan ikmal, üsse geri dönüş.
- Zırh: kinetik ve oyuk dolgu için **iki ayrı zırh değeri**; kinetik delme mesafe azaldıkça artar, oyuk dolgu artmaz; hafif tanksavar silahları her zaman kritik hasar verir (kılavuz s.18).
- Model sayısı (katalog dosya adları): ABD ~300, Rusya ~230 araç/silah prefabı, ~200 piyade prefabı, 51 uçak, 36 helikopter.

**Emirler** (kılavuz s.19–23): Saldırı hareketi, iptal, ateşi tut, hızlı hareket (yol bonusu), geri vites,
zorla ateş, üsse dön (iade), indir, uçak taarruz hattı, alçak irtifa, havadan atma, topçu ateş görevi
(mühimmat: patlayıcı/sis/hassas; süre: kısa/orta/uzun; desen: nokta/hat/yürüyen), koşu, sis, aldatıcı,
aktif koruma, lazer işaretleme, hassas vuruş, radar.

**Efektler** (dosya adları): patlamalar **kalibreye** (12.7 mm, 30 mm, 152–155 mm, termobarik, misket, hava patlaması)
ve **çarpılan yüzeye** (zemin / bina / araç) göre ayrı efekt.

**Haritalar**: ~25 harita (Baltık şehirleri, liman, havalimanı, baraj, rafineri, kömür madeni...).

## Çıkarımlar (Mevzi için)
- 20+ dakikalık çok oyunculu maç için harita en az **1–1.5 km** olmalı (şu an 256 m). Lojistik hatlarının
  ve araç hareketinin anlamlı olması için ilk hedef **1024 × 1024 m**.
- Maç süresi ayarlanabilir olmalı (30–60 dk), gelir + bakım modeli birim spamını sınırlar.
- Efekt kalitesinin anahtarı tek tip patlama değil, **kalibre × yüzey** matrisi.
- İki zırh değeri (kinetik / oyuk dolgu) bizim zırh sistemimize derinlik katar.

## Mevzi'nin farkı (Defilade ve Broken Arrow'dan ayrışma)
Esin: Sudden Strike 5, Men of War AS2, Company of Heroes 2/3, Red Alert tarzı RTS.
- **Üs kurma + ikmal yolları** (Red Alert / CoH): deste yerine sahada kurulan yapılar ve kamyon hattı.
- **Doğrudan kontrol ve envanter** (Men of War): askerin cebindeki el bombası/mermi, ölülerden alma (var).
- **Asker yapay zekâsı ve hikâye anları** (CoH): yaralı sürükleme, esir/istihbarat, sedye (var).
- **Hava durumu ve mevsim** etkisi: kum fırtınası, sel, kar fırtınası ve donma — iki oyunda da yok.
- **Tim şablonları**: kendi timini tasarla.

## Bilinmeyenler
- Harita metre boyutları (sahneler oyun paketinde; bunları açmadık).
- Birimlerin sayısal istatistikleri (paketli veride; çıkarmadık).

---

# Derin analiz (2. tur)

Kaynaklar: Lua API belgeleri (`MissionEditor/3. Lua/*.md`), IL2CPP meta verisindeki sınıf/alan **adları**
(yalnızca isimler; kod çözülmedi), Addressables kataloğundaki prefab **adları**. Varlık çıkarılmadı.

## 1. Hasar modeli
- **Zırh**: her araçta 4 yön × 2 tip: `KinArmorFront/Sides/Rear/Top` ve `HeatArmorFront/Sides/Rear/Top`.
  Atış vektörüne göre yan seçilir (`GetArmorSideFromShotVector`); bazı mühimmat **üstten saldırı** yapar (`TopArmorAttack`, ör. Javelin).
- **Delme**: `PenetrationAtMinRange`, `PenetrationAtEffectiveRange`, `PenetrationAtGroundRange` → mesafeye göre doğrusal düşüş.
- **Kritik hasar** (`CriticalEffectSystem`): 4 tür × 2 seviye (sarı/kırmızı):
  `Mobility` (hareket), `Optics` (görüş), `Targeting` (nişan), `Loading` (dolum/şarjör).
  `CriticalBaseProbability`, `RedCritsActivationThreshold`; hafif tanksavar her zaman kritik verir.
- **Yakıt**: `FuelSystem` — turuncu/kırmızı bölge, uçaklar yakıt bitince düşer, art yakıcı 2× yakar.

## 2. Stres (baskılanma) — morali yok, stres var
- `StressSystem`: `CurrentStressValue` → seviye 1 **Shocked** (sarsılmış), seviye 2 **Panicked** (panik).
- Stres: isabet, alan etkisi (`StressAOERadius`), füze uyarısı, taşıtın vurulması (`OnTransportDeathCargoForcedStressPercentage`).
- Etkisi: şarjör değiştirme ve atış arası süre uzar (`MagazineReloadTimeStressModifier`, `TimeBetweenBurstsStressModifier`), isabet düşer, panikte birim kaçar.
- Toparlanma: `StressRecovery`, `StressRecoveryMultiplier`.

## 3. Görüş ve gizlilik
- `Optics` (yer / alçak irtifa / yüksek irtifa ayrı değer) karşı `Stealth` (min/max; hareket edince düşer, ateş edince açığa çıkar).
- Duman görüşü keser (`GetDistanceViaSmokes`), radar optiği artırır ama SEAD hedefi olur.
- Sis-i harp birim bazlı (`FogOfWarUnit`), binada gizlenme.

## 4. Ekonomi ve lojistik
- Gelir/dakika (`DefaultIncomePerMinute`) + gelir eğrisi (`IncomeCurve`) + bakım (`Upkeep`, uçaklar ayrı çarpan).
- İkmal: **kg cinsinden** ikmal kutuları / depolar (`Supply`, `MaxSupplyPoints`), taşıtla taşınır, havadan atılır,
  ele geçirilir (`HandleCapturedSupply`), müttefikle paylaşılır. Mühimmat maliyetle ölçülür (`AmmoCost`, `AmmoResupplyModifier`).
- Onarım (`RepairSystem`, maliyetli) ve iyileştirme ikmalden.
- Birim **üsse dönüş** = maliyet iadesi (hasar ve harcanan mühimmat düşülür).
- **Konuşlanma aşaması** (`DeploymentPhase`) maç başında.

## 5. Oyun modları (kod adları)
- `WarGoals`: aşamalar, aşama sonu hedef sahipliği + imha puanı (`WarGoalsConquestPoints`, `WarGoalsDestructionPoints`, `WarGoalsPhasePointsMultiplier`), kaybedene VP telafisi.
- `Conquest`: bölge başına sürekli puan (`ConquestPointsPerZone`), 3 hedef eşiği (`ConquestGoal1-3`).
- `Destruction`.
- Hedef bölgeler: ele geçirilir, çekişmeli olur, tehdit altında uyarısı (`ObjectiveThreatened`, `ObjectiveContested`).

## 6. Hava
- Uçak irtifası alçak/yüksek; aldatıcı (decoy) ve APS şarjlı.
- **Helikopter düşüşü** (`HelicopterCrashFlySystem`): vurulan helikopter kontrolsüz dönerek, alçalarak düşer; alçak irtifada farklı düşüş; düşüş efektleri ayrı.
- Havadan atma: birlik ve ikmal kargo uçağından tek tek atlar (`Airdrop`, `Paradrop`).

## 7. Ortam
- `WeatherController`: yağmur (`CloudRain`, `CloudRainHeavy`, şimşek), kar (`Snowing`, `SnowTextures`), hacimsel sis, gece görüşü.
- Bina: içinde piyade koltuk sayısı (`GetHouseCapacity`), yıkılabilir.

## 8. Piyade tim yapısı (prefab adlarından)
Her tim aynı rol iskeletinden oluşuyor:
`officer` (tim lideri) · `radio` (telsizci) · `rifle` / `rifle1` / `rifle2` (tüfekçi) · `MG` (makineli) ·
`granade` (bombacı) · `heavy` / `Weapon` (ağır silah: AGS, Kornet, TOW, M2) · ayrıca `Engineer`, `Sniper`, `driver`.
Örnek birlik türleri: ABD — Army, Marines, Rangers, Airborne, Delta, Force Recon, Scout Sniper, Engineer;
Rusya — Motostrelki, VDV, Morskaya pehota, GRU, Razvedka, Snaipery, Ingenery-shturmoviki, Conscripts.
Silah sınıfları: piyade tüfeği, karabina, hafif makineli (SAW), genel amaçlı makineli, keskin nişancı (7.62 / .338 / 12.7),
bombaatar, tek kullanımlık roket, güdümlü tanksavar (tripod), omuzdan uçaksavar, otomatik bomba atar.

## 9. Roster ölçeği
Kara: ABD ~80, Rusya ~87 · Helikopter 36 · Uçak 51 · Piyade silahı ~180.
Rol aileleri: ana tank, PSA/ZPT, keşif, tanksavar araç, uçaksavar (top/füze), obüs (çekili/KMO), çok namlulu roketatar,
balistik füze, havan aracı, mühendis/köprü, lojistik kamyon, komuta/gözetleme, insansız hava aracı, kargo uçağı.

## 10. Görsel stil (gözlem; ekran görüntüsü referansına göre)
- Kamera: yüksek, eğik, döndürülebilir; ortografik değil perspektif.
- Efekt matrisi: kalibre × yüzey; büyük patlamalarda kalıcı duman sütunu, ateş, saçılan toprak ve şok dalgası tozu.
- Askerler: gerçek insan oranları, düzgün (yumuşak) gölgelendirme, çok parçalı teçhizat.

## Mevzi'ye aktarılacaklar (öncelik sırası)
1. Yumuşak gölgelendirmeli, organik asker modelleri (lego görünümünün kaynağı düz gölgelendirmeydi).
2. Helikopter düşüşü: kontrolsüz dönüş + yavaşlayan pal + yere çarpma; dönen disk düşerken gizlenir.
3. Stres seviyeleri (sarsılmış / panik) ve kritik hasar türleri (hareket/optik/nişan/dolum) mevcut baskı ve palet sistemine eklenir.
4. 4 yönlü iki tip zırh + mesafeye bağlı delme.
5. kg cinsinden ikmal kutuları, üsse dönüş iadesi, konuşlanma aşaması, Fetih/Savaş Hedefleri modları.
6. Hava durumu ve gece.
