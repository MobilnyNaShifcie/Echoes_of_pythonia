# Changelog

## [0.25.0-dev] — Pierwsza grywalna pętla w Godot 4

- ustawiono docelową rozdzielczość Full HD `1920×1080` i zabezpieczono ekran
  walki przed nachodzeniem na nagłówek oraz stopkę także przy `1280×720`,
- przetłumaczono techniczne identyfikatory w stopce oraz nazwy `Slot`,
  `Item Power` i `HP`, aby interfejs nie mieszał języka polskiego z kodem gry,
- przeniesiono pięcioetapowy prolog wraz z obowiązkową, turową walką fabularną,
- dodano pełną nawigację Varenhold oraz działające ekrany Gildii, klas, bohatera,
  ekwipunku, kupca, karczmy, przygotowania wyprawy, kuźni i warsztatu,
- odtworzono pierwszą misję fabularną **Ci, którzy nie wrócili**, jej cel,
  nagrody i 40 punktów reputacji Gildii,
- dodano modułową mapę Zmierzchowych Równin z oryginalnymi tabelami spotkań
  dnia i nocy oraz zdarzeniami bez walki,
- przeniesiono wszystkich przeciwników pierwszego regionu, ich statystyki,
  zachowania specjalne, nagrody i tabele łupów,
- dodano grywalną walkę turową: atak, obronę, ucieczkę, użycie mikstury,
  zwycięstwo, porażkę i powrót na mapę lub do miasta,
- rozszerzono plecak o materiały, stosy, mikstury oraz szczegóły przedmiotów,
- dodano podgląd czterech Dróg bohatera i zachowano stały wybór klasy na
  poziomie 5 wraz z właściwym wyposażeniem startowym,
- dodano testy GUT dla walki, wypraw, misji, klas, plecaka i nawigacji całego
  pionowego wycinka; kompletna regresja terminalowa nadal pozostaje zielona.

## [0.24.7] — Przygotowanie do wyprawy

- dodano w Varenhold osobny ekran **Przygotowanie do wyprawy**, spinający w jednym miejscu cel, HP/Manę, udźwig, aktywną drużynę, zapasy i ostrzeżenia przed wyruszeniem,
- można wybrać docelowy region i wyruszyć do niego bez przechodzenia przez kilka osobnych menu; stara Mapa Świata nadal pozostaje dostępna,
- z ekranu przygotowania można od razu zmienić skład drużyny, wejść do ekwipunku bohatera, pobrać zapasy z Magazynu Gildii, użyć mikstury/prowiantu oraz przejść do Karczmy,
- dodano cztery trwałe **taktyki AI kompanów**: Agresywna, Zrównoważona, Ostrożna i Obronna; są zapisywane w save i wpływają na decyzje NPC w walce drużynowej Szczelin,
- dodano cztery **presety wyprawowe**: SOLO / BOSS / DUNGEON / SZCZELINA; preset zapamiętuje aktywny skład i docelowe ilości zapasów,
- zastosowanie presetu automatycznie dobiera brakujące mikstury/prowiant z Magazynu Gildii do zadanych ilości; brakujące sztuki są raportowane, a gra nigdy nie tworzy zapasów z niczego,
- uzupełnianie zapasów z ekranu przygotowania i z presetów nie pozwala przekroczyć udźwigu przed wyruszeniem,
- ekran ostrzega o niskim HP, braku leczenia, ciężko rannych kompanach i przeciążeniu; przeciążenie twardo blokuje wyruszenie, pozostałe ostrzeżenia można świadomie zaakceptować,
- naprawiono rzadki problem generatora osobistego wyposażenia NPC: przedmiot zastąpiony przez lepszy osobisty unikat trafia teraz do osobistego schowka kompana zamiast pozostawiać nieistniejące odwołanie w save,
- save schema podniesiono **v14 → v15** dla taktyk i presetów; zapisy v14 migrują automatycznie z taktyką Zrównoważoną i pustymi presetami,
- **v0.24.7 jest ostatnią planowaną wersją terminalową dodającą nową funkcjonalność**; kolejne v0.24.x mają służyć wyłącznie stabilizacji, poprawkom i balansowi przed migracją do Godot 4.

## [0.24.6] — Rest & Healing Rebalance + audyt materiałów

- darmowy odpoczynek przy ognisku nie odnawia już bohatera do pełna: przywraca **25% maks. HP i 35% maks. Many**,
- po użyciu ogniska kolejny darmowy odpoczynek odblokowuje dopiero następna zwykła wyprawa lub walka; stan jest zapisywany, więc reload nie resetuje blokady,
- pełne leczenie pozostaje w Karczmie Pod Czarnym Krukiem: nocleg odnawia całe HP i Manę, kosztuje `25 + 25 × poziom` Gold i po użyciu jest niedostępny do kolejnego dnia Pythonii,
- przebudowano leczenie: Słaba Mikstura 20 HP, Mocna 65 HP, nowa **Wielka Mikstura Lecznicza 150 HP**, Eliksir Arcymistrza 35% maks. HP + 20% maks. Many, Prowiant Myśliwego 30 HP,
- Mirela pozwala kondensować mikstury: `3x Słaba → 1x Mocna`, `3x Mocna + Esencja Mgły → 1x Wielka`, `2x Wielka + Iskra Życia → 1x Eliksir Arcymistrza`,
- przeprowadzono pełny audyt 53 materiałów: każdy ma co najmniej jedną recepturę; `Moneta Topielca` ma trzy zastosowania craftingowe,
- wykryto i naprawiono wcześniejszy błąd: receptura **Starożytnego Klucza Zakonu** istniała w danych, ale nie była widoczna w kolejności receptur Mireli,
- w Plecaku dodano **Sprawdź zastosowanie materiału / wejściówki**; pokazuje wszystkie receptury wykorzystujące materiał oraz dungeon otwierany przez daną wejściówkę,
- kategoria `Klucz` w Plecaku została doprecyzowana jako **Wejściówka**; Starożytny Klucz Zakonu prowadzi do Krypty, a Medalion Czarnej Floty do Wraku,
- save schema pozostaje `14`; nowe pola odpoczynku są opcjonalne i stare zapisy v14 wczytują się bez migracji.

## [0.24.5] — Czytelna waga plecaka i magazynu

- każdy stos materiałów, mikstur, kluczy i ksiąg w Plecaku pokazuje teraz **łączną wagę całego stosu**,
- wyposażenie w Plecaku pokazuje własną wagę obok slotu, dzięki czemu łatwiej znaleźć najcięższe zapasowe przedmioty,
- Magazyn Gildii pokazuje łączną wagę każdego stosu,
- podczas odkładania i odbierania stosów u Kwatermistrza widoczna jest zarówno **waga całego stosu**, jak i waga jednej sztuki,
- brak zmian w samych wartościach wag, balansie udźwigu i save schema; schema pozostaje `14`.

## [0.24.4] — Szybkie zarządzanie Magazynem Gildii

- Kwatermistrz pozwala teraz odkładać i odbierać **wiele egzemplarzy wyposażenia naraz** (`1,3,5-7`),
- przedmioty i materiały można przenosić grupowo (`1,3,5` = całe stosy; `1x5,2xMAX,4x2` = wybrane ilości),
- operacje grupowe są walidowane przed przeniesieniem, więc brak miejsca w Magazynie nie powoduje częściowego przeniesienia wyposażenia,
- zachowano konkretne instancje wyposażenia wraz z ulepszeniami, affixami i `instance_id`,
- save schema pozostaje `14`.

## [0.24.3] — Spójność nazewnictwa wyposażenia

- `Karwasz Kapitana` został przemianowany na **Bransoletę Czarnej Floty**, zgodnie ze slotem Bransolety; `item_id = captain_signet` pozostaje bez zmian dla kompatybilności save'ów,
- `Relikt Burzowego Archiwum` został przemianowany na **Medalion Burzowego Archiwum**, aby nazwa jasno wskazywała slot Naszyjnika,
- poprawiono odpowiadające nazwy receptury, opisy oraz komunikat efektu Medalionu Burzowego Archiwum,
- dodano automatyczny test podstawowej semantyki nazw wyposażenia, pilnujący oczywistych nazw typu Rękawice/Karwasze, Bransoleta, Pierścień, Kolczyki, Buty, Tarcza, Kołczan i rodzaje broni,
- brak zmian statystyk, dropu, receptur kosztowych, balansu i mechaniki przedmiotów,
- save schema pozostaje **v14**.

## [0.24.2] — Kwatermistrz, Magazyn Gildii i Udźwig

