extends GutTest

const View = preload("res://ui/screens/black_market/market_item_3d.gd")


func test_unbased_artifacts_lie_down_with_centered_footprints_and_contact_shadows() -> void:
	var view = View.new()
	add_child_autofree(view)
	for item_id in ["hearth_core", "azhar_sigil", "leviathan_scale", "spark_of_life"]:
		view.build(item_id)
		var first := true
		var bounds := AABB()
		for part: MeshInstance3D in view.model.get_children():
			if part.name == "ContactShadow":
				continue
			var box := part.get_aabb()
			box.position += part.position
			bounds = box if first else bounds.merge(box)
			first = false
		assert_almost_eq(bounds.position.y, 0.018, 0.0001, item_id)
		assert_lt(
			bounds.size.y,
			maxf(bounds.size.x, bounds.size.z) * 0.65,
			item_id + " rests on its broad side"
		)
		assert_almost_eq(bounds.get_center().x, 0.0, 0.001)
		assert_almost_eq(bounds.get_center().z, 0.0, 0.001)
		var shadow: MeshInstance3D = view.model.get_node("ContactShadow")
		assert_gt(shadow.mesh.size.x, bounds.size.x)
		assert_gt(shadow.mesh.size.y, bounds.size.z)
