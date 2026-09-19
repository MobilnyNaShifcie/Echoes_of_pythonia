extends GutTest

const Combat := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Saves := preload("res://core/save/save_game_service.gd")
const Style := preload("res://ui/screens/combat/combat_visual_style.gd")


func test_empty_effects_hide_but_real_guard_bleed_and_weather_remain_visible() -> void:
	var screen = _screen(Vector2(1920, 1080))
	assert_false(screen.player_effect_label.visible)
	assert_false(screen.enemy_effect_label.visible)
	screen._engine.effects.player_guard_hits = 2
	screen._engine.effects.enemy_bleed_turns = 2
	screen._render()
	assert_true(screen.player_effect_label.visible)
	assert_string_contains(screen.player_effect_label.text, "GARDA")
	assert_true(screen.enemy_effect_label.visible)
	assert_string_contains(screen.enemy_effect_label.tooltip_text, "KRWAWIENIE")
	screen.configure(screen._session, "wolf", "expedition", "storm")
	assert_true(screen.enemy_effect_label.visible)
	assert_false(screen.player_effect_label.visible)


func test_defeat_remains_readable_and_does_not_move_actors_on_supported_canvases() -> void:
	for dimensions: Vector2 in [
		Vector2(1280, 720), Vector2(1366, 768), Vector2(1920, 1080), Vector2(2560, 1080)
	]:
		var screen = _screen(dimensions)
		await _settle()
		var hero: Rect2 = screen.player_visual.get_global_rect()
		var enemy: Rect2 = screen.enemy_visual.get_global_rect()
		_lose(screen)
		await _settle()
		assert_eq(screen.player_visual.get_global_rect(), hero)
		assert_eq(screen.enemy_visual.get_global_rect(), enemy)
		assert_true(screen.result_panel.visible)
		assert_gte(screen.result_panel.size.y, 238.0)
		assert_true(screen.get_global_rect().encloses(screen.result_panel.get_global_rect()))
		assert_true(
			screen.result_panel.get_global_rect().encloses(screen.continue_button.get_global_rect())
		)
		assert_gte(screen.result_label.get_theme_font_size("font_size"), 22)
		assert_eq(screen.loot_presentation.loot_grid.cell_size, Vector2(72, 72))
		var original_size: Vector2 = screen.result_panel.size
		screen.result_label.text += "\nDługi raport: Łucja — Żółć, osiągnięcie i zadanie.".repeat(
			25
		)
		await _settle()
		assert_eq(screen.result_panel.size, original_size)
		var report_scroll: ScrollContainer = screen.result_label.get_parent()
		assert_gt(report_scroll.get_v_scroll_bar().max_value, report_scroll.size.y)
		assert_lte(screen.continue_button.get_global_rect().end.y, report_scroll.global_position.y)
		screen.get_parent().free()


func test_legacy_result_loot_overflow_scrolls_without_hiding_continue() -> void:
	var screen = _screen(Vector2(1280, 720))
	_lose(screen)
	await _settle()
	var initial_size: Vector2 = screen.result_panel.size
	var drops: Array = []
	for index in 12:
		drops.append({"item_id": "wolf_fang", "quantity": index + 1})
	screen.loot_presentation.set_drops(drops)
	await _settle()
	var grid: InventoryGridView = screen.loot_presentation.loot_grid
	var scroll: ScrollContainer = grid.get_parent()
	assert_eq(grid.entry_count(), 12)
	assert_eq(screen.result_panel.size, initial_size)
	assert_gt(scroll.get_v_scroll_bar().max_value, scroll.size.y)
	scroll.scroll_vertical = 1000
	await _settle()
	assert_gt(scroll.scroll_vertical, 0)
	assert_true(screen.continue_button.is_visible_in_tree())


func test_presentation_refresh_and_result_interaction_never_duplicate_rewards() -> void:
	var screen = _screen(Vector2(1920, 1080))
	_win(screen)
	var codec := Saves.new("user://unused-stage-one-test")
	var before: Dictionary = codec._serialize_session(screen._session)
	before.erase("saved_at_unix")
	for attempt in 4:
		screen._render()
		screen.get_node("Page/Lower").update_layout()
		screen.attack_button.pressed.emit()
		screen.defend_button.pressed.emit()
		screen.log_toggle_button.pressed.emit()
	var after: Dictionary = codec._serialize_session(screen._session)
	after.erase("saved_at_unix")
	assert_eq(after, before)
	assert_eq(screen._session.victories, 1)
	watch_signals(screen)
	screen.continue_button.pressed.emit()
	assert_signal_emitted_with_parameters(screen, "finished", ["expedition", "victory"])
	after = codec._serialize_session(screen._session)
	after.erase("saved_at_unix")
	assert_eq(after, before)


func test_reconfigure_preserves_player_name_and_clears_terminal_view() -> void:
	var screen = _screen(Vector2(1280, 720))
	screen._session.player.display_name = "Żaneta Świętopełka Źdźbłowska o Długim Imieniu"
	screen._render()
	await _settle()
	var original_name: String = screen._session.player.display_name
	assert_eq(screen.player_name_label.text_overrun_behavior, TextServer.OVERRUN_TRIM_ELLIPSIS)
	assert_string_contains(screen.player_name_label.tooltip_text, original_name)
	_win(screen)
	screen.configure(screen._session, "wolf", "expedition")
	await _settle()
	assert_false(screen.result_panel.visible)
	assert_true(screen.get_node("Page/Lower").drawer.handle.visible)
	assert_eq(screen._session.player.display_name, original_name)
	assert_true(
		screen.get_global_rect().encloses(
			screen.get_node("Page/Arena/PlayerPanel").get_global_rect()
		)
	)


func test_button_hover_focus_and_disabled_do_not_change_geometry() -> void:
	var button := Button.new()
	add_child_autofree(button)
	button.text = "Atak"
	Style.button(button, true)
	var normal := button.get_theme_stylebox("normal")
	for state: String in ["hover", "pressed", "focus", "disabled"]:
		assert_eq(button.get_theme_stylebox(state).get_minimum_size(), normal.get_minimum_size())
	assert_ne(
		button.get_theme_stylebox("focus").border_color,
		button.get_theme_stylebox("disabled").border_color
	)


func _screen(dimensions: Vector2):
	var host := Control.new()
	host.size = dimensions
	add_child_autofree(host)
	var session = NewGame.new().create_session("Aria", 1, null, "female")
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


func _lose(screen) -> void:
	screen._enemy.attack = 5000
	screen._session.player.stats.dodge = 0.0
	screen.attack_button.pressed.emit()


func _settle() -> void:
	for frame in 8:
		await get_tree().process_frame
