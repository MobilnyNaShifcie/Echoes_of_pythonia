# Fundament pod przyszłe GUI — v0.17

v0.17 nie zmienia jeszcze gry w aplikację okienkową. Wprowadza natomiast zasadę architektoniczną potrzebną do takiej migracji:

- mechanika przedmiotów przechowuje dane, nie gotowe teksty terminala,
- affix to `affix_id + tier + value`,
- Item Power jest częścią instancji przedmiotu,
- obliczenia statystyk i walki znajdują się poza `ui/`,
- `ui/` odpowiada za sposób prezentacji danych.

Docelowo obecny Console UI może zostać zastąpiony GUI bez przepisywania generatora lootów, systemu statystyk, save'a, walki, craftingu ani wyposażenia.
