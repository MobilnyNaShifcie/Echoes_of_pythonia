class_name CombatScreen
extends Control

signal finished(context: String, result: String)

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const HEALING_ITEM_IDS := [
	"weak_healing_potion", "strong_healing_potion", "hunter_provisions", "grandmaster_elixir"
]

var _session: GameSessionClass
var _enemy
var _engine: CombatEngineClass
var _context := "expedition"
var _rng := RandomNumberGenerator.new()

@onready var encounter_label: Label = %EncounterLabel
@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_stats_label: Label = %PlayerStatsLabel
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_stats_label: Label = %EnemyStatsLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHpBar
@onready var combat_log: RichTextLabel = %CombatLog
@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var consumable_selector: OptionButton = %ConsumableSelector
@onready var potion_button: Button = %PotionButton
@onready var flee_button: Button = %FleeButton
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	attack_button.pressed.connect(_attack)
	defend_button.pressed.connect(_defend)
	consumable_selector.item_selected.connect(_on_consumable_selected)
	potion_button.pressed.connect(_use_potion)
	flee_button.pressed.connect(_flee)
	continue_button.pressed.connect(_continue)
	_rng.randomize()
	_render()
	attack_button.grab_focus()


func configure(session: GameSessionClass, enemy_id: String, context := "expedition") -> void:
	_session = session
	_context = context
	_enemy = EnemyCatalogClass.create_enemy(enemy_id)
	_engine = CombatEngineClass.new(_session.player, _enemy, _rng)
	if is_node_ready():
		combat_log.clear()
		_append_log("Rozpoczyna się walka z: %s." % _enemy.display_name)
		_render()


func _attack() -> void:
	_resolve_turn(_engine.player_attack(), "Atakujesz przeciwnika.")


func _defend() -> void:
	_resolve_turn(_engine.player_defend(), "Przyjmujesz pozycję obronną.")


func _use_potion() -> void:
	if consumable_selector.item_count == 0:
		_append_log("Nie masz przedmiotu leczącego.")
		return
	var item_id := str(consumable_selector.get_item_metadata(consumable_selector.selected))
	if not _session.player.inventory.remove_item(item_id):
		_append_log("Nie masz wybranego przedmiotu leczącego.")
		return
	var definition = ItemCatalogClass.get_definition(item_id)
	var heal_amount: int = (
		definition.heal_hp
		+ roundi(_session.player.stats.max_hp * definition.heal_hp_percent / 100.0)
	)
	var mana_amount: int = (
		definition.restore_mana
		+ roundi(_session.player.stats.max_mana * definition.restore_mana_percent / 100.0)
	)
	_resolve_turn(
		_engine.player_use_restoration(heal_amount, mana_amount),
		"Używasz: %s." % definition.display_name
	)


func _on_consumable_selected(_index: int) -> void:
	_render_consumable_action()


func _flee() -> void:
	_resolve_turn(_engine.player_flee(), "Próbujesz uciec.")


func _resolve_turn(report: Dictionary, action_text: String) -> void:
	if report.is_empty():
		return
	_append_log("\n" + action_text)
	if report.get("enemy_dodged", false):
		_append_log("Przeciwnik unika ciosu.")
	elif report.get("player_damage", 0) > 0:
		_append_log("Zadajesz %d obrażeń." % report.player_damage)
	if report.get("player_healed", 0) > 0:
		_append_log("Odzyskujesz %d PŻ." % report.player_healed)
	if report.get("player_mana_restored", 0) > 0:
		_append_log("Odzyskujesz %d Many." % report.player_mana_restored)
	if report.get("flee_failed", false):
		_append_log("Droga odwrotu została odcięta.")
	if not report.get("enemy_special_name", "").is_empty():
		_append_log("%s używa: %s." % [_enemy.display_name, report.enemy_special_name])
	if report.get("enemy_acted", false):
		if report.get("enemy_damage", 0) > 0:
			_append_log("Otrzymujesz %d obrażeń." % report.enemy_damage)
		else:
			_append_log("Atak przeciwnika nie zadaje obrażeń.")
		if report.get("enemy_extra_damage", 0) > 0:
			_append_log("Kolejny atak zadaje %d obrażeń." % report.enemy_extra_damage)
	_render()
	if _engine.result != CombatEngineClass.ONGOING:
		_finish_battle()


func _finish_battle() -> void:
	_set_actions_enabled(false)
	result_panel.visible = true
	match _engine.result:
		CombatEngineClass.VICTORY:
			result_label.text = _resolve_victory()
		CombatEngineClass.DEFEAT:
			result_label.text = _resolve_defeat()
		CombatEngineClass.FLED:
			_session.last_activity = "Ucieczka z walki z: %s." % _enemy.display_name
			result_label.text = "Ucieczka udana. Wracasz na szlak."
	_render()
	continue_button.grab_focus()


