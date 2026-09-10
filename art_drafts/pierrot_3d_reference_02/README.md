# Pierrot — referencje do modelu 3D, wersja 02

**Arkusz v2 zatwierdzony przez użytkownika 2026-09-09: „okej zatwierdzam”. To wzorzec wyglądu i proporcji, nie model 3D. Nie podłączono do gry.**

## Korekta proporcji v2

`pierrot_turnaround_v2.png` jest obowiązującym zatwierdzonym wzorcem po uwadze użytkownika, że dolna część sylwetki v1 była zbyt szczupła. Wbudowanym imagegen poprawiono pełność bioder, ud i pośladków według dodatkowej ilustracji użytkownika, zachowując układ arkusza. Pełny prompt, źródła i zakres akceptacji: `manifest_v2.json`. Akceptacja obejmuje wygląd, proporcje, tył i profil; nie zastępuje oceny przyszłej geometrii 3D. V1 pozostaje zachowana do porównania i nie jest wzorcem proporcji dolnej części ciała.

Arkusze przedstawiają przód w neutralnej pozie, tył oraz profil. Wygenerowany przód nie zastępuje oryginalnej ilustracji `godot/assets/combat/heroes/pierrot.png` w grze. Oryginał zachowuje rolę źródła tożsamości i detali, a zatwierdzone v2 określa skorygowane proporcje i konstrukcję tyłu. Niewidoczne wcześniej fragmenty zostały zaprojektowane i zatwierdzone, nie odzyskane z oryginału.

Lanca celowo nie zasłania sylwetki: pozostaje osobnym obiektem do modelowania według oryginału. Odrzucony model z `pierrot_3d_study_01` nie jest źródłem tego arkusza.

## Następny etap: rzeczywisty model 3D

- Przenieść zatwierdzone detale pleców; sprawdzić ciągłość szwów, rombów i warstw materiału między widokami.
- Przygotować wyrównane referencje i pełną siatkę ciała, stroju i włosów; nie sklejać dwóch płaskich ilustracji.
- Sprawdzić podobieństwo modelu z kamery walki oraz z profilu i tyłu przed riggowaniem.
- Oddzielić namalowane światło od materiałów reagujących na scenę; oświetlenie i cienie otoczenia dopracować w późniejszym etapie.

## Osobne ujęcia do Tripo — 2026-09-09

Użytkownik zatwierdził zwykłe, bezstratne kadrowanie bez ponownej generacji AI. Gotowe pliki znajdują się w `tripo_multiview_v2/`:

- `pierrot_front_v2.png` — przód, 548 × 956 px.
- `pierrot_back_v2.png` — tył, 506 × 956 px.
- `pierrot_profile_facing_right_v2.png` — profil zwrócony w prawo na obrazie, 482 × 956 px.

Zachowano wszystkie piksele wewnątrz kadrów, wspólną skalę i zakres pionowy oryginału. Nie skalowano, nie usuwano tła, nie odwracano sylwetki i nie poprawiano proporcji. Usunięto z kadrów tylko sąsiednie ujęcia i dolne podpisy. Kontrola obrazu zachowała kompletne dłonie, włosy, buty oraz końce stroju i złote ozdoby. Porównanie każdego piksela przed i po zapisie PNG przeszło dla wszystkich trzech plików. Oryginalny arkusz pozostał niezmieniony.

Skrypt: `scripts/split-pierrot-reference.ps1`; współrzędne, sumy kontrolne i zakres weryfikacji: `tripo_multiview_v2/manifest.json`. Skrypt nie nadpisuje istniejących plików.

To przygotowane referencje, nie wynik generowania 3D. Na etapie wycinania nie wysłano ich do Tripo ani nie zużyto kredytów. Późniejszy zrzut użytkownika pokazuje ręcznie wczytane trzy ujęcia w panelu Multi-view, z pustym polem „Po lewej”. Przed generacją nadal trzeba sprawdzić wszystkie miniatury, ustawienia prywatności oraz potwierdzić koszt. Nie należy wczytywać całej planszy trzech postaci do pojedynczego wejścia obrazu.

## Brakujący lewy profil — 2026-09-09

Na prośbę „BRAKUJE NAM LEWEJ STRONY” przygotowano dodatkowy plik `tripo_multiview_v2/pierrot_profile_facing_left_v2.png` (891 × 1766 px), z sylwetką skierowaną w lewo. Powstał wbudowanym imagegen na podstawie zatwierdzonego arkusza v2 oraz istniejącego prawego profilu. To nowo wygenerowany widok przeciwnej strony, nie bezstratny wycinek ani techniczne odbicie lustrzane. Detale niewidoczne wcześniej są interpretacją referencji i wymagają oceny użytkownika oraz sprawdzenia na przyszłej siatce 3D.

Nowy profil zachowano w natywnej rozdzielczości; nie jest wyrównany pikselowo z trzema wycinkami o wysokości 956 px. Sprawdzono pełną sylwetkę, kierunek profilu, brak podpisów i broni oraz główne elementy stroju. Trzy istniejące pliki pozostały niezmienione, co potwierdzono sumami SHA-256. Pełny prompt, źródła i uwagi: `tripo_multiview_v2/left_profile_manifest.json`. Nowego pliku asystent nie wgrał do Tripo i nie uruchomił generacji 3D.

## Pochodzenie

Użyto wbudowanego narzędzia image_gen, zgodnie z umiejętnością imagegen. Źródła i pełne prompty: `manifest.json` dla v1 oraz `manifest_v2.json` dla korekty. V1 bazowała na obecnej ilustracji Pierrotki; v2 dodatkowo na ilustracji proporcji załączonej przez użytkownika. Niczego nie wysłano do Meshy i nie uruchomiono płatnych operacji 3D. Wcześniejsza zgoda na wysłanie ilustracji do Meshy nie jest zgodą na koszty ani integrację niezatwierdzonego modelu.
