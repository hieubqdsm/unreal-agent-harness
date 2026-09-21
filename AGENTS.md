# AGENTS.md — Operating manual for the agent

> **Read this file FIRST** when entering the repo. This is the operational manual for
> the AI agent in charge of developing/testing features for an Unreal Engine game in
> this harness. If this is your first pull → run `bash scripts/init.sh "<Project Name>"` first.

You are working in a **markdown-first** harness: all state lives in committed files. You
must NOT keep state in the conversation — context gone = state lost. Core principle:
**model-visible ⟺ logged** (see §5).

---

## 0. HARD RULES — highest law (if any § conflicts with §0, §0 wins)

1. **Asking = plain chat.** Do NOT use select-list / choice-box / multiple-choice
   question tools. Send the question as plain text, then **end your turn** and wait for
   the user to type the answer (details: §1b).
2. **Unreal HEADLESS ONLY.** NEVER open a window on the user's machine: do not launch
   `UnrealEditor.exe` (GUI), do not start PIE, do not run a rendered/game build, do not
   call MCP tools that do any of these (`control_editor: play`, ...) — **unless the
   user explicitly orders it in writing** during the session ("open the editor",
   "run it for me"). Every engine process you start yourself must be
   `UnrealEditor-Cmd.exe` with `-nullrhi -unattended -nosplash -nopause` (§6).
   Editor-attached MCP tools (`manage_*`, `inspect`, `control_editor`...) need a
   RUNNING editor — allowed when the user's editor is already open on this project,
   or the user asked you to open it (details: `docs/MCP.md` §"Window policy").
3. **Missing info / no plan yet → STOP.** If a question has been asked but not answered
   (e.g. no `ue_root` in `docs/LOCAL.md` yet), do NOT guess, do NOT scan disks, do NOT
   "do something else and figure it out later". End your turn, log the blocker in
   `SESSION.blockers`, wait for the user. No engine = nothing meaningful can compile
   or run — that's the moment to ask, not to experiment.
4. **Binary assets are untouchable as text.** `.uasset` / `.umap` are binary: never
   hand-edit them, never sed/regex/patch them. Asset work goes through MCP editor
   tools or stays a `TODO(dev):` (see `docs/CODING.md` §0b).

## 1. Session entry protocol (do immediately, in order)

0. **Template or game repo?** If the `TEMPLATE` file still exists at the repo root →
   this is the TEMPLATE. **Do NOT dev a game / do NOT create a .uproject here.**
   Your job (if asked to make a game): copy this repo to a new directory, run
   `bash scripts/init.sh "<Game Name>"` there, then continue. The `TEMPLATE` file
   disappears after init = valid game repo, continue with the steps below.
1. **Read `docs/LOCAL.md` (if it exists)** — setup answers from previous sessions
   (engine root, version, IDE, project type...). If it doesn't exist and you need
   machine info → follow §1b: **ASK the user, don't go hunting**.
2. Read `docs/SESSION.md` → learn `current_focus` + `next_action` + `blockers`.
3. Read `docs/ROADMAP.md` → the big picture (milestones + feature table).
4. Run `bash scripts/status.sh` → the `STATUS / AUTO_TEST / PLAYTEST / BRANCH` table
   for every feature.
5. Tester → also open `docs/PLAYTEST_QUEUE.md`.
6. Follow `next_action`.
   - `handoff_kind: planned-next` → just continue.
   - `handoff_kind: pause` → present `decisions_pending`, **wait for a human decision**
     before continuing.

## 1b. Setup communication with the user (MANDATORY)

For information that lives **on the user's machine** (engine root path, VS/Rider,
Git LFS, node/python, GPU...), proceed in this order — stop at the first step that
yields a result:

1. Read `docs/LOCAL.md` (a previous session already asked).
2. Check the standard places with ≤2 commands: `which UnrealEditor-Cmd`, env var
   `UE_ROOT`.
