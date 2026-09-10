# Panel kości po walce — 2026-09-07

Przyczyna: panel był pokazywany bezwarunkowo dla klasy Pierrot, także bez rzutu
i na ekranie wyniku. Akcja bez kości dodatkowo pozostawiała wynik poprzedniej umiejętności.

Poprawka dotyczy wyłącznie prezentacji:

- Panel wymaga rzeczywistych kości w raporcie ostatniej zaakceptowanej akcji.
- Atak, obrona i mikstura czyszczą poprzedni rzut; nie ma zastępczego „RZUT OCZEKUJE”.
- Zwycięstwo, porażka, ucieczka i ponowna konfiguracja czyszczą kości oraz tekst.
- Umiejętność kończąca walkę nadal odtwarza rzut przed pokazaniem podsumowania.
- LOS i żetony pozostają w panelu zasobów bohatera podczas walki.

Silnik, losowanie, obrażenia, koszty i format zapisów nie zostały zmienione.
Nie jest potrzebny nowy zapis; uruchom ponownie grę z projektu.

## Weryfikacja

Nowy zestaw test_combat_fate_panel_lifecycle.gd: przed poprawką 7/8 testów
odtwarzało błąd; po poprawce wszystkie 8 przechodzi. Obejmuje oba tryby animacji.
Starszy test rozmiaru panelu pokazuje teraz prawdziwy rzut; test 1/2/3 kości
korzysta z celu, który przeżywa umiejętność, zamiast oczekiwać kości po zwycięstwie.

Łącznie: **97/97 testów, 1870 asercji, 11 zestawów**. Formatowanie, lint i diff-check OK.
Konfiguracja: godot/tools/fate_panel_tests.json.
Logi: output/fate_panel/before_fix.log, after_fix.log i tests.xml.

Skrypt godot/tools/render_fate_panel_preview.gd renderuje rzeczywistą aplikację:
stan początkowy, zwycięstwo atakiem, prawdziwy rzut oraz zwycięstwo umiejętnością.
Cztery podglądy Full HD znajdują się w output/fate_panel/. Oceniono oba podsumowania
bez panelu kości oraz widoczny rzeczywisty rzut w trwającej walce.

Testy i podglądy używają sesji w pamięci i izolowanych APPDATA/LOCALAPPDATA.
Nie odczytywano ani nie nadpisywano zapisów gracza.
Pozostają wcześniejsze ostrzeżenia Godota o certyfikatach systemu i zasobach
RID/ObjectDB przy zamykaniu narzędzi; zachowano je w logach, nie omijano ograniczeń.
