extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const COMBATANT_VISUAL_SCENE := preload(
	"res://ui/components/combatant_visual/combatant_visual.tscn"
)
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const CombatActionCardClass := preload(
	"res://ui/components/combat_action_card/combat_action_card.gd"
)
const CombatantVisualClass := preload("res://ui/components/combatant_visual/combatant_visual.gd")
const CombatPresentationCatalogClass := preload(
	"res://ui/presentation/combat_presentation_catalog.gd"
)
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_combatant_visual_supports_placeholder_static_and_animated_presentations() -> void:
	var visual := COMBATANT_VISUAL_SCENE.instantiate() as CombatantVisualClass
	add_child_autofree(visual)
	visual.show_placeholder("BOHATER", "Aria")
	assert_eq(visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_true(visual.placeholder.visible)
	assert_eq(visual.name_label.text, "Aria")

	var texture := GradientTexture2D.new()
	visual.show_static(texture, "BOHATER", "Aria")
	assert_eq(visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_true(visual.static_texture.visible)
	assert_eq(visual.static_texture.texture, texture)
	assert_eq(visual.source_texture(), texture)
	assert_false(visual.placeholder.visible)
	var cropped_presentation := {
		"crop": Rect2(1, 2, 16, 24),
		"frame": Rect2(0.1, 0.05, 0.8, 0.91),
	}
	visual.show_static(texture, "BOHATER", "Aria", cropped_presentation)
	assert_true(visual.static_texture.texture is AtlasTexture)
	assert_eq(visual.presentation_frame(), cropped_presentation.frame)

	var animated_root := Control.new()
	animated_root.name = "AnimatedFighter"
	var animated_scene := PackedScene.new()
	assert_eq(animated_scene.pack(animated_root), OK)
	animated_root.free()
	visual.show_animated(animated_scene, "BOHATER", "Aria")
	assert_eq(visual.mode(), CombatantVisualClass.Mode.ANIMATED_SCENE)
	assert_true(visual.animated_host.visible)
	assert_eq(visual.animated_instance().name, "AnimatedFighter")

	visual.show_placeholder("BOHATER", "Aria")
	await get_tree().process_frame
	assert_eq(visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_null(visual.animated_instance())


func test_combat_scene_reserves_full_hd_space_for_art_vfx_and_centered_actions() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition")
	host.add_child(screen)
	screen.get_node("Page/Lower").drawer.pinned = true
	screen.get_node("Page/Lower").drawer.set_open(true, true)
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame

	var arena: Control = screen.get_node("Page/Arena")
	var player_visual: CombatantVisualClass = screen.player_visual
	var enemy_visual: CombatantVisualClass = screen.enemy_visual
	var action_dock: PanelContainer = screen.get_node("Page/Lower/ActionsDock")
	assert_gte(player_visual.size.x, 700.0)
	assert_gte(enemy_visual.size.x, 700.0)
	assert_lte(player_visual.get_global_rect().end.x, arena.get_global_rect().get_center().x)
	assert_gte(enemy_visual.get_global_rect().position.x, arena.get_global_rect().get_center().x)
	assert_almost_eq(
		(
			(
				screen.get_node("Page/Lower/PlayerCommandHud").global_position.x
				+ action_dock.get_global_rect().end.x
			)
			/ 2.0
		),
		screen.get_global_rect().get_center().x,
		1.0,
	)
	assert_eq(screen.get_node("Page/Lower/ActionsDock/Actions/ActionGrid").columns, 3)
	assert_true(screen.empty_skills_label.visible)
	assert_false(screen.skill_cards_scroll.visible)
	assert_string_contains(screen.battlefield_placeholder.text, "ZMIERZCHOWE RÓWNINY")
	assert_false(screen.battlefield_placeholder.visible)
	assert_true(screen.battlefield_texture.visible)
	assert_eq(player_visual.name_label.text, session.player.titled_display_name())
	assert_eq(player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_not_null(player_visual.source_texture())
	assert_eq(
		player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/seeker_female.png",
	)
	assert_string_contains(player_visual.role_label.text, "POSZUKIWACZ")
	assert_eq(enemy_visual.name_label.text, "Wilk")
	assert_eq(enemy_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_string_contains(screen.enemy_name_label.text, "Wilk")
	assert_false(screen.log_panel.visible)
	screen.log_toggle_button.pressed.emit()
	assert_true(screen.log_panel.visible)
	assert_eq(screen.log_toggle_button.text, "Ukryj dziennik")
	assert_string_contains(screen.turn_state_label.text, "RUNDA 1")
	assert_eq(screen.target_name_label.text, "Wilk")
	host.free()


func test_region_one_battlefield_uses_session_day_and_night_without_rng() -> void:
	var day_texture := CombatPresentationCatalogClass.battlefield_texture(
		"twilight_plains", "day", "expedition"
	)
	var night_texture := CombatPresentationCatalogClass.battlefield_texture(
		"twilight_plains", "night", "expedition"
	)
	assert_not_null(day_texture)
	assert_not_null(night_texture)
	assert_ne(day_texture, night_texture)
	assert_eq(day_texture.resource_path, "res://assets/combat/backgrounds/twilight_plains_day.png")
	assert_eq(
		night_texture.resource_path, "res://assets/combat/backgrounds/twilight_plains_night.png"
	)
	assert_null(
		CombatPresentationCatalogClass.battlefield_texture("twilight_plains", "day", "dungeon")
	)


func test_surface_enemy_region_selects_background_without_changing_session() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "twilight_plains"
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	add_child_autofree(screen)
	for hour: int in [12, 22]:
		session.hour = hour
		screen.configure(session, "ice_crab", "expedition")
		var period := session.period_code()
		assert_eq(
			screen.battlefield_texture.texture.resource_path,
			"res://assets/combat/backgrounds/ice_coast_%s.png" % period
		)
		assert_eq(session.current_location_id, "twilight_plains")
		assert_string_contains(screen.encounter_label.text, "LODOWE")
		screen.configure(session, "wolf", "expedition")
		assert_eq(
			screen.battlefield_texture.texture.resource_path,
			"res://assets/combat/backgrounds/twilight_plains_%s.png" % period
		)
	screen.configure(session, "ice_crab", "dungeon")
	assert_null(screen.battlefield_texture.texture)
	screen.configure(session, "ice_crab", "prologue")
	assert_null(screen.battlefield_texture.texture)
	assert_eq(
		CombatPresentationCatalogClass.enemy_region_id("unknown_enemy", "black_forest"),
		"black_forest"
	)


func test_region_one_uses_every_technically_valid_approved_enemy_asset() -> void:
	var expected_paths := {
		"wild_dog": "res://assets/combat/enemies/wild_dog.png",
		"slime": "res://assets/combat/enemies/slime.png",
		"wolf": "res://assets/combat/enemies/wolf.png",
		"boar": "res://assets/combat/enemies/boar.png",
		"bandit": "res://assets/combat/enemies/bandit.png",
		"cursed_scarecrow": "res://assets/combat/enemies/cursed_scarecrow.png",
		"plains_spirit": "res://assets/combat/enemies/plains_spirit.png",
		"night_guard": "res://assets/combat/enemies/night_guard.png",
		"hunter": "res://assets/combat/enemies/hunter.png",
		"nature_guardian": "res://assets/combat/enemies/nature_guardian.png",
	}
	for enemy_id: String in expected_paths:
		var texture := CombatPresentationCatalogClass.enemy_texture(enemy_id)
		assert_not_null(texture, enemy_id)
		assert_eq(texture.resource_path, expected_paths[enemy_id], enemy_id)
	assert_true(CombatPresentationCatalogClass.missing_region_one_enemy_assets().is_empty())


func test_regions_two_to_four_use_their_day_night_backgrounds_and_enemy_art() -> void:
	var expected_backgrounds := {
		"black_forest": "black_forest",
		"silentwater_marshes": "silentwater_marshes",
		"ashen_borderlands": "ashen_borderlands",
	}
	for region_id: String in expected_backgrounds:
		for period_code: String in ["day", "night"]:
			var texture := CombatPresentationCatalogClass.battlefield_texture(
				region_id, period_code, "expedition"
			)
			assert_not_null(texture, "%s %s" % [region_id, period_code])
			assert_eq(
				texture.resource_path,
				(
					"res://assets/combat/backgrounds/%s_%s.png"
					% [expected_backgrounds[region_id], period_code]
				),
			)
		assert_true(
			CombatPresentationCatalogClass.missing_enemy_assets_for_region(region_id).is_empty(),
			region_id,
		)

	var expected_enemy_paths := {
		"venom_spider": "venom_spider",
		"forest_cultist": "forest_cultist",
		"rotting_knight": "rotting_knight",
		"corrupted_bear": "corrupted_bear",
		"black_hart": "black_hart",
		"gallows_wraith": "gallows_wraith",
		"blackwood_executioner": "blackwood_executioner",
		"bog_crawler": "bog_crawler",
		"drowned_dead": "drowned_dead",
		"swamp_witch": "swamp_witch",
		"bone_crocodile": "bone_crocodile",
		"mist_walker": "mist_walker",
		"sunken_knight": "sunken_knight_anime",
		"drowned_mother": "drowned_mother",
		"sand_golem": "sand_golem",
		"desert_harpy": "desert_harpy",
		"desert_wanderer": "desert_wanderer",
		"boneburner": "boneburner",
		"red_salamander": "red_salamander",
		"hearth_devourer": "hearth_devourer",
		"azhar": "azhar",
	}
	for enemy_id: String in expected_enemy_paths:
		var presentation := CombatPresentationCatalogClass.enemy_presentation(enemy_id)
		var enemy_texture := presentation.get("texture") as Texture2D
		assert_not_null(enemy_texture, enemy_id)
		assert_eq(
			enemy_texture.resource_path,
			"res://assets/combat/enemies/%s.png" % expected_enemy_paths[enemy_id],
			enemy_id,
		)
		var frame: Rect2 = presentation.frame
		assert_almost_eq(frame.end.y, 0.96, 0.001, enemy_id)


func test_new_enemy_cutouts_keep_transparent_canvas_corners() -> void:
	for region_id: String in ["black_forest", "silentwater_marshes", "ashen_borderlands"]:
		var enemy_ids: Array = CombatPresentationCatalogClass.REGION_ENEMY_IDS[region_id]
		for enemy_id: String in enemy_ids:
			var texture := CombatPresentationCatalogClass.enemy_texture(enemy_id)
			var image := texture.get_image()
			assert_ne(image.detect_alpha(), Image.ALPHA_NONE, enemy_id)
			var last := image.get_size() - Vector2i.ONE
			for corner: Vector2i in [
				Vector2i.ZERO,
				Vector2i(last.x, 0),
				Vector2i(0, last.y),
				last,
			]:
				assert_lte(image.get_pixelv(corner).a, 0.01, enemy_id)


func test_region_one_profiles_crop_padding_and_share_a_ground_line() -> void:
	for enemy_id: String in ["wild_dog", "slime", "wolf", "boar", "bandit"]:
		var presentation := CombatPresentationCatalogClass.enemy_presentation(enemy_id)
		var crop: Rect2 = presentation.crop
		var frame: Rect2 = presentation.frame
		assert_gt(crop.size.x, 0.0, enemy_id)
		assert_gt(crop.size.y, 0.0, enemy_id)
		assert_almost_eq(frame.end.y, 0.96, 0.001, enemy_id)
	for enemy_id: String in [
		"cursed_scarecrow", "plains_spirit", "night_guard", "hunter", "nature_guardian"
	]:
		var tall_presentation := CombatPresentationCatalogClass.enemy_presentation(enemy_id)
		var tall_frame: Rect2 = tall_presentation.frame
		assert_almost_eq(tall_frame.end.y, 0.96, 0.001, enemy_id)


func test_gender_and_class_control_hero_art_without_silent_gender_changes() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	session.player.gender_code = "female"
	screen.configure(session, "wolf", "expedition")
	add_child_autofree(screen)
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/seeker_female.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "POSZUKIWACZKA")

	session.player.gender_code = "male"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/seeker_male.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "POSZUKIWACZ")

	session.player.character_class_code = "hunter"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/hunter_male.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "ŁOWCA")
	assert_false(screen.player_visual.role_label.text.contains("PIERROT"))

	session.player.character_class_code = "mage"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/mage_male.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "MAG")

	session.player.character_class_code = "warrior"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/warrior.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "WOJOWNIK")
	session.player.talent_ranks.heavy_knight_core = 1
	screen.configure(session, "wolf", "expedition")
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/warrior_heavy_knight.png",
	)
	session.player.talent_ranks.clear()

	session.player.character_class_code = "pierrot"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/pierrot_male.png",
	)
	session.player.gender_code = "female"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/pierrot.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "PIERROT")
	assert_string_contains(screen.class_resource_label.text, "ŻETONY")

	session.player.character_class_code = "mage"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/mage_female.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "MAG")

	session.player.character_class_code = "hunter"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/hunter_female.png",
	)

	session.player.character_class_code = "warrior"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/warrior_female.png",
	)
	session.player.talent_ranks.heavy_knight_core = 1
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_null(CombatPresentationCatalogClass.hero_texture_for_player(session.player))


