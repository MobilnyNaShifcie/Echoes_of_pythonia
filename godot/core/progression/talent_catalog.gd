class_name TalentCatalog
extends RefCounted

const ClassPathDefinitionClass := preload("res://core/progression/class_path_definition.gd")
const TalentDefinitionClass := preload("res://core/progression/talent_definition.gd")

const CLASS_PATH_ORDER := {
	"warrior": ["warrior_assault", "warrior_heavy_knight"],
	"hunter": ["hunter_volley", "hunter_phantom_archer"],
	"mage": ["mage_elements", "mage_arcana"],
	"pierrot": ["pierrot_chaos", "pierrot_fortuna"],
}
const TALENT_ORDER := {
	"warrior_assault":
	[
		"warrior_battle_fury",
		"warrior_deep_wounds",
		"warrior_breaker",
		"warrior_executioner",
		"warrior_relentless",
	],
	"warrior_heavy_knight":
	[
		"heavy_knight_core",
		"heavy_shield_mastery",
		"heavy_shield_bash",
		"heavy_counter",
		"heavy_provoke",
		"heavy_bastion",
	],
	"hunter_volley":
	[
		"hunter_piercing_arrow",
		"hunter_frost_arrow",
		"hunter_explosive_arrow",
		"hunter_phantom_arrow",
		"hunter_rain_of_arrows",
		"hunter_splitting_arrow",
		"hunter_sequence_mastery",
	],
	"hunter_phantom_archer":
	[
		"phantom_archer_core",
		"phantom_echo_mastery",
		"phantom_bows",
		"phantom_thousand_arrows",
	],
	"mage_elements":
	[
		"mage_fire_mastery",
		"mage_frost_mastery",
		"mage_storm_mastery",
		"mage_elemental_cycle",
	],
	"mage_arcana":
	[
		"arcana_core",
		"arcana_double_weave",
		"arcana_efficiency",
		"arcana_perfect_weave",
		"arcana_mana_cycle",
	],
	"pierrot_chaos":
	[
		"pierrot_wild_roll",
		"pierrot_crooked_mirror",
		"pierrot_double_stake",
		"pierrot_domino",
		"pierrot_va_banque",
	],
	"pierrot_fortuna":
	[
		"fortuna_core",
		"fortuna_loaded_die",
		"fortuna_cheat",
		"fortuna_second_chance",
		"fortuna_favored",
	],
}

static var _paths := {
	"warrior_assault":
	_path(
		"warrior_assault",
		"warrior",
		"Natarcie",
		"Krwawienie, przełamywanie obrony i egzekucja.",
	),
	"warrior_heavy_knight":
	_path(
		"warrior_heavy_knight",
		"warrior",
		"Ciężki Rycerz",
		"Ciężki pancerz, tarcza, blok, prowokacja i kontry skalujące się z DEF.",
		"path_heavy_knight_book",
		"Ciężki Rycerz",
	),
	"hunter_volley":
	_path(
		"hunter_volley",
		"hunter",
		"Mistrz Salwy",
		"Techniki układane w trzystrzałowe sekwencje i odkrywane kombinacje.",
	),
	"hunter_phantom_archer":
	_path(
		"hunter_phantom_archer",
		"hunter",
		"Widmowy Strzelec",
		"Widmowe echa, kopie łuku i salwy powtarzające wcześniejsze techniki.",
		"path_phantom_archer_book",
		"Widmowy Strzelec",
	),
	"mage_elements":
	_path(
		"mage_elements",
		"mage",
		"Żywioły",
		"Wzmacnia ogień, mróz i błyskawice oraz nagradza ich świadome łączenie.",
	),
	"mage_arcana":
	_path(
		"mage_arcana",
		"mage",
		"Arkana",
		"Splot Magii, ekonomia Many i dwa zaklęcia w jednej turze.",
		"path_arcana_book",
		"Arkanista",
	),
	"pierrot_chaos":
	_path(
		"pierrot_chaos",
		"pierrot",
		"Chaos",
		"Więcej ryzyka, dublety, odbicia i ekstremalne jackpoty.",
	),
	"pierrot_fortuna":
	_path(
		"pierrot_fortuna",
		"pierrot",
		"Fortuna",
		"Manipulowanie wynikiem i świadome wykorzystywanie Żetonów Losu.",
		"path_fortuna_book",
		"Wybraniec Fortuny",
	),
}

