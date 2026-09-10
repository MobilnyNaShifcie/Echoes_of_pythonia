# Pierrotka — animacja 2D bez kolejnych zakupów

## Decyzja i stan

2026-09-09: użytkownik wyklucza dalsze zakupy. Zastępujemy plan Spine animacją 2D w Godocie, który jest już silnikiem gry. Nie kupujemy licencji, abonamentów ani kredytów i nie uruchamiamy nowych płatnych generacji w Meshy lub Tripo. Nie instalujemy runtime'u Spine i nie obchodzimy ograniczeń jego wersji próbnej.

**Stan: pierwszy działający, izolowany podgląd idle w Godocie; pełne pchnięcie nadal przed nami.** Nie zmieniono walki, zapisów ani zatwierdzonych grafik. Wcześniejsze modele i prototypy pozostają w archiwum; nie wracają automatycznie do gry.

## Wykonany pierwszy krok — 2026-09-09

- Audyt potwierdził, że oryginalny portret ma prawdziwy kanał alfa. Stary arkusz części ma narysowaną szachownicę i inne proporcje; nie został ponownie użyty.
- Powstała nowa scena `godot/tools/pierrot_native/portrait_lab.tscn`: porównanie oryginału i animacji, odtwarzanie/pauza, przewijanie, poza bazowa, jasne tło kontrolne i punkty ruchu.
- Oryginalny PNG jest teksturą ciągłej siatki `Polygon2D` z 6305 wierzchołkami i 12288 trójkątami, sterowanej przez 9 `Bone2D` w `Skeleton2D`. `AnimationPlayer` napędza cykl 5,6 s. Maksymalnie cztery znormalizowane wpływy na wierzchołek.
- Oddech oraz ruch włosów, rękawa i szarf są celowo subtelne. Twarz ma jeden sztywny wpływ bez zmiany proporcji oczu i ust. Lanca, chwyt oraz podeszwy pozostają stabilne.
- To **studium idle na niezmienionej ilustracji**, a nie gotowy zestaw rozdzielonych części ciała. Nie wykonano jeszcze nowych rysunków, mrugania, niezależnego chwytu dwóch dłoni, kroku ani pchnięcia. Nie wolno rozszerzać tego rozwiązania na duże obroty lub udawać ataku przesuwaniem całego obrazka.
- Następny etap po ocenie: właściwe oddzielenie lancy i kończyn, odtworzenie zasłoniętych fragmentów oraz kluczowe pozy pchnięcia. Dotychczasowe punkty 2–5 pozostają planem, nie listą zakończonych prac.

Podgląd: `output/pierrot_native_20260909/pierrot_native_idle.gif`. Po lewej nieruchomy oryginał, po prawej animowane idle. GIF jest skompresowanym podglądem; scena Godota korzysta z pełnokolorowej tekstury.

Uruchomienie interaktywne: w Godot otworzyć `res://tools/pierrot_native/portrait_lab.tscn` i nacisnąć F6, albo z katalogu repozytorium uruchomić `./scripts/preview-pierrot-native.ps1`. Skrypt używa osobnego profilu danych w `build/validation-runtime/native-portrait-profile`, bez prawdziwych zapisów gracza.

Walidacja: 8 testów GUT sprawdzających źródła, wagi, sztywność twarzy/broni/stóp, pętlę, przewijanie, faktyczne sterowanie przez AnimationPlayer oraz dopasowanie sceny. Kontrola pikselowa na prawdziwym rendererze OpenGL Compatibility porównuje pozę bazową ze zwykłym `Sprite2D`: tylko 0,0096% kanałów różniło się o więcej niż 2/255. Raport `output/pierrot_native_20260909/render_qa.json` potwierdza również rzeczywisty ruch siatki na GPU. To nie jest pomiar FPS ani zastępstwo oceny artystycznej. Sprawdzono kadry 1280×720, 1920×1080 i 2560×1080.

Suma SHA-256 obu oryginałów pozostała `E31A4BBF95D49CC4A5A63AD37D551A32261088154A627A5761E79FAE3B7FF830`. Nie zmieniono konfiguracji uruchamiania gry. Znane ostrzeżenie środowiska o magazynie certyfikatów nie dotyczy animacji; podgląd nie wymaga sieci.

## Cel wizualny

Wzorcem pozostaje `godot/assets/combat/heroes/pierrot.png`, identyczny z `godot/assets/ui/class_selection/pierrot_female.png`.

Zachować twarz, czerwone oczy, falowany czerwony bob, proporcje, czarno-biało-czerwony strój, złote ozdoby i dwustronną lancę. Nie używać odrzuconej głowy 3D jako nowego wzorca.

