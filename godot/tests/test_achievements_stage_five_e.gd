extends GutTest

const AchievementCatalogClass := preload("res://core/progression/achievement_catalog.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")
const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const BlackMarketServiceClass := preload("res://core/economy/black_market_service.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const GuildRumorCatalogClass := preload("res://core/quests/guild_rumor_catalog.gd")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const QuestCatalogClass := preload("res://core/quests/quest_catalog.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const UpgradeServiceClass := preload("res://core/economy/upgrade_service.gd")
const ACHIEVEMENTS_SCENE := preload("res://ui/screens/achievements/achievements.tscn")
const APP_SCENE := preload("res://scenes/app/app.tscn")


func test_catalog_matches_all_seven_terminal_achievements_and_titles() -> void:
	assert_eq(AchievementCatalogClass.ORDER.size(), 7)
	assert_eq(AchievementCatalogClass.DEFAULT_TITLE, "Wędrowiec")
	var expected := {
		"first_blood": ["Pierwsza krew", "Łowca"],
		"nature_breaker": ["Pogromca Natury", "Pogromca Natury"],
		"executioners_end": ["Koniec Egzekutora", "Kat Egzekutora"],
		"silence_the_mother": ["Cisza nad Głuchą Wodą", "Ten, Który Uciszył Matkę"],
		"aurora_hunter": ["Pod Zorzą", "Dziecko Zorzy"],
		"master_smith": ["Mistrz Kowadła", "Mistrz Kowadła"],
		"guild_veteran": ["Weteran Gildii", "Weteran Gildii"],
	}
	for achievement_id: String in AchievementCatalogClass.ORDER:
		var definition = AchievementCatalogClass.get_definition(achievement_id)
		assert_eq(definition.display_name, expected[achievement_id][0])
		assert_eq(definition.title, expected[achievement_id][1])
		assert_false(definition.description.is_empty())


func test_victory_unlocks_first_blood_boss_and_aurora_only_once() -> void:
	var session = _session()
	var enemy = EnemyCatalogClass.create_enemy("nature_guardian")
	enemy.weather_code = "aurora"
	var rng := RandomNumberGenerator.new()
	rng.seed = 5
	var result := AdventureServiceClass.resolve_victory(session, enemy, rng)

	assert_eq(result.unlocked_achievements.size(), 3)
	assert_true(session.player.achievement_book.is_unlocked("first_blood"))
	assert_true(session.player.achievement_book.is_unlocked("nature_breaker"))
	assert_true(session.player.achievement_book.is_unlocked("aurora_hunter"))
	assert_eq(
		AchievementServiceClass.record_victory(session, "nature_guardian", "aurora").size(), 0
	)
	assert_string_contains(session.adventure_log.entries[-2], "Odblokowano tytuł")


func test_remaining_bosses_rank_s_and_plus_ten_upgrade_unlock_achievements() -> void:
	var session = _session()
	AchievementServiceClass.record_victory(session, "blackwood_executioner", "sunny")
	AchievementServiceClass.record_victory(session, "drowned_mother", "sunny")
	session.guild_reputation = 4500
	AchievementServiceClass.record_guild_rank(session, "S")

	var item = session.player.equipment.slots.values()[0]
	var plan := UpgradeServiceClass.get_upgrade_plan(item, 10)
	session.player.gold = int(plan.gold)
	for item_id: String in plan.materials:
		session.player.inventory.add(item_id, int(plan.materials[item_id]))
	var upgrade := UpgradeServiceClass.upgrade_item(session.player, item, 10, session)

	assert_true(upgrade.ok, upgrade.message)
	assert_eq(item.upgrade_level, 10)
	assert_eq(upgrade.unlocked_achievements.size(), 1)
	assert_true(session.player.achievement_book.is_unlocked("executioners_end"))
	assert_true(session.player.achievement_book.is_unlocked("silence_the_mother"))
	assert_true(session.player.achievement_book.is_unlocked("guild_veteran"))
	assert_true(session.player.achievement_book.is_unlocked("master_smith"))


func test_titles_can_only_be_equipped_after_unlocking() -> void:
	var session = _session()
	var locked := AchievementServiceClass.equip_title(session, "Dziecko Zorzy")
	assert_false(locked.ok)
	AchievementServiceClass.record_victory(session, "wolf", "sunny")
	var equipped := AchievementServiceClass.equip_title(session, "Łowca")

	assert_true(equipped.ok)
	assert_eq(session.player.achievement_book.equipped_title, "Łowca")
	assert_eq(session.player.titled_display_name(), "[Łowca] Aria")
	assert_eq(session.player.achievement_book.available_titles(), ["Wędrowiec", "Łowca"])


func test_schema_twelve_preserves_achievements_and_migrates_schema_eleven() -> void:
	var session = _session()
	AchievementServiceClass.record_victory(session, "wolf", "sunny")
	AchievementServiceClass.equip_title(session, "Łowca")
	var service := SaveGameServiceClass.new("user://stage_five_e_not_written")
	var payload: Dictionary = service._serialize_session(session)

	assert_eq(payload.schema_version, 18)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.player.achievement_book.unlocked_ids, ["first_blood"])
	assert_eq(loaded.session.player.achievement_book.equipped_title, "Łowca")

	var legacy := payload.duplicate(true)
	legacy.schema_version = 11
	legacy.session.player.erase("achievements")
	var migrated := service._deserialize_payload(legacy, 1)
	assert_true(migrated.ok, migrated.message)
	assert_true(migrated.session.player.achievement_book.unlocked_ids.is_empty())
	assert_eq(
		migrated.session.player.achievement_book.equipped_title,
		AchievementCatalogClass.DEFAULT_TITLE,
	)


