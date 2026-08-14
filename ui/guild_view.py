from data.enemies import ENEMY_DATA
from items.catalog import get_item_definition
from player.player import Player
from quests.contracts import ContractBoard
from quests.models import QuestDefinition, QuestLog, QuestObjectiveType
from data.guild import DAILY_UNLOCK_RANK, GUILD_RANKS, WEEKLY_UNLOCK_RANK
from systems.contracts import contract_is_ready
from systems.guild_progression import (
    GuildProgress,
    current_guild_rank,
    has_guild_rank,
    next_guild_rank,
)
from systems.quest_system import objective_progress
from ui.console import print_header


def _objective_text(quest: QuestDefinition) -> str:
    if quest.objective_type is QuestObjectiveType.KILL:
        name = str(ENEMY_DATA[quest.target_id]["name"])
        return f"Pokonaj: {name} x{quest.required_count}"

    name = get_item_definition(quest.target_id).name
    return f"Dostarcz: {name} x{quest.required_count}"


def _reward_text(quest: QuestDefinition) -> str:
    reward = (
        f"{quest.reward_exp} EXP | {quest.reward_gold} Gold | "
        f"+{quest.guild_reputation} Reputacji Gildii"
    )
    if quest.reward_item_id is not None:
        item = get_item_definition(quest.reward_item_id)
        reward += f" | {item.name} x{quest.reward_item_quantity}"
    return reward


def _quest_status(log: QuestLog, quest: QuestDefinition) -> str:
    if quest.quest_id in log.completed:
        return "UKOŃCZONE"
    if quest.quest_id in log.active:
        return "AKTYWNE"
    return "DOSTĘPNE"


def show_guild_menu(
    player: Player,
    log: QuestLog,
    contracts: ContractBoard,
    guild_progress: GuildProgress,
) -> str:
    while True:
        print_header()
        print()
        print("GILDIA POSZUKIWACZY")
        print("-" * 58)

        daily_ready = sum(
            1
            for contract in contracts.daily_contracts
            if contract_is_ready(player, contracts, contract)
        )
        daily_claimed = len(contracts.daily_claimed)

        weekly_status = "BRAK"
        if contracts.weekly_contract is not None:
            if contracts.weekly_claimed:
                weekly_status = "ODEBRANY"
            elif contract_is_ready(
                player,
                contracts,
                contracts.weekly_contract,
            ):
                weekly_status = "GOTOWY"
            else:
                weekly_status = "W TOKU"

        rank = current_guild_rank(guild_progress)
        next_rank = next_guild_rank(guild_progress)
        print(
            f"{player.name} | Poziom {player.level} | "
            f"Ranga Gildii: {rank.display_name}"
        )
        if next_rank is None:
            print(f"Reputacja: {guild_progress.reputation} [MAKSYMALNA RANGA]")
        else:
            print(
                f"Reputacja: {guild_progress.reputation}/"
                f"{next_rank.reputation_required} do rangi {next_rank.code}"
            )
        print(f"Fabularne aktywne: {len(log.active)}")
        print(
            f"Daily: {daily_claimed}/3 odebrane"
            + (
                f" | {daily_ready} gotowe"
                if daily_ready > 0
                else ""
            )
            + f" | Weekly: {weekly_status}"
        )
        print()
        print("[1] Zadania fabularne / jednorazowe")
        daily_label = "Kontrakty dzienne" if has_guild_rank(guild_progress, DAILY_UNLOCK_RANK) else f"Kontrakty dzienne [RANGA {DAILY_UNLOCK_RANK}]"
        weekly_label = "Kontrakt tygodniowy" if has_guild_rank(guild_progress, WEEKLY_UNLOCK_RANK) else f"Kontrakt tygodniowy [RANGA {WEEKLY_UNLOCK_RANK}]"
        print(f"[2] {daily_label}")
        print(f"[3] {weekly_label}")
        print("[4] Aktywne zadania fabularne")
        print("[5] Oddaj zadanie fabularne")
        print("[6] Rangi Gildii")
        print("[7] Plotki Gildii")
        print("[8] Drużyna i kompani")
        print("[9] Alarmy Szczelin")
        print("[10] Kwatermistrz — Magazyn Gildii")
        print("[0] Powrót")
        print()

        choice = input("> ").strip()
        if choice in {"1", "2", "3", "4", "5", "6", "7", "8", "9", "10", "0"}:
            return choice

        print("\nNieprawidłowa opcja.")
        input("Naciśnij Enter...")


