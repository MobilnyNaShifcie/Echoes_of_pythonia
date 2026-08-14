from game.config import INN_REST_DURATION_HOURS
from player.player import Player
from ui.console import print_header
from world.city import City
from world.time_system import GameClock
from systems.inn import inn_rest_cost


def show_city_menu(player: Player, city: City, clock: GameClock, *, black_market_unlocked: bool = False) -> str:
    while True:
        print_header(); print(); print(city.name.upper()); print("-" * 58)
        print(f"{clock.formatted_time()} | {clock.period.display_name}")
        print(f"{player.display_name} | Poziom {player.level} | Gold {player.gold}")
        print(); print(city.description); print()
        print(f"[1] {city.gate_name}")
        print(f"[2] {city.blacksmith_name}")
        print(f"[3] {city.workshop_name}")
        print(f"[4] {city.merchant_name}")
        print(f"[5] {city.inn_name}")
        print(f"[6] {city.guild_name}")
        print("[7] Bohater")
        if black_market_unlocked:
            print("[8] Czarny Rynek")
        print("[9] Przygotowanie do wyprawy")
        print("[0] Powrót do menu głównego\n")
        choice=input("> ").strip()
        allowed={"1","2","3","4","5","6","7","9","0"}
        if black_market_unlocked:
            allowed.add("8")
        if choice in allowed: return choice
        print("\nNieprawidłowa opcja."); input("Naciśnij Enter...")


def show_hero_hub_menu(player: Player) -> str:
    while True:
        print_header(); print(); print("BOHATER"); print("-" * 58)
        print(
            f"{player.display_name} | Poziom {player.level} | "
            f"{player.character_class.display_name}\n"
        )
        print("[1] Status bohatera")
        print("[2] Plecak")
        print("[3] Ekwipunek")
        point_note = f" ({player.unspent_attribute_points} pkt)" if player.unspent_attribute_points > 0 else ""
        passive_note = f" ({player.available_passive_points} pkt)" if player.available_passive_points > 0 else ""
        print(f"[4] Atrybuty{point_note}")
        print(f"[5] Umiejętności pasywne{passive_note}")
        print("[6] Osiągnięcia i tytuły")
        print("[7] Dziennik przygód")
        if player.character_class.code == "none":
            class_label = (
                "Wybierz Drogę bohatera"
                if player.level >= 5
                else "Droga bohatera [POZIOM 5]"
            )
        else:
            class_label = "Umiejętności"
        print(f"[8] {class_label}")
        print("[0] Powrót\n")
        choice=input("> ").strip()
        if choice in {"1","2","3","4","5","6","7","8","0"}: return choice
        print("\nNieprawidłowa opcja."); input("Naciśnij Enter...")


def show_inn_menu(
    player: Player,
    city: City,
    *,
    current_day: int,
    last_inn_rest_day: int = 0,
    informant_present: bool = False,
) -> str:
    while True:
        print_header(); print(); print(city.inn_name.upper()); print("-" * 58)
        print(f"Gold: {player.gold}")
        print(f"HP {player.stats.current_hp}/{player.stats.max_hp} | MANA {player.stats.current_mana}/{player.stats.max_mana}\n")
        cost = inn_rest_cost(player)
        if last_inn_rest_day >= current_day:
            print(f"[1] Wynajmij pokój — [DOSTĘPNY OD DNIA {current_day + 1}]")
        else:
            print(f"[1] Wynajmij pokój — {cost} Gold (pełne HP i Mana, +{INN_REST_DURATION_HOURS}h)")
        print("[2] Posłuchaj plotek")
        if informant_present:
            print("[3] Podejdź do nieznajomego")
        print("[0] Powrót\n")
        choice=input("> ").strip()
        allowed={"1","2","0"}
        if informant_present:
            allowed.add("3")
        if choice in allowed: return choice
        print("\nNieprawidłowa opcja."); input("Naciśnij Enter...")
