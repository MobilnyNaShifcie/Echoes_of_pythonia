# Przedmioty regionalne — plan i stan prac (2026-09-06)

## Stan

- Katalog po czwartej partii: **159 przedmiotów, 159 ikon, 0 brakujących ikon**.
- Użytkownik zatwierdził nowy kierunek anime-fantasy na podstawie Czarnego Pazura, Hełmu Zgniłego Rycerza i Wisiorka Kultysty. Wzorce nadrzędne: postacie gry; szczegóły w `docs/ART_DIRECTION_ANIME_FANTASY.md`.
- Pierwsze **30 ikon podpięte**: 27 w katalogu regionalnym i 3 bronie w katalogu klasowym. Finalne PNG: `godot/assets/items/regional/`. Podgląd: `output/item_art/anime_batch_01_review.png`.
- Źródła i prompty nowej partii: `art_drafts/anime_style_batch_01/`. Lokalne usuwanie tła odbywa się za wyraźną zgodą użytkownika. Wszystkie finalne ikony mają prawdziwy kanał alfa; generator nie dostarczył gotowej przezroczystości.
- Starsze 21 szkiców w `art_drafts/regional_batch_01/` zachowane jako archiwum sprzed zmiany stylu, niepodpięte do gry.
- Druga partia: **30 nowych ikon podpiętych** (24 regionalne i 6 broni klasowych), Głucha Woda i Popielne Pogranicza. Rodziny wizualne odpowiadają potworom i składnikom receptur. Podgląd: `output/item_art/anime_batch_02_review.png`; źródła i pełne prompty: `art_drafts/anime_style_batch_02/review_manifest.json`.
- Trzecia partia: **30 nowych ikon podpiętych** (23 regionalne i 7 klasowych): Zatopiony Zakon, Azhar, Czarna Flota, Czarne Morze i północ. Podgląd: `output/item_art/anime_batch_03_review.png`; pełne prompty i źródła: `art_drafts/anime_style_batch_03/review_manifest.json`; raport: `docs/ART_BATCH_03_REPORT.md`.
- Czwarta partia: **19 nowych ikon podpiętych** — 3 przedmioty drugiej ręki późnej gry i 16 artefaktów Szczelin, spójne rodziny czterech klas. Podgląd: `output/item_art/anime_batch_04_review.png`; prompty i źródła: `art_drafts/anime_style_batch_04/review_manifest.json`; raport: `docs/ART_BATCH_04_REPORT.md`.
- **Braki ikon zamknięte.** Nowy kierunek obejmuje 109 ikon z czterech partii. Pozostaje selektywny przegląd stylu 50 starszych ikon — nie są brakującymi grafikami. Ujednolicenie całego katalogu nie jest jeszcze uznane za zakończone.
- Audyt do odtworzenia: `godot --headless --path godot --script res://tools/audit_item_art.gd`. Używać izolowanego APPDATA, nigdy zapisu gracza.

## Reguły wizualne

1. Wyłącznie ikony 2D do zwykłego ekwipunku; bez tworzenia nowych modeli 3D.
2. Materiał potwora wynika z jego istniejącej grafiki, opisu i tabeli łupów. Przed generowaniem obejrzeć obraz źródłowego potwora.
3. Przedmiot wytwarzany powinien pokazywać składniki receptury: pajęcze sploty, płyty rycerza, skórę niedźwiedzia, te same symbole kultu.
4. Rodzina wizualna nie oznacza dodania nowego bonusu zestawu. Zachować istniejące set_id i mechanikę.
5. Cały obiekt w kadrze, czytelny przy 64–96 px, bez napisów, ramek i ilości namalowanych w pliku. Ramki i ilość pochodzą z UI.
6. Ilustracyjne anime-fantasy zgodne z bohaterami i zatwierdzonymi trzema wzorcami: czytelne kontury, celowe płaszczyzny cienia, ograniczona mikrofaktura. Bez przypadkowych klejnotów i świetlików; nie upraszczać do płaskiej kreskówki.
7. Kontrola przezroczystości przed integracją: rzeczywisty kanał alpha, przezroczyste narożniki, brak szachownicy i jasnej obwódki. Nie naprawiać po cichu niedozwoloną metodą.
8. Z każdą partią zapisać manifest, prompty, źródła, podgląd kontaktowy i testy odczytu ikon przez katalog. Zachowywać oryginały; starsze ikony wymieniać selektywnie w ramach zatwierdzonego ujednolicania.

## Jakość — jedna paleta dla całego ekwipunku

| Kod | Nazwa | Kolor | Liczba obecnych przedmiotów |
| --- | --- | --- | ---: |
| common | Zwykły | szary #8b929c | 34 |
| uncommon | Niepospolity | zielony #4ab875 | 28 |
| rare | Rzadki | niebieski #4f96e8 | 57 |
| epic | Epicki | fioletowy #aa69dc | 26 |
| legendary | Legendarny | czerwony #e35b62 | 13 |
| mythic | Mityczny | pomarańczowy #f49b3f | 1 |

