# Odrodzenie bossów regionowych — v0.21.1

## Zasada

Dobrowolni bossowie otwartego świata nie są już dostępni bez ograniczeń po zwycięstwie.

- Azhar, Władca Pustkowi — Popielne Pogranicze.
- Lewiatan Północy — Lodowe Wybrzeże.

Po zwycięstwie licznik ustawia się na **6 wypraw**. Każde użycie normalnej opcji `Wyrusz na wyprawę` w regionie danego bossa zmniejsza licznik o 1. Liczą się zarówno spotkania z przeciwnikiem, jak i spokojne wyprawy; wynik walki na wyprawie nie zmienia tej zasady.

Nie liczą się:
- odpoczynek przy ognisku,
- wyprawy w innych regionach,
- wejścia do dungeonów,
- sama walka z bossem.

Porażka albo ucieczka z walki z bossem nie uruchamia odrodzenia. Licznik startuje wyłącznie po zwycięstwie.

## UI

Dostępny boss zachowuje dotychczasowy wpis, np.:

```text
[3] Azhar, Władca Pustkowi [BOSS | poziom 14+]
```

Podczas odrodzenia:

```text
[3] Azhar, Władca Pustkowi [Odrodzenie: 3 wyprawy]
```

Próba wejścia w tę opcję pokazuje pozostałą liczbę wypraw i nie rozpoczyna walki.

## Save

Stan odrodzenia jest przechowywany w `region_boss_respawns` osobno dla każdego bossa. Schema zapisu została podniesiona z v9 do v10. Migracja starszego save ustawia pusty stan odrodzeń, więc istniejący gracz nie zostaje zablokowany po aktualizacji.
