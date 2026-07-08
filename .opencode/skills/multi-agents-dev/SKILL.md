---
name: multi-agents-dev
description: >
  Use when the orchestrator agent in tmux pane main:0.0 receives a high-level
  feature requirement and must route work across panes. Triggers on phrases like
  "implement feature", "build", "add support for", or any task requiring design +
  coding + review across multiple agents.
  DO NOT trigger for: single-file edits, questions, explanations, or debugging
  sessions that don't require multi-pane coordination.
compatibility: Requires tmux session "main" with panes 0.0–0.4 and dispatch.sh installed.
---

# Multi-Agents Dev — Orchestrator Guide

## Your Role

You are the **router** in `main:0.0`. Your only job is to send messages to the right pane at the right time using `dispatch.sh`. You do not write code, answer questions from other panes, or check on worker progress.

## Pane Map

| dispatch.sh agent   | Pane       | Role                                              |
|---------------------|------------|---------------------------------------------------|
| `orchestrator`      | `main:0.0` | **YOU** — route only                              |
| `implementer`       | `main:0.1` | TDD for easy tasks (complexity 1)                 |
| `implement_complex` | `main:0.2` | TDD for complex tasks (complexity ≥ 2)            |
| `Cursor`            | `main:0.3` | Brainstorming, writing plans, code review         |
| `ops`               | `main:0.4` | Git worktree setup, per-task review               |

## Invocation

| Command | Behavior |
|---------|----------|
| `/multi-agents-dev` | Full pipeline: Startup → Steps 1–5 |
| `/multi-agents-dev <design_path> <plan_path>` | Skip steps 1 and 3; set `DESIGN_PATH` and `PLAN_PATH`, then run steps 2 → 4 → 5 |

## State Variables

Set these as shell variables in your session. Do not guess their values.

| Variable       | Set when             | Used in       |
|----------------|----------------------|---------------|
| `REQUIREMENT`  | Startup (from user)  | Step 1        |
| `DESIGN_PATH`  | Step 1 signal        | Step 3        |
| `FEATURE_NAME` | Step 2               | Steps 2, 5    |
| `PLAN_PATH`    | Step 3 signal        | Steps 4, 5    |

## Execution Order

Open and execute **one step file at a time**. Do not open the next step file until you see the exact completion signal.

```
Startup → Step 1 → [signal] → Step 2 → [signal] → Step 3 → [signal] → Step 4 → [signal] → Step 5
```

| Step | File | Completion signal (exact substring match) |
|------|------|-------------------------------------------|
| 1 | [steps/01-brainstorming.md](steps/01-brainstorming.md) | `brainstorm step finished` |
| 2 | [steps/02-using-git-worktrees.md](steps/02-using-git-worktrees.md) | `using-git-worktress step finished` |
| 3 | [steps/03-writing-plans.md](steps/03-writing-plans.md) | `writing plan step finished` |
| 4 | [steps/04-subagent-driven-development.md](steps/04-subagent-driven-development.md) | `task <N> review finished` (all tasks, no defects) |
| 5 | [steps/05-requesting-code-review.md](steps/05-requesting-code-review.md) | `code review finished, status: pass` |

## Dispatch Rules (outcome-based)

**Rule A — A step is complete only when its completion signal appears in your pane.**
Do not infer completion from silence, elapsed time, or apparent context. Do not run `capture-pane` or `sleep` to poll for it.

**Rule B — Do not implement, review, or fix code.**
If an implementer reports a defect, re-dispatch a defect report via `dispatch.sh implementer` per Step 4 instructions. Do not fix it yourself.

**Rule C — Use `dispatch.sh` for all pane messages.**
Raw `tmux send-keys` is allowed only for `BTab` pane-focus commands. `dispatch.sh` sends `C-m` automatically — never add it manually.

**Rule D — Always include callback instructions in the same dispatch message.**
Workers only see the message you send. If you split work and callback into two messages, the worker will not know to report back.

```bash
# CORRECT — work + callback in one message
dispatch.sh implementer "implement X | when done: dispatch.sh orchestrator \"task done\""

# WRONG — callback omitted
dispatch.sh implementer "implement X"
```

**Rule E — Do not answer questions from `main:0.1`–`main:0.4`.**
The user handles those directly. Your session receives worker signals only.


## Gotchas

- **Step 2 git worktree** — always run `git status` before assuming the worktree is ready. Do not skip this check.
- **Complexity routing** — use `implementer` for complexity 1 tasks, `implement_complex` for complexity ≥ 2. Routing the wrong pane causes silent failures.
- **Startup** — copy the user's requirement verbatim into `REQUIREMENT` before opening Step 1. Do not paraphrase.

## Startup

Run from project root before opening Step 1:

```bash
REQUIREMENT="<paste user requirement verbatim here>"
```

The read and refresh yourself Dispatch Rules (outcome-based) Rule A 

Then open [steps/01-brainstorming.md](steps/01-brainstorming.md).
