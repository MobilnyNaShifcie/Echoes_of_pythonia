# Kuźnia Garrana — przegląd warsztatu ulepszania

## Dopracowanie wizualne — 2026-09-19

Gałąź: `codex/blacksmith-visual-polish`. Baza:
`37f211e25941da9bb627f9e73bbd4fcda1481cb9` oraz ręczne zmiany właściciela
z gałęzi `manual/blacksmith-visual-polish`. Nie scalono do main, bez push.
Pełny hash jednego commita tej korekty podano w końcowej odpowiedzi.

### Zmiany

- Zachowane i wykorzystane własne grafiki kowadła oraz tła właściciela.
  Ich oryginały i dwa ręcznie zmienione pliki zachowano lokalnie w ignorowanym
  `build/blacksmith-workbench-review/manual-backup-20260919/`.
- Duże kowadło i pozioma Lanca Kaprysu w jednej przycinanej scenie.
  Tło nie wychodzi już w obszar etykiet. Punkt oparcia broni skaluje się
  razem z kowadłem; dolna część postumentu celowo wychodzi poza kadr.
- Nowa lanca tylko w prezentacji kuźni: bez podmiany ikony katalogowej,
  grafiki bohatera, definicji przedmiotu ani instancji. Pozostałe przedmioty
  zachowują własne ikony — nie otrzymały wymyślonych nowych ilustracji.
- Linia poziomów +0…+10 z podświetleniem obecnego/docelowego poziomu,
  wyborem kliknięciem i klawiaturą. Zachowane pomocnicze przyciski −/+.
  Wybór celu nadal jest wyłącznie podglądem; operację potwierdza główny przycisk.
- Złote nagłówki szeryfowe, narożniki, kompaktowe wymagania posiadane/potrzebne,
  wektorowa ikona złota i złoty przycisk. Źródło/Odłóż przeniesiono do górnej linii.
  Skrócono powtórzoną nazwę w porównaniu poziomów; pełne teksty są w podpowiedziach.
- Bez zmian CharacterEquipmentPanel, rozstawu 11 slotów, zakładek Założone/Plecak,
  mechanik, kosztów, statystyk i schematu zapisu. Przykładowe liczby z makiety
  nie zastępują prawdziwych danych UpgradeService.

### Dowody i odtworzenie

Automatyczne PNG i logi pozostają **wyłącznie lokalnie w build**, które Git ignoruje.
Nazwy poniżej są instrukcją odtworzenia, nie linkami do plików w repozytorium:

- Przed: `build/blacksmith-workbench-review/visual-before/evidence/`,
  obrazy empty/selected/target10/equipped/backpack w 1920×1080 i 1366×768.
  To rzeczywisty stan ręcznych zmian użytkownika przed tą korektą.
- Po: `build/blacksmith-workbench-review/visual-after/evidence/`,
  te same stany w 1920×1080, 1366×768 i 1280×720.
- Import/uruchomienie/zrzuty: `.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py visual-after`.
- Testy kuźni: ten sam skrypt z `--only-tests --test-script res://tests/test_blacksmith_workbench.gd`.
- Pełny GUT: ten sam skrypt z `--only-tests`.
- Zrzuty uruchamiają rzeczywistą scenę App w osobnym profilu i na danych fixture,
  bez odczytywania lub nadpisywania zapisu właściciela.

### Kontrola i ograniczenia

Testy kuźni: **19/19**. Obejmują także nową linię poziomów
(mysz/klawiatura), osobną teksturę lancy, niezmienność danych i geometrię
kompozycji w trzech rozdzielczościach i czytelność wielowierszowego porównania.
Pełna regresja Godota: **703/703**, 94 skrypty, 23 320 asercji, 143,592 s.
Import, boot oraz zrzuty OpenGL:
bez błędów parsera, brakujących zasobów i odwołań.
Godot zgłasza istniejący błąd środowiska Windows
`Failed to read the root certificate store.` również w przebiegu „przed”;
nie jest błędem sceny ani brakującym zasobem i nie został wyciszony w logach.

