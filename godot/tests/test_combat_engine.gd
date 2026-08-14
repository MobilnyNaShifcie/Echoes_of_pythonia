extends GutTest

const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")


func test_prologue_combat_uses_legacy_damage_and_ends_in_victory() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	var enemy = EnemyCatalogClass.create_enemy("prologue_scarecrow")
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	var combat := CombatEngineClass.new(player, enemy, rng)

	assert_eq(combat.player_attack().player_damage, 3)
	assert_eq(enemy.current_hp, 4)
	assert_eq(player.stats.current_hp, 19)
	assert_eq(combat.player_attack().player_damage, 3)
	assert_eq(combat.player_attack().player_damage, 1)

	assert_eq(combat.result, CombatEngineClass.VICTORY)
	assert_eq(enemy.current_hp, 0)


func test_defend_halves_the_incoming_damage_with_integer_rounding() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	var enemy = EnemyCatalogClass.create_enemy("prologue_scarecrow")
	var combat := CombatEngineClass.new(player, enemy)

	var report := combat.player_defend()

	assert_true(report.player_defended)
	assert_eq(report.enemy_damage, 0)
	assert_eq(player.stats.current_hp, player.stats.max_hp)


func test_healing_item_action_still_allows_the_enemy_turn() -> void:
	var player = PlayerFactoryClass.create_player("Tester")
	player.stats.take_damage(10)
	var enemy = EnemyCatalogClass.create_enemy("prologue_scarecrow")
	var combat := CombatEngineClass.new(player, enemy)

	var report := combat.player_use_healing(20)

	assert_eq(report.player_healed, 10)
	assert_eq(report.enemy_damage, 1)
	assert_eq(player.stats.current_hp, 19)
