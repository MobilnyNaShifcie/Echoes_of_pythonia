class_name DungeonService
extends RefCounted

# Player-facing domain messages are kept whole for parity with the terminal flow.
# gdlint: disable=max-line-length

const AdmiralVarekCombatEngineClass := preload("res://core/combat/admiral_varek_combat_engine.gd")
const GrandMasterCombatEngineClass := preload("res://core/combat/grandmaster_combat_engine.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const DungeonCatalogClass := preload("res://core/dungeons/dungeon_catalog.gd")
const DungeonRunStateClass := preload("res://core/dungeons/dungeon_run_state.gd")
const EquipmentAffixServiceClass := preload("res://core/items/equipment_affix_service.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const MathClass := preload("res://core/math/legacy_math.gd")

const COMBAT_RESULT_VICTORY := "victory"
const COMBAT_RESULT_DEFEAT := "defeat"
const COMBAT_RESULT_FLED := "fled"


static func start(session, dungeon_id: String, _rng: RandomNumberGenerator) -> Dictionary:
	var dungeon = DungeonCatalogClass.get_definition(dungeon_id)
	if dungeon == null:
		return _error("Nieznany loch.")
	if session == null or session.player == null:
		return _error("Nie można rozpocząć lochu bez bohatera.")
	if not session.party.active_companions(session.day).is_empty():
		return _error(
			"Te dwa lochy zachowują terminalowy tryb SOLO. Ustaw skład SOLO przed wejściem."
		)
	if not session.player.inventory.has(dungeon.entry_item_id, dungeon.entry_item_quantity):
		var key = ItemCatalogClass.get_definition(dungeon.entry_item_id)
		return _error(
			(
				"Potrzebujesz: %s ×%d. Źródła: %s"
				% [key.display_name, dungeon.entry_item_quantity, dungeon.entry_source_text]
			)
		)
	ContractServiceClass.ensure_board(session.contract_board, session.player)
	if not session.player.inventory.remove_item(dungeon.entry_item_id, dungeon.entry_item_quantity):
		return _error("Nie udało się atomowo zużyć wejściówki.")
	var run := DungeonRunStateClass.new(dungeon_id)
	run.step = "room_one"
	run.snapshot_stacks = session.player.inventory.stacks.duplicate(true)
	for item in session.player.inventory.equipment_items:
		run.snapshot_equipment_ids.append(item.instance_id)
	session.current_location_id = dungeon.region_id
	var key_name: String = ItemCatalogClass.get_definition(dungeon.entry_item_id).display_name
	session.log_event("Zużyto wejściówkę do %s: %s." % [dungeon.display_name, key_name])
	session.log_event("Rozpoczęto loch SOLO: %s." % dungeon.display_name)
	run.last_message = str(dungeon.scenes.get("entrance", "Wejście zostało otwarte."))
	return {"ok": true, "run": run, "message": run.last_message}


static func choose(
	run: DungeonRunStateClass, session, action: String, rng: RandomNumberGenerator
) -> Dictionary:
	if run == null or run.is_finished():
		return _error("Ta wyprawa już się zakończyła.")
	if run.step == "in_combat":
		return _error("Najpierw zakończ bieżące starcie.")
	if action == "retreat":
		return _finish_retreat(run, session)
	var dungeon = DungeonCatalogClass.get_definition(run.dungeon_id)
	match run.step:
		"room_one":
			if action == "begin":
				return _begin_random_encounter(
					run,
					dungeon.room_one_enemies,
					str(dungeon.scenes.room_one_title),
					"pause_after_room_one",
					rng,
				)
		"pause_after_room_one":
			if action == "continue":
				return _begin_random_encounter(
					run,
					dungeon.room_two_enemies,
					str(dungeon.scenes.room_two_title),
					"pause_after_room_two",
					rng,
				)
		"pause_after_room_two":
			if action == "continue":
				run.step = "crossroads"
				run.last_message = "Przed tobą znajdują się dwie drogi."
				return _ok(run.last_message)
		"crossroads":
			return _choose_crossroads(run, session, dungeon, action, rng)
		"flooded_chest":
			if action == "continue":
				if run.branch_ambush_pending:
					run.branch_ambush_pending = false
					return _begin_encounter(
						run,
						dungeon.flooded_ambush_enemy,
						"Zalany Korytarz — ZASADZKA",
						"pause_after_path",
					)
				run.step = "pause_after_path"
				return _ok("Woda pozostaje nieruchoma. Droga dalej jest otwarta.")
		"upper_deck":
			if action == "continue":
				return _begin_encounter(
					run,
					dungeon.flooded_ambush_enemy,
					"Górny Pokład — OSTRZAŁ",
					"pause_after_path",
				)
		"cargo_boatswain":
			if action == "continue":
				return _begin_encounter(
					run,
					dungeon.iron_path_enemy,
					"Ładownia — BOSMAN CZARNEJ FLOTY",
					"cargo_treasure",
				)
		"cargo_treasure":
			if action == "claim_treasure":
				session.advance_hours(1, rng)
				var chest := _roll_chest(session, dungeon, rng)
				run.step = "pause_after_path"
				run.last_message = "Skarbiec Czarnej Floty: %s" % _format_loot(chest)
				return _ok(run.last_message)
		"pause_after_path":
			if action == "continue":
				return _begin_random_encounter(
					run,
					dungeon.room_three_enemies,
					str(dungeon.scenes.room_three_title),
					"recovery",
					rng,
				)
		"recovery":
			if action in ["recover", "skip_recovery"]:
				return _resolve_recovery(run, session, dungeon, action == "recover")
		"pause_after_recovery":
			if action == "continue":
				return _begin_encounter(
					run,
					dungeon.mandatory_elite_enemy,
					str(dungeon.scenes.elite_title),
					"final_gate",
				)
		"final_gate":
			if action == "continue":
				return _begin_encounter(
					run,
					dungeon.boss_enemy,
					"%s — FINAŁ" % dungeon.display_name,
					"completed",
				)
	return _error("Ta decyzja nie jest dostępna w bieżącej komnacie.")


static func resolve_combat(
	run: DungeonRunStateClass, session, result: String, rng: RandomNumberGenerator
) -> Dictionary:
	if run == null or run.step != "in_combat":
		return _error("Loch nie oczekuje na wynik walki.")
	var dungeon = DungeonCatalogClass.get_definition(run.dungeon_id)
	var enemy_id := run.pending_enemy_id
	session.camp_rest_available = true
	session.advance_hours(1, rng)
	if result == COMBAT_RESULT_DEFEAT:
		return _finish_defeat(run, session)
	if result == COMBAT_RESULT_FLED:
		return _finish_retreat(run, session)
	if result != COMBAT_RESULT_VICTORY:
		return _error("Nieznany wynik walki.")
	var next_step := run.pending_next_step
	run.pending_enemy_id = ""
	run.pending_battle_title = ""
	run.pending_next_step = ""
	if next_step == "completed":
		return _finish_completed(run, session, dungeon)
	run.step = next_step
	run.last_message = "Pokonano: %s. PŻ i Mana nie zostały odnowione." % enemy_id
	return _ok(run.last_message)


static func view(run: DungeonRunStateClass, session) -> Dictionary:
	var dungeon = DungeonCatalogClass.get_definition(run.dungeon_id)
	var result := {
		"title": dungeon.display_name,
		"eyebrow": "LOCH SOLO  •  ZALECANY POZIOM %s" % dungeon.recommended_level_text(),
		"description": dungeon.description,
		"message": run.last_message,
		"actions": [],
		"finished": run.is_finished(),
		"outcome": run.outcome,
		"loot": run.last_loot,
		"resources": _resource_text(session),
	}
	if run.is_finished():
		result.actions = [{"id": "exit", "label": "Wróć na mapę świata"}]
		return result
	match run.step:
		"room_one":
			result.title = str(dungeon.scenes.room_one_title)
			result.description = str(dungeon.scenes.room_one)
			result.actions = [{"id": "begin", "label": "Rozpocznij starcie"}, _retreat()]
		"pause_after_room_one":
			result.title = "Chwila ciszy"
			result.description = "Droga dalej jest otwarta. Możesz naciskać naprzód albo zabezpieczyć zdobyty łup."
			result.actions = [_continue(), _retreat()]
		"pause_after_room_two":
			result.title = "Chwila ciszy"
			result.description = "Przed tobą rozgałęzia się dalsza droga przez loch."
			result.actions = [_continue(), _retreat()]
		"crossroads":
			result = _crossroads_view(result, dungeon.dungeon_id)
		"flooded_chest":
			result.title = "Zatopiona Skrzynia"
			result.description = ("Stara skrzynia ustępuje pod naciskiem. Woda wokół niej może skrywać zasadzkę.")
			result.actions = [_continue(), _retreat()]
		"upper_deck":
			result.title = "Górny Pokład"
			result.description = str(dungeon.scenes.upper_deck)
			result.actions = [{"id": "continue", "label": "Przebij się przez ostrzał"}, _retreat()]
		"cargo_boatswain":
			result.title = "Zalana Ładownia"
			result.description = "Za pokonanym strażnikiem czeka Bosman Czarnej Floty."
			result.actions = [{"id": "continue", "label": "Staw czoła Bosmanowi"}, _retreat()]
		"cargo_treasure":
			result.title = "Skarbiec Czarnej Floty"
			result.description = "Ciężkie drzwi skarbca ustępują z jękiem."
			result.actions = [
				{"id": "claim_treasure", "label": "Przeszukaj skarbiec  •  +1 godzina"}, _retreat()
			]
		"pause_after_path":
			result.title = "Chwila ciszy"
			result.description = "Obie drogi znów łączą się przed głębszą częścią lochu."
			result.actions = [_continue(), _retreat()]
		"recovery":
			result.title = str(dungeon.scenes.recovery_title)
			result.description = str(dungeon.scenes.recovery)
			var percent := 25 if dungeon.dungeon_id == "sunken_order_crypt" else 30
			result.actions = [
				{"id": "recover", "label": "Odzyskaj %d%% maks. PŻ i Many" % percent},
				{"id": "skip_recovery", "label": "Zostaw miejsce odpoczynku"},
			]
		"pause_after_recovery":
			result.title = str(dungeon.scenes.elite_title)
			result.description = str(
				dungeon.scenes.get("elite", "Ostatni strażnik zagradza drogę do władcy lochu.")
			)
			result.actions = [_continue(), _retreat()]
		"final_gate":
			result.title = str(dungeon.scenes.final_title)
			result.description = str(dungeon.scenes.final)
			if dungeon.scenes.has("boss"):
				result.description += "\n\n" + str(dungeon.scenes.boss)
			result.actions = [{"id": "continue", "label": "Wejdź do finałowej walki"}, _retreat()]
	return result


static func entrance_view(session, dungeon_id: String) -> Dictionary:
	var dungeon = DungeonCatalogClass.get_definition(dungeon_id)
	if dungeon == null:
		return {}
	var key = ItemCatalogClass.get_definition(dungeon.entry_item_id)
	var owned: int = session.player.inventory.count(dungeon.entry_item_id)
	return {
		"title": dungeon.display_name,
		"eyebrow": "LOCH SOLO  •  ZALECANY POZIOM %s" % dungeon.recommended_level_text(),
		"description": dungeon.description,
		"message":
		(
			"WEJŚCIÓWKA: %s  •  %d/%d\nŹródła: %s"
			% [key.display_name, owned, dungeon.entry_item_quantity, dungeon.entry_source_text]
		),
		"resources": _resource_text(session),
		"actions":
		[
			{"id": "start", "label": "Użyj wejściówki i wejdź"},
			{"id": "exit", "label": "Wróć na mapę świata"},
		],
		"finished": false,
		"outcome": "",
		"loot": [],
	}


static func engine_script_for(enemy_id: String):
	match enemy_id:
		"order_grandmaster":
			return GrandMasterCombatEngineClass
		"admiral_varek":
			return AdmiralVarekCombatEngineClass
	return null


static func loot_since_snapshot(run: DungeonRunStateClass, inventory) -> Array[Dictionary]:
	var changes := {}
	for item_id: String in inventory.stacks:
		var current := int(inventory.stacks[item_id])
		var baseline := int(run.snapshot_stacks.get(item_id, 0))
		if current > baseline:
			changes[item_id] = current - baseline
	for item in inventory.equipment_items:
		if item.instance_id not in run.snapshot_equipment_ids:
			changes[item.item_id] = int(changes.get(item.item_id, 0)) + 1
	var result: Array[Dictionary] = []
	for item_id: String in changes:
		result.append({"item_id": item_id, "quantity": int(changes[item_id])})
	result.sort_custom(
		func(left: Dictionary, right: Dictionary) -> bool:
			return (
				ItemCatalogClass.get_definition(str(left.item_id)).display_name
				< ItemCatalogClass.get_definition(str(right.item_id)).display_name
			)
	)
	return result


static func discard_unsecured_loot(run: DungeonRunStateClass, inventory) -> Array[Dictionary]:
	var lost := loot_since_snapshot(run, inventory)
	for item_id: String in inventory.stacks.keys():
		var baseline := int(run.snapshot_stacks.get(item_id, 0))
		if int(inventory.stacks[item_id]) <= baseline:
			continue
		if baseline > 0:
			inventory.stacks[item_id] = baseline
		else:
			inventory.stacks.erase(item_id)
	for index in range(inventory.equipment_items.size() - 1, -1, -1):
		if inventory.equipment_items[index].instance_id not in run.snapshot_equipment_ids:
			inventory.equipment_items.remove_at(index)
	return lost


static func restore_resources(session, fraction: float) -> Dictionary:
	var stats = session.player.stats
	var healed: int = stats.heal(maxi(1, MathClass.python_roundi(stats.max_hp * fraction)))
	var mana := 0
	if stats.max_mana > 0:
		mana = stats.restore_mana(maxi(1, MathClass.python_roundi(stats.max_mana * fraction)))
	return {"hp": healed, "mana": mana}


static func _choose_crossroads(run, session, dungeon, action: String, rng) -> Dictionary:
	if dungeon.dungeon_id == "sunken_order_crypt":
		if action == "path_iron":
			return _begin_encounter(
				run, dungeon.iron_path_enemy, "Żelazne Wrota — ELITA", "pause_after_path"
			)
		if action == "path_flooded":
			session.advance_hours(1, rng)
			var chest := _roll_chest(session, dungeon, rng)
			run.step = "flooded_chest"
			run.branch_ambush_pending = rng.randf() < dungeon.flooded_ambush_chance
			run.last_message = "Zatopiona skrzynia: %s" % _format_loot(chest)
			return _ok(run.last_message)
	else:
		if action == "path_cargo":
			return _begin_random_encounter(
				run,
				["cursed_sailor", "black_fleet_drowned", "cursed_gunner"],
				"Zalana Ładownia",
				"cargo_boatswain",
				rng,
			)
		if action == "path_upper":
			run.step = "upper_deck"
			run.last_message = "Na pokładzie błyska lont przeklętego kanoniera."
			return _ok(run.last_message)
	return _error("Wybierz jedną z dostępnych dróg albo odwrót.")


static func _resolve_recovery(run, session, dungeon, use_recovery: bool) -> Dictionary:
	var message := "Nie korzystasz z miejsca odpoczynku."
	if use_recovery:
		var fraction := 0.25 if dungeon.dungeon_id == "sunken_order_crypt" else 0.30
		var restored := restore_resources(session, fraction)
		message = "Odzyskano %d PŻ i %d Many." % [restored.hp, restored.mana]
	run.step = "pause_after_recovery"
	run.last_message = message
	return _ok(message)


static func _begin_random_encounter(
	run, enemy_pool: Array, title: String, next_step: String, rng: RandomNumberGenerator
) -> Dictionary:
	var enemy_id := str(enemy_pool[rng.randi_range(0, enemy_pool.size() - 1)])
	return _begin_encounter(run, enemy_id, title, next_step)


static func _begin_encounter(run, enemy_id: String, title: String, next_step: String) -> Dictionary:
	run.step = "in_combat"
	run.pending_enemy_id = enemy_id
	run.pending_battle_title = title
	run.pending_next_step = next_step
	return {
		"ok": true,
		"combat": true,
		"enemy_id": enemy_id,
		"battle_title": title,
		"message": "Rozpoczyna się walka.",
	}


static func _roll_chest(session, dungeon, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	for entry: Dictionary in dungeon.chest_loot:
		if rng.randf() >= float(entry.chance):
			continue
		var drop := {"item_id": str(entry.item_id), "quantity": int(entry.get("quantity", 1))}
		if (
			session
			. player
			. inventory
			. add(
				drop.item_id,
				drop.quantity,
				rng,
				EquipmentAffixServiceClass.QUALITY_DUNGEON,
			)
		):
			drops.append(drop)
	return drops


static func _finish_completed(run, session, dungeon) -> Dictionary:
	run.step = "finished"
	run.outcome = "completed"
	run.completed = true
	run.last_loot = loot_since_snapshot(run, session.player.inventory)
	var contract_updates := ContractServiceClass.record_dungeon_completion(
		session.player, session.contract_board, dungeon.dungeon_id
	)
	var milestone := GuildMilestoneServiceClass.record(session, "dungeon:%s" % dungeon.dungeon_id)
	run.last_message = "Loch ukończony. Zdobyty łup został zabezpieczony."
	if milestone.get("awarded", false):
		run.last_message += " Reputacja Gildii +%d." % int(milestone.reputation)
	if not contract_updates.is_empty():
		run.last_message += " Zaktualizowano kontrakt Gildii."
	session.log_event("Ukończono loch: %s." % dungeon.display_name)
	return _ok(run.last_message)


static func _finish_retreat(run, session) -> Dictionary:
	var dungeon = DungeonCatalogClass.get_definition(run.dungeon_id)
	run.step = "finished"
	run.outcome = "retreated"
	run.last_loot = loot_since_snapshot(run, session.player.inventory)
	run.last_message = "Odwrót. Zdobyty podczas wyprawy łup został zabezpieczony."
	session.log_event("Wycofano się z lochu: %s." % dungeon.display_name)
	return _ok(run.last_message)


static func _finish_defeat(run, session) -> Dictionary:
	var dungeon = DungeonCatalogClass.get_definition(run.dungeon_id)
	run.step = "finished"
	run.outcome = "defeated"
	run.last_loot = discard_unsecured_loot(run, session.player.inventory)
	session.player.stats.restore_full()
	run.last_message = "Wyprawa nieudana. EXP i złoto pozostają, lecz niezabezpieczony łup przepada."
	session.log_event("Porażka w lochu: %s — utracono niezabezpieczony łup." % dungeon.display_name)
	return _ok(run.last_message)


static func _crossroads_view(result: Dictionary, dungeon_id: String) -> Dictionary:
	if dungeon_id == "sunken_order_crypt":
		result.title = "Rozwidlenie Krypty"
		result.description = "Żelazne wrota są strzeżone. Zalany korytarz prowadzi do starej skrzyni, ale woda może skrywać zasadzkę."
		result.actions = [
			{"id": "path_iron", "label": "Żelazne wrota"},
			{"id": "path_flooded", "label": "Zalany korytarz  •  skrzynia  •  +1 godzina"},
			_retreat(),
		]
	else:
		result.title = "Rozwidlenie Czarnej Floty"
		result.description = "Ładownia jest dłuższa i prowadzi do skarbca. Górny Pokład to krótsza droga pod ostrzałem."
		result.actions = [
			{"id": "path_cargo", "label": "Ładownia  •  dwie walki  •  skarbiec"},
			{"id": "path_upper", "label": "Górny Pokład  •  ostrzał"},
			_retreat(),
		]
	return result


static func _format_loot(drops: Array[Dictionary]) -> String:
	if drops.is_empty():
		return "brak łupu"
	var names: Array[String] = []
	for drop: Dictionary in drops:
		var definition = ItemCatalogClass.get_definition(str(drop.item_id))
		var quantity := int(drop.quantity)
		names.append(
			(
				definition.display_name
				if quantity == 1
				else "%s ×%d" % [definition.display_name, quantity]
			)
		)
	return ", ".join(names)


static func _resource_text(session) -> String:
	return (
		"PŻ %d/%d  •  MANA %d/%d  •  %s"
		% [
			session.player.stats.current_hp,
			session.player.stats.max_hp,
			session.player.stats.current_mana,
			session.player.stats.max_mana,
			session.formatted_time(),
		]
	)


static func _continue() -> Dictionary:
	return {"id": "continue", "label": "Idź głębiej"}


static func _retreat() -> Dictionary:
	return {"id": "retreat", "label": "Wycofaj się i zabezpiecz łup"}


static func _ok(message: String) -> Dictionary:
	return {"ok": true, "combat": false, "message": message}


static func _error(message: String) -> Dictionary:
	return {"ok": false, "combat": false, "message": message}
