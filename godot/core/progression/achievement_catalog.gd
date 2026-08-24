class_name AchievementCatalog
extends RefCounted

const AchievementDefinitionClass := preload("res://core/progression/achievement_definition.gd")
const DEFAULT_TITLE := "Wędrowiec"

const ORDER := [
	"first_blood",
	"nature_breaker",
	"executioners_end",
	"silence_the_mother",
	"aurora_hunter",
	"master_smith",
	"guild_veteran",
]

const DATA := {
	"first_blood":
	{
		"name": "Pierwsza krew",
		"description": "Pokonaj pierwszego przeciwnika.",
		"title": "Łowca",
	},
	"nature_breaker":
	{
		"name": "Pogromca Natury",
		"description": "Pokonaj Strażnika Natury.",
		"title": "Pogromca Natury",
	},
	"executioners_end":
	{
		"name": "Koniec Egzekutora",
		"description": "Pokonaj Leśnego Egzekutora.",
		"title": "Kat Egzekutora",
	},
	"silence_the_mother":
	{
		"name": "Cisza nad Głuchą Wodą",
		"description": "Pokonaj Matkę Głuchej Wody.",
		"title": "Ten, Który Uciszył Matkę",
	},
	"aurora_hunter":
	{
		"name": "Pod Zorzą",
		"description": "Odnieś zwycięstwo podczas Zorzy Polarnej.",
		"title": "Dziecko Zorzy",
	},
	"master_smith":
	{
		"name": "Mistrz Kowadła",
		"description": "Ulepsz dowolny przedmiot do +10.",
		"title": "Mistrz Kowadła",
	},
	"guild_veteran":
	{
		"name": "Weteran Gildii",
		"description": "Osiągnij rangę S — Legenda w Gildii Poszukiwaczy.",
		"title": "Weteran Gildii",
	},
}


static func get_all() -> Array[AchievementDefinitionClass]:
	var definitions: Array[AchievementDefinitionClass] = []
	for achievement_id: String in ORDER:
		definitions.append(get_definition(achievement_id))
	return definitions


static func get_definition(achievement_id: String) -> AchievementDefinitionClass:
	if not DATA.has(achievement_id):
		return null
	var data: Dictionary = DATA[achievement_id]
	return (
		AchievementDefinitionClass
		. new(
			achievement_id,
			str(data.name),
			str(data.description),
			str(data.title),
		)
	)


static func is_valid_id(achievement_id: String) -> bool:
	return DATA.has(achievement_id)
