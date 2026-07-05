# Step 2 — Git Worktree

**Prerequisite:** `DESIGN_PATH` is set from Step 1 completion signal.

**Completion signal:** message to `main:0.0` containing `using-git-worktress step finished`

**On complete:** open `steps/03-writing-plans.md`

---

Execute TODO lines **one by one, in order**. Use `dispatch.cmd` for all pane messages. **DO NOT** use raw `tmux send-keys`. Combine work and callback in **one** `dispatch.cmd` — do not split into separate messages unless a prior TODO must complete first.

## TODO (orchestrator — main:0.0)

**TODO 1** — execute command EXACTLY:
```
git status
```
- IF output contains `not a git repository` → execute command EXACTLY: `git init`
- IF output does NOT contain `not a git repository` → proceed to TODO 2 (do not run `git init`)

**TODO 2** — set `FEATURE_NAME` using this rule only:
- Take the first 3–5 meaningful words from `REQUIREMENT` (drop articles: a, an, the)
- Lowercase each word
- Join with hyphens
- Example: `Build a news sentiment API` → `build-news-sentiment-api`

**TODO 3** — worker dispatch prompt; execute command EXACTLY (replace `<FEATURE_NAME>` with value of `FEATURE_NAME`):
```
dispatch.cmd ops "/skills using-git-worktrees create branch dev/<FEATURE_NAME> | TODO: 1) Create git worktree on branch dev/<FEATURE_NAME>. 2) dispatch.cmd orchestrator \"using-git-worktress step finished, you can proceed next step\". | AVOID: - DO NOT implement feature code - DO NOT skip TODO 2 - DO NOT stop before TODO 2 succeeds"
```

**TODO 4** — STOP. Do not run any more commands. Wait for completion signal.

## Worker Completion (main:0.4 runs after worktree created)

Ops pane `main:0.4` **must** execute this as its final action:

```
dispatch.cmd orchestrator "using-git-worktress step finished, you can proceed next step"
```

## Worker Questions (main:0.4 → orchestrator)

If ops needs to ask the orchestrator a question:

```
dispatch.cmd orchestrator "<question>"
```

## FORBIDDEN in this step

- DO NOT IMPLEMENT CODE
- DO NOT use raw `tmux send-keys` — use `dispatch.cmd` only
- DO NOT skip TODO 1 (`git status` is mandatory)
- DO NOT split TODO 3 into separate work and callback dispatches
- DO NOT omit callback instructions from TODO 3
- DO NOT invent a different `FEATURE_NAME` format
- DO NOT answer any question from `main:0.4` in orchestrator session — orchestrator answers via dispatch if step allows
- DO NOT run any command not listed in TODO 1–3
- DO NOT open Step 3 until completion signal received
