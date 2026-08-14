extends GutTest

const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")


func test_first_story_quest_tracks_exactly_two_wolf_kills() -> void:
	var session = NewGameServiceClass.new().create_session("Tester", 1)

	assert_true(QuestServiceClass.accept_story_quest(session.quest_log))
	assert_eq(QuestServiceClass.get_progress(session.quest_log), 0)
	assert_true(QuestServiceClass.record_enemy_kill(session.quest_log, "slime").is_empty())
	assert_eq(QuestServiceClass.record_enemy_kill(session.quest_log, "wolf").current, 1)
	assert_eq(QuestServiceClass.record_enemy_kill(session.quest_log, "wolf").current, 2)
	assert_eq(QuestServiceClass.record_enemy_kill(session.quest_log, "wolf").current, 2)
	assert_true(QuestServiceClass.is_ready(session.quest_log))


func test_turning_in_first_story_quest_grants_legacy_rewards() -> void:
	var session = NewGameServiceClass.new().create_session("Tester", 1)
	QuestServiceClass.accept_story_quest(session.quest_log)
	QuestServiceClass.record_enemy_kill(session.quest_log, "wolf")
	QuestServiceClass.record_enemy_kill(session.quest_log, "wolf")

	var reward := QuestServiceClass.turn_in_story_quest(session)

	assert_eq(reward.experience, 45)
	assert_eq(reward.gold, 70)
	assert_eq(session.player.experience, 45)
	assert_eq(session.player.gold, 70)
	assert_eq(session.guild_reputation, 40)
	assert_true(session.quest_log.is_completed(QuestServiceClass.STORY_QUEST_ID))
