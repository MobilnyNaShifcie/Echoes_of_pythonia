# Roadmap

## Ukończone

- [x] fundament aplikacji,
- [x] bohater i progresja,
- [x] walka,
- [x] Zmierzchowe Równiny,
- [x] przedmioty i ekwipunek,
- [x] atrybuty,
- [x] Czarny Bór,
- [x] crafting i mikstury,
- [x] kowal +0 do +10,
- [x] save / load,
- [x] Varenhold i NPC-usługi,
- [x] Gildia Poszukiwaczy,
- [x] system questów,
- [x] Mokradła Głuchej Wody,
- [x] zakupy wielu sztuk w jednej transakcji,
- [x] pogoda świata,
- [x] Burza / Mróz / Wichura,
- [x] rzadka Zorza Polarna,
- [x] wzmacnianie bossów pogodą,
- [x] pogodowy loot bossów,
- [x] pięć odporności żywiołowych,
- [x] pasywki bohatera,
- [x] bonusy zestawów wyposażenia,
- [x] Zestaw Natury z Pierścieniem Natury,
- [x] osiągnięcia,
- [x] tytuły,
- [x] Dziennik Przygód,
- [x] oryginalne specjalne mechaniki przeciwników z pierwszego regionu.

## Oryginalny notatnik — stan wdrożenia

Wszystkie konkretne pomysły mechaniczne zapisane w pierwotnym notatniku zostały już zaimplementowane lub zastąpione ich rozwiniętą wersją. Dotyczy to m.in. pogody, Zorzy, broni z bossów, odporności, pasywek, set bonusów, craftingu, kowala, poziomów, wypraw, dnia/nocy oraz specjalnych zachowań przeciwników.

Nie zastosowano jedynie późniejszej, surowej tabeli wyższych HP/ATK/DEF przeciwników z Łąki, ponieważ balans aktualnej gry był następnie rozwijany przez kolejne regiony i został zaakceptowany w testach rozgrywki.

## Następne duże systemy

- [x] Equipment 2.0 — role slotów, Item Power i affixy T1-T5,
- [x] Classes 2.0 — drzewka, specjalizacje, Pierrot, Księgi Ścieżki i klasowe typy broni,
- [x] Party System — 1 gracz + do 3 rekrutowanych NPC z klasami/buildami/AI,
- [ ] Region 6 projektowany już pod Classes 2.0 i przyszłą drużynę,
- [ ] unikalne efekty kolejnych bossowych przedmiotów,
- [ ] przekuwanie / zmiana bonusów jako Gold i material sink,
- [ ] dalsze rozwijanie architektury pod przyszłe GUI.

## Dalszy rozwój

- kolejne regiony i huby,
- regionalna ekonomia,
- gildie i frakcje,
- symulowani poszukiwacze,
- bardziej złożone statusy bojowe,
- endgame i długoterminowa progresja.


## v0.14.0 — Klasy i aktywne umiejętności [GOTOWE]

- Wojownik / Łowca / Mag
- wybór Drogi od poziomu 5
- 4 aktywne umiejętności na klasę
- wykorzystanie Many w walce
- efekty statusu: krwawienie, pęknięcie pancerza, ochrona, unik
- kompatybilna migracja save v4 → v5


## v0.15.0 — Krypta Zatopionego Zakonu [GOTOWE]
- pierwszy dungeon
- ciągłe HP/Mana między pokojami
- odwrót i zabezpieczanie łupu
- utrata wyłącznie niezabezpieczonego łupu po porażce
- rozwidlenie, skrzynia, zasadzka, kaplica
- elity
- trzyfazowy boss
- dungeonowe materiały i crafting


## v0.15.2 — Balans ekonomii [GOTOWE]

- pełny audyt źródeł i wydatków Golda,
- zachowany balans ekonomii początku gry,
- mniej powtarzalnego Golda na Mokradłach i w Krypcie,
- zmniejszona nagroda Gold Wielkiego Mistrza,
- droższe ulepszenia +7…+10,
- Gold jako koszt wysokopoziomowego craftingu,
- Eliksir Arcymistrza u Orena za 2500 Gold,
- automatyczne testy pilnujące docelowego pasma ekonomii.


