from player.player import Player
from systems.region_boss_respawn import respawn_remaining
from ui.console import print_header
from world.location import Location
from world.time_system import GameClock


def _danger_stars(rating: int, maximum: int = 5) -> str:
    safe_rating = max(0, min(rating, maximum))
    return "★" * safe_rating + "☆" * (maximum - safe_rating)


def _expedition_count_text(count: int) -> str:
    count = max(0, int(count))
    last_two = count % 100
    last = count % 10
    if count == 1:
        noun = "wyprawa"
    elif 2 <= last <= 4 and not 12 <= last_two <= 14:
        noun = "wyprawy"
    else:
        noun = "wypraw"
    return f"{count} {noun}"


def show_world_map(
    player: Player,
    locations: list[Location],
    clock: GameClock,
) -> None:
    print_header()
    print()
    print("MAPA ŚWIATA")
    print("-" * 58)
    print(
        f"{clock.formatted_time()} | {clock.period.display_name} "
        f"| Poziom bohatera: {player.level}"
    )
    print()

    for index, location in enumerate(locations, start=1):
        warning = (
            "  [RYZYKO]"
            if player.level < location.recommended_level_min
            else ""
        )
        print(f"[{index}] {location.name}{warning}")
        print(
            f"    Zagrożenie: {_danger_stars(location.danger_rating)} "
            f"| Zalecany poziom: {location.recommended_level_text}"
        )

    print()
    print("Dalsze szlaki pozostają jeszcze nieodkryte.")
    print()
    print(
        "Poziom jest tylko zaleceniem. "
        "Gra nie blokuje wejścia do trudniejszych regionów."
    )
    print()
    print("[0] Powrót")


def show_location_menu(
    player: Player,
    location: Location,
    clock: GameClock,
    region_boss_respawns: dict[str, int] | None = None,
    *,
    camp_rest_available: bool = True,
) -> None:
    print_header()
    print()
    print(location.name.upper())
    print("-" * 58)
    print(f"{clock.formatted_time()} | {clock.period.display_name}")
    print(
        f"Zagrożenie: {_danger_stars(location.danger_rating)} "
        f"| Zalecany poziom: {location.recommended_level_text}"
    )
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} "
        f"| Gold {player.gold} | Poziom {player.level}"
    )

    if player.level < location.recommended_level_min:
        print("UWAGA: ten region przewyższa obecny poziom bohatera.")

    print()
    print(location.description)
    print()
    print("[1] Wyrusz na wyprawę        (czas: 1 godzina)")
    if camp_rest_available:
        print("[2] Odpocznij przy ognisku   (+25% HP / +35% Many, czas: 2 godziny)")
    else:
        print("[2] Odpocznij przy ognisku   [DOSTĘPNY PO KOLEJNEJ WYPRAWIE/WALCE]")
    if location.location_id == "silentwater_marshes":
        print("[3] Krypta Zatopionego Zakonu [DUNGEON | poziom 7-10]")
    elif location.location_id == "ashen_borderlands":
        respawns = region_boss_respawns or {}
        remaining = respawn_remaining(respawns, "azhar")
        if remaining > 0:
            print(
                f"[3] Azhar, Władca Pustkowi "
                f"[Odrodzenie: {_expedition_count_text(remaining)}]"
            )
        else:
            print("[3] Azhar, Władca Pustkowi [BOSS | poziom 14+]")
    elif location.location_id == "ice_coast":
        respawns = region_boss_respawns or {}
        remaining = respawn_remaining(respawns, "leviathan_north")
        if remaining > 0:
            print(
                f"[3] Lewiatan Północy "
                f"[Odrodzenie: {_expedition_count_text(remaining)}]"
            )
        else:
            print("[3] Lewiatan Północy [BOSS | poziom 18+]")
        print("[4] Wrak Czarnej Floty [DUNGEON | poziom 16-20]")
    print("[0] Wróć na mapę")
    print()


def show_quiet_exploration(message: str) -> None:
    print_header()
    print()
    print("WYPRAWA")
    print("-" * 58)
    print(message)


def show_rest_result(
    *,
    healed_hp: int = 0,
    restored_mana: int = 0,
    message: str | None = None,
) -> None:
    print_header()
    print()
    print("OGNISKO")
    print("-" * 58)

    if message is not None:
        print(message)
        return

    print("Odpoczywasz przy ogniu.")
    print(f"Odzyskano: +{healed_hp} HP, +{restored_mana} Many.")
    print("Mijają 2 godziny.")
    print("Kolejny darmowy odpoczynek odblokuje następna wyprawa lub walka.")


def show_region_boss_respawn(
    boss_name: str,
    location_name: str,
    remaining: int,
) -> None:
    print_header()
    print()
    print("ODRODZENIE BOSSA")
    print("-" * 58)
    print(boss_name.upper())
    print()
    print("Boss jeszcze się nie odrodził.")
    print(
        f"Wykonaj jeszcze {_expedition_count_text(remaining)} "
        f"w regionie {location_name}."
    )


def show_region_boss_challenge(
    player: Player,
    boss_name: str,
    recommended_level: int,
) -> None:
    print_header()
    print()
    print("WYZWANIE BOSSA")
    print("-" * 58)
    print(boss_name.upper())
    print(f"Zalecany poziom: {recommended_level}+")
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} "
        f"| Poziom {player.level}"
    )
    if player.level < recommended_level:
        print("UWAGA: ten przeciwnik przewyższa obecny poziom bohatera.")
    print()
    print(f"Walka z {boss_name} rozpocznie się natychmiast.")
    print()
    print("[1] Podejmij wyzwanie")
    print("[0] Wycofaj się")
