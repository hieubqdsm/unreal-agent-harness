# CODING — Game code design policy (Unreal)

> **Fixed rules about HOW to write code** (policy — never mixed with state).
> Feature process/lifecycle lives in `docs/WORKFLOW.md`; agent operations in `AGENTS.md`.
>
> The spirit in one sentence: **the repo must be an ORDINARY Unreal project** — the
> agent can write, compile and test it headless; a human (dev/tester) opens the
> editor and understands it immediately. The "agent generates one giant builder
> that constructs the whole game at runtime" style is not acceptable.

## 0. Principle zero — headless-testable & human-editable

Two constraints of this harness, **above every other principle**:

- **The agent cannot press Play.** No windowed runs, no editor GUI
  (`AGENTS.md` §0.2). The agent's "Play" is the automation test:
  ```sh
  "$EDITOR_CMD" "$UPROJECT" -nullrhi -unattended -nopause -nosplash -log \
    -ExecCmds="Automation RunTests <Filter>" -TestExit="Automation Test Queue Empty"
  ```
  Gameplay logic must be testable through this command (or at minimum through a
  clean compile).
- **Logic separated from presentation.** Gameplay rules go in C++ classes testable
  without rendering; Widgets/Blueprints stay thin wrappers that call down.
  Event Tick stays thin — dispatch only, no logic.
- **A human opening the editor understands it.** Standard UE naming (`A/U/F/E/I`
  prefixes for C++; `BP_`/`T_`/`DA_`/`DT_` prefixes for assets), standard folder
  layout (`Source/<Game>/`, `Content/`), content created through the editor or MCP
  tools — never assembled by a runtime generator script.

## 0b. Text files vs binary assets (Unreal-specific — hard rule)

The agent writes **text**: C++ (`Source/`), `.uproject`, `Config/*.ini`, Python.
`.uasset` / `.umap` are **binary** — never hand-edit them, never sed/regex them:

- Blueprint / level / asset creation goes through **MCP editor tools**
  (`docs/MCP.md`) or an editor Python script — both need the editor running
  (`AGENTS.md` §0.2).
- No editor / MCP available → keep the logic in C++, leave a `TODO(dev):` in the
  feature file + code. A missing `.uasset` must not block auto-tests.
- `git diff` on `.uasset` is meaningless → always describe binary changes in the
  feature's §Changelog; C++ stays the reviewable source of truth.

## 1. One entity = one Actor/Blueprint at entity level

- One entity = one Actor: a C++ base class (e.g. `APlayerCharacter`) + optionally a
  thin Blueprint child (`BP_PlayerCharacter`) for content/presentation only.
- Entity-level Actors get a smoke test (automation / functional test) where
  feasible (principle 0).
- **Valid exception:** fragments (one HUD row, a small hitbox, a private
  sub-widget) don't need a meaningful standalone test — don't force scaffolding
  onto every child.

## 2. Call down, delegate up — the default, not an absolute

- Owners call children directly (`Component->Setup(...)`, `AddWidget(...)`).
  Reusable components never crawl upward
  (`GetOwner()->GetOwner()->FindComponentByClass...`) or reach into siblings —
  that couples them to one parent.
- Children report upward via **delegates**
  (`DECLARE_DYNAMIC_MULTICAST_DELEGATE`, `UPROPERTY(BlueprintAssignable)`) — but
  pick the channel by relationship, don't delegate-ize everything:
  - **Known 1:1** (a HealthBar always belongs to a HUD) → pass the reference down
    (`UPROPERTY` weak reference) — easier to trace than a delegate.
  - **Broadcast** (whoever cares listens) → delegate on the owning Actor.
  - **Truly global** (game_over, level_changed) → Event Bus subsystem (principle 5).
  - **Cross-actor contracts** (player ↔ door) → Blueprint Interface
    (`IInteractable`) instead of type-coupling.
- Delegate spaghetti is harder to debug than calls — only broadcast when several
  parties genuinely listen.

## 3. Moderate composition — no component bloat

- **`UActorComponent`** for things that belong on an Actor: `UHealthComponent`,
  `UHitboxComponent`... drag-and-drop reuse instead of deep inheritance
  (Blueprint inheritance >1 level is suspicious).
- **Plain C++ for pure logic** (damage math, AI decisions, shuffling...): free
  functions, plain structs, or a subsystem — testable headless without a world,
  no Actor overhead. This is the most test-friendly level — prefer it for game
  rules.
- Not "everything is a component": 5–7 components per entity × hundreds of
  entities = a hierarchy humans can't read + needless tick cost.

## 4. Data-driven with Data Assets & DataTables — mind the sharing trap

- Config separated from logic: `UPrimaryDataAsset` subclasses (`UItemData`,
  `UEnemyStats`) with instances (`DA_*`) in `/Content/Data/`, or `UDataTable`
  (`DT_*`) for bulk tabular data. Actors just `UPROPERTY(EditAnywhere)` and
  designers drag-and-drop — **humans tweak numbers in the editor without
  touching code**.
- ⚠ **Data Asset instances are shared by default:** two Actors referencing the
  same `DA_GoblinStats` share ONE runtime object; mutating `Stats->Hp` on one
  leaks to the other. Data assets are read-only at runtime — need a private copy
  → `DuplicateObject` at construction time.
- Don't promote every config to a Data Asset class — for 2–3 variables plain
  `UPROPERTY(EditAnywhere)` is usually enough.

## 5. Subsystems = services, NOT a variable store

- GameInstance Subsystems hold no gameplay state (global variables) — the root
  of test leaks, init-order dependencies and state surviving level changes
  undisciplined.
- An EventBus subsystem (e.g. `UGameEventsSubsystem`) only declares delegates and
  is used only for **truly cross-cutting** events (game_over, level_changed).
  Everything else uses principle 2.
- **Auto-tests must reset the bus between tests** — subsystems persist across
  tests; delegate bindings leak from one test into the next without cleanup.

## 6. C++ / Blueprint split (agent-writable vs editor-only)

| Layer | Where | Why |
|---|---|---|
| Gameplay logic, math, data model | **C++** (`Source/<Game>/`) | text → agent-writable, reviewable diff, headless-testable |
| Content wiring, visuals, BP-level tuning | **Blueprint** (editor / MCP tools) | the editor's strength; humans see & tweak it |
| Anything the agent must create without a running editor | C++ first, asset later | the agent never blocks on `.uasset` (§0b) |

- Expose knobs with `UPROPERTY(EditAnywhere, BlueprintReadWrite, Category="...")`
  so Blueprints/designers tune without code changes.
- A feature counts as `dev_done` when its C++ compiles + auto-tests pass, with
  editor-only gaps listed as `TODO(dev):` — not when every asset exists.

## Code review checklist (agent + dev)

- [ ] Does it compile? (`Build.bat <Game>Editor Win64 Development -project=...`)
- [ ] Do the automation tests pass? (`Automation RunTests <Filter>` with `-nullrhi`)
- [ ] Any component crawling upward into owner/siblings?
- [ ] Pure logic stuck inside an Actor/Tick? (move it to plain C++)
- [ ] Any runtime mutation of a shared Data Asset?
- [ ] Does a subsystem hold state variables? Do tests reset the bus?
- [ ] Open the editor: do class/asset names + folder layout explain themselves?
- [ ] Binary (`.uasset`) changes described in §Changelog — diff is meaningless on them?