## v0.16.0 — Elity i Kontrakty Gildii [GOTOWE]

- 5 kompatybilnych modyfikatorów elit,
- dzień / noc / Zorza wpływają na szansę elity,
- bonus EXP / Gold / loot za elitę,
- pierwsze odkrycia elit w Dzienniku Przygód,
- 3 Daily na lokalny dzień,
- 1 wieloetapowy Weekly na tydzień ISO,
- generator kontraktów z danych istniejących regionów i potworów,
- brak rerolla po restarcie,
- automatyczna migracja save v5 → v6.


## v0.16.1 — Narastająca szansa elit [GOTOWE]

- +5 p.p. po każdym zwykłym spotkaniu bez elity,
- osobny licznik dla każdej mapy,
- reset tylko regionu, w którym pojawiła się elita,
- maksymalna szansa 95%, bez gwarancji,
- Krypta poza systemem,
- save v6 → v7.


## v0.16.2 — Delikatniejsze skalowanie elit [GOTOWE]

- obniżono przyrost po zwykłym spotkaniu bez elity do +2 p.p.,
- pozostawiono osobne liczniki dla każdej mapy,
- pozostawiono sufit 95% i brak gwarancji 100%.


## v0.17.0 — Equipment 2.0 [GOTOWE]

- role ofensywne / defensywne / mieszane,
- Item Power I-IV,
- 0-4 affixy według rarity,
- T1-T5 z widełkami 20-100%,
- skalowanie flat stats pod przyszły endgame,
- bezpieczne capy statystyk procentowych,
- lepsza jakość tierów z elit/minibossów/Krypty/bossa,
- realne podpięcie nowych modyfikatorów do walki,
- kompaktowy terminal + widok szczegółów,
- fundament danych pod przyszłe GUI,
- save v7 → v8.


## v0.18.0 — Item Progression + Signature Dungeon Weapons [GOTOWE]

- wymagany poziom dla całego wyposażenia,
- niezależność required level / Item Power / +0..+10,
- blokada zakładania ponad poziom bohatera,
- Miecz Wielkiego Mistrza jako pierwsza Signature Dungeon Weapon,
- Średnie Obrażenia -5%..+15% per egzemplarz,
- bezpośredni drop 12% z bossa + crafting jako bad-luck protection,
- save v8 → v9 bez rerolla istniejących affixów.

## v0.19.0 — Popielne Pogranicze [GOTOWE]

- czwarty region, poziom 10-14,
- Item Power V,
- materiały zamiast masowego śmieciowego ekwipunku,
- Pożeracz Palenisk jako miniboss,
- Azhar, Władca Pustkowi jako dobrowolny boss regionu,
- sześć celowych nowych elementów wyposażenia,
- Iskra Życia i Zwykła Esencja wracają do późniejszego craftingu.

## v0.20.0 — Lodowe Wybrzeże [GOTOWE]
- Region 5: poziom 14-18 / Item Power VI.
- Pięciu zatwierdzonych zwykłych przeciwników, Widmo Kapitana Statku i Lewiatan Północy.
- Pierwsze trzy drop-only przedmioty klasowe z efektami pod build.
- Bez nowej broni — następna Signature Weapon jest planowana dopiero dla Dungeon 2.

## v0.21.0 — Wrak Czarnej Floty [GOTOWE]
- drugi dungeon, poziom 16-20,
- Medalion Czarnej Floty jako wejściówka,
- rozwidlenie Ładownia / Górny Pokład, Skarbiec i Kajuta Medyka,
- Pierwszy Oficer Czarnej Floty jako miniboss,
- Admirał Varek jako trzyfazowy boss z zapowiadaną Salwą Armatnią,
- Szabla Admirała Vareka: IP VII, wymagany poziom 20, Średnie -8%..+22%,
- 10% bezpośredniego dropu + crafting jako bad-luck protection.

