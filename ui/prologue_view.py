from enemies.enemy import Enemy
from player.player import Player
from ui.console import print_header


def show_prologue_opening() -> None:
    print_header()
    print()
    print("PROLOG — DROGA DO VARENHOLD")
    print("-" * 58)
    print(
        "Królestwo od lat zamyka swoje granice coraz szczelniej.\n\n"
        "Na północy zamarzają porty. Na południu popiół zasypuje drogi.\n"
        "Z lasów znikają całe patrole, a stare ruiny znów pojawiają się\n"
        "w raportach Gildii.\n\n"
        "Mimo to do Varenhold każdego dnia przybywają nowi ludzie.\n"
        "Jedni szukają Golda. Inni sławy. Niektórzy po prostu nie mają\n"
        "już dokąd wrócić.\n\n"
        "Ty jesteś jednym z nich."
    )


def show_prologue_wagon() -> None:
    print_header(); print(); print("DROGA DO VARENHOLD"); print("-" * 58)
    print(
        "Pod wieczór karawana zatrzymuje się przy rozbitym królewskim wozie.\n"
        "Strażnicy nie żyją. Skrzynie z Goldem są nietknięte.\n\n"
        "Brakuje tylko jednej, niewielkiej skrzyni.\n\n"
        "Woźnica spogląda na ślady prowadzące w pole.\n"
        "— Jeśli zostawili złoto, to nie pieniędzy szukali.\n\n"
        "Kilkaset kroków dalej konie nagle wpadają w panikę.\n"
        "Z ciemności wychodzi coś, co jeszcze rano mogło wyglądać jak\n"
        "zwykły strach na wróble."
    )


def show_tutorial_combat(player: Player, enemy: Enemy) -> None:
    print_header(); print(); print("PIERWSZA WALKA"); print("-" * 58)
    print(f"{player.name:<28} HP {player.stats.current_hp}/{player.stats.max_hp}")
    print(f"{enemy.name:<28} HP {enemy.current_hp}/{enemy.max_hp}")
    print()
    print("[1] Atak")
    print("[2] Obrona")
    print()
    print("To krótka walka wprowadzająca. Umiejętności klasowe odblokujesz później.")


def ask_tutorial_action() -> str:
    while True:
        choice = input("> ").strip()
        if choice in {"1", "2"}:
            return choice
        print("Wybierz 1 — Atak albo 2 — Obrona.")


def show_prologue_clue() -> None:
    print_header(); print(); print("PO WALCE"); print("-" * 58)
    print(
        "W słomie znajdujesz nadpalony skrawek pergaminu.\n"
        "Na papierze pozostał fragment królewskiej pieczęci, ale większość\n"
        "tekstu spalono celowo. Zabierasz znalezisko jako dowód.\n\n"
        "Nie wygląda na przypadkową rzecz, którą wiatr przywiał na pole."
    )


def show_prologue_gate() -> None:
    print_header(); print(); print("BRAMA VARENHOLD"); print("-" * 58)
    print(
        "Przed bramą strażnicy przeszukują karawanę. Jeden z podróżnych\n"
        "zostaje zatrzymany, gdy spod jego płaszcza wypada stara księga.\n\n"
        "— Handel wiedzą bojową jest zakazany na mocy królewskiego edyktu.\n"
        "— To tylko stary manuskrypt!\n"
        "— W takim razie nie będziesz miał nic przeciwko, jeśli go spalimy.\n\n"
        "Nikt w kolejce nie protestuje. Ty zapamiętujesz płomień."
    )


def show_prologue_city(player_name: str) -> None:
    print_header(); print(); print("VARENHOLD"); print("-" * 58)
    print(
        "Miasto zbudowano bardziej z potrzeby niż z piękna. Kupcy\n"
        "przekrzykują najemników, kowalskie młoty słychać nawet po zmroku,\n"
        "a na tablicach Gildii wiszą zlecenia z miejsc, do których rozsądny\n"
        "człowiek nigdy by nie poszedł.\n\n"
        "Dla większości ludzi to koniec drogi.\n"
        "Dla Poszukiwaczy — dopiero początek.\n\n"
        f"W Gildii urzędnik zapisuje imię: {player_name}.\n"
        "— Doświadczenie?\n"
        "Cisza wystarcza za odpowiedź. Urzędnik przesuwa po blacie drewniany\n"
        "znak z literą F.\n\n"
        "— W takim razie zaczynasz tam, gdzie wszyscy."
    )
    print()
    print("OTRZYMANO RANGĘ GILDII: F — Nowicjusz")
    print("Nowe zadanie czeka na tablicy Gildii: „Ci, którzy nie wrócili”.")
