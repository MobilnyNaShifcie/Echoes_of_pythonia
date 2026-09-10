# Pierrotka — kierunek Spine 2D

> **PLAN ARCHIWALNY — nie realizować zakupu ani integracji Spine.** Użytkownik 2026-09-09 wykluczył kolejne zakupy. Aktywny kierunek: [animacja 2D w istniejącym Godocie](../pierrot_2d_native_01/README.md), bez nowych licencji, abonamentów i płatnych generacji zewnętrznych. Poniższe ustalenia o Spine pozostają wyłącznie historią poprzedniej propozycji.

Decyzja użytkownika: 2026-09-09. Docelowe animowanie postaci w Spine, z zachowaniem wyglądu ilustracji i ambicją jakości inspirowanej Epic Seven. Wstrzymujemy kolejne rekonstrukcje postaci 3D. Poprzednie próby pozostają jako archiwum; niczego nie usunięto.

**Stan: przygotowany plan produkcji, nie gotowa postać ani projekt Spine.** Nie zakupiono licencji, nie zainstalowano edytora lub runtime'u i nie zmieniono gry. Status licencji użytkownika jest niepotwierdzony.

## Wzorzec wyglądu

Główna referencja: `godot/assets/combat/heroes/pierrot.png`. Identyczny plik jest używany jako `godot/assets/ui/class_selection/pierrot_female.png`.

SHA-256 obu plików: `E31A4BBF95D49CC4A5A63AD37D551A32261088154A627A5761E79FAE3B7FF830`.

Zachować twarz, czerwone oczy, asymetryczny falowany bob, proporcje sylwetki, czarno-biało-czerwony strój, złote gwiazdy i dwustronną lancę. Ujęcie bojowe 3/4, zwrócone w prawo. Nie używać odrzuconej proceduralnej głowy 3D jako referencji. Turnaround z prób 3D jest tylko pomocą do fragmentów niewidocznych na głównej ilustracji.

Spine nie odtwarza automatycznie zakrytych części i nie zamienia jednego PNG w gotową animację. Jakość zależy od przygotowania warstw, dodatkowych rysunków póz, rigowania, tempa ruchu i efektów. Nie gwarantujemy jakości studyjnej samym wyborem programu.

## Kolejność prac

1. **Przygotowanie grafiki.** Rozdzielić ilustrację na warstwy z prawdziwą przezroczystością, odtworzyć zakryte fragmenty kończyn, tułowia, włosów i lancy. Usunąć z warstw tło oraz poświatę tła; światło od broni przygotować oddzielnie. Nie rozciągać twarzy i ozdób, by udawać nowy kąt widzenia.
2. **Test statycznego złożenia.** Złożona postać w pozycji bazowej ma zachowywać wygląd wzorca. Kontrola w docelowej skali gry i w powiększeniu, na jasnym oraz ciemnym tle. Brak szczelin, ciemnych obwódek, obciętych włosów i podwójnych fragmentów.
3. **Rig w Spine Professional.** Osobne kości i kontrolery kończyn, głowy, lancy, pasm włosów i połów stroju. Dłonie utrzymują chwyt; stopy mają wyraźne kontakty z podłożem. Deformacja tylko tam, gdzie zachowuje rysunek. Trudniejsze obroty przez zmianę rysunków, nie nadmierne wyginanie płaskiej grafiki.
4. **Jedna dopracowana sekwencja.** `idle` i `fate_thrust`: przygotowanie, przeniesienie ciężaru, krok/doskok, pchnięcie, kontakt, wycofanie lancy, powrót. To atak trzymaną lancą, nie rzut. Efekt nie wylatuje z tułowia.
5. **Izolowana integracja w Godocie.** Sprawdzić odpowiedni runtime, eksport, animację i zdarzenia w laboratorium. Dopiero po akceptacji grafiki i ruchu zastąpić wizualizację w walce. Zachować statyczny wariant awaryjny.

## Podział warstw — lista robocza, bez wygenerowanych plików

- Głowa: twarz bazowa, uszy, brwi, powieki otwarte/zamknięte, tęczówki, usta i alternatywna mimika wysiłku. Zachować dokładny kształt oczu i charakter rysunku.
- Włosy: tylna masa, pasma przy karku, boczne loki, korona, grzywka i krótkie przednie pasma. Podział zgodny z rzeczywistym przebiegiem włosów, bez przypadkowych równych pasków.
- Tułów: szyja, kołnierz, czerwona gwiazda, gorset, brzuch i biodra; ornamenty, które nie powinny się gumowo rozciągać, na osobnych warstwach.
- Ręce: osobno bliższa i dalsza kończyna; bark, rękaw, przedramię, mankiet, dłoń otwarta oraz chwyty. Dorysować dłoń trzymającą drzewce z obu potrzebnych stron.
- Nogi: osobne uda, podudzia, obuwie i ozdoby; dodatkowy rysunek mocno zgiętego kolana, jeśli deformacja nie zachowa anatomii.
- Strój: przednie i tylne poły, boczne szarfy, końcówki oraz większe wiszące gwiazdy. Ustalić kolejność zasłaniania dla pozycji bazowej i pchnięcia.
- Lanca: pełne drzewce za dłońmi, oba ozdobne zakończenia, osobne światło/iskry. Punkty `grip_rear`, `grip_front`, `weapon_tip`, `weapon_rear_tip`.

