class_name CombatPresentationController
extends Node

signal playback_started
signal playback_finished
signal skill_impact(event: Dictionary)

const COMBAT_DIE_SCENE := preload("res://ui/components/combat_die/combat_die.tscn")
const FateThrustEffect := preload("res://ui/presentation/fate_thrust_effect.gd")

var reduced_motion := false
var animation_duration_scale := 1.0
var last_feedback_texts: Array[String] = []
var _busy := false
var _player_visual: Control
var _enemy_visual: Control
var _feedback_layer: Control
var _dice_row: HBoxContainer
var _fate_outcome_label: Label
var _player_hp_bar: ProgressBar
var _player_mana_bar: ProgressBar
var _enemy_hp_bar: ProgressBar
var _turn_state_label: Label
var _player_turn_icon: Label
var _enemy_turn_icon: Label
var _motion_toggle_button: Button
var _player_stats_label: Label
var _enemy_stats_label: Label
var _active_skill_effect: Control


func configure(screen: Control) -> void:
	_player_visual = screen.get_node("%PlayerVisual")
	_enemy_visual = screen.get_node("%EnemyVisual")
	_feedback_layer = screen.get_node("%FeedbackLayer")
	_dice_row = screen.get_node("%DiceRow")
	_fate_outcome_label = screen.get_node("%FateOutcomeLabel")
	_player_hp_bar = screen.get_node("%PlayerHpBar")
	_player_mana_bar = screen.get_node("%PlayerManaBar")
	_enemy_hp_bar = screen.get_node("%EnemyHpBar")
	_turn_state_label = screen.get_node("%TurnStateLabel")
	_player_turn_icon = screen.get_node("%PlayerTurnIcon")
	_enemy_turn_icon = screen.get_node("%EnemyTurnIcon")
	_motion_toggle_button = screen.get_node("%MotionToggleButton")
	_player_stats_label = screen.get_node("%PlayerStatsLabel")
	_enemy_stats_label = screen.get_node("%EnemyStatsLabel")
	for bar: ProgressBar in [_player_hp_bar, _player_mana_bar, _enemy_hp_bar]:
		bar.value_changed.connect(func(_value: float) -> void: _sync_resource_labels())
	_motion_toggle_button.pressed.connect(_toggle_reduced_motion)
	set_reduced_motion(DisplayServer.get_name() == "headless")


func set_reduced_motion(enabled: bool) -> void:
	reduced_motion = enabled
	_motion_toggle_button.text = "Animacje: ograniczone" if enabled else "Animacje: pełne"


func resource_snapshot(player, enemy) -> Dictionary:
	return {
		"player_hp": player.stats.current_hp,
		"player_mana": player.stats.current_mana,
		"enemy_hp": enemy.current_hp,
	}


func _toggle_reduced_motion() -> void:
	set_reduced_motion(not reduced_motion)


func is_busy() -> bool:
	return _busy


func present(
	events: Array[Dictionary], before: Dictionary, after: Dictionary, round_number: int
) -> void:
	if _busy:
		return
	_busy = true
	last_feedback_texts.clear()
	playback_started.emit()
	_apply_resources(before)
	if reduced_motion:
		_present_instant(events)
		_apply_resources(after)
		_set_turn_actor("player", round_number)
		_finish_playback()
		return
	var displayed := before.duplicate(true)
	for event: Dictionary in events:
		await _play_event(event, displayed, round_number)
	_apply_resources(after)
	_set_turn_actor("player", round_number)
	_finish_playback()


func render_dice(dice: Array[int], outcome: String) -> void:
	_clear_dice()
	for value: int in dice:
		var die = COMBAT_DIE_SCENE.instantiate()
		_dice_row.add_child(die)
		die.set_value(value)
	_fate_outcome_label.text = "" if dice.is_empty() else outcome


func reveal_result(panel: Control) -> void:
	panel.modulate.a = 1.0
	panel.scale = Vector2.ONE
	if reduced_motion:
		return
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.985, 0.985)
	panel.pivot_offset = panel.size * 0.5
	var tween := panel.create_tween().set_parallel()
	tween.tween_property(panel, "modulate:a", 1.0, _duration(0.2))
	(
		tween
		. tween_property(panel, "scale", Vector2.ONE, _duration(0.2))
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)


func _present_instant(events: Array[Dictionary]) -> void:
	for event: Dictionary in events:
		match str(event.get("kind", "")):
			"fate_roll":
				var values: Array[int] = []
				values.assign(event.get("dice", []))
				render_dice(values, str(event.get("outcome", "")))
			"damage":
				_record_feedback(_damage_text(event))
			"restore":
				_record_feedback(_restore_text(event))
			"feedback":
				_record_feedback(str(event.get("text", "")))


