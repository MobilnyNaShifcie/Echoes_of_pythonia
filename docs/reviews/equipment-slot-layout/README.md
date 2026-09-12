# Przegląd układu wyposażenia — 2026-09-13

Gałąź: `codex/equipment-slot-layout-redesign`.
Baza zrzutów „przed”: `8755b43dedfd4df0c8adc9bb18e5d1ec6af14679`.
Zmiany przygotowane jako jeden commit; bez scalania do `main` i bez pushowania.

## Zakres

Wydzielono prezentacyjny `CharacterEquipmentPanel` do osobnej sceny. `CenterContainer`
umieszcza hełm na osi panelu, `HBoxContainer` rozdziela dwie jednakowe kolumny i
centralną sylwetkę, a `VBoxContainer` porządkuje sloty. Jeden wspólny rozmiar i odstęp
zależą od wysokości panelu. Przy standardowym płótnie sloty mają 97 × 97 px.

| Lewa kolumna | Nad postacią | Prawa kolumna |
| --- | --- | --- |
| Broń (`weapon`) | Hełm (`head`) | Druga ręka (`off_hand`) |
| Zbroja (`chest`) | | Kolczyki (`earrings`) |
| Rękawice (`hands`) | | Naszyjnik (`necklace`) |
| Pas (`belt`) | | Bransoleta (`bracelet`) |
| Buty (`feet`) | | Pierścień (`ring`) |

Ikony zachowują proporcje, mają osobne pasmo podpisu; puste sloty nadal wyświetlają
`◇`, a rzadkość jest nakładana dotychczasowym mechanizmem na obramowanie. Mała
tabliczka pod postacią pobiera nazwę, poziom i klasę z aktualnego gracza.

Końcowa poprawka ogranicza szerokość tabliczki do środkowej części panelu.
`Label` nie przekazuje naturalnej szerokości długiego tekstu do kontenerów;
nadmiar jest prezentowany z wielokropkiem, a pełna treść pozostaje w podpowiedzi.
Po zmianie tekstu i przy zmianie rozmiaru panelu ograniczenie jest przeliczane.
Stopka `Control` izoluje minimum tabliczki od minimum całego panelu, więc długi
tekst nie blokuje późniejszego zwężenia wcześniej szerokiego okna.
Nie zmieniono zaakceptowanego rozmieszczenia, rozmiarów ani mapowania slotów.

Kontroler ekwipunku zachowuje dotychczasową logikę interakcji, model wyposażenia i
identyfikatory. Komponent nie zapisuje danych i nie duplikuje mechanik. Jest gotowy
do ponownego użycia, ale w tej zmianie **nie podłączano go do Kuźni Garrana**.
Nie zmieniano sekcji statystyk, plecaka, balansu ani grafik źródłowych. Oryginalny
`pierrot.png` ma przed i po ten sam Git blob `792285bdbcc9f2f52b2f1fdf6c5be11904721439`.
Zachowano pełny kadr postaci i lancy, zoom 1.0 oraz brak obcinania dołu sylwetki.

## Testy i wyniki

- Godot 4.7.1: import edytora, uruchomienie właściwej sceny startowej oraz renderowanie
  rzeczywistego ekranu ekwipunku w aplikacji — kod wyjścia 0. Bez błędów parsera,
  brakujących zasobów i uszkodzonych odwołań scen/skryptów.
- Końcowe pełne GUT po poprawkach: **684/684**, 93 skrypty, 22 464 asercje, 114.463 s.
- Dodano łącznie 8 testów: geometria i brak nakładania na sylwetkę; poprawne ikony/podpisy/
  ramki; dynamiczne dane i niezmieniony stan gracza; zamiana/zdejmowanie biżuterii
  i aktualizacja statystyk; podwójny klik i tooltip; serializacja/deserializacja
  11 slotów wraz z ID instancji; rzeczywiste zdarzenia kursora i drag/drop.
