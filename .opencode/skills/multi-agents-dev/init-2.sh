#!/usr/bin/env bash
set -euo pipefail

#tmux kill-server
tmux new-session -d -s main "opencode --auto --agent orchestrator; bash"
PANE1=$(tmux split-window -h -t main:0.0 -P -F "#{pane_id}" "opencode --auto --agent implementer; bash")
PANE2=$(tmux split-window -h -t $PANE1 -P -F "#{pane_id}" "opencode --auto --agent implement_complex; bash")
tmux split-window -v -t $PANE1 "opencode --auto --agent Cursor; bash"
tmux split-window -v -t $PANE2 "opencode --auto --agent ops; bash"
tmux resize-pane -t main:0.0 -x 30

tmux attach -t main