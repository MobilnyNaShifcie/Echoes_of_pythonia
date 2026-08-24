class_name EquipmentSetCatalog
extends RefCounted

const SETS := {
	"nature_guardian":
	{
		"display_name": "Zestaw Natury",
		"required_items":
		[
			"nature_amulet",
			"nature_ring",
			"nature_bracelet",
			"nature_earrings",
		],
		"bonuses":
		{
			"attack": 1,
			"defense": 2,
			"max_hp": 10,
			"earth_resistance": 15,
		},
	},
}


static func get_definition(set_id: String) -> Dictionary:
	return SETS.get(set_id, {})


static func active_sets(slots: Dictionary) -> Array[String]:
	var equipped_ids := {}
	for item in slots.values():
		if item != null:
			equipped_ids[item.item_id] = true
	var active: Array[String] = []
	for set_id: String in SETS:
		var definition: Dictionary = SETS[set_id]
		var complete := true
		for required_id: String in definition.required_items:
			if not equipped_ids.has(required_id):
				complete = false
				break
		if complete:
			active.append(set_id)
	return active


static func total_bonuses(slots: Dictionary) -> Dictionary:
	var result := {}
	for set_id in active_sets(slots):
		for stat_id: String in SETS[set_id].bonuses:
			result[stat_id] = result.get(stat_id, 0) + SETS[set_id].bonuses[stat_id]
	return result
