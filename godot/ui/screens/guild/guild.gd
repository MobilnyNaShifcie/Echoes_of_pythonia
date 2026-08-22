class_name GuildScreen
extends Control

signal back_requested
signal party_requested
signal rifts_requested

const ContractDefinitionClass := preload("res://core/quests/contract_definition.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const GuildRumorCatalogClass := preload("res://core/quests/guild_rumor_catalog.gd")
const ItemCatalogClass := preload("res://core/items/item_catalog.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")

const MODE_STORY := "story"
const MODE_DAILY := "daily"
const MODE_WEEKLY := "weekly"
const MODE_MILESTONES := "milestones"
const MODE_RUMORS := "rumors"

var _session: GameSessionClass
var _mode := MODE_STORY
var _selected_quest_id := QuestServiceClass.STORY_QUEST_ID
var _selected_contract_id := ""
var _selected_milestone_id := GuildMilestoneServiceClass.MILESTONE_ORDER[0]
var _selected_rumor_index := 0

@onready var rank_label: Label = %RankLabel
@onready var rank_progress_label: Label = %RankProgressLabel
@onready var story_button: Button = %StoryButton
@onready var daily_button: Button = %DailyButton
@onready var weekly_button: Button = %WeeklyButton
@onready var milestones_button: Button = %MilestonesButton
@onready var rumors_button: Button = %RumorsButton
@onready var board_title: Label = %BoardTitle
@onready var quest_list: ItemList = %QuestList
@onready var notice_label: Label = %NoticeLabel
@onready var arc_label: Label = %ArcLabel
@onready var status_label: Label = %StatusLabel
@onready var chapter_label: Label = %ChapterLabel
@onready var quest_title_label: Label = %QuestTitleLabel
@onready var description_label: Label = %DescriptionLabel
@onready var progress_label: Label = %ProgressLabel
@onready var reward_label: Label = %RewardLabel
@onready var dependency_label: Label = %DependencyLabel
@onready var action_button: Button = %ActionButton
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	%PartyButton.pressed.connect(party_requested.emit)
	%RiftsButton.pressed.connect(rifts_requested.emit)
	story_button.pressed.connect(_set_mode.bind(MODE_STORY))
	daily_button.pressed.connect(_set_mode.bind(MODE_DAILY))
	weekly_button.pressed.connect(_set_mode.bind(MODE_WEEKLY))
	milestones_button.pressed.connect(_set_mode.bind(MODE_MILESTONES))
	rumors_button.pressed.connect(_set_mode.bind(MODE_RUMORS))
	quest_list.item_selected.connect(_select_entry)
	action_button.pressed.connect(_perform_action)
	_render()
	quest_list.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_render()


func show_story_board() -> void:
	_set_mode(MODE_STORY)


func show_daily_contracts() -> void:
	_set_mode(MODE_DAILY)


func show_weekly_contract() -> void:
	_set_mode(MODE_WEEKLY)


func show_milestones() -> void:
	_set_mode(MODE_MILESTONES)


func show_rumors() -> void:
	_set_mode(MODE_RUMORS)


func _set_mode(mode: String) -> void:
	_mode = mode
	result_label.text = ""
	_render()
	quest_list.grab_focus()


func _select_entry(index: int) -> void:
	var entry_id := str(quest_list.get_item_metadata(index))
	match _mode:
		MODE_STORY:
			_selected_quest_id = entry_id
		MODE_DAILY, MODE_WEEKLY:
			_selected_contract_id = entry_id
		MODE_MILESTONES:
			_selected_milestone_id = entry_id
		MODE_RUMORS:
			_selected_rumor_index = int(entry_id)
	_render_details()


func _perform_action() -> void:
	if _session == null:
		return
	match _mode:
		MODE_STORY:
			_perform_quest_action()
		MODE_DAILY, MODE_WEEKLY:
			_perform_contract_claim()
	_render()


func _perform_quest_action() -> void:
	var log = _session.quest_log
	var quest := QuestServiceClass.get_quest(_selected_quest_id)
	if quest == null:
		return
	if log.is_active(quest.quest_id):
		var result := QuestServiceClass.turn_in_quest(_session, quest.quest_id)
		result_label.text = result.message if not result.ok else _format_reward(result)
		if result.ok:
			_session.last_activity = "Ukończono zadanie: %s." % quest.title
	else:
		var result := QuestServiceClass.accept_quest(log, quest.quest_id, _session.player.level)
		result_label.text = result.message
		if result.ok:
			_session.last_activity = result.message


func _perform_contract_claim() -> void:
	var contract: ContractDefinitionClass = ContractServiceClass.find_contract(
		_session.contract_board, _selected_contract_id
	)
	if contract == null:
		return
	var result := ContractServiceClass.claim(_session, contract.contract_id)
	result_label.text = result.message if not result.ok else _format_reward(result)
	if result.ok:
		_session.last_activity = "Ukończono kontrakt Gildii: %s." % contract.title


func _render() -> void:
	if _session == null:
		return
	ContractServiceClass.ensure_board(_session.contract_board, _session.player)
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	rank_label.text = "RANGA %s — %s" % [rank.code, rank.display_name.to_upper()]
	rank_progress_label.text = GuildProgressionServiceClass.progress_text(_session.guild_reputation)
	story_button.disabled = _mode == MODE_STORY
	daily_button.disabled = _mode == MODE_DAILY
	weekly_button.disabled = _mode == MODE_WEEKLY
	milestones_button.disabled = _mode == MODE_MILESTONES
	rumors_button.disabled = _mode == MODE_RUMORS
	_refresh_list()
	_render_details()


func _refresh_list() -> void:
	quest_list.clear()
	match _mode:
		MODE_DAILY:
			_refresh_contract_list(_session.contract_board.daily_contracts)
		MODE_WEEKLY:
			var contracts: Array = []
			if _session.contract_board.weekly_contract != null:
				contracts.append(_session.contract_board.weekly_contract)
			_refresh_contract_list(contracts)
		MODE_MILESTONES:
			_refresh_milestone_list()
		MODE_RUMORS:
			_refresh_rumor_list()
		_:
			_refresh_quest_list()


func _refresh_milestone_list() -> void:
	board_title.text = "Kamienie milowe Gildii"
	notice_label.text = (
		"Cztery jednorazowe osiągnięcia świata dają łącznie 650 reputacji. "
		+ "Nagroda zostaje naliczona wyłącznie przez rzeczywiste zwycięstwo."
	)
	var selected_index := 0
	var milestones := GuildMilestoneServiceClass.get_all()
	for index in milestones.size():
		var milestone = milestones[index]
		var completed: bool = milestone.milestone_id in _session.guild_milestones
		var row := quest_list.add_item(
			(
				"%d. %s  —  %s"
				% [index + 1, milestone.display_name, "zdobyty" if completed else "niezdobyty"]
			)
		)
		quest_list.set_item_metadata(row, milestone.milestone_id)
		if milestone.milestone_id == _selected_milestone_id:
			selected_index = row
	_select_list_row(selected_index, false)
	_selected_milestone_id = str(quest_list.get_item_metadata(selected_index))


func _refresh_rumor_list() -> void:
	var rank := GuildProgressionServiceClass.rank_for_reputation(_session.guild_reputation)
	var rumors := (
		GuildRumorCatalogClass
		. available(
			_session.guild_reputation,
			_session.guild_milestones,
			_session.black_market.unlocked,
		)
	)
	board_title.text = "Plotki dostępne dla rangi %s" % rank.code
	notice_label.text = (
		"Plotki odblokowują się wraz z rangą i wydarzeniami świata. "
		+ "Informator oraz plotki Czarnego Rynku pojawią się w etapie 5D."
	)
	_selected_rumor_index = clampi(_selected_rumor_index, 0, maxi(0, rumors.size() - 1))
	for index in rumors.size():
		var rumor = rumors[index]
		var row := quest_list.add_item("Plotka %02d  •  ranga %s" % [index + 1, rumor.minimum_rank])
		quest_list.set_item_metadata(row, str(index))
	_select_list_row(_selected_rumor_index, false)


func _refresh_quest_list() -> void:
	board_title.text = "Akt I — dziewięć rozdziałów"
	notice_label.text = (
		"Poziom i poprzedni rozdział sterują dostępnością. Późne cele pokazują "
		+ "swoje zależności migracji."
	)
	var selected_index := 0
	var quests := QuestServiceClass.get_all_story_quests()
	for index in quests.size():
		var quest = quests[index]
		var row := quest_list.add_item(
			"%d. %s  —  %s" % [index + 1, quest.title, _short_quest_status(quest)]
		)
		quest_list.set_item_metadata(row, quest.quest_id)
		if quest.quest_id == _selected_quest_id:
			selected_index = row
	_select_list_row(selected_index, true)


func _refresh_contract_list(contracts: Array) -> void:
	var is_daily := _mode == MODE_DAILY
	var required_rank := (
		ContractServiceClass.DAILY_UNLOCK_RANK
		if is_daily
		else ContractServiceClass.WEEKLY_UNLOCK_RANK
	)
	board_title.text = "Kontrakty dzienne — 3" if is_daily else "Kontrakt tygodniowy"
	notice_label.text = (
		(
			"Zestaw %s. Automatycznie aktywny; reset korzysta z lokalnego kalendarza. "
			% (
				_session.contract_board.daily_date
				if is_daily
				else _session.contract_board.weekly_key
			)
		)
		+ "Odbiór od rangi %s." % required_rank
	)
	var selected_index := 0
	for index in contracts.size():
		var contract = contracts[index]
		var row := quest_list.add_item(
			"%d. %s  —  %s" % [index + 1, contract.title, _short_contract_status(contract)]
		)
		quest_list.set_item_metadata(row, contract.contract_id)
		if contract.contract_id == _selected_contract_id:
			selected_index = row
	_select_list_row(selected_index, false)


func _select_list_row(index: int, story: bool) -> void:
	if quest_list.item_count == 0:
		return
	quest_list.select(index)
	var entry_id := str(quest_list.get_item_metadata(index))
	if story:
		_selected_quest_id = entry_id
	elif _mode in [MODE_DAILY, MODE_WEEKLY]:
		_selected_contract_id = entry_id


func _render_details() -> void:
	if _session == null:
		return
	match _mode:
		MODE_STORY:
			_render_quest_details()
		MODE_DAILY, MODE_WEEKLY:
			_render_contract_details()
		MODE_MILESTONES:
			_render_milestone_details()
		MODE_RUMORS:
			_render_rumor_details()


func _render_milestone_details() -> void:
	var milestone := GuildMilestoneServiceClass.get_definition(_selected_milestone_id)
	if milestone == null:
		return
	var completed: bool = milestone.milestone_id in _session.guild_milestones
	arc_label.text = "ARCHIWUM GILDII"
	chapter_label.text = milestone.source_text
	quest_title_label.text = milestone.display_name
	description_label.text = (
		"To osiągnięcie świata jest rejestrowane automatycznie " + "i tylko jeden raz."
	)
	progress_label.text = "Status: %s" % ("zdobyty" if completed else "niezdobyty")
	reward_label.text = "Nagroda: %d reputacji Gildii" % milestone.reputation
	dependency_label.visible = not completed and not milestone.dependency_note.is_empty()
	dependency_label.text = "ZALEŻNOŚĆ MIGRACJI: %s" % milestone.dependency_note
	status_label.text = ("ZAPISANO W ARCHIWUM" if completed else "OCZEKUJE NA WYDARZENIE")
	action_button.text = "Przyznawane automatycznie"
	action_button.disabled = true


func _render_rumor_details() -> void:
	var rumors := (
		GuildRumorCatalogClass
		. available(
			_session.guild_reputation,
			_session.guild_milestones,
			_session.black_market.unlocked,
		)
	)
	if rumors.is_empty():
		return
	_selected_rumor_index = clampi(_selected_rumor_index, 0, rumors.size() - 1)
	var rumor = rumors[_selected_rumor_index]
	arc_label.text = "SZEPTY W SALI GILDII"
	chapter_label.text = "Dostępna od rangi %s" % rumor.minimum_rank
	quest_title_label.text = "Zasłyszana plotka"
	description_label.text = rumor.text
	progress_label.text = (
		"Plotka %d z %d obecnie dostępnych." % [_selected_rumor_index + 1, rumors.size()]
	)
	reward_label.text = "Plotki nie przyznają nagród i nie zmieniają stanu gry."
	dependency_label.visible = false
	status_label.text = "INFORMACJA"
	action_button.text = "Brak akcji"
	action_button.disabled = true


func _render_quest_details() -> void:
	var quest := QuestServiceClass.get_quest(_selected_quest_id)
	if quest == null:
		return
	var progress := QuestServiceClass.objective_progress(_session.player, _session.quest_log, quest)
	arc_label.text = quest.story_arc.to_upper()
	chapter_label.text = quest.chapter
	quest_title_label.text = quest.title
	description_label.text = quest.description
	progress_label.text = quest.objective_text(progress)
	reward_label.text = (
		"Zalecany poziom: %d  •  Nagroda: %d EXP, %d złota, %d reputacji Gildii"
		% [quest.recommended_level, quest.reward_exp, quest.reward_gold, quest.guild_reputation]
	)
	dependency_label.visible = not quest.dependency_note.is_empty()
	dependency_label.text = "ZALEŻNOŚĆ MIGRACJI: %s" % quest.dependency_note
	_render_quest_action(quest)


func _render_contract_details() -> void:
	var contract: ContractDefinitionClass = ContractServiceClass.find_contract(
		_session.contract_board, _selected_contract_id
	)
	if contract == null:
		return
	var is_daily: bool = contract.category == ContractDefinitionClass.DAILY
	arc_label.text = "KONTRAKT DZIENNY" if is_daily else "KONTRAKT TYGODNIOWY"
	chapter_label.text = "Okres: %s" % contract.period_key
	quest_title_label.text = contract.title
	description_label.text = contract.description
	var objective_lines: Array[String] = []
	for index in contract.objectives.size():
		objective_lines.append(
			ContractServiceClass.objective_text(
				_session.player, _session.contract_board, contract, index
			)
		)
	progress_label.text = "\n".join(objective_lines)
	var reputation := (
		ContractServiceClass.DAILY_REPUTATION
		if is_daily
		else ContractServiceClass.WEEKLY_REPUTATION
	)
	reward_label.text = (
		"Zalecany poziom: %d  •  Nagroda: %d EXP, %d złota, %d reputacji Gildii"
		% [contract.recommended_level, contract.reward_exp, contract.reward_gold, reputation]
	)
	if not contract.reward_item_id.is_empty():
		var item = ItemCatalogClass.get_definition(contract.reward_item_id)
		reward_label.text += "  •  %s ×%d" % [item.display_name, contract.reward_item_quantity]
	var dependency := ContractServiceClass.dependency_note(contract)
	dependency_label.visible = not dependency.is_empty()
	dependency_label.text = "ZALEŻNOŚĆ MIGRACJI: %s" % dependency
	_render_contract_action(contract)


func _render_quest_action(quest) -> void:
	var log = _session.quest_log
	if log.is_completed(quest.quest_id):
		status_label.text = "UKOŃCZONE"
		action_button.text = "Zadanie ukończone"
		action_button.disabled = true
		return
	if log.is_active(quest.quest_id):
		var ready := QuestServiceClass.is_ready_to_turn_in(_session, quest.quest_id)
		status_label.text = "GOTOWE DO ODDANIA" if ready else "AKTYWNE"
		action_button.text = "Oddaj zadanie" if ready else "Wróć po wykonaniu celu"
		action_button.disabled = not ready
		return
	var error := QuestServiceClass.get_accept_error(log, quest.quest_id, _session.player.level)
	if error.is_empty():
		status_label.text = "DOSTĘPNE NA TABLICY"
		action_button.text = "Przyjmij zadanie"
		action_button.disabled = false
	else:
		status_label.text = "ZABLOKOWANE"
		action_button.text = error
		action_button.disabled = true


func _render_contract_action(contract) -> void:
	var required_rank := (
		ContractServiceClass.DAILY_UNLOCK_RANK
		if contract.category == ContractDefinitionClass.DAILY
		else ContractServiceClass.WEEKLY_UNLOCK_RANK
	)
	if not GuildProgressionServiceClass.has_rank(_session.guild_reputation, required_rank):
		status_label.text = "ZABLOKOWANE — WYMAGANA RANGA %s" % required_rank
		action_button.text = "Wymagana ranga Gildii %s" % required_rank
		action_button.disabled = true
		return
	if ContractServiceClass.is_claimed(_session.contract_board, contract):
		status_label.text = "NAGRODA ODEBRANA"
		action_button.text = "Kontrakt ukończony"
		action_button.disabled = true
		return
	var ready := ContractServiceClass.is_ready(_session.player, _session.contract_board, contract)
	status_label.text = "GOTOWE DO ODBIORU" if ready else "AKTYWNE"
	action_button.text = "Odbierz nagrodę" if ready else "Wróć po wykonaniu celów"
	action_button.disabled = not ready


func _short_quest_status(quest) -> String:
	var log = _session.quest_log
	if log.is_completed(quest.quest_id):
		return "ukończone"
	if log.is_active(quest.quest_id):
		return (
			"gotowe"
			if QuestServiceClass.is_ready_to_turn_in(_session, quest.quest_id)
			else "aktywne"
		)
	return (
		"dostępne"
		if QuestServiceClass.get_accept_error(log, quest.quest_id, _session.player.level).is_empty()
		else "zablokowane"
	)


func _short_contract_status(contract) -> String:
	var required_rank := (
		ContractServiceClass.DAILY_UNLOCK_RANK
		if contract.category == ContractDefinitionClass.DAILY
		else ContractServiceClass.WEEKLY_UNLOCK_RANK
	)
	if not GuildProgressionServiceClass.has_rank(_session.guild_reputation, required_rank):
		return "ranga %s" % required_rank
	if ContractServiceClass.is_claimed(_session.contract_board, contract):
		return "odebrane"
	return (
		"gotowe"
		if ContractServiceClass.is_ready(_session.player, _session.contract_board, contract)
		else "aktywne"
	)


func _format_reward(result: Dictionary) -> String:
	var text := (
		"Nagroda: +%d EXP, +%d złota, +%d reputacji Gildii."
		% [result.experience, result.gold, result.guild_reputation]
	)
	if result.get("reward_item_quantity", 0) > 0:
		var item = ItemCatalogClass.get_definition(result.reward_item_id)
		text += " Otrzymano: %s ×%d." % [item.display_name, result.reward_item_quantity]
	if result.rank_changed:
		text += "\nAWANS GILDII: ranga %s." % result.new_rank_code
	if not str(result.get("completion_text", "")).is_empty():
		text += "\n\n" + str(result.completion_text)
	return text
