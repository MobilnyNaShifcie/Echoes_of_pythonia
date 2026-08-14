from combat.combat import CombatResult, TurnReport
from combat.effects import CombatEffects
from enemies.enemy import Enemy
from items.catalog import get_item_definition
from items.loot import LootDrop
from player.player import Player
from ui.console import print_header


def show_combat_screen(
    player: Player,
    enemy: Enemy,
    battle_title: str = "WALKA",
    effects: CombatEffects | None = None,
    status_lines: tuple[str, ...] = (),
) -> None:
    print_header(); print(); print(battle_title); print("-" * 58)
    if enemy.weather_note: print(f"[{enemy.weather_note}]")

    enemy_name = enemy.name
    if enemy.rank == "boss":
        enemy_name = f"[BOSS] {enemy_name}"
    elif enemy.rank == "elite":
        enemy_name = f"[ELITA] {enemy_name}"
    elif enemy.is_miniboss:
        enemy_name = f"[MINIBOSS] {enemy_name}"

    print(
        f"{player.display_name:<32} "
        f"HP {player.stats.current_hp}/{player.stats.max_hp} | "
        f"MANA {player.stats.current_mana}/{player.stats.max_mana}"
    )
    print(f"{enemy_name:<32} HP {enemy.current_hp}/{enemy.max_hp}")

    if effects is not None:
        active_effects = []

        if effects.armor_break_active:
            active_effects.append(
                f"Pęknięty pancerz: DEF -"
                f"{effects.enemy_defense_reduction} "
                f"({effects.enemy_defense_actions_remaining} akcje)"
            )

        if effects.bleed_active:
            active_effects.append(
                f"Krwawienie: {effects.bleed_damage} obrażeń "
                f"({effects.bleed_turns_remaining} tury)"
            )

        if effects.guard_active:
            active_effects.append(
                f"Ochrona: -{effects.player_damage_reduction_percent}% "
                f"obrażeń ({effects.player_guard_hits_remaining} ataki)"
            )

        if effects.dodge_active:
            active_effects.append(
                f"Krok w Cieniu: +{effects.player_dodge_bonus:.0f}% UNIK "
                f"({effects.player_dodge_hits_remaining} ataki)"
            )

        if active_effects:
            print()
            print("AKTYWNE EFEKTY:")
            for effect in active_effects:
                print(f"- {effect}")

    if status_lines:
        print()
        for line in status_lines:
            print(line)

    if enemy.is_alive and player.stats.is_alive:
        print()
        print("[1] Atak")
        print("[2] Umiejętności")
        print("[3] Obrona")
        print("[4] Mikstura")
        print("[5] Ucieczka")
        print()


def ask_combat_action() -> str:
    while True:
        choice=input("> ").strip()
        if choice in {"1","2","3","4","5"}: return choice
        print("Nieprawidłowa opcja. Wybierz 1, 2, 3, 4 albo 5.")


