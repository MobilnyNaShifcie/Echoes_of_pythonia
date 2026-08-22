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
utrwalone w 4A. Elity, pogoda, ognisko, bossowie i ich liczniki należą do
kolejnych podetapów.

### Etap 4C — regionalne łupy i przedmioty (ukończony)

- wszystkie 36 tabel łupów przeciwników otwartego świata, wraz z terminalowymi
  szansami i zachowanymi wariantami szans dla przyszłych elit,
- 72 brakujące definicje materiałów, wyposażenia, mikstur i wejściówek; razem z
  wcześniejszym katalogiem Godot rozpoznaje teraz 118 przedmiotów,
- łup ze wszystkich pięciu regionów trafia do zwykłego plecaka, a wyposażenie
  powstaje jako osobny egzemplarz z własnym `instance_id`,
- terminalowe statystyki bazowe, rzadkość, Item Power, wymagany poziom,
  odporności żywiołowe i metadane specjalnych przedmiotów regionalnych,
- odporności założonego wyposażenia są sumowane i rzeczywiście redukują
  odpowiednie obrażenia w walce,
- 42 receptury Mireli podzielone na pięć regionów: 10 dla Równin, 8 dla Boru,
  12 dla Mokradeł, 7 dla Pogranicza i 5 dla Wybrzeża,
- terminalowe koszty złota receptur są sprawdzane atomowo; brak złota albo
  składnika nie zużywa żadnych zasobów,
- profile ulepszeń Item Power II, III, V i VI wymagają materiałów pochodzących
  z właściwego regionu,
- nowe stosy i egzemplarze wyposażenia przechodzą przez istniejący zapis i
  odczyt schematu `v6` bez dodawania pól trwałego stanu.

Etap 4C przenosi bazowy regionalny przedmiot i jego pełny obieg, ale jeszcze nie
losuje afiksów Equipment 2.0, nie aktywuje bonusów zestawów ani wyjątkowych
efektów klasowych późnego wyposażenia. Te mechaniki wymagają rozszerzenia
zapisywanej instancji przedmiotu i pozostają osobnym podetapem.

### Etap 4D — Equipment 2.0 (ukończony)

- 17 terminalowych afiksów podzielonych na pule ofensywną i defensywną; pas
  korzysta z obu pul z mnożnikiem wartości `0,75`,
- od zera do czterech unikalnych afiksów zależnie od rzadkości przedmiotu oraz
  pełne wartości T1–T5 dla Item Power I–IV i bezpieczne krzywe endgame,
- jakość źródła `normal`, `elite`, `miniboss`, `dungeon` lub `boss` przesuwa
  szanse tierów; łup używa rangi przeciwnika, a receptura może określić własną
  jakość wyposażenia,
- wszystkie premie płaskie, procentowe i odporności trafiają do statystyk
  bohatera; obrażenia umiejętności, przebicie pancerza oraz premie przeciw
  elitom i bossom działają w prawdziwej walce turowej,
- pełny czteroelementowy Zestaw Natury aktywuje `+1 ATK`, `+2 DEF`, `+10 PŻ`
  i `+15%` odporności na ziemię,
- trzy regionalne efekty klasowe: Odwet Pancerza Północy, Drapieżny Odruch
  Płaszcza Śnieżnego Gryfa oraz Przypływ Many Amuletu Czarnego Morza,
- placeholderowy panel szczegółów pokazuje Item Power, każdy afiks i jego tier,
  postęp zestawu, stan efektu klasowego oraz porównanie wszystkich nowych
  statystyk,
- schemat zapisu `v7` przechowuje i waliduje Item Power oraz afiksy każdego
  egzemplarza. Pliki `v1`–`v6` otrzymują stabilny, deterministyczny zestaw
  afiksów na podstawie `instance_id`, więc ponowne wczytanie nie zmienia łupu.

Etap nadal używa prostych paneli i tekstu. Nie dodaje finalnych ikon, grafik,
dźwięków ani animacji przedmiotów.

### Etap 4E — pogoda i obóz (ukończony)

- pięć terminalowych stanów pogody: Słonecznie, Burza, Mróz, Wichura oraz
  rzadka Zorza Polarna, losowanych z wagami `30/20/20/20/10`,
- jeden zegar świata przesuwający pogodę w sześciogodzinnych cyklach podczas
  wyprawy, noclegu i odpoczynku przy ognisku,
- zachowanie pogody z chwili rozpoczęcia spotkania, dzięki czemu zmiana po
  godzinnej wyprawie nie podmienia modyfikatorów już wylosowanego przeciwnika,
- wzmocnienia wszystkich przeciwników podczas Zorzy oraz osobne reguły Burzy,
  Mrozu i Wichury dla minibossów, razem z typami ich podstawowych obrażeń,
- premia Zorzy `+50%` do EXP, złota i szans tabeli łupów,
- darmowy odpoczynek polowy regenerujący `25%` maksymalnych PŻ i `35%`
  maksymalnej Many, zajmujący dwie godziny i odnawiany przez następną wyprawę,
