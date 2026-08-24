class_name RiftBoardScreen
extends Control

signal back_requested
signal state_changed

const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const PartyCombatEngineClass := preload("res://core/combat/party_combat_engine.gd")
const RiftCatalogClass := preload("res://core/rifts/rift_catalog.gd")
const RiftExpeditionServiceClass := preload("res://core/rifts/rift_expedition_service.gd")
const RiftLifecycleServiceClass := preload("res://core/rifts/rift_lifecycle_service.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")

var _session: GameSessionClass
var _combat: PartyCombatEngineClass
var _combat_kind := ""
var _abandon_armed := false
var _last_message := ""
var _completion := {}

@onready var back_button: Button = %BackButton
@onready var state_label: Label = %StateLabel
@onready var title_label: Label = %TitleLabel
@onready var summary_label: Label = %SummaryLabel
@onready var intro_label: Label = %IntroLabel
@onready var modifier_label: Label = %ModifierLabel
@onready var boss_label: Label = %BossLabel
@onready var party_label: Label = %PartyLabel
@onready var status_label: Label = %StatusLabel
@onready var start_button: Button = %StartButton
@onready var abandon_button: Button = %AbandonButton
@onready var combat_panel: PanelContainer = %CombatPanel
@onready var enemy_label: Label = %EnemyLabel
@onready var fighters_label: Label = %FightersLabel
@onready var combat_log_label: Label = %CombatLogLabel
@onready var skill_selector: OptionButton = %SkillSelector
@onready var help_selector: OptionButton = %HelpSelector
@onready var attack_button: Button = %AttackButton
@onready var skill_button: Button = %SkillButton
@onready var defend_button: Button = %DefendButton
@onready var help_button: Button = %HelpButton


func _ready() -> void:
	back_button.pressed.connect(back_requested.emit)
	start_button.pressed.connect(_primary_action)
	abandon_button.pressed.connect(_abandon_expedition)
	attack_button.pressed.connect(_combat_action.bind("attack"))
	skill_button.pressed.connect(_combat_action.bind("skill"))
	defend_button.pressed.connect(_combat_action.bind("defend"))
	help_button.pressed.connect(_combat_action.bind("help"))
	_render()


func configure(session: GameSessionClass) -> void:
	_session = session
	_combat = null
	_combat_kind = ""
	_abandon_armed = false
	_last_message = ""
	_completion = {}
	if is_node_ready():
		_render()


func _primary_action() -> void:
	if _session == null:
		return
	if not _completion.is_empty():
		_completion = {}
		_last_message = ""
		_render()
		return
	if _session.rifts.expedition == null:
		_start_expedition()
		return
	var segment := RiftExpeditionServiceClass.current_segment(_session)
	if not segment.ok:
		_last_message = segment.message
		_render()
		return
	match segment.kind:
		"event":
			_apply_noncombat_result(RiftExpeditionServiceClass.resolve_event(_session))
		"camp":
			_apply_noncombat_result(RiftExpeditionServiceClass.resolve_camp(_session))
		_:
			_start_combat()


func _start_expedition() -> void:
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	var companion_ids: Array[String] = []
	for companion in _session.party.active_companions(_session.day):
		companion_ids.append(companion.companion_id)
	var result := RiftLifecycleServiceClass.start_expedition(
		_session.rifts, _session.day, companion_ids, rank.code
	)
	_last_message = result.message
	if result.ok:
		_session.log_event(result.message)
		state_changed.emit()
	_render()


func _apply_noncombat_result(result: Dictionary) -> void:
	_last_message = str(result.get("message", ""))
	if result.ok and result.has("banter_lines") and not result.banter_lines.is_empty():
		_last_message += "\n\n" + "\n".join(result.banter_lines)
	if result.ok:
		state_changed.emit()
	_render()


func _start_combat() -> void:
	var result := RiftExpeditionServiceClass.start_combat(_session)
	if not result.ok:
		_last_message = result.message
		_render()
		return
	_combat = result.engine
	_combat_kind = str(result.kind)
	_last_message = "Rozpoczyna się walka z %s." % _combat.enemy.display_name
	_render()