func _play_event(event: Dictionary, displayed: Dictionary, round_number: int) -> void:
	match str(event.get("kind", "")):
		"turn":
			_set_turn_actor(str(event.get("actor", "player")), round_number)
			await get_tree().create_timer(_duration(0.08)).timeout
		"fate_roll":
			var cost := int(event.get("mana_cost", 0))
			if cost > 0:
				displayed.player_mana = maxf(0.0, float(displayed.get("player_mana", 0)) - cost)
				_apply_resources(displayed)
			await _play_dice(event)
		"damage":
			await _play_damage(event, displayed)
		"restore":
			await _play_restore(event, displayed)
		"feedback":
			await _play_feedback(
				str(event.get("target", "enemy")),
				str(event.get("text", "")),
				str(event.get("tone", "neutral")),
			)


func _play_dice(event: Dictionary) -> void:
	_turn_state_label.text = "RZUT LOSU"
	var final_values: Array[int] = []
	final_values.assign(event.get("dice", []))
	_clear_dice()
	var dice: Array[Control] = []
	for final_value: int in final_values:
		var die = COMBAT_DIE_SCENE.instantiate()
		_dice_row.add_child(die)
		die.set_value(final_value, false)
		dice.append(die)
	_fate_outcome_label.text = "KOŚCI W RUCHU…"
	for step in 5:
		for index in dice.size():
			var preview := ((final_values[index] + step * 2 + index) % 6) + 1
			dice[index].set_value(preview, false)
			dice[index].rotation = deg_to_rad(-5.0 if (step + index) % 2 == 0 else 5.0)
		await get_tree().create_timer(_duration(0.055)).timeout
	for index in dice.size():
		dice[index].rotation = 0.0
		dice[index].set_value(final_values[index], true)
	_fate_outcome_label.text = str(event.get("outcome", ""))
	await get_tree().create_timer(_duration(0.18)).timeout


func _play_damage(event: Dictionary, displayed: Dictionary) -> void:
	var actor := str(event.get("actor", "player"))
	if str(event.get("vfx", "")) == "fate_thrust":
		await _play_fate_thrust(event, displayed)
		return
	await _lunge(_visual_for(actor), 1.0 if actor == "player" else -1.0)
	await _apply_damage_impact(event, displayed)


func _play_fate_thrust(event: Dictionary, displayed: Dictionary) -> void:
	_turn_state_label.text = "PCHNIĘCIE LOSU"
	var effect := FateThrustEffect.new()
	_active_skill_effect = effect
	_feedback_layer.add_child(effect)
	_feedback_layer.move_child(effect, 0)
	effect.impact.connect(
		func() -> void:
			_apply_damage_impact(event, displayed)
			skill_impact.emit(event)
	)
	effect.start(_player_visual, _enemy_visual, event, animation_duration_scale)
	await effect.finished
	_active_skill_effect = null
	effect.queue_free()


func _apply_damage_impact(event: Dictionary, displayed: Dictionary) -> void:
	var target := str(event.get("target", "enemy"))
	var text := _damage_text(event)
	_record_feedback(text)
	var tone := "critical" if bool(event.get("critical", false)) else "damage"
	_show_floating_text(_visual_for(target), text, tone)
	if int(event.get("amount", 0)) > 0:
		_flash(_visual_for(target), Color(1.0, 0.42, 0.48))
	if target == "enemy":
		var enemy_target := maxf(
			0.0, float(displayed.get("enemy_hp", _enemy_hp_bar.value)) - float(event.amount)
		)
		displayed.enemy_hp = enemy_target
		await _tween_bar(_enemy_hp_bar, enemy_target)
	else:
		var player_target := maxf(
			0.0, float(displayed.get("player_hp", _player_hp_bar.value)) - float(event.amount)
		)
		displayed.player_hp = player_target
		await _tween_bar(_player_hp_bar, player_target)


func _play_restore(event: Dictionary, displayed: Dictionary) -> void:
	var target := str(event.get("target", "player"))
	var text := _restore_text(event)
	_record_feedback(text)
	_show_floating_text(_visual_for(target), text, "restore")
	if target == "player":
		var health_target := minf(
			_player_hp_bar.max_value,
			float(displayed.get("player_hp", _player_hp_bar.value)) + float(event.health),
		)
		var mana_target := minf(
			_player_mana_bar.max_value,
			float(displayed.get("player_mana", _player_mana_bar.value)) + float(event.mana),
		)
		displayed.player_hp = health_target
		displayed.player_mana = mana_target
		await _tween_bar(_player_hp_bar, health_target)
		await _tween_bar(_player_mana_bar, mana_target)
	else:
		var enemy_target := minf(
			_enemy_hp_bar.max_value,
			float(displayed.get("enemy_hp", _enemy_hp_bar.value)) + float(event.health),
		)
		displayed.enemy_hp = enemy_target
		await _tween_bar(_enemy_hp_bar, enemy_target)


func _play_feedback(target: String, text: String, tone: String) -> void:
	_record_feedback(text)
	_show_floating_text(_visual_for(target), text, tone)
	await get_tree().create_timer(_duration(0.22)).timeout


func _lunge(visual: Control, direction: float) -> void:
	if visual == null:
		return
	var origin := visual.position
	var tween := visual.create_tween()
	(
		tween
		. tween_property(visual, "position:x", origin.x + 24.0 * direction, _duration(0.07))
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	(
		tween
		. tween_property(visual, "position:x", origin.x, _duration(0.09))
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_IN)
	)
	await tween.finished


