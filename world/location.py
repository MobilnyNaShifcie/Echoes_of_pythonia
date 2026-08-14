from dataclasses import dataclass

from world.time_system import TimePeriod


@dataclass(frozen=True)
class Location:
    """Definicja pojedynczej lokacji eksploracyjnej."""

    location_id: str
    name: str
    description: str
    danger_rating: int
    recommended_level_min: int
    recommended_level_max: int
    encounter_chance: float
    day_encounters: dict[str, int]
    night_encounters: dict[str, int]
    quiet_events: tuple[str, ...]

    def encounters_for(self, period: TimePeriod) -> dict[str, int]:
        if period is TimePeriod.DAY:
            return self.day_encounters
        return self.night_encounters

    @property
    def recommended_level_text(self) -> str:
        return (
            f"{self.recommended_level_min}-"
            f"{self.recommended_level_max}"
        )
