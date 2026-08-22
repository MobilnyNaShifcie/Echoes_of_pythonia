class_name PartyHubScreen
extends Control

signal back_requested
signal state_changed

const CompanionCatalogClass := preload("res://core/companions/companion_catalog.gd")
const CompanionBuildServiceClass := preload("res://core/companions/companion_build_service.gd")
const CompanionCandidateClass := preload("res://core/companions/companion_candidate.gd")
const CompanionEquipmentServiceClass := preload(
	"res://core/companions/companion_equipment_service.gd"
)
const CompanionRecruitmentServiceClass := preload(
	"res://core/companions/companion_recruitment_service.gd"
)
const CompanionRelationshipServiceClass := preload(
	"res://core/companions/companion_relationship_service.gd"
)
const CompanionServiceClass := preload("res://core/companions/companion_service.gd")
const CompanionStateClass := preload("res://core/companions/companion_state.gd")
const CompanionStoryCatalogClass := preload("res://core/companions/companion_story_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const TalentCatalogClass := preload("res://core/progression/talent_catalog.gd")

var _session: GameSessionClass
var _selected_companion_id := ""
var _selected_candidate_id := ""
var _selected_companion_slot := ""
var _selected_player_item_index := -1

@onready var summary_label: Label = %SummaryLabel
@onready var tabs: TabContainer = %ModeTabs
@onready var roster_list: ItemList = %RosterList
@onready var empty_label: Label = %EmptyLabel
@onready var detail_name_label: Label = %DetailNameLabel
@onready var detail_state_label: Label = %DetailStateLabel
@onready var personal_title_label: Label = %PersonalTitleLabel
@onready var personal_text_label: Label = %PersonalTextLabel
@onready var personal_choice_one: Button = %PersonalChoiceOne
@onready var personal_choice_two: Button = %PersonalChoiceTwo
@onready var toggle_button: Button = %ToggleButton
@onready var solo_button: Button = %SoloButton
@onready var dismiss_button: Button = %DismissButton
@onready var companion_equipment_list: ItemList = %CompanionEquipmentList
@onready var player_equipment_list: ItemList = %PlayerEquipmentList
@onready var equipment_detail_label: Label = %EquipmentDetailLabel
@onready var equip_player_item_button: Button = %EquipPlayerItemButton
@onready var return_player_item_button: Button = %ReturnPlayerItemButton
@onready var candidate_list: ItemList = %CandidateList
@onready var candidate_name_label: Label = %CandidateNameLabel
@onready var candidate_detail_label: Label = %CandidateDetailLabel
@onready var talk_buttons: Array[Button] = [%TalkOne, %TalkTwo, %TalkThree]
@onready var recruit_button: Button = %RecruitButton
@onready var messages_list: ItemList = %MessagesList
@onready var message_detail_label: Label = %MessageDetailLabel
@onready var mark_read_button: Button = %MarkReadButton
@onready var result_label: Label = %ResultLabel


func _ready() -> void:
	tabs.set_tab_title(0, "Moi kompani")
	tabs.set_tab_title(1, "Kandydaci")
	tabs.set_tab_title(2, "Wiadomości")
	%BackButton.pressed.connect(back_requested.emit)
	tabs.tab_changed.connect(_tab_changed)
	roster_list.item_selected.connect(_select_companion)
	toggle_button.pressed.connect(_toggle_selected)
	solo_button.pressed.connect(_set_solo)
	dismiss_button.pressed.connect(_dismiss_selected)
	companion_equipment_list.item_selected.connect(_select_companion_equipment)
	player_equipment_list.item_selected.connect(_select_player_equipment)
	equip_player_item_button.pressed.connect(_equip_player_item)
	return_player_item_button.pressed.connect(_return_player_item)
	personal_choice_one.pressed.connect(_complete_personal_choice.bind(0))
	personal_choice_two.pressed.connect(_complete_personal_choice.bind(1))
	candidate_list.item_selected.connect(_select_candidate)
	for index in talk_buttons.size():
		talk_buttons[index].pressed.connect(_talk_to_candidate.bind(index))
	recruit_button.pressed.connect(_recruit_selected)
	messages_list.item_selected.connect(_select_message)
	mark_read_button.pressed.connect(_mark_messages_read)
	_render()


func configure(session: GameSessionClass) -> void:
	_session = session
	var changed := _refresh_daily_state()
	if is_node_ready():
		_render()
	if changed:
		state_changed.emit()


func _refresh_daily_state() -> bool:
	if _session == null:
		return false
	var rank_code := CompanionRecruitmentServiceClass.rank_code_for_reputation(
		_session.guild_reputation
	)
	var candidates_changed := CompanionRecruitmentServiceClass.ensure_daily_candidates(
		_session.party, _session.player, _session.day, rank_code
	)
	var message_result := CompanionRelationshipServiceClass.ensure_daily_party_message(
		_session.party, _session.day, _session.player.display_name
	)
	return candidates_changed or message_result.get("created", false)


func _select_companion(index: int) -> void:
	_selected_companion_id = str(roster_list.get_item_metadata(index))
	_render_companion_details()


func _toggle_selected() -> void:
	var companion := _selected_companion()
	if companion == null:
		return
	var result := CompanionServiceClass.set_active(
		_session.party, companion.companion_id, not companion.active, _session.day
	)
	_show_result(result.message, result.ok)
	if result.ok:
		state_changed.emit()
	_render()


func _set_solo() -> void:
	if _session == null:
		return
	var result := CompanionServiceClass.set_solo(_session.party)
	_show_result(result.message, result.ok)
	if result.ok and result.changed > 0:
		state_changed.emit()
	_render()


func _dismiss_selected() -> void:
	var companion := _selected_companion()
	if companion == null:
		return
	var result := CompanionRecruitmentServiceClass.dismiss_companion(
		_session.party, _session.player, companion.companion_id, _session.day
	)
	_show_result(result.message, result.ok)
	if result.ok:
		_selected_companion_id = ""
		_selected_companion_slot = ""
		_selected_player_item_index = -1
		state_changed.emit()
	_render()


func _select_companion_equipment(index: int) -> void:
	_selected_companion_slot = str(companion_equipment_list.get_item_metadata(index))
	_render_equipment_detail()


func _select_player_equipment(index: int) -> void:
	_selected_player_item_index = int(player_equipment_list.get_item_metadata(index))
	_render_equipment_detail()


func _equip_player_item() -> void:
	var companion := _selected_companion()
	if companion == null:
		return
	var result := CompanionEquipmentServiceClass.equip_player_item(
		_session.player, companion, _selected_player_item_index
	)
	_show_result(result.message, result.ok)
	if result.ok:
		_selected_companion_slot = result.item.slot
		_selected_player_item_index = -1
		state_changed.emit()
	_render()


func _return_player_item() -> void:
	var companion := _selected_companion()
	if companion == null:
		return
	var result := CompanionEquipmentServiceClass.remove_player_item(
		_session.player, companion, _selected_companion_slot
	)
	_show_result(result.message, result.ok)
	if result.ok:
		state_changed.emit()
	_render()


func _complete_personal_choice(choice_index: int) -> void:
	var companion := _selected_companion()
	if companion == null:
		return
	var result := CompanionRelationshipServiceClass.complete_personal_stage(companion, choice_index)
	_show_result(result.message, result.ok)
	if result.ok:
		state_changed.emit()
	_render()


func _select_candidate(index: int) -> void:
	_selected_candidate_id = str(candidate_list.get_item_metadata(index))
	_render_candidate_details()


func _talk_to_candidate(choice_index: int) -> void:
	var candidate = _selected_candidate()
	if candidate == null:
		return
	var result := CompanionRecruitmentServiceClass.talk_to_candidate(candidate, choice_index)
	_show_result(result.message, result.ok)
	if result.ok:
		state_changed.emit()
	_render_candidates()


func _recruit_selected() -> void:
	var candidate = _selected_candidate()
	if candidate == null:
		return
	var rank_code := CompanionRecruitmentServiceClass.rank_code_for_reputation(
		_session.guild_reputation
	)
	var result := CompanionRecruitmentServiceClass.recruit_candidate(
		_session.party, candidate, _session.player, rank_code
	)
	_show_result(result.message, result.ok and result.get("success", false))
	if result.ok:
		state_changed.emit()
	if result.get("success", false):
		_selected_candidate_id = ""
	_render()


func _select_message(index: int) -> void:
	if _session == null or index < 0 or index >= _session.party.messages.size():
		message_detail_label.text = "Wybierz wiadomość."
		return
	var message = _session.party.messages[index]
	message_detail_label.text = (
		"Dzień %d — %s\n\n„%s”" % [message.day, message.sender_name, message.text]
	)


func _mark_messages_read() -> void:
	if _session == null:
		return
	var changed := CompanionRelationshipServiceClass.mark_messages_read(_session.party)
	if changed > 0:
		state_changed.emit()
	_show_result("Oznaczono jako przeczytane: %d." % changed, true)
	_render_messages()
	_render_summary()


func _tab_changed(tab_index: int) -> void:
	if tab_index == 2 and _session != null and _session.party.unread_messages() > 0:
		_mark_messages_read()


func _render() -> void:
	_render_summary()
	_render_roster()
	_render_candidates()
	_render_messages()


func _render_summary() -> void:
	if _session == null:
		summary_label.text = "Brak aktywnej sesji."
		return
	var active_count := _session.party.active_companions(_session.day).size()
	summary_label.text = (
		"Kompanie %d/%d  •  aktywny skład %d/%d  •  nowe wiadomości %d"
		% [
			_session.party.companions.size(),
			CompanionServiceClass.MAX_COMPANIONS,
			active_count,
			CompanionServiceClass.MAX_ACTIVE_COMPANIONS,
			_session.party.unread_messages(),
		]
	)


func _render_roster() -> void:
	roster_list.clear()
	if _session == null:
		return
	var selected_index := -1
	for companion: CompanionStateClass in _session.party.companions:
		var row := roster_list.add_item(_companion_row(companion))
		roster_list.set_item_metadata(row, companion.companion_id)
		if companion.companion_id == _selected_companion_id:
			selected_index = row
	empty_label.visible = roster_list.item_count == 0
	if roster_list.item_count > 0:
		if selected_index < 0:
			selected_index = 0
			_selected_companion_id = str(roster_list.get_item_metadata(0))
		roster_list.select(selected_index)
	_render_companion_details()


func _render_companion_details() -> void:
	var companion := _selected_companion()
	if companion == null:
		detail_name_label.text = "Brak kompanów"
		detail_state_label.text = (
			"Zajrzyj do zakładki Kandydaci, aby poznać Poszukiwaczy "
			+ "dostępnych dzisiaj w Gildii."
		)
		personal_title_label.text = "Historia osobista"
		personal_text_label.text = "Brak historii do wyświetlenia."
		_set_companion_buttons_disabled(true)
		_render_equipment()
		return
	detail_name_label.text = "%s  •  poziom %d" % [companion.display_name, companion.level]
	var state := "AKTYWNY SKŁAD" if companion.active else "VARENHOLD"
	if companion.dead:
		state = "POLEGŁY"
	elif companion.is_injured(_session.day):
		state = "CIĘŻKO RANNY • powrót do sił: %d dni" % (companion.injury_until_day - _session.day)
	var path = TalentCatalogClass.get_path_definition(companion.path_id)
	var path_name: String = path.display_name if path != null else "Nieznana ścieżka"
	var limits := CompanionBuildServiceClass.resource_limits(companion)
	var resources := CompanionBuildServiceClass.resolved_resources(companion)
	detail_state_label.text = (
		(
			"%s\n%s • %s\nPŻ %d/%d  •  Mana %d/%d  •  Relacja %+d\n"
			+ "ATK %d  •  DEF %d  •  UNIK %.1f%%\nTaktyka: %s\n"
			+ "Atrybuty: %s\nTalenty: %s\n\n%s"
		)
		% [
			state,
			_class_name(companion.class_code),
			path_name,
			resources.current_hp,
			resources.max_hp,
			resources.current_mana,
			resources.max_mana,
			companion.relation,
			limits.attack,
			limits.defense,
			limits.dodge,
			CompanionStateClass.tactic_display_name(companion.tactic),
			_attribute_summary(companion),
			_talent_summary(companion),
			CompanionRelationshipServiceClass.idle_line(companion, _session.day),
		]
	)
	toggle_button.disabled = companion.dead or companion.is_injured(_session.day)
	toggle_button.text = "Pozostaw w Varenhold" if companion.active else "Dodaj do aktywnego składu"
	solo_button.disabled = _session.party.active_companions(_session.day).is_empty()
	dismiss_button.disabled = companion.dead
	_render_equipment()
	_render_personal_stage(companion)


func _render_equipment() -> void:
	companion_equipment_list.clear()
	player_equipment_list.clear()
	var companion := _selected_companion()
	if companion == null or _session == null:
		equipment_detail_label.text = "Wybierz kompana."
		equip_player_item_button.disabled = true
		return_player_item_button.disabled = true
		return

	var selected_companion_index := -1
	var slots: Array = companion.equipment.slots.keys()
	slots.sort()
	for slot_value in slots:
		var slot := str(slot_value)
		var item = companion.equipment.get_item(slot)
		var ownership := "osobisty" if companion.owns_item(item) else "gracza"
		var row := companion_equipment_list.add_item(
			"%s — %s [%s]" % [_slot_name(slot), item.formatted_name(), ownership]
		)
		companion_equipment_list.set_item_metadata(row, slot)
		if slot == _selected_companion_slot:
			selected_companion_index = row
	if companion_equipment_list.item_count > 0:
		if selected_companion_index < 0:
			selected_companion_index = 0
			_selected_companion_slot = str(
				companion_equipment_list.get_item_metadata(selected_companion_index)
			)
		companion_equipment_list.select(selected_companion_index)
	else:
		_selected_companion_slot = ""

	var selected_player_row := -1
	for index in _session.player.inventory.equipment_items.size():
		var item = _session.player.inventory.equipment_items[index]
		var row := player_equipment_list.add_item(
			"%s — %s" % [_slot_name(item.slot), item.formatted_name()]
		)
		player_equipment_list.set_item_metadata(row, index)
		if index == _selected_player_item_index:
			selected_player_row = row
	if selected_player_row >= 0:
		player_equipment_list.select(selected_player_row)
	elif _selected_player_item_index >= _session.player.inventory.equipment_items.size():
		_selected_player_item_index = -1
	_render_equipment_detail()


func _render_equipment_detail() -> void:
	var companion := _selected_companion()
	if companion == null or _session == null:
		return
	var lines: Array[String] = []
	var equipped_item = companion.equipment.get_item(_selected_companion_slot)
	if equipped_item != null:
		(
			lines
			. append(
				(
					"Założone: %s (%s)"
					% [
						equipped_item.formatted_name(),
						"osobiste" if companion.owns_item(equipped_item) else "należy do gracza",
					]
				)
			)
		)
	if (
		_selected_player_item_index >= 0
		and _selected_player_item_index < _session.player.inventory.equipment_items.size()
	):
		var player_item = _session.player.inventory.equipment_items[_selected_player_item_index]
		var error := CompanionEquipmentServiceClass.get_equip_error(companion, player_item)
		lines.append(
			(
				"Z plecaka: %s%s"
				% [player_item.formatted_name(), "\n%s" % error if not error.is_empty() else ""]
			)
		)
		equip_player_item_button.disabled = not error.is_empty()
	else:
		equip_player_item_button.disabled = true
	return_player_item_button.disabled = equipped_item == null or companion.owns_item(equipped_item)
	equipment_detail_label.text = "\n".join(lines) if not lines.is_empty() else "Wybierz przedmiot."


func _render_personal_stage(companion: CompanionStateClass) -> void:
	var story = CompanionStoryCatalogClass.get_story(companion.template_id)
	var arc = story.arc_by_id(companion.quest_arc_id)
	if arc == null:
		personal_title_label.text = "Historia osobista"
		personal_text_label.text = "Nie przypisano historii."
		personal_choice_one.disabled = true
		personal_choice_two.disabled = true
		return
	var available := CompanionRelationshipServiceClass.available_personal_stage(companion)
	if available.is_empty():
		personal_title_label.text = arc.title
		if companion.quest_stage >= arc.stages.size():
			personal_text_label.text = "Historia zakończona."
		else:
			var stage = arc.stages[companion.quest_stage]
			personal_text_label.text = (
				"Następny etap wymaga wspólnych Szczelin: %d/%d."
				% [companion.rifts_together, stage.unlock_rifts]
			)
		personal_choice_one.disabled = true
		personal_choice_two.disabled = true
		return
	var stage = available.stage
	personal_title_label.text = "%s — %s" % [arc.title, stage.title]
	personal_text_label.text = stage.text
	personal_choice_one.text = stage.choices[0].text
	personal_choice_two.text = stage.choices[1].text
	personal_choice_one.disabled = false
	personal_choice_two.disabled = false


func _render_candidates() -> void:
	candidate_list.clear()
	if _session == null:
		return
	var rank_code := CompanionRecruitmentServiceClass.rank_code_for_reputation(
		_session.guild_reputation
	)
	var selected_index := -1
	for candidate in _session.party.candidates:
		var score := CompanionRecruitmentServiceClass.willingness_score(
			candidate, _session.player, rank_code
		)
		var row := (
			candidate_list
			. add_item(
				(
					"%s • %s • poziom %d • %s%s"
					% [
						candidate.companion.display_name,
						_class_name(candidate.companion.class_code),
						candidate.companion.level,
						CompanionRecruitmentServiceClass.willingness_label(score),
						" • POWRÓT" if candidate.returning else "",
					]
				)
			)
		)
		candidate_list.set_item_metadata(row, candidate.candidate_id)
		if candidate.candidate_id == _selected_candidate_id:
			selected_index = row
	if candidate_list.item_count > 0:
		if selected_index < 0:
			selected_index = 0
			_selected_candidate_id = str(candidate_list.get_item_metadata(0))
		candidate_list.select(selected_index)
	_render_candidate_details()


func _render_candidate_details() -> void:
	var candidate = _selected_candidate()
	if candidate == null:
		candidate_name_label.text = "Brak kandydatów"
		candidate_detail_label.text = "Dzisiaj nikt dostępny nie szuka stałej drużyny."
		for button in talk_buttons:
			button.disabled = true
		recruit_button.disabled = true
		return
	var story = CompanionStoryCatalogClass.get_story(candidate.companion.template_id)
	var identity = CompanionCatalogClass.get_definition(candidate.companion.template_id)
	var rank_code := CompanionRecruitmentServiceClass.rank_code_for_reputation(
		_session.guild_reputation
	)
	var score := CompanionRecruitmentServiceClass.willingness_score(
		candidate, _session.player, rank_code
	)
	var path = TalentCatalogClass.get_path_definition(candidate.companion.path_id)
	candidate_name_label.text = candidate.companion.display_name
	candidate_detail_label.text = (
		(
			"%s\n\nPochodzenie: %s\nKlasa: %s • poziom %d\nŚcieżka: %s%s\n"
			+ "Styl: %s\nSzansa na porozumienie: %s\n"
			+ "Ekwipunek: nieznany do czasu dołączenia%s"
		)
		% [
			story.return_line if candidate.returning else story.intro,
			identity.origin,
			_class_name(candidate.companion.class_code),
			candidate.companion.level,
			path.display_name,
			" [RZADKA ŚCIEŻKA]" if path.requires_book() else "",
			identity.voice,
			CompanionRecruitmentServiceClass.willingness_label(score),
			(
				"\nPróba rekrutacji została już wykorzystana."
				if candidate.recruitment_attempted
				else ""
			),
		]
	)
	for index in talk_buttons.size():
		talk_buttons[index].text = CompanionStoryCatalogClass.TALK_PROMPTS[index]
		talk_buttons[index].disabled = candidate.talked
	recruit_button.disabled = (
		candidate.recruitment_attempted
		or _session.party.companions.size() >= CompanionServiceClass.MAX_COMPANIONS
	)


func _render_messages() -> void:
	messages_list.clear()
	if _session == null:
		return
	for message in _session.party.messages:
		messages_list.add_item(
			(
				"%sDzień %d — %s"
				% ["[NOWA] " if not message.read else "", message.day, message.sender_name]
			)
		)
	mark_read_button.disabled = _session.party.unread_messages() == 0
	if messages_list.item_count == 0:
		message_detail_label.text = "Brak wiadomości."
	else:
		messages_list.select(messages_list.item_count - 1)
		_select_message(messages_list.item_count - 1)


func _selected_companion() -> CompanionStateClass:
	return (
		_session.party.companion_by_id(_selected_companion_id)
		if _session != null and not _selected_companion_id.is_empty()
		else null
	)


func _selected_candidate() -> CompanionCandidateClass:
	if _session == null:
		return null
	for candidate in _session.party.candidates:
		if candidate.candidate_id == _selected_candidate_id:
			return candidate
	return null


func _set_companion_buttons_disabled(disabled: bool) -> void:
	toggle_button.disabled = disabled
	solo_button.disabled = disabled
	dismiss_button.disabled = disabled
	personal_choice_one.disabled = disabled
	personal_choice_two.disabled = disabled
	equip_player_item_button.disabled = disabled
	return_player_item_button.disabled = disabled


func _attribute_summary(companion: CompanionStateClass) -> String:
	var values := companion.attributes
	return (
		"SIŁ %d, WIT %d, INT %d, ZRĘ %d, WYT %d, SZC %d"
		% [
			values.strength,
			values.vitality,
			values.intelligence,
			values.dexterity,
			values.endurance,
			values.luck,
		]
	)


func _talent_summary(companion: CompanionStateClass) -> String:
	var names: Array[String] = []
	for talent_id: String in companion.talents:
		var talent = TalentCatalogClass.get_talent(talent_id)
		if talent != null:
			names.append(
				"%s %d/%d" % [talent.display_name, companion.talents[talent_id], talent.max_rank]
			)
	return ", ".join(names) if not names.is_empty() else "brak"


func _slot_name(slot: String) -> String:
	return (
		{
			"weapon": "Broń",
			"off_hand": "Druga ręka",
			"head": "Głowa",
			"chest": "Zbroja",
			"hands": "Rękawice",
			"feet": "Buty",
			"belt": "Pas",
			"necklace": "Naszyjnik",
			"bracelet": "Bransoleta",
			"earrings": "Kolczyki",
			"ring": "Pierścień",
		}
		. get(slot, slot)
	)


func _companion_row(companion: CompanionStateClass) -> String:
	var marker := "AKTYWNY" if companion.active else "VARENHOLD"
	if companion.dead:
		marker = "POLEGŁY"
	elif companion.is_injured(_session.day):
		marker = "CIĘŻKO RANNY"
	return (
		"%s  •  %s  •  poziom %d  •  relacja %+d  •  %s"
		% [
			companion.display_name,
			_class_name(companion.class_code),
			companion.level,
			companion.relation,
			marker
		]
	)


func _class_name(class_code: String) -> String:
	match class_code:
		"warrior":
			return "Wojownik"
		"hunter":
			return "Łowca"
		"mage":
			return "Mag"
		"pierrot":
			return "Pierrot"
		_:
			return "Nieznana klasa"


func _show_result(message: String, positive: bool) -> void:
	result_label.text = message
	result_label.modulate = Color("73c796") if positive else Color("dd6b86")