func _flash(visual: Control, color: Color) -> void:
	if visual == null:
		return
	visual.modulate = color
	var tween := visual.create_tween()
	tween.tween_property(visual, "modulate", Color.WHITE, _duration(0.18))


func _show_floating_text(target: Control, text: String, tone: String) -> void:
	if target == null or _feedback_layer == null or text.is_empty():
		return
	var label := Label.new()
	label.text = text
	label.size = Vector2(260, 52)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", 25 if tone == "critical" else 21)
	label.add_theme_color_override("font_color", _tone_color(tone))
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.01, 0.025, 0.95))
	label.add_theme_constant_override("outline_size", 6)
	_feedback_layer.add_child(label)
	var center: Vector2 = (
		target.get_global_rect().get_center() - _feedback_layer.get_global_rect().position
	)
	label.position = center - Vector2(label.size.x * 0.5, 15.0)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var tween := label.create_tween().set_parallel()
	(
		tween
		. tween_property(label, "position:y", label.position.y - 64.0, _duration(0.42))
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	tween.tween_property(label, "modulate:a", 0.0, _duration(0.42)).set_delay(_duration(0.12))
	tween.chain().tween_callback(label.queue_free)


func _tween_bar(bar: ProgressBar, target_value: float) -> void:
	if is_equal_approx(bar.value, target_value):
		return
	var tween := bar.create_tween()
	(
		tween
		. tween_property(bar, "value", target_value, _duration(0.22))
		. set_trans(Tween.TRANS_QUAD)
		. set_ease(Tween.EASE_OUT)
	)
	await tween.finished


func _set_turn_actor(actor: String, round_number: int) -> void:
	var player_active := actor == "player"
	_player_turn_icon.modulate = Color.WHITE if player_active else Color(0.46, 0.5, 0.58)
	_enemy_turn_icon.modulate = Color.WHITE if not player_active else Color(0.46, 0.5, 0.58)
	_turn_state_label.text = (
		"RUNDA %d  •  WYBIERZ AKCJĘ" % round_number
		if player_active
		else "RUNDA %d  •  RUCH PRZECIWNIKA" % round_number
	)


func _apply_resources(snapshot: Dictionary) -> void:
	_player_hp_bar.value = float(snapshot.get("player_hp", _player_hp_bar.value))
	_player_mana_bar.value = float(snapshot.get("player_mana", _player_mana_bar.value))
	_enemy_hp_bar.value = float(snapshot.get("enemy_hp", _enemy_hp_bar.value))
	_sync_resource_labels()


func _sync_resource_labels() -> void:
	# Domain resolution is immediate; visible numbers follow the impact-time bars.
	_player_stats_label.text = (
		"PŻ %d/%d  •  MANA %d/%d"
		% [
			roundi(_player_hp_bar.value),
			roundi(_player_hp_bar.max_value),
			roundi(_player_mana_bar.value),
			roundi(_player_mana_bar.max_value)
		]
	)
	_enemy_stats_label.text = (
		"PŻ %d/%d" % [roundi(_enemy_hp_bar.value), roundi(_enemy_hp_bar.max_value)]
	)
	for bar: ProgressBar in [_player_hp_bar, _enemy_hp_bar]:
		bar.tooltip_text = "PŻ %d/%d" % [roundi(bar.value), roundi(bar.max_value)]
	_player_mana_bar.tooltip_text = (
		"Mana %d/%d" % [roundi(_player_mana_bar.value), roundi(_player_mana_bar.max_value)]
	)


func _visual_for(side: String) -> Control:
	return _player_visual if side == "player" else _enemy_visual


func _damage_text(event: Dictionary) -> String:
	var prefix := str(event.get("prefix", ""))
	var critical := bool(event.get("critical", false))
	var amount := int(event.get("amount", 0))
	if not prefix.is_empty():
		return "%s  •  -%d" % [prefix, amount]
	return "KRYTYK  •  -%d" % amount if critical else "-%d" % amount


func _restore_text(event: Dictionary) -> String:
	var parts: Array[String] = []
	if int(event.get("health", 0)) > 0:
		parts.append("+%d PŻ" % int(event.health))
	if int(event.get("mana", 0)) > 0:
		parts.append("+%d MANY" % int(event.mana))
	return "  •  ".join(parts)


func _tone_color(tone: String) -> Color:
	match tone:
		"critical":
			return Color(1.0, 0.8, 0.3)
		"restore":
			return Color(0.42, 0.94, 0.68)
		"dodge":
			return Color(0.55, 0.84, 1.0)
		"block":
			return Color(0.62, 0.76, 0.92)
	return Color(1.0, 0.4, 0.5)


func _record_feedback(text: String) -> void:
	if not text.is_empty():
		last_feedback_texts.append(text)


func _clear_dice() -> void:
	for child in _dice_row.get_children():
		child.free()


func _finish_playback() -> void:
	_busy = false
	playback_finished.emit()


func _duration(base: float) -> float:
	return maxf(0.001, base * animation_duration_scale)
