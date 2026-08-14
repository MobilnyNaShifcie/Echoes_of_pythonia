from __future__ import annotations

import json
import os
from dataclasses import dataclass
from pathlib import Path
from typing import Any

from data.elites import ELITE_MODIFIERS
from companions.models import COMPANION_TACTICS, Companion, CompanionCandidate, FallenCompanion, PartyMessage, PartyState
from data.companions import COMPANION_TEMPLATES
from rifts.models import RiftExpedition, RiftInstance, RiftState
from data.rifts import RIFT_MODIFIERS, RIFT_RANKS, RIFT_THEMES
from game.adventure_log import AdventureLog
from game.config import (
    APP_DATA_FOLDER,
    DEFAULT_SAVE_SLOT,
    BASIC_PASSIVE_LEVEL,
    GAME_VERSION,
    MAX_PASSIVE_LEVEL,
    MAX_UPGRADE_LEVEL,
    OLDER_SAVE_SCHEMA_VERSIONS,
    PREVIOUS_SAVE_SCHEMA_VERSION,
    SAVE_SCHEMA_VERSION,
    SAVE_SLOT_COUNT,
    STARTING_CITY_ID,
)
from game.state import GameState
from items.affixes import (
    affix_count_for_rarity,
    backfill_legacy_equipment_item,
    ensure_equipment_generation,
    validate_affix_roll,
)
from items.catalog import get_item_definition
from items.models import AffixRoll, EquipmentItem, EquipmentSlot
from items.signature_weapons import (
    deterministic_average_damage_percent,
    validate_average_damage_percent,
)
from player.achievements import AchievementBook, DEFAULT_TITLE, achievement_exists
from player.attributes import Attributes
from player.classes import PlayerClass, player_class_from_code
from player.equipment import Equipment
from player.inventory import Inventory
from player.passives import Passives, PassiveType
from data.talents import CLASS_PATHS, TALENT_DATA
from data.passive_specializations import PASSIVE_SPECIALIZATIONS, SPECIALIZATIONS_BY_PASSIVE
from combat.hunter_combo import HUNTER_COMBOS
from player.player import Player
from quests.catalog import quest_exists
from quests.contracts import (
    ContractBoard,
    contract_from_dict,
    contract_to_dict,
)
from quests.models import QuestLog
from systems.black_market import BlackMarketOffer, BlackMarketState
from systems.guild_progression import GuildProgress
from systems.guild_storage import GuildStorage
from systems.expedition_preparation import (
    PRESET_NAMES,
    PRESET_ORDER,
    ExpeditionPreparationState,
    ExpeditionPreset,
)
from systems.region_boss_respawn import REGION_BOSS_NAMES
from world.city_factory import create_city
from world.factory import create_location
from world.time_system import GameClock
from world.weather import WeatherState, WeatherType, weather_from_code


class SaveGameError(Exception):
    pass


@dataclass(frozen=True)
class SaveSummary:
    player_name: str
    level: int
    day: int
    hour: int
    location_name: str
    city_name: str
    game_version: str


def get_user_data_directory() -> Path:
    if os.name == "nt":
        base = os.environ.get("LOCALAPPDATA")
        if base:
            return Path(base) / APP_DATA_FOLDER
        return Path.home() / "AppData" / "Local" / APP_DATA_FOLDER
    xdg = os.environ.get("XDG_DATA_HOME")
    if xdg:
        return Path(xdg) / APP_DATA_FOLDER
    return Path.home() / ".local" / "share" / APP_DATA_FOLDER


def get_save_directory() -> Path:
    return get_user_data_directory() / "saves"


def get_save_path(slot_name: str = DEFAULT_SAVE_SLOT) -> Path:
    return get_save_directory() / slot_name


def get_project_root() -> Path:
    return Path(__file__).resolve().parent.parent


def get_legacy_save_path() -> Path:
    return get_project_root() / "saves" / DEFAULT_SAVE_SLOT


def save_exists(slot_name: str = DEFAULT_SAVE_SLOT) -> bool:
    return get_save_path(slot_name).is_file()




def save_slot_name(slot_number: int) -> str:
    if not 1 <= int(slot_number) <= SAVE_SLOT_COUNT:
        raise ValueError(f"Numer slotu musi być z zakresu 1-{SAVE_SLOT_COUNT}.")
    return f"save_{int(slot_number)}.json"


def save_slot_number(slot_name: str) -> int | None:
    for number in range(1, SAVE_SLOT_COUNT + 1):
        if slot_name == save_slot_name(number):
            return number
    return None


def any_save_exists() -> bool:
    return any(save_exists(save_slot_name(number)) for number in range(1, SAVE_SLOT_COUNT + 1))


def get_save_summaries() -> dict[int, SaveSummary | None]:
    summaries: dict[int, SaveSummary | None] = {}
    for number in range(1, SAVE_SLOT_COUNT + 1):
        summaries[number] = get_save_summary(save_slot_name(number))
    return summaries

def _equipment_item_to_dict(item: EquipmentItem) -> dict[str, Any]:
    ensure_equipment_generation(item)
    return {
        "item_id": item.item_id,
        "upgrade_level": item.upgrade_level,
        "instance_id": item.instance_id,
        "item_power": item.item_power,
        "affixes": [
            {
                "affix_id": affix.affix_id,
                "tier": affix.tier,
                "value": affix.value,
            }
            for affix in item.affixes
        ],
        "average_damage_percent": item.average_damage_percent,
    }


def _equipment_item_from_dict(data: dict[str, Any]) -> EquipmentItem:
    item_id = str(data["item_id"])
    definition = get_item_definition(item_id)
    if not definition.is_equipment:
        raise SaveGameError(f"Przedmiot {item_id} nie jest wyposażeniem.")

    upgrade_level = int(data["upgrade_level"])
    if not 0 <= upgrade_level <= MAX_UPGRADE_LEVEL:
        raise SaveGameError(
            f"Nieprawidłowy poziom ulepszenia dla {item_id}: {upgrade_level}."
        )

    instance_id = str(data["instance_id"]).strip()
    if not instance_id:
        raise SaveGameError("Przedmiot w zapisie nie ma instance_id.")

    # Save sprzed v0.17 nie ma Item Power ani affixów. Losujemy je
    # deterministycznie na podstawie instance_id, więc migracja jest stabilna.
    if "item_power" not in data or "affixes" not in data:
        return backfill_legacy_equipment_item(
            item_id,
            upgrade_level,
            instance_id,
        )

    item_power = int(data["item_power"])
    if item_power != definition.item_power:
        raise SaveGameError(
            f"Nieprawidłowy Item Power dla {item_id}: {item_power}."
        )

    affixes: list[AffixRoll] = []
    for raw in list(data.get("affixes", [])):
        affix_data = dict(raw)
        affix = AffixRoll(
            affix_id=str(affix_data["affix_id"]),
            tier=int(affix_data["tier"]),
            value=float(affix_data["value"]),
        )
        try:
            validate_affix_roll(definition, affix)
        except (KeyError, ValueError) as error:
            raise SaveGameError(str(error)) from error
        affixes.append(affix)

    if len({affix.affix_id for affix in affixes}) != len(affixes):
        raise SaveGameError("Przedmiot ma zduplikowany bonus.")

    expected_count = affix_count_for_rarity(definition.rarity)
    if len(affixes) != expected_count:
        raise SaveGameError(
            f"Nieprawidłowa liczba bonusów dla {item_id}: "
            f"{len(affixes)}, oczekiwano {expected_count}."
        )

    if "average_damage_percent" in data:
        raw_average_damage = data.get("average_damage_percent")
        average_damage_percent = (
            None
            if raw_average_damage is None
            else int(raw_average_damage)
        )
    else:
        # v0.17 / schema v8 nie zapisywała Średnich Obrażeń. Dla już
        # istniejącej broni dungeonowej dokładamy stabilny roll bez
        # zmiany jej affixów T1-T5.
        average_damage_percent = deterministic_average_damage_percent(
            item_id,
            instance_id,
        )

    try:
        validate_average_damage_percent(
            item_id,
            average_damage_percent,
        )
    except ValueError as error:
        raise SaveGameError(str(error)) from error

    return EquipmentItem(
        item_id=item_id,
        upgrade_level=upgrade_level,
        instance_id=instance_id,
        item_power=item_power,
        affixes=affixes,
        average_damage_percent=average_damage_percent,
    )


