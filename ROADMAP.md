| 31 | Roketler havada önlenebilsin (dengeli) | ✅ | APS (Trophy/Afganit) %70 / üstten %15, 4 şarj; C-RAM inen mermide %35, 20 angajman (missiletest) || 15 | Hava araçları füzeden kaçınsın; gerçek füze türleri ve atış mekanizmaları | ✅ | Güdüm türleri (IR / tel / lazer hüzme / lazer işaretleme / radar), kilit süreleri, nişancı izleme prosedürü (bastırılınca sapma), görünür tel, füzeye göre fişeğe kanma; helikopter fişek + kaçış (missiletest, evadetest) |# MEVZİ — Yol Haritası ve Değişiklik Günlüğü

> Bu dosya projenin tek kaynağıdır: en üstte **yapılanların madde madde günlüğü**, ardından **0.0.8 (32 maddelik liste)** durumu ve fazları, en altta Steam'e hazırlık tabloları.

Ana test aracı: **Sandbox** (her yeni birim/yapı otomatik listelenir, sınırsız çıkarılır).
Takımlar: **Müttefikler vs Mihver** — uluslar: ABD, Rusya, Almanya, Birleşik Krallık, Türkiye. Şu an odak: **ABD vs Rusya**.
İlham: Broken Arrow (REA tasarım analizi), Sudden Strike 5, Men of War AS2, CoH 2/3, Red Alert tarzı RTS. Defilade'den farklı olmalı.

