extends SceneTree
## Fixed presentation reports in the real App. No RNG, rewards or disk saves.
const App := preload("res://scenes/app/app.tscn")
const NewGame := preload("res://core/game/new_game_service.gd")
const Plan := preload("res://ui/presentation/combat_presentation_plan.gd")
var output := "res://../build/combat-impact-review/after/evidence/"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render_previews")


func _render_previews() -> void:
	if not OS.get_cmdline_user_args().is_empty():
		output = OS.get_cmdline_user_args()[0]
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	for dimensions: Vector2i in [
		Vector2i(1280, 720), Vector2i(1366, 768), Vector2i(1920, 1080), Vector2i(2560, 1080)
	]:
		var viewport := SubViewport.new()
		viewport.size = dimensions
		var factor := minf(float(dimensions.x) / 1920.0, float(dimensions.y) / 1080.0)
		viewport.size_2d_override = Vector2i(Vector2(dimensions) / factor)
		viewport.size_2d_override_stretch = true
		viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(viewport)
		var app = App.instantiate()
		app._save_service = MemorySave.new()
		viewport.add_child(app)
		for fixture: Dictionary in [
			{"id": "hit", "report": {"player_damage": 4}},
			{"id": "critical", "report": {"player_damage": 7, "player_critical": true}},
			{"id": "dodge", "report": {"enemy_dodged": true}},
			{
				"id": "block",
				"report": {"enemy_acted": true, "shield_blocked": true, "enemy_damage": 2}
			},
			{
				"id": "reduced",
				"report": {"player_damage": 4, "enemy_acted": true, "enemy_damage": 2}
			}
		]:
			var session = NewGame.new().create_session("Aria", 1, null, "female")
			session.player.level = 5
			session.player.choose_class("warrior")
			app._current_session = session
			app._show_combat("wolf", "expedition")
			var screen = app.screen_host.get_child(0)
			var controller = screen._presentation_controller
			screen.set_reduced_motion(fixture.id == "reduced")
			for frame in 8:
				await process_frame
			var before: Dictionary = controller.resource_snapshot(session.player, screen._enemy)
			var after := before.duplicate()
			after.enemy_hp -= int(fixture.report.get("player_damage", 0))
			after.player_hp -= int(fixture.report.get("enemy_damage", 0))
			controller.present(Plan.from_report(fixture.report), before, after, 1)
			await create_timer(0.20).timeout
			await _capture(viewport, fixture.id + "_impact", dimensions)
			await create_timer(0.18).timeout
			await _capture(viewport, fixture.id + "_reaction", dimensions)
			await create_timer(0.52).timeout
			await _capture(viewport, fixture.id + "_settled", dimensions)
			if controller.is_busy():
				await controller.playback_finished
		app.free()
		viewport.queue_free()
		await process_frame
	print("COMBAT FEEDBACK PREVIEW COMPLETE — synthetic reports, memory-only saves")
	quit()


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	await RenderingServer.frame_post_draw
	var path := output.path_join("%s_%dx%d.png" % [stage, dimensions.x, dimensions.y])
	if viewport.get_texture().get_image().save_png(path) != OK:
		push_error("Cannot save feedback preview: " + path)
		quit(1)
	print("COMBAT_FEEDBACK_CAPTURE ", path)