def _player_to_dict(player: Player) -> dict[str, Any]:
    return {
        "name":player.name,"level":player.level,"experience":player.experience,
        "gold":player.gold,"rubies":player.rubies,
        "unspent_attribute_points":player.unspent_attribute_points,
        "carry_upgrade_level":player.carry_upgrade_level,
        "character_class":player.character_class.code,
        "current_hp":player.stats.current_hp,"current_mana":player.stats.current_mana,
        "attributes":{
            "strength":player.attributes.strength,"vitality":player.attributes.vitality,
            "intelligence":player.attributes.intelligence,"dexterity":player.attributes.dexterity,
            "endurance":player.attributes.endurance,
            "luck":player.attributes.luck,
        },
        "passive_masteries":sorted(player.passive_masteries),
        "passive_specializations":dict(player.passive_specializations),
        "talents":dict(player.talents),
        "unlocked_class_paths":sorted(player.unlocked_class_paths),
        "discovered_hunter_combos":sorted(player.discovered_hunter_combos),
        "passives":{
            "attack_speed":player.passives.attack_speed,
            "critical_damage":player.passives.critical_damage,
            "health_regen":player.passives.health_regen,
            "increased_attack":player.passives.increased_attack,
        },
        "achievements":{
            "unlocked":sorted(player.achievements.unlocked),
            "equipped_title":player.achievements.equipped_title,
        },
        "inventory":{
            "stacks":dict(player.inventory.stacks),
            "equipment_items":[_equipment_item_to_dict(item) for item in player.inventory.equipment_items],
        },
        "equipment":{slot.code:_equipment_item_to_dict(item) for slot,item in player.equipment.slots.items()},
    }


def _player_from_dict(data: dict[str, Any]) -> Player:
    name=str(data["name"]).strip()
    if not 2 <= len(name) <= 20: raise SaveGameError("Nieprawidłowe imię bohatera w zapisie.")
    attrs=data["attributes"]
    attributes=Attributes(
        strength=int(attrs["strength"]),vitality=int(attrs["vitality"]),
        intelligence=int(attrs["intelligence"]),dexterity=int(attrs["dexterity"]),endurance=int(attrs["endurance"]),
        luck=int(attrs.get("luck", 0)),
    )
    if any(value<0 for value in attributes.as_dict().values()): raise SaveGameError("Atrybuty w zapisie nie mogą być ujemne.")

    passive_data=dict(data.get("passives",{}))
    passives=Passives(
        attack_speed=int(passive_data.get("attack_speed",0)),
        critical_damage=int(passive_data.get("critical_damage",0)),
        health_regen=int(passive_data.get("health_regen",0)),
        increased_attack=int(passive_data.get("increased_attack",0)),
    )
    passive_masteries={str(code) for code in list(data.get("passive_masteries",[]))}
    valid_passive_codes={passive.code for passive in PassiveType}
    if not passive_masteries.issubset(valid_passive_codes):
        raise SaveGameError("Nieznane Mistrzostwo pasywne w zapisie.")
    for passive in PassiveType:
        value=passives.get(passive)
        cap=MAX_PASSIVE_LEVEL if passive.code in passive_masteries else BASIC_PASSIVE_LEVEL
        if value<0 or value>cap:
            raise SaveGameError("Nieprawidłowy poziom pasywki w zapisie.")

    passive_specializations = {str(k): str(v) for k, v in dict(data.get("passive_specializations", {})).items()}
    for passive_code, spec_id in passive_specializations.items():
        if passive_code not in SPECIALIZATIONS_BY_PASSIVE or spec_id not in PASSIVE_SPECIALIZATIONS:
            raise SaveGameError("Nieznana specjalizacja pasywna w zapisie.")
        if spec_id not in SPECIALIZATIONS_BY_PASSIVE[passive_code]:
            raise SaveGameError("Specjalizacja nie pasuje do pasywki w zapisie.")

    talents = {str(k): int(v) for k, v in dict(data.get("talents", {})).items()}
    for talent_id, rank in talents.items():
        if talent_id not in TALENT_DATA or rank < 1 or rank > TALENT_DATA[talent_id].max_rank:
            raise SaveGameError("Nieprawidłowy talent w zapisie.")
    unlocked_class_paths = {str(v) for v in list(data.get("unlocked_class_paths", []))}
    if not unlocked_class_paths.issubset(CLASS_PATHS):
        raise SaveGameError("Nieznana Ścieżka klasy w zapisie.")
    discovered_hunter_combos = {str(v) for v in list(data.get("discovered_hunter_combos", []))}
    if not discovered_hunter_combos.issubset(HUNTER_COMBOS):
        raise SaveGameError("Nieznana kombinacja Łowcy w zapisie.")

    achievement_data=dict(data.get("achievements",{}))
    unlocked=set()
    for achievement_id in list(achievement_data.get("unlocked",[])):
        achievement_id=str(achievement_id)
        if not achievement_exists(achievement_id): raise SaveGameError(f"Nieznane osiągnięcie: {achievement_id}.")
        unlocked.add(achievement_id)
    achievements=AchievementBook(unlocked=unlocked,equipped_title=str(achievement_data.get("equipped_title",DEFAULT_TITLE)))
    if achievements.equipped_title not in achievements.available_titles():
        achievements.equipped_title=DEFAULT_TITLE

    inventory_data=data["inventory"]; inventory=Inventory()
    for item_id,quantity_raw in dict(inventory_data["stacks"]).items():
        quantity=int(quantity_raw); definition=get_item_definition(str(item_id))
        if definition.is_equipment: raise SaveGameError(f"Wyposażenie {item_id} zapisano błędnie jako stos.")
        if quantity<=0: raise SaveGameError(f"Nieprawidłowa ilość przedmiotu {item_id}.")
        inventory.stacks[str(item_id)]=quantity
    inventory.equipment_items=[_equipment_item_from_dict(x) for x in list(inventory_data["equipment_items"])]

    equipment=Equipment(); seen={item.instance_id for item in inventory.equipment_items}
    for slot_code,item_data in dict(data["equipment"]).items():
        try: slot=next(candidate for candidate in EquipmentSlot if candidate.code==slot_code)
        except StopIteration as error: raise SaveGameError(f"Nieznany slot wyposażenia: {slot_code}.") from error
        item=_equipment_item_from_dict(item_data); definition=get_item_definition(item.item_id)
        if definition.slot is not slot: raise SaveGameError(f"Przedmiot {item.item_id} znajduje się w złym slocie.")
        if item.instance_id in seen: raise SaveGameError("Ten sam egzemplarz wyposażenia występuje w zapisie więcej niż raz.")
        seen.add(item.instance_id); equipment.slots[slot]=item

    try:
        character_class=player_class_from_code(
            str(data.get("character_class","none"))
        )
    except ValueError as error:
        raise SaveGameError(str(error)) from error

    player=Player(
        name=name,level=int(data["level"]),experience=int(data["experience"]),gold=int(data["gold"]),rubies=int(data["rubies"]),
        unspent_attribute_points=int(data["unspent_attribute_points"]),carry_upgrade_level=int(data.get("carry_upgrade_level", 0)),character_class=character_class,
        attributes=attributes,passives=passives,passive_masteries=passive_masteries,
        passive_specializations=passive_specializations,talents=talents,unlocked_class_paths=unlocked_class_paths,
        discovered_hunter_combos=discovered_hunter_combos,achievements=achievements,
        inventory=inventory,equipment=equipment,
    )
    if any(value<0 for value in (player.level,player.experience,player.gold,player.rubies,player.unspent_attribute_points)):
        raise SaveGameError("Zapis zawiera ujemną wartość progresji.")
    if not 0 <= player.carry_upgrade_level <= 3:
        raise SaveGameError("Nieprawidłowy poziom ulepszenia udźwigu w zapisie.")
    player.recalculate_stats()
    hp=int(data["current_hp"]); mana=int(data["current_mana"])
    if hp<0 or mana<0: raise SaveGameError("HP i Mana w zapisie nie mogą być ujemne.")
    player.stats.current_hp=min(hp,player.stats.max_hp); player.stats.current_mana=min(mana,player.stats.max_mana)
    return player


