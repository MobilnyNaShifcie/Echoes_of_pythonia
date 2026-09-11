extends GutTest

const Items = preload("res://core/items/item_catalog.gd")
const Slot = preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")
const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const EXPECTED := {
	"echo_quiver": ["rare", "equipment", "off_hand", 14],
	"weave_relic": ["rare", "equipment", "off_hand", 14],
	"trickster_card_deck": ["rare", "equipment", "off_hand", 14],
	"rift_bastion_shield": ["legendary", "equipment", "off_hand", 18],
	"last_guard_plate": ["legendary", "equipment", "chest", 18],
	"oathbreaker_edge": ["legendary", "equipment", "weapon", 18],
	"warden_chain": ["epic", "equipment", "bracelet", 18],
	"third_echo_quiver": ["legendary", "equipment", "off_hand", 18],
	"riftglass_bow": ["legendary", "equipment", "weapon", 18],
	"silent_volley_cloak": ["legendary", "equipment", "chest", 18],
	"afterimage_ring": ["epic", "equipment", "ring", 18],
	"split_weave_artifact": ["legendary", "equipment", "off_hand", 18],
	"twin_star_staff": ["legendary", "equipment", "weapon", 18],
	"empty_mana_robe": ["legendary", "equipment", "chest", 18],
	"storm_archive_relic": ["epic", "equipment", "necklace", 18],
	"two_lies_dice": ["legendary", "equipment", "off_hand", 18],
	"deck_without_ace": ["legendary", "equipment", "off_hand", 18],
	"seven_chances_lance": ["mythic", "equipment", "weapon", 18],
	"crooked_smile_mask": ["legendary", "equipment", "head", 18],
}


func test_all_nineteen_icons_resolve_through_unified_catalog_without_data_changes() -> void:
	assert_eq(EXPECTED.size(), 19)
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


func test_all_nineteen_items_reach_the_actual_equipment_screen() -> void:
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


func test_all_existing_catalog_items_now_have_art() -> void:
	var definitions := Items.get_all_definitions()
	assert_eq(definitions.size(), 159)
	var seen := {}
	for item in definitions:
		assert_false(seen.has(item.item_id), item.item_id)
		seen[item.item_id] = true
		assert_not_null(item.icon, item.item_id)
		if item.icon != null:
			assert_gt(item.icon.get_width(), 0, item.item_id)
			assert_gt(item.icon.get_height(), 0, item.item_id)
