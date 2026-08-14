# Echoes of Pythonia

## Aktualna wersja

**0.24.7 — Przygotowanie do wyprawy**


### Przygotowanie do wyprawy v0.24.7

Varenhold ma teraz centralny ekran **Przygotowanie do wyprawy**. W jednym miejscu wybierasz cel, sprawdzasz HP/Manę i udźwig, ustawiasz aktywną drużynę, taktyki AI kompanów, ekwipunek oraz zapasy. Z Magazynu Gildii można pobierać wyłącznie potrzebne zapasy bez biegania przez kilka menu.

Cztery trwałe taktyki kompanów — **Agresywna / Zrównoważona / Ostrożna / Obronna** — wpływają na zachowanie AI w Szczelinach. Dodano też presety **SOLO / BOSS / DUNGEON / SZCZELINA**, które zapamiętują skład i docelowe ilości mikstur/prowiantu oraz potrafią uzupełnić brakujące zapasy z Magazynu.

Ekran przygotowania ostrzega o niskim HP, braku leczenia, ciężko rannych kompanach i przeciążeniu. Przeciążenie blokuje wyruszenie, ale pozostałe ryzyka można zaakceptować świadomie. Save schema: **v15**; zapis v14 migruje automatycznie.

**v0.24.7 zamyka rozwój nowych funkcji w terminalu.** Kolejne v0.24.x to wyłącznie bugfixy/balans, a następny duży etap to **v0.25.0 — migracja do Godot 4 + GDScript**.

### Leczenie i odpoczynek v0.24.6

Ognisko nie resetuje już bohatera do pełna. Darmowy odpoczynek przywraca 25% maksymalnego HP i 35% maksymalnej Many, a kolejny jest dostępny dopiero po następnej wyprawie lub walce. Pełne leczenie zapewnia Karczma Pod Czarnym Krukiem za koszt rosnący z poziomem i z ograniczeniem do kolejnego dnia Pythonii.

Mikstury zostały przeskalowane i można je kondensować u Mireli: `3x Słaba → Mocna`, `3x Mocna + Esencja Mgły → Wielka`, `2x Wielka + Iskra Życia → Eliksir Arcymistrza`. Eliksir Arcymistrza skaluje się procentowo z maksymalnym HP i Maną.

Audyt potwierdził, że wszystkie 53 materiały mają zastosowanie. Plecak ma nową opcję **Sprawdź zastosowanie materiału / wejściówki**, która pokazuje konkretne receptury albo dungeon otwierany przez wejściówkę. Przy okazji naprawiono niewidoczną wcześniej recepturę Starożytnego Klucza Zakonu. Save schema pozostaje v14.

### Czytelna waga v0.24.5

Plecak i Magazyn Gildii pokazują teraz **łączną wagę każdego stosu**, dzięki czemu od razu widać, które materiały i zapasy najbardziej obciążają bohatera. Przy odkładaniu i odbieraniu u Kwatermistrza wyświetlana jest także waga jednej sztuki, a zapasowe wyposażenie w Plecaku pokazuje własną wagę. Same wartości wag i balans udźwigu nie zostały zmienione.

### Magazyn Gildii QoL v0.24.4

U Kwatermistrza można teraz przenosić wiele rzeczy jednym wyborem. Wyposażenie obsługuje listy i zakresy, np. `1,3,5-7`. Stosy można przenosić w całości (`1,3,5`) albo w podanej liczbie (`1x5,2xMAX,4x2`). Operacje grupowe zachowują pełne dane konkretnych egzemplarzy wyposażenia.

Gildia otrzymała pełny **Party System**. Bohater może związać się maksymalnie z czterema ręcznie napisanymi kompanami: trzema aktywnymi i jednym pozostającym w Varenhold. Kandydaci zmieniają się raz na dzień Pythonii, a każdy pojawia się w utrwalonym wariancie poziomu, klasy, drzewka, talentów, atrybutów, ekwipunku i osobistego questline'u. Ekwipunek jest ukryty przed rekrutacją, a rzadkie ścieżki mogą uczynić konkretnego kandydata wyjątkowo wartościowym.

