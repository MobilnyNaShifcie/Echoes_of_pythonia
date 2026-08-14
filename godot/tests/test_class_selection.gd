extends GutTest

const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_class_choice_is_locked_before_level_five() -> void:
	var player = PlayerFactoryClass.create_player("Tester")

	assert_false(player.can_choose_class)
	assert_false(player.choose_class("pierrot"))
	assert_eq(player.character_class_code, player.CLASS_NONE)


func test_each_legacy_class_equips_its_starting_set_at_level_five() -> void:
	var expectations := {
		"warrior": ["starter_sword", "training_shield", 12],
		"hunter": ["hunting_bow", "simple_quiver", 16],
		"mage": ["apprentice_staff", "mana_crystal_artifact", 37],
		"pierrot": ["caprice_lance", "worn_fate_dice", 18],
	}
	for class_code: String in expectations:
		var player = PlayerFactoryClass.create_player("Tester")
		player.level = 5

		assert_true(player.choose_class(class_code), class_code)
		assert_eq(player.weapon_id, expectations[class_code][0], class_code)
		assert_eq(
			player.get_equipped_item_id(PlayerEquipmentClass.OFF_HAND),
			expectations[class_code][1],
			class_code,
		)
		assert_eq(player.stats.max_mana, expectations[class_code][2], class_code)