func test_approved_gender_variants_keep_production_alpha_contract() -> void:
	for asset_path: String in [
		"res://assets/combat/heroes/warrior_female.png",
		"res://assets/combat/heroes/pierrot_male.png",
		"res://assets/combat/heroes/mage_male.png",
		"res://assets/combat/heroes/mage_female.png",
		"res://assets/combat/heroes/hunter_male.png",
		"res://assets/combat/heroes/hunter_female.png",
	]:
		var texture := load(asset_path) as Texture2D
		assert_not_null(texture, asset_path)
		var image := texture.get_image()
		assert_eq(image.get_size(), Vector2i(1024, 1536), asset_path)
		assert_eq(image.get_format(), Image.FORMAT_RGBA8, asset_path)
		for corner: Vector2i in [
			Vector2i.ZERO,
			Vector2i(1023, 0),
			Vector2i(0, 1535),
			Vector2i(1023, 1535),
		]:
			assert_almost_eq(image.get_pixelv(corner).a, 0.0, 0.001, asset_path)


func test_all_base_class_art_stays_inside_supported_combat_stages() -> void:
	var variants: Array[Dictionary] = [
		{
			"class_code": "warrior",
			"gender_code": "male",
			"path": "res://assets/combat/heroes/warrior.png",
		},
		{
			"class_code": "warrior",
			"gender_code": "female",
			"path": "res://assets/combat/heroes/warrior_female.png",
		},
		{
			"class_code": "hunter",
			"gender_code": "male",
			"path": "res://assets/combat/heroes/hunter_male.png",
		},
		{
			"class_code": "hunter",
			"gender_code": "female",
			"path": "res://assets/combat/heroes/hunter_female.png",
		},
		{
			"class_code": "mage",
			"gender_code": "male",
			"path": "res://assets/combat/heroes/mage_male.png",
		},
		{
			"class_code": "mage",
			"gender_code": "female",
			"path": "res://assets/combat/heroes/mage_female.png",
		},
		{
			"class_code": "pierrot",
			"gender_code": "male",
			"path": "res://assets/combat/heroes/pierrot_male.png",
		},
		{
			"class_code": "pierrot",
			"gender_code": "female",
			"path": "res://assets/combat/heroes/pierrot.png",
		},
	]
	for viewport_size: Vector2 in [Vector2(1920, 1080), Vector2(1280, 720)]:
		var host := Control.new()
		host.size = viewport_size
		add_child(host)
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
		screen.configure(session, "wolf", "expedition")
		host.add_child(screen)
		await get_tree().process_frame

		for variant: Dictionary in variants:
			session.player.character_class_code = variant.class_code
			session.player.gender_code = variant.gender_code
			screen.configure(session, "wolf", "expedition")
			await get_tree().process_frame
			assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
			assert_eq(screen.player_visual.source_texture().resource_path, variant.path)
			var visual_rect := screen.player_visual.get_global_rect()
			var texture_rect := screen.player_visual.static_texture.get_global_rect()
			assert_gte(texture_rect.position.x, visual_rect.position.x, variant.path)
			assert_gte(texture_rect.position.y, visual_rect.position.y, variant.path)
			assert_lte(texture_rect.end.x, visual_rect.end.x, variant.path)
			assert_lte(texture_rect.end.y, visual_rect.end.y, variant.path)

		host.free()


