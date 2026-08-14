from items.catalog import get_item_definition
from items.loot import LootDrop
from player.player import Player
from ui.console import print_header
from world.dungeon import DungeonDefinition, DungeonLootChange


def show_dungeon_entrance(player: Player, dungeon: DungeonDefinition) -> None:
    print_header()
    print()
    print(dungeon.name.upper())
    print("-" * 58)
    print(
        f"Zalecany poziom: {dungeon.recommended_level_text} | "
        f"Twój poziom: {player.level}"
    )
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"Mana {player.stats.current_mana}/{player.stats.max_mana}"
    )
    print()
    print(dungeon.description)

    if dungeon.entry_item_id is not None:
        key = get_item_definition(dungeon.entry_item_id)
        owned = player.inventory.count(dungeon.entry_item_id)
        required = max(1, dungeon.entry_item_quantity)
        print()
        print("WEJŚCIÓWKA:")
        print(f"- {key.name}: {owned}/{required}")
        if dungeon.entry_source_text:
            print(f"- Źródła: {dungeon.entry_source_text}")

    print()
    print("ZASADY WYPRAWY:")
    print("- HP i Mana przechodzą między komnatami.")
    print("- Wycofanie się zabezpiecza zdobyty łup.")
    print("- Porażka usuwa tylko niezabezpieczony łup z tej wyprawy.")
    print("- Gold i EXP zdobyte w dungeonie pozostają nawet po porażce.")
    print()
    if dungeon.entry_item_id is None:
        print("[1] Wejdź do dungeonu")
    else:
        key = get_item_definition(dungeon.entry_item_id)
        print(f"[1] Użyj: {key.name} i wejdź do dungeonu")
    print("[0] Wróć")


def show_dungeon_room(title: str, description: str) -> None:
    print_header()
    print()
    print(title.upper())
    print("-" * 58)
    print(description)


def show_dungeon_scene(title: str, description: str) -> None:
    """Show a narrative-only dungeon beat without changing game state."""
    print_header()
    print()
    print(title.upper())
    print("-" * 58)
    print(description)


def ask_continue_or_retreat(player: Player) -> str:
    print()
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"Mana {player.stats.current_mana}/{player.stats.max_mana}"
    )
    print()
    print("[1] Idź głębiej")
    print("[0] Wycofaj się do Varenhold i zabezpiecz łup")
    while True:
        choice = input("> ").strip()
        if choice in {"0", "1"}:
            return choice
        print("Nieprawidłowa opcja. Wybierz 1 albo 0.")


def ask_crossroads() -> str:
    print_header()
    print()
    print("ROZWIDLENIE KRYPTY")
    print("-" * 58)
    print("Przed tobą znajdują się dwie drogi.")
    print()
    print("[1] Żelazne wrota")
    print("    Słychać ciężkie kroki. Droga jest niebezpieczna, ale strzeżona.")
    print()
    print("[2] Zalany korytarz")
    print("    W oddali widać starą skrzynię. Woda skrywa to, co czai się pod powierzchnią.")
    print()
    print("[0] Wycofaj się do Varenhold")
    while True:
        choice = input("> ").strip()
        if choice in {"0", "1", "2"}:
            return choice
        print("Nieprawidłowa opcja. Wybierz 1, 2 albo 0.")


def ask_shrine(player: Player) -> str:
    print_header()
    print()
    print("ZATOPIONA KAPLICA")
    print("-" * 58)
    print("W kamiennej misie wciąż lśni błękitna woda.")
    print("Możesz skorzystać z niej tylko raz podczas tej wyprawy.")
    print()
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"Mana {player.stats.current_mana}/{player.stats.max_mana}"
    )
    print()
    print("[1] Napij się — odzyskaj 25% maks. HP i Many")
    print("[2] Zostaw wodę i idź dalej")
    while True:
        choice = input("> ").strip()
        if choice in {"1", "2"}:
            return choice
        print("Nieprawidłowa opcja. Wybierz 1 albo 2.")


def show_shrine_result(healed_hp: int, restored_mana: int) -> None:
    print()
    if healed_hp == 0 and restored_mana == 0:
        print("Woda nie może już niczego ci przywrócić.")
    else:
        print(
            f"Kaplica przywraca {healed_hp} HP i "
            f"{restored_mana} Many."
        )


def show_chest_result(drops: list[LootDrop]) -> None:
    print_header()
    print()
    print("ZATOPIONA SKRZYNIA")
    print("-" * 58)
    if not drops:
        print("Skrzynia okazuje się pusta.")
        return
    print("Znajdujesz:")
    for drop in drops:
        definition = get_item_definition(drop.item_id)
        quantity = f" x{drop.quantity}" if drop.quantity > 1 else ""
        suffix = " +0" if definition.is_equipment else ""
        print(f"+ {definition.name}{suffix}{quantity}")



