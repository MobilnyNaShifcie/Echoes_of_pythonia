# Czarny Rynek — okno ofert 2D

Gałąź: `codex/black-market-offer-window`.
Baza: `240a8bc32e28713776b3111d7d871f6bc86841c2`.
Bez merge do `main` i bez push. Pełny hash końcowego commita znajduje się w raporcie przekazania; dokument jest częścią tego commita.

## Zmiana

- Pusta lada po wejściu, bez modeli, podstawek, wiszących cen i pola przeciągania zakupu. Ekran nie instancjonuje żadnego świata/viewportu 3D.
- Kliknięcie handlarza lub subtelnego napisu „Zobacz ofertę” otwiera okno po prawej. Handlarz pozostaje widoczny. X/Esc zamyka ofertę; osobny przycisk „Cofnij” wraca do miasta, a Esc na zamkniętym ekranie również wraca.
- Cztery jednakowe karty: istniejąca ilustracja katalogowa 2D bez przycięcia, ramka rzeczywistej jakości, ilość, cena, podświetlenie wyboru i stan „Sprzedane”. Kliknięcie/podwójne kliknięcie tylko wybiera; zakup wymaga przycisku „Kup”. Przeciągnięcie nie dokonuje transakcji.
- Wspólny dolny panel: miniatura, kategoria, nazwa, opis, cena/ilość, targowanie i zakup/sprzedaż. Długie teksty kończą się wielokropkiem i mają pełną treść w tooltipie. Komunikat transakcji nie zmienia wysokości okna.
- Usunięty cały nagłówek nad sceną, w tym etykiety postaci, złota i udźwigu. Daty dostawy są pojedynczą informacją wewnątrz okna. Skup ksiąg pozostaje dostępną zakładką.
- Bez zmian w serwisach ekonomii, katalogach przedmiotów, cenach, prawdopodobieństwie targowania, dziennej rotacji, limitach udźwigu, formacie zapisów i sygnałach autosave.
- Nie generowano nowych ilustracji. Dawne modele i ich samodzielne testy geometrii zachowano. Narzędzia ich podglądu nie odwołują się już do usuniętej wystawy w scenie gry.

## Odtworzenie i dowody

Uruchom z katalogu repozytorium:

```powershell
.venv/Scripts/python.exe scripts/review_black_market.py after --tests
.venv/Scripts/gdlint.exe godot/ui/screens/black_market/black_market.gd godot/ui/screens/black_market/market_offer_card.gd godot/tests/test_black_market_offer_window.gd godot/tools/capture_black_market.gd
git diff --check
```

Runner importuje zasoby, uruchamia projekt i prawdziwą scenę aplikacji, wykonuje zrzuty przez renderer OpenGL oraz opcjonalnie GUT. Profile APPDATA/LOCALAPPDATA/XDG_DATA_HOME i SaveGameService są odizolowane; nie korzysta z zapisów użytkownika.

Lokalne PNG, logi i profile znajdują się wyłącznie w ignorowanym `build/black-market-review/<stage>/`. Żaden plik `build/` nie jest śledzony przez Git. Dowody sprzed zmiany są w `before/evidence/`; nowe w `after/evidence/`. Stan `before` wymaga bazowego kodu sceny, nie odtwarza starego interfejsu z nowego commita.

Zrzuty dla 1920×1080, 1366×768 i 1280×720: `entrance_*`, `offers_*`, `insufficient_gold_*`, `sold_*`, `books_*`. Nie są dołączane do historii Git. Pełne lokalne linki przekazane w raporcie końcowym.

## Walidacja

- Końcowy pełny GUT: **719/719**, 97 skryptów, 24 271 asercji, 145,85 s; kod wyjścia 0. Log: `build/black-market-review/after/gut.log`.
- Nowy plik testów okna: **9/9**, w tym wejście, rzeczywiste kliknięcia w trzech rozdzielczościach, X/Esc, hover, targowanie, skup ksiąg, próba przeciągania, długie polskie teksty i bezpieczne wygaszanie podświetlenia podczas usuwania sceny.
- Import zasobów, start projektu i renderowane zrzuty prawdziwej aplikacji: PASS. Obejrzano wejście, ofertę, stan sprzedany i skup ksiąg; karty nie są przycięte, a szczegóły mieszczą się w panelu.
- `gdformat --check` i `gdlint` dla głównego skryptu, karty, nowego testu i capture: PASS.
- `git diff --check` oraz `git diff --cached --check`: PASS. Brak zmian w `godot/core/` i `godot/assets/`; brak śledzonych plików w `build/`.
- Wcześniejszy przebieg został odrzucony mimo zaliczonych asercji: wykrył odwołanie do etykiety już usuniętej przy zamykaniu sceny. Naprawiono je i dodano regresję; powyższy końcowy przebieg nie zawiera tego błędu, błędów parsera ani brakujących zasobów.

## Ryzyka i drugi przegląd

- Sprawdzić kliknięcie sylwetki i napisu, X/Esc/powrót, wybór klawiaturą, wszystkie cztery karty, ich stan po zakupie i powrocie do rynku, targowanie oraz skup ostatniej księgi.
- Obejrzeć czytelność i skalowanie na własnym ekranie, zwłaszcza 1366×768. Ramki mają rzeczywiste kolory z katalogu, nie kolory wymyślone na mockupie. Tej zmiany nie należy traktować jako zmiany jakości przedmiotów.
- Całe okno skaluje się jednolicie do dostępnego miejsca. Układ jest desktopowy; pionowy/mobile nie jest celem tego zadania.
- Pozostaje znany, wcześniejszy komunikat środowiska Windows: `Failed to read the root certificate store.` Nie dotyczy scen ani zasobów gry. Runner nie ignoruje innych błędów.
- Zastane, niezwiązane z rynkiem pliki kuźni oraz oznaczenia `.import` pozostawiono poza commitem.

## Pliki

Interfejs:

- `godot/ui/screens/black_market/black_market.gd`
- `godot/ui/screens/black_market/black_market.tscn`
- `godot/ui/screens/black_market/market_offer_card.gd` i `.gd.uid`

Testy:

- `godot/tests/test_black_market_offer_window.gd` i `.gd.uid`
- `godot/tests/test_black_market_stage_five_d.gd`
- `godot/tests/test_integrated_npc_hit_regions.gd`
- `godot/tests/test_leviathan_scale_reference.gd`
- `godot/tests/test_market_artifact_reference.gd`
- `godot/tests/test_market_item_drag.gd`
- `godot/tests/test_market_price_signs.gd`
- `godot/tests/test_spark_of_life_reference.gd`

Narzędzia:

- `scripts/review_black_market.py`
- `godot/tools/capture_black_market.gd` i `.gd.uid`
- `godot/tools/render_black_pearl_reference_preview.gd`
- `godot/tools/render_core_and_sigil_preview.gd`
- `godot/tools/render_counter_rest_preview.gd`
- `godot/tools/render_leviathan_scale_preview.gd`
- `godot/tools/render_market_drag_preview.gd`
- `godot/tools/render_spark_of_life_preview.gd`
- `godot/tools/render_swift_blade_manuscript_preview.gd`
- `godot/tools/verify_npc_navigation.gd`

Dokumentacja: `docs/ART_DIRECTION_ANIME_FANTASY.md` i niniejszy raport.
