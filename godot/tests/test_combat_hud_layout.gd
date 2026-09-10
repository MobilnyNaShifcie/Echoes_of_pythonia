extends GutTest

const Combat = preload("res://ui/screens/combat/combat.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Skills = preload("res://core/skills/skill_catalog.gd")
const Items = preload("res://core/items/item_catalog.gd")


func test_compact_decks_keep_card_size_and_center_the_whole_command_group() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		for code: String in ["none", "warrior", "mage", "hunter"]:
			var host := Control.new()
			host.size = dimensions
			add_child(host)
			var session = _session(code, 5 if code == "warrior" else 30)
			var screen = _screen(session, host)
			await _settle()
			var player_hud: Control = screen.get_node("Page/Lower/PlayerCommandHud")
			var dock: Control = screen.get_node("Page/Lower/ActionsDock")
			var lower: Control = screen.get_node("Page/Lower")
			assert_lte(player_hud.get_global_rect().end.x, dock.global_position.x)
			assert_almost_eq(
				(player_hud.global_position.x + dock.get_global_rect().end.x) / 2.0,
				host.get_global_rect().get_center().x,
				1.0,
				code
			)
			assert_lte(dock.size.x, 1120.0, code)
			assert_lte(lower.get_global_rect().end.y, dimensions.y + 1.0, code)
			assert_lte(lower.size.y, 390.0, "The command drawer must hug its content: " + code)
			assert_gte(screen.get_node("Page/Arena").size.y, dimensions.y * 0.5, code)
			assert_false(screen.get_node("Page/Lower/TargetCommandHud").is_visible_in_tree())
			for card in screen.skill_cards.get_children():
				assert_almost_eq(card.size.x, 148.0, 0.1, code)
				assert_almost_eq(card.size.y, 180.0, 0.1, code)
				assert_lte(
					card.get_global_rect().end.y, screen.skill_cards_scroll.get_global_rect().end.y
				)
			for button in [screen.attack_button, screen.defend_button, screen.flee_button]:
				assert_lte(button.size.x, 190.0, code)
			host.free()


func test_single_skill_has_no_useless_scrollbar_or_arrows() -> void:
	var screen = _screen(_session("warrior", 5))
	await _settle()
	assert_eq(screen.skill_cards.get_child_count(), 1)
	assert_false(screen.skill_cards_scroll.get_h_scroll_bar().is_visible_in_tree())
	assert_false(screen.scroll_next_button.visible)
	assert_false(screen.scroll_previous_button.visible)
	assert_almost_eq(screen.get_node("Page/Lower/ActionsDock").size.x, 480.0, 1.0)
	screen.free()


func test_compact_card_mode_does_not_change_the_catalog_variant_on_reuse() -> void:
	var card = load("res://ui/components/combat_action_card/combat_action_card.tscn").instantiate()
	add_child(card)
	var skill = Skills.get_definition("power_slash")
	for compact: bool in [true, false]:
		card.configure(
			skill.skill_id,
			1,
			skill.display_name,
			"6 MANY",
			skill.description,
			true,
			Color.STEEL_BLUE,
			"FIZYCZNE",
			"GOTOWA",
			{"artwork": skill.card_art, "compact": compact}
		)
		assert_eq(card.custom_minimum_size, Vector2(148, 180) if compact else Vector2(168, 212))
		assert_eq(card.artwork.texture, skill.card_art)
		assert_eq(
			card.title_label.autowrap_mode,
			TextServer.AUTOWRAP_WORD_SMART if compact else TextServer.AUTOWRAP_OFF
		)
	card.free()


func test_full_hunter_deck_scrolls_to_last_card_and_back_without_rebuilding() -> void:
	var screen = _screen(_session("hunter", 30))
	await _settle()
	assert_eq(screen.skill_cards.get_child_count(), 11)
	assert_true(screen.scroll_next_button.is_visible_in_tree())
	var last_card = screen.skill_cards.get_child(10)
	assert_eq(last_card.action_id, "thousand_arrows")
	for attempt in 5:
		screen.scroll_next_button.pressed.emit()
		await _settle()
	assert_true(screen.scroll_next_button.disabled)
	assert_lte(
		last_card.get_global_rect().end.x, screen.skill_cards_scroll.get_global_rect().end.x + 1
	)
	assert_gte(last_card.global_position.x, screen.skill_cards_scroll.global_position.x)
	for attempt in 5:
		screen.scroll_previous_button.pressed.emit()
		await _settle()
	assert_eq(screen.skill_cards_scroll.scroll_horizontal, 0)
	assert_eq(screen.skill_cards.get_child(10), last_card)
	assert_true(screen.skill_cards_scroll.follow_focus)
	last_card.grab_focus()
	await _settle()
	assert_lte(
		last_card.get_global_rect().end.x, screen.skill_cards_scroll.get_global_rect().end.x + 1
	)
	screen.skill_cards.get_child(0).grab_focus()
	await _settle()
	assert_eq(screen.skill_cards_scroll.scroll_horizontal, 0)
	screen.free()


func test_resize_reflows_width_without_losing_cards_or_selected_item() -> void:
	var host := Control.new()
	add_child(host)
	var session = _session("hunter", 30)
	session.player.inventory.add("grandmaster_elixir", 2)
	var screen = _screen(session, host)
	var first_card = screen.skill_cards.get_child(0)
	for dimensions: Vector2 in [Vector2(2560, 1080), Vector2(1280, 720), Vector2(1920, 1080)]:
		host.size = dimensions
		await _settle()
		assert_eq(screen.skill_cards.get_child(0), first_card)
		assert_lte(screen.get_node("Page/Lower/ActionsDock").get_global_rect().end.x, dimensions.x)
		assert_eq(screen.consumable_selector.get_item_metadata(0), "grandmaster_elixir")
	host.free()


func test_mage_can_choose_both_spells_in_an_explicit_collapsible_row() -> void:
	var session = _session("mage", 12)
	session.player.unlocked_class_mechanic_ids.assign(["arcana_core", "arcana_double_weave"])
	var screen = _screen(session)
	assert_false(screen.weave_row.visible)
	assert_true(screen.weave_toggle_button.visible)
	screen.weave_toggle_button.button_pressed = true
	assert_true(screen.skill_selector.is_visible_in_tree())
	assert_true(screen.second_spell_selector.is_visible_in_tree())
	screen.skill_selector.select(1)
	screen.skill_selector.item_selected.emit(1)
	screen.second_spell_selector.select(2)
	screen.second_spell_selector.item_selected.emit(2)
	assert_eq(screen.skill_selector.get_item_metadata(1), "frost_lance")
	assert_eq(screen.second_spell_selector.get_item_metadata(2), "lightning")
	screen._engine.mage_arcane_weave = 3
	screen._render()
	assert_false(screen.double_weave_button.disabled)
	var mana_before: int = session.player.stats.current_mana
	var attacks_before: int = screen._enemy.attacks_made
	screen.double_weave_button.pressed.emit()
	assert_eq(session.player.stats.current_mana, mana_before - 16)
	assert_eq(screen._round_number, 2)
	assert_eq(screen._enemy.attacks_made, attacks_before + 1)
	assert_eq(screen._engine.mage_arcane_weave, 0)
	assert_string_contains(screen.combat_log.get_parsed_text(), "Lodowa Lanca + Piorun")
	screen.weave_toggle_button.button_pressed = false
	assert_false(screen.weave_row.visible)
	screen.free()


func test_open_weave_fits_fallback_canvas_and_does_not_enable_locked_pair() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var screen = _screen(_session("mage", 5), host)
	screen.weave_toggle_button.button_pressed = true
	await _settle()
	assert_true(screen.double_weave_button.disabled)
	assert_string_contains(screen.double_weave_button.tooltip_text, "nie jest jeszcze gotowy")
	assert_lte(screen.double_weave_button.get_global_rect().end.x, 1280.0)
	assert_lte(screen.get_node("Page/Lower").get_global_rect().end.y, 720.0)
	screen._set_actions_enabled(false)
	assert_true(screen.skill_selector.disabled)
	assert_true(screen.second_spell_selector.disabled)
	host.free()


func test_selected_restorative_shows_its_inventory_art_and_consumes_only_player_item() -> void:
	var session = _session("warrior", 5)
	session.player.inventory.add("grandmaster_elixir", 2)
	session.player.stats.current_hp = 100
	session.player.stats.current_mana = 0
	var screen = _screen(session)
	assert_eq(screen.potion_button.icon, Items.get_definition("grandmaster_elixir").icon)
	var enemy_hp: int = screen._enemy.current_hp
	screen.potion_button.pressed.emit()
	assert_eq(session.player.inventory.count("grandmaster_elixir"), 1)
	assert_gt(session.player.stats.current_hp, 100)
	assert_gt(session.player.stats.current_mana, 0)
	assert_eq(screen._enemy.current_hp, enemy_hp)
	assert_eq(screen._round_number, 2)
	screen.free()


func test_result_replaces_commands_and_reconfigure_resets_all_transient_panels() -> void:
	var screen = _screen(_session("mage", 12))
	screen.weave_toggle_button.button_pressed = true
	screen.log_toggle_button.pressed.emit()
	screen._enemy.current_hp = 1
	screen._enemy.defense = 0
	screen._enemy.dodge = 0.0
	screen.attack_button.pressed.emit()
	assert_true(screen.result_panel.visible)
	assert_false(screen.get_node("Page/Lower").visible)
	assert_true(screen.continue_button.is_visible_in_tree())
	screen.configure(_session("warrior", 5), "wolf", "expedition")
	assert_false(screen.result_panel.visible)
	assert_false(screen.get_node("Page/Lower").drawer.opened)
	assert_true(screen.get_node("Page/Lower").drawer.handle.visible)
	assert_false(screen.weave_row.visible)
	assert_false(screen.weave_toggle_button.visible)
	assert_false(screen.log_panel.visible)
	assert_eq(screen.log_toggle_button.text, "Pokaż dziennik")
	screen.free()


func _session(code: String, level: int):
	var session = NewGame.new().create_session("Aria", 1)
	session.player.level = level
	if code != "none":
		session.player.choose_class(code)
	if code == "hunter" and level >= 30:
		for skill in Skills.get_preview_skills_for_class(code):
			if skill.unlock_source == "talent":
				session.player.unlocked_talent_skill_ids.append(skill.skill_id)
	session.player.stats.max_hp = 500
	session.player.stats.max_mana = 500
	session.player.stats.restore_full()
	return session


func _screen(session, host: Node = null):
	var screen = Combat.instantiate()
	screen.configure(session, "wolf", "expedition")
	if host == null:
		screen.set_anchors_preset(Control.PRESET_TOP_LEFT)
		screen.size = Vector2(1920, 1080)
		add_child(screen)
	else:
		host.add_child(screen)
	screen.set_reduced_motion(true)
	screen.get_node("Page/Lower").drawer.pinned = true
	screen.get_node("Page/Lower").drawer.set_open(true, true)
	screen._enemy.max_hp = 5000
	screen._enemy.current_hp = 5000
	screen._enemy.attack = 0
	screen._enemy.dodge = 0.0
	return screen


func _settle() -> void:
	for frame in 5:
		await get_tree().process_frame
