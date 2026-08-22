# Stage 7 — końcowy parytet i bezpieczne przejście

> Aktualizacja po Stage 8A: trzy jawne luki opisane w tym historycznym raporcie
> mają już bezpieczny odpowiednik w `OpenWorldEncounterState`. Importer mapuje
> ich zapisane wartości do Godotowego schematu `v17`, a `audit.not_migrated`
> pozostaje pusty. Stage 8A utrwala wyłącznie stan; zasady elit i bossów
> regionalnych należą do etapów 8B–8D.

## Zakres audytu

Stage 7 porównuje wykonywalną specyfikację terminalową `v0.24.7` (schemat
zapisu `v15`) z migracją Godot `v0.25.0` (schemat `v16`). Audyt objął stan
bohatera, świat, pogodę i czas, ekwipunek, rozwój, zadania, kontrakty, Gildię,
Czarny Rynek, Magazyn Gildii, Dziennik Przygód, kompanów, przygotowanie
wyprawy, lochy SOLO oraz Szczeliny i walkę drużynową.

Formaty pozostają rozdzielone. Terminalowy plik nie jest zwykłym starszym
schematem Godota i nie przechodzi przez automatyczne migracje Godot `v1–v16`.
Dedykowany `TerminalSaveV15Mapper` mapuje wyłącznie dokładną parę:

- `schema_version = 15`,
- `game_version = 0.24.7`.

`SaveGameService` nadal jest autorytetem walidacji i tworzenia obiektów
domenowych po mapowaniu. Import nie wymaga podniesienia schematu Godota ponad
`v16`.

## Wynik parytetu zapisu

| Terminal `v15` | Godot `v16` | Wynik |
| --- | --- | --- |
| bohater, atrybuty, PŻ/Mana, waluty | `player` | mapowane i walidowane |
| klasa, talenty, ścieżki, pasywki | progresja gracza | mapowane; aktywne umiejętności wynikają z rang talentów |
| ekwipunek i plecak | equipment/inventory codecs | mapowane z zachowaniem instancji, ulepszeń i affixów |
| lokalizacja, miasto, dzień, godzina, pogoda | stan sesji i świata | mapowane |
| zadania i ukończenia | `quest_log` | mapowane; lista ukończeń jest normalizowana do słownika |
| kontrakty | `contracts` | mapowane; terminalowe `null` jest normalizowane do pustej wartości Godota |
| reputacja i kamienie milowe | Gildia | reputacja i trwałe milestone'y świata są mapowane |
| Czarny Rynek i Magazyn Gildii | osobne stany domenowe | mapowane |
| Dziennik Przygód | `adventure_log` | mapowany |
| kompani, kandydaci i polegli | `PartyState` / `PartySaveCodec` | mapowane wraz z buildem, relacjami i własnością sprzętu |
| `current_hp/current_mana <= 0` kompana | flagi inicjalizacji `v16` | zachowana terminalowa semantyka pierwszej inicjalizacji |
| presety przygotowania wyprawy | `ExpeditionPreparationState` | mapowane z jawnym `preset_id` |
| lifecycle i ekspedycja Szczeliny | `RiftState` / `RiftSaveCodec` | mapowane i walidowane |

Terminalowe wpisy `quest:*` i `contract:*` w `guild.milestones` są danymi
wtórnymi: ich autorytatywny stan znajduje się w dzienniku zadań, kontraktach i
reputacji. Importer zapisuje je w raporcie jako normalizację, a nie jako utratę
postępu. Terminal nie utrwala prezentacyjnego licznika zwycięstw Godota, dlatego
otrzymuje on udokumentowaną wartość domyślną `0`. Każdy terminalowy zapis jest
tworzony po prologu, więc kopia otrzymuje ukończony stan prologu.

## Jawne różnice bez bezpiecznego odpowiednika

Importer nie ukrywa wartości, których obecny Godot nie potrafi bezpiecznie
odtworzyć. Raport kopii zawiera ich pełne wartości w `audit.not_migrated`:

