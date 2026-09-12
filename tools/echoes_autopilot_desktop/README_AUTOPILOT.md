# Echoes Autopilot 3.0 — lokalne studio Astra + Sol

Narzędzie do pracy nad tym projektem Godota, przebudowane na podstawie paczki
`Echoes_Autopilot_FULL_SOURCE_v1_1`. Z oryginału zachowano ideę niezależnego
reviewera, dokładnych zamian tekstu, kopii plików i ograniczonej liczby poprawek.
Uzupełniono brakujące moduły i dodano działającą kontrolę wizualną oraz panel Windows.


## Aktualizacja 3.0 — siedem funkcji

1. **Napraw i sprawdź**: jedno działanie uruchamia poprawki, testy i ocenę. Szczegóły
   pokazują bieżący etap i liczbę ukończonych etapów. Inne zadanie nie jest przerywane.
2. **Wznawianie etapów**: po STOPPED/BLOCKED kontroler ponownie używa ukończonych
   etapów tylko przy zgodności źródeł, konfiguracji, narzędzi i zapisanych dowodów.
   Zmiana kodu, obrazu, wzorca, modelu, fixture lub logu wymaga nowego przebiegu.
   Zamknięty wynik NEEDS_CHANGES rozpoczyna świeży cykl naprawczy na aktualnych plikach.
3. **Krótsza walidacja**: zakończony start i GUT z check.ps1 nie są powtarzane, również gdy wykryły błąd.
   Kolejne zmiany ograniczone do UI/scen/grafik/dokumentacji zaczynają od kontroli
   zasobów, formatu i lint. Końcowe PASSED nadal wymaga pełnej walidacji.
4. **Usterki**: numery, dowody i historia open/fixed/returned/unverified w issues.json.
   Brak ustalenia w niepełnej lub innej ocenie nie oznacza naprawy. Brak postępu
   zatrzymuje powtarzanie tych samych cykli. Rejestr nie importuje automatycznie
   dawnych raportów pochodzących z innej wersji gry.
5. **Test czynności gracza**: rzeczywiste przyciski/sygnały UI wykonują zakup skór, wykonanie kaptura w warsztacie i
   założenie tej samej instancji, turę walki, zapis oraz wczytanie. Sprawdzane są
   złoto, PŻ i tożsamość wyposażenia. To kontrolowana sekwencja, nie swobodna gra AI.
6. **Studio grafik**: katalog wzorców, nowe zlecenia, generowanie 1–4 wariantów PNG
   przez wbudowane imagegen w Codex, import z dysku, pomiary alfa i marginesów,
   podgląd rzeczywistej sceny w osobnej kopii oraz niezależna ocena Sola.
   Zastosowanie wariantu wymaga PASS, niezmienionych dowodów i źródeł; zachowuje
   oryginał. Nie wymaga nowego klucza API. Generowanie zużywa dostępny limit konta.
7. **Projekt i branch**: wybór lokalnego/zdalnego brancha, fetch origin, osobne
   katalogi robocze i dołączanie bieżących niezacommitowanych plików. Kopie mają
   własne importy Godota i profile testowe. Zmiany z kopii pokazuje listę plików;
   przenoszenie zaliczonego wyniku odmawia nadpisania równoległych zmian użytkownika oraz zastosowania kopii zmienionej po ocenie.

### Studio grafik

Wybierz istniejący PNG gry, region i scenę, opisz zmianę, kliknij Generuj PNG.
Możesz też wybrać Importuj PNG. Zaznacz wariant i kliknij Podgląd + Sol.
Otwórz wynik pokazuje raport ze sceną. Zastosuj wariant kopiuje zaliczony PNG do
jego miejsca w grze i zachowuje kopię. Nowe tworzy oddzielne zlecenie; Historia
otwiera zapisany request.json. Wzorce zatwierdza się świadomie w katalogu wzorców.
Pierwszy import całej gry do świeżego katalogu może trwać kilka minut. Zatrzymaj pracę studia przerywa jego proces; zamknięcie okna studia także wysyła zatrzymanie. Jedno generowanie obejmuje po jednym wywołaniu imagegen na zamówiony wariant, bez automatycznego poprawiania grafiki w pętli.

### Kopie robocze

