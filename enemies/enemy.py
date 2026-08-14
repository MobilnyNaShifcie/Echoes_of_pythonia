from dataclasses import dataclass
import random

from combat.elements import DamageType, ElementalResistances


@dataclass
class Enemy:
    enemy_id: str
    name: str
    max_hp: int
    current_hp: int
    attack: int
    defense: int
    dodge: float
    experience_reward: int
    gold_min: int
    gold_max: int
    rank: str = "normal"
    grammatical_gender: str = "masculine"
    special_name: str | None = None
    special_chance: float = 0.0
    special_attack_bonus: int = 0
    basic_damage_type: DamageType = DamageType.PHYSICAL
    special_damage_type: DamageType | None = None
    extra_attack_chance: float = 0.0
    first_attack_bonus: int = 0
    physical_damage_reduction: int = 0
    attacks_made: int = 0
    weather_note: str | None = None
    elite_modifier_id: str | None = None
    elite_note: str | None = None
    life_steal_percent: float = 0.0
    status_resistance: float = 0.0
    loot_chance_multiplier: float = 1.0
    elemental_resistances: ElementalResistances = ElementalResistances()

    @property
    def is_alive(self) -> bool:
        return self.current_hp > 0

    @property
    def is_miniboss(self) -> bool:
        return self.rank == "miniboss"

    def take_damage(self, amount: int) -> int:
        if amount < 0:
            raise ValueError("Obrażenia nie mogą być ujemne.")
        damage_taken = min(amount, self.current_hp)
        self.current_hp -= damage_taken
        return damage_taken

    def heal(self, amount: int) -> int:
        if amount < 0:
            raise ValueError("Leczenie nie może być ujemne.")
        healed = min(amount, self.max_hp - self.current_hp)
        self.current_hp += healed
        return healed

    def reduce_physical_damage(self, amount: int) -> int:
        if amount <= 0:
            return 0
        return max(1, amount - self.physical_damage_reduction)

    def roll_gold_reward(self, rng: random.Random) -> int:
        if self.gold_min < 0 or self.gold_max < self.gold_min:
            raise ValueError("Nieprawidłowy zakres nagrody gold.")
        return rng.randint(self.gold_min, self.gold_max)

    def roll_special_attack(self, rng: random.Random) -> bool:
        if self.special_name is None or self.special_chance <= 0:
            return False
        return rng.random() < min(self.special_chance, 1.0)

    def roll_extra_attack(self, rng: random.Random) -> bool:
        if self.extra_attack_chance <= 0:
            return False
        return rng.random() < min(self.extra_attack_chance, 1.0)
