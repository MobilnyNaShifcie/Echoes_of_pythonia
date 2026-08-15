class_name SkillsScreen
extends Control

signal back_requested

const GameSessionClass := preload("res://core/game/game_session.gd")
const ClassCombatMechanicCatalogClass := preload(
	"res://core/combat/class_combat_mechanic_catalog.gd"
)
const HunterComboCatalogClass := preload("res://core/combat/hunter_combo_catalog.gd")
const PlayerClassCatalogClass := preload("res://core/player/player_class_catalog.gd")
const SkillCatalogClass := preload("res://core/skills/skill_catalog.gd")
const SkillDefinitionClass := preload("res://core/skills/skill_definition.gd")

var _session: GameSessionClass
var _preview_class_code := "warrior"

@onready var class_label: Label = %ClassLabel
@onready var summary_label: Label = %SummaryLabel
@onready var path_selector: OptionButton = %PathSelector
@onready var skill_list: ItemList = %SkillList
@onready var skill_name_label: Label = %SkillNameLabel
@onready var skill_meta_label: Label = %SkillMetaLabel
@onready var skill_description_label: Label = %SkillDescriptionLabel
@onready var skill_requirements_label: Label = %SkillRequirementsLabel
@onready var skill_status_label: Label = %SkillStatusLabel


func _ready() -> void:
	%BackButton.pressed.connect(back_requested.emit)
	path_selector.item_selected.connect(_on_path_selected)
	skill_list.item_selected.connect(_show_skill_details)
	_populate_path_selector()
	_render()
	%BackButton.grab_focus()


func configure(session: GameSessionClass) -> void:
	_session = session
	if is_node_ready():
		_populate_path_selector()
		_render()


func _populate_path_selector() -> void:
	path_selector.clear()
	var selected_index := 0
	for definition in PlayerClassCatalogClass.get_playable_definitions():
		path_selector.add_item(definition.display_name)
		var index := path_selector.item_count - 1
		path_selector.set_item_metadata(index, definition.class_code)
		if _session != null and definition.class_code == _session.player.character_class_code:
			selected_index = index
	path_selector.select(selected_index)
	_preview_class_code = str(path_selector.get_item_metadata(selected_index))


func _on_path_selected(index: int) -> void:
	if index < 0 or index >= path_selector.item_count:
		return
	_preview_class_code = str(path_selector.get_item_metadata(index))
	_render()


func _render() -> void:
	if _session == null:
		return
	var player := _session.player
	class_label.text = "Droga: %s  •  Poziom %d" % [player.character_class_name, player.level]
	skill_list.clear()
	var skills := SkillCatalogClass.get_preview_skills_for_class(_preview_class_code)
	if skills.is_empty():
		summary_label.text = "Brak umiejętności w wybranym katalogu."
		_show_empty_details()
		return
	var unlocked_count := 0
	for skill: SkillDefinitionClass in skills:
		var unlocked := SkillCatalogClass.is_unlocked(player, skill)
		if unlocked:
			unlocked_count += 1
		var state := "odblokowana"
		if not unlocked:
			state = (
				"wymagany talent"
				if skill.unlock_source == "talent"
				else "wymagany poziom %d" % skill.unlock_level
			)
		skill_list.add_item("%s  •  %d Many  •  %s" % [skill.display_name, skill.mana_cost, state])
		var index := skill_list.item_count - 1
		skill_list.set_item_metadata(index, skill.skill_id)
		if not unlocked:
			skill_list.set_item_custom_fg_color(index, Color(0.48, 0.56, 0.66))
	var preview_definition = PlayerClassCatalogClass.get_definition(_preview_class_code)
	if player.character_class_code == _preview_class_code:
		if _preview_class_code == "hunter":
			summary_label.text = (
				"Odblokowane: %d/%d  •  Techniki Salwy: 6  •  Odkryte kombinacje: %d/%d"
				% [
					unlocked_count,
					skills.size(),
					player.discovered_hunter_combos.size(),
					HunterComboCatalogClass.COMBO_ORDER.size(),
				]
			)
		elif _preview_class_code in ["warrior", "mage"]:
			var mechanics = ClassCombatMechanicCatalogClass.get_for_class(_preview_class_code)
			var unlocked_mechanics := 0
			for mechanic in mechanics:
				if mechanic.mechanic_id in player.unlocked_class_mechanic_ids:
					unlocked_mechanics += 1
			var system_name := (
				"Stany i tarcza" if _preview_class_code == "warrior" else "Żywioły i Splot"
			)
			summary_label.text = (
				"Odblokowane: %d/%d  •  %s  •  Mechaniki talentowe: %d/%d"
				% [
					unlocked_count,
					skills.size(),
					system_name,
					unlocked_mechanics,
					mechanics.size(),
				]
			)
		else:
			summary_label.text = (
				"Odblokowane umiejętności: %d/%d. Kolejne zdolności pojawiają się wraz z poziomem."
				% [unlocked_count, skills.size()]
			)
	else:
		summary_label.text = (
			"Podgląd Drogi: %s. Wybór klasy postaci nie zostanie tutaj zmieniony."
			% preview_definition.display_name
		)
	skill_list.select(0)
	_show_skill_details(0)


