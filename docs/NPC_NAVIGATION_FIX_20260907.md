# Poprawka interakcji z NPC — 7 września 2026

## Przyczyna i zmiana

Po przebudowie układu `CityEconomyScreen/Page/Body`, `MerchantTradeOverlay`
i `GuildHallPresentation` zajmowały cały ekran, ale nadal miały domyślne
`MOUSE_FILTER_STOP`. Ich niewidoczne części przechwytywały kliknięcia przed
przyciskami. Wysoki `z_index` nagłówka zmieniał rysowanie, nie kolejność
obsługi myszy.

Te trzy kontenery mają teraz `MOUSE_FILTER_IGNORE`. Ich interaktywne dzieci
(przyciski, siatki przedmiotów, obszary NPC) pozostają aktywne. Nie wyłączamy
obsługi wejścia całego poddrzewa.

Wspólny styl nadaje napisom złoty kolor po najechaniu i przy fokusie klawiatury,
delikatne obramowanie oraz odrębny, przygaszony stan niedostępny. Marginesy
przycisków nie zmieniają się przy najechaniu. Styl obejmuje również opcje
rozmowy w gildii, informatora oraz kompaktowe przyciski czarnego rynku.

## Weryfikacja

- Przed poprawką testy myszy odtworzyły blokadę, wskazując rzeczywiste kontrolki
  przechwytujące kursor; wcześniejsze testy wywoływały sygnał `pressed` bez myszy.
- 98/98 testów zestawu UI przeszło po poprawce, w tym zamykanie oferty,
  powrót w stanach ambient/focused/service, sloty i zakup u Orena, otwarcie
  wyboru trybu handlu, zakładki czarnego rynku oraz stan hover napisów.
- Testy interakcji obejmują rozmiary od 1280×720 do 2560×1080.
- `godot/tools/verify_npc_navigation.gd`: 47/47 sprawdzeń w renderowanej aplikacji,
  rzeczywiste zdarzenia myszy i przejścia przez router App. Kram, kuźnia,
  warsztat, karczma, gildia oraz czarny rynek wracają do miasta.
- Podglądy hover i powrotu: `output/ui_refresh_20260907/npc_navigation/`.
- Log pełnego zestawu regresji: `output/ui_refresh_20260907/npc_navigation_full_tests.log`.
- Formatowanie i lint sześciu edytowanych/dodanych skryptów: bez błędów.

Testy używają izolowanego profilu, a renderowana aplikacja atrapowego zapisu
w pamięci. Zapisy gracza, grafiki, balans i przedmioty nie zostały zmienione.
Po ponownym uruchomieniu gry można kontynuować dotychczasowy zapis.
