extends SceneTree
## Batch 2 preview: throwaway in-memory inventory; no save-service access.
const NewGame = preload("res://core/game/new_game_service.gd")
const Equipment = preload("res://ui/screens/equipment/equipment.tscn")
const ThemeResource = preload("res://ui/theme/game_theme.tres")
const OUTPUT := "res://../output/item_art/anime_batch_02_in_game.png"


func _init() -> void:
	call_deferred("render_preview")


func render_preview() -> void:
	RenderingServer.set_default_clear_color(Color("#070e17"))
	var session = NewGame.new().create_session("Aria", 1)
	session.player.character_class_code = "mage"
	session.player.gender_code = "female"
	session.player.level = 13
	for item_id: String in [
		"ancient_scale",
		"bone_fang",
		"scale_belt",
		"mist_essence",
		"mist_earrings",
		"witch_herb",
		"witchbone_ring",
		"sunken_plate",
		"sunken_knight_armor",
		"silentwater_heart",
		"drowned_mother_medallion",
		"drowned_mother_blade",
		"drowned_mother_crown",
		"mireglass_bow",
		"mire_staff",
		"drowned_fate_lance",
		"charred_bone",
		"cursed_resin",
		"desert_cloth",
		"wasteland_belt",
		"wasteland_armor",
		"harpy_feather",
		"salamander_scale",
		"hearth_gauntlets",
		"sand_golem_core",
		"sun_talisman",
		"ashwind_bow",
		"ember_staff",
		"ashen_fate_lance",
		"great_healing_potion",
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
	print("ANIME BATCH 2 INVENTORY PREVIEW: ", result)
	screen.queue_free()
	await process_frame
	quit(result)

