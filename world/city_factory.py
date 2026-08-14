from data.cities import CITY_DATA
from world.city import City


def create_city(city_id: str) -> City:
    if city_id not in CITY_DATA:
        raise KeyError(f"Nieznane miasto: {city_id}")

    data = CITY_DATA[city_id]
    return City(
        city_id=city_id,
        name=str(data["name"]),
        description=str(data["description"]),
        gate_name=str(data["gate_name"]),
        blacksmith_name=str(data["blacksmith_name"]),
        workshop_name=str(data["workshop_name"]),
        merchant_name=str(data["merchant_name"]),
        inn_name=str(data["inn_name"]),
        guild_name=str(data["guild_name"]),
        rumors=tuple(data["rumors"]),
    )
