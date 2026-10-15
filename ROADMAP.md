# MEVZİ — Steam'e hazır oyun yol haritası (eksiksiz)

Ana test aracı: **Sandbox** (her yeni birim/yapı otomatik listelenir, sınırsız çıkarılır).
Takımlar: **Müttefikler vs Mihver** — uluslar: ABD, Rusya, Almanya, Birleşik Krallık, Türkiye. Şu an odak: **ABD vs Rusya**.
İlham: Broken Arrow (REA tasarım analizi), Sudden Strike 5, Men of War AS2, CoH 2/3, Red Alert tarzı RTS. Defilade'den farklı olmalı.

Durum: ✅ bitti · 🟡 kısmen · ⏳ yapılacak. Öncelik: **P0** (Steam'den önce şart) · **P1** (çıkışta olmalı) · **P2** (çıkış sonrası olabilir).

---

## A. Çekirdek oynanış
| | Öğe | Durum |
|---|---|---|
| P0 | Seçim, sürükle-seç, kontrol grupları (Ctrl+1-9), çift tık ile aynı türü seç | 🟡 (kontrol grupları kontrol edilecek) |
| P0 | Emirler: hareket, hızlı, saldırı hareketi, geri vites, dur, mevzi tut, geri çekil, ateş modu, duruş, indir, el bombası, sis, baskı ateşi, terk et, iade | ✅ |
| P0 | Formasyonlar (hat, kol, kama) + sağ tık sürükleyerek yön/genişlik (CoH/SS5) | ⏳ |
| P0 | **Binaya girme / garnizon** (pencereden ateş, kat bonusu, bina yıkılınca dışarı) | ⏳ |
| P0 | Araçlara binme/inme, yolcu taşıma | ✅ |
| P0 | Siper, örtü, baskı, stres (sarsılmış/panik) | ✅ |
| P0 | Zırh 4 yön × kinetik/HEAT, delme, kritik hasar | ✅ |
| P0 | Görüş hattı + savaş sisi (birim bazlı), duman görüşü keser | ✅ |
| P1 | Gizlilik: hareketsiz/çalılıkta görünmezlik, ateş edince açığa çıkma (BA optik/stealth) | 🟡 (gece/havada var) |
| P1 | Keşif birimleri, dürbünlü gözcü, yüksek zemin görüş bonusu | ⏳ |
| P1 | Topçu çağrısı / hava desteği (yetenek ağacı, puanla) | ⏳ |
| P1 | Havadan ikmal + paraşütçüler | ⏳ |
| P1 | Mayın döşeme/temizleme, istihkâm köprü kurma | 🟡 (tank tuzağı var) |
| P2 | Kuşatma/teslim alma, esir değişimi | 🟡 |

## B. Birimler ve içerik
| | Öğe | Durum |
|---|---|---|
| P0 | Piyade sınıfları: tüfekçi, lider, makineli, tanksavar, sıhhiye, keskin nişancı, istihkâm, havan, drone, mürettebat | ✅ |
| P0 | Tim şablonları: kışlada "TİM" sekmesi, kendi timini tasarla, hazır timler | ⏳ |
| P0 | ABD ve Rusya için ayrı asker modelleri (üniforma, yelek, kask) | ✅ (v3 faset) |
| P0 | Ulusa özel silahlar (M4/AK-12, M249/PKP, AT4/RPG, M2/Kord, tabanca) — Blender | ⏳ |
| P1 | Araç listeleri: 50+ kara, 50+ hava (veri kataloğu: DEF + zırh + delme + maliyet) | ⏳ |
| P1 | 14 helikopter tipi (jenerik adlar) | ⏳ |
| P1 | Uçaklar: yakın hava desteği, keşif, kargo | ⏳ |
| P2 | Almanya, Birleşik Krallık, Türkiye setleri | ⏳ |

## C. Harita ve dünya
| | Öğe | Durum |
|---|---|---|
| P0 | **Büyük harita** (≥ 1 km, MP'de ≥ 20 dk) — ızgara/yol bulma/arazi akışı ölçeklenecek | ⏳ |
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
- [ ] Hava indirme tugayı: paraşütçü birlikleri, büyük harita (helikopter menzili için)
- [ ] Faction yapılarının özgün Blender modelleri (fabrika/kışla/pist hâlâ basit)

## Sıradaki adımlar (sıra)
1. **Görsel polish (Blender):** binalar → üs yapıları → harita öğeleri (ağaç, çit, direk, köprü) — hepsi yeniden, faset/temiz stil, asker v3 ile uyumlu
2. **Büyük harita:** ≥ 1 km arazi, ızgara/yol bulma ölçekleme, bölge başına yükleme
3. **Binaya girme / garnizon**
4. Formasyonlar + tim şablonları
5. Ulus silahları (Blender) + animasyon polish
6. Kayıt/yükleme, tuş atama, eğitim
7. Araç kataloğu (50+50), helikopterler, uçaklar
8. Çok oyunculu, Steam entegrasyonu, mağaza
