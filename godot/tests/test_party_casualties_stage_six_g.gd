extends GutTest

const CompanionCasualtyServiceClass := preload(
	"res://core/companions/companion_casualty_service.gd"
)
const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionEquipmentServiceClass := preload(
	"res://core/companions/companion_equipment_service.gd"
)
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const EnemyClass := preload("res://core/combat/enemy.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const PartyCombatRoundResultClass := preload("res://core/combat/party_combat_round_result.gd")
const PartySaveCodecClass := preload("res://core/save/party_save_codec.gd")
const PartyStateClass := preload("res://core/companions/party_state.gd")
const PlayerFactoryClass := preload("res://core/player/player_factory.gd")

const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")


func test_only_a_high_rift_boss_marks_a_companion_for_execution() -> void:
	var cases := [
		["boss", "B", true],
		["boss", "A", true],
		["boss", "S", true],
		["boss", "C", false],
		["normal", "S", false],
	]
	for index in cases.size():
		var values: Array = cases[index]
		var combat := _combat(values[0], values[1], index + 1)
		var fighter = combat.companion_fighters[0]
		fighter.profile.stats.current_hp = 0
		var report := PartyCombatRoundResultClass.new()

		combat._down_fighter(fighter, report)

		assert_eq(fighter.lethal_downed, values[2], "%s/%s" % [values[0], values[1]])
		assert_eq(fighter.downed_timer, 3 if values[2] else 4)
		assert_eq(report.killed, [])

	var player_combat := _combat("boss", "S", 20)
	player_combat.player_fighter.profile.stats.current_hp = 0
	player_combat._down_fighter(player_combat.player_fighter, PartyCombatRoundResultClass.new())
	assert_false(player_combat.player_fighter.lethal_downed)
	assert_eq(player_combat.player_fighter.downed_timer, 4)


func test_enemy_attack_announces_execution_before_any_permanent_result() -> void:
	var combat := _combat("boss", "B", 31, 999)
	combat.taunt_companion_id = "ally"

	var report = combat.player_basic_attack()

	assert_eq(report.enemy_target_ids, ["ally"])
	assert_eq(report.downed_timers["ally"], 2)
	assert_eq(report.lethal_downed_ids, ["ally"])
	assert_true(report.killed.is_empty())
	assert_true(report.lines.any(func(line: String) -> bool: return "EGZEKUCJĘ" in line))
	assert_true(
		report.lines.any(func(line: String) -> bool: return "masz 3 rundy na reakcję" in line)
	)


func test_execution_countdown_is_deterministic_and_never_rolls_rng() -> void:
	var combat := _combat("boss", "S", 41)
	var fighter = combat.companion_fighters[0]
	fighter.profile.stats.current_hp = 0
	var report := PartyCombatRoundResultClass.new()
	var rng_state_before: int = combat.rng.state

	combat._down_fighter(fighter, report)
	combat._tick_downed(report)
	combat._tick_downed(report)
	assert_true(report.killed.is_empty())
	combat._tick_downed(report)

	assert_eq(combat.rng.state, rng_state_before)
	assert_true(fighter.removed)
	assert_eq(report.killed, ["ally"])
	assert_true(report.critically_injured.is_empty())
	assert_true(report.lines.any(func(line: String) -> bool: return "ginie" in line))


func test_player_help_cancels_execution_and_restores_twenty_eight_percent() -> void:
	var combat := _combat("boss", "B", 51, 0)
	var fighter = combat.companion_fighters[0]
	fighter.profile.stats.current_hp = 0
	var setup := PartyCombatRoundResultClass.new()
	combat._down_fighter(fighter, setup)
	var expected_hp := maxi(1, roundi(fighter.profile.stats.max_hp * 0.28))

	var report = combat.player_help("ally")

	assert_true(report.turn_consumed)
	assert_eq(report.rescue_actor_ids, ["player"])
	assert_eq(report.rescued_fighter_ids, ["ally"])
	assert_false(fighter.lethal_downed)
	assert_eq(fighter.downed_timer, 0)
	assert_gt(fighter.profile.stats.current_hp, 0)
	assert_lte(fighter.profile.stats.current_hp, expected_hp)
	assert_true(report.killed.is_empty())


func test_finishing_battle_interrupts_announced_execution() -> void:
	var combat := _combat("boss", "A", 61)
	var fighter = combat.companion_fighters[0]
	fighter.profile.stats.current_hp = 0
	combat._down_fighter(fighter, PartyCombatRoundResultClass.new())
	combat.enemy.current_hp = 1

	var report = combat.player_basic_attack()

	assert_true(report.victory)
	assert_eq(fighter.downed_timer, 3)
	assert_true(report.killed.is_empty())


func test_normal_countdown_creates_heavy_injury_not_death() -> void:
	var combat := _combat("normal", "S", 71)
	var fighter = combat.companion_fighters[0]
	fighter.profile.stats.current_hp = 0
	var report := PartyCombatRoundResultClass.new()
	combat._down_fighter(fighter, report)

	for _round in 4:
		combat._tick_downed(report)

	assert_true(fighter.removed)
	assert_eq(report.critically_injured, ["ally"])
	assert_true(report.killed.is_empty())
	assert_false(fighter.lethal_downed)


func test_first_standing_companion_rescues_downed_player_instead_of_attacking() -> void:
	var first := _companion("first", "warrior")
	var second := _companion("second", "hunter")
	var player = _player()
	var combat := PartyCombatEngineClass.new(
		player, [first, second], _enemy("normal", 500, 0), _rng(81), 1.0, "B"
	)
	player.stats.current_hp = 0
	combat._down_fighter(combat.player_fighter, PartyCombatRoundResultClass.new())
	var expected_hp := maxi(1, roundi(player.stats.max_hp * 0.25))
	var report := PartyCombatRoundResultClass.new()

	combat._companion_turns(report)

	assert_eq(player.stats.current_hp, expected_hp)
	assert_eq(combat.player_fighter.downed_timer, 0)
	assert_eq(report.rescue_actor_ids, ["first"])
	assert_eq(report.rescued_fighter_ids, ["player"])
	assert_eq(report.companion_action_order, ["second"])


func test_downed_player_action_only_waits_for_rescue_and_never_attacks() -> void:
	var combat := _combat("normal", "B", 86, 0)
	combat.player_fighter.profile.stats.current_hp = 0
	combat._down_fighter(combat.player_fighter, PartyCombatRoundResultClass.new())
	var enemy_hp_before: int = combat.enemy.current_hp

	var report = combat.player_basic_attack()

	assert_true(report.turn_consumed)
	assert_eq(report.rescue_actor_ids, ["ally"])
	assert_eq(report.rescued_fighter_ids, ["player"])
	assert_true(report.companion_action_order.is_empty())
	assert_eq(combat.enemy.current_hp, enemy_hp_before)
	assert_false(report.lines.any(func(line: String) -> bool: return "Dowódca atakuje" in line))


func test_heavy_injury_is_applied_outside_combat_with_injected_duration_rng() -> void:
	var party := PartyStateClass.new()
	var companion := _companion("injured", "warrior")
	companion.active = true
	party.companions.append(companion)
	var report := PartyCombatRoundResultClass.new()
	report.critically_injured.append(companion.companion_id)
	var expected_rng := _rng(91)
	var expected_days := expected_rng.randi_range(2, 5)

	var result := CompanionCasualtyServiceClass.apply_round_result(
		party, _player(), report, 10, "Wilk", "C", _rng(91)
	)

	assert_true(result.ok)
	assert_true(result.changed)
	assert_false(companion.active)
	assert_eq(companion.current_hp, 1)
	assert_eq(companion.injury_until_day, 10 + expected_days)
	assert_eq(party.messages.size(), 1)
	assert_string_contains(party.messages[0].text, "Powrót do sił")
	assert_false("rekonwalescenc" in party.messages[0].text.to_lower())
	assert_false(companion.dead)


func test_execution_returns_player_gear_writes_memorial_and_does_not_use_rng() -> void:
	var party := PartyStateClass.new()
	var victim := _companion("victim", "warrior")
	var survivor := _companion("survivor", "hunter")
	victim.active = true
	survivor.active = true
	party.companions.assign([victim, survivor])
	var player = _player()
	var personal = ItemCatalogClass.create_equipment_item("starter_sword", _rng(101))
	var borrowed = ItemCatalogClass.create_equipment_item("worn_leather_armor", _rng(102))
	victim.equipment.equip_and_return_previous(personal)
	victim.personal_instance_ids.append(personal.instance_id)
	player.inventory.add_equipment_instance(borrowed)
	assert_true(CompanionEquipmentServiceClass.equip_player_item(player, victim, 0).ok)
	var report := PartyCombatRoundResultClass.new()
	report.killed.append(victim.companion_id)
	var casualty_rng := _rng(103)
	var rng_state_before: int = casualty_rng.state

	var result := CompanionCasualtyServiceClass.apply_round_result(
		party, player, report, 12, "Strażnik Szczeliny", "B", casualty_rng
	)

	assert_true(result.ok)
	assert_eq(casualty_rng.state, rng_state_before)
	assert_true(victim.dead)
	assert_false(victim.active)
	assert_null(party.companion_by_id(victim.companion_id))
	assert_eq(party.fallen.size(), 1)
	assert_eq(party.fallen[0].rift_rank, "B")
	assert_string_contains(party.fallen[0].cause, "Egzekucja Strażnik Szczeliny")
	assert_eq(player.inventory.equipment_items.size(), 1)
	assert_eq(player.inventory.equipment_items[0].instance_id, borrowed.instance_id)
	assert_eq(result.returned_items[0].instance_id, borrowed.instance_id)
	assert_eq(party.messages.size(), 1)
	assert_string_contains(party.messages[0].text, "Mieliśmy czas zareagować")

	var repeated := CompanionCasualtyServiceClass.apply_round_result(
		party, player, report, 12, "Strażnik Szczeliny", "B", casualty_rng
	)
	assert_true(repeated.ok)
	assert_false(repeated.changed)
	assert_eq(party.fallen.size(), 1)


func test_injury_recovery_and_fallen_board_survive_save_load() -> void:
	var party := PartyStateClass.new()
	var injured := _companion("injured-save", "mage")
	injured.injury_until_day = 8
	injured.current_hp = 1
	party.companions.append(injured)
	var report := PartyCombatRoundResultClass.new()
	var victim := _companion("fallen-save", "hunter")
	party.companions.append(victim)
	report.killed.append(victim.companion_id)
	assert_true(
		(
			CompanionCasualtyServiceClass
			. apply_round_result(party, _player(), report, 4, "Władca Echa", "A", _rng(111))
			. ok
		)
	)

	var loaded := PartySaveCodecClass.deserialize(PartySaveCodecClass.serialize(party), 4)

	assert_true(loaded.ok, loaded.get("message", ""))
	assert_eq(loaded.party.companions[0].injury_until_day, 8)
	assert_eq(loaded.party.companions[0].current_hp, 1)
	assert_eq(loaded.party.fallen.size(), 1)
	assert_eq(loaded.party.fallen[0].display_name, victim.display_name)
	assert_eq(loaded.party.fallen[0].rift_rank, "A")
	assert_eq(CompanionCasualtyServiceClass.refresh_injuries(loaded.party, 7), [])
	assert_eq(
		CompanionCasualtyServiceClass.refresh_injuries(loaded.party, 8),
		[injured.display_name],
	)
	assert_eq(loaded.party.companions[0].injury_until_day, 0)


func test_existing_party_hub_displays_the_fallen_board() -> void:
	var party := PartyStateClass.new()
	var victim := _companion("hub-fallen", "pierrot")
	party.companions.append(victim)
	var report := PartyCombatRoundResultClass.new()
	report.killed.append(victim.companion_id)
	assert_true(
		(
			CompanionCasualtyServiceClass
			. apply_round_result(party, _player(), report, 6, "Arbiter", "S", _rng(121))
			. ok
		)
	)
	var session = preload("res://core/game/game_session.gd").new(1, _player())
	session.party = party
	var screen = PARTY_HUB_SCENE.instantiate()
	screen.configure(session)
	add_child_autofree(screen)
	await get_tree().process_frame

	assert_eq(screen.tabs.get_tab_title(3), "Tablica Poległych")
	assert_eq(screen.fallen_list.item_count, 1)
	assert_string_contains(screen.fallen_detail_label.text, victim.display_name)
	assert_string_contains(screen.fallen_detail_label.text, "Szczelina rangi S")


func _combat(
	rank: String, rift_rank: String, seed_value: int, enemy_attack := 1
) -> PartyCombatEngineClass:
	return (
		PartyCombatEngineClass
		. new(
			_player(),
			[_companion("ally", "hunter")],
			_enemy(rank, 1000, enemy_attack),
			_rng(seed_value),
			1.0,
			rift_rank,
		)
	)


func _player():
	var player = PlayerFactoryClass.create_player("Dowódca")
	player.level = 12
	player.character_class_code = "warrior"
	player.attributes.strength = 6
	player.attributes.endurance = 4
	player.recalculate_stats()
	player.stats.restore_full()
	return player


func _companion(companion_id: String, class_code: String) -> CompanionStateClass:
	var template_id: String = str(
		(
			{
				"warrior": "kael",
				"hunter": "nessa",
				"mage": "elyra",
				"pierrot": "mira",
			}
			. get(class_code, "kael")
		)
	)
	var definition = CompanionCatalogClass.get_definition(template_id)
	var companion := CompanionStateClass.new(
		companion_id, template_id, definition.display_name, class_code
	)
	companion.level = 12
	companion.attributes.strength = 6
	companion.attributes.intelligence = 4
	companion.attributes.endurance = 4
	companion.current_hp = 20
	companion.current_mana = 20
	return companion


func _enemy(rank: String, max_hp: int, attack: int) -> EnemyClass:
	return (
		EnemyClass
		. new(
			{
				"enemy_id": "stage-six-g-enemy",
				"display_name": "Strażnik Szczeliny",
				"max_hp": max_hp,
				"attack": attack,
				"defense": 0,
				"dodge": 0.0,
				"rank": rank,
			}
		)
	)


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng
