extends Control
## View of canonical regional recipes. Crafting and inventory ownership stay in CraftingService.
signal services_requested
signal close_requested
signal state_changed

const Crafting := preload("res://core/economy/crafting_service.gd")
const Catalog := preload("res://core/items/item_catalog.gd")
const Config := preload("res://ui/screens/city_economy/city_economy_config.gd")
const Style := preload("res://ui/screens/workshop_book/book_style.gd")
const Ornament := preload("res://ui/screens/workshop_book/book_ornament.gd")
const BOOK := preload("res://assets/ui/workshop/recipe_book_v1.png")
const GOLD_ICON := preload("res://assets/ui/blacksmith/gold_stack.svg")
const PAGE_SIZE := 6
const DESIGN_SIZE := Vector2(1920, 1080)

var session
var recipes: Array[Dictionary] = []
var region_index := 0
var page := 0
var selected_index := 0
var stage: Control
var book_canvas: Control
var region_label: Label
var recipe_title: Label
var recipe_image: TextureRect
var output_quantity: Label
var description: Label
var description_scroll: ScrollContainer
var ingredients: VBoxContainer
var ingredient_scroll: ScrollContainer
var craft_button: Button
var feedback: Label
var page_label: Label
var previous_button: Button
var next_button: Button
var services_button: Button
var close_button: Button
var region_buttons: Array[Button] = []
var recipe_buttons: Array[Button] = []


func _ready() -> void:
	_build()
	resized.connect(_layout)
	_layout()
	if session != null:
		select_region(0)


func configure(current_session) -> void:
	session = current_session
	if is_node_ready():
		select_region(0)


func _layout() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - DESIGN_SIZE * factor) * 0.5


func _build() -> void:
	stage = Control.new()
	Style.place(stage, self, Rect2(Vector2.ZERO, DESIGN_SIZE))
	stage.mouse_filter = Control.MOUSE_FILTER_IGNORE
	services_button = Style.button(stage, "←  Usługi Mireli", Rect2(26, 26, 240, 58), true)
	services_button.pressed.connect(services_requested.emit)
	var heading := Style.label(stage, "Warsztat Mireli", Rect2(680, 18, 1160, 64), 40)
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.add_theme_color_override("font_color", Color("#f0d18a"))
	heading.add_theme_color_override("font_shadow_color", Color.BLACK)
	heading.add_theme_constant_override("shadow_offset_y", 3)
	book_canvas = Control.new()
	Style.place(book_canvas, stage, Rect2(635, 90, 1448, 1086))
	book_canvas.scale = Vector2.ONE * 0.875
	book_canvas.mouse_filter = Control.MOUSE_FILTER_IGNORE
	Style.image(book_canvas, BOOK, Rect2(0, 0, 1448, 1086))
	_build_regions()
	close_button = Style.button(book_canvas, "×", Rect2(1338, 58, 54, 54), true)
	close_button.tooltip_text = "Zamknij księgę (Esc)"
	close_button.pressed.connect(close_requested.emit)
	var title := Style.label(book_canvas, "Receptury", Rect2(200, 105, 440, 62), 46)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label = Style.label(book_canvas, "", Rect2(154, 174, 520, 52), 26)
	region_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	region_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	Style.divider(book_canvas, Rect2(168, 237, 480, 1))
	for index in PAGE_SIZE:
		var row := Style.button(book_canvas, "", Rect2(148, 258 + index * 96, 530, 90))
		row.name = "Recipe%d" % index
		row.pressed.connect(_select_row.bind(index))
		Style.image(row, null, Rect2(10, 5, 80, 80)).name = "Icon"
		var label := Style.label(row, "", Rect2(108, 5, 382, 80), 27)
		label.name = "Name"
		label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		label.max_lines_visible = 2
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		var ready_mark := Style.label(row, "", Rect2(495, 26, 27, 32), 24)
		ready_mark.name = "Ready"
		recipe_buttons.append(row)
	previous_button = Style.button(book_canvas, "‹", Rect2(268, 863, 64, 56))
	previous_button.pressed.connect(change_page.bind(-1))
	next_button = Style.button(book_canvas, "›", Rect2(510, 863, 64, 56))
	next_button.pressed.connect(change_page.bind(1))
	previous_button.tooltip_text = "Poprzednia strona"
	next_button.tooltip_text = "Następna strona"
	page_label = Style.label(book_canvas, "", Rect2(340, 868, 158, 46), 28)
	page_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_build_recipe_page()


func _build_regions() -> void:
	for index in Config.MODES.workshop.size():
		var tab := Style.button(
			book_canvas,
			["I", "II", "III", "IV", "V"][index],
			Rect2(245 + index * 116, 0, 91, 78),
			true
		)
		tab.toggle_mode = true
		tab.tooltip_text = Config.MODES.workshop[index].name
		tab.pressed.connect(select_region.bind(index))
		region_buttons.append(tab)


