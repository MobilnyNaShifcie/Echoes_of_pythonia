# Walka 1B — dźwięki i wyciszenie

Gałąź: `codex/combat-audio-feedback`.
Baza: `2f97c0d2619393b243ff6e2ce84b3cb69ed3675c`.
Bez merge/push. Kontynuacja przyjętych reakcji; bez przebudowy sztandaru zwycięstwa.

## Zakres

- Trafienie, krytyk, blok i unik grają na istniejącym impact; Pchnięcie Losu
  zachowuje dźwięk każdego faktycznego uderzenia. Brak audio dla krwawienia/aura/odbicia.
- Ograniczone animacje: pojedynczy priorytetowy sygnał na turę (krytyk, blok,
  unik, trafienie), bez oczekiwania na audio. Nowa tura zatrzymuje poprzednie ogony.
- Zwycięstwo: jeden krótki odgłos monet. Odświeżenie/ponowne włączenie dźwięku
  nie odtwarza wyniku. Porażka i odwrót nie dostają dźwięku zwycięstwa.
- `Dźwięk: wł./wył.` w nagłówku walki, dostępny także przy zablokowanych akcjach
  i klawiaturą. Wyłączenie natychmiast zatrzymuje głosy; zapamiętywane w osobnym
  `user://combat_audio.cfg`. Nie zmienia danych gracza ani globalnego Master volume.
- Dwa głosy o ograniczonej głośności, krótkie próbki bez pętli, bez RNG.
  Usunięcie ekranu usuwa odtwarzacze. Brak globalnego autoload/busa/frameworka.

Nie zmieniono mechanik, domeny, schematu zapisu, treści, wyniku/nagród ani grafik.
Nie kupowano niczego, nie dodawano zależności, muzyki ani systemu generowania audio.
Próbki są oryginalnymi plikami Kenney CC0. Źródła, licencje i hashe:
`godot/assets/ASSET_MANIFEST.md`.

## Pliki zmiany

- `godot/ui/presentation/combat_audio_feedback.gd` + `.uid` — audio i preferencja.
- `godot/ui/presentation/combat_presentation_controller.gd` — synchronizacja.
- `godot/ui/screens/combat/combat.gd` — przekazanie rozstrzygniętego wyniku.
- `godot/ui/screens/combat/combat.tscn` — przełącznik dźwięku.
- `godot/assets/audio/combat/` — pięć OGG, pięć importów, dwie oryginalne licencje.
- `godot/tests/test_combat_audio_feedback.gd` + `.uid` — skupione regresje.
- `godot/tools/render_combat_audio_preview.gd` + `.uid` — offline miks silnika.
- `scripts/review_combat_presentation.py` — izolowany przegląd audio i analiza PCM.
- `AI_CONTEXT/UI_RULES.md`, `docs/UI_REFRESH_PLAN_20260907.md`, `CHANGELOG.md`,
  `godot/assets/ASSET_MANIFEST.md`, niniejszy raport — kontrakt i dowody.

## Reprodukcja

```powershell
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-audio-review --only-tests --test-script res://tests/test_combat_audio_feedback.gd
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-audio-review --capture-script render_combat_feedback_preview.gd
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-audio-review --only-audio
./scripts/check.ps1
git diff --check
```

Audio wymaga wcześniejszego importu, wykonywanego w drugim poleceniu. Przegląd
izoluje profile pod `build/`; nie używa prawdziwych zapisów. Zrzuty to realny App
i renderer OpenGL Godota, raporty wizualne są syntetyczne. Test zgodności porównuje
prawdziwe tury, zapisane dane i RNG na identycznych kopiach sesji czterech klas.

Offline Movie Maker używa tego samego produkcyjnego odtwarzacza i gainów. WAV:
trafienie od 1 s, krytyk od 4 s, blok od 7 s, unik od 10 s, monety od 13 s,
wyciszona próba od 16 s. Skrypt sprawdza niezerowy sygnał każdej próbki, zapas
przed clippingiem i ciszę po wyciszeniu. To kontrola techniczna, nie ocena brzmienia.

## Dowody lokalne, ignorowane przez Git

- `build/combat-audio-review/before/evidence/` — PNG stanu bazowego.
- `build/combat-audio-review/after/evidence/` — PNG po dodaniu przełącznika.
- Rozdzielczości: 1280×720, 1366×768, 1920×1080, 2560×1080.
- `build/combat-audio-review/after/evidence/audio/combat-audio.wav` — odsłuch.
- W tym samym katalogu `.json` z analizą PCM oraz klatki offline Movie Maker.
- Logi import/boot/capture/GUT/audio w `build/combat-audio-review/after/`.
- Pełna walidacja: `build/combat-audio-review/validation.log`.

## Wyniki

Wyniki końcowe (2026-09-19):

- PASS: cały `scripts/check.ps1`: 783/783 GUT, 39 461 asercji, 104 skrypty.
- PASS: 660 testów Python + 8 podtestów.
- PASS: 12/12 testów skupionych, 146 asercji; bez osieroconych węzłów.
- PASS: gdformat 346 plików i gdlint; osobno formatter/linter narzędzia audio.
- PASS: 10 ikon, 26 kart, 16 grafik z alfą i 11 teł miasta w istniejących gate'ach.
- PASS: import, start projektu i renderowanie w Godot 4.7.1; bez błędów parsera,
  brakujących zasobów i niedziałających odwołań. Tylko znany komunikat certyfikatów.
- PASS: 120 PNG walki przed/po, po 60 na zestaw; kontrola wizualna nagłówka
  w 1280×720, 1366×768, 1920×1080 i 2560×1080, bez nakładania kontrolek.
- PASS: rzeczywisty miks offline: stereo 48 kHz, PCM 32-bit, 19,05 s;
  pięć słyszalnych technicznie sygnałów, peak 0,22466 (około -12,97 dBFS),
  RMS wyciszonego odcinka dokładnie 0. Nie zastępuje odsłuchu przez człowieka.
- PASS: `git diff --check` i `git diff --cached --check`. Brak zmian `core`,
  danych i `project.godot`; brak wygenerowanych dowodów w indeksie Git.

W początkowym nowym teście poprawiono typ pustej tablicy GDScript; końcowy
zestaw i pełna regresja przechodzą. Treść licencji zachowano, normalizując tylko
końce linii i końcowe białe znaki; próbki OGG pozostały byte-identical z paczkami.

## Ryzyka i drugi recenzent

- Odsłuchać pięć próbek i realną walkę na głośnikach/słuchawkach. Jakość artystyczna
  i preferowany poziom głośności wymagają oceny właściciela; automat tego nie ustala.
- Sprawdzić trafienie/krytyk/blok/unik obu stron, Pchnięcie Losu i szybkie tury,
  bez spóźnienia, duplikowania ani dźwięku pasywnych obrażeń.
- Sprawdzić wyciszenie podczas animacji, po ponownym uruchomieniu i wejściu w
  następną walkę. Zapisy postaci i nagrody mają pozostać identyczne.
- Ocenić nowy przycisk/fokus w 720p i Full HD; wynik zachowuje zaakceptowaną
  kompozycję bez nowego nagłówka. Próbki nie zastępują przyszłego audio klas/skilli.
- Znany komunikat Windows: `Failed to read the root certificate store.` —
  istniejący problem środowiska, nie błąd parsera lub zasobów.
- Zastane różnice EOL w `.import` i niezwiązana grafika kowadła pozostają poza commitem.