func _combat_action(action: String) -> void:
	if _combat == null:
		return
	var report
	match action:
		"skill":
			var skill_id := _selected_metadata(skill_selector)
			report = _combat.player_skill(skill_id)
		"defend":
			report = _combat.player_defend()
		"help":
			var companion_id := _selected_metadata(help_selector)
			report = _combat.player_help(companion_id)
		_:
			report = _combat.player_basic_attack()
	var result := RiftExpeditionServiceClass.apply_combat_round(_session, _combat, report)
	var lines: Array[String] = report.lines.duplicate()
	if not result.ok or result.outcome != RiftExpeditionServiceClass.OUTCOME_ONGOING:
		lines.append(str(result.message))
	_last_message = "\n".join(lines)
	if report.turn_consumed or result.outcome != RiftExpeditionServiceClass.OUTCOME_ONGOING:
		state_changed.emit()
	match str(result.get("outcome", "")):
		RiftExpeditionServiceClass.OUTCOME_SEGMENT_COMPLETED:
			_combat = null
			_combat_kind = ""
		RiftExpeditionServiceClass.OUTCOME_DEFEAT:
			_combat = null
			_combat_kind = ""
		RiftExpeditionServiceClass.OUTCOME_RIFT_COMPLETED:
			_combat = null
			_combat_kind = ""
			_completion = result
	_render()


func _abandon_expedition() -> void:
	if _session == null or _session.rifts.expedition == null or _combat != null:
		return
	if not _abandon_armed:
		_abandon_armed = true
		_last_message = (
			"Potwierdź porzucenie. Szczelina znów stanie się dostępna " + "dla innych drużyn."
		)
		abandon_button.text = "Potwierdź porzucenie"
		_render_status()
		return
	var result := RiftLifecycleServiceClass.abandon_expedition(_session.rifts, _session.day)
	_last_message = result.message
	if result.ok:
		_session.log_event("Porzucono ekspedycję Szczeliny.")
		state_changed.emit()
	_abandon_armed = false
	_render()


func _render() -> void:
	if not is_node_ready():
		return
	back_button.disabled = _combat != null
	combat_panel.visible = false
	start_button.visible = true
	start_button.disabled = true
	start_button.text = "Rozpocznij ekspedycję"
	abandon_button.visible = false
	abandon_button.text = "Potwierdź porzucenie" if _abandon_armed else "Porzuć ekspedycję"
	if _session == null:
		_render_empty("Brak aktywnej sesji.")
		return
	summary_label.text = _completion_summary()
	if not _completion.is_empty():
		_render_completion()
		return
	if _combat != null:
		_render_combat()
		return
	var state = _session.rifts
	if state.expedition != null and state.active_rift != null:
		_render_expedition_segment()
		return
	if state.active_rift == null:
		_render_empty("Brak aktywnego alarmu Szczeliny.")
		return
	_render_active_rift()


func _render_empty(message: String) -> void:
	state_label.text = "BRAK ALARMU"
	title_label.text = message
	intro_label.text = (
		"Gildia nie wykryła obecnie stabilnej Szczeliny. "
		+ "Alarmy pojawiają się wraz z upływem czasu Pythonii."
	)
	modifier_label.text = ""
	boss_label.text = ""
	party_label.text = ""
	start_button.visible = false
	abandon_button.visible = false
	_render_status()


