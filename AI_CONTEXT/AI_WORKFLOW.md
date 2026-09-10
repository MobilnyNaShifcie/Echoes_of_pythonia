# Echoes of Pythonia — AI Workflow

> Role: operating contract for autonomous multi-agent development  
> Project: Echoes of Pythonia  
> Primary roles: Developer + Reviewer/Designer  
> Protected baseline: `snapshot/pre-ai-team-2026-09-10`  
> Integration branch: `ai/echoes-team`  
> Default maximum review cycles per task: 4  
> Default policy: no autonomous merge to `main`

---

# 1. Purpose

This document defines **how the AI development team works**.

It controls:

- how tasks are created;
- what the Developer receives;
- what the Reviewer receives;
- when code may be changed;
- how testing is performed;
- how review loops work;
- when an agent must stop;
- when a human decision is required;
- when a commit may be created;
- when a branch may be pushed or merged;
- how runaway loops and unnecessary cost are prevented;
- how creative decisions remain under owner control.

The intended team model is:

```text
OWNER / TASK SOURCE
        ↓
    ORCHESTRATOR
        ↓
     DEVELOPER
        ↓
 IMPLEMENTATION + TESTS
        ↓
      REVIEWER
        ↓
 ┌──────────────────────┐
 │ APPROVED?            │
 └───────┬──────────────┘
         │
   NO    │    YES
   ↓     │     ↓
DEVELOPER│   FINAL GATE
fixes    │     ↓
   ↑     │   COMMIT
   └─────┘     ↓
          OPTIONAL PUSH
               ↓
          NEXT TASK
```

The Developer and Reviewer are separate roles.

The Reviewer does not silently repair its own findings.

---

# 2. Core operating principle

The AI team should be autonomous for **ordinary implementation work**, but not autonomous for **irreversible product decisions**.

Default rule:

```text
AI may decide HOW to implement an approved task.
AI may not silently decide WHAT the game should become.
```

The owner retains control over:

- major creative direction;
- new canonical lore;
- new class/region identity;
- permanent balance philosophy changes;
- final art approval;
- purchases/licensing;
- destructive repository actions;
- releases;
- production branch policy.

---

# 3. Required context before every task

Every agent must read the relevant source-of-truth files.

Minimum required reading:

```text
AI_CONTEXT/PROJECT_BIBLE.md
AI_CONTEXT/GAME_DESIGN.md
AI_CONTEXT/TECHNICAL_RULES.md
AI_CONTEXT/UI_RULES.md
AI_CONTEXT/ART_DIRECTION.md
AI_CONTEXT/AI_WORKFLOW.md
```

The Developer should also inspect:

- the assigned subsystem;
- nearby tests;
- current project docs;
- current implementation.

The Reviewer must independently read the same project rules relevant to the task.

No agent may rely only on a task summary from another agent.

---

# 4. Agent roles

## 4.1 Developer

The Developer is responsible for:

- understanding the task;
- inspecting the repository;
- planning the smallest coherent implementation;
- editing task-related files;
- adding/updating tests;
- running targeted validation;
- running required final validation;
- producing screenshots when needed;
- reporting exact changes and risks;
- addressing Reviewer feedback.

The Developer is **not** responsible for final approval.

---

## 4.2 Reviewer / Designer

The Reviewer is responsible for independently evaluating:

- correctness;
- regressions;
- architecture;
- gameplay consistency;
- save compatibility;
- UI/UX;
- visual quality;
- scope discipline;
- test quality;
- hidden risk;
- compliance with AI_CONTEXT.

The Reviewer must be willing to reject work that compiles but violates project direction.

The Reviewer does not directly edit production files during the review phase.

---

## 4.3 Orchestrator

The Orchestrator is responsible for:

- creating task IDs;
- loading project context;
- checking branch/workspace state;
- handing the task to Developer;
- capturing changed files;
- capturing test results;
- handing the exact task and diff to Reviewer;
- returning review findings to Developer;
- limiting review cycles;
- enforcing stop conditions;
- creating an approved commit if policy allows;
- optionally pushing/merging according to configured policy;
- preserving logs.

The Orchestrator should be deterministic about workflow state.

It must not improvise around a failed safety check.

---

# 5. Default autonomy level

The initial recommended mode is:

**SAFE AUTONOMOUS DEVELOPMENT**

Meaning:

- Developer may edit task files automatically;
- Developer may run tests automatically;
- Reviewer may review automatically;
- Developer may perform Reviewer-requested fixes automatically;
- Orchestrator may create a commit after final approval;
- Orchestrator may push a task branch after final approval if configured;
- Orchestrator must not merge to `main`;
- Orchestrator must not publish a release;
- Orchestrator must stop for human decision on protected categories.

This gives meaningful autonomy without handing over irreversible project control.

---

# 6. Branch model

Protected disaster-recovery branch:

```text
snapshot/pre-ai-team-2026-09-10
```

Integration branch:

```text
ai/echoes-team
```

Recommended per-task branch pattern:

```text
ai/task/<task-id>-<short-name>
```

Example:

```text
ai/task/EOP-001-equipment-layout
ai/task/EOP-002-world-map-hover
ai/task/EOP-003-save-migration-fix
```

A task branch should normally start from the current approved `ai/echoes-team`.

---

# 7. Protected branches

The following are protected from autonomous direct work:

```text
snapshot/*
main
release/*
```

The AI team must not:

