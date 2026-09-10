extends Control
## Isolated comparison: no game session, save service, damage or RNG.

const Rig := preload("res://tools/pierrot_native/portrait_rig.gd")
const SkinData := preload("res://tools/pierrot_native/portrait_skin.gd")
const BACKDROP := preload("res://assets/combat/backgrounds/twilight_plains_night.png")
const DESIGN := Vector2(1440, 900)

var rig: Node2D
var playing := true
var light_background := false
var stage: Node2D
var _backdrop: TextureRect
var _wash: ColorRect
var _pause: Button
var _status: Label
var _slider: HSlider
var _guides: Node2D
var _original: Sprite2D
var _background_button: Button
var _labels: Array[Label] = []


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	stage = Node2D.new()
	add_child(stage)
	_backdrop = TextureRect.new()
	_backdrop.texture = BACKDROP
	_backdrop.size = DESIGN
	_backdrop.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	_backdrop.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	_backdrop.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_backdrop.modulate = Color(0.37, 0.42, 0.52)
	stage.add_child(_backdrop)
	_wash = ColorRect.new()
	_wash.size = DESIGN
	_wash.color = Color(0.02, 0.025, 0.043, 0.38)
	_wash.mouse_filter = Control.MOUSE_FILTER_IGNORE
	stage.add_child(_wash)
	_original = Sprite2D.new()
	_original.name = "UnmodifiedReference"
	_original.texture = Rig.SOURCE
	_original.centered = false
	_original.position = Vector2(140, 112)
	_original.scale = Vector2.ONE * 0.45
	stage.add_child(_original)
	rig = Rig.new()
	rig.name = "NativePortrait"
	rig.position = Vector2(840, 112)
	rig.scale = _original.scale
	stage.add_child(rig)
	_guides = Node2D.new()
	_guides.draw.connect(_draw_guides)
	stage.add_child(_guides)
	_build_controls()
	resized.connect(_layout)
	_layout()
	rig.set_playing(playing)


func _build_controls() -> void:
	_label("PIERROTKA", Vector2(42, 29), 27, Color("f2e7db"))
	_label("STUDIUM RUCHU  /  GODOT 2D", Vector2(44, 66), 12, Color("b59e7d"))
	var badge := _label(
		"ORYGINALNA GRAFIKA · BEZ NOWYCH GENERACJI", Vector2(900, 44), 12, Color("a8b6c8")
	)
	badge.size.x = 493
	badge.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_label("01  /  ORYGINAŁ", Vector2(65, 98), 12, Color("9caaba"))
	_label("02  /  SUBTELNE IDLE", Vector2(765, 98), 12, Color("dfba79"))
	_pause = _button("Pauza", Vector2(45, 825), Vector2(122, 42))
	_pause.pressed.connect(func() -> void: set_playing(not playing))
	var rest := _button("Poza bazowa", Vector2(179, 825), Vector2(151, 42))
	rest.pressed.connect(func() -> void: seek(0.0))
	_slider = HSlider.new()
	_slider.position = Vector2(351, 832)
	_slider.size = Vector2(346, 28)
	_slider.min_value = 0
	_slider.max_value = SkinData.CYCLE
	_slider.step = 0.001
	_slider.value_changed.connect(seek)
	stage.add_child(_slider)
	_background_button = _button("Jasne tło", Vector2(733, 825), Vector2(139, 42))
	_background_button.pressed.connect(func() -> void: set_light_background(not light_background))
	var guides := _button("Punkty ruchu", Vector2(884, 825), Vector2(155, 42))
	guides.pressed.connect(
		func() -> void:
			rig.debug_guides = not rig.debug_guides
			rig.queue_redraw()
			_guides.queue_redraw()
			guides.text = "Ukryj punkty" if rig.debug_guides else "Punkty ruchu"
	)
	var close := _button("Zamknij podgląd", Vector2(1210, 825), Vector2(185, 42))
	close.pressed.connect(func() -> void: get_tree().quit())
	_status = _label("", Vector2(45, 883), 11, Color("9cabbf"))
	_label(
		"Spacja: pauza   ·   R: poza bazowa   ·   Esc: zamknij",
		Vector2(1022, 883),
		11,
		Color("9cabbf")
	)
	_update_status()


