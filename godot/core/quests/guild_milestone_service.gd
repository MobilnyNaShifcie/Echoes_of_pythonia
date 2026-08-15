class_name GuildMilestoneService
extends RefCounted

const GuildMilestoneDefinitionClass := preload("res://core/quests/guild_milestone_definition.gd")
const GuildProgressionServiceClass := preload("res://core/quests/guild_progression_service.gd")
const AchievementServiceClass := preload("res://core/progression/achievement_service.gd")

const MILESTONE_ORDER := [
	"boss:azhar",
	"boss:leviathan_north",
	"dungeon:sunken_order_crypt",
	"dungeon:black_fleet_wreck",
]


static func get_all() -> Array[GuildMilestoneDefinitionClass]:
	return [
		(
			GuildMilestoneDefinitionClass
			. new(
				"boss:azhar",
				"Pokonanie Azhara, Władcy Pustkowi",
				100,
				"Boss regionalny: Azhar",
				"Bossowie regionalni zostaną podłączeni w etapie świata 4F.",
			)
		),
		(
			GuildMilestoneDefinitionClass
			. new(
				"boss:leviathan_north",
				"Pokonanie Lewiatana Północy",
				150,
				"Boss regionalny: Lewiatan Północy",
				"Bossowie regionalni zostaną podłączeni w etapie świata 4F.",
			)
		),
		(
			GuildMilestoneDefinitionClass
			. new(
				"dungeon:sunken_order_crypt",
				"Ukończenie Krypty Zatopionego Zakonu",
				150,
				"Loch: Krypta Zatopionego Zakonu",
				"Lochy zostaną podłączone w etapie 6.",
			)
		),
		(
			GuildMilestoneDefinitionClass
			. new(
				"dungeon:black_fleet_wreck",
				"Ukończenie Wraku Czarnej Floty",
				250,
				"Loch: Wrak Czarnej Floty",
				"Lochy zostaną podłączone w etapie 6.",
			)
		),
	]


static func get_definition(milestone_id: String) -> GuildMilestoneDefinitionClass:
	for milestone in get_all():
		if milestone.milestone_id == milestone_id:
			return milestone
	return null


static func is_valid_id(milestone_id: String) -> bool:
	return milestone_id in MILESTONE_ORDER


static func record(session, milestone_id: String) -> Dictionary:
	var milestone := get_definition(milestone_id)
	if milestone == null:
		return {"ok": false, "awarded": false, "message": "Nieznany kamień milowy Gildii."}
	if milestone_id in session.guild_milestones:
		return {
			"ok": true,
			"awarded": false,
			"message": "Ten kamień milowy został już zapisany przez Gildię.",
		}
	var old_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	session.guild_milestones.append(milestone_id)
	session.guild_reputation += milestone.reputation
	var new_rank := GuildProgressionServiceClass.rank_for_reputation(session.guild_reputation)
	var message := "Reputacja Gildii +%d: %s." % [milestone.reputation, milestone.display_name]
	session.adventure_log.add(session.day, session.hour, message)
	if old_rank.code != new_rank.code:
		(
			session
			. adventure_log
			. add(
				session.day,
				session.hour,
				"Awans w Gildii: %s." % new_rank.full_name(),
			)
		)
	var unlocked_achievements := AchievementServiceClass.record_guild_rank(session, new_rank.code)
	session.last_activity = message
	return {
		"ok": true,
		"awarded": true,
		"message": message,
		"milestone_id": milestone_id,
		"reputation": milestone.reputation,
		"old_rank_code": old_rank.code,
		"new_rank_code": new_rank.code,
		"rank_changed": old_rank.code != new_rank.code,
		"unlocked_achievements": unlocked_achievements,
	}
