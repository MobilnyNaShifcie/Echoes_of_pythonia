from dataclasses import dataclass


@dataclass(frozen=True)
class City:
    city_id: str
    name: str
    description: str
    gate_name: str
    blacksmith_name: str
    workshop_name: str
    merchant_name: str
    inn_name: str
    guild_name: str
    rumors: tuple[str, ...]
