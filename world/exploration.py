from dataclasses import dataclass
import random

from world.location import Location
from world.time_system import TimePeriod


@dataclass(frozen=True)
class ExplorationResult:
    enemy_id: str | None = None
    message: str = ""

    @property
    def has_encounter(self) -> bool:
        return self.enemy_id is not None


def explore_location(
    location: Location,
    period: TimePeriod,
    rng: random.Random,
) -> ExplorationResult:
    """Losuje wynik pojedynczej wyprawy w lokacji."""
    if not 0.0 <= location.encounter_chance <= 1.0:
        raise ValueError("Szansa spotkania musi mieścić się w zakresie 0-1.")

    if rng.random() >= location.encounter_chance:
        message = rng.choice(location.quiet_events)
        return ExplorationResult(message=message)

    encounter_table = location.encounters_for(period)

    if not encounter_table:
        return ExplorationResult(
            message="Droga pozostaje niepokojąco pusta."
        )

    enemy_ids = list(encounter_table.keys())
    weights = list(encounter_table.values())
    enemy_id = rng.choices(enemy_ids, weights=weights, k=1)[0]

    return ExplorationResult(enemy_id=enemy_id)
