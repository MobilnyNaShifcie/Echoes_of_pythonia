extends Node
## Card-based collection; unlocks and equipped titles still use AchievementService.
const Style := preload("res://ui/presentation/interface_style.gd")
const GuildRanks := preload("res://core/quests/guild_progression_service.gd")
const ICONS := [
	"achievements", "gate", "blacksmith", "workshop", "class_path", "blacksmith", "guild"
]
var screen: Control
var cards: GridContainer
var title_cards: GridContainer
var _left: VBoxContainer
var _filter := 0
var _empty: Label
var _progress: ProgressBar
var _equipped: Label
var _filters: Array[Button] = []


func configure(owner_screen: Control) -> void:
	screen = owner_screen
	var page: VBoxContainer = screen.get_node("Page")
	page.offset_left = 32
	page.offset_top = 24
	page.offset_right = -32
	page.offset_bottom = -24
	screen.get_node("Page/Content").hide()
	screen.get_node("Page/Separator").hide()
	screen.get_node("Page/Header/Identity/Eyebrow").hide()
	Style.quiet_button(screen.get_node("%BackButton"))
	var layout := HBoxContainer.new()
	layout.name = "Collection"
	layout.size_flags_vertical = Control.SIZE_EXPAND_FILL
	layout.add_theme_constant_override("separation", 24)
	page.add_child(layout)
	_left = VBoxContainer.new()
	_left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_left.add_theme_constant_override("separation", 16)
	layout.add_child(_left)
	var filters := HBoxContainer.new()
	filters.add_theme_constant_override("separation", 8)
	_left.add_child(filters)
	for index in 3:
		var button := Button.new()
		button.text = ["Wszystkie", "Zdobyte", "Do zdobycia"][index]
		button.toggle_mode = true
		button.pressed.connect(
			func() -> void:
				_filter = index
				rebuild()
		)
		Style.quiet_button(button)
		filters.add_child(button)
		_filters.append(button)
	_progress = ProgressBar.new()
	_progress.custom_minimum_size.y = 5
	_progress.show_percentage = false
	_left.add_child(_progress)
	var scroll := ScrollContainer.new()
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	_left.add_child(scroll)
	cards = GridContainer.new()
	cards.name = "AchievementCards"
	cards.columns = 3
	cards.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	cards.add_theme_constant_override("h_separation", 14)
	cards.add_theme_constant_override("v_separation", 14)
	scroll.add_child(cards)
	_left.resized.connect(_resize_cards)
	_empty = _label("Brak osiągnięć w tej kategorii.", 19, Color(0.62, 0.71, 0.81))
	_left.add_child(_empty)
	var titles := PanelContainer.new()
	titles.custom_minimum_size.x = 376
	titles.add_theme_stylebox_override("panel", Style.panel(0.65))
	layout.add_child(titles)
	var right := VBoxContainer.new()
	right.add_theme_constant_override("separation", 16)
	titles.add_child(right)
	right.add_child(_label("TYTUŁ BOHATERA", 16, Color(0.85, 0.70, 0.36)))
	_equipped = _label("", 23, Color(0.92, 0.85, 0.62))
	right.add_child(_equipped)
	var title_scroll := ScrollContainer.new()
	title_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	title_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	right.add_child(title_scroll)
	title_cards = GridContainer.new()
	title_cards.name = "TitleCards"
	title_cards.columns = 2
	title_cards.add_theme_constant_override("h_separation", 10)
	title_cards.add_theme_constant_override("v_separation", 10)
	title_scroll.add_child(title_cards)
	screen.equip_button.reparent(right)
	Style.quiet_button(screen.equip_button)
	screen.status_label.reparent(right)
	screen.status_label.text = "Wybierz odblokowany tytuł."
	_resize_cards.call_deferred()