def _quest_log_to_dict(log: QuestLog) -> dict[str, Any]:
    return {"active":dict(log.active),"completed":sorted(log.completed)}


def _quest_log_from_dict(data: dict[str, Any]) -> QuestLog:
    active={}
    for quest_id,progress_raw in dict(data.get("active",{})).items():
        if not quest_exists(str(quest_id)): raise SaveGameError(f"Nieznane zadanie w zapisie: {quest_id}.")
        progress=int(progress_raw)
        if progress<0: raise SaveGameError("Postęp zadania nie może być ujemny.")
        active[str(quest_id)]=progress
    completed=set()
    for quest_id in list(data.get("completed",[])):
        quest_id=str(quest_id)
        if not quest_exists(quest_id): raise SaveGameError(f"Nieznane ukończone zadanie: {quest_id}.")
        completed.add(quest_id)
    for quest_id in completed: active.pop(quest_id,None)
    return QuestLog(active=active,completed=completed)



def _contract_board_to_dict(
    board: ContractBoard,
) -> dict[str, Any]:
    return {
        "daily_date": board.daily_date,
        "daily_contracts": [
            contract_to_dict(contract)
            for contract in board.daily_contracts
        ],
        "daily_claimed": sorted(board.daily_claimed),
        "weekly_key": board.weekly_key,
        "weekly_contract": (
            None
            if board.weekly_contract is None
            else contract_to_dict(board.weekly_contract)
        ),
        "weekly_claimed": board.weekly_claimed,
        "progress": {
            contract_id: {
                str(index): int(value)
                for index, value in objective_progress.items()
            }
            for contract_id, objective_progress in board.progress.items()
        },
    }


def _contract_board_from_dict(
    data: dict[str, Any],
) -> ContractBoard:
    daily_contracts = [
        contract_from_dict(dict(raw))
        for raw in list(data.get("daily_contracts", []))
    ]
    daily_ids = {
        contract.contract_id
        for contract in daily_contracts
    }

    daily_claimed = {
        str(contract_id)
        for contract_id in list(data.get("daily_claimed", []))
    }
    if not daily_claimed <= daily_ids:
        raise SaveGameError(
            "Zapis zawiera nieznany ukończony kontrakt dzienny."
        )

    weekly_raw = data.get("weekly_contract")
    weekly_contract = (
        None
        if weekly_raw is None
        else contract_from_dict(dict(weekly_raw))
    )

    progress: dict[str, dict[str, int]] = {}
    for contract_id, raw_values in dict(
        data.get("progress", {})
    ).items():
        values: dict[str, int] = {}
        for index, value_raw in dict(raw_values).items():
            value = int(value_raw)
            if value < 0:
                raise SaveGameError(
                    "Postęp kontraktu nie może być ujemny."
                )
            values[str(index)] = value
        progress[str(contract_id)] = values

    board = ContractBoard(
        daily_date=str(data.get("daily_date", "")),
        daily_contracts=daily_contracts,
        daily_claimed=daily_claimed,
        weekly_key=str(data.get("weekly_key", "")),
        weekly_contract=weekly_contract,
        weekly_claimed=bool(data.get("weekly_claimed", False)),
        progress=progress,
    )

    active_ids = daily_ids
    if weekly_contract is not None:
        active_ids = active_ids | {weekly_contract.contract_id}

    # Stary, wygasły progres nie ma prawa wpływać na obecne kontrakty.
    board.progress = {
        contract_id: values
        for contract_id, values in board.progress.items()
        if contract_id in active_ids
    }
    return board


def _elite_discoveries_from_data(
    raw: list[Any],
) -> set[str]:
    discoveries: set[str] = set()
    for modifier_id_raw in raw:
        modifier_id = str(modifier_id_raw)
        if modifier_id not in ELITE_MODIFIERS:
            raise SaveGameError(
                f"Nieznany typ elity w zapisie: {modifier_id}."
            )
        discoveries.add(modifier_id)
    return discoveries


def _elite_miss_streaks_from_data(
    raw: dict[str, Any],
) -> dict[str, int]:
    streaks: dict[str, int] = {}

    for location_id_raw, count_raw in raw.items():
        location_id = str(location_id_raw)
        create_location(location_id)

        count = int(count_raw)
        if count < 0:
            raise SaveGameError(
                "Licznik spotkań bez elity nie może być ujemny."
            )
        streaks[location_id] = count

    return streaks


def _region_boss_respawns_from_data(
    raw: dict[str, Any],
) -> dict[str, int]:
    respawns: dict[str, int] = {}

    for boss_id_raw, count_raw in raw.items():
        boss_id = str(boss_id_raw)
        if boss_id not in REGION_BOSS_NAMES:
            raise SaveGameError(
                f"Nieznany boss regionu w zapisie: {boss_id}."
            )

        count = int(count_raw)
        if count < 0:
            raise SaveGameError(
                "Licznik odrodzenia bossa nie może być ujemny."
            )
        if count > 0:
            respawns[boss_id] = count

    return respawns

def _guild_progress_to_dict(progress: GuildProgress) -> dict[str, Any]:
    return {
        "reputation": progress.reputation,
        "milestones": sorted(progress.milestones),
    }


def _guild_progress_from_dict(data: dict[str, Any]) -> GuildProgress:
    reputation = int(data.get("reputation", 0))
    if reputation < 0:
        raise SaveGameError("Reputacja Gildii nie może być ujemna.")
    milestones = {str(value) for value in list(data.get("milestones", []))}
    return GuildProgress(reputation=reputation, milestones=milestones)


def _guild_storage_to_dict(storage: GuildStorage) -> dict[str, Any]:
    return {
        "stacks": dict(storage.inventory.stacks),
        "equipment_items": [
            _equipment_item_to_dict(item)
            for item in storage.inventory.equipment_items
        ],
    }


