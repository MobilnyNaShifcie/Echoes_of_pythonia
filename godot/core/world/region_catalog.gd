class_name RegionCatalog
extends RefCounted

const RegionDefinitionClass := preload("res://core/world/region_definition.gd")
const REGION_ORDER := [
	"twilight_plains",
	"black_forest",
	"silentwater_marshes",
	"ashen_borderlands",
	"ice_coast",
]
const ENCOUNTER_DISPLAY_NAMES := {
	"wild_dog": "Dziki Pies",
	"slime": "Slime",
	"wolf": "Wilk",
	"boar": "Spaczony Dzik",
	"bandit": "Bandyta",
	"cursed_scarecrow": "Przeklęty Strach na Wróble",
	"plains_spirit": "Duch Równin",
	"night_guard": "Nocny Strażnik",
	"hunter": "Myśliwy",
	"nature_guardian": "Strażnik Natury",
	"venom_spider": "Jadowity Pająk",
	"forest_cultist": "Kultysta Boru",
	"rotting_knight": "Zgniły Rycerz",
	"corrupted_bear": "Spaczony Niedźwiedź",
	"black_hart": "Czarny Jeleń",
	"gallows_wraith": "Zjawa Wisielca",
	"blackwood_executioner": "Leśny Egzekutor",
	"bog_crawler": "Błotny Pełzacz",
	"drowned_dead": "Topielec",
	"swamp_witch": "Bagienna Wiedźma",
	"bone_crocodile": "Kościany Krokodyl",
	"sunken_knight": "Rycerz Zatopionego Zakonu",
	"mist_walker": "Wędrowiec Mgieł",
	"drowned_mother": "Matka Głuchej Wody",
	"desert_wanderer": "Pustynny Wędrowiec",
	"desert_harpy": "Pustynna Harpia",
	"red_salamander": "Czerwona Salamandra",
	"sand_golem": "Piaskowy Golem",
	"boneburner": "Kościopal",
	"hearth_devourer": "Pożeracz Palenisk",
	"frozen_castaway": "Zamarznięty Rozbitek",
	"ice_bear": "Lodowy Niedźwiedź",
	"snow_griffin": "Śnieżny Gryf",
	"ice_crab": "Lodowy Krab",
	"black_sea_siren": "Syrena Czarnego Morza",
	"ghost_ship_captain": "Widmo Kapitana Statku",
}


static func get_definition(region_id: String) -> RegionDefinitionClass:
	match region_id:
		"twilight_plains":
			return _twilight_plains()
		"black_forest":
			return _black_forest()
		"silentwater_marshes":
			return _silentwater_marshes()
		"ashen_borderlands":
			return _ashen_borderlands()
		"ice_coast":
			return _ice_coast()
	return null


static func get_all_definitions() -> Array[RegionDefinitionClass]:
	var result: Array[RegionDefinitionClass] = []
	for region_id: String in REGION_ORDER:
		result.append(get_definition(region_id))
	return result


static func is_valid_region_id(region_id: String) -> bool:
	return region_id in REGION_ORDER


static func encounter_display_name(enemy_id: String) -> String:
	return str(ENCOUNTER_DISPLAY_NAMES.get(enemy_id, enemy_id))


static func validate_known_region_ids(region_ids: Array) -> String:
	var seen := {}
	for region_id_value in region_ids:
		if not region_id_value is String:
			return "Zapis zawiera nieprawidłowy identyfikator regionu."
		var region_id := str(region_id_value)
		if not is_valid_region_id(region_id) or seen.has(region_id):
			return "Zapis zawiera nieznany albo powtórzony region."
		seen[region_id] = true
	if not seen.has("twilight_plains"):
		return "Zapis nie zawiera regionu startowego."
	return ""


static func _twilight_plains() -> RegionDefinitionClass:
	return (
		RegionDefinitionClass
		. new(
			"twilight_plains",
			"Zmierzchowe Równiny",
			(
				"Rozległe pola za granicą bezpiecznych szlaków. Za dnia krążą tu dzikie "
				+ "zwierzęta i rabusie. Po zmroku między wysoką trawą zaczynają poruszać "
				+ "się rzeczy, które nie powinny już żyć."
			),
			1,
			0,
			2,
			0.8,
			{
				"wild_dog": 25,
				"slime": 20,
				"wolf": 20,
				"boar": 15,
				"bandit": 10,
				"cursed_scarecrow": 10
			},
			{
				"plains_spirit": 25,
				"night_guard": 25,
				"hunter": 20,
				"wolf": 10,
				"boar": 10,
				"bandit": 5,
				"nature_guardian": 5
			},
			[
				"Wiatr ugina wysoką trawę. Tym razem nic cię nie atakuje.",
				"Znajdujesz stare ślady butów, ale prowadzą donikąd.",
				"W oddali słyszysz wycie. Dźwięk szybko milknie.",
				"Przez chwilę masz wrażenie, że ktoś obserwuje cię z pola.",
			]
		)
	)


