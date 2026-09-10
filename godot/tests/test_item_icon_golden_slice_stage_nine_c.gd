extends GutTest

const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const ITEM_SLOT_SCENE := preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")

const GOLDEN_SLICE := {
	"starter_sword": Vector2i(512, 1024),
	"training_shield": Vector2i(512, 1024),
	"worn_leather_armor": Vector2i(1024, 1024),
	"leather_hood": Vector2i(512, 512),
	"weak_healing_potion": Vector2i(512, 512),
	"whetstone": Vector2i(512, 512),
	"wolf_fur": Vector2i(512, 512),
	"wolf_fang": Vector2i(512, 512),
	"slime_gel": Vector2i(512, 512),
	"mastery_strength_book": Vector2i(512, 512),
}

const APPROVED_BATCH_TWO := [
	"hunting_bow",
	"apprentice_staff",
	"caprice_lance",
	"hunter_gloves",
	"reinforced_boots",
	"leather_belt",
	"wolf_tooth_necklace",
	"nature_ring",
	"hard_wood",
	"common_essence",
	"strong_healing_potion",
	"path_arcana_book",
]

const APPROVED_BATCH_THREE := [
	"sharpened_sword",
	"stitched_armor",
	"simple_quiver",
	"nature_amulet",
	"nature_bracelet",
	"nature_earrings",
	"weak_leather",
	"metal_buckle",
	"grinding_stone",
	"spark_of_life",
	"mana_crystal_artifact",
	"hunter_provisions",
]

const APPROVED_BATCH_FOUR := [
	"grandmaster_elixir",
	"mastery_attack_speed_book",
	"mastery_critical_book",
	"mastery_regeneration_book",
	"old_clothes",
	"path_fortuna_book",
	"path_heavy_knight_book",
	"path_phantom_archer_book",
	"raw_boar_meat",
	"truffle",
	"worn_fate_dice",
	"worn_strap",
]


func test_all_golden_slice_definitions_own_the_approved_texture_contract() -> void:
	for item_id: String in GOLDEN_SLICE:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_not_null(definition, item_id)
		assert_not_null(definition.icon, item_id)
		assert_eq(
			Vector2i(definition.icon.get_width(), definition.icon.get_height()),
			GOLDEN_SLICE[item_id],
			item_id,
		)


func test_all_approved_batch_two_definitions_own_an_imported_texture() -> void:
	for item_id: String in APPROVED_BATCH_TWO:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_not_null(definition, item_id)
		assert_not_null(definition.icon, item_id)
		assert_gt(definition.icon.get_width(), 0, item_id)
		assert_gt(definition.icon.get_height(), 0, item_id)


func test_all_approved_batch_three_definitions_own_an_imported_texture() -> void:
	for item_id: String in APPROVED_BATCH_THREE:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_not_null(definition, item_id)
		assert_not_null(definition.icon, item_id)
		assert_gt(definition.icon.get_width(), 0, item_id)
		assert_gt(definition.icon.get_height(), 0, item_id)


func test_all_approved_batch_four_definitions_own_an_imported_texture() -> void:
	for item_id: String in APPROVED_BATCH_FOUR:
		var definition = ItemCatalogClass.get_definition(item_id)
		assert_not_null(definition, item_id)
		assert_not_null(definition.icon, item_id)
		assert_gt(definition.icon.get_width(), 0, item_id)
		assert_gt(definition.icon.get_height(), 0, item_id)


