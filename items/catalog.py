from combat.elements import ElementalResistances
from data.equipment_power import EQUIPMENT_ITEM_POWER
from data.equipment_requirements import EQUIPMENT_REQUIRED_LEVEL
from data.items import ITEM_DATA
from items.models import (
    EquipmentSlot,
    ItemCategory,
    ItemDefinition,
    ItemRarity,
)

_CATEGORY_BY_CODE = {category.value: category for category in ItemCategory}
_RARITY_BY_CODE = {rarity.code: rarity for rarity in ItemRarity}
_SLOT_BY_CODE = {slot.code: slot for slot in EquipmentSlot}


def get_item_definition(item_id: str) -> ItemDefinition:
    if item_id not in ITEM_DATA:
        raise KeyError(f"Nieznany przedmiot: {item_id}")

    data = ITEM_DATA[item_id]
    category = _CATEGORY_BY_CODE[str(data["category"])]
    rarity = _RARITY_BY_CODE[str(data["rarity"])]
    slot_code = data.get("slot")
    slot = None if slot_code is None else _SLOT_BY_CODE[str(slot_code)]

    return ItemDefinition(
        item_id=item_id,
        name=str(data["name"]),
        description=str(data["description"]),
        category=category,
        rarity=rarity,
        stackable=bool(data["stackable"]),
        slot=slot,
        item_power=(EQUIPMENT_ITEM_POWER.get(item_id, 0) if category is ItemCategory.EQUIPMENT else 0),
        required_level=(EQUIPMENT_REQUIRED_LEVEL.get(item_id, 0) if category is ItemCategory.EQUIPMENT else 0),
        attack=int(data.get("attack", 0)),
        defense=int(data.get("defense", 0)),
        max_hp=int(data.get("max_hp", 0)),
        dodge=float(data.get("dodge", 0.0)),
        max_mana=int(data.get("max_mana", 0)),
        magic_power=int(data.get("magic_power", 0)),
        heal_hp=int(data.get("heal_hp", 0)),
        heal_hp_percent=float(data.get("heal_hp_percent", 0.0)),
        restore_mana=int(data.get("restore_mana", 0)),
        restore_mana_percent=float(data.get("restore_mana_percent", 0.0)),
        set_id=(None if data.get("set_id") is None else str(data["set_id"])),
        class_effect_id=(None if data.get("class_effect_id") is None else str(data["class_effect_id"])),
        equipment_type=(None if data.get("equipment_type") is None else str(data["equipment_type"])),
        required_class_code=(None if data.get("required_class") is None else str(data["required_class"])),
        required_class_name=(None if data.get("required_class_name") is None else str(data["required_class_name"])),
        class_bonus_class_code=(None if data.get("class_bonus_class") is None else str(data["class_bonus_class"])),
        class_bonus_attack=int(data.get("class_bonus_attack", 0)),
        class_bonus_defense=int(data.get("class_bonus_defense", 0)),
        class_bonus_max_hp=int(data.get("class_bonus_max_hp", 0)),
        class_bonus_max_mana=int(data.get("class_bonus_max_mana", 0)),
        class_bonus_dodge=float(data.get("class_bonus_dodge", 0.0)),
        resistances=ElementalResistances(
            fire=int(data.get("fire_resistance", 0)),
            wind=int(data.get("wind_resistance", 0)),
            frost=int(data.get("frost_resistance", 0)),
            earth=int(data.get("earth_resistance", 0)),
            water=int(data.get("water_resistance", 0)),
        ),
    )


def item_exists(item_id: str) -> bool:
    return item_id in ITEM_DATA
