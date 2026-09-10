# Zapis gry — widoczny wynik operacji

## Ustalona przyczyna

Kliknięcie przycisku docierało do `SaveGameService.save_session`, ale wynik był
wyświetlany wyłącznie w `AppStatusLabel`, którego rodzic (`Footer`) jest ukryty
po przebudowie UI. Po pierwszym zapisie nie odświeżało się też `has_saved_session`
w aktualnym menu, przez co przycisk wczytania pozostawał nieaktywny.

Test przed poprawką potwierdził zapis i ponowny odczyt pliku; nie przechodziły
asercje widocznego potwierdzenia i natychmiastowego odblokowania wczytywania.

## Poprawka

- Wynik zapisu jest widoczny w istniejącym miejscu pod tytułem menu.
- Sukces pokazuje numer slotu, a błąd informuje, że nie zapisano gry, i podaje
  dokładną przyczynę. Nie przywracamy ciężkiego paska u dołu ekranu.
- Przyciski odświeżają dostępność po operacji, bez przebudowy ekranu.
- Delikatne rozjaśnienie komunikatu sygnalizuje również kolejne kliknięcie zapisu.
- Przyciski menu otrzymały spójne złote podświetlenie tekstu.
- Format zapisów oraz reguły walidacji nie zostały zmienione.

## Testy i ograniczenia

32/32 testy zestawu `godot/tools/save_menu_tests.json`: kliknięcie → plik →
ponowne wczytanie, widoczny wynik, zachowanie poprzedniego pliku po błędzie,
ponowienie próby, aktywacja wczytywania i układ 1280×720–2560×1080.

Renderowana aplikacja przeszła całą ścieżkę przy użyciu zdarzeń myszy i prawdziwej
usługi plikowej. Podglądy sukcesu, wymuszonego błędu i wczytywania znajdują się
w `output/ui_refresh_20260907/save_menu/`. Dane w katalogu `fixture_*` są wyłącznie
wygenerowanym zapisem testowym. Logi: `save_menu_after.log`,
`save_menu_render.log` oraz `save_menu_full_tests.log` w katalogu powyższym.

Odczyt prywatnego katalogu zapisów i logu działającej gry był niedostępny.
Nie obchodzono ograniczenia; wszystkie testy działały w izolowanym profilu.
Nie potwierdzono stanu konkretnego zapisu gracza i nie nadpisano żadnego z nich.
