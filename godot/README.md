# Echoes of Pythonia — Godot v0.25.0

This directory contains the Godot 4 migration of Echoes of Pythonia. The Python
implementation remains the behavioral reference until each feature has an
equivalent, tested GDScript implementation.

## Pinned toolchain

- Godot 4.7.1 stable
- GUT 9.7.0
- Godot State Charts 0.22.5
- Dialogic 2.0 Alpha 20
- GDScript Toolkit 4.5.0

## Layout

- `addons/` — pinned third-party Godot add-ons
- `assets/` — source-controlled game assets
- `autoload/` — intentionally small application-wide services
- `core/` — engine-independent domain rules and data models
- `features/` — vertical gameplay slices
- `scenes/` — composition and entry-point scenes
- `tests/` — GUT tests mirroring migrated behavior
- `ui/` — reusable controls, themes, and presentation logic

The current playable migration includes stages 0–3 and stage 4A, including all eight class
talent paths, 41 talents, passive Masteries, and specializations. All sixteen
base Path skills are active. Pierrot uses a dedicated
Fate Engine with encounter-local Fate Tokens and exact 1d6/2d6/3d6 tables.
Hunter has all additional Volley Techniques and named combinations. Mage has
elemental sequences and Arcane Weave, while Warrior has shield blocking,
Provoke, Shield Bash, counters, and retaliation. Purchased talents now drive
those mechanics, including Pierrot's Fate manipulation and four talent-only
active skills. The progression and combat panels remain placeholders; final
presentation is a later, separately approved step. Stage 4A adds all eight
Path and Mastery books as readable backpack items, plus a typed catalog and
placeholder browser for the five terminal regions. Recommended levels remain
warnings rather than access locks, matching the terminal game.

Open the project with the pinned local editor from the repository root:

```powershell
.\scripts\open-godot.ps1
```

Run formatting checks, lint, the legacy Python suite, the bootstrap smoke test,
and GUT tests with one command:

```powershell
.\scripts\check.ps1
```
