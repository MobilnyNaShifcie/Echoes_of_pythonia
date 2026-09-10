class_name CityHubScreen
extends Control

signal world_map_requested
signal guild_requested
signal hero_requested
signal adventure_log_requested
signal achievements_requested
signal classes_requested
signal service_requested(service_id: String)
signal main_menu_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const SlideDrawer := preload("res://ui/components/slide_drawer.gd")
const CITY_DAY_TEXTURE := preload(
	"res://assets/city/varenhold/backgrounds/varenhold_city_hub_day_v1.png"
)
const CITY_NIGHT_TEXTURE := preload(
	"res://assets/city/varenhold/backgrounds/varenhold_city_hub_night_v1.png"
)
const MAP_ICONS := {
	"guild": preload("res://assets/ui/city_icons/guild.svg"),
	"gate": preload("res://assets/ui/city_icons/gate.svg"),
	"blacksmith": preload("res://assets/ui/city_icons/blacksmith.svg"),
	"merchant": preload("res://assets/ui/city_icons/merchant.svg"),
	"inn": preload("res://assets/ui/city_icons/inn.svg"),
	"workshop": preload("res://assets/ui/city_icons/workshop.svg"),
}
const MAP_ZOOM := 1.0
const MAP_ZOOM_FOCUS := Vector2(0.5, 0.49)
const MAP_HOTSPOTS := {
	"guild":
	{
		"node": "GuildHotspot",
		"label": "Gildia",
		"center": Vector2(0.350, 0.460),
		"extent": Vector2(0.075, 0.105),
	},
	"gate":
	{
		"node": "GateHotspot",
		"label": "Brama Zachodnia",
		"center": Vector2(0.235, 0.710),
		"extent": Vector2(0.070, 0.130),
	},
	"blacksmith":
	{
		"node": "BlacksmithHotspot",
		"label": "Kuźnia",
		"center": Vector2(0.800, 0.500),
		"extent": Vector2(0.080, 0.105),
	},
	"merchant":
	{
		"node": "MerchantHotspot",
		"label": "Kram",
		"center": Vector2(0.370, 0.770),
		"extent": Vector2(0.080, 0.090),
	},
	"inn":
	{
		"node": "InnHotspot",
		"label": "Karczma",
		"center": Vector2(0.590, 0.785),
		"extent": Vector2(0.080, 0.105),
	},
	"workshop":
	{
		"node": "WorkshopHotspot",
		"label": "Warsztat",
		"center": Vector2(0.790, 0.735),
		"extent": Vector2(0.090, 0.115),
	},
}
const NAV_BUTTON_NAMES := [
	"GateButton",
	"PreparationButton",
	"GuildButton",
	"BlacksmithButton",
	"WorkshopButton",
	"MerchantButton",
	"InnButton",
	"HeroButton",
	"AdventureLogButton",
	"AchievementsButton",
	"ClassButton",
	"BlackMarketButton",
	"MainMenuButton",
]

var navigation_drawer: Node

var _session: GameSessionClass
var _active_marker: Control
var _active_glow: Control
var _marker_tween: Tween

@onready var time_label: Label = %TimeLabel
@onready var activity_label: Label = %ActivityLabel
@onready var class_button: Button = %ClassButton
@onready var black_market_button: Button = %BlackMarketButton
@onready var map_location_label: Label = %MapLocationLabel
@onready var base_map: TextureRect = %BaseMap
@onready var city_view: Control = %CityView