def ask_black_fleet_crossroads() -> str:
    print_header()
    print()
    print("ROZWIDLENIE CZARNEJ FLOTY")
    print("-" * 58)
    print("Kadłuby dwóch okrętów zderzyły się i zamarzły razem. Dalej możesz zejść")
    print("pod pokład albo wspiąć się ponad wraki, prosto na otwartą przestrzeń.")
    print()
    print("[1] Ładownia")
    print("    Dłuższa droga przez zalane wnętrze statku. W głębi podobno znajduje się")
    print("    Skarbiec Czarnej Floty, ale coś porusza się między skrzyniami.")
    print()
    print("[2] Górny Pokład")
    print("    Krótsza droga po oblodzonych masztach. Wiatr ogranicza widoczność,")
    print("    a kanonierzy mają stamtąd czystą linię strzału.")
    print()
    print("[0] Wycofaj się do Varenhold")
    while True:
        choice = input("> ").strip()
        if choice in {"0", "1", "2"}:
            return choice
        print("Nieprawidłowa opcja. Wybierz 1, 2 albo 0.")


def ask_medical_cabin(player: Player) -> str:
    print_header()
    print()
    print("KAJUTA MEDYKA")
    print("-" * 58)
    print("Na drzwiach wciąż można odczytać wyblakły znak medyka okrętowego.")
    print("W środku ocalały zapasy, bandaże i niewielki piecyk, w którym pod warstwą")
    print("popiołu wciąż tli się żar. To pierwsze ciepłe miejsce od wejścia do wraków.")
    print("Możesz odpocząć tutaj tylko raz podczas tej wyprawy.")
    print()
    print(
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"Mana {player.stats.current_mana}/{player.stats.max_mana}"
    )
    print()
    print("[1] Odpocznij — odzyskaj 30% maks. HP i Many")
    print("[2] Zostaw zapasy i idź dalej")
    while True:
        choice = input("> ").strip()
        if choice in {"1", "2"}:
            return choice
        print("Nieprawidłowa opcja. Wybierz 1 albo 2.")


def show_black_fleet_treasury(drops: list[LootDrop]) -> None:
    print_header()
    print()
    print("SKARBIEC CZARNEJ FLOTY")
    print("-" * 58)
    print("Ciężkie drzwi ustępują z jękiem. Za nimi leżą skrzynie zabezpieczone")
    print("pieczęciami Czarnej Floty, których lód nie zdołał całkowicie pochłonąć.")
    print()
    if not drops:
        print("Skarbiec został już dawno ograbiony.")
        return
    print("W ocalałych skrzyniach znajdujesz:")
    for drop in drops:
        definition = get_item_definition(drop.item_id)
        quantity = f" x{drop.quantity}" if drop.quantity > 1 else ""
        suffix = " +0" if definition.is_equipment else ""
        print(f"+ {definition.name}{suffix}{quantity}")


def show_medical_cabin_result(healed_hp: int, restored_mana: int) -> None:
    print()
    if healed_hp == 0 and restored_mana == 0:
        print("Odpoczynek nie może już niczego ci przywrócić.")
    else:
        print(
            f"Odpoczynek przywraca {healed_hp} HP i "
            f"{restored_mana} Many."
        )

def show_dungeon_exit(
    dungeon: DungeonDefinition,
    loot: list[DungeonLootChange],
    completed: bool,
) -> None:
    print_header()
    print()
    print("DUNGEON UKOŃCZONY" if completed else "ODWRÓT Z DUNGEONU")
    print("-" * 58)
    if completed:
        print(f"Pokonujesz władcę miejsca i opuszczasz: {dungeon.name}.")
    else:
        print("Wycofujesz się, zanim wyprawa pochłonie więcej zasobów.")
    print("Zdobyty podczas tej wyprawy łup zostaje zabezpieczony.")
    _show_loot(loot)


def show_dungeon_defeat(lost: list[DungeonLootChange]) -> None:
    print_header()
    print()
    print("WYPRAWA NIEUDANA")
    print("-" * 58)
    print("Odnajdują cię ludzie z Varenhold i sprowadzają w bezpieczne miejsce.")
    print("Gold i EXP pozostają. Niezabezpieczony łup z tej wyprawy przepada.")
    _show_loot(lost, heading="UTRACONY ŁUP")


def _show_loot(
    loot: list[DungeonLootChange],
    heading: str = "ŁUP Z WYPRAWY",
) -> None:
    print()
    print(f"{heading}:")
    if not loot:
        print("- brak")
        return
    for change in loot:
        definition = get_item_definition(change.item_id)
        suffix = " +0" if definition.is_equipment else ""
        quantity = f" x{change.quantity}" if change.quantity > 1 else ""
        print(f"- {definition.name}{suffix}{quantity}")
