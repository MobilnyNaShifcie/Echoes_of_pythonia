class_name CombatScreen
extends Control

signal finished(context: String, result: String)

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CombatEngineClass := preload("res://core/combat/combat_engine.gd")
const ElementalResistancesClass := preload("res://core/combat/elemental_resistances.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const EliteEncounterServiceClass := preload("res://core/world/elite_encounter_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const TalentProgressionServiceClass := preload(
	"res://core/progression/talent_progression_service.gd"
)
const WeatherServiceClass := preload("res://core/world/weather_service.gd")
const HEALING_ITEM_IDS := [
	"weak_healing_potion", "strong_healing_potion", "hunter_provisions", "grandmaster_elixir"
]

var _session: GameSessionClass
var _enemy
var _engine: CombatEngineClass
var _context := "expedition"
var _rng := RandomNumberGenerator.new()
var _battle_actions_enabled := true
var _last_fate_dice: Array[int] = []
var _last_fate_outcome := ""
var _last_hunter_combo := ""
var _encounter_weather_code := WeatherServiceClass.SUNNY
var _battle_title := ""
var _configuration_error := ""

@onready var encounter_label: Label = %EncounterLabel
@onready var weather_label: Label = %EnemyNameLabel
@onready var fate_panel: PanelContainer = %FatePanel
@onready var fate_status_label: Label = %FateStatusLabel
@onready var dice_row: HBoxContainer = %DiceRow
@onready var fate_outcome_label: Label = %FateOutcomeLabel
@onready var hunter_panel: PanelContainer = %HunterPanel
@onready var hunter_sequence_label: Label = %HunterSequenceLabel
@onready var hunter_resources_label: Label = %HunterResourcesLabel
@onready var hunter_combo_label: Label = %HunterComboLabel
@onready var warrior_panel: PanelContainer = %WarriorPanel
@onready var warrior_defense_label: Label = %WarriorDefenseLabel
@onready var warrior_offense_label: Label = %WarriorOffenseLabel
@onready var warrior_retribution_label: Label = %WarriorRetributionLabel
@onready var mage_panel: PanelContainer = %MagePanel
@onready var mage_elements_label: Label = %MageElementsLabel
@onready var mage_weave_label: Label = %MageWeaveLabel
@onready var mage_ready_label: Label = %MageReadyLabel
@onready var player_name_label: Label = %PlayerNameLabel
@onready var player_stats_label: Label = %PlayerStatsLabel
@onready var player_hp_bar: ProgressBar = %PlayerHpBar
@onready var enemy_name_label: Label = %EnemyNameLabel
@onready var enemy_stats_label: Label = %EnemyStatsLabel
@onready var enemy_hp_bar: ProgressBar = %EnemyHpBar
@onready var combat_log: RichTextLabel = %CombatLog
@onready var attack_button: Button = %AttackButton
@onready var defend_button: Button = %DefendButton
@onready var skill_selector: OptionButton = %SkillSelector
@onready var skill_button: Button = %SkillButton
@onready var weave_row: HBoxContainer = %WeaveRow
@onready var second_spell_selector: OptionButton = %SecondSpellSelector
@onready var double_weave_button: Button = %DoubleWeaveButton
@onready var consumable_selector: OptionButton = %ConsumableSelector
@onready var potion_button: Button = %PotionButton
@onready var flee_button: Button = %FleeButton
@onready var result_panel: PanelContainer = %ResultPanel
@onready var result_label: Label = %ResultLabel
@onready var continue_button: Button = %ContinueButton


func _ready() -> void:
	attack_button.pressed.connect(_attack)
	defend_button.pressed.connect(_defend)
	skill_selector.item_selected.connect(_on_skill_selected)
	skill_button.pressed.connect(_use_skill)
	second_spell_selector.item_selected.connect(_on_second_spell_selected)
	double_weave_button.pressed.connect(_use_double_weave)
	consumable_selector.item_selected.connect(_on_consumable_selected)
	potion_button.pressed.connect(_use_potion)
	flee_button.pressed.connect(_flee)
	continue_button.pressed.connect(_continue)
	_rng.randomize()
	_render()
	attack_button.grab_focus()


