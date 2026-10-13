class_name Biomes extends RefCounted
# Harita iklimleri: zemin dokuları, tonlar, su rengi, ışık, bitki örtüsü.

const T := "res://assets/textures/"

static func get_biome(id: String) -> Dictionary:
	match id:
		"desert":
			return {
				"id": "desert", "winter": false,
				"a": "aerial_sand", "b": "dirt_aerial_02", "road": "aerial_beach_01", "bank": "brown_mud_dry", "burn": "burned_ground_01",
				"tint_a": Color(1.0, 0.9, 0.76), "tint_a2": Color(1.04, 0.93, 0.79), "tint_b": Color(0.98, 0.88, 0.74), "tint_road": Color(1.0, 0.88, 0.74),
				"tint_bank": Color(0.85, 0.74, 0.6), "tint_track": Color(0.78, 0.66, 0.52),
				"scale_a": 16.0, "scale_b": 14.0, "scale_road": 5.0, "patch_noise": 0.3, "dune": 0.9, "nstr": 1.1, "macro": 0.12,
				"water_shallow": Color(0.3, 0.86, 0.88), "water_deep": Color(0.05, 0.55, 0.65), "clarity": 0.45,
				"sun": Color(1.0, 0.92, 0.8), "sun_e": 2.3, "amb": Color(0.74, 0.7, 0.64), "amb_e": 0.62, "bg": Color(0.86, 0.74, 0.58), "sat": 1.0, "exp": 1.0,
				"sand": Color(0.82, 0.66, 0.46),
			}
		"green":
			return {
				"id": "green", "winter": false,
				"a": "aerial_grass_rock", "b": "forest_ground_04", "road": "brown_mud_dry", "bank": "brown_mud_dry", "burn": "burned_ground_01",
				"tint_a": Color(0.62, 0.92, 0.42), "tint_a2": Color(0.78, 0.95, 0.48), "tint_b": Color(0.85, 0.82, 0.6), "tint_road": Color(0.6, 0.53, 0.46),
				"tint_bank": Color(0.6, 0.48, 0.36), "tint_track": Color(0.55, 0.42, 0.3),
				"scale_a": 9.0, "scale_b": 8.0, "scale_road": 4.0, "patch_noise": 0.6, "dune": 0.35, "nstr": 1.2, "macro": 0.22,
				"water_shallow": Color(0.38, 0.5, 0.42), "water_deep": Color(0.14, 0.24, 0.24), "clarity": 0.3,
				"sun": Color(1.0, 0.94, 0.82), "sun_e": 2.2, "amb": Color(0.62, 0.68, 0.6), "amb_e": 0.65, "bg": Color(0.4, 0.5, 0.3), "sat": 1.05, "exp": 0.95,
				"sand": Color(0.5, 0.46, 0.34),
			}
		"winter":
			return {
				"id": "winter", "winter": true,
				"a": "snow_02", "b": "snow_field_aerial", "road": "aerial_mud_1", "bank": "brown_mud_dry", "burn": "burned_ground_01",
				"tint_a": Color(1.02, 1.03, 1.06), "tint_a2": Color(0.98, 1.0, 1.04), "tint_b": Color(0.95, 0.96, 1.0), "tint_road": Color(0.78, 0.74, 0.72), "road_amt": 0.62,
				"tint_bank": Color(0.5, 0.46, 0.42), "tint_track": Color(0.42, 0.4, 0.4),
				"scale_a": 7.0, "scale_b": 18.0, "scale_road": 6.0, "patch_noise": 0.55, "dune": 0.25, "nstr": 0.8, "macro": 0.06,
				"water_shallow": Color(0.42, 0.5, 0.55), "water_deep": Color(0.12, 0.2, 0.25), "clarity": 0.25,
				"sun": Color(1.0, 0.95, 0.88), "sun_e": 1.9, "amb": Color(0.64, 0.7, 0.82), "amb_e": 0.75, "bg": Color(0.9, 0.92, 0.95), "sat": 1.02, "exp": 0.9,
				"sand": Color(0.9, 0.9, 0.92),
			}
	return get_biome("desert")

static func tex(name: String, kind := "albedo") -> Texture2D:
	return load(T + name + "/" + kind + ".jpg")
