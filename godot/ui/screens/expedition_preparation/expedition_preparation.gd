class_name ExpeditionPreparationScreen
extends Control

signal back_requested
signal party_requested
signal equipment_requested
signal storage_requested
signal inn_requested
signal departure_requested(region_id: String)
signal state_changed

const CarryWeightServiceClass := preload("res://core/economy/carry_weight_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const ExpeditionPreparationServiceClass := preload(
	"res://core/world/expedition_preparation_service.gd"
)
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")

var _session: GameSessionClass
var _preset_supply_targets := {}
var _confirm_departure := false

@onready var target_selector: OptionButton = %TargetSelector
@onready var player_label: Label = %PlayerLabel
@onready var carry_label: Label = %CarryLabel
@onready var party_label: Label = %PartyLabel
@onready var supply_selector: OptionButton = %SupplySelector
@onready var supply_summary_label: Label = %SupplySummaryLabel
@onready var withdraw_quantity: SpinBox = %WithdrawQuantity
@onready var target_quantity: SpinBox = %TargetQuantity
@onready var preset_selector: OptionButton = %PresetSelector
@onready var preset_summary_label: Label = %PresetSummaryLabel
@onready var warnings_label: Label = %WarningsLabel
@onready var status_label: Label = %StatusLabel
@onready var depart_button: Button = %DepartButton


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	%PartyButton.pressed.connect(party_requested.emit)
	%EquipmentButton.pressed.connect(equipment_requested.emit)
	%StorageButton.pressed.connect(storage_requested.emit)
	%InnButton.pressed.connect(inn_requested.emit)
	%WithdrawButton.pressed.connect(_withdraw_supply)
	%UseButton.pressed.connect(_use_supply)
	%SetTargetButton.pressed.connect(_set_supply_target)
	%SavePresetButton.pressed.connect(_save_preset)
	%ApplyPresetButton.pressed.connect(_apply_preset)
	%ClearPresetButton.pressed.connect(_clear_preset)
	depart_button.pressed.connect(_depart)
	target_selector.item_selected.connect(_select_target)
	supply_selector.item_selected.connect(_select_supply)
	preset_selector.item_selected.connect(_select_preset)
	_render()
	target_selector.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _select_target(index: int) -> void:
	if _session == null:
		return
	var location_id := str(target_selector.get_item_metadata(index))
	if location_id.is_empty():
		return
	var result := ExpeditionPreparationServiceClass.select_location(
		_session.expedition_preparation, location_id, _session.known_region_ids
	)
	status_label.text = result.message
	_confirm_departure = false
	if result.ok:
		state_changed.emit()
	_render_status()


func _select_supply(_index: int) -> void:
	_render_selected_supply()


func _select_preset(_index: int) -> void:
	_load_preset_draft()
	_render_preset()


func _withdraw_supply() -> void:
	var item_id := _selected_supply_id()
	if item_id.is_empty():
		status_label.text = "Wybierz zapas z listy."
		return
	var result := ExpeditionPreparationServiceClass.withdraw_supply(
		_session, item_id, int(withdraw_quantity.value)
	)
	status_label.text = result.message
	if result.ok:
		state_changed.emit()
	_render_dynamic()


func _use_supply() -> void:
	var item_id := _selected_supply_id()
	if item_id.is_empty():
		status_label.text = "Wybierz zapas z listy."
		return
	var result := ExpeditionPreparationServiceClass.use_supply(_session, item_id)
	status_label.text = result.message
	if result.ok:
		var effects: Array[String] = []
		if result.healed_hp > 0:
			effects.append("+%d PŻ" % result.healed_hp)
		if result.restored_mana > 0:
			effects.append("+%d Many" % result.restored_mana)
		status_label.text += " " + ", ".join(effects) + "."
		state_changed.emit()
	_render_dynamic()


func _set_supply_target() -> void:
	var item_id := _selected_supply_id()
	if item_id.is_empty():
		status_label.text = "Wybierz zapas z listy."
		return
	var quantity := int(target_quantity.value)
	if quantity <= 0:
		_preset_supply_targets.erase(item_id)
	else:
		_preset_supply_targets[item_id] = quantity
	status_label.text = "Zmieniono roboczą ilość zapasu. Zapisz preset, aby ją zachować."
	_render_preset()


func _save_preset() -> void:
	var result := (
		ExpeditionPreparationServiceClass
		. save_preset(
			_session.expedition_preparation,
			_selected_preset_id(),
			_session.party,
			_preset_supply_targets,
			_session.day,
		)
	)
	status_label.text = result.message
	if result.ok:
		state_changed.emit()
	_refresh_preset_selector()
	_render_preset()