def show_quest_board(
    player: Player,
    quests: list[QuestDefinition],
) -> None:
    """Pokazuje wyłącznie zlecenia, które można jeszcze przyjąć."""
    print_header()
    print()
    print("ZADANIA FABULARNE / JEDNORAZOWE")
    print("-" * 58)

    if not quests:
        print("Nie ma już nowych jednorazowych zadań fabularnych.")
        print("\n[0] Powrót")
        return

    for index, quest in enumerate(quests, start=1):
        risk = (
            " [RYZYKO]"
            if player.level < quest.recommended_level
            else ""
        )
        print(f"[{index}] {quest.title}{risk}")
        if quest.story_arc is not None:
            print(f"    {quest.story_arc}")
        if quest.chapter is not None:
            print(f"    {quest.chapter}")
        print(f"    Zalecany poziom: {quest.recommended_level}+")
        print(f"    {_objective_text(quest)}")
        print(f"    Nagroda: {_reward_text(quest)}")
        print(f"    {quest.description}")
        print()

    print(
        "Przyjęte zadania znajdziesz w menu Aktywne zadania. "
        "Ukończone znikają z tablicy na stałe."
    )
    print("[0] Powrót")


def show_active_quests(
    player: Player,
    log: QuestLog,
    quests: list[QuestDefinition],
) -> None:
    print_header()
    print()
    print("AKTYWNE ZADANIA")
    print("-" * 58)

    if not quests:
        print("Nie masz aktywnych zadań.")
        return

    for quest in quests:
        current, required = objective_progress(player, log, quest)
        ready = " [GOTOWE DO ODDANIA]" if current >= required else ""
        print(f"- {quest.title}{ready}")
        print(f"  {_objective_text(quest)}: {current}/{required}")
        print(f"  Nagroda: {_reward_text(quest)}")
        print()


def show_ready_quests(quests: list[QuestDefinition]) -> None:
    print_header()
    print()
    print("ODDAJ ZADANIE")
    print("-" * 58)

    if not quests:
        print("Nie masz zadania gotowego do oddania.")
        return

    for index, quest in enumerate(quests, start=1):
        print(f"[{index}] {quest.title}")
        print(f"    Nagroda: {_reward_text(quest)}")
    print("\n[0] Powrót")


def show_quest_turn_in(result) -> None:
    print_header()
    print()
    print("ZADANIE UKOŃCZONE")
    print("-" * 58)
    print(result.title)
    print(f"+ {result.experience} EXP")
    print(f"+ {result.gold} Gold")
    if result.reward_item_id is not None:
        item = get_item_definition(result.reward_item_id)
        print(f"+ {item.name} x{result.reward_item_quantity}")
    if result.levels_gained > 0:
        print(f"AWANS! Poziomy: +{result.levels_gained}")
        print(f"Punkty atrybutów: +{result.attribute_points_gained}")
    if result.completion_text:
        print()
        print("FABUŁA:")
        print(result.completion_text)


def show_guild_ranks(progress: GuildProgress) -> None:
    print_header()
    print()
    print("RANGI GILDII")
    print("-" * 58)
    current = current_guild_rank(progress)
    for rank in GUILD_RANKS:
        marker = " [AKTUALNA]" if rank.code == current.code else ""
        print(
            f"{rank.code} — {rank.name:<12} "
            f"od {rank.reputation_required} reputacji{marker}"
        )
    print()
    print("Odblokowania:")
    print("- E — kontrakty dzienne")
    print("- D — kontrakty tygodniowe")
    print("- C — możliwość spotkania informatora po ukończeniu dungeonu")
    print("- S — prestiżowy tytuł: Weteran Gildii")


def show_guild_rumor(rumor_text: str, rank_code: str) -> None:
    print_header(); print(); print("PLOTKI GILDII"); print("-" * 58)
    print(f"Ranga dostępu: {rank_code}")
    print()
    print(f'„{rumor_text}”')
