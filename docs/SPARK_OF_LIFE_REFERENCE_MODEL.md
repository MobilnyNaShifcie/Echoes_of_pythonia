# Iskra Życia — model wystawowy

- Zastępuje dawną grupę prostych kryształów dla `spark_of_life`.
- Zachowuje ikonę `godot/assets/items/materials/spark_of_life.png` (1254 × 1254).
- 19 zamkniętych siatek: świetlisty rdzeń, dwa wygięte metalowe liście,
  skręcona łodyżka i 15 wypukłych żyłek. Osobna płaszczyzna daje cień kontaktowy.
- Stałe UV zachowują wygląd ilustracji po obrocie. Jest to model opracowany
  na podstawie jednego obrazu, nie skan; niewidoczny w ikonie tył wykorzystuje
  tę samą teksturę, podobnie jak wcześniejsze modele referencyjne.
- Rdzeń wchodzi pod brzegi liści, aby na łączeniach nie powstawały czarne szczeliny.
- Wysokość referencyjna eliksiru, wspólne powiększenie 1,5× i kotwica na macie.
- Przeciągany jest ten sam model, bez kopii pozostającej na ladzie. Anulowanie
  lub odrzucony zakup przywraca model i cień; tabliczka pozostaje przy ladzie.
- Bez zmian w cenie (8500 złota), rotacji, zapisie i funkcji przedmiotu.
  Iskra nadal jest materiałem, nie miksturą. Nie dodano animacji ani cząsteczek.

## Kod i podglądy

- `godot/ui/screens/black_market/spark_of_life_reference_model.gd`
- Integracja: `market_item_3d.gd` i `black_market_offer_slot.gd`.
- `godot/tests/test_spark_of_life_reference.gd`
- `godot/tools/render_spark_of_life_preview.gd`
- Wyniki renderowania: `output/spark_of_life/` (wystawa, porównanie, obrót,
  przeciąganie i eksport `spark_of_life.glb`).

Renderer tworzy wyłącznie testową dostawę w sesji w pamięci, bez uruchamiania
aplikacji i bez odczytu zapisu użytkownika. Uruchamiać Godot Compatibility
z rozdzielczością 1920 × 1080 i osobnym APPDATA/LOCALAPPDATA w
`build/validation-runtime/spark-preview-profile`.

Regresje GUT: testy Iskry, łuski, modeli 3D rynku, modeli artefaktów,
przeciągania, tabliczek i `test_black_market_stage_five_d.gd`.
Używać `-gconfig=` i izolowanego profilu `build/validation-runtime/spark-profile`.
Znany komunikat izolowanego silnika o systemowym magazynie certyfikatów
nie wpływa na lokalne renderowanie ani te testy.