func test_slot_renders_art_quantity_and_icon_aware_tooltip_without_baked_text() -> void:
	var definition = ItemCatalogClass.get_definition("wolf_fur")
	var slot := ITEM_SLOT_SCENE.instantiate() as InventoryItemSlot
	add_child_autofree(slot)
	(
		slot
		. configure(
			{
				"title": definition.display_name,
				"placeholder": "FW",
				"icon": definition.icon,
				"rarity": definition.rarity,
				"quantity": 12,
				"tooltip": "Futro Wilka\n\nMateriał rzemieślniczy.",
			}
		)
	)

	assert_eq(slot.text, "")
	assert_eq(slot.item_texture, definition.icon)
	assert_true(slot.get_node("ItemIcon").visible)
	assert_eq(slot.get_node("QuantityBadge").text, "×12")
	assert_true(slot.get_node("QuantityBadge").visible)
	var tooltip := slot._make_custom_tooltip(slot.tooltip_text) as PanelContainer
	assert_eq(tooltip.find_children("*", "TextureRect", true, false).size(), 1)
	assert_eq(tooltip.find_children("*", "Label", true, false).size(), 2)
	assert_eq(tooltip.size_flags_horizontal, Control.SIZE_SHRINK_BEGIN)
	assert_eq(tooltip.size_flags_vertical, Control.SIZE_SHRINK_BEGIN)
	var tooltip_icon := tooltip.find_children("*", "TextureRect", true, false)[0] as TextureRect
	var tooltip_label := tooltip.find_child("ItemDescription", true, false) as Label
	assert_string_contains(tooltip.find_child("RarityLabel", true, false).text, "Jakość:")
	assert_eq(tooltip_icon.size_flags_vertical, Control.SIZE_SHRINK_BEGIN)
	assert_eq(tooltip_label.size_flags_vertical, Control.SIZE_SHRINK_BEGIN)
	assert_eq(tooltip_label.custom_minimum_size.x, 268.0)
	assert_lt(tooltip.get_combined_minimum_size().y, 160.0)
	tooltip.free()


func test_same_item_art_contract_reaches_all_seven_required_ui_contexts() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.gold = 500
	session.player.inventory.add("wolf_fur", 3)

	var equipment = EQUIPMENT_SCENE.instantiate()
	equipment.configure(session)
	add_child_autofree(equipment)
	assert_eq(
		equipment.slot_buttons.weapon.item_texture,
		ItemCatalogClass.get_definition("starter_sword").icon,
	)
	var backpack_cell := _find_cell_with_texture(
		equipment.inventory_grid, ItemCatalogClass.get_definition("wolf_fur").icon
	)
	assert_not_null(backpack_cell)
	assert_eq(backpack_cell.get_node("QuantityBadge").text, "×3")

	var merchant = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(merchant)
	merchant.configure(session, "merchant")
	assert_not_null(
		_find_cell_with_texture(
			merchant.service_grid,
			ItemCatalogClass.get_definition("weak_healing_potion").icon,
		)
	)

	var blacksmith = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(blacksmith)
	blacksmith.configure(session, "blacksmith")
	assert_not_null(
		_find_cell_with_texture(
			blacksmith.service_grid,
			ItemCatalogClass.get_definition("starter_sword").icon,
		)
	)

	var workshop = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(workshop)
	workshop.configure(session, "workshop")
	assert_not_null(
		_find_cell_with_texture(
			workshop.service_grid,
			ItemCatalogClass.get_definition("leather_hood").icon,
		)
	)

	var inn = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(inn)
	inn.configure(session, "inn")
	inn.mode_selector.select(1)
	inn.mode_selector.item_selected.emit(1)
	assert_not_null(
		_find_cell_with_texture(
			inn.service_grid,
			ItemCatalogClass.get_definition("wolf_fur").icon,
		)
	)

	var combat = COMBAT_SCENE.instantiate()
	combat.configure(session, "wild_dog", "expedition")
	add_child_autofree(combat)
	combat.loot_presentation.set_drops([{"item_id": "wolf_fang", "quantity": 2}])
	assert_true(combat.loot_presentation.visible)
	var loot_cell: InventoryItemSlot = combat.loot_presentation.loot_grid.get_child(0)
	assert_eq(loot_cell.item_texture, ItemCatalogClass.get_definition("wolf_fang").icon)
	assert_eq(loot_cell.get_node("QuantityBadge").text, "×2")
	assert_lte(
		loot_cell.get_rect().end.y,
		combat.loot_presentation.loot_grid.size.y,
		"Loot thumbnail must remain inside its compact result grid.",
	)


func _find_cell_with_texture(grid: InventoryGridView, texture: Texture2D) -> InventoryItemSlot:
	for child in grid.get_children():
		if child is InventoryItemSlot and child.item_texture == texture:
			return child
	return null
