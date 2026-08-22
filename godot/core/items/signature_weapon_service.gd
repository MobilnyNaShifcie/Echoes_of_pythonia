class_name SignatureWeaponService
extends RefCounted

const RANGES := {
	"grandmaster_sword": Vector2i(-5, 15),
	"varek_sabre": Vector2i(-8, 22),
}


static func roll_average_damage_percent(item_id: String, rng: RandomNumberGenerator):
	if rng == null or not RANGES.has(item_id):
		return null
	var limits: Vector2i = RANGES[item_id]
	return rng.randi_range(limits.x, limits.y)


static func deterministic_average_damage_percent(item_id: String, instance_id: String):
	if not RANGES.has(item_id):
		return null
	var context := HashingContext.new()
	context.start(HashingContext.HASH_SHA256)
	context.update(
		("EchoesOfPythonia-v0.25-average|%s|%s" % [item_id, instance_id]).to_utf8_buffer()
	)
	var digest := context.finish()
	var seed_value := 0
	for index in 7:
		seed_value = (seed_value << 8) | int(digest[index])
	var rng := RandomNumberGenerator.new()
	rng.seed = seed_value
	return roll_average_damage_percent(item_id, rng)


static func is_valid(item_id: String, value) -> bool:
	if not RANGES.has(item_id):
		return value == null
	if value == null or not value is int:
		return false
	var limits: Vector2i = RANGES[item_id]
	return int(value) >= limits.x and int(value) <= limits.y
