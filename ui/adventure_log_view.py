from game.adventure_log import AdventureLog
from ui.console import print_header


def show_adventure_log(log: AdventureLog) -> None:
    print_header()
    print()
    print("DZIENNIK PRZYGÓD")
    print("-" * 58)

    entries = log.recent(30)
    if not entries:
        print("Dziennik jest jeszcze pusty.")
        return

    for entry in entries:
        print(f"- {entry}")
