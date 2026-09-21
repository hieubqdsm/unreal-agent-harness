# Unreal MCP — setup (optional, recommended)

> The harness **works without MCP** — the agent drives the engine through the CLI
> (`Build.bat`, `UnrealEditor-Cmd.exe`; `AGENTS.md` §6).
> With an Unreal MCP server installed, the agent can create Blueprints/assets/levels
> and inspect the running editor directly — a much tighter feedback loop, and the
> only sane way for an agent to produce `.uasset` content (`docs/CODING.md` §0b).
> **HARD RULE (`AGENTS.md` §0.2):** window-opening operations (launching the editor,
> starting PIE) are never done by the agent on its own — only when the user
> explicitly asks, or attaches to an editor the user already opened.

## Server (what this environment uses)

**ChiR24/Unreal_mcp** (<https://github.com/ChiR24/Unreal_mcp>, MIT) — a C++ "MCP
Automation Bridge" editor plugin + MCP bridge (TypeScript stdio or native HTTP/SSE
built into the plugin). It exposes **23 canonical tools** grouped exactly as the
table below (core 8 / world 4 / gameplay 8 / utility 3), matching the tool names
this harness documents (`manage_blueprint`, `build_environment`, `manage_gas`...).
Engine support: UE 5.0–5.8; blueprint-only projects can't compile the C++ plugin
from source (use the prebuilt binaries per version).

Alternatives (surveyed 2026-09): Epic's **official** Unreal MCP (built into
UE 5.8+, `ModelContextProtocol` + `AllToolsets` engine plugins, hundreds of tools
via ToolsetRegistry; also in UEFN; see
[EpicGames/unreal-engine-skills-for-claude-code-plugin](https://github.com/EpicGames/unreal-engine-skills-for-claude-code-plugin)),
[chongdashu/unreal-mcp](https://github.com/chongdashu/unreal-mcp) (C++ plugin +
Python FastMCP, UE 5.5+, experimental),
[remiphilippe/mcp-unreal](https://github.com/remiphilippe/mcp-unreal) (Go binary,
~49 tools, UE 5.7 — the only one with a real **headless** channel: builds/tests
via `UnrealEditor-Cmd` with no editor running),
[VibeUE](https://github.com/kevinpbuckley/VibeUE) (extends the built-in UE 5.8 MCP,
in-editor chat). Asset editing across all of them still requires a running editor;
the window policy below applies the same.

## Architecture (2 channels)

1. **Headless CLI — always available, no editor needed.** The agent writes text
   files (C++, `.uproject`, `Config/*.ini`), compiles with
   `<UE_ROOT>/Engine/Build/BatchFiles/Build.bat` and runs automation tests with
   `UnrealEditor-Cmd.exe ... -nullrhi`. This is the auto-test channel and it never
   opens a window.
2. **Editor MCP tools — need a RUNNING editor.** The Unreal MCP server is an
   editor plugin + bridge: tools execute on the game thread inside the editor
   process. Usable when:
   - the user has the editor open on this project (normal case during joint dev), or
   - the user explicitly asked the agent to open the editor (§0.2).
   When no editor is running, the agent stays on channel 1 and leaves
   `TODO(dev):` for asset work — it must NOT launch the editor just to use MCP.

## Tool groups (what the agent uses)

| Group (tool) | What it does |
|---|---|
| `control_editor` | PIE play/stop/pause, viewport camera, console commands, open level, input simulation, screenshots |
| `control_actor` | spawn/delete/attach actors, set transforms/components/properties |
| `inspect` | inspect objects/classes/Blueprint CDOs, get/set properties, snapshots, world stats |
| `manage_asset` | create/duplicate/delete assets, material graphs, procedural textures, dependencies |
| `manage_blueprint` | create Blueprint/Widget Blueprints, add components/variables/functions/graph nodes, connect pins, build UMG |
| `manage_character` / `manage_combat` / `manage_gas` | character movement config, weapons/hitscan/projectiles, Gameplay Ability System |
| `manage_ai` | Behavior Trees, Blackboards, EQS, perception, NavMesh settings |
| `manage_level` / `manage_level_structure` / `build_environment` | create/load/save levels, lighting, landscape, foliage, splines, volumes, World Partition |
| `manage_geometry` | Geometry Script procedural meshes (booleans, deformers, UVs, LODs) |
| `manage_pcg` | PCG graphs (samplers, filters, spawners) |
| `manage_audio` / `manage_effect` / `manage_sequence` / `animation_physics` | Sound Cues/MetaSounds, Niagara, Level Sequences, AnimBPs/skeletons |
| `manage_interaction` / `manage_inventory` | doors/switches/triggers, item/inventory/loot/crafting |
| `manage_networking` | replication, RPCs, GameMode/player classes, Enhanced Input |
| `system_control` | console commands, `execute_python` (editor Python — needs PythonScriptPlugin), screenshots, validate_assets, profiling |
| `manage_tools` | enable/disable tool groups |

Full action lists: the server's own README / tool descriptions in the client.
Not every project needs every group — ignore what the game doesn't use.

## Window policy (maps to HARD RULE §0.2)

**Never on the agent's own initiative:**
- Launching `UnrealEditor.exe` (GUI) — including "let me just open it to test".
- `control_editor: play` (PIE opens a game window), unless the user asked for a
  run in this session.
- Running packaged/rendered builds.

**Fine at any time (no window):**
- All headless CLI (channel 1) with `-nullrhi -unattended -nosplash -nopause`.
- Read-only inspection via MCP when the user's editor is already running
  (`inspect`, `get_*`, screenshots of an already-running PIE the user started).

**Editor started by the agent at all?** Only when the user explicitly asks, and it
must be recorded in `SESSION.done` (evidence) when it changes anything.

## Relationship with the harness workflow

- MCP is only **how the agent drives Unreal**. **State still lives in markdown**
  (SESSION / features) — unchanged.
- Auto-tests in `AGENTS.md` §6 still run via the headless CLI. MCP does not
  replace that channel; `validate_assets` / `inspect` are cheap pre-checks before
  a full automation run.
- Asset changes made through MCP are binary — describe them in the feature's
  §Changelog (`docs/CODING.md` §0b); git diff won't show anything useful.