def show_turn_report(player: Player, enemy: Enemy, report: TurnReport) -> None:
    print()
    if report.used_item_name:
        effects = []
        if report.player_healed > 0:
            effects.append(f"+{report.player_healed} HP")
        if report.player_restored_mana > 0:
            effects.append(f"+{report.player_restored_mana} Mana")
        effect_text = ", ".join(effects)
        print(
            f"Używasz: {report.used_item_name}"
            + (f" ({effect_text})." if effect_text else ".")
        )

    if report.skill_name:
        print(
            f"Używasz: {report.skill_name} "
            f"(-{report.skill_mana_cost} Mana)."
        )

    if report.enemy_dodged:
        print(f"{enemy.name} unika twojego ataku!")
    elif report.player_damage > 0:
        damage_type = ""
        if report.player_damage_type.code != "physical":
            damage_type = f" [{report.player_damage_type.display_name}]"
        prefix = "Umiejętność trafia" if report.skill_name else "Atakujesz"
        if report.player_critical:
            print(
                f"{prefix}: {enemy.name} otrzymuje "
                f"{report.player_damage} obrażeń krytycznych"
                f"{damage_type}!"
            )
        else:
            print(
                f"{prefix}: {enemy.name} otrzymuje "
                f"{report.player_damage} obrażeń{damage_type}."
            )

    if report.extra_player_damage > 0 or report.extra_enemy_dodged:
        if report.skill_name:
            print("Umiejętność wykonuje drugie uderzenie!")
        else:
            print("Szybkość ataku pozwala ci wykonać dodatkowe uderzenie!")
        if report.extra_enemy_dodged:
            print(f"{enemy.name} unika dodatkowego ataku!")
        else:
            if report.extra_player_critical:
                print(
                    f"Dodatkowy atak zadaje "
                    f"{report.extra_player_damage} obrażeń krytycznych!"
                )
            else:
                print(
                    f"Dodatkowy atak zadaje "
                    f"{report.extra_player_damage} obrażeń."
                )

    # Umiejętności ofensywne dostają czytelne podsumowanie obrażeń.
    # Dla pudła pokazujemy 0, a przy umiejętności wielouderzeniowej
    # sumujemy wszystkie trafienia w tej samej akcji.
    if report.skill_name and (
        report.skill_total_damage > 0
        or report.player_damage > 0
        or report.enemy_dodged
        or report.extra_player_damage > 0
        or report.extra_enemy_dodged
    ):
        total_skill_damage = report.skill_total_damage or (report.player_damage + report.extra_player_damage)
        if total_skill_damage > 0:
            print(f"Łączne obrażenia umiejętności: {total_skill_damage}.")
        else:
            print("Łączne obrażenia umiejętności: 0 (unik).")

    for note in report.skill_notes:
        print(f"Efekt: {note}")

    for note in report.class_effect_notes:
        print(f"Efekt klasowy: {note}")

    for note in report.boss_notes:
        print(note)

    if report.boss_aura_damage > 0:
        print(
            f"Klątwa Głębin zadaje ci "
            f"{report.boss_aura_damage} obrażeń [Woda]."
        )

    if report.enemy_bleed_damage > 0:
        print(
            f"Krwawienie zadaje {enemy.name} "
            f"{report.enemy_bleed_damage} obrażeń."
        )

    if report.player_defended: print("Przyjmujesz pozycję obronną.")
    if report.flee_failed: print("Próba ucieczki nie powiodła się!")
    if report.enemy_special_name: print(f"{enemy.name} używa: {report.enemy_special_name}!")

    if report.player_dodged:
        print(f"{player.name} unika ataku przeciwnika!")
    elif report.enemy_damage > 0:
        type_suffix = "" if report.enemy_damage_type.code == "physical" else f" [{report.enemy_damage_type.display_name}]"
        print(f"{enemy.name} atakuje: otrzymujesz {report.enemy_damage} obrażeń{type_suffix}.")
    elif report.player_defended:
        print("Blokujesz całe nadchodzące obrażenia.")

    if report.enemy_extra_damage > 0:
        print(f"{enemy.name} atakuje ponownie: otrzymujesz {report.enemy_extra_damage} obrażeń.")
    if report.enemy_healed > 0:
        print(
            f"{enemy.name} wysysa życie i odzyskuje "
            f"{report.enemy_healed} HP."
        )
    if report.player_regenerated > 0:
        print(f"Regeneracja przywraca {report.player_regenerated} HP.")


def show_combat_result(
    result: CombatResult,
    enemy: Enemy,
    experience_gained: int = 0,
    gold_gained: int = 0,
    levels_gained: int = 0,
    attribute_points_gained: int = 0,
    drops: list[LootDrop] | None = None,
    note: str | None = None,
) -> None:
    print(); print("-" * 58)
    if result is CombatResult.VICTORY:
        print(f"ZWYCIĘSTWO — pokonano: {enemy.name}")
        print(f"Zdobyte EXP: {experience_gained}")
        print(f"Zdobyty gold: {gold_gained}")
        if levels_gained > 0:
            print(f"AWANS! Zdobyte poziomy: {levels_gained}")
            print(f"Punkty atrybutów: +{attribute_points_gained}")
        if drops:
            print("\nŁUPY:")
            for drop in drops:
                definition=get_item_definition(drop.item_id)
                quantity=f" x{drop.quantity}" if drop.quantity>1 else ""
                suffix=" +0" if definition.is_equipment else ""
                class_suffix = ""
                if definition.class_effect_id is not None:
                    from items.class_effects import get_class_effect
                    effect = get_class_effect(definition.class_effect_id)
                    class_suffix = f" | Klasowy: {effect.player_class_name}"
                print(
                    f"+ {definition.name}{suffix}{quantity} "
                    f"[{definition.rarity.display_name}{class_suffix}]"
                )
        else:
            print("\nBrak dodatkowych łupów.")
    elif result is CombatResult.DEFEAT:
        print(f"PORAŻKA — {enemy.name} okazał się silniejszy.")
    elif result is CombatResult.FLED:
        print("Udało ci się wycofać z walki.")
    if note: print(); print(note)
