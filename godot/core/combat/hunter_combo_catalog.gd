class_name HunterComboCatalog
extends RefCounted

const HunterComboDefinitionClass := preload("res://core/combat/hunter_combo_definition.gd")
const TECHNIQUE_NAMES := {
	"blood": "Krwawa",
	"piercing": "Przebijająca",
	"frost": "Lodowa",
	"explosive": "Wybuchowa",
	"phantom": "Widmowa",
	"rain": "Deszcz Strzał",
	"splitting": "Rozszczepiająca",
}
const COMBO_ORDER := [
	"scarlet_execution",
	"brittle_burst",
	"phantom_detonation",
	"phantom_parade",
	"armor_storm",
	"bloody_echo",
]

static var _definitions := {
	"scarlet_execution":
	_combo(
		"scarlet_execution",
		"Szkarłatna Egzekucja",
		["blood", "blood", "blood"],
		"Pogłębia krwawienie i natychmiast zadaje dodatkowe obrażenia.",
		0.80,
		"physical",
		0.0,
		4,
		3,
	),
	"brittle_burst":
	_combo(
		"brittle_burst",
		"Kruche Rozerwanie",
		["frost", "frost", "explosive"],
		"Lód pęka wraz z ładunkiem i wywołuje mocną detonację.",
		1.45,
		"frost",
	),
	"phantom_detonation":
	_combo(
		"phantom_detonation",
		"Widmowa Detonacja",
		["explosive", "phantom", "explosive"],
		"Echo odpala wbite ładunki od środka.",
		1.35,
		"physical",
		0.0,
		0,
		0,
		true,
	),
	"phantom_parade":
	_combo(
		"phantom_parade",
		"Parada Widm",
		["phantom", "phantom", "phantom"],
		"Trzy echa materializują się jednocześnie i uderzają serię razy.",
		1.65,
	),
	"armor_storm":
	_combo(
		"armor_storm",
		"Burza Przebicia",
		["rain", "piercing", "splitting"],
		"Salwa zostaje rozszczepiona i przebija pancerz.",
		1.25,
		"physical",
		70.0,
	),
	"bloody_echo":
	_combo(
		"bloody_echo",
		"Szkarłatne Widmo",
		["blood", "phantom", "piercing"],
		"Widmowe echo otwiera ranę ponownie po przebiciu pancerza.",
		1.10,
		"physical",
		70.0,
		4,
		3,
	),
}


static func _combo(
	combo_id: String,
	display_name: String,
	sequence: Array[String],
	description: String,
	multiplier: float,
	damage_type := "physical",
	armor_penetration := 0.0,
	bleed_damage := 0,
	bleed_duration := 0,
	consumes_explosive_charges := false,
) -> HunterComboDefinitionClass:
	return (
		HunterComboDefinitionClass
		. new(
			{
				"combo_id": combo_id,
				"display_name": display_name,
				"sequence": sequence,
				"description": description,
				"multiplier": multiplier,
				"damage_type": damage_type,
				"armor_penetration": armor_penetration,
				"bleed_damage": bleed_damage,
				"bleed_duration": bleed_duration,
				"consumes_explosive_charges": consumes_explosive_charges,
			}
		)
	)


static func get_definition(combo_id: String) -> HunterComboDefinitionClass:
	return _definitions.get(combo_id)


static func get_all() -> Array[HunterComboDefinitionClass]:
	var result: Array[HunterComboDefinitionClass] = []
	for combo_id: String in COMBO_ORDER:
		result.append(_definitions[combo_id])
	return result


static func for_sequence(sequence: Array[String]) -> HunterComboDefinitionClass:
	for combo: HunterComboDefinitionClass in get_all():
		if combo.sequence == sequence:
			return combo
	return null


static func technique_name(technique: String) -> String:
	return str(TECHNIQUE_NAMES.get(technique, technique))


static func sequence_text(sequence: Array[String]) -> String:
	var names: Array[String] = []
	for technique: String in sequence:
		names.append(technique_name(technique))
	return " → ".join(names)


static func is_valid_combo_id(combo_id: String) -> bool:
	return _definitions.has(combo_id)
