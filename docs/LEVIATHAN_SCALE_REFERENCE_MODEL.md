# Łuska Lewiatana — model wystawowy

## Zakres

- Zastępuje uproszczoną bryłę `leviathan_scale` na wystawie Czarnego Rynku.
- Wykorzystuje istniejącą ikonę `godot/assets/items/materials/leviathan_scale.png`
  (1273 × 1236); nie zmienia grafiki ani identyfikatora w ekwipunku.
- Dziewięć zamkniętych siatek: wygięta skorupa, trzy wypukłe żebra, obrzeże,
  metalowe okucie oraz trzy fazowania okucia. Cień kontaktowy to osobna płaszczyzna.
- Tekstura ma stałe UV, niezależne od kamery. To ręcznie opracowana geometria
  na podstawie jednej ilustracji, nie skan 3D. Niewidoczny w oryginale tył
  wykorzystuje tę samą ilustrację, zgodnie z pozostałymi modelami referencyjnymi.
- Model opiera się najniższym punktem o matę, ma wysokość ekspozycyjną eliksiru
  i korzysta ze wspólnego powiększenia 1,5× oraz kotwicy na ladzie.
- Przeciągany jest ten sam żywy model wraz ze swoim SubViewportem. Tabliczka
  zostaje na ladzie; anulowanie i odrzucony zakup przywracają model oraz cień.
- Cena bazowa 13 000 złota, losowanie dostaw i zapis gry pozostają bez zmian.

## Pliki

- Model: `godot/ui/screens/black_market/leviathan_scale_reference_model.gd`.
- Integracja: `market_item_3d.gd` i `black_market_offer_slot.gd` w tym samym katalogu.
- Testy: `godot/tests/test_leviathan_scale_reference.gd`.
- Izolowany renderer: `godot/tools/render_leviathan_scale_preview.gd`.
- Podglądy i eksport GLB: `output/leviathan_scale/`.

## Weryfikacja 2026-09-06

Godot 4.7.1, renderer Compatibility. Sprawdzono render na ladzie, zgodność
z ikoną, obrót o 35° i przeciąganie. Renderer tworzy wyłącznie sesję w pamięci;
nie uruchamia aplikacji ani nie korzysta z zapisu użytkownika.

37/37 testów i 1268 asercji w sześciu zestawach: `test_leviathan_scale_reference`,
`test_market_item_3d`, `test_market_artifact_reference`, `test_market_item_drag`,
`test_market_price_signs`, `test_black_market_stage_five_d`.
Testy uruchomiono z `-gconfig=` oraz osobnymi katalogami APPDATA/LOCALAPPDATA
w `build/validation-runtime/leviathan-profile`. Log silnika zawiera znane
ostrzeżenie o odczycie systemowego magazynu certyfikatów.
