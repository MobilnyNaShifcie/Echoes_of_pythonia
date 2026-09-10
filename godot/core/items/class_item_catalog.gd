class_name ClassItemCatalog
extends RefCounted

const ItemDefinitionClass := preload("res://core/items/item_definition.gd")
const CLASS_ICONS := {
	"echo_quiver": preload("res://assets/items/regional/echo_quiver.png"),
	"weave_relic": preload("res://assets/items/regional/weave_relic.png"),
	"trickster_card_deck": preload("res://assets/items/regional/trickster_card_deck.png"),
	"rift_bastion_shield": preload("res://assets/items/regional/rift_bastion_shield.png"),
	"last_guard_plate": preload("res://assets/items/regional/last_guard_plate.png"),
	"oathbreaker_edge": preload("res://assets/items/regional/oathbreaker_edge.png"),
	"warden_chain": preload("res://assets/items/regional/warden_chain.png"),
	"third_echo_quiver": preload("res://assets/items/regional/third_echo_quiver.png"),
	"riftglass_bow": preload("res://assets/items/regional/riftglass_bow.png"),
	"silent_volley_cloak": preload("res://assets/items/regional/silent_volley_cloak.png"),
	"afterimage_ring": preload("res://assets/items/regional/afterimage_ring.png"),
	"split_weave_artifact": preload("res://assets/items/regional/split_weave_artifact.png"),
	"twin_star_staff": preload("res://assets/items/regional/twin_star_staff.png"),
	"empty_mana_robe": preload("res://assets/items/regional/empty_mana_robe.png"),
	"storm_archive_relic": preload("res://assets/items/regional/storm_archive_relic.png"),
	"two_lies_dice": preload("res://assets/items/regional/two_lies_dice.png"),
	"deck_without_ace": preload("res://assets/items/regional/deck_without_ace.png"),
	"seven_chances_lance": preload("res://assets/items/regional/seven_chances_lance.png"),
	"crooked_smile_mask": preload("res://assets/items/regional/crooked_smile_mask.png"),
	"varek_sabre": preload("res://assets/items/regional/varek_sabre.png"),
	"black_sea_bow": preload("res://assets/items/regional/black_sea_bow.png"),
	"black_sea_staff": preload("res://assets/items/regional/black_sea_staff.png"),
	"black_tide_fate_lance": preload("res://assets/items/regional/black_tide_fate_lance.png"),
	"hearthguard_shield": preload("res://assets/items/regional/hearthguard_shield.png"),
	"order_bracelet": preload("res://assets/items/regional/order_bracelet.png"),
	"abyss_ring": preload("res://assets/items/regional/abyss_ring.png"),
	"mireglass_bow": preload("res://assets/items/regional/mireglass_bow.png"),
	"mire_staff": preload("res://assets/items/regional/mire_staff.png"),
	"drowned_fate_lance": preload("res://assets/items/regional/drowned_fate_lance.png"),
	"ashwind_bow": preload("res://assets/items/regional/ashwind_bow.png"),
	"ember_staff": preload("res://assets/items/regional/ember_staff.png"),
	"ashen_fate_lance": preload("res://assets/items/regional/ashen_fate_lance.png"),
	"blackwood_longbow": preload("res://assets/items/regional/blackwood_longbow.png"),
	"blackwood_staff": preload("res://assets/items/regional/blackwood_staff.png"),
	"crooked_fate_lance": preload("res://assets/items/regional/crooked_fate_lance.png"),
}

