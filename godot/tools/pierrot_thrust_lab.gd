extends Control
## Review scene only: no App, GameSession, CombatEngine or save service.

const Rig := preload("res://ui/presentation/rigs/pierrot_cutout_rig.gd")
const Pose := preload("res://ui/presentation/rigs/pierrot_thrust_pose.gd")
const BACKGROUND := preload("res://assets/combat/backgrounds/twilight_plains_night.png")
const ENEMY := preload("res://assets/combat/enemies/plains_spirit.png")
const DURATION := 1.85
const DESIGN_SIZE := Vector2(1280, 720)

var playing := false
var speed := 1.0
var progress := 0.0
var show_guides := false
var rig: Node2D
var target := Vector2(987, 344)
var _stage: Node2D
var _guides: Node2D
var _label: Label
var _slider: HSlider
var _play: Button
var _time := 0.0


func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_stage = Node2D.new()
	add_child(_stage)
	var background := TextureRect.new()
	background.texture = BACKGROUND
	background.size = DESIGN_SIZE
	background.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	background.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	background.mouse_filter = Control.MOUSE_FILTER_IGNORE
	background.modulate = Color(0.76, 0.80, 0.88)
	_stage.add_child(background)
	var atlas := AtlasTexture.new()
	atlas.atlas = ENEMY
	atlas.region = ENEMY.get_image().get_used_rect()
	var opponent := Sprite2D.new()
	opponent.texture = atlas
	opponent.scale = Vector2.ONE * (444.0 / atlas.get_height())
	opponent.position = Vector2(1008, 600 - 222)
	opponent.modulate = Color(0.72, 0.80, 0.90)
	_stage.add_child(opponent)
	rig = Rig.new()
	rig.name = "LayeredPierrot"
	rig.position = Vector2(320, 600)
	rig.scale = Vector2.ONE * 0.90
	_stage.add_child(rig)
	_build_controls()
	_guides = Node2D.new()
	_guides.z_index = 100
	_guides.draw.connect(_draw_guides)
	_stage.add_child(_guides)
	resized.connect(_layout)
	_layout()
	seek(0.0)


func _build_controls() -> void:
	var title := _text("PIERROT  /  PCHNIĘCIE LOSU", Vector2(28, 21), 23, Color("e4c272"))
	title.size.x = 700
	_text(
		"PROTOTYP WARSTWOWY 2D · RUCH BEZ MAGII · PORTRETY W GRZE BEZ ZMIAN",
		Vector2(30, 55),
		12,
		Color("adbdcf")
	)
	_label = _text("", Vector2(900, 25), 16, Color("e1b4c2"))
	_label.size.x = 345
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	_play = _button("Odtwórz pchnięcie", Vector2(28, 648), Vector2(180, 42))
	_play.pressed.connect(toggle_play)
	_slider = HSlider.new()
	_slider.position = Vector2(229, 655)
	_slider.size = Vector2(425, 30)
	_slider.min_value = 0
	_slider.max_value = 1
	_slider.step = 0.001
	_slider.value_changed.connect(
		func(value: float) -> void:
			playing = false
			seek(value)
	)
	_stage.add_child(_slider)
	var slow := _button("Tempo 1×", Vector2(678, 648), Vector2(130, 42))
	slow.pressed.connect(
		func() -> void:
			speed = 0.35 if speed == 1.0 else 1.0
			slow.text = "Tempo 0,35×" if speed < 1.0 else "Tempo 1×"
	)
	var guides := _button("Pokaż kości", Vector2(822, 648), Vector2(150, 42))
	guides.pressed.connect(
		func() -> void:
			show_guides = not show_guides
			rig.debug_bones = show_guides
			rig.queue_redraw()
			guides.text = "Ukryj kości" if show_guides else "Pokaż kości"
			queue_redraw()
	)
	var reset := _button("Pozycja wyjściowa", Vector2(986, 648), Vector2(266, 42))
	reset.pressed.connect(
		func() -> void:
			playing = false
			seek(0.0)
	)
	_text(
		"Spacja: odtwórz / pauza    •    Suwak: sprawdź dowolną fazę ruchu",
		Vector2(230, 696),
		11,
		Color("96a7bc")
	)


func _process(delta: float) -> void:
	if not playing:
		return
	_time += delta * speed
	seek(minf(1.0, _time / DURATION))
	if progress >= 1.0:
		playing = false
		_play.text = "Odtwórz ponownie"


func _unhandled_key_input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_SPACE:
		toggle_play()
		get_viewport().set_input_as_handled()


func toggle_play() -> void:
	if progress >= 1.0:
		seek(0.0)
	playing = not playing
	_play.text = "Pauza" if playing else "Odtwórz pchnięcie"


func seek(value: float) -> void:
	progress = clampf(value, 0.0, 1.0)
	_time = progress * DURATION
	var local_target := (target - rig.position) / rig.scale
	rig.set_pose(progress, local_target)
	_slider.set_value_no_signal(progress)
	_label.text = Pose.phase_name(progress)
	_play.text = "Pauza" if playing else "Odtwórz pchnięcie"
	queue_redraw()


func _layout() -> void:
	var factor := minf(size.x / DESIGN_SIZE.x, size.y / DESIGN_SIZE.y)
	_stage.scale = Vector2.ONE * factor
	_stage.position = (size - DESIGN_SIZE * factor) * 0.5


func _text(value: String, at: Vector2, font_size: int, tint: Color) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", tint)
	label.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.9))
	label.add_theme_constant_override("shadow_offset_y", 2)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_stage.add_child(label)
	return label


func _button(value: String, at: Vector2, dimensions: Vector2) -> Button:
	var button := Button.new()
	button.text = value
	button.position = at
	button.size = dimensions
	button.add_theme_font_size_override("font_size", 14)
	var style := StyleBoxFlat.new()
	style.bg_color = Color(0.025, 0.04, 0.065, 0.86)
	style.border_color = Color("695637")
	style.set_border_width_all(1)
	style.set_corner_radius_all(5)
	button.add_theme_stylebox_override("normal", style)
	var hover := style.duplicate() as StyleBoxFlat
	hover.bg_color = Color("192539")
	hover.border_color = Color("dcb765")
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", hover)
	_stage.add_child(button)
	return button


func _draw() -> void:
	if _guides != null:
		_guides.queue_redraw()


func _draw_guides() -> void:
	if not show_guides:
		return
	_guides.draw_line(Vector2(100, 600), Vector2(1170, 600), Color(0.3, 0.8, 0.8, 0.5), 1.0)
	_guides.draw_arc(target, 12, 0, TAU, 32, Color.ORANGE_RED, 1.5, true)
