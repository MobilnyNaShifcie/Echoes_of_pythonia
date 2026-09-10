extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")


func test_elemental_resistances_clamp_and_preserve_python_damage_floor() -> void:
	var resistances := ElementalResistancesClass.new({"fire": 30, "wind": 200, "frost": -10})

	assert_eq(resistances.get_value("fire"), 30)
	assert_eq(resistances.get_value("wind"), 75)
	assert_eq(resistances.get_value("frost"), 0)
	assert_eq(resistances.reduce_damage(10, "fire"), 7)
	assert_eq(resistances.reduce_damage(1, "wind"), 1)
	assert_eq(resistances.reduce_damage(10, "physical"), 10)
	assert_false(resistances.set_value("void", 50))


func test_mage_spells_and_enemy_attacks_apply_elemental_resistances() -> void:
	var mage := _class_player("mage", 5)
	var resistant_enemy := _enemy(
		200,
		0,
		0,
		{"elemental_resistances": {"fire": 25}},
	)
	var spell_report := CombatEngineClass.new(mage, resistant_enemy).player_use_skill("fire_bolt")
	assert_eq(spell_report.player_damage_type, "fire")
	assert_eq(spell_report.player_damage, 12)

	var defender := _class_player("mage", 5)
	defender.stats.defense = 0
	defender.stats.elemental_resistances.set_value("fire", 50)
	var fire_enemy := _enemy(100, 20, 0, {"basic_damage_type": "fire"})
	var attack_report := CombatEngineClass.new(defender, fire_enemy).player_attack()
	assert_eq(attack_report.enemy_damage_type, "fire")
	assert_eq(attack_report.enemy_damage, 10)


func test_elemental_cycle_boosts_exactly_the_third_different_spell() -> void:
	var mage := _class_player("mage", 12)
	mage.unlocked_class_mechanic_ids.append("mage_elemental_cycle")
	var combat := CombatEngineClass.new(mage, _enemy(500, 0, 0))

	combat.player_use_skill("fire_bolt")
	combat.player_use_skill("frost_lance")
	var third := combat.player_use_skill("lightning")

	assert_eq(third.player_damage, 24)
	assert_string_contains("\n".join(third.class_effect_notes), "CYKL ŻYWIOŁÓW")
	assert_true(combat.mage_element_sequence.is_empty())


func test_arcane_weave_builds_to_three_and_rejects_early_pair_without_cost() -> void:
	var mage := _class_player("mage", 12)
	mage.unlocked_class_mechanic_ids.assign(["arcana_core", "arcana_double_weave"])
	var combat := CombatEngineClass.new(mage, _enemy(1000, 0, 0))
	var mana_before: int = mage.stats.current_mana

	var early := combat.player_use_skill_pair("fire_bolt", "frost_lance")
	assert_string_contains(early.error, "nie jest jeszcze gotowy")
	assert_eq(mage.stats.current_mana, mana_before)
	assert_eq(combat.enemy.attacks_made, 0)

	for _cast in 3:
		combat.player_use_skill("fire_bolt")
	assert_eq(combat.mage_arcane_weave, 3)
	assert_true(combat.can_double_cast())


func test_double_weave_casts_two_spells_for_one_enemy_turn_and_resets_charge() -> void:
	var mage := _class_player("mage", 12)
	mage.unlocked_class_mechanic_ids.assign(["arcana_core", "arcana_double_weave"])
	var enemy := _enemy(1000, 0, 0)
	var combat := CombatEngineClass.new(mage, enemy)
	combat.mage_arcane_weave = 3
	var attacks_before: int = enemy.attacks_made
	var mana_before: int = mage.stats.current_mana

	var report := combat.player_use_skill_pair("frost_lance", "lightning")

	assert_eq(report.skill_mana_cost, 16)
	assert_eq(mage.stats.current_mana, mana_before - 16)
	assert_eq(report.skill_total_damage, 31)
	assert_eq(enemy.attacks_made, attacks_before + 1)
	assert_eq(combat.mage_arcane_weave, 0)
	assert_string_contains("\n".join(report.class_effect_notes), "PODWÓJNY SPLOT")
	assert_string_contains("\n".join(report.class_effect_notes), "80%")


