import os

from game.config import GAME_TITLE, GAME_VERSION

_WORLD_STATUS: str | None = None


def clear_screen() -> None:
    os.system("cls" if os.name == "nt" else "clear")


def set_world_status(status: str | None) -> None:
    global _WORLD_STATUS
    _WORLD_STATUS = status


def print_header() -> None:
    width = 58
    print("=" * width)
    print(f"{GAME_TITLE:^{width}}")
    print(f"{('v' + GAME_VERSION):^{width}}")
    if _WORLD_STATUS:
        print(f"{('Świat: ' + _WORLD_STATUS):^{width}}")
    print("=" * width)


def pause() -> None:
    input("\nNaciśnij Enter, aby kontynuować...")
