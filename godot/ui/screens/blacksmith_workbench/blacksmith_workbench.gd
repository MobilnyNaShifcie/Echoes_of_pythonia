extends Control
## Service host: navigation and event coordination, not upgrade rules or item ownership.
signal services_requested
signal close_requested
signal state_changed
const Style := preload("res://ui/screens/blacksmith_workbench/workbench_style.gd")
const Carry := preload("res://core/economy/carry_weight_service.gd")
var _session
var _service_views := {}

@onready var upgrade_view: PanelContainer = %UpgradeView
@onready var picker: VBoxContainer = %EquipmentPicker


func _ready() -> void:
	theme = Style.create_theme()
	_service_views = {"upgrade": upgrade_view}
	%ServicesButton.pressed.connect(services_requested.emit)
	%CloseButton.pressed.connect(close_requested.emit)
	%UpgradeTab.pressed.connect(show_service.bind("upgrade"))
	picker.item_selected.connect(upgrade_view.select_item)
	upgrade_view.selection_changed.connect(picker.refresh)
	upgrade_view.operation_completed.connect(_on_operation_completed)
	Style.style_primary(upgrade_view.action_button)
	$Margin/Layout/Header/Title.add_theme_font_override("font", Style.heading_font())


func configure(session) -> void:
	_session = session
	picker.configure(session)
	upgrade_view.configure(session)
	show_service("upgrade")
	_refresh_resources()


func show_location(texture: Texture2D) -> void:
	# Frame the approved integrated Garran art in the uncovered left strip.
	# AtlasTexture is a presentation crop; the source image is neither edited nor copied.
	var crop := AtlasTexture.new()
	crop.atlas = texture
	crop.region = Rect2(
		texture.get_size() * Vector2(0.18, 0), texture.get_size() * Vector2(0.38, 1)
	)
	%ForgePortrait.texture = crop


func show_service(service_id: String) -> void:
	if not _service_views.has(service_id):
		return
	for key: String in _service_views:
		_service_views[key].visible = key == service_id
	%UpgradeTab.set_pressed_no_signal(service_id == "upgrade")


func _on_operation_completed(result: Dictionary) -> void:
	if not result.ok:
		return
	_session.last_activity = result.message
	_session.log_event(result.message)
	picker.refresh(upgrade_view.model.selected_id)
	_refresh_resources()
	state_changed.emit()


func _refresh_resources() -> void:
	var load := Carry.carry_status(_session.player)
	%ResourcesLabel.text = (
		"Złoto %d   ·   Udźwig %.1f / %.1f kg"
		% [
			_session.player.gold,
			load.current_kg,
			load.capacity_kg,
		]
	)


func _input(event: InputEvent) -> void:
	# Escape also works while a focused Control would otherwise consume keyboard input.
	if is_visible_in_tree() and event.is_action_pressed("ui_cancel") and not event.is_echo():
		get_viewport().set_input_as_handled()
		close_requested.emit()