- dodano **Kwatermistrza Gildii** jako nową usługę w Gildii Poszukiwaczy,
- dodano **Magazyn Gildii** o pojemności 200 miejsc; stos materiałów zajmuje jedno miejsce niezależnie od liczby sztuk,
- można odkładać i odbierać materiały, mikstury, klucze, księgi oraz konkretne egzemplarze wyposażenia bez utraty `instance_id`, affixów i poziomu +0…+10,
- osobisty ekwipunek kompanów nadal należy do NPC i nie trafia do magazynu gracza,
- dodano miękki system **Udźwigu plecaka**: bazowo 50 kg, +0.5 kg za punkt Siły i +1.5 kg za punkt Wytrzymałości,
- założony ekwipunek bohatera nie obciąża plecaka; system dotyczy rzeczy faktycznie noszonych w inventory,
- stan `Swobodny` obowiązuje poniżej 75% pojemności, `Obciążony` od 75% do limitu, a `Przeciążony` po jego przekroczeniu,
- przeciążenie **nigdy nie usuwa ani nie odrzuca zdobytego łupu**; blokuje jedynie rozpoczęcie kolejnej zwykłej wyprawy regionalnej do czasu odciążenia plecaka,
- w pierwszej wersji testowej stan `Obciążony` nie nakłada jeszcze kar do statystyk bojowych, aby najpierw ocenić wygodę samego systemu,
- Kwatermistrz oferuje trzy stałe ulepszenia plecaka: `+10 / +20 / +35 kg`, wymagające kolejno rangi E / D / C i kosztujące 8 000 / 18 000 / 35 000 Gold,
- aktualny udźwig i stan obciążenia są widoczne w Plecaku, statusie Bohatera oraz u Kwatermistrza,
- save schema pozostaje **v14**; stare zapisy v0.24.0/v0.24.1 bez danych magazynu i udźwigu wczytują się z pustym magazynem i poziomem ulepszenia 0.

## [0.24.1] — Party Setup QoL

- dodano osobny ekran **Ustaw skład wyprawy** w menu `Drużyna i kompani`,
- z jednego miejsca można zaznaczać/odznaczać maksymalnie 3 aktywnych kompanów,
- dodano skrót **Wyruszaj solo**, który jednym wyborem zostawia całą drużynę w Varenhold,
- ciężko ranni i polegli kompani są czytelnie oznaczeni na ekranie składu; istniejące limity aktywnej drużyny nadal obowiązują,
- skład nie może być zmieniany po rozpoczęciu ekspedycji Szczeliny,
- balans kompanów, AI, Szczelin i save schema pozostają bez zmian; schema nadal **v14**.

## [0.24.0] — Companions & Rifts

### Kompani z własnym charakterem
- dodano system stałej drużyny: **maks. 3 aktywnych kompanów + 1 kompan pozostający w Varenhold**, bez kolekcjonowania całej obsady jak katalogu postaci,
- dodano 12 ręcznie napisanych kompanów z własnym pochodzeniem, sposobem mówienia, żartami, wiadomościami, scenami przy obozie i osobistymi historiami,
- kandydaci pojawiają się w Gildii **raz na dzień Pythonii**; restart gry nie rerolluje dziennej oferty,
- wariant kompana jest losowany i utrwalany: klasa z dozwolonej puli, poziom około `-6/+8` względem gracza, atrybuty, drzewko, talenty, wyposażenie i jeden z ręcznie napisanych questline'ów,
- rzadkie ścieżki klas mogą pojawić się u NPC nawet wtedy, gdy gracz sam nie przeczytał odpowiedniej Księgi Ścieżki,
- przed rekrutacją widoczne są klasa, poziom, drzewko i nastawienie, ale **ekwipunek pozostaje tajemnicą**,
- rekrutacja zależy m.in. od rangi Gildii, relacji/rozmowy, dokonań w Szczelinach, osobowości i różnicy poziomów; wynik nie jest rerollowany przez wczytywanie save'a,
- pierwsze rozmowy rekrutacyjne są ręcznie napisane osobno dla każdego kompana zamiast generycznych odpowiedzi.

### Relacje, wiadomości i osobiste historie
- kompani wysyłają wiadomości, komentują świat i pojawiają się w scenach obozowych; dodano ręcznie napisane bantery dla wybranych par NPC,
- każdy kompan losuje jeden z przygotowanych ręcznie osobistych wątków rozwijanych wraz ze wspólnymi Szczelinami,
- wybory w rozmowach zwiększają relację i zapisują wspomnienia używane przez dalsze etapy historii,
- rozstanie nie kasuje postaci: były kompan może po czasie ponownie pojawić się w Gildii i pamięta wcześniejszą relację oraz rozwój.

### Ekwipunek i rozwój NPC
- kompani mają własny EXP, poziomy, atrybuty, drzewka i automatyczny rozwój zgodny z ich buildem,
- gracz może ręcznie wyposażać kompanów w swój sprzęt, z zachowaniem wymagań poziomu i klasy,
- wyposażenie, z którym NPC przychodzi do drużyny, jest **jego osobistą własnością** i nie można go ukraść ani przełożyć na gracza,
- przedmioty powierzone przez gracza pozostają własnością gracza; przy zdjęciu lub rozstaniu automatycznie wracają do jego plecaka, a osobisty sprzęt NPC zostaje przy nim,
- ciężko ranny kompan staje się czasowo niedostępny i otrzymuje stan `CIĘŻKO RANNY` z komunikatem `Powrót do sił: X dni Pythonii`.

### Szczeliny Przebudzenia F → S
- dodano czasowe **Szczeliny Przebudzenia** o rangach `F, E, D, C, B, A, S`, zgodnych ze skalą Gildii,
- Szczeliny pojawiają się i wygasają wyłącznie według **czasu Pythonii**, nigdy czasu realnego,
- jednocześnie aktywna jest maksymalnie jedna Szczelina; jeśli gracz zwleka, może zamknąć ją inna drużyna Poszukiwaczy tej samej Gildii,
- rozpoczęta ekspedycja rezerwuje Szczelinę dla drużyny i można ją bezpiecznie zapisać/wznowić; po porzuceniu wraca do świata i może zostać przejęta,
- Szczelina jest jednorazową, długą ekspedycją: od **12 segmentów na F do 24 na S**, z walkami, elitami, wydarzeniami, obozowiskami, minibossem i finałem,
- układ, motyw, modyfikatory, przeciwnicy i boss są proceduralnie składane z ręcznie przygotowanych elementów i zapisane w seedzie konkretnej Szczeliny,
- wejście wymaga prawdziwego party: F/E co najmniej 2 aktywnych kompanów, D–S pełnej aktywnej trójki kompanów,
- **pokonanie głównego bossa zamyka Szczelinę na zawsze**; nie ma ponownego wejścia do tej samej instancji ani pętli farmienia pierwszych pomieszczeń,
- najwyższe rangi mogą zawierać zapowiadaną Egzekucję powalonego kompana; permanentna śmierć nie jest RNG i następuje tylko po zignorowaniu widocznego śmiertelnego zagrożenia,
- niższe rangi kończą brak ratunku ciężkim urazem i czasowym `Powrotem do sił`, nie losową śmiercią.

### Nowe unikaty klasowe
- dodano **16 nowych Unikatów Szczelin — po 4 dla Wojownika, Łowcy, Maga i Pierrota**,
- obejmują broń, pancerze i OFF-HAND-y zmieniające mechaniki klas: m.in. Tarcza Pękniętego Bastionu, Łuk ze Szkła Szczeliny, Artefakt Rozszczepionego Splotu, Kości Dwóch Kłamstw i Lanca Siedmiu Przypadków,
- efekty nowych unikatów działają zarówno w zwykłej walce, jak i w walce drużynowej Szczelin,
- unikaty nie trafiają do zwykłego craftingu ani normalnych tabel dropu; główna szansa na nie pojawia się przy **zamknięciu całej Szczeliny**.

### QoL / save
- usunięto powtarzany komentarz spod ekranu Plotek Gildii: `Nie każda plotka jest prawdą...`,
- dodano `Drużyna i kompani` oraz `Alarmy Szczelin` do Gildii,
- save schema podniesiono **v13 → v14**; istniejące zapisy v0.23.2 migrują z pustą drużyną i stanem Szczelin bez utraty postępu.

## [0.23.2] — Ślady Przebudzenia / Guild & Save QoL

- dodano grywalny prolog **Droga do Varenhold** i pierwszą walkę fabularną,
- rozpoczęto główny wątek świata: **Akt I — Ślady Przebudzenia**,
- dodano 9 połączonych misji Gildii z własnymi progami poziomu, następstwem fabularnym i zakończeniami,
- nowe misje dają łącznie 700 Reputacji Gildii; wybrane trofea bossów są tylko okazywane i nie są zużywane,
- `C — Łowca` zmieniono na `C — Zdobywca`, bez zmiany progu 700 reputacji,
- dodano kolejne plotki o Przebudzeniu, pieczęciach, Koronie i zakazanych księgach,
- system zapisu rozszerzono z 1 do 4 niezależnych slotów,
- zapis usunięto z menu Varenhold i przeniesiono do głównego menu obok wczytywania,
- autosave zapisuje zawsze do aktualnie aktywnego slotu,
- nowa gra wybiera slot przed rozpoczęciem prologu,
- schema zapisu pozostaje v13.

## [0.23.1] - Codzienna rotacja Czarnego Rynku

- Czarny Rynek odświeża cztery oferty co **1 realny dzień** zamiast co 3 dni,
- restart gry nadal nie rerolluje oferty w obrębie tego samego dnia,
- przy przejściu z v0.23.0 bieżąca stara 3-dniowa rotacja zostaje jednorazowo zastąpiona ofertą przypisaną do aktualnego dnia,
- ceny, szanse na Księgi Mistrzostwa i Ścieżki, liczba ofert oraz zasady targowania pozostają bez zmian,
- save schema pozostaje **v13**.

## [0.23.0] - Classes 2.0

