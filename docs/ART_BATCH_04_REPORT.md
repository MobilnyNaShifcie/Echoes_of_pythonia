# Partia 04 — ostatnie 19 brakujących ikon przedmiotów

Zakończona i podpięta 2026-09-06. Audyt obecnego katalogu: **159/159 ikon, 0 braków**.
Ta partia obejmuje 3 przedmioty drugiej ręki późnej gry i 16 unikatów Szczelin. Nie dodaje przedmiotów ani nowych bonusów zestawów.

## Spójność i zakres

- Wojownik: stal, srebrne krawędzie, karmazyn i motyw pękniętego bastionu — tarcza, napierśnik, ostrze i bransoleta.
- Łowca: zielona skóra/tkanina, liściaste okucia i motyw trzech ech — dwa kołczany, łuk, płaszcz i pierścień.
- Mag: indygo, złote sploty, ametyst i chłodny błękit — relikwiarz, rozszczepiony artefakt, kostur, szata i medalion.
- Pierrot: kość słoniowa, czerń, czerwień i złoto — dwie talie, para kości, lanca i maska.

Wzorcami są istniejące postacie anime i zatwierdzone przedmioty. Najpierw powstały cztery ikony bazowe rodzin, następnie reszta wyposażenia z tymi referencjami. To wizualne rodziny, nie nowe sety. Pochodzenie unikatów odpowiada istniejącym pulom klasowym Szczelin; nie dopisano fikcyjnych potworów ani łupów.

## Pliki i pochodzenie

- Produkcja: `godot/assets/items/regional/<item_id>.png` — 19 osobnych plików RGBA 512×512.
- Podpięcie: `godot/core/items/class_item_catalog.gd`, wyłącznie mapa tekstur.
- Pełna lista ID, promptów, referencji i źródeł: `art_drafts/anime_style_batch_04/review_manifest.json`.
- Zachowane oryginały: `art_drafts/anime_style_batch_04/raw/`; przygotowane wersje: `processed/`.
- Plansza z miniaturami 64 px i ramkami UI: `output/item_art/anime_batch_04_review.png`.
- Rzeczywisty ekwipunek: `output/item_art/anime_batch_04_in_game.png`.
- Generacja: wbudowany **imagegen**, 19 ilustracji i 2 punktowe korekty. Bez zewnętrznego API i bez rysowania ilustracji skryptem.

Skill imagegen wyznaczył użycie referencji, zachowanie oryginałów i przegląd wizualny przed integracją. Poprawiono kamień Pierścienia Powidoku, w którym generator namalował szachownicę, oraz przycięty łańcuszek Medalionu Burzowego Archiwum. Pierwsze wersje zachowano jako pliki `*-first.png`.

Generator zwrócił nieprzezroczyste źródła: 11 z neutralnym tłem/szachownicą i 8 z magentą. Na podstawie wcześniejszej zgody użytkownika lokalnie usunięto tło, wskazując zamknięte otwory w 4 ikonach. W 3 ikonach oczyszczono brzeg z resztek koloru tła. Współrzędne i ustawienia są w manifeście. Prawdziwy fiolet kryształów pozostawiono — detektor koloru tła rozróżnia go od magenty, co obejmują osobne testy.

## Weryfikacja

- Nowe PNG: **19/19**, unikatowe ilustracje, przezroczyste marginesy, identyczne kopie robocze i produkcyjne. SHA-256: `output/item_art/anime_batch_04_asset_validation.json`.
- Ponowna walidacja partii 3: **30/30**.
- Godot: **82/82 testów, 4963 asercje, 12 zestawów**. Zakres: cztery partie ikon, faktyczny ekwipunek i podpowiedzi, ramki jakości, mikstury, region 5, prezentacja walki, cykl życia i nagrody Szczelin. Log: `output/item_art/anime_batch_04_tests.log`.
- Python: **6/6** testów wycinania tła oraz **3/3** testów odróżniania magenty od fioletowych kryształów. Początkowe wywołanie testów alfa z niewłaściwą ścieżką importu nie uruchomiło zestawu; poprawny przebieg to `python scripts/test_regional_item_cutout.py`.
- Import Godot, audyt i render rzeczywistego ekwipunku zakończone kodem 0.
- Audyt: 159 wpisów, 0 brakujących ikon; wszystkie pola poza ścieżką ikony identyczne jak przed partią. Treść katalogu klasowego poza mapą ikon również bez zmian.
- Sprawdzono planszę całej partii, ciemne/jasne tło, miniatury i faktyczny ekran ekwipunku. Przyciemnienie sprzętu innej klasy pochodzi z istniejącej blokady UI, nie z PNG.
- Profil testowy: `build/validation-runtime/item-art-profile/`. Podgląd pracuje na sesji wyłącznie w pamięci. Prawdziwego zapisu gracza nie odczytywano i nie zmieniano.
- Zachowano ceny, statystyki, poziomy, rzadkości, receptury, pule nagród i modele lady. Nowy zapis nie jest potrzebny.
- Znane komunikaty środowiskowe o certyfikatach oraz zasobach przy zamykaniu Godot pozostają w logach. To test wskazanego zakresu, nie pełny test całej gry.

## Co jest zamknięte, a co pozostaje

Zamknięto **braki ikon wszystkich obecnych przedmiotów**. Cztery partie nowego kierunku obejmują 109 ikon. Pozostałych 50 starszych ikon nie wymieniano hurtowo; ewentualne dalsze ujednolicanie jest osobnym przeglądem, nie brakiem grafiki.

Nie dodawano animacji ani modeli 3D. Propozycje subtelnych efektów dla wyjątkowych artefaktów pozostają w `docs/REGIONAL_ITEM_ART_BATCHES.md`.
