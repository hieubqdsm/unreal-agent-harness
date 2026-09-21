# ROADMAP — {{PROJECT_NAME}}

> The game's overall plan. The agent/dev updates feature status here.
> Detailed source of truth lives in `docs/features/F-xxx.md` (this file is just the big map).
> Full workflow: `docs/WORKFLOW.md`.

## Game (not finalized)

- **Name:** {{PROJECT_NAME}}
- **Description (1 line):** _<fill in: genre, core feeling>_
- **Engine:** Unreal Engine 5.x (per docs/LOCAL.md)
- **Target platform:** _<PC / console / mobile>_

## Milestones

| Milestone | Goal | Status |
|---|---|---|
| **M0 — Vertical slice** | UE project init + one small playable gameplay loop | planned |
| **M1 — _<fill in>_** | _<fill in>_ | planned |
| **M2 — _<fill in>_** | _<fill in>_ | planned |

## Feature register

| ID | Name | Priority | Status | Auto-test | Playtest | Assigned | Branch | Depends on |
|---|---|---|---|---|---|---|---|---|
| _<F-001>_ | _<e.g. Player movement>_ | _P1_ | _planned_ | — | — | — | — | — |
| _<F-002>_ | _<...>_ | _P2_ | _planned_ | — | — | — | — | — |

_(Add a row when creating a new feature. The status/auto-test/playtest columns follow the feature file.)_

## Legend

- **Status:** `planned` → `in_dev` → `dev_done` → `playtesting` → `pass` → `shipped` (× `fail` loops back to `in_dev`).
- **Priority:** `P0` blocker · `P1` important · `P2` normal · `P3` nice-to-have.
- **Auto-test:** `—` none yet · `pass` · `fail`.
- **Playtest:** `—` not reached · `pending` awaiting tester · `pass` · `fail`.
