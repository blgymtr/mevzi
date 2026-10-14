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