### Drzewka klas i buildy
- przebudowano rozwój klas wokół **punktów drzewka**: 1 punkt przy wyborze klasy na poziomie 5, następnie 1 punkt co 2 poziomy; bohater na poziomie 18 ma łącznie 8 punktów,
- obecne aktywne umiejętności Wojownika, Łowcy i Maga pozostają bazą klasy; drzewka je rozwijają i odblokowują nowe techniki,
- dodano reset drzewka za `1000 + 250 × wydane punkty` Gold; przeczytane Księgi Ścieżki pozostają odblokowane,
- ekran **Bohater → Umiejętności** pokazuje aktywne skille, drzewko, wolne punkty, specjalizację oraz — dla Łowcy — Księgę Kombinacji.

### Wojownik — Natarcie / Ciężki Rycerz
- **Ciężki Rycerz nie jest nową klasą**; jest specjalizacją Wojownika odblokowywaną przez `Traktat Ciężkiego Rycerza`,
- Natarcie rozwija obrażenia skilli, krwawienie, łamanie DEF i egzekucję rannych celów,
- Ciężki Rycerz otrzymał tarcze, Blok, Prowokację, Uderzenie Tarczą, Żelazną Kontrę oraz skalowanie części obrażeń z DEF,
- Obrona z tarczą przygotowuje Odwet oparty na DEF; talent Bastion zwiększa jego przelicznik do 75% DEF,
- po wejściu w talent rdzeniowy status postaci pokazuje `Wojownik — Ciężki Rycerz`.

### Mag — Żywioły / Arkana
- drzewko Żywiołów wzmacnia ogień, mróz i błyskawice oraz nagradza wykonanie trzech różnych żywiołów z rzędu,
- `Grimuar Podwójnego Splotu` odblokowuje **Arkana** i mechanikę `Splot Magii 0/3`,
- po zbudowaniu 3/3 Splotu Mag może rzucić **dwa ofensywne zaklęcia w jednej turze**, a przeciwnik odpowiada dopiero po obu,
- drugie zaklęcie zaczyna od 80% mocy; talenty mogą obniżyć jego koszt Many o 25%, podnieść moc do 95% i zwrócić 4 Many po splocie.

### Łowca — Mistrz Salwy / Widmowy Strzelec
- zwykłe strzały są abstrakcyjne i **nieskończone**; Łowca nie craftuje ani nie zużywa pojedynczej amunicji,
- dodano techniki: **Przebijająca, Lodowa, Wybuchowa, Widmowa, Deszcz Strzał i Rozszczepiająca Strzała**; istniejący Krwawiący Strzał jest techniką Krwawą,
- trzy techniki tworzą sekwencję; wybrane sekwencje uruchamiają nazwane Finisher-y i po pierwszym użyciu zapisują się w **Księdze Kombinacji**,
- dostępne kombinacje obejmują m.in. `Szkarłatną Egzekucję`, `Kruche Rozerwanie`, `Widmową Detonację`, `Paradę Widm`, `Burzę Przebicia` i `Szkarłatne Widmo`,
- Widmowa Strzała trafia teraz i pozostawia Echo materializujące się po następnej akcji Łowcy; Deszcz Strzał działa analogicznie jako opóźniona salwa,
- `Kronika Widmowego Strzelca` odblokowuje ścieżkę Widmowego Strzelca: silniejsze Echa, Widmowe Łuki i finałowe `Tysiąc Strzał`.

### Pierrot — nowa klasa / Fate Engine
- dodano czwartą grywalną klasę **Pierrot**, korzystającą z Lancy Losu, Kości Losu oraz unikalnego atrybutu **Szczęście**,
- Szczęście jest dostępne wyłącznie Pierrotowi i wzmacnia jego system Losu; bardzo wysokie Szczęście daje jedynie niewielki bonus do szans zwykłego lootu, aby Pierrot nie stał się obowiązkową klasą do farmienia,
- dodano centralny **Fate Engine** zarządzający rzutami kości, historią wyników i manipulacjami Fortuny zamiast rozrzucania logiki Pierrota po przypadkowych wywołaniach RNG,
- podstawowe skille Pierrota korzystają z 1k6, 2k6 i 3k6: występują Pechowe Numery, dublety, Wężowe Oczy, Szczęśliwa Siódemka, Jackpoty i trójki,
- pech generuje **Żetony Losu**, a `Va Banque` zużywa zgromadzoną pulę i zwiększa stawkę finałowego rzutu,
- drzewko **Chaos** rozwija skrajne wyniki, Efekt Domina i `Krzywe Zwierciadło`, które może odbić następny bezpośredni atak przeciwnika,
- `Księga Fortuny` odblokowuje ścieżkę **Fortuna**: Dociążoną Kość, Kant zmieniający sumę 6/8 w 7, Drugą Szansę i silniejsze wykorzystywanie Szczęścia/Żetonów Losu.

### Księgi Ścieżki i Mistrzostwa pasywne
- dodano cztery pierwsze Księgi Ścieżki: `Traktat Ciężkiego Rycerza`, `Kronika Widmowego Strzelca`, `Grimuar Podwójnego Splotu` i `Księga Fortuny`,
- księgi są losowane ze **wspólnej puli**: regionalni bossowie mają 0,5% na Księgę Ścieżki, minibossowie/ważne elity dungeonów 1%, a bossowie dungeonów 2%; żaden boss nie ma przypisanej konkretnej księgi,
- Księga Ścieżki innej klasy może wypaść i pozostać w plecaku, ale nie można jej przeczytać; można ją zachować albo sprzedać na Czarnym Rynku,
- Czarny Rynek może teraz wylosować Księgę Ścieżki w 8% rotacji; są wyraźnie droższe od Ksiąg Mistrzostwa,
- pasywki na 10/10 otrzymały wybór specjalizacji: **Żelazna Wola / Drugi Oddech, Nawałnica Ciosów / Zabójcze Tempo, Precyzja / Egzekucja, Surowa Siła / Rozpęd**.

### Broń klasowa i OFF-HAND
- dodano slot **Druga ręka (OFF-HAND)**: Wojownik używa Tarcz, Łowca Kołczanów, Mag Artefaktów, a Pierrot Kości lub Talii Kart,
- wybór klasy na poziomie 5 automatycznie daje i zakłada podstawowy zestaw: Tarcza Rekruta, Łuk Myśliwski + Kołczan Tropiciela, Kostur Adepta + Kryształ Many albo Lanca Kaprysu + Wytarte Kości Losu,
- nowe skille Łowcy wymagają Łuku, skille Maga Kostura, a skille Pierrota Lancy Losu; stare ogólne bronie nie zostały usunięte,
- dodano 12 drop-only broni klasowych zapewniających progresję przez Czarny Bór, Mokradła, Popielne Pogranicze i Lodowe Wybrzeże: po cztery Łuki, Kostury i Lance Losu,
- broń klasowa jest losowana z **puli całego regionu**, a nie konkretnego potwora: 4% z normalnego przeciwnika, 10% z elity, 14% z minibossa i 20% z bossa,
- dodano pierwszą późną pulę rzadkich OFF-HAND-ów: `Tarcza Straży Paleniska`, `Kołczan Echa`, `Relikwiarz Splotu` i `Talia Oszusta`; sprzęt ten jest drop-only,
- nie dodano craftowanych strzał ani kosztu Esencji/Iskry Życia przy używaniu skilli — materiały pozostają zasobem progresji i craftingu, nie amunicją.

### Warsztat i Gildia
- Warsztat Mireli dzieli receptury na: **Mikstury i prowiant, Klucze i wejściówki, Materiały i komponenty, Wyposażenie ogólne, Przedmioty specjalne, Wszystkie receptury**,
- sprzęt klasowy i build-defining nie trafia do zwykłego craftingu, dzięki czemu lista receptur nie będzie rosła do setek pozycji,
- dodano dużą pulę progresywnych **Plotek Gildii** zależnych od rangi, odkrytego Czarnego Rynku i ważnych osiągnięć,
- lore oficjalnie wprowadza królewski zakaz handlu Księgami Mistrzostwa i Ścieżki oraz plotki o przemytnikach, Ciężkim Rycerzu, Pierrocie, Widmowym Strzelcu i Podwójnym Splocie.

### Save i kompatybilność
- save schema **v12 → v13**,
- migracja dodaje Szczęście, drzewka, odblokowane ścieżki, specjalizacje pasywek i odkryte kombinacje bez naruszania istniejącego postępu,
- stare postacie Łowcy i Maga automatycznie zakładają wymagany Łuk/Kostur oraz OFF-HAND; zastąpiona stara broń trafia bezpiecznie do plecaka,
- istniejące wyposażenie ogólne, ulepszenia, affixy, Signature Weapons, bossowie i dotychczasowy balans świata pozostają zachowane.

## [0.22.0] - Guild & Black Market

### Gildia 2.0
- dodano Reputację Gildii i pełną progresję rang: **F — Nowicjusz, E — Adept, D — Poszukiwacz, C — Łowca, B — Weteran, A — Mistrz, S — Legenda**,
- zadania fabularne, Daily, Weekly i jednorazowe ważne osiągnięcia zwiększają Reputację Gildii,
- Daily odblokowują się od rangi E, Weekly od rangi D,
- dawne osiągnięcie `Weteran Gildii` nie wpada już za kilka jednorazowych zadań; od v0.22 jest nagrodą za **S — Legenda**,
- ekran Gildii pokazuje aktualną rangę, reputację, próg kolejnego awansu oraz pełną tabelę rang.

