# Warsztat Mireli — księga receptur

Gałąź: `codex/mirela-recipe-book`. Baza: `8b83dd8b7306eefaf3496c9ba3d29c1e288d01bc`.
Zakres: wdrożenie zaakceptowanej przez właściciela makiety otwartej księgi.
Bez scalania do main, pushu, zmian receptur, ekwipunku, balansu i formatu zapisów.

## Zmiana

- Standardowa rozmowa z Mirelą nadal poprzedza otwarcie usługi.
- Księga z zieloną skórą, mosiężną oprawą, pergaminem i osobnymi kontrolkami UI.
- Pięć zakładek regionów, po sześć receptur na stronie, łącznie 42 istniejące receptury.
- Wybór receptury pokazuje oryginalną ikonę, bazowe właściwości, opis i zachowane
  uwagi katalogowe. Długie opisy mają osobne przewijanie; nie wypychają składników.
- Wszystkie wymagane materiały oraz dodatni koszt złota widoczne jednocześnie,
  również dla receptury z pięcioma składnikami i złotem. Liczniki posiadane/wymagane,
  kolor dostępności, konkretna przyczyna blokady na przycisku/wierszu.
- Jeden przycisk Wytwórz wywołuje istniejący CraftingService; nie ma nowego modelu
  ekwipunku ani własnych reguł zużywania materiałów. Przeglądanie niczego nie zużywa.
- Po operacji odświeżenie liczników i dostępności, zachowanie receptury, istniejący
  sygnał state_changed do autosave. Nie są konsumowane przedmioty założone.
- Usługi Mireli wraca do rozmowy, X/Esc zamyka księgę. Brak animacji na tym etapie.
- Tło/NPC/ikony katalogowe zachowane bez edycji. Księga nie zasłania twarzy Mireli.

## Weryfikacja

Powtarzalna komenda z katalogu repozytorium:

```powershell
.venv/Scripts/python.exe scripts/review_workshop_book.py after --tests
```

Runner wykonuje import w recovery mode, boot rzeczywistego projektu, rendery
rzeczywistej sceny App i testy GUT. Profile i zapisy testowe są izolowane w build/;
nie czyta ani nie nadpisuje zapisu gracza. Nie zamyka uruchomionego edytora.

Skupione testy: `--only-tests --test-script=res://tests/test_workshop_book.gd`.
Zakres: wejście przez rozmowę, 42 receptury wybierane rzeczywistymi zdarzeniami
myszy, regiony/strony, zgodność każdego materiału i kosztu z backendem,
rozmieszczenie wszystkich wymagań w 1920×1080, 1366×768 i 1280×720, zużycie
materiałów dokładnie raz, aktualizacja liczników, walidacja po zmianie zasobów,
przedmiot założony pozostaje na postaci, zamykanie i ponowne otwieranie,
konfiguracja przed ready, autosave/load zachowujący instance ID i polskie znaki.

Wyniki końcowe (Godot 4.7.1, Windows, OpenGL compatibility):

- Pełna regresja GUT: **747/747**, 100 skryptów, 38 756 asercji, 224,46 s.
- Nowy zestaw warsztatu: **13/13** (w powyższym przebiegu), także obsługa Enter.
- Import, boot i capture: exit 0; brak błędów parsera, skryptów i zasobów.
- `git diff --check` i `git diff --cached --check`: poprawne.
- `gdlint` nowych skryptów runtime/test/capture oraz `gdformat --check`: poprawne.
- Obejrzane rzeczywiste rendery w trzech rozdzielczościach: bazowa receptura,
  druga strona, receptura regionalna, sześć kosztów i stan po wytworzeniu.
- Środowisko zgłasza `Failed to read the root certificate store.`; runner
  spośród komunikatów `ERROR:` dopuszcza wyłącznie ten znany komunikat systemowy.
- Import edytora zgłosił też `Failed to bind socket. Error: 3.` po załadowaniu
  układu edytora; zakończył się kodem 0. Nie występuje to w boot/capture/testach.
  Przyczyny ograniczenia socketu nie zmieniano ani nie obchodzono w tym zadaniu.

## Dowody lokalne — nie są częścią commita

- Przed: `build/workshop-book-review/before/evidence/recipe_1920x1080.png`.
- Po: `build/workshop-book-review/after/evidence/recipe_1920x1080.png`.
- Oba etapy: również rendery 1366×768 i 1280×720 oraz ambient/dialogue.
- Po: dodatkowo page2, ingredients, six_costs, crafted dla każdej rozdzielczości.
- Logi import/boot/capture/gut: `build/workshop-book-review/after/`.

Ścieżki są celowo opisem lokalnych artefaktów, nie linkami do plików w Git.
Scena sprzed zmiany jest utrwalona lokalnie; odtworzenie jej wymaga rewizji bazowej
i narzędzia capture_workshop_book, które obsługuje także brak węzła WorkshopBook.

