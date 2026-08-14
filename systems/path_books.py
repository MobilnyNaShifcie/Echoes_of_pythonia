from dataclasses import dataclass
import random

from data.books import PATH_UNLOCK_BOOK_IDS, BookType, get_book_definition
from player.player import Player


PATH_BOOK_DROP_CHANCES: dict[str, float] = {
    "azhar": 0.005,
    "leviathan_north": 0.005,
    "crypt_warden": 0.01,
    "black_fleet_first_officer": 0.01,
    "order_grandmaster": 0.02,
    "admiral_varek": 0.02,
}


@dataclass(frozen=True)
class PathBookReadResult:
    item_id: str
    path_id: str


def roll_path_book_drop(enemy_id: str, rng: random.Random) -> str | None:
    chance = PATH_BOOK_DROP_CHANCES.get(enemy_id, 0.0)
    if chance <= 0.0 or rng.random() >= chance:
        return None
    return rng.choice(PATH_UNLOCK_BOOK_IDS)


def read_path_book(player: Player, item_id: str) -> PathBookReadResult:
    book = get_book_definition(item_id)
    if book.book_type is not BookType.PATH_UNLOCK or book.path_id is None:
        raise ValueError("Ta księga nie jest Księgą Ścieżki.")
    if book.class_code is not None and player.character_class.code != book.class_code:
        raise ValueError(
            "Ta Księga Ścieżki należy do innej klasy. Możesz ją zachować albo sprzedać na Czarnym Rynku."
        )
    if book.path_id in player.unlocked_class_paths:
        raise ValueError("Ta Ścieżka została już odblokowana.")
    if not player.inventory.has(item_id, 1):
        raise ValueError("Nie posiadasz tej księgi.")
    player.inventory.remove_item(item_id, 1)
    player.unlocked_class_paths.add(book.path_id)
    return PathBookReadResult(item_id=item_id, path_id=book.path_id)
