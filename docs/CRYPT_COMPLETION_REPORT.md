# Krypta Zatopionego Zakonu — domknięcie grafiki
Data: 2026-09-07. Wdrożenie na polecenie użytkownika „okej domykamy ją”.

## W grze

- Sześć różnych teł: zachowany zatwierdzony Przedsionek oraz nowe Korytarz Pieczęci,
  Galeria Utopionych, Zatopiona Kaplica, Sala Łańcuchów i Brama Wielkiego Mistrza.
- Pięciu wcześniej brakujących przeciwników: Akolita, Kapłanka, Strażnik Żelaznych
  Wrót, Strażnik Krypty oraz Wielki Mistrz. Dodatkowo nowa ilustracyjna wersja Rycerza.
- Wszystkie dziewięć ID przeciwników z rzeczywistych tabel spotkań Krypty ma grafikę.
  Topielec, Kroczący we Mgle i Wiedźma pozostają istniejącymi grafikami regionu;
  nie są liczeni jako nowo wygenerowane postacie.
- Postacie mają prawdziwą przezroczystość, pełne sylwetki i margines 12 px.
  Ręcznie wskazane otwory w łańcuchach, lasce, tarczy i płaszczach usunięto lokalnie
  na podstawie wcześniejszej zgody na obróbkę kanału alfa. Jasne fragmenty tkanin,
  skóry i metalu pozostały nieprzezroczyste.
- Wielki Mistrz zachowuje twarz, koronę, miecz i płaszcz z projektu pilotażowego.
  Dodano tarczę, ponieważ istniejąca druga faza walki wspomina jej roztrzaskanie.
  Kapłanka i Mistrz są odwracani w prezentacji w stronę bohatera.
- Stary Rycerz pozostaje w pliku sunken_knight.png. Katalog korzysta teraz z
  sunken_knight_anime.png także na mokradłach — to ten sam przeciwnik, nie osobny klon.

## Dobór komnat

Katalog prezentacji korzysta ze stabilnych kroków DungeonRunState.
Nie analizuje polskich nazw ani ID przeciwnika. Żelazne wrota i zalana odnoga
korzystają z Korytarza Pieczęci, którego grafika przedstawia oba przejścia.
Galeria jest tłem trzeciego starcia, a Kaplica kolejnym ekranem odpoczynku.
Po zwycięstwie finałowym pozostaje Brama Mistrza. Nieznany klucz komnaty ma bezpieczny
fallback do Przedsionka tylko w obrębie Krypty; Wrak i powierzchnia nie przejmują tych teł.

Nie zmieniono statystyk, losowania, progów faz bossa, łupów, kluczy ani formatu zapisu.
Ta dostawa nie obejmuje nowych animacji umiejętności ani przebudowy paneli walki.

## Pliki i odtwarzanie

- Tła produkcyjne: godot/assets/combat/backgrounds/dungeons/sunken_order_crypt/.
- Nowe sylwetki: godot/assets/combat/enemies/ (sześć PNG wymienionych powyżej).
- Pełne prompty, role referencji i źródła:
  art_drafts/dungeon_crypt_complete/manifest.json oraz generated_sources.json.
- Generator: wbudowane image_gen, osobne wywołanie dla każdego zasobu.
  Oryginały zachowano w katalogu generated_images oraz kopiach raw/ w projekcie.
- Przygotowanie alfa: art_drafts/dungeon_crypt_complete/prepare_assets.py.
  Ziarna ręcznie ocenionych otworów są zapisane jawnie, bez globalnego usuwania bieli.
- QA: art_drafts/dungeon_crypt_complete/qa/enemy_contact_sheet.png,
  room_contact_sheet.png i osobne podglądy na jasnym/ciemnym tle.
- Render rzeczywistej aplikacji: godot/tools/render_crypt_complete_preview.gd;
  wynik w output/dungeon_crypt/in_game_complete/.

## Walidacja

68/68 testów, 1630 asercji, siedem zestawów GUT (8,141 s).
Konfiguracja: godot/tools/crypt_art_tests.json; log:
output/dungeon_crypt/complete_tests.log. JUnit: output/dungeon_crypt/targeted_tests.xml.

Jedenaście nowych testów obejmuje katalog rzeczywistych spotkań, alfa i marginesy,
sześć osobnych teł, czysty dobór komnat bez zmiany stanu, przełączanie ekranów,
odwracanie sylwetek i reset tej opcji, trzy rozmiary płótna oraz trzy pełne ścieżki:
żelazne wrota, zalany korytarz z zasadzką i bez niej. W pełnych ścieżkach naciskane
są rzeczywiste przyciski aplikacji: atak, kontynuacja, decyzje i powrót na mapę.
Testowy przeciwnik ma 1 PŻ wyłącznie w jednorazowej sesji testu; rzeczywiste
naliczanie łupów, zużycie klucza i zakończenie wyprawy nie są pomijane.
To weryfikacja integracji, nie test balansu trudności.

Testy oraz podglądy uruchamiane są z izolowanym APPDATA/LOCALAPPDATA w build/.
Pełne przejścia podstawiają zapis w pamięci zamiast zapisu gracza.
Żadnego prawdziwego zapisu nie odczytano ani nie zmieniono.

Silnik przy zamykaniu zestawu nadal zgłasza ostrzeżenia ObjectDB/RID/zasobów;
są zachowane w logu. Nie oznaczono całego repozytorium jako bezbłędne:
osiem wcześniejszych błędów pełnego zestawu poza Kryptą opisuje
docs/CRYPT_ART_INTEGRATION.md. Nie maskowano ich zmianami niezwiązanych testów.

## Kontrola obrazu w silniku

Przejście przez żelazne wrota wyrenderowało 48 zrzutów: 16 etapów w 1280×720,
1920×1080 i 2560×1080. Proces zakończył się kodem 0. Oceniono bezpośrednio
finał z Wielkim Mistrzem w Full HD, Strażnika Krypty w 720p, Kapłankę
w formacie panoramicznym, Kaplicę w Full HD i ekran ukończenia w 720p.
Sylwetki mieszczą się nad panelami, kierunek postaci jest właściwy, a komnaty
pozostają pełnoekranowe również na szerokim płótnie. Dłuższy opis łupów w 720p
korzysta z przewijania zamiast zasłaniać przycisk powrotu.

Podglądy i logi nie są dowodem zakończenia osobnego zadania przebudowy HUD walki.
W istniejącym komunikacie po zwycięstwie nadal pojawia się techniczna nazwa
przeciwnika (np. „drowned priestess”); to osobna poprawka tekstów prezentacji,
nie brak zasobu graficznego. Log silnika zawiera też komunikat o niedostępnym
systemowym magazynie certyfikatów oraz ostrzeżenia zasobów przy zamykaniu.
Nie zmieniano konfiguracji bezpieczeństwa systemu.
