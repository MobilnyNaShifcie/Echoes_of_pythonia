extends Control

const PROJECT_VERSION := "0.25.0"

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	status_label.text = "Echoes of Pythonia v%s jest gotowe." % PROJECT_VERSION
