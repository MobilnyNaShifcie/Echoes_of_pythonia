# Klasy i aktywne umiejętności — v0.14.0

## Odblokowanie klasy
- Klasa odblokowuje się na poziomie 5.
- Stary save nie otrzymuje klasy automatycznie.
- Po wejściu do Varenhold gra proponuje wybór Drogi.
- Wybór można odłożyć i wykonać później z menu Bohatera.
- Wybór jest nieodwracalny.

## Bazowa Mana
- Wojownik: 12
- Łowca: 16
- Mag: 24

Bazowa Mana klasy sumuje się z Maną z Inteligencji i wyposażenia.

## Odblokowanie umiejętności
Każda klasa ma umiejętności na poziomach:
5 / 7 / 9 / 12.

## Wojownik
1. Potężne Cięcie — 6 Many — 150% ATK.
2. Roztrzaskanie Pancerza — 8 Many — 115% ATK,
   następnie DEF przeciwnika -2 na 3 ofensywne akcje.
3. Postawa Obronna — 7 Many — 40% redukcji obrażeń
   na 2 ataki przeciwnika.
4. Krwawy Zamach — 12 Many — 180% ATK + krwawienie
   3 obrażenia przez 3 tury.

## Łowca
1. Precyzyjny Strzał — 5 Many — 135% mocy Łowcy,
   nie może zostać uniknięty.
2. Krwawiący Strzał — 7 Many — 100% mocy Łowcy +
   krwawienie 2 obrażenia przez 3 tury.
3. Krok w Cieniu — 6 Many — +30% Uniku na
   2 ataki przeciwnika.
4. Podwójny Strzał — 10 Many — dwa uderzenia po 85%.

Moc Łowcy = ATK + połowa Zręczności.

## Mag
1. Ognisty Pocisk — 6 Many — 150% mocy magicznej.
2. Lodowa Lanca — 7 Many — 135% mocy magicznej.
3. Piorun — 9 Many — 180% mocy magicznej,
   nie może zostać uniknięty.
4. Wybuch Many — 14 Many — 220% mocy magicznej.

Moc magiczna = 4 + 2 × Inteligencja.
Wszystkie zaklęcia Maga ignorują połowę DEF przeciwnika.

## Zasady tury
- poprawnie użyta umiejętność zużywa Manę i turę,
- przeciwnik nie wykonuje tury, jeśli umiejętność go zabije,
- próba użycia zablokowanej umiejętności nie zużywa tury,
- brak Many nie zużywa tury,
- efekty walki nie są zapisywane, ponieważ gra nie zapisuje
  stanu w połowie walki.
