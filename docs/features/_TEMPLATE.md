---
id: F-xxx
name: <short feature name>
status: planned            # planned | in_dev | dev_done | playtesting | pass | fail | shipped
branch: feat/F-xxx-<slug>
priority: P2               # P0 (blocker) | P1 | P2 | P3
assigned: <agent | dev name>
depends_on: []             # dependency feature ids, e.g. [F-003]
auto_test: none            # none | pass | fail   ← agent runs it (Automation test / compile)
playtest:
  assigned: <tester>
  result: pending          # pending | pass | fail ← TESTER writes this
  checklist: []            # e.g. ["Player moves with WASD", "Walls block movement"]
  notes: ""
---

<!--
  HOW TO USE: copy this file to docs/features/F-00X.md and fill in the fields.
  The frontmatter is the source of truth — agent/ROADMAP/status.sh read it from here.
  The tester only edits 2 lines: playtest.result + playtest.notes.
-->

# <feature name>

## Description
<What this feature does, what role it plays in the game.>

## Acceptance criteria (when is it done)
- [ ] <requirement 1>
- [ ] <requirement 2>

## Plan / sub-tasks (cell)
- [ ] <step 1>
- [ ] <step 2>

## Automated testing (auto_test)
<Record the exact command/test here, e.g. "Automation RunTests <ProjectName>.F-xxx" (see AGENTS.md §6). If there is no auto test, write "none".>

## Playtest checklist (for the tester)
- [ ] <what to check when playing>
- [ ] <...>

## Changelog
- <YYYY-MM-DD> — <commit> — <what changed, why; for .uasset changes describe manually — git diff is meaningless on binary>
