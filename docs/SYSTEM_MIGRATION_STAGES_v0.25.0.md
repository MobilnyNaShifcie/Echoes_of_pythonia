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

## Etap 1 — zapis i odczyt stanu Godot (w realizacji)

- osobny format i katalog zapisów migracyjnych Godota,
- cztery sloty, podsumowanie zawartości i walidacja danych,
- zapis bohatera, atrybutów, statystyk, wyposażenia, plecaka, czasu,
  prologu, aktywnej misji i reputacji Gildii,
- bezpieczna obsługa uszkodzonego albo nowszego pliku,
- ekran wyboru zapisu i działające przyciski zapisu/odczytu w menu.

Pliki tego etapu nie nadpisują zapisów schematu `v15` aplikacji terminalowej.
Bezpośredni import starego zapisu nastąpi dopiero po migracji wszystkich pól,
które taki zapis może zawierać.

## Etap 2 — pełna ekonomia Varenhold

- kupno i sprzedaż zgodne z terminalową ekonomią,
- Kuźnia Garrana i ulepszenia `+0`–`+10`,
- Warsztat Mireli, przepisy, materiały i wymagania,
- zasady karczmy, odpoczynku, udźwigu i magazynu Gildii,
- testy cen, transakcji, receptur i braku utraty przedmiotów.

## Etap 3 — rozwój bohatera i kompletna walka klas

- wydawanie punktów atrybutów i wszystkie efekty pasywne,
- umiejętności oraz ograniczenia wyposażenia każdej Drogi,
- kombinacje Łowcy i logika kości Pierrota w wariantach `1k6`, `2k6`, `3k6`,
- tymczasowy, konfigurowalny panel akcji zależny od postaci i stanu walki,
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
