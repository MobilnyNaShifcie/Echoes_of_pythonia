extends GutTest

const CombatDamageRulesClass := preload("res://core/combat/combat_damage_rules.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const EquipmentClassEffectCatalogClass := preload(
	"res://core/items/equipment_class_effect_catalog.gd"
)
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_shared_damage_rules_preserve_legacy_rounding_and_minimums() -> void:
	assert_eq(CombatDamageRulesClass.calculate_damage(7, 2), 5)
	assert_eq(CombatDamageRulesClass.calculate_damage(0, 99), 1)
	assert_eq(CombatDamageRulesClass.apply_armor_penetration(9, 50.0), 4)
	assert_eq(CombatDamageRulesClass.apply_armor_penetration(9, 200.0), 1)
	assert_eq(CombatDamageRulesClass.apply_defend_reduction(5), 2)
	assert_eq(CombatDamageRulesClass.apply_multiplier(5, 0.5), 2)


func test_ordinary_one_on_one_combat_keeps_its_stage_two_contract() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	var enemy = EnemyCatalogClass.create_enemy("prologue_scarecrow")
	var combat := CombatEngineClass.new(player, enemy, _rng(7))

	var report: Dictionary = combat.player_attack()

	assert_eq(report.player_damage, 3)
	assert_eq(enemy.current_hp, 4)
	assert_eq(player.stats.current_hp, 19)


func test_party_damage_reports_terminal_overkill_without_negative_enemy_hp() -> void:
	var combat := PartyCombatEngineClass.new(
		_player("Niszczyciel", "warrior", 12), [], _enemy(1, 0, 0), _rng(71)
	)

	var hit: Dictionary = combat._deal_to_enemy(combat.player_fighter, 50.0, 0.0, true)

	assert_eq(hit.damage, 50)
	assert_eq(combat.enemy.current_hp, 0)


