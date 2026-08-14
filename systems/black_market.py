from __future__ import annotations

from dataclasses import dataclass, field
from datetime import date, timedelta
import hashlib
import random

from data.books import BOOK_DATA, MASTERY_BOOK_IDS, PATH_UNLOCK_BOOK_IDS, get_book_definition
from data.guild import BLACK_MARKET_CONTACT_RANK
from items.catalog import get_item_definition
from player.player import Player
from quests.models import QuestLog
from systems.guild_progression import GuildProgress, has_guild_rank


INFORMANT_CHANCE = 0.20
INFORMANT_PITY_FAILED_CHECKS = 4
BLACK_MARKET_ROTATION_DAYS = 1
BARGAIN_SUCCESS_CHANCE = 0.30


@dataclass(frozen=True)
class BlackMarketOffer:
    offer_id: str
    item_id: str
    quantity: int
    base_price: int


@dataclass
class BlackMarketState:
    unlocked: bool = False
    informant_last_check_day: int = 0
    informant_failed_checks: int = 0
    informant_present_day: int = 0
    rotation_key: str = ""
    offers: list[BlackMarketOffer] = field(default_factory=list)
    purchased_offer_ids: set[str] = field(default_factory=set)
    buy_negotiated_prices: dict[str, int] = field(default_factory=dict)
    sale_negotiated_prices: dict[str, int] = field(default_factory=dict)


@dataclass(frozen=True)
class BargainResult:
    success: bool
    old_price: int
    new_price: int


MARKET_GOODS: tuple[tuple[str, int, int], ...] = (
    ("spark_of_life", 1, 8_500),
    ("common_essence", 3, 4_800),
    ("grandmaster_elixir", 1, 7_500),
    ("black_pearl", 2, 7_000),
    ("leviathan_scale", 1, 13_000),
    ("hearth_core", 1, 9_500),
    ("azhar_sigil", 1, 12_000),
)


def informant_eligible(
    progress: GuildProgress,
    quest_log: QuestLog,
) -> bool:
    return (
        has_guild_rank(progress, BLACK_MARKET_CONTACT_RANK)
        and bool(
            {
                "dungeon:sunken_order_crypt",
                "dungeon:black_fleet_wreck",
            }.intersection(progress.milestones)
        )
    )


def check_informant_for_day(
    market: BlackMarketState,
    progress: GuildProgress,
    quest_log: QuestLog,
    game_day: int,
    rng: random.Random,
) -> bool:
    if market.unlocked:
        return False
    if not informant_eligible(progress, quest_log):
        return False
    if market.informant_last_check_day == game_day:
        return market.informant_present_day == game_day

    market.informant_last_check_day = game_day
    guaranteed = market.informant_failed_checks >= INFORMANT_PITY_FAILED_CHECKS
    present = guaranteed or rng.random() < INFORMANT_CHANCE
    if present:
        market.informant_present_day = game_day
        market.informant_failed_checks = 0
    else:
        market.informant_present_day = 0
        market.informant_failed_checks += 1
    return present


def unlock_black_market(market: BlackMarketState) -> None:
    market.unlocked = True
    market.informant_present_day = 0


def rotation_key_for_date(today: date) -> str:
    block = today.toordinal() // BLACK_MARKET_ROTATION_DAYS
    return str(block)


def next_rotation_date(today: date) -> date:
    current = today.toordinal()
    block = current // BLACK_MARKET_ROTATION_DAYS
    next_ordinal = (block + 1) * BLACK_MARKET_ROTATION_DAYS
    return date.fromordinal(next_ordinal)


def _rotation_rng(player_name: str, key: str) -> random.Random:
    digest = hashlib.sha256(
        f"EchoesOfPythonia|black-market|{player_name}|{key}".encode("utf-8")
    ).digest()
    return random.Random(int.from_bytes(digest[:8], "big"))