func test_night_weather_elite_and_miniboss_contexts_keep_art_independent() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.hour = 22
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wild_dog", "expedition", "aurora", null, "", "furious")
	add_child_autofree(screen)
	assert_eq(
		screen.battlefield_texture.texture.resource_path,
		"res://assets/combat/backgrounds/twilight_plains_night.png",
	)
	assert_eq(screen.enemy_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_string_contains(screen.enemy_role_label.text, "ELITA")
	assert_string_contains(screen.enemy_effect_label.text, "[ELITA]")
	assert_string_contains(screen.enemy_effect_label.text, "[ZORZA POLARNA]")
	assert_eq(screen.enemy_name_label.text, "Wściekły Dziki Pies")
	assert_false("ZORZA POLARNA" in screen.enemy_name_label.text)

	screen.configure(session, "nature_guardian", "expedition", "storm")
	assert_eq(screen.enemy_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(screen.enemy_role_label.text, "MINIBOSS")
	assert_string_contains(screen.enemy_effect_label.text, "[MINIBOSS]")
	assert_string_contains(screen.enemy_effect_label.text, "[BURZA]")


func test_skill_cards_are_live_actions_and_preserve_the_legacy_skill_adapter() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("warrior"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition")
	add_child_autofree(screen)

	assert_false(screen.empty_skills_label.visible)
	assert_true(screen.skill_cards_scroll.visible)
	assert_eq(screen.skill_cards.get_child_count(), screen.skill_selector.item_count)
	var first_card := screen.skill_cards.get_child(0) as CombatActionCardClass
	assert_eq(first_card.action_id, "power_slash")
	assert_string_contains(first_card.text, "POTĘŻNE CIĘCIE")
	assert_string_contains(first_card.text, "MANY")
	assert_false(first_card.disabled)
	assert_string_contains(first_card.text, "FIZYCZNE")
	var mana_before: int = session.player.stats.current_mana
	first_card.pressed.emit()
	assert_lt(session.player.stats.current_mana, mana_before)
	assert_string_contains(screen.combat_log.get_parsed_text(), "Potężne Cięcie")
	assert_string_contains(screen.turn_state_label.text, "RUNDA 2")
	assert_string_contains(screen.class_resource_label.text, "BLOK")


func test_combat_hud_keeps_player_commands_separate_without_duplicate_enemy_zone() -> void:
	var host := Control.new()
	host.size = Vector2(1920, 1080)
	add_child(host)
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.player.level = 5
	assert_true(session.player.choose_class("hunter"))
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "wolf", "expedition")
	host.add_child(screen)
	await get_tree().process_frame

	var lower: HBoxContainer = screen.get_node("Page/Lower")
	lower.drawer.pinned = true
	lower.drawer.set_open(true, true)
	await get_tree().process_frame
	await get_tree().process_frame
	var player_hud: PanelContainer = lower.get_node("PlayerCommandHud")
	var action_dock: PanelContainer = lower.get_node("ActionsDock")
	var target_hud: PanelContainer = lower.get_node("TargetCommandHud")
	assert_lte(player_hud.get_global_rect().end.x, action_dock.get_global_rect().position.x)
	assert_false(target_hud.is_visible_in_tree())
	assert_lte(action_dock.get_global_rect().end.x, screen.get_global_rect().end.x)
	assert_lte(lower.get_global_rect().end.y, screen.get_global_rect().end.y)
	assert_string_contains(screen.class_resource_label.text, "SEKWENCJA")
	assert_eq(screen.player_turn_icon.text, "Ł")
	assert_eq(screen.enemy_turn_icon.text, "W")
	host.free()


func test_region_one_screen_flow_reaches_rewards_continue_and_defeat() -> void:
	var victory_session = NewGameServiceClass.new().create_session("Aria", 1)
	var victory_screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	victory_screen.configure(victory_session, "wild_dog", "expedition")
	add_child_autofree(victory_screen)
	watch_signals(victory_screen)
	victory_screen._enemy.current_hp = 1
	victory_screen.attack_button.pressed.emit()
	assert_true(victory_screen.result_panel.visible)
	assert_string_contains(victory_screen.result_label.text, "Zwycięstwo")
	assert_string_contains(victory_screen.result_label.text, "EXP")
	assert_string_contains(victory_screen.result_label.text, "złota")
	assert_eq(victory_session.victories, 1)
	victory_screen.continue_button.pressed.emit()
	assert_signal_emitted_with_parameters(victory_screen, "finished", ["expedition", "victory"])

	var defeat_session = NewGameServiceClass.new().create_session("Aria", 2)
	defeat_session.player.stats.current_hp = 1
	var defeat_screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	defeat_screen.configure(defeat_session, "wolf", "expedition")
	add_child_autofree(defeat_screen)
	defeat_screen._enemy.attack = 100
	defeat_screen._enemy.dodge = 0.0
	defeat_screen.attack_button.pressed.emit()
	assert_true(defeat_screen.result_panel.visible)
	assert_string_contains(defeat_screen.result_label.text, "Porażka")
	assert_eq(defeat_screen.continue_button.text, "Kontynuuj")


func test_region_four_boss_uses_approved_azhar_art() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "ashen_borderlands"
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "azhar", "region_boss", "sunny", null, "WYZWANIE AZHARA")
	add_child_autofree(screen)
	assert_eq(screen.enemy_role_label.text, "BOSS")
	assert_eq(screen.enemy_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.enemy_visual.source_texture().resource_path,
		"res://assets/combat/enemies/azhar.png",
	)
	assert_string_contains(screen.enemy_visual.name_label.text, "Azhar")
