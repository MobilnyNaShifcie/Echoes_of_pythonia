extends Node
## Shared service geometry. Gameplay remains in CityEconomyScreen / economy services.
const Style := preload("res://ui/presentation/interface_style.gd")
var screen: Control
var _item_preview: TextureRect
var _rest_icon: TextureRect


func configure(owner_screen: Control) -> void:
	screen = owner_screen
	screen.resized.connect(refresh)
	var header := screen.get_node("Page/Header")
	header.mouse_filter = Control.MOUSE_FILTER_PASS
	screen.get_node("Page/Header/Identity/Eyebrow").hide()
	Style.heading(screen.title_label, 27)
	screen.summary_label.add_theme_font_size_override("font_size", 15)
	screen.summary_label.add_theme_constant_override("outline_size", 4)
	screen.mode_selector.fit_to_longest_item = false
	screen.mode_selector.clip_text = true
	screen.close_service_button.text = "Zamknij"
	screen.close_service_button.custom_minimum_size.x = 100
	screen.get_node("Page/Body/Columns").mouse_filter = Control.MOUSE_FILTER_IGNORE
	for panel in [
		screen.catalogue_panel,
		screen.transaction_panel,
		screen.npc_action_panel,
		screen.informant_action_panel,
		screen.get_node("Page/Body/MerchantTradeOverlay/MerchantActionPanel")
	]:
		panel.add_theme_stylebox_override("panel", Style.panel())
	for node_name in ["MerchantStockPanel", "MerchantPlayerPanel"]:
		var panel := screen.get_node("Page/Body/MerchantTradeOverlay/InventoryPanels/" + node_name)
		panel.custom_minimum_size = Vector2(448, 0)
		panel.size_flags_stretch_ratio = 1.0
		panel.add_theme_stylebox_override("panel", Style.panel())
	for grid in [screen.service_grid, screen.merchant_stock_grid, screen.merchant_player_grid]:
		grid.columns = 6
		grid.visible_rows = 4
		grid.cell_size = Vector2(64, 64)
		grid.gap = 5.0
		grid.stretch_cells_to_width = false
		grid.stretch_cells_to_height = false
		grid.size_flags_horizontal = Control.SIZE_SHRINK_CENTER
	for button in [
		screen.mode_selector,
		screen.action_button,
		screen.merchant_action_button,
		screen.open_service_button,
		screen.close_interaction_button,
		screen.close_service_button,
		screen.informant_unlock_button,
		screen.get_node("%CloseInformantButton"),
		screen.get_node("%BackButton")
	]:
		Style.quiet_button(button)
	screen.merchant_action_button.custom_minimum_size.x = 186
	screen.merchant_quantity_box.custom_minimum_size.x = 100
	screen.merchant_selection_name.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.merchant_selection_price.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	screen.selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	screen.selection_label.add_theme_font_size_override("font_size", 16)
	screen.transaction_drop_zone.custom_minimum_size = Vector2(0, 96)
	screen.transaction_drop_zone.add_theme_stylebox_override("panel", Style.panel(0.32))
	_item_preview = TextureRect.new()
	_item_preview.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_item_preview.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_item_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_item_preview.custom_minimum_size = Vector2(80, 80)
	screen.transaction_drop_zone.add_child(_item_preview)
	_rest_icon = TextureRect.new()
	_rest_icon.texture = load("res://assets/ui/city_icons/inn.svg")
	_rest_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_rest_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	_rest_icon.custom_minimum_size = Vector2(0, 72)
	_rest_icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var transaction: VBoxContainer = screen.selection_label.get_parent()
	transaction.add_child(_rest_icon)
	transaction.move_child(_rest_icon, 1)
	refresh.call_deferred()


func refresh() -> void:
	if screen == null or not screen.is_node_ready():
		return
	var bounds := screen.size
	_rect(screen.get_node("Page/Body"), Rect2(Vector2.ZERO, bounds))
	_rect(screen.columns, Rect2(Vector2.ZERO, bounds))
	_rect(screen.get_node("Page/Header"), Rect2(24, 15, bounds.x - 48, 42))
	_rect(screen.summary_label, Rect2(24, 61, bounds.x - 48, 27))
	screen.npc_panel.hide()  # The approved backgrounds already include the NPC.
	var width := minf(912, bounds.x - 40)
	var left := bounds.x - width - 24
	var top := maxf(120, bounds.y * 0.20)
	var height := minf(470, bounds.y - top - 180)
	var service_only: bool = screen._current_mode() in ["inn_rest", "carry_upgrade"]
	var active: bool = screen._interaction_state == "service"
	_rect(screen.service_toolbar, Rect2(left, top - 54, width, 42))
	_rect(screen.catalogue_panel, Rect2(left, top, 448, height))
	_rect(screen.transaction_panel, Rect2(left + 460, top, 452, height))
	screen.catalogue_panel.visible = (
		active and screen._service_id != "merchant" and not service_only
	)
	screen.transaction_panel.visible = active and screen._service_id != "merchant"
	if service_only:
		_rect(screen.transaction_panel, Rect2(left + width - 480, top, 480, 370))
		_rect(screen.service_toolbar, Rect2(left + width - 480, top - 54, 480, 42))
	screen.quantity_box.get_parent().visible = not service_only
	screen.transaction_drop_zone.visible = not service_only
	_rest_icon.visible = screen._current_mode() == "inn_rest"
	if service_only:
		screen.transaction_title.text = (
			"Pokój na noc" if screen._current_mode() == "inn_rest" else "Większy udźwig"
		)
	var definition = (
		screen._entry_definition(screen._selected_entry())
		if not screen._selected_entry().is_empty()
		else null
	)
	_item_preview.texture = definition.icon if definition != null else null
	_rect(
		screen.get_node("Page/Body/MerchantTradeOverlay/InventoryPanels"),
		Rect2(left, top, width, height)
	)
	_rect(
		screen.get_node("Page/Body/MerchantTradeOverlay/MerchantActionPanel"),
		Rect2(left, top + height + 12, width, 110)
	)
	for panel in [screen.npc_action_panel, screen.informant_action_panel]:
		_rect(panel, Rect2(bounds.x - 466, bounds.y * 0.34, 442, 290))
	screen.status_label.z_index = 35
	screen.status_label.add_theme_font_size_override("font_size", 16)
	screen.status_label.add_theme_constant_override("outline_size", 4)
	_rect(screen.status_label, Rect2(left, minf(bounds.y - 70, top + height + 134), width, 52))


func update_selection() -> void:
	if _item_preview == null:
		return
	var entry: Dictionary = screen._selected_entry()
	var definition = screen._entry_definition(entry) if not entry.is_empty() else null
	_item_preview.texture = definition.icon if definition != null else null


func _rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size
