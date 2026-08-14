extends GutTest

const PlayerAttributesClass := preload("res://core/player/attributes.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PrimaryStatsClass := preload("res://core/player/primary_stats.gd")


func test_starting_equipment_provides_legacy_initial_stats() -> void:
	var player := PlayerFactoryClass.create_player("Tester")

	assert_eq(player.stats.attack, 3)
	assert_eq(player.stats.defense, 2)
	assert_eq(player.stats.current_hp, 20)
	assert_eq(player.stats.max_hp, 20)
	assert_eq(player.stats.current_mana, 0)
	assert_eq(player.stats.max_mana, 0)
	assert_eq(player.stats.dodge, 0.0)


func test_starting_equipment_keeps_legacy_ids_and_names() -> void:
	var player := PlayerFactoryClass.create_player("Tester")

	assert_eq(player.weapon_id, "starter_sword")
	assert_eq(player.armor_id, "worn_leather_armor")
	assert_eq(player.get_equipped_item_name(PlayerEquipmentClass.WEAPON), "Stary Miecz +0")
	assert_eq(
		player.get_equipped_item_name(PlayerEquipmentClass.CHEST), "Zużyta Skórzana Zbroja +0"
	)


func test_attributes_match_legacy_derived_stat_formulas() -> void:
	var attributes := PlayerAttributesClass.new()
	attributes.strength = 3
	attributes.vitality = 2
	attributes.intelligence = 4
	attributes.dexterity = 2
	attributes.endurance = 3

	var bonuses := attributes.calculate_bonuses()
	assert_eq(bonuses.attack, 3)
	assert_eq(bonuses.max_hp, 10)
	assert_eq(bonuses.max_mana, 20)
	assert_eq(bonuses.dodge, 3.0)
	assert_eq(bonuses.defense, 1)


func test_spending_attribute_points_is_atomic() -> void:
	var player := PlayerFactoryClass.create_player("Tester")
	player.unspent_attribute_points = 2

	assert_false(player.spend_attribute_points(PlayerAttributesClass.VITALITY, 3))
	assert_eq(player.attributes.vitality, 0)
	assert_eq(player.unspent_attribute_points, 2)
	assert_eq(player.stats.max_hp, 20)

	assert_true(player.spend_attribute_points(PlayerAttributesClass.VITALITY, 2))
	assert_eq(player.attributes.vitality, 2)
	assert_eq(player.unspent_attribute_points, 0)
	assert_eq(player.stats.max_hp, 30)


func test_luck_remains_exclusive_to_pierrot() -> void:
	var player := PlayerFactoryClass.create_player("Tester")
	player.unspent_attribute_points = 1

	assert_false(player.spend_attribute_points(PlayerAttributesClass.LUCK))
	assert_eq(player.attributes.luck, 0)
	assert_eq(player.unspent_attribute_points, 1)

	player.character_class_code = player.CLASS_PIERROT
	assert_true(player.spend_attribute_points(PlayerAttributesClass.LUCK))
	assert_eq(player.attributes.luck, 1)


func test_level_up_matches_legacy_experience_curve() -> void:
	var player := PlayerFactoryClass.create_player("Tester")

	assert_eq(player.experience_remaining_to_next_level(), 50)
	assert_eq(player.gain_experience(50), 1)
	assert_eq(player.level, 1)
	assert_eq(player.experience, 0)
	assert_eq(player.unspent_attribute_points, 4)


func test_primary_stats_clamp_damage_healing_and_mana() -> void:
	var stats := PrimaryStatsClass.new()
	stats.apply_derived_stats(0, 0, 10, 0.0, 8)
	stats.restore_full()

	assert_eq(stats.take_damage(35), 30)
	assert_false(stats.is_alive())
	assert_eq(stats.heal(12), 12)
	assert_eq(stats.current_hp, 12)
	assert_true(stats.spend_mana(5))
	assert_false(stats.spend_mana(4))
	assert_eq(stats.restore_mana(99), 5)
	assert_eq(stats.current_mana, 8)
