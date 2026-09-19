extends GutTest
const Screen := preload("res://ui/screens/city_economy/city_economy.tscn")
const Book := preload("res://ui/screens/workshop_book/workshop_book.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Crafting := preload("res://core/economy/crafting_service.gd")
const Catalog := preload("res://core/items/item_catalog.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const ThemeResource := preload("res://ui/theme/game_theme.tres")
const App := preload("res://scenes/app/app.tscn")


func after_each() -> void:
	await wait_process_frames(3)


func _mount(session, dimensions := Vector2i(1920, 1080), open := true):
	var viewport := SubViewport.new()
	viewport.size = dimensions
	var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
	viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
	viewport.size_2d_override_stretch = true
	add_child_autofree(viewport)
	var screen = Screen.instantiate()
	screen.theme = ThemeResource
	screen.configure(session, "workshop")
	viewport.add_child(screen)
	if open:
		screen._open_service()
	await wait_process_frames(8)
	return screen


func _snapshot(session) -> Dictionary:
	var data := Saves.new("user://workshop_snapshot_not_written")._serialize_session(session)
	data.erase("saved_at_unix")
	return data


func _bounds(control: Control) -> Rect2:
	var transform := control.get_global_transform()
	return Rect2(transform * Vector2.ZERO, transform * control.size - transform * Vector2.ZERO)


func _click(control: Control) -> void:
	var viewport := control.get_viewport()
	var point := _bounds(control).get_center()
	var motion := InputEventMouseMotion.new()
	motion.position = point
	viewport.push_input(motion, true)
	await wait_process_frames(1)
	var event := InputEventMouseButton.new()
	event.position = point
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	viewport.push_input(event, true)
	event = event.duplicate()
	event.pressed = false
	viewport.push_input(event, true)
	await wait_process_frames(3)


func test_npc_dialogue_precedes_book_and_original_art_is_preserved() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	var screen = await _mount(session, Vector2i(1920, 1080), false)
	var background: Texture2D = screen.location_background.texture
	var before := _snapshot(session)
	assert_false(screen.workshop_book.visible)
	await _click(screen.npc_hit_area)
	assert_eq(screen._interaction_state, "focused")
	assert_true(screen.npc_action_panel.visible)
	assert_false(screen.workshop_book.visible)
	await _click(screen.open_service_button)
	assert_true(screen.workshop_book.visible)
	assert_eq(screen.location_background.texture, background)
	assert_eq(
		background.resource_path,
		"res://assets/city/varenhold/interiors/mirela_workshop_anime_integrated_v5.png"
	)
	assert_false(screen.service_grid.is_visible_in_tree())
	assert_false(screen.quantity_box.is_visible_in_tree())
	assert_false(screen.summary_label.is_visible_in_tree())
	assert_eq(_snapshot(session), before)


func test_all_42_canonical_recipes_are_reachable_with_mouse_pagination() -> void:
	var session = NewGame.new().create_session("Żaneta Źródlana", 1)
	var screen = await _mount(session)
	var book = screen.workshop_book
	var before := _snapshot(session)
	var seen: Array[String] = []
	for region in 5:
		await _click(book.region_buttons[region])
		assert_eq(book.region_index, region)
		assert_eq(book.region_buttons.filter(func(button): return button.button_pressed).size(), 1)
		for page_index in ceili(book.recipes.size() / 6.0):
			for row in book.recipe_buttons:
				if not row.visible:
					continue
				await _click(row)
				var recipe: Dictionary = book.selected_recipe()
				seen.append(recipe.recipe_id)
				assert_eq(recipe, Crafting.get_recipe(recipe.recipe_id))
				assert_eq(
					book.recipe_image.texture, Catalog.get_definition(recipe.output_item_id).icon
				)
				assert_eq(book.recipe_title.text, recipe.name)
			if not book.next_button.disabled:
				await _click(book.next_button)
		assert_true(book.next_button.disabled)
	assert_eq(seen.size(), 42)
	for recipe_id in seen:
		assert_eq(seen.count(recipe_id), 1)
	assert_eq(
		_snapshot(session),
		before,
		"Browsing never mutates player data or creates equipment instances"
	)


func test_every_ingredient_and_gold_cost_matches_backend() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	var book = (await _mount(session)).workshop_book
	for region in 5:
		book.select_region(region)
		for index in book.recipes.size():
			book.select_recipe(index)
			var recipe: Dictionary = book.selected_recipe()
			var expected: int = recipe.ingredients.size() + int(int(recipe.get("gold_cost", 0)) > 0)
			assert_eq(book.ingredients.get_child_count(), expected, recipe.name)
			for item_id: String in recipe.ingredients:
				var row = book.ingredients.get_node(item_id)
				assert_eq(row.get_meta("required"), int(recipe.ingredients[item_id]))
				assert_eq(row.get_meta("owned"), session.player.inventory.count(item_id))
			if int(recipe.get("gold_cost", 0)) > 0:
				assert_eq(
					book.ingredients.get_node("gold").get_meta("required"), int(recipe.gold_cost)
				)
			else:
				assert_null(book.ingredients.get_node_or_null("gold"))
			assert_eq(
				book.craft_button.disabled,
				not Crafting.get_craft_error(session.player, recipe.recipe_id).is_empty()
			)


func test_full_requirements_and_controls_fit_at_supported_resolutions() -> void:
	for dimensions: Vector2i in [Vector2i(1920, 1080), Vector2i(1366, 768), Vector2i(1280, 720)]:
		var book = (await _mount(NewGame.new().create_session("Aria", 1), dimensions)).workshop_book
		var screen_bounds := Rect2(Vector2.ZERO, Vector2(1920, 1080))
		assert_true(screen_bounds.encloses(_bounds(book.book_canvas)))
		for region in 5:
			book.select_region(region)
			for index in book.recipes.size():
				book.select_recipe(index)
				await wait_process_frames(3)
				var bounds := _bounds(book.ingredient_scroll).grow(1)
				for row in book.ingredients.get_children():
					assert_true(
						bounds.encloses(_bounds(row)),
						"%s: %s %s" % [dimensions, book.recipe_title.text, row.name]
					)
				assert_false(book.ingredient_scroll.get_v_scroll_bar().visible)
				assert_true(screen_bounds.encloses(_bounds(book.craft_button)))
				assert_false(_bounds(book.craft_button).intersects(_bounds(book.ingredient_scroll)))
		await _click(book.region_buttons[0])
		await _click(book.recipe_buttons[4])
		assert_eq(book.selected_recipe().recipe_id, "sharpened_sword")
		assert_string_contains(book.description.text, "Stary Miecz musi znajdować się w plecaku.")


func test_craft_consumes_once_refreshes_counts_and_emits_save_signal() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 3)
	var screen = await _mount(session)
	watch_signals(screen)
	var book = screen.workshop_book
	var equipment_before: Dictionary = session.player.equipment.slots.duplicate()
	var gold: int = session.player.gold
	await _click(book.craft_button)
	assert_eq(session.player.inventory.count("leather_hood"), 1)
	assert_eq(session.player.inventory.count("weak_leather"), 1)
	assert_eq(session.player.gold, gold)
	assert_eq(session.player.equipment.slots, equipment_before)
	assert_eq(book.ingredients.get_node("weak_leather").get_meta("owned"), 1)
	assert_true(book.craft_button.disabled)
	assert_eq(book.recipe_buttons[0].get_node("Ready").text, "")
	assert_signal_emit_count(screen, "state_changed", 1)
	assert_string_contains(session.last_activity, "Wytworzono")
	await _click(book.craft_button)
	assert_eq(session.player.inventory.count("leather_hood"), 1)
	assert_signal_emit_count(screen, "state_changed", 1)


func test_craft_rechecks_stale_resources_without_partial_consumption() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 2)
	var screen = await _mount(session)
	watch_signals(screen)
	var book = screen.workshop_book
	assert_false(book.craft_button.disabled)
	session.player.inventory.remove_item("weak_leather", 1)
	var before := _snapshot(session)
	await _click(book.craft_button)
	assert_eq(_snapshot(session), before)
	assert_signal_not_emitted(screen, "state_changed")
	assert_true(book.craft_button.disabled)
	assert_string_contains(book.feedback.text, "Brakuje składnika")


