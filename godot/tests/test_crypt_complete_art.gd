extends GutTest

const App = preload("res://scenes/app/app.tscn")
const Combat = preload("res://ui/screens/combat/combat.tscn")
const Dungeon = preload("res://ui/screens/dungeon/dungeon.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Run = preload("res://core/dungeons/dungeon_run_state.gd")
const Catalog = preload("res://core/dungeons/dungeon_catalog.gd")
const Art = preload("res://ui/presentation/dungeon_presentation_catalog.gd")
const Presentation = preload("res://ui/presentation/combat_presentation_catalog.gd")
const Visual = preload("res://ui/components/combatant_visual/combatant_visual.gd")
const CRYPT := "sunken_order_crypt"
const NEW_ENEMIES := [
	"drowned_acolyte",
	"drowned_priestess",
	"iron_gate_guardian",
	"crypt_warden",
	"order_grandmaster",
	"sunken_knight",
]


class MemorySave:
	extends SaveGameService

	var calls := 0

	func save_session(_session: GameSession) -> Dictionary:
		calls += 1
		return {"ok": true, "message": "Memory-only test save"}


func test_every_enemy_in_actual_crypt_encounter_pools_has_art() -> void:
	assert_eq(Presentation.missing_enemy_assets_for_dungeon(CRYPT), [])
	var dungeon = Catalog.get_definition(CRYPT)
	var ids: Array = []
	for pool: Array in [
		dungeon.room_one_enemies,
		dungeon.room_two_enemies,
		dungeon.room_three_enemies,
		[
			dungeon.iron_path_enemy,
			dungeon.flooded_ambush_enemy,
			dungeon.mandatory_elite_enemy,
			dungeon.boss_enemy
		]
	]:
		for id: String in pool:
			if id not in ids:
				ids.append(id)
			assert_not_null(Presentation.enemy_texture(id), id)
	assert_eq(ids.size(), 9)
	assert_true(
		"admiral_varek" in Presentation.missing_enemy_assets_for_dungeon("black_fleet_wreck")
	)


func test_new_enemy_assets_have_real_alpha_and_complete_uncropped_silhouettes() -> void:
	for id: String in NEW_ENEMIES:
		var texture := Presentation.enemy_texture(id)
		assert_not_null(texture, id)
		if texture == null:
			continue
		var image := texture.get_image()
		assert_ne(image.detect_alpha(), Image.ALPHA_NONE, id)
		var used := image.get_used_rect()
		assert_gt(used.position.x, 0, id)
		assert_gt(used.position.y, 0, id)
		assert_lt(used.end.x, image.get_width(), id)
		assert_lt(used.end.y, image.get_height(), id)
		assert_gt(used.size.y, 1000, id)
		for point: Vector2i in [
			Vector2i.ZERO,
			Vector2i(image.get_width() - 1, 0),
			Vector2i(0, image.get_height() - 1),
			image.get_size() - Vector2i.ONE
		]:
			assert_eq(image.get_pixelv(point).a, 0.0, id)


func test_six_chambers_are_distinct_and_only_used_in_the_crypt() -> void:
	var paths: Array[String] = []
	assert_eq(Art.CRYPT_ROOMS.size(), 6)
	for id: String in Art.CRYPT_ROOMS:
		var texture := Art.background_texture(CRYPT, id)
		assert_not_null(texture, id)
		assert_false(texture.resource_path in paths)
		paths.append(texture.resource_path)
		assert_gt(texture.get_width(), 1500)
		assert_almost_eq(float(texture.get_width()) / texture.get_height(), 16.0 / 9.0, 0.02)
		assert_null(Art.background_texture("black_fleet_wreck", id))
		assert_ne(
			Presentation.battlefield_texture("silentwater_marshes", "day", "expedition", CRYPT, id),
			texture
		)
	assert_eq(Art.background_texture(CRYPT, "unknown"), Art.background_texture(CRYPT))


func test_room_selection_is_pure_and_uses_steps_not_translated_titles() -> void:
	var run = Run.new(CRYPT)
	for step: String in Art.STEP_ROOMS:
		run.step = step
		run.pending_battle_title = "A changed localized title"
		assert_eq(Art.room_for_run(run), Art.STEP_ROOMS[step], step)
		assert_eq(run.step, step)
	run.step = "in_combat"
	for destination: String in Art.ENCOUNTER_ROOMS:
		run.pending_next_step = destination
		var before: String = run.pending_next_step
		assert_eq(Art.room_for_run(run), Art.ENCOUNTER_ROOMS[destination], destination)
		assert_eq(run.pending_next_step, before)
	run.step = "finished"
	run.outcome = "completed"
	assert_eq(Art.room_for_run(run), "grandmaster_gate")
	assert_eq(Art.room_for_run(Run.new("black_fleet_wreck")), "")


func test_decision_screen_tracks_each_chamber() -> void:
	var session = NewGame.new().create_session("Crypt art QA", 1)
	for step: String in Art.STEP_ROOMS:
		if step == "entrance":
			continue
		var run = Run.new(CRYPT)
		run.step = step
		var screen = Dungeon.instantiate()
		screen.configure(session, CRYPT, run)
		add_child(screen)
		assert_eq(
			screen.background_texture.texture,
			Art.background_texture(CRYPT, Art.STEP_ROOMS[step]),
			step
		)
		assert_gt(screen.actions.get_child_count(), 0, step)
		screen.free()


func test_combat_uses_requested_room_and_resets_it_for_surface() -> void:
	var session = NewGame.new().create_session("Crypt art QA", 1)
	session.current_location_id = "silentwater_marshes"
	var screen = Combat.instantiate()
	add_child(screen)
	for room: String in Art.CRYPT_ROOMS:
		screen.configure(session, "order_grandmaster", "dungeon", "rain", null, "", "", CRYPT, room)
		assert_eq(screen.battlefield_texture.texture, Art.background_texture(CRYPT, room))
		assert_false(screen._uses_surface_weather())
	screen.configure(session, "sunken_knight", "expedition")
	assert_eq(screen._dungeon_room_id, "")
	assert_eq(screen._dungeon_id, "")
	screen.free()


func test_flip_metadata_is_applied_and_cleared_on_reuse() -> void:
	var scene = load("res://ui/components/combatant_visual/combatant_visual.tscn").instantiate()
	add_child(scene)
	var texture = Presentation.enemy_texture("order_grandmaster")
	scene.show_static(texture, "", "", {"flip_h": true})
	assert_true(scene.static_texture.flip_h)
	scene.show_static(texture, "", "")
	assert_false(scene.static_texture.flip_h)
	scene.show_static(texture, "", "", {"flip_h": true})
	scene.show_placeholder("", "")
	assert_false(scene.static_texture.flip_h)
	scene.free()


func test_all_new_fighters_fit_three_combat_canvases() -> void:
	for dimensions: Vector2 in [Vector2(1280, 720), Vector2(1920, 1080), Vector2(2560, 1080)]:
		var host := Control.new()
		host.size = dimensions
		add_child(host)
		var session = NewGame.new().create_session("Crypt art QA", 1)
		for id: String in NEW_ENEMIES:
			var screen = Combat.instantiate()
			screen.configure(
				session, id, "dungeon", "sunny", null, "", "", CRYPT, "grandmaster_gate"
			)
			host.add_child(screen)
			await get_tree().process_frame
			await get_tree().process_frame
			var arena: Control = screen.get_node("Page/Arena")
			var bounds: Rect2 = screen.enemy_visual.static_texture.get_global_rect()
			assert_eq(screen.enemy_visual.mode(), Visual.Mode.STATIC_TEXTURE, id)
			assert_true(arena.get_global_rect().encloses(bounds), id)
			assert_gte(bounds.position.y, arena.get_node("EnemyPanel").get_global_rect().end.y, id)
			screen.free()
		host.free()


func test_full_iron_route_art_rewards_and_return_to_map() -> void:
	await _complete_route("iron", true)


func test_full_flooded_route_with_ambush_art_rewards_and_return() -> void:
	await _complete_route("flooded", true)


func test_full_flooded_route_without_ambush_art_rewards_and_return() -> void:
	await _complete_route("flooded", false)


func _complete_route(branch: String, ambush: bool) -> void:
	var app = App.instantiate()
	var memory_save := MemorySave.new()
	app._save_service = memory_save
	add_child(app)
	var session = NewGame.new().create_session("Crypt QA", 1)
	session.player.level = 8
	session.player.choose_class("warrior")
	session.player.inventory.add("ancient_order_key")
	app._current_session = session
	app._dungeon_rng.seed = 401
	app._show_dungeon(CRYPT)
	app.screen_host.get_child(0).actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	var combats := 0
	for iteration in 30:
		var run = app._active_dungeon_run
		if run.is_finished():
			break
		var screen = app.screen_host.get_child(0)
		if run.step == "in_combat":
			combats += 1
			assert_eq(screen._dungeon_room_id, Art.room_for_run(run))
			assert_eq(
				screen.battlefield_texture.texture,
				Art.background_texture(CRYPT, Art.room_for_run(run))
			)
			assert_eq(screen.enemy_visual.mode(), Visual.Mode.STATIC_TEXTURE)
			# Only the disposable test enemy is weakened. Real buttons, reward
			# resolution, completion and navigation still run through the app.
			screen.set_reduced_motion(true)
			screen._enemy.current_hp = 1
			screen._enemy.defense = 0
			screen._enemy.dodge = 0.0
			screen.attack_button.pressed.emit()
			for frame in 60:
				if screen.result_panel.visible:
					break
				await get_tree().process_frame
			assert_eq(screen._engine.result, "victory")
			assert_true(screen.result_panel.visible)
			screen.continue_button.pressed.emit()
		elif run.step == "crossroads":
			screen.actions.get_child(0 if branch == "iron" else 1).pressed.emit()
		else:
			if run.step == "flooded_chest":
				run.branch_ambush_pending = ambush
			screen.actions.get_child(0).pressed.emit()
		await get_tree().process_frame
	var run = app._active_dungeon_run
	assert_true(run.completed)
	assert_eq(run.outcome, "completed")
	assert_eq(combats, 6 if branch == "iron" or ambush else 5)
	assert_eq(session.player.inventory.count("ancient_order_key"), 0)
	assert_gte(session.player.inventory.count("crown_fragment"), 1)
	assert_gte(session.player.inventory.count("grandmaster_chain"), 1)
	assert_eq(memory_save.calls, 1)
	var result_screen = app.screen_host.get_child(0)
	assert_eq(
		result_screen.background_texture.texture, Art.background_texture(CRYPT, "grandmaster_gate")
	)
	assert_string_contains(result_screen.loot_label.text, "ŁUP Z WYPRAWY")
	result_screen.actions.get_child(0).pressed.emit()
	await get_tree().process_frame
	assert_null(app._active_dungeon_run)
	assert_eq(session.current_location_id, "silentwater_marshes")
	app.free()
