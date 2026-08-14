from __future__ import annotations

from dataclasses import dataclass
import random


@dataclass(frozen=True)
class FateRoll:
    dice: tuple[int, ...]
    original_dice: tuple[int, ...]
    notes: tuple[str, ...] = ()

    @property
    def total(self) -> int:
        return sum(self.dice)

    @property
    def is_double(self) -> bool:
        return len(self.dice) >= 2 and len(set(self.dice)) < len(self.dice)

    @property
    def is_triple(self) -> bool:
        return len(self.dice) == 3 and len(set(self.dice)) == 1


class FateEngine:
    """Jedno źródło losu dla Pierrota.

    Mechanika nadal korzysta z generatora pseudolosowego Pythona, ale cała
    logika Kości Losu, historii i manipulacji Fortuny przechodzi przez ten
    moduł zamiast rozproszonych wywołań random.* w klasie Pierrota.
    """

    def __init__(self, rng: random.Random, luck: int = 0) -> None:
        self.rng = rng
        self.luck = max(0, int(luck))
        self.history: list[FateRoll] = []
        self.loaded_die_used = False
        self.second_chance_used = False


    def chance(self, probability: float) -> bool:
        """Losuje zdarzenie Pierrota przez centralny silnik Losu."""
        probability = min(1.0, max(0.0, float(probability)))
        return self.rng.random() < probability

    def roll(
        self,
        count: int,
        *,
        loaded_die: bool = False,
        second_chance: bool = False,
        cheat_to_seven: bool = False,
        fate_tokens: int = 0,
    ) -> tuple[FateRoll, int]:
        if count <= 0:
            raise ValueError("Liczba kości musi być dodatnia.")
        original = tuple(self.rng.randint(1, 6) for _ in range(count))
        dice = list(original)
        notes: list[str] = []

        if loaded_die and not self.loaded_die_used and 1 in dice:
            index = dice.index(1)
            rerolled = self.rng.randint(1, 6)
            dice[index] = rerolled
            self.loaded_die_used = True
            notes.append(f"Dociążona Kość: 1 → {rerolled}.")

        if second_chance and count == 3 and sum(dice) <= 5 and not self.second_chance_used:
            before = tuple(dice)
            dice = [self.rng.randint(1, 6) for _ in range(count)]
            self.second_chance_used = True
            notes.append(
                "Druga Szansa: katastrofalny rzut "
                f"{'+'.join(map(str, before))} został przerzucony."
            )

        spent = 0
        if cheat_to_seven and count == 2 and sum(dice) in {6, 8} and fate_tokens > 0:
            # Zmieniamy dokładnie jedną kość o 1 w stronę sumy 7.
            delta = 1 if sum(dice) == 6 else -1
            candidates = [i for i, value in enumerate(dice) if 1 <= value + delta <= 6]
            if candidates:
                index = candidates[0]
                before = dice[index]
                dice[index] += delta
                spent = 1
                notes.append(f"Kant: {before} → {dice[index]}; suma zostaje ustawiona na 7.")

        roll = FateRoll(tuple(dice), original, tuple(notes))
        self.history.append(roll)
        return roll, spent
