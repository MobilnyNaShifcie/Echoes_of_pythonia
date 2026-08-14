# Narastająca szansa elit — v0.16.1

## Reguła

Dla każdego regionu otwartego świata zapisywany jest osobny
`miss streak`: liczba kwalifikujących się spotkań bez elity.

Szansa:
`min(95%, baza + miss_streak × 2 p.p.)`

Baza:
- dzień: 10%,
- noc: 15%,
- Zorza Polarna: 25%.

## Aktualizacja licznika

- zwykły przeciwnik, który nie został elitą → +1,
- zwykły przeciwnik, który został elitą → reset regionu do 0,
- miniboss → bez zmian,
- brak spotkania → bez zmian,
- dungeon → bez zmian.

Licznik jest związany z regionem, a nie typem przeciwnika.
Wszystkie zwykłe potwory na danej mapie korzystają z tej samej
narastającej szansy regionu.

## Brak gwarancji

Maksymalna szansa wynosi 95%. System celowo nie posiada progu,
po którym elita staje się gwarantowana.

## Save

Schema v7 zapisuje:
`elite_miss_streaks: {location_id: count}`.

v6 migruje z pustymi licznikami.
