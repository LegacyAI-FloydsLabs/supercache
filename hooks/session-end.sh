#!/usr/bin/env bash
# Session-end hook — reminds agent to produce a handoff block.
# READS from .supercache/. WRITES to project .floyd/ directory only.
set -euo pipefail

PROJECT_DIR="${1:-.}"
FLOYD_DIR="$PROJECT_DIR/.floyd"

mkdir -p "$FLOYD_DIR"

cat <<'EOF'
=== SESSION END — HANDOFF REQUIRED ===

Before ending this session, you MUST produce:

1. Current Objective: <what you were working on>
2. Completed Work: <actions + evidence>
3. Exact Current State: <branch/files/tests>
4. Remaining Steps: <ordered list>
5. Restart Prompt: <copy-paste prompt for next session>

Write the handoff to: .floyd/HANDOFF_<date>.md
Write session state to: Firestore (if configured) or .floyd/session_state.json

DO NOT write to .supercache/.
=== END ===
EOF
