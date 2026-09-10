class_name BlackMarketDropTarget
extends PanelContainer

signal offer_dropped(offer_id: String)

@onready var prompt_label: Label = %DropPromptLabel


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP


func _can_drop_data(_at_position: Vector2, data: Variant) -> bool:
	var accepted := (
		data is Dictionary
		and str((data as Dictionary).get("kind", "")) == "black_market_offer"
		and not str((data as Dictionary).get("offer_id", "")).is_empty()
	)
	prompt_label.modulate = Color(1.0, 0.84, 0.42) if accepted else Color.WHITE
	return accepted


func _drop_data(_at_position: Vector2, data: Variant) -> void:
	prompt_label.modulate = Color.WHITE
	if _can_drop_data(Vector2.ZERO, data):
		offer_dropped.emit(str((data as Dictionary).offer_id))
