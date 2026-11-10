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

## 7. Unreal Gameplay Framework & runtime standards (UE5 baseline)

> Added 2026-11 from production lessons (F-001 testmcp). These are the engine's
> own architecture rules — a project that violates them "works" until it doesn't.

### 7a. Framework roles — each class has exactly one job

| Class | Role | In this game (example) |
|---|---|---|
| **GameMode** (server-only) | Referee: rules, score, win/lose, spawns players & ball | `BP_PongGameMode` |
| **GameState** | Match state replicated to everyone (timer, score) | needed only for multiplayer |
| **PlayerController** | The player's will: input, camera, UI/HUD, personal audio | `BP_MenuPlayerController` |
| **Pawn / Character** | The physical body: mesh, collision, animation | `BP_PongCamera`, paddles |
| **AIController** | The machine's brain: drives a Pawn (BT/Blackboard/StateTree) | an AI paddle's owner |

Don't blur roles: scoring in a Pawn, movement in the GameMode, input in an Actor
are all architecture bugs even when they run fine.

### 7b. RootComponent & movement (hard rule — cost us 3 fix rounds)

- The component that carries the **primary collision and moves physically must be
  the RootComponent** (a `StaticMeshActor`-parented BP gets this for free).
- Move the **Actor** (`AddActorWorldOffset` with sweep, `SetActorLocation`) or via
  a **MovementComponent** — never move a child mesh and then teleport the actor
  to catch up, never leave a SceneComponent root in front of a colliding mesh.
- 2D-on-a-plane gameplay (pong, top-down): **`bConstrainToPlane` + plane normal**
  on the movement component — corner hits can't launch the body off-plane.

### 7c. Event-driven, not polling (Tick discipline)

- **No searching or key-polling in Tick** (`GetActorOfClass`, `IsInputKeyDown`
  every frame is the anti-pattern — it worked at 1 ball and still cost FPS).
- Gameplay reacts via **events/delegates**: a GoalZone broadcasts; the GameMode
  listens and scores. Lower classes never `Cast` up to GameMode to push data —
  delegate up (see §2).
- **Timers over Tick-counting**: `SetTimerByFunctionName/ByEvent` for delays,
  cooldowns, periodic sweeps. A looping 3s timer beats a per-frame watchdog that
  races the very timer it guards.
- Turn Tick **off** (`PrimaryActorTick.bCanEverTick = false`) on anything that
  doesn't need per-frame work; a Tick that only forwards is a candidate for
  deletion.

### 7d. Enhanced Input (mandatory from UE 5.1+)

- `InputAction` (IA_*) defines the intent; `InputMappingContext` (IMC_*) binds
  keys/keys→modifiers (Negate for the minus direction). Never read raw keys
  (`IsInputKeyDown`) in shipped gameplay — polling was an MCP-tooling workaround
  in F-001, not a pattern to copy.
- Enable the IMC on the pawn/controller that owns input; clean input mode +
  cursor when handing off to another level (a menu that doesn't unhook leaves the
  next level keyboard-dead).

### 7e. UMG for UI — PrintString is a debug log, never a UI

- Any player-facing text lives in a **Widget Blueprint** added to the viewport;
  update via **property binding** or delegates from GameState/PlayerState — the
  widget pulls state, actors don't push strings into widgets.
- Menu ↔ game handoff: `SetInputMode_UIOnly/GameOnly` + `bShowMouseCursor` +
  `RemoveFromParent` before `OpenLevel` (all of it, every time).

### 7f. No magic numbers

Every tunable (speeds, scores, camera height, clamp ranges) is an
`EditAnywhere` variable / Data Asset (§4) — never a literal inside a graph
formula. If a number appears twice, it becomes a variable.

## 8. Senior Blueprint Graph Architecture & Hygiene

> Blueprints are compiled to bytecode and run on Unreal's VM. Bad Blueprint
> practices ruin frame time and cause massive memory bloat via asset reference trees.
> Senior engineers treat Blueprints with the exact same rigor as C++.

### 8a. Memory & Reference Hygiene — the Size Map trap

