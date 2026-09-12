extends HBoxContainer
const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const SlideDrawer := preload("res://ui/components/slide_drawer.gd")
const Style := preload("res://ui/presentation/interface_style.gd")
## Presentation-only deck sizing and navigation; no combat state or actions.

var drawer

@onready var _screen: Control = get_parent().get_parent()
@onready var _dock: PanelContainer = $ActionsDock
@onready var _scroll: ScrollContainer = %SkillCardsScroll
@onready var _cards: HBoxContainer = %SkillCards
@onready var _previous: Button = %ScrollPreviousButton
@onready var _next: Button = %ScrollNextButton


func _ready() -> void:
	_previous.pressed.connect(scroll_cards.bind(-1))
	_next.pressed.connect(scroll_cards.bind(1))
	_scroll.get_h_scroll_bar().changed.connect(_refresh_navigation)
	_scroll.get_h_scroll_bar().value_changed.connect(
		func(_value: float) -> void: _refresh_navigation()
	)
	_screen.resized.connect(update_layout)
	_screen.get_node("Page/ResultPanel").minimum_size_changed.connect(update_layout)
	drawer = SlideDrawer.new()
	add_child(drawer)
	drawer.configure(get_parent(), self, "bottom", "UMIEJĘTNOŚCI I AKCJE")
	_dock.add_theme_stylebox_override("panel", Style.panel())
	$PlayerCommandHud.add_theme_stylebox_override("panel", Style.panel())
	for side: String in ["Player", "Enemy"]:
		var hud: Control = _screen.get_node("Page/Arena/" + side + "Panel")
		hud.add_theme_stylebox_override("panel", Style.panel(0.94))
		hud.minimum_size_changed.connect(update_layout)
		for suffix: String in ["StatsLabel", "EffectLabel"]:
			var label: Label = _screen.get_node("%" + side + suffix)
			# 21 canvas pixels remain 14 physical pixels at the 720p capture scale.
			label.add_theme_font_size_override("font_size", 21)
			label.add_theme_color_override("font_color", Color(0.92, 0.95, 0.98))
	update_layout.call_deferred()


func update_layout() -> void:
	if not is_node_ready():
		return
	# Grow with the actual deck, never with all spare screen space.
	var available := maxf(480.0, _screen.size.x - 324.0)
	var desired := clampf(_cards.get_child_count() * 156.0 + 24.0, 480.0, 1120.0)
	_dock.custom_minimum_size.x = minf(desired, available)
	_layout_stage()
	if drawer != null:
		drawer.set_enabled(_screen._engine == null or _screen._engine.result == "ongoing")
		drawer.refresh_layout.call_deferred()
	_refresh_navigation.call_deferred()


func configure_motion(controller) -> void:
	drawer.reduced_motion = controller.reduced_motion
	controller.playback_started.connect(
		func() -> void:
			if not drawer.pinned:
				drawer.set_open(false)
	)
	_screen.motion_toggle_button.pressed.connect(
		func() -> void: drawer.reduced_motion = controller.reduced_motion
	)


func _layout_stage() -> void:
	var bounds := _screen.size
	var arena: Control = _screen.get_node("Page/Arena")
	_rect(_screen.get_node("Page/EncounterHeader"), Rect2(18, 8, bounds.x - 36, 38))
	_rect(arena, Rect2(0, 52, bounds.x, bounds.y - 52))
	_layout_turn_queue(arena, bounds.x)
	var hud_width := minf(480, bounds.x * 0.32)
	for side: String in ["Player", "Enemy"]:
		var hud: Control = arena.get_node(side + "Panel")
		_rect(hud, Rect2(22 if side == "Player" else bounds.x - hud_width - 22, 76, hud_width, 152))
	# Keep the dice readable between the HUDs, away from the hero-to-enemy VFX path.
	var fate_width := minf(360.0, bounds.x - 2.0 * hud_width - 76.0)
	_rect(arena.get_node("VfxStage"), Rect2((bounds.x - fate_width) * 0.5, 76, fate_width, 144))
	arena.get_node("Versus").hide()
	var actor_top := (
		maxf(
			arena.get_node("PlayerPanel").get_rect().end.y,
			arena.get_node("EnemyPanel").get_rect().end.y
		)
		+ 16
	)
	var actor_height := arena.size.y - actor_top - 90
	_rect(_screen.player_visual, Rect2(24, actor_top, bounds.x * 0.44 - 36, actor_height))
	_rect(
		_screen.enemy_visual,
		Rect2(bounds.x * 0.56 + 12, actor_top, bounds.x * 0.44 - 36, actor_height)
	)
	var result: Control = _screen.result_panel
	var result_width := minf(1180, bounds.x - 40)
	var result_height := maxf(82, result.get_combined_minimum_size().y)
	_rect(
		result,
		Rect2(
			(bounds.x - result_width) * 0.5,
			bounds.y - result_height - 12,
			result_width,
			result_height
		)
	)
	result.add_theme_stylebox_override("panel", Style.panel(0.88, Color(0.38, 0.64, 0.51, 0.65)))
	Style.quiet_button(_screen.log_toggle_button)
	Style.quiet_button(_screen.motion_toggle_button)


