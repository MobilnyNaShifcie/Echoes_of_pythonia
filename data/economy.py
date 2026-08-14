MERCHANT_STOCK: tuple[dict[str, object], ...] = (
    {"item_id": "weak_healing_potion", "buy_price": 25},
    {"item_id": "weak_leather", "buy_price": 30},
    {"item_id": "old_clothes", "buy_price": 20},
    {"item_id": "whetstone", "buy_price": 60},
    {"item_id": "grinding_stone", "buy_price": 160},
    {"item_id": "grandmaster_elixir", "buy_price": 2500},
)

MATERIAL_SELL_BASE: dict[str, int] = {
    "common": 4,
    "uncommon": 10,
    "rare": 25,
    "epic": 60,
    "legendary": 150,
    "mythic": 350,
}

CONSUMABLE_SELL_BASE: dict[str, int] = {
    "common": 8,
    "uncommon": 18,
    "rare": 40,
    "epic": 90,
    "legendary": 220,
    "mythic": 500,
}

EQUIPMENT_SELL_BASE: dict[str, int] = {
    "common": 15,
    "uncommon": 30,
    "rare": 60,
    "epic": 150,
    "legendary": 400,
    "mythic": 1000,
}