Liczbę części ustalić po testach deformacji; nie traktować liczby warstw lub kości jako miary jakości. Nie nadpisywać źródłowych ilustracji.

## Pierwsza animacja — propozycja rytmu

Czas roboczy 1,2–1,6 s, do oceny w ruchu, nie sztywne wymaganie. Najpierw zatwierdzić kluczowe pozy bez interpolacji.

- Przygotowanie: lekki kontrruch bioder i barków, ustawienie dwóch chwytów.
- Przeniesienie ciężaru/krok: inicjacja nogami, następnie biodra i barki. Brak ślizgania stóp.
- Pchnięcie: wyprowadzenie grotu trzymanej broni, wyprost ramion bez zmiany ich długości; rysunek alternatywny przy dużym skrócie perspektywicznym.
- Kontakt: pojedyncze zdarzenie `contact`, krótki akcent zatrzymania i efekt trafienia przy grocie. Obrażenia pochodzą z istniejącej logiki, nie z losowania w animacji.
- Powrót: wycofanie lancy i ciężaru ciała, opóźnione uspokojenie włosów i stroju, płynne przejście do `idle`.

## Integracja — sprawdzony punkt wyjścia

Projekt wskazuje Godot 4.7, renderer `gl_compatibility`. Dotychczasowy `CombatantVisual.show_animated(PackedScene, ...)` udostępnia host sceny animowanej. Plan: wrapper `Control` ze `SpineSprite`, dopasowujący skalę do istniejącej linii podłoża.

W `CombatPresentationController._play_fate_thrust()` istnieje rozdzielenie sygnału trafienia i końca efektu. Nowy adapter powinien zachować ten kontrakt. Zdarzenie `contact` ma uruchamiać prezentację wcześniej wyliczonego wyniku najwyżej raz na akcję. Zabezpieczyć pominięcie/ograniczenie animacji, przerwanie, wyjście ze sceny, timeout i restart walki. Nie zmieniać RNG, zapisu, kosztu many ani reguł obrażeń.

Preferowany pierwszy test: oficjalny **spine-godot GDExtension**. Nie wymieniać edytora Godot całego projektu bez konieczności. GDExtension według dokumentacji nie zapewnia integracji z `AnimationPlayer`; użyć stanu animacji Spine oraz sygnału `animation_event`. Zgodność konkretnego wydania z Godot 4.7 / Windows x64 nie została jeszcze przetestowana.

Wersje edytora i runtime'u muszą być dobrane zgodnie z dokumentacją. Eksport: `.skel`, `.atlas`, strony `.png`; przy JSON użyć rozszerzenia `.spine-json`. Dla spine-godot nie eksportować atlasu z pre-multiplied alpha. Normal maps do oświetlenia 2D są opcją na późniejszy etap.

## Kryteria odbioru

- Sylwetka i twarz rozpoznawalne jako ta sama Pierrotka, nie nowy projekt postaci.
- Brak rozjazdu dłoni z drzewcem, przeskoków rysunków, szczelin w stawach, gumowych ozdób oraz ślizgania stóp.
- Włosy i strój pracują wtórnie, bez drżenia i przenikania przez twarz.
- Ruch czytelny również bez poświaty, smugi, drgań kamery i dźwięku.
- Kontakt grotu, efekt, pasek HP i liczba obrażeń zsynchronizowane; brak podwójnego trafienia.
- Testy 1280×720, 1920×1080 i 2560×1080 oraz trybu ograniczonych animacji.
- Najpierw akceptacja jednej umiejętności, później rozszerzanie zestawu i pozostałe klasy.

## Edytor i licencja

Planowane siatki i deformacje wymagają Spine Professional; Essential nie obsługuje tych zaawansowanych funkcji. Trial nie pozwala zapisywać projektów, pakować atlasów ani eksportować własnych animacji. Zakup i aktywacja pozostają po stronie użytkownika; nie prosić o klucz ani prywatny link licencyjny w czacie. Przed włączeniem runtime'u sprawdzić oficjalne warunki licencji.

## Źródła sprawdzone 2026-09-09

- Funkcje edycji i zakup: https://esotericsoftware.com/spine-purchase
- Ograniczenia triala: https://esotericsoftware.com/spine-download
- Integracja Godot i eksport: https://esotericsoftware.com/spine-godot
- Spine w zespole Epic Seven: https://recruit.supercreative.kr/job_posting/pwofELaR

Nie ustalono jeszcze wersji edytora, wersji runtime'u ani zatwierdzonej paczki grafiki. Ten dokument nie jest dowodem ukończenia integracji.
