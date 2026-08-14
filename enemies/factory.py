from combat.elements import ElementalResistances, damage_type_from_code
from data.enemies import ENEMY_DATA
from enemies.enemy import Enemy


def create_enemy(enemy_id: str) -> Enemy:
    if enemy_id not in ENEMY_DATA:
        raise KeyError(f"Nieznany przeciwnik: {enemy_id}")

    data = ENEMY_DATA[enemy_id]
    max_hp = int(data["max_hp"])
    special_type = data.get("special_damage_type")

    return Enemy(
        enemy_id=enemy_id,
        name=str(data["name"]),
        max_hp=max_hp,
        current_hp=max_hp,
        attack=int(data["attack"]),
        defense=int(data["defense"]),
        dodge=float(data["dodge"]),
        experience_reward=int(data["experience_reward"]),
        gold_min=int(data["gold_min"]),
        gold_max=int(data["gold_max"]),
        rank=str(data.get("rank", "normal")),
        grammatical_gender=str(data.get("grammatical_gender", "masculine")),
        special_name=(None if data.get("special_name") is None else str(data["special_name"])),
        special_chance=float(data.get("special_chance", 0.0)),
        special_attack_bonus=int(data.get("special_attack_bonus", 0)),
        basic_damage_type=damage_type_from_code(str(data.get("basic_damage_type", "physical"))),
        special_damage_type=(None if special_type is None else damage_type_from_code(str(special_type))),
        extra_attack_chance=float(data.get("extra_attack_chance", 0.0)),
        first_attack_bonus=int(data.get("first_attack_bonus", 0)),
        physical_damage_reduction=int(data.get("physical_damage_reduction", 0)),
        status_resistance=float(data.get("status_resistance", 0.0)),
        elemental_resistances=ElementalResistances(
            fire=int(data.get("fire_resistance", 0)),
            wind=int(data.get("wind_resistance", 0)),
            frost=int(data.get("frost_resistance", 0)),
            earth=int(data.get("earth_resistance", 0)),
            water=int(data.get("water_resistance", 0)),
        ).clamped(),
    )
