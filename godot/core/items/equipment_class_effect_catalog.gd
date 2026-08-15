class_name EquipmentClassEffectCatalog
extends RefCounted

# Descriptions intentionally preserve the terminal version's complete prose.
# gdlint: disable=max-line-length
const EFFECTS := {
	"warrior_retribution":
	{
		"display_name": "Odwet",
		"class_code": "warrior",
		"class_name": "Wojownik",
		"description":
		"Po użyciu Obrony następny podstawowy atak otrzymuje dodatkową siłę równą 50% twojego DEF.",
	},
	"hunter_predatory_instinct":
	{
		"display_name": "Drapieżny Odruch",
		"class_code": "hunter",
		"class_name": "Łowca",
		"description":
		"Po udanym uniku następny podstawowy atak zadaje +20% obrażeń i otrzymuje +10 p.p. szansy na trafienie krytyczne.",
	},
	"mage_mana_tide":
	{
		"display_name": "Przypływ Many",
		"class_code": "mage",
		"class_name": "Mag",
		"description":
		"Za każde 20 Many wydane na umiejętności odzyskujesz 5 Many. Postęp liczy się w obrębie jednej walki.",
	},
}
# gdlint: enable=max-line-length


static func get_definition(effect_id: String) -> Dictionary:
	return EFFECTS.get(effect_id, {})


static func is_active(player, effect_id: String) -> bool:
	var effect := get_definition(effect_id)
	if effect.is_empty() or player == null or player.character_class_code != effect.class_code:
		return false
	for item in player.equipment.slots.values():
		if item != null and item.definition.class_effect_id == effect_id:
			return true
	return false
