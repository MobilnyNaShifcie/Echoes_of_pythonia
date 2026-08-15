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

The current playable migration includes stages 0–2 and character progression
stages 3A–3B. The skill catalog preserves all four Paths; the shared combat
execution for Warrior, Hunter, and Mage is active, while Pierrot's dice-based
resolution remains explicitly reserved for stage 3C.

Open the project with the pinned local editor from the repository root:

```powershell
.\scripts\open-godot.ps1
```

Run formatting checks, lint, the legacy Python suite, the bootstrap smoke test,
and GUT tests with one command:

```powershell
.\scripts\check.ps1
```