- placeholderowy panel pogody i obozu na mapie świata oraz informacja o
  pogodzie spotkania na ekranie walki; bez finalnego tła i efektów pogodowych,
- schemat zapisu `v8`, który przechowuje pogodę, czas do kolejnego losowania i
  cooldown ogniska. Pliki `v1`–`v7` dostają bezpieczny stan Słonecznie na sześć
  godzin i dostępny odpoczynek.

Losowe elity, pogodowe bronie minibossów, bossowie regionalni i ich odradzanie
pozostają w następnych podetapach, ponieważ zależą od niewdrożonych jeszcze
liczników spotkań i osobnych tabel bossów.

### Następne podetapy

- elity, pogodowe bronie minibossów, bossowie i ich odradzanie,
- dane mapy oddzielone od widoku, aby miejsca można było rozbudowywać bez
  generowania jednej sztywnej ilustracji miasta albo regionu.

## Etap 5 — fabuła, Gildia i zadania

### Etap 5A — Akt I i rangi Gildii (ukończony)

- pełny, uporządkowany katalog dziewięciu zadań Aktu I „Ślady Przebudzenia” z
  terminalowymi poziomami, celami, nagrodami i łączną pulą `700` reputacji,
- jeden ogólny silnik zadań obsługujący cele zabójstw i zbierania, zużywane
  dowody oraz trofea zachowywane po oddaniu zadania,
- sekwencyjne odblokowywanie rozdziałów według poziomu i ukończenia
  poprzedniego zadania; nie można przyjąć rozdziału z pominięciem fabuły,
- rzeczywiste rangi Gildii od F — Nowicjusza do S — Legendy, wraz z dokładnymi
  progami reputacji `0/100/300/700/1400/2600/4500`,
- placeholderowa tablica Gildii pokazująca cały Akt I, stan każdego rozdziału,
  cel, nagrody, blokady oraz postęp do następnej rangi,
- aktywne zadanie i aktualna ranga są pokazywane dynamicznie w mieście, na
  mapie świata, po walce oraz w stopce aplikacji,
- walidacja zapisu obejmuje wszystkie rozdziały i ich kolejność. Istniejący
  schemat `v8` już przechowywał ogólne słowniki aktywnych i ukończonych zadań,
  dlatego nie wymaga dodania nowego pola.

Pierwszych pięć rozdziałów ma źródła celów w obecnie przemigrowanym świecie.
Cztery późne rozdziały są prawidłowo opisane i walidowane, lecz ich zależności
— Krypta Zatopionego Zakonu, bossowie regionalni oraz wrak Czarnej Floty —
zostają oznaczone na tablicy zamiast otrzymać fikcyjne skróty rozgrywki.

### Etap 5B — kontrakty dzienne i tygodniowe (ukończony)

- dokładnie trzy automatyczne kontrakty dzienne: polowanie na konkretny typ
  przeciwnika, dostawa materiałów oraz elitarne zagrożenie; przed poziomem 2
  ostatni typ jest zastępowany pierwszym patrolem,
- jeden kontrakt tygodniowy z celami regionalnymi, elitarnymi oraz minibossem
  albo lochem zależnie od poziomu postaci,
- generator korzystający z poziomu bohatera, pięciu przemigrowanych regionów,
  ich przeciwników i rzeczywistych tabel łupów; zestaw jest stabilny dla imienia
  postaci i okresu,
- Daily zmieniają się według lokalnego dnia kalendarzowego, a Weekly według
  tygodnia ISO rozpoczynającego się w poniedziałek. Restart oraz cofnięcie
  zegara nie pozwalają przerzucać tablicy,
- cele zabójstw, regionów i minibossów aktualizują się po prawdziwej walce,
  zaś postęp dostawy jest liczony bezpośrednio z plecaka,
- dostawy są zużywane dopiero po pełnej walidacji, a nagrody EXP, złota,
  przedmiotu i reputacji (`+15` Daily, `+75` Weekly) można odebrać tylko raz,
- Daily wymagają rangi E — Adept, a Weekly rangi D — Poszukiwacz,
- placeholderowa tablica Gildii ma osobne widoki fabuły, Daily i Weekly, pokazuje
  wszystkie cele, ich postęp, okres resetu, nagrody oraz wymagania rangi,
- cele losowych elit i lochów zachowują oryginalną definicję, ale są oznaczone
  jako zależności etapów świata 4F i lochów 6 zamiast otrzymać sztuczne źródła,
- schemat zapisu `v9` przechowuje wygenerowane definicje, okresy, postęp i
  odebrane nagrody. Pliki `v1`–`v8` otrzymują pustą, bezpieczną tablicę, która
  zostaje wygenerowana przy następnym wejściu do Gildii albo rozpoczęciu wyprawy.

### Etap 5C — kamienie milowe, plotki i Dziennik Przygód (ukończony)

- cztery terminalowe kamienie milowe świata przyznają jednorazowo dokładnie
  `100/150/150/250` reputacji za Azhara, Lewiatana Północy, Kryptę
  Zatopionego Zakonu oraz Wrak Czarnej Floty,
