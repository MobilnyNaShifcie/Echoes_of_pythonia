from dataclasses import dataclass, field
from enum import Enum, auto
import random

from combat.damage import apply_defend_reduction, calculate_damage
from combat.effects import CombatEffects
from combat.elements import DamageType, apply_elemental_resistance, damage_type_from_code
from combat.fate import FateEngine
from combat.hunter_combo import combo_for_sequence
from enemies.enemy import Enemy
from game.config import BASE_FLEE_CHANCE
from items.class_effects import has_active_class_effect
from items.catalog import get_item_definition
from items.models import EquipmentSlot
from player.passive_specializations import specialization_for
from player.passives import (
    attack_speed_extra_hit_chance,
    critical_chance,
    critical_multiplier,
    health_regeneration_per_turn,
)
from player.player import Player
from player.skills import SkillDefinition, get_skill, skill_is_unlocked
from player.talents import has_talent


class CombatResult(Enum):
    ONGOING = auto()
    VICTORY = auto()
    DEFEAT = auto()
    FLED = auto()


@dataclass
class TurnReport:
    player_damage: int = 0
    extra_player_damage: int = 0
    player_critical: bool = False
    extra_player_critical: bool = False
    player_damage_type: DamageType = DamageType.PHYSICAL
    enemy_damage: int = 0
    enemy_extra_damage: int = 0
    enemy_dodged: bool = False
    extra_enemy_dodged: bool = False
    player_dodged: bool = False
    player_defended: bool = False
    flee_failed: bool = False
    enemy_special_name: str | None = None
    enemy_damage_type: DamageType = DamageType.PHYSICAL
    player_healed: int = 0
    player_restored_mana: int = 0
    player_regenerated: int = 0
    used_item_name: str | None = None
    skill_name: str | None = None
    skill_mana_cost: int = 0
    skill_notes: list[str] = field(default_factory=list)
    enemy_bleed_damage: int = 0
    enemy_healed: int = 0
    boss_notes: list[str] = field(default_factory=list)
    boss_aura_damage: int = 0
    class_effect_notes: list[str] = field(default_factory=list)
    skill_total_damage: int = 0


