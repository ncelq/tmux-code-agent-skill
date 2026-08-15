#!/bin/bash
set -e

CODE_HOME="${CODE_HOME:-/data}"

mkdir -p /opt/data
# Bind mounts (especially Docker Desktop on Windows) make recursive chown
# extremely slow on large trees; ownership on the mount root is enough.
chown coder:coder /opt/data 2>/dev/null || true

# Write secrets as explicit export statements so they survive tmux/exec chains.
# Use CODE_HOME (not /tmp) so the coder user can re-run entrypoint after root
# created the file at container start.
ENV_FILE="$CODE_HOME/.env.sh"
for VAR in OPENCODE_API_KEY GITHUB_TOKEN CURSOR_API_KEY; do
    if [ -n "${!VAR}" ]; then
        printf "export %s=%s\n" "$VAR" "$(printf '%q' "${!VAR}")"
    fi
done > "$ENV_FILE"
chmod 600 "$ENV_FILE"
chown coder:coder "$ENV_FILE" 2>/dev/null || true

# Write OpenCode auth.json if OPENCODE_API_KEY is set
if [ -n "${OPENCODE_API_KEY}" ]; then
    AUTH_DIR="$CODE_HOME/.local/share/opencode"
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
    chown coder:coder "$AUTH_DIR/auth.json" 2>/dev/null || true
fi

# Detached `compose up -d` has no TTY, so do not start tmux/bash as PID 1.
# Sleep keeps the container alive for later `docker exec`.
if [ "$#" -gt 0 ]; then
    exec "$@"
else
    exec sleep infinity
fi

