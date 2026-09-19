extends HBoxContainer
## Native buttons keep level selection keyboard-accessible; the rail only previews a target.
signal target_selected(level: int)
const GOLD := Color("#f3cb70")
var current_level := -1
var target_level := -1
var buttons: Array[Button] = []


func _ready() -> void:
	add_theme_constant_override("separation", 0)
	for level in range(11):
		var button := Button.new()
		button.name = "Level%d" % level
		button.custom_minimum_size = Vector2(34, 58)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
		for state in ["normal", "hover", "pressed", "disabled"]:
			button.add_theme_stylebox_override(state, StyleBoxEmpty.new())
		button.pressed.connect(_select.bind(level))
		buttons.append(button)
		add_child(button)
	resized.connect(queue_redraw)
	configure(-1, -1)


func configure(current: int, target: int) -> void:
	current_level = current
	target_level = target
	for level in range(buttons.size()):
		var button := buttons[level]
		button.disabled = current < 0 or level <= current
		var highlighted := level == current or level == target
		button.text = "+%d\n%s" % [level, "◆" if highlighted else "◇"]
		var color := GOLD if highlighted else Color("#a09c92")
		button.add_theme_color_override("font_color", color)
		button.add_theme_color_override("font_disabled_color", color)
		button.add_theme_color_override("font_hover_color", GOLD.lightened(0.3))
		button.add_theme_color_override("font_focus_color", GOLD)
		button.tooltip_text = (
			"Bieżący poziom +%d" % level
			if level == current
			else "Docelowy poziom +%d — podgląd kosztów" % level
		)
	queue_redraw()


func _select(level: int) -> void:
	if current_level >= 0 and level > current_level and level <= 10:
		target_selected.emit(level)


func _draw() -> void:
	if buttons.size() != 11:
		return
	var first := buttons[0].size.x * 0.5
	var last := size.x - buttons[-1].size.x * 0.5
	var y := size.y * 0.69
	draw_line(Vector2(first, y), Vector2(last, y), Color("#706657"), 1.0, true)
	for level in [current_level, target_level]:
		if level < 0:
			continue
		var point := Vector2(buttons[level].position.x + buttons[level].size.x * 0.5, y)
		for radius in range(18, 8, -2):
			draw_circle(point, radius, Color(1, 0.63, 0.13, 0.025))
