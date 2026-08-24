class_name ContractService
extends RefCounted

const ContractDefinitionClass := preload("res://core/quests/contract_definition.gd")
const ContractObjectiveClass := preload("res://core/quests/contract_objective.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const LootCatalogClass := preload("res://core/items/loot_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")

const DAILY_UNLOCK_RANK := "E"
const WEEKLY_UNLOCK_RANK := "D"
const DAILY_REPUTATION := 15
const WEEKLY_REPUTATION := 75
const DUNGEON_NAMES := {
	"sunken_order_crypt": "Krypta Zatopionego Zakonu",
	"black_fleet_wreck": "Wrak Czarnej Floty",
}


static func current_daily_key() -> String:
	return Time.get_date_string_from_system()


static func current_weekly_key() -> String:
	return weekly_key_for_date(current_daily_key())


static func weekly_key_for_date(date_key: String) -> String:
	var parts := date_key.split("-")
	if parts.size() != 3:
		return ""
	var date := {"year": int(parts[0]), "month": int(parts[1]), "day": int(parts[2])}
	var unix := int(Time.get_unix_time_from_datetime_dict(date))
	var days := int(floori(unix / 86400.0))
	var iso_weekday := posmod(days + 3, 7) + 1
	var thursday_unix := unix + (4 - iso_weekday) * 86400
	var iso_year := int(Time.get_datetime_dict_from_unix_time(thursday_unix).year)
	var january_fourth := int(
		Time.get_unix_time_from_datetime_dict({"year": iso_year, "month": 1, "day": 4})
	)
	var january_fourth_days := int(floori(january_fourth / 86400.0))
	var january_fourth_weekday := posmod(january_fourth_days + 3, 7) + 1
	var week_one_monday := january_fourth - (january_fourth_weekday - 1) * 86400
	var week := 1 + int(floori((thursday_unix - week_one_monday) / 604800.0))
	return "%04d-W%02d" % [iso_year, week]


static func ensure_board(
	board,
	player,
	daily_key := "",
	weekly_key := "",
) -> Array[String]:
	var day: String = current_daily_key() if daily_key.is_empty() else daily_key
	var week: String = current_weekly_key() if weekly_key.is_empty() else weekly_key
	var messages: Array[String] = []
	if board.daily_date.is_empty() or day > board.daily_date:
		var old_daily_ids: Array[String] = []
		for contract in board.daily_contracts:
			old_daily_ids.append(contract.contract_id)
		board.clear_progress(old_daily_ids)
		board.daily_date = day
		board.daily_contracts = generate_daily_contracts(player, day)
		board.daily_claimed.clear()
		messages.append("Nowe kontrakty dzienne: %s." % day)
	elif day == board.daily_date and board.daily_contracts.is_empty():
		board.daily_contracts = generate_daily_contracts(player, day)
		messages.append("Utworzono kontrakty dzienne: %s." % day)
	if board.weekly_key.is_empty() or week > board.weekly_key:
		var old_weekly_ids: Array[String] = []
		if board.weekly_contract != null:
			old_weekly_ids.append(board.weekly_contract.contract_id)
		board.clear_progress(old_weekly_ids)
		board.weekly_key = week
		board.weekly_contract = generate_weekly_contract(player, week)
		board.weekly_claimed = false
		messages.append("Nowy kontrakt tygodniowy: %s." % week)
	elif week == board.weekly_key and board.weekly_contract == null:
		board.weekly_contract = generate_weekly_contract(player, week)
		messages.append("Utworzono kontrakt tygodniowy: %s." % week)
	return messages


static func generate_daily_contracts(player, period_key: String) -> Array:
	var rng: RandomNumberGenerator = _period_rng(
		player.display_name, period_key, ContractDefinitionClass.DAILY
	)
	var regions := _accessible_regions(player.level)
	var hunt_region: String = _choice(regions, rng)
	var hunt_enemy: String = _choice(_normal_enemies(hunt_region), rng)
	var hunt_region_data = RegionCatalogClass.get_definition(hunt_region)
	var danger: int = hunt_region_data.danger_rating
	var hunt_count: int = 3 + danger + rng.randi_range(0, 2)
	var hunt_name := EnemyCatalogClass.display_name_for(hunt_enemy)
	var hunt_titles := [
		"Polowanie: %s" % hunt_name,
		"Problem z: %s" % hunt_name,
		"List gończy: %s" % hunt_name,
		"Uszczuplić stado: %s" % hunt_name,
	]
	var hunt := (
		ContractDefinitionClass
		. new(
			"daily-%s-hunt" % period_key,
			{
				"category": ContractDefinitionClass.DAILY,
				"period_key": period_key,
				"title": _choice(hunt_titles, rng),
				"description": "Gildia płaci za ograniczenie liczby zagrożeń na szlakach.",
				"recommended_level": hunt_region_data.recommended_level_min,
				"objectives":
				[
					ContractObjectiveClass.new(
						ContractObjectiveClass.KILL_ENEMY, hunt_enemy, hunt_count
					)
				],
				"reward_exp": 100 + danger * 70 + hunt_count * 10,
				"reward_gold": 55 + danger * 35,
			}
		)
	)

	var supply_region: String = _choice(regions, rng)
	var supply_region_data = RegionCatalogClass.get_definition(supply_region)
	var material_id: String = _choice(_common_materials_for_region(supply_region), rng)
	var supply_danger: int = supply_region_data.danger_rating
	var quantity: int = 2 + mini(2, supply_danger - 1) + rng.randi_range(0, 1)
	var material_name: String = ItemCatalogClass.get_definition(material_id).display_name
	var supply_titles := [
		"Zamówienie: %s" % material_name,
		"Braki w magazynie: %s" % material_name,
		"Dostawa dla rzemieślników",
		"Potrzebne materiały: %s" % material_name,
	]
	var supply := (
		ContractDefinitionClass
		. new(
			"daily-%s-supply" % period_key,
			{
				"category": ContractDefinitionClass.DAILY,
				"period_key": period_key,
				"title": _choice(supply_titles, rng),
				"description":
				"Gildia skupuje materiały potrzebne miejscowym rzemieślnikom i alchemikom.",
				"recommended_level": supply_region_data.recommended_level_min,
				"objectives":
				[
					ContractObjectiveClass.new(
						ContractObjectiveClass.COLLECT, material_id, quantity, true
					)
				],
				"reward_exp": 120 + supply_danger * 65,
				"reward_gold": 70 + supply_danger * 30,
			}
		)
	)

	var third_region: String = _choice(regions, rng)
	var third_region_data = RegionCatalogClass.get_definition(third_region)
	var third = null
	if player.level >= 2:
		var elite_count := 1 if third_region_data.danger_rating == 1 else 2
		var elite_titles := [
			"Elitarne zagrożenie",
			"Niebezpieczny okaz",
			"Łowca elit",
			"Ponadprzeciętny przeciwnik",
		]
		third = (
			ContractDefinitionClass
			. new(
				"daily-%s-elite" % period_key,
				{
					"category": ContractDefinitionClass.DAILY,
					"period_key": period_key,
					"title": _choice(elite_titles, rng),
					"description":
					"Gildia szuka kogoś, kto poradzi sobie z wyjątkowo silnymi przeciwnikami.",
					"recommended_level": maxi(2, third_region_data.recommended_level_min),
					"objectives":
					[
						(
							ContractObjectiveClass
							. new(
								ContractObjectiveClass.KILL_ELITE_REGION,
								third_region,
								elite_count,
							)
						)
					],
					"reward_exp": 240 + third_region_data.danger_rating * 90,
					"reward_gold": 100 + third_region_data.danger_rating * 45,
					"reward_item_id": "strong_healing_potion",
					"reward_item_quantity": 1,
				}
			)
		)
	else:
		third = (
			ContractDefinitionClass
			. new(
				"daily-%s-patrol" % period_key,
				{
					"category": ContractDefinitionClass.DAILY,
					"period_key": period_key,
					"title": "Pierwszy patrol",
					"description": "Przejdź się po okolicy i oczyść najbliższe szlaki.",
					"recommended_level": 0,
					"objectives":
					[
						ContractObjectiveClass.new(
							ContractObjectiveClass.KILL_REGION, third_region, 5
						)
					],
					"reward_exp": 160,
					"reward_gold": 80,
				}
			)
		)
	return [hunt, supply, third]


static func generate_weekly_contract(player, period_key: String):
	var rng: RandomNumberGenerator = _period_rng(
		player.display_name, period_key, ContractDefinitionClass.WEEKLY
	)
	var region_id: String = _accessible_regions(player.level)[-1]
	var region = RegionCatalogClass.get_definition(region_id)
	var danger: int = region.danger_rating
	var objectives := [
		ContractObjectiveClass.new(ContractObjectiveClass.KILL_REGION, region_id, 8 + danger * 2),
		ContractObjectiveClass.new(ContractObjectiveClass.KILL_ELITE, "", mini(3, 1 + danger)),
	]
	var titles: Array
	var description: String
	var reward_item_id: String
	var reward_item_quantity: int
	if player.level >= 7:
		var dungeon_id := "black_fleet_wreck" if player.level >= 16 else "sunken_order_crypt"
		var dungeon_name: String = DUNGEON_NAMES[dungeon_id]
		objectives.append(
			ContractObjectiveClass.new(ContractObjectiveClass.COMPLETE_DUNGEON, dungeon_id, 1)
		)
		titles = [
			"Tydzień w regionie: %s" % region.display_name,
			"Próba Gildii",
			"Szlaki i %s" % dungeon_name,
		]
		description = (
			"Długi kontrakt dla doświadczonego poszukiwacza. Gildia oczekuje "
			+ "działań w aktualnym regionie oraz ukończenia: %s." % dungeon_name
		)
		reward_item_id = "grandmaster_elixir"
		reward_item_quantity = 1
	else:
		var minibosses := _minibosses_for_region(region_id)
		if not minibosses.is_empty():
			objectives.append(
				ContractObjectiveClass.new(
					ContractObjectiveClass.KILL_MINIBOSS, _choice(minibosses, rng), 1
				)
			)
		titles = [
			"Tydzień w regionie: %s" % region.display_name,
			"Kontrakt tygodniowy",
			"Duże zlecenie Gildii",
		]
		description = "Tygodniowe zlecenie łączące kilka celów w jednym regionie."
		reward_item_id = "strong_healing_potion"
		reward_item_quantity = 2
	return (
		ContractDefinitionClass
		. new(
			"weekly-%s" % period_key,
			{
				"category": ContractDefinitionClass.WEEKLY,
				"period_key": period_key,
				"title": _choice(titles, rng),
				"description": description,
				"recommended_level": region.recommended_level_min,
				"objectives": objectives,
				"reward_exp": 850 + danger * 170,
				"reward_gold": 450 + danger * 110,
				"reward_item_id": reward_item_id,
				"reward_item_quantity": reward_item_quantity,
			}
		)
	)


static func active_contracts(board) -> Array:
	var contracts: Array = []
	for contract in board.daily_contracts:
		if contract.contract_id not in board.daily_claimed:
			contracts.append(contract)
	if board.weekly_contract != null and not board.weekly_claimed:
		contracts.append(board.weekly_contract)
	return contracts


static func find_contract(board, contract_id: String):
	for contract in board.daily_contracts:
		if contract.contract_id == contract_id:
			return contract
	if board.weekly_contract != null and board.weekly_contract.contract_id == contract_id:
		return board.weekly_contract
	return null


static func is_claimed(board, contract) -> bool:
	return (
		contract.contract_id in board.daily_claimed
		if contract.category == ContractDefinitionClass.DAILY
		else board.weekly_claimed
	)


static func objective_progress(player, board, contract, objective_index: int) -> Array[int]:
	var objective = contract.objectives[objective_index]
	var current := 0
	if objective.objective_type == ContractObjectiveClass.COLLECT:
		current = player.inventory.count(objective.target_id)
	else:
		current = int(board.progress.get(contract.contract_id, {}).get(str(objective_index), 0))
	return [mini(current, objective.required_count), objective.required_count]


static func is_ready(player, board, contract) -> bool:
	if is_claimed(board, contract):
		return false
	for index in contract.objectives.size():
		if (
			objective_progress(player, board, contract, index)[0]
			< contract.objectives[index].required_count
		):
			return false
	return true


static func record_victory(
	player,
	board,
	enemy_id: String,
	region_id: String,
	is_miniboss := false,
	elite_modifier_id := "",
) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for contract in active_contracts(board):
		for index in contract.objectives.size():
			var objective = contract.objectives[index]
			var matches := false
			match objective.objective_type:
				ContractObjectiveClass.KILL_ENEMY:
					matches = objective.target_id == enemy_id
				ContractObjectiveClass.KILL_REGION:
					matches = objective.target_id == region_id
				ContractObjectiveClass.KILL_ELITE:
					matches = not elite_modifier_id.is_empty()
				ContractObjectiveClass.KILL_ELITE_REGION:
					matches = not elite_modifier_id.is_empty() and objective.target_id == region_id
				ContractObjectiveClass.KILL_MINIBOSS:
					matches = is_miniboss and objective.target_id == enemy_id
			if matches:
				var update := _increment(player, board, contract, index)
				if not update.is_empty():
					updates.append(update)
	return updates


static func record_dungeon_completion(player, board, dungeon_id: String) -> Array[Dictionary]:
	var updates: Array[Dictionary] = []
	for contract in active_contracts(board):
		for index in contract.objectives.size():
			var objective = contract.objectives[index]
			if (
				objective.objective_type == ContractObjectiveClass.COMPLETE_DUNGEON
				and objective.target_id == dungeon_id
			):
				var update := _increment(player, board, contract, index)
				if not update.is_empty():
					updates.append(update)
	return updates


static func claim(session, contract_id: String) -> Dictionary:
	var board = session.contract_board
	var contract = find_contract(board, contract_id)
	if contract == null:
		return {"ok": false, "message": "Nieznany kontrakt."}
	var required_rank := (
		DAILY_UNLOCK_RANK
		if contract.category == ContractDefinitionClass.DAILY
		else WEEKLY_UNLOCK_RANK
	)
	if not GuildProgressionServiceClass.has_rank(session.guild_reputation, required_rank):
		return {"ok": false, "message": "Wymagana ranga Gildii %s." % required_rank}
	if is_claimed(board, contract):
		return {"ok": false, "message": "Nagroda za ten kontrakt została już odebrana."}
	if not is_ready(session.player, board, contract):
		return {"ok": false, "message": "Warunki kontraktu nie zostały jeszcze spełnione."}
	for objective in contract.objectives:
		if (
			objective.objective_type == ContractObjectiveClass.COLLECT
			and objective.consume_items
			and not session.player.inventory.has(objective.target_id, objective.required_count)
		):
			return {"ok": false, "message": "Brakuje materiałów wymaganych do oddania kontraktu."}
	for objective in contract.objectives:
		if objective.objective_type == ContractObjectiveClass.COLLECT and objective.consume_items:
			session.player.inventory.remove_item(objective.target_id, objective.required_count)
	var old_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	var levels_gained: int = session.player.gain_experience(contract.reward_exp)
	session.player.add_gold(contract.reward_gold)
	if not contract.reward_item_id.is_empty():
		session.player.inventory.add(contract.reward_item_id, contract.reward_item_quantity)
	var reputation := (
		DAILY_REPUTATION
		if contract.category == ContractDefinitionClass.DAILY
		else WEEKLY_REPUTATION
	)
	session.guild_reputation += reputation
	if contract.category == ContractDefinitionClass.DAILY:
		board.daily_claimed.append(contract.contract_id)
	else:
		board.weekly_claimed = true
	var new_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	session.log_event("Ukończono kontrakt Gildii: %s." % contract.title)
	session.log_event("Reputacja Gildii +%d: kontrakt „%s”." % [reputation, contract.title])
	if old_rank.code != new_rank.code:
		session.log_event("Awans w Gildii: %s." % new_rank.full_name())
	var unlocked_achievements := AchievementServiceClass.record_guild_rank(session, new_rank.code)
	return {
		"ok": true,
		"contract_id": contract.contract_id,
		"title": contract.title,
		"experience": contract.reward_exp,
		"gold": contract.reward_gold,
		"guild_reputation": reputation,
		"levels_gained": levels_gained,
		"attribute_points_gained": levels_gained * 4,
		"reward_item_id": contract.reward_item_id,
		"reward_item_quantity": contract.reward_item_quantity,
		"old_rank_code": old_rank.code,
		"new_rank_code": new_rank.code,
		"rank_changed": old_rank.code != new_rank.code,
		"unlocked_achievements": unlocked_achievements,
	}


static func objective_text(player, board, contract, objective_index: int) -> String:
	var objective = contract.objectives[objective_index]
	var progress := objective_progress(player, board, contract, objective_index)
	var target_name: String = objective.target_id
	match objective.objective_type:
		ContractObjectiveClass.KILL_ENEMY, ContractObjectiveClass.KILL_MINIBOSS:
			target_name = EnemyCatalogClass.display_name_for(objective.target_id)
		ContractObjectiveClass.KILL_REGION, ContractObjectiveClass.KILL_ELITE_REGION:
			target_name = RegionCatalogClass.get_definition(objective.target_id).display_name
		ContractObjectiveClass.COLLECT:
			target_name = ItemCatalogClass.get_definition(objective.target_id).display_name
		ContractObjectiveClass.COMPLETE_DUNGEON:
			target_name = DUNGEON_NAMES.get(objective.target_id, objective.target_id)
	match objective.objective_type:
		ContractObjectiveClass.KILL_ENEMY:
			return "Pokonaj: %s  •  %d/%d" % [target_name, progress[0], progress[1]]
		ContractObjectiveClass.KILL_REGION:
			return "Wygraj walki — %s  •  %d/%d" % [target_name, progress[0], progress[1]]
		ContractObjectiveClass.COLLECT:
			return "Dostarcz: %s  •  %d/%d" % [target_name, progress[0], progress[1]]
		ContractObjectiveClass.KILL_ELITE:
			return "Pokonaj elity  •  %d/%d" % [progress[0], progress[1]]
		ContractObjectiveClass.KILL_ELITE_REGION:
			return "Pokonaj elity — %s  •  %d/%d" % [target_name, progress[0], progress[1]]
		ContractObjectiveClass.KILL_MINIBOSS:
			return "Pokonaj minibossa: %s  •  %d/%d" % [target_name, progress[0], progress[1]]
		ContractObjectiveClass.COMPLETE_DUNGEON:
			return "Ukończ: %s  •  %d/%d" % [target_name, progress[0], progress[1]]
	return "Nieznany cel"


static func dependency_note(contract) -> String:
	var missing: Array[String] = []
	for objective in contract.objectives:
		if (
			objective.objective_type == ContractObjectiveClass.COMPLETE_DUNGEON
			and "lochy — etap 6" not in missing
		):
			missing.append("lochy — etap 6")
	return ", ".join(missing)


static func serialize_board(board) -> Dictionary:
	return {
		"daily_date": board.daily_date,
		"daily_contracts": board.daily_contracts.map(serialize_contract),
		"daily_claimed": board.daily_claimed.duplicate(),
		"weekly_key": board.weekly_key,
		"weekly_contract":
		{} if board.weekly_contract == null else serialize_contract(board.weekly_contract),
		"weekly_claimed": board.weekly_claimed,
		"progress": board.progress.duplicate(true),
	}


static func serialize_contract(contract) -> Dictionary:
	var objectives: Array[Dictionary] = []
	for objective in contract.objectives:
		(
			objectives
			. append(
				{
					"objective_type": objective.objective_type,
					"target_id": objective.target_id,
					"required_count": objective.required_count,
					"consume_items": objective.consume_items,
				}
			)
		)
	return {
		"contract_id": contract.contract_id,
		"category": contract.category,
		"period_key": contract.period_key,
		"title": contract.title,
		"description": contract.description,
		"recommended_level": contract.recommended_level,
		"objectives": objectives,
		"reward_exp": contract.reward_exp,
		"reward_gold": contract.reward_gold,
		"reward_item_id": contract.reward_item_id,
		"reward_item_quantity": contract.reward_item_quantity,
	}


static func deserialize_board(data: Dictionary, board) -> String:
	var error := validate_serialized_board(data)
	if not error.is_empty():
		return error
	board.daily_date = str(data.daily_date)
	board.daily_contracts.clear()
	for contract_data: Dictionary in data.daily_contracts:
		board.daily_contracts.append(_deserialize_contract(contract_data))
	board.daily_claimed.assign(data.daily_claimed)
	board.weekly_key = str(data.weekly_key)
	board.weekly_contract = (
		null if data.weekly_contract.is_empty() else _deserialize_contract(data.weekly_contract)
	)
	board.weekly_claimed = data.weekly_claimed
	board.progress = data.progress.duplicate(true)
	return ""


static func validate_serialized_board(data: Dictionary) -> String:
	if (
		not data.get("daily_date") is String
		or not data.get("daily_contracts") is Array
		or not data.get("daily_claimed") is Array
		or not data.get("weekly_key") is String
		or not data.get("weekly_contract") is Dictionary
		or not data.get("weekly_claimed") is bool
		or not data.get("progress") is Dictionary
	):
		return "Zapis zawiera nieprawidłową tablicę kontraktów."
	if not data.daily_date.is_empty() and not _valid_daily_key(data.daily_date):
		return "Zapis zawiera nieprawidłową datę kontraktów dziennych."
	if not data.weekly_key.is_empty() and not _valid_weekly_key(data.weekly_key):
		return "Zapis zawiera nieprawidłowy tydzień kontraktu."
	if not data.daily_contracts.is_empty() and data.daily_contracts.size() != 3:
		return "Zapis nie zawiera trzech kontraktów dziennych."
	var ids := {}
	var daily_ids := {}
	var contracts: Array = []
	for contract_data in data.daily_contracts:
		if not contract_data is Dictionary:
			return "Zapis zawiera uszkodzony kontrakt dzienny."
		var error := _validate_contract_data(contract_data, ContractDefinitionClass.DAILY)
		if not error.is_empty():
			return error
		if contract_data.period_key != data.daily_date:
			return "Kontrakt dzienny pochodzi z innego okresu."
		if ids.has(contract_data.contract_id):
			return "Zapis powtarza identyfikator kontraktu."
		ids[contract_data.contract_id] = true
		daily_ids[contract_data.contract_id] = true
		contracts.append(contract_data)
	if not data.daily_contracts.is_empty():
		var daily_prefix := "daily-%s-" % data.daily_date
		if (
			not daily_ids.has(daily_prefix + "hunt")
			or not daily_ids.has(daily_prefix + "supply")
			or (
				not daily_ids.has(daily_prefix + "elite")
				and not daily_ids.has(daily_prefix + "patrol")
			)
		):
			return "Zapis zawiera nieprawidłowy zestaw kontraktów dziennych."
	if not data.weekly_contract.is_empty():
		var weekly_error := _validate_contract_data(
			data.weekly_contract, ContractDefinitionClass.WEEKLY
		)
		if not weekly_error.is_empty():
			return weekly_error
		if data.weekly_contract.period_key != data.weekly_key:
			return "Kontrakt tygodniowy pochodzi z innego okresu."
		if data.weekly_contract.contract_id != "weekly-%s" % data.weekly_key:
			return "Zapis zawiera nieprawidłowy identyfikator kontraktu tygodniowego."
		if ids.has(data.weekly_contract.contract_id):
			return "Zapis powtarza identyfikator kontraktu."
		ids[data.weekly_contract.contract_id] = true
		contracts.append(data.weekly_contract)
	elif data.weekly_claimed:
		return "Zapis oznacza nieistniejący kontrakt tygodniowy jako odebrany."
	var claimed := {}
	for contract_id_value in data.daily_claimed:
		if not contract_id_value is String:
			return "Zapis zawiera nieprawidłowy odebrany kontrakt."
		var contract_id := str(contract_id_value)
		if not daily_ids.has(contract_id) or claimed.has(contract_id):
			return "Zapis zawiera nieznany albo powtórzony odebrany kontrakt."
		claimed[contract_id] = true
	for contract_id_value in data.progress:
		var contract_id := str(contract_id_value)
		if not ids.has(contract_id) or not data.progress[contract_id_value] is Dictionary:
			return "Zapis zawiera postęp nieznanego kontraktu."
		var matching_contracts := contracts.filter(
			func(candidate: Dictionary) -> bool: return candidate.contract_id == contract_id
		)
		var contract_data: Dictionary = matching_contracts[0]
		for objective_index_value in data.progress[contract_id_value]:
			var objective_index_text := str(objective_index_value)
			if not objective_index_text.is_valid_int():
				return "Zapis zawiera nieprawidłowy indeks celu kontraktu."
			var objective_index := int(objective_index_text)
			var progress = data.progress[contract_id_value][objective_index_value]
			if (
				objective_index < 0
				or objective_index >= contract_data.objectives.size()
				or not _is_non_negative_integer(progress)
				or int(progress) > int(contract_data.objectives[objective_index].required_count)
			):
				return "Zapis zawiera nieprawidłowy postęp kontraktu."
	return ""


static func _validate_contract_data(data: Dictionary, category: String) -> String:
	var required_fields := [
		"contract_id",
		"category",
		"period_key",
		"title",
		"description",
		"recommended_level",
		"objectives",
		"reward_exp",
		"reward_gold",
		"reward_item_id",
		"reward_item_quantity",
	]
	for field: String in required_fields:
		if not data.has(field):
			return "Zapis kontraktu nie zawiera pola %s." % field
	if (
		not data.contract_id is String
		or not data.category is String
		or data.category != category
		or not data.period_key is String
		or not data.title is String
		or data.title.is_empty()
		or not data.description is String
		or not _is_non_negative_integer(data.recommended_level)
		or not data.objectives is Array
		or data.objectives.is_empty()
		or not _is_non_negative_integer(data.reward_exp)
		or not _is_non_negative_integer(data.reward_gold)
		or not data.reward_item_id is String
		or not _is_non_negative_integer(data.reward_item_quantity)
	):
		return "Zapis zawiera nieprawidłową definicję kontraktu."
	if not data.reward_item_id.is_empty():
		if ItemCatalogClass.get_definition(data.reward_item_id) == null:
			return "Zapis kontraktu wskazuje nieznaną nagrodę."
		if int(data.reward_item_quantity) <= 0:
			return "Zapis kontraktu ma nieprawidłową liczbę nagród."
	elif int(data.reward_item_quantity) != 0:
		return "Zapis kontraktu ma liczbę nagród bez przedmiotu."
	for objective_data in data.objectives:
		var objective_error := _validate_objective_data(objective_data)
		if not objective_error.is_empty():
			return objective_error
	return ""


static func _validate_objective_data(data) -> String:
	if (
		not data is Dictionary
		or not data.get("objective_type") is String
		or not data.get("target_id") is String
		or not _is_positive_integer(data.get("required_count"))
		or not data.get("consume_items") is bool
	):
		return "Zapis zawiera nieprawidłowy cel kontraktu."
	var objective_type := str(data.objective_type)
	var target_id := str(data.target_id)
	if objective_type not in ContractObjectiveClass.TYPES:
		return "Zapis zawiera nieznany typ celu kontraktu."
	match objective_type:
		ContractObjectiveClass.KILL_ENEMY, ContractObjectiveClass.KILL_MINIBOSS:
			if not EnemyCatalogClass.has_enemy(target_id):
				return "Cel kontraktu wskazuje nieznanego przeciwnika."
		ContractObjectiveClass.KILL_REGION, ContractObjectiveClass.KILL_ELITE_REGION:
			if not RegionCatalogClass.is_valid_region_id(target_id):
				return "Cel kontraktu wskazuje nieznany region."
		ContractObjectiveClass.COLLECT:
			if ItemCatalogClass.get_definition(target_id) == null:
				return "Cel kontraktu wskazuje nieznany przedmiot."
		ContractObjectiveClass.KILL_ELITE:
			if not target_id.is_empty():
				return "Ogólny cel elitarny nie może wskazywać przeciwnika."
		ContractObjectiveClass.COMPLETE_DUNGEON:
			if not DUNGEON_NAMES.has(target_id):
				return "Cel kontraktu wskazuje nieznany loch."
	return ""


static func _deserialize_contract(data: Dictionary):
	var objectives: Array = []
	for objective_data: Dictionary in data.objectives:
		(
			objectives
			. append(
				(
					ContractObjectiveClass
					. new(
						objective_data.objective_type,
						objective_data.target_id,
						int(objective_data.required_count),
						objective_data.consume_items,
					)
				)
			)
		)
	return (
		ContractDefinitionClass
		. new(
			data.contract_id,
			{
				"category": data.category,
				"period_key": data.period_key,
				"title": data.title,
				"description": data.description,
				"recommended_level": int(data.recommended_level),
				"objectives": objectives,
				"reward_exp": int(data.reward_exp),
				"reward_gold": int(data.reward_gold),
				"reward_item_id": data.reward_item_id,
				"reward_item_quantity": int(data.reward_item_quantity),
			}
		)
	)


static func _increment(player, board, contract, objective_index: int) -> Dictionary:
	var objective = contract.objectives[objective_index]
	var contract_progress: Dictionary = board.progress.get(contract.contract_id, {})
	var key := str(objective_index)
	var old := int(contract_progress.get(key, 0))
	var current := mini(objective.required_count, old + 1)
	contract_progress[key] = current
	board.progress[contract.contract_id] = contract_progress
	if current == old:
		return {}
	return {
		"contract_id": contract.contract_id,
		"title": contract.title,
		"objective_index": objective_index,
		"current": current,
		"required": objective.required_count,
		"ready": is_ready(player, board, contract),
	}


static func _accessible_regions(level: int) -> Array[String]:
	var result: Array[String] = []
	for region_id: String in RegionCatalogClass.REGION_ORDER:
		if level >= RegionCatalogClass.get_definition(region_id).recommended_level_min:
			result.append(region_id)
	if result.is_empty():
		result.append(RegionCatalogClass.REGION_ORDER[0])
	return result


static func _normal_enemies(region_id: String) -> Array[String]:
	var region = RegionCatalogClass.get_definition(region_id)
	var ids: Array[String] = []
	var all_ids: Array = region.day_encounters.keys()
	all_ids.append_array(region.night_encounters.keys())
	for enemy_id_value in all_ids:
		var enemy_id := str(enemy_id_value)
		if (
			enemy_id not in ids
			and EnemyCatalogClass.get_data(enemy_id).get("rank", "normal") == "normal"
		):
			ids.append(enemy_id)
	ids.sort()
	return ids


static func _minibosses_for_region(region_id: String) -> Array[String]:
	var region = RegionCatalogClass.get_definition(region_id)
	var ids: Array[String] = []
	var all_ids: Array = region.day_encounters.keys()
	all_ids.append_array(region.night_encounters.keys())
	for enemy_id_value in all_ids:
		var enemy_id := str(enemy_id_value)
		if (
			enemy_id not in ids
			and EnemyCatalogClass.get_data(enemy_id).get("rank", "normal") == "miniboss"
		):
			ids.append(enemy_id)
	ids.sort()
	return ids


static func _common_materials_for_region(region_id: String) -> Array[String]:
	var materials: Array[String] = []
	for enemy_id: String in _normal_enemies(region_id):
		for entry: Dictionary in LootCatalogClass.get_table(enemy_id):
			if float(entry.chance) < 0.2:
				continue
			var item_id := str(entry.item_id)
			var definition = ItemCatalogClass.get_definition(item_id)
			if (
				definition != null
				and definition.category == "material"
				and item_id not in materials
			):
				materials.append(item_id)
	materials.sort()
	return materials


static func _period_rng(
	player_name: String, period_key: String, category: String
) -> RandomNumberGenerator:
	var rng := RandomNumberGenerator.new()
	rng.seed = ("EchoesOfPythonia|%s|%s|%s" % [player_name, category, period_key]).hash()
	return rng


static func _choice(values: Array, rng: RandomNumberGenerator):
	return values[rng.randi_range(0, values.size() - 1)]


static func _valid_daily_key(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9]{4}-[0-9]{2}-[0-9]{2}$")
	return regex.search(value) != null


static func _valid_weekly_key(value: String) -> bool:
	var regex := RegEx.new()
	regex.compile("^[0-9]{4}-W[0-9]{2}$")
	return regex.search(value) != null


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _is_non_negative_integer(value) -> bool:
	return _is_integer(value) and int(value) >= 0


static func _is_positive_integer(value) -> bool:
	return _is_integer(value) and int(value) > 0
