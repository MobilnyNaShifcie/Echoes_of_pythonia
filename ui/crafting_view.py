from items.affixes import item_power_display
from items.catalog import get_item_definition
from player.player import Player
from systems.crafting import CRAFTING_CATEGORIES, Recipe, can_craft_for_player
from ui.console import print_header


def _ingredient_line(
    player: Player,
    item_id: str,
    required: int,
) -> str:
    definition = get_item_definition(item_id)
    owned = player.inventory.count(item_id)
    marker = "OK" if owned >= required else "BRAK"

    return (
        f"      - {definition.name}: "
        f"{owned}/{required} [{marker}]"
    )


def show_crafting_menu(
    player: Player,
    recipes: list[Recipe],
) -> None:
    print_header()
    print()
    print("CRAFTING")
    print("-" * 58)
    print(
        "Receptury zużywają materiały z plecaka. "
        "Założone wyposażenie nie jest automatycznie rozbierane."
    )
    print()

    current_region = None

    for index, recipe in enumerate(recipes, start=1):
        if recipe.region != current_region:
            current_region = recipe.region
            print(f"=== {current_region.upper()} ===")
            print()

        output = get_item_definition(recipe.output_item_id)
        status = (
            "GOTOWE"
            if can_craft_for_player(player, recipe)
            else "BRAK WYMAGANYCH ZASOBÓW"
        )

        equipment_note = ""
        if output.is_equipment:
            equipment_note = (
                f" | IP {item_power_display(output.item_power)}"
                f" | Wym. poz. {output.required_level}"
            )
        print(
            f"[{index}] {recipe.name} "
            f"[{output.rarity.display_name}{equipment_note}] [{status}]"
        )

        for item_id, quantity in recipe.ingredients.items():
            print(_ingredient_line(player, item_id, quantity))

        if recipe.gold_cost > 0:
            marker = "OK" if player.gold >= recipe.gold_cost else "BRAK"
            print(
                f"      - Gold: {player.gold}/{recipe.gold_cost} "
                f"[{marker}]"
            )

        if recipe.note:
            print(f"      Uwaga: {recipe.note}")

        print()

    print("[0] Powrót")


def show_crafting_category_menu(player: Player) -> list[str]:
    print_header(); print(); print("WARSZTAT MIRELI — CRAFTING"); print("-" * 58)
    print("Receptury są pogrupowane, aby warsztat pozostał czytelny wraz z rozwojem świata.")
    print()
    categories = list(CRAFTING_CATEGORIES) + ["Wszystkie receptury"]
    for index, category in enumerate(categories, start=1):
        print(f"[{index}] {category}")
    print("[0] Powrót")
    return categories
