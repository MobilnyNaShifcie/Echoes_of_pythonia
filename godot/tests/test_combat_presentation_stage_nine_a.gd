extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatActionCardClass := preload(
	"res://ui/components/combat_action_card/combat_action_card.gd"
)
const CombatDieClass := preload("res://ui/components/combat_die/combat_die.gd")
const CombatPresentationPlanClass := preload("res://ui/presentation/combat_presentation_plan.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_report_is_mapped_to_presentation_events_without_domain_mutation() -> void:
	var report := {
		"fate_dice": [2, 3, 4],
		"fate_outcome": "Próba losu",
		"skill_total_damage": 9,
		"player_critical": true,
		"player_healed": 4,
		"player_mana_restored": 2,
		"enemy_acted": true,
		"player_dodged": true,
		"warrior_counter_damage": 5,
		"boss_aura_damage": 2,
		"reflected_damage": 2,
		"enemy_bleed_damage": 1,
		"player_regenerated": 3,
	}
	var frozen_report := report.duplicate(true)

	var events := CombatPresentationPlanClass.from_report(report)

	assert_eq(report, frozen_report)
	assert_eq(
		_event_kinds(events),
		[
			"fate_roll",
			"damage",
			"restore",
			"turn",
			"feedback",
			"damage",
			"damage",
			"damage",
			"damage",
			"restore",
			"turn",
		]
	)
	assert_eq(events[0].dice, [2, 3, 4])
	assert_eq(events[1].amount, 9)
	assert_true(events[1].critical)
	assert_eq(events[4].text, "UNIK")
	assert_eq(events[5].prefix, "KONTRA")
	assert_eq(events[6].prefix, "AURA")
	assert_eq(events[7].prefix, "ODBICIE")
	assert_eq(events[8].prefix, "KRWAWIENIE")


func test_reduced_motion_renders_real_pierrot_result_and_unlocks_input() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("pierrot"))
	session.player.stats.restore_full()
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	add_child_autofree(screen)
	screen.set_reduced_motion(true)
	_rig_dice(screen, [3])
	_select_skill(screen, "fate_thrust")

	screen.skill_button.pressed.emit()

	assert_false(screen._presentation_controller.is_busy())
	assert_eq(screen.dice_row.get_child_count(), 1)
	assert_true(screen.dice_row.get_child(0) is CombatDieClass)
	assert_eq(screen.dice_row.get_child(0).value, 3)
	assert_false(screen.fate_outcome_label.text.is_empty())
	assert_false(screen._presentation_controller.last_feedback_texts.is_empty())
	assert_false(screen.attack_button.disabled)


func test_full_presentation_locks_actions_until_playback_finishes() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition")
	add_child_autofree(screen)
	screen.set_reduced_motion(false)
	screen._presentation_controller.animation_duration_scale = 0.01

	screen.attack_button.pressed.emit()

	assert_true(screen._presentation_controller.is_busy())
	assert_true(screen.attack_button.disabled)
	assert_true(screen.motion_toggle_button.disabled)
	await screen._presentation_controller.playback_finished
	await get_tree().process_frame
	assert_false(screen._presentation_controller.is_busy())
	assert_false(screen.attack_button.disabled)
	assert_false(screen.motion_toggle_button.disabled)
	assert_string_contains(screen.turn_state_label.text, "WYBIERZ AKCJĘ")


func test_motion_preference_and_card_states_are_explicit() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition")
	add_child_autofree(screen)

	assert_true(screen._presentation_controller.reduced_motion)
	assert_string_contains(screen.motion_toggle_button.text, "ograniczone")
	screen.motion_toggle_button.pressed.emit()
	assert_false(screen._presentation_controller.reduced_motion)
	assert_string_contains(screen.motion_toggle_button.text, "pełne")
	screen.set_reduced_motion(true)
	var card := screen.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(card.visual_state(), "GOTOWA")
	assert_string_contains(card.text, "[GOTOWA]")
	session.player.stats.current_mana = 0
	screen._render()
	card = screen.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(card.visual_state(), "BLOKADA")
	assert_true(card.disabled)


func test_resource_bars_and_result_panel_keep_a_stable_full_hd_contract() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("mage"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wild_dog", "expedition")
	host.add_child(screen)
	await get_tree().process_frame

	assert_eq(screen.player_hp_bar.max_value, float(session.player.stats.max_hp))
	assert_eq(screen.player_mana_bar.max_value, float(session.player.stats.max_mana))
	assert_eq(screen.player_mana_bar.value, float(session.player.stats.current_mana))
	var continue_size := screen.continue_button.size
	screen._enemy.current_hp = 1
	screen.set_reduced_motion(true)
	screen.attack_button.pressed.emit()
	await get_tree().process_frame
	assert_true(screen.result_panel.visible)
	assert_eq(screen.result_title_label.text, "ZWYCIĘSTWO")
	assert_eq(screen.continue_button.size, continue_size)
	assert_eq(screen.continue_button.custom_minimum_size, Vector2(180, 56))
	host.free()


func _event_kinds(events: Array[Dictionary]) -> Array[String]:
	var result: Array[String] = []
	for event: Dictionary in events:
		result.append(str(event.get("kind", "")))
	return result


func _rig_dice(screen: CombatScreenClass, values: Array[int]) -> void:
	var remaining := values.duplicate()
	var roller := func() -> int: return remaining.pop_front()
	screen._engine.fate = FateEngineClass.new(screen._engine.rng, roller)


func _select_skill(screen: CombatScreenClass, skill_id: String) -> void:
	for index in screen.skill_selector.item_count:
		if str(screen.skill_selector.get_item_metadata(index)) == skill_id:
			screen.skill_selector.select(index)
			screen.skill_selector.item_selected.emit(index)
			return
	fail_test("Nie znaleziono umiejętności: %s" % skill_id)