Kompanów rozwija własny EXP i AI klasowe. Mają ręcznie napisane rozmowy, wiadomości, sceny obozowe, relacje i wątki osobiste. Ich własnego wyposażenia nie można zabrać; sprzęt powierzony przez gracza można swobodnie odzyskać. Rozstanie zachowuje historię postaci i pozwala jej później wrócić do świata.

Nowym drużynowym endgame'em są **Szczeliny Przebudzenia F–S**. To długie, jednorazowe proceduralne ekspedycje składane z ręcznie przygotowanych motywów, wydarzeń, modyfikatorów i bossów. Trwają od 12 do 24 segmentów, wymagają party i istnieją tylko przez kilka dni Pythonii. Jeśli gracz zwleka, Szczelinę może zamknąć inna drużyna Poszukiwaczy. Po rozpoczęciu ekspedycji Szczelina zostaje zarezerwowana dla gracza; pokonanie jej głównego bossa zamyka ją permanentnie.

W wyższych Szczelinach powalony kompan może znaleźć się pod zapowiadaną **Egzekucją**. Permanentna śmierć nigdy nie jest losowym procem: gracz otrzymuje ostrzeżenie i czas na ratunek. Brak pomocy może zakończyć historię kompana na zawsze; w mniej groźnych sytuacjach NPC zostaje `CIĘŻKO RANNY` i wraca do sił przez kilka dni Pythonii.

Dodano również **16 nowych Unikatów Szczelin (po 4 na klasę)**, których efekty wpływają na mechaniki buildów, a nie tylko na bazowe statystyki. Nie są craftowane ani farmione z normalnych przeciwników — najważniejsza nagroda jest związana z zamknięciem całej ekspedycji.

Save schema: **v15**. Zapisy v0.24.x/v14 i starsze wspierane formaty migrują automatycznie.

### Party Setup v0.24.1

Menu `Drużyna i kompani` ma teraz osobny ekran **Ustaw skład wyprawy**. Można w nim szybko wybrać do 3 kompanów idących z bohaterem albo jednym wyborem przełączyć grę na **SOLO**, pozostawiając wszystkich kompanów w Varenhold. Trwająca ekspedycja Szczeliny nadal blokuje zmianę składu.

### Kwatermistrz i Udźwig v0.24.2

W Gildii działa teraz **Kwatermistrz** z Magazynem Gildii na 200 miejsc. Można tam odkładać zapasowe unikaty, materiały, księgi i sprzęt przygotowywany dla przyszłych kompanów. Konkretne egzemplarze wyposażenia zachowują ulepszenia, affixy i własne `instance_id`.

Plecak ma miękki **Udźwig**: 50 kg bazowo, +0.5 kg za punkt Siły i +1.5 kg za punkt Wytrzymałości. Założony sprzęt nie liczy się do limitu plecaka. Przy 75% pojemności stan zmienia się na `Obciążony`; przekroczenie limitu daje `Przeciążony`. Łup nadal zawsze trafia do plecaka — przeciążenie blokuje tylko rozpoczęcie kolejnej zwykłej wyprawy regionalnej.

Kwatermistrz sprzedaje również trzy trwałe ulepszenia udźwigu: +10 kg, +20 kg i +35 kg. W tej wersji testowej `Obciążony` nie nakłada jeszcze kary do walki; najpierw testujemy, czy sam system logistyczny jest wygodny.

### Spójność wyposażenia v0.24.3

Poprawiono dwie nazwy wyposażenia, aby czytelnie odpowiadały slotom: `Karwasz Kapitana` został przemianowany na **Bransoletę Czarnej Floty**, a `Relikt Burzowego Archiwum` na **Medalion Burzowego Archiwum**. Wewnętrzne `item_id` pozostają bez zmian, więc istniejące egzemplarze, ulepszenia i affixy zachowują pełną kompatybilność ze starymi zapisami. Dodano także test semantyczny wyłapujący najbardziej oczywiste pomyłki nazw względem slotów. Save schema pozostaje **v14**.

## Najważniejsze systemy v0.13.0

### Pogoda świata

