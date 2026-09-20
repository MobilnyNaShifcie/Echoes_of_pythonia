# Kuźnia Garrana — przegląd warsztatu ulepszania

## Widoczność wszystkich materiałów ulepszenia — 2026-09-19

Gałąź: `codex/forge-upgrade-materials`. Baza:
`cfc7e0f7f4aff32217aaf2583e4fef1f4b7a211e`.
Jeden commit, pełny hash w odpowiedzi końcowej. Bez scalania do main i bez push.
Ta korekta zastępuje wcześniejsze przewijanie materiałów w dolnym panelu.

### Przyczyna i zakres

`UpgradeService` oraz `upgrade_view_model.requirements()` już zwracały wszystkie
materiały. Problemem był `ResourceScroll` o wysokości 96 px: widoczny był tylko
pierwszy wiersz (osełka i złoto), a materiały wyższych progów wymagały przewinięcia.

- Koszt jest teraz w całości widoczny: siatka dobiera 2–4 kolumny tak, aby obecne
  receptury, maksymalnie siedem kafelków wraz ze złotem, zajmowały najwyżej dwa wiersze.
  Wysokość wynika z zawartości; nie ma ukrytych wierszy ani paska przewijania.
- Dla więcej niż dwóch wymagań kafelki i odstępy panelu są kompaktowe. Każdy
  zasób zachowuje ikonę, nazwę, posiadane/potrzebne oraz kolor dostępności.
  Dłuższa nazwa ma wielokropek; pełna nazwa i obie liczby są w podpowiedzi.
  Niskie progi zachowują duże kafelki osełki i złota.
- Kowadło, tło, położenie przedmiotu i prawy panel wyposażenia pozostają
  niezmienione. Dolna nakładka nie zakrywa nawet szerokiej lancy z trzema
  wierszami porównania statystyk. Nie dodano animacji ani dodatkowych komunikatów.
- Bez zmian receptur, kosztów, statystyk, definicji/ikon, transakcji i zapisów.
  Osełka słusznie pozostaje w kosztach skoku +0 → +10, lecz nie w samym +9 → +10.

Dla zgłoszonego Pancerza Zatopionego Zakonu +0 → +10 test potwierdza
4 osełki, 15 kamieni szlifierskich, 12 płyt zakonu, 3 zwykłe esencje,
5 serc Głuchej Wody oraz 5075 złota. To istniejąca receptura, nie zmiana balansu.
Sam krok +9 → +10 wymaga 4 kamieni szlifierskich i 2 serc, bez osełki.

### Testy i lokalne dowody

- Nowy zestaw: 4/4 testy, 12 794 asercje. Wszystkie pojedyncze kroki +0…+10
  i siedem profili mocy; zmiana celu w obie strony; zgodność ilości i ikon
  z kanonicznym planem; brak pominiętych/zdublowanych kafelków; widoczność całych
  kafelków i liczb bez przewijania w 1920×1080, 1366×768 i 1280×720.
- Niezmienność danych podczas podglądu, pozycji kowadła i szerokości panelu;
  brak przesłonięcia przedmiotu; blokada przy brakującym materiale bossa;
  udane ulepszenie tej samej instancji z pobraniem wszystkich kosztów;
  wyczyszczenie wymagań po osiągnięciu +10.
- Pełna regresja: **734/734**, 99 skryptów, 37 353 asercje, 178,691 s.
  Import, uruchomienie App i zrzuty OpenGL: kod 0. Brak błędów parsera,
  brakujących zasobów, uszkodzonych odwołań i ostrzeżeń skryptów.
  `gdformat --check`, `gdlint` (cztery skrypty) i `git diff --check`: poprawne.
  Obejrzano pancerz +0 → +10 i +9 → +10 w 768p, siedem zasobów w 720p,
  lancę w 1080p oraz trzywierszowe porównanie w 768p. Wszystkie wymagania
  są widoczne, a panel nie zakrywa przedmiotu.
- Generowane pliki pozostają wyłącznie w ignorowanym `build/`, poza Git.
  Przed: `build/blacksmith-workbench-review/materials-before/evidence/`.
  Po: `build/blacksmith-workbench-review/materials-after/evidence/`.
  W każdej serii 45 PNG, także `sunken_knight_armor_target10_*`,
  `sunken_knight_armor_9_to_10_*` oraz siedmioskładnikowy `sunken_order_cloak_target10_*`.
  Zrzuty pochodzą z rzeczywistej sceny App, na odizolowanym profilu fixture,
  bez odczytu lub nadpisywania zapisu użytkownika.
  Losowane affiksy fixture mogą różnić się między seriami; receptury i ich
  sumaryczne koszty pozostają identyczne.

Odtworzenie (etap wybiera katalog dowodów, nie przełącza wersji Git):

