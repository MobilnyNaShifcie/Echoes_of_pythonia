extends GutTest

const Items = preload("res://core/items/item_catalog.gd")
const Slot = preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const EXPECTED := {
	"ancient_order_key": ["rare","key","",0],
	"order_seal": ["uncommon","material","",0],
	"grandmaster_chain": ["rare","material","",0],
	"crown_fragment": ["rare","material","",0],
	"grandmaster_sword": ["epic","equipment","weapon",10],
	"sunken_order_cloak": ["epic","equipment","chest",10],
	"varek_sabre_fragment": ["epic","material","",0],
	"azhar_blade": ["epic","equipment","weapon",14],
	"azhar_crown": ["epic","equipment","head",14],
	"azhar_ring": ["epic","equipment","ring",14],
	"black_fleet_medallion": ["rare","key","",0],
	"black_pearl_earrings": ["rare","equipment","earrings",16],
	"black_sea_amulet": ["epic","equipment","necklace",16],
	"captain_signet": ["epic","equipment","bracelet",17],
	"cursed_compass": ["rare","material","",0],
	"frozen_cloth": ["common","material","",0],
	"ice_chitin": ["uncommon","material","",0],
	"leviathan_ring": ["epic","equipment","ring",18],
	"north_armor": ["epic","equipment","chest",16],
	"northern_trail_boots": ["rare","equipment","feet",15],
	"snow_griffin_cloak": ["epic","equipment","chest",16],
	"snow_griffin_feather": ["uncommon","material","",0],
	"white_fur": ["common","material","",0],
	"varek_sabre": ["legendary","equipment","weapon",20],
	"black_sea_bow": ["epic","equipment","weapon",17],
	"black_sea_staff": ["epic","equipment","weapon",17],
	"black_tide_fate_lance": ["epic","equipment","weapon",17],
	"hearthguard_shield": ["rare","equipment","off_hand",14],
	"order_bracelet": ["rare","equipment","bracelet",10],
	"abyss_ring": ["epic","equipment","ring",10],
}


func test_all_thirty_icons_resolve_through_unified_catalog_without_data_changes() -> void:
	assert_eq(EXPECTED.size(), 30)
	var paths := {}
	for item_id: String in EXPECTED:
		var item = Items.get_definition(item_id)
		assert_not_null(item, item_id)
		if item == null:
			continue
		assert_eq([item.rarity, item.category, item.slot, item.required_level], EXPECTED[item_id], item_id)
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
		for corner: Vector2i in [Vector2i.ZERO, Vector2i(511, 0), Vector2i(0, 511), Vector2i(511, 511)]:
			assert_eq(pixels.get_pixelv(corner).a, 0.0, item_id)


func test_every_new_icon_reaches_inventory_slot_tooltip_quantity_and_quality_frame() -> void:
	for item_id: String in EXPECTED:
		var item = Items.get_definition(item_id)
		var slot = Slot.instantiate()
		add_child(slot)
		slot.configure({
			"title": item.display_name,
			"icon": item.icon,
			"rarity": item.rarity,
			"quantity": 2,
			"tooltip": item.description,
		})
		assert_eq(slot.item_texture, item.icon, item_id)
		assert_true(slot.get_node("ItemIcon").visible, item_id)
		assert_eq(slot.get_node("ItemIcon").texture, item.icon, item_id)
		assert_eq(slot.get_node("QuantityBadge").text, "×2", item_id)
		assert_eq(slot.get_theme_stylebox("normal").border_color, Palette.color_for(item.rarity), item_id)
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