Pogoda jest teraz częścią stanu świata i pojawia się pod nagłówkiem gry na wszystkich ekranach.

- `SŁONECZNIE` — 30%,
- `BURZA` — 20%,
- `MRÓZ` — 20%,
- `WICHURA` — 20%,
- `ZORZA POLARNA` — 10%.

Jedna pogoda trwa 6 godzin czasu gry. Zorza jest rzadkim wydarzeniem: wzmacnia wszystkich przeciwników, podnosi nagrody i zwiększa szanse na zwykły loot.

### Bossowie zależni od pogody

Minibossowie reagują na aktualną pogodę. Burza, Mróz i Wichura dają im różne wzmocnienia, a podczas Zorzy wszystkie potwory stają się groźniejsze.

Miniboss może również wyrzucić specjalną broń powiązaną z pogodą. Każdy z obecnych minibossów ma warianty Burzy, Mrozu, Wichury oraz bardzo rzadki wariant Zorzy.

### Odporności żywiołowe

Bohater posiada pięć odporności:

- ogień,
- wiatr,
- mróz,
- ziemia,
- woda.

Odporności pochodzą obecnie głównie z wyposażenia i zestawów. Ich efektywna wartość jest ograniczona do 75%, aby nie można było uzyskać całkowitej niewrażliwości.

### Umiejętności pasywne

Co 2 poziomy bohater otrzymuje 1 punkt pasywny. Bez odpowiedniej Księgi Mistrzostwa każda pasywka zatrzymuje się na 5/5; przeczytanie właściwej księgi permanentnie otwiera poziomy 6–10.

- **Szybkość Ataku** — do 25% na 5/5 i 35% na 10/10,
- **Obrażenia Krytyczne** — do 9% / x2.75 na 5/5 i 14% / x3.00 na 10/10,
- **Regeneracja Zdrowia** — +15 HP na 5/5 i +35 HP na 10/10 po turze przeciwnika,
- **Zwiększenie Ataku** — +10 ATK na 5/5 i +25 ATK na 10/10.

### Zestawy wyposażenia

Pierwszym pełnym setem jest **Zestaw Natury**:

- Amulet Natury,
- Pierścień Natury,
- Bransoleta Natury,
- Kolczyki Natury.

Po założeniu całego zestawu bohater otrzymuje dodatkowy bonus do ATK, DEF, HP oraz odporności na ziemię. `Pierścień Natury` został dodany do dropu Strażnika Natury z szansą 20%.

### Osiągnięcia i tytuły

Osiągnięcia odblokowują tytuły, które można zakładać na bohatera. Są m.in. nagrody za pierwsze zwycięstwo, pokonanie minibossów, polowanie podczas Zorzy, maksymalne ulepszenie przedmiotu i wykonanie wszystkich obecnych zleceń Gildii.

### Dziennik Przygód

Dziennik zapisuje najważniejsze wydarzenia rozgrywki: pogodę, zdobyte poziomy, loot pogodowy, crafting, ulepszenia, questy i inne istotne wydarzenia. Jest dostępny w menu Bohatera.

### Zakupy wielu sztuk

Po wybraniu przedmiotu u Orena gra pyta o ilość. Można wpisać konkretną liczbę lub `MAX`.

Przykład:

```text
Ile sztuk? Maksymalnie za obecny Gold: 17
Wpisz liczbę albo MAX. [0] Anuluj
> 10

Kupiono: Słaba Mikstura Lecznicza x10 za 200 Gold.
```

### Oryginalne mechaniki przeciwników z pierwszego regionu

Przywrócono mechaniki zapisane w notatkach bez naruszania sprawdzonego w praktyce balansu statystyk:

- Dziki Pies — 20% szansy na drugi atak,
- Dzik — pierwsze uderzenie ma premię szarży +2,
- Bandyta — 20% szansy na mocniejsze Sprytne Cięcie,
- Przeklęty Strach na Wróble — redukuje fizyczne obrażenia o 1,
- Duch Równin — 25% Uniku,
- Myśliwy — 25% szansy na Celny Strzał +2.

Nie podmieniono obecnych wartości HP/ATK/DEF przeciwników na późniejszą tabelę z notatnika, ponieważ aktualny balans trzech regionów został już przetestowany i zaakceptowany podczas gry.

