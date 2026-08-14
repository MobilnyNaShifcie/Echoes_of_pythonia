from dataclasses import dataclass
import random

from data.books import MASTERY_BOOK_IDS, BookType, get_book_definition
from player.passives import PassiveType
from player.player import Player


MASTERY_BOOK_DROP_CHANCES: dict[str, float] = {
    # Bossowie regionów.
    "azhar": 0.01,
    "leviathan_north": 0.01,
    # Najważniejsi przeciwnicy dungeonów.
    "crypt_warden": 0.02,
    "black_fleet_first_officer": 0.02,
    "order_grandmaster": 0.04,
    "admiral_varek": 0.04,
}


@dataclass(frozen=True)
class MasteryReadResult:
    item_id: str
    passive: PassiveType


def roll_mastery_book_drop(
    enemy_id: str,
    rng: random.Random,
) -> str | None:
    chance = MASTERY_BOOK_DROP_CHANCES.get(enemy_id, 0.0)
    if chance <= 0.0 or rng.random() >= chance:
        return None
    return rng.choice(MASTERY_BOOK_IDS)


def read_mastery_book(player: Player, item_id: str) -> MasteryReadResult:
    book = get_book_definition(item_id)
    if book.book_type is not BookType.MASTERY or book.passive_code is None:
        raise ValueError("Ta księga nie jest Księgą Mistrzostwa.")
    passive = next(
        passive for passive in PassiveType
        if passive.code == book.passive_code
    )
    if passive.code in player.passive_masteries:
        raise ValueError("To Mistrzostwo zostało już odblokowane.")
    if not player.inventory.has(item_id, 1):
        raise ValueError("Nie posiadasz tej księgi.")
    player.inventory.remove_item(item_id, 1)
    player.passive_masteries.add(passive.code)
    return MasteryReadResult(item_id=item_id, passive=passive)