# Class progression and Rift uniques used by companion builds in terminal v0.24.7.
# They stay in a dedicated catalog because they are neither starter resources nor
# ordinary regional loot owned by the Stage 5 migration.
static var _definitions := {
	"varek_sabre": _item("Szabla Admirała Vareka", "legendary", "weapon", 7, 20, {"attack": 24}),
	"blackwood_longbow":
	_item(
		"Łuk Czarnego Boru",
		"uncommon",
		"weapon",
		2,
		5,
		{"equipment_type": "bow", "required_class": "hunter", "attack": 7}
	),
	"blackwood_staff":
	_item(
		"Kostur Czarnego Boru",
		"uncommon",
		"weapon",
		2,
		5,
		{
			"equipment_type": "staff",
			"required_class": "mage",
			"magic_power": 7,
			"max_mana": 4,
		}
	),
	"crooked_fate_lance":
	_item(
		"Lanca Krzywego Losu",
		"uncommon",
		"weapon",
		2,
		5,
		{"equipment_type": "fate_lance", "required_class": "pierrot", "attack": 7}
	),
	"mireglass_bow":
	_item(
		"Łuk Mglistej Toni",
		"rare",
		"weapon",
		3,
		8,
		{"equipment_type": "bow", "required_class": "hunter", "attack": 10}
	),
	"mire_staff":
	_item(
		"Kostur Głuchej Wody",
		"rare",
		"weapon",
		3,
		8,
		{
			"equipment_type": "staff",
			"required_class": "mage",
			"magic_power": 10,
			"max_mana": 7,
		}
	),
	"drowned_fate_lance":
	_item(
		"Lanca Utopionego Zakładu",
		"rare",
		"weapon",
		3,
		8,
		{"equipment_type": "fate_lance", "required_class": "pierrot", "attack": 10}
	),
	"ashwind_bow":
	_item(
		"Łuk Popielnego Wiatru",
		"rare",
		"weapon",
		5,
		13,
		{"equipment_type": "bow", "required_class": "hunter", "attack": 18}
	),
	"ember_staff":
	_item(
		"Kostur Popielnego Żaru",
		"rare",
		"weapon",
		5,
		13,
		{
			"equipment_type": "staff",
			"required_class": "mage",
			"magic_power": 15,
			"max_mana": 11,
		}
	),
	"ashen_fate_lance":
	_item(
		"Lanca Popielnego Hazardu",
		"rare",
		"weapon",
		5,
		13,
		{"equipment_type": "fate_lance", "required_class": "pierrot", "attack": 18}
	),
	"black_sea_bow":
	_item(
		"Łuk Czarnego Morza",
		"epic",
		"weapon",
		6,
		17,
		{"equipment_type": "bow", "required_class": "hunter", "attack": 21}
	),
	"black_sea_staff":
	_item(
		"Kostur Czarnego Morza",
		"epic",
		"weapon",
		6,
		17,
		{
			"equipment_type": "staff",
			"required_class": "mage",
			"magic_power": 19,
			"max_mana": 15,
		}
	),
	"black_tide_fate_lance":
	_item(
		"Lanca Czarnego Losu",
		"epic",
		"weapon",
		6,
		17,
		{"equipment_type": "fate_lance", "required_class": "pierrot", "attack": 21}
	),
	"hearthguard_shield":
	_item(
		"Tarcza Straży Paleniska",
		"rare",
		"off_hand",
		5,
		14,
		{
			"equipment_type": "shield",
			"required_class": "warrior",
			"defense": 7,
			"max_hp": 35,
		}
	),
	"echo_quiver":
	_item(
		"Kołczan Echa",
		"rare",
		"off_hand",
		5,
		14,
		{
			"equipment_type": "quiver",
			"required_class": "hunter",
			"attack": 3,
			"dodge": 3.0,
		}
	),
	"weave_relic":
	_item(
		"Relikwiarz Splotu",
		"rare",
		"off_hand",
		5,
		14,
		{
			"equipment_type": "artifact",
			"required_class": "mage",
			"magic_power": 5,
			"max_mana": 16,
		}
	),
	"trickster_card_deck":
	_item(
		"Talia Oszusta",
		"rare",
		"off_hand",
		5,
		14,
		{
			"equipment_type": "fate_cards",
			"required_class": "pierrot",
			"max_mana": 10,
			"dodge": 2.0,
		}
	),
	"order_bracelet":
	_item(
		"Bransoleta Zakonu",
		"rare",
		"bracelet",
		4,
		10,
		{
			"description":
			(
				"Ciężka bransoleta nosząca zatarty znak Zatopionego Zakonu. "
				+ "Wciąż przewodzi energię dawnych pieczęci."
			),
			"attack": 4,
			"max_mana": 16,
		}
	),
	"abyss_ring":
	_item(
		"Pierścień Głębin",
		"epic",
		"ring",
		4,
		10,
		{
			"description":
			"Pierścień wykuty z fragmentu korony. Wzmacnia Manę i chroni przed wodną magią.",
			"attack": 2,
			"max_mana": 20,
		}
	),
	"rift_bastion_shield":
	_item(
		"Tarcza Pękniętego Bastionu",
		"legendary",
		"off_hand",
		7,
		18,
		{
			"equipment_type": "shield",
			"required_class": "warrior",
			"defense": 11,
			"max_hp": 70,
			"class_effect_id": "rift_bastion_memory",
		}
	),
	"last_guard_plate":
	_item(
		"Napierśnik Ostatniej Straży",
		"legendary",
		"chest",
		7,
		18,
		{
			"defense": 16,
			"max_hp": 110,
			"class_bonus_class": "warrior",
			"class_bonus_defense": 7,
			"class_bonus_max_hp": 80,
			"class_effect_id": "last_guard",
		}
	),
	"oathbreaker_edge":
	_item(
		"Ostrze Złamanej Przysięgi",
		"legendary",
		"weapon",
		7,
		18,
		{
			"equipment_type": "sword",
			"required_class": "warrior",
			"attack": 29,
			"class_effect_id": "oathbreaker_bleed",
		}
	),
	"warden_chain":
	_item(
		"Łańcuch Strażnika Szczeliny",
		"epic",
		"bracelet",
		7,
		18,
		{
			"attack": 3,
			"class_bonus_class": "warrior",
			"class_bonus_defense": 8,
			"class_bonus_max_hp": 45,
			"class_effect_id": "warden_afterguard",
		}
	),
	"third_echo_quiver":
	_item(
		"Kołczan Trzeciego Echa",
		"legendary",
		"off_hand",
		7,
		18,
		{
			"equipment_type": "quiver",
			"required_class": "hunter",
			"attack": 6,
			"dodge": 4.0,
			"class_effect_id": "third_echo",
		}
	),
	"riftglass_bow":
	_item(
		"Łuk ze Szkła Szczeliny",
		"legendary",
		"weapon",
		7,
		18,
		{
			"equipment_type": "bow",
			"required_class": "hunter",
			"attack": 28,
			"class_effect_id": "riftglass_echo",
		}
	),
	"silent_volley_cloak":
	_item(
		"Płaszcz Bezgłośnej Salwy",
		"legendary",
		"chest",
		7,
		18,
		{
			"defense": 8,
			"max_hp": 65,
			"dodge": 4.0,
			"class_bonus_class": "hunter",
			"class_bonus_dodge": 4.0,
			"class_effect_id": "silent_volley",
		}
	),
	"afterimage_ring":
	_item(
		"Pierścień Powidoku",
		"epic",
		"ring",
		7,
		18,
		{
			"attack": 4,
			"max_mana": 8,
			"class_bonus_class": "hunter",
			"class_bonus_dodge": 2.0,
			"class_effect_id": "afterimage_mana",
		}
	),
	"split_weave_artifact":
	_item(
		"Artefakt Rozszczepionego Splotu",
		"legendary",
		"off_hand",
		7,
		18,
		{
			"equipment_type": "artifact",
			"required_class": "mage",
			"magic_power": 10,
			"max_mana": 24,
			"class_effect_id": "split_weave",
		}
	),
	"twin_star_staff":
	_item(
		"Kostur Dwóch Gwiazd",
		"legendary",
		"weapon",
		7,
		18,
		{
			"equipment_type": "staff",
			"required_class": "mage",
			"magic_power": 27,
			"max_mana": 14,
			"class_effect_id": "twin_star",
		}
	),
	"empty_mana_robe":
	_item(
		"Szata Wyczerpanej Many",
		"legendary",
		"chest",
		7,
		18,
		{
			"defense": 6,
			"max_hp": 45,
			"class_bonus_class": "mage",
			"class_bonus_max_mana": 48,
			"class_effect_id": "empty_mana_power",
		}
	),
	"storm_archive_relic":
	_item(
		"Medalion Burzowego Archiwum",
		"epic",
		"necklace",
		7,
		18,
		{
			"magic_power": 7,
			"max_mana": 16,
			"class_bonus_class": "mage",
			"class_bonus_max_mana": 12,
			"class_effect_id": "storm_archive_refund",
		}
	),
	"two_lies_dice":
	_item(
		"Kości Dwóch Kłamstw",
		"legendary",
		"off_hand",
		7,
		18,
		{
			"equipment_type": "fate_dice",
			"required_class": "pierrot",
			"dodge": 4.0,
			"max_mana": 12,
			"class_effect_id": "two_lies",
		}
	),
	"deck_without_ace":
	_item(
		"Talia Bez Asa",
		"legendary",
		"off_hand",
		7,
		18,
		{
			"equipment_type": "fate_cards",
			"required_class": "pierrot",
			"dodge": 5.0,
			"max_mana": 16,
			"class_effect_id": "ace_less_deck",
		}
	),
	"seven_chances_lance":
	_item(
		"Lanca Siedmiu Przypadków",
		"mythic",
		"weapon",
		7,
		18,
		{
			"equipment_type": "fate_lance",
			"required_class": "pierrot",
			"attack": 30,
			"class_effect_id": "seven_chances",
		}
	),
	"crooked_smile_mask":
	_item(
		"Maska Krzywego Uśmiechu",
		"legendary",
		"head",
		7,
		18,
		{
			"defense": 5,
			"max_hp": 35,
			"dodge": 3.0,
			"class_bonus_class": "pierrot",
			"class_bonus_dodge": 3.0,
			"class_effect_id": "crooked_smile",
		}
	),
}

