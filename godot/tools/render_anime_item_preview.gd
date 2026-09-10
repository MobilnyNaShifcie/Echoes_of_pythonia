extends SceneTree
## Preview uses a throwaway session in memory, never SaveGameService.
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const ThemeResource = preload("res://ui/theme/game_theme.tres")
const OUTPUT := "res://../output/item_art/anime_batch_01_in_game.png"


func _init() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	var session = NewGame.new().create_session("Aria", 1)
	session.player.character_class_code = "mage"
	session.player.gender_code = "female"
	session.player.level = 8
	for item_id: String in [
		"rotting_knight_helm", "cultist_pendant", "spiderstep_boots",
		"spiderweave_gloves", "blackwood_staff", "blackwood_mail",
		"black_bear_claw", "spider_silk", "venom_gland", "cultist_cloth",
	]:
		session.player.inventory.add(item_id)
	var screen = Equipment.instantiate()
	screen.theme = ThemeResource
	screen.configure(session)
	root.add_child(screen)
	screen.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	await create_timer(0.5).timeout
	await RenderingServer.frame_post_draw
	var result := root.get_texture().get_image().save_png(OUTPUT)
	print("ANIME ITEM INVENTORY PREVIEW: ", result)
	screen.queue_free()
	await process_frame
	quit(result)