- force-push;
- reset;
- rewrite history;
- delete;
- directly commit;

to these branches unless an explicit human-controlled workflow later changes the policy.

The snapshot branch is permanently read-only.

---

# 8. Task ID

Every task receives a stable ID.

Format:

```text
EOP-001
EOP-002
EOP-003
...
```

The Orchestrator should persist the next task number outside the source tree or in a safe workflow state file.

Do not infer task identity from commit message alone.

---

# 9. Task specification

Every autonomous task must begin with a structured task specification.

Template:

```text
TASK_ID: EOP-001
TITLE: Repair equipment workspace proportions

OBJECTIVE:
Reduce wasted width in the backpack area and improve the equipment composition.

ACCEPTANCE_CRITERIA:
- inventory grid no longer sits inside excessive empty horizontal space
- paperdoll remains prominent
- 11 equipment slots remain functional
- drag/drop still works
- 1920×1080 passes visual review
- 1280×720 remains usable
- relevant automated tests pass

ALLOWED_SCOPE:
- godot/ui/screens/equipment/
- godot/ui/components/inventory_grid/
- directly related tests

FORBIDDEN_SCOPE:
- combat formulas
- save schema
- item balance

VISUAL_REVIEW_REQUIRED: yes
FULL_VALIDATION_REQUIRED: yes
OWNER_DECISION_REQUIRED: no
```

The task must be concrete enough for the Reviewer to judge completion.

---

# 10. Task source

A task may originate from:

- owner instruction;
- approved roadmap;
- approved bug report;
- Reviewer follow-up;
- automated test failure;
- predefined maintenance queue.

An autonomous agent must not turn a casual observation into a major redesign without a task.

---

# 11. Preflight — mandatory

Before any Developer edit, Orchestrator runs:

```text
git branch --show-current
git status --short
git rev-parse HEAD
```

Preflight must verify:

- repository exists;
- expected branch exists;
- working tree is clean or contains only known workflow files;
- current branch is not protected;
- base commit is recorded.

If unexplained changes exist:

```text
STOP
```

Do not stash, clean, reset or absorb them automatically.

---

# 12. Preflight project health

For tasks that depend on a healthy baseline, the Orchestrator may run:

- targeted baseline test;
- Godot bootstrap;
- relevant subsystem test.

If the baseline already fails before the task:

- record the failure;
- determine whether task is specifically about that failure;
- otherwise stop with `HUMAN_DECISION_REQUIRED` or create a dedicated baseline-fix task if policy explicitly permits.

Never attribute a pre-existing failure to the new change.

---

# 13. Context package for Developer

Developer receives:

- full task specification;
- base branch;
- base commit;
- AI_CONTEXT files;
- relevant code paths;
- relevant tests;
- current git status;
- any approved screenshot/reference;
- previous Reviewer feedback if this is a revision round.

Developer should not receive vague instructions such as:

```text
make it better
```

unless the task intentionally asks for design proposals rather than implementation.

---

# 14. Developer analysis phase

Before editing, Developer should identify:

```text
OWNER
Which subsystem owns this behavior?

FILES
Which files are likely relevant?

TESTS
Which tests protect the behavior?

PERSISTENCE
Does this touch save data?

UI
Does visual/manual review apply?

RISK
Could this affect another system?

PLAN
What is the smallest coherent implementation?
```

This plan may remain concise.

The Developer should not spend a large portion of the budget writing an essay before making a straightforward change.

---

# 15. Developer implementation rule

Developer may modify only what is necessary to meet the task acceptance criteria.

If implementation unexpectedly requires a major scope expansion:

```text
STOP_EXPANSION
```

and report why.

Do not quietly turn one screen fix into an application-wide rewrite.

---

# 16. Existing architecture first

Developer must search for existing:

- services;
- catalogs;
- components;
- utilities;
- tests;
- presentation helpers;

before adding new ones.

New architecture requires a demonstrated current need.

---

# 17. No silent design changes

If Developer discovers that satisfying the task would require changing an approved gameplay/design rule:

```text
HUMAN_DECISION_REQUIRED
```

Examples:

- change class unlock level;
- remove permanent specialization;
- change Black Market rotation philosophy;
- change companion death rule;
- rename a region;
- redesign Region 6 canon;
- change a boss identity.

Developer may propose options, but must not choose canonical direction alone.

---

# 18. Targeted tests during development

Developer should first run the smallest useful test set.

Examples:

```text
relevant GUT test file
relevant pytest module
asset checker
specific Godot scene bootstrap
formatter/linter for changed area
```

This shortens iteration time.

The Developer should fix targeted failures before asking for final review.

---

# 19. Formatting and linting

Changed project-owned GDScript must comply with current:

- gdformat;
- gdlint;

rules.

Do not suppress warnings globally.

---

# 20. Full validation gate

The canonical full validation command is:

```powershell
.\scripts\check.ps1
```

When required by the task, this must complete successfully before final approval.

The script currently checks:

- item assets;
- skill-card assets;
- modular Varenhold assets;
- GDScript formatting;
- GDScript linting;
- legacy Python regression tests;
- headless Godot bootstrap;
- GUT suite.

A report must distinguish:

```text
TARGETED TESTS PASSED
```

from:

```text
FULL VALIDATION PASSED
```

---

# 21. When full validation may be skipped

Full validation may be skipped before first review only for:

