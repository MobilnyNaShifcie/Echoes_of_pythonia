extends SceneTree
## Memory-only art QA. Never loads or saves a player's game.
const Combat = preload("res://ui/screens/combat/combat.tscn")
const NewGame = preload("res://core/game/new_game_service.gd")
const Bosses = preload("res://core/world/region_boss_catalog.gd")
const Catalog = preload("res://ui/presentation/combat_presentation_catalog.gd")
const OUTPUT := "res://../output/ice_coast/in_game/"


func _init() -> void:
	if not InputMap.has_action("dialogic_default_action"):
		InputMap.add_action("dialogic_default_action")
	call_deferred("render_preview")


func render_preview() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for enemy_id: String in Catalog.REGION_FIVE_ENEMY_IDS:
		var session = NewGame.new().create_session("Aria", 1)
		session.current_location_id = "ice_coast"
		session.player.character_class_code = "hunter"
		session.player.gender_code = "male"
		session.hour = 22 if enemy_id in ["black_sea_siren", "ghost_ship_captain"] else 8
		var screen = Combat.instantiate()
		var context := "region_boss" if enemy_id == "leviathan_north" else "expedition"
		var boss = Bosses.get_definition(enemy_id)
		screen.configure(session, enemy_id, context, "sunny",
			boss.engine_script if boss != null else null)
		root.add_child(screen)
		screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		await create_timer(0.2).timeout
		await RenderingServer.frame_post_draw
		var error := root.get_texture().get_image().save_png(OUTPUT + enemy_id + ".png")
		print("ICE_COAST_SCREENSHOT ", enemy_id, " ", error)
		screen.queue_free()
		await process_frame
	print("ICE COAST PREVIEW COMPLETE")
	quit()
