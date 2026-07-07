# Step 5 — Requesting Code Review

**Prerequisite:** Step 4 complete (all tasks implemented and reviewed).

**Completion signal:** message to `main:0.0` containing `code review finished`

**On complete:** pipeline finished. Report success to user.

---

Execute TODO lines **one by one, in order**. Use `dispatch.sh` for all pane messages. **DO NOT** use raw `tmux send-keys`. Combine work and callback in **one** `dispatch.sh` — do not split into separate messages unless a prior TODO must complete first.

## TODO (orchestrator — main:0.0)

**TODO 1** — execute command EXACTLY:
```
dispatch.sh Cursor "/clear"
```

**TODO 2** — worker dispatch prompt; execute command EXACTLY (replace `<FEATURE_NAME>` with value of `FEATURE_NAME`):
```
dispatch.sh Cursor "/requesting-code-review for <FEATURE_NAME> | TODO: 1) Review feature; follow receiving-code-review skill. 2) dispatch.sh orchestrator \"STATUS UPDATE - code review finished, status: STATUS, summary: SUMMARY\" — STATUS=pass or issues, SUMMARY=review result or issue list. | AVOID: - DO NOT implement fixes - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 3** — STOP. Wait for completion signal containing `code review finished`.

**TODO 4** — branch on result:
- IF signal contains `status: pass` → pipeline complete. Stop.
- IF signal contains `status: issues` → go to TODO 5

**TODO 5** — open `steps/04-subagent-driven-development.md` and execute Step 4C fix loop using the code review issues as the defect report. Then re-run TODO 1–3 of this file.

**TODO 6** — IF implementer asks a question about the review issue:
  - **TODO 6a** — worker dispatch prompt; execute command EXACTLY (replace `<QUESTION>`):
    ```
    dispatch.sh Cursor "<QUESTION> | TODO: 1) Answer the code review question for implementer. | AVOID: - DO NOT implement fixes - DO NOT dispatch to other panes"
    ```
  - **TODO 6b** — STOP. Wait for `main:0.3` answer in your session.
  - **TODO 6c** — worker dispatch prompt; execute command EXACTLY (replace `<ANSWER>`):
    ```
    dispatch.sh implementer "<ANSWER> | TODO: 1) Apply this guidance to your fix for the review issue. | AVOID: - DO NOT ask orchestrator the same question again unless blocked"
    ```

## Worker Completion (main:0.3 runs after review done)

Cursor pane `main:0.3` **must** execute this as its final action:

```
dispatch.sh orchestrator "STATUS UPDATE - code review finished, status: <pass|issues>, summary: <summary or issues>"
```

## FORBIDDEN in this step

- DO NOT IMPLEMENT CODE
- DO NOT use raw `tmux send-keys` — use `dispatch.sh` only
- DO NOT split TODO 2 into separate work and callback dispatches
- DO NOT omit callback instructions from TODO 2
- DO NOT answer code review questions yourself — dispatch to `main:0.3` per TODO 6
- DO NOT run any command not listed in TODO 1–6
- DO NOT declare pipeline complete while review issues remain open
