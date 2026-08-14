from datetime import date

from data.books import get_book_definition
from items.catalog import get_item_definition
from player.player import Player
from systems.black_market import (
    BlackMarketOffer,
    BlackMarketState,
    base_book_sell_price,
    effective_book_sell_price,
    effective_buy_price,
    books_in_inventory,
    next_rotation_date,
)
from ui.console import print_header


def show_informant_scene() -> None:
    print_header()
    print()
    print("NIEZNAJOMY W KARCZMIE")
    print("-" * 58)
    print("W ciemnym kącie sali siedzi człowiek w kapturze.")
    print("Nie ma przy sobie towaru. Gdy podchodzisz, przesuwa")
    print("po stole mały skrawek pergaminu z narysowaną drogą.")
    print()
    print('„Szukasz wiedzy, której Gildia nie wystawia na tablicy?”')
    print('„Zapamiętaj drogę. I nie pytaj, kto mi ją pokazał.”')
    print()
    print("ODBLOKOWANO: CZARNY RYNEK")


def show_black_market_menu(player: Player, market: BlackMarketState) -> str:
    while True:
        print_header(); print(); print("CZARNY RYNEK"); print("-" * 58)
        print(f"Gold: {player.gold}")
        print(f"Następna dostawa: {next_rotation_date(date.today()).isoformat()}")
        print()
        print("[1] Zobacz ofertę")
        print("[2] Sprzedaj księgi")
        print("[0] Powrót")
        print()
        choice=input("> ").strip()
        if choice in {"1","2","0"}: return choice
        print("\nNieprawidłowa opcja."); input("Naciśnij Enter...")


def show_black_market_offers(player: Player, market: BlackMarketState) -> list[BlackMarketOffer]:
    print_header(); print(); print("CZARNY RYNEK — OFERTA"); print("-" * 58)
    print(f"Gold: {player.gold}\n")
    for index, offer in enumerate(market.offers, start=1):
        definition=get_item_definition(offer.item_id)
        price=effective_buy_price(market, offer)
        sold=offer.offer_id in market.purchased_offer_ids
        negotiated=offer.offer_id in market.buy_negotiated_prices
        status=" [SPRZEDANE]" if sold else (" [CENA PO TARGOWANIU]" if negotiated else "")
        category=""
        try:
            book=get_book_definition(offer.item_id)
            category=f" [{book.book_type.display_name}]"
        except KeyError:
            pass
        qty=f" x{offer.quantity}" if offer.quantity>1 else ""
        print(f"[{index}] {definition.name}{qty}{category}")
        print(f"    {price} Gold{status}")
        print(f"    {definition.description}")
        print()
    print("[0] Powrót")
    return market.offers


def show_buy_offer_actions(market: BlackMarketState, offer: BlackMarketOffer) -> str:
    print()
    if offer.offer_id in market.purchased_offer_ids:
        print("Ta oferta została już wykupiona.")
        return "0"
    print("[1] Kup")
    if offer.offer_id not in market.buy_negotiated_prices:
        print("[2] Spróbuj się targować (jedna próba)")
    print("[0] Anuluj")
    return input("> ").strip()


def show_bargain_result(success: bool, old_price: int, new_price: int, *, selling: bool=False) -> None:
    print()
    if success:
        print("Targowanie udane.")
    else:
        print("Targowanie nieudane — handlarz zmienił cenę na swoją korzyść.")
    arrow=f"{old_price} → {new_price} Gold"
    print(arrow)
    print("Ta cena obowiązuje do następnej dostawy.")


def show_book_sell_menu(player: Player, market: BlackMarketState) -> list[str]:
    print_header(); print(); print("CZARNY RYNEK — SKUP KSIĄG"); print("-" * 58)
    print(f"Gold: {player.gold}\n")
    books=books_in_inventory(player)
    if not books:
        print("Nie masz ksiąg na sprzedaż.")
        print("\n[0] Powrót")
        return []
    for index,item_id in enumerate(books,start=1):
        definition=get_item_definition(item_id)
        quantity=player.inventory.count(item_id)
        price=effective_book_sell_price(market,item_id)
        note=" [CENA PO TARGOWANIU]" if item_id in market.sale_negotiated_prices else ""
        print(f"[{index}] {definition.name} x{quantity}")
        print(f"    Oferta: {price} Gold / szt.{note}")
    print("\n[0] Powrót")
    return books


def show_sell_book_actions(market: BlackMarketState, item_id: str) -> str:
    print()
    print("[1] Sprzedaj 1 egzemplarz")
    if item_id not in market.sale_negotiated_prices:
        print("[2] Spróbuj się targować (jedna próba)")
    print("[0] Anuluj")
    return input("> ").strip()
