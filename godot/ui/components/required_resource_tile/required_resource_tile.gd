extends PanelContainer
## A reusable resource requirement, not an inventory item or a purchase action.
const Style := preload("res://ui/screens/blacksmith_workbench/workbench_style.gd")
const GOLD_ICON := preload("res://assets/ui/blacksmith/gold_stack.svg")
var resource_id := ""
var owned := 0
var required := 0


func configure(data: Dictionary) -> void:
	add_theme_stylebox_override("panel", Style.panel(0.65, 10))
	resource_id = str(data.id)
	owned = int(data.owned)
	required = int(data.required)
	%ResourceName.text = data.name
	%ResourceName.tooltip_text = data.name
	%ResourceIcon.texture = GOLD_ICON if resource_id == "gold" else data.icon
	%Owned.text = "%d / %d" % [owned, required]
	var enough := owned >= required
	tooltip_text = "%s\nPosiadasz: %d\nPotrzeba: %d" % [data.name, owned, required]
	%Owned.add_theme_color_override(
		"font_color", Color(0.48, 0.87, 0.59) if enough else Color(1, 0.43, 0.37)
	)
