# SETUP — ask the user once, write it down, never ask again

> The agent reads this file when it needs information that lives on the user's machine.
> Communication rules: `AGENTS.md` §1b. Short version: LOCAL.md → which/env → ASK.
> **Asking = a plain chat message, then wait** — no select-lists, no choice boxes.
> **Never scan disks to find paths.**

## Why

By default an agent will try to "find" the engine itself across drives — slow, and it
rummages through the user's personal data. Information only the user certainly knows
(what's installed where on their machine) is fastest asked: 10 seconds of their time
instead of 10 minutes of probing. After asking you **must write it down** — the next
session reads the file and never re-asks an answered question.

## What to ask (standard checklist)

| Information | Ask when | Used for |
|---|---|---|
| UE root path (the `UE_5.x` folder — launcher or source build) | first run / build / test | `Build.bat`, `UnrealEditor-Cmd.exe` |
| Engine version (e.g. 5.5.4) + launcher/source | first time | `.uproject` EngineAssociation, feature decisions |
| Project type: **C++** or **Blueprint-only** | project creation | `Source/` skeleton or not (`docs/CODING.md` §6) |
| Visual Studio 2022 + "Game development with C++" workload (or Rider) | C++ project | compiling |
| Git LFS installed? | first `.uasset` commit | tracking binary assets |
| Node.js / Python + libs | when tooling is needed | pipelines |

## `docs/LOCAL.md` format

This file is **gitignored** — write machine paths freely, they never get pushed.
Create it upon the first answer:

```markdown
# LOCAL — machine config (gitignored, never committed)

- ue_root: "D:\\UE_5.5"
- ue_version: 5.5.4 (launcher build)
- editor_cmd: "D:\\UE_5.5\\Engine\\Binaries\\Win64\\UnrealEditor-Cmd.exe"
- build_bat: "D:\\UE_5.5\\Engine\\Build\\BatchFiles\\Build.bat"
- uproject: "D:\\UNREAL5\\my-game\\MyGame.uproject"   # filled after project creation
- project_type: cpp          # cpp | blueprint
- ide: Visual Studio 2022 ("Game development with C++" workload installed)
- git_lfs: yes
- note: builds take ~2-5 min; automation tests boot the engine (~1-3 min)
```

Next session: read this file at step 1 of the protocol (`AGENTS.md` §1) — if
`ue_root` is there, use it directly; don't re-ask, don't `find`.