## Zapis gry

Aktualny schemat zapisu to **v15**. Starsze wspierane zapisy są automatycznie migrowane. Plik nadal znajduje się poza folderem projektu:

```text
%LOCALAPPDATA%\EchoesOfPythonia\saves\save_1.json
%LOCALAPPDATA%\EchoesOfPythonia\saves\save_2.json
%LOCALAPPDATA%\EchoesOfPythonia\saves\save_3.json
%LOCALAPPDATA%\EchoesOfPythonia\saves\save_4.json
```

Save przechowuje m.in. pogodę, pasywki i ich Mistrzostwa, osiągnięcia, tytuły, kontrakty, rangi/reputację Gildii, stan odrodzenia bossów, odblokowanie Czarnego Rynku, jego rotację i wyniki targowania.

## Uruchomienie

```bash
python main.py
```

## Testy

```bash
python -m unittest discover -s tests -v
```


## Faza stabilizacji v0.13.1

Nie są dodawane nowe systemy rozgrywki. Priorytetem są testy, usuwanie błędów, niespójności danych i poprawa obsługi istniejących mechanik.

Atrybuty i pasywki można rozdawać wieloma punktami naraz, wpisując liczbę lub `MAX`.


## Audit Hotfix 0.13.2 — Sprzedaż partiami

U Orena można teraz sprzedawać wiele rzeczy w jednej transakcji.

Materiały i przedmioty użytkowe:
- `1x5` — pięć sztuk pozycji 1,
- `2` — jedna sztuka pozycji 2,
- `4xMAX` — cały stos pozycji 4,
- można łączyć wybory przecinkami: `1x5, 2, 4xMAX`.

Wyposażenie:
- `1,3,5-7` wybiera konkretne egzemplarze z plecaka.

Przed finalną sprzedażą gra pokazuje listę przedmiotów i łączną
wartość Golda oraz wymaga potwierdzenia.

Format zapisu nie zmienił się względem 0.13.1.


## Audit Hotfix 0.13.3 — materiały i crafting

Od tej wersji testy pilnują pełnego obiegu:
`potwór → drop → materiał → crafting`.

- każdy materiał ma zastosowanie,
- każdy materiałowy składnik receptury ma źródło w dropie,
- każdy przeciwnik ma przynajmniej jeden użyteczny drop,
- trzy gwarantowane Serca minibossa pozwalają wycraftować
  jeden z jego głównych przedmiotów,
- pogodowe bronie bossów pozostają wyłącznie rzadkim lootem.

Crafting jest teraz pogrupowany według regionów.

Schema zapisu pozostaje `v4`.


## v0.14.0 — Klasy i aktywne umiejętności

Od poziomu 5 bohater może wybrać jedną stałą Drogę:

- **Wojownik** — bazowo +12 maks. Many; ciężkie uderzenia i obrona.
- **Łowca** — bazowo +16 maks. Many; precyzja, uniki i krwawienie.
- **Mag** — bazowo +24 maks. Many; zaklęcia skalujące się z Inteligencją.

Klasy mają po cztery aktywne umiejętności odblokowywane na
poziomach 5, 7, 9 i 12.

### Wojownik
- Potężne Cięcie
- Roztrzaskanie Pancerza
- Postawa Obronna
- Krwawy Zamach

### Łowca
- Precyzyjny Strzał
- Krwawiący Strzał
- Krok w Cieniu
- Podwójny Strzał

### Mag
- Ognisty Pocisk
- Lodowa Lanca
- Piorun
- Wybuch Many

Walka posiada teraz osobną opcję `Umiejętności`, pokazuje Manę
oraz aktywne efekty statusu.

Wybór klasy jest nieodwracalny dla danej postaci i jest automatycznie
zapisywany. Starszy save pozostaje kompatybilny: zapis schema v4
migruje do v5 jako `Poszukiwacz`, dzięki czemu gracz sam wybiera klasę.

Mana odnawia się podczas pełnego odpoczynku tak jak wcześniej.

Save schema: **v5**.


