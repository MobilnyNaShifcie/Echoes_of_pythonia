# Pierrot — prototyp warstwowego pchnięcia (2026-09-08)

## Zakres i stan

Użytkownik zaakceptował kierunek: **pchnięcie, nie rzut lancą**, najpierw prototyp ciała i broni bez magii. Powstała osobna scena `godot/tools/pierrot_thrust_lab.tscn`. Nie podmieniono zatwierdzonego portretu, grafiki wyboru klasy ani kodu zwykłej walki. Nie zmieniono balansu, raportów obrażeń, RNG ani zapisów.

**To prototyp ruchu do oceny, nie gotowa animacja produkcyjna.** Nowe części nie są idealną rekonstrukcją oryginalnego stroju, krawędzie i łączenia wymagają dalszej pracy. Nie należy automatycznie zastępować nim wszystkich Pierrotów; prototyp przedstawia tylko wariant żeński. Męski portret pozostaje bez zmian.

## Implementacja

- Godot Skeleton2D z 15 Bone2D; osobny tułów, głowa, ogony stroju, dwa łańcuchy rąk, dwa łańcuchy nóg, oddzielne stopy i lanca.
- Polygon2D z autorskimi wierzchołkami i współrzędnymi UV do wygenerowanego arkusza. Oryginalne arkusze PNG nie są przetwarzane ani nadpisywane.
- Analityczne dwusegmentowe IK utrzymuje długości rąk/nóg. Dwa punkty chwytu na lancy mają stały rozstaw. Końce przedramion pokrywają się z chwytami, także po skalowaniu sceny.
- Przygotowanie → doskok → pchnięcie → kontakt grotem → wycofanie lancy → powrót. Czas podstawowy 1,85 s. Czysta funkcja pozy umożliwia przewijanie i odtwarzanie bez dryfu transformacji.
- Dystans doskoku liczony z długości broni i punktu trafienia; nie jest to wystrzelenie tekstury z tułowia.
- Odtwarzanie/pauza, tempo 1× / 0,35×, suwak fazy, podgląd kości/chwytów, reset. Spacja przełącza odtwarzanie.
- Brak magii jest celowy. Nie podłączono jeszcze istniejącego efektu VFX do grotu, wariantu dwóch ciosów ani Jackpotu. To kolejny etap po ocenie ruchu i oczyszczeniu grafiki.

## Istotny problem źródeł

Wbudowany generator zwrócił **RGB z narysowaną szachownicą**, mimo żądania prawdziwej przezroczystości. Dwie ukierunkowane poprawki również nie dostarczyły kanału alfa. Nie uznajemy ich za poprawne przezroczyste sprite'y. Wysłano osobne pytanie o zgodę na programowe usunięcie tła; w chwili sporządzania tej notatki brak odpowiedzi.

Do testu ruchu zastosowano zwykłe natywne obrysy siatek UV, bez edycji bitmap. Pozwala to zobaczyć złożoną postać, ale miejscami zostają jasne krawędzie i fragmenty szachownicy w drobnych prześwitach ornamentów. **Nie wolno w tym stanie włączyć prototypu jako domyślnej postaci w grze.** Po uzyskaniu zgody na oczyszczenie przygotować osobne pliki RGBA i zweryfikować na ciemnym i jasnym tle, bez utraty białych tkanin/połysków.

## Pliki

- `godot/assets/combat/rigs/pierrot_prototype/parts-source.png` — arkusz 1254×1254, RGB, bez prawdziwego alfa.
- `godot/assets/combat/rigs/pierrot_prototype/lance-source.png` — lanca 2172×724, RGB, bez prawdziwego alfa.
- `godot/ui/presentation/rigs/pierrot_thrust_pose.gd` — czysta geometria i fazy.
- `godot/ui/presentation/rigs/pierrot_cutout_art.gd` — obrysy, UV, osie i skale części.
- `godot/ui/presentation/rigs/pierrot_cutout_rig.gd` — szkielet i siatki.
- `godot/tools/pierrot_thrust_lab.tscn` / `.gd` — samodzielny podgląd.
- `godot/tools/render_pierrot_rig_preview.gd` — kadry z prawdziwego renderera Godot.
- `scripts/export_pierrot_rig_preview.py` — wyłącznie pakowanie kadrów renderera do GIF, bez modyfikacji źródłowej grafiki.
- `output/pierrot_rig_20260908/` — kadry sześciu faz i animowany podgląd.