func test_party_round_runs_player_then_companions_then_enemy() -> void:
	var player = _player("Dowódca", "warrior", 12)
	var first := _companion("first", "warrior", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	var second := _companion("second", "mage", 12, CompanionStateClass.TACTIC_BALANCED)
	var combat := PartyCombatEngineClass.new(player, [first, second], _enemy(200, 4, 2), _rng(107))

	var report = combat.player_basic_attack()

	assert_true(report.turn_consumed)
	assert_eq(report.companion_action_order, ["first", "second"])
	assert_eq(report.companion_skill_ids["first"], "blood_strike")
	assert_eq(report.companion_skill_ids["second"], "mana_burst")
	assert_eq(report.enemy_target_ids.size(), 1)
	assert_lt(report.enemy_hp_after, report.enemy_hp_before)
	assert_eq(combat.round_number, 2)


func test_all_four_tactics_reach_the_party_engine_ai() -> void:
	var cases := [
		[CompanionStateClass.TACTIC_AGGRESSIVE, 20, 20, "blood_strike"],
		[CompanionStateClass.TACTIC_BALANCED, 20, 20, "blood_strike"],
		[CompanionStateClass.TACTIC_CAUTIOUS, 9, 20, "defensive_stance"],
		[CompanionStateClass.TACTIC_DEFENSIVE, 15, 20, "defensive_stance"],
	]
	for index in cases.size():
		var values: Array = cases[index]
		var companion := _companion("tactic-%d" % index, "warrior", 12, values[0])
		companion.current_hp = values[1]
		companion.current_mana = values[2]
		var combat := PartyCombatEngineClass.new(
			_player("Taktyk", "warrior", 12), [companion], _enemy(300, 1, 0), _rng(500 + index)
		)

		var report = combat.player_basic_attack()

		assert_eq(report.companion_skill_ids[companion.companion_id], values[3], values[0])


func test_heavy_knight_provokes_and_receives_the_enemy_attack() -> void:
	var player = _player("Ranny", "warrior", 12)
	player.stats.current_hp = 5
	var knight := _companion("knight", "warrior", 12, CompanionStateClass.TACTIC_BALANCED)
	knight.talents = {"heavy_knight_core": 1, "heavy_provoke": 1}
	var combat := PartyCombatEngineClass.new(player, [knight], _enemy(200, 12, 2), _rng(77))

	var report = combat.player_basic_attack()

	assert_eq(report.companion_skill_ids["knight"], "provoke")
	assert_eq(report.enemy_target_ids, ["knight"])
	assert_gt(int(report.enemy_damage_by_fighter.get("knight", 0)), 0)
	assert_false(report.enemy_damage_by_fighter.has("player"))


func test_bleed_ticks_at_the_start_of_the_same_round_enemy_turn() -> void:
	var player = _player("Krwawy", "warrior", 12)
	var combat := PartyCombatEngineClass.new(player, [], _enemy(200, 1, 0), _rng(91))

	var report = combat.player_skill("blood_strike")

	assert_eq(report.player_skill_id, "blood_strike")
	assert_eq(report.enemy_bleed_damage, 3)
	assert_eq(combat.effects.enemy_bleed_turns, 2)
	assert_eq(player.stats.current_mana, player.stats.max_mana - 12)


func test_armor_break_is_shared_by_later_party_actions() -> void:
	var player = _player("Łamacz", "warrior", 12)
	var companion := _companion("finisher", "warrior", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	var combat := PartyCombatEngineClass.new(player, [companion], _enemy(250, 1, 8), _rng(815))

	var report = combat.player_skill("armor_break")

	assert_true(report.turn_consumed)
	assert_eq(combat.effects.enemy_defense_reduction, 2)
	assert_eq(report.companion_skill_ids["finisher"], "blood_strike")
	assert_lt(report.enemy_hp_after, report.enemy_hp_before)


func test_rift_unique_effect_catalog_and_oathbreaker_work_in_party_combat() -> void:
	var effect_ids := [
		"rift_bastion_memory",
		"last_guard",
		"oathbreaker_bleed",
		"warden_afterguard",
		"third_echo",
		"riftglass_echo",
		"silent_volley",
		"afterimage_mana",
		"split_weave",
		"twin_star",
		"empty_mana_power",
		"storm_archive_refund",
		"two_lies",
		"ace_less_deck",
		"seven_chances",
		"crooked_smile",
	]
	for effect_id: String in effect_ids:
		assert_false(
			EquipmentClassEffectCatalogClass.get_definition(effect_id).is_empty(), effect_id
		)

	var companion := _companion("oathbreaker", "warrior", 18, CompanionStateClass.TACTIC_AGGRESSIVE)
	companion.equipment.equip_and_return_previous(
		ItemCatalogClass.create_equipment_item("oathbreaker_edge")
	)
	var combat := PartyCombatEngineClass.new(
		_player("Dowódca", "warrior", 12), [companion], _enemy(1000, 1, 0), _rng(818)
	)
	assert_true(
		combat.companion_fighters[0].profile.has_active_equipment_effect("oathbreaker_bleed")
	)

	combat.player_basic_attack()

	assert_eq(combat.effects.enemy_bleed_turns, 3)


func test_boss_frenzy_performs_two_attacks_below_thirty_five_percent() -> void:
	var player = _player("Cel", "warrior", 12)
	player.attributes.vitality = 10
	player.recalculate_stats()
	player.stats.restore_full()
	var enemy := _enemy(100, 5, 99, "boss")
	enemy.current_hp = 35
	var combat := PartyCombatEngineClass.new(player, [], enemy, _rng(63))

	var report = combat.player_basic_attack()

	assert_true(report.enemy_frenzy)
	assert_eq(report.enemy_target_ids, ["player", "player"])
	assert_eq(report.enemy_damage_by_fighter["player"], 2)


func test_adjusted_mana_shortage_falls_back_without_spending_mana() -> void:
	var companion := _companion("expensive", "warrior", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	companion.current_mana = 12
	var combat := PartyCombatEngineClass.new(
		_player("Dowódca", "warrior", 12), [companion], _enemy(200, 1, 0), _rng(42), 2.0
	)

	var report = combat.player_basic_attack()

	assert_eq(report.companion_skill_ids["expensive"], "blood_strike")
	assert_eq(companion.current_mana, 12)
	assert_true(report.lines.any(func(line: String) -> bool: return "brakuje Many" in line))


func test_companion_resources_are_resolved_and_synchronized_between_rounds() -> void:
	var companion := _companion("resources", "mage", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	companion.current_hp = 0
	companion.current_mana = 0
	var combat := PartyCombatEngineClass.new(
		_player("Dowódca", "warrior", 12), [companion], _enemy(200, 1, 0), _rng(404)
	)
	var fighter = combat.companion_fighters[0]

	assert_eq(fighter.profile.stats.current_hp, fighter.profile.stats.max_hp)
	assert_eq(fighter.profile.stats.current_mana, fighter.profile.stats.max_mana)
	var before_mana: int = fighter.profile.stats.current_mana
	var report = combat.player_basic_attack()

	assert_eq(report.companion_skill_ids["resources"], "mana_burst")
	assert_eq(companion.current_mana, before_mana - 14)
	assert_eq(companion.current_hp, fighter.profile.stats.current_hp)


func test_companion_reaching_zero_hp_does_not_start_stage_six_g_injuries() -> void:
	var player = _player("Ranny", "warrior", 12)
	player.stats.current_hp = 5
	var knight := _companion("boundary", "warrior", 12, CompanionStateClass.TACTIC_BALANCED)
	knight.current_hp = 1
	knight.talents = {"heavy_knight_core": 1, "heavy_provoke": 1}
	var combat := PartyCombatEngineClass.new(player, [knight], _enemy(200, 999, 0), _rng(3))

	var report = combat.player_basic_attack()

	assert_eq(report.enemy_target_ids, ["boundary"])
	assert_eq(knight.current_hp, 0)
	assert_false(knight.dead)
	assert_eq(knight.injury_until_day, 0)


func test_companion_can_finish_the_enemy_before_it_gets_a_turn() -> void:
	var player = _player("Dowódca", "warrior", 12)
	var companion := _companion("closer", "warrior", 12, CompanionStateClass.TACTIC_AGGRESSIVE)
	var combat := PartyCombatEngineClass.new(player, [companion], _enemy(8, 99, 0), _rng(19))
	var hp_before: int = player.stats.current_hp

	var report = combat.player_basic_attack()

	assert_true(report.victory)
	assert_eq(combat.result, PartyCombatEngineClass.VICTORY)
	assert_true(report.enemy_target_ids.is_empty())
	assert_eq(player.stats.current_hp, hp_before)


func test_invalid_player_skill_does_not_consume_a_party_round() -> void:
	var combat := (
		PartyCombatEngineClass
		. new(
			_player("Dowódca", "warrior", 12),
			[_companion("ally", "warrior", 12)],
			_enemy(50, 2, 0),
			_rng(9),
		)
	)

	var report = combat.player_skill("missing")

	assert_false(report.turn_consumed)
	assert_eq(report.error, "Nieznana umiejętność.")
	assert_true(report.companion_action_order.is_empty())
	assert_true(report.enemy_target_ids.is_empty())
	assert_eq(combat.round_number, 1)


func test_injected_rng_makes_a_complete_party_round_repeatable() -> void:
	var first := _deterministic_round(771)
	var second := _deterministic_round(771)

	assert_eq(first.lines, second.lines)
	assert_eq(first.enemy_hp_after, second.enemy_hp_after)
	assert_eq(first.companion_skill_ids, second.companion_skill_ids)
	assert_eq(first.enemy_target_ids, second.enemy_target_ids)
	assert_eq(first.enemy_damage_by_fighter, second.enemy_damage_by_fighter)


func _deterministic_round(seed: int) -> PartyCombatRoundResultClass:
	var combat := (
		PartyCombatEngineClass
		. new(
			_player("Los", "pierrot", 12),
			[
				_companion("mira", "pierrot", 12, CompanionStateClass.TACTIC_BALANCED),
				_companion("nessa", "hunter", 12, CompanionStateClass.TACTIC_BALANCED),
			],
			_enemy(300, 4, 3),
			_rng(seed),
		)
	)
	return combat.player_skill("grand_gamble")


func _player(display_name: String, class_code: String, level: int):
	var player = PlayerFactoryClass.create_player(display_name)
	player.level = level
	player.character_class_code = class_code
	player.attributes.strength = 6
	player.attributes.intelligence = 4
	player.attributes.endurance = 4
	player.recalculate_stats()
	player.stats.restore_full()
	return player


func _companion(
	companion_id: String,
	class_code: String,
	level: int,
	tactic := CompanionStateClass.TACTIC_BALANCED,
) -> CompanionStateClass:
	var template_id: String = (
		{
			"warrior": "kael",
			"hunter": "nessa",
			"mage": "elyra",
			"pierrot": "mira",
		}
		. get(class_code, "kael")
	)
	var definition = CompanionCatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = level
	companion.tactic = tactic
	companion.attributes.strength = 6
	companion.attributes.intelligence = 4
	companion.attributes.endurance = 4
	companion.current_hp = 20
	companion.current_mana = 20
	return companion


func _enemy(max_hp: int, attack: int, defense: int, rank := "normal") -> EnemyClass:
	return (
		EnemyClass
		. new(
			{
				"enemy_id": "stage-six-f-enemy",
				"display_name": "Przeciwnik testowy",
				"max_hp": max_hp,
				"attack": attack,
				"defense": defense,
				"dodge": 0.0,
				"rank": rank,
			}
		)
	)


func _rng(seed: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed
	return rng
