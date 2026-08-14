from __future__ import annotations

from dataclasses import dataclass, field
import random

from combat.damage import calculate_damage
from combat.fate import FateEngine
from combat.hunter_combo import combo_for_sequence
from items.class_effects import has_active_class_effect
from player.player import Player
from player.skills import get_skill, unlocked_skills
from player.talents import has_talent
from rifts.models import RiftInstance
from systems.companions import companion_to_player
from systems.rifts import RiftEnemyProfile, mana_cost_multiplier
from companions.models import Companion


@dataclass
class RiftFighter:
    name: str
    combatant: Player
    companion_id: str | None = None
    downed_timer: int = 0
    removed: bool = False
    defending: bool = False
    lethal_downed: bool = False

    @property
    def is_player(self) -> bool:
        return self.companion_id is None

    @property
    def standing(self) -> bool:
        return not self.removed and self.downed_timer <= 0 and self.combatant.stats.current_hp > 0


@dataclass
class RiftRoundResult:
    lines: list[str] = field(default_factory=list)
    victory: bool = False
    defeat: bool = False
    critically_injured: list[str] = field(default_factory=list)
    killed: list[str] = field(default_factory=list)


class RiftBattleEngine:
    """Osobna walka drużynowa dla Szczelin.

    Nie zastępuje normalnego CombatEngine. W Szczelinach kolejność jest
    drużynowa: akcja gracza -> AI kompanów -> akcja przeciwnika. Dzięki temu
    klasy zachowują własne skille, ale boss może reagować na cały skład.
    """

    def __init__(
        self,
        player: Player,
        companions: list[Companion],
        enemy: RiftEnemyProfile,
        rift: RiftInstance,
        rng: random.Random,
    ) -> None:
        self.player = player
        self.companions = companions
        self.enemy = enemy
        self.rift = rift
        self.rng = rng
        self.enemy_hp = enemy.max_hp
        self.enemy_defense_penalty = 0
        self.enemy_bleed_damage = 0
        self.enemy_bleed_turns = 0
        self.round_number = 1
        self.taunt_companion_id: str | None = None
        self.player_fighter = RiftFighter(player.name, player)
        self.companion_fighters = [
            RiftFighter(companion.name, companion_to_player(companion), companion.companion_id)
            for companion in companions
        ]
        self.hunter_sequences: dict[str, list[str]] = {}
        self.fate_engines: dict[str, FateEngine] = {}
        self._main_player_hunter_sequence: list[str] = []

    @property
    def all_fighters(self) -> list[RiftFighter]:
        return [self.player_fighter] + self.companion_fighters

    def living_party(self) -> list[RiftFighter]:
        return [fighter for fighter in self.all_fighters if not fighter.removed]

    def standing_party(self) -> list[RiftFighter]:
        return [fighter for fighter in self.all_fighters if fighter.standing]

    def enemy_alive(self) -> bool:
        return self.enemy_hp > 0

    def downed_companions(self) -> list[RiftFighter]:
        return [fighter for fighter in self.companion_fighters if fighter.downed_timer > 0 and not fighter.removed]

    def _crit_multiplier(self, actor: Player) -> float:
        return max(1.5, 2.0 + actor.stats.crit_damage / 100.0)

    def _deal_to_enemy(self, actor: Player, power: float, *, armor_pen: float = 0.0, guaranteed: bool = False) -> tuple[int, bool]:
        defense = max(0, self.enemy.defense - self.enemy_defense_penalty)
        effective_defense = int(round(defense * (1.0 - min(95.0, max(0.0, armor_pen + actor.stats.armor_penetration)) / 100.0)))
        damage = calculate_damage(max(0, int(round(power))), effective_defense)
        crit_chance = 5.0 + actor.stats.crit_chance
        critical = self.rng.random() < min(95.0, crit_chance) / 100.0
        if critical:
            damage = max(1, int(round(damage * self._crit_multiplier(actor))))
        if actor.stats.skill_damage and not guaranteed:
            damage = int(round(damage * (1.0 + actor.stats.skill_damage / 100.0)))
        self.enemy_hp = max(0, self.enemy_hp - damage)
        return damage, critical

    def player_basic_attack(self) -> RiftRoundResult:
        result = RiftRoundResult()
        if not self.player_fighter.standing:
            result.lines.append("Nie możesz teraz wykonać akcji.")
            return result
        damage, critical = self._deal_to_enemy(self.player, self.player.stats.attack, guaranteed=True)
        result.lines.append(f"{self.player.name} atakuje: {damage} obrażeń" + (" krytycznych." if critical else "."))
        if self.player.character_class.code == "pierrot" and has_active_class_effect(self.player, "seven_chances") and self.enemy_alive():
            fate = self.fate_engines.setdefault("player", FateEngine(self.rng, self.player.attributes.luck))
            roll, _ = fate.roll(1)
            extra = max(1, int(round(self.player.stats.attack * (0.10 + roll.total * 0.03))))
            self.enemy_hp = max(0, self.enemy_hp - extra)
            result.lines.append(f"Lanca Siedmiu Przypadków — znak {roll.total}: +{extra} obrażeń.")
        return self._finish_party_round(result)

    def _skill_power(self, actor: Player, skill) -> int:
        if skill.scaling == "attack":
            return max(1, actor.stats.attack)
        if skill.scaling == "hunter":
            return max(1, actor.stats.attack + actor.attributes.dexterity // 2)
        if skill.scaling == "magic":
            return max(1, 4 + actor.attributes.intelligence * 2 + actor.stats.magic_power)
        if skill.scaling == "shield":
            return max(1, actor.stats.attack + int(round(actor.stats.defense * 0.60)))
        if skill.scaling == "fate":
            return max(1, actor.stats.attack + actor.attributes.luck // 2)
        return 0

    def _cast_skill(self, fighter: RiftFighter, skill_id: str, lines: list[str], *, power_scale: float = 1.0) -> None:
        actor = fighter.combatant
        skill = get_skill(skill_id)
        cost = max(1, int(round(skill.mana_cost * mana_cost_multiplier(self.rift)))) if skill.mana_cost else 0
        if actor.stats.current_mana < cost:
            lines.append(f"{fighter.name} próbuje użyć {skill.name}, ale brakuje Many.")
            damage, critical = self._deal_to_enemy(actor, actor.stats.attack, guaranteed=True)
            lines.append(f"{fighter.name} atakuje podstawowo: {damage}" + (" [KRYTYK]" if critical else "") + ".")
            return
        actor.stats.spend_mana(cost)

        if skill.effect and skill.effect.startswith("fate_"):
            self._cast_fate(fighter, skill.effect, lines)
            return
        if skill.effect == "guard":
            fighter.defending = True
            lines.append(f"{fighter.name}: {skill.name} — przygotowuje obronę.")
            return
        if skill.effect == "dodge":
            fighter.defending = True
            lines.append(f"{fighter.name}: {skill.name} — znika z linii ataku.")
            return
        if skill.effect == "provoke":
            self.taunt_companion_id = fighter.companion_id
            fighter.defending = True
            lines.append(f"{fighter.name} używa Prowokacji. Boss skupia na nim uwagę.")
            return
        if skill.effect == "delayed_rain":
            # W party combat opóźnienie reprezentujemy trafieniem pod koniec rundy.
            damage, critical = self._deal_to_enemy(actor, self._skill_power(actor, skill) * 0.75 * power_scale, guaranteed=True)
            lines.append(f"{fighter.name}: Deszcz Strzał spada pod koniec salwy — {damage}" + (" [KRYTYK]" if critical else "") + ".")
            self._record_hunter_sequence(fighter, skill, lines, damage)
            return

        power = self._skill_power(actor, skill)
        total = 0
        hits = max(1, skill.hits)
        for _ in range(hits):
            if not self.enemy_alive():
                break
            damage, critical = self._deal_to_enemy(
                actor,
                power * skill.multiplier * power_scale,
                armor_pen=skill.special_armor_penetration,
                guaranteed=not skill.is_offensive,
            )
            total += damage
            if critical:
                lines.append(f"  Trafienie krytyczne: {damage}.")
        lines.append(f"{fighter.name}: {skill.name} — łącznie {total} obrażeń.")

        if skill.effect == "bleed" and total > 0:
            self.enemy_bleed_damage = max(self.enemy_bleed_damage, skill.effect_value)
            self.enemy_bleed_turns = max(self.enemy_bleed_turns, skill.effect_duration)
            if has_active_class_effect(actor, "oathbreaker_bleed") and skill.skill_id == "blood_strike":
                self.enemy_bleed_turns += 1
            lines.append(f"Krwawienie: {self.enemy_bleed_damage} przez {self.enemy_bleed_turns} rund.")
        elif skill.effect == "armor_break" and total > 0:
            self.enemy_defense_penalty = max(self.enemy_defense_penalty, skill.effect_value)
            lines.append(f"DEF przeciwnika spada o {self.enemy_defense_penalty}.")
        elif skill.effect == "phantom_echo" and total > 0:
            echo_scale = 0.72 if has_active_class_effect(actor, "riftglass_echo") else 0.60
            echo = max(1, int(round(total * echo_scale)))
            self.enemy_hp = max(0, self.enemy_hp - echo)
            lines.append(f"Widmowe Echo wraca natychmiast w chaosie Szczeliny: +{echo} obrażeń.")
        elif skill.effect == "explosive_charge" and total > 0:
            bonus = max(1, int(round(total * 0.35)))
            self.enemy_hp = max(0, self.enemy_hp - bonus)
            lines.append(f"Ładunek rezonuje ze Szczeliną: +{bonus} obrażeń.")
        elif skill.effect == "splitting" and total > 0:
            extra = max(2, int(round(total * 0.45)))
            self.enemy_hp = max(0, self.enemy_hp - extra)
            lines.append(f"Odłamki Rozszczepiającej Strzały: +{extra} obrażeń.")

        self._record_hunter_sequence(fighter, skill, lines, total)

        if actor.character_class.code == "mage":
            if has_active_class_effect(actor, "storm_archive_refund") and self.rng.random() < 0.20:
                restored = actor.stats.restore_mana(3)
                if restored:
                    lines.append(f"Medalion Burzowego Archiwum zwraca {restored} Many.")

    def _record_hunter_sequence(self, fighter: RiftFighter, skill, lines: list[str], base_damage: int) -> None:
        if skill.hunter_technique is None:
            return
        key = fighter.companion_id or "player"
        sequence = self.hunter_sequences.setdefault(key, [])
        sequence.append(skill.hunter_technique)
        if len(sequence) < 3:
            return
        sequence_tuple = tuple(sequence[-3:])
        combo = combo_for_sequence(sequence_tuple)
        bonus = 0
        if combo is not None:
            bonus = max(1, int(round(max(1, base_damage) * 0.40)))
            lines.append(f"KOMBINACJA ŁOWCY: {combo.name}! +{bonus} obrażeń.")
        elif len(set(sequence_tuple)) == 3:
            bonus = max(1, int(round(max(1, base_damage) * 0.18)))
            lines.append(f"TRZY RÓŻNE TECHNIKI: +{bonus} obrażeń.")
        if has_active_class_effect(fighter.combatant, "third_echo"):
            extra = max(1, int(round(max(1, base_damage) * 0.15)))
            bonus += extra
            lines.append(f"Trzecie Echo wzmacnia Finisher: +{extra}.")
        if bonus:
            self.enemy_hp = max(0, self.enemy_hp - bonus)
        sequence.clear()

    def _cast_fate(self, fighter: RiftFighter, effect: str, lines: list[str]) -> None:
        actor = fighter.combatant
        engine = self.fate_engines.setdefault(fighter.companion_id or "player", FateEngine(self.rng, actor.attributes.luck))
        count = 1 if effect in {"fate_1d6", "fate_feint"} else 2 if effect == "fate_2d6" else 3
        roll, _ = engine.roll(count)
        dice_text = "+".join(map(str, roll.dice))
        if effect == "fate_feint":
            fighter.defending = True
            lines.append(f"{fighter.name}: Błazeński Unik — [{dice_text}].")
            return
        power = max(1, actor.stats.attack + actor.attributes.luck // 2)
        multiplier = 0.65 + roll.total / (6.0 * count)
        if roll.is_double:
            multiplier += 0.25
        if roll.is_triple:
            multiplier += 0.65
        if effect == "fate_va_banque":
            multiplier += 0.45
        if has_active_class_effect(actor, "ace_less_deck"):
            multiplier = max(0.85, multiplier)
            if roll.total == 6 * count:
                multiplier *= 0.90
        damage, critical = self._deal_to_enemy(actor, power * multiplier, guaranteed=True)
        lines.append(f"{fighter.name}: Kości Losu [{dice_text}] → {damage} obrażeń" + (" krytycznych." if critical else "."))

    def player_skill(self, skill_id: str) -> RiftRoundResult:
        result = RiftRoundResult()
        available = {skill.skill_id for skill in unlocked_skills(self.player)}
        if skill_id not in available:
            result.lines.append("Ta umiejętność nie jest dostępna.")
            return result
        self._cast_skill(self.player_fighter, skill_id, result.lines)
        return self._finish_party_round(result)

    def player_defend(self) -> RiftRoundResult:
        result = RiftRoundResult(lines=[f"{self.player.name} przyjmuje pozycję obronną."])
        self.player_fighter.defending = True
        return self._finish_party_round(result)

    def player_help(self, companion_id: str) -> RiftRoundResult:
        result = RiftRoundResult()
        target = next((fighter for fighter in self.companion_fighters if fighter.companion_id == companion_id), None)
        if target is None or target.downed_timer <= 0 or target.removed:
            result.lines.append("Ten kompan nie potrzebuje teraz pomocy.")
            return result
        target.downed_timer = 0
        target.lethal_downed = False
        target.combatant.stats.current_hp = max(1, int(round(target.combatant.stats.max_hp * 0.28)))
        result.lines.append(f"Podnosisz {target.name}. Wraca do walki z {target.combatant.stats.current_hp} HP.")
        return self._finish_party_round(result)

    def _companion_tactic(self, fighter: RiftFighter) -> str:
        if fighter.companion_id is None:
            return "balanced"
        companion = next(
            (item for item in self.companions if item.companion_id == fighter.companion_id),
            None,
        )
        return "balanced" if companion is None else companion.tactic

    def _choose_companion_skill(self, fighter: RiftFighter):
        actor = fighter.combatant
        skills = [skill for skill in unlocked_skills(actor) if skill.mana_cost <= actor.stats.current_mana]
        if not skills:
            return None

        tactic = self._companion_tactic(fighter)
        offensive = [skill for skill in skills if skill.is_offensive]
        defensive = [skill for skill in skills if skill.effect in {"guard", "dodge", "provoke"}]
        hp_ratio = actor.stats.current_hp / max(1, actor.stats.max_hp)
        mana_ratio = actor.stats.current_mana / max(1, actor.stats.max_mana) if actor.stats.max_mana > 0 else 1.0
        ally_in_danger = any(
            member.standing
            and member.combatant.stats.current_hp < member.combatant.stats.max_hp * 0.35
            for member in self.all_fighters
        )

        # Obronna aktywnie osłania drużynę. Ciężki Rycerz szczególnie chętnie
        # przejmuje zagrożenie Prowokacją.
        if tactic == "defensive" and defensive and (hp_ratio < 0.80 or ally_in_danger):
            if actor.character_class.code == "warrior" and has_talent(actor, "heavy_knight_core"):
                provoke = next((skill for skill in defensive if skill.skill_id == "provoke"), None)
                if provoke is not None:
                    return provoke
            return defensive[0]

        # Ostrożna oszczędza Manę i reaguje obroną dopiero przy realnym ryzyku.
        if tactic == "cautious":
            if defensive and hp_ratio < 0.50:
                return defensive[0]
            if mana_ratio < 0.25:
                return None

        # Ciężki Rycerz w trybie zrównoważonym nadal reaguje na zagrożenie drużyny.
        if tactic == "balanced" and actor.character_class.code == "warrior" and has_talent(actor, "heavy_knight_core"):
            if ally_in_danger:
                provoke = next((skill for skill in skills if skill.skill_id == "provoke"), None)
                if provoke:
                    return provoke

        # Agresywna wybiera możliwie najmocniejsze ofensywne zagranie.
        if tactic == "aggressive" and offensive:
            return max(offensive, key=lambda skill: skill.multiplier * max(1, skill.hits))

        # Zachowujemy tożsamość klas również dla Zrównoważonej/Ostrożnej.
        if actor.character_class.code == "hunter":
            techniques = [skill for skill in offensive if skill.hunter_technique]
            if techniques:
                return self.rng.choice(techniques)
        if actor.character_class.code == "pierrot":
            fate = [skill for skill in skills if skill.effect and skill.effect.startswith("fate_")]
            if fate:
                return self.rng.choice(fate)
        return max(offensive or skills, key=lambda skill: skill.multiplier * max(1, skill.hits))

    def _companion_turns(self, result: RiftRoundResult) -> None:
        # Jeżeli gracz został powalony, pierwszy zdolny kompan automatycznie
        # poświęca turę na pomoc. Drużyna naprawdę reaguje na siebie.
        player_downed = self.player_fighter.downed_timer > 0 and not self.player_fighter.removed
        helper_used = False
        for fighter in self.companion_fighters:
            if not fighter.standing:
                continue
            if player_downed and not helper_used:
                self.player_fighter.downed_timer = 0
                self.player_fighter.combatant.stats.current_hp = max(1, int(round(self.player.stats.max_hp * 0.25)))
                result.lines.append(f"{fighter.name} porzuca atak i podnosi {self.player.name}!")
                helper_used = True
                continue
            skill = self._choose_companion_skill(fighter)
            if skill is None:
                damage, critical = self._deal_to_enemy(fighter.combatant, fighter.combatant.stats.attack, guaranteed=True)
                result.lines.append(f"{fighter.name} atakuje: {damage}" + (" [KRYTYK]" if critical else "") + ".")
            else:
                self._cast_skill(fighter, skill.skill_id, result.lines)
                # Arkanista ma możliwość prawdziwego drugiego castu.
                if fighter.combatant.character_class.code == "mage" and has_talent(fighter.combatant, "arcana_double_weave") and self.enemy_alive():
                    second = self._choose_companion_skill(fighter)
                    if second is not None and second.skill_id != skill.skill_id and second.mana_cost <= fighter.combatant.stats.current_mana:
                        scale = 0.90 if has_active_class_effect(fighter.combatant, "split_weave") else 0.80
                        result.lines.append(f"{fighter.name}: PODWÓJNY SPLOT!")
                        self._cast_skill(fighter, second.skill_id, result.lines, power_scale=scale)
            if not self.enemy_alive():
                return

    def _enemy_turn(self, result: RiftRoundResult) -> None:
        if not self.enemy_alive():
            return
        if self.enemy_bleed_turns > 0:
            self.enemy_hp = max(0, self.enemy_hp - self.enemy_bleed_damage)
            result.lines.append(f"Krwawienie zadaje {self.enemy_bleed_damage} obrażeń.")
            self.enemy_bleed_turns -= 1
            if not self.enemy_alive():
                return

        standing = self.standing_party()
        if not standing:
            result.defeat = True
            return
        target = None
        if self.taunt_companion_id:
            target = next((fighter for fighter in standing if fighter.companion_id == self.taunt_companion_id), None)
            self.taunt_companion_id = None
        if target is None:
            target = self.rng.choice(standing)

        attacks = 1
        if self.enemy.boss and self.enemy_hp <= self.enemy.max_hp * 0.35:
            attacks = 2
            result.lines.append(f"{self.enemy.name} wpada w FURIĘ — wykonuje dwa ataki!")

        for _ in range(attacks):
            if not target.standing:
                standing = self.standing_party()
                if not standing:
                    break
                target = self.rng.choice(standing)
            # Unik.
            if self.rng.random() < min(70.0, target.combatant.stats.dodge) / 100.0:
                result.lines.append(f"{target.name} unika ataku {self.enemy.name}.")
                continue
            defense = target.combatant.stats.defense
            if has_active_class_effect(target.combatant, "last_guard") and target.combatant.stats.current_hp <= target.combatant.stats.max_hp * 0.35:
                defense = int(round(defense * 1.20))
            damage = calculate_damage(self.enemy.attack, max(0, defense))
            if target.defending:
                damage = max(0, damage // 2)
                if has_active_class_effect(target.combatant, "warden_afterguard"):
                    damage = int(round(damage * 0.85))
            target.defending = False
            taken = target.combatant.stats.take_damage(damage)
            result.lines.append(f"{self.enemy.name} trafia {target.name}: {taken} obrażeń.")
            if target.combatant.stats.current_hp <= 0:
                self._down_fighter(target, result)

    def _down_fighter(self, fighter: RiftFighter, result: RiftRoundResult) -> None:
        if fighter.downed_timer > 0 or fighter.removed:
            return
        lethal = (
            self.enemy.boss
            and self.rift.rank_code in {"B", "A", "S"}
            and not fighter.is_player
        )
        fighter.downed_timer = 3 if lethal else 4
        fighter.lethal_downed = lethal
        if lethal:
            result.lines.append(
                f"{fighter.name} zostaje POWALONY. {self.enemy.name} przygotowuje EGZEKUCJĘ — masz {fighter.downed_timer} rundy na reakcję!"
            )
        else:
            result.lines.append(f"{fighter.name} zostaje POWALONY — {fighter.downed_timer} rundy na pomoc.")

    def _tick_downed(self, result: RiftRoundResult) -> None:
        for fighter in self.all_fighters:
            if fighter.downed_timer <= 0 or fighter.removed:
                continue
            fighter.downed_timer -= 1
            if fighter.downed_timer > 0:
                if fighter.lethal_downed:
                    result.lines.append(f"EGZEKUCJA {fighter.name}: pozostało {fighter.downed_timer} rund.")
                continue
            fighter.removed = True
            if fighter.is_player:
                result.lines.append(f"{fighter.name} nie odzyskuje przytomności. Ekspedycja jest przegrana.")
                result.defeat = True
            elif fighter.lethal_downed:
                result.lines.append(f"EGZEKUCJA. {fighter.name} ginie, ponieważ drużyna nie zdążyła zareagować.")
                result.killed.append(fighter.companion_id or "")
            else:
                result.lines.append(f"{fighter.name} zostaje ciężko ranny i odpada z dalszej walki.")
                result.critically_injured.append(fighter.companion_id or "")

    def _finish_party_round(self, result: RiftRoundResult) -> RiftRoundResult:
        if not self.enemy_alive():
            result.victory = True
            return result
        self._companion_turns(result)
        if not self.enemy_alive():
            result.victory = True
            return result
        self._enemy_turn(result)
        self._tick_downed(result)
        if self.enemy_hp <= 0:
            result.victory = True
        elif not any(fighter.standing or fighter.downed_timer > 0 for fighter in self.all_fighters):
            result.defeat = True
        self.round_number += 1
        return result