def _guild_storage_from_dict(data: dict[str, Any]) -> GuildStorage:
    storage = GuildStorage()
    for item_id, quantity_raw in dict(data.get("stacks", {})).items():
        item_id = str(item_id)
        quantity = int(quantity_raw)
        definition = get_item_definition(item_id)
        if definition.is_equipment:
            raise SaveGameError(
                f"Wyposażenie {item_id} zapisano błędnie jako stos w Magazynie Gildii."
            )
        if quantity <= 0:
            raise SaveGameError(
                f"Nieprawidłowa ilość przedmiotu {item_id} w Magazynie Gildii."
            )
        storage.inventory.stacks[item_id] = quantity

    storage.inventory.equipment_items = [
        _equipment_item_from_dict(dict(raw))
        for raw in list(data.get("equipment_items", []))
    ]
    if storage.used_slots > 200:
        raise SaveGameError("Magazyn Gildii przekracza limit 200 miejsc.")
    instance_ids = [
        item.instance_id for item in storage.inventory.equipment_items
    ]
    if len(instance_ids) != len(set(instance_ids)):
        raise SaveGameError("Ten sam egzemplarz wyposażenia występuje w Magazynie Gildii więcej niż raz.")
    return storage


def _black_market_to_dict(market: BlackMarketState) -> dict[str, Any]:
    return {
        "unlocked": market.unlocked,
        "informant_last_check_day": market.informant_last_check_day,
        "informant_failed_checks": market.informant_failed_checks,
        "informant_present_day": market.informant_present_day,
        "rotation_key": market.rotation_key,
        "offers": [
            {
                "offer_id": offer.offer_id,
                "item_id": offer.item_id,
                "quantity": offer.quantity,
                "base_price": offer.base_price,
            }
            for offer in market.offers
        ],
        "purchased_offer_ids": sorted(market.purchased_offer_ids),
        "buy_negotiated_prices": dict(market.buy_negotiated_prices),
        "sale_negotiated_prices": dict(market.sale_negotiated_prices),
    }


def _black_market_from_dict(data: dict[str, Any]) -> BlackMarketState:
    offers: list[BlackMarketOffer] = []
    for raw in list(data.get("offers", [])):
        item = dict(raw)
        item_id = str(item["item_id"])
        get_item_definition(item_id)
        quantity = int(item["quantity"])
        price = int(item["base_price"])
        if quantity <= 0 or price <= 0:
            raise SaveGameError("Nieprawidłowa oferta Czarnego Rynku.")
        offers.append(BlackMarketOffer(str(item["offer_id"]), item_id, quantity, price))
    market = BlackMarketState(
        unlocked=bool(data.get("unlocked", False)),
        informant_last_check_day=int(data.get("informant_last_check_day", 0)),
        informant_failed_checks=int(data.get("informant_failed_checks", 0)),
        informant_present_day=int(data.get("informant_present_day", 0)),
        rotation_key=str(data.get("rotation_key", "")),
        offers=offers,
        purchased_offer_ids={str(value) for value in list(data.get("purchased_offer_ids", []))},
        buy_negotiated_prices={str(key): int(value) for key, value in dict(data.get("buy_negotiated_prices", {})).items()},
        sale_negotiated_prices={str(key): int(value) for key, value in dict(data.get("sale_negotiated_prices", {})).items()},
    )
    if min(market.informant_last_check_day, market.informant_failed_checks, market.informant_present_day) < 0:
        raise SaveGameError("Nieprawidłowy stan informatora Czarnego Rynku.")
    if any(price <= 0 for price in market.buy_negotiated_prices.values()) or any(price <= 0 for price in market.sale_negotiated_prices.values()):
        raise SaveGameError("Nieprawidłowa wynegocjowana cena Czarnego Rynku.")
    return market


def _infer_legacy_guild_progress(payload: dict[str, Any]) -> dict[str, Any]:
    quests = dict(payload.get("quests", {}))
    completed = {str(value) for value in list(quests.get("completed", []))}
    milestones = {f"quest:{quest_id}" for quest_id in completed}
    reputation = len(completed) * 50

    player = dict(payload.get("player", {}))
    inventory = dict(player.get("inventory", {}))
    stacks = dict(inventory.get("stacks", {}))
    equipment_items = list(inventory.get("equipment_items", []))
    equipped = list(dict(player.get("equipment", {})).values())
    item_ids = {str(item.get("item_id")) for item in equipment_items + equipped if isinstance(item, dict)}

    entries = [str(entry) for entry in list(payload.get("adventure_log", []))]
    joined = "\n".join(entries)

    def add(milestone: str, amount: int) -> None:
        nonlocal reputation
        if milestone not in milestones:
            milestones.add(milestone)
            reputation += amount

    if "azhar_sigil" in stacks or "Pokonano Azhar" in joined:
        add("boss:azhar", 100)
    if "leviathan_scale" in stacks or "Pokonano Lewiatan Północy" in joined:
        add("boss:leviathan_north", 150)
    if (
        "crown_fragment" in stacks
        or item_ids.intersection({"grandmaster_sword", "sunken_order_cloak", "abyss_ring"})
        or "Ukończono dungeon: Krypta Zatopionego Zakonu" in joined
    ):
        add("dungeon:sunken_order_crypt", 150)
    if (
        "varek_sabre_fragment" in stacks
        or "varek_sabre" in item_ids
        or "Ukończono dungeon: Wrak Czarnej Floty" in joined
    ):
        add("dungeon:black_fleet_wreck", 250)

    return {"reputation": reputation, "milestones": sorted(milestones)}



def _companion_to_dict(companion: Companion) -> dict[str, Any]:
    return {
        "companion_id": companion.companion_id,
        "template_id": companion.template_id,
        "name": companion.name,
        "class_code": companion.class_code,
        "level": companion.level,
        "experience": companion.experience,
        "path_id": companion.path_id,
        "talents": dict(companion.talents),
        "attributes": {
            "strength": companion.attributes.strength,
            "vitality": companion.attributes.vitality,
            "intelligence": companion.attributes.intelligence,
            "dexterity": companion.attributes.dexterity,
            "endurance": companion.attributes.endurance,
            "luck": companion.attributes.luck,
        },
        "equipment": {
            slot.code: _equipment_item_to_dict(item)
            for slot, item in companion.equipment.slots.items()
        },
        "personal_instance_ids": sorted(companion.personal_instance_ids),
        "personal_storage": [
            _equipment_item_to_dict(item) for item in companion.personal_storage
        ],
        "relation": companion.relation,
        "quest_arc_id": companion.quest_arc_id,
        "quest_stage": companion.quest_stage,
        "memories": sorted(companion.memories),
        "rifts_together": companion.rifts_together,
        "injury_until_day": companion.injury_until_day,
        "dead": companion.dead,
        "active": companion.active,
        "tactic": companion.tactic,
        "current_hp": companion.current_hp,
        "current_mana": companion.current_mana,
        "dismissed_day": companion.dismissed_day,
    }


