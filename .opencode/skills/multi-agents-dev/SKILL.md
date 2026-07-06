---
name: multi-agents-dev
description: Use when the orchestrator agent in tmux pane main:0.0 receives a high-level feature requirement and must route work across panes without implementing code — symptoms include answering questions meant for other agents, combining send-keys with C-m, or advancing before a pane reports completion.
compatibility: Requires tmux session "main" with panes 0.0–0.4.
---

# Multi-Agents Dev

## NEVER DO THIS (read before every step)

**Violating the letter of these rules is violating the spirit of these rules.**

| # | NEVER |
|---|-------|
| 1 | Answer any question from `main:0.1`, `main:0.2`, `main:0.3`, or `main:0.4` unless the current step TODO explicitly says "answer question from implementer" or "answer question from ops" |
| 2 | Use raw `tmux send-keys` for agent messages — use `dispatch.sh` only (exception: BTab pane focus in Steps 1 and 3) |
| 3 | Run any dispatch command except those listed in the current step TODO |
| 4 | Dispatch work without callback instructions in the same message — workers only see dispatched messages |
| 5 | Add a manual `C-m` after `dispatch.sh` — it handles C-m automatically |
| 6 | Run `sleep`, `capture-pane`, or any poll/wait command |
| 7 | Implement, review, or fix code |
| 8 | Spawn Task tool or subagent for implement/review work |
| 9 | Advance to the next step until the completion signal appears in your session |
| 10 | Skip `git status` check before assuming git worktree is ready (Step 2) |

## Rationalization Table

If you catch yourself thinking any of these, STOP — you are about to break a rule.

| Excuse | Reality |
|--------|---------|
| "User is waiting — I'll unblock by answering" | Rule 1. User answers `main:0.3` questions in Step 1 only |
| "Combined send-keys + C-m is faster" | Use `dispatch.sh` — it handles C-m automatically |
| "I'll use raw tmux send-keys" | Rule 2. Use `dispatch.sh` for messages; raw tmux only for BTab pane focus (Steps 1 and 3) |
| "Completion signal doesn't need C-m" | `dispatch.sh orchestrator "..."` sends C-m automatically |
| "I'll capture-pane to check progress" | Rule 6. Wait for completion signal only |
| "subagent-driven-development says use Task tool" | Rule 8. Step 4 uses `implementer` and `ops` via dispatch script |
| "Implementer is stuck — I'll fix it" | Rule 7. Re-dispatch defect report via `dispatch.sh implementer` per Step 4 |
| "Step looks done, moving on" | Rule 9. Wait for completion signal |
| "Worker knows to callback without dispatch" | Rule 4. Workers only see messages — always include callback instructions |
| "Splitting work and callback is clearer" | Rule 4. One message unless callback depends on prior output |
| "git init is probably done — skip it" | Step 2 TODO 1 requires `git status` check first |

## Your Role

You are the orchestrator in `main:0.0`. You execute numbered commands only. You do not think, decide, interpret, or improvise. You do not implement code.

## State Variables

| Variable | Set in step | Used in |
|----------|-------------|---------|
| `REQUIREMENT` | Start | Step 1 |
| `DESIGN_PATH` | Step 1 complete | Step 3 |
| `FEATURE_NAME` | Step 2 | Step 2, 5 |
| `PLAN_PATH` | Step 3 complete | Step 4, 5 |

## Pane Map

| dispatch.sh agent | Pane | Role |
|-------------------|------|------|
| `orchestrator` | `main:0.0` | **YOU** — route only, never implement |
| `implementer` | `main:0.1` | TDD implementation of **easy** tasks (complexity 1) |
| `implement_complex` | `main:0.2` | TDD implementation of **complex** tasks (complexity ≥ 2) |
| `Cursor` | `main:0.3` | Brainstorming, writing plans, code review |
| `ops` | `main:0.4` | Git worktree setup, per-task review |

## Skill Invocation

| Command | Behavior |
|---------|----------|
| `/multi-agents-dev` | Run full pipeline (startup → step 1 → ... → step 5) |
| `/multi-agents-dev <design_path> <plan_path>` | Skip steps 1 and 3; use provided design and plan files. Run: step 2 → step 4 → step 5. Set `DESIGN_PATH=<design_path>` and `PLAN_PATH=<plan_path>` at startup. |

## Execution Order (mandatory sequence)

```
Startup → Step 1 → wait signal → Step 2 → wait signal → Step 3 → wait signal → Step 4 → Step 5
```

### Startup (before Step 1)

Run from project root. Execute every line in order.

**TODO 0** — copy the user's high-level requirement verbatim into `REQUIREMENT`

### Step Files

Open and execute **one step file at a time**. Do not open the next step file until the current step's completion signal is received.

| Step | File | Completion signal (exact substring) |
|------|------|-------------------------------------|
| 1 | [steps/01-brainstorming.md](steps/01-brainstorming.md) | `brainstorm step finished` |
| 2 | [steps/02-using-git-worktrees.md](steps/02-using-git-worktrees.md) | `using-git-worktress step finished` |
| 3 | [steps/03-writing-plans.md](steps/03-writing-plans.md) | `writing plan step finished` |
| 4 | [steps/04-subagent-driven-development.md](steps/04-subagent-driven-development.md) | `task <N> review finished` (all tasks, no defects) |
| 5 | [steps/05-requesting-code-review.md](steps/05-requesting-code-review.md) | `code review finished, status: pass` |
