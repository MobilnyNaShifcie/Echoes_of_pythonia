# Spójność rozgrywki — etap 1A: walka i wynik

Gałąź: `codex/combat-presentation-stage-one`.
Baza: `d53ca6838651396928a12b59ebbf76ab594bad8a` (zawiera zaakceptowaną księgę Mireli).
Plan etapów zapisany w istniejącym `docs/UI_REFRESH_PLAN_20260907.md`.
Nie scalano do main i nie wykonywano pushu.

## Zakres

- Lokalny styl walki oparty na wspólnym InterfaceStyle i kontrakcie UI_RULES:
  ciemny granat, spokojne złoto, czytelniejsze nagłówki, jednakowe stany przycisków.
  Brak globalnej zmiany stylu pozostałych ekranów.
- Grubsze paski PŻ, pełna nazwa gracza w podpowiedzi, wielokropek w nagłówku,
  ukrycie pustego „STATUS: —”. Aktywne efekty, pogoda, elity i bossowie pozostają.
- HUD zajmuje wysokość potrzebną treści, lecz przestrzeń aktorów rezerwuje miejsce
  na statusy: postacie nie przeskakują po wyświetleniu efektu/wyniku.
- Miękki cień pod istniejącymi ilustracjami; domyślnie wyłączony w komponencie,
  włączony tylko przez ekran walki. Bez edycji obrazów, kadrowania lub orientacji.
  Dopasowanie ma zabezpieczenie przed ujemnym odchyleniem float przy krawędzi ramy.
- Osobny nagłówek wyniku i stale dostępne Kontynuuj; raport ma własne przewijanie.
  Ikony łupu 72 px zamiast 44 px, osobne pionowe przewijanie wielu łupów.
- Nazwa atrybutu Pierrota w panelu komend: Szczęście, zgodnie z Project Bible.
- Zachowano istniejący drawer, akcje, karty, Splot, mikstury, blokady wejścia podczas
  animacji i prezentację rzeczywistych końcowych zasobów po porażce.

Nie zmieniono core, kosztów, obrażeń, nagród, RNG, zapisów, klas ani przedmiotów.
Nie dodano nowych grafik, zakupów, muzyki lub dźwięków. **To część 1A, nie ukończenie
całego etapu walki.** Część 1B to dalsza praca nad reakcjami, tempem i audio po
ocenie kierunku. Kompozycja dużej talii i widowiskowość umiejętności wymagają
dalszej oceny w ruchu, nie są uznane za finalną oprawę gry.

## Powtarzalna weryfikacja

Z katalogu repozytorium:

```powershell
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --tests
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --only-tests --test-script=res://tests/test_combat_presentation_stage_one.gd
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --only-capture
./scripts/check.ps1
```

Runner ma odizolowane profile w build, testowe sesje w pamięci i zastępczy zapis.
Nie otwiera zapisu właściciela. Import/boot/capture/GUT logowane osobno.
Podgląd renderuje rzeczywistą scenę App: poszukiwacz, cztery klasy, otwarte komendy,
Splot, ostatnie karty łowcy, zwycięstwo, porażka, długi raport i nadmiar łupów.
Ten ostatni jest jawnym fixture prezentacji, a nie zmianą prawdziwych nagród.
Podglądy: 1920×1080, 1366×768, 1280×720 i 2560×1080.

Nowe testy obejmują statusy, stabilność pozycji aktorów, rozmiar wyniku,
przewijanie łupów/raportu, pełne polskie imię, reset nowej walki, geometrię stanów
przycisku i niezmienność serializowalnego stanu po odświeżaniu wyniku.
Istniejący test ikon zmienia oczekiwane 44 na 72 px jako jawny kontrakt części 1A;
nadal sprawdza brak wymuszonego minimum oraz containment slotu.

### Wyniki końcowe

- PASS: walidatory istniejących assetów (10 ikon, 26 kart, 16 wyciętych obiektów
  miasta oraz 11 nieprzezroczystych teł).
