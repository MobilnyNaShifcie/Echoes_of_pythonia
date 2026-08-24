class_name CombatDie
extends PanelContainer

var value := 1

@onready var value_label: Label = %ValueLabel


func set_value(next_value: int, settled := true) -> void:
	value = clampi(next_value, 1, 6)
	value_label.text = str(value)
	value_label.add_theme_color_override(
		"font_color", Color(1.0, 0.72, 0.8) if settled else Color(0.88, 0.34, 0.52)
	)
	tooltip_text = "Kość k6 — wynik %d" % value if settled else "Kość k6 w ruchu"
