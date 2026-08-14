from data.locations import LOCATION_DATA, LOCATION_ORDER
from world.location import Location


def create_location(location_id: str) -> Location:
    """Tworzy definicję lokacji na podstawie danych."""
    if location_id not in LOCATION_DATA:
        raise KeyError(f"Nieznana lokacja: {location_id}")

    data = LOCATION_DATA[location_id]

    return Location(
        location_id=location_id,
        name=str(data["name"]),
        description=str(data["description"]),
        danger_rating=int(data["danger_rating"]),
        recommended_level_min=int(data["recommended_level_min"]),
        recommended_level_max=int(data["recommended_level_max"]),
        encounter_chance=float(data["encounter_chance"]),
        day_encounters=dict(data["day_encounters"]),
        night_encounters=dict(data["night_encounters"]),
        quiet_events=tuple(data["quiet_events"]),
    )


def create_world_locations() -> list[Location]:
    """Zwraca lokacje w kolejności używanej przez mapę świata."""
    return [
        create_location(location_id)
        for location_id in LOCATION_ORDER
    ]