def _companion_from_dict(data: dict[str, Any]) -> Companion:
    template_id = str(data.get("template_id", ""))
    if template_id not in COMPANION_TEMPLATES:
        raise SaveGameError(f"Nieznany kompan w zapisie: {template_id}.")
    companion_id = str(data.get("companion_id", "")).strip()
    if not companion_id:
        raise SaveGameError("Kompan w zapisie nie ma identyfikatora.")
    class_code = str(data.get("class_code", ""))
    try:
        player_class_from_code(class_code)
    except ValueError as error:
        raise SaveGameError(str(error)) from error
    if class_code == "none":
        raise SaveGameError("Kompan nie może być bez klasy.")
    path_id = str(data.get("path_id", ""))
    if path_id not in CLASS_PATHS:
        raise SaveGameError("Nieznana Ścieżka kompana w zapisie.")
    if CLASS_PATHS[path_id].class_code != class_code:
        raise SaveGameError("Ścieżka kompana nie pasuje do jego klasy.")
    level = int(data.get("level", 0))
    experience = int(data.get("experience", 0))
    if level < 5 or experience < 0:
        raise SaveGameError("Nieprawidłowy poziom lub EXP kompana.")
    attrs = dict(data.get("attributes", {}))
    attributes = Attributes(
        strength=int(attrs.get("strength", 0)),
        vitality=int(attrs.get("vitality", 0)),
        intelligence=int(attrs.get("intelligence", 0)),
        dexterity=int(attrs.get("dexterity", 0)),
        endurance=int(attrs.get("endurance", 0)),
        luck=int(attrs.get("luck", 0)),
    )
    if any(value < 0 for value in attributes.as_dict().values()):
        raise SaveGameError("Atrybuty kompana nie mogą być ujemne.")
    talents = {str(key): int(value) for key, value in dict(data.get("talents", {})).items()}
    for talent_id, rank in talents.items():
        if talent_id not in TALENT_DATA or not 1 <= rank <= TALENT_DATA[talent_id].max_rank:
            raise SaveGameError("Nieprawidłowy talent kompana w zapisie.")

    equipment = Equipment()
    seen: set[str] = set()
    for slot_code, raw in dict(data.get("equipment", {})).items():
        try:
            slot = next(candidate for candidate in EquipmentSlot if candidate.code == str(slot_code))
        except StopIteration as error:
            raise SaveGameError(f"Nieznany slot wyposażenia kompana: {slot_code}.") from error
        item = _equipment_item_from_dict(dict(raw))
        if get_item_definition(item.item_id).slot is not slot:
            raise SaveGameError("Przedmiot kompana zapisano w złym slocie.")
        if item.instance_id in seen:
            raise SaveGameError("Ten sam przedmiot kompana występuje dwa razy.")
        seen.add(item.instance_id)
        equipment.slots[slot] = item
    personal_storage: list[EquipmentItem] = []
    for raw in list(data.get("personal_storage", [])):
        item = _equipment_item_from_dict(dict(raw))
        if item.instance_id in seen:
            raise SaveGameError("Ten sam osobisty przedmiot kompana występuje dwa razy.")
        seen.add(item.instance_id)
        personal_storage.append(item)
    personal_ids = {str(value) for value in list(data.get("personal_instance_ids", []))}
    if not personal_ids.issubset(seen):
        raise SaveGameError("Zapis kompana wskazuje nieistniejący osobisty przedmiot.")

    relation = int(data.get("relation", 0))
    if not -100 <= relation <= 100:
        raise SaveGameError("Relacja z kompanem jest poza zakresem.")
    values_nonnegative = (
        int(data.get("quest_stage", 0)), int(data.get("rifts_together", 0)),
        int(data.get("injury_until_day", 0)), int(data.get("current_hp", 0)),
        int(data.get("current_mana", 0)), int(data.get("dismissed_day", 0)),
    )
    if any(value < 0 for value in values_nonnegative):
        raise SaveGameError("Zapis kompana zawiera ujemny stan progresji.")
    tactic = str(data.get("tactic", "balanced"))
    if tactic not in COMPANION_TACTICS:
        raise SaveGameError("Nieprawidłowa taktyka kompana w zapisie.")

    return Companion(
        companion_id=companion_id,
        template_id=template_id,
        name=str(data.get("name", COMPANION_TEMPLATES[template_id].name)),
        class_code=class_code,
        level=level,
        experience=experience,
        path_id=path_id,
        talents=talents,
        attributes=attributes,
        equipment=equipment,
        personal_instance_ids=personal_ids,
        personal_storage=personal_storage,
        relation=relation,
        quest_arc_id=str(data.get("quest_arc_id", "")),
        quest_stage=int(data.get("quest_stage", 0)),
        memories={str(value) for value in list(data.get("memories", []))},
        rifts_together=int(data.get("rifts_together", 0)),
        injury_until_day=int(data.get("injury_until_day", 0)),
        dead=bool(data.get("dead", False)),
        active=bool(data.get("active", False)),
        tactic=tactic,
        current_hp=int(data.get("current_hp", 0)),
        current_mana=int(data.get("current_mana", 0)),
        dismissed_day=int(data.get("dismissed_day", 0)),
    )


def _candidate_to_dict(candidate: CompanionCandidate) -> dict[str, Any]:
    return {
        "candidate_id": candidate.candidate_id,
        "companion": _companion_to_dict(candidate.companion),
        "generated_day": candidate.generated_day,
        "recruitment_roll": candidate.recruitment_roll,
        "impression": candidate.impression,
        "talked": candidate.talked,
        "recruitment_attempted": candidate.recruitment_attempted,
        "returning": candidate.returning,
    }


def _candidate_from_dict(data: dict[str, Any]) -> CompanionCandidate:
    generated_day = int(data.get("generated_day", 0))
    recruitment_roll = int(data.get("recruitment_roll", 0))
    if generated_day < 0 or not 0 <= recruitment_roll <= 100:
        raise SaveGameError("Nieprawidłowy kandydat do drużyny w zapisie.")
    return CompanionCandidate(
        candidate_id=str(data.get("candidate_id", "")),
        companion=_companion_from_dict(dict(data.get("companion", {}))),
        generated_day=generated_day,
        recruitment_roll=recruitment_roll,
        impression=int(data.get("impression", 0)),
        talked=bool(data.get("talked", False)),
        recruitment_attempted=bool(data.get("recruitment_attempted", False)),
        returning=bool(data.get("returning", False)),
    )


def _party_to_dict(party: PartyState) -> dict[str, Any]:
    return {
        "companions": [_companion_to_dict(companion) for companion in party.companions],
        "dismissed_companions": [_companion_to_dict(companion) for companion in party.dismissed_companions],
        "candidates_day": party.candidates_day,
        "candidates": [_candidate_to_dict(candidate) for candidate in party.candidates],
        "messages": [
            {"day": message.day, "sender_id": message.sender_id, "sender_name": message.sender_name, "text": message.text, "read": message.read}
            for message in party.messages
        ],
        "last_message_day": party.last_message_day,
        "seen_banter": sorted(party.seen_banter),
        "fallen": [
            {
                "companion_id": fallen.companion_id, "name": fallen.name,
                "class_code": fallen.class_code, "level": fallen.level,
                "day": fallen.day, "cause": fallen.cause, "rift_rank": fallen.rift_rank,
            }
            for fallen in party.fallen
        ],
    }


def _party_from_dict(data: dict[str, Any]) -> PartyState:
    companions = [_companion_from_dict(dict(raw)) for raw in list(data.get("companions", []))]
    if len(companions) > 4:
        raise SaveGameError("Zapis zawiera zbyt wielu kompanów.")
    ids = [companion.companion_id for companion in companions]
    if len(set(ids)) != len(ids):
        raise SaveGameError("Zapis zawiera zduplikowanego kompana.")
    if sum(1 for companion in companions if companion.active and companion.can_join_party) > 3:
        raise SaveGameError("Zapis zawiera zbyt wielu aktywnych kompanów.")
    dismissed = [_companion_from_dict(dict(raw)) for raw in list(data.get("dismissed_companions", []))]
    candidates = [_candidate_from_dict(dict(raw)) for raw in list(data.get("candidates", []))]
    messages: list[PartyMessage] = []
    for raw in list(data.get("messages", [])):
        item = dict(raw)
        day = int(item.get("day", 0))
        if day < 0:
            raise SaveGameError("Nieprawidłowa data wiadomości drużyny.")
        messages.append(PartyMessage(day, str(item.get("sender_id", "")), str(item.get("sender_name", "")), str(item.get("text", "")), bool(item.get("read", False))))
    fallen: list[FallenCompanion] = []
    for raw in list(data.get("fallen", [])):
        item = dict(raw)
        rank = item.get("rift_rank")
        if rank is not None and str(rank) not in RIFT_RANKS:
            raise SaveGameError("Nieprawidłowa ranga Szczeliny na Tablicy Poległych.")
        fallen.append(FallenCompanion(
            str(item.get("companion_id", "")), str(item.get("name", "")), str(item.get("class_code", "")),
            int(item.get("level", 0)), int(item.get("day", 0)), str(item.get("cause", "")),
            None if rank is None else str(rank),
        ))
    candidates_day = int(data.get("candidates_day", 0))
    last_message_day = int(data.get("last_message_day", 0))
    if candidates_day < 0 or last_message_day < 0:
        raise SaveGameError("Nieprawidłowy stan czasu drużyny.")
    return PartyState(
        companions=companions,
        dismissed_companions=dismissed,
        candidates_day=candidates_day,
        candidates=candidates,
        messages=messages[-60:],
        last_message_day=last_message_day,
        seen_banter={str(value) for value in list(data.get("seen_banter", []))},
        fallen=fallen,
    )