- documentation-only task;
- concept-only task;
- very narrow asset preview outside production;
- intermediate fix round where targeted tests are sufficient.

Before final integration of code/gameplay/UI production changes, full validation is normally required.

If not run:

- state `NOT RUN`;
- state why.

Reviewer decides whether this blocks approval.

---

# 22. Manual/visual smoke test

Required for player-facing visual changes.

Developer should validate the affected flow in Godot.

At minimum where applicable:

- open screen;
- primary action;
- Back;
- disabled state;
- selection;
- hover;
- 1920×1080;
- 1280×720.

For substantial UI tasks, screenshots should be captured.

---

# 23. Screenshot package

Preferred screenshot set:

```text
before_1920x1080.png
after_1920x1080.png
after_1280x720.png
hover_or_selected.png
blocked_or_warning.png
```

Only capture relevant states.

Do not generate 50 screenshots for a minor change.

Workflow screenshots should be stored in an ignored run-output area, for example:

```text
output/ai-team/<task-id>/
```

unless they are explicitly approved as project documentation.

---

# 24. Developer handoff package

Before Reviewer receives the task, Developer must provide:

```text
TASK_ID
BASE_COMMIT
CURRENT_COMMIT_OR_WORKTREE
CHANGED_FILES
DIFF_STAT
IMPLEMENTED
TARGETED_TESTS
FULL_VALIDATION
VISUAL_CHECK
SAVE_IMPACT
RISKS
SCREENSHOTS
```

The Orchestrator should provide the actual diff independently.

Do not trust only the Developer's summary.

---

# 25. Reviewer independence

Reviewer receives:

- original task;
- acceptance criteria;
- AI_CONTEXT;
- base commit;
- actual changed-file list;
- actual diff;
- actual test outputs/status;
- screenshots;
- Developer summary.

Reviewer should review the **artifact**, not the Developer's confidence.

---

# 26. Reviewer first-pass behavior

Reviewer should first ask:

```text
Did the task actually get solved?
```

Then:

```text
Did solving it break anything?
```

Then:

```text
Does it fit Echoes of Pythonia?
```

Then:

```text
Is the implementation maintainable?
```

Do not begin with micro-style preferences.

---

# 27. Review severity

Findings use three normal severities.

## BLOCKER

Must be fixed before approval.

Examples:

- feature does not work;
- parser error;
- save corruption risk;
- duplicated resources;
- critical regression;
- broken 1280×720 layout;
- wrong gameplay rule;
- unsafe Git behavior;
- missing required migration;
- test failure;
- unapproved production art.

## IMPORTANT

Should normally be fixed before approval unless Reviewer explicitly allows follow-up.

Examples:

- substantial UX issue;
- poor architecture;
- misleading UI;
- missing edge case;
- inadequate test coverage.

## OPTIONAL

Polish that does not block task acceptance.

Examples:

- minor spacing;
- naming cleanup;
- small animation refinement;
- follow-up refactor.

Reviewer must not inflate every preference into a blocker.

---

# 28. Reviewer verdicts

Reviewer must end with exactly one verdict:

```text
VERDICT: APPROVED
```

or:

```text
VERDICT: CHANGES_REQUESTED
```

or:

```text
VERDICT: HUMAN_DECISION_REQUIRED
```

The Orchestrator should parse only these exact verdict markers.

---

# 29. APPROVED

Reviewer may return APPROVED only when:

- acceptance criteria are met;
- no blockers remain;
- required tests are credible;
- scope is clean;
- save risk is handled;
- required visual review passes;
- no protected design rule was changed silently.

Optional suggestions may remain.

---

# 30. CHANGES_REQUESTED

Use when the work is fixable inside approved task scope.

Reviewer returns:

```text
BLOCKERS
1. ...
2. ...

IMPORTANT
1. ...

OPTIONAL
1. ...
```

Developer receives only actionable findings plus enough context to reproduce them.

---

# 31. HUMAN_DECISION_REQUIRED

Use when resolution requires owner judgment.

Examples:

- two valid design directions;
- new canonical lore;
- major balance change;
- art approval;
- paid asset/license decision;
- removing a feature;
- schema break with unavoidable loss;
- task conflicts with Project Bible;
- destructive cleanup;
- release/merge-to-main decision.

The autonomous loop stops.

---

# 32. Fix round

On `CHANGES_REQUESTED`:

```text
round += 1
```

Developer must:

- address blockers;
- address important findings unless explicitly deferred;
- avoid unrelated improvements;
- rerun affected tests;
- update screenshots if visual result changed;
- provide a new handoff.

Reviewer then reviews the new diff/state.

---

# 33. Maximum review cycles

Default:

**4 review cycles**

Meaning:

```text
Developer attempt
→ Review 1
→ Fix
→ Review 2
→ Fix
→ Review 3
→ Fix
→ Review 4
```

If still not approved:

```text
STOP
VERDICT: HUMAN_DECISION_REQUIRED
```

Do not continue indefinitely.

---

# 34. Repeated blocker rule

If the same blocker reappears in two consecutive review rounds, the Orchestrator should flag:

```text
REPEATED_BLOCKER
```

Developer should reconsider the approach rather than patching the same symptom again.

If the third attempt still fails, stop early and request human decision.

---

# 35. Reviewer cannot modify code

During normal review:

Reviewer is read-only.

If Reviewer notices an obvious one-line fix, it still returns the finding.

Developer performs the fix.

