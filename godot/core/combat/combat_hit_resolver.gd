class_name CombatHitResolver
extends RefCounted

const MathClass := preload("res://core/math/legacy_math.gd")
const PassiveProgressionServiceClass := preload(
	"res://core/progression/passive_progression_service.gd"
)

var player
var enemy
var effects
var rng: RandomNumberGenerator


func _init(player_profile, combat_enemy, combat_effects, random_number_generator) -> void:
	player = player_profile
	enemy = combat_enemy
	effects = combat_effects
	rng = random_number_generator


func resolve(
	power: int,
	multiplier: float,
	guaranteed_hit: bool,
	magical: bool,
	damage_type: String,
	armor_penetration := 0.0,
	bonus_critical_chance := 0.0,
	is_skill := false,
) -> Dictionary:
	if not guaranteed_hit and rng.randf() < enemy.dodge / 100.0:
		return {"damage": 0, "dodged": true, "critical": false}
	var effective_multiplier := multiplier
	if is_skill and player.stats.skill_damage > 0.0:
		effective_multiplier *= 1.0 + player.stats.skill_damage / 100.0
	var attack_value := maxi(1, MathClass.python_roundi(power * effective_multiplier))
	var enemy_defense: int = effects.effective_enemy_defense(enemy.defense)
	var penetration := clampf(player.stats.armor_penetration + armor_penetration, 0.0, 90.0)
	if penetration > 0.0:
		enemy_defense = maxi(
			0, MathClass.python_roundi(enemy_defense * (1.0 - penetration / 100.0))
		)
	if magical:
		enemy_defense = int(enemy_defense / 2.0)
	var damage := maxi(1, attack_value - enemy_defense)
	if damage_type != "physical":
		damage = enemy.elemental_resistances.reduce_damage(damage, damage_type)
	elif not magical:
		damage = enemy.reduce_physical_damage(damage)
	var situational_bonus := 0.0
	if enemy.rank == "elite":
		situational_bonus += player.stats.damage_vs_elite
	if enemy.rank in ["miniboss", "boss"]:
		situational_bonus += player.stats.damage_vs_boss
	if situational_bonus > 0.0:
		damage = maxi(1, MathClass.python_roundi(damage * (1.0 + situational_bonus / 100.0)))
	var critical := false
	var critical_chance: float = (
		PassiveProgressionServiceClass.critical_chance(player)
		+ player.stats.crit_chance
		+ bonus_critical_chance
	)
	if PassiveProgressionServiceClass.specialization_for(player, "critical_damage") == "precision":
		critical_chance += 3.0
	if critical_chance > 0.0 and rng.randf() < minf(100.0, critical_chance) / 100.0:
		var critical_multiplier: float = (
			PassiveProgressionServiceClass.critical_multiplier(player)
			+ player.stats.crit_damage / 100.0
		)
		if (
			(
				PassiveProgressionServiceClass.specialization_for(player, "critical_damage")
				== "execution"
			)
			and enemy.current_hp / float(maxi(1, enemy.max_hp)) < 0.30
		):
			critical_multiplier *= 1.20
		damage = maxi(1, MathClass.python_roundi(damage * critical_multiplier))
		critical = true
	return {"damage": enemy.take_damage(damage), "dodged": false, "critical": critical}