Durum: ✅ bitti · 🟡 kısmen · ⏳ yapılacak. Öncelik: **P0** (Steam'den önce şart) · **P1** (çıkışta olmalı) · **P2** (çıkış sonrası olabilir).

---

## 📒 Değişiklik günlüğü — yapılanlar (madde madde)
Her madde bir commit'e dayanır (`git log` ile doğrulanabilir). **Eklendi** = yeni özellik, **Düzeltildi** = hata giderimi, **Değişti** = mevcut özelliğin yenilenmesi.

### Temel sürüm (0.0.1 – 0.0.4) — 14 Ekim
- **Eklendi:** Kompakt alt panel (harita, seçim+emir, üretim), İngilizce dil, ayarlar menüsü
- **Eklendi:** CoH2/SS5/BA tarzı emirler — saldırı hareketi, hızlı hareket, geri vites, mevzi tut, geri çekil, ateş modu, duruş, el bombası, sis, baskı ateşi
- **Eklendi:** Ragdoll ölüm (verlet, silah ayrı düşer, patlamada savrulur)
- **Eklendi:** Teslim olma / esir alma / yürüyüşte istihbarat, sürüklenirken tabanca, sedyeciler (ölüleri de toplar), yakın dövüş, irkilme, alçak duvar atlama, kayarak siper, mermi için üsse dönme, zırhtan sekme
- **Eklendi:** Sandbox modu (sınırsız ikmal, birlik sınırı yok, imleçte birim/yapı/efekt, geliştirici konsolu), ekip lideri sınıfı
- **Eklendi:** Topçu sınıfları — sahra topu, çekili obüs, tanksavar topu, uçaksavar topu, ağır havan, dağ topu, roketatar, sahil topçusu, kundağı motorlu obüs; TOPÇU sekmesi, dolaylı atış
- **Eklendi:** Araç hasar modeli — palet kopması, teker patlaması, nişancı/sürücü vurulması (piyade yerine geçer), mürettebat kaybı, terk et + kendini imha; mürettebat/istihkâm onarımı
- **Düzeltildi:** Araçların köprüde takılması (eksene hizalanma), suya itilme
- **Eklendi:** Zırh 4 yön × kinetik/HEAT tablosu, silah delme profilleri, sekme, güdümlü tanksavar (ATGM), armortest
- **Eklendi:** Stres sistemi (sarsılmış/panik) + araç kritikleri (hareket/optik/nişan/dolum); oyun modları Fetih ve Savaş Hedefleri
- **Eklendi:** Lojistik — ileri üste kg ikmal stoğu, kamyon hattı, üste onarım, Üsse Dön (iade), konuşlanma aşaması
- **Eklendi:** Hava durumu + gece (yağmur, sağanak/nehir taşması, kum fırtınası, kar fırtınası/üşüme, gece görüşü)
- **Eklendi:** Gerçekçilik 1-3 — CC0 PBR araç/asker malzemeleri, bina sıva/tuğla/beton shader'ı, kiremit + kar, sivil araç modelleri, kış ağaçları
- **Eklendi:** Asker v3 / Blender asker üretici / iskeletli tek parça askerler (ABD OCP, Rus EMR)
- **Eklendi:** Araç kataloğu (ABD 87 + Rusya 83 birim), Blender araç üreticisi (palet baklaları, yürüyen aksam, RWS, APS, reaktif zırh)
- **Eklendi:** İHA keşif/silahlı/kamikaze, güdümlü tanksavar timi; her araç farklı imha (taret fırlaması, ikincil patlamalar, enkaz, krater); kör ateş, araç arkası siper

### 0.0.4 – 0.0.5 — 15 Ekim
- **Eklendi:** Girilebilir binalar (kapı/pencere, pencere başında siper, çatı kesiti, çökmede enkaz hasarı), garnizon
- **Eklendi:** Dinamik harita boyutu, Büyük Şehir haritası (512 m, ~110 girilebilir bina)
- **Eklendi:** Asker v4 (yumuşak gövde, açık yüz, kask, yelek)
- **Düzeltildi:** Araç–araç ve asker–araç iç içe girmesi (yönlü dikdörtgen ayrışma)
- **Eklendi:** Patlama/mermi efektleri (toprak tacı, ateş topu, mantar duman, yangın sütunu, roket izi)
- **Eklendi:** Kademeli kazılan siperler (kalas perde, kum torbası, toprak set)
- **Eklendi:** Avrupa cephe paleti, sıra evler, hasarlı çatılar, demiryolu, meydan, sokak lambaları (~190 bina)
- **Eklendi (hotfix 0.0.5):** Gerçek mermi modelleri (APFSDS/HE/havan/155/RPG/ATGM/el bombası), kan püskürmesi/lekesi, kompakt seçim halkası, büyük mini harita, görünür İHA, ağırlığa göre araç hızı, kurma-toplama süreleri, derin kraterler, tabanca/bıçak/sargı
- **Eklendi:** Yüzeye göre patlama çeşitliliği (su sütunu, kar/kum/beton), zırh içi kıvılcım, HEAT jeti; suda araç batar; piyade tank arkasında ilerler
- **Eklendi:** Yıkılabilir köprüler, IK ile iki elle silah tutuşu, ikmal kamyonunda hamallar
- **Eklendi:** Kargo helikopterleri (CH-47F / Mi-26 tipi), askıya alma, havadan ikmal paleti, irtifaya göre yer gölgesi
- **Eklendi:** Gerçekçi inşaat (alttan örülen duvar, iskele, 6 işçi yeri), bina döndürme (R / Shift+R)
- **Eklendi:** Bekleme (low ready) tutuşu, tabancayı kılıftan çekme/geri takma
- **Eklendi:** Roket topçusu kavisli izleri, cephane alev jeti

### 0.0.7 — 15 Ekim
- **Düzeltildi:** Araçlar askeri itmez (yavaşlar/durur, asker kenara çekilir)
- **Düzeltildi:** Patlamada çift ragdoll
- **Eklendi:** Gerçek ağaç modelleri (meşe, dişbudak, kavak, huş, söğüt, çam + kış ikizleri, 3 çalı), patlama şok dalgasında sallanma
- **Eklendi:** Drone operatörü — Mini Drone Kaldır (L) ve Drone İstasyonu Kur (O); operatör kendiliğinden drone kaldırmaz
- **Eklendi:** Bölgesel yaralar (bacak/kol/omuz/kafa/gövde) + hastaneye yürüme; lideri ölen tim başka time katılır
- **Eklendi:** SAM füzesi, fişek + kaçış manevrası; Hellfire / Vikhr / Hydra / SAM modelleri
- **Eklendi:** Halatla iniş (fast-rope) ve halatla çekme (SPIES)
- **Eklendi:** Araca kapıdan binme/inme; çekili top mürettebatı dolum döngüsü
- **Eklendi:** Paraşütçü timi (C-130/Il-76 tipi uçak, kubbe paraşüt)
- **Eklendi:** Görsel savaş sisi (keşfedilmemiş / görülmüş / görüş içi)
- **Eklendi:** Tim beyni (örtme ateşi, kanattan dolanma, binaya el bombası + baskın, roketten yana atılma), patikalar ve taş döşeme yollar
- **Eklendi:** 1 km / 2 km / 4×4 km haritalar; ağaç MultiMesh bankaları; numpy 3B gaz simülasyonu ile patlama/duman/toz flipbook'ları
- **Düzeltildi:** Flipbook kenarlarında dikdörtgen kesik görüntü
- **Eklendi:** Asker v5 (anatomik gövde, yüksek kesim kask, MOLLE, telsiz, turnike...); ot çeşitleri
- **Eklendi:** Ulus silahları (Blender): M4A1/ACOG/PEQ, M249, AT4, M110, M17 — AK-12, PKP, RPG-7, SV-98, PL-15
- **Eklendi:** Uzun yol bulma iş parçacığında (2 km+): grup emri 2–8 ms (önce 0,5–0,7 sn donma)
- **Eklendi:** Gerçek kaya modelleri + üretilmiş kaya dokusu, kışta karlı / yazın yosunlu kayalar; çakıllar da aynı modelden
- **Eklendi:** İskeletli animasyon hattı prototipi — MakeHuman (CC0) taban örgü + 35 kemikli iskelet + CMU mocap retarget → `assets/anim/soldier_anim.glb` (22 klip + tüfek üst gövde katmanı), Godot AnimationTree ön izlemesi; oyuna henüz bağlı değil (`docs/ANIM_PIPELINE.md`)
- **Eklendi:** Windows/GPU test çalıştırıcısı `tools/run_tests.ps1` (sahne başına süre sınırı, TIMEOUT/CRASH tespiti, özet tablo) ve devir notu `docs/DEVIR_NOTU.md`
- **Doğrulama durumu (dürüst not):** crewtest (top hedef almıyor), paratest (8 askerden 7'si indi) ve SPIES/evadetest testleri takıldı → kök neden ve kalıcı önlem çalışması sürüyor (aşağıda 0.0.8 Faz 0)

### 0.0.8 (yerel GPU oturumu, RTX 5060) — 15 Ekim
- **Düzeltildi (Faz 0):** crewtest / paratest / SPIES / evadetest takılmaları — yamalar uygulandı ve GPU'da doğrulandı: doğrudan atışlı araç (çekili top dahil) görmediği hedefe yaklaşır, dolaylı atışlı topçu gözcü ister; paraşüt çıkış noktaları kare süresinden bağımsız, dolu hücreye iniş yok, havada vurulan yaralı süzülerek iner; halat çekmede geciken beklenmez; test bekçisi (duvar saati + kare kilitlenmesi)
- **Düzeltildi:** Saldırı emrindeki helikopter hedefi ilk konumdan göremiyorsa (ağaç/bina) sonsuza dek asılı kalıyordu → hedef çevresinde 50° dönerek, mesafeyi daraltarak atış açısı arar
- **Eklendi (32):** Ana menü — Kampanya (Hazırlanıyor), Klasik Harita, Sandbox Test, Senaryo Oluşturucu, Ayarlar (Grafik/Ses/Oynanış/Klavye), Masaüstüne Çık (onaylı); tam tuş atama (çakışma denetimi, kalıcı)
- **Düzeltildi:** "Arayüz sesleri: kapalı" tüm savaş seslerini de susturuyordu
- **Eklendi:** Faction yapılarının Blender modelleri (karargâh, kışla, fabrika, helipad, hastane, ileri üs — ABD/Rus)
- **Değişti (10):** Araç kataloğunun tamamı (191 araç) yeni detay çekirdeğiyle yeniden üretildi (AO pişirme, bmesh; ortalama 13,6 K üçgen)
- **Eklendi (16):** 143 bina arketipi (köy, kasaba/şehir, sanayi, çöl, kış), harita üreticisinde deste mantığıyla yerleşim, editörde "BİNA (100+ TÜR)"
- **Düzeltildi:** Drone istasyonundan dev İHA kalkıyordu (temel "uav" tipi RQ-4 modelini 1,6 kat büyütüyordu) → mancınıkla atılan küçük taktik İHA (RQ-7 / Orlan-10 sınıfı), gerçek ölçekte
- **Değişti:** Tüm hava araçları gerçek boyutta (`data/real_dims.json` + `tools/size_audit.gd`; helikopterlerde rotor çapına göre, İHA/dolanan mühimmatta kanat açıklığı ve boya göre)
- **Düzeltildi (6/26):** Topçu/havan mermisi alçak yayla "taş atar gibi" uçuyordu → yüksek gerçekçi yörünge + hareket bulanıklığı izi; patlama molozu yuvarlak top değil köşeli parça
- **Test altyapısı:** testler oyun süresiyle sınırlı (hugetest, crewtest...), `shots/.gdignore`, yeni testler: para2test, ammotest, structtest denetimi, evadetest "engel halkası"; GPU'da tam paket (13 sahne) + arch/map/garrison/editor/roundtrip/cat testleri geçiyor
- **Kaldırıldı (34):** Tüm dini yapılar (8 arketip; minare, çan kulesi, alem, haç, apsis, soğan kubbe üreticileri) — bundan sonra oyunda hiçbir dini yapı yok
- **Değişti (34):** Avlu duvarları gelişigüzel: her binada değil (kasaba %22, çöl %25, sanayi %35, bazı evlerde hiç yok), kayık köşe, L/U biçim, gedik, yıkık bölüm, ara sıra çit
- **Düzeltildi (20):** Garnizondaki askerler pencere yuvalarına ulaşamıyordu (kapı boşluğu hücreleri piyadeye kapalıydı) → kapı yol hücreleri; erişilemeyen yuva 1006 → 65 (archtest garnizon denetimi)
- **Eklendi (Faz 0 ✅):** Takılma bekçisi — asker (8 sn'de yeniden yol, 30 sn'de emri bırakır), araç (15 sn'de geri çekilip yeniden yol, 45 sn'de bırakır), sedye (hastane yıkılır/ele geçirilirse yaralı bırakılır, 150 sn sınırı) (stucktest)
- **Eklendi:** Yapılamayan saldırı emrinde sesli uyarı + neden (menzil dışı, asgari menzil, görüş yok); kundağı motorlu top asgari menzilde geri çekilir, çekili top emri bırakır
- **Eklendi:** Ekransız test modu (`-Headless`, `tools/run_tests.sh`)
- **Düzeltildi (27):** Kendi aracının patlaması ve helikopterin düşüşü kendi askerine hasar veriyordu → yalnız bastırır; bina patlaması iki tarafa da hasar verir (fftest)
- **Eklendi (2):** Araç başına gerçek performans (`data/real_perf.json`): yol/arazi hızı, 0→32 km/h ivme (tekerlekli araç yolda hızlı), ana silah dolum süresi, otomatik top dakikada atım + seri boyu, roketatar salvosu, hava aracı seyir hızı (perftest)
- **Eklendi (6):** Mühimmat tablosu (`data/ammo.json`): kalibre başına gerçek namlu çıkış hızı, kütle, yakın/uzak delme, doğrudan hasar, patlama yarıçapı ve hasarı; ulusa göre iz rengi (NATO kırmızı-turuncu, Rus yeşil). 120 mm APFSDS T-72'nin önünü deler, 30 mm M1'in önünü delemez, 203 mm 9 m patlama (ammotest)
- **Eklendi (15):** Gerçek füze türleri ve atış prosedürü — ateşle-unut kızılötesi (Javelin, Stinger, Igla, Verba), tel güdümlü (TOW, Konkurs, Metis), lazer hüzme binici (Kornet, Refleks, Arkan, Vikhr), lazer işaretlemeli (Hellfire), radar güdümlü SAM. Nişan/kilit süresi füzeye göre (Javelin ~4 sn, Kornet 1,5, RPG 1,3, Stinger 3, Verba 2,5); tel/hüzme/işaretleme füzesinde nişancı hedefi izlemeli — bastırılır, ölür, görüş kesilir ya da tel biterse füze sapar; tel güdümlüde görünür tel; fişeğe kanma füzeye göre (Stinger %45, Igla %35, Verba %15, radar %5-10); füze hızları ve delme/hasar modele göre (missiletest)
- **Eklendi (31):** Havada önleme (dengeli) — aktif koruma (Trophy / Afganit: M1A2 SEP v3, M1E3, T-14, Kurganets) yaklaşan RPG/füzeyi ~%70 olasılıkla vurur, üstten saldırıda %15, 4 şarj; C-RAM (Centurion) inen havan/topçu/roket mermisini %35 olasılıkla düşürür, 20 angajman (missiletest)
- **Eklendi (49):** Gerçek menziller — `data/real_combat.json` (üretici `tools/gen_combat.js`): 197 birimin her silahı için gerçek etkili menzil (ana top, güdümlü füze, otomatik top, makineli, roket, hava savunma, dolaylı atış); ör. M1A2 SEP v3 4000 m, T-72B3M 3000 m + namludan füze 5000 m, Bradley 25 mm 2200 m + TOW 3750 m, Kornet 5500 m, Javelin 2500 m, AH-64 Hellfire 8 km, M109A7 30 km, S-400 250 km (harita köşegeniyle sınırlı). Piyade silahları ulusa göre (M249 800 / PKP 1000, AT4 300 / RPG-7 400). Her silah kendi menzilinde ateş eder (PSA hedef otomatik top menzili dışındaysa füze atar). Atış kontrolü gerçekçi: termal nişangâhlı top 2 km'de ~1 m dağılır, hareketli hedefe öndeleme; topçu dağılımı menzilin ~%1,2'si. Mermi/füze hızları gerçek (rangetest)
- **Değişti (49): Harita ölçeği** — 8 km haritada menzil, görüş ve mermi hızı tam gerçek; küçük haritalarda aynı oranlarla küçülür (256 m 0,07 · 1 km 0,2 · 2 km 0,35 · 4 km 0,59 · 8 km 1). Silahlar arası oranlar her haritada gerçek (tank topu piyade tüfeğinin ~7 katı)
- **Eklendi (50):** Gerçekçi tespit (takım görüşü): gözcü optiği (çıplak göz, dürbün, gündüz nişangâhı, termal 2. ve 3. nesil, İHA, radar) × hedef izi (gerçek W×H boyutu; ayakta / çömelik / yüzüstü; hareket; ateş anında namlu alevi ve toz; bina içi, siper, orman/çalı örtüsü) × hava/gece (termal az etkilenir) + görüş hattı; hava hedefini radar uzaktan görür; görülen hedef 2 sn hafızada. Eskiden görüş yalnız mesafeydi (görüş hattı, gizlenme, optik yoktu) ve 125 m ile sınırlıydı (spottest)
- **Eklendi (51):** Her birimin kendi zırhı ve canı: kinetik/HEAT × ön/yan/arka/üst gerçek RHA eşdeğeri (M1A1 ön 600/1000 mm, T-90M ön 720/1250 mm, BMP-2 ön 35 mm, MT-LB 14 mm...); delme değerleri gerçek ölçekte (M829A3 800 mm, 3BM60 700 mm, 30 mm APDS 85 mm, RPG-7 500 mm, Kornet 1200 mm, Javelin üstten) ve mesafeyle (2 km) düşer; delen ana top/füze isabeti ağır hasar (ör. Kornet 520). Piyadede yelek: plakalı yelek gövde isabetinde tüfek mermisini çoğunlukla durdurur, nişancı/makineli kısmen; yumuşak yelek (nişancı, mürettebat) yalnız parçacığa
- **Eklendi (43):** Savaş sisi görüş çokgenleri: her birimin (piyade timi tek) gözünden ışınlarla — orman, bina, yüksek duvar görüşü keser; kenarlar yumuşak; yarıçap birimin optiğiyle açıktaki piyadeyi seçebildiği mesafe; havadaki gözcü engelsiz. Büyük haritada 4 m/piksel doku
- **Test altyapısı:** sahne testleri başlangıç birliksiz (gerçek menzilde karargâhtaki tank ortadaki deney birliklerini vuruyordu); yeni rangetest, spottest
- **Eklendi (21/53):** **Büyük Muharebe haritası (8×8 km)** — kuzeyden güneye kıvrılan nehir cepheyi ikiye böler (batı RUS, doğu ABD); merkez kasaba iki yakada sokak ızgarası + köprü + meydan + sanayi; iki yan kasaba, on üç yol köyü, kırk çiftlik; büyük ormanlar (kapalı tepe örtüsü), koruluklar, kıyı ormanı, ağaç sıraları; tarla deseni; demiryolu ve istasyon; altı geçit, sekiz hedef bölgesi (A–H), on altı ileri üs noktası. 1250 bina, ~75 bin ağaç/çalı; yükleme 24 sn (ilerleme çubuklu ekran)
- **Eklendi (21):** Stratejik yakınlaştırma (8 km'de 2,4 km görüş) ve NATO tipi birlik simgeleri: dost mavi dikdörtgen / düşman kırmızı eşkenar dörtgen; piyade, zırh, mekanize, motorlu, topçu, roketatar, tanksavar, hava savunma, helikopter, İHA, ikmal, sıhhiye, istihkâm sembolleri; tim başına tek simge + kişi sayısı, can çubuğu, simgeye tıklayarak seçim; hedef bölgeleri harf ve sahip rengiyle (icontest)
- **Değişti (21):** Büyük harita motoru — arazi dokuları parçalı (iz/krater/siper yalnız değişen parçayı yükler; eskiden her patlamada 16 MB'lık tam doku), arazi karoları tek ortak örgü + yakınlaştırmaya göre seyrek örgü (4 km'de ~1,2 GB VRAM boşa gidiyordu), su yüklemesi 4 sn → 0,2 sn, otomatik köprü yerleşimi 16 sn → 1 sn, ızgara ham yükseklikleri bayt, görüş hattı iri hücreli (uzun ışında 10 kata kadar hızlı, sonuç birebir aynı — lostest)
- **Eklendi (21):** Uzak görüş ayrıntı düzeyi: ağaçlar hafif taç modeline, bina blokları düz kutuya geçer (2 km görüşte 33 → 112 FPS); ot yalnız kameranın çevresinde üretilir (akışlı), uzakta ot/çakıl gizlenir
- **Eklendi (46):** Tarla deseni: bölge bölge yola hizalı şeritler — buğday, yeşil ekin, sürülmüş toprak, çayır; ekim/sürüm sıraları, aralarında sınır şeridi; orman zemini (uzaktan koyu yeşil kütle okunur)
- **Düzeltildi (42):** Nehirde durduk yere çıkan duman kaldırıldı; su yüzeyi nehir boyunca akar (akış yönü nehri izler, ortada hızlı kıyıda yavaş, iki evreli akış haritası); su yalnız nehir şeridinde çizilir
- **Değişti (41, kısmen):** Gölge mesafesi basamaklı — yakınlaştırırken sürekli değişip gölgeleri kaydırmıyor
- **Test altyapısı:** mapprof (yükleme aşamaları, bellek/VRAM, yakınlaştırmaya göre çizim yükü ve ot/gölge/ağaç/bina dökümü, harita görünümleri), lostest, icontest; `run_tests.ps1 -Extra` (ör. `--map=battle_8k`); tactest sabit tohum (rastgele haritada görüş hattı kapanınca takılıyordu)
- **Eklendi (26):** İz kalınlığı ve kuyruk boyu kalibreye göre (tüfek ince/kısa, makineli orta, 12,7 mm ve otomatik top kalın, tank topu kalın/uzun/parlak; nişancı izi soluk). Yerden atılan RPG, tanksavar füzesi ve roketatar roketinde motor alevi + çevreyi aydınlatan ışık, tanksavar füzesinde kuyruk iz fişeği — kurşun ve roket artık açıkça farklı (ammotest gece görüntüsü)

---

## 🎯 0.0.8 — 32 maddelik büyük güncelleme (kullanıcı listesi, 15 Ekim)
Durum: ✅ bitti · 🟡 kısmen var (temel mevcut, istek tam karşılanmadı) · ⏳ yapılacak · 🔄 şu an çalışılıyor.
(Listede 4. madde yok; numaralar kullanıcının listesindeki gibi korundu. 33–58: 15 Ekim yerel oturumunda kullanıcının ek istekleri.)

| # | İstek (özet) | Durum | Mevcut durum → yapılacak |
|---|---|---|---|
| 1 | Asker modelleri 1-2. fotoğraftaki gibi (gerçekçi oran, kıyafet katmanları, teçhizat) | ⏳ | v5 var ama stilize. → Gerçek insan taban modeli (MakeHuman CC0) + Blender'da katmanlı üniforma/teçhizat, PBR doku |
| 2 | Her aracın hızı farklı ve gerçekçi; hava araçları; atış hızları | ✅ | `data/real_perf.json`: araç başına gerçek yol/arazi hızı, 0→32 km/h ivme, ana silah dolumu, otomatik top dakikada atım/seri, roketatar salvosu, hava aracı seyir hızı (kara ×0,5, hava ×0,25 ölçek); tekerlekli araç yolda hızlı (perftest) |
| 3 | Palet/teker/motor arızası + istihkâm tamir animasyonu; daha önce hasar alan daha kolay hasar alır (dengeli) | 🟡 | Palet/teker kopması ve onarım var. → Motor arızası, birikimli yıpranma katsayısı, istihkâm tamir animasyonu (alet, eğilme, kıvılcım) |
| 5 | Seçim göstergesi: daha küçük, estetik, kendi tarzımız | 🟡 | Kompakt halka var. → Özgün tasarım (köşeli parantez + rol işareti, takım rengi), RA/SS/CoH analiziyle |
| 6 | Tüm mühimmatlar gerçekçi: hız, boyut, çarpma, patlama, atış hızı — her araç ve silah | ✅ | `data/ammo.json`: kalibre başına namlu çıkış hızı, kütle, delme, hasar, patlama yarıçapı; ulusa göre iz rengi; araç → mühimmat eşlemesi (ammotest) |
| 7 | Havan, top, obüs ve kurmalı ekip animasyonları | 🟡 | Çekili top dolum döngüsü var (doğrulama sürüyor). → Havan timi, obüs, ağır silah kurma/sökme/dolum animasyonları |
| 8 | Drone: havada görünmeme düzeltmesi, irtifa gölgesi, drone sesi, kalkış/inişte dönen pervane, 2 kişilik operatör (istasyoncu + kumandalı pilot), drone türüne göre istihbarat | 🟡 | Mini drone + istasyon var; istasyon artık gerçek ölçekte küçük taktik İHA kaldırıyor ✅. → Ses, pervane, 2 kişilik ekip, türe göre görüş/tespit |
| 9 | Vurulma yerine göre kan, patlamada uzuv kopması, sağlık çadırı/hastane/paramedikte ilk yardım, timleri isteğe göre birleştirme (tim+tim=manga) | 🟡 | Kan, bölgesel yara, hastane var. → İsabet bölgesine göre kan, uzuv kopması, ilk yardım animasyonu, oyuncu kontrollü tim birleştirme |
| 10 | Araç modelleri çok detaylı (teker, kapak, yakıt deposu, namlu, zırh, renk) — EN KRİTİK KURAL | 🟡 | Katalog (191 araç) detay çekirdeğiyle yeniden üretildi ✅. → Taban tip modelleri (tank_blue vb.), gerçek boyut (38) |
| 11 | Tank mürettebatı inip binebilsin (dismount/mount) | ⏳ | → Mürettebat ayrı askerler olarak iner/biner, araç mürettebatsız hareket etmez |
| 12 | İmha mermi türüne göre değişsin: yan yatma, farklı yönde taret fırlaması, çakılma | 🟡 | Taret fırlaması, ikincil patlama var. → Fizik tabanlı imha (devrilme, taret yörüngesi, mermi türü/açıya göre) |
| 13 | Nadir teslim olma: beyaz bayrak, silah zoruyla karargâha götürülme | 🟡 | Teslim olma/esir var. → Beyaz bayrak modeli, eller havada yürüme, muhafız silahı doğrultarak eşlik |
| 14 | Patlama bulutu yarı saydam; suya düşüşte araç boyutuna göre dalga | 🟡 | Yarı saydam duman var. → Bulut saydamlığı, boyuta göre dalga halkası (su shader'ı) |
| 15 | Hava araçları füzeden kaçınsın; gerçek füze türleri ve atış mekanizmaları | 🟡 | SAM + fişek + kaçış var. → Stinger/Igla/Verba/Javelin/Kornet/TOW vb. arayıcı türleri, kilitlenme süresi, atış prosedürü |
| 16 | 100+ farklı bina, yıkılabilir köprüler, ağaç/çiçek/kaldırım/kapı/pencere/sokak/başıboş araç/direk — tam detay | 🟡 | 143 bina arketipi ✅, köprüler var. → 34 (dini yapı yok, duvarlar), 35 (özgünlük), sokak eşyaları |
| 17 | Asker modeli fotoğraftaki gibi + her eylem için animasyon (düşme, eğilme, zıplama, koşma...) | ⏳ | → 1 ve 25 ile birlikte: iskeletli animasyon kütüphanesi |
| 18 | Araçlar 3. fotoğraftaki gibi gerçekçi (mürettebat görünür, açık bölme) | ⏳ | → Kundağı motorlu topçuda açık bölme + içeride çalışan mürettebat |
| 19 | Animasyon için kendi sistemimiz (Unreal ile) | ⏳ | → Bkz. teknik not: Blender + mocap tabanlı kendi animasyon hattımız |
| 20 | 4. fotoğraftaki gibi keskin hatlı, girilebilir, çatısı detaylı binalar | 🟡 | Çatı eşyaları var; girilebilirlik düzeltildi (kapı yol hücreleri: erişilemeyen pencere yuvası 1006 → 65). → Kalan 10 tür (istasyon, kültür merkezi, karakol kulesi...), fotoğraftan farklılaştırma (35) |
| 21 | Harita boyutları büyütülecek — **öne alındı:** gerçek muharebeye yetecek büyüklükte, büyük savaş mekanizmasına uygun harita; bundan sonra her şey bu haritada test edilecek, ardından özel haritalar (48) | 🔄 | **Büyük Muharebe 8×8 km** ✅ (motor, stratejik görüş, simgeler, tarla/orman, yükleme ekranı). → Kalan: YZ'nin büyük haritada ilerleyişi, mini harita, yol bulma ızgarası belleği (2,5 GB), 49/50 ile gerçek menzil ve görüş |
| 22 | Helikopter alçaldıkça pervane sesi artsın, rotor rüzgârı ağaç/çimen sallasın | ⏳ | → Global shader rüzgâr kaynağı (patlama dalgası sistemi gibi), irtifaya bağlı ses |
| 23 | Palet izi; iklime göre kalıcı/kaybolan; savaş sisine uyumlu | ⏳ | → Arazi iz dokusu, biyoma göre sönüm, görülmeyen izler gizli |
| 24 | Gerçekçi 3B alev, roketin poddan çıkışı vb. (dengeli) | 🟡 | → Hacimli alev flipbook'u, pod çıkış duman/alev |
| 25 | Tüm asker animasyonları: tutuş, ateş, şarjör, silah değiştirme, siper, sürünme, atlama, depar, tetikte yürüme, araç arkasında yürüme | 🟡 | Kodla poz + IK var. → Keyframe/mocap klipleri |
| 26 | Mühimmat efektleri için gerekli programları kur, test et; kurşun ve roket farklı görünsün | ✅ | İz boyutu kalibreye göre; yerden atılan roket/füzede motor alevi + ışık, füzede iz fişeği (ammotest) |
| 27 | Kendi araç patlaması/düşüşü kendi askerine zarar vermesin; bina patlaması iki tarafa da zarar verir | ✅ | G.explode spare: araç imhası / helikopter düşüşü kendi askerine hasar vermez (bastırır); bina patlaması herkese (fftest) |
| 28 | İnşaatta her asker kutudan malzeme alıp taşır, bırakır, farklı animasyonla çalışır | 🟡 | 6 işçi yeri var. → Kutu alma/taşıma/bırakma döngüsü |
| 29 | Bazı İHA/drone'lar görünmüyor; özel sesler; yüksek irtifa | 🟡 | → 8 ile birlikte |
| 30 | 9×9 / 9×6 km haritalar, 30+ harita, Senaryo; radar araçları, S-300 tipi radar+SAM, uçaklar; **Mevzi-Core**: oyuncu kontrolünde olmayan birimlerin gerçekçi doktrinle davranışı | 🟡 | 4 km harita, tim beyni var. → Mevzi-Core tasarımı (bölgesel komuta, birim rolleri, angajman kuralları), radar/SAM katmanı |
| 31 | Roketler havada önlenebilsin (dengeli) | ⏳ | → APS / C-RAM tipi önleme, düşük olasılıklı |
| 32 | Ana menü: Masaüstüne Çık · Ayarlar (Grafik, Ses, Oynanış, Klavye) · Senaryo Oluşturucu · Kampanya · Klasik Harita · Sandbox Test | ✅ | Menü + tuş atama birleştirildi (keybinds_test 55/55, menü ön izlemesi TR/EN) |
| 33 | Bayrak animasyonu (Blender + UE) | ⏳ | → Blender kumaş simülasyonu pişirilir (köşe animasyon dokusu), Godot'ta rüzgârla oynatılır. UE kurulu değil; istenirse yalnız pişirme istasyonu olabilir |
| 34 | Oyunda cami/kilise/mescit vb. hiçbir dini yapı olmayacak; her binanın yanında duvar olmasın, duvarlar gelişigüzel | ✅ | 8 dini arketip + minare/çan kulesi/alem/haç üreticileri silindi; avlu duvarları seyrek ve gelişigüzel (L/U, gedik, yıkık, eğri) |
| 35 | Binalar referans fotoğraflardan biraz farklı olsun (aynısı değil) | ⏳ | → Oran, renk, cephe düzeni, çatı ve detay çeşitlemesi |
| 36 | Kum torbaları gerçekçi (web'den CC0 varlık ya da kendi üretimimiz) | ⏳ | → Blender'da torba modeli (kumaş dokusu, sarkma, dikiş), şaşırtmalı dizim |
| 37 | Kazma ve inşaat animasyonları: silah sırtta, binanın içine girmeden dışarıdan inşa (hata var) | ⏳ | → İnşaat yuvaları iskele dışında, tüfek sırtta, kazma/kürek/çekiç aleti |
| 38 | Tüm araç boyutları gerçekçi | 🟡 | Hava araçları ✅ (`data/real_dims.json` + `tools/size_audit.gd`). → Kara araçlarında 42 sapma: namlu boyu, kamyon şasisi, köprü/dozer |
| 39 | Helikopter pervaneleri gerçekçi, detay dokulu | ⏳ | → Kanat profili, uç bandı, hub; dönüşte hareket bulanıklığı diski |
| 40 | Hiçbir mermi yuvarlak top/taş gibi görünmesin | ✅ | Topçu/havan yüksek yörünge + iz, moloz köşeli parça (ammotest) |
| 41 | Köprüler gerçekçi olsun ve hasar alsın; uzaklaşınca (zoom out) gölgeler kayıyor/parlıyor | ⏳ | → Köprü modeli (ayak, kiriş, korkuluk, hasar durumları); yönlü gölge mesafesi yakınlaştırmaya göre basamaklı + sapma ayarı |
| 42 | Harita başlayınca nehirde durduk yere duman çıkıyor → kaldırılacak; nehre gerçekçi akış | 🟡 | Duman kaldırıldı ✅, su nehir boyunca akıyor ✅. → Köprü ayağında girdap, akıntıyla taşınan köpük çizgileri |
| 43 | Savaş sisi gerçekçi: karemsi değil, birliklerin görüşüne göre değişsin | ✅ | Görüş çokgenleri (orman/bina/duvar keser), yumuşak kenar, optiğe göre yarıçap, büyük haritada 4 m/piksel |
| 44 | Helikopter pervaneleri mutlaka görünsün (sesler en son, ama sistem buna uygun) | ⏳ | → 39 ile birlikte: dönen kanat her zaman görünür (kanat + bulanık disk), rotor devri ses için hazır değişken |
| 45 | Soldaki bilgilendirmeler daha estetik | ⏳ | → Bilgi/olay paneli yeniden tasarım (tipografi, ikon, kart, solma) |
| 46 | Harita daha estetik | 🟡 | Tarla deseni, orman zemini, yol köyleri ✅. → Arazi dokusu ve renk paleti, kıyılar, yol kenarları, bitki dağılımı, ışık/atmosfer |
| 47 | Roadmap bitince genel kalite turu: grafik ayarlarıyla hata kontrolü, sandbox'ta tüm yapılar, tüm animasyonlar (model güncellemesi sonrası), büyük haritada oyuncu gibi uzun ve gerçekçi maç (maç süresi ölçülür), olası hataların bulunup engellenmesi | ⏳ | → Faz 7 |
| 48 | Büyük haritadan sonra özel (custom) haritalar | ⏳ | → Faz 6: editörle yeni haritalar |
| 49 | Her aracın (ve silahın) menzili kontrol edilecek, gerçekçi olacak | ✅ | `data/real_combat.json`: 197 birim × silah başına gerçek menzil; harita ölçeği (8 km'de tam gerçek); silah başına menzil kapısı, gerçek atış kontrolü ve öndeleme, gerçek mermi/füze hızları (rangetest) |
| 50 | Araçların birbirini görme kapasitesi kontrol edilecek (hata varsa düzeltilecek) | ✅ | **Hata düzeltildi:** görüş yalnız mesafeydi (görüş hattı/gizlenme/optik yok, 125 m sınırı). → Optik × hedef izi × görüş hattı × gece/hava, radar, tespit hafızası (spottest) |
| 51 | Her birimin canı ve zırhı farklı olacak, sisteme uyarlanacak | ✅ | Birim başına gerçek zırh (mm RHA, 4 yön × kinetik/HEAT) ve can; gerçek delme ve mesafe düşüşü; piyadede plakalı/yumuşak yelek |
| 52 | Bina yıkımı "lego gibi" — çok daha gerçekçi olacak | ⏳ | Bloklar tek tek düşüyor. → Kırık kenarlı duvar levhaları, kat kat çökme, toz bulutu, moloz yığını ve kalıcı yıkıntı, kısmi hasar (delik, çatlak, açılmış cephe) |
| 53 | Büyük haritalar Broken Arrow / CoH3 büyüklüğünde ve detayında | ⏳ | → 21 ile birlikte: 8×8 km, stratejik yakınlaştırma + birim simgeleri, gerçek yer düzeni, yoğun detay |
| 54 | **Kritik:** modellerle ilgili tüm maddeler eksiksiz yapılacak | ⏳ | → 1, 10, 12, 13, 17, 18, 33, 35, 36, 38, 39/44 — her biri kendi fazında, atlanmadan |
| 55 | Performans iyileştirmeleri | ⏳ | → Faz 7 |
| 56 | Ses efektleri | ⏳ | → Faz 7 (helikopter rotor devri ses için hazır tutulur) |
| 57 | Genel HUD/arayüz yenilemesi ve buna yönelik hata avı | ⏳ | → Faz 7 (45 ile birlikte) |
| 58 | Kayıt sistemi aktif: oyunu kaydet / yükle, otomatik kayıt | ⏳ | → Faz 7 |

### Uygulama sırası (fazlar)
- **Faz 0 — Stabilite ✅:** yamalar + test bekçisi, crewtest/paratest/SPIES/evade; takılma bekçisi (asker/araç/sedye, stucktest); yapılamayan emirde sesli uyarı; ekransız test (-Headless, run_tests.sh)
- **Faz 1B — Büyük muharebe haritası (öne alındı, 🔄):** 21/53 — önce motor (ızgara, arazi, su, kamera, simgeler), sonra 49/50/51 ile birlikte harita içeriği ve YZ; bundan sonra her madde bu haritada da test edilir
- **Faz 1 — Veri gerçekçiliği (🔄):** 2 ✅, 27 ✅, 6 ✅, 26 ✅, 49 ✅, 50 ✅, 51 ✅, 15 ✅, 31 ✅, 38
- **Faz 2 — Araç sistemleri:** 3, 11, 12, 23, 22, 39/44, 8/29, 18, 7
- **Faz 3 — Asker yeniden yapımı:** 1, 17, 19, 25, 9, 13, 28/37, 5
- **Faz 4 — Dünya ve görsel:** 34 ✅ (öne alındı), 42, 43, 46, 52, 10, 16, 20, 35, 36, 33, 14, 24, 41
- **Faz 5 — Menü ve çekirdek:** 32, 30 (Mevzi-Core, radar/S-300)
- **Faz 6 — Haritalar:** 30 (9×9 km ve 30+ harita), 48 özel haritalar
- **Faz 7 — Genel kalite turu (roadmap bitince):** 47, 55 performans, 56 ses efektleri, 57/45 HUD/arayüz + hata avı, 58 kayıt sistemi — grafik ayarları × hata kontrolü, sandbox'ta tüm yapılar, tüm animasyonlar, büyük haritada uzun gerçekçi maç ve süre ölçümü
- **Model maddeleri (54, kritik):** 1, 10, 12, 13, 17, 18, 33, 35, 36, 38, 39/44 hiçbiri atlanmayacak

### Teknik not: Unreal Engine ve animasyon hattı (dürüst değerlendirme)
- Bu bulut ortamında Unreal Engine kurulamaz: Epic hesabı ile indirme gerekiyor, ağ yalnız GitHub/npm/PyPI'ye açık, GPU yok. Kurulsaydı bile Niagara efektleri ve UE animasyon sistemi Godot'a taşınamaz; yalnız pişirilmiş çıktı (flipbook PNG, FBX/GLB animasyon klibi) taşınabilir.
- **Kendi sistemimiz:** Blender (kurulu, Python ile otomatik) + MakeHuman CC0 insan taban modeli + CMU hareket yakalama verisi (ticari kullanım serbest, BVH) → iskelete yeniden hedefleme → GLB animasyon klipleri → Godot AnimationTree (karıştırma, katman: üst gövde silah / alt gövde hareket). Bu hat 1, 17, 19, 25 maddelerinin omurgası.
- İstenirse UE senin Windows makinende "pişirme istasyonu" olarak kullanılabilir (efekt flipbook'u veya animasyon FBX'i dışa aktarıp depoya koyarsın, biz entegre ederiz).

---


## A. Çekirdek oynanış
| | Öğe | Durum |
|---|---|---|
| P0 | Seçim, sürükle-seç, kontrol grupları (Ctrl+1-9), çift tık ile aynı türü seç | 🟡 (kontrol grupları kontrol edilecek) |
| P0 | Emirler: hareket, hızlı, saldırı hareketi, geri vites, dur, mevzi tut, geri çekil, ateş modu, duruş, indir, el bombası, sis, baskı ateşi, terk et, iade | ✅ |
| P0 | Formasyonlar (hat, kol, kama) + sağ tık sürükleyerek yön/genişlik (CoH/SS5) | ⏳ |
| P0 | **Binaya girme / garnizon** (pencereden ateş, kat bonusu, bina yıkılınca dışarı) | ✅ |
| P0 | Araçlara binme/inme, yolcu taşıma | ✅ |
| P0 | Siper, örtü, baskı, stres (sarsılmış/panik) | ✅ |
| P0 | Zırh 4 yön × kinetik/HEAT, delme, kritik hasar | ✅ |
| P0 | Görüş hattı + savaş sisi (birim bazlı), duman görüşü keser | ✅ |
| P1 | Gizlilik: hareketsiz/çalılıkta görünmezlik, ateş edince açığa çıkma (BA optik/stealth) | 🟡 (gece/havada var) |
| P1 | Keşif birimleri, dürbünlü gözcü, yüksek zemin görüş bonusu | ⏳ |
| P1 | Topçu çağrısı / hava desteği (yetenek ağacı, puanla) | ⏳ |
| P1 | Havadan ikmal + paraşütçüler | 🟡 (paratest doğrulaması sürüyor) |
| P1 | Mayın döşeme/temizleme, istihkâm köprü kurma | 🟡 (tank tuzağı var) |
| P2 | Kuşatma/teslim alma, esir değişimi | 🟡 |

## B. Birimler ve içerik
| | Öğe | Durum |
|---|---|---|
| P0 | Piyade sınıfları: tüfekçi, lider, makineli, tanksavar, sıhhiye, keskin nişancı, istihkâm, havan, drone, mürettebat | ✅ |
| P0 | Tim şablonları: kışlada "TİM" sekmesi, kendi timini tasarla, hazır timler | ⏳ |
| P0 | ABD ve Rusya için ayrı asker modelleri (üniforma, yelek, kask) | ✅ (v3 faset) |
| P0 | Ulusa özel silahlar (M4/AK-12, M249/PKP, AT4/RPG, M2/Kord, tabanca) — Blender | ✅ (M2/Kord hariç) |
| P1 | Araç listeleri: 50+ kara, 50+ hava (veri kataloğu: DEF + zırh + delme + maliyet) | ⏳ |
| P1 | 14 helikopter tipi (jenerik adlar) | ⏳ |
| P1 | Uçaklar: yakın hava desteği, keşif, kargo | ⏳ |
| P2 | Almanya, Birleşik Krallık, Türkiye setleri | ⏳ |

## C. Harita ve dünya
| | Öğe | Durum |
|---|---|---|
| P0 | **Büyük harita** (≥ 1 km, MP'de ≥ 20 dk) — ızgara/yol bulma/arazi akışı ölçeklenecek | ✅ (1/2/4 km; 9 km en son) |
| P0 | Binalar Blender'da yeniden: kırsal ev, apartman, dükkân, ahır, cami/kilise, fabrika, benzinlik — iç mekân + kırılabilir parçalar | ⏳ |
| P0 | Yapılar Blender'da: üs, ileri üs, kışla, fabrika, pist, hastane, MG yuvası, kule, siperler | ⏳ |
| P0 | Harita öğeleri Blender'da: ağaç, çalı, çit, duvar, elektrik direği, köprü, araç enkazı, saman, kaya | 🟡 |
| P1 | Yollar/şehir dokusu: kavşak, kaldırım, sokak lambası, tabela | 🟡 |
| P1 | Biyomlar: ılıman, çöl, kış (+ sonbahar, şehir) | 🟡 |
| P1 | Yıkım: bina parça parça çöker, enkaz siper olur, krater kalıcı | 🟡 |
| P1 | Harita editörü + senaryo editörü | ✅ |
| P2 | Prosedürel harita üretici seçenekleri | 🟡 |

## D. Oyun modları ve ekonomi
| | Öğe | Durum |
|---|---|---|
| P0 | Klasik (üs yıkımı), Fetih, Savaş Hedefleri | ✅ |
| P0 | Konuşlanma aşaması | ✅ |
| P0 | Lojistik: kg stok, kamyon hattı, mühimmat, onarım, iade | ✅ |
| P1 | Deste/kart sistemi (BA): maçtan önce birlik destesi kur | ⏳ |
| P1 | Yetenek/destek ağacı (CoH komutan) | ⏳ |
| P1 | Seferberlik (kampanya): bağlı görevler, birlik deneyimi taşınır | ⏳ |
| P1 | Eğitim görevi | ⏳ |
| P2 | Hayatta kalma / savunma dalgaları | ⏳ |

## E. Yapay zekâ
| | Öğe | Durum |
|---|---|---|
| P0 | Üs kurma, üretim, saldırı dalgaları, bölge hedefleme | ✅ |
| P0 | Zorluk seviyeleri | ✅ |
| P1 | Kanat saldırısı (zırhın arkasına dolaşma), zayıf noktayı seçme | ⏳ |
| P1 | Birim karşı-seçimi (tanka tanksavar, piyadeye makineli) | 🟡 |
| P1 | Savunma hattı kurma, geri çekilip yeniden toplanma | 🟡 |

## F. Görsel ve ses (polish)
| | Öğe | Durum |
|---|---|---|
| P0 | Patlama/atış efektleri (kalibre × yüzey matrisi, kalıcı duman, kıvılcım, şok tozu) | 🟡 |
| P0 | Hava durumu + gece | ✅ |
| P0 | Ölüm: ragdoll, kan, ceset kalıcılığı | ✅ |
| P1 | Asker animasyonları: yürüyüş döngüsü, nişan, şarjör değiştirme, bomba atma, binaya girme | 🟡 (kodla poz) |
| P1 | Araç fizikleri: süspansiyon, palet izi, çamur, devrilme | 🟡 |
| P1 | Ses: silah başına ses, uzaklık/yankı, telsiz konuşmaları (TR/EN), müzik | 🟡 |
| P2 | Ölüm kamerası / sinematik tekrar | ⏳ |

## G. Arayüz ve kullanılabilirlik
| | Öğe | Durum |
|---|---|---|
| P0 | Kompakt alt panel, üretim, emir ikonları, mini harita | ✅ |
| P0 | Ayarlar: grafik, ses, tuş atama, dil, arayüz ölçeği | 🟡 (tuş atama yok) |
| P0 | Kayıt / yükleme (çatışma + senaryo) | ⏳ |
| P0 | Duraklatma menüsü, maç sonu istatistik ekranı | 🟡 |
| P1 | Birim kartları (zırh, delme, menzil grafiği) | 🟡 |
| P1 | İpuçları, ilk oyun rehberi | ⏳ |
| P1 | Erişilebilirlik: renk körü takım renkleri, yazı boyutu | ⏳ |
| P1 | İngilizce + Türkçe tam çeviri | ✅ |

## H. Teknik
| | Öğe | Durum |
|---|---|---|
| P0 | Performans: 300+ birimde 60 FPS (LOD, çoklu örnek, yol bulma bütçesi) | ⏳ |
| P0 | Otomatik testler (sahneler) | ✅ |
| P0 | Çökme raporu, log | ⏳ |
| P1 | Çok oyunculu: LAN + Steam (GodotSteam), kilit adımlı veya sunucu yetkili | ⏳ |
| P1 | Steam başarımları, bulut kayıt | ⏳ |
| P2 | Mod desteği (birim kataloğu JSON, harita paylaşımı / Workshop) | ⏳ |

## I. Steam yayını
| | Öğe | Durum |
|---|---|---|
| P0 | Mağaza sayfası: kapsül görseller, 5+ ekran görüntüsü, fragman, açıklama TR/EN | ⏳ |
| P0 | Steamworks: uygulama kimliği, depot, sürüm kanalları | ⏳ |
| P0 | Lisans/telif: tüm varlıklar kendi üretimimiz veya CC0 (kaynak listesi) | 🟡 |
| P1 | Erken erişim planı, yol haritası sayfası, Discord | ⏳ |

---


## Hotfix 0.0.5 — kalanlar (kullanıcı listesi)
- [x] Gerçek mermi modelleri (APFSDS, HE, havan, topçu, RPG, ATGM, el bombası), ince iz
- [x] Kan (isabet püskürmesi, yer lekesi, sürüklenme izi)
- [x] Seçim halkası küçük/kompakt; konuşma balonları seyrek
- [x] Mini harita büyük, renkli, ayarlardan boyut
- [x] İHA görünür (alçak, büyük ölçek)
- [x] Araç hızı ağırlığa göre; katalog araçlarında tekerli/paletli ayrımı (lastik patlar/tamir)
- [x] Havan/top/roketatar kurma-toplama süreleri
- [x] Derin kraterler (askerler içine girer, siper)
- [x] Yarı saydam duman, canlı renk ayarı; koşu döngüsü; tabanca/bıçak/sargı (kendi kendine sargı); nadir teslim olma
- [ ] Araç modelleri: daha keskin, detaysız araçlara detay (tüm katalog)
- [~] Asker: IK ile iki elle silah tutuşu, bekleme (low ready) tutuşu, tabanca kılıftan çek/geri tak — kalan: daha hatlı insan modeli, Blender animasyonları
- [~] Her olay için animasyon: ikmal kamyonu yükleme/boşaltma (hamallar kutu taşır) ✅, inşaat işçileri ✅ — kalan: araca binme/inme
- [x] Patlama: mermi türü/açı/zırha göre değişken; tank imhasında daha fazla tür (cephane alev jeti dahil)
- [x] Piyade-tank birlikte ilerleme (Ctrl+sağ tık: tank arkası siper takip)
- [~] Yıkılabilir köprüler ✅ — kalan: 100+ farklı bina türü, çiçek/kaldırım/araç/direk çeşitliliği
- [ ] Faction yapılarının modelleri (sağ alt menü), özgün tasarım
- [ ] Sis efekti (5. foto), daha gerçekçi yeşillik, orman haritası
- [~] Suya düşen/suda vurulan araç batar ✅ — kalan: nehir/deniz suyu görseli
- [ ] YZ komutan: planlama, takılmadan ilerleme
- [x] El bombası düşüşünde yüzeye göre farklı efekt

## Hotfix 0.0.6 — kullanıcı listesi
- [x] Çatışma sahası canlı/yoğun (1. foto): asılı beyaz roket izi kavisleri, cephane alev jetleri, yanan enkazlar
- [x] İHA/helikopter/hava araçlarına irtifaya göre değişen yer gölgesi
- [x] Bina yerleştirmede döndürme (R / Shift+R, 45°) + gerçek model önizlemesi
- [x] Gerçekçi inşaat: 4-6 işçi farklı yerlerde farklı işler (çakma, yukarı çakma, malzeme taşıma), iskele, alttan yukarı örülen duvar
- [x] ABD/Rusya kargo helikopteri (CH-47F tipi, Mi-26 tipi; Blender): asker indirme/bindirme, araç askıya alma/bırakma, havadan ikmal
- [x] Bekleme tutuşuyla koşu (2. foto), nişana kalkıp geri inme, tabancayı kılıftan çekme/ateş/geri takma
- [x] Hava indirme tugayı: paraşütçü timi, halatla iniş/çekme, 4×4 km Hava İndirme Bölgesi (0.0.7)
- [~] Faction yapılarının özgün Blender modelleri — 0.0.7'de ayrı dalda yapılıyor

## Hotfix 0.0.7 — kullanıcı listesi
- [x] Hiçbir araç askeri itmez: araç şeridindeki piyade için yavaşlar/durur ("YOLU AÇIN!"), asker kendi adımlarıyla kenara çekilir (septest)
- [x] Patlamada çift ragdoll: ceset bir kez savrulur, sonraki patlamalar yalnız hafif sarsar; canlı asker 3 sn içinde ikinci kez uçmaz
- [x] Ağaçlar: gerçek modeller (ez-tree, MIT) — meşe, dişbudak, kavak, huş, söğüt, çam (S/M/L, 3'er tohum), kış için yaprağı dökülmüş ikizleri, 3 çalı türü; gerçek kabuk/yaprak dokuları (Poly Haven/TextureCan, CC0); kışta karlı tepe; rüzgâr salınımı (treetest)
- [x] Büyük patlamada ağaçlar şok dalgasıyla (ses hızı gecikmeli) yatıp sönümlenerek sallanır; yapraklar titrer (son 4 patlama, global shader halkası)
- [x] Drone operatörü kendiliğinden drone kaldırmaz: "Mini Drone Kaldır" (L, çantadan elden kaldırma, 3 adet, hedef yoksa noktada asılı kalıp tarar) ve "Drone İstasyonu Kur" (O, 16 sn kurulum: Pelican çanta+dizüstü, tripod anten, jeneratör, mancınık rampası, kamuflaj ağı → yüksek irtifa keşif İHA'sı, 120 m görüş, vurulması zor; operatör/istasyon kaybında bağ kopar ve İHA düşer) (dronetest)
- [x] Bölgesel yara: bacak (topallar, kanlı sargı), kol (alçı + boyun askısı, tek el; ağır silahta tabancaya geçer), omuz (yavaş), kafa (bandaj, kask altında), gövde; hastanede tedavi sonrası etkiler zamanla geçer (woundtest)
- [x] Lideri ölen / eriyen tim yakındaki liderli time katılır; tedavi gereken yaralılar sahra hastanesine kendileri yürür
- [~] Karadan havaya güdümlü füze (SAM/MANPADS ailesine göre sayı/menzil), yakınlık tapası; helikopter fişek atıp yana kırarak alçalır, kızılötesi arayıcı fişeğe kanabilir; İHA manevra yapar (evadetest — test sonu takıldı, Faz 0)
- [~] Detaylı hava füzeleri: Hellfire (ABD) / Vikhr (RU) güdümlü tanksavar, Hydra/S-8 roket, SAM; motor alevi + keskin beyaz duman
- [~] Halatla iniş (fast-rope ✅ 8/8 indi; SPIES çekme doğrulanamadı, Faz 0): helikopter 8 m'de asılı kalır, iki halat sarkar; asker tüfeği sırta atar, iki elle tutunup bacaklarını sarar, kayar, çömelip tüfeği alır ve açılır; halatlar bırakılır. Halatla çekme (SPIES) (ropetest)
- [~] Araca kapıdan binme/inme: arka kapıya yürür, eğilerek girer; inerken sırayla kapıdan çömelerek çıkar ve yelpaze açılır (crewtest — test topa takıldığı için bu bölüm doğrulanamadı, Faz 0)
- [~] Çekili top mürettebatı (crewtest'te top hedef almadı, Faz 0'da düzeltiliyor): atışta kulak kapatma, kovan atma, cephaneci sandıktan mermi taşır, doldurucu kamaya sürer, nişancı volan çevirir; havanda mermi ağızdan bırakılır (crewtest)
- [~] Paraşütçü timi (paratest: 8'den 7'si indi, Faz 0'da düzeltiliyor) (pistten): C-130 / Il-76 tipi uçak geçer, statik hatla atlama, kubbe paraşüt, süzülme, iniş yuvarlanması, kubbe çöker (paratest)
- [x] Görsel savaş sisi: keşfedilmemiş alan koyu, görülmüş ama görüş dışı soluk, görüş içi açık (fowtest)
- [x] Büyük haritalar: Geniş Cephe 1 km, Kuzey Cephesi 2 km, Hava İndirme Bölgesi 4×4 km — ızgara/yol bulma hücresi haritaya göre ölçeklenir, ağaçlar karo karo MultiMesh, yol önbelleği (largetest, hugetest)
- [x] Tim beyni: ilerlerken örtme ateşi, YZ timi kanattan dolanır (taban kolu baskı ateşi), düşmanın tuttuğu binaya el bombası + baskın, gelen roketten yana atılma (tactest)
- [x] Patika ve evden yola taş döşeme yollar
- [x] Efekt flipbook'ları: numpy 3B gaz simülasyonu (yanma, kaldırma, girdap, basınç) → patlama ateş topu/mantar bulutu, kalın duman sütunu, toprak sütunu (tools/fx_sim.py)
- [~] 100+ bina türü — ayrı dalda yapılıyor
- [x] Uzun yol bulma iş parçacığında (2 km+): kopya ızgarada A*, birim o sırada hedefe doğru engelsiz düz parçayı yürür; 12 birimlik grup emri 2–8 ms (önce 0,5–0,7 sn donma). Bedeli 4 km'de ~+250 MB (hugetest)
- [x] Kayalar: kırık yüzlü ikosfer modeller + üretilmiş kaya dokusu (Voronoi çatlak, tabaka, liken), kışta kar / yazın yosun; çakıllar da aynı modelden (rocktest)
- [x] Ulus silahları (Blender): M4A1/ACOG/PEQ, M249, AT4, M110, M17 — AK-12, PKP, RPG-7, SV-98, PL-15
- [ ] 4 km'de bellek (~1,5 GB) ve yükleme (~77 sn yazılım render altında): seyrek ızgara, ot yoğunluğu
- [ ] İskeletli (Blender) animasyon kütüphanesi: koşu/nişan/binme/halat/paraşüt pozlarının keyframe klipleri (şu an kodla poz + IK iskelete uygulanıyor)
- [ ] Araç modelleri A-Z detay geçişi (ABD/Rusya tüm katalog)

### Unreal Engine kararı
Niagara efektleri Godot'a "export" edilemez: Niagara yalnız UE çalışma zamanında çalışır. Taşınabilen tek şey
efektin **flipbook** (sprite sheet) olarak pişirilmiş görüntüsüdür; bunu Blender Mantaflow ile de üretebiliriz.
Oyunu UE'ye taşımak ~21 bin satırlık GDScript'in sıfırdan yazılması demek. Karar: **Godot + Blender** devam;
UE yalnız istenirse bir "efekt pişirme istasyonu" olarak (flipbook PNG) kullanılır.

### Büyük harita mimarisi (0.0.7)
- ≤1 km: 0,5 m ince ızgara, 1 m yol bulma · 2 km: 0,5 m / 2 m · 4 km: 1 m / 4 m (iri hücrede piyade için çoğunluk kuralı)
- Arazi 256 m karolar, ağaç bankaları 256/512 m karolar (görüş dışı kırpılır), su ve ızgara taraması yalnız nehir kutularında
- Sırada: seyrek (chunk) ince ızgara, hiyerarşik + iş parçacıklı yol bulma, uzak ağaçlar için impostor

## Sıradaki adımlar (sıra)
1. **Görsel polish (Blender):** binalar → üs yapıları → harita öğeleri (ağaç, çit, direk, köprü) — hepsi yeniden, faset/temiz stil, asker v3 ile uyumlu
2. **Büyük harita:** ≥ 1 km arazi, ızgara/yol bulma ölçekleme, bölge başına yükleme
3. **Binaya girme / garnizon**
4. Formasyonlar + tim şablonları
5. Ulus silahları (Blender) + animasyon polish
6. Kayıt/yükleme, tuş atama, eğitim
7. Araç kataloğu (50+50), helikopterler, uçaklar
8. Çok oyunculu, Steam entegrasyonu, mağaza