func _apply_preset() -> void:
	var result := ExpeditionPreparationServiceClass.apply_preset(_session, _selected_preset_id())
	status_label.text = _format_apply_result(result)
	if result.ok:
		state_changed.emit()
	_render_dynamic()


func _clear_preset() -> void:
	var result := ExpeditionPreparationServiceClass.clear_preset(
		_session.expedition_preparation, _selected_preset_id()
	)
	status_label.text = result.message
	if result.ok:
		_preset_supply_targets.clear()
		state_changed.emit()
	_refresh_preset_selector()
	_render_preset()


func _depart() -> void:
	var result := ExpeditionPreparationServiceClass.departure_status(_session, _confirm_departure)
	if result.get("needs_confirmation", false):
		_confirm_departure = true
		status_label.text = (
			"Potwierdź ponownie, aby wyruszyć mimo ostrzeżeń:\n• " + "\n• ".join(result.warnings)
		)
		depart_button.text = "Wyrusz mimo ostrzeżeń"
		return
	status_label.text = result.message
	if not result.ok:
		_confirm_departure = false
		_render_status()
		return
	state_changed.emit()
	departure_requested.emit(result.region_id)


func _render() -> void:
	if _session == null:
		return
	_refresh_target_selector()
	_refresh_preset_selector()
	_refresh_supply_selector()
	_load_preset_draft()
	_render_dynamic()


func _render_dynamic() -> void:
	if _session == null:
		return
	var player := _session.player
	var load := CarryWeightServiceClass.carry_status(player)
	player_label.text = (
		"%s  •  Poziom %d\nPŻ %d/%d  •  Mana %d/%d"
		% [
			player.display_name,
			player.level,
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.current_mana,
			player.stats.max_mana,
		]
	)
	carry_label.text = (
		"Udźwig %.1f/%.1f kg  •  %s" % [load.current_kg, load.capacity_kg, load.display_name]
	)
	carry_label.modulate = Color(0.9, 0.35, 0.35) if load.overloaded else Color(0.72, 0.79, 0.87)
	party_label.text = _format_party()
	_refresh_supply_selector()
	_render_selected_supply()
	_render_preset()
	warnings_label.text = _format_warnings()
	_render_status()


func _refresh_target_selector() -> void:
	target_selector.clear()
	target_selector.add_item("Wybierz cel wyprawy")
	target_selector.set_item_metadata(0, "")
	var selected_index := 0
	for region_id: String in _session.known_region_ids:
		var region = RegionCatalogClass.get_definition(region_id)
		if region == null:
			continue
		target_selector.add_item(
			"%s  •  poziom %s" % [region.display_name, region.recommended_level_text()]
		)
		var index := target_selector.item_count - 1
		target_selector.set_item_metadata(index, region_id)
		if region_id == _session.expedition_preparation.selected_location_id:
			selected_index = index
	target_selector.select(selected_index)


func _refresh_preset_selector() -> void:
	var previous_id := _selected_preset_id()
	preset_selector.clear()
	var selected_index := 0
	for preset_id: String in ExpeditionPreparationServiceClass.PRESET_ORDER:
		var preset = _session.expedition_preparation.preset_for(preset_id)
		var suffix := "GOTOWY" if preset.configured else "NIESKONFIGUROWANY"
		preset_selector.add_item(
			"%s  •  %s" % [ExpeditionPreparationServiceClass.PRESET_NAMES[preset_id], suffix]
		)
		var index := preset_selector.item_count - 1
		preset_selector.set_item_metadata(index, preset_id)
		if preset_id == previous_id:
			selected_index = index
	preset_selector.select(selected_index)


func _refresh_supply_selector() -> void:
	var previous_id := _selected_supply_id()
	supply_selector.clear()
	var selected_index := 0
	var supply_ids := ExpeditionPreparationServiceClass.available_supply_ids(
		_session.player, _session.guild_storage
	)
	for item_id: String in supply_ids:
		var definition = ItemCatalogClass.get_definition(item_id)
		(
			supply_selector
			. add_item(
				(
					"%s  •  plecak %d  •  magazyn %d"
					% [
						definition.display_name,
						_session.player.inventory.count(item_id),
						_session.guild_storage.inventory.count(item_id),
					]
				)
			)
		)
		var index := supply_selector.item_count - 1
		supply_selector.set_item_metadata(index, item_id)
		if item_id == previous_id:
			selected_index = index
	if supply_selector.item_count > 0:
		supply_selector.select(selected_index)


