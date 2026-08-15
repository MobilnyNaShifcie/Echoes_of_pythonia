extends GutTest

const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const PlayerEquipmentClass := preload("res://core/player/equipment.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")


func test_catalog_preserves_four_terminal_base_skills_for_every_class() -> void:
	for class_code: String in ["warrior", "hunter", "mage", "pierrot"]:
		var skills := SkillCatalogClass.get_skills_for_class(class_code)
		assert_eq(skills.size(), 4, "Klasa %s powinna mieć cztery bazowe skille." % class_code)
		assert_eq(skills[0].unlock_level, 5)
		assert_eq(skills[1].unlock_level, 7)
		assert_eq(skills[2].unlock_level, 9)
		assert_eq(skills[3].unlock_level, 12)
		for skill in skills:
			assert_false(skill.skill_id.is_empty())
			assert_false(skill.display_name.is_empty())
			assert_gt(skill.mana_cost, 0)
			assert_false(skill.description.is_empty())


func test_all_sixteen_base_skills_are_combat_ready_after_stage_three_c() -> void:
	var ready_count := 0
	for class_code: String in ["warrior", "hunter", "mage", "pierrot"]:
		for skill in SkillCatalogClass.get_skills_for_class(class_code):
			assert_true(skill.is_combat_ready())
			ready_count += 1
	assert_eq(ready_count, 16)


func test_power_slash_spends_mana_and_gives_enemy_one_turn() -> void:
	var player = _create_class_player("warrior", 5)
	var enemy := _enemy(40, 2, 1)
	var combat := CombatEngineClass.new(player, enemy)
	var mana_before: int = player.stats.current_mana

	var report := combat.player_use_skill("power_slash")

	assert_eq(player.stats.current_mana, mana_before - 6)
	assert_gt(report.skill_total_damage, 0)
	assert_eq(report.skill_name, "Potężne Cięcie")
	assert_true(report.enemy_acted)
	assert_eq(enemy.attacks_made, 1)


func test_invalid_skill_does_not_spend_mana_or_consume_turn() -> void:
	var player = _create_class_player("warrior", 5)
	player.stats.current_mana = 0
	var enemy := _enemy(40, 3, 1)
	var combat := CombatEngineClass.new(player, enemy)
	var hp_before: int = player.stats.current_hp

	var report := combat.player_use_skill("power_slash")

	assert_string_contains(report.error, "Brak Many")
	assert_false(report.turn_consumed)
	assert_eq(player.stats.current_mana, 0)
	assert_eq(player.stats.current_hp, hp_before)
	assert_eq(enemy.attacks_made, 0)


func test_weapon_requirement_is_validated_without_consuming_turn() -> void:
	var player = _create_class_player("hunter", 5)
	player.unequip_to_inventory(PlayerEquipmentClass.WEAPON)
	var enemy := _enemy(40, 3, 1)
	var combat := CombatEngineClass.new(player, enemy)
	var mana_before: int = player.stats.current_mana

	var report := combat.player_use_skill("precise_shot")

	assert_string_contains(report.error, "Łuku")
	assert_eq(player.stats.current_mana, mana_before)
	assert_eq(enemy.attacks_made, 0)


func test_armor_break_improves_next_basic_attack_and_tracks_duration() -> void:
	var player = _create_class_player("warrior", 7)
	player.attributes.strength = 3
	player.recalculate_stats()
	player.stats.restore_full()
	var enemy := _enemy(100, 0, 5)
	var combat := CombatEngineClass.new(player, enemy)

	combat.player_use_skill("armor_break")
	var report := combat.player_attack()

	assert_eq(report.player_damage, 3)
	assert_eq(combat.effects.enemy_defense_reduction, 2)
	assert_eq(combat.effects.enemy_defense_reduction_actions, 2)


func test_bleed_ticks_after_enemy_turn_and_keeps_two_turns() -> void:
	var player = _create_class_player("warrior", 12)
	var enemy := _enemy(100, 0, 0)
	var combat := CombatEngineClass.new(player, enemy)

	var report := combat.player_use_skill("blood_strike")

	assert_eq(report.enemy_bleed_damage, 3)
	assert_eq(combat.effects.enemy_bleed_damage, 3)
	assert_eq(combat.effects.enemy_bleed_turns, 2)


