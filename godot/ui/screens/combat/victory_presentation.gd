extends Control
## Read-only victory view. Receives the already-resolved reward receipt exactly once.
const VictorySkin := preload("res://ui/screens/combat/victory_skin.gd")
const Style := preload("res://ui/screens/combat/combat_visual_style.gd")
const Items := preload("res://core/items/item_catalog.gd")
const Regions := preload("res://core/world/region_catalog.gd")
const GOLD := preload("res://assets/ui/blacksmith/gold_stack.svg")
const DESIGN_SIZE := Vector2(1920, 1080)

var canvas := Control.new()
var region_label: Label
var hero_name: Label
var experience_label: Label
var gold_label: Label
var achievement_label: Label
var achievement_strip: TextureRect
var medal: TextureRect
var rewards_strip: TextureRect
var loot_heading: TextureRect
var loot_scroll := ScrollContainer.new()
var loot_grid := GridContainer.new()
var report_button := Button.new()
var report_panel := PanelContainer.new()
var report_text := RichTextLabel.new()
var _continue: Button
var _continue_parent: Node
var _continue_font: Font


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(canvas)
	canvas.size = DESIGN_SIZE
	_art(canvas, "banner", Rect2(590, 8, 1250, 410))
	_label(canvas, "ZWYCIĘSTWO", Rect2(790, 129, 850, 113), 87)
	region_label = _label(canvas, "", Rect2(835, 244, 760, 45), 32)
	rewards_strip = _art(canvas, "rewards", Rect2(822, 308, 796, 115))
	_art(rewards_strip, "medal", Rect2(48, 13, 64, 87))
	experience_label = _label(rewards_strip, "", Rect2(116, 17, 296, 78), 43)
	var coin := _image(rewards_strip, GOLD, Rect2(464, 19, 92, 76))
	coin.tooltip_text = "Złoto"
	coin.mouse_filter = Control.MOUSE_FILTER_PASS
	gold_label = _label(rewards_strip, "", Rect2(557, 17, 192, 78), 43)
	loot_heading = _art(canvas, "plaque", Rect2(940, 440, 560, 80))
	_label(loot_heading, "ZDOBYTY ŁUP", Rect2(88, 7, 385, 64), 32)
	canvas.add_child(loot_scroll)
	_place(loot_scroll, Rect2(793, 529, 854, 226))
	loot_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	loot_scroll.follow_focus = true
	var centering := CenterContainer.new()
	centering.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	centering.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	loot_scroll.add_child(centering)
	centering.add_child(loot_grid)
	loot_grid.add_theme_constant_override("h_separation", 18)
	loot_grid.add_theme_constant_override("v_separation", 14)
	achievement_strip = _art(canvas, "achievement", Rect2(807, 799, 827, 110))
	medal = _art(canvas, "medal", Rect2(915, 776, 112, 140))
	achievement_label = _label(canvas, "", Rect2(1040, 810, 502, 88), 32)
	var nameplate := _art(canvas, "plaque", Rect2(180, 981, 380, 62))
	hero_name = _label(nameplate, "", Rect2(65, 4, 250, 48), 28)
	canvas.add_child(report_panel)
	_place(report_panel, Rect2(812, 443, 812, 462))
	report_panel.add_theme_stylebox_override("panel", Style.surface())
	report_panel.add_child(report_text)
	report_text.add_theme_font_size_override("normal_font_size", 24)
	report_text.bbcode_enabled = false
	report_text.scroll_following = false
	report_text.selection_enabled = true
	report_panel.hide()
	canvas.add_child(report_button)
	_place(report_button, Rect2(1650, 992, 226, 48))
	Style.button(report_button)
	report_button.text = "Raport walki"
	report_button.toggle_mode = true
	report_button.toggled.connect(_toggle_report)
	resized.connect(fit_canvas)
	fit_canvas()


func present(receipt: Dictionary, region: String, name_text: String, report: String) -> void:
	region_label.text = region
	region_label.tooltip_text = region
	hero_name.text = name_text.to_upper()
	hero_name.tooltip_text = name_text
	experience_label.text = "+%d EXP" % int(receipt.get("experience", 0))
	experience_label.tooltip_text = experience_label.text
	gold_label.text = "+%d" % int(receipt.get("gold", 0))
	gold_label.tooltip_text = "%d złota" % int(receipt.get("gold", 0))
	rewards_strip.visible = receipt.has("experience") or receipt.has("gold")
	set_drops(receipt.get("loot_drops", []))
	var achievements: Array = receipt.get("unlocked_achievements", [])
	achievement_strip.visible = (
		not achievements.is_empty() or int(receipt.get("levels_gained", 0)) > 0
	)
	medal.visible = achievement_strip.visible
	achievement_label.visible = achievement_strip.visible
	var titles: PackedStringArray = []
	for achievement in achievements:
		titles.append("%s\nTytuł: %s" % [achievement.display_name, achievement.title])
	if not titles.is_empty():
		achievement_label.text = titles[0]
		if titles.size() > 1:
			achievement_label.text += "  (+%d)" % (titles.size() - 1)
	else:
		achievement_label.text = "Awans: +%d poziom" % int(receipt.get("levels_gained", 0))
	achievement_label.tooltip_text = "\n\n".join(titles)
	report_text.text = report
	report_text.scroll_to_line(0)
	report_button.set_pressed_no_signal(false)
	_toggle_report(false)
	show()
	fit_canvas()