Paleta w `godot/ui/presentation/item_rarity_palette.gd`. Nie zmieniono dotychczasowych klas rzadkości, cen, statystyk, szans łupu ani afiksów. Każdy istniejący przedmiot dostaje kolor według swojego wpisu rarity. Wskazówka zawiera nazwę jakości; blokada poziomem nie usuwa kolorowej ramki.

## Propozycje efektów na później — niezaimplementowane

Zwykły ekwipunek pozostaje statyczny. Najlepiej zarezerwować animacje dla wyjątkowych artefaktów Szczelin oraz ekspozycji pojedynczego, wybranego przedmiotu. Nie animować jednocześnie całego plecaka.

| Przedmiot | Opcjonalny efekt | Gdzie |
| --- | --- | --- |
| Lanca Siedmiu Przypadków | powolna zmiana pojedynczych znaków losu | podgląd mitycznego przedmiotu |
| Łuk ze Szkła Szczeliny | delikatne przełamanie światła na szkliwie | zaznaczenie / zdobycie |
| Artefakt Rozszczepionego Splotu | dwa powoli przesuwające się pasma energii | podgląd artefaktu Szczeliny |
| Kostur Dwóch Gwiazd | naprzemienny puls dwóch punktów | podgląd przedmiotu |
| Szabla Admirała Vareka | ledwie widoczny chłodny refleks na ostrzu | nagroda bossa / podgląd |
| Rdzeń Paleniska | puls żaru wewnątrz szczelin | lada i duży podgląd |
| Iskra Życia | spokojne bladozielone pulsowanie rdzenia | lada i duży podgląd |
| Czarna Perła | subtelny ruch refleksu, bez otaczającej mgły | lada i duży podgląd |

Efekt nie zastępuje ramki jakości. Przy przyszłej implementacji zapewnić wyłączenie animacji i ograniczenie ruchu. Nie podnosić rarity tylko dlatego, że przedmiot ma efekt.

## Lada czarnego rynku

- Nowe tło `godot/assets/city/varenhold/interiors/black_market_anime_integrated_v4.png`: bez czterech skórzanych pól, zachowana postać, regały i wyposażenie.
- Poprzednie tło v3 zachowane jako możliwość powrotu.
- Łuska, Iskra, Rdzeń i Pieczęć obracane jako prawdziwa geometria i osadzane na najniższym punkcie. Naturalne podstawy eliksiru i perły pozostają.
- Usunięte sztuczne wspólne podstawy pozostałych prostych modeli. Księgi leżą, pospolita esencja jest ułożona na boku.
- Wiszące ceny i przenoszenie tego samego modelu pozostają.
- Podglądy izolowane: `output/counter_rest/`. To fixture z pamięci, nie zapis użytkownika.

## Weryfikacja

- Czwarta partia: **19/19 PNG RGBA 512×512**, prawdziwa przezroczystość i unikatowe ilustracje; kopie produkcyjne zgodne z przygotowanymi. Hashy i wyników szukać w `output/item_art/anime_batch_04_asset_validation.json`. Ponowna walidacja partii 3: 30/30.
- Najnowszy przebieg: **82/82 testów Godot, 4963 asercje, 12 zestawów**, w tym cztery partie ikon oraz Szczeliny. **6/6** testów wycinania tła i **3/3** testów rozróżniania magenty od fioletu kryształów. Log: `output/item_art/anime_batch_04_tests.log`; rzeczywisty ekwipunek: `output/item_art/anime_batch_04_in_game.png`. Audyt potwierdza **159/159 ikon, 0 braków**, bez zmian pól rozgrywki.
- Trzecia partia: 30/30 unikatowych PNG RGBA 512×512, marginesy alfa i zgodność kopii produkcyjnych. Raport: `output/item_art/anime_batch_03_asset_validation.json`. Sprawdzone na jasnym i ciemnym tle oraz przy 64 px; ponowna walidacja partii 2: 30/30.
- Przebieg trzeciej partii: **53/53 testów, 3647 asercji**, 9 zestawów (trzy partie ikon, rzeczywisty ekwipunek, jakość, mikstury, region 5 i prezentacja walki). Log: `output/item_art/anime_batch_03_tests.log`. Dodatkowo **6/6 testów wycinania tła**, w tym kontrolowanych otworów wewnątrz obiektów. Rzeczywista scena ekwipunku bez zapisu: `output/item_art/anime_batch_03_in_game.png`.
- Druga partia: 30/30 unikatowych PNG RGBA 512×512; bez zastępowania wcześniejszych ikon. Raport z SHA-256: `output/item_art/anime_batch_02_asset_validation.json`. Dwa źródła miały prawdziwy kanał alfa, w pozostałych lokalnie usunięto tło; krawędzie sprawdzone na ciemnym i jasnym tle oraz przy 64 px.
- Przebieg drugiej partii: **50/50 testów, 2896 asercji** (obie partie ikon, rzeczywisty ekwipunek, jakość, mikstury, region 5 i prezentacja walki). Log: `output/item_art/anime_batch_02_tests.log`. Dodatkowo 5/5 testów wycinania tła. Rzeczywista scena ekwipunku z sesją wyłącznie w pamięci: `output/item_art/anime_batch_02_in_game.png`.
- Nowa partia: 30/30 unikatowych PNG RGBA 512×512, przezroczyste marginesy, identyczne pliki robocze i produkcyjne. Raport i SHA-256: `output/item_art/anime_batch_01_asset_validation.json`.
- Końcowy przebieg po oczyszczeniu krawędzi: **47/47 testów, 2145 asercji** (nowe ikony w rzeczywistym ekwipunku, region 5, stary przepływ ikon, jakość, mikstury i walka). Log: `output/item_art/anime_batch_01_tests_final.log`. Dodatkowo 5/5 testów lokalnego usuwania tła.
- Sprawdzone obrazy rzeczywistej sceny walki dla wszystkich 7 przeciwników Lodowego Wybrzeża: `output/ice_coast/in_game/`.
- Poniższe 49 testów dotyczą wcześniejszego etapu lady, nie są dodatkowym pełnym testem całego projektu.

