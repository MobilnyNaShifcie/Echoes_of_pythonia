# Pierrotka 3D — studium geometrii 01

Stan: **ODRZUCONY przez użytkownika 2026-09-09**. Nie używać jako wzorca wyglądu, nie integrować z grą ani nie rozpoczynać riggowania tej wersji. Pliki zachowane wyłącznie jako archiwum nieudanej próby.

Wymaganie po odrzuceniu: możliwie wierne odtworzenie obecnej ilustracji `godot/assets/combat/heroes/pierrot.png`, w tym twarzy, proporcji, fryzury, kroju i detali stroju oraz lancy. Sprawdzenie 2026-09-09 potwierdziło, że katalog prezentacji walki nadal używa tej grafiki 2D. Model nie został podłączony do gry.

## Pliki

- `pierrot_study.blend` — edytowalny model, materiały oraz osobna kolekcja oświetlenia do przeglądu.
- `pierrot_study.glb` — rzeczywista geometria 3D, eksport bez studia, lamp i podłoża.
- `manifest.json` — zakres, aktualne statystyki, ograniczenia.
- `validation.json` — wynik 11 kontroli importu rzeczywistego modelu w Godocie.
- Podglądy: `../../output/pierrot_3d_study_01/` — przód, tył, 3/4, twarz i wspólna plansza `turnaround.png`.

Wzorzec: `godot/assets/combat/heroes/pierrot.png`. Zachowane motywy: czerwona fryzura z przedziałkiem, czerwone oczy, czarno-biało-karminowy strój w romby, złote gwiazdy, rozdzielone poły, obcasy i dwustronna lanca. Tył ubioru jest interpretacją pojedynczej ilustracji, nie odtworzeniem niewidocznego wzorca.

Model nie używa ilustracji postaci jako płaszczyzny ani tekstury projekcyjnej. Twarz, oczy, włosy, palce, ubranie i broń są osobnymi elementami geometrii. Wszystkie trzy postacie na planszy przeglądowej są instancjami tego samego modelu obróconymi w Blenderze; podglądy nie są generowanymi obrazami udającymi model.

Po przeglądzie zbliżenia połączono objętości pasm włosów w jedną siatkę, aby usunąć artefakty prawie współpłaszczyznowych powierzchni grzywki. W skrypcie zachowano konstrukcję poszczególnych pasm. Podeszwy sprowadzono do wysokości 0; test importu dopuszcza maksymalnie 2 mm różnicy.

## Co nie jest jeszcze gotowe

- Podobieństwo do ilustracji i charakter twarzy wymagają oceny użytkownika. Nie jest to finalny model anime.
- Siatka jest studium kształtu; liczba elementów i trójkątów nie stanowi budżetu docelowego. Przed grą potrzebne są retopologia, ograniczenie liczby obiektów i test wydajności.
- Nie ma finalnych UV, malowanych tekstur ani docelowego shadera anime. Obecne materiały to jednokolorowe bazy PBR.
- Nie ma kości, wag, korekt deformacji ani animacji. Dłonie są w pozie roboczej, a lanca stoi oddzielnie do przeglądu — postać jeszcze jej nie trzyma.
- Nie zmieniono systemu walki, portretów ani zapisów gry.

## Kolejność dalszej pracy

1. Ocena sylwetki, twarzy, fryzury i stroju z kilku stron; korekta podobieństwa.
2. Siatka do deformacji, UV i stylizowane materiały.
3. Rig: kręgosłup, kończyny, palce, dodatkowe kości włosów i połów. Lanca jako osobny obiekt z punktem chwytu; druga dłoń prowadzona do drugiego chwytu.
4. Pozycja bojowa i pchnięcie: przygotowanie, doskok, wyprowadzenie lancy, kontakt, wycofanie. Na tym etapie bez zastępowania pchnięcia rzutem.
5. Wspólna scena 3D bohatera i celu w Godocie: jedna kamera i płaszczyzna podłoża, potem podłączenie istniejącej prezentacji walki.

## Odtworzenie i kontrola

Uruchomić Blender z lokalnym profilem testowym, jak w `scripts/check-character-3d-pipeline.ps1`:

```powershell
& ./.tools/blender-4.5.13-windows-x64/blender.exe --background --factory-startup --python-exit-code 1 --python scripts/build_pierrot_3d_study.py
```

`-- --quick` przygotowuje jeden szybki podgląd; `-- --no-render` tylko geometrię i pliki źródłowe. Skrypt nadpisuje wyłącznie wyniki tego studium — ręczne poprawki w Blenderze należy zapisać pod nową nazwą przed ponownym generowaniem.

Import rzeczywistego modelu sprawdza `tools/character_3d_smoke/validate_study.gd` w odizolowanym projekcie, bez autoloadów gry. Testy kontrolują m.in. bryłę głowy i tułowia, skalę, położenie stóp i niezależną lancę. Nie są oceną jakości artystycznej ani potwierdzeniem gotowości do animacji.
