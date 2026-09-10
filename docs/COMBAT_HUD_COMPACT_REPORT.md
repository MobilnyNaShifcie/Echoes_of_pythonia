# Zwarte menu walki — 2026-09-07

## Zakres

- Osobny, wyśrodkowany zestaw komend bohatera i umiejętności. Panel kart rośnie
  wraz z talią w zakresie 600–1120 jednostek, zamiast zajmować wolną szerokość ekranu.
- Karty bojowe mają stały rozmiar 148×180. Jedna karta nie jest rozciągana.
  Wariant katalogu umiejętności pozostaje 168×212; używane są te same istniejące ilustracje.
- Przewijanie i strzałki pojawiają się dopiero przy nadmiarze kart. Fokus klawiatury
  przewija talię do wskazanej karty. Rozmiar i tożsamość kart są zachowane przy resize.
- Atak, Obrona i Ucieczka tworzą ograniczony szerokością, wyśrodkowany rząd.
- Usunięto widoczny, powielony dolny panel przeciwnika i zastępcze portrety-romby.
  Nazwa, zdrowie i efekty przeciwnika pozostają przy jego sylwetce.
- Mikstury pozostają w panelu bohatera, z ikoną aktualnie wybranego przedmiotu,
  liczbą sztuk i podglądem odnowienia. Ta zmiana nie przenosi żadnych przedmiotów
  między ekwipunkami i nie zmienia zasad leczenia.
- Podwójny Splot ma rozwijany panel z jawnym wyborem **obu** zaklęć.
  Zwykłe kliknięcie karty nadal wykonuje pojedynczą umiejętność.
- Dziennik i ograniczenie animacji przeniesiono do nagłówka. Po walce komendy
  ustępują podsumowaniu i łupom; ponowne skonfigurowanie sceny resetuje panele.
- Tło obejmuje również obszar za dolnymi komendami. Nie wygenerowano nowej grafiki.

Samo dopasowanie i nawigacja kart są wydzielone do combat_command_layout.gd.
Nie zmieniono silnika walki, statystyk, kosztów, losowania, formatów zapisów ani nagród.
Nie jest to jeszcze dostawa nowych animacji umiejętności, trafień i pokonania przeciwnika.

## Weryfikacja

Końcowy wynik: **78/78 testów, 1585 asercji, 9 zestawów** (12,606 s).
Dziewięć nowych testów obejmuje również powrót wspólnego komponentu karty
z wariantu bojowego do katalogowego. Formatowanie, lint zmienionych komponentów
i kontrola białych znaków w diffie przeszły poprawnie.

Konfiguracja: godot/tools/combat_hud_tests.json. Log i JUnit:
output/combat_hud/tests.log oraz output/combat_hud/tests.xml.
Testy obejmują puste i pojedyncze talie, 11 umiejętności Łowcy, zmianę wielkości okna,
nawigację/fokus, Splot dwóch wybranych zaklęć, blokady, zużywanie mikstur i powrót
ze stanu zakończenia. Uruchamiane są także istniejące zestawy silnika, prezentacji,
kart, Maga/Wojownika oraz pełnych tras Krypty.

Rzeczywista aplikacja wyrenderowała 24 podglądy w 1280×720, 1920×1080 i 2560×1080.
Skrypt: godot/tools/render_combat_hud_preview.gd. Pliki: output/combat_hud/.
Oceniono Wojownika z jedną kartą w Full HD, rozwinięty Splot w 720p,
ostatnie karty Łowcy w panoramie oraz podsumowanie zwycięstwa w Full HD.

Sesje testowe są tworzone w pamięci. Testy i podglądy korzystają z osobnych katalogów
APPDATA/LOCALAPPDATA, a renderer aplikacji podstawia zapis w pamięci.
Istniejące zapisy gracza pozostają nietknięte; nowy zapis nie jest potrzebny.

Godot nadal zgłasza niedostępność magazynu certyfikatów systemu i ostrzeżenia
RID/ObjectDB przy kończeniu narzędzi. Import edytora zgłosił także błędy sprawdzania
aktualizacji dodatku GUT i zapisywania ustawień edytora. Nie omijano ograniczeń
systemu ani nie zmieniano konfiguracji bezpieczeństwa. Nie są to błędy działania
nowego układu; logi zachowano. Pełny zestaw całego repozytorium nie jest tutaj
deklarowany jako bezbłędny — raport dotyczy wyżej wymienionych zestawów.

## Kolejny etap

Efekty i prezentacja jednej wzorcowej umiejętności w zatwierdzonym stylu:
czytelny moment ataku, trafienie, reakcja celu, osadzenie sylwetek w scenie,
liczby obrażeń oraz wariant ograniczonego ruchu. Dopiero po ocenie wzorca
rozszerzenie na pozostałe umiejętności; bez automatycznej regeneracji ikon lub postaci.
