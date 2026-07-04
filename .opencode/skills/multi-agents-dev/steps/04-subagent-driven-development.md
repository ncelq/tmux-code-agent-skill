# Step 4 — Subagent-Driven Development

**Prerequisite:** `PLAN_PATH` is set from Step 3.

**Completion condition:** every task in the plan has been implemented (Step 4A) and reviewed with no open defects (Step 4B).

**On complete:** open `steps/05-requesting-code-review.md`

---

Use `dispatch.cmd` for all pane messages. **DO NOT** use raw `tmux send-keys`. Combine work and callback in **one** `dispatch.cmd` — do not split into separate messages unless a prior TODO must complete first.

## Fixed mapping (do not deviate)

| subagent-driven-development says | dispatch.cmd agent |
|----------------------------------|-------------------|
| implementer subagent | `implementer` |
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

### Step 4A — dispatch implementer

**TODO 4A-0** — new session:
```
dispatch.cmd implementer "/new"
```

**TODO 4A-1** — worker dispatch prompt; execute command EXACTLY (replace `<PLAN_PATH>`):
```
dispatch.cmd implementer "refer to <PLAN_PATH>, implement task <N> | TODO: 1) Read task <N> in plan; follow implementer-prompt.md in subagent-driven-development. 2) Implement task <N> yourself (TDD). 3) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> implement finished, status: STATUS, summary: SUMMARY\" — STATUS=pass or fail, SUMMARY=brief result. | AVOID: - DO NOT assign to sub-agents or Task tool - DO NOT skip TODO 3 - DO NOT stop before TODO 3 succeeds"
```

**TODO 4A-2** — STOP. Wait for completion signal containing `task <N> implement finished`.

- IF implementer asks a question → answer it in your session (only step where you answer `main:0.2` questions)
- IF signal received → proceed to Step 4B
- DO NOT proceed to Step 4B before signal received

#### Worker Completion 4A (main:0.2)

```
dispatch.cmd orchestrator "STATUS UPDATE - task <N> implement finished, status: <pass|fail>, summary: <summary>"
```

### Step 4B — dispatch reviewer

**TODO 4B-1** — worker dispatch prompt; execute command EXACTLY (replace `<PLAN_PATH>`):
```
dispatch.cmd ops "refer to <PLAN_PATH>, review task <N> | TODO: 1) Read task <N> in plan; follow task-reviewer-prompt.md in subagent-driven-development. 2) Review implementation; if issues, write defect report only (no fixes). 3) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> review finished, status: STATUS, summary: SUMMARY\" — STATUS=pass or defects, SUMMARY=result or defect report. | AVOID: - DO NOT fix code - DO NOT spawn sub-agents - DO NOT assign review to Task tool - DO NOT skip TODO 3"
```

**TODO 4B-2** — STOP. Wait for completion signal containing `task <N> review finished`.

- IF ops asks a question → answer it in your session (only step where you answer `main:0.3` questions)
- IF signal contains `status: pass` → set `CURRENT_TASK` = `CURRENT_TASK` + 1. IF `CURRENT_TASK` <= `TASK_COUNT` → repeat from Step 4A. IF `CURRENT_TASK` > `TASK_COUNT` → Step 4 complete, open Step 5.
- IF signal contains `status: defects` → go to Step 4C (do not increment `CURRENT_TASK`)

#### Worker Completion 4B (main:0.3)

```
dispatch.cmd orchestrator "STATUS UPDATE - task <N> review finished, status: <pass|defects>, summary: <summary or defect report>"
```

#### Worker Questions (main:0.3 → orchestrator)

```
dispatch.cmd orchestrator "<question>"
```

### Step 4C — fix loop (only when reviewer reports defects)

**TODO 4C-1** — worker dispatch prompt; execute command EXACTLY (replace defect report text):
```
dispatch.cmd implementer "fix defects for task <N> | TODO: 1) Fix only these defects: <defect/issue report text from reviewer>. 2) dispatch.cmd orchestrator \"STATUS UPDATE - task <N> fix finished, summary: SUMMARY\" — SUMMARY=what you fixed. | AVOID: - DO NOT change unrelated code - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 4C-2** — STOP. Wait for completion signal containing `task <N> fix finished`.

**TODO 4C-3** — go back to Step 4B (re-review same `CURRENT_TASK`, do not increment)

#### Worker Completion 4C (main:0.2)

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
