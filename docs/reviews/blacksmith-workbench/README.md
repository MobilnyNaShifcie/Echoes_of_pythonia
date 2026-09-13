# Kuźnia Garrana — przegląd warsztatu ulepszania

Gałąź: `codex/blacksmith-workbench-redesign`.
Baza: `dc73f3d928934999fd7054a458d29b4568664099`.
Raport dotyczy commita, w którym znajduje się ten plik; pełny hash jest podany
w odpowiedzi końcowej i dostępny przez `git rev-parse HEAD`.
Zmiana nie jest scalana do `main` ani wypychana automatycznie.

## Zakres i zachowane kontrakty

Pełnoekranowy warsztat zastępuje dotychczasowy mały panel ulepszania.
Oryginalna ilustracja kuźni pozostaje przyciemnionym tłem; widoczny po lewej
Garran jest kadrem tej samej tekstury, bez zmiany pliku graficznego.
Panele mają stalowo-grafitową paletę, złote obramowania i pomarańczową
poświatę kowadła. Motyw jest lokalny dla warsztatu, nie globalny dla gry.

Lewy panel oferuje pusty slot z konturem kowadła, wybór kliknięciem lub
przeciągnięciem, nazwę i rzadkość, źródło przedmiotu, poziom docelowy,
porównanie zmienianych statystyk, osobne kafelki materiałów i złota oraz
potwierdzenie operacji. Odłożenie i anulowane przeciągnięcie tylko zmieniają
wybór. Złoto jest zawsze w pierwszym wierszu wymagań; długa lista materiałów
przewija się wewnętrznie, bez wypychania przycisku ulepszenia poza ekran.

Prawa strona wykorzystuje niezmieniony `CharacterEquipmentPanel` i istniejącą
siatkę `InventoryGridView`: pełna aktualna ilustracja bohatera, wszystkie
11 dotychczasowych slotów, oryginalne mapowania i ramki rzadkości oraz
zwarty plecak. Filtry Wszystko / Założone / Plecak wybierają źródło dostępnych
przedmiotów. W trybie Plecak postać pozostaje widoczna, a sloty założone są
wygaszone i nie służą do wyboru. Nieobsługiwane przedmioty pozostają widoczne
z przyczyną blokady w podpowiedzi. W poprzednim widoku kowala nie było
dodatkowych filtrów typów, które wymagałyby zachowania.

Wszystkie koszty, maksymalny poziom, skalowanie, walidacja i transakcja nadal
pochodzą z `UpgradeService`. Widok przechowuje identyfikator instancji, ponownie
sprawdza własność i zasoby przy potwierdzeniu, a następnie ulepsza dokładnie
ten sam obiekt w plecaku lub slocie postaci. Podgląd nie modyfikuje obiektu
gracza nawet tymczasowo. Udana operacja emituje dotychczasowy sygnał zapisu;
złoto i udźwig odświeżają się także w poprzednim nagłówku po wyjściu.

Nie zmieniono `godot/core`, `godot/data`, `godot/assets`, balansu, schematu
zapisów ani ogólnego ekranu ekwipunku. Nie dodano losowej porażki, niszczenia
przedmiotów, nowej fabuły ani nowych slotów.

## Usunięte elementy starego widoku kowala

- Rozwijany wybór usługi i dotychczasowy pasek narzędzi w otwartym warsztacie.
- Mały katalog wyposażenia po prawej i tekstowy panel transakcji „Stół kowalski”.
- Pole „Ilość”, zastąpione poziomem docelowym z przyciskami minus/plus.
- Automatyczny wybór pierwszego wpisu: warsztat otwiera się z pustym kowadłem.
- Dublujące się nagłówki, komunikaty i przyciski starego widoku; warsztat ma
  powrót „Usługi kowala” oraz jeden przycisk X. Escape zamyka warsztat do kuźni.
- Niepotrzebne gałęzie kodu starego katalogu/transakcji obsługujące kowala.

Te same kontrolki pozostają tam, gdzie są nadal potrzebne innym usługodawcom.
Przenoszenie bonusu i rozkładanie są ukrytymi, nieaktywnymi miejscami na przyszłe
moduły. Główny ekran koordynuje widok usługi, wybór i nawigację; nie implementuje
mechanik ulepszania. Widok ulepszania, adapter podglądu, selektor wyposażenia,
kowadło i kafelek zasobu są rozdzielone.

## Weryfikacja

Środowisko: Godot 4.7.1 stable, Windows, renderer OpenGL dla zrzutów.
Testy i zrzuty używają odizolowanych katalogów profilu/zapisów pod `build/`,
nie istniejącego zapisu gracza.

