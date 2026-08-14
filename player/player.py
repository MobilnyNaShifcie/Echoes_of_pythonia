from dataclasses import dataclass, field

from game.config import (
    ATTRIBUTE_POINTS_PER_LEVEL,
    BASIC_PASSIVE_LEVEL,
    MAX_PASSIVE_LEVEL,
    CLASS_UNLOCK_LEVEL,
    STARTING_ATTRIBUTE_POINTS,
    STARTING_LEVEL,
)
from items.catalog import get_item_definition
from items.models import EquipmentItem, EquipmentSlot
from player.achievements import AchievementBook
from player.attributes import Attributes, AttributeType, calculate_attribute_bonuses
from player.classes import PlayerClass
from player.equipment import Equipment
from player.inventory import Inventory
from player.passives import Passives, PassiveType, available_passive_points, passive_attack_bonus
from player.stats import PrimaryStats


@dataclass
class Player:
    name: str
    level: int = STARTING_LEVEL
    experience: int = 0
    gold: int = 0
    rubies: int = 0
    unspent_attribute_points: int = STARTING_ATTRIBUTE_POINTS
    character_class: PlayerClass = PlayerClass.NONE
    stats: PrimaryStats = field(default_factory=PrimaryStats)
    attributes: Attributes = field(default_factory=Attributes)
    passives: Passives = field(default_factory=Passives)
    passive_masteries: set[str] = field(default_factory=set)
    passive_specializations: dict[str, str] = field(default_factory=dict)
    talents: dict[str, int] = field(default_factory=dict)
    unlocked_class_paths: set[str] = field(default_factory=set)
    discovered_hunter_combos: set[str] = field(default_factory=set)
    achievements: AchievementBook = field(default_factory=AchievementBook)
    carry_upgrade_level: int = 0
    inventory: Inventory = field(default_factory=Inventory)
    equipment: Equipment = field(default_factory=Equipment)

    @property
    def display_name(self) -> str:
        return f"[{self.achievements.equipped_title}] {self.name}"

    @property
    def can_choose_class(self) -> bool:
        return (
            self.level >= CLASS_UNLOCK_LEVEL
            and self.character_class is PlayerClass.NONE
        )

    @property
    def available_passive_points(self) -> int:
        return available_passive_points(self.level, self.passives)

    def experience_to_next_level(self) -> int:
        next_level = self.level + 1
        return int(50 * (next_level ** 1.5))

    def experience_remaining_to_next_level(self) -> int:
        return self.experience_to_next_level() - self.experience

    def gain_experience(self, amount: int) -> int:
        if amount < 0:
            raise ValueError("Ilość doświadczenia nie może być ujemna.")
        self.experience += amount
        levels_gained = 0
        while self.experience >= self.experience_to_next_level():
            required = self.experience_to_next_level()
            self.experience -= required
            self.level += 1
            self.unspent_attribute_points += ATTRIBUTE_POINTS_PER_LEVEL
            levels_gained += 1
        return levels_gained

    def add_gold(self, amount: int) -> None:
        if amount < 0:
            raise ValueError("Nie można dodać ujemnej ilości golda.")
        self.gold += amount

    def choose_class(self, player_class: PlayerClass) -> None:
        if player_class is PlayerClass.NONE:
            raise ValueError("Nie można wybrać klasy Poszukiwacz.")

        if self.character_class is not PlayerClass.NONE:
            raise ValueError(
                f"Twoja droga została już wybrana: "
                f"{self.character_class.display_name}."
            )

        if self.level < CLASS_UNLOCK_LEVEL:
            raise ValueError(
                f"Klasę można wybrać od poziomu {CLASS_UNLOCK_LEVEL}."
            )

        self.character_class = player_class
        starter_items = {
            PlayerClass.WARRIOR: ("training_shield",),
            PlayerClass.HUNTER: ("hunting_bow", "simple_quiver"),
            PlayerClass.MAGE: ("apprentice_staff", "mana_crystal_artifact"),
            PlayerClass.PIERROT: ("caprice_lance", "worn_fate_dice"),
        }
        granted_ids: list[str] = []
        for item_id in starter_items.get(player_class, ()):
            if self.inventory.count(item_id) == 0:
                self.inventory.add(item_id)
                granted_ids.append(item_id)

        # Nowa Droga od razu dostaje własną broń i przedmiot dodatkowy.
        # Zastąpiony sprzęt wraca do plecaka, więc nic nie przepada.
        for item_id in granted_ids:
            for index, item in enumerate(self.inventory.equipment_items):
                if item.item_id != item_id:
                    continue
                previous = self.equipment.equip_and_return_previous(
                    self.inventory.pop_equipment(index)
                )
                if previous is not None:
                    self.inventory.add_equipment_instance(previous)
                break
        self.recalculate_stats()
        self.stats.current_mana = self.stats.max_mana

    def spend_attribute_points(
        self,
        attribute: AttributeType,
        amount: int = 1,
    ) -> None:
        if amount <= 0:
            raise ValueError("Liczba punktów musi być większa od zera.")

        if amount > self.unspent_attribute_points:
            raise ValueError(
                f"Brak tylu wolnych punktów atrybutów. "
                f"Dostępne: {self.unspent_attribute_points}."
            )
        if attribute is AttributeType.LUCK and self.character_class is not PlayerClass.PIERROT:
            raise ValueError("Atrybut Szczęście jest dostępny wyłącznie dla Pierrota.")

        self.attributes.increase(attribute, amount)
        self.unspent_attribute_points -= amount
        self.recalculate_stats()

    def spend_attribute_point(self, attribute: AttributeType) -> None:
        self.spend_attribute_points(attribute, 1)

    def passive_level_cap(self, passive: PassiveType) -> int:
        return (
            MAX_PASSIVE_LEVEL
            if passive.code in self.passive_masteries
            else BASIC_PASSIVE_LEVEL
        )

    def spend_passive_points(
        self,
        passive: PassiveType,
        amount: int = 1,
    ) -> None:
        if amount <= 0:
            raise ValueError("Liczba punktów musi być większa od zera.")

        available = self.available_passive_points

        if amount > available:
            raise ValueError(
                f"Brak tylu wolnych punktów umiejętności pasywnych. "
                f"Dostępne: {available}."
            )

        self.passives.increase(
            passive,
            amount,
            max_level=self.passive_level_cap(passive),
        )
        self.recalculate_stats()

    def spend_passive_point(self, passive: PassiveType) -> None:
        self.spend_passive_points(passive, 1)

    def recalculate_stats(self) -> None:
        equipment = self.equipment.total_bonuses(self.character_class.code)
        attributes = calculate_attribute_bonuses(self.attributes)
        self.stats.apply_derived_stats(
            attack=(
                equipment.attack
                + attributes.attack
                + passive_attack_bonus(self.passives)
                + (5 if self.passive_specializations.get("increased_attack") == "raw_strength" else 0)
            ),
            defense=equipment.defense + attributes.defense,
            bonus_hp=equipment.max_hp + attributes.max_hp,
            dodge=equipment.dodge + attributes.dodge,
            max_mana=(
                equipment.max_mana
                + attributes.max_mana
                + self.character_class.base_mana
            ),
            resistances=equipment.resistances,
            health_regen=equipment.health_regen,
            crit_chance=equipment.crit_chance,
            crit_damage=equipment.crit_damage,
            skill_damage=equipment.skill_damage,
            armor_penetration=equipment.armor_penetration,
            damage_vs_elite=equipment.damage_vs_elite,
            damage_vs_boss=equipment.damage_vs_boss,
            average_damage=equipment.average_damage,
            magic_power=equipment.magic_power,
        )

    def equip_from_inventory(self, index: int) -> EquipmentItem:
        if index < 0 or index >= len(self.inventory.equipment_items):
            raise IndexError("Nieprawidłowy indeks wyposażenia.")

        candidate = self.inventory.equipment_items[index]
        definition = get_item_definition(candidate.item_id)
        if definition.required_class_code is not None and definition.required_class_code != self.character_class.code:
            raise ValueError(f"Ten przedmiot wymaga klasy: {definition.required_class_name}.")
        if self.level < definition.required_level:
            raise ValueError(
                f"Wymagany poziom: {definition.required_level}. "
                f"Twój poziom: {self.level}."
            )

        item = self.inventory.pop_equipment(index)
        try:
            previous = self.equipment.equip_and_return_previous(item)
        except Exception:
            self.inventory.add_equipment_instance(item)
            raise
        if previous is not None:
            self.inventory.add_equipment_instance(previous)
        self.recalculate_stats()
        return item

    def unequip_to_inventory(self, slot: EquipmentSlot) -> EquipmentItem | None:
        item = self.equipment.unequip(slot)
        if item is None:
            return None
        self.inventory.add_equipment_instance(item)
        self.recalculate_stats()
        return item