func test_paid_regional_recipe_consumes_all_materials_and_keeps_selection() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	var recipe := Crafting.get_recipe("leviathan_ring")
	session.player.gold = recipe.gold_cost + 71
	for item_id: String in recipe.ingredients:
		session.player.inventory.add(item_id, int(recipe.ingredients[item_id]) + 2)
	var book = (await _mount(session)).workshop_book
	book.select_region(4)
	book.select_recipe(3)
	await _click(book.craft_button)
	assert_eq(book.selected_recipe().recipe_id, "leviathan_ring")
	assert_eq(book.region_index, 4)
	assert_eq(session.player.gold, 71)
	for item_id: String in recipe.ingredients:
		assert_eq(session.player.inventory.count(item_id), 2)
	assert_eq(session.player.inventory.count(recipe.output_item_id), int(recipe.quantity))
	assert_eq(book.ingredients.get_node("gold").get_meta("owned"), 71)


func test_equipped_ingredient_is_never_taken_from_character() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	session.player.inventory.add("whetstone", 2)
	var book = (await _mount(session)).workshop_book
	book.select_recipe(4)
	var before := _snapshot(session)
	assert_true(book.craft_button.disabled)
	book._craft()
	assert_eq(_snapshot(session), before)
	assert_string_contains(book.craft_button.tooltip_text, "Stary Miecz")