static func _black_forest() -> RegionDefinitionClass:
	return (
		RegionDefinitionClass
		. new(
			"black_forest",
			"Czarny Bór",
			(
				"Stary las, w którym słońce dociera do ziemi jedynie w postaci cienkich "
				+ "smug. Pnie pokrywa czarna żywica, a z głębi dochodzi skrzypienie lin, "
				+ "choć od lat nikt nie powinien tu mieszkać."
			),
			2,
			2,
			4,
			0.85,
			{
				"venom_spider": 25,
				"forest_cultist": 22,
				"rotting_knight": 18,
				"corrupted_bear": 15,
				"black_hart": 12,
				"gallows_wraith": 8
			},
			{
				"gallows_wraith": 25,
				"forest_cultist": 20,
				"rotting_knight": 18,
				"corrupted_bear": 15,
				"venom_spider": 10,
				"black_hart": 7,
				"blackwood_executioner": 5
			},
			[
				"Między drzewami widzisz świeże ślady ciągniętego łańcucha.",
				"Na gałęzi wisi pusty kaptur. Nie ma pod nim ciała.",
				"Czarna żywica spływa po korze jak zastygła krew.",
				"Słyszysz szept tuż za plecami, lecz nikogo tam nie ma.",
				"Przez moment las całkowicie milknie. Nawet wiatr ustaje.",
			]
		)
	)


static func _silentwater_marshes() -> RegionDefinitionClass:
	return (
		RegionDefinitionClass
		. new(
			"silentwater_marshes",
			"Mokradła Głuchej Wody",
			(
				"Zapadnięty trakt znika pod czarną wodą i mgłą. Zbutwiałe pale po dawnej "
				+ "drodze prowadzą między zatopionymi kaplicami, a pod powierzchnią czasem "
				+ "widać światła poruszające się wbrew nurtowi."
			),
			3,
			5,
			8,
			0.9,
			{
				"bog_crawler": 25,
				"drowned_dead": 22,
				"swamp_witch": 18,
				"bone_crocodile": 15,
				"sunken_knight": 12,
				"mist_walker": 8
			},
			{
				"mist_walker": 22,
				"drowned_dead": 20,
				"swamp_witch": 18,
				"sunken_knight": 15,
				"bone_crocodile": 12,
				"bog_crawler": 8,
				"drowned_mother": 5
			},
			[
				"Coś dużego przepływa pod pomostem, lecz woda pozostaje zupełnie gładka.",
				"Znajdujesz zatopiony drogowskaz. Wszystkie strzałki wskazują w dół.",
				"Z mgły dobiega dźwięk dzwonu. Za każdym razem brzmi nieco bliżej.",
				"Na kamieniu leży świeża moneta, choć wokół nie ma żadnych śladów.",
				"Przez kilka minut idziesz obok własnego odbicia. Potem odbicie skręca gdzie indziej.",
			]
		)
	)


static func _ashen_borderlands() -> RegionDefinitionClass:
	return (
		RegionDefinitionClass
		. new(
			"ashen_borderlands",
			"Popielne Pogranicze",
			(
				"Spękana ziemia przechodzi tu w rozległe morze piasku. Gorący wiatr niesie "
				+ "popiół po dawnych szlakach, a między wydmami wędrują harpie, salamandry "
				+ "i istoty zrodzone z kamienia. Nad pustkowiem ciąży imię Azhara."
			),
			4,
			10,
			14,
			0.92,
			{
				"desert_wanderer": 25,
				"desert_harpy": 22,
				"red_salamander": 20,
				"sand_golem": 18,
				"boneburner": 15
			},
			{
				"boneburner": 24,
				"red_salamander": 22,
				"sand_golem": 19,
				"desert_wanderer": 14,
				"desert_harpy": 11,
				"hearth_devourer": 10
			},
			[
				"Wiatr zasypuje twoje ślady niemal natychmiast po przejściu.",
				"Na horyzoncie pojawia się miraż, który znika, gdy próbujesz podejść bliżej.",
				"Znajdujesz resztki starego obozowiska przykryte cienką warstwą popiołu.",
				"Wydma osuwa się z głuchym pomrukiem, odsłaniając fragment dawnego traktu.",
				"Przez chwilę nad pustkowiem zapada całkowita cisza. Nawet wiatr ustaje.",
			]
		)
	)


static func _ice_coast() -> RegionDefinitionClass:
	return (
		RegionDefinitionClass
		. new(
			"ice_coast",
			"Lodowe Wybrzeże",
			(
				"Północne klify schodzą ku czarnemu morzu skutej lodem wody. Między wrakami "
				+ "statków krążą rozbitkowie i widma, a wśród śnieżnych skał polują gryfy "
				+ "oraz wielkie bestie. Marynarze twierdzą, że pod lodem porusza się Lewiatan Północy."
			),
			5,
			14,
			18,
			0.93,
			{
				"frozen_castaway": 25,
				"ice_bear": 22,
				"snow_griffin": 20,
				"ice_crab": 20,
				"black_sea_siren": 13
			},
			{
				"black_sea_siren": 25,
				"frozen_castaway": 22,
				"ice_bear": 18,
				"snow_griffin": 15,
				"ice_crab": 15,
				"ghost_ship_captain": 5
			},
			[
				"Wśród lodowych skał znajdujesz fragment burty starego statku.",
				"Z czarnego morza dobiega niski dźwięk, po którym lód pod stopami lekko drży.",
				"Śnieg zasypuje ślady prowadzące w stronę klifu.",
				"Na brzegu leży zamarznięta lina okrętowa. Jej drugi koniec znika pod lodem.",
				"Przez mgłę widzisz światło latarni. Gdy podchodzisz bliżej, nie ma tam żadnego statku.",
			]
		)
	)
