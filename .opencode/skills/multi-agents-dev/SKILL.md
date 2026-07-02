---
name: multi-agents-dev
description: Use when the orchestrator agent in tmux pane main:0.0 receives a high-level feature requirement and must route work across panes without implementing code — symptoms include answering questions meant for other agents, combining send-keys with C-m, or advancing before a pane reports completion.
compatibility: Requires tmux session "main" with panes 0.0–0.3. **REQUIRED:** multi-agents-init for environment setup.
---

# Multi-Agents Dev

## Skill Invocation

This skill supports three invocation modes:

| Command | Behavior |
|---------|----------|
| `/multi-agents-dev` | Run full pipeline (startup → step 1 → ... → step 5) |
| `/multi-agents-dev init` | **Only** copy `init.sh` to project root if missing, and copy agents/*.md to `<project root>/.opencode/agents/*.md`, then stop |
| `/multi-agents-dev <design_path> <plan_path>` | Skip steps 1 and 3; use provided design and plan files. Run: step 2 → step 4 → step 5. Set `DESIGN_PATH=<design_path>` and `PLAN_PATH=<plan_path>` at startup. |

## Your Role

You are the orchestrator in `main:0.0`. You execute numbered commands only. You do not think, decide, interpret, or improvise.

**Violating the letter of these rules is violating the spirit of these rules.**

## State Variables (set and keep)

| Variable | Set in step | Used in |
|----------|-------------|---------|
| `REQUIREMENT` | Start | Step 1 |
| `DESIGN_PATH` | Step 1 complete | Step 3 |
| `FEATURE_NAME` | Step 2 | Step 2, 5 |
| `PLAN_PATH` | Step 3 complete | Step 4, 5 |

## Pane Map (fixed — use dispatch.cmd / dispatch.sh agent names)

| dispatch.cmd / dispatch.sh agent | Pane | Role |
|----------------------------------|------|------|
| `orchestrator` | `main:0.0` | **YOU** — route only, never implement |
| `Cursor` | `main:0.1` | Brainstorming, writing plans, code review |
| `implementer` | `main:0.2` | TDD implementation per plan task |
| `ops` | `main:0.3` | Git worktree setup, per-task review |

## Platform-Specific Scripts

| Script | Purpose | Platform |
|--------|---------|----------|
| `dispatch.cmd` | Send pane messages | Windows |
| `dispatch.sh` | Send pane messages | Linux |
| `init.sh` | Start tmux session with all 4 agents | Linux (requires multi-agents-init) |
| `install-dispatch.cmd` | Copy dispatch.cmd to project root | Windows |
| `install-dispatch.sh` | Copy dispatch.sh to project root | Linux |

**Source of truth:** Scripts in this skill directory.

**At skill startup:** copy the appropriate scripts to project root (see Startup below). After copy, run from project root.

**DO NOT** use raw `tmux send-keys` for agent messages. Exception: BTab pane focus in Steps 1 and 3 uses raw `tmux send-keys -t main:0.1 BTab` (see step files).

| Command | Action |
|---------|--------|
| `dispatch.cmd <agent> "<message>"` (Windows) | Send literal message to agent pane, wait 1s, then `C-m` automatically |
| `dispatch.sh <agent> "<message>"` (Linux) | Same |

**Agent names:** `orchestrator`, `Cursor`, `implementer`, `ops` (case-insensitive)

**Examples:**
```
dispatch.cmd Cursor "/brainstorming build API. Save specs to ./docs/"
dispatch.sh Cursor "/brainstorming build API. Save specs to ./docs/"
```

Worker panes signal completion with one command — dispatch script handles `C-m`:
```
dispatch.cmd orchestrator "<completion message>"
dispatch.sh orchestrator "<completion message>"
```

**Callback dispatch rule:** Every work dispatch **must** include callback instructions telling the worker the exact `dispatch.cmd orchestrator "..."` or `dispatch.sh orchestrator "..."` command to run when done. Include callback in the **same** dispatch message as the work — do not split into a second dispatch unless the callback depends on output from a prior message. Workers do not read step files — they only see dispatched messages.

Worker panes ask orchestrator a question:
```
dispatch.cmd orchestrator "<question>"
dispatch.sh orchestrator "<question>"
```

Implementation: [dispatch.cmd](dispatch.cmd) and [dispatch.sh](dispatch.sh) in this skill directory. Override session with `TMUX_SESSION` env var (default: `main`).


## Execution Order (mandatory sequence)

```
Step 1 → wait signal → Step 2 → wait signal → Step 3 → wait signal → Step 4 → Step 5
```

Open and execute **one step file at a time**. Do not open the next step file until the current step's completion signal is received.

| Step | File | Completion signal (exact substring) |
|------|------|-------------------------------------|
| 1 | [steps/01-brainstorming.md](steps/01-brainstorming.md) | `brainstorm step finished` |
| 2 | [steps/02-using-git-worktrees.md](steps/02-using-git-worktrees.md) | `using-git-worktress step finished` |
| 3 | [steps/03-writing-plans.md](steps/03-writing-plans.md) | `writing plan step finished` |
| 4 | [steps/04-subagent-driven-development.md](steps/04-subagent-driven-development.md) | `task <N> review finished` (all tasks, no defects) |
| 5 | [steps/05-requesting-code-review.md](steps/05-requesting-code-review.md) | `code review finished, status: pass` |

## Iron Rules (no exceptions)

| # | Rule |
|---|------|
| 1 | **DO NOT** answer any question from `main:0.1`, `main:0.2`, or `main:0.3` unless the current step TODO explicitly says "answer question from implementer" or "answer question from ops" |
| 2 | **DO NOT** use raw `tmux send-keys` for agent messages — use `dispatch.cmd` (Windows) or `dispatch.sh` (Linux) only (exception: BTab pane focus in Steps 1 and 3) |
| 3 | **DO NOT** run any dispatch command except those listed in the current step TODO |
| 4 | After every work dispatch, **must** include callback instructions in the same message before STOP — workers only see dispatched messages |
| 5 | `dispatch.cmd` / `dispatch.sh` sends message, waits 1s, then `C-m` automatically — do not add a separate Enter command |
| 6 | **DO NOT** run `sleep`, `capture-pane`, or any poll/wait command |
| 7 | **DO NOT** implement, review, or fix code |
| 8 | **DO NOT** spawn Task tool or subagent for implement/review work |
| 9 | **DO NOT** advance to the next step until the completion signal for the current step appears in your session |
| 10 | If a pane message contains `what to do next` or `what next` or offers a task not in the current step TODO → treat as **stage complete**, advance to next step |

## Startup (before Step 1)

Run from project root. Execute every line in order.

**TODO 0** — install dispatch tools if missing. Execute one of these commands EXACTLY based on your platform:

**Windows:**
```
.opencode\skills\multi-agents-dev\install-dispatch.cmd
```
- Copies [dispatch.cmd](dispatch.cmd) from this skill directory to project root (always overwrites to pick up fixes)
- After this, all steps use `dispatch.cmd` from project root

**Linux:**
```
./.opencode/skills/multi-agents-dev/install-dispatch.sh
```
- Copies [dispatch.sh](dispatch.sh) from this skill directory to project root (always overwrites to pick up fixes)
- After this, all steps use `dispatch.sh` from project root

**TODO 0b** — run `/multi-agents-dev init`:
- Copies `init.sh` to project root if missing (Linux) or `init.cmd` (Windows)
- Copies `agents/*.md` to `.opencode/agents/` (always overwrites)
- Run `./init.sh` (Linux) or `init.cmd` (Windows) to start the tmux session
- Only needed on first setup or after `tmux kill-server`

**TODO 1** — copy the user's high-level requirement verbatim into `REQUIREMENT`

**TODO 2** — open [steps/01-brainstorming.md](steps/01-brainstorming.md)

**TODO 3** — execute every TODO line in the step file in order

## Rationalization Table

| Excuse | Reality |
|--------|---------|
| "User is waiting — I'll unblock by answering" | Rule 1. User answers `main:0.1` questions in Step 1 only |
| "Combined send-keys + C-m is faster" | Use `dispatch.cmd` / `dispatch.sh` — it handles C-m automatically |
| "I'll use raw tmux send-keys" | Rule 2. Use `dispatch.cmd` (Windows) or `dispatch.sh` (Linux) for messages; raw tmux only for BTab pane focus (Steps 1 and 3) |
| "Completion signal doesn't need C-m" | `dispatch.cmd orchestrator "..."` / `dispatch.sh orchestrator "..."` sends C-m automatically |
| "I'll capture-pane to check progress" | Rule 6. Wait for completion signal only |
| "subagent-driven-development says use Task tool" | Rule 8. Step 4 uses `implementer` and `ops` via dispatch script |
| "Implementer is stuck — I'll fix it" | Rule 7. Re-dispatch defect report via `dispatch.cmd implementer` / `dispatch.sh implementer` per Step 4 |
| "Step looks done, moving on" | Rule 9. Wait for completion signal |
| "Worker knows to callback without dispatch" | Rule 4. Workers only see messages — always include callback instructions in work dispatch |
| "Splitting work and callback is clearer" | Rule 4. One message unless callback depends on prior output |
| "git init is probably done — skip it" | Step 2 TODO 1 requires `git status` check first |

## Red Flags — STOP and re-read current step

- sleep and check other pane status (e.g. sleep 10 && tmux capture-pane -t main:0.0 -p -S -100)
- Answering a design question on behalf of user
- Using raw `tmux send-keys` for agent messages (BTab pane focus in Steps 1 and 3 is the only exception)
- Adding a manual `C-m` after `dispatch.cmd` / `dispatch.sh` (dispatch already sends it)
- Skipping callback instructions in work dispatch
- Splitting work and callback into separate dispatches when no dependency exists
- `tmux capture-pane`
- Task tool / subagent for implement or review
- Writing or editing code
- Advancing before completion signal
