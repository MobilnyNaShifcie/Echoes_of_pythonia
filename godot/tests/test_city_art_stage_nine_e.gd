extends GutTest

const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const NewGameServiceClass := preload("res://core/game/new_game_service.gd")


func test_varenhold_plan_exposes_every_current_location_as_a_hotspot() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var city = CITY_HUB_SCENE.instantiate()
	city.configure(session)
	add_child_autofree(city)
	await get_tree().process_frame
	watch_signals(city)
	var requested_services: Array[String] = []
	city.service_requested.connect(
		func(service_id: String) -> void: requested_services.append(service_id)
	)

	var city_view := city.get_node("%CityView") as Control
	var base_map := city.get_node("%BaseMap") as TextureRect
	assert_eq(
		base_map.texture.resource_path,
		"res://assets/city/varenhold/backgrounds/varenhold_city_hub_day_v1.png",
	)
	var city_bounds := Rect2(Vector2.ZERO, city_view.size)
	assert_eq(base_map.get_rect(), city_bounds)
	assert_eq(base_map.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	var hotspots := [
		"GuildHotspot",
		"GateHotspot",
		"BlacksmithHotspot",
		"WorkshopHotspot",
		"MerchantHotspot",
		"InnHotspot",
	]
	for hotspot_name: String in hotspots:
		var hotspot := city.get_node("%%%s" % hotspot_name) as Button
		var hotspot_rect := hotspot.get_rect()
		assert_gte(hotspot_rect.position.x, city_bounds.position.x, hotspot_name)
		assert_gte(hotspot_rect.position.y, city_bounds.position.y, hotspot_name)
		assert_lte(hotspot_rect.end.x, city_bounds.end.x, hotspot_name)
		assert_lte(hotspot_rect.end.y, city_bounds.end.y, hotspot_name)
		assert_false(hotspot.tooltip_text.is_empty(), hotspot_name)

	city.get_node("%GuildHotspot").pressed.emit()
	city.get_node("%GateHotspot").pressed.emit()
	city.get_node("%BlacksmithHotspot").pressed.emit()
	city.get_node("%WorkshopHotspot").pressed.emit()
	city.get_node("%MerchantHotspot").pressed.emit()
	city.get_node("%InnHotspot").pressed.emit()
	assert_signal_emitted(city, "guild_requested")
	assert_signal_emitted(city, "world_map_requested")
	assert_eq(
		requested_services,
		["blacksmith", "workshop", "merchant", "inn"],
	)


func test_varenhold_hub_switches_between_approved_day_and_night_art() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var city = CITY_HUB_SCENE.instantiate()
	add_child_autofree(city)
	session.hour = 9
	city.configure(session)
	await get_tree().process_frame
	var base_map := city.get_node("%BaseMap") as TextureRect
	assert_eq(
		base_map.texture.resource_path,
		"res://assets/city/varenhold/backgrounds/varenhold_city_hub_day_v1.png",
	)
	session.hour = 22
	city.configure(session)
	assert_eq(
		base_map.texture.resource_path,
		"res://assets/city/varenhold/backgrounds/varenhold_city_hub_night_v1.png",
	)


func test_each_economy_service_uses_its_approved_npc_portrait() -> void:
	var expected_paths := {
		"merchant":
		{
			"npc": "res://assets/city/varenhold/npcs/oren_counter_v6.png",
			"background":
			"res://assets/city/varenhold/interiors/oren_stall_anime_wide_integrated_v2.png",
			"integrated": true,
			"anchor_x": 0.63,
			"ambient_zoom": 0.72,
			"ambient_offset": Vector2(0, -85),
			"ambient_width": 1200.0,
			"clip_bottom_ratio": 1.0,
			"clip_bottom_slope": 0.0,
			"counter_y": 0.71,
			"counter_slope": -0.04,
		},
		"blacksmith":
		{
			"npc": "res://assets/city/varenhold/npcs/garran_forging_v5.png",
			"background":
			"res://assets/city/varenhold/interiors/garran_forge_anime_integrated_v4.png",
			"integrated": true,
			"anchor_x": 0.5,
			"ambient_width": 1000.0,
			"clip_bottom_ratio": 1.0,
			"clip_bottom_slope": 0.0,
		},
		"workshop":
		{
			"npc": "res://assets/city/varenhold/npcs/mirela_counter_v3.png",
			"background":
			"res://assets/city/varenhold/interiors/mirela_workshop_anime_integrated_v5.png",
			"integrated": true,
			"anchor_x": 0.48,
			"ambient_zoom": 0.51,
			"ambient_offset": Vector2(10, 0),
			"clip_bottom_ratio": 1.0,
			"clip_bottom_slope": 0.0,
			"counter_y": 0.66,
			"counter_slope": -0.08,
		},
		"inn":
		{
			"npc": "res://assets/city/varenhold/npcs/runa_innkeeper_v7.png",
			"background":
			"res://assets/city/varenhold/interiors/inn_tavern_anime_wide_integrated_v5.png",
			"integrated": true,
			"anchor_x": 0.28,
			"ambient_zoom": 0.7968,
			"ambient_offset": Vector2(144, -46),
			"clip_bottom_ratio": 1.0,
			"clip_bottom_slope": 0.0,
			"counter_y": 0.50,
			"counter_slope": -0.12,
			"counter_shade": 1.0,
		},
	}
	for service_id: String in expected_paths:
		var session = NewGameServiceClass.new().create_session("Aria", 1)
		var screen = CITY_ECONOMY_SCENE.instantiate()
		add_child_autofree(screen)
		screen.configure(session, service_id)

		assert_not_null(screen.npc_visual.character_texture())
		assert_eq(
			screen.npc_visual.character_texture().resource_path,
			expected_paths[service_id].npc,
		)
		assert_eq(
			_source_texture_path(screen.location_background.texture),
			expected_paths[service_id].background,
		)
		assert_eq(
			_source_texture_path(screen.counter_foreground.texture),
			expected_paths[service_id].background,
		)
		assert_gt(screen.counter_foreground.get_index(), screen.columns.get_index(), service_id)
		var integrated := bool(expected_paths[service_id].get("integrated", false))
		assert_eq(
			screen.counter_foreground.visible,
			service_id != "blacksmith" and not integrated,
			service_id,
		)
		assert_eq(screen.location_shade.visible, not integrated, service_id)
		assert_false(screen.npc_integrated_highlight.visible, service_id)
		assert_almost_eq(
			screen.npc_visual.self_modulate.a,
			0.0 if integrated else 1.0,
			0.001,
			service_id,
		)
		if expected_paths[service_id].has("counter_y"):
			var counter_material := screen.counter_foreground.material as ShaderMaterial
			assert_not_null(counter_material, service_id)
			assert_almost_eq(
				float(counter_material.get_shader_parameter("counter_y")),
				float(expected_paths[service_id].counter_y),
				0.001,
				service_id,
			)
			assert_almost_eq(
				float(counter_material.get_shader_parameter("counter_slope")),
				float(expected_paths[service_id].counter_slope),
				0.001,
				service_id,
			)
			assert_almost_eq(
				float(counter_material.get_shader_parameter("background_shade")),
				float(expected_paths[service_id].get("counter_shade", 0.8)),
				0.001,
				service_id,
			)
		assert_almost_eq(
			screen.npc_visual.character_anchor_x,
			float(expected_paths[service_id].anchor_x),
			0.001,
		)
		if expected_paths[service_id].has("ambient_zoom"):
			assert_almost_eq(
				screen.npc_visual.character_zoom,
				float(expected_paths[service_id].ambient_zoom),
				0.001,
				service_id,
			)
			assert_eq(
				screen.npc_visual.character_offset,
				expected_paths[service_id].ambient_offset,
				service_id,
			)
		if expected_paths[service_id].has("ambient_width"):
			assert_almost_eq(
				screen.npc_panel.custom_minimum_size.x,
				float(expected_paths[service_id].ambient_width),
				0.001,
				service_id,
			)
		assert_almost_eq(
			screen.npc_visual.character_clip_bottom_ratio,
			float(expected_paths[service_id].clip_bottom_ratio),
			0.001,
		)
		assert_almost_eq(
			screen.npc_visual.character_clip_bottom_slope,
			float(expected_paths[service_id].clip_bottom_slope),
			0.001,
		)
		assert_true(screen.npc_hit_area.tooltip_text.is_empty())
		assert_eq(screen.location_background.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
		assert_false(screen.service_grid.is_visible_in_tree())
		assert_false(screen.transaction_drop_zone.is_visible_in_tree())
		assert_true(screen.columns is Control)
		assert_eq(screen.npc_panel.size_flags_horizontal, Control.SIZE_FILL)
		await get_tree().process_frame
		if integrated:
			assert_false(screen.npc_hit_area.use_alpha_mask)
			assert_true(
				screen.npc_hit_area._has_point(screen.npc_hit_area.size * 0.5),
				"Zintegrowany NPC musi przyjmowac interakcje w swojej stalej strefie.",
			)
		var ambient_visual_size: Vector2 = screen.npc_visual.size
		var ambient_visual_position: Vector2 = screen.npc_visual.global_position
		var ambient_character_rect: Rect2 = screen.npc_visual.character_visible_rect()
		var ambient_anchor: float = screen.npc_visual.character_anchor_x
		if integrated:
			assert_eq(
				screen.npc_integrated_highlight.texture,
				screen.location_background.texture,
				service_id,
			)
			screen.npc_hit_area.mouse_entered.emit()
			assert_true(screen.npc_integrated_highlight.visible, service_id)
			screen.npc_hit_area.mouse_exited.emit()
			assert_false(screen.npc_integrated_highlight.visible, service_id)
		if service_id == "merchant":
			assert_true(screen.location_background.is_visible_in_tree())
			assert_false(screen.npc_panel.visible, "Integrated Oren must not be duplicated.")
		screen.npc_hit_area.pressed.emit()
		screen.open_service_button.pressed.emit()
		await get_tree().process_frame
		assert_false(screen.counter_foreground.visible, service_id)
		assert_eq(screen.npc_visual.size, ambient_visual_size, service_id)
		assert_eq(screen.npc_visual.global_position, ambient_visual_position, service_id)
		assert_eq(screen.npc_visual.character_visible_rect(), ambient_character_rect, service_id)
		assert_almost_eq(screen.npc_visual.character_anchor_x, ambient_anchor, 0.001)
		if service_id == "merchant":
			assert_true(screen.merchant_trade_overlay.is_visible_in_tree())
			assert_true(screen.merchant_stock_grid.is_visible_in_tree())
			assert_true(screen.merchant_player_grid.is_visible_in_tree())
			assert_false(screen.service_grid.is_visible_in_tree())
			assert_false(screen.transaction_drop_zone.is_visible_in_tree())
		elif service_id == "inn":
			assert_false(screen.service_grid.is_visible_in_tree())
			assert_false(screen.transaction_drop_zone.is_visible_in_tree())
			assert_true(screen.action_button.is_visible_in_tree())
		else:
			assert_false(screen.merchant_trade_overlay.is_visible_in_tree())
			assert_true(screen.service_grid.is_visible_in_tree())
			assert_true(screen.transaction_drop_zone.is_visible_in_tree())


func _source_texture_path(texture: Texture2D) -> String:
	var atlas_texture := texture as AtlasTexture
	if atlas_texture != null:
		return atlas_texture.atlas.resource_path
	return texture.resource_path


func test_guild_presentation_starts_as_an_interactive_full_hall() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	var guild = GUILD_SCENE.instantiate()
	guild.configure(session)
	add_child_autofree(guild)
	await get_tree().process_frame

	var interior := guild.get_node("%Interior") as TextureRect
	var highlight := guild.get_node("%GuildmasterHighlight") as TextureRect
	assert_eq(
		interior.texture.resource_path,
		"res://assets/city/varenhold/interiors/guild_hall_anime_integrated_v3.png",
	)
	assert_null(
		guild.get_node_or_null("%GuildmasterVisual"), "No duplicate cutout over the artwork."
	)
	assert_eq(highlight.texture, interior.texture)
	assert_eq(highlight.get_rect(), interior.get_rect())
	assert_eq(interior.stretch_mode, TextureRect.STRETCH_KEEP_ASPECT_COVERED)
	assert_gt(guild.get_node("%GuildHallPresentation").size.y, 500.0)
	assert_eq(
		guild.get_node("%GuildHallPresentation").size_flags_vertical,
		Control.SIZE_EXPAND_FILL,
	)
	assert_false(guild.get_node("%HallIdentity").visible)
	assert_false(highlight.visible)
	assert_false(guild.get_node("%GuildActionPanel").visible)
	assert_false(guild.get_node("%BoardTabs").visible)
	assert_false(guild.get_node("%Body").visible)
	guild.guildmaster_hit_area.mouse_entered.emit()
	assert_true(highlight.visible)
	guild.guildmaster_hit_area.mouse_exited.emit()
	assert_false(highlight.visible)

	guild.get_node("%GuildmasterHitArea").pressed.emit()
	assert_true(guild.get_node("%GuildActionPanel").visible)
	assert_false(guild.get_node("%HallIdentity").visible)
	assert_true(guild.get_node("%GuildmasterHitArea").tooltip_text.is_empty())

	guild.get_node("%OpenBoardButton").pressed.emit()
	assert_false(guild.get_node("%GuildActionPanel").visible)
	assert_true(guild.get_node("%BoardTabs").visible)
	assert_true(guild.get_node("%Body").visible)
	assert_true(guild.guildmaster_hit_area.disabled)
	guild.guildmaster_hit_area.mouse_entered.emit()
	assert_false(highlight.visible, "No hover behind the open quest board.")
	await get_tree().process_frame
	assert_eq(guild.hall_presentation.size, guild.size)


func test_inn_informant_uses_the_matching_room_and_keeps_runa() -> void:
	var session = NewGameServiceClass.new().create_session("Aria", 1)
	session.day = 7
	session.guild_reputation = 700
	session.guild_milestones.append("dungeon:sunken_order_crypt")
	session.black_market.informant_failed_checks = 4
	var inn = CITY_ECONOMY_SCENE.instantiate()
	add_child_autofree(inn)
	var rng := RandomNumberGenerator.new()
	rng.seed = 1
	inn.configure(session, "inn", rng)
	await get_tree().process_frame

	var interior := inn.get_node("%LocationBackground") as TextureRect
	var runa := inn.get_node("%NpcVisual") as CharacterPaperdoll
	var informant_hit_area := inn.get_node("%InformantHitArea") as Button
	var informant_glow := inn.get_node("%InformantGlow") as TextureRect
	assert_eq(
		interior.texture.resource_path,
		"res://assets/city/varenhold/interiors/inn_tavern_anime_wide_informant_integrated_v5.png",
	)
	assert_true(runa.visible)
	assert_eq(
		runa.character_texture().resource_path,
		"res://assets/city/varenhold/npcs/runa_innkeeper_v7.png",
	)
	assert_true(informant_hit_area.visible)
	assert_almost_eq(informant_hit_area.anchor_left, 0.69, 0.001)
	assert_almost_eq(informant_hit_area.anchor_top, 0.48, 0.001)
	assert_almost_eq(informant_hit_area.anchor_right, 0.82, 0.001)
	assert_almost_eq(informant_hit_area.anchor_bottom, 0.88, 0.001)
	assert_false(informant_glow.visible)
	var informant_material := informant_glow.material as ShaderMaterial
	assert_eq(
		informant_material.get_shader_parameter("glow_center"),
		Vector2(0.755, 0.67),
	)
	assert_eq(
		informant_material.get_shader_parameter("glow_radius"),
		Vector2(0.085, 0.20),
	)
	informant_hit_area.mouse_entered.emit()
	assert_true(informant_glow.visible)
	informant_hit_area.mouse_exited.emit()
	assert_false(informant_glow.visible)