## v0.15.0 — Krypta Zatopionego Zakonu

Pierwszy dungeon znajduje się na Mokradłach Głuchej Wody.
Zalecany poziom to 7-10.

W dungeon:
- HP i Mana przechodzą między kolejnymi walkami,
- gracz wybiera, czy iść głębiej, czy zabezpieczyć łup i wrócić,
- porażka usuwa wyłącznie niezabezpieczone przedmioty zdobyte podczas tej wyprawy,
- Gold i EXP nie są odbierane,
- dostępne jest rozwidlenie, skrzynia z ryzykiem zasadzki i jednorazowa kaplica,
- finałowy Wielki Mistrz Zatopionego Zakonu ma trzy fazy walki.

Nowe materiały dungeonowe są od razu powiązane z craftingiem.
Pogoda nie wzmacnia przeciwników wewnątrz Krypty.

Save schema pozostaje **v5**.


## v0.15.1 — Starożytny Klucz Zakonu

Krypta Zatopionego Zakonu wymaga teraz jednej wejściówki na każdą
rozpoczętą wyprawę:

`Starożytny Klucz Zakonu x1`

Klucz jest zużywany przy wejściu do Krypty.

### Źródła
1. **Matka Głuchej Wody** — gwarantowany drop x1.
2. **Crafting** — Serce Głuchej Wody x1, Płyta Zatopionego Zakonu x2,
   Esencja Mgły x2 oraz 300 Gold.
3. **Gildia Poszukiwaczy** — zlecenie `Pieczęć Zatopionych` za pokonanie
   trzech Rycerzy Zatopionego Zakonu.

Klucz ma osobną kategorię przedmiotu, nie jest miksturą ani materiałem
handlowym i nie można sprzedać go Orenowi.

Receptury obsługują od tej wersji opcjonalny koszt Golda.

Save schema pozostaje **v5**.


## v0.15.2 — Balans ekonomii

Aktualizacja ogranicza inflację późnej gry bez spowalniania początku.

- Gold z Równin i Czarnego Boru nie został zmniejszony.
- Mokradła i Krypta generują mniej powtarzalnego Golda.
- Wielki Mistrz daje 450–650 Gold.
- Koszt ulepszenia przedmiotu +0 → +10 wynosi teraz 4025 Gold
  plus wymagane materiały.
- wysokopoziomowy crafting pobiera dodatkowy Gold.
- Oren sprzedaje Eliksir Arcymistrza za 2500 Gold:
  +50 HP i +15 Many.

Save schema pozostaje **v5**.


## v0.16.0 — Elity i Kontrakty Gildii

### Elity
Zwykli przeciwnicy w otwartym świecie mogą pojawić się jako elity.

Szansa:
- dzień: 10%,
- noc: 15%,
- Zorza Polarna: 25%.

Modyfikatory:
- Wściekły — większy ATK, mniejszy DEF,
- Opancerzony — większe HP i DEF,
- Wampiryczny — odzyskuje część zadanych obrażeń,
- Przeklęty — silniejsze ataki specjalne i odporność na debuffy,
- Żywiołowy — żywioł zależny od pogody i 40% odporności na niego.

Nie każdy przeciwnik może otrzymać każdy modyfikator.

Wszystkie elity:
- +50% bazowego EXP,
- +25% bazowego Golda,
- +20% do szans zwykłego dropu.

Pierwsze pokonanie każdego z pięciu typów elit trafia do
Dziennika Przygód.

### Kontrakty dzienne
Gildia generuje 3 kontrakty na lokalny dzień kalendarzowy:
- polowanie na konkretnych przeciwników,
- dostawa materiałów,
- polowanie na elity / patrol dla początkujących.

Kontrakty są automatycznie aktywne. Nie trzeba przyjmować każdego
osobno. Wygenerowany zestaw jest zapisany w sejwie.

### Kontrakt tygodniowy
Jeden większy kontrakt jest generowany na tydzień ISO.
Dla rozwiniętej postaci łączy kilka celów, np.:
- walki w regionie,
- pokonanie elit,
- ukończenie Krypty Zatopionego Zakonu.