func configure(
	session: GameSessionClass,
	enemy_id: String,
	context := "expedition",
	weather_code := WeatherServiceClass.SUNNY,
	engine_script = null,
	battle_title := "",
	elite_modifier_id := "",
) -> void:
	_session = session
	_context = context
	_encounter_weather_code = (
		weather_code
		if WeatherServiceClass.is_valid_code(weather_code)
		else WeatherServiceClass.SUNNY
	)
	_enemy = EnemyCatalogClass.create_enemy(enemy_id)
	_battle_title = battle_title
	_configuration_error = ""
	if _context == "expedition":
		WeatherServiceClass.apply_to_enemy(_enemy, _encounter_weather_code)
		if not elite_modifier_id.is_empty():
			var elite_result := EliteEncounterServiceClass.apply_modifier(
				_enemy, elite_modifier_id, _encounter_weather_code
			)
			if not elite_result.ok:
				_configuration_error = elite_result.message
	_engine = (
		engine_script.new(_session.player, _enemy, _rng)
		if engine_script != null
		else CombatEngineClass.new(_session.player, _enemy, _rng)
	)
	_battle_actions_enabled = _configuration_error.is_empty()
	_last_fate_dice.clear()
	_last_fate_outcome = ""
	_last_hunter_combo = ""
	if is_node_ready():
		combat_log.clear()
		_append_log("Rozpoczyna się walka z: %s." % _enemy.display_name)
		if not _enemy.weather_note.is_empty():
			_append_log(_enemy.weather_note + ".")
		if not _enemy.elite_note.is_empty():
			_append_log("[ELITA] %s." % _enemy.elite_note)
		if not _configuration_error.is_empty():
			_append_log("Błąd przygotowania walki: %s" % _configuration_error)
		_render()
		_set_actions_enabled(_configuration_error.is_empty())


func enemy_display_name() -> String:
	return _enemy.display_name if _enemy != null else ""


func _attack() -> void:
	_resolve_turn(_engine.player_attack(), "Atakujesz przeciwnika.")


func _defend() -> void:
	_resolve_turn(_engine.player_defend(), "Przyjmujesz pozycję obronną.")


func _use_skill() -> void:
	if skill_selector.item_count == 0:
		_append_log("Nie masz jeszcze dostępnej umiejętności bojowej.")
		return
	var skill_id := str(skill_selector.get_item_metadata(skill_selector.selected))
	var skill = SkillCatalogClass.get_definition(skill_id)
	_resolve_turn(
		_engine.player_use_skill(skill_id),
		"Używasz: %s (-%d Many)." % [skill.display_name, skill.mana_cost],
	)


func _use_double_weave() -> void:
	if skill_selector.item_count == 0 or second_spell_selector.item_count == 0:
		_append_log("Podwójny Splot wymaga dwóch zaklęć Maga.")
		return
	var first_skill_id := str(skill_selector.get_item_metadata(skill_selector.selected))
	var second_skill_id := str(
		second_spell_selector.get_item_metadata(second_spell_selector.selected)
	)
	var first = SkillCatalogClass.get_definition(first_skill_id)
	var second = SkillCatalogClass.get_definition(second_skill_id)
	_resolve_turn(
		_engine.player_use_skill_pair(first_skill_id, second_skill_id),
		"Splatasz zaklęcia: %s + %s." % [first.display_name, second.display_name],
	)


func _on_skill_selected(_index: int) -> void:
	_render_skill_action()
	_render_double_weave_action()