func _ready() -> void:
	_configure_navigation_buttons()
	_build_map_hotspots()
	if base_map.material != null:
		base_map.material = base_map.material.duplicate()
	city_view.resized.connect(_queue_map_hotspot_layout)
	%GateButton.pressed.connect(world_map_requested.emit)
	%BlacksmithButton.pressed.connect(service_requested.emit.bind("blacksmith"))
	%WorkshopButton.pressed.connect(service_requested.emit.bind("workshop"))
	%MerchantButton.pressed.connect(service_requested.emit.bind("merchant"))
	%InnButton.pressed.connect(service_requested.emit.bind("inn"))
	%GuildButton.pressed.connect(guild_requested.emit)
	%GuildHotspot.pressed.connect(guild_requested.emit)
	%GateHotspot.pressed.connect(world_map_requested.emit)
	%BlacksmithHotspot.pressed.connect(service_requested.emit.bind("blacksmith"))
	%WorkshopHotspot.pressed.connect(service_requested.emit.bind("workshop"))
	%MerchantHotspot.pressed.connect(service_requested.emit.bind("merchant"))
	%InnHotspot.pressed.connect(service_requested.emit.bind("inn"))
	_connect_map_hint(%GuildHotspot, "Gildia Poszukiwaczy • zadania, drużyna i Szczeliny", "guild")
	_connect_map_hint(%GateHotspot, "Brama Zachodnia • wyprawy poza Varenhold", "gate")
	_connect_map_hint(%BlacksmithHotspot, "Kuźnia Garrana • ulepszanie wyposażenia", "blacksmith")
	_connect_map_hint(%WorkshopHotspot, "Warsztat Mireli • alchemia i receptury", "workshop")
	_connect_map_hint(%MerchantHotspot, "Kram Orena • handel i skup łupów", "merchant")
	_connect_map_hint(%InnHotspot, "Karczma • nocleg, magazyn i udźwig", "inn")
	%HeroButton.pressed.connect(hero_requested.emit)
	%AdventureLogButton.pressed.connect(adventure_log_requested.emit)
	%AchievementsButton.pressed.connect(achievements_requested.emit)
	%PreparationButton.pressed.connect(service_requested.emit.bind("preparation"))
	class_button.pressed.connect(classes_requested.emit)
	black_market_button.pressed.connect(service_requested.emit.bind("black_market"))
	%MainMenuButton.pressed.connect(main_menu_requested.emit)
	_create_marker_labels()
	_render()
	_queue_map_hotspot_layout()
	navigation_drawer = SlideDrawer.new()
	add_child(navigation_drawer)
	navigation_drawer.configure($Layout, $Layout/MenuPanel, "left", "MIASTO")
	navigation_drawer.openness_changed.connect(
		func(opened: bool) -> void: $Layout/City/TopInfo.offset_left = 366 if opened else 62
	)
	$Layout/City/QuickActionsDock.hide()
	$Layout/City/QuickActionsDock.queue_free()
	$Layout/City/LegacyQuickActions.queue_free()


func _configure_navigation_buttons() -> void:
	for node_name: String in NAV_BUTTON_NAMES:
		var button := get_node("%%%s" % node_name) as Button
		button.custom_minimum_size = Vector2(0.0, 48.0)
		# Grid columns only use the spare width when a child requests expansion.
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.icon_alignment = HORIZONTAL_ALIGNMENT_LEFT
		button.vertical_icon_alignment = VERTICAL_ALIGNMENT_CENTER
		button.expand_icon = false


func _build_map_hotspots() -> void:
	for location_id: String in MAP_HOTSPOTS:
		var hotspot_data: Dictionary = MAP_HOTSPOTS[location_id]
		var hotspot := Button.new()
		hotspot.name = str(hotspot_data.node)
		hotspot.unique_name_in_owner = true
		hotspot.z_index = 6
		hotspot.mouse_filter = Control.MOUSE_FILTER_STOP
		hotspot.focus_mode = Control.FOCUS_NONE
		hotspot.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		var center: Vector2 = hotspot_data.center
		var extent: Vector2 = hotspot_data.extent
		hotspot.anchor_left = center.x - extent.x
		hotspot.anchor_top = center.y - extent.y
		hotspot.anchor_right = center.x + extent.x
		hotspot.anchor_bottom = center.y + extent.y
		var empty_style := StyleBoxEmpty.new()
		for state: String in ["normal", "hover", "pressed", "focus"]:
			hotspot.add_theme_stylebox_override(state, empty_style)

		var marker := Panel.new()
		marker.name = "Marker"
		marker.set_anchors_preset(Control.PRESET_CENTER)
		marker.position = Vector2(-23.0, -23.0)
		marker.size = Vector2(46.0, 46.0)
		marker.pivot_offset = Vector2(23.0, 23.0)
		marker.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var marker_style := StyleBoxFlat.new()
		marker_style.bg_color = Color(0.008, 0.016, 0.026, 0.96)
		marker_style.border_color = Color(0.91, 0.66, 0.17, 1.0)
		marker_style.set_border_width_all(2)
		marker_style.set_corner_radius_all(24)
		marker_style.shadow_color = Color(0, 0, 0, 0.82)
		marker_style.shadow_size = 7
		marker.add_theme_stylebox_override("panel", marker_style)

		var glow := Panel.new()
		glow.name = "Glow"
		glow.show_behind_parent = true
		glow.position = Vector2(-8.0, -8.0)
		glow.size = Vector2(62.0, 62.0)
		glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
		glow.modulate = Color(1, 1, 1, 0)
		var glow_style := StyleBoxFlat.new()
		glow_style.bg_color = Color(1, 0.68, 0.12, 0.15)
		glow_style.set_corner_radius_all(32)
		glow_style.shadow_color = Color(1, 0.62, 0.08, 0.62)
		glow_style.shadow_size = 14
		glow.add_theme_stylebox_override("panel", glow_style)
		marker.add_child(glow)

		var icon := TextureRect.new()
		icon.name = "Icon"
		icon.set_anchors_preset(Control.PRESET_CENTER)
		icon.position = Vector2(-14.0, -14.0)
		icon.size = Vector2(28.0, 28.0)
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		icon.texture = MAP_ICONS[location_id]
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		marker.add_child(icon)

		hotspot.add_child(marker)
		city_view.add_child(hotspot)
		hotspot.owner = self