- powtórzenie zdarzenia nie nalicza reputacji ponownie, a zmiana rangi zostaje
  zapisana jako osobne wydarzenie,
- katalog zachowuje wszystkie `32` plotki z wersji terminalowej i filtruje je
  według rangi, odblokowania Czarnego Rynku oraz trwałych kamieni milowych,
- placeholderowa Gildia ma osobne widoki kamieni i dostępnych plotek; zależne
  walki z bossami i lochy są jawnie opisane jako późniejsze źródła zamiast
  otrzymać sztuczne przyciski nagród,
- Dziennik Przygód zapisuje wpisy z dniem i godziną, pokazuje ostatnie `30`
  oraz zachowuje maksymalnie `50` najnowszych wydarzeń,
- walki, pogoda, odpoczynek, crafting, handel, ulepszanie, zadania, kontrakty,
  prolog i zmiany reputacji korzystają ze wspólnego API dziennika,
- osobny placeholderowy ekran Dziennika jest dostępny z pionowego planu
  Varenhold bez używania terminala,
- schemat zapisu `v10` przechowuje kamienie milowe i wpisy dziennika, odrzuca
  nieznane lub powtórzone identyfikatory oraz przekroczenie limitu. Pliki
  `v1`–`v9` otrzymują bezpieczny pusty stan tych dwóch systemów.

Bossowie regionalni i lochy nadal należą odpowiednio do etapu świata 4F i
etapu 6. Warstwa 5C udostępnia ich docelowe, testowane punkty integracji, ale nie
udaje nieistniejących jeszcze zwycięstw.

### Etap 5D — informator i Czarny Rynek (ukończony)

- informator wymaga rangi C oraz trwałego kamienia za Kryptę Zatopionego
  Zakonu albo Wrak Czarnej Floty,
- każdy kwalifikujący dzień Pythonii wykonuje tylko jedną próbę `20%`;
  ponowne wejście do Karczmy nie przerzuca wyniku, a po czterech porażkach
  piąty dzień jest gwarantowany,
- rozmowa z informatorem permanentnie odblokowuje kafelek Czarnego Rynku w
  pionowym planie Varenhold i zapisuje wydarzenie w Dzienniku Przygód,
- dzienna rotacja według realnej daty zawiera dokładnie cztery jednorazowe
  oferty i jest deterministyczna dla imienia bohatera oraz daty, więc restart
  nie zmienia dostawy,
- łączna szansa na księgę wynosi `55%`: `8%` na Księgę Ścieżki i `47%`
  na Księgę Mistrzostwa; pozostałe miejsca wypełnia siedem terminalowych
  rzadkich materiałów i przedmiotów zużywalnych,
- wszystkie osiem ksiąg można sprzedawać po jednej sztuce,
- targowanie ma bazową szansę `30%` i tylko jedną próbę na ofertę albo
  tytuł księgi w dostawie; sukces i porażka stosują terminalowe przedziały
  `-10–15%/+5–10%` dla zakupu oraz `+10–15%/-5–10%` dla sprzedaży,
- wynik sprawdzenia informatora, odblokowanie, rotacja, negocjacje i transakcje
  wywołują natychmiastowy zapis zamiast pozwalać na przerzut restartem,
- osobny placeholderowy ekran pozwala przeglądać ofertę, kupować, sprzedawać
  księgi i negocjować bez używania terminala,
- schemat zapisu `v11` przechowuje pełny stan informatora i rynku, waliduje
  definicje i ceny ofert, wykupione pozycje oraz wyniki negocjacji. Pliki
  `v1`–`v10` otrzymują bezpieczny, zablokowany stan rynku.

Naturalne spotkanie informatora pozostaje zależne od lochów z etapu 6. Etap
5D nie dodaje przycisku omijającego ten warunek; dostarcza kompletny przepływ,
który uruchomi się po zdobyciu prawdziwego kamienia milowego.

### Etap 5E — osiągnięcia, tytuły i audyt Gildii (ukończony)

- przeniesiono dokładnie siedem osiągnięć terminalowych wraz z opisami i
  nagradzanymi tytułami; domyślnym tytułem pozostaje `Wędrowiec`,
- zwycięstwa odblokowują `Pierwszą krew`, osiągnięcia Strażnika Natury,
  Leśnego Egzekutora i Matki Głuchej Wody oraz `Pod Zorzą` przy pogodzie
  Zorza Polarna; każde osiągnięcie jest nadawane tylko raz,
- ulepszenie dowolnego przedmiotu do `+10` odblokowuje `Mistrza Kowadła`, a
  osiągnięcie rangi S — Legenda odblokowuje `Weterana Gildii`,
- przy wczytywaniu i zapisie jednoznaczny istniejący progres (`+10` i ranga S)
  jest uzgadniany, dzięki czemu starszy stan nie traci należnej nagrody,
- osobny placeholderowy ekran w planie Varenhold pokazuje postęp `x/7`, status,
  opis i nagrodę oraz pozwala wybrać wyłącznie odblokowany tytuł; wybór zapisuje
  się natychmiast i pojawia przy imieniu bohatera,