class CombatEngine:
    def __init__(self, player: Player, enemy: Enemy, rng: random.Random | None = None) -> None:
        self.player = player
        self.enemy = enemy
        self.result = CombatResult.ONGOING
        self.rng = rng or random.Random()
        self.effects = CombatEffects()

        # Wojownik / Ciężki Rycerz
        self._warrior_retribution_ready = False
        self._warrior_retribution_ratio = 0.50
        self._provoke_ready = False
        self._provoke_block_bonus = 0.0

        # Łowca
        self._hunter_instinct_ready = False
        self._hunter_sequence: list[str] = []
        self._hunter_phantom_pending: list[int] = []
        self._hunter_rain_pending: list[int] = []
        self._hunter_explosive_charges = 0

        # Mag
        self._mage_mana_spent = 0
        self._arcane_weave = 0
        self._mage_element_sequence: list[str] = []

        # Pierrot
        self._pierrot_reflect_ready = False
        self._fate_tokens = 0
        self.fate = FateEngine(self.rng, self.player.attributes.luck)

        # Specjalizacje pasywek
        self._momentum_stacks = 0
        self._deadly_tempo_ready = False
        self._second_wind_used = False

    # ------------------------------------------------------------------
    # Public status / actions
    # ------------------------------------------------------------------
    def class_status_lines(self) -> tuple[str, ...]:
        lines: list[str] = []
        if self.player.character_class.code == "mage" and has_talent(self.player, "arcana_core"):
            ready = " [PODWÓJNY SPLOT GOTOWY]" if self.can_double_cast() else ""
            lines.append(f"Splot Magii: {self._arcane_weave}/3{ready}")
        if self.player.character_class.code == "hunter":
            if self._hunter_sequence:
                lines.append("Sekwencja Salwy: " + " → ".join(self._hunter_sequence))
            if self._hunter_explosive_charges:
                lines.append(f"Ładunki Wybuchowe: {self._hunter_explosive_charges}/3")
            if self._hunter_phantom_pending:
                lines.append(f"Widmowe Echa oczekują: {len(self._hunter_phantom_pending)}")
            if self._hunter_rain_pending:
                lines.append(f"Deszcz Strzał oczekuje: {len(self._hunter_rain_pending)}")
        if self.player.character_class.code == "pierrot":
            lines.append(
                f"Kości Losu | Szczęście {self.player.attributes.luck} | "
                f"Żetony Losu: {self._fate_tokens}/{self._fate_token_cap()}"
            )
            if self._pierrot_reflect_ready:
                lines.append("Krzywe Zwierciadło: następny bezpośredni atak zostanie odbity.")
        return tuple(lines)

    def status_lines(self) -> tuple[str, ...]:
        return self.class_status_lines()

    def can_double_cast(self) -> bool:
        return (
            self.player.character_class.code == "mage"
            and has_talent(self.player, "arcana_double_weave")
            and self._arcane_weave >= 3
        )

    def player_attack(self) -> TurnReport:
        self._ensure_ongoing()
        report = TurnReport()
        armor_break_was_active = self.effects.armor_break_active
        pending_echoes, pending_rain = self._take_hunter_delayed_effects()

        power = self.player.stats.attack
        attack_multiplier = 1.0
        bonus_crit_chance = 0.0

        if has_talent(self.player, "warrior_relentless"):
            attack_multiplier *= 1.0 + 0.05 * self.player.talents.get("warrior_relentless", 0)

        if self._warrior_retribution_ready:
            defense_power = max(1, int(round(self.player.stats.defense * self._warrior_retribution_ratio)))
            power += defense_power
            report.class_effect_notes.append(
                f"ODWET: DEF dodaje +{defense_power} siły do tego ataku."
            )
        self._warrior_retribution_ready = False
        self._warrior_retribution_ratio = 0.50

        if self._hunter_instinct_ready and has_active_class_effect(self.player, "hunter_predatory_instinct"):
            attack_multiplier *= 1.20
            bonus_crit_chance = 10.0
            report.class_effect_notes.append(
                "DRAPIEŻNY ODRUCH: +20% obrażeń i +10 p.p. szansy na krytyk."
            )
        self._hunter_instinct_ready = False

        if specialization_for(self.player, "increased_attack") == "momentum":
            attack_multiplier *= 1.0 + 0.03 * self._momentum_stacks

        damage, dodged, critical = self._resolve_player_hit(
            power=power,
            multiplier=attack_multiplier,
            guaranteed_hit=False,
            magical=False,
            damage_type=DamageType.PHYSICAL,
            bonus_crit_chance=bonus_crit_chance,
        )
        report.player_damage = damage
        report.enemy_dodged = dodged
        report.player_critical = critical

        if (
            self.player.character_class.code == "pierrot"
            and has_active_class_effect(self.player, "seven_chances")
            and not dodged
            and self.enemy.is_alive
        ):
            sign = self.rng.randint(1, 7)
            report.class_effect_notes.append(f"LANCA SIEDMIU PRZYPADKÓW: znak {sign}.")
            if sign == 1:
                self._add_fate_tokens(1, report)
            elif sign == 2:
                self.enemy.attack = max(0, self.enemy.attack - 1)
                report.class_effect_notes.append("KAPRYS: przeciwnik traci 1 ATK do końca walki.")
            elif sign == 3:
                bonus = self.enemy.take_damage(max(1, int(round(self.player.stats.attack * 0.20))))
                report.extra_player_damage += bonus
                report.class_effect_notes.append(f"TRZECI ZNAK: dodatkowe {bonus} obrażeń.")
            elif sign == 4:
                self.effects.apply_dodge_bonus(10.0, 1)
                report.class_effect_notes.append("CZWARTY ZNAK: +10 p.p. Uniku na następny atak.")
            elif sign == 5:
                bonus, _, bonus_crit = self._resolve_player_hit(
                    power=self.player.stats.attack, multiplier=0.35, guaranteed_hit=True,
                    magical=False, damage_type=DamageType.PHYSICAL,
                )
                report.extra_player_damage += bonus
                report.extra_player_critical = report.extra_player_critical or bonus_crit
                report.class_effect_notes.append(f"PIĄTY ZNAK: dodatkowe pchnięcie za {bonus} obrażeń.")
            elif sign == 6:
                bonus, _, bonus_crit = self._resolve_player_hit(
                    power=self.player.stats.attack, multiplier=0.50, guaranteed_hit=True,
                    magical=False, damage_type=DamageType.PHYSICAL,
                )
                report.extra_player_damage += bonus
                report.extra_player_critical = report.extra_player_critical or bonus_crit
                report.class_effect_notes.append(f"SZÓSTY ZNAK: Los uderza za dodatkowe {bonus} obrażeń.")
            else:
                bonus, _, bonus_crit = self._resolve_player_hit(
                    power=self.player.stats.attack, multiplier=0.75, guaranteed_hit=True,
                    magical=False, damage_type=DamageType.PHYSICAL,
                )
                report.extra_player_damage += bonus
                report.extra_player_critical = report.extra_player_critical or bonus_crit
                self._add_fate_tokens(1, report)
                report.class_effect_notes.append(f"SIÓDMY ZNAK — JACKPOT: +{bonus} obrażeń.")

        if critical and specialization_for(self.player, "attack_speed") == "deadly_tempo":
            self._deadly_tempo_ready = True

        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            if armor_break_was_active:
                self.effects.consume_armor_break_action()
            return report

        extra_chance = attack_speed_extra_hit_chance(self.player.passives)
        if specialization_for(self.player, "attack_speed") == "flurry":
            extra_chance += 5.0
        if self._deadly_tempo_ready:
            extra_chance += 15.0
            report.class_effect_notes.append(
                "ZABÓJCZE TEMPO: +15 p.p. szansy na dodatkowe uderzenie."
            )
            self._deadly_tempo_ready = False
        if extra_chance > 0 and self.rng.random() < extra_chance / 100.0:
            damage, dodged, critical = self._resolve_player_hit(
                power=self.player.stats.attack,
                multiplier=1.0,
                guaranteed_hit=False,
                magical=False,
                damage_type=DamageType.PHYSICAL,
            )
            report.extra_player_damage = damage
            report.extra_enemy_dodged = dodged
            report.extra_player_critical = critical
            if critical and specialization_for(self.player, "attack_speed") == "deadly_tempo":
                self._deadly_tempo_ready = True
            if not self.enemy.is_alive:
                self.result = CombatResult.VICTORY
                if armor_break_was_active:
                    self.effects.consume_armor_break_action()
                return report

        if armor_break_was_active:
            self.effects.consume_armor_break_action()

        self._resolve_hunter_delayed_effects(report, pending_echoes, pending_rain)
        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return report
        self._after_offensive_action()
        self._enemy_turn(report)
        return report

    def player_use_skill(self, skill_id: str) -> TurnReport:
        self._ensure_ongoing()
        skill = self._prepare_skill(skill_id)
        if skill.effect == "fate_va_banque" and self._fate_tokens <= 0:
            raise ValueError("Va Banque wymaga przynajmniej 1 Żetonu Losu.")

        pending_echoes, pending_rain = self._take_hunter_delayed_effects()
        report = TurnReport(
            skill_name=skill.name,
            skill_mana_cost=skill.mana_cost,
            player_damage_type=damage_type_from_code(skill.damage_type),
        )
        self._spend_skill_mana(skill.mana_cost, report)
        armor_break_was_active = self.effects.armor_break_active

        self._execute_skill(skill, report, power_scale=1.0)

        if armor_break_was_active and self._skill_counts_as_offensive(skill):
            self.effects.consume_armor_break_action()

        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return report

        self._resolve_hunter_delayed_effects(report, pending_echoes, pending_rain)
        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return report

        if self._skill_counts_as_offensive(skill):
            self._after_offensive_action()
        else:
            self._break_momentum()

        self._enemy_turn(report)
        return report

    def player_use_skill_pair(self, first_skill_id: str, second_skill_id: str) -> TurnReport:
        """Arkana: dwa zaklęcia w jednej turze, potem jedna tura przeciwnika."""
        self._ensure_ongoing()
        if not self.can_double_cast():
            raise ValueError("Podwójny Splot nie jest jeszcze gotowy.")

        first = self._prepare_skill(first_skill_id)
        second = self._prepare_skill(second_skill_id)
        if first.player_class.code != "mage" or second.player_class.code != "mage":
            raise ValueError("Podwójny Splot działa wyłącznie na zaklęcia Maga.")
        if not self._skill_counts_as_offensive(first) or not self._skill_counts_as_offensive(second):
            raise ValueError("Podwójny Splot wymaga dwóch ofensywnych zaklęć.")

        second_cost = second.mana_cost
        if has_talent(self.player, "arcana_efficiency"):
            second_cost = max(1, int(round(second_cost * 0.75)))
        total_cost = first.mana_cost + second_cost
        if self.player.stats.current_mana < total_cost:
            raise ValueError(
                f"Brak Many na Podwójny Splot. Potrzeba {total_cost}, masz {self.player.stats.current_mana}."
            )

        report = TurnReport(
            skill_name=f"{first.name} + {second.name}",
            skill_mana_cost=total_cost,
            player_damage_type=damage_type_from_code(first.damage_type),
        )
        self._spend_skill_mana(first.mana_cost, report)
        self._spend_skill_mana(second_cost, report)
        self._arcane_weave = 0
        report.class_effect_notes.append("PODWÓJNY SPLOT: dwa zaklęcia zostają rzucone w jednej turze.")

        armor_break_was_active = self.effects.armor_break_active
        self._execute_skill(first, report, power_scale=1.0, build_weave=False)
        if self.enemy.is_alive:
            second_scale = 0.95 if has_talent(self.player, "arcana_perfect_weave") else 0.80
            if has_active_class_effect(self.player, "split_weave"):
                second_scale += 0.10
                report.class_effect_notes.append("ROZSZCZEPIONY SPLOT: drugie zaklęcie zyskuje +10 p.p. mocy.")
            elemental = {"fire", "frost", "wind"}
            if (
                has_active_class_effect(self.player, "twin_star")
                and first.damage_type in elemental
                and second.damage_type in elemental
                and first.damage_type != second.damage_type
            ):
                second_scale += 0.15
                report.class_effect_notes.append("DWIE GWIAZDY: dwa różne żywioły wzmacniają drugie zaklęcie o 15%.")
            self._execute_skill(second, report, power_scale=second_scale, build_weave=False)
            report.class_effect_notes.append(
                f"Drugie zaklęcie Splotu działa z {int(round(second_scale * 100))}% mocy."
            )

        if armor_break_was_active:
            self.effects.consume_armor_break_action()

        if has_talent(self.player, "arcana_mana_cycle"):
            restored = self.player.stats.restore_mana(4)
            if restored:
                report.class_effect_notes.append(f"OBIEG MANY: odzyskujesz {restored} Many.")

        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return report

        self._after_offensive_action()
        self._enemy_turn(report)
        return report

    def player_defend(self) -> TurnReport:
        self._ensure_ongoing()
        report = TurnReport(player_defended=True)
        shield = self._equipped_type(EquipmentSlot.OFF_HAND) == "shield"
        if has_active_class_effect(self.player, "warrior_retribution") or (
            shield and has_talent(self.player, "heavy_knight_core")
        ):
            self._warrior_retribution_ready = True
            self._warrior_retribution_ratio = 0.75 if shield and has_talent(self.player, "heavy_bastion") else 0.50
            percent = int(round(self._warrior_retribution_ratio * 100))
            report.class_effect_notes.append(
                f"ODWET: następny podstawowy atak wykorzysta {percent}% DEF jako dodatkową siłę."
            )
        self._break_momentum()
        self._enemy_turn(report, defending=True)
        return report

    def player_flee(self) -> TurnReport:
        self._ensure_ongoing()
        report = TurnReport()
        self._break_momentum()
        if self.rng.random() < BASE_FLEE_CHANCE:
            self.result = CombatResult.FLED
            return report
        report.flee_failed = True
        self._enemy_turn(report)
        return report

    def player_item_turn(self, healed_hp: int, item_name: str, restored_mana: int = 0) -> TurnReport:
        self._ensure_ongoing()
        self._break_momentum()
        report = TurnReport(
            player_healed=healed_hp,
            player_restored_mana=restored_mana,
            used_item_name=item_name,
        )
        self._enemy_turn(report)
        return report

    # ------------------------------------------------------------------
    # Skill execution
    # ------------------------------------------------------------------
    def _prepare_skill(self, skill_id: str) -> SkillDefinition:
        skill = get_skill(skill_id)
        if not skill_is_unlocked(self.player, skill):
            raise ValueError("Ta umiejętność nie jest dostępna dla twojej postaci.")
        self._validate_skill_equipment(skill)
        if self.player.stats.current_mana < skill.mana_cost:
            raise ValueError(
                f"Brak Many. Potrzeba {skill.mana_cost}, masz {self.player.stats.current_mana}."
            )
        return skill

    def _validate_skill_equipment(self, skill: SkillDefinition) -> None:
        if skill.required_weapon_type is not None:
            equipped = self._equipped_type(EquipmentSlot.WEAPON)
            if equipped != skill.required_weapon_type:
                labels = {"bow": "Łuku", "staff": "Kostura", "fate_lance": "Lancy Losu"}
                raise ValueError(f"Ta umiejętność wymaga: {labels.get(skill.required_weapon_type, skill.required_weapon_type)}.")
        if skill.required_offhand_type is not None:
            equipped = self._equipped_type(EquipmentSlot.OFF_HAND)
            if equipped != skill.required_offhand_type:
                labels = {"shield": "Tarczy", "quiver": "Kołczanu", "artifact": "Artefaktu"}
                raise ValueError(f"Ta umiejętność wymaga: {labels.get(skill.required_offhand_type, skill.required_offhand_type)}.")

    def _equipped_type(self, slot: EquipmentSlot) -> str | None:
        item = self.player.equipment.get(slot)
        if item is None:
            return None
        return get_item_definition(item.item_id).equipment_type

    def _spend_skill_mana(self, mana_cost: int, report: TurnReport) -> None:
        self.player.stats.spend_mana(mana_cost)
        if has_active_class_effect(self.player, "mage_mana_tide"):
            self._mage_mana_spent += mana_cost
            while self._mage_mana_spent >= 20:
                self._mage_mana_spent -= 20
                restored = self.player.stats.restore_mana(5)
                if restored:
                    report.class_effect_notes.append(f"PRZYPŁYW MANY: odzyskujesz {restored} Many.")
        if mana_cost > 0 and has_active_class_effect(self.player, "storm_archive_refund") and self.rng.random() < 0.20:
            restored = self.player.stats.restore_mana(3)
            if restored:
                report.class_effect_notes.append(f"MARGINES ARCHIWUM: odzyskujesz {restored} Many.")

    def _execute_skill(
        self,
        skill: SkillDefinition,
        report: TurnReport,
        *,
        power_scale: float = 1.0,
        build_weave: bool = True,
    ) -> None:
        if skill.effect and skill.effect.startswith("fate_"):
            self._resolve_fate_skill(skill, report)
            return

        # Deszcz Strzał nie zadaje natychmiast obrażeń — salwa wraca po kolejnej akcji Łowcy.
        if skill.effect == "delayed_rain":
            power = self._skill_power(skill)
            self._hunter_rain_pending.append(power)
            report.skill_notes.append("DESZCZ STRZAŁ: salwa leci w górę i spadnie po następnej akcji Łowcy.")
            self._record_hunter_technique(skill, report)
            return

        multiplier_scale = power_scale * self._talent_skill_multiplier(skill, report)
        self._resolve_skill_hits(skill, report, power_scale=multiplier_scale)

        if skill.effect == "splitting" and self.enemy.is_alive and not report.enemy_dodged:
            power = self._skill_power(skill)
            for _ in range(2):
                if not self.enemy.is_alive:
                    break
                damage, _, crit = self._resolve_player_hit(
                    power=power,
                    multiplier=skill.effect_value / 100.0,
                    guaranteed_hit=True,
                    magical=False,
                    damage_type=DamageType.PHYSICAL,
                    is_skill=True,
                )
                report.skill_total_damage += damage
                report.skill_notes.append(
                    f"Widmowy odłamek zadaje {damage} obrażeń" + (" krytycznych." if crit else ".")
                )

        if skill.effect == "phantom_echo" and not report.enemy_dodged:
            self._hunter_phantom_pending.append(self._skill_power(skill))
            report.skill_notes.append("WIDMOWE ECHO: ślad strzały pozostaje przy celu.")

        if skill.effect == "explosive_charge" and not report.enemy_dodged:
            self._hunter_explosive_charges += 1
            report.skill_notes.append(f"Ładunek Wybuchowy: {self._hunter_explosive_charges}/3.")
            if self._hunter_explosive_charges >= 3 and self.enemy.is_alive:
                power = self._skill_power(skill)
                damage, _, critical = self._resolve_player_hit(
                    power=power,
                    multiplier=1.55,
                    guaranteed_hit=True,
                    magical=False,
                    damage_type=DamageType.FIRE,
                    is_skill=True,
                )
                report.skill_total_damage += damage
                report.skill_notes.append(
                    f"DETONACJA 3/3: {damage} obrażeń" + (" krytycznych." if critical else ".")
                )
                self._hunter_explosive_charges = 0

        self._apply_skill_effect(skill, report)
        self._record_hunter_technique(skill, report)

        if build_weave and skill.player_class.code == "mage" and has_talent(self.player, "arcana_core"):
            self._arcane_weave = min(3, self._arcane_weave + 1)
            report.class_effect_notes.append(f"SPLOT MAGII: {self._arcane_weave}/3.")

    def _resolve_skill_hits(
        self,
        skill: SkillDefinition,
        report: TurnReport,
        *,
        power_scale: float = 1.0,
    ) -> None:
        power = self._skill_power(skill)
        damage_type = damage_type_from_code(skill.damage_type)
        magical = skill.scaling == "magic"
        results: list[tuple[int, bool, bool]] = []

        for _ in range(skill.hits):
            if not self.enemy.is_alive:
                break
            results.append(
                self._resolve_player_hit(
                    power=power,
                    multiplier=skill.multiplier * power_scale,
                    guaranteed_hit=skill.guaranteed_hit,
                    magical=magical,
                    damage_type=damage_type,
                    is_skill=True,
                    bonus_armor_penetration=skill.special_armor_penetration,
                )
            )

        report.skill_total_damage += sum(result[0] for result in results)
        if results:
            report.player_damage, report.enemy_dodged, report.player_critical = results[0]
        if len(results) > 1:
            report.extra_player_damage, report.extra_enemy_dodged, report.extra_player_critical = results[1]
        if len(results) > 2:
            for index, (damage, dodged, critical) in enumerate(results[2:], start=3):
                if dodged:
                    report.skill_notes.append(f"Trafienie {index}: unik.")
                else:
                    report.skill_notes.append(
                        f"Trafienie {index}: {damage} obrażeń" + (" krytycznych." if critical else ".")
                    )

    def _skill_power(self, skill: SkillDefinition) -> int:
        if skill.scaling == "attack":
            return max(1, self.player.stats.attack)
        if skill.scaling == "hunter":
            return max(1, self.player.stats.attack + self.player.attributes.dexterity // 2)
        if skill.scaling == "magic":
            return max(1, 4 + self.player.attributes.intelligence * 2 + self.player.stats.magic_power)
        if skill.scaling == "shield":
            return max(1, self.player.stats.attack + int(round(self.player.stats.defense * 0.60)))
        if skill.scaling == "fate":
            return max(1, self.player.stats.attack + self.player.attributes.luck // 2)
        return 0

    def _talent_skill_multiplier(self, skill: SkillDefinition, report: TurnReport) -> float:
        result = 1.0
        if skill.player_class.code == "warrior" and skill.hits > 0:
            result *= 1.0 + 0.04 * self.player.talents.get("warrior_battle_fury", 0)
            if skill.skill_id == "blood_strike" and has_talent(self.player, "warrior_executioner"):
                if self.enemy.current_hp / max(1, self.enemy.max_hp) < 0.35:
                    result *= 1.30
                    report.class_effect_notes.append("EGZEKUTOR: Krwawy Zamach zyskuje +30% obrażeń.")

        mage_talents = {
            "fire_bolt": "mage_fire_mastery",
            "frost_lance": "mage_frost_mastery",
            "lightning": "mage_storm_mastery",
        }
        talent_id = mage_talents.get(skill.skill_id)
        if talent_id:
            result *= 1.0 + 0.08 * self.player.talents.get(talent_id, 0)

        if skill.player_class.code == "mage" and skill.damage_type in {"fire", "frost", "wind"}:
            element = skill.damage_type
            candidate = (self._mage_element_sequence + [element])[-3:]
            if has_talent(self.player, "mage_elemental_cycle") and len(candidate) == 3 and len(set(candidate)) == 3:
                result *= 1.20
                report.class_effect_notes.append("CYKL ŻYWIOŁÓW: trzeci różny żywioł zyskuje +20% obrażeń.")
                self._mage_element_sequence.clear()
            else:
                self._mage_element_sequence.append(element)
                self._mage_element_sequence = self._mage_element_sequence[-2:]

        if skill.player_class.code == "hunter" and skill.hunter_technique and has_talent(self.player, "hunter_sequence_mastery"):
            candidate = self._hunter_sequence[-2:] + [skill.hunter_technique]
            if len(candidate) == 3 and len(set(candidate)) == 3:
                result *= 1.15
                report.class_effect_notes.append("PERFEKCYJNA SEKWENCJA: trzeci różny strzał zyskuje +15% obrażeń.")

        if (
            skill.player_class.code == "mage"
            and skill.is_offensive
            and has_active_class_effect(self.player, "empty_mana_power")
            and self.player.stats.max_mana > 0
            and self.player.stats.current_mana <= self.player.stats.max_mana * 0.25
        ):
            result *= 1.12
            report.class_effect_notes.append("OSTATNIA ISKRA: niska Mana zwiększa obrażenia zaklęcia o 12%.")

        if specialization_for(self.player, "increased_attack") == "momentum" and skill.hits > 0:
            result *= 1.0 + 0.03 * self._momentum_stacks
        return result

    # ------------------------------------------------------------------
    # Hunter system
    # ------------------------------------------------------------------
    def _take_hunter_delayed_effects(self) -> tuple[list[int], list[int]]:
        if self.player.character_class.code != "hunter":
            return [], []
        echoes = self._hunter_phantom_pending
        rain = self._hunter_rain_pending
        self._hunter_phantom_pending = []
        self._hunter_rain_pending = []
        return echoes, rain

    def _resolve_hunter_delayed_effects(self, report: TurnReport, echoes: list[int], rain: list[int]) -> None:
        if self.player.character_class.code != "hunter":
            return
        echo_multiplier = 0.60 + 0.15 * self.player.talents.get("phantom_echo_mastery", 0)
        if has_active_class_effect(self.player, "riftglass_echo"):
            echo_multiplier *= 1.20
        for power in echoes:
            if not self.enemy.is_alive:
                break
            damage, _, critical = self._resolve_player_hit(
                power=power,
                multiplier=echo_multiplier,
                guaranteed_hit=True,
                magical=False,
                damage_type=DamageType.PHYSICAL,
                is_skill=True,
            )
            report.skill_total_damage += damage
            report.skill_notes.append(
                f"WIDMOWE ECHO materializuje się: {damage} obrażeń" + (" krytycznych." if critical else ".")
            )
            if has_active_class_effect(self.player, "afterimage_mana") and self.rng.random() < 0.30:
                restored = self.player.stats.restore_mana(2)
                if restored:
                    report.class_effect_notes.append(f"POWIDOK: odzyskujesz {restored} Many.")
        for power in rain:
            if not self.enemy.is_alive:
                break
            damage, _, critical = self._resolve_player_hit(
                power=power,
                multiplier=0.65,
                guaranteed_hit=True,
                magical=False,
                damage_type=DamageType.PHYSICAL,
                is_skill=True,
            )
            report.skill_total_damage += damage
            report.skill_notes.append(
                f"DESZCZ STRZAŁ spada z góry: {damage} obrażeń" + (" krytycznych." if critical else ".")
            )

    def _record_hunter_technique(self, skill: SkillDefinition, report: TurnReport) -> None:
        technique = skill.hunter_technique
        if self.player.character_class.code != "hunter" or not technique:
            return
        self._hunter_sequence.append(technique)
        if len(self._hunter_sequence) < 3:
            return
        sequence = tuple(self._hunter_sequence[-3:])
        combo = combo_for_sequence(sequence)
        self._hunter_sequence.clear()

        if has_active_class_effect(self.player, "third_echo") and self.enemy.is_alive:
            power = max(1, self.player.stats.attack + self.player.attributes.dexterity // 2)
            bonus, _, critical = self._resolve_player_hit(
                power=power, multiplier=0.15, guaranteed_hit=True, magical=False,
                damage_type=DamageType.PHYSICAL, is_skill=True,
            )
            report.skill_total_damage += bonus
            report.class_effect_notes.append(
                f"TRZECIE ECHO: Finisher zadaje dodatkowe {bonus} obrażeń" + (" krytycznych." if critical else ".")
            )
        if len(set(sequence)) == 3 and has_active_class_effect(self.player, "silent_volley"):
            self.effects.apply_dodge_bonus(15.0, 1)
            report.class_effect_notes.append("BEZGŁOŚNA SALWA: +15 p.p. Uniku na następny atak.")

        if combo is None:
            report.skill_notes.append("Sekwencja trzech strzałów zakończona — brak nazwanej kombinacji.")
            return

        first_discovery = combo.combo_id not in self.player.discovered_hunter_combos
        self.player.discovered_hunter_combos.add(combo.combo_id)
        report.class_effect_notes.append(
            f"KOMBINACJA: {combo.name}!" + (" [NOWA]" if first_discovery else "")
        )
        self._resolve_hunter_combo(combo.combo_id, report)

        if self.enemy.is_alive and has_talent(self.player, "phantom_bows"):
            power = self.player.stats.attack + self.player.attributes.dexterity // 2
            damage, _, critical = self._resolve_player_hit(
                power=max(1, power), multiplier=0.35, guaranteed_hit=True,
                magical=False, damage_type=DamageType.PHYSICAL, is_skill=True,
            )
            report.skill_total_damage += damage
            report.class_effect_notes.append(
                f"WIDMOWY ŁUK powtarza Finisher: {damage} obrażeń" + (" krytycznych." if critical else ".")
            )

    def _resolve_hunter_combo(self, combo_id: str, report: TurnReport) -> None:
        if not self.enemy.is_alive:
            return
        power = max(1, self.player.stats.attack + self.player.attributes.dexterity // 2)
        multiplier = {
            "scarlet_execution": 0.80,
            "brittle_burst": 1.45,
            "phantom_detonation": 1.35 + 0.20 * self._hunter_explosive_charges,
            "phantom_parade": 1.65,
            "armor_storm": 1.25,
            "bloody_echo": 1.10,
        }.get(combo_id, 0.75)
        damage_type = DamageType.FROST if combo_id == "brittle_burst" else DamageType.PHYSICAL
        penetration = 70.0 if combo_id in {"armor_storm", "bloody_echo"} else 0.0
        damage, _, critical = self._resolve_player_hit(
            power=power, multiplier=multiplier, guaranteed_hit=True,
            magical=False, damage_type=damage_type, is_skill=True,
            bonus_armor_penetration=penetration,
        )
        report.skill_total_damage += damage
        report.skill_notes.append(
            f"{combo_for_sequence(tuple({
                'scarlet_execution': ('blood','blood','blood'),
                'brittle_burst': ('frost','frost','explosive'),
                'phantom_detonation': ('explosive','phantom','explosive'),
                'phantom_parade': ('phantom','phantom','phantom'),
                'armor_storm': ('rain','piercing','splitting'),
                'bloody_echo': ('blood','phantom','piercing'),
            }[combo_id])).name}: {damage} obrażeń" + (" krytycznych." if critical else ".")
        )
        if combo_id in {"scarlet_execution", "bloody_echo"}:
            self.effects.apply_bleed(4, 3)
            report.skill_notes.append("Kombinacja pogłębia Krwawienie: 4 obrażenia przez 3 tury.")
        if combo_id == "phantom_detonation":
            self._hunter_explosive_charges = 0

    # ------------------------------------------------------------------
    # Pierrot / Fate Engine
    # ------------------------------------------------------------------
    def _fate_token_cap(self) -> int:
        cap = 6 + min(4, self.player.attributes.luck // 10)
        if has_talent(self.player, "fortuna_core"):
            cap += 2
        return cap

    def _add_fate_tokens(self, amount: int, report: TurnReport) -> None:
        if amount <= 0:
            return
        before = self._fate_tokens
        self._fate_tokens = min(self._fate_token_cap(), self._fate_tokens + amount)
        gained = self._fate_tokens - before
        if gained:
            report.class_effect_notes.append(f"ŻETONY LOSU: +{gained} ({self._fate_tokens}/{self._fate_token_cap()}).")

    def _resolve_fate_skill(self, skill: SkillDefinition, report: TurnReport) -> None:
        loaded = has_talent(self.player, "fortuna_loaded_die")
        cheat = has_talent(self.player, "fortuna_cheat")
        second = has_talent(self.player, "fortuna_second_chance")
        power = self._skill_power(skill)

        if skill.effect == "fate_feint":
            roll, _ = self.fate.roll(1, loaded_die=loaded)
            value = roll.dice[0]
            report.skill_notes.append(f"BŁAZEŃSKI UNIK: 🎲 {value}.")
            for note in roll.notes:
                report.class_effect_notes.append(note)
            if value == 1:
                self._add_fate_tokens(3 if has_talent(self.player, "fortuna_favored") else 2, report)
                self.effects.apply_dodge_bonus(10.0, 1)
                report.skill_notes.append("PECH: +2 Żetony Losu i +10 p.p. Uniku na 1 atak.")
            elif value <= 3:
                self.effects.apply_dodge_bonus(20.0, 2)
                report.skill_notes.append("ZWÓD: +20 p.p. Uniku na 2 ataki.")
            elif value <= 5:
                self.effects.apply_dodge_bonus(35.0, 2)
                report.skill_notes.append("AKROBACJA: +35 p.p. Uniku na 2 ataki.")
            else:
                self._pierrot_reflect_ready = True
                report.skill_notes.append("KURTYNA LUSTRZANA: następny bezpośredni atak zostanie odbity.")
            return

        if skill.effect == "fate_1d6":
            roll, _ = self.fate.roll(1, loaded_die=loaded)
            value = roll.dice[0]
            report.skill_notes.append(f"KOŚĆ LOSU: 🎲 {value}.")
            for note in roll.notes:
                report.class_effect_notes.append(note)
            table = {1: 0.70, 2: 0.95, 3: 1.15, 4: 1.10, 5: 0.85, 6: 1.85}
            mult = table[value]
            if has_talent(self.player, "pierrot_double_stake") and value in {1, 6}:
                mult *= 1.25
            hits = 2 if value == 5 else 1
            total = 0
            for _ in range(hits):
                if not self.enemy.is_alive:
                    break
                damage, _, critical = self._resolve_player_hit(
                    power=power, multiplier=mult, guaranteed_hit=True,
                    magical=False, damage_type=DamageType.PHYSICAL, is_skill=True,
                )
                total += damage
                if critical:
                    report.skill_notes.append("Kość prowadzi cios w trafienie krytyczne.")
            report.player_damage = total
            report.skill_total_damage += total
            if value == 1:
                self._add_fate_tokens(3 if has_talent(self.player, "fortuna_favored") else 2, report)
                report.skill_notes.append("PECHOWY NUMER: słabszy cios, ale pech zasila Los.")
            elif value == 2:
                self.enemy.attack = max(0, self.enemy.attack - 1)
                report.skill_notes.append("FIGIEL: przeciwnik traci 1 ATK do końca walki.")
            elif value == 4:
                self.effects.apply_dodge_bonus(15.0, 1)
                report.skill_notes.append("UNIK BŁAZNA: +15 p.p. Uniku na następny atak.")
            elif value == 5:
                report.skill_notes.append("PODWÓJNY NUMER: lanca uderza dwa razy.")
            elif value == 6:
                self._add_fate_tokens(1, report)
                report.skill_notes.append("JACKPOT!")
                self._maybe_chaos_bonus_roll(power, report)
            return

        count = 2 if skill.effect == "fate_2d6" else 3
        if skill.effect == "fate_va_banque":
            count = 3
        roll, spent = self.fate.roll(
            count,
            loaded_die=loaded,
            second_chance=second and count == 3,
            cheat_to_seven=cheat and count == 2,
            fate_tokens=self._fate_tokens,
        )
        if spent:
            self._fate_tokens -= spent
        report.skill_notes.append("KOŚCI LOSU: " + " + ".join(str(x) for x in roll.dice) + f" = {roll.total}.")
        for note in roll.notes:
            report.class_effect_notes.append(note)

        if roll.is_double and has_active_class_effect(self.player, "two_lies"):
            self._add_fate_tokens(1, report)
            report.class_effect_notes.append("DWA KŁAMSTWA: dublet daje dodatkowy Żeton Losu.")

        if roll.is_double and has_talent(self.player, "pierrot_crooked_mirror"):
            self._pierrot_reflect_ready = True
            report.class_effect_notes.append("KRZYWE ZWIERCIADŁO: dublet przygotowuje odbicie następnego bezpośredniego ataku.")

        if skill.effect == "fate_va_banque":
            wager = self._fate_tokens
            self._fate_tokens = 0
            mult = 0.55 + roll.total * 0.075 + wager * 0.14
            if roll.is_triple:
                mult += 0.75
            report.skill_notes.append(f"VA BANQUE: stawka {wager} Żetonów Losu.")
        elif count == 2:
            if roll.total == 2:
                mult = 0.50
                self._add_fate_tokens(3 if has_talent(self.player, "fortuna_favored") else 2, report)
                report.skill_notes.append("WĘŻOWE OCZY: katastrofalny cios, ale Los zaczyna ci sprzyjać.")
            elif roll.total == 7:
                mult = 1.70
                self._add_fate_tokens(2, report)
                report.skill_notes.append("SZCZĘŚLIWA SIÓDEMKA!")
            elif roll.dice == (6, 6):
                mult = 2.25
                self._add_fate_tokens(1, report)
                report.skill_notes.append("PODWÓJNA SZÓSTKA — JACKPOT!")
            elif roll.is_double:
                mult = 1.45
                report.skill_notes.append("DUBLET!")
            elif roll.total <= 4:
                mult = 0.80
                self._add_fate_tokens(2, report)
            elif roll.total >= 10:
                mult = 1.60
                self._add_fate_tokens(1, report)
            else:
                mult = 1.10
        else:
            if roll.is_triple:
                mult = 2.55
                self._add_fate_tokens(2, report)
                report.skill_notes.append("TRÓJKA! Kurtyna opada — potężny finał.")
            elif roll.total <= 5:
                mult = 0.60
                self._add_fate_tokens(4 if has_talent(self.player, "fortuna_favored") else 3, report)
                report.skill_notes.append("KATASTROFA: bardzo słaby wynik zasila Żetony Losu.")
            elif roll.total >= 16:
                mult = 2.15
                self._add_fate_tokens(2, report)
                report.skill_notes.append("WIELKI JACKPOT!")
            elif roll.is_double:
                mult = 1.55
                report.skill_notes.append("Dublet wzmacnia Wielki Zakład.")
            else:
                mult = 0.85 + roll.total * 0.055

        if has_active_class_effect(self.player, "ace_less_deck"):
            if count == 3 and roll.total <= 5:
                mult = max(mult, 0.85)
                report.class_effect_notes.append("BEZ ASA: katastrofalny wynik zostaje złagodzony.")
            if roll.total == count * 6:
                mult *= 0.90
                report.class_effect_notes.append("BEZ ASA: Jackpot traci 10% mocy.")

        if has_talent(self.player, "pierrot_double_stake") and (roll.total <= count + 2 or roll.total >= count * 6 - 2):
            mult *= 1.25
            report.class_effect_notes.append("PODWÓJNA STAWKA: skrajny wynik ma o 25% silniejszy skutek.")

        if has_talent(self.player, "fortuna_favored") and mult >= 1.5:
            mult *= 1.0 + min(0.20, self.player.attributes.luck * 0.004)

        damage, dodged, critical = self._resolve_player_hit(
            power=power, multiplier=mult, guaranteed_hit=True,
            magical=False, damage_type=DamageType.PHYSICAL, is_skill=True,
        )
        report.player_damage = damage
        report.enemy_dodged = dodged
        report.player_critical = critical
        report.skill_total_damage += damage
        if mult >= 1.7:
            self._maybe_chaos_bonus_roll(power, report)

    def _maybe_chaos_bonus_roll(self, power: int, report: TurnReport) -> None:
        trigger = has_talent(self.player, "pierrot_wild_roll")
        if has_talent(self.player, "pierrot_domino"):
            trigger = trigger and self.fate.chance(0.50)
        if not trigger or not self.enemy.is_alive:
            return
        roll, _ = self.fate.roll(1)
        bonus = roll.dice[0]
        damage, _, critical = self._resolve_player_hit(
            power=power, multiplier=0.20 + bonus * 0.08, guaranteed_hit=True,
            magical=False, damage_type=DamageType.PHYSICAL, is_skill=True,
        )
        report.skill_total_damage += damage
        report.class_effect_notes.append(
            f"EFEKT DOMINA: dodatkowy rzut 🎲 {bonus} zadaje {damage} obrażeń" + (" krytycznych." if critical else ".")
        )

    # ------------------------------------------------------------------
    # Generic hit / effects / enemy turn
    # ------------------------------------------------------------------
    def _skill_counts_as_offensive(self, skill: SkillDefinition) -> bool:
        fate_offensive = (
            skill.effect is not None
            and skill.effect.startswith("fate_")
            and skill.effect != "fate_feint"
        )
        return skill.hits > 0 or fate_offensive or skill.effect == "delayed_rain"

    def _resolve_player_hit(
        self,
        power: int,
        multiplier: float,
        guaranteed_hit: bool,
        magical: bool,
        damage_type: DamageType,
        is_skill: bool = False,
        bonus_crit_chance: float = 0.0,
        bonus_armor_penetration: float = 0.0,
    ) -> tuple[int, bool, bool]:
        if not guaranteed_hit and self._roll_dodge(self.enemy.dodge):
            return 0, True, False

        effective_multiplier = multiplier
        if is_skill and self.player.stats.skill_damage > 0:
            effective_multiplier *= 1.0 + self.player.stats.skill_damage / 100.0

        attack_value = max(1, int(round(power * effective_multiplier)))
        enemy_defense = self.effects.effective_enemy_defense(self.enemy.defense)
        penetration = min(90.0, max(0.0, self.player.stats.armor_penetration + bonus_armor_penetration))
        if penetration > 0:
            enemy_defense = max(0, int(round(enemy_defense * (1.0 - penetration / 100.0))))
        if magical:
            enemy_defense //= 2

        damage = calculate_damage(attack_value, enemy_defense)
        if damage_type is not DamageType.PHYSICAL:
            damage = apply_elemental_resistance(damage, damage_type, self.enemy.elemental_resistances)
        elif not magical:
            damage = self.enemy.reduce_physical_damage(damage)

        if not is_skill and self.player.stats.average_damage != 0:
            damage = max(1, int(round(damage * (1.0 + self.player.stats.average_damage / 100.0))))

        situational_bonus = 0.0
        if self.enemy.rank == "elite" or self.enemy.elite_modifier_id is not None:
            situational_bonus += self.player.stats.damage_vs_elite
        if self.enemy.rank in {"miniboss", "boss"}:
            situational_bonus += self.player.stats.damage_vs_boss
        if situational_bonus > 0:
            damage = max(1, int(round(damage * (1.0 + situational_bonus / 100.0))))

        critical = False
        spec = specialization_for(self.player, "critical_damage")
        crit_bonus = 3.0 if spec == "precision" else 0.0
        crit_chance = min(
            100.0,
            critical_chance(self.player.passives) + self.player.stats.crit_chance + bonus_crit_chance + crit_bonus,
        )
        if crit_chance > 0 and self.rng.random() < crit_chance / 100.0:
            multiplier_with_gear = critical_multiplier(self.player.passives) + self.player.stats.crit_damage / 100.0
            if spec == "execution" and self.enemy.current_hp / max(1, self.enemy.max_hp) < 0.30:
                multiplier_with_gear *= 1.20
            damage = max(1, int(round(damage * multiplier_with_gear)))
            critical = True

        return self.enemy.take_damage(damage), False, critical

    def _apply_skill_effect(self, skill: SkillDefinition, report: TurnReport) -> None:
        if skill.effect in {"armor_break", "bleed"} and self.enemy.status_resistance > 0 and self.rng.random() < self.enemy.status_resistance:
            report.skill_notes.append(f"{self.enemy.name} odpiera negatywny efekt.")
            return

        if skill.effect == "armor_break":
            reduction = skill.effect_value
            if skill.player_class.code == "warrior":
                reduction += self.player.talents.get("warrior_breaker", 0)
            self.effects.apply_armor_break(reduction, skill.effect_duration)
            report.skill_notes.append(f"DEF przeciwnika -{reduction} na {skill.effect_duration} ofensywne akcje.")
        elif skill.effect == "bleed":
            damage = skill.effect_value
            duration = skill.effect_duration
            if skill.player_class.code == "warrior":
                damage += self.player.talents.get("warrior_deep_wounds", 0)
                if skill.skill_id == "blood_strike" and has_active_class_effect(self.player, "oathbreaker_bleed"):
                    duration += 1
                    report.class_effect_notes.append("ZŁAMANA PRZYSIĘGA: Krwawy Zamach krwawi o 1 turę dłużej.")
            self.effects.apply_bleed(damage, duration)
            report.skill_notes.append(f"Krwawienie: {damage} obrażeń przez {duration} tury.")
        elif skill.effect == "guard":
            self.effects.apply_guard(skill.effect_value, skill.effect_duration)
            report.skill_notes.append(f"Redukcja obrażeń {skill.effect_value}% przez {skill.effect_duration} ataki przeciwnika.")
        elif skill.effect == "dodge":
            self.effects.apply_dodge_bonus(float(skill.effect_value), skill.effect_duration)
            report.skill_notes.append(f"UNIK +{skill.effect_value}% przez {skill.effect_duration} ataki przeciwnika.")
        elif skill.effect == "provoke":
            self._provoke_ready = True
            self._provoke_block_bonus = float(skill.effect_value)
            report.skill_notes.append(
                f"PROWOKACJA: przeciwnik odpowie zwykłym atakiem; +{skill.effect_value} p.p. Bloku na tę wymianę."
            )

    def _enemy_turn(self, report: TurnReport, defending: bool = False) -> None:
        attack_value = self.enemy.attack
        damage_type = self.enemy.basic_damage_type
        provoked = self._provoke_ready
        self._provoke_ready = False

        if self.enemy.attacks_made == 0:
            attack_value += self.enemy.first_attack_bonus

        if not provoked and self.enemy.roll_special_attack(self.rng):
            report.enemy_special_name = self.enemy.special_name
            attack_value += self.enemy.special_attack_bonus
            if self.enemy.special_damage_type is not None:
                damage_type = self.enemy.special_damage_type

        report.enemy_damage_type = damage_type
        report.enemy_damage = self._resolve_enemy_hit(attack_value, damage_type, defending, report)
        self.enemy.attacks_made += 1
        self._provoke_block_bonus = 0.0

        if not self.player.stats.is_alive:
            self.result = CombatResult.DEFEAT
            return
        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return

        if not provoked and self.enemy.roll_extra_attack(self.rng):
            report.enemy_extra_damage = self._resolve_enemy_hit(
                self.enemy.attack, self.enemy.basic_damage_type, defending=False, report=report, extra=True
            )
            if not self.player.stats.is_alive:
                self.result = CombatResult.DEFEAT
                return
            if not self.enemy.is_alive:
                self.result = CombatResult.VICTORY
                return

        self._apply_bleed_tick(report)
        if not self.enemy.is_alive:
            self.result = CombatResult.VICTORY
            return

        self._maybe_second_wind(report)
        regen = health_regeneration_per_turn(self.player.passives) + self.player.stats.health_regen
        if regen > 0:
            if specialization_for(self.player, "health_regen") == "iron_will" and self.player.stats.current_hp <= self.player.stats.max_hp * 0.40:
                regen = int(round(regen * 1.50))
                report.class_effect_notes.append("ŻELAZNA WOLA: regeneracja zwiększona o 50%.")
            report.player_regenerated = self.player.stats.heal(regen)

    def _apply_bleed_tick(self, report: TurnReport) -> None:
        if not self.effects.bleed_active:
            return
        report.enemy_bleed_damage = self.enemy.take_damage(self.effects.bleed_damage)
        self.effects.consume_bleed_turn()

    def _shield_block_chance(self) -> float:
        if self.player.character_class.code != "warrior" or self._equipped_type(EquipmentSlot.OFF_HAND) != "shield":
            return 0.0
        chance = 5.0
        chance += 5.0 * self.player.talents.get("heavy_shield_mastery", 0)
        chance += self._provoke_block_bonus
        return min(75.0, chance)

    def _resolve_enemy_hit(
        self,
        attack_value: int,
        damage_type: DamageType,
        defending: bool,
        report: TurnReport,
        extra: bool = False,
    ) -> int:
        dodge_chance = self.player.stats.dodge
        if self.effects.dodge_active:
            dodge_chance += self.effects.player_dodge_bonus
        dodged = self._roll_dodge(dodge_chance)
        self.effects.consume_dodge_hit()
        if dodged:
            if not extra:
                report.player_dodged = True
            if has_active_class_effect(self.player, "hunter_predatory_instinct"):
                self._hunter_instinct_ready = True
                report.class_effect_notes.append(
                    "DRAPIEŻNY ODRUCH: unik przygotowuje wzmocniony podstawowy atak."
                )
            self.effects.consume_guard_hit()
            return 0

        block_chance = self._shield_block_chance()
        if block_chance > 0 and self.rng.random() < block_chance / 100.0:
            report.class_effect_notes.append(f"BLOK TARCZĄ! ({block_chance:.0f}% szansy)")
            self.effects.consume_guard_hit()
            if has_active_class_effect(self.player, "rift_bastion_memory"):
                self._warrior_retribution_ready = True
                self._warrior_retribution_ratio = min(1.00, max(0.0, self._warrior_retribution_ratio) + 0.25)
                report.class_effect_notes.append("PAMIĘĆ BASTIONU: następny podstawowy atak zyskuje dodatkowe 25% DEF.")
            if has_talent(self.player, "heavy_counter") and self.enemy.is_alive:
                counter = max(1, int(round(self.player.stats.defense * 0.70)))
                dealt = self.enemy.take_damage(counter)
                report.class_effect_notes.append(f"ŻELAZNA KONTRA: {self.enemy.name} otrzymuje {dealt} obrażeń.")
            return 0

        effective_defense = self.player.stats.defense
        if (
            has_active_class_effect(self.player, "last_guard")
            and self.player.stats.current_hp <= self.player.stats.max_hp * 0.35
        ):
            effective_defense = int(round(effective_defense * 1.20))
            report.class_effect_notes.append("OSTATNIA STRAŻ: niski poziom HP zwiększa efektywny DEF o 20%.")
        damage = calculate_damage(attack_value, effective_defense)
        damage = apply_elemental_resistance(damage, damage_type, self.player.stats.resistances)
        if defending:
            damage = apply_defend_reduction(damage)
            if has_active_class_effect(self.player, "warden_afterguard"):
                damage = int(round(damage * 0.85))
                report.class_effect_notes.append("PO STRAŻY: broniony cios zostaje dodatkowo osłabiony o 15%.")
        if self.effects.guard_active:
            damage = int(damage * (1.0 - self.effects.player_damage_reduction_percent / 100.0))
        self.effects.consume_guard_hit()

        if self._pierrot_reflect_ready and damage > 0:
            self._pierrot_reflect_ready = False
            reflected = self.enemy.take_damage(max(0, damage))
            report.class_effect_notes.append(
                f"KRZYWE ZWIERCIADŁO: atak zostaje odbity! {self.enemy.name} otrzymuje {reflected} obrażeń."
            )
            if has_active_class_effect(self.player, "crooked_smile"):
                self._add_fate_tokens(1, report)
                report.class_effect_notes.append("KRZYWY UŚMIECH: odbicie odzyskuje 1 Żeton Losu.")
            return 0

        dealt = self.player.stats.take_damage(max(0, damage))
        if dealt > 0 and self.enemy.life_steal_percent > 0:
            heal_amount = max(1, int(round(dealt * self.enemy.life_steal_percent / 100.0)))
            report.enemy_healed += self.enemy.heal(heal_amount)
        return dealt

    def _maybe_second_wind(self, report: TurnReport) -> None:
        if self._second_wind_used or specialization_for(self.player, "health_regen") != "second_wind":
            return
        if self.player.stats.current_hp <= 0:
            return
        if self.player.stats.current_hp <= self.player.stats.max_hp * 0.25:
            self._second_wind_used = True
            healed = self.player.stats.heal(max(1, int(round(self.player.stats.max_hp * 0.20))))
            if healed:
                report.player_healed += healed
                report.class_effect_notes.append(f"DRUGI ODDECH: odzyskujesz {healed} HP.")

    def _after_offensive_action(self) -> None:
        if specialization_for(self.player, "increased_attack") == "momentum":
            self._momentum_stacks = min(3, self._momentum_stacks + 1)

    def _break_momentum(self) -> None:
        if specialization_for(self.player, "increased_attack") == "momentum":
            self._momentum_stacks = 0

    def _roll_dodge(self, dodge_chance: float) -> bool:
        if dodge_chance <= 0:
            return False
        return self.rng.random() < min(dodge_chance, 100.0) / 100.0

    def _ensure_ongoing(self) -> None:
        if self.result is not CombatResult.ONGOING:
            raise RuntimeError("Ta walka już się zakończyła.")