3. Not found → **ASK THE USER**. One question = 10 seconds of their time, instead of
   10 minutes of scanning. Include a hint (e.g. "usually C:\Program Files\Epic
   Games\UE_5.5 or D:\UE_5.5?").

**How to ask: a plain chat message (HARD RULE §0.1).** Send the question as plain text
in chat, with a hint, then **end your turn and wait for the user to type the answer
directly**.
**NEVER** use select-list / choice-box / multiple-choice question tools (forcing
the user to pick from presets or click "Other" just to type) — pushing every question
through a choice box is more friction than plain chat. Free-form answers (paths,
versions...) are fastest typed straight into chat.

**NEVER** `find`/scan disks/roam "tens of TB of data" to guess a path — slow, noisy,
and rummaging through the user's personal data.

When you get an answer → **write it into `docs/LOCAL.md` immediately** (already
gitignored, machine paths never pushed to remote) following the template in
`docs/SETUP.md`. The next session reads this file — exactly the model-visible ⟺ logged
principle: not written down = considered never asked.

## 2. Creating a new feature

1. Take the next number (see `docs/features/F-*.md` or ROADMAP). Copy the template:
   ```sh
   cp docs/features/_TEMPLATE.md docs/features/F-001.md
   ```
2. Fill the frontmatter (schema in §4): `id`, `name`, `status: planned`, `branch`,
   `priority`, `assigned`, `depends_on`, `auto_test: none`, `playtest{...}`.
3. Create the branch: `git switch -c feat/F-001-<slug>`.
4. Add one row to `docs/ROADMAP.md` (feature register).
5. Commit.
6. Before writing the feature's first line of code → read the policy `docs/CODING.md`
   (headless-testable, call-down/delegate-up, C++/Blueprint split, binary-asset rule).

## 3. Feature lifecycle (state machine)

```
planned → in_dev → dev_done → playtesting → pass → shipped
                                      ↘ fail → in_dev
```

| Transition | Set `status:` | Accompanying action |
|---|---|---|
| Start coding | `in_dev` | — |
| Code done + `auto_test` pass (or no auto test) | `dev_done` | push into `docs/PLAYTEST_QUEUE.md` |
| Tester played, `playtest.result: pass` | `pass` | ready to merge to `main` |
| Tester played, `playtest.result: fail` | back to `in_dev` | read `playtest.notes`, then fix |
| Merged to main | `shipped` | — |

The two test channels are **independent**: `auto_test` (you run it) and `playtest.result`
(**the tester writes it, NOT you**).

## 4. Frontmatter schema (source of truth)

**Feature file `docs/features/F-xxx.md`:**
```yaml
id: F-xxx
name: <short name>
status: planned            # planned | in_dev | dev_done | playtesting | pass | fail | shipped
branch: feat/F-xxx-<slug>
priority: P2               # P0 (blocker) | P1 | P2 | P3
assigned: <agent | dev name>
depends_on: []             # [F-003, ...]
auto_test: none            # none | pass | fail   ← YOU write this
playtest:
  assigned: <tester>
  result: pending          # pending | pass | fail ← TESTER writes this
  checklist: []            # ["Player moves with WASD", ...]
  notes: ""                # tester writes bugs/notes here
```

**File `docs/SESSION.md`:**
```yaml
last_updated: "YYYY-MM-DD"
phase: planned             # planned | dev | paused | done
branch: main
handoff_kind: planned-next # planned-next | pause
current_focus: none        # feature id being worked on, or "none"
next_action: "<EXACTLY 1 feasible, resumable command>"
done: []                   # evidence: "<what> (commit/file:...)" — NONE = not done
blockers: []               # each line: "<what> (→ <condition to clear>)"
decisions_pending: []      # only required when handoff_kind: pause
```

## 5. MANDATORY discipline

- **model-visible ⟺ logged:** every decision/state MUST live in a committed file. If
  you "remember" something that isn't in `docs/` → it doesn't exist.
- **Evidence required:** `SESSION.done` must include evidence (commit hash / file).
  Work without evidence = considered not done.
- **3 domains, never mixed:**
  - *Durable* (survives reload: status, test results) → frontmatter `docs/features/F-xxx.md`.
  - *In-flight* (what's being done, what's next) → frontmatter `docs/SESSION.md`.
  - *Policy* (fixed rules) → `docs/WORKFLOW.md` (process) + `docs/CODING.md`
    (how to write code) — NEVER mixed into state.
- **Merge to `main` only when** `auto_test != fail` **AND** `playtest.result == pass`.
- **You NEVER write `playtest.result`** on the tester's behalf.

## 6. Auto-test (Unreal headless)

Engine paths come from `docs/LOCAL.md` (`ue_root` → `editor_cmd`, `build_bat`).
No `ue_root` yet → §0.3: STOP and ask.

> **Unreal is SLOW:** a C++ compile takes minutes, an automation run boots the
> engine (~1–3 min). **Batch your changes, then run the check once** — not after
> every file. Record the exact command you ran in the feature's §"Automated testing".

```sh
# 0) Convenience (bash, from the repo root):
UPROJECT="$(ls -1 *.uproject)"          # after the project exists
EDITOR_CMD="<ue_root>/Engine/Binaries/Win64/UnrealEditor-Cmd.exe"
BUILD_BAT="<ue_root>/Engine/Build/BatchFiles/Build.bat"

# 1) Compile check (C++ projects) — the cheap pre-check:
"$BUILD_BAT" <ProjectName>Editor Win64 Development -project="$PWD/$UPROJECT" -waitmutex

# 2) Boot smoke test — project loads, no window (ALWAYS these flags, §0.2):
"$EDITOR_CMD" "$PWD/$UPROJECT" -nullrhi -unattended -nosplash -nopause -ExecCmds="Quit"

# 3) Automation tests (Unreal Automation framework):
"$EDITOR_CMD" "$PWD/$UPROJECT" -nullrhi -unattended -nopause -nosplash -log \
  -ExecCmds="Automation RunTests <Filter>" -TestExit="Automation Test Queue Empty"
```

- Tests live in `Source/<Game>/Tests/` (`IMPLEMENT_SIMPLE_AUTOMATION_TEST`) —
  filter by your project's namespace, e.g. `Automation RunTests MyGame` (or a
  narrower `MyGame.F-001`). Functional (in-map) tests run under the same command.