- **Hard Object References vs Soft References (`TSoftObjectPtr`, `TSoftClassPtr`):**
  - A variable of type `BP_HeavyCharacter` or a `Cast to BP_HeavyCharacter` inside
    a HUD Widget creates a **synchronous hard dependency**. Loading that HUD
    forces the engine to load the character mesh, textures, audio, anim BP, and
    all attached weapons into memory immediately!
  - Check the **Reference Viewer** / **Size Map** in the editor: if a small UI or
    data asset pulls in hundreds of megabytes, you have a hard reference leak.
  - **Solution:**
    - Use **Blueprint Interfaces (`BPI_`)** for cross-actor communication — zero hard
      asset dependencies.
    - Use **Soft References** (`TSoftObjectPtr<T>`, `TSoftClassPtr<T>`) for heavy
      assets (weapons, skins, levels) and load asynchronously via `AsyncLoadAsset`
      or `FStreamableManager`.

### 8b. The Pure Function Re-Execution Trap (Green Nodes)

- **Pure functions (green nodes with no exec pin) have NO cache:**
  - Unreal executes a pure function **every single time** any of its output pins
    are read down the graph chain.
  - If a pure function performs a line trace, array loop, or math formula, and its
    result is wired to 4 subsequent nodes, **it runs 4 separate times** in that single frame!
- **Rule:**
  - Never put loops, traces, or expensive calculations in a Pure function.
  - When calling a pure node whose output is needed more than once: promote/set it
    to a **Local Variable** first, then read that local variable.
  - If a function has non-trivial cost, make it **Impure** (with exec pins) so it
    runs exactly once.

### 8c. Cast vs Blueprint Interface vs Cached Pointer

- **Avoid frequent casting:**
  - `Cast To` creates a compile-time hard dependency and incurs execution overhead.
  - **Never cast inside Event Tick or tight loops.**
  - If an Actor needs a typed reference: cast **once** in `BeginPlay` (or on setup),
    store the typed pointer in a variable, and check `IsValid` before using.
- **Interfaces (`BPI_`) are king for gameplay decoupling:**
  - Interactions (`IInteractable`), damage dispatch (`IDamageable`), UI data feeds
    (`IPlayerHUDProvider`) should be Blueprint Interfaces.
  - Calling an interface message on an Actor that doesn't implement it is a safe no-op
    and creates zero asset dependencies.

### 8d. Construction Script Boundaries (Pure Setup Only)

- The **Construction Script** runs in the editor viewport every time the Actor is
  moved, rotated, or any property is changed in the Details panel.
- **Strictly forbidden in Construction Script:**
  - Spawning other Actors (`SpawnActor`).
  - Starting Timers or triggering Async operations.
  - Binding Event Dispatchers or delegates.
  - Modifying global game state or touching GameMode/GameState.
- **Permitted in Construction Script:**
  - Creating and assigning Dynamic Material Instances (`CreateDynamicMaterialInstance`).
  - Swapping static meshes based on `EditAnywhere` enums/flags.
  - Procedural spline mesh generation for level dressing.

### 8e. Flow Control: Functions vs Macros vs Collapsed Graphs

- **Functions (`UFUNCTION` in C++, or BP Function):**
  - Has its own local variables, call stack, and memory frame.
  - Supports recursion, can be overridden by child Blueprints.
  - Best for encapsulated operations, calculations, and interface implementations.