func _render_active_rift() -> void:
	var rift = _session.rifts.active_rift
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	var active_companions := _session.party.active_companions(_session.day)
	var eligibility := RiftLifecycleServiceClass.can_start_rift(
		rift, active_companions.size(), rank.code
	)
	var theme: Dictionary = RiftCatalogClass.get_theme(rift.theme_id)
	state_label.text = "AKTYWNY ALARM • RANGA %s" % rift.rank_code
	title_label.text = rift.theme_name
	intro_label.text = str(theme.intro)
	modifier_label.text = "Anomalie:\n" + _modifier_text(rift.modifier_ids)
	boss_label.text = (
		"Władca Szczeliny: %s\nDługość ekspedycji: %d segmentów\nPozostało na decyzję: %d dni Pythonii"
		% [
			rift.boss_name,
			rift.segment_count,
			RiftLifecycleServiceClass.days_remaining(rift, _session.day),
		]
	)
	party_label.text = (
		"Aktywni kompani: %d/3 • wymagani: %d\nRanga Gildii: %s"
		% [
			active_companions.size(),
			int(RiftCatalogClass.MIN_COMPANIONS[rift.rank_code]),
			rank.code,
		]
	)
	start_button.disabled = not eligibility.ok
	if _last_message.is_empty():
		_last_message = (
			"Szczelina jest gotowa do ekspedycji."
			if eligibility.ok
			else "Nie możesz rozpocząć ekspedycji: %s" % eligibility.message
		)
	_render_status()


func _render_expedition_segment() -> void:
	var rift = _session.rifts.active_rift
	var expedition = _session.rifts.expedition
	var segment := RiftExpeditionServiceClass.current_segment(_session)
	state_label.text = (
		"TRWA EKSPEDYCJA • SEGMENT %d/%d • %s"
		% [segment.segment_number, segment.segment_count, segment.kind_name]
	)
	title_label.text = rift.theme_name
	intro_label.text = segment.description
	modifier_label.text = "Anomalie:\n" + _modifier_text(rift.modifier_ids)
	boss_label.text = (
		"Postęp: %d/%d segmentów\nWładca Szczeliny: %s\nObozowiska: %d"
		% [
			expedition.segment_index,
			rift.segment_count,
			rift.boss_name,
			expedition.camp_visits,
		]
	)
	party_label.text = "Związany skład:\n" + _bound_party_text(expedition.party_companion_ids)
	start_button.text = _segment_action_text(str(segment.kind))
	start_button.disabled = false
	abandon_button.visible = true
	if _last_message.is_empty():
		_last_message = "Wybierz dalszy krok ekspedycji."
	_render_status()


func _render_combat() -> void:
	var rift = _session.rifts.active_rift
	var expedition = _session.rifts.expedition
	state_label.text = (
		"WALKA DRUŻYNOWA • RUNDA %d • SEGMENT %d/%d"
		% [_combat.round_number, expedition.segment_index + 1, rift.segment_count]
	)
	title_label.text = "%s — %s" % [rift.theme_name, _combat.enemy.display_name]
	intro_label.text = "Akcja bohatera → AI kompanów → akcja przeciwnika."
	modifier_label.text = "Anomalie:\n" + _modifier_text(rift.modifier_ids)
	boss_label.text = (
		"Typ segmentu: %s" % RiftExpeditionServiceClass.segment_kind_name(_combat_kind)
	)
	party_label.text = "Skład pozostaje związany do końca ekspedycji."
	start_button.visible = false
	abandon_button.visible = false
	combat_panel.visible = true
	enemy_label.text = (
		"%s  •  PŻ %d/%d  •  ATK %d  •  DEF %d"
		% [
			_combat.enemy.display_name,
			_combat.enemy.current_hp,
			_combat.enemy.max_hp,
			_combat.enemy.attack,
			_combat.enemy.defense,
		]
	)
	fighters_label.text = _fighter_status_text()
	combat_log_label.text = _last_message
	_refresh_combat_selectors()
	_render_status()


func _render_completion() -> void:
	var reward = _completion.reward
	state_label.text = "SZCZELINA ZAMKNIĘTA • RANGA %s" % _completion.rank_code
	title_label.text = _completion.rift_name
	intro_label.text = _completion.message
	modifier_label.text = (
		"NAGRODY\n• Złoto: %d\n• EXP bohatera: %d" % [reward.gold, reward.experience]
	)
	if not reward.unique_item_name.is_empty():
		modifier_label.text += "\n• UNIKAT: %s" % reward.unique_item_name
	boss_label.text = "%s został pokonany." % _completion.boss_name
	party_label.text = "Wspólna Szczelina zwiększa relację ocalałych kompanów o 3."
	start_button.text = "Wróć do tablicy alarmów"
	start_button.disabled = false
	abandon_button.visible = false
	_render_status()


