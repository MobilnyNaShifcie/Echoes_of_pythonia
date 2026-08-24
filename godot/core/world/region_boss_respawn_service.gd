class_name RegionBossRespawnService
extends RefCounted

const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")

const RESPAWN_EXPEDITIONS := 6


static func remaining(world_encounters, boss_id: String) -> int:
	if world_encounters == null:
		return 0
	return maxi(0, int(world_encounters.region_boss_respawns.get(boss_id, 0)))


static func is_available(world_encounters, boss_id: String) -> bool:
	return remaining(world_encounters, boss_id) == 0


static func start_after_victory(session, boss_id: String) -> Dictionary:
	var boss = RegionBossCatalogClass.get_definition(boss_id)
	if session == null or session.world_encounters == null or boss == null:
		return _failure("Nie można rozpocząć odrodzenia nieznanego bossa regionu.")
	var region = RegionCatalogClass.get_definition(boss.region_id)
	session.world_encounters.region_boss_respawns[boss_id] = RESPAWN_EXPEDITIONS
	var message := (
		"%s został pokonany. Odrodzenie wymaga %s w regionie %s."
		% [
			boss.display_name,
			format_expedition_count(RESPAWN_EXPEDITIONS),
			region.display_name,
		]
	)
	session.log_event(message)
	return {
		"ok": true,
		"boss_id": boss_id,
		"remaining": RESPAWN_EXPEDITIONS,
		"started": true,
		"message": message,
	}


static func record_region_expedition(session, region_id: String) -> Dictionary:
	if session == null or session.world_encounters == null:
		return _failure("Nie można zarejestrować wyprawy bez aktywnego świata.")
	var boss = RegionBossCatalogClass.boss_for_region(region_id)
	if boss == null:
		return {
			"ok": true,
			"boss_id": "",
			"remaining": 0,
			"changed": false,
			"respawned": false,
			"message": "",
		}
	var before := remaining(session.world_encounters, boss.boss_id)
	if before <= 0:
		return {
			"ok": true,
			"boss_id": boss.boss_id,
			"remaining": 0,
			"changed": false,
			"respawned": false,
			"message": "",
		}
	var after := before - 1
	var message := ""
	if after <= 0:
		session.world_encounters.region_boss_respawns.erase(boss.boss_id)
		message = "%s odrodził się i ponownie można rzucić mu wyzwanie." % boss.display_name
		session.log_event(message)
	else:
		session.world_encounters.region_boss_respawns[boss.boss_id] = after
	return {
		"ok": true,
		"boss_id": boss.boss_id,
		"remaining": after,
		"changed": true,
		"respawned": after == 0,
		"message": message,
	}


static func blocked_message(boss_id: String, count: int) -> String:
	var boss = RegionBossCatalogClass.get_definition(boss_id)
	if boss == null:
		return "Nieznany boss regionu."
	var region = RegionCatalogClass.get_definition(boss.region_id)
	return (
		"%s jeszcze się nie odrodził. Wykonaj jeszcze %s w regionie %s."
		% [boss.display_name, format_expedition_count(count), region.display_name]
	)


static func format_expedition_count(value: int) -> String:
	var count := maxi(0, value)
	var last_two := count % 100
	var last := count % 10
	var noun := "wypraw"
	if count == 1:
		noun = "wyprawa"
	elif last >= 2 and last <= 4 and not (last_two >= 12 and last_two <= 14):
		noun = "wyprawy"
	return "%d %s" % [count, noun]


static func _failure(message: String) -> Dictionary:
	return {
		"ok": false,
		"boss_id": "",
		"remaining": 0,
		"changed": false,
		"respawned": false,
		"message": message,
	}
