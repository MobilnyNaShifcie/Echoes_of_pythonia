class_name PlayerProfile
extends RefCounted

const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const AchievementBookClass := preload("res://core/progression/achievement_book.gd")
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerInventoryClass := preload("res://core/player/inventory.gd")
const PrimaryStatsClass := preload("res://core/player/primary_stats.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const EquipmentClassEffectCatalogClass := preload(
	"res://core/items/equipment_class_effect_catalog.gd"
)
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const STARTING_LEVEL := 0
const ATTRIBUTE_POINTS_PER_LEVEL := 4
const CLASS_NONE := "none"
const CLASS_PIERROT := "pierrot"

var display_name: String
var level := STARTING_LEVEL
var experience := 0
var gold := 0
var rubies := 0
var unspent_attribute_points := 0
var character_class_code := CLASS_NONE
var carry_upgrade_level := 0
var unlocked_talent_skill_ids: Array[String] = []
var unlocked_class_mechanic_ids: Array[String] = []
var discovered_hunter_combos: Array[String] = []
var talent_ranks := {}
var unlocked_class_path_ids: Array[String] = []
var passive_ranks := {}
var unlocked_passive_mastery_ids: Array[String] = []
var passive_specialization_ids := {}
var achievement_book := AchievementBookClass.new()
var attributes := PlayerAttributesClass.new()
var stats := PrimaryStatsClass.new()
var equipment := PlayerEquipmentClass.new()
var inventory := PlayerInventoryClass.new()

var health: int:
	get:
		return stats.current_hp

var max_health: int:
	get:
		return stats.max_hp

var weapon_id: String:
	get:
		return get_equipped_item_id(PlayerEquipmentClass.WEAPON)

var armor_id: String:
	get:
		return get_equipped_item_id(PlayerEquipmentClass.CHEST)

var character_class_name: String:
	get:
		var definition = PlayerClassCatalogClass.get_definition(character_class_code)
		return definition.display_name if definition != null else character_class_code

var can_choose_class: bool:
	get:
		return level >= 5 and character_class_code == CLASS_NONE


func _init(player_name: String) -> void:
	display_name = player_name


func titled_display_name() -> String:
	return "[%s] %s" % [achievement_book.equipped_title, display_name]


func experience_to_next_level() -> int:
	var next_level := level + 1
	return int(50 * pow(next_level, 1.5))


func experience_remaining_to_next_level() -> int:
	return experience_to_next_level() - experience


func gain_experience(amount: int) -> int:
	if amount < 0:
		return 0
	experience += amount
	var levels_gained := 0
	while experience >= experience_to_next_level():
		experience -= experience_to_next_level()
		level += 1
		unspent_attribute_points += ATTRIBUTE_POINTS_PER_LEVEL
		levels_gained += 1
	return levels_gained


func add_gold(amount: int) -> bool:
	if amount < 0:
		return false
	gold += amount
	return true


func get_class_choice_error(class_code: String) -> String:
	if not PlayerClassCatalogClass.is_valid_code(class_code) or class_code == CLASS_NONE:
		return "Nieznana Droga bohatera."
	if character_class_code != CLASS_NONE:
		return "Droga została już wybrana: %s." % character_class_name
	if level < 5:
		return "Drogę bohatera można wybrać od poziomu 5."
	return ""


func choose_class(class_code: String) -> bool:
	if not get_class_choice_error(class_code).is_empty():
		return false
	character_class_code = class_code
	var definition = PlayerClassCatalogClass.get_definition(class_code)
	for item_id: String in definition.starter_equipment_ids:
		if inventory.count(item_id) > 0:
			continue
		var item = ItemCatalogClass.create_equipment_item(item_id)
		var previous = equipment.equip_and_return_previous(item)
		if previous != null:
			inventory.add_equipment_instance(previous)
	recalculate_stats()
	stats.current_mana = stats.max_mana
	return true


