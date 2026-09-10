extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const ConsumableServiceClass := preload("res://core/items/consumable_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const RESTORATIVES := [
	"weak_healing_potion",
	"strong_healing_potion",
	"hunter_provisions",
	"grandmaster_elixir",
	"great_healing_potion",
]

var _test_item_original := {}


func after_each() -> void:
	var definition = ItemCatalogClass.get_definition("slime_gel")
	for property: String in _test_item_original:
		definition.set(property, _test_item_original[property])
	_test_item_original.clear()


func test_catalog_discovers_all_five_restoratives_and_excludes_other_items() -> void:
	var session = _session()
	for item_id: String in RESTORATIVES:
		assert_true(session.player.inventory.add(item_id))
	session.player.inventory.add("slime_gel")
	session.player.inventory.add("mastery_strength_book")
	session.player.inventory.add("starter_sword")
	var found := ConsumableServiceClass.restorative_items_in_inventory(session.player)
	assert_eq(found.size(), 5)
	for item_id: String in RESTORATIVES:
		assert_has(found, item_id)


func test_new_catalog_restorative_works_without_a_combat_allowlist() -> void:
	var definition = ItemCatalogClass.get_definition("slime_gel")
	_test_item_original = {
		"category": definition.category,
		"restore_mana": definition.restore_mana,
	}
	definition.category = "consumable"
	definition.restore_mana = 11
	var session = _session()
	session.player.stats.current_hp = 500
	session.player.inventory.add(definition.item_id)
	var screen := _screen(session)
	assert_eq(screen.consumable_selector.item_count, 1)
	assert_eq(screen.consumable_selector.get_item_metadata(0), definition.item_id)
	screen.potion_button.pressed.emit()
	assert_eq(session.player.stats.current_mana, 11)
	assert_eq(session.player.inventory.count(definition.item_id), 0)


func test_selector_and_use_button_belong_to_player_not_enemy() -> void:
	var session = _session()
	session.player.inventory.add("great_healing_potion", 2)
	var screen := _screen(session)
	var player_hud := screen.get_node("Page/Lower/PlayerCommandHud")
	var enemy_hud := screen.get_node("Page/Lower/TargetCommandHud")
	assert_true(player_hud.is_ancestor_of(screen.consumable_selector))
	assert_true(player_hud.is_ancestor_of(screen.potion_button))
	assert_false(enemy_hud.is_ancestor_of(screen.consumable_selector))
	assert_false(enemy_hud.is_ancestor_of(screen.potion_button))
	assert_eq(screen.consumable_selector.get_parent(), screen.potion_button.get_parent())
	assert_string_contains(screen.consumable_selector.get_item_text(0), "×2")
	assert_true(screen.consumable_selector.get_item_text(0).begins_with("×2"))
	assert_eq(screen.consumable_hint.text, "Użycie zajmuje turę.")


func test_each_restorative_heals_player_spends_one_item_and_one_turn() -> void:
	for item_id: String in RESTORATIVES:
		var session = _session()
		session.player.inventory.add(item_id, 2)
		var preview := ConsumableServiceClass.preview_use(session.player, item_id)
		var screen := _screen(session)
		var enemy_hp: int = screen._enemy.current_hp
		assert_false(screen.potion_button.disabled, item_id)
		screen.potion_button.pressed.emit()
		assert_eq(session.player.stats.current_hp, int(preview.healed_hp), item_id)
		assert_eq(session.player.stats.current_mana, int(preview.restored_mana), item_id)
		assert_eq(session.player.inventory.count(item_id), 1, item_id)
		assert_eq(screen._round_number, 2, item_id)
		assert_eq(screen._enemy.current_hp, enemy_hp, item_id)
		assert_string_contains(screen.combat_log.get_parsed_text(), "Otrzymujesz 1 obrażeń")
		assert_string_contains(screen.consumable_selector.get_item_text(0), "×1")


func test_full_resources_block_even_direct_use_without_consuming_turn() -> void:
	for item_id: String in RESTORATIVES:
		var session = _session()
		session.player.stats.restore_full()
		session.player.inventory.add(item_id)
		var screen := _screen(session)
		assert_true(screen.potion_button.disabled, item_id)
		screen._set_actions_enabled(true)
		assert_true(screen.potion_button.disabled, item_id)
		screen.potion_button.pressed.emit()
		assert_eq(session.player.inventory.count(item_id), 1, item_id)
		assert_eq(screen._round_number, 1, item_id)
		assert_eq(session.player.stats.current_hp, 500)
		assert_eq(session.player.stats.current_mana, 100)


func test_health_only_item_cannot_be_wasted_when_only_mana_is_missing() -> void:
	var session = _session()
	session.player.stats.current_hp = 500
	session.player.inventory.add("weak_healing_potion")
	session.player.inventory.add("grandmaster_elixir")
	var screen := _screen(session)
	_select(screen, "weak_healing_potion")
	assert_true(screen.potion_button.disabled)
	assert_eq(screen.consumable_hint.text, "Masz już pełne PŻ.")
	screen.potion_button.pressed.emit()
	assert_eq(session.player.inventory.count("weak_healing_potion"), 1)
	assert_eq(screen._round_number, 1)
	_select(screen, "grandmaster_elixir")
	assert_false(screen.potion_button.disabled)
	assert_string_contains(screen.potion_button.text, "+20 Many")
	screen.potion_button.pressed.emit()
	assert_eq(session.player.stats.current_mana, 20)
	assert_eq(session.player.inventory.count("grandmaster_elixir"), 0)