## Walidacja

Testy: `godot/tools/pierrot_rig_tests.json` / `godot/tests/test_pierrot_cutout_rig.gd`: stała długość broni i kończyn, rzeczywisty kontakt grotu, dwa chwyty, ciągłość faz, odwracalność próbkowania, poprawność triangulacji UV, transformacje Bone2D w skalowanej scenie, izolacja podglądu. Testy i render uruchamiane na profilu `build/validation-runtime/ui-refresh-profile`; brak dostępu do prawdziwych zapisów użytkownika. Wyniki końcowe należy sprawdzić w `output/pierrot_rig_tests.log`.

Podgląd renderowany OpenGL Compatibility na Intel UHD Graphics 620; znane ostrzeżenie środowiska o magazynie certyfikatów nie jest błędem animacji. Przechwytywanie z ustalonym krokiem nie stanowi pomiaru FPS.

## Uruchomienie

W Godot otworzyć scenę `res://tools/pierrot_thrust_lab.tscn` i uruchomić bieżącą scenę (F6). Scena nie tworzy GameSession ani nie odczytuje/zapisuje stanu gry.

Źródła API: [Bone2D](https://docs.godotengine.org/en/stable/classes/class_bone2d.html), [2D skeletons](https://docs.godotengine.org/en/stable/tutorials/animation/2d_skeletons.html).

## Tryb i pełne prompty generowania

Użyto wyłącznie **wbudowanego imagegen**, bez zewnętrznego API, klucza API i bez przełączenia modelu/CLI. Referencja: zatwierdzona `godot/assets/combat/heroes/pierrot.png`. Oryginały zachowane w katalogu generated_images; kopie projektu wskazane powyżej.

### Arkusz części — wybrany jako źródło prototypu

Źródło: `exec-402b5d0b-362e-4a72-be40-7dc18f8c8937.png`.

Use the attached approved game heroine as the identity, costume and rendering reference. Create a professional 2D cutout animation PARTS ATLAS for this SAME adult female Pierrot lancer, NOT a finished character pose. She must retain the short wavy crimson hair, red eyes, black corset with gold clasps, white off-shoulder blouse, red/white harlequin diamond fabric, crimson/black heeled boots, and the same polished hand-painted anime fantasy illustration style. Clean readable contour lines and grouped shadows, no photorealism, no sparkles, no outer glow. Three-quarter view facing RIGHT, coherent lighting from upper left.
Technical composition: a square transparent RGBA sprite sheet, 3 columns by 3 rows of exactly equal cells. NO grid lines, NO text, NO labels, NO shadows on background. Each part centered and fully isolated inside its own cell, with generous clear alpha separation. Parts never touch other cells. Draw complete hidden joint overlap ends, rounded natural overlaps, not chopped jagged ends. No weapon in this atlas. Do not draw a full assembled person anywhere.
CELL row1 col1: one headless, armless, legless torso from neck to hips: black fitted corset, off-shoulder white blouse neckline and gold detailing, red/black hip costume. Torso upright, three-quarter right. No long hanging skirt in this cell.
CELL row1 col2: her complete head including short wavy crimson hair and neck. Same recognizable face, red eyes, focused expression, looking right, no hat, no shoulders.
CELL row1 col3: one complete separate pair of flowing red/white diamond and crimson skirt tails, attached together at the waistband, trailing diagonally downward and LEFT, clean readable folds, no body or legs.
CELL row2 col1: a single upper arm with the heroine's short white/red harlequin puff sleeve and upper arm, shoulder at LEFT, elbow at RIGHT; straight horizontal limb, overlapping rounded ends. No forearm or hand.
CELL row2 col2: a single forearm with simple wrist cuff and closed GRIPPING HAND seen in three-quarter side view, elbow at LEFT, fist at RIGHT, straight horizontal; the fist is empty, designed to wrap around a separately drawn lance shaft. No weapon. No upper arm.
CELL row2 col3: the opposite forearm and closed gripping hand, slightly different visible side, elbow LEFT and fist RIGHT, same proportions and costume.
CELL row3 col1: a single upper leg / thigh from hip to knee, upright pointing DOWN, matching her fitted black/red thigh costume and exposed upper thigh. No lower leg or foot. Rounded overlap at hip and knee.
CELL row3 col2: a single lower leg with black/crimson fitted high boot from knee through ankle to pointed heeled shoe, upright DOWN, shoe pointing RIGHT. Same slender but natural proportions, gold trim, clear knee overlap.
CELL row3 col3: the opposite lower leg with matching black/crimson boot and pointed heeled shoe, upright DOWN, shoe pointing RIGHT, three-quarter far-side view.
Output high resolution, ideally 3072x3072, clean genuine transparent alpha. This is production cutout art, not a diagram, not a sprite pose sequence, no checkerboard painted into image. Preserve sophisticated anime anatomy, not chibi or paper-doll proportions.

### Lanca — wybrana jako źródło prototypu

Źródło: `exec-bbf734f5-4330-4da2-989c-4e773488223b.png`.

Create an isolated animation sprite of ONLY the Pierrot heroine's ornate double-ended lance, using the attached approved heroine illustration as the exact weapon design reference. Match her weapon: long slim dark crimson/black straight shaft with restrained small gold collars, a long sharp crimson red diamond/spearhead at the RIGHT end with angular black/gold structural edging, and a smaller crimson pointed counterweight at the LEFT end. Rich hand-painted anime fantasy game art, crisp silhouette, grouped cel-painted shading, same red/black/ivory/gold palette as the heroine. No neon emission, no bloom, no particles, no magic trail.
The WHOLE lance must be completely straight HORIZONTAL, viewed side-on in the screen plane, main spear tip pointing RIGHT. Center it on a very wide transparent RGBA canvas, approximately 3:1 aspect ratio. The shaft is one continuous thin straight cylinder, NOT curving or tapering randomly. The weapon should be about 3 times a human head-to-foot height in-world, but here it is an isolated object without any person or hands. Elegant long forward blade, NOT a huge axe. Leave a narrow safe transparent margin around both tips, generous transparent above and below. No text, no icon frame, no stand, no ground, no shadow. Real alpha transparency, not a painted checkerboard. This is a separate movable weapon for a 2D skeleton animation, not a card illustration or projectile effect.

### Próba poprawy alfa arkusza — nie spełniła wymagania

Wynik: `exec-c5644975-543c-444e-b14c-d9f0ed728c94.png`.

Remove the gray and white checkerboard background from this sprite atlas. Output an actual RGBA PNG with alpha=0 in every background pixel, including between fingers, fabric and hair. Background removal ONLY: preserve the nine cutout parts exactly, same colors, proportions, details, locations, dimensions and sharp contours. Do not add, recolor, rearrange or redraw anything. This must be genuine transparency, not a visual transparency pattern.

### Próba poprawy alfa lancy — nie spełniła wymagania

Wynik: `exec-a03e6829-3f2c-4949-81dc-16c44669fcb5.png`.

Remove the checkerboard background and every faint ghost image from behind this lance. Return only the exact same sharp red/black/gold lance on actual alpha transparency. Transparent background / background=transparent. Do not redesign the lance. Preserve its straight horizontal orientation, tips, proportions, lighting, and sharp painted contours. Output a genuine transparent PNG sprite with no background pixels, ready for compositing in a game.

