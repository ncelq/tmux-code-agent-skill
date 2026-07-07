# Step 3 — Writing Plans

**Prerequisite:** `DESIGN_PATH` is set from Step 1.

**Completion signal:** message to `main:0.0` containing `writing plan step finished`

**On complete:** extract `<plan file path>` from signal → set `PLAN_PATH` → open `steps/04-subagent-driven-development.md`

---

Execute TODO lines **one by one, in order**. Use `dispatch.sh` for all pane messages. Raw `tmux send-keys` is allowed **only** for BTab pane focus (TODO 1–3). Combine work and callback in **one** `dispatch.sh` — do not split into separate messages unless a prior TODO must complete first.

## TODO (orchestrator — main:0.0)

**TODO 1** — execute command EXACTLY:
```
tmux send-keys -t main:0.3 BTab
```

**TODO 2** — execute command EXACTLY:
```
tmux send-keys -t main:0.3 BTab
```

**TODO 3** — execute command EXACTLY:
```
tmux send-keys -t main:0.3 BTab
```

**TODO 4** — execute command EXACTLY:
```
dispatch.sh Cursor "/clear"
```

**TODO 5** — worker dispatch prompt; execute command EXACTLY (replace `<DESIGN_PATH>` with value of `DESIGN_PATH`):
```
dispatch.sh Cursor "/writing-plans using the design doc <DESIGN_PATH> | TODO: 1) Write implementation plan from design doc, evaluate the task complexity 1-3 and put the complexity evaluation for each task; save plan to ./docs/ only. 2) dispatch.sh orchestrator \"writing plan step finished, the plan file is at PATH, you can proceed next step\" — replace PATH with the saved plan file path. | AVOID: - DO NOT implement code - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 6** — STOP. Do not run any more commands. Wait for completion signal.

## Worker Completion (main:0.3 runs after plan written)

Cursor pane `main:0.3` **must** execute this as its final action (replace `PATH` with actual saved plan file path):

```
dispatch.sh orchestrator "writing plan step finished, the plan file is at PATH, you can proceed next step"
```

## FORBIDDEN in this step

- DO NOT IMPLEMENT CODE
- DO NOT use raw `tmux send-keys` except BTab pane focus (TODO 1–3)
- DO NOT skip any BTab (TODO 1–3 are all required)
- DO NOT split TODO 5 into separate work and callback dispatches
- DO NOT omit callback instructions from TODO 5
- DO NOT answer any question from `main:0.3`
- DO NOT run any command not listed in TODO 1–5
- DO NOT open Step 4 until completion signal received