func _on_second_spell_selected(_index: int) -> void:
	_render_double_weave_action()


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
	var error := str(report.get("error", ""))
	if not error.is_empty():
		_append_log(error)
		_render()
		return
	var rolled_dice: Array = report.get("fate_dice", [])
	if not rolled_dice.is_empty():
		_last_fate_dice.assign(rolled_dice)
		_last_fate_outcome = str(report.get("fate_outcome", ""))
	if not str(report.get("hunter_combo_name", "")).is_empty():
		_last_hunter_combo = str(report.hunter_combo_name)
	_append_log("\n" + action_text)
	if report.get("enemy_dodged", false):
		_append_log("Przeciwnik unika ciosu.")
	elif report.get("player_damage", 0) > 0:
		_append_log(
			(
				"Zadajesz %d obrażeń%s."
				% [report.player_damage, _damage_type_suffix(str(report.player_damage_type))]
			)
		)
	for note: String in report.get("skill_notes", []):
		_append_log(note)
	for note: String in report.get("class_effect_notes", []):
		_append_log(note)
	for note: String in report.get("boss_notes", []):
		_append_log(note)
	if report.get("boss_aura_damage", 0) > 0:
		_append_log("Klątwa Głębin zadaje %d obrażeń od Wody." % int(report.boss_aura_damage))
	if report.get("player_healed", 0) > 0:
		_append_log("Odzyskujesz %d PŻ." % report.player_healed)
	if report.get("player_mana_restored", 0) > 0:
		_append_log("Odzyskujesz %d Many." % report.player_mana_restored)
	if report.get("flee_failed", false):
		_append_log("Droga odwrotu została odcięta.")
	if not report.get("enemy_special_name", "").is_empty():
		_append_log("%s używa: %s." % [_enemy.display_name, report.enemy_special_name])
	if report.get("enemy_acted", false):
		if report.get("player_dodged", false):
			_append_log("Unikasz ataku przeciwnika.")
		elif report.get("enemy_damage", 0) > 0:
			_append_log(
				(
					"Otrzymujesz %d obrażeń%s."
					% [report.enemy_damage, _damage_type_suffix(str(report.enemy_damage_type))]
				)
			)
		else:
			_append_log("Atak przeciwnika nie zadaje obrażeń.")
		if report.get("enemy_extra_damage", 0) > 0:
			_append_log("Kolejny atak zadaje %d obrażeń." % report.enemy_extra_damage)
		if report.get("reflected_damage", 0) > 0:
			_append_log(
				(
					"Krzywe Zwierciadło odbija cios. Przeciwnik otrzymuje %d obrażeń."
					% report.reflected_damage
				)
			)
	if report.get("enemy_healed", 0) > 0:
		_append_log("%s odzyskuje %d PŻ." % [_enemy.display_name, report.enemy_healed])
	if report.get("enemy_bleed_damage", 0) > 0:
		_append_log("Krwawienie zadaje przeciwnikowi %d obrażeń." % report.enemy_bleed_damage)
	if report.get("player_regenerated", 0) > 0:
		_append_log("Regenerujesz %d PŻ." % report.player_regenerated)
	_render()
	if _engine.result != CombatEngineClass.ONGOING:
		_finish_battle()


func _damage_type_suffix(damage_type: String) -> String:
	if damage_type == "physical":
		return ""
	return " [%s]" % ElementalResistancesClass.display_name(damage_type)


func _finish_battle() -> void:
	_set_actions_enabled(false)
	if _context in ["expedition", "dungeon"]:
		_session.camp_rest_available = true
	result_panel.visible = true
	match _engine.result:
		CombatEngineClass.VICTORY:
			result_label.text = _resolve_victory()
		CombatEngineClass.DEFEAT:
			result_label.text = _resolve_defeat()
		CombatEngineClass.FLED:
			if _context == "dungeon":
				result_label.text = "Ucieczka udana. Wycofujesz się z lochu z dotychczasowym łupem."
			else:
				_session.last_activity = "Ucieczka z walki z: %s." % _enemy.display_name
				_session.log_event(_session.last_activity)
				result_label.text = "Ucieczka udana. Wracasz na szlak."
	_render()
	continue_button.grab_focus()


