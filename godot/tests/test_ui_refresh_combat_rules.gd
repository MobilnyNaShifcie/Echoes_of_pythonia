extends GutTest

const COMBAT := preload("res://ui/screens/combat/combat.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Adventure := preload("res://core/world/adventure_service.gd")
const Regions := preload("res://core/world/region_catalog.gd")
const Enemies := preload("res://core/combat/enemy_catalog.gd")


func test_defeat_shows_terminal_zero_hp_not_post_rescue_full_health() -> void:
	for context in ["expedition", "prologue"]:
		for reduced in [true, false]:
			var session = NewGame.new().create_session("Aria", 1)
			var screen = COMBAT.instantiate()
			screen.configure(session, "wolf", context)
			add_child_autoqfree(screen)
			screen.set_reduced_motion(reduced)
			screen._presentation_controller.animation_duration_scale = 0.01
			screen._enemy.current_hp = 10000
			screen._enemy.attack = 10000
			session.player.stats.dodge = 0.0
			screen.attack_button.pressed.emit()
			if screen._presentation_controller.is_busy():
				await screen._presentation_controller.playback_finished
			assert_eq(screen._engine.result, "defeat")
			assert_eq(screen.player_hp_bar.value, 0.0)
			assert_string_contains(screen.player_stats_label.text, "PŻ 0/")
			assert_eq(session.player.stats.current_hp, session.player.stats.max_hp)
			screen._render()
			assert_eq(screen.player_hp_bar.value, 0.0)
			screen.configure(session, "wolf", "expedition")
			assert_eq(screen.player_hp_bar.value, float(session.player.stats.current_hp))


func test_every_region_and_period_encounters_even_on_maximum_roll() -> void:
	for region in Regions.get_all_definitions():
		assert_eq(region.encounter_chance, 1.0)
		for period in ["day", "night"]:
			for enemy_roll in range(0, 100):
				var result := Adventure._roll_region_exploration(
					region.region_id, period, 1.0, enemy_roll, 0
				)
				assert_false(result.enemy_id.is_empty())
				assert_true(Enemies.has_enemy(result.enemy_id))
				assert_has(region.encounters_for(period), result.enemy_id)


func test_live_expeditions_always_encounter_and_advance_exactly_one_hour() -> void:
	for region_id in Regions.REGION_ORDER:
		for seed_value in 20:
			var session = NewGame.new().create_session("Aria", 1)
			var rng := RandomNumberGenerator.new()
			rng.seed = seed_value
			var result := Adventure.explore_region(session, region_id, rng)
			assert_false(result.get("blocked", false))
			assert_false(result.enemy_id.is_empty())
			assert_eq(session.hour, 9)
