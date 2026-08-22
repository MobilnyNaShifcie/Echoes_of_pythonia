class_name PlayerEquipment
extends RefCounted

const EquipmentItemClass := preload("res://core/items/equipment_item.gd")
const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const EquipmentSetCatalogClass := preload("res://core/items/equipment_set_catalog.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")

const WEAPON := "weapon"
const HEAD := "head"
const CHEST := "chest"
const HANDS := "hands"
const FEET := "feet"
const BELT := "belt"
const NECKLACE := "necklace"
const BRACELET := "bracelet"
const EARRINGS := "earrings"
const RING := "ring"
const OFF_HAND := "off_hand"

var slots := {}


func equip_and_return_previous(item: EquipmentItemClass) -> EquipmentItemClass:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return null
	var previous: EquipmentItemClass = slots.get(item.slot)
	slots[item.slot] = item
	return previous


func unequip(slot: String) -> EquipmentItemClass:
	var item: EquipmentItemClass = slots.get(slot)
	slots.erase(slot)
	return item


func get_item(slot: String) -> EquipmentItemClass:
	return slots.get(slot)


func total_bonuses(character_class_code := "") -> Dictionary:
	var bonuses := {
		"attack": 0,
		"defense": 0,
		"max_hp": 0,
		"dodge": 0.0,
		"max_mana": 0,
		"magic_power": 0,
		"health_regen": 0,
		"crit_chance": 0.0,
		"crit_damage": 0.0,
		"skill_damage": 0.0,
		"armor_penetration": 0.0,
		"damage_vs_elite": 0.0,
		"damage_vs_boss": 0.0,
		"average_damage": 0.0,
		"elemental_resistances": ElementalResistancesClass.new(),
		"active_set_names": [],
	}
	for item: EquipmentItemClass in slots.values():
		var stats := UpgradeServiceClass.effective_stats(item)
		var affix_bonuses := EquipmentAffixServiceClass.bonuses_for(item)
		bonuses.attack += stats.attack
		bonuses.defense += stats.defense
		bonuses.max_hp += stats.max_hp
		bonuses.dodge += stats.dodge
		bonuses.max_mana += stats.max_mana
		bonuses.magic_power += stats.magic_power
		bonuses.attack += roundi(affix_bonuses.get("attack", 0.0))
		bonuses.defense += roundi(affix_bonuses.get("defense", 0.0))
		bonuses.max_hp += roundi(affix_bonuses.get("max_hp", 0.0))
		bonuses.dodge += affix_bonuses.get("dodge", 0.0)
		bonuses.max_mana += roundi(affix_bonuses.get("max_mana", 0.0))
		bonuses.health_regen += roundi(affix_bonuses.get("health_regen", 0.0))
		bonuses.crit_chance += affix_bonuses.get("crit_chance", 0.0)
		bonuses.crit_damage += affix_bonuses.get("crit_damage", 0.0)
		bonuses.skill_damage += affix_bonuses.get("skill_damage", 0.0)
		bonuses.armor_penetration += affix_bonuses.get("armor_penetration", 0.0)
		bonuses.damage_vs_elite += affix_bonuses.get("damage_vs_elite", 0.0)
		bonuses.damage_vs_boss += affix_bonuses.get("damage_vs_boss", 0.0)
		var definition = item.definition
		if definition.class_bonus_class_code == character_class_code:
			bonuses.attack += definition.class_bonus_attack
			bonuses.defense += definition.class_bonus_defense
			bonuses.max_hp += definition.class_bonus_max_hp
			bonuses.max_mana += definition.class_bonus_max_mana
			bonuses.dodge += definition.class_bonus_dodge
		if item.average_damage_percent != null:
			bonuses.average_damage += float(item.average_damage_percent)
		var item_resistances := {
			"fire": definition.fire_resistance + roundi(affix_bonuses.get("fire_resistance", 0.0)),
			"wind": definition.wind_resistance + roundi(affix_bonuses.get("wind_resistance", 0.0)),
			"frost":
			definition.frost_resistance + roundi(affix_bonuses.get("frost_resistance", 0.0)),
			"earth":
			definition.earth_resistance + roundi(affix_bonuses.get("earth_resistance", 0.0)),
			"water":
			definition.water_resistance + roundi(affix_bonuses.get("water_resistance", 0.0)),
		}
		for damage_type: String in ElementalResistancesClass.ELEMENT_ORDER:
			var total: int = (
				bonuses.elemental_resistances.get_value(damage_type)
				+ int(item_resistances[damage_type])
			)
			bonuses.elemental_resistances.set_value(damage_type, total)
	var set_bonuses := EquipmentSetCatalogClass.total_bonuses(slots)
	for stat_id: String in ["attack", "defense", "max_hp", "max_mana"]:
		bonuses[stat_id] += int(set_bonuses.get(stat_id, 0))
	bonuses.dodge += float(set_bonuses.get("dodge", 0.0))
	for damage_type: String in ElementalResistancesClass.ELEMENT_ORDER:
		var resistance_id := "%s_resistance" % damage_type
		bonuses.elemental_resistances.set_value(
			damage_type,
			(
				bonuses.elemental_resistances.get_value(damage_type)
				+ int(set_bonuses.get(resistance_id, 0))
			)
		)
	for set_id: String in EquipmentSetCatalogClass.active_sets(slots):
		bonuses.active_set_names.append(
			EquipmentSetCatalogClass.get_definition(set_id).display_name
		)
	for stat_id: String in [
		"dodge",
		"crit_chance",
		"crit_damage",
		"skill_damage",
		"armor_penetration",
		"damage_vs_elite",
		"damage_vs_boss",
		"average_damage",
	]:
		bonuses[stat_id] = snappedf(float(bonuses[stat_id]), 0.1)
	return bonuses
