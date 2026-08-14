from __future__ import annotations

from dataclasses import dataclass

from data.dungeons import DUNGEON_DATA
from data.recipes import RECIPE_DATA, RECIPE_ORDER
from items.catalog import get_item_definition
from items.models import ItemCategory


@dataclass(frozen=True)
class ItemUsage:
    item_id: str
    recipe_names: tuple[str, ...] = ()
    dungeon_names: tuple[str, ...] = ()
    effect_lines: tuple[str, ...] = ()

    @property
    def has_gameplay_use(self) -> bool:
        return bool(self.recipe_names or self.dungeon_names or self.effect_lines)


def _consumable_effect_lines(item_id: str) -> tuple[str, ...]:
    definition = get_item_definition(item_id)
    lines: list[str] = []
    if definition.heal_hp:
        lines.append(f"Przywraca {definition.heal_hp} HP.")
    if definition.heal_hp_percent:
        lines.append(f"Przywraca {definition.heal_hp_percent:g}% maksymalnego HP.")
    if definition.restore_mana:
        lines.append(f"Przywraca {definition.restore_mana} Many.")
    if definition.restore_mana_percent:
        lines.append(f"Przywraca {definition.restore_mana_percent:g}% maksymalnej Many.")
    return tuple(lines)


def get_item_usage(item_id: str) -> ItemUsage:
    definition = get_item_definition(item_id)

    recipe_names: list[str] = []
    for recipe_id in RECIPE_ORDER:
        recipe = RECIPE_DATA[recipe_id]
        if item_id in dict(recipe["ingredients"]):
            recipe_names.append(str(recipe["name"]))

    dungeon_names: list[str] = []
    for dungeon in DUNGEON_DATA.values():
        if dungeon.get("entry_item_id") == item_id:
            dungeon_names.append(str(dungeon["name"]))

    effect_lines: tuple[str, ...] = ()
    if definition.category is ItemCategory.CONSUMABLE:
        effect_lines = _consumable_effect_lines(item_id)
    elif definition.category is ItemCategory.BOOK:
        effect_lines = ("Księga może zostać przeczytana w menu Księgi.",)
    elif definition.category is ItemCategory.EQUIPMENT:
        effect_lines = ("Przedmiot może zostać założony jako wyposażenie.",)

    return ItemUsage(
        item_id=item_id,
        recipe_names=tuple(recipe_names),
        dungeon_names=tuple(dungeon_names),
        effect_lines=effect_lines,
    )


def audit_stackable_gameplay_uses() -> dict[str, ItemUsage]:
    """Zwraca stackowalne materiały/klucze bez widocznego zastosowania."""
    from data.items import ITEM_DATA

    missing: dict[str, ItemUsage] = {}
    for item_id, raw in ITEM_DATA.items():
        category = str(raw["category"])
        if category not in {"material", "key"}:
            continue
        usage = get_item_usage(item_id)
        if not usage.has_gameplay_use:
            missing[item_id] = usage
    return missing
