# unreal-agent-harness

> A harness (process framework) for developing **Unreal Engine 5** games with an
> **AI agent + dev + human tester**. All state lives in committed Markdown
> → any agent / dev / tester can resume, independent of any AI session.

> **AI agent — read first:** [`AGENTS.md`](AGENTS.md) (session entry/exit protocol, frontmatter schemas, discipline).

Built by borrowing patterns from production-grade agent harnesses:
**model-visible ⟺ logged** (state always in files, never in conversation),
**structured handoff**, and **durable / in-flight / policy separation**.
Ported from [godot-agent-harness](https://github.com/hieubqdsm/godot-agent-harness)
with Unreal-specific policy: headless `-nullrhi` testing, C++/Blueprint split,
binary-asset (`.uasset`) rules.

---

## For a new Unreal project

**Option 1 — GitHub "Use this template"** (enable *Template repository* in this
repo's Settings): click the button → name the new game repo → clone it locally.

**Option 2 — manual clone:**
```sh
git clone --depth 1 https://github.com/hieubqdsm/unreal-agent-harness.git my-game
cd my-game
rm -rf .git
git init
```
_(change the URL to your own repo)_

**Name the project** (run once; `init.sh` replaces the name + date in every doc file):
```sh
bash scripts/init.sh "Your Game Name"
```

**Start developing:**
1. `git add -A && git commit -m "init project"` (recommended for UE binary assets:
   `git lfs install` + track `*.uasset *.umap *.umedia`)
2. Create `<Name>.uproject` (**user** step): open Unreal → New Project at this
   directory (or right-click → launch engine). If you are an agent: write the
   `.uproject` (+ `Source/` skeleton for C++ projects) directly as text, **do not
   open the editor** (`AGENTS.md` §0.2).
3. Read `docs/SESSION.md` → follow `next_action`.

> After running `init.sh` you may delete it if you want (it's only used once).

### Updating the harness for a game repo generated from this template

The template has a new patch (e.g. hard rules) and your game repo wants it? Don't
hand-copy files one by one — use git:

```sh
cd my-game
git remote add template https://github.com/hieubqdsm/unreal-agent-harness.git   # once
git fetch template

# Pull only the HARNESS files (game repos don't customize them):
git checkout template/main -- \
  AGENTS.md README.md LICENSE docs/CODING.md docs/MCP.md docs/SETUP.md docs/WORKFLOW.md \
  scripts/status.sh scripts/init.sh

git commit -m "sync harness from template"
```

- The harness files above are taken **verbatim** from the latest template — even if
  the game repo was generated from a much older template.
- Do **NOT** checkout `docs/SESSION.md`, `docs/ROADMAP.md`, `docs/features/`,
  `docs/PLAYTEST_QUEUE.md`, `docs/LOCAL.md` — those are the game's own state.
- To keep history clean (repo generated from a recent template): `git cherry-pick`
  the template commits instead of checkout; resolve the conflicts manually.

## What you get

| File | Role |
|---|---|
| `docs/WORKFLOW.md` | Full process: roles, state machine, session start/end protocols, state discipline |
| `docs/CODING.md` | Code-writing policy: headless-testable, call-down/delegate-up, moderate composition, C++/Blueprint split, binary-asset rules, senior Blueprint graph hygiene, UE5 asset standards & authority rules |
| `docs/ROADMAP.md` | Overall plan: milestones + feature table |
| `docs/SESSION.md` | **Resume entry point** — current work + next step (structured handoff) |
| `docs/SETUP.md` | Standard ask-the-user machine setup + `docs/LOCAL.md` format (gitignored) |
| `docs/MCP.md` | Optional Unreal MCP: tool groups, editor/headless channels, window policy |
| `docs/PLAYTEST_QUEUE.md` | Tester's daily worklist |
| `docs/features/F-xxx.md` | 1 feature / file. Frontmatter = source of truth |
| `docs/features/_TEMPLATE.md` | Template for new features (copy → `F-00X.md`) |
| `scripts/status.sh` | Live status table from every feature's frontmatter |
| `scripts/init.sh` | Name the project (run once) |
| `.gitignore` | Unreal Engine 5 ignores |

## Workflow summary

Every feature goes through:
```
planned → in_dev → dev_done → playtesting → pass → shipped
                                              ↘ fail → in_dev
```
Two **independent** test channels: `auto_test` (agent runs it headless — compile +
Unreal Automation with `-nullrhi`) and `playtest` (human tester). A feature merges
into `main` only when `auto_test != fail` **AND** `playtest.result == pass`.

At the start of any session, read in order:
`docs/SESSION.md` → `docs/ROADMAP.md` → `bash scripts/status.sh`.

Details: `docs/WORKFLOW.md`.

## State discipline (3 kinds, never mixed)

| Kind | Where it goes |
|---|---|
| **Durable** (facts that survive reload: status, test results) | frontmatter `docs/features/F-xxx.md` |
| **In-flight** (what's being done, what's next) | frontmatter `docs/SESSION.md` |
| **Policy** (fixed rules: merge conditions, code policy) | `docs/WORKFLOW.md` + `docs/CODING.md` |

## Requirements

- Unreal Engine 5.x (Windows)
- Visual Studio 2022 with the "Game development with C++" workload (or JetBrains
  Rider) — required for C++ projects
- Bash (Git Bash on Windows ships with Git for Windows)
- Git LFS (recommended — UE binary assets)
- (optional, recommended) **Unreal MCP** — lets the agent drive the editor over MCP:
  see [`docs/MCP.md`](docs/MCP.md)

## License
MIT — see `LICENSE`.
