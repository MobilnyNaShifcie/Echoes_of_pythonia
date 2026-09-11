extends GutTest

const Items = preload("res://core/items/item_catalog.gd")
const Slot = preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const EXPECTED := {
	"ancient_scale": ["common", "material", "", 0],
	"bone_fang": ["uncommon", "material", "", 0],
	"scale_belt": ["rare", "equipment", "belt", 6],
	"mist_essence": ["uncommon", "material", "", 0],
	"mist_earrings": ["rare", "equipment", "earrings", 6],
	"witch_herb": ["uncommon", "material", "", 0],
	"witchbone_ring": ["rare", "equipment", "ring", 5],
	"sunken_plate": ["uncommon", "material", "", 0],
	"sunken_knight_armor": ["epic", "equipment", "chest", 7],
	"silentwater_heart": ["rare", "material", "", 0],
	"drowned_mother_medallion": ["rare", "equipment", "necklace", 8],
	"drowned_mother_blade": ["epic", "equipment", "weapon", 8],
	"drowned_mother_crown": ["epic", "equipment", "head", 8],
	"mireglass_bow": ["rare", "equipment", "weapon", 8],
	"mire_staff": ["rare", "equipment", "weapon", 8],
	"drowned_fate_lance": ["rare", "equipment", "weapon", 8],
	"charred_bone": ["common", "material", "", 0],
	"cursed_resin": ["uncommon", "material", "", 0],
	"desert_cloth": ["common", "material", "", 0],
	"wasteland_belt": ["rare", "equipment", "belt", 13],
	"wasteland_armor": ["rare", "equipment", "chest", 11],
	"harpy_feather": ["common", "material", "", 0],
	"salamander_scale": ["uncommon", "material", "", 0],
	"hearth_gauntlets": ["epic", "equipment", "hands", 13],
	"sand_golem_core": ["uncommon", "material", "", 0],
	"sun_talisman": ["rare", "equipment", "necklace", 12],
	"ashwind_bow": ["rare", "equipment", "weapon", 13],
	"ember_staff": ["rare", "equipment", "weapon", 13],
	"ashen_fate_lance": ["rare", "equipment", "weapon", 13],
	"great_healing_potion": ["rare", "consumable", "", 0],
}


func test_all_thirty_icons_resolve_through_unified_catalog_without_data_changes() -> void:
	assert_eq(EXPECTED.size(), 30)
	var paths := {}
	for item_id: String in EXPECTED:
		var item = Items.get_definition(item_id)
		assert_not_null(item, item_id)
		if item == null:
			continue
		assert_eq(
			[item.rarity, item.category, item.slot, item.required_level], EXPECTED[item_id], item_id
		)
		assert_not_null(item.icon, item_id)
		if item.icon == null:
			continue
		assert_eq(item.icon.resource_path, "res://assets/items/regional/%s.png" % item_id)
		assert_false(paths.has(item.icon.resource_path), "Each item owns its own illustration")
		paths[item.icon.resource_path] = true
		assert_eq(item.icon.get_size(), Vector2(512, 512), item_id)
		var pixels = item.icon.get_image()
		assert_ne(pixels.detect_alpha(), Image.ALPHA_NONE, item_id)
		var bounds = pixels.get_used_rect()
		assert_gte(bounds.position.x, 35, item_id)
		assert_gte(bounds.position.y, 35, item_id)
		assert_lte(bounds.end.x, 477, item_id)
		assert_lte(bounds.end.y, 477, item_id)
		assert_gt(bounds.get_area(), 1000, item_id)
		for corner: Vector2i in [
			Vector2i.ZERO, Vector2i(511, 0), Vector2i(0, 511), Vector2i(511, 511)
		]:
			assert_eq(pixels.get_pixelv(corner).a, 0.0, item_id)


func test_every_new_icon_reaches_inventory_slot_tooltip_quantity_and_quality_frame() -> void:
	for item_id: String in EXPECTED:
		var item = Items.get_definition(item_id)
		var slot = Slot.instantiate()
		add_child(slot)
		(
			slot
			. configure(
				{
					"title": item.display_name,
					"icon": item.icon,
					"rarity": item.rarity,
					"quantity": 2,
					"tooltip": item.description,
				}
			)
		)
		assert_eq(slot.item_texture, item.icon, item_id)
		assert_true(slot.get_node("ItemIcon").visible, item_id)
		assert_eq(slot.get_node("ItemIcon").texture, item.icon, item_id)
		assert_eq(slot.get_node("QuantityBadge").text, "×2", item_id)
		assert_eq(
			slot.get_theme_stylebox("normal").border_color, Palette.color_for(item.rarity), item_id
		)
		var tooltip = slot._make_custom_tooltip(slot.tooltip_text)
		var icons = tooltip.find_children("*", "TextureRect", true, false)
		assert_eq(icons.size(), 1, item_id)
		assert_eq(icons[0].texture, item.icon, item_id)
		tooltip.free()
		slot.free()


func test_all_thirty_items_reach_the_actual_equipment_screen() -> void:
	var session = NewGame.new().create_session("Art QA", 1)
	for item_id: String in EXPECTED:
		assert_true(session.player.inventory.add(item_id), item_id)
	var screen = Equipment.instantiate()
	screen.configure(session)
	add_child(screen)
	await get_tree().process_frame
	var shown := {}
	for slot in screen.inventory_grid.get_children():
		if slot is InventoryItemSlot and slot.item_texture != null:
			shown[slot.item_texture.resource_path] = true
	for item_id: String in EXPECTED:
		assert_has(shown, Items.get_definition(item_id).icon.resource_path, item_id)
	screen.free()
