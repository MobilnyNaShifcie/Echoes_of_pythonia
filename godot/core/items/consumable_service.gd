class_name ConsumableService
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")


static func restorative_items_in_inventory(player) -> Array[String]:
	var item_ids: Array[String] = []
	for definition in ItemCatalogClass.get_all_definitions():
		if definition.category != "consumable" or not player.inventory.has(definition.item_id):
			continue
		if (
			definition.heal_hp > 0
			or definition.heal_hp_percent > 0.0
			or definition.restore_mana > 0
			or definition.restore_mana_percent > 0.0
		):
			item_ids.append(definition.item_id)
	return item_ids


## Read-only validation shared by the backpack and the combat action.
static func preview_use(player, item_id: String) -> Dictionary:
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null or definition.category != "consumable":
		return _failure("Wybrany przedmiot nie jest przedmiotem użytkowym.")
	if not player.inventory.has(item_id):
		return _failure("Nie posiadasz tego przedmiotu.")

	var missing_hp: int = maxi(0, player.stats.max_hp - player.stats.current_hp)
	var missing_mana: int = maxi(0, player.stats.max_mana - player.stats.current_mana)
	var hp_power: int = definition.heal_hp
	if definition.heal_hp_percent > 0.0:
		hp_power += maxi(
			1,
			MathClass.python_roundi(player.stats.max_hp * definition.heal_hp_percent / 100.0),
		)
	var mana_power: int = definition.restore_mana
	if definition.restore_mana_percent > 0.0 and player.stats.max_mana > 0:
		mana_power += maxi(
			1,
			MathClass.python_roundi(
				player.stats.max_mana * definition.restore_mana_percent / 100.0
			),
		)

	var healed_hp := mini(hp_power, missing_hp)
	var restored_mana := mini(mana_power, missing_mana)
	if healed_hp <= 0 and restored_mana <= 0:
		if definition.restore_mana > 0 or definition.restore_mana_percent > 0.0:
			return _failure("Masz już pełne PŻ i Manę.")
		return _failure("Masz już pełne PŻ.")

	return {
		"ok": true,
		"item_id": item_id,
		"healed_hp": healed_hp,
		"restored_mana": restored_mana,
	}


static func use(player, item_id: String) -> Dictionary:
	var preview := preview_use(player, item_id)
	if not preview.ok:
		return preview
	if not player.inventory.remove_item(item_id):
		return _failure("Nie posiadasz tego przedmiotu.")
	player.stats.current_hp += int(preview.healed_hp)
	player.stats.current_mana += int(preview.restored_mana)
	preview.message = "Użyto: %s." % ItemCatalogClass.get_definition(item_id).display_name
	return preview


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