func _resolve_victory() -> String:
	if _context == "prologue":
		_session.player.stats.restore_full()
		_session.prologue_stage = 2
		_session.last_activity = "Pokonano Przeklętego Stracha na Wróble."
		_session.log_event(_session.last_activity)
		return "Zwycięstwo. Po walce odzyskujesz pełne PŻ i możesz przeszukać pobojowisko."
	var rewards := (
		AdventureServiceClass.resolve_dungeon_victory(_session, _enemy, _rng)
		if _context == "dungeon"
		else AdventureServiceClass.resolve_victory(_session, _enemy, _rng)
	)
	var text := "Zwycięstwo  •  +%d EXP  •  +%d złota" % [rewards.experience, rewards.gold]
	if rewards.levels_gained > 0:
		text += "  •  Awans: +%d poziom" % rewards.levels_gained
	if not rewards.loot_names.is_empty():
		text += "\nŁup: %s" % ", ".join(rewards.loot_names)
	if not rewards.quest_update.is_empty():
		text += (
			"\nMisja „%s”: %d/%d"
			% [
				rewards.quest_update.title,
				rewards.quest_update.current,
				rewards.quest_update.required,
			]
		)
	for update: Dictionary in rewards.contract_updates:
		text += "\nKontrakt „%s”: %d/%d" % [update.title, update.current, update.required]
	for achievement in rewards.unlocked_achievements:
		text += "\nOsiągnięcie: %s — tytuł „%s”" % [achievement.display_name, achievement.title]
	if not rewards.elite_discovery_note.is_empty():
		text += "\n%s" % rewards.elite_discovery_note
	return text


func _resolve_defeat() -> String:
	if _context == "prologue":
		_session.player.stats.restore_full()
		_session.prologue_stage = 1
		return "Porażka. Możesz ponownie podjąć walkę prologu."
	if _context == "dungeon":
		return "Porażka. Rozliczenie niezabezpieczonego łupu nastąpi po opuszczeniu lochu."
	return AdventureServiceClass.resolve_defeat(_session, _enemy.display_name).message


func _continue() -> void:
	finished.emit(_context, _engine.result)


func _render() -> void:
	if _session == null or _enemy == null or _engine == null:
		return
	var player = _session.player
	if _context == "prologue":
		encounter_label.text = "WALKA FABULARNA — PROLOG"
	elif _context == "dungeon":
		encounter_label.text = (
			_battle_title.to_upper() if not _battle_title.is_empty() else "LOCH — WALKA SOLO"
		)
		var warnings := _engine.boss_status_lines()
		if not warnings.is_empty():
			encounter_label.text += "\n" + "\n".join(warnings)
	else:
		var region = RegionCatalogClass.get_definition(_session.current_location_id)
		encounter_label.text = "%s — WALKA TUROWA" % region.display_name.to_upper()
		if not _enemy.elite_modifier_id.is_empty():
			encounter_label.text += " — ELITA"
	player_name_label.text = player.titled_display_name()
	player_stats_label.text = (
		"PŻ %d/%d  •  MANA %d/%d  •  ATK %d  •  DEF %d  •  UNIK %.1f%%"
		% [
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.current_mana,
			player.stats.max_mana,
			player.stats.attack,
			player.stats.defense,
			player.stats.dodge,
		]
	)
	player_hp_bar.max_value = player.stats.max_hp
	player_hp_bar.value = player.stats.current_hp
	player_hp_bar.tooltip_text = "PŻ %d/%d" % [player.stats.current_hp, player.stats.max_hp]
	enemy_name_label.text = _enemy.display_name
	if _context == "expedition":
		enemy_name_label.text += (
			"  •  %s" % WeatherServiceClass.display_name_for(_encounter_weather_code)
		)
		enemy_name_label.tooltip_text = WeatherServiceClass.description_for(_encounter_weather_code)
		if not _enemy.weather_note.is_empty():
			enemy_name_label.tooltip_text += "\n" + _enemy.weather_note
		if not _enemy.elite_note.is_empty():
			enemy_name_label.tooltip_text += "\nElita: " + _enemy.elite_note
	else:
		enemy_name_label.tooltip_text = "Pogoda powierzchni nie wpływa na walkę w lochu."
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
	_render_fate_panel()
	_render_hunter_panel()
	_render_warrior_panel()
	_render_mage_panel()
	_refresh_skill_selector()
	_render_skill_action()
	_refresh_second_spell_selector()
	_render_double_weave_action()
	_refresh_consumable_selector()
	_render_consumable_action()


