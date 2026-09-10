# Echoes of Pythonia — Technical Rules

> Role: engineering contract for AI-assisted development  
> Project: Echoes of Pythonia  
> Godot line: v0.25.x  
> Engine baseline: Godot 4.7.1 stable  
> Protected baseline: `snapshot/pre-ai-team-2026-09-10`  
> Primary AI working branch: `ai/echoes-team`

---

## 1. Purpose

This document defines **how AI agents are allowed to modify the Echoes of Pythonia repository**.

It is not a gameplay design document.

Gameplay intent belongs primarily to:

- `AI_CONTEXT/PROJECT_BIBLE.md`
- `AI_CONTEXT/GAME_DESIGN.md`

Visual rules belong primarily to:

- `AI_CONTEXT/UI_RULES.md`
- `AI_CONTEXT/ART_DIRECTION.md`

Agent-to-agent handoff rules belong primarily to:

- `AI_CONTEXT/AI_WORKFLOW.md`

This file controls:

- architecture;
- repository safety;
- source ownership;
- Godot conventions;
- test expectations;
- save compatibility;
- file handling;
- asset integration boundaries;
- dependency/version changes;
- Git behavior;
- completion criteria.

Every developer agent and reviewer must read this file before modifying code.

---

# PART I — SOURCE OF TRUTH

## 2. Source-of-truth priority

When technical sources disagree, use this priority:

1. explicit latest user instruction;
2. `AI_CONTEXT/PROJECT_BIBLE.md`;
3. `AI_CONTEXT/GAME_DESIGN.md`;
4. this `TECHNICAL_RULES.md`;
5. specialized AI_CONTEXT document;
6. current automated tests;
7. current domain implementation;
8. current project documentation in `docs/`;
9. terminal implementation when it still acts as parity reference;
10. older notes / comments / abandoned prototypes.

This priority does **not** mean an AI agent may casually change a test to make new behavior pass.

If tests and approved design disagree:

- stop;
- identify the conflict;
- explain which behavior each source requires;
- propose the smallest safe resolution;
- do not silently rewrite the test.

---

## 3. Current migration principle

The project was migrated from a Python terminal implementation to Godot 4.

The technical migration rules remain:

- domain logic before presentation;
- UI calls tested domain services;
- gameplay definitions should be typed resources or validated data;
- migration should happen in runnable vertical slices;
- presentation must not become the source of combat/economy/quest/save results;
- terminal behavior remains reference material for mechanics whose parity is still intentionally preserved.

Do not use the existence of old Python code as permission to add new production gameplay to the terminal version.

v0.24.7 closed normal terminal feature development.

---

# PART II — CURRENT PLATFORM

## 4. Godot version

Current project baseline:

**Godot 4.7.1 stable**

The project configuration declares Godot 4.7 features.

Do not upgrade:

- Godot;
- GUT;
- Dialogic;
- Godot State Charts;
- gdtoolkit;
- pytest;

as part of an unrelated feature.

Engine/add-on upgrades must be isolated work with:

- dedicated task;
- compatibility review;
- full test run;
- project launch test;
- regression review.

---

## 5. Main Godot project

Godot project root:

```text
godot/
```

Godot configuration:

```text
godot/project.godot
```

Main scene:

```text
res://scenes/app/app.tscn
```

Do not create a second competing Godot project for normal production features.

Small diagnostic projects under `tools/` may exist for isolated pipelines, but they must not become alternate application roots.

---

## 6. Display baseline

Reference resolution:

**1920 × 1080**

Functional minimum:

**1280 × 720**

Current project stretch configuration is based on:

```text
canvas_items
```

with expandable aspect behavior.

A UI change is not technically complete if it only looks correct at one developer-window size.

At minimum, visually verify:

- 1920×1080 reference layout;
- 1280×720 functional layout;

for any materially changed screen.

---

## 7. Renderer baseline

Current renderer:

```text
gl_compatibility
```

This is also used by the validation script for headless/bootstrap checks.

Do not switch the project to another renderer as a side effect of unrelated scene or asset work.

A renderer change requires explicit compatibility testing.

---

## 8. Enabled Godot plugins

Current project enables:

- Dialogic;
- Godot State Charts;
- GUT.

### Dialogic rule

Dialogic is a presentation layer for dialogue.

It must not become authoritative storage for:

- quest state;
- rewards;
- reputation;
- inventory mutation;
- companion progression;
- permanent story flags already owned by domain state.

Dialogue may request a domain action.

Domain services own the result.

---

# PART III — REPOSITORY STRUCTURE

## 9. Repository root

The repository intentionally contains both:

- legacy Python implementation;
- current Godot implementation.

