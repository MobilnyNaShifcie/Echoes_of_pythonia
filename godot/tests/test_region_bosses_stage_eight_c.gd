extends GutTest

const AzharCombatEngineClass := preload("res://core/combat/azhar_combat_engine.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const ClassLootServiceClass := preload("res://core/items/class_loot_service.gd")
const LeviathanNorthCombatEngineClass := preload(
	"res://core/combat/leviathan_north_combat_engine.gd"
)
const LootCatalogClass := preload("res://core/items/loot_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const QuestCatalogClass := preload("res://core/quests/quest_catalog.gd")
const RareBookDropServiceClass := preload("res://core/items/rare_book_drop_service.gd")
const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const RegionBossChallengeServiceClass := preload(
	"res://core/world/region_boss_challenge_service.gd"
)
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_catalog_maps_both_terminal_region_bosses_and_engines() -> void:
	assert_eq(RegionBossCatalogClass.BOSS_ORDER, ["azhar", "leviathan_north"])
	var azhar = RegionBossCatalogClass.get_definition("azhar")
	assert_eq(azhar.region_id, "ashen_borderlands")
	assert_eq(azhar.display_name, "Azhar, Władca Pustkowi")
	assert_eq(azhar.recommended_level, 14)
	assert_eq(azhar.engine_script, AzharCombatEngineClass)
	var leviathan = RegionBossCatalogClass.boss_for_region("ice_coast")
	assert_eq(leviathan.boss_id, "leviathan_north")
	assert_eq(leviathan.recommended_level, 18)
	assert_eq(leviathan.engine_script, LeviathanNorthCombatEngineClass)
	assert_null(RegionBossCatalogClass.boss_for_region("twilight_plains"))


func test_enemy_profiles_match_terminal_v0247() -> void:
	var azhar = EnemyCatalogClass.create_enemy("azhar")
	assert_eq(azhar.max_hp, 1850)
	assert_eq(azhar.attack, 34)
	assert_eq(azhar.defense, 14)
	assert_eq(azhar.dodge, 12.0)
	assert_eq(azhar.experience_reward, 1500)
	assert_eq(azhar.gold_min, 650)
	assert_eq(azhar.gold_max, 850)
	assert_eq(azhar.rank, "boss")
	assert_eq(azhar.special_name, "Gniew Pustyni")
	assert_almost_eq(azhar.special_chance, 0.28, 0.0001)
	assert_eq(azhar.special_attack_bonus, 10)
	assert_eq(azhar.special_damage_type, "earth")
	assert_eq(azhar.elemental_resistances.earth, 35)
	assert_eq(azhar.elemental_resistances.wind, 25)
	assert_almost_eq(azhar.status_resistance, 0.40, 0.0001)

	var leviathan = EnemyCatalogClass.create_enemy("leviathan_north")
	assert_eq(leviathan.max_hp, 3050)
	assert_eq(leviathan.attack, 52)
	assert_eq(leviathan.defense, 22)
	assert_eq(leviathan.dodge, 6.0)
	assert_eq(leviathan.experience_reward, 2350)
	assert_eq(leviathan.gold_min, 950)
	assert_eq(leviathan.gold_max, 1250)
	assert_eq(leviathan.rank, "boss")
	assert_eq(leviathan.special_name, "Fala Północy")
	assert_almost_eq(leviathan.special_chance, 0.32, 0.0001)
	assert_eq(leviathan.special_attack_bonus, 15)
	assert_eq(leviathan.special_damage_type, "water")
	assert_eq(leviathan.elemental_resistances.water, 60)
	assert_eq(leviathan.elemental_resistances.frost, 55)
	assert_eq(leviathan.elemental_resistances.wind, 25)
	assert_almost_eq(leviathan.status_resistance, 0.45, 0.0001)


func test_azhar_three_phases_match_terminal_thresholds_and_values() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var enemy = EnemyCatalogClass.create_enemy("azhar")
	var engine := AzharCombatEngineClass.new(session.player, enemy, _rng(1))
	var report := {"boss_notes": []}
	enemy.current_hp = int(enemy.max_hp * 0.60)
	engine._update_phase(report)
	assert_eq(engine.phase, 2)
	assert_eq(enemy.attack, 36)
	assert_eq(enemy.dodge, 22.0)
	assert_string_contains(report.boss_notes[0], "Burza Piaskowa")

	enemy.current_hp = int(enemy.max_hp * 0.25)
	engine._update_phase(report)
	assert_eq(engine.phase, 3)
	assert_eq(enemy.attack, 42)
	assert_eq(enemy.defense, 10)
	assert_eq(report.boss_notes.size(), 2)
	assert_string_contains(report.boss_notes[1], "Gniew Pustkowi")


func test_leviathan_three_phases_match_terminal_thresholds_and_values() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var enemy = EnemyCatalogClass.create_enemy("leviathan_north")
	var engine := LeviathanNorthCombatEngineClass.new(session.player, enemy, _rng(2))
	var report := {"boss_notes": []}
	enemy.current_hp = int(enemy.max_hp * 0.60)
	engine._update_phase(report)
	assert_eq(engine.phase, 2)
	assert_eq(enemy.attack, 56)
	assert_eq(enemy.defense, 26)
	assert_string_contains(report.boss_notes[0], "Wzburzone Morze")

	enemy.current_hp = int(enemy.max_hp * 0.25)
	engine._update_phase(report)
	assert_eq(engine.phase, 3)
	assert_eq(enemy.attack, 66)
	assert_eq(enemy.defense, 18)
	assert_eq(report.boss_notes.size(), 2)
	assert_string_contains(report.boss_notes[1], "Gniew Lewiatana")


func test_prepare_challenge_is_explicit_level_is_only_warning_and_weather_is_snapshotted() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 3
	session.weather_code = WeatherServiceClass.AURORA
	var result := RegionBossChallengeServiceClass.prepare_challenge(session, "ashen_borderlands")
	assert_true(result.ok)
	assert_eq(result.boss_id, "azhar")
	assert_eq(result.weather_code, WeatherServiceClass.AURORA)
	assert_eq(result.engine_script, AzharCombatEngineClass)
	assert_false(result.level_warning.is_empty())
	assert_eq(session.current_location_id, "ashen_borderlands")
	assert_eq(session.hour, 8, "Przygotowanie nie zużywa czasu przed zakończeniem walki.")
	assert_true(session.world_encounters.region_boss_respawns.is_empty())

	var missing := RegionBossChallengeServiceClass.prepare_challenge(session, "black_forest")
	assert_false(missing.ok)


func test_boss_loot_rare_books_story_and_guild_sources_are_live() -> void:
	assert_true(LootCatalogClass.has_table("azhar"))
	assert_true(LootCatalogClass.has_table("leviathan_north"))
	assert_eq(LootCatalogClass.get_table("azhar").size(), 5)
	assert_eq(LootCatalogClass.get_table("leviathan_north").size(), 3)
	assert_almost_eq(RareBookDropServiceClass.MASTERY_CHANCES.azhar, 0.01, 0.0001)
	assert_almost_eq(RareBookDropServiceClass.PATH_CHANCES.azhar, 0.005, 0.0001)
	assert_almost_eq(RareBookDropServiceClass.MASTERY_CHANCES.leviathan_north, 0.01, 0.0001)
	assert_almost_eq(RareBookDropServiceClass.PATH_CHANCES.leviathan_north, 0.005, 0.0001)
	assert_true(
		QuestCatalogClass.get_definition("awakening_ash_remembers").dependency_note.is_empty()
	)
	assert_true(
		QuestCatalogClass.get_definition("awakening_bells_beneath_ice").dependency_note.is_empty()
	)
	assert_true(GuildMilestoneServiceClass.get_definition("boss:azhar").dependency_note.is_empty())
	assert_true(
		GuildMilestoneServiceClass.get_definition("boss:leviathan_north").dependency_note.is_empty()
	)
	assert_eq(ClassLootServiceClass.region_for_enemy("azhar"), "ashlands")
	assert_eq(ClassLootServiceClass.region_for_enemy("leviathan_north"), "ice_coast")
	assert_almost_eq(ClassLootServiceClass.weapon_chance("boss", false), 0.20, 0.0001)
	assert_almost_eq(ClassLootServiceClass.gear_chance("boss", false), 0.04, 0.0001)
	assert_eq(ClassLootServiceClass.CLASS_WEAPON_POOLS.ashlands.size(), 3)
	assert_eq(ClassLootServiceClass.CLASS_WEAPON_POOLS.ice_coast.size(), 3)
	assert_eq(ClassLootServiceClass.CLASS_GEAR_POOL.size(), 4)


func test_region_boss_victory_grants_weather_rewards_boss_quality_and_milestone_once() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 18
	session.current_location_id = "ashen_borderlands"
	var enemy = EnemyCatalogClass.create_enemy("azhar")
	WeatherServiceClass.apply_to_enemy(enemy, WeatherServiceClass.AURORA)
	var first := RegionBossChallengeServiceClass.resolve_victory(session, enemy, _rng(8103))
	assert_true(first.ok)
	assert_eq(first.experience, 2250)
	assert_gte(first.gold, 975)
	assert_lte(first.gold, 1275)
	assert_eq(first.equipment_quality, "boss")
	assert_almost_eq(first.reward_multiplier, 1.5, 0.0001)
	assert_almost_eq(first.drop_chance_multiplier, 1.5, 0.0001)
	assert_gte(session.player.inventory.count("azhar_sigil"), 1)
	assert_true(first.guild_milestone.awarded)
	assert_eq(first.guild_milestone.reputation, 100)
	assert_eq(session.guild_reputation, 100)
	assert_has(session.guild_milestones, "boss:azhar")
	assert_true(session.world_encounters.region_boss_respawns.is_empty())

	var repeated := EnemyCatalogClass.create_enemy("azhar")
	WeatherServiceClass.apply_to_enemy(repeated, WeatherServiceClass.SUNNY)
	var second := RegionBossChallengeServiceClass.resolve_victory(session, repeated, _rng(8104))
	assert_false(second.guild_milestone.awarded)
	assert_eq(session.guild_reputation, 100)


func test_finishing_any_boss_attempt_advances_one_hour_without_starting_stage_8d_respawn() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.camp_rest_available = false
	session.world_encounters.region_boss_respawns = {"azhar": 4}
	var result := RegionBossChallengeServiceClass.finish_attempt(
		session, "azhar", "victory", _rng(3)
	)
	assert_true(result.ok)
	assert_eq(session.hour, 9)
	assert_true(session.camp_rest_available)
	assert_eq(session.world_encounters.region_boss_respawns, {"azhar": 4})


func test_world_map_and_combat_placeholder_expose_real_boss_flow() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 18
	var world = WORLD_MAP_SCENE.instantiate()
	add_child_autofree(world)
	world.configure(session, "ice_coast")
	assert_true(world.boss_button.visible)
	assert_string_contains(world.boss_button.text, "Lewiatan Północy")
	watch_signals(world)
	world.boss_button.pressed.emit()
	assert_signal_emitted(world, "boss_requested")

	var combat = COMBAT_SCENE.instantiate()
	add_child_autofree(combat)
	(
		combat
		. configure(
			session,
			"leviathan_north",
			"region_boss",
			WeatherServiceClass.FROST,
			LeviathanNorthCombatEngineClass,
			"WYZWANIE LEWIATANA",
		)
	)
	assert_true(combat._engine is LeviathanNorthCombatEngineClass)
	assert_eq(combat._enemy.weather_code, WeatherServiceClass.FROST)
	assert_string_contains(combat.encounter_label.text, "WYZWANIE LEWIATANA")
	assert_string_contains(combat.enemy_name_label.text, "MRÓZ")
	assert_false(combat.flee_button.disabled)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