- schemat zapisu `v12` przechowuje listę osiągnięć i aktywny tytuł, odrzuca
  nieznane i powtórzone identyfikatory oraz tytuły bez osiągnięcia; pliki
  `v1`–`v11` otrzymują bezpieczny pusty stan z tytułem `Wędrowiec`,
- końcowy audyt etapu 5 zabezpiecza testami progi rang F–S, dziewięć zadań
  Aktu I i ich 700 reputacji, nagrody kontraktów `15/75`, cztery kamienie
  milowe warte 650, 32 plotki, warunki Czarnego Rynku i siedem osiągnięć.

Etap 5 jest domknięty domenowo. Zależności fabularnych zadań, informatora oraz
kamieni milowych prowadzące do lochów pozostają jawnie zablokowane do etapu 6;
5E nie dodaje zastępczych przycisków ani fikcyjnych zwycięstw.

Dialogic pozostaje wyłącznie warstwą prezentacji rozmów; stan misji i wszystkie
nagrody należą do testowanej logiki domenowej.

## Etap 6 — lochy, drużyna i Szczeliny

### Etap 6A — fundament kompanów i drużyny (ukończony)

- jawne modele `CompanionState` oraz `PartyState` są właścicielami stanu
  konkretnego kompana i całego rosteru zamiast luźnych pól w `GameSession`,
- katalog zachowuje 12 ręcznie napisanych szablonów v0.24.7, ich dozwolone
  klasy, pochodzenie, głos, nastawienie i minimalną rangę Gildii,
- osobny serwis egzekwuje limit 4 kompanów, 3 aktywnych, tryb SOLO oraz blokady
  dla poległych, ciężko rannych i trwającej ekspedycji,
- placeholder „Drużyna i kompani” jest dostępny z Gildii i wywołuje serwis
  domenowy zamiast samodzielnie zmieniać reguły składu,
- `EquipmentSaveCodec` współdzieli reguły instancji sprzętu, a
  `PartySaveCodec` przechowuje kompanów, kandydatów, wiadomości, własność
  przedmiotów, prywatny schowek i Tablicę Poległych,
- schemat Godot `v13` dodaje `party`; pliki `v1`–`v12` migrują z pustym stanem
  bez aktywowania niepełnego importu terminalowego save v15.

### Etap 6B — rekrutacja, relacje i historie kompanów (ukończony)

- dzienna rotacja zachowuje terminalowy limit dwóch kandydatów, wymagania rang
  F–S, przedział poziomów, zwykłe i rzadkie ścieżki oraz zapisany rzut
  rekrutacyjny; ponowne wejście i restart tego samego dnia nie przerzucają
  oferty ani wyniku,
- wszystkie pierwsze rozmowy, odpowiedzi rekrutacyjne, pożegnania, wiadomości,
  wypowiedzi bezczynności i obozowe są ręcznie przeniesione z v0.24.7;
  rozmowa zmienia nastawienie tylko raz, a próba rekrutacji jest jednorazowa,
- rekrutacja egzekwuje limit czterech kompanów, automatycznie uzupełnia wolne
  miejsce aktywnej trójki i pozostawia odrzuconego kandydata bez kolejnej próby
  tego dnia,
- rozstanie zachowuje relację, wspomnienia i postęp osobistej historii; były
  kompan może ponownie wejść do deterministycznej rotacji najwcześniej po
  trzech dniach Pythonii,
- `CompanionRelationshipService` jest właścicielem relacji, unikalnych tagów
  pamięci, dziennych wiadomości, stanu przeczytania, jednorazowych scenek par,
  scenek obozowych i integracyjnego postępu wspólnych Szczelin,
- jawne modele `CompanionPersonalArc`, `CompanionQuestStage` oraz
  `CompanionDialogueChoice` przechowują wszystkie 16 ręcznie napisanych
  wariantów historii dla 12 kompanów. Kolejne etapy wymagają odpowiednio
  `0/1/2` wspólnie zamkniętych Szczelin i nie mogą przyznać relacji ani
  wspomnienia ponownie po zapisie i odczycie,
- istniejący ekran „Drużyna i kompani” ma zakładki rosteru, kandydatów i
  wiadomości oraz pozwala rozmawiać, rekrutować, czytać wiadomości i wybierać
  odpowiedzi w historii bez przenoszenia reguł domenowych do UI,
- `PartySaveCodec` w schemacie `v13` już posiadał wszystkie potrzebne pola.
  Etap nie podnosi wersji schematu, lecz dodatkowo waliduje limit kandydatów,
  identyfikatory wątków, ich etapy i dozwolone tagi pamięci.

Pełne buildy, rozwój oraz osobiste i powierzone wyposażenie kandydatów należą
do 6C. 6B nie tworzy ich przedwcześnie i nie dodaje zastępczych przedmiotów.
Prezentacja nadal używa prostych paneli i tekstu bez finalnych assetów.

#### Kontrakt RNG po Stage 6B

- Stage 6 zachowuje parytet reguł, deterministyczność po stronie Godota,
  stabilność po save/load i ochronę przed ponownym losowaniem, ale nie wymaga
  bitowo identycznego strumienia RNG z Pythonowym `random.Random`/MT19937.