func _create_marker_labels() -> void:
	for location_id: String in MAP_HOTSPOTS:
		var hotspot_data: Dictionary = MAP_HOTSPOTS[location_id]
		var hotspot := get_node("%%%s" % str(hotspot_data.node)) as Button
		var marker := hotspot.get_node("Marker") as Control
		if marker.has_node("NamePlate"):
			continue
		var name_plate := PanelContainer.new()
		name_plate.name = "NamePlate"
		name_plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		name_plate.position = Vector2(38.0, 6.0)
		var plate_style := StyleBoxFlat.new()
		plate_style.bg_color = Color(0.008, 0.014, 0.022, 0.94)
		plate_style.border_color = Color(0.76, 0.55, 0.18, 0.92)
		plate_style.set_border_width_all(1)
		plate_style.set_corner_radius_all(3)
		plate_style.content_margin_left = 10.0
		plate_style.content_margin_right = 10.0
		plate_style.content_margin_top = 5.0
		plate_style.content_margin_bottom = 5.0
		name_plate.add_theme_stylebox_override("panel", plate_style)
		var label := Label.new()
		label.text = str(hotspot_data.label)
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		label.add_theme_color_override("font_color", Color(0.94, 0.94, 0.95, 1.0))
		label.add_theme_font_size_override("font_size", 14)
		name_plate.add_child(label)
		marker.add_child(name_plate)


func _connect_map_hint(hotspot: Button, copy: String, location_id: String) -> void:
	hotspot.tooltip_text = copy
	hotspot.mouse_entered.connect(_show_map_location.bind(copy, location_id))
	hotspot.mouse_exited.connect(_reset_map_location)


func _show_map_location(copy: String, location_id: String) -> void:
	map_location_label.text = copy
	_activate_marker(location_id)


func _activate_marker(location_id: String) -> void:
	_deactivate_marker()
	var hotspot_data: Dictionary = MAP_HOTSPOTS[location_id]
	var hotspot := get_node("%%%s" % str(hotspot_data.node)) as Button
	_active_marker = hotspot.get_node("Marker") as Control
	_active_glow = _active_marker.get_node("Glow") as Control
	_active_marker.scale = Vector2(1.06, 1.06)
	_active_marker.modulate = Color(1.08, 1.04, 0.9, 1.0)
	_active_glow.modulate = Color(1, 1, 1, 0.35)
	_marker_tween = create_tween()
	_marker_tween.set_loops()
	_marker_tween.set_trans(Tween.TRANS_SINE)
	_marker_tween.set_ease(Tween.EASE_IN_OUT)
	_marker_tween.tween_property(_active_marker, "scale", Vector2(1.16, 1.16), 0.48)
	_marker_tween.parallel().tween_property(
		_active_marker, "modulate", Color(1.2, 1.12, 0.82, 1.0), 0.48
	)
	_marker_tween.parallel().tween_property(_active_glow, "modulate:a", 1.0, 0.48)
	_marker_tween.tween_property(_active_marker, "scale", Vector2(1.06, 1.06), 0.48)
	_marker_tween.parallel().tween_property(
		_active_marker, "modulate", Color(1.08, 1.04, 0.9, 1.0), 0.48
	)
	_marker_tween.parallel().tween_property(_active_glow, "modulate:a", 0.35, 0.48)


