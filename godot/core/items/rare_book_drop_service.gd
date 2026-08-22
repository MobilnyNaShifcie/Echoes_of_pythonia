class_name RareBookDropService
extends RefCounted

const MASTERY_BOOK_IDS := [
	"mastery_regeneration_book",
	"mastery_attack_speed_book",
	"mastery_critical_book",
	"mastery_strength_book",
]
const PATH_BOOK_IDS := [
	"path_heavy_knight_book",
	"path_phantom_archer_book",
	"path_arcana_book",
	"path_fortuna_book",
]
const MASTERY_CHANCES := {
	"crypt_warden": 0.02,
	"black_fleet_first_officer": 0.02,
	"order_grandmaster": 0.04,
	"admiral_varek": 0.04,
}
const PATH_CHANCES := {
	"crypt_warden": 0.01,
	"black_fleet_first_officer": 0.01,
	"order_grandmaster": 0.02,
	"admiral_varek": 0.02,
}


static func roll_for_enemy(enemy_id: String, rng: RandomNumberGenerator) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	var mastery_chance := float(MASTERY_CHANCES.get(enemy_id, 0.0))
	if mastery_chance > 0.0 and rng.randf() < mastery_chance:
		drops.append(
			{
				"item_id": MASTERY_BOOK_IDS[rng.randi_range(0, MASTERY_BOOK_IDS.size() - 1)],
				"quantity": 1
			}
		)
	var path_chance := float(PATH_CHANCES.get(enemy_id, 0.0))
	if path_chance > 0.0 and rng.randf() < path_chance:
		drops.append(
			{"item_id": PATH_BOOK_IDS[rng.randi_range(0, PATH_BOOK_IDS.size() - 1)], "quantity": 1}
		)
	return drops
