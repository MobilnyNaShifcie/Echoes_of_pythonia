extends PanelContainer
## A reusable resource requirement, not an inventory item or a purchase action.
var resource_id := ""
var owned := 0
var required := 0


func configure(data: Dictionary) -> void:
	resource_id = str(data.id)
	owned = int(data.owned)
	required = int(data.required)
	%ResourceName.text = data.name
	%ResourceName.tooltip_text = data.name
	%ResourceIcon.texture = data.icon
	%GoldSymbol.visible = resource_id == "gold"
	%Owned.text = "Posiadasz %d" % owned
	%Required.text = "Potrzeba %d" % required
	var enough := owned >= required
	%Availability.text = "✓  Wystarczy" if enough else "Brakuje %d" % (required - owned)
	%Availability.add_theme_color_override(
		"font_color", Color(0.48, 0.87, 0.59) if enough else Color(1, 0.43, 0.37)
	)