static var _talents := {
	"warrior_battle_fury":
	_talent(
		"warrior_battle_fury",
		"warrior",
		"warrior_assault",
		"Furia Bitewna",
		"+4% obrażeń umiejętności Wojownika za rangę.",
		3
	),
	"warrior_deep_wounds":
	_talent(
		"warrior_deep_wounds",
		"warrior",
		"warrior_assault",
		"Głębokie Rany",
		"Krwawienia Wojownika zadają +1 obrażenie na turę za rangę.",
		3,
		{"warrior_battle_fury": 1}
	),
	"warrior_breaker":
	_talent(
		"warrior_breaker",
		"warrior",
		"warrior_assault",
		"Łamacz",
		"Roztrzaskanie Pancerza obniża dodatkowo DEF o 1 za rangę.",
		2,
		{"warrior_battle_fury": 1}
	),
	"warrior_executioner":
	_talent(
		"warrior_executioner",
		"warrior",
		"warrior_assault",
		"Egzekutor",
		"Krwawy Zamach zadaje +30% obrażeń celom poniżej 35% PŻ.",
		1,
		{"warrior_deep_wounds": 2}
	),
	"warrior_relentless":
	_talent(
		"warrior_relentless",
		"warrior",
		"warrior_assault",
		"Nieustępliwy",
		"Podstawowe ataki zadają +5% obrażeń za rangę.",
		2,
		{"warrior_breaker": 1}
	),
	"heavy_knight_core":
	_talent(
		"heavy_knight_core",
		"warrior",
		"warrior_heavy_knight",
		"Przysięga Ciężkiego Rycerza",
		"Aktywuje specjalizację i użycie Odwetu z tarczą."
	),
	"heavy_shield_mastery":
	_talent(
		"heavy_shield_mastery",
		"warrior",
		"warrior_heavy_knight",
		"Mistrz Tarczy",
		"+5 p.p. szansy na Blok za rangę podczas używania tarczy.",
		3,
		{"heavy_knight_core": 1}
	),
	"heavy_shield_bash":
	_talent(
		"heavy_shield_bash",
		"warrior",
		"warrior_heavy_knight",
		"Uderzenie Tarczą",
		"Odblokowuje atak skalujący się z ATK i DEF.",
		1,
		{"heavy_knight_core": 1},
		"shield_bash"
	),
	"heavy_counter":
	_talent(
		"heavy_counter",
		"warrior",
		"warrior_heavy_knight",
		"Żelazna Kontra",
		"Blok zadaje przeciwnikowi obrażenia równe 70% DEF.",
		1,
		{"heavy_shield_mastery": 2}
	),
	"heavy_provoke":
	_talent(
		"heavy_provoke",
		"warrior",
		"warrior_heavy_knight",
		"Prowokacja",
		"Wymusza zwykły atak i zwiększa Blok na tę wymianę.",
		1,
		{"heavy_shield_mastery": 1},
		"provoke"
	),
	"heavy_bastion":
	_talent(
		"heavy_bastion",
		"warrior",
		"warrior_heavy_knight",
		"Bastion",
		"Odwet z tarczą wykorzystuje 75% DEF zamiast 50%.",
		1,
		{"heavy_counter": 1, "heavy_provoke": 1}
	),
	"hunter_piercing_arrow":
	_talent(
		"hunter_piercing_arrow",
		"hunter",
		"hunter_volley",
		"Przebijająca Strzała",
		"Odblokowuje technikę ignorującą dużą część DEF.",
		1,
		{},
		"piercing_arrow"
	),
	"hunter_frost_arrow":
	_talent(
		"hunter_frost_arrow",
		"hunter",
		"hunter_volley",
		"Lodowa Strzała",
		"Odblokowuje technikę mrozu.",
		1,
		{},
		"frost_arrow"
	),
	"hunter_explosive_arrow":
	_talent(
		"hunter_explosive_arrow",
		"hunter",
		"hunter_volley",
		"Wybuchowa Strzała",
		"Odblokowuje technikę wbijającą Ładunki Wybuchowe.",
		1,
		{"hunter_piercing_arrow": 1},
		"explosive_arrow"
	),
	"hunter_phantom_arrow":
	_talent(
		"hunter_phantom_arrow",
		"hunter",
		"hunter_volley",
		"Widmowa Strzała",
		"Odblokowuje technikę pozostawiającą opóźnione echo.",
		1,
		{"hunter_frost_arrow": 1},
		"phantom_arrow"
	),
	"hunter_rain_of_arrows":
	_talent(
		"hunter_rain_of_arrows",
		"hunter",
		"hunter_volley",
		"Deszcz Strzał",
		"Odblokowuje opóźnioną salwę.",
		1,
		{"hunter_explosive_arrow": 1},
		"rain_of_arrows"
	),
	"hunter_splitting_arrow":
	_talent(
		"hunter_splitting_arrow",
		"hunter",
		"hunter_volley",
		"Rozszczepiająca Strzała",
		"Odblokowuje strzał rozpadający się na dwa widmowe odłamki.",
		1,
		{"hunter_phantom_arrow": 1},
		"splitting_arrow"
	),
	"hunter_sequence_mastery":
	_talent(
		"hunter_sequence_mastery",
		"hunter",
		"hunter_volley",
		"Perfekcyjna Sekwencja",
		"Trzy różne techniki wzmacniają kończący strzał o 15%.",
		1,
		{"hunter_explosive_arrow": 1, "hunter_phantom_arrow": 1}
	),
	"phantom_archer_core":
	_talent(
		"phantom_archer_core",
		"hunter",
		"hunter_phantom_archer",
		"Przysięga Widmowego Strzelca",
		"Aktywuje specjalizację Widmowego Strzelca."
	),
	"phantom_echo_mastery":
	_talent(
		"phantom_echo_mastery",
		"hunter",
		"hunter_phantom_archer",
		"Echo Łowcy",
		"Widmowe Echo zadaje +15% bazowej mocy za rangę.",
		2,
		{"phantom_archer_core": 1}
	),
	"phantom_bows":
	_talent(
		"phantom_bows",
		"hunter",
		"hunter_phantom_archer",
		"Widmowe Łuki",
		"Nazwana kombinacja jest powtarzana przez widmowy łuk z 35% mocy.",
		1,
		{"phantom_echo_mastery": 1}
	),
	"phantom_thousand_arrows":
	_talent(
		"phantom_thousand_arrows",
		"hunter",
		"hunter_phantom_archer",
		"Tysiąc Strzał",
		"Odblokowuje finałową salwę czterech widmowych trafień.",
		1,
		{"phantom_bows": 1},
		"thousand_arrows"
	),
	"mage_fire_mastery":
	_talent(
		"mage_fire_mastery",
		"mage",
		"mage_elements",
		"Serce Ognia",
		"+8% obrażeń Ognistego Pocisku za rangę.",
		2
	),
	"mage_frost_mastery":
	_talent(
		"mage_frost_mastery",
		"mage",
		"mage_elements",
		"Wieczny Mróz",
		"+8% obrażeń Lodowej Lancy za rangę.",
		2
	),
	"mage_storm_mastery":
	_talent(
		"mage_storm_mastery",
		"mage",
		"mage_elements",
		"Głos Burzy",
		"+8% obrażeń Pioruna za rangę.",
		2
	),
	"mage_elemental_cycle":
	_talent(
		"mage_elemental_cycle",
		"mage",
		"mage_elements",
		"Cykl Żywiołów",
		"Trzeci różny żywioł z rzędu zyskuje 20% obrażeń.",
		1,
		{"mage_fire_mastery": 1, "mage_frost_mastery": 1, "mage_storm_mastery": 1}
	),
	"arcana_core":
	_talent(
		"arcana_core",
		"mage",
		"mage_arcana",
		"Przysięga Arkanisty",
		"Każde zaklęcie buduje Splot Magii, maksymalnie 3."
	),
	"arcana_double_weave":
	_talent(
		"arcana_double_weave",
		"mage",
		"mage_arcana",
		"Podwójny Splot",
		"Przy 3/3 Splotu pozwala rzucić dwa zaklęcia w jednej turze.",
		1,
		{"arcana_core": 1}
	),
	"arcana_efficiency":
	_talent(
		"arcana_efficiency",
		"mage",
		"mage_arcana",
		"Oszczędny Splot",
		"Drugie zaklęcie kosztuje 25% mniej Many.",
		1,
		{"arcana_double_weave": 1}
	),
	"arcana_perfect_weave":
	_talent(
		"arcana_perfect_weave",
		"mage",
		"mage_arcana",
		"Perfekcyjny Splot",
		"Drugie zaklęcie ma 95% mocy zamiast 80%.",
		1,
		{"arcana_efficiency": 1}
	),
	"arcana_mana_cycle":
	_talent(
		"arcana_mana_cycle",
		"mage",
		"mage_arcana",
		"Obieg Many",
		"Po Podwójnym Splocie odzyskujesz 4 Many.",
		1,
		{"arcana_perfect_weave": 1}
	),
	"pierrot_wild_roll":
	_talent(
		"pierrot_wild_roll",
		"pierrot",
		"pierrot_chaos",
		"Dziki Rzut",
		"Jackpot uruchamia dodatkowy rzut kością za bonusowe obrażenia."
	),
	"pierrot_crooked_mirror":
	_talent(
		"pierrot_crooked_mirror",
		"pierrot",
		"pierrot_chaos",
		"Krzywe Zwierciadło",
		"Dublet przygotowuje odbicie następnego bezpośredniego ataku.",
		1,
		{"pierrot_wild_roll": 1}
	),
	"pierrot_double_stake":
	_talent(
		"pierrot_double_stake",
		"pierrot",
		"pierrot_chaos",
		"Podwójna Stawka",
		"Skrajne wyniki Kości Losu mają o 25% silniejsze skutki.",
		1,
		{"pierrot_wild_roll": 1}
	),
	"pierrot_domino":
	_talent(
		"pierrot_domino",
		"pierrot",
		"pierrot_chaos",
		"Efekt Domina",
		"Jackpot ma 50% szansy uruchomić dodatkowy rzut k6.",
		1,
		{"pierrot_double_stake": 1}
	),
	"pierrot_va_banque":
	_talent(
		"pierrot_va_banque",
		"pierrot",
		"pierrot_chaos",
		"Va Banque",
		"Odblokowuje rzut 3k6 zużywający wszystkie Żetony Losu.",
		1,
		{"pierrot_crooked_mirror": 1, "pierrot_domino": 1},
		"va_banque"
	),
	"fortuna_core":
	_talent(
		"fortuna_core",
		"pierrot",
		"pierrot_fortuna",
		"Przysięga Fortuny",
		"Aktywuje specjalizację i zwiększa limit Żetonów Losu o 2."
	),
	"fortuna_loaded_die":
	_talent(
		"fortuna_loaded_die",
		"pierrot",
		"pierrot_fortuna",
		"Dociążona Kość",
		"Pierwsza wyrzucona jedynka zostaje automatycznie przerzucona.",
		1,
		{"fortuna_core": 1}
	),
	"fortuna_cheat":
	_talent(
		"fortuna_cheat",
		"pierrot",
		"pierrot_fortuna",
		"Kant",
		"Przy 2k6 wynik 6 lub 8 zużywa Żeton i staje się siódemką.",
		1,
		{"fortuna_loaded_die": 1}
	),
	"fortuna_second_chance":
	_talent(
		"fortuna_second_chance",
		"pierrot",
		"pierrot_fortuna",
		"Druga Szansa",
		"Raz na walkę katastrofalny rzut 3k6 zostaje przerzucony.",
		1,
		{"fortuna_cheat": 1}
	),
	"fortuna_favored":
	_talent(
		"fortuna_favored",
		"pierrot",
		"pierrot_fortuna",
		"Wybraniec Fortuny",
		"Jackpoty skalują się ze Szczęściem, a pech daje dodatkowy Żeton.",
		1,
		{"fortuna_second_chance": 1}
	),
}


