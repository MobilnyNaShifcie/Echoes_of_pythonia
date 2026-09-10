# Przebudowa interfejsu — 7 września 2026

Zmiany są podpięte w projekcie Godot. Nie trzeba zakładać nowej postaci ani nowego
zapisu; należy ponownie uruchomić grę, żeby wczytać zmienione sceny.
Zatwierdzone ilustracje anime fantasy i modele towarów nie zostały zastąpione.

## Co zmieniono

1. **Miasto:** wysuwana nawigacja po lewej, bez dolnego panelu powielającego
   budynki. Ilustracja nie zmienia kadru przy otwieraniu menu. Ikony budynków
   pozostają interaktywne; nazwa miasta i zegar przesuwają się poza otwartą szufladę.
2. **Walka:** panel umiejętności i zapasów wysuwa się od dołu. Karty zachowują
   stałą wielkość, a duża kolekcja przewija się poziomo. Panel dopasowuje wysokość
   do zawartości, zamiast zostawiać pusty blok. HP, mana i przebieg tury pozostają
   widoczne po jego schowaniu. Po zakończeniu walki zostaje tylko podsumowanie.
3. **Lżejszy wygląd:** usunięte zewnętrzne marginesy, cienka górna linia,
   pływające nagłówki, półprzezroczysty granat zamiast ciężkich czarnych pasów.
   Mniej powtarzających się statystyk; szczegóły bojowe są dostępne w podpowiedziach.
   Odchudzony także nagłówek karty bohatera.
4. **NPC:** kuźnia, warsztat, kram i karczma korzystają ze wspólnego układu.
   Panele usług są zebrane po prawej, a NPC pozostaje widoczny. Obie siatki handlu
   mają jednakową szerokość i wspólną górną krawędź. Komórki mają 64 × 64 jednostki
   interfejsu i stałe odstępy; duże przedmioty nadal zajmują kilka komórek.
   Otwieranie usług nie powiększa i nie przekadrowuje pokoju.
5. **Gildia / czarny rynek:** tablica gildii jest nakładką na pełną salę.
   Uspójnione panele i przyciski, bez dodatkowego opisu zasłaniającego wnętrze.
   Na czarnym rynku skrócony panel opisu i wyrównany cel przeciągania do plecaka;
   położenia modeli, lad, podstawek i cen pozostają bez zmian.
6. **Karczma:** odpoczynek jest kartą usługi „Pokój na noc” z czasem, kosztem
   i przyciskiem wynajęcia. Nie zajmuje slotu i nie trafia do ekwipunku.
   Zachowane zasady: 6 godzin, koszt 25 + 25 × poziom, raz dziennie,
   brak opłaty przy pełnym zdrowiu i manie. Skrytka pozostaje osobną usługą.
7. **Osiągnięcia i tytuły:** kolekcja kart, filtry Wszystkie / Zdobyte / Do zdobycia,
   postęp i siatka tytułów. Wyposażanie odblokowanego tytułu zachowane.
8. **Grafiki umiejętności:** pełniejszy kadr na kartach i w podglądzie,
   bez powiększenia obcinającego ilustrację.
9. **Ustawienie walczących:** wspólna linia bazowa sylwetek, uwzględnienie
   przezroczystego marginesu grafik i odsunięcie postaci poniżej HUD.
   Pozy postaci, uniesione nogi i unoszące się duchy nadal wynikają z ilustracji.

## Sterowanie wysuwanym menu

- Najedź na uchwyt ze strzałką, aby rozwinąć panel.
- Kliknij uchwyt, aby przypiąć go na stałe; ponowny klik zamyka.
- Po odsunięciu kursora nieprzypięty panel zamyka się z krótkim opóźnieniem.
- Fokus klawiatury również otwiera uchwyt. Esc zamyka i odpina panel.
- Menu nie zamyka się podczas przeciągania, przytrzymania przycisku myszy
  ani obsługi jego kontrolek klawiaturą. Schowane kontrolki nie przechwytują fokusu.
- Ruch szuflady trwa 0,22 s; w ograniczonym trybie animacji walki jest natychmiastowy.

## Błędy walki i wypraw

**Porażka przy pełnym HP:** po przegranej logika ratowania postaci odnawiała zdrowie
przed wyświetleniem podsumowania. Ekran pokazywał więc już zdrowie po ratunku,
a nie stan ostatniej tury. Podsumowanie zachowuje teraz końcowe HP i manę walki.
Odnowienie po powrocie i dotychczasowy zapis działają nadal.

**Kość po walce:** zachowano i ponownie sprawdzono poprawkę cyklu życia panelu Losu.
Zwykły atak nie tworzy rzutu; rzeczywisty rzut umiejętności może się odtworzyć,
ale panel znika po zakończeniu starcia.

**Wyprawy:** każde dozwolone wyruszenie do regionu prowadzi do spotkania — 100%.
Pozostają oddzielne pule dnia i nocy, wagi przeciwników, elity, respawn bossów
i koszt jednej godziny. Blokady wypraw, np. przeciążenie, nie zostały wyłączone.

## Balans — pomiary, nie deklaracja zakończonego strojenia