func rebuild() -> void:
	if screen._session == null:
		return
	_clear(cards)
	_clear(title_cards)
	var book = screen._session.player.achievement_book
	for index in _filters.size():
		_filters[index].set_pressed_no_signal(index == _filter)
	_progress.max_value = screen._definitions.size()
	_progress.value = book.unlocked_ids.size()
	screen.summary_label.text = (
		"%d / %d osiągnięć zdobytych" % [book.unlocked_ids.size(), screen._definitions.size()]
	)
	for index in screen._definitions.size():
		var definition = screen._definitions[index]
		var unlocked: bool = book.is_unlocked(definition.achievement_id)
		if (_filter == 1 and not unlocked) or (_filter == 2 and unlocked):
			continue
		var card := Button.new()
		card.name = definition.achievement_id
		card.custom_minimum_size = Vector2(310, 244)
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		card.tooltip_text = definition.description + "\nNagroda: " + definition.title
		card.add_theme_stylebox_override("normal", Style.panel(0.83))
		card.add_theme_stylebox_override("hover", Style.panel(0.98, Color(0.8, 0.65, 0.3)))
		card.pressed.connect(
			func() -> void:
				screen.achievement_list.select(index)
				screen._render_selected_achievement(index)
		)
		cards.add_child(card)
		var content := VBoxContainer.new()
		content.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		content.offset_left = 20
		content.offset_top = 17
		content.offset_right = -20
		content.offset_bottom = -17
		content.add_theme_constant_override("separation", 10)
		content.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(content)
		var icon := TextureRect.new()
		icon.texture = load("res://assets/ui/city_icons/%s.svg" % ICONS[index])
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.custom_minimum_size = Vector2(44, 44)
		icon.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.modulate = Color.WHITE if unlocked else Color(0.52, 0.60, 0.70)
		content.add_child(icon)
		content.add_child(_label(definition.display_name, 21, Color(0.93, 0.94, 0.97)))
		var condition := _label(definition.description, 16, Color(0.67, 0.75, 0.84))
		condition.size_flags_vertical = Control.SIZE_EXPAND_FILL
		content.add_child(condition)
		content.add_child(_label("Tytuł · " + definition.title, 14, Color(0.81, 0.70, 0.43)))
		content.add_child(
			_label(
				_status(definition.achievement_id, unlocked),
				14,
				Color(0.48, 0.82, 0.66) if unlocked else Color(0.54, 0.63, 0.74)
			)
		)
	_empty.visible = cards.get_child_count() == 0
	_equipped.text = "[ %s ]\n%s" % [book.equipped_title, screen._session.player.display_name]
	var all_titles: Array[String] = ["Wędrowiec"]
	for definition in screen._definitions:
		all_titles.append(definition.title)
	var available: Array[String] = book.available_titles()
	for title in all_titles:
		var tile := Button.new()
		tile.custom_minimum_size = Vector2(164, 98)
		tile.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		tile.text = title + ("\nAKTYWNY" if title == book.equipped_title else "")
		tile.disabled = title not in available
		tile.tooltip_text = (
			"Zdobądź odpowiadające osiągnięcie." if tile.disabled else "Wybierz tytuł"
		)
		tile.add_theme_font_size_override("font_size", 16)
		tile.add_theme_stylebox_override("disabled", Style.panel(0.3, Color(0.17, 0.23, 0.31)))
		tile.add_theme_stylebox_override(
			"normal",
			Style.panel(
				0.5,
				Color(0.83, 0.68, 0.3) if title == book.equipped_title else Color(0.25, 0.34, 0.45)
			)
		)
		tile.pressed.connect(
			func() -> void:
				var index := available.find(title)
				screen.title_selector.select(index)
				screen._on_title_selected(index)
				screen.status_label.text = "Wybrano: " + title
		)
		title_cards.add_child(tile)
	_resize_cards.call_deferred()


func _status(achievement_id: String, unlocked: bool) -> String:
	if unlocked:
		return "✓ ZDOBYTE"
	if achievement_id == "guild_veteran":
		return (
			"%d / %d reputacji"
			% [screen._session.guild_reputation, GuildRanks.RANKS.back().reputation]
		)
	if achievement_id == "master_smith":
		var highest := 0
		var items: Array = screen._session.player.equipment.slots.values()
		items.append_array(screen._session.player.inventory.equipment_items)
		for item in items:
			if item != null:
				highest = maxi(highest, item.upgrade_level)
		return "Ulepszenie +%d / +10" % highest
	return "DO ODKRYCIA"


func _resize_cards() -> void:
	if cards == null:
		return
	cards.columns = clampi(int(_left.size.x / 330), 1, 3)
	var width := maxf(260, (_left.size.x - (cards.columns - 1) * 14 - 14) / cards.columns)
	for card in cards.get_children():
		card.custom_minimum_size.x = width


func _label(value: String, font_size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	return label


func _clear(parent: Node) -> void:
	for child in parent.get_children():
		parent.remove_child(child)
		child.queue_free()