```powershell
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py materials-after --tests
.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py materials-after --only-tests --test-script=res://tests/test_blacksmith_materials.gd
```

### Zmienione pliki i druga recenzja

```text
docs/reviews/blacksmith-workbench/README.md
godot/tests/test_blacksmith_materials.gd
godot/tests/test_blacksmith_materials.gd.uid
godot/tools/capture_blacksmith_workbench.gd
godot/ui/components/required_resource_tile/required_resource_tile.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.tscn
scripts/review_blacksmith_workbench.py
```

Drugi recenzent: sprawdzić czytelność nazw/podpowiedzi na 720p i 768p,
pełny koszt pancerza przy +10, zmianę celu z +10 na +1 i z powrotem oraz
przeciąganie lancy bez kolizji z panelem. Więcej niż siedem zasobów w przyszłych
recepturach lub zmiana skalowania płótna wymaga ponownej kontroli geometrii.
W logach nadal występuje znany komunikat środowiska Windows
`Failed to read the root certificate store.`; nie jest błędem zasobów gry.
Niezwiązana lokalna kopia `forge_anvil_work_v2.png` z `.import` w katalogu
sceny kuźni pozostaje nietknięta i poza commitem.

## Stałe kowadło i nakładany panel — 2026-09-19

Gałąź: `codex/blacksmith-fixed-anvil-panel`. Baza:
`b0b0e69a81938eb4cc969a77be79a789510253b6`.
Jeden commit; pełny hash w odpowiedzi końcowej. Bez scalania do main i bez push.
Ta sekcja zastępuje opis zmiennej kompozycji z poprzedniej korekty.

### Zakres

- Ilustracja ma stałą scenę `Stage`, niezależną od widoczności kontrolek.
  Położenie i skala kowadła, tła oraz punktu oparcia zależą tylko od rozmiaru
  dostępnego obszaru, nigdy od wyboru, rodzaju przedmiotu lub poziomu ulepszenia.
- Kontrolki poziomu pojawiają się nad kowadłem; dolny panel nakłada się na jego
  podstawę. Nie zmniejsza ilustracji ani nie przesuwa blatu. Po odłożeniu rzeczy
  obie warstwy UI znikają, pozostawiając niezmieniony obraz.
- Nazwa i porównanie statystyk znajdują się obok siebie, aby również trzywierszowe
  porównanie nie zasłaniało lancy i jej wstęg. Długie nazwy nadal mają wielokropek
  i pełną podpowiedź. Materiały zachowują wewnętrzne przewijanie.
- Pusta część warstwy kontrolek przepuszcza zdarzenia myszy do kowadła; przyciski
  i dolny panel je obsługują. Przeciąganie/odkładanie i podświetlenia pozostają.
- **Bez animacji** zgodnie z ostatnią decyzją: panel pokazuje się i chowa
  natychmiast. Wysunięcie/zanikanie pozostaje osobnym, przyszłym etapem.
- Bez zmian grafik, postaci, 11 slotów, definicji przedmiotów, instance ID,
  kosztów, mechanik i zapisów. Bez usuwania wcześniejszych lokalnych plików.

### Dowody i testy

Generowane PNG oraz logi pozostają lokalnie, w ignorowanym `build/`.
Poniższe ścieżki są opisem lokalnych dowodów, nie linkami do plików w Git:

- Przed: `build/blacksmith-workbench-review/fixed-before/evidence/` — zachowane
  kopie końcowych 30 zrzutów z bazowego commita b0b0e69, bez nadpisania oryginałów.
- Po: `build/blacksmith-workbench-review/fixed-after/evidence/` — 33 PNG,
  stany empty/selected/target10/equipped/backpack/chest/boots/earrings/drag_return/
  returned/multi_stat, każdy w 1920×1080, 1366×768 i 1280×720.
- Odtworzenie: `.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py fixed-after --tests`.
  Rzeczywista scena App działa na osobnym profilu i danych fixture, bez korzystania
  z zapisu użytkownika. Multi_stat używa odłączonej definicji testowej.
- Nowe testy porównują dokładne prostokąty sceny, tła, kowadła i wszystkich slotów
  oraz punkt oparcia przed/po wyborze, zmianie przedmiotu, poziomu, zakładki
  i odłożeniu. Sprawdzają granice obróconej lancy, brak przykrycia przedmiotów
  przez panel, trzy statystyki, +10 i niezmienność danych gracza.
- Istniejące testy obsługi myszy, klawiatury, kosztów, anulowania, powrotu i zapisów
  pozostają częścią regresji; zmieniono jedynie odwołania do nowej hierarchii UI
  oraz oczekiwania dotyczące panelu, który teraz nakłada się na ilustrację.

