# pi-todo

Pi extension that adds a branch-aware todo list.

- `todo` tool: the model manages the list with `list`, `add`, `toggle`, and `clear`.
- `/todos` command: shows the list for the current branch in the terminal UI.

State lives in tool-result details instead of an external file, so branching the
session rewinds the todo list to that point in history.

## Install

```bash
pi install npm:pi-todo
```

Or load it for a single run:

```bash
pi -e ./pi-todo
```

## Usage

```text
> add "write deploy notes" to my todos
> mark todo 1 done
> /todos
```

## Layout

```text
pi-todo/
├── package.json   # pi.extensions -> ./src/index.ts
├── README.md
└── src/index.ts   # the extension
```

Pi supplies `@earendil-works/pi-ai`, `@earendil-works/pi-coding-agent`,
`@earendil-works/pi-tui`, and `typebox` at runtime, so they stay peer
dependencies and no build step is needed.