Typical root-level areas include:

```text
combat/
companions/
data/
enemies/
game/
items/
player/
quests/
rifts/
systems/
tests/
ui/
world/

godot/
docs/
scripts/
tools/
AI_CONTEXT/
```

Do not delete legacy Python directories merely because the Godot version exists.

The legacy suite is still used as regression/specification support during migration.

---

## 10. Godot domain structure

Current Godot domain areas include:

```text
godot/core/combat/
godot/core/companions/
godot/core/dungeons/
godot/core/economy/
godot/core/game/
godot/core/items/
godot/core/math/
godot/core/player/
godot/core/progression/
godot/core/quests/
godot/core/rifts/
godot/core/save/
godot/core/skills/
godot/core/world/
```

Before creating a new service:

1. search for an existing owner;
2. inspect nearby services/models;
3. inspect tests;
4. extend the existing owner if responsibility fits;
5. create a new subsystem only when responsibility is genuinely distinct.

---

## 11. UI structure

Player-facing presentation lives under Godot UI/scenes rather than in domain models.

Typical areas:

```text
godot/ui/components/
godot/ui/presentation/
godot/ui/screens/
godot/scenes/
```

UI scripts may:

- render state;
- gather input;
- call services;
- translate service results into presentation;
- manage purely visual animation/state.

UI scripts must not independently own:

- damage formulas;
- pricing;
- crafting costs;
- quest completion;
- Guild rank thresholds;
- item generation;
- save migration;
- Black Market RNG;
- companion combat decisions;
- Rift lifecycle.

---

# PART IV — ARCHITECTURE

## 12. Core architecture rule

Use:

```text
UI → domain/service → state/model/data
```

Avoid:

```text
UI → direct mutation everywhere
```

and avoid:

```text
Control node state = gameplay truth
```

A scene-tree node being visible/selected/disabled must not be the only evidence that a permanent gameplay state exists.

---

## 13. Domain ownership

Each persistent or gameplay-critical concept should have one clear owner.

Examples:

- player stats → player/stat domain;
- combat → combat domain;
- item definitions → item catalogs/resources;
- inventory ownership → inventory/equipment domain;
- economy transaction → economy service;
- quests → quest service/state;
- Guild → Guild domain/service;
- companions → companion/party state and services;
- dungeon run → dungeon subsystem;
- Rift lifecycle → Rift subsystem;
- saves → save codecs/services;
- world regions → world catalogs/services.

Do not create parallel ownership because it is convenient for a screen.

---

## 14. Avoid duplicated formulas

Never copy a gameplay formula into:

- UI label code;
- tooltip code;
- test fixtures used as production data;
- a second service;
- an animation script.

Instead, expose the authoritative computed result through a model/service.

If a tooltip needs a prediction:

- call the same domain calculation;
- or use a pure shared calculation helper.

---

## 15. Prefer explicit state models

For non-trivial systems, prefer explicit typed/validated state such as:

- player state;
- party state;
- companion state;
- dungeon run state;
- Rift state;
- expedition-preparation state.

Avoid large dictionaries with undocumented magic keys when a domain type already exists or should reasonably exist.

---

## 16. Data-driven content

Definitions for:

- items;
- regions;
- enemies;
- skills;
- quests;
- dungeons;
- companion templates;
- progression;

should remain in catalogs/resources/validated data rather than being buried inside scene scripts.

A new region should not require copying an entire screen script.

A new item should not require editing five unrelated UI files.

---

## 17. Dependency direction

Preferred dependency direction:

```text
presentation
    ↓
services/domain
    ↓
models/data/math
```

Avoid domain code importing:

- screen nodes;
- visual widgets;
- animation-specific classes;

unless the class is intentionally a presentation adapter rather than domain logic.

---

## 18. Signals and callbacks

Signals are suitable for:

- UI notification;
- presentation events;
- lifecycle notifications;
- decoupled scene communication.

Do not use a complex signal chain to hide critical domain mutation.

For important state changes, there should still be a traceable service call / state mutation path.

---

## 19. Refactoring rule

Refactor only as far as the task requires.

A normal feature task must not become:

```text
"rewrote 40 unrelated files because the architecture could be cleaner"
```

Broad refactors require:

- explicit scope;
- motivation;
- regression plan;
- reviewer approval;
- behavior-preservation tests.

---

## 20. No speculative architecture

Do not add:

- generic framework layers;
- factories;
- registries;
- dependency injection systems;
- event buses;
- abstraction interfaces;

only because they might be useful later.

Introduce abstraction when at least one current problem justifies it.

---

# PART V — GDSCRIPT RULES

## 21. Formatting

