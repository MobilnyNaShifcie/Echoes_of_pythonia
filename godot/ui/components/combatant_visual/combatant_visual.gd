class_name CombatantVisual
extends Control

enum Mode {
	PLACEHOLDER,
	STATIC_TEXTURE,
	ANIMATED_SCENE,
}

static var _opaque_bounds: Dictionary = {}

var _mode := Mode.PLACEHOLDER
var _animated_instance: Node
var _source_texture: Texture2D
var _presentation_frame := Rect2(0.0, 0.0, 1.0, 1.0)

@onready var static_texture: TextureRect = %StaticTexture
@onready var animated_host: Control = %AnimatedHost
@onready var placeholder: PanelContainer = %Placeholder
@onready var role_label: Label = %RoleLabel
@onready var name_label: Label = %NameLabel


func _ready() -> void:
	resized.connect(_layout_grounded_texture)


func show_placeholder(role: String, display_name: String) -> void:
	_clear_animated_instance()
	_mode = Mode.PLACEHOLDER
	_source_texture = null
	static_texture.texture = null
	static_texture.flip_h = false
	_apply_static_frame(Rect2(0.0, 0.0, 1.0, 1.0))
	static_texture.visible = false
	animated_host.visible = false
	placeholder.visible = true
	role_label.text = role
	name_label.text = display_name


func show_static(
	texture: Texture2D, role: String, display_name: String, presentation: Dictionary = {}
) -> void:
	_clear_animated_instance()
	_mode = Mode.STATIC_TEXTURE
	_source_texture = texture
	static_texture.texture = _cropped_texture(texture, presentation.get("crop", Rect2()))
	static_texture.flip_h = bool(presentation.get("flip_h", false))
	_apply_static_frame(presentation.get("frame", Rect2(0.0, 0.0, 1.0, 1.0)))
	static_texture.visible = true
	animated_host.visible = false
	placeholder.visible = texture == null
	role_label.text = role
	name_label.text = display_name
	if texture == null:
		_mode = Mode.PLACEHOLDER


func show_animated(scene: PackedScene, role: String, display_name: String) -> void:
	_clear_animated_instance()
	_source_texture = null
	static_texture.texture = null
	static_texture.flip_h = false
	static_texture.visible = false
	role_label.text = role
	name_label.text = display_name
	if scene == null:
		_mode = Mode.PLACEHOLDER
		animated_host.visible = false
		placeholder.visible = true
		return
	_mode = Mode.ANIMATED_SCENE
	_animated_instance = scene.instantiate()
	animated_host.add_child(_animated_instance)
	if _animated_instance is Control:
		var animated_control := _animated_instance as Control
		animated_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	animated_host.visible = true
	placeholder.visible = false


func mode() -> Mode:
	return _mode


func animated_instance() -> Node:
	return _animated_instance


func source_texture() -> Texture2D:
	return _source_texture


func presentation_frame() -> Rect2:
	return _presentation_frame


func _cropped_texture(texture: Texture2D, crop: Rect2) -> Texture2D:
	if texture == null:
		return texture
	if crop.size.x <= 0.0 or crop.size.y <= 0.0:
		var key := texture.get_instance_id()
		if not _opaque_bounds.has(key):
			var pixels := texture.get_image()
			_opaque_bounds[key] = Rect2(pixels.get_used_rect()) if pixels != null else Rect2()
		crop = _opaque_bounds[key]
		if not crop.has_area():
			return texture
	var atlas := AtlasTexture.new()
	atlas.atlas = texture
	atlas.region = crop
	return atlas


func _apply_static_frame(frame: Rect2) -> void:
	_presentation_frame = frame
	static_texture.anchor_left = frame.position.x
	static_texture.anchor_top = frame.position.y
	static_texture.anchor_right = frame.end.x
	static_texture.anchor_bottom = frame.end.y
	static_texture.offset_left = 0.0
	static_texture.offset_top = 0.0
	static_texture.offset_right = 0.0
	static_texture.offset_bottom = 0.0
	_layout_grounded_texture()


func _layout_grounded_texture() -> void:
	if _mode != Mode.STATIC_TEXTURE or static_texture.texture == null or not size.x > 0:
		return
	# Fit the painted silhouette, not its transparent canvas, to a shared ground line.
	var frame := Rect2(_presentation_frame.position * size, _presentation_frame.size * size)
	var dimensions := static_texture.texture.get_size()
	var fit_height := minf(frame.size.y, size.y * 0.965 - frame.position.y)
	var scale_factor := minf(frame.size.x / dimensions.x, fit_height / dimensions.y)
	var fitted := dimensions * scale_factor
	static_texture.set_anchors_preset(Control.PRESET_TOP_LEFT)
	static_texture.position = Vector2(
		frame.get_center().x - fitted.x * 0.5, size.y * 0.965 - fitted.y
	)
	static_texture.size = fitted


func _clear_animated_instance() -> void:
	if _animated_instance == null:
		return
	if _animated_instance.get_parent() == animated_host:
		animated_host.remove_child(_animated_instance)
	_animated_instance.queue_free()
	_animated_instance = null
