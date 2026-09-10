# Pchnięcie Losu — wzorcowa animacja Pierrota

## Zakres

Pierwsza umiejętność Pierrota (`fate_thrust`, poziom 5, koszt 5 Many). Działa na istniejących zapisach, dla obu płci, bez nowej postaci, migracji zapisu, zmiany cen, obrażeń, szans ani mechaniki kości. Nie dodaje auto-walki, petów ani timerów wypraw.

- Prawdziwy rzut z raportu walki → przygotowanie → ruch śladu lancy → trafienie → wygaszenie. Pojedynczy efekt trwa 0,92 s, kolejne pchnięcie w serii jest nieco szybsze.
- Kolory zgodne z Pierrotem: karmazyn, magenta, biel i oszczędne złoto. Jackpot ma złoty akcent; nie każdy atak wygląda jak Jackpot.
- Wynik 5 odtwarza dwa faktyczne trafienia. Jeśli pierwsze zabije wroga, drugiego efektu nie ma. Dodatkowy cios talentu Chaosu korzysta z faktycznej różnicy w raporcie, nie z wymyślonego dzielenia obrażeń. Metadane `fate_hits` zapisują krytyki poszczególnych trafień bez dodatkowego losowania.
- HP, jego liczba i obrażenia zmieniają się od momentu trafienia; Mana od początku rzutu. Model domeny nadal rozlicza turę od razu, animacja jedynie prezentuje zapisany wynik.
- Ograniczone animacje pomijają ruch i efekt. Nie ma pełnoekranowych błysków ani trzęsienia kamery. Wejście pozostaje zablokowane do końca prezentacji.
- Panel kości przeniesiony między górne panele postaci, poza tor efektów. Usunięty dekoracyjny napis VS. Stan podczas prezentacji to rzut/umiejętność, nie wezwanie do kolejnej akcji.

To animacja efektu umiejętności z delikatnym ruchem istniejącej sylwetki, a nie nowy szkielet lub zestaw klatek ciała Pierrota. Zatwierdzone postacie i karta skilla pozostają niezmienione. Dźwięk nie został dodany w tej partii.

## Grafika i źródło

Nowy asset: `godot/assets/combat/vfx/pierrot/fate_thrust_streak.png` (2172×724, prawdziwa alfa). Wygenerowano wbudowanym narzędziem imagegen, nie przez płatny skrypt/API. Obraz skopiowano do repozytorium; runtime nie zależy od katalogu Codex. Złote/karmazynowe romby trafienia i ich czas są rysowane przez Godot.

Oryginał: `C:/Users/kamil/.codex/generated_images/01a000c5-507d-7760-aa0e-b8169452ad43/exec-df3d4a37-fdd1-49e6-9cdf-6d5515da428d.png`.

Pełny prompt:

```text
Use case: stylized-concept. Asset type: transparent 2D VFX sprite for an anime-fantasy RPG, Pchnięcie Losu / Fate Thrust. Generate ONE isolated magic thrust streak, NOT a screenshot or illustration of a scene. Horizontal landscape canvas about 3:1. A razor sharp elongated lance-shaped surge points exactly RIGHT, tip at 88% width and 50% height, tapering ribbon tails back to 12% width. Color: rich crimson and deep magenta outer ribbon, rose-pink midtones, a narrow ivory-white inner cutting edge; tiny sparse antique-gold accents. A few large diamond/harlequin shaped light fragments, no dice, no cards, no characters. Elegant inked anime impact-animation style, confident tapered hand-painted shapes, high contrast grouped cel shading. One strong pointed silhouette with 2 graceful curving ribbon strokes around it, much negative space above and below. Designed to appear at 300x100 pixels, avoid microdetail, noise, speckled glitter, thick fog, realistic textures, 3D render or laser sci-fi appearance. Background MUST be genuinely transparent RGBA, including all corners, no black background, no colored backdrop, no checkerboard painted in. Entire effect inside canvas with 10% transparent margins, no clipping, no text, no frame. This will be animated by game code, do not draw multiple frames.
```

## Weryfikacja

- Wynik końcowy: **55/55 testów ukierunkowanych, 995 asercji**; **653/653 testy całego projektu, 17 160 asercji / 89 skryptów**. Podgląd rzeczywistego kliknięcia i animacji: **35/35 kontroli**, zero niezaliczonych. Linter wszystkich siedmiu zmienianych/dodanych skryptów GDScript: bez uwag.
- `godot/tools/fate_thrust_tests.json`: mapowanie trafień/krytyków, zgodność pełnych i ograniczonych animacji przy wszystkich 6 wynikach, brak dodatkowego RNG, podwójne kliknięcie, moment aktualizacji HP/Many, alfa, sprzątanie efektu, zabicie pierwszym ciosem, ustawienie wobec sylwetek i panelu kości przy 1280×720, 1920×1080, 2560×1080.
- `godot/tools/render_fate_thrust_preview.gd`: prawdziwa scena App, rzeczywiste kliknięcie karty, trzy rozdzielczości, obie płcie, dzień/noc, pojedyncze/podwójne pchnięcie i Jackpot. Sesje wyłącznie w pamięci; profil testowy APPDATA oddzielny od zapisów gracza.
- Podglądy: `output/fate_thrust_20260908/`; animowany podgląd z rzeczywistych klatek sceny tworzy `scripts/export_fate_thrust_preview.py`.
- Logi: `output/fate_thrust_tests.log`, `output/fate_thrust_full_tests.log`, `output/fate_thrust_render.log`, `output/fate_thrust_render.err.log`. Ostrzeżenia certyfikatów i wycieki zasobów przy wyjściu z narzędzi odnotowujemy osobno od wyników testów; nie przedstawiamy logów jako wolnych od wszystkich ostrzeżeń.

## Jak obejrzeć w grze

Uruchom ponownie grę, wczytaj obecną postać Pierrota i rozpocznij walkę. Wysuń dolną talię, wybierz **Pchnięcie Losu**, pozostaw **Animacje: pełne**. Potrzebujesz poziomu 5, Lancy Losu i co najmniej 5 Many — wymagania nie zostały zmienione. Grafiki kolejnych umiejętności powstają dopiero po ocenie tego wzorca.
