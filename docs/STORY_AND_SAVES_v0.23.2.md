# v0.23.2 — Ślady Przebudzenia / Guild & Save QoL

## Prolog

Nowa postać rozpoczyna grę w grywalnym prologu **Droga do Varenhold**. Prolog przedstawia sytuację królestwa, rozbity królewski wóz, pierwszą walkę z przeklętym strachem na wróble, królewski zakaz handlu wiedzą bojową oraz rejestrację bohatera w Gildii jako **F — Nowicjusz**.

Główną tajemnicą pierwszego aktu jest pytanie, dlaczego dawne pieczęcie, potwory, ruiny i stare miejsca w różnych regionach zaczynają reagować na to samo zjawisko określane przez Gildię jako **Przebudzenie**.

## Akt I — Ślady Przebudzenia

Dodano 9 połączonych zadań fabularnych:

1. Ci, którzy nie wrócili
2. Czarny wosk
3. Głos spod korzeni
4. To, czego nie powinno być pod wodą
5. Pieczęć bez imienia
6. Krypta, która oddycha
7. Popiół pamięta
8. Dzwony pod lodem
9. Ostatni rozkaz

Zadania odblokowują się wraz z poziomem i ukończeniem poprzednich rozdziałów. Każde daje własną wartość Reputacji Gildii. Cały Akt I daje łącznie **700 reputacji**. Późniejsze etapy potrafią użyć istniejących trofeów jako dowodów bez ich zużywania.

## Ranga C

Ranga **C — Łowca** została przemianowana na **C — Zdobywca**, aby nie kolidowała z grywalną klasą Łowca. Progi reputacji nie zmieniły się.

## Cztery sloty zapisu

Gra obsługuje teraz:

- `save_1.json`
- `save_2.json`
- `save_3.json`
- `save_4.json`

Opcja zapisu została usunięta z Varenhold i przeniesiona do głównego menu obok wczytywania. Nowa gra wybiera swój slot przed rozpoczęciem prologu. Po wczytaniu danego slotu wszystkie automatyczne zapisy trafiają z powrotem do niego, dopóki gracz świadomie nie zapisze sesji w innym slocie.

Schema zapisu pozostaje **v13** — dodatkowe sloty są osobnymi plikami i nie wymagają zmiany struktury pojedynczego save'a.
