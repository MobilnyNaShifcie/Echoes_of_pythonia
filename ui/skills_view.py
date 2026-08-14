from game.config import CLASS_UNLOCK_LEVEL
from data.books import BOOK_DATA
from items.catalog import get_item_definition
from player.classes import PLAYABLE_CLASSES, PlayerClass
from player.player import Player
from player.passives import PassiveType
from player.skills import SkillDefinition, skills_for_class, unlocked_skills
from player.talents import available_tree_points, specialization_name
from ui.console import print_header


def show_class_selection(player: Player) -> None:
    print_header()
    print()
    print("WYBÓR DROGI")
    print("-" * 58)
    print(
        f"Od poziomu {CLASS_UNLOCK_LEVEL} możesz określić "
        "swoją drogę."
    )
    print("Wybór jest stały dla tej postaci.")
    print()

    for index, player_class in enumerate(PLAYABLE_CLASSES, start=1):
        print(f"[{index}] {player_class.display_name}")
        print(f"    {player_class.description}")
        print(
            f"    Główne atrybuty: "
            f"{player_class.primary_attributes}"
        )
        print(
            f"    Bazowa Mana klasy: "
            f"{player_class.base_mana}"
        )
        print()

    print("[0] Wybiorę później")
    print()


def get_class_from_choice(choice: str) -> PlayerClass | None:
    try:
        index = int(choice) - 1
    except ValueError:
        return None

    if not 0 <= index < len(PLAYABLE_CLASSES):
        return None

    return PLAYABLE_CLASSES[index]


def show_active_skills(player: Player) -> None:
    print_header()
    print()
    print("UMIEJĘTNOŚCI BOHATERA")
    print("-" * 58)

    if player.character_class is PlayerClass.NONE:
        if player.level < CLASS_UNLOCK_LEVEL:
            print(
                f"Klasy odblokowują się na poziomie "
                f"{CLASS_UNLOCK_LEVEL}."
            )
        else:
            print("Nie wybrano jeszcze Drogi bohatera.")
        return

    spec = specialization_name(player)
    class_text = player.character_class.display_name + (f" — {spec}" if spec else "")
    print(f"Klasa: {class_text} | Poziom: {player.level}")
    print(f"Punkty drzewka: {available_tree_points(player)}")
    print(
        f"Mana: {player.stats.current_mana}/"
        f"{player.stats.max_mana}"
    )
    print()

    unlocked_ids = {skill.skill_id for skill in unlocked_skills(player)}
    shown = []
    for skill in skills_for_class(player.character_class):
        shown.append(skill)
    for skill in unlocked_skills(player):
        if skill.skill_id not in {item.skill_id for item in shown}:
            shown.append(skill)
    for skill in shown:
        if skill.skill_id in unlocked_ids:
            status = "ODBLOKOWANA"
        else:
            status = f"POZIOM {skill.unlock_level}"
        requirements = []
        if skill.required_weapon_type:
            requirements.append({"bow":"Łuk", "staff":"Kostur", "fate_lance":"Lanca Losu"}.get(skill.required_weapon_type, skill.required_weapon_type))
        if skill.required_offhand_type:
            requirements.append({"shield":"Tarcza", "quiver":"Kołczan", "artifact":"Artefakt"}.get(skill.required_offhand_type, skill.required_offhand_type))
        req = f" | Wymaga: {', '.join(requirements)}" if requirements else ""
        print(f"- {skill.name} | {skill.mana_cost} Mana [{status}]{req}")
        print(f"  {skill.description}")

    print()
    print("MISTRZOSTWA PASYWNE")
    print("-" * 58)
    for passive in PassiveType:
        cap = player.passive_level_cap(passive)
        level = player.passives.get(passive)
        if passive.code in player.passive_masteries:
            status = "ODBLOKOWANE"
        else:
            matching = next(
                item_id for item_id, book in BOOK_DATA.items()
                if book.passive_code == passive.code
            )
            status = f"WYMAGA: {get_item_definition(matching).name}"
        print(f"- {passive.display_name}: {level}/{cap} [{status}]")


def show_combat_skill_menu(
    player: Player,
) -> list[SkillDefinition]:
    print_header()
    print()
    print("UMIEJĘTNOŚCI")
    print("-" * 58)
    print(
        f"{player.character_class.display_name} | "
        f"Mana {player.stats.current_mana}/"
        f"{player.stats.max_mana}"
    )
    print()

    skills = unlocked_skills(player)

    if not skills:
        print("Nie masz jeszcze odblokowanych aktywnych umiejętności.")
        print()
        print("[0] Powrót")
        return []

    for index, skill in enumerate(skills, start=1):
        affordable = (
            "GOTOWA"
            if player.stats.current_mana >= skill.mana_cost
            else "BRAK MANY"
        )
        requirement = ""
        if skill.required_weapon_type:
            requirement = " | " + {"bow":"Łuk", "staff":"Kostur", "fate_lance":"Lanca Losu"}.get(skill.required_weapon_type, skill.required_weapon_type)
        if skill.required_offhand_type:
            requirement += " | " + {"shield":"Tarcza", "quiver":"Kołczan", "artifact":"Artefakt"}.get(skill.required_offhand_type, skill.required_offhand_type)
        print(f"[{index}] {skill.name} — {skill.mana_cost} Mana [{affordable}]{requirement}")
        print(f"    {skill.description}")

    print()
    print("[0] Powrót")
    return skills
