class_name CombatPresentationCatalog
extends RefCounted

const SURFACE_CONTEXTS := ["expedition", "region_boss"]
const DEFAULT_HERO_GENDER_CODE := "female"
const DungeonPresentationCatalogClass := preload(
	"res://ui/presentation/dungeon_presentation_catalog.gd"
)
const RegionCatalogClass := preload("res://core/world/region_catalog.gd")
const RegionBossCatalogClass := preload("res://core/world/region_boss_catalog.gd")
const DungeonCatalogClass := preload("res://core/dungeons/dungeon_catalog.gd")
const BATTLEFIELD_TEXTURES := {
	"twilight_plains":
	{
		"day": preload("res://assets/combat/backgrounds/twilight_plains_day.png"),
		"night": preload("res://assets/combat/backgrounds/twilight_plains_night.png"),
	},
	"black_forest":
	{
		"day": preload("res://assets/combat/backgrounds/black_forest_day.png"),
		"night": preload("res://assets/combat/backgrounds/black_forest_night.png"),
	},
	"silentwater_marshes":
	{
		"day": preload("res://assets/combat/backgrounds/silentwater_marshes_day.png"),
		"night": preload("res://assets/combat/backgrounds/silentwater_marshes_night.png"),
	},
	"ashen_borderlands":
	{
		"day": preload("res://assets/combat/backgrounds/ashen_borderlands_day.png"),
		"night": preload("res://assets/combat/backgrounds/ashen_borderlands_night.png"),
	},
	"ice_coast":
	{
		"day": preload("res://assets/combat/backgrounds/ice_coast_day.png"),
		"night": preload("res://assets/combat/backgrounds/ice_coast_night.png"),
	},
}
const REGION_ONE_ENEMY_IDS := [
	"wild_dog",
	"slime",
	"wolf",
	"boar",
	"bandit",
	"cursed_scarecrow",
	"plains_spirit",
	"night_guard",
	"hunter",
	"nature_guardian",
]
const REGION_TWO_ENEMY_IDS := [
	"venom_spider",
	"forest_cultist",
	"rotting_knight",
	"corrupted_bear",
	"black_hart",
	"gallows_wraith",
	"blackwood_executioner",
]
const REGION_THREE_ENEMY_IDS := [
	"bog_crawler",
	"drowned_dead",
	"swamp_witch",
	"bone_crocodile",
	"mist_walker",
	"sunken_knight",
	"drowned_mother",
]
const REGION_FOUR_ENEMY_IDS := [
	"sand_golem",
	"desert_harpy",
	"desert_wanderer",
	"boneburner",
	"red_salamander",
	"hearth_devourer",
	"azhar",
]
const REGION_FIVE_ENEMY_IDS := [
	"frozen_castaway",
	"black_sea_siren",
	"ghost_ship_captain",
	"ice_bear",
	"snow_griffin",
	"ice_crab",
	"leviathan_north",
]
const REGION_ENEMY_IDS := {
	"twilight_plains": REGION_ONE_ENEMY_IDS,
	"black_forest": REGION_TWO_ENEMY_IDS,
	"silentwater_marshes": REGION_THREE_ENEMY_IDS,
	"ashen_borderlands": REGION_FOUR_ENEMY_IDS,
	"ice_coast": REGION_FIVE_ENEMY_IDS,
}
const ENEMY_PRESENTATIONS := {
	"wild_dog":
	{
		"texture": preload("res://assets/combat/enemies/wild_dog.png"),
		"frame": Rect2(0.19, 0.49, 0.62, 0.47),
	},
	"slime":
	{
		"texture": preload("res://assets/combat/enemies/slime.png"),
		"frame": Rect2(0.19, 0.58, 0.62, 0.38),
	},
	"wolf":
	{
		"texture": preload("res://assets/combat/enemies/wolf.png"),
		"frame": Rect2(0.1, 0.35, 0.8, 0.61),
	},
	"boar":
	{
		"texture": preload("res://assets/combat/enemies/boar.png"),
		"frame": Rect2(0.08, 0.35, 0.84, 0.61),
	},
	"bandit":
	{
		"texture": preload("res://assets/combat/enemies/bandit.png"),
		"crop": Rect2(8, 53, 1046, 1339),
		"frame": Rect2(0.1, 0.01, 0.8, 0.95),
	},
	"cursed_scarecrow":
	{
		"texture": preload("res://assets/combat/enemies/cursed_scarecrow.png"),
		"frame": Rect2(0.05, 0.0, 0.9, 0.96),
	},
	"plains_spirit":
	{
		"texture": preload("res://assets/combat/enemies/plains_spirit.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"night_guard":
	{
		"texture": preload("res://assets/combat/enemies/night_guard.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"hunter":
	{
		"texture": preload("res://assets/combat/enemies/hunter.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"nature_guardian":
	{
		"texture": preload("res://assets/combat/enemies/nature_guardian.png"),
		"frame": Rect2(0.02, 0.0, 0.96, 0.96),
	},
	"venom_spider":
	{
		"texture": preload("res://assets/combat/enemies/venom_spider.png"),
		"frame": Rect2(0.02, 0.08, 0.96, 0.88),
	},
	"forest_cultist":
	{
		"texture": preload("res://assets/combat/enemies/forest_cultist.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"rotting_knight":
	{
		"texture": preload("res://assets/combat/enemies/rotting_knight.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"corrupted_bear":
	{
		"texture": preload("res://assets/combat/enemies/corrupted_bear.png"),
		"frame": Rect2(0.03, 0.07, 0.94, 0.89),
	},
	"black_hart":
	{
		"texture": preload("res://assets/combat/enemies/black_hart.png"),
		"frame": Rect2(0.05, 0.0, 0.9, 0.96),
	},
	"gallows_wraith":
	{
		"texture": preload("res://assets/combat/enemies/gallows_wraith.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"blackwood_executioner":
	{
		"texture": preload("res://assets/combat/enemies/blackwood_executioner.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"bog_crawler":
	{
		"texture": preload("res://assets/combat/enemies/bog_crawler.png"),
		"frame": Rect2(0.02, 0.2, 0.96, 0.76),
	},
	"drowned_dead":
	{
		"texture": preload("res://assets/combat/enemies/drowned_dead.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"swamp_witch":
	{
		"texture": preload("res://assets/combat/enemies/swamp_witch.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"bone_crocodile":
	{
		"texture": preload("res://assets/combat/enemies/bone_crocodile.png"),
		"frame": Rect2(0.02, 0.18, 0.96, 0.78),
	},
	"mist_walker":
	{
		"texture": preload("res://assets/combat/enemies/mist_walker.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"sunken_knight":
	{
		"texture": preload("res://assets/combat/enemies/sunken_knight_anime.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"drowned_acolyte":
	{
		"texture": preload("res://assets/combat/enemies/drowned_acolyte.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"drowned_priestess":
	{
		"texture": preload("res://assets/combat/enemies/drowned_priestess.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.96),
		"flip_h": true,
	},
	"iron_gate_guardian":
	{
		"texture": preload("res://assets/combat/enemies/iron_gate_guardian.png"),
		"frame": Rect2(0.02, 0.0, 0.96, 0.96),
	},
	"crypt_warden":
	{
		"texture": preload("res://assets/combat/enemies/crypt_warden.png"),
		"frame": Rect2(0.03, 0.0, 0.94, 0.96),
	},
	"order_grandmaster":
	{
		"texture": preload("res://assets/combat/enemies/order_grandmaster.png"),
		"frame": Rect2(0.03, 0.0, 0.94, 0.96),
		"flip_h": true,
	},
	"drowned_mother":
	{
		"texture": preload("res://assets/combat/enemies/drowned_mother.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"sand_golem":
	{
		"texture": preload("res://assets/combat/enemies/sand_golem.png"),
		"frame": Rect2(0.05, 0.0, 0.9, 0.96),
	},
	"desert_harpy":
	{
		"texture": preload("res://assets/combat/enemies/desert_harpy.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.96),
	},
	"desert_wanderer":
	{
		"texture": preload("res://assets/combat/enemies/desert_wanderer.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"boneburner":
	{
		"texture": preload("res://assets/combat/enemies/boneburner.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"red_salamander":
	{
		"texture": preload("res://assets/combat/enemies/red_salamander.png"),
		"frame": Rect2(0.02, 0.13, 0.96, 0.83),
	},
	"hearth_devourer":
	{
		"texture": preload("res://assets/combat/enemies/hearth_devourer.png"),
		"frame": Rect2(0.05, 0.0, 0.9, 0.96),
	},
	"azhar":
	{
		"texture": preload("res://assets/combat/enemies/azhar.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.96),
	},
	"frozen_castaway":
	{
		"texture": preload("res://assets/combat/enemies/frozen_castaway.png"),
		"frame": Rect2(0.1, 0.0, 0.8, 0.96),
	},
	"black_sea_siren":
	{
		"texture": preload("res://assets/combat/enemies/black_sea_siren.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"ghost_ship_captain":
	{
		"texture": preload("res://assets/combat/enemies/ghost_ship_captain.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.96),
	},
	"ice_bear":
	{
		"texture": preload("res://assets/combat/enemies/ice_bear.png"),
		"frame": Rect2(0.03, 0.12, 0.94, 0.84),
	},
	"snow_griffin":
	{
		"texture": preload("res://assets/combat/enemies/snow_griffin.png"),
		"frame": Rect2(0.02, 0.0, 0.96, 0.96),
	},
	"ice_crab":
	{
		"texture": preload("res://assets/combat/enemies/ice_crab.png"),
		"frame": Rect2(0.12, 0.4, 0.76, 0.56),
	},
	"leviathan_north":
	{
		"texture": preload("res://assets/combat/enemies/leviathan_north.png"),
		"frame": Rect2(0.01, -0.02, 0.98, 0.98),
	},
}
const HERO_PRESENTATIONS := {
	"none_female":
	{
		"texture": preload("res://assets/combat/heroes/seeker_female.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.97),
	},
	"none_male":
	{
		"texture": preload("res://assets/combat/heroes/seeker_male.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.97),
	},
	"warrior_male":
	{
		"texture": preload("res://assets/combat/heroes/warrior.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.97),
	},
	"warrior_female":
	{
		"texture": preload("res://assets/combat/heroes/warrior_female.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.97),
	},
	"hunter_male":
	{
		"texture": preload("res://assets/combat/heroes/hunter_male.png"),
		"frame": Rect2(0.02, 0.0, 0.96, 0.97),
	},
	"hunter_female":
	{
		"texture": preload("res://assets/combat/heroes/hunter_female.png"),
		"frame": Rect2(0.02, 0.0, 0.96, 0.97),
	},
	"mage_male":
	{
		"texture": preload("res://assets/combat/heroes/mage_male.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.97),
	},
	"mage_female":
	{
		"texture": preload("res://assets/combat/heroes/mage_female.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.97),
	},
	"pierrot_female":
	{
		"texture": preload("res://assets/combat/heroes/pierrot.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	},
	"pierrot_male":
	{
		"texture": preload("res://assets/combat/heroes/pierrot_male.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	}
}
const HERO_PATH_PRESENTATIONS := {
	"warrior_heavy_knight_male":
	{
		"texture": preload("res://assets/combat/heroes/warrior_heavy_knight.png"),
		"frame": Rect2(0.06, 0.0, 0.88, 0.97),
	}
}


static func battlefield_texture(
	region_id: String, period_code: String, context: String, dungeon_id := "", room_id := ""
) -> Texture2D:
	if context == "dungeon":
		return DungeonPresentationCatalogClass.background_texture(dungeon_id, room_id)
	if context not in SURFACE_CONTEXTS:
		return null
	var region_textures: Dictionary = BATTLEFIELD_TEXTURES.get(region_id, {})
	return region_textures.get(period_code) as Texture2D


static func enemy_region_id(enemy_id: String, fallback_region_id: String) -> String:
	for region_id: String in REGION_ENEMY_IDS:
		if enemy_id in REGION_ENEMY_IDS[region_id]:
			return region_id
	return fallback_region_id


static func enemy_texture(enemy_id: String) -> Texture2D:
	return enemy_presentation(enemy_id).get("texture") as Texture2D


static func hero_texture(class_code: String, gender_code := "unspecified") -> Texture2D:
	return hero_presentation(class_code, gender_code).get("texture") as Texture2D


static func hero_texture_for_player(player) -> Texture2D:
	return hero_presentation_for_player(player).get("texture") as Texture2D


static func enemy_presentation(enemy_id: String) -> Dictionary:
	return ENEMY_PRESENTATIONS.get(enemy_id, {}).duplicate()


static func hero_presentation(class_code: String, gender_code := "unspecified") -> Dictionary:
	var resolved_gender_code: String = gender_code
	if resolved_gender_code not in ["female", "male"]:
		resolved_gender_code = DEFAULT_HERO_GENDER_CODE
	return HERO_PRESENTATIONS.get("%s_%s" % [class_code, resolved_gender_code], {}).duplicate()


static func hero_presentation_for_player(player) -> Dictionary:
	if player == null:
		return {}
	if (
		player.character_class_code == "warrior"
		and int(player.talent_ranks.get("heavy_knight_core", 0)) > 0
	):
		var path_key := "warrior_heavy_knight_%s" % player.gender_code
		return HERO_PATH_PRESENTATIONS.get(path_key, {}).duplicate()
	return hero_presentation(player.character_class_code, player.gender_code)


static func missing_region_one_enemy_assets() -> Array[String]:
	return missing_enemy_assets_for_region("twilight_plains")


static func missing_enemy_assets_for_dungeon(dungeon_id: String) -> Array[String]:
	var missing: Array[String] = []
	var dungeon = DungeonCatalogClass.get_definition(dungeon_id)
	if dungeon == null:
		return missing
	var pools: Array = [
		dungeon.room_one_enemies,
		dungeon.room_two_enemies,
		dungeon.room_three_enemies,
		[
			dungeon.iron_path_enemy,
			dungeon.flooded_ambush_enemy,
			dungeon.mandatory_elite_enemy,
			dungeon.boss_enemy
		],
	]
	for pool: Array in pools:
		for enemy_id: String in pool:
			if enemy_texture(enemy_id) == null and enemy_id not in missing:
				missing.append(enemy_id)
	return missing


static func missing_enemy_assets_for_region(region_id: String) -> Array[String]:
	var missing: Array[String] = []
	# Audit the gameplay source as well: an omitted region mapping must not
	# silently report success (the original cause of the missing region 5 art).
	var enemy_ids: Array = REGION_ENEMY_IDS.get(region_id, []).duplicate()
	var region := RegionCatalogClass.get_definition(region_id)
	if region != null:
		for period: String in ["day", "night"]:
			for enemy_id: String in region.encounters_for(period):
				if enemy_id not in enemy_ids:
					enemy_ids.append(enemy_id)
	var boss := RegionBossCatalogClass.boss_for_region(region_id)
	if boss != null and boss.boss_id not in enemy_ids:
		enemy_ids.append(boss.boss_id)
	for enemy_id: String in enemy_ids:
		if enemy_texture(enemy_id) == null:
			missing.append(enemy_id)
	return missing
