extends GutTest

const ContractDefinitionClass := preload("res://core/quests/contract_definition.gd")
const ContractObjectiveClass := preload("res://core/quests/contract_objective.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const APP_SCENE := preload("res://scenes/app/app.tscn")
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")


func test_period_keys_use_calendar_day_and_iso_monday_week() -> void:
	assert_eq(ContractServiceClass.weekly_key_for_date("2026-08-09"), "2026-W32")
	assert_eq(ContractServiceClass.weekly_key_for_date("2026-08-10"), "2026-W33")
	assert_eq(ContractServiceClass.weekly_key_for_date("2027-01-01"), "2026-W53")


func test_board_generates_three_dailies_and_one_multiobjective_weekly() -> void:
	var session = _session(12)
	var messages := ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-09", "2026-W32"
	)
	assert_eq(session.contract_board.daily_contracts.size(), 3)
	assert_not_null(session.contract_board.weekly_contract)
	assert_eq(session.contract_board.daily_date, "2026-08-09")
	assert_eq(session.contract_board.weekly_key, "2026-W32")
	assert_eq(messages.size(), 2)
	assert_eq(
		session.contract_board.daily_contracts[0].objectives[0].objective_type,
		ContractObjectiveClass.KILL_ENEMY
	)
	assert_eq(
		session.contract_board.daily_contracts[1].objectives[0].objective_type,
		ContractObjectiveClass.COLLECT
	)
	assert_eq(
		session.contract_board.daily_contracts[2].objectives[0].objective_type,
		ContractObjectiveClass.KILL_ELITE_REGION
	)
	var weekly_types: Array[String] = []
	for objective in session.contract_board.weekly_contract.objectives:
		weekly_types.append(objective.objective_type)
	assert_has(weekly_types, ContractObjectiveClass.KILL_REGION)
	assert_has(weekly_types, ContractObjectiveClass.KILL_ELITE)
	assert_has(weekly_types, ContractObjectiveClass.COMPLETE_DUNGEON)


func test_same_period_is_stable_and_clock_rollback_does_not_reroll() -> void:
	var session = _session(12)
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-11", "2026-W33"
	)
	var first_payload := ContractServiceClass.serialize_board(session.contract_board)
	assert_true(
		(
			ContractServiceClass
			. ensure_board(session.contract_board, session.player, "2026-08-11", "2026-W33")
			. is_empty()
		)
	)
	assert_true(
		(
			ContractServiceClass
			. ensure_board(session.contract_board, session.player, "2026-08-10", "2026-W33")
			. is_empty()
		)
	)
	assert_eq(ContractServiceClass.serialize_board(session.contract_board), first_payload)


func test_next_day_refreshes_daily_but_keeps_weekly_and_discards_old_progress() -> void:
	var session = _session(12)
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-11", "2026-W33"
	)
	var old_daily_id: String = session.contract_board.daily_contracts[0].contract_id
	var weekly_id: String = session.contract_board.weekly_contract.contract_id
	session.contract_board.progress[old_daily_id] = {"0": 1}
	session.contract_board.progress[weekly_id] = {"0": 2}
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-12", "2026-W33"
	)
	assert_false(session.contract_board.progress.has(old_daily_id))
	assert_eq(session.contract_board.progress[weekly_id]["0"], 2)
	assert_eq(session.contract_board.weekly_contract.contract_id, weekly_id)
	assert_ne(session.contract_board.daily_contracts[0].contract_id, old_daily_id)


func test_victory_tracks_enemy_region_and_real_elite_separately() -> void:
	var session = _session(12)
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-09", "2026-W32"
	)
	var hunt = session.contract_board.daily_contracts[0]
	var elite = session.contract_board.daily_contracts[2]
	assert_true(
		(
			ContractServiceClass
			. record_victory(
				session.player, session.contract_board, "wrong_enemy", "twilight_plains"
			)
			. is_empty()
		)
	)
	var hunt_updates := (
		ContractServiceClass
		. record_victory(
			session.player,
			session.contract_board,
			hunt.objectives[0].target_id,
			"twilight_plains",
		)
	)
	assert_eq(hunt_updates.size(), 1)
	assert_eq(hunt_updates[0].contract_id, hunt.contract_id)
	(
		ContractServiceClass
		. record_victory(
			session.player,
			session.contract_board,
			"wolf",
			elite.objectives[0].target_id,
			false,
		)
	)
	assert_eq(
		(
			ContractServiceClass
			. objective_progress(session.player, session.contract_board, elite, 0)[0]
		),
		0,
	)
	(
		ContractServiceClass
		. record_victory(
			session.player,
			session.contract_board,
			"wolf",
			elite.objectives[0].target_id,
			false,
			"furious",
		)
	)
	assert_eq(
		(
			ContractServiceClass
			. objective_progress(session.player, session.contract_board, elite, 0)[0]
		),
		1,
	)


