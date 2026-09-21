---
# ── Structured handoff ─────────────────────────────────────────────
# Rule: every field is a "logged fact". A resuming agent/dev can ONLY read
# from here — never keep state in the conversation (model-visible ⟺ logged).
# Full schema: docs/WORKFLOW.md §"State discipline".
last_updated: "{{DATE}}"
phase: planned                 # planned | dev | paused | done
branch: main
handoff_kind: planned-next     # planned-next = just continue | pause = wait for a human decision
current_focus: none            # feature id being worked on, or "none"
next_action: "If the TEMPLATE file still exists at the root: this is the TEMPLATE — create a new game repo (copy the template + run bash scripts/init.sh '<Name>') instead of developing here. If already initialized: create <Name>.uproject at the repo root (C++ project: also the Source/ skeleton — docs/CODING.md §6; agent writes these as text, never opens the editor) + finalize the game description & milestone M0 in docs/ROADMAP.md, then create F-001."

# Evidence — work DONE in this session, with proof (commit/file).
# No evidence = considered not done. (Ralph-handoff: evidence field)
done: []

# Blockers — each line: '<what> (→ <condition to clear>)'. Empty = not stuck.
blockers: []

# Decisions waiting for a human (only required when handoff_kind: pause).
decisions_pending:
  - "Game description + milestone M0 not finalized yet (see docs/ROADMAP.md)"
---

# Session state — {{PROJECT_NAME}}

> **Read this file first.** This is the resume entry point for any AI/dev entering a session.
> Full workflow: `docs/WORKFLOW.md`.

## Quick resume
1. Read the frontmatter above: `current_focus` + `next_action` = the next piece of work.
2. `done:` = evidence of finished work; `blockers:` = what's stuck.
3. `handoff_kind: planned-next` → continue `next_action` right away.
   `handoff_kind: pause` → present `decisions_pending`, wait for a human decision first.

## Context (fits no field above)
- The repo has no `.uproject` yet — the first step is creating the project (see `docs/SETUP.md` for the engine path question).
