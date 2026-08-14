import random

from combat.elements import DamageType
from data.weather_loot import WEATHER_BOSS_WEAPONS
from enemies.enemy import Enemy
from items.catalog import get_item_definition
from items.loot import LootDrop
from world.weather import WeatherType


def apply_weather_to_enemy(enemy: Enemy, weather: WeatherType) -> None:
    """Nakłada pogodowe modyfikatory na świeżą instancję przeciwnika."""
    if weather is WeatherType.AURORA:
        enemy.max_hp = max(1, int(round(enemy.max_hp * 1.25)))
        enemy.current_hp = enemy.max_hp
        enemy.attack += 2
        enemy.defense += 1
        enemy.dodge = min(95.0, enemy.dodge + 5.0)
        enemy.weather_note = "Wzmocniony przez Zorzę Polarną"
        if enemy.is_miniboss:
            enemy.basic_damage_type = DamageType.FROST
        return

    if not enemy.is_miniboss:
        return

    if weather is WeatherType.STORM:
        enemy.max_hp = max(1, int(round(enemy.max_hp * 1.20)))
        enemy.current_hp = enemy.max_hp
        enemy.attack += 2
        enemy.basic_damage_type = DamageType.WIND
        enemy.weather_note = "Wzmocniony przez Burzę"
    elif weather is WeatherType.FROST:
        enemy.max_hp = max(1, int(round(enemy.max_hp * 1.20)))
        enemy.current_hp = enemy.max_hp
        enemy.defense += 2
        enemy.basic_damage_type = DamageType.FROST
        enemy.weather_note = "Wzmocniony przez Mróz"
    elif weather is WeatherType.WIND:
        enemy.attack += 1
        enemy.dodge = min(95.0, enemy.dodge + 10.0)
        enemy.basic_damage_type = DamageType.WIND
        enemy.weather_note = "Wzmocniony przez Wichurę"


def reward_multiplier(weather: WeatherType) -> float:
    return 1.5 if weather is WeatherType.AURORA else 1.0


def drop_chance_multiplier(weather: WeatherType) -> float:
    return 1.5 if weather is WeatherType.AURORA else 1.0


def roll_weather_boss_weapon(
    enemy: Enemy,
    weather: WeatherType,
    rng: random.Random,
) -> list[LootDrop]:
    if not enemy.is_miniboss or weather is WeatherType.SUNNY:
        return []

    entry = WEATHER_BOSS_WEAPONS.get(enemy.enemy_id, {}).get(weather.code)
    if entry is None:
        return []

    chance = float(entry["chance"])
    item_id = str(entry["item_id"])
    get_item_definition(item_id)

    if rng.random() < chance:
        return [LootDrop(item_id=item_id)]
    return []
