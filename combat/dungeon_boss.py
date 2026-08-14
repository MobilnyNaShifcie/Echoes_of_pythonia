from combat.combat import CombatEngine, CombatResult, TurnReport
from combat.elements import DamageType, apply_elemental_resistance


class GrandMasterCombatEngine(CombatEngine):
    """Trzyfazowa walka z Wielkim Mistrzem Zatopionego Zakonu."""

    def __init__(self, player, enemy, rng=None) -> None:
        super().__init__(player, enemy, rng)
        self.phase = 1

    def _enemy_turn(
        self,
        report: TurnReport,
        defending: bool = False,
    ) -> None:
        self._update_phase(report)
        super()._enemy_turn(report, defending=defending)

        if (
            self.phase >= 3
            and self.result is CombatResult.ONGOING
            and self.enemy.is_alive
            and self.player.stats.is_alive
        ):
            aura_damage = apply_elemental_resistance(
                2,
                DamageType.WATER,
                self.player.stats.resistances,
            )
            report.boss_aura_damage = self.player.stats.take_damage(
                aura_damage
            )
            if not self.player.stats.is_alive:
                self.result = CombatResult.DEFEAT

    def _update_phase(self, report: TurnReport) -> None:
        hp_ratio = self.enemy.current_hp / self.enemy.max_hp

        if self.phase < 2 and hp_ratio <= 0.60:
            self.phase = 2
            self.enemy.attack += 3
            self.enemy.defense = max(0, self.enemy.defense - 3)
            report.boss_notes.append(
                "FAZA II: Wielki Mistrz roztrzaskuje tarczę — "
                "ATK +3, DEF -3."
            )

        if self.phase < 3 and hp_ratio <= 0.25:
            self.phase = 3
            report.boss_notes.append(
                "FAZA III: Klątwa Głębin budzi się — po każdej turze "
                "zadaje dodatkowe obrażenia od Wody."
            )


class AdmiralVarekCombatEngine(CombatEngine):
    """Trzyfazowy pojedynek z Admirałem Varekiem.

    Faza II wprowadza zapowiadaną Salwę Armatnią. Ostrzeżenie pozostaje
    widoczne aż do następnej akcji gracza, więc Obrona jest świadomą
    odpowiedzią, a nie zgadywaniem. Faza III kończy salwy i zmienia walkę
    w agresywny pojedynek na szable.
    """

    def __init__(self, player, enemy, rng=None) -> None:
        super().__init__(player, enemy, rng)
        self.phase = 1
        self.cannon_pending = False
        self.normal_turns_since_salvo = 0
        self.phase_three_crit_chance = 0.20

    def status_lines(self) -> tuple[str, ...]:
        class_lines = super().class_status_lines()
        if self.cannon_pending and self.phase == 2:
            return (
                "[UWAGA] Kanonierzy celują — nadchodzi Salwa Armatnia!",
                "        Obrona znacząco zmniejszy obrażenia salwy.",
                *class_lines,
            )
        return class_lines

    def _enemy_turn(
        self,
        report: TurnReport,
        defending: bool = False,
    ) -> None:
        self._update_phase(report)

        if self.phase == 2 and self.cannon_pending:
            self._fire_cannon_salvo(report, defending)
            return

        if self.phase >= 3:
            self._phase_three_turn(report, defending)
            return

        super()._enemy_turn(report, defending=defending)
        if self.phase == 2 and self.result is CombatResult.ONGOING:
            self.normal_turns_since_salvo += 1
            if self.normal_turns_since_salvo >= 2:
                self.cannon_pending = True
                report.boss_notes.append(
                    "Kanonierzy Czarnej Floty przygotowują salwę. "
                    "Następny atak Vareka zostanie zastąpiony ostrzałem."
                )

    def _fire_cannon_salvo(
        self,
        report: TurnReport,
        defending: bool,
    ) -> None:
        original_name = self.enemy.special_name
        original_chance = self.enemy.special_chance
        original_bonus = self.enemy.special_attack_bonus
        original_type = self.enemy.special_damage_type

        self.enemy.special_name = "Salwa Armatnia"
        self.enemy.special_chance = 1.0
        self.enemy.special_attack_bonus = 24
        self.enemy.special_damage_type = DamageType.PHYSICAL

        try:
            report.boss_notes.append(
                "SALWA ARMATNIA: działa okrętu flagowego otwierają ogień!"
            )
            super()._enemy_turn(report, defending=defending)
        finally:
            self.enemy.special_name = original_name
            self.enemy.special_chance = original_chance
            self.enemy.special_attack_bonus = original_bonus
            self.enemy.special_damage_type = original_type
            self.cannon_pending = False
            self.normal_turns_since_salvo = 0

    def _phase_three_turn(
        self,
        report: TurnReport,
        defending: bool,
    ) -> None:
        original_attack = self.enemy.attack
        critical = self.rng.random() < self.phase_three_crit_chance
        if critical:
            bonus = max(1, int(round(original_attack * 0.50)))
            self.enemy.attack += bonus
            report.boss_notes.append(
                "KRYTYCZNE CIĘCIE: desperacki zamach Vareka zyskuje "
                f"+{bonus} siły."
            )
        try:
            super()._enemy_turn(report, defending=defending)
        finally:
            self.enemy.attack = original_attack

    def _update_phase(self, report: TurnReport) -> None:
        hp_ratio = self.enemy.current_hp / self.enemy.max_hp

        if self.phase < 2 and hp_ratio <= 0.60:
            self.phase = 2
            self.normal_turns_since_salvo = 0
            report.boss_notes.append(
                "FAZA II: Dowódca Czarnej Floty — Varek wydaje rozkaz "
                "kanonierom. Co kilka tur salwa zostanie zapowiedziana."
            )

        if self.phase < 3 and hp_ratio <= 0.25:
            self.phase = 3
            self.cannon_pending = False
            self.normal_turns_since_salvo = 0
            self.enemy.attack += 10
            self.enemy.defense = max(0, self.enemy.defense - 8)
            report.boss_notes.append(
                "FAZA III: Ostatni Rozkaz — Varek porzuca dowodzenie, "
                "zyskuje +10 ATK, traci 8 DEF i może wykonywać "
                "krytyczne cięcia."
            )
