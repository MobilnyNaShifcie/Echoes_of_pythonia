# Dostęp do dungeonów — v0.15.1

## Krypta Zatopionego Zakonu

Każde wejście wymaga:
- `Starożytny Klucz Zakonu x1`.

Klucz jest pobierany po potwierdzeniu wejścia, przed utworzeniem snapshotu
łupu z wyprawy. Dzięki temu porażka nie przywraca zużytej wejściówki.

## Źródła klucza

### Matka Głuchej Wody
- gwarantowany drop: x1.

### Crafting
- Serce Głuchej Wody x1,
- Płyta Zatopionego Zakonu x2,
- Esencja Mgły x2,
- 300 Gold.

### Gildia
Zlecenie `Pieczęć Zatopionych`:
- pokonaj Rycerza Zatopionego Zakonu x3,
- 220 EXP,
- 250 Gold,
- Starożytny Klucz Zakonu x1.

## Architektura

Wymaganie wejścia jest częścią `DungeonDefinition`:
- `entry_item_id`,
- `entry_item_quantity`.

Pozwala to dodawać kolejne dungeony z własnymi wejściówkami bez
wpisywania wyjątków na sztywno w systemie ekwipunku.

## Bezpieczeństwo
- brak klucza nie uruchamia dungeonu,
- nieudany crafting z kosztem Golda niczego nie zabiera,
- klucza nie można sprzedać,
- klucz przechodzi przez zwykły save/load,
- save schema pozostaje v5.
