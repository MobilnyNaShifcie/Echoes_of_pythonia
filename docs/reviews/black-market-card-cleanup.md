# Czarny Rynek — uproszczenie kart

Gałąź: `codex/black-market-card-cleanup`.
Baza: `3acf5488a03295df858503e2300d06d4399eac15`.
Jeden commit, bez scalania do main i bez push. Pełny hash końcowy w raporcie przekazania.

## Zmiany

- Usunięto węzeł napisu/przycisku „Porozmawiaj” znad lady wraz z jego połączeniami i obsługą podświetlenia. Kliknięcie sylwetki nadal otwiera standardową rozmowę. Klawiatura i kursor wskazujący pozostają obsługiwane; tooltip sylwetki to jedynie „Handlarz”.
- Usunięto cenę i monetę z każdej karty oraz dopisaną cenę z tooltipu karty. Cena z ikoną monety jest tylko w dolnym panelu wybranego przedmiotu. Targowanie nadal aktualizuje tę cenę.
- Ramka jakości obejmuje całą kartę z równym marginesem 8 jednostek UI z każdej strony. Nie ma skróconej ramki nad osobną stopką cenową. Ilustracja wykorzystuje odzyskane miejsce, zachowując proporcje i pełną sylwetkę; ilość pozostaje w prawym dolnym rogu.
- Bez zmian w wielkości i rozmieszczeniu kart, rozmowie NPC, dziennej dostawie, zakupach, cenach, jakości przedmiotów, grafice, zapisach i mechanikach gry.

## Testy i dowody

- Pełny GUT: **730/730**, 98 skryptów, 24 559 asercji, 218,199 s, kod wyjścia 0.
- Import zasobów, uruchomienie projektu i renderowanie OpenGL: PASS. Brak błędów parsera, brakujących zasobów i niedziałających odwołań.
- `gdformat --check`, `gdlint` oraz `git diff --check`: PASS.
- Brak zmian w `godot/core/` i plikach grafik. Nowe PNG pozostają wyłącznie w ignorowanym build.

Testy kontrolują brak napisu i dodatkowego rzędu ceny, równy margines ramek oraz mieścienie ilustracji i ilości w ramce dla 1920×1080, 1366×768, 1280×720 i 2560×1080. Wybór każdej z czterech kart aktualizuje jedyną cenę w szczegółach, nie kupując przedmiotu. Zachowano testy targowania, zakupu, skupu, X/Esc i faktycznych kliknięć; dodano aktywację rozmowy klawiaturą bez napisu.

Podglądy „przed” pochodzą z końcowej walidacji niezmienionej bazy 3acf548:
`build/black-market-review/chest-after/evidence/`.
Nowe zrzuty i logi:
`build/black-market-review/cards-after/`.
W obu katalogach zrzuty obejmują wejście, rozmowę, ofertę, brak złota, stan sprzedany i skup ksiąg w 1920×1080, 1366×768 i 1280×720. Są lokalne i ignorowane przez Git, nie są hostowane w docs. Obejrzano wejście bez napisu oraz ofertę w 1920×1080 i 1366×768.

Odtworzenie (izolowane profile i testowy zapis, bez dostępu do zapisów gracza):

```powershell
.venv/Scripts/python.exe scripts/review_black_market.py cards-after --tests
.venv/Scripts/gdformat.exe --check godot/ui/screens/black_market/black_market.gd godot/ui/screens/black_market/market_offer_card.gd godot/tests/test_black_market_offer_window.gd godot/tests/test_market_price_signs.gd
.venv/Scripts/gdlint.exe godot/ui/screens/black_market/black_market.gd godot/ui/screens/black_market/market_offer_card.gd godot/tests/test_black_market_offer_window.gd godot/tests/test_market_price_signs.gd
git diff --check
```

## Ryzyka i drugi recenzent

- Sprawdzić równe ramki i czytelność czterech kart w 1366×768, brak napisu nad ladą oraz cen pod ikonami.
- Sprawdzić kliknięcie handlarza, klawiaturę, powrót do rozmowy, wybór każdej karty, zmianę dolnej ceny po targowaniu i blokadę ponownego zakupu.
- Pozostaje wcześniejszy komunikat Windows `Failed to read the root certificate store.`, niezwiązany z parserem ani zasobami gry. Runner nadal odrzuca wszystkie pozostałe błędy.
- Zastane niezwiązane pliki kuźni i oznaczenia metadanych importu pozostawiono poza commitem.

## Zmienione pliki

- `godot/ui/screens/black_market/black_market.gd`
- `godot/ui/screens/black_market/black_market.tscn`
- `godot/ui/screens/black_market/market_offer_card.gd`
- `godot/tests/test_black_market_offer_window.gd`
- `godot/tests/test_market_price_signs.gd`
- `scripts/review_black_market.py`
- `docs/reviews/black-market-card-cleanup.md`