| Kontrola | Wynik |
| --- | --- |
| Import projektu w edytorze headless | Kod wyjścia 0 |
| Uruchomienie właściwej sceny aplikacji | Kod wyjścia 0 |
| Zrzuty rzeczywistej aplikacji przez renderer | Kod wyjścia 0, oba rozmiary |
| Pełna regresja GUT | 697/697 testów, 94 skrypty, 23 057 asercji |
| Nowy zestaw warsztatu | 13/13 testów, włączony do pełnej regresji |
| `gdformat --check` | 17 zmienionych/dodanych skryptów GDScript, bez zmian |
| `gdlint` | Te same 17 skryptów, bez problemów |
| `git diff --check` | Bez błędów białych znaków |
| Diff core/data/assets | Pusty |
| Wygenerowane PNG i logi w Git | Brak; `build/` jest ignorowany |

Nowe testy obejmują:

1. Puste kowadło i otwarcie bez zmiany danych gracza.
2. Wybór założonego i plecakowego przedmiotu z zachowaniem instancji.
3. Odrzucenie nieobsługiwanego typu, fałszywego oraz nieaktualnego drag payload.
4. Braki materiałów/złota, dokładne niedobory i nieaktywną, atomową transakcję.
5. Zakres poziomów 1–10, sumę kanonicznych kosztów i niemutujący podgląd.
6. Ulepszenie o jeden i kilka poziomów w obu źródłach, koszty i sygnał zapisu.
7. Przedmiot +10 i brak dalszej operacji.
8. Powtórną walidację własności i złota bezpośrednio przed zatwierdzeniem.
9. Filtry źródeł z zachowaniem bohatera, mapowań i danych.
10. Rzeczywiste zdarzenia myszy: kliknięcie slotu, przeciągnięcie ze slotu
    i plecaka na kowadło, anulowanie przeciągnięcia; bez automatycznego zakupu.
11. Kliknięcie powrotu/X oraz Escape z aktywnym focusem kontrolki.
12. Geometrię w 1920×1080 i 1366×768: wszystkie 11 slotów, brak kolizji,
    widoczny przycisk, plecak i koszt złota także dla celu +10.
13. Zapis przez istniejącą aplikację i ponowny odczyt: identyfikator, źródło,
    liczba przedmiotów, statystyki, materiały i złoto po ulepszeniu.

Nie wykryto błędów parsera, brakujących zasobów ani niedziałających odwołań
do scen/skryptów. W środowisku występuje znany również przed zmianą komunikat
`Failed to read the root certificate store.`. Import edytora zgłasza ponadto
dwa obiekty `UndoRedo` przy zamykaniu — identyczny rodzaj ostrzeżenia znajduje
się w zapisanym logu importu sprzed zmiany. Nie traktujemy tych komunikatów jako
nowych usterek warsztatu. Narzędzie zachowuje je w logach i przepuszcza wyłącznie
dokładnie rozpoznany błąd magazynu certyfikatów, nie dowolne błędy Godota.

## Grafiki i ograniczenia

- Nie brakuje ilustracji dla obecnych wariantów bohaterów w katalogu.
  W razie brakującego wariantu używany jest neutralny stan istniejącego panelu,
  nie wymyślona postać.
- Kowadło i symbol złota są rysowane interfejsem; nie dodano wygenerowanych
  bitmap ani nowych modeli. Ikony wyposażenia i materiałów pochodzą z gry.
- Obecna logika obsługuje wiele poziomów jednocześnie, więc kontrolka docelowa
  korzysta z niej bez zmian. Dla niektórych słabszych przedmiotów zaokrąglenie
  powoduje brak zmiany statystyk przy pierwszym poziomie. Przykład na zrzucie:
  Lanca Kaprysu +0 → +1. UI pokazuje wtedy „Na tym poziomie statystyki pozostają
  bez zmian.” zamiast fikcyjnego przyrostu z makiety. Cel +10 pokazuje faktyczne
  Atak 5 → 10 (+5).
- Docelowe rozmiary sprawdzono z istniejącym skalowaniem płótna aplikacji.
  Plecak i wymagania mają własne przewijanie. Skrajnie małe samodzielne płótno
  ma dodatkowo bezpieczne przewijanie obszaru roboczego.
- Przed rozpoczęciem zadania Git zgłaszał niezwiązane pliki `.import`
  różniące się metadanymi/końcami linii, bez różnic w treści normalizowanej.
  Nie zostały dołączone do commita ani wycofane.

## Zrzuty i powtarzalność

Artefakty są lokalne i celowo nie są linkowane jako pliki repozytorium.
Nie zapisujemy automatycznie generowanych dowodów w `docs/`.

Katalogi wyjściowe:

