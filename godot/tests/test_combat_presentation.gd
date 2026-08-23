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
		action_dock.get_global_rect().get_center().x,
		screen.get_global_rect().get_center().x,
		1.0,
	)
	assert_eq(screen.get_node("Page/Lower/ActionsDock/Actions/ActionGrid").columns, 4)
	assert_true(screen.empty_skills_label.visible)
	assert_false(screen.skill_cards_scroll.visible)
	assert_string_contains(screen.battlefield_placeholder.text, "ZMIERZCHOWE RÓWNINY")
	assert_false(screen.battlefield_placeholder.visible)
	assert_true(screen.battlefield_texture.visible)
	assert_eq(player_visual.name_label.text, session.player.titled_display_name())
	assert_eq(player_visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
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


func test_region_one_uses_every_technically_valid_approved_enemy_asset() -> void:
	var expected_paths := {
		"wild_dog": "res://assets/combat/enemies/wild_dog.png",
		"slime": "res://assets/combat/enemies/slime.png",
		"wolf": "res://assets/combat/enemies/wolf.png",
		"boar": "res://assets/combat/enemies/boar.png",
		"bandit": "res://assets/combat/enemies/bandit.png",
		"plains_spirit": "res://assets/combat/enemies/plains_spirit.png",
		"hunter": "res://assets/combat/enemies/hunter.png",
		"nature_guardian": "res://assets/combat/enemies/nature_guardian.png",
	}
	for enemy_id: String in expected_paths:
		var texture := CombatPresentationCatalogClass.enemy_texture(enemy_id)
		assert_not_null(texture, enemy_id)
		assert_eq(texture.resource_path, expected_paths[enemy_id], enemy_id)
	assert_eq(
		CombatPresentationCatalogClass.missing_region_one_enemy_assets(),
		["cursed_scarecrow", "night_guard"],
	)
	assert_null(CombatPresentationCatalogClass.enemy_texture("cursed_scarecrow"))
	assert_null(CombatPresentationCatalogClass.enemy_texture("night_guard"))


func test_region_one_profiles_crop_padding_and_share_a_ground_line() -> void:
	for enemy_id: String in ["wild_dog", "slime", "wolf", "boar", "bandit"]:
		var presentation := CombatPresentationCatalogClass.enemy_presentation(enemy_id)
		var crop: Rect2 = presentation.crop
		var frame: Rect2 = presentation.frame
		assert_gt(crop.size.x, 0.0, enemy_id)
		assert_gt(crop.size.y, 0.0, enemy_id)
		assert_almost_eq(frame.end.y, 0.96, 0.001, enemy_id)
	for enemy_id: String in ["plains_spirit", "hunter", "nature_guardian"]:
		var tall_presentation := CombatPresentationCatalogClass.enemy_presentation(enemy_id)
		var tall_frame: Rect2 = tall_presentation.frame
		assert_almost_eq(tall_frame.end.y, 0.96, 0.001, enemy_id)


func test_selected_class_controls_hero_placeholder_and_never_defaults_to_pierrot() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	session.player.character_class_code = "hunter"
	screen.configure(session, "wolf", "expedition")
	add_child_autofree(screen)
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_string_contains(screen.player_visual.role_label.text, "ŁOWCA")
	assert_false(screen.player_visual.role_label.text.contains("PIERROT"))

	session.player.character_class_code = "pierrot"
	screen.configure(session, "wolf", "expedition")
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.STATIC_TEXTURE)
	assert_eq(
		screen.player_visual.source_texture().resource_path,
		"res://assets/combat/heroes/pierrot.png",
	)
	assert_string_contains(screen.player_visual.role_label.text, "PIERROT")
	assert_string_contains(screen.class_resource_label.text, "ŻETONY")
	assert_null(CombatPresentationCatalogClass.hero_texture("hunter"))


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


func test_combat_hud_uses_three_non_overlapping_full_hd_command_zones() -> void:
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
	var player_hud: PanelContainer = lower.get_node("PlayerCommandHud")
	var action_dock: PanelContainer = lower.get_node("ActionsDock")
	var target_hud: PanelContainer = lower.get_node("TargetCommandHud")
	assert_lte(player_hud.get_global_rect().end.x, action_dock.get_global_rect().position.x)
	assert_lte(action_dock.get_global_rect().end.x, target_hud.get_global_rect().position.x)
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


func test_region_boss_without_approved_art_keeps_an_explicit_placeholder() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.current_location_id = "ashen_borderlands"
	var screen := COMBAT_SCENE.instantiate() as CombatScreenClass
	screen.configure(session, "azhar", "region_boss", "sunny", null, "WYZWANIE AZHARA")
	add_child_autofree(screen)
	assert_eq(screen.enemy_role_label.text, "BOSS")
	assert_eq(screen.enemy_visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_string_contains(screen.enemy_visual.name_label.text, "Azhar")