This preserves role separation and makes the audit trail clear.

---

# 36. Reviewer may run verification

Reviewer may independently run:

- tests;
- static checks;
- diff inspection;
- screenshot inspection;
- project bootstrap;
- targeted reproduction.

Reviewer should not rely on Developer's test report when verification is cheap and available.

---

# 37. Final validation after last fix

When Reviewer is close to approval, the final Developer state should receive the required full validation.

Do not rely on a full test run from two fix rounds ago if code changed afterward.

---

# 38. Final approval package

Before commit, Orchestrator records:

```text
task ID
base commit
final changed files
final diff stat
final test result
reviewer verdict
review round count
save impact
visual review status
```

This becomes the task audit record.

---

# 39. Commit gate

A commit may be created automatically only after:

```text
VERDICT: APPROVED
```

and all required checks are satisfied.

No "almost approved" commit.

---

# 40. Commit message

Recommended pattern:

```text
<type>(<scope>): <short task result> [EOP-###]
```

Examples:

```text
fix(ui): repair equipment workspace proportions [EOP-001]
feat(world): improve region hover presentation [EOP-002]
test(save): cover companion injury migration [EOP-003]
```

The task ID must appear in the commit message.

---

# 41. Commit body

For larger tasks, commit body may summarize:

```text
- primary implementation
- tests
- migration note
```

Do not paste entire Reviewer discussion into the commit message.

---

# 42. Push policy

Initial recommended policy:

**Auto-push approved task branches: allowed when configured.**

The task branch may be pushed after approval.

The Orchestrator must not push:

- secrets;
- ignored local artifacts;
- large unexpected binaries;
- failed work.

---

# 43. Integration into `ai/echoes-team`

Recommended autonomous integration policy after the workflow is proven stable:

Auto-merge/rebase task branch into:

```text
ai/echoes-team
```

only when:

- Reviewer approved;
- full required validation passed;
- branch has no unexpected divergence;
- no human-decision flag;
- no protected-category change.

During initial setup, keep this configurable and conservative.

---

# 44. `main` policy

Default:

```text
NO AUTONOMOUS MERGE TO MAIN
```

Moving approved AI work from `ai/echoes-team` to `main` remains a human-controlled release/integration decision unless policy is explicitly changed later.

---

# 45. Release policy

AI team may prepare:

- release notes;
- build checklist;
- version proposal;
- export validation.

AI team may not autonomously:

- publish Steam build;
- publish GitHub Release;
- change store metadata;
- upload paid production release;
- sign commercial agreement.

---

# 46. Logs

Each task should have a run directory outside tracked production files:

```text
output/ai-team/EOP-001/
```

Suggested files:

```text
task.txt
preflight.txt
developer_round_1.md
tests_round_1.txt
review_round_1.md
developer_round_2.md
tests_round_2.txt
review_round_2.md
final_summary.md
```

`output/` is ignored by Git.

Do not pollute the source tree with transient agent logs.

---

# 47. Machine-readable state

The Orchestrator should maintain a task state such as:

```json
{
  "task_id": "EOP-001",
  "state": "REVIEW",
  "round": 2,
  "base_commit": "abc123",
  "branch": "ai/task/EOP-001-equipment-layout",
  "developer_status": "COMPLETE",
  "reviewer_verdict": "CHANGES_REQUESTED",
  "full_validation": "NOT_RUN"
}
```

This runtime state should normally live in ignored output/workflow storage.

Do not make the game depend on it.

---

# 48. Workflow states

Recommended finite-state machine:

```text
CREATED
↓
PREFLIGHT
↓
DEVELOPING
↓
TESTING
↓
READY_FOR_REVIEW
↓
REVIEWING
↓
┌─────────────────────────────┐
│ APPROVED                    │
│ CHANGES_REQUESTED           │
│ HUMAN_DECISION_REQUIRED     │
└─────────────────────────────┘
```

Transitions:

```text
APPROVED
→ FINAL_VALIDATION
→ COMMIT
→ PUSH(optional)
→ DONE

CHANGES_REQUESTED
→ DEVELOPING
→ TESTING
→ READY_FOR_REVIEW

HUMAN_DECISION_REQUIRED
→ PAUSED
```

A task should not jump from CREATED directly to COMMIT.

---

# 49. Developer status markers

Developer response should end with one exact marker:

```text
DEVELOPER_STATUS: READY_FOR_REVIEW
```

or:

```text
DEVELOPER_STATUS: BLOCKED
```

or:

```text
DEVELOPER_STATUS: HUMAN_DECISION_REQUIRED
```

The Orchestrator should parse these exact markers.

---

# 50. Developer report template

Use:

```text
TASK
EOP-###

BASE
branch:
commit:

CHANGED
- path
- path

IMPLEMENTED
- ...

TESTS
PASS: ...
FAIL: ...
NOT RUN: ...

VISUAL CHECK
PASS / NOT APPLICABLE / NOT RUN

SAVE IMPACT
NONE / MIGRATION ADDED / HUMAN DECISION REQUIRED

RISKS
- NONE
or
- ...

DIFF
X files changed, +A/-B

DEVELOPER_STATUS: READY_FOR_REVIEW
```

---

# 51. Reviewer report template

Use:

```text
TASK
EOP-###

SCOPE CHECK
PASS / FAIL

BLOCKERS
- NONE
or
1. ...

IMPORTANT
- NONE
or
1. ...

OPTIONAL
- NONE
or
1. ...

TEST CONFIDENCE
- ...

SAVE / DATA RISK
- ...

VISUAL REVIEW
PASS / NOT APPLICABLE / FAIL / NOT RUN

SUMMARY
- ...

VERDICT: APPROVED
```

The verdict line must be last.

---

# 52. Do not hide failures

Forbidden:

```text
Everything is good, but 12 tests fail because they are probably unrelated.
VERDICT: APPROVED
```

If failures are unexplained:

- investigate;
- or stop.

---

# 53. Baseline failure handling

If a test failed before Developer changes and remains unchanged:

Reviewer may distinguish:

```text
PRE_EXISTING_FAILURE
```

from:

```text
NEW_FAILURE
```

But a pre-existing critical failure may still make safe approval impossible.

Do not silently ignore it.

---

# 54. Save-system tasks

Any task touching persistent state receives mandatory extra review.

Developer must state:

- current schema;
- schema changed? yes/no;
- migration path;
- older supported save behavior;
- round-trip result;
- anti-reroll impact.

Reviewer should treat missing save reasoning as a blocker for persistent changes.

---

# 55. RNG tasks

For random systems Developer must state:

- RNG owner;
- whether result must persist;
- deterministic test strategy;
- restart-reroll risk.

Reviewer should reject UI-owned gameplay RNG.

---

# 56. Economy tasks

For economy/resource tasks test:

- success;
- insufficient Gold/materials;
- quantity edge;
- atomic failure;
- duplicate-click/repeat behavior;
- save/reload where persistent.

No resource-duplication risk may remain unexplained.

---

# 57. UI tasks

A meaningful UI task requires:

- current scene inspection;
- current script inspection;
- relevant reusable components;
- screenshot/manual visual test;
- 1920×1080;
- 1280×720.

Reviewer must use `UI_RULES.md`.

---

# 58. Art tasks

Art has a separate approval gate.

AI may:

- generate concepts;
- prepare previews;
- evaluate technical quality;
- suggest improvements;
- prepare production extraction;
- validate alpha/dimensions.

AI may not mark a new creative asset as final production-approved without owner approval.

Reviewer verdict for new creative art should normally be:

```text
APPROVED_FOR_OWNER_REVIEW
```

This is not equivalent to gameplay/code `VERDICT: APPROVED`.

---

# 59. Approved-art integration tasks

Once owner approval exists, the AI team may autonomously:

- prepare alpha;
- rename;
- place into production path;
- update presentation catalog;
- update manifest;
- run asset checks;
- run visual smoke tests;

within the approved design.

Reviewer then evaluates integration, not the creative choice itself.

---

# 60. Third-party/paid asset task

Immediate human gate if any task requires:

- purchase;
- subscription;
- license acceptance;
- paid download;
- unclear commercial rights;
- attribution/legal interpretation beyond existing documented license.

The AI may research and present options.

It must not spend money.

---

# 61. Major game-design task

Examples:

- Region 6 identity;
- new class;
- new permanent progression system;
- major combat rework;
- economy philosophy change;
- changing permanent companion death;
- changing primary art style.

Workflow:

```text
AI proposes options
→ owner selects
→ decision enters AI_CONTEXT
→ implementation task begins
```

Do not let Developer + Reviewer create new canon by agreement between themselves.

---

# 62. Bug-fix task

Ordinary bug fixes can be highly autonomous.

Required:

- reproduce or establish failing behavior;
- add regression test where practical;
- fix smallest owner;
- targeted tests;
- full validation when appropriate;
- Reviewer approval.

No owner intervention needed unless the bug exposes an ambiguous intended behavior.

---

# 63. Refactor task

A refactor must define preserved behavior.

Required acceptance criteria should include:

```text
behavior unchanged
tests pass
save compatibility unchanged
diff scope justified
```

Reviewer should reject feature creep inside refactor.

---

# 64. Documentation task

Documentation-only work may skip game runtime validation when no code/data behavior changed.

Still check:

- links/paths;
- terminology;
- encoding;
- current source consistency.

---

# 65. Dependency/toolchain task

Any dependency or engine upgrade requires a dedicated task.

Required:

- reason;
- old/new version;
- compatibility notes;
- full validation;
- launch test;
- rollback plan.

No automatic dependency upgrade bots should merge directly into production branches.

---

# 66. Large-file task

Before staging new binary assets:

- inspect file size;
- inspect path;
- verify approval;
- check GitHub limits;
- verify ignore/LFS policy.

Unexpected file >50 MB:

```text
REVIEW_REQUIRED
```

File near/over normal GitHub 100 MB limit:

```text
STOP
```

unless an explicitly approved storage strategy exists.

---

# 67. Untracked-file safety

If preflight sees unknown untracked files:

Developer must not automatically delete them.

Classify:

- task file;
- generated file;
- user file;
- unknown.

Unknown:

```text
STOP
```

---

# 68. Dirty-worktree safety

If another process/user has modified tracked files:

Do not:

- stash automatically;
- reset;
- overwrite;
- include them in the task.

Pause and report.

---

# 69. One task at a time per working copy

Initial orchestration should run only one writing Developer task per working copy.

Do not allow two Developer agents to edit the same checkout simultaneously.

Future parallelism should use:

- separate worktrees;
- separate task branches;
- isolated build/output directories.

---

# 70. Parallel review is safe