- Golden testy zamrażają Godotową tożsamość, kolejność, ścieżkę, historię i
  `recruitment_roll` kandydatów 6B. Generatory dodawane w 6C muszą korzystać z
  osobnych, nazwanych substreamów i nie mogą konsumować ani zmieniać strumienia
  generatora 6B.
- Przyszły importer terminalowego save v15 ma odczytywać pełne zapisane stany
  kandydatów i kompanów. Nie wolno mu regenerować tych wyników na podstawie
  terminalowego seeda.

Przed ukończeniem pełnego buildu kompana w 6C trzeba jawnie rozstrzygnąć
semantykę `current_hp`: terminalowy nowy kandydat zaczyna z `current_hp = 0`, a
wartość `<= 0` oznacza inicjalizację do pełnego HP przy tworzeniu combatanta.
Godot musi uzyskać jednoznaczny odpowiednik po wygenerowaniu buildu bez zmiany
globalnego defaultu `CompanionState.current_hp` w fundamencie 6A.

### Etap 6C — rozwój i osobiste wyposażenie kompanów (ukończony)

- `CompanionBuildService` odtwarza terminalowe rozłożenie `4 × poziom`
  punktów atrybutów, przydział punktów obu drzewek, klasową progresję broni i
  drugiej ręki, pule zwykłych slotów, ulepszenia, afiksy oraz rzadkie unikaty
  Szczelin. Rozwój po zdobyciu EXP korzysta z tej samej krzywej poziomów,
  dodaje cztery atrybuty na poziom i rozwija główną ścieżkę kompana,
- atrybuty, talenty i wyposażenie mają trzy osobne nazwane substreamy RNG.
  Powstają dopiero po ustaleniu wszystkich pól objętych snapshotami 6B, więc
  nie zmieniają klasy, poziomu, ścieżki, ID, historii ani rzutu rekrutacji,
- `current_hp = 0` i `current_mana = 0` są jawnymi sentinelami nowego buildu i
  po awansie. `resolved_resources()` zamienia wartości `<= 0` na wyliczone
  maksimum przy tworzeniu profilu walki, zachowując globalny default 6A,
- `CompanionEquipmentService` jest właścicielem przekazywania sprzętu,
  walidacji poziomu i klasy oraz rozróżnienia osobistego przedmiotu kompana od
  przedmiotu gracza. Osobisty przedmiot zastąpiony w slocie trafia do prywatnego
  schowka i wraca po odebraniu przedmiotu gracza,
- `dismiss_companion` najpierw atomowo zwraca wszystkie player-owned items do
  plecaka i odtwarza osobiste sloty. Osobny test regresyjny zabezpiecza przed
  utratą sprzętu podczas rozstania,
- istniejący ekran „Drużyna i kompani” pokazuje build, zasoby, atrybuty,
  talenty i dwie listy wyposażenia oraz wywołuje wyłącznie serwisy domenowe,
- schemat pozostaje `v13`: kodeki 6A już przechowywały pełny stan buildu i
  własności. Odczyt akceptuje brak nowego opcjonalnego rolla broni
  sygnaturowej, a zapis 6B z pustym buildem jest deterministycznie uzupełniany
  przy pierwszym wejściu bez zmiany zapisanej rotacji kandydatów.

### Etap 6D — przygotowanie do wyprawy i presety (ukończony)

- audyt `systems/expedition_preparation.py`, `ui/expedition_prep_view.py` oraz
  przepływu w `game/application.py` potwierdził, że 6D jest oddzielnym
  subsystemem przygotowania, a nie częścią mapy, UI drużyny ani przyszłego AI,
- jawne modele `ExpeditionPreparationState` i `ExpeditionPreset` przechowują
  wybrany region oraz cztery terminalowe presety `SOLO`, `BOSS`, `DUNGEON` i
  `SZCZELINA`; preset zapisuje skład i docelowe ilości zapasów, nie stan
  chwilowego formularza UI,
- `ExpeditionPreparationService` wybiera wyłącznie znane regiony, tworzy,
  stosuje i czyści presety, generuje ostrzeżenia oraz waliduje wyruszenie;
  ekran tylko przekazuje input i prezentuje wynik,
- zastosowanie presetu oblicza cały transfer przed mutacją. Pobiera z Magazynu
  Gildii wyłącznie brakujące sztuki, raportuje niedobory, nigdy nie tworzy
  przedmiotów i nie zmienia składu ani zapasów, jeżeli transfer przekroczyłby
  udźwig,
- aktywny skład pokazuje PŻ, Manę i wybraną taktykę kompanów. 6D nie interpretuje
  taktyki i nie dodaje zachowania AI, które pozostaje wyłączną odpowiedzialnością
  6E,
- przed wyprawą można pobrać zapasy z Magazynu i użyć mikstury lub prowiantu.
  Wspólny `ConsumableService` zachowuje zasadę terminalową, że przedmiot nie jest
  zużywany, jeżeli nie odnowiłby ani jednego punktu PŻ lub Many,