- 49/49 testów, 2075 asercji (10 zestawów: lada, geometria, przeciąganie, ceny, paleta, ekwipunek i przepływ ikon).
- Testy pracowały na izolowanym profilu w `build/validation-runtime/item-art-profile/`; bez odczytu i zmiany prawdziwego zapisu.
- Godot zakończył testy kodem 0. W logu pozostają komunikaty środowiskowe o magazynie certyfikatów i zasobach renderera przy zamykaniu; nie oznaczać logu jako pozbawionego ostrzeżeń.
- Pełna lista przypisań dla 159 przedmiotów: `docs/ITEM_RARITY_ASSIGNMENTS.md`.

### Prompt użyty do poprawki tła (built-in imagegen)

Edit the supplied game environment image only. Image 1 is the EDIT TARGET, approved black-market interior. Remove ONLY the four identical rectangular brown leather display mats with raised frames from the countertop. Reconstruct continuous worn wooden tabletop planks in those exact areas with the existing grain, restrained scratches, lighting and perspective. Empty bare wooden countertop, no display items. CRITICAL: Keep precisely the same camera, framing, image aspect ratio, countertop outer silhouette and front edge positions, hooded anime male merchant identity/face/hands/pose/size, all shelving, books, jade ornaments, gold and jewel treasure, lanterns, background, staircase ladder, room, colors and brightness. Do not move, redesign or add anything else. Do not add cloth, text, price signs, UI, new props, glow particles or pedestal. Maintain the original clean painted fantasy/anime RPG background style. This is a minimal local cleanup, not a new scene.

### Prompty dwóch szkiców (built-in imagegen)

#### Spaczona Skóra

Create ONE finished 2D inventory item icon for the painted fantasy RPG Echoes of Pythonia. Image 1 is an existing ITEM STYLE reference (material finish and readable silhouette only, do not copy its subject). Image 2 is the SOURCE MONSTER reference: the item must plausibly come from this exact creature. Single isolated item, centered on a square canvas, comfortably fills 78-84% of frame with no cropping. Genuine transparent alpha background, no black/white rectangle, no checkerboard painted into image. Crisp hand-painted fantasy illustration, restrained texture, warm upper-left light, controlled highlights, clean contours, readable at 64px. Not a photo, not a glossy 3D product render. No scenery, hands, creature, lettering, border, rarity frame, numbers, floating particles, aura or pedestal. Preserve monster's material identity without adding arbitrary unrelated gems.
ITEM: Spaczona Skóra: one folded thick irregular piece of black bear hide, short charcoal-violet fur along torn edges and smooth tough dark leather underside, a little dried black resin soaked through it, subtle muted violet discoloration from corruption, no luminous purple cracks. Clearly usable leather crafting material, NOT an entire bear pelt, no face/head/paws. Source is this black corrupted bear.

#### Czarny Pazur

Create ONE finished 2D inventory item icon for the painted fantasy RPG Echoes of Pythonia. Image 1 is an existing ITEM STYLE reference (material finish and readable silhouette only, do not copy its subject). Image 2 is the SOURCE MONSTER reference: the item must plausibly come from this exact creature. Single isolated item, centered on a square canvas, comfortably fills 78-84% of frame with no cropping. Genuine transparent alpha background, no black/white rectangle, no checkerboard painted into image. Crisp hand-painted fantasy illustration, restrained texture, warm upper-left light, controlled highlights, clean contours, readable at 64px. Not a photo, not a glossy 3D product render. No scenery, hands, creature, lettering, border, rarity frame, numbers, floating particles, aura or pedestal. Preserve monster's material identity without adding arbitrary unrelated gems.
ITEM: Czarny Pazur: one enormous curved tapered claw from this corrupted bear, charcoal horn with brown worn ridges, pale subtly chipped keratin edge, the root thicker and hollow, tip sharp. Silhouette must be a bear claw, not a fang, crystal or ornamental pendant. No blood, no fur clump, no glowing enchantment.
