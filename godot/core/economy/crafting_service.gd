class_name CraftingService
extends RefCounted

const ItemCatalogClass := preload("res://core/items/item_catalog.gd")

const RECIPE_ORDER := [
	"leather_hood",
	"stitched_armor",
	"hunter_gloves",
	"reinforced_boots",
	"sharpened_sword",
	"leather_belt",
	"wolf_tooth_necklace",
	"hunter_provisions",
	"nature_ring",
	"weak_to_strong_potion",
]
const RECIPES := {
	"leather_hood":
	{
		"name": "Skórzany Kaptur",
		"output_item_id": "leather_hood",
		"quantity": 1,
		"ingredients": {"weak_leather": 2},
	},
	"stitched_armor":
	{
		"name": "Zszywana Zbroja",
		"output_item_id": "stitched_armor",
		"quantity": 1,
		"ingredients": {"old_clothes": 5, "weak_leather": 1},
	},
	"hunter_gloves":
	{
		"name": "Rękawice Myśliwego",
		"output_item_id": "hunter_gloves",
		"quantity": 1,
		"ingredients": {"weak_leather": 3, "worn_strap": 2},
	},
	"reinforced_boots":
	{
		"name": "Wzmocnione Buty",
		"output_item_id": "reinforced_boots",
		"quantity": 1,
		"ingredients": {"weak_leather": 4, "old_clothes": 2},
	},
	"sharpened_sword":
	{
		"name": "Ostrzony Miecz",
		"output_item_id": "sharpened_sword",
		"quantity": 1,
		"ingredients": {"starter_sword": 1, "whetstone": 2},
		"note": "Stary Miecz musi znajdować się w plecaku.",
	},
	"leather_belt":
	{
		"name": "Pas Skórzany",
		"output_item_id": "leather_belt",
		"quantity": 1,
		"ingredients": {"worn_strap": 2, "metal_buckle": 1, "weak_leather": 1},
	},
	"wolf_tooth_necklace":
	{
		"name": "Ząb Wilka",
		"output_item_id": "wolf_tooth_necklace",
		"quantity": 1,
		"ingredients": {"wolf_fur": 3, "wolf_fang": 2},
		"note": "Alternatywa dla bezpośredniego łupu z Wilka.",
	},
	"hunter_provisions":
	{
		"name": "Prowiant Myśliwego",
		"output_item_id": "hunter_provisions",
		"quantity": 1,
		"ingredients": {"raw_boar_meat": 2, "truffle": 1},
	},
	"nature_ring":
	{
		"name": "Pierścień Natury",
		"output_item_id": "nature_ring",
		"quantity": 1,
		"ingredients": {"spark_of_life": 1, "common_essence": 3, "hard_wood": 2},
		"note": "Alternatywa dla bezpośredniego łupu ze Strażnika Natury.",
	},
	"weak_to_strong_potion":
	{
		"name": "Wzmocnienie: Słaba → Mocna",
		"output_item_id": "strong_healing_potion",
		"quantity": 1,
		"ingredients": {"weak_healing_potion": 3},
		"note": "Trzy Słabe Mikstury tworzą jedną Mocną.",
	},
}


static func get_recipes() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for recipe_id: String in RECIPE_ORDER:
		var recipe: Dictionary = RECIPES[recipe_id].duplicate(true)
		recipe.recipe_id = recipe_id
		result.append(recipe)
	return result


static func get_recipe(recipe_id: String) -> Dictionary:
	if not RECIPES.has(recipe_id):
		return {}
	var recipe: Dictionary = RECIPES[recipe_id].duplicate(true)
	recipe.recipe_id = recipe_id
	return recipe


static func get_craft_error(player, recipe_id: String) -> String:
	var recipe := get_recipe(recipe_id)
	if recipe.is_empty():
		return "Nieznana receptura."
	if ItemCatalogClass.get_definition(recipe.output_item_id) == null:
		return "Wynik receptury nie istnieje w katalogu przedmiotów."
	for item_id: String in recipe.ingredients:
		var required := int(recipe.ingredients[item_id])
		var owned: int = player.inventory.count(item_id)
		if owned < required:
			return (
				"Brakuje składnika: %s %d/%d."
				% [
					ItemCatalogClass.get_definition(item_id).display_name,
					owned,
					required,
				]
			)
	return ""


static func craft(player, recipe_id: String) -> Dictionary:
	var error := get_craft_error(player, recipe_id)
	if not error.is_empty():
		return {"ok": false, "message": error}
	var recipe := get_recipe(recipe_id)
	for item_id: String in recipe.ingredients:
		player.inventory.remove_item(item_id, int(recipe.ingredients[item_id]))
	player.inventory.add(recipe.output_item_id, int(recipe.quantity))
	return {
		"ok": true,
		"message": "Wytworzono: %s ×%d." % [recipe.name, recipe.quantity],
		"recipe": recipe,
	}