Puste pole brancha oznacza bieżącą wersję. Dołączanie lokalnych zmian działa tylko
na aktualnym commicie; dla innego brancha odznacz ten wybór. Narzędzia Python i
Godot są używane z instalacji głównego projektu, a dane gry i zapisy są oddzielne.
Raporty głównych zadań pozostają w output/ai-team. Worktree i raporty grafik są
zachowywane do przeglądu. Usunięcie folderu ręcznie wymaga także uporządkowania
rejestru Git worktree; panel nie usuwa automatycznie kopii z niezapisanymi zmianami.

## Aktualny projekt

Panel pracuje bezpośrednio na katalogu repozytorium, w którym jest zainstalowany.
Domyślnie może pracować na bieżących plikach; tryb osobnej kopii wybiera się w oknie Projekt i branch. Pobranie GitHuba jest osobną, świadomą operacją.
Wersja 3.0 pokazuje pełny katalog, aktualny branch i commit nad formularzem;
te same dane trafiają do promptu Astry oraz raportu. Historyczne błędy pozostają
w kolejce z oznaczeniem brancha, na którym je wykryto. Wznowienie czyta aktualne pliki.

2026-09-12: przełączono lokalny projekt z `snapshot/pre-ai-team-2026-09-10`
na pobrany `ai/echoes-team` (`67741fe`, 28 commitów naprzód). Zachowano lokalne
reguły stylu, kolejkę i raporty. Panel znajduje się teraz w
`tools/echoes_autopilot_desktop`; `tools/echoes_ai_team` zawiera oryginalne narzędzia
z tego brancha. Launcher `ECHOES_AUTOPILOT.cmd` uruchamia panel desktopowy.
Nowszy branch zawiera poprawiony walidator oraz PNG Orena v6 i Mireli v3.

## Uruchomienie

Dwuklik **ECHOES_AUTOPILOT.cmd** w katalogu nadrzędnym projektu.
Alternatywnie w katalogu repozytorium:

```powershell
.\scripts\start-autopilot.ps1
```

1. Wpisz zadanie i kliknij **Dodaj zadanie**.
2. Kliknij **Uruchom kolejkę**. Zadania wykonują się kolejno.
3. Obserwuj etap pracy i dziennik. **Zatrzymaj** kończy aktywny proces i wstrzymuje kolejkę.
4. Zaznacz przebieg i kliknij **Otwórz raport**. Raport zawiera ocenę Sola, dowody,
   zalecane poprawki, logi, obrazy i rzeczywiste zmiany w plikach.
5. Po błędzie kolejka zatrzymuje się. **Wznów zaznaczone** kontynuuje z zapisanym
   zadaniem i uwagami. Jeśli źródła się zmieniły, Astra bada aktualne pliki od nowa;
   stare propozycje nie są odtwarzane. Przycisk uruchamia dokładnie zaznaczone zadanie,
   niezależnie od wcześniejszych pozycji oczekujących. Powód zatrzymania widać po
   zaznaczeniu wiersza, również dla starych raportów.

**Audyt Sola** sprawdza bieżącą grę bez wprowadzania zmian.
**Napraw i sprawdź** uruchamia zadanie naprawcze z zaznaczonego raportu. Jeśli trwa inne zadanie, naprawa czeka w kolejce.
**Usuń z kolejki** usuwa zaznaczone zadanie, które jeszcze nie zostało rozpoczęte.
**Tylko testy** i **Tylko obrazy** działają lokalnie bez wywoływania modeli.
**Diagnostyka** sprawdza Godota, PowerShell 7, Codex i jego logowanie.

## Przepływ

- Astra (`gpt-6-astra`) czyta projekt i przygotowuje dokładne zamiany lub nowe pliki.
- Lokalny kontroler weryfikuje ścieżki, wykrywa równoległe edycje, zapisuje kopie
  i stosuje całą zweryfikowaną propozycję. Zachowuje istniejące niezapisane w Git zmiany.
- `scripts/check.ps1` wykonuje kontrole, start gry i pełny GUT. Brakujące etapy są wykonywane osobno; zakończone nie są powtarzane.
- Renderer zapisuje 11 scen w 1280×720 i 1920×1080. Zadania mają obrazy przed i po zmianach.
- Sol (`gpt-5.6-sol`) osobno ocenia kod/testy oraz każdą paczkę obrazów. W raporcie
  wskazuje błędy rozgrywki, niespójności UI, kadrowanie, proporcje, oświetlenie, styl,
  czytelność i priorytet naprawy. Sugestie rozwoju są oddzielone od wymaganych napraw.
