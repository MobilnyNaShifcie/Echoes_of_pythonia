extends GutTest

const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const QuestCatalogClass := preload("res://core/quests/quest_catalog.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")


func test_act_one_catalog_has_nine_ordered_quests_and_700_reputation() -> void:
	var quests := QuestServiceClass.get_all_story_quests()
	var total_reputation := 0
	for quest in quests:
		total_reputation += quest.guild_reputation

	assert_eq(quests.size(), 9)
	assert_eq(quests[0].quest_id, "awakening_missing_recruits")
	assert_eq(quests[-1].quest_id, "awakening_last_order")
	assert_eq(total_reputation, 700)
	assert_true(
		quests.all(func(quest) -> bool: return quest.story_arc == "Akt I — Ślady Przebudzenia")
	)
	assert_string_contains(quests[5].dependency_note, "Krypta")
	assert_string_contains(quests[8].dependency_note, "Czarnej Floty")


func test_story_availability_requires_level_and_previous_chapter() -> void:
	var session = _session()
	var level_zero := QuestServiceClass.get_available_quests(
		session.quest_log, session.player.level
	)
	assert_eq(level_zero.size(), 1)
	assert_eq(level_zero[0].quest_id, QuestServiceClass.STORY_QUEST_ID)

	session.quest_log.completed[QuestServiceClass.STORY_QUEST_ID] = true
	assert_true(QuestServiceClass.get_available_quests(session.quest_log, 1).is_empty())
	session.player.level = 2
	var level_two := QuestServiceClass.get_available_quests(session.quest_log, session.player.level)
	assert_eq(level_two.size(), 1)
	assert_eq(level_two[0].quest_id, "awakening_black_wax")


func test_generic_kill_quest_tracks_combat_and_grants_its_exact_reward() -> void:
	var session = _session()
	session.player.level = 2
	session.quest_log.completed[QuestServiceClass.STORY_QUEST_ID] = true
	assert_true(
		(
			QuestServiceClass
			. accept_quest(session.quest_log, "awakening_black_wax", session.player.level)
			. ok
		)
	)
	assert_true(QuestServiceClass.record_enemy_kill(session.quest_log, "wolf").is_empty())
	assert_eq(
		QuestServiceClass.record_enemy_kill(session.quest_log, "forest_cultist").current,
		1,
	)
	assert_eq(
		QuestServiceClass.record_enemy_kill(session.quest_log, "forest_cultist").current,
		2,
	)

	var result := QuestServiceClass.turn_in_quest(session, "awakening_black_wax")
	assert_true(result.ok, str(result.get("message", "")))
	assert_eq(result.experience, 100)
	assert_eq(result.gold, 150)
	assert_eq(result.guild_reputation, 50)
	assert_eq(session.guild_reputation, 50)
	assert_true(session.quest_log.is_completed("awakening_black_wax"))


func test_collect_quest_reads_inventory_and_consumes_ordinary_evidence() -> void:
	var session = _session()
	session.player.level = 4
	session.quest_log.completed["awakening_missing_recruits"] = true
	session.quest_log.completed["awakening_black_wax"] = true
	assert_true(
		(
			QuestServiceClass
			. accept_quest(session.quest_log, "awakening_voice_beneath_roots", session.player.level)
			. ok
		)
	)
	session.player.inventory.add("blackwood_heart")
	var quest := QuestServiceClass.get_quest("awakening_voice_beneath_roots")
	assert_eq(
		QuestServiceClass.objective_progress(session.player, session.quest_log, quest),
		1,
	)

	var result := QuestServiceClass.turn_in_quest(session, "awakening_voice_beneath_roots")
	assert_true(result.ok, str(result.get("message", "")))
	assert_eq(session.player.inventory.count("blackwood_heart"), 0)
	assert_string_contains(result.completion_text, "Przebudzenie")


