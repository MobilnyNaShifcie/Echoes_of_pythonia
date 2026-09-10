extends Node
const Style := preload("res://ui/presentation/interface_style.gd")
var screen: Control


func configure(owner_screen: Control) -> void:
	screen = owner_screen
	screen.resized.connect(refresh)
	screen.rank_label.hide()
	Style.heading(screen.get_node("Page/Header/Identity/Title"), 27)
	screen.rank_progress_label.add_theme_font_size_override("font_size", 15)
	screen.rank_progress_label.add_theme_constant_override("outline_size", 4)
	screen.quest_list.custom_minimum_size = Vector2(0, 170)
	screen.quest_list.add_theme_font_size_override("font_size", 16)
	screen.quest_list.add_theme_constant_override("v_separation", 12)
	screen.quest_list.add_theme_stylebox_override("panel", StyleBoxEmpty.new())
	screen.quest_list.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
	screen.quest_list.add_theme_stylebox_override(
		"selected", Style.panel(0.95, Color(0.77, 0.63, 0.32))
	)
	screen.quest_list.add_theme_stylebox_override(
		"selected_focus", Style.panel(0.95, Color(0.77, 0.63, 0.32))
	)
	screen.get_node("Page/Body/BoardPanel").custom_minimum_size.x = 300
	screen.get_node("Page/Body/BoardPanel").size_flags_stretch_ratio = 0.8
	screen.get_node("Page/Body/QuestPanel").custom_minimum_size.x = 440
	screen.arc_label.hide()
	screen.chapter_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.quest_title_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.board_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	for panel in [
		screen.guild_action_panel,
		screen.get_node("Page/Body/BoardPanel"),
		screen.get_node("Page/Body/QuestPanel")
	]:
		panel.add_theme_stylebox_override("panel", Style.panel())
	for button in screen.board_tabs.get_children():
		if button is Button:
			Style.quiet_button(button)
	screen.get_node("%CloseBoardButton").custom_minimum_size.x = 110
	screen.get_node("%CloseBoardButton").text = "Zamknij"
	Style.quiet_button(screen.get_node("%BackButton"))
	Style.quiet_button(screen.action_button)
	for button in screen.guild_action_panel.get_node("Content").get_children():
		if button is Button:
			Style.quiet_button(button)
	refresh.call_deferred()


func refresh() -> void:
	if not screen.is_node_ready():
		return
	var bounds := screen.size
	_rect(screen.hall_presentation, Rect2(Vector2.ZERO, bounds))
	_rect(screen.get_node("Page/Header"), Rect2(24, 15, bounds.x - 48, 72))
	var width := minf(1000, bounds.x - 48)
	var left := bounds.x - width - 24
	var top := maxf(160, bounds.y * 0.20)
	_rect(screen.board_tabs, Rect2(left, top - 48, width, 40))
	_rect(screen.board_body, Rect2(left, top, width, minf(560, bounds.y - top - 90)))
	_rect(screen.result_label, Rect2(left, bounds.y - 72, width, 60))
	_rect(screen.guild_action_panel, Rect2(bounds.x - 466, bounds.y * 0.32, 442, 370))
	screen._queue_hall_art_update()


func _rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
