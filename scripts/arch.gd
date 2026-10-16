class_name Arch extends RefCounted
# Bina arketipleri: 100'den fazla adlandırılmış sivil / kentsel / sanayi yapı türü.
# Her arketip: taban şekli (dikdörtgen, L, U, avlulu, sıra, sekizgen, hücre), kat sayısı, çatı tipi,
# cephe malzemesi (sıva, tuğla, taş, ahşap, kütük, sac, panel, kerpiç), renk paleti ve detay listesi.
# Duvarlar yıkılabilir blok (Blocks.wall_line); zemin kat kapı/pencere boşlukları girilebilir
# (MapGen._house_slots). Kanat başına iki düğüm: çatı (garnizonda ve çökünce gizlenir) ve cephe süsü
# (yalnız çökünce gizlenir). Haritaya MapGen işlemi {"t": "bld", "a": kimlik, ...} ile yerleşir.

# cephe malzemesi → blok rengi alfa kodu (masonry.gdshader: kimlik = round((1 - a) * 10))
const FAC_A := {"stone": 0.9, "timber": 0.8, "metal": 0.7, "panel": 0.6, "adobe": 0.5, "brick": 0.4, "plaster": 0.3, "steel": 0.2, "log": 0.1, "conc": 0.0}
# blok tipi: kaba taş/kerpiç yuvarlak kenarlı, diğerleri keskin
const FAC_T := {"stone": 0, "adobe": 0, "log": 0}
const FAC_JIT := {"stone": 0.09, "timber": 0.05, "metal": 0.015, "panel": 0.02, "adobe": 0.05, "brick": 0.07, "plaster": 0.014, "steel": 0.012, "log": 0.07, "conc": 0.02}

const PAL := {
	"krem": [Color(0.9, 0.84, 0.7), Color(0.86, 0.76, 0.58), Color(0.92, 0.88, 0.78), Color(0.84, 0.7, 0.52), Color(0.94, 0.9, 0.82), Color(0.88, 0.8, 0.64)],
	"pastel": [Color(0.72, 0.8, 0.86), Color(0.78, 0.86, 0.76), Color(0.92, 0.78, 0.74), Color(0.94, 0.88, 0.66), Color(0.82, 0.78, 0.86), Color(0.95, 0.82, 0.62)],
	"beyaz": [Color(0.95, 0.94, 0.9), Color(0.92, 0.92, 0.88), Color(0.9, 0.88, 0.82)],
	"canli": [Color(0.85, 0.48, 0.34), Color(0.4, 0.58, 0.72), Color(0.92, 0.74, 0.34), Color(0.52, 0.7, 0.52), Color(0.8, 0.36, 0.3), Color(0.62, 0.5, 0.72)],
	"tugla": [Color(0.66, 0.34, 0.24), Color(0.6, 0.3, 0.22), Color(0.72, 0.4, 0.28), Color(0.56, 0.3, 0.24)],
	"tas": [Color(0.8, 0.76, 0.68), Color(0.72, 0.68, 0.6), Color(0.86, 0.8, 0.66), Color(0.66, 0.64, 0.6)],
	"kerpic": [Color(0.8, 0.66, 0.48), Color(0.76, 0.6, 0.44), Color(0.84, 0.72, 0.54), Color(0.72, 0.58, 0.42)],
	"ahsap": [Color(0.58, 0.45, 0.32), Color(0.5, 0.38, 0.28), Color(0.64, 0.52, 0.4), Color(0.46, 0.38, 0.32)],
	"kirmizi": [Color(0.62, 0.2, 0.16), Color(0.56, 0.18, 0.14), Color(0.66, 0.26, 0.2)],
	"gri": [Color(0.64, 0.64, 0.62), Color(0.72, 0.72, 0.7), Color(0.58, 0.59, 0.6)],
	"sac": [Color(0.74, 0.76, 0.78), Color(0.42, 0.52, 0.62), Color(0.46, 0.58, 0.44), Color(0.66, 0.34, 0.26), Color(0.88, 0.86, 0.8)],
	"panel": [Color(0.76, 0.74, 0.7), Color(0.82, 0.8, 0.74), Color(0.7, 0.72, 0.74)],
}
const ROOF_COL := {
	"clay": [Color(0.62, 0.3, 0.18), Color(0.56, 0.26, 0.16), Color(0.68, 0.36, 0.22)],
	"tile": [Color(0.6, 0.32, 0.22), Color(0.48, 0.3, 0.24), Color(0.56, 0.36, 0.28)],
	"slate": [Color(0.42, 0.44, 0.48), Color(0.36, 0.38, 0.4), Color(0.48, 0.48, 0.5)],
	"metal": [Color(0.62, 0.22, 0.18), Color(0.3, 0.46, 0.32), Color(0.32, 0.42, 0.56), Color(0.62, 0.64, 0.66), Color(0.5, 0.5, 0.52)],
	"rust": [Color(0.55, 0.4, 0.3), Color(0.5, 0.42, 0.36)],
	"conc": [Color(0.58, 0.57, 0.55), Color(0.5, 0.5, 0.49)],
	"lead": [Color(0.52, 0.56, 0.6), Color(0.48, 0.52, 0.56)],
	"copper": [Color(0.42, 0.62, 0.52)],
	"mud": [Color(0.7, 0.58, 0.42), Color(0.66, 0.54, 0.4)],
	"wood": [Color(0.46, 0.36, 0.28), Color(0.4, 0.32, 0.26)],
}

