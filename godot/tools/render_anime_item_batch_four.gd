extends SceneTree
## Batch 4 preview: throwaway in-memory inventory; no save-service access.
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const ThemeResource = preload("res://ui/theme/game_theme.tres")
const OUTPUT := "res://../output/item_art/anime_batch_04_in_game.png"


func _init() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	RenderingServer.set_default_clear_color(Color("#070e17"))
	var session = NewGame.new().create_session("Aria", 1)
	session.player.character_class_code = "mage"
	session.player.gender_code = "female"
	session.player.level = 20
	for item_id: String in [
		"echo_quiver",
		"weave_relic",
		"trickster_card_deck",
		"rift_bastion_shield",
		"last_guard_plate",
		"oathbreaker_edge",
		"warden_chain",
		"third_echo_quiver",
		"riftglass_bow",
		"silent_volley_cloak",
		"afterimage_ring",
		"split_weave_artifact",
		"twin_star_staff",
		"empty_mana_robe",
		"storm_archive_relic",
		"two_lies_dice",
		"deck_without_ace",
		"seven_chances_lance",
		"crooked_smile_mask",
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
	print("ANIME BATCH 4 INVENTORY PREVIEW: ", result)
	screen.queue_free()
	await process_frame
	quit(result)