func _render_selected_supply() -> void:
	var item_id := _selected_supply_id()
	if item_id.is_empty():
		supply_summary_label.text = "Brak przedmiotów użytkowych w plecaku i Magazynie."
		return
	var definition = ItemCatalogClass.get_definition(item_id)
	var effects: Array[String] = []
	if definition.heal_hp > 0:
		effects.append("+%d PŻ" % definition.heal_hp)
	if definition.heal_hp_percent > 0.0:
		effects.append("+%.0f%% PŻ" % definition.heal_hp_percent)
	if definition.restore_mana > 0:
		effects.append("+%d Many" % definition.restore_mana)
	if definition.restore_mana_percent > 0.0:
		effects.append("+%.0f%% Many" % definition.restore_mana_percent)
	supply_summary_label.text = (
		definition.description
		+ ("\nEfekt: " + ", ".join(effects) if not effects.is_empty() else "")
	)
	target_quantity.value = int(_preset_supply_targets.get(item_id, 0))


func _load_preset_draft() -> void:
	_preset_supply_targets.clear()
	var preset = _session.expedition_preparation.preset_for(_selected_preset_id())
	if preset != null and preset.configured:
		_preset_supply_targets = preset.supplies.duplicate(true)
	_render_selected_supply()


func _render_preset() -> void:
	var preset_id := _selected_preset_id()
	var preset = _session.expedition_preparation.preset_for(preset_id)
	var lines: Array[String] = []
	if preset != null and preset.configured:
		lines.append(
			(
				"Zapisany skład: %s"
				% (
					"SOLO"
					if preset.active_companion_ids.is_empty()
					else "%d kompanów" % preset.active_companion_ids.size()
				)
			)
		)
	else:
		lines.append("Preset nie został jeszcze skonfigurowany.")
	lines.append("Robocze zapasy docelowe:")
	if _preset_supply_targets.is_empty():
		lines.append("• brak")
	else:
		var item_ids: Array[String] = []
		item_ids.assign(_preset_supply_targets.keys())
		item_ids.sort()
		for item_id: String in item_ids:
			var definition = ItemCatalogClass.get_definition(item_id)
			lines.append("• %s ×%d" % [definition.display_name, _preset_supply_targets[item_id]])
	preset_summary_label.text = "\n".join(lines)


func _format_party() -> String:
	var active := _session.party.active_companions(_session.day)
	var lines: Array[String] = [
		(
			"Tryb: %s  •  Aktywni kompani: %d/3"
			% ["DRUŻYNA" if not active.is_empty() else "SOLO", active.size()]
		)
	]
	for companion: CompanionStateClass in active:
		var summary := ExpeditionPreparationServiceClass.companion_summary(companion)
		(
			lines
			. append(
				(
					"• %s  •  PŻ %d/%d  •  Mana %d/%d  •  %s"
					% [
						summary.display_name,
						summary.current_hp,
						summary.max_hp,
						summary.current_mana,
						summary.max_mana,
						summary.tactic,
					]
				)
			)
		)
	return "\n".join(lines)


func _format_warnings() -> String:
	var values := ExpeditionPreparationServiceClass.warnings(_session)
	if values.is_empty():
		return "Brak ostrzeżeń. Drużyna jest gotowa."
	return "• " + "\n• ".join(values)


func _render_status() -> void:
	depart_button.text = (
		"Wyrusz mimo ostrzeżeń" if _confirm_departure else "Wyrusz do wybranego regionu"
	)


func _selected_supply_id() -> String:
	if supply_selector == null or supply_selector.item_count == 0:
		return ""
	return str(supply_selector.get_item_metadata(supply_selector.selected))


func _selected_preset_id() -> String:
	if preset_selector == null or preset_selector.item_count == 0:
		return "solo"
	return str(preset_selector.get_item_metadata(preset_selector.selected))


func _format_apply_result(result: Dictionary) -> String:
	if not result.ok:
		return result.message
	var lines: Array[String] = [result.message]
	if not result.activated_companions.is_empty():
		lines.append("Aktywni: %s." % ", ".join(result.activated_companions))
	if not result.withdrawn.is_empty():
		lines.append("Uzupełniono %d rodzajów zapasów." % result.withdrawn.size())
	if not result.missing.is_empty():
		lines.append("Magazyn nie pokrył %d braków." % result.missing.size())
	if not result.unavailable_companions.is_empty():
		lines.append("Niedostępni: %s." % ", ".join(result.unavailable_companions))
	return " ".join(lines)
