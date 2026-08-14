# v0.23.0 — Classes 2.0

## Cel

Aktualizacja nadaje każdej klasie własny rytm walki zamiast różnicować je wyłącznie mnożnikami obrażeń. Stare skille Wojownika, Łowcy i Maga pozostają bazą, a nowe drzewka rozwijają je i dodają specjalizacje. Ciężki Rycerz jest specjalizacją Wojownika; jedyną nową klasą jest Pierrot.

## Punkty drzewka

- poziom 5 / wybór klasy: 1 punkt,
- następnie +1 punkt co 2 poziomy,
- poziom 18: 8 punktów łącznie,
- każda ranga talentu kosztuje 1 punkt,
- reset: `1000 + 250 × liczba wydanych punktów` Gold,
- reset nie usuwa przeczytanych Ksiąg Ścieżki.

## Wojownik

### Natarcie

Rozwija Furię Bitewną, Głębokie Rany, Łamacza, Egzekutora i Nieustępliwego. Jest dostępne bez księgi.

### Ciężki Rycerz

Wymaga **Traktatu Ciężkiego Rycerza**. Rdzeń aktywuje nazwę specjalizacji. Tarcza daje bazowy Blok; drzewko rozwija Mistrza Tarczy, Uderzenie Tarczą, Żelazną Kontrę, Prowokację i Bastion. Uderzenie Tarczą skaluje się z ATK + 60% DEF, kontra z 70% DEF, a Obrona z Bastionem przygotowuje Odwet o sile 75% DEF.

## Łowca

Łowca używa Łuku i nie zużywa liczonych sztuk amunicji. Specjalne strzały są technikami nakładanymi na zwykły pocisk.

### Mistrz Salwy

Techniki: Krwawa, Przebijająca, Lodowa, Wybuchowa, Widmowa, Deszcz Strzał i Rozszczepiająca. Co trzy techniki powstaje sekwencja. Nazwane układy uruchamiają dodatkowy Finisher oraz zapisują odkrycie w Księdze Kombinacji.

- **Szkarłatna Egzekucja** — Krwawa → Krwawa → Krwawa,
- **Kruche Rozerwanie** — Lodowa → Lodowa → Wybuchowa,
- **Widmowa Detonacja** — Wybuchowa → Widmowa → Wybuchowa,
- **Parada Widm** — Widmowa → Widmowa → Widmowa,
- **Burza Przebicia** — Deszcz Strzał → Przebijająca → Rozszczepiająca,
- **Szkarłatne Widmo** — Krwawa → Widmowa → Przebijająca.

Widmowa Strzała zadaje pierwsze trafienie od razu i zostawia Echo, które materializuje się po następnej akcji Łowcy. Deszcz Strzał jest opóźnioną salwą. Wybuchowa Strzała buduje do 3 ładunków i detonuje trzeci.

### Widmowy Strzelec

Wymaga **Kroniki Widmowego Strzelca**. Rozwija moc Echa, tworzy Widmowe Łuki powtarzające część Finishera i odblokowuje `Tysiąc Strzał`.

## Mag

Mag wymaga Kostura do aktywnych zaklęć.

### Żywioły

Serce Ognia, Wieczny Mróz i Głos Burzy zwiększają moc odpowiednich skilli. Cykl Żywiołów wzmacnia trzeci kolejny różny żywioł.

### Arkana

Wymagają **Grimuaru Podwójnego Splotu**. `Splot Magii` rośnie do 3/3 po ofensywnych zaklęciach. Przy 3/3 Podwójny Splot pozwala wybrać dwa ofensywne zaklęcia i rzucić je w jednej turze. Przeciwnik odpowiada dopiero po obu. Drugie zaklęcie ma 80% mocy; kolejne talenty zmniejszają koszt o 25%, zwiększają moc do 95% i pozwalają odzyskać 4 Many.

## Pierrot

Pierrot jest nową klasą. Używa Lancy Losu oraz własnego atrybutu **Szczęście**. Szczęście nie sprawia, że kość zawsze wyrzuca 6; wzmacnia sposób, w jaki Pierrot wykorzystuje wynik. Zasobem walki są **Żetony Losu**.

### Fate Engine

Rzuty i manipulacje Pierrota przechodzą przez jeden moduł `combat/fate.py`. Silnik przechowuje historię rzutów oraz obsługuje Dociążoną Kość, Drugą Szansę i Kant.

Podstawowe skille:

- **Pchnięcie Losu** — 1k6; każda ścianka ma inny rezultat,
- **Podwójny Rzut** — 2k6; obsługuje dublety, Wężowe Oczy, Szczęśliwą Siódemkę i podwójną szóstkę,
- **Błazeński Unik** — obronny k6; od Uniku po przygotowanie odbicia,
- **Wielki Zakład** — 3k6; skrajne sumy, dublety i trójki,
- **Va Banque** — talent Chaosu zużywający wszystkie Żetony Losu.

### Chaos

Zwiększa skrajność wyników: Dziki Rzut, Krzywe Zwierciadło, Podwójna Stawka, Efekt Domina i Va Banque. Krzywe Zwierciadło może sprawić, że następny bezpośredni atak przeciwnika zada 0 graczowi i wróci do atakującego.

### Fortuna

Wymaga **Księgi Fortuny**. Jest sztuką kontroli przypadku: Dociążona Kość, Kant, Druga Szansa i Wybraniec Fortuny.

## Księgi Ścieżki

Pierwsza pula: Heavy Knight / Phantom Archer / Arcana / Fortuna. Boss losuje wyłącznie to, czy wypadła Księga Ścieżki; konkretny tytuł pochodzi później ze wspólnej puli. Szanse: 0,5% boss regionu, 1% ważny miniboss/elite dungeonu, 2% boss dungeonu. Książkę innej klasy można zachować i sprzedać na Czarnym Rynku.

## Pasywki 10/10

Po osiągnięciu 10/10 i posiadaniu Mistrzostwa można wybrać jedną z dwóch specjalizacji:

- Regeneracja: Żelazna Wola / Drugi Oddech,
- Szybkość Ataku: Nawałnica Ciosów / Zabójcze Tempo,
- Krytyki: Precyzja / Egzekucja,
- Atak: Surowa Siła / Rozpęd.

## Wyposażenie klasowe

OFF-HAND: Tarcza / Kołczan / Artefakt / Kości lub Talia Kart. Bronie klasowe są twardziej związane z klasą, ponieważ aktywne mechaniki ich wymagają. Stare ogólne przedmioty pozostają w grze bez retroaktywnego przerabiania. Nowy sprzęt klasowy jest drop-only.

Łowca, Mag i Pierrot mają regionalne pule Łuków, Kosturów i Lanc Losu dla Czarnego Boru, Mokradeł, Popielnego Pogranicza i Lodowego Wybrzeża. Wojownik zachowuje istniejącą szeroką linię mieczy/toporów/szabli.

## Warsztat i lore

Warsztat Mireli ma sześć widoków kategorii, w tym `Wszystkie receptury`. Sprzęt klasowy nie jest dodawany do craftingu. Gildia otrzymała plotki zależne od rangi i progresji, a królewski zakaz handlu księgami stał się fabularnym uzasadnieniem Czarnego Rynku.

## Save

Schema v13. Migracja z v12 dodaje pola Classes 2.0 i automatycznie zakłada wymaganą startową broń klasową starym Łowcom/Magom, przenosząc zastąpione wyposażenie do plecaka zamiast je usuwać.
