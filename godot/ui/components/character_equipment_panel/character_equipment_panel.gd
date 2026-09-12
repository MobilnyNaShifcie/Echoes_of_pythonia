class_name CharacterEquipmentPanel
extends PanelContainer
## Presentation only. The host owns equipment, drag forwarding and save state.

const Equipment := preload("res://core/player/equipment.gd")

@onready var character_visual: CharacterPaperdoll = %CharacterVisual
@onready var nameplate_label: Label = %NameplateLabel
@onready var slot_buttons := {
	Equipment.HEAD: %HeadSlot,
	Equipment.WEAPON: %WeaponSlot,
	Equipment.CHEST: %ChestSlot,
	Equipment.HANDS: %HandsSlot,
	Equipment.BELT: %BeltSlot,
	Equipment.FEET: %FeetSlot,
	Equipment.OFF_HAND: %OffHandSlot,
	Equipment.EARRINGS: %EarringsSlot,
	Equipment.NECKLACE: %NecklaceSlot,
	Equipment.BRACELET: %BraceletSlot,
	Equipment.RING: %RingSlot,
}
@onready var _nameplate: PanelContainer = nameplate_label.get_parent()
@onready var _character_center: Control = character_visual.get_parent()


func _ready() -> void:
	resized.connect(_fit_slots)
	_fit_slots.call_deferred()
	_character_center.resized.connect(_fit_nameplate)
	_nameplate.get_parent().resized.connect(_fit_nameplate)
	nameplate_label.theme_changed.connect(_fit_nameplate)
	_fit_nameplate.call_deferred()
	for button: InventoryItemSlot in slot_buttons.values():
		# Reserve a separate caption band without changing shared backpack cells.
		var icon: TextureRect = button.get_node("ItemIcon")
		icon.offset_bottom = -28.0
		var label: Label = button.get_node("SlotCaption")
		label.add_theme_font_size_override("font_size", 14)
		label.offset_top = -25.0


func show_identity(display_name: String, level: int, class_name_text: String) -> void:
	nameplate_label.text = (
		"%s  •  POZIOM %d  •  %s" % [display_name.to_upper(), level, class_name_text.to_upper()]
	)
	_nameplate.tooltip_text = nameplate_label.text
	_fit_nameplate()


func _fit_nameplate() -> void:
	# Clipped text must not feed its natural width back into the parent containers.
	# Only the label presentation is shortened; its full text and the model stay intact.
	var font := nameplate_label.get_theme_font("font")
	var font_size := nameplate_label.get_theme_font_size("font_size")
	var text_width := (
		font.get_string_size(nameplate_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size).x
	)
	var margins := _nameplate.get_theme_stylebox("panel").get_minimum_size().x
	_nameplate.size = Vector2(
		minf(ceilf(text_width + margins), floorf(_character_center.size.x)),
		_nameplate.get_combined_minimum_size().y
	)
	_nameplate.position = ((_nameplate.get_parent().size - _nameplate.size) * 0.5).floor()


func _fit_slots() -> void:
	# Containers own every slot position. One shared size responds to panel height.
	var side := floorf(clampf((size.y - 152.0) / 6.72, 80.0, 104.0))
	for button: InventoryItemSlot in slot_buttons.values():
		button.custom_minimum_size = Vector2(side, side)
	var gap := roundi(side * 0.18)
	for column: String in ["LeftEquipmentVBox", "RightEquipmentVBox"]:
		var slots: VBoxContainer = get_node("Margin/Layout/EquipmentBodyHBox/" + column + "/Slots")
		slots.add_theme_constant_override("separation", gap)