- Nowy test długiego polskiego imienia i długiej etykiety klasy sprawdza cztery
  szerokości panelu (w tym 1800 px), niezmienione minimum i granice panelu,
  centrowanie tabliczki w środkowej części, widoczny tryb wielokropka oraz pełny
  tekst w podpowiedzi. Porównuje prostokąty obu kolumn i wszystkich slotów,
  cały serializowany stan gracza, zwężenie panelu do 730 px przy długim tekście
  i powrót do krótkiej tabliczki. Nie dodaje nowej klasy ani nie zmienia katalogu.
- Test kursora trafia we wszystkie 11 przycisków, przeciąga kolczyki do plecaka
  i z powrotem do slotu oraz sprawdza, że bransoleta nie została zmieniona.
- Test zapisu używa istniejącego serializatora i deserializatora, bez zmiany schematu.
  Pełny zestaw GUT obejmuje też istniejące testy zapisu/odczytu plików i migracji.
- Python z poprzedniego etapu: **660 testów i 8 podtestów — PASS**, 153.52 s.
- `scripts/check.ps1 -Focused` z poprzedniego etapu: PASS — zasoby przedmiotów (10), kart umiejętności
  (26), miasta (16 z alfą i 11 teł), formatowanie 315 plików GDScript, lint.
- Końcowy lint i formatowanie komponentu, jego testów i skryptu przechwytywania: PASS.
- `git diff --check`: PASS.
- Zrzuty przed/po: **1920 × 1080, 1600 × 900, 1366 × 768**; odrębne detale
  wyposażonych kolczyków i bransolety. Układ zweryfikowano wizualnie i testami
  geometrii; sloty, sylwetka i podpis pozostają w granicach panelu.

## Dowody wizualne

Zrzuty wykonuje prawdziwa scena aplikacji przez renderer OpenGL w SubViewport,
ze skalowaniem płótna zgodnym z projektem. Kadry panelu i biżuterii są wycięte z
tych zrzutów, nie są makietami. Nie czytano ani nie nadpisywano zapisu użytkownika.
Fixture ma stały zestaw przedmiotów, ale używa normalnego losowania affiksów,
więc wartości statystyk pomiędzy niezależnymi uruchomieniami mogą się różnić.
To nie jest zmiana balansu; testy porównują stan tej samej sesji przed i po obsłudze UI.

PNG i `layout.json` nie są częścią commita. Wszystkie 18 wcześniejszych plików
skopiowano lokalnie i zweryfikowano sumami SHA-256 przed usunięciem ich z indeksu
Git. Lokalizacje względem katalogu głównego repozytorium:

```text
build/equipment-layout-review/before/evidence/    # stan przed przebudową
build/equipment-layout-review/accepted/evidence/  # zaakceptowany stan d9fe04d
build/equipment-layout-review/after/evidence/     # aktualny wynik narzędzia
```

Zestaw obejmuje `equipment_<rozdzielczość>.png`, `panel_<rozdzielczość>.png`,
`earrings.png`, `bracelet.png` oraz `layout.json`. Aktualny capture dodatkowo
tworzy `nameplate_long_<rozdzielczość>.png`, pokazujące wielokropek dla długiego
tekstu, bez modyfikowania danych sesji.

Nie umieszczamy w raporcie linków do tych generowanych plików: nie istnieją one
w świeżym checkoutcie, a `build/` jest ignorowany i nie ma śledzonych plików.
Przed kolejnym uruchomieniem można zachować starszy wynik w osobnym katalogu
wewnątrz `build/`. Katalog `accepted/evidence/` to lokalne archiwum — runner go
nie nadpisuje. Porównanie `layout.json` potwierdza niezmienione granice panelu,
pozycje wszystkich slotów, kadr postaci i źródła grafik w trzech rozdzielczościach.

## Powtórzenie kontroli

