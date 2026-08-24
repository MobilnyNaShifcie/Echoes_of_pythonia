class_name RegionBossChallengeService
extends RefCounted

const AdventureServiceClass := preload("res://core/world/adventure_service.gd")
const ContractServiceClass := preload("res://core/quests/contract_service.gd")
const GuildMilestoneServiceClass := preload("res://core/quests/guild_milestone_service.gd")
const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const RegionBossRespawnServiceClass := preload("res://core/world/region_boss_respawn_service.gd")


static func prepare_challenge(session, region_id: String) -> Dictionary:
	if session == null or session.player == null:
		return {"ok": false, "message": "Nie można rozpocząć wyzwania bez bohatera."}
	if region_id not in session.known_region_ids:
		return {"ok": false, "message": "Nie możesz wejść do nieznanego regionu."}
	var definition = RegionBossCatalogClass.boss_for_region(region_id)
	if definition == null:
		return {"ok": false, "message": "Ten region nie ma jawnego wyzwania bossa."}
	var remaining := RegionBossRespawnServiceClass.remaining(
		session.world_encounters, definition.boss_id
	)
	if remaining > 0:
		return {
			"ok": false,
			"blocked": true,
			"message": RegionBossRespawnServiceClass.blocked_message(definition.boss_id, remaining),
			"boss_id": definition.boss_id,
			"remaining": remaining,
		}
	ContractServiceClass.ensure_board(session.contract_board, session.player)
	session.current_location_id = region_id
	var message := "Podjęto wyzwanie: %s." % definition.display_name
	session.last_activity = message
	session.log_event(message)
	return {
		"ok": true,
		"message": message,
		"boss_id": definition.boss_id,
		"region_id": definition.region_id,
		"weather_code": session.weather_code,
		"battle_title": definition.challenge_title,
		"recommended_level": definition.recommended_level,
		"level_warning": definition.level_warning(session.player.level),
		"engine_script": definition.engine_script,
	}


static func resolve_victory(session, enemy, rng: RandomNumberGenerator) -> Dictionary:
	var definition = RegionBossCatalogClass.get_definition(enemy.enemy_id if enemy != null else "")
	if definition == null:
		return {"ok": false, "message": "Nieznany boss regionalny."}
	var summary := (
		AdventureServiceClass
		. resolve_victory(
			session,
			enemy,
			rng,
			{
				"use_weather": true,
				"contract_region_id": definition.region_id,
				"include_rare_books": true,
				"include_class_loot": true,
			},
		)
	)
	var victory_activity: String = session.last_activity
	var milestone := GuildMilestoneServiceClass.record(session, "boss:%s" % definition.boss_id)
	summary["ok"] = true
	summary["guild_milestone"] = milestone
	session.last_activity = victory_activity
	if bool(milestone.get("awarded", false)):
		session.last_activity += " " + str(milestone.message)
	return summary


static func finish_attempt(
	session, boss_id: String, result: String, rng: RandomNumberGenerator = null
) -> Dictionary:
	var definition = RegionBossCatalogClass.get_definition(boss_id)
	if session == null or definition == null:
		return {"ok": false, "message": "Nie można zakończyć nieznanego wyzwania."}
	if result not in ["victory", "defeat", "fled"]:
		return {"ok": false, "message": "Nieznany wynik wyzwania bossa regionu."}
	session.camp_rest_available = true
	session.advance_hours(1, rng)
	var summary := {
		"ok": true,
		"boss_id": boss_id,
		"result": result,
		"weather_changes": session.last_weather_changes.duplicate(true),
		"boss_respawn": {"started": false},
	}
	# Terminal v0.24.7 uruchamia i loguje odrodzenie dopiero po koszcie czasu próby.
	if result == "victory":
		summary["boss_respawn"] = RegionBossRespawnServiceClass.start_after_victory(
			session, boss_id
		)
	return summary
