class_name CraftingService
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionalRecipeCatalogClass := preload("res://core/economy/regional_recipe_catalog.gd")


static func get_recipes(region_id := "twilight_plains") -> Array[Dictionary]:
	return RegionalRecipeCatalogClass.get_recipes(region_id)


static func get_all_recipes() -> Array[Dictionary]:
	return RegionalRecipeCatalogClass.get_recipes()


static func get_recipe(recipe_id: String) -> Dictionary:
	return RegionalRecipeCatalogClass.get_recipe(recipe_id)


static func get_craft_error(player, recipe_id: String) -> String:
	var recipe := get_recipe(recipe_id)
	if recipe.is_empty():
		return "Nieznana receptura."
	if ItemCatalogClass.get_definition(recipe.output_item_id) == null:
		return "Wynik receptury nie istnieje w katalogu przedmiotów."
	var gold_cost := int(recipe.get("gold_cost", 0))
	if gold_cost < 0:
		return "Receptura ma nieprawidłowy koszt złota."
	if player.gold < gold_cost:
		return "Brakuje złota. Potrzeba %d, masz %d." % [gold_cost, player.gold]
	for item_id: String in recipe.ingredients:
		var definition = ItemCatalogClass.get_definition(item_id)
		if definition == null:
			return "Receptura zawiera nieznany składnik: %s." % item_id
		var required := int(recipe.ingredients[item_id])
		var owned: int = player.inventory.count(item_id)
		if owned < required:
			return "Brakuje składnika: %s %d/%d." % [definition.display_name, owned, required]
	return ""


static func craft(player, recipe_id: String, rng: RandomNumberGenerator = null) -> Dictionary:
	var error := get_craft_error(player, recipe_id)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var recipe := get_recipe(recipe_id)
	for item_id: String in recipe.ingredients:
		player.inventory.remove_item(item_id, int(recipe.ingredients[item_id]))
	player.gold -= int(recipe.get("gold_cost", 0))
	player.inventory.add(
		recipe.output_item_id,
		int(recipe.quantity),
		rng,
		str(recipe.get("equipment_quality", "normal"))
	)
	return {
		"ok": true,
		"message": "Wytworzono: %s ×%d." % [recipe.name, recipe.quantity],
		"recipe": recipe,
	}
