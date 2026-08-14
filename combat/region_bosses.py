from combat.combat import CombatEngine, TurnReport


class HearthDevourerCombatEngine(CombatEngine):
    """Rosnące zagrożenie Pożeracza Palenisk podczas dłuższej walki."""

    def __init__(self, player, enemy, rng=None) -> None:
        super().__init__(player, enemy, rng)
        self.heat_stacks = 0
        self.frenzy_triggered = False

    def _enemy_turn(
        self,
        report: TurnReport,
        defending: bool = False,
    ) -> None:
        # Co trzy wykonane ataki Pożeracz podkręca żar. Limit dwóch stosów
        # zapobiega nieskończonemu skalowaniu przy bardzo defensywnym buildzie.
        if self.enemy.attacks_made in {3, 6} and self.heat_stacks < 2:
            self.heat_stacks += 1
            self.enemy.attack += 2
            report.boss_notes.append(
                f"Rozżarzenie {self.heat_stacks}/2: "
                "Pożeracz Palenisk zyskuje +2 ATK."
            )

        hp_ratio = self.enemy.current_hp / self.enemy.max_hp
        if not self.frenzy_triggered and hp_ratio <= 0.30:
            self.frenzy_triggered = True
            self.enemy.attack += 4
            self.enemy.defense = max(0, self.enemy.defense - 2)
            report.boss_notes.append(
                "SZAŁ PALENISKA: Pożeracz Palenisk zyskuje +4 ATK, "
                "ale traci 2 DEF."
            )

        super()._enemy_turn(report, defending=defending)


class AzharCombatEngine(CombatEngine):
    """Trzyfazowa walka z Azharem, Władcą Pustkowi."""

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

    def _update_phase(self, report: TurnReport) -> None:
        hp_ratio = self.enemy.current_hp / self.enemy.max_hp

        if self.phase < 2 and hp_ratio <= 0.60:
            self.phase = 2
            self.enemy.attack += 2
            self.enemy.dodge = min(95.0, self.enemy.dodge + 10.0)
            report.boss_notes.append(
                "FAZA II: Burza Piaskowa — Azhar zyskuje +2 ATK "
                "i +10 p.p. Uniku."
            )

        if self.phase < 3 and hp_ratio <= 0.25:
            self.phase = 3
            self.enemy.attack += 6
            self.enemy.defense = max(0, self.enemy.defense - 4)
            report.boss_notes.append(
                "FAZA III: Gniew Pustkowi — Azhar zyskuje +6 ATK, "
                "ale traci 4 DEF."
            )


class LeviathanNorthCombatEngine(CombatEngine):
    """Trzyfazowa walka z Lewiatanem Północy."""

    def __init__(self, player, enemy, rng=None) -> None:
        super().__init__(player, enemy, rng)
        self.phase = 1

    def _enemy_turn(self, report: TurnReport, defending: bool = False) -> None:
        self._update_phase(report)
        super()._enemy_turn(report, defending=defending)

    def _update_phase(self, report: TurnReport) -> None:
        hp_ratio = self.enemy.current_hp / self.enemy.max_hp
        if self.phase < 2 and hp_ratio <= 0.60:
            self.phase = 2
            self.enemy.attack += 4
            self.enemy.defense += 4
            report.boss_notes.append(
                "FAZA II: Wzburzone Morze — Lewiatan zyskuje +4 ATK i +4 DEF."
            )
        if self.phase < 3 and hp_ratio <= 0.25:
            self.phase = 3
            self.enemy.attack += 10
            self.enemy.defense = max(0, self.enemy.defense - 8)
            report.boss_notes.append(
                "FAZA III: Gniew Lewiatana — Lewiatan zyskuje +10 ATK, ale traci 8 DEF."
            )

