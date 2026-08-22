class_name ClassLootService
extends RefCounted

const CLASS_GEAR_POOL := [
	"hearthguard_shield",
	"echo_quiver",
	"weave_relic",
	"trickster_card_deck",
]
const CLASS_WEAPON_POOLS := {
	"blackwood": ["blackwood_longbow", "blackwood_staff", "crooked_fate_lance"],
	"marsh": ["mireglass_bow", "mire_staff", "drowned_fate_lance"],
	"ashlands": ["ashwind_bow", "ember_staff", "ashen_fate_lance"],
	"ice_coast": ["black_sea_bow", "black_sea_staff", "black_tide_fate_lance"],
}
const REGION_ENEMIES := {
	"blackwood":
	[
		"venom_spider",
		"forest_cultist",
		"rotting_knight",
		"corrupted_bear",
		"gallows_wraith",
		"black_hart",
		"blackwood_executioner",
	],
	"marsh":
	[
		"bog_crawler",
		"drowned_dead",
		"swamp_witch",
		"bone_crocodile",
		"mist_walker",
		"sunken_knight",
		"drowned_mother",
	],
	"ashlands":
	[
		"sand_golem",
		"desert_harpy",
		"desert_wanderer",
		"boneburner",
		"red_salamander",
		"hearth_devourer",
		"azhar",
	],
	"ice_coast":
	[
		"frozen_castaway",
		"ice_bear",
		"snow_griffin",
		"ice_crab",
		"black_sea_siren",
		"ghost_ship_captain",
		"leviathan_north",
	],
}


static func roll_for_enemy(
	enemy_id: String,
	rank: String,
	elite: bool,
	rng: RandomNumberGenerator,
) -> Array[Dictionary]:
	var drops: Array[Dictionary] = []
	if rng == null:
		return drops
	var region_id := region_for_enemy(enemy_id)
	if not region_id.is_empty() and rng.randf() < weapon_chance(rank, elite):
		var weapon_pool: Array = CLASS_WEAPON_POOLS[region_id]
		(
			drops
			. append(
				{
					"item_id": weapon_pool[rng.randi_range(0, weapon_pool.size() - 1)],
					"quantity": 1,
				}
			)
		)
	if is_late_game_gear_enemy(enemy_id) and rng.randf() < gear_chance(rank, elite):
		(
			drops
			. append(
				{
					"item_id": CLASS_GEAR_POOL[rng.randi_range(0, CLASS_GEAR_POOL.size() - 1)],
					"quantity": 1,
				}
			)
		)
	return drops


static func weapon_chance(rank: String, elite: bool) -> float:
	if rank == "boss":
		return 0.20
	if rank == "miniboss":
		return 0.14
	return 0.10 if elite else 0.04


static func gear_chance(rank: String, elite: bool) -> float:
	if rank == "boss":
		return 0.04
	if rank == "miniboss":
		return 0.03
	return 0.02 if elite else 0.005


static func region_for_enemy(enemy_id: String) -> String:
	for region_id: String in REGION_ENEMIES:
		if enemy_id in REGION_ENEMIES[region_id]:
			return region_id
	return ""


static func is_late_game_gear_enemy(enemy_id: String) -> bool:
	return enemy_id in REGION_ENEMIES.ashlands or enemy_id in REGION_ENEMIES.ice_coast
