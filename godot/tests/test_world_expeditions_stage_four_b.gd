extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CombatEnemyClass := preload("res://core/combat/enemy.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_every_open_world_encounter_has_a_combat_definition() -> void:
	var encounter_ids := {}
	for region in RegionCatalogClass.get_all_definitions():
		for table: Dictionary in [region.day_encounters, region.night_encounters]:
			for enemy_id: String in table:
				encounter_ids[enemy_id] = true
				assert_true(
					EnemyCatalogClass.has_enemy(enemy_id),
					"Brak definicji przeciwnika: %s" % enemy_id,
				)
				assert_not_null(EnemyCatalogClass.create_enemy(enemy_id))
	assert_eq(encounter_ids.size(), 36)


func test_regional_enemy_stats_resistances_and_ranks_match_terminal_data() -> void:
	var spider = EnemyCatalogClass.create_enemy("venom_spider")
	assert_eq(spider.max_hp, 14)
	assert_eq(spider.attack, 5)
	assert_eq(spider.special_name, "Jadowite Ukąszenie")
	var drowned_mother = EnemyCatalogClass.create_enemy("drowned_mother")
	assert_eq(drowned_mother.max_hp, 95)
	assert_eq(drowned_mother.rank, "miniboss")
	assert_eq(drowned_mother.special_damage_type, "water")
	var golem = EnemyCatalogClass.create_enemy("sand_golem")
	assert_eq(golem.max_hp, 440)
	assert_eq(golem.physical_damage_reduction, 2)
	assert_eq(golem.elemental_resistances.earth, 35)
	var siren = EnemyCatalogClass.create_enemy("black_sea_siren")
	assert_eq(siren.elemental_resistances.water, 50)
	assert_eq(siren.elemental_resistances.frost, 30)
	assert_eq(siren.status_resistance, 0.2)
	var captain = EnemyCatalogClass.create_enemy("ghost_ship_captain")
	assert_eq(captain.max_hp, 1480)
	assert_eq(captain.gold_max, 720)
	assert_eq(captain.status_resistance, 0.3)


func test_first_region_specials_keep_their_terminal_damage_types() -> void:
	assert_eq(EnemyCatalogClass.create_enemy("cursed_scarecrow").special_damage_type, "fire")
	assert_eq(EnemyCatalogClass.create_enemy("nature_guardian").special_damage_type, "earth")
	assert_eq(EnemyCatalogClass.create_enemy("hunter").special_damage_type, "")


func test_each_region_uses_its_own_day_and_night_encounter_tables() -> void:
	var expected := {
		"black_forest": ["venom_spider", "gallows_wraith"],
		"silentwater_marshes": ["bog_crawler", "mist_walker"],
		"ashen_borderlands": ["desert_wanderer", "boneburner"],
		"ice_coast": ["frozen_castaway", "black_sea_siren"],
	}
	for region_id: String in expected:
		var day := AdventureServiceClass._roll_region_exploration(region_id, "day", 0.0, 0, 0)
		var night := AdventureServiceClass._roll_region_exploration(region_id, "night", 0.0, 0, 0)
		assert_eq(day.enemy_id, expected[region_id][0])
		assert_eq(night.enemy_id, expected[region_id][1])


func test_former_quiet_roll_preserves_the_selected_regions_enemy_table() -> void:
	var former_quiet := AdventureServiceClass._roll_region_exploration(
		"ice_coast", "day", 0.93, 0, 1
	)
	var encounter := AdventureServiceClass._roll_region_exploration("ice_coast", "day", 0.929, 0, 1)
	assert_eq(former_quiet.enemy_id, "frozen_castaway")
	assert_eq(encounter.enemy_id, "frozen_castaway")


func test_high_level_region_is_not_locked_and_advances_one_hour() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var rng := RandomNumberGenerator.new()
	rng.seed = 41
	var result := AdventureServiceClass.explore_region(session, "ice_coast", rng)

	assert_false(result.get("blocked", false))
	assert_eq(session.current_location_id, "ice_coast")
	assert_eq(session.hour, 9)
	if not result.enemy_id.is_empty():
		assert_true(EnemyCatalogClass.has_enemy(result.enemy_id))


func test_unknown_region_is_rejected_without_advancing_time() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var result := AdventureServiceClass.explore_region(
		session, "unknown_region", RandomNumberGenerator.new()
	)
	assert_true(result.blocked)
	assert_eq(session.hour, 8)
	assert_eq(session.current_location_id, "twilight_plains")


func test_selected_region_survives_save_round_trip() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "ice_coast"
	var service := SaveGameServiceClass.new()
	var payload: Dictionary = service._serialize_session(session)
	var result := service._deserialize_payload(payload, 1)
	assert_true(result.ok, result.message)
	assert_eq(result.session.current_location_id, "ice_coast")


func test_regional_victory_grants_terminal_experience_and_gold_range() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var enemy = EnemyCatalogClass.create_enemy("venom_spider")
	var rng := RandomNumberGenerator.new()
	rng.seed = 17
	var rewards := AdventureServiceClass.resolve_victory(session, enemy, rng)
	assert_eq(rewards.experience, 30)
	assert_between(rewards.gold, 20, 28)
	assert_eq(session.player.experience, 30)
	assert_eq(session.victories, 1)


func test_world_screen_starts_real_expedition_in_selected_region() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	screen._rng.seed = 9
	screen.region_list.select(1)
	screen.region_list.item_selected.emit(1)

	assert_false(screen.explore_button.disabled)
	assert_eq(screen.explore_button.text, "Wyrusz na wyprawę  •  +1 godzina")
	screen.explore_button.pressed.emit()
	assert_eq(session.current_location_id, "black_forest")
	assert_eq(session.hour, 9)


func test_regional_combat_header_uses_current_region_name() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "ice_coast"
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "frozen_castaway", "expedition")
	add_child_autofree(screen)
	assert_eq(screen.encounter_label.text, "LODOWE WYBRZEŻE — WALKA TUROWA")


func test_status_resistance_can_reject_bleed_and_armor_break() -> void:
	var player = PlayerFactoryClass.create_player("Aria")
	player.level = 5
	assert_true(player.choose_class("warrior"))
	player.level = 7
	player.stats.restore_full()
	var enemy := (
		CombatEnemyClass
		. new(
			{
				"enemy_id": "resistant_enemy",
				"display_name": "Odporny cel",
				"max_hp": 100,
				"attack": 0,
				"defense": 5,
				"dodge": 0.0,
				"status_resistance": 1.0,
			}
		)
	)
	var combat := CombatEngineClass.new(player, enemy)
	var report := combat.player_use_skill("armor_break")

	assert_eq(combat.effects.enemy_defense_reduction, 0)
	assert_string_contains("\n".join(report.skill_notes), "odpiera negatywny efekt")