Project-owned GDScript is checked with:

**gdformat**

Formatting validation covers:

```text
godot/core
godot/scenes
godot/tests
godot/ui
```

Any changed GDScript must pass the current formatter checks.

Do not manually fight the formatter.

---

## 22. Linting

Project-owned GDScript is checked with:

**gdlint**

Development dependency baseline:

```text
gdtoolkit==4.5.0
```

Do not disable lint rules globally to hide new violations.

If a local exception is truly justified:

- keep it narrow;
- explain why;
- follow existing project conventions.

---

## 23. Type clarity

Prefer typed GDScript where the surrounding subsystem already uses typed code.

Avoid unnecessary Variant-heavy APIs.

Function contracts should make clear:

- accepted input;
- returned type;
- failure representation;
- state mutation.

---

## 24. Naming

Follow existing subsystem naming before inventing a new convention.

General preferences:

- descriptive names;
- stable IDs separate from display text;
- IDs in English/snake_case where the project already uses that convention;
- Polish player-facing display strings where appropriate;
- avoid encoding display names into logic.

Example:

```text
region_id = "ice_coast"
display_name = "Lodowe Wybrzeże"
```

Do not use translated display text as a save key.

---

## 25. Stable IDs

Persistent IDs must be treated as API-like contracts.

Do not rename an:

- item ID;
- region ID;
- quest ID;
- companion ID;
- dungeon ID;
- skill ID;
- Rift ID;
- save field;

only to make naming prettier.

If an ID must change:

- add migration/compatibility mapping;
- update tests;
- verify old save behavior.

---

## 26. Godot resource paths

Use `res://` paths consistently inside Godot.

Before changing or moving a referenced asset/resource:

- search all references;
- consider UID behavior;
- update scene/resource references;
- run headless project boot;
- run relevant tests.

Do not mass-move Godot assets without validation.

---

## 27. `.uid` files

The repository currently tracks Godot `.uid` files associated with scripts/resources.

Do not delete them casually as "generated junk".

If Godot legitimately regenerates UID data because of a controlled move/import:

- inspect the diff;
- verify references;
- include required UID changes.

---

## 28. `project.godot`

Prefer editing project settings through Godot when practical.

Direct text edits to `project.godot` require extra care because:

- settings may have non-obvious semantics;
- plugins and engine features are global;
- accidental changes affect every scene.

Any change to:

```text
godot/project.godot
```

must be explicitly called out in the developer report.

---

# PART VI — PYTHON LEGACY CODE

## 29. Legacy implementation status

Python remains important for:

- regression testing;
- terminal behavioral reference;
- migration comparison;
- old save understanding.

It is not the normal target for new graphical-game features.

Do not implement a feature twice in Python and Godot unless the task explicitly requires terminal parity work.

---

## 30. Python runtime dependencies

The historical game code uses the Python standard library for runtime.

Development/test dependencies currently include:

```text
pytest==9.1.1
gdtoolkit==4.5.0
```

Do not add Python runtime dependencies casually.

If a build/asset utility needs a third-party dependency:

- justify it;
- isolate it;
- pin it;
- update setup documentation;
- ensure it does not become a hidden game-runtime requirement.

---

# PART VII — TESTING

## 31. Canonical full validation command

The repository provides:

```powershell
.\scripts\check.ps1
```

This is the default **full validation command** for code changes when the local toolchain is available.

It currently performs several layers of validation.

---

## 32. Full validation stages

`check.ps1` currently validates:

1. golden-slice item assets;
2. golden-slice skill-card assets;
3. modular Varenhold assets;
4. GDScript formatting;
5. GDScript linting;
6. legacy Python pytest regression suite;
7. Godot bootstrap scene in headless mode;
8. GUT test suite.

An agent must not say:

```text
"all tests passed"
```

if it only ran one subset.

Reports must say exactly what was run.

---

## 33. GDScript formatter check

Full validation uses:

```text
gdformat --check
```

for project-owned GDScript locations.

Before final review, changed scripts should not leave formatting failures.

---

## 34. GDScript lint check

Full validation uses:

```text
gdlint
```

for project-owned GDScript locations.

Lint errors count as technical failures unless the existing baseline intentionally contains them and the task did not worsen them.

---

## 35. Python regression suite

Full validation executes:

```text
python -m pytest -q -p no:cacheprovider <repository root>
```

The legacy suite is still part of the quality gate.

If a Godot change breaks Python tests through shared data/docs/scripts:

- investigate;
- do not assume the Python suite is irrelevant.

---

## 36. Headless Godot bootstrap

The validation harness starts Godot headlessly with:

```text
--headless
--audio-driver Dummy
--rendering-method gl_compatibility
--quit-after 3
```

