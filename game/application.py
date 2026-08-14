import random

from combat.combat import CombatEngine, CombatResult
from combat.dungeon_boss import AdmiralVarekCombatEngine, GrandMasterCombatEngine
from combat.region_bosses import AzharCombatEngine, HearthDevourerCombatEngine, LeviathanNorthCombatEngine
from data.dungeon_narrative import BLACK_FLEET_NARRATIVE
from enemies.enemy import Enemy
from data.books import BookType, get_book_definition
from data.guild_rumors import available_guild_rumors
from enemies.factory import create_enemy
from game.config import (
    ATTRIBUTE_POINTS_PER_LEVEL,
    DEFAULT_SAVE_SLOT,
    DUNGEON_ROOM_DURATION_HOURS,
    EXPEDITION_DURATION_HOURS,
    GAME_VERSION,
    INN_REST_DURATION_HOURS,
    REST_DURATION_HOURS,
    SAVE_SLOT_COUNT,
    STARTING_CITY_ID,
    STARTING_LOCATION_ID,
)
from game.state import GameState
from items.affixes import equipment_quality_for_enemy
from items.catalog import get_item_definition
from items.consumables import use_consumable
from items.loot import LootDrop, add_loot_to_inventory, roll_loot
from items.upgrades import format_upgrade_name
from player.classes import PlayerClass
from player.factory import create_player
from player.inventory import Inventory
from quests.catalog import get_all_quests
from systems.achievements import (
    achievements_after_guild_rank,
    achievements_after_quest_turn_in,
    achievements_after_upgrade,
    achievements_after_victory,
    reconcile_existing_progress,
)
from systems.black_market import (
    bargain_book_sale,
    bargain_buy,
    buy_black_market_offer,
    check_informant_for_day,
    ensure_black_market_rotation,
    sell_mastery_book,
    unlock_black_market,
)
from systems.class_loot import roll_class_gear_drop, roll_class_weapon_drop
from systems.companions import (
    available_personal_stage,
    camp_banter,
    candidate_willingness_score,
    complete_personal_stage,
    critically_injure,
    dismiss_companion,
    ensure_daily_candidates,
    ensure_daily_party_message,
    equip_player_item_to_companion,
    gain_companion_experience,
    kill_companion,
    mark_messages_read,
    record_rift_together,
    recruit_candidate,
    refresh_injuries,
    remove_player_item_from_companion,
    set_companion_active,
    set_companion_tactic,
    set_party_solo,
    sync_companion_from_player,
)
from systems.rifts import (
    abandon_rift_expedition,
    can_start_rift,
    create_rift_enemy,
    ensure_rift_state,
    resolve_rift_completion,
    rift_event_text,
    rift_segment_kind,
    start_rift_expedition,
)
from systems.rift_combat import RiftBattleEngine
from systems.blacksmith import (
    get_upgrade_plan,
    get_upgrade_targets,
    upgrade_item_levels,
)
from systems.crafting import (
    craft_for_player,
    get_all_recipes,
    recipes_for_category,
)
from systems.contracts import (
    claim_contract,
    contract_is_ready,
    ensure_contract_board,
    record_contract_victory,
    record_dungeon_completion,
)
from systems.elite_system import roll_elite_for_region
from systems.economy import (
    buy_item,
    get_merchant_stock,
    sell_equipment_item,
    sell_equipment_items,
    sell_stack_item,
    sell_stack_items,
)
from systems.guild_progression import (
    current_guild_rank,
    has_guild_rank,
    record_contract_reputation,
    record_guild_milestone,
    record_story_quest_reputation,
)
from systems.inn import rest_at_camp as apply_camp_rest, rest_at_inn
from systems.carry_weight import carry_status, next_carry_upgrade
from systems.expedition_preparation import (
    PRESET_NAMES,
    apply_preset,
    clear_preset,
    healing_supply_ids,
    save_preset,
)
from systems.guild_storage import (
    deposit_equipment,
    deposit_equipment_many,
    deposit_stack,
    deposit_stacks,
    withdraw_equipment,
    withdraw_equipment_many,
    withdraw_stack,
    withdraw_stacks,
)
from systems.mastery_books import read_mastery_book, roll_mastery_book_drop
from systems.path_books import read_path_book, roll_path_book_drop
from systems.region_boss_respawn import (
    REGION_BOSS_NAMES,
    boss_id_for_location,
    record_region_expedition,
    respawn_remaining,
    start_boss_respawn,
)
from systems.quest_system import (
    accept_quest,
    get_active_quests,
    get_available_quests,
    get_ready_quests,
    record_enemy_kill,
    turn_in_quest,
)
from systems.save_system import (
    SaveGameError,
    any_save_exists,
    get_save_summary,
    get_save_summaries,
    load_game,
    migrate_legacy_save_if_needed,
    save_exists,
    save_game,
    save_slot_name,
    save_slot_number,
)
from systems.weather_effects import (
    apply_weather_to_enemy,
    drop_chance_multiplier,
    reward_multiplier,
    roll_weather_boss_weapon,
)
from ui.achievements_view import (
    show_achievement_menu,
    show_achievements,
    show_titles,
)
from ui.adventure_log_view import show_adventure_log
from ui.attributes_view import get_attribute_from_choice, show_attribute_menu
from ui.black_market_view import (
    show_bargain_result,
    show_black_market_menu,
    show_black_market_offers,
    show_book_sell_menu,
    show_buy_offer_actions,
    show_informant_scene,
    show_sell_book_actions,
)
from ui.blacksmith_view import (
    ask_upgrade_confirmation,
    ask_upgrade_quantity,
    show_blacksmith_menu,
    show_upgrade_preview,
    show_upgrade_result,
)
from ui.books_view import show_books
from ui.companions_view import (
    show_candidate,
    show_candidate_list,
    show_candidate_talk_choices,
    show_companion_build,
    show_companion_detail,
    show_companion_equipment,
    show_companion_equippable_inventory,
    show_companion_hub,
    show_companion_list,
    show_companion_loaned_slots,
    show_party_setup,
    show_fallen,
    show_messages,
    show_personal_stage,
)
from ui.rifts_view import (
    ask_rift_player_action,
    show_rift_board,
    show_rift_completion,
    show_rift_party_status,
    show_rift_round,
    show_rift_segment,
)
from ui.city_view import show_city_menu, show_hero_hub_menu, show_inn_menu
from ui.combat_view import (
    ask_combat_action,
    show_combat_result,
    show_combat_screen,
    show_turn_report,
)
from ui.console import clear_screen, pause, set_world_status
from ui.crafting_view import show_crafting_category_menu, show_crafting_menu
from ui.contracts_view import (
    show_contract_claim,
    show_daily_contracts,
    show_weekly_contract,
)
from ui.dungeon_view import (
    ask_black_fleet_crossroads,
    ask_continue_or_retreat,
    ask_crossroads,
    ask_medical_cabin,
    ask_shrine,
    show_black_fleet_treasury,
    show_chest_result,
    show_dungeon_defeat,
    show_dungeon_entrance,
    show_dungeon_exit,
    show_dungeon_room,
    show_dungeon_scene,
    show_medical_cabin_result,
    show_shrine_result,
)
from ui.guild_view import (
    show_active_quests,
    show_guild_menu,
    show_guild_ranks,
    show_guild_rumor,
    show_quest_board,
    show_quest_turn_in,
    show_ready_quests,
)
from ui.hero_status import show_hero_status
from ui.inventory_view import (
    show_consumables,
    show_equipment,
    show_equipment_details,
    show_all_equipped_details,
    show_equipment_detail_selection,
    show_equipped_detail_selection,
    show_equippable_inventory,
    show_inventory_menu,
    show_item_usage,
    show_item_usage_selection,
    show_unequip_slots,
)
from ui.merchant_view import (
    ask_buy_quantity,
    ask_equipment_sale_selection,
    ask_stack_sale_selection,
    get_sellable_stacks,
    show_buy_menu,
    show_equipment_sell_menu,
    show_equipment_sale_confirmation,
    show_merchant_menu,
    show_stack_sale_confirmation,
    show_stack_sell_menu,
)
from ui.menus import ask_player_name, show_main_menu
from ui.quartermaster_view import (
    ask_equipment_multi_selection as ask_storage_equipment_multi_selection,
    ask_quantity as ask_storage_quantity,
    ask_stack_multi_selection as ask_storage_stack_multi_selection,
    show_carry_upgrade,
    show_deposit_type_menu,
    show_equipment_selection as show_storage_equipment_selection,
    show_quartermaster_menu,
    show_stack_selection as show_storage_stack_selection,
    show_storage,
    show_withdraw_type_menu,
)
from ui.expedition_prep_view import (
    preparation_warnings,
    show_departure_confirmation,
    show_preparation_menu,
    show_preset_actions,
    show_preset_list,
    show_preset_supply_catalog,
    show_tactic_companion_selection,
    show_tactic_selection,
    show_target_selection,
)
from ui.passives_view import (
    get_passive_from_choice,
    show_passive_specialization_choice,
    show_passives_menu,
)
from ui.point_allocation import ask_point_quantity
from ui.prologue_view import (
    ask_tutorial_action,
    show_prologue_city,
    show_prologue_clue,
    show_prologue_gate,
    show_prologue_opening,
    show_prologue_wagon,
    show_tutorial_combat,
)
from player.passive_specializations import (
    can_choose_passive_specialization,
    choose_passive_specialization,
)
from player.talents import learn_talent, reset_talents
from ui.talents_view import show_hunter_combos, show_skill_hub, show_talent_tree
from ui.skills_view import (
    get_class_from_choice,
    show_active_skills,
    show_class_selection,
    show_combat_skill_menu,
)
from ui.save_view import (
    show_load_success,
    show_migration_success,
    show_save_error,
    show_save_slots,
    show_save_success,
    show_save_summary,
)
from ui.world_view import (
    show_location_menu,
    show_quiet_exploration,
    show_rest_result,
    show_region_boss_challenge,
    show_region_boss_respawn,
    show_world_map,
)
from world.city_factory import create_city
from world.dungeon import (
    can_enter_dungeon,
    capture_dungeon_loot_snapshot,
    consume_dungeon_entry,
    create_dungeon,
    discard_unsecured_dungeon_loot,
    dungeon_loot_since_snapshot,
    roll_dungeon_chest,
    use_dungeon_shrine,
    use_medical_cabin,
)
from world.exploration import explore_location
from world.factory import create_location, create_world_locations
from world.time_system import GameClock
from world.weather import advance_weather, create_initial_weather


