class_name ExpeditionPreparationService
extends RefCounted

const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const ConsumableServiceClass := preload("res://core/items/consumable_service.gd")
const ExpeditionPresetClass := preload("res://core/world/expedition_preset.gd")
const GuildStorageServiceClass := preload("res://core/economy/guild_storage_service.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")

const PRESET_ORDER := ["solo", "boss", "dungeon", "rift"]
const PRESET_NAMES := {
	"solo": "SOLO",
	"boss": "BOSS",
	"dungeon": "DUNGEON",
	"rift": "SZCZELINA",
}


static func select_location(state, location_id: String, known_region_ids: Array) -> Dictionary:
	if (
		not RegionCatalogClass.is_valid_region_id(location_id)
		or location_id not in known_region_ids
	):
		return _failure("Nie możesz wybrać nieznanego regionu.")
	state.selected_location_id = location_id
	return {"ok": true, "message": "Wybrano cel wyprawy."}


static func available_supply_ids(player, storage) -> Array[String]:
	var ids := {}
	for item_id: String in player.inventory.stacks:
		ids[item_id] = true
	for item_id: String in storage.inventory.stacks:
		ids[item_id] = true
	var result: Array[String] = []
	for item_id_value in ids:
		var item_id := str(item_id_value)
		var definition = ItemCatalogClass.get_definition(item_id)
		if definition == null or definition.category != "consumable":
			continue
		if player.inventory.count(item_id) + storage.inventory.count(item_id) > 0:
			result.append(item_id)
	result.sort_custom(
		func(left: String, right: String) -> bool:
			return (
				ItemCatalogClass.get_definition(left).display_name
				< ItemCatalogClass.get_definition(right).display_name
			)
	)
	return result


static func save_preset(
	state, preset_id: String, party, supplies: Dictionary, current_day := 0
) -> Dictionary:
	if not PRESET_NAMES.has(preset_id):
		return _failure("Nieznany preset wyprawowy.")
	var clean_supplies := {}
	for item_id_value in supplies:
		var item_id := str(item_id_value)
		var quantity_value = supplies[item_id_value]
		if not _is_integer(quantity_value) or int(quantity_value) < 0:
			return _failure("Ilość zapasu nie może być ujemna.")
		var definition = ItemCatalogClass.get_definition(item_id)
		if definition == null or definition.category != "consumable":
			return _failure("Wybrany przedmiot nie jest zapasem użytkowym.")
		if int(quantity_value) > 0:
			clean_supplies[item_id] = int(quantity_value)

	var preset := ExpeditionPresetClass.new(preset_id)
	preset.configured = true
	if preset_id != "solo":
		for companion in party.active_companions(current_day):
			preset.active_companion_ids.append(companion.companion_id)
	preset.supplies = clean_supplies
	state.presets[preset_id] = preset
	return {"ok": true, "message": "Zapisano preset %s." % PRESET_NAMES[preset_id]}


static func clear_preset(state, preset_id: String) -> Dictionary:
	if not PRESET_NAMES.has(preset_id):
		return _failure("Nieznany preset wyprawowy.")
	state.presets[preset_id] = ExpeditionPresetClass.new(preset_id)
	return {"ok": true, "message": "Preset został wyczyszczony."}


static func apply_preset(session, preset_id: String, composition_locked := false) -> Dictionary:
	if not PRESET_NAMES.has(preset_id):
		return _failure("Nieznany preset wyprawowy.")
	var preset = session.expedition_preparation.preset_for(preset_id)
	if preset == null or not preset.configured:
		return _failure("Ten preset nie został jeszcze skonfigurowany.")
	if composition_locked:
		return _failure("Skład jest zablokowany na czas ekspedycji Szczeliny.")

	var planned_withdrawals := {}
	var missing := {}
	for item_id_value in preset.supplies:
		var item_id := str(item_id_value)
		var target_quantity := int(preset.supplies[item_id_value])
		var needed := maxi(0, target_quantity - session.player.inventory.count(item_id))
		if needed <= 0:
			continue
		var available: int = session.guild_storage.inventory.count(item_id)
		var take: int = mini(needed, available)
		if take > 0:
			planned_withdrawals[item_id] = take
		if take < needed:
			missing[item_id] = needed - take

	var added_weight := 0.0
	for item_id: String in planned_withdrawals:
		added_weight += CarryWeightServiceClass.stack_weight(
			item_id, int(planned_withdrawals[item_id])
		)
	var projected := (
		CarryWeightServiceClass.inventory_weight(session.player.inventory) + added_weight
	)
	var capacity := CarryWeightServiceClass.carry_capacity(session.player)
	if projected > capacity + 0.000000001:
		return _failure(
			(
				(
					"Preset przekroczyłby udźwig: %.1f/%.1f kg. "
					+ "Odłóż część rzeczy przed uzupełnieniem zapasów."
				)
				% [projected, capacity]
			)
		)

	CompanionServiceClass.set_solo(session.party)
	var activated: Array[String] = []
	var unavailable: Array[String] = []
	for companion_id_value in preset.active_companion_ids:
		var companion_id := str(companion_id_value)
		var companion = session.party.companion_by_id(companion_id)
		if companion == null:
			unavailable.append(companion_id)
			continue
		if not companion.can_join_party(session.day):
			unavailable.append(companion.display_name)
			continue
		var activation := CompanionServiceClass.set_active(
			session.party, companion_id, true, session.day
		)
		if activation.ok:
			activated.append(companion.display_name)
		else:
			unavailable.append(companion.display_name)

	for item_id: String in planned_withdrawals:
		(
			GuildStorageServiceClass
			. withdraw_stack(
				session.player,
				session.guild_storage,
				item_id,
				int(planned_withdrawals[item_id]),
			)
		)
	return {
		"ok": true,
		"message": "Zastosowano preset %s." % PRESET_NAMES[preset_id],
		"activated_companions": activated,
		"unavailable_companions": unavailable,
		"withdrawn": planned_withdrawals,
		"missing": missing,
	}


