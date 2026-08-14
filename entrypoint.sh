#!/bin/bash
set -e

CODE_HOME="${CODE_HOME:-/data}"

mkdir -p "$CODE_HOME"
mkdir -p /opt/data
chown -R coder:coder /opt/data

# Ensure the npm cache is writable by the non-root runtime user so that
# `pi update` (which runs `npm install -g`) can write to it. This is a
# safety net in case the build-time chown did not take effect.
mkdir -p "$CODE_HOME/.npm"
chown -R coder:coder "$CODE_HOME/.npm" 2>/dev/null || true

# Write secrets as explicit export statements so they survive tmux/exec chains
for VAR in OPENCODE_API_KEY GITHUB_TOKEN CURSOR_API_KEY; do
    if [ -n "${!VAR}" ]; then
        printf "export %s=%s\n" "$VAR" "$(printf '%q' "${!VAR}")"
    fi
done > /tmp/env.sh
chmod 600 /tmp/env.sh

# Write OpenCode auth.json if OPENCODE_API_KEY is set
if [ -n "${OPENCODE_API_KEY}" ]; then
    for AUTH_DIR in "$HOME/.local/share/opencode" "/data/.local/share/opencode"; do
        mkdir -p "$AUTH_DIR"
        cat > "$AUTH_DIR/auth.json" <<EOF
{
  "opencode": {
    "type": "api",
    "key": "$OPENCODE_API_KEY"
  },
  "opencode-go": {
    "type": "api",
    "key": "$OPENCODE_API_KEY"
  }
}
EOF
        chmod 600 "$AUTH_DIR/auth.json"
        chown -R coder:coder "/data/.local/share/opencode" 2>/dev/null || true
    done
fi

# Cursor models come from @akepka/pi-cursor-cli-provider, which authenticates
# via the Agent CLI (CURSOR_API_KEY / agent login) — not Pi auth.json.

# Write Pi agent settings
PI_SETTINGS_DIR="/data/.pi/agent"
mkdir -p "$PI_SETTINGS_DIR"
cat > "$PI_SETTINGS_DIR/settings.json" <<EOF
{
  "packages": [
    "npm:@akepka/pi-cursor-cli-provider"
  ],
  "lastChangelogVersion": "0.84.1",
  "theme": "dark",
  "enabledModels": [
    "opencode-go/mimo-v2.5",
    "opencode-go/deepseek-v4-flash",
    "opencode/mimo-v2.5-free",
    "opencode/hy3-free",
    "cursor/cursor-grok-4.5-high-fast",
    "cursor/cursor-grok-4.6-high-fast",
    "cursor/composer-2.5-fast"
  ],
  "defaultProvider": "opencode",
  "defaultModel": "opencode/hy3-free"
}
EOF
chown -R coder:coder "/data/.pi" 2>/dev/null || true

exec tmux new-session -A -s coder