### Informator i Czarny Rynek
- od rangi **C — Łowca** i po ukończeniu co najmniej jednego dungeonu w Karczmie może pojawić się losowy informator,
- informator ma 20% szansy raz na nowy dzień Pythonii; po czterech nieudanych dniach piąta kwalifikująca próba jest gwarantowana,
- informator niczego nie sprzedaje — przekazuje drogę, po czym **Czarny Rynek** zostaje odblokowany permanentnie,
- Czarny Rynek ma cztery oferty na rotację i zmienia towar co **3 realne dni**; restart gry nie rerolluje oferty,
- w rotacji mogą pojawić się rzadkie materiały, eliksiry oraz Księgi Mistrzostwa,
- przy zakupie oraz sprzedaży księgi można wykonać jedną próbę targowania; sukces poprawia cenę, porażka ją pogarsza, a wynik jest zapisywany natychmiast.

### Księgi Mistrzostwa
- dodano cztery pierwsze Księgi Mistrzostwa: **Traktat Mistrzowskiej Regeneracji, Manuskrypt Szybkiego Ostrza, Kodeks Krytycznego Uderzenia, Traktat Siły**,
- przeczytanie właściwej księgi permanentnie zwiększa limit konkretnej pasywki z 5 do 10 i zużywa księgę,
- duplikaty pozostają normalnymi przedmiotami i można sprzedać je na Czarnym Rynku albo zachować na przyszłość,
- regionalni bossowie mają 1% szansy na jakąkolwiek Księgę Mistrzostwa, ważni minibossowie dungeonów 2%, a bossowie dungeonów 4%,
- po udanym rollu tytuł księgi jest losowany ze wspólnej puli; żadna księga nie jest przypisana do konkretnego bossa,
- overworldowi minibossowie i zwykłe potwory nie dropią Ksiąg Mistrzostwa,
- przygotowano osobny typ **Księga Ścieżki** pod późniejsze Classes 2.0, ale żadna taka księga nie jest jeszcze dostępna.

### Mistrzostwo pasywek 6-10
- Szybkość Ataku: 27% / 29% / 31% / 33% / **35%**,
- Obrażenia Krytyczne: 10–14% szansy oraz mnożnik x2.80–**x3.00**,
- Regeneracja Zdrowia: +19 / +23 / +27 / +31 / **+35 HP**,
- Zwiększenie Ataku: +13 / +16 / +19 / +22 / **+25 ATK**,
- bez właściwej księgi limit pasywki pozostaje 5/5.

### UI i save
- menu Bohatera ma wyraźny ekran **Umiejętności** dostępny poza walką; pokazuje aktywne skille, poziomy odblokowania i stan Mistrzostw pasywnych,
- Ekwipunek otrzymał osobny widok **Księgi** z oznaczeniem przeczytanych i nieprzeczytanych egzemplarzy,
- save schema **v11 → v12**; migracja rekonstruuje możliwą do potwierdzenia Reputację Gildii z ukończonych zadań, trwałych trofeów i zapisanych osiągnięć świata,
- dawny zbyt łatwo zdobyty `Weteran Gildii` jest podczas migracji usuwany; tytuł można ponownie zdobyć dopiero na randze S.

## [0.21.9] - Spójne nazewnictwo wyposażenia

- `Talizman Czarnego Jelenia` został przemianowany na **Bransoletę Czarnego Jelenia**, zgodnie z faktycznym slotem Bransolety,
- poprawiono opis przedmiotu, aby nie sugerował naszyjnika,
- `item_id`, statystyki, wymagany poziom, receptura, drop, affixy i istniejące egzemplarze w save pozostają bez zmian,
- `Talizman Słońca` pozostaje Talizmanem i zajmuje slot Naszyjnika,
- save schema pozostaje **v11**.

## [0.21.8] - Częstsza Iskra Życia

- szansa na **Iskrę Życia** z Przeklętego Stracha na Wróble wzrosła z **5% do 20%**,
- pozostałe dropy Przeklętego Stracha na Wróble pozostają bez zmian,
- bez zmian balansu przeciwników, craftingu i schematu zapisu; save pozostaje **v11**.

## [0.21.7] - Equipment Progression Pass

### Dodano
- **Medalion Utopionej Matki** — Naszyjnik, IP III, wymagany poziom 8; 12% dropu z Matki Głuchej Wody i alternatywna receptura.
- **Bransoleta Zakonu** — Bransoleta, IP IV, wymagany poziom 10; receptura z materiałów Krypty.
- **Pas Pustkowi** — Pas, IP V, wymagany poziom 13; receptura z materiałów Popielnego Pogranicza.

### Zmieniono
- `Kapitański Sygnet` został przebudowany w **Karwasz Kapitana**: zachowuje `item_id`, IP VI, wymagany poziom 17, dotychczasowy drop i recepturę, ale zajmuje teraz slot Bransolety.
- **Pierścień Lewiatana** pozostaje pierścieniem IP VI na poziom 18; oba przedmioty nie są już liniowymi zamiennikami w tym samym slocie.
- Save schema **v10 → v11**. Migracja zachowuje istniejący Karwasz/Sygnet; jeśli stary egzemplarz był założony jako pierścień, zostaje przeniesiony do slotu Bransolety, a przy zajętym slocie trafia bezpiecznie do plecaka.

## [0.21.6] - Pasywki i QoL kowala

### Pasywki 1-5
- Szybkość Ataku zwiększa teraz szansę na dodatkowe uderzenie o **5% na poziom** (25% na 5/5),
- Obrażenia Krytyczne zwiększają szansę na krytyk od 5% na 1/5 do **9% na 5/5** oraz mnożnik do **x2.75**,
- Regeneracja Zdrowia daje teraz **+3 HP na poziom**, czyli +15 HP po turze przeciwnika na 5/5,
- Zwiększenie Ataku daje teraz **+2 ATK na poziom**, czyli +10 ATK na 5/5,
- maksymalny poziom pozostaje 5; poziomy 6-10 i specjalizacje będą częścią późniejszego systemu mistrzostwa/ksiąg.

### Kowal
- koszt następnego ulepszenia pokazuje obecny i wymagany Gold: `posiadane/wymagane [OK/BRAK]`,
- każdy wymagany materiał pokazuje stan `posiadane/wymagane [OK/BRAK]`,
- nie trzeba już sprawdzać plecaka, aby dowiedzieć się, którego komponentu brakuje.

### Save
- schema pozostaje **v10**; istniejące poziomy pasywek zachowują się i automatycznie korzystają z nowych wartości.

## [0.21.5] - Klimat Wraku Czarnej Floty

### Atmospheric Dungeon Pass
- rozbudowano narracyjne wejście do Wraku Czarnej Floty oraz opis samego cmentarzyska okrętów,
- Zamarznięty Pokład, Przejście między Wrakami, Zalana Ładownia, Górny Pokład i Kajuty Oficerskie dostały pełniejsze opisy miejsca,
- rozwidlenie Czarnej Floty lepiej przedstawia ryzyko obu tras bez zmiany ich mechaniki,
- Skarbiec Czarnej Floty i Kajuta Medyka dostały własne opisy atmosferyczne,
- dodano osobną scenę wejścia **Pierwszego Oficera Czarnej Floty** wraz z krótką kwestią przed walką,
- dodano podejście do okrętu flagowego oraz osobną scenę pojawienia się **Admirała Vareka** i widmowych kanonierów,
- teksty narracyjne są przechowywane oddzielnie od mechaniki dungeonu, co ułatwi późniejsze przeniesienie gry do GUI.

### Balans i save
- brak zmian statystyk, dropów, kosztów, przeciwników, tras i mechanik walki,
- brak dodatkowych losowań wpływających na RNG encounterów lub łupu,
- save schema pozostaje **v10**.

## [0.21.4] - Częstszy Pożeracz Palenisk

- nocna waga Pożeracza Palenisk w Popielnym Pograniczu wzrosła z **5% do 10%**,
- pozostałe nocne wagi spotkań zostały lekko obniżone, aby pula nadal wynosiła dokładnie 100%,
- Pożeracz nadal pojawia się wyłącznie nocą; bez zmian jego statystyk, mechanik i dropu,
- bez zmian schematu zapisu.

## [0.21.3] - Czytelne obrażenia umiejętności

- ofensywne umiejętności pokazują teraz osobne podsumowanie łącznych zadanych obrażeń,
- przy pełnym uniku podsumowanie pokazuje `0 (unik)`,
- umiejętności wielouderzeniowe sumują obrażenia wszystkich trafień,
- bez zmian balansu i schematu zapisu.

# Changelog

## [0.24.1] — Party Setup QoL

- dodano osobny ekran **Ustaw skład wyprawy** w menu `Drużyna i kompani`,
- z jednego miejsca można zaznaczać/odznaczać maksymalnie 3 aktywnych kompanów,
- dodano skrót **Wyruszaj solo**, który jednym wyborem zostawia całą drużynę w Varenhold,
- ciężko ranni i polegli kompani są czytelnie oznaczeni na ekranie składu; istniejące limity aktywnej drużyny nadal obowiązują,
- skład nie może być zmieniany po rozpoczęciu ekspedycji Szczeliny,
- balans kompanów, AI, Szczelin i save schema pozostają bez zmian; schema nadal **v14**.

## [0.21.2] - Upgrade System 2.0

