from player.attributes import (
    AttributeType,
    attribute_effect_description,
)
from player.player import Player
from ui.console import print_header


BASE_ATTRIBUTE_MENU = {
    "1": AttributeType.STRENGTH,
    "2": AttributeType.VITALITY,
    "3": AttributeType.INTELLIGENCE,
    "4": AttributeType.DEXTERITY,
    "5": AttributeType.ENDURANCE,
}


def attribute_menu_for_player(player: Player | None = None):
    menu = dict(BASE_ATTRIBUTE_MENU)
    if player is not None and player.character_class.code == "pierrot":
        menu["6"] = AttributeType.LUCK
    return menu


def show_attribute_menu(player: Player) -> None:
    print_header()
    print()
    print("ROZWÓJ BOHATERA")
    print("-" * 58)
    print(f"Wolne punkty: {player.unspent_attribute_points}")
    print()
    print(
        f"ATK {player.stats.attack} | "
        f"DEF {player.stats.defense} | "
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"MANA {player.stats.current_mana}/{player.stats.max_mana} | "
        f"UNIK {player.stats.dodge:.1f}%"
    )
    print()

    for key, attribute in attribute_menu_for_player(player).items():
        value = player.attributes.get(attribute)
        effect = attribute_effect_description(attribute)
        print(
            f"[{key}] {attribute.display_name:<14} "
            f"{value:<3} | {effect}"
        )

    print()
    print("Po wyborze atrybutu podasz liczbę punktów albo MAX.")
    print("[0] Powrót")


def get_attribute_from_choice(choice: str, player: Player | None = None) -> AttributeType | None:
    return attribute_menu_for_player(player).get(choice)
