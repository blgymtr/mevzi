# Hazır varlık kaynakları (CC0) — modelleme aşaması için

Kullanıcı önerisi (16 Ekim 2026): Poly Haven ve ambientCG. İkisi de **CC0** (ticari oyunda atıfsız kullanım
serbest; yine de `assets/CREDITS.txt`'e kaynak yazılır). Tarama: Poly Haven API (`api.polyhaven.com`),
ambientCG API (`ambientcg.com/api/v2/full_json`).

## Poly Haven (polyhaven.com) — 521 model, 869 doku, HDRI
Konuya uyan modeller:
- **Siper / sandık / ikmal (120, 36, 106):** `wooden_military_crate`, `old_military_crate`, `ammo_box`,
  `metal_jerrycan`, `metal_jerrycan_green`, `plastic_jerrycan`, `medical_box`, `russian_food_cans_01`,
  `long_life_food`, `wooden_crate_01/02`, `plastic_crate_01..03`, `cardboard_box_01`, `Barrel_01/02`,
  `barrel_03`, `propane_tank`, `small_lpg_tank`
- **Yol / şehir siperi:** `concrete_road_barrier`, `concrete_road_barrier_02`, `modular_chainlink_fence`,
  `modular_electricity_poles`, `street_lamp_01/02`, `fire_hydrant`, `utility_box_01/02`, `water_manhole_cover`
- **Hurda / sivil araç siperi:** `covered_car`, `old_tyre`, `rusted_wheel_rim_01/02`
- **Askerî teçhizat:** `old_gas_mask`, `old_military_compressor`, `portable_generator`, `hand_truck`
- **Bina cepheleri (35, 67, 69):** `modular_factory_facade`, `modular_urban_apartments_facade`,
  `rollershutter_door`, `rollershutter_window_01..03`, `modular_fire_escape`, `modular_metal_gutter`
- **Doğa:** `tree_stump_01/02`, `dead_tree_trunk_02`, `rocks` (37 model), `ground cover` (32)
- Dokular: `aerial` (30, uydu görünümlü arazi), `terrain` 131, `rock` 125, `brick` 108,
  `plaster-concrete` 136, `asphalt` 20, `road` 36, `roofing` 23, `metal` 25, `gravel`, `sand`, `snow`
- HDRI: gökyüzü / ortam ışığı (hava durumu ve günün saati)

**Uyarı:** Poly Haven ağaçları milyonlarca üçgen (`fir_tree_01` 7,8 M, `pine_tree_01` 17 M) — doğrudan
kullanılamaz; ya yalnız kabuk / yaprak dokuları alınır ya da Blender'da azaltma + impostor (kare başına
~1,1 M ilkel bütçesi, devir notu §0). Küçük eşyalar da RTS kamerası için 300–3000 üçgene indirilmeli.

## ambientCG (ambientcg.com) — PBR doku (renk, normal, pürüzlülük, AO, yükseklik)
- `Ground*` 169 (çamur, çim, toprak — arazi katmanları, 63 mat harita)
- `Bricks*` 130, `Concrete*`, `Plaster*` (67 malzemeye göre yıkım, binalar)
- `PaintedMetal001..017`, `Metal027..029`, `CorrugatedSteel*`, pas araması 58 (araç boyası / yanmış enkaz,
  hangar, çatı sacı)
- "military" / "camouflage" araması boş — kamuflaj desenleri kendi üreticimizde kalır
  (`assets/gen/camo_*`), alttaki boya / kir / pas katmanları ambientCG'den beslenebilir

## Kullanım planı
1. İndirme: her varlık kendi klasörüne (`tools/assets_src/<kaynak>/<id>/`, git dışı), 1K–2K çözünürlük.
2. Blender hattı (`tools/blender/`): içe al → azalt (decimate) → LOD0/LOD1 → doku 1K'ya küçült →
   `assets/props/<id>.glb`; çarpışma / siper yüksekliği ızgaraya (Grid) işlenir (120: fiziksel siper).
3. Arazi: ambientCG Ground dokuları `terrain.gdshader` katmanlarına (mat, düşük parlaklık).
4. Kaynak listesi `assets/CREDITS.txt`'e (CC0 olsa da).
