extends PanelContainer
signal operation_completed(result: Dictionary)
signal selection_changed(instance_id: String)
const Model := preload("res://ui/screens/blacksmith_workbench/upgrade_view_model.gd")
const ResourceTile := preload(
	"res://ui/components/required_resource_tile/required_resource_tile.tscn"
)
const Style := preload("res://ui/screens/blacksmith_workbench/workbench_style.gd")
var model := Model.new()

@onready var anvil: Control = %Anvil
@onready var action_button: Button = %UpgradeButton
@onready var comparison_label: RichTextLabel = %Comparison


func _ready() -> void:
	$Content/Heading.add_theme_font_override("font", Style.heading_font())
	%ItemName.add_theme_font_override("font", Style.heading_font())
	var details_style := Style.panel(0.94, 10)
	details_style.set_border_width_all(0)
	details_style.border_width_top = 1
	%UpgradeDetails.add_theme_stylebox_override("panel", details_style)
	%LevelRail.target_selected.connect(set_target_level)
	for button in [%MinusButton, %PlusButton]:
		for state in ["normal", "hover", "pressed", "disabled"]:
			var style := Style.panel(0.55, 4)
			if state == "hover":
				style.border_color = Style.GOLD
				style.bg_color = Color("#332617")
			button.add_theme_stylebox_override(state, style)
	resized.connect(queue_redraw)
	anvil.accepts_item = model.accepts
	anvil.item_dropped.connect(select_item)
	anvil.return_requested.connect(return_item)
	anvil.drag_state_changed.connect(_on_drag_state_changed)
	%MinusButton.pressed.connect(_step_target.bind(-1))
	%PlusButton.pressed.connect(_step_target.bind(1))
	action_button.pressed.connect(perform_upgrade)


func configure(session) -> void:
	model.session = session
	clear_selection()


func select_item(data: Dictionary) -> void:
	if not model.select(data):
		return
	refresh()
	selection_changed.emit(model.selected_id)


func set_target_level(level: int) -> void:
	model.set_target(level)
	refresh()


func _step_target(step: int) -> void:
	set_target_level(model.target_level + step)


func clear_selection() -> void:
	model.selected_id = ""
	refresh()
	selection_changed.emit("")


func accepts_return(data: Variant) -> bool:
	return (
		data is Dictionary
		and data.get("kind") == "forge_return"
		and data.get("anvil_id") == anvil.get_instance_id()
		and not model.selected_id.is_empty()
		and data.get("instance_id") == model.selected_id
		and not model.selection().is_empty()
	)


func return_item(data: Dictionary) -> void:
	if accepts_return(data):
		clear_selection()


func _on_drag_state_changed(_active: bool) -> void:
	refresh()


func refresh() -> void:
	var entry := model.selection()
	var has_item := not entry.is_empty()
	if not has_item and not model.selected_id.is_empty():
		model.selected_id = ""
		selection_changed.emit("")
	var maximum: bool = has_item and entry.item.upgrade_level == 10
	anvil.show_item(
		entry.item.definition.icon if has_item else null, entry.item.item_id if has_item else ""
	)
	anvil.return_payload = (
		{
			"kind": "forge_return",
			"instance_id": model.selected_id,
			"anvil_id": anvil.get_instance_id()
		}
		if has_item
		else {}
	)
	%LevelRail.configure(
		entry.item.upgrade_level if has_item else -1, model.target_level if has_item else -1
	)
	# Both layers overlay the fixed stage; visibility never participates in its layout.
	%LevelControls.visible = has_item
	%UpgradeDetails.visible = has_item
	%LevelRail.visible = has_item
	%ItemName.visible = has_item
	%ItemName.text = entry.item.formatted_name() if has_item else ""
	%ItemName.tooltip_text = %ItemName.text
	%ItemName.add_theme_color_override("font_color", Color(0.95, 0.80, 0.47))
	%TargetLabel.text = "Poziom ulepszenia"
	%MinusButton.disabled = not has_item or model.target_level <= entry.item.upgrade_level + 1
	%PlusButton.disabled = not has_item or model.target_level >= 10
	%Transition.text = (
		("+%d     →     +%d" % [entry.item.upgrade_level, model.target_level])
		if has_item and not maximum
		else "Maksymalny poziom +10" if maximum else ""
	)
	%Transition.tooltip_text = %Transition.text
	%Transition.visible = has_item and not maximum
	comparison_label.text = _comparison_text()
	comparison_label.visible = not comparison_label.text.is_empty()
	# Keep multi-stat upgrades readable; a longer comparison retains internal scrolling.
	comparison_label.custom_minimum_size.y = (
		26.0 * clampi(comparison_label.text.count("\n") + 1, 1, 3)
	)
	for tile in %Materials.get_children():
		%Materials.remove_child(tile)
		tile.queue_free()
	for resource: Dictionary in model.requirements():
		var tile = ResourceTile.instantiate()
		%Materials.add_child(tile)
		tile.configure(resource)
	%ResourceScroll.visible = has_item and not maximum
	var blocked := model.error()
	action_button.visible = has_item and not maximum
	action_button.disabled = not blocked.is_empty() or anvil.dragging
	action_button.text = (
		"Maksymalny poziom"
		if maximum
		else "Ulepsz do +%d" % model.target_level if has_item else "Ulepsz"
	)
	action_button.tooltip_text = blocked


func _draw() -> void:
	# Small corner engravings, scoped to this panel instead of the accepted equipment panel.
	var gold := Color(0.84, 0.65, 0.29, 0.8)
	for corner in [
		Vector2(6, 6), Vector2(size.x - 6, 6), Vector2(6, size.y - 6), size - Vector2(6, 6)
	]:
		var direction := Vector2(
			1 if corner.x < size.x * 0.5 else -1, 1 if corner.y < size.y * 0.5 else -1
		)
		draw_line(corner, corner + Vector2(16 * direction.x, 0), gold, 1.5, true)
		draw_line(corner, corner + Vector2(0, 16 * direction.y), gold, 1.5, true)
		draw_line(
			corner + Vector2(3, 3) * direction, corner + Vector2(9, 9) * direction, gold, 2, true
		)


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
	if lines.is_empty():
		return ""
	return "[center]" + "\n".join(lines) + "[/center]"


func _number(value: float, stat: String) -> String:
	return "%.1f%%" % value if stat == "dodge" else str(roundi(value))


func perform_upgrade() -> void:
	if anvil.dragging:
		return
	var result := model.execute()
	if result.ok:
		model.set_target(model.target_level + 1)
	refresh()
	operation_completed.emit(result)
