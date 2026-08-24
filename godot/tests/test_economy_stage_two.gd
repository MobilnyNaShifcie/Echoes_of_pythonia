extends GutTest

const CraftingServiceClass := preload("res://core/economy/crafting_service.gd")
const EconomyServiceClass := preload("res://core/economy/economy_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_buying_uses_the_terminal_prices_and_is_atomic_without_gold() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.gold = 100

	var bought := EconomyServiceClass.buy_item(player, "weak_healing_potion", 2)
	var rejected := EconomyServiceClass.buy_item(player, "grinding_stone", 1)

	assert_true(bought.ok)
	assert_eq(player.gold, 50)
	assert_eq(player.inventory.count("weak_healing_potion"), 2)
	assert_false(rejected.ok)
	assert_eq(player.gold, 50)
	assert_eq(player.inventory.count("grinding_stone"), 0)


func test_selling_stacks_and_equipment_uses_terminal_price_rules() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("wolf_fur", 3)
	player.inventory.add("leather_hood", 2)
	player.inventory.equipment_items[1].upgrade_level = 5
	var base_price := EconomyServiceClass.get_equipment_sell_price(
		player.inventory.equipment_items[0]
	)
	var upgraded_price := EconomyServiceClass.get_equipment_sell_price(
		player.inventory.equipment_items[1]
	)

	var stack_sale := EconomyServiceClass.sell_stack(player, "wolf_fur", 2)
	var equipment_sale := EconomyServiceClass.sell_equipment(player, 1)

	assert_true(stack_sale.ok)
	assert_eq(stack_sale.gold, 8)
	assert_eq(player.inventory.count("wolf_fur"), 1)
	assert_gt(upgraded_price, base_price)
	assert_true(equipment_sale.ok)
	assert_eq(equipment_sale.gold, upgraded_price)
	assert_eq(player.gold, 8 + upgraded_price)
	assert_eq(player.inventory.equipment_items.size(), 1)


func test_first_region_recipe_set_matches_terminal_order_and_catalog() -> void:
	var recipes := CraftingServiceClass.get_recipes()
	assert_eq(recipes.size(), 10)
	assert_eq(recipes[0].recipe_id, "leather_hood")
	assert_eq(recipes[9].recipe_id, "weak_to_strong_potion")
	for recipe: Dictionary in recipes:
		assert_not_null(ItemCatalogClass.get_definition(recipe.output_item_id))
		for item_id: String in recipe.ingredients:
			assert_not_null(ItemCatalogClass.get_definition(item_id))


func test_crafting_consumes_all_materials_only_after_full_validation() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("weak_leather", 2)
	var crafted := CraftingServiceClass.craft(player, "leather_hood")

	assert_true(crafted.ok)
	assert_eq(player.inventory.count("weak_leather"), 0)
	assert_eq(player.inventory.count("leather_hood"), 1)

	player.inventory.add("weak_leather", 3)
	var rejected := CraftingServiceClass.craft(player, "hunter_gloves")
	assert_false(rejected.ok)
	assert_eq(player.inventory.count("weak_leather"), 3)


func test_sharpened_sword_requires_the_exact_backpack_instance() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("whetstone", 2)
	assert_false(CraftingServiceClass.craft(player, "sharpened_sword").ok)
	assert_eq(player.inventory.count("whetstone"), 2)

	player.unequip_to_inventory("weapon")
	var crafted := CraftingServiceClass.craft(player, "sharpened_sword")
	assert_true(crafted.ok)
	assert_eq(player.inventory.count("starter_sword"), 0)
	assert_eq(player.inventory.count("whetstone"), 0)
	assert_eq(player.inventory.count("sharpened_sword"), 1)