func test_save_rejects_unknown_duplicate_and_locked_achievement_titles() -> void:
	var service := SaveGameServiceClass.new("user://stage_five_e_invalid_not_written")
	var payload: Dictionary = service._serialize_session(_session())
	payload.session.player.achievements.unlocked = ["unknown"]
	var unknown := service._deserialize_payload(payload, 1)
	assert_false(unknown.ok)
	assert_string_contains(unknown.message, "nieznane albo powtórzone")

	payload = service._serialize_session(_session())
	payload.session.player.achievements.unlocked = ["first_blood", "first_blood"]
	assert_false(service._deserialize_payload(payload, 1).ok)

	payload = service._serialize_session(_session())
	payload.session.player.achievements.equipped_title = "Łowca"
	var locked := service._deserialize_payload(payload, 1)
	assert_false(locked.ok)
	assert_string_contains(locked.message, "nie został odblokowany")


func test_achievement_screen_and_app_route_work_without_terminal() -> void:
	var session = _session()
	AchievementServiceClass.record_victory(session, "wolf", "sunny")
	var screen = ACHIEVEMENTS_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_eq(screen.achievement_list.item_count, 7)
	assert_eq(screen.title_selector.item_count, 2)
	assert_string_contains(screen.summary_label.text, "1/7 osiągnięć")
	screen.title_selector.select(1)
	screen.title_selector.item_selected.emit(1)
	screen.equip_button.pressed.emit()
	assert_eq(session.player.achievement_book.equipped_title, "Łowca")

	var app = APP_SCENE.instantiate()
	add_child_autofree(app)
	session.prologue_completed = true
	app._on_session_created(session)
	app._show_achievements()
	await get_tree().process_frame
	assert_eq(app.screen_host.get_child(0).achievement_list.item_count, 7)


func test_final_guild_audit_matches_terminal_values_and_stage_five_scope() -> void:
	var rank_codes: Array[String] = []
	var thresholds: Array[int] = []
	for rank: Dictionary in GuildProgressionServiceClass.RANKS:
		rank_codes.append(rank.code)
		thresholds.append(rank.reputation)
	assert_eq(rank_codes, ["F", "E", "D", "C", "B", "A", "S"])
	assert_eq(thresholds, [0, 100, 300, 700, 1400, 2600, 4500])

	var story_reputation := 0
	for quest in QuestCatalogClass.get_all_definitions():
		story_reputation += quest.guild_reputation
	var milestone_reputation := 0
	for milestone in GuildMilestoneServiceClass.get_all():
		milestone_reputation += milestone.reputation
	assert_eq(QuestCatalogClass.get_all_definitions().size(), 9)
	assert_eq(story_reputation, 700)
	assert_eq(ContractServiceClass.DAILY_REPUTATION, 15)
	assert_eq(ContractServiceClass.WEEKLY_REPUTATION, 75)
	assert_eq(milestone_reputation, 650)
	assert_eq(GuildRumorCatalogClass.get_all().size(), 32)
	assert_eq(BlackMarketServiceClass.CONTACT_RANK, "C")
	assert_eq(BlackMarketServiceClass.REQUIRED_DUNGEON_MILESTONES.size(), 2)
	assert_eq(BlackMarketServiceClass.OFFER_COUNT, 4)
	assert_eq(AchievementCatalogClass.get_all().size(), 7)


func _session():
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	return NewGameServiceClass.new().create_session("Aria", 1, rng)
