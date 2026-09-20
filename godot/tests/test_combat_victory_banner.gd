extends GutTest

const Combat := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Items := preload("res://core/items/item_catalog.gd")
const VictorySkin := preload("res://ui/screens/combat/victory_skin.gd")
const Presentation := preload("res://ui/presentation/combat_presentation_catalog.gd")


func test_victory_composition_fits_supported_resolutions_without_battle_hud() -> void:
	for dimensions: Vector2 in [
		Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)
	]:
		var screen = _screen(dimensions)
		_win(screen)
		await _settle()
		var view = screen.victory_presentation
		assert_true(view.is_visible_in_tree())
		assert_false(screen.enemy_visual.is_visible_in_tree())
		assert_false(screen.get_node("Page/EncounterHeader").is_visible_in_tree())
		assert_false(screen.get_node("Page/Arena/PlayerPanel").is_visible_in_tree())
		assert_false(screen.get_node("Page/Arena/TurnOrder").is_visible_in_tree())
		assert_true(screen.player_visual.is_visible_in_tree())
		var bounds: Rect2 = screen.get_global_rect().grow(1)
		for control: Control in [
			screen.continue_button,
			view.canvas,
			view.hero_name,
			view.loot_scroll,
			view.achievement_label,
			view.report_button,
			screen.player_visual.static_texture
		]:
			assert_true(
				bounds.encloses(control.get_global_rect()), "%s: %s" % [dimensions, control]
			)
		assert_gte(screen.continue_button.get_global_rect().size.y, 64.0)
		assert_false(
			screen.player_visual.get_global_rect().intersects(view.loot_scroll.get_global_rect())
		)
		assert_lte(view.loot_grid.get_child(0).get_global_rect().size.x, 269.0)
		screen.get_parent().free()


func test_actual_rewards_catalog_icons_names_and_amounts_are_displayed() -> void:
	var screen = _screen(Vector2(1920, 1080))
	_win(screen)
	await _settle()
	var view = screen.victory_presentation
	var receipt: Dictionary = screen._victory_receipt
	assert_eq(view.experience_label.text, "+%d EXP" % receipt.experience)
	assert_eq(view.gold_label.text, "+%d" % receipt.gold)
	assert_eq(view.region_label.text, "Zmierzchowe Równiny")
	assert_eq(view.loot_grid.get_child_count(), receipt.loot_drops.size())
	for index in receipt.loot_drops.size():
		var drop: Dictionary = receipt.loot_drops[index]
		var definition = Items.get_definition(drop.item_id)
		var card: Control = view.loot_grid.get_child(index)
		assert_eq(card.get_child(1).texture, definition.icon)
		assert_eq(card.get_child(3).text, definition.display_name)
		assert_string_contains(card.tooltip_text, "×%d" % drop.quantity)
		var quantity: Label = card.get_child(2)
		assert_eq(quantity.text, "×%d" % drop.quantity)
		assert_lte(quantity.get_minimum_size().y, 30.0)
	assert_string_contains(view.report_text.text, screen.result_label.text)
	assert_string_contains(view.report_text.text, "Przebieg walki")


func test_loot_and_long_report_scroll_without_moving_continue_or_mutating_save() -> void:
	var screen = _screen(Vector2(1366, 768))
	_win(screen)
	await _settle()
	var view = screen.victory_presentation
	var before := _snapshot(screen)
	var button_rect: Rect2 = screen.continue_button.get_global_rect()
	var drops: Array = []
	for index in 12:
		drops.append({"item_id": "wolf_fang", "quantity": index + 1})
	view.set_drops(drops)
	view.report_text.text += "\nMisja Żółć i źdźbła: długi postęp zadania.".repeat(40)
	await _settle()
	assert_eq(view.loot_grid.get_child_count(), 12)
	assert_gt(view.loot_scroll.get_v_scroll_bar().max_value, view.loot_scroll.size.y)
	view.loot_scroll.scroll_vertical = 1000
	await _settle()
	assert_gt(view.loot_scroll.scroll_vertical, 0)
	view.report_button.button_pressed = true
	await _settle()
	assert_true(view.report_panel.is_visible_in_tree())
	assert_false(view.loot_scroll.is_visible_in_tree())
	assert_gt(view.report_text.get_v_scroll_bar().max_value, view.report_text.size.y)
	view.report_button.button_pressed = false
	assert_eq(screen.continue_button.get_global_rect(), button_rect)
	assert_eq(_snapshot(screen), before)


func test_missing_rewards_and_achievements_do_not_create_fake_cards_or_medals() -> void:
	var screen = _screen(Vector2(1280, 720))
	_win(screen)
	var view = screen.victory_presentation
	view.present({}, "Prolog", "Aria", "Pobojowisko")
	await _settle()
	assert_false(view.rewards_strip.visible)
	assert_false(view.loot_scroll.visible)
	assert_false(view.loot_heading.visible)
	assert_false(view.achievement_strip.visible)
	assert_false(view.medal.visible)
	assert_eq(view.loot_grid.get_child_count(), 0)
	assert_eq(view.report_text.text, "Pobojowisko")