Wykonano **11 200 deterministycznych symulacji**, 112 wariantów po 100 walk.
Nie znaleziono końcowej porażki z dodatnim HP ani zwycięstwa z żywym przeciwnikiem.
Nie było walk przekraczających limit 150 tur.

Metoda: dolna i górna granica zalecanego poziomu regionu; dzień i noc;
cztery klasy od poziomu 5; nowa postać z pełnymi zasobami w każdej próbie.
Rozdział punktów na poziom: 2 w atrybut główny, 1 w witalność, 1 w wytrzymałość.
Porównano sprzęt startowy i optymistyczny zestaw dopuszczalnego wyposażenia
nieunikalnego z katalogu. Ten drugi nie symuluje kolejności faktycznego zdobywania łupów.
Bot wybiera atak lub dostępną ofensywną umiejętność według jej bazowej mocy.

Przykładowe wyniki przy wejściowym poziomie regionu:

| Region / poziom | Wyposażenie | Wygrane dzień | Wygrane noc |
| --- | --- | --- | --- |
| Zmierzchowe Równiny / 0 | startowe | 98% | 85% |
| Czarny Las / 2 | startowe | 82% | 79% |
| Bagna / 5 | rozwinięte, zależnie od klasy | 100% | 100% |
| Popielne Pogranicze / 10 | rozwinięte, zależnie od klasy | 92–100% | 82–93% |
| Lodowe Wybrzeże / 14 | rozwinięte, zależnie od klasy | 94–100% | 87–97% |

Mag kończy część walk wyraźnie szybciej; słabsze wyposażenie mocno obciąża pozostałe
klasy. To sygnał do dalszych prób, nie wystarczający powód do globalnego osłabienia
maga: ten audyt nie wykorzystuje kombinacji talentów, eliksirów, ulepszeń,
pogody, elit ani strat zasobów między kolejnymi walkami.

**Nie zmieniano globalnie statystyk klas, przedmiotów ani przeciwników.**
Zmianą tempa jest gwarantowane spotkanie: przy tym samym czasie wypraw rośnie
liczba starć, ale także zużycie zasobów. Nagrody za pojedyncze zabicie pozostają takie same.
Pełne strojenie klas i ekonomii wymaga następnej rundy z realnymi zestawami oraz
ciągiem wypraw bez przywracania HP/many między próbami.

Surowe wyniki: [balance_audit.json](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/balance_audit.json>).

## Weryfikacja i ograniczenia

- Pełny zestaw regresji: 635/635 testów, 16 815 asercji. Końcowy log:
  [release_tests.log](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/release_tests.log>).
- Osobne testy nowego układu obejmują najechanie, przypinanie, Esc, schowany fokus,
  szybkie przełączanie scen, stały kadr, równe siatki, odpoczynek, tytuły,
  układ kart oraz zwycięstwo/porażkę z pełnymi i ograniczonymi animacjami.
- Wygenerowano podglądy z rzeczywistego renderera Godota dla 1280 × 720,
  1920 × 1080 i 2560 × 1080, z takim samym skalowaniem jak w grze.
- Próby korzystały wyłącznie z osobnego profilu w build/validation-runtime.
  Podglądy używają atrap zapisu. Nie otwierano ani nie nadpisywano rzeczywistego
  zapisu użytkownika.
- Godot nadal zgłasza przy zamykaniu wcześniejsze ostrzeżenia o zasobach/ObjectDB
  oraz odczycie magazynu certyfikatów. Audyt pamięci całego silnika nie był częścią
  tej przebudowy. Znany duży plik city_economy.gd nadal przekracza limit 1000 linii
  lintera; przekraczał go również przed zmianami. Nowy układ wydzielono do helpera.
- Nie generowano jeszcze nowych klatek animacji skilli. To następny etap po ocenie UI.

## Co sprawdzić po powrocie

1. Uruchom grę ponownie i wczytaj dotychczasową postać.
2. W mieście najedź na lewą strzałkę, przypnij/odepnij menu i wybierz budynek.
3. U Orena porównaj obie siatki; sprawdź zakup, sprzedaż i przeciąganie.
4. Wejdź do karczmy z niepełnym HP/maną i wynajmij pokój.
5. Wyrusz na wyprawę: sprawdź szufladę akcji, miksturę i wynik walki.
6. Otwórz osiągnięcia, filtr i wyposaż odblokowany tytuł.

Podglądy: [miasto](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/previews/city_open_1920x1080.png>),
[walka](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/previews/combat_open_wolf_1920x1080.png>),
[kram](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/previews/merchant_service_1920x1080.png>),
[osiągnięcia](<C:/Users/kamil/OneDrive/Desktop/echoes_of_pythonia_v0.24.7_refactored/echoes_of_pythonia/output/ui_refresh_20260907/previews/achievements_1920x1080.png>).

Kopia kodu sprzed przebudowy: output/ui_refresh_20260907/baseline_code.zip.
To materiał do selektywnego porównania/przywracania, nie polecenie zastąpienia całego
projektu; wcześniejsze zmiany użytkownika zostały zachowane.
