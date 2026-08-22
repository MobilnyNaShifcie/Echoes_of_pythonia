class_name WorldMapScreen
extends Control

signal back_requested
signal encounter_requested(enemy_id: String, weather_code: String, elite_modifier_id: String)
signal boss_requested(
	boss_id: String, weather_code: String, engine_script: Script, battle_title: String
)
signal dungeon_requested(dungeon_id: String)

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const CampRestServiceClass := preload("res://core/economy/camp_rest_service.gd")
const DungeonCatalogClass := preload("res://core/dungeons/dungeon_catalog.gd")
const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const QuestServiceClass := preload("res://core/quests/quest_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const RegionDefinitionClass := preload("res://core/world/region_definition.gd")
const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const RegionBossChallengeServiceClass := preload(
	"res://core/world/region_boss_challenge_service.gd"
)
const RegionBossRespawnServiceClass := preload("res://core/world/region_boss_respawn_service.gd")
const WeatherServiceClass := preload("res://core/world/weather_service.gd")

var _session: GameSessionClass
var _rng := RandomNumberGenerator.new()
var _selected_region_id := GameSessionClass.STARTING_LOCATION_ID
var _selection_locked := false

@onready var eyebrow_label: Label = %EyebrowLabel
@onready var title_label: Label = %TitleLabel
@onready var time_label: Label = %TimeLabel
@onready var player_label: Label = %PlayerLabel
@onready var region_list: ItemList = %RegionList
@onready var description_label: Label = %DescriptionLabel
@onready var risk_label: Label = %RiskLabel
@onready var map_placeholder_label: Label = %MapPlaceholderLabel
@onready var threats_label: Label = %ThreatsLabel
@onready var weather_label: Label = %WeatherLabel
@onready var camp_button: Button = %CampButton
@onready var explore_button: Button = %ExploreButton
@onready var boss_button: Button = %BossButton
@onready var dungeon_button: Button = %DungeonButton
@onready var event_label: Label = %EventLabel
@onready var quest_label: Label = %QuestLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	explore_button.pressed.connect(_explore)
	boss_button.pressed.connect(_challenge_region_boss)
	dungeon_button.pressed.connect(_enter_dungeon)
	camp_button.pressed.connect(_rest_at_camp)
	region_list.item_selected.connect(_select_region)
	_rng.randomize()
	_render()
	region_list.grab_focus()


func configure(session: GameSessionClass, selected_region_id := "") -> void:
	_session = session
	if _session != null and _session.known_region_ids.has(selected_region_id):
		_selected_region_id = selected_region_id
		_selection_locked = true
	elif _session != null and _session.known_region_ids.has(_session.current_location_id):
		_selected_region_id = _session.current_location_id
		_selection_locked = false
	if is_node_ready():
		_render()


func _select_region(index: int) -> void:
	if _selection_locked:
		_refresh_region_list()
		return
	_selected_region_id = str(region_list.get_item_metadata(index))
	_render_region()


func _explore() -> void:
	if _session == null:
		return
	var result := AdventureServiceClass.explore_region(_session, _selected_region_id, _rng)
	_render_session()
	_render_region()
	event_label.text = result.message
	if not result.enemy_id.is_empty():
		(
			encounter_requested
			. emit(
				result.enemy_id,
				result.weather_code,
				str(result.get("elite_modifier_id", "")),
			)
		)


func _rest_at_camp() -> void:
	if _session == null:
		return
	var result := CampRestServiceClass.rest(_session, _rng)
	_render_session()
	_render_region()
	event_label.text = result.message


func _enter_dungeon() -> void:
	var dungeon = DungeonCatalogClass.dungeon_for_region(_selected_region_id)
	if dungeon != null:
		dungeon_requested.emit(dungeon.dungeon_id)


func _challenge_region_boss() -> void:
	if _session == null:
		return
	var result := RegionBossChallengeServiceClass.prepare_challenge(_session, _selected_region_id)
	_render_session()
	_render_region()
	event_label.text = result.message
	if not result.ok:
		return
	(
		boss_requested
		. emit(
			result.boss_id,
			result.weather_code,
			result.engine_script,
			result.battle_title,
		)
	)


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
		region_list.set_item_disabled(row, _selection_locked and region_id != _selected_region_id)
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
	weather_label.text = (
		"%s\n%s"
		% [
			WeatherServiceClass.format_status(_session),
			WeatherServiceClass.description_for(_session.weather_code),
		]
	)
	var camp_error := CampRestServiceClass.get_rest_error(_session)
	camp_button.disabled = not camp_error.is_empty()
	camp_button.text = "Odpocznij przy ognisku  •  +2 godziny"
	camp_button.tooltip_text = (
		"Regeneruje 25% maksymalnych PŻ i 35% maksymalnej Many."
		if camp_error.is_empty()
		else camp_error
	)
	event_label.text = (
		_session.last_activity
		if not _session.last_activity.is_empty()
		else "Wybierz region. Wyprawa na Równiny przesuwa czas o godzinę."
	)
	var log = _session.quest_log
	var active_quests := QuestServiceClass.get_active_quests(log)
	if not active_quests.is_empty():
		var quest = active_quests[0]
		var progress := QuestServiceClass.objective_progress(_session.player, log, quest)
		quest_label.text = (
			"Śledzona misja: %s  •  %s" % [quest.title, quest.objective_text(progress)]
		)
	elif not QuestServiceClass.get_available_quests(log, _session.player.level).is_empty():
		quest_label.text = "Nowy rozdział fabularny czeka w Gildii Poszukiwaczy."
	elif log.completed.size() >= QuestServiceClass.get_all_story_quests().size():
		quest_label.text = "Akt I — Ślady Przebudzenia został ukończony."
	else:
		quest_label.text = "Kolejny rozdział odblokuje poziom bohatera lub postęp fabuły."


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
	var boss = RegionBossCatalogClass.boss_for_region(_selected_region_id)
	boss_button.visible = boss != null
	if boss != null:
		var remaining := RegionBossRespawnServiceClass.remaining(
			_session.world_encounters, boss.boss_id
		)
		if remaining > 0:
			boss_button.text = (
				"%s  •  Odrodzenie: %s"
				% [
					boss.display_name,
					RegionBossRespawnServiceClass.format_expedition_count(remaining)
				]
			)
			boss_button.tooltip_text = RegionBossRespawnServiceClass.blocked_message(
				boss.boss_id, remaining
			)
		else:
			boss_button.text = (
				"%s  •  BOSS • poziom %d+" % [boss.display_name, boss.recommended_level]
			)
			boss_button.tooltip_text = boss.challenge_description
			var warning := boss.level_warning(_session.player.level)
			if not warning.is_empty():
				boss_button.tooltip_text += "\n" + warning
	var dungeon = DungeonCatalogClass.dungeon_for_region(_selected_region_id)
	dungeon_button.visible = dungeon != null
	if dungeon != null:
		dungeon_button.text = "Loch SOLO: %s" % dungeon.display_name


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
