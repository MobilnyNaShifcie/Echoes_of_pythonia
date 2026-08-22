class_name CombatDamageRules
extends RefCounted

const MathClass := preload("res://core/math/legacy_math.gd")


static func calculate_damage(attack: int, defense: int) -> int:
	return maxi(1, maxi(0, attack) - maxi(0, defense))


static func apply_armor_penetration(
	defense: int, penetration: float, penetration_cap := 90.0
) -> int:
	var clamped := clampf(penetration, 0.0, penetration_cap)
	return maxi(0, MathClass.python_roundi(maxi(0, defense) * (1.0 - clamped / 100.0)))


static func apply_defend_reduction(damage: int) -> int:
	return int(maxi(0, damage) / 2.0)


static func apply_multiplier(damage: int, multiplier: float) -> int:
	return maxi(1, MathClass.python_roundi(maxi(0, damage) * maxf(0.0, multiplier)))


static func roll_percent(rng: RandomNumberGenerator, chance: float, chance_cap := 100.0) -> bool:
	return rng != null and chance > 0.0 and rng.randf() < clampf(chance, 0.0, chance_cap) / 100.0