Pełna regresja: **710/710**, 96 skryptów, 24 407 asercji, 169,813 s;
w tym wszystkie **26/26** testy kuźni. Import, boot i zrzuty OpenGL: kod 0,
bez błędów parsera, brakujących zasobów i niedziałających odwołań.
Formatowanie/lint sześciu skryptów zakresu oraz `git diff --check`: bez błędów.
Obejrzano puste i zajęte kowadło w 1080p, trzywierszowe porównanie w 768p,
buty oraz pusty panel w 720p. Kontrola potwierdza niezmienną pozycję blatu,
czytelne dane i brak przykrycia przedmiotów przez panel.

### Ograniczenia i druga recenzja

Do ręcznego sprawdzenia: brak ruchu blatu przy wyborze i odłożeniu, czytelność
kompaktowego porównania na 720p/768p, długie nazwy, przeciąganie przez wolny obszar
warstwy UI oraz normalne ulepszenie. Animacji jeszcze nie ma. Grafiki pozostałych
przedmiotów nadal są istniejącymi ikonami, a nie nowymi ilustracjami perspektywicznymi.
Znany komunikat środowiska Windows `Failed to read the root certificate store.`
pozostaje w logach. Niezwiązane oznaczenia M plików .import i kopia właściciela
`forge_anvil_work_v2.png` z .import są poza commitem i pozostają nietknięte.

### Zmienione pliki

```text
docs/reviews/blacksmith-workbench/README.md
godot/tests/fixtures/blacksmith_ui_test_base.gd
godot/tests/test_blacksmith_fixed_anvil.gd
godot/tests/test_blacksmith_fixed_anvil.gd.uid
godot/tests/test_blacksmith_workbench.gd
godot/tools/capture_blacksmith_workbench.gd
godot/ui/components/upgrade_anvil/upgrade_anvil.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.tscn
scripts/review_blacksmith_workbench.py
```

## Oczyszczenie ekranu i odkładanie przeciągnięciem — 2026-09-19

Gałąź: `codex/blacksmith-cleanup-drag-return`. Baza:
`7b3831cc13bd00c827c130abcd21f64b6e86a297`.
Jeden commit, którego pełny hash znajduje się w odpowiedzi końcowej.
Bez scalania do main i bez push. Poniższa sekcja zastępuje opis zachowania
kuźni z wcześniejszych sekcji historycznych.

### Zmiany i bezpieczeństwo danych

- Usunięte złoto/udźwig z nagłówka, podpis Garrana w dolnym lewym rogu,
  Źródło/Odłóż, nagłówek wymagań, powtarzane komunikaty o brakach i wyniku
  oraz zdanie o niezmienionych statystykach. Koszt pozostaje jeden raz,
  na kafelkach posiadane/potrzebne; rzeczywiste zmiany statystyk są widoczne.
  Brak środków zaznacza czerwony koszt i podpowiedź nieaktywnego przycisku.
- Puste kowadło wypełnia dostępny panel ilustracją kuźni. Nie ma powielonych
  instrukcji, pustej sekcji materiałów ani nieaktywnego przycisku na dole.
  Instrukcja przeciągania jest dostępna dopiero jako podpowiedź po najechaniu.
- Wybrany przedmiot znika wizualnie ze swojego slotu. Komórka jest zarezerwowana,
  więc pozostałe rzeczy w plecaku nie przeskakują. Nie jest to usunięcie ani
  zdjęcie przedmiotu w modelu gracza: pozostaje ta sama instancja i instance ID,
  statystyki, udźwig i dane zapisu nie zmieniają się od samego wyboru.
- Przeciągnięcie z kowadła do prawego panelu przywraca przedmiot dokładnie do
  pierwotnego miejsca, także po zmianie zakładki lub upuszczeniu na inny zajęty
  slot. To odłożenie, nie zamiana ani automatyczne założenie. Anulowanie przywraca
  obraz na kowadle. Podczas przeciągania widoczny jest tylko przenoszony obraz,
  ponad oboma panelami; nie dodatkowy kafelek. Ulepszanie jest wtedy zablokowane.
  Backspace na zaznaczonym kowadle umożliwia odłożenie klawiaturą.
- Zamknięcie kuźni czyści wyłącznie tymczasowy wybór prezentacji. Nie wymaga
  odtwarzania skasowanych rzeczy, dlatego także zapis po ulepszeniu zachowuje
  oryginalną instancję i źródło przedmiotu.
- Pozostałe grafiki mają dopasowanie proporcji i widocznych granic alfa w czasie
  wyświetlania. Zbroja, buty i biżuteria nie wychodzą ponad przycinany kadr.
  Nie edytowano plików graficznych ani katalogowych ikon. Lanca zachowuje osobną
  ilustrację kuźni; inne rzeczy nadal korzystają z istniejących ikon.
