# Krypta — podpięcie zatwierdzonej komnaty

Aktualizacja 2026-09-07: poniżej zachowano raport pierwszego etapu. Krypta ma już
sześć teł i komplet grafik przeciwników; bieżący stan: `CRYPT_COMPLETION_REPORT.md`.

Data: 2026-09-06. Zakres: pierwsze tło Krypty oraz jego prezentacja w nawigacji i walce.

## Co jest w grze

- Zatwierdzony `sunken_vestibule_v2.png` jest skopiowany bez przerabiania do
  `godot/assets/combat/backgrounds/dungeons/sunken_order_crypt/sunken_vestibule.png`.
- SHA-256 obu plików: `899f28bb6ab790a2397c63887db11104e50fc7e6a6dae36097a0f3c2930706df`.
- Katalog `dungeon_presentation_catalog.gd` wybiera tło po ID lochu. Aplikacja
  przekazuje `dungeon_id` do walki; nie zgaduje go po przeciwniku ani regionie.
- Grafika jest obecna przy wejściu, decyzjach i walkach Krypty. Jest wspólna dla
  jej komnat do czasu przygotowania indywidualnych ilustracji.
- Wrak Czarnej Floty, nieznane ID, prolog i wyprawy powierzchniowe nie przejmują
  tła Krypty. Tło lochu nie zależy od pory dnia i pogody.
- Ekran decyzji pokazuje komnatę pod zwartym nagłówkiem i dolnymi panelami.
  Długi łup przewija się wewnątrz panelu. Tło nie przechwytuje myszy.
- Warstwa postaci walki ma dolną granicę nad panelami zasobów oraz nie dziedziczy
  już wymuszonej minimalnej wysokości 360 px, która powodowała nakładanie na HUD.
  Zmiana dotyczy współdzielonego ekranu walki; prezentacje klas i powierzchni
  pozostają objęte testami regresji.

## Co pozostaje do przygotowania

Wielki Mistrz nadal jest projektem do osobnej oceny — nie dodano go do katalogu
przeciwników. Brakujące ilustracje przeciwników lochu pozostają jawne; ta integracja
nie zastępuje ich przypadkowymi NPC. Kolejne komnaty otrzymają osobne grafiki
według zatwierdzonego wzorca. Nie zmieniono statystyk, łupów, kluczy ani zapisu gry.

## Walidacja

- 57/57 testów, 1269 asercji, sześć zestawów GUT. W tym siedem nowych testów
  Krypty, dotychczasowa logika obu lochów, prezentacja walki, region 5 i mikstury.
- Raport JUnit: `output/dungeon_crypt/targeted_tests.xml`.
  Log: `output/dungeon_crypt/targeted_tests.log`.
  Powtarzalna konfiguracja: `godot/tools/crypt_art_tests.json`.
- Formatowanie i lint nowego katalogu, sceny lochu oraz plików testów/podglądu:
  bez błędów. `git diff --check` dla zmienionych plików śledzonych: bez błędów.
- Podglądy rzeczywistej nawigacji aplikacji: wejście → komnata → walka,
  rozdzielczości 1280×720, 1920×1080 i 2560×1080.
  Skrypt `godot/tools/render_crypt_preview.gd` odtwarza produkcyjne skalowanie
  `canvas_items + expand` od bazowego płótna 1920×1080.
  Pliki w `output/dungeon_crypt/in_game/`.
- Osobno przetestowano granice kontrolek także na surowym logicznym płótnie 1280×720.
- Wszystko uruchomiono z profilami wewnątrz `build/validation-runtime/`.
  Podgląd używa sesji w pamięci i nie odczytuje ani nie zapisuje gry użytkownika.

Pełny przebieg przed ostatnią korektą granic postaci uruchomił 594 testy:
586 zaliczonych i osiem błędów poza nową integracją. Dotyczą istniejącego menu:
odwołań do nieobecnych HeaderSeparator/FooterSeparator (pięć testów),
dawnego city.player_label, starej listy opcji miasta oraz szerokości menu głównego.
Nie zmieniano tych testów ani niezwiązanych ekranów, żeby uzyskać zielony wynik.

Silnik zgłasza podczas startu brak dostępu do systemowego magazynu certyfikatów,
a przy zamykaniu testów/podglądu ostrzeżenia o zasobach ObjectDB/RID.
Są zapisane w logach; nie występują błędy parsowania ani wyjątki scen Krypty.
Nie obchodzono ograniczeń systemowych ani nie instalowano certyfikatów.
