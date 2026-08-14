# v0.24.0 — Companions & Rifts

## Założenie

v0.24.0 dodaje dwa powiązane filary: drużynę z ręcznie napisanymi kompanami oraz Szczeliny Przebudzenia jako długi content wymagający party. System nie generuje dialogów przez model językowy. Losowość wybiera wcześniej napisane warianty postaci, historii, buildów i wypraw; sam tekst pozostaje ręcznie kontrolowany.

## Kompani

- roster: maks. 4 kompanów, z czego maks. 3 aktywnych,
- kandydaci: 2 osoby na dzień Pythonii, oferta utrwalona w save,
- poziom kandydata: zwykle w przedziale około -6/+8 względem gracza,
- różnica poziomu jest tylko jednym z modyfikatorów rekrutacji,
- widoczne przed rekrutacją: imię, klasa, poziom, ścieżka, styl i nastawienie,
- ukryte przed rekrutacją: cały ekwipunek,
- rzadkie ścieżki mogą istnieć u NPC niezależnie od książek przeczytanych przez gracza,
- rekrutacja korzysta z utrwalonego rzutu i wielu modyfikatorów, więc reload nie rerolluje decyzji,
- 12 ręcznie napisanych szablonów postaci z własnym głosem, dialogami, wiadomościami, obozowymi scenami i osobistymi historiami.

### Własność wyposażenia

Sprzęt wygenerowany razem z kompanem jest jego osobistym wyposażeniem. Gracz może go zastąpić, ale nie może go zabrać do własnego plecaka. Przedmiot powierzony przez gracza pozostaje własnością gracza i wraca po zdjęciu lub rozstaniu. Osobisty przedmiot zastąpiony przez sprzęt gracza trafia do prywatnego magazynu kompana i może zostać później automatycznie przywrócony.

### Rozwój i relacje

Kompan zdobywa własny EXP, poziomy, atrybuty i punkty drzewka. AI korzysta z mechanik klasy (m.in. Prowokacji, sekwencji Łowcy, Podwójnego Splotu i Kości Losu). Relacja rośnie przez rozmowy, osobiste questy i wspólne wyprawy. Rozstanie nie usuwa historii NPC; były kompan może po czasie wrócić do rotacji.

## Ciężkie rany i śmierć

`CIĘŻKO RANNY` kompan jest czasowo wyłączony z aktywnej drużyny. UI pokazuje `Powrót do sił: X dni Pythonii`.

Permanentna śmierć nie jest losowana. W wysokich Szczelinach boss może przygotować wyraźnie zapowiedzianą Egzekucję powalonego kompana. Gracz otrzymuje czas na reakcję: podniesienie NPC, przerwanie zagrożenia albo zakończenie walki. Dopiero zignorowanie ostrzeżenia może zakończyć historię postaci. Polegli trafiają na Tablicę Poległych, a pozostali kompani reagują wiadomościami.

## Szczeliny Przebudzenia

Rangi: `F → E → D → C → B → A → S`.

- czas działania liczony wyłącznie w dniach Pythonii,
- maks. jedna aktywna Szczelina w świecie,
- zignorowaną Szczelinę może zamknąć inna drużyna Poszukiwaczy,
- rozpoczęcie ekspedycji rezerwuje instancję dla gracza,
- po porzuceniu wraca ona do świata,
- konfiguracja jest deterministyczna i zapisywana: restart nie rerolluje lepszej wersji,
- długość: 12 segmentów na F do 24 segmentów na S,
- typy segmentów: walki, elity, wydarzenia, obozowiska, miniboss, finałowy boss,
- F/E wymagają min. 2 aktywnych kompanów; D–S wymagają aktywnej trójki,
- zabicie głównego bossa zamyka Szczelinę permanentnie.

Szczeliny są proceduralnie składane z ręcznie przygotowanych tematów (np. Krwawy Księżyc, Zamarznięta Pustka, Popielne Zwierciadło, Archiwum Burzy i Czarna Toń), modyfikatorów, przeciwników oraz bossów.

## Unikaty Szczelin

Dodano cztery nowe unikaty na klasę. Nie są częścią zwykłego craftingu ani standardowego dropu. Ich efekty wspierają konkretne mechaniki klasowe, np. Odwet/Blok Wojownika, Echa Łowcy, Podwójny Splot Maga oraz Kości Losu Pierrota.

## Save

Schema: v14. Migracja z v13 dodaje puste `party` i `rifts`, zachowując dotychczasową postać, Gildię, ekwipunek, questy i cztery sloty zapisu.

## QoL v0.24.1 — ustawianie składu

W Gildii ekran `Drużyna i kompani` zawiera teraz osobne `Ustaw skład wyprawy`. Gracz może z jednego miejsca włączać i wyłączać kompanów do limitu 3 aktywnych albo wybrać `Wyruszaj solo`, co pozostawia wszystkich kompanów w Varenhold. Po rozpoczęciu ekspedycji Szczeliny skład pozostaje zablokowany do jej zakończenia lub porzucenia.