```text
build/blacksmith-workbench-review/before/evidence/before_1920x1080.png
build/blacksmith-workbench-review/before/evidence/before_1366x768.png
build/blacksmith-workbench-review/after/evidence/empty_1920x1080.png
build/blacksmith-workbench-review/after/evidence/empty_1366x768.png
build/blacksmith-workbench-review/after/evidence/selected_1920x1080.png
build/blacksmith-workbench-review/after/evidence/selected_1366x768.png
build/blacksmith-workbench-review/after/evidence/target10_1920x1080.png
build/blacksmith-workbench-review/after/evidence/target10_1366x768.png
```

Zrzuty „before” wykonano na kodzie bazowym, przed podłączeniem nowego warsztatu.
To pełne ekrany aplikacji, nie wycinki ani przerysowana makieta. Zrzuty „after”
pokazują osobno pusty stan, wybór założonej broni oraz droższy cel +10.

Z katalogu repozytorium, przy zainstalowanych lokalnych narzędziach:

```powershell
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py after --tests
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py after --only-tests --test-script=res://tests/test_blacksmith_workbench.gd
```

Pierwsze polecenie importuje, uruchamia aplikację, wykonuje zrzuty oraz pełne
testy. Drugie uruchamia wyłącznie zestaw warsztatu. Argument `before` wybiera
katalog artefaktów, a nie wersję Git: odtworzenie historycznych zrzutów wymaga
kodu bazowego z samym narzędziem przechwytującym. Narzędzie nie przełącza gałęzi.
Logi importu, startu, renderera i GUT pozostają obok katalogu `evidence`.

## Wszystkie zmienione pliki (33)

Zmodyfikowane:

```text
godot/ui/screens/city_economy/city_economy.gd
godot/ui/screens/city_economy/city_economy.tscn
godot/ui/screens/city_economy/service_layout.gd
godot/tests/test_city_art_stage_nine_e.gd
godot/tests/test_city_economy_screen.gd
godot/tests/test_equipment_ui_stage_nine_b.gd
godot/tests/test_integrated_npc_hit_regions.gd
godot/tests/test_item_icon_golden_slice_stage_nine_c.gd
godot/tests/test_ui_readability_pass.gd
```

Dodane:

```text
docs/reviews/blacksmith-workbench/README.md
godot/tests/test_blacksmith_workbench.gd
godot/tests/test_blacksmith_workbench.gd.uid
godot/tools/capture_blacksmith_workbench.gd
godot/tools/capture_blacksmith_workbench.gd.uid
godot/ui/components/equipment_picker/equipment_picker.gd
godot/ui/components/equipment_picker/equipment_picker.gd.uid
godot/ui/components/equipment_picker/equipment_picker.tscn
godot/ui/components/required_resource_tile/required_resource_tile.gd
godot/ui/components/required_resource_tile/required_resource_tile.gd.uid
godot/ui/components/required_resource_tile/required_resource_tile.tscn
godot/ui/components/upgrade_anvil/upgrade_anvil.gd
godot/ui/components/upgrade_anvil/upgrade_anvil.gd.uid
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.gd
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.gd.uid
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.tscn
godot/ui/screens/blacksmith_workbench/upgrade_view.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.gd.uid
godot/ui/screens/blacksmith_workbench/upgrade_view.tscn
godot/ui/screens/blacksmith_workbench/upgrade_view_model.gd
godot/ui/screens/blacksmith_workbench/upgrade_view_model.gd.uid
godot/ui/screens/blacksmith_workbench/workbench_style.gd
godot/ui/screens/blacksmith_workbench/workbench_style.gd.uid
scripts/review_blacksmith_workbench.py
```

## Drugi recenzent

- Czy czytelność i wielkość postaci oraz widoczność Garrana są satysfakcjonujące
  na fizycznym ekranie 1366×768, nie tylko na zrzucie?
- Czy wybór kliknięciem/przeciąganiem jest wyraźnie odróżniony od potwierdzenia
  kosztownej operacji i czy „Odłóż” nie sugeruje zdejmowania wyposażenia?
- Sprawdzić +1, większy cel i +10, niedobory wielu materiałów, przewijanie oraz
  ciągłą widoczność złota i głównego przycisku.
- Sprawdzić wszystkie 11 pierwotnych slotów, filtry źródła, podpowiedzi blokad
  i ramki jakości na bardziej wypełnionym plecaku oraz innych klasach/płciach.
- Przejść „Usługi kowala”, X i Escape, a następnie ponownie otworzyć usługę.
- Wczytać istniejący zapis, ulepszyć własny przedmiot i ponownie wczytać:
  potwierdzić brak utraty/duplikacji oraz zachowanie tego samego wyposażenia.
