class_name RegionalItemCatalog
extends RefCounted

const ItemDefinitionClass := preload("res://core/items/item_definition.gd")
# Data descriptions intentionally preserve the terminal version's complete prose.
# gdlint: disable=max-line-length
const DEFINITIONS := {
	"ancient_order_key":
	{
		"name": "Starożytny Klucz Zakonu",
		"description":
		"Ciężki, sczerniały klucz noszący herb Zatopionego Zakonu. Otwiera kamienne wrota Krypty Zatopionego Zakonu i zostaje zużyty przy wejściu.",
		"category": "key",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"order_seal":
	{
		"name": "Pieczęć Zatopionego Zakonu",
		"description": "Ciężka pieczęć noszona przez członków zakonu pochowanych pod Głuchą Wodą.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"grandmaster_chain":
	{
		"name": "Łańcuch Wielkiego Mistrza",
		"description": "Fragment ceremonialnego łańcucha dowódcy Zatopionego Zakonu.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"crown_fragment":
	{
		"name": "Fragment Zatopionej Korony",
		"description":
		"Odłamek korony nasiąknięty magią głębin. Reaguje na stare pieczęcie zakonu.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"grandmaster_sword":
	{
		"name": "Miecz Wielkiego Mistrza",
		"description":
		"Ciężkie ostrze ostatniego dowódcy Zakonu. Stworzone do przełamywania obrony.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "weapon",
		"attack": 13,
		"item_power": 4,
		"required_level": 10
	},
	"sunken_order_cloak":
	{
		"name": "Płaszcz Zatopionego Zakonu",
		"description": "Warstwowy pancerz i płaszcz odporny na zimną wodę krypt.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "chest",
		"defense": 8,
		"max_hp": 30,
		"water_resistance": 15,
		"item_power": 4,
		"required_level": 10
	},
	"varek_sabre_fragment":
	{
		"name": "Fragment Szabli Vareka",
		"description":
		"Odłamany fragment czarnej klingi Admirała Vareka. Metal pozostaje lodowaty nawet przy ogniu.",
		"category": "material",
		"rarity": "epic",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"ancient_scale":
	{
		"name": "Prastara Łuska",
		"description": "Gruba łuska pokryta śladami kościanych narośli.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"azhar_blade":
	{
		"name": "Ostrze Azhara",
		"description": "Długie ostrze Władcy Pustkowi. Jest lżejsze, niż sugeruje jego rozmiar.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "weapon",
		"attack": 18,
		"item_power": 5,
		"required_level": 14
	},
	"azhar_crown":
	{
		"name": "Korona Azhara",
		"description": "Korona nosząca ślady piasku wtopionego w metal przez lata pustynnych burz.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "head",
		"defense": 7,
		"max_hp": 40,
		"fire_resistance": 12,
		"item_power": 5,
		"required_level": 14
	},
	"azhar_ring":
	{
		"name": "Pierścień Azhara",
		"description": "Masywny pierścień będący symbolem władzy nad pustkowiem.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "ring",
		"attack": 4,
		"max_mana": 24,
		"item_power": 5,
		"required_level": 14
	},
	"azhar_sigil":
	{
		"name": "Pieczęć Azhara",
		"description": "Ciężka pieczęć nosząca znak Władcy Pustkowi.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"bearhide_belt":
	{
		"name": "Pas z Czarnej Skóry",
		"description": "Szeroki pas wykonany ze skóry spaczonego niedźwiedzia.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "belt",
		"defense": 1,
		"max_hp": 10,
		"item_power": 2,
		"required_level": 4
	},
	"black_antler":
	{
		"name": "Czarne Poroże",
		"description": "Odłamek poroża, który zdaje się pochłaniać światło.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"black_antler_charm":
	{
		"name": "Bransoleta Czarnego Jelenia",
		"description": "Oszlifowany fragment czarnego poroża osadzony w skórzanej opasce.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "bracelet",
		"attack": 3,
		"item_power": 2,
		"required_level": 4
	},
	"black_bear_claw":
	{
		"name": "Czarny Pazur",
		"description": "Ogromny pazur spaczonego niedźwiedzia.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"black_fleet_medallion":
	{
		"name": "Medalion Czarnej Floty",
		"description":
		"Ciężki medalion noszony przez oficerów Czarnej Floty. Jest wejściówką do Wraku Czarnej Floty i zostaje zużyty przy wejściu.",
		"category": "key",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"black_pearl":
	{
		"name": "Czarna Perła",
		"description": "Ciemna perła wydobywana przez syreny z najgłębszych partii morza.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"black_pearl_earrings":
	{
		"name": "Kolczyki Czarnej Perły",
		"description":
		"Para ciemnych pereł, w których słychać szum morza nawet daleko od wybrzeża.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "earrings",
		"attack": 5,
		"max_mana": 30,
		"item_power": 6,
		"required_level": 16
	},
	"black_sea_amulet":
	{
		"name": "Amulet Czarnego Morza",
		"description":
		"Czarna perła zamknięta w srebrnej oprawie. Jej energia odpowiada na przepływ Many Maga.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "necklace",
		"attack": 5,
		"max_mana": 32,
		"class_effect_id": "mage_mana_tide",
		"item_power": 6,
		"required_level": 16
	},
	"blackwood_heart":
	{
		"name": "Serce Czarnego Boru",
		"description": "Twardy rdzeń pulsujący jak żywe serce drzewa.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"blackwood_mail":
	{
		"name": "Pancerz Czarnego Boru",
		"description": "Płyty metalu wzmocnione grubą, spaczoną skórą.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "chest",
		"defense": 5,
		"max_hp": 10,
		"item_power": 2,
		"required_level": 4
	},
	"bog_ichor":
	{
		"name": "Posoka Bagienna",
		"description": "Gęsta ciecz o zapachu mokrej ziemi.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"bone_fang":
	{
		"name": "Kościany Kieł",
		"description": "Ząb większy niż ludzki palec, twardy jak kamień.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"captain_signet":
	{
		"name": "Bransoleta Czarnej Floty",
		"description":
		"Ciężka bransoleta należąca niegdyś do oficera Czarnej Floty. Jej ciemne ogniwa pozostają chłodne nawet z dala od północnego morza.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "bracelet",
		"attack": 5,
		"max_mana": 26,
		"item_power": 6,
		"required_level": 17
	},
	"charred_bone":
	{
		"name": "Zwęglona Kość",
		"description": "Lekka, czarna kość nasycona suchym żarem.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"corrupted_hide":
	{
		"name": "Spaczona Skóra",
		"description": "Gruba skóra przesiąknięta czarną żywicą.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"cultist_cloth":
	{
		"name": "Fragment Szaty Kultysty",
		"description": "Oderwany fragment czarnej ceremonialnej szaty, pokryty zaschniętą żywicą.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"cultist_pendant":
	{
		"name": "Wisiorek Kultysty",
		"description": "Kamień, który delikatnie reaguje na przepływ Many.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "necklace",
		"max_mana": 10,
		"attack": 1,
		"item_power": 2,
		"required_level": 3
	},
	"cursed_compass":
	{
		"name": "Przeklęty Kompas",
		"description": "Stary kompas kapitański. Igła zawsze wskazuje w stronę czarnego morza.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"cursed_resin":
	{
		"name": "Przeklęta Żywica",
		"description": "Czarna żywica, która pozostaje ciepła nawet w zimnej wodzie.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"damned_essence":
	{
		"name": "Potępiona Esencja",
		"description": "Zimna energia pozostała po zjawie wisielca.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"dark_sigil":
	{
		"name": "Mroczny Sygnet",
		"description": "Metalowy znak nieznanego leśnego kultu.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"dark_sigil_ring":
	{
		"name": "Pierścień Mrocznego Sygnetu",
		"description": "Przerobiony znak kultu, w którym pulsuje potępiona energia.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "ring",
		"max_mana": 10,
		"attack": 1,
		"item_power": 2,
		"required_level": 3
	},
	"desert_cloth":
	{
		"name": "Pustynna Tkanina",
		"description": "Gruba tkanina odporna na piasek i gorący wiatr.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"drowned_bone":
	{
		"name": "Kość Topielca",
		"description": "Kość wygładzona przez lata spędzone pod wodą.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"drowned_coin":
	{
		"name": "Moneta Topielca",
		"description":
		"Zielonkawa moneta z nieczytelnym herbem. Cenny składnik kilku receptur związanych z Głuchą Wodą i Zatopionym Zakonem.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"drowned_gauntlets":
	{
		"name": "Rękawice Topielca",
		"description": "Ciężkie rękawice, których metal jest stale chłodny.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "hands",
		"defense": 3,
		"max_hp": 10,
		"item_power": 3,
		"required_level": 5
	},
	"drowned_mother_blade":
	{
		"name": "Ostrze Matki Głuchej Wody",
		"description": "Długie, czarne ostrze, z którego nieustannie ścieka woda.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "weapon",
		"attack": 10,
		"item_power": 3,
		"required_level": 8
	},
	"drowned_mother_crown":
	{
		"name": "Korona Utopionej Matki",
		"description": "Korona spleciona z metalu, korzeni i kości.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "head",
		"defense": 5,
		"max_hp": 20,
		"water_resistance": 15,
		"item_power": 3,
		"required_level": 8
	},
	"drowned_mother_medallion":
	{
		"name": "Medalion Utopionej Matki",
		"description":
		"Ciemny medalion znaleziony pośród reliktów Głuchej Wody. W jego wnętrzu porusza się kropla czarnej wody.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "necklace",
		"attack": 3,
		"max_mana": 14,
		"item_power": 3,
		"required_level": 8
	},
	"executioner_axe":
	{
		"name": "Topór Leśnego Egzekutora",
		"description": "Ciężkie ostrze noszące ślady setek rytualnych cięć.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "weapon",
		"attack": 7,
		"item_power": 2,
		"required_level": 5
	},
	"executioner_mask":
	{
		"name": "Maska Leśnego Egzekutora",
		"description": "Drewniana maska spojona z metalem i zaschniętą żywicą.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "head",
		"defense": 4,
		"max_hp": 10,
		"fire_resistance": 8,
		"item_power": 2,
		"required_level": 5
	},
	"frozen_cloth":
	{
		"name": "Zamarznięta Tkanina",
		"description":
		"Gruby materiał zdjęty z odzieży rozbitków. Mróz usztywnił włókna, ale ich nie zniszczył.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"great_healing_potion":
	{
		"name": "Wielka Mikstura Lecznicza",
		"description": "Duża fiolka gęstego eliksiru. Przywraca 150 HP.",
		"category": "consumable",
		"rarity": "rare",
		"stackable": true,
		"heal_hp": 150,
		"item_power": 0,
		"required_level": 0
	},
	"harpy_feather":
	{
		"name": "Pióro Harpii",
		"description": "Twarde pióro zachowujące lekkość mimo pustynnego pyłu.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"hearth_core":
	{
		"name": "Rdzeń Paleniska",
		"description": "Rozżarzony rdzeń wyrwany z wnętrza Pożeracza Palenisk.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"hearth_gauntlets":
	{
		"name": "Karwasze Paleniska",
		"description":
		"Ciężkie osłony przedramion wykute z materiału, który nie stygnie nawet nocą.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "hands",
		"defense": 8,
		"max_hp": 35,
		"fire_resistance": 15,
		"item_power": 5,
		"required_level": 13
	},
	"ice_chitin":
	{
		"name": "Lodowa Chityna",
		"description": "Twardy fragment pancerza lodowego kraba.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"leviathan_ring":
	{
		"name": "Pierścień Lewiatana",
		"description": "Ciężki pierścień wykonany z fragmentów łuski Lewiatana Północy.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "ring",
		"attack": 7,
		"max_mana": 30,
		"item_power": 6,
		"required_level": 18
	},
	"leviathan_scale":
	{
		"name": "Łuska Lewiatana",
		"description": "Ogromna łuska wyrwana z ciała Lewiatana Północy.",
		"category": "material",
		"rarity": "epic",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"mirewalker_boots":
	{
		"name": "Buty Brodzącego w Mule",
		"description": "Buty ze sztywną podeszwą i plecionymi cholewami.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "feet",
		"defense": 2,
		"dodge": 4.0,
		"water_resistance": 8,
		"item_power": 3,
		"required_level": 5
	},
	"mist_earrings":
	{
		"name": "Kolczyki Wędrowca Mgieł",
		"description": "Srebrne kolczyki z kamieniem, którego krawędzie rozmywają się w powietrzu.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "earrings",
		"max_mana": 12,
		"attack": 2,
		"item_power": 3,
		"required_level": 6
	},
	"mist_essence":
	{
		"name": "Esencja Mgły",
		"description": "Chłodna kropla, która nigdy nie spada z naczynia.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"north_armor":
	{
		"name": "Pancerz Północy",
		"description":
		"Ciężki pancerz stworzony do przyjmowania ciosów na lodowych szlakach. Jego prawdziwy potencjał ujawnia Wojownik.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "chest",
		"defense": 14,
		"max_hp": 65,
		"frost_resistance": 15,
		"class_effect_id": "warrior_retribution",
		"item_power": 6,
		"required_level": 16
	},
	"northern_trail_boots":
	{
		"name": "Buty Północnego Szlaku",
		"description": "Solidne buty przygotowane do marszu po lodzie, śniegu i mokrych skałach.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "feet",
		"defense": 5,
		"dodge": 6.0,
		"frost_resistance": 10,
		"item_power": 6,
		"required_level": 15
	},
	"rotting_knight_helm":
	{
		"name": "Hełm Zgniłego Rycerza",
		"description": "Ciężki hełm o zardzewiałej, lecz wciąż solidnej konstrukcji.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "head",
		"defense": 3,
		"max_hp": 5,
		"item_power": 2,
		"required_level": 4
	},
	"rusted_plate":
	{
		"name": "Zardzewiała Płyta",
		"description": "Ciężki fragment pancerza zdjęty z martwego rycerza.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"salamander_scale":
	{
		"name": "Łuska Salamandry",
		"description": "Czerwona łuska, która długo pozostaje ciepła po dotknięciu.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"sand_golem_core":
	{
		"name": "Rdzeń Piaskowego Golema",
		"description": "Zbity kamienny rdzeń, wokół którego utrzymuje się drobny piasek.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"scale_belt":
	{
		"name": "Pas z Prastarych Łusek",
		"description": "Ciężki pas z nakładających się łusek.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "belt",
		"defense": 2,
		"max_hp": 15,
		"earth_resistance": 8,
		"item_power": 3,
		"required_level": 6
	},
	"silentwater_heart":
	{
		"name": "Serce Głuchej Wody",
		"description": "Ciemny rdzeń, w którym słychać odległy rytm przypominający bicie serca.",
		"category": "material",
		"rarity": "rare",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"snow_griffin_cloak":
	{
		"name": "Płaszcz Śnieżnego Gryfa",
		"description":
		"Lekki płaszcz z jasnych piór, pozwalający błyskawicznie wykorzystać chwilę po uniknięciu ciosu.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "chest",
		"defense": 9,
		"max_hp": 35,
		"dodge": 5.0,
		"wind_resistance": 12,
		"class_effect_id": "hunter_predatory_instinct",
		"item_power": 6,
		"required_level": 16
	},
	"snow_griffin_feather":
	{
		"name": "Pióro Śnieżnego Gryfa",
		"description": "Długie, jasne pióro zachowujące sprężystość mimo mrozu.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"spider_silk":
	{
		"name": "Pajęcza Nić",
		"description": "Nienaturalnie mocna nić z głębi Czarnego Boru.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"spiderstep_boots":
	{
		"name": "Buty Pajęczego Kroku",
		"description": "Lekkie buty oplecione srebrzystą nicią.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "feet",
		"defense": 1,
		"dodge": 3.0,
		"wind_resistance": 5,
		"item_power": 2,
		"required_level": 3
	},
	"spiderweave_gloves":
	{
		"name": "Rękawice Pajęczego Splotu",
		"description": "Elastyczne rękawice utkane z pajęczej nici.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "hands",
		"defense": 1,
		"dodge": 2.0,
		"item_power": 2,
		"required_level": 3
	},
	"sun_talisman":
	{
		"name": "Talizman Słońca",
		"description":
		"Ogrzany kamień oprawiony w metal. Zatrzymuje w sobie resztki żywej energii.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "necklace",
		"attack": 5,
		"max_mana": 18,
		"item_power": 5,
		"required_level": 12
	},
	"sunken_knight_armor":
	{
		"name": "Pancerz Zatopionego Zakonu",
		"description": "Ciężka zbroja dawnego zakonu, oczyszczona z mułu, lecz nie z klątwy.",
		"category": "equipment",
		"rarity": "epic",
		"stackable": false,
		"slot": "chest",
		"defense": 7,
		"max_hp": 25,
		"water_resistance": 12,
		"item_power": 3,
		"required_level": 7
	},
	"sunken_plate":
	{
		"name": "Płyta Zatopionego Zakonu",
		"description": "Fragment starego pancerza zachowany pod warstwą mułu.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"swamp_reed":
	{
		"name": "Trzcina Głuchej Wody",
		"description": "Twarda trzcina rosnąca na czarnych płyciznach.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"venom_gland":
	{
		"name": "Gruczoł Jadowy",
		"description": "Wciąż pulsujący gruczoł wypełniony trucizną.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"wasteland_armor":
	{
		"name": "Pancerz Pustkowi",
		"description":
		"Warstwowy pancerz przygotowany na żar, pył i długie wyprawy przez pustkowie.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "chest",
		"defense": 10,
		"max_hp": 45,
		"fire_resistance": 10,
		"item_power": 5,
		"required_level": 11
	},
	"wasteland_belt":
	{
		"name": "Pas Pustkowi",
		"description":
		"Szeroki pas wzmocniony płytkami odpornymi na żar i piasek. Łączy ochronę z miejscem na cięższy ekwipunek.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "belt",
		"attack": 2,
		"defense": 4,
		"max_hp": 28,
		"fire_resistance": 10,
		"item_power": 5,
		"required_level": 13
	},
	"white_fur":
	{
		"name": "Białe Futro",
		"description": "Gęste futro lodowego niedźwiedzia, odporne na północny wiatr.",
		"category": "material",
		"rarity": "common",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"witch_herb":
	{
		"name": "Ziele Czarnej Wody",
		"description": "Roślina zbierana przez bagienne wiedźmy.",
		"category": "material",
		"rarity": "uncommon",
		"stackable": true,
		"item_power": 0,
		"required_level": 0
	},
	"witchbone_ring":
	{
		"name": "Pierścień z Kości Wiedźmy",
		"description": "Kościany pierścień wypełniony zielonkawym światłem.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "ring",
		"max_mana": 15,
		"attack": 1,
		"item_power": 3,
		"required_level": 5
	},
	"wraith_ring":
	{
		"name": "Pierścień Wisielca",
		"description": "Zimny pierścień, którego dotyk niemal znika na skórze.",
		"category": "equipment",
		"rarity": "rare",
		"stackable": false,
		"slot": "ring",
		"max_mana": 10,
		"attack": 1,
		"item_power": 2,
		"required_level": 4
	}
}

static var _cache := {}


static func has_definition(item_id: String) -> bool:
	return DEFINITIONS.has(item_id)


static func get_definition(item_id: String) -> ItemDefinitionClass:
	if _cache.has(item_id):
		return _cache[item_id]
	if not DEFINITIONS.has(item_id):
		return null
	var data: Dictionary = DEFINITIONS[item_id]
	var definition := ItemDefinitionClass.new()
	definition.item_id = item_id
	definition.display_name = str(data.name)
	definition.description = str(data.description)
	definition.category = str(data.category)
	definition.rarity = str(data.rarity)
	definition.stackable = bool(data.stackable)
	definition.slot = str(data.get("slot", ""))
	definition.equipment_type = str(data.get("equipment_type", ""))
	definition.item_power = int(data.get("item_power", 0))
	definition.required_level = int(data.get("required_level", 0))
	definition.required_class_code = str(data.get("required_class", ""))
	definition.required_class_name = str(data.get("required_class_name", ""))
	definition.attack = int(data.get("attack", 0))
	definition.defense = int(data.get("defense", 0))
	definition.max_hp = int(data.get("max_hp", 0))
	definition.dodge = float(data.get("dodge", 0.0))
	definition.max_mana = int(data.get("max_mana", 0))
	definition.magic_power = int(data.get("magic_power", 0))
	definition.heal_hp = int(data.get("heal_hp", 0))
	definition.heal_hp_percent = float(data.get("heal_hp_percent", 0.0))
	definition.restore_mana = int(data.get("restore_mana", 0))
	definition.restore_mana_percent = float(data.get("restore_mana_percent", 0.0))
	definition.set_id = str(data.get("set_id", ""))
	definition.class_effect_id = str(data.get("class_effect_id", ""))
	definition.class_bonus_class_code = str(data.get("class_bonus_class", ""))
	definition.class_bonus_attack = int(data.get("class_bonus_attack", 0))
	definition.class_bonus_defense = int(data.get("class_bonus_defense", 0))
	definition.class_bonus_max_hp = int(data.get("class_bonus_max_hp", 0))
	definition.class_bonus_max_mana = int(data.get("class_bonus_max_mana", 0))
	definition.class_bonus_dodge = float(data.get("class_bonus_dodge", 0.0))
	definition.fire_resistance = int(data.get("fire_resistance", 0))
	definition.wind_resistance = int(data.get("wind_resistance", 0))
	definition.frost_resistance = int(data.get("frost_resistance", 0))
	definition.earth_resistance = int(data.get("earth_resistance", 0))
	definition.water_resistance = int(data.get("water_resistance", 0))
	_cache[item_id] = definition
	return definition


static func get_all_definitions() -> Array:
	var result: Array = []
	for item_id: String in DEFINITIONS:
		result.append(get_definition(item_id))
	return result