Ręcznie sprawdzono wybrany przedmiot w 1080p, pusty panel w 720p i brak
materiałów/złota przy celu +10 w 768p, a także wybrany przedmiot w 720p.
Formatowanie i lint 10 plików/skryptów tego zakresu: bez problemów.
`git diff --check` oraz kontrola staged: bez błędów.
Walidator 10 bazowych ikon przedmiotów przechodzi.

Drugi recenzent powinien sprawdzić zgodność skali/położenia lancy ze wzorem,
czytelność cyfr na fizycznym ekranie 720p, przewijanie wymagań +10 oraz normalne
ulepszenie z własnego zapisu. Pozostałe typy przedmiotów używają dawnych ikon,
a nie nowych grafik ułożonych specjalnie na kowadle. Nagłówki używają systemowej
Georgii z fallbackami Noto Serif/DejaVu Serif — na innym systemie krój może się różnić.
Nie użyto odpłatnych fontów ani nowych usług generowania.

Niezwiązane oznaczenia M przy plikach .import zastano przed zadaniem; nie są
częścią commita. Nieużywana kopia właściciela
`godot/ui/screens/blacksmith_workbench/forge_anvil_work_v2.png` i jej .import
pozostają lokalnie nietknięte, poza commitem. Ma ten sam SHA-256 co użyta kopia
w assets/ui/blacksmith; niczego nie usunięto.

### Pliki tej korekty

```text
docs/reviews/blacksmith-workbench/README.md
godot/assets/ASSET_MANIFEST.md
godot/assets/ui/blacksmith/caprice_lance_forge_v1.png
godot/assets/ui/blacksmith/caprice_lance_forge_v1.png.import
godot/assets/ui/blacksmith/forge_anvil_work_v2.png
godot/assets/ui/blacksmith/forge_anvil_work_v2.png.import
godot/assets/ui/blacksmith/forge_panel_backdrop_v1.png
godot/assets/ui/blacksmith/forge_panel_backdrop_v1.png.import
godot/assets/ui/blacksmith/gold_stack.svg
godot/assets/ui/blacksmith/gold_stack.svg.import
godot/tests/test_blacksmith_workbench.gd
godot/tools/capture_blacksmith_workbench.gd
godot/ui/components/required_resource_tile/required_resource_tile.gd
godot/ui/components/required_resource_tile/required_resource_tile.tscn
godot/ui/components/upgrade_anvil/forge_edge_fade.gdshader
godot/ui/components/upgrade_anvil/forge_edge_fade.gdshader.uid
godot/ui/components/upgrade_anvil/forge_item_presentation.gd
godot/ui/components/upgrade_anvil/forge_item_presentation.gd.uid
godot/ui/components/upgrade_anvil/upgrade_anvil.gd
godot/ui/components/upgrade_anvil/upgrade_level_rail.gd
godot/ui/components/upgrade_anvil/upgrade_level_rail.gd.uid
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.gd
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.tscn
godot/ui/screens/blacksmith_workbench/upgrade_view.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.tscn
godot/ui/screens/blacksmith_workbench/workbench_style.gd
scripts/review_blacksmith_workbench.py
```

## Historia — wcześniejsza przebudowa warsztatu

Gałąź: `codex/blacksmith-workbench-redesign`.
Baza: `dc73f3d928934999fd7054a458d29b4568664099`.
Raport dotyczy commita, w którym znajduje się ten plik; pełny hash jest podany
w odpowiedzi końcowej i dostępny przez `git rev-parse HEAD`.
Zmiana nie jest scalana do `main` ani wypychana automatycznie.

### Korekta punktu 7 — dwie zakładki źródła