func _deactivate_marker() -> void:
	if _marker_tween != null and _marker_tween.is_valid():
		_marker_tween.kill()
	_marker_tween = null
	if _active_marker != null:
		_active_marker.scale = Vector2.ONE
		_active_marker.modulate = Color.WHITE
	if _active_glow != null:
		_active_glow.modulate = Color(1, 1, 1, 0)
	_active_marker = null
	_active_glow = null


func _queue_map_hotspot_layout() -> void:
	_update_map_hotspot_layout.call_deferred()


func _update_map_hotspot_layout() -> void:
	if base_map.texture == null or city_view.size.x <= 0.0 or city_view.size.y <= 0.0:
		return
	var texture_size := base_map.texture.get_size()
	if texture_size.x <= 0.0 or texture_size.y <= 0.0:
		return
	var cover_scale := maxf(city_view.size.x / texture_size.x, city_view.size.y / texture_size.y)
	var draw_size := texture_size * cover_scale
	var draw_origin := (city_view.size - draw_size) * 0.5
	var zoomed_draw_size := draw_size * MAP_ZOOM
	var zoomed_draw_origin := draw_origin + MAP_ZOOM_FOCUS * draw_size * (1.0 - MAP_ZOOM)
	var view_bounds := Rect2(Vector2.ZERO, city_view.size)
	for location_id: String in MAP_HOTSPOTS:
		var hotspot_data: Dictionary = MAP_HOTSPOTS[location_id]
		var center: Vector2 = hotspot_data.center
		var extent: Vector2 = hotspot_data.extent
		var hotspot_rect := (
			Rect2(
				zoomed_draw_origin + (center - extent) * zoomed_draw_size,
				extent * 2.0 * zoomed_draw_size,
			)
			. intersection(view_bounds)
		)
		var hotspot := get_node("%%%s" % str(hotspot_data.node)) as Button
		hotspot.anchor_left = 0.0
		hotspot.anchor_top = 0.0
		hotspot.anchor_right = 0.0
		hotspot.anchor_bottom = 0.0
		hotspot.offset_left = hotspot_rect.position.x
		hotspot.offset_top = hotspot_rect.position.y
		hotspot.offset_right = hotspot_rect.end.x
		hotspot.offset_bottom = hotspot_rect.end.y


func _reset_map_location() -> void:
	map_location_label.text = "Wybierz budynek bezpośrednio na planie miasta."
	_deactivate_marker()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func _render() -> void:
	if _session == null:
		return
	var player := _session.player
	base_map.texture = CITY_DAY_TEXTURE if _session.period_code() == "day" else CITY_NIGHT_TEXTURE
	time_label.text = "Dzień %d  •  %02d:00" % [_session.day, _session.hour]
	activity_label.text = (
		_session.last_activity
		if not _session.last_activity.is_empty()
		else "Wybierz miejsce w mieście albo wyrusz przez Bramę Zachodnią."
	)
	if player.character_class_code == player.CLASS_NONE:
		class_button.text = ("Wybierz Drogę" if player.can_choose_class else "Droga bohatera")
	else:
		class_button.text = "Droga: %s" % player.character_class_name
	black_market_button.disabled = not _session.black_market.unlocked
	black_market_button.text = "Czarny Rynek"
	black_market_button.tooltip_text = (
		"Wejdź na Czarny Rynek."
		if _session.black_market.unlocked
		else "Czarny Rynek jest jeszcze niedostępny. Wypatruj informatora w karczmie."
	)
	var has_active_party := not _session.party.active_companions(_session.day).is_empty()
	%PreparationButton.visible = has_active_party
	%PreparationButton.disabled = not has_active_party
	%PreparationHint.visible = false
