# Pierrot — próba projekcji grafiki na głowę 3D

Data: 2026-09-09. **Eksperyment techniczny, niezatwierdzony wizualnie. Nie używać w grze.**

## Wynik

Aktualna próbka: `sample_v05/pierrot_head_sample.glb` oraz edytowalny
`sample_v05/pierrot_head_sample.blend`. Porównania `comparison_front.png`
i `comparison_angle.png` są renderami rzeczywistych modeli 3D z tą samą kamerą
i materiałem pokazującym sam kolor, bez wpływu oświetlenia.

Lewy model: oryginalna tekstura Tripo 8K. Prawy: projekcja fragmentu zatwierdzonej
referencji, wypalona do osobnej tekstury UV 2048×2048. Rozdzielczość atlasu nie
oznacza odzyskania nowych szczegółów twarzy — referencja ma 548×956 pikseli na
całą postać, a sama twarz stanowi mały fragment tego obrazu.

## Ocena wizualna

- Metoda działa technicznie: kolor jest zapisany na powierzchni prawdziwej siatki,
  nie na płaskiej planszy ani billboardzie.
- Frontalne rysy stały się bardziej rysunkowe, ale pozostało rozmycie.
- Pod kątem widoczne są artefakty przejścia na skroni/policzku i nakładanie
  fragmentów starej i nowej tekstury. Wynik nie spełnia docelowego standardu.
- Grzywka modelu nadal zasłania oczy inaczej niż rysunek. Jej geometrii nie
  zmieniano; nie należy udawać rozwiązania tego problemu przez malowanie oczu
  na włosach. Maskowanie wyklucza wykryte czerwone komponenty włosów.
- To próbka samej tekstury, nie ukończona przebudowa głowy, włosów ani rigu.

## Zakres i bezpieczeństwo

- Wejście: `C:/Users/kamil/Downloads/pierrot_8k.glb.glb`.
- Referencja: `../pierrot_3d_reference_02/tripo_multiview_v2/pierrot_front_v2.png`.
- Oryginalny GLB, referencja oraz pliki gry pozostają bez zmian; hashe znajdują
  się w `sample_v05/report.json`.
- Próbka obejmuje wycięcie głowy i fragmentu ramion: 136 972 wierzchołki,
  244 665 trójkątów przed eksportem. Otwarta krawędź u dołu jest celowym cięciem
  próbki, nie gotową konstrukcją szyi.
- Wypalanie zachowuje pozycje wierzchołków. GLB ma standardowy matowy materiał
  PBR reagujący na światło, jedną mapę UV i osadzoną teksturę.
- Nie dodano kości ani animacji. Nie integrowano niczego z produkcyjną postacią.
- Nie używano generowania AI nowych obrazów ani kredytów Tripo. Użyto zwykłej
  projekcji UV i wypalania w Blenderze.

## Dalsza praca przed zaakceptowaniem

Potrzebna jest osobna, precyzyjna tekstura twarzy z poprawnymi widokami bocznymi,
dopasowana do punktów charakterystycznych bryły, oraz korekta grzywki/rysów tam,
gdzie geometria odbiega od referencji. Nie przenosić obecnych artefaktów na całą
postać i nie traktować samego zwiększania rozdzielczości jako naprawy.

## Odtwarzanie

`build_head_sample.py` buduje bieżący eksperyment `v05`; `bake_head_sample.py`
wypala atlas i tworzy porównania; `verify_export.py` ponownie importuje GLB,
sprawdza geometrię/UV/materiał i renderuje osadzoną teksturę niezależnie.
Raport kontroli eksportu: `sample_v05/validation.json`.

Foldery `v01`–`v04` i `sample_v04` zawierają wcześniejsze, odrzucone próby
techniczne (błędne przypisanie UV, kalibrację i niepełne maski). Nie są wynikami
do użycia. Ocenie podlega wyłącznie jawnie oznaczona próbka `sample_v05`.