func test_daily_delivery_requires_rank_consumes_items_and_awards_once() -> void:
	var session = _session(12)
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-09", "2026-W32"
	)
	var supply = session.contract_board.daily_contracts[1]
	var objective = supply.objectives[0]
	session.player.inventory.add(objective.target_id, objective.required_count)
	var locked := ContractServiceClass.claim(session, supply.contract_id)
	assert_false(locked.ok)
	assert_string_contains(locked.message, "ranga Gildii E")
	session.guild_reputation = 100
	var gold_before: int = session.player.gold
	var result := ContractServiceClass.claim(session, supply.contract_id)
	assert_true(result.ok, str(result.get("message", "")))
	assert_eq(session.player.inventory.count(objective.target_id), 0)
	assert_eq(session.player.gold, gold_before + supply.reward_gold)
	assert_eq(session.guild_reputation, 115)
	assert_eq(result.guild_reputation, 15)
	assert_false(ContractServiceClass.claim(session, supply.contract_id).ok)


func test_weekly_claim_awards_terminal_reputation_and_item() -> void:
	var session = _session(12)
	session.guild_reputation = 300
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2026-08-09", "2026-W32"
	)
	var weekly = session.contract_board.weekly_contract
	var completed := {}
	for index in weekly.objectives.size():
		completed[str(index)] = weekly.objectives[index].required_count
	session.contract_board.progress[weekly.contract_id] = completed
	var result := ContractServiceClass.claim(session, weekly.contract_id)
	assert_true(result.ok, str(result.get("message", "")))
	assert_eq(session.guild_reputation, 375)
	assert_eq(result.guild_reputation, 75)
	assert_eq(session.player.inventory.count("grandmaster_elixir"), 1)
	assert_true(session.contract_board.weekly_claimed)


func test_current_schema_preserves_board_and_schema_eight_gets_safe_empty_state() -> void:
	var session = _session(12)
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2099-08-09", "2099-W32"
	)
	var contract_id: String = session.contract_board.daily_contracts[0].contract_id
	session.contract_board.progress[contract_id] = {"0": 1}
	var service := SaveGameServiceClass.new("user://stage_five_b_not_written")
	var payload: Dictionary = service._serialize_session(session)
	assert_eq(payload.schema_version, 18)
	var loaded := service._deserialize_payload(payload, 1)
	assert_true(loaded.ok, loaded.message)
	assert_eq(loaded.session.contract_board.daily_date, "2099-08-09")
	assert_eq(loaded.session.contract_board.progress[contract_id]["0"], 1)
	assert_eq(
		loaded.session.contract_board.daily_contracts[0].title,
		session.contract_board.daily_contracts[0].title,
	)

	var legacy := payload.duplicate(true)
	legacy.schema_version = 8
	legacy.session.erase("contracts")
	var migrated := service._deserialize_payload(legacy, 1)
	assert_true(migrated.ok, migrated.message)
	assert_true(migrated.session.contract_board.daily_contracts.is_empty())

	var invalid := payload.duplicate(true)
	invalid.session.contracts.progress[contract_id]["0"] = 999
	var rejected := service._deserialize_payload(invalid, 1)
	assert_false(rejected.ok)
	assert_string_contains(rejected.message, "postęp kontraktu")


func test_guild_placeholder_switches_between_story_daily_and_weekly() -> void:
	var session = _session(12)
	session.guild_reputation = 300
	ContractServiceClass.ensure_board(
		session.contract_board, session.player, "2099-08-09", "2099-W32"
	)
	var screen := GUILD_SCENE.instantiate() as GuildScreenClass
	screen.configure(session)
	add_child_autofree(screen)
	screen.show_daily_contracts()
	assert_eq(screen.quest_list.item_count, 3)
	assert_string_contains(screen.board_title.text, "dzienne")
	assert_string_contains(screen.chapter_label.text, "2099-08-09")
	screen.show_weekly_contract()
	assert_eq(screen.quest_list.item_count, 1)
	assert_string_contains(screen.arc_label.text, "TYGODNIOWY")
	assert_false(screen.dependency_label.visible)
	screen.show_story_board()
	assert_eq(screen.quest_list.item_count, 9)


func test_guild_contract_overlay_fits_full_canvas_without_app_bands_at_720p() -> void:
	var host := Control.new()
	host.size = Vector2(1280, 720)
	add_child(host)
	var app = APP_SCENE.instantiate()
	host.add_child(app)
	var session = _session(12)
	session.prologue_completed = true
	session.guild_reputation = 300
	app._on_session_created(session)
	app._show_guild()
	await get_tree().process_frame
	var guild = app.screen_host.get_child(0)
	guild.show_weekly_contract()
	guild.result_label.text = (
		"Nagroda: +1360 EXP, +780 złota, +75 reputacji Gildii.\n"
		+ "Otrzymano: Eliksir Arcymistrza ×1."
	)
	await get_tree().process_frame
	assert_eq(guild.hall_presentation.size, guild.size)
	assert_true(guild.get_global_rect().encloses(guild.board_body.get_global_rect()))
	assert_lte(guild.result_label.get_global_rect().end.y, guild.get_global_rect().end.y)
	assert_null(app.get_node_or_null("SafeArea/Page/HeaderSeparator"))
	host.free()


func _session(level: int):
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	var session = NewGameServiceClass.new().create_session("Aria", 1, rng)
	session.player.level = level
	return session