## Drugi recenzent / ryzyka

Sprawdzić na swoim ekranie kontrast pergaminu, wielkość pisma, zgodność z makietą,
nawigację zakładkami i klawiaturą, długie nazwy/opisy, sześć kosztów Butów Północnego
Szlaku oraz wytworzenie receptury z regionu V i ponowne wczytanie zapisu.
Font używa istniejącego w projekcie podejścia SystemFont: Georgia, Noto Serif,
DejaVu Serif. Zweryfikowano Windows; inne systemy mogą inaczej składać tekst.
Właściwości na stronie są bazą z ItemDefinition, nie prognozą losowanych afiksów.
Zachowano dwa zastane, nieśledzone pliki kowadła w blacksmith_workbench; nie należą
do tej zmiany. Ostrzeżenie środowiska o magazynie certyfikatów nie jest błędem sceny.
Zastane pliki `.import` bywają oznaczone przez Git jako zmodyfikowane po imporcie
przy `core.autocrlf=true`; ich znormalizowany diff jest pusty. Nie zostały dodane
do commita. Jedyny nowy import w zmianie należy do grafiki księgi.

## Pliki

- `godot/ui/screens/workshop_book/workshop_book.tscn`
- `godot/ui/screens/workshop_book/workshop_book.gd`
- `godot/ui/screens/workshop_book/workshop_book.gd.uid`
- `godot/ui/screens/workshop_book/book_style.gd`
- `godot/ui/screens/workshop_book/book_style.gd.uid`
- `godot/ui/screens/workshop_book/book_ornament.gd`
- `godot/ui/screens/workshop_book/book_ornament.gd.uid`
- `godot/assets/ui/workshop/recipe_book_v1.png`
- `godot/assets/ui/workshop/recipe_book_v1.png.import`
- `godot/ui/screens/city_economy/city_economy.gd`
- `godot/ui/screens/city_economy/city_economy.tscn`
- `godot/ui/screens/city_economy/service_layout.gd`
- `godot/tests/test_workshop_book.gd`
- `godot/tests/test_workshop_book.gd.uid`
- `godot/tests/test_city_economy_screen.gd`
- `godot/tests/test_city_art_stage_nine_e.gd`
- `godot/tests/test_equipment_ui_stage_nine_b.gd`
- `godot/tests/test_item_icon_golden_slice_stage_nine_c.gd`
- `godot/tests/test_ui_readability_pass.gd`
- `godot/tests/test_integrated_npc_hit_regions.gd`
- `godot/tools/capture_workshop_book.gd`
- `godot/tools/capture_workshop_book.gd.uid`
- `scripts/review_workshop_book.py`.
- `godot/assets/ASSET_MANIFEST.md`
- `docs/reviews/workshop-book/README.md`

## Produkcyjna grafika — dokładny prompt i tryb

Tryb: built-in imagegen, edycja zaakceptowanej makiety jako referenced_image_paths.
Ścieżka produkcyjna: `godot/assets/ui/workshop/recipe_book_v1.png`.
Źródło i hash: wpis w ASSET_MANIFEST. Obraz źródłowy zachowany, bez retuszu Pythonem.

```text
Use case: precise-object-edit / background-extraction. Input image 1 is an OWNER-APPROVED game UI mockup. Produce the PRODUCTION BACKGROUND TEXTURE of exactly its open recipe book, isolated on genuinely transparent alpha. Keep the approved design: dark forest-green leather cover, fine brass/gold embossed edges, metal corner protectors and side hinges, thick layered page edges, beautiful warm ivory parchment, central gutter and slight page curvature, subtle botanical corner motifs, two hanging red and green ribbon ends at bottom. Near-orthographic front view for readable Godot UI. The entire open book should fill a landscape canvas about 4:3, tightly framed with small transparent padding, centered, with two equal spacious page areas and central spine at exactly 50% width. Preserve the reference's attractive craft and illustrated game rendering, not a redesign.
REMOVE ALL CONTENT from the pages: all words, headings, letters, numbers, icons, hood, leather ingredient, list rows, horizontal dividers, selection rectangle, buttons, close X, navigation arrows, and the five top numbered region tabs. These will be interactive Godot controls. The interior pages must be empty continuous softly textured parchment with only faint botanical decoration strictly at the outer corners, ample quiet writing space. DO NOT leave ghost text or silhouettes. REMOVE ALL surrounding scene: no NPC, workshop, wood counter, backdrop, buttons, title, scenery, black or white background, checkerboard or frame behind the book. No baked UI, text, symbols, watermark, new props or random ornaments. Only one complete isolated empty open book, real transparency outside its silhouette and around dangling ribbons. Preserve both pale parchment pages as fully opaque. High-resolution polished clean game texture.
```