This catches:

- parser errors;
- missing resources;
- broken startup dependencies;
- project-load failures.

A successful editor open on one machine does not replace this check.

---

## 37. GUT

Godot tests are run with the GUT command-line entrypoint:

```text
res://addons/gut/gut_cmdln.gd
```

and include subdirectories under:

```text
res://tests
```

A domain mechanic change should add or update a GUT regression test where appropriate.

---

## 38. Targeted testing first, full suite before approval

Recommended development sequence:

```text
make change
↓
run closest targeted tests
↓
fix
↓
run subsystem tests
↓
run full check.ps1
↓
manual/visual smoke test if player-facing
↓
review
```

Do not repeatedly run the full suite after every single-line edit if a targeted test can shorten iteration.

Before final approval, however, broad gameplay/code changes should receive the full validation pass.

---

## 39. Tests must test behavior

Avoid tests that only assert:

- a file exists;
- a label contains hard-coded text;
- a function returned the value the test itself duplicated.

Prefer tests for:

- domain invariants;
- transaction atomicity;
- save migration;
- resource ownership;
- invalid actions;
- edge cases;
- deterministic anti-reroll behavior;
- progression gates.

---

## 40. Do not weaken tests to pass

Forbidden pattern:

```text
feature breaks test
→ agent deletes assertion
→ tests green
```

Changing an existing expected behavior requires:

- documented design change;
- explanation;
- reviewer acceptance.

---

## 41. Visual testing

For UI/presentation tasks, automated tests are necessary but insufficient.

Visual review should check:

- clipping;
- overlap;
- readability;
- scale;
- spacing;
- hover/focus;
- incorrect aspect behavior;
- placeholder leakage;
- broken asset positioning;
- 1920×1080;
- 1280×720.

When possible, provide before/after screenshots to the Reviewer.

---

# PART VIII — LOCAL TOOLCHAIN

## 42. Virtual environment

The repository validation script expects a local Windows environment:

```text
.venv\Scripts\python.exe
.venv\Scripts\gdformat.exe
.venv\Scripts\gdlint.exe
```

`.venv/` is local-only and ignored by Git.

Never commit the virtual environment.

---

## 43. Local Godot runtime

The current validation script expects downloaded Godot executables under:

```text
.tools\godot\
```

including:

```text
Godot_v4.7.1-stable_win64.exe
Godot_v4.7.1-stable_win64_console.exe
```

`.tools/` is local-only and ignored by Git.

Agents must not commit downloaded engine binaries.

---

## 44. Isolated validation runtime

`check.ps1` creates an isolated validation runtime under:

```text
build\validation-runtime\
```

and isolated profile/AppData locations.

This protects tests from some local Godot/user-state contamination.

`build/` is ignored and must not be committed.

---

## 45. Current Windows working-copy guidance

Primary working copy should remain outside cloud-synced folders such as OneDrive.

Recommended current location:

```text
C:\Projects\Echoes_of_Pythonia
```

Reason:

- Git writes many short-lived objects/locks;
- Godot imports many files;
- cloud sync can lock `.git` internals or generated files.

An AI agent must not move the repository back into OneDrive.

---

# PART IX — GIT SAFETY

## 46. Protected snapshot

Protected branch:

```text
snapshot/pre-ai-team-2026-09-10
```

Treat this branch as **read-only**.

AI agents must never:

- commit to it;
- rebase it;
- reset it;
- force-push it;
- delete it;
- merge experimental work into it.

Its purpose is disaster recovery.

---

## 47. AI working branch

Primary integration branch:

```text
ai/echoes-team
```

Normal AI work should happen:

- on this branch during initial controlled setup; or
- on short-lived task branches created from it once orchestration supports that safely.

The Reviewer must always know the base commit and changed files.

---

## 48. Never work directly on protected production branches

Unless the user explicitly changes policy, agents must not autonomously modify:

- snapshot branches;
- `main`;
- release branches;
- stable feature baselines.

Use an AI/task branch.

---

## 49. Destructive Git commands

Autonomous agents may not use destructive commands such as:

```text
git reset --hard
git clean -fd
git clean -fdx
git checkout -- .
git restore .
git branch -D
git push --force
git push --force-with-lease
```

unless the workflow gives explicit permission for a narrowly defined recovery operation.

If uncommitted user changes are detected:

**STOP.**

Do not clean them.

---

## 50. Before editing

Developer agent should record:

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Expected normal state:

- correct AI/task branch;
- no unexplained dirty files.

If unrelated changes already exist:

- do not absorb them into the task;
- report them;
- wait for orchestration policy / user decision.

---