func _build_recipe_page() -> void:
	recipe_title = Style.label(book_canvas, "", Rect2(778, 109, 531, 82), 34)
	recipe_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	recipe_title.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	recipe_title.max_lines_visible = 2
	recipe_title.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	recipe_title.mouse_filter = Control.MOUSE_FILTER_STOP
	Style.divider(book_canvas, Rect2(814, 201, 460, 1))
	recipe_image = Style.image(book_canvas, null, Rect2(883, 218, 324, 245))
	output_quantity = Style.label(book_canvas, "", Rect2(1212, 410, 84, 48), 27)
	description_scroll = ScrollContainer.new()
	Style.place(description_scroll, book_canvas, Rect2(789, 474, 513, 88))
	description_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	description = Style.label(description_scroll, "", Rect2(0, 0, 495, 0), 23)
	description.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	description.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	description.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	description.add_theme_color_override("font_color", Style.MUTED)
	var ingredient_heading := Style.label(book_canvas, "Składniki", Rect2(813, 570, 460, 44), 32)
	ingredient_heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	Style.divider(book_canvas, Rect2(814, 619, 460, 1))
	ingredient_scroll = ScrollContainer.new()
	Style.place(ingredient_scroll, book_canvas, Rect2(806, 628, 491, 204))
	ingredient_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	ingredients = VBoxContainer.new()
	ingredients.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ingredients.add_theme_constant_override("separation", 0)
	ingredient_scroll.add_child(ingredients)
	craft_button = Style.button(book_canvas, "Wytwórz", Rect2(817, 842, 457, 68), true)
	craft_button.add_theme_font_size_override("font_size", 34)
	craft_button.pressed.connect(_craft)
	var ornament := Ornament.new()
	craft_button.add_child(ornament)
	ornament.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	feedback = Style.label(book_canvas, "", Rect2(812, 914, 474, 32), 20)
	feedback.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	feedback.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	feedback.add_theme_color_override("font_color", Color("#f0d18a"))
	feedback.add_theme_color_override("font_shadow_color", Color.BLACK)
	feedback.add_theme_constant_override("shadow_offset_y", 1)


func select_region(index: int) -> void:
	if session == null or index < 0 or index >= Config.MODES.workshop.size():
		return
	region_index = index
	var mode: Dictionary = Config.MODES.workshop[index]
	recipes = Crafting.get_recipes(str(mode.id).trim_prefix("workshop_"))
	region_label.text = mode.name
	page = 0
	selected_index = 0
	for tab_index in region_buttons.size():
		var tab := region_buttons[tab_index]
		tab.set_pressed_no_signal(tab_index == index)
		tab.add_theme_stylebox_override("normal", Style.box(Color("#63392e"), Style.GOLD, 2))
	refresh()
	feedback.text = ""


func change_page(direction: int) -> void:
	var target := clampi(page + direction, 0, maxi(0, ceili(recipes.size() / float(PAGE_SIZE)) - 1))
	if target == page:
		return
	page = target
	select_recipe(page * PAGE_SIZE)


func _select_row(index: int) -> void:
	select_recipe(page * PAGE_SIZE + index)


func select_recipe(index: int) -> void:
	if index < 0 or index >= recipes.size():
		return
	selected_index = index
	page = index / PAGE_SIZE
	feedback.text = ""
	description_scroll.scroll_vertical = 0
	ingredient_scroll.scroll_vertical = 0
	refresh()


func selected_recipe() -> Dictionary:
	return (
		recipes[selected_index] if selected_index >= 0 and selected_index < recipes.size() else {}
	)


func refresh() -> void:
	if session == null or not is_instance_valid(craft_button):
		return
	_render_rows()
	_render_recipe()


func _render_rows() -> void:
	for row_index in PAGE_SIZE:
		var index := page * PAGE_SIZE + row_index
		var row := recipe_buttons[row_index]
		row.visible = index < recipes.size()
		if not row.visible:
			continue
		var recipe: Dictionary = recipes[index]
		var definition = Catalog.get_definition(recipe.output_item_id)
		row.get_node("Icon").texture = definition.icon
		row.get_node("Name").text = recipe.name
		var error := Crafting.get_craft_error(session.player, recipe.recipe_id)
		row.tooltip_text = (
			recipe.name + ("\n" + error if not error.is_empty() else "\nMożesz wytworzyć")
		)
		var selected := index == selected_index
		var fill := Color(0.20, 0.34, 0.24, 0.18) if selected else Color.TRANSPARENT
		row.add_theme_stylebox_override(
			"normal", Style.box(fill, Style.GOLD if selected else Color.TRANSPARENT, 2)
		)
		row.get_node("Ready").text = "✓" if error.is_empty() else ""
		row.get_node("Ready").add_theme_color_override("font_color", Style.READY)
	page_label.text = "%d / %d" % [page + 1, maxi(1, ceili(recipes.size() / float(PAGE_SIZE)))]
	previous_button.disabled = page == 0
	next_button.disabled = (page + 1) * PAGE_SIZE >= recipes.size()


