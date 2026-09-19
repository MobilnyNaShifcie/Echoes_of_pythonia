extends RefCounted
## Combat-local use of the shared dark/gold UI contract; no domain state.
const Style := preload("res://ui/presentation/interface_style.gd")
const GOLD := Color(0.85, 0.68, 0.34)
const INK := Color(0.025, 0.04, 0.055, 0.94)


static func surface(accent := GOLD) -> StyleBoxFlat:
	var box := Style.panel(0.94, Color(accent, 0.65))
	box.bg_color = INK
	box.set_corner_radius_all(4)
	box.border_width_top = 2
	return box


static func heading(label: Label, font_size := 26) -> void:
	var font := SystemFont.new()
	font.font_names = PackedStringArray(["Georgia", "Noto Serif", "DejaVu Serif"])
	label.add_theme_font_override("font", font)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color(0.96, 0.87, 0.66))
	label.add_theme_color_override("font_outline_color", Color(0.02, 0.025, 0.035))
	label.add_theme_constant_override("outline_size", 2)
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS


static func button(control: Button, primary := false) -> void:
	var normal := surface()
	normal.content_margin_top = 8
	normal.content_margin_bottom = 8
	if primary:
		normal.bg_color = Color(0.27, 0.19, 0.08, 0.97)
	control.add_theme_stylebox_override("normal", normal)
	control.add_theme_font_size_override("font_size", 20)
	Style.button_feedback(control)
	var disabled := normal.duplicate() as StyleBoxFlat
	disabled.border_color = Color(0.35, 0.32, 0.26, 0.7)
	disabled.bg_color = Color(0.06, 0.065, 0.07, 0.94)
	control.add_theme_stylebox_override("disabled", disabled)


static func apply(screen: Control) -> void:
	for path: String in [
		"Page/Arena/PlayerPanel",
		"Page/Arena/EnemyPanel",
		"Page/Arena/TurnQueueBackdrop",
		"Page/Lower/PlayerCommandHud",
		"Page/Lower/ActionsDock",
		"Page/Arena/LogPanel"
	]:
		screen.get_node(path).add_theme_stylebox_override("panel", surface())
	screen.result_panel.add_theme_stylebox_override("panel", surface())
	screen.fate_panel.add_theme_stylebox_override("panel", surface(Color(0.71, 0.46, 0.62)))
	for label: Label in [screen.player_name_label, screen.enemy_name_label]:
		heading(label, 27)
	heading(screen.result_title_label, 32)
	heading(screen.command_class_label, 23)
	screen.command_class_label.custom_minimum_size.y = 32
	screen.result_label.add_theme_font_size_override("font_size", 22)
	screen.result_label.add_theme_color_override("font_color", Color(0.92, 0.92, 0.86))
	for control: Button in [
		screen.attack_button,
		screen.defend_button,
		screen.flee_button,
		screen.potion_button,
		screen.continue_button,
		screen.log_toggle_button,
		screen.motion_toggle_button,
		screen.scroll_previous_button,
		screen.scroll_next_button,
		screen.weave_toggle_button,
		screen.double_weave_button
	]:
		button(control, control in [screen.attack_button, screen.continue_button])
	for control: Button in [screen.log_toggle_button, screen.motion_toggle_button]:
		control.add_theme_font_size_override("font_size", 17)
	for bar: ProgressBar in [screen.player_hp_bar, screen.enemy_hp_bar, screen.player_mana_bar]:
		var background := surface(Color(0.54, 0.44, 0.28))
		background.set_border_width_all(1)
		background.content_margin_top = 0
		background.content_margin_bottom = 0
		bar.add_theme_stylebox_override("background", background)
		bar.custom_minimum_size.y = 10 if bar == screen.player_mana_bar else 18


static func refresh(screen: Control) -> void:
	# Absence of an effect is not a warning. Keep actual statuses and their full tooltip.
	for label: Label in [screen.player_effect_label, screen.enemy_effect_label]:
		label.visible = label.text != "STATUS: —" and not label.text.is_empty()
		label.tooltip_text = label.text
	for label: Label in [screen.player_name_label, screen.enemy_name_label]:
		if label == screen.player_name_label:
			label.tooltip_text = label.text
		elif not label.tooltip_text.contains(label.text):
			label.tooltip_text = label.text + "\n" + label.tooltip_text
