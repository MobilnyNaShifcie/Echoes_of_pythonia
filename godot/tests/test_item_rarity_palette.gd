extends GutTest

const Palette = preload("res://ui/presentation/item_rarity_palette.gd")
const Items = preload("res://core/items/item_catalog.gd")
const Slot = preload("res://ui/components/inventory_grid/inventory_item_slot.tscn")


func test_all_existing_items_have_one_of_six_distinct_rarity_colors() -> void:
	assert_eq(Palette.ORDER, ["common", "uncommon", "rare", "epic", "legendary", "mythic"])
	assert_eq(Palette.COLORS.values().size(), 6)
	for definition in Items.get_all_definitions():
		assert_true(Palette.COLORS.has(definition.rarity), definition.item_id)
	assert_eq(Palette.color_for("rare"), Color("#4f96e8"))
	assert_eq(Palette.color_for("epic"), Color("#aa69dc"))
	assert_eq(Palette.color_for("legendary"), Color("#e35b62"))
	assert_eq(Palette.color_for("mythic"), Color("#f49b3f"))


func test_slots_preserve_quality_even_when_locked_and_use_consistent_frames() -> void:
	var slot = Slot.instantiate()
	add_child_autofree(slot)
	for rarity in Palette.ORDER:
		for locked in [false, true]:
			slot.configure({"rarity": rarity, "locked": locked, "quantity": 1})
			assert_eq(slot.rarity, rarity)
			assert_eq(slot.get_theme_stylebox("normal").border_color, Palette.color_for(rarity))
			assert_eq(slot.get_theme_stylebox("normal").border_width_left, 2)
	assert_eq(Palette.normalize("  LEGENDARY "), "legendary")
	assert_eq(Palette.normalize("invalid"), "common")
