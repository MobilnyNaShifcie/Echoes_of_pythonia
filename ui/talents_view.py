from data.talents import CLASS_PATH_ORDER, CLASS_PATHS, TALENT_DATA, talents_for_path
from items.catalog import get_item_definition
from player.talents import (
    available_tree_points,
    path_is_unlocked,
    reset_tree_cost,
    specialization_name,
    talent_can_be_learned,
    talent_rank,
)
from ui.console import print_header


def show_skill_hub(player) -> str:
    print_header(); print(); print("ROZWÓJ KLASY"); print("-" * 58)
    spec = specialization_name(player)
    print(f"Klasa: {player.character_class.display_name}" + (f" — {spec}" if spec else ""))
    print(f"Punkty drzewka: {available_tree_points(player)}")
    print()
    print("[1] Aktywne umiejętności")
    print("[2] Drzewko rozwoju")
    print(f"[3] Resetuj drzewko — {reset_tree_cost(player)} Gold")
    if player.character_class.code == "hunter":
        print("[4] Księga Kombinacji Łowcy")
    print("[0] Powrót")
    allowed = {"1", "2", "3", "0"}
    if player.character_class.code == "hunter": allowed.add("4")
    while True:
        choice = input("> ").strip()
        if choice in allowed: return choice
        print("Nieprawidłowa opcja.")


def show_talent_tree(player) -> list[str]:
    print_header(); print(); print("DRZEWKO ROZWOJU"); print("-" * 58)
    print(f"Wolne punkty: {available_tree_points(player)}")
    print("Każda ranga kosztuje 1 punkt. Księga odblokowuje ścieżkę permanentnie.")
    print()
    selectable: list[str] = []
    for path_id in CLASS_PATH_ORDER.get(player.character_class.code, ()):
        path = CLASS_PATHS[path_id]
        unlocked = path_is_unlocked(player, path_id)
        if unlocked:
            print(f"=== {path.name.upper()} ===")
        else:
            book_name = get_item_definition(path.book_item_id).name if path.book_item_id else "Księga Ścieżki"
            print(f"=== {path.name.upper()} [ZABLOKOWANA — {book_name}] ===")
        print(path.description)
        for talent in talents_for_path(path_id):
            current = talent_rank(player, talent.talent_id)
            status = f"{current}/{talent.max_rank}"
            allowed, reason = talent_can_be_learned(player, talent)
            selectable.append(talent.talent_id)
            index = len(selectable)
            marker = "" if allowed else (f" | {reason}" if current < talent.max_rank else " | MAX")
            print(f"[{index}] {talent.name} {status}{marker}")
            print(f"    {talent.description}")
        print()
    print("[0] Powrót")
    return selectable


def show_hunter_combos(player) -> None:
    print_header(); print(); print("KSIĘGA KOMBINACJI ŁOWCY"); print("-" * 58)
    known = sorted(player.discovered_hunter_combos)
    if not known:
        print("Nie odkryto jeszcze żadnej nazwanej kombinacji.")
        print("Łącz trzy techniki strzeleckie i eksperymentuj z kolejnością.")
        return
    from combat.hunter_combo import HUNTER_COMBOS
    for combo_id in known:
        combo = HUNTER_COMBOS.get(combo_id)
        if combo is None: continue
        print(f"- {combo.name}")
        print(f"  {' → '.join(combo.sequence_names)}")
        print(f"  {combo.description}")
