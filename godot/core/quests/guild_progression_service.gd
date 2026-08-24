class_name GuildProgressionService
extends RefCounted

const GuildRankDefinitionClass := preload("res://core/quests/guild_rank_definition.gd")

const RANKS := [
	{"code": "F", "name": "Nowicjusz", "reputation": 0},
	{"code": "E", "name": "Adept", "reputation": 100},
	{"code": "D", "name": "Poszukiwacz", "reputation": 300},
	{"code": "C", "name": "Zdobywca", "reputation": 700},
	{"code": "B", "name": "Weteran", "reputation": 1400},
	{"code": "A", "name": "Mistrz", "reputation": 2600},
	{"code": "S", "name": "Legenda", "reputation": 4500},
]


static func rank_for_reputation(reputation: int) -> GuildRankDefinitionClass:
	var selected: Dictionary = RANKS[0]
	for data: Dictionary in RANKS:
		if maxi(0, reputation) < int(data.reputation):
			break
		selected = data
	return GuildRankDefinitionClass.new(selected.code, selected.name, selected.reputation)


static func next_rank_for_reputation(reputation: int) -> GuildRankDefinitionClass:
	var current := rank_for_reputation(reputation)
	for index in RANKS.size():
		if RANKS[index].code != current.code:
			continue
		if index + 1 >= RANKS.size():
			return null
		var data: Dictionary = RANKS[index + 1]
		return GuildRankDefinitionClass.new(data.code, data.name, data.reputation)
	return null


static func has_rank(reputation: int, required_code: String) -> bool:
	var current_index := -1
	var required_index := -1
	var current_code: String = rank_for_reputation(reputation).code
	for index in RANKS.size():
		if RANKS[index].code == current_code:
			current_index = index
		if RANKS[index].code == required_code:
			required_index = index
	return required_index >= 0 and current_index >= required_index


static func progress_text(reputation: int) -> String:
	var current := rank_for_reputation(reputation)
	var next := next_rank_for_reputation(reputation)
	if next == null:
		return "%s  •  %d reputacji  •  najwyższa ranga" % [current.full_name(), reputation]
	return (
		"%s  •  %d/%d reputacji do rangi %s"
		% [current.full_name(), reputation, next.reputation_required, next.code]
	)
