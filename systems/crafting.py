from dataclasses import dataclass
import random

from data.recipes import RECIPE_DATA, RECIPE_ORDER
from items.affixes import EquipmentQuality
from items.catalog import get_item_definition
from items.signature_weapons import is_signature_dungeon_weapon
from player.inventory import Inventory
from player.player import Player


@dataclass(frozen=True)
class Recipe:
    recipe_id: str
    name: str
    output_item_id: str
    output_quantity: int
    ingredients: dict[str, int]
    region: str = "Inne"
    gold_cost: int = 0
    note: str | None = None
    equipment_quality: EquipmentQuality | None = None
    crafting_category: str = "Inne"


def get_recipe(recipe_id: str) -> Recipe:
    if recipe_id not in RECIPE_DATA:
        raise KeyError(f"Nieznana receptura: {recipe_id}")

    data = RECIPE_DATA[recipe_id]

    output_item_id = str(data["output_item_id"])
    output = get_item_definition(output_item_id)
    if output.is_consumable:
        category = "Mikstury i prowiant"
    elif output.is_key:
        category = "Klucze i wejściówki"
    elif output.category.value == "material":
        category = "Materiały i komponenty"
    elif output.is_equipment and is_signature_dungeon_weapon(output_item_id):
        category = "Przedmioty specjalne"
    elif output.is_equipment:
        category = "Wyposażenie ogólne"
    else:
        category = "Przedmioty specjalne"
    category = str(data.get("crafting_category", category))
    return Recipe(
        recipe_id=recipe_id,
        name=str(data["name"]),
        output_item_id=output_item_id,
        output_quantity=int(data.get("output_quantity", 1)),
        ingredients=dict(data["ingredients"]),
        region=str(data.get("region", "Inne")),
        gold_cost=int(data.get("gold_cost", 0)),
        note=(None if data.get("note") is None else str(data["note"])),
        equipment_quality=(None if data.get("equipment_quality") is None else EquipmentQuality[str(data["equipment_quality"]).upper()]),
        crafting_category=category,
    )


def get_all_recipes() -> list[Recipe]:
    return [
        get_recipe(recipe_id)
        for recipe_id in RECIPE_ORDER
    ]


def can_craft(inventory: Inventory, recipe: Recipe) -> bool:
    return all(
        inventory.has(item_id, quantity)
        for item_id, quantity in recipe.ingredients.items()
    )


def craft(
    inventory: Inventory,
    recipe: Recipe,
    rng: random.Random | None = None,
) -> None:
    """Tworzy recepturę bez kosztu Golda na podstawie samego plecaka."""
    if recipe.gold_cost > 0:
        raise ValueError(
            "Ta receptura wymaga Golda i musi być wykonana przez bohatera."
        )

    if not can_craft(inventory, recipe):
        raise ValueError("Brakuje wymaganych składników.")

    # Walidacja outputu przed usunięciem składników.
    get_item_definition(recipe.output_item_id)

    for item_id, quantity in recipe.ingredients.items():
        inventory.remove_item(item_id, quantity)

    output = get_item_definition(recipe.output_item_id)
    if output.is_equipment:
        inventory.add_generated_equipment(
            recipe.output_item_id,
            rng or random.Random(),
            quality=(
                recipe.equipment_quality
                if recipe.equipment_quality is not None
                else (
                    EquipmentQuality.BOSS
                    if is_signature_dungeon_weapon(recipe.output_item_id)
                    else EquipmentQuality.NORMAL
                )
            ),
            quantity=recipe.output_quantity,
        )
    else:
        inventory.add(recipe.output_item_id, recipe.output_quantity)



def can_craft_for_player(player: Player, recipe: Recipe) -> bool:
    return (
        can_craft(player.inventory, recipe)
        and player.gold >= recipe.gold_cost
    )


def craft_for_player(
    player: Player,
    recipe: Recipe,
    rng: random.Random | None = None,
) -> None:
    """Tworzy przedmiot z uwzględnieniem opcjonalnego kosztu w Goldzie.

    Walidacja jest wykonywana przed pobraniem czegokolwiek, więc nieudana
    próba nie może zabrać części materiałów ani Golda.
    """
    if not can_craft(player.inventory, recipe):
        raise ValueError("Brakuje wymaganych składników.")

    if player.gold < recipe.gold_cost:
        raise ValueError(
            f"Brakuje Golda. Potrzeba {recipe.gold_cost}, masz {player.gold}."
        )

    get_item_definition(recipe.output_item_id)

    for item_id, quantity in recipe.ingredients.items():
        player.inventory.remove_item(item_id, quantity)

    player.gold -= recipe.gold_cost
    output = get_item_definition(recipe.output_item_id)
    if output.is_equipment:
        player.inventory.add_generated_equipment(
            recipe.output_item_id,
            rng or random.Random(),
            quality=(
                recipe.equipment_quality
                if recipe.equipment_quality is not None
                else (
                    EquipmentQuality.BOSS
                    if is_signature_dungeon_weapon(recipe.output_item_id)
                    else EquipmentQuality.NORMAL
                )
            ),
            quantity=recipe.output_quantity,
        )
    else:
        player.inventory.add(recipe.output_item_id, recipe.output_quantity)


CRAFTING_CATEGORIES: tuple[str, ...] = (
    "Mikstury i prowiant",
    "Klucze i wejściówki",
    "Materiały i komponenty",
    "Wyposażenie ogólne",
    "Przedmioty specjalne",
)


def recipes_for_category(recipes: list[Recipe], category: str) -> list[Recipe]:
    if category == "Wszystkie receptury":
        return list(recipes)
    return [recipe for recipe in recipes if recipe.crafting_category == category]
