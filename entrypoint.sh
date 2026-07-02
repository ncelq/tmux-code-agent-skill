#!/bin/bash
set -e

CODE_HOME="${CODE_HOME:-/data}"

mkdir -p "$CODE_HOME"

# Write HF secrets as explicit export statements so they survive tmux/exec chains
for VAR in OPENCODE_GO_API_KEY GITHUB_TOKEN; do
    if [ -n "${!VAR}" ]; then
        printf "export %s=%s\n" "$VAR" "$(printf '%q' "${!VAR}")"
    fi
done > /tmp/env.sh
chmod 600 /tmp/env.sh

# Write OpenCode auth.json if OPENCODE_GO_API_KEY is set
if [ -n "${OPENCODE_GO_API_KEY}" ]; then
    for AUTH_DIR in "$HOME/.local/share/opencode" "/data/.local/share/opencode"; do
        mkdir -p "$AUTH_DIR"
        cat > "$AUTH_DIR/auth.json" <<EOF
{
  "opencode": {
    "type": "api",
    "key": "$OPENCODE_GO_API_KEY"
  },
  "opencode-go": {
    "type": "api",
    "key": "$OPENCODE_GO_API_KEY"
  }
}
EOF
        chmod 600 "$AUTH_DIR/auth.json"
        chown -R coder:coder "/data/.local/share/opencode" 2>/dev/null || true
    done
fi

exec tmux new-session -A -s coder
