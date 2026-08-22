extends Control

const EnemyCatalogClass := preload("res://core/combat/enemy_catalog.gd")
const GameSessionClass := preload("res://core/game/game_session.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const DungeonServiceClass := preload("res://core/dungeons/dungeon_service.gd")
const DungeonRunStateClass := preload("res://core/dungeons/dungeon_run_state.gd")
const CharacterSheetScreenClass := preload("res://ui/screens/character_sheet/character_sheet.gd")
const AdventureLogScreenClass := preload("res://ui/screens/adventure_log/adventure_log.gd")
const AchievementsScreenClass := preload("res://ui/screens/achievements/achievements.gd")
const BlackMarketScreenClass := preload("res://ui/screens/black_market/black_market.gd")
const CityHubScreenClass := preload("res://ui/screens/city_hub/city_hub.gd")
const CityEconomyScreenClass := preload("res://ui/screens/city_economy/city_economy.gd")
const CityServiceScreenClass := preload("res://ui/screens/city_service/city_service.gd")
const ClassSelectionScreenClass := preload("res://ui/screens/class_selection/class_selection.gd")
const CombatScreenClass := preload("res://ui/screens/combat/combat.gd")
const EquipmentScreenClass := preload("res://ui/screens/equipment/equipment.gd")
const DungeonScreenClass := preload("res://ui/screens/dungeon/dungeon.gd")
const RiftBoardScreenClass := preload("res://ui/screens/rift_board/rift_board.gd")
const RiftLifecycleServiceClass := preload("res://core/rifts/rift_lifecycle_service.gd")
const ExpeditionPreparationScreenClass := preload(
	"res://ui/screens/expedition_preparation/expedition_preparation.gd"
)
const GuildScreenClass := preload("res://ui/screens/guild/guild.gd")
const PartyHubScreenClass := preload("res://ui/screens/party_hub/party_hub.gd")
const LoadGameScreenClass := preload("res://ui/screens/load_game/load_game.gd")
const MainMenuScreenClass := preload("res://ui/screens/main_menu/main_menu.gd")
const NewGameScreenClass := preload("res://ui/screens/new_game/new_game.gd")
const PrologueScreenClass := preload("res://ui/screens/prologue/prologue.gd")
const ProgressionScreenClass := preload("res://ui/screens/progression/progression.gd")
const SessionReadyScreenClass := preload("res://ui/screens/session_ready/session_ready.gd")
const SkillsScreenClass := preload("res://ui/screens/skills/skills.gd")
const WorldMapScreenClass := preload("res://ui/screens/world_map/world_map.gd")
const SaveGameServiceClass := preload("res://core/save/save_game_service.gd")
const CHARACTER_SHEET_SCENE := preload("res://ui/screens/character_sheet/character_sheet.tscn")
const ADVENTURE_LOG_SCENE := preload("res://ui/screens/adventure_log/adventure_log.tscn")
const ACHIEVEMENTS_SCENE := preload("res://ui/screens/achievements/achievements.tscn")
const BLACK_MARKET_SCENE := preload("res://ui/screens/black_market/black_market.tscn")
const CITY_HUB_SCENE := preload("res://ui/screens/city_hub/city_hub.tscn")
const CITY_ECONOMY_SCENE := preload("res://ui/screens/city_economy/city_economy.tscn")
const CITY_SERVICE_SCENE := preload("res://ui/screens/city_service/city_service.tscn")
const CLASS_SELECTION_SCENE := preload("res://ui/screens/class_selection/class_selection.tscn")
const COMBAT_SCENE := preload("res://ui/screens/combat/combat.tscn")
const EQUIPMENT_SCENE := preload("res://ui/screens/equipment/equipment.tscn")
const DUNGEON_SCENE := preload("res://ui/screens/dungeon/dungeon.tscn")
const RIFT_BOARD_SCENE := preload("res://ui/screens/rift_board/rift_board.tscn")
const EXPEDITION_PREPARATION_SCENE := preload(
	"res://ui/screens/expedition_preparation/expedition_preparation.tscn"
)
const GUILD_SCENE := preload("res://ui/screens/guild/guild.tscn")
const PARTY_HUB_SCENE := preload("res://ui/screens/party_hub/party_hub.tscn")
const LOAD_GAME_SCENE := preload("res://ui/screens/load_game/load_game.tscn")
const MAIN_MENU_SCENE := preload("res://ui/screens/main_menu/main_menu.tscn")
const NEW_GAME_SCENE := preload("res://ui/screens/new_game/new_game.tscn")
const PROLOGUE_SCENE := preload("res://ui/screens/prologue/prologue.tscn")
const PROGRESSION_SCENE := preload("res://ui/screens/progression/progression.tscn")
const SESSION_READY_SCENE := preload("res://ui/screens/session_ready/session_ready.tscn")
const SKILLS_SCENE := preload("res://ui/screens/skills/skills.tscn")
const WORLD_MAP_SCENE := preload("res://ui/screens/world_map/world_map.tscn")

var _current_session: GameSessionClass
var _save_service := SaveGameServiceClass.new()
var _active_dungeon_run: DungeonRunStateClass
var _dungeon_rng := RandomNumberGenerator.new()

@onready var screen_host: Control = %ScreenHost
@onready var app_status_label: Label = %AppStatusLabel


func _ready() -> void:
	_dungeon_rng.randomize()
	_show_main_menu()


func _show_main_menu() -> void:
	var menu: MainMenuScreenClass = _replace_screen(MAIN_MENU_SCENE)
	menu.configure(_current_session != null, _save_service.any_save_exists())
	menu.continue_requested.connect(_continue_session)
	menu.new_game_requested.connect(_show_new_game)
	menu.load_requested.connect(_show_load_game)
	menu.save_requested.connect(_save_current_session)
	menu.project_status_requested.connect(_show_project_status)
	menu.exit_requested.connect(get_tree().quit)
	app_status_label.text = "Gotowe"


func _show_load_game() -> void:
	var load_game: LoadGameScreenClass = _replace_screen(LOAD_GAME_SCENE)
	load_game.configure(_save_service)
	load_game.canceled.connect(_show_main_menu)
	load_game.session_loaded.connect(_on_session_loaded)
	app_status_label.text = "Wybór zapisu"


func _save_current_session() -> void:
	var result := _save_service.save_session(_current_session)
	app_status_label.text = result.message


func _on_session_loaded(session: GameSessionClass) -> void:
	_current_session = session
	app_status_label.text = "Wczytano: %s" % session.player.display_name
	_continue_session()


func _show_new_game() -> void:
	var new_game: NewGameScreenClass = _replace_screen(NEW_GAME_SCENE)
	new_game.canceled.connect(_show_main_menu)
	new_game.session_created.connect(_on_session_created)
	app_status_label.text = "Tworzenie nowej gry"


func _on_session_created(session: GameSessionClass) -> void:
	_current_session = session
	app_status_label.text = "Aktywna sesja: %s" % session.player.display_name
	_continue_session()


func _continue_session() -> void:
	if _current_session == null:
		_show_main_menu()
	elif _current_session.prologue_completed:
		_show_city_hub()
	else:
		_show_prologue()


func _show_prologue() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var prologue: PrologueScreenClass = _replace_screen(PROLOGUE_SCENE)
	prologue.configure(_current_session)
	prologue.tutorial_battle_requested.connect(_show_combat.bind("prologue_scarecrow", "prologue"))
	prologue.prologue_completed.connect(_show_city_hub)
	app_status_label.text = "Prolog: Droga do Varenhold"


func _show_city_hub() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var hub: CityHubScreenClass = _replace_screen(CITY_HUB_SCENE)
	hub.world_map_requested.connect(_show_world_map)
	hub.guild_requested.connect(_show_guild)
	hub.hero_requested.connect(_show_character_sheet)
	hub.adventure_log_requested.connect(_show_adventure_log)
	hub.achievements_requested.connect(_show_achievements)
	hub.classes_requested.connect(_show_class_selection)
	hub.service_requested.connect(_show_city_service)
	hub.main_menu_requested.connect(_show_main_menu)
	hub.configure(_current_session)
	app_status_label.text = "Varenhold: %s" % _current_session.player.display_name


func _show_session_ready() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var ready_screen: SessionReadyScreenClass = _replace_screen(SESSION_READY_SCENE)
	ready_screen.configure(_current_session)
	ready_screen.back_to_menu_requested.connect(_show_main_menu)
	ready_screen.character_sheet_requested.connect(_show_character_sheet)
	app_status_label.text = "Aktywna sesja: %s" % _current_session.player.display_name


func _show_character_sheet() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var character_sheet: CharacterSheetScreenClass = _replace_screen(CHARACTER_SHEET_SCENE)
	character_sheet.configure(_current_session)
	character_sheet.back_requested.connect(_show_city_hub)
	character_sheet.equipment_requested.connect(_show_equipment)
	character_sheet.class_selection_requested.connect(_show_class_selection)
	character_sheet.skills_requested.connect(_show_skills)
	character_sheet.progression_requested.connect(_show_progression)
	app_status_label.text = "Karta postaci: %s" % _current_session.player.display_name


func _show_adventure_log() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var adventure_log: AdventureLogScreenClass = _replace_screen(ADVENTURE_LOG_SCENE)
	adventure_log.configure(_current_session)
	adventure_log.back_requested.connect(_show_city_hub)
	app_status_label.text = "Dziennik Przygód: %s" % _current_session.player.display_name


func _show_achievements() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var achievements: AchievementsScreenClass = _replace_screen(ACHIEVEMENTS_SCENE)
	achievements.configure(_current_session)
	achievements.back_requested.connect(_show_city_hub)
	achievements.state_changed.connect(_save_current_session_silently)
	app_status_label.text = "Osiągnięcia i tytuły: %s" % _current_session.player.display_name


func _show_skills() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var skills_screen: SkillsScreenClass = _replace_screen(SKILLS_SCENE)
	skills_screen.configure(_current_session)
	skills_screen.back_requested.connect(_show_character_sheet)
	app_status_label.text = "Umiejętności: %s" % _current_session.player.character_class_name


func _show_progression() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var progression: ProgressionScreenClass = _replace_screen(PROGRESSION_SCENE)
	progression.configure(_current_session)
	progression.back_requested.connect(_show_character_sheet)
	app_status_label.text = "Talenty i pasywy: %s" % _current_session.player.display_name


func _show_equipment() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var equipment_screen: EquipmentScreenClass = _replace_screen(EQUIPMENT_SCENE)
	equipment_screen.configure(_current_session)
	equipment_screen.back_requested.connect(_show_character_sheet)
	app_status_label.text = "Ekwipunek: %s" % _current_session.player.display_name


func _show_guild() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var guild: GuildScreenClass = _replace_screen(GUILD_SCENE)
	guild.configure(_current_session)
	guild.back_requested.connect(_show_city_hub)
	guild.party_requested.connect(_show_party_hub)
	guild.rifts_requested.connect(_show_rift_board)
	var rank := GuildProgressionServiceClass.rank_for_reputation(_current_session.guild_reputation)
	app_status_label.text = "Gildia Poszukiwaczy: ranga %s" % rank.code


func _show_party_hub() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var party_hub: PartyHubScreenClass = _replace_screen(PARTY_HUB_SCENE)
	party_hub.back_requested.connect(_show_guild)
	party_hub.state_changed.connect(_save_current_session_silently)
	party_hub.configure(_current_session)
	app_status_label.text = (
		"Drużyna: %d/3 aktywnych"
		% (_current_session.party.active_companions(_current_session.day).size())
	)


func _show_class_selection() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var class_screen: ClassSelectionScreenClass = _replace_screen(CLASS_SELECTION_SCENE)
	class_screen.configure(_current_session)
	class_screen.back_requested.connect(_show_city_hub)
	class_screen.class_chosen.connect(_show_city_hub)
	app_status_label.text = "Drogi bohatera: od poziomu 5"


func _show_city_service(service_id: String) -> void:
	if _current_session == null:
		_show_main_menu()
		return
	if service_id in ["merchant", "blacksmith", "workshop", "quartermaster"]:
		var economy: CityEconomyScreenClass = _replace_screen(CITY_ECONOMY_SCENE)
		economy.configure(_current_session, service_id)
		economy.back_requested.connect(_show_city_hub)
		app_status_label.text = (
			"Varenhold: %s" % CityEconomyScreenClass.display_name_for(service_id)
		)
		return
	if service_id == "black_market":
		_show_black_market()
		return
	if service_id == "preparation":
		_show_expedition_preparation()
		return
	var service: CityServiceScreenClass = _replace_screen(CITY_SERVICE_SCENE)
	service.back_requested.connect(_show_city_hub)
	service.world_map_requested.connect(_show_world_map)
	service.state_changed.connect(_save_current_session_silently)
	service.configure(_current_session, service_id)
	app_status_label.text = "Varenhold: %s" % CityServiceScreenClass.display_name_for(service_id)


func _show_expedition_preparation() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var preparation: ExpeditionPreparationScreenClass = _replace_screen(
		EXPEDITION_PREPARATION_SCENE
	)
	preparation.back_requested.connect(_show_city_hub)
	preparation.party_requested.connect(_show_preparation_party)
	preparation.equipment_requested.connect(_show_preparation_equipment)
	preparation.storage_requested.connect(_show_preparation_storage)
	preparation.inn_requested.connect(_show_preparation_inn)
	preparation.departure_requested.connect(_show_world_map)
	preparation.state_changed.connect(_save_current_session_silently)
	preparation.configure(_current_session)
	app_status_label.text = "Przygotowanie do wyprawy"


func _show_preparation_party() -> void:
	var party_hub: PartyHubScreenClass = _replace_screen(PARTY_HUB_SCENE)
	party_hub.back_requested.connect(_show_expedition_preparation)
	party_hub.state_changed.connect(_save_current_session_silently)
	party_hub.configure(_current_session)
	app_status_label.text = "Przygotowanie: skład drużyny"


func _show_preparation_equipment() -> void:
	var equipment_screen: EquipmentScreenClass = _replace_screen(EQUIPMENT_SCENE)
	equipment_screen.configure(_current_session)
	equipment_screen.back_requested.connect(_show_expedition_preparation)
	app_status_label.text = "Przygotowanie: ekwipunek bohatera"


func _show_preparation_storage() -> void:
	var economy: CityEconomyScreenClass = _replace_screen(CITY_ECONOMY_SCENE)
	economy.configure(_current_session, "quartermaster")
	economy.back_requested.connect(_show_expedition_preparation)
	app_status_label.text = "Przygotowanie: Magazyn Gildii"


func _show_preparation_inn() -> void:
	var service: CityServiceScreenClass = _replace_screen(CITY_SERVICE_SCENE)
	service.back_requested.connect(_show_expedition_preparation)
	service.state_changed.connect(_save_current_session_silently)
	service.configure(_current_session, "inn")
	app_status_label.text = "Przygotowanie: Karczma"


func _show_black_market() -> void:
	if _current_session == null or not _current_session.black_market.unlocked:
		_show_city_hub()
		return
	var market: BlackMarketScreenClass = _replace_screen(BLACK_MARKET_SCENE)
	market.back_requested.connect(_show_city_hub)
	market.state_changed.connect(_save_current_session_silently)
	market.configure(_current_session)
	app_status_label.text = "Czarny Rynek: dzienna dostawa"


func _save_current_session_silently() -> void:
	var result := _save_service.save_session(_current_session)
	if not result.ok:
		app_status_label.text = result.message


func _show_world_map(selected_region_id := "") -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var world_map: WorldMapScreenClass = _replace_screen(WORLD_MAP_SCENE)
	world_map.configure(_current_session, selected_region_id)
	world_map.back_requested.connect(_show_city_hub)
	world_map.encounter_requested.connect(_show_expedition_combat)
	world_map.dungeon_requested.connect(_show_dungeon)
	var region = RegionCatalogClass.get_definition(_current_session.current_location_id)
	app_status_label.text = "Wyprawa: %s" % region.display_name


func _show_expedition_combat(enemy_id: String, weather_code: String) -> void:
	_show_combat(enemy_id, "expedition", weather_code)


func _show_combat(
	enemy_id: String,
	context: String,
	weather_code := "sunny",
	engine_script = null,
	battle_title := "",
) -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var combat: CombatScreenClass = _replace_screen(COMBAT_SCENE)
	combat.configure(_current_session, enemy_id, context, weather_code, engine_script, battle_title)
	combat.finished.connect(_on_combat_finished)
	app_status_label.text = "Walka: %s" % EnemyCatalogClass.display_name_for(enemy_id)


func _on_combat_finished(context: String, result: String) -> void:
	if context == "prologue":
		_show_prologue()
	elif context == "dungeon":
		_on_dungeon_combat_finished(result)
	elif result == "defeat":
		_show_city_hub()
	else:
		_show_world_map()


func _show_dungeon(dungeon_id: String) -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var dungeon: DungeonScreenClass = _replace_screen(DUNGEON_SCENE)
	var run := (
		_active_dungeon_run
		if _active_dungeon_run != null and _active_dungeon_run.dungeon_id == dungeon_id
		else null
	)
	dungeon.configure(_current_session, dungeon_id, run)
	dungeon.start_requested.connect(_start_dungeon)
	dungeon.action_requested.connect(_on_dungeon_action)
	dungeon.exit_requested.connect(_leave_dungeon)
	app_status_label.text = "Loch SOLO: %s" % dungeon_id


func _start_dungeon(dungeon_id: String) -> void:
	var result := DungeonServiceClass.start(_current_session, dungeon_id, _dungeon_rng)
	if not result.ok:
		var screen := screen_host.get_child(0) as DungeonScreenClass
		screen.show_message(result.message)
		return
	_active_dungeon_run = result.run
	_show_dungeon(dungeon_id)


func _on_dungeon_action(action: String) -> void:
	if _active_dungeon_run == null:
		return
	var result := DungeonServiceClass.choose(
		_active_dungeon_run, _current_session, action, _dungeon_rng
	)
	if not result.ok:
		var screen := screen_host.get_child(0) as DungeonScreenClass
		screen.show_message(result.message)
		return
	if result.get("combat", false):
		_show_combat(
			str(result.enemy_id),
			"dungeon",
			"sunny",
			DungeonServiceClass.engine_script_for(str(result.enemy_id)),
			str(result.battle_title),
		)
		return
	_show_dungeon(_active_dungeon_run.dungeon_id)


func _on_dungeon_combat_finished(result: String) -> void:
	if _active_dungeon_run == null:
		_show_world_map()
		return
	DungeonServiceClass.resolve_combat(_active_dungeon_run, _current_session, result, _dungeon_rng)
	if _active_dungeon_run.is_finished():
		_save_current_session_silently()
	_show_dungeon(_active_dungeon_run.dungeon_id)


func _leave_dungeon(region_id: String) -> void:
	_active_dungeon_run = null
	_show_world_map(region_id)


func _show_project_status() -> void:
	app_status_label.text = (
		"v0.25.0: prolog, Varenhold, ekonomia, walka klasowa, "
		+ "progresja, pięć regionów, Akt I, Gildia, Czarny Rynek, dwa lochy SOLO "
		+ "i lifecycle Szczelin"
	)


func _show_rift_board() -> void:
	if _current_session == null:
		_show_main_menu()
		return
	var changed := _refresh_rift_world()
	var board: RiftBoardScreenClass = _replace_screen(RIFT_BOARD_SCENE)
	board.back_requested.connect(_show_guild)
	board.state_changed.connect(_save_current_session_silently)
	board.configure(_current_session)
	if changed:
		_save_current_session_silently()
	app_status_label.text = "Alarmy Szczelin"


func _refresh_rift_world() -> bool:
	var rank := GuildProgressionServiceClass.rank_for_reputation(_current_session.guild_reputation)
	var result := (
		RiftLifecycleServiceClass
		. ensure_state(
			_current_session.rifts,
			_current_session.player.display_name,
			_current_session.day,
			rank.code,
		)
	)
	if result.ok and result.changed:
		_current_session.log_event(result.notice)
		_current_session.last_activity = result.notice
	return result.ok and result.changed


func _replace_screen(scene: PackedScene) -> Control:
	for child in screen_host.get_children():
		screen_host.remove_child(child)
		child.queue_free()
	var screen := scene.instantiate() as Control
	screen_host.add_child(screen)
	return screen
