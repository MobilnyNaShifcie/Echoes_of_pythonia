# Spójny, lekki interfejs — plan i dziennik realizacji

Zakres zatwierdzony przez użytkownika 2026-09-07. Kolejne etapy realizowane
w projekcie, z zachowaniem istniejących grafik anime fantasy i zapisów gry.
Nie generujemy jeszcze klatek animacji umiejętności.

## Etapy

1. [x] Poprawność walki i wypraw: wyjaśnić porażkę przy pełnym HP, poprawić
   stan wyświetlany po zakończeniu; każda dozwolona wyprawa spotyka przeciwnika.
2. [x] Wspólny lekki język UI: cienkie separatory, kompaktowe nagłówki,
   ograniczenie powtórzeń, półprzezroczyste panele i spokojne przejścia.
3. [x] Miasto: wysuwana nawigacja od lewej, wyraźny uchwyt (hover / klik / fokus),
   usunięcie dolnych skrótów; pozostają interaktywne budynki.
4. [x] Walka: wysuwany od dołu panel akcji, nierozciągnięte karty i pełniejsze
   kadry ich grafik; HP i stan tury czytelne także przy zamkniętym panelu.
   Sprawdzić ustawienie bohatera i przeciwników względem podłoża.
5. [x] NPC: jednakowe zasady nagłówków i układu interakcji, równe siatki slotów,
   miejsce dla ilustracji. Odpoczynek w karczmie jako usługa, nie przedmiot.
6. [x] Osiągnięcia i tytuły: kolekcja kart z postępem/stanem zamiast surowej listy;
   zachować wyposażanie tytułów i działanie filtrów/nawigacji.
7. [x] Balans oparty na powtarzalnych symulacjach; skorygować udowodnione anomalie,
   sprawdzić tempo po zwiększeniu spotkań. Testy, podglądy 720p/1080p/ultrawide,
   raport zmian i ograniczeń do oceny po powrocie użytkownika.

## Kryteria

- Żadnych zmian w zapisach gracza podczas testów; osobne profile testowe.
- Wysuwane menu nie znika podczas kliknięcia, wyboru lub przeciągania;
  dostępne również klawiaturą i kliknięciem, nie tylko najechaniem.
- Ograniczone animacje pozostają dostępne. Brak migotania / pulsowania całego ekranu.
- Handel, zakup, ulepszanie, odpoczynek, mikstury i akcje bojowe pozostają funkcjonalne.
- Balans nie oznacza dowolnego zmieniania wszystkich statystyk; zmiany z pomiarów
  i jasnym opisem wpływu. Częstotliwość spotkań = 100% zgodnie z prośbą.
- Każdy ukończony etap odnotowany poniżej; nie deklarować ukończenia bez testów.

## Dziennik

- Start: zastano wiele wcześniejszych zmian w repozytorium; zostają zachowane.
  Przygotowanie kopii kodu sprzed przebudowy w output/ui_refresh_20260907/.
- Etap 1: 67/67 testów, 4016 asercji. Porażka pokazywała HP odnowione przez
  ratowników; podsumowanie zachowuje teraz stan ostatniej tury. Spotkania = 100%
  we wszystkich regionach, zachowane pule dnia/nocy, elity, godzina wyprawy i respawn.
- Etapy 2–6: podpięte wspólne lekkie style, dwie szuflady, nowe układy NPC,
  odpoczynek jako usługa, kolekcja osiągnięć i tytułów, pełne kadry kart.
  Usunięto dolne skróty miasta. Ilustracje i modele przedmiotów bez zmian.
- Poprawiono również minimum rozmiaru szuflady po przeliczeniu tekstu,
  schowany fokus i odroczone tworzenie uchwytu przy szybkiej nawigacji.
- Etap 7 (audyt): 11 200 deterministycznych walk; zero nieprawidłowych końcowych
  stanów HP, zero przekroczeń 150 tur. Duży wpływ ekwipunku i przewaga maga
  w uproszczonym teście wymagają osobnego strojenia z talentami i ubytkiem zasobów.
  Nie zmieniono globalnie statystyk klas ani potworów.
- Weryfikacja końcowa: 635/635 testów, 16 815 asercji. Podglądy z renderera Godota
  dla 720p, 1080p i ultrawide. Szczegóły oraz ograniczenia: UI_REFRESH_REPORT_20260907.md.
- Zakończenie tego pakietu nie oznacza ukończenia globalnego balansu ani nowych
  animacji skilli. Te elementy pozostają następnym etapem po ocenie przebudowanego UI.
