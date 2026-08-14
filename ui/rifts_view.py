from __future__ import annotations

from data.rifts import RIFT_MIN_COMPANIONS, RIFT_MODIFIERS, RIFT_THEMES
from rifts.models import RiftExpedition, RiftInstance, RiftState
from systems.rifts import rift_days_remaining, rift_segment_kind
from ui.console import print_header


def show_rift_board(state: RiftState, current_day: int) -> str:
    print_header(); print(); print("ALARMY SZCZELIN"); print("-" * 58)
    if state.expedition is not None and state.active_rift is not None:
        rift = state.active_rift
        exp = state.expedition
        print(f"TRWA EKSPEDYCJA: {rift.theme_name} | Ranga {rift.rank_code}")
        print(f"Postęp: {exp.segment_index}/{rift.segment_count}")
        print("Szczelina jest przypisana do twojej ekspedycji — inne drużyny jej teraz nie zamkną.")
        print()
        print("[1] Wznów ekspedycję")
        print("[2] Porzuć ekspedycję")
        print("[0] Powrót")
        return input("\n> ").strip()

    rift = state.active_rift
    if rift is None:
        print("Brak aktywnego alarmu Szczeliny.")
        if state.last_notice:
            print()
            print(state.last_notice)
        print("\n[0] Powrót")
        return input("\n> ").strip()

    print(f"{rift.theme_name.upper()}")
    print(f"Ranga zagrożenia: {rift.rank_code}")
    print(f"Pozostało na decyzję: {rift_days_remaining(rift, current_day)} dni Pythonii")
    print(f"Wymaganie drużyny: {RIFT_MIN_COMPANIONS[rift.rank_code]} aktywnych kompanów")
    print(f"Długość ekspedycji: {rift.segment_count} segmentów")
    print()
    print(str(RIFT_THEMES[rift.theme_id]["intro"]))
    print()
    print("Anomalie:")
    for modifier_id in rift.modifier_ids:
        modifier = RIFT_MODIFIERS[modifier_id]
        print(f"- {modifier.name}: {modifier.description}")
    print()
    print(f"Władca Szczeliny: {rift.boss_name}")
    print("Pokonanie Władcy zamknie tę Szczelinę na zawsze.")
    print()
    print("[1] Rozpocznij ekspedycję")
    print("[0] Powrót")
    return input("\n> ").strip()


def show_rift_segment(rift: RiftInstance, expedition: RiftExpedition) -> None:
    print_header(); print(); print(f"{rift.theme_name.upper()} — RANGA {rift.rank_code}"); print("-" * 58)
    index = expedition.segment_index
    kind = rift_segment_kind(rift, index)
    print(f"Segment {index + 1}/{rift.segment_count}")
    labels = {"battle": "STARCIE", "elite": "ELITA", "event": "ZDARZENIE", "camp": "OBOZOWISKO", "miniboss": "MINIBOSS", "boss": "SERCE SZCZELINY"}
    print(f"{labels.get(kind, kind.upper())}")
    print()


def show_rift_party_status(player, fighters, enemy_name: str, enemy_hp: int, enemy_max_hp: int, round_number: int) -> None:
    print_header(); print(); print(f"WALKA DRUŻYNOWA — RUNDA {round_number}"); print("-" * 58)
    print(f"{enemy_name}: HP {enemy_hp}/{enemy_max_hp}")
    print()
    for fighter in fighters:
        if fighter.removed:
            state = "[POZA WALKĄ]"
        elif fighter.downed_timer > 0:
            state = f"[POWALONY: {fighter.downed_timer}]"
        else:
            state = f"HP {fighter.combatant.stats.current_hp}/{fighter.combatant.stats.max_hp} | Mana {fighter.combatant.stats.current_mana}/{fighter.combatant.stats.max_mana}"
        print(f"- {fighter.name}: {state}")
    print()


def ask_rift_player_action(engine) -> tuple[str, str | None]:
    downed = engine.downed_companions()
    print("[1] Atak")
    print("[2] Umiejętność")
    print("[3] Obrona")
    if downed:
        print("[4] Pomóż powalonemu kompanowi")
    raw = input("\n> ").strip()
    if raw == "1":
        return "attack", None
    if raw == "2":
        skills = __import__("player.skills", fromlist=["unlocked_skills"]).unlocked_skills(engine.player)
        available = [skill for skill in skills if skill.mana_cost <= engine.player.stats.current_mana]
        if not available:
            return "attack", None
        print()
        for index, skill in enumerate(available, start=1):
            print(f"[{index}] {skill.name} | Mana {skill.mana_cost} | {skill.description}")
        choice = input("\n> ").strip()
        try:
            index = int(choice) - 1
        except ValueError:
            return "attack", None
        if 0 <= index < len(available):
            return "skill", available[index].skill_id
        return "attack", None
    if raw == "3":
        return "defend", None
    if raw == "4" and downed:
        for index, fighter in enumerate(downed, start=1):
            lethal = " [EGZEKUCJA!]" if fighter.lethal_downed else ""
            print(f"[{index}] {fighter.name} — {fighter.downed_timer} rund{lethal}")
        choice = input("\n> ").strip()
        try:
            index = int(choice) - 1
        except ValueError:
            return "attack", None
        if 0 <= index < len(downed):
            return "help", downed[index].companion_id
    return "attack", None


def show_rift_round(lines: list[str]) -> None:
    print()
    for line in lines:
        print(line)


def show_rift_completion(rift: RiftInstance, reward, unique_name: str | None) -> None:
    print_header(); print(); print("SZCZELINA ZAMKNIĘTA"); print("-" * 58)
    print(f"{rift.boss_name} został pokonany.")
    print("Przestrzeń wokół drużyny składa się do środka. Szczelina znika i nie będzie można wejść do niej ponownie.")
    print()
    print(f"+ {reward.gold} Gold")
    print(f"+ {reward.experience} EXP")
    if unique_name:
        print(f"+ UNIKAT: {unique_name}")