func get_attribute_spend_error(attribute_code: String, amount := 1) -> String:
	if amount <= 0:
		return "Liczba punktów musi być większa od zera."
	if attributes.get_value(attribute_code) < 0:
		return "Nieznany atrybut bohatera."
	if amount > unspent_attribute_points:
		return "Brak tylu wolnych punktów atrybutów."
	if attribute_code == PlayerAttributesClass.LUCK and character_class_code != CLASS_PIERROT:
		return "Atrybut Szczęście jest dostępny wyłącznie dla Pierrota."
	return ""


func spend_attribute_points(attribute_code: String, amount := 1) -> bool:
	if not get_attribute_spend_error(attribute_code, amount).is_empty():
		return false
	if not attributes.increase(attribute_code, amount):
		return false
	unspent_attribute_points -= amount
	recalculate_stats()
	return true


func recalculate_stats() -> void:
	var equipment_bonuses := equipment.total_bonuses(character_class_code)
	var attribute_bonuses := attributes.calculate_bonuses()
	var class_definition = PlayerClassCatalogClass.get_definition(character_class_code)
	var class_base_mana: int = class_definition.base_mana if class_definition != null else 0
	stats.apply_derived_stats(
		(
			equipment_bonuses.attack
			+ attribute_bonuses.attack
			+ PassiveProgressionServiceClass.attack_bonus(self)
		),
		equipment_bonuses.defense + attribute_bonuses.defense,
		equipment_bonuses.max_hp + attribute_bonuses.max_hp,
		equipment_bonuses.dodge + attribute_bonuses.dodge,
		equipment_bonuses.max_mana + attribute_bonuses.max_mana + class_base_mana,
		equipment_bonuses.magic_power
	)
	stats.elemental_resistances = equipment_bonuses.elemental_resistances
	stats.health_regen = equipment_bonuses.health_regen
	stats.crit_chance = equipment_bonuses.crit_chance
	stats.crit_damage = equipment_bonuses.crit_damage
	stats.skill_damage = equipment_bonuses.skill_damage
	stats.armor_penetration = equipment_bonuses.armor_penetration
	stats.damage_vs_elite = equipment_bonuses.damage_vs_elite
	stats.damage_vs_boss = equipment_bonuses.damage_vs_boss
	stats.average_damage = equipment_bonuses.average_damage


func has_active_equipment_effect(effect_id: String) -> bool:
	return EquipmentClassEffectCatalogClass.is_active(self, effect_id)


func get_equip_error(inventory_index: int) -> String:
	if inventory_index < 0 or inventory_index >= inventory.equipment_items.size():
		return "Nieprawidłowy przedmiot w plecaku."
	return get_item_equip_error(inventory.equipment_items[inventory_index])


func get_item_equip_error(item) -> String:
	if item == null or item.definition == null or not item.definition.is_equipment():
		return "Tego przedmiotu nie można założyć."
	if level < item.definition.required_level:
		return "Wymagany poziom: %d. Twój poziom: %d." % [item.definition.required_level, level]
	if (
		not item.definition.required_class_code.is_empty()
		and item.definition.required_class_code != character_class_code
	):
		return "Ten przedmiot wymaga klasy: %s." % item.definition.required_class_name
	return ""


func equip_from_inventory(inventory_index: int):
	if not get_equip_error(inventory_index).is_empty():
		return null
	var item = inventory.pop_equipment(inventory_index)
	var previous = equipment.equip_and_return_previous(item)
	if previous != null:
		inventory.add_equipment_instance(previous)
	recalculate_stats()
	return item


func unequip_to_inventory(slot: String):
	var item = equipment.unequip(slot)
	if item == null:
		return null
	inventory.add_equipment_instance(item)
	recalculate_stats()
	return item


func get_equipped_item_id(slot: String) -> String:
	var item = equipment.get_item(slot)
	return item.item_id if item != null else ""


func get_equipped_item_name(slot: String) -> String:
	var item = equipment.get_item(slot)
	return item.formatted_name() if item != null else "Brak"
