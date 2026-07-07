# Step 1 — Brainstorming

**Prerequisite:** `REQUIREMENT` is set from user prompt.

**Completion signal:** message to `main:0.0` containing `brainstorm step finished`

**On complete:** extract `<design file path>` from signal → set `DESIGN_PATH` → open `steps/02-using-git-worktrees.md`

---

Execute TODO lines **one by one, in order**. Use `dispatch.sh` for all pane messages. Raw `tmux send-keys` is allowed **only** for BTab pane focus (TODO 1). Combine work and callback in **one** `dispatch.sh` — do not split into separate messages unless a prior TODO must complete first.

## TODO (orchestrator — main:0.0)

**TODO 1** — execute command EXACTLY:
```
tmux send-keys -t main:0.3 BTab
```

**TODO 2** — worker dispatch prompt; execute command EXACTLY (replace `<REQUIREMENT>` with value of `REQUIREMENT`):
```
dispatch.sh Cursor "/brainstorming <REQUIREMENT> | TODO: 1) Run brainstorming; save design spec to ./docs/ only. 2) dispatch.sh orchestrator \"brainstorm step finished, the design file is at PATH, you can proceed next step\" — replace PATH with the saved file path. | AVOID: - DO NOT implement code - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 3** — STOP. Do not run any more commands. Wait for completion signal.

## Worker Completion (main:0.3 runs after brainstorm done)

Cursor pane `main:0.3` **must** execute this as its final action (replace `PATH` with actual saved file path):

```
dispatch.sh orchestrator "brainstorm step finished, the design file is at PATH, you can proceed next step"
```

## FORBIDDEN in this step

- DO NOT IMPLEMENT CODE
- DO NOT use raw `tmux send-keys` except BTab pane focus (TODO 1)
- DO NOT split TODO 2 into separate work and callback dispatches
- DO NOT omit callback instructions from TODO 2
- DO NOT answer any question from `main:0.3` — user answers those
- DO NOT run any command not listed in TODO 1–2
- DO NOT open Step 2 until completion signal received
- DO NOT treat brainstorm as complete without `brainstorm step finished` signal on orchestrator pane