### Koszty ulepszania
- `+0 → +3` pozostaje etapem startowym opartym na Osełkach i Goldzie,
- od `+4` ulepszenia wymagają materiałów powiązanych z Item Power i regionem pochodzenia sprzętu,
- od `+8` wchodzą materiały elit/minibossów,
- `+10` wymaga trofeum głównego bossa odpowiedniego etapu progresji,
- Osełki i Kamienie Szlifierskie nadal można kupować, ale same nie wystarczają już do osiągnięcia +10,
- koszt Golda skaluje się z Item Power; pełne +0 → +10 kosztuje 4025 Gold dla IP I, 5825 dla IP IV, 6825 dla IP V, 8050 dla IP VI i 9450 dla IP VII,
- multi-upgrade i `MAX` uwzględniają wszystkie nowe materiały i nadal są atomowe.

### Skalowanie statystyk
- zastąpiono stałe, zbyt małe przyrosty skalowaniem opartym o bazowe statystyki przedmiotu,
- ATK na +10 może otrzymać do +90% bazowej wartości, DEF do +60%, HP/Mana do +85%, a Unik do +100% bazowej wartości,
- stary wzór pozostaje minimalnym progiem, dzięki czemu żaden istniejący przedmiot nie staje się słabszy po aktualizacji,
- Miecz Wielkiego Mistrza rośnie z 13 do 25 bazowego ATK na +10,
- Szabla Admirała Vareka rośnie z 24 do 46 bazowego ATK na +10,
- Pancerz Północy rośnie z 14 DEF / 65 HP do 22 DEF / 120 HP na +10.

### UI kowala
- przy następnym ulepszeniu wyświetlane są wszystkie wymagane materiały,
- lista pokazuje bezpośredni wzrost statystyk następnego poziomu,
- ekran potwierdzenia multi-upgrade pokazuje finalne statystyki przed zatwierdzeniem.

### Save
- schema pozostaje **v10**,
- istniejące poziomy ulepszeń są zachowane i automatycznie korzystają z nowego skalowania.

## [0.21.1] - Odrodzenie bossów regionowych

### Bossowie otwartego świata
- Azhar, Władca Pustkowi oraz Lewiatan Północy rozpoczynają po zwycięstwie odrodzenie trwające **6 normalnych wypraw w ich własnym regionie**,
- wyprawy w innych regionach, odpoczynek i dungeony nie skracają odrodzenia,
- porażka i ucieczka z walki z bossem nie uruchamiają licznika,
- menu regionu pokazuje pozostałą liczbę wypraw, np. `[Odrodzenie: 3 wyprawy]`,
- podczas aktywnego odrodzenia ponowne wyzwanie bossa jest blokowane,
- po szóstej wyprawie boss automatycznie staje się ponownie dostępny,
- system jest przygotowany tak, aby przyszli bossowie regionowi mogli dostać ten sam mechanizm bez kopiowania logiki.

### Save
- licznik odrodzenia jest zapisywany osobno dla każdego bossa,
- save schema **v9 → v10**,
- istniejące zapisy z v0.21.0 migrują z pustymi licznikami, więc po aktualizacji oba bossy są od razu dostępne.

## [0.21.0] - Wrak Czarnej Floty

### Dungeon 2
- dodano **Wrak Czarnej Floty** jako drugi dungeon dla poziomów 16-20, dostępny z Lodowego Wybrzeża,
- wejście wymaga **Medalionu Czarnej Floty**; Widmo Kapitana Statku gwarantuje jeden medalion, a crafting jest alternatywnym źródłem,
- nowi przeciwnicy: Przeklęty Marynarz, Topielec Czarnej Floty, Przeklęty Kanonier, Widmowy Strzelec i Bosman Czarnej Floty,
- miniboss: **Pierwszy Oficer Czarnej Floty**,
- boss: **Admirał Varek**,
- Ładownia jest dłuższą trasą z dodatkowymi walkami i dostępem do Skarbca Czarnej Floty,
- Górny Pokład jest krótszą trasą z wymuszonym starciem pod ostrzałem,
- **Kajuta Medyka** może raz na wyprawę przywrócić 30% maks. HP i Many,
- HP i Mana nadal przechodzą pomiędzy starciami; odwrót zabezpiecza łup, a porażka usuwa wyłącznie niezabezpieczony loot z runu.

### Admirał Varek
- faza I: pojedynek na pokładzie okrętu flagowego,
- faza II: kanonierzy przygotowują **Salwę Armatnią**; atak jest zapowiadany turę wcześniej i Obrona realnie redukuje jego obrażenia,
- faza III: **Ostatni Rozkaz** — +10 ATK, -8 DEF, koniec salw i 20% szansy na wzmocnione krytyczne cięcie.

### Druga Signature Dungeon Weapon
- dodano **Szablę Admirała Vareka** [Legendarny | IP VII],
- wymagany poziom: **20**,
- Średnie Obrażenia losują się osobno na każdym egzemplarzu w zakresie **-8%..+22%**,
- Średnie nie zajmują żadnego z czterech legendarnych affixów T1-T5,
- Admirał Varek ma **10%** szansy na bezpośredni drop Szabli,
- gwarantowany Fragment Szabli Vareka pozwala po co najmniej dwóch zwycięstwach wycraftować nowy egzemplarz jako bad-luck protection.

### Integracja
- wysokopoziomowy Weekly od poziomu 16 może wymagać ukończenia Wraku Czarnej Floty zamiast starej Krypty,
- interfejs wejścia i zakończenia dungeonów został uogólniony, aby nie używał tekstów przypisanych wyłącznie do Krypty,
- save schema pozostaje **v9**; brak zmian balansu wcześniejszych regionów i przeciwników.

## [0.20.0] - Lodowe Wybrzeże

### Region 5
- dodano **Lodowe Wybrzeże** jako piąty region otwartego świata dla poziomów 14-18,
- nowi zwykli przeciwnicy: Zamarznięty Rozbitek, Lodowy Niedźwiedź, Śnieżny Gryf, Lodowy Krab i Syrena Czarnego Morza,
- Syrena Czarnego Morza jest najsilniejszym zwykłym przeciwnikiem regionu,
- **Widmo Kapitana Statku** jest rzadkim minibossem nocnym,
- **Lewiatan Północy** jest dobrowolnym trzyfazowym bossem regionu,
- nowe zwykłe potwory współpracują z istniejącym systemem losowych elit oraz licznikami pity/streak per region.

### Item Power VI i przedmioty klasowe
- dodano pierwsze trzy drop-only przedmioty z efektem klasowym: **Pancerz Północy** (Wojownik), **Płaszcz Śnieżnego Gryfa** (Łowca), **Amulet Czarnego Morza** (Mag),
- przedmioty klasowe może założyć dowolna klasa; stały efekt aktywuje się tylko dla właściwej klasy,
- Pancerz Północy: Obrona przygotowuje Odwet skalujący następny podstawowy atak z DEF,
- Płaszcz Śnieżnego Gryfa: udany unik przygotowuje Drapieżny Odruch (+20% obrażeń i +10 p.p. krytyka na następnym podstawowym ataku),
- Amulet Czarnego Morza: każde 20 Many wydane na umiejętności zwraca 5 Many,
- zwykłe wersje właściwych potworów mają ~2-2.5% szansy na klasowy drop; elity 7-8% przed modyfikatorami pogody,
- **przedmioty klasowe nie mają receptur**, aby pozostały celem farmienia,
- dodano kilka neutralnych receptur i ograniczony loot minibossa/bossa, aby materiały regionu miały zastosowanie bez zalewania plecaka wyposażeniem,
- region celowo nie dodaje nowej broni; Signature Weapon pozostaje domeną dungeonów.

### Balans i kompatybilność
- Daily/Weekly automatycznie mogą korzystać z Lodowego Wybrzeża od odpowiedniego poziomu,
- wymagane poziomy sprzętu Regionu 5 mieszczą się w przedziale 15-18,
- save schema pozostaje **v9** — efekty klasowe wynikają z definicji przedmiotu i nie wymagają migracji save.

## [0.19.0] - Popielne Pogranicze

### Region 4
- dodano **Popielne Pogranicze** jako czwarty region otwartego świata,
- zalecany poziom: 10-14, zagrożenie 4/5,
- dzień i noc mają osobne pule spotkań,
- nowi przeciwnicy: Piaskowy Golem, Pustynna Harpia, Pustynny Wędrowiec, Kościopal i Czerwona Salamandra,
- Pożeracz Palenisk jest rzadkim minibossem nocnym,
- Azhar, Władca Pustkowi jest dobrowolnym bossem dostępnym z menu regionu i nie pojawia się losowo.

### Walka i bossowie
- pierwsza większa skala HP dla otwartego świata: zwykli przeciwnicy ~190-440 HP, miniboss 1050 HP, Azhar 1850 HP,
- Pożeracz Palenisk rozgrzewa się podczas dłuższej walki i wchodzi w Szał Paleniska poniżej 30% HP,
- Azhar ma trzy fazy: Burza Piaskowa poniżej 60% HP oraz Gniew Pustkowi poniżej 25% HP,
- przeciwnicy Regionu 4 korzystają z bazowych odporności żywiołowych,
- zwykli przeciwnicy Regionu 4 mogą otrzymywać istniejące modyfikatory elit.

