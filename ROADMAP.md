# MEVZİ — Yol Haritası ve Değişiklik Günlüğü

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
- **Düzeltildi (38):** Kara araçlarının boyutu gerçeğe uyduruldu — 42 araç gerçek ölçüden sapıyordu (tank namlusu uzun ve tareti önde, kamyon şasisi kısa, istihkâm köprüsü/dozer kısa, roketatar kutusu kısa). Blender aile parametreleriyle (taret yeri, namlu boyu, gövde ölçeği; tekerler ölçeklenmeden taşınır) yeniden üretildi → 190 araçta sapma yok (`tools/size_audit.gd`). UR-77 artık MT-LB gövdesinde iki rampalı mayın hattı açma aracı; BAT-2'de kabin önde, vinç arkada; MTU-72 ve Wolverine köprüsü gerçek boyda; TOS-1A fırlatıcı kutusu öne taşar
- **Eklendi (10/38):** Çekili topçu modelleri baştan: konik namlu (hazne + omuz bileziği), kama bloğu ve kolları, beşik ve üstünde geri tepme silindirleri, dengeleyiciler, yükseliş/yön volanları, panoramik nişangâh, kalkan (yarığı namluyla yükselen kayar levha), kuyruk ayakları (hafifletme delikleri, toprağa gömülü pençe, çekme halkası, el kolları, alet sandığı, sürme çubuğu), çift bölmeli ya da çok delikli namlu freni. D-30 üç ayaklı (360° dönüş, kriko tablası), M777 ön destek ayakları, M198/M119 atış tablası, M102 kuyruk makarası, Giatsint-B çift teker, M114/M101 frensiz, Vasilek soğutma ceketi ve şarjör. Doldurucu kamanın gerçek yerinde durur (modelden `breech`)
- **Düzeltildi (10):** Tüm namlular ters konikti (ağızda kalın) → kamada kalın, ağızda ince
- **Eklendi (25, kısmen):** Araç arkasında yürüyen piyade (eskort): araç piyadenin koşusuna uyar (koşudan biraz yavaş), geride kalan olursa bekler — eskiden gerçek hızdaki tank piyadeyi geride bırakıyordu (escorttest)
- **Düzeltildi:** Köprü kenarına kayan araç (kenardaki hücre su sayılıyordu) olduğu yerde sonsuza dek duruyordu → köprü ekseni boyunca kayarak geçer; suya taşmış araç en yakın kuru zemine / köprüye alınır (vehtest)
- **Düzeltildi:** Her yanı ağaç/duvar olan küçük bir cepte doğan araç hiç yürüyemiyordu → doğduğunda en yakın açık alana alınır
- **Düzeltildi:** Araç izi (çarpışma/siper/eskort yeri) namlu taşmasını da sayıyordu ve taret düğümünün yeri hesaba katılmıyordu → gövde + taret
- **Test altyapısı:** testlerde harita tohumu yazdırılır, `-Extra "--seed=N"` ile aynı harita yeniden üretilir; kararsız testler düzeltildi (topçu testinde hedefler ateş etmez ve obüs/roketatara asgari menzil dışında hedef; stres testi başlangıç birliksiz; eskort ölçütü gerçek tank boyuna göre; holdtest sonuç satırı)
- **Düzeltildi (21/55): Büyük harita performansı** — 8 km'de 242 birimlik çatışmada kare 1,17 sn → 29 ms (1 → 34 FPS): ağır araçlar saniyede 8 kez 75 bin ağacın hepsini tarıyordu (ezme), her patlama da öyle → artımlı uzamsal kovalar; ulaşılamayan hedefte ana iş parçacığında A* (araç başına 0,1–0,5 sn) → büyük haritada tüm yol aramaları işçide, kısa engelsiz yol aramasız, yeniden arama 3 sn aralıklı; ikmal yolları da işçide (perf8k)
- **Eklendi (21/53):** YZ büyük haritada: saldırı grubu yol rotası üzerinde ~160 m adımlarla ilerler (düz adım nehre düşüp grubu kıyıda kilitliyordu), 90 sn ilerleyemezse hedef değiştirir; inşaatçı ileri üsse 2,9 km'ye kadar gider; ele geçirilen bölgeye tim bırakır; topçu cephe gerisinde menzile göre mevzilenir; araçlar ulusun gerçek katalog birimlerinden üretilir. İleri üs menzili ve birlik sınırı harita boyutuyla büyür (8 km: 2 km, ×3). 40 dakikalık YZ maçı 90–144 FPS (aimatch)
- **Değişti (21):** Mini harita yeniden: arazinin kendi tarla / yol / yükseklik dokularından alan ortalamasıyla (512 px), orman, tek ağaçlar, binalar, köprüler; yükleme ekranında üretilir
- **Eklendi (10):** Taban tip modelleri (YZ'nin ve sandbox'ın ürettiği tank, PSA, ZPT, helikopter, topçu…) ulusa göre ayrıntılı Blender modelleri (`data/catalog/base_models.json`, `<tip>_<ulus>.glb`)
- **Eklendi (39/44):** Rotor palleri hep görünür: sivrilen, burulmuş pal, hücum kenarı şeridi, uç şeridi, ayrıntılı göbek (eğik plaka, hatve çubukları); dönüş görüntüsü stroboskopsuz, hafif bulanık disk; rotor devri (kalkışta açılır, inişte rölanti) ses perdesine bağlı
- **Eklendi (22):** Rotor rüzgârı: alçalan helikopterin altında ağaçlar ve otlar savrulur, toz kalkar, ses yükselir (rotortest)
- **Eklendi (3):** Motor arızası (hız %60 + duman → motor durur, yangın; mürettebat söndürür), birikimli yıpranma (en çok +%25 hasar), mürettebat/istihkâm onarımında çekiç ve kıvılcım; istihkâm gerçek boyutlu araçta gövde kenarına yaklaşır (enginetest)
- **Eklendi (11):** Tank mürettebatı iner/biner: ayrı askerler olarak iner, araç sürücüsüz yürüyemez/ateş edemez; "Mürettebat Bin" ile geri biner (mounttest)
- **Eklendi (12):** İmha biçimi öldüren isabete göre: üstten saldırı/topçu → cephane infilakı, taret dimdik fırlar; yandan/arkadan → taret vuruş yönünde savrulur; mayın ve ağır patlama hafif aracı devirir/ters çevirir (killtest)
- **Eklendi (23):** Palet izi iklime göre silinir (çölde ~2,5 dk, ılımanda ~8 dk, karda kalıcı, kar fırtınası örter), yağmurda daha derin; oyuncunun görmediği düşman aracı iz bırakmaz (tracktest)
- **Düzeltildi:** Helikopter tanka Hydra roketi harcıyordu (füze kilidi dolmadan tankı öldürüyordu) → güdümlü füze varken ağır zırha roket atmaz
- **Test altyapısı:** aimatch (YZ–YZ maçı, dakika dakika durum), perf8k, basegallery, enginetest, mounttest, rotortest, killtest, tracktest; mode/logi testleri başlangıç birliksiz
- **Düzeltildi (55, kısmen): Kalabalık savaşta performans** — 8 km'de 600 birimlik çatışma 4 → 18 FPS: tespit taraması gözcü verisini paketli dizilerle ve uzamsal kovalarla yapar, gizli hedefte yalnız en yakın 6 gözcü görüş hattı sınar; hedefi olan / boştaki birim tüm görünür düşmanları her yarım saniyede taramaz; sis içindeki / ekran dışındaki askerin animasyonu seyrek güncellenir; duran askerin komşu ve araç itme sorguları seyrek (perf8k, 30 tim)
- **Eklendi (8/29):** İHA ve FPV pervaneleri döner (ayrı düğüm); drone ekibi 2 kişi — istasyoncu ekran başında, ikinci asker kumandayla İHA'yı uçurur; istasyoncu düşerse pilot devralır, ikisi de düşerse bağ kopar; FPV operatörü uçuşta kumanda tutar (dronetest)
- **Test altyapısı:** tactest saldıran tim saldırı hareketiyle gelir (gerçek menzilde 44 m tüfek menzilinin dışıydı)
- **Eklendi (18):** Görünür mürettebat — tank, PSA, ZPT, uçaksavar ve kapalı kundağı motorluda komutan açık kapaktan bakar, ateş altında / çatışmada içeri girer; açık bölmeli obüste (M110, M107, 2S7 Malka) nişancı ve doldurucu güvertede, cephaneci yerde: atışta dolum döngüsü (crewvistest)
- **Eklendi (7):** Havan timi havanını görünür kurar (taban plakası → iki ayak → namlu), mermiyi namluya bırakır, atışta kulak kapatır, namlu geri teper ve taban toz kaldırır; yürüyünce söker (mortartest)
- **Değişti (21):** YZ boşta bekleyen birlikleri saldırı grubuna takviye olarak katar (her dört boştakinden biri üs savunmasında kalır)
- **Eklendi (1):** Gerçekçi asker modeli — MakeHuman CC0 gövde (1,78 m, gerçek oranlar; yüz, kulak, eklemler) + MakeHuman CC0 sistem kıyafetleri mhclo tanımıyla gövdeye oturtuldu (ABD: OCP muharebe gömleği + pantolon, Rusya: Ratnik ceketi + pantolon); kıyafet kıvrım gölgesi köşe renginde, kıvrım normali dokuda; 8 inç bot (dışa taşan kauçuk dişli taban) + bot körüğü. Teçhizat katmanları: kask (ABD yüksek kesim: NVG yuvası, ARC rayları, karşı ağırlık, IR yamaları; Rusya 6B47 kumaş örtü), aktif kulaklık + mikrofon, balistik gözlük, plaka taşıyıcı (gövde kesitine oturan kabuk, ön/arka plaka, gövde yüzeyini izleyen omuz askıları, MOLLE), 3'lü M4 / 4'lü AK şarjör cebi, idari cep, telsiz + anten + PTT kablosu, IFAK, turnike, Rus yaka ve kasık koruması, saldırı çantası, battle belt (dökme cebi, matara), uyluk kılıfı + tabanca, kargo cebi, dizlik, kolda takım renkli IFF bandı, kabza tutuşuna kıvrık eldivenli eller. Tek örgü / tek yüzey (önce 14 yüzey = 14 çizim çağrısı): malzeme kimliği UV2'de, yeni `shaders/soldier.gdshader` (kimliğe göre kamuflaj / yelek / deri, çamur, toz); ~18–20 bin üçgen (önce 27,5 bin). Üretim `tools/anim/build_soldier.py` (Blender), kaynaklar `assets/models/CREDITS_soldier.txt` (posetest)
- **Düzeltildi:** Askerler solak nişan alıyordu (iskelette sağ kol −X'teydi = anatomik sol): gövde aynalandı; pozlar ayna uzayında hesaplanıp uygulanırken X'e göre çevriliyor — tüfek sağ omuzda, sağ el kabzada. Ragdoll, tabanca, çekiç, yara sargıları uyarlandı
- **Değişti:** İskelet gerçek oranlara getirildi: uyluk 0,44 → 0,40 m, baldır 0,46 → 0,52 m, üst kol 0,29 → 0,26 m, dirsek–avuç 0,31 → 0,33 m, omuz 1,42 → 1,38 m. Tek diz pozları (çömelme, çömelerek nişan, top başı, kör ateş, inşa, irkilme) arka diz yere değecek biçimde, havan dolumunda çömelme bacaklar bükülerek yeniden ayarlandı; kol askısı göğse, yara kan lekeleri öne taşındı. posetest 30 poz × 2 ulus, ayak tabanı ve diz yer teması denetimiyle
- **Düzeltildi:** YZ maçı kapanışında yol işçisinin ertelenmiş teslimi serbest kalmış `G`'ye erişiyordu (SCRIPT ERROR)
- **Ölçüm (47/21):** 45 dk YZ maçı (takviyeli, 8 km): kazanan yok 1292/896, yalnız 4 kayıp, 30–127 FPS — ordular 2 km'den yakına gelemedi: piyade yaya ilerliyor (2,5 km ≈ 25 dk). → YZ'nin piyadeyi araçla taşıması ve yakın hedef seçimi gerekli (21)
- **Eklendi (17/19/25):** Mocap yürüyüş — CMU döngü klipleri (yürüme, koşu, depar, geri yürüme, çömelerek yürüme, bekleme) kendi hattımızla (`tools/anim/build_loco.py`) oyunun iskeletine çevrildi (`assets/anim/loco.json`): bacak, kalça ve gövde gerçek hareket verisinden; hız arttıkça yürüme → koşu → depar harmanı, adım evreleri hizalı, ayak kaymaz (evre alınan yolla ilerler); tetikte yürüyüş (dizler bükük), geri geri yürüme, duran askerde ağırlık aktarma ve nefes; esir ve sedyeci de aynı yürüyüşle. Kollar silaha IK ile oturmaya devam eder
- **Eklendi (25):** Şarjör değiştirme (sol el yuvadan boş şarjörü çıkarır → yelekteki cepten yenisini alır → takar → el kundağına döner; tüfek sola yatar) ve atış geri tepmesi (omuz geri, namlu kalkışı; makineli hafif, keskin nişancı sert)
- **Eklendi (9):** İsabet bölgesi — baş / gövde / kol / bacak (yüzüstü, siperde ya da siper arkasında baş-omuz daha açık); kask parçaların çoğunu, tüfek mermisini nadiren durdurur; plaka gövde isabetlerinin ~%65'ini karşılar; kan isabet yerinde fışkırır, yara türü isabet bölgesinden gelir, başa isabet çok daha öldürücü. Yakın ağır patlamada ölen askerde uzuv kopar (iskelette kemik büzülür, eldivenli kol / botlu bacak parçası savrulup kan lekesi bırakır). Sıhhiyeci yaralının yanında diz çöküp sargı sarar (ilk yardım hareketi + sargı rulosu). Oyuncu emriyle tim birleştirme: "Timleri Birleştir" (en çok 13 kişi, komutu en kalabalık timin lideri alır)
- **Eklendi (13):** Teslim olan asker sopaya bağlı beyaz bez sallar, esir eller havada yürür; esir alan asker (meşgul değilse) esirin 2,5 m arkasından tüfeğini ona doğrultarak karargâha götürür, teslim edince timine döner
- **Eklendi (28/37):** İnşaatta taşıyıcı yığına varınca eğilip kutuyu kavrar, iskelede eğilip bırakır (alma/bırakma hareketi); siper hendeği ve kum torbasında kürekle kazma (batır → kaldır → yana at); tüfek sırtta; işçiler bina izinin dışında çalışır (buildtest: içeri giren 0)
- **Değişti (5):** Seçim göstergesi özgün tasarım: zemine yatırılmış köşeli parantezler (asker: küçük baklava; araç / yapı: gövde ve taban izine hizalı dikdörtgen köşeleri) + birimin baktığı yönü gösteren çentik; kalabalıkta halka gürültüsü yok
- **Değişti (52):** Bina yıkımı "lego" olmaktan çıktı — yıkılan blok tek kutu olarak uçmaz, 2–3 düzensiz kırık parçaya ayrılır (biri fizikle savrulur, gerisi dibe moloz), ince kırıntılar ve toz bulutu (yıkılan blok sayısıyla büyür); delik kenarındaki tuğlalar yerinden oynar ve kararır (basamaklı delik yok). Bina çökünce kat kat yıkılır: çatı eğilerek iner, duvarlar tepeden aşağı çöker (bir kısmı kırık kalıntı olarak durur), üç dalga toz; sonunda taban izinde moloz tepesi (düzensiz tümsek + büyük duvar/çatı parçaları + kırıntı). Moloz bölgelere ayrık (görüş dışı kırpılır), düşük poligonlu parça örgüleri (ruintest)
- **Değişti (36):** Kum torbaları gerçekçi: üstü-altı yassı yastık torba, ortası çökük, bağlı uç kulağı, çuval (hessian, CC0) dokusu; 15–17 cm torbalar, 5 sıra, elle dizilmiş gibi düzensiz; vurulan torba yırtılır, kum fışkırır, sönmüş torba dibe düşer
- **Düzeltildi:** yieldtest sahnesi hiç yazılmamıştı (anında kapanıyordu) → askerlerin araca yol vermesi gerçekten sınanıyor; supplytest kare süresine bağlı kalmadan koşulu bekliyor
- **Değişti (10):** Helikopterler baştan: kutu dilimli gövdeler yerine kesitlerden örülen (loft) pürüzsüz gövdeler, gerçek boyutlarla (`tools/blender/veh/fam_heli.py`): AH-64D/E (kademeli tandem kokpit, aviyonik yanaklar, TADS/PNVS, "black hole" egzozlar, kanatçıkta Hellfire + Hydra, Longbow radarı, kuyruk tekerlekli takım), Mi-28N/NM, UH-60M / MH-60M DAP (kayar kapılar, pencereler, üstte motor kaportaları, büyük stabilatör, ESSS + silahlar), Mi-24P / Mi-35M (kabarcık kokpitler, aşağı eğik kanatlar, toz filtreleri), Mi-8 / Mi-17 / Mi-8AMTSh (cam burun, yuvarlak pencereler, dış yakıt tankları, istiridye kapılar, roket kirişleri), Ka-52 / Ka-52M (yan yana kokpit, radar kubbesi, ikiz dikme, gövde yanında 2A42), Ka-226 (çift kuyruk kirişi), AH-1Z / UH-1Y, AH-6 / OH-58D (direk nişangâhı) / UH-72 / Ansat, CH-53K (7 pallı, sponsonlar), MV-22B (dik nasel, ikiz dikme). Katalogdaki ölçek düzeltmeleri kaldırıldı (boyut denetimi: 190 araç, sapma yok)
- **Değişti (10):** Katalogda karşılığı olmayan taban tipler eski JS modellerinden Blender hattına geçti (`fam_extra.py`): 100 mm MT-12 tipi tanksavar topu, dağ topu, uçaksavar (Rusya ZU-23-2, ABD M167 VADS), sahil topçusu kulesi (beton kaide), ABD M1083 FMTV kargo kamyonu; tüm katalog (192 araç + 36 taban) namlu konikliği ve son ayrıntı çekirdeğiyle yeniden üretildi
- **Düzeltildi:** uavtest / vehtest / evadetest her koşuda rastgele haritada çalıştığı için zaman zaman yanlış alarm veriyordu (ör. güdümlü füze köprü korkuluğuna çarpıyordu) → harita tohumları sabitlendi
- **Değişti (41):** Köprüler baştan (`scripts/bridge_mesh.gd`): ≤ 20 m (20–30 m arası konuma göre) **kesme taş kemerli** — parke taşı yol ve oluklar, su üstünde kalan kemer ağızları ve kemer taşları (açık renk kilit taşı), kordon silmesi, akıntı burunlu ayaklar (eğik taş başlıklı), harpuştalı taş korkuluk, uçlarda dışa açılan kanat korkulukları ve baba taşları; uzunlar **betonarme** — açıklık başına döşeme, asfalt (tekerlek izi bantları, yamalar), kesikli orta / sürekli kenar çizgisi, bordürlü kaldırım, yağmur ızgaraları, çift lamalı genleşme derzleri, damlalıklı ön yüz kirişi, yuvarlak burunlu duvar ayaklar, çelik korkuluk + W kiriş, sırayla iki yana aydınlatma direkleri, uç ayak + kanat duvarı, yaklaşımda bariyer; iki tipte de kıyı şevinde iri taş tahkimatı. Köprü malzemesinde kir / nem izi su çizgisinde (yol yüzünde değil)
- **Eklendi (41):** Köprü hasarı — ağır vuruş döşemede gerçek delik açar (açıklık yarısı 12,5 cm'lik karolarla yeniden örülür, kırık kenar yüzleri; betonda delikten su görünür ve kopuk / sarkık donatı demirleri, taşta dolgu çukuru), kenarda kalkmış parçalar, is izi; yakındaki ~4 m'lik korkuluk parçası kopar (çelik: dış kenarda menteşelenip ön yüzden sarkar ya da kıvılcımla suya düşer; taş: taşları yola ve suya saçılır, su sıçrar). Köprüdeki patlamada toprak çukuru / toprak tozu yerine is izi ve beton tozu
- **Değişti (41):** Köprü çöküşü — vurulan açıklık (3+ açıklıkta bazen komşusu da) ortadan kırılır: betonda iki yarı mesnetleri etrafında dönüp suya V biçiminde düşer (kırık uçta pürüzlü beton + dışarı taşan demirler, üstündeki korkuluk ve direk de birlikte), iri beton kırıkları sudan çıkar; taşta kemer yıkılır, iri bloklar dibe yığılıp bir kısmı sudan çıkar, açıklık uçlarında kırık kemer kalır; ayaklar ve öteki açıklıklar ayakta. Geçit kapanır (bridgetest: iki tip, delik + korkuluk + çöküş)
- **Düzeltildi (41):** Uzaklaşınca ekranda beliren beyaz çapraz çizgiler — mini haritadaki görüş çerçevesi harita alanını aşınca mini haritanın dışına taşıyordu (kırpıldı). Gölge: yönlü gölgenin solma bandı kaldırıldı (basamaklı mesafe ekranı zaten kapsıyor; bant basamakla zıplayıp gölgeyi ekranın üstünde kaydırıyordu), stratejik görüşe çıkarken gölgeler 700–1100 arasında yumuşakça söner (bir anda kapanıp sahne parlamıyor); Ayarlar > Gölgeler artık gerçekten etkili (kamera her karede açıyordu). shadowtest: 40 → 614 yakınlaştırmada gölge binaya bağlı, yavaş yakınlaştırmada sürünme yok
- **Değişti (14):** Duman hacimli ve yarı saydam — yeni duman pufu atlası (`tools/fx_smoke_puff.py`: kürelerin birleşimi karnabahar yumaklar, normal + kalınlık + örtme kanalları); gölgelendirici her pufu güneş yönüne göre ışıklandırır (güneşe bakan kabartı aydınlık ve sıcak, gölge yüzü serin, kalın çekirdek öz gölgeli), yaşlandıkça ince kısımlar önce dağılır (arkası görünür), yumuşak parçacık (zemine / duvara değdiği yerde sert kesik yok). Toprak sütunu tek düz flipbook yerine derinlikte dağılmış pufler; ateş topu kısa sürüp isli dumana döner; kara duman, toz ve sütunlar daha saydam (smoketest: 6 tür × 6 an)
- **Düzeltildi:** Testlerde gerçek fare imleci pencere kenarındaysa kenar kaydırma kamerayı kaçırıyordu (kırpılan test kareleri kayıyordu) → testlerde kenar kaydırma kapalı
- **Eklendi (42):** Nehirde akıntı ayrıntısı — akıntıyla taşınan ince uzun köpük çizgileri (nehir boyu / kesit uzayında, kıyıya yakın daha çok); köprü ayaklarında akıntıyı karşılayan burunu saran köpük hilali, mansapta genişleyip sönen türbülans izi ve iki sıra dönüşümlü girdap (Kármán dizisi: girdaplar su yüzeyinin normalini döndürür, iki kollu dönen köpük sarmalı). Ayaklar köprü kurulurken suya kaydedilir
- **Eklendi (14):** Suya düşüş dalgası — her sıçramada (mermi, moloz, batan araç) büyüklüğe göre genişleyen, sönümlenen eş merkezli halkalar su yüzeyinde (öncü tepede kısa süre kırık köpük); batan araçta sıçrama ve dalga gövde boyuyla ölçeklenir (cip ~0,9, tank ~2,4)
- **Düzeltildi:** Köprü döşemesinin altındaki kıyıdan çıkan ot, çakıl ve kamış döşemeyi deliyordu → köprü hücrelerine dökülmüyor
- **Eklendi (24):** Hacimli alev — yanan araç / yapı yangınlarında üst üste binen prosedürel alev dilleri (yeni parçacık türü: gürültüyle çarpıtılmış, yukarı akan damla biçimi; çekirdek beyaz-sarı, kenar turuncu-kızıl, uç kopuk, hafif yalpalama; yumuşak parçacık). Akışkan simülasyonuyla üretilen alev flipbook'u denendi, yetersiz bulunup bırakıldı (`tools/fx_sim.py` PIL olmadan da çalışır)
- **Eklendi (24/75):** Roketatar atışı: fırlatıcı (pod) kurulumla birlikte atış açısına kalkar, toplanırken iner; her roket podun kendi tüpünden (tüp kafesi salvo sayısından: HIMARS 2×3, M270 3×4, BM-21 4×10; atış sırası kafes boyunca dağınık); kapalı podlarda (≤ 16 tüp) tüp kapağı parçalanır, iki yarım parça dönerek yere düşüp kalır, dolumda yeni pod; tüp ağzında alev dili ve parlama, podun arkasına fışkıran egzoz, yere çarpıp yayılan toz bulutu (salvonun ilk roketinde büyük); roket tüpten önce yavaş süzülüp hızlanarak (≈ t³) tüp ekseninde havalanır, sonra hedefe yörüngeye girer; motor yanarken (~1,9 sn) aralıksız beyaz duman izi (eskiden boncuk boncuk), yanma bitince iz kesilir (firetest)
- **Düzeltildi:** Başlamış roketatar salvosu hedef kaybolunca donuyordu; artık sürer (toplanırken bekler)
- **Düzeltildi (kalıcı kural):** Camiye / mescide benzeyen yapılar tamamen kaldırıldı — kubbeli hamam (yanındaki ince bacayla minare silueti veriyordu), kubbeli küçük kerpiç kuyu evi (artık düz damlı), kervansaraylardaki kubbecikler, Harran konik kubbeli evi; kubbe üreticisi (`_r_dome`, kubbe profili, kubbeli revak) koddan silindi, hiçbir yapı kubbe üretemez. Fabrika / kazan dairesi / tuğla harmanı bacası ince, halkalı, tepesi çubuklu kule (minareye benziyordu) yerine kalın beton kaideli, konik tuğla gövdeli, kornişli taçlı, isli açık ağızlı sanayi bacası + yan servis merdiveni + binaya bağlanan duman kanalı; ekmek fırını tonoz örtülü
- **Eklendi (91):** Havadaki araçlarda irtifa çizgisi (Broken Arrow gibi) — gövdeden yere inen ince, takım renkli dikey çizgi + yerde halka: eğik kamerada yüksekte çizilen İHA / helikopterin yer konumu kaybolmuyor; sis ve tespitte birimle birlikte gizlenir. İHA'lar için kamuflajsız açık gri hava aracı boyası ("airgray") (armeduav)
- **Test altyapısı:** soldiertest (asker görünümü yakın çekim: yürüyüş kareleri, duruşlar, tank üstü, siper), armeduav (silahlı İHA: doğrudan doğma, helikopter pistinde üretim, yörünge ve irtifa denetimi)
- **Değişti (94): Taret kopması fiziksel** — iki parçalı mekanik ara geçiş (yukarı → yana iniş) yerine katı cisim benzetimi (`scripts/debris_body.gd`): yerçekimi, kütle dağılımından atalet (taret + namlu), örgünün dış bükey kabuğundan temas noktaları, araziye (çift doğrusal yükseklik) ve enkaz gövdesinin güvertesine çarpışma — sekme, sürtünme, kayma, yuvarlanma; suya düşerse sıçrar ve batar; durunca içi tüter ve ızgarada enkaz engeli olur (piyade siper alır). Fırlayış biçimi öldüren isabetten: üstten saldırı / topçu → dimdik yükselip takla (karusel doldurucuda daha olası), yandan / arkadan → vuruşun tersine yana savrulur ya da güverteden kayar, önden → arkaya devrilir ya da kalkıp gövdeye çarpık oturur (boş taret yuvasına bir yanı oturur); ara sıra namlu beşikten kopup ayrı uçar, yükseliş düzeneği kopan namlu sarkar. Cephane yanmasında önce kapaklardan alev, 0,5–2 sn sonra infilak; yanan tankta alev cephaneye ulaşınca (6–24 sn) tek tek patlayan mermilerin ardından gecikmeli infilak. M1 ailesi: arka bölmenin atılır panelleri uçar, iki alev jeti fışkırır, taret yerinde kalır. Boşalan yuva kararır, içi kor. Yükseklik ölçülü (kullanıcı: "aşırı yükseğe uçuyor"): en şiddetlide tepe ~3–5 m, yana savrulmada ~1 m, kalkıp oturmada ~0,5 m; zırh plakası / kutu / teker parçaları da aynı fizikle ~1–2 m (turrettest: 8 durum, uçuş kareleri, yüzme / gömülme / tepe denetimi)
- **Değişti:** Yanmış enkaz düz siyah siluet değil: aynı araç malzemesinin yanmış çeşidi (is, pas, kül lekeleri; doku, pişmiş AO ve yüzey ayrıntısı korunur)
- **Düzeltildi (87):** Patlayan tankın üstündeki askerler ayakta kalıyordu → savrulur, infilakta çoğu ölür; içerideki yolcuların kaderi imha türüne göre
- **Test altyapısı:** evadetest'in "engel arkasındaki hedef" aşaması çözümsüz kurulmuştu (harita içeriği değişince hedef tankın 2 m yanına düşen ev, duvar halkasındaki tek boşluğu kapatıyordu; oyun hatası değil) → hedef açık alana konur, görüş hattını kesen hücre teşhis satırında yazılır
- **Değişti (93): İHA ve dolanan mühimmat modelleri baştan** — kesitlerden örülen pürüzsüz gövdeler, gerçek boyutlu ve türe özgü düzen: MQ-9 (Y kuyruk, sırt uydu çıkıntısı, GBU-12 + Hellfire), MQ-1C (ters V kuyruk), Orion (V kuyruk, KAB), Forpost-R ve RQ-7 (çift kuyruk kirişi), RQ-4 (sırtta turbofan), Orlan-10/30, Raven, ZALA 421-16E / Eleron-3 (uçan kanat), V-BAT (kanallı fan); dolanan mühimmat birim başına gerçek boy / kanat açıklığından: Switchblade 300/600, ALTIUS-600/700, Lancet-3/3M ve Red Dragon (X kanat), KUB-BLA (uçan kanat), Molniya-2 (küçük uçak), Geran-2 (delta). Boya açık gri hava aracı boyası. Katalogdaki eski ölçek düzeltmeleri kaldırıldı (`v.type`, `v.L`/`v.W`); boyut denetimi 190/190 (X kanatta açıklık çapraz ölçülür)
- **Değişti (93):** Yüksekte uçan İHA'lar ortografik kamerada "maket uçak gibi dev" görünmesin diye görsel irtifa ölçeğiyle çizilir — kanat açıklığı yumuşak tavanla sıkıştırılır (4 m'ye kadar gerçek, üstü ×0,15): MQ-9 20 m → 6,4 m, MQ-1C 17 m → 5,9 m, Orion → 5,8 m, RQ-4 40 m → 9,4 m, Orlan / Raven / dolanan mühimmat gerçek boyutta (kullanıcı: "ABD İHA'ları aşırı büyük"); büyük İHA'nın yörüngesi genişledi (MALE ~35 m, HALE ~47 m). armeduav'a açıklık denetimi (en çok 10 m), dronetest, uavtest geçti
- **Düzeltildi (95):** İnşaat bitince malzeme taşıyan işçiler kaldırılmış malzeme yığınına kutu götürmeye devam ediyordu (bitiş yalnız çalışırken denetleniyordu, yürürken değil) → yürüyen / taşıyan işçi de bitişte ya da yapı yıkılınca işi bırakır (buildtest: bitişten 0,5 sn sonra çalışan işçi kalmaz; düzeltmesiz sürümde 2 işçi kalıyordu)

---

## 🎯 0.0.8 — 32 maddelik büyük güncelleme (kullanıcı listesi, 15 Ekim)
Durum: ✅ bitti · 🟡 kısmen var (temel mevcut, istek tam karşılanmadı) · ⏳ yapılacak · 🔄 şu an çalışılıyor.
(Listede 4. madde yok; numaralar kullanıcının listesindeki gibi korundu. 33–58: 15 Ekim yerel oturumunda kullanıcının ek istekleri.)

| # | İstek (özet) | Durum | Mevcut durum → yapılacak |
|---|---|---|---|
| 1 | Asker modelleri 1-2. fotoğraftaki gibi (gerçekçi oran, kıyafet katmanları, teçhizat) | ✅ | MakeHuman CC0 gövde + CC0 kıyafet (mhclo) + katmanlı teçhizat (kask, plaka taşıyıcı, cepler, çanta, kemer, dizlik), ulus farkı (OCP / Ratnik), tek yüzey; sağ elle nişan düzeltmesi (`tools/anim/build_soldier.py`) |
| 2 | Her aracın hızı farklı ve gerçekçi; hava araçları; atış hızları | ✅ | `data/real_perf.json`: araç başına gerçek yol/arazi hızı, 0→32 km/h ivme, ana silah dolumu, otomatik top dakikada atım/seri, roketatar salvosu, hava aracı seyir hızı (kara ×0,5, hava ×0,25 ölçek); tekerlekli araç yolda hızlı (perftest) |
| 3 | Palet/teker/motor arızası + istihkâm tamir animasyonu; daha önce hasar alan daha kolay hasar alır (dengeli) | ✅ | Motor arızası (duman, yangın, söndürme), birikimli yıpranma, çekiç/kıvılcımlı onarım (enginetest) |
| 5 | Seçim göstergesi: daha küçük, estetik, kendi tarzımız | ✅ | Zemine yatırılmış köşeli parantezler (asker baklava, araç/yapı iz köşeleri) + bakış yönü çentiği |
| 6 | Tüm mühimmatlar gerçekçi: hız, boyut, çarpma, patlama, atış hızı — her araç ve silah | ✅ | `data/ammo.json`: kalibre başına namlu çıkış hızı, kütle, delme, hasar, patlama yarıçapı; ulusa göre iz rengi; araç → mühimmat eşlemesi (ammotest) |
| 7 | Havan, top, obüs ve kurmalı ekip animasyonları | ✅ | Çekili top dolum döngüsü; havan kurma/dolum/atış/sökme; açık bölmeli obüste güverte mürettebatı (mortartest, crewvistest) |
| 8 | Drone: havada görünmeme düzeltmesi, irtifa gölgesi, drone sesi, kalkış/inişte dönen pervane, 2 kişilik operatör (istasyoncu + kumandalı pilot), drone türüne göre istihbarat | 🟡 | Dönen pervaneler, 2 kişilik ekip (pilot devralır), türe göre optik/tespit ✅. → Drone sesleri (Faz 7) |
| 9 | Vurulma yerine göre kan, patlamada uzuv kopması, sağlık çadırı/hastane/paramedikte ilk yardım, timleri isteğe göre birleştirme (tim+tim=manga) | ✅ | İsabet bölgesi (kask/plaka), bölgede kan ve yara, uzuv kopması + savrulan parça, sıhhiyecide sargı sarma hareketi, "Timleri Birleştir" emri (woundtest) |
| 10 | Araç modelleri çok detaylı (teker, kapak, yakıt deposu, namlu, zırh, renk) — EN KRİTİK KURAL | ✅ | Katalog (192) + taban tipler (36) Blender ayrıntı çekirdeğiyle; helikopterler loft gövdeli gerçek boyutlu; eski JS modelleri (tanksavar/uçaksavar/dağ/sahil topu, ABD kamyonu) yenilendi |
| 11 | Tank mürettebatı inip binebilsin (dismount/mount) | ✅ | Mürettebat İn / Bin emirleri; araç mürettebatsız yürümez/ateş etmez (mounttest) |
| 12 | İmha mermi türüne göre değişsin: yan yatma, farklı yönde taret fırlaması, çakılma | ✅ | Öldüren isabete göre imha: dikey/yönlü taret fırlaması, devrilme, helikopter düşüşü (killtest) |
| 13 | Nadir teslim olma: beyaz bayrak, silah zoruyla karargâha götürülme | ✅ | Beyaz bayrak, eller havada yürüyen esir, tüfeği esire doğrultmuş muhafız eşliği (behav) |
| 14 | Patlama bulutu yarı saydam; suya düşüşte araç boyutuna göre dalga | ✅ | Hacimli, güneşe göre ışıklı, yarı saydam duman (smoketest); büyüklüğe göre su dalga halkaları, batan araçta gövde boyuyla (bridgetest) |
| 15 | Hava araçları füzeden kaçınsın; gerçek füze türleri ve atış mekanizmaları | ✅ | Güdüm türleri (IR / tel / lazer hüzme / lazer işaretleme / radar), kilit süreleri, nişancı izleme prosedürü (bastırılınca sapma), görünür tel, füzeye göre fişeğe kanma; helikopter fişek + kaçış (missiletest, evadetest) |
| 16 | 100+ farklı bina, yıkılabilir köprüler, ağaç/çiçek/kaldırım/kapı/pencere/sokak/başıboş araç/direk — tam detay | 🟡 | 143 bina arketipi ✅, köprüler var. → 34 (dini yapı yok, duvarlar), 35 (özgünlük), sokak eşyaları |
| 17 | Asker modeli fotoğraftaki gibi + her eylem için animasyon (düşme, eğilme, zıplama, koşma...) | ✅ | Gerçekçi model (1); mocap yürüme/koşu/depar/çömelerek/geri yürüme + 30'dan fazla poz, ragdoll düşme, engel atlama (posetest) |
| 18 | Araçlar 3. fotoğraftaki gibi gerçekçi (mürettebat görünür, açık bölme) | ✅ | Kapakta komutan (çatışmada içeri), açık bölmeli obüste çalışan mürettebat (crewvistest) |
| 19 | Animasyon için kendi sistemimiz (Unreal ile) | ✅ | Blender + MakeHuman + CMU mocap hattı oyunda kullanılıyor (`build_soldier.py`, `build_loco.py`, `build_anims.py`); Unreal gerekmedi |
| 20 | 4. fotoğraftaki gibi keskin hatlı, girilebilir, çatısı detaylı binalar | 🟡 | Çatı eşyaları var; girilebilirlik düzeltildi (kapı yol hücreleri: erişilemeyen pencere yuvası 1006 → 65). → Kalan 10 tür (istasyon, kültür merkezi, karakol kulesi...), fotoğraftan farklılaştırma (35) |
| 21 | Harita boyutları büyütülecek — **öne alındı:** gerçek muharebeye yetecek büyüklükte, büyük savaş mekanizmasına uygun harita; bundan sonra her şey bu haritada test edilecek, ardından özel haritalar (48) | 🔄 | **Büyük Muharebe 8×8 km** ✅ (motor, stratejik görüş, simgeler, tarla/orman, yükleme ekranı). → Kalan: YZ'nin büyük haritada ilerleyişi, mini harita, yol bulma ızgarası belleği (2,5 GB), 49/50 ile gerçek menzil ve görüş |
| 22 | Helikopter alçaldıkça pervane sesi artsın, rotor rüzgârı ağaç/çimen sallasın | ✅ | Rotor rüzgârı (ağaç, ot, toz), alçaldıkça ses yükselir, devir ses perdesinde (rotortest) |
| 23 | Palet izi; iklime göre kalıcı/kaybolan; savaş sisine uyumlu | ✅ | İklime göre silinme, yağmurda derin iz, görülmeyen düşman iz bırakmaz (tracktest) |
| 24 | Gerçekçi 3B alev, roketin poddan çıkışı vb. (dengeli) | ✅ | Hacimli prosedürel alev dilleri; roketatar pod kalkışı, tüp tüp atış, kapak parçalanması, yavaş çıkış + hızlanma, sürekli iz, egzoz ve toz (firetest) |
| 25 | Tüm asker animasyonları: tutuş, ateş, şarjör, silah değiştirme, siper, sürünme, atlama, depar, tetikte yürüme, araç arkasında yürüme | ✅ | IK tutuş, geri tepme, şarjör değiştirme, tabancaya geçiş, siper/kör ateş, sürünme, engel atlama, mocap depar ve tetikte yürüyüş, eskort yürüyüşü |
| 26 | Mühimmat efektleri için gerekli programları kur, test et; kurşun ve roket farklı görünsün | ✅ | İz boyutu kalibreye göre; yerden atılan roket/füzede motor alevi + ışık, füzede iz fişeği (ammotest) |
| 27 | Kendi araç patlaması/düşüşü kendi askerine zarar vermesin; bina patlaması iki tarafa da zarar verir | ✅ | G.explode spare: araç imhası / helikopter düşüşü kendi askerine hasar vermez (bastırır); bina patlaması herkese (fftest) |
| 28 | İnşaatta her asker kutudan malzeme alıp taşır, bırakır, farklı animasyonla çalışır | ✅ | Yığından eğilip kutu alma, taşıma, iskelede bırakma; alçak/yüksek çekiç, kürekle kazma (buildtest) |
| 29 | Bazı İHA/drone'lar görünmüyor; özel sesler; yüksek irtifa | 🟡 | → 8 ile birlikte |
| 30 | 9×9 / 9×6 km haritalar, 30+ harita, Senaryo; radar araçları, S-300 tipi radar+SAM, uçaklar; **Mevzi-Core**: oyuncu kontrolünde olmayan birimlerin gerçekçi doktrinle davranışı | 🟡 | 4 km harita, tim beyni var. → Mevzi-Core tasarımı (bölgesel komuta, birim rolleri, angajman kuralları), radar/SAM katmanı |
| 31 | Roketler havada önlenebilsin (dengeli) | ✅ | APS (Trophy/Afganit) %70 / üstten %15, 4 şarj; C-RAM inen mermide %35, 20 angajman (missiletest) |
| 32 | Ana menü: Masaüstüne Çık · Ayarlar (Grafik, Ses, Oynanış, Klavye) · Senaryo Oluşturucu · Kampanya · Klasik Harita · Sandbox Test | ✅ | Menü + tuş atama birleştirildi (keybinds_test 55/55, menü ön izlemesi TR/EN) |
| 33 | Bayrak animasyonu (Blender + UE) | ⏳ | → Blender kumaş simülasyonu pişirilir (köşe animasyon dokusu), Godot'ta rüzgârla oynatılır. UE kurulu değil; istenirse yalnız pişirme istasyonu olabilir |
| 34 | Oyunda cami/kilise/mescit vb. hiçbir dini yapı olmayacak; her binanın yanında duvar olmasın, duvarlar gelişigüzel | ✅ | 8 dini arketip + minare/çan kulesi/alem/haç üreticileri silindi; avlu duvarları seyrek ve gelişigüzel (L/U, gedik, yıkık, eğri) |
| 35 | Binalar referans fotoğraflardan biraz farklı olsun (aynısı değil) | ⏳ | **Kullanıcı tekrar istedi (16 Ekim): ev türleri hâlâ aynı, farklı evler eklenecek.** → Oran, renk, cephe düzeni, çatı ve detay çeşitlemesi  |
| 36 | Kum torbaları gerçekçi (web'den CC0 varlık ya da kendi üretimimiz) | 🔄 | Yastık torba örgüsü + CC0 çuval dokusu, düzensiz dizim, yırtılan torba. **Kullanıcı (16 Ekim): hâlâ çok yapay** → gerçek kum torbası: dolgun-sarkık biçim, dikiş/bağ, kirli-solgun renk farkı, sıra arası çökme, toprak bulaşığı |
| 37 | Kazma ve inşaat animasyonları: silah sırtta, binanın içine girmeden dışarıdan inşa (hata var) | ✅ | Kürekle kazma, tüfek sırtta, işçiler iz dışında (içeri giren 0, buildtest) |
| 38 | Tüm araç boyutları gerçekçi | ✅ | `data/real_dims.json` + `tools/size_audit.gd`: 190 araçta sapma yok (önce 42 kara aracı hatalı). Namlu boyu/taret yeri, kamyon şasisi, köprü/dozer, roketatar kutusu; çekili toplar gerçek yerleşimle yeniden (D-30 atış düzeninde) |
| 39 | Helikopter pervaneleri gerçekçi, detay dokulu | ✅ | Sivrilen burulmuş pal, uç ve hücum kenarı şeridi, ayrıntılı göbek |
| 40 | Hiçbir mermi yuvarlak top/taş gibi görünmesin | ✅ | Topçu/havan yüksek yörünge + iz, moloz köşeli parça (ammotest) |
| 41 | Köprüler gerçekçi olsun ve hasar alsın; uzaklaşınca (zoom out) gölgeler kayıyor/parlıyor | ✅ | Taş kemerli / betonarme iki tip, delik + kopan korkuluk, açıklık çöküşü (bridgetest); gölge solma bandı kaldırıldı, uzakta yumuşak sönme, mini harita çerçevesi taşması düzeltildi (shadowtest) |
| 42 | Harita başlayınca nehirde durduk yere duman çıkıyor → kaldırılacak; nehre gerçekçi akış | ✅ | Duman kaldırıldı, su nehir boyunca akıyor, akıntı köpük çizgileri, köprü ayağında burun köpüğü + girdap izi |
| 43 | Savaş sisi gerçekçi: karemsi değil, birliklerin görüşüne göre değişsin | ✅ | Görüş çokgenleri (orman/bina/duvar keser), yumuşak kenar, optiğe göre yarıçap, büyük haritada 4 m/piksel |
| 44 | Helikopter pervaneleri mutlaka görünsün (sesler en son, ama sistem buna uygun) | ✅ | Paller hep görünür, stroboskopsuz dönüş, rotor devri değişkeni ses perdesine bağlı |
| 45 | Soldaki bilgilendirmeler daha estetik | ⏳ | → Bilgi/olay paneli yeniden tasarım (tipografi, ikon, kart, solma) |
| 46 | Harita daha estetik | 🟡 | Tarla deseni, orman zemini, yol köyleri ✅. → Arazi dokusu ve renk paleti, kıyılar, yol kenarları, bitki dağılımı, ışık/atmosfer |
| 47 | Roadmap bitince genel kalite turu: grafik ayarlarıyla hata kontrolü, sandbox'ta tüm yapılar, tüm animasyonlar (model güncellemesi sonrası), büyük haritada oyuncu gibi uzun ve gerçekçi maç (maç süresi ölçülür), olası hataların bulunup engellenmesi | ⏳ | → Faz 7 |
| 48 | Büyük haritadan sonra özel (custom) haritalar | ⏳ | → Faz 6: editörle yeni haritalar |
| 49 | Her aracın (ve silahın) menzili kontrol edilecek, gerçekçi olacak | ✅ | `data/real_combat.json`: 197 birim × silah başına gerçek menzil; harita ölçeği (8 km'de tam gerçek); silah başına menzil kapısı, gerçek atış kontrolü ve öndeleme, gerçek mermi/füze hızları (rangetest) |
| 50 | Araçların birbirini görme kapasitesi kontrol edilecek (hata varsa düzeltilecek) | ✅ | **Hata düzeltildi:** görüş yalnız mesafeydi (görüş hattı/gizlenme/optik yok, 125 m sınırı). → Optik × hedef izi × görüş hattı × gece/hava, radar, tespit hafızası (spottest) |
| 51 | Her birimin canı ve zırhı farklı olacak, sisteme uyarlanacak | ✅ | Birim başına gerçek zırh (mm RHA, 4 yön × kinetik/HEAT) ve can; gerçek delme ve mesafe düşüşü; piyadede plakalı/yumuşak yelek |
| 52 | Bina yıkımı "lego gibi" — çok daha gerçekçi olacak | ✅ | Kırık parçalar, yerinden oynamış delik kenarı, toz, kat kat çökme, kalıntı duvar + moloz tepesi (ruintest) |
| 53 | Büyük haritalar Broken Arrow / CoH3 büyüklüğünde ve detayında | ⏳ | → 21 ile birlikte: 8×8 km, stratejik yakınlaştırma + birim simgeleri, gerçek yer düzeni, yoğun detay |
| 54 | **Kritik:** modellerle ilgili tüm maddeler eksiksiz yapılacak | ⏳ | → 1, 10, 12, 13, 17, 18, 33, 35, 36, 38, 39/44 — her biri kendi fazında, atlanmadan |
| 55 | Performans iyileştirmeleri | ⏳ | → Faz 7 |
| 56 | Ses efektleri | ⏳ | → Faz 7 (helikopter rotor devri ses için hazır tutulur) |
| 57 | Genel HUD/arayüz yenilemesi ve buna yönelik hata avı | ⏳ | → Faz 7 (45 ile birlikte) |
| 58 | Kayıt sistemi aktif: oyunu kaydet / yükle, otomatik kayıt | ⏳ | → Faz 7 |
| 59 | Oyun için sinematik fragman | ⏳ | → Faz 7 sonunda (duman, ses ve HUD bittikten sonra): Godot Movie Maker ile oyun içi kayıt — serbest perspektif kamera yolları, yavaş çekim, sahnelenmiş muharebe (topçu, köprü geçişi, helikopter, piyade hücumu, bina / köprü yıkımı); kurgu, yazı ve ses Blender VSE ile, MP4 |
| 60 | Askerler yürürken uçuyor gibi duruyor — gerçekten adım atmalı (ayak yere basmalı) | ⏳ | → Zemin yüksekliği (krater, şev), adım uzunluğu = hız, animasyon seyreltmesinin ekrandaki askerde kapatılması |
| 61 | Araç üstündeki askerler havada duruyor | ⏳ | → Gerçek güverte yüksekliği (gövde örgüsünden), oturma pozu, tutamak |
| 62 | İmha olan araç enkazı çevrenin parçası: başka araç çarpıp itebilir, kıyıdaysa nehre/göle düşer | ⏳ | → Enkaz itme fiziği, suya düşüp batma |
| 63 | Harita daha mat | ⏳ | → Arazi parlaklığı/doygunluğu, yansıma, ışık |
| 64 | Birliklerin hepsi görünmeli | ⏳ | → Uzaklaşınca / ağaç altında / sis kenarında kaybolan birlikler |
| 65 | HUD değişsin (güncel HUD yenilenecek) | ⏳ | → 57 ile birlikte öne alındı |
| 66 | Askerlerin silah tutuşu hâlâ çok saçma | ⏳ | → Omuz/kabza/el yerleşimi, nişan ve taşıma tutuşu yeniden |
| 67 | Bina patlaması lego parçası gibi saçılıyor — binanın gerçek yapısına göre (tuğla, beton, sıva, ahşap, kiremit) parçalanmalı | ⏳ | → Malzemeye göre parça örgüleri (tuğla, beton levha + donatı, sıva kabuğu, ahşap kiriş, kiremit) |
| 68 | Köprüler hep aynı şekilde yıkılmasın — mühimmat türüne göre farklı | ⏳ | → Topçu: vurulan yerden kırılma; ağır bomba: açıklık düz düşer; tanksavar: menteşe gibi tek uç; ayakta patlama: ayak çöker, iki açıklık V |
| 69 | Binalar girilebilir, üst katlara çıkılabilir | ⏳ | → Kat kat pencere mevzileri, merdiven, üst katta görüş/atış avantajı |
| 70 | Kule gibi yapılar yana devrilebilmeli | ⏳ | → Su kulesi, gözetleme / karakol kulesi, baca, anten direği, silo: tabandan kırılıp vuruşun tersine devrilir, düştüğü yeri ezer |
| 71 | Nehirde tek yöne sert ve yoğun akış animasyonu | ⏳ | → Akış hızı ve akıntı çizgileri belirgin, hız alanı kesitte |
| 72 | Broken Arrow gibi araç başına saldırı modları / silah seçimi: roketatar tek noktaya seri ya da çoklu yöne yayarak; her araçta farklı modlar, silah değiştirme tuşu, HUD ile entegre | ⏳ | → Silah paneli (mühimmat, mod), kısayol, roketatar alan/nokta/çoklu hedef salvosu |
| 73 | İnşaat modunda askerler hâlâ binanın içine koşup takılıyor — inşaat / tamir tamamen dışarıdan | ⏳ | → Tüm bina türlerinde ve tamirde çalışma noktaları iz dışında, içeri yol yok |
| 74 | Askerler eğilirken aşırı geriye yatıyor | ⏳ | → Çömelme / eğilme / diz çökme pozlarında gövde öne |
| 75 | Roketatar atışı ayrıntılı: pod kalkar, tüp kapağı parçalanıp düşer, alev, roket yavaş çıkıp hızlanarak havalanır, hedefte patlar | ✅ | 24 ile birlikte (firetest) |
| 76 | Chinook tipi nakliye helikopteri: askerler arka rampadan tek tek biner / iner (animasyonlu), en çok 7 asker ya da en çok 1 ZPT | ⏳ | → Rampa açılır, sıra hâlinde yürüyüş, kapasite kuralı, ZPT yükleme |
| 77 | Askı halatı daha iyi, kanca oyuncuya net görünmeli | ⏳ | → Kalın sarkan halat (salınım), belirgin kanca + sapan, yükte bağlantı noktaları |
| 78 | Askı yükü bırakma ani — gerçekçi olmalı: yük yavaşça iner, yere değince sallanıp oturur, rotor rüzgârıyla ağaçlar sallanır, toz | ⏳ | → İniş hızı yere yaklaştıkça düşer, halat gevşer, kanca açılır, yük sekme/oturma, rotor rüzgârı çevreyi sallar |
| 79 | Biniş / iniş animasyonları atlanmasın: askerler kamyon kapısını açıp biner, inerken kapı açılır ve inerler | ⏳ | → Kabin kapısı / arka kapak / rampa düğümleri, kapıya yürüme, tırmanma, sıra |
| 80 | Tanksavarcı silahı sırtına atınca kolsuz gibi duruyor | ⏳ | → Sırttaki tanksavarda kollar serbest / tüfek tutuşu, kol IK hedefi sırt değil |
| 81 | Gerçekçilik: tüfekle ateş eden askerler araçları patlatabiliyor | ⏳ | → Hafif silah zırhlıya hasar vermez (yalnız açıkta duran mürettebat / optik), yumuşak araca sınırlı hasar, patlatma yalnız tanksavar / HE |
| 82 | Köprüde patlama sonrası ragdoll olan askerler havada kalıyor | ⏳ | → Ragdoll zemini köprü döşemesi / su; yıkılan açıklıktaki cesetler suya düşer |
| 83 | Askerler geriye koşarken arkalarına bakmadan ateş ediyor | ⏳ | → Ateş için gövde hedefe dönük olmalı; geri çekilirken ya dönüp ateş eder ya geri geri yürür |
| 84 | Kalabalıkta askerler tank çevresinde sıkışıyor, birbirinin içine giriyor | ⏳ | → Asker–asker ve asker–araç ayrışması, araç çevresinde yol açma |
| 85 | Askerler bazen ördek gibi yürüyor; kollar kullanılmıyor gibi | ⏳ | → 60/66 ile birlikte: kalça/diz açısı, kol salınımı ve silah tutuşu |
| 86 | Malzeme aldıktan sonra askerler saçma eğiliyor (model/poz cilası) | ⏳ | → Kutu alma / taşıma pozu |
| 87 | Tank patlayınca üstündeki asker ayakta kalıyor, ölmüyor | ✅ | Güvertedekiler patlamayla savrulur: infilakta çoğu ölür (ceset savrulur, yakın infilakta uzuv kopabilir), yanan tanktan atlayanlar sersem / yaralı; içerideki yolcular imha türüne göre (infilakta kurtulamaz, hareketsiz kalan araçtan çoğu sağ iner) (turrettest) |
| 88 | Roketatarda hızlı salvo seçeneği | ⏳ | → 72 atış modları ile |
| 89 | Askerler siperde yatamıyor; siper boyutuna göre eğilme / çömelme animasyonu | ⏳ | → Siper derinliğine göre poz: sığ hendekte yüzüstü / diz, derin siperde ayakta siper kenarına yaslanma, başını eğme |
| 90 | Bazı roketler çok yavaş — hızlar gerçekçi olmalı | ⏳ | → Roket / füze türüne göre gerçek hız (RPG ~115→295 m/sn, Grad ~690, GMLRS ~Mach 2+, ATGM 200–400) |
| 91 | Silahlı İHA havada durmuyor / görünmüyor | 🔄 | Oyun içi akışlar (doğrudan, helikopter pisti üretimi, sandbox taban tipi) denendi: İHA 13 m'de yörüngede kalıyor ve görünür (armeduav). Eğik kamerada uçak yer konumundan ~10 m yukarıda çizildiği için yer işaretinin üstünde görünmüyordu → Broken Arrow gibi irtifa çizgisi + yerde halka ✅ (görüntüde doğrulandı). → 93 ile birlikte görsel irtifa ölçeği |
| 92 | ZPT ve benzeri kara araçlarında bindirilmiş (mount) askerler saçma şekilde ayakta duruyor | ⏳ | → 61 ile birlikte: kapak / güverte pozları, gerçek güverte yüksekliği |
| 93 | İHA boyutları çok büyük, maket uçak gibi — modeller böyle olmamalı | ✅ | `tools/blender/veh/fam_uav.py` baştan yazıldı (loft gövde, türe özgü düzen: MQ-9 Y kuyruk + uydu sırtı, MQ-1C ters V, Orion V, Forpost / RQ-7 çift kiriş, RQ-4 sırt turbofanı, Orlan, ZALA / Eleron uçan kanat; dolanan mühimmat gerçek boy / açıklıktan; açık gri "airgray" boya, kamuflaj değil). 22 model üretildi, katalog ölçek düzeltmeleri kaldırıldı, boyut denetimi 190/190; görsel irtifa ölçeği HALE ×0,4 / MALE ×0,5 / taktik ×0,8, geniş yörünge (armeduav, dronetest, uavtest) |
| 94 | Tank taretinin patlaması fazla mekanik, saçma duruyor — farklı açılarla farklı şekilde patlayabilmeli (+ "taretler ve parçalar aşırı yükseğe uçuyor") | ✅ | Katı cisim benzetimi (`scripts/debris_body.gd`): yerçekimi, takla, araziye ve enkaz güvertesine temas, sekme, kayma, yuvarlanma, namlu ucunun yere dayanması; biçim vuruş yönü / mühimmat / imha türüne göre: dimdik fırlayıp takla, vuruşun tersine yana savrulma, arkaya devrilme, kalkıp gövdeye çarpık oturma, güverteden kayma, namlunun ayrı kopması, yanan tankta gecikmeli infilak, M1'de panel atma (taret yerinde). Yükseklik ölçülü: en şiddetlide ~3–5 m (turrettest) |
| 95 | Üs yapımı bittikten sonra asker hâlâ ikmal deposu varmış gibi depoya malzeme götürüyor | ✅ | Bitişte / yıkımda yürüyen ve taşıyan işçiler de işi bırakır (buildtest) |
| 96 | Kamyon binaların içinden geçmemeli | ⏳ | |
| 97 | ABD Ana Muharebe Tankı 2'de taret hatalı, kocaman — düzelt, küçült | ⏳ | |
| 98 | Piyade taşıma aracı 6 kişilik ama 2 kişi biniyor | ⏳ | |
| 99 | Patlama sonrası Rus topçuları kraterde hiçbir şey olmamış gibi bekliyor; top araç gibi patlıyor ama askerlere bir şey olmuyor | ⏳ | |

### Uygulama sırası (fazlar)
- **Faz 0 — Stabilite ✅:** yamalar + test bekçisi, crewtest/paratest/SPIES/evade; takılma bekçisi (asker/araç/sedye, stucktest); yapılamayan emirde sesli uyarı; ekransız test (-Headless, run_tests.sh)
- **Faz 1B — Büyük muharebe haritası (öne alındı, 🔄):** 21/53 — önce motor (ızgara, arazi, su, kamera, simgeler), sonra 49/50/51 ile birlikte harita içeriği ve YZ; bundan sonra her madde bu haritada da test edilir
- **Faz 1 — Veri gerçekçiliği (🔄):** 2 ✅, 27 ✅, 6 ✅, 26 ✅, 49 ✅, 50 ✅, 51 ✅, 15 ✅, 31 ✅, 38
- **Faz 2 — Araç sistemleri:** 3, 11, 12, 23, 22, 39/44, 8/29, 18, 7
- **Faz 3 — Asker yeniden yapımı:** 1, 17, 19, 25, 9, 13, 28/37, 5
- **Faz 4 — Dünya ve görsel:** 34 ✅ (öne alındı), 42, 43, 46, 52, 10, 16, 20, 35, 36, 33, 14, 24, 41
- **Faz 5 — Menü ve çekirdek:** 32, 30 (Mevzi-Core, radar/S-300)
- **Faz 6 — Haritalar:** 30 (9×9 km ve 30+ harita), 48 özel haritalar
- **Faz 7 — Genel kalite turu (roadmap bitince):** 47, 55 performans, 56 ses efektleri, 57/45 HUD/arayüz + hata avı, 58 kayıt sistemi, 59 sinematik fragman — grafik ayarları × hata kontrolü, sandbox'ta tüm yapılar, tüm animasyonlar, büyük haritada uzun gerçekçi maç ve süre ölçümü
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
