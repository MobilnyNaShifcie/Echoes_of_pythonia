extends SceneTree
## Read catalogs, never player saves. Re-run after each integrated art batch.
const Items = preload("res://core/items/item_catalog.gd")
const Loot = preload("res://core/items/loot_catalog.gd")
const ClassLoot = preload("res://core/items/class_loot_service.gd")
const Regions = preload("res://core/world/region_catalog.gd")
const Sets = preload("res://core/items/equipment_set_catalog.gd")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const Regional = preload("res://core/items/regional_item_catalog.gd")
const Recipes = preload("res://core/economy/regional_recipe_catalog.gd")
const Rifts = preload("res://core/rifts/rift_catalog.gd")


func _init() -> void:
	var enemy_regions := {}
	for region in Regions.get_all_definitions():
		for enemy_id in region.day_encounters.keys() + region.night_encounters.keys():
			enemy_regions[enemy_id] = region.region_id
	var region_aliases := {"blackwood": "black_forest", "marsh": "silentwater_marshes", "ashlands": "ashen_borderlands", "ice_coast": "ice_coast"}
	for group in ClassLoot.REGION_ENEMIES:
		for enemy_id in ClassLoot.REGION_ENEMIES[group]:
			enemy_regions[enemy_id] = region_aliases[group]
	var sources := {}
	for enemy_id: String in Loot.TABLES:
		for drop in Loot.TABLES[enemy_id]:
			if not sources.has(drop.item_id):
				sources[drop.item_id] = []
			sources[drop.item_id].append({"enemy": enemy_id, "region": enemy_regions.get(enemy_id, "dungeon"), "chance": drop.chance})
	for group: String in ClassLoot.CLASS_WEAPON_POOLS:
		for item_id in ClassLoot.CLASS_WEAPON_POOLS[group]:
			sources[item_id] = [{"class_pool": group, "enemies": ClassLoot.REGION_ENEMIES[group]}]
	for recipe_id in Recipes.RECIPES:
		var recipe: Dictionary = Recipes.RECIPES[recipe_id]
		if not sources.has(recipe.output_item_id):
			sources[recipe.output_item_id] = []
		sources[recipe.output_item_id].append({"recipe": recipe_id, "region": recipe.region_id, "ingredients": recipe.ingredients})
	for class_code in Rifts.UNIQUE_POOLS:
		for item_id in Rifts.UNIQUE_POOLS[class_code]:
			sources[item_id] = [{"rift_unique_pool": class_code}]
	for item_id in ClassLoot.CLASS_GEAR_POOL:
		sources[item_id] = [{"class_gear_pool": "late_game"}]
	var all := []
	var missing := []
	var counts := {}
	for definition in Items.get_all_definitions():
		var set_ids := []
		for set_id in Sets.SETS:
			if definition.item_id in Sets.SETS[set_id].required_items:
				set_ids.append(set_id)
		var row := {
			"id": definition.item_id, "name": definition.display_name,
			"description": definition.description, "category": definition.category,
			"slot": definition.slot, "rarity": definition.rarity,
			"rarity_label": Palette.label_for(definition.rarity),
			"rarity_color": Palette.color_for(definition.rarity).to_html(false),
			"level": definition.required_level, "sets": set_ids,
			"regional": Regional.has_definition(definition.item_id),
			"sources": sources.get(definition.item_id, []),
			"icon": definition.icon.resource_path if definition.icon != null else "",
		}
		all.append(row)
		counts[definition.rarity] = counts.get(definition.rarity, 0) + 1
		if definition.icon == null:
			missing.append(row)
	var output := "res://../output/item_art/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var file := FileAccess.open(output + "catalog_audit.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"total": all.size(), "missing_count": missing.size(), "rarities": counts, "items": all, "missing": missing}, "\t"))
	file.close()
	print("ITEM ART AUDIT total=", all.size(), " missing=", missing.size(), " rarities=", counts)
	quit()