### Loot i Item Power V
- zwykli przeciwnicy Regionu 4 dropią przede wszystkim materiały, bez nowej puli śmieciowego wyposażenia,
- dodano sześć celowych przedmiotów IP V: Pancerz Pustkowi, Talizman Słońca, Karwasze Paleniska, Ostrze Azhara, Koronę Azhara i Pierścień Azhara,
- Pożeracz Palenisk może bezpośrednio upuścić Karwasze Paleniska,
- Azhar może bezpośrednio upuścić Ostrze, Koronę lub Pierścień Azhara,
- Ostrze Azhara **nie** posiada Średnich Obrażeń; mechanika pozostaje zarezerwowana dla Signature Dungeon Weapons.

### Crafting
- Pancerz Pustkowi i Talizman Słońca tworzą przewidywalną ścieżkę progresji z materiałów regionu,
- trzy Rdzenie Paleniska stanowią bad-luck protection dla Karwaszy Paleniska,
- sześć Pieczęci Azhara stanowi bad-luck protection dla każdego z trzech bossowych przedmiotów,
- craft minibossowego i bossowego wyposażenia zachowuje jakość źródła przy losowaniu tierów T1-T5,
- Iskra Życia jest ponownie używana jako rzadki katalizator,
- Zwykła Esencja jest używana jako uniwersalny reagent magiczny i ma dodatkowe źródła w Regionie 4.

### Gildia i save
- kontrakty automatycznie uznają Popielne Pogranicze za dostępny region od poziomu 10,
- tygodniowe zlecenia wysokopoziomowe używają nazwy aktualnego regionu zamiast nazw związanych wyłącznie z Mokradłami,
- save schema pozostaje **v9**; zapis z v0.18.0 działa bez migracji.


## [0.18.0] - Item Progression + Signature Dungeon Weapons

### Wymagany poziom wyposażenia
- każde obecne wyposażenie ma jawnie przypisany wymagany poziom,
- wymagany poziom jest niezależny od Item Power i ulepszenia +0..+10,
- próba założenia przedmiotu ponad poziom bohatera jest blokowana,
- zablokowana próba nie usuwa przedmiotu z plecaka,
- UI ekwipunku, craftingu, kowala i sprzedaży pokazuje wymagany poziom.

### Signature Dungeon Weapons
- utworzono osobną kategorię danych dla wybranych broni z bossów dungeonów,
- pierwszą jest Miecz Wielkiego Mistrza,
- każdy egzemplarz losuje Średnie Obrażenia od -5% do +15%,
- Średnie Obrażenia nie zajmują miejsca w affixach T1-T5,
- dodatni roll zwiększa zwykłe uderzenia, ujemny je zmniejsza,
- bonus nie wpływa na aktywne umiejętności; służy temu osobny Skill Damage,
- dodatkowe uderzenie z Szybkości Ataku korzysta ze Średnich Obrażeń,
- Wielki Mistrz nadal ma 12% bezpośredniej szansy na miecz,
- craftowany Miecz Wielkiego Mistrza losuje właściwości z jakością BOSS,
  dzięki czemu crafting pozostaje pełnoprawnym bad-luck protection.

### Save
- schema v8 → v9,
- istniejące Miecze Wielkiego Mistrza dostają stabilny roll Średnich
  Obrażeń bez zmiany dotychczasowych affixów,
- roll jest zapisywany per egzemplarz i nie zmienia się po restarcie.


## [0.17.11] - Porządek u kowala

### UI kowala
- lista ulepszeń została podzielona na sekcje `ZAŁOŻONE` i `PLECAK`,
- zachowano wspólną numerację wszystkich przedmiotów,
- w sekcji założonego sprzętu skrócono oznaczenie do samego slotu, np. `[Broń]`,
- usunięto powtarzające się etykiety `[Plecak]` i `[Założone: ...]`.


## [0.17.10] - Wygodniejsze ulepszanie

### Kowal
- `[GOTOWE]` zastąpiono statusem `[MOŻNA ULEPSZYĆ]`,
- `[BRAKI]` zastąpiono statusem `[BRAK ZASOBÓW]`,
- po wybraniu przedmiotu można wykonać kilka kolejnych ulepszeń naraz,
- dodano `MAX`, które wybiera maksymalną liczbę ulepszeń dostępną przy aktualnych zasobach,
- przed wykonaniem operacji wyświetlany jest łączny koszt Golda i wszystkich materiałów,
- multi-upgrade jest atomowy: przy brakujących zasobach nic nie zostaje pobrane,
- koszty poszczególnych poziomów +0 → +10 pozostają bez zmian.

### Save
- schema pozostaje v8.


## [0.17.9] - Equipment UI cleanup

### UI ekwipunku
- usunięto z widoków gracza etykiety `Defensywny`, `Ofensywny` i `Mieszany`,
- role slotów nadal istnieją wewnętrznie i nadal sterują pulami affixów Equipment 2.0,
- usunięto również linię `Rola:` z pełnych szczegółów przedmiotu.


## [0.17.8] - Czytelniejszy status craftingu

### UI craftingu
- ogólny status receptury `[BRAKI]` zmieniono na `[BRAK WYMAGANYCH ZASOBÓW]`,
- krótkie statusy `[BRAK]` / `[OK]` przy konkretnych składnikach pozostają bez zmian,
- mechanika craftingu i save schema pozostają bez zmian.



## [0.17.7] - Czytelniejsze komunikaty krytyków

### UI walki
- usunięto techniczną etykietę `[KRYTYK!]`,
- trafienie krytyczne jest teraz częścią naturalnego komunikatu o obrażeniach,
- zmiana obejmuje zwykłe ataki, umiejętności i dodatkowe uderzenia.


## [0.17.6] - Dungeon UI cleanup

### Wejście do Krypty
- usunięto statusy `[GOTOWE]` i `[BRAK]` przy Starożytnym Kluczu Zakonu,
- ekran pokazuje teraz wyłącznie liczbę posiadanych i wymaganych kluczy, np. `2/1` albo `0/1`,
- mechanika wejścia do Krypty pozostaje bez zmian.


## [0.17.5] - Wygodniejsze szczegóły ekwipunku

### UI ekwipunku
- po sprawdzeniu pojedynczego założonego przedmiotu gracz wraca teraz do listy założonego ekwipunku,
- nie trzeba ponownie wchodzić do sekcji szczegółów po każdym przedmiocie,
- dodano `[A] Pokaż wszystkie szczegóły`, które wyświetla cały założony zestaw na jednym ekranie,
- nagłówek zmieniono na `SZCZEGÓŁY ZAŁOŻONEGO EKWIPUNKU`,
- brak zmian w balansie, save schema pozostaje v8.


## [0.17.4] - Combat UI polish

### UI walki
- oznaczenie rangi przeciwnika zostało przeniesione bezpośrednio przed nazwę potwora,
- dotyczy to elit, minibossów i bossów,
- ekran walki jest dzięki temu krótszy i czytelniejszy.


## [0.17.3] - Combat UI Cleanup

### Interfejs walki
- usunięto techniczny opis modyfikatora elity z ekranu walki,
- pozostawiono oznaczenie `[ELITA]` oraz nazwę wariantu przeciwnika,
- mechanika i balans elit pozostają bez zmian.


## [0.17.2] - UI Cleanup

### Interfejs
- usunięto etykietę `Bonusy: X` z list wyposażenia, craftingu, handlu i kowala,
- szczegóły przedmiotu nadal pokazują wszystkie faktyczne affixy,
- uproszczono główne menu Varenhold: usunięto opisy po prawej stronie pozycji,
- mechanika Equipment 2.0 i save schema v8 pozostają bez zmian.


## [0.17.1] - Gramatyka i balans elit

### Nazwy elit
- dodano rodzaj gramatyczny przeciwnika do danych wroga,
- prefiksy elit odmieniają się teraz przez rodzaj,
- przykładowo: `Zorzowa Bagienna Wiedźma`, `Przeklęta Bagienna Wiedźma`, `Mroźna Zjawa Wisielca`,
- męskie nazwy zachowują dotychczasowe formy.

### Balans elit
- każda losowa elita otrzymuje teraz wspólną bazę: +40% HP, +10% ATK, +1 DEF i +3 p.p. Uniku,
- Wściekły: dodatkowe +10% HP i +30% ATK,
- Opancerzony: dodatkowe +35% HP i mocniejszy DEF,
- Wampiryczny: dodatkowe +25% HP i 40% lifestealu,
- Przeklęty: dodatkowe +20% HP, częstsze i mocniejsze ataki specjalne,
- Żywiołowy: dodatkowe +30% HP, +15% ATK, +2 do specjalnego ataku i 50% odporności na swój żywioł,
- pogodowe wzmocnienie Zorzy nadal nakłada się przed modyfikatorem elity,
- Krypta nadal nie korzysta z losowych elit.

### Save
- schema pozostaje v8; brak migracji danych gracza.


## [0.17.0] - Equipment 2.0

### Sloty i role
- Hełm/Zbroja/Rękawice/Buty są defensywne,
- Broń/Naszyjnik/Bransoleta/Kolczyki/Pierścień są ofensywne,
- Pas jest mieszany i ma 75% normalnej wartości affixu,
- istniejące bazowe statystyki wyposażenia zostały uporządkowane zgodnie z rolami slotów.

### Item Power i T1-T5
- dodano Item Power I-IV dla całego istniejącego wyposażenia,
- rarity określa 0/1/2/3/4 affixy,
- T1/T2/T3/T4/T5 odpowiada 20/40/60/80/100% rolla,
- płaskie statystyki posiadają skalowanie przygotowane pod przyszły endgame,
- procentowe bonusy mają twarde limity bezpieczeństwa.

