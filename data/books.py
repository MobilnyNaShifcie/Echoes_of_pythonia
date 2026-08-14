from dataclasses import dataclass
from enum import Enum


class BookType(Enum):
    MASTERY = ("mastery", "Księga Mistrzostwa")
    PATH_UNLOCK = ("path_unlock", "Księga Ścieżki")

    def __init__(self, code: str, display_name: str) -> None:
        self.code = code
        self.display_name = display_name


@dataclass(frozen=True)
class BookDefinition:
    item_id: str
    book_type: BookType
    passive_code: str | None = None
    path_id: str | None = None
    class_code: str | None = None
    buy_price: int = 0
    sell_price: int = 0


BOOK_DATA: dict[str, BookDefinition] = {
    "mastery_regeneration_book": BookDefinition(
        item_id="mastery_regeneration_book",
        book_type=BookType.MASTERY,
        passive_code="health_regen",
        buy_price=36_000,
        sell_price=16_000,
    ),
    "mastery_attack_speed_book": BookDefinition(
        item_id="mastery_attack_speed_book",
        book_type=BookType.MASTERY,
        passive_code="attack_speed",
        buy_price=42_000,
        sell_price=18_000,
    ),
    "mastery_critical_book": BookDefinition(
        item_id="mastery_critical_book",
        book_type=BookType.MASTERY,
        passive_code="critical_damage",
        buy_price=48_000,
        sell_price=21_000,
    ),
    "mastery_strength_book": BookDefinition(
        item_id="mastery_strength_book",
        book_type=BookType.MASTERY,
        passive_code="increased_attack",
        buy_price=40_000,
        sell_price=17_000,
    ),
    "path_heavy_knight_book": BookDefinition(
        item_id="path_heavy_knight_book", book_type=BookType.PATH_UNLOCK,
        path_id="warrior_heavy_knight", class_code="warrior", buy_price=78_000, sell_price=32_000,
    ),
    "path_phantom_archer_book": BookDefinition(
        item_id="path_phantom_archer_book", book_type=BookType.PATH_UNLOCK,
        path_id="hunter_phantom_archer", class_code="hunter", buy_price=82_000, sell_price=34_000,
    ),
    "path_arcana_book": BookDefinition(
        item_id="path_arcana_book", book_type=BookType.PATH_UNLOCK,
        path_id="mage_arcana", class_code="mage", buy_price=88_000, sell_price=36_000,
    ),
    "path_fortuna_book": BookDefinition(
        item_id="path_fortuna_book", book_type=BookType.PATH_UNLOCK,
        path_id="pierrot_fortuna", class_code="pierrot", buy_price=95_000, sell_price=40_000,
    ),
}

MASTERY_BOOK_IDS: tuple[str, ...] = tuple(
    item_id for item_id, book in BOOK_DATA.items()
    if book.book_type is BookType.MASTERY
)
PATH_UNLOCK_BOOK_IDS: tuple[str, ...] = tuple(
    item_id for item_id, book in BOOK_DATA.items()
    if book.book_type is BookType.PATH_UNLOCK
)


def get_book_definition(item_id: str) -> BookDefinition:
    if item_id not in BOOK_DATA:
        raise KeyError(f"Nieznana księga: {item_id}")
    return BOOK_DATA[item_id]
