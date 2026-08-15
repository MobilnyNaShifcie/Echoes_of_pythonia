extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const SKILLS_SCENE := preload("res://ui/screens/skills/skills.tscn")
const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")


func test_hunter_catalog_preserves_six_techniques_and_named_combinations() -> void:
	var expected_combos := {
		"scarlet_execution": ["blood", "blood", "blood"],
		"brittle_burst": ["frost", "frost", "explosive"],
		"phantom_detonation": ["explosive", "phantom", "explosive"],
		"phantom_parade": ["phantom", "phantom", "phantom"],
		"armor_storm": ["rain", "piercing", "splitting"],
		"bloody_echo": ["blood", "phantom", "piercing"],
	}
	assert_eq(SkillCatalogClass.get_hunter_techniques().size(), 6)
	assert_eq(HunterComboCatalogClass.get_all().size(), 6)
	for combo_id: String in expected_combos:
		var combo = HunterComboCatalogClass.get_definition(combo_id)
		assert_not_null(combo)
		assert_eq(combo.sequence, expected_combos[combo_id])
		assert_false(combo.display_name.is_empty())
		assert_false(combo.description.is_empty())


func test_locked_talent_technique_spends_neither_mana_nor_turn() -> void:
	var player := _hunter(5)
	var combat := CombatEngineClass.new(player, _enemy(100, 5, 0))
	var mana_before: int = player.stats.current_mana

	var report := combat.player_use_skill("phantom_arrow")

	assert_string_contains(report.error, "drzewku talentów")
	assert_eq(player.stats.current_mana, mana_before)
	assert_eq(combat.enemy.attacks_made, 0)
	assert_true(combat.hunter_phantom_pending.is_empty())


func test_piercing_frost_and_splitting_arrows_preserve_damage_rules() -> void:
	var piercing := _combat_with_skills(["piercing_arrow"], 100, 0, 10)
	piercing.player.stats.attack = 10
	var piercing_report := piercing.player_use_skill("piercing_arrow")
	assert_eq(piercing_report.player_damage, 6)

	var frost := _combat_with_skills(["frost_arrow"], 100, 0, 0)
	var frost_report := frost.player_use_skill("frost_arrow")
	assert_eq(frost_report.player_damage_type, "frost")
	assert_eq(frost_report.player_damage, 6)

	var splitting := _combat_with_skills(["splitting_arrow"], 100, 0, 0)
	var splitting_report := splitting.player_use_skill("splitting_arrow")
	assert_eq(splitting_report.player_damage, 5)
	assert_eq(splitting_report.skill_total_damage, 9)
	assert_eq(_notes_containing(splitting_report, "Widmowy odłamek"), 2)


func test_explosive_arrow_detonates_and_resets_on_third_charge() -> void:
	var combat := _combat_with_skills(["explosive_arrow"], 200, 0, 0)
	var reports: Array[Dictionary] = []
	for _shot in 3:
		combat.player.stats.current_mana = combat.player.stats.max_mana
		reports.append(combat.player_use_skill("explosive_arrow"))

	assert_eq(combat.hunter_explosive_charges, 0)
	assert_string_contains("\n".join(reports[2].skill_notes), "DETONACJA 3/3")
	assert_eq(reports[2].skill_total_damage, 13)


func test_phantom_echo_and_rain_resolve_after_the_next_hunter_action() -> void:
	var phantom := _combat_with_skills(["phantom_arrow"], 200, 0, 0)
	var first := phantom.player_use_skill("phantom_arrow")
	assert_eq(phantom.hunter_phantom_pending.size(), 1)
	assert_eq(first.hunter_delayed_damage, 0)
	var echo_report := phantom.player_attack()
	assert_eq(echo_report.hunter_delayed_damage, 3)
	assert_string_contains("\n".join(echo_report.skill_notes), "WIDMOWE ECHO materializuje")
	assert_true(phantom.hunter_phantom_pending.is_empty())

	var rain := _combat_with_skills(["rain_of_arrows"], 200, 0, 0)
	var rain_cast := rain.player_use_skill("rain_of_arrows")
	assert_eq(rain_cast.player_damage, 0)
	assert_eq(rain.hunter_rain_pending.size(), 1)
	var rain_report := rain.player_attack()
	assert_eq(rain_report.hunter_delayed_damage, 3)
	assert_string_contains("\n".join(rain_report.skill_notes), "DESZCZ STRZAŁ spada")