### Affixy
- defensywne: HP, DEF, Unik, regeneracja HP i 5 odporności,
- ofensywne: ATK, Mana, Crit Chance, Crit Damage, Skill Damage,
  penetracja, damage vs Elite i damage vs Boss,
- brak duplikatów tego samego bonusu na jednym przedmiocie.

### Loot
- elity mają lepszy rozkład tierów niż zwykły drop,
- minibossowie mają dalszy bonus jakości,
- Krypta korzysta z premiumowego rozkładu,
- boss ma najwyższą szansę T4-T5 bez gwarantowanego T5,
- crafting wyposażenia generuje pełny zestaw affixów zgodnie z rarity.

### Walka
- affixy są podpięte do prawdziwych obliczeń walki,
- Crit Chance może odblokować krytyki bez pasywki,
- Crit Damage zwiększa mnożnik krytyczny,
- Skill Damage skaluje aktywne umiejętności,
- penetracja zmniejsza efektywny DEF celu,
- damage vs Elite/Boss działa sytuacyjnie,
- regeneracja i odporności integrują się z istniejącymi systemami.

### UI / przyszłe GUI
- plecak i ekwipunek otrzymały kompaktowe nagłówki Item Power/Bonusy,
- dodano ekran szczegółów instancji wyposażenia,
- dane affixów są strukturalne i niezależne od Console UI.

### Save
- schema v7 → v8,
- stare instancje dostają deterministyczny jednorazowy roll na podstawie instance_id,
- Item Power i affixy są dalej zapisywane bezpośrednio.


## [0.16.2] - Delikatniejsze skalowanie elit

### Balans elit
- zmniejszono przyrost szansy po zwykłym spotkaniu bez elity z +5 p.p. do +2 p.p.,
- bazowe szanse pozostają bez zmian: 10% dzień, 15% noc, 25% Zorza,
- maksymalna szansa nadal wynosi 95%,
- osobne liczniki map, reset po spotkaniu elity oraz brak losowych elit w Krypcie pozostają bez zmian.

### Save
- schema pozostaje v7,
- brak potrzeby nowej migracji.


## [0.16.1] - Narastająca szansa elit

### Elity
- bazowa szansa pozostaje 10% w dzień, 15% w nocy i 25% podczas Zorzy,
- każde kwalifikujące się spotkanie bez elity dodaje +5 p.p.,
- maksymalna szansa została ograniczona do 95% — nigdy nie ma gwarancji 100%,
- spotkanie elity resetuje licznik tylko bieżącego regionu,
- Zmierzchowe Równiny, Czarny Bór i Mokradła mają osobne liczniki,
- puste wyprawy i minibossowie nie zwiększają ani nie resetują licznika,
- Krypta nadal nie korzysta z losowych wariantów elit,
- dodano test integralności: każdy zwykły przeciwnik z map otwartego świata
  musi być zgodny z systemem elit.

### Save
- schema v6 → v7,
- liczniki elit dla poszczególnych regionów są zapisywane,
- restart gry nie resetuje narastającej szansy,
- pełna automatyczna migracja save v6 → v7.


## [0.16.0] - Elity i Kontrakty Gildii

### Elitarni przeciwnicy
- 10% szansy na elitę za dnia,
- 15% w nocy,
- 25% podczas Zorzy Polarnej,
- dodano: Wściekły, Opancerzony, Wampiryczny, Przeklęty i Żywiołowy,
- zgodność modyfikatorów jest kontrolowana per przeciwnik,
- elity dają +50% EXP, +25% Golda i +20% szans zwykłego dropu,
- Wampiryczne elity leczą się zadanymi obrażeniami,
- Przeklęte elity mogą odpierać krwawienie i roztrzaskanie pancerza,
- Żywiołowe elity zmieniają typ obrażeń według pogody i mają
  40% odporności na swój żywioł,
- pierwsze pokonanie każdego typu trafia do Dziennika Przygód.

### Gildia Poszukiwaczy
- zadania jednorazowe zostały oddzielone od powtarzalnych kontraktów,
- generowane są 3 kontrakty dzienne,
- generowany jest 1 kontrakt tygodniowy,
- Daily są automatycznie aktywne,
- kontrakty mogą śledzić: konkretne potwory, region, dostawy,
  elity, minibossy i ukończenie dungeonu,
- kontrakt tygodniowy może posiadać kilka celów jednocześnie,
- nagrody Daily są celowo umiarkowane, aby nie przywrócić inflacji.

### Reset kontraktów
- Daily: raz na lokalny dzień kalendarzowy,
- Weekly: raz na tydzień ISO (poniedziałek),
- zestaw jest zapisywany i nie rerolluje się po restarcie,
- cofnięcie daty systemowej nie wymusza ponownego losowania,
- zegar świata i odpoczynek w karczmie nie wpływają na reset.

### Save
- schema v5 → v6,
- pełna automatyczna migracja,
- zapisywane są kontrakty, ich progres, odebrane nagrody i
  odkryte typy elit.


## [0.15.2] - Balans ekonomii

### Gold z przeciwników
- Równiny i Czarny Bór pozostają bez zmian,
- obniżono powtarzalny Gold z Mokradeł o około 17–20%,
- pełna Krypta daje teraz około 1134–1264 Gold zamiast 1810–1978,
- Wielki Mistrz: 450–650 Gold zamiast 900–1200,
- EXP wszystkich przeciwników pozostaje bez zmian.

### Wydatki
- późne ulepszenia +7…+10 są droższe,
- koszt pełnego +0 → +10 wzrósł z 3025 do 4025 Gold
  (nie licząc materiałów),
- bossowy i dungeonowy crafting wymaga teraz dodatkowego Golda.

### Kram Orena
- dodano `Eliksir Arcymistrza` za 2500 Gold,
- przywraca 50 HP i 15 Many,
- można użyć go w walce; użycie nadal kosztuje turę.

### Save
- schema pozostaje v5,
- istniejący Gold i cały progres gracza pozostają nietknięte.


## [0.15.1] - Wejściówka do Krypty

### Krypta Zatopionego Zakonu
- wejście wymaga teraz `Starożytnego Klucza Zakonu x1`,
- klucz jest zużywany w momencie wejścia,
- brak klucza nie uruchamia wyprawy i nie zmienia ekwipunku,
- wymaganie wejścia zapisano w danych dungeonu, więc ten sam mechanizm można wykorzystać przy przyszłych instancjach.

### Źródła klucza
- `Matka Głuchej Wody` gwarantuje `Starożytny Klucz Zakonu x1`,
- nowa receptura:
  - Serce Głuchej Wody x1,
  - Płyta Zatopionego Zakonu x2,
  - Esencja Mgły x2,
  - 300 Gold,
- nowe zlecenie Gildii `Pieczęć Zatopionych`:
  - pokonaj Rycerza Zatopionego Zakonu x3,
  - nagroda: 220 EXP, 250 Gold i Starożytny Klucz Zakonu x1.

### Crafting
- receptury mogą teraz mieć opcjonalny koszt w Goldzie,
- koszt jest sprawdzany i pobierany atomowo razem z materiałami,
- nieudana próba craftingu nie zabiera części zasobów.

### Przedmioty
- dodano osobną kategorię `key`,
- kluczy do instancji nie można sprzedać Orenowi ani użyć jak mikstury.

### Zapis gry
- schema pozostaje `v5`,
- brak migracji sejwa.


## [0.15.0] - Krypta Zatopionego Zakonu

### Dungeon
- dodano pierwszy pełnoprawny dungeon pod Mokradłami Głuchej Wody,
- zalecany poziom: 7-10,
- HP i Mana nie odnawiają się automatycznie pomiędzy komnatami,
- po każdej większej sekcji można wycofać się do Varenhold,
- bezpieczny odwrót zachowuje łup z wyprawy,
- porażka usuwa tylko niezabezpieczony łup zdobyty podczas bieżącej wyprawy,
- Gold i EXP pozostają po porażce,
- po porażce bohater zostaje uratowany i wraca do pełnego HP/Many.

### Przebieg
- trzy losowane sekcje walk,
- rozwidlenie: Żelazne Wrota albo Zalany Korytarz,
- Zalany Korytarz zawiera skrzynię i ryzyko zasadzki,
- jednorazowa Zatopiona Kaplica przywraca 25% maks. HP i Many,
- obowiązkowa elita przed finałem.

### Nowi przeciwnicy
- Akolita Zatopionego Zakonu,
- Kapłanka Zatopionych [ELITA],
- Strażnik Żelaznych Wrót [ELITA],
- Strażnik Krypty [ELITA],
- Wielki Mistrz Zatopionego Zakonu [BOSS].

### Boss
- Wielki Mistrz posiada trzy fazy,
- poniżej 60% HP roztrzaskuje tarczę: ATK +3, DEF -3,
- poniżej 25% HP aktywuje Klątwę Głębin z dodatkowymi obrażeniami wodnymi co turę.

### Łup i crafting
- Pieczęć Zatopionego Zakonu,
- Łańcuch Wielkiego Mistrza,
- Fragment Zatopionej Korony,
- Miecz Wielkiego Mistrza,
- Płaszcz Zatopionego Zakonu,
- Pierścień Głębin,
- wszystkie nowe materiały od razu mają zastosowanie w craftingu.

