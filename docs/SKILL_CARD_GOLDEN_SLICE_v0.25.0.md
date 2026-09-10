# Stage 9D — golden slice kart umiejętności

## Zatwierdzony język obrazu

Pierrot pozostaje wzorcem jakości postaci, ale ilustracja karty umiejętności nie
jest portretem bohatera. Pokazuje broń, pocisk, żywioł, ślad ruchu albo skutek
działania. Zatwierdzone wyjątki to `Błazeński Unik`, gdzie sylwetka pokazuje
ruch, oraz `Prowokacja`, gdzie cienista sylwetka Wojownika, podświetlona tarcza
i skierowane ku niemu bronie jednoznacznie pokazują przejęcie uwagi wrogów.

Kolor nie jest wspólnym czerwonym filtrem. Wynika z klasy i działania:

- Wojownik: stal, granat i chłodny błękit,
- Łowca: zieleń, brąz, szałwia i przygaszone złoto,
- Mag: barwa właściwego żywiołu na głębokim tle,
- Pierrot: czerń, biel, głęboka magenta i różowo-czerwone akcenty.

`Pchnięcie Losu` przedstawia wyłącznie Lancę Losu. Wynik `1k6` pokazuje po
użyciu istniejący, dynamiczny system kości. Grafika nie miesza lancy z kośćmi.

## Kontrakt pliku źródłowego

- PNG, 1086×1448 px, pionowe proporcje 3:4,
- pełnokadrowa, nieprzezroczysta ilustracja bez wypalonej ramki karty,
- brak nazwy, kosztu Many, opisu, stanu, symbolu blokady, liczby kości i innych
  elementów interfejsu,
- jeden czytelny motyw umiejętności, spójne oświetlenie i poziom szczegółu,
- bez postaci, chyba że zatwierdzony wyjątek jest potrzebny do pokazania ruchu,
- plik: `assets/skills/<class_code>/<skill_id>.png`.

Ramkę, klasowy akcent, nazwę, koszt, stan, typ efektu i `1K6/2K6/3K6` generuje
Godot. Dzięki temu jedna ilustracja działa w walce i katalogu, a lokalizacja,
blokady i balans nie wymagają ponownego renderowania obrazu.

## Zatwierdzony katalog

| Klasa | ID | Nazwa | Motyw |
| --- | --- | --- | --- |
| Wojownik | `power_slash` | Potężne Cięcie | ostrza i stalowy łuk cięcia |
| Wojownik | `armor_break` | Roztrzaskanie Pancerza | pękający pancerz pod ciężkim ciosem |
| Wojownik | `defensive_stance` | Postawa Obronna | tarcza przyjmująca serię uderzeń |
| Wojownik | `blood_strike` | Krwawy Zamach | ciężki zamach z krwistym śladem |
| Wojownik | `shield_bash` | Uderzenie Tarczą | rozpędzona tarcza wybijająca hełm |
| Wojownik | `provoke` | Prowokacja | wojownik z podświetloną tarczą przyciągający bronie |
| Łowca | `precise_shot` | Precyzyjny Strzał | strzała trafiająca w wybrany punkt |
| Łowca | `bleeding_shot` | Krwawiący Strzał | prawidłowy grot przeszywający cel z krwistym śladem |
| Łowca | `shadow_step` | Krok w Cieniu | ślad kroku pozostawiony wyraźnie przed spadającą strzałą |
| Łowca | `double_shot` | Podwójny Strzał | dwa równoległe pociski jednego ataku |
| Łowca | `piercing_arrow` | Przebijająca Strzała | strzała przebijająca osiowo trzy tarcze, wariant A |
| Łowca | `frost_arrow` | Lodowa Strzała | grot i tor lotu pokryte lodem |
| Łowca | `explosive_arrow` | Wybuchowa Strzała | strzała inicjująca eksplozję |
| Łowca | `phantom_arrow` | Widmowa Strzała | niematerialny pocisk o widmowym śladzie |
| Łowca | `rain_of_arrows` | Deszcz Strzał | salwa opadająca na obszar |
| Łowca | `splitting_arrow` | Rozszczepiająca Strzała | jeden pocisk dzielący się na kolejne |
| Łowca | `thousand_arrows` | Tysiąc Strzał | gęsta, kulminacyjna nawała strzał |
| Mag | `fire_bolt` | Ognisty Pocisk | skupiony pocisk ognia |
| Mag | `frost_lance` | Lodowa Lanca | długa lanca uformowana z lodu |
| Mag | `lightning` | Piorun | skoncentrowane wyładowanie elektryczne |
| Mag | `mana_burst` | Wybuch Many | spektakularna detonacja surowej energii |
| Pierrot | `fate_thrust` | Pchnięcie Losu | Lanca Losu bez kości |
| Pierrot | `double_roll` | Podwójny Rzut | dwie kości jako główny motyw mechaniki |
| Pierrot | `fate_feint` | Błazeński Unik | zatwierdzona sylwetka uniku |
| Pierrot | `grand_gamble` | Wielki Zakład | trzy kości i eskalacja ryzyka |
| Pierrot | `va_banque` | Va Banque | kulminacyjny motyw pełnego zakładu |

Wszystkie 26 obecnie zarejestrowanych umiejętności ma własną zatwierdzoną
ilustrację. Przyszłe umiejętności bez zaakceptowanego assetu muszą używać
jawnego placeholdera. Zabronione jest ciche wykorzystanie grafiki innego skilla
jako fallbacku.

## Kontrola jakości

`scripts/check-skill-card-assets.ps1` sprawdza obecność, dokładne proporcje i
SHA-256 wszystkich 26 zatwierdzonych plików. Test GUT sprawdza przypisanie
unikalnego obrazu do właściwego `SkillDefinition`, wspólne użycie w walce i
katalogu, clipping, dynamiczne oznaczenia kości oraz układ 1920×1080 i
1280×720.

Zmiana zatwierdzonego obrazu wymaga nowego podglądu, akceptacji właściciela i
świadomej aktualizacji hasha. Stage 9D nie zmienia mechaniki, balansu ani zapisu.
