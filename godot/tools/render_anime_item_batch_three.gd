extends SceneTree
## Batch 3 preview: throwaway in-memory inventory; no save-service access.
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const ThemeResource = preload("res://ui/theme/game_theme.tres")
const OUTPUT := "res://../output/item_art/anime_batch_03_in_game.png"


func _init() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	RenderingServer.set_default_clear_color(Color("#070e17"))
	var session = NewGame.new().create_session("Aria", 1)
	session.player.character_class_code = "mage"
	session.player.gender_code = "female"
	session.player.level = 20
	for item_id: String in [
		"ancient_order_key",
		"order_seal",
		"grandmaster_chain",
		"crown_fragment",
		"grandmaster_sword",
		"sunken_order_cloak",
		"varek_sabre_fragment",
		"azhar_blade",
		"azhar_crown",
		"azhar_ring",
		"black_fleet_medallion",
		"black_pearl_earrings",
		"black_sea_amulet",
		"captain_signet",
		"cursed_compass",
		"frozen_cloth",
		"ice_chitin",
		"leviathan_ring",
		"north_armor",
		"northern_trail_boots",
		"snow_griffin_cloak",
		"snow_griffin_feather",
		"white_fur",
		"varek_sabre",
		"black_sea_bow",
		"black_sea_staff",
		"black_tide_fate_lance",
		"hearthguard_shield",
		"order_bracelet",
		"abyss_ring",
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
	print("ANIME BATCH 3 INVENTORY PREVIEW: ", result)
	screen.queue_free()
	await process_frame
	quit(result)
