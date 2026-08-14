# Etapy migracji systemów — v0.25.0

## Zasada prowadząca

Wersja terminalowa `v0.24.7` pozostaje źródłem prawdy dla mechanik. Każdy etap
przenosi zamknięty fragment reguł do testowanego kodu GDScript, dopiero potem
podłącza proste UI. Finalne grafiki, dźwięki i animacje nie należą do tych
etapów; do czasu osobnej akceptacji używane są wyłącznie placeholdery.

## Etap 0 — grywalny fundament (ukończony)

- prolog, tworzenie bohatera i startowe wyposażenie,
- Varenhold i pionowy plan miasta,
- pierwsza misja fabularna i Zmierzchowe Równiny,
- turowa walka, nagrody, łupy, ekwipunek oraz podgląd klas,
- testy regresji Python i GUT, Full HD jako rozdzielczość referencyjna.

## Etap 1 — zapis i odczyt stanu Godot (ukończony)

- osobny format i katalog zapisów migracyjnych Godota,
- cztery sloty, podsumowanie zawartości i walidacja danych,
- zapis bohatera, atrybutów, statystyk, wyposażenia, plecaka, czasu,
  prologu, aktywnej misji i reputacji Gildii,
- bezpieczna obsługa uszkodzonego albo nowszego pliku,
- ekran wyboru zapisu i działające przyciski zapisu/odczytu w menu.

Pliki tego etapu nie nadpisują zapisów schematu `v15` aplikacji terminalowej.
Bezpośredni import starego zapisu nastąpi dopiero po migracji wszystkich pól,
które taki zapis może zawierać.

## Etap 2 — pełna ekonomia Varenhold (ukończony)

- kupno i sprzedaż zgodne z terminalową ekonomią,
- Kuźnia Garrana i ulepszenia `+0`–`+10`,
- Warsztat Mireli, przepisy, materiały i wymagania,
- zasady karczmy, odpoczynku, udźwigu i magazynu Gildii,
- testy cen, transakcji, receptur i braku utraty przedmiotów.

Zaimplementowany zakres obejmuje pełne operacje dla zawartości już dostępnej
w Godocie: sześciopozycyjny asortyment Orena, sprzedaż stosów i konkretnych
instancji wyposażenia, dziesięć receptur Zmierzchowych Równin, ulepszenia
`+0`–`+10`, nocleg raz na dzień, miękki limit udźwigu, blokadę startu wyprawy
przy przeciążeniu, 200-miejscowy Magazyn Gildii i trzy ulepszenia plecaka.
Stan tych systemów zapisuje schemat Godot `v2`; pliki `v1` są automatycznie
uzupełniane bezpiecznymi wartościami domyślnymi. Receptury następnych regionów
zostaną podłączone razem z ich przedmiotami i źródłami materiałów w etapie 4.

## Etap 3 — rozwój bohatera i kompletna walka klas (w toku)

### Etap 3A — atrybuty, Drogi i wyposażenie (ukończony)

- działające wydawanie punktów atrybutów z karty postaci,
- Szczęście dostępne wyłącznie dla Pierrota,
- wspólny katalog czterech Dróg używany przez model i UI,
- wybór Drogi od poziomu 5, bazowa Mana i sprzęt startowy,
- wymagania poziomu oraz klasy przy zakładaniu przedmiotów,
- plecak z porównaniem statystyk wobec aktualnie założonego wyposażenia,
- pełne jedenaście slotów, druga ręka, typy broni, udźwig i opisy zapasów,
- walidacja klasy i założonego wyposażenia przy zapisie oraz odczycie,
- przewijana karta postaci dla 1280×720 i pełny widok referencyjny Full HD.

Schemat zapisu pozostaje w wersji `v2`, ponieważ już przechowuje klasę,
atrybuty, wszystkie instancje wyposażenia oraz zawartość plecaka. Afiksy,
zestawy i przedmioty z kolejnych regionów pozostają częścią etapu 4.

### Etap 3B — fundament aktywnych umiejętności

- definicje umiejętności, koszty Many, poziomy i wymagane wyposażenie,
- wspólne efekty walki: krwawienie, osłabienie DEF, garda i unik,
- akcja odrzucona bez utraty Many i tury, gdy wymagania nie są spełnione.

### Etap 3C–3F — klasy, systemy specjalne i progresja

- cztery bazowe umiejętności Wojownika, Łowcy, Maga i Pierrota,
- kombinacje Łowcy i logika kości Pierrota w wariantach `1k6`, `2k6`, `3k6`,
- żywioły i Splot Maga oraz stany ofensywne i obronne Wojownika,
- tymczasowy, konfigurowalny panel akcji zależny od postaci i stanu walki,
- drzewka, specjalizacje, pasywne mistrzostwa i trwały zapis progresji,
- testy parytetu obrażeń, kosztów, efektów, tur i losowości.

## Etap 4 — wyprawy i świat

- wszystkie regiony, tabele przeciwników i pora dnia,
- pogoda, obóz, odpoczynek, elity, bossowie i ich odradzanie,
- pełne tabele łupów, afiksy, zestawy i progresja przedmiotów,
- dane mapy oddzielone od widoku, aby miejsca można było rozbudowywać bez
  generowania jednej sztywnej ilustracji miasta albo regionu.

## Etap 5 — fabuła, Gildia i zadania

- pozostałe misje fabularne oraz kontrakty,
- rangi, kamienie milowe, Czarny Rynek i osiągnięcia,
- Dialogic tylko jako warstwa prezentacji rozmów; stan misji pozostaje w
  testowanej logice domenowej.

## Etap 6 — lochy, drużyna i Szczeliny

- lochy i ich zasady dostępu,
- towarzysze, relacje, taktyki oraz przygotowanie wyprawy,
- Szczeliny i związane z nimi zasoby, progresja oraz spotkania.

## Etap 7 — parytet i bezpieczne przejście

- audyt wszystkich systemów wobec `v0.24.7`,
- importer terminalowego schematu `v15` działający tylko do odczytu,
- migracja kopii starego zapisu i raport elementów, których nie można przenieść,
- testy pełnego cyklu, eksport Windows, sterowanie i podstawowa dostępność,
- dopiero potem rozpoczęcie osobno akceptowanej warstwy finalnych assetów.

## Kryterium ukończenia etapu

Etap jest ukończony, gdy reguły zgadzają się z wersją terminalową, ekran da się
przejść bez terminala, zapis nie traci obsługiwanych danych, testy Python i GUT
przechodzą, a następny etap nie wymaga omijania niedokończonej logiki.
