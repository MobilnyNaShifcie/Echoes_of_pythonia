# Stage 8 — końcowy raport parytetu otwartego świata

## Zakres i wynik

Stage 8E kończy porównanie terminalowej wykonywalnej specyfikacji `v0.24.7`
z Godotem `v0.25.0` dla trzech luk pozostawionych jawnie po Stage 7:

- `elite_discoveries`,
- `elite_miss_streaks`,
- `region_boss_respawns`.

Audyt objął terminalowe `data/elites.py`, `systems/elite_system.py`, oba silniki
regionalnych bossów, `systems/region_boss_respawn.py`, serializację schematu
`v15` i testy regresyjne. Po stronie Godota sprawdzono modele, katalogi,
serwisy, silniki walki, UI mapy i walki, codec schematu `v17`, importer kopii
terminalowego zapisu oraz testy etapów 8A–8E.

Wynik: wszystkie trzy luki mają pełny, aktywny odpowiednik. Nie znaleziono
dalszych znanych braków parytetu w zakresie Stage 8.

## Macierz parytetu

| Obszar terminala | Odpowiednik Godota | Wynik |
| --- | --- | --- |
| pięć modyfikatorów elit | `EliteCatalog` | pełny katalog i reguły |
| 31 zgodnych zwykłych przeciwników | `EliteCatalog.COMPATIBILITY` | pełna tabela |
| szansa dzień/noc/Zorza | `EliteEncounterService` | `10% / 15% / 25%` |
| regionalny pity elit | `elite_miss_streaks` | `+2 p.p.`, limit `95%`, reset po sukcesie |
| trwałe pierwsze odkrycie elity | `elite_discoveries` | jednorazowy wpis i save/load |
| statystyki i efekty elit | wspólny combat + `EliteEncounterService` | pełne reguły pięciu wariantów |
| Azhar i Lewiatan Północy | `RegionBossCatalog` | oba jawne wyzwania i dane walki |
| trzy fazy każdego bossa | dedykowane silniki bossów | pełne progi i efekty |
| nagrody, trofea, księgi i kamienie milowe | istniejące serwisy domenowe | pełny przepływ, bez logiki w UI |
| koszt próby bossa | `RegionBossChallengeService.finish_attempt()` | jedna godzina po walce |
| odrodzenie po zwycięstwie | `RegionBossRespawnService` | dokładnie sześć wypraw w regionie |
| blokada rewanżu | przygotowanie wyzwania + mapa | bez mutacji czasu i kontraktów |
| terminalowy save `v15` | read-only mapper/importer kopii | wszystkie trzy pola mapowane |
| Godot save/load | `WorldEncounterSaveCodec`, schemat `v17` | pełny round-trip i walidacja |

## Domknięta różnica kolejności

Audyt wykrył jedną rzeczywistą różnicę. Terminal po walce z bossem:

1. rozlicza wynik walki,
2. przesuwa czas świata o godzinę,
3. po zwycięstwie uruchamia odrodzenie i zapisuje wpis w dzienniku.

Godot przed 8E uruchamiał odrodzenie już podczas rozliczania nagród, czyli przed
kosztem czasu. Stan końcowy licznika był poprawny, lecz wpis Dziennika Przygód
miał godzinę wcześniejszą niż terminal. Po poprawce nagrody i kamień milowy są
rozliczane przez `resolve_victory()`, natomiast `finish_attempt()` nalicza czas,
a następnie — wyłącznie dla zwycięstwa — uruchamia odrodzenie. UI prezentuje
zwrócony komunikat i nie jest właścicielem żadnej z tych reguł.

## RNG i zapis

Obowiązuje wcześniejsza decyzja architektoniczna: wymagany jest parytet reguł,
deterministyczność wewnątrz Godota, stabilność po save/load i zachowanie
zapisanych wyników importu. Bitowo identyczny strumień Python `random.Random`
i Godot `RandomNumberGenerator` nie jest kontraktem migracji.

Stage 8E nie dodaje danych trwałych. Schemat pozostaje `v17`. Importer nadal
otwiera terminalowy zapis tylko do odczytu, tworzy wyłącznie nową kopię w
pustym slocie i nigdy nie modyfikuje źródła. Test pełnego cyklu potwierdza, że
zaimportowane liczniki nie są pasywnymi polami: wpływają na następne losowanie
elity, blokują wyzwanie bossa, zmniejszają się po właściwej wyprawie i zachowują
nowy stan po kolejnym zapisie oraz odczycie.

## Granica etapu

Stage 8 jest zamknięty. Raport nie rozpoczyna integracji finalnych grafik,
dźwięków ani rozbudowanych animacji. Warstwa prezentacyjna wymaga osobnej,
jawnej decyzji i nadal korzysta z placeholderów.
