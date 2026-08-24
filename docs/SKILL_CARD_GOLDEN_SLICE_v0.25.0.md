# Stage 9D — golden slice kart umiejętności

## Zatwierdzony język obrazu

Pierrot pozostaje wzorcem jakości postaci, ale ilustracja karty umiejętności nie
jest portretem bohatera. Pokazuje broń, pocisk, żywioł, ślad ruchu albo skutek
działania. Jedynym zaplanowanym wyjątkiem jest `Błazeński Unik`, dla którego
czytelna sylwetka w ruchu może być właściwym nośnikiem mechaniki.

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

## Zatwierdzony golden slice

| Klasa | ID | Nazwa | Motyw |
| --- | --- | --- | --- |
| Wojownik | `power_slash` | Potężne Cięcie | ostrza i stalowy łuk cięcia |
| Łowca | `precise_shot` | Precyzyjny Strzał | strzała trafiająca w wybrany punkt |
| Mag | `fire_bolt` | Ognisty Pocisk | skupiony pocisk ognia |
| Pierrot | `fate_thrust` | Pchnięcie Losu | Lanca Losu bez kości |

Pozostałe umiejętności muszą używać jawnego placeholdera. Zabronione jest
ciche wykorzystanie grafiki innego skilla jako fallbacku.

## Kontrola jakości

`scripts/check-skill-card-assets.ps1` sprawdza obecność, dokładne proporcje i
SHA-256 czterech zatwierdzonych plików. Test GUT sprawdza przypisanie obrazu do
właściwego `SkillDefinition`, brak przypisań u pozostałych skilli, wspólne użycie
w walce i katalogu, clipping, placeholdery, dynamiczne oznaczenia kości oraz
układ 1920×1080 i 1280×720.

Zmiana zatwierdzonego obrazu wymaga nowego podglądu, akceptacji właściciela i
świadomej aktualizacji hasha. Stage 9D nie zmienia mechaniki, balansu ani zapisu.