func set_playing(active: bool) -> void:
	playing = active
	rig.set_playing(active)
	_update_status()


func seek(seconds: float) -> void:
	playing = false
	rig.seek(seconds)
	_slider.set_value_no_signal(clampf(seconds, 0.0, SkinData.CYCLE))
	_update_status()


func set_light_background(active: bool) -> void:
	light_background = active
	_backdrop.visible = not active
	_wash.color = Color("bac0c8") if active else Color(0.02, 0.025, 0.043, 0.38)
	_background_button.text = "Tło regionu" if active else "Jasne tło"
	for label in _labels:
		var color: Color = Color("1a2639") if active else label.get_meta("dark_background_color")
		label.add_theme_color_override("font_color", color)
		label.add_theme_color_override(
			"font_shadow_color", Color.TRANSPARENT if active else Color(0.015, 0.02, 0.04, 0.95)
		)
	_guides.queue_redraw()


func _process(_delta: float) -> void:
	if rig == null:
		return
	if playing:
		_slider.set_value_no_signal(fposmod(rig.phase, TAU) / TAU * SkinData.CYCLE)
	if rig.debug_guides:
		_guides.queue_redraw()


func _unhandled_key_input(event: InputEvent) -> void:
	if event is not InputEventKey or not event.pressed or event.echo:
		return
	match event.keycode:
		KEY_SPACE:
			set_playing(not playing)
		KEY_R:
			seek(0.0)
		KEY_ESCAPE:
			get_tree().quit()
		_:
			return
	get_viewport().set_input_as_handled()


func _update_status() -> void:
	if _status == null:
		return
	_pause.text = "Pauza" if playing else "Odtwórz idle"
	_status.text = "ODDECH · WŁOSY · SZARFY     /     OSOBNY PODGLĄD — WALKA I ZAPISY BEZ ZMIAN"


func _layout() -> void:
	if size.x <= 0.0 or size.y <= 0.0:
		return
	var factor := minf(size.x / DESIGN.x, size.y / DESIGN.y)
	stage.scale = Vector2.ONE * factor
	stage.position = (size - DESIGN * factor) * 0.5
	# The comparison stays centered; the environment fills even ultrawide windows.
	_backdrop.position = -stage.position / factor
	_backdrop.size = size / factor
	_wash.position = _backdrop.position
	_wash.size = _backdrop.size


func _label(value: String, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color(0.015, 0.02, 0.04, 0.95))
	label.add_theme_constant_override("shadow_offset_y", 1)
	label.set_meta("dark_background_color", tint)
	_labels.append(label)
	stage.add_child(label)
	return label


func _button(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 13)
	var normal := StyleBoxFlat.new()
	normal.bg_color = Color(0.055, 0.067, 0.095, 0.9)
	normal.border_color = Color(0.44, 0.49, 0.60, 0.4)
	normal.set_border_width_all(1)
	normal.set_corner_radius_all(12)
	button.add_theme_stylebox_override("normal", normal)
	var hover := normal.duplicate() as StyleBoxFlat
	hover.bg_color = Color("263246")
	hover.border_color = Color("d0ad74")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	button.add_theme_stylebox_override("focus", hover)
	stage.add_child(button)
	return button


func _draw_guides() -> void:
	_guides.draw_line(Vector2(720, 136), Vector2(720, 780), Color(0.6, 0.66, 0.77, 0.22), 1)
	if rig == null or not rig.debug_guides:
		return
	for point: Vector2 in [Vector2(350, 532), Vector2(474, 1353), Vector2(722, 1425)]:
		var at: Vector2 = rig.position + rig.point_in_pose(point) * rig.scale
		_guides.draw_arc(at, 7, 0, TAU, 32, Color("e2bf7f"), 1.4, true)