func _refresh_combat_selectors() -> void:
	skill_selector.clear()
	for skill in SkillCatalogClass.get_unlocked_skills(_session.player):
		if not skill.is_combat_ready():
			continue
		skill_selector.add_item("%s • Mana %d" % [skill.display_name, skill.mana_cost])
		skill_selector.set_item_metadata(skill_selector.item_count - 1, skill.skill_id)
	skill_button.disabled = skill_selector.item_count == 0
	skill_selector.visible = skill_selector.item_count > 0
	help_selector.clear()
	for fighter in _combat.downed_companions():
		var lethal := " • EGZEKUCJA" if fighter.lethal_downed else ""
		help_selector.add_item(
			"%s • %d rund%s" % [fighter.display_name, fighter.downed_timer, lethal]
		)
		help_selector.set_item_metadata(help_selector.item_count - 1, fighter.companion_id)
	help_button.disabled = help_selector.item_count == 0
	help_selector.visible = help_selector.item_count > 0


func _fighter_status_text() -> String:
	var lines: Array[String] = []
	for fighter in _combat.all_fighters():
		var resource_text := (
			"PŻ %d/%d • Mana %d/%d"
			% [
				fighter.profile.stats.current_hp,
				fighter.profile.stats.max_hp,
				fighter.profile.stats.current_mana,
				fighter.profile.stats.max_mana,
			]
		)
		if fighter.removed:
			resource_text = "POZA WALKĄ"
		elif fighter.is_downed():
			resource_text = (
				"POWALONY • %d rund%s"
				% [fighter.downed_timer, " • EGZEKUCJA" if fighter.lethal_downed else ""]
			)
		lines.append("• %s — %s" % [fighter.display_name, resource_text])
	return "\n".join(lines)


func _modifier_text(modifier_ids: Array[String]) -> String:
	var lines: Array[String] = []
	for modifier_id: String in modifier_ids:
		var modifier = RiftCatalogClass.get_modifier(modifier_id)
		lines.append("• %s — %s" % [modifier.display_name, modifier.description])
	return "\n".join(lines)


func _bound_party_text(companion_ids: Array[String]) -> String:
	var lines: Array[String] = []
	for companion_id: String in companion_ids:
		var companion = _session.party.companion_by_id(companion_id)
		if companion == null:
			lines.append("• %s — POLEGŁY" % companion_id)
			continue
		var resources := CompanionBuildServiceClass.resolved_resources(companion)
		var limits := CompanionBuildServiceClass.resource_limits(companion)
		var state := (
			"CIĘŻKO RANNY"
			if companion.is_injured(_session.day)
			else (
				"PŻ %d/%d • Mana %d/%d"
				% [resources.current_hp, limits.max_hp, resources.current_mana, limits.max_mana]
			)
		)
		lines.append("• %s — %s" % [companion.display_name, state])
	return "\n".join(lines)


func _completion_summary() -> String:
	var rank_parts: Array[String] = []
	for rank_code: String in RiftCatalogClass.RANKS:
		var count := int(_session.rifts.completed_by_rank.get(rank_code, 0))
		if count > 0:
			rank_parts.append("%s: %d" % [rank_code, count])
	var details := "brak" if rank_parts.is_empty() else ", ".join(rank_parts)
	return "Zamknięte Szczeliny: %d • według rang: %s" % [_session.rifts.completed_total, details]


func _segment_action_text(kind: String) -> String:
	match kind:
		"event":
			return "Przejdź przez wydarzenie"
		"camp":
			return "Odpocznij w obozowisku"
		"boss":
			return "Wejdź do Serca Szczeliny"
		_:
			return "Rozpocznij starcie"


func _selected_metadata(selector: OptionButton) -> String:
	if selector.item_count == 0 or selector.selected < 0:
		return ""
	return str(selector.get_item_metadata(selector.selected))


func _render_status() -> void:
	status_label.text = _last_message
