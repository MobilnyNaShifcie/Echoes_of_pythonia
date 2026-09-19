extends PanelContainer
## A reusable resource requirement, not an inventory item or a purchase action.
const Style := preload("res://ui/screens/blacksmith_workbench/workbench_style.gd")
const GOLD_ICON := preload("res://assets/ui/blacksmith/gold_stack.svg")
var resource_id := ""
var owned := 0
var required := 0


func configure(data: Dictionary, compact := false) -> void:
	# Multiple upgrade tiers must fit together, not disappear below a one-row viewport.
	add_theme_stylebox_override("panel", Style.panel(0.65, 4 if compact else 10))
	custom_minimum_size.y = 60 if compact else 92
	$Content.add_theme_constant_override("separation", 6 if compact else 14)
	$Content/Icon.custom_minimum_size.x = 40 if compact else 62
	%ResourceName.add_theme_font_size_override("font_size", 16 if compact else 18)
	%Owned.add_theme_font_size_override("font_size", 18 if compact else 20)
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
