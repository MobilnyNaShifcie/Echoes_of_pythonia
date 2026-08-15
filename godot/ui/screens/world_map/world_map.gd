class_name WorldMapScreen
extends Control

signal back_requested
signal encounter_requested(enemy_id: String)

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const RegionDefinitionClass := preload("res://core/world/region_definition.gd")

var _session: GameSessionClass
var _rng := RandomNumberGenerator.new()
var _selected_region_id := GameSessionClass.STARTING_LOCATION_ID

@onready var eyebrow_label: Label = %EyebrowLabel
@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var player_label: Label = %PlayerLabel
@onready var region_list: ItemList = %RegionList
@onready var description_label: Label = %DescriptionLabel
@onready var risk_label: Label = %RiskLabel
@onready var map_placeholder_label: Label = %MapPlaceholderLabel
@onready var threats_label: Label = %ThreatsLabel
@onready var explore_button: Button = %ExploreButton
@onready var event_label: Label = %EventLabel
@onready var quest_label: Label = %QuestLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	explore_button.pressed.connect(_explore)
	region_list.item_selected.connect(_select_region)
	_rng.randomize()
	_render()
	region_list.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if _session != null and _session.known_region_ids.has(_session.current_location_id):
		_selected_region_id = _session.current_location_id
	if is_node_ready():
		_render()


func _select_region(index: int) -> void:
	_selected_region_id = str(region_list.get_item_metadata(index))
	_render_region()


func _explore() -> void:
	if _session == null:
		return
	var result := AdventureServiceClass.explore_region(_session, _selected_region_id, _rng)
	_render_session()
	event_label.text = result.message
	if not result.enemy_id.is_empty():
		encounter_requested.emit(result.enemy_id)


func _render() -> void:
	if _session == null:
		return
	_refresh_region_list()
	_render_session()
	_render_region()


func _refresh_region_list() -> void:
	region_list.clear()
	var selected_index := 0
	for region_id: String in _session.known_region_ids:
		var region: RegionDefinitionClass = RegionCatalogClass.get_definition(region_id)
		if region == null:
			continue
		var row := region_list.add_item(
			(
				"%d. %s  •  poziom %s"
				% [region.danger_rating, region.display_name, region.recommended_level_text()]
			)
		)
		region_list.set_item_metadata(row, region_id)
		if region_id == _selected_region_id:
			selected_index = row
	if region_list.item_count > 0:
		region_list.select(selected_index)


func _render_session() -> void:
	var player := _session.player
	time_label.text = _session.formatted_time()
	player_label.text = (
		"%s  •  Poziom %d  •  PŻ %d/%d  •  ATK %d  •  DEF %d"
		% [
			player.display_name,
			player.level,
			player.stats.current_hp,
			player.stats.max_hp,
			player.stats.attack,
			player.stats.defense,
		]
	)
	event_label.text = (
		_session.last_activity
		if not _session.last_activity.is_empty()
		else "Wybierz region. Wyprawa na Równiny przesuwa czas o godzinę."
	)
	var log = _session.quest_log
	if log.is_active(QuestServiceClass.STORY_QUEST_ID):
		quest_label.text = (
			"Śledzona misja: Ci, którzy nie wrócili  •  Wilki %d/2"
			% QuestServiceClass.get_progress(log)
		)
	elif log.is_completed(QuestServiceClass.STORY_QUEST_ID):
		quest_label.text = "Misja „Ci, którzy nie wrócili” ukończona."
	else:
		quest_label.text = "Nowa misja fabularna czeka w Gildii Poszukiwaczy."


func _render_region() -> void:
	var region: RegionDefinitionClass = RegionCatalogClass.get_definition(_selected_region_id)
	if region == null:
		return
	eyebrow_label.text = (
		"REGION %d  •  NIEBEZPIECZEŃSTWO %d"
		% [
			RegionCatalogClass.REGION_ORDER.find(region.region_id) + 1,
			region.danger_rating,
		]
	)
	title_label.text = region.display_name
	description_label.text = region.description
	risk_label.text = (
		(
			"Zalecany poziom: %s  •  Szansa spotkania: %.0f%%\n%s\n"
			+ "Zalecany poziom jest ostrzeżeniem i nie blokuje regionu."
		)
		% [
			region.recommended_level_text(),
			region.encounter_chance * 100.0,
			region.level_guidance(_session.player.level),
		]
	)
	map_placeholder_label.text = (
		(
			"SCHEMAT REGIONU — PLACEHOLDER\n\n%s\n\n"
			+ "Docelowe kafelki mapy i grafika powstaną po migracji logiki świata."
		)
		% region.display_name.to_upper()
	)
	threats_label.text = _format_encounters(region)
	explore_button.disabled = false
	explore_button.text = "Wyrusz na wyprawę  •  +1 godzina"


func _format_encounters(region: RegionDefinitionClass) -> String:
	return (
		"DZIEŃ\n%s\n\nNOC\n%s"
		% [
			_format_encounter_table(region.day_encounters),
			_format_encounter_table(region.night_encounters),
		]
	)


func _format_encounter_table(encounters: Dictionary) -> String:
	var lines: Array[String] = []
	for enemy_id: String in encounters:
		lines.append("• %s" % EnemyCatalogClass.display_name_for(enemy_id))
	return "\n".join(lines)
