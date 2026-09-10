extends SceneTree
## Real app UI, isolated in-memory sessions. Never reads or writes a player's save.
const App = preload("res://scenes/app/app.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Skills = preload("res://core/skills/skill_catalog.gd")
const OUTPUT := "res://../output/combat_hud/"


class MemorySave:
	extends SaveGameService

	func save_session(_session: GameSession) -> Dictionary:
		return {"ok": true, "message": "Preview only"}


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("_render_previews")


func _render_previews() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for dimensions: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2560, 1080)]:
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
		for fixture: Array in [
			["none", 1], ["warrior", 5], ["mage", 12], ["hunter", 30], ["pierrot", 12]
		]:
			var code: String = fixture[0]
			var session = NewGame.new().create_session("Aria", 1, null, "female")
			session.player.level = fixture[1]
			if code != "none":
				session.player.choose_class(code)
			if code == "hunter":
				for skill in Skills.get_preview_skills_for_class(code):
					if skill.unlock_source == "talent":
						session.player.unlocked_talent_skill_ids.append(skill.skill_id)
			if code == "mage":
				session.player.unlocked_class_mechanic_ids.assign(
					["arcana_core", "arcana_double_weave"]
				)
			session.player.inventory.add("strong_healing_potion", 3)
			session.player.inventory.add("grandmaster_elixir")
			session.player.stats.current_hp = maxi(1, session.player.stats.max_hp / 2)
			app._current_session = session
			if code == "mage":
				app._show_combat(
					"order_grandmaster",
					"dungeon",
					"sunny",
					null,
					"Krypta Zatopionego Zakonu — Finał",
					"",
					"sunken_order_crypt",
					"grandmaster_gate"
				)
			else:
				app._show_combat("wolf", "expedition")
			var screen = app.screen_host.get_child(0)
			screen.set_reduced_motion(true)
			await _capture(viewport, code, dimensions)
			if code == "mage":
				screen._engine.mage_arcane_weave = 3
				screen._render()
				screen.weave_toggle_button.button_pressed = true
				screen.skill_selector.select(1)
				screen.skill_selector.item_selected.emit(1)
				screen.second_spell_selector.select(2)
				screen.second_spell_selector.item_selected.emit(2)
				await _capture(viewport, "mage_weave", dimensions)
			if code == "hunter":
				screen.get_node("Page/Lower").scroll_cards(5)
				await _capture(viewport, "hunter_last_cards", dimensions)
			if code == "warrior":
				screen._enemy.current_hp = 1
				screen._enemy.defense = 0
				screen._enemy.dodge = 0.0
				screen.attack_button.pressed.emit()
				await _capture(viewport, "victory", dimensions)
		app.free()
		viewport.queue_free()
		await process_frame
	print("COMBAT HUD PREVIEW COMPLETE — 24 captures, memory-only saves")
	quit()


func _capture(viewport: SubViewport, stage: String, dimensions: Vector2i) -> void:
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := OUTPUT + "%s_%dx%d.png" % [stage, dimensions.x, dimensions.y]
	var error := viewport.get_texture().get_image().save_png(path)
	if error != OK:
		push_error("Cannot save combat HUD preview: %s" % error)
		quit(1)
	print("COMBAT_HUD_CAPTURE ", path)