static var _cache := {}


static func get_definition(item_id: String) -> ItemDefinitionClass:
	if _cache.has(item_id):
		return _cache[item_id]
	var data: Dictionary = _definitions.get(item_id, {})
	if data.is_empty():
		return null
	var definition := ItemDefinitionClass.new()
	definition.item_id = item_id
	definition.display_name = str(data.name)
	definition.description = str(data.description)
	definition.category = "equipment"
	definition.rarity = str(data.rarity)
	definition.slot = str(data.slot)
	definition.equipment_type = str(data.get("equipment_type", ""))
	definition.item_power = int(data.item_power)
	definition.required_level = int(data.required_level)
	definition.icon = CLASS_ICONS.get(item_id)
	definition.required_class_code = str(data.get("required_class", ""))
	definition.required_class_name = _class_name(definition.required_class_code)
	definition.attack = int(data.get("attack", 0))
	definition.defense = int(data.get("defense", 0))
	definition.max_hp = int(data.get("max_hp", 0))
	definition.dodge = float(data.get("dodge", 0.0))
	definition.max_mana = int(data.get("max_mana", 0))
	definition.magic_power = int(data.get("magic_power", 0))
	definition.class_effect_id = str(data.get("class_effect_id", ""))
	definition.class_bonus_class_code = str(data.get("class_bonus_class", ""))
	definition.class_bonus_attack = int(data.get("class_bonus_attack", 0))
	definition.class_bonus_defense = int(data.get("class_bonus_defense", 0))
	definition.class_bonus_max_hp = int(data.get("class_bonus_max_hp", 0))
	definition.class_bonus_max_mana = int(data.get("class_bonus_max_mana", 0))
	definition.class_bonus_dodge = float(data.get("class_bonus_dodge", 0.0))
	_cache[item_id] = definition
	return definition


static func get_all_definitions() -> Array:
	var result := []
	for item_id: String in _definitions:
		result.append(get_definition(item_id))
	return result


static func _item(
	name: String, rarity: String, slot: String, item_power: int, required_level: int, extra := {}
) -> Dictionary:
	var data := {
		"name": name,
		"description": "Osobiste wyposażenie kompana, zgodne z terminalową v0.24.7.",
		"rarity": rarity,
		"slot": slot,
		"item_power": item_power,
		"required_level": required_level,
	}
	data.merge(extra, true)
	return data


static func _class_name(class_code: String) -> String:
	match class_code:
		"warrior":
			return "Wojownik"
		"hunter":
			return "Łowca"
		"mage":
			return "Mag"
		"pierrot":
			return "Pierrot"
	return ""