Reviewer may inspect a frozen diff in parallel with non-writing analysis.

But no new Developer mutation should occur while Reviewer is reviewing that exact state unless the review is cancelled and restarted.

---

# 71. Worktree strategy for future parallel tasks

Future advanced orchestration may use:

```text
C:\Projects\Echoes_AI_Worktrees\EOP-001
C:\Projects\Echoes_AI_Worktrees\EOP-002
```

Each with:

- separate task branch;
- separate working tree;
- separate output;
- controlled integration.

Do not implement parallel work until the single-task pipeline is stable.

---

# 72. Cost control

The Orchestrator must enforce finite resource limits.

At minimum:

- max 4 review rounds;
- max 1 active writing task per checkout;
- targeted tests before repeated full tests;
- stop on repeated blocker;
- stop on ambiguous design gate.

Recommended configurable limits:

```text
MAX_REVIEW_ROUNDS = 4
MAX_REPEATED_BLOCKER = 2
MAX_UNEXPECTED_SCOPE_FILES = 20 for small tasks
```

The exact API token/currency budget should be set in runtime configuration, not hardcoded into game source.

---

# 73. Context efficiency

Do not send the entire repository to both agents every round.

Prefer:

- AI_CONTEXT;
- task spec;
- relevant files;
- changed diff;
- relevant tests;
- error logs;
- screenshots.

Reviewer should request more repository context only when necessary.

---

# 74. Long diff handling

If the diff is too large for reliable review:

- split the task;
- or review by subsystem in a controlled sequence.

Do not summarize a massive diff into "looks fine".

---

# 75. Scope warning threshold

For a small task, if changed source-file count exceeds roughly:

**20 files**

the Orchestrator should ask Developer to justify scope before review.

This is a warning threshold, not a universal hard cap.

Expected large asset/data migrations may exceed it.

---

# 76. Automatic task splitting

The Orchestrator may propose splitting when one task contains independent goals.

Example:

```text
redesign equipment UI
+ rebalance affixes
+ add controller support
+ change save schema
```

should probably become separate tasks.

The Orchestrator must not split in a way that changes owner intent.

---

# 77. Recovery after failed task

If a task becomes broken:

- keep task branch;
- keep logs;
- do not reset integration branch;
- mark task `FAILED` or `PAUSED`;
- start a clean replacement task branch if needed.

The protected snapshot remains untouched.

---

# 78. Rollback after approved integration

If an approved task later proves harmful:

- create a dedicated revert/fix task;
- use Git history;
- do not rewrite protected history.

Rollback should itself receive validation.

---

# 79. Never use the snapshot as scratch space

The snapshot is not:

- fallback working branch;
- staging area;
- place to "quickly test one fix".

Read only.

---

# 80. Owner interruption

The owner may interrupt any autonomous task.

The Orchestrator should support:

```text
PAUSE
CANCEL
RESUME
```

Cancel should stop future edits but preserve:

- current branch;
- diff;
- logs.

Do not automatically discard work on cancel.

---

# 81. Pause behavior

On PAUSE:

- stop new agent calls;
- stop future mutations;
- allow currently running safe command to finish if interruption would corrupt state;
- save task state;
- record last known commit/diff.

---

# 82. Cancel behavior

On CANCEL:

- mark task cancelled;
- preserve branch;
- preserve logs;
- do not merge;
- do not delete;
- do not reset.

Cleanup may be a later explicit operation.

---

# 83. Resume behavior

On RESUME:

- rerun preflight;
- confirm branch/commit/diff matches saved state;
- if changed externally, stop;
- otherwise continue from saved workflow state.

---

# 84. Human decision response

When stopping for owner input, return a concise decision packet:

```text
TASK
EOP-###

WHY STOPPED
<one paragraph>

OPTIONS
A. ...
B. ...
C. ...

RECOMMENDATION
<one option + reason>

IMPACT
- save:
- gameplay:
- UI/art:
- cost:
```

Do not dump raw internal logs unless requested.

---

# 85. Decision recording

After owner chooses:

- record the decision in the appropriate AI_CONTEXT file if it changes project canon/policy;
- update task acceptance criteria;
- resume.

Do not rely only on ephemeral chat history for permanent design decisions.

---

# 86. AI_CONTEXT change policy

Agents may update AI_CONTEXT when:

- owner made a new explicit decision;
- implementation reveals a current canonical fact that the docs clearly misstated;
- workflow policy changes.

The Reviewer must inspect AI_CONTEXT changes carefully.

An agent must not modify Project Bible merely to justify its own implementation.

---

# 87. Conflicting documentation

If the repository and AI_CONTEXT conflict:

- identify exact conflict;
- determine source priority;
- do not silently rewrite both;
- request human decision if neither is clearly authoritative.

---

# 88. Reviewer bias control

Reviewer should not automatically accept because:

- Developer used sophisticated language;
- many tests were added;
- diff is large;
- implementation is elegant.

Review the actual behavior and project fit.

---

# 89. Developer bias control

Developer should not optimize for:

```text
getting APPROVED
```

by:

- hiding changes;
- weakening tests;
- minimizing reported risk;
- skipping screenshots;
- rewriting docs after the fact.

The goal is correct project work.

---

# 90. No agent self-congratulation in logs

Reports should be factual.

Avoid:

```text
This is an amazing, production-ready implementation.
```

Prefer:

```text
Implemented X. Full validation passed. Visual check passed at 1920×1080 and 1280×720.
```