## 51. Diff discipline

Before handing work to Reviewer, Developer must inspect:

```text
git status --short
git diff --stat
git diff
```

or the equivalent comparison for committed work.

The final diff should contain only files justified by the task.

Unexpected regenerated files require investigation.

---

## 52. Commit discipline

A commit should represent one coherent task/reviewed change.

Avoid commit messages such as:

```text
stuff
fix
changes
update
```

Prefer:

```text
fix(ui): repair equipment panel layout
feat(world): add modular region hover state
test(save): cover companion injury migration
```

Exact Conventional Commit syntax is not mandatory, but messages should be descriptive.

---

## 53. Commit only reviewed scope

Do not run blind:

```text
git add .
```

after an autonomous task without first inspecting the changed-file list.

Prefer staging known task files.

If many generated files are expected, verify them by category before staging.

---

## 54. Push policy

Developer should not push or merge automatically until the AI workflow explicitly permits it.

Recommended initial policy:

```text
Developer modifies
→ tests
→ Reviewer reviews
→ fixes
→ Reviewer APPROVED
→ commit
→ optional push
```

Detailed automation belongs in `AI_WORKFLOW.md`.

---

# PART X — LINE ENDINGS AND TEXT ENCODING

## 55. Canonical encoding

New text source/documentation should use:

**UTF-8**

Polish characters must remain intact.

Do not "fix" mojibake by deleting diacritics.

---

## 56. Canonical line endings

Repository `.gitattributes` currently enforces LF for:

```text
*.gd
*.godot
*.json
*.tres
*.tscn
```

Windows warnings about CRLF/LF should be understood before changing policy.

Do not change the global line-ending strategy in an unrelated task.

---

## 57. Avoid whole-file line-ending churn

A small feature must not produce a 2,000-line diff because every line ending changed.

If an unexpected whole-file diff appears:

- inspect encoding/EOL;
- restore correct EOL policy;
- preserve semantic diff.

---

# PART XI — IGNORE RULES AND GENERATED FILES

## 58. Never commit local caches

Current ignore policy includes:

```text
__pycache__/
.pytest_cache/
.mypy_cache/
.ruff_cache/
.venv/
venv/
env/
.coverage
htmlcov/
build/
dist/
.idea/
.vscode/
.godot/
.tools/
output/
```

Agents must respect these exclusions.

---

## 59. Secrets

Current ignore policy includes:

```text
.env
.env.*
```

with:

```text
!.env.example
```

Never commit:

- API keys;
- OpenAI keys;
- GitHub tokens;
- passwords;
- private service credentials;
- export credentials.

Godot export credentials are also local-only.

If a task requires a secret:

- read from environment/config;
- document variable name;
- never print the value into logs/reports.

---

## 60. Godot generated data

`.godot/` is ignored.

Do not stage Godot import caches.

Imported source assets belong in the repository where appropriate; generated editor cache does not.

---

## 61. Generated local output

`output/` is ignored.

Generated previews, diagnostics and scratch output should generally go there or another intentionally ignored workspace unless they are approved production assets.

---

## 62. Blender repair drafts

Current ignore policy excludes:

```text
art_drafts/pierrot_meshy_repair_04/
```

Do not re-add this folder through force-add.

It contains local/WIP Blender repair material that previously exceeded normal GitHub file limits.

---

# PART XII — LARGE FILES AND ASSETS

## 63. Large-file rule

Before staging a new binary asset, check its size.

Normal GitHub pushes reject individual files over approximately 100 MB.

Files above ~50 MB should receive deliberate review even when technically accepted.

AI agents must not discover large-file push failures only after building a huge commit.

---

## 64. Git LFS

Do not introduce Git LFS automatically.

If a final production asset genuinely needs LFS:

- propose it;
- identify file patterns;
- estimate repository impact;
- obtain explicit approval;
- configure it as a dedicated repository change.

Do not use LFS as a dumping ground for temporary drafts.

---

## 65. WORK vs FINAL

Asset workflow distinguishes:

- WORK — drafts / experiments;
- FINAL — approved production assets.

Developer agents must not promote a draft into production merely because it is the newest file.

Final integration requires:

- approved asset;
- correct path/name;
- manifest/tracker update where applicable;
- visual validation.

---

## 66. Asset replacement

When replacing a production asset:

- preserve intended dimensions/aspect when required;
- inspect import behavior;
- check all scenes using it;
- run asset validation;
- visually smoke-test screens using it.

Do not overwrite unrelated variants.

---

# PART XIII — SAVE SYSTEM SAFETY

## 67. Save compatibility is a first-class constraint

Persistent-data changes are high-risk.

Any change involving:

- player state;
- inventory;
- equipment;
- quests;
- Guild state;
- contracts;
- Black Market;
- companions;
- party;
- dungeon progression;
- Rift state;
- progression/talents;
- known regions;

must consider save compatibility.

---

## 68. Do not bump schema casually

A schema version bump is not cosmetic.

Before bumping:

1. identify new/changed persistent fields;
2. define migration from previous supported versions;
3. provide safe defaults;
4. validate invariants;
5. add migration tests;
6. ensure current saves still round-trip.

Do not bump schema because a transient UI field was added.

---

## 69. Transient state should stay transient

Do not serialize temporary battle/UI state merely because it is convenient.

Examples that are normally transient:

- hovered region;
- selected UI tab;
- current animation;
- combat popup;
- dice visual positions;
- temporary battle counter;
- modal visibility.

Persist only state that gameplay genuinely needs across sessions.

---

## 70. Safe default migration

When an older save lacks a newly supported field:

- choose a safe deterministic default;
- do not roll random new progression on every load;
- migrate once into the validated current representation.

---

## 71. Anti-reroll fields

Systems designed to prevent restart rerolls must preserve their state through saves.

Particularly sensitive:

- Daily/Weekly contracts;
- Black Market stock;
- bargaining result;
- recruitment candidates;
- recruitment attempt;
- Rift generation;
- persisted world milestones.

---

## 72. Terminal saves

Terminal save schema and Godot save schema are separate migration concerns.

Do not silently load a terminal save into the Godot model unless the dedicated migration path supports every required field.

A migration tool should prefer:

- read-only source;
- copied/migrated destination;
- migration report;
- explicit unsupported-field reporting.

Never destroy the original terminal save during import.

---

# PART XIV — TRANSACTIONS AND RESOURCE SAFETY

## 73. Atomic transactions

Economic/resource operations should be atomic.

Examples:

- crafting;
- purchasing;
- selling;
- upgrading;
- storage transfers;
- preset supply pulls.

Pattern:

```text
validate entire operation
→ compute complete result
→ mutate state once
```

Avoid:

```text
remove Gold
→ discover missing material
→ return failure
```

unless rollback is guaranteed and tested.

---

## 74. Exact instance ownership

Equipment instances can have:

- unique instance IDs;
- upgrades;
- affixes;
- ownership provenance.

Do not convert an exact equipment instance into a generic item stack.

Transfers must preserve instance data.

---

## 75. No resource duplication

Any code path that moves/consumes resources must be reviewed for duplication exploits.

Test at least:

- success;
- insufficient quantity;
- full capacity;
- repeated click/call;
- save/reload;
- partial-failure path where applicable.

---

# PART XV — RNG AND DETERMINISM

## 76. RNG ownership

Randomness must live in the domain system that owns the rule.

Do not generate gameplay RNG in:

- button callbacks;
- animation completion signals;
- rendering functions;
- tooltip functions.

---

## 77. Testable RNG

Where a mechanic is probabilistic, prefer a testable injection/source or deterministic seed mechanism consistent with the existing subsystem.

Tests should not become flaky.

---

## 78. Persist when rerolling would be exploitable

Generated state must be persisted when restart could otherwise reroll a meaningful outcome.

This includes market/candidate/Rift/contract systems defined by Game Design.

---

## 79. Python vs Godot random streams

Behavioral parity means preserving rules and deterministic expectations.

It does not require bit-for-bit identity with Python `random.Random` unless explicitly required.

Do not write fragile tests that accidentally enforce cross-language PRNG bit identity.

---

# PART XVI — ERROR HANDLING

## 80. Fail clearly

For invalid domain operations:

- return/raise a clear result according to subsystem convention;
- do not silently mutate half the state;
- do not hide errors behind UI messages only.

---

## 81. Player-facing vs developer-facing errors

Player-facing error:

```text
Brakuje wymaganych przedmiotów.
```

Developer-facing diagnostic may include:

```text
missing item_id=ancient_order_key expected=1
```

Do not expose internal file paths, stack traces or raw IDs to players unless it is a debug build/tool.

---

## 82. Parser/resource failures

Missing `res://` resources or parser errors are release-blocking technical failures.

An agent must not label a task complete while Godot bootstrap reports parser errors.

---

# PART XVII — PERFORMANCE AND SCENE SAFETY

## 83. Avoid premature optimization

Correctness and maintainability come before speculative micro-optimization.

Optimize after identifying:

- measurable frame cost;
- loading delay;
- memory issue;
- repeated expensive work.

---

## 84. Do not process static work every frame

Avoid putting expensive catalog lookups, file loading, layout reconstruction or resource creation in `_process()` unless it genuinely needs per-frame execution.