W katalogu głównym repozytorium, z zainstalowanymi lokalnymi narzędziami:

```powershell
.venv/Scripts/python.exe scripts/review_equipment_layout.py after --tests
./scripts/check.ps1 -Focused
```

Runner izoluje profil Godota i zapisy w `build/equipment-layout-review/`, zapisuje
pełne logi `after/import.log`, `after/boot.log`, `after/capture.log`, `after/gut.log`
oraz odświeża dowody `after/evidence/`. Nie generuje plików w `docs/`.
Argument `before` to nazwa katalogu wyjścia, nie
przełączenie wersji kodu: zapisane zrzuty „przed” wykonano rzeczywiście przed
zmianą UI. Nie uruchamiać ponownie `before` na nowym kodzie jako porównania bazy.

## Problemy i ryzyka

- Windows/Godot zgłasza `Failed to read the root certificate store.` w obu wersjach,
  a import edytora dodatkowo ostrzega o dwóch obiektach `UndoRedo` przy zamknięciu.
  Logów nie uznano za całkowicie pozbawione diagnostyki: komunikaty są zachowane,
  a runner toleruje tylko ten konkretny błąd środowiskowego magazynu certyfikatów.
  Inne `ERROR:` i niezerowy kod zakończenia przerywają kontrolę.
- Długi prawy nagłówek celowo zawija się do dwóch wierszy; obie kolumny rezerwują
  tę samą wysokość nagłówka. Rozdzielczości niższe niż 1366 × 768 nie były kryterium.
- Istniejący model nie ma osobnej blokady broni dwuręcznej: lanca Pierrota i kości
  nadal współistnieją. Nie dodano ani nie zmieniono tej mechaniki.
- Przyszłe użycie w kuźni wymaga podpięcia istniejącej obsługi interakcji przez
  gospodarza komponentu; nie jest to częścią obecnego zadania.

## Drugi recenzent

- Porównać z referencją: 11 równych slotów, hełm nad włosami, dwie kolumny po pięć,
  czytelne etykiety i kompletna lanca bez zasłaniania przez UI.
- Na własnym zapisie sprawdzić zamianę kolczyków, bransoletę i naszyjnik osobno,
  drag/drop w obie strony, podwójny klik, zdejmowanie, tooltip i aktualizację statystyk.
- Zapisać i wczytać wyposażenie; porównać ID instancji oraz rzadkość przedmiotów.
- Sprawdzić wielokropek i pełną podpowiedź przy długim imieniu/nazwie klasy;
  szerokość panelu i położenie slotów nie mogą się zmieniać.
- Sprawdzić inne klasy/płcie oraz docelowe skalowanie systemowe monitora.
- Potwierdzić brak zmian w danych/core, ikonach źródłowych i regułach ekwipunku;
  zaakceptować wizualnie dwuwierszowy nagłówek na mniejszej rozdzielczości.

## Wszystkie zmienione/dodane pliki względem bazy (14)

Kod, testy i narzędzia:

- `godot/ui/screens/equipment/equipment.gd`
- `godot/ui/screens/equipment/equipment.tscn`
- `godot/ui/components/character_equipment_panel/character_equipment_panel.gd`
- `godot/ui/components/character_equipment_panel/character_equipment_panel.gd.uid`
- `godot/ui/components/character_equipment_panel/character_equipment_panel.tscn`
- `godot/tests/test_equipment_ui_stage_nine_b.gd`
- `godot/tests/test_character_equipment_panel.gd`
- `godot/tests/test_character_equipment_panel.gd.uid`
- `godot/tests/fixtures/equipment_layout_fixture.gd`
- `godot/tests/fixtures/equipment_layout_fixture.gd.uid`
- `godot/tools/capture_equipment_layout.gd`
- `godot/tools/capture_equipment_layout.gd.uid`
- `scripts/review_equipment_layout.py`
- `docs/reviews/equipment-slot-layout/README.md`
