# Playtest Queue — {{PROJECT_NAME}}

> Daily worklist for the **tester**. Every feature reaching `dev_done`/`playtesting`
> gets pushed here by the agent.
> How to report results: see `docs/WORKFLOW.md` §"How the TESTER reports results".

## How to run a feature for testing

1. Make sure you are in the project repo's root directory (the one containing
   `docs/` and `<Name>.uproject`).
2. Checkout the feature branch: `git switch feat/F-xxx-<slug>` (see the Branch column).
   - Or run the packaged build per the feature's own notes.
3. Open the project in the Unreal Editor (double-click the `.uproject`) and run
   **Play In Editor** (or Standalone / the packaged build per the feature's notes).
4. Check against the **Playtest checklist** in `docs/features/F-xxx.md`.
5. Record the result in `docs/features/F-xxx.md`: `playtest.result` + `playtest.notes`.
6. Commit.

## Queue

| ID | Name | Branch | Checklist | How to run | Result |
|---|---|---|---|---|---|
| _<F-xxx>_ | _<name>_ | _feat/F-xxx-slug_ | _see F-xxx.md_ | _<how to run>_ | _pending_ |

_(Empty = no feature is ready for testing yet.)_

## Processed (recent history)

| ID | Result | Date | Short notes |
|---|---|---|---|
| — | — | — | — |
