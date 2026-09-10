extends SceneTree
## Isolated visual fixture: never loads the app scene or a player's save.

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func _initialize() -> void:
	call_deferred("_render_previews")


func _render_previews() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1, null, "female")
	session.player.level = 5
	session.player.choose_class("mage")
	session.player.stats.current_hp = 5
	session.player.stats.current_mana = 0
	for item_id: String in ["weak_healing_potion", "great_healing_potion", "grandmaster_elixir"]:
		session.player.inventory.add(item_id, 2)
	var screen := COMBAT_SCENE.instantiate()
	screen.theme = load("res://ui/theme/game_theme.tres")
	screen.configure(session, "wolf", "expedition")
	root.content_scale_size = Vector2i.ZERO
	root.add_child(screen)
	screen.set_reduced_motion(true)
	var output_dir := ProjectSettings.globalize_path("res://../output/combat-consumables")
	DirAccess.make_dir_recursive_absolute(output_dir)
	for viewport_size in [Vector2i(1920, 1080), Vector2i(1600, 900)]:
		root.size = viewport_size
		for frame in 5:
			await process_frame
		await RenderingServer.frame_post_draw
		var capture := root.get_texture().get_image()
		var path := output_dir.path_join("combat_%dx%d.png" % [viewport_size.x, viewport_size.y])
		var error := capture.save_png(path)
		if error != OK:
			push_error("Cannot save combat preview: %s" % error)
			quit(1)
			return
		print("COMBAT_PREVIEW ", path)
	screen.free()
	quit()