- `elite_discoveries` — trwały rejestr odkrytych modyfikatorów elit,
- `elite_miss_streaks` — terminalowa ochrona przed długą serią bez elity,
- `region_boss_respawns` — liczniki odrodzenia regionalnych bossów.

Te sekcje są najpierw walidowane według terminalowych identyfikatorów i granic.
Uszkodzona albo nieznana wartość przerywa import zamiast zostać pominięta.
Pozostałe obsługiwane dane nie są z tego powodu blokowane. Jest to jawna luka
parytetu świata do decyzji w osobnym etapie, a nie prowizoryczna mechanika
Stage 7.

## Nienaruszalność źródła i transakcja kopii

`TerminalSaveV15Importer` spełnia następujący kontrakt:

1. źródło jest otwierane wyłącznie w trybie `FileAccess.READ`,
2. suma SHA-256 jest sprawdzana przed i po odczycie oraz po każdym etapie importu,
3. źródło i cel nie mogą wskazywać tego samego pliku,
4. celem może być tylko pusty slot Godota,
5. istniejący zapis i istniejący raport nigdy nie są nadpisywane,
6. Godot waliduje mapowanie przed zapisem, a utworzoną kopię od razu ponownie
   wczytuje,
7. nieudana operacja usuwa wyłącznie nowy plik utworzony przez bieżący import,
8. raport JSON zapisuje ścieżki, wersje, sumy kontrolne, wynik round-trip oraz
   wszystkie normalizacje i niemigrowane pola.

Oryginalny terminalowy save nie jest przenoszony, zmieniany, usuwany ani
nadpisywany. Ekran `Wczytaj grę` jedynie wybiera źródło i pusty slot oraz wywołuje
usługę domenową.

## Testy pełnego cyklu

Regresje Stage 7 obejmują:

- akceptację wyłącznie terminalowego `v0.24.7/v15`,
- mapowanie wszystkich obsługiwanych sekcji i jawny raport trzech luk,
- odrzucenie uszkodzonych danych terminalowych,
- zachowanie aktywnej umiejętności wynikającej z terminalowej rangi talentu,
- import do pustego slotu, zapis raportu i niezmienność tekstu oraz SHA-256 źródła,
- odmowę nadpisania zajętego slotu,
- cykl terminal `v15` → mapa → Godot `v16` → zapis → odczyt → ponowny zapis →
  ponowny odczyt, także z kompanem i jego osobistym wyposażeniem,
- pozostawienie pustego celu i braku raportu po błędzie,
- pełny przepływ importu przez istniejący ekran `Wczytaj grę` bez terminala.

Test dyskowego round-trip ujawnił różnicę typów JSON dla całkowitych wartości
`relation` i `impression`. `PartySaveCodec` przyjmuje teraz również liczby
zmiennoprzecinkowe o dokładnej wartości całkowitej, nadal odrzucając ułamki i
wartości spoza terminalowych granic.

## Eksport i podstawowa dostępność

Projekt ma wersjonowany preset `Windows Desktop` i skrypt
`scripts/export-windows.ps1`. Eksport wyklucza GUT oraz zasoby testowe, sprawdza
kod procesu, świeżość plików EXE/PCK i nadaje aplikacji wersję `0.25.0`.

UI pozostaje placeholderowe, ale korzysta ze standardowych kontrolek Godota,
widocznego stylu fokusu, początkowego fokusu klawiatury, opisów narzędzi dla
nieodwracalnych wyborów oraz skalowanego viewportu Full HD `1920×1080`. Import
jest dostępny z istniejącego ekranu wczytywania; nie wymaga konsoli ani nowego
hubu.

Finalne grafiki, dźwięki i rozbudowane animacje nie są częścią Stage 7 i nie
zostały rozpoczęte.

## Walidacja checkpointu

- GDScript formatter: 211 plików bez zmian,
- GDScript lint: brak problemów,
- Python: 534 testy + 8 subtestów,
- GUT: 391/391 testów, 3993 asercje,
- bootstrap Godota: kod wyjścia 0,
- eksport Windows EXE/PCK i smoke test spakowanej aplikacji: kod wyjścia 0.
