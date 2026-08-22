class_name ConsumableService
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")


static func use(player, item_id: String) -> Dictionary:
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

	player.stats.current_hp += healed_hp
	player.stats.current_mana += restored_mana
	player.inventory.remove_item(item_id)
	return {
		"ok": true,
		"message": "Użyto: %s." % definition.display_name,
		"item_id": item_id,
		"healed_hp": healed_hp,
		"restored_mana": restored_mana,
	}


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
