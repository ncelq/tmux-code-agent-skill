#!/usr/bin/env bash
set -euo pipefail

#tmux kill-server
tmux new-session -d -s main "opencode --auto --agent orchestrator; bash"
tmux split-window -h -t main:0.0 "agent --model Auto --yolo; bash"
tmux split-window -h -t main:0.1 "opencode --mini --auto --agent implementer; bash"
tmux split-window -v -t main:0.2 "opencode --mini --auto --agent ops; bash"
tmux resize-pane -t main:0.0 -x 30

tmux attach -t main