func test_advanced_weave_cost_power_and_mana_cycle_match_terminal_rules() -> void:
	var mage := _class_player("mage", 12)
	(
		mage
		. unlocked_class_mechanic_ids
		. assign(
			[
				"arcana_core",
				"arcana_double_weave",
				"arcana_efficiency",
				"arcana_perfect_weave",
				"arcana_mana_cycle",
			]
		)
	)
	mage.stats.max_mana = 100
	mage.stats.current_mana = 100
	var combat := CombatEngineClass.new(mage, _enemy(1000, 0, 0))
	combat.mage_arcane_weave = 3

	var report := combat.player_use_skill_pair("fire_bolt", "frost_lance")

	assert_eq(report.skill_mana_cost, 11)
	assert_eq(report.skill_total_damage, 30)
	assert_eq(mage.stats.current_mana, 93)
	assert_eq(report.player_mana_restored, 4)
	assert_string_contains("\n".join(report.class_effect_notes), "95%")
	assert_string_contains("\n".join(report.class_effect_notes), "OBIEG MANY")


func test_shield_bash_uses_attack_and_sixty_percent_defense() -> void:
	var warrior := _class_player("warrior", 5)
	warrior.unlocked_talent_skill_ids.append("shield_bash")
	var combat := CombatEngineClass.new(warrior, _enemy(100, 0, 0))

	var report := combat.player_use_skill("shield_bash")

	assert_eq(report.player_damage, 5)
	assert_eq(report.skill_name, "Uderzenie Tarczą")
	warrior.unequip_to_inventory(PlayerEquipmentClass.OFF_HAND)
	var missing_shield := CombatEngineClass.new(warrior, _enemy(100, 0, 0))
	var invalid := missing_shield.player_use_skill("shield_bash")
	assert_string_contains(invalid.error, "Tarczy")
	assert_false(invalid.turn_consumed)


func test_provoke_forces_one_basic_attack_and_can_trigger_shield_counter() -> void:
	var warrior := _class_player("warrior", 5)
	warrior.unlocked_talent_skill_ids.append("provoke")
	warrior.unlocked_class_mechanic_ids.append("heavy_counter")
	var enemy := _enemy(
		100,
		12,
		0,
		{
			"special_name": "Niebezpieczny Specjalny Atak",
			"special_chance": 1.0,
			"special_attack_bonus": 50,
			"extra_attack_chance": 1.0,
		},
	)
	var combat := CombatEngineClass.new(warrior, enemy, _rng_with_second_roll_below(0.25))

	var report := combat.player_use_skill("provoke")

	assert_true(report.shield_blocked)
	assert_eq(report.enemy_damage, 0)
	assert_eq(report.enemy_extra_damage, 0)
	assert_true(str(report.enemy_special_name).is_empty())
	assert_eq(enemy.attacks_made, 1)
	assert_eq(report.warrior_counter_damage, 3)
	assert_string_contains("\n".join(report.class_effect_notes), "ŻELAZNA KONTRA")


func test_heavy_defense_prepares_seventy_five_percent_defense_retribution() -> void:
	var warrior := _class_player("warrior", 5)
	warrior.unlocked_class_mechanic_ids.assign(["heavy_knight_core", "heavy_bastion"])
	var combat := CombatEngineClass.new(warrior, _enemy(100, 0, 0))

	var defend := combat.player_defend()
	assert_true(combat.warrior_retribution_ready)
	assert_string_contains("\n".join(defend.class_effect_notes), "75% DEF")
	var attack := combat.player_attack()
	assert_eq(attack.player_damage, 6)
	assert_false(combat.warrior_retribution_ready)
	assert_string_contains("\n".join(attack.class_effect_notes), "ODWET")


