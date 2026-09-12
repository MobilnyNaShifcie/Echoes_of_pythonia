extends SceneTree
## Captures the actual app, including its character menu and equipment view.
const App := preload("res://scenes/app/app.tscn")
const Fixture := preload("res://tests/fixtures/equipment_layout_fixture.gd")
const Saves := preload("res://core/save/save_game_service.gd")
var _records: Array[Dictionary] = []


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	_run.call_deferred()


func _run() -> void:
	var args := OS.get_cmdline_user_args()
	if args.size() != 2 or not args[0].is_absolute_path() or not args[1].is_absolute_path():
		push_error("Expected absolute screenshot directory and isolated fixture-save directory")
		quit(1)
		return
	DirAccess.make_dir_recursive_absolute(args[0])
	for dimensions: Vector2i in [Vector2i(1920, 1080), Vector2i(1600, 900), Vector2i(1366, 768)]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = Saves.new(args[1])
		viewport.add_child(app)
		var session = Fixture.create_session()
		app._current_session = session
		app._show_equipment()
		await _settle()
		var menu = app.screen_host.get_child(0)
		var screen = menu.view_for_section("equipment")
		await RenderingServer.frame_post_draw
		var image := viewport.get_texture().get_image()
		var suffix := "%dx%d.png" % [dimensions.x, dimensions.y]
		assert(image.save_png(args[0].path_join("equipment_" + suffix)) == OK)
		var panel: Control = screen.get_node("Page/Workspace/PaperdollPanel/Content/Paperdoll")
		var panel_rect := panel.get_global_rect()
		var crop := Rect2i(panel_rect.position * factor, panel_rect.size * factor)
		assert(image.get_region(crop).save_png(args[0].path_join("panel_" + suffix)) == OK)
		var slots := {}
		for slot: String in screen.slot_buttons:
			var button: Control = screen.slot_buttons[slot]
			slots[slot] = _rect(button.get_global_rect())
			if dimensions.x == 1920 and slot in ["earrings", "bracelet"]:
				var detail := Rect2i(button.get_global_rect().grow(8.0))
				assert(image.get_region(detail).save_png(args[0].path_join(slot + ".png")) == OK)
		var visual: Control = screen.character_visual
		var hero: Rect2 = visual.character_visible_rect()
		hero.position += visual.global_position
		(
			_records
			. append(
				{
					"resolution": [dimensions.x, dimensions.y],
					"slots": slots,
					"panel": _rect(panel_rect),
					"hero": _rect(hero),
					"hero_source": visual.character_texture().resource_path,
					"earrings_icon": screen.slot_buttons.earrings.item_texture.resource_path,
					"bracelet_icon": screen.slot_buttons.bracelet.item_texture.resource_path,
				}
			)
		)
		# Stress only the nameplate presentation, never the actual player or class catalog.
		screen.equipment_panel.show_identity(
			"Żaneta Źdźbło Łucja Ćma Świątek",
			session.player.level,
			session.player.character_class_name + " — pełna nazwa klasy".repeat(12)
		)
		await _settle()
		await RenderingServer.frame_post_draw
		image = viewport.get_texture().get_image()
		assert(image.get_region(crop).save_png(args[0].path_join("nameplate_long_" + suffix)) == OK)
		viewport.render_target_update_mode = SubViewport.UPDATE_DISABLED
		app.queue_free()
		await _settle()
		viewport.queue_free()
		await _settle()
		print("EQUIPMENT CAPTURE ", suffix)
	var manifest := FileAccess.open(args[0].path_join("layout.json"), FileAccess.WRITE)
	manifest.store_string(JSON.stringify(_records, "\t"))
	manifest.close()
	quit(0)


func _rect(rect: Rect2) -> Array:
	return [rect.position.x, rect.position.y, rect.size.x, rect.size.y]


func _settle() -> void:
	for frame in 20:
		await process_frame
