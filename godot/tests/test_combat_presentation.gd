extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const COMBATANT_VISUAL_SCENE := preload(
	"res://ui/components/combatant_visual/combatant_visual.tscn"
)
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
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
	assert_false(visual.placeholder.visible)

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


func test_wolf_is_static_but_unintegrated_enemies_keep_their_placeholder() -> void:
	var wolf_texture := CombatPresentationCatalogClass.enemy_texture("wolf")
	assert_not_null(wolf_texture)
	assert_eq(wolf_texture.resource_path, "res://assets/combat/enemies/wolf.png")
	assert_null(CombatPresentationCatalogClass.enemy_texture("wild_dog"))


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
	assert_eq(screen.player_visual.mode(), CombatantVisualClass.Mode.PLACEHOLDER)
	assert_string_contains(screen.player_visual.role_label.text, "PIERROT")