func test_long_polish_names_and_multiple_achievements_keep_full_data_in_report() -> void:
	var screen = _screen(Vector2(1280, 720))
	var name_text := "Żaneta Świętopełka Źdźbłowska o Bardzo Długim Imieniu"
	screen._session.player.display_name = name_text
	_win(screen)
	await _settle()
	var view = screen.victory_presentation
	var original_rect: Rect2 = view.canvas.get_global_rect()
	var receipt: Dictionary = screen._victory_receipt.duplicate(true)
	receipt.unlocked_achievements = [
		{"display_name": name_text, "title": "Łowczyni"},
		{"display_name": "Drugie osiągnięcie", "title": "Wędrowiec"}
	]
	view.present(receipt, name_text, name_text, name_text + "\nDrugie osiągnięcie")
	await _settle()
	assert_eq(view.canvas.get_global_rect(), original_rect)
	assert_eq(view.hero_name.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert_eq(view.hero_name.tooltip_text, name_text)
	assert_eq(screen._session.player.display_name, name_text)
	assert_string_contains(view.achievement_label.text, "+1")
	assert_string_contains(view.achievement_label.tooltip_text, "Drugie osiągnięcie")
	assert_string_contains(view.report_text.text, "Drugie osiągnięcie")


func test_reconfigure_restores_battle_and_defeat_layout_without_replacing_hero_art() -> void:
	for class_code: String in ["warrior", "mage", "hunter", "pierrot"]:
		var screen = _screen(Vector2(1920, 1080), class_code)
		await _settle()
		var hero_rect: Rect2 = screen.player_visual.get_global_rect()
		var artwork: Texture2D = screen.player_visual.source_texture()
		_win(screen)
		await _settle()
		assert_eq(screen.player_visual.source_texture(), artwork)
		assert_eq(artwork, Presentation.hero_texture_for_player(screen._session.player))
		screen.configure(screen._session, "wolf", "expedition")
		await _settle()
		assert_eq(screen.player_visual.get_global_rect(), hero_rect)
		assert_false(screen.result_panel.visible)
		assert_false(screen.victory_presentation.visible)
		assert_true(screen.enemy_visual.is_visible_in_tree())
		screen._enemy.attack = 5000
		screen._session.player.stats.dodge = 0.0
		screen.attack_button.pressed.emit()
		await _settle()
		assert_false(screen.victory_presentation.visible)
		assert_true(screen.result_panel.get_node("Result").is_visible_in_tree())
		assert_true(screen.continue_button.is_visible_in_tree())
		screen.get_parent().free()


func test_presentation_focus_refresh_and_continue_never_repeat_reward_awards() -> void:
	var screen = _screen(Vector2(1920, 1080))
	_win(screen)
	await _settle()
	var before := _snapshot(screen)
	for attempt in 3:
		screen._render()
		screen.get_node("Page/Lower").update_layout()
		screen.victory_presentation.report_button.button_pressed = true
		screen.victory_presentation.report_button.button_pressed = false
		screen.attack_button.pressed.emit()
	assert_eq(_snapshot(screen), before)
	watch_signals(screen)
	screen.continue_button.pressed.emit()
	assert_signal_emitted_with_parameters(screen, "finished", ["expedition", "victory"])
	assert_eq(_snapshot(screen), before)
	assert_eq(screen._session.victories, 1)


func test_skin_has_real_transparency_and_all_atlas_regions_are_in_bounds() -> void:
	var pixels := VictorySkin.ATLAS.get_image()
	assert_eq(pixels.get_pixel(0, 0).a, 0.0)
	assert_eq(pixels.get_pixel(640, 510).a, 0.0)
	for region: Rect2 in VictorySkin.REGIONS.values():
		assert_true(Rect2(Vector2.ZERO, VictorySkin.ATLAS.get_size()).encloses(region))


func test_prologue_has_no_fake_rewards_and_escape_closes_its_report() -> void:
	var screen = _screen(Vector2(1280, 720))
	screen.configure(screen._session, "prologue_scarecrow", "prologue")
	_win(screen)
	await _settle()
	var view = screen.victory_presentation
	assert_true(view.is_visible_in_tree())
	assert_eq(view.region_label.text, "Prolog")
	assert_false(view.rewards_strip.visible)
	assert_false(view.achievement_strip.visible)
	assert_string_contains(view.report_text.text, "pełne PŻ")
	assert_eq(screen._session.prologue_stage, 2)
	view.report_button.button_pressed = true
	var escape := InputEventAction.new()
	escape.action = "ui_cancel"
	escape.pressed = true
	view._unhandled_key_input(escape)
	assert_false(view.report_panel.visible)
	assert_false(view.report_button.button_pressed)
	assert_true(screen.continue_button.is_visible_in_tree())


func _screen(dimensions: Vector2, class_code := "warrior"):
	var host := Control.new()
	host.size = dimensions
	add_child_autofree(host)
	var session = NewGame.new().create_session("Aria", 1, null, "female")
	session.player.level = 5
	session.player.choose_class(class_code)
	var screen = Combat.instantiate()
	screen.configure(session, "wolf", "expedition")
	host.add_child(screen)
	screen.set_reduced_motion(true)
	screen._rng.seed = 83
	return screen


func _win(screen) -> void:
	screen._enemy.current_hp = 1
	screen._enemy.defense = 0
	screen._enemy.dodge = 0.0
	screen.attack_button.pressed.emit()


func _snapshot(screen) -> Dictionary:
	var result: Dictionary = Saves.new("user://unused-victory-test")._serialize_session(
		screen._session
	)
	result.erase("saved_at_unix")
	return result


func _settle() -> void:
	for frame in 8:
		await get_tree().process_frame