func test_every_terminal_hunter_sequence_triggers_and_discovers_its_finisher() -> void:
	var sequences := {
		"scarlet_execution": ["bleeding_shot", "bleeding_shot", "bleeding_shot"],
		"brittle_burst": ["frost_arrow", "frost_arrow", "explosive_arrow"],
		"phantom_detonation": ["explosive_arrow", "phantom_arrow", "explosive_arrow"],
		"phantom_parade": ["phantom_arrow", "phantom_arrow", "phantom_arrow"],
		"armor_storm": ["rain_of_arrows", "piercing_arrow", "splitting_arrow"],
		"bloody_echo": ["bleeding_shot", "phantom_arrow", "piercing_arrow"],
	}
	for combo_id: String in sequences:
		var skill_ids: Array = sequences[combo_id]
		var unlocks: Array[String] = []
		for skill_id: String in skill_ids:
			if SkillCatalogClass.is_hunter_technique_id(skill_id) and skill_id not in unlocks:
				unlocks.append(skill_id)
		var combat := _combat_with_skills(unlocks, 2000, 0, 0)
		var report: Dictionary
		for skill_id: String in skill_ids:
			combat.player.stats.current_mana = combat.player.stats.max_mana
			report = combat.player_use_skill(skill_id)

		assert_eq(report.hunter_combo_id, combo_id)
		assert_gt(report.hunter_combo_damage, 0)
		assert_true(report.hunter_combo_discovered)
		assert_has(combat.player.discovered_hunter_combos, combo_id)
		assert_true(combat.hunter_sequence.is_empty())


func test_unknown_three_shot_sequence_clears_without_false_discovery() -> void:
	var combat := _combat_with_skills(["piercing_arrow", "frost_arrow"], 500, 0, 0)
	for skill_id: String in ["bleeding_shot", "piercing_arrow", "frost_arrow"]:
		combat.player.stats.current_mana = combat.player.stats.max_mana
		var report := combat.player_use_skill(skill_id)
		if skill_id == "frost_arrow":
			assert_string_contains("\n".join(report.skill_notes), "brak nazwanej kombinacji")
	assert_true(combat.hunter_sequence.is_empty())
	assert_true(combat.player.discovered_hunter_combos.is_empty())


func test_hunter_catalog_and_combat_panels_expose_placeholder_state() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("hunter"))
	session.player.level = 7
	session.player.unlocked_talent_skill_ids.append("phantom_arrow")
	session.player.stats.restore_full()

	var skills_screen := SKILLS_SCENE.instantiate() as SkillsScreenClass
	skills_screen.configure(session)
	add_child_autofree(skills_screen)
	assert_eq(skills_screen.skill_list.item_count, 10)
	assert_string_contains(skills_screen.summary_label.text, "Techniki Salwy: 6")

	var combat_screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	combat_screen.configure(session, "nature_guardian", "stage_three_d_preview")
	add_child_autofree(combat_screen)
	_select_skill(combat_screen, "phantom_arrow")
	combat_screen.skill_button.pressed.emit()

	assert_true(combat_screen.hunter_panel.visible)
	assert_string_contains(combat_screen.hunter_sequence_label.text, "Widmowa")
	assert_string_contains(combat_screen.hunter_resources_label.text, "ECHA 1")
	combat_screen.attack_button.pressed.emit()
	assert_string_contains(combat_screen.combat_log.get_parsed_text(), "WIDMOWE ECHO materializuje")


func test_hunter_mechanic_panel_fits_the_720p_combat_header() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("hunter"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "prologue_scarecrow", "prologue")
	host.add_child(screen)
	await get_tree().process_frame

	assert_true(screen.hunter_panel.visible)
	assert_lte(screen.hunter_panel.get_global_rect().end.x, screen.get_global_rect().end.x)
	assert_lte(
		screen.hunter_panel.get_global_rect().end.y,
		screen.get_node("Page/Arena").get_global_rect().position.y,
	)
	host.free()


func _combat_with_skills(
	unlocked_skills: Array[String], enemy_hp: int, enemy_attack: int, enemy_defense: int
) -> CombatEngineClass:
	var player := _hunter(12)
	player.unlocked_talent_skill_ids.assign(unlocked_skills)
	return CombatEngineClass.new(player, _enemy(enemy_hp, enemy_attack, enemy_defense))


func _hunter(level: int) -> PlayerProfileClass:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = 5
	assert_true(player.choose_class("hunter"))
	player.level = level
	player.attributes.intelligence = 20
	player.recalculate_stats()
	player.stats.restore_full()
	return player


func _enemy(hp: int, attack: int, defense: int) -> CombatEnemyClass:
	return (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "hunter_target",
				"display_name": "Cel Łowcy",
				"max_hp": hp,
				"attack": attack,
				"defense": defense,
				"dodge": 0.0,
			}
		)
	)


func _notes_containing(report: Dictionary, fragment: String) -> int:
	var count := 0
	for note: String in report.skill_notes:
		if fragment in note:
			count += 1
	return count


func _select_skill(screen: CombatScreenClass, skill_id: String) -> void:
	for index in screen.skill_selector.item_count:
		if str(screen.skill_selector.get_item_metadata(index)) == skill_id:
			screen.skill_selector.select(index)
			screen.skill_selector.item_selected.emit(index)
			return
	fail_test("Nie znaleziono techniki w panelu walki: %s" % skill_id)
