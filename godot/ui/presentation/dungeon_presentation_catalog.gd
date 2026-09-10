class_name DungeonPresentationCatalog
extends RefCounted

## Art follows stable run steps, never localized titles, enemy names or weather.
const CRYPT := "sunken_order_crypt"
const ROOM_PATH := "res://assets/combat/backgrounds/dungeons/sunken_order_crypt/"
const CRYPT_ROOMS := {
	"sunken_vestibule": preload(ROOM_PATH + "sunken_vestibule.png"),
	"seal_corridor": preload(ROOM_PATH + "seal_corridor.png"),
	"drowned_gallery": preload(ROOM_PATH + "drowned_gallery.png"),
	"sunken_chapel": preload(ROOM_PATH + "sunken_chapel.png"),
	"chain_hall": preload(ROOM_PATH + "chain_hall.png"),
	"grandmaster_gate": preload(ROOM_PATH + "grandmaster_gate.png"),
}
const STEP_ROOMS := {
	"entrance": "sunken_vestibule",
	"room_one": "sunken_vestibule",
	"pause_after_room_one": "sunken_vestibule",
	"pause_after_room_two": "seal_corridor",
	"crossroads": "seal_corridor",
	"flooded_chest": "seal_corridor",
	"pause_after_path": "seal_corridor",
	"recovery": "sunken_chapel",
	"pause_after_recovery": "chain_hall",
	"final_gate": "grandmaster_gate",
}
const ENCOUNTER_ROOMS := {
	"pause_after_room_one": "sunken_vestibule",
	"pause_after_room_two": "seal_corridor",
	"pause_after_path": "seal_corridor",
	"recovery": "drowned_gallery",
	"final_gate": "chain_hall",
	"completed": "grandmaster_gate",
}


static func room_for_run(run) -> String:
	if run == null:
		return "sunken_vestibule"
	if run.dungeon_id != CRYPT:
		return ""
	if run.step == "in_combat":
		return str(ENCOUNTER_ROOMS.get(run.pending_next_step, "sunken_vestibule"))
	if run.outcome == "completed":
		return "grandmaster_gate"
	return str(STEP_ROOMS.get(run.step, "sunken_vestibule"))


static func background_texture(dungeon_id: String, room_id := "") -> Texture2D:
	if dungeon_id != CRYPT:
		return null
	return CRYPT_ROOMS.get(room_id, CRYPT_ROOMS.sunken_vestibule) as Texture2D