func _layout_turn_queue(arena: Control, available_width: float) -> void:
	var width := minf(1120.0, available_width - 44.0)
	var left := (available_width - width) * 0.5
	_rect(arena.get_node("TurnQueueBackdrop"), Rect2(left, 8, width, 60))
	_rect(arena.get_node("TurnOrder"), Rect2(left + 12, 12, width - 24, 52))
	for label: Label in [_screen.player_turn_label, _screen.enemy_turn_label]:
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_font_size_override("font_size", 20)
	_screen.player_turn_label.custom_minimum_size.x = 100
	_screen.enemy_turn_label.custom_minimum_size.x = 220
	_screen.enemy_turn_label.size_flags_stretch_ratio = 2.0
	_screen.enemy_turn_label.add_theme_color_override("font_color", Color(1.0, 0.72, 0.8))


func _rect(control: Control, rect: Rect2) -> void:
	control.set_anchors_preset(Control.PRESET_TOP_LEFT)
	control.position = rect.position
	control.size = rect.size


func scroll_cards(direction: int) -> void:
	var distance := maxi(156, int(_scroll.size.x) - 156)
	_scroll.scroll_horizontal += direction * distance
	_refresh_navigation()


func _refresh_navigation() -> void:
	if not is_node_ready():
		return
	var bar := _scroll.get_h_scroll_bar()
	var overflow := _scroll.visible and bar.max_value > bar.page + 1.0
	_previous.visible = overflow
	_next.visible = overflow
	_previous.disabled = bar.value <= bar.min_value
	_next.disabled = bar.value >= bar.max_value - bar.page - 1.0


static func class_resource_summary(player, engine, last_combo: String) -> String:
	match player.character_class_code:
		"warrior":
			var guard := "—"
			if engine.effects.player_guard_hits > 0:
				guard = (
					"%d%% ×%d"
					% [engine.effects.player_guard_percent, engine.effects.player_guard_hits]
				)
			return (
				"BLOK %.0f%%  •  GARDA %s\nODWET %s"
				% [
					engine.warrior_block_chance(),
					guard,
					"GOTOWY" if engine.warrior_retribution_ready else "—"
				]
			)
		"hunter":
			var sequence := "—"
			if not engine.hunter_sequence.is_empty():
				sequence = HunterComboCatalogClass.sequence_text(engine.hunter_sequence)
			return (
				"SEKWENCJA %s\nŁADUNKI %d/3  •  ECHA %d  •  DESZCZ %d\nFINISHER %s"
				% [
					sequence,
					engine.hunter_explosive_charges,
					engine.hunter_phantom_pending.size(),
					engine.hunter_rain_pending.size(),
					"—" if last_combo.is_empty() else last_combo,
				]
			)
		"mage":
			var elements: Array[String] = []
			for damage_type: String in engine.mage_element_sequence:
				elements.append(ElementalResistancesClass.display_name(damage_type))
			return (
				"ŻYWIOŁY %s\nSPLOT %d/3  •  WYDANA MANA %d"
				% [
					"—" if elements.is_empty() else " → ".join(elements),
					engine.mage_arcane_weave,
					engine.mage_mana_spent,
				]
			)
		"pierrot":
			return (
				"LOS %d  •  ŻETONY %d/%d"
				% [player.attributes.luck, engine.fate_tokens, engine.fate_token_cap()]
			)
	return "DROGA JESZCZE NIEWYBRANA"