### Czas
Daily i Weekly korzystają z lokalnej daty systemowej wyłącznie
przy odświeżaniu tablicy. Zegar świata Pythonii nie został zmieniony.
Odpoczynek w karczmie nie pozwala resetować kontraktów.

### Save
Schema: **v6**.
Save v5 migruje automatycznie. Po migracji nowe kontrakty zostaną
utworzone przy pierwszym sprawdzeniu systemu.


## v0.16.1 — Narastająca szansa elit

Każdy z trzech regionów otwartego świata posiada własny licznik
zwykłych spotkań od ostatniej elity.

Efektywna szansa:

`bazowa szansa + (licznik × 5 punktów procentowych)`

Bazowe wartości pozostają:
- dzień: 10%,
- noc: 15%,
- Zorza Polarna: 25%.

Przykład dla dnia:
`10% → 15% → 20% → 25% → ... → maks. 95%`.

Nie istnieje gwarantowane 100%. Nawet przy bardzo długiej serii
zwykłych przeciwników maksymalna szansa pozostaje 95%.

Spotkanie elity zeruje wyłącznie licznik regionu, w którym elita
wystąpiła. Pozostałe mapy zachowują własny postęp.

Puste wyprawy i minibossowie nie zmieniają licznika.
Krypta Zatopionego Zakonu nadal nie korzysta z losowych wariantów elit.

Schema zapisu: **v7**. Save v6 migruje automatycznie.


## v0.16.2 — Delikatniejsze skalowanie elit

Narastająca szansa elit pozostaje w grze, ale wzrost po każdym zwykłym spotkaniu bez elity został obniżony z **+5 p.p.** do **+2 p.p.**

Przykład dla dnia:
`10% → 12% → 14% → 16% → 18% → ...`

Zasady bez zmian:
- osobny licznik dla każdej mapy,
- reset tylko po spotkaniu elity na danej mapie,
- brak gwarantowanego 100%,
- maksymalna szansa 95%,
- Krypta nie korzysta z losowych elit,
- schema zapisu pozostaje **v7**.


## v0.17.0 — Equipment 2.0

- defensywne sloty: Hełm / Zbroja / Rękawice / Buty,
- ofensywne sloty: Broń / Naszyjnik / Bransoleta / Kolczyki / Pierścień,
- Pas korzysta z obu pul z osłabioną wartością rolla,
- rarity daje dokładnie 0/1/2/3/4 losowe bonusy,
- każdy bonus posiada T1–T5,
- Item Power I–IV skaluje aktualną zawartość,
- flat stats posiadają przygotowaną krzywą pod przyszły endgame,
- procenty mają twarde capy,
- elity/minibossowie/Krypta/boss przesuwają jakość rolla w stronę wyższych tierów,
- Crit, Crit Damage, Skill Damage, penetracja, damage vs Elite/Boss i regen działają w realnej walce,
- plecak pokazuje wersję kompaktową, a pełne bonusy są dostępne w szczegółach,
- schema save v8; istniejące przedmioty z v7 otrzymują stabilny jednorazowy roll.


## v0.17.1 — Gramatyka i balans elit

- poprawiono odmianę prefiksów elit dla nazw żeńskich,
- każda elita ma teraz mocniejszą wspólną bazę statystyk,
- modyfikatory elit zostały wzmocnione, szczególnie Żywiołowy,
- Zorza + elita pozostają kumulatywnym, rzadkim spotkaniem,
- losowe elity nadal występują wyłącznie na mapach otwartego świata,
- save schema pozostaje **v8**.


## v0.17.2 — UI Cleanup

- listy wyposażenia nie pokazują już zbędnego licznika `Bonusy: X`,
- pełne bonusy nadal są dostępne w szczegółach przedmiotu,
- menu Varenhold zostało uproszczone do samych nazw miejsc i usług,
- brak zmian w balansie i save schema (v8).


## v0.17.4 — Combat UI polish

Na ekranie walki oznaczenie rangi przeciwnika nie pojawia się już w osobnej linii nad statystykami. Teraz jest częścią nazwy celu, np. ` [ELITA] Wampiryczna Bagienna Wiedźma `. Dotyczy to także minibossów i bossów.


