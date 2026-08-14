# Audit v0.13.1

Ta wersja jest wydaniem testowym. Nie dodaje nowych systemów rozgrywki.

## Fragment Szaty Kultysty

`cultist_cloth` wypada z Kultysty Boru, ale w v0.13.1 nie jest jeszcze
składnikiem receptury ani celem zadania. Jego jedynym mechanicznym
zastosowaniem jest sprzedaż jako zwykłego materiału.

Nazwa ekranowa została zmieniona z `Szatka Kultysty` na
`Fragment Szaty Kultysty`, aby odpowiadała faktycznemu opisowi przedmiotu.
`item_id` pozostał bez zmian, więc stare zapisy gry są kompatybilne.

## Materiały bez aktywnego zastosowania poza sprzedażą

Pierwszy audyt wykazał także inne materiały, które obecnie są tylko lootem
handlowym i nie są zużywane przez crafting ani zadania:

- Futro Wilka,
- Kieł Wilka,
- Surowe Mięso Dzika,
- Trufla,
- Iskra Życia,
- Zwykła Esencja,
- Twarde Drewno,
- Fragment Szaty Kultysty,
- Czarny Pazur,
- Czarne Poroże,
- Serce Czarnego Boru,
- Moneta Topielca,
- Przeklęta Żywica,
- Płyta Zatopionego Zakonu.

Nie dodajemy im teraz nowych receptur. Pozostają na liście audytowej do
świadomej decyzji po zakończeniu fazy stabilizacji.

## Rozdawanie punktów

Atrybuty i umiejętności pasywne obsługują teraz wydawanie wielu punktów
naraz. Można wpisać konkretną liczbę albo `MAX`.

Operacja jest atomowa: jeśli gracz spróbuje wydać więcej punktów niż ma
albo przekroczyć maksymalny poziom pasywki, żaden punkt nie zostanie
częściowo wydany.

## Dodatkowa kontrola danych

Dodano testy integralności odwołań między tabelami danych: loot, receptury,
questy, lokacje, sklep, zestawy oraz pogodowy loot bossów.