def _rift_to_dict(rift: RiftInstance | None) -> dict[str, Any] | None:
    if rift is None:
        return None
    return {
        "rift_id": rift.rift_id, "rank_code": rift.rank_code,
        "theme_id": rift.theme_id, "theme_name": rift.theme_name,
        "modifier_ids": list(rift.modifier_ids), "discovered_day": rift.discovered_day,
        "expires_day": rift.expires_day, "seed": rift.seed,
        "segment_count": rift.segment_count, "boss_id": rift.boss_id,
        "boss_name": rift.boss_name, "closed": rift.closed, "closed_by": rift.closed_by,
    }


def _rift_from_dict(data: dict[str, Any] | None) -> RiftInstance | None:
    if data is None:
        return None
    rank_code = str(data.get("rank_code", ""))
    theme_id = str(data.get("theme_id", ""))
    modifier_ids = tuple(str(value) for value in list(data.get("modifier_ids", [])))
    if rank_code not in RIFT_RANKS or theme_id not in RIFT_THEMES:
        raise SaveGameError("Nieprawidłowa Szczelina w zapisie.")
    if any(value not in RIFT_MODIFIERS for value in modifier_ids):
        raise SaveGameError("Nieznany modyfikator Szczeliny w zapisie.")
    discovered_day = int(data.get("discovered_day", 0))
    expires_day = int(data.get("expires_day", 0))
    segment_count = int(data.get("segment_count", 0))
    if discovered_day < 1 or expires_day < discovered_day or segment_count < 2:
        raise SaveGameError("Nieprawidłowy czas lub długość Szczeliny.")
    return RiftInstance(
        rift_id=str(data.get("rift_id", "")), rank_code=rank_code,
        theme_id=theme_id, theme_name=str(data.get("theme_name", RIFT_THEMES[theme_id]["name"])),
        modifier_ids=modifier_ids, discovered_day=discovered_day,
        expires_day=expires_day, seed=int(data.get("seed", 0)), segment_count=segment_count,
        boss_id=str(data.get("boss_id", "")), boss_name=str(data.get("boss_name", "")),
        closed=bool(data.get("closed", False)), closed_by=str(data.get("closed_by", "")),
    )


def _expedition_to_dict(expedition: RiftExpedition | None) -> dict[str, Any] | None:
    if expedition is None:
        return None
    return {
        "rift_id": expedition.rift_id, "segment_index": expedition.segment_index,
        "party_companion_ids": list(expedition.party_companion_ids),
        "secured_rewards": dict(expedition.secured_rewards),
        "pending_unique_item_id": expedition.pending_unique_item_id,
        "started_day": expedition.started_day, "camp_visits": expedition.camp_visits,
        "defeated": expedition.defeated,
    }


def _expedition_from_dict(data: dict[str, Any] | None) -> RiftExpedition | None:
    if data is None:
        return None
    segment_index = int(data.get("segment_index", 0))
    started_day = int(data.get("started_day", 0))
    camp_visits = int(data.get("camp_visits", 0))
    if min(segment_index, started_day, camp_visits) < 0:
        raise SaveGameError("Nieprawidłowy stan ekspedycji Szczeliny.")
    return RiftExpedition(
        rift_id=str(data.get("rift_id", "")), segment_index=segment_index,
        party_companion_ids=tuple(str(value) for value in list(data.get("party_companion_ids", []))),
        secured_rewards={str(key): int(value) for key, value in dict(data.get("secured_rewards", {})).items()},
        pending_unique_item_id=(None if data.get("pending_unique_item_id") is None else str(data.get("pending_unique_item_id"))),
        started_day=started_day, camp_visits=camp_visits, defeated=bool(data.get("defeated", False)),
    )


def _rift_state_to_dict(state: RiftState) -> dict[str, Any]:
    return {
        "active_rift": _rift_to_dict(state.active_rift),
        "expedition": _expedition_to_dict(state.expedition),
        "next_spawn_day": state.next_spawn_day,
        "last_resolution_day": state.last_resolution_day,
        "completed_total": state.completed_total,
        "completed_by_rank": dict(state.completed_by_rank),
        "last_notice": state.last_notice,
    }


def _rift_state_from_dict(data: dict[str, Any]) -> RiftState:
    active = _rift_from_dict(data.get("active_rift"))
    expedition = _expedition_from_dict(data.get("expedition"))
    if expedition is not None:
        if active is None or expedition.rift_id != active.rift_id:
            raise SaveGameError("Ekspedycja nie pasuje do aktywnej Szczeliny.")
        if expedition.segment_index >= active.segment_count:
            raise SaveGameError("Postęp ekspedycji wykracza poza długość Szczeliny.")
    next_spawn_day = int(data.get("next_spawn_day", 2))
    last_resolution_day = int(data.get("last_resolution_day", 0))
    completed_total = int(data.get("completed_total", 0))
    completed_by_rank = {str(key): int(value) for key, value in dict(data.get("completed_by_rank", {})).items()}
    if any(rank not in RIFT_RANKS or value < 0 for rank, value in completed_by_rank.items()):
        raise SaveGameError("Nieprawidłowa historia Szczelin w zapisie.")
    if min(next_spawn_day, last_resolution_day, completed_total) < 0:
        raise SaveGameError("Nieprawidłowy stan systemu Szczelin.")
    return RiftState(
        active_rift=active, expedition=expedition, next_spawn_day=next_spawn_day,
        last_resolution_day=last_resolution_day, completed_total=completed_total,
        completed_by_rank=completed_by_rank, last_notice=str(data.get("last_notice", "")),
    )


def _expedition_preparation_to_dict(preparation: ExpeditionPreparationState) -> dict[str, Any]:
    return {
        "selected_location_id": preparation.selected_location_id,
        "presets": {
            preset_id: {
                "configured": preset.configured,
                "active_companion_ids": list(preset.active_companion_ids),
                "supplies": dict(preset.supplies),
            }
            for preset_id, preset in preparation.presets.items()
            if preset_id in PRESET_NAMES
        },
    }


