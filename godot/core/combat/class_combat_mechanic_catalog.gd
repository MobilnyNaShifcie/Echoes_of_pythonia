class_name ClassCombatMechanicCatalog
extends RefCounted

const ClassCombatMechanicDefinitionClass := preload(
	"res://core/combat/class_combat_mechanic_definition.gd"
)
const CLASS_ORDER := {
	"warrior":
	[
		"warrior_retribution",
		"heavy_knight_core",
		"heavy_counter",
		"heavy_bastion",
	],
	"mage":
	[
		"mage_elemental_cycle",
		"arcana_core",
		"arcana_double_weave",
		"arcana_efficiency",
		"arcana_perfect_weave",
		"arcana_mana_cycle",
	],
}

static var _definitions := {
	"warrior_retribution":
	_mechanic(
		"warrior_retribution",
		"warrior",
		"Odwet",
		"Obrona przygotowuje podstawowy atak wzmocniony o 50% DEF.",
	),
	"heavy_knight_core":
	_mechanic(
		"heavy_knight_core",
		"warrior",
		"Przysięga Ciężkiego Rycerza",
		"Obrona z tarczą przygotowuje Odwet.",
	),
	"heavy_counter":
	_mechanic(
		"heavy_counter",
		"warrior",
		"Żelazna Kontra",
		"Blok tarczą zadaje przeciwnikowi obrażenia równe 70% DEF.",
	),
	"heavy_bastion":
	_mechanic(
		"heavy_bastion",
		"warrior",
		"Bastion",
		"Odwet przygotowany tarczą wykorzystuje 75% DEF zamiast 50%.",
	),
	"mage_elemental_cycle":
	_mechanic(
		"mage_elemental_cycle",
		"mage",
		"Cykl Żywiołów",
		"Trzeci różny żywioł z rzędu zyskuje 20% obrażeń.",
	),
	"arcana_core":
	_mechanic(
		"arcana_core",
		"mage",
		"Przysięga Arkanisty",
		"Każde zaklęcie buduje jeden punkt Splotu Magii, maksymalnie trzy.",
	),
	"arcana_double_weave":
	_mechanic(
		"arcana_double_weave",
		"mage",
		"Podwójny Splot",
		"Przy 3/3 Splotu pozwala rzucić dwa zaklęcia w jednej turze.",
	),
	"arcana_efficiency":
	_mechanic(
		"arcana_efficiency",
		"mage",
		"Oszczędny Splot",
		"Drugie zaklęcie Podwójnego Splotu kosztuje 25% mniej Many.",
	),
	"arcana_perfect_weave":
	_mechanic(
		"arcana_perfect_weave",
		"mage",
		"Perfekcyjny Splot",
		"Drugie zaklęcie Podwójnego Splotu działa z 95% zamiast 80% mocy.",
	),
	"arcana_mana_cycle":
	_mechanic(
		"arcana_mana_cycle",
		"mage",
		"Obieg Many",
		"Po Podwójnym Splocie odzyskuje cztery punkty Many.",
	),
}


static func _mechanic(
	mechanic_id: String, character_class_code: String, display_name: String, description: String
) -> ClassCombatMechanicDefinitionClass:
	return (
		ClassCombatMechanicDefinitionClass
		. new(
			{
				"mechanic_id": mechanic_id,
				"character_class_code": character_class_code,
				"display_name": display_name,
				"description": description,
			}
		)
	)


static func get_definition(mechanic_id: String) -> ClassCombatMechanicDefinitionClass:
	return _definitions.get(mechanic_id)


static func get_for_class(class_code: String) -> Array[ClassCombatMechanicDefinitionClass]:
	var result: Array[ClassCombatMechanicDefinitionClass] = []
	for mechanic_id: String in CLASS_ORDER.get(class_code, []):
		result.append(_definitions[mechanic_id])
	return result


static func is_valid_for_class(mechanic_id: String, class_code: String) -> bool:
	var definition: ClassCombatMechanicDefinitionClass = get_definition(mechanic_id)
	return definition != null and definition.character_class_code == class_code
