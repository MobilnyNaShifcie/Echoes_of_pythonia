# Zwycięstwo — zatwierdzony sztandar i małe łupy

Gałąź: `codex/combat-victory-banner`.
Baza: `aef0b741ce801720e250e2bc281ae36ee97998d5`.
Zakres: kontynuacja części 1A istniejącego planu UI, nie nowy system walki.
Nie scalać z main ani wypychać bez osobnej zgody właściciela.

## Co wdrożono

- Bordowy sztandar z dynamicznym nagłówkiem i nazwą regionu/walki.
- Istniejąca ilustracja właściwej postaci po lewej, pełna sylwetka i tabliczka
  z prawdziwym imieniem. Bez podmiany grafiki bohatera lub tła regionu.
- Dynamiczne EXP i złoto z jednego już rozliczonego wyniku usługi domenowej.
- Małe karty faktycznych łupów: kanoniczna ikona, nazwa, ilość i tooltip.
  Do trzech kolumn, pionowe przewijanie nadmiaru, bez pustych kart.
- Pasek naprawdę odblokowanego osiągnięcia/awansu; brak fikcyjnych medali.
- Raport zawiera pełny wynik, zadania, kontrakty, dodatkowe osiągnięcia,
  komunikat bossa i przebieg walki. Otwarcie nie zasłania Kontynuuj; Escape zamyka raport.
- HUD walki i pokonany przeciwnik znikają dopiero po rozliczeniu zwycięstwa.
  Porażka, odwrót, akcje i następna walka zachowują dotychczasowe zachowanie.
- Zachowano ten sam przycisk Kontynuuj i sygnał nawigacji. Przy powrocie do walki
  przycisk wraca do swojego kontenera, a pole bitwy odzyskuje poprzednią kompozycję.

Żadnych zmian w `core`, danych przedmiotów, balansie, RNG, schemacie zapisów,
ekwipunku czy liczbie nagród. Animacje, dźwięk i dalsze etapy pozostają poza zakresem.
Różnica względem malowanej makiety jest zamierzona tam, gdzie chodzi o dane:
nazwy, ilustracje przedmiotów, regiony i nagrody pochodzą z gry, nie ze screenshotu.

## Pliki

- `godot/ui/screens/combat/combat.gd` — wiązanie gotowego wyniku, wejście/reset widoku.
- `godot/ui/screens/combat/combat_command_layout.gd` — responsywna kompozycja zwycięstwa.
- `godot/ui/screens/combat/victory_presentation.gd` + `.uid` — wyłącznie widok i interakcje.
- `godot/ui/screens/combat/victory_skin.gd` + `.uid` — atlas, font i stany przycisku.
- `godot/assets/ui/combat/victory_atlas_v1.png` + `.import` — przezroczysta oprawa bez tekstów.
- `godot/tests/test_combat_victory_banner.gd` + `.uid` — skupione regresje nowego widoku.
- `godot/tests/test_combat_presentation_stage_one.gd` — zachowane sprawdzenia starego
  panelu dla porażki; nową geometrię zwycięstwa sprawdza nowy zestaw.
- `godot/tests/test_combat_presentation_stage_nine_a.gd` — stabilność przycisku już po
  wejściu w zatwierdzony, większy ekran zwycięstwa; zachowane minimum i zasoby.
- `godot/tools/render_combat_hud_preview.gd` — klasy, nowy raport i stress wielu łupów.
- `scripts/review_combat_presentation.py` — opcjonalny osobny katalog tej weryfikacji.
- `AI_CONTEXT/UI_RULES.md`, `docs/UI_REFRESH_PLAN_20260907.md`,
  `godot/assets/ASSET_MANIFEST.md`, niniejszy raport — zatwierdzony kierunek i pochodzenie.

## Weryfikacja i odtworzenie

Z katalogu repozytorium:

```powershell
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-victory-review
.venv/Scripts/python.exe scripts/review_combat_presentation.py after --review-name combat-victory-review --only-tests --test-script=res://tests/test_combat_victory_banner.gd
./scripts/check.ps1
git diff --check
```

Podgląd uruchamia rzeczywisty App/Combat w Godocie, sesje w pamięci i zastępczy
zapis. Profile walidacji pozostają pod build, nie są otwierane zapisy właściciela.
Karty stress-testu nie są dodawane do ekwipunku.

Wyniki końcowe (2026-09-19):

- PASS: cały `scripts/check.ps1`: 762/762 testy GUT, 38 988 asercji, 102 skrypty.
- PASS: 660 testów Pythona + 8 podtestów.
- PASS: osobny zestaw zwycięstwa 9/9, 160 asercji, bez osieroconych węzłów.
- PASS: gdformat (341 plików), gdlint, walidatory 10 ikon / 26 kart / 16 obiektów
  z alfą i 11 teł miasta oraz `git diff --check` i `git diff --cached --check`.
- PASS: import, start projektu i ponowne renderowanie 80 zrzutów w Godocie 4.7.1,
  cztery rozdzielczości. Brak błędów parsera, brakujących zasobów i odwołań.
- Potwierdzono: żaden plik `godot/core`, `godot/data` ani wygenerowany dowód
  z `build` nie jest częścią zmiany. Atlas jest identyczny z oryginałem imagegen.

