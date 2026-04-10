#!/usr/bin/env bash
# Floyd state pause — captures session state for cross-device resume.
# WRITES to project .floyd/ directory and optionally Firestore. NEVER to .supercache/.
set -euo pipefail

PROJECT_DIR="${1:-.}"
FLOYD_DIR="$PROJECT_DIR/.floyd"
TIMESTAMP="$(date -u +%Y-%m-%dT%H:%M:%SZ)"
SESSION_ID="${FLOYD_SESSION_ID:-$(uuidgen 2>/dev/null || python3 -c 'import uuid; print(uuid.uuid4())')}"

mkdir -p "$FLOYD_DIR"

STATE_FILE="$FLOYD_DIR/session_state.json"

cat > "$STATE_FILE" <<EOF
{
  "session_id": "$SESSION_ID",
  "paused_at": "$TIMESTAMP",
  "project": "$(basename "$(cd "$PROJECT_DIR" && pwd)")",
  "project_path": "$(cd "$PROJECT_DIR" && pwd)",
  "hostname": "$(hostname)",
  "user": "$(whoami)",
  "supercache_version": "$(cat "${SUPERCACHE_ROOT:-$(cd "$PROJECT_DIR" && pwd)/../.supercache}/VERSION" 2>/dev/null || echo 'unknown')",
  "status": "paused",
  "resume_hint": "Read .floyd/HANDOFF_*.md for context, then continue from remaining steps."
}
EOF

echo "[pause] Session state written to: $STATE_FILE"
echo "[pause] Session ID: $SESSION_ID"
echo "[pause] To resume on another device, copy .floyd/session_state.json or read from Firestore."