func test_close_back_escape_and_reopen_do_not_craft_or_reset_player() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	var screen = await _mount(session)
	var before := _snapshot(session)
	await _click(screen.workshop_book.services_button)
	assert_eq(screen._interaction_state, "focused")
	assert_false(screen.workshop_book.visible)
	await _click(screen.open_service_button)
	await _click(screen.workshop_book.close_button)
	assert_eq(screen._interaction_state, "ambient")
	screen._open_service()
	screen.workshop_book.craft_button.grab_focus()
	var escape := InputEventKey.new()
	escape.keycode = KEY_ESCAPE
	escape.pressed = true
	screen.get_viewport().push_input(escape, true)
	await wait_process_frames(3)
	assert_eq(screen._interaction_state, "ambient")
	screen.workshop_book._craft()
	assert_eq(_snapshot(session), before)
	screen._open_service()
	assert_eq(screen.workshop_book.selected_recipe().recipe_id, "leather_hood")


func test_invalid_navigation_cannot_mutate_recipe_or_player() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	var book = (await _mount(session)).workshop_book
	var before := _snapshot(session)
	book.select_region(-1)
	book.select_region(500)
	book.select_recipe(-1)
	book.select_recipe(500)
	book.change_page(-1)
	assert_eq(book.selected_recipe().recipe_id, "leather_hood")
	assert_eq(_snapshot(session), before)


func test_book_can_be_configured_before_entering_tree() -> void:
	var book = Book.instantiate()
	book.configure(NewGame.new().create_session("Aria", 1))
	add_child_autofree(book)
	assert_eq(book.selected_recipe().recipe_id, "leather_hood")
	assert_eq(book.recipe_title.text, "Skórzany Kaptur")
	assert_eq(book.ingredients.get_child_count(), 1)


func test_keyboard_accept_can_select_and_craft_without_mouse() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	session.player.inventory.add("weak_leather", 2)
	var book = (await _mount(session)).workshop_book
	for control in [
		book.region_buttons[1], book.region_buttons[0], book.recipe_buttons[0], book.craft_button
	]:
		control.grab_focus()
		var accept := InputEventAction.new()
		accept.action = "ui_accept"
		accept.pressed = true
		book.get_viewport().push_input(accept, true)
		accept = accept.duplicate()
		accept.pressed = false
		book.get_viewport().push_input(accept, true)
		await wait_process_frames(2)
	assert_eq(session.player.inventory.count("leather_hood"), 1)
	assert_eq(session.player.inventory.count("weak_leather"), 0)


func test_real_app_autosave_restores_crafted_item_and_unchanged_equipment() -> void:
	var session = NewGame.new().create_session("Żaneta Źródlana", 1)
	session.player.inventory.add("weak_leather", 4)
	var saves := Saves.new("user://workshop_book_test_" + str(Time.get_ticks_usec()))
	var app = App.instantiate()
	app._save_service = saves
	add_child_autofree(app)
	app._current_session = session
	app._show_city_service("workshop")
	var screen = app.screen_host.get_child(0)
	screen._open_service()
	screen.workshop_book.craft_button.pressed.emit()
	var crafted = session.player.inventory.equipment_items.back()
	var result := saves.load_session(1)
	assert_true(result.ok, result.message)
	if not result.ok:
		return
	assert_eq(result.session.player.display_name, "Żaneta Źródlana")
	assert_eq(result.session.player.inventory.count("leather_hood"), 1)
	assert_eq(result.session.player.inventory.count("weak_leather"), 2)
	assert_eq(
		result.session.player.inventory.equipment_items.back().instance_id, crafted.instance_id
	)
	assert_eq(
		result.session.player.equipment.get_item("weapon").instance_id,
		session.player.equipment.get_item("weapon").instance_id
	)
	assert_eq(result.session.player.gold, session.player.gold)
	assert_eq(result.session.last_activity, session.last_activity)
