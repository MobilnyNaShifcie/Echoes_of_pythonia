# Kowal — multi-upgrade v0.17.10

## Przebieg

1. Gracz wybiera przedmiot.
2. Wybiera liczbę kolejnych ulepszeń albo `MAX`.
3. `MAX` oznacza maksymalną liczbę poziomów, na które wystarczają aktualne Gold i materiały, z limitem +10.
4. Gra sumuje koszt każdego poziomu po kolei.
5. Przed pobraniem zasobów pokazuje podsumowanie.
6. Cała operacja jest atomowa.

Nie ma rabatu za ulepszanie kilku poziomów naraz.