def ensure_black_market_rotation(
    market: BlackMarketState,
    player_name: str,
    *,
    today: date | None = None,
) -> bool:
    current = today or date.today()
    key = rotation_key_for_date(current)
    if market.rotation_key == key and market.offers:
        return False

    rng = _rotation_rng(player_name, key)
    offers: list[BlackMarketOffer] = []

    # Wiedza bojowa jest najważniejszym towarem rynku, ale Księgi Ścieżki
    # są znacznie rzadsze i droższe od Ksiąg Mistrzostwa.
    book_roll = rng.random()
    item_id = None
    if book_roll < 0.08:
        item_id = rng.choice(PATH_UNLOCK_BOOK_IDS)
    elif book_roll < 0.55:
        item_id = rng.choice(MASTERY_BOOK_IDS)
    if item_id is not None:
        book = get_book_definition(item_id)
        offers.append(
            BlackMarketOffer(
                offer_id=f"{key}:book",
                item_id=item_id,
                quantity=1,
                base_price=book.buy_price,
            )
        )

    goods = list(MARKET_GOODS)
    rng.shuffle(goods)
    used_ids = {offer.item_id for offer in offers}
    for item_id, quantity, price in goods:
        if item_id in used_ids:
            continue
        get_item_definition(item_id)
        offers.append(
            BlackMarketOffer(
                offer_id=f"{key}:{len(offers)}",
                item_id=item_id,
                quantity=quantity,
                base_price=price,
            )
        )
        if len(offers) >= 4:
            break

    market.rotation_key = key
    market.offers = offers
    market.purchased_offer_ids.clear()
    market.buy_negotiated_prices.clear()
    market.sale_negotiated_prices.clear()
    return True


def effective_buy_price(market: BlackMarketState, offer: BlackMarketOffer) -> int:
    return market.buy_negotiated_prices.get(offer.offer_id, offer.base_price)


def bargain_buy(
    market: BlackMarketState,
    offer: BlackMarketOffer,
    rng: random.Random,
) -> BargainResult:
    if offer.offer_id in market.buy_negotiated_prices:
        raise ValueError("Cena tej oferty była już negocjowana.")
    old = offer.base_price
    success = rng.random() < BARGAIN_SUCCESS_CHANCE
    if success:
        factor = rng.uniform(0.85, 0.90)
    else:
        factor = rng.uniform(1.05, 1.10)
    new = max(1, int(round(old * factor / 50.0)) * 50)
    market.buy_negotiated_prices[offer.offer_id] = new
    return BargainResult(success, old, new)


def buy_black_market_offer(
    player: Player,
    market: BlackMarketState,
    offer: BlackMarketOffer,
) -> int:
    if offer.offer_id in market.purchased_offer_ids:
        raise ValueError("Ta oferta została już wykupiona.")
    price = effective_buy_price(market, offer)
    if player.gold < price:
        raise ValueError(f"Brakuje Golda. Potrzeba {price}, masz {player.gold}.")
    player.gold -= price
    player.inventory.add(offer.item_id, offer.quantity)
    market.purchased_offer_ids.add(offer.offer_id)
    return price


def books_in_inventory(player: Player) -> list[str]:
    return [item_id for item_id in BOOK_DATA if player.inventory.count(item_id) > 0]


def mastery_books_in_inventory(player: Player) -> list[str]:
    """Kompatybilny alias używany przez starsze testy/UI."""
    return books_in_inventory(player)


def base_book_sell_price(item_id: str) -> int:
    return get_book_definition(item_id).sell_price


def effective_book_sell_price(market: BlackMarketState, item_id: str) -> int:
    return market.sale_negotiated_prices.get(item_id, base_book_sell_price(item_id))


def bargain_book_sale(
    market: BlackMarketState,
    item_id: str,
    rng: random.Random,
) -> BargainResult:
    if item_id in market.sale_negotiated_prices:
        raise ValueError("Cena tej księgi była już negocjowana w tej dostawie.")
    old = base_book_sell_price(item_id)
    success = rng.random() < BARGAIN_SUCCESS_CHANCE
    if success:
        factor = rng.uniform(1.10, 1.15)
    else:
        factor = rng.uniform(0.90, 0.95)
    new = max(1, int(round(old * factor / 50.0)) * 50)
    market.sale_negotiated_prices[item_id] = new
    return BargainResult(success, old, new)


def sell_mastery_book(
    player: Player,
    market: BlackMarketState,
    item_id: str,
    quantity: int = 1,
) -> int:
    get_book_definition(item_id)
    if quantity <= 0:
        raise ValueError("Ilość musi być dodatnia.")
    if not player.inventory.has(item_id, quantity):
        raise ValueError("Nie posiadasz tylu egzemplarzy tej księgi.")
    unit = effective_book_sell_price(market, item_id)
    total = unit * quantity
    player.inventory.remove_item(item_id, quantity)
    player.add_gold(total)
    return total
