# v0.24.7 — Przygotowanie do wyprawy

To ostatni planowany system dodany do terminalowego prototypu przed migracją do Godot 4.

## Cel

Połączyć rozproszone systemy v0.24 w jeden workflow przed wyprawą: stan bohatera, Party, zapasy, Magazyn Gildii, udźwig, leczenie i konfigurację AI.

## Centralny ekran

`Varenhold -> Przygotowanie do wyprawy` pokazuje:

- wybrany region,
- HP i Manę bohatera,
- aktualny udźwig i stan obciążenia,
- tryb SOLO/DRUŻYNA oraz aktywnych kompanów,
- HP/Mana i taktykę aktywnych kompanów,
- posiadane przedmioty użytkowe,
- ostrzeżenia przed wyruszeniem.

Z tego miejsca można zmienić cel, skład, taktyki, wyposażenie, dobrać zapasy z Magazynu, użyć mikstury, odwiedzić Karczmę albo wyruszyć.

## Taktyki AI

Każdy kompan przechowuje jedną z czterech taktyk:

- **Agresywna** — priorytet najmocniejszych ofensywnych umiejętności,
- **Zrównoważona** — zachowanie klasowe i reakcje na sytuację drużyny,
- **Ostrożna** — obrona przy niskim HP i oszczędzanie Many,
- **Obronna** — częstsze osłanianie siebie/drużyny; Ciężki Rycerz mocniej wykorzystuje Prowokację.

Taktyki dotyczą AI kompanów w walce drużynowej Szczelin i są zapisywane w save.

## Presety

Stałe sloty presetów:

- SOLO,
- BOSS,
- DUNGEON,
- SZCZELINA.

Preset zapamiętuje aktywnych kompanów oraz **docelową** liczbę każdego przedmiotu użytkowego. Po zastosowaniu system sprawdza aktualny plecak i dobiera z Magazynu tylko brakującą liczbę sztuk. Jeżeli Magazyn nie ma pełnej ilości, gracz dostaje raport braków. System nie tworzy przedmiotów i nie pozwala uzupełnieniem przekroczyć limitu udźwigu.

## Ostrzeżenia

Przed wyruszeniem gra sygnalizuje m.in.:

- HP <= 35%,
- brak leczenia w plecaku,
- ciężko rannych kompanów,
- przeciążenie.

Przeciążenie blokuje start. Pozostałe ostrzeżenia są informacyjne i mogą zostać świadomie zaakceptowane.

## Save

Schema: **v15**.

Migracja z v14:

- kompani bez pola taktyki otrzymują `balanced / Zrównoważona`,
- system przygotowania startuje bez wybranego celu i z czterema pustymi presetami,
- istniejący ekwipunek, Party, Magazyn, Szczeliny i progres pozostają bez zmian.