- PASS: gdformat (338 plików) i gdlint; po końcowych korektach ponowiono oba
  narzędzia dla zmienionych plików, w tym narzędzia renderującego.
- PASS: Python — 660 testów i 8 podtestów, 151,80 s.
- PASS: końcowy import, uruchomienie bootstrapu, render rzeczywistej App oraz
  cały GUT — **753/753**, 38 828 asercji, 101 skryptów, 217,169 s.
- PASS: `git diff --check`; wygenerowane dowody są ignorowane, `git ls-files build`
  nie zwraca śledzonych plików.
- Obejrzano rzeczywiste rendery walki, otwartych komend, Splotu, zwycięstwa,
  porażki i przepełnienia raportu. Zapisano 52 zrzuty przed i 60 po.

Pierwszy przebieg `scripts/check.ps1` zakończył się wynikiem 751/753 GUT.
Ujawnił utratę dotychczasowego minimum 56 px przycisku Kontynuuj oraz odchylenie
float 0,00003 px nad ramą łowczyni. Poprawiono kod, nie obniżano tych wymagań.
Końcowy runner ponowił pełny GUT i rozruch z wynikiem PASS. Python i walidatory
assetów pozostały bez zmian po swoim udanym przebiegu. Nie oznaczamy pierwszego
wywołania `check.ps1` jako udanego.

Brak błędów parsera, ładowania scen/skryptów i brakujących zasobów w końcowych
logach. Jedyny komunikat ERROR to istniejący problem środowiska Windows:
`Failed to read the root certificate store.` Nie blokuje lokalnego renderowania
ani testów; nie jest ukrywany w logach. Nie wykonywano testu sieci/HTTPS.

## Lokalne dowody — poza Git

- Przed: `build/combat-presentation-review/before/evidence/`.
- Po: `build/combat-presentation-review/after/evidence/`.
- Przykłady: `pierrot_actions_1920x1080.png`, `victory_1280x720.png`,
  `mage_weave_1366x768.png`, `result_overflow_1280x720.png`, `defeat_1920x1080.png`.
- Log pierwszej walidacji: `build/combat-presentation-review/full-validation.log`.
- Końcowe logi: `build/combat-presentation-review/after/{import,boot,capture,gut}.log`.

Są to lokalne ścieżki, nie linki do nieistniejących załączników Git.
Zrzuty „przed” dokumentują bazową wersję sceny. Ich odtworzenie wymaga bazy.

## Ryzyka i drugi recenzent

- Ocenić serif nagłówków i czytelność 720p na fizycznym ekranie. SystemFont ma
  istniejący zestaw fallbacków Georgia / Noto Serif / DejaVu Serif.
- Sprawdzić walkę każdą klasą, Splot i ostatnie karty łowcy, fokus oraz myszy.
- Ocenić cienie pod postaciami unoszącymi się nad ziemią i proporcje różnych bestii.
- Sprawdzić pełne/ograniczone animacje, statusy, zero PŻ po porażce, Kontynuuj,
  raporty z wieloma zadaniami, łupami i osiągnięciami.
- Ekran wyniku jest nakładką na scenę; nie przesuwa i nie skaluje jej postaci.
- Zastane nieśledzone pliki kowadła zachowano; nie są częścią zadania.
  Zastane `.import` oznaczane przez Git z powodu normalizacji EOL nie są dodawane.

## Pliki zmiany

- `docs/UI_REFRESH_PLAN_20260907.md`
- `docs/reviews/combat-presentation-stage-one/README.md`
- `godot/ui/screens/combat/combat.gd`
- `godot/ui/screens/combat/combat.tscn`
- `godot/ui/screens/combat/combat_command_layout.gd`
- `godot/ui/screens/combat/combat_visual_style.gd` oraz `.uid`
- `godot/ui/components/combatant_visual/combatant_visual.gd`
- `godot/tests/test_combat_presentation_stage_one.gd` oraz `.uid`
- `godot/tests/test_ui_readability_pass.gd`
- `godot/tools/render_combat_hud_preview.gd`
- `scripts/review_combat_presentation.py`
