extends GutTest

const AdventureLogClass := preload("res://core/game/adventure_log.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const GuildRumorCatalogClass := preload("res://core/quests/guild_rumor_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const APP_SCENE := preload("res://scenes/app/app.tscn")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")


func test_adventure_log_formats_timestamps_and_keeps_last_fifty_entries() -> void:
	var log := AdventureLogClass.new()
	for index in 55:
		log.add(2, 7, "Wydarzenie %d." % index)

	assert_eq(log.entries.size(), 50)
	assert_eq(log.entries[0], "Dzień 2, 07:00 — Wydarzenie 5.")
	assert_eq(log.entries[-1], "Dzień 2, 07:00 — Wydarzenie 54.")
	assert_eq(log.recent().size(), 30)
	assert_eq(log.recent()[0], "Dzień 2, 07:00 — Wydarzenie 25.")


func test_four_world_milestones_award_exactly_650_reputation_only_once() -> void:
	var session = _session()
	var expected := {
		"boss:azhar": 100,
		"boss:leviathan_north": 150,
		"dungeon:sunken_order_crypt": 150,
		"dungeon:black_fleet_wreck": 250,
	}
	var total := 0
	for milestone_id: String in GuildMilestoneServiceClass.MILESTONE_ORDER:
		var result := GuildMilestoneServiceClass.record(session, milestone_id)
		assert_true(result.ok)
		assert_true(result.awarded)
		assert_eq(result.reputation, expected[milestone_id])
		total += result.reputation

	assert_eq(total, 650)
	assert_eq(session.guild_reputation, 650)
	assert_eq(session.guild_milestones.size(), 4)
	var repeated := GuildMilestoneServiceClass.record(session, "boss:azhar")
	assert_true(repeated.ok)
	assert_false(repeated.awarded)
	assert_eq(session.guild_reputation, 650)
	assert_false(GuildMilestoneServiceClass.record(session, "unknown").ok)


func test_milestone_rank_change_is_written_to_the_adventure_log() -> void:
	var session = _session()
	session.guild_reputation = 50
	var result := GuildMilestoneServiceClass.record(session, "boss:azhar")

	assert_true(result.rank_changed)
	assert_eq(result.old_rank_code, "F")
	assert_eq(result.new_rank_code, "E")
	assert_string_contains(session.adventure_log.entries[-2], "Reputacja Gildii +100")
	assert_string_contains(session.adventure_log.entries[-1], "Awans w Gildii: E — Adept")


func test_rumors_are_filtered_by_rank_market_and_world_milestones() -> void:
	assert_eq(GuildRumorCatalogClass.get_all().size(), 32)
	assert_eq(GuildRumorCatalogClass.available(0, []).size(), 5)
	assert_eq(GuildRumorCatalogClass.available(700, []).size(), 17)
	assert_eq(GuildRumorCatalogClass.available(700, [], true).size(), 19)
	assert_eq(
		GuildRumorCatalogClass.available(700, ["dungeon:black_fleet_wreck"]).size(),
		18,
	)
	assert_eq(
		GuildRumorCatalogClass.available(1400, ["dungeon:black_fleet_wreck"], true).size(),
		27,
	)
	var texts: Array[String] = []
	for rumor in GuildRumorCatalogClass.get_all():
		texts.append(rumor.text)
	assert_false(texts.any(func(value: String) -> bool: return "Golda" in value))
	assert_false(texts.any(func(value: String) -> bool: return "edykt" in value.to_lower()))


func test_current_schema_preserves_milestones_and_journal_and_migrates_schema_nine() -> void:
	var session = _session()
	GuildMilestoneServiceClass.record(session, "boss:azhar")
	session.log_event("Test zapisu Dziennika Przygód.")
	var service := SaveGameServiceClass.new("user://stage_five_c_not_written")
	var payload: Dictionary = service._serialize_session(session)

	assert_eq(payload.schema_version, 12)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.guild_milestones, ["boss:azhar"])
	assert_eq(loaded.session.adventure_log.entries, session.adventure_log.entries)

	var legacy := payload.duplicate(true)
	legacy.schema_version = 9
	legacy.session.erase("guild_milestones")
	legacy.session.erase("adventure_log")
	var migrated := service._deserialize_payload(legacy, 1)
	assert_true(migrated.ok, migrated.message)
	assert_true(migrated.session.guild_milestones.is_empty())
	assert_true(migrated.session.adventure_log.entries.is_empty())


func test_save_rejects_duplicate_milestones_and_oversized_journal() -> void:
	var session = _session()
	var service := SaveGameServiceClass.new("user://stage_five_c_invalid_not_written")
	var payload: Dictionary = service._serialize_session(session)
	payload.session.guild_milestones = ["boss:azhar", "boss:azhar"]
	var duplicate := service._deserialize_payload(payload, 1)
	assert_false(duplicate.ok)
	assert_string_contains(duplicate.message, "powtórzony kamień milowy")

	payload = service._serialize_session(session)
	for index in 51:
		payload.session.adventure_log.append("Wpis %d" % index)
	var oversized := service._deserialize_payload(payload, 1)
	assert_false(oversized.ok)
	assert_string_contains(oversized.message, "przekracza limit")


func test_guild_tabs_and_city_journal_are_navigable_without_terminal() -> void:
	var session = _session()
	var guild = GUILD_SCENE.instantiate()
	guild.configure(session)
	add_child_autofree(guild)
	guild.show_milestones()
	assert_eq(guild.quest_list.item_count, 4)
	assert_string_contains(guild.reward_label.text, "100 reputacji")
	guild.show_rumors()
	assert_eq(guild.quest_list.item_count, 5)
	assert_string_contains(guild.quest_title_label.text, "Zasłyszana plotka")

	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_adventure_log()
	await get_tree().process_frame
	var journal = app.screen_host.get_child(0)
	assert_eq(journal.entry_list.item_count, session.adventure_log.entries.size())
	assert_string_contains(journal.summary_label.text, "/50 zapisanych wydarzeń")


func _session():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return NewGameServiceClass.new().create_session("Aria", 1, rng)
