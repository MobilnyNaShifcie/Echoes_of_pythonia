from data.books import BOOK_DATA, BookType, get_book_definition
from items.catalog import get_item_definition
from player.passives import PassiveType
from player.player import Player
from ui.console import print_header


def show_books(player: Player) -> list[str]:
    print_header(); print(); print("KSIĘGI"); print("-" * 58)
    books=[item_id for item_id in BOOK_DATA if player.inventory.count(item_id)>0]
    if not books:
        print("Nie masz żadnych ksiąg.")
        print("\n[0] Powrót")
        return []
    for index,item_id in enumerate(books,start=1):
        definition=get_item_definition(item_id)
        book=get_book_definition(item_id)
        quantity=player.inventory.count(item_id)
        status=""
        if book.book_type is BookType.MASTERY and book.passive_code is not None:
            status=" [POZNANA]" if book.passive_code in player.passive_masteries else " [NIEPRZECZYTANA]"
        elif book.book_type is BookType.PATH_UNLOCK and book.path_id is not None:
            if book.path_id in player.unlocked_class_paths:
                status = " [POZNANA]"
            elif book.class_code == player.character_class.code:
                status = " [NIEPRZECZYTANA]"
            else:
                status = " [INNA KLASA]"
        print(f"[{index}] {definition.name} x{quantity}{status}")
        print(f"    {book.book_type.display_name}")
        print(f"    {definition.description}")
    print("\n[0] Powrót")
    return books
