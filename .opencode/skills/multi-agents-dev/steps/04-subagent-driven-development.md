# Step 4 — Subagent-Driven Development

**Prerequisite:** `PLAN_PATH` is set from Step 3.

**Completion condition:** every task in the plan has been implemented (Step 4A) and reviewed with no open defects (Step 4B).

**On complete:** open `steps/05-requesting-code-review.md`

---

Use `dispatch.cmd` for all pane messages. **DO NOT** use raw `tmux send-keys`. Combine work and callback in **one** `dispatch.cmd` — do not split into separate messages unless a prior TODO must complete first.

## Fixed mapping (do not deviate)

| subagent-driven-development says | dispatch.cmd agent |
|----------------------------------|-------------------|
| implementer subagent (complexity 1) | `implementer` |
| implement_complex subagent (complexity ≥ 2) | `implement_complex` |
| task reviewer subagent | `ops` |

**DO NOT** use Task tool. **DO NOT** spawn subagents. **DO NOT** implement code yourself.

---

## TODO 0 — load plan (orchestrator only, no dispatch)

Execute in your own session (pane `main:0.0`):
```
/skills subagent-driven-development to develop the plan: <PLAN_PATH>
```

Read the plan. Count tasks. Set `TASK_COUNT` = number of tasks. Set `CURRENT_TASK` = 1.

**DO NOT** dispatch this command to any other tmux pane.

---

## Per-task loop

Repeat the block below for `CURRENT_TASK` = 1, 2, 3, … up to `TASK_COUNT`. Replace `<N>` with `CURRENT_TASK`.

### Complexity-based routing rule

For each task `<N>`, read its complexity in the plan:

| Complexity | Dispatch agent | Pane |
|------------|---------------|------|
| 1 (easy) | `implementer` | `main:0.1` |
| ≥ 2 (complex) | `implement_complex` | `main:0.2` |
| Not mentioned | Orchestrator decides: easy → `implementer`, otherwise → `implement_complex` |

Set `IMPL_AGENT` to the chosen agent before dispatching.

### Step 4A — dispatch implementer

**TODO 4A-0** — new session:
```
dispatch.cmd $IMPL_AGENT "/new"
```

**TODO 4A-1** — worker dispatch prompt; execute command EXACTLY (replace `<PLAN_PATH>` and `$IMPL_AGENT`):
```
dispatch.cmd $IMPL_AGENT "/test-driven-development refer to <PLAN_PATH>, implement task <N> in dev/<FEATURE_NAME> branch | TODO: 1) Read task <N> in plan; follow implementer-prompt.md in subagent-driven-development. 2) Implement task <N> yourself (TDD). 3) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> implement finished, status: STATUS, summary: SUMMARY\" — STATUS=pass or fail, SUMMARY=brief result. | AVOID: - DO NOT assign to sub-agents or Task tool - DO NOT skip TODO 3 - DO NOT stop before TODO 3 succeeds"
```

**TODO 4A-2** — STOP. Wait for completion signal containing `task <N> implement finished`.

- IF implementer asks a question → answer it in your session (only step where you answer implementer questions)
- IF signal received → proceed to Step 4B
- DO NOT proceed to Step 4B before signal received

#### Worker Completion 4A

The implementing pane (`implementer` or `implement_complex` depending on task) must execute:

```
dispatch.cmd orchestrator "STATUS UPDATE - task <N> implement finished, status: <pass|fail>, summary: <summary>"
```

### Step 4B — dispatch reviewer

**TODO 4B-1** — worker dispatch prompt; execute command EXACTLY (replace `<PLAN_PATH>`):
```
dispatch.cmd ops "refer to <PLAN_PATH>, review task <N> | TODO: 1) Read task <N> in plan; follow task-reviewer-prompt.md in subagent-driven-development. 2) Review implementation; if issues, write defect report only (no fixes). 3) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> review finished, status: STATUS, summary: SUMMARY\" — STATUS=pass or defects, SUMMARY=result or defect report. | AVOID: - DO NOT fix code - DO NOT spawn sub-agents - DO NOT assign review to Task tool - DO NOT skip TODO 3"
```

**TODO 4B-2** — STOP. Wait for completion signal containing `task <N> review finished`.

- IF ops asks a question → answer it in your session (only step where you answer ops questions)
- IF signal contains `status: pass` → set `CURRENT_TASK` = `CURRENT_TASK` + 1. IF `CURRENT_TASK` <= `TASK_COUNT` → repeat from Step 4A. IF `CURRENT_TASK` > `TASK_COUNT` → Step 4 complete, open Step 5.
- IF signal contains `status: defects` → go to Step 4C (do not increment `CURRENT_TASK`)

#### Worker Completion 4B (main:0.4)

```
dispatch.cmd orchestrator "STATUS UPDATE - task <N> review finished, status: <pass|defects>, summary: <summary or defect report>"
```

#### Worker Questions (main:0.4 → orchestrator)

```
dispatch.cmd orchestrator "<question>"
```

### Step 4C — fix loop (only when reviewer reports defects)

**TODO 4C-1** — worker dispatch prompt; execute command EXACTLY (replace defect report text):
```
dispatch.cmd $IMPL_AGENT "fix defects for task <N>  in dev/<FEATURE_NAME> branch | TODO: 1) Fix only these defects: <defect/issue report text from reviewer>. 2) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> fix finished, summary: SUMMARY\" — SUMMARY=what you fixed. | AVOID: - DO NOT change unrelated code - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 4C-2** — STOP. Wait for completion signal containing `task <N> fix finished`.

**TODO 4C-3** — go back to Step 4B (re-review same `CURRENT_TASK`, do not increment)

#### Worker Completion 4C

The implementing pane (`implementer` or `implement_complex` depending on task) must execute:

```
dispatch.cmd orchestrator "STATUS UPDATE - task <N> fix finished, summary: <summary>"
```

---

## FORBIDDEN in this step

- DO NOT IMPLEMENT CODE
- DO NOT use raw `tmux send-keys` — use `dispatch.cmd` only
- DO NOT split 4A-1, 4B-1, or 4C-1 into separate work and callback dispatches
- DO NOT omit callback instructions from 4A-1, 4B-1, or 4C-1
- DO NOT dispatch TODO 0 to any pane other than yourself
- DO NOT use Task tool for implement or review
- DO NOT let ops agent fix issues — only defect reports
- DO NOT increment `CURRENT_TASK` while defects are open
- DO NOT open Step 5 until all tasks pass review with no open defects
