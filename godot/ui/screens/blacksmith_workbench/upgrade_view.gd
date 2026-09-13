extends PanelContainer
signal operation_completed(result: Dictionary)
signal selection_changed(instance_id: String)
const Model := preload("res://ui/screens/blacksmith_workbench/upgrade_view_model.gd")
const ResourceTile := preload(
	"res://ui/components/required_resource_tile/required_resource_tile.tscn"
)
const Palette := preload("res://ui/presentation/item_rarity_palette.gd")
var model := Model.new()

@onready var anvil: Control = %Anvil
@onready var action_button: Button = %UpgradeButton
@onready var comparison_label: RichTextLabel = %Comparison


func _ready() -> void:
	anvil.accepts_item = model.accepts
	anvil.item_dropped.connect(select_item)
	%MinusButton.pressed.connect(_step_target.bind(-1))
	%PlusButton.pressed.connect(_step_target.bind(1))
	%ClearButton.pressed.connect(_clear)
	action_button.pressed.connect(perform_upgrade)


func configure(session) -> void:
	model.session = session
	_clear()


func select_item(data: Dictionary) -> void:
	if not model.select(data):
		return
	%Result.text = ""
	refresh()
	selection_changed.emit(model.selected_id)


func set_target_level(level: int) -> void:
	model.set_target(level)
	%Result.text = ""
	refresh()


func _step_target(step: int) -> void:
	set_target_level(model.target_level + step)


func _clear() -> void:
	model.selected_id = ""
	%Result.text = ""
	refresh()
	selection_changed.emit("")


func refresh() -> void:
	var entry := model.selection()
	var has_item := not entry.is_empty()
	var maximum: bool = has_item and entry.item.upgrade_level == 10
	anvil.show_item(entry.item.definition.icon if has_item else null)
	%Source.text = "Źródło: " + entry.source if has_item else ""
	%ClearButton.visible = has_item
	%ItemName.text = entry.item.formatted_name() if has_item else "Umieść przedmiot do ulepszenia"
	%ItemName.add_theme_color_override(
		"font_color",
		Palette.color_for(entry.item.definition.rarity) if has_item else Color(0.92, 0.85, 0.69)
	)
	%TargetLabel.text = (
		"Poziom docelowy: +%d" % model.target_level if has_item else "Poziom docelowy: —"
	)
	%MinusButton.disabled = not has_item or model.target_level <= entry.item.upgrade_level + 1
	%PlusButton.disabled = not has_item or model.target_level >= 10
	%Transition.text = (
		(
			"%s +%d  →  %s +%d"
			% [
				entry.item.display_name,
				entry.item.upgrade_level,
				entry.item.display_name,
				model.target_level
			]
		)
		if has_item and not maximum
		else "Maksymalny poziom +10" if maximum else ""
	)
	%Transition.tooltip_text = %Transition.text
	comparison_label.text = _comparison_text()
	for tile in %Materials.get_children():
		%Materials.remove_child(tile)
		tile.queue_free()
	for resource: Dictionary in model.requirements():
		var tile = ResourceTile.instantiate()
		%Materials.add_child(tile)
		tile.configure(resource)
	%NoRequirements.visible = not has_item or maximum
	%NoRequirements.text = (
		"Wybierz przedmiot, aby poznać koszt."
		if not has_item
		else "Przedmiot jest w pełni ulepszony."
	)
	var blocked := model.error()
	action_button.disabled = not blocked.is_empty()
	action_button.text = (
		"Maksymalny poziom"
		if maximum
		else "Ulepsz do +%d" % model.target_level if has_item else "Ulepsz"
	)
	action_button.tooltip_text = blocked
	%BlockReason.text = blocked if has_item and not maximum else ""
	%BlockReason.tooltip_text = %BlockReason.text
	%BlockReason.visible = not %BlockReason.text.is_empty()
	%Result.visible = not %Result.text.is_empty()


func _comparison_text() -> String:
	var lines: Array[String] = []
	for stat: Dictionary in model.comparison():
		(
			lines
			. append(
				(
					"%s   %s  →  [color=#79df96]%s  (+%s)[/color]"
					% [
						stat.name,
						_number(stat.before, stat.stat),
						_number(stat.after, stat.stat),
						_number(stat.delta, stat.stat),
					]
				)
			)
		)
	if lines.is_empty() and model.plan().ok:
		return "[center][color=#b8b1a1]Na tym poziomie statystyki pozostają bez zmian.[/color][/center]"
	return "[center]" + "\n".join(lines) + "[/center]"


func _number(value: float, stat: String) -> String:
	return "%.1f%%" % value if stat == "dodge" else str(roundi(value))


func perform_upgrade() -> void:
	var result := model.execute()
	%Result.text = result.message
	%Result.add_theme_color_override(
		"font_color", Color(0.48, 0.87, 0.59) if result.ok else Color(1, 0.43, 0.37)
	)
	if result.ok:
		model.set_target(model.target_level + 1)
	refresh()
	operation_completed.emit(result)