### Pogoda i zapis
- pogoda świata zmienia się podczas długiej wyprawy, ale nie wzmacnia przeciwników pod ziemią,
- schema save pozostaje v5 — brak migracji względem v0.14.0.


## [0.14.0] - Klasy i aktywne umiejętności

### Klasy
- od poziomu 5 można wybrać Wojownika, Łowcę albo Maga,
- wybór klasy jest stały,
- Wojownik otrzymuje 12 bazowej Many,
- Łowca otrzymuje 16 bazowej Many,
- Mag otrzymuje 24 bazowej Many.

### Aktywne umiejętności
- każda klasa ma 4 umiejętności,
- odblokowania następują na poziomach 5, 7, 9 i 12,
- umiejętności zużywają Manę,
- brak Many lub zablokowana umiejętność nie zużywa tury.

### Walka
- dodano opcję `Umiejętności`,
- ekran walki pokazuje HP i Manę,
- dodano krwawienie,
- dodano czasowe obniżenie DEF przeciwnika,
- dodano czasową redukcję obrażeń,
- dodano czasowy bonus do Uniku,
- aktywne efekty są widoczne na ekranie walki.

### Skalowanie
- Wojownik opiera umiejętności głównie na ATK,
- Łowca wykorzystuje ATK oraz część Zręczności,
- Mag wykorzystuje Inteligencję; zaklęcia ignorują połowę DEF.

### Save
- schema podniesiona z v4 do v5,
- stare zapisy v4 są automatycznie migrowane,
- istniejąca postać nie dostaje klasy automatycznie,
- po migracji gracz sam wybiera Drogę,
- wybór klasy jest automatycznie zapisywany.


## [0.13.3] - Audit Hotfix: Domknięcie materiałów

### Naprawiono
- każdy z 35 materiałów ma teraz przynajmniej jedną recepturę,
- każdy materiałowy składnik craftingu ma źródło w dropie,
- każdy przeciwnik daje przynajmniej jeden drop z zastosowaniem,
- bossowe Serca są teraz zabezpieczeniem przed pechowym RNG.

### Dodano receptury
- Ząb Wilka,
- Prowiant Myśliwego,
- Pierścień Natury,
- Wisiorek Kultysty,
- Pas z Czarnej Skóry,
- Talizman Czarnego Jelenia,
- Topór Leśnego Egzekutora,
- Maska Leśnego Egzekutora,
- Rękawice Topielca,
- Kolczyki Wędrowca Mgieł,
- Pancerz Zatopionego Zakonu,
- Ostrze Matki Głuchej Wody,
- Korona Utopionej Matki.

### Questy
- `Matka z głębin` daje teraz `Mocna Mikstura Lecznicza x3`
  zamiast dodatkowego `Serca Głuchej Wody`.

### UI
- crafting jest pogrupowany nagłówkami regionów.

### Zapis gry
- schema pozostaje `v4`,
- brak migracji sejwa.


## [0.13.2] - Audit Hotfix: Sprzedaż partiami

### Zmieniono

- Oren pozwala sprzedawać kilka różnych materiałów i przedmiotów użytkowych w jednej transakcji,
- można podawać ilości, np. `1x5, 2, 4xMAX`,
- wyposażenie można zaznaczać grupowo, np. `1,3,5-7`,
- przed wykonaniem sprzedaży pojawia się podsumowanie i potwierdzenie całej transakcji,
- sprzedaż grupowa jest atomowa: błędna pozycja nie powoduje częściowej utraty przedmiotów,
- schema zapisu pozostaje bez zmian (`v4`).


## [0.13.1] - Audit Hotfix

### Poprawiono

- możliwość wydawania wielu punktów atrybutów jednocześnie,
- możliwość wydawania wielu punktów pasywnych jednocześnie,
- obsługę komendy `MAX` przy rozdawaniu punktów,
- atomową walidację wydawania punktów,
- nazwę `Szatka Kultysty` na `Fragment Szaty Kultysty`.

### Audyt

- potwierdzono, że `cultist_cloth` nie ma obecnie zastosowania w craftingu ani questach,
- zidentyfikowano pozostałe materiały służące obecnie wyłącznie jako loot handlowy,
- dodano testy integralności danych między lootem, questami, craftingiem, lokacjami, sklepem, setami i pogodowym lootem.

### Zapis gry

- schema zapisu pozostaje `v4`,
- brak migracji sejwa,
- `item_id` przedmiotów nie zostały zmienione.

## [0.13.0] - Żywy Świat

### Dodano — pogoda i rzadkie wydarzenia

- globalny system pogody,
- status pogody wyświetlany pod nagłówkiem gry,
- `SŁONECZNIE` jako pogoda bazowa,
- `BURZA` — 20% w losowaniu pogody,
- `MRÓZ` — 20%,
- `WICHURA` — 20%,
- `ZORZA POLARNA` — 10%,
- sześciogodzinne okresy pogody,
- Zorzę jako rzadkie wydarzenie wzmacniające przeciwników i nagrody,
- zapisywanie i wczytywanie aktualnej pogody.

### Dodano — bossowie i loot pogodowy

- modyfikatory minibossów zależne od Burzy, Mrozu i Wichury,
- globalne wzmocnienie przeciwników podczas Zorzy,
- zwiększone EXP, Gold i szanse na loot podczas Zorzy,
- specjalne bronie minibossów zależne od pogody,
- warianty Burzy, Mrozu, Wichury i Zorzy dla Strażnika Natury, Leśnego Egzekutora i Matki Głuchej Wody.

### Dodano — odporności

- odporność na ogień,
- odporność na wiatr,
- odporność na mróz,
- odporność na ziemię,
- odporność na wodę,
- maksymalną efektywną odporność 75%,
- obrażenia żywiołowe przeciwników,
- odporności na wybranym wyposażeniu.

### Dodano — pasywki

- 1 punkt pasywny co 2 poziomy,
- maksymalnie 5 poziomów jednej pasywki,
- `Szybkość Ataku`,
- `Obrażenia Krytyczne`,
- `Regenerację Zdrowia`,
- `Zwiększenie Ataku`,
- osobne menu rozwoju pasywnego.

### Dodano — zestawy

- system zestawów wyposażenia,
- pełny `Zestaw Natury`,
- bonus aktywowany dopiero po założeniu wszystkich wymaganych elementów,
- `Pierścień Natury`,
- 20% szansy na Pierścień Natury ze Strażnika Natury.

### Dodano — osiągnięcia, tytuły i dziennik

- system osiągnięć,
- tytuły odblokowywane osiągnięciami,
- możliwość wyboru aktywnego tytułu,
- Dziennik Przygód przechowujący najważniejsze zdarzenia,
- automatyczne rozpoznawanie części osiągnięć z istniejącego save'a.

### Dodano — mechaniki przeciwników z pierwotnych notatek

- Dziki Pies: 20% szansy na drugi atak,
- Dzik: +2 obrażenia przy pierwszej szarży,
- Bandyta: 20% szansy na +1 obrażenie,
- Przeklęty Strach na Wróble: -1 otrzymanych obrażeń fizycznych,
- Duch Równin: 25% Uniku,
- Myśliwy: 25% szansy na +2 obrażenia.

Obecne, przetestowane statystyki HP/ATK/DEF przeciwników pozostawiono bez zmian.

### Zmieniono — handel

- można kupić dowolną liczbę sztuk jednego towaru w jednej transakcji,
- można wpisać konkretną ilość albo `MAX`,
- sklep pokazuje maksymalną liczbę sztuk możliwych do kupienia za aktualny Gold,
- zakup waliduje pełny koszt przed pobraniem Golda.

### Zapis gry

- schema zapisu: `v4`,
- automatyczna migracja `v3 -> v4`,
- kompatybilność również ze starszymi formatami,
- zapis pogody,
- zapis pasywek,
- zapis osiągnięć i aktywnego tytułu,
- zapis Dziennika Przygód.

### Decyzje balansowe dodane poza notatnikiem

Notatnik określał kierunek systemów, ale nie podawał wszystkich wartości. W v0.13.0 dobrano więc:

- czas trwania pogody: 6 godzin świata,
- konkretne premie pogodowe bossów,
- nazwy, statystyki i szanse pogodowych broni,
- statystyki Pierścienia Natury,
- wartości bonusu pełnego Zestawu Natury,
- skalowanie czterech pasywek,
- listę i warunki obecnych osiągnięć oraz tytułów.

## [0.12.3] - Hotfix widoczności questów

- aktywne zadania znikają z Tablicy Zleceń,
- ukończone i oddane zadania znikają z tablicy na stałe,
- ukończonych zadań nie można powtarzać.

## [0.12.2] - Hotfix Ukończonych Zadań
## [0.12.1] - Hotfix Tablicy Zleceń
## [0.12.0] - Gildia Poszukiwaczy i Mokradła Głuchej Wody
## [0.11.0] - Varenhold
## [0.10.0] - Save / Load
## [0.9.0] - Kowal i Ulepszanie
## [0.8.0] - Mikstury i Crafting
## [0.7.0] - Mapa Świata i Czarny Bór
## [0.6.0] - Rozwój Bohatera
## [0.5.0] - Przedmioty i Ekwipunek
## [0.4.0] - Zmierzchowe Równiny
## [0.3.0] - Fundament walki
## [0.2.0] - Bohater
## [0.1.0] - Fundament projektu