- przeciążenie jest twardą blokadą wyruszenia. Niskie PŻ, brak leczenia oraz
  ciężko ranni kompani są jawnymi ostrzeżeniami, które gracz może potwierdzić
  świadomie drugim kliknięciem,
- placeholderowy ekran jest dostępny zarówno z Bramy Zachodniej, jak i kafelka
  przygotowania. Zawiera szybkie przejścia do istniejącej drużyny, ekwipunku,
  Magazynu Gildii i Karczmy, bez tworzenia drugiego hubu tych systemów,
- osobny `ExpeditionPreparationSaveCodec` utrzymuje walidację poza
  `SaveGameService`. Schemat Godota `v14` zapisuje cel oraz komplet presetów;
  pliki `v1`–`v13` migrują do pustego, bezpiecznego stanu przygotowania.

6D nie uruchamia taktyk AI, walki drużynowej, lochów ani Szczelin. Oficjalne
wejście do otwartego świata przechodzi przez przygotowanie, po czym korzysta z
istniejącej mapy i `AdventureService` bez duplikowania zasad eksploracji.

### Etap 6E — taktyki AI kompanów (ukończony)

- audyt `systems/companions.py`, `systems/rift_combat.py` i terminalowych modeli
  potwierdził cztery zapisane taktyki: Agresywną, Zrównoważoną, Ostrożną oraz
  Obronną. `CompanionTacticService` jest ich właścicielem domenowym; UI jedynie
  przekazuje wybrany kod i prezentuje opis,
- `CompanionAiContext` oddziela politykę AI od przyszłego silnika walki. Zawiera
  bieżące PŻ/Manę oraz zasoby stojących członków drużyny, ale nie wykonuje akcji,
  nie mutuje walki i nie przyznaje żadnych rezultatów,
- wybór AI zachowuje terminalowe progi: Obronna reaguje poniżej 80% PŻ lub na
  członka drużyny poniżej 35% PŻ, Ostrożna broni się poniżej 50% PŻ i nie zużywa
  skilla poniżej 25% Many. Porównania pozostają ścisłe (`<`), także na granicach,
- Agresywna wybiera najsilniejszy dostępny skill ofensywny według
  `multiplier × max(1, hits)`. Zrównoważona i Ostrożna zachowują tożsamość klas:
  Łowca losuje odblokowaną technikę, Pierrot losuje skill Losu, a pozostałe
  klasy wybierają najsilniejszy dostępny fallback,
- Ciężki Rycerz z odpowiednimi talentami priorytetowo używa Prowokacji, gdy
  drużyna jest zagrożona, zarówno przy taktyce Obronnej, jak i Zrównoważonej,
- RNG jest jawnie wstrzykiwany przez przyszły subsystem walki, dzięki czemu
  decyzje są deterministyczne w testach. Pusty identyfikator skilla stanowi
  jawny kontrakt ataku podstawowego dla 6F,
- `SkillCatalog` potrafi wyliczyć skille kompana bez tworzenia adaptera gracza,
  uwzględniając poziom, klasę i aktywne skille odblokowane talentami,
- istniejący ekran „Drużyna i kompani” otrzymał wybór taktyki i jej opis bez
  tworzenia nowego hubu oraz bez przeniesienia decyzji AI do UI,
- schemat pozostaje `v14`, ponieważ `PartySaveCodec` już zapisuje i waliduje kod
  taktyki. Test regresyjny potwierdza zachowanie ustawienia po save/load.

6E nie wykonuje tur, obrażeń, statusów ani akcji kompanów. Wspólne reguły
obrażeń i osobny silnik walki drużynowej pozostają wyłącznym zakresem 6F.

### Etap 6F — osobny silnik walki drużynowej (ukończony)

- audyt `systems/rift_combat.py`, `combat/damage.py`, adaptera
  `companion_to_player()` i istniejącego Godotowego `TurnBasedCombatEngine`
  potwierdził, że walka drużynowa musi pozostać osobnym subsystemem. Dotychczasowy
  silnik 1v1 nie przejął składu drużyny, AI kompanów ani zasad Szczelin,
- `CombatDamageRules` wydziela bezstanowe, współdzielone obliczenia minimum
  obrażeń, penetracji pancerza, redukcji Obrony, mnożników z Pythonowym
  half-even rounding i rzutów procentowych. `CombatHitResolver` oraz zwykły
  `TurnBasedCombatEngine` używają tych helperów bez zmiany dotychczasowych
  rezultatów 1v1,
- nowy `PartyCombatEngine` zachowuje terminalową kolejność rundy: akcja gracza,
  akcje stojących kompanów w kolejności składu, krwawienie i akcja przeciwnika.
  Obsługuje atak, Obronę, odblokowane skille, skorygowany koszt Many, fallback do
  ataku podstawowego, krytyki, penetrację, Krwawienie, obniżenie DEF, techniki i
  kombinacje Łowcy, Kości Losu Pierrota, Podwójny Splot, Prowokację oraz furię
  bossa poniżej 35% PŻ,
