extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const EliteCatalogClass := preload("res://core/world/elite_catalog.gd")
const EliteEncounterServiceClass := preload("res://core/world/elite_encounter_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const OpenWorldEncounterStateClass := preload("res://core/world/open_world_encounter_state.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")


func test_catalog_covers_every_normal_open_world_enemy_and_only_known_modifiers() -> void:
	var encounter_ids := {}
	var normal_count := 0
	for region_id: String in RegionCatalogClass.REGION_ORDER:
		var region = RegionCatalogClass.get_definition(region_id)
		for table: Dictionary in [region.day_encounters, region.night_encounters]:
			for enemy_id: String in table:
				encounter_ids[enemy_id] = true
	for enemy_id: String in encounter_ids:
		var enemy = EnemyCatalogClass.create_enemy(enemy_id)
		if enemy.rank == "normal":
			normal_count += 1
			assert_true(
				EliteCatalogClass.COMPATIBILITY.has(enemy_id),
				"Brak wariantu elity: %s" % enemy_id,
			)
			for modifier_id: String in EliteCatalogClass.compatible_modifier_ids(enemy_id):
				assert_has(OpenWorldEncounterStateClass.ELITE_MODIFIER_IDS, modifier_id)
		else:
			assert_false(EliteCatalogClass.COMPATIBILITY.has(enemy_id))

	assert_eq(encounter_ids.size(), 36)
	assert_eq(normal_count, 31)
	assert_eq(EliteCatalogClass.COMPATIBILITY.size(), 31)
	assert_eq(EliteCatalogClass.get_all_modifiers().size(), 5)


func test_chances_and_regional_miss_streak_match_terminal_rules() -> void:
	assert_almost_eq(
		EliteEncounterServiceClass.elite_encounter_chance("day", "sunny"), 0.10, 0.0001
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_encounter_chance("night", "sunny"), 0.15, 0.0001
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_encounter_chance("day", "aurora"), 0.25, 0.0001
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_chance_with_streak("day", "sunny", 3),
		0.16,
		0.0001,
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_chance_with_streak("night", "sunny", 3),
		0.21,
		0.0001,
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_chance_with_streak("day", "aurora", 3),
		0.31,
		0.0001,
	)
	assert_almost_eq(
		EliteEncounterServiceClass.elite_chance_with_streak("day", "sunny", 10_000),
		0.95,
		0.0001,
	)
	assert_lt(
		EliteEncounterServiceClass.elite_chance_with_streak("day", "sunny", 10_000),
		1.0,
	)

	var state := OpenWorldEncounterStateClass.new()
	state.elite_miss_streaks = {
		"twilight_plains": 2,
		"black_forest": 4,
		"silentwater_marshes": 1,
	}
	var failed := (
		EliteEncounterServiceClass
		. resolve_roll(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			"sunny",
			"twilight_plains",
			state,
			0.99,
			0,
		)
	)
	assert_true(failed.ok)
	assert_true(failed.modifier_id.is_empty())
	assert_eq(state.elite_miss_streaks.twilight_plains, 3)
	assert_eq(state.elite_miss_streaks.black_forest, 4)
	assert_eq(state.elite_miss_streaks.silentwater_marshes, 1)

	var success := (
		EliteEncounterServiceClass
		. resolve_roll(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			"sunny",
			"twilight_plains",
			state,
			0.0,
			0,
		)
	)
	assert_true(success.ok)
	assert_eq(success.modifier_id, "furious")
	assert_eq(state.elite_miss_streaks.twilight_plains, 0)
	assert_eq(state.elite_miss_streaks.black_forest, 4)


func test_ineligible_enemy_never_changes_the_regional_counter() -> void:
	var state := OpenWorldEncounterStateClass.new()
	state.elite_miss_streaks = {"silentwater_marshes": 6}
	var result := (
		EliteEncounterServiceClass
		. resolve_roll(
			EnemyCatalogClass.create_enemy("drowned_mother"),
			"night",
			"aurora",
			"silentwater_marshes",
			state,
			0.0,
			0,
		)
	)

	assert_true(result.ok)
	assert_false(result.eligible)
	assert_true(result.modifier_id.is_empty())
	assert_eq(state.elite_miss_streaks.silentwater_marshes, 6)


func test_seeded_roll_is_deterministic_and_failed_roll_does_not_consume_choice_rng() -> void:
	var first_rng := RandomNumberGenerator.new()
	var second_rng := RandomNumberGenerator.new()
	first_rng.seed = 801
	second_rng.seed = 801
	var first_state := OpenWorldEncounterStateClass.new()
	var second_state := OpenWorldEncounterStateClass.new()
	var first := (
		EliteEncounterServiceClass
		. roll_for_region(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			"sunny",
			"twilight_plains",
			first_state,
			first_rng,
		)
	)
	var second := (
		EliteEncounterServiceClass
		. roll_for_region(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			"sunny",
			"twilight_plains",
			second_state,
			second_rng,
		)
	)

	assert_true(first.ok)
	assert_eq(first.modifier_id, second.modifier_id)
	assert_eq(first_state.elite_miss_streaks, second_state.elite_miss_streaks)
	assert_eq(first_rng.randi(), second_rng.randi())

	var preview := RandomNumberGenerator.new()
	preview.seed = 901
	var chance_roll := preview.randf()
	assert_gte(chance_roll, 0.10, "Seed regresyjny musi dawać nieudany rzut dzienny.")
	var expected_next := preview.randi()
	var failed_rng := RandomNumberGenerator.new()
	failed_rng.seed = 901
	var failed := (
		EliteEncounterServiceClass
		. roll_for_region(
			EnemyCatalogClass.create_enemy("wolf"),
			"day",
			"sunny",
			"twilight_plains",
			OpenWorldEncounterStateClass.new(),
			failed_rng,
		)
	)
	assert_true(failed.ok)
	assert_true(failed.modifier_id.is_empty())
	assert_eq(failed_rng.randi(), expected_next)


func test_furious_armored_vampiric_and_cursed_apply_terminal_values() -> void:
	var furious = EnemyCatalogClass.create_enemy("wolf")
	var furious_result := EliteEncounterServiceClass.apply_modifier(furious, "furious", "sunny")
	assert_true(furious_result.ok)
	assert_eq(furious.display_name, "Wściekły Wilk")
	assert_eq(furious.max_hp, 15)
	assert_eq(furious.current_hp, 15)
	assert_eq(furious.attack, 6)
	assert_eq(furious.defense, 1)
	assert_eq(furious.dodge, 8.0)
	assert_eq(furious.experience_reward, 21)
	assert_eq(furious.gold_min, 12)
	assert_eq(furious.gold_max, 12)
	assert_eq(furious.loot_chance_multiplier, 1.20)

	var armored = EnemyCatalogClass.create_enemy("slime")
	assert_true(EliteEncounterServiceClass.apply_modifier(armored, "armored", "sunny").ok)
	assert_eq(armored.display_name, "Opancerzony Slime")
	assert_eq(armored.max_hp, 17)
	assert_eq(armored.attack, 3)
	assert_eq(armored.defense, 4)

	var vampiric = EnemyCatalogClass.create_enemy("wolf")
	assert_true(EliteEncounterServiceClass.apply_modifier(vampiric, "vampiric", "sunny").ok)
	assert_eq(vampiric.display_name, "Wampiryczny Wilk")
	assert_eq(vampiric.max_hp, 17)
	assert_eq(vampiric.life_steal_percent, 40.0)

	var cursed = EnemyCatalogClass.create_enemy("rotting_knight")
	assert_true(EliteEncounterServiceClass.apply_modifier(cursed, "cursed", "sunny").ok)
	assert_eq(cursed.display_name, "Przeklęty Zgniły Rycerz")
	assert_eq(cursed.special_name, "Uderzenie Klątwy")
	assert_almost_eq(cursed.special_chance, 0.30, 0.0001)
	assert_eq(cursed.special_attack_bonus, 2)
	assert_almost_eq(cursed.status_resistance, 0.50, 0.0001)

	var incompatible = EnemyCatalogClass.create_enemy("slime")
	var rejected := EliteEncounterServiceClass.apply_modifier(incompatible, "vampiric", "sunny")
	assert_false(rejected.ok)
	assert_eq(incompatible.rank, "normal")


func test_aurora_elemental_witch_uses_weather_order_and_feminine_grammar() -> void:
	var enemy = EnemyCatalogClass.create_enemy("swamp_witch")
	WeatherServiceClass.apply_to_enemy(enemy, WeatherServiceClass.AURORA)
	var result := EliteEncounterServiceClass.apply_modifier(
		enemy, "elemental", WeatherServiceClass.AURORA
	)

	assert_true(result.ok)
	assert_eq(enemy.display_name, "Zorzowa Bagienna Wiedźma")
	assert_eq(enemy.grammatical_gender, "feminine")
	assert_eq(enemy.max_hp, 73)
	assert_eq(enemy.attack, 18)
	assert_eq(enemy.defense, 4)
	assert_eq(enemy.dodge, 23.0)
	assert_eq(enemy.basic_damage_type, "frost")
	assert_eq(enemy.special_damage_type, "frost")
	assert_eq(enemy.elemental_resistances.frost, 50)
	assert_eq(enemy.elemental_resistances.water, 0)
	assert_eq(enemy.special_attack_bonus, 6)


func test_vampiric_elite_heals_from_each_successful_enemy_hit() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.attributes.vitality = 10
	session.player.recalculate_stats()
	session.player.stats.restore_full()
	var enemy = EnemyCatalogClass.create_enemy("corrupted_bear")
	assert_true(EliteEncounterServiceClass.apply_modifier(enemy, "vampiric", "sunny").ok)
	enemy.current_hp -= 10
	var before: int = enemy.current_hp
	var rng := RandomNumberGenerator.new()
	rng.seed = 4
	var engine := CombatEngineClass.new(session.player, enemy, rng)

	var report := engine.player_attack()

	assert_gt(int(report.enemy_healed), 0)
	assert_gt(enemy.current_hp, before - int(report.player_damage))


func test_exploration_rolls_elite_once_and_passes_the_exact_modifier_forward() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.weather_code = WeatherServiceClass.SUNNY
	session.weather_remaining_hours = 6
	session.world_encounters.elite_miss_streaks = {"twilight_plains": 43}
	var chosen_seed := -1
	for seed_value in 1000:
		var preview := RandomNumberGenerator.new()
		preview.seed = seed_value
		if preview.randf() >= 0.80:
			continue
		preview.randi()
		preview.randi()
		if preview.randf() < 0.95:
			chosen_seed = seed_value
			break
	assert_gte(chosen_seed, 0)
	var rng := RandomNumberGenerator.new()
	rng.seed = chosen_seed

	var result := AdventureServiceClass.explore_region(session, "twilight_plains", rng)

	assert_false(result.enemy_id.is_empty())
	assert_false(result.elite_modifier_id.is_empty())
	assert_string_contains(result.message, "Na szlaku pojawia się:")
	assert_eq(session.world_encounters.elite_miss_streaks.twilight_plains, 0)
	assert_true(session.world_encounters.elite_discoveries.is_empty())

	var combat = COMBAT_SCENE.instantiate()
	add_child_autofree(combat)
	(
		combat
		. configure(
			session,
			result.enemy_id,
			"expedition",
			result.weather_code,
			null,
			"",
			result.elite_modifier_id,
		)
	)
	assert_eq(combat._enemy.elite_modifier_id, result.elite_modifier_id)
	assert_string_contains(combat.encounter_label.text, "ELITA")
	assert_string_contains(combat.enemy_name_label.tooltip_text, "Elita:")
	assert_eq(session.world_encounters.elite_miss_streaks.twilight_plains, 0)


func test_elite_victory_updates_contract_rewards_loot_quality_and_discovery_once() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 12
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2099-08-09", "2099-W32"
	)
	var elite_contract = session.contract_board.daily_contracts[2]
	var region_id: String = elite_contract.objectives[0].target_id
	session.current_location_id = region_id
	var enemy = EnemyCatalogClass.create_enemy("wolf")
	assert_true(EliteEncounterServiceClass.apply_modifier(enemy, "furious", "sunny").ok)
	var rng := RandomNumberGenerator.new()
	rng.seed = 8107

	var first := AdventureServiceClass.resolve_victory(session, enemy, rng)

	assert_eq(first.elite_modifier_id, "furious")
	assert_eq(first.equipment_quality, "elite")
	assert_almost_eq(first.drop_chance_multiplier, 1.20, 0.0001)
	assert_false(first.elite_discovery_note.is_empty())
	assert_eq(session.world_encounters.elite_discoveries, ["furious"])
	assert_eq(
		(
			ContractServiceClass
			. objective_progress(session.player, session.contract_board, elite_contract, 0)[0]
		),
		1,
	)
	assert_false(ContractServiceClass.dependency_note(elite_contract).contains("elity"))

	var repeated = EnemyCatalogClass.create_enemy("wolf")
	assert_true(EliteEncounterServiceClass.apply_modifier(repeated, "furious", "sunny").ok)
	var second := AdventureServiceClass.resolve_victory(session, repeated, rng)
	assert_true(second.elite_discovery_note.is_empty())
	assert_eq(session.world_encounters.elite_discoveries, ["furious"])
