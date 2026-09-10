extends GutTest

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")


func test_day_and_night_use_their_separate_encounter_tables() -> void:
	var day_result := AdventureServiceClass._roll_exploration("day", 0.0, 0, 0)
	var night_result := AdventureServiceClass._roll_exploration("night", 0.0, 0, 0)

	assert_eq(day_result.enemy_id, "wild_dog")
	assert_eq(night_result.enemy_id, "plains_spirit")


func test_former_quiet_roll_now_starts_an_encounter() -> void:
	var result := AdventureServiceClass._roll_exploration("day", 0.8, 0, 2)

	assert_eq(result.enemy_id, "wild_dog")
	assert_string_contains(result.message, "Na szlaku")


func test_wolf_victory_grants_rewards_and_advances_the_story_objective() -> void:
	var session = NewGameServiceClass.new().create_session("Tester", 1)
	QuestServiceClass.accept_story_quest(session.quest_log)
	var enemy = EnemyCatalogClass.create_enemy("wolf")
	var rng := RandomNumberGenerator.new()
	rng.seed = 19

	var rewards := AdventureServiceClass.resolve_victory(session, enemy, rng)

	assert_eq(rewards.experience, 14)
	assert_eq(rewards.gold, 10)
	assert_eq(session.player.experience, 14)
	assert_eq(session.player.gold, 10)
	assert_eq(QuestServiceClass.get_progress(session.quest_log), 1)
