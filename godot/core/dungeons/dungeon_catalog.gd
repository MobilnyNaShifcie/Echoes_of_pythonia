class_name DungeonCatalog
extends RefCounted

# Narrative text intentionally preserves terminal v0.24.7 prose.
# gdlint: disable=max-line-length

const DungeonDefinitionClass := preload("res://core/dungeons/dungeon_definition.gd")
const DUNGEON_ORDER := ["sunken_order_crypt", "black_fleet_wreck"]

const DATA := {
	"sunken_order_crypt":
	{
		"display_name": "Krypta Zatopionego Zakonu",
		"description":
		"Pod ruinami mokradeł schodzą kamienne schody. Woda sączy się po ścianach, a na zatopionych płytach wciąż widać pieczęcie dawnego zakonu. To długa wyprawa: PŻ i Mana nie odnawiają się między komnatami.",
		"region_id": "silentwater_marshes",
		"recommended_level_min": 7,
		"recommended_level_max": 10,
		"room_one_enemies": ["drowned_dead", "drowned_acolyte", "sunken_knight"],
		"room_two_enemies": ["drowned_acolyte", "mist_walker", "swamp_witch"],
		"room_three_enemies": ["drowned_acolyte", "sunken_knight", "drowned_priestess"],
		"iron_path_enemy": "iron_gate_guardian",
		"flooded_ambush_enemy": "drowned_priestess",
		"flooded_ambush_chance": 0.45,
		"mandatory_elite_enemy": "crypt_warden",
		"boss_enemy": "order_grandmaster",
		"chest_loot":
		[
			{"item_id": "order_seal", "quantity": 1, "chance": 1.0},
			{"item_id": "drowned_coin", "quantity": 2, "chance": 1.0},
			{"item_id": "strong_healing_potion", "quantity": 1, "chance": 0.35},
		],
		"entry_item_id": "ancient_order_key",
		"entry_item_quantity": 1,
		"entry_source_text": "Matka Głuchej Wody, crafting lub zlecenie Gildii.",
		"scenes":
		{
			"room_one_title": "Zatopiony Przedsionek",
			"room_one": "Woda sięga kostek. Między sarkofagami porusza się cień.",
			"room_two_title": "Korytarz Pieczęci",
			"room_two": "Na ścianach wiszą zerwane herby. Ktoś wciąż ich pilnuje.",
			"room_three_title": "Galeria Utopionych",
			"room_three":
			"Kamienne figury stoją po obu stronach przejścia. Jedna z nich właśnie poruszyła głową.",
			"recovery_title": "Zatopiona Kaplica",
			"recovery":
			"W kamiennej misie wciąż lśni błękitna woda. Możesz skorzystać z niej tylko raz podczas tej wyprawy.",
			"elite_title": "Sala Łańcuchów — ELITA",
			"final_title": "Brama Wielkiego Mistrza",
			"final":
			"Za masywnymi drzwiami słychać metal przesuwany po kamieniu. To ostatni moment na odwrót.",
		}
	},
	"black_fleet_wreck":
	{
		"display_name": "Wrak Czarnej Floty",
		"description":
		"Całe cmentarzysko okrętów zostało skute lodem u brzegów północy. Połamane maszty sterczą ponad śniegiem, a czarne bandery wciąż wiszą nad wrakami Czarnej Floty. Gdzieś pośród nich czeka okręt flagowy Admirała Vareka. PŻ i Mana nie odnawiają się między starciami.",
		"region_id": "ice_coast",
		"recommended_level_min": 16,
		"recommended_level_max": 20,
		"room_one_enemies": ["cursed_sailor", "black_fleet_drowned", "spectral_marksman"],
		"room_two_enemies": ["cursed_sailor", "cursed_gunner", "black_fleet_drowned"],
		"room_three_enemies": ["cursed_gunner", "spectral_marksman", "black_fleet_boatswain"],
		"iron_path_enemy": "black_fleet_boatswain",
		"flooded_ambush_enemy": "cursed_gunner",
		"flooded_ambush_chance": 1.0,
		"mandatory_elite_enemy": "black_fleet_first_officer",
		"boss_enemy": "admiral_varek",
		"chest_loot":
		[
			{"item_id": "cursed_compass", "quantity": 2, "chance": 1.0},
			{"item_id": "black_pearl", "quantity": 1, "chance": 1.0},
			{"item_id": "leviathan_scale", "quantity": 1, "chance": 0.35},
			{"item_id": "grandmaster_elixir", "quantity": 1, "chance": 0.25},
		],
		"entry_item_id": "black_fleet_medallion",
		"entry_item_quantity": 1,
		"entry_source_text": "Widmo Kapitana Statku lub crafting.",
		"scenes":
		{
			"entrance":
			"Przed tobą rozciąga się cmentarzysko okrętów skute lodem. Połamane maszty sterczą z białej równiny niczym nagrobki, a między kadłubami słychać skrzypienie drewna poruszanego przez wiatr.\n\nNa największym z wraków wciąż powiewa czarna bandera. Medalion Czarnej Floty robi się lodowato zimny w twojej dłoni.",
			"room_one_title": "Zamarznięty Pokład",
			"room_one":
			"Stawiasz stopę na zamarzniętym pokładzie pierwszego wraku. Drewno jęczy pod grubą warstwą lodu, choć morze wokół pozostaje nieruchome.\n\nZ wnętrza okrętu dochodzą powolne kroki. Ktoś nadal pełni tu wachtę.",
			"room_two_title": "Przejście między Wrakami",
			"room_two":
			"Zerwane maszty tworzą chwiejne przejście nad czarną wodą. Pod lodem widać sylwetki kolejnych statków, które nigdy nie dotarły do brzegu.\n\nNa sąsiednim pokładzie porusza się cień, a potem znika za rozdartym żaglem Czarnej Floty.",
			"cargo_hold":
			"Schodzisz głęboko pod pokład. Zamarznięta woda pokrywa podłogę, a w lodzie tkwią beczki, skrzynie i szczątki dawnej załogi.\n\nGdzieś dalej naprężony łańcuch przesuwa się po drewnie. Sam.",
			"upper_deck":
			"Wychodzisz na otwarty pokład. Wiatr natychmiast uderza w twarz drobnym lodem, a widoczność między wrakami niemal znika.\n\nPrzez zamieć dostrzegasz błysk lontu. Ktoś przy jednym z dział właśnie zajął pozycję.",
			"room_three_title": "Kajuty Oficerskie",
			"room_three":
			"Drzwi kajut noszą wyblakłe stopnie i nazwiska. Na ścianach wciąż wiszą mapy morskie, całe pokryte szronem.\n\nNa jednym ze stołów leży otwarty dziennik pokładowy. Ostatni wpis urywa się w połowie zdania. Z sąsiedniej kajuty dobiega odgłos odsuwanego krzesła.",
			"recovery_title": "Kajuta Medyka",
			"recovery":
			"Na drzwiach wciąż można odczytać wyblakły znak medyka okrętowego. W środku ocalały zapasy, bandaże i niewielki piecyk, w którym pod warstwą popiołu wciąż tli się żar. To pierwsze ciepłe miejsce od wejścia do wraków. Możesz odpocząć tutaj tylko raz podczas tej wyprawy.",
			"elite_title": "Okręt Flagowy — PIERWSZY OFICER",
			"elite":
			"Powolne kroki odbijają się echem po korytarzu.\n\nZ ciemności wyłania się wysoka postać w zniszczonym mundurze. Na jego ramionach wciąż widać oznaczenia Czarnej Floty, a widmowa dłoń spoczywa na rękojeści szabli.\n\n— Admirał nie przyjmuje gości.",
			"final_title": "Okręt Flagowy",
			"final":
			"Przed tobą wyrasta największy ze wszystkich wraków — okręt flagowy. Jego kadłub jest niemal całkowicie skuty czarnym lodem, lecz wygląda, jakby mimo upływu lat wciąż czekał na rozkaz wypłynięcia.\n\nNa burcie widnieje znak Czarnej Floty. Gdzieś wysoko rozlega się dźwięk okrętowego dzwonu.\n\nJeden raz.\nDrugi.\nTrzeci.",
			"boss_title": "Pokład Admiralski",
			"boss":
			"Drzwi kabiny admirała otwierają się bez niczyjego dotyku. Na pokład wychodzi mężczyzna w czarnym mundurze, którego ciało dawno powinno obrócić się w proch. W jego oczach płonie blade światło.\n\nAdmirał Varek spogląda na skute lodem okręty, a potem powoli wyciąga szablę. Wokół dział zaczynają materializować się widmowi kanonierzy.\n\n— Moja flota jeszcze nie zatonęła.",
		}
	},
}


static func get_definition(dungeon_id: String) -> DungeonDefinitionClass:
	if not DATA.has(dungeon_id):
		return null
	var data: Dictionary = DATA[dungeon_id].duplicate(true)
	data.dungeon_id = dungeon_id
	return DungeonDefinitionClass.new(data)


static func dungeon_for_region(region_id: String) -> DungeonDefinitionClass:
	for dungeon_id: String in DUNGEON_ORDER:
		var definition := get_definition(dungeon_id)
		if definition.region_id == region_id:
			return definition
	return null


static func is_valid_id(dungeon_id: String) -> bool:
	return dungeon_id in DUNGEON_ORDER