func test_late_story_trophy_is_examined_without_being_consumed() -> void:
	var session = _session()
	session.player.level = 12
	for quest_id: String in QuestCatalogClass.ACT_ONE_ORDER.slice(0, 6):
		session.quest_log.completed[quest_id] = true
	session.player.inventory.add("azhar_sigil")
	assert_true(
		(
			QuestServiceClass
			. accept_quest(session.quest_log, "awakening_ash_remembers", session.player.level)
			. ok
		)
	)

	var result := QuestServiceClass.turn_in_quest(session, "awakening_ash_remembers")
	assert_true(result.ok, str(result.get("message", "")))
	assert_eq(session.player.inventory.count("azhar_sigil"), 1)


func test_all_seven_terminal_guild_ranks_use_exact_thresholds() -> void:
	var expected := {0: "F", 99: "F", 100: "E", 300: "D", 700: "C", 1400: "B", 2600: "A", 4500: "S"}
	for reputation: int in expected:
		assert_eq(
			GuildProgressionServiceClass.rank_for_reputation(reputation).code,
			expected[reputation],
		)
	assert_true(GuildProgressionServiceClass.has_rank(700, "C"))
	assert_false(GuildProgressionServiceClass.has_rank(699, "C"))
	assert_eq(
		GuildProgressionServiceClass.rank_for_reputation(700).display_name,
		"Zdobywca",
	)


func test_all_act_one_quest_states_survive_current_save_schema() -> void:
	var session = _session()
	session.player.level = 2
	session.quest_log.completed[QuestServiceClass.STORY_QUEST_ID] = true
	session.quest_log.active["awakening_black_wax"] = 1
	var service := SaveGameServiceClass.new("user://stage_five_a_not_written")
	var payload: Dictionary = service._serialize_session(session)

	assert_eq(payload.schema_version, 13)
	var result := service._deserialize_payload(payload, 1)
	assert_true(result.ok, result.message)
	assert_true(result.session.quest_log.is_completed(QuestServiceClass.STORY_QUEST_ID))
	assert_eq(result.session.quest_log.active["awakening_black_wax"], 1)

	var invalid_payload := payload.duplicate(true)
	invalid_payload.session.quest_log.completed.erase(QuestServiceClass.STORY_QUEST_ID)
	var invalid := service._deserialize_payload(invalid_payload, 1)
	assert_false(invalid.ok)
	assert_string_contains(invalid.message, "omija wymagany rozdział")


func test_guild_screen_lists_every_chapter_and_exposes_real_rank() -> void:
	var session = _session()
	session.guild_reputation = 700
	var screen := GUILD_SCENE.instantiate() as GuildScreenClass
	screen.configure(session)
	add_child_autofree(screen)

	assert_eq(screen.quest_list.item_count, 9)
	assert_eq(screen.rank_label.text, "RANGA C — ZDOBYWCA")
	assert_string_contains(screen.rank_progress_label.text, "700/1400")
	assert_false(screen.action_button.disabled)
	screen.action_button.pressed.emit()
	assert_true(session.quest_log.is_active(QuestServiceClass.STORY_QUEST_ID))
	assert_string_contains(screen.result_label.text, "Przyjęto zadanie")


func test_world_and_city_placeholders_show_generic_quest_and_dynamic_rank() -> void:
	var session = _session()
	session.player.level = 2
	session.guild_reputation = 100
	session.quest_log.completed[QuestServiceClass.STORY_QUEST_ID] = true
	session.quest_log.active["awakening_black_wax"] = 1
	var world := WORLD_MAP_SCENE.instantiate() as WorldMapScreenClass
	world.configure(session)
	add_child_autofree(world)
	assert_string_contains(world.quest_label.text, "Czarny wosk")
	assert_string_contains(world.quest_label.text, "1/2")

	var city := CITY_HUB_SCENE.instantiate() as CityHubScreenClass
	city.configure(session)
	add_child_autofree(city)
	assert_string_contains(city.player_label.text, "Gildia E (100)")


func _session():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return NewGameServiceClass.new().create_session("Aria", 1, rng)