## v0.21.1 — Odrodzenie bossów regionowych [GOTOWE]
- Azhar i Lewiatan wymagają 6 wypraw w swoim regionie po każdym zwycięstwie,
- porażka nie blokuje ponownej próby,
- licznik jest widoczny w menu i zapisywany w save v10.

## v0.22.0 — Guild & Black Market [GOTOWE]
- Reputacja Gildii oraz rangi F → S,
- Daily od E, Weekly od D,
- Weteran Gildii jako prestiżowy tytuł dopiero za S — Legenda,
- losowy informator po randze C i ukończeniu dungeonu,
- permanentnie odblokowywany Czarny Rynek z 3-dniową rotacją,
- jednorazowe targowanie cen zakupu i sprzedaży ksiąg,
- cztery losowe Księgi Mistrzostwa, rzadko dropiące z bossów i ważnych przeciwników dungeonów,
- Mistrzostwo pasywek 6–10,
- osobny typ Księgi Ścieżki przygotowany pod Classes 2.0,
- pełny podgląd aktywnych umiejętności poza walką,
- save v11 → v12.

## v0.23.1 — Codzienna rotacja Czarnego Rynku [GOTOWE]
- rotacja Czarnego Rynku skrócona z 3 realnych dni do 1 realnego dnia,
- brak rerolla po restarcie w obrębie tego samego dnia,
- bez zmian cen, prawdopodobieństw, targowania i save schema v13.

## v0.23.0 — Classes 2.0 [GOTOWE]
- prawdziwe drzewka i punkty rozwoju Wojownika / Łowcy / Maga / Pierrota,
- **Ciężki Rycerz jako specjalizacja Wojownika**, nie osobna klasa,
- Pierrot jako czwarta grywalna klasa ze Szczęściem, Fate Engine, Kośćmi Losu, Chaosem i Fortuną,
- Mag: Splot Magii i dwa zaklęcia w jednej turze,
- Łowca: techniki strzeleckie, trzystrzałowe sekwencje, odkrywane kombinacje i Widmowy Strzelec,
- cztery losowe Księgi Ścieżki, wspólna pula bossów/dungeonów i obsługa Czarnego Rynku,
- specjalizacje pasywek po 10/10,
- OFF-HAND: Tarcze / Kołczany / Artefakty / Kości i Talie Kart,
- drop-only progresja Łuków, Kosturów i Lanc Losu w istniejących regionach,
- kategorie craftingu oraz progresywne Plotki Gildii o królewskim zakazie ksiąg,
- save v12 → v13.


## v0.23.2 — Ślady Przebudzenia / Guild & Save QoL [GOTOWE]
- grywalny Prolog — Droga do Varenhold,
- Akt I — Ślady Przebudzenia i 9 nowych misji fabularnych,
- Reputacja Gildii jako istotna nagroda fabularna,
- C — Zdobywca zamiast C — Łowca,
- 4 sloty zapisu oraz autosave przypisany do aktywnego slotu,
- zapis/wczytywanie przeniesione do głównego menu,
- dodatkowe plotki o zakazanych księgach, Koronie i Przebudzeniu.

## v0.24.0 — Companions & Rifts [GOTOWE]
- 3 aktywnych kompanów + 1 dodatkowy związany z drużyną,
- 12 ręcznie napisanych postaci z losowanymi wariantami levelu/buildów/ekwipunku i osobistych historii,
- dzienna rotacja kandydatów w czasie Pythonii oraz rekrutacja oparta na wielu czynnikach,
- własny EXP, AI, buildy i ekwipunek NPC; osobiste przedmioty są niezbywalne,
- wiadomości, sceny obozowe, relacje, bantery i osobiste questline'y,
- ciężkie rany, Powrót do sił oraz nie-losowa permanentna śmierć wynikająca z zaniedbania,
- Szczeliny Przebudzenia F–S: długie jednorazowe wyprawy party-only, czasowe w świecie Pythonii,
- inne drużyny Poszukiwaczy mogą zamknąć zignorowaną Szczelinę,
- główny boss zamyka instancję permanentnie,
- 16 nowych klasowych Unikatów Szczelin,
- save v13 → v14.