- Uwagi wracają do Astry. Domyślnie dozwolone są dwa cykle, maksymalnie pięć.
- `PASSED` wymaga zarówno zaliczonych kontroli technicznych, jak i wszystkich ocen Sola.
  Sam komunikat modelu „PASS” nie wystarcza. Niepełny wynik modelu blokuje przebieg.

Każda paczka wizualna otrzymuje zatwierdzone ilustracje klas i aktualną mapę.
Sceny walki otrzymują dodatkowo krajobraz właściwego regionu oraz źródłowy PNG
przeciwnika. Kontroler sprawdza RGBA, przezroczyste narożniki i marginesy; Sol ocenia
sylwetkę, kierunek, pozę i styl. `scenario_regions` oraz `scenario_enemies` w polityce
muszą obejmować te same scenariusze. Reguły stylu, kryteria
Sola i referencje są odczytywane z bloku `autopilot-art-policy` w kanonicznym
`AI_CONTEXT/ART_DIRECTION.md` (sekcja 35); Astra może zmieniać ten konkretny plik bez zmiany
kontrolera. `scripts/build_art_reference_board.py --region ice_coast --output
output/art-review/ice_coast.png` przygotowuje planszę, manifest i wspólny prompt.
Skrypt planszy korzysta z Pillow (`pip install -r requirements-dev.txt`).

Studio Grafik czyta aktualne reguły przed każdym wariantem i review; zapisane
zlecenie nie zamraża starego stylu. Referencje stylu pochodzą wyłącznie z polityki,
a stary potwór służy zachowaniu tożsamości. Wariant wymaga właściwej pary
region/scenariusz, prawdziwego RGBA i minimum 5% marginesu na każdej krawędzi.
Review przeciwników ma osobne obowiązkowe oceny realizmu i spójności oraz dowody
porównania ze wzorcami. Niepełna ocena nie może dać PASS. Zmiana polityki lub
plików wzorcowych unieważnia stare review. Szczegóły procesu pozostają w
`docs/ART_AND_AUDIO_PIPELINE_v0.25.0.md`; decyzję o integracji podejmuje właściciel.

Każda rola działa jako nowa, niezależna sesja Codex CLI zalogowana na Twoje konto.
To nie jest sterowanie istniejącą kartą rozmowy „Sol”. Kontekst przekazuje kontroler.
Astra przygotowująca kod i Sol mają sandbox `read-only`; zapis zmian należy do kontrolera. Generator PNG ma zapis wyłącznie do katalogu wariantu i korzysta z wbudowanego imagegen.
Poza panelem można dalej pracować w tej rozmowie i używać **Audyt Sola** do oceny zmian.

## Dane i wymagania

Wywołania modeli przekazują do OpenAI zadanie, odpowiedni kod, logi i załączone
zrzuty gry. Użytkownik zezwolił na ten przepływ podczas konfiguracji narzędzia.
Narzędzie używa istniejącego logowania Codex, nie przechowuje kopii tokenów ani
nie wymaga wpisywania klucza API w panelu. Obowiązują limity dostępne na tym koncie.

Wymagane: Python 3.12+ z Tkinter, Codex CLI, Godot 4.7.1 oraz PowerShell **7**.
Projekt zawiera środowisko `.venv` i lokalny silnik `.tools/godot`.
Narzędzie wykrywa też CLI i PowerShell dostarczane przez aplikację Codex.
Kontroler używa biblioteki standardowej Pythona oraz Pillow do kontroli źródłowych
PNG. Zależności instaluje `pip install -r requirements-dev.txt`; testy używają pytest.

Ustawienia są w `output/ai-team/settings.json`. Panel zapisuje modele i limit cykli.
W JSON można też ustawić ścieżki programów, listę scen, rozdzielczości oraz limity czasu.
Przykład ograniczenia audytu:

```powershell
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --audit --scenarios city,inn,equipment
```

## Polecenia

```powershell
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --doctor
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --capture
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --test
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --audit
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py "Popraw czytelność opisu przedmiotów w ekwipunku"
.\.venv\Scripts\python.exe tools\echoes_autopilot_desktop\autopilot.py --resume-latest
.\.venv\Scripts\python.exe -m pytest -q tests\test_autopilot.py tools\echoes_autopilot_desktop\test_controller_edge_cases.py
```