Use:

- initialization;
- cached data;
- signals;
- dirty-state refresh;
- events;

where appropriate.

---

## 85. Scene instancing

Prefer reusable components/scenes for repeated UI patterns.

Do not duplicate a 300-line screen structure for each region/class/shop if the difference is data.

---

## 86. Runtime asset loading

Use Godot resource loading conventions consistently.

Avoid arbitrary filesystem paths to developer machines.

Production runtime references must not point to:

```text
C:\Users\...
C:\Projects\...
OneDrive...
Desktop...
```

Use project resources or appropriate `user://` storage.

---

# PART XVIII — DOCUMENTATION

## 87. Documentation changes with behavior

If a task changes an established mechanic or technical contract, update the relevant documentation in the same reviewed task.

Possible files:

```text
AI_CONTEXT/
docs/
README.md
CHANGELOG.md
asset manifests
```

Do not update every document for every tiny internal refactor.

---

## 88. AI_CONTEXT is maintained documentation

When an explicit project decision changes:

- update the relevant AI_CONTEXT file;
- do not leave agents reading an obsolete rule.

The Reviewer should flag code/design changes that require a documentation update.

---

## 89. Changelog

Player-visible or milestone-level changes should update the project changelog according to the existing project convention.

Do not fill the changelog with trivial formatting changes.

---

# PART XIX — AGENT SAFETY BOUNDARIES

## 90. Developer agent permissions — normal

The Developer may normally:

- inspect repository files;
- search code;
- edit task-related source;
- add tests;
- run tests;
- run formatters;
- run linters;
- run Godot headlessly;
- launch local project for smoke testing when environment permits;
- create task-local documentation;
- inspect diffs.

---

## 91. Developer agent permissions — restricted

Without explicit workflow permission, the Developer must not:

- merge branches;
- force-push;
- delete branches;
- delete large unrelated directories;
- modify protected snapshot;
- rotate/revoke credentials;
- publish a release;
- upload builds publicly;
- change repository visibility;
- change billing;
- upgrade engine/toolchain globally;
- enable Git LFS;
- erase saves;
- overwrite user-created source art;
- mass-delete "unused" assets without proof.

---

## 92. No "cleanup everything" tasks inside feature work

If Developer notices unrelated debt:

- record it in the report;
- optionally propose a follow-up;
- do not fix it unless required for the assigned task.

This keeps reviews understandable.

---

## 93. File-deletion rule

Before deleting any tracked file, Developer must establish:

- what owns it;
- whether anything references it;
- whether it is generated or source;
- whether save/resource paths depend on it.

Deletion must appear explicitly in the change report.

---

## 94. Mass-change threshold

If an apparently small task unexpectedly changes many files, Developer should stop and explain why.

Recommended warning thresholds:

- >20 source files for a small UI/mechanic task;
- any unrelated domain;
- large binary churn;
- large generated UID/resource churn.

These are review triggers, not absolute bans.

---

# PART XX — REVIEWER TECHNICAL CHECKLIST

## 95. Reviewer must inspect more than tests

Reviewer checks:

- task scope;
- diff size;
- architecture ownership;
- duplicated logic;
- save impact;
- RNG impact;
- resource ownership;
- test adequacy;
- UI/domain separation;
- large files;
- generated files;
- suspicious deletions;
- unrelated changes;
- player-facing regression risk.

---

## 96. High-risk files

Changes in these areas deserve extra scrutiny:

```text
godot/project.godot
godot/core/save/
godot/core/combat/
godot/core/economy/
godot/core/companions/
godot/core/rifts/
godot/core/progression/
.gitattributes
.gitignore
requirements-dev.txt
plugin/addon configuration
```

This does not mean they are forbidden.

It means Reviewer should require strong justification and tests.

---

## 97. Reviewer rejection reasons

Reviewer should request changes when:

- tests were not run;
- "tests passed" is unsupported;
- unrelated files changed;
- UI duplicates domain logic;
- save migration is missing;
- persistent IDs changed without migration;
- binary files are unexpectedly huge;
- ignored/local files were force-added;
- formatter/lint failures remain;
- engine/plugin versions changed without task scope;
- behavior was altered only to satisfy a failing test;
- task works only at one resolution;
- source art was overwritten without approval.

---

# PART XXI — STANDARD VALIDATION REPORT

## 98. Developer completion report format

Developer should return a concise structured report:

```text
TASK
<assigned task>

BASE
<branch>
<base commit>

CHANGED
- file/path
- file/path

IMPLEMENTED
- concise behavior
- concise behavior

TESTS
PASS: <command>
PASS: <command>
NOT RUN: <command + reason>

VISUAL CHECK
PASS / NOT APPLICABLE / NOT RUN

SAVE IMPACT
NONE / MIGRATION REQUIRED / MIGRATION ADDED

RISKS
- remaining risk or NONE

DIFF
<X files changed, +A/-B>
```

Do not bury failures in prose.

---

## 99. Reviewer response format

Detailed workflow will be in `AI_WORKFLOW.md`, but technical review should contain:

```text
VERDICT
APPROVED
or
CHANGES_REQUESTED

BLOCKERS
- ...

IMPORTANT
- ...

OPTIONAL
- ...

TEST CONFIDENCE
- ...

SAVE / DATA RISK
- ...

SCOPE CHECK
- ...
```

Only genuine blockers should prevent approval.

---

# PART XXII — DEFINITION OF DONE

## 100. Code task

A code task is technically complete only when:

- assigned behavior is implemented;
- architecture ownership is correct;
- relevant tests exist/pass;
- formatter/linter pass where applicable;
- Godot parses/boots;
- save impact is handled;
- diff contains no unexplained files;
- Developer report is complete;
- Reviewer approves.

---

## 101. UI task

A UI task is technically complete only when:

- functionality still uses domain services;
- UI does not duplicate gameplay rules;
- scene opens without parser/resource errors;
- relevant automated tests pass;
- 1920×1080 is visually checked;
- 1280×720 remains usable;
- interaction/focus/hover is checked where relevant;
- Reviewer approves visual and technical result.

---

## 102. Asset integration task

An asset integration task is technically complete only when:

- source status is approved for integration;
- correct production path is used;
- no WIP/local-only files are accidentally added;
- file size is acceptable;
- manifest/tracker is updated when required;
- Godot import succeeds;
- dependent screens/scenes are checked;
- asset validation passes;
- Reviewer approves.

---

## 103. Persistent-system task

A persistent-system task is technically complete only when:

- state ownership is clear;
- save schema impact is assessed;
- migration/default behavior is defined;
- validation is defined;
- old save path is tested;
- current save round-trip works;
- reroll/exploit risk is checked;
- Reviewer approves.

---

# PART XXIII — CURRENT LOCAL COMMAND REFERENCE

## 104. Verify branch and workspace

```powershell
git branch --show-current
git status --short
git rev-parse HEAD
```

---

## 105. Inspect task diff

```powershell
git --no-pager diff --stat
git --no-pager diff
```

If comparing committed work:

```powershell
git diff <base>...HEAD
```

---

## 106. Full repository validation

From repository root:

```powershell
.\scripts\check.ps1
```

Do not claim this passed unless it completed successfully.

---

## 107. Godot project path

```text
C:\Projects\Echoes_of_Pythonia\godot\project.godot
```

The absolute path is local-machine guidance only.

Production code must use `res://` / `user://`, never this absolute path.

---

# PART XXIV — AUTOMATION READINESS

## 108. Agent execution should be bounded

The future orchestrator should give Developer:

- task scope;
- maximum review cycles;
- maximum allowed changed-file scope when appropriate;
- allowed branch;
- test expectations;
- stop conditions.

Autonomy must be bounded.

---

## 109. Stop conditions

Developer must stop rather than improvise when:

- branch is protected;
- repository has unexplained user changes;
- task conflicts with Project Bible;
- required source asset is missing;
- a save migration decision is ambiguous;
- a destructive operation appears necessary;
- engine/plugin upgrade becomes necessary unexpectedly;
- test baseline is already failing and cause is unknown;
- credentials are required but unavailable;
- work would require deleting/overwriting unapproved art;
- scope expands far beyond the task.

---

## 110. Reviewer cannot directly "approve its own fix"

If Reviewer finds a blocker:

- Reviewer reports it;
- Developer performs the fix;
- tests rerun;
- Reviewer reviews the new diff.

This separation is intentional.

---

## 111. No infinite review loop

If repeated attempts fail:

- stop after configured maximum rounds;
- preserve the branch and logs;
- summarize unresolved blockers;
- request human decision.

Do not keep spending tokens/computation indefinitely.

---

# PART XXV — FINAL TECHNICAL PRINCIPLE

## 112. Engineering goal

The technical goal is not to produce the most abstract or clever architecture.

The goal is to produce a game that is:

- correct;
- maintainable;
- testable;
- safe to iterate;
- resistant to save corruption;
- easy to review;
- visually extensible;
- friendly to future content;
- recoverable when an AI agent makes a mistake.

The best AI change is a **small, well-tested, well-explained change that fits the existing project**.

When in doubt:

**inspect first, change second, test third, review before integration.**