def _expedition_preparation_from_dict(data: dict[str, Any]) -> ExpeditionPreparationState:
    selected_location_id = str(data.get("selected_location_id", ""))
    if selected_location_id:
        create_location(selected_location_id)
    preparation = ExpeditionPreparationState(selected_location_id=selected_location_id)
    raw_presets = dict(data.get("presets", {}))
    for preset_id in PRESET_ORDER:
        raw = dict(raw_presets.get(preset_id, {}))
        configured = bool(raw.get("configured", False))
        companion_ids = [str(value) for value in list(raw.get("active_companion_ids", []))]
        if len(companion_ids) > 3 or len(set(companion_ids)) != len(companion_ids):
            raise SaveGameError("Nieprawidłowy skład w presecie wyprawowym.")
        supplies: dict[str, int] = {}
        for item_id_raw, quantity_raw in dict(raw.get("supplies", {})).items():
            item_id = str(item_id_raw)
            quantity = int(quantity_raw)
            definition = get_item_definition(item_id)
            if not definition.is_consumable or quantity <= 0:
                raise SaveGameError("Nieprawidłowy zapas w presecie wyprawowym.")
            supplies[item_id] = quantity
        preparation.presets[preset_id] = ExpeditionPreset(
            preset_id=preset_id,
            configured=configured,
            active_companion_ids=companion_ids,
            supplies=supplies,
        )
    return preparation


def _state_to_dict(state: GameState) -> dict[str, Any]:
    if state.player is None: raise SaveGameError("Nie można zapisać gry bez bohatera.")
    return {
        "schema_version":SAVE_SCHEMA_VERSION,"game_version":GAME_VERSION,
        "player":_player_to_dict(state.player),
        "world":{
            "current_location_id":state.current_location_id,"current_city_id":state.current_city_id,
            "day":state.world_clock.day,"hour":state.world_clock.hour,
            "weather":state.weather.current.code,"weather_remaining_hours":state.weather.remaining_hours,
            "camp_rest_available": bool(state.camp_rest_available),
            "last_inn_rest_day": int(state.last_inn_rest_day),
        },
        "quests":_quest_log_to_dict(state.quest_log),
        "contracts":_contract_board_to_dict(state.contract_board),
        "elite_discoveries":sorted(state.elite_discoveries),
        "elite_miss_streaks":dict(state.elite_miss_streaks),
        "region_boss_respawns":dict(state.region_boss_respawns),
        "guild":_guild_progress_to_dict(state.guild_progress),
        "black_market":_black_market_to_dict(state.black_market),
        "guild_storage":_guild_storage_to_dict(state.guild_storage),
        "adventure_log":list(state.adventure_log.entries),
        "party":_party_to_dict(state.party),
        "rifts":_rift_state_to_dict(state.rifts),
        "expedition_preparation":_expedition_preparation_to_dict(state.expedition_preparation),
    }


def _normalize_payload(payload: dict[str, Any]) -> dict[str, Any]:
    schema=int(payload.get("schema_version",-1))
    if schema==SAVE_SCHEMA_VERSION: return payload
    if schema==PREVIOUS_SAVE_SCHEMA_VERSION or schema in OLDER_SAVE_SCHEMA_VERSIONS:
        upgraded=dict(payload)
        player=dict(upgraded["player"])
        player.setdefault("passives",{"attack_speed":0,"critical_damage":0,"health_regen":0,"increased_attack":0})
        player.setdefault("achievements",{"unlocked":[],"equipped_title":DEFAULT_TITLE})
        player.setdefault("character_class",PlayerClass.NONE.code)
        attrs = dict(player.get("attributes", {})); attrs.setdefault("luck", 0); player["attributes"] = attrs
        player.setdefault("passive_specializations", {})
        player.setdefault("talents", {})
        player.setdefault("unlocked_class_paths", [])
        player.setdefault("discovered_hunter_combos", [])

        # v0.21.7: dawny Kapitański Sygnet został przeniesiony ze slotu
        # pierścienia do bransolety. Od v0.24.3 wyświetla się jako Bransoleta
        # Czarnej Floty. Zachowujemy ten sam item_id, aby egzemplarz, ulepszenia
        # i affixy nie zostały utracone.
        equipment_data = dict(player.get("equipment", {}))
        ring_item = equipment_data.get("ring")
        if isinstance(ring_item, dict) and str(ring_item.get("item_id")) == "captain_signet":
            moved_item = equipment_data.pop("ring")
            if "bracelet" not in equipment_data:
                equipment_data["bracelet"] = moved_item
            else:
                inventory_data = dict(player.get("inventory", {}))
                equipment_items = list(inventory_data.get("equipment_items", []))
                equipment_items.append(moved_item)
                inventory_data["equipment_items"] = equipment_items
                player["inventory"] = inventory_data
        player["equipment"] = equipment_data

        # v0.23: klasy dostają własną broń i OFF-HAND bez utraty starego lootu.
        # Łuk/Kostur/Lanca są wymagane przez nowe skille, więc przy migracji
        # wyposażamy zestaw startowy automatycznie. Zastąpiony przedmiot trafia
        # do plecaka wraz z instancją, affixami i poziomem ulepszenia.
        class_code = str(player.get("character_class", "none"))
        starter_items = {
            "warrior": (("training_shield", "off_hand"),),
            "hunter": (("hunting_bow", "weapon"), ("simple_quiver", "off_hand")),
            "mage": (("apprentice_staff", "weapon"), ("mana_crystal_artifact", "off_hand")),
            "pierrot": (("caprice_lance", "weapon"), ("worn_fate_dice", "off_hand")),
        }
        inventory_data = dict(player.get("inventory", {}))
        equipment_items = list(inventory_data.get("equipment_items", []))

        def _find_raw_item(item_id: str):
            for index, raw in enumerate(equipment_items):
                if isinstance(raw, dict) and str(raw.get("item_id")) == item_id:
                    return index, raw
            for slot, raw in equipment_data.items():
                if isinstance(raw, dict) and str(raw.get("item_id")) == item_id:
                    return slot, raw
            return None, None

        for item_id, target_slot in starter_items.get(class_code, ()):
            location, raw_item = _find_raw_item(item_id)
            if raw_item is None:
                raw_item = {
                    "item_id": item_id,
                    "upgrade_level": 0,
                    "instance_id": f"v023-{player.get('name','hero')}-{item_id}",
                }
            elif isinstance(location, int):
                equipment_items.pop(location)
            elif isinstance(location, str):
                equipment_data.pop(location, None)

            replaced = equipment_data.get(target_slot)
            if isinstance(replaced, dict) and str(replaced.get("item_id")) != item_id:
                equipment_items.append(replaced)
            equipment_data[target_slot] = raw_item

        player["equipment"] = equipment_data
        inventory_data["equipment_items"] = equipment_items
        player["inventory"] = inventory_data

        upgraded["player"]=player
        world=dict(upgraded["world"]); world.setdefault("current_city_id",STARTING_CITY_ID)
        world.setdefault("weather",WeatherType.SUNNY.code); world.setdefault("weather_remaining_hours",6)
        upgraded["world"]=world
        upgraded.setdefault("quests",{"active":{},"completed":[]})
        upgraded.setdefault(
            "contracts",
            {
                "daily_date":"",
                "daily_contracts":[],
                "daily_claimed":[],
                "weekly_key":"",
                "weekly_contract":None,
                "weekly_claimed":False,
                "progress":{},
            },
        )
        upgraded.setdefault("elite_discoveries",[])
        upgraded.setdefault("elite_miss_streaks",{})
        upgraded.setdefault("region_boss_respawns",{})
        upgraded.setdefault("adventure_log",[])
        player.setdefault("passive_masteries", [])

        # v0.22: stary tytuł Weterana nie jest już nagrodą za kilka questów.
        achievements = dict(player.get("achievements", {}))
        old_unlocked = [str(value) for value in list(achievements.get("unlocked", []))]
        achievements["unlocked"] = [value for value in old_unlocked if value != "guild_veteran"]
        if str(achievements.get("equipped_title", DEFAULT_TITLE)) == "Weteran Gildii":
            achievements["equipped_title"] = DEFAULT_TITLE
        player["achievements"] = achievements
        upgraded["player"] = player

        upgraded.setdefault("guild", _infer_legacy_guild_progress(upgraded))
        upgraded.setdefault("black_market", {
            "unlocked": False,
            "informant_last_check_day": 0,
            "informant_failed_checks": 0,
            "informant_present_day": 0,
            "rotation_key": "",
            "offers": [],
            "purchased_offer_ids": [],
            "buy_negotiated_prices": {},
            "sale_negotiated_prices": {},
        })
        upgraded.setdefault("party", _party_to_dict(PartyState()))
        upgraded.setdefault("rifts", _rift_state_to_dict(RiftState()))
        upgraded.setdefault("guild_storage", _guild_storage_to_dict(GuildStorage()))
        upgraded.setdefault("expedition_preparation", _expedition_preparation_to_dict(ExpeditionPreparationState()))
        player = dict(upgraded["player"])
        player.setdefault("carry_upgrade_level", 0)
        upgraded["player"] = player
        upgraded["schema_version"]=SAVE_SCHEMA_VERSION
        return upgraded
    raise SaveGameError("Nieobsługiwana wersja formatu zapisu.")


