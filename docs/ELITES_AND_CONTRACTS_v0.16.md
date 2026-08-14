# Elity i Kontrakty Gildii — v0.16.0

## Cel aktualizacji

Urozmaicić istniejące trzy regiony i dać rozwiniętej postaci
powtarzalne cele bez przebudowy czasu świata.

## Elity

Elity występują wyłącznie jako warianty zwykłych przeciwników
otwartego świata. Minibossowie, bossowie i ręcznie zaprojektowane
elity Krypty nie otrzymują losowego prefiksu.

Szansa:
- DZIEŃ: 10%
- NOC: 15%
- ZORZA: 25%

Wspólne nagrody:
- EXP ×1.50
- Gold ×1.25
- chance zwykłego dropu ×1.20

Modyfikatory:
1. Wściekły — ATK ×1.30, DEF -1.
2. Opancerzony — HP ×1.25, DEF około ×1.40.
3. Wampiryczny — HP ×1.15, 35% lifestealu.
4. Przeklęty — HP ×1.10, częstsze i mocniejsze specjalne ataki,
   50% odporności na bleed / armor break.
5. Żywiołowy — HP ×1.15, ATK +1, element i nazwa z pogody,
   40% odporności na ten element.

## Daily

Każdego dnia powstają dokładnie trzy kontrakty:
1. polowanie,
2. dostawa materiałów,
3. elitarne zagrożenie (albo patrol przed poziomem 2).

Generator korzysta z aktualnie dostępnych regionów, przeciwników,
loot tables i materiałów. Dzięki temu kilka szablonów tworzy dużą
liczbę realnych kombinacji.

Daily są automatycznie aktywne i wygasają wraz z nowym lokalnym dniem.

## Weekly

Jeden kontrakt na tydzień ISO. Dla postaci od poziomu 7 składa się
z kilku celów:
- wygraj określoną liczbę walk w najwyższym regionie,
- pokonaj elitarne warianty,
- ukończ Kryptę Zatopionego Zakonu.

Nagroda rozwiniętej postaci zawiera również Eliksir Arcymistrza.

## Anty-reroll

Wygenerowane definicje kontraktów są zapisywane w save.
Ponowne uruchomienie programu tego samego dnia nie losuje nowych.

Jeżeli lokalna data komputera jest wcześniejsza niż zapisana data
Daily/Weekly, system nie generuje nowego zestawu.

## Ekonomia

Łączny Gold z trzech Daily jest testowany automatycznie i nie może
przekroczyć 600 Gold dla referencyjnej postaci poziomu 12.
Weekly daje większą nagrodę, ale jest jednorazowy w tygodniu.

## Save

v0.16.0 używa schema v6.
Save v5 dostaje puste bezpieczne wartości dla nowych pól i jest
następnie normalnie uzupełniany przez generator kontraktów.
