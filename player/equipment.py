from dataclasses import dataclass, field

from combat.elements import ElementalResistances
from items.affixes import calculate_affix_bonuses
from items.catalog import get_item_definition
from items.models import EquipmentItem, EquipmentSlot
from items.sets import get_active_set_bonuses
from items.upgrades import calculate_upgraded_stats


@dataclass(frozen=True)
class EquipmentBonuses:
    attack: int = 0
    defense: int = 0
    max_hp: int = 0
    dodge: float = 0.0
    max_mana: int = 0
    magic_power: int = 0
    health_regen: int = 0
    crit_chance: float = 0.0
    crit_damage: float = 0.0
    skill_damage: float = 0.0
    armor_penetration: float = 0.0
    damage_vs_elite: float = 0.0
    damage_vs_boss: float = 0.0
    average_damage: float = 0.0
    resistances: ElementalResistances = ElementalResistances()
    active_set_names: tuple[str, ...] = ()


@dataclass
class Equipment:
    slots: dict[EquipmentSlot, EquipmentItem] = field(default_factory=dict)

    def equip_and_return_previous(self, item: EquipmentItem) -> EquipmentItem | None:
        definition = get_item_definition(item.item_id)
        if not definition.is_equipment or definition.slot is None:
            raise ValueError("Tego przedmiotu nie można założyć.")
        previous = self.slots.get(definition.slot)
        self.slots[definition.slot] = item
        return previous

    def unequip(self, slot: EquipmentSlot) -> EquipmentItem | None:
        return self.slots.pop(slot, None)

    def get(self, slot: EquipmentSlot) -> EquipmentItem | None:
        return self.slots.get(slot)

    def total_bonuses(self, character_class_code: str | None = None) -> EquipmentBonuses:
        attack = defense = max_hp = max_mana = magic_power = health_regen = 0
        dodge = 0.0
        crit_chance = crit_damage = skill_damage = armor_penetration = 0.0
        damage_vs_elite = damage_vs_boss = 0.0
        average_damage = 0.0
        resistances = ElementalResistances()

        for item in self.slots.values():
            stats = calculate_upgraded_stats(item)
            definition = get_item_definition(item.item_id)
            affixes = calculate_affix_bonuses(item)

            attack += stats.attack + affixes.attack
            defense += stats.defense + affixes.defense
            max_hp += stats.max_hp + affixes.max_hp
            dodge += stats.dodge + affixes.dodge
            max_mana += stats.max_mana + affixes.max_mana
            magic_power += stats.magic_power
            if definition.class_bonus_class_code == character_class_code:
                attack += definition.class_bonus_attack
                defense += definition.class_bonus_defense
                max_hp += definition.class_bonus_max_hp
                max_mana += definition.class_bonus_max_mana
                dodge += definition.class_bonus_dodge
            health_regen += affixes.health_regen
            crit_chance += affixes.crit_chance
            crit_damage += affixes.crit_damage
            skill_damage += affixes.skill_damage
            armor_penetration += affixes.armor_penetration
            damage_vs_elite += affixes.damage_vs_elite
            damage_vs_boss += affixes.damage_vs_boss
            if item.average_damage_percent is not None:
                average_damage += item.average_damage_percent
            resistances = resistances.add(definition.resistances)
            resistances = resistances.add(affixes.resistances)

        active_sets = get_active_set_bonuses(list(self.slots.values()))
        for bonus in active_sets:
            attack += bonus.attack
            defense += bonus.defense
            max_hp += bonus.max_hp
            dodge += bonus.dodge
            max_mana += bonus.max_mana
            resistances = resistances.add(bonus.resistances)

        return EquipmentBonuses(
            attack=attack,
            defense=defense,
            max_hp=max_hp,
            dodge=round(dodge, 1),
            max_mana=max_mana,
            magic_power=magic_power,
            health_regen=health_regen,
            crit_chance=round(crit_chance, 1),
            crit_damage=round(crit_damage, 1),
            skill_damage=round(skill_damage, 1),
            armor_penetration=round(armor_penetration, 1),
            damage_vs_elite=round(damage_vs_elite, 1),
            damage_vs_boss=round(damage_vs_boss, 1),
            average_damage=round(average_damage, 1),
            resistances=resistances,
            active_set_names=tuple(bonus.name for bonus in active_sets),
        )