def save_game(state: GameState, slot_name: str = DEFAULT_SAVE_SLOT) -> Path:
    directory=get_save_directory(); directory.mkdir(parents=True,exist_ok=True)
    path=get_save_path(slot_name); temp_path=path.with_suffix(path.suffix+".tmp"); payload=_state_to_dict(state)
    try:
        with temp_path.open("w",encoding="utf-8") as file:
            json.dump(payload,file,ensure_ascii=False,indent=2); file.flush(); os.fsync(file.fileno())
        os.replace(temp_path,path)
    except (OSError,TypeError,ValueError) as error:
        try: temp_path.unlink(missing_ok=True)
        except OSError: pass
        raise SaveGameError(f"Nie udało się zapisać gry: {error}") from error
    return path


def _read_payload_from_path(path: Path) -> dict[str, Any]:
    if not path.is_file(): raise SaveGameError("Nie znaleziono pliku zapisu.")
    try:
        with path.open("r",encoding="utf-8") as file: payload=json.load(file)
    except (OSError,json.JSONDecodeError) as error:
        raise SaveGameError("Plik zapisu jest uszkodzony albo nie można go odczytać.") from error
    if not isinstance(payload,dict): raise SaveGameError("Nieprawidłowy format pliku zapisu.")
    return _normalize_payload(payload)


def _state_from_payload(payload: dict[str, Any]) -> GameState:
    try:
        player=_player_from_dict(dict(payload["player"])); world=dict(payload["world"])
        location_id=str(world["current_location_id"]); create_location(location_id)
        city_id=str(world["current_city_id"]); create_city(city_id)
        day=int(world["day"]); hour=int(world["hour"])
        if day<1 or not 0<=hour<=23: raise SaveGameError("Nieprawidłowy czas świata w zapisie.")
        weather=WeatherState(current=weather_from_code(str(world.get("weather","sunny"))),remaining_hours=int(world.get("weather_remaining_hours",6)))
        if weather.remaining_hours<=0: raise SaveGameError("Nieprawidłowy czas trwania pogody.")
        quest_log=_quest_log_from_dict(dict(payload.get("quests",{})))
        contract_board=_contract_board_from_dict(
            dict(payload.get("contracts",{}))
        )
        elite_discoveries=_elite_discoveries_from_data(
            list(payload.get("elite_discoveries",[]))
        )
        elite_miss_streaks=_elite_miss_streaks_from_data(
            dict(payload.get("elite_miss_streaks",{}))
        )
        region_boss_respawns=_region_boss_respawns_from_data(
            dict(payload.get("region_boss_respawns",{}))
        )
        guild_progress=_guild_progress_from_dict(dict(payload.get("guild",{})))
        black_market=_black_market_from_dict(dict(payload.get("black_market",{})))
        guild_storage=_guild_storage_from_dict(dict(payload.get("guild_storage",{})))
        party=_party_from_dict(dict(payload.get("party",{})))
        rifts=_rift_state_from_dict(dict(payload.get("rifts",{})))
        expedition_preparation=_expedition_preparation_from_dict(dict(payload.get("expedition_preparation",{})))
        entries=[str(entry) for entry in list(payload.get("adventure_log",[]))][-50:]
        return GameState(
            running=True,
            active_game=True,
            player=player,
            current_location_id=location_id,
            current_city_id=city_id,
            world_clock=GameClock(day=day,hour=hour),
            weather=weather,
            camp_rest_available=bool(world.get("camp_rest_available", True)),
            last_inn_rest_day=max(0, int(world.get("last_inn_rest_day", 0))),
            quest_log=quest_log,
            contract_board=contract_board,
            elite_discoveries=elite_discoveries,
            elite_miss_streaks=elite_miss_streaks,
            region_boss_respawns=region_boss_respawns,
            guild_progress=guild_progress,
            black_market=black_market,
            guild_storage=guild_storage,
            adventure_log=AdventureLog(entries=entries),
            party=party,
            rifts=rifts,
            expedition_preparation=expedition_preparation,
        )
    except SaveGameError: raise
    except (KeyError,TypeError,ValueError) as error: raise SaveGameError("Plik zapisu ma brakujące albo nieprawidłowe dane.") from error


def load_game(slot_name: str = DEFAULT_SAVE_SLOT) -> GameState:
    return _state_from_payload(_read_payload_from_path(get_save_path(slot_name)))


def _summary_from_payload(payload: dict[str, Any]) -> SaveSummary:
    try:
        player=dict(payload["player"]); world=dict(payload["world"])
        location=create_location(str(world["current_location_id"])); city=create_city(str(world["current_city_id"]))
        return SaveSummary(player_name=str(player["name"]),level=int(player["level"]),day=int(world["day"]),hour=int(world["hour"]),location_name=location.name,city_name=city.name,game_version=str(payload.get("game_version","?")))
    except (KeyError,TypeError,ValueError) as error: raise SaveGameError("Nie można odczytać podsumowania zapisu.") from error


def get_save_summary(slot_name: str = DEFAULT_SAVE_SLOT) -> SaveSummary | None:
    if not save_exists(slot_name): return None
    return _summary_from_payload(_read_payload_from_path(get_save_path(slot_name)))


def _legacy_candidates() -> list[Path]:
    project_root=get_project_root(); candidates=[]; current=get_legacy_save_path()
    if current.is_file(): candidates.append(current)
    parent=project_root.parent
    try: siblings=list(parent.iterdir())
    except OSError: siblings=[]
    for sibling in siblings[:200]:
        if not sibling.is_dir() or sibling.resolve()==project_root.resolve(): continue
        name=sibling.name.lower()
        if "echoes" not in name and "pythonia" not in name: continue
        for candidate in (sibling/"saves"/DEFAULT_SAVE_SLOT, sibling/"echoes_of_pythonia"/"saves"/DEFAULT_SAVE_SLOT):
            if candidate.is_file() and candidate not in candidates: candidates.append(candidate)
    return sorted(candidates,key=lambda p:p.stat().st_mtime if p.exists() else 0,reverse=True)


def migrate_legacy_save_if_needed() -> Path | None:
    if save_exists(): return None
    for candidate in _legacy_candidates():
        try:
            state=_state_from_payload(_read_payload_from_path(candidate)); save_game(state); return candidate
        except (SaveGameError,OSError): continue
    return None