func _resolve_victory() -> String:
	if _context == "prologue":
		_session.player.stats.restore_full()
		_session.prologue_stage = 2
		_session.last_activity = "Pokonano Przeklętego Stracha na Wróble."
		return "Zwycięstwo. Po walce odzyskujesz pełne PŻ i możesz przeszukać pobojowisko."
	var rewards := AdventureServiceClass.resolve_victory(_session, _enemy, _rng)
	var text := "Zwycięstwo  •  +%d EXP  •  +%d złota" % [rewards.experience, rewards.gold]
	if rewards.levels_gained > 0:
		text += "  •  Awans: +%d poziom" % rewards.levels_gained
	if not rewards.loot_names.is_empty():
		text += "\nŁup: %s" % ", ".join(rewards.loot_names)
	if not rewards.quest_update.is_empty():
		text += (
			"\nMisja: Wilki %d/%d"
			% [
				rewards.quest_update.current,
				rewards.quest_update.required,
			]
		)
	return text


func _resolve_defeat() -> String:
	if _context == "prologue":
		_session.player.stats.restore_full()
		_session.prologue_stage = 1
		return "Porażka. Możesz ponownie podjąć walkę prologu."
	return AdventureServiceClass.resolve_defeat(_session, _enemy.display_name).message


func _continue() -> void:
	finished.emit(_context, _engine.result)


func _render() -> void:
	if _session == null or _enemy == null or _engine == null:
		return
	var player = _session.player
	encounter_label.text = (
		"WALKA FABULARNA — PROLOG"
		if _context == "prologue"
		else "ZMIERZCHOWE RÓWNINY — WALKA TUROWA"
	)
	player_name_label.text = player.display_name
	player_stats_label.text = (
		"PŻ %d/%d  •  ATK %d  •  DEF %d  •  UNIK %.1f%%"
		% [
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.attack,
			player.stats.defense,
			player.stats.dodge,
		]
	)
	player_hp_bar.max_value = player.stats.max_hp
	player_hp_bar.value = player.stats.current_hp
	player_hp_bar.tooltip_text = "PŻ %d/%d" % [player.stats.current_hp, player.stats.max_hp]
	enemy_name_label.text = _enemy.display_name
	enemy_stats_label.text = (
		"PŻ %d/%d  •  ATK %d  •  DEF %d  •  UNIK %.1f%%"
		% [
			_enemy.current_hp,
			_enemy.max_hp,
			_enemy.attack,
			_enemy.defense,
			_enemy.dodge,
		]
	)
	enemy_hp_bar.max_value = _enemy.max_hp
	enemy_hp_bar.value = _enemy.current_hp
	enemy_hp_bar.tooltip_text = "PŻ %d/%d" % [_enemy.current_hp, _enemy.max_hp]
	flee_button.visible = _context != "prologue"
	_refresh_consumable_selector()
	_render_consumable_action()


func _set_actions_enabled(enabled: bool) -> void:
	attack_button.disabled = not enabled
	defend_button.disabled = not enabled
	potion_button.disabled = not enabled or consumable_selector.item_count == 0
	flee_button.disabled = not enabled


func _refresh_consumable_selector() -> void:
	var previous_id := ""
	if consumable_selector.item_count > 0:
		previous_id = str(consumable_selector.get_item_metadata(consumable_selector.selected))
	consumable_selector.clear()
	var selected_index := 0
	for item_id: String in HEALING_ITEM_IDS:
		var count: int = _session.player.inventory.count(item_id)
		if count <= 0:
			continue
		var definition = ItemCatalogClass.get_definition(item_id)
		consumable_selector.add_item("%s ×%d" % [definition.display_name, count])
		var index := consumable_selector.item_count - 1
		consumable_selector.set_item_metadata(index, item_id)
		if item_id == previous_id:
			selected_index = index
	if consumable_selector.item_count > 0:
		consumable_selector.select(selected_index)


func _render_consumable_action() -> void:
	if _session == null or consumable_selector.item_count == 0:
		consumable_selector.visible = false
		potion_button.text = "Brak leczenia"
		potion_button.disabled = true
		return
	consumable_selector.visible = true
	var item_id := str(consumable_selector.get_item_metadata(consumable_selector.selected))
	var definition = ItemCatalogClass.get_definition(item_id)
	var effects: Array[String] = []
	if definition.heal_hp > 0:
		effects.append("+%d PŻ" % definition.heal_hp)
	if definition.heal_hp_percent > 0:
		effects.append("+%.0f%% PŻ" % definition.heal_hp_percent)
	if definition.restore_mana > 0:
		effects.append("+%d Many" % definition.restore_mana)
	if definition.restore_mana_percent > 0:
		effects.append("+%.0f%% Many" % definition.restore_mana_percent)
	potion_button.text = "Użyj (%s)" % ", ".join(effects)
	potion_button.disabled = (
		_session.player.stats.current_hp >= _session.player.stats.max_hp
		and _session.player.stats.current_mana >= _session.player.stats.max_mana
	)


func _append_log(message: String) -> void:
	combat_log.append_text(message + "\n")
	combat_log.scroll_to_line(combat_log.get_line_count())
