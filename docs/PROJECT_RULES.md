# Zasady projektu

## 1. Jeden moduł — jedna odpowiedzialność

System walki nie zarządza ekwipunkiem.
Interfejs nie przechowuje stanu gry.
Dane przeciwników nie będą zaszyte w kodzie odpowiedzialnym za walkę.

## 2. Kod po angielsku, gra po polsku

Nazwy plików, funkcji, klas i zmiennych piszemy po angielsku.
Teksty wyświetlane graczowi są po polsku.

## 3. Dane oddzielamy od mechaniki

Przeciwnicy, przedmioty, lokacje, receptury i tabele lootu będą
przechowywane poza kodem wykonującym ich mechanikę.

## 4. Nie tworzymy pustych systemów na zapas

Nowe foldery i moduły powstają wtedy, kiedy faktycznie zaczynamy
implementować odpowiadającą im mechanikę.

## 5. Każda aktualizacja ma wersję

Większe etapy otrzymują numer wersji i wpis w `CHANGELOG.md`.

## 6. Spójność świata ma pierwszeństwo

Nowa mechanika powinna pasować do istniejących zasad świata,
progresji, ekonomii i balansu. Jeśli coś koliduje z wcześniejszą
decyzją, najpierw świadomie zmieniamy tę decyzję.