- Bez zmian wspólnego CharacterEquipmentPanel, jego 11 slotów, grafiki Arii,
  modelu ekwipunku, kosztów, mechanik ulepszeń i formatu zapisu. Bez animacji.

### Testy i dowody

Zrzuty PNG i logi są wyłącznie lokalnie, w ignorowanym `build/`.
Poniżej podano ścieżki do odtworzenia, nie linki do nieśledzonych plików w repo.

- Przed: `build/blacksmith-workbench-review/cleanup-before/evidence/`.
  Stany empty/selected/target10/equipped/backpack, trzy rozdzielczości.
- Po: `build/blacksmith-workbench-review/cleanup-after/evidence/`.
  Dodatkowo chest/boots/earrings, drag_return (przedmiot trzymany myszą)
  i returned. Razem 30 PNG w 1920×1080, 1366×768 i 1280×720.
- Odtworzenie importu, uruchomienia rzeczywistej sceny App, zrzutów oraz pełnej
  regresji: `.venv/Scripts/python.exe scripts/review_blacksmith_workbench.py cleanup-after --tests`.
  Osobny profil i fixture chronią zapis użytkownika.
- Testy skupione: `test_blacksmith_workbench.gd` (19) oraz
  `test_blacksmith_cleanup.gd` (5). Wspólne narzędzia testowe przeniesiono do
  `tests/fixtures/blacksmith_ui_test_base.gd`, bez wyłączenia starych testów.
- Sprawdzane są rzeczywiste zdarzenia myszy/klawiatury, anulowanie w obie strony,
  ukrywanie oryginalnego obrazu podczas przeciągania, zablokowanie ulepszenia
  trzymanego przedmiotu, odrzucanie obcych/starych danych przeciągania, powrót
  do innej zakładki, +10, ponowne otwarcie, pełna geometria wszystkich dostępnych
  ikon, identyczność danych i istniejący autosave/reload po ulepszeniu.

Pełna regresja: **708/708**, 95 skryptów, 23 621 asercji, 155,348 s.
W tym wszystkie **24/24** testy kuźni. Import, boot i zrzuty OpenGL kończą się
kodem 0, bez błędów parsera, brakujących zasobów ani odwołań do scen/skryptów.
Formatowanie i lint 13 skryptów zakresu oraz `git diff --check`: bez błędów.
Ręcznie obejrzano wybrany przedmiot i warstwę przeciągania w 1080p,
zbroję/kolczyki w 768p oraz buty i pusty panel w 720p. Potwierdzono, że przeciągana
lanca nie chowa się za postacią ani slotami, a podglądy nie są ucinane.

### Ograniczenia i drugi recenzent

Godot zgłasza istniejący również przed zmianą problem środowiska Windows:
`Failed to read the root certificate store.` Pozostaje w logach; nie dotyczy
parsera, zasobów ani scen kuźni. Stare, niezwiązane oznaczenia M plików .import
oraz nieśledzona kopia właściciela `forge_anvil_work_v2.png` z .import nie są
częścią zmiany; niczego nie usunięto i nie nadpisano.

Drugi recenzent powinien sprawdzić przeciąganie wybranej rzeczy z obu zakładek,
odłożenie na inny slot, anulowanie, wyjście z kuźni z zajętym kowadłem,
jedno ulepszenie i zapis na swoim profilu, czytelność czerwonych kosztów oraz
kompozycję pustego panelu i nietypowych ikon. Zbroja/biżuteria to wciąż istniejące
ikony w podglądzie, a nie nowe ilustracje perspektywiczne ułożone płasko na kowadle.

### Zmienione pliki

```text
docs/reviews/blacksmith-workbench/README.md
godot/tests/fixtures/blacksmith_ui_test_base.gd
godot/tests/fixtures/blacksmith_ui_test_base.gd.uid
godot/tests/test_blacksmith_cleanup.gd
godot/tests/test_blacksmith_cleanup.gd.uid
godot/tests/test_blacksmith_workbench.gd
godot/tools/capture_blacksmith_workbench.gd
godot/ui/components/equipment_picker/equipment_picker.gd
godot/ui/components/required_resource_tile/required_resource_tile.gd
godot/ui/components/required_resource_tile/required_resource_tile.tscn
godot/ui/components/upgrade_anvil/forge_item_presentation.gd
godot/ui/components/upgrade_anvil/upgrade_anvil.gd
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.gd
godot/ui/screens/blacksmith_workbench/blacksmith_workbench.tscn
godot/ui/screens/blacksmith_workbench/upgrade_view.gd
godot/ui/screens/blacksmith_workbench/upgrade_view.tscn
scripts/review_blacksmith_workbench.py
```

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