func _render_recipe() -> void:
	var recipe := selected_recipe()
	if recipe.is_empty():
		craft_button.disabled = true
		return
	var definition = Catalog.get_definition(recipe.output_item_id)
	recipe_title.text = recipe.name
	recipe_title.tooltip_text = recipe.name
	recipe_image.texture = definition.icon
	output_quantity.text = "×%d" % recipe.quantity if int(recipe.quantity) > 1 else ""
	var lines: Array[String] = []
	var stats := _base_stats(definition)
	if not stats.is_empty():
		lines.append(stats)
	if not definition.description.is_empty():
		lines.append(definition.description)
	if not str(recipe.get("note", "")).is_empty():
		lines.append(recipe.note)
	description.text = "\n".join(lines)
	description.tooltip_text = description.text
	description_scroll.tooltip_text = description.text
	if definition.is_equipment():
		description_scroll.tooltip_text = "Właściwości bazowe przedmiotu.\n" + description.text
	for child in ingredients.get_children():
		ingredients.remove_child(child)
		child.queue_free()
	var count: int = recipe.ingredients.size() + int(int(recipe.get("gold_cost", 0)) > 0)
	# Floor pixel sizes so all six canonical costs fit without a hidden last row.
	var row_height := minf(76.0, floorf(ingredient_scroll.size.y / maxi(1, count)))
	for item_id: String in recipe.ingredients:
		var item = Catalog.get_definition(item_id)
		_add_ingredient(
			item_id,
			item.display_name,
			item.icon,
			session.player.inventory.count(item_id),
			int(recipe.ingredients[item_id]),
			row_height
		)
	var gold := int(recipe.get("gold_cost", 0))
	if gold > 0:
		_add_ingredient("gold", "Złoto", GOLD_ICON, session.player.gold, gold, row_height)
	var error := Crafting.get_craft_error(session.player, recipe.recipe_id)
	craft_button.disabled = not error.is_empty()
	craft_button.tooltip_text = (
		error if not error.is_empty() else "Wytwórz: %s ×%d" % [recipe.name, recipe.quantity]
	)


func _add_ingredient(
	item_id: String, caption: String, icon: Texture2D, owned: int, required: int, row_height: float
) -> void:
	var row := HBoxContainer.new()
	row.name = item_id
	row.custom_minimum_size.y = maxf(34, row_height)
	row.set_meta("owned", owned)
	row.set_meta("required", required)
	row.add_theme_constant_override("separation", 12)
	ingredients.add_child(row)
	var texture := Style.image(row, icon, Rect2(0, 0, 50, 0))
	texture.custom_minimum_size.x = 50
	var label := Style.label(row, caption, Rect2(), 23)
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var amount := Style.label(row, "%d / %d" % [owned, required], Rect2(), 23)
	amount.name = "Amount"
	amount.add_theme_color_override(
		"font_color", Style.READY if owned >= required else Style.MISSING
	)
	row.tooltip_text = (
		"%s: %d / %d%s"
		% [
			caption,
			owned,
			required,
			" — brakuje %d" % (required - owned) if owned < required else ""
		]
	)
	row.mouse_filter = Control.MOUSE_FILTER_STOP


static func _base_stats(definition) -> String:
	var values: Array[String] = []
	for pair in [
		["attack", "Atak"],
		["defense", "Obrona"],
		["max_hp", "Maks. PŻ"],
		["max_mana", "Maks. mana"],
		["magic_power", "Moc magii"]
	]:
		var value := int(definition.get(pair[0]))
		if value > 0:
			values.append("%s %d" % [pair[1], value])
	return "  ·  ".join(values)


func _craft() -> void:
	if session == null or not is_visible_in_tree() or selected_recipe().is_empty():
		return
	# Revalidate against current player data, never against cached affordability or UI counts.
	var result := Crafting.craft(session.player, selected_recipe().recipe_id)
	refresh()
	feedback.text = result.message
	feedback.tooltip_text = result.message
	if result.ok:
		session.last_activity = result.message
		session.log_event(result.message)
		state_changed.emit()


func _input(event: InputEvent) -> void:
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_requested.emit()