## v0.17.5 — Wygodniejsze szczegóły ekwipunku

W sekcji szczegółów założonego ekwipunku można teraz przeglądać kolejne przedmioty bez opuszczania listy. Dodano także `[A] Pokaż wszystkie szczegóły`, aby wyświetlić pełne statystyki całego założonego zestawu na jednym ekranie. Save schema pozostaje v8.


## v0.17.6 — Dungeon UI cleanup

Przy wymaganym kluczu do Krypty wyświetlana jest już tylko czytelna liczba, np. `Starożytny Klucz Zakonu: 2/1`. Usunięto redundantne statusy `[GOTOWE]` i `[BRAK]`.


## v0.17.8 — Czytelniejszy status craftingu

Receptura, której nie można obecnie wykonać, pokazuje teraz `[BRAK WYMAGANYCH ZASOBÓW]` zamiast `[BRAKI]`. Statusy poszczególnych materiałów nadal używają krótkich `[OK]` i `[BRAK]`.


## v0.17.9 — Equipment UI cleanup

Etykiety roli przedmiotu (`Defensywny`, `Ofensywny`, `Mieszany`) zostały usunięte z interfejsu gracza. Role pozostają częścią wewnętrznego modelu Equipment 2.0 i nadal określają dostępne pule affixów.


## v0.17.10 — Wygodniejsze ulepszanie

Kowal obsługuje teraz kilka kolejnych ulepszeń w jednej operacji. Po wybraniu przedmiotu można podać liczbę ulepszeń albo użyć `MAX`, które oznacza maksymalną liczbę poziomów dostępną przy aktualnym Goldzie i materiałach. Przed zatwierdzeniem wyświetlany jest łączny koszt całej operacji.

Statusy na liście kowala zostały uproszczone do `[MOŻNA ULEPSZYĆ]`, `[BRAK ZASOBÓW]` i `[MAX]`. Koszty pojedynczych poziomów nie zostały zmienione. Save schema pozostaje **v8**.


## v0.17.11 — Porządek u kowala

Lista przedmiotów w kuźni została podzielona na dwie czytelne sekcje: `ZAŁOŻONE` i `PLECAK`. Numeracja jest wspólna dla obu sekcji, więc sposób wybierania przedmiotów się nie zmienia.


## v0.18.0 — Item Progression + Signature Dungeon Weapons

### Wymagany poziom
Wyposażenie posiada teraz osobny `required_level`.

Są to trzy niezależne osie progresji:
- `+0..+10` — poziom ulepszenia przedmiotu,
- `Item Power` — skala jego statystyk i affixów,
- `Wymagany poziom` — minimalny poziom bohatera potrzebny do założenia.

Aktualny rozkład:
- start: 0,
- Zmierzchowe Równiny: 1-3,
- Czarny Bór: 3-5,
- Mokradła Głuchej Wody: 5-8,
- Krypta Zatopionego Zakonu: 10.

Przedmiot można zdobyć i przechowywać przed osiągnięciem wymaganego
poziomu, ale próba założenia zostanie zablokowana.

### Miecz Wielkiego Mistrza — pierwsza Signature Dungeon Weapon
Miecz Wielkiego Mistrza jest pierwszą bronią z osobnym rollem
`Średnich Obrażeń`.

- wymagany poziom: 10,
- Średnie Obrażenia: od -5% do +15%,
- właściwość nie zajmuje slotu affixu,
- każdy egzemplarz losuje ją osobno,
- działa na zwykłe ataki i dodatkowe uderzenia,
- nie zwiększa obrażeń umiejętności — od nich istnieje `Skill Damage`,
- Wielki Mistrz ma 12% bezpośredniej szansy na miecz,
- crafting pozostaje bad-luck protection i korzysta z jakości generacji
  bossowego sprzętu.

### Save
Schema: **v9**.
Istniejące Miecze Wielkiego Mistrza z save v8 otrzymują jednorazowy,
deterministyczny roll Średnich Obrażeń oparty o `instance_id`.
Ich dotychczasowe affixy T1-T5 nie są losowane ponownie.