## v0.24.1 — Party Setup QoL [GOTOWE]
- osobny ekran ustawiania składu wyprawy,
- szybkie przełączanie kompanów aktywnych / pozostających w Varenhold,
- `Wyruszaj solo` wyłączające wszystkich aktywnych kompanów jednym wyborem,
- brak zmian balansu i save schema v14.


## v0.24.2 — Kwatermistrz / Magazyn / Udźwig [GOTOWE]
- Kwatermistrz jako nowa usługa Gildii,
- Magazyn Gildii 200 miejsc na zapasy, unikaty i sprzęt dla przyszłych kompanów,
- miękki udźwig plecaka zależny od Siły i Wytrzymałości,
- `Przeciążony` nie traci lootu, ale nie może rozpocząć następnej zwykłej wyprawy regionalnej,
- trzy ulepszenia plecaka jako Gold sink,
- save schema pozostaje v14.

## v0.24.3 — Spójność nazewnictwa wyposażenia [GOTOWE]
- `Karwasz Kapitana` → `Bransoleta Czarnej Floty`,
- `Relikt Burzowego Archiwum` → `Medalion Burzowego Archiwum`,
- test semantyczny pilnujący oczywistych nazw względem slotów,
- brak zmian balansu i save schema v14.

## v0.24.4 — Szybkie zarządzanie Magazynem Gildii [GOTOWE]
- grupowe odkładanie i odbieranie wyposażenia (`1,3,5-7`),
- grupowe przenoszenie stosów z ilościami (`1x5`, `2xMAX`),
- atomowa walidacja pojemności Magazynu przed transferem.

## v0.24.5 — Czytelna waga plecaka i magazynu [GOTOWE]
- łączna waga każdego stosu bezpośrednio w Plecaku i Magazynie Gildii,
- waga pojedynczej sztuki oraz całego stosu w ekranach transferu Kwatermistrza,
- waga zapasowego wyposażenia widoczna w Plecaku,
- brak zmian balansu i save schema v14.

## v0.24.6 — Rest & Healing Rebalance [GOTOWE]
- częściowy odpoczynek przy ognisku zamiast darmowego full heala,
- pełny nocleg w Karczmie z kosztem skalowanym poziomem i limitem dnia,
- nowa progresja mikstur i receptury kondensowania słabszych mikstur w mocniejsze,
- pełny audyt zastosowania materiałów i wejściówek + ekran zastosowania w Plecaku,
- naprawiona niewidoczna receptura Starożytnego Klucza Zakonu,
- save schema v14.

## v0.24.7 — Przygotowanie do wyprawy [GOTOWE]
- centralny ekran przygotowania w Varenhold: cel / HP / Mana / udźwig / aktywny skład / zapasy,
- szybkie wejścia do drużyny, ekwipunku, Magazynu, przedmiotów użytkowych i Karczmy,
- taktyki AI kompanów: Agresywna / Zrównoważona / Ostrożna / Obronna,
- presety SOLO / BOSS / DUNGEON / SZCZELINA zapisujące skład i docelowe zapasy,
- automatyczne uzupełnianie brakujących zapasów z Magazynu bez przekraczania udźwigu,
- ostrzeżenia przed wyruszeniem i twarda blokada przeciążenia,
- save v14 → v15,
- ostatnia planowana aktualizacja terminalowa z nową funkcjonalnością.

## Następny duży etap
- stabilizacja v0.24.x: **wyłącznie bugfixy i balans**, bez dokładania nowych systemów terminalowych,
- **v0.25.0 — GUI Migration: Godot 4 + GDScript**, ekranowa struktura 2D zamiast chodzenia WASD / otwartego świata,
- podczas migracji: **World Time 2.0** — walka pozostaje turowa, zwykłe wyprawy otrzymują krótkie timery poszukiwania zakończone aktywnym encounterem; Dungeon i Szczeliny pozostają aktywną rozgrywką,
- po stabilizacji GUI: **Alchemik i Eliksiry**, następnie Region 6 / Dungeon 3,
- później wybrane transformacje sprzętu +10 → nowa forma +0.

