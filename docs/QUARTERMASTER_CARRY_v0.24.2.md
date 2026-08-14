# v0.24.2 — Kwatermistrz, Magazyn Gildii i Udźwig

## Cel
System ma zachęcać do odkładania zapasowego wyposażenia — szczególnie sprzętu dla przyszłych kompanów — bez karania gracza utratą rzadkich dropów.

## Magazyn Gildii
- lokalizacja: Gildia Poszukiwaczy → Kwatermistrz,
- pojemność: 200 miejsc,
- jeden stos materiału / mikstury / księgi / klucza = jedno miejsce,
- każdy egzemplarz wyposażenia = jedno miejsce,
- transfer wyposażenia zachowuje instance_id, affixy, Item Power, Średnie Obrażenia i poziom ulepszenia,
- osobisty sprzęt NPC nie jest własnością gracza i nie może być przenoszony do magazynu.

## Udźwig plecaka
`50 kg + 0.5 kg × Siła + 1.5 kg × Wytrzymałość + bonus plecaka`

Założony sprzęt bohatera nie jest liczony do udźwigu plecaka. Kompani również niosą własne założone wyposażenie poza limitem gracza.

### Progi
- poniżej 75%: **Swobodny**,
- 75–100%: **Obciążony**,
- powyżej 100%: **Przeciążony**.

W v0.24.2 stan Obciążony jest informacyjny i nie zmniejsza statystyk. Przeciążenie nie blokuje przyjęcia nagrody ani podniesienia lootu. Blokuje tylko rozpoczęcie kolejnej zwykłej wyprawy regionalnej, aż gracz sprzeda lub odłoży część przedmiotów.

## Wagi
System używa czytelnych wag według kategorii, nie realistycznej wagi każdego drobiazgu. Materiały ważą 0.05 kg/szt., mikstury 0.30 kg, księgi 0.50 kg, a wyposażenie korzysta z wag typu/slotu (np. ciężki pancerz 6 kg, tarcza 4 kg, łuk 2.5 kg).

## Ulepszenia Kwatermistrza
1. Plecak Poszukiwacza I — +10 kg, 8 000 Gold, ranga E,
2. Plecak Poszukiwacza II — +20 kg łącznie, 18 000 Gold, ranga D,
3. Plecak Poszukiwacza III — +35 kg łącznie, 35 000 Gold, ranga C.

## Save
Schema pozostaje v14. Nowe pola są opcjonalne przy odczycie, dlatego save z v0.24.0/v0.24.1 ładuje się z pustym Magazynem Gildii i poziomem ulepszenia plecaka 0.
