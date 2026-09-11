extends GutTest

const Catalog = preload("res://ui/presentation/combat_presentation_catalog.gd")
const Regions = preload("res://core/world/region_catalog.gd")
const Bosses = preload("res://core/world/region_boss_catalog.gd")
const NewGame = preload("res://core/game/new_game_service.gd")
const Combat = preload("res://ui/screens/combat/combat.tscn")
const Visual = preload("res://ui/components/combatant_visual/combatant_visual.gd")


func test_every_playable_region_has_backgrounds_and_all_actual_encounters() -> void:
	for region in Regions.get_all_definitions():
		assert_has(Catalog.REGION_ENEMY_IDS, region.region_id)
		for period: String in ["day", "night"]:
			assert_not_null(Catalog.battlefield_texture(region.region_id, period, "expedition"))
			for enemy_id: String in region.encounters_for(period):
				assert_not_null(Catalog.enemy_texture(enemy_id), region.region_id + ": " + enemy_id)
				assert_has(Catalog.REGION_ENEMY_IDS[region.region_id], enemy_id)
		var boss = Bosses.boss_for_region(region.region_id)
		if boss != null:
			assert_not_null(Catalog.enemy_texture(boss.boss_id), boss.boss_id)
		assert_true(Catalog.missing_enemy_assets_for_region(region.region_id).is_empty())


func test_ice_coast_has_distinct_day_night_and_all_seven_transparent_enemies() -> void:
	assert_eq(Catalog.REGION_FIVE_ENEMY_IDS.size(), 7)
	var day = Catalog.battlefield_texture("ice_coast", "day", "expedition")
	var night = Catalog.battlefield_texture("ice_coast", "night", "region_boss")
	assert_ne(day, night)
	assert_eq(day.resource_path, "res://assets/combat/backgrounds/ice_coast_day.png")
	assert_eq(night.resource_path, "res://assets/combat/backgrounds/ice_coast_night.png")
	assert_eq(day.get_size(), night.get_size())
	assert_null(Catalog.battlefield_texture("ice_coast", "day", "dungeon"))
	for enemy_id: String in Catalog.REGION_FIVE_ENEMY_IDS:
		var presentation: Dictionary = Catalog.enemy_presentation(enemy_id)
		var texture: Texture2D = presentation.texture
		assert_eq(texture.resource_path, "res://assets/combat/enemies/%s.png" % enemy_id)
		var image := texture.get_image()
		assert_ne(image.detect_alpha(), Image.ALPHA_NONE, enemy_id)
		var last := image.get_size() - Vector2i.ONE
		for corner: Vector2i in [Vector2i.ZERO, Vector2i(last.x, 0), Vector2i(0, last.y), last]:
			assert_lte(image.get_pixelv(corner).a, 0.01, enemy_id)
		var bounds := image.get_used_rect()
		assert_gt(bounds.position.x, 0, enemy_id)
		assert_gt(bounds.position.y, 0, enemy_id)
		assert_lt(bounds.end.x, image.get_width(), enemy_id)
		assert_lt(bounds.end.y, image.get_height(), enemy_id)
		assert_almost_eq(presentation.frame.end.y, 0.96, 0.001, enemy_id)


func test_real_combat_scene_binds_region_five_in_day_night_and_boss_context() -> void:
	for hour: int in [8, 22]:
		for enemy_id: String in Catalog.REGION_FIVE_ENEMY_IDS:
			var session = NewGame.new().create_session("Art QA", 1)
			session.current_location_id = "ice_coast"
			session.hour = hour
			var screen = Combat.instantiate()
			var context := "region_boss" if enemy_id == "leviathan_north" else "expedition"
			screen.configure(session, enemy_id, context)
			add_child(screen)
			await get_tree().process_frame
			assert_true(screen.battlefield_texture.visible, enemy_id)
			assert_false(screen.battlefield_placeholder.visible, enemy_id)
			assert_eq(screen.enemy_visual.mode(), Visual.Mode.STATIC_TEXTURE, enemy_id)
			assert_eq(screen.enemy_visual.source_texture(), Catalog.enemy_texture(enemy_id))
			assert_eq(
				screen.battlefield_texture.texture,
				Catalog.battlefield_texture("ice_coast", session.period_code(), context)
			)
			assert_true(screen.attack_button.visible)
			assert_false(screen.attack_button.disabled)
			screen.free()
