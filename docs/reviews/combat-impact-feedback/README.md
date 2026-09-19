# Walka 1B — moment trafienia i czytelne reakcje

Gałąź: `codex/combat-impact-feedback`.
Baza: `1ae376b7abf62cfa4284e45c4d3e0cb5479f0ca5`.
Kontynuacja zaakceptowanego etapu 1A, bez merge/push do main.

## Zmiany

- Lekki ruch atakującego i odrzut trafionego wokół stóp, bez przesuwania układu.
- Krytyk: mocniejszy odrzut, większy złoty tekst i lokalne iskry. Unik: odchylenie
  od atakującego i krótkie smugi. Blok: mała reakcja i łuk w kolorze tarczy.
- Obrażenia oraz widoczne PŻ zmieniają się w tym samym momencie trafienia;
  częściowy blok nie czeka już na końcowe odświeżenie zasobów.
- Krwawienie, aura i odbicie nie udają kolejnego ataku. Pchnięcie Losu zachowuje
  własny efekt i rzeczywiste obrażenia każdego uderzenia.
- Większe liczby przy sylwetce, poza HUD-em; do trzech reakcji na postać,
  z pełną historią w dzienniku. Brak przechwytywania myszy przez efekty.
- Ograniczone animacje pokazują nieruchome komunikaty bez błysków/ruchu;
  usuwane po krótkim czasie, przed następną turą i wynikiem.
- Zakończenie/anulowanie/usunięcie efektu przywraca oba oryginalne obroty i pivoty.

Nie zmieniono `core`, danych, mechanik, RNG, zasobów gracza, schematu zapisu,
wyniku/nagród ani zatwierdzonej kompozycji zwycięstwa. Nie dodano bitmap, dźwięków,
zależności ani nowych mechanik. To lokalna reakcja istniejących ilustracji,
nie animacja szkieletowa postaci ani komplet animacji wszystkich umiejętności.

## Pliki

- `godot/ui/presentation/combat_hit_effect.gd` + `.uid` — lokalna reakcja i impact.
- `godot/ui/presentation/combat_feedback_text.gd` + `.uid` — czytelne krótkie komunikaty.
- `godot/ui/presentation/combat_presentation_controller.gd` — odtwarzanie, PŻ i cleanup.
- `godot/ui/presentation/combat_presentation_plan.gd` — prawdziwy ubytek przy bloku,
  jawne oznaczenie ataku bez rozpoznawania go po przetłumaczonym tekście.
- `godot/tests/test_combat_impact_feedback.gd` + `.uid` — skupione regresje.
- `godot/tools/render_combat_feedback_preview.gd` + `.uid` — reprodukowalne podglądy.
- `scripts/review_combat_presentation.py` — wybór zestawu i katalogu dowodów.
- `AI_CONTEXT/UI_RULES.md`, `docs/UI_REFRESH_PLAN_20260907.md`, `CHANGELOG.md`,
  niniejszy raport — kontrakt, etap i przegląd audio.

## Testy i reprodukcja

```powershell
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-impact-review --only-tests --test-script res://tests/test_combat_impact_feedback.gd
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-impact-review --capture-script render_combat_feedback_preview.gd
./scripts/check.ps1
git diff --check
```

Runner izoluje profile w ignorowanym `build/`. Podglądy uruchamiają prawdziwy App
i Combat, z syntetycznymi raportami prezentacji oraz zapisem wyłącznie w pamięci.
Testy zgodności trybów używają prawdziwych, deterministycznych tur silnika i kopii
tej samej sesji (łącznie z identycznymi instance ID i pogodą), bez zapisu na dysk.

Wyniki końcowe (2026-09-19):

- PASS: cały `scripts/check.ps1`: 771/771 GUT, 39 315 asercji, 103 skrypty.
- PASS: 660 testów Python + 8 podtestów.
- PASS: testy skupione 9/9, 327 asercji; bez osieroconych węzłów.
- PASS: gdformat 344 plików, gdlint, osobna kontrola narzędzia renderującego;
  walidatory 10 ikon, 26 kart, 16 grafik z alfą i 11 teł miasta.
- PASS: import, start projektu i renderery Godota 4.7.1; bez błędów parsera,
  brakujących zasobów i niedziałających odwołań.
- PASS: `git diff --check` oraz `git diff --cached --check`; żaden plik `core`,
  danych, bitmap lub wygenerowanych dowodów nie wchodzi do zmiany.
- Sprawdzono wizualnie 720p, 1366×768, Full HD i ultrawide. Zestaw dowodów
  obejmuje łącznie 100 klatek przed/po; tempo wymaga końcowej oceny właściciela na żywo.

Logi: `build/combat-impact-review/validation.log`, `focused-impact-tests.log`,
`after/import.log`, `after/boot.log`, `after/capture.log`, `git-diff-check.log`.
Gotowe do oceny właściciela/drugiego recenzenta; bez merge/push.

## Dowody lokalne — nie śledzić w Git

- `build/combat-impact-review/before/evidence/` — stan bazowy.
- `build/combat-impact-review/after/evidence/` — nowa prezentacja.
- `hit_impact_*`, `critical_impact_*`, `dodge_impact_*`, `block_impact_*`,
  `reduced_impact_*` oraz odpowiadające `*_settled_*`.
- Rozdzielczości: 1280×720, 1366×768, 1920×1080, 2560×1080; 40 PNG przed i 60 po.
- Po zmianie dodatkowo `*_reaction_*` — środkowa klatka reakcji, także bloku.

Zrzuty są klatkami rzeczywistego renderera, nie makietami. `impact` oznacza
próbkę po 0,20 s, `reaction` po kolejnych 0,18 s, `settled` po łącznie około 0,90 s;
blok poprzedza zmiana tury, więc jego efekt zaczyna się później.
Dokładny moment impact sprawdzają testy sygnału.
Statyczne PNG nie wystarczają do oceny tempa — potrzebna ocena w uruchomionej grze.

## Audio i ograniczenia

Repo zawiera tylko pięć przykładów `typing*.wav` Dialogic, bez własnych odgłosów
walki lub odtwarzaczy w scenach/UI. Nie wykorzystano ich w walce. Audio jest
oddzielnym następnym krokiem, wymagającym doboru spójnych i legalnych próbek.

Znany komunikat środowiska Windows: `Failed to read the root certificate store.`
Runner dopuszcza wyłącznie ten błąd środowiskowy, nie inne błędy Godota.
Niezwiązana grafika kowadła i zastane różnice zakończeń linii `.import` pozostają
poza commitem. Właściciel nadal musi ocenić subiektywne tempo reakcji.

## Drugi recenzent

1. Obejrzeć na żywo trafienie/krytyk/unik/blok, obu walczących i szybkie kolejne tury.
2. Sprawdzić jednoczesny tekst i PŻ przy częściowym bloku; nie zmieniać jego obrażeń.
3. Sprawdzić Pchnięcie Losu, efekty pasywne, zwycięstwo i wejście w kolejną walkę.
4. Potwierdzić czytelność oraz brak kolizji komunikatów/HUD w 720p i Full HD.
5. Potwierdzić identyczny stan domeny/RNG w obu trybach, brak zmian zapisów/nagród
   oraz brak nowych bitmap i dowodów z `build/` w commicie.