# k: kır / köy / kasaba / şehir / sanayi / çöl / kış · b: uygun biyom (g yeşil, w kış, d çöl)
# w, d: genişlik (cephe) / derinlik aralığı · fl: kat · fh: tek katlı salon yüksekliği (m)
# fp: rect / L / U / court / T / row / oct / grid / open · rf: flat gable hip shed mansard gambrel saw barrel cone sera (kubbe yok — dini yapıya benzer)
# rm: çatı dokusu · pit: eğim · gf: alınlık cephede (mahya derinlikte) · f: cephe · p: palet · pl: taş/beton kaide
# wk: pencere (std small slit tall shop band high arch none) · ws: pencere aralığı · dr: kapı (std dbl wide roll gar arc) · sym: ortada kapı
# x: detaylar
const ARCH := {
	# ---------------------------------------------------------------- kır
	"ciftlik_evi": {"n": "Çiftlik evi", "k": "kir", "b": "gw", "w": [8, 10], "d": [6.5, 8], "fl": [2, 2], "rf": "gable", "rm": "clay", "f": "plaster", "p": "krem", "x": ["chim", "porch", "shut", "gutter", "fence", "solar"]},
	"ahir": {"n": "Ahır", "k": "kir", "b": "gwd", "w": [11, 14], "d": [7, 9], "fl": [1, 1], "fh": 4.4, "rf": "gable", "gf": true, "rm": "metal", "f": "timber", "p": "kirmizi", "wk": "small", "dr": "wide", "sym": true, "x": ["loft", "cupola", "hay", "trim_white"]},
	"kirma_ambar": {"n": "Kırma çatılı ambar", "k": "kir", "b": "gw", "w": [10, 12], "d": [12, 15], "fl": [1, 1], "fh": 3.6, "rf": "gambrel", "gf": true, "rm": "slate", "f": "timber", "p": "kirmizi", "wk": "small", "dr": "wide", "sym": true, "x": ["loft", "cupola", "trim_white", "hay"]},
	"at_ahiri": {"n": "At ahırı", "k": "kir", "b": "gwd", "w": [13, 16], "d": [5, 6], "fl": [1, 1], "fh": 3.0, "rf": "shed", "rm": "metal", "f": "timber", "p": "ahsap", "wk": "small", "ws": 2.2, "x": ["halfdoors", "paddock", "hay"]},
	"silolu_ambar": {"n": "Silolu çiftlik ambarı", "k": "kir", "b": "gw", "w": [10, 12], "d": [7, 8], "fl": [1, 1], "fh": 4.2, "rf": "gable", "gf": true, "rm": "metal", "f": "metal", "p": "sac", "wk": "small", "dr": "wide", "sym": true, "x": ["silo2", "loft"], "ext": 5.0},
	"sera": {"n": "Sera", "k": "kir", "b": "gd", "w": [6, 7], "d": [13, 16], "fl": [1, 1], "fh": 0.85, "rf": "sera", "f": "conc", "p": "gri", "wk": "none", "dr": "none", "x": ["plants"]},
	"besi_ahiri": {"n": "Besi ahırı", "k": "kir", "b": "gw", "w": [15, 18], "d": [8, 10], "fl": [1, 1], "fh": 3.4, "rf": "gable", "rm": "metal", "f": "brick", "p": "tugla", "wk": "band", "ws": 3.0, "x": ["ridgevent", "hay", "silo1"], "ext": 4.0},
	"kuyu_evi": {"n": "Kuyu evi", "k": "kir", "b": "gwd", "w": [3.4, 3.8], "d": [3.4, 3.8], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "stone", "p": "tas", "wk": "small", "x": ["well"]},
	"saman_sundurma": {"n": "Saman sundurması", "k": "kir", "b": "gwd", "w": [8, 10], "d": [6, 7], "fl": [1, 1], "fh": 4.0, "fp": "open", "rf": "gable", "rm": "rust", "f": "timber", "p": "ahsap", "x": ["hay_in"]},
	"kumes": {"n": "Kümes", "k": "kir", "b": "gwd", "w": [4.5, 5.5], "d": [3, 3.5], "fl": [1, 1], "fh": 2.1, "rf": "shed", "rm": "metal", "f": "timber", "p": "ahsap", "wk": "small", "x": ["coop_run"]},
	"yel_degirmeni": {"n": "Yel değirmeni", "k": "kir", "b": "gwd", "w": [5.5, 6], "d": [5.5, 6], "fl": [1, 1], "fh": 8.0, "fp": "oct", "rf": "cone", "rm": "wood", "f": "stone", "p": "beyaz", "wk": "small", "x": ["sails"]},
	"traktor_garaji": {"n": "Traktör garajı", "k": "kir", "b": "gwd", "w": [8, 10], "d": [6, 8], "fl": [1, 1], "fh": 3.8, "rf": "shed", "rm": "metal", "f": "metal", "p": "sac", "wk": "small", "dr": "roll", "x": ["tires", "barrels"]},
	"bag_evi": {"n": "Bağ evi", "k": "kir", "b": "gd", "w": [5, 6], "d": [4, 5], "fl": [1, 1], "rf": "gable", "rm": "clay", "f": "stone", "p": "tas", "wk": "small", "x": ["perg", "chim"]},
	"tutun_ambari": {"n": "Tütün kurutma ambarı", "k": "kir", "b": "gw", "w": [6, 7], "d": [9, 11], "fl": [2, 2], "rf": "gable", "pit": 1.15, "gf": true, "rm": "clay", "f": "timber", "p": "ahsap", "wk": "slit", "ws": 1.6, "x": ["loft", "tobacco"]},
	"coban_kulubesi": {"n": "Çoban kulübesi", "k": "kir", "b": "gwd", "w": [3.6, 4.4], "d": [3, 3.4], "fl": [1, 1], "fh": 2.5, "rf": "flat", "rm": "mud", "f": "stone", "p": "tas", "wk": "small", "x": ["chim", "earthroof"]},
	"yayla_evi": {"n": "Yayla evi", "k": "kir", "b": "gw", "w": [7, 8.5], "d": [6, 7], "fl": [2, 2], "rf": "gable", "rm": "metal", "f": "timber", "p": "ahsap", "pl": "stone", "x": ["bal_wood", "chim"]},
	"sut_toplama": {"n": "Süt toplama merkezi", "k": "kir", "b": "gw", "w": [8, 9], "d": [5, 6], "fl": [1, 1], "rf": "gable", "rm": "metal", "f": "plaster", "p": "beyaz", "x": ["sign", "milktank", "dock"]},
	"tahil_ambari": {"n": "Tahıl ambarı", "k": "kir", "b": "gwd", "w": [6, 8], "d": [5, 6], "fl": [1, 1], "fh": 3.2, "rf": "gable", "gf": true, "rm": "metal", "f": "brick", "p": "tugla", "pl": "stone", "wk": "slit", "x": ["loft", "sacks"]},
	# ---------------------------------------------------------------- köy
	"tas_ev": {"n": "Taş ev", "k": "koy", "b": "gwd", "w": [6, 8], "d": [5, 6], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "stone", "p": "tas", "x": ["chim", "shut"]},
	"koy_evi": {"n": "İki katlı köy evi", "k": "koy", "b": "gw", "w": [7, 9], "d": [6, 7], "fl": [2, 2], "rf": "gable", "rm": "clay", "f": "plaster", "p": "krem", "x": ["bal_wood", "chim", "shut", "extstair"]},
	"cumbali_ev": {"n": "Cumbalı ev", "k": "koy", "b": "gw", "w": [7, 9], "d": [7, 8], "fl": [2, 2], "rf": "hip", "rm": "clay", "f": "plaster", "p": "pastel", "pl": "stone", "x": ["cumba", "tframe", "chim", "wide_eave"]},
	"firin": {"n": "Fırın", "k": "koy", "b": "gwd", "w": [6, 8], "d": [5.5, 7], "fl": [1, 1], "rf": "gable", "rm": "clay", "f": "plaster", "p": "krem", "wk": "shop", "x": ["bigchim", "sign", "awn", "bread"], "sign": "FIRIN"},
	"kahvehane": {"n": "Kahvehane", "k": "koy", "b": "gwd", "w": [7, 9], "d": [6, 7], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "plaster", "p": "krem", "wk": "shop", "x": ["awn", "sign", "tables", "perg"], "sign": "KAHVE"},
	"bakkal": {"n": "Bakkal", "k": "koy", "b": "gwd", "w": [5.5, 7], "d": [5, 6], "fl": [1, 2], "rf": "gable", "rm": "tile", "f": "plaster", "p": "canli", "wk": "shop", "x": ["sign", "rollshut", "crates", "awn"], "sign": "BAKKAL"},
	"koy_okulu": {"n": "Köy okulu", "k": "koy", "b": "gwd", "w": [14, 18], "d": [7, 8], "fl": [1, 1], "fh": 3.4, "rf": "hip", "rm": "clay", "f": "plaster", "p": "krem", "wk": "tall", "ws": 2.2, "sym": true, "x": ["flag", "steps", "yard_fence", "sign"], "sign": "İLKOKULU", "ext": 3.0},
	"muhtarlik": {"n": "Muhtarlık", "k": "koy", "b": "gwd", "w": [6, 7], "d": [5, 6], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "plaster", "p": "beyaz", "sym": true, "x": ["flag", "sign", "bench", "board"], "sign": "MUHTARLIK"},
	"ptt": {"n": "PTT şubesi", "k": "koy", "b": "gwd", "w": [8, 10], "d": [7, 8], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "krem", "sym": true, "x": ["sign_y", "mailbox", "ac"], "sign": "PTT"},
	"jandarma": {"n": "Jandarma karakolu", "k": "koy", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "krem", "sym": true, "x": ["flag", "sandbag", "cwall", "watchtower", "bars", "mast"], "sign": "JANDARMA", "ext": 5.0},
	"saglik_ocagi": {"n": "Sağlık ocağı", "k": "koy", "b": "gwd", "w": [10, 12], "d": [7, 9], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "plaster", "p": "beyaz", "sym": true, "x": ["redcross", "ramp", "sign", "canopy"], "sign": "SAĞLIK OCAĞI"},
	"konak": {"n": "Köy konağı", "k": "koy", "b": "gw", "w": [14, 17], "d": [11, 13], "fl": [2, 2], "fp": "U", "rf": "hip", "rm": "clay", "f": "plaster", "p": "krem", "pl": "stone", "x": ["cumba", "chim", "shut", "wide_eave"]},
	"kasap": {"n": "Kasap", "k": "koy", "b": "gwd", "w": [5, 6], "d": [5, 6], "fl": [1, 1], "rf": "gable", "rm": "tile", "f": "plaster", "p": "beyaz", "wk": "shop", "x": ["sign_r", "awn"], "sign": "KASAP"},
	"demirci": {"n": "Demirci", "k": "koy", "b": "gwd", "w": [6, 7.5], "d": [5, 6], "fl": [1, 1], "rf": "shed", "rm": "rust", "f": "stone", "p": "tas", "wk": "small", "dr": "wide", "x": ["bigchim", "anvil", "logs"]},
	"han": {"n": "Han (kervansaray)", "k": "koy", "b": "gwd", "w": [20, 24], "d": [20, 24], "fl": [2, 2], "fp": "court", "rf": "flat", "rm": "conc", "f": "stone", "p": "tas", "wk": "small", "dr": "arc", "sym": true, "x": ["cren_low"]},
	"su_degirmeni": {"n": "Su değirmeni", "k": "koy", "b": "gw", "w": [6, 7], "d": [5, 6], "fl": [1, 1], "rf": "gable", "rm": "clay", "f": "stone", "p": "tas", "wk": "small", "x": ["wheel", "sacks"]},
	"lojman": {"n": "Öğretmen lojmanı", "k": "koy", "b": "gwd", "w": [7, 8.5], "d": [6, 7], "fl": [2, 2], "rf": "hip", "rm": "clay", "f": "plaster", "p": "pastel", "sym": true, "x": ["bal", "chim", "fence", "dish"]},
	"kooperatif": {"n": "Tarım kooperatifi", "k": "koy", "b": "gwd", "w": [10, 12], "d": [8, 9], "fl": [1, 1], "fh": 3.6, "rf": "gable", "rm": "metal", "f": "plaster", "p": "krem", "dr": "roll", "x": ["sign", "dock", "sacks"], "sign": "KOOPERATİF"},
	# ---------------------------------------------------------------- kasaba / şehir
	"sira_ev": {"n": "Sıra evler", "k": "kasaba", "b": "gw", "w": [16, 22], "d": [8, 9], "fl": [2, 2], "fp": "row", "rf": "gable", "rm": "clay", "f": "plaster", "p": "pastel", "x": ["chim", "shut", "steps"]},
	"sira_ev_3": {"n": "Üç katlı sıra ev", "k": "kasaba", "b": "gw", "w": [16, 20], "d": [9, 10], "fl": [3, 3], "fp": "row", "rf": "mansard", "rm": "slate", "f": "brick", "p": "tugla", "x": ["dormer", "chim", "steps", "bal_small"]},
	"kose_dukkan": {"n": "Köşe dükkânı", "k": "kasaba", "b": "gwd", "w": [7, 9], "d": [7, 9], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "canli", "wk": "shop", "x": ["shop2", "sign", "awn", "bal", "ac"], "sign": "MARKET"},
	"dukkanli_apt": {"n": "Dükkânlı apartman", "k": "sehir", "b": "gwd", "w": [10, 13], "d": [9, 11], "fl": [3, 4], "rf": "flat", "f": "plaster", "p": "krem", "wk": "shop", "x": ["bal", "ac", "dish", "tank", "solar", "sign", "rollbox"], "sign": "TERZİ"},
	"apartman_3": {"n": "Apartman (3 katlı)", "k": "sehir", "b": "gwd", "w": [10, 12], "d": [9, 11], "fl": [3, 3], "rf": "flat", "f": "plaster", "p": "pastel", "x": ["bal", "ac", "solar", "dish", "tank", "rollbox", "laundry"]},
	"apartman_4": {"n": "Apartman (4 katlı)", "k": "sehir", "b": "gw", "w": [12, 14], "d": [10, 12], "fl": [4, 4], "rf": "hip", "rm": "clay", "f": "plaster", "p": "krem", "x": ["bal", "ac", "dish", "rollbox", "bands"]},
	"apartman_5": {"n": "Apartman (5 katlı)", "k": "sehir", "b": "gwd", "w": [13, 15], "d": [11, 13], "fl": [5, 5], "rf": "flat", "f": "plaster", "p": "canli", "x": ["balband", "lift", "ac", "dish", "solar", "bands"]},
	"l_blok": {"n": "L blok apartman", "k": "sehir", "b": "gwd", "w": [16, 19], "d": [14, 16], "fl": [3, 4], "fp": "L", "rf": "flat", "f": "plaster", "p": "pastel", "x": ["bal", "ac", "dish", "tank", "rollbox"]},
	"panel_blok": {"n": "Prefabrik panel blok", "k": "sehir", "b": "gw", "w": [18, 22], "d": [10, 11], "fl": [5, 5], "rf": "flat", "f": "panel", "p": "panel", "x": ["loggia", "lift", "ant", "panels"]},
	"eczane": {"n": "Eczane", "k": "kasaba", "b": "gwd", "w": [6, 8], "d": [6, 7], "fl": [1, 2], "rf": "flat", "f": "plaster", "p": "beyaz", "wk": "shop", "x": ["sign_g", "awn", "ac"], "sign": "ECZANE"},
	"banka": {"n": "Banka", "k": "sehir", "b": "gwd", "w": [10, 12], "d": [9, 10], "fl": [2, 2], "rf": "flat", "f": "stone", "p": "tas", "wk": "tall", "sym": true, "x": ["portico", "sign", "cornice", "atm", "steps"], "sign": "BANKA"},
	"otel": {"n": "Otel", "k": "sehir", "b": "gwd", "w": [12, 15], "d": [10, 12], "fl": [4, 4], "rf": "flat", "f": "plaster", "p": "krem", "sym": true, "x": ["roofsign", "bal", "canopy", "flags", "ac"], "sign": "OTEL"},
	"sinema": {"n": "Sinema", "k": "sehir", "b": "gwd", "w": [12, 14], "d": [16, 19], "fl": [1, 1], "fh": 7.0, "rf": "gable", "gf": true, "pit": 0.35, "rm": "metal", "f": "plaster", "p": "canli", "wk": "none", "sym": true, "x": ["marquee", "posters", "falsefront"], "sign": "SİNEMA"},
	"hal": {"n": "Kapalı çarşı (hal)", "k": "sehir", "b": "gwd", "w": [16, 20], "d": [12, 14], "fl": [1, 1], "fh": 5.6, "rf": "barrel", "rm": "metal", "f": "brick", "p": "tugla", "wk": "arch", "ws": 3.2, "dr": "arc", "sym": true, "x": ["stalls", "sign", "clerestory"], "sign": "HAL"},
	"otogar": {"n": "Otogar", "k": "sehir", "b": "gwd", "w": [20, 24], "d": [8, 9], "fl": [1, 1], "fh": 3.6, "rf": "flat", "f": "plaster", "p": "beyaz", "wk": "shop", "sym": true, "x": ["platform", "sign", "benches"], "sign": "OTOGAR", "ext": 6.0},
	"itfaiye": {"n": "İtfaiye", "k": "sehir", "b": "gwd", "w": [14, 16], "d": [10, 12], "fl": [2, 2], "rf": "flat", "f": "brick", "p": "tugla", "dr": "fire", "x": ["hosetower", "sign", "siren"], "sign": "İTFAİYE"},
	"belediye": {"n": "Belediye binası", "k": "sehir", "b": "gwd", "w": [16, 20], "d": [12, 14], "fl": [3, 3], "rf": "hip", "rm": "slate", "f": "stone", "p": "tas", "wk": "tall", "sym": true, "x": ["clocktower", "flags", "portico", "steps", "cornice"], "sign": "BELEDİYE"},
	"lokanta": {"n": "Lokanta", "k": "kasaba", "b": "gwd", "w": [8, 10], "d": [7, 8], "fl": [1, 1], "rf": "gable", "rm": "clay", "f": "plaster", "p": "krem", "wk": "shop", "x": ["awn", "tables", "sign"], "sign": "LOKANTA"},
	"berber": {"n": "Berber", "k": "kasaba", "b": "gwd", "w": [4.5, 5.5], "d": [5, 6], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "pastel", "wk": "shop", "x": ["barberpole", "sign"], "sign": "BERBER"},
	"arasta": {"n": "Dükkân sırası (arasta)", "k": "kasaba", "b": "gwd", "w": [16, 21], "d": [6, 7], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "krem", "wk": "shop", "ws": 4.0, "x": ["rollshut", "signs", "awns", "crates"]},
	"benzinlik": {"n": "Akaryakıt istasyonu", "k": "kasaba", "b": "gwd", "w": [8, 10], "d": [6, 7], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "beyaz", "wk": "shop", "x": ["gascanopy", "pylon", "sign"], "sign": "MARKET", "ext": 9.0},
	"oto_tamir": {"n": "Oto tamirhanesi", "k": "kasaba", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [1, 1], "fh": 4.0, "rf": "shed", "rm": "metal", "f": "brick", "p": "tugla", "dr": "gar2", "x": ["tires", "sign", "barrels", "wreck"], "sign": "OTO TAMİR"},
	"emniyet": {"n": "Emniyet müdürlüğü", "k": "sehir", "b": "gwd", "w": [16, 18], "d": [12, 14], "fl": [3, 3], "rf": "flat", "f": "conc", "p": "gri", "sym": true, "x": ["flags", "barriers", "bars", "mast", "sign", "bands"], "sign": "EMNİYET"},
	"hastane": {"n": "Hastane", "k": "sehir", "b": "gwd", "w": [22, 26], "d": [18, 20], "fl": [4, 4], "fp": "L", "rf": "flat", "f": "plaster", "p": "beyaz", "x": ["redcross", "helipad", "canopy", "lift", "bands", "ac"], "sign": "HASTANE"},
	"lise": {"n": "Lise", "k": "sehir", "b": "gwd", "w": [24, 28], "d": [16, 19], "fl": [3, 3], "fp": "U", "rf": "hip", "rm": "clay", "f": "brick", "p": "tugla", "wk": "tall", "sym": true, "x": ["flag", "sign", "steps", "bands"], "sign": "LİSESİ"},
	"kutuphane": {"n": "Kütüphane", "k": "sehir", "b": "gwd", "w": [12, 14], "d": [10, 12], "fl": [2, 2], "rf": "hip", "rm": "slate", "f": "stone", "p": "tas", "wk": "tall", "sym": true, "x": ["portico", "steps", "cornice", "sign"], "sign": "KÜTÜPHANE"},
	"ishani": {"n": "İşhanı (ofis bloğu)", "k": "sehir", "b": "gwd", "w": [12, 14], "d": [12, 14], "fl": [5, 5], "rf": "flat", "f": "conc", "p": "gri", "wk": "band", "x": ["signs_v", "ac", "ant", "lift", "bands"]},
	"villa": {"n": "Villa", "k": "kasaba", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [2, 2], "rf": "hip", "rm": "clay", "f": "plaster", "p": "beyaz", "x": ["bal", "perg", "cwall_low", "pool", "garage_side"], "ext": 4.0},
	"mustakil_ev": {"n": "Garajlı müstakil ev", "k": "kasaba", "b": "gwd", "w": [10, 12], "d": [9, 10], "fl": [1, 1], "fp": "L", "rf": "gable", "rm": "tile", "f": "plaster", "p": "pastel", "x": ["chim", "picket", "garage_wing", "gutter"]},
	"gecekondu": {"n": "Gecekondu", "k": "kasaba", "b": "gwd", "w": [5, 6.5], "d": [4.5, 5.5], "fl": [1, 1], "fh": 2.5, "rf": "shed", "rm": "rust", "f": "brick", "p": "tugla", "wk": "small", "x": ["patch", "roofstones", "laundry", "stovepipe"]},
	"istasyon": {"n": "Tren istasyonu", "k": "sehir", "b": "gwd", "w": [16, 20], "d": [8, 9], "fl": [2, 2], "rf": "hip", "rm": "clay", "f": "stone", "p": "tas", "wk": "tall", "sym": true, "x": ["platform", "clock", "sign", "benches"], "sign": "İSTASYON", "ext": 6.0},
	"spor_salonu": {"n": "Spor salonu", "k": "sehir", "b": "gwd", "w": [18, 22], "d": [14, 16], "fl": [1, 1], "fh": 7.0, "rf": "barrel", "rm": "metal", "f": "panel", "p": "panel", "wk": "high", "sym": true, "x": ["sign", "canopy"], "sign": "SPOR SALONU"},
	"pastane": {"n": "Pastane", "k": "kasaba", "b": "gwd", "w": [6, 8], "d": [6, 7], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "pastel", "wk": "shop", "x": ["umbrellas", "awn", "sign", "bal"], "sign": "PASTANE"},
	"supermarket": {"n": "Süpermarket", "k": "sehir", "b": "gwd", "w": [18, 22], "d": [14, 16], "fl": [1, 1], "fh": 4.6, "rf": "flat", "f": "panel", "p": "beyaz", "wk": "shop", "ws": 3.6, "sym": true, "x": ["bigsign", "carts", "roofac", "canopy"], "sign": "SÜPERMARKET"},
	"telekom": {"n": "Telekom santrali", "k": "sehir", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [2, 2], "rf": "flat", "f": "conc", "p": "gri", "wk": "small", "x": ["latticemast", "dish", "sign", "ac"], "sign": "TELEKOM"},
	"pansiyon": {"n": "Pansiyon", "k": "kasaba", "b": "gwd", "w": [9, 11], "d": [7, 8], "fl": [2, 2], "rf": "gable", "rm": "clay", "f": "plaster", "p": "beyaz", "x": ["bal_wood", "flowers", "sign", "perg", "shut"], "sign": "PANSİYON"},
	"dugun_salonu": {"n": "Düğün salonu", "k": "sehir", "b": "gwd", "w": [14, 16], "d": [12, 14], "fl": [1, 1], "fh": 5.0, "rf": "flat", "f": "plaster", "p": "canli", "wk": "tall", "sym": true, "x": ["bigsign", "canopy", "lights"], "sign": "DÜĞÜN SALONU"},
	"askerlik_subesi": {"n": "Askerlik şubesi", "k": "sehir", "b": "gwd", "w": [12, 14], "d": [10, 12], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "krem", "sym": true, "x": ["flag", "cwall", "sentry", "bars", "sign"], "sign": "ASKERLİK ŞUBESİ", "ext": 5.0},
	"carsi_evi": {"n": "Osmanlı çarşı evi", "k": "kasaba", "b": "gw", "w": [6, 7], "d": [8, 9], "fl": [3, 3], "rf": "hip", "rm": "clay", "f": "plaster", "p": "pastel", "pl": "stone", "wk": "shop", "x": ["cumba", "tframe", "shut", "wide_eave", "sign"], "sign": "AKTAR"},
	# ---------------------------------------------------------------- sanayi
	"depo": {"n": "Depo", "k": "sanayi", "b": "gwd", "w": [18, 24], "d": [12, 16], "fl": [1, 1], "fh": 6.0, "rf": "gable", "pit": 0.22, "rm": "metal", "f": "metal", "p": "sac", "wk": "high", "dr": "roll2", "x": ["dock", "sign", "pallets"], "sign": "DEPO"},
	"atolye": {"n": "Atölye", "k": "sanayi", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [1, 1], "fh": 4.2, "rf": "shed", "rm": "metal", "f": "brick", "p": "tugla", "wk": "high", "dr": "roll", "x": ["stovepipe", "crates", "sign"], "sign": "ATÖLYE"},
	"fabrika": {"n": "Testere çatılı fabrika", "k": "sanayi", "b": "gwd", "w": [20, 26], "d": [16, 20], "fl": [1, 1], "fh": 6.0, "rf": "saw", "rm": "metal", "f": "brick", "p": "tugla", "wk": "high", "dr": "roll2", "x": ["stack", "sign", "pallets"], "sign": "FABRİKA", "ext": 4.0},
	"soguk_hava": {"n": "Soğuk hava deposu", "k": "sanayi", "b": "gwd", "w": [16, 20], "d": [12, 14], "fl": [1, 1], "fh": 6.0, "rf": "flat", "f": "panel", "p": "beyaz", "wk": "none", "dr": "dock3", "x": ["roofac", "dock", "sign"], "sign": "SOĞUK HAVA DEPOSU"},
	"su_kulesi": {"n": "Su kulesi ve pompa evi", "k": "sanayi", "b": "gwd", "w": [4.5, 5], "d": [4, 4.5], "fl": [1, 1], "rf": "flat", "f": "brick", "p": "tugla", "wk": "small", "x": ["wtower"], "ext": 6.0},
	"trafo": {"n": "Trafo merkezi", "k": "sanayi", "b": "gwd", "w": [5, 6], "d": [4, 5], "fl": [1, 1], "fh": 3.2, "rf": "flat", "f": "brick", "p": "tugla", "wk": "small", "x": ["transformers", "warn"], "ext": 6.0},
	"akaryakit_depo": {"n": "Akaryakıt depolama tesisi", "k": "sanayi", "b": "gwd", "w": [5, 6], "d": [4, 5], "fl": [1, 1], "rf": "flat", "f": "conc", "p": "gri", "wk": "small", "x": ["ftanks"], "ext": 13.0},
	"tahil_elevatoru": {"n": "Tahıl elevatörü", "k": "sanayi", "b": "gwd", "w": [6, 7], "d": [6, 7], "fl": [5, 6], "rf": "gable", "rm": "metal", "f": "conc", "p": "gri", "wk": "small", "x": ["silo4", "conveyor"], "ext": 9.0},
	"demiryolu_hangari": {"n": "Demiryolu hangarı", "k": "sanayi", "b": "gwd", "w": [12, 14], "d": [24, 28], "fl": [1, 1], "fh": 7.0, "rf": "gable", "gf": true, "pit": 0.45, "rm": "metal", "f": "brick", "p": "tugla", "wk": "arch", "ws": 3.4, "dr": "arc", "sym": true, "x": ["rails", "clerestory", "ridgevent"]},
	"kazan_dairesi": {"n": "Kazan dairesi", "k": "sanayi", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [1, 1], "fh": 5.0, "rf": "gable", "rm": "metal", "f": "brick", "p": "tugla", "wk": "arch", "x": ["stack", "pipes"], "ext": 4.0},
	"fabrika_idare": {"n": "Fabrika idare binası", "k": "sanayi", "b": "gwd", "w": [14, 16], "d": [9, 10], "fl": [2, 2], "rf": "flat", "f": "brick", "p": "tugla", "wk": "tall", "sym": true, "x": ["sign", "flag", "clock", "bands"], "sign": "İDARE"},
	"hangar": {"n": "Yarım silindir hangar", "k": "sanayi", "b": "gwd", "w": [12, 14], "d": [18, 22], "fl": [1, 1], "fh": 2.6, "rf": "barrel", "gf": true, "pit": 1.0, "rm": "metal", "f": "metal", "p": "sac", "wk": "none", "dr": "roll", "x": ["sign"], "sign": "HANGAR"},
	"un_fabrikasi": {"n": "Un fabrikası", "k": "sanayi", "b": "gwd", "w": [12, 14], "d": [10, 12], "fl": [5, 5], "rf": "gable", "rm": "metal", "f": "brick", "p": "tugla", "wk": "arch", "x": ["paintsign", "hoist", "silo2"], "sign": "UN FABRİKASI", "ext": 5.0},
	"hizar": {"n": "Kereste atölyesi (hızar)", "k": "sanayi", "b": "gw", "w": [12, 14], "d": [8, 10], "fl": [1, 1], "fh": 4.0, "fp": "open", "rf": "gable", "rm": "metal", "f": "timber", "p": "ahsap", "x": ["logs", "planks", "saw"]},
	"pompa_istasyonu": {"n": "Pompa istasyonu", "k": "sanayi", "b": "gwd", "w": [5, 6], "d": [4, 5], "fl": [1, 1], "rf": "flat", "f": "conc", "p": "gri", "wk": "small", "x": ["pipes", "fence_mesh", "warn"]},
	"garaj_sirasi": {"n": "Garaj sırası", "k": "sanayi", "b": "gwd", "w": [14, 18], "d": [5.5, 6], "fl": [1, 1], "fh": 2.8, "rf": "shed", "rm": "metal", "f": "brick", "p": "tugla", "wk": "none", "dr": "garrow", "x": []},
	"lpg_dolum": {"n": "LPG dolum tesisi", "k": "sanayi", "b": "gwd", "w": [6, 7], "d": [5, 6], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "beyaz", "x": ["sphere", "fence_mesh", "warn", "sign"], "sign": "LPG", "ext": 10.0},
	"tugla_harmani": {"n": "Tuğla harmanı", "k": "sanayi", "b": "gwd", "w": [10, 12], "d": [8, 10], "fl": [1, 1], "fh": 4.0, "rf": "gable", "rm": "rust", "f": "brick", "p": "tugla", "wk": "arch", "x": ["stack", "brickstacks"], "ext": 5.0},
	"beton_santrali": {"n": "Beton santrali", "k": "sanayi", "b": "gwd", "w": [6, 7], "d": [5, 6], "fl": [1, 1], "rf": "flat", "f": "metal", "p": "sac", "wk": "small", "x": ["silo1", "conveyor", "gravel"], "ext": 8.0},
	# ---------------------------------------------------------------- çöl
	"kerpic_ev": {"n": "Kerpiç ev", "k": "col", "b": "d", "w": [6, 8], "d": [5, 6], "fl": [1, 1], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "small", "x": ["viga", "cwall_mud", "jars", "roofladder"], "ext": 3.0},
	"avlulu_ev": {"n": "Avlulu ev", "k": "col", "b": "d", "w": [12, 14], "d": [10, 12], "fl": [1, 1], "fp": "U", "rf": "flat", "rm": "mud", "f": "plaster", "p": "beyaz", "wk": "small", "x": ["courtwall", "viga", "tank", "cren_low"]},
	"sarnic": {"n": "Sarnıç", "k": "col", "b": "gd", "w": [6, 8], "d": [4.5, 6], "fl": [1, 1], "fh": 1.3, "rf": "vault", "rm": "mud", "f": "stone", "p": "tas", "wk": "none", "dr": "none", "x": ["wellhead", "cstair"]},
	"badgirli_ev": {"n": "Rüzgâr kuleli ev", "k": "col", "b": "d", "w": [7, 9], "d": [6, 8], "fl": [2, 2], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "small", "x": ["badgir", "cren", "viga"]},
	"kemerli_carsi": {"n": "Kemerli çarşı", "k": "col", "b": "gd", "w": [16, 20], "d": [6, 7], "fl": [1, 1], "rf": "flat", "rm": "conc", "f": "stone", "p": "tas", "wk": "shop", "ws": 3.4, "x": ["arcade", "stalls", "signs"]},
	"kule_ev": {"n": "Kule ev (kale ev)", "k": "col", "b": "d", "w": [7, 8], "d": [7, 8], "fl": [3, 3], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "slit", "x": ["cren", "viga", "machic"]},
	"col_karakolu": {"n": "Çöl karakolu (kale)", "k": "col", "b": "d", "w": [20, 24], "d": [20, 24], "fl": [1, 1], "fh": 4.2, "fp": "court", "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "slit", "dr": "arc", "sym": true, "x": ["corners", "cren", "flag"]},
	"damli_ev": {"n": "Teraslı ev (dam)", "k": "col", "b": "d", "w": [7, 9], "d": [6, 7], "fl": [2, 2], "rf": "flat", "rm": "conc", "f": "plaster", "p": "beyaz", "x": ["roofshade", "extstair", "tank", "laundry"]},
	"kerpic_dukkan": {"n": "Kerpiç dükkânlar", "k": "col", "b": "d", "w": [12, 16], "d": [5, 6], "fl": [1, 1], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "shop", "ws": 3.6, "x": ["clothawn", "sacks", "viga", "stalls"]},
	"hurma_ambari": {"n": "Hurma ambarı", "k": "col", "b": "d", "w": [8, 10], "d": [6, 7], "fl": [1, 1], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "slit", "x": ["ventholes", "viga", "sacks"]},
	"kubik_ev": {"n": "Beyaz kübik ev", "k": "col", "b": "gd", "w": [6, 8], "d": [6, 7], "fl": [1, 2], "rf": "flat", "rm": "conc", "f": "plaster", "p": "beyaz", "x": ["blueshut", "extstair", "perg"]},
	"col_hani": {"n": "Çöl kervansarayı", "k": "col", "b": "d", "w": [20, 24], "d": [20, 24], "fl": [1, 1], "fh": 4.4, "fp": "court", "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "small", "dr": "arc", "sym": true, "x": ["cren_low", "gatehouse"]},
	"kuyu_bekci": {"n": "Su kuyusu bekçi evi", "k": "col", "b": "d", "w": [4.5, 5.5], "d": [4, 4.5], "fl": [1, 1], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "small", "x": ["well", "jars"]},
	# ---------------------------------------------------------------- kış
	"sale": {"n": "Dağ evi (şale)", "k": "kis", "b": "w", "w": [8, 10], "d": [7, 8], "fl": [2, 2], "rf": "gable", "pit": 0.9, "gf": true, "rm": "wood", "f": "timber", "p": "ahsap", "pl": "stone", "x": ["bal_wood_wrap", "chim_stone", "logpile", "wide_eave"]},
	"kutuk_ev": {"n": "Kütük ev", "k": "kis", "b": "gw", "w": [6, 8], "d": [5, 6], "fl": [1, 1], "rf": "gable", "pit": 1.0, "rm": "wood", "f": "log", "p": "ahsap", "wk": "small", "x": ["chim_stone", "porch", "logpile", "logends"]},
	"kis_ahiri": {"n": "Karlı ahır", "k": "kis", "b": "w", "w": [12, 14], "d": [8, 10], "fl": [1, 1], "fh": 3.8, "rf": "gable", "pit": 1.1, "gf": true, "rm": "wood", "f": "timber", "p": "ahsap", "pl": "stone", "wk": "small", "dr": "wide", "sym": true, "x": ["loft", "cupola"]},
	"kis_koy_evi": {"n": "Karlı köy evi", "k": "kis", "b": "w", "w": [7, 9], "d": [6, 7], "fl": [2, 2], "rf": "gable", "pit": 1.0, "rm": "metal", "f": "plaster", "p": "krem", "pl": "stone", "x": ["chim", "shut", "porch", "logpile"]},
	"dag_oteli": {"n": "Dağ oteli", "k": "kis", "b": "w", "w": [15, 18], "d": [10, 12], "fl": [3, 3], "rf": "hip", "pit": 0.9, "rm": "slate", "f": "plaster", "p": "beyaz", "pl": "stone", "sym": true, "x": ["dormer", "bal_wood", "sign", "flags", "tframe"], "sign": "OTEL"},
	"odunluk": {"n": "Odunluk", "k": "kis", "b": "gw", "w": [4.5, 6], "d": [3, 3.6], "fl": [1, 1], "fh": 2.4, "fp": "open", "rf": "shed", "rm": "wood", "f": "timber", "p": "ahsap", "x": ["logs_in"]},
	"dag_karakolu": {"n": "Dağ karakolu", "k": "kis", "b": "w", "w": [10, 12], "d": [8, 9], "fl": [2, 2], "rf": "gable", "pit": 0.9, "rm": "metal", "f": "stone", "p": "tas", "sym": true, "x": ["flag", "mast", "sandbag", "watchtower"], "ext": 5.0},
	"kis_bakkal": {"n": "Karlı köy bakkalı", "k": "kis", "b": "w", "w": [6, 7.5], "d": [6, 7], "fl": [2, 2], "rf": "gable", "pit": 0.9, "rm": "metal", "f": "timber", "p": "ahsap", "pl": "stone", "wk": "shop", "x": ["sign", "logpile", "porch"], "sign": "BAKKAL"},
	"kis_okulu": {"n": "Karlı köy okulu", "k": "kis", "b": "w", "w": [13, 16], "d": [7, 8], "fl": [1, 1], "fh": 3.4, "rf": "gable", "pit": 0.9, "rm": "metal", "f": "plaster", "p": "krem", "pl": "stone", "wk": "tall", "sym": true, "x": ["flag", "chim", "sign", "steps"], "sign": "İLKOKULU"},
	"sauna_hamam": {"n": "Köy hamamı (karlı)", "k": "kis", "b": "w", "w": [7, 8], "d": [6, 7], "fl": [1, 1], "rf": "gable", "pit": 0.8, "rm": "wood", "f": "log", "p": "ahsap", "wk": "small", "x": ["chim_stone", "logpile"]},
	"kis_ambari": {"n": "Taş tabanlı ambar", "k": "kis", "b": "w", "w": [6, 8], "d": [5, 6], "fl": [2, 2], "rf": "gable", "pit": 1.0, "rm": "metal", "f": "timber", "p": "kirmizi", "pl": "stone", "wk": "small", "x": ["loft", "trim_white"]},
	"kis_apartman": {"n": "Karlı kasaba apartmanı", "k": "kis", "b": "w", "w": [11, 13], "d": [9, 11], "fl": [3, 4], "rf": "hip", "pit": 0.7, "rm": "metal", "f": "plaster", "p": "pastel", "x": ["bal", "chim", "dish", "rollbox"]},
	# ---------------------------------------------------------------- ek kasaba/köy çeşitleri
	"cay_bahcesi": {"n": "Çay bahçesi köşkü", "k": "kasaba", "b": "gd", "w": [6, 7], "d": [5, 6], "fl": [1, 1], "rf": "hip", "rm": "tile", "f": "timber", "p": "ahsap", "wk": "shop", "x": ["tables", "perg", "sign"], "sign": "ÇAY BAHÇESİ"},
	"marangoz": {"n": "Marangoz", "k": "kasaba", "b": "gwd", "w": [7, 9], "d": [6, 7], "fl": [1, 1], "fh": 3.4, "rf": "gable", "rm": "metal", "f": "brick", "p": "tugla", "wk": "high", "dr": "wide", "x": ["planks", "sign", "stovepipe"], "sign": "MARANGOZ"},
	"nalbur": {"n": "Nalbur", "k": "kasaba", "b": "gwd", "w": [7, 9], "d": [7, 8], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "krem", "wk": "shop", "x": ["sign", "rollshut", "crates", "barrels"], "sign": "NALBUR"},
	"sebzeci": {"n": "Manav", "k": "kasaba", "b": "gwd", "w": [5, 6.5], "d": [5, 6], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "canli", "wk": "shop", "x": ["produce", "awn", "sign"], "sign": "MANAV"},
	"kahve_2kat": {"n": "Kıraathane (iki katlı)", "k": "kasaba", "b": "gwd", "w": [8, 10], "d": [7, 8], "fl": [2, 2], "rf": "hip", "rm": "clay", "f": "plaster", "p": "krem", "wk": "shop", "x": ["awn", "tables", "sign", "bal", "cumba"], "sign": "KIRAATHANE"},
	"koy_konutu_tek": {"n": "Tek katlı sıvalı ev", "k": "koy", "b": "gwd", "w": [6, 8], "d": [5, 6], "fl": [1, 1], "rf": "gable", "rm": "tile", "f": "plaster", "p": "pastel", "x": ["chim", "shut", "porch_small", "gutter"]},
	"kerpic_koy_evi": {"n": "Kerpiç köy evi (düz damlı)", "k": "koy", "b": "gd", "w": [7, 9], "d": [5, 6], "fl": [1, 1], "rf": "flat", "rm": "mud", "f": "adobe", "p": "kerpic", "wk": "small", "x": ["viga", "earthroof", "stovepipe", "logpile"]},
	"cifte_sundurma": {"n": "Sundurmalı ev", "k": "koy", "b": "gwd", "w": [8, 10], "d": [6, 7], "fl": [1, 1], "rf": "hip", "rm": "clay", "f": "stone", "p": "tas", "x": ["porch_full", "chim", "shut"]},
	"karakol_kulesi": {"n": "Gözetleme kulesi", "k": "koy", "b": "gwd", "w": [4, 4.5], "d": [4, 4.5], "fl": [4, 4], "rf": "hip", "rm": "metal", "f": "stone", "p": "tas", "wk": "slit", "x": ["sandbag_top", "flag"]},
	"motel": {"n": "Yol kenarı motel", "k": "kasaba", "b": "gwd", "w": [18, 22], "d": [7, 8], "fl": [1, 1], "rf": "flat", "f": "plaster", "p": "canli", "ws": 3.0, "x": ["roofsign", "gallery", "ac"], "sign": "MOTEL"},
	"lojman_blok": {"n": "Lojman bloğu", "k": "sehir", "b": "gwd", "w": [14, 16], "d": [10, 11], "fl": [3, 3], "rf": "gable", "pit": 0.45, "rm": "metal", "f": "plaster", "p": "krem", "x": ["bal", "dish", "chim", "bands"]},
	"kultur_merkezi": {"n": "Kültür merkezi", "k": "sehir", "b": "gwd", "w": [16, 20], "d": [12, 14], "fl": [2, 2], "rf": "flat", "f": "conc", "p": "beyaz", "wk": "band", "sym": true, "x": ["canopy", "bigsign", "flags", "steps"], "sign": "KÜLTÜR MERKEZİ"},
	"oto_galeri": {"n": "Oto galeri", "k": "kasaba", "b": "gwd", "w": [12, 14], "d": [9, 10], "fl": [1, 1], "fh": 4.0, "rf": "flat", "f": "panel", "p": "beyaz", "wk": "shop", "ws": 3.4, "x": ["bigsign", "flags", "cars"], "sign": "OTO GALERİ"},
	"kuruyemis": {"n": "Kuruyemişçi", "k": "kasaba", "b": "gwd", "w": [4.5, 5.5], "d": [5, 6], "fl": [2, 2], "rf": "flat", "f": "plaster", "p": "canli", "wk": "shop", "x": ["sign", "awn", "sacks", "ac"], "sign": "KURUYEMİŞ"},
}

static func count() -> int:
	return ARCH.size()

static func name_of(id: String) -> String:
	return String(ARCH.get(id, {}).get("n", id))

# biyom ve kategoriye uygun kimlikler
static func ids_where(biome: String, cats: Array) -> Array:
	var bk := {"green": "g", "winter": "w", "desert": "d"}.get(biome, "g")
	var out: Array = []
	for id in ARCH:
		var a: Dictionary = ARCH[id]
		if String(a["b"]).contains(bk) and (cats.is_empty() or cats.has(a["k"])):
			out.append(id)
	return out

# taban boyutu (w: cephe, d: derinlik) ve yerleşim yarıçapı
static func pick_size(id: String, r: RandomNumberGenerator) -> Vector2:
	var a: Dictionary = ARCH[id]
	return Vector2(snappedf(r.randf_range(a["w"][0], a["w"][1]), 0.25), snappedf(r.randf_range(a["d"][0], a["d"][1]), 0.25))

static func radius(id: String, sz: Vector2) -> float:
	var a: Dictionary = ARCH.get(id, {})
	return Vector2(sz.x, sz.y).length() * 0.5 + float(a.get("ext", 0.0)) * 0.6 + 0.4

# ============================================================ kurucu
var mg: MapGen
var B: Blocks
var rng: RandomNumberGenerator
var A: Dictionary = {}
var aid := ""                 # kurulan arketip kimliği (ev kaydına yazılır: hata ayıklama / testler)
var X := {}
var c0 := Vector3.ZERO
var rb := Basis()
var ang := 0.0
var odd := false
var W := 8.0
var D := 6.0
var fl := 1
var bh := 0.42
var rpf := 7
var blen := 0.5
var t2 := 0.42
var fac := "plaster"
var wcol := Color.WHITE      # alfa kodlu blok rengi
var wrgb := Color.WHITE      # süs için (alfasız)
var trim := Color.WHITE      # söve, korniş, denizlik
var acc := Color.WHITE       # kapı / kepenk / pancur
var frame_c := Color.WHITE   # pencere doğraması
var rcol := Color.WHITE
var rtex := "clay"
var snow := false
var wings: Array = []
var me: MB                   # dış süs (gizlenmez)
var meg: MB                  # dış cam
var mem: Dictionary = {}     # dış çatı malzemeli parçalar
var sign_txt := ""

func _init(m: MapGen) -> void:
	mg = m
	B = m.B
	rng = m.rng

func _w(lp: Vector3) -> Vector3:
	return c0 + rb * lp

func _rgb(c: Color) -> Color:
	return Color(c.r, c.g, c.b)

func _rr(a: Array) -> float:
	return rng.randf_range(float(a[0]), float(a[1]))

func _pick(arr: Array):
	return arr[rng.randi() % arr.size()]

func build(c: Vector3, id: String, rot: int, w: float, d: float, dmg := false) -> void:
	if not ARCH.has(id):
		id = "tas_ev"
	aid = id
	A = ARCH[id]
	X.clear()
	for k in A.get("x", []):
		X[k] = true
	c0 = Vector3(c.x, 0, c.z)
	ang = posmod(rot, 4) * PI * 0.5
	odd = posmod(rot, 2) == 1
	rb = Basis(Vector3.UP, ang)
	snow = mg.kind == "winter"
	if w <= 0.0 or d <= 0.0:
		var sz := pick_size(id, rng)
		w = sz.x
		d = sz.y
	W = w
	D = d
	fl = rng.randi_range(int(A["fl"][0]), int(A["fl"][1]))
	fac = String(A.get("f", "plaster"))
	var pal: Array = PAL[String(A.get("p", "krem"))]
	var base: Color = _pick(pal)
	base = base.darkened(rng.randf_range(0.0, 0.06))
	wrgb = base
	wcol = Color(base.r, base.g, base.b, FAC_A.get(fac, 0.3))
	match fac:
		"plaster", "panel", "conc":
			trim = Color(0.95, 0.94, 0.9) if base.get_luminance() < 0.8 else base.darkened(0.16)
		"stone":
			trim = base.lightened(0.12)
		"brick":
			trim = _pick([Color(0.88, 0.84, 0.74), Color(0.92, 0.9, 0.86), Color(0.7, 0.68, 0.64)])
		"timber", "log":
			trim = Color(0.94, 0.92, 0.86) if X.has("trim_white") else base.darkened(0.3)
		"adobe":
			trim = base.darkened(0.12)
		_:
			trim = base.lightened(0.1)
	acc = _pick([Color(0.32, 0.22, 0.14), Color(0.2, 0.32, 0.42), Color(0.24, 0.36, 0.24), Color(0.5, 0.18, 0.14), Color(0.42, 0.42, 0.44), Color(0.55, 0.42, 0.26)])
	if X.has("blueshut"):
		acc = Color(0.12, 0.34, 0.62)
	if fac in ["plaster", "panel", "conc", "brick"] and fl >= 2:
		frame_c = Color(0.96, 0.96, 0.95)
	elif fac in ["stone", "timber", "log", "adobe"] or rng.randf() < 0.4:
		frame_c = Color(0.36, 0.26, 0.18)
	else:
		frame_c = Color(0.94, 0.94, 0.92)
	rtex = String(A.get("rm", "clay"))
	var rc: Array = ROOF_COL.get(rtex, ROOF_COL["clay"])
	rcol = _pick(rc)
	sign_txt = String(A.get("sign", ""))
	me = MB.new()
	meg = MB.new()
	mem = {}
	wings = _footprint(String(A.get("fp", "rect")))
	# blok yüksekliği: 6.7 m üstü kanat varsa iri blok (blok sayısı makul kalsın)
	var hmax := 0.0
	for wg in wings:
		if not wg.has("ring"):
			hmax = maxf(hmax, float(wg["hm"]))
	bh = 0.42 if hmax <= 6.7 else 0.6
	rpf = 7 if bh < 0.5 else 5
	blen = 0.6 if bh < 0.5 else 0.9
	t2 = 0.42 if bh < 0.5 else 0.5
	for wg in wings:
		_wing_rows(wg)
	_shared()
	for wg in wings:
		if wg.has("ring"):
			_ring_wing(wg)
		else:
			_wing(wg)
	_extras()
	_commit_ext()
	if dmg:
		var m: Dictionary = wings[0]
		if not m.has("ring"):
			var r: Rect2 = m["r"]
			var hp := _roof_h(m, r.get_center().x, r.get_center().y)
			mg.P.roof_damage(_w(Vector3(r.get_center().x, 0, r.get_center().y)), r.size.x if not odd else r.size.y, r.size.y if not odd else r.size.x, (hp + float(m["top"])) * 0.5 - 0.6, 0.0)

# ------------------------------------------------------------ taban şekilleri
func _wg(r: Rect2, extra := {}) -> Dictionary:
	var fh: float = float(A.get("fh", 0.0))
	var g := {"r": r, "fl": fl, "fh": fh if fl == 1 else 0.0, "rf": String(A.get("rf", "gable")), "col": wcol, "rgb": wrgb, "main": false}
	g.merge(extra, true)
	g["hm"] = float(g["fh"]) if float(g["fh"]) > 0.0 else int(g["fl"]) * 3.0
	return g

func _ringwg(cx: float, cz: float, rad: float, n: int, hm: float, rf: String, col: Color, rbh: float, extra := {}) -> Dictionary:
	var g := {"r": Rect2(cx - rad, cz - rad, rad * 2.0, rad * 2.0), "ring": n, "rad": rad, "cx": cx, "cz": cz, "hm": hm, "rf": rf, "col": col, "rgb": _rgb(col), "bhr": rbh, "fl": 1, "main": false}
	g.merge(extra, true)
	return g

func _footprint(fp: String) -> Array:
	var out: Array = []
	var hw := W * 0.5
	var hd := D * 0.5
	match fp:
		"L":
			var da := clampf(D * 0.5, 5.0, 8.0)
			var wb := clampf(W * 0.42, 4.5, 8.0)
			out.append(_wg(Rect2(-hw, hd - da, W, da), {"main": true}))
			var bx := -hw if rng.randf() < 0.5 else hw - wb
			if X.has("garage_wing"):
				out.append(_wg(Rect2(bx, -hd, wb, D - da), {"fl": 1, "fh": 2.7, "garage": true, "rf": "flat" if A["rf"] == "flat" else "shed"}))
			else:
				out.append(_wg(Rect2(bx, -hd, wb, D - da)))
		"U":
			var db := clampf(D * 0.42, 5.0, 8.0)
			var ws := clampf(W * 0.3, 4.5, 7.0)
			out.append(_wg(Rect2(-hw, -hd, W, db), {"main": true}))
			out.append(_wg(Rect2(-hw, -hd + db, ws, D - db)))
			out.append(_wg(Rect2(hw - ws, -hd + db, ws, D - db)))
		"court":
			var db := clampf(D * 0.24, 4.5, 6.5)
			var ws := clampf(W * 0.22, 4.0, 6.0)
			out.append(_wg(Rect2(-hw, hd - db, W, db), {"main": true, "gate": true}))
			out.append(_wg(Rect2(-hw, -hd, W, db)))
			out.append(_wg(Rect2(-hw, -hd + db, ws, D - 2.0 * db)))
			out.append(_wg(Rect2(hw - ws, -hd + db, ws, D - 2.0 * db)))
		"row":
			var n := maxi(2, int(round(W / 5.6)))
			var uw := W / n
			var pal: Array = PAL[String(A.get("p", "krem"))]
			var k0 := rng.randi()
			for i in n:
				var cl: Color = pal[(k0 + i) % pal.size()]
				cl = cl.darkened(rng.randf_range(0.0, 0.08))
				out.append(_wg(Rect2(-hw + i * uw, -hd, uw, D), {"main": i == 0, "party": true, "col": Color(cl.r, cl.g, cl.b, wcol.a), "rgb": cl}))
		"grid":
			var nx := maxi(1, int(round(W / 3.6)))
			var nz := maxi(1, int(round(D / 3.6)))
			var cw := W / nx
			var cd := D / nz
			for iz in nz:
				for ix in nx:
					out.append(_wg(Rect2(-hw + ix * cw, -hd + iz * cd, cw, cd), {"main": ix == 0 and iz == nz - 1, "cell": true}))
		"oct":
			var g := _ringwg(0.0, 0.0, W * 0.5, 8, float(A.get("fh", 6.0)), String(A.get("rf", "cone")), wcol, 0.6, {"main": true, "fl": 1})
			out.append(g)
		"open":
			out.append(_wg(Rect2(-hw, -hd, W, D), {"main": true, "open": true}))
		_:
			if X.has("garage_side"):
				var gw := 3.6
				out.append(_wg(Rect2(-hw, -hd, W - gw, D), {"main": true}))
				out.append(_wg(Rect2(hw - gw, hd - 6.0, gw, 6.0), {"fl": 1, "fh": 2.7, "garage": true, "rf": "flat"}))
			else:
				out.append(_wg(Rect2(-hw, -hd, W, D), {"main": true}))
	# kuleler: yapıya bitişik kanat (kapısı içeri açılır). Oyunda dini yapı ve ona benzeyen hiçbir şey yok:
	# çan kulesi, minare, kubbe, soğan kubbe, ince halkalı kule üretilmez (kullanıcı kararı, 15–16 Ekim).
	if X.has("hosetower"):
		out.append(_wg(Rect2(hw - 3.2, -hd - 3.2, 3.2, 3.2), {"fl": 1, "fh": 12.0, "rf": "flat", "tower": true}))
	# halka kanatlar (blok silindir): silo, tank, baca, köşe kulesi
	if X.has("silo1") or X.has("silo2") or X.has("silo4"):
		var n := 1 if X.has("silo1") else (2 if X.has("silo2") else 4)
		var sr := 2.2 if n < 4 else 2.6
		var sh := rng.randf_range(10.0, 14.0) if n < 4 else rng.randf_range(16.0, 20.0)
		var scol := Color(0.8, 0.82, 0.84, FAC_A["metal"]) if n < 4 else Color(0.76, 0.75, 0.72, FAC_A["conc"])
		for i in n:
			var sx := hw + sr + 1.0
			var sz2 := -hd + sr + i * (sr * 2.0 + 0.6)
			if n == 4:
				sx = hw + sr + 1.2 + (i % 2) * (sr * 2.0 + 0.2)
				sz2 = -hd + sr + (i / 2) * (sr * 2.0 + 0.2)
			out.append(_ringwg(sx, sz2, sr, 12, sh, "silo", scol, 1.0, {"silo": true}))
	if X.has("stack"):
		out.append(_ringwg(-hw - 3.4, -hd + 3.0, 2.3, 12, rng.randf_range(24.0, 32.0), "stack", Color(0.62, 0.32, 0.24, FAC_A["brick"]), 1.0))
	if X.has("ftanks"):
		for i in 3:
			var tr := rng.randf_range(3.4, 4.2)
			var tx := hw + 5.0 + (i % 2) * 9.5
			var tz := -hd - 3.0 + (i / 2) * 9.5 + (i % 2) * 2.0
			out.append(_ringwg(tx, tz, tr, 16, rng.randf_range(4.5, 6.5), "tank", Color(0.9, 0.9, 0.88, FAC_A["steel"]), 1.0))
	if X.has("corners"):
		for sx: float in [-1.0, 1.0]:
			for sz2: float in [-1.0, 1.0]:
				out.append(_ringwg(sx * hw, sz2 * hd, 2.2, 10, float(A.get("fh", 4.0)) + 2.2, "fortcap", wcol, 0.6))
	return out

func _wing_rows(wg: Dictionary) -> void:
	if wg.has("ring"):
		var rbh: float = float(wg.get("bhr", 0.6))
		wg["bh"] = rbh
		wg["rows"] = maxi(2, int(round(float(wg["hm"]) / rbh)))
		wg["rows0"] = wg["rows"]
		wg["top"] = int(wg["rows"]) * rbh
		return
	var rows: int
	if float(wg["fh"]) > 0.0:
		rows = maxi(2, int(round(float(wg["fh"]) / bh)))
		wg["rows0"] = rows
	else:
		rows = int(wg["fl"]) * rpf
		wg["rows0"] = rpf
	wg["rows"] = rows
	wg["top"] = rows * bh
	wg["bh"] = bh

# kanat kenarı: [a, b, dışa normal] (yerel); a→b yönünde dış sağda
func _side(wg: Dictionary, k: int) -> Array:
	var r: Rect2 = wg["r"]
	var h := t2 * 0.5
	var x0 := r.position.x
	var x1 := r.end.x
	var z0 := r.position.y
	var z1 := r.end.y
	match k:
		0:
			return [Vector3(x0 - h, 0, z1), Vector3(x1 + h, 0, z1), Vector3(0, 0, 1)]
		1:
			return [Vector3(x1 + h, 0, z0), Vector3(x0 - h, 0, z0), Vector3(0, 0, -1)]
		2:
			return [Vector3(x0, 0, z0 + h), Vector3(x0, 0, z1 - h), Vector3(-1, 0, 0)]
	return [Vector3(x1, 0, z1 - h), Vector3(x1, 0, z0 + h), Vector3(1, 0, 0)]

# kenar çizgisi: [eksen değeri, aralık başı, sonu]
func _sline(wg: Dictionary, k: int) -> Array:
	var r: Rect2 = wg["r"]
	match k:
		0:
			return [r.end.y, r.position.x, r.end.x]
		1:
			return [r.position.y, r.position.x, r.end.x]
		2:
			return [r.position.x, r.position.y, r.end.y]
	return [r.end.x, r.position.y, r.end.y]

# kenar boyunca konum (yerel eksen değeri → a'dan metre)
func _s_of(wg: Dictionary, k: int, v: float) -> float:
	var r: Rect2 = wg["r"]
	var h := t2 * 0.5
	match k:
		0:
			return v - (r.position.x - h)
		1:
			return (r.end.x + h) - v
		2:
			return v - (r.position.y + h)
	return (r.end.y - h) - v

const OPP := [1, 0, 3, 2]

# bitişik kanatlar: ortak duvar bir kez kurulur, araya iç kapı açılır (sıra evlerde sağır)
func _shared() -> void:
	for wg in wings:
		wg["skip"] = [false, false, false, false]
		wg["cover"] = [[], [], [], []]
		wg["inner"] = [[], [], [], []]
	for j in wings.size():
		var wj: Dictionary = wings[j]
		if wj.has("ring"):
			continue
		for i in j:
			var wi: Dictionary = wings[i]
			if wi.has("ring"):
				continue
			for k in 4:
				var o: int = OPP[k]
				var lj := _sline(wj, k)
				var li := _sline(wi, o)
				if absf(float(lj[0]) - float(li[0])) > 0.05:
					continue
				var a0 := maxf(lj[1], li[1])
				var a1 := minf(lj[2], li[2])
				if a1 - a0 < 0.5:
					continue
				var party: bool = wj.get("party", false) and wi.get("party", false)
				var mid := (a0 + a1) * 0.5
				if lj[1] >= li[1] - 0.3 and lj[2] <= li[2] + 0.3:
					wj["skip"][k] = true
					wi["cover"][o].append([_s_of(wi, o, a0), _s_of(wi, o, a1)])
					if not party:
						wi["inner"][o].append(_s_of(wi, o, mid))
				else:
					wi["skip"][o] = true
					wj["cover"][k].append([_s_of(wj, k, a0), _s_of(wj, k, a1)])
					if not party:
						wj["inner"][k].append(_s_of(wj, k, mid))

# ------------------------------------------------------------ kanat: duvar, boşluk, slot
const WK_W := {"std": 1.1, "small": 0.75, "slit": 0.42, "tall": 1.1, "shop": 1.1, "band": 1.6, "high": 1.8, "arch": 1.0, "none": 0.0}
const WK_S := {"std": 2.6, "small": 2.4, "slit": 1.8, "tall": 2.3, "shop": 2.8, "band": 2.1, "high": 3.0, "arch": 2.8, "none": 3.0}

func _side_free(wg: Dictionary, k: int) -> float:
	var sd := _side(wg, k)
	var L: float = (sd[0] as Vector3).distance_to(sd[1])
	for cv in wg["cover"][k]:
		L -= absf(float(cv[1]) - float(cv[0]))
	return L

func _pick_dside(wg: Dictionary) -> int:
	for k: int in [0, 3, 2, 1]:
		if not wg["skip"][k] and _side_free(wg, k) >= 2.6:
			return k
	return -1

func _wing(wg: Dictionary) -> void:
	var r: Rect2 = wg["r"]
	var lc := Vector3(r.get_center().x, 0, r.get_center().y)
	var wc := _w(lc)
	var wsz := Vector2(r.size.y, r.size.x) if odd else r.size
	var roof := MeshInstance3D.new()
	var deco := MeshInstance3D.new()
	var hid := B.new_house(wc, wsz, float(wg["top"]), roof)
	B.houses[hid]["deco"] = deco
	B.houses[hid]["aid"] = aid
	wg["hid"] = hid
	wg["lc"] = lc
	wg["wc"] = wc
	wg["mr"] = {}
	wg["mx"] = MB.new()
	wg["mxg"] = MB.new()
	wg["md"] = MB.new()
	wg["mdg"] = MB.new()
	wg["dside"] = _pick_dside(wg)
	if wg.get("gate", false):
		wg["dside2"] = 1
	if wg.get("open", false):
		_open_wing(wg)
	else:
		for k in 4:
			if not wg["skip"][k]:
				_wall_side(wg, k)
		mg._floor(wc, wsz.x, wsz.y)
	_roof(wg)
	_commit_wing(wg, roof, deco)

func _commit_wing(wg: Dictionary, roof: MeshInstance3D, deco: MeshInstance3D) -> void:
	var m: ArrayMesh = null
	var mr: Dictionary = wg["mr"]
	for key in mr:
		m = (mr[key] as MB).commit(Mats.roof2(key, snow) if key != "glass" else Mats.glass(), m)
	m = (wg["mx"] as MB).commit(Mats.vcs(), m)
	m = (wg["mxg"] as MB).commit(Mats.glass(), m)
	roof.mesh = m
	roof.position = c0
	roof.rotation.y = ang
	B.add_child(roof)
	var dm: ArrayMesh = (wg["md"] as MB).commit(Mats.vcs())
	dm = (wg["mdg"] as MB).commit(Mats.glass(), dm)
	deco.mesh = dm
	deco.position = c0
	deco.rotation.y = ang
	B.add_child(deco)

func _mr(wg: Dictionary, key: String) -> MB:
	var mr: Dictionary = wg["mr"]
	if not mr.has(key):
		mr[key] = MB.new()
	return mr[key]

# boşluk sıraları [r0, r1] (zemin pencereleri oyun kuralı: üst sıra lento hizasında kalsın)
func _orows(kd: String, f: int, wg: Dictionary) -> Array:
	var rows: int = wg["rows"]
	var r0f: int = wg["rows0"]
	var fr := f * rpf
	var lo := bh < 0.5
	match kd:
		"door", "half":
			return [0, 4 if lo else 3]
		"gar":
			return [0, mini(5 if lo else 4, r0f - 2)]
		"roll", "arc", "fire", "dock":
			return [0, maxi(4 if lo else 3, mini(r0f - 2, 8 if lo else 6))]
		"bal":
			return [fr, fr + (4 if lo else 3)]
		"high":
			return [rows - (4 if lo else 3), rows - (3 if lo else 2)]
		"bell":
			return [rows - (6 if lo else 4), rows - 2]
		"hwin":
			return [5 if lo else 4, maxi(5 if lo else 4, r0f - (3 if lo else 2))]
	if f == 0:
		return [2, 3] if lo else [1, 2]
	if kd == "small" or kd == "slit":
		return [fr + 2, fr + 3]
	if kd == "tall":
		return [fr + 1, fr + 4] if lo else [fr + 1, fr + 3]
	return [fr + 2, fr + 4] if lo else [fr + 2, fr + 3]

func _openings(wg: Dictionary, k: int, L: float) -> Array:
	var ops: Array = []
	var blocked: Array = []
	for cv in wg["cover"][k]:
		blocked.append([minf(cv[0], cv[1]), maxf(cv[0], cv[1])])
	for s in wg["inner"][k]:
		ops.append({"s": s, "w": 1.3, "k": "door", "f": 0, "inner": true})
	var wk: String = String(A.get("wk", "std"))
	if wg.get("garage", false):
		wk = "none"
	if wg.get("tower", false):
		wk = "slit"
	if wg.get("cell", false):
		wk = "small"
	var ws: float = float(A.get("ws", WK_S[wk]))
	var n := maxi(1, int((L - 0.6) / ws))
	var step := L / n
	var pos: Array = []
	for i in n:
		var s := (i + 0.5) * step
		var ok := s > 0.9 and s < L - 0.9
		for bl in blocked:
			if s > bl[0] - 0.9 and s < bl[1] + 0.9:
				ok = false
		for o in ops:
			if absf(s - float(o["s"])) < 1.6:
				ok = false
		if ok:
			pos.append(s)
	var front := k == 0
	var nfl: int = int(wg["fl"])
	var tall_hall: bool = int(wg["rows0"]) >= (9 if bh < 0.5 else 7)
	# kapı(lar)
	var dr: String = String(A.get("dr", "std"))
	if wg.get("garage", false):
		dr = "gar"
	elif wg.get("tower", false) or wg.get("cell", false) or not wg.get("main", false):
		dr = "std" if dr != "none" else "none"
	if wg.get("gate", false):
		dr = "arc"
	var is_door_side: bool = k == int(wg.get("dside", -1)) or k == int(wg.get("dside2", -1))
	var used := {}
	if is_door_side and dr != "none" and not pos.is_empty():
		var multi := {"roll2": 2, "gar2": 2, "fire": 3, "dock3": 3, "garrow": maxi(2, int(L / 3.0))}
		if multi.has(dr):
			var nd: int = multi[dr]
			var kd: String = {"roll2": "roll", "gar2": "gar", "fire": "fire", "dock3": "dock", "garrow": "gar"}[dr]
			var dw: float = {"roll": 3.6, "gar": 2.5, "fire": 3.2, "dock": 2.8}[kd]
			var sp := L / nd
			dw = minf(dw, sp - 0.7)
			for i in nd:
				ops.append({"s": (i + 0.5) * sp, "w": dw, "k": kd, "f": 0})
			pos = []
		else:
			var di := rng.randi() % pos.size()
			if A.get("sym", false) or wg.get("tower", false) or wg.get("gate", false):
				var best := 1e9
				for i in pos.size():
					if absf(float(pos[i]) - L * 0.5) < best:
						best = absf(float(pos[i]) - L * 0.5)
						di = i
			var kd: String = {"std": "door", "dbl": "door", "wide": "roll", "roll": "roll", "gar": "gar", "arc": "arc"}.get(dr, "door")
			var dw: float = {"std": 1.4, "dbl": 2.0, "wide": 3.0, "roll": 3.6, "gar": 2.6, "arc": 2.4}.get(dr, 1.4)
			if X.has("halfdoors") and front:
				kd = "half"
				dw = 1.2
			var s0: float = pos[di]
			if A.get("sym", false) and absf(s0 - L * 0.5) < step * 0.5 + 0.1:
				s0 = L * 0.5
			dw = minf(dw, step - 0.6) if pos.size() > 1 else minf(dw, L - 1.2)
			ops.append({"s": s0, "w": dw, "k": kd, "f": 0, "main": true})
			used[di] = true
			if X.has("halfdoors") and front:
				for i in pos.size():
					if not used.has(i):
						ops.append({"s": pos[i], "w": 1.2, "k": "half", "f": 0})
						used[i] = true
	# pencereler / vitrin / balkon
	var upk := {"shop": "std", "high": "none", "none": "none"}.get(wk, wk)
	var balk: bool = (X.has("bal") or X.has("bal_small") or X.has("bal_wood")) and (k == 0 or k == 1)
	var balall: bool = (X.has("balband") or X.has("loggia")) and (k == 0 or k == 1)
	if X.has("bal_wood_wrap"):
		balall = true
	for i in pos.size():
		var s: float = pos[i]
		for f in nfl:
			if f == 0:
				if used.has(i):
					continue
				var gk := wk
				if wk == "shop":
					gk = "shop" if (front or (k == 3 and X.has("shop2"))) and wg.get("main", false) else "std"
				elif wk == "band":
					gk = "std"
				if gk == "none" or gk == "high":
					continue
				var gw: float = WK_W[gk]
				if gk == "shop":
					gw = minf(step - 0.7, 2.6)
				ops.append({"s": s, "w": gw, "k": gk, "f": 0})
				if tall_hall and gk in ["std", "tall", "arch", "small"]:
					ops.append({"s": s, "w": gw, "k": "hwin", "f": 0, "up": true})
			else:
				if upk == "none":
					continue
				var bal := balall or (balk and i % 2 == 0)
				var uw: float = WK_W[upk] if upk != "band" else minf(step - 0.5, 2.0)
				ops.append({"s": s, "w": uw if not bal else 1.0, "k": "bal" if bal else upk, "f": f})
	# yüksek bant pencere (salon, depo)
	if (wk == "high" or X.has("clerestory")) and nfl == 1 and int(wg["rows"]) >= 7:
		var nh := maxi(1, int((L - 1.0) / 3.0))
		for i in nh:
			var s := (i + 0.5) * L / nh
			var ok := true
			for bl in blocked:
				if s > bl[0] - 1.2 and s < bl[1] + 1.2:
					ok = false
			if ok:
				ops.append({"s": s, "w": minf(2.2, L / nh - 0.6), "k": "high", "f": 1})
	# çan / kule penceresi
	if wg.get("bell", false):
		ops.append({"s": L * 0.5, "w": minf(1.2, L - 1.2), "k": "bell", "f": 1})
	for o in ops:
		var rr := _orows(String(o["k"]), int(o["f"]), wg)
		o["r0"] = rr[0]
		o["r1"] = rr[1]
	return ops

func _wall_side(wg: Dictionary, k: int) -> void:
	var sd := _side(wg, k)
	var la: Vector3 = sd[0]
	var lb: Vector3 = sd[1]
	var out: Vector3 = sd[2]
	var L := la.distance_to(lb)
	var ops := _openings(wg, k, L)
	var gaps: Array = []
	var g0: Array = []
	for o in ops:
		var g := [float(o["s"]) - float(o["w"]) * 0.5, float(o["s"]) + float(o["w"]) * 0.5, int(o["r0"]), int(o["r1"]), false, false]
		gaps.append(g)
		if int(o["f"]) == 0 and not o.get("inner", false) and not o.get("up", false):
			g0.append(g)
	var a := _w(la)
	var b := _w(lb)
	var wcl: Color = wg["col"]
	var wi := B.wall_line(a, b, int(wg["rows"]), wcl, Grid.K_HOUSE, {"len": blen, "h": bh, "t": t2, "gaps": gaps, "house": wg["hid"], "jit": FAC_JIT.get(fac, 0.02), "type": FAC_T.get(fac, Blocks.T_CONCRETE)})
	_paint(wi, wg, a, b, L)
	if not g0.is_empty():
		mg._house_slots(int(wg["hid"]), a, b, g0, wg["wc"])
	var dir := (lb - la) / L
	for o in ops:
		_d_open(wg, la, dir, out, o)
	_d_wall(wg, k, la, lb, out, L, ops)

# blok boyama: taş kaide, köşe taşları, tuğla şeritleri, sıva yaması, ahşap köşe tahtası
func _paint(wi: int, wg: Dictionary, a: Vector3, b: Vector3, L: float) -> void:
	var ids: Array = B.walls[wi]["blocks"]
	var dir := Vector2(b.x - a.x, b.z - a.z).normalized()
	var pl := String(A.get("pl", ""))
	var prow := 0
	if pl != "":
		prow = int(wg["rows0"]) if int(wg["fl"]) >= 2 else (2 if bh < 0.5 else 1)
	var pcol := Color(0.66, 0.64, 0.6, FAC_A["stone"])
	var quoin := fac in ["stone", "brick"] or (fac == "plaster" and (int(wg["hid"]) % 3) == 0)
	var qcol := Color(trim.r, trim.g, trim.b, FAC_A["stone"] if fac != "brick" else FAC_A["plaster"])
	var board := (fac == "timber" or fac == "metal") and X.has("trim_white")
	var patch := X.has("patch")
	var pc := Color(0.86, 0.84, 0.78, FAC_A["plaster"])
	var px := rng.randf_range(0.2, 0.7) * L
	var pw := rng.randf_range(1.0, 2.4)
	for id in ids:
		var p: Vector3 = B.bpos[id]
		var s := Vector2(p.x - a.x, p.z - a.z).dot(dir)
		var row: int = B.brow[id]
		var edge := s < 0.62 or s > L - 0.62
		if row < prow:
			B.set_col(id, MB.jit(pcol, rng, 0.1))
		elif quoin and edge and row % 2 == 0:
			B.set_col(id, MB.jit(qcol, rng, 0.03))
		elif board and edge:
			B.set_col(id, Color(0.92, 0.9, 0.86, FAC_A["plaster"]))
		elif patch and absf(s - px) < pw and row > 1 and row < 5:
			B.set_col(id, MB.jit(pc, rng, 0.04))
		elif fac == "brick" and bh < 0.5 and row > 0 and row % rpf == 0:
			B.set_col(id, (wg["col"] as Color).darkened(0.18))
		elif fac in ["timber", "log"]:
			# tahta: sıra boyunca aynı ton (yatay kaplama okunur)
			B.set_col(id, _rowc(wg["col"], row, 0.14))
		elif fac in ["metal", "panel", "plaster", "conc", "steel"]:
			B.set_col(id, _rowc(wg["col"], row, 0.025))

func _rowc(c: Color, row: int, amt: float) -> Color:
	var h := fposmod(sin(row * 12.9898 + c.r * 78.233) * 43758.5453, 1.0)
	return Color(c.r * (1.0 - h * amt), c.g * (1.0 - h * amt), c.b * (1.0 - h * amt), c.a)

# ------------------------------------------------------------ cephe süsü: boşluklar
const GLASS := [Color(0.16, 0.2, 0.25), Color(0.2, 0.25, 0.3), Color(0.14, 0.17, 0.2), Color(0.22, 0.27, 0.28)]
const AWN := [[Color(0.72, 0.12, 0.1), Color(0.95, 0.93, 0.88)], [Color(0.1, 0.42, 0.24), Color(0.95, 0.93, 0.88)], [Color(0.14, 0.3, 0.6), Color(0.95, 0.93, 0.88)],
	[Color(0.9, 0.62, 0.12), Color(0.95, 0.93, 0.88)], [Color(0.55, 0.28, 0.14), Color(0.86, 0.72, 0.5)], [Color(0.5, 0.1, 0.2), Color(0.9, 0.85, 0.8)]]

func _basis(dir: Vector3, out: Vector3) -> Basis:
	return Basis(dir, Vector3.UP, out)

# kiriş: p→q arası kutu (kesit sx, sy)
func _beam(mb: MB, p: Vector3, q: Vector3, sx: float, sy: float, col: Color) -> void:
	var d := q - p
	var L := d.length()
	if L < 0.01:
		return
	var x := d / L
	var up := Vector3.UP if absf(x.y) < 0.95 else Vector3.RIGHT
	var z := x.cross(up).normalized()
	var y := z.cross(x).normalized()
	mb.box((p + q) * 0.5, Vector3(L, sy, sx), col, Basis(x, y, z))

func _d_open(wg: Dictionary, la: Vector3, dir: Vector3, out: Vector3, o: Dictionary) -> void:
	if o.get("inner", false):
		return
	var kd := String(o["k"])
	var cw := float(o["w"])
	var y0: float = float(o.get("y0", int(o["r0"]) * bh))
	var y1: float = float(o.get("y1", (int(o["r1"]) + 1) * bh))
	var cp := la + dir * float(o["s"])
	var bas := _basis(dir, out)
	match kd:
		"door", "half":
			_d_door(wg, cp, dir, out, bas, cw, y1, kd == "half", o.get("main", false))
		"shop":
			_d_shop(wg, cp, dir, out, bas, cw, y0, y1)
		"gar", "roll", "fire", "dock":
			_d_roll(wg, cp, dir, out, bas, cw, y1, kd)
		"arc":
			_d_arc(wg, cp, dir, out, bas, cw, y1)
		"bell":
			_d_bell(wg, cp, dir, out, bas, cw, y0, y1)
		"high":
			_d_high(wg, cp, out, bas, cw, y0, y1)
		"bal":
			_d_window(wg, cp, dir, out, bas, cw, y0 + 0.05, y1, "bal", int(o["f"]))
			if not (X.has("balband") or X.has("loggia") or X.has("bal_wood_wrap")):
				_d_balcony(wg, cp, dir, out, bas, cw + 1.6, y0)
		_:
			_d_window(wg, cp, dir, out, bas, cw, y0, y1, kd, int(o["f"]))

func _d_window(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y0: float, y1: float, kd: String, f: int) -> void:
	var md: MB = wg["md"]
	var mgl: MB = wg["mdg"]
	var off := out * (t2 * 0.5)
	var up := Vector3.UP
	var ch := y1 - y0
	var cy := (y0 + y1) * 0.5
	var gcol: Color = _pick(GLASS)
	var fc := frame_c
	# zemin: görsel vasistas (lento sırası üstünde cam) → pencere boyu üst katlarla aynı okunur
	var vy1 := y1
	if f == 0 and bh < 0.5 and kd in ["std", "tall", "arch", "band"] and int(wg["rows0"]) >= 6:
		vy1 = y1 + bh
		mgl.box(cp + off + out * 0.012 + up * (y1 + bh * 0.5), Vector3(cw, bh - 0.04, 0.02), gcol.lightened(0.05), bas)
		md.box(cp + off + out * 0.03 + up * y1, Vector3(cw, 0.06, 0.05), fc, bas)
	if kd == "hwin":
		vy1 = y1
	mgl.box(cp - out * 0.05 + up * cy, Vector3(cw, ch, 0.04), gcol, bas)
	# perde
	if rng.randf() < 0.3 and kd != "slit":
		md.box(cp - out * 0.02 + dir * (cw * (0.3 if rng.randf() < 0.5 else -0.3)) + up * cy, Vector3(cw * 0.36, ch * 0.92, 0.01), _pick([Color(0.92, 0.88, 0.78), Color(0.86, 0.72, 0.62), Color(0.8, 0.84, 0.86)]), bas)
	# doğrama: kasa, orta kayıt, vasistas kaydı
	for sx: float in [-1.0, 1.0]:
		md.box(cp + dir * sx * (cw * 0.5 - 0.03) - out * 0.03 + up * cy, Vector3(0.06, ch, 0.08), fc, bas)
	md.box(cp - out * 0.03 + up * (y1 - 0.03), Vector3(cw, 0.06, 0.08), fc, bas)
	md.box(cp - out * 0.03 + up * (y0 + 0.03), Vector3(cw, 0.06, 0.08), fc, bas)
	if cw > 0.7 and kd != "slit":
		md.box(cp - out * 0.03 + up * cy, Vector3(0.05, ch, 0.07), fc, bas)
	if ch > 0.9 and kd != "slit":
		md.box(cp - out * 0.03 + up * (y0 + ch * 0.7), Vector3(cw, 0.05, 0.07), fc, bas)
	# denizlik
	md.box(cp + off + out * 0.06 + up * (y0 - 0.03), Vector3(cw + 0.2, 0.06, 0.2), trim if fac != "brick" else Color(0.82, 0.8, 0.74), bas)
	# söve / lento
	if fac in ["plaster", "stone", "panel", "conc"] and kd != "slit":
		md.box(cp + off + out * 0.02 + up * (vy1 + 0.07), Vector3(cw + 0.28, 0.14, 0.05), trim, bas)
		if fac == "plaster" and (int(wg["hid"]) % 2 == 0):
			for sx: float in [-1.0, 1.0]:
				md.box(cp + dir * sx * (cw * 0.5 + 0.07) + off + out * 0.015 + up * ((y0 + vy1) * 0.5), Vector3(0.12, vy1 - y0, 0.04), trim, bas)
	elif fac == "brick":
		md.box(cp + off + out * 0.015 + up * (vy1 + 0.1), Vector3(cw + 0.2, 0.2, 0.04), (wg["rgb"] as Color).darkened(0.25), bas)
	if kd == "arch":
		_arch_head(md, mgl, cp + off, dir, out, bas, cw, vy1, gcol)
	if kd == "bal":
		return
	# pancur / kepenk / ızgara / saksı / klima
	if (X.has("shut") or X.has("blueshut") or (kd == "small" and fac in ["stone", "plaster"] and int(wg["hid"]) % 2 == 1)) and kd != "slit" and kd != "hwin":
		for sx: float in [-1.0, 1.0]:
			var sp := cp + dir * sx * (cw * 0.75 + 0.03) + off + out * 0.03 + up * ((y0 + vy1) * 0.5)
			var sh := vy1 - y0
			md.box(sp, Vector3(cw * 0.5, sh, 0.04), acc, bas)
			for k in int(sh / 0.12):
				md.box(sp + out * 0.022 + up * (-sh * 0.5 + 0.08 + k * 0.12), Vector3(cw * 0.46, 0.025, 0.012), acc.darkened(0.22), bas)
	elif X.has("rollbox") and kd in ["std", "tall", "band"]:
		md.box(cp + off + out * 0.06 + up * (y1 + 0.12), Vector3(cw + 0.08, 0.24, 0.16), Color(0.9, 0.9, 0.88), bas)
		var fr := rng.randf_range(0.05, 0.75)
		var rh := ch * fr
		md.box(cp - out * 0.0 + up * (y1 - rh * 0.5), Vector3(cw - 0.04, rh, 0.03), Color(0.82, 0.82, 0.8), bas)
		for k in int(rh / 0.09):
			md.box(cp + out * 0.016 + up * (y1 - 0.05 - k * 0.09), Vector3(cw - 0.06, 0.012, 0.01), Color(0.6, 0.6, 0.6), bas)
	if (X.has("bars") or (f == 0 and mg.kind == "desert" and int(wg["hid"]) % 3 == 0)) and f == 0:
		for k in 5:
			md.cyl(cp + dir * (-cw * 0.5 + (k + 0.5) * cw / 5.0) + off + out * 0.05 + up * y0, 0.015, 0.015, ch, 4, Color(0.12, 0.12, 0.12), bas)
		md.box(cp + off + out * 0.05 + up * (y0 + ch * 0.5), Vector3(cw, 0.025, 0.025), Color(0.12, 0.12, 0.12), bas)
	if X.has("flowers") or (f >= 1 and rng.randf() < 0.12):
		var pp := cp + off + out * 0.16 + up * (y0 - 0.12)
		md.box(pp, Vector3(cw * 0.9, 0.18, 0.2), Color(0.5, 0.32, 0.2), bas)
		for k in 4:
			md.sphere(pp + dir * (-cw * 0.35 + k * cw * 0.233) + up * 0.16, Vector3(0.14, 0.12, 0.12), 6, 4, Color(0.22, 0.42, 0.18), bas)
			md.sphere(pp + dir * (-cw * 0.3 + k * cw * 0.233) + up * 0.24 + out * 0.04, Vector3(0.05, 0.05, 0.05), 4, 3, _pick([Color(0.85, 0.15, 0.15), Color(0.95, 0.85, 0.2), Color(0.9, 0.4, 0.6)]), bas)
	if X.has("ac") and f >= 1 and rng.randf() < 0.28:
		var ap := cp + dir * (cw * 0.5 + 0.55) + off + out * 0.16 + up * (y0 + 0.1)
		md.box(ap, Vector3(0.78, 0.52, 0.26), Color(0.9, 0.9, 0.88), bas)
		md.cyl(ap + out * 0.135, 0.18, 0.18, 0.01, 10, Color(0.3, 0.3, 0.32), bas * Basis(Vector3.RIGHT, PI * 0.5))
		md.box(ap + dir * 0.42 + up * (-0.4), Vector3(0.03, 0.8, 0.03), Color(0.85, 0.85, 0.85), bas)

func _arch_head(md: MB, mgl: MB, base: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y: float, gcol: Color) -> void:
	var r := cw * 0.5
	var n := 7
	var c := base + Vector3.UP * y
	for i in n:
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		var p0 := c + dir * (cos(a0) * r) + Vector3.UP * (sin(a0) * r)
		var p1 := c + dir * (cos(a1) * r) + Vector3.UP * (sin(a1) * r)
		mgl.tri(c + out * 0.012, p0 + out * 0.012, p1 + out * 0.012, gcol, out)
		var q0 := c + dir * (cos(a0) * (r + 0.14)) + Vector3.UP * (sin(a0) * (r + 0.14))
		var q1 := c + dir * (cos(a1) * (r + 0.14)) + Vector3.UP * (sin(a1) * (r + 0.14))
		_beam(md, (p0 + q0) * 0.5 + out * 0.03, (p1 + q1) * 0.5 + out * 0.03, 0.05, 0.16, trim)
	md.box(c + Vector3.UP * (r + 0.07) + out * 0.05, Vector3(0.16, 0.24, 0.07), trim.lightened(0.05), bas)

func _d_door(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y1: float, half: bool, is_main: bool) -> void:
	var md: MB = wg["md"]
	var off := out * (t2 * 0.5)
	var up := Vector3.UP
	var dcol := acc.darkened(0.1) if fac != "timber" else Color(0.94, 0.92, 0.86)
	# kanat: içeri açık (menteşe solda)
	var hinge := cp - dir * (cw * 0.5 - 0.05) - out * 0.05
	var th := 1.25
	var ld := (dir * cos(th) - out * sin(th)).normalized()
	var lw := cw - 0.1
	var lb := Basis(ld, up, ld.cross(up))
	if half:
		md.box(cp - out * 0.0 + up * 0.55, Vector3(cw - 0.06, 1.1, 0.06), dcol, bas)
		for k in 3:
			md.box(cp + out * 0.035 + up * (0.25 + k * 0.32), Vector3(cw - 0.12, 0.05, 0.01), dcol.darkened(0.25), bas)
		md.box(hinge + ld * (lw * 0.5) + up * ((y1 + 1.1) * 0.5), Vector3(lw, y1 - 1.15, 0.05), dcol, lb)
	else:
		md.box(hinge + ld * (lw * 0.5) + up * (y1 * 0.5), Vector3(lw, y1 - 0.06, 0.05), dcol, lb)
		md.box(hinge + ld * (lw * 0.5) + up * (y1 * 0.72) + ld.cross(up) * 0.03, Vector3(lw * 0.7, y1 * 0.3, 0.01), dcol.darkened(0.2), lb)
		md.box(hinge + ld * (lw * 0.5) + up * (y1 * 0.3) + ld.cross(up) * 0.03, Vector3(lw * 0.7, y1 * 0.3, 0.01), dcol.darkened(0.2), lb)
	# kasa + üst atkı
	var kc := frame_c if fac != "timber" else Color(0.94, 0.92, 0.86)
	for sx: float in [-1.0, 1.0]:
		md.box(cp + dir * sx * (cw * 0.5 + 0.04) + off + up * (y1 * 0.5), Vector3(0.09, y1, 0.07), kc, bas)
	md.box(cp + off + up * (y1 + 0.06), Vector3(cw + 0.26, 0.12, 0.08), trim if fac != "timber" else kc, bas)
	# eşik / basamak
	var steps := 3 if (X.has("steps") and is_main) else 1
	for k in steps:
		var sw := cw + 0.5 + (steps - 1 - k) * 0.5
		md.box(cp + off + out * (0.22 + (steps - 1 - k) * 0.3) + up * (0.07 + k * 0.14), Vector3(sw + (steps - k) * 0.4, 0.14, 0.45 + (steps - 1 - k) * 0.6), Color(0.62, 0.6, 0.57), bas)
	if X.has("ramp") and is_main:
		md.box(cp + off + dir * (cw * 0.5 + 1.2) + out * 0.5 + up * 0.08, Vector3(1.6, 0.16, 1.0), Color(0.6, 0.6, 0.58), bas * Basis(Vector3.FORWARD, 0.08))
	# sundurma (küçük saçak) + aplik + kapı numarası
	if not half and fac in ["plaster", "stone", "brick", "adobe", "log", "timber"] and not X.has("porch") and not X.has("porch_full") and not X.has("canopy") and not X.has("portico") and (int(wg["hid"]) + int(cp.x * 7.0)) % 2 == 0:
		var sy := y1 + 0.32
		md.box(cp + off + out * 0.45 + up * sy, Vector3(cw + 0.7, 0.08, 0.9), rcol.darkened(0.1) if fac != "adobe" else Color(0.45, 0.34, 0.24), bas * Basis(Vector3.RIGHT, -0.12))
		for sx: float in [-1.0, 1.0]:
			_beam(md, cp + dir * sx * (cw * 0.5 + 0.2) + off + up * (sy - 0.45), cp + dir * sx * (cw * 0.5 + 0.2) + off + out * 0.75 + up * (sy - 0.05), 0.06, 0.06, Color(0.25, 0.25, 0.25))
	md.box(cp + dir * (cw * 0.5 + 0.35) + off + out * 0.05 + up * (y1 + 0.1), Vector3(0.14, 0.2, 0.1), Color(0.15, 0.15, 0.15), bas)
	md.box(cp + dir * (cw * 0.5 + 0.35) + off + out * 0.1 + up * (y1 + 0.06), Vector3(0.1, 0.1, 0.06), Color(1.0, 0.92, 0.6), bas)
	md.box(cp - dir * (cw * 0.5 + 0.3) + off + out * 0.015 + up * 1.7, Vector3(0.2, 0.14, 0.02), Color(0.12, 0.28, 0.62), bas)

func _d_shop(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y0: float, y1: float) -> void:
	var md: MB = wg["md"]
	var mgl: MB = wg["mdg"]
	var off := out * (t2 * 0.5)
	var up := Vector3.UP
	var vlo := 0.4
	var vhi := (int(wg["rows0"]) - 2) * bh if bh < 0.5 else 2.4
	vhi = maxf(vhi, y1)
	var al := Color(0.28, 0.29, 0.31)
	mgl.box(cp + off + out * 0.012 + up * ((vlo + vhi) * 0.5), Vector3(cw, vhi - vlo, 0.02), _pick(GLASS).lightened(0.06), bas)
	md.box(cp + off + out * 0.02 + up * (vlo * 0.5), Vector3(cw + 0.1, vlo, 0.05), Color(0.3, 0.3, 0.32), bas)
	var nm := maxi(1, int(cw / 0.95))
	for k in nm + 1:
		md.box(cp + dir * (-cw * 0.5 + k * cw / nm) + off + out * 0.03 + up * ((vlo + vhi) * 0.5), Vector3(0.06, vhi - vlo, 0.05), al, bas)
	md.box(cp + off + out * 0.03 + up * vhi, Vector3(cw + 0.06, 0.08, 0.06), al, bas)
	md.box(cp + off + out * 0.03 + up * (vlo + 0.02), Vector3(cw + 0.06, 0.05, 0.06), al, bas)
	# ürün rafı silueti (camın içinde)
	for k in 3:
		md.box(cp - out * 0.15 + up * (0.7 + k * 0.4), Vector3(cw * 0.9, 0.05, 0.25), Color(0.5, 0.45, 0.4), bas)
		for j in 4:
			md.box(cp - out * 0.1 + dir * (-cw * 0.36 + j * cw * 0.24) + up * (0.82 + k * 0.4), Vector3(cw * 0.16, 0.2, 0.15), _pick([Color(0.8, 0.3, 0.2), Color(0.25, 0.5, 0.7), Color(0.9, 0.8, 0.3), Color(0.4, 0.6, 0.3)]), bas)
	# kepenk: yarı inik / kapalı
	if X.has("rollshut") or X.has("rollbox") or rng.randf() < 0.3:
		md.box(cp + off + out * 0.1 + up * (vhi + 0.16), Vector3(cw + 0.1, 0.3, 0.22), Color(0.6, 0.6, 0.6), bas)
		var fr := 1.0 if rng.randf() < 0.18 else rng.randf_range(0.1, 0.5)
		var sh := (vhi - vlo + 0.4) * fr
		md.box(cp + off + out * 0.04 + up * (vhi - sh * 0.5), Vector3(cw, sh, 0.03), Color(0.7, 0.7, 0.68), bas)
		for k in int(sh / 0.1):
			md.box(cp + off + out * 0.058 + up * (vhi - 0.05 - k * 0.1), Vector3(cw - 0.02, 0.015, 0.01), Color(0.5, 0.5, 0.5), bas)
	# tabela
	var sy := vhi + 0.5
	var scol: Color = _sign_col()
	md.box(cp + off + out * 0.06 + up * sy, Vector3(cw + 0.3, 0.55, 0.08), scol, bas)
	_letters(md, cp + off + out * 0.105 + up * sy, dir, bas, cw * 0.8, 0.3, scol)
	if X.has("awn") or X.has("awns") or X.has("clothawn"):
		_awning(md, cp + off + up * (vhi + 0.12), dir, out, bas, cw + 0.4)
	if X.has("signs"):
		# dik bayrak tabela (sokaktan okunur)
		var bp := cp + dir * (cw * 0.5 + 0.2) + off + out * 0.45 + up * (vhi + 0.9)
		md.box(bp - out * 0.2, Vector3(0.05, 0.05, 0.5), Color(0.2, 0.2, 0.2), bas)
		var bc := _sign_col()
		md.box(bp, Vector3(0.06, 0.6, 0.7), bc, bas)
		md.box(bp + dir * 0.035, Vector3(0.01, 0.3, 0.5), Color(0.97, 0.97, 0.95) if bc.get_luminance() < 0.6 else Color(0.1, 0.1, 0.1), bas)

func _sign_col() -> Color:
	if X.has("sign_y"):
		return Color(0.95, 0.78, 0.1)
	if X.has("sign_g"):
		return Color(0.1, 0.55, 0.3)
	if X.has("sign_r"):
		return Color(0.72, 0.1, 0.08)
	return _pick([Color(0.12, 0.25, 0.55), Color(0.72, 0.12, 0.1), Color(0.1, 0.45, 0.26), Color(0.15, 0.15, 0.18), Color(0.92, 0.75, 0.15), Color(0.95, 0.95, 0.93)])

# sahte yazı: tabela üstünde harf kütleleri
func _letters(md: MB, c: Vector3, dir: Vector3, bas: Basis, w: float, h: float, bg: Color) -> void:
	var lc := Color(0.97, 0.97, 0.95) if bg.get_luminance() < 0.6 else Color(0.1, 0.1, 0.12)
	var n := maxi(3, int(w / (h * 0.75)))
	if sign_txt != "":
		n = clampi(sign_txt.length(), 2, 18)
	var cwid := w / n
	for i in n:
		if sign_txt != "" and i < sign_txt.length() and sign_txt[i] == " ":
			continue
		var lx := -w * 0.5 + (i + 0.5) * cwid
		var gw := cwid * rng.randf_range(0.55, 0.8)
		md.box(c + dir * lx + Vector3.UP * (h * 0.15), Vector3(gw, h * 0.12, 0.012), lc, bas)
		md.box(c + dir * lx - Vector3.UP * (h * 0.3), Vector3(gw, h * 0.12, 0.012), lc, bas)
		md.box(c + dir * (lx - gw * 0.4), Vector3(gw * 0.2, h * 0.7, 0.012), lc, bas)
		if rng.randf() < 0.6:
			md.box(c + dir * (lx + gw * 0.4), Vector3(gw * 0.2, h * 0.7, 0.012), lc, bas)
		if rng.randf() < 0.5:
			md.box(c + dir * lx + Vector3.UP * (h * 0.35), Vector3(gw, h * 0.12, 0.012), lc, bas)

func _awning(md: MB, top: Vector3, dir: Vector3, out: Vector3, bas: Basis, w: float) -> void:
	var cols: Array = _pick(AWN)
	var n := maxi(2, int(w / 0.4))
	var sw := w / n
	var depth := 1.25
	var drop := 0.5
	var tilt := atan2(drop, depth)
	for i in n:
		var p := top + dir * (-w * 0.5 + (i + 0.5) * sw) + out * (depth * 0.5) - Vector3.UP * (drop * 0.5)
		md.box(p, Vector3(sw, 0.03, sqrt(depth * depth + drop * drop)), cols[i % 2], bas * Basis(Vector3.RIGHT, tilt))
		md.box(top + dir * (-w * 0.5 + (i + 0.5) * sw) + out * depth - Vector3.UP * (drop + 0.12), Vector3(sw, 0.24, 0.02), cols[i % 2], bas)
	for sx: float in [-1.0, 1.0]:
		_beam(md, top + dir * sx * (w * 0.5 - 0.05) - Vector3.UP * 0.6, top + dir * sx * (w * 0.5 - 0.05) + out * depth - Vector3.UP * drop, 0.03, 0.03, Color(0.3, 0.3, 0.3))

func _d_roll(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y1: float, kd: String) -> void:
	var md: MB = wg["md"]
	var off := out * (t2 * 0.5)
	var up := Vector3.UP
	var col := Color(0.72, 0.72, 0.7)
	if kd == "fire":
		col = Color(0.75, 0.12, 0.1)
	elif fac == "timber":
		col = (wg["rgb"] as Color).darkened(0.1)
	elif kd == "gar":
		col = _pick([Color(0.82, 0.82, 0.8), Color(0.6, 0.62, 0.64), Color(0.45, 0.32, 0.22), Color(0.3, 0.4, 0.5)])
	var fr := rng.randf_range(0.35, 0.65)
	if fac == "timber" and kd == "roll":
		# ahır: iki kanatlı sürgülü kapı, X kuşaklı, aralık
		var gap := cw * rng.randf_range(0.25, 0.5)
		for sx: float in [-1.0, 1.0]:
			var lc := cp + dir * sx * (cw * 0.25 + gap * 0.25 + cw * 0.25 * 0.0) + off + out * 0.06
			var lp := cp + dir * sx * (gap * 0.5 + cw * 0.25) + off + out * 0.06 + up * (y1 * 0.5)
			md.box(lp, Vector3(cw * 0.5, y1, 0.06), col, bas)
			var t := Color(0.94, 0.92, 0.86)
			_beam(md, lp - dir * cw * 0.22 - up * y1 * 0.45 + out * 0.04, lp + dir * cw * 0.22 + up * y1 * 0.45 + out * 0.04, 0.03, 0.12, t)
			_beam(md, lp + dir * cw * 0.22 - up * y1 * 0.45 + out * 0.04, lp - dir * cw * 0.22 + up * y1 * 0.45 + out * 0.04, 0.03, 0.12, t)
			md.box(lp + out * 0.04, Vector3(cw * 0.5, 0.12, 0.03), t, bas)
			var _u := lc
		md.box(cp + off + out * 0.12 + up * (y1 + 0.15), Vector3(cw * 1.6, 0.1, 0.1), Color(0.25, 0.25, 0.25), bas)
		return
	var sh := y1 * fr
	md.box(cp + off + out * 0.04 + up * (y1 - sh * 0.5), Vector3(cw, sh, 0.05), col, bas)
	for k in int(sh / 0.22):
		md.box(cp + off + out * 0.07 + up * (y1 - 0.11 - k * 0.22), Vector3(cw - 0.04, 0.025, 0.02), col.darkened(0.2), bas)
	md.box(cp + off + out * 0.12 + up * (y1 + 0.18), Vector3(cw + 0.2, 0.36, 0.24), col.darkened(0.15), bas)
	for sx: float in [-1.0, 1.0]:
		md.box(cp + dir * sx * (cw * 0.5 + 0.06) + off + out * 0.05 + up * (y1 * 0.5), Vector3(0.1, y1, 0.1), Color(0.3, 0.3, 0.3), bas)
		if kd in ["roll", "dock"]:
			for k in 6:
				md.box(cp + dir * sx * (cw * 0.5 + 0.2) + off + out * 0.08 + up * (0.12 + k * 0.2), Vector3(0.12, 0.1, 0.06), Color(0.95, 0.8, 0.1) if k % 2 == 0 else Color(0.1, 0.1, 0.1), bas)
	if kd == "dock":
		for sx: float in [-1.0, 1.0]:
			md.box(cp + dir * sx * (cw * 0.5 - 0.2) + off + out * 0.15 + up * 0.5, Vector3(0.25, 0.4, 0.2), Color(0.1, 0.1, 0.1), bas)
	md.box(cp + off + out * 0.2 + up * (y1 + 0.5), Vector3(0.3, 0.12, 0.2), Color(0.95, 0.9, 0.6), bas)
	if kd == "fire":
		_letters(md, cp + off + out * 0.13 + up * (y1 + 0.18), dir, bas, cw * 0.6, 0.22, Color(0.6, 0.1, 0.08))

func _d_arc(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y1: float) -> void:
	var md: MB = wg["md"]
	var off := out * (t2 * 0.5)
	var r := cw * 0.5
	var c := cp + off + out * 0.03 + Vector3.UP * (y1 - r)
	var n := 9
	for i in n:
		var a0 := PI * i / n
		var a1 := PI * (i + 1) / n
		_beam(md, c + dir * (cos(a0) * (r + 0.1)) + Vector3.UP * (sin(a0) * (r + 0.1)), c + dir * (cos(a1) * (r + 0.1)) + Vector3.UP * (sin(a1) * (r + 0.1)), 0.08, 0.22, trim if i % 2 == 0 else trim.darkened(0.12))
		# köşe dolgusu (kemer omuzları)
		var p0 := c + dir * (cos(a0) * r) + Vector3.UP * (sin(a0) * r)
		var p1 := c + dir * (cos(a1) * r) + Vector3.UP * (sin(a1) * r)
		var corner := c + dir * (r * signf(cos((a0 + a1) * 0.5))) + Vector3.UP * r
		md.tri(p0 + out * 0.01, p1 + out * 0.01, corner + out * 0.01, wg["rgb"], out)
	for sx: float in [-1.0, 1.0]:
		md.box(cp + dir * sx * (r + 0.12) + off + out * 0.03 + Vector3.UP * ((y1 - r) * 0.5), Vector3(0.24, y1 - r, 0.08), trim, bas)
	md.box(c + Vector3.UP * (r + 0.14) + out * 0.03, Vector3(0.24, 0.3, 0.1), trim.lightened(0.08), bas)

func _d_bell(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y0: float, y1: float) -> void:
	var md: MB = wg["md"]
	var off := out * (t2 * 0.5)
	_arch_head(md, wg["mdg"], cp + off, dir, out, bas, cw, y1, Color(0.08, 0.08, 0.09))
	for k in 5:
		md.box(cp + Vector3.UP * (y0 + 0.2 + k * (y1 - y0 - 0.3) / 5.0), Vector3(cw, 0.04, 0.2), Color(0.3, 0.24, 0.18), bas * Basis(Vector3.RIGHT, 0.5))
	md.box(cp + off + out * 0.08 + Vector3.UP * (y0 - 0.04), Vector3(cw + 0.3, 0.08, 0.22), trim, bas)

func _d_high(wg: Dictionary, cp: Vector3, out: Vector3, bas: Basis, cw: float, y0: float, y1: float) -> void:
	var md: MB = wg["md"]
	var mgl: MB = wg["mdg"]
	var ch := y1 - y0
	var up := Vector3.UP
	mgl.box(cp - out * 0.04 + up * ((y0 + y1) * 0.5), Vector3(cw, ch, 0.03), Color(0.3, 0.36, 0.38), bas)
	var g := Color(0.2, 0.22, 0.24)
	for k in 4:
		md.box(cp + bas.x * (-cw * 0.5 + k * cw / 3.0) - out * 0.02 + up * ((y0 + y1) * 0.5), Vector3(0.05, ch, 0.06), g, bas)
	for k in 3:
		md.box(cp - out * 0.02 + up * (y0 + k * ch / 2.0), Vector3(cw, 0.05, 0.06), g, bas)
	md.box(cp + out * (t2 * 0.5 + 0.06) + up * (y0 - 0.03), Vector3(cw + 0.16, 0.06, 0.16), trim, bas)

# balkon: döşeme, korkuluk, eşyalar
func _d_balcony(wg: Dictionary, cp: Vector3, dir: Vector3, out: Vector3, bas: Basis, bw: float, y0: float) -> void:
	var md: MB = wg["md"]
	var off := out * (t2 * 0.5)
	var up := Vector3.UP
	var dep := 1.05 if not X.has("bal_small") else 0.6
	var wood := X.has("bal_wood") or X.has("bal_wood_wrap")
	var slab := Color(0.8, 0.79, 0.76) if not wood else Color(0.45, 0.33, 0.22)
	md.box(cp + off + out * (dep * 0.5) + up * (y0 - 0.08), Vector3(bw, 0.16, dep), slab, bas)
	md.box(cp + off + out * dep + up * (y0 - 0.08), Vector3(bw + 0.02, 0.2, 0.04), slab.darkened(0.1), bas)
	var rc := Color(0.15, 0.15, 0.16) if not wood else Color(0.42, 0.3, 0.2)
	var solid := X.has("loggia") or (not wood and int(wg["hid"]) % 3 == 1)
	var rh := 1.0
	# korkuluk üç kenar
	for e in 3:
		var a: Vector3
		var b: Vector3
		if e == 0:
			a = cp + off + out * (dep - 0.03) - dir * (bw * 0.5 - 0.03)
			b = cp + off + out * (dep - 0.03) + dir * (bw * 0.5 - 0.03)
		elif e == 1:
			a = cp + off - dir * (bw * 0.5 - 0.03)
			b = a + out * (dep - 0.03)
		else:
			a = cp + off + dir * (bw * 0.5 - 0.03)
			b = a + out * (dep - 0.03)
		if solid:
			_beam(md, a + up * (y0 + rh * 0.5), b + up * (y0 + rh * 0.5), 0.08, rh, (wg["rgb"] as Color).lightened(0.05))
			continue
		_beam(md, a + up * (y0 + rh), b + up * (y0 + rh), 0.06, 0.06, rc)
		_beam(md, a + up * (y0 + 0.08), b + up * (y0 + 0.08), 0.05, 0.05, rc)
		var L := a.distance_to(b)
		var n := int(L / (0.13 if not wood else 0.16))
		for i in n + 1:
			var p := a.lerp(b, float(i) / maxf(n, 1))
			md.box(p + up * (y0 + rh * 0.5), Vector3(0.025 if not wood else 0.06, rh, 0.025 if not wood else 0.04), rc, Basis())
	# eşya: saksı, sandalye, çamaşır, çanak anten
	var r := rng.randf()
	var ip := cp + off + out * (dep * 0.5)
	if r < 0.3:
		for k in 2:
			md.cyl(ip + dir * (bw * 0.3 * (k * 2 - 1)) + up * y0, 0.14, 0.18, 0.3, 8, Color(0.62, 0.32, 0.2), bas)
			md.sphere(ip + dir * (bw * 0.3 * (k * 2 - 1)) + up * (y0 + 0.45), Vector3(0.24, 0.22, 0.24), 7, 5, Color(0.24, 0.45, 0.2), bas)
	elif r < 0.5:
		var lp := ip + up * (y0 + 1.4)
		_beam(md, lp - dir * bw * 0.45, lp + dir * bw * 0.45, 0.015, 0.015, Color(0.8, 0.8, 0.8))
		for k in 4:
			md.box(lp + dir * (-bw * 0.35 + k * bw * 0.23) - up * 0.25, Vector3(bw * 0.18, 0.5, 0.015), _pick([Color(0.9, 0.9, 0.92), Color(0.3, 0.45, 0.7), Color(0.8, 0.3, 0.3), Color(0.9, 0.8, 0.4)]), bas)
	elif r < 0.68 and X.has("dish"):
		_dish(md, cp + off + out * (dep - 0.1) + dir * (bw * 0.35) + up * (y0 + 1.05), Basis(Vector3.UP, ang * 0.0) * bas, 0.32)
	elif r < 0.8:
		md.box(ip + dir * (bw * 0.3) + up * (y0 + 0.25), Vector3(0.4, 0.5, 0.4), Color(0.85, 0.85, 0.83), bas)
		md.box(ip + dir * (-bw * 0.2) + up * (y0 + 0.22), Vector3(0.45, 0.04, 0.45), Color(0.9, 0.9, 0.9), bas)

# çanak anten: çanak + kol + LNB (yerel taban basis)
func _dish(mb: MB, p: Vector3, bas: Basis, r: float) -> void:
	var tilt := bas * Basis(Vector3.RIGHT, -0.9)
	mb.sphere(p, Vector3(r, r * 0.25, r), 10, 6, Color(0.92, 0.92, 0.9), tilt, true)
	mb.cyl(p - Vector3.UP * 0.4, 0.02, 0.02, 0.4, 4, Color(0.4, 0.4, 0.4))
	_beam(mb, p, p + tilt.y * (r * 0.9), 0.015, 0.015, Color(0.3, 0.3, 0.3))
	mb.box(p + tilt.y * (r * 0.9), Vector3(0.05, 0.05, 0.08), Color(0.2, 0.2, 0.2), tilt)

# ------------------------------------------------------------ cephe süsü: duvar boyu
func _d_wall(wg: Dictionary, k: int, la: Vector3, lb: Vector3, out: Vector3, L: float, ops: Array) -> void:
	var md: MB = wg["md"]
	var dir := (lb - la) / L
	var bas := _basis(dir, out)
	var off := out * (t2 * 0.5)
	var mid := (la + lb) * 0.5
	var up := Vector3.UP
	var top: float = wg["top"]
	var nfl: int = wg["fl"]
	var rgb: Color = wg["rgb"]
	var rf := String(wg["rf"])
	var flat := rf in ["flat", "dome", "lantern"]
	var pl := String(A.get("pl", ""))
	var is_main: bool = wg.get("main", false)
	var dop := {}
	for o in ops:
		if o.get("main", false):
			dop = o
	var ds: float = float(dop.get("s", L * 0.5))
	# süpürgelik / kaide silmesi
	if fac in ["plaster", "panel", "conc"] and pl == "":
		md.box(mid + off + out * 0.02 + up * 0.18, Vector3(L + 0.04, 0.36, 0.05), rgb.darkened(0.28), bas)
	if pl != "":
		var py := (int(wg["rows0"]) if nfl >= 2 else (2 if bh < 0.5 else 1)) * bh
		md.box(mid + off + out * 0.05 + up * py, Vector3(L + 0.08, 0.09, 0.12), Color(0.62, 0.6, 0.56), bas)
	# kat silmeleri
	if nfl >= 2 and fac in ["plaster", "stone", "conc", "panel", "adobe"]:
		for f in range(1, nfl):
			md.box(mid + off + out * 0.04 + up * (f * rpf * bh), Vector3(L + 0.1, 0.14, 0.09), trim, bas)
	if X.has("bands") and nfl >= 2:
		for f in range(1, nfl):
			md.box(mid + off + out * 0.012 + up * (f * rpf * bh + 0.3), Vector3(L, 0.5, 0.02), rgb.darkened(0.14) if fac != "brick" else Color(0.86, 0.84, 0.78), bas)
	if X.has("panels"):
		for f in nfl:
			md.box(mid + off + out * 0.015 + up * (f * rpf * bh), Vector3(L, 0.04, 0.02), rgb.darkened(0.3), bas)
		var nv := int(L / 3.0)
		for i in nv + 1:
			md.box(la + dir * (i * L / maxf(nv, 1)) + off + out * 0.015 + up * (top * 0.5), Vector3(0.04, top, 0.02), rgb.darkened(0.3), bas)
	# saçak silmesi / korniş
	if not flat and rf not in ["open"]:
		md.box(mid + off + out * 0.06 + up * (top - 0.1), Vector3(L + 0.24, 0.2, 0.14), trim, bas)
	if X.has("cornice"):
		md.box(mid + off + out * 0.16 + up * (top - 0.2), Vector3(L + 0.5, 0.3, 0.34), trim, bas)
		var nd := int(L / 0.35)
		for i in nd:
			md.box(la + dir * ((i + 0.5) * L / nd) + off + out * 0.08 + up * (top - 0.45), Vector3(0.12, 0.16, 0.16), trim.darkened(0.06), bas)
		for sx: float in [0.25, L - 0.25]:
			md.box(la + dir * sx + off + out * 0.06 + up * (top * 0.5), Vector3(0.45, top, 0.12), trim, bas)
	# ahşap karkas (bağdadi): üst katlarda koyu kirişler
	if X.has("tframe"):
		var tc := Color(0.3, 0.2, 0.13)
		for f in range(1 if nfl > 1 else 0, nfl):
			var fy0 := f * rpf * bh + 0.06
			var fy1 := minf((f + 1) * rpf * bh, top) - 0.06
			md.box(mid + off + out * 0.025 + up * fy0, Vector3(L, 0.12, 0.05), tc, bas)
			md.box(mid + off + out * 0.025 + up * fy1, Vector3(L, 0.12, 0.05), tc, bas)
			var s := 0.2
			while s < L - 0.1:
				var free := true
				for o in ops:
					if int(o["f"]) == f and absf(s - float(o["s"])) < float(o["w"]) * 0.5 + 0.12:
						free = false
				if free:
					md.box(la + dir * s + off + out * 0.025 + up * ((fy0 + fy1) * 0.5), Vector3(0.12, fy1 - fy0, 0.05), tc, bas)
				s += 1.15
			for e in [[0.2, 1.3], [L - 0.2, L - 1.3]]:
				_beam(md, la + dir * float(e[0]) + off + out * 0.03 + up * fy0, la + dir * float(e[1]) + off + out * 0.03 + up * fy1, 0.05, 0.1, tc)
	# kerpiç: dışa taşan hatıl uçları
	if X.has("viga"):
		var s := 0.45
		while s < L - 0.3:
			md.box(la + dir * s + off + out * 0.22 + up * (top - 0.32), Vector3(0.13, 0.13, 0.46), Color(0.36, 0.27, 0.18), bas)
			s += rng.randf_range(0.55, 0.8)
	if X.has("ventholes"):
		# havalandırma delikleri: üst kuşakta üçgen dizili kerpiç boşluklar
		var s := 0.6
		while s < L - 0.5:
			for j in 3:
				if j == 1 or int(s / 0.6) % 2 == 0:
					md.box(la + dir * (s + (0.15 if j == 1 else 0.0)) + off + out * 0.01 + up * (top - 0.9 + j * 0.22 - (0.22 if j == 2 else 0.0)), Vector3(0.12, 0.14, 0.02), Color(0.08, 0.06, 0.05), bas)
			s += 0.6
	if X.has("machic") and k == 0:
		md.box(mid + off + out * 0.4 + up * (top - 0.9), Vector3(1.6, 0.9, 0.8), rgb, bas)
		for sx: float in [-0.6, 0.0, 0.6]:
			md.box(mid + dir * sx + off + out * 0.4 + up * (top - 1.45), Vector3(0.14, 0.3, 0.6), rgb.darkened(0.1), bas)
	# kütük uçları (köşe bindirme)
	if X.has("logends"):
		var y := 0.2
		while y < top:
			md.cyl_between(la - dir * 0.4 + up * y, la + dir * 0.1 + up * y, 0.17, 0.17, 7, rgb.darkened(0.15))
			md.cyl_between(lb + dir * 0.4 + up * y, lb - dir * 0.1 + up * y, 0.17, 0.17, 7, rgb.darkened(0.15))
			y += bh * 2.0
	# yağmur borusu
	if X.has("gutter") or nfl >= 2 or (rf != "flat" and int(wg["hid"]) % 2 == 0):
		var gs := 0.18 if k % 2 == 0 else L - 0.18
		var gc := Color(0.6, 0.6, 0.6) if fac not in ["stone", "timber", "log"] else Color(0.45, 0.32, 0.24)
		md.cyl(la + dir * gs + off + out * 0.08 + up * 0.15, 0.05, 0.05, top - 0.2, 6, gc)
		md.box(la + dir * gs + off + out * 0.16 + up * 0.12, Vector3(0.1, 0.1, 0.22), gc, bas)
	# yan duvar klima / elektrik panosu
	if X.has("ac") and k >= 2 and int(wg["hid"]) % 2 == 0:
		var ap := la + dir * (L * rng.randf_range(0.25, 0.75)) + off + out * 0.16 + up * 2.3
		md.box(ap, Vector3(0.8, 0.55, 0.3), Color(0.9, 0.9, 0.88), bas)
		md.cyl(ap + out * 0.155, 0.19, 0.19, 0.01, 10, Color(0.3, 0.3, 0.32), bas * Basis(Vector3.RIGHT, PI * 0.5))
	if k == int(wg.get("dside", -1)) and rng.randf() < 0.5 and fac != "timber":
		md.box(la + dir * clampf(ds + 1.6, 0.4, L - 0.4) + off + out * 0.08 + up * 1.4, Vector3(0.45, 0.6, 0.16), Color(0.7, 0.7, 0.68), bas)
	if not is_main:
		if X.has("extstair") and k == 3 and nfl >= 1 and wg.get("garage", false) == false:
			pass
		return
	# tabela ve kamu işaretleri (ön cephe)
	if k == 0:
		var shop := String(A.get("wk", "")) == "shop"
		if sign_txt != "" and not shop and not X.has("roofsign") and not X.has("marquee") and not X.has("bigsign") and not X.has("paintsign"):
			var sy := (int(wg["rows0"]) * bh - 0.45) if nfl > 1 else top - 0.55
			if rf == "flat" and nfl == 1:
				sy = top + 0.1
			var sw := minf(L * 0.7, 0.32 * sign_txt.length() + 1.0)
			var scol := _sign_col()
			md.box(la + dir * (L * 0.5) + off + out * 0.07 + up * sy, Vector3(sw, 0.6, 0.08), scol, bas)
			_letters(md, la + dir * (L * 0.5) + off + out * 0.115 + up * sy, dir, bas, sw * 0.86, 0.34, scol)
		if X.has("bigsign"):
			var sw := L * 0.72
			var scol := _sign_col()
			var sy := top - 0.9 if rf != "flat" else top + 0.55
			md.box(mid + off + out * 0.1 + up * sy, Vector3(sw, 1.3, 0.12), scol, bas)
			_letters(md, mid + off + out * 0.165 + up * sy, dir, bas, sw * 0.86, 0.8, scol)
		if X.has("paintsign"):
			_letters(md, mid + off + out * 0.012 + up * (top - 1.4), dir, bas, L * 0.75, 1.2, rgb)
		if X.has("signs_v"):
			for i in 3:
				var sp := la + dir * (L * (0.2 + i * 0.3)) + off + out * 0.35 + up * (3.0 + i * 2.6)
				var scol := _sign_col()
				md.box(sp, Vector3(0.1, 2.2, 0.6), scol, bas)
				for j in 5:
					md.box(sp + dir * 0.06 + up * (-0.8 + j * 0.4), Vector3(0.012, 0.26, 0.4), Color(0.97, 0.97, 0.95) if scol.get_luminance() < 0.6 else Color(0.1, 0.1, 0.1), bas)
		if X.has("redcross"):
			var cp2 := mid + off + out * 0.04 + up * (top - 1.0)
			md.box(cp2, Vector3(1.4, 1.4, 0.06), Color(0.96, 0.96, 0.96), bas)
			md.box(cp2 + out * 0.04, Vector3(1.0, 0.32, 0.03), Color(0.85, 0.08, 0.08), bas)
			md.box(cp2 + out * 0.04, Vector3(0.32, 1.0, 0.03), Color(0.85, 0.08, 0.08), bas)
		if X.has("clock"):
			_clock(md, mid + off + out * 0.05 + up * (top - 0.9), bas, 0.55)
		if X.has("posters"):
			for sx: float in [-1.0, 1.0]:
				for j in 2:
					var pp := la + dir * (L * 0.5 + sx * (2.2 + j * 1.3)) + off + out * 0.04 + up * 1.6
					md.box(pp, Vector3(1.0, 1.4, 0.06), Color(0.15, 0.15, 0.15), bas)
					md.box(pp + out * 0.035, Vector3(0.86, 1.26, 0.01), _pick([Color(0.75, 0.2, 0.15), Color(0.2, 0.35, 0.6), Color(0.85, 0.7, 0.2), Color(0.3, 0.5, 0.3)]), bas)
		if X.has("falsefront"):
			md.box(mid + off + out * 0.05 + up * (top + 1.0), Vector3(L + 0.1, 2.0, 0.3), rgb, bas)
			md.box(mid + off + out * 0.12 + up * (top + 2.05), Vector3(L + 0.3, 0.16, 0.3), trim, bas)
		if X.has("arcade"):
			_arcade(wg, la, dir, out, bas, L, 2.6)
		if X.has("gallery"):
			_gallery(wg, la, dir, out, bas, L)
	if k == int(wg.get("dside", -1)):
		var dp := la + dir * ds + off
		if X.has("board"):
			md.box(dp + dir * 1.5 + out * 0.04 + up * 1.5, Vector3(1.0, 0.8, 0.06), Color(0.4, 0.3, 0.2), bas)
			md.box(dp + dir * 1.5 + out * 0.075 + up * 1.5, Vector3(0.88, 0.68, 0.01), Color(0.92, 0.9, 0.84), bas)
		if X.has("mailbox"):
			md.box(dp - dir * 1.4 + out * 0.15 + up * 1.2, Vector3(0.45, 0.6, 0.3), Color(0.95, 0.75, 0.1), bas)
		if X.has("atm"):
			md.box(dp + dir * 1.6 + out * 0.03 + up * 1.2, Vector3(0.7, 1.0, 0.06), Color(0.2, 0.25, 0.32), bas)
			md.box(dp + dir * 1.6 + out * 0.07 + up * 1.35, Vector3(0.36, 0.28, 0.02), Color(0.3, 0.6, 0.8), bas)
		if X.has("barberpole"):
			var bp := dp + dir * 1.2 + out * 0.2 + up * 1.4
			md.cyl(bp, 0.09, 0.09, 0.8, 8, Color(0.95, 0.95, 0.95))
			for j in 4:
				md.cyl(bp + up * (0.08 + j * 0.18), 0.095, 0.095, 0.07, 8, Color(0.8, 0.1, 0.1) if j % 2 == 0 else Color(0.15, 0.25, 0.65))
		if X.has("porch") or X.has("porch_full") or X.has("porch_small"):
			var pw := L if X.has("porch_full") else (2.6 if X.has("porch_small") else minf(L, 4.8))
			var pc := clampf(ds, pw * 0.5, L - pw * 0.5) if not X.has("porch_full") else L * 0.5
			_porch(wg, la + dir * pc + off, dir, out, bas, pw)
		if X.has("portico"):
			_portico(wg, dp, dir, out, bas, minf(L * 0.55, 7.5))
		if X.has("canopy") and not X.has("portico"):
			_canopy(wg, dp, dir, out, bas)
		if X.has("marquee"):
			_marquee(wg, dp, dir, out, bas, minf(L * 0.6, 8.0))
	# dış merdiven: kapı olmayan yan duvar boyunca üst kata / dama
	if X.has("extstair") and k == (3 if int(wg.get("dside", 0)) != 3 else 2):
		_extstair(wg, la, dir, out, bas, L, rpf * bh if nfl >= 2 else top)
	# balkon bandı / lojya / çepeçevre ahşap balkon
	if (X.has("balband") or X.has("loggia")) and k <= 1 or X.has("bal_wood_wrap"):
		for f in range(1, nfl):
			_d_balcony(wg, mid, dir, out, bas, L - 0.3, f * rpf * bh)
	if X.has("cumba") and k == 0 and nfl >= 2:
		for f in range(1, nfl):
			_cumba(wg, la + dir * (L * 0.5) + off, dir, out, bas, clampf(L * 0.4, 2.0, 3.4), f * rpf * bh, rpf * bh)

func _clock(md: MB, p: Vector3, bas: Basis, r: float) -> void:
	md.cyl(p, r + 0.08, r + 0.08, 0.06, 16, Color(0.25, 0.22, 0.18), bas * Basis(Vector3.RIGHT, PI * 0.5))
	md.cyl(p + bas.z * 0.04, r, r, 0.04, 16, Color(0.95, 0.94, 0.88), bas * Basis(Vector3.RIGHT, PI * 0.5))
	md.box(p + bas.z * 0.09 + Vector3.UP * r * 0.3, Vector3(0.05, r * 0.6, 0.02), Color(0.1, 0.1, 0.1), bas)
	md.box(p + bas.z * 0.09 + bas.x * r * 0.22, Vector3(r * 0.45, 0.05, 0.02), Color(0.1, 0.1, 0.1), bas)
	for i in 12:
		var a := TAU * i / 12.0
		md.box(p + bas.z * 0.075 + (bas.x * cos(a) + Vector3.UP * sin(a)) * r * 0.85, Vector3(0.05, 0.05, 0.02), Color(0.15, 0.15, 0.15), bas)

func _porch(wg: Dictionary, base: Vector3, dir: Vector3, out: Vector3, bas: Basis, pw: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var dep := 1.9
	var h := minf(int(wg["rows0"]) * bh - 0.1, 2.7)
	var wood := Color(0.42, 0.3, 0.2)
	md.box(base + out * (dep * 0.5) + up * 0.1, Vector3(pw, 0.2, dep), Color(0.55, 0.52, 0.48), bas)
	var np := maxi(2, int(pw / 2.2) + 1)
	for i in np:
		var pp := base + dir * (-pw * 0.5 + 0.12 + i * (pw - 0.24) / (np - 1)) + out * (dep - 0.12)
		md.box(pp + up * (h * 0.5 + 0.2), Vector3(0.14, h, 0.14), wood if fac != "stone" else trim, bas)
	# korkuluk
	_beam(md, base - dir * (pw * 0.5 - 0.1) + out * (dep - 0.12) + up * 1.0, base + dir * (pw * 0.5 - 0.1) + out * (dep - 0.12) + up * 1.0, 0.06, 0.06, wood)
	# eğimli sundurma çatısı (çatı dokusu)
	var mr := _mr(wg, rtex if rtex != "conc" else "metal")
	var a := base + up * (h + 0.55) - dir * (pw * 0.5 + 0.2)
	var b := base + up * (h + 0.55) + dir * (pw * 0.5 + 0.2)
	var c := b + out * (dep + 0.3) - up * 0.5
	var d := a + out * (dep + 0.3) - up * 0.5
	mr.quad(a, b, c, d, rcol, (out + up * 1.8).normalized())
	md.box((a + b + c + d) * 0.25 - up * 0.08, Vector3(pw + 0.4, 0.06, dep + 0.2), wood.darkened(0.2), bas * Basis(Vector3.RIGHT, -0.26))

func _portico(wg: Dictionary, dp: Vector3, dir: Vector3, out: Vector3, bas: Basis, pw: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var h := minf(float(wg["top"]) - 0.4, 6.4)
	var dep := 2.3
	var nc := 4 if pw < 6.5 else 6
	var cc := trim.lightened(0.05)
	for i in nc:
		var pp := dp + dir * (-pw * 0.5 + 0.3 + i * (pw - 0.6) / (nc - 1)) + out * (dep - 0.3)
		md.box(pp + up * 0.15, Vector3(0.6, 0.3, 0.6), cc, bas)
		md.cyl(pp + up * 0.3, 0.24, 0.2, h - 0.65, 12, cc)
		md.box(pp + up * (h - 0.25), Vector3(0.6, 0.2, 0.6), cc, bas)
	md.box(dp + out * (dep * 0.5) + up * (h + 0.05), Vector3(pw + 0.4, 0.5, dep + 0.2), cc, bas)
	# alınlık
	var a := dp - dir * (pw * 0.5 + 0.2) + out * (dep + 0.08) + up * (h + 0.3)
	var b := dp + dir * (pw * 0.5 + 0.2) + out * (dep + 0.08) + up * (h + 0.3)
	var t := dp + out * (dep + 0.08) + up * (h + 0.3 + pw * 0.22)
	md.tri(a, b, t, cc.darkened(0.05), out)
	var mr := _mr(wg, "slate" if rtex in ["conc", "mud"] else rtex)
	mr.quad(a, t, t - out * (dep + 0.1), a - out * (dep + 0.1), rcol, (up - dir * 0.6).normalized())
	mr.quad(t, b, b - out * (dep + 0.1), t - out * (dep + 0.1), rcol, (up + dir * 0.6).normalized())
	for i in 4:
		md.box(dp + out * (0.4 + (3 - i) * 0.4) + up * (0.08 + i * 0.16), Vector3(pw + 0.8 - i * 0.2, 0.16, 0.42 + i * 0.0), Color(0.68, 0.66, 0.62), bas)

func _canopy(wg: Dictionary, dp: Vector3, dir: Vector3, out: Vector3, bas: Basis) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var cw := 4.2
	var y := minf(3.0, int(wg["rows0"]) * bh - 0.2)
	md.box(dp + out * 1.4 + up * y, Vector3(cw, 0.22, 2.8), Color(0.88, 0.88, 0.86), bas)
	md.box(dp + out * 2.8 + up * y, Vector3(cw + 0.04, 0.4, 0.06), Color(0.2, 0.3, 0.5) if not X.has("redcross") else Color(0.85, 0.1, 0.1), bas)
	for sx: float in [-1.0, 1.0]:
		md.cyl(dp + dir * sx * (cw * 0.5 - 0.2) + out * 2.6, 0.08, 0.08, y, 8, Color(0.75, 0.75, 0.75))
	if sign_txt != "":
		_letters(md, dp + out * 2.84 + up * y, dir, bas, cw * 0.8, 0.26, Color(0.2, 0.3, 0.5))

func _marquee(wg: Dictionary, dp: Vector3, dir: Vector3, out: Vector3, bas: Basis, mw: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var y := 3.4
	md.box(dp + out * 0.9 + up * y, Vector3(mw, 0.9, 1.8), Color(0.15, 0.12, 0.12), bas)
	md.box(dp + out * 1.81 + up * y, Vector3(mw - 0.2, 0.6, 0.02), Color(0.95, 0.93, 0.85), bas)
	_letters(md, dp + out * 1.83 + up * y, dir, bas, mw * 0.8, 0.4, Color(0.95, 0.93, 0.85))
	for i in int(mw / 0.3):
		for e in [y + 0.42, y - 0.42]:
			md.box(dp + dir * (-mw * 0.5 + 0.15 + i * 0.3) + out * 1.82 + up * e, Vector3(0.08, 0.08, 0.04), Color(1.0, 0.85, 0.4), bas)
	var bp := dp + out * 0.5 + up * (y + 3.2)
	md.box(bp, Vector3(0.2, 4.4, 1.0), Color(0.75, 0.12, 0.1), bas)
	for j in 6:
		md.box(bp + dir * 0.11 + up * (1.6 - j * 0.65), Vector3(0.02, 0.45, 0.6), Color(0.98, 0.95, 0.85), bas)

func _arcade(wg: Dictionary, la: Vector3, dir: Vector3, out: Vector3, bas: Basis, L: float, dep: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var off := out * (t2 * 0.5)
	var h := minf(int(wg["rows0"]) * bh, 3.4)
	var n := maxi(2, int(L / 3.0))
	var span := L / n
	var cc := trim
	md.box(la + dir * (L * 0.5) + off + out * (dep * 0.5) + up * 0.08, Vector3(L, 0.16, dep), Color(0.62, 0.6, 0.56), bas)
	for i in n + 1:
		var pp := la + dir * (i * span) + off + out * (dep - 0.25)
		md.cyl(pp + up * 0.16, 0.2, 0.17, h - 0.4, 10, cc)
		md.box(pp + up * (h - 0.2), Vector3(0.45, 0.2, 0.45), cc, bas)
	for i in n:
		var c := la + dir * ((i + 0.5) * span) + off + out * (dep - 0.25) + up * (h - 0.1)
		var r := span * 0.5 - 0.15
		for j in 7:
			var a0 := PI * j / 7.0
			var a1 := PI * (j + 1) / 7.0
			_beam(md, c + dir * (cos(a0) * r) + up * (sin(a0) * r * 0.7), c + dir * (cos(a1) * r) + up * (sin(a1) * r * 0.7), 0.3, 0.16, cc)
	md.box(la + dir * (L * 0.5) + off + out * (dep * 0.5) + up * (h + r_top(span)), Vector3(L + 0.2, 0.4, dep + 0.1), (wg["rgb"] as Color), bas)
	var mr := _mr(wg, rtex if rtex not in ["conc", "mud"] else "lead")
	var a := la + off + up * (h + r_top(span) + 0.7)
	var b := a + dir * L
	mr.quad(a, b, b + out * (dep + 0.3) - up * 0.55, a + out * (dep + 0.3) - up * 0.55, rcol, (out + up * 2.0).normalized())

func r_top(span: float) -> float:
	return (span * 0.5 - 0.15) * 0.7 + 0.15

func _gallery(wg: Dictionary, la: Vector3, dir: Vector3, out: Vector3, bas: Basis, L: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var off := out * (t2 * 0.5)
	var h := 2.6
	md.box(la + dir * (L * 0.5) + off + out * 1.0 + up * 0.08, Vector3(L, 0.16, 2.0), Color(0.6, 0.58, 0.55), bas)
	md.box(la + dir * (L * 0.5) + off + out * 1.05 + up * h, Vector3(L + 0.2, 0.18, 2.2), Color(0.9, 0.9, 0.88), bas)
	md.box(la + dir * (L * 0.5) + off + out * 2.12 + up * (h - 0.05), Vector3(L + 0.2, 0.3, 0.06), (wg["rgb"] as Color).darkened(0.2), bas)
	var n := int(L / 3.0)
	for i in n + 1:
		md.box(la + dir * (i * L / maxf(n, 1)) + off + out * 1.95 + up * (h * 0.5), Vector3(0.12, h, 0.12), Color(0.85, 0.85, 0.83), bas)

func _extstair(wg: Dictionary, la: Vector3, dir: Vector3, out: Vector3, bas: Basis, L: float, H: float) -> void:
	var md: MB = wg["md"]
	var up := Vector3.UP
	var off := out * (t2 * 0.5)
	var n := int(H / 0.19)
	var run := minf(n * 0.27, L - 1.6)
	var tr := run / n
	var s0 := L - 0.6 - run
	var sc := Color(0.62, 0.6, 0.57) if fac != "timber" else Color(0.42, 0.3, 0.2)
	for i in n:
		var s := s0 + (i + 0.5) * tr
		var y := (i + 1) * H / n
		md.box(la + dir * s + off + out * 0.5 + up * (y - 0.1), Vector3(tr + 0.02, 0.2, 0.95), sc, bas)
	# taşıyıcı duvar (merdiven altı) + sahanlık
	md.box(la + dir * (L - 0.45) + off + out * 0.5 + up * (H - 0.1), Vector3(0.9, 0.2, 0.95), sc, bas)
	var a := la + dir * s0 + off + out * 0.95 + up * 1.0
	var b := la + dir * (L - 0.4) + off + out * 0.95 + up * (H + 1.0)
	_beam(md, a, b - up * 0.0 - dir * 0.4, 0.05, 0.05, Color(0.2, 0.2, 0.2))
	for i in 5:
		var p := a.lerp(b - dir * 0.4, i / 4.0)
		md.box(p - up * 0.5, Vector3(0.04, 1.0, 0.04), Color(0.2, 0.2, 0.2), bas)

# cumba: üst katta dışa taşan kapalı çıkma (üç yüzü pencereli, altında payandalar)
func _cumba(wg: Dictionary, base: Vector3, dir: Vector3, out: Vector3, bas: Basis, cw: float, y0: float, fh: float) -> void:
	var md: MB = wg["md"]
	var mgl: MB = wg["mdg"]
	var up := Vector3.UP
	var dep := 0.75
	var rgb: Color = wg["rgb"]
	var c := base + out * (dep * 0.5)
	md.box(c + up * (y0 + 0.1), Vector3(cw, 0.2, dep), Color(0.4, 0.28, 0.18), bas)
	md.box(c + up * (y0 + fh - 0.05), Vector3(cw + 0.2, 0.14, dep + 0.2), Color(0.4, 0.28, 0.18), bas)
	# alt dolgu + camlar + dikmeler
	md.box(c + out * (dep * 0.5 - 0.04) + up * (y0 + 0.55), Vector3(cw, 0.7, 0.08), rgb, bas)
	mgl.box(c + out * (dep * 0.5 - 0.06) + up * (y0 + 0.9 + (fh - 1.1) * 0.5), Vector3(cw - 0.1, fh - 1.1, 0.03), Color(0.2, 0.24, 0.28), bas)
	for sx: float in [-1.0, 1.0]:
		md.box(c + dir * sx * (cw * 0.5 - 0.04) + up * (y0 + 0.55), Vector3(0.08, 0.7, dep), rgb, bas)
		mgl.box(c + dir * sx * (cw * 0.5 - 0.06) + up * (y0 + 0.9 + (fh - 1.1) * 0.5), Vector3(0.03, fh - 1.1, dep - 0.1), Color(0.2, 0.24, 0.28), bas)
	var nm := int(cw / 0.7)
	for i in nm + 1:
		md.box(c + dir * (-cw * 0.5 + i * cw / nm) + out * (dep * 0.5) + up * (y0 + 0.9 + (fh - 1.1) * 0.5), Vector3(0.07, fh - 1.1, 0.06), Color(0.95, 0.94, 0.9), bas)
	for sx: float in [-1.0, 1.0]:
		md.box(c + dir * sx * (cw * 0.5) + out * (dep * 0.5) + up * (y0 + 0.9 + (fh - 1.1) * 0.5), Vector3(0.07, fh - 1.1, 0.07), Color(0.95, 0.94, 0.9), bas)
	# payandalar
	for sx: float in [-0.4, 0.0, 0.4]:
		_beam(md, base + dir * (sx * cw) + up * (y0 - 0.7), base + dir * (sx * cw) + out * (dep - 0.05) + up * (y0 + 0.02), 0.1, 0.1, Color(0.36, 0.24, 0.15))

# ============================================================ çatılar
func _rp(cx: float, cz: float, top: float, p: Vector2, l: float, az: bool) -> Vector3:
	return Vector3(cx + p.x, top + p.y, cz + l) if az else Vector3(cx + l, top + p.y, cz + p.x)

func _roof(wg: Dictionary) -> void:
	var rf := String(wg["rf"])
	var r: Rect2 = wg["r"]
	var az: bool = r.size.y > r.size.x
	if wg.get("main", false) and not wg.get("cell", false):
		az = bool(A.get("gf", false)) or r.size.y > r.size.x * 1.6
	if wg.get("garage", false):
		az = false
	wg["az"] = az
	var hw := (r.size.x if az else r.size.y) * 0.5
	var pit: float = float(A.get("pit", 0.0))
	var ov := 0.38 + (0.45 if X.has("wide_eave") else 0.0) + (0.12 if snow else 0.0)
	if not wg.get("main", false) and pit > 0.0 and rf in ["gable", "hip"]:
		pit = minf(pit, 0.8)
	match rf:
		"flat", "dome":
			# kubbe üretilmez (oyunda dini yapıya benzeyen kubbe yok — kullanıcı kuralı); eski kayıtlar düz çatı olur
			_r_flat(wg)
		"gable":
			var p := (pit if pit > 0.0 else (0.62 if not snow else 0.85))
			_r_ext(wg, [Vector2(-hw, 0), Vector2(0, hw * p), Vector2(hw, 0)], az, ov, ov, rtex)
		"gambrel":
			_r_ext(wg, [Vector2(-hw, 0), Vector2(-hw * 0.6, hw * 0.82), Vector2(0, hw * 1.08), Vector2(hw * 0.6, hw * 0.82), Vector2(hw, 0)], az, ov, ov, rtex)
		"shed":
			wg["az"] = false
			var hz := r.size.y * 0.5
			_r_ext(wg, [Vector2(-hz, hz * 2.0 * (pit if pit > 0.0 else 0.2)), Vector2(hz, 0)], false, ov, ov, rtex)
		"barrel", "vault", "sera":
			var k := pit if pit > 0.0 else (0.42 if rf == "barrel" else 0.6)
			if rf == "sera":
				k = 0.95
			var prof: Array = []
			for i in 13:
				var t := PI - PI * i / 12.0
				prof.append(Vector2(hw * cos(t), hw * k * sin(t)))
			_r_ext(wg, prof, az, 0.15 if rf != "sera" else 0.0, 0.2 if rf != "sera" else 0.0, rtex if rf != "sera" else "glass", rf != "sera")
			if rf == "sera":
				_sera_frame(wg, prof, az)
		"hip":
			_r_hip(wg, pit if pit > 0.0 else (0.55 if not snow else 0.75), ov)
		"mansard":
			_r_mansard(wg)
		"saw":
			_r_saw(wg)
		"cone":
			_r_cone(wg)
	_roof_details(wg)

func _r_ext(wg: Dictionary, prof: Array, az: bool, ov: float, ovl: float, tex: String, infill := true) -> void:
	var r: Rect2 = wg["r"]
	var cx := r.get_center().x
	var cz := r.get_center().y
	var top: float = wg["top"]
	var hl := (r.size.y if az else r.size.x) * 0.5
	var mr: MB = _mr(wg, tex)
	var mx: MB = wg["mx"]
	var pts: Array = prof.duplicate()
	var n := pts.size()
	if ov > 0.0 and n >= 2:
		var e0: Vector2 = (pts[0] - pts[1]).normalized()
		pts[0] = pts[0] + e0 * (ov / maxf(absf(e0.x), 0.4))
		var e1: Vector2 = (pts[n - 1] - pts[n - 2]).normalized()
		pts[n - 1] = pts[n - 1] + e1 * (ov / maxf(absf(e1.x), 0.4))
	var l0 := -hl - ovl
	var l1 := hl + ovl
	var fasc := Color(0.28, 0.22, 0.18) if fac not in ["metal", "panel"] else Color(0.55, 0.55, 0.56)
	if X.has("trim_white"):
		fasc = Color(0.94, 0.92, 0.86)
	var rc := rcol if tex != "glass" else Color(0.82, 0.88, 0.88)
	for i in n - 1:
		var a2: Vector2 = pts[i]
		var b2: Vector2 = pts[i + 1]
		var e := b2 - a2
		var n2 := Vector2(-e.y, e.x).normalized()
		var nn := Vector3(n2.x, n2.y, 0) if az else Vector3(0, n2.y, n2.x)
		mr.quad(_rp(cx, cz, top, a2, l0, az), _rp(cx, cz, top, b2, l0, az), _rp(cx, cz, top, b2, l1, az), _rp(cx, cz, top, a2, l1, az), rc, nn)
		if tex != "glass" and n < 8:
			for l: float in [l0, l1]:
				_beam(mx, _rp(cx, cz, top, a2, l, az), _rp(cx, cz, top, b2, l, az), 0.07, 0.2, fasc)
	# alın dolgusu (kalkan duvar)
	if infill:
		var poly: Array = prof.duplicate()
		if (poly[0] as Vector2).y > 0.01:
			poly.push_front(Vector2((poly[0] as Vector2).x, 0))
		if (poly[poly.size() - 1] as Vector2).y > 0.01:
			poly.append(Vector2((poly[poly.size() - 1] as Vector2).x, 0))
		var cen := Vector2.ZERO
		for q in poly:
			cen += q
		cen /= poly.size()
		var gc: Color = (wg["rgb"] as Color).darkened(0.04)
		if fac == "stone" or fac == "brick":
			gc = (wg["rgb"] as Color).darkened(0.08)
		for sg: float in [-1.0, 1.0]:
			var l: float = sg * (hl + t2 * 0.5)
			var nrm := Vector3(0, 0, sg) if az else Vector3(sg, 0, 0)
			for i in poly.size() - 1:
				mx.tri(_rp(cx, cz, top, cen, l, az), _rp(cx, cz, top, poly[i], l, az), _rp(cx, cz, top, poly[i + 1], l, az), gc, nrm)
			if fac in ["timber", "log"] or X.has("tframe"):
				# kalkanda dikey tahta / kirişler
				var hw := absf((prof[0] as Vector2).x)
				for j in 7:
					var u := -hw + (j + 0.5) * hw * 2.0 / 7.0
					var yh := _prof_y(prof, u)
					if yh > 0.2:
						_beam(mx, _rp(cx, cz, top, Vector2(u, 0.05), l + sg * 0.02, az), _rp(cx, cz, top, Vector2(u, yh - 0.05), l + sg * 0.02, az), 0.03, 0.07, gc.darkened(0.25))
	# mahya
	for i in range(1, n - 1):
		var p: Vector2 = prof[i]
		if p.y >= (prof[i - 1] as Vector2).y and p.y >= (prof[i + 1] as Vector2).y and tex != "glass":
			mx.cyl_between(_rp(cx, cz, top, p + Vector2(0, 0.03), l0, az), _rp(cx, cz, top, p + Vector2(0, 0.03), l1, az), 0.1, 0.1, 6, rcol.darkened(0.3))
	# oluk
	if tex not in ["glass"] and n < 8:
		for e in [pts[0], pts[n - 1]]:
			var ep: Vector2 = e
			if ep.y < 0.3:
				mx.cyl_between(_rp(cx, cz, top, ep + Vector2(0, -0.08), l0, az), _rp(cx, cz, top, ep + Vector2(0, -0.08), l1, az), 0.07, 0.07, 6, Color(0.55, 0.55, 0.55))
	wg["prof"] = prof

func _prof_y(prof: Array, u: float) -> float:
	for i in prof.size() - 1:
		var a: Vector2 = prof[i]
		var b: Vector2 = prof[i + 1]
		if (u >= a.x and u <= b.x) or (u <= a.x and u >= b.x):
			var t := (u - a.x) / (b.x - a.x) if absf(b.x - a.x) > 1e-4 else 0.0
			return lerpf(a.y, b.y, t)
	return 0.0

# çatı yüksekliği (yerel x, z) → baca/panel yerleşimi
func _roof_h(wg: Dictionary, x: float, z: float) -> float:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	if wg.has("prof"):
		var az: bool = wg["az"]
		var u := (x - r.get_center().x) if az else (z - r.get_center().y)
		return top + _prof_y(wg["prof"], u)
	if wg.has("hipd"):
		var hd: Array = wg["hipd"]
		var dx := maxf(0.0, absf(x - float(hd[0])) - float(hd[2]))
		var dz := maxf(0.0, absf(z - float(hd[1])) - float(hd[3]))
		return float(hd[4]) - maxf(dx, dz) * float(hd[5])
	return top + 0.2

func _frustum(mb: MB, lo: Rect2, y0: float, hi: Rect2, y1: float, col: Color, ctr: Vector3) -> void:
	var lc := [Vector3(lo.position.x, y0, lo.position.y), Vector3(lo.end.x, y0, lo.position.y), Vector3(lo.end.x, y0, lo.end.y), Vector3(lo.position.x, y0, lo.end.y)]
	var hc := [Vector3(hi.position.x, y1, hi.position.y), Vector3(hi.end.x, y1, hi.position.y), Vector3(hi.end.x, y1, hi.end.y), Vector3(hi.position.x, y1, hi.end.y)]
	for i in 4:
		var j := (i + 1) % 4
		var a: Vector3 = lc[i]
		var b: Vector3 = lc[j]
		var c: Vector3 = hc[j]
		var d: Vector3 = hc[i]
		var fc := (a + b + c + d) * 0.25
		var n := (b - a).cross(d - a)
		if n.length_squared() < 1e-8:
			n = (b - a).cross(c - a)
		var od := Vector3(fc.x - ctr.x, 0.0, fc.z - ctr.z)
		if n.dot(od + Vector3.UP * 0.01) < 0.0:
			n = -n
		mb.quad(a, b, c, d, col, n.normalized())

func _inset(r: Rect2, k: float) -> Rect2:
	var s := Vector2(maxf(r.size.x - 2.0 * k, 0.0), maxf(r.size.y - 2.0 * k, 0.0))
	return Rect2(r.get_center() - s * 0.5, s)

func _r_hip(wg: Dictionary, pit: float, ov: float) -> void:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var ctr := Vector3(r.get_center().x, 0, r.get_center().y)
	var E := r.grow(ov)
	var ye := top - ov * pit
	var ins := minf(E.size.x, E.size.y) * 0.5
	var R := _inset(E, ins)
	var yr := ye + ins * pit
	_frustum(_mr(wg, rtex), E, ye, R, yr, rcol, ctr)
	var mx: MB = wg["mx"]
	var rc := rcol.darkened(0.3)
	var ec := [Vector3(E.position.x, ye, E.position.y), Vector3(E.end.x, ye, E.position.y), Vector3(E.end.x, ye, E.end.y), Vector3(E.position.x, ye, E.end.y)]
	var hc := [Vector3(R.position.x, yr, R.position.y), Vector3(R.end.x, yr, R.position.y), Vector3(R.end.x, yr, R.end.y), Vector3(R.position.x, yr, R.end.y)]
	for i in 4:
		mx.cyl_between(ec[i] + Vector3.UP * 0.04, hc[i] + Vector3.UP * 0.04, 0.08, 0.08, 5, rc)
		_beam(mx, ec[i] - Vector3.UP * 0.06, ec[(i + 1) % 4] - Vector3.UP * 0.06, 0.06, 0.16, Color(0.28, 0.22, 0.18))
		mx.cyl_between(ec[i] - Vector3.UP * 0.14, ec[(i + 1) % 4] - Vector3.UP * 0.14, 0.06, 0.06, 5, Color(0.55, 0.55, 0.55))
	mx.cyl_between(hc[0] + Vector3.UP * 0.04, hc[2] + Vector3.UP * 0.04, 0.09, 0.09, 5, rc)
	wg["hipd"] = [ctr.x, ctr.z, R.size.x * 0.5, R.size.y * 0.5, yr, pit]

func _r_mansard(wg: Dictionary) -> void:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var ctr := Vector3(r.get_center().x, 0, r.get_center().y)
	var E := r.grow(0.18)
	var M := _inset(E, 0.75)
	var ym := top + 2.5
	var mr := _mr(wg, rtex)
	_frustum(mr, E, top, M, ym, rcol, ctr)
	var ins := minf(M.size.x, M.size.y) * 0.5
	var R := _inset(M, ins)
	_frustum(mr, M, ym, R, ym + ins * 0.25, rcol.lightened(0.05), ctr)
	var mx: MB = wg["mx"]
	_beam(mx, Vector3(M.position.x, ym, M.position.y), Vector3(M.end.x, ym, M.position.y), 0.08, 0.1, trim)
	_beam(mx, Vector3(M.position.x, ym, M.end.y), Vector3(M.end.x, ym, M.end.y), 0.08, 0.1, trim)
	_beam(mx, Vector3(E.position.x, top + 0.05, E.end.y), Vector3(E.end.x, top + 0.05, E.end.y), 0.12, 0.22, trim)
	_beam(mx, Vector3(E.position.x, top + 0.05, E.position.y), Vector3(E.end.x, top + 0.05, E.position.y), 0.12, 0.22, trim)
	# çatı pencereleri (ön ve arka dik yüzde)
	for sg: float in [1.0, -1.0]:
		var n := maxi(1, int(r.size.x / 2.6))
		for i in n:
			var x := r.position.x + (i + 0.5) * r.size.x / n
			var z: float = (E.end.y - 0.3) if sg > 0 else (E.position.y + 0.3)
			_dormer(wg, Vector3(x, top + 0.25, z), Vector3(0, 0, sg), 1.0, 1.3)
	wg["hipd"] = [ctr.x, ctr.z, R.size.x * 0.5, R.size.y * 0.5, ym + ins * 0.25, 0.25]

func _dormer(wg: Dictionary, p: Vector3, out: Vector3, w: float, h: float) -> void:
	var mx: MB = wg["mx"]
	var mxg: MB = wg["mxg"]
	var dir := Vector3(out.z, 0, -out.x)
	var bas := _basis(dir, out)
	var rgb: Color = wg["rgb"]
	mx.box(p + Vector3.UP * (h * 0.5) - out * 0.35, Vector3(w + 0.2, h, 0.9), rgb, bas)
	mxg.box(p + Vector3.UP * (h * 0.5 + 0.05) + out * 0.11, Vector3(w - 0.3, h - 0.45, 0.03), Color(0.18, 0.22, 0.26), bas)
	mx.box(p + Vector3.UP * (h * 0.5 + 0.05) + out * 0.12, Vector3(0.05, h - 0.45, 0.04), frame_c, bas)
	mx.box(p + Vector3.UP * 0.2 + out * 0.14, Vector3(w - 0.2, 0.06, 0.12), trim, bas)
	var pr := PackedVector2Array([Vector2(-w * 0.5 - 0.2, h), Vector2(w * 0.5 + 0.2, h), Vector2(0, h + w * 0.45)])
	mx.prism(pr, 1.1, rcol, p - out * 0.35, bas, rgb)

func _r_saw(wg: Dictionary) -> void:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var mr := _mr(wg, rtex)
	var mx: MB = wg["mx"]
	var mxg: MB = wg["mxg"]
	var n := maxi(2, int(round(r.size.y / 4.5)))
	var tw := r.size.y / n
	var th := 2.0
	var x0 := r.position.x - 0.25
	var x1 := r.end.x + 0.25
	var rgb: Color = wg["rgb"]
	for i in n:
		var za := r.position.y + i * tw
		var zb := za + tw
		mxg.quad(Vector3(x0, top, za), Vector3(x1, top, za), Vector3(x1, top + th, za), Vector3(x0, top + th, za), Color(0.3, 0.36, 0.4), Vector3(0, 0, -1))
		mr.quad(Vector3(x0, top + th, za), Vector3(x1, top + th, za), Vector3(x1, top, zb), Vector3(x0, top, zb), rcol, Vector3(0, tw, th).normalized())
		var nm := int((x1 - x0) / 1.2)
		for k in nm + 1:
			mx.box(Vector3(x0 + k * (x1 - x0) / nm, top + th * 0.5, za - 0.02), Vector3(0.06, th, 0.05), Color(0.22, 0.24, 0.26))
		mx.box(Vector3((x0 + x1) * 0.5, top + th * 0.5, za - 0.02), Vector3(x1 - x0, 0.06, 0.05), Color(0.22, 0.24, 0.26))
		mx.box(Vector3((x0 + x1) * 0.5, top + th + 0.05, za), Vector3(x1 - x0, 0.12, 0.2), rcol.darkened(0.3))
		for xe: float in [r.position.x - 0.21, r.end.x + 0.21]:
			mx.tri(Vector3(xe, top, za), Vector3(xe, top + th, za), Vector3(xe, top, zb), rgb.darkened(0.06), Vector3(signf(xe - r.get_center().x), 0, 0))
		mx.cyl_between(Vector3(x0, top + 0.05, zb), Vector3(x1, top + 0.05, zb), 0.1, 0.1, 6, Color(0.5, 0.5, 0.5))

func _sera_frame(wg: Dictionary, prof: Array, az: bool) -> void:
	var r: Rect2 = wg["r"]
	var mx: MB = wg["mx"]
	var hl := (r.size.y if az else r.size.x) * 0.5
	var cx := r.get_center().x
	var cz := r.get_center().y
	var top: float = wg["top"]
	var nl := int(hl * 2.0 / 1.6)
	for k in nl + 1:
		var l := -hl + k * hl * 2.0 / nl
		for i in prof.size() - 1:
			_beam(mx, _rp(cx, cz, top, prof[i], l, az) + Vector3.UP * 0.02, _rp(cx, cz, top, prof[i + 1], l, az) + Vector3.UP * 0.02, 0.04, 0.04, Color(0.85, 0.85, 0.85))
	# uç plastik perdeler
	for sg: float in [-1.0, 1.0]:
		var l: float = sg * hl
		for i in prof.size() - 1:
			(_mr(wg, "glass")).tri(_rp(cx, cz, top, Vector2(0, 0), l, az), _rp(cx, cz, top, prof[i], l, az), _rp(cx, cz, top, prof[i + 1], l, az), Color(0.82, 0.88, 0.88), Vector3(0, 0, sg) if az else Vector3(sg, 0, 0))

# düz dam: döşeme, korkuluk duvarı (parapet), harpuşta
func _r_flat(wg: Dictionary, ph := -1.0) -> void:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var cx := r.get_center().x
	var cz := r.get_center().y
	var E := r.grow(t2 * 0.5)
	var tex := rtex if rtex in ["conc", "mud"] else "conc"
	if fac == "adobe" or X.has("earthroof"):
		tex = "mud"
	var mr := _mr(wg, tex)
	var mx: MB = wg["mx"]
	var rgb: Color = wg["rgb"]
	var sc := Color(0.6, 0.58, 0.55) if tex == "conc" else rgb.darkened(0.1)
	mr.box(Vector3(cx, top + 0.08, cz), Vector3(E.size.x, 0.16, E.size.y), sc)
	if tex == "conc":
		# membran ek yerleri, yamalar, süzgeç
		var ns := int(E.size.x / 2.4)
		for i in range(1, ns):
			mx.box(Vector3(E.position.x + i * E.size.x / ns, top + 0.165, cz), Vector3(0.05, 0.01, E.size.y - 0.6), sc.darkened(0.3))
		for i in 3:
			mx.box(Vector3(rng.randf_range(E.position.x + 1.0, E.end.x - 1.0), top + 0.167, rng.randf_range(E.position.y + 1.0, E.end.y - 1.0)), Vector3(rng.randf_range(0.8, 2.4), 0.01, rng.randf_range(0.8, 2.0)), sc.darkened(rng.randf_range(0.12, 0.25)))
		mx.cyl(Vector3(E.end.x - 0.6, top + 0.16, E.end.y - 0.6), 0.12, 0.12, 0.02, 8, Color(0.15, 0.15, 0.15))
	if ph < 0.0:
		ph = 0.55
		if fac == "adobe" or X.has("cren"):
			ph = 0.8
		if String(A.get("k", "")) == "sanayi":
			ph = 0.35
	var pt := 0.24
	var segs := [[Vector3(cx, 0, E.position.y + pt * 0.5), Vector3(E.size.x, 0, pt)], [Vector3(cx, 0, E.end.y - pt * 0.5), Vector3(E.size.x, 0, pt)],
		[Vector3(E.position.x + pt * 0.5, 0, cz), Vector3(pt, 0, E.size.y)], [Vector3(E.end.x - pt * 0.5, 0, cz), Vector3(pt, 0, E.size.y)]]
	for s in segs:
		var p: Vector3 = s[0]
		var sz: Vector3 = s[1]
		mx.box(p + Vector3.UP * (top + ph * 0.5), Vector3(sz.x, ph, sz.z), rgb.darkened(0.03))
		if fac not in ["adobe"]:
			mx.box(p + Vector3.UP * (top + ph + 0.04), Vector3(sz.x + (0.12 if sz.x > sz.z else 0.0), 0.08, sz.z + (0.12 if sz.z > sz.x else 0.0)), trim)
	if X.has("cren") or X.has("cren_low"):
		var mh := 0.5 if X.has("cren") else 0.3
		for s in segs:
			var p: Vector3 = s[0]
			var sz: Vector3 = s[1]
			var along := sz.x > sz.z
			var L := maxf(sz.x, sz.z)
			var n := int(L / 0.9)
			for i in n:
				if i % 2 == 1:
					continue
				var o := -L * 0.5 + (i + 0.5) * L / n
				var q := p + (Vector3(o, 0, 0) if along else Vector3(0, 0, o)) + Vector3.UP * (top + ph + mh * 0.5)
				if X.has("cren"):
					mx.box(q, Vector3(L / n if along else pt, mh, pt if along else L / n), rgb)
				else:
					mx.sphere(q - Vector3.UP * mh * 0.3, Vector3(0.22, mh, 0.22), 6, 4, rgb)
	if fac == "adobe" or X.has("viga"):
		# çörten (dam suyu oluğu)
		for i in 3:
			var x := r.position.x + (i + 0.5) * r.size.x / 3.0
			mx.box(Vector3(x, top + 0.15, E.end.y + 0.3), Vector3(0.14, 0.12, 0.7), Color(0.4, 0.3, 0.2))
	if X.has("earthroof"):
		for i in int(r.size.x * r.size.y * 0.6):
			var q := Vector3(rng.randf_range(E.position.x + 0.3, E.end.x - 0.3), top + 0.18, rng.randf_range(E.position.y + 0.3, E.end.y - 0.3))
			mx.sphere(q, Vector3(0.18, 0.1, 0.18), 5, 3, _pick([Color(0.36, 0.42, 0.2), Color(0.48, 0.44, 0.26), Color(0.3, 0.36, 0.18)]))

func _lathe(mb: MB, c: Vector3, prof: Array, segs: int, col: Color, half := 0.0) -> void:
	var n := prof.size()
	var nrm: Array = []
	for i in n:
		var a: Vector2 = prof[maxi(i - 1, 0)]
		var b: Vector2 = prof[mini(i + 1, n - 1)]
		var e := b - a
		nrm.append(Vector2(e.y, -e.x).normalized())
	var a_max := TAU if half == 0.0 else PI
	for s in segs:
		var a0 := a_max * s / segs + (0.0 if half == 0.0 else (PI if half > 0.0 else 0.0))
		var a1 := a_max * (s + 1) / segs + (0.0 if half == 0.0 else (PI if half > 0.0 else 0.0))
		var d0 := Vector3(cos(a0), 0, sin(a0))
		var d1 := Vector3(cos(a1), 0, sin(a1))
		for i in n - 1:
			var p: Vector2 = prof[i]
			var q: Vector2 = prof[i + 1]
			var np: Vector2 = nrm[i]
			var nq: Vector2 = nrm[i + 1]
			var v00 := c + d0 * p.x + Vector3.UP * p.y
			var v01 := c + d1 * p.x + Vector3.UP * p.y
			var v10 := c + d0 * q.x + Vector3.UP * q.y
			var v11 := c + d1 * q.x + Vector3.UP * q.y
			var n00 := d0 * np.x + Vector3.UP * np.y
			var n01 := d1 * np.x + Vector3.UP * np.y
			var n10 := d0 * nq.x + Vector3.UP * nq.y
			var n11 := d1 * nq.x + Vector3.UP * nq.y
			if p.x > 0.001:
				mb.tri_s(v00, v01, v11, n00, n01, n11, col)
			if q.x > 0.001 or p.x > 0.001:
				mb.tri_s(v00, v11, v10, n00, n11, n10, col)

# Harran konik evi: kare hücre üstünde kerpiç sıralı konik çatı
func _r_cone(wg: Dictionary) -> void:
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var c := Vector3(r.get_center().x, top, r.get_center().y)
	var mx: MB = wg["mx"]
	var rgb: Color = wg["rgb"]
	var mr := _mr(wg, rtex if rtex != "clay" else "mud")
	var R := minf(r.size.x, r.size.y) * 0.5 + 0.1
	mx.box(c + Vector3.UP * 0.1, Vector3(r.size.x + 0.3, 0.2, r.size.y + 0.3), rgb.darkened(0.05))
	var prof: Array = []
	var H := R * (1.55 if wg.get("cell", false) else 1.1)
	var n := 12
	for i in n + 1:
		var t := float(i) / n
		var rr := R * (1.0 - t) * (1.0 + 0.25 * sin(t * PI)) * (1.03 if i % 2 == 0 else 0.97)
		prof.append(Vector2(maxf(rr, 0.0), H * t))
	_lathe(mr, c + Vector3.UP * 0.2, prof, 14, rcol if wg.get("cell", false) else rcol)
	if X.has("conevents"):
		mx.box(c + Vector3.UP * (0.2 + H * 0.82) + Vector3(0, 0, R * 0.3), Vector3(0.25, 0.25, 0.3), Color(0.1, 0.08, 0.06))
	if wg.has("ring") and X.has("sails"):
		_sails(mx, c + Vector3.UP * (H * 0.55) + Vector3(0, 0, R * 0.9), R)

func _sails(mx: MB, hub: Vector3, R: float) -> void:
	var wood := Color(0.42, 0.3, 0.2)
	var cloth := Color(0.9, 0.88, 0.8)
	mx.cyl_between(hub - Vector3(0, 0, 1.0), hub + Vector3(0, 0, 0.4), 0.18, 0.18, 8, wood)
	var a0 := rng.randf() * TAU
	for i in 4:
		var a := a0 + i * PI * 0.5
		var d := Vector3(cos(a), sin(a), 0)
		var s := Vector3(-d.y, d.x, 0)
		var L := R * 2.4
		_beam(mx, hub + Vector3(0, 0, 0.3), hub + Vector3(0, 0, 0.3) + d * L, 0.12, 0.12, wood)
		var p0 := hub + Vector3(0, 0, 0.35) + d * 0.8
		var p1 := hub + Vector3(0, 0, 0.35) + d * L
		mx.quad(p0, p1, p1 + s * 0.9, p0 + s * 0.9, cloth, Vector3(0, 0, 1))
		mx.quad(p0, p1, p1 + s * 0.9, p0 + s * 0.9, cloth.darkened(0.2), Vector3(0, 0, -1))
		for k in 5:
			var q := p0.lerp(p1, (k + 0.5) / 5.0)
			_beam(mx, q, q + s * 0.9, 0.03, 0.03, wood)

# ------------------------------------------------------------ çatı eşyaları
var _occ: Array = []

func _spot(E: Rect2, rad: float) -> Vector2:
	for t in 14:
		var p := Vector2(rng.randf_range(E.position.x + rad, E.end.x - rad), rng.randf_range(E.position.y + rad, E.end.y - rad))
		var ok := true
		for o in _occ:
			if p.distance_to(o[0]) < rad + float(o[1]):
				ok = false
				break
		if ok:
			_occ.append([p, rad])
			return p
	return Vector2.INF

func _chimney(mx: MB, p: Vector3, h: float, w: float, col: Color) -> void:
	mx.box(p + Vector3.UP * (h * 0.5), Vector3(w, h, w), col)
	mx.box(p + Vector3.UP * (h - 0.25), Vector3(w + 0.1, 0.1, w + 0.1), col.darkened(0.15))
	mx.box(p + Vector3.UP * (h + 0.04), Vector3(w + 0.12, 0.08, w + 0.12), Color(0.95, 0.95, 0.97) if snow else col.darkened(0.25))
	mx.cyl(p + Vector3.UP * (h + 0.08), w * 0.18, w * 0.16, 0.3, 6, Color(0.55, 0.3, 0.2))
	if w > 0.6:
		mx.cyl(p + Vector3(w * 0.25, h + 0.08, 0), w * 0.15, w * 0.13, 0.25, 6, Color(0.55, 0.3, 0.2))

# güneş enerjili termosifon: eğik panel + yatay depo + ayaklar
func _solar(mx: MB, mxg: MB, p: Vector3, yaw: float, tilt: float) -> void:
	var b := Basis(Vector3.UP, yaw)
	var tb := b * Basis(Vector3.RIGHT, -tilt)
	for i in 2:
		var pp := p + b * Vector3(-0.55 + i * 1.1, 0.0, 0.0) + tb * Vector3(0, 0.0, 0) + Vector3.UP * 0.5
		mxg.box(pp, Vector3(1.0, 0.04, 1.9), Color(0.12, 0.16, 0.3), tb)
		mx.box(pp - tb.y * 0.03, Vector3(1.06, 0.04, 1.96), Color(0.75, 0.75, 0.76), tb)
		for k in 6:
			mx.box(pp + tb.y * 0.022 + tb * Vector3(-0.45 + k * 0.18, 0, 0), Vector3(0.015, 0.01, 1.85), Color(0.6, 0.62, 0.65), tb)
	var tp := p + Vector3.UP * (0.5 + sin(tilt) * 0.95 + 0.3) + b * Vector3(0, 0, -cos(tilt) * 0.95)
	mx.cyl_between(tp - b.x * 1.05, tp + b.x * 1.05, 0.27, 0.27, 10, Color(0.88, 0.88, 0.86))
	for sx: float in [-0.9, 0.9]:
		_beam(mx, p + b * Vector3(sx, 0, -0.9), tp + b.x * sx - Vector3.UP * 0.2, 0.04, 0.04, Color(0.6, 0.6, 0.62))
		_beam(mx, p + b * Vector3(sx, 0, 0.9), p + b * Vector3(sx, 0, 0.9) + Vector3.UP * 0.5, 0.04, 0.04, Color(0.6, 0.6, 0.62))

func _tank(mx: MB, p: Vector3) -> void:
	var col: Color = _pick([Color(0.12, 0.12, 0.13), Color(0.78, 0.8, 0.82), Color(0.2, 0.32, 0.52), Color(0.85, 0.85, 0.82)])
	for sx: float in [-0.45, 0.45]:
		for sz: float in [-0.45, 0.45]:
			mx.box(p + Vector3(sx, 0.35, sz), Vector3(0.08, 0.7, 0.08), Color(0.45, 0.45, 0.46))
	mx.box(p + Vector3.UP * 0.72, Vector3(1.1, 0.06, 1.1), Color(0.45, 0.45, 0.46))
	mx.cyl(p + Vector3.UP * 0.75, 0.55, 0.55, 1.2, 12, col)
	mx.cyl(p + Vector3.UP * 1.95, 0.55, 0.18, 0.14, 12, col.darkened(0.08))
	mx.cyl(p + Vector3(0.0, 0.75, 0.56), 0.04, 0.04, 0.6, 5, Color(0.6, 0.6, 0.6), Basis(Vector3.RIGHT, PI * 0.5))

func _condenser(mx: MB, p: Vector3, big: bool) -> void:
	var s := 1.0 if not big else 1.8
	mx.box(p + Vector3.UP * (0.45 * s), Vector3(1.0 * s, 0.9 * s, 0.7 * s), Color(0.82, 0.83, 0.82))
	mx.cyl(p + Vector3.UP * (0.9 * s), 0.3 * s, 0.3 * s, 0.03, 12, Color(0.25, 0.25, 0.27))
	if big:
		mx.cyl(p + Vector3(0.9, 1.62, 0), 0.5, 0.5, 0.03, 12, Color(0.25, 0.25, 0.27))
		mx.box(p + Vector3(0.9, 0.81, 0), Vector3(1.8, 1.62, 1.26), Color(0.82, 0.83, 0.82))

func _antenna(mx: MB, p: Vector3, h: float) -> void:
	var c := Color(0.55, 0.55, 0.58)
	mx.cyl(p, 0.03, 0.025, h, 5, c)
	for k in 4:
		mx.box(p + Vector3.UP * (h - 0.1 - k * 0.25), Vector3(1.0 - k * 0.15, 0.025, 0.025), c)
	mx.box(p + Vector3.UP * (h - 0.45), Vector3(0.025, 0.025, 0.9), c)

func _flagpole(mb: MB, p: Vector3, h: float, yaw: float) -> void:
	mb.cyl(p, 0.06, 0.04, h, 6, Color(0.82, 0.82, 0.84))
	mb.sphere(p + Vector3.UP * h, Vector3(0.07, 0.07, 0.07), 6, 4, Color(0.85, 0.7, 0.3))
	var b := Basis(Vector3.UP, yaw)
	var fp := p + Vector3.UP * (h - 0.55) + b * Vector3(0.85, 0, 0)
	for i in 4:
		var q := fp + b * Vector3(-0.6 + i * 0.4, 0, sin(i * 1.3) * 0.08)
		mb.box(q, Vector3(0.41, 1.0, 0.02), Color(0.82, 0.08, 0.1), b * Basis(Vector3.UP, sin(i * 1.3 + 0.6) * 0.25))
	mb.sphere(fp + b * Vector3(-0.5, 0, 0.05), Vector3(0.18, 0.18, 0.02), 8, 4, Color(0.96, 0.96, 0.96), b)

func _roof_details(wg: Dictionary) -> void:
	var rf := String(wg["rf"])
	var r: Rect2 = wg["r"]
	var top: float = wg["top"]
	var mx: MB = wg["mx"]
	var mxg: MB = wg["mxg"]
	var cx := r.get_center().x
	var cz := r.get_center().y
	var main: bool = wg.get("main", false)
	var rgb: Color = wg["rgb"]
	var flat := rf in ["flat", "dome", "lantern"]
	_occ = []
	if wg.get("tower", false):
		if rf == "flat":
			for sx: float in [-1.0, 1.0]:
				mx.box(Vector3(cx + sx * r.size.x * 0.3, top + 1.0, cz), Vector3(0.1, 1.6, 0.1), Color(0.3, 0.3, 0.3))
			mx.box(Vector3(cx, top + 1.7, cz), Vector3(r.size.x * 0.7, 0.1, 0.1), Color(0.3, 0.3, 0.3))
			if X.has("siren"):
				mx.cyl(Vector3(cx, top + 0.5, cz), 0.25, 0.35, 0.5, 8, Color(0.75, 0.75, 0.72))
		return
	if wg.get("garage", false) or wg.get("open", false):
		return
	if flat:
		var E := _inset(r, 0.7)
		if X.has("lift") and main:
			var lp := Vector3(cx + r.size.x * 0.15, top, cz - r.size.y * 0.1)
			mx.box(lp + Vector3.UP * 1.3, Vector3(2.4, 2.6, 2.8), rgb.darkened(0.05))
			mx.box(lp + Vector3.UP * 2.66, Vector3(2.7, 0.12, 3.1), trim)
			mx.box(lp + Vector3(0, 1.0, 1.41), Vector3(0.9, 2.0, 0.04), Color(0.4, 0.42, 0.45))
			_occ.append([Vector2(lp.x, lp.z), 2.0])
		if X.has("helipad") and main:
			var hp := Vector3(cx, top + 0.17, cz)
			var hr := minf(r.size.x, r.size.y) * 0.36
			mx.cyl(hp, hr, hr, 0.02, 24, Color(0.3, 0.32, 0.3))
			mx.cyl(hp + Vector3.UP * 0.005, hr - 0.15, hr - 0.15, 0.02, 24, Color(0.95, 0.95, 0.9))
			mx.cyl(hp + Vector3.UP * 0.01, hr - 0.4, hr - 0.4, 0.02, 24, Color(0.3, 0.32, 0.3))
			mx.box(hp + Vector3(-hr * 0.3, 0.04, 0), Vector3(0.35, 0.02, hr * 0.9), Color(0.95, 0.95, 0.9))
			mx.box(hp + Vector3(hr * 0.3, 0.04, 0), Vector3(0.35, 0.02, hr * 0.9), Color(0.95, 0.95, 0.9))
			mx.box(hp + Vector3(0, 0.04, 0), Vector3(hr * 0.6, 0.02, 0.35), Color(0.95, 0.95, 0.9))
			_occ.append([Vector2(cx, cz), hr])
		if X.has("roofsign") and main:
			var sw := r.size.x * 0.7
			var sp := Vector3(cx, top + 2.2, r.end.y - 0.6)
			for sx: float in [-0.4, 0.0, 0.4]:
				mx.box(sp + Vector3(sx * sw, -1.0, -0.3), Vector3(0.08, 1.8, 0.08), Color(0.3, 0.3, 0.3))
			var scol := _sign_col()
			mx.box(sp, Vector3(sw, 1.3, 0.12), scol)
			_letters(mx, sp + Vector3(0, 0, 0.07), Vector3.RIGHT, Basis(), sw * 0.86, 0.85, scol)
		if X.has("latticemast") and main:
			_lattice(mx, Vector3(cx - r.size.x * 0.2, top + 0.16, cz), 14.0)
			_occ.append([Vector2(cx - r.size.x * 0.2, cz), 1.6])
		if X.has("clocktower") and main:
			_clocktower(wg, Vector3(cx, top + 0.16, cz), 2.6)
			_occ.append([Vector2(cx, cz), 2.2])
		if X.has("badgir"):
			var bp := Vector3(cx + r.size.x * 0.25, top + 0.16, cz - r.size.y * 0.2)
			mx.box(bp + Vector3.UP * 1.7, Vector3(1.6, 3.4, 1.6), rgb)
			for k in 4:
				var a := PI * 0.5 * k
				var d := Vector3(cos(a), 0, sin(a))
				for j in 3:
					mx.box(bp + d * 0.81 + Vector3.UP * 2.6 + Vector3(-d.z, 0, d.x) * (-0.45 + j * 0.45), Vector3(0.22 if absf(d.x) < 0.5 else 0.04, 1.2, 0.04 if absf(d.x) < 0.5 else 0.22), Color(0.08, 0.07, 0.06))
			mx.box(bp + Vector3.UP * 3.45, Vector3(1.8, 0.14, 1.8), trim)
			_occ.append([Vector2(bp.x, bp.z), 1.4])
		if X.has("roofshade"):
			var sp := Vector3(cx - r.size.x * 0.15, top + 0.16, cz)
			for sx: float in [-1.2, 1.2]:
				for sz: float in [-1.2, 1.2]:
					mx.box(sp + Vector3(sx, 1.1, sz), Vector3(0.1, 2.2, 0.1), Color(0.42, 0.3, 0.2))
			mx.box(sp + Vector3.UP * 2.25, Vector3(2.8, 0.04, 2.8), Color(0.9, 0.86, 0.72))
			mx.box(sp + Vector3(0, 0.25, 0), Vector3(1.2, 0.5, 0.6), Color(0.6, 0.4, 0.25))
			_occ.append([Vector2(sp.x, sp.z), 1.8])
		if X.has("roofac"):
			for i in 4:
				var q := _spot(E, 1.5)
				if q != Vector2.INF:
					_condenser(mx, Vector3(q.x, top + 0.16, q.y), true)
		if String(A.get("k", "")) == "sanayi" or X.has("roofac"):
			for i in 3:
				var q := _spot(E, 1.0)
				if q != Vector2.INF:
					mxg.box(Vector3(q.x, top + 0.4, q.y), Vector3(1.4, 0.4, 1.4), Color(0.6, 0.7, 0.75))
					mx.box(Vector3(q.x, top + 0.3, q.y), Vector3(1.55, 0.3, 1.55), Color(0.7, 0.7, 0.7))
		if X.has("solar"):
			for i in rng.randi_range(1, 3):
				var q := _spot(E, 1.3)
				if q != Vector2.INF:
					_solar(mx, mxg, Vector3(q.x, top + 0.16, q.y), 0.0, 0.6)
		if X.has("tank"):
			for i in rng.randi_range(1, 3):
				var q := _spot(E, 0.8)
				if q != Vector2.INF:
					_tank(mx, Vector3(q.x, top + 0.16, q.y))
		if X.has("ac"):
			for i in rng.randi_range(1, 3):
				var q := _spot(E, 0.7)
				if q != Vector2.INF:
					_condenser(mx, Vector3(q.x, top + 0.16, q.y), false)
		if X.has("dish"):
			for i in rng.randi_range(1, 3):
				var q := _spot(E, 0.6)
				if q != Vector2.INF:
					_dish(mx, Vector3(q.x, top + 0.75, q.y), Basis(Vector3.UP, rng.randf_range(-0.6, 0.6)), 0.42)
		if X.has("ant"):
			for i in rng.randi_range(1, 3):
				var q := _spot(E, 0.4)
				if q != Vector2.INF:
					_antenna(mx, Vector3(q.x, top + 0.16, q.y), rng.randf_range(1.8, 3.0))
		if X.has("mast"):
			var q := _spot(E, 0.5)
			if q != Vector2.INF:
				mx.cyl(Vector3(q.x, top + 0.16, q.y), 0.08, 0.05, 7.0, 6, Color(0.6, 0.6, 0.62))
				for k in 3:
					mx.box(Vector3(q.x, top + 4.5 + k * 0.9, q.y), Vector3(0.9, 0.05, 0.05), Color(0.6, 0.6, 0.62))
		if X.has("laundry"):
			var q := _spot(E, 1.4)
			if q != Vector2.INF:
				var lp := Vector3(q.x, top + 0.16, q.y)
				for sx: float in [-1.3, 1.3]:
					mx.box(lp + Vector3(sx, 0.85, 0), Vector3(0.06, 1.7, 0.06), Color(0.5, 0.5, 0.5))
				_beam(mx, lp + Vector3(-1.3, 1.6, 0), lp + Vector3(1.3, 1.6, 0), 0.015, 0.015, Color(0.9, 0.9, 0.9))
				for k in 5:
					mx.box(lp + Vector3(-1.0 + k * 0.5, 1.3, 0), Vector3(0.36, 0.55, 0.015), _pick([Color(0.95, 0.95, 0.95), Color(0.3, 0.45, 0.75), Color(0.85, 0.3, 0.3), Color(0.95, 0.8, 0.3), Color(0.4, 0.6, 0.4)]))
		if X.has("sandbag_top"):
			for i in 10:
				mx.sphere(Vector3(r.position.x + 0.3 + i * (r.size.x - 0.6) / 9.0, top + 0.75, r.end.y), Vector3(0.32, 0.14, 0.2), 6, 3, Color(0.62, 0.56, 0.4))
		if X.has("siren"):
			mx.cyl(Vector3(cx - r.size.x * 0.3, top + 0.16, cz), 0.06, 0.06, 2.5, 6, Color(0.5, 0.5, 0.5))
			mx.cyl(Vector3(cx - r.size.x * 0.3, top + 2.6, cz), 0.3, 0.42, 0.5, 8, Color(0.85, 0.85, 0.8))
		if X.has("flags") and main and not X.has("roofsign"):
			for i in 3:
				_flagpole(mx, Vector3(cx + (i - 1) * 1.6, top + 0.6, r.end.y - 0.3), 3.6, 0.0)
		if X.has("lights") and main:
			for i in 12:
				var x := r.position.x + i * r.size.x / 11.0
				mx.sphere(Vector3(x, top + 0.8 - absf(sin(i * 0.9)) * 0.3, r.end.y + 0.25), Vector3(0.07, 0.07, 0.07), 4, 3, Color(1.0, 0.9, 0.5))
		return
	# eğik çatı
	var E := _inset(r, 0.9)
	var az: bool = wg.get("az", false)
	if X.has("chim") or X.has("bigchim") or X.has("stovepipe"):
		var n := 1 if (r.size.x * r.size.y < 60.0 or X.has("bigchim")) else 2
		for i in n:
			var q := _spot(E, 0.6)
			if q == Vector2.INF:
				continue
			var y := _roof_h(wg, q.x, q.y)
			if X.has("stovepipe") and not X.has("chim"):
				mx.cyl(Vector3(q.x, y - 0.2, q.y), 0.1, 0.1, 1.4, 8, Color(0.3, 0.3, 0.32))
				mx.cyl(Vector3(q.x, y + 1.2, q.y), 0.2, 0.05, 0.18, 8, Color(0.3, 0.3, 0.32))
			else:
				var cc := Color(0.6, 0.3, 0.22) if fac != "stone" else rgb.darkened(0.08)
				_chimney(mx, Vector3(q.x, y - 0.4, q.y), (1.6 if not X.has("bigchim") else 2.6), 0.55 if not X.has("bigchim") else 0.95, cc)
	if X.has("chim_stone") and main:
		var gx: float = r.position.x - t2 * 0.5 - 0.35 if not az else cx
		var gz: float = cz if not az else r.position.y - t2 * 0.5 - 0.35
		var ry := _roof_h(wg, cx, cz)
		var md: MB = wg["md"]
		md.box(Vector3(gx, ry * 0.5 + 0.3, gz), Vector3(0.9 if az else 0.7, ry + 0.6, 0.7 if az else 0.9), Color(0.58, 0.56, 0.52, 1.0))
		md.box(Vector3(gx, ry + 0.66, gz), Vector3(1.0, 0.12, 1.0), Color(0.95, 0.95, 0.97) if snow else Color(0.45, 0.43, 0.4))
	if X.has("solar") and main and _roof_h(wg, cx, r.end.y - 1.2) > top + 0.3:
		var q := Vector2(cx + rng.randf_range(-1.0, 1.0), r.end.y - 1.5)
		var y := _roof_h(wg, q.x, q.y)
		_solar(mx, mxg, Vector3(q.x, y - 0.45, q.y), 0.0, 0.55)
	if X.has("dish"):
		var q := _spot(E, 0.5)
		if q != Vector2.INF:
			_dish(mx, Vector3(q.x, _roof_h(wg, q.x, q.y) + 0.4, q.y), Basis(Vector3.UP, rng.randf_range(-0.5, 0.5)), 0.4)
	if X.has("ant") or (main and rng.randf() < 0.3 and rf in ["gable", "hip"]):
		_antenna(mx, Vector3(cx + rng.randf_range(-1, 1), _roof_h(wg, cx, cz) - 0.1, cz), 2.2)
	if X.has("cupola") and main:
		var y := _roof_h(wg, cx, cz)
		var cp := Vector3(cx, y - 0.4, cz)
		mx.box(cp + Vector3.UP * 0.8, Vector3(1.3, 1.6, 1.3), Color(0.94, 0.92, 0.86) if X.has("trim_white") else rgb)
		for k in 4:
			var a := PI * 0.5 * k
			var d := Vector3(cos(a), 0, sin(a))
			for j in 4:
				mx.box(cp + d * 0.66 + Vector3.UP * (0.5 + j * 0.22), Vector3(0.9 if absf(d.z) > 0.5 else 0.04, 0.05, 0.04 if absf(d.z) > 0.5 else 0.9), Color(0.25, 0.2, 0.16), Basis())
		_frustum(_mr(wg, rtex), Rect2(cx - 0.85, cz - 0.85, 1.7, 1.7), cp.y + 1.6, Rect2(cx, cz, 0, 0), cp.y + 2.5, rcol, Vector3(cx, 0, cz))
		mx.cyl(cp + Vector3.UP * 2.5, 0.025, 0.025, 1.0, 4, Color(0.2, 0.2, 0.2))
		mx.box(cp + Vector3.UP * 3.2, Vector3(0.7, 0.2, 0.03), Color(0.2, 0.2, 0.2))
	if X.has("ridgevent"):
		var y := _roof_h(wg, cx, cz)
		var L := (r.size.y if az else r.size.x) * 0.8
		mx.box(Vector3(cx, y + 0.25, cz), Vector3(0.9 if az else L, 0.4, L if az else 0.9), rcol.darkened(0.15))
		mx.box(Vector3(cx, y + 0.5, cz), Vector3(1.3 if az else L + 0.2, 0.08, L + 0.2 if az else 1.3), rcol.darkened(0.05))
	if X.has("dormer") and rf in ["gable", "hip"]:
		var n := maxi(1, int(r.size.x / 3.2))
		for i in n:
			var x := r.position.x + (i + 0.5) * r.size.x / n
			var z := r.end.y - 0.9
			_dormer(wg, Vector3(x, _roof_h(wg, x, z) - 0.3, z + 0.3), Vector3(0, 0, 1), 1.0, 1.25)
	if X.has("roofstones"):
		for i in 9:
			var q := Vector2(rng.randf_range(r.position.x, r.end.x), rng.randf_range(r.position.y, r.end.y))
			mx.sphere(Vector3(q.x, _roof_h(wg, q.x, q.y) + 0.08, q.y), Vector3(0.22, 0.12, 0.18), 5, 3, Color(0.55, 0.53, 0.5), Basis(), false, 0.2, rng)
		for i in 3:
			_beam(mx, Vector3(r.position.x, _roof_h(wg, cx, r.position.y + 0.8 + i * 1.4) + 0.06, r.position.y + 0.8 + i * 1.4), Vector3(r.end.x, _roof_h(wg, cx, r.position.y + 0.8 + i * 1.4) + 0.06, r.position.y + 0.8 + i * 1.4), 0.1, 0.08, Color(0.4, 0.3, 0.22))
	# ön kalkan: samanlık kapısı, gül pencere, çan duvarı (kalkan önde ise)
	if main and az and wg.has("prof"):
		var gz := r.end.y + t2 * 0.5 + 0.02
		var ry := _roof_h(wg, cx, cz)
		var md: MB = wg["md"]
		if X.has("loft"):
			var ly := top + 0.3
			md.box(Vector3(cx, ly + 0.7, gz), Vector3(1.4, 1.4, 0.05), Color(0.94, 0.92, 0.86) if X.has("trim_white") else Color(0.3, 0.22, 0.15))
			md.box(Vector3(cx, ly + 0.7, gz + 0.03), Vector3(1.2, 1.2, 0.03), (wg["rgb"] as Color).darkened(0.15))
			_beam(md, Vector3(cx - 0.6, ly + 0.1, gz + 0.04), Vector3(cx + 0.6, ly + 1.3, gz + 0.04), 0.03, 0.1, Color(0.94, 0.92, 0.86))
			_beam(md, Vector3(cx + 0.6, ly + 0.1, gz + 0.04), Vector3(cx - 0.6, ly + 1.3, gz + 0.04), 0.03, 0.1, Color(0.94, 0.92, 0.86))
			_beam(md, Vector3(cx, ry - 0.3, gz - 0.3), Vector3(cx, ry - 0.3, gz + 0.9), 0.14, 0.14, Color(0.35, 0.25, 0.16))
			md.cyl(Vector3(cx, ry - 1.4, gz + 0.85), 0.012, 0.012, 1.0, 4, Color(0.2, 0.2, 0.2))
	if X.has("clocktower") and main:
		_clocktower(wg, Vector3(cx, _roof_h(wg, cx, cz) - 0.6, cz), 2.4)

func _lattice(mx: MB, p: Vector3, h: float) -> void:
	var c := Color(0.75, 0.75, 0.76)
	var n := int(h / 1.2)
	for i in n:
		var s0 := lerpf(1.2, 0.35, float(i) / n)
		var s1 := lerpf(1.2, 0.35, float(i + 1) / n)
		var y0 := i * h / n
		var y1 := (i + 1) * h / n
		for k in 4:
			var a := PI * 0.5 * k + PI * 0.25
			var b := a + PI * 0.5
			var p0 := p + Vector3(cos(a) * s0, y0, sin(a) * s0)
			var p1 := p + Vector3(cos(a) * s1, y1, sin(a) * s1)
			var q1 := p + Vector3(cos(b) * s1, y1, sin(b) * s1)
			_beam(mx, p0, p1, 0.06, 0.06, c)
			_beam(mx, p0, q1, 0.03, 0.03, c)
	for k in 3:
		var a := TAU * k / 3.0
		mx.box(p + Vector3(cos(a) * 0.5, h - 1.0, sin(a) * 0.5), Vector3(0.3, 1.4, 0.15), Color(0.9, 0.9, 0.9), Basis(Vector3.UP, -a))
	mx.cyl(p + Vector3.UP * h, 0.03, 0.02, 2.0, 4, c)
	_dish(mx, p + Vector3(0.6, h - 3.0, 0.3), Basis(Vector3.UP, 0.4), 0.6)

func _clocktower(wg: Dictionary, p: Vector3, s: float) -> void:
	var mx: MB = wg["mx"]
	var rgb: Color = wg["rgb"]
	mx.box(p + Vector3.UP * (s * 0.9), Vector3(s, s * 1.8, s), rgb.lightened(0.04))
	mx.box(p + Vector3.UP * (s * 1.8 + 0.1), Vector3(s + 0.3, 0.2, s + 0.3), trim)
	for k in 4:
		var a := PI * 0.5 * k
		var d := Vector3(sin(a), 0, cos(a))
		_clock(mx, p + Vector3.UP * (s * 1.3) + d * (s * 0.5 + 0.02), Basis(Vector3.UP, a), s * 0.3)
	_frustum(_mr(wg, "slate" if rtex in ["conc", "mud"] else rtex), Rect2(p.x - s * 0.6, p.z - s * 0.6, s * 1.2, s * 1.2), p.y + s * 1.9, Rect2(p.x, p.z, 0, 0), p.y + s * 2.9, rcol.darkened(0.1), p)
	mx.cyl(p + Vector3.UP * (s * 2.9), 0.03, 0.03, 0.8, 4, Color(0.85, 0.7, 0.3))

# ============================================================ halka kanat (silo, tank, sanayi bacası, köşe kulesi, değirmen)
func _ring_wing(wg: Dictionary) -> void:
	var n: int = wg["ring"]
	var rad: float = wg["rad"]
	var cx: float = wg["cx"]
	var cz: float = wg["cz"]
	var rbh: float = wg["bh"]
	var rows: int = wg["rows"]
	var top: float = wg["top"]
	var rf := String(wg["rf"])
	var lc := Vector3(cx, 0, cz)
	var wc := _w(lc)
	var roof := MeshInstance3D.new()
	var deco := MeshInstance3D.new()
	var hid := B.new_house(wc, Vector2(rad * 2.0, rad * 2.0), top, roof)
	B.houses[hid]["deco"] = deco
	B.houses[hid]["aid"] = aid
	wg["hid"] = hid
	wg["lc"] = lc
	wg["wc"] = wc
	wg["mr"] = {}
	wg["mx"] = MB.new()
	wg["mxg"] = MB.new()
	wg["md"] = MB.new()
	wg["mdg"] = MB.new()
	var th: float = {"silo": 0.35, "tank": 0.3, "stack": 0.55, "fortcap": 0.6}.get(rf, t2)
	var col: Color = wg["col"]
	var typ := Blocks.T_BOX if (fac in ["stone", "adobe"] and rf in ["fortcap", "cone"]) else Blocks.T_CONCRETE
	var d1 := int(ceil(2.0 / rbh)) - 1
	var w0 := maxi(1, int(round(0.85 / rbh)))
	var w1 := maxi(w0, int(floor(1.84 / rbh)) - 1)
	for i in n:
		var a0 := TAU * (i + 0.5) / n
		var a1 := TAU * (i + 1.5) / n
		var p0 := lc + Vector3(cos(a0), 0, sin(a0)) * rad
		var p1 := lc + Vector3(cos(a1), 0, sin(a1)) * rad
		var mid := (p0 + p1) * 0.5
		if wg.get("half", false) and mid.z > cz - 0.05:
			continue
		var out := (mid - lc).normalized()
		var L := p0.distance_to(p1)
		var ops: Array = []
		var front := out.z > 0.9
		if front and rf in ["cone", "fortcap"]:
			ops.append({"s": L * 0.5, "w": minf(1.3, L - 0.12), "k": "door", "f": 0, "r0": 0, "r1": d1, "main": true})
		elif rf == "cone":
			ops.append({"s": L * 0.5, "w": minf(0.8, L - 0.8), "k": "small", "f": 0, "r0": w0, "r1": w1})
			ops.append({"s": L * 0.5, "w": minf(0.8, L - 0.8), "k": "small", "f": 1, "r0": rows / 2, "r1": rows / 2 + 1})
		elif rf == "fortcap" and i % 2 == 0:
			ops.append({"s": L * 0.5, "w": 0.45, "k": "slit", "f": 0, "r0": w0, "r1": w1})
		var gaps: Array = []
		var g0: Array = []
		for o in ops:
			var g := [float(o["s"]) - float(o["w"]) * 0.5, float(o["s"]) + float(o["w"]) * 0.5, int(o["r0"]), int(o["r1"]), false, false]
			gaps.append(g)
			if int(o["f"]) == 0:
				g0.append(g)
		var bl := L / maxf(1.0, round(L / 1.0))
		var wi := B.wall_line(_w(p0), _w(p1), rows, col, Grid.K_HOUSE, {"len": bl, "h": rbh, "t": th, "gaps": gaps, "house": hid, "jit": FAC_JIT.get(fac, 0.02) if rf in ["cone", "fortcap"] else 0.015, "type": typ})
		if rf in ["silo", "tank"]:
			for id in B.walls[wi]["blocks"]:
				B.set_col(id, _rowc(col, B.brow[id], 0.03))
		if not g0.is_empty() and rf in ["cone", "fortcap"]:
			mg._house_slots(hid, _w(p0), _w(p1), g0, wc)
		var dir := (p1 - p0) / L
		for o in ops:
			o["y0"] = int(o["r0"]) * rbh
			o["y1"] = (int(o["r1"]) + 1) * rbh
			_d_open(wg, p0, dir, out, o)
	var mx: MB = wg["mx"]
	var md: MB = wg["md"]
	var rgb: Color = wg["rgb"]
	var ro := rad + th * 0.5
	var up := Vector3.UP
	match rf:
		"silo":
			_mr(wg, "metal").cyl(lc + up * top, ro + 0.1, 0.35, rad * 0.55, 14, Color(0.74, 0.75, 0.77), Basis(), false, false)
			mx.cyl(lc + up * (top + rad * 0.55), 0.38, 0.38, 0.3, 8, Color(0.6, 0.6, 0.62))
			if fac != "conc" and wg["col"].a > 0.15:
				for k in range(1, rows):
					md.cyl(lc + up * (k * rbh - 0.02), ro + 0.02, ro + 0.02, 0.05, 14, (wg["rgb"] as Color).darkened(0.18), Basis(), false)
			var lp := lc + Vector3(ro + 0.25, 0, 0)
			for sz: float in [-0.22, 0.22]:
				md.box(lp + Vector3(0, top * 0.5 + 0.5, sz), Vector3(0.05, top + 1.0, 0.05), Color(0.4, 0.4, 0.42))
			for k in int(top / 0.4):
				md.box(lp + Vector3(0, 0.3 + k * 0.4, 0), Vector3(0.04, 0.04, 0.44), Color(0.4, 0.4, 0.42))
			for k in int((top - 2.5) / 0.9):
				md.cyl(lp + Vector3(0.12, 2.5 + k * 0.9, 0), 0.4, 0.4, 0.04, 8, Color(0.4, 0.4, 0.42), Basis(), false)
		"tank":
			_mr(wg, "lead").cyl(lc + up * top, ro + 0.05, 0.5, rad * 0.2, 18, Color(0.82, 0.83, 0.84), Basis(), false, false)
			for k in 24:
				var a := TAU * k / 24.0
				mx.box(lc + up * (top + 0.5) + Vector3(cos(a), 0, sin(a)) * (ro - 0.1), Vector3(0.04, 1.0, 0.04), Color(0.85, 0.75, 0.15))
			md.cyl(lc + up * (top * 0.62), ro + 0.015, ro + 0.015, 0.5, 18, _pick([Color(0.8, 0.15, 0.12), Color(0.1, 0.35, 0.65), Color(0.15, 0.5, 0.3)]), Basis(), false)
			for k in 18:
				var a := -PI * 0.2 + k * 0.16
				var y := 0.2 + k * (top - 0.2) / 18.0
				md.box(lc + Vector3(cos(a) * (ro + 0.4), y, sin(a) * (ro + 0.4)), Vector3(0.7, 0.06, 0.3), Color(0.45, 0.45, 0.47), Basis(Vector3.UP, -a))
			md.cyl(lc, ro + 0.2, ro + 0.2, 0.25, 18, Color(0.6, 0.58, 0.55))
		"stack":
			# kare beton kaide + konik tuğla gövde (tabanda kalın, tepeye incelir) + kornişli taç, isli açık ağız
			md.box(lc + up * 1.2, Vector3(ro * 2.0 + 1.2, 2.4, ro * 2.0 + 1.2), Color(0.55, 0.54, 0.52))
			var rt := ro * 0.55
			md.cyl(lc + up * 2.4, ro, rt, top - 3.4, n, rgb, Basis(), false)
			var y := 6.0
			while y < top - 3.0:
				var ry := lerpf(ro, rt, (y - 2.4) / (top - 3.4))
				md.cyl(lc + up * y, ry + 0.015, ry + 0.015, 0.12, n, Color(0.2, 0.2, 0.21), Basis(), false)     # demir çember (gömülü)
				y += 5.0
			md.cyl(lc + up * (top - 1.0), rt, rt + 0.35, 0.6, n, rgb.lightened(0.05), Basis(), false)       # korniş
			md.cyl(lc + up * (top - 0.4), rt + 0.35, rt + 0.35, 0.4, n, rgb.darkened(0.1), Basis(), false)
			mx.cyl(lc + up * (top - 1.6), rt + 0.36, rt + 0.36, 1.6, n, Color(0.12, 0.11, 0.1), Basis(), false)  # is
			mx.cyl(lc + up * top, rt + 0.1, rt + 0.1, 0.03, n, Color(0.03, 0.03, 0.03))                          # ağız
			# yan servis merdiveni (kafesli)
			var lad := lc + Vector3(ro + 0.05, 0, 0)
			_beam(md, lad + up * 2.4, lc + Vector3(rt + 0.12, 0, 0) + up * (top - 1.0), 0.05, 0.05, Color(0.3, 0.3, 0.3))
			_beam(md, lad + up * 2.4 + Vector3(0, 0, 0.45), lc + Vector3(rt + 0.12, 0, 0.45) + up * (top - 1.0), 0.05, 0.05, Color(0.3, 0.3, 0.3))
			# binadan bacaya duman kanalı (sanayi bacası olduğu okunur)
			md.box(lc + Vector3(-ro - 1.6, 1.6, 0), Vector3(3.2, 1.2, 1.2), Color(0.5, 0.42, 0.36))
		"fortcap":
			_mr(wg, "mud").cyl(lc + up * top, rad, rad, 0.12, n, rgb.darkened(0.1))
			for k in n:
				var a := TAU * (k + 0.5) / n
				mx.box(lc + up * (top + 0.4) + Vector3(cos(a), 0, sin(a)) * rad, Vector3(0.55, 0.8, 0.55), rgb, Basis(Vector3.UP, -a))
			_beam(mx, lc + up * (top + 0.8), lc + up * (top + 3.0), 0.06, 0.06, Color(0.5, 0.5, 0.5))
		"cone":
			_r_cone(wg)
	var r: Rect2 = wg["r"]
	_commit_wing(wg, roof, deco)
	var _u := r

# ============================================================ açık sundurma (direkli)
func _open_wing(wg: Dictionary) -> void:
	var r: Rect2 = wg["r"]
	var rows: int = wg["rows"]
	var top: float = wg["top"]
	var md: MB = wg["md"]
	var sd := _side(wg, 1)
	B.wall_line(_w(sd[0]), _w(sd[1]), rows, wcol, Grid.K_HOUSE, {"len": blen, "h": bh, "t": t2, "house": wg["hid"], "jit": FAC_JIT.get(fac, 0.04), "type": FAC_T.get(fac, Blocks.T_CONCRETE)})
	var wood := Color(0.4, 0.3, 0.2)
	var np := maxi(2, int(r.size.x / 2.6) + 1)
	for i in np:
		var x := r.position.x + 0.1 + i * (r.size.x - 0.2) / (np - 1)
		for z: float in [r.end.y - 0.1, r.get_center().y]:
			if z == r.get_center().y and i != 0 and i != np - 1:
				continue
			md.box(Vector3(x, top * 0.5, z), Vector3(0.22, top, 0.22), wood)
			G.grid.set_static_rect(_w(Vector3(x, 0, z)), Vector2(0.3, 0.3), ang, top, Grid.K_WALL)
	_beam(md, Vector3(r.position.x, top - 0.1, r.end.y - 0.1), Vector3(r.end.x, top - 0.1, r.end.y - 0.1), 0.2, 0.25, wood)
	if X.has("hay_in"):
		for ix in int(r.size.x / 1.3):
			for iz in 2:
				for iy in rng.randi_range(1, 3):
					md.box(Vector3(r.position.x + 0.8 + ix * 1.3, 0.35 + iy * 0.7, r.position.y + 0.9 + iz * 1.1), Vector3(1.2, 0.68, 1.0), Color(0.82, 0.7, 0.38).darkened(rng.randf_range(0.0, 0.15)))
	if X.has("logs_in"):
		for ix in int(r.size.x / 0.34):
			for iy in int(1.6 / 0.32):
				md.cyl_between(Vector3(r.position.x + 0.3 + ix * 0.34, 0.17 + iy * 0.32, r.position.y + 0.3), Vector3(r.position.x + 0.3 + ix * 0.34, 0.17 + iy * 0.32, r.position.y + 1.4), 0.15, 0.15, 6, Color(0.5, 0.38, 0.26).darkened(rng.randf_range(0.0, 0.2)))
	if X.has("saw"):
		md.box(Vector3(r.get_center().x, 0.45, r.get_center().y), Vector3(4.0, 0.9, 1.0), Color(0.4, 0.4, 0.42))
		md.cyl(Vector3(r.get_center().x, 0.9, r.get_center().y), 0.6, 0.6, 0.03, 16, Color(0.7, 0.72, 0.75), Basis(Vector3.RIGHT, PI * 0.5))
		md.cyl_between(Vector3(r.position.x + 0.6, 1.1, r.get_center().y), Vector3(r.end.x - 0.6, 1.1, r.get_center().y), 0.3, 0.3, 8, Color(0.55, 0.42, 0.28))

# ============================================================ dış süs ve avlu
func _solid(lp: Vector3, sz: Vector2, h: float, k := Grid.K_WALL) -> void:
	G.grid.set_static_rect(_w(lp), sz, ang, h, k)

func _yard_rect(m: float, front_extra := 0.0) -> Rect2:
	return Rect2(-W * 0.5 - m, -D * 0.5 - m, W + 2.0 * m, D + 2.0 * m + front_extra)

# avlu çevresi: blok duvar (kapı önde) ya da çit
# Gelişigüzel: arketipin her örneğinde bahçe duvarı olmaz (%30 yok); olunca bazen yalnız 2-3 kenar (L/U),
# uzun kenarda gedik, duvarda yer yer yıkılma. Ön kenarda (i == 2) kapı her zaman ortada.
func _yard(r: Rect2, kind: String, rows: int, col: Color) -> void:
	if rng.randf() < 0.3:
		return
	var c := [Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x, 0, r.end.y)]
	var gate := 2.0
	var skip := {}
	var shape := rng.randf()
	if shape < 0.2:
		skip[0] = true                                   # U: arka açık
	elif shape < 0.35:
		skip[0] = true                                   # L: arka + bir yan açık
		skip[1 if rng.randf() < 0.5 else 3] = true
	for i in 4:
		if skip.has(i):
			continue
		var a: Vector3 = c[i]
		var b: Vector3 = c[(i + 1) % 4]
		var segs: Array = [[a, b]]
		if i == 2:
			var m := Vector3(0, 0, r.end.y)
			segs = [[a, m + Vector3(gate, 0, 0)], [m - Vector3(gate, 0, 0), b]]
		elif kind == "wall" and a.distance_to(b) > 7.0 and rng.randf() < 0.35:
			# gedik
			var t := rng.randf_range(0.25, 0.75)
			var gw := rng.randf_range(1.0, 2.2) / a.distance_to(b)
			segs = [[a, a.lerp(b, t - gw)], [a.lerp(b, t + gw), b]]
		var ruin := rng.randf_range(0.0, 0.2) if rng.randf() < 0.7 else rng.randf_range(0.3, 0.6)
		for sg in segs:
			var p: Vector3 = sg[0]
			var q: Vector3 = sg[1]
			if p.distance_to(q) < 0.6:
				continue
			match kind:
				"wall":
					B.wall_line(_w(p), _w(q), rows, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.45, "jit": 0.06, "ruin": ruin, "type": Blocks.T_BOX if col.a > 0.85 or col.a == 0.5 else Blocks.T_CONCRETE})
					if ruin < 0.08:          # üst harpuşta yalnız sağlam duvarda (yıkık duvarda havada kalırdı)
						me.box((p + q) * 0.5 + Vector3.UP * (rows * 0.46 + 0.04), Vector3(absf(q.x - p.x) + 0.5, 0.08, absf(q.z - p.z) + 0.5), trim if col.a < 0.85 else _rgb(col).lightened(0.08))
				"picket":
					P_picket(p, q)
				"mesh":
					mg._x_fence(_w(p), _w(q), Color(0.62, 0.64, 0.66))
	if kind == "wall":
		for sx: float in [-1.0, 1.0]:
			me.box(Vector3(sx * (gate + 0.25), rows * 0.46 * 0.5 + 0.3, r.end.y), Vector3(0.6, rows * 0.46 + 0.6, 0.6), _rgb(col).darkened(0.05))
			me.box(Vector3(sx * (gate + 0.25), rows * 0.46 + 0.66, r.end.y), Vector3(0.7, 0.12, 0.7), trim)
		# kapı kanatları (açık)
		for sx: float in [-1.0, 1.0]:
			me.box(Vector3(sx * (gate - 0.2), 0.9, r.end.y + 0.95), Vector3(0.05, 1.7, 1.8), Color(0.25, 0.25, 0.27), Basis(Vector3.UP, sx * 0.15))

func P_picket(p: Vector3, q: Vector3) -> void:
	mg.P.picket(_w(p), _w(q))

func _commit_ext() -> void:
	var m: ArrayMesh = me.commit(Mats.vcs())
	m = meg.commit(Mats.glass(), m)
	for key in mem:
		m = (mem[key] as MB).commit(Mats.roof2(key, snow), m)
	if m.get_surface_count() == 0:
		return
	var mi := MeshInstance3D.new()
	mi.mesh = m
	mi.position = c0
	mi.rotation.y = ang
	B.add_child(mi)

func _mem(key: String) -> MB:
	if not mem.has(key):
		mem[key] = MB.new()
	return mem[key]

func _extras() -> void:
	var hw := W * 0.5
	var hd := D * 0.5
	var up := Vector3.UP
	var fz := hd + t2 * 0.5
	var stonec := Color(0.74, 0.7, 0.62, FAC_A["stone"])
	# avlu duvarları / çitler
	if X.has("cwall"):
		_yard(_yard_rect(3.2, 1.5), "wall", 5, Color(wrgb.r, wrgb.g, wrgb.b, FAC_A["plaster"]) if fac == "plaster" else stonec)
	if X.has("cwall_low"):
		_yard(_yard_rect(2.6, 2.0), "wall", 2, Color(0.95, 0.94, 0.9, FAC_A["plaster"]))
	if X.has("cwall_mud"):
		_yard(_yard_rect(2.8, 3.0), "wall", 4, wcol)
	if X.has("fence") or X.has("picket"):
		_yard(_yard_rect(2.4, 1.8), "picket", 0, wcol)
	if X.has("yard_fence"):
		_yard(_yard_rect(3.0, 3.0), "mesh", 0, wcol)
	if X.has("fence_mesh"):
		_yard(_yard_rect(3.2, 0.0), "mesh", 0, wcol)
	if X.has("courtwall"):
		var cw := clampf(W * 0.3, 4.5, 7.0) if String(A.get("fp", "")) == "U" else 0.0
		var col := wcol
		var z := hd if cw > 0.0 else hd + 6.0
		if cw <= 0.0:
			for sx: float in [-1.0, 1.0]:
				B.wall_line(_w(Vector3(sx * hw, 0, fz)), _w(Vector3(sx * hw, 0, z)), 5, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.45, "jit": 0.05, "type": Blocks.T_BOX})
		var x0 := -hw + cw
		var x1 := hw - cw
		B.wall_line(_w(Vector3(x0, 0, z)), _w(Vector3(-1.6, 0, z)), 5, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.45, "jit": 0.05, "type": Blocks.T_BOX})
		B.wall_line(_w(Vector3(1.6, 0, z)), _w(Vector3(x1, 0, z)), 5, col, Grid.K_WALL, {"len": 0.62, "h": 0.46, "t": 0.45, "jit": 0.05, "type": Blocks.T_BOX})
		_d_arc_gate(Vector3(0, 0, z), 3.2, 3.0)
	if X.has("paddock"):
		var r := Rect2(hw + 1.0, -hd, 8.0, D)
		for e in [[Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y)], [Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y)], [Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x + 2.0, 0, r.end.y)]]:
			P_picket(e[0], e[1])
	if X.has("coop_run"):
		for e in [[Vector3(-hw, 0, fz), Vector3(-hw, 0, fz + 3.0)], [Vector3(-hw, 0, fz + 3.0), Vector3(hw, 0, fz + 3.0)], [Vector3(hw, 0, fz + 3.0), Vector3(hw, 0, fz)]]:
			P_picket(e[0], e[1])
		for i in 6:
			me.sphere(Vector3(rng.randf_range(-hw + 0.5, hw - 0.5), 0.15, fz + rng.randf_range(0.6, 2.6)), Vector3(0.14, 0.14, 0.18), 5, 3, _pick([Color(0.95, 0.95, 0.92), Color(0.6, 0.35, 0.2), Color(0.3, 0.25, 0.2)]))
	# askerî / güvenlik
	if X.has("sandbag"):
		for sx: float in [-1.0, 1.0]:
			B.wall_line(_w(Vector3(sx * 1.2, 0, fz + 2.4)), _w(Vector3(sx * 3.8, 0, fz + 2.4)), 5, Color(0.86, 0.8, 0.64), Grid.K_WALL, {"len": 0.64, "h": 0.17, "t": 0.42, "jit": 0.07, "type": Blocks.T_SANDBAG})
	if X.has("barriers"):
		for sx: float in [-1.0, 1.0]:
			B.wall_line(_w(Vector3(sx * 2.0, 0, fz + 4.0)), _w(Vector3(sx * 5.0, 0, fz + 4.0)), 2, Color(0.78, 0.78, 0.76, 0.0), Grid.K_WALL, {"len": 1.0, "h": 0.42, "t": 0.6, "jit": 0.02, "type": Blocks.T_CONCRETE})
			me.box(Vector3(sx * 3.5, 0.86, fz + 4.0), Vector3(3.0, 0.06, 0.62), Color(0.85, 0.7, 0.1))
	if X.has("sentry"):
		var sp := Vector3(3.2, 0, hd + 4.2)
		me.box(sp + up * 1.2, Vector3(1.3, 2.4, 1.3), Color(0.9, 0.88, 0.82))
		meg.box(sp + up * 1.6 + Vector3(0, 0, 0.66), Vector3(0.9, 0.7, 0.02), Color(0.2, 0.25, 0.3))
		me.box(sp + up * 2.5, Vector3(1.6, 0.15, 1.6), Color(0.55, 0.15, 0.12))
		for k in 3:
			me.box(sp + up * (0.25 + k * 0.6) + Vector3(0.66, 0, 0), Vector3(0.02, 0.3, 1.3), Color(0.82, 0.1, 0.1))
		_solid(sp, Vector2(1.3, 1.3), 2.4)
	if X.has("watchtower"):
		var tp := Vector3(-hw - 2.5, 0, -hd - 2.5)
		var th := 6.0
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_beam(me, tp + Vector3(sx * 1.1, 0, sz * 1.1), tp + Vector3(sx * 0.8, th, sz * 0.8), 0.18, 0.18, Color(0.4, 0.3, 0.2))
		for y: float in [2.0, 4.0]:
			_beam(me, tp + Vector3(-1.0, y, -1.0), tp + Vector3(1.0, y, 1.0), 0.08, 0.08, Color(0.4, 0.3, 0.2))
			_beam(me, tp + Vector3(1.0, y, -1.0), tp + Vector3(-1.0, y, 1.0), 0.08, 0.08, Color(0.4, 0.3, 0.2))
		me.box(tp + up * th, Vector3(2.4, 0.15, 2.4), Color(0.45, 0.34, 0.24))
		for e in [[Vector3(0, 0, 1.15), Vector3(2.4, 1.0, 0.08)], [Vector3(0, 0, -1.15), Vector3(2.4, 1.0, 0.08)], [Vector3(1.15, 0, 0), Vector3(0.08, 1.0, 2.4)], [Vector3(-1.15, 0, 0), Vector3(0.08, 1.0, 2.4)]]:
			me.box(tp + e[0] + up * (th + 0.55), e[1], Color(0.45, 0.34, 0.24))
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				me.box(tp + Vector3(sx * 1.1, th + 1.2, sz * 1.1), Vector3(0.1, 2.4, 0.1), Color(0.4, 0.3, 0.2))
		_mem("metal").quad(tp + Vector3(-1.5, th + 2.4, -1.5), tp + Vector3(1.5, th + 2.4, -1.5), tp + Vector3(1.5, th + 2.9, 1.5), tp + Vector3(-1.5, th + 2.9, 1.5), Color(0.4, 0.42, 0.4), Vector3(0, 1, -0.17).normalized())
		_solid(tp, Vector2(2.4, 2.4), 1.5)
	if X.has("flag") and not X.has("flags"):
		_flagpole(me, Vector3(hw - 1.0, 0, fz + 3.0), 7.5, 0.0)
		me.box(Vector3(hw - 1.0, 0.2, fz + 3.0), Vector3(0.8, 0.4, 0.8), Color(0.75, 0.73, 0.7))
	if X.has("flags") and (String(A.get("rf", "")) != "flat" or X.has("roofsign")):
		for i in 3:
			_flagpole(me, Vector3(-2.0 + i * 2.0, 0, fz + 3.5), 7.0, 0.0)
	# akaryakıt istasyonu: kanopi + pompa + fiyat panosu
	if X.has("gascanopy"):
		mg.P.gas_station(_w(Vector3(0, 0, fz + 6.8)), ang)
	if X.has("pylon"):
		var pp := Vector3(hw + 2.0, 0, fz + 9.0)
		me.box(pp + up * 2.5, Vector3(0.3, 5.0, 0.3), Color(0.8, 0.8, 0.8))
		me.box(pp + up * 5.4, Vector3(1.6, 1.8, 0.3), Color(0.85, 0.15, 0.1))
		for k in 3:
			me.box(pp + up * (4.9 + k * 0.4) + Vector3(0, 0, 0.16), Vector3(1.2, 0.26, 0.02), Color(0.1, 0.1, 0.1))
			for j in 4:
				me.box(pp + up * (4.9 + k * 0.4) + Vector3(-0.42 + j * 0.28, 0, 0.18), Vector3(0.16, 0.18, 0.01), Color(1.0, 0.75, 0.2))
	if X.has("platform"):
		var L := W + 6.0
		var dz := 4.2
		me.box(Vector3(0, 0.25, fz + dz * 0.5), Vector3(L, 0.5, dz), Color(0.6, 0.58, 0.55))
		me.box(Vector3(0, 0.51, fz + dz - 0.3), Vector3(L, 0.02, 0.25), Color(0.95, 0.8, 0.1))
		var n := int(L / 4.0)
		for i in n + 1:
			me.cyl(Vector3(-L * 0.5 + i * L / n, 0.5, fz + dz - 0.9), 0.1, 0.1, 3.0, 8, Color(0.35, 0.36, 0.38))
		_mem("metal").quad(Vector3(-L * 0.5, 3.6, fz), Vector3(L * 0.5, 3.6, fz), Vector3(L * 0.5, 3.2, fz + dz), Vector3(-L * 0.5, 3.2, fz + dz), Color(0.5, 0.52, 0.55), Vector3(0, 1, 0.1).normalized())
		me.box(Vector3(0, 3.15, fz + dz), Vector3(L, 0.3, 0.06), Color(0.3, 0.3, 0.32))
		if String(A.get("sign", "")) == "İSTASYON" and mg.map_id != "big_city":
			var pts := PackedVector3Array([_w(Vector3(-L * 0.5 - 12.0, 0, fz + dz + 2.4)), _w(Vector3(L * 0.5 + 12.0, 0, fz + dz + 2.4))])
			mg.P.railway(pts)
		_solid(Vector3(0, 0, fz + dz * 0.5), Vector2(L, dz), 0.5)
	# oturma / masa / şemsiye / tezgâh
	if X.has("tables") or X.has("umbrellas"):
		for i in rng.randi_range(3, 5):
			var tp := Vector3(rng.randf_range(-hw + 0.8, hw - 0.8), 0, fz + rng.randf_range(1.4, 3.4))
			me.cyl(tp, 0.04, 0.04, 0.72, 5, Color(0.3, 0.3, 0.3))
			me.cyl(tp + up * 0.72, 0.38, 0.38, 0.04, 10, Color(0.9, 0.9, 0.88) if rng.randf() < 0.5 else Color(0.5, 0.36, 0.24))
			for k in rng.randi_range(2, 4):
				var a := TAU * k / 4.0 + rng.randf_range(-0.3, 0.3)
				var cp := tp + Vector3(cos(a), 0, sin(a)) * 0.62
				me.box(cp + up * 0.42, Vector3(0.38, 0.05, 0.38), Color(0.6, 0.45, 0.3) if X.has("tables") else Color(0.85, 0.85, 0.85))
				me.box(cp + up * 0.62 + Vector3(cos(a), 0, sin(a)) * 0.17, Vector3(0.38, 0.4, 0.04), Color(0.6, 0.45, 0.3) if X.has("tables") else Color(0.85, 0.85, 0.85), Basis(Vector3.UP, -a + PI * 0.5))
			if X.has("umbrellas") or rng.randf() < 0.3:
				var uc: Color = _pick([Color(0.85, 0.2, 0.15), Color(0.95, 0.95, 0.92), Color(0.2, 0.5, 0.3), Color(0.95, 0.8, 0.2)])
				me.cyl(tp + up * 0.74, 0.025, 0.025, 1.6, 4, Color(0.6, 0.6, 0.6))
				me.cyl(tp + up * 2.0, 1.2, 0.05, 0.4, 8, uc, Basis(), false, false)
	if X.has("perg"):
		# çardak: direkler, kirişler, asma
		var pw := minf(W * 0.6, 5.0)
		var pc := Vector3(-hw + pw * 0.5 + 0.3, 0, fz + 1.6) if not X.has("tables") else Vector3(0, 0, fz + 2.2)
		var wood := Color(0.42, 0.3, 0.2)
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				me.box(pc + Vector3(sx * (pw * 0.5 - 0.1), 1.2, sz * 1.3), Vector3(0.12, 2.4, 0.12), wood)
		for sz: float in [-1.3, 1.3]:
			me.box(pc + Vector3(0, 2.45, sz), Vector3(pw + 0.4, 0.12, 0.1), wood)
		for i in int(pw / 0.5) + 1:
			me.box(pc + Vector3(-pw * 0.5 + i * 0.5, 2.55, 0), Vector3(0.07, 0.07, 3.0), wood.darkened(0.1))
		for i in 14:
			me.sphere(pc + Vector3(rng.randf_range(-pw * 0.5, pw * 0.5), 2.65, rng.randf_range(-1.4, 1.4)), Vector3(0.45, 0.16, 0.4), 6, 3, Color(0.3, 0.48, 0.2).lightened(rng.randf_range(0.0, 0.15)))
	if X.has("gatehouse"):
		# kervansaray taç kapısı: yükseltilmiş portal, sivri kemer nişi
		var gp := Vector3(0, 0, fz + 0.3)
		var gt: float = float(wings[0]["top"]) + 2.2
		for sx: float in [-1.0, 1.0]:
			me.box(gp + Vector3(sx * 2.4, gt * 0.5, 0), Vector3(1.0, gt, 0.9), wrgb.lightened(0.04))
		me.box(gp + Vector3(0, gt - 0.8, 0), Vector3(5.8, 1.6, 0.9), wrgb.lightened(0.04))
		me.box(gp + Vector3(0, gt + 0.1, 0), Vector3(6.0, 0.25, 1.0), trim)
		for i in 10:
			var a0 := PI * i / 10.0
			var a1 := PI * (i + 1) / 10.0
			_beam(me, gp + Vector3(cos(a0) * 1.95, gt - 1.8 + sin(a0) * 1.4, 0.46), gp + Vector3(cos(a1) * 1.95, gt - 1.8 + sin(a1) * 1.4, 0.46), 0.1, 0.25, trim)
		for i in 9:
			me.box(gp + Vector3(-1.6 + i * 0.4, gt - 1.3, 0.3), Vector3(0.3, 0.3, 0.3), wrgb.darkened(0.08))
	if X.has("benches"):
		for i in 3:
			var bp := Vector3(-hw + 2.0 + i * (W - 4.0) * 0.5, 0, fz + (3.6 if X.has("platform") else 1.6))
			me.box(bp + up * 0.45, Vector3(1.6, 0.06, 0.45), Color(0.45, 0.32, 0.2))
			me.box(bp + up * 0.7 + Vector3(0, 0, -0.2), Vector3(1.6, 0.35, 0.05), Color(0.45, 0.32, 0.2))
			for sx: float in [-0.7, 0.7]:
				me.box(bp + Vector3(sx, 0.22, 0), Vector3(0.06, 0.44, 0.4), Color(0.2, 0.2, 0.2))
	if X.has("bench"):
		me.box(Vector3(-hw + 1.2, 0.45, fz + 1.2), Vector3(1.6, 0.08, 0.45), Color(0.45, 0.32, 0.2))
		me.box(Vector3(-hw + 1.2, 0.22, fz + 1.2), Vector3(1.4, 0.44, 0.3), Color(0.6, 0.58, 0.55))
	if X.has("stalls"):
		var n := maxi(2, int(W / 4.5))
		for i in n:
			var sp := Vector3(-hw + (i + 0.5) * W / n, 0, fz + (3.2 if not X.has("arcade") else 4.0))
			for sx: float in [-0.9, 0.9]:
				for sz: float in [-0.6, 0.6]:
					me.box(sp + Vector3(sx, 1.05, sz), Vector3(0.06, 2.1, 0.06), Color(0.4, 0.3, 0.2))
			me.box(sp + up * 0.85, Vector3(2.0, 0.08, 1.4), Color(0.5, 0.36, 0.24))
			var cc: Array = _pick(AWN)
			me.box(sp + up * 2.15, Vector3(2.2, 0.04, 1.6), cc[0], Basis(Vector3.RIGHT, 0.12))
			for k in 6:
				me.sphere(sp + Vector3(-0.8 + k * 0.32, 0.98, rng.randf_range(-0.4, 0.4)), Vector3(0.14, 0.1, 0.14), 5, 3, _pick([Color(0.85, 0.2, 0.1), Color(0.95, 0.6, 0.1), Color(0.4, 0.65, 0.2), Color(0.9, 0.85, 0.3), Color(0.5, 0.2, 0.4)]))
	if X.has("produce"):
		for i in 4:
			var cp := Vector3(-hw * 0.6 + i * hw * 0.4, 0, fz + 0.8)
			me.box(cp + up * 0.4, Vector3(0.7, 0.3, 0.5), Color(0.55, 0.42, 0.28), Basis(Vector3.RIGHT, 0.3))
			me.box(cp + up * 0.18, Vector3(0.7, 0.36, 0.5), Color(0.5, 0.38, 0.25))
			for k in 5:
				me.sphere(cp + Vector3(-0.25 + k * 0.12, 0.6, rng.randf_range(-0.12, 0.12)), Vector3(0.07, 0.07, 0.07), 5, 3, _pick([Color(0.85, 0.15, 0.1), Color(0.95, 0.6, 0.1), Color(0.4, 0.65, 0.2), Color(0.9, 0.85, 0.3)]))
	if X.has("carts"):
		for i in 5:
			var cp := Vector3(hw - 1.5 - i * 0.45, 0, fz + 2.0)
			me.box(cp + up * 0.6, Vector3(0.45, 0.4, 0.8), Color(0.7, 0.7, 0.72))
			me.box(cp + up * 0.25, Vector3(0.4, 0.05, 0.7), Color(0.6, 0.6, 0.62))
	if X.has("cars"):
		for i in 3:
			mg.P.car(_w(Vector3(-hw + 2.5 + i * (W - 5.0) * 0.5, 0, fz + 3.5)), ang + PI * 0.5, -1)
	if X.has("wreck"):
		var wp := Vector3(hw + 1.6, 0, fz - 1.0)
		me.box(wp + up * 0.45, Vector3(1.7, 0.6, 3.8), Color(0.2, 0.18, 0.16))
		me.box(wp + up * 1.0, Vector3(1.5, 0.5, 1.9), Color(0.15, 0.13, 0.12))
		for sx: float in [-0.85, 0.85]:
			for sz: float in [-1.2, 1.2]:
				me.cyl(wp + Vector3(sx, 0.32, sz), 0.32, 0.32, 0.2, 8, Color(0.08, 0.08, 0.08), Basis(Vector3.FORWARD, PI * 0.5))
		_solid(wp, Vector2(1.8, 3.9), 1.2)
	# yığınlar
	if X.has("crates"):
		for i in 3:
			mg.P.crate(_w(Vector3(hw + 0.9, 0, -hd + 1.0 + i * 1.0)), ang + rng.randf_range(-0.3, 0.3), rng.randf_range(0.8, 1.0))
	if X.has("barrels"):
		for i in rng.randi_range(3, 5):
			mg.P.barrel(_w(Vector3(-hw - 0.8 + rng.randf_range(-0.3, 0.3), 0, -hd + 1.0 + i * 0.7)), _pick([Color(0.55, 0.12, 0.08), Color(0.25, 0.32, 0.2), Color(0.2, 0.3, 0.55)]))
	if X.has("tires"):
		for i in 3:
			var tp := Vector3(hw + 0.9, 0, fz - 1.0 - i * 1.0)
			for k in rng.randi_range(2, 5):
				me.cyl(tp + up * (k * 0.24), 0.36, 0.36, 0.22, 10, Color(0.08, 0.08, 0.09))
	if X.has("sacks"):
		var sp := Vector3(-hw - 0.9, 0, fz - 1.2)
		for k in 7:
			me.sphere(sp + Vector3((k % 3) * 0.55 - 0.5, 0.2 + (k / 3) * 0.3, rng.randf_range(-0.1, 0.1)), Vector3(0.28, 0.17, 0.42), 6, 4, Color(0.82, 0.76, 0.6).darkened(rng.randf_range(0.0, 0.15)))
	if X.has("pallets"):
		for i in 3:
			var pp := Vector3(-hw - 1.2, 0, -hd + 1.5 + i * 1.6)
			for k in rng.randi_range(1, 4):
				me.box(pp + up * (0.07 + k * 0.15), Vector3(1.2, 0.12, 1.0), Color(0.62, 0.5, 0.34))
			if rng.randf() < 0.6:
				me.box(pp + up * 0.95, Vector3(1.1, 0.9, 0.95), _pick([Color(0.6, 0.5, 0.35), Color(0.3, 0.4, 0.6), Color(0.85, 0.85, 0.85)]))
	if X.has("logs"):
		var lp := Vector3(hw + 2.0, 0, -hd + 1.0)
		for iy in 4:
			for iz in 6 - iy:
				me.cyl_between(lp + Vector3(0, 0.3 + iy * 0.5, iz * 0.55 + iy * 0.27), lp + Vector3(5.0, 0.3 + iy * 0.5, iz * 0.55 + iy * 0.27), 0.27, 0.27, 7, Color(0.48, 0.36, 0.24).darkened(rng.randf_range(0.0, 0.2)))
		_solid(lp + Vector3(2.5, 0, 1.6), Vector2(5.0, 3.4), 1.2)
	if X.has("logpile"):
		var lp := Vector3(-hw - t2 * 0.5 - 0.45, 0, -hd + 0.6)
		for iy in 5:
			for iz in int((D - 1.4) / 0.3):
				me.cyl_between(lp + Vector3(-0.35, 0.15 + iy * 0.28, iz * 0.3), lp + Vector3(0.35, 0.15 + iy * 0.28, iz * 0.3), 0.13, 0.13, 6, Color(0.55, 0.42, 0.3).darkened(rng.randf_range(0.0, 0.2)))
		_mem("wood").quad(lp + Vector3(-0.6, 1.7, -0.2), lp + Vector3(-0.6, 1.7, D - 1.0), lp + Vector3(0.5, 2.1, D - 1.0), lp + Vector3(0.5, 2.1, -0.2), Color(0.42, 0.32, 0.24), Vector3(-0.35, 1, 0).normalized())
	if X.has("planks"):
		for i in 2:
			var pp := Vector3(hw + 1.6, 0, -hd + 1.0 + i * 2.2)
			for k in 8:
				me.box(pp + up * (0.1 + k * 0.1), Vector3(1.0, 0.08, 4.0), Color(0.72, 0.58, 0.4).darkened(rng.randf_range(0.0, 0.1)))
	if X.has("hay"):
		for i in rng.randi_range(2, 4):
			mg.P.hay(_w(Vector3(hw + 1.6 + rng.randf_range(0, 2.0), 0, rng.randf_range(-hd, hd))))
	if X.has("brickstacks"):
		for i in 4:
			var bp := Vector3(hw + 1.5 + (i % 2) * 1.6, 0, -hd + 1.0 + (i / 2) * 1.6)
			me.box(bp + up * 0.08, Vector3(1.2, 0.14, 1.2), Color(0.6, 0.5, 0.34))
			me.box(bp + up * 0.62, Vector3(1.1, 0.95, 1.1), Color(0.68, 0.36, 0.26))
			for k in 4:
				me.box(bp + up * (0.25 + k * 0.24) + Vector3(0, 0, 0.56), Vector3(1.1, 0.02, 0.01), Color(0.5, 0.3, 0.22))
	if X.has("gravel"):
		for i in 2:
			var gp := Vector3(-hw - 4.0, 0, -hd + 2.0 + i * 4.5)
			me.cyl(gp, 2.0, 0.2, 1.6, 10, Color(0.55, 0.53, 0.5) if i == 0 else Color(0.72, 0.62, 0.45))
	if X.has("jars"):
		for i in 3:
			var jp := Vector3(hw * 0.5 + i * 0.6, 0, fz + 0.6)
			me.sphere(jp + up * 0.38, Vector3(0.3, 0.4, 0.3), 8, 6, Color(0.7, 0.42, 0.28))
			me.cyl(jp + up * 0.7, 0.13, 0.15, 0.18, 8, Color(0.66, 0.4, 0.27))
	if X.has("anvil"):
		var ap := Vector3(1.6, 0, fz + 1.3)
		me.box(ap + up * 0.3, Vector3(0.4, 0.6, 0.4), Color(0.35, 0.25, 0.18))
		me.box(ap + up * 0.7, Vector3(0.7, 0.2, 0.25), Color(0.15, 0.15, 0.16))
		me.box(Vector3(-1.6, 0.5, fz + 1.2), Vector3(1.2, 1.0, 1.0), Color(0.45, 0.42, 0.4))
		me.cyl(Vector3(-1.6, 1.0, fz + 1.2), 0.3, 0.3, 0.05, 8, Color(0.85, 0.35, 0.1))
	if X.has("tobacco"):
		for i in 3:
			var tp := Vector3(-hw + 1.0 + i * (W - 2.0) * 0.5, 0, fz + 2.5)
			for sx: float in [-1.0, 1.0]:
				me.box(tp + Vector3(sx * 0.9, 0.8, 0), Vector3(0.08, 1.6, 0.08), Color(0.4, 0.3, 0.2))
			for k in 3:
				_beam(me, tp + Vector3(-0.9, 1.5 - k * 0.45, 0), tp + Vector3(0.9, 1.5 - k * 0.45, 0), 0.03, 0.03, Color(0.4, 0.3, 0.2))
				for j in 9:
					me.box(tp + Vector3(-0.8 + j * 0.2, 1.32 - k * 0.45, 0), Vector3(0.12, 0.34, 0.03), Color(0.62, 0.58, 0.25).darkened(rng.randf_range(0.0, 0.25)))
	if X.has("plants"):
		for row in 3:
			for k in int(D / 0.7):
				me.sphere(Vector3(-hw + 1.2 + row * (W - 2.4) * 0.5, 0.3, -hd + 0.5 + k * 0.7), Vector3(0.28, 0.3, 0.28), 6, 4, Color(0.25, 0.48, 0.2).lightened(rng.randf_range(0.0, 0.15)))
	if X.has("milktank"):
		var mp := Vector3(hw + 1.8, 0, 0)
		me.cyl_between(mp + Vector3(0, 1.4, -1.6), mp + Vector3(0, 1.4, 1.6), 0.9, 0.9, 14, Color(0.85, 0.86, 0.88))
		for sz: float in [-1.1, 1.1]:
			me.box(mp + Vector3(0, 0.3, sz), Vector3(1.2, 0.6, 0.15), Color(0.5, 0.5, 0.52))
		_solid(mp, Vector2(1.9, 3.3), 2.3)
	if X.has("dock"):
		me.box(Vector3(0, 0.5, fz + 1.4), Vector3(W * 0.85, 1.0, 2.8), Color(0.62, 0.6, 0.57))
		me.box(Vector3(W * 0.42 + 0.6, 0.25, fz + 1.4), Vector3(1.2, 0.5, 1.6), Color(0.62, 0.6, 0.57))
		me.box(Vector3(0, 1.02, fz + 2.75), Vector3(W * 0.85, 0.06, 0.12), Color(0.95, 0.8, 0.1))
	if X.has("rails"):
		var pts := PackedVector3Array([_w(Vector3(0, 0, -hd - 6.0)), _w(Vector3(0, 0, hd + 14.0))])
		mg.P.railway(pts)
	if X.has("conveyor"):
		var a := Vector3(-hw - 3.0, 0.8, hd - 1.0)
		var b := Vector3(-hw + 0.5, minf(float(wings[0]["top"]), 14.0) - 1.0, 0.0)
		if X.has("silo4") or X.has("silo1"):
			b = Vector3(hw + 2.5, 15.0 if X.has("silo4") else 10.0, -hd + 2.5)
			a = Vector3(-hw - 2.0, 0.8, hd + 2.0)
		_beam(me, a, b, 1.1, 1.2, Color(0.62, 0.6, 0.56))
		for k in 5:
			var p := a.lerp(b, (k + 0.5) / 5.0)
			me.box(Vector3(p.x, p.y * 0.5, p.z), Vector3(0.25, p.y, 0.25), Color(0.5, 0.5, 0.52))
	if X.has("hoist"):
		var t: float = float(wings[0]["top"])
		_beam(me, Vector3(0, t - 0.4, fz - 0.4), Vector3(0, t - 0.4, fz + 1.2), 0.2, 0.2, Color(0.35, 0.3, 0.25))
		me.cyl(Vector3(0, t - 1.6, fz + 1.1), 0.012, 0.012, 1.1, 4, Color(0.2, 0.2, 0.2))
	if X.has("pipes"):
		for i in 2:
			var py := 0.6 + i * 0.45
			me.cyl_between(Vector3(-hw - 1.5, py, fz + 1.0 + i * 0.5), Vector3(hw + 3.0, py, fz + 1.0 + i * 0.5), 0.16, 0.16, 8, Color(0.4, 0.5, 0.6) if i == 0 else Color(0.75, 0.6, 0.15))
		for k in 4:
			me.box(Vector3(-hw + k * W / 3.0, 0.35, fz + 1.25), Vector3(0.12, 0.7, 1.0), Color(0.4, 0.4, 0.42))
		me.cyl(Vector3(hw + 3.0, 0, fz + 1.0), 0.16, 0.16, 2.2, 8, Color(0.4, 0.5, 0.6))
		me.cyl(Vector3(hw + 3.0, 1.2, fz + 1.0), 0.3, 0.3, 0.1, 10, Color(0.75, 0.1, 0.1), Basis(Vector3.RIGHT, PI * 0.5))
	if X.has("warn"):
		for i in 2:
			var wp := Vector3(-hw + 0.8 + i * (W - 1.6), 1.6, fz + 0.02)
			me.box(wp, Vector3(0.5, 0.5, 0.02), Color(0.95, 0.8, 0.1), Basis(Vector3.FORWARD, PI * 0.25))
			me.box(wp + Vector3(0, 0, 0.015), Vector3(0.06, 0.26, 0.01), Color(0.1, 0.1, 0.1))
	if X.has("well") or X.has("wellhead"):
		var wp := Vector3(hw + 2.2, 0, fz + 1.5) if X.has("well") else Vector3(0, 0, fz + 1.8)
		if A.get("k", "") == "kir" and X.has("well"):
			wp = Vector3(0, 0, fz + 2.2)
		me.cyl(wp, 0.75, 0.75, 0.75, 12, Color(0.62, 0.6, 0.55))
		me.cyl(wp + up * 0.74, 0.55, 0.55, 0.02, 12, Color(0.08, 0.1, 0.12))
		if X.has("well"):
			for sx: float in [-0.7, 0.7]:
				me.box(wp + Vector3(sx, 1.2, 0), Vector3(0.12, 1.5, 0.12), Color(0.4, 0.3, 0.2))
			me.cyl_between(wp + Vector3(-0.7, 1.6, 0), wp + Vector3(0.7, 1.6, 0), 0.1, 0.1, 6, Color(0.45, 0.35, 0.25))
			_mem("clay" if rtex == "clay" else "wood").quad(wp + Vector3(-0.9, 2.2, 0), wp + Vector3(0.9, 2.2, 0), wp + Vector3(0.9, 1.75, 0.8), wp + Vector3(-0.9, 1.75, 0.8), rcol, Vector3(0, 1, 0.6).normalized())
			_mem("clay" if rtex == "clay" else "wood").quad(wp + Vector3(-0.9, 2.2, 0), wp + Vector3(0.9, 2.2, 0), wp + Vector3(0.9, 1.75, -0.8), wp + Vector3(-0.9, 1.75, -0.8), rcol, Vector3(0, 1, -0.6).normalized())
			me.cyl(wp + Vector3(0.3, 0.75, 0.3), 0.15, 0.17, 0.3, 8, Color(0.5, 0.4, 0.3))
		_solid(wp, Vector2(1.5, 1.5), 0.75)
	if X.has("cstair"):
		me.box(Vector3(0, 0.01, fz + 1.4), Vector3(1.8, 0.02, 2.4), Color(0.08, 0.07, 0.06))
		for sx: float in [-1.0, 1.0]:
			me.box(Vector3(sx * 1.05, 0.4, fz + 1.4), Vector3(0.3, 0.8, 2.6), Color(0.66, 0.62, 0.55))
	if X.has("wheel"):
		var wp := Vector3(hw + 0.6 + t2 * 0.5, 2.0, 0)
		var wb := Basis(Vector3.FORWARD, PI * 0.5)
		me.cyl(wp - Vector3(0.4, 0, 0), 2.0, 2.0, 0.1, 18, Color(0.36, 0.26, 0.18), wb, false)
		me.cyl(wp + Vector3(0.4, 0, 0), 2.0, 2.0, 0.1, 18, Color(0.36, 0.26, 0.18), wb, false)
		for k in 12:
			var a := TAU * k / 12.0
			var d := Vector3(0, sin(a), cos(a))
			_beam(me, wp + d * 0.3, wp + d * 1.95, 0.08, 0.08, Color(0.4, 0.3, 0.2))
			me.box(wp + d * 1.95, Vector3(0.9, 0.08, 0.5), Color(0.42, 0.32, 0.22), Basis(Vector3.RIGHT, -a))
		me.cyl_between(wp - Vector3(0.8, 0, 0), wp + Vector3(0.6, 0, 0), 0.15, 0.15, 8, Color(0.3, 0.3, 0.3))
		_solid(wp, Vector2(1.0, 4.0), 2.0)
	if X.has("bread"):
		var op := Vector3(-hw - 1.6, 0, -hd + 1.6)
		me.box(op + up * 0.5, Vector3(2.0, 1.0, 2.0), Color(0.75, 0.7, 0.62))
		me.cyl_between(op + Vector3(-1.0, 1.0, 0), op + Vector3(1.0, 1.0, 0), 0.9, 0.9, 12, Color(0.72, 0.62, 0.5))   # tonoz örtü
		me.box(op + Vector3(0, 0.75, 1.0), Vector3(0.5, 0.4, 0.04), Color(0.1, 0.08, 0.06))
		_solid(op, Vector2(2.0, 2.0), 1.8)
	if X.has("pool"):
		var pp := Vector3(0, 0, -hd - 4.0)
		me.box(pp + up * 0.08, Vector3(6.0, 0.16, 3.2), Color(0.9, 0.9, 0.88))
		meg.box(pp + up * 0.12, Vector3(5.4, 0.1, 2.6), Color(0.2, 0.55, 0.7))
	if X.has("roofladder"):
		_beam(me, Vector3(hw + 0.9, 0, 0.3), Vector3(hw + t2 * 0.5 + 0.1, float(wings[0]["top"]) + 0.8, 0.3), 0.06, 0.06, Color(0.42, 0.32, 0.22))
		_beam(me, Vector3(hw + 0.9, 0, -0.3), Vector3(hw + t2 * 0.5 + 0.1, float(wings[0]["top"]) + 0.8, -0.3), 0.06, 0.06, Color(0.42, 0.32, 0.22))
		for k in int(float(wings[0]["top"]) / 0.35):
			var t := (k + 0.5) / (float(wings[0]["top"]) / 0.35)
			var p := Vector3(hw + 0.9, 0, 0).lerp(Vector3(hw + t2 * 0.5 + 0.1, float(wings[0]["top"]) + 0.8, 0), t)
			me.box(p, Vector3(0.05, 0.05, 0.6), Color(0.42, 0.32, 0.22))
	# sanayi: trafo, LPG küresi, su kulesi, tank havuzu seti
	if X.has("transformers"):
		var tp := Vector3(hw + 4.2, 0, 0)
		_yard(Rect2(hw + 1.2, -hd - 0.5, 6.0, D + 1.0), "mesh", 0, wcol)
		for i in 2:
			var q := tp + Vector3(0, 0, -1.4 + i * 2.8)
			me.box(q + up * 0.9, Vector3(1.6, 1.8, 1.2), Color(0.5, 0.56, 0.5))
			for k in 6:
				me.box(q + Vector3(-0.6 + k * 0.24, 0.9, 0.66), Vector3(0.05, 1.5, 0.12), Color(0.45, 0.5, 0.45))
			for k in 3:
				me.cyl(q + Vector3(-0.5 + k * 0.5, 1.8, 0), 0.08, 0.06, 0.8, 6, Color(0.6, 0.35, 0.25))
				for j in 4:
					me.cyl(q + Vector3(-0.5 + k * 0.5, 1.9 + j * 0.16, 0), 0.13, 0.13, 0.05, 8, Color(0.62, 0.38, 0.28))
			_solid(q, Vector2(1.6, 1.4), 2.6)
		for sx: float in [-1.0, 1.0]:
			me.box(tp + Vector3(sx * 1.6, 3.5, 0), Vector3(0.2, 7.0, 0.2), Color(0.55, 0.55, 0.56))
		me.box(tp + Vector3(0, 6.8, 0), Vector3(3.6, 0.2, 0.2), Color(0.55, 0.55, 0.56))
	if X.has("sphere"):
		var sp := Vector3(hw + 6.0, 0, 0)
		for k in 8:
			var a := TAU * k / 8.0
			me.box(sp + Vector3(cos(a) * 2.6, 2.2, sin(a) * 2.6), Vector3(0.22, 4.4, 0.22), Color(0.7, 0.7, 0.72))
		me.sphere(sp + up * 5.0, Vector3(3.3, 3.3, 3.3), 18, 12, Color(0.94, 0.94, 0.93))
		me.box(sp + up * 8.35, Vector3(1.6, 0.1, 1.6), Color(0.6, 0.6, 0.62))
		me.cyl(sp + Vector3(0, 0, 0), 3.6, 3.6, 0.2, 18, Color(0.6, 0.58, 0.55))
		_solid(sp, Vector2(6.0, 6.0), 3.0)
	if X.has("wtower"):
		var tp := Vector3(hw + 4.5, 0, 0)
		var h := 14.0
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_beam(me, tp + Vector3(sx * 2.0, 0, sz * 2.0), tp + Vector3(sx * 1.4, h, sz * 1.4), 0.3, 0.3, Color(0.7, 0.7, 0.68))
		for y: float in [4.0, 8.0, 12.0]:
			for k in 4:
				var a := PI * 0.5 * k
				var s := lerpf(2.0, 1.4, y / h)
				_beam(me, tp + Vector3(cos(a) - sin(a), 0, sin(a) + cos(a)) * s + up * y, tp + Vector3(cos(a + PI * 0.5) - sin(a + PI * 0.5), 0, sin(a + PI * 0.5) + cos(a + PI * 0.5)) * s + up * y, 0.15, 0.15, Color(0.7, 0.7, 0.68))
		me.cyl(tp + up * h, 3.0, 3.0, 4.0, 18, Color(0.82, 0.84, 0.86))
		_mem("lead").cyl(tp + up * (h + 4.0), 3.1, 0.3, 1.4, 18, Color(0.6, 0.64, 0.68), Basis(), false)
		me.cyl(tp + up * (h + 1.6), 3.04, 3.04, 0.7, 18, Color(0.2, 0.4, 0.7), Basis(), false)
		for k in 30:
			var a := TAU * k / 30.0
			me.box(tp + up * (h + 0.5) + Vector3(cos(a), 0, sin(a)) * 3.5, Vector3(0.05, 1.0, 0.05), Color(0.4, 0.4, 0.42))
		me.cyl(tp + up * h, 3.6, 3.6, 0.1, 18, Color(0.5, 0.5, 0.52))
		me.cyl(tp, 0.4, 0.4, h, 8, Color(0.4, 0.5, 0.6))
		for sx: float in [-1.0, 1.0]:
			for sz: float in [-1.0, 1.0]:
				_solid(tp + Vector3(sx * 2.0, 0, sz * 2.0), Vector2(0.6, 0.6), 3.0)
	if X.has("ftanks"):
		var r := Rect2(hw + 0.8, -hd - 8.0, 21.0, D + 12.0)
		var bc := Color(0.7, 0.7, 0.68, 0.0)
		for e in [[Vector3(r.position.x, 0, r.position.y), Vector3(r.end.x, 0, r.position.y)], [Vector3(r.end.x, 0, r.position.y), Vector3(r.end.x, 0, r.end.y)], [Vector3(r.end.x, 0, r.end.y), Vector3(r.position.x + 3.0, 0, r.end.y)]]:
			B.wall_line(_w(e[0]), _w(e[1]), 2, bc, Grid.K_WALL, {"len": 1.0, "h": 0.42, "t": 0.4, "jit": 0.02, "type": Blocks.T_CONCRETE})
		me.cyl_between(Vector3(hw, 0.5, 0), Vector3(r.end.x - 2.0, 0.5, 0), 0.15, 0.15, 8, Color(0.6, 0.6, 0.62))

func _d_arc_gate(p: Vector3, w: float, h: float) -> void:
	var c := p + Vector3.UP * h
	var r := w * 0.5 + 0.3
	for i in 8:
		var a0 := PI * i / 8.0
		var a1 := PI * (i + 1) / 8.0
		_beam(me, c + Vector3(cos(a0) * r, sin(a0) * r * 0.7, 0), c + Vector3(cos(a1) * r, sin(a1) * r * 0.7, 0), 0.5, 0.3, wrgb.darkened(0.05))
	for sx: float in [-1.0, 1.0]:
		me.box(p + Vector3(sx * r, h * 0.5, 0), Vector3(0.5, h, 0.55), wrgb.darkened(0.05))