static func withdraw_supply(session, item_id: String, quantity: int) -> Dictionary:
	var definition = ItemCatalogClass.get_definition(item_id)
	if definition == null or definition.category != "consumable":
		return _failure("Wybrany przedmiot nie jest zapasem użytkowym.")
	if quantity <= 0:
		return _failure("Ilość musi być większa od zera.")
	if not session.guild_storage.inventory.has(item_id, quantity):
		return _failure("W Magazynie Gildii nie ma tylu sztuk tego przedmiotu.")
	var projected := (
		CarryWeightServiceClass.inventory_weight(session.player.inventory)
		+ CarryWeightServiceClass.stack_weight(item_id, quantity)
	)
	var capacity := CarryWeightServiceClass.carry_capacity(session.player)
	if projected > capacity + 0.000000001:
		return _failure("Te zapasy przekroczyłyby udźwig: %.1f/%.1f kg." % [projected, capacity])
	return GuildStorageServiceClass.withdraw_stack(
		session.player, session.guild_storage, item_id, quantity
	)


static func use_supply(session, item_id: String) -> Dictionary:
	return ConsumableServiceClass.use(session.player, item_id)


static func warnings(session) -> Array[String]:
	var result: Array[String] = []
	var player = session.player
	if float(player.stats.current_hp) / maxi(1, player.stats.max_hp) <= 0.35:
		result.append("Niskie PŻ bohatera: %d/%d." % [player.stats.current_hp, player.stats.max_hp])
	var has_healing := false
	for item_id: String in player.inventory.stacks:
		if player.inventory.count(item_id) <= 0:
			continue
		var definition = ItemCatalogClass.get_definition(item_id)
		if (
			definition != null
			and definition.category == "consumable"
			and (definition.heal_hp > 0 or definition.heal_hp_percent > 0.0)
		):
			has_healing = true
			break
	if not has_healing:
		result.append("Brak mikstur lub prowiantu odnawiającego PŻ w plecaku.")
	var load := CarryWeightServiceClass.carry_status(player)
	if load.overloaded:
		result.append("PRZECIĄŻENIE: %.1f/%.1f kg." % [load.current_kg, load.capacity_kg])
	var injured: Array[String] = []
	for companion in session.party.companions:
		if companion.is_injured(session.day):
			injured.append(companion.display_name)
	if not injured.is_empty():
		result.append("Ciężko ranni kompani: %s." % ", ".join(injured))
	return result


static func departure_status(session, accept_warnings := false) -> Dictionary:
	var location_id: String = session.expedition_preparation.selected_location_id
	if location_id.is_empty():
		return _failure("Najpierw wybierz cel wyprawy.")
	if (
		not RegionCatalogClass.is_valid_region_id(location_id)
		or location_id not in session.known_region_ids
	):
		return _failure("Wybrany cel wyprawy nie jest dostępny.")
	var load := CarryWeightServiceClass.carry_status(session.player)
	if load.overloaded:
		return _failure(
			(
				"Nie możesz wyruszyć z przeciążonym plecakiem: %.1f/%.1f kg."
				% [load.current_kg, load.capacity_kg]
			)
		)
	var departure_warnings := warnings(session).filter(
		func(text: String) -> bool: return not text.begins_with("PRZECIĄŻENIE")
	)
	if not departure_warnings.is_empty() and not accept_warnings:
		return {
			"ok": false,
			"needs_confirmation": true,
			"message": "Wyprawa wymaga potwierdzenia ostrzeżeń.",
			"warnings": departure_warnings,
		}
	session.current_location_id = location_id
	var region = RegionCatalogClass.get_definition(location_id)
	session.last_activity = "Przygotowano wyprawę: %s." % region.display_name
	return {
		"ok": true,
		"message": "Drużyna jest gotowa do drogi.",
		"region_id": location_id,
		"warnings": departure_warnings,
	}


static func companion_summary(companion) -> Dictionary:
	var resources := CompanionBuildServiceClass.resolved_resources(companion)
	return {
		"display_name": companion.display_name,
		"current_hp": resources.current_hp,
		"max_hp": resources.max_hp,
		"current_mana": resources.current_mana,
		"max_mana": resources.max_mana,
		"tactic": companion.tactic_display_name(companion.tactic),
	}


static func _is_integer(value) -> bool:
	return (value is int or value is float) and is_equal_approx(float(value), floorf(float(value)))


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "needs_confirmation": false, "message": message}
