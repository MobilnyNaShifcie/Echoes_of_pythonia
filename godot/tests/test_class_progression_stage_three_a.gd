extends GutTest

const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_class_catalog_matches_the_four_terminal_paths() -> void:
	var definitions = PlayerClassCatalogClass.get_playable_definitions()
	assert_eq(definitions.size(), 4)
	assert_eq(
		definitions.map(func(definition): return definition.class_code),
		["warrior", "hunter", "mage", "pierrot"],
	)
	assert_eq(PlayerClassCatalogClass.get_definition("warrior").base_mana, 12)
	assert_eq(PlayerClassCatalogClass.get_definition("hunter").base_mana, 16)
	assert_eq(PlayerClassCatalogClass.get_definition("mage").base_mana, 24)
	assert_eq(PlayerClassCatalogClass.get_definition("pierrot").base_mana, 18)


func test_attribute_spending_is_atomic_and_luck_remains_pierrot_only() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	player.unspent_attribute_points = 2

	assert_false(player.spend_attribute_points("strength", 3))
	assert_eq(player.attributes.strength, 0)
	assert_eq(player.unspent_attribute_points, 2)
	assert_false(player.spend_attribute_points("luck"))
	assert_eq(player.attributes.luck, 0)
	assert_eq(player.unspent_attribute_points, 2)

	player.level = 5
	assert_true(player.choose_class("pierrot"))
	assert_true(player.spend_attribute_points("luck", 2))
	assert_eq(player.attributes.luck, 2)
	assert_eq(player.unspent_attribute_points, 0)
