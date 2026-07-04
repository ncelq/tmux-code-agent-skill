#!/usr/bin/env bash
set -euo pipefail

ROOT="$(pwd)"
cp "$(dirname "$0")/dispatch.sh" "$ROOT/dispatch.sh"
chmod +x "$ROOT/dispatch.sh"
echo "dispatch synced to project root"