- Pass → `auto_test: pass` + record the command in the feature's
  §"Automated testing" section.
- Fail → `auto_test: fail`, read `Saved/Logs/*.log`, fix, rerun.
- No auto test → leave `auto_test: none` (that's fine, playtest is the main gate).
- **Never** drop `-nullrhi -unattended` "to see what happens" — that opens a window
  (§0.2).
- Packaging (`BuildCookRun`) is heavy — only when a feature/playtest needs a build;
  never "just to check".

> **Unreal MCP (optional):** if an Unreal MCP server is configured AND the user's
> editor is running on this project, tools like `inspect` / `validate_assets` /
> `manage_blueprint` give a tighter feedback loop (see `docs/MCP.md`). Auto-tests
> still run via the headless CLI above — MCP does not replace that channel.

## 7. Session end protocol (MANDATORY before exiting)

1. Commit every code change (1 commit / logical step).
2. Update `docs/features/F-xxx.md`: `status`, `auto_test`, §Changelog (for `.uasset`
   changes: describe manually — git diff is meaningless on binary).
3. Update the matching row in `docs/ROADMAP.md`.
4. Feature reaching the test stage → push into `docs/PLAYTEST_QUEUE.md`.
5. Write `docs/SESSION.md` (structured handoff): `current_focus`, `phase`,
   `next_action`, `handoff_kind`, `done` (**evidence with commit/file**),
   `blockers`, plus `decisions_pending` if `handoff_kind: pause`.
6. Commit these docs files. **Never exit while `docs/` has uncommitted changes.**

## 8. Useful commands

| Command | When |
|---|---|
| `bash scripts/status.sh` | live status of every feature (start of session) |
| `bash scripts/init.sh "<Name>"` | **only once** after first pulling the harness (set project name) |
| `git switch -c feat/F-xxx-<slug>` | create a feature branch |
| `"$BUILD_BAT" <Game>Editor Win64 Development -project=...` | compile check (no window) |
| `"$EDITOR_CMD" "$UPROJECT" -nullrhi -unattended -nosplash -nopause -ExecCmds="Quit"` | boot smoke test, no window |
| `"$EDITOR_CMD" ... -ExecCmds="Automation RunTests <Filter>" -TestExit="Automation Test Queue Empty"` | run auto-tests headless |
| open the editor / PIE / packaged build | **ONLY when the user asks** (§0.2) |

## 9. Don'ts

- ❌ Keep state in the conversation instead of files.
- ❌ Ask the user via select-list/choice box — ask in plain chat (§0.1).
- ❌ Open any window (UnrealEditor GUI, PIE, rendered run) without the user asking — headless `-nullrhi` only (§0.2).
- ❌ Run `UnrealEditor-Cmd` without `-nullrhi -unattended` (§0.2).
- ❌ Keep working while waiting for an answer / missing info (no engine path, no approved plan) — stop and wait (§0.3).
- ❌ Hand-edit or sed/regex `.uasset`/`.umap` binary files (§0.4).
- ❌ Write `playtest.result` on the tester's behalf.
- ❌ Merge to `main` before the feature has `playtest.result == pass`.
- ❌ Change `status`/`auto_test` without the accompanying commit + `ROADMAP` + `SESSION` updates.
- ❌ Edit `docs/WORKFLOW.md` (policy) to "work around" a failing feature — policy is fixed.