- `PartyCombatant` jest adapterem bohatera lub `CompanionState` do jednej walki.
  Dla kompana wylicza profil z jego atrybutów, talentów i osobistego wyposażenia,
  rozwiązuje terminalowe sentinele PŻ/Many, a po rundzie synchronizuje zasoby z
  powrotem do jawnego stanu kompana,
- `PartyCombatRoundResult` przenosi wynik domenowy bez zależności od UI: linie
  raportu, kolejność AI, wybrane skille, cele i obrażenia przeciwnika oraz stan
  zwycięstwa/porażki. RNG jest wstrzykiwany, więc pełna runda pozostaje
  powtarzalna w testach,
- zachowano terminalową semantykę overkill: raport pokazuje wyliczone obrażenia,
  a przechowywane PŻ przeciwnika jest ograniczone do zera. Katalog efektów
  klasowych rozpoznaje wszystkie 16 Unikatów Szczelin z v0.24.7; silnik 6F
  wykonuje dokładnie te ich interakcje, które wykonuje terminalowy
  `RiftBattleEngine`,
- nie utworzono sztucznej areny ani wejścia UI. Legalny przepływ walki
  drużynowej zostanie podłączony dopiero do lifecycle Szczelin w 6I/6J, dzięki
  czemu ekran nie będzie generował nagród ani stanu wyprawy poza subsystemem,
- 6F nie implementuje powalenia, pomocy, ciężkich ran ani śmierci. Kompan z
  zerowym PŻ przestaje wykonywać akcje, ale jego `dead` i `injury_until_day`
  pozostają nietknięte; jawne zagrożenia i konsekwencje należą wyłącznie do 6G,
- schemat zapisu pozostaje `v14`: stan walki jest chwilowy, a utrwalane PŻ/Many,
  taktyki i wyposażenie kompanów były już własnością kodeków Stage 6A–6D.

### Etap 6G — Powalenie, ciężkie rany i jawna Egzekucja (ukończony)

- `PartyCombatant` przechowuje chwilowe `downed_timer`, `removed` i
  `lethal_downed`, a `PartyCombatRoundResult` jawnie raportuje uratowanych,
  pomagających, pozostałe liczniki, ciężko rannych i poległych. Stan jednej walki
  nadal nie przecieka do `CompanionState` ani do UI,
- zwykłe Powalenie daje 4 rundy na pomoc i po wyczerpaniu licznika kończy się
  stanem `CIĘŻKO RANNY`. Gracz podnosi kompana do 28% PŻ, a pierwszy zdolny
  kompan rezygnuje z własnego ataku, aby podnieść Powalonego bohatera do 25% PŻ,
- permanentna śmierć nie wykonuje żadnego rzutu RNG. Wyłącznie boss Szczeliny
  rangi B, A albo S może oznaczyć Powalonego kompana jawnym komunikatem
  `EGZEKUCJA` i licznikiem 3 rund. Pomoc albo zakończenie walki przerywa
  zagrożenie; dopiero wyzerowanie widocznego licznika raportuje śmierć,
- audyt ujawnił błąd wykonywalnej specyfikacji v0.24.7: podstawowy atak
  Powalonego gracza odrzucał akcję przed turą automatycznej pomocy, natomiast
  skill i Obrona mogły wykonać nielegalną akcję przed podniesieniem. Migracja 1:1
  powodowałaby odpowiednio zakleszczenie albo działanie mimo Powalenia. Godot
  rozwiązuje to jednym jawnym `player_wait_for_help()`; próba zwykłej akcji w
  tym stanie wyłącznie przesuwa rundę do reakcji kompanów i sama nie atakuje,
- osobny `CompanionCasualtyService` stosuje wynik poza silnikiem i poza UI.
  Tylko długość ciężkiej rany korzysta ze wstrzykniętego RNG (2–5 dni Pythonii);
  ścieżka Egzekucji nie konsumuje RNG, atomowo zwraca całe wyposażenie należące
  do gracza, usuwa kompana z rosteru, zapisuje wpis Tablicy Poległych oraz
  ręcznie napisaną reakcję ocalałego,
- istniejący ekran „Drużyna i kompani” otrzymał zakładkę Tablicy Poległych oraz
  zachowuje określenie `Powrót do sił`. Upływ dnia czyści zakończone ciężkie
  rany przez serwis domenowy,
- istniejący `PartySaveCodec` z etapu 6A już przechowuje `injury_until_day`,
  zasoby, wiadomości i pełne wpisy poległych, dlatego schemat pozostaje `v14`.
  Liczniki Powalenia są celowo stanem chwilowej walki i nie są zapisywane.

### Etap 6H — dwa terminalowe lochy SOLO (ukończony)

- `DungeonCatalog`, `DungeonRunState` i `DungeonService` przenoszą Kryptę
  Zatopionego Zakonu oraz Wrak Czarnej Floty jako osobny subsystem. Przebieg
  pozostaje SOLO i korzysta ze zwykłego `TurnBasedCombatEngine`; nie importuje
  ani `PartyCombatEngine`, ani przyszłego lifecycle Szczelin,