func test_warrior_and_mage_placeholder_panels_expose_live_combat_state() -> void:
	var warrior_session = NewGameServiceClass.new().create_session("Aria", 1)
	warrior_session.player.level = 5
	assert_true(warrior_session.player.choose_class("warrior"))
	warrior_session.player.unlocked_talent_skill_ids.assign(["shield_bash", "provoke"])
	var warrior_screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	warrior_screen.configure(warrior_session, "nature_guardian", "stage_three_e_preview")
	add_child_autofree(warrior_screen)
	assert_string_contains(warrior_screen.class_resource_label.text, "BLOK 5%")
	assert_eq(warrior_screen.skill_selector.item_count, 3)

	var mage_session = NewGameServiceClass.new().create_session("Lyra", 1)
	mage_session.player.level = 5
	assert_true(mage_session.player.choose_class("mage"))
	mage_session.player.level = 12
	mage_session.player.unlocked_class_mechanic_ids.assign(["arcana_core", "arcana_double_weave"])
	mage_session.player.stats.restore_full()
	var mage_screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	mage_screen.configure(mage_session, "nature_guardian", "stage_three_e_preview")
	add_child_autofree(mage_screen)
	mage_screen._enemy.max_hp = 1000
	mage_screen._enemy.current_hp = 1000
	mage_screen._enemy.attack = 0
	_select_skill(mage_screen, "fire_bolt")
	for _cast in 3:
		mage_screen.skill_button.pressed.emit()
	assert_false(mage_screen.weave_row.visible)
	mage_screen.weave_toggle_button.button_pressed = true
	assert_true(mage_screen.weave_row.visible)
	assert_string_contains(mage_screen.class_resource_label.text, "3/3")
	assert_false(mage_screen.double_weave_button.disabled)


func test_warrior_and_mage_panels_fit_the_720p_combat_header() -> void:
	for class_code: String in ["warrior", "mage"]:
		var host := Control.new()
		host.size = Vector2(1280, 720)
		add_child(host)
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		session.player.level = 5
		assert_true(session.player.choose_class(class_code))
		var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
		screen.configure(session, "prologue_scarecrow", "prologue")
		host.add_child(screen)
		await get_tree().process_frame
		var class_hud: PanelContainer = screen.get_node("Page/Lower/PlayerCommandHud")
		screen.get_node("Page/Lower").drawer.pinned = true
		screen.get_node("Page/Lower").drawer.set_open(true, true)
		await get_tree().process_frame
		await get_tree().process_frame
		assert_lte(class_hud.get_global_rect().end.x, screen.get_global_rect().end.x)
		assert_lte(
			class_hud.get_global_rect().end.y,
			screen.get_global_rect().end.y,
		)
		host.free()


func _class_player(class_code: String, level: int) -> PlayerProfileClass:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = 5
	assert_true(player.choose_class(class_code))
	player.level = level
	player.stats.restore_full()
	return player


func _enemy(hp: int, attack: int, defense: int, extra: Dictionary = {}) -> CombatEnemyClass:
	var data := {
		"enemy_id": "stage_three_e_target",
		"display_name": "Cel etapu 3E",
		"max_hp": hp,
		"attack": attack,
		"defense": defense,
		"dodge": 0.0,
	}
	data.merge(extra, true)
	return CombatEnemyClass.new(data)


func _rng_with_second_roll_below(threshold: float) -> RandomNumberGenerator:
	for seed_value in range(1, 1000):
		var probe := RandomNumberGenerator.new()
		probe.seed = seed_value
		probe.randf()
		if probe.randf() < threshold:
			var result := RandomNumberGenerator.new()
			result.seed = seed_value
			return result
	return RandomNumberGenerator.new()


func _select_skill(screen: CombatScreenClass, skill_id: String) -> void:
	for index in screen.skill_selector.item_count:
		if str(screen.skill_selector.get_item_metadata(index)) == skill_id:
			screen.skill_selector.select(index)
			screen.skill_selector.item_selected.emit(index)
			return
	fail_test("Nie znaleziono umiejętności w panelu walki: %s" % skill_id)
