extends GutTest

const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const COMBATANT_VISUAL_SCENE := preload(
	"res://ui/components/combatant_visual/combatant_visual.tscn"
)
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const CombatantVisualClass := preload("res://ui/components/combatant_visual/combatant_visual.gd")
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
	assert_eq(player_visual.name_label.text, session.player.titled_display_name())
	assert_eq(enemy_visual.name_label.text, "Wilk")
	assert_string_contains(screen.enemy_name_label.text, "Wilk")
	assert_false(screen.log_panel.visible)
	screen.log_toggle_button.pressed.emit()
	assert_true(screen.log_panel.visible)
	assert_eq(screen.log_toggle_button.text, "Ukryj dziennik")
	host.free()