- oba lochy zachowują terminalowe wejściówki zużywane atomowo, poziomy
  rekomendowane, trzy losowe komnaty, osobne rozwidlenia, obowiązkową elitę,
  finałowego bossa, godzinę za każde starcie oraz dodatkową godzinę za skrzynię
  w zalanym korytarzu lub Skarbiec Czarnej Floty,
- PŻ i Mana przechodzą między walkami. Zatopiona Kaplica przywraca 25%, Kajuta
  Medyka 30%, z Pythonowym zaokrągleniem half-even. Pogoda powierzchni przesuwa
  się wraz z czasem świata, lecz nie modyfikuje walk ani nagród w lochu,
- bezpieczny odwrót i ucieczka zachowują cały łup. Snapshot wykonany po zużyciu
  wejściówki pozwala porażce usunąć wyłącznie dodatnie przyrosty stosów i nowe
  instancje wyposażenia z tej wyprawy; zdobyte EXP i złoto pozostają, a bohater
  odzyskuje pełne zasoby,
- dwanaście brakujących przeciwników, ich terminalowe statystyki, odporności i
  tabele łupu zostały dodane wraz z materiałami Krypty i fragmentem szabli
  Vareka. Sprzęt wypada z jakością `dungeon`, a Strażnicy i bossowie zachowują
  szanse na Księgi Mistrzostwa oraz Księgi Ścieżki,
- `GrandMasterCombatEngine` zachowuje fazy 60%/25% i wodną aurę, a
  `AdmiralVarekCombatEngine` zapowiadaną Salwę Armatnią oraz fazę Ostatniego
  Rozkazu. Są to wąskie podklasy zwykłej walki 1v1, nie rozszerzenie walki
  drużynowej,
- ukończenie korzysta z istniejących punktów integracji kontraktów i kamieni
  milowych Gildii. Przejściowy przebieg lochu nie jest zapisywany — tak jak w
  terminalu zapis następuje po jego zakończeniu — więc schema pozostaje `v14`,
- placeholder lochu jest dostępny z właściwego regionu mapy, zawiera pełny
  przepływ decyzji i nie posiada finalnych assetów. Testy obejmują oba pełne
  warianty, SOLO, wejście, snapshot łupu, odwrót, porażkę, odpoczynek, czas,
  bossów, nagrody i integrację UI.

### Etap 6I — lifecycle Szczelin (ukończony)

- `RiftState`, `RiftInstance`, `RiftExpedition` oraz `RiftModifier` przenoszą
  trwały kontrakt terminalowej v0.24.7 bez luźnych pól w `GameSession`.
  `RiftCatalog` zachowuje rangi F–S, długości 12–24 segmentów, wymagania dwóch
  albo trzech kompanów, pięć motywów, sześć anomalii, bossów i pięć nazw innych
  drużyn Poszukiwaczy,
- `RiftLifecycleService` jest jedynym właścicielem pojawiania się alarmu,
  czasu życia 2–4 dni, ważenia rangi względem rangi Gildii, deterministycznego
  przejęcia wygasłej Szczeliny i odstępów między kolejnymi alarmami. Generator
  zachowuje parytet reguł oraz deterministyczność Godota; zgodnie z decyzją 6B
  nie próbuje odtwarzać bitowego strumienia Pythonowego `random.Random`,
- rozpoczęcie sprawdza rangę Gildii i rzeczywistą liczbę aktywnych kompanów,
  po czym zapisuje dokładne ID związanego składu. Aktywna ekspedycja chroni
  Szczelinę przed innymi drużynami nawet po terminie alarmu. Porzucenie usuwa
  rezerwację, a wygasły alarm może zostać natychmiast rozstrzygnięty przez świat,
- związany skład blokuje aktywowanie/dezaktywowanie kompanów, tryb SOLO,
  rekrutację, rozstanie, zastosowanie presetu i zwykłe wyjście na wyprawę.
  Sprzęt, taktyki, rozmowy i inne operacje, których terminal nie blokował, nie
  otrzymały sztucznych ograniczeń,
- osobny `RiftSaveCodec` przechowuje alarm, rezerwację, terminy, komunikat oraz
  historię zamknięć według rang. Godotowy schemat wzrasta z `v14` do `v15`, a
  wcześniejsze zapisy otrzymują pusty `RiftState` z `next_spawn_day = 2`.
  Jest to nadal format Godota i nie aktywuje importu terminalowego save v15,
- w Gildii działa placeholder „Alarmy Szczelin”, pokazujący motyw, anomalie,
  Władcę, termin, wymagania i związany skład. Może utworzyć albo po dwukrotnym
  potwierdzeniu porzucić rezerwację, lecz nie wykonuje segmentów, nie przyznaje
  nagród, nie zamyka Szczeliny i nie uruchamia `PartyCombatEngine`,
- testy obejmują deterministyczność, harmonogram, wygaśnięcie, ochronę aktywnej
  ekspedycji, bramki rangi/składu, blokady, porzucenie, save/load, migrację v14,
  walidację kodeka i nawigację UI.

### Dalsza kolejność Stage 6

- **6J:** kompletne ekspedycje i walki drużynowe Szczelin,
- **6K:** audyt parytetu Stage 6 i save/load.

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