func show_result(screen: Control) -> void:
	var region = Regions.get_definition(screen._presentation_region_id())
	var location: String = region.display_name if region != null else ""
	if screen._context == "prologue":
		location = "Prolog"
	elif not screen._battle_title.is_empty():
		location = screen._battle_title
	screen.result_panel.get_node("Result").hide()
	present(
		screen._victory_receipt,
		location,
		screen._session.player.display_name,
		screen.result_label.text + "\n\nPrzebieg walki\n" + screen.combat_log.get_parsed_text()
	)
	take_continue(screen.continue_button)
	screen._set_victory_stage(true)


func take_continue(button: Button) -> void:
	_continue = button
	_continue_parent = button.get_parent()
	_continue_font = button.get_theme_font("font")
	button.reparent(canvas)
	_place(button, Rect2(914, 932, 612, 114))
	VictorySkin.button(button)
	button.focus_neighbor_right = button.get_path_to(report_button)
	report_button.focus_neighbor_left = report_button.get_path_to(button)


func reset() -> void:
	if _continue != null:
		_continue.reparent(_continue_parent)
		_continue.focus_neighbor_right = NodePath()
		Style.button(_continue, true)
		_continue.add_theme_font_override("font", _continue_font)
		_continue = null
	hide()
	report_panel.hide()


func set_drops(drops: Array) -> void:
	for child in loot_grid.get_children():
		loot_grid.remove_child(child)
		child.queue_free()
	for drop: Dictionary in drops:
		var definition = Items.get_definition(str(drop.get("item_id", "")))
		if definition == null:
			continue
		var card := Control.new()
		card.custom_minimum_size = Vector2(268, 202)
		card.tooltip_text = (
			"%s ×%d\n\n%s"
			% [definition.display_name, int(drop.get("quantity", 1)), definition.description]
		)
		card.focus_mode = Control.FOCUS_ALL
		card.mouse_filter = Control.MOUSE_FILTER_STOP
		card.focus_entered.connect(func() -> void: card.modulate = Color(1.18, 1.13, 1.02))
		card.focus_exited.connect(func() -> void: card.modulate = Color.WHITE)
		loot_grid.add_child(card)
		_art(card, "loot", Rect2(0, 0, 268, 202))
		_image(card, definition.icon, Rect2(28, 17, 211, 129))
		var quantity := _label(
			card, "×%d" % int(drop.get("quantity", 1)), Rect2(196, 119, 48, 30), 24
		)
		var quantity_box := Style.surface()
		quantity_box.set_content_margin_all(0)
		quantity.add_theme_stylebox_override("normal", quantity_box)
		_label(card, definition.display_name, Rect2(18, 159, 232, 31), 24)
	loot_grid.columns = mini(3, maxi(1, loot_grid.get_child_count()))
	loot_heading.visible = loot_grid.get_child_count() > 0
	loot_scroll.visible = loot_heading.visible
	loot_scroll.scroll_vertical = 0


func fit_canvas() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	canvas.scale = Vector2.ONE * factor
	canvas.position = (size - DESIGN_SIZE * factor) * 0.5


func _unhandled_key_input(event: InputEvent) -> void:
	if is_visible_in_tree() and report_panel.visible and event.is_action_pressed("ui_cancel"):
		report_button.button_pressed = false
		get_viewport().set_input_as_handled()


func _toggle_report(open: bool) -> void:
	report_panel.visible = open
	report_button.text = "Zamknij raport" if open else "Raport walki"
	loot_scroll.visible = not open and loot_grid.get_child_count() > 0
	loot_heading.visible = loot_scroll.visible
	medal.visible = not open and achievement_strip.visible
	achievement_label.visible = medal.visible
	if not open and _continue != null:
		_continue.grab_focus()


static func _place(control: Control, rect: Rect2) -> void:
	control.position = rect.position
	control.size = rect.size


static func describe_rewards(rewards: Dictionary) -> String:
	var text := "Zwycięstwo  •  +%d EXP  •  +%d złota" % [rewards.experience, rewards.gold]
	if rewards.levels_gained > 0:
		text += "  •  Awans: +%d poziom" % rewards.levels_gained
	if not rewards.loot_names.is_empty():
		text += "\nŁup: %s" % ", ".join(rewards.loot_names)
	if not rewards.quest_update.is_empty():
		text += (
			"\nMisja „%s”: %d/%d"
			% [
				rewards.quest_update.title,
				rewards.quest_update.current,
				rewards.quest_update.required
			]
		)
	for update: Dictionary in rewards.contract_updates:
		text += "\nKontrakt „%s”: %d/%d" % [update.title, update.current, update.required]
	for achievement in rewards.unlocked_achievements:
		text += "\nOsiągnięcie: %s — tytuł „%s”" % [achievement.display_name, achievement.title]
	if not rewards.elite_discovery_note.is_empty():
		text += "\n%s" % rewards.elite_discovery_note
	var milestone: Dictionary = rewards.get("guild_milestone", {})
	if bool(milestone.get("awarded", false)):
		text += "\n%s" % milestone.message
	return text


static func _image(parent: Node, texture: Texture2D, rect: Rect2) -> TextureRect:
	var control := TextureRect.new()
	control.texture = texture
	control.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	control.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	control.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(control)
	_place(control, rect)
	return control


static func _art(parent: Node, piece: String, rect: Rect2) -> TextureRect:
	var control := _image(parent, VictorySkin.texture(piece), rect)
	control.stretch_mode = TextureRect.STRETCH_SCALE
	return control


static func _label(parent: Node, text: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.mouse_filter = Control.MOUSE_FILTER_PASS
	Style.heading(label, font_size)
	label.add_theme_color_override("font_shadow_color", Color(0.04, 0.02, 0.01, 0.95))
	label.add_theme_constant_override("shadow_offset_y", 3)
	parent.add_child(label)
	_place(label, rect)
	return label
