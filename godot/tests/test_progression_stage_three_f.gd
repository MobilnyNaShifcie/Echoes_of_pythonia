extends GutTest

const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const FateEngineClass := preload("res://core/combat/fate_engine.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const PlayerProfileClass := preload("res://core/player/player_profile.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)


func test_catalog_preserves_eight_paths_and_all_terminal_talents() -> void:
	assert_eq(TalentCatalogClass.get_paths_for_class("warrior").size(), 2)
	assert_eq(TalentCatalogClass.get_paths_for_class("hunter").size(), 2)
	assert_eq(TalentCatalogClass.get_paths_for_class("mage").size(), 2)
	assert_eq(TalentCatalogClass.get_paths_for_class("pierrot").size(), 2)
	var total := 0
	for class_code in ["warrior", "hunter", "mage", "pierrot"]:
		total += TalentCatalogClass.get_talents_for_class(class_code).size()
	assert_eq(total, 41)
	assert_eq(TalentCatalogClass.get_talent("heavy_shield_bash").active_skill_id, "shield_bash")
	assert_eq(TalentCatalogClass.get_talent("pierrot_va_banque").active_skill_id, "va_banque")


func test_tree_points_and_base_path_match_terminal_progression() -> void:
	var warrior := _class_player("warrior", 18)
	assert_eq(TalentProgressionServiceClass.total_points_for_level(18, true), 8)
	assert_eq(TalentProgressionServiceClass.available_points(warrior), 8)

	var result := TalentProgressionServiceClass.learn(warrior, "warrior_battle_fury")
	assert_true(result.ok)
	assert_eq(result.rank, 1)
	assert_eq(TalentProgressionServiceClass.available_points(warrior), 7)


func test_locked_path_and_prerequisites_reject_without_spending() -> void:
	var warrior := _class_player("warrior", 18)
	var locked := TalentProgressionServiceClass.learn(warrior, "heavy_knight_core")
	assert_false(locked.ok)
	assert_string_contains(locked.message, "Księgi Ścieżki")

	var prerequisite := TalentProgressionServiceClass.learn(warrior, "warrior_deep_wounds")
	assert_false(prerequisite.ok)
	assert_string_contains(prerequisite.message, "Furia Bitewna")
	assert_eq(TalentProgressionServiceClass.spent_points(warrior), 0)


func test_learned_talent_unlocks_real_active_skill_and_reset_disables_it() -> void:
	var warrior := _class_player("warrior", 18)
	warrior.unlocked_class_path_ids.append("warrior_heavy_knight")
	assert_true(TalentProgressionServiceClass.learn(warrior, "heavy_knight_core").ok)
	assert_true(TalentProgressionServiceClass.learn(warrior, "heavy_shield_bash").ok)
	assert_true(
		SkillCatalogClass.is_unlocked(warrior, SkillCatalogClass.get_definition("shield_bash"))
	)

	warrior.gold = 1500
	var reset := TalentProgressionServiceClass.reset(warrior)
	assert_true(reset.ok)
	assert_eq(reset.cost, 1500)
	assert_true(warrior.talent_ranks.is_empty())
	assert_true("warrior_heavy_knight" in warrior.unlocked_class_path_ids)
	assert_false(
		SkillCatalogClass.is_unlocked(warrior, SkillCatalogClass.get_definition("shield_bash"))
	)


func test_passive_points_caps_and_attack_bonus_match_terminal() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = 6
	assert_eq(PassiveProgressionServiceClass.available_points(player), 3)
	var result := PassiveProgressionServiceClass.spend(player, "increased_attack", 3)
	assert_true(result.ok)
	assert_eq(player.passive_ranks.increased_attack, 3)
	assert_eq(player.stats.attack, 9)
	assert_eq(PassiveProgressionServiceClass.available_points(player), 0)

	player.level = 30
	player.passive_ranks.increased_attack = 5
	var capped := PassiveProgressionServiceClass.spend(player, "increased_attack")
	assert_false(capped.ok)
	assert_string_contains(capped.message, "limit")


func test_mastery_rank_ten_and_specialization_are_permanent_choices() -> void:
	var warrior := _class_player("warrior", 20)
	warrior.unlocked_passive_mastery_ids.append("increased_attack")
	assert_true(PassiveProgressionServiceClass.spend(warrior, "increased_attack", 10).ok)
	assert_eq(PassiveProgressionServiceClass.attack_bonus(warrior), 25)
	var chosen := PassiveProgressionServiceClass.choose_specialization(
		warrior, "increased_attack", "raw_strength"
	)
	assert_true(chosen.ok)
	assert_eq(PassiveProgressionServiceClass.attack_bonus(warrior), 30)
	assert_eq(warrior.stats.attack, 33)
	assert_false(
		(
			PassiveProgressionServiceClass
			. choose_specialization(warrior, "increased_attack", "momentum")
			. ok
		)
	)


func test_purchased_warrior_ranks_increase_real_skill_damage() -> void:
	var base_warrior := _class_player("warrior", 18)
	var base_combat := CombatEngineClass.new(base_warrior, _enemy(200, 0, 0))
	var base_damage: int = base_combat.player_use_skill("power_slash").player_damage

	var talented_warrior := _class_player("warrior", 18)
	assert_true(TalentProgressionServiceClass.learn(talented_warrior, "warrior_battle_fury").ok)
	assert_true(TalentProgressionServiceClass.learn(talented_warrior, "warrior_battle_fury").ok)
	assert_true(TalentProgressionServiceClass.learn(talented_warrior, "warrior_battle_fury").ok)
	var talented_combat := CombatEngineClass.new(talented_warrior, _enemy(200, 0, 0))
	var talented_damage: int = talented_combat.player_use_skill("power_slash").player_damage

	assert_gt(talented_damage, base_damage)


func test_fortuna_loaded_die_changes_the_first_one_in_real_combat() -> void:
	var pierrot := _class_player("pierrot", 8)
	pierrot.unlocked_class_path_ids.append("pierrot_fortuna")
	assert_true(TalentProgressionServiceClass.learn(pierrot, "fortuna_core").ok)
	assert_true(TalentProgressionServiceClass.learn(pierrot, "fortuna_loaded_die").ok)
	var combat := CombatEngineClass.new(pierrot, _enemy(200, 0, 0))
	var values: Array[int] = [1, 6]
	combat.fate = FateEngineClass.new(combat.rng, func() -> int: return values.pop_front())

	var report := combat.player_use_skill("fate_thrust")

	assert_eq(report.fate_dice, [6])
	assert_string_contains(" ".join(report.class_effect_notes), "Dociążona Kość")


func test_second_wind_and_rank_ten_regeneration_resolve_after_enemy_turn() -> void:
	var warrior := _class_player("warrior", 20)
	warrior.unlocked_passive_mastery_ids.append("health_regen")
	assert_true(PassiveProgressionServiceClass.spend(warrior, "health_regen", 10).ok)
	assert_true(
		(
			PassiveProgressionServiceClass
			. choose_specialization(warrior, "health_regen", "second_wind")
			. ok
		)
	)
	warrior.stats.current_hp = 5
	var combat := CombatEngineClass.new(warrior, _enemy(200, 3, 0))

	var report := combat.player_attack()

	assert_true(combat.second_wind_used)
	assert_eq(report.player_healed, 5)
	assert_gt(report.player_regenerated, 0)
	assert_string_contains(" ".join(report.class_effect_notes), "DRUGI ODDECH")


func _class_player(class_code: String, level: int) -> PlayerProfileClass:
	var player = PlayerFactoryClass.create_player("Tester")
	player.level = level
	assert_true(player.choose_class(class_code))
	return player


func _enemy(hp: int, attack: int, defense: int) -> CombatEnemyClass:
	return (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "progression_target",
				"display_name": "Cel progresji",
				"max_hp": hp,
				"attack": attack,
				"defense": defense,
				"dodge": 0.0,
			}
		)
	)
