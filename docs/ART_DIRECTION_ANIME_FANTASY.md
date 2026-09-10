# Echoes of Pythonia — spójność ilustracji

Decyzja użytkownika z 2026-09-06: zachować istniejące postacie anime-fantasy i dopasować do nich sposób malowania przedmiotów. Nie przerabiać wszystkich postaci na realistyczne.

## Wspólny standard

- Główne wzorce: `godot/assets/combat/heroes/hunter_male.png` i `mage_female.png`. Kontur, grupowanie cieni oraz sposób przedstawiania skóry, tkanin, metalu i kamieni na tych postaciach są nadrzędne wobec starszych ikon.
- Przedmioty: ilustracyjne 2D PNG z prawdziwą przezroczystością, 512×512, sylwetka około 84% dłuższego boku. Kontrola w dużym powiększeniu oraz slocie 64 px, na jasnym i ciemnym tle.
- Duże, czytelne płaszczyzny światła i cienia; niewiele celowych rys i śladów zużycia. Bez fototekstur, szumu, drobnych świetlików i wszechobecnych połysków. Nie upraszczać do płaskiej, dziecięcej kreskówki.
- Materiały nie stają się biżuterią. Zwykły pazur pozostaje pazurem, stara zbroja może być zardzewiała; spójny jest sposób rysowania, nie jednakowy poziom przepychu.
- Potwór wyznacza anatomię, materiał i motyw łupu. Receptura i zestaw wyznaczają wspólne elementy wyposażenia. Nie kopiować realistycznej mikrofaktury z potwora do ikony.
- Ramki jakości rysuje interfejs według `item_rarity_palette.gd`: szara → zielona → niebieska → fioletowa → czerwona → pomarańczowa. Nie wmalowywać ramek, napisów ani cen w PNG. Nie zmieniać statystyk ani rzadkości przy wymianie ilustracji.
- Poświaty/animacje rezerwować dla wybranych artefaktów i wyjątkowych nagród; zwykły ekwipunek pozostaje 2D. Modeli 3D czarnego rynku nie zastępować hurtowo ikonami.

## Kolejność pracy

1. **Zatwierdzone** przez użytkownika: Czarny Pazur, Hełm Zgniłego Rycerza, Wisiorek Kultysty. Karty kontrolne: `output/item_art/anime_style_pilot_review.png`.
2. **Pierwsza grupa 30 podpięta**: `art_drafts/anime_style_batch_01/`, podgląd `output/item_art/anime_batch_01_review.png`. Starsze szkice pozostają zachowane, nie są uznawane za finalne.
3. **Braki ikon zamknięte po partiach 30 + 30 + 30 + 19**: katalog 159/159. Nowy kierunek obejmuje 109 ikon, pozostałe 50 starszych zachowano do selektywnego przeglądu. Ostatnia partia: `docs/ART_BATCH_04_REPORT.md`. Nie oznacza to zakończenia ujednolicania wszystkich istniejących grafik.
4. Osobny przegląd brakujących dungeonów, potem efekty umiejętności i czytelność walki. Zmiany UI nie mogą być warunkiem poprawnego wczytywania grafik.

## Krypta — zatwierdzony wzorzec komnat

Decyzja użytkownika z 2026-09-06: zatwierdzony **Zatopiony Przedsionek v2** (`art_drafts/dungeon_crypt_pilot_01/sunken_vestibule_v2.png`). Pierwsza wersja była zbyt realistyczna i nie jest wzorcem kolejnych komnat.

- Zachować malarskie anime-fantasy: wyraźny kontur, duże płaszczyzny światła i cienia, ograniczone drobne faktury kamienia oraz ilustracyjne odbicia wody. Bez fotograficznych materiałów i wyglądu renderu 3D.
- Wspólne motywy Zakonu: granatowe sztandary, złoty znak kompasowej gwiazdy, chłodna niebieskozielona woda i oszczędne bursztynowe światło lamp.
- Zachować czytelną przestrzeń dla postaci walczących. Tło bez wmalowanego interfejsu i przeciwników.
- Zatwierdzenie pilota dotyczyło komnaty. Dnia 2026-09-07, na polecenie domknięcia Krypty, dodano pięć kolejnych teł, pięciu brakujących przeciwników i poprawiony portret Rycerza. Wielki Mistrz zachowuje projekt pilota, uzupełniony tarczą z istniejącej mechaniki faz. Szczegóły: `docs/CRYPT_COMPLETION_REPORT.md`.

## Region 5 — równoległe uzupełnienie

Lodowe Wybrzeże (`ice_coast`) nie miało wpisów w katalogu prezentacji ani plików tła/przeciwników. Dodano nowy zestaw: dwie pory dnia tej samej lokalizacji, sześciu przeciwników tabel spotkań i Lewiatana Północy. Wygląd powiązano z faktycznymi łupami: białe futro, pióra gryfa, lodowa chityna, perła, kompas oraz niebiesko-jadeitowa łuska.

Źródła, pełne prompty i tryb generowania: `art_drafts/anime_style_pilot/region5_and_style_manifest.json`. Oryginały pozostają zachowane. Usunięcie jednolitego tła wykonuje lokalny skrypt na podstawie wcześniejszej zgody użytkownika; bez zewnętrznego API.

Walidacja: test katalogów wszystkich regionów, prawdziwa scena walki dzień/noc/boss, przezroczystość i marginesy sylwetek. Podgląd uruchamiany wyłącznie na sesji w pamięci, bez odczytu i zapisu gry użytkownika.
