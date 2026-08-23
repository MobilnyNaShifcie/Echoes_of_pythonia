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
const ENEMY_TEXTURES := {
	"wolf": preload("res://assets/combat/enemies/wolf.png"),
}
const HERO_TEXTURES := {}


static func battlefield_texture(
	region_id: String, period_code: String, context: String
) -> Texture2D:
	if context not in SURFACE_CONTEXTS:
		return null
	var region_textures: Dictionary = BATTLEFIELD_TEXTURES.get(region_id, {})
	return region_textures.get(period_code) as Texture2D


static func enemy_texture(enemy_id: String) -> Texture2D:
	return ENEMY_TEXTURES.get(enemy_id) as Texture2D


static func hero_texture(class_code: String) -> Texture2D:
	return HERO_TEXTURES.get(class_code) as Texture2D
