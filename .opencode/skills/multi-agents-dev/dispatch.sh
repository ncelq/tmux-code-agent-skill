#!/usr/bin/env bash
# dispatch — send message to agent pane + C-m
# Usage: dispatch <agent> <message>
#
# Agents: orchestrator, Cursor, implementer, implement_complex, ops
# Env: TMUX_SESSION (default: main), DISPATCH_DEBUG (set to 1 for verbose)
#      DISPATCH_FORCE (set to 1 to bypass duplicate guard), DISPATCH_DEDUP_MS (default: 5000)

set -euo pipefail

get_agent_pane() {
    local agent="$1"
    local session="${TMUX_SESSION:-main}"
    case "${agent,,}" in
        orchestrator)       echo "${session}:0.0" ;;
        implementer)        echo "${session}:0.1" ;;
        implement_complex)  echo "${session}:0.2" ;;
        cursor)            echo "${session}:0.3" ;;
        ops)               echo "${session}:0.4" ;;
        *)
            echo "Unknown agent '$agent'. Use: orchestrator, Cursor, implementer, implement_complex, ops" >&2
            exit 1
            ;;
    esac
}

test_recent_duplicate() {
    local pane="$1" message="$2"
    [[ "${DISPATCH_FORCE:-}" == "1" ]] && return 1
    local window_ms="${DISPATCH_DEDUP_MS:-5000}"
    local state_file="/tmp/dispatch-last.json"
    local now
    now=$(date +%s%3N)
    local key="${pane}|${message}"
    if [[ -f "$state_file" ]]; then
        local saved_key saved_ts
        saved_key=$(jq -r '.Key' "$state_file" 2>/dev/null || echo "")
        saved_ts=$(jq -r '.Ts' "$state_file" 2>/dev/null || echo 0)
        if [[ "$saved_key" == "$key" && $((now - saved_ts)) -lt $window_ms ]]; then
            return 0
        fi
    fi
    echo "{\"Key\":\"$key\",\"Ts\":$now}" > "$state_file"
    return 1
}

send_dispatch() {
    local pane="$1" message="$2"
    if [[ "${DISPATCH_DEBUG:-}" == "1" ]]; then
        echo "dispatch: pane=$pane message=$message"
    fi
    tmux send-keys -t "$pane" -l "$message"
    sleep 1
    tmux send-keys -t "$pane" C-m
}

if [[ $# -lt 2 ]]; then
    cat >&2 <<'EOF'
Usage:
  dispatch <agent> <message>

  Sends message literally, waits 1s, then C-m (Enter) automatically.
  Skips duplicate pane+message within 5s (override: DISPATCH_FORCE=1).

Agents: orchestrator (0.0), implementer (0.1), implement_complex (0.2), Cursor (0.3), ops (0.4)

Examples:
  dispatch Cursor "/brainstorming build API. Save specs to ./docs/"
  dispatch ops "/skills using-git-worktrees create branch dev/my-feature"
  dispatch orchestrator "using-git-worktress step finished, you can proceed next step"
EOF
    exit 1
fi

agent="$1"
shift
message="$*"
pane=$(get_agent_pane "$agent")

if test_recent_duplicate "$pane" "$message"; then
    if [[ "${DISPATCH_DEBUG:-}" == "1" ]]; then
        echo "dispatch: SKIPPED duplicate to $pane (within dedup window)"
    fi
    exit 0
fi

send_dispatch "$pane" "$message"
