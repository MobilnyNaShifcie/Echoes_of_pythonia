from player.achievements import ACHIEVEMENTS, DEFAULT_TITLE
from player.player import Player
from ui.console import print_header


def show_achievement_menu(player: Player) -> str:
    while True:
        print_header()
        print()
        print("OSIĄGNIĘCIA I TYTUŁY")
        print("-" * 58)
        print(f"Aktualny tytuł: {player.achievements.equipped_title}")
        print(
            f"Osiągnięcia: {len(player.achievements.unlocked)}/"
            f"{len(ACHIEVEMENTS)}"
        )
        print()
        print("[1] Lista osiągnięć")
        print("[2] Wybierz tytuł")
        print("[0] Powrót")
        print()
        choice = input("> ").strip()
        if choice in {"1", "2", "0"}:
            return choice
        print("\nNieprawidłowa opcja.")
        input("Naciśnij Enter...")


def show_achievements(player: Player) -> None:
    print_header()
    print()
    print("OSIĄGNIĘCIA")
    print("-" * 58)

    for achievement in ACHIEVEMENTS:
        unlocked = achievement.achievement_id in player.achievements.unlocked
        status = "ODBLOKOWANE" if unlocked else "ZABLOKOWANE"
        print(f"- {achievement.name} [{status}]")
        print(f"  {achievement.description}")
        print(f"  Tytuł: {achievement.title}")
        print()


def show_titles(player: Player) -> list[str]:
    print_header()
    print()
    print("TYTUŁY")
    print("-" * 58)
    titles = player.achievements.available_titles()

    for index, title in enumerate(titles, start=1):
        marker = " [AKTYWNY]" if title == player.achievements.equipped_title else ""
        print(f"[{index}] {title}{marker}")

    print("\n[0] Powrót")
    return titles