func _show_skill_details(index: int) -> void:
	if _session == null or index < 0 or index >= skill_list.item_count:
		return
	var skill_id := str(skill_list.get_item_metadata(index))
	var skill: SkillDefinitionClass = SkillCatalogClass.get_definition(skill_id)
	var player := _session.player
	skill_name_label.text = skill.display_name
	skill_meta_label.text = (
		"Poziom %d  •  Koszt: %d Many  •  %s"
		% [skill.unlock_level, skill.mana_cost, _damage_type_name(skill.damage_type)]
	)
	skill_description_label.text = skill.description
	skill_requirements_label.text = _requirements_text(skill)
	if player.character_class_code != skill.character_class_code:
		skill_status_label.text = "PODGLĄD — ta umiejętność należy do innej Drogi"
		skill_status_label.modulate = Color(0.62, 0.68, 0.76)
	elif player.level < skill.unlock_level:
		skill_status_label.text = "ZABLOKOWANA — wymagany poziom %d" % skill.unlock_level
		skill_status_label.modulate = Color(0.62, 0.68, 0.76)
	elif skill.unlock_source == "talent" and not SkillCatalogClass.is_unlocked(player, skill):
		skill_status_label.text = ("UMIEJĘTNOŚĆ TALENTOWA — wymaga odblokowania w drzewku (etap 3F)")
		skill_status_label.modulate = Color(0.88, 0.68, 0.38)
	else:
		skill_status_label.text = "ODBLOKOWANA — dostępna w panelu akcji podczas walki"
		skill_status_label.modulate = Color(0.42, 0.78, 0.56)


func _show_empty_details() -> void:
	skill_name_label.text = "Najpierw wybierz Drogę"
	skill_meta_label.text = "Wojownik  •  Łowca  •  Mag  •  Pierrot"
	skill_description_label.text = (
		"Każda Droga ma cztery bazowe umiejętności odblokowywane " + "na poziomach 5, 7, 9 i 12."
	)
	skill_requirements_label.text = "Wybór Drogi jest trwały i staje się dostępny od poziomu 5."
	skill_status_label.text = "Katalog umiejętności czeka na wybór klasy postaci."
	skill_status_label.modulate = Color(0.62, 0.68, 0.76)


func _requirements_text(skill: SkillDefinitionClass) -> String:
	var requirements: Array[String] = []
	if not skill.required_weapon_type.is_empty():
		var weapon_names := {
			"bow": "Łuk",
			"staff": "Kostur",
			"fate_lance": "Lanca Losu",
		}
		requirements.append(
			"Broń: %s" % weapon_names.get(skill.required_weapon_type, skill.required_weapon_type)
		)
	if not skill.required_offhand_type.is_empty():
		var offhand_names := {
			"shield": "Tarcza",
			"quiver": "Kołczan",
			"artifact": "Artefakt",
		}
		requirements.append(
			(
				"Druga ręka: %s"
				% offhand_names.get(skill.required_offhand_type, skill.required_offhand_type)
			)
		)
	if skill.hits > 1:
		requirements.append("Trafienia: %d" % skill.hits)
	if not skill.hunter_technique.is_empty():
		requirements.append(
			"Technika: %s" % HunterComboCatalogClass.technique_name(skill.hunter_technique)
		)
	if skill.special_armor_penetration > 0.0:
		requirements.append("Przebicie pancerza: %.0f%%" % skill.special_armor_penetration)
	if not skill.required_talent_id.is_empty():
		requirements.append("Źródło: drzewko talentów")
	if requirements.is_empty():
		return "Wymagania: brak dodatkowych wymagań sprzętowych."
	return "Wymagania: %s." % "  •  ".join(requirements)


func _damage_type_name(damage_type: String) -> String:
	return (
		{
			"physical": "obrażenia fizyczne",
			"fire": "ogień",
			"frost": "mróz",
			"wind": "wiatr",
		}
		. get(damage_type, damage_type)
	)