Baza tej korekty: `8439a046e54f0ec0f469e3f9003dc68a00bc28ac`.
Usunięto kategorię „Wszystko” oraz wspólny widok postaci z małym paskiem
plecaka. Domyślne „Założone” pokazuje wyłącznie zaakceptowany panel postaci;
„Plecak” zastępuje go dużą siatką. Przyciski są równorzędne, aktywny ma złote
wypełnienie, a nieaktywny ciemne tło ze złotym obramowaniem. Przełączanie nie
zmienia wyboru na kowadle ani ustawionego poziomu docelowego.

Ta korekta zmienia tylko sześć plików:

```text
godot/ui/components/equipment_picker/equipment_picker.gd
godot/ui/components/equipment_picker/equipment_picker.tscn
godot/tests/test_blacksmith_workbench.gd
godot/tools/capture_blacksmith_workbench.gd
scripts/review_blacksmith_workbench.py
docs/reviews/blacksmith-workbench/README.md
```

Pliki wspólnego `CharacterEquipmentPanel`, `InventoryGridView`, głównego ekranu
ekwipunku, mechanik, definicji przedmiotów i grafik nie zostały zmodyfikowane.
Poniższa lista 33 plików opisuje całą przebudowę warsztatu względem `main`.

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
siatkę `InventoryGridView`. „Założone” jest aktywne po każdym otwarciu warsztatu:
pełna aktualna ilustracja bohatera i lanca pozostają odsłonięte, hełm jest nad
postacią, a po bokach jest po pięć istniejących slotów. Nie ma paska plecaka.
W trybie „Plecak” cała postać, tabliczka i wszystkie założone sloty są ukryte.
Plecak zajmuje ten sam duży obszar pod zakładkami. Ma nagłówek, aktualny udźwig
i liczbę zajętych miejsc: jedna instancja wyposażenia lub jeden stos to jedno
miejsce, bez zmiany modelu ekwipunku i bez sugerowania nowego limitu pojemności.

Siatka dobiera liczbę kolumn do szerokości panelu. Kwadratowe komórki mają
minimum 96 px na płótnie gry, zamiast wcześniejszych 60 px; liczba pustych
wierszy także dopasowuje się do wysokości. Nadmiar zawartości przewija się
pionowo wewnątrz panelu. Rezerwacja miejsca na pasek przewijania zapobiega
oscylacji liczby kolumn. Nieobsługiwane przedmioty pozostają przygaszone
z przyczyną blokady w podpowiedzi; ramki nadal pokazują jakość przedmiotów.
Przełączenie zakładki nie czyści kowadła, a udane ulepszenie odświeża dane
w obu widokach, również tym ukrytym. W poprzednim widoku kowala nie było
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
| Import projektu w edytorze headless, recovery mode | Kod wyjścia 0 |
| Uruchomienie właściwej sceny aplikacji | Kod wyjścia 0 |
| Zrzuty rzeczywistej aplikacji przez renderer | Kod wyjścia 0, oba rozmiary |
| Pełna regresja GUT | 699/699 testów, 94 skrypty, 23 143 asercje, 129,508 s |
| Zestaw warsztatu | 15/15 testów, 671 asercji; także w pełnej regresji |
| `gdformat --check` | 3 skrypty GDScript zmienione w korekcie, bez zmian |
| `gdlint` | Te same 3 skrypty, bez problemów |
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
9. Brak „Wszystko”, domyślne „Założone”, ukrywanie całej postaci/tabliczki/slotów
   w plecaku, brak małego paska, zachowanie grafiki, danych i wyboru/poziomu
   na kowadle przy zmianie zakładek oraz powrót do domyślnej zakładki po otwarciu.
10. Rzeczywiste zdarzenia myszy: kliknięcie slotu, przeciągnięcie ze slotu
    i plecaka na kowadło, anulowanie przeciągnięcia; bez automatycznego zakupu.
    Te zdarzenia są wykonywane w obu wymaganych rozdzielczościach.
