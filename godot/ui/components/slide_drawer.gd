extends Node
## One interaction model for city navigation and combat commands; presentation only.
signal openness_changed(opened: bool)

var opened := false
var pinned := false
var reduced_motion := false
var enabled := true
var handle: Button
var _bounds: Control
var _panel: Control
var _edge := "left"
var _progress := 0.0
var _outside_time := 0.0
var _hovered_handle := false
var _tween: Tween


func configure(bounds: Control, panel: Control, edge: String, caption: String) -> void:
	_bounds = bounds
	_panel = panel
	_edge = edge
	handle = Button.new()
	handle.name = "DrawerHandle"
	handle.text = "›" if edge == "left" else "▲  " + caption
	handle.tooltip_text = "Najedź, aby otworzyć. Kliknij, aby przypiąć. Esc zamyka."
	handle.custom_minimum_size = Vector2(36, 84) if edge == "left" else Vector2(260, 34)
	handle.add_theme_font_size_override("font_size", 25 if edge == "left" else 14)
	handle.z_index = 41
	_attach_handle.call_deferred()
	_panel.z_index = 40
	_panel.mouse_filter = Control.MOUSE_FILTER_STOP
	_panel.set_anchors_preset(Control.PRESET_TOP_LEFT, true)
	handle.pressed.connect(_toggle_pin)
	handle.focus_entered.connect(func() -> void: set_open(true))
	_bounds.resized.connect(refresh_layout)
	_panel.resized.connect(_place)
	_panel.minimum_size_changed.connect(refresh_layout, CONNECT_DEFERRED)
	reduced_motion = DisplayServer.get_name() == "headless"
	refresh_layout()
	set_open(false, true)


func _attach_handle() -> void:
	if not is_inside_tree() or not is_instance_valid(_bounds) or not is_instance_valid(handle):
		return
	if handle.get_parent() != null:
		return
	_bounds.add_child(handle)
	_place()


func _exit_tree() -> void:
	if is_instance_valid(handle) and handle.get_parent() == null:
		handle.free()
	handle = null


func refresh_layout() -> void:
	if _bounds == null:
		return
	if _edge == "left":
		_panel.size = Vector2(minf(304, _bounds.size.x - 44), _bounds.size.y)
	else:
		_panel.size = _panel.get_combined_minimum_size()
	_place()


func _place() -> void:
	if not is_instance_valid(handle) or not is_instance_valid(_bounds):
		return
	handle.size = handle.custom_minimum_size
	if _edge == "left":
		_panel.position = Vector2(-_panel.size.x * (1.0 - _progress), 0)
		handle.position = Vector2(_panel.size.x * _progress, _bounds.size.y * 0.45 - 42)
		handle.text = "‹" if opened else "›"
	else:
		_panel.position = Vector2(
			(_bounds.size.x - _panel.size.x) * 0.5,
			_bounds.size.y - (_panel.size.y + 10) * _progress
		)
		handle.position = Vector2(
			(_bounds.size.x - handle.size.x) * 0.5, _panel.position.y - handle.size.y
		)


func set_open(value: bool, immediate := false) -> void:
	if not enabled and value:
		return
	opened = value
	_outside_time = 0.0
	if _tween != null:
		_tween.kill()
	if not opened:
		var focus := _panel.get_viewport().gui_get_focus_owner()
		if focus != null and _panel.is_ancestor_of(focus):
			focus.release_focus()
	_panel.show()
	if immediate or reduced_motion:
		_set_progress(1.0 if value else 0.0)
		_panel.visible = value
	else:
		_tween = create_tween().set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
		_tween.tween_method(_set_progress, _progress, 1.0 if value else 0.0, 0.22)
		_tween.tween_callback(func() -> void: _panel.visible = opened)
	openness_changed.emit(opened)


func _set_progress(value: float) -> void:
	_progress = value
	_place()


func set_enabled(value: bool) -> void:
	if enabled == value:
		return
	enabled = value
	handle.visible = value
	if not value:
		pinned = false
		set_open(false, true)


func _toggle_pin() -> void:
	pinned = not pinned
	set_open(pinned)
	handle.modulate = Color(1, 0.86, 0.58) if pinned else Color.WHITE


func _process(delta: float) -> void:
	if not enabled or not is_instance_valid(handle) or not is_instance_valid(_bounds):
		return
	var mouse := _bounds.get_global_mouse_position()
	var over_handle := handle.get_global_rect().has_point(mouse)
	if over_handle and not _hovered_handle:
		set_open(true)
	_hovered_handle = over_handle
	if not opened or pinned:
		return
	var focus := _bounds.get_viewport().gui_get_focus_owner()
	var working := (
		(focus != null and _panel.is_ancestor_of(focus))
		or Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT)
		or _bounds.get_viewport().gui_is_dragging()
	)
	if over_handle or _panel.get_global_rect().grow(8).has_point(mouse) or working:
		_outside_time = 0.0
	else:
		_outside_time += delta
		if _outside_time >= 0.55:
			set_open(false)


func _unhandled_key_input(event: InputEvent) -> void:
	if enabled and opened and event.is_action_pressed("ui_cancel"):
		pinned = false
		handle.modulate = Color.WHITE
		set_open(false)
		get_viewport().set_input_as_handled()