Inspiracja Epic Seven dotyczy jakości rysunku, czytelnych póz i rytmu animacji. Sam program nie zapewni takiej jakości. Najtrudniejszym etapem jest przygotowanie poprawnych warstw i dodatkowych rysunków, nie wybór silnika. Jeden płaski obraz nie zawiera zakrytych fragmentów ciała i stroju; trzeba je odtworzyć, a nie rozciągać sąsiednie piksele.

## Kolejność prac

1. **Audyt istniejących materiałów.** Sprawdzić oryginał oraz dostępne wycięcia, rozdzielczość, przezroczystość i kompletność fragmentów. Ustalić, czego brakuje do jednej animacji. Nie generować od razu całej postaci ponownie.
2. **Warstwy i statyczna próba złożenia.** Przygotować głowę, grupy włosów, tułów, bliższe i dalsze kończyny, rękawy, poły stroju, dłonie i oddzielną lancę. Uzupełnić zakryte obszary. Złożenie w pozie bazowej musi zachowywać wygląd ilustracji bez szczelin, obwódek, uciętych elementów lub podwójnych konturów. Najpierw ocena tej wersji, dopiero potem ruch.
3. **Natywny rig Godota.** `Skeleton2D` i `Bone2D` dla hierarchii; teksturowane `Polygon2D` z wagami tylko tam, gdzie deformacja zachowuje rysunek. Sztywne ozdoby i broń pozostają nierozciągane. `AnimationPlayer` steruje pozami, zmianą rysunków i widocznością. Przy większym obrocie stosować dodatkowy rysunek, zamiast gumowo wyginać twarz lub kończynę.
4. **Pierwszy mały zakres.** Dopracować `idle`, następnie jedno `fate_thrust`: przygotowanie, przeniesienie ciężaru, krok, pchnięcie trzymaną lancą, kontakt i powrót. Dłonie utrzymują chwyt, stopy kontakt z podłożem. Ruch włosów i materiału ma wspierać akcję, nie maskować błędów.
5. **Laboratorium i akceptacja.** Pokazać ruch bez efektów, a potem z krótkim efektem przy grocie. Dopiero po akceptacji podpiąć do walki, zachowując statyczny wariant awaryjny. Pozostałe klasy i skille czekają na zatwierdzenie wzorca.

## Co wykorzystać z projektu

- `godot/ui/presentation/rigs/pierrot_cutout_rig.gd` pokazuje działającą techniczną bazę natywnego rigowania. Jego dotychczasowe wycięcia i wygląd nie są zatwierdzonym materiałem końcowym. Nie wystarczy ponownie włączyć tego prototypu.
- `pierrot_thrust_pose.gd` może posłużyć do testów chwytu, pozycji grotu i kontaktu stóp. Proporcje oraz ruch należy dopasować do zatwierdzonych warstw.
- `CombatantVisual.show_animated()` udostępnia punkt integracji sceny animowanej. Natywny rig `Node2D` można osadzić w komponencie `Control`, który utrzymuje wspólną linię podłoża i poprawne skalowanie.
- `CombatPresentationController._play_fate_thrust()` już rozdziela moment trafienia i koniec prezentacji. Adapter animacji musi zachować ten kontrakt.

## Warunki odbioru

- Postać rozpoznawalna jako ta sama Pierrotka, zwłaszcza twarz i włosy; nie nowa uproszczona interpretacja.
- Brak rozjeżdżających się chwytów, ślizgania stóp, dziur między częściami i rozciąganych złotych ornamentów.
- Kontakt grotu, efekt, liczba obrażeń i zmiana PŻ zsynchronizowane. Zdarzenie kontaktu najwyżej raz na akcję; animacja nie losuje ani nie nalicza obrażeń samodzielnie.
- Obsłużone przerwanie, wyjście ze sceny, ponowna walka, pominięcie/redukcja animacji i awaryjne zakończenie prezentacji. Bez zmian reguł RNG, many i zapisu gry.
- Czytelność w skali gry, na jasnym i ciemnym tle, w 1280×720, 1920×1080 i 2560×1080. Animacja ma działać wizualnie również bez rozbłysków i trzęsienia kamery.

## Dokumentacja techniczna

[Godot: 2D skeletons](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html) — natywne kości, siatki i wagi deformacji. Szczegóły implementacji weryfikować na używanej przez projekt wersji 4.7; dokumentacja tutoriala może nie obejmować wszystkich zmian tej wersji.
