from dataclasses import dataclass, field

from combat.elements import ElementalResistances
from game.config import STARTING_HP


@dataclass
class PrimaryStats:
    max_hp: int = STARTING_HP
    current_hp: int = STARTING_HP
    attack: int = 0
    defense: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    magic_power: int = 0
    current_mana: int = 0
    health_regen: int = 0
    crit_chance: float = 0.0
    crit_damage: float = 0.0
    skill_damage: float = 0.0
    armor_penetration: float = 0.0
    damage_vs_elite: float = 0.0
    damage_vs_boss: float = 0.0
    average_damage: float = 0.0
    resistances: ElementalResistances = field(default_factory=ElementalResistances)

    @property
    def is_alive(self) -> bool:
        return self.current_hp > 0

    @property
    def needs_restoration(self) -> bool:
        return self.current_hp < self.max_hp or self.current_mana < self.max_mana

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

    def spend_mana(self, amount: int) -> None:
        if amount < 0:
            raise ValueError("Koszt Many nie może być ujemny.")
        if amount > self.current_mana:
            raise ValueError(
                f"Brak Many. Potrzeba {amount}, masz {self.current_mana}."
            )
        self.current_mana -= amount

    def restore_mana(self, amount: int) -> int:
        if amount < 0:
            raise ValueError("Przywracana Mana nie może być ujemna.")
        restored = min(amount, self.max_mana - self.current_mana)
        self.current_mana += restored
        return restored

    def restore_full(self) -> None:
        self.current_hp = self.max_hp
        self.current_mana = self.max_mana

    def apply_derived_stats(
        self,
        attack: int,
        defense: int,
        bonus_hp: int,
        dodge: float,
        max_mana: int,
        resistances: ElementalResistances | None = None,
        *,
        health_regen: int = 0,
        crit_chance: float = 0.0,
        crit_damage: float = 0.0,
        skill_damage: float = 0.0,
        armor_penetration: float = 0.0,
        damage_vs_elite: float = 0.0,
        damage_vs_boss: float = 0.0,
        average_damage: float = 0.0,
        magic_power: int = 0,
    ) -> None:
        numeric = (
            attack,
            defense,
            bonus_hp,
            dodge,
            max_mana,
            magic_power,
            health_regen,
            crit_chance,
            crit_damage,
            skill_damage,
            armor_penetration,
            damage_vs_elite,
            damage_vs_boss,
        )
        if any(value < 0 for value in numeric):
            raise ValueError("Statystyki pochodne nie mogą być ujemne.")
        if not -100.0 < average_damage < 100.0:
            raise ValueError(
                "Średnie Obrażenia muszą mieścić się między -99% a +99%."
            )

        self.attack = attack
        self.defense = defense
        self.max_hp = STARTING_HP + bonus_hp
        self.dodge = dodge
        self.max_mana = max_mana
        self.magic_power = magic_power
        self.health_regen = health_regen
        self.crit_chance = crit_chance
        self.crit_damage = crit_damage
        self.skill_damage = skill_damage
        self.armor_penetration = armor_penetration
        self.damage_vs_elite = damage_vs_elite
        self.damage_vs_boss = damage_vs_boss
        self.average_damage = average_damage
        self.resistances = (resistances or ElementalResistances()).clamped()
        self.current_hp = min(self.current_hp, self.max_hp)
        self.current_mana = min(self.current_mana, self.max_mana)
