class_name RiftCatalog
extends RefCounted

const RiftModifierClass := preload("res://core/rifts/rift_modifier.gd")

const RANKS := ["F", "E", "D", "C", "B", "A", "S"]
const SEGMENTS := {"F": 12, "E": 14, "D": 16, "C": 18, "B": 20, "A": 22, "S": 24}
const MIN_COMPANIONS := {"F": 2, "E": 2, "D": 3, "C": 3, "B": 3, "A": 3, "S": 3}
const THEME_ORDER := ["blood_moon", "frozen_void", "ashen_mirror", "storm_archive", "black_tide"]
const MODIFIER_ORDER := ["hungry", "violent", "armored", "mana_static", "thin_air", "echoing"]
const OTHER_SEARCHER_TEAMS := [
	"Drużyna Srebrnego Wilka",
	"Drużyna Czerwonego Kła",
	"Trzy Korony",
	"Drużyna Bez Imienia",
	"Żelazne Kruki",
]
const RANK_SCALES := {
	"F": 1.00,
	"E": 1.10,
	"D": 1.22,
	"C": 1.38,
	"B": 1.58,
	"A": 1.82,
	"S": 2.12,
}
const GOLD_REWARDS := {
	"F": [900, 1400],
	"E": [1400, 2200],
	"D": [2200, 3500],
	"C": [3500, 5200],
	"B": [5200, 7800],
	"A": [7800, 11500],
	"S": [11500, 17000],
}
const EXPERIENCE_REWARDS := {
	"F": 220,
	"E": 320,
	"D": 450,
	"C": 620,
	"B": 850,
	"A": 1150,
	"S": 1550,
}
const UNIQUE_POOLS := {
	"warrior": ["rift_bastion_shield", "last_guard_plate", "oathbreaker_edge", "warden_chain"],
	"hunter": ["third_echo_quiver", "riftglass_bow", "silent_volley_cloak", "afterimage_ring"],
	"mage": ["split_weave_artifact", "twin_star_staff", "empty_mana_robe", "storm_archive_relic"],
	"pierrot": ["two_lies_dice", "deck_without_ace", "seven_chances_lance", "crooked_smile_mask"],
}

# Authored names and prose are preserved from terminal v0.24.7.
# gdlint: disable=max-line-length
const THEMES := {
	"blood_moon":
	{
		"name": "Pęknięcie Krwawego Księżyca",
		"intro":
		"Nad rozdartym niebem wisi czerwony księżyc, choć w Pythonii jest środek dnia. Ziemia pulsuje jak rana.",
		"enemy_names": ["Krwawy Tułacz", "Rozdarty Rycerz", "Ogar Pęknięcia", "Szkarłatne Widmo"],
		"elite_names": ["Herold Krwawego Księżyca", "Rzeźnik Rozdarcia"],
		"bosses":
		[
			["blood_devourer", "Pożeracz Krwawego Księżyca"],
			["red_warden", "Karmazynowy Strażnik"],
		],
	},
	"frozen_void":
	{
		"name": "Zamarznięta Pustka",
		"intro":
		"Śnieg unosi się ku górze, a każdy oddech zamarza w powietrzu na kilka sekund. Za horyzontem nie ma nic poza bielą.",
		"enemy_names":
		["Pustkowy Rozbitek", "Lodowe Widmo", "Bestia Białej Ciszy", "Zamarznięty Strażnik"],
		"elite_names": ["Żniwiarz Białej Ciszy", "Pęknięty Kolos"],
		"bosses":
		[
			["white_maw", "Paszcza Białej Pustki"],
			["frozen_oracle", "Zamarznięta Wyrocznia"],
		],
	},
	"ashen_mirror":
	{
		"name": "Popielne Zwierciadło",
		"intro":
		"Każdy krok zostawia dwa ślady: jeden w popiele i drugi po niewłaściwej stronie własnego cienia.",
		"enemy_names":
		["Popielny Sobowtór", "Pusty Wędrowiec", "Zwierciadlane Ostrze", "Cień bez Twarzy"],
		"elite_names": ["Kopia Bez Imienia", "Strażnik Drugiej Strony"],
		"bosses":
		[
			["mirror_lord", "Władca Krzywego Odbicia"],
			["nameless_twin", "Bezimienny Bliźniak"],
		],
	},
	"storm_archive":
	{
		"name": "Archiwum Burzy",
		"intro":
		"W powietrzu wiszą fragmenty kamiennych stron zapisanych błyskawicami. Każdy grzmot brzmi jak przewracana karta.",
		"enemy_names":
		["Runiczny Wartownik", "Burzowy Skryba", "Żywa Pieczęć", "Arkaniczny Łupieżca"],
		"elite_names": ["Egzekutor Zakazanej Strony", "Strażnik Archiwum"],
		"bosses":
		[
			["archive_keeper", "Kustosz Burzowego Archiwum"],
			["living_edict", "Żywy Edykt"],
		],
	},
	"black_tide":
	{
		"name": "Czarna Przypływowa Szczelina",
		"intro":
		"Pod stopami chlupie czarna woda, choć nie ma tu morza. W oddali dzwoni okręt, którego nie da się zobaczyć.",
		"enemy_names":
		["Topielec Szczeliny", "Marynarz Bez Portu", "Czarny Krab Otchłani", "Widmowy Harpunik"],
		"elite_names": ["Bosman Bez Okrętu", "Kapitan Czarnej Toni"],
		"bosses":
		[
			["tide_colossus", "Kolos Czarnej Toni"],
			["bell_captain", "Kapitan Czwartego Dzwonu"],
		],
	},
}

const MODIFIERS := {
	"hungry": ["Głodna Szczelina", "Przeciwnicy są bardziej wytrzymali.", 1.18, 1.0, 0, 1.0],
	"violent": ["Nadmierna Agresja", "Ataki przeciwników są silniejsze.", 1.0, 1.15, 0, 1.0],
	"armored": ["Skamieniała Tkanka", "Przeciwnicy zyskują dodatkowy DEF.", 1.0, 1.0, 2, 1.0],
	"mana_static": ["Niestabilna Mana", "Umiejętności kosztują więcej Many.", 1.0, 1.0, 0, 1.15],
	"thin_air":
	[
		"Cienka Granica",
		"Szczelina jest niestabilna: elity pojawiają się częściej.",
		1.0,
		1.0,
		0,
		1.0
	],
	"echoing":
	[
		"Echo Przebudzenia",
		"Niektóre walki pozostawiają po sobie dodatkowe widma.",
		1.0,
		1.0,
		0,
		1.0
	],
}


static func rank_index(rank_code: String) -> int:
	return RANKS.find(rank_code)


static func is_valid_rank(rank_code: String) -> bool:
	return rank_code in RANKS


static func get_theme(theme_id: String):
	return THEMES.get(theme_id)


static func get_modifier(modifier_id: String) -> RiftModifierClass:
	var data = MODIFIERS.get(modifier_id)
	if data == null:
		return null
	return (
		RiftModifierClass
		. new(
			modifier_id,
			str(data[0]),
			str(data[1]),
			float(data[2]),
			float(data[3]),
			int(data[4]),
			float(data[5]),
		)
	)
