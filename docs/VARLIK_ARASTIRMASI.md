# Varlık araştırması — gerçekçi asker / araç / animasyon (ROADMAP 165, 17 Ekim 2026)

Kullanıcı: "Fizikleri, asker araçlarını, askerleri modelleme — oyunun satışında en önemli şey. En iyi assetleri
internetten bul." Aşağıdaki karar noktaları **kullanıcının onayını** bekliyor (ücretli alım, hesap girişi).

## 1. Önemli hukuki bulgu: gerçek araç adları / tasarımları
Büyük mağazalarda (TurboSquid, RenderHub, CGTrader) gerçek askerî araç modellerinin önemli bir kısmı
**"Editorial Use Only"** (yalnız haber / belgesel) lisanslı: satıcı, aracın tasarım / marka haklarını üreticiden
(General Dynamics, BAE, Uralvagonzavod …) almadığı için ticari oyunda kullanımı açmıyor. Satın alınacak her
paketin lisansında "editorial" kısıtı OLMAMALI. (Bu bir hukuki görüş değildir; satış öncesi bir avukata
danışılması önerilir — kendi Blender modellerimiz için de araç adları aynı soruyu doğurur.)

## 2. Ücretsiz / açık lisanslı seçenekler
| Kaynak | İçerik | Lisans | Kalite / not |
|---|---|---|---|
| Mixamo (Adobe) | Rigli insan karakterleri + yüzlerce mocap animasyonu (ölüm, vurulma, tırmanma, araca binme, sürünme, siper) | Ticari oyunda ücretsiz; ham dosya yeniden dağıtılamaz (oyun paketinin içinde olması uygun) | **En büyük kazanç**: 162 (gerçekçi vurulup ölme) ve 159 (biniş / iniş) için hazır animasyon. Adobe hesabıyla indirme gerekir — **kullanıcı girişi** |
| Sketchfab CC-BY | Low Poly T-72 (1,5k üçgen), Low Poly Abrams | CC-BY (atıf) | Mevcut Blender modellerimizden (23–37k üçgen, ayrıntılı) **düşük** — kullanılmamalı |
| Sketchfab CC-BY | "Military Special Forces" asker (BAMEN), rigli FBX | CC-BY | Mevcut MakeHuman tabanlı askerle karşılaştırılmalı |
| Poly Haven / ambientCG | Sahne eşyası, doku | CC0 | Zaten kullanılıyor (28 eşya) |

## 3. Ücretli adaylar (kullanıcı kararı — fiyat / lisans sayfası doğrulanmalı)
| Kaynak | İçerik | Bilinen lisans / fiyat |
|---|---|---|
| ArtStation Marketplace — "15 Game-Ready Military Vehicle + 4K Texture" | 15 optimize araç | Extended Commercial; Studio katmanı ~149,99 $ (araç listesi doğrulanmalı) |
| CGTrader — "15 Military Combat Vehicles Pack (tanks, APC, IFV, trucks)" | işaretsiz (logosuz) tank / ZPT / PSA / kamyon | Sayfada "editorial" geçiyor — **kontrol** |
| RenderHub (max3ddd) — T-72, T-34 Low-Poly PBR | oyun hazır PBR | Extended commercial (bazı RenderHub modelleri editorial) |
| Fab (Epic) | çok sayıda asker / araç paketi | Standard License (Personal < 100 bin $ gelir / Professional); Godot'ta kullanım ve "editorial" durumu ürün başına doğrulanmalı |

## 4. Öneri
1. **Animasyon: Mixamo** — ücretsiz, en hızlı görünür kazanç. Kullanıcı Mixamo'ya girip seçilen animasyonları
   (FBX, "without skin") `tools/assets_src/mixamo/` içine indirirse Blender hattı askerimizin iskeletine aktarır.
   İstenecek liste: Dying / Falling Back Death / Shot in the back / Hit reaction ×3, Crouch walk, Climbing
   (ladder / vehicle), Getting in vehicle, Prone crawl, Run to cover, Throw grenade, Rifle reload.
2. **Araçlar**: hazır gerçekçi paketlerin çoğu ya editorial ya düşük kalite. En güvenli yol mevcut Blender
   hattını (gerçek ölçülü, 23–37k üçgen) iyileştirmeye devam etmek — doku (PBR boya / kir / pas, ambientCG),
   kapak, cıvata, zincir ayrıntısı. Ücretli paket istenirse 3. bölümden lisansı "editorial" olmayan biri seçilir.
3. **Asker**: mevcut model (MakeHuman CC0 + katmanlı teçhizat) korunur; Mixamo animasyonlarıyla hareket
   kalitesi yükseltilir; gerekirse CC-BY asker modeli karşılaştırılır.

## Kaynaklar
- https://www.cgtrader.com/3d-models/abrams · https://www.cgtrader.com/3d-models/military-vehicle
- https://www.artstation.com/marketplace/p/xkaem/15-game-ready-military-vehicle-4k-texture
- https://www.cgtrader.com/3d-model-packs/15-military-combat-vehicles-pack-tanks-apc-ifv-trucks
- https://www.renderhub.com/max3ddd/t-72-soviet-main-battle-tank-low-poly-pbr
- https://www.renderhub.com/exquisite/kamaz-5350-military-truck (editorial kısıt örneği)
- https://turbosquid.com/3d-models/modern-military-ground-and-air-vehicle-collection-2459203 (editorial)
- https://sketchfab.com/3d-models/low-poly-t-72-tank-game-ready-8c9d0d6640a244e39082cd9fdf565cef
- https://sketchfab.com/3d-models/low-poly-abrams-free-model-ee925340fd0249bfac6f766c7eb81abd
- https://sketchfab.com/3d-models/free-military-soldier-rigged-e9c56308a67d4a3db62e914fafa4d198
- https://community.adobe.com/questions-696/mixamo-faq-licensing-royalties-ownership-eula-and-tos-589400
- https://community.adobe.com/questions-696/mixamo-characters-for-commercial-games-589934
- https://forums.unrealengine.com/t/fab-license/2693908
