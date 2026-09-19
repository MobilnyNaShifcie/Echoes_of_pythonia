# Czarny Rynek — rozmowa NPC, skrzynia i dzienna dostawa

Gałąź: `codex/black-market-chest-dialogue`.
Baza: `0d45589e5ca40c8443aceff5a334182bd6d39040`.
Jeden commit; bez merge do main i bez push. Pełny hash końcowy w raporcie przekazania.

## Wykonane zmiany

- Kliknięcie handlarza lub napisu „Porozmawiaj” otwiera rozmowę, nie sklep. Panel korzysta z tego samego `InterfaceStyle.panel()` i `quiet_button()` co pozostali NPC. Akcje: „Zobacz ofertę”, „Skup ksiąg”, „Odejdź od lady”. Nie dodano nowego imienia ani fabuły.
- Oferty w otwartej drewnianej skrzyni: cztery równe karty w siatce 2×2, szczegóły i transakcja na froncie. Dotychczasowe ilustracje, przedmioty i kolory jakości z katalogu nie są zastępowane przez te z mockupu. Brak modeli 3D i przedmiotów na ladzie; usunięty wcześniej górny pasek nie wraca.
- X/Esc: skrzynia → rozmowa → widok lokacji → miasto. „Cofnij” nadal wraca do miasta. NPC nie przechwytuje kliknięć podczas oglądania oferty.
- Cena na każdej karcie oraz w szczegółach zakupu/skupu ma ikonę złotej monety zamiast „zł”. Ilości pozostają osobnymi etykietami. Pełny opis i ewentualnie skrócona cena/ilość są dostępne w tooltipach.
- Serwis już używał daty dziennej, ale ekran sprawdzał ją tylko przy konfiguracji. Dodano sprawdzanie co sekundę, przy otwieraniu rozmowy/oferty, odzyskaniu fokusu aplikacji i przed transakcją/targowaniem. Nowa dostawa resetuje stan poprzez istniejący serwis i emituje istniejący sygnał autosave.
- Kliknięcie dotyczące poprzedniej dostawy nie kupuje ani nie negocjuje nowego towaru. Po automatycznej zmianie oferty trzeba ponownie wybrać kartę. Ponowne wejście tego samego dnia nie odnawia sprzedanego towaru ani prób targowania.
- Bez zmian w cenach, szansach targowania, zawartości katalogu, limitach udźwigu, modelu ekwipunku i schemacie zapisów. Bez zmian w kuźni, postaci i wyposażeniu.

## Walidacja

- Końcowy pełny GUT: **729/729**, 98 skryptów, 24 492 asercje, 153,725 s; kod wyjścia 0. Log: `build/black-market-review/chest-after/gut.log`.
- Import zasobów, uruchomienie projektu oraz capture OpenGL: PASS. Brak błędów parsera, brakujących zasobów i uszkodzonych odwołań. Zrzuty potwierdzają rozmiar rozmowy 442×342 w przestrzeni UI.
- `gdformat --check` (9 zmienionych skryptów), `gdlint` (skrypty rynku, nowe testy, test cen i capture) oraz `git diff --check`: PASS.
- Metadane importu nowych grafik dołączono. Dowody w build są ignorowane; żaden plik build nie jest śledzony. Serwisy `godot/core/` pozostają bez zmian.

Zrzuty prawdziwej aplikacji: wejście, rozmowa, oferta, brak złota, sprzedany towar, skup ksiąg — w 1920×1080, 1366×768 i 1280×720. Obejrzano renderowane obrazy; karty i obrazy przedmiotów nie są przycięte, panel rozmowy pozostaje kompaktowy. Testy geometrii dodatkowo obejmują 2560×1080.

Nowe testy obejmują: codzienne odświeżanie zamiast tygodniowego, timer podczas otwartego ekranu, powrót z uśpienia/fokusu, bezpieczny zakup i targowanie na przełomie dni, sprzedaż księgi przy zmianie ceny, trwałość stanu tego samego dnia, granice miesiąca/roku/roku przestępnego i round-trip zapisu. Istniejące testy kliknięć, X/Esc, targowania, zakupów i skupu dostosowano do rozmowy poprzedzającej skrzynię. Test wspólnego motywu kontroluje styl i rozmiar panelu.

Pierwszy pełny przebieg, mimo zaliczonych asercji, został odrzucony przez runner: test timera zwalniał jego nadawcę przed zakończeniem emisji sygnału. Test czeka teraz na zakończenie emisji przed sprzątaniem. Sprawdzanie błędów nie zostało wyłączone.

## Odtworzenie i lokalne dowody

Z katalogu repozytorium:

```powershell
.venv/Scripts/python.exe scripts/review_black_market.py chest-after --tests
.venv/Scripts/gdlint.exe godot/ui/screens/black_market/black_market.gd godot/ui/screens/black_market/market_offer_card.gd godot/tests/test_black_market_daily_refresh.gd godot/tests/test_black_market_offer_window.gd godot/tests/test_market_price_signs.gd godot/tools/capture_black_market.gd
git diff --check
```

Runner importuje zasoby, uruchamia projekt, renderuje prawdziwą aplikację w OpenGL i uruchamia GUT. Używa osobnych profili APPDATA/LOCALAPPDATA/XDG_DATA_HOME oraz testowego SaveGameService. Zapisy użytkownika nie są odczytywane ani modyfikowane.

