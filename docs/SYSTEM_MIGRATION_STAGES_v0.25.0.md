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

## Etap 3 — rozwój bohatera i kompletna walka klas (ukończony)

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

### Etap 3B — fundament aktywnych umiejętności (ukończony)

- typowany katalog zachowujący cztery bazowe umiejętności każdej Drogi,
- koszty Many, poziomy odblokowania, opisy i wymagane typy wyposażenia,
- działające w walce bazowe zdolności Wojownika, Łowcy i Maga, w tym
  wielokrotne trafienia i gwarantowane trafienie,
- wspólne efekty walki: krwawienie, osłabienie DEF, garda i premia do uniku,
- skalowanie z ATK, Zręczności i Inteligencji zgodne z wersją terminalową,
- akcja odrzucona bez utraty Many i tury, gdy wymagania nie są spełnione,
- ekran katalogu dostępny z karty bohatera, podgląd wszystkich czterech Dróg
  bez zmiany klasy oraz dynamiczny wybór odblokowanej umiejętności w walce,
- testowany układ 1280×720 przy referencyjnym Full HD.

Umiejętności Pierrota są już obecne w katalogu i można sprawdzić ich opis,
koszt oraz poziom. Nie wykonują jednak zastępczego ataku: ich rozstrzygnięcie
pozostaje zablokowane do podetapu 3C, ponieważ wymaga pełnej logiki Kości Losu.
Stan efektów 3B istnieje tylko podczas walki, a dostępność umiejętności wynika
z zapisanych już klasy, poziomu i wyposażenia, dlatego schemat zapisu nadal ma
wersję `v2`.

### Etap 3C — Kości Losu Pierrota (ukończony)

- jeden Fate Engine z historią rzutów i testowalnym źródłem wyników,
- Kości Losu w wariantach `1k6`, `2k6` i `3k6`, włącznie z dubletami,
  trójkami, skrajnymi sumami i dokładnymi mnożnikami z wersji terminalowej,
- Żetony Losu z limitem zależnym od Szczęścia,
- pełne rozstrzygnięcia Pchnięcia Losu, Podwójnego Rzutu, Błazeńskiego Uniku
  i Wielkiego Zakładu,
- osłabienie ATK, podwójne trafienie, premie do Uniku oraz Kurtyna Lustrzana,
- odrzucenie nieprawidłowej akcji bez utraty Many, tury ani wykonania rzutu,
- elastyczny panel zastępczy pokazujący `1–3` kości, wynik, Żetony i gotowość
  odbicia; finalna animacja oraz oprawa pozostają poza tym etapem,
- parytet zaokrąglania połówek z Pythonem oraz testowany układ 1280×720.

Stan rzutów, Żetony Losu i odbicie istnieją wyłącznie w bieżącej walce, więc
schemat zapisu pozostaje w wersji `v2`. Manipulacje kośćmi z talentów Fortuny
i Chaosu należą do 3F i nie są zastępowane uproszczoną logiką.

### Etap 3D — Techniki Salwy i kombinacje Łowcy (ukończony)

- sześć dodatkowych Technik Salwy oraz bazowy Krwawiący Strzał jako elementy
  trzystrzałowej sekwencji,
- pełne reguły Przebijającej, Lodowej, Wybuchowej, Widmowej i
  Rozszczepiającej Strzały oraz Deszczu Strzał,
- trzy Ładunki Wybuchowe, opóźnione Widmowe Echo i opóźniona salwa,
- sześć nazwanych kombinacji z mnożnikami, przebiciem pancerza, żywiołem,
  krwawieniem i zużyciem ładunków zgodnymi z wersją terminalową,
- czyszczenie także nienazwanej sekwencji po trzeciej technice,
- trwałe odkrywanie kombinacji oraz walidowany zapis progresji Łowcy,
- zastępczy panel walki pokazujący sekwencję, ładunki, oczekujące efekty i
  ostatni finiszer; finalne efekty pocisków pozostają poza tym etapem,
- katalog technik na ekranie umiejętności bez przedwczesnego wdrażania drzewka.

Schemat zapisu Godota ma teraz wersję `v3`. Zapisuje odblokowane techniki
talentowe i odkryte kombinacje, a pliki `v1` oraz `v2` są kolejno migrowane z
bezpiecznymi pustymi kolekcjami. Samo zdobywanie talentów nadal należy do 3F;
3D dostarcza gotowe i testowane reguły, które ta progresja będzie odblokowywać.

### Etap 3E — Splot Maga i postawy Wojownika (ukończony)

- sześć typów obrażeń oraz odporności żywiołów z limitem `0–75%`,
- Sekwencja Żywiołów Maga i premia trzeciego różnego czaru,
- trzy Ładunki Splotu i Podwójne Tkanie dwóch czarów w jednej turze,
- warianty kosztu, obrażeń i odzyskiwania Many wynikające z mistrzostw Splotu,
- bazowa szansa bloku Wojownika z tarczą oraz jednorazowa premia Prowokacji,
- Uderzenie Tarczą, wymuszony podstawowy atak po Prowokacji, ciężka kontra
  po bloku i odwet przygotowywany przez Obronę,
