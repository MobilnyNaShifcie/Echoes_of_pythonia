extends GutTest

const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_class_choice_unlocks_at_level_five_and_remains_permanent() -> void:
	var player = PlayerFactoryClass.create_player("Tester")

	assert_false(player.can_choose_class)
	assert_false(player.choose_class("pierrot"))
	player.level = 5
	assert_true(player.can_choose_class)
	assert_true(player.choose_class("pierrot"))
	assert_eq(player.character_class_code, "pierrot")
	assert_false(player.can_choose_class)
	assert_false(player.choose_class("warrior"))


func test_each_class_equips_its_starting_set_at_level_five() -> void:
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


func test_gender_is_chosen_once_and_feminizes_the_neutral_role_name() -> void:
	var player = PlayerFactoryClass.create_player("Aria")

	assert_eq(player.gender_code, "unspecified")
	assert_true(player.choose_gender("female"))
	assert_eq(player.gender_name, "Kobieta")
	assert_eq(player.character_class_name, "Poszukiwaczka")
	assert_false(player.choose_gender("male"))
	assert_eq(player.gender_code, "female")