static func _path(
	path_id: String,
	class_code: String,
	display_name: String,
	description: String,
	book_item_id := "",
	specialization_name := "",
) -> ClassPathDefinitionClass:
	return (
		ClassPathDefinitionClass
		. new(
			{
				"path_id": path_id,
				"character_class_code": class_code,
				"display_name": display_name,
				"description": description,
				"book_item_id": book_item_id,
				"specialization_name": specialization_name,
			}
		)
	)


static func _talent(
	talent_id: String,
	class_code: String,
	path_id: String,
	display_name: String,
	description: String,
	max_rank := 1,
	prerequisites := {},
	active_skill_id := "",
) -> TalentDefinitionClass:
	return (
		TalentDefinitionClass
		. new(
			{
				"talent_id": talent_id,
				"character_class_code": class_code,
				"path_id": path_id,
				"display_name": display_name,
				"description": description,
				"max_rank": max_rank,
				"prerequisites": prerequisites,
				"active_skill_id": active_skill_id,
			}
		)
	)


static func get_path_definition(path_id: String) -> ClassPathDefinitionClass:
	return _paths.get(path_id)


static func get_paths_for_class(class_code: String) -> Array[ClassPathDefinitionClass]:
	var result: Array[ClassPathDefinitionClass] = []
	for path_id: String in CLASS_PATH_ORDER.get(class_code, []):
		result.append(_paths[path_id])
	return result


static func get_talent(talent_id: String) -> TalentDefinitionClass:
	return _talents.get(talent_id)


static func get_talents_for_path(path_id: String) -> Array[TalentDefinitionClass]:
	var result: Array[TalentDefinitionClass] = []
	for talent_id: String in TALENT_ORDER.get(path_id, []):
		result.append(_talents[talent_id])
	return result


static func get_talents_for_class(class_code: String) -> Array[TalentDefinitionClass]:
	var result: Array[TalentDefinitionClass] = []
	for path: ClassPathDefinitionClass in get_paths_for_class(class_code):
		result.append_array(get_talents_for_path(path.path_id))
	return result


static func talent_for_active_skill(skill_id: String) -> TalentDefinitionClass:
	for talent: TalentDefinitionClass in _talents.values():
		if talent.active_skill_id == skill_id:
			return talent
	return null


static func is_valid_path_for_class(path_id: String, class_code: String) -> bool:
	var path: ClassPathDefinitionClass = get_path_definition(path_id)
	return path != null and path.character_class_code == class_code