- osobne, zwarte panele zastępcze Wojownika i Maga oraz drugi selektor czaru,
- testy parytetu obrażeń, odporności, kosztów Many, tur i stanów walki.

Schemat zapisu Godota ma teraz wersję `v4` i przechowuje identyfikatory
odblokowanych mechanik klasowych. Pliki `v1`–`v3` są migrowane z pustą,
bezpieczną kolekcją. Reguły talentów są gotowe, lecz bohater nie otrzymuje ich
automatycznie: faktyczny zakup i odblokowanie należą do etapu 3F.

### Etap 3F — drzewka i specjalizacje (ukończony)

- typowany katalog ośmiu ścieżek i wszystkich 41 talentów czterech klas,
- punkty drzewka zgodne z poziomem, wymagania rang, ścieżek oraz Ksiąg Ścieżki,
- zakup talentów i reset za złoto bez usuwania trwale otwartych ścieżek,
- cztery pasywki, rangi `1–5`, Mistrzostwa `6–10` oraz osiem trwałych
  specjalizacji pasywnych,
- podłączenie rang do obrażeń, krwawienia, osłabienia DEF, bloku, sekwencji,
  Widmowego Echa, żywiołów, Splotu, Kości Losu, krytyków, dodatkowych ciosów,
  regeneracji, Drugiego Oddechu i Rozpędu,
- talentowe umiejętności Uderzenie Tarczą, Prowokacja, Tysiąc Strzał i
  Va Banque odblokowywane wyłącznie przez prawdziwy zakup talentu,
- osobny moduł rozstrzygania Fortuny z Dociążoną Kością, Kantem, Drugą Szansą,
  Wybrańcem Fortuny, Krzywym Zwierciadłem, Podwójną Stawką i Efektem Domina,
- roboczy ekran `Talenty i pasywy` dostępny z karty postaci, z dwiema zakładkami,
  opisami wymagań i czytelnymi blokadami; finalna oprawa pozostaje poza etapem,
- walidacja budżetu punktów, wymagań i specjalizacji przy zapisie oraz odczycie.

Schemat zapisu Godota ma teraz wersję `v5`. Przechowuje rangi talentów,
odblokowane Księgami Ścieżki, rangi pasywów, Mistrzostwa i wybrane
specjalizacje. Pliki `v1`–`v4` są migrowane z bezpiecznymi pustymi wartościami,
a zapis próbujący ominąć wymagania albo budżet punktów jest odrzucany.

## Etap 4 — wyprawy i świat

### Etap 4A — księgi i fundament świata (ukończony)

- osiem terminalowych Ksiąg Mistrzostwa i Ksiąg Ścieżki jako zwykłe,
  stosowalne przedmioty plecaka,
- czytanie księgi z ekranu ekwipunku; błędna klasa i ponowne czytanie nie
  zużywają egzemplarza,
- typowany katalog pięciu regionów z opisami, poziomami, zagrożeniem, szansą
  spotkania, tabelami dnia i nocy oraz cichymi wydarzeniami,
- lista znanych regionów oddzielona od UI i gotowa na przyszłe odblokowania,
- placeholderowy ekran przeglądania regionów bez finalnej mapy i assetów,
- zachowanie reguły terminalowej: zalecany poziom ostrzega, ale nie blokuje
  dostępu do trudniejszego obszaru.

Schemat zapisu Godota ma teraz wersję `v6`. Księgi są zapisywane w zwykłym
plecaku, a lista znanych regionów jest przechowywana i walidowana osobno. Pliki
`v1`–`v5` otrzymują przy migracji wszystkie pięć regionów, ponieważ były one
widoczne od początku w wersji terminalowej.

### Etap 4B — regionalne wyprawy i przeciwnicy (ukończony)

- jeden serwis wypraw obsługujący wszystkie pięć regionów, ich osobne szanse
  spotkania, tabele dnia i nocy oraz ciche wydarzenia,
- 26 brakujących definicji przeciwników, dzięki czemu wszystkie 36 unikalnych
  spotkań otwartego świata prowadzi do prawdziwej walki,
- terminalowe PŻ, ATK, DEF, unik, nagrody EXP i złota, rangi, ataki specjalne,
  dodatkowe ciosy, pierwszy wzmocniony atak i redukcja obrażeń fizycznych,
- odporności na ogień, wiatr, mróz, ziemię i wodę oraz odporność wybranych
  przeciwników na krwawienie i obniżenie DEF,
- dynamiczna nazwa regionu na ekranie walki i zachowanie wybranego regionu po
  powrocie z walki oraz po zapisie i odczycie,
- wejście do regionu powyżej zalecanego poziomu nadal nie jest blokowane;
  każda rozpoczęta wyprawa przesuwa czas o jedną godzinę.

Etap nie zmienia schematu `v6`, ponieważ bieżący i znane regiony zostały już
utrwalone w 4A. Pełne regionalne tabele przedmiotów, elity, pogoda, ognisko,
bossowie i ich liczniki należą do kolejnych podetapów.

### Następne podetapy

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
