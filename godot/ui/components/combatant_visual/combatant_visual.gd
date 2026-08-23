class_name CombatantVisual
extends Control

enum Mode {
	PLACEHOLDER,
	STATIC_TEXTURE,
	ANIMATED_SCENE,
}

var _mode := Mode.PLACEHOLDER
var _animated_instance: Node

@onready var static_texture: TextureRect = %StaticTexture
@onready var animated_host: Control = %AnimatedHost
@onready var placeholder: PanelContainer = %Placeholder
@onready var role_label: Label = %RoleLabel
@onready var name_label: Label = %NameLabel


func show_placeholder(role: String, display_name: String) -> void:
	_clear_animated_instance()
	_mode = Mode.PLACEHOLDER
	static_texture.texture = null
	static_texture.visible = false
	animated_host.visible = false
	placeholder.visible = true
	role_label.text = role
	name_label.text = display_name


func show_static(texture: Texture2D, role: String, display_name: String) -> void:
	_clear_animated_instance()
	_mode = Mode.STATIC_TEXTURE
	static_texture.texture = texture
	static_texture.visible = true
	animated_host.visible = false
	placeholder.visible = texture == null
	role_label.text = role
	name_label.text = display_name
	if texture == null:
		_mode = Mode.PLACEHOLDER


func show_animated(scene: PackedScene, role: String, display_name: String) -> void:
	_clear_animated_instance()
	static_texture.texture = null
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


func _clear_animated_instance() -> void:
	if _animated_instance == null:
		return
	if _animated_instance.get_parent() == animated_host:
		animated_host.remove_child(_animated_instance)
	_animated_instance.queue_free()
	_animated_instance = null
