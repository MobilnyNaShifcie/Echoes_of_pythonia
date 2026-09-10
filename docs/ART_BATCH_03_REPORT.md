# Partia 03 — 30 nowych ikon anime-fantasy

Zakończona i podpięta 2026-09-06. Katalog: **140/159 ikon**, **19 braków**.
Ta partia dodaje 23 ikony regionalne i 7 klasowych. Nie zastępuje wcześniejszych grafik i nie zmienia danych rozgrywki.

## Spójność i zakres

- Zatopiony Zakon: klucz, pieczęć, łańcuch, fragment korony, miecz, płaszcz, bransoleta i pierścień. Granat, postarzone okucia i czteroramienny symbol nawiązują do istniejącego pancerza Zakonu.
- Azhar: ostrze, korona i pierścień z motywem rogatej pieczęci, bursztynu i ciemnego metalu, na podstawie faktycznej grafiki przeciwnika.
- Czarna Flota: medalion, bransoleta, kompas, fragment szabli i Szabla Admirała Vareka. Wspólne kotwice, okucia i kształt ostrza, bez przypadkowych ozdób.
- Czarne Morze: kolczyki, amulet, pierścień Lewiatana i trzy bronie klasowe. Czarne perły, chłodne ostrza, łuski i turkus tworzą wspólną rodzinę.
- Północ: tkanina, chityna, białe futro, pióro gryfa, pancerz, buty i płaszcz. Materiały odnoszą się do istniejących grafik rozbitka, kraba, niedźwiedzia i gryfa; nie są losowymi składnikami.
- Tarcza Straży Paleniska zachowuje wzornictwo wcześniejszych karwaszy.

Istniejące grafiki bohaterów i zaakceptowane ikony są wzorcem kreski oraz cieniowania. Tam, gdzie nie ma osobnej grafiki bossa lochu (Wielki Mistrz i Varek), wykorzystano opisy oraz istniejące wyposażenie frakcji i kapitana widmo; nie dodawano ani nie zakładano nowych grafik tych bossów.

## Pliki, źródła i prompty

- Produkcja: `godot/assets/items/regional/<item_id>.png` — 30 osobnych PNG RGBA 512×512, przezroczyste marginesy, bez napisów i ramek w obrazie.
- Wszystkie ID, przypisania, pełne prompty, referencje i ścieżki źródłowe: `art_drafts/anime_style_batch_03/review_manifest.json`.
- Oryginały: `art_drafts/anime_style_batch_03/raw/`; przygotowane kopie: `processed/` w tym samym folderze. Oryginały generatora również zachowano.
- Podgląd całej partii: `output/item_art/anime_batch_03_review.png`.
- Faktyczny ekwipunek: `output/item_art/anime_batch_03_in_game.png`.
- Generacja: wbudowany **imagegen**, 30 osobnych nowych ilustracji oraz jedna korekta pancerza północy; bez zewnętrznego API. Pierwszy wariant pancerza zachowano jako `raw/north_armor-first.png`.
- Skill imagegen wpłynął na sposób użycia referencji, zachowanie źródeł oraz kontrolę wizualną. Najpierw powstało 11 kotwic materiałowych/frakcyjnych, następnie 19 ikon z odwołaniem do tych rodzin.

Generator dostarczył obrazy nieprzezroczyste. Zgodnie z wcześniejszą zgodą użytkownika usunięto tło lokalnie: 11 źródeł z neutralnym tłem/szachownicą i 19 z tłem magenta. W 5 ikonach jawnie wskazano zamknięte otwory między elementami, chroniąc białe futro i refleksy. W 10 ikonach oczyszczono pozostałości magenty na krawędziach. Metody i współrzędne zapisano w manifeście. Nie domalowywano nowych ilustracji skryptem.

## Weryfikacja

- `scripts/verify_anime_item_batch.py --batch 3`: **30/30**; unikatowe obrazy, alfa, marginesy, zgodność kopii produkcyjnych i przygotowanych. SHA-256: `output/item_art/anime_batch_03_asset_validation.json`.
- Ponowna walidacja partii 2: **30/30**.
- **53/53 testów Godot, 3647 asercji, 9 zestawów**. Log: `output/item_art/anime_batch_03_tests.log`.
- **6/6 testów lokalnego wycinania tła**, w tym ochrona białych detali i odrzucanie niewłaściwych punktów usuwania tła.
- Import Godot i render prawdziwej sceny ekwipunku zakończone kodem 0. Przejrzano planszę 30 ikon, przezroczystość na jasnym/ciemnym tle, miniatury 64 px i ekran w grze. Przyciemnienie przedmiotów innej klasy jest istniejącym stanem blokady UI, nie częścią PNG.
- Audyt: 159 przedmiotów, 140 ikon, 19 braków (`output/item_art/catalog_audit.json`).
- Testy i podgląd używają izolowanego profilu `build/validation-runtime/item-art-profile/`; przedmioty testowe istnieją wyłącznie w pamięci. Nie czytano ani nie zmieniano prawdziwego zapisu gracza.
- Bez zmian cen, statystyk, rzadkości, receptur, łupów, bonusów zestawów oraz modeli lady. Ramki jakości nadal generuje UI.
- Pozostają znane komunikaty środowiskowe certyfikatów i zasobów przy zamykaniu Godot. To testy wskazanego zakresu, nie pełny test całego projektu.

## Następny zakres

Pozostało 19 brakujących ikon: trzy przedmioty drugiej ręki późnej gry i 16 artefaktów Szczelin. Potem selektywny przegląd 50 starszych ikon pod kątem nowego stylu. W tej partii nie dodawano animacji; wcześniejsze propozycje wyjątkowych efektów są w `docs/REGIONAL_ITEM_ART_BATCHES.md`.