func test_elixir_is_usable_when_only_health_is_missing() -> void:
	var session = _session()
	session.player.stats.current_mana = 100
	session.player.inventory.add("grandmaster_elixir")
	var screen := _screen(session)
	assert_false(screen.potion_button.disabled)
	screen.potion_button.pressed.emit()
	assert_eq(session.player.stats.current_hp, 175)
	assert_eq(session.player.stats.current_mana, 100)


func test_no_items_and_last_item_leave_a_clear_disabled_control() -> void:
	var session = _session()
	var screen := _screen(session)
	assert_true(screen.potion_button.disabled)
	assert_false(screen.consumable_selector.visible)
	assert_string_contains(screen.consumable_hint.text, "Brak przedmiotów")
	session.player.inventory.add("great_healing_potion")
	screen._render()
	assert_false(screen.potion_button.disabled)
	screen.potion_button.pressed.emit()
	assert_eq(session.player.inventory.count("great_healing_potion"), 0)
	assert_true(screen.potion_button.disabled)
	assert_false(screen.consumable_selector.visible)
	assert_eq(screen.consumable_selector.item_count, 0)


func test_stale_selection_cannot_spend_a_missing_item_or_a_turn() -> void:
	var session = _session()
	session.player.inventory.add("great_healing_potion")
	var screen := _screen(session)
	session.player.inventory.remove_item("great_healing_potion")
	screen.potion_button.pressed.emit()
	assert_eq(session.player.stats.current_hp, 1)
	assert_eq(screen._round_number, 1)
	assert_eq(screen.consumable_selector.item_count, 0)
	assert_true(screen.potion_button.disabled)


func test_selection_survives_refresh_and_moves_after_stack_is_depleted() -> void:
	var session = _session()
	session.player.inventory.add("weak_healing_potion", 2)
	session.player.inventory.add("great_healing_potion")
	var screen := _screen(session)
	_select(screen, "great_healing_potion")
	screen._render()
	assert_eq(
		screen.consumable_selector.get_item_metadata(screen.consumable_selector.selected),
		"great_healing_potion"
	)
	screen.potion_button.pressed.emit()
	assert_eq(screen.consumable_selector.item_count, 1)
	assert_eq(screen.consumable_selector.get_item_metadata(0), "weak_healing_potion")
	assert_false(screen.potion_button.disabled)


func test_animation_blocks_repeat_use_and_unlocks_after_playback() -> void:
	var session = _session()
	session.player.inventory.add("weak_healing_potion", 3)
	var screen := _screen(session)
	screen.set_reduced_motion(false)
	screen._presentation_controller.animation_duration_scale = 0.01
	screen.potion_button.pressed.emit()
	assert_true(screen._presentation_controller.is_busy())
	assert_true(screen.potion_button.disabled)
	assert_true(screen.consumable_selector.disabled)
	screen.potion_button.pressed.emit()
	assert_eq(session.player.inventory.count("weak_healing_potion"), 2)
	assert_eq(screen._round_number, 2)
	await screen._presentation_controller.playback_finished
	await get_tree().process_frame
	assert_false(screen.potion_button.disabled)
	assert_false(screen.consumable_selector.disabled)


func test_finished_battle_cannot_use_a_potion() -> void:
	var session = _session()
	session.player.inventory.add("weak_healing_potion")
	var screen := _screen(session)
	screen._engine.result = "fled"
	screen._set_actions_enabled(false)
	assert_true(screen.potion_button.disabled)
	assert_true(screen.consumable_selector.disabled)
	assert_eq(screen.consumable_hint.text, "Walka zakończona.")
	screen.potion_button.pressed.emit()
	assert_eq(session.player.inventory.count("weak_healing_potion"), 1)
	assert_eq(screen._round_number, 1)


func test_preview_is_read_only_and_matches_backpack_rounding() -> void:
	var session = _session()
	session.player.stats.max_hp = 30
	session.player.stats.max_mana = 1
	session.player.inventory.add("grandmaster_elixir", 2)
	var preview := ConsumableServiceClass.preview_use(session.player, "grandmaster_elixir")
	assert_eq(preview.healed_hp, 10)
	assert_eq(preview.restored_mana, 1)
	assert_eq(session.player.stats.current_hp, 1)
	assert_eq(session.player.stats.current_mana, 0)
	assert_eq(session.player.inventory.count("grandmaster_elixir"), 2)
	var result := ConsumableServiceClass.use(session.player, "grandmaster_elixir")
	assert_true(result.ok)
	assert_eq(result.healed_hp, preview.healed_hp)
	assert_eq(result.restored_mana, preview.restored_mana)
	assert_eq(session.player.inventory.count("grandmaster_elixir"), 1)


func _session():
	var session = NewGameServiceClass.new().create_session("TestMikstur", 1)
	session.player.stats.max_hp = 500
	session.player.stats.current_hp = 1
	session.player.stats.max_mana = 100
	session.player.stats.current_mana = 0
	session.player.stats.defense = 0
	session.player.stats.dodge = 0.0
	return session


func _screen(session) -> CombatScreenClass:
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	add_child_autofree(screen)
	screen.set_reduced_motion(true)
	return screen


func _select(screen: CombatScreenClass, item_id: String) -> void:
	for index in screen.consumable_selector.item_count:
		if str(screen.consumable_selector.get_item_metadata(index)) == item_id:
			screen.consumable_selector.select(index)
			screen.consumable_selector.item_selected.emit(index)
			return
	fail_test("Brak przedmiotu na liście: %s" % item_id)