class Game:
    def __init__(self, rng: random.Random | None = None) -> None:
        self.state = GameState()
        self.rng = rng or random.Random()
        self.migration_checked = False
        self.active_save_slot = DEFAULT_SAVE_SLOT

    def _sync_world_status(self) -> None:
        weather = self.state.weather
        set_world_status(
            f"{weather.current.display_name} "
            f"(zmiana za {weather.remaining_hours}h)"
        )

    def _log(self, message: str) -> None:
        self.state.adventure_log.add(
            self.state.world_clock.day,
            self.state.world_clock.hour,
            message,
        )

    def _show_guild_update(self, update) -> None:
        if update is None:
            return
        print(f"+ {update.amount} Reputacji Gildii ({update.reason})")
        self._log(
            f"Reputacja Gildii +{update.amount}: {update.reason}."
        )
        if update.rank_changed:
            print(
                f"AWANS W GILDII: {update.old_rank.display_name} → "
                f"{update.new_rank.display_name}"
            )
            self._log(
                f"Awans w Gildii: {update.new_rank.display_name}."
            )
        unlocked = achievements_after_guild_rank(
            self.state.player,
            update.new_rank.code,
        ) if self.state.player is not None else []
        self._show_unlocked_achievements(unlocked)

    def _save_silently(self) -> None:
        try:
            save_game(self.state, self.active_save_slot)
        except SaveGameError:
            pass

    def _advance_weather(self, hours: int) -> None:
        changes = advance_weather(self.state.weather, hours, self.rng)
        for old, new in changes:
            if old is new:
                continue
            self._log(
                f"Pogoda zmieniła się: "
                f"{old.display_name} → {new.display_name}."
            )
        self._sync_world_status()

    def _refresh_party_world(self) -> None:
        player = self.state.player
        if player is None:
            return
        changed = False
        day = self.state.world_clock.day
        healed = refresh_injuries(self.state.party, day)
        for name in healed:
            self._log(f"{name} wrócił do sił i znów może wyruszać z drużyną.")
            changed = True
        message = ensure_daily_party_message(self.state.party, day, player.name)
        if message is not None:
            changed = True
        rank = current_guild_rank(self.state.guild_progress)
        notice = ensure_rift_state(self.state.rifts, player, day, rank.code)
        if notice:
            self._log(notice)
            changed = True
        if changed:
            self._save_silently()

    def _advance_world_time(self, hours: int) -> None:
        self.state.world_clock.advance(hours)
        self._advance_weather(hours)
        self._refresh_party_world()

    def _show_unlocked_achievements(self, unlocked) -> None:
        if not unlocked:
            return
        print("\nOSIĄGNIĘCIA:")
        for achievement in unlocked:
            print(
                f"- Odblokowano: {achievement.name} "
                f"| nowy tytuł: {achievement.title}"
            )
            self._log(
                f"Osiągnięcie: {achievement.name}. "
                f"Odblokowano tytuł „{achievement.title}”."
            )

    def run(self) -> None:
        if not self.migration_checked:
            self.migration_checked = True
            migrated_from = migrate_legacy_save_if_needed()
            if migrated_from is not None:
                clear_screen()
                show_migration_success(migrated_from)
                pause()

        while self.state.running:
            if not self.state.active_game:
                set_world_status(None)
            clear_screen()
            choice = show_main_menu(
                any_save_exists(),
                self.state.player is not None,
            )
            if choice == "1":
                if self.state.player is None:
                    print("\nNie ma aktywnej gry do kontynuowania.")
                    pause()
                else:
                    self.run_city()
            elif choice == "2":
                self.start_new_game()
            elif choice == "3":
                self.load_saved_game()
            elif choice == "4":
                self.save_current_game()
            elif choice == "5":
                self.show_project_status()
            elif choice == "0":
                self.exit_game()

    def _slot_summaries_safe(self) -> dict[int, object | None]:
        summaries: dict[int, object | None] = {}
        for number in range(1, SAVE_SLOT_COUNT + 1):
            try:
                summaries[number] = get_save_summary(save_slot_name(number))
            except SaveGameError:
                summaries[number] = None
        return summaries

    def _choose_slot(self, *, title: str) -> int | None:
        summaries = self._slot_summaries_safe()
        active_number = save_slot_number(self.active_save_slot)
        clear_screen()
        show_save_slots(summaries, title=title, active_slot=active_number)
        choice = input("> ").strip()
        if choice == "0":
            return None
        try:
            number = int(choice)
        except ValueError:
            return None
        if not 1 <= number <= SAVE_SLOT_COUNT:
            return None
        return number

    def start_new_game(self) -> None:
        slot_number = self._choose_slot(title="NOWA GRA — WYBIERZ SLOT")
        if slot_number is None:
            return
        slot_name = save_slot_name(slot_number)
        if save_exists(slot_name):
            print(f"\nSlot {slot_number} zawiera zapis. Rozpoczęcie nowej gry go nadpisze.")
            confirm = input("Potwierdź [T/N]: ").strip().lower()
            if confirm not in {"t", "tak", "y", "yes"}:
                return

        clear_screen()
        player_name = ask_player_name()
        self.active_save_slot = slot_name
        self.state = GameState(
            running=True,
            active_game=True,
            player=create_player(player_name),
            current_location_id=STARTING_LOCATION_ID,
            current_city_id=STARTING_CITY_ID,
            world_clock=GameClock(),
            weather=create_initial_weather(self.rng),
        )
        self._sync_world_status()
        self.run_prologue()
        self._log("Rozpoczęto przygodę w Varenhold.")
        self._save_silently()
        self.run_city()

    def run_prologue(self) -> None:
        player = self.state.player
        if player is None:
            return
        set_world_status(None)
        for scene in (show_prologue_opening, show_prologue_wagon):
            clear_screen(); scene(); pause()

        enemy = Enemy(
            enemy_id="prologue_scarecrow",
            name="Przeklęty Strach na Wróble",
            max_hp=7,
            current_hp=7,
            attack=1,
            defense=0,
            dodge=0.0,
            experience_reward=0,
            gold_min=0,
            gold_max=0,
            rank="story",
        )
        combat = CombatEngine(player, enemy, self.rng)
        while combat.result is CombatResult.ONGOING:
            clear_screen(); show_tutorial_combat(player, enemy)
            action = ask_tutorial_action()
            report = combat.player_attack() if action == "1" else combat.player_defend()
            clear_screen(); show_tutorial_combat(player, enemy); show_turn_report(player, enemy, report)
            if combat.result is CombatResult.ONGOING:
                pause()
        player.stats.restore_full()
        clear_screen(); show_prologue_clue(); pause()
        clear_screen(); show_prologue_gate(); pause()
        clear_screen(); show_prologue_city(player.name); pause()
        self._log("Prolog: przybyto do Varenhold i otrzymano rangę F — Nowicjusz.")
        self._log("Na drodze znaleziono nadpalony fragment królewskiego dokumentu.")
        self._sync_world_status()

    def load_saved_game(self) -> None:
        slot_number = self._choose_slot(title="WCZYTAJ GRĘ")
        if slot_number is None:
            return
        slot_name = save_slot_name(slot_number)
        try:
            summary = get_save_summary(slot_name)
        except SaveGameError as error:
            show_save_error(str(error)); pause(); return
        if summary is None:
            print(f"\nSlot {slot_number} jest pusty."); pause(); return
        try:
            self.state = load_game(slot_name)
        except SaveGameError as error:
            show_save_error(str(error)); pause(); return
        self.active_save_slot = slot_name
        self._sync_world_status()
        self._refresh_party_world()
        unlocked = reconcile_existing_progress(
            self.state.player, self.state.quest_log, len(get_all_quests())
        )
        unlocked.extend(
            achievements_after_guild_rank(
                self.state.player,
                current_guild_rank(self.state.guild_progress).code,
            )
        )
        clear_screen()
        show_load_success(summary, slot_number)
        self._show_unlocked_achievements(unlocked)
        pause()
        self.run_city()

    def save_current_game(self) -> None:
        if self.state.player is None:
            print("\nNie ma aktywnej gry do zapisania.")
            pause()
            return
        slot_number = self._choose_slot(title="ZAPISZ GRĘ — WYBIERZ SLOT")
        if slot_number is None:
            return
        slot_name = save_slot_name(slot_number)
        try:
            summary = get_save_summary(slot_name)
        except SaveGameError:
            summary = None
        if summary is not None:
            print(f"\nSlot {slot_number} zawiera zapis {summary.player_name} (lvl {summary.level}).")
            confirm = input("Nadpisać ten zapis? [T/N]: ").strip().lower()
            if confirm not in {"t", "tak", "y", "yes"}:
                return
        try:
            save_game(self.state, slot_name)
        except SaveGameError as error:
            show_save_error(str(error)); pause(); return
        self.active_save_slot = slot_name
        show_save_success(slot_number)
        pause()

    def run_city(self) -> None:
        player = self.state.player
        if player is None:
            return

        self.state.active_game = True
        class_offer_shown = False

        while self.state.active_game:
            self._sync_world_status()
            self._refresh_party_world()

            if player.can_choose_class and not class_offer_shown:
                class_offer_shown = True
                self.run_class_selection()

            city = create_city(self.state.current_city_id)
            clear_screen()
            choice = show_city_menu(
                player, city, self.state.world_clock,
                black_market_unlocked=self.state.black_market.unlocked,
            )
            if choice == "1": self.run_world_map()
            elif choice == "2": self.run_blacksmith_menu()
            elif choice == "3": self.run_crafting_menu()
            elif choice == "4": self.run_merchant()
            elif choice == "5": self.run_inn(city)
            elif choice == "6": self.run_guild()
            elif choice == "7": self.run_hero_hub()
            elif choice == "8": self.run_black_market()
            elif choice == "9": self.run_expedition_preparation()
            elif choice == "0": self.state.active_game = False

    def _ensure_repeatable_contracts(self) -> None:
        player = self.state.player
        if player is None:
            return

        messages = ensure_contract_board(
            self.state.contract_board,
            player,
        )
        if not messages:
            return

        for message in messages:
            self._log(message)

        # Zestaw Daily/Weekly zapisujemy od razu, aby restart gry
        # nie pozwalał przerzucać kontraktów.
        try:
            save_game(self.state, self.active_save_slot)
        except SaveGameError:
            pass

    def _show_contract_updates(self, updates) -> None:
        if not updates:
            return
        print("\nPOSTĘP KONTRAKTÓW:")
        for update in updates:
            ready = " — GOTOWE" if update.ready else ""
            print(
                f"- {update.title}: "
                f"{update.current}/{update.required}{ready}"
            )

    def _claim_repeatable_contract(self, contract_id: str) -> None:
        player = self.state.player
        if player is None:
            return

        try:
            result = claim_contract(
                player,
                self.state.contract_board,
                contract_id,
            )
        except (ValueError, KeyError) as error:
            print(f"\nNie można odebrać nagrody: {error}")
            pause()
            return

        guild_update = record_contract_reputation(
            self.state.guild_progress,
            result.contract_id,
        )
        self._log(
            f"Ukończono kontrakt Gildii: {result.title}."
        )
        clear_screen()
        show_contract_claim(result)
        self._show_guild_update(guild_update)

        try:
            save_game(self.state, self.active_save_slot)
            print("\nPostęp został zapisany automatycznie.")
        except SaveGameError as save_error:
            print(
                "\nNagrodę odebrano, ale automatyczny zapis "
                f"nie powiódł się: {save_error}"
            )
        pause()

    def run_guild(self) -> None:
        player = self.state.player
        if player is None:
            return

        self._ensure_repeatable_contracts()

        while True:
            clear_screen()
            choice = show_guild_menu(
                player,
                self.state.quest_log,
                self.state.contract_board,
                self.state.guild_progress,
            )

            if choice == "1":
                quests = get_available_quests(self.state.quest_log, player.level)
                clear_screen()
                show_quest_board(player, quests)

                if not quests:
                    pause()
                    continue

                selected = input("> ").strip()
                if selected == "0":
                    continue

                try:
                    selected_index = int(selected) - 1
                    if not 0 <= selected_index < len(quests):
                        raise IndexError

                    quest = quests[selected_index]
                    accept_quest(
                        self.state.quest_log,
                        quest.quest_id,
                    )
                    self._log(
                        f"Przyjęto zadanie fabularne: "
                        f"{quest.title}."
                    )
                    print(f"\nPrzyjęto zadanie: {quest.title}")
                except ValueError as error:
                    print(
                        f"\nNie udało się przyjąć zadania: "
                        f"{error}"
                    )
                except IndexError:
                    print(
                        "\nNie udało się przyjąć zadania: "
                        "Nieprawidłowy numer zadania."
                    )
                pause()

            elif choice == "2":
                if not has_guild_rank(self.state.guild_progress, "E"):
                    print("\nKontrakty dzienne odblokowują się od rangi E — Adept.")
                    pause()
                    continue
                contracts = show_daily_contracts(
                    player,
                    self.state.contract_board,
                )
                selected = input("> ").strip()

                if selected == "0":
                    continue

                try:
                    index = int(selected) - 1
                    if not 0 <= index < len(contracts):
                        raise IndexError
                    contract = contracts[index]

                    if not contract_is_ready(
                        player,
                        self.state.contract_board,
                        contract,
                    ):
                        print(
                            "\nTen kontrakt nie jest jeszcze gotowy "
                            "do oddania."
                        )
                        pause()
                        continue

                    self._claim_repeatable_contract(
                        contract.contract_id
                    )
                except (ValueError, IndexError):
                    print("\nNieprawidłowy numer kontraktu.")
                    pause()

            elif choice == "3":
                if not has_guild_rank(self.state.guild_progress, "D"):
                    print("\nKontrakt tygodniowy odblokowuje się od rangi D — Poszukiwacz.")
                    pause()
                    continue
                contract = show_weekly_contract(
                    player,
                    self.state.contract_board,
                )
                selected = input("> ").strip()

                if selected == "0":
                    continue

                if (
                    selected == "1"
                    and contract is not None
                    and contract_is_ready(
                        player,
                        self.state.contract_board,
                        contract,
                    )
                ):
                    self._claim_repeatable_contract(
                        contract.contract_id
                    )
                else:
                    print(
                        "\nKontrakt tygodniowy nie jest jeszcze "
                        "gotowy do oddania."
                    )
                    pause()

            elif choice == "4":
                quests = get_active_quests(self.state.quest_log)
                clear_screen()
                show_active_quests(
                    player,
                    self.state.quest_log,
                    quests,
                )
                pause()

            elif choice == "5":
                quests = get_ready_quests(
                    player,
                    self.state.quest_log,
                )
                clear_screen()
                show_ready_quests(quests)

                if not quests:
                    pause()
                    continue

                selected = input("> ").strip()
                if selected == "0":
                    continue

                try:
                    selected_index = int(selected) - 1
                    if not 0 <= selected_index < len(quests):
                        raise IndexError

                    quest = quests[selected_index]
                    result = turn_in_quest(
                        player,
                        self.state.quest_log,
                        quest.quest_id,
                    )
                    guild_update = record_story_quest_reputation(
                        self.state.guild_progress,
                        quest.quest_id,
                        quest.guild_reputation,
                    )
                    self._log(
                        f"Ukończono zadanie fabularne: "
                        f"{quest.title}."
                    )

                    unlocked = achievements_after_quest_turn_in(
                        player,
                        self.state.quest_log,
                        len(get_all_quests()),
                    )

                    clear_screen()
                    show_quest_turn_in(result)
                    self._show_guild_update(guild_update)
                    self._show_unlocked_achievements(unlocked)

                    try:
                        save_game(self.state, self.active_save_slot)
                        print(
                            "\nPostęp został zapisany "
                            "automatycznie."
                        )
                    except SaveGameError as save_error:
                        print(
                            "\nZadanie zostało ukończone, ale "
                            "automatyczny zapis nie powiódł się: "
                            f"{save_error}"
                        )
                except (ValueError, IndexError) as error:
                    message = (
                        str(error)
                        or "Nieprawidłowy numer zadania."
                    )
                    print(
                        f"\nNie udało się oddać zadania: "
                        f"{message}"
                    )
                pause()

            elif choice == "6":
                clear_screen()
                show_guild_ranks(self.state.guild_progress)
                pause()

            elif choice == "7":
                rank = current_guild_rank(self.state.guild_progress)
                rumors = available_guild_rumors(
                    rank.code,
                    market_unlocked=self.state.black_market.unlocked,
                    milestones=self.state.guild_progress.milestones,
                )
                clear_screen()
                if rumors:
                    rumor = self.rng.choice(rumors)
                    show_guild_rumor(rumor.text, rank.code)
                else:
                    show_guild_rumor("Dziś nawet najstarsi członkowie Gildii milczą.", rank.code)
                pause()

            elif choice == "8":
                self.run_companion_hub()

            elif choice == "9":
                self.run_rift_board()

            elif choice == "10":
                self.run_quartermaster()

            elif choice == "0":
                return

    def run_expedition_preparation(self) -> None:
        player = self.state.player
        if player is None:
            return
        locations = create_world_locations()

        while self.state.active_game:
            selected = next(
                (
                    location
                    for location in locations
                    if location.location_id == self.state.expedition_preparation.selected_location_id
                ),
                None,
            )
            clear_screen()
            choice = show_preparation_menu(
                player,
                self.state.party,
                self.state.guild_storage,
                self.state.expedition_preparation,
                selected,
            )
            if choice == "0":
                return
            if choice == "1":
                clear_screen()
                index = show_target_selection(player, locations)
                if index is not None:
                    self.state.expedition_preparation.selected_location_id = locations[index].location_id
                    self._save_silently()
                continue
            if choice == "2":
                self._run_party_setup()
                continue
            if choice == "3":
                self._run_companion_tactics()
                continue
            if choice == "4":
                self.run_equipment_menu()
                continue
            if choice == "5":
                self._preparation_withdraw_supplies()
                continue
            if choice == "6":
                self._preparation_use_consumable()
                continue
            if choice == "7":
                self.run_inn(create_city(self.state.current_city_id))
                continue
            if choice == "8":
                self._run_expedition_presets()
                continue
            if choice == "9":
                if selected is None:
                    print("\nNajpierw wybierz cel wyprawy.")
                    pause()
                    continue
                load = carry_status(player)
                if load.overloaded:
                    print("\nNie możesz wyruszyć z przeciążonym plecakiem.")
                    print(f"Udźwig: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg.")
                    pause()
                    continue
                warnings = [
                    warning
                    for warning in preparation_warnings(player, self.state.party)
                    if not warning.startswith("PRZECIĄŻENIE")
                ]
                clear_screen()
                if not show_departure_confirmation(warnings, selected.name):
                    continue
                self.state.current_location_id = selected.location_id
                self._save_silently()
                self.run_location()
                return
            print("\nNieprawidłowa opcja.")
            pause()

    def _preparation_withdraw_supplies(self) -> None:
        player = self.state.player
        if player is None:
            return
        temporary = Inventory()
        for item_id, quantity in self.state.guild_storage.inventory.stacks.items():
            definition = get_item_definition(item_id)
            if definition.is_consumable and quantity > 0:
                temporary.stacks[item_id] = quantity
        clear_screen()
        item_ids = show_storage_stack_selection(temporary, "ZAPASY Z MAGAZYNU GILDII")
        if not item_ids:
            pause()
            return
        selections = ask_storage_stack_multi_selection(temporary, item_ids)
        if selections is None:
            return
        try:
            # W ekranie przygotowania nie pozwalamy świadomie wyjść z miasta
            # już przeciążonym po dobraniu zapasów.
            from systems.carry_weight import carry_capacity, inventory_weight, stack_weight
            projected = inventory_weight(player.inventory) + sum(
                stack_weight(item_id, quantity)
                for item_id, quantity in selections.items()
            )
            capacity = carry_capacity(player)
            if projected > capacity + 1e-9:
                raise ValueError(
                    f"Te zapasy przekroczyłyby udźwig: {projected:.1f}/{capacity:.1f} kg."
                )
            withdraw_stacks(player, self.state.guild_storage, selections)
        except ValueError as error:
            print(f"\n{error}")
            pause()
            return
        self._save_silently()
        print("\nZabrano z Magazynu Gildii:")
        for item_id, quantity in selections.items():
            print(f"- {get_item_definition(item_id).name} x{quantity}")
        pause()

    def _preparation_use_consumable(self) -> None:
        player = self.state.player
        if player is None:
            return
        clear_screen()
        consumables = show_consumables(player)
        if not consumables:
            pause()
            return
        raw = input("> ").strip()
        if raw == "0":
            return
        try:
            item_id = consumables[int(raw) - 1]
            result = use_consumable(player, item_id)
        except (ValueError, IndexError) as error:
            print(f"\n{error}")
            pause()
            return
        self._save_silently()
        definition = get_item_definition(item_id)
        print(f"\nUżyto: {definition.name}.")
        if result.healed_hp:
            print(f"HP: +{result.healed_hp}")
        if result.restored_mana:
            print(f"Mana: +{result.restored_mana}")
        pause()

    def _run_companion_tactics(self) -> None:
        while True:
            clear_screen()
            companion_id = show_tactic_companion_selection(self.state.party)
            if companion_id is None:
                return
            companion = self.state.party.companion_by_id(companion_id)
            if companion is None:
                continue
            clear_screen()
            tactic = show_tactic_selection(companion)
            if tactic is None:
                continue
            try:
                set_companion_tactic(self.state.party, companion_id, tactic)
            except (KeyError, ValueError) as error:
                print(f"\n{error}")
                pause()
                continue
            self._save_silently()
            from companions.models import COMPANION_TACTICS
            print(f"\n{companion.name}: taktyka ustawiona na {COMPANION_TACTICS[tactic]}.")
            pause()

    def _run_expedition_presets(self) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            preset_id = show_preset_list(self.state.expedition_preparation)
            if preset_id is None:
                return
            while True:
                clear_screen()
                action = show_preset_actions(self.state.expedition_preparation, preset_id)
                if action == "0":
                    break
                if action == "1":
                    if self.state.rifts.expedition is not None:
                        print("\nNie możesz zmieniać składu podczas aktywnej ekspedycji Szczeliny.")
                        pause()
                        continue
                    try:
                        result = apply_preset(
                            self.state.expedition_preparation,
                            preset_id,
                            player,
                            self.state.party,
                            self.state.guild_storage,
                        )
                    except (ValueError, KeyError) as error:
                        print(f"\n{error}")
                        pause()
                        continue
                    self._save_silently()
                    print(f"\nZastosowano preset {PRESET_NAMES[preset_id]}.")
                    if result.activated_companions:
                        print("Aktywni: " + ", ".join(result.activated_companions))
                    elif preset_id == "solo":
                        print("Tryb: SOLO")
                    if result.withdrawn:
                        print("Uzupełniono zapasy:")
                        for item_id, quantity in result.withdrawn.items():
                            print(f"- {get_item_definition(item_id).name} x{quantity}")
                    if result.missing:
                        print("Brakuje w Magazynie:")
                        for item_id, quantity in result.missing.items():
                            print(f"- {get_item_definition(item_id).name} x{quantity}")
                    if result.unavailable_companions:
                        print("Niedostępni kompani: " + ", ".join(result.unavailable_companions))
                    pause()
                    continue
                if action == "2":
                    item_ids = healing_supply_ids(player, self.state.guild_storage)
                    totals = {
                        item_id: player.inventory.count(item_id) + self.state.guild_storage.inventory.count(item_id)
                        for item_id in item_ids
                    }
                    temporary = Inventory(stacks=dict(totals))
                    clear_screen()
                    show_preset_supply_catalog(item_ids, totals)
                    supplies = ask_storage_stack_multi_selection(temporary, item_ids) if item_ids else {}
                    if supplies is None:
                        supplies = {}
                    try:
                        save_preset(
                            self.state.expedition_preparation,
                            preset_id,
                            self.state.party,
                            supplies,
                        )
                    except (ValueError, KeyError) as error:
                        print(f"\n{error}")
                        pause()
                        continue
                    self._save_silently()
                    print(f"\nZapisano preset {PRESET_NAMES[preset_id]}.")
                    pause()
                    continue
                if action == "3":
                    clear_preset(self.state.expedition_preparation, preset_id)
                    self._save_silently()
                    print("\nPreset wyczyszczony.")
                    pause()
                    continue
                print("\nNieprawidłowa opcja.")
                pause()

    def run_quartermaster(self) -> None:
        player = self.state.player
        if player is None:
            return

        while True:
            clear_screen()
            choice = show_quartermaster_menu(player, self.state.guild_storage)
            if choice == "0":
                return
            if choice == "1":
                clear_screen()
                show_storage(player, self.state.guild_storage)
                pause()
                continue
            if choice == "2":
                self._quartermaster_deposit()
                continue
            if choice == "3":
                self._quartermaster_withdraw()
                continue
            if choice == "4":
                self._quartermaster_upgrade_carry()
                continue
            print("\nNieprawidłowa opcja.")
            pause()

    def _quartermaster_deposit(self) -> None:
        player = self.state.player
        if player is None:
            return
        clear_screen()
        choice = show_deposit_type_menu(player, self.state.guild_storage)
        if choice == "0":
            return

        try:
            moved_count = 0
            if choice == "1":
                clear_screen()
                item_ids = show_storage_stack_selection(
                    player.inventory,
                    "ODŁÓŻ — PRZEDMIOTY / MATERIAŁY",
                )
                if not item_ids:
                    pause()
                    return
                selections = ask_storage_stack_multi_selection(
                    player.inventory,
                    item_ids,
                )
                if selections is None:
                    return
                deposit_stacks(player, self.state.guild_storage, selections)
                moved_count = sum(selections.values())
                print("\nOdłożono do Magazynu Gildii:")
                for item_id, quantity in selections.items():
                    name = get_item_definition(item_id).name
                    self._log(f"Odłożono do Magazynu Gildii: {name} x{quantity}.")
                    print(f"- {name} x{quantity}")
            elif choice == "2":
                clear_screen()
                items = show_storage_equipment_selection(
                    player.inventory,
                    "ODŁÓŻ — WYPOSAŻENIE",
                )
                if not items:
                    pause()
                    return
                indexes = ask_storage_equipment_multi_selection(len(items))
                if indexes is None:
                    return
                moved = deposit_equipment_many(
                    player,
                    self.state.guild_storage,
                    indexes,
                )
                moved_count = len(moved)
                print("\nOdłożono do Magazynu Gildii:")
                for item in moved:
                    name = format_upgrade_name(item)
                    self._log(f"Odłożono do Magazynu Gildii: {name}.")
                    print(f"- {name}")
            else:
                print("\nNieprawidłowa opcja.")
                pause()
                return
        except (ValueError, IndexError) as error:
            print(
                "\nNie udało się odłożyć przedmiotów: "
                f"{error or 'Nieprawidłowy wybór.'}"
            )
            pause()
            return

        self._save_silently()
        load = carry_status(player)
        print(f"\nPrzeniesiono łącznie: {moved_count} szt./egz.")
        print(
            f"Udźwig: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg "
            f"({load.display_name})."
        )
        pause()

    def _quartermaster_withdraw(self) -> None:
        player = self.state.player
        if player is None:
            return
        clear_screen()
        choice = show_withdraw_type_menu(player, self.state.guild_storage)
        if choice == "0":
            return

        try:
            moved_count = 0
            if choice == "1":
                clear_screen()
                item_ids = show_storage_stack_selection(
                    self.state.guild_storage.inventory,
                    "ODBIERZ — PRZEDMIOTY / MATERIAŁY",
                )
                if not item_ids:
                    pause()
                    return
                selections = ask_storage_stack_multi_selection(
                    self.state.guild_storage.inventory,
                    item_ids,
                )
                if selections is None:
                    return
                withdraw_stacks(player, self.state.guild_storage, selections)
                moved_count = sum(selections.values())
                print("\nOdebrano z Magazynu Gildii:")
                for item_id, quantity in selections.items():
                    name = get_item_definition(item_id).name
                    self._log(f"Odebrano z Magazynu Gildii: {name} x{quantity}.")
                    print(f"- {name} x{quantity}")
            elif choice == "2":
                clear_screen()
                items = show_storage_equipment_selection(
                    self.state.guild_storage.inventory,
                    "ODBIERZ — WYPOSAŻENIE",
                )
                if not items:
                    pause()
                    return
                indexes = ask_storage_equipment_multi_selection(len(items))
                if indexes is None:
                    return
                moved = withdraw_equipment_many(
                    player,
                    self.state.guild_storage,
                    indexes,
                )
                moved_count = len(moved)
                print("\nOdebrano z Magazynu Gildii:")
                for item in moved:
                    name = format_upgrade_name(item)
                    self._log(f"Odebrano z Magazynu Gildii: {name}.")
                    print(f"- {name}")
            else:
                print("\nNieprawidłowa opcja.")
                pause()
                return
        except (ValueError, IndexError) as error:
            print(
                "\nNie udało się odebrać przedmiotów: "
                f"{error or 'Nieprawidłowy wybór.'}"
            )
            pause()
            return

        self._save_silently()
        load = carry_status(player)
        print(f"\nPrzeniesiono łącznie: {moved_count} szt./egz.")
        print(
            f"Udźwig: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg "
            f"({load.display_name})."
        )
        if load.overloaded:
            print(
                "Uwaga: jesteś przeciążony. Możesz zachować odebrane rzeczy, "
                "ale nie rozpoczniesz kolejnej zwykłej wyprawy regionalnej."
            )
        pause()

    def _quartermaster_upgrade_carry(self) -> None:
        player = self.state.player
        if player is None:
            return
        rank = current_guild_rank(self.state.guild_progress)
        clear_screen()
        show_carry_upgrade(player, rank.code)
        upgrade = next_carry_upgrade(player)
        if upgrade is None:
            pause()
            return
        choice = input("\n> ").strip()
        if choice != "1":
            return
        level, name, _bonus, cost, required_rank = upgrade
        if not has_guild_rank(self.state.guild_progress, required_rank):
            print(f"\nWymagana ranga Gildii: {required_rank}.")
            pause()
            return
        if player.gold < cost:
            print(
                f"\nBrakuje Golda. Potrzeba: {cost}, "
                f"masz: {player.gold}."
            )
            pause()
            return
        player.gold -= cost
        player.carry_upgrade_level = level
        self._log(
            f"Kwatermistrz ulepszył udźwig: {name} za {cost} Gold."
        )
        self._save_silently()
        load = carry_status(player)
        print(f"\nKupiono: {name}.")
        print(f"Nowy udźwig: {load.capacity_kg:.1f} kg.")
        pause()

    def run_companion_hub(self) -> None:
        player = self.state.player
        if player is None:
            return
        self._refresh_party_world()
        rank = current_guild_rank(self.state.guild_progress)
        if ensure_daily_candidates(
            self.state.party, player, self.state.world_clock.day, rank.code
        ):
            self._save_silently()

        while True:
            clear_screen()
            choice = show_companion_hub(self.state.party)
            if choice == "0":
                return
            if choice == "1":
                while True:
                    clear_screen()
                    index = show_companion_list(self.state.party)
                    if index is None:
                        break
                    if 0 <= index < len(self.state.party.companions):
                        self._run_companion_detail(self.state.party.companions[index])
                continue
            if choice == "2":
                self._run_party_setup()
                continue
            if choice == "3":
                self._run_candidate_board()
                continue
            if choice == "4":
                clear_screen()
                show_messages(self.state.party)
                mark_messages_read(self.state.party)
                self._save_silently()
                pause()
                continue
            if choice == "5":
                clear_screen()
                show_fallen(self.state.party)
                pause()

    def _run_party_setup(self) -> None:
        if self.state.rifts.expedition is not None:
            clear_screen()
            print("Skład ekspedycji jest już związany ze Szczeliną.")
            print("Najpierw zakończ albo porzuć trwającą ekspedycję.")
            pause()
            return

        while True:
            clear_screen()
            action, companion_id = show_party_setup(self.state.party)
            if action == "done":
                return
            if action == "solo":
                changed = set_party_solo(self.state.party)
                self._save_silently()
                if changed:
                    print("\nTryb SOLO ustawiony. Wszyscy kompani pozostają w Varenhold.")
                else:
                    print("\nJuż podróżujesz solo.")
                pause()
                continue
            if action == "toggle" and companion_id is not None:
                companion = self.state.party.companion_by_id(companion_id)
                if companion is None:
                    continue
                try:
                    set_companion_active(self.state.party, companion_id, not companion.active)
                    self._save_silently()
                except (ValueError, KeyError) as error:
                    print(f"\n{error}")
                    pause()
                continue

    def _run_candidate_board(self) -> None:
        player = self.state.player
        if player is None:
            return
        rank = current_guild_rank(self.state.guild_progress)
        while True:
            scores = {
                candidate.candidate_id: candidate_willingness_score(
                    candidate, player, rank.code, self.state.rifts.completed_total
                )
                for candidate in self.state.party.candidates
            }
            clear_screen()
            index = show_candidate_list(self.state.party.candidates, rank.code, scores)
            if index is None:
                return
            if not 0 <= index < len(self.state.party.candidates):
                continue
            candidate = self.state.party.candidates[index]
            while True:
                score = candidate_willingness_score(
                    candidate, player, rank.code, self.state.rifts.completed_total
                )
                clear_screen()
                choice = show_candidate(candidate, score)
                if choice == "0":
                    break
                if choice == "1":
                    if candidate.talked:
                        print("\nRozmawialiście już dziś. Dalsze naciskanie nie zmieni jego decyzji.")
                        pause()
                        continue
                    clear_screen()
                    talk_choice = show_candidate_talk_choices(candidate.companion.name)
                    if talk_choice is None:
                        continue
                    from systems.companions import talk_to_candidate
                    text = talk_to_candidate(candidate, talk_choice)
                    print(f"\n{text}")
                    self._save_silently()
                    pause()
                    continue
                if choice == "2":
                    if self.state.rifts.expedition is not None:
                        print("\nNie możesz zmieniać składu stałej drużyny w trakcie ekspedycji Szczeliny.")
                        pause()
                        continue
                    try:
                        success, text, final_score = recruit_candidate(
                            self.state.party, candidate, player, rank.code,
                            self.state.rifts.completed_total,
                        )
                    except ValueError as error:
                        print(f"\n{error}")
                        pause()
                        continue
                    print(f"\n{text}")
                    print(f"Nastawienie przy decyzji: {final_score}/100")
                    if success:
                        print("\nNowy kompan dołączył do twojej drużyny. Dopiero teraz możesz zobaczyć jego pełny ekwipunek.")
                        self._log(f"Do drużyny dołączył kompan: {candidate.companion.name}.")
                    self._save_silently()
                    pause()
                    break

    def _run_companion_detail(self, companion) -> None:
        player = self.state.player
        if player is None:
            return
        while companion in self.state.party.companions:
            clear_screen()
            choice = show_companion_detail(companion, self.state.world_clock.day)
            if choice == "0":
                return
            if choice == "1":
                self._run_companion_equipment(companion)
                continue
            if choice == "2":
                clear_screen()
                show_companion_build(companion)
                pause()
                continue
            if choice == "3":
                available = available_personal_stage(companion)
                if available is None:
                    from data.companions import COMPANION_TEMPLATES
                    template = COMPANION_TEMPLATES[companion.template_id]
                    clear_screen()
                    print(f"{companion.name}: „{self.rng.choice(template.idle_lines)}”")
                    pause()
                    continue
                arc, stage = available
                clear_screen()
                selected = show_personal_stage(companion, arc, stage)
                if selected is None:
                    continue
                try:
                    title, response, relation = complete_personal_stage(companion, selected)
                except ValueError as error:
                    print(f"\n{error}")
                    pause()
                    continue
                clear_screen()
                print(f"{companion.name}: „{response}”")
                print(f"\nRelacja: {relation:+d}")
                self._log(f"Historia kompana {companion.name}: {title}.")
                self._save_silently()
                pause()
                continue
            if choice == "4":
                if self.state.rifts.expedition is not None:
                    print("\nSkład ekspedycji jest już związany ze Szczeliną. Najpierw ją zakończ albo porzuć.")
                    pause()
                    continue
                try:
                    set_companion_active(self.state.party, companion.companion_id, not companion.active)
                    self._save_silently()
                except (ValueError, KeyError) as error:
                    print(f"\n{error}")
                    pause()
                continue
            if choice == "5":
                if self.state.rifts.expedition is not None:
                    print("\nNie możesz rozstać się z kompanem w trakcie ekspedycji Szczeliny.")
                    pause()
                    continue
                print(f"\nCzy na pewno chcesz rozstać się z {companion.name}?")
                print("Jego historia i osobisty ekwipunek pozostaną jego własnością. Twoje powierzone przedmioty wrócą do plecaka.")
                confirm = input("Potwierdź [T/N]: ").strip().lower()
                if confirm not in {"t", "tak", "y", "yes"}:
                    continue
                dismissed = dismiss_companion(
                    self.state.party, player, companion.companion_id, self.state.world_clock.day
                )
                from data.companions import COMPANION_TEMPLATES
                print(f"\n{dismissed.name}: „{COMPANION_TEMPLATES[dismissed.template_id].farewell}”")
                self._log(f"Drużyna rozstała się z {dismissed.name}.")
                self._save_silently()
                pause()
                return

    def _run_companion_equipment(self, companion) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            choice = show_companion_equipment(companion)
            if choice == "0":
                return
            if choice == "1":
                clear_screen()
                inventory_index = show_companion_equippable_inventory(player, companion)
                if inventory_index is None:
                    continue
                try:
                    item = equip_player_item_to_companion(player, companion, inventory_index)
                    print(f"\n{get_item_definition(item.item_id).name} został powierzony kompanowi {companion.name}.")
                    self._save_silently()
                except (ValueError, IndexError) as error:
                    print(f"\n{error}")
                pause()
                continue
            if choice == "2":
                clear_screen()
                slot = show_companion_loaned_slots(companion)
                if slot is None:
                    continue
                try:
                    item = remove_player_item_from_companion(player, companion, slot)
                    print(f"\nOdzyskano: {get_item_definition(item.item_id).name}.")
                    self._save_silently()
                except ValueError as error:
                    print(f"\n{error}")
                pause()

    def run_rift_board(self) -> None:
        player = self.state.player
        if player is None:
            return
        self._refresh_party_world()
        while True:
            clear_screen()
            choice = show_rift_board(self.state.rifts, self.state.world_clock.day)
            if choice == "0":
                return
            if self.state.rifts.expedition is not None:
                if choice == "1":
                    self.run_rift_expedition()
                    continue
                if choice == "2":
                    print("\nPorzucić trwającą ekspedycję? Szczelina znów stanie się dostępna dla innych drużyn.")
                    confirm = input("Potwierdź [T/N]: ").strip().lower()
                    if confirm in {"t", "tak", "y", "yes"}:
                        abandon_rift_expedition(self.state.rifts, self.state.world_clock.day)
                        self._log("Porzucono ekspedycję Szczeliny.")
                        self._save_silently()
                    continue
            if choice == "1" and self.state.rifts.active_rift is not None:
                rank = current_guild_rank(self.state.guild_progress)
                active = self.state.party.active_companions()
                allowed, reason = can_start_rift(
                    self.state.rifts.active_rift, len(active), rank.code
                )
                if not allowed:
                    print(f"\nNie możesz rozpocząć ekspedycji: {reason}")
                    pause()
                    continue
                start_rift_expedition(
                    self.state.rifts, self.state.world_clock.day,
                    tuple(companion.companion_id for companion in active),
                )
                self._log(
                    f"Rozpoczęto ekspedycję: {self.state.rifts.active_rift.theme_name} "
                    f"rangi {self.state.rifts.active_rift.rank_code}."
                )
                self._save_silently()
                self.run_rift_expedition()

    def _rift_companions(self):
        expedition = self.state.rifts.expedition
        if expedition is None:
            return []
        wanted = set(expedition.party_companion_ids)
        return [
            companion for companion in self.state.party.companions
            if companion.companion_id in wanted and not companion.dead and not companion.is_injured
        ]

    def _rift_camp(self, rift, expedition) -> None:
        player = self.state.player
        if player is None:
            return
        clear_screen()
        show_rift_segment(rift, expedition)
        print("Drużyna znajduje skrawek stabilnej przestrzeni. Na kilka chwil można opuścić broń.")
        lines = camp_banter(self.state.party, rift.seed + expedition.segment_index)
        if lines:
            print()
            for line in lines:
                print(line)
        healed = max(1, int(round(player.stats.max_hp * 0.25)))
        mana = max(1, int(round(player.stats.max_mana * 0.25))) if player.stats.max_mana else 0
        player.stats.heal(healed)
        if mana:
            player.stats.restore_mana(mana)
        for companion in self._rift_companions():
            from systems.companions import companion_to_player
            actor = companion_to_player(companion)
            current_hp = actor.stats.current_hp
            current_mana = actor.stats.current_mana
            actor.stats.heal(max(1, int(round(actor.stats.max_hp * 0.25))))
            if actor.stats.max_mana:
                actor.stats.restore_mana(max(1, int(round(actor.stats.max_mana * 0.25))))
            companion.current_hp = actor.stats.current_hp
            companion.current_mana = actor.stats.current_mana
        expedition.camp_visits += 1
        print("\nOdpoczynek przywraca 25% HP i Many żyjącym członkom ekspedycji.")
        pause()

    def _process_rift_casualties(self, result, engine, rift) -> None:
        player = self.state.player
        if player is None:
            return
        for fighter in engine.companion_fighters:
            companion = next(
                (item for item in self.state.party.companions if item.companion_id == fighter.companion_id),
                None,
            )
            if companion is not None:
                sync_companion_from_player(companion, fighter.combatant)
        for companion_id in result.critically_injured:
            companion = self.state.party.companion_by_id(companion_id)
            if companion is None:
                continue
            days = self.rng.randint(2, 5)
            critically_injure(companion, self.state.world_clock.day, days)
            self.state.party.messages.append(
                __import__("companions.models", fromlist=["PartyMessage"]).PartyMessage(
                    self.state.world_clock.day, companion.companion_id, companion.name,
                    f"Mirela kazała mi leżeć. Powrót do sił: około {days} dni Pythonii. Spróbujcie nie zamknąć świata beze mnie.", False,
                )
            )
        for companion_id in result.killed:
            companion = self.state.party.companion_by_id(companion_id)
            if companion is None:
                continue
            kill_companion(
                self.state.party, player, companion, self.state.world_clock.day,
                f"Egzekucja {engine.enemy.name} po pozostawieniu w stanie Powalenia.",
                rift.rank_code,
            )

    def _run_rift_battle(self, rift, expedition, kind: str) -> bool:
        player = self.state.player
        if player is None:
            return False
        companions = self._rift_companions()
        profile = create_rift_enemy(rift, player.level, expedition.segment_index, kind)
        engine = RiftBattleEngine(player, companions, profile, rift, self.rng)
        while engine.enemy_alive():
            clear_screen()
            show_rift_party_status(
                player, engine.all_fighters, profile.name, engine.enemy_hp,
                profile.max_hp, engine.round_number,
            )
            action, target = ask_rift_player_action(engine)
            if action == "skill" and target is not None:
                result = engine.player_skill(target)
            elif action == "defend":
                result = engine.player_defend()
            elif action == "help" and target is not None:
                result = engine.player_help(target)
            else:
                result = engine.player_basic_attack()
            clear_screen()
            show_rift_party_status(
                player, engine.all_fighters, profile.name, engine.enemy_hp,
                profile.max_hp, engine.round_number,
            )
            show_rift_round(result.lines)
            self._process_rift_casualties(result, engine, rift)
            self._save_silently()
            if result.defeat:
                if player.stats.current_hp <= 0:
                    player.stats.current_hp = 1
                self.state.rifts.expedition = None
                self._log(f"Ekspedycja w Szczelinie rangi {rift.rank_code} zakończyła się porażką.")
                print("\nDrużyna zostaje wyciągnięta z rozpadającego się odcinka Szczeliny. Jeśli alarm nadal obowiązuje, możecie przygotować nową próbę.")
                self._save_silently()
                pause()
                return False
            if result.victory:
                rank_index = "FEDCBAS".index(rift.rank_code)
                base_exp = 18 + rank_index * 8 + (18 if kind == "elite" else 0) + (35 if kind == "miniboss" else 0)
                for companion in companions:
                    if self.state.party.companion_by_id(companion.companion_id) is not None and not companion.is_injured:
                        gained = gain_companion_experience(companion, base_exp)
                        if gained:
                            self._log(f"{companion.name} awansuje na poziom {companion.level}.")
                pause()
                return True
            pause()
        return True

    def run_rift_expedition(self) -> None:
        player = self.state.player
        rift = self.state.rifts.active_rift
        expedition = self.state.rifts.expedition
        if player is None or rift is None or expedition is None:
            return
        while self.state.rifts.expedition is not None and self.state.rifts.active_rift is not None:
            rift = self.state.rifts.active_rift
            expedition = self.state.rifts.expedition
            if expedition.segment_index >= rift.segment_count:
                return
            kind = rift_segment_kind(rift, expedition.segment_index)
            clear_screen()
            show_rift_segment(rift, expedition)

            if kind == "event":
                title, text = rift_event_text(rift, expedition.segment_index)
                print(title.upper())
                print()
                print(text)
                print("\nSzczelina nie daje wam pewności, czy to wspomnienie, ostrzeżenie czy zwykłe kłamstwo przestrzeni.")
                expedition.segment_index += 1
                self._save_silently()
                pause()
                continue
            if kind == "camp":
                self._rift_camp(rift, expedition)
                expedition.segment_index += 1
                self._save_silently()
                continue

            if not self._run_rift_battle(rift, expedition, kind):
                return

            if kind == "boss":
                companion_ids = expedition.party_companion_ids
                reward = resolve_rift_completion(self.state.rifts, player, self.rng)
                surviving = [
                    companion for companion in self.state.party.companions
                    if companion.companion_id in set(companion_ids) and not companion.dead
                ]
                for companion in surviving:
                    gain_companion_experience(companion, max(50, int(round(reward.experience * 0.60))))
                record_rift_together(self.state.party, companion_ids)
                unique_name = (
                    get_item_definition(reward.unique_item_id).name
                    if reward.unique_item_id is not None else None
                )
                clear_screen()
                show_rift_completion(rift, reward, unique_name)
                self._log(f"Zamknięto Szczelinę rangi {rift.rank_code}: {rift.theme_name}.")
                self._save_silently()
                pause()
                return

            expedition.segment_index += 1
            self._save_silently()

    def run_hero_hub(self) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            choice = show_hero_hub_menu(player)
            if choice == "1":
                clear_screen(); show_hero_status(player, self.state.guild_progress); pause()
            elif choice == "2":
                self.run_inventory_menu()
            elif choice == "3":
                self.run_equipment_menu()
            elif choice == "4":
                self.run_attribute_menu()
            elif choice == "5":
                self.run_passive_menu()
            elif choice == "6":
                self.run_achievement_menu()
            elif choice == "7":
                clear_screen(); show_adventure_log(self.state.adventure_log); pause()
            elif choice == "8":
                if player.character_class is PlayerClass.NONE:
                    self.run_class_selection()
                else:
                    self.run_skill_development_menu()
            elif choice == "0":
                return

    def run_skill_development_menu(self) -> None:
        player = self.state.player
        if player is None or player.character_class is PlayerClass.NONE:
            return
        while True:
            clear_screen()
            choice = show_skill_hub(player)
            if choice == "0":
                return
            if choice == "1":
                clear_screen(); show_active_skills(player); pause(); continue
            if choice == "4" and player.character_class.code == "hunter":
                clear_screen(); show_hunter_combos(player); pause(); continue
            if choice == "3":
                from player.talents import reset_tree_cost, spent_tree_points
                spent = spent_tree_points(player.talents)
                if spent <= 0:
                    print("\nNie wydano jeszcze żadnych punktów drzewka.")
                    pause(); continue
                cost = reset_tree_cost(player)
                print(f"\nReset zwróci {spent} punktów. Koszt: {cost} Gold.")
                confirm = input("Potwierdź [T/N]: ").strip().lower()
                if confirm not in {"t", "tak", "y", "yes"}:
                    continue
                try:
                    paid = reset_talents(player)
                    self._log(f"Zresetowano drzewko klasy za {paid} Gold.")
                    self._save_silently()
                    print(f"\nDrzewko zostało zresetowane. Zapłacono {paid} Gold.")
                except ValueError as error:
                    print(f"\n{error}")
                pause(); continue
            if choice == "2":
                while True:
                    clear_screen()
                    selectable = show_talent_tree(player)
                    selected = input("> ").strip()
                    if selected == "0":
                        break
                    try:
                        talent_id = selectable[int(selected) - 1]
                        rank = learn_talent(player, talent_id)
                        from data.talents import TALENT_DATA
                        talent = TALENT_DATA[talent_id]
                        self._log(f"Rozwinięto talent {talent.name} do rangi {rank}.")
                        self._save_silently()
                        print(f"\n{talent.name}: ranga {rank}/{talent.max_rank}.")
                    except (ValueError, IndexError) as error:
                        print(f"\nNie udało się rozwinąć talentu: {error or 'Nieprawidłowy numer.'}")
                    pause()

    def run_class_selection(self) -> None:
        player = self.state.player
        if player is None:
            return

        if player.character_class is not PlayerClass.NONE:
            clear_screen()
            show_active_skills(player)
            pause()
            return

        if not player.can_choose_class:
            clear_screen()
            show_active_skills(player)
            pause()
            return

        clear_screen()
        show_class_selection(player)
        choice = input("> ").strip()

        if choice == "0":
            return

        player_class = get_class_from_choice(choice)
        if player_class is None:
            print("\nNieprawidłowa opcja.")
            pause()
            return

        try:
            player.choose_class(player_class)
        except ValueError as error:
            print(f"\n{error}")
            pause()
            return

        self._log(
            f"Wybrano Drogę bohatera: "
            f"{player.character_class.display_name}."
        )

        clear_screen()
        show_active_skills(player)
        print(
            f"\nWybrano Drogę: "
            f"{player.character_class.display_name}."
        )

        try:
            save_game(self.state, self.active_save_slot)
            print("\nWybór klasy został zapisany automatycznie.")
        except SaveGameError as save_error:
            print(
                "\nKlasa została wybrana, ale automatyczny zapis "
                f"nie powiódł się: {save_error}"
            )

        pause()

    def run_passive_menu(self) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            show_passives_menu(player)
            choice = input("> ").strip()
            if choice == "0":
                return
            passive = get_passive_from_choice(choice)
            if passive is None:
                print("\nNieprawidłowa opcja."); pause(); continue

            if can_choose_passive_specialization(player, passive):
                clear_screen()
                options = show_passive_specialization_choice(passive)
                selected = input("> ").strip()
                if selected == "0":
                    continue
                try:
                    spec_id = options[int(selected) - 1]
                    choose_passive_specialization(player, passive, spec_id)
                    from data.passive_specializations import PASSIVE_SPECIALIZATIONS
                    spec = PASSIVE_SPECIALIZATIONS[spec_id]
                    self._log(f"Wybrano specjalizację pasywki: {spec.name}.")
                    self._save_silently()
                    print(f"\nWybrano: {spec.name}.")
                except (ValueError, IndexError) as error:
                    print(f"\n{error or 'Nieprawidłowy wybór.'}")
                pause(); continue

            available = player.available_passive_points
            current = player.passives.get(passive)
            maximum_for_passive = player.passive_level_cap(passive) - current
            maximum = min(available, maximum_for_passive)
            if maximum <= 0:
                if maximum_for_passive <= 0:
                    print("\nTa umiejętność pasywna ma już maksymalny poziom.")
                else:
                    print("\nBrak wolnych punktów umiejętności pasywnych.")
                pause(); continue
            amount = ask_point_quantity(maximum)
            if amount is None:
                continue
            try:
                player.spend_passive_points(passive, amount)
                self._log(
                    f"Rozwinięto pasywkę {passive.display_name} o {amount} pkt, "
                    f"do poziomu {player.passives.get(passive)}."
                )
                print(f"\n{passive.display_name}: +{amount} pkt -> poziom {player.passives.get(passive)}.")
            except ValueError as error:
                print(f"\n{error}"); pause(); continue

            if can_choose_passive_specialization(player, passive):
                clear_screen()
                options = show_passive_specialization_choice(passive)
                selected = input("> ").strip()
                if selected != "0":
                    try:
                        spec_id = options[int(selected) - 1]
                        choose_passive_specialization(player, passive, spec_id)
                        from data.passive_specializations import PASSIVE_SPECIALIZATIONS
                        spec = PASSIVE_SPECIALIZATIONS[spec_id]
                        self._log(f"Wybrano specjalizację pasywki: {spec.name}.")
                        self._save_silently()
                        print(f"\nWybrano: {spec.name}.")
                    except (ValueError, IndexError) as error:
                        print(f"\n{error or 'Nieprawidłowy wybór.'}")
            pause()

    def run_achievement_menu(self) -> None:
        player = self.state.player
        if player is None: return
        while True:
            clear_screen(); choice=show_achievement_menu(player)
            if choice=="1":
                clear_screen(); show_achievements(player); pause()
            elif choice=="2":
                clear_screen(); titles=show_titles(player)
                selected=input("> ").strip()
                if selected=="0": continue
                try:
                    index=int(selected)-1
                    if not 0 <= index < len(titles): raise IndexError
                    player.achievements.equip_title(titles[index])
                    self._log(f"Wybrano tytuł: {titles[index]}.")
                    print(f"\nAktywny tytuł: {titles[index]}")
                except (ValueError,IndexError) as error:
                    print(f"\nNie udało się wybrać tytułu: {error or 'Nieprawidłowy numer.'}")
                pause()
            elif choice=="0": return

    def run_merchant(self) -> None:
        player = self.state.player
        if player is None: return
        stock=get_merchant_stock()
        while True:
            clear_screen(); choice=show_merchant_menu(player)
            if choice=="1":
                clear_screen(); show_buy_menu(player,stock)
                selected=input("> ").strip()
                if selected=="0": continue
                try:
                    index=int(selected)-1
                    if not 0 <= index < len(stock): raise IndexError
                    entry=stock[index]
                    quantity=ask_buy_quantity(player,entry)
                    if quantity is None: continue
                    total=buy_item(player,entry,quantity)
                    name=get_item_definition(entry.item_id).name
                    self._log(f"Kupiono {name} x{quantity} za {total} Gold.")
                    print(f"\nKupiono: {name} x{quantity} za {total} Gold.")
                except (ValueError,IndexError) as error:
                    print(f"\nNie udało się kupić: {error or 'Nieprawidłowy numer.'}")
                pause()
            elif choice=="2":
                item_ids=get_sellable_stacks(player)
                clear_screen(); show_stack_sell_menu(player,item_ids)
                if not item_ids:
                    pause()
                    continue
                try:
                    sales=ask_stack_sale_selection(player,item_ids)
                    if sales is None:
                        continue

                    clear_screen()
                    show_stack_sale_confirmation(player,sales)
                    confirm=input("> ").strip()
                    if confirm!="1":
                        continue

                    sold,total=sell_stack_items(player,sales)
                    summary=", ".join(
                        f"{get_item_definition(item_id).name} x{quantity}"
                        for item_id,quantity,_ in sold
                    )
                    self._log(
                        f"Sprzedano u Orena: {summary} za {total} Gold."
                    )
                    print(
                        f"\nSprzedano {len(sold)} rodzajów przedmiotów "
                        f"za łącznie {total} Gold."
                    )
                except (ValueError,IndexError) as error:
                    print(f"\nNie udało się sprzedać: {error}")
                pause()
            elif choice=="3":
                clear_screen(); show_equipment_sell_menu(player)
                if not player.inventory.equipment_items:
                    pause()
                    continue
                try:
                    indexes=ask_equipment_sale_selection(player)
                    if indexes is None:
                        continue

                    clear_screen()
                    show_equipment_sale_confirmation(player,indexes)
                    confirm=input("> ").strip()
                    if confirm!="1":
                        continue

                    sold,total=sell_equipment_items(player,indexes)
                    summary=", ".join(
                        format_upgrade_name(item)
                        for item,_ in sold
                    )
                    self._log(
                        f"Sprzedano wyposażenie u Orena: "
                        f"{summary} za {total} Gold."
                    )
                    print(
                        f"\nSprzedano {len(sold)} szt. wyposażenia "
                        f"za łącznie {total} Gold."
                    )
                except (ValueError,IndexError) as error:
                    print(f"\nNie udało się sprzedać: {error}")
                pause()
            elif choice=="0": return

    def run_inn(self, city) -> None:
        player=self.state.player
        if player is None: return
        while True:
            informant_present = check_informant_for_day(
                self.state.black_market,
                self.state.guild_progress,
                self.state.quest_log,
                self.state.world_clock.day,
                self.rng,
            )
            # Pierwsza próba danego dnia jest częścią stanu świata, więc
            # zapisujemy ją od razu. Restart nie przerzuca informatora.
            self._save_silently()
            clear_screen(); choice=show_inn_menu(
                player,
                city,
                current_day=self.state.world_clock.day,
                last_inn_rest_day=self.state.last_inn_rest_day,
                informant_present=informant_present,
            )
            if choice=="1":
                try:
                    result = rest_at_inn(
                        player,
                        self.state.world_clock,
                        last_inn_rest_day=self.state.last_inn_rest_day,
                    )
                    self.state.last_inn_rest_day = result.next_available_day - 1
                    self._advance_weather(INN_REST_DURATION_HOURS)
                    self._log(
                        f"Nocleg w Karczmie Pod Czarnym Krukiem: -{result.gold_cost} Gold, pełne HP i Mana."
                    )
                    print(
                        f"\nOdpoczywasz w bezpiecznym pokoju. "
                        f"Odzyskano {result.healed_hp} HP i {result.restored_mana} Many."
                    )
                    print(f"Koszt: {result.gold_cost} Gold.")
                    print(f"Kolejny pełny nocleg: od Dnia {result.next_available_day}.")
                    self._save_silently()
                except ValueError as error: print(f"\n{error}")
                pause()
            elif choice=="2":
                print(f"\nKarczmarka Mara: \"{self.rng.choice(city.rumors)}\""); pause()
            elif choice=="3":
                clear_screen()
                show_informant_scene()
                unlock_black_market(self.state.black_market)
                self._log("Odkryto drogę na Czarny Rynek.")
                self._save_silently()
                pause()
            elif choice=="0": return

    def run_black_market(self) -> None:
        player = self.state.player
        if player is None or not self.state.black_market.unlocked:
            return

        if ensure_black_market_rotation(
            self.state.black_market, player.name
        ):
            self._save_silently()

        while True:
            clear_screen()
            choice = show_black_market_menu(player, self.state.black_market)
            if choice == "0":
                return

            if choice == "1":
                clear_screen()
                offers = show_black_market_offers(player, self.state.black_market)
                selected = input("> ").strip()
                if selected == "0":
                    continue
                try:
                    offer = offers[int(selected) - 1]
                except (ValueError, IndexError):
                    print("\nNieprawidłowa oferta.")
                    pause()
                    continue

                action = show_buy_offer_actions(self.state.black_market, offer)
                if action == "0":
                    continue
                if action == "2":
                    try:
                        result = bargain_buy(self.state.black_market, offer, self.rng)
                        # Wynik targowania zapisujemy zanim gracz zdecyduje, czy kupuje.
                        self._save_silently()
                        show_bargain_result(result.success, result.old_price, result.new_price)
                    except ValueError as error:
                        print(f"\n{error}")
                    pause()
                    continue
                if action != "1":
                    print("\nNieprawidłowa opcja.")
                    pause()
                    continue
                try:
                    paid = buy_black_market_offer(player, self.state.black_market, offer)
                    definition = get_item_definition(offer.item_id)
                    self._log(
                        f"Czarny Rynek: kupiono {definition.name} "
                        f"za {paid} Gold."
                    )
                    self._save_silently()
                    print(f"\nKupiono: {definition.name} za {paid} Gold.")
                except ValueError as error:
                    print(f"\nNie udało się kupić: {error}")
                pause()

            elif choice == "2":
                clear_screen()
                books = show_book_sell_menu(player, self.state.black_market)
                if not books:
                    pause()
                    continue
                selected = input("> ").strip()
                if selected == "0":
                    continue
                try:
                    item_id = books[int(selected) - 1]
                except (ValueError, IndexError):
                    print("\nNieprawidłowa księga.")
                    pause()
                    continue
                action = show_sell_book_actions(self.state.black_market, item_id)
                if action == "0":
                    continue
                if action == "2":
                    try:
                        result = bargain_book_sale(
                            self.state.black_market, item_id, self.rng
                        )
                        self._save_silently()
                        show_bargain_result(
                            result.success, result.old_price, result.new_price, selling=True
                        )
                    except ValueError as error:
                        print(f"\n{error}")
                    pause()
                    continue
                if action != "1":
                    print("\nNieprawidłowa opcja.")
                    pause()
                    continue
                try:
                    earned = sell_mastery_book(
                        player, self.state.black_market, item_id, 1
                    )
                    definition = get_item_definition(item_id)
                    self._log(
                        f"Czarny Rynek: sprzedano {definition.name} "
                        f"za {earned} Gold."
                    )
                    self._save_silently()
                    print(f"\nSprzedano: {definition.name} za {earned} Gold.")
                except ValueError as error:
                    print(f"\nNie udało się sprzedać: {error}")
                pause()

    def run_blacksmith_menu(self) -> None:
        player=self.state.player
        if player is None: return
        while True:
            targets=get_upgrade_targets(player)
            clear_screen(); show_blacksmith_menu(player,targets)
            choice=input("> ").strip()
            if choice=="0": return
            try:
                index=int(choice)-1
                if not 0 <= index < len(targets): raise IndexError
                target=targets[index]
                old_level=target.item.upgrade_level
                levels=ask_upgrade_quantity(player,target)
                if levels is None:
                    continue

                plan=get_upgrade_plan(old_level,levels,target.item)
                clear_screen(); show_upgrade_preview(target,plan)
                if not ask_upgrade_confirmation():
                    continue

                upgrade_item_levels(player,target.item,levels)
                self._log(
                    f"Ulepszono {get_item_definition(target.item.item_id).name} "
                    f"z +{old_level} do +{target.item.upgrade_level}."
                )
                unlocked=achievements_after_upgrade(
                    player,target.item.upgrade_level
                )
            except (ValueError,IndexError) as error:
                print(f"\nNie udało się ulepszyć: {error or 'Nieprawidłowy numer.'}"); pause(); continue
            clear_screen(); show_upgrade_result(target,old_level); self._show_unlocked_achievements(unlocked); pause()

    def run_inventory_menu(self) -> None:
        player = self.state.player
        if player is None: return
        while True:
            clear_screen(); show_inventory_menu(player)
            choice = input("> ").strip()
            if choice == "0": return
            if choice == "1":
                self.use_consumable_from_inventory()
            elif choice == "2":
                self.show_inventory_equipment_details()
            elif choice == "3":
                self.run_books_menu()
            elif choice == "4":
                self.show_inventory_item_usage()
            else:
                print("\nNieprawidłowa opcja.")
                pause()

    def show_inventory_item_usage(self) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            items = show_item_usage_selection(player)
            if not items:
                pause()
                return
            choice = input("> ").strip()
            if choice == "0":
                return
            try:
                item_id = items[int(choice) - 1]
            except (ValueError, IndexError):
                print("\nNieprawidłowy wybór.")
                pause()
                continue
            clear_screen()
            show_item_usage(item_id)
            pause()

    def run_books_menu(self) -> None:
        player = self.state.player
        if player is None:
            return
        while True:
            clear_screen()
            books = show_books(player)
            if not books:
                pause(); return
            choice = input("> ").strip()
            if choice == "0":
                return
            try:
                item_id = books[int(choice) - 1]
                book = get_book_definition(item_id)
                definition = get_item_definition(item_id)
                if book.book_type is BookType.MASTERY:
                    result = read_mastery_book(player, item_id)
                    message = f"Odblokowano Mistrzostwo 6–10: {result.passive.display_name}."
                    log = f"Przeczytano {definition.name}; odblokowano Mistrzostwo: {result.passive.display_name}."
                else:
                    result = read_path_book(player, item_id)
                    from data.talents import CLASS_PATHS
                    path = CLASS_PATHS[result.path_id]
                    message = f"Odblokowano Ścieżkę: {path.name}."
                    log = f"Przeczytano {definition.name}; odblokowano Ścieżkę: {path.name}."
                self._log(log)
                self._save_silently()
                print(f"\n{message}")
            except (ValueError, IndexError) as error:
                print(f"\nNie udało się przeczytać księgi: {error}")
            pause()

    def show_inventory_equipment_details(self) -> None:
        player = self.state.player
        if player is None:
            return
        clear_screen()
        show_equipment_detail_selection(player)
        if not player.inventory.equipment_items:
            pause()
            return
        choice = input("> ").strip()
        if choice == "0":
            return
        try:
            item = player.inventory.equipment_items[int(choice) - 1]
        except (ValueError, IndexError):
            print("\nNieprawidłowy wybór.")
            pause()
            return
        clear_screen()
        show_equipment_details(item)
        pause()

    def use_consumable_from_inventory(self) -> None:
        player = self.state.player
        if player is None: return
        clear_screen(); consumables = show_consumables(player)
        if not consumables: pause(); return
        choice = input("> ").strip()
        if choice == "0": return
        try:
            item_id = consumables[int(choice) - 1]
            definition = get_item_definition(item_id)
            result = use_consumable(player, item_id)
            restored: list[str] = []
            if result.healed_hp:
                restored.append(f"{result.healed_hp} HP")
            if result.restored_mana:
                restored.append(f"{result.restored_mana} Many")
            print(
                f"\nUżyto: {definition.name}. Przywrócono "
                + " i ".join(restored)
                + "."
            )
        except (ValueError, IndexError) as error:
            print(f"\n{error}")
        pause()

    def run_crafting_menu(self) -> None:
        player = self.state.player
        if player is None:
            return
        all_recipes = get_all_recipes()
        while True:
            clear_screen()
            categories = show_crafting_category_menu(player)
            choice = input("> ").strip()
            if choice == "0":
                return
            try:
                category = categories[int(choice) - 1]
            except (ValueError, IndexError):
                print("\nNieprawidłowa kategoria."); pause(); continue
            recipes = recipes_for_category(all_recipes, category)
            while True:
                clear_screen()
                print(f"Kategoria: {category}\n")
                show_crafting_menu(player, recipes)
                selected = input("> ").strip()
                if selected == "0":
                    break
                try:
                    index = int(selected) - 1
                    if not 0 <= index < len(recipes):
                        raise IndexError
                    recipe = recipes[index]
                    craft_for_player(player, recipe, self.rng)
                    output = get_item_definition(recipe.output_item_id)
                    suffix = " +0" if output.is_equipment else ""
                    self._log(f"Stworzono: {output.name}{suffix}.")
                    print(f"\nStworzono: {output.name}{suffix}")
                except (ValueError, IndexError) as error:
                    print(f"\nNie udało się stworzyć przedmiotu: {error or 'Nieprawidłowy numer.'}")
                pause()

    def run_world_map(self) -> None:
        player = self.state.player
        if player is None: return
        locations = create_world_locations()
        while self.state.active_game:
            clear_screen(); show_world_map(player, locations, self.state.world_clock)
            choice = input("> ").strip()
            if choice == "0": return
            try:
                location = locations[int(choice) - 1]
            except (ValueError, IndexError):
                print("\nNieprawidłowa lokacja."); pause(); continue
            self.state.current_location_id = location.location_id
            if self.run_location():
                return

    def run_attribute_menu(self) -> None:
        player = self.state.player
        if player is None:
            return

        while True:
            clear_screen()
            show_attribute_menu(player)
            choice = input("> ").strip()

            if choice == "0":
                return

            attribute = get_attribute_from_choice(choice, player)

            if attribute is None:
                print("\nNieprawidłowa opcja.")
                pause()
                continue

            if player.unspent_attribute_points <= 0:
                print("\nBrak wolnych punktów atrybutów.")
                pause()
                continue

            amount = ask_point_quantity(player.unspent_attribute_points)

            if amount is None:
                continue

            try:
                player.spend_attribute_points(attribute, amount)
                print(
                    f"\n{attribute.display_name}: +{amount} pkt -> "
                    f"{player.attributes.get(attribute)}."
                )
            except ValueError as error:
                print(f"\n{error}")

            pause()

    def run_equipment_menu(self) -> None:
        player = self.state.player
        if player is None: return
        while True:
            clear_screen(); show_equipment(player)
            choice = input("> ").strip()
            if choice == "1":
                self.equip_item_from_inventory()
            elif choice == "2":
                self.unequip_item()
            elif choice == "3":
                self.show_equipped_item_details()
            elif choice == "0":
                return
            else:
                print("\nNieprawidłowa opcja.")
                pause()

    def show_equipped_item_details(self) -> None:
        player = self.state.player
        if player is None:
            return

        while True:
            clear_screen()
            items = show_equipped_detail_selection(player)

            if not items:
                pause()
                return

            choice = input("> ").strip()
            if choice == "0":
                return

            if choice.lower() == "a":
                clear_screen()
                show_all_equipped_details(player)
                pause()
                continue

            try:
                item = items[int(choice) - 1]
            except (ValueError, IndexError):
                print("\nNieprawidłowy wybór.")
                pause()
                continue

            clear_screen()
            show_equipment_details(item)
            pause()

    def equip_item_from_inventory(self) -> None:
        player = self.state.player
        if player is None: return
        clear_screen(); show_equippable_inventory(player)
        if not player.inventory.equipment_items: pause(); return
        choice = input("> ").strip()
        if choice == "0": return
        try:
            item = player.inventory.equipment_items[int(choice) - 1]
            player.equip_from_inventory(int(choice) - 1)
            print(f"\nZałożono: {format_upgrade_name(item)}")
        except (ValueError, IndexError) as error:
            print(f"\nNieprawidłowy wybór: {error}")
        pause()

    def unequip_item(self) -> None:
        player = self.state.player
        if player is None: return
        clear_screen(); occupied_slots = show_unequip_slots(player)
        if not occupied_slots: print("Nie masz żadnego założonego wyposażenia."); pause(); return
        choice = input("> ").strip()
        if choice == "0": return
        try:
            item = player.unequip_to_inventory(occupied_slots[int(choice) - 1])
            if item is not None: print(f"\nZdjęto: {format_upgrade_name(item)}")
        except (ValueError, IndexError) as error:
            print(f"\nNieprawidłowy wybór: {error}")
        pause()

    def run_location(self) -> bool:
        player = self.state.player
        if player is None:
            return False
        location = create_location(self.state.current_location_id)
        while self.state.active_game:
            clear_screen(); show_location_menu(
                player,
                location,
                self.state.world_clock,
                self.state.region_boss_respawns,
                camp_rest_available=self.state.camp_rest_available,
            )
            choice = input("> ").strip()
            if choice == "1":
                self.run_expedition(location)
            elif choice == "2":
                self.rest_at_camp()
            elif choice == "3" and location.location_id == "silentwater_marshes":
                return self.run_sunken_order_crypt()
            elif choice == "3" and location.location_id == "ashen_borderlands":
                self.run_azhar_challenge(location)
            elif choice == "3" and location.location_id == "ice_coast":
                self.run_leviathan_challenge(location)
            elif choice == "4" and location.location_id == "ice_coast":
                return self.run_black_fleet_wreck()
            elif choice == "0":
                return False
            else:
                print("\nNieprawidłowa opcja.")
                pause()
        return False


    def _show_boss_respawn_if_blocked(
        self,
        boss_id: str,
        location,
    ) -> bool:
        remaining = respawn_remaining(
            self.state.region_boss_respawns,
            boss_id,
        )
        if remaining <= 0:
            return False

        clear_screen()
        show_region_boss_respawn(
            REGION_BOSS_NAMES[boss_id],
            location.name,
            remaining,
        )
        pause()
        return True

    def _record_region_boss_respawn_expedition(
        self,
        location_id: str,
    ) -> None:
        boss_id = boss_id_for_location(location_id)
        if boss_id is None:
            return

        before = respawn_remaining(
            self.state.region_boss_respawns,
            boss_id,
        )
        after = record_region_expedition(
            self.state.region_boss_respawns,
            location_id,
        )
        if before > 0 and after == 0:
            self._log(
                f"{REGION_BOSS_NAMES[boss_id]} odrodził się "
                "i ponownie można rzucić mu wyzwanie."
            )


    def run_azhar_challenge(self, location) -> None:
        player = self.state.player
        if player is None:
            return
        if self._show_boss_respawn_if_blocked("azhar", location):
            return

        clear_screen()
        show_region_boss_challenge(
            player,
            "Azhar, Władca Pustkowi",
            14,
        )
        if input("> ").strip() != "1":
            return

        self._ensure_repeatable_contracts()
        enemy = create_enemy("azhar")
        apply_weather_to_enemy(enemy, self.state.weather.current)
        self._log("Podjęto wyzwanie Azhara, Władcy Pustkowi.")
        result = self.play_combat(
            enemy,
            f"{location.name} — WYZWANIE AZHARA",
            engine_factory=AzharCombatEngine,
            contract_region_id=location.location_id,
        )
        self._advance_world_time(EXPEDITION_DURATION_HOURS)
        if result is CombatResult.VICTORY:
            remaining = start_boss_respawn(
                self.state.region_boss_respawns,
                "azhar",
            )
            self._log(
                "Azhar, Władca Pustkowi został pokonany. "
                f"Odrodzenie wymaga {remaining} wypraw "
                "w Popielnym Pograniczu."
            )
        if result is CombatResult.DEFEAT:
            player.stats.restore_full()

    def run_leviathan_challenge(self, location) -> None:
        player = self.state.player
        if player is None:
            return
        if self._show_boss_respawn_if_blocked("leviathan_north", location):
            return

        clear_screen()
        show_region_boss_challenge(
            player,
            "Lewiatan Północy",
            18,
        )
        if input("> ").strip() != "1":
            return

        self._ensure_repeatable_contracts()
        enemy = create_enemy("leviathan_north")
        apply_weather_to_enemy(enemy, self.state.weather.current)
        self._log("Podjęto wyzwanie Lewiatana Północy.")
        result = self.play_combat(
            enemy,
            f"{location.name} — WYZWANIE LEWIATANA",
            engine_factory=LeviathanNorthCombatEngine,
            contract_region_id=location.location_id,
        )
        self._advance_world_time(EXPEDITION_DURATION_HOURS)
        if result is CombatResult.VICTORY:
            remaining = start_boss_respawn(
                self.state.region_boss_respawns,
                "leviathan_north",
            )
            self._log(
                "Lewiatan Północy został pokonany. "
                f"Odrodzenie wymaga {remaining} wypraw "
                "na Lodowym Wybrzeżu."
            )
        if result is CombatResult.DEFEAT:
            player.stats.restore_full()

    def run_sunken_order_crypt(self) -> bool:
        player = self.state.player
        if player is None:
            return False

        self._ensure_repeatable_contracts()
        dungeon = create_dungeon("sunken_order_crypt")
        clear_screen()
        show_dungeon_entrance(player, dungeon)
        if input("> ").strip() != "1":
            return False

        if not can_enter_dungeon(player.inventory, dungeon):
            key_name = (
                get_item_definition(dungeon.entry_item_id).name
                if dungeon.entry_item_id is not None
                else "wymagana wejściówka"
            )
            print()
            print(
                f"Kamienne wrota pozostają zamknięte. "
                f"Potrzebujesz: {key_name}."
            )
            print(
                "Klucz możesz zdobyć z Matki Głuchej Wody, "
                "wycraftować albo otrzymać ze zlecenia Gildii."
            )
            pause()
            return False

        consume_dungeon_entry(player.inventory, dungeon)
        if dungeon.entry_item_id is not None:
            key_name = get_item_definition(
                dungeon.entry_item_id
            ).name
            self._log(
                f"Zużyto wejściówkę do Krypty: {key_name}."
            )

        # Snapshot robimy dopiero po zużyciu wejściówki. Dzięki temu
        # porażka w Krypcie nie może przypadkiem przywrócić klucza.
        snapshot = capture_dungeon_loot_snapshot(player.inventory)
        set_world_status(
            "KRYPTA — pogoda powierzchni nie wpływa na walkę"
        )
        self._log(f"Rozpoczęto dungeon: {dungeon.name}.")

        sequence = (
            ("Zatopiony Przedsionek", "Woda sięga kostek. Między sarkofagami porusza się cień.", dungeon.room_one_enemies),
            ("Korytarz Pieczęci", "Na ścianach wiszą zerwane herby. Ktoś wciąż ich pilnuje.", dungeon.room_two_enemies),
        )

        for title, description, enemy_pool in sequence:
            result = self._run_dungeon_random_encounter(
                title, description, enemy_pool
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True
            if not self._dungeon_continue(player):
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True

        clear_screen()
        path_choice = ask_crossroads()
        if path_choice == "0":
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        if path_choice == "1":
            result = self._run_dungeon_enemy(
                dungeon.iron_path_enemy,
                "Żelazne Wrota — ELITA",
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True
        elif path_choice == "2":
            self._advance_world_time(DUNGEON_ROOM_DURATION_HOURS)
            drops = roll_dungeon_chest(
                dungeon, player.inventory, self.rng
            )
            clear_screen()
            show_chest_result(drops)
            pause()
            if self.rng.random() < dungeon.flooded_ambush_chance:
                result = self._run_dungeon_enemy(
                    dungeon.flooded_ambush_enemy,
                    "Zalany Korytarz — ZASADZKA",
                )
                if result is CombatResult.DEFEAT:
                    self._finish_failed_dungeon(dungeon, snapshot)
                    return True
                if result is CombatResult.FLED:
                    self._finish_safe_dungeon_retreat(dungeon, snapshot)
                    return True
        else:
            print("\nNieprawidłowa droga. Wycofujesz się przed rozwidleniem.")
            pause()
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        if not self._dungeon_continue(player):
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        result = self._run_dungeon_random_encounter(
            "Galeria Utopionych",
            "Kamienne figury stoją po obu stronach przejścia. Jedna z nich właśnie poruszyła głową.",
            dungeon.room_three_enemies,
        )
        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True
        if result is CombatResult.FLED:
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        shrine_choice = ask_shrine(player)
        if shrine_choice == "1":
            healed_hp, restored_mana = use_dungeon_shrine(player)
            show_shrine_result(healed_hp, restored_mana)
            pause()

        if not self._dungeon_continue(player):
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        result = self._run_dungeon_enemy(
            dungeon.mandatory_elite_enemy,
            "Sala Łańcuchów — ELITA",
        )
        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True
        if result is CombatResult.FLED:
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        show_dungeon_room(
            "Brama Wielkiego Mistrza",
            "Za masywnymi drzwiami słychać metal przesuwany po kamieniu. To ostatni moment na odwrót.",
        )
        if ask_continue_or_retreat(player) != "1":
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        boss = create_enemy(dungeon.boss_enemy)
        result = self.play_combat(
            boss,
            f"{dungeon.name} — FINAŁ",
            use_weather=False,
            engine_factory=GrandMasterCombatEngine,
            in_dungeon=True,
        )
        self._advance_world_time(DUNGEON_ROOM_DURATION_HOURS)

        if result is CombatResult.VICTORY:
            loot = dungeon_loot_since_snapshot(
                player.inventory, snapshot
            )
            contract_updates = record_dungeon_completion(
                player,
                self.state.contract_board,
                dungeon.dungeon_id,
            )
            guild_update = record_guild_milestone(
                self.state.guild_progress,
                f"dungeon:{dungeon.dungeon_id}",
            )
            self._log(
                f"Ukończono dungeon: {dungeon.name}."
            )
            clear_screen()
            show_dungeon_exit(dungeon, loot, completed=True)
            self._show_contract_updates(contract_updates)
            self._show_guild_update(guild_update)
            self._save_silently()
            pause()
            return True

        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True

        self._finish_safe_dungeon_retreat(dungeon, snapshot)
        return True

    def run_black_fleet_wreck(self) -> bool:
        player = self.state.player
        if player is None:
            return False

        self._ensure_repeatable_contracts()
        dungeon = create_dungeon("black_fleet_wreck")
        clear_screen()
        show_dungeon_entrance(player, dungeon)
        if input("> ").strip() != "1":
            return False

        if not can_enter_dungeon(player.inventory, dungeon):
            key_name = (
                get_item_definition(dungeon.entry_item_id).name
                if dungeon.entry_item_id is not None
                else "wymagana wejściówka"
            )
            print()
            print(
                f"Droga między skutymi lodem wrakami jest zamknięta. "
                f"Potrzebujesz: {key_name}."
            )
            print(
                "Medalion możesz zdobyć z Widma Kapitana Statku "
                "albo wycraftować z materiałów Lodowego Wybrzeża."
            )
            pause()
            return False

        consume_dungeon_entry(player.inventory, dungeon)
        if dungeon.entry_item_id is not None:
            key_name = get_item_definition(dungeon.entry_item_id).name
            self._log(
                f"Zużyto wejściówkę do Wraku Czarnej Floty: {key_name}."
            )

        snapshot = capture_dungeon_loot_snapshot(player.inventory)
        set_world_status(
            "WRAK CZARNEJ FLOTY — pogoda powierzchni nie wpływa na walkę"
        )
        self._log(f"Rozpoczęto dungeon: {dungeon.name}.")

        clear_screen()
        show_dungeon_scene(
            "Cmentarzysko Okrętów",
            BLACK_FLEET_NARRATIVE["entrance"],
        )
        pause()

        sequence = (
            (
                "Zamarznięty Pokład",
                BLACK_FLEET_NARRATIVE["frozen_deck"],
                dungeon.room_one_enemies,
            ),
            (
                "Przejście między Wrakami",
                BLACK_FLEET_NARRATIVE["wreck_passage"],
                dungeon.room_two_enemies,
            ),
        )

        for title, description, enemy_pool in sequence:
            result = self._run_dungeon_random_encounter(
                title, description, enemy_pool
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True
            if not self._dungeon_continue(player):
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True

        clear_screen()
        path_choice = ask_black_fleet_crossroads()
        if path_choice == "0":
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        if path_choice == "1":
            # Ładownia jest dłuższa: najpierw losowa walka, potem Bosman,
            # ale nagrodą jest dostęp do Skarbca Czarnej Floty.
            result = self._run_dungeon_random_encounter(
                "Zalana Ładownia",
                BLACK_FLEET_NARRATIVE["cargo_hold"],
                ("cursed_sailor", "black_fleet_drowned", "cursed_gunner"),
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True

            result = self._run_dungeon_enemy(
                dungeon.iron_path_enemy,
                "Ładownia — BOSMAN CZARNEJ FLOTY",
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True

            self._advance_world_time(DUNGEON_ROOM_DURATION_HOURS)
            drops = roll_dungeon_chest(
                dungeon, player.inventory, self.rng
            )
            clear_screen()
            show_black_fleet_treasury(drops)
            pause()

        elif path_choice == "2":
            # Górny Pokład skraca drogę, ale wymusza starcie z Kanonierem.
            clear_screen()
            show_dungeon_scene(
                "Górny Pokład",
                BLACK_FLEET_NARRATIVE["upper_deck"],
            )
            pause()
            result = self._run_dungeon_enemy(
                dungeon.flooded_ambush_enemy,
                "Górny Pokład — OSTRZAŁ",
            )
            if result is CombatResult.DEFEAT:
                self._finish_failed_dungeon(dungeon, snapshot)
                return True
            if result is CombatResult.FLED:
                self._finish_safe_dungeon_retreat(dungeon, snapshot)
                return True

        if not self._dungeon_continue(player):
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        result = self._run_dungeon_random_encounter(
            "Kajuty Oficerskie",
            BLACK_FLEET_NARRATIVE["officer_quarters"],
            dungeon.room_three_enemies,
        )
        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True
        if result is CombatResult.FLED:
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        medical_choice = ask_medical_cabin(player)
        if medical_choice == "1":
            healed_hp, restored_mana = use_medical_cabin(player)
            show_medical_cabin_result(healed_hp, restored_mana)
            pause()

        if not self._dungeon_continue(player):
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        show_dungeon_scene(
            "Droga na Okręt Flagowy",
            BLACK_FLEET_NARRATIVE["first_officer_intro"],
        )
        pause()
        result = self._run_dungeon_enemy(
            dungeon.mandatory_elite_enemy,
            "Okręt Flagowy — PIERWSZY OFICER",
        )
        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True
        if result is CombatResult.FLED:
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        show_dungeon_scene(
            "Okręt Flagowy",
            BLACK_FLEET_NARRATIVE["flagship_approach"],
        )
        if ask_continue_or_retreat(player) != "1":
            self._finish_safe_dungeon_retreat(dungeon, snapshot)
            return True

        clear_screen()
        show_dungeon_scene(
            "Pokład Admiralski",
            BLACK_FLEET_NARRATIVE["varek_intro"],
        )
        pause()

        boss = create_enemy(dungeon.boss_enemy)
        result = self.play_combat(
            boss,
            f"{dungeon.name} — FINAŁ",
            use_weather=False,
            engine_factory=AdmiralVarekCombatEngine,
            in_dungeon=True,
        )
        self._advance_world_time(DUNGEON_ROOM_DURATION_HOURS)

        if result is CombatResult.VICTORY:
            loot = dungeon_loot_since_snapshot(
                player.inventory, snapshot
            )
            contract_updates = record_dungeon_completion(
                player,
                self.state.contract_board,
                dungeon.dungeon_id,
            )
            guild_update = record_guild_milestone(
                self.state.guild_progress,
                f"dungeon:{dungeon.dungeon_id}",
            )
            self._log(f"Ukończono dungeon: {dungeon.name}.")
            clear_screen()
            show_dungeon_exit(dungeon, loot, completed=True)
            self._show_contract_updates(contract_updates)
            self._show_guild_update(guild_update)
            self._save_silently()
            pause()
            return True

        if result is CombatResult.DEFEAT:
            self._finish_failed_dungeon(dungeon, snapshot)
            return True

        self._finish_safe_dungeon_retreat(dungeon, snapshot)
        return True

    def _run_dungeon_random_encounter(
        self,
        title: str,
        description: str,
        enemy_pool: tuple[str, ...],
    ) -> CombatResult:
        clear_screen()
        show_dungeon_room(title, description)
        pause()
        enemy_id = self.rng.choice(enemy_pool)
        return self._run_dungeon_enemy(enemy_id, title)

    def _run_dungeon_enemy(
        self,
        enemy_id: str,
        battle_title: str,
    ) -> CombatResult:
        enemy = create_enemy(enemy_id)
        result = self.play_combat(
            enemy,
            battle_title,
            use_weather=False,
            in_dungeon=True,
        )
        self._advance_world_time(DUNGEON_ROOM_DURATION_HOURS)
        return result

    def _dungeon_continue(self, player) -> bool:
        clear_screen()
        show_dungeon_room(
            "Chwila ciszy",
            "Droga dalej jest otwarta. Możesz naciskać naprzód albo zabezpieczyć to, co już zdobyłeś.",
        )
        return ask_continue_or_retreat(player) == "1"

    def _finish_safe_dungeon_retreat(self, dungeon, snapshot) -> None:
        player = self.state.player
        if player is None:
            return
        loot = dungeon_loot_since_snapshot(player.inventory, snapshot)
        self._log(f"Wycofano się z dungeon: {dungeon.name}.")
        clear_screen()
        show_dungeon_exit(dungeon, loot, completed=False)
        pause()

    def _finish_failed_dungeon(self, dungeon, snapshot) -> None:
        player = self.state.player
        if player is None:
            return
        lost = discard_unsecured_dungeon_loot(
            player.inventory, snapshot
        )
        player.stats.restore_full()
        self._log(
            f"Porażka w dungeon: {dungeon.name} — "
            "utracono niezabezpieczony łup z wyprawy."
        )
        clear_screen()
        show_dungeon_defeat(lost)
        pause()

    def run_expedition(self, location) -> None:
        player=self.state.player
        if player is None: return
        load = carry_status(player)
        if load.overloaded:
            clear_screen()
            print("PRZECIĄŻENIE")
            print("-" * 58)
            print(f"Udźwig: {load.current_kg:.1f}/{load.capacity_kg:.1f} kg")
            print()
            print("Nie możesz rozpocząć kolejnej zwykłej wyprawy z przeciążonym plecakiem.")
            print("Zdobyty łup nie przepada — sprzedaj część rzeczy albo odłóż je u Kwatermistrza w Gildii.")
            pause()
            return
        self._ensure_repeatable_contracts()
        period=self.state.world_clock.period
        result=explore_location(location,period,self.rng)
        if not result.has_encounter:
            self.state.camp_rest_available = True
            self._advance_world_time(EXPEDITION_DURATION_HOURS)
            self._record_region_boss_respawn_expedition(
                location.location_id
            )
            clear_screen(); show_quiet_exploration(result.message)
            print(f"\nCzas: {self.state.world_clock.formatted_time()} | {self.state.world_clock.period.display_name}")
            pause(); return

        enemy=create_enemy(result.enemy_id)
        apply_weather_to_enemy(enemy,self.state.weather.current)

        # Każdy region otwartego świata ma własny licznik spotkań
        # bez elity. Krypta nie przechodzi przez run_expedition,
        # więc nie korzysta z tego systemu.
        roll_elite_for_region(
            enemy,
            period,
            self.state.weather.current,
            location.location_id,
            self.state.elite_miss_streaks,
            self.rng,
        )

        battle_title=f"{location.name} — {period.display_name}"
        combat_result=self.play_combat(
            enemy,
            battle_title,
            contract_region_id=location.location_id,
        )
        self._advance_world_time(EXPEDITION_DURATION_HOURS)
        self._record_region_boss_respawn_expedition(
            location.location_id
        )
        if combat_result is CombatResult.DEFEAT:
            player.stats.restore_full()

    def use_combat_consumable(self, combat: CombatEngine):
        player = self.state.player
        if player is None: return None
        clear_screen(); consumables = show_consumables(player)
        if not consumables: pause(); return None
        choice = input("> ").strip()
        if choice == "0": return None
        try:
            item_id = consumables[int(choice) - 1]
            definition = get_item_definition(item_id)
            result = use_consumable(player, item_id)
            return combat.player_item_turn(
                result.healed_hp,
                definition.name,
                result.restored_mana,
            )
        except (ValueError, IndexError) as error:
            print(f"\n{error}"); pause(); return None

    def use_combat_skill(self, combat: CombatEngine):
        player = self.state.player
        if player is None:
            return None
        clear_screen()
        skills = show_combat_skill_menu(player)
        if not skills:
            pause(); return None
        choice = input("> ").strip()
        if choice == "0":
            return None
        try:
            selected_index = int(choice) - 1
            if not 0 <= selected_index < len(skills):
                raise IndexError
            first = skills[selected_index]
            if combat.can_double_cast() and player.character_class.code == "mage" and first.is_offensive:
                print("\n[PODWÓJNY SPLOT GOTOWY]")
                print("[1] Rzuć tylko wybrane zaklęcie")
                print("[2] Dobierz drugie zaklęcie i rzuć oba w tej turze")
                weave_choice = input("> ").strip()
                if weave_choice == "2":
                    clear_screen()
                    second_all = show_combat_skill_menu(player)
                    second_skills = [skill for skill in second_all if skill.is_offensive]
                    second_choice = input("Drugie zaklęcie > ").strip()
                    if second_choice == "0":
                        return None
                    second = second_skills[int(second_choice) - 1]
                    return combat.player_use_skill_pair(first.skill_id, second.skill_id)
            return combat.player_use_skill(first.skill_id)
        except IndexError:
            print("\nNieprawidłowy numer umiejętności."); pause(); return None
        except ValueError as error:
            print(f"\n{error}"); pause(); return None

    def play_combat(
        self,
        enemy: Enemy,
        battle_title: str,
        *,
        use_weather: bool = True,
        engine_factory=None,
        contract_region_id: str | None = None,
        in_dungeon: bool = False,
    ) -> CombatResult:
        player=self.state.player
        if player is None: raise RuntimeError("Nie można rozpocząć walki bez bohatera.")
        if engine_factory is None and enemy.enemy_id == "hearth_devourer":
            engine_factory = HearthDevourerCombatEngine

        combat=(
            engine_factory(player,enemy,self.rng)
            if engine_factory is not None
            else CombatEngine(player,enemy,self.rng)
        )
        while combat.result is CombatResult.ONGOING:
            clear_screen(); show_combat_screen(
                player, enemy, battle_title, combat.effects, combat.status_lines()
            )
            action=ask_combat_action()
            if action=="1":
                report=combat.player_attack()
            elif action=="2":
                report=self.use_combat_skill(combat)
                if report is None:
                    continue
            elif action=="3":
                report=combat.player_defend()
            elif action=="4":
                report=self.use_combat_consumable(combat)
                if report is None:
                    continue
            else:
                report=combat.player_flee()
            clear_screen(); show_combat_screen(
                player, enemy, battle_title, combat.effects
            ); show_turn_report(player,enemy,report)
            if combat.result is CombatResult.ONGOING: pause()

        experience_gained=gold_gained=levels_gained=attribute_points_gained=0
        drops=[]; note=None; quest_updates=[]; contract_updates=[]; unlocked=[]
        elite_discovery_note=None
        guild_update=None
        weather=self.state.weather.current
        if combat.result is CombatResult.VICTORY:
            multiplier=(reward_multiplier(weather) if use_weather else 1.0)
            drop_multiplier=(drop_chance_multiplier(weather) if use_weather else 1.0)
            drop_multiplier*=enemy.loot_chance_multiplier
            if player.character_class.code == "pierrot":
                # Szczęście pomaga w polowaniu tylko odrobinę; jego główną rolą pozostaje walka.
                drop_multiplier *= 1.0 + min(0.05, player.attributes.luck * 0.001)
            experience_gained=max(1,int(round(enemy.experience_reward*multiplier)))
            gold_gained=max(0,int(round(enemy.roll_gold_reward(self.rng)*multiplier)))
            drops=roll_loot(
                enemy.enemy_id,
                self.rng,
                drop_multiplier,
                elite=enemy.elite_modifier_id is not None,
            )
            mastery_book_id = roll_mastery_book_drop(
                enemy.enemy_id, self.rng
            )
            if mastery_book_id is not None:
                drops.append(LootDrop(mastery_book_id, 1))
            path_book_id = roll_path_book_drop(enemy.enemy_id, self.rng)
            if path_book_id is not None:
                drops.append(LootDrop(path_book_id, 1))
            class_weapon_id = roll_class_weapon_drop(
                enemy.enemy_id,
                enemy.rank,
                elite=enemy.elite_modifier_id is not None,
                rng=self.rng,
            )
            if class_weapon_id is not None:
                drops.append(LootDrop(class_weapon_id, 1))
            class_gear_id = roll_class_gear_drop(
                enemy.enemy_id,
                enemy.rank,
                elite=enemy.elite_modifier_id is not None,
                rng=self.rng,
            )
            if class_gear_id is not None:
                drops.append(LootDrop(class_gear_id, 1))
            if use_weather:
                drops.extend(roll_weather_boss_weapon(enemy,weather,self.rng))
            levels_gained=player.gain_experience(experience_gained)
            attribute_points_gained=levels_gained*ATTRIBUTE_POINTS_PER_LEVEL
            player.add_gold(gold_gained)
            equipment_quality = equipment_quality_for_enemy(
                rank=enemy.rank,
                elite_modifier_id=enemy.elite_modifier_id,
                in_dungeon=in_dungeon,
            )
            add_loot_to_inventory(
                player.inventory,
                drops,
                rng=self.rng,
                equipment_quality=equipment_quality,
            )
            quest_updates=record_enemy_kill(
                self.state.quest_log,
                enemy.enemy_id,
            )
            contract_updates=record_contract_victory(
                player,
                self.state.contract_board,
                enemy_id=enemy.enemy_id,
                region_id=contract_region_id or "",
                is_miniboss=enemy.is_miniboss,
                elite_modifier_id=enemy.elite_modifier_id,
            )
            if enemy.enemy_id in {"azhar", "leviathan_north"}:
                guild_update = record_guild_milestone(
                    self.state.guild_progress,
                    f"boss:{enemy.enemy_id}",
                )

            elite_discovery_note=None
            if (
                enemy.elite_modifier_id is not None
                and enemy.elite_modifier_id
                not in self.state.elite_discoveries
            ):
                self.state.elite_discoveries.add(
                    enemy.elite_modifier_id
                )
                elite_discovery_note=(
                    f"Po raz pierwszy pokonano typ elity: "
                    f"{enemy.name}."
                )
                self._log(elite_discovery_note)

            unlocked=achievements_after_victory(
                player,
                enemy.enemy_id,
                weather,
            )
            self._log(
                f"Pokonano {enemy.name}: +{experience_gained} EXP, "
                f"+{gold_gained} Gold."
            )
            if use_weather and weather.code=="aurora":
                note="Zorza Polarna: przeciwnicy są silniejsi, ale EXP, Gold i szanse dropu są zwiększone o 50%."
        elif combat.result is CombatResult.DEFEAT:
            note="Porażka nie odbiera jeszcze Golda ani EXP. Bohater zostanie uratowany."
            self._log(f"Porażka w walce z: {enemy.name}.")

        self.state.camp_rest_available = True
        show_combat_result(combat.result,enemy,experience_gained,gold_gained,levels_gained,attribute_points_gained,drops,note)
        self._show_unlocked_achievements(unlocked)
        if quest_updates:
            print("\nPOSTĘP ZADAŃ FABULARNYCH:")
            for update in quest_updates:
                ready=" — GOTOWE DO ODDANIA" if update.ready else ""
                print(
                    f"- {update.title}: "
                    f"{update.current}/{update.required}{ready}"
                )

        self._show_contract_updates(contract_updates)
        self._show_guild_update(guild_update)

        if elite_discovery_note:
            print("\nDZIENNIK PRZYGÓD:")
            print(f"- {elite_discovery_note}")

        pause(); return combat.result

    def rest_at_camp(self) -> None:
        player = self.state.player
        if player is None:
            return

        clear_screen()
        if not self.state.camp_rest_available:
            show_rest_result(
                message=(
                    "Ognisko nie daje już dziś wytchnienia. "
                    "Kolejny darmowy odpoczynek odblokuje następna wyprawa lub walka."
                )
            )
            pause()
            return

        try:
            result = apply_camp_rest(player)
        except ValueError as error:
            show_rest_result(message=str(error))
            pause()
            return

        self.state.camp_rest_available = False
        self._advance_world_time(REST_DURATION_HOURS)
        self._log(
            f"Odpoczęto przy ognisku: +{result.healed_hp} HP, "
            f"+{result.restored_mana} Many."
        )
        show_rest_result(
            healed_hp=result.healed_hp,
            restored_mana=result.restored_mana,
        )
        self._save_silently()
        pause()

    def show_project_status(self) -> None:
        clear_screen()
        print("AKTUALNY STAN PROJEKTU")
        print("-" * 40)
        print(f"Wersja: {GAME_VERSION}")
        print("Status: Akt I — Ślady Przebudzenia + Classes 2.0")
        print()
        print("Najważniejsze systemy:")
        print("- 5 regionów otwartego świata")
        print("- pogoda i Zorza Polarna")
        print("- crafting z kategoriami, handel i kowal")
        print("- Gildia 2.0: reputacja, rangi F-S, fabuła Aktu I i progresywne plotki")
        print("- Prolog: Droga do Varenhold oraz pierwsza walka fabularna")
        print("- 4 niezależne sloty zapisu z autosave przypisanym do aktywnego slotu")
        print("- klasy: Wojownik / Łowca / Mag / Pierrot")
        print("- Classes 2.0: punkty drzewka, specjalizacje i reset buildów")
        print("- Ciężki Rycerz jako specjalizacja Wojownika")
        print("- Łowca: sekwencje technik i Księga Kombinacji")
        print("- Mag: Splot Magii i dwa zaklęcia w jednej turze")
        print("- Pierrot: Szczęście, Fate Engine, Kości Losu, Chaos / Fortuna")
        print("- aktywne umiejętności + pasywki i Mistrzostwo 6-10")
        print("- specjalizacje pasywek po 10/10")
        print("- Krypta Zatopionego Zakonu + Wrak Czarnej Floty")
        print("- losowe elitarne warianty przeciwników")
        print("- kontrakty dzienne i tygodniowe")
        print("- losowy informator i permanentny Czarny Rynek")
        print("- Księgi Mistrzostwa i Księgi Ścieżki + targowanie cen")
        print("- Przygotowanie do wyprawy: cel / Party / zapasy / udźwig / presety")
        print("- taktyki AI kompanów: Agresywna / Zrównoważona / Ostrożna / Obronna")
        print("- OFF-HAND: Tarcze / Kołczany / Artefakty / Kości i Talie Kart")
        print("- drop-only Łuki / Kostury / Lance Losu")
        print("- Equipment 2.0: role slotów / Item Power / T1-T5")
        print("- wymagane poziomy wyposażenia")
        print("- Średnie Obrażenia na broniach dungeonowych")
        print("- Popielne Pogranicze: poziom 10-14 / Item Power V")
        print("- Pożeracz Palenisk i Azhar, Władca Pustkowi")
        print("- Lodowe Wybrzeże: poziom 14-18 / Item Power VI")
        print("- Widmo Kapitana Statku i Lewiatan Północy")
        print("- drop-only przedmioty klasowe dla Wojownika / Łowcy / Maga")
        print("- Iskra Życia i Zwykła Esencja w późniejszym craftingu")
        print("- affixy bojowe: Crit / Skill Damage / penetracja")
        print("- dungeony z rozwidleniami, odpoczynkiem i bossami wielofazowymi")
        pause()

    def exit_game(self) -> None:
        self.state.running = False
        clear_screen()
        print("Do zobaczenia w mroku, Wędrowcze.")
