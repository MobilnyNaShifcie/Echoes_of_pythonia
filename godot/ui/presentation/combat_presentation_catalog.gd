class_name CombatPresentationCatalog
extends RefCounted

const SURFACE_CONTEXTS := ["expedition", "region_boss"]
const BATTLEFIELD_TEXTURES := {
	"twilight_plains":
	{
		"day": preload("res://assets/combat/backgrounds/twilight_plains_day.png"),
		"night": preload("res://assets/combat/backgrounds/twilight_plains_night.png"),
	}
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
const ENEMY_PRESENTATIONS := {
	"wild_dog":
	{
		"texture": preload("res://assets/combat/enemies/wild_dog.png"),
		"crop": Rect2(23, 272, 1063, 977),
		"frame": Rect2(0.06, 0.12, 0.88, 0.84),
	},
	"slime":
	{
		"texture": preload("res://assets/combat/enemies/slime.png"),
		"crop": Rect2(45, 400, 1035, 813),
		"frame": Rect2(0.1, 0.27, 0.8, 0.69),
	},
	"wolf":
	{
		"texture": preload("res://assets/combat/enemies/wolf.png"),
		"crop": Rect2(21, 49, 1233, 1082),
		"frame": Rect2(0.04, 0.08, 0.92, 0.88),
	},
	"boar":
	{
		"texture": preload("res://assets/combat/enemies/boar.png"),
		"crop": Rect2(0, 40, 1254, 1126),
		"frame": Rect2(0.02, 0.08, 0.96, 0.88),
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
		"frame": Rect2(0.02, -0.01, 0.96, 0.97),
	},
}
const HERO_PRESENTATIONS := {
	"pierrot":
	{
		"texture": preload("res://assets/combat/heroes/pierrot.png"),
		"frame": Rect2(0.08, 0.0, 0.84, 0.96),
	}
}


static func battlefield_texture(
	region_id: String, period_code: String, context: String
) -> Texture2D:
	if context not in SURFACE_CONTEXTS:
		return null
	var region_textures: Dictionary = BATTLEFIELD_TEXTURES.get(region_id, {})
	return region_textures.get(period_code) as Texture2D


static func enemy_texture(enemy_id: String) -> Texture2D:
	return enemy_presentation(enemy_id).get("texture") as Texture2D


static func hero_texture(class_code: String) -> Texture2D:
	return hero_presentation(class_code).get("texture") as Texture2D


static func enemy_presentation(enemy_id: String) -> Dictionary:
	return ENEMY_PRESENTATIONS.get(enemy_id, {}).duplicate()


static func hero_presentation(class_code: String) -> Dictionary:
	return HERO_PRESENTATIONS.get(class_code, {}).duplicate()


static func missing_region_one_enemy_assets() -> Array[String]:
	var missing: Array[String] = []
	for enemy_id: String in REGION_ONE_ENEMY_IDS:
		if not ENEMY_PRESENTATIONS.has(enemy_id):
			missing.append(enemy_id)
	return missing
