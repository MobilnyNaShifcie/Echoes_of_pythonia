extends Control

const PROJECT_VERSION := "0.25.0"

@onready var status_label: Label = %StatusLabel


func _ready() -> void:
	status_label.text = (
		"Szkielet v%s działa. Następny krok: migracja modelu domenowego." % PROJECT_VERSION
	)