func _render_fate_panel() -> void:
	var is_pierrot := _session.player.character_class_code == "pierrot"
	fate_panel.visible = is_pierrot
	if not is_pierrot:
		return
	var mirror_status := "  •  ODBICIE GOTOWE" if _engine.pierrot_reflect_ready else ""
	fate_status_label.text = (
		"LOS %d  •  ŻETONY %d/%d%s"
		% [
			_session.player.attributes.luck,
			_engine.fate_tokens,
			_engine.fate_token_cap(),
			mirror_status,
		]
	)
	for die_label in dice_row.get_children():
		die_label.free()
	for value: int in _last_fate_dice:
		var die_label := Label.new()
		die_label.text = "[ %d ]" % value
		die_label.add_theme_color_override("font_color", Color(0.94, 0.28, 0.43))
		die_label.tooltip_text = "Tymczasowa kość k6 — wynik %d" % value
		dice_row.add_child(die_label)
	fate_outcome_label.text = (
		"RZUT OCZEKUJE" if _last_fate_outcome.is_empty() else _last_fate_outcome
	)


func _render_hunter_panel() -> void:
	var is_hunter := _session.player.character_class_code == "hunter"
	hunter_panel.visible = is_hunter
	if not is_hunter:
		return
	var sequence_text := "—"
	if not _engine.hunter_sequence.is_empty():
		sequence_text = HunterComboCatalogClass.sequence_text(_engine.hunter_sequence)
	hunter_sequence_label.text = "SEKWENCJA %s" % sequence_text
	hunter_resources_label.text = (
		"ŁADUNKI %d/3  •  ECHA %d  •  DESZCZ %d"
		% [
			_engine.hunter_explosive_charges,
			_engine.hunter_phantom_pending.size(),
			_engine.hunter_rain_pending.size(),
		]
	)
	hunter_combo_label.text = (
		"FINISHER OCZEKUJE" if _last_hunter_combo.is_empty() else _last_hunter_combo
	)


func _render_warrior_panel() -> void:
	var is_warrior := _session.player.character_class_code == "warrior"
	warrior_panel.visible = is_warrior
	if not is_warrior:
		return
	var guard := "—"
	if _engine.effects.player_guard_hits > 0:
		guard = (
			"%d%% ×%d" % [_engine.effects.player_guard_percent, _engine.effects.player_guard_hits]
		)
	warrior_defense_label.text = (
		"BLOK %.0f%%  •  GARDA %s" % [_engine.warrior_block_chance(), guard]
	)
	var armor_break := "—"
	if _engine.effects.enemy_defense_reduction_actions > 0:
		armor_break = (
			"-%d ×%d"
			% [
				_engine.effects.enemy_defense_reduction,
				_engine.effects.enemy_defense_reduction_actions,
			]
		)
	var bleed := "—"
	if _engine.effects.enemy_bleed_turns > 0:
		bleed = "%d ×%d" % [_engine.effects.enemy_bleed_damage, _engine.effects.enemy_bleed_turns]
	warrior_offense_label.text = "PANCERZ %s  •  KRWAWIENIE %s" % [armor_break, bleed]
	warrior_retribution_label.text = (
		"ODWET %.0f%% DEF" % (_engine.warrior_retribution_ratio * 100.0)
		if _engine.warrior_retribution_ready
		else "ODWET —"
	)


func _render_mage_panel() -> void:
	var is_mage := _session.player.character_class_code == "mage"
	mage_panel.visible = is_mage
	if not is_mage:
		return
	var elements: Array[String] = []
	for damage_type: String in _engine.mage_element_sequence:
		elements.append(ElementalResistancesClass.display_name(damage_type))
	mage_elements_label.text = (
		"ŻYWIOŁY —" if elements.is_empty() else "ŻYWIOŁY " + " → ".join(elements)
	)
	var has_arcana := _has_mechanic("arcana_core")
	mage_weave_label.text = ("SPLOT %d/3" % _engine.mage_arcane_weave if has_arcana else "SPLOT —")
	if _engine.can_double_cast():
		mage_ready_label.text = "PODWÓJNY SPLOT GOTOWY"
	elif has_arcana and _has_mechanic("arcana_double_weave"):
		mage_ready_label.text = "SPLOT SIĘ ŁADUJE"
	else:
		mage_ready_label.text = "ARKANA — TALENT 3F"


func _set_actions_enabled(enabled: bool) -> void:
	_battle_actions_enabled = enabled
	attack_button.disabled = not enabled
	defend_button.disabled = not enabled
	_render_skill_action()
	_render_double_weave_action()
	potion_button.disabled = not enabled or consumable_selector.item_count == 0
	flee_button.disabled = not enabled