## Raporty i odzyskiwanie

Każdy przebieg tworzy własny `output/ai-team/RUN-.../`:

- `report.html`: raport do otwarcia w przeglądarce, także przy błędzie lub przerwaniu;
- `state.json`, `events.jsonl`, `settings.json`: stan, historia i użyta konfiguracja;
- `before/` i `cycle-N/after/`: obrazy przed/po, manifest i log renderera;
- `cycle-N/astra/`, `cycle-N/sol-*/`: wysłany prompt, odpowiedź i dziennik modelu;
- `cycle-N/backup/`: oryginalne bajty zmienionych plików, manifest i zastosowany diff;
- `cycle-N/tests/`: logi kontroli.

Po odrzuceniu zmiany przez Sola pliki pozostają do dalszej poprawy lub przeglądu.
Program nie wykonuje `git reset`, commitu, push, PR ani merge. W oknie Projekt i branch może pobrać referencje z GitHuba i utworzyć odłączony worktree dla wybranej wersji. Główny checkout zachowuje swój branch.
Przy ręcznym przywracaniu korzystaj z kopii tylko po porównaniu z obecną treścią,
aby nie nadpisać późniejszych zmian. Utworzone nowe pliki są oznaczone w manifeście.
Blokada procesu zapobiega uruchomieniu dwóch kontrolerów jednocześnie.

## Zakres i ograniczenia

Automatyczne zmiany obejmują tekstowe źródła Godota, sceny, zasoby tekstowe/SVG,
projekt.godot, dokumentację, testy i listy zasobów w trzech walidatorach
`check-city-assets.ps1`, `check-item-assets.ps1`, `check-skill-card-assets.ps1` oraz
powiązane `normalize-city-assets.ps1`, `normalize-item-assets.ps1` oraz
`build_art_reference_board.py`.
Główny `check.ps1` i sam kontroler pozostają poza zakresem zapisów modeli. Każda propozycja ma do 16 plików i 400 KB końcowej
zawartości. Standardowe zadania Astry nie zapisują binariów. Oddzielne Studio grafik obsługuje generowanie PNG, podgląd i zastosowanie wybranego wariantu; animacje i modele 3D pozostają poza automatycznymi zmianami. Sol może wykrywać ich problemy, a Astra może poprawiać
wykorzystanie istniejących zasobów, układ, położenie i skalę. Nowe warianty PNG można przygotować w Studio grafik albo zaimportować z dysku.

Ocena wizualna obejmuje zapisane scenariusze, a nie wszystkie możliwe stany gry.
Są to rzeczywiste renderowane ekrany z przygotowanymi danymi; nie swobodna ręczna
rozgrywka modelu. Zmiany rozgrywki sprawdzają także istniejące testy GUT.
Zapis gracza jest odseparowany od fixture testowych. Renderer potrzebuje dostępnego
pulpitu Windows i OpenGL; `--headless` nie zastępuje kontroli obrazów.

Pełne obrazy są zachowywane również przy błędach zgłoszonych podczas zamykania
renderera. Takie błędy są widoczne w logu i blokują pełne zaliczenie audytu.
`CAPTURED` oznacza wyłącznie zapis kompletu obrazów, nie aprobatę jakości gry.
`TESTED` oznacza zaliczone testy techniczne, bez oceny Sola.

Historyczne raporty ze starego brancha wymieniają Orena v5 i Mirelę v2.
Aktualny `ai/echoes-team` sprawdza Orena v6 i Mirelę v3; stare raporty nie
stanowią listy zasobów wymaganych przez bieżącą grę.

## Źródła integracji

Interfejs CLI sprawdzono przez lokalne `codex exec --help` oraz oficjalną dokumentację:

- [Codex — tryb nieinteraktywny](https://learn.chatgpt.com/docs/non-interactive-mode)
- [Parametry CLI, obrazy i wynik JSON](https://learn.chatgpt.com/docs/developer-commands?surface=cli)
- [GPT-5.6 Sol](https://developers.openai.com/api/docs/models/gpt-5.6-sol)

Dokumenty paczki v1.1 opisujące automatyczny commit/push potraktowano jako materiał
projektowy. Bieżącym zakresem jest lokalne narzędzie do zmian i kontroli gry.
