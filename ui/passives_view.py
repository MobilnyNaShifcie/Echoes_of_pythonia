from player.passives import PassiveType, passive_effect_description
from player.player import Player
from data.passive_specializations import PASSIVE_SPECIALIZATIONS, SPECIALIZATIONS_BY_PASSIVE
from player.passive_specializations import can_choose_passive_specialization, specialization_name
from ui.console import print_header


PASSIVE_MENU = {
    "1": PassiveType.ATTACK_SPEED,
    "2": PassiveType.CRITICAL_DAMAGE,
    "3": PassiveType.HEALTH_REGEN,
    "4": PassiveType.INCREASED_ATTACK,
}


def show_passives_menu(player: Player) -> None:
    print_header()
    print()
    print("UMIEJĘTNOŚCI PASYWNE")
    print("-" * 58)
    print(
        f"Wolne punkty: {player.available_passive_points} | "
        "1 punkt co 2 poziomy bohatera"
    )
    print()

    for key, passive in PASSIVE_MENU.items():
        level = player.passives.get(passive)
        print(
            f"[{key}] {passive.display_name:<22} "
            f"{level}/{player.passive_level_cap(passive)}"
        )
        print(f"    {passive_effect_description(passive, level)}")
        if level >= 5 and passive.code not in player.passive_masteries:
            print("    Mistrzostwo 6–10: [WYMAGA KSIĘGI]")
        spec = specialization_name(player, passive.code)
        if spec is not None:
            print(f"    Specjalizacja: {spec}")
        elif can_choose_passive_specialization(player, passive):
            print("    Specjalizacja 10/10: [GOTOWA DO WYBORU]")

    print()
    print("Po wyborze pasywki podasz liczbę punktów albo MAX.")
    print("[0] Powrót")


def get_passive_from_choice(choice: str) -> PassiveType | None:
    return PASSIVE_MENU.get(choice)


def show_passive_specialization_choice(passive: PassiveType) -> list[str]:
    print_header(); print(); print(f"SPECJALIZACJA — {passive.display_name.upper()}"); print("-" * 58)
    options = list(SPECIALIZATIONS_BY_PASSIVE[passive.code])
    for index, spec_id in enumerate(options, start=1):
        spec = PASSIVE_SPECIALIZATIONS[spec_id]
        print(f"[{index}] {spec.name}")
        print(f"    {spec.description}")
    print("[0] Wybiorę później")
    return options