---

# 91. Security

Agents must never print or commit:

- API keys;
- GitHub tokens;
- passwords;
- secret environment values;
- private license credentials.

If a secret is required and unavailable:

```text
DEVELOPER_STATUS: BLOCKED
```

Do not invent credentials.

---

# 92. External network actions

Ordinary repository development may require:

- Git fetch/push;
- dependency download;
- documentation lookup.

But autonomous agents must not:

- post public announcements;
- contact third parties;
- purchase assets;
- create store listings;
- upload releases;

unless explicitly configured and approved.

---

# 93. Tool download policy

If a missing local tool is required:

Developer may identify it.

Default initial behavior:

- do not install system-wide software automatically;
- do not change PATH globally;
- do not accept licenses silently.

Project-local tooling may later be automated if installation source/version is pinned and approved.

---

# 94. Godot launch

Developer may launch Godot for:

- smoke test;
- screenshot capture;
- scene verification.

Do not keep uncontrolled GUI automation running indefinitely.

Use deterministic scripted/headless checks where possible.

---

# 95. Computer-use testing

If future Developer uses computer control:

- operate only inside task-relevant applications;
- avoid unrelated personal files/apps;
- capture only task-relevant screenshots;
- do not alter system settings unless task requires it;
- stop if a destructive/privileged prompt appears unexpectedly.

---

# 96. Visual AI review

Reviewer may evaluate screenshots for:

- clipping;
- composition;
- layout;
- hierarchy;
- asset fit;
- wrong orientation;
- obvious visual bugs.

Reviewer should not claim pixel-perfect verification if screenshot resolution or state is insufficient.

---

# 97. Screenshot mismatch

If the provided screenshot does not clearly prove the acceptance criterion:

Reviewer requests a better screenshot/state.

Do not approve based on assumption.

---

# 98. UI interaction evidence

For interaction-heavy tasks, static screenshot alone may be insufficient.

Developer may provide:

- short capture;
- sequence of screenshots;
- test output;
- interaction notes.

Reviewer chooses the lightest evidence necessary.

---

# 99. Art approval vs technical approval

Two different approvals exist.

## Creative approval
Owner says the art/design is accepted.

## Technical approval
Reviewer confirms:

- alpha;
- scale;
- path;
- integration;
- manifest;
- performance;
- no gameplay impact.

A technically perfect asset without creative approval is not production-approved.

---

# 100. Gameplay proposal mode

When the owner asks for ideas rather than implementation, use:

```text
MODE: PROPOSAL
```

In proposal mode:

- Developer does not edit code;
- Reviewer may compare alternatives;
- no commit;
- no branch mutation;
- result is options for owner.

---

# 101. Implementation mode

Normal approved task uses:

```text
MODE: IMPLEMENTATION
```

Full workflow applies.

---

# 102. Audit mode

For broad inspection use:

```text
MODE: AUDIT
```

In audit mode:

- no source mutation unless separately authorized;
- agents may inspect;
- run tests;
- produce issue list;
- prioritize findings.

Do not fix every finding during the audit itself.

---

# 103. Playtest-fix mode

For owner-reported bugs after playtest:

```text
MODE: PLAYTEST_FIX
```

Input may include:

- screenshot;
- user description;
- reproduction steps.

Developer should:

- reproduce;
- locate owner;
- fix;
- test;
- Reviewer validates.

---

# 104. Batch asset mode

For many approved repetitive asset integrations:

```text
MODE: ASSET_BATCH
```

Use only after a golden slice is proven.

Batch must still:

- validate each file;
- update manifest;
- preserve mapping;
- stop on first structural anomaly rather than propagate it to all assets.

---

# 105. Batch data mode

For large content catalogs:

- validate IDs;
- validate duplicates;
- validate references;
- use automated checks;
- sample-review output.

Do not manually trust 100 generated entries.

---

# 106. Scheduled autonomous work

Future orchestration may run queued tasks without owner present.

Only tasks already marked:

```text
OWNER_DECISION_REQUIRED: no
```

may start automatically.

A queued task that encounters a human gate pauses itself.

---

# 107. Task queue priority

Suggested priority classes:

```text
P0 — project broken / data loss / blocking regression
P1 — major gameplay/UI blocker
P2 — normal feature / important polish
P3 — cleanup / optional polish
```

The AI team should not spend hours polishing P3 while a P0 exists.

---

# 108. Dependency between tasks

A task may declare:

```text
DEPENDS_ON: EOP-014
```

Orchestrator must not start it until dependency is approved/integrated.

---

# 109. Mutually exclusive tasks

If two queued tasks edit the same core subsystem heavily:

- serialize them;
- or use separate branches and review integration conflicts carefully.

Do not let autonomous agents race on the same files.

---

# 110. Conflict handling

On Git conflict:

```text
STOP AUTOMATIC MERGE
```

unless conflict is trivial and policy explicitly allows controlled resolution.

Developer may propose a resolution.

Reviewer checks the merged result.

Never resolve conflict by choosing "ours" or "theirs" globally.

---

# 111. Post-merge validation

After integration into `ai/echoes-team`, run an integration validation when:

- multiple task branches changed related areas;
- merge had conflict;
- persistent systems changed;
- project-wide shared component changed.

Individual branch passes do not always guarantee integration pass.

---

# 112. Integration regression task

If integration validation fails:

- do not merge to protected production branch;
- create a dedicated integration-fix task;
- preserve original approved commits.

---

# 113. Review quality over speed

The Reviewer should spend effort proportionally to risk.

Low-risk:

- typo;
- docs;
- simple spacing.

High-risk:

- saves;
- combat;
- economy;
- companion death;
- inventory ownership;
- RNG persistence;
- plugin/engine configuration.

Do not use identical review depth for all tasks.

---

# 114. High-risk automatic escalation

Automatically require stricter review for changes touching:

```text
godot/core/save/
godot/core/combat/
godot/core/economy/
godot/core/companions/
godot/core/rifts/
godot/core/progression/
godot/project.godot
.gitattributes
.gitignore
requirements-dev.txt
```

Stricter review means:

- targeted tests;
- full validation;
- explicit risk section;
- save/data statement where relevant.

---

# 115. Main AI team success criterion

The system is successful when the owner can provide a clear goal such as:

```text
"Popraw ekran ekwipunku, bo plecak jest za szeroki i chcę większą postać."
```

and the workflow can autonomously produce:

```text
task
→ branch
→ implementation
→ tests
→ screenshots
→ review
→ fixes
→ approval
→ commit
```

without requiring the owner to relay every message between agents.

---

# 116. What autonomy must not become

Autonomy must not become:

- endless self-directed feature creation;
- rewriting the game overnight;
- uncontrolled API spending;
- silent canon changes;
- replacing owner art;
- changing balance because "it seems better";
- merging directly to release;
- hiding failures.

The AI team is an accelerator and quality loop, not the project owner.

---

# 117. Initial rollout plan

Do not switch immediately from manual development to full autonomy.

Recommended rollout:

## Phase A — Dry run
- Orchestrator passes task to Developer.
- Developer proposes plan/diff but commit is manual.
- Reviewer reviews.
- Owner observes logs.

## Phase B — Safe write
- Developer edits automatically.
- Reviewer loops automatically.
- Orchestrator commits approved work.
- No automatic push/merge.

## Phase C — Safe branch automation
- approved task branch may auto-push;
- approved low/medium-risk work may integrate into `ai/echoes-team`;
- no `main` merge.

## Phase D — Mature workflow
- queued tasks;
- isolated worktrees;
- automated screenshots;
- integration validation;
- owner only sees decisions, blockers and completed summaries.

Advance only after several successful tasks.

---

# 118. First test task

The first orchestrated task should be:

- small;
- reversible;
- visual or low-risk;
- easy to verify;
- covered by existing structure.

Good examples:

- spacing/layout improvement on one UI screen;
- hover-state polish;
- clearer disabled-state message;
- small asset-placement correction.

Avoid using the first autonomous run for:

- save-schema migration;
- combat-engine rewrite;
- Region 6 implementation;
- mass asset conversion.

---

# 119. First workflow acceptance

Before trusting the system for larger tasks, confirm the first run demonstrates:

- correct branch handling;
- clean diff;
- no snapshot modification;
- Developer obeys scope;
- tests execute;
- Reviewer finds real issues when present;
- fix loop works;
- max-cycle limit works;
- commit only occurs after approval;
- logs are readable;
- owner can understand final summary quickly.

---

# 120. Final task summary to owner

After a successful task, the Orchestrator should present a concise owner-facing summary:

```text
EOP-001 — Equipment layout

Status: Approved and committed
Review rounds: 2
Changed: 4 files
Tests: full validation passed
Visual: 1920×1080 and 1280×720 passed
Save impact: none

What changed:
- narrowed backpack workspace
- enlarged character presentation
- preserved 11 equipment slots and drag/drop

Commit:
abc1234
```

Do not force the owner to read full agent logs unless requested.

---

# 121. Failure summary to owner

If stopped:

```text
EOP-001 — PAUSED

Reason:
Reviewer still finds the same inventory overlap after 3 attempts.

Current state:
- branch preserved
- no merge
- snapshot untouched
- tests currently pass except visual acceptance

Decision needed:
A. reduce paperdoll width
B. add scroll to details
C. redesign right column
```

The owner should be able to resume by choosing an option.

---

# 122. Final workflow principle

The team should behave like:

```text
careful developer
+
independent reviewer
+
strict build system
```

not like:

```text
two chatbots agreeing with each other
```

A healthy workflow requires disagreement when the work is wrong.

The Developer's goal is not to persuade the Reviewer.

The Reviewer's goal is not to find arbitrary faults.

Both roles serve the same target:

**ship a better Echoes of Pythonia without sacrificing project identity, technical safety, owner control or recoverability.**

---

# 123. Compact canonical state machine

```text
OWNER TASK
    ↓
CREATE TASK SPEC
    ↓
PREFLIGHT
    ├── unsafe → PAUSED
    ↓
TASK BRANCH
    ↓
DEVELOPER
    ↓
TARGETED TESTS
    ↓
HANDOFF
    ↓
REVIEWER
    ├── HUMAN_DECISION_REQUIRED → PAUSED
    ├── CHANGES_REQUESTED → DEVELOPER (max 4 rounds)
    └── APPROVED
            ↓
      FINAL VALIDATION
            ├── fail → DEVELOPER / PAUSED
            ↓
         COMMIT
            ↓
       PUSH (optional)
            ↓
INTEGRATE TO ai/echoes-team (policy-controlled)
            ↓
        DONE
```

No autonomous path leads directly to `main`.