Jedyny pozostały komunikat ERROR to znany wcześniej problem środowiska Windows:
`Failed to read the root certificate store.` Runner rozróżnia go od błędów gry;
nie wycisza innych błędów. Nie naprawiano magazynu certyfikatów w zadaniu UI.
Logi: `build/combat-victory-review/validation.log`, `after/import.log`,
`after/boot.log`, `after/capture.log`, `after/gut.log`, `git-diff-check.log`.

Nowe testy: 720p/1366×768/Full HD/ultrawide, ukryty HUD, widoczny pełny bohater,
małe karty i ilości, prawdziwe nagrody, kanoniczne ikony, przepełnienie i długi
raport, polskie imię, wiele osiągnięć, puste dane, prolog, Escape, reset każdej
klasy do walki/porażki, niezmienność pełnego serializowanego stanu przy odświeżaniu
i Kontynuuj oraz rzeczywista przezroczystość atlasu.

## Zrzuty przed i po

Lokalne pliki (celowo nie dodane do Git i nie zamienione w martwe linki docs):

- `build/combat-victory-review/before/evidence/victory_1920x1080.png`
- `build/combat-victory-review/after/evidence/victory_1920x1080.png`
- analogicznie `victory_1280x720.png`, `victory_1366x768.png`, `victory_2560x1080.png`;
- po zmianie również `victory_report_*`, `result_overflow_*`, `defeat_*`,
  `none_victory_*`, `mage_victory_*`, `hunter_victory_*`, `pierrot_victory_*`.

Przed = zachowane renderowane dowody bazowego etapu 1A. Po = ponowne uruchomienie
realnej gry. To nie wygenerowane mockupy. PNG i logi są w ignorowanym build.

## Drugi recenzent i ryzyka

1. Zgodność z zaakceptowanym małym łupem, pełna sylwetka, czytelne ×ilość i diakrytyki.
2. Kliknięcie/fokus Kontynuuj, przewijanie kart i raportu, powrót do kolejnej walki.
3. Nagrody i instance ID nie zmieniają się od oglądania wyniku; brak drugiego rozliczenia.
4. Szczególnie boss, loch, prolog, wiele osiągnięć i długie nazwy.
5. Dowody nie trafiają do commita; niezwiązana grafika kowadła pozostaje nietknięta.

Skórka to atlas bitmapowy, więc na monitorach większych od Full HD jakość krawędzi
podlega skalowaniu. Georgia ma systemowe fallbacki Noto Serif/DejaVu Serif;
metryka na innym OS może się różnić, dlatego etykiety mają wielokropek i pełne tooltipy.
Weryfikacja wizualna tej zmiany odbywa się na Windows. Nie dodano nowych animacji;
istniejące krótkie odsłonięcie wyniku i tryb ograniczonego ruchu pozostają.

## Pochodzenie oprawy / imagegen

Jedno wywołanie wbudowanego imagegen edit z zaakceptowaną referencją
`exec-4d9fae83-4dc8-4bfc-b95f-12d504fcdd28.png`.
Wynik: `exec-f264a523-aa0e-42f5-8067-af05a8171e8c.png`.
Oryginały zachowane lokalnie w `.codex/generated_images/01a000c5-507d-7760-aa0e-b8169452ad43/`.
Kopia produkcyjna byte-identical, bez rasterowego postprocessingu; użyto regionów
AtlasTexture. Wynik ma 1254×1254 mimo żądanej większej rozdzielczości.
SHA-256 i rozmiar zapisano w istniejącym ASSET_MANIFEST.

Dokładny prompt:

> Create a production game UI sprite atlas from the approved reference. This is NOT a screenshot/mockup. Extract/reconstruct ONLY the matching decorative interface pieces, without ANY text, letters, numerals, item art, hero, landscape or game content. Preserve the reference's rich illustrated dark iron, antique beveled gold and deep burgundy woven cloth style exactly, premium painted fantasy RPG. True transparent RGBA background outside each component, NOT a checkerboard, not black. Square 2048x2048 atlas, clear generous transparent separation between pieces. Arrange in FOUR horizontal rows as follows: Row1 in top quarter (x64..1984 y32..600): one wide burgundy victory cloth banner with long black-gold horizontal spear pole ends, gold cloth borders, side pennants, centered small black-and-gold shield crest, ample blank dark red central area for future title and subtitle. No hanging legs below banner. Row2 (x160..1888 y680..930): one long black iron reward strip, beveled antique gold trim with cut corners and tiny rivets, blank dark textured center, no icons and no divider. Row3 (y1040..1470): left x80..650 one compact landscape loot card with dark iron interior and fine ornate gold framing, bottom narrow blank name strip; center x760..1360 one long narrow dark gold-edged heading/name plaque; right x1510..1930 one round gold achievement medal with a generic small embossed star and short burgundy ribbon, isolated. Row4 (y1620..1950): left x60..1110 one wide slim dark iron achievement/info strip with gold beveled angular ends, blank center; right x1220..1990 one wide burgundy-and-gold button matching reference Continue button, blank center. Every part fully contained in its allocated area; consistent frontal orthographic UI perspective, straight horizontal symmetrical panels, rich material edges but interiors restrained for readable text. No words, no EXP, no numbers, no characters, no loot or coins, no background scenery. All areas between sprites fully transparent with clean anti-aliased alpha edges.