func test_guard_reduces_the_next_enemy_hit() -> void:
	var player = _create_class_player("warrior", 9)
	var enemy := _enemy(100, 10, 0)
	var combat := CombatEngineClass.new(player, enemy)

	var report := combat.player_use_skill("defensive_stance")

	assert_eq(report.enemy_damage, 3)
	assert_eq(combat.effects.player_guard_hits, 1)


func test_precise_and_double_shot_support_guaranteed_and_multiple_hits() -> void:
	var precise_player = _create_class_player("hunter", 5)
	var evasive_enemy := _enemy(100, 0, 0, 100.0)
	var precise_combat := CombatEngineClass.new(precise_player, evasive_enemy)
	var precise_report := precise_combat.player_use_skill("precise_shot")
	assert_false(precise_report.enemy_dodged)
	assert_gt(precise_report.player_damage, 0)

	var double_player = _create_class_player("hunter", 12)
	var steady_enemy := _enemy(100, 0, 0)
	var double_combat := CombatEngineClass.new(double_player, steady_enemy)
	var double_report := double_combat.player_use_skill("double_shot")
	assert_eq(double_report.player_hit_damages.size(), 2)
	assert_eq(
		double_report.skill_total_damage,
		double_report.player_hit_damages[0] + double_report.player_hit_damages[1],
	)


func test_magic_damage_scales_with_intelligence() -> void:
	var base_player = _create_class_player("mage", 5)
	var base_combat := CombatEngineClass.new(base_player, _enemy(100, 0, 0))
	var base_damage: int = base_combat.player_use_skill("fire_bolt").player_damage
	var intelligent_player = _create_class_player("mage", 5)
	intelligent_player.attributes.intelligence = 3
	intelligent_player.recalculate_stats()
	intelligent_player.stats.restore_full()
	var intelligent_combat := CombatEngineClass.new(intelligent_player, _enemy(100, 0, 0))
	var intelligent_damage: int = intelligent_combat.player_use_skill("fire_bolt").player_damage

	assert_gt(intelligent_damage, base_damage)


func test_pierrot_skill_executes_with_real_dice_resolution() -> void:
	var player = _create_class_player("pierrot", 5)
	var enemy := _enemy(40, 0, 0)
	var combat := CombatEngineClass.new(player, enemy)
	var mana_before: int = player.stats.current_mana

	var report := combat.player_use_skill("fate_thrust")

	assert_eq(report.error, "")
	assert_eq(report.fate_dice.size(), 1)
	assert_eq(player.stats.current_mana, mana_before - 5)
	assert_eq(enemy.attacks_made, 1)


func test_dodge_applies_to_every_hit_of_an_enemy_multiattack() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	player.stats.dodge = 100.0
	var enemy := (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "fast_enemy",
				"display_name": "Szybki cel",
				"max_hp": 100,
				"attack": 10,
				"defense": 0,
				"dodge": 0.0,
				"extra_attack_chance": 1.0,
			}
		)
	)
	var combat := CombatEngineClass.new(player, enemy)
	var hp_before: int = player.stats.current_hp

	var report := combat.player_attack()

	assert_true(report.player_dodged)
	assert_eq(report.enemy_damage, 0)
	assert_eq(report.enemy_extra_damage, 0)
	assert_eq(player.stats.current_hp, hp_before)


func _create_class_player(class_code: String, level: int) -> PlayerProfileClass:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = 5
	assert_true(player.choose_class(class_code))
	player.level = level
	player.stats.restore_full()
	return player


func _enemy(hp: int, attack: int, defense: int, dodge := 0.0) -> CombatEnemyClass:
	return (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "test_enemy",
				"display_name": "Cel testowy",
				"max_hp": hp,
				"attack": attack,
				"defense": defense,
				"dodge": dodge,
			}
		)
	)
