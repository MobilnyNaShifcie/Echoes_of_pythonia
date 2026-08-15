extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CraftingServiceClass := preload("res://core/economy/crafting_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const LootCatalogClass := preload("res://core/items/loot_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RegionalItemCatalogClass := preload("res://core/items/regional_item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")

var _save_root: String


func before_each() -> void:
	_save_root = "user://test_stage_four_c_%s" % Crypto.new().generate_random_bytes(8).hex_encode()


func after_each() -> void:
	var directory := DirAccess.open(_save_root)
	if directory != null:
		for file_name in directory.get_files():
			DirAccess.remove_absolute(
				ProjectSettings.globalize_path("%s/%s" % [_save_root, file_name])
			)
	DirAccess.remove_absolute(ProjectSettings.globalize_path(_save_root))


func test_all_open_world_enemies_have_valid_terminal_loot_tables() -> void:
	var encounter_ids := {}
	for region_id: String in RegionCatalogClass.REGION_ORDER:
		var region = RegionCatalogClass.get_definition(region_id)
		for table: Dictionary in [region.day_encounters, region.night_encounters]:
			for enemy_id: String in table:
				encounter_ids[enemy_id] = true

	assert_eq(encounter_ids.size(), 36)
	assert_eq(LootCatalogClass.TABLES.size(), 36)
	for enemy_id: String in encounter_ids:
		assert_true(LootCatalogClass.has_table(enemy_id), "Brak tabeli łupu: %s" % enemy_id)
		var table := LootCatalogClass.get_table(enemy_id)
		assert_false(table.is_empty(), "Pusta tabela łupu: %s" % enemy_id)
		for entry: Dictionary in table:
			assert_between(float(entry.chance), 0.0, 1.0)
			assert_not_null(ItemCatalogClass.get_definition(entry.item_id), entry.item_id)


func test_regional_catalog_contains_complete_stage_four_c_item_data() -> void:
	assert_eq(RegionalItemCatalogClass.DEFINITIONS.size(), 72)
	var boots = ItemCatalogClass.get_definition("spiderstep_boots")
	assert_eq(boots.display_name, "Buty Pajęczego Kroku")
	assert_eq(boots.item_power, 2)
	assert_eq(boots.required_level, 3)
	assert_eq(boots.dodge, 3.0)

	var crown = ItemCatalogClass.get_definition("drowned_mother_crown")
	assert_eq(crown.item_power, 3)
	assert_eq(crown.required_level, 8)
	assert_eq(crown.water_resistance, 15)

	var armor = ItemCatalogClass.get_definition("north_armor")
	assert_eq(armor.item_power, 6)
	assert_eq(armor.required_level, 16)
	assert_eq(armor.frost_resistance, 15)
	assert_eq(armor.class_effect_id, "warrior_retribution")


func test_loot_roller_supports_guaranteed_and_elite_specific_chances() -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 4003
	var normal := LootCatalogClass.roll_loot("ice_bear", rng, 100.0)
	rng.seed = 4003
	var elite := LootCatalogClass.roll_loot("ice_bear", rng, 100.0, true)

	assert_eq(normal.size(), 2)
	assert_eq(elite.size(), 2)
	assert_eq(normal[0].item_id, "white_fur")
	assert_eq(normal[1].item_id, "north_armor")
	assert_true(LootCatalogClass.roll_loot("unknown_enemy", rng).is_empty())
	assert_true(LootCatalogClass.roll_loot("ice_bear", rng, -1.0).is_empty())


func test_regional_victory_adds_materials_equipment_and_keys_to_inventory() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var enemy = EnemyCatalogClass.create_enemy("drowned_mother")
	var rng := RandomNumberGenerator.new()
	rng.seed = 4011

	var rewards := AdventureServiceClass.resolve_victory(session, enemy, rng)

	assert_eq(session.player.inventory.count("silentwater_heart"), 1)
	assert_eq(session.player.inventory.count("ancient_order_key"), 1)
	assert_true(rewards.loot_names.has("Serce Głuchej Wody"))
	assert_true(rewards.loot_names.has("Starożytny Klucz Zakonu"))
	assert_true(rewards.loot_drops.size() >= 2)


func test_all_five_regional_recipe_groups_are_complete_and_closed() -> void:
	var expected_counts := {
		"twilight_plains": 10,
		"black_forest": 8,
		"silent_water_marshes": 12,
		"ashen_borderlands": 7,
		"ice_coast": 5,
	}
	assert_eq(CraftingServiceClass.get_all_recipes().size(), 42)
	for region_id: String in expected_counts:
		var recipes := CraftingServiceClass.get_recipes(region_id)
		assert_eq(recipes.size(), expected_counts[region_id], region_id)
		for recipe: Dictionary in recipes:
			assert_eq(recipe.region_id, region_id)
			assert_not_null(ItemCatalogClass.get_definition(recipe.output_item_id))
			for ingredient_id: String in recipe.ingredients:
				assert_not_null(ItemCatalogClass.get_definition(ingredient_id), ingredient_id)


func test_later_region_recipe_charges_gold_and_creates_equipment() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var player = session.player
	player.gold = 1400
	player.inventory.add("desert_cloth", 4)
	player.inventory.add("sand_golem_core", 3)
	player.inventory.add("charred_bone", 2)
	player.inventory.add("common_essence", 2)

	var crafted := CraftingServiceClass.craft(player, "wasteland_armor")

	assert_true(crafted.ok, crafted.message)
	assert_eq(player.gold, 0)
	assert_eq(player.inventory.count("wasteland_armor"), 1)
	assert_eq(player.inventory.count("desert_cloth"), 0)


func test_recipe_does_not_consume_materials_when_gold_is_missing() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("desert_cloth", 4)
	player.inventory.add("sand_golem_core", 3)
	player.inventory.add("charred_bone", 2)
	player.inventory.add("common_essence", 2)

	var result := CraftingServiceClass.craft(player, "wasteland_armor")

	assert_false(result.ok)
	assert_string_contains(result.message, "Brakuje złota")
	assert_eq(player.inventory.count("desert_cloth"), 4)


func test_required_level_and_elemental_resistance_apply_after_equipping() -> void:
	var player = NewGameServiceClass.new().create_session("Aria", 1).player
	player.inventory.add("wasteland_armor")
	assert_string_contains(player.get_equip_error(0), "Wymagany poziom: 11")

	player.level = 11
	var equipped = player.equip_from_inventory(0)

	assert_not_null(equipped)
	assert_eq(player.stats.elemental_resistances.fire, 10)
	assert_eq(player.stats.defense, 10)
	assert_eq(player.stats.max_hp, 65)


func test_item_power_uses_matching_regional_upgrade_materials() -> void:
	var item = ItemCatalogClass.create_equipment_item("hearth_gauntlets")
	var cost := UpgradeServiceClass.get_upgrade_cost(3, item)

	assert_true(cost.ok)
	assert_eq(cost.materials, {"grinding_stone": 1, "salamander_scale": 1})


func test_regional_items_round_trip_through_existing_schema_six_save() -> void:
	var service := SaveGameServiceClass.new(_save_root)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 16
	session.player.inventory.add("black_pearl", 3)
	session.player.inventory.add("north_armor")
	var source_instance_id: String = session.player.inventory.equipment_items[0].instance_id

	var save_result := service.save_session(session)
	var load_result := service.load_session(1)

	assert_true(save_result.ok, save_result.message)
	assert_true(load_result.ok, load_result.message)
	assert_eq(load_result.session.player.inventory.count("black_pearl"), 3)
	assert_eq(load_result.session.player.inventory.count("north_armor"), 1)
	assert_eq(
		load_result.session.player.inventory.equipment_items[0].instance_id,
		source_instance_id,
	)
