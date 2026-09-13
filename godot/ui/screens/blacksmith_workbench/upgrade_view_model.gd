extends RefCounted
## UI selection/preview adapter. Costs, scaling and the transaction belong to UpgradeService.
const Upgrades := preload("res://core/economy/upgrade_service.gd")
const Item := preload("res://core/items/equipment_item.gd")
const Affixes := preload("res://core/items/equipment_affix_service.gd")
const Catalog := preload("res://core/items/item_catalog.gd")
const STAT_NAMES := {
	"attack": "Atak",
	"defense": "Obrona",
	"max_hp": "Maks. PŻ",
	"max_mana": "Maks. mana",
	"magic_power": "Moc magiczna",
	"dodge": "Unik",
}

var session
var selected_id := ""
var target_level := 1


static func resolve(player, instance_id: String) -> Dictionary:
	if instance_id.is_empty():
		return {}
	for slot: String in player.equipment.slots:
		var item = player.equipment.get_item(slot)
		if item != null and item.instance_id == instance_id:
			return {"item": item, "source": "Założone", "slot": slot}
	for item in player.inventory.equipment_items:
		if item.instance_id == instance_id:
			return {"item": item, "source": "Plecak", "slot": ""}
	return {}


static func payload(item) -> Dictionary:
	return {"kind": "upgrade_equipment", "instance_id": item.instance_id}


func selection() -> Dictionary:
	return resolve(session.player, selected_id) if session != null else {}


func accepts(data: Variant) -> bool:
	if session == null or not data is Dictionary:
		return false
	if data.get("kind") != "upgrade_equipment":
		return false
	var entry := resolve(session.player, str(data.get("instance_id", "")))
	return not entry.is_empty() and entry.item.definition.is_equipment()


func select(data: Dictionary) -> bool:
	if not accepts(data):
		return false
	selected_id = str(data.instance_id)
	target_level = mini(Upgrades.MAX_UPGRADE_LEVEL, selection().item.upgrade_level + 1)
	return true


func set_target(level: int) -> void:
	var entry := selection()
	if entry.is_empty():
		return
	target_level = clampi(level, mini(10, entry.item.upgrade_level + 1), 10)


func plan() -> Dictionary:
	var entry := selection()
	if entry.is_empty():
		return {"ok": false}
	return Upgrades.get_upgrade_plan(entry.item, target_level - entry.item.upgrade_level)


func error() -> String:
	var entry := selection()
	if entry.is_empty():
		return "Wybierz przedmiot do ulepszenia."
	if entry.item.upgrade_level == Upgrades.MAX_UPGRADE_LEVEL:
		return "Maksymalny poziom"
	return Upgrades.get_upgrade_error(
		session.player, entry.item, target_level - entry.item.upgrade_level
	)


func requirements() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	var current_plan := plan()
	if not current_plan.ok:
		return result
	for item_id: String in current_plan.materials:
		var definition = Catalog.get_definition(item_id)
		(
			result
			. append(
				{
					"id": item_id,
					"name": definition.display_name,
					"icon": definition.icon,
					"owned": session.player.inventory.count(item_id),
					"required": int(current_plan.materials[item_id]),
				}
			)
		)
	(
		result
		. insert(
			mini(1, result.size()),
			{
				"id": "gold",
				"name": "Złoto",
				"icon": null,
				"owned": session.player.gold,
				"required": int(current_plan.gold),
			}
		)
	)
	return result


func comparison() -> Array[Dictionary]:
	var entry := selection()
	var result: Array[Dictionary] = []
	if entry.is_empty() or not plan().ok:
		return result
	var item = entry.item
	# Detached, read-only preview: never change the live instance, even temporarily.
	var preview := Item.new(
		item.definition, target_level, item.affixes, item.item_power, item.average_damage_percent
	)
	var before := Upgrades.effective_stats(item)
	var after := Upgrades.effective_stats(preview)
	var bonuses := Affixes.bonuses_for(item)
	for stat: String in STAT_NAMES:
		var delta := float(after[stat]) - float(before[stat])
		if is_zero_approx(delta):
			continue
		var bonus := float(bonuses.get(stat, 0.0))
		if stat != "dodge":
			bonus = roundf(bonus)
		if item.definition.class_bonus_class_code == session.player.character_class_code:
			var property := "class_bonus_" + stat
			var class_bonus = item.definition.get(property)
			if class_bonus != null:
				bonus += float(class_bonus)
		(
			result
			. append(
				{
					"stat": stat,
					"name": STAT_NAMES[stat],
					"before": float(before[stat]) + bonus,
					"after": float(after[stat]) + bonus,
					"delta": delta,
				}
			)
		)
	return result


func execute() -> Dictionary:
	# Re-resolve ownership and affordability at confirmation, not only during selection.
	var blocked := error()
	if not blocked.is_empty():
		return {"ok": false, "message": blocked}
	var item = selection().item
	return Upgrades.upgrade_item(session.player, item, target_level - item.upgrade_level, session)
