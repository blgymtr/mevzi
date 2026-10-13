# MEVZİ

İzometrik modern savaş RTS (Godot 4.7). Tüm grafik ve sesler kodla üretilir.

## Oynanış
- Askerler siperi kendileri bulur: alçak duvarın arkasında çömelir, kalkıp ateş eder; yüksek duvarın köşesinden eğilir.
- Yakın mermiler baskılar (yere yatarlar), patlamalar savurur. Vurulan asker sıhhiye çağırır; arkadaşları sürükleyip tedavi eder, sis bombası atabilir.
- Yapılar birlikler tarafından elle inşa edilir. Her ileri üs karargâha yol açar; ikmal kamyonları gelir taşır. Yol kesilirse gelir düşer.
- Son üssünü (karargâh dahil, ele geçirilebilir) kaybeden taraf yenilir.

## Kontroller
| Tuş | İşlev |
|---|---|
| Sol tık / sürükle | Seç (tık: tüm tim, Alt+tık: tek asker, çift tık: aynı türdekiler) |
| Sağ tık | Git / saldır / inşa et / yaralıyı kurtar |
| Ctrl + sağ tık | Koşarak git (çatışmaya girmeden) |
| WASD, kenar, orta tuş | Kamera |
| Tekerlek | Yakınlaştır |
| Ctrl+1-9 / 1-9 | Grup ata / seç |
| Q / E | Ekrandaki piyadeyi / araçları seç |
| X | Dur |
| R | Yerleştirirken döndür |
| H | Karargâha git |
| F1-F3 | Oyun hızı |
| Esc / P | Duraklat |

## Geliştirme
- `./check.sh` — betik hataları
- `./shot.sh desert|winter|test` — ekran görüntüsü / akış testi
- `godot --path . -- --autoplay=900 --scene=desert` — yapay zekâ maçı
- `python tools/gen_audio.py` — sesleri yeniden üret
- Export: `godot --headless --path . --export-release "Windows Desktop" build/Mevzi.exe`
