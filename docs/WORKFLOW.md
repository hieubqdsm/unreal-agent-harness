# Workflow — {{PROJECT_NAME}}

Working process for Unreal Engine game development with **AI agent + dev + human
tester**. All state lives in committed files → any AI/dev/tester can resume.

## Roles

| Role | Does what | Reads first |
|---|---|---|
| **Agent (AI)** | Develops features, compiles, runs auto-tests, updates status | `SESSION.md` → `ROADMAP.md` |
| **Dev (human)** | Develops/reviews, may take over features from the agent | `SESSION.md` → `ROADMAP.md` |
| **Tester (human)** | Plays features that are `dev_done`, records playtest results | `PLAYTEST_QUEUE.md` |

## State machine (per feature)

```
planned → in_dev → dev_done → playtesting → pass → shipped
   ↑         ↑        ↑              ↓
   └─────────┴────────┴───── fail (notes) → back to in_dev
```

Two **independent** test channels:
- `auto_test` — the agent runs it (compile + Unreal Automation tests, headless
  `-nullrhi`). Values `none|pass|fail`.
- `playtest.result` — the tester decides. Values `pending|pass|fail`. **The tester writes it.**

A feature merges into `main` only when `auto_test != fail` AND `playtest.result == pass`.

## Artefacts

| File | Role | Who writes it |
|---|---|---|
| `docs/ROADMAP.md` | Overall plan: milestones + feature table (id, status, priority, depends_on, assigned) | Agent / dev |
| `docs/CODING.md` | Code-writing policy: headless-testable, call-down/delegate-up, moderate composition, C++/BP split | Fixed policy — agent / dev follow it |
| `docs/features/F-xxx.md` | 1 feature / file. Frontmatter = source of truth (status, auto_test, playtest). | Agent writes status/auto_test; **tester writes playtest.result+notes** |
| `docs/SESSION.md` | **Resume entry point** — current focus, next action, blockers. Anyone reads this first. | Agent writes it before ending a session |
| `docs/PLAYTEST_QUEUE.md` | Tester's daily worklist | Agent updates, tester uses |
| `scripts/status.sh` | Prints a live status table from every feature's frontmatter | (read-only) |

## State discipline (durable / in-flight / policy)

All information falls into 3 kinds — **put the right kind in the right file**, never mixed:

| Kind | What it is | Where it lives |
|---|---|---|
| **Durable** | Facts that must survive reload/restart: feature status, test results, commits | Frontmatter `docs/features/F-xxx.md` (committed) |
| **In-flight** | Current work state: which feature, next step | Frontmatter `docs/SESSION.md` (`current_focus`, `next_action`) |
| **Policy** | Fixed rules: merge conditions, definition of "pass", how to write code | `docs/WORKFLOW.md` (process) + `docs/CODING.md` (code) — NEVER mixed into state |

**Invariant — model-visible ⟺ logged:** anything the agent knows/decides **must live
in a committed file**. Never keep state only in the conversation: context gone = state
lost. If the agent "remembers" something that isn't in `docs/`, it doesn't exist.

**Structured handoff:** `SESSION.md` is a handoff with a schema (`current_focus`,
`next_action`, `done`, `blockers`, `decisions_pending`). When ending a session, `done:`
must list the finished work **with evidence** (commit/file). No evidence = not done.

## Session START protocol (resume) — for anyone

Read in order:
1. `docs/SESSION.md` → current focus + `next_action` + blockers.
2. `docs/ROADMAP.md` → the big picture.
3. Run `bash scripts/status.sh` (or scan `docs/features/*.md`) → status table.
4. Tester → open `docs/PLAYTEST_QUEUE.md`.
5. Continue from `next_action` in SESSION.md.

> If `SESSION.md` says `handoff_kind: planned-next` → just continue.
> If `handoff_kind: pause` → present the stopping point and wait for a human decision.

## Session END / pause protocol

The agent must do this before exiting:
1. Commit every change (1 commit / logical step).
2. Update `docs/features/F-xxx.md`: `status`, `auto_test`, §Changelog.
3. Update `docs/ROADMAP.md` (the feature's row).
4. If the feature reached the test stage → push into `docs/PLAYTEST_QUEUE.md`.
5. Write `docs/SESSION.md` (structured handoff): `current_focus`, `phase`,
   `next_action`, `handoff_kind`, `done` (evidence with commit/file), `blockers`,
   and `decisions_pending` if `handoff_kind: pause`.
6. Commit these docs files.

## Parallelization (multiple features / multiple people)

- **1 feature = 1 branch** `feat/F-xxx-<slug>`. Two people working on two features
  don't touch each other's files.
- Frontmatter `assigned:` shows who holds it. ROADMAP displays ownership.
- `main` = only receives features with `playtest.result == pass` (merged via branch).
- ⚠ **Binary merge conflicts:** `.uasset`/`.umap` cannot be merged textually —
  avoid two branches editing the same asset; if it happens, one side re-does the
  change in the editor. Prefer C++ (text) for anything two people touch.
- To run several engine instances at once (testing 2 branches in parallel) →
  `git worktree add` — note each worktree compiles its own `Binaries/` (disk +
  minutes of build time), so prefer testing serially.
- Only 1 person updates `ROADMAP.md` / `SESSION.md` at a time (merge fast to avoid
  conflicts).

## How the TESTER reports results

1. Open `docs/PLAYTEST_QUEUE.md` → pick a feature that is `dev_done`/`playtesting`.
2. Checkout the branch `feat/F-xxx-<slug>` (or run the packaged build per the queue's notes).
3. Open the project in the Unreal Editor → Play In Editor (or run the build).
4. Play, check against §Playtest checklist in `docs/features/F-xxx.md`.
5. Edit 2 lines in the frontmatter of `docs/features/F-xxx.md`:
   - `playtest.result: pass` (or `fail`)
   - `playtest.notes: "<notes/bugs if any>"`
6. (Optional) update §Changelog with the date + result.
7. Commit. The agent reads it next session → knows pass/fail → merges or fixes.

## How the AGENT knows "what's tested / where to continue"

- Read `SESSION.md` (`current_focus` + `next_action`) → what's being worked on.
- Run `scripts/status.sh` → the STATUS / AUTO_TEST / PLAYTEST table for every feature.
- Feature with `playtest.result == pass` → ready to merge.
- Feature with `playtest.result == fail` → read `playtest.notes`, fix (back to `in_dev`).
