class_name ExpeditionPreparationSaveCodec
extends RefCounted

const ExpeditionPreparationStateClass := preload("res://core/world/expedition_preparation_state.gd")
const ExpeditionPresetClass := preload("res://core/world/expedition_preset.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")


static func empty_data() -> Dictionary:
	var presets := {}
	for preset_id: String in ExpeditionPreparationStateClass.PRESET_ORDER:
		presets[preset_id] = {
			"preset_id": preset_id,
			"configured": false,
			"active_companion_ids": [],
			"supplies": {},
		}
	return {"selected_location_id": "", "presets": presets}


static func serialize(state) -> Dictionary:
	var presets := {}
	for preset_id: String in ExpeditionPreparationStateClass.PRESET_ORDER:
		var preset = state.preset_for(preset_id)
		presets[preset_id] = {
			"preset_id": preset_id,
			"configured": preset.configured,
			"active_companion_ids": preset.active_companion_ids.duplicate(),
			"supplies": preset.supplies.duplicate(true),
		}
	return {"selected_location_id": state.selected_location_id, "presets": presets}


static func deserialize(data: Dictionary, known_region_ids: Array) -> Dictionary:
	if not data.get("selected_location_id") is String or not data.get("presets") is Dictionary:
		return _failure("Nieprawidłowy stan przygotowania wyprawy.")
	var selected_location_id := str(data.selected_location_id)
	if (
		not selected_location_id.is_empty()
		and (
			not RegionCatalogClass.is_valid_region_id(selected_location_id)
			or selected_location_id not in known_region_ids
		)
	):
		return _failure("Zapis wskazuje niedostępny cel wyprawy.")
	if data.presets.size() != ExpeditionPreparationStateClass.PRESET_ORDER.size():
		return _failure("Zapis nie zawiera czterech presetów wyprawowych.")

	var state := ExpeditionPreparationStateClass.new()
	state.selected_location_id = selected_location_id
	for preset_id: String in ExpeditionPreparationStateClass.PRESET_ORDER:
		if not data.presets.get(preset_id) is Dictionary:
			return _failure("Zapis nie zawiera presetu %s." % preset_id)
		var raw: Dictionary = data.presets[preset_id]
		if (
			str(raw.get("preset_id", "")) != preset_id
			or not raw.get("configured") is bool
			or not raw.get("active_companion_ids") is Array
			or not raw.get("supplies") is Dictionary
		):
			return _failure("Preset %s ma nieprawidłową strukturę." % preset_id)
		var preset := ExpeditionPresetClass.new(preset_id)
		preset.configured = raw.configured
		var seen_companions := {}
		for companion_id_value in raw.active_companion_ids:
			if not companion_id_value is String:
				return _failure("Preset zawiera nieprawidłowy identyfikator kompana.")
			var companion_id := str(companion_id_value)
			if companion_id.is_empty() or seen_companions.has(companion_id):
				return _failure("Preset zawiera pustego albo powtórzonego kompana.")
			seen_companions[companion_id] = true
			preset.active_companion_ids.append(companion_id)
		if (
			preset.active_companion_ids.size() > 3
			or (preset_id == "solo" and not preset.active_companion_ids.is_empty())
		):
			return _failure("Preset ma nieprawidłowy skład drużyny.")
		for item_id_value in raw.supplies:
			var item_id := str(item_id_value)
			var definition = ItemCatalogClass.get_definition(item_id)
			var quantity_value = raw.supplies[item_id_value]
			if (
				definition == null
				or definition.category != "consumable"
				or not _is_positive_integer(quantity_value)
			):
				return _failure("Preset zawiera nieprawidłowy zapas.")
			preset.supplies[item_id] = int(quantity_value)
		if (
			not preset.configured
			and (not preset.active_companion_ids.is_empty() or not preset.supplies.is_empty())
		):
			return _failure("Nieskonfigurowany preset nie może przechowywać zawartości.")
		state.presets[preset_id] = preset
	return {"ok": true, "state": state}


static func _is_positive_integer(value) -> bool:
	return (
		(value is int or value is float)
		and is_equal_approx(float(value), floorf(float(value)))
		and int(value) > 0
	)


static func _failure(message: String) -> Dictionary:
	return {"ok": false, "message": message}