- **Macros:**
  - Inline expansion (compiler pastes graph nodes at call site).
  - Can have **multiple execution inputs/outputs** (e.g. `Branch`, custom loops).
  - No local variables (shares macro parent's scope), **cannot be recursive**.
  - Keep macros small and reusable; don't bury complex game logic inside deep macros.
- **Collapsed Graphs:**
  - Pure visual grouping in the editor graph to declutter wires. No execution or
    scope difference whatsoever.

### 8f. Event Dispatcher & Delegate Lifecycle Management

- When an Actor or Widget binds to an Event Dispatcher, it creates a reference.
- **Always unbind or clear bindings** when the object is destroyed or removed:
  - UMG Widgets: unbind in `Destruct` or `RemoveFromParent`.
  - Actors: unbind in `EndPlay`.
- Leaving dangling delegate bindings leads to callbacks executing on dying/stale
  objects, phantom state bugs, and garbage collection prevention (memory leaks).

---

## 9. UE5 Asset & Folder Standards (Epic Games Style Guide)

> A clean project structure allows human developers, testers, and AI agents to
> instantly find assets and understand their type without opening them.

### 9a. Standard Directory Layout

All project content lives under a dedicated root game folder (never dump directly
into `/Content/` root):

```
/Content/<ProjectName>/
  ├── Core/             # GameMode, GameState, PlayerController, GameInstance
  ├── Characters/       # Meshes, AnimBPs, Character Blueprints
  ├── Data/             # DataAssets (DA_), DataTables (DT_), Curves
  ├── Input/            # InputActions (IA_), InputMappingContexts (IMC_)
  ├── UI/               # Widget Blueprints (WBP_), HUD textures, fonts
  ├── Environment/      # Maps/Levels (.umap), StaticMeshes (SM_), Materials
  ├── Audio/            # MetaSounds (MS_), Sound Cues (SC_), Sound Waves (S_)
  └── VFX/              # Niagara Systems (NS_), Emitters (NE_)
```

### 9b. Standard Asset Prefixes (UE5 Canonical)

| Asset Type | Prefix | Example |
|---|---|---|
| Blueprint Class | `BP_` | `BP_PlayerCharacter` |
| Widget Blueprint (UMG) | `WBP_` | `WBP_HealthBar` |
| Blueprint Interface | `BPI_` | `BPI_Interactable` |
| Blueprint Component | `BPC_` | `BPC_HealthComponent` |
| Enumeration | `E_` | `E_WeaponType` |
| Structure | `F_` (C++) / `S_` (BP) | `F_ItemData` |
| Primary Data Asset / Data Asset | `DA_` | `DA_PistolStats` |
| Data Table | `DT_` | `DT_WeaponBalancing` |
| Input Action | `IA_` | `IA_Jump`, `IA_Move` |
| Input Mapping Context | `IMC_` | `IMC_Default` |
| Master Material | `M_` | `M_HeroBase` |
| Material Instance | `MI_` | `MI_HeroRed` |
| Material Function | `MF_` | `MF_FoliageWind` |
| Texture | `T_` | `T_Hero_D` (Diffuse), `T_Hero_N` (Normal) |
| Static Mesh | `SM_` | `SM_DoorFrame` |
| Skeletal Mesh | `SK_` or `SKM_` | `SKM_Hero` |
| Animation Blueprint | `ABP_` | `ABP_Hero` |
| Animation Montage | `AM_` | `AM_SwordAttack_01` |
| Niagara System | `NS_` | `NS_MuzzleFlash` |
| MetaSound / Sound Cue | `MS_` / `SC_` | `MS_EngineSound`, `SC_Explosion` |

---

## 10. UE5 Performance, Memory & Compilation Engineering

### 10a. Advanced Tick & Timer Engineering

- **Ticking is off by default:**
  - `PrimaryActorTick.bCanEverTick = false;` in constructor.
  - If a component or actor needs per-frame logic, question whether a timer or
    event can do it instead.
- **Tick Intervals & Tick Groups:**
  - If ticking is genuinely required (e.g. an AI distance check or health regeneration):
    set `PrimaryActorTick.TickInterval = 0.1f;` (10 times/sec instead of 60–120 times/sec).
  - Use `TickGroup` deliberately:
    - `TG_PrePhysics`: input, player movement.
    - `TG_PostPhysics`: camera updates, HUD tracking physical objects (avoids 1-frame jitter).
- **Timers:**
  - Always use `FTimerHandle` with `GetWorldTimerManager().SetTimer(...)`.
  - Clear active timers in `EndPlay()` to avoid firing after actor death.

### 10b. Collision Channel & Overlap Optimization

- Never use `BlockAll` or `OverlapAllDynamic` as a lazy fix.
- Create custom **Object Channels** (e.g. `Projectile`, `Pickup`) and **Trace Channels**
  (e.g. `WeaponTrace`, `InteractTrace`) in `Config/DefaultEngine.ini`.
- Disable collision completely (`SetCollisionEnabled(ECollisionEnabled::NoCollision)`)
  on purely decorative visual meshes.
- Turn off **`Generate Overlap Events`** on any mesh/component that does not actively
  need to trigger `OnComponentBeginOverlap`. Having overlap enabled on hundreds of
  static meshes chokes physics engine broadphase.

### 10c. Fast C++ Compilation Hygiene (Keep agent compile sub-minute)

- **Header Include Hygiene:**
  - In `.h` files: **always use forward declarations** (`class APlayerCharacter;`,
    `class UStaticMeshComponent;`, `struct FGameplayTag;`) instead of `#include`.
  - Never `#include "Engine.h"`. Only include `#include "CoreMinimal.h"`, the base
    class header, and the `.generated.h` (always last).
  - Put full `#include "PlayerCharacter.h"` in `.cpp` files only.
  - This keeps compile turnaround fast for both developer and headless agent checks.
- **`UPROPERTY()` Garbage Collection Semantics:**
  - Any raw `UObject*` pointer stored on an Actor/Component without `UPROPERTY()`
    is **invisible to the Unreal Garbage Collector** and will be freed out from
    under you, leading to wild crashes.
  - If you hold a pointer to another object you do NOT own, use `TWeakObjectPtr<T>`
    or decorate with `UPROPERTY()` so the engine handles cleanup safely.

---

## 11. Multiplayer & Authority Preparedness (Even in SP)

> Writing single-player code that completely ignores authority makes multiplayer
> refactoring an impossible rewrite later. Senior engineers build with authority
> boundaries from day one.

- **Authority Discipline (`HasAuthority()`):**
  - Game state modification (damage, score, inventory, spawning items/enemies)
    must execute exclusively on the Authority (`HasAuthority()` == true).
  - Clients send player intent (e.g. via Enhanced Input → Server RPC).
- **Framework Lifetimes across Network:**
  - `GameMode`: Exists **only on the server**. Never attempt to read GameMode on a client.
  - `GameState`: Replicated to all clients. Use this for replicated match state (timer, score).
  - `PlayerController`: Exists on the server for all players, but on a client **only for the local player**.
  - `PlayerState`: Replicated to all clients. Holds persistent player data (name, ping, score, kills)
    that survives Pawn deaths and respawns.
- **Cosmetics vs Simulation:**
  - Simulation (math, traces, cooldowns) = Authority.
  - Audio, Niagara effects, screen shakes, UI animations = Client (triggered via
    RepNotify or NetMulticast).

---

## Code review checklist (agent + dev)

- [ ] Does it compile? (`Build.bat <Game>Editor Win64 Development -project=...`)
- [ ] Do the automation tests pass? (`Automation RunTests <Filter>` with `-nullrhi`)
- [ ] Any component crawling upward into owner/siblings? (§2)
- [ ] Pure logic stuck inside an Actor/Tick? (move it to plain C++ or subsystem) (§3)
- [ ] Any runtime mutation of a shared Data Asset? (§4)
- [ ] Does a subsystem hold state variables? Do tests reset the bus? (§5)
- [ ] Framework roles respected — score in GameMode, input in Controller, physics in Pawn? (§7a)
- [ ] Primary collision/moving component is the RootComponent? No mesh-move + teleport-actor hacks? (§7b)
- [ ] Tick clean — `bCanEverTick = false` where possible? No per-frame searching/polling/key reads? Timers/delegates instead? (§7c, §10a)
- [ ] Enhanced Input assets in use, no raw `IsInputKeyDown` in shipped paths? (§7d)
- [ ] Player-facing text in UMG (not PrintString)? Input mode/cursor handed off cleanly between levels? (§7e)
- [ ] No magic numbers in graphs — everything tunable is `EditAnywhere` or Data Asset? (§7f)
- [ ] **Blueprint hygiene (§8):** No hard reference size map explosions? Interfaces used for cross-actor calls? No loops/traces in Pure Functions? Construction Script free from side-effects/spawns?
- [ ] **Asset naming & layout (§9):** Standard prefixes used (`BP_`, `WBP_`, `DA_`, `IA_`, `IMC_`...)? Folder placed inside `/Content/<GameName>/`?
- [ ] **Performance & compilation (§10):** Forward declarations used in headers? Collision channels customized and unneeded overlap events disabled?
- [ ] **Authority respected (§11):** Gameplay mutations gated by `HasAuthority()`?
- [ ] Open the editor: do class/asset names + folder layout explain themselves?
- [ ] Binary (`.uasset`) changes described in §Changelog — diff is meaningless on them?