func _refresh_skill_selector() -> void:
	var previous_id := ""
	if skill_selector.item_count > 0:
		previous_id = str(skill_selector.get_item_metadata(skill_selector.selected))
	skill_selector.clear()
	var selected_index := 0
	for skill in SkillCatalogClass.get_combat_ready_skills(_session.player):
		skill_selector.add_item("%s  •  %d Many" % [skill.display_name, skill.mana_cost])
		var index := skill_selector.item_count - 1
		skill_selector.set_item_metadata(index, skill.skill_id)
		if skill.skill_id == previous_id:
			selected_index = index
	if skill_selector.item_count > 0:
		skill_selector.select(selected_index)


func _render_skill_action() -> void:
	if _session == null or _engine == null:
		return
	if skill_selector.item_count == 0:
		skill_selector.visible = false
		if _session.player.character_class_code == "none":
			skill_button.text = "Umiejętności po wyborze Drogi"
		else:
			skill_button.text = "Brak odblokowanych umiejętności"
		skill_button.tooltip_text = "Podgląd pełnego katalogu znajdziesz na karcie bohatera."
		skill_button.disabled = true
		return
	skill_selector.visible = true
	var skill_id := str(skill_selector.get_item_metadata(skill_selector.selected))
	var skill = SkillCatalogClass.get_definition(skill_id)
	var error := _engine.get_skill_use_error(skill_id)
	skill_button.text = "Użyj umiejętności"
	skill_button.tooltip_text = skill.description if error.is_empty() else error
	skill_button.disabled = not _battle_actions_enabled or not error.is_empty()


func _refresh_second_spell_selector() -> void:
	var is_mage := _session.player.character_class_code == "mage"
	weave_row.visible = is_mage
	if not is_mage:
		second_spell_selector.clear()
		return
	var previous_id := ""
	if second_spell_selector.item_count > 0:
		previous_id = str(second_spell_selector.get_item_metadata(second_spell_selector.selected))
	second_spell_selector.clear()
	var selected_index := 0
	for skill in SkillCatalogClass.get_combat_ready_skills(_session.player):
		if not skill.is_offensive():
			continue
		second_spell_selector.add_item("II: %s" % skill.display_name)
		var index := second_spell_selector.item_count - 1
		second_spell_selector.set_item_metadata(index, skill.skill_id)
		if skill.skill_id == previous_id:
			selected_index = index
	if second_spell_selector.item_count > 0:
		second_spell_selector.select(selected_index)


func _render_double_weave_action() -> void:
	if _session == null or _engine == null:
		return
	if _session.player.character_class_code != "mage":
		weave_row.visible = false
		return
	weave_row.visible = true
	if skill_selector.item_count == 0 or second_spell_selector.item_count == 0:
		double_weave_button.text = "Brak zaklęć"
		double_weave_button.disabled = true
		return
	var first_id := str(skill_selector.get_item_metadata(skill_selector.selected))
	var second_id := str(second_spell_selector.get_item_metadata(second_spell_selector.selected))
	var error := _engine.get_skill_pair_error(first_id, second_id)
	var total_cost := _engine.get_double_cast_cost(first_id, second_id)
	double_weave_button.text = "Podwójny Splot (%d)" % total_cost
	double_weave_button.tooltip_text = (
		"Rzuć dwa zaklęcia, potem przeciwnik otrzyma jedną turę." if error.is_empty() else error
	)
	double_weave_button.disabled = not _battle_actions_enabled or not error.is_empty()


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
		not _battle_actions_enabled
		or (
			_session.player.stats.current_hp >= _session.player.stats.max_hp
			and _session.player.stats.current_mana >= _session.player.stats.max_mana
		)
	)


func _append_log(message: String) -> void:
	combat_log.append_text(message + "\n")
	combat_log.scroll_to_line(combat_log.get_line_count())


func _has_mechanic(mechanic_id: String) -> bool:
	return (
		mechanic_id in _session.player.unlocked_class_mechanic_ids
		or TalentProgressionServiceClass.has_talent(_session.player, mechanic_id)
	)