Przed: `build/black-market-review/chest-before/evidence/` (15 PNG).
Po: `build/black-market-review/chest-after/evidence/` (18 PNG).
Logi: `build/black-market-review/chest-after/{import,boot,capture,gut}.log`.
Dowody pozostają lokalne, w ignorowanym build; nie są dodawane do Git ani do docs. Wariant „przed” wymaga kodu bazowego, nie odtwarza dawnego wyglądu z nowego commita. Powyższe ścieżki są lokalizacjami lokalnymi, nie linkami do plików hostowanych w repozytorium.

## Grafika i pochodzenie

Metoda: wbudowane `imagegen`, jedna generacja z mockupem użytkownika jako referencją, bez CLI/API. Bez edycji ikonek przedmiotów.
Plik projektowy: `godot/assets/ui/black_market/offer_chest_v1.png`.
Rozmiar: 1402×1122, RGBA, przezroczysty obszar poza skrzynią (alpha narożnika 0).
SHA-256: `403036b158bb1bf118870eb4be70c31c09ddc8ce09836e352cd5f97148572819`.
Oryginał pozostaje w `C:/Users/kamil/.codex/generated_images/01a000c5-507d-7760-aa0e-b8169452ad43/exec-ff9a2c6f-ecdd-41a0-9826-002aa1782706.png`.
Referencja: `C:/Users/kamil/Downloads/ChatGPT Image 19 wrz 2026, 14_18_06.png`.
Moneta: natywny `godot/assets/ui/black_market/gold_coin.svg`, paleta i cieniowanie zgodne z istniejącym `assets/ui/blacksmith/gold_stack.svg`. Napisy, karty i przyciski nie są wmalowane w dekorację.

Prompt końcowy (dokładny):

> Use case: stylized-concept. Asset type: transparent-background 2D game UI chest frame. Input image: reference for the open merchant chest on the RIGHT only, not an edit of the full screenshot. Generate ONLY that open wooden merchant chest as a clean isolated reusable UI asset, front-facing symmetric with mild perspective, dark brown wood, warm antique brass hinges/rivets/locks and dark plum-purple velvet lining. Keep the elegant stylized fantasy game illustration language of the reference, controlled hand-painted details, no photorealism. Wide nearly square 5:4 composition, entire chest visible, minimal outer margin. The tall open lid and upper interior occupy the top 70 percent and provide ONE large very dark quiet flat purple area for a header and four live item cards arranged 2x2. The lower chest front occupies bottom 25 percent and contains a wide empty dark rectangular inset for live item details. Keep these interior areas EMPTY and uncluttered, borders only around outer chest. No internal slots or painted cards. Lighting warm restrained edge highlights. Genuine transparent alpha outside chest, no room, ground or background, no checkerboard. NO text, letters, numbers, items, cards, coins, buttons, icons, characters, watermark or interface. Render just the illustrated empty chest frame.

## Ryzyka i drugi recenzent

- Dzienna dostawa korzysta z lokalnej daty komputera, zgodnie z dotychczasowym serwisem offline. Nie jest zegarem serwerowym ani zabezpieczeniem przed ręcznym przestawianiem daty.
- Pozostaje wcześniejszy komunikat środowiska Windows `Failed to read the root certificate store.`; nie dotyczy parsera, scen ani zasobów. Runner odrzuca wszystkie inne komunikaty ERROR.
- Sprawdzić: kliknięcie handlarza → rozmowa → oba rodzaje usługi, X/Esc/„Cofnij”, wybór klawiaturą, zakup tylko przez „Kup”, brak ponownego zakupu sprzedanej oferty, jedna próba targowania, sprzedaż ostatniej księgi.
- Obejrzeć czytelność kart i opisów przy 1366×768 oraz skalowanie skrzyni. Sprawdzić, że ramki odzwierciedlają rzeczywistą jakość z katalogu, nie ilustracyjne kolory z mockupu.
- Zweryfikować zmianę dnia przy otwartym sklepie oraz po wznowieniu aplikacji; ponowne wejście tego samego dnia nie może resetować dostawy.
- Zastane pliki kuźni i nieskopowane oznaczenia metadanych `.import` pozostawiono poza commitem.

## Lista zmienionych plików

- `godot/ui/screens/black_market/black_market.gd`
- `godot/ui/screens/black_market/black_market.tscn`
- `godot/ui/screens/black_market/market_offer_card.gd`
- `godot/assets/ui/black_market/offer_chest_v1.png`
- `godot/assets/ui/black_market/offer_chest_v1.png.import`
- `godot/assets/ui/black_market/gold_coin.svg`
- `godot/assets/ui/black_market/gold_coin.svg.import`
- `godot/tests/test_black_market_daily_refresh.gd`
- `godot/tests/test_black_market_daily_refresh.gd.uid`
- `godot/tests/test_black_market_offer_window.gd`
- `godot/tests/test_black_market_stage_five_d.gd`
- `godot/tests/test_integrated_npc_hit_regions.gd`
- `godot/tests/test_market_price_signs.gd`
- `godot/tools/capture_black_market.gd`
- `godot/tools/verify_npc_navigation.gd`
- `scripts/review_black_market.py`
- `docs/ART_DIRECTION_ANIME_FANTASY.md`
- `docs/reviews/black-market-chest-dialogue.md`
