extends GutTest

const AdmiralVarekCombatEngineClass := preload("res://core/combat/admiral_varek_combat_engine.gd")
const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CombatReportFactoryClass := preload("res://core/combat/combat_report_factory.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const DungeonCatalogClass := preload("res://core/dungeons/dungeon_catalog.gd")
const DungeonServiceClass := preload("res://core/dungeons/dungeon_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const GrandMasterCombatEngineClass := preload("res://core/combat/grandmaster_combat_engine.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const LootCatalogClass := preload("res://core/items/loot_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")
const DUNGEON_SCENE := preload("res://ui/screens/dungeon/dungeon.tscn")


func test_catalog_preserves_both_terminal_solo_dungeons() -> void:
	assert_eq(
		DungeonCatalogClass.DUNGEON_ORDER,
		["sunken_order_crypt", "black_fleet_wreck"],
	)
	var crypt = DungeonCatalogClass.get_definition("sunken_order_crypt")
	assert_eq(crypt.display_name, "Krypta Zatopionego Zakonu")
	assert_eq(crypt.region_id, "silentwater_marshes")
	assert_eq(crypt.recommended_level_text(), "7–10")
	assert_eq(crypt.entry_item_id, "ancient_order_key")
	assert_eq(crypt.room_one_enemies, ["drowned_dead", "drowned_acolyte", "sunken_knight"])
	assert_eq(crypt.flooded_ambush_chance, 0.45)
	assert_eq(crypt.mandatory_elite_enemy, "crypt_warden")
	assert_eq(crypt.boss_enemy, "order_grandmaster")
	assert_eq(crypt.chest_loot.size(), 3)

	var fleet = DungeonCatalogClass.get_definition("black_fleet_wreck")
	assert_eq(fleet.display_name, "Wrak Czarnej Floty")
	assert_eq(fleet.region_id, "ice_coast")
	assert_eq(fleet.recommended_level_text(), "16–20")
	assert_eq(fleet.entry_item_id, "black_fleet_medallion")
	assert_eq(fleet.flooded_ambush_chance, 1.0)
	assert_eq(fleet.mandatory_elite_enemy, "black_fleet_first_officer")
	assert_eq(fleet.boss_enemy, "admiral_varek")
	assert_eq(fleet.chest_loot.size(), 4)


func test_all_dungeon_enemies_loot_and_new_items_are_available() -> void:
	var expected_hp := {
		"drowned_acolyte": 50,
		"drowned_priestess": 82,
		"iron_gate_guardian": 105,
		"crypt_warden": 120,
		"order_grandmaster": 220,
		"cursed_sailor": 720,
		"black_fleet_drowned": 880,
		"cursed_gunner": 690,
		"spectral_marksman": 640,
		"black_fleet_boatswain": 1080,
		"black_fleet_first_officer": 2150,
		"admiral_varek": 4300,
	}
	for enemy_id: String in expected_hp:
		var enemy = EnemyCatalogClass.create_enemy(enemy_id)
		assert_not_null(enemy, enemy_id)
		assert_eq(enemy.max_hp, expected_hp[enemy_id], enemy_id)
		assert_true(LootCatalogClass.has_table(enemy_id), enemy_id)
	for item_id: String in [
		"order_seal",
		"grandmaster_chain",
		"crown_fragment",
		"grandmaster_sword",
		"sunken_order_cloak",
		"varek_sabre_fragment",
		"varek_sabre",
	]:
		assert_not_null(ItemCatalogClass.get_definition(item_id), item_id)
	assert_eq(ItemCatalogClass.get_definition("grandmaster_sword").item_power, 4)
	assert_eq(ItemCatalogClass.get_definition("varek_sabre").item_power, 7)


func test_entry_is_atomic_solo_only_and_snapshot_happens_after_consumption() -> void:
	var rng := _rng(10)
	var missing = DungeonServiceClass.start(_session(), "sunken_order_crypt", rng)
	assert_false(missing.ok)
	assert_string_contains(missing.message, "Starożytny Klucz Zakonu")

	var party_session = _session()
	party_session.player.inventory.add("ancient_order_key")
	var companion := CompanionStateClass.new("ally", "kael", "Kael", "warrior")
	companion.active = true
	party_session.party.companions.append(companion)
	var blocked = DungeonServiceClass.start(party_session, "sunken_order_crypt", rng)
	assert_false(blocked.ok)
	assert_string_contains(blocked.message, "SOLO")
	assert_eq(party_session.player.inventory.count("ancient_order_key"), 1)

	var session = _session()
	session.player.inventory.add("ancient_order_key")
	var started = DungeonServiceClass.start(session, "sunken_order_crypt", rng)
	assert_true(started.ok, started.message)
	assert_eq(session.player.inventory.count("ancient_order_key"), 0)
	assert_eq(started.run.snapshot_stacks.get("ancient_order_key", 0), 0)
	assert_eq(started.run.step, "room_one")
	assert_eq(session.current_location_id, "silentwater_marshes")


func test_defeat_discards_only_unsecured_items_but_keeps_gold_and_experience() -> void:
	var rng := _rng(20)
	var session = _session()
	session.player.inventory.add("ancient_order_key")
	session.player.inventory.add("order_seal", 2)
	var run = DungeonServiceClass.start(session, "sunken_order_crypt", rng).run
	session.player.inventory.add("order_seal", 3)
	session.player.inventory.add(
		"grandmaster_sword", 1, rng, EquipmentAffixServiceClass.QUALITY_DUNGEON
	)
	session.player.gold = 321
	session.player.experience = 87
	session.player.stats.current_hp = 1
	assert_true(DungeonServiceClass.choose(run, session, "begin", rng).combat)
	var result = DungeonServiceClass.resolve_combat(run, session, "defeat", rng)

	assert_true(result.ok)
	assert_eq(run.outcome, "defeated")
	assert_eq(session.player.inventory.count("ancient_order_key"), 0)
	assert_eq(session.player.inventory.count("order_seal"), 2)
	assert_eq(session.player.inventory.count("grandmaster_sword"), 0)
	assert_eq(session.player.gold, 321)
	assert_eq(session.player.experience, 87)
	assert_eq(session.player.stats.current_hp, session.player.stats.max_hp)
	assert_eq(_loot_quantity(run.last_loot, "order_seal"), 3)
	assert_eq(_loot_quantity(run.last_loot, "grandmaster_sword"), 1)


func test_safe_retreat_keeps_all_loot_and_does_not_restore_resources() -> void:
	var rng := _rng(30)
	var session = _session()
	session.player.inventory.add("ancient_order_key")
	var run = DungeonServiceClass.start(session, "sunken_order_crypt", rng).run
	session.player.inventory.add("order_seal", 2)
	session.player.stats.current_hp = 4
	var result = DungeonServiceClass.choose(run, session, "retreat", rng)

	assert_true(result.ok)
	assert_eq(run.outcome, "retreated")
	assert_eq(session.player.inventory.count("order_seal"), 2)
	assert_eq(session.player.stats.current_hp, 4)
	assert_eq(_loot_quantity(run.last_loot, "order_seal"), 2)


func test_crypt_chest_is_presented_before_the_optional_ambush() -> void:
	var rng := _rng(31)
	var session = _session()
	session.player.inventory.add("ancient_order_key")
	var run = DungeonServiceClass.start(session, "sunken_order_crypt", rng).run
	run.step = "crossroads"
	var chest := DungeonServiceClass.choose(run, session, "path_flooded", rng)

	assert_true(chest.ok)
	assert_false(chest.combat)
	assert_eq(run.step, "flooded_chest")
	assert_eq(session.hour, 9)
	assert_eq(session.player.inventory.count("order_seal"), 1)
	assert_eq(session.player.inventory.count("drowned_coin"), 2)
	assert_string_contains(DungeonServiceClass.view(run, session).message, "Zatopiona skrzynia")
	run.branch_ambush_pending = true
	var ambush := DungeonServiceClass.choose(run, session, "continue", rng)
	assert_true(ambush.combat)
	assert_eq(ambush.enemy_id, "drowned_priestess")


func test_fleet_upper_deck_narrative_precedes_the_mandatory_gunner() -> void:
	var rng := _rng(32)
	var session = _session()
	session.player.inventory.add("black_fleet_medallion")
	var run = DungeonServiceClass.start(session, "black_fleet_wreck", rng).run
	run.step = "crossroads"
	var upper := DungeonServiceClass.choose(run, session, "path_upper", rng)

	assert_true(upper.ok)
	assert_false(upper.combat)
	assert_eq(run.step, "upper_deck")
	assert_string_contains(DungeonServiceClass.view(run, session).description, "błysk lontu")
	var gunner := DungeonServiceClass.choose(run, session, "continue", rng)
	assert_true(gunner.combat)
	assert_eq(gunner.enemy_id, "cursed_gunner")


func test_recovery_uses_python_half_even_rounding_and_terminal_fractions() -> void:
	var session = _session()
	session.player.stats.max_hp = 10
	session.player.stats.current_hp = 0
	session.player.stats.max_mana = 10
	session.player.stats.current_mana = 0
	var crypt := DungeonServiceClass.restore_resources(session, 0.25)
	assert_eq(crypt, {"hp": 2, "mana": 2})
	assert_eq(session.player.stats.current_hp, 2)
	assert_eq(session.player.stats.current_mana, 2)

	session.player.stats.current_hp = 0
	session.player.stats.current_mana = 0
	var fleet := DungeonServiceClass.restore_resources(session, 0.30)
	assert_eq(fleet, {"hp": 3, "mana": 3})


func test_dungeon_victory_ignores_surface_weather_and_grants_dungeon_loot() -> void:
	var session = _session()
	session.weather_code = "aurora"
	var enemy = EnemyCatalogClass.create_enemy("crypt_warden")
	var rewards := AdventureServiceClass.resolve_dungeon_victory(session, enemy, _rng(35))

	assert_eq(rewards.experience, 260)
	assert_between(rewards.gold, 190, 260)
	assert_eq(rewards.reward_multiplier, 1.0)
	assert_eq(rewards.drop_chance_multiplier, 1.0)
	assert_eq(session.player.inventory.count("grandmaster_chain"), 1)


func test_crypt_full_iron_route_reaches_grandmaster_and_records_completion() -> void:
	var rng := _rng(40)
	var session = _session()
	session.player.inventory.add("ancient_order_key")
	var run = DungeonServiceClass.start(session, "sunken_order_crypt", rng).run

	_win_action(run, session, "begin", rng)
	_win_action(run, session, "continue", rng)
	assert_true(DungeonServiceClass.choose(run, session, "continue", rng).ok)
	assert_eq(run.step, "crossroads")
	_win_action(run, session, "path_iron", rng)
	_win_action(run, session, "continue", rng)
	assert_eq(run.step, "recovery")
	assert_true(DungeonServiceClass.choose(run, session, "skip_recovery", rng).ok)
	_win_action(run, session, "continue", rng)
	assert_eq(run.step, "final_gate")
	var boss = DungeonServiceClass.choose(run, session, "continue", rng)
	assert_eq(boss.enemy_id, "order_grandmaster")
	assert_eq(DungeonServiceClass.engine_script_for(boss.enemy_id), GrandMasterCombatEngineClass)
	assert_true(DungeonServiceClass.resolve_combat(run, session, "victory", rng).ok)

	assert_true(run.completed)
	assert_eq(run.outcome, "completed")
	assert_true("dungeon:sunken_order_crypt" in session.guild_milestones)
	assert_eq(session.guild_reputation, 150)
	assert_eq(session.hour, 14)


func test_black_fleet_cargo_route_has_two_fights_treasure_and_varek() -> void:
	var rng := _rng(50)
	var session = _session()
	session.player.inventory.add("black_fleet_medallion")
	var run = DungeonServiceClass.start(session, "black_fleet_wreck", rng).run

	_win_action(run, session, "begin", rng)
	_win_action(run, session, "continue", rng)
	DungeonServiceClass.choose(run, session, "continue", rng)
	_win_action(run, session, "path_cargo", rng)
	assert_eq(run.step, "cargo_boatswain")
	_win_action(run, session, "continue", rng)
	assert_eq(run.step, "cargo_treasure")
	assert_true(DungeonServiceClass.choose(run, session, "claim_treasure", rng).ok)
	assert_gte(session.player.inventory.count("cursed_compass"), 2)
	assert_gte(session.player.inventory.count("black_pearl"), 1)
	_win_action(run, session, "continue", rng)
	DungeonServiceClass.choose(run, session, "skip_recovery", rng)
	_win_action(run, session, "continue", rng)
	var boss = DungeonServiceClass.choose(run, session, "continue", rng)
	assert_eq(boss.enemy_id, "admiral_varek")
	assert_eq(DungeonServiceClass.engine_script_for(boss.enemy_id), AdmiralVarekCombatEngineClass)
	DungeonServiceClass.resolve_combat(run, session, "victory", rng)

	assert_true(run.completed)
	assert_true("dungeon:black_fleet_wreck" in session.guild_milestones)
	assert_eq(session.guild_reputation, 250)
	assert_eq(session.hour, 16)


func test_grandmaster_phases_and_water_aura_match_terminal_rules() -> void:
	var session = _session()
	session.player.stats.max_hp = 1000
	session.player.stats.current_hp = 1000
	var enemy = EnemyCatalogClass.create_enemy("order_grandmaster")
	var combat := GrandMasterCombatEngineClass.new(session.player, enemy, _rng(60))
	enemy.current_hp = 50
	var report := CombatReportFactoryClass.create(combat)
	combat._enemy_turn(report)

	assert_eq(combat.phase, 3)
	assert_eq(enemy.attack, 21)
	assert_eq(enemy.defense, 6)
	assert_eq(report.boss_notes.size(), 2)
	assert_eq(report.boss_aura_damage, 2)


func test_varek_salvo_is_announced_and_phase_three_cancels_it() -> void:
	var session = _session()
	session.player.stats.max_hp = 10000
	session.player.stats.current_hp = 10000
	var enemy = EnemyCatalogClass.create_enemy("admiral_varek")
	var combat := AdmiralVarekCombatEngineClass.new(session.player, enemy, _rng(70))
	enemy.current_hp = 2000
	var phase_two := CombatReportFactoryClass.create(combat)
	combat._update_phase(phase_two)
	assert_eq(combat.phase, 2)
	combat.cannon_pending = true
	assert_string_contains(combat.boss_status_lines()[0], "Salwa Armatnia")
	var salvo := CombatReportFactoryClass.create(combat)
	combat._enemy_turn(salvo, true)
	assert_eq(salvo.enemy_special_name, "Salwa Armatnia")
	assert_false(combat.cannon_pending)

	enemy.current_hp = 1000
	combat.cannon_pending = true
	var phase_three := CombatReportFactoryClass.create(combat)
	combat._update_phase(phase_three)
	assert_eq(combat.phase, 3)
	assert_false(combat.cannon_pending)
	assert_eq(enemy.attack, 73)
	assert_eq(enemy.defense, 19)


func test_world_map_and_dungeon_placeholder_expose_the_solo_flow() -> void:
	var session = _session()
	session.player.inventory.add("ancient_order_key")
	var map = WORLD_MAP_SCENE.instantiate()
	map.configure(session, "silentwater_marshes")
	add_child_autofree(map)
	assert_true(map.dungeon_button.visible)
	assert_string_contains(map.dungeon_button.text, "Krypta Zatopionego Zakonu")

	var screen = DUNGEON_SCENE.instantiate()
	screen.configure(session, "sunken_order_crypt")
	add_child_autofree(screen)
	assert_string_contains(screen.eyebrow_label.text, "SOLO")
	assert_string_contains(screen.message_label.text, "Starożytny Klucz Zakonu")
	assert_eq(screen.actions.get_child_count(), 2)


func _win_action(run, session, action: String, rng: RandomNumberGenerator) -> void:
	var encounter = DungeonServiceClass.choose(run, session, action, rng)
	assert_true(encounter.ok, str(encounter.get("message", "")))
	assert_true(encounter.get("combat", false), action)
	assert_true(DungeonServiceClass.resolve_combat(run, session, "victory", rng).ok)


func _loot_quantity(loot: Array[Dictionary], item_id: String) -> int:
	for entry: Dictionary in loot:
		if entry.item_id == item_id:
			return int(entry.quantity)
	return 0


func _session():
	return NewGameServiceClass.new().create_session("Tester", 1, _rng(1))


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