11. Kliknięcie powrotu/X oraz Escape z aktywnym focusem kontrolki.
12. Geometrię w 1920×1080 i 1366×768: wszystkie 11 slotów, brak kolizji,
    widoczny przycisk, plecak i koszt złota także dla celu +10.
13. Zapis przez istniejącą aplikację i ponowny odczyt: identyfikator, źródło,
    liczba przedmiotów, statystyki, materiały i złoto po ulepszeniu.
14. Pełnowymiarowy plecak, większe kwadratowe komórki, automatyczną zmianę
    liczby kolumn przy zmianie szerokości 760 → 1100, licznik miejsc i pionowe
    przewijanie fixture z ponad 100 przedmiotami, bez mutowania danych.
15. Ulepszenie tej samej instancji podczas oglądania drugiego źródła:
    odświeżone nazwy z poziomem i ramki rzadkości obu widoków, niezmieniony
    instance ID, aktualna zakładka, liczba przedmiotów i założona broń.

Nie wykryto błędów parsera, brakujących zasobów ani niedziałających odwołań
do scen/skryptów. W środowisku występuje znany również przed zmianą komunikat
`Failed to read the root certificate store.`. Zwykły import edytora zgłaszał
również dwa obiekty `UndoRedo` przy zamykaniu (obecne już przed przebudową),
a podczas tej korekty próba sprawdzenia wersji dodatku GUT przez GitHub
zakończyła się błędem sieciowym. Dlatego narzędzie uruchamia sam import
w udokumentowanym trybie `--recovery-mode`, bez zbędnych dodatków edytora.
Uruchomienie gry, renderowanie i GUT odbywają się normalnie, poza tym trybem.
Końcowe logi nie zawierają błędów skryptów, brakujących zasobów ani ostrzeżeń
o orphan nodes. Pozostał tylko komunikat magazynu certyfikatów; narzędzie
przepuszcza wyłącznie ten dokładnie rozpoznany komunikat, nie dowolne błędy.

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

Korekta zakładek ma osobny, ignorowany katalog; nie nadpisuje wcześniejszych
zrzutów warsztatu:

```powershell
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py tabs-after --tests
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py tabs-after --only-tests --test-script=res://tests/test_blacksmith_workbench.gd
```

Aktualne pełne zrzuty obu zakładek:

```text
build/blacksmith-workbench-review/tabs-after/evidence/equipped_1920x1080.png
build/blacksmith-workbench-review/tabs-after/evidence/equipped_1366x768.png
build/blacksmith-workbench-review/tabs-after/evidence/backpack_1920x1080.png
build/blacksmith-workbench-review/tabs-after/evidence/backpack_1366x768.png
```

Zachowano również `empty_*`, `selected_*` i `target10_*` w tym samym katalogu.
Porównanie sprzed zmiany zakładek stanowią poprzednie `after/evidence/selected_*`:
zostały wyrenderowane dla commita bazowego korekty i pozostają nietknięte.
Katalog `tabs-before` zachowuje log nieudanej próby importu ze sprawdzaniem
aktualizacji GUT; nie zawiera nowej serii zrzutów. Końcowe poprawne logi i zrzuty
znajdują się w `tabs-after`.

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
- Potwierdzić, że po otwarciu są tylko dwie równe zakładki, „Założone” jest
  aktywne i nie ma paska plecaka, a „Plecak” całkowicie zastępuje postać.
- Wybrać broń, zmienić poziom docelowy, przełączyć zakładki i zatwierdzić
  ulepszenie: wybór i poziom nie powinny się zerować, broń nie może się zdjąć.
- Przejść „Usługi kowala”, X i Escape, a następnie ponownie otworzyć usługę.
- Wczytać istniejący zapis, ulepszyć własny przedmiot i ponownie wczytać:
  potwierdzić brak utraty/duplikacji oraz zachowanie tego samego wyposażenia.
